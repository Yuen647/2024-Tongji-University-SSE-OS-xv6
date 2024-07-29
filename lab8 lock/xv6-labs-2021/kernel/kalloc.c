// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;// 空闲资源链表
  char lock_name[7];
} kmem[NCPU];//修改成数组形式

void
kinit()
{
  for (int idx = 0; idx < NCPU; idx++) {
    snprintf(kmem[idx].lock_name, sizeof(kmem[idx].lock_name), "kmem_%d", idx);
    initlock(&kmem[idx].lock, kmem[idx].lock_name); // 初始化锁
  }
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *start_addr, void *end_addr)
{
  char *mem_ptr;
  mem_ptr = (char*)PGROUNDUP((uint64)start_addr);
  for(; mem_ptr + PGSIZE <= (char*)end_addr; mem_ptr += PGSIZE)
    kfree(mem_ptr);
}

void
kfree(void *phys_addr)
{
  struct run *node;
  if(((uint64)phys_addr % PGSIZE) != 0 || (char*)phys_addr < end || (uint64)phys_addr >= PHYSTOP)
    panic("kfree"); // 检查释放的内存块是否合法
  memset(phys_addr, 1, PGSIZE);
  node = (struct run*)phys_addr;
  push_off();
  int cpu_id = cpuid(); // 获取当前CPU的ID

  acquire(&kmem[cpu_id].lock); // 获取锁
  node->next = kmem[cpu_id].freelist;
  kmem[cpu_id].freelist = node;
  release(&kmem[cpu_id].lock); // 释放锁

  pop_off();
}

void *
kalloc(void)
{
  struct run *node;

  push_off();
  int cpu_id = cpuid();

  acquire(&kmem[cpu_id].lock);
  node = kmem[cpu_id].freelist; // 将当前CPU空闲资源链表的头节点赋值给node
  if(node) {
    kmem[cpu_id].freelist = node->next;
  }
  else {
    int success = 0;
    for(int i = 0; i < NCPU; i++) {
      if (i == cpu_id) continue;
      acquire(&kmem[i].lock);
      struct run *temp = kmem[i].freelist; 
      if(temp) {
        struct run *half_node = temp; 
        struct run *prev = temp;
        while (half_node && half_node->next) {
          half_node = half_node->next->next;
          prev = temp;
          temp = temp->next;
        }
        kmem[cpu_id].freelist = kmem[i].freelist; // 将窃取的一半内存分配给当前CPU
        if (temp == kmem[i].freelist) {
          kmem[i].freelist = 0;
        }
        else {
          kmem[i].freelist = temp; // 更新其他CPU空闲资源链表的头指针
          prev->next = 0;
        }
        success = 1;
      }
      release(&kmem[i].lock);
      if (success) {
        node = kmem[cpu_id].freelist;
        kmem[cpu_id].freelist = node->next; // 更新当前CPU空闲资源链表的头指针
        break;
      }
    }
  }
  release(&kmem[cpu_id].lock);
  pop_off();

  if(node)
    memset((char*)node, 5, PGSIZE);
  return (void*)node;
}
