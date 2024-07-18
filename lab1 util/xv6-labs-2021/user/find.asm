
user/_find:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <match>:
void match(const char* path, const char* name) {
    int pathIndex = 0;
    int nameIndex = 0;

    // 遍历路径字符串
    while (path[pathIndex] != 0) {
   0:	00054783          	lbu	a5,0(a0)
   4:	cbb9                	beqz	a5,5a <match+0x5a>
        nameIndex = 0;
        int tempIndex = pathIndex;

        // 检查子字符串是否与name匹配
        while (name[nameIndex] != 0) {
   6:	0005c883          	lbu	a7,0(a1)
   a:	882a                	mv	a6,a0
   c:	8346                	mv	t1,a7
   e:	a031                	j	1a <match+0x1a>
                break;
            }
        }

        // 如果完整匹配name，则打印路径
        if (name[nameIndex] == 0) {
  10:	c785                	beqz	a5,38 <match+0x38>
    while (path[pathIndex] != 0) {
  12:	0805                	addi	a6,a6,1
  14:	00084783          	lbu	a5,0(a6)
  18:	c3a9                	beqz	a5,5a <match+0x5a>
        while (name[nameIndex] != 0) {
  1a:	00088f63          	beqz	a7,38 <match+0x38>
  1e:	00158693          	addi	a3,a1,1
  22:	8742                	mv	a4,a6
  24:	879a                	mv	a5,t1
            if (name[nameIndex] == path[tempIndex]) {
  26:	00074603          	lbu	a2,0(a4)
  2a:	fef613e3          	bne	a2,a5,10 <match+0x10>
        while (name[nameIndex] != 0) {
  2e:	0006c783          	lbu	a5,0(a3)
  32:	0705                	addi	a4,a4,1
  34:	0685                	addi	a3,a3,1
  36:	fbe5                	bnez	a5,26 <match+0x26>
void match(const char* path, const char* name) {
  38:	1141                	addi	sp,sp,-16
  3a:	e406                	sd	ra,8(sp)
  3c:	e022                	sd	s0,0(sp)
  3e:	0800                	addi	s0,sp,16
            printf("%s\n", path);
  40:	85aa                	mv	a1,a0
  42:	00001517          	auipc	a0,0x1
  46:	9ae50513          	addi	a0,a0,-1618 # 9f0 <malloc+0xe8>
  4a:	00001097          	auipc	ra,0x1
  4e:	800080e7          	jalr	-2048(ra) # 84a <printf>
            return;
        }
        pathIndex++;
    }
}
  52:	60a2                	ld	ra,8(sp)
  54:	6402                	ld	s0,0(sp)
  56:	0141                	addi	sp,sp,16
  58:	8082                	ret
  5a:	8082                	ret

000000000000005c <find>:

// 递归查找路径中的文件
void find(const char *path, const char *name) {
  5c:	d8010113          	addi	sp,sp,-640
  60:	26113c23          	sd	ra,632(sp)
  64:	26813823          	sd	s0,624(sp)
  68:	26913423          	sd	s1,616(sp)
  6c:	27213023          	sd	s2,608(sp)
  70:	25313c23          	sd	s3,600(sp)
  74:	25413823          	sd	s4,592(sp)
  78:	25513423          	sd	s5,584(sp)
  7c:	25613023          	sd	s6,576(sp)
  80:	23713c23          	sd	s7,568(sp)
  84:	0500                	addi	s0,sp,640
  86:	892a                	mv	s2,a0
  88:	89ae                	mv	s3,a1
    int fileDescriptor;
    struct dirent directoryEntry;
    struct stat status;

    // 打开目录
    if ((fileDescriptor = open(path, 0)) < 0) {
  8a:	4581                	li	a1,0
  8c:	00000097          	auipc	ra,0x0
  90:	486080e7          	jalr	1158(ra) # 512 <open>
  94:	06054563          	bltz	a0,fe <find+0xa2>
  98:	84aa                	mv	s1,a0
        fprintf(2, "无法打开 %s\n", path);
        return;
    }

    // 获取目录信息
    if (fstat(fileDescriptor, &status) < 0) {
  9a:	d8840593          	addi	a1,s0,-632
  9e:	00000097          	auipc	ra,0x0
  a2:	48c080e7          	jalr	1164(ra) # 52a <fstat>
  a6:	06054763          	bltz	a0,114 <find+0xb8>
        close(fileDescriptor);
        return;
    }

    // 根据文件类型处理
    switch (status.type) {
  aa:	d9041783          	lh	a5,-624(s0)
  ae:	0007869b          	sext.w	a3,a5
  b2:	4705                	li	a4,1
  b4:	08e68063          	beq	a3,a4,134 <find+0xd8>
  b8:	4709                	li	a4,2
  ba:	00e69863          	bne	a3,a4,ca <find+0x6e>
        case T_FILE:
            // 如果是文件，尝试匹配
            match(path, name);
  be:	85ce                	mv	a1,s3
  c0:	854a                	mv	a0,s2
  c2:	00000097          	auipc	ra,0x0
  c6:	f3e080e7          	jalr	-194(ra) # 0 <match>
                find(buffer, name);
            }
            break;
    }

    close(fileDescriptor); // 关闭目录
  ca:	8526                	mv	a0,s1
  cc:	00000097          	auipc	ra,0x0
  d0:	42e080e7          	jalr	1070(ra) # 4fa <close>
}
  d4:	27813083          	ld	ra,632(sp)
  d8:	27013403          	ld	s0,624(sp)
  dc:	26813483          	ld	s1,616(sp)
  e0:	26013903          	ld	s2,608(sp)
  e4:	25813983          	ld	s3,600(sp)
  e8:	25013a03          	ld	s4,592(sp)
  ec:	24813a83          	ld	s5,584(sp)
  f0:	24013b03          	ld	s6,576(sp)
  f4:	23813b83          	ld	s7,568(sp)
  f8:	28010113          	addi	sp,sp,640
  fc:	8082                	ret
        fprintf(2, "无法打开 %s\n", path);
  fe:	864a                	mv	a2,s2
 100:	00001597          	auipc	a1,0x1
 104:	8f858593          	addi	a1,a1,-1800 # 9f8 <malloc+0xf0>
 108:	4509                	li	a0,2
 10a:	00000097          	auipc	ra,0x0
 10e:	712080e7          	jalr	1810(ra) # 81c <fprintf>
        return;
 112:	b7c9                	j	d4 <find+0x78>
        fprintf(2, "无法获取状态 %s\n", path);
 114:	864a                	mv	a2,s2
 116:	00001597          	auipc	a1,0x1
 11a:	8fa58593          	addi	a1,a1,-1798 # a10 <malloc+0x108>
 11e:	4509                	li	a0,2
 120:	00000097          	auipc	ra,0x0
 124:	6fc080e7          	jalr	1788(ra) # 81c <fprintf>
        close(fileDescriptor);
 128:	8526                	mv	a0,s1
 12a:	00000097          	auipc	ra,0x0
 12e:	3d0080e7          	jalr	976(ra) # 4fa <close>
        return;
 132:	b74d                	j	d4 <find+0x78>
            if (strlen(path) + 1 + DIRSIZ + 1 > sizeof(buffer)) {
 134:	854a                	mv	a0,s2
 136:	00000097          	auipc	ra,0x0
 13a:	16e080e7          	jalr	366(ra) # 2a4 <strlen>
 13e:	2541                	addiw	a0,a0,16
 140:	20000793          	li	a5,512
 144:	00a7fb63          	bgeu	a5,a0,15a <find+0xfe>
                printf("路径过长\n");
 148:	00001517          	auipc	a0,0x1
 14c:	8e050513          	addi	a0,a0,-1824 # a28 <malloc+0x120>
 150:	00000097          	auipc	ra,0x0
 154:	6fa080e7          	jalr	1786(ra) # 84a <printf>
                break;
 158:	bf8d                	j	ca <find+0x6e>
            strcpy(buffer, path);
 15a:	85ca                	mv	a1,s2
 15c:	db040513          	addi	a0,s0,-592
 160:	00000097          	auipc	ra,0x0
 164:	0fc080e7          	jalr	252(ra) # 25c <strcpy>
            ptr = buffer + strlen(buffer);
 168:	db040513          	addi	a0,s0,-592
 16c:	00000097          	auipc	ra,0x0
 170:	138080e7          	jalr	312(ra) # 2a4 <strlen>
 174:	02051913          	slli	s2,a0,0x20
 178:	02095913          	srli	s2,s2,0x20
 17c:	db040793          	addi	a5,s0,-592
 180:	993e                	add	s2,s2,a5
            *ptr++ = '/';
 182:	00190b13          	addi	s6,s2,1
 186:	02f00793          	li	a5,47
 18a:	00f90023          	sb	a5,0(s2)
                if (directoryEntry.name[0] == '.' && directoryEntry.name[1] == 0) continue;
 18e:	02e00a93          	li	s5,46
                if (directoryEntry.name[0] == '.' && directoryEntry.name[1] == '.' && directoryEntry.name[2] == 0) continue;
 192:	6a0d                	lui	s4,0x3
 194:	e2ea0a13          	addi	s4,s4,-466 # 2e2e <__global_pointer$+0x1bb5>
                    printf("无法获取状态 %s\n", buffer);
 198:	00001b97          	auipc	s7,0x1
 19c:	878b8b93          	addi	s7,s7,-1928 # a10 <malloc+0x108>
            while (read(fileDescriptor, &directoryEntry, sizeof(directoryEntry)) == sizeof(directoryEntry)) {
 1a0:	a825                	j	1d8 <find+0x17c>
                memmove(ptr, directoryEntry.name, DIRSIZ);
 1a2:	4639                	li	a2,14
 1a4:	da240593          	addi	a1,s0,-606
 1a8:	855a                	mv	a0,s6
 1aa:	00000097          	auipc	ra,0x0
 1ae:	272080e7          	jalr	626(ra) # 41c <memmove>
                ptr[DIRSIZ] = 0;
 1b2:	000907a3          	sb	zero,15(s2)
                if (stat(buffer, &status) < 0) {
 1b6:	d8840593          	addi	a1,s0,-632
 1ba:	db040513          	addi	a0,s0,-592
 1be:	00000097          	auipc	ra,0x0
 1c2:	1ce080e7          	jalr	462(ra) # 38c <stat>
 1c6:	04054363          	bltz	a0,20c <find+0x1b0>
                find(buffer, name);
 1ca:	85ce                	mv	a1,s3
 1cc:	db040513          	addi	a0,s0,-592
 1d0:	00000097          	auipc	ra,0x0
 1d4:	e8c080e7          	jalr	-372(ra) # 5c <find>
            while (read(fileDescriptor, &directoryEntry, sizeof(directoryEntry)) == sizeof(directoryEntry)) {
 1d8:	4641                	li	a2,16
 1da:	da040593          	addi	a1,s0,-608
 1de:	8526                	mv	a0,s1
 1e0:	00000097          	auipc	ra,0x0
 1e4:	30a080e7          	jalr	778(ra) # 4ea <read>
 1e8:	47c1                	li	a5,16
 1ea:	eef510e3          	bne	a0,a5,ca <find+0x6e>
                if (directoryEntry.inum == 0)
 1ee:	da045783          	lhu	a5,-608(s0)
 1f2:	d3fd                	beqz	a5,1d8 <find+0x17c>
                if (directoryEntry.name[0] == '.' && directoryEntry.name[1] == 0) continue;
 1f4:	da245783          	lhu	a5,-606(s0)
 1f8:	0007871b          	sext.w	a4,a5
 1fc:	fd570ee3          	beq	a4,s5,1d8 <find+0x17c>
                if (directoryEntry.name[0] == '.' && directoryEntry.name[1] == '.' && directoryEntry.name[2] == 0) continue;
 200:	fb4711e3          	bne	a4,s4,1a2 <find+0x146>
 204:	da444783          	lbu	a5,-604(s0)
 208:	ffc9                	bnez	a5,1a2 <find+0x146>
 20a:	b7f9                	j	1d8 <find+0x17c>
                    printf("无法获取状态 %s\n", buffer);
 20c:	db040593          	addi	a1,s0,-592
 210:	855e                	mv	a0,s7
 212:	00000097          	auipc	ra,0x0
 216:	638080e7          	jalr	1592(ra) # 84a <printf>
                    continue;
 21a:	bf7d                	j	1d8 <find+0x17c>

000000000000021c <main>:

int main(int argc, char *argv[]) {
 21c:	1141                	addi	sp,sp,-16
 21e:	e406                	sd	ra,8(sp)
 220:	e022                	sd	s0,0(sp)
 222:	0800                	addi	s0,sp,16
    // 检查参数数量
    if (argc < 3) {
 224:	4709                	li	a4,2
 226:	00a74f63          	blt	a4,a0,244 <main+0x28>
        printf("用法: find [路径] [文件名]\n");
 22a:	00001517          	auipc	a0,0x1
 22e:	80e50513          	addi	a0,a0,-2034 # a38 <malloc+0x130>
 232:	00000097          	auipc	ra,0x0
 236:	618080e7          	jalr	1560(ra) # 84a <printf>
        exit(1);
 23a:	4505                	li	a0,1
 23c:	00000097          	auipc	ra,0x0
 240:	296080e7          	jalr	662(ra) # 4d2 <exit>
 244:	87ae                	mv	a5,a1
    }

    // 调用查找函数
    find(argv[1], argv[2]);
 246:	698c                	ld	a1,16(a1)
 248:	6788                	ld	a0,8(a5)
 24a:	00000097          	auipc	ra,0x0
 24e:	e12080e7          	jalr	-494(ra) # 5c <find>
    exit(0); // 正常退出程序
 252:	4501                	li	a0,0
 254:	00000097          	auipc	ra,0x0
 258:	27e080e7          	jalr	638(ra) # 4d2 <exit>

000000000000025c <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 25c:	1141                	addi	sp,sp,-16
 25e:	e422                	sd	s0,8(sp)
 260:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 262:	87aa                	mv	a5,a0
 264:	0585                	addi	a1,a1,1
 266:	0785                	addi	a5,a5,1
 268:	fff5c703          	lbu	a4,-1(a1)
 26c:	fee78fa3          	sb	a4,-1(a5)
 270:	fb75                	bnez	a4,264 <strcpy+0x8>
    ;
  return os;
}
 272:	6422                	ld	s0,8(sp)
 274:	0141                	addi	sp,sp,16
 276:	8082                	ret

0000000000000278 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 278:	1141                	addi	sp,sp,-16
 27a:	e422                	sd	s0,8(sp)
 27c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 27e:	00054783          	lbu	a5,0(a0)
 282:	cb91                	beqz	a5,296 <strcmp+0x1e>
 284:	0005c703          	lbu	a4,0(a1)
 288:	00f71763          	bne	a4,a5,296 <strcmp+0x1e>
    p++, q++;
 28c:	0505                	addi	a0,a0,1
 28e:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 290:	00054783          	lbu	a5,0(a0)
 294:	fbe5                	bnez	a5,284 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 296:	0005c503          	lbu	a0,0(a1)
}
 29a:	40a7853b          	subw	a0,a5,a0
 29e:	6422                	ld	s0,8(sp)
 2a0:	0141                	addi	sp,sp,16
 2a2:	8082                	ret

00000000000002a4 <strlen>:

uint
strlen(const char *s)
{
 2a4:	1141                	addi	sp,sp,-16
 2a6:	e422                	sd	s0,8(sp)
 2a8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2aa:	00054783          	lbu	a5,0(a0)
 2ae:	cf91                	beqz	a5,2ca <strlen+0x26>
 2b0:	0505                	addi	a0,a0,1
 2b2:	87aa                	mv	a5,a0
 2b4:	4685                	li	a3,1
 2b6:	9e89                	subw	a3,a3,a0
 2b8:	00f6853b          	addw	a0,a3,a5
 2bc:	0785                	addi	a5,a5,1
 2be:	fff7c703          	lbu	a4,-1(a5)
 2c2:	fb7d                	bnez	a4,2b8 <strlen+0x14>
    ;
  return n;
}
 2c4:	6422                	ld	s0,8(sp)
 2c6:	0141                	addi	sp,sp,16
 2c8:	8082                	ret
  for(n = 0; s[n]; n++)
 2ca:	4501                	li	a0,0
 2cc:	bfe5                	j	2c4 <strlen+0x20>

00000000000002ce <memset>:

void*
memset(void *dst, int c, uint n)
{
 2ce:	1141                	addi	sp,sp,-16
 2d0:	e422                	sd	s0,8(sp)
 2d2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 2d4:	ce09                	beqz	a2,2ee <memset+0x20>
 2d6:	87aa                	mv	a5,a0
 2d8:	fff6071b          	addiw	a4,a2,-1
 2dc:	1702                	slli	a4,a4,0x20
 2de:	9301                	srli	a4,a4,0x20
 2e0:	0705                	addi	a4,a4,1
 2e2:	972a                	add	a4,a4,a0
    cdst[i] = c;
 2e4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 2e8:	0785                	addi	a5,a5,1
 2ea:	fee79de3          	bne	a5,a4,2e4 <memset+0x16>
  }
  return dst;
}
 2ee:	6422                	ld	s0,8(sp)
 2f0:	0141                	addi	sp,sp,16
 2f2:	8082                	ret

00000000000002f4 <strchr>:

char*
strchr(const char *s, char c)
{
 2f4:	1141                	addi	sp,sp,-16
 2f6:	e422                	sd	s0,8(sp)
 2f8:	0800                	addi	s0,sp,16
  for(; *s; s++)
 2fa:	00054783          	lbu	a5,0(a0)
 2fe:	cb99                	beqz	a5,314 <strchr+0x20>
    if(*s == c)
 300:	00f58763          	beq	a1,a5,30e <strchr+0x1a>
  for(; *s; s++)
 304:	0505                	addi	a0,a0,1
 306:	00054783          	lbu	a5,0(a0)
 30a:	fbfd                	bnez	a5,300 <strchr+0xc>
      return (char*)s;
  return 0;
 30c:	4501                	li	a0,0
}
 30e:	6422                	ld	s0,8(sp)
 310:	0141                	addi	sp,sp,16
 312:	8082                	ret
  return 0;
 314:	4501                	li	a0,0
 316:	bfe5                	j	30e <strchr+0x1a>

0000000000000318 <gets>:

char*
gets(char *buf, int max)
{
 318:	711d                	addi	sp,sp,-96
 31a:	ec86                	sd	ra,88(sp)
 31c:	e8a2                	sd	s0,80(sp)
 31e:	e4a6                	sd	s1,72(sp)
 320:	e0ca                	sd	s2,64(sp)
 322:	fc4e                	sd	s3,56(sp)
 324:	f852                	sd	s4,48(sp)
 326:	f456                	sd	s5,40(sp)
 328:	f05a                	sd	s6,32(sp)
 32a:	ec5e                	sd	s7,24(sp)
 32c:	1080                	addi	s0,sp,96
 32e:	8baa                	mv	s7,a0
 330:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 332:	892a                	mv	s2,a0
 334:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 336:	4aa9                	li	s5,10
 338:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 33a:	89a6                	mv	s3,s1
 33c:	2485                	addiw	s1,s1,1
 33e:	0344d863          	bge	s1,s4,36e <gets+0x56>
    cc = read(0, &c, 1);
 342:	4605                	li	a2,1
 344:	faf40593          	addi	a1,s0,-81
 348:	4501                	li	a0,0
 34a:	00000097          	auipc	ra,0x0
 34e:	1a0080e7          	jalr	416(ra) # 4ea <read>
    if(cc < 1)
 352:	00a05e63          	blez	a0,36e <gets+0x56>
    buf[i++] = c;
 356:	faf44783          	lbu	a5,-81(s0)
 35a:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 35e:	01578763          	beq	a5,s5,36c <gets+0x54>
 362:	0905                	addi	s2,s2,1
 364:	fd679be3          	bne	a5,s6,33a <gets+0x22>
  for(i=0; i+1 < max; ){
 368:	89a6                	mv	s3,s1
 36a:	a011                	j	36e <gets+0x56>
 36c:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 36e:	99de                	add	s3,s3,s7
 370:	00098023          	sb	zero,0(s3)
  return buf;
}
 374:	855e                	mv	a0,s7
 376:	60e6                	ld	ra,88(sp)
 378:	6446                	ld	s0,80(sp)
 37a:	64a6                	ld	s1,72(sp)
 37c:	6906                	ld	s2,64(sp)
 37e:	79e2                	ld	s3,56(sp)
 380:	7a42                	ld	s4,48(sp)
 382:	7aa2                	ld	s5,40(sp)
 384:	7b02                	ld	s6,32(sp)
 386:	6be2                	ld	s7,24(sp)
 388:	6125                	addi	sp,sp,96
 38a:	8082                	ret

000000000000038c <stat>:

int
stat(const char *n, struct stat *st)
{
 38c:	1101                	addi	sp,sp,-32
 38e:	ec06                	sd	ra,24(sp)
 390:	e822                	sd	s0,16(sp)
 392:	e426                	sd	s1,8(sp)
 394:	e04a                	sd	s2,0(sp)
 396:	1000                	addi	s0,sp,32
 398:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 39a:	4581                	li	a1,0
 39c:	00000097          	auipc	ra,0x0
 3a0:	176080e7          	jalr	374(ra) # 512 <open>
  if(fd < 0)
 3a4:	02054563          	bltz	a0,3ce <stat+0x42>
 3a8:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3aa:	85ca                	mv	a1,s2
 3ac:	00000097          	auipc	ra,0x0
 3b0:	17e080e7          	jalr	382(ra) # 52a <fstat>
 3b4:	892a                	mv	s2,a0
  close(fd);
 3b6:	8526                	mv	a0,s1
 3b8:	00000097          	auipc	ra,0x0
 3bc:	142080e7          	jalr	322(ra) # 4fa <close>
  return r;
}
 3c0:	854a                	mv	a0,s2
 3c2:	60e2                	ld	ra,24(sp)
 3c4:	6442                	ld	s0,16(sp)
 3c6:	64a2                	ld	s1,8(sp)
 3c8:	6902                	ld	s2,0(sp)
 3ca:	6105                	addi	sp,sp,32
 3cc:	8082                	ret
    return -1;
 3ce:	597d                	li	s2,-1
 3d0:	bfc5                	j	3c0 <stat+0x34>

00000000000003d2 <atoi>:

int
atoi(const char *s)
{
 3d2:	1141                	addi	sp,sp,-16
 3d4:	e422                	sd	s0,8(sp)
 3d6:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 3d8:	00054603          	lbu	a2,0(a0)
 3dc:	fd06079b          	addiw	a5,a2,-48
 3e0:	0ff7f793          	andi	a5,a5,255
 3e4:	4725                	li	a4,9
 3e6:	02f76963          	bltu	a4,a5,418 <atoi+0x46>
 3ea:	86aa                	mv	a3,a0
  n = 0;
 3ec:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 3ee:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 3f0:	0685                	addi	a3,a3,1
 3f2:	0025179b          	slliw	a5,a0,0x2
 3f6:	9fa9                	addw	a5,a5,a0
 3f8:	0017979b          	slliw	a5,a5,0x1
 3fc:	9fb1                	addw	a5,a5,a2
 3fe:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 402:	0006c603          	lbu	a2,0(a3)
 406:	fd06071b          	addiw	a4,a2,-48
 40a:	0ff77713          	andi	a4,a4,255
 40e:	fee5f1e3          	bgeu	a1,a4,3f0 <atoi+0x1e>
  return n;
}
 412:	6422                	ld	s0,8(sp)
 414:	0141                	addi	sp,sp,16
 416:	8082                	ret
  n = 0;
 418:	4501                	li	a0,0
 41a:	bfe5                	j	412 <atoi+0x40>

000000000000041c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 41c:	1141                	addi	sp,sp,-16
 41e:	e422                	sd	s0,8(sp)
 420:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 422:	02b57663          	bgeu	a0,a1,44e <memmove+0x32>
    while(n-- > 0)
 426:	02c05163          	blez	a2,448 <memmove+0x2c>
 42a:	fff6079b          	addiw	a5,a2,-1
 42e:	1782                	slli	a5,a5,0x20
 430:	9381                	srli	a5,a5,0x20
 432:	0785                	addi	a5,a5,1
 434:	97aa                	add	a5,a5,a0
  dst = vdst;
 436:	872a                	mv	a4,a0
      *dst++ = *src++;
 438:	0585                	addi	a1,a1,1
 43a:	0705                	addi	a4,a4,1
 43c:	fff5c683          	lbu	a3,-1(a1)
 440:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 444:	fee79ae3          	bne	a5,a4,438 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 448:	6422                	ld	s0,8(sp)
 44a:	0141                	addi	sp,sp,16
 44c:	8082                	ret
    dst += n;
 44e:	00c50733          	add	a4,a0,a2
    src += n;
 452:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 454:	fec05ae3          	blez	a2,448 <memmove+0x2c>
 458:	fff6079b          	addiw	a5,a2,-1
 45c:	1782                	slli	a5,a5,0x20
 45e:	9381                	srli	a5,a5,0x20
 460:	fff7c793          	not	a5,a5
 464:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 466:	15fd                	addi	a1,a1,-1
 468:	177d                	addi	a4,a4,-1
 46a:	0005c683          	lbu	a3,0(a1)
 46e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 472:	fee79ae3          	bne	a5,a4,466 <memmove+0x4a>
 476:	bfc9                	j	448 <memmove+0x2c>

0000000000000478 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 478:	1141                	addi	sp,sp,-16
 47a:	e422                	sd	s0,8(sp)
 47c:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 47e:	ca05                	beqz	a2,4ae <memcmp+0x36>
 480:	fff6069b          	addiw	a3,a2,-1
 484:	1682                	slli	a3,a3,0x20
 486:	9281                	srli	a3,a3,0x20
 488:	0685                	addi	a3,a3,1
 48a:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 48c:	00054783          	lbu	a5,0(a0)
 490:	0005c703          	lbu	a4,0(a1)
 494:	00e79863          	bne	a5,a4,4a4 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 498:	0505                	addi	a0,a0,1
    p2++;
 49a:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 49c:	fed518e3          	bne	a0,a3,48c <memcmp+0x14>
  }
  return 0;
 4a0:	4501                	li	a0,0
 4a2:	a019                	j	4a8 <memcmp+0x30>
      return *p1 - *p2;
 4a4:	40e7853b          	subw	a0,a5,a4
}
 4a8:	6422                	ld	s0,8(sp)
 4aa:	0141                	addi	sp,sp,16
 4ac:	8082                	ret
  return 0;
 4ae:	4501                	li	a0,0
 4b0:	bfe5                	j	4a8 <memcmp+0x30>

00000000000004b2 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4b2:	1141                	addi	sp,sp,-16
 4b4:	e406                	sd	ra,8(sp)
 4b6:	e022                	sd	s0,0(sp)
 4b8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4ba:	00000097          	auipc	ra,0x0
 4be:	f62080e7          	jalr	-158(ra) # 41c <memmove>
}
 4c2:	60a2                	ld	ra,8(sp)
 4c4:	6402                	ld	s0,0(sp)
 4c6:	0141                	addi	sp,sp,16
 4c8:	8082                	ret

00000000000004ca <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 4ca:	4885                	li	a7,1
 ecall
 4cc:	00000073          	ecall
 ret
 4d0:	8082                	ret

00000000000004d2 <exit>:
.global exit
exit:
 li a7, SYS_exit
 4d2:	4889                	li	a7,2
 ecall
 4d4:	00000073          	ecall
 ret
 4d8:	8082                	ret

00000000000004da <wait>:
.global wait
wait:
 li a7, SYS_wait
 4da:	488d                	li	a7,3
 ecall
 4dc:	00000073          	ecall
 ret
 4e0:	8082                	ret

00000000000004e2 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 4e2:	4891                	li	a7,4
 ecall
 4e4:	00000073          	ecall
 ret
 4e8:	8082                	ret

00000000000004ea <read>:
.global read
read:
 li a7, SYS_read
 4ea:	4895                	li	a7,5
 ecall
 4ec:	00000073          	ecall
 ret
 4f0:	8082                	ret

00000000000004f2 <write>:
.global write
write:
 li a7, SYS_write
 4f2:	48c1                	li	a7,16
 ecall
 4f4:	00000073          	ecall
 ret
 4f8:	8082                	ret

00000000000004fa <close>:
.global close
close:
 li a7, SYS_close
 4fa:	48d5                	li	a7,21
 ecall
 4fc:	00000073          	ecall
 ret
 500:	8082                	ret

0000000000000502 <kill>:
.global kill
kill:
 li a7, SYS_kill
 502:	4899                	li	a7,6
 ecall
 504:	00000073          	ecall
 ret
 508:	8082                	ret

000000000000050a <exec>:
.global exec
exec:
 li a7, SYS_exec
 50a:	489d                	li	a7,7
 ecall
 50c:	00000073          	ecall
 ret
 510:	8082                	ret

0000000000000512 <open>:
.global open
open:
 li a7, SYS_open
 512:	48bd                	li	a7,15
 ecall
 514:	00000073          	ecall
 ret
 518:	8082                	ret

000000000000051a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 51a:	48c5                	li	a7,17
 ecall
 51c:	00000073          	ecall
 ret
 520:	8082                	ret

0000000000000522 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 522:	48c9                	li	a7,18
 ecall
 524:	00000073          	ecall
 ret
 528:	8082                	ret

000000000000052a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 52a:	48a1                	li	a7,8
 ecall
 52c:	00000073          	ecall
 ret
 530:	8082                	ret

0000000000000532 <link>:
.global link
link:
 li a7, SYS_link
 532:	48cd                	li	a7,19
 ecall
 534:	00000073          	ecall
 ret
 538:	8082                	ret

000000000000053a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 53a:	48d1                	li	a7,20
 ecall
 53c:	00000073          	ecall
 ret
 540:	8082                	ret

0000000000000542 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 542:	48a5                	li	a7,9
 ecall
 544:	00000073          	ecall
 ret
 548:	8082                	ret

000000000000054a <dup>:
.global dup
dup:
 li a7, SYS_dup
 54a:	48a9                	li	a7,10
 ecall
 54c:	00000073          	ecall
 ret
 550:	8082                	ret

0000000000000552 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 552:	48ad                	li	a7,11
 ecall
 554:	00000073          	ecall
 ret
 558:	8082                	ret

000000000000055a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 55a:	48b1                	li	a7,12
 ecall
 55c:	00000073          	ecall
 ret
 560:	8082                	ret

0000000000000562 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 562:	48b5                	li	a7,13
 ecall
 564:	00000073          	ecall
 ret
 568:	8082                	ret

000000000000056a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 56a:	48b9                	li	a7,14
 ecall
 56c:	00000073          	ecall
 ret
 570:	8082                	ret

0000000000000572 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 572:	1101                	addi	sp,sp,-32
 574:	ec06                	sd	ra,24(sp)
 576:	e822                	sd	s0,16(sp)
 578:	1000                	addi	s0,sp,32
 57a:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 57e:	4605                	li	a2,1
 580:	fef40593          	addi	a1,s0,-17
 584:	00000097          	auipc	ra,0x0
 588:	f6e080e7          	jalr	-146(ra) # 4f2 <write>
}
 58c:	60e2                	ld	ra,24(sp)
 58e:	6442                	ld	s0,16(sp)
 590:	6105                	addi	sp,sp,32
 592:	8082                	ret

0000000000000594 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 594:	7139                	addi	sp,sp,-64
 596:	fc06                	sd	ra,56(sp)
 598:	f822                	sd	s0,48(sp)
 59a:	f426                	sd	s1,40(sp)
 59c:	f04a                	sd	s2,32(sp)
 59e:	ec4e                	sd	s3,24(sp)
 5a0:	0080                	addi	s0,sp,64
 5a2:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 5a4:	c299                	beqz	a3,5aa <printint+0x16>
 5a6:	0805c863          	bltz	a1,636 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 5aa:	2581                	sext.w	a1,a1
  neg = 0;
 5ac:	4881                	li	a7,0
 5ae:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 5b2:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 5b4:	2601                	sext.w	a2,a2
 5b6:	00000517          	auipc	a0,0x0
 5ba:	4b250513          	addi	a0,a0,1202 # a68 <digits>
 5be:	883a                	mv	a6,a4
 5c0:	2705                	addiw	a4,a4,1
 5c2:	02c5f7bb          	remuw	a5,a1,a2
 5c6:	1782                	slli	a5,a5,0x20
 5c8:	9381                	srli	a5,a5,0x20
 5ca:	97aa                	add	a5,a5,a0
 5cc:	0007c783          	lbu	a5,0(a5)
 5d0:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 5d4:	0005879b          	sext.w	a5,a1
 5d8:	02c5d5bb          	divuw	a1,a1,a2
 5dc:	0685                	addi	a3,a3,1
 5de:	fec7f0e3          	bgeu	a5,a2,5be <printint+0x2a>
  if(neg)
 5e2:	00088b63          	beqz	a7,5f8 <printint+0x64>
    buf[i++] = '-';
 5e6:	fd040793          	addi	a5,s0,-48
 5ea:	973e                	add	a4,a4,a5
 5ec:	02d00793          	li	a5,45
 5f0:	fef70823          	sb	a5,-16(a4)
 5f4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 5f8:	02e05863          	blez	a4,628 <printint+0x94>
 5fc:	fc040793          	addi	a5,s0,-64
 600:	00e78933          	add	s2,a5,a4
 604:	fff78993          	addi	s3,a5,-1
 608:	99ba                	add	s3,s3,a4
 60a:	377d                	addiw	a4,a4,-1
 60c:	1702                	slli	a4,a4,0x20
 60e:	9301                	srli	a4,a4,0x20
 610:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 614:	fff94583          	lbu	a1,-1(s2)
 618:	8526                	mv	a0,s1
 61a:	00000097          	auipc	ra,0x0
 61e:	f58080e7          	jalr	-168(ra) # 572 <putc>
  while(--i >= 0)
 622:	197d                	addi	s2,s2,-1
 624:	ff3918e3          	bne	s2,s3,614 <printint+0x80>
}
 628:	70e2                	ld	ra,56(sp)
 62a:	7442                	ld	s0,48(sp)
 62c:	74a2                	ld	s1,40(sp)
 62e:	7902                	ld	s2,32(sp)
 630:	69e2                	ld	s3,24(sp)
 632:	6121                	addi	sp,sp,64
 634:	8082                	ret
    x = -xx;
 636:	40b005bb          	negw	a1,a1
    neg = 1;
 63a:	4885                	li	a7,1
    x = -xx;
 63c:	bf8d                	j	5ae <printint+0x1a>

000000000000063e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 63e:	7119                	addi	sp,sp,-128
 640:	fc86                	sd	ra,120(sp)
 642:	f8a2                	sd	s0,112(sp)
 644:	f4a6                	sd	s1,104(sp)
 646:	f0ca                	sd	s2,96(sp)
 648:	ecce                	sd	s3,88(sp)
 64a:	e8d2                	sd	s4,80(sp)
 64c:	e4d6                	sd	s5,72(sp)
 64e:	e0da                	sd	s6,64(sp)
 650:	fc5e                	sd	s7,56(sp)
 652:	f862                	sd	s8,48(sp)
 654:	f466                	sd	s9,40(sp)
 656:	f06a                	sd	s10,32(sp)
 658:	ec6e                	sd	s11,24(sp)
 65a:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 65c:	0005c903          	lbu	s2,0(a1)
 660:	18090f63          	beqz	s2,7fe <vprintf+0x1c0>
 664:	8aaa                	mv	s5,a0
 666:	8b32                	mv	s6,a2
 668:	00158493          	addi	s1,a1,1
  state = 0;
 66c:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 66e:	02500a13          	li	s4,37
      if(c == 'd'){
 672:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 676:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 67a:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 67e:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 682:	00000b97          	auipc	s7,0x0
 686:	3e6b8b93          	addi	s7,s7,998 # a68 <digits>
 68a:	a839                	j	6a8 <vprintf+0x6a>
        putc(fd, c);
 68c:	85ca                	mv	a1,s2
 68e:	8556                	mv	a0,s5
 690:	00000097          	auipc	ra,0x0
 694:	ee2080e7          	jalr	-286(ra) # 572 <putc>
 698:	a019                	j	69e <vprintf+0x60>
    } else if(state == '%'){
 69a:	01498f63          	beq	s3,s4,6b8 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 69e:	0485                	addi	s1,s1,1
 6a0:	fff4c903          	lbu	s2,-1(s1)
 6a4:	14090d63          	beqz	s2,7fe <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 6a8:	0009079b          	sext.w	a5,s2
    if(state == 0){
 6ac:	fe0997e3          	bnez	s3,69a <vprintf+0x5c>
      if(c == '%'){
 6b0:	fd479ee3          	bne	a5,s4,68c <vprintf+0x4e>
        state = '%';
 6b4:	89be                	mv	s3,a5
 6b6:	b7e5                	j	69e <vprintf+0x60>
      if(c == 'd'){
 6b8:	05878063          	beq	a5,s8,6f8 <vprintf+0xba>
      } else if(c == 'l') {
 6bc:	05978c63          	beq	a5,s9,714 <vprintf+0xd6>
      } else if(c == 'x') {
 6c0:	07a78863          	beq	a5,s10,730 <vprintf+0xf2>
      } else if(c == 'p') {
 6c4:	09b78463          	beq	a5,s11,74c <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 6c8:	07300713          	li	a4,115
 6cc:	0ce78663          	beq	a5,a4,798 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 6d0:	06300713          	li	a4,99
 6d4:	0ee78e63          	beq	a5,a4,7d0 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 6d8:	11478863          	beq	a5,s4,7e8 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 6dc:	85d2                	mv	a1,s4
 6de:	8556                	mv	a0,s5
 6e0:	00000097          	auipc	ra,0x0
 6e4:	e92080e7          	jalr	-366(ra) # 572 <putc>
        putc(fd, c);
 6e8:	85ca                	mv	a1,s2
 6ea:	8556                	mv	a0,s5
 6ec:	00000097          	auipc	ra,0x0
 6f0:	e86080e7          	jalr	-378(ra) # 572 <putc>
      }
      state = 0;
 6f4:	4981                	li	s3,0
 6f6:	b765                	j	69e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 6f8:	008b0913          	addi	s2,s6,8
 6fc:	4685                	li	a3,1
 6fe:	4629                	li	a2,10
 700:	000b2583          	lw	a1,0(s6)
 704:	8556                	mv	a0,s5
 706:	00000097          	auipc	ra,0x0
 70a:	e8e080e7          	jalr	-370(ra) # 594 <printint>
 70e:	8b4a                	mv	s6,s2
      state = 0;
 710:	4981                	li	s3,0
 712:	b771                	j	69e <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 714:	008b0913          	addi	s2,s6,8
 718:	4681                	li	a3,0
 71a:	4629                	li	a2,10
 71c:	000b2583          	lw	a1,0(s6)
 720:	8556                	mv	a0,s5
 722:	00000097          	auipc	ra,0x0
 726:	e72080e7          	jalr	-398(ra) # 594 <printint>
 72a:	8b4a                	mv	s6,s2
      state = 0;
 72c:	4981                	li	s3,0
 72e:	bf85                	j	69e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 730:	008b0913          	addi	s2,s6,8
 734:	4681                	li	a3,0
 736:	4641                	li	a2,16
 738:	000b2583          	lw	a1,0(s6)
 73c:	8556                	mv	a0,s5
 73e:	00000097          	auipc	ra,0x0
 742:	e56080e7          	jalr	-426(ra) # 594 <printint>
 746:	8b4a                	mv	s6,s2
      state = 0;
 748:	4981                	li	s3,0
 74a:	bf91                	j	69e <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 74c:	008b0793          	addi	a5,s6,8
 750:	f8f43423          	sd	a5,-120(s0)
 754:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 758:	03000593          	li	a1,48
 75c:	8556                	mv	a0,s5
 75e:	00000097          	auipc	ra,0x0
 762:	e14080e7          	jalr	-492(ra) # 572 <putc>
  putc(fd, 'x');
 766:	85ea                	mv	a1,s10
 768:	8556                	mv	a0,s5
 76a:	00000097          	auipc	ra,0x0
 76e:	e08080e7          	jalr	-504(ra) # 572 <putc>
 772:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 774:	03c9d793          	srli	a5,s3,0x3c
 778:	97de                	add	a5,a5,s7
 77a:	0007c583          	lbu	a1,0(a5)
 77e:	8556                	mv	a0,s5
 780:	00000097          	auipc	ra,0x0
 784:	df2080e7          	jalr	-526(ra) # 572 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 788:	0992                	slli	s3,s3,0x4
 78a:	397d                	addiw	s2,s2,-1
 78c:	fe0914e3          	bnez	s2,774 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 790:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 794:	4981                	li	s3,0
 796:	b721                	j	69e <vprintf+0x60>
        s = va_arg(ap, char*);
 798:	008b0993          	addi	s3,s6,8
 79c:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 7a0:	02090163          	beqz	s2,7c2 <vprintf+0x184>
        while(*s != 0){
 7a4:	00094583          	lbu	a1,0(s2)
 7a8:	c9a1                	beqz	a1,7f8 <vprintf+0x1ba>
          putc(fd, *s);
 7aa:	8556                	mv	a0,s5
 7ac:	00000097          	auipc	ra,0x0
 7b0:	dc6080e7          	jalr	-570(ra) # 572 <putc>
          s++;
 7b4:	0905                	addi	s2,s2,1
        while(*s != 0){
 7b6:	00094583          	lbu	a1,0(s2)
 7ba:	f9e5                	bnez	a1,7aa <vprintf+0x16c>
        s = va_arg(ap, char*);
 7bc:	8b4e                	mv	s6,s3
      state = 0;
 7be:	4981                	li	s3,0
 7c0:	bdf9                	j	69e <vprintf+0x60>
          s = "(null)";
 7c2:	00000917          	auipc	s2,0x0
 7c6:	29e90913          	addi	s2,s2,670 # a60 <malloc+0x158>
        while(*s != 0){
 7ca:	02800593          	li	a1,40
 7ce:	bff1                	j	7aa <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 7d0:	008b0913          	addi	s2,s6,8
 7d4:	000b4583          	lbu	a1,0(s6)
 7d8:	8556                	mv	a0,s5
 7da:	00000097          	auipc	ra,0x0
 7de:	d98080e7          	jalr	-616(ra) # 572 <putc>
 7e2:	8b4a                	mv	s6,s2
      state = 0;
 7e4:	4981                	li	s3,0
 7e6:	bd65                	j	69e <vprintf+0x60>
        putc(fd, c);
 7e8:	85d2                	mv	a1,s4
 7ea:	8556                	mv	a0,s5
 7ec:	00000097          	auipc	ra,0x0
 7f0:	d86080e7          	jalr	-634(ra) # 572 <putc>
      state = 0;
 7f4:	4981                	li	s3,0
 7f6:	b565                	j	69e <vprintf+0x60>
        s = va_arg(ap, char*);
 7f8:	8b4e                	mv	s6,s3
      state = 0;
 7fa:	4981                	li	s3,0
 7fc:	b54d                	j	69e <vprintf+0x60>
    }
  }
}
 7fe:	70e6                	ld	ra,120(sp)
 800:	7446                	ld	s0,112(sp)
 802:	74a6                	ld	s1,104(sp)
 804:	7906                	ld	s2,96(sp)
 806:	69e6                	ld	s3,88(sp)
 808:	6a46                	ld	s4,80(sp)
 80a:	6aa6                	ld	s5,72(sp)
 80c:	6b06                	ld	s6,64(sp)
 80e:	7be2                	ld	s7,56(sp)
 810:	7c42                	ld	s8,48(sp)
 812:	7ca2                	ld	s9,40(sp)
 814:	7d02                	ld	s10,32(sp)
 816:	6de2                	ld	s11,24(sp)
 818:	6109                	addi	sp,sp,128
 81a:	8082                	ret

000000000000081c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 81c:	715d                	addi	sp,sp,-80
 81e:	ec06                	sd	ra,24(sp)
 820:	e822                	sd	s0,16(sp)
 822:	1000                	addi	s0,sp,32
 824:	e010                	sd	a2,0(s0)
 826:	e414                	sd	a3,8(s0)
 828:	e818                	sd	a4,16(s0)
 82a:	ec1c                	sd	a5,24(s0)
 82c:	03043023          	sd	a6,32(s0)
 830:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 834:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 838:	8622                	mv	a2,s0
 83a:	00000097          	auipc	ra,0x0
 83e:	e04080e7          	jalr	-508(ra) # 63e <vprintf>
}
 842:	60e2                	ld	ra,24(sp)
 844:	6442                	ld	s0,16(sp)
 846:	6161                	addi	sp,sp,80
 848:	8082                	ret

000000000000084a <printf>:

void
printf(const char *fmt, ...)
{
 84a:	711d                	addi	sp,sp,-96
 84c:	ec06                	sd	ra,24(sp)
 84e:	e822                	sd	s0,16(sp)
 850:	1000                	addi	s0,sp,32
 852:	e40c                	sd	a1,8(s0)
 854:	e810                	sd	a2,16(s0)
 856:	ec14                	sd	a3,24(s0)
 858:	f018                	sd	a4,32(s0)
 85a:	f41c                	sd	a5,40(s0)
 85c:	03043823          	sd	a6,48(s0)
 860:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 864:	00840613          	addi	a2,s0,8
 868:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 86c:	85aa                	mv	a1,a0
 86e:	4505                	li	a0,1
 870:	00000097          	auipc	ra,0x0
 874:	dce080e7          	jalr	-562(ra) # 63e <vprintf>
}
 878:	60e2                	ld	ra,24(sp)
 87a:	6442                	ld	s0,16(sp)
 87c:	6125                	addi	sp,sp,96
 87e:	8082                	ret

0000000000000880 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 880:	1141                	addi	sp,sp,-16
 882:	e422                	sd	s0,8(sp)
 884:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 886:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 88a:	00000797          	auipc	a5,0x0
 88e:	1f67b783          	ld	a5,502(a5) # a80 <freep>
 892:	a805                	j	8c2 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 894:	4618                	lw	a4,8(a2)
 896:	9db9                	addw	a1,a1,a4
 898:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 89c:	6398                	ld	a4,0(a5)
 89e:	6318                	ld	a4,0(a4)
 8a0:	fee53823          	sd	a4,-16(a0)
 8a4:	a091                	j	8e8 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8a6:	ff852703          	lw	a4,-8(a0)
 8aa:	9e39                	addw	a2,a2,a4
 8ac:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 8ae:	ff053703          	ld	a4,-16(a0)
 8b2:	e398                	sd	a4,0(a5)
 8b4:	a099                	j	8fa <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8b6:	6398                	ld	a4,0(a5)
 8b8:	00e7e463          	bltu	a5,a4,8c0 <free+0x40>
 8bc:	00e6ea63          	bltu	a3,a4,8d0 <free+0x50>
{
 8c0:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8c2:	fed7fae3          	bgeu	a5,a3,8b6 <free+0x36>
 8c6:	6398                	ld	a4,0(a5)
 8c8:	00e6e463          	bltu	a3,a4,8d0 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8cc:	fee7eae3          	bltu	a5,a4,8c0 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 8d0:	ff852583          	lw	a1,-8(a0)
 8d4:	6390                	ld	a2,0(a5)
 8d6:	02059713          	slli	a4,a1,0x20
 8da:	9301                	srli	a4,a4,0x20
 8dc:	0712                	slli	a4,a4,0x4
 8de:	9736                	add	a4,a4,a3
 8e0:	fae60ae3          	beq	a2,a4,894 <free+0x14>
    bp->s.ptr = p->s.ptr;
 8e4:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 8e8:	4790                	lw	a2,8(a5)
 8ea:	02061713          	slli	a4,a2,0x20
 8ee:	9301                	srli	a4,a4,0x20
 8f0:	0712                	slli	a4,a4,0x4
 8f2:	973e                	add	a4,a4,a5
 8f4:	fae689e3          	beq	a3,a4,8a6 <free+0x26>
  } else
    p->s.ptr = bp;
 8f8:	e394                	sd	a3,0(a5)
  freep = p;
 8fa:	00000717          	auipc	a4,0x0
 8fe:	18f73323          	sd	a5,390(a4) # a80 <freep>
}
 902:	6422                	ld	s0,8(sp)
 904:	0141                	addi	sp,sp,16
 906:	8082                	ret

0000000000000908 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 908:	7139                	addi	sp,sp,-64
 90a:	fc06                	sd	ra,56(sp)
 90c:	f822                	sd	s0,48(sp)
 90e:	f426                	sd	s1,40(sp)
 910:	f04a                	sd	s2,32(sp)
 912:	ec4e                	sd	s3,24(sp)
 914:	e852                	sd	s4,16(sp)
 916:	e456                	sd	s5,8(sp)
 918:	e05a                	sd	s6,0(sp)
 91a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 91c:	02051493          	slli	s1,a0,0x20
 920:	9081                	srli	s1,s1,0x20
 922:	04bd                	addi	s1,s1,15
 924:	8091                	srli	s1,s1,0x4
 926:	0014899b          	addiw	s3,s1,1
 92a:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 92c:	00000517          	auipc	a0,0x0
 930:	15453503          	ld	a0,340(a0) # a80 <freep>
 934:	c515                	beqz	a0,960 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 936:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 938:	4798                	lw	a4,8(a5)
 93a:	02977f63          	bgeu	a4,s1,978 <malloc+0x70>
 93e:	8a4e                	mv	s4,s3
 940:	0009871b          	sext.w	a4,s3
 944:	6685                	lui	a3,0x1
 946:	00d77363          	bgeu	a4,a3,94c <malloc+0x44>
 94a:	6a05                	lui	s4,0x1
 94c:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 950:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 954:	00000917          	auipc	s2,0x0
 958:	12c90913          	addi	s2,s2,300 # a80 <freep>
  if(p == (char*)-1)
 95c:	5afd                	li	s5,-1
 95e:	a88d                	j	9d0 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 960:	00000797          	auipc	a5,0x0
 964:	12878793          	addi	a5,a5,296 # a88 <base>
 968:	00000717          	auipc	a4,0x0
 96c:	10f73c23          	sd	a5,280(a4) # a80 <freep>
 970:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 972:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 976:	b7e1                	j	93e <malloc+0x36>
      if(p->s.size == nunits)
 978:	02e48b63          	beq	s1,a4,9ae <malloc+0xa6>
        p->s.size -= nunits;
 97c:	4137073b          	subw	a4,a4,s3
 980:	c798                	sw	a4,8(a5)
        p += p->s.size;
 982:	1702                	slli	a4,a4,0x20
 984:	9301                	srli	a4,a4,0x20
 986:	0712                	slli	a4,a4,0x4
 988:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 98a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 98e:	00000717          	auipc	a4,0x0
 992:	0ea73923          	sd	a0,242(a4) # a80 <freep>
      return (void*)(p + 1);
 996:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 99a:	70e2                	ld	ra,56(sp)
 99c:	7442                	ld	s0,48(sp)
 99e:	74a2                	ld	s1,40(sp)
 9a0:	7902                	ld	s2,32(sp)
 9a2:	69e2                	ld	s3,24(sp)
 9a4:	6a42                	ld	s4,16(sp)
 9a6:	6aa2                	ld	s5,8(sp)
 9a8:	6b02                	ld	s6,0(sp)
 9aa:	6121                	addi	sp,sp,64
 9ac:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 9ae:	6398                	ld	a4,0(a5)
 9b0:	e118                	sd	a4,0(a0)
 9b2:	bff1                	j	98e <malloc+0x86>
  hp->s.size = nu;
 9b4:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 9b8:	0541                	addi	a0,a0,16
 9ba:	00000097          	auipc	ra,0x0
 9be:	ec6080e7          	jalr	-314(ra) # 880 <free>
  return freep;
 9c2:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 9c6:	d971                	beqz	a0,99a <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9c8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9ca:	4798                	lw	a4,8(a5)
 9cc:	fa9776e3          	bgeu	a4,s1,978 <malloc+0x70>
    if(p == freep)
 9d0:	00093703          	ld	a4,0(s2)
 9d4:	853e                	mv	a0,a5
 9d6:	fef719e3          	bne	a4,a5,9c8 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 9da:	8552                	mv	a0,s4
 9dc:	00000097          	auipc	ra,0x0
 9e0:	b7e080e7          	jalr	-1154(ra) # 55a <sbrk>
  if(p == (char*)-1)
 9e4:	fd5518e3          	bne	a0,s5,9b4 <malloc+0xac>
        return 0;
 9e8:	4501                	li	a0,0
 9ea:	bf45                	j	99a <malloc+0x92>
