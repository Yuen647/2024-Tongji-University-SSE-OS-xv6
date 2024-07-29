// Buffer cache.
//
// The buffer cache is a linked list of buf structures holding
// cached copies of disk block contents.  Caching disk blocks
// in memory reduces the number of disk reads and also provides
// a synchronization point for disk blocks used by multiple processes.
//
// Interface:
// * To get a buffer for a particular disk block, call bread.
// * After changing buffer data, call bwrite to write it to disk.
// * When done with the buffer, call brelse.
// * Do not use the buffer after calling brelse.
// * Only one process at a time can use a buffer,
//     so do not keep them longer than necessary.

#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "buf.h"

#define NBUFMAP_BUCKET 13 // 缓冲区映射关系的桶数量
// 哈希函数，根据设备号和块号计算桶索引
#define BUFMAP_HASH(dev, blockno) ((((dev)<<27)|(blockno))%NBUFMAP_BUCKET)

struct {
  struct buf buf[NBUF]; // 缓冲区数组
  struct spinlock eviction_lock; // 自旋锁，保护缓冲区
  struct buf bufmap[NBUFMAP_BUCKET]; // 缓冲区桶
  struct spinlock bufmap_locks[NBUFMAP_BUCKET]; // 桶的锁
} bcache; // 块缓存

void binit(void) {
  for(int i = 0; i < NBUFMAP_BUCKET; i++) {
    initlock(&bcache.bufmap_locks[i], "bcache_bufmap"); // 初始化bufmap的锁
    bcache.bufmap[i].next = 0; // 初始化bufmap的next字段
  }

  for(int i = 0; i < NBUF; i++){
    struct buf *b = &bcache.buf[i];
    initsleeplock(&b->lock, "buffer"); // 初始化缓冲区的锁
    b->lastuse = 0; // 初始化lastuse字段
    b->refcnt = 0;
    b->next = bcache.bufmap[0].next;
    bcache.bufmap[0].next = b;
  }

  initlock(&bcache.eviction_lock, "bcache_eviction"); // 初始化eviction锁
}

// 查找或分配一个锁定的缓冲区
static struct buf* bget(uint dev, uint blockno) {
  struct buf *b;
  uint key = BUFMAP_HASH(dev, blockno); // 计算哈希值确定索引

  acquire(&bcache.bufmap_locks[key]); // 获取bufmap锁

  for(b = bcache.bufmap[key].next; b; b = b->next) {
    if(b->dev == dev && b->blockno == blockno) {
      b->refcnt++; // 引用计数加1
      release(&bcache.bufmap_locks[key]); // 释放锁
      acquiresleep(&b->lock); // 获取缓冲区锁
      return b; // 返回缓冲区
    }
  }
  release(&bcache.bufmap_locks[key]); // 释放锁
  acquire(&bcache.eviction_lock); // 获取eviction锁

  for(b = bcache.bufmap[key].next; b; b = b->next) {
    if(b->dev == dev && b->blockno == blockno) {
      acquire(&bcache.bufmap_locks[key]); // 获取bufmap锁
      b->refcnt++;
      release(&bcache.bufmap_locks[key]); // 释放锁
      release(&bcache.eviction_lock); // 释放eviction锁
      acquiresleep(&b->lock); // 获取缓冲区锁
      return b;
    }
  }

  struct buf *least_recently_used = 0; 
  uint holding_bucket = -1;

  for(int i = 0; i < NBUFMAP_BUCKET; i++){
    acquire(&bcache.bufmap_locks[i]); // 获取桶锁
    int found = 0;
    for(b = &bcache.bufmap[i]; b->next; b = b->next) {
      if(b->next->refcnt == 0 && (!least_recently_used || b->next->lastuse < least_recently_used->next->lastuse)) {
        least_recently_used = b;
        found = 1;
      }
    }
    if(!found) {
      release(&bcache.bufmap_locks[i]);
    } else {
      if(holding_bucket != -1) release(&bcache.bufmap_locks[holding_bucket]);
      holding_bucket = i;
    }
  }

  if(!least_recently_used) { 
    panic("bget: no buffers");
  }
  b = least_recently_used->next;

  if(holding_bucket != key) {
    least_recently_used->next = b->next;
    release(&bcache.bufmap_locks[holding_bucket]);
    acquire(&bcache.bufmap_locks[key]);
    b->next = bcache.bufmap[key].next;
    bcache.bufmap[key].next = b;
  }

  b->dev = dev;
  b->blockno = blockno;
  b->refcnt = 1;
  b->valid = 0;
  release(&bcache.bufmap_locks[key]);
  release(&bcache.eviction_lock);
  acquiresleep(&b->lock);
  return b;
}

// 返回一个包含指定块内容的锁定缓冲区
struct buf* bread(uint dev, uint blockno) {
  struct buf *b;
  b = bget(dev, blockno);
  if(!b->valid) {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}

// 将缓冲区内容写入磁盘
void bwrite(struct buf *b) {
  if(!holdingsleep(&b->lock))
    panic("bwrite");
  virtio_disk_rw(b, 1);
}

// 释放一个被锁定的缓冲区
void brelse(struct buf *b) {
  if(!holdingsleep(&b->lock))
    panic("brelse");

  releasesleep(&b->lock); // 释放锁

  uint key = BUFMAP_HASH(b->dev, b->blockno); // 计算哈希值
  acquire(&bcache.bufmap_locks[key]); // 获取bufmap锁
  b->refcnt--; // 引用计数减1
  if (b->refcnt == 0) {
    b->lastuse = ticks; // 更新最后使用时间
  }
  release(&bcache.bufmap_locks[key]); // 释放锁
}

// 将缓冲区锁定，避免回收
void bpin(struct buf *b) {
  uint key = BUFMAP_HASH(b->dev, b->blockno);
  acquire(&bcache.bufmap_locks[key]);
  b->refcnt++;
  release(&bcache.bufmap_locks[key]);
}

// 取消对缓冲区的锁定，允许回收
void bunpin(struct buf *b) {
  uint key = BUFMAP_HASH(b->dev, b->blockno);
  acquire(&bcache.bufmap_locks[key]);
  b->refcnt--;
  release(&bcache.bufmap_locks[key]);
}

