
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	d1478793          	addi	a5,a5,-748 # 80005d70 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd37ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e9e78793          	addi	a5,a5,-354 # 80000f44 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b8a080e7          	jalr	-1142(ra) # 80000c96 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	41a080e7          	jalr	1050(ra) # 80002540 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00001097          	auipc	ra,0x1
    8000013a:	830080e7          	jalr	-2000(ra) # 80000966 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	bfc080e7          	jalr	-1028(ra) # 80000d4a <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	af8080e7          	jalr	-1288(ra) # 80000c96 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	896080e7          	jalr	-1898(ra) # 80001a64 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	0aa080e7          	jalr	170(ra) # 80002288 <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	2d0080e7          	jalr	720(ra) # 800024ea <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	b14080e7          	jalr	-1260(ra) # 80000d4a <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	afe080e7          	jalr	-1282(ra) # 80000d4a <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	5ea080e7          	jalr	1514(ra) # 80000880 <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	5d8080e7          	jalr	1496(ra) # 80000880 <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	5cc080e7          	jalr	1484(ra) # 80000880 <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	5c2080e7          	jalr	1474(ra) # 80000880 <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	9b8080e7          	jalr	-1608(ra) # 80000c96 <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	29a080e7          	jalr	666(ra) # 80002596 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	a3e080e7          	jalr	-1474(ra) # 80000d4a <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	fbe080e7          	jalr	-66(ra) # 8000240e <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	794080e7          	jalr	1940(ra) # 80000c06 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	3b6080e7          	jalr	950(ra) # 80000830 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00026797          	auipc	a5,0x26
    80000486:	32e78793          	addi	a5,a5,814 # 800267b0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b9460613          	addi	a2,a2,-1132 # 80008058 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000552:	00011497          	auipc	s1,0x11
    80000556:	38648493          	addi	s1,s1,902 # 800118d8 <pr>
    8000055a:	00008597          	auipc	a1,0x8
    8000055e:	abe58593          	addi	a1,a1,-1346 # 80008018 <etext+0x18>
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	6a2080e7          	jalr	1698(ra) # 80000c06 <initlock>
  pr.locking = 1;
    8000056c:	4785                	li	a5,1
    8000056e:	cc9c                	sw	a5,24(s1)
}
    80000570:	60e2                	ld	ra,24(sp)
    80000572:	6442                	ld	s0,16(sp)
    80000574:	64a2                	ld	s1,8(sp)
    80000576:	6105                	addi	sp,sp,32
    80000578:	8082                	ret

000000008000057a <backtrace>:


void
backtrace(void)
{
    8000057a:	7139                	addi	sp,sp,-64
    8000057c:	fc06                	sd	ra,56(sp)
    8000057e:	f822                	sd	s0,48(sp)
    80000580:	f426                	sd	s1,40(sp)
    80000582:	f04a                	sd	s2,32(sp)
    80000584:	ec4e                	sd	s3,24(sp)
    80000586:	e852                	sd	s4,16(sp)
    80000588:	e456                	sd	s5,8(sp)
    8000058a:	0080                	addi	s0,sp,64
  printf("backtrace:\n");
    8000058c:	00008517          	auipc	a0,0x8
    80000590:	a9450513          	addi	a0,a0,-1388 # 80008020 <etext+0x20>
    80000594:	00000097          	auipc	ra,0x0
    80000598:	0b6080e7          	jalr	182(ra) # 8000064a <printf>
  asm volatile("mv %0, s0" : "=r" (x) );//这是一个内联汇编表达式，用于将寄存器s0的值移动到变量x中
    8000059c:	84a2                	mv	s1,s0
  uint64 addr = r_fp();//获取当前函数栈帧的帧指针
  while (PGROUNDUP(addr) - PGROUNDDOWN(addr) == PGSIZE)
    8000059e:	6685                	lui	a3,0x1
    800005a0:	fff68793          	addi	a5,a3,-1 # fff <_entry-0x7ffff001>
    800005a4:	97a6                	add	a5,a5,s1
    800005a6:	777d                	lui	a4,0xfffff
    800005a8:	8ff9                	and	a5,a5,a4
    800005aa:	8f65                	and	a4,a4,s1
    800005ac:	8f99                	sub	a5,a5,a4
    800005ae:	02d79c63          	bne	a5,a3,800005e6 <backtrace+0x6c>
  {
    uint64 ret_addr = *(uint64 *)(addr - 8);
    printf("%p\n", ret_addr);//打印ret_addr的值
    800005b2:	00008a97          	auipc	s5,0x8
    800005b6:	a7ea8a93          	addi	s5,s5,-1410 # 80008030 <etext+0x30>
  while (PGROUNDUP(addr) - PGROUNDDOWN(addr) == PGSIZE)
    800005ba:	6985                	lui	s3,0x1
    800005bc:	fff98a13          	addi	s4,s3,-1 # fff <_entry-0x7ffff001>
    800005c0:	797d                	lui	s2,0xfffff
    printf("%p\n", ret_addr);//打印ret_addr的值
    800005c2:	ff84b583          	ld	a1,-8(s1)
    800005c6:	8556                	mv	a0,s5
    800005c8:	00000097          	auipc	ra,0x0
    800005cc:	082080e7          	jalr	130(ra) # 8000064a <printf>
    addr = *((uint64 *)(addr - 16));//获取下一个栈帧的帧指针
    800005d0:	ff04b483          	ld	s1,-16(s1)
  while (PGROUNDUP(addr) - PGROUNDDOWN(addr) == PGSIZE)
    800005d4:	014487b3          	add	a5,s1,s4
    800005d8:	0127f7b3          	and	a5,a5,s2
    800005dc:	0124f733          	and	a4,s1,s2
    800005e0:	8f99                	sub	a5,a5,a4
    800005e2:	ff3780e3          	beq	a5,s3,800005c2 <backtrace+0x48>
  }
}
    800005e6:	70e2                	ld	ra,56(sp)
    800005e8:	7442                	ld	s0,48(sp)
    800005ea:	74a2                	ld	s1,40(sp)
    800005ec:	7902                	ld	s2,32(sp)
    800005ee:	69e2                	ld	s3,24(sp)
    800005f0:	6a42                	ld	s4,16(sp)
    800005f2:	6aa2                	ld	s5,8(sp)
    800005f4:	6121                	addi	sp,sp,64
    800005f6:	8082                	ret

00000000800005f8 <panic>:
{
    800005f8:	1101                	addi	sp,sp,-32
    800005fa:	ec06                	sd	ra,24(sp)
    800005fc:	e822                	sd	s0,16(sp)
    800005fe:	e426                	sd	s1,8(sp)
    80000600:	1000                	addi	s0,sp,32
    80000602:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000604:	00011797          	auipc	a5,0x11
    80000608:	2e07a623          	sw	zero,748(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a2c50513          	addi	a0,a0,-1492 # 80008038 <etext+0x38>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	036080e7          	jalr	54(ra) # 8000064a <printf>
  printf(s);
    8000061c:	8526                	mv	a0,s1
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	02c080e7          	jalr	44(ra) # 8000064a <printf>
  printf("\n");
    80000626:	00008517          	auipc	a0,0x8
    8000062a:	aba50513          	addi	a0,a0,-1350 # 800080e0 <digits+0x88>
    8000062e:	00000097          	auipc	ra,0x0
    80000632:	01c080e7          	jalr	28(ra) # 8000064a <printf>
  backtrace(); // 调用backtrace函数
    80000636:	00000097          	auipc	ra,0x0
    8000063a:	f44080e7          	jalr	-188(ra) # 8000057a <backtrace>
  panicked = 1; // freeze uart output from other CPUs
    8000063e:	4785                	li	a5,1
    80000640:	00009717          	auipc	a4,0x9
    80000644:	9cf72023          	sw	a5,-1600(a4) # 80009000 <panicked>
  for(;;)
    80000648:	a001                	j	80000648 <panic+0x50>

000000008000064a <printf>:
{
    8000064a:	7131                	addi	sp,sp,-192
    8000064c:	fc86                	sd	ra,120(sp)
    8000064e:	f8a2                	sd	s0,112(sp)
    80000650:	f4a6                	sd	s1,104(sp)
    80000652:	f0ca                	sd	s2,96(sp)
    80000654:	ecce                	sd	s3,88(sp)
    80000656:	e8d2                	sd	s4,80(sp)
    80000658:	e4d6                	sd	s5,72(sp)
    8000065a:	e0da                	sd	s6,64(sp)
    8000065c:	fc5e                	sd	s7,56(sp)
    8000065e:	f862                	sd	s8,48(sp)
    80000660:	f466                	sd	s9,40(sp)
    80000662:	f06a                	sd	s10,32(sp)
    80000664:	ec6e                	sd	s11,24(sp)
    80000666:	0100                	addi	s0,sp,128
    80000668:	8a2a                	mv	s4,a0
    8000066a:	e40c                	sd	a1,8(s0)
    8000066c:	e810                	sd	a2,16(s0)
    8000066e:	ec14                	sd	a3,24(s0)
    80000670:	f018                	sd	a4,32(s0)
    80000672:	f41c                	sd	a5,40(s0)
    80000674:	03043823          	sd	a6,48(s0)
    80000678:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    8000067c:	00011d97          	auipc	s11,0x11
    80000680:	274dad83          	lw	s11,628(s11) # 800118f0 <pr+0x18>
  if(locking)
    80000684:	020d9b63          	bnez	s11,800006ba <printf+0x70>
  if (fmt == 0)
    80000688:	040a0263          	beqz	s4,800006cc <printf+0x82>
  va_start(ap, fmt);
    8000068c:	00840793          	addi	a5,s0,8
    80000690:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000694:	000a4503          	lbu	a0,0(s4)
    80000698:	16050263          	beqz	a0,800007fc <printf+0x1b2>
    8000069c:	4481                	li	s1,0
    if(c != '%'){
    8000069e:	02500a93          	li	s5,37
    switch(c){
    800006a2:	07000b13          	li	s6,112
  consputc('x');
    800006a6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006a8:	00008b97          	auipc	s7,0x8
    800006ac:	9b0b8b93          	addi	s7,s7,-1616 # 80008058 <digits>
    switch(c){
    800006b0:	07300c93          	li	s9,115
    800006b4:	06400c13          	li	s8,100
    800006b8:	a82d                	j	800006f2 <printf+0xa8>
    acquire(&pr.lock);
    800006ba:	00011517          	auipc	a0,0x11
    800006be:	21e50513          	addi	a0,a0,542 # 800118d8 <pr>
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	5d4080e7          	jalr	1492(ra) # 80000c96 <acquire>
    800006ca:	bf7d                	j	80000688 <printf+0x3e>
    panic("null fmt");
    800006cc:	00008517          	auipc	a0,0x8
    800006d0:	97c50513          	addi	a0,a0,-1668 # 80008048 <etext+0x48>
    800006d4:	00000097          	auipc	ra,0x0
    800006d8:	f24080e7          	jalr	-220(ra) # 800005f8 <panic>
      consputc(c);
    800006dc:	00000097          	auipc	ra,0x0
    800006e0:	baa080e7          	jalr	-1110(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800006e4:	2485                	addiw	s1,s1,1
    800006e6:	009a07b3          	add	a5,s4,s1
    800006ea:	0007c503          	lbu	a0,0(a5)
    800006ee:	10050763          	beqz	a0,800007fc <printf+0x1b2>
    if(c != '%'){
    800006f2:	ff5515e3          	bne	a0,s5,800006dc <printf+0x92>
    c = fmt[++i] & 0xff;
    800006f6:	2485                	addiw	s1,s1,1
    800006f8:	009a07b3          	add	a5,s4,s1
    800006fc:	0007c783          	lbu	a5,0(a5)
    80000700:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000704:	cfe5                	beqz	a5,800007fc <printf+0x1b2>
    switch(c){
    80000706:	05678a63          	beq	a5,s6,8000075a <printf+0x110>
    8000070a:	02fb7663          	bgeu	s6,a5,80000736 <printf+0xec>
    8000070e:	09978963          	beq	a5,s9,800007a0 <printf+0x156>
    80000712:	07800713          	li	a4,120
    80000716:	0ce79863          	bne	a5,a4,800007e6 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000071a:	f8843783          	ld	a5,-120(s0)
    8000071e:	00878713          	addi	a4,a5,8
    80000722:	f8e43423          	sd	a4,-120(s0)
    80000726:	4605                	li	a2,1
    80000728:	85ea                	mv	a1,s10
    8000072a:	4388                	lw	a0,0(a5)
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	d7a080e7          	jalr	-646(ra) # 800004a6 <printint>
      break;
    80000734:	bf45                	j	800006e4 <printf+0x9a>
    switch(c){
    80000736:	0b578263          	beq	a5,s5,800007da <printf+0x190>
    8000073a:	0b879663          	bne	a5,s8,800007e6 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000073e:	f8843783          	ld	a5,-120(s0)
    80000742:	00878713          	addi	a4,a5,8
    80000746:	f8e43423          	sd	a4,-120(s0)
    8000074a:	4605                	li	a2,1
    8000074c:	45a9                	li	a1,10
    8000074e:	4388                	lw	a0,0(a5)
    80000750:	00000097          	auipc	ra,0x0
    80000754:	d56080e7          	jalr	-682(ra) # 800004a6 <printint>
      break;
    80000758:	b771                	j	800006e4 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000075a:	f8843783          	ld	a5,-120(s0)
    8000075e:	00878713          	addi	a4,a5,8
    80000762:	f8e43423          	sd	a4,-120(s0)
    80000766:	0007b983          	ld	s3,0(a5)
  consputc('0');
    8000076a:	03000513          	li	a0,48
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	b18080e7          	jalr	-1256(ra) # 80000286 <consputc>
  consputc('x');
    80000776:	07800513          	li	a0,120
    8000077a:	00000097          	auipc	ra,0x0
    8000077e:	b0c080e7          	jalr	-1268(ra) # 80000286 <consputc>
    80000782:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000784:	03c9d793          	srli	a5,s3,0x3c
    80000788:	97de                	add	a5,a5,s7
    8000078a:	0007c503          	lbu	a0,0(a5)
    8000078e:	00000097          	auipc	ra,0x0
    80000792:	af8080e7          	jalr	-1288(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000796:	0992                	slli	s3,s3,0x4
    80000798:	397d                	addiw	s2,s2,-1
    8000079a:	fe0915e3          	bnez	s2,80000784 <printf+0x13a>
    8000079e:	b799                	j	800006e4 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800007a0:	f8843783          	ld	a5,-120(s0)
    800007a4:	00878713          	addi	a4,a5,8
    800007a8:	f8e43423          	sd	a4,-120(s0)
    800007ac:	0007b903          	ld	s2,0(a5)
    800007b0:	00090e63          	beqz	s2,800007cc <printf+0x182>
      for(; *s; s++)
    800007b4:	00094503          	lbu	a0,0(s2) # fffffffffffff000 <end+0xffffffff7ffd4000>
    800007b8:	d515                	beqz	a0,800006e4 <printf+0x9a>
        consputc(*s);
    800007ba:	00000097          	auipc	ra,0x0
    800007be:	acc080e7          	jalr	-1332(ra) # 80000286 <consputc>
      for(; *s; s++)
    800007c2:	0905                	addi	s2,s2,1
    800007c4:	00094503          	lbu	a0,0(s2)
    800007c8:	f96d                	bnez	a0,800007ba <printf+0x170>
    800007ca:	bf29                	j	800006e4 <printf+0x9a>
        s = "(null)";
    800007cc:	00008917          	auipc	s2,0x8
    800007d0:	87490913          	addi	s2,s2,-1932 # 80008040 <etext+0x40>
      for(; *s; s++)
    800007d4:	02800513          	li	a0,40
    800007d8:	b7cd                	j	800007ba <printf+0x170>
      consputc('%');
    800007da:	8556                	mv	a0,s5
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	aaa080e7          	jalr	-1366(ra) # 80000286 <consputc>
      break;
    800007e4:	b701                	j	800006e4 <printf+0x9a>
      consputc('%');
    800007e6:	8556                	mv	a0,s5
    800007e8:	00000097          	auipc	ra,0x0
    800007ec:	a9e080e7          	jalr	-1378(ra) # 80000286 <consputc>
      consputc(c);
    800007f0:	854a                	mv	a0,s2
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	a94080e7          	jalr	-1388(ra) # 80000286 <consputc>
      break;
    800007fa:	b5ed                	j	800006e4 <printf+0x9a>
  if(locking)
    800007fc:	020d9163          	bnez	s11,8000081e <printf+0x1d4>
}
    80000800:	70e6                	ld	ra,120(sp)
    80000802:	7446                	ld	s0,112(sp)
    80000804:	74a6                	ld	s1,104(sp)
    80000806:	7906                	ld	s2,96(sp)
    80000808:	69e6                	ld	s3,88(sp)
    8000080a:	6a46                	ld	s4,80(sp)
    8000080c:	6aa6                	ld	s5,72(sp)
    8000080e:	6b06                	ld	s6,64(sp)
    80000810:	7be2                	ld	s7,56(sp)
    80000812:	7c42                	ld	s8,48(sp)
    80000814:	7ca2                	ld	s9,40(sp)
    80000816:	7d02                	ld	s10,32(sp)
    80000818:	6de2                	ld	s11,24(sp)
    8000081a:	6129                	addi	sp,sp,192
    8000081c:	8082                	ret
    release(&pr.lock);
    8000081e:	00011517          	auipc	a0,0x11
    80000822:	0ba50513          	addi	a0,a0,186 # 800118d8 <pr>
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	524080e7          	jalr	1316(ra) # 80000d4a <release>
}
    8000082e:	bfc9                	j	80000800 <printf+0x1b6>

0000000080000830 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000830:	1141                	addi	sp,sp,-16
    80000832:	e406                	sd	ra,8(sp)
    80000834:	e022                	sd	s0,0(sp)
    80000836:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000838:	100007b7          	lui	a5,0x10000
    8000083c:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000840:	f8000713          	li	a4,-128
    80000844:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000848:	470d                	li	a4,3
    8000084a:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    8000084e:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000852:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000856:	469d                	li	a3,7
    80000858:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000085c:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000860:	00008597          	auipc	a1,0x8
    80000864:	81058593          	addi	a1,a1,-2032 # 80008070 <digits+0x18>
    80000868:	00011517          	auipc	a0,0x11
    8000086c:	09050513          	addi	a0,a0,144 # 800118f8 <uart_tx_lock>
    80000870:	00000097          	auipc	ra,0x0
    80000874:	396080e7          	jalr	918(ra) # 80000c06 <initlock>
}
    80000878:	60a2                	ld	ra,8(sp)
    8000087a:	6402                	ld	s0,0(sp)
    8000087c:	0141                	addi	sp,sp,16
    8000087e:	8082                	ret

0000000080000880 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000880:	1101                	addi	sp,sp,-32
    80000882:	ec06                	sd	ra,24(sp)
    80000884:	e822                	sd	s0,16(sp)
    80000886:	e426                	sd	s1,8(sp)
    80000888:	1000                	addi	s0,sp,32
    8000088a:	84aa                	mv	s1,a0
  push_off();
    8000088c:	00000097          	auipc	ra,0x0
    80000890:	3be080e7          	jalr	958(ra) # 80000c4a <push_off>

  if(panicked){
    80000894:	00008797          	auipc	a5,0x8
    80000898:	76c7a783          	lw	a5,1900(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000089c:	10000737          	lui	a4,0x10000
  if(panicked){
    800008a0:	c391                	beqz	a5,800008a4 <uartputc_sync+0x24>
    for(;;)
    800008a2:	a001                	j	800008a2 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800008a4:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800008a8:	0ff7f793          	andi	a5,a5,255
    800008ac:	0207f793          	andi	a5,a5,32
    800008b0:	dbf5                	beqz	a5,800008a4 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    800008b2:	0ff4f793          	andi	a5,s1,255
    800008b6:	10000737          	lui	a4,0x10000
    800008ba:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    800008be:	00000097          	auipc	ra,0x0
    800008c2:	42c080e7          	jalr	1068(ra) # 80000cea <pop_off>
}
    800008c6:	60e2                	ld	ra,24(sp)
    800008c8:	6442                	ld	s0,16(sp)
    800008ca:	64a2                	ld	s1,8(sp)
    800008cc:	6105                	addi	sp,sp,32
    800008ce:	8082                	ret

00000000800008d0 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008d0:	00008797          	auipc	a5,0x8
    800008d4:	7347a783          	lw	a5,1844(a5) # 80009004 <uart_tx_r>
    800008d8:	00008717          	auipc	a4,0x8
    800008dc:	73072703          	lw	a4,1840(a4) # 80009008 <uart_tx_w>
    800008e0:	08f70263          	beq	a4,a5,80000964 <uartstart+0x94>
{
    800008e4:	7139                	addi	sp,sp,-64
    800008e6:	fc06                	sd	ra,56(sp)
    800008e8:	f822                	sd	s0,48(sp)
    800008ea:	f426                	sd	s1,40(sp)
    800008ec:	f04a                	sd	s2,32(sp)
    800008ee:	ec4e                	sd	s3,24(sp)
    800008f0:	e852                	sd	s4,16(sp)
    800008f2:	e456                	sd	s5,8(sp)
    800008f4:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008f6:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    800008fa:	00011a17          	auipc	s4,0x11
    800008fe:	ffea0a13          	addi	s4,s4,-2 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000902:	00008497          	auipc	s1,0x8
    80000906:	70248493          	addi	s1,s1,1794 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000090a:	00008997          	auipc	s3,0x8
    8000090e:	6fe98993          	addi	s3,s3,1790 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000912:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000916:	0ff77713          	andi	a4,a4,255
    8000091a:	02077713          	andi	a4,a4,32
    8000091e:	cb15                	beqz	a4,80000952 <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    80000920:	00fa0733          	add	a4,s4,a5
    80000924:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000928:	2785                	addiw	a5,a5,1
    8000092a:	41f7d71b          	sraiw	a4,a5,0x1f
    8000092e:	01b7571b          	srliw	a4,a4,0x1b
    80000932:	9fb9                	addw	a5,a5,a4
    80000934:	8bfd                	andi	a5,a5,31
    80000936:	9f99                	subw	a5,a5,a4
    80000938:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000093a:	8526                	mv	a0,s1
    8000093c:	00002097          	auipc	ra,0x2
    80000940:	ad2080e7          	jalr	-1326(ra) # 8000240e <wakeup>
    
    WriteReg(THR, c);
    80000944:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000948:	409c                	lw	a5,0(s1)
    8000094a:	0009a703          	lw	a4,0(s3)
    8000094e:	fcf712e3          	bne	a4,a5,80000912 <uartstart+0x42>
  }
}
    80000952:	70e2                	ld	ra,56(sp)
    80000954:	7442                	ld	s0,48(sp)
    80000956:	74a2                	ld	s1,40(sp)
    80000958:	7902                	ld	s2,32(sp)
    8000095a:	69e2                	ld	s3,24(sp)
    8000095c:	6a42                	ld	s4,16(sp)
    8000095e:	6aa2                	ld	s5,8(sp)
    80000960:	6121                	addi	sp,sp,64
    80000962:	8082                	ret
    80000964:	8082                	ret

0000000080000966 <uartputc>:
{
    80000966:	7179                	addi	sp,sp,-48
    80000968:	f406                	sd	ra,40(sp)
    8000096a:	f022                	sd	s0,32(sp)
    8000096c:	ec26                	sd	s1,24(sp)
    8000096e:	e84a                	sd	s2,16(sp)
    80000970:	e44e                	sd	s3,8(sp)
    80000972:	e052                	sd	s4,0(sp)
    80000974:	1800                	addi	s0,sp,48
    80000976:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    80000978:	00011517          	auipc	a0,0x11
    8000097c:	f8050513          	addi	a0,a0,-128 # 800118f8 <uart_tx_lock>
    80000980:	00000097          	auipc	ra,0x0
    80000984:	316080e7          	jalr	790(ra) # 80000c96 <acquire>
  if(panicked){
    80000988:	00008797          	auipc	a5,0x8
    8000098c:	6787a783          	lw	a5,1656(a5) # 80009000 <panicked>
    80000990:	c391                	beqz	a5,80000994 <uartputc+0x2e>
    for(;;)
    80000992:	a001                	j	80000992 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000994:	00008717          	auipc	a4,0x8
    80000998:	67472703          	lw	a4,1652(a4) # 80009008 <uart_tx_w>
    8000099c:	0017079b          	addiw	a5,a4,1
    800009a0:	41f7d69b          	sraiw	a3,a5,0x1f
    800009a4:	01b6d69b          	srliw	a3,a3,0x1b
    800009a8:	9fb5                	addw	a5,a5,a3
    800009aa:	8bfd                	andi	a5,a5,31
    800009ac:	9f95                	subw	a5,a5,a3
    800009ae:	00008697          	auipc	a3,0x8
    800009b2:	6566a683          	lw	a3,1622(a3) # 80009004 <uart_tx_r>
    800009b6:	04f69263          	bne	a3,a5,800009fa <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    800009ba:	00011a17          	auipc	s4,0x11
    800009be:	f3ea0a13          	addi	s4,s4,-194 # 800118f8 <uart_tx_lock>
    800009c2:	00008497          	auipc	s1,0x8
    800009c6:	64248493          	addi	s1,s1,1602 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009ca:	00008917          	auipc	s2,0x8
    800009ce:	63e90913          	addi	s2,s2,1598 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    800009d2:	85d2                	mv	a1,s4
    800009d4:	8526                	mv	a0,s1
    800009d6:	00002097          	auipc	ra,0x2
    800009da:	8b2080e7          	jalr	-1870(ra) # 80002288 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009de:	00092703          	lw	a4,0(s2)
    800009e2:	0017079b          	addiw	a5,a4,1
    800009e6:	41f7d69b          	sraiw	a3,a5,0x1f
    800009ea:	01b6d69b          	srliw	a3,a3,0x1b
    800009ee:	9fb5                	addw	a5,a5,a3
    800009f0:	8bfd                	andi	a5,a5,31
    800009f2:	9f95                	subw	a5,a5,a3
    800009f4:	4094                	lw	a3,0(s1)
    800009f6:	fcf68ee3          	beq	a3,a5,800009d2 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    800009fa:	00011497          	auipc	s1,0x11
    800009fe:	efe48493          	addi	s1,s1,-258 # 800118f8 <uart_tx_lock>
    80000a02:	9726                	add	a4,a4,s1
    80000a04:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000a08:	00008717          	auipc	a4,0x8
    80000a0c:	60f72023          	sw	a5,1536(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	ec0080e7          	jalr	-320(ra) # 800008d0 <uartstart>
      release(&uart_tx_lock);
    80000a18:	8526                	mv	a0,s1
    80000a1a:	00000097          	auipc	ra,0x0
    80000a1e:	330080e7          	jalr	816(ra) # 80000d4a <release>
}
    80000a22:	70a2                	ld	ra,40(sp)
    80000a24:	7402                	ld	s0,32(sp)
    80000a26:	64e2                	ld	s1,24(sp)
    80000a28:	6942                	ld	s2,16(sp)
    80000a2a:	69a2                	ld	s3,8(sp)
    80000a2c:	6a02                	ld	s4,0(sp)
    80000a2e:	6145                	addi	sp,sp,48
    80000a30:	8082                	ret

0000000080000a32 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000a32:	1141                	addi	sp,sp,-16
    80000a34:	e422                	sd	s0,8(sp)
    80000a36:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000a38:	100007b7          	lui	a5,0x10000
    80000a3c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a40:	8b85                	andi	a5,a5,1
    80000a42:	cb91                	beqz	a5,80000a56 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a44:	100007b7          	lui	a5,0x10000
    80000a48:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000a4c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000a50:	6422                	ld	s0,8(sp)
    80000a52:	0141                	addi	sp,sp,16
    80000a54:	8082                	ret
    return -1;
    80000a56:	557d                	li	a0,-1
    80000a58:	bfe5                	j	80000a50 <uartgetc+0x1e>

0000000080000a5a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000a5a:	1101                	addi	sp,sp,-32
    80000a5c:	ec06                	sd	ra,24(sp)
    80000a5e:	e822                	sd	s0,16(sp)
    80000a60:	e426                	sd	s1,8(sp)
    80000a62:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a64:	54fd                	li	s1,-1
    int c = uartgetc();
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	fcc080e7          	jalr	-52(ra) # 80000a32 <uartgetc>
    if(c == -1)
    80000a6e:	00950763          	beq	a0,s1,80000a7c <uartintr+0x22>
      break;
    consoleintr(c);
    80000a72:	00000097          	auipc	ra,0x0
    80000a76:	856080e7          	jalr	-1962(ra) # 800002c8 <consoleintr>
  while(1){
    80000a7a:	b7f5                	j	80000a66 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a7c:	00011497          	auipc	s1,0x11
    80000a80:	e7c48493          	addi	s1,s1,-388 # 800118f8 <uart_tx_lock>
    80000a84:	8526                	mv	a0,s1
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	210080e7          	jalr	528(ra) # 80000c96 <acquire>
  uartstart();
    80000a8e:	00000097          	auipc	ra,0x0
    80000a92:	e42080e7          	jalr	-446(ra) # 800008d0 <uartstart>
  release(&uart_tx_lock);
    80000a96:	8526                	mv	a0,s1
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	2b2080e7          	jalr	690(ra) # 80000d4a <release>
}
    80000aa0:	60e2                	ld	ra,24(sp)
    80000aa2:	6442                	ld	s0,16(sp)
    80000aa4:	64a2                	ld	s1,8(sp)
    80000aa6:	6105                	addi	sp,sp,32
    80000aa8:	8082                	ret

0000000080000aaa <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000aaa:	1101                	addi	sp,sp,-32
    80000aac:	ec06                	sd	ra,24(sp)
    80000aae:	e822                	sd	s0,16(sp)
    80000ab0:	e426                	sd	s1,8(sp)
    80000ab2:	e04a                	sd	s2,0(sp)
    80000ab4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000ab6:	03451793          	slli	a5,a0,0x34
    80000aba:	ebb9                	bnez	a5,80000b10 <kfree+0x66>
    80000abc:	84aa                	mv	s1,a0
    80000abe:	0002a797          	auipc	a5,0x2a
    80000ac2:	54278793          	addi	a5,a5,1346 # 8002b000 <end>
    80000ac6:	04f56563          	bltu	a0,a5,80000b10 <kfree+0x66>
    80000aca:	47c5                	li	a5,17
    80000acc:	07ee                	slli	a5,a5,0x1b
    80000ace:	04f57163          	bgeu	a0,a5,80000b10 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000ad2:	6605                	lui	a2,0x1
    80000ad4:	4585                	li	a1,1
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	2bc080e7          	jalr	700(ra) # 80000d92 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000ade:	00011917          	auipc	s2,0x11
    80000ae2:	e5290913          	addi	s2,s2,-430 # 80011930 <kmem>
    80000ae6:	854a                	mv	a0,s2
    80000ae8:	00000097          	auipc	ra,0x0
    80000aec:	1ae080e7          	jalr	430(ra) # 80000c96 <acquire>
  r->next = kmem.freelist;
    80000af0:	01893783          	ld	a5,24(s2)
    80000af4:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000af6:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000afa:	854a                	mv	a0,s2
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	24e080e7          	jalr	590(ra) # 80000d4a <release>
}
    80000b04:	60e2                	ld	ra,24(sp)
    80000b06:	6442                	ld	s0,16(sp)
    80000b08:	64a2                	ld	s1,8(sp)
    80000b0a:	6902                	ld	s2,0(sp)
    80000b0c:	6105                	addi	sp,sp,32
    80000b0e:	8082                	ret
    panic("kfree");
    80000b10:	00007517          	auipc	a0,0x7
    80000b14:	56850513          	addi	a0,a0,1384 # 80008078 <digits+0x20>
    80000b18:	00000097          	auipc	ra,0x0
    80000b1c:	ae0080e7          	jalr	-1312(ra) # 800005f8 <panic>

0000000080000b20 <freerange>:
{
    80000b20:	7179                	addi	sp,sp,-48
    80000b22:	f406                	sd	ra,40(sp)
    80000b24:	f022                	sd	s0,32(sp)
    80000b26:	ec26                	sd	s1,24(sp)
    80000b28:	e84a                	sd	s2,16(sp)
    80000b2a:	e44e                	sd	s3,8(sp)
    80000b2c:	e052                	sd	s4,0(sp)
    80000b2e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b30:	6785                	lui	a5,0x1
    80000b32:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b36:	94aa                	add	s1,s1,a0
    80000b38:	757d                	lui	a0,0xfffff
    80000b3a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b3c:	94be                	add	s1,s1,a5
    80000b3e:	0095ee63          	bltu	a1,s1,80000b5a <freerange+0x3a>
    80000b42:	892e                	mv	s2,a1
    kfree(p);
    80000b44:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b46:	6985                	lui	s3,0x1
    kfree(p);
    80000b48:	01448533          	add	a0,s1,s4
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	f5e080e7          	jalr	-162(ra) # 80000aaa <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b54:	94ce                	add	s1,s1,s3
    80000b56:	fe9979e3          	bgeu	s2,s1,80000b48 <freerange+0x28>
}
    80000b5a:	70a2                	ld	ra,40(sp)
    80000b5c:	7402                	ld	s0,32(sp)
    80000b5e:	64e2                	ld	s1,24(sp)
    80000b60:	6942                	ld	s2,16(sp)
    80000b62:	69a2                	ld	s3,8(sp)
    80000b64:	6a02                	ld	s4,0(sp)
    80000b66:	6145                	addi	sp,sp,48
    80000b68:	8082                	ret

0000000080000b6a <kinit>:
{
    80000b6a:	1141                	addi	sp,sp,-16
    80000b6c:	e406                	sd	ra,8(sp)
    80000b6e:	e022                	sd	s0,0(sp)
    80000b70:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b72:	00007597          	auipc	a1,0x7
    80000b76:	50e58593          	addi	a1,a1,1294 # 80008080 <digits+0x28>
    80000b7a:	00011517          	auipc	a0,0x11
    80000b7e:	db650513          	addi	a0,a0,-586 # 80011930 <kmem>
    80000b82:	00000097          	auipc	ra,0x0
    80000b86:	084080e7          	jalr	132(ra) # 80000c06 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b8a:	45c5                	li	a1,17
    80000b8c:	05ee                	slli	a1,a1,0x1b
    80000b8e:	0002a517          	auipc	a0,0x2a
    80000b92:	47250513          	addi	a0,a0,1138 # 8002b000 <end>
    80000b96:	00000097          	auipc	ra,0x0
    80000b9a:	f8a080e7          	jalr	-118(ra) # 80000b20 <freerange>
}
    80000b9e:	60a2                	ld	ra,8(sp)
    80000ba0:	6402                	ld	s0,0(sp)
    80000ba2:	0141                	addi	sp,sp,16
    80000ba4:	8082                	ret

0000000080000ba6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ba6:	1101                	addi	sp,sp,-32
    80000ba8:	ec06                	sd	ra,24(sp)
    80000baa:	e822                	sd	s0,16(sp)
    80000bac:	e426                	sd	s1,8(sp)
    80000bae:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000bb0:	00011497          	auipc	s1,0x11
    80000bb4:	d8048493          	addi	s1,s1,-640 # 80011930 <kmem>
    80000bb8:	8526                	mv	a0,s1
    80000bba:	00000097          	auipc	ra,0x0
    80000bbe:	0dc080e7          	jalr	220(ra) # 80000c96 <acquire>
  r = kmem.freelist;
    80000bc2:	6c84                	ld	s1,24(s1)
  if(r)
    80000bc4:	c885                	beqz	s1,80000bf4 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000bc6:	609c                	ld	a5,0(s1)
    80000bc8:	00011517          	auipc	a0,0x11
    80000bcc:	d6850513          	addi	a0,a0,-664 # 80011930 <kmem>
    80000bd0:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000bd2:	00000097          	auipc	ra,0x0
    80000bd6:	178080e7          	jalr	376(ra) # 80000d4a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bda:	6605                	lui	a2,0x1
    80000bdc:	4595                	li	a1,5
    80000bde:	8526                	mv	a0,s1
    80000be0:	00000097          	auipc	ra,0x0
    80000be4:	1b2080e7          	jalr	434(ra) # 80000d92 <memset>
  return (void*)r;
}
    80000be8:	8526                	mv	a0,s1
    80000bea:	60e2                	ld	ra,24(sp)
    80000bec:	6442                	ld	s0,16(sp)
    80000bee:	64a2                	ld	s1,8(sp)
    80000bf0:	6105                	addi	sp,sp,32
    80000bf2:	8082                	ret
  release(&kmem.lock);
    80000bf4:	00011517          	auipc	a0,0x11
    80000bf8:	d3c50513          	addi	a0,a0,-708 # 80011930 <kmem>
    80000bfc:	00000097          	auipc	ra,0x0
    80000c00:	14e080e7          	jalr	334(ra) # 80000d4a <release>
  if(r)
    80000c04:	b7d5                	j	80000be8 <kalloc+0x42>

0000000080000c06 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c06:	1141                	addi	sp,sp,-16
    80000c08:	e422                	sd	s0,8(sp)
    80000c0a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c0c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c0e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c12:	00053823          	sd	zero,16(a0)
}
    80000c16:	6422                	ld	s0,8(sp)
    80000c18:	0141                	addi	sp,sp,16
    80000c1a:	8082                	ret

0000000080000c1c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c1c:	411c                	lw	a5,0(a0)
    80000c1e:	e399                	bnez	a5,80000c24 <holding+0x8>
    80000c20:	4501                	li	a0,0
  return r;
}
    80000c22:	8082                	ret
{
    80000c24:	1101                	addi	sp,sp,-32
    80000c26:	ec06                	sd	ra,24(sp)
    80000c28:	e822                	sd	s0,16(sp)
    80000c2a:	e426                	sd	s1,8(sp)
    80000c2c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c2e:	6904                	ld	s1,16(a0)
    80000c30:	00001097          	auipc	ra,0x1
    80000c34:	e18080e7          	jalr	-488(ra) # 80001a48 <mycpu>
    80000c38:	40a48533          	sub	a0,s1,a0
    80000c3c:	00153513          	seqz	a0,a0
}
    80000c40:	60e2                	ld	ra,24(sp)
    80000c42:	6442                	ld	s0,16(sp)
    80000c44:	64a2                	ld	s1,8(sp)
    80000c46:	6105                	addi	sp,sp,32
    80000c48:	8082                	ret

0000000080000c4a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c4a:	1101                	addi	sp,sp,-32
    80000c4c:	ec06                	sd	ra,24(sp)
    80000c4e:	e822                	sd	s0,16(sp)
    80000c50:	e426                	sd	s1,8(sp)
    80000c52:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c54:	100024f3          	csrr	s1,sstatus
    80000c58:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c5c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c62:	00001097          	auipc	ra,0x1
    80000c66:	de6080e7          	jalr	-538(ra) # 80001a48 <mycpu>
    80000c6a:	5d3c                	lw	a5,120(a0)
    80000c6c:	cf89                	beqz	a5,80000c86 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c6e:	00001097          	auipc	ra,0x1
    80000c72:	dda080e7          	jalr	-550(ra) # 80001a48 <mycpu>
    80000c76:	5d3c                	lw	a5,120(a0)
    80000c78:	2785                	addiw	a5,a5,1
    80000c7a:	dd3c                	sw	a5,120(a0)
}
    80000c7c:	60e2                	ld	ra,24(sp)
    80000c7e:	6442                	ld	s0,16(sp)
    80000c80:	64a2                	ld	s1,8(sp)
    80000c82:	6105                	addi	sp,sp,32
    80000c84:	8082                	ret
    mycpu()->intena = old;
    80000c86:	00001097          	auipc	ra,0x1
    80000c8a:	dc2080e7          	jalr	-574(ra) # 80001a48 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c8e:	8085                	srli	s1,s1,0x1
    80000c90:	8885                	andi	s1,s1,1
    80000c92:	dd64                	sw	s1,124(a0)
    80000c94:	bfe9                	j	80000c6e <push_off+0x24>

0000000080000c96 <acquire>:
{
    80000c96:	1101                	addi	sp,sp,-32
    80000c98:	ec06                	sd	ra,24(sp)
    80000c9a:	e822                	sd	s0,16(sp)
    80000c9c:	e426                	sd	s1,8(sp)
    80000c9e:	1000                	addi	s0,sp,32
    80000ca0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000ca2:	00000097          	auipc	ra,0x0
    80000ca6:	fa8080e7          	jalr	-88(ra) # 80000c4a <push_off>
  if(holding(lk))
    80000caa:	8526                	mv	a0,s1
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	f70080e7          	jalr	-144(ra) # 80000c1c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cb4:	4705                	li	a4,1
  if(holding(lk))
    80000cb6:	e115                	bnez	a0,80000cda <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cb8:	87ba                	mv	a5,a4
    80000cba:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000cbe:	2781                	sext.w	a5,a5
    80000cc0:	ffe5                	bnez	a5,80000cb8 <acquire+0x22>
  __sync_synchronize();
    80000cc2:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000cc6:	00001097          	auipc	ra,0x1
    80000cca:	d82080e7          	jalr	-638(ra) # 80001a48 <mycpu>
    80000cce:	e888                	sd	a0,16(s1)
}
    80000cd0:	60e2                	ld	ra,24(sp)
    80000cd2:	6442                	ld	s0,16(sp)
    80000cd4:	64a2                	ld	s1,8(sp)
    80000cd6:	6105                	addi	sp,sp,32
    80000cd8:	8082                	ret
    panic("acquire");
    80000cda:	00007517          	auipc	a0,0x7
    80000cde:	3ae50513          	addi	a0,a0,942 # 80008088 <digits+0x30>
    80000ce2:	00000097          	auipc	ra,0x0
    80000ce6:	916080e7          	jalr	-1770(ra) # 800005f8 <panic>

0000000080000cea <pop_off>:

void
pop_off(void)
{
    80000cea:	1141                	addi	sp,sp,-16
    80000cec:	e406                	sd	ra,8(sp)
    80000cee:	e022                	sd	s0,0(sp)
    80000cf0:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cf2:	00001097          	auipc	ra,0x1
    80000cf6:	d56080e7          	jalr	-682(ra) # 80001a48 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cfa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cfe:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d00:	e78d                	bnez	a5,80000d2a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d02:	5d3c                	lw	a5,120(a0)
    80000d04:	02f05b63          	blez	a5,80000d3a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d08:	37fd                	addiw	a5,a5,-1
    80000d0a:	0007871b          	sext.w	a4,a5
    80000d0e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d10:	eb09                	bnez	a4,80000d22 <pop_off+0x38>
    80000d12:	5d7c                	lw	a5,124(a0)
    80000d14:	c799                	beqz	a5,80000d22 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d16:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d1a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d1e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d22:	60a2                	ld	ra,8(sp)
    80000d24:	6402                	ld	s0,0(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
    panic("pop_off - interruptible");
    80000d2a:	00007517          	auipc	a0,0x7
    80000d2e:	36650513          	addi	a0,a0,870 # 80008090 <digits+0x38>
    80000d32:	00000097          	auipc	ra,0x0
    80000d36:	8c6080e7          	jalr	-1850(ra) # 800005f8 <panic>
    panic("pop_off");
    80000d3a:	00007517          	auipc	a0,0x7
    80000d3e:	36e50513          	addi	a0,a0,878 # 800080a8 <digits+0x50>
    80000d42:	00000097          	auipc	ra,0x0
    80000d46:	8b6080e7          	jalr	-1866(ra) # 800005f8 <panic>

0000000080000d4a <release>:
{
    80000d4a:	1101                	addi	sp,sp,-32
    80000d4c:	ec06                	sd	ra,24(sp)
    80000d4e:	e822                	sd	s0,16(sp)
    80000d50:	e426                	sd	s1,8(sp)
    80000d52:	1000                	addi	s0,sp,32
    80000d54:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d56:	00000097          	auipc	ra,0x0
    80000d5a:	ec6080e7          	jalr	-314(ra) # 80000c1c <holding>
    80000d5e:	c115                	beqz	a0,80000d82 <release+0x38>
  lk->cpu = 0;
    80000d60:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d64:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d68:	0f50000f          	fence	iorw,ow
    80000d6c:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d70:	00000097          	auipc	ra,0x0
    80000d74:	f7a080e7          	jalr	-134(ra) # 80000cea <pop_off>
}
    80000d78:	60e2                	ld	ra,24(sp)
    80000d7a:	6442                	ld	s0,16(sp)
    80000d7c:	64a2                	ld	s1,8(sp)
    80000d7e:	6105                	addi	sp,sp,32
    80000d80:	8082                	ret
    panic("release");
    80000d82:	00007517          	auipc	a0,0x7
    80000d86:	32e50513          	addi	a0,a0,814 # 800080b0 <digits+0x58>
    80000d8a:	00000097          	auipc	ra,0x0
    80000d8e:	86e080e7          	jalr	-1938(ra) # 800005f8 <panic>

0000000080000d92 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d92:	1141                	addi	sp,sp,-16
    80000d94:	e422                	sd	s0,8(sp)
    80000d96:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d98:	ce09                	beqz	a2,80000db2 <memset+0x20>
    80000d9a:	87aa                	mv	a5,a0
    80000d9c:	fff6071b          	addiw	a4,a2,-1
    80000da0:	1702                	slli	a4,a4,0x20
    80000da2:	9301                	srli	a4,a4,0x20
    80000da4:	0705                	addi	a4,a4,1
    80000da6:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000da8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000dac:	0785                	addi	a5,a5,1
    80000dae:	fee79de3          	bne	a5,a4,80000da8 <memset+0x16>
  }
  return dst;
}
    80000db2:	6422                	ld	s0,8(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dbe:	ca05                	beqz	a2,80000dee <memcmp+0x36>
    80000dc0:	fff6069b          	addiw	a3,a2,-1
    80000dc4:	1682                	slli	a3,a3,0x20
    80000dc6:	9281                	srli	a3,a3,0x20
    80000dc8:	0685                	addi	a3,a3,1
    80000dca:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000dcc:	00054783          	lbu	a5,0(a0)
    80000dd0:	0005c703          	lbu	a4,0(a1)
    80000dd4:	00e79863          	bne	a5,a4,80000de4 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000dd8:	0505                	addi	a0,a0,1
    80000dda:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ddc:	fed518e3          	bne	a0,a3,80000dcc <memcmp+0x14>
  }

  return 0;
    80000de0:	4501                	li	a0,0
    80000de2:	a019                	j	80000de8 <memcmp+0x30>
      return *s1 - *s2;
    80000de4:	40e7853b          	subw	a0,a5,a4
}
    80000de8:	6422                	ld	s0,8(sp)
    80000dea:	0141                	addi	sp,sp,16
    80000dec:	8082                	ret
  return 0;
    80000dee:	4501                	li	a0,0
    80000df0:	bfe5                	j	80000de8 <memcmp+0x30>

0000000080000df2 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000df2:	1141                	addi	sp,sp,-16
    80000df4:	e422                	sd	s0,8(sp)
    80000df6:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000df8:	00a5f963          	bgeu	a1,a0,80000e0a <memmove+0x18>
    80000dfc:	02061713          	slli	a4,a2,0x20
    80000e00:	9301                	srli	a4,a4,0x20
    80000e02:	00e587b3          	add	a5,a1,a4
    80000e06:	02f56563          	bltu	a0,a5,80000e30 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e0a:	fff6069b          	addiw	a3,a2,-1
    80000e0e:	ce11                	beqz	a2,80000e2a <memmove+0x38>
    80000e10:	1682                	slli	a3,a3,0x20
    80000e12:	9281                	srli	a3,a3,0x20
    80000e14:	0685                	addi	a3,a3,1
    80000e16:	96ae                	add	a3,a3,a1
    80000e18:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000e1a:	0585                	addi	a1,a1,1
    80000e1c:	0785                	addi	a5,a5,1
    80000e1e:	fff5c703          	lbu	a4,-1(a1)
    80000e22:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000e26:	fed59ae3          	bne	a1,a3,80000e1a <memmove+0x28>

  return dst;
}
    80000e2a:	6422                	ld	s0,8(sp)
    80000e2c:	0141                	addi	sp,sp,16
    80000e2e:	8082                	ret
    d += n;
    80000e30:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000e32:	fff6069b          	addiw	a3,a2,-1
    80000e36:	da75                	beqz	a2,80000e2a <memmove+0x38>
    80000e38:	02069613          	slli	a2,a3,0x20
    80000e3c:	9201                	srli	a2,a2,0x20
    80000e3e:	fff64613          	not	a2,a2
    80000e42:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e44:	17fd                	addi	a5,a5,-1
    80000e46:	177d                	addi	a4,a4,-1
    80000e48:	0007c683          	lbu	a3,0(a5)
    80000e4c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e50:	fec79ae3          	bne	a5,a2,80000e44 <memmove+0x52>
    80000e54:	bfd9                	j	80000e2a <memmove+0x38>

0000000080000e56 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e56:	1141                	addi	sp,sp,-16
    80000e58:	e406                	sd	ra,8(sp)
    80000e5a:	e022                	sd	s0,0(sp)
    80000e5c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e5e:	00000097          	auipc	ra,0x0
    80000e62:	f94080e7          	jalr	-108(ra) # 80000df2 <memmove>
}
    80000e66:	60a2                	ld	ra,8(sp)
    80000e68:	6402                	ld	s0,0(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret

0000000080000e6e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e6e:	1141                	addi	sp,sp,-16
    80000e70:	e422                	sd	s0,8(sp)
    80000e72:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e74:	ce11                	beqz	a2,80000e90 <strncmp+0x22>
    80000e76:	00054783          	lbu	a5,0(a0)
    80000e7a:	cf89                	beqz	a5,80000e94 <strncmp+0x26>
    80000e7c:	0005c703          	lbu	a4,0(a1)
    80000e80:	00f71a63          	bne	a4,a5,80000e94 <strncmp+0x26>
    n--, p++, q++;
    80000e84:	367d                	addiw	a2,a2,-1
    80000e86:	0505                	addi	a0,a0,1
    80000e88:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e8a:	f675                	bnez	a2,80000e76 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e8c:	4501                	li	a0,0
    80000e8e:	a809                	j	80000ea0 <strncmp+0x32>
    80000e90:	4501                	li	a0,0
    80000e92:	a039                	j	80000ea0 <strncmp+0x32>
  if(n == 0)
    80000e94:	ca09                	beqz	a2,80000ea6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e96:	00054503          	lbu	a0,0(a0)
    80000e9a:	0005c783          	lbu	a5,0(a1)
    80000e9e:	9d1d                	subw	a0,a0,a5
}
    80000ea0:	6422                	ld	s0,8(sp)
    80000ea2:	0141                	addi	sp,sp,16
    80000ea4:	8082                	ret
    return 0;
    80000ea6:	4501                	li	a0,0
    80000ea8:	bfe5                	j	80000ea0 <strncmp+0x32>

0000000080000eaa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000eaa:	1141                	addi	sp,sp,-16
    80000eac:	e422                	sd	s0,8(sp)
    80000eae:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000eb0:	872a                	mv	a4,a0
    80000eb2:	8832                	mv	a6,a2
    80000eb4:	367d                	addiw	a2,a2,-1
    80000eb6:	01005963          	blez	a6,80000ec8 <strncpy+0x1e>
    80000eba:	0705                	addi	a4,a4,1
    80000ebc:	0005c783          	lbu	a5,0(a1)
    80000ec0:	fef70fa3          	sb	a5,-1(a4)
    80000ec4:	0585                	addi	a1,a1,1
    80000ec6:	f7f5                	bnez	a5,80000eb2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ec8:	00c05d63          	blez	a2,80000ee2 <strncpy+0x38>
    80000ecc:	86ba                	mv	a3,a4
    *s++ = 0;
    80000ece:	0685                	addi	a3,a3,1
    80000ed0:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000ed4:	fff6c793          	not	a5,a3
    80000ed8:	9fb9                	addw	a5,a5,a4
    80000eda:	010787bb          	addw	a5,a5,a6
    80000ede:	fef048e3          	bgtz	a5,80000ece <strncpy+0x24>
  return os;
}
    80000ee2:	6422                	ld	s0,8(sp)
    80000ee4:	0141                	addi	sp,sp,16
    80000ee6:	8082                	ret

0000000080000ee8 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ee8:	1141                	addi	sp,sp,-16
    80000eea:	e422                	sd	s0,8(sp)
    80000eec:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eee:	02c05363          	blez	a2,80000f14 <safestrcpy+0x2c>
    80000ef2:	fff6069b          	addiw	a3,a2,-1
    80000ef6:	1682                	slli	a3,a3,0x20
    80000ef8:	9281                	srli	a3,a3,0x20
    80000efa:	96ae                	add	a3,a3,a1
    80000efc:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000efe:	00d58963          	beq	a1,a3,80000f10 <safestrcpy+0x28>
    80000f02:	0585                	addi	a1,a1,1
    80000f04:	0785                	addi	a5,a5,1
    80000f06:	fff5c703          	lbu	a4,-1(a1)
    80000f0a:	fee78fa3          	sb	a4,-1(a5)
    80000f0e:	fb65                	bnez	a4,80000efe <safestrcpy+0x16>
    ;
  *s = 0;
    80000f10:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f14:	6422                	ld	s0,8(sp)
    80000f16:	0141                	addi	sp,sp,16
    80000f18:	8082                	ret

0000000080000f1a <strlen>:

int
strlen(const char *s)
{
    80000f1a:	1141                	addi	sp,sp,-16
    80000f1c:	e422                	sd	s0,8(sp)
    80000f1e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f20:	00054783          	lbu	a5,0(a0)
    80000f24:	cf91                	beqz	a5,80000f40 <strlen+0x26>
    80000f26:	0505                	addi	a0,a0,1
    80000f28:	87aa                	mv	a5,a0
    80000f2a:	4685                	li	a3,1
    80000f2c:	9e89                	subw	a3,a3,a0
    80000f2e:	00f6853b          	addw	a0,a3,a5
    80000f32:	0785                	addi	a5,a5,1
    80000f34:	fff7c703          	lbu	a4,-1(a5)
    80000f38:	fb7d                	bnez	a4,80000f2e <strlen+0x14>
    ;
  return n;
}
    80000f3a:	6422                	ld	s0,8(sp)
    80000f3c:	0141                	addi	sp,sp,16
    80000f3e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f40:	4501                	li	a0,0
    80000f42:	bfe5                	j	80000f3a <strlen+0x20>

0000000080000f44 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f44:	1141                	addi	sp,sp,-16
    80000f46:	e406                	sd	ra,8(sp)
    80000f48:	e022                	sd	s0,0(sp)
    80000f4a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	aec080e7          	jalr	-1300(ra) # 80001a38 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f54:	00008717          	auipc	a4,0x8
    80000f58:	0b870713          	addi	a4,a4,184 # 8000900c <started>
  if(cpuid() == 0){
    80000f5c:	c139                	beqz	a0,80000fa2 <main+0x5e>
    while(started == 0)
    80000f5e:	431c                	lw	a5,0(a4)
    80000f60:	2781                	sext.w	a5,a5
    80000f62:	dff5                	beqz	a5,80000f5e <main+0x1a>
      ;
    __sync_synchronize();
    80000f64:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f68:	00001097          	auipc	ra,0x1
    80000f6c:	ad0080e7          	jalr	-1328(ra) # 80001a38 <cpuid>
    80000f70:	85aa                	mv	a1,a0
    80000f72:	00007517          	auipc	a0,0x7
    80000f76:	15e50513          	addi	a0,a0,350 # 800080d0 <digits+0x78>
    80000f7a:	fffff097          	auipc	ra,0xfffff
    80000f7e:	6d0080e7          	jalr	1744(ra) # 8000064a <printf>
    kvminithart();    // turn on paging
    80000f82:	00000097          	auipc	ra,0x0
    80000f86:	0d8080e7          	jalr	216(ra) # 8000105a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f8a:	00001097          	auipc	ra,0x1
    80000f8e:	74c080e7          	jalr	1868(ra) # 800026d6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f92:	00005097          	auipc	ra,0x5
    80000f96:	e1e080e7          	jalr	-482(ra) # 80005db0 <plicinithart>
  }

  scheduler();        
    80000f9a:	00001097          	auipc	ra,0x1
    80000f9e:	012080e7          	jalr	18(ra) # 80001fac <scheduler>
    consoleinit();
    80000fa2:	fffff097          	auipc	ra,0xfffff
    80000fa6:	4b8080e7          	jalr	1208(ra) # 8000045a <consoleinit>
    printfinit();
    80000faa:	fffff097          	auipc	ra,0xfffff
    80000fae:	59e080e7          	jalr	1438(ra) # 80000548 <printfinit>
    printf("\n");
    80000fb2:	00007517          	auipc	a0,0x7
    80000fb6:	12e50513          	addi	a0,a0,302 # 800080e0 <digits+0x88>
    80000fba:	fffff097          	auipc	ra,0xfffff
    80000fbe:	690080e7          	jalr	1680(ra) # 8000064a <printf>
    printf("xv6 kernel is booting\n");
    80000fc2:	00007517          	auipc	a0,0x7
    80000fc6:	0f650513          	addi	a0,a0,246 # 800080b8 <digits+0x60>
    80000fca:	fffff097          	auipc	ra,0xfffff
    80000fce:	680080e7          	jalr	1664(ra) # 8000064a <printf>
    printf("\n");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	10e50513          	addi	a0,a0,270 # 800080e0 <digits+0x88>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	670080e7          	jalr	1648(ra) # 8000064a <printf>
    kinit();         // physical page allocator
    80000fe2:	00000097          	auipc	ra,0x0
    80000fe6:	b88080e7          	jalr	-1144(ra) # 80000b6a <kinit>
    kvminit();       // create kernel page table
    80000fea:	00000097          	auipc	ra,0x0
    80000fee:	2a0080e7          	jalr	672(ra) # 8000128a <kvminit>
    kvminithart();   // turn on paging
    80000ff2:	00000097          	auipc	ra,0x0
    80000ff6:	068080e7          	jalr	104(ra) # 8000105a <kvminithart>
    procinit();      // process table
    80000ffa:	00001097          	auipc	ra,0x1
    80000ffe:	96e080e7          	jalr	-1682(ra) # 80001968 <procinit>
    trapinit();      // trap vectors
    80001002:	00001097          	auipc	ra,0x1
    80001006:	6ac080e7          	jalr	1708(ra) # 800026ae <trapinit>
    trapinithart();  // install kernel trap vector
    8000100a:	00001097          	auipc	ra,0x1
    8000100e:	6cc080e7          	jalr	1740(ra) # 800026d6 <trapinithart>
    plicinit();      // set up interrupt controller
    80001012:	00005097          	auipc	ra,0x5
    80001016:	d88080e7          	jalr	-632(ra) # 80005d9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000101a:	00005097          	auipc	ra,0x5
    8000101e:	d96080e7          	jalr	-618(ra) # 80005db0 <plicinithart>
    binit();         // buffer cache
    80001022:	00002097          	auipc	ra,0x2
    80001026:	f3a080e7          	jalr	-198(ra) # 80002f5c <binit>
    iinit();         // inode cache
    8000102a:	00002097          	auipc	ra,0x2
    8000102e:	5ca080e7          	jalr	1482(ra) # 800035f4 <iinit>
    fileinit();      // file table
    80001032:	00003097          	auipc	ra,0x3
    80001036:	564080e7          	jalr	1380(ra) # 80004596 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000103a:	00005097          	auipc	ra,0x5
    8000103e:	e7e080e7          	jalr	-386(ra) # 80005eb8 <virtio_disk_init>
    userinit();      // first user process
    80001042:	00001097          	auipc	ra,0x1
    80001046:	d04080e7          	jalr	-764(ra) # 80001d46 <userinit>
    __sync_synchronize();
    8000104a:	0ff0000f          	fence
    started = 1;
    8000104e:	4785                	li	a5,1
    80001050:	00008717          	auipc	a4,0x8
    80001054:	faf72e23          	sw	a5,-68(a4) # 8000900c <started>
    80001058:	b789                	j	80000f9a <main+0x56>

000000008000105a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000105a:	1141                	addi	sp,sp,-16
    8000105c:	e422                	sd	s0,8(sp)
    8000105e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001060:	00008797          	auipc	a5,0x8
    80001064:	fb07b783          	ld	a5,-80(a5) # 80009010 <kernel_pagetable>
    80001068:	83b1                	srli	a5,a5,0xc
    8000106a:	577d                	li	a4,-1
    8000106c:	177e                	slli	a4,a4,0x3f
    8000106e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001070:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001074:	12000073          	sfence.vma
  sfence_vma();
}
    80001078:	6422                	ld	s0,8(sp)
    8000107a:	0141                	addi	sp,sp,16
    8000107c:	8082                	ret

000000008000107e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000107e:	7139                	addi	sp,sp,-64
    80001080:	fc06                	sd	ra,56(sp)
    80001082:	f822                	sd	s0,48(sp)
    80001084:	f426                	sd	s1,40(sp)
    80001086:	f04a                	sd	s2,32(sp)
    80001088:	ec4e                	sd	s3,24(sp)
    8000108a:	e852                	sd	s4,16(sp)
    8000108c:	e456                	sd	s5,8(sp)
    8000108e:	e05a                	sd	s6,0(sp)
    80001090:	0080                	addi	s0,sp,64
    80001092:	84aa                	mv	s1,a0
    80001094:	89ae                	mv	s3,a1
    80001096:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001098:	57fd                	li	a5,-1
    8000109a:	83e9                	srli	a5,a5,0x1a
    8000109c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000109e:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010a0:	04b7f263          	bgeu	a5,a1,800010e4 <walk+0x66>
    panic("walk");
    800010a4:	00007517          	auipc	a0,0x7
    800010a8:	04450513          	addi	a0,a0,68 # 800080e8 <digits+0x90>
    800010ac:	fffff097          	auipc	ra,0xfffff
    800010b0:	54c080e7          	jalr	1356(ra) # 800005f8 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010b4:	060a8663          	beqz	s5,80001120 <walk+0xa2>
    800010b8:	00000097          	auipc	ra,0x0
    800010bc:	aee080e7          	jalr	-1298(ra) # 80000ba6 <kalloc>
    800010c0:	84aa                	mv	s1,a0
    800010c2:	c529                	beqz	a0,8000110c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010c4:	6605                	lui	a2,0x1
    800010c6:	4581                	li	a1,0
    800010c8:	00000097          	auipc	ra,0x0
    800010cc:	cca080e7          	jalr	-822(ra) # 80000d92 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010d0:	00c4d793          	srli	a5,s1,0xc
    800010d4:	07aa                	slli	a5,a5,0xa
    800010d6:	0017e793          	ori	a5,a5,1
    800010da:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010de:	3a5d                	addiw	s4,s4,-9
    800010e0:	036a0063          	beq	s4,s6,80001100 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010e4:	0149d933          	srl	s2,s3,s4
    800010e8:	1ff97913          	andi	s2,s2,511
    800010ec:	090e                	slli	s2,s2,0x3
    800010ee:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010f0:	00093483          	ld	s1,0(s2)
    800010f4:	0014f793          	andi	a5,s1,1
    800010f8:	dfd5                	beqz	a5,800010b4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010fa:	80a9                	srli	s1,s1,0xa
    800010fc:	04b2                	slli	s1,s1,0xc
    800010fe:	b7c5                	j	800010de <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001100:	00c9d513          	srli	a0,s3,0xc
    80001104:	1ff57513          	andi	a0,a0,511
    80001108:	050e                	slli	a0,a0,0x3
    8000110a:	9526                	add	a0,a0,s1
}
    8000110c:	70e2                	ld	ra,56(sp)
    8000110e:	7442                	ld	s0,48(sp)
    80001110:	74a2                	ld	s1,40(sp)
    80001112:	7902                	ld	s2,32(sp)
    80001114:	69e2                	ld	s3,24(sp)
    80001116:	6a42                	ld	s4,16(sp)
    80001118:	6aa2                	ld	s5,8(sp)
    8000111a:	6b02                	ld	s6,0(sp)
    8000111c:	6121                	addi	sp,sp,64
    8000111e:	8082                	ret
        return 0;
    80001120:	4501                	li	a0,0
    80001122:	b7ed                	j	8000110c <walk+0x8e>

0000000080001124 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001124:	57fd                	li	a5,-1
    80001126:	83e9                	srli	a5,a5,0x1a
    80001128:	00b7f463          	bgeu	a5,a1,80001130 <walkaddr+0xc>
    return 0;
    8000112c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000112e:	8082                	ret
{
    80001130:	1141                	addi	sp,sp,-16
    80001132:	e406                	sd	ra,8(sp)
    80001134:	e022                	sd	s0,0(sp)
    80001136:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001138:	4601                	li	a2,0
    8000113a:	00000097          	auipc	ra,0x0
    8000113e:	f44080e7          	jalr	-188(ra) # 8000107e <walk>
  if(pte == 0)
    80001142:	c105                	beqz	a0,80001162 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001144:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001146:	0117f693          	andi	a3,a5,17
    8000114a:	4745                	li	a4,17
    return 0;
    8000114c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000114e:	00e68663          	beq	a3,a4,8000115a <walkaddr+0x36>
}
    80001152:	60a2                	ld	ra,8(sp)
    80001154:	6402                	ld	s0,0(sp)
    80001156:	0141                	addi	sp,sp,16
    80001158:	8082                	ret
  pa = PTE2PA(*pte);
    8000115a:	00a7d513          	srli	a0,a5,0xa
    8000115e:	0532                	slli	a0,a0,0xc
  return pa;
    80001160:	bfcd                	j	80001152 <walkaddr+0x2e>
    return 0;
    80001162:	4501                	li	a0,0
    80001164:	b7fd                	j	80001152 <walkaddr+0x2e>

0000000080001166 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001166:	1101                	addi	sp,sp,-32
    80001168:	ec06                	sd	ra,24(sp)
    8000116a:	e822                	sd	s0,16(sp)
    8000116c:	e426                	sd	s1,8(sp)
    8000116e:	1000                	addi	s0,sp,32
    80001170:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001172:	1552                	slli	a0,a0,0x34
    80001174:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001178:	4601                	li	a2,0
    8000117a:	00008517          	auipc	a0,0x8
    8000117e:	e9653503          	ld	a0,-362(a0) # 80009010 <kernel_pagetable>
    80001182:	00000097          	auipc	ra,0x0
    80001186:	efc080e7          	jalr	-260(ra) # 8000107e <walk>
  if(pte == 0)
    8000118a:	cd09                	beqz	a0,800011a4 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    8000118c:	6108                	ld	a0,0(a0)
    8000118e:	00157793          	andi	a5,a0,1
    80001192:	c38d                	beqz	a5,800011b4 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001194:	8129                	srli	a0,a0,0xa
    80001196:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001198:	9526                	add	a0,a0,s1
    8000119a:	60e2                	ld	ra,24(sp)
    8000119c:	6442                	ld	s0,16(sp)
    8000119e:	64a2                	ld	s1,8(sp)
    800011a0:	6105                	addi	sp,sp,32
    800011a2:	8082                	ret
    panic("kvmpa");
    800011a4:	00007517          	auipc	a0,0x7
    800011a8:	f4c50513          	addi	a0,a0,-180 # 800080f0 <digits+0x98>
    800011ac:	fffff097          	auipc	ra,0xfffff
    800011b0:	44c080e7          	jalr	1100(ra) # 800005f8 <panic>
    panic("kvmpa");
    800011b4:	00007517          	auipc	a0,0x7
    800011b8:	f3c50513          	addi	a0,a0,-196 # 800080f0 <digits+0x98>
    800011bc:	fffff097          	auipc	ra,0xfffff
    800011c0:	43c080e7          	jalr	1084(ra) # 800005f8 <panic>

00000000800011c4 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011c4:	715d                	addi	sp,sp,-80
    800011c6:	e486                	sd	ra,72(sp)
    800011c8:	e0a2                	sd	s0,64(sp)
    800011ca:	fc26                	sd	s1,56(sp)
    800011cc:	f84a                	sd	s2,48(sp)
    800011ce:	f44e                	sd	s3,40(sp)
    800011d0:	f052                	sd	s4,32(sp)
    800011d2:	ec56                	sd	s5,24(sp)
    800011d4:	e85a                	sd	s6,16(sp)
    800011d6:	e45e                	sd	s7,8(sp)
    800011d8:	0880                	addi	s0,sp,80
    800011da:	8aaa                	mv	s5,a0
    800011dc:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011de:	777d                	lui	a4,0xfffff
    800011e0:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011e4:	167d                	addi	a2,a2,-1
    800011e6:	00b609b3          	add	s3,a2,a1
    800011ea:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011ee:	893e                	mv	s2,a5
    800011f0:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011f4:	6b85                	lui	s7,0x1
    800011f6:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011fa:	4605                	li	a2,1
    800011fc:	85ca                	mv	a1,s2
    800011fe:	8556                	mv	a0,s5
    80001200:	00000097          	auipc	ra,0x0
    80001204:	e7e080e7          	jalr	-386(ra) # 8000107e <walk>
    80001208:	c51d                	beqz	a0,80001236 <mappages+0x72>
    if(*pte & PTE_V)
    8000120a:	611c                	ld	a5,0(a0)
    8000120c:	8b85                	andi	a5,a5,1
    8000120e:	ef81                	bnez	a5,80001226 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001210:	80b1                	srli	s1,s1,0xc
    80001212:	04aa                	slli	s1,s1,0xa
    80001214:	0164e4b3          	or	s1,s1,s6
    80001218:	0014e493          	ori	s1,s1,1
    8000121c:	e104                	sd	s1,0(a0)
    if(a == last)
    8000121e:	03390863          	beq	s2,s3,8000124e <mappages+0x8a>
    a += PGSIZE;
    80001222:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001224:	bfc9                	j	800011f6 <mappages+0x32>
      panic("remap");
    80001226:	00007517          	auipc	a0,0x7
    8000122a:	ed250513          	addi	a0,a0,-302 # 800080f8 <digits+0xa0>
    8000122e:	fffff097          	auipc	ra,0xfffff
    80001232:	3ca080e7          	jalr	970(ra) # 800005f8 <panic>
      return -1;
    80001236:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001238:	60a6                	ld	ra,72(sp)
    8000123a:	6406                	ld	s0,64(sp)
    8000123c:	74e2                	ld	s1,56(sp)
    8000123e:	7942                	ld	s2,48(sp)
    80001240:	79a2                	ld	s3,40(sp)
    80001242:	7a02                	ld	s4,32(sp)
    80001244:	6ae2                	ld	s5,24(sp)
    80001246:	6b42                	ld	s6,16(sp)
    80001248:	6ba2                	ld	s7,8(sp)
    8000124a:	6161                	addi	sp,sp,80
    8000124c:	8082                	ret
  return 0;
    8000124e:	4501                	li	a0,0
    80001250:	b7e5                	j	80001238 <mappages+0x74>

0000000080001252 <kvmmap>:
{
    80001252:	1141                	addi	sp,sp,-16
    80001254:	e406                	sd	ra,8(sp)
    80001256:	e022                	sd	s0,0(sp)
    80001258:	0800                	addi	s0,sp,16
    8000125a:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000125c:	86ae                	mv	a3,a1
    8000125e:	85aa                	mv	a1,a0
    80001260:	00008517          	auipc	a0,0x8
    80001264:	db053503          	ld	a0,-592(a0) # 80009010 <kernel_pagetable>
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f5c080e7          	jalr	-164(ra) # 800011c4 <mappages>
    80001270:	e509                	bnez	a0,8000127a <kvmmap+0x28>
}
    80001272:	60a2                	ld	ra,8(sp)
    80001274:	6402                	ld	s0,0(sp)
    80001276:	0141                	addi	sp,sp,16
    80001278:	8082                	ret
    panic("kvmmap");
    8000127a:	00007517          	auipc	a0,0x7
    8000127e:	e8650513          	addi	a0,a0,-378 # 80008100 <digits+0xa8>
    80001282:	fffff097          	auipc	ra,0xfffff
    80001286:	376080e7          	jalr	886(ra) # 800005f8 <panic>

000000008000128a <kvminit>:
{
    8000128a:	1101                	addi	sp,sp,-32
    8000128c:	ec06                	sd	ra,24(sp)
    8000128e:	e822                	sd	s0,16(sp)
    80001290:	e426                	sd	s1,8(sp)
    80001292:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001294:	00000097          	auipc	ra,0x0
    80001298:	912080e7          	jalr	-1774(ra) # 80000ba6 <kalloc>
    8000129c:	00008797          	auipc	a5,0x8
    800012a0:	d6a7ba23          	sd	a0,-652(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800012a4:	6605                	lui	a2,0x1
    800012a6:	4581                	li	a1,0
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	aea080e7          	jalr	-1302(ra) # 80000d92 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012b0:	4699                	li	a3,6
    800012b2:	6605                	lui	a2,0x1
    800012b4:	100005b7          	lui	a1,0x10000
    800012b8:	10000537          	lui	a0,0x10000
    800012bc:	00000097          	auipc	ra,0x0
    800012c0:	f96080e7          	jalr	-106(ra) # 80001252 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012c4:	4699                	li	a3,6
    800012c6:	6605                	lui	a2,0x1
    800012c8:	100015b7          	lui	a1,0x10001
    800012cc:	10001537          	lui	a0,0x10001
    800012d0:	00000097          	auipc	ra,0x0
    800012d4:	f82080e7          	jalr	-126(ra) # 80001252 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012d8:	4699                	li	a3,6
    800012da:	6641                	lui	a2,0x10
    800012dc:	020005b7          	lui	a1,0x2000
    800012e0:	02000537          	lui	a0,0x2000
    800012e4:	00000097          	auipc	ra,0x0
    800012e8:	f6e080e7          	jalr	-146(ra) # 80001252 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012ec:	4699                	li	a3,6
    800012ee:	00400637          	lui	a2,0x400
    800012f2:	0c0005b7          	lui	a1,0xc000
    800012f6:	0c000537          	lui	a0,0xc000
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	f58080e7          	jalr	-168(ra) # 80001252 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001302:	00007497          	auipc	s1,0x7
    80001306:	cfe48493          	addi	s1,s1,-770 # 80008000 <etext>
    8000130a:	46a9                	li	a3,10
    8000130c:	80007617          	auipc	a2,0x80007
    80001310:	cf460613          	addi	a2,a2,-780 # 8000 <_entry-0x7fff8000>
    80001314:	4585                	li	a1,1
    80001316:	05fe                	slli	a1,a1,0x1f
    80001318:	852e                	mv	a0,a1
    8000131a:	00000097          	auipc	ra,0x0
    8000131e:	f38080e7          	jalr	-200(ra) # 80001252 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001322:	4699                	li	a3,6
    80001324:	4645                	li	a2,17
    80001326:	066e                	slli	a2,a2,0x1b
    80001328:	8e05                	sub	a2,a2,s1
    8000132a:	85a6                	mv	a1,s1
    8000132c:	8526                	mv	a0,s1
    8000132e:	00000097          	auipc	ra,0x0
    80001332:	f24080e7          	jalr	-220(ra) # 80001252 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001336:	46a9                	li	a3,10
    80001338:	6605                	lui	a2,0x1
    8000133a:	00006597          	auipc	a1,0x6
    8000133e:	cc658593          	addi	a1,a1,-826 # 80007000 <_trampoline>
    80001342:	04000537          	lui	a0,0x4000
    80001346:	157d                	addi	a0,a0,-1
    80001348:	0532                	slli	a0,a0,0xc
    8000134a:	00000097          	auipc	ra,0x0
    8000134e:	f08080e7          	jalr	-248(ra) # 80001252 <kvmmap>
}
    80001352:	60e2                	ld	ra,24(sp)
    80001354:	6442                	ld	s0,16(sp)
    80001356:	64a2                	ld	s1,8(sp)
    80001358:	6105                	addi	sp,sp,32
    8000135a:	8082                	ret

000000008000135c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000135c:	715d                	addi	sp,sp,-80
    8000135e:	e486                	sd	ra,72(sp)
    80001360:	e0a2                	sd	s0,64(sp)
    80001362:	fc26                	sd	s1,56(sp)
    80001364:	f84a                	sd	s2,48(sp)
    80001366:	f44e                	sd	s3,40(sp)
    80001368:	f052                	sd	s4,32(sp)
    8000136a:	ec56                	sd	s5,24(sp)
    8000136c:	e85a                	sd	s6,16(sp)
    8000136e:	e45e                	sd	s7,8(sp)
    80001370:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001372:	03459793          	slli	a5,a1,0x34
    80001376:	e795                	bnez	a5,800013a2 <uvmunmap+0x46>
    80001378:	8a2a                	mv	s4,a0
    8000137a:	892e                	mv	s2,a1
    8000137c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000137e:	0632                	slli	a2,a2,0xc
    80001380:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001384:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001386:	6b05                	lui	s6,0x1
    80001388:	0735e863          	bltu	a1,s3,800013f8 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000138c:	60a6                	ld	ra,72(sp)
    8000138e:	6406                	ld	s0,64(sp)
    80001390:	74e2                	ld	s1,56(sp)
    80001392:	7942                	ld	s2,48(sp)
    80001394:	79a2                	ld	s3,40(sp)
    80001396:	7a02                	ld	s4,32(sp)
    80001398:	6ae2                	ld	s5,24(sp)
    8000139a:	6b42                	ld	s6,16(sp)
    8000139c:	6ba2                	ld	s7,8(sp)
    8000139e:	6161                	addi	sp,sp,80
    800013a0:	8082                	ret
    panic("uvmunmap: not aligned");
    800013a2:	00007517          	auipc	a0,0x7
    800013a6:	d6650513          	addi	a0,a0,-666 # 80008108 <digits+0xb0>
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	24e080e7          	jalr	590(ra) # 800005f8 <panic>
      panic("uvmunmap: walk");
    800013b2:	00007517          	auipc	a0,0x7
    800013b6:	d6e50513          	addi	a0,a0,-658 # 80008120 <digits+0xc8>
    800013ba:	fffff097          	auipc	ra,0xfffff
    800013be:	23e080e7          	jalr	574(ra) # 800005f8 <panic>
      panic("uvmunmap: not mapped");
    800013c2:	00007517          	auipc	a0,0x7
    800013c6:	d6e50513          	addi	a0,a0,-658 # 80008130 <digits+0xd8>
    800013ca:	fffff097          	auipc	ra,0xfffff
    800013ce:	22e080e7          	jalr	558(ra) # 800005f8 <panic>
      panic("uvmunmap: not a leaf");
    800013d2:	00007517          	auipc	a0,0x7
    800013d6:	d7650513          	addi	a0,a0,-650 # 80008148 <digits+0xf0>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	21e080e7          	jalr	542(ra) # 800005f8 <panic>
      uint64 pa = PTE2PA(*pte);
    800013e2:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013e4:	0532                	slli	a0,a0,0xc
    800013e6:	fffff097          	auipc	ra,0xfffff
    800013ea:	6c4080e7          	jalr	1732(ra) # 80000aaa <kfree>
    *pte = 0;
    800013ee:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013f2:	995a                	add	s2,s2,s6
    800013f4:	f9397ce3          	bgeu	s2,s3,8000138c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013f8:	4601                	li	a2,0
    800013fa:	85ca                	mv	a1,s2
    800013fc:	8552                	mv	a0,s4
    800013fe:	00000097          	auipc	ra,0x0
    80001402:	c80080e7          	jalr	-896(ra) # 8000107e <walk>
    80001406:	84aa                	mv	s1,a0
    80001408:	d54d                	beqz	a0,800013b2 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000140a:	6108                	ld	a0,0(a0)
    8000140c:	00157793          	andi	a5,a0,1
    80001410:	dbcd                	beqz	a5,800013c2 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001412:	3ff57793          	andi	a5,a0,1023
    80001416:	fb778ee3          	beq	a5,s7,800013d2 <uvmunmap+0x76>
    if(do_free){
    8000141a:	fc0a8ae3          	beqz	s5,800013ee <uvmunmap+0x92>
    8000141e:	b7d1                	j	800013e2 <uvmunmap+0x86>

0000000080001420 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001420:	1101                	addi	sp,sp,-32
    80001422:	ec06                	sd	ra,24(sp)
    80001424:	e822                	sd	s0,16(sp)
    80001426:	e426                	sd	s1,8(sp)
    80001428:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000142a:	fffff097          	auipc	ra,0xfffff
    8000142e:	77c080e7          	jalr	1916(ra) # 80000ba6 <kalloc>
    80001432:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001434:	c519                	beqz	a0,80001442 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001436:	6605                	lui	a2,0x1
    80001438:	4581                	li	a1,0
    8000143a:	00000097          	auipc	ra,0x0
    8000143e:	958080e7          	jalr	-1704(ra) # 80000d92 <memset>
  return pagetable;
}
    80001442:	8526                	mv	a0,s1
    80001444:	60e2                	ld	ra,24(sp)
    80001446:	6442                	ld	s0,16(sp)
    80001448:	64a2                	ld	s1,8(sp)
    8000144a:	6105                	addi	sp,sp,32
    8000144c:	8082                	ret

000000008000144e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000144e:	7179                	addi	sp,sp,-48
    80001450:	f406                	sd	ra,40(sp)
    80001452:	f022                	sd	s0,32(sp)
    80001454:	ec26                	sd	s1,24(sp)
    80001456:	e84a                	sd	s2,16(sp)
    80001458:	e44e                	sd	s3,8(sp)
    8000145a:	e052                	sd	s4,0(sp)
    8000145c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000145e:	6785                	lui	a5,0x1
    80001460:	04f67863          	bgeu	a2,a5,800014b0 <uvminit+0x62>
    80001464:	8a2a                	mv	s4,a0
    80001466:	89ae                	mv	s3,a1
    80001468:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000146a:	fffff097          	auipc	ra,0xfffff
    8000146e:	73c080e7          	jalr	1852(ra) # 80000ba6 <kalloc>
    80001472:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001474:	6605                	lui	a2,0x1
    80001476:	4581                	li	a1,0
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	91a080e7          	jalr	-1766(ra) # 80000d92 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001480:	4779                	li	a4,30
    80001482:	86ca                	mv	a3,s2
    80001484:	6605                	lui	a2,0x1
    80001486:	4581                	li	a1,0
    80001488:	8552                	mv	a0,s4
    8000148a:	00000097          	auipc	ra,0x0
    8000148e:	d3a080e7          	jalr	-710(ra) # 800011c4 <mappages>
  memmove(mem, src, sz);
    80001492:	8626                	mv	a2,s1
    80001494:	85ce                	mv	a1,s3
    80001496:	854a                	mv	a0,s2
    80001498:	00000097          	auipc	ra,0x0
    8000149c:	95a080e7          	jalr	-1702(ra) # 80000df2 <memmove>
}
    800014a0:	70a2                	ld	ra,40(sp)
    800014a2:	7402                	ld	s0,32(sp)
    800014a4:	64e2                	ld	s1,24(sp)
    800014a6:	6942                	ld	s2,16(sp)
    800014a8:	69a2                	ld	s3,8(sp)
    800014aa:	6a02                	ld	s4,0(sp)
    800014ac:	6145                	addi	sp,sp,48
    800014ae:	8082                	ret
    panic("inituvm: more than a page");
    800014b0:	00007517          	auipc	a0,0x7
    800014b4:	cb050513          	addi	a0,a0,-848 # 80008160 <digits+0x108>
    800014b8:	fffff097          	auipc	ra,0xfffff
    800014bc:	140080e7          	jalr	320(ra) # 800005f8 <panic>

00000000800014c0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014c0:	1101                	addi	sp,sp,-32
    800014c2:	ec06                	sd	ra,24(sp)
    800014c4:	e822                	sd	s0,16(sp)
    800014c6:	e426                	sd	s1,8(sp)
    800014c8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014ca:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014cc:	00b67d63          	bgeu	a2,a1,800014e6 <uvmdealloc+0x26>
    800014d0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014d2:	6785                	lui	a5,0x1
    800014d4:	17fd                	addi	a5,a5,-1
    800014d6:	00f60733          	add	a4,a2,a5
    800014da:	767d                	lui	a2,0xfffff
    800014dc:	8f71                	and	a4,a4,a2
    800014de:	97ae                	add	a5,a5,a1
    800014e0:	8ff1                	and	a5,a5,a2
    800014e2:	00f76863          	bltu	a4,a5,800014f2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014e6:	8526                	mv	a0,s1
    800014e8:	60e2                	ld	ra,24(sp)
    800014ea:	6442                	ld	s0,16(sp)
    800014ec:	64a2                	ld	s1,8(sp)
    800014ee:	6105                	addi	sp,sp,32
    800014f0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014f2:	8f99                	sub	a5,a5,a4
    800014f4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014f6:	4685                	li	a3,1
    800014f8:	0007861b          	sext.w	a2,a5
    800014fc:	85ba                	mv	a1,a4
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	e5e080e7          	jalr	-418(ra) # 8000135c <uvmunmap>
    80001506:	b7c5                	j	800014e6 <uvmdealloc+0x26>

0000000080001508 <uvmalloc>:
  if(newsz < oldsz)
    80001508:	0ab66163          	bltu	a2,a1,800015aa <uvmalloc+0xa2>
{
    8000150c:	7139                	addi	sp,sp,-64
    8000150e:	fc06                	sd	ra,56(sp)
    80001510:	f822                	sd	s0,48(sp)
    80001512:	f426                	sd	s1,40(sp)
    80001514:	f04a                	sd	s2,32(sp)
    80001516:	ec4e                	sd	s3,24(sp)
    80001518:	e852                	sd	s4,16(sp)
    8000151a:	e456                	sd	s5,8(sp)
    8000151c:	0080                	addi	s0,sp,64
    8000151e:	8aaa                	mv	s5,a0
    80001520:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001522:	6985                	lui	s3,0x1
    80001524:	19fd                	addi	s3,s3,-1
    80001526:	95ce                	add	a1,a1,s3
    80001528:	79fd                	lui	s3,0xfffff
    8000152a:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000152e:	08c9f063          	bgeu	s3,a2,800015ae <uvmalloc+0xa6>
    80001532:	894e                	mv	s2,s3
    mem = kalloc();
    80001534:	fffff097          	auipc	ra,0xfffff
    80001538:	672080e7          	jalr	1650(ra) # 80000ba6 <kalloc>
    8000153c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000153e:	c51d                	beqz	a0,8000156c <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001540:	6605                	lui	a2,0x1
    80001542:	4581                	li	a1,0
    80001544:	00000097          	auipc	ra,0x0
    80001548:	84e080e7          	jalr	-1970(ra) # 80000d92 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000154c:	4779                	li	a4,30
    8000154e:	86a6                	mv	a3,s1
    80001550:	6605                	lui	a2,0x1
    80001552:	85ca                	mv	a1,s2
    80001554:	8556                	mv	a0,s5
    80001556:	00000097          	auipc	ra,0x0
    8000155a:	c6e080e7          	jalr	-914(ra) # 800011c4 <mappages>
    8000155e:	e905                	bnez	a0,8000158e <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001560:	6785                	lui	a5,0x1
    80001562:	993e                	add	s2,s2,a5
    80001564:	fd4968e3          	bltu	s2,s4,80001534 <uvmalloc+0x2c>
  return newsz;
    80001568:	8552                	mv	a0,s4
    8000156a:	a809                	j	8000157c <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000156c:	864e                	mv	a2,s3
    8000156e:	85ca                	mv	a1,s2
    80001570:	8556                	mv	a0,s5
    80001572:	00000097          	auipc	ra,0x0
    80001576:	f4e080e7          	jalr	-178(ra) # 800014c0 <uvmdealloc>
      return 0;
    8000157a:	4501                	li	a0,0
}
    8000157c:	70e2                	ld	ra,56(sp)
    8000157e:	7442                	ld	s0,48(sp)
    80001580:	74a2                	ld	s1,40(sp)
    80001582:	7902                	ld	s2,32(sp)
    80001584:	69e2                	ld	s3,24(sp)
    80001586:	6a42                	ld	s4,16(sp)
    80001588:	6aa2                	ld	s5,8(sp)
    8000158a:	6121                	addi	sp,sp,64
    8000158c:	8082                	ret
      kfree(mem);
    8000158e:	8526                	mv	a0,s1
    80001590:	fffff097          	auipc	ra,0xfffff
    80001594:	51a080e7          	jalr	1306(ra) # 80000aaa <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001598:	864e                	mv	a2,s3
    8000159a:	85ca                	mv	a1,s2
    8000159c:	8556                	mv	a0,s5
    8000159e:	00000097          	auipc	ra,0x0
    800015a2:	f22080e7          	jalr	-222(ra) # 800014c0 <uvmdealloc>
      return 0;
    800015a6:	4501                	li	a0,0
    800015a8:	bfd1                	j	8000157c <uvmalloc+0x74>
    return oldsz;
    800015aa:	852e                	mv	a0,a1
}
    800015ac:	8082                	ret
  return newsz;
    800015ae:	8532                	mv	a0,a2
    800015b0:	b7f1                	j	8000157c <uvmalloc+0x74>

00000000800015b2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015b2:	7179                	addi	sp,sp,-48
    800015b4:	f406                	sd	ra,40(sp)
    800015b6:	f022                	sd	s0,32(sp)
    800015b8:	ec26                	sd	s1,24(sp)
    800015ba:	e84a                	sd	s2,16(sp)
    800015bc:	e44e                	sd	s3,8(sp)
    800015be:	e052                	sd	s4,0(sp)
    800015c0:	1800                	addi	s0,sp,48
    800015c2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015c4:	84aa                	mv	s1,a0
    800015c6:	6905                	lui	s2,0x1
    800015c8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ca:	4985                	li	s3,1
    800015cc:	a821                	j	800015e4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015ce:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015d0:	0532                	slli	a0,a0,0xc
    800015d2:	00000097          	auipc	ra,0x0
    800015d6:	fe0080e7          	jalr	-32(ra) # 800015b2 <freewalk>
      pagetable[i] = 0;
    800015da:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015de:	04a1                	addi	s1,s1,8
    800015e0:	03248163          	beq	s1,s2,80001602 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015e4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015e6:	00f57793          	andi	a5,a0,15
    800015ea:	ff3782e3          	beq	a5,s3,800015ce <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015ee:	8905                	andi	a0,a0,1
    800015f0:	d57d                	beqz	a0,800015de <freewalk+0x2c>
      panic("freewalk: leaf");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	b8e50513          	addi	a0,a0,-1138 # 80008180 <digits+0x128>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	ffe080e7          	jalr	-2(ra) # 800005f8 <panic>
    }
  }
  kfree((void*)pagetable);
    80001602:	8552                	mv	a0,s4
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	4a6080e7          	jalr	1190(ra) # 80000aaa <kfree>
}
    8000160c:	70a2                	ld	ra,40(sp)
    8000160e:	7402                	ld	s0,32(sp)
    80001610:	64e2                	ld	s1,24(sp)
    80001612:	6942                	ld	s2,16(sp)
    80001614:	69a2                	ld	s3,8(sp)
    80001616:	6a02                	ld	s4,0(sp)
    80001618:	6145                	addi	sp,sp,48
    8000161a:	8082                	ret

000000008000161c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000161c:	1101                	addi	sp,sp,-32
    8000161e:	ec06                	sd	ra,24(sp)
    80001620:	e822                	sd	s0,16(sp)
    80001622:	e426                	sd	s1,8(sp)
    80001624:	1000                	addi	s0,sp,32
    80001626:	84aa                	mv	s1,a0
  if(sz > 0)
    80001628:	e999                	bnez	a1,8000163e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000162a:	8526                	mv	a0,s1
    8000162c:	00000097          	auipc	ra,0x0
    80001630:	f86080e7          	jalr	-122(ra) # 800015b2 <freewalk>
}
    80001634:	60e2                	ld	ra,24(sp)
    80001636:	6442                	ld	s0,16(sp)
    80001638:	64a2                	ld	s1,8(sp)
    8000163a:	6105                	addi	sp,sp,32
    8000163c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000163e:	6605                	lui	a2,0x1
    80001640:	167d                	addi	a2,a2,-1
    80001642:	962e                	add	a2,a2,a1
    80001644:	4685                	li	a3,1
    80001646:	8231                	srli	a2,a2,0xc
    80001648:	4581                	li	a1,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	d12080e7          	jalr	-750(ra) # 8000135c <uvmunmap>
    80001652:	bfe1                	j	8000162a <uvmfree+0xe>

0000000080001654 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001654:	c679                	beqz	a2,80001722 <uvmcopy+0xce>
{
    80001656:	715d                	addi	sp,sp,-80
    80001658:	e486                	sd	ra,72(sp)
    8000165a:	e0a2                	sd	s0,64(sp)
    8000165c:	fc26                	sd	s1,56(sp)
    8000165e:	f84a                	sd	s2,48(sp)
    80001660:	f44e                	sd	s3,40(sp)
    80001662:	f052                	sd	s4,32(sp)
    80001664:	ec56                	sd	s5,24(sp)
    80001666:	e85a                	sd	s6,16(sp)
    80001668:	e45e                	sd	s7,8(sp)
    8000166a:	0880                	addi	s0,sp,80
    8000166c:	8b2a                	mv	s6,a0
    8000166e:	8aae                	mv	s5,a1
    80001670:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001672:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001674:	4601                	li	a2,0
    80001676:	85ce                	mv	a1,s3
    80001678:	855a                	mv	a0,s6
    8000167a:	00000097          	auipc	ra,0x0
    8000167e:	a04080e7          	jalr	-1532(ra) # 8000107e <walk>
    80001682:	c531                	beqz	a0,800016ce <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001684:	6118                	ld	a4,0(a0)
    80001686:	00177793          	andi	a5,a4,1
    8000168a:	cbb1                	beqz	a5,800016de <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000168c:	00a75593          	srli	a1,a4,0xa
    80001690:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001694:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001698:	fffff097          	auipc	ra,0xfffff
    8000169c:	50e080e7          	jalr	1294(ra) # 80000ba6 <kalloc>
    800016a0:	892a                	mv	s2,a0
    800016a2:	c939                	beqz	a0,800016f8 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016a4:	6605                	lui	a2,0x1
    800016a6:	85de                	mv	a1,s7
    800016a8:	fffff097          	auipc	ra,0xfffff
    800016ac:	74a080e7          	jalr	1866(ra) # 80000df2 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016b0:	8726                	mv	a4,s1
    800016b2:	86ca                	mv	a3,s2
    800016b4:	6605                	lui	a2,0x1
    800016b6:	85ce                	mv	a1,s3
    800016b8:	8556                	mv	a0,s5
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	b0a080e7          	jalr	-1270(ra) # 800011c4 <mappages>
    800016c2:	e515                	bnez	a0,800016ee <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016c4:	6785                	lui	a5,0x1
    800016c6:	99be                	add	s3,s3,a5
    800016c8:	fb49e6e3          	bltu	s3,s4,80001674 <uvmcopy+0x20>
    800016cc:	a081                	j	8000170c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016ce:	00007517          	auipc	a0,0x7
    800016d2:	ac250513          	addi	a0,a0,-1342 # 80008190 <digits+0x138>
    800016d6:	fffff097          	auipc	ra,0xfffff
    800016da:	f22080e7          	jalr	-222(ra) # 800005f8 <panic>
      panic("uvmcopy: page not present");
    800016de:	00007517          	auipc	a0,0x7
    800016e2:	ad250513          	addi	a0,a0,-1326 # 800081b0 <digits+0x158>
    800016e6:	fffff097          	auipc	ra,0xfffff
    800016ea:	f12080e7          	jalr	-238(ra) # 800005f8 <panic>
      kfree(mem);
    800016ee:	854a                	mv	a0,s2
    800016f0:	fffff097          	auipc	ra,0xfffff
    800016f4:	3ba080e7          	jalr	954(ra) # 80000aaa <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016f8:	4685                	li	a3,1
    800016fa:	00c9d613          	srli	a2,s3,0xc
    800016fe:	4581                	li	a1,0
    80001700:	8556                	mv	a0,s5
    80001702:	00000097          	auipc	ra,0x0
    80001706:	c5a080e7          	jalr	-934(ra) # 8000135c <uvmunmap>
  return -1;
    8000170a:	557d                	li	a0,-1
}
    8000170c:	60a6                	ld	ra,72(sp)
    8000170e:	6406                	ld	s0,64(sp)
    80001710:	74e2                	ld	s1,56(sp)
    80001712:	7942                	ld	s2,48(sp)
    80001714:	79a2                	ld	s3,40(sp)
    80001716:	7a02                	ld	s4,32(sp)
    80001718:	6ae2                	ld	s5,24(sp)
    8000171a:	6b42                	ld	s6,16(sp)
    8000171c:	6ba2                	ld	s7,8(sp)
    8000171e:	6161                	addi	sp,sp,80
    80001720:	8082                	ret
  return 0;
    80001722:	4501                	li	a0,0
}
    80001724:	8082                	ret

0000000080001726 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001726:	1141                	addi	sp,sp,-16
    80001728:	e406                	sd	ra,8(sp)
    8000172a:	e022                	sd	s0,0(sp)
    8000172c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000172e:	4601                	li	a2,0
    80001730:	00000097          	auipc	ra,0x0
    80001734:	94e080e7          	jalr	-1714(ra) # 8000107e <walk>
  if(pte == 0)
    80001738:	c901                	beqz	a0,80001748 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000173a:	611c                	ld	a5,0(a0)
    8000173c:	9bbd                	andi	a5,a5,-17
    8000173e:	e11c                	sd	a5,0(a0)
}
    80001740:	60a2                	ld	ra,8(sp)
    80001742:	6402                	ld	s0,0(sp)
    80001744:	0141                	addi	sp,sp,16
    80001746:	8082                	ret
    panic("uvmclear");
    80001748:	00007517          	auipc	a0,0x7
    8000174c:	a8850513          	addi	a0,a0,-1400 # 800081d0 <digits+0x178>
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	ea8080e7          	jalr	-344(ra) # 800005f8 <panic>

0000000080001758 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001758:	c6bd                	beqz	a3,800017c6 <copyout+0x6e>
{
    8000175a:	715d                	addi	sp,sp,-80
    8000175c:	e486                	sd	ra,72(sp)
    8000175e:	e0a2                	sd	s0,64(sp)
    80001760:	fc26                	sd	s1,56(sp)
    80001762:	f84a                	sd	s2,48(sp)
    80001764:	f44e                	sd	s3,40(sp)
    80001766:	f052                	sd	s4,32(sp)
    80001768:	ec56                	sd	s5,24(sp)
    8000176a:	e85a                	sd	s6,16(sp)
    8000176c:	e45e                	sd	s7,8(sp)
    8000176e:	e062                	sd	s8,0(sp)
    80001770:	0880                	addi	s0,sp,80
    80001772:	8b2a                	mv	s6,a0
    80001774:	8c2e                	mv	s8,a1
    80001776:	8a32                	mv	s4,a2
    80001778:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000177a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000177c:	6a85                	lui	s5,0x1
    8000177e:	a015                	j	800017a2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001780:	9562                	add	a0,a0,s8
    80001782:	0004861b          	sext.w	a2,s1
    80001786:	85d2                	mv	a1,s4
    80001788:	41250533          	sub	a0,a0,s2
    8000178c:	fffff097          	auipc	ra,0xfffff
    80001790:	666080e7          	jalr	1638(ra) # 80000df2 <memmove>

    len -= n;
    80001794:	409989b3          	sub	s3,s3,s1
    src += n;
    80001798:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000179a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000179e:	02098263          	beqz	s3,800017c2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017a2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017a6:	85ca                	mv	a1,s2
    800017a8:	855a                	mv	a0,s6
    800017aa:	00000097          	auipc	ra,0x0
    800017ae:	97a080e7          	jalr	-1670(ra) # 80001124 <walkaddr>
    if(pa0 == 0)
    800017b2:	cd01                	beqz	a0,800017ca <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017b4:	418904b3          	sub	s1,s2,s8
    800017b8:	94d6                	add	s1,s1,s5
    if(n > len)
    800017ba:	fc99f3e3          	bgeu	s3,s1,80001780 <copyout+0x28>
    800017be:	84ce                	mv	s1,s3
    800017c0:	b7c1                	j	80001780 <copyout+0x28>
  }
  return 0;
    800017c2:	4501                	li	a0,0
    800017c4:	a021                	j	800017cc <copyout+0x74>
    800017c6:	4501                	li	a0,0
}
    800017c8:	8082                	ret
      return -1;
    800017ca:	557d                	li	a0,-1
}
    800017cc:	60a6                	ld	ra,72(sp)
    800017ce:	6406                	ld	s0,64(sp)
    800017d0:	74e2                	ld	s1,56(sp)
    800017d2:	7942                	ld	s2,48(sp)
    800017d4:	79a2                	ld	s3,40(sp)
    800017d6:	7a02                	ld	s4,32(sp)
    800017d8:	6ae2                	ld	s5,24(sp)
    800017da:	6b42                	ld	s6,16(sp)
    800017dc:	6ba2                	ld	s7,8(sp)
    800017de:	6c02                	ld	s8,0(sp)
    800017e0:	6161                	addi	sp,sp,80
    800017e2:	8082                	ret

00000000800017e4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017e4:	c6bd                	beqz	a3,80001852 <copyin+0x6e>
{
    800017e6:	715d                	addi	sp,sp,-80
    800017e8:	e486                	sd	ra,72(sp)
    800017ea:	e0a2                	sd	s0,64(sp)
    800017ec:	fc26                	sd	s1,56(sp)
    800017ee:	f84a                	sd	s2,48(sp)
    800017f0:	f44e                	sd	s3,40(sp)
    800017f2:	f052                	sd	s4,32(sp)
    800017f4:	ec56                	sd	s5,24(sp)
    800017f6:	e85a                	sd	s6,16(sp)
    800017f8:	e45e                	sd	s7,8(sp)
    800017fa:	e062                	sd	s8,0(sp)
    800017fc:	0880                	addi	s0,sp,80
    800017fe:	8b2a                	mv	s6,a0
    80001800:	8a2e                	mv	s4,a1
    80001802:	8c32                	mv	s8,a2
    80001804:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001806:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001808:	6a85                	lui	s5,0x1
    8000180a:	a015                	j	8000182e <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000180c:	9562                	add	a0,a0,s8
    8000180e:	0004861b          	sext.w	a2,s1
    80001812:	412505b3          	sub	a1,a0,s2
    80001816:	8552                	mv	a0,s4
    80001818:	fffff097          	auipc	ra,0xfffff
    8000181c:	5da080e7          	jalr	1498(ra) # 80000df2 <memmove>

    len -= n;
    80001820:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001824:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001826:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000182a:	02098263          	beqz	s3,8000184e <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000182e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001832:	85ca                	mv	a1,s2
    80001834:	855a                	mv	a0,s6
    80001836:	00000097          	auipc	ra,0x0
    8000183a:	8ee080e7          	jalr	-1810(ra) # 80001124 <walkaddr>
    if(pa0 == 0)
    8000183e:	cd01                	beqz	a0,80001856 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001840:	418904b3          	sub	s1,s2,s8
    80001844:	94d6                	add	s1,s1,s5
    if(n > len)
    80001846:	fc99f3e3          	bgeu	s3,s1,8000180c <copyin+0x28>
    8000184a:	84ce                	mv	s1,s3
    8000184c:	b7c1                	j	8000180c <copyin+0x28>
  }
  return 0;
    8000184e:	4501                	li	a0,0
    80001850:	a021                	j	80001858 <copyin+0x74>
    80001852:	4501                	li	a0,0
}
    80001854:	8082                	ret
      return -1;
    80001856:	557d                	li	a0,-1
}
    80001858:	60a6                	ld	ra,72(sp)
    8000185a:	6406                	ld	s0,64(sp)
    8000185c:	74e2                	ld	s1,56(sp)
    8000185e:	7942                	ld	s2,48(sp)
    80001860:	79a2                	ld	s3,40(sp)
    80001862:	7a02                	ld	s4,32(sp)
    80001864:	6ae2                	ld	s5,24(sp)
    80001866:	6b42                	ld	s6,16(sp)
    80001868:	6ba2                	ld	s7,8(sp)
    8000186a:	6c02                	ld	s8,0(sp)
    8000186c:	6161                	addi	sp,sp,80
    8000186e:	8082                	ret

0000000080001870 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001870:	c6c5                	beqz	a3,80001918 <copyinstr+0xa8>
{
    80001872:	715d                	addi	sp,sp,-80
    80001874:	e486                	sd	ra,72(sp)
    80001876:	e0a2                	sd	s0,64(sp)
    80001878:	fc26                	sd	s1,56(sp)
    8000187a:	f84a                	sd	s2,48(sp)
    8000187c:	f44e                	sd	s3,40(sp)
    8000187e:	f052                	sd	s4,32(sp)
    80001880:	ec56                	sd	s5,24(sp)
    80001882:	e85a                	sd	s6,16(sp)
    80001884:	e45e                	sd	s7,8(sp)
    80001886:	0880                	addi	s0,sp,80
    80001888:	8a2a                	mv	s4,a0
    8000188a:	8b2e                	mv	s6,a1
    8000188c:	8bb2                	mv	s7,a2
    8000188e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001890:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001892:	6985                	lui	s3,0x1
    80001894:	a035                	j	800018c0 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001896:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000189a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000189c:	0017b793          	seqz	a5,a5
    800018a0:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018a4:	60a6                	ld	ra,72(sp)
    800018a6:	6406                	ld	s0,64(sp)
    800018a8:	74e2                	ld	s1,56(sp)
    800018aa:	7942                	ld	s2,48(sp)
    800018ac:	79a2                	ld	s3,40(sp)
    800018ae:	7a02                	ld	s4,32(sp)
    800018b0:	6ae2                	ld	s5,24(sp)
    800018b2:	6b42                	ld	s6,16(sp)
    800018b4:	6ba2                	ld	s7,8(sp)
    800018b6:	6161                	addi	sp,sp,80
    800018b8:	8082                	ret
    srcva = va0 + PGSIZE;
    800018ba:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018be:	c8a9                	beqz	s1,80001910 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018c0:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018c4:	85ca                	mv	a1,s2
    800018c6:	8552                	mv	a0,s4
    800018c8:	00000097          	auipc	ra,0x0
    800018cc:	85c080e7          	jalr	-1956(ra) # 80001124 <walkaddr>
    if(pa0 == 0)
    800018d0:	c131                	beqz	a0,80001914 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018d2:	41790833          	sub	a6,s2,s7
    800018d6:	984e                	add	a6,a6,s3
    if(n > max)
    800018d8:	0104f363          	bgeu	s1,a6,800018de <copyinstr+0x6e>
    800018dc:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018de:	955e                	add	a0,a0,s7
    800018e0:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018e4:	fc080be3          	beqz	a6,800018ba <copyinstr+0x4a>
    800018e8:	985a                	add	a6,a6,s6
    800018ea:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018ec:	41650633          	sub	a2,a0,s6
    800018f0:	14fd                	addi	s1,s1,-1
    800018f2:	9b26                	add	s6,s6,s1
    800018f4:	00f60733          	add	a4,a2,a5
    800018f8:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd4000>
    800018fc:	df49                	beqz	a4,80001896 <copyinstr+0x26>
        *dst = *p;
    800018fe:	00e78023          	sb	a4,0(a5)
      --max;
    80001902:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001906:	0785                	addi	a5,a5,1
    while(n > 0){
    80001908:	ff0796e3          	bne	a5,a6,800018f4 <copyinstr+0x84>
      dst++;
    8000190c:	8b42                	mv	s6,a6
    8000190e:	b775                	j	800018ba <copyinstr+0x4a>
    80001910:	4781                	li	a5,0
    80001912:	b769                	j	8000189c <copyinstr+0x2c>
      return -1;
    80001914:	557d                	li	a0,-1
    80001916:	b779                	j	800018a4 <copyinstr+0x34>
  int got_null = 0;
    80001918:	4781                	li	a5,0
  if(got_null){
    8000191a:	0017b793          	seqz	a5,a5
    8000191e:	40f00533          	neg	a0,a5
}
    80001922:	8082                	ret

0000000080001924 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001924:	1101                	addi	sp,sp,-32
    80001926:	ec06                	sd	ra,24(sp)
    80001928:	e822                	sd	s0,16(sp)
    8000192a:	e426                	sd	s1,8(sp)
    8000192c:	1000                	addi	s0,sp,32
    8000192e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	2ec080e7          	jalr	748(ra) # 80000c1c <holding>
    80001938:	c909                	beqz	a0,8000194a <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    8000193a:	749c                	ld	a5,40(s1)
    8000193c:	00978f63          	beq	a5,s1,8000195a <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001940:	60e2                	ld	ra,24(sp)
    80001942:	6442                	ld	s0,16(sp)
    80001944:	64a2                	ld	s1,8(sp)
    80001946:	6105                	addi	sp,sp,32
    80001948:	8082                	ret
    panic("wakeup1");
    8000194a:	00007517          	auipc	a0,0x7
    8000194e:	89650513          	addi	a0,a0,-1898 # 800081e0 <digits+0x188>
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	ca6080e7          	jalr	-858(ra) # 800005f8 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000195a:	4c98                	lw	a4,24(s1)
    8000195c:	4785                	li	a5,1
    8000195e:	fef711e3          	bne	a4,a5,80001940 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001962:	4789                	li	a5,2
    80001964:	cc9c                	sw	a5,24(s1)
}
    80001966:	bfe9                	j	80001940 <wakeup1+0x1c>

0000000080001968 <procinit>:
{
    80001968:	715d                	addi	sp,sp,-80
    8000196a:	e486                	sd	ra,72(sp)
    8000196c:	e0a2                	sd	s0,64(sp)
    8000196e:	fc26                	sd	s1,56(sp)
    80001970:	f84a                	sd	s2,48(sp)
    80001972:	f44e                	sd	s3,40(sp)
    80001974:	f052                	sd	s4,32(sp)
    80001976:	ec56                	sd	s5,24(sp)
    80001978:	e85a                	sd	s6,16(sp)
    8000197a:	e45e                	sd	s7,8(sp)
    8000197c:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    8000197e:	00007597          	auipc	a1,0x7
    80001982:	86a58593          	addi	a1,a1,-1942 # 800081e8 <digits+0x190>
    80001986:	00010517          	auipc	a0,0x10
    8000198a:	fca50513          	addi	a0,a0,-54 # 80011950 <pid_lock>
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	278080e7          	jalr	632(ra) # 80000c06 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001996:	00010917          	auipc	s2,0x10
    8000199a:	3d290913          	addi	s2,s2,978 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    8000199e:	00007b97          	auipc	s7,0x7
    800019a2:	852b8b93          	addi	s7,s7,-1966 # 800081f0 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    800019a6:	8b4a                	mv	s6,s2
    800019a8:	00006a97          	auipc	s5,0x6
    800019ac:	658a8a93          	addi	s5,s5,1624 # 80008000 <etext>
    800019b0:	040009b7          	lui	s3,0x4000
    800019b4:	19fd                	addi	s3,s3,-1
    800019b6:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019b8:	0001ba17          	auipc	s4,0x1b
    800019bc:	bb0a0a13          	addi	s4,s4,-1104 # 8001c568 <tickslock>
      initlock(&p->lock, "proc");
    800019c0:	85de                	mv	a1,s7
    800019c2:	854a                	mv	a0,s2
    800019c4:	fffff097          	auipc	ra,0xfffff
    800019c8:	242080e7          	jalr	578(ra) # 80000c06 <initlock>
      char *pa = kalloc();
    800019cc:	fffff097          	auipc	ra,0xfffff
    800019d0:	1da080e7          	jalr	474(ra) # 80000ba6 <kalloc>
    800019d4:	85aa                	mv	a1,a0
      if(pa == 0)
    800019d6:	c929                	beqz	a0,80001a28 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    800019d8:	416904b3          	sub	s1,s2,s6
    800019dc:	8495                	srai	s1,s1,0x5
    800019de:	000ab783          	ld	a5,0(s5)
    800019e2:	02f484b3          	mul	s1,s1,a5
    800019e6:	2485                	addiw	s1,s1,1
    800019e8:	00d4949b          	slliw	s1,s1,0xd
    800019ec:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019f0:	4699                	li	a3,6
    800019f2:	6605                	lui	a2,0x1
    800019f4:	8526                	mv	a0,s1
    800019f6:	00000097          	auipc	ra,0x0
    800019fa:	85c080e7          	jalr	-1956(ra) # 80001252 <kvmmap>
      p->kstack = va;
    800019fe:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a02:	2a090913          	addi	s2,s2,672
    80001a06:	fb491de3          	bne	s2,s4,800019c0 <procinit+0x58>
  kvminithart();
    80001a0a:	fffff097          	auipc	ra,0xfffff
    80001a0e:	650080e7          	jalr	1616(ra) # 8000105a <kvminithart>
}
    80001a12:	60a6                	ld	ra,72(sp)
    80001a14:	6406                	ld	s0,64(sp)
    80001a16:	74e2                	ld	s1,56(sp)
    80001a18:	7942                	ld	s2,48(sp)
    80001a1a:	79a2                	ld	s3,40(sp)
    80001a1c:	7a02                	ld	s4,32(sp)
    80001a1e:	6ae2                	ld	s5,24(sp)
    80001a20:	6b42                	ld	s6,16(sp)
    80001a22:	6ba2                	ld	s7,8(sp)
    80001a24:	6161                	addi	sp,sp,80
    80001a26:	8082                	ret
        panic("kalloc");
    80001a28:	00006517          	auipc	a0,0x6
    80001a2c:	7d050513          	addi	a0,a0,2000 # 800081f8 <digits+0x1a0>
    80001a30:	fffff097          	auipc	ra,0xfffff
    80001a34:	bc8080e7          	jalr	-1080(ra) # 800005f8 <panic>

0000000080001a38 <cpuid>:
{
    80001a38:	1141                	addi	sp,sp,-16
    80001a3a:	e422                	sd	s0,8(sp)
    80001a3c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a3e:	8512                	mv	a0,tp
}
    80001a40:	2501                	sext.w	a0,a0
    80001a42:	6422                	ld	s0,8(sp)
    80001a44:	0141                	addi	sp,sp,16
    80001a46:	8082                	ret

0000000080001a48 <mycpu>:
mycpu(void) {
    80001a48:	1141                	addi	sp,sp,-16
    80001a4a:	e422                	sd	s0,8(sp)
    80001a4c:	0800                	addi	s0,sp,16
    80001a4e:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a50:	2781                	sext.w	a5,a5
    80001a52:	079e                	slli	a5,a5,0x7
}
    80001a54:	00010517          	auipc	a0,0x10
    80001a58:	f1450513          	addi	a0,a0,-236 # 80011968 <cpus>
    80001a5c:	953e                	add	a0,a0,a5
    80001a5e:	6422                	ld	s0,8(sp)
    80001a60:	0141                	addi	sp,sp,16
    80001a62:	8082                	ret

0000000080001a64 <myproc>:
myproc(void) {
    80001a64:	1101                	addi	sp,sp,-32
    80001a66:	ec06                	sd	ra,24(sp)
    80001a68:	e822                	sd	s0,16(sp)
    80001a6a:	e426                	sd	s1,8(sp)
    80001a6c:	1000                	addi	s0,sp,32
  push_off();
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	1dc080e7          	jalr	476(ra) # 80000c4a <push_off>
    80001a76:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a78:	2781                	sext.w	a5,a5
    80001a7a:	079e                	slli	a5,a5,0x7
    80001a7c:	00010717          	auipc	a4,0x10
    80001a80:	ed470713          	addi	a4,a4,-300 # 80011950 <pid_lock>
    80001a84:	97ba                	add	a5,a5,a4
    80001a86:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	262080e7          	jalr	610(ra) # 80000cea <pop_off>
}
    80001a90:	8526                	mv	a0,s1
    80001a92:	60e2                	ld	ra,24(sp)
    80001a94:	6442                	ld	s0,16(sp)
    80001a96:	64a2                	ld	s1,8(sp)
    80001a98:	6105                	addi	sp,sp,32
    80001a9a:	8082                	ret

0000000080001a9c <forkret>:
{
    80001a9c:	1141                	addi	sp,sp,-16
    80001a9e:	e406                	sd	ra,8(sp)
    80001aa0:	e022                	sd	s0,0(sp)
    80001aa2:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001aa4:	00000097          	auipc	ra,0x0
    80001aa8:	fc0080e7          	jalr	-64(ra) # 80001a64 <myproc>
    80001aac:	fffff097          	auipc	ra,0xfffff
    80001ab0:	29e080e7          	jalr	670(ra) # 80000d4a <release>
  if (first) {
    80001ab4:	00007797          	auipc	a5,0x7
    80001ab8:	d8c7a783          	lw	a5,-628(a5) # 80008840 <first.1672>
    80001abc:	eb89                	bnez	a5,80001ace <forkret+0x32>
  usertrapret();
    80001abe:	00001097          	auipc	ra,0x1
    80001ac2:	c30080e7          	jalr	-976(ra) # 800026ee <usertrapret>
}
    80001ac6:	60a2                	ld	ra,8(sp)
    80001ac8:	6402                	ld	s0,0(sp)
    80001aca:	0141                	addi	sp,sp,16
    80001acc:	8082                	ret
    first = 0;
    80001ace:	00007797          	auipc	a5,0x7
    80001ad2:	d607a923          	sw	zero,-654(a5) # 80008840 <first.1672>
    fsinit(ROOTDEV);
    80001ad6:	4505                	li	a0,1
    80001ad8:	00002097          	auipc	ra,0x2
    80001adc:	a9c080e7          	jalr	-1380(ra) # 80003574 <fsinit>
    80001ae0:	bff9                	j	80001abe <forkret+0x22>

0000000080001ae2 <allocpid>:
allocpid() {
    80001ae2:	1101                	addi	sp,sp,-32
    80001ae4:	ec06                	sd	ra,24(sp)
    80001ae6:	e822                	sd	s0,16(sp)
    80001ae8:	e426                	sd	s1,8(sp)
    80001aea:	e04a                	sd	s2,0(sp)
    80001aec:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aee:	00010917          	auipc	s2,0x10
    80001af2:	e6290913          	addi	s2,s2,-414 # 80011950 <pid_lock>
    80001af6:	854a                	mv	a0,s2
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	19e080e7          	jalr	414(ra) # 80000c96 <acquire>
  pid = nextpid;
    80001b00:	00007797          	auipc	a5,0x7
    80001b04:	d4478793          	addi	a5,a5,-700 # 80008844 <nextpid>
    80001b08:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b0a:	0014871b          	addiw	a4,s1,1
    80001b0e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b10:	854a                	mv	a0,s2
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	238080e7          	jalr	568(ra) # 80000d4a <release>
}
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	60e2                	ld	ra,24(sp)
    80001b1e:	6442                	ld	s0,16(sp)
    80001b20:	64a2                	ld	s1,8(sp)
    80001b22:	6902                	ld	s2,0(sp)
    80001b24:	6105                	addi	sp,sp,32
    80001b26:	8082                	ret

0000000080001b28 <proc_pagetable>:
{
    80001b28:	1101                	addi	sp,sp,-32
    80001b2a:	ec06                	sd	ra,24(sp)
    80001b2c:	e822                	sd	s0,16(sp)
    80001b2e:	e426                	sd	s1,8(sp)
    80001b30:	e04a                	sd	s2,0(sp)
    80001b32:	1000                	addi	s0,sp,32
    80001b34:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b36:	00000097          	auipc	ra,0x0
    80001b3a:	8ea080e7          	jalr	-1814(ra) # 80001420 <uvmcreate>
    80001b3e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b40:	c121                	beqz	a0,80001b80 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b42:	4729                	li	a4,10
    80001b44:	00005697          	auipc	a3,0x5
    80001b48:	4bc68693          	addi	a3,a3,1212 # 80007000 <_trampoline>
    80001b4c:	6605                	lui	a2,0x1
    80001b4e:	040005b7          	lui	a1,0x4000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b2                	slli	a1,a1,0xc
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	66e080e7          	jalr	1646(ra) # 800011c4 <mappages>
    80001b5e:	02054863          	bltz	a0,80001b8e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b62:	4719                	li	a4,6
    80001b64:	05893683          	ld	a3,88(s2)
    80001b68:	6605                	lui	a2,0x1
    80001b6a:	020005b7          	lui	a1,0x2000
    80001b6e:	15fd                	addi	a1,a1,-1
    80001b70:	05b6                	slli	a1,a1,0xd
    80001b72:	8526                	mv	a0,s1
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	650080e7          	jalr	1616(ra) # 800011c4 <mappages>
    80001b7c:	02054163          	bltz	a0,80001b9e <proc_pagetable+0x76>
}
    80001b80:	8526                	mv	a0,s1
    80001b82:	60e2                	ld	ra,24(sp)
    80001b84:	6442                	ld	s0,16(sp)
    80001b86:	64a2                	ld	s1,8(sp)
    80001b88:	6902                	ld	s2,0(sp)
    80001b8a:	6105                	addi	sp,sp,32
    80001b8c:	8082                	ret
    uvmfree(pagetable, 0);
    80001b8e:	4581                	li	a1,0
    80001b90:	8526                	mv	a0,s1
    80001b92:	00000097          	auipc	ra,0x0
    80001b96:	a8a080e7          	jalr	-1398(ra) # 8000161c <uvmfree>
    return 0;
    80001b9a:	4481                	li	s1,0
    80001b9c:	b7d5                	j	80001b80 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b9e:	4681                	li	a3,0
    80001ba0:	4605                	li	a2,1
    80001ba2:	040005b7          	lui	a1,0x4000
    80001ba6:	15fd                	addi	a1,a1,-1
    80001ba8:	05b2                	slli	a1,a1,0xc
    80001baa:	8526                	mv	a0,s1
    80001bac:	fffff097          	auipc	ra,0xfffff
    80001bb0:	7b0080e7          	jalr	1968(ra) # 8000135c <uvmunmap>
    uvmfree(pagetable, 0);
    80001bb4:	4581                	li	a1,0
    80001bb6:	8526                	mv	a0,s1
    80001bb8:	00000097          	auipc	ra,0x0
    80001bbc:	a64080e7          	jalr	-1436(ra) # 8000161c <uvmfree>
    return 0;
    80001bc0:	4481                	li	s1,0
    80001bc2:	bf7d                	j	80001b80 <proc_pagetable+0x58>

0000000080001bc4 <proc_freepagetable>:
{
    80001bc4:	1101                	addi	sp,sp,-32
    80001bc6:	ec06                	sd	ra,24(sp)
    80001bc8:	e822                	sd	s0,16(sp)
    80001bca:	e426                	sd	s1,8(sp)
    80001bcc:	e04a                	sd	s2,0(sp)
    80001bce:	1000                	addi	s0,sp,32
    80001bd0:	84aa                	mv	s1,a0
    80001bd2:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bd4:	4681                	li	a3,0
    80001bd6:	4605                	li	a2,1
    80001bd8:	040005b7          	lui	a1,0x4000
    80001bdc:	15fd                	addi	a1,a1,-1
    80001bde:	05b2                	slli	a1,a1,0xc
    80001be0:	fffff097          	auipc	ra,0xfffff
    80001be4:	77c080e7          	jalr	1916(ra) # 8000135c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001be8:	4681                	li	a3,0
    80001bea:	4605                	li	a2,1
    80001bec:	020005b7          	lui	a1,0x2000
    80001bf0:	15fd                	addi	a1,a1,-1
    80001bf2:	05b6                	slli	a1,a1,0xd
    80001bf4:	8526                	mv	a0,s1
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	766080e7          	jalr	1894(ra) # 8000135c <uvmunmap>
  uvmfree(pagetable, sz);
    80001bfe:	85ca                	mv	a1,s2
    80001c00:	8526                	mv	a0,s1
    80001c02:	00000097          	auipc	ra,0x0
    80001c06:	a1a080e7          	jalr	-1510(ra) # 8000161c <uvmfree>
}
    80001c0a:	60e2                	ld	ra,24(sp)
    80001c0c:	6442                	ld	s0,16(sp)
    80001c0e:	64a2                	ld	s1,8(sp)
    80001c10:	6902                	ld	s2,0(sp)
    80001c12:	6105                	addi	sp,sp,32
    80001c14:	8082                	ret

0000000080001c16 <freeproc>:
{
    80001c16:	1101                	addi	sp,sp,-32
    80001c18:	ec06                	sd	ra,24(sp)
    80001c1a:	e822                	sd	s0,16(sp)
    80001c1c:	e426                	sd	s1,8(sp)
    80001c1e:	1000                	addi	s0,sp,32
    80001c20:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c22:	6d28                	ld	a0,88(a0)
    80001c24:	c509                	beqz	a0,80001c2e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	e84080e7          	jalr	-380(ra) # 80000aaa <kfree>
  p->trapframe = 0;
    80001c2e:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c32:	68a8                	ld	a0,80(s1)
    80001c34:	c511                	beqz	a0,80001c40 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c36:	64ac                	ld	a1,72(s1)
    80001c38:	00000097          	auipc	ra,0x0
    80001c3c:	f8c080e7          	jalr	-116(ra) # 80001bc4 <proc_freepagetable>
  p->pagetable = 0;
    80001c40:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c44:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c48:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c4c:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c50:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c54:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c58:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c5c:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c60:	0004ac23          	sw	zero,24(s1)
  p->interval=0;
    80001c64:	1604a423          	sw	zero,360(s1)
  p->since_interval=0;
    80001c68:	1604a623          	sw	zero,364(s1)
  p->running_hand=0;
    80001c6c:	1604ac23          	sw	zero,376(s1)
}
    80001c70:	60e2                	ld	ra,24(sp)
    80001c72:	6442                	ld	s0,16(sp)
    80001c74:	64a2                	ld	s1,8(sp)
    80001c76:	6105                	addi	sp,sp,32
    80001c78:	8082                	ret

0000000080001c7a <allocproc>:
{
    80001c7a:	1101                	addi	sp,sp,-32
    80001c7c:	ec06                	sd	ra,24(sp)
    80001c7e:	e822                	sd	s0,16(sp)
    80001c80:	e426                	sd	s1,8(sp)
    80001c82:	e04a                	sd	s2,0(sp)
    80001c84:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c86:	00010497          	auipc	s1,0x10
    80001c8a:	0e248493          	addi	s1,s1,226 # 80011d68 <proc>
    80001c8e:	0001b917          	auipc	s2,0x1b
    80001c92:	8da90913          	addi	s2,s2,-1830 # 8001c568 <tickslock>
    acquire(&p->lock);
    80001c96:	8526                	mv	a0,s1
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	ffe080e7          	jalr	-2(ra) # 80000c96 <acquire>
    if(p->state == UNUSED) {
    80001ca0:	4c9c                	lw	a5,24(s1)
    80001ca2:	cf81                	beqz	a5,80001cba <allocproc+0x40>
      release(&p->lock);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	0a4080e7          	jalr	164(ra) # 80000d4a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cae:	2a048493          	addi	s1,s1,672
    80001cb2:	ff2492e3          	bne	s1,s2,80001c96 <allocproc+0x1c>
  return 0;
    80001cb6:	4481                	li	s1,0
    80001cb8:	a8a9                	j	80001d12 <allocproc+0x98>
  p->pid = allocpid();
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	e28080e7          	jalr	-472(ra) # 80001ae2 <allocpid>
    80001cc2:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	ee2080e7          	jalr	-286(ra) # 80000ba6 <kalloc>
    80001ccc:	892a                	mv	s2,a0
    80001cce:	eca8                	sd	a0,88(s1)
    80001cd0:	c921                	beqz	a0,80001d20 <allocproc+0xa6>
  p->pagetable = proc_pagetable(p);
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	e54080e7          	jalr	-428(ra) # 80001b28 <proc_pagetable>
    80001cdc:	892a                	mv	s2,a0
    80001cde:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001ce0:	c539                	beqz	a0,80001d2e <allocproc+0xb4>
  memset(&p->context, 0, sizeof(p->context));
    80001ce2:	07000613          	li	a2,112
    80001ce6:	4581                	li	a1,0
    80001ce8:	06048513          	addi	a0,s1,96
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	0a6080e7          	jalr	166(ra) # 80000d92 <memset>
  p->context.ra = (uint64)forkret;
    80001cf4:	00000797          	auipc	a5,0x0
    80001cf8:	da878793          	addi	a5,a5,-600 # 80001a9c <forkret>
    80001cfc:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cfe:	60bc                	ld	a5,64(s1)
    80001d00:	6705                	lui	a4,0x1
    80001d02:	97ba                	add	a5,a5,a4
    80001d04:	f4bc                	sd	a5,104(s1)
  p->interval=0;
    80001d06:	1604a423          	sw	zero,360(s1)
  p->since_interval=0;
    80001d0a:	1604a623          	sw	zero,364(s1)
  p->running_hand=0;
    80001d0e:	1604ac23          	sw	zero,376(s1)
}
    80001d12:	8526                	mv	a0,s1
    80001d14:	60e2                	ld	ra,24(sp)
    80001d16:	6442                	ld	s0,16(sp)
    80001d18:	64a2                	ld	s1,8(sp)
    80001d1a:	6902                	ld	s2,0(sp)
    80001d1c:	6105                	addi	sp,sp,32
    80001d1e:	8082                	ret
    release(&p->lock);
    80001d20:	8526                	mv	a0,s1
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	028080e7          	jalr	40(ra) # 80000d4a <release>
    return 0;
    80001d2a:	84ca                	mv	s1,s2
    80001d2c:	b7dd                	j	80001d12 <allocproc+0x98>
    freeproc(p);
    80001d2e:	8526                	mv	a0,s1
    80001d30:	00000097          	auipc	ra,0x0
    80001d34:	ee6080e7          	jalr	-282(ra) # 80001c16 <freeproc>
    release(&p->lock);
    80001d38:	8526                	mv	a0,s1
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	010080e7          	jalr	16(ra) # 80000d4a <release>
    return 0;
    80001d42:	84ca                	mv	s1,s2
    80001d44:	b7f9                	j	80001d12 <allocproc+0x98>

0000000080001d46 <userinit>:
{
    80001d46:	1101                	addi	sp,sp,-32
    80001d48:	ec06                	sd	ra,24(sp)
    80001d4a:	e822                	sd	s0,16(sp)
    80001d4c:	e426                	sd	s1,8(sp)
    80001d4e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d50:	00000097          	auipc	ra,0x0
    80001d54:	f2a080e7          	jalr	-214(ra) # 80001c7a <allocproc>
    80001d58:	84aa                	mv	s1,a0
  initproc = p;
    80001d5a:	00007797          	auipc	a5,0x7
    80001d5e:	2aa7bf23          	sd	a0,702(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d62:	03400613          	li	a2,52
    80001d66:	00007597          	auipc	a1,0x7
    80001d6a:	aea58593          	addi	a1,a1,-1302 # 80008850 <initcode>
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	6de080e7          	jalr	1758(ra) # 8000144e <uvminit>
  p->sz = PGSIZE;
    80001d78:	6785                	lui	a5,0x1
    80001d7a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d7c:	6cb8                	ld	a4,88(s1)
    80001d7e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d82:	6cb8                	ld	a4,88(s1)
    80001d84:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d86:	4641                	li	a2,16
    80001d88:	00006597          	auipc	a1,0x6
    80001d8c:	47858593          	addi	a1,a1,1144 # 80008200 <digits+0x1a8>
    80001d90:	15848513          	addi	a0,s1,344
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	154080e7          	jalr	340(ra) # 80000ee8 <safestrcpy>
  p->cwd = namei("/");
    80001d9c:	00006517          	auipc	a0,0x6
    80001da0:	47450513          	addi	a0,a0,1140 # 80008210 <digits+0x1b8>
    80001da4:	00002097          	auipc	ra,0x2
    80001da8:	1f8080e7          	jalr	504(ra) # 80003f9c <namei>
    80001dac:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001db0:	4789                	li	a5,2
    80001db2:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001db4:	8526                	mv	a0,s1
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	f94080e7          	jalr	-108(ra) # 80000d4a <release>
}
    80001dbe:	60e2                	ld	ra,24(sp)
    80001dc0:	6442                	ld	s0,16(sp)
    80001dc2:	64a2                	ld	s1,8(sp)
    80001dc4:	6105                	addi	sp,sp,32
    80001dc6:	8082                	ret

0000000080001dc8 <growproc>:
{
    80001dc8:	1101                	addi	sp,sp,-32
    80001dca:	ec06                	sd	ra,24(sp)
    80001dcc:	e822                	sd	s0,16(sp)
    80001dce:	e426                	sd	s1,8(sp)
    80001dd0:	e04a                	sd	s2,0(sp)
    80001dd2:	1000                	addi	s0,sp,32
    80001dd4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dd6:	00000097          	auipc	ra,0x0
    80001dda:	c8e080e7          	jalr	-882(ra) # 80001a64 <myproc>
    80001dde:	892a                	mv	s2,a0
  sz = p->sz;
    80001de0:	652c                	ld	a1,72(a0)
    80001de2:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001de6:	00904f63          	bgtz	s1,80001e04 <growproc+0x3c>
  } else if(n < 0){
    80001dea:	0204cc63          	bltz	s1,80001e22 <growproc+0x5a>
  p->sz = sz;
    80001dee:	1602                	slli	a2,a2,0x20
    80001df0:	9201                	srli	a2,a2,0x20
    80001df2:	04c93423          	sd	a2,72(s2)
  return 0;
    80001df6:	4501                	li	a0,0
}
    80001df8:	60e2                	ld	ra,24(sp)
    80001dfa:	6442                	ld	s0,16(sp)
    80001dfc:	64a2                	ld	s1,8(sp)
    80001dfe:	6902                	ld	s2,0(sp)
    80001e00:	6105                	addi	sp,sp,32
    80001e02:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e04:	9e25                	addw	a2,a2,s1
    80001e06:	1602                	slli	a2,a2,0x20
    80001e08:	9201                	srli	a2,a2,0x20
    80001e0a:	1582                	slli	a1,a1,0x20
    80001e0c:	9181                	srli	a1,a1,0x20
    80001e0e:	6928                	ld	a0,80(a0)
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	6f8080e7          	jalr	1784(ra) # 80001508 <uvmalloc>
    80001e18:	0005061b          	sext.w	a2,a0
    80001e1c:	fa69                	bnez	a2,80001dee <growproc+0x26>
      return -1;
    80001e1e:	557d                	li	a0,-1
    80001e20:	bfe1                	j	80001df8 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e22:	9e25                	addw	a2,a2,s1
    80001e24:	1602                	slli	a2,a2,0x20
    80001e26:	9201                	srli	a2,a2,0x20
    80001e28:	1582                	slli	a1,a1,0x20
    80001e2a:	9181                	srli	a1,a1,0x20
    80001e2c:	6928                	ld	a0,80(a0)
    80001e2e:	fffff097          	auipc	ra,0xfffff
    80001e32:	692080e7          	jalr	1682(ra) # 800014c0 <uvmdealloc>
    80001e36:	0005061b          	sext.w	a2,a0
    80001e3a:	bf55                	j	80001dee <growproc+0x26>

0000000080001e3c <fork>:
{
    80001e3c:	7179                	addi	sp,sp,-48
    80001e3e:	f406                	sd	ra,40(sp)
    80001e40:	f022                	sd	s0,32(sp)
    80001e42:	ec26                	sd	s1,24(sp)
    80001e44:	e84a                	sd	s2,16(sp)
    80001e46:	e44e                	sd	s3,8(sp)
    80001e48:	e052                	sd	s4,0(sp)
    80001e4a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e4c:	00000097          	auipc	ra,0x0
    80001e50:	c18080e7          	jalr	-1000(ra) # 80001a64 <myproc>
    80001e54:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e56:	00000097          	auipc	ra,0x0
    80001e5a:	e24080e7          	jalr	-476(ra) # 80001c7a <allocproc>
    80001e5e:	c175                	beqz	a0,80001f42 <fork+0x106>
    80001e60:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e62:	04893603          	ld	a2,72(s2)
    80001e66:	692c                	ld	a1,80(a0)
    80001e68:	05093503          	ld	a0,80(s2)
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	7e8080e7          	jalr	2024(ra) # 80001654 <uvmcopy>
    80001e74:	04054863          	bltz	a0,80001ec4 <fork+0x88>
  np->sz = p->sz;
    80001e78:	04893783          	ld	a5,72(s2)
    80001e7c:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e80:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e84:	05893683          	ld	a3,88(s2)
    80001e88:	87b6                	mv	a5,a3
    80001e8a:	0589b703          	ld	a4,88(s3)
    80001e8e:	12068693          	addi	a3,a3,288
    80001e92:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e96:	6788                	ld	a0,8(a5)
    80001e98:	6b8c                	ld	a1,16(a5)
    80001e9a:	6f90                	ld	a2,24(a5)
    80001e9c:	01073023          	sd	a6,0(a4)
    80001ea0:	e708                	sd	a0,8(a4)
    80001ea2:	eb0c                	sd	a1,16(a4)
    80001ea4:	ef10                	sd	a2,24(a4)
    80001ea6:	02078793          	addi	a5,a5,32
    80001eaa:	02070713          	addi	a4,a4,32
    80001eae:	fed792e3          	bne	a5,a3,80001e92 <fork+0x56>
  np->trapframe->a0 = 0;
    80001eb2:	0589b783          	ld	a5,88(s3)
    80001eb6:	0607b823          	sd	zero,112(a5)
    80001eba:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001ebe:	15000a13          	li	s4,336
    80001ec2:	a03d                	j	80001ef0 <fork+0xb4>
    freeproc(np);
    80001ec4:	854e                	mv	a0,s3
    80001ec6:	00000097          	auipc	ra,0x0
    80001eca:	d50080e7          	jalr	-688(ra) # 80001c16 <freeproc>
    release(&np->lock);
    80001ece:	854e                	mv	a0,s3
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	e7a080e7          	jalr	-390(ra) # 80000d4a <release>
    return -1;
    80001ed8:	54fd                	li	s1,-1
    80001eda:	a899                	j	80001f30 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001edc:	00002097          	auipc	ra,0x2
    80001ee0:	74c080e7          	jalr	1868(ra) # 80004628 <filedup>
    80001ee4:	009987b3          	add	a5,s3,s1
    80001ee8:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001eea:	04a1                	addi	s1,s1,8
    80001eec:	01448763          	beq	s1,s4,80001efa <fork+0xbe>
    if(p->ofile[i])
    80001ef0:	009907b3          	add	a5,s2,s1
    80001ef4:	6388                	ld	a0,0(a5)
    80001ef6:	f17d                	bnez	a0,80001edc <fork+0xa0>
    80001ef8:	bfcd                	j	80001eea <fork+0xae>
  np->cwd = idup(p->cwd);
    80001efa:	15093503          	ld	a0,336(s2)
    80001efe:	00002097          	auipc	ra,0x2
    80001f02:	8b0080e7          	jalr	-1872(ra) # 800037ae <idup>
    80001f06:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f0a:	4641                	li	a2,16
    80001f0c:	15890593          	addi	a1,s2,344
    80001f10:	15898513          	addi	a0,s3,344
    80001f14:	fffff097          	auipc	ra,0xfffff
    80001f18:	fd4080e7          	jalr	-44(ra) # 80000ee8 <safestrcpy>
  pid = np->pid;
    80001f1c:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001f20:	4789                	li	a5,2
    80001f22:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f26:	854e                	mv	a0,s3
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	e22080e7          	jalr	-478(ra) # 80000d4a <release>
}
    80001f30:	8526                	mv	a0,s1
    80001f32:	70a2                	ld	ra,40(sp)
    80001f34:	7402                	ld	s0,32(sp)
    80001f36:	64e2                	ld	s1,24(sp)
    80001f38:	6942                	ld	s2,16(sp)
    80001f3a:	69a2                	ld	s3,8(sp)
    80001f3c:	6a02                	ld	s4,0(sp)
    80001f3e:	6145                	addi	sp,sp,48
    80001f40:	8082                	ret
    return -1;
    80001f42:	54fd                	li	s1,-1
    80001f44:	b7f5                	j	80001f30 <fork+0xf4>

0000000080001f46 <reparent>:
{
    80001f46:	7179                	addi	sp,sp,-48
    80001f48:	f406                	sd	ra,40(sp)
    80001f4a:	f022                	sd	s0,32(sp)
    80001f4c:	ec26                	sd	s1,24(sp)
    80001f4e:	e84a                	sd	s2,16(sp)
    80001f50:	e44e                	sd	s3,8(sp)
    80001f52:	e052                	sd	s4,0(sp)
    80001f54:	1800                	addi	s0,sp,48
    80001f56:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f58:	00010497          	auipc	s1,0x10
    80001f5c:	e1048493          	addi	s1,s1,-496 # 80011d68 <proc>
      pp->parent = initproc;
    80001f60:	00007a17          	auipc	s4,0x7
    80001f64:	0b8a0a13          	addi	s4,s4,184 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f68:	0001a997          	auipc	s3,0x1a
    80001f6c:	60098993          	addi	s3,s3,1536 # 8001c568 <tickslock>
    80001f70:	a029                	j	80001f7a <reparent+0x34>
    80001f72:	2a048493          	addi	s1,s1,672
    80001f76:	03348363          	beq	s1,s3,80001f9c <reparent+0x56>
    if(pp->parent == p){
    80001f7a:	709c                	ld	a5,32(s1)
    80001f7c:	ff279be3          	bne	a5,s2,80001f72 <reparent+0x2c>
      acquire(&pp->lock);
    80001f80:	8526                	mv	a0,s1
    80001f82:	fffff097          	auipc	ra,0xfffff
    80001f86:	d14080e7          	jalr	-748(ra) # 80000c96 <acquire>
      pp->parent = initproc;
    80001f8a:	000a3783          	ld	a5,0(s4)
    80001f8e:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f90:	8526                	mv	a0,s1
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	db8080e7          	jalr	-584(ra) # 80000d4a <release>
    80001f9a:	bfe1                	j	80001f72 <reparent+0x2c>
}
    80001f9c:	70a2                	ld	ra,40(sp)
    80001f9e:	7402                	ld	s0,32(sp)
    80001fa0:	64e2                	ld	s1,24(sp)
    80001fa2:	6942                	ld	s2,16(sp)
    80001fa4:	69a2                	ld	s3,8(sp)
    80001fa6:	6a02                	ld	s4,0(sp)
    80001fa8:	6145                	addi	sp,sp,48
    80001faa:	8082                	ret

0000000080001fac <scheduler>:
{
    80001fac:	715d                	addi	sp,sp,-80
    80001fae:	e486                	sd	ra,72(sp)
    80001fb0:	e0a2                	sd	s0,64(sp)
    80001fb2:	fc26                	sd	s1,56(sp)
    80001fb4:	f84a                	sd	s2,48(sp)
    80001fb6:	f44e                	sd	s3,40(sp)
    80001fb8:	f052                	sd	s4,32(sp)
    80001fba:	ec56                	sd	s5,24(sp)
    80001fbc:	e85a                	sd	s6,16(sp)
    80001fbe:	e45e                	sd	s7,8(sp)
    80001fc0:	e062                	sd	s8,0(sp)
    80001fc2:	0880                	addi	s0,sp,80
    80001fc4:	8792                	mv	a5,tp
  int id = r_tp();
    80001fc6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fc8:	00779b13          	slli	s6,a5,0x7
    80001fcc:	00010717          	auipc	a4,0x10
    80001fd0:	98470713          	addi	a4,a4,-1660 # 80011950 <pid_lock>
    80001fd4:	975a                	add	a4,a4,s6
    80001fd6:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001fda:	00010717          	auipc	a4,0x10
    80001fde:	99670713          	addi	a4,a4,-1642 # 80011970 <cpus+0x8>
    80001fe2:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001fe4:	4c0d                	li	s8,3
        c->proc = p;
    80001fe6:	079e                	slli	a5,a5,0x7
    80001fe8:	00010a17          	auipc	s4,0x10
    80001fec:	968a0a13          	addi	s4,s4,-1688 # 80011950 <pid_lock>
    80001ff0:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ff2:	0001a997          	auipc	s3,0x1a
    80001ff6:	57698993          	addi	s3,s3,1398 # 8001c568 <tickslock>
        found = 1;
    80001ffa:	4b85                	li	s7,1
    80001ffc:	a899                	j	80002052 <scheduler+0xa6>
        p->state = RUNNING;
    80001ffe:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80002002:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80002006:	06048593          	addi	a1,s1,96
    8000200a:	855a                	mv	a0,s6
    8000200c:	00000097          	auipc	ra,0x0
    80002010:	638080e7          	jalr	1592(ra) # 80002644 <swtch>
        c->proc = 0;
    80002014:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80002018:	8ade                	mv	s5,s7
      release(&p->lock);
    8000201a:	8526                	mv	a0,s1
    8000201c:	fffff097          	auipc	ra,0xfffff
    80002020:	d2e080e7          	jalr	-722(ra) # 80000d4a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002024:	2a048493          	addi	s1,s1,672
    80002028:	01348b63          	beq	s1,s3,8000203e <scheduler+0x92>
      acquire(&p->lock);
    8000202c:	8526                	mv	a0,s1
    8000202e:	fffff097          	auipc	ra,0xfffff
    80002032:	c68080e7          	jalr	-920(ra) # 80000c96 <acquire>
      if(p->state == RUNNABLE) {
    80002036:	4c9c                	lw	a5,24(s1)
    80002038:	ff2791e3          	bne	a5,s2,8000201a <scheduler+0x6e>
    8000203c:	b7c9                	j	80001ffe <scheduler+0x52>
    if(found == 0) {
    8000203e:	000a9a63          	bnez	s5,80002052 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002042:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002046:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000204a:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    8000204e:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002052:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002056:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000205a:	10079073          	csrw	sstatus,a5
    int found = 0;
    8000205e:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002060:	00010497          	auipc	s1,0x10
    80002064:	d0848493          	addi	s1,s1,-760 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002068:	4909                	li	s2,2
    8000206a:	b7c9                	j	8000202c <scheduler+0x80>

000000008000206c <sched>:
{
    8000206c:	7179                	addi	sp,sp,-48
    8000206e:	f406                	sd	ra,40(sp)
    80002070:	f022                	sd	s0,32(sp)
    80002072:	ec26                	sd	s1,24(sp)
    80002074:	e84a                	sd	s2,16(sp)
    80002076:	e44e                	sd	s3,8(sp)
    80002078:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000207a:	00000097          	auipc	ra,0x0
    8000207e:	9ea080e7          	jalr	-1558(ra) # 80001a64 <myproc>
    80002082:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	b98080e7          	jalr	-1128(ra) # 80000c1c <holding>
    8000208c:	c93d                	beqz	a0,80002102 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000208e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002090:	2781                	sext.w	a5,a5
    80002092:	079e                	slli	a5,a5,0x7
    80002094:	00010717          	auipc	a4,0x10
    80002098:	8bc70713          	addi	a4,a4,-1860 # 80011950 <pid_lock>
    8000209c:	97ba                	add	a5,a5,a4
    8000209e:	0907a703          	lw	a4,144(a5)
    800020a2:	4785                	li	a5,1
    800020a4:	06f71763          	bne	a4,a5,80002112 <sched+0xa6>
  if(p->state == RUNNING)
    800020a8:	4c98                	lw	a4,24(s1)
    800020aa:	478d                	li	a5,3
    800020ac:	06f70b63          	beq	a4,a5,80002122 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020b0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020b4:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020b6:	efb5                	bnez	a5,80002132 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020b8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020ba:	00010917          	auipc	s2,0x10
    800020be:	89690913          	addi	s2,s2,-1898 # 80011950 <pid_lock>
    800020c2:	2781                	sext.w	a5,a5
    800020c4:	079e                	slli	a5,a5,0x7
    800020c6:	97ca                	add	a5,a5,s2
    800020c8:	0947a983          	lw	s3,148(a5)
    800020cc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020ce:	2781                	sext.w	a5,a5
    800020d0:	079e                	slli	a5,a5,0x7
    800020d2:	00010597          	auipc	a1,0x10
    800020d6:	89e58593          	addi	a1,a1,-1890 # 80011970 <cpus+0x8>
    800020da:	95be                	add	a1,a1,a5
    800020dc:	06048513          	addi	a0,s1,96
    800020e0:	00000097          	auipc	ra,0x0
    800020e4:	564080e7          	jalr	1380(ra) # 80002644 <swtch>
    800020e8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020ea:	2781                	sext.w	a5,a5
    800020ec:	079e                	slli	a5,a5,0x7
    800020ee:	97ca                	add	a5,a5,s2
    800020f0:	0937aa23          	sw	s3,148(a5)
}
    800020f4:	70a2                	ld	ra,40(sp)
    800020f6:	7402                	ld	s0,32(sp)
    800020f8:	64e2                	ld	s1,24(sp)
    800020fa:	6942                	ld	s2,16(sp)
    800020fc:	69a2                	ld	s3,8(sp)
    800020fe:	6145                	addi	sp,sp,48
    80002100:	8082                	ret
    panic("sched p->lock");
    80002102:	00006517          	auipc	a0,0x6
    80002106:	11650513          	addi	a0,a0,278 # 80008218 <digits+0x1c0>
    8000210a:	ffffe097          	auipc	ra,0xffffe
    8000210e:	4ee080e7          	jalr	1262(ra) # 800005f8 <panic>
    panic("sched locks");
    80002112:	00006517          	auipc	a0,0x6
    80002116:	11650513          	addi	a0,a0,278 # 80008228 <digits+0x1d0>
    8000211a:	ffffe097          	auipc	ra,0xffffe
    8000211e:	4de080e7          	jalr	1246(ra) # 800005f8 <panic>
    panic("sched running");
    80002122:	00006517          	auipc	a0,0x6
    80002126:	11650513          	addi	a0,a0,278 # 80008238 <digits+0x1e0>
    8000212a:	ffffe097          	auipc	ra,0xffffe
    8000212e:	4ce080e7          	jalr	1230(ra) # 800005f8 <panic>
    panic("sched interruptible");
    80002132:	00006517          	auipc	a0,0x6
    80002136:	11650513          	addi	a0,a0,278 # 80008248 <digits+0x1f0>
    8000213a:	ffffe097          	auipc	ra,0xffffe
    8000213e:	4be080e7          	jalr	1214(ra) # 800005f8 <panic>

0000000080002142 <exit>:
{
    80002142:	7179                	addi	sp,sp,-48
    80002144:	f406                	sd	ra,40(sp)
    80002146:	f022                	sd	s0,32(sp)
    80002148:	ec26                	sd	s1,24(sp)
    8000214a:	e84a                	sd	s2,16(sp)
    8000214c:	e44e                	sd	s3,8(sp)
    8000214e:	e052                	sd	s4,0(sp)
    80002150:	1800                	addi	s0,sp,48
    80002152:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002154:	00000097          	auipc	ra,0x0
    80002158:	910080e7          	jalr	-1776(ra) # 80001a64 <myproc>
    8000215c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000215e:	00007797          	auipc	a5,0x7
    80002162:	eba7b783          	ld	a5,-326(a5) # 80009018 <initproc>
    80002166:	0d050493          	addi	s1,a0,208
    8000216a:	15050913          	addi	s2,a0,336
    8000216e:	02a79363          	bne	a5,a0,80002194 <exit+0x52>
    panic("init exiting");
    80002172:	00006517          	auipc	a0,0x6
    80002176:	0ee50513          	addi	a0,a0,238 # 80008260 <digits+0x208>
    8000217a:	ffffe097          	auipc	ra,0xffffe
    8000217e:	47e080e7          	jalr	1150(ra) # 800005f8 <panic>
      fileclose(f);
    80002182:	00002097          	auipc	ra,0x2
    80002186:	4f8080e7          	jalr	1272(ra) # 8000467a <fileclose>
      p->ofile[fd] = 0;
    8000218a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000218e:	04a1                	addi	s1,s1,8
    80002190:	01248563          	beq	s1,s2,8000219a <exit+0x58>
    if(p->ofile[fd]){
    80002194:	6088                	ld	a0,0(s1)
    80002196:	f575                	bnez	a0,80002182 <exit+0x40>
    80002198:	bfdd                	j	8000218e <exit+0x4c>
  begin_op();
    8000219a:	00002097          	auipc	ra,0x2
    8000219e:	00e080e7          	jalr	14(ra) # 800041a8 <begin_op>
  iput(p->cwd);
    800021a2:	1509b503          	ld	a0,336(s3)
    800021a6:	00002097          	auipc	ra,0x2
    800021aa:	800080e7          	jalr	-2048(ra) # 800039a6 <iput>
  end_op();
    800021ae:	00002097          	auipc	ra,0x2
    800021b2:	07a080e7          	jalr	122(ra) # 80004228 <end_op>
  p->cwd = 0;
    800021b6:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800021ba:	00007497          	auipc	s1,0x7
    800021be:	e5e48493          	addi	s1,s1,-418 # 80009018 <initproc>
    800021c2:	6088                	ld	a0,0(s1)
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	ad2080e7          	jalr	-1326(ra) # 80000c96 <acquire>
  wakeup1(initproc);
    800021cc:	6088                	ld	a0,0(s1)
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	756080e7          	jalr	1878(ra) # 80001924 <wakeup1>
  release(&initproc->lock);
    800021d6:	6088                	ld	a0,0(s1)
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	b72080e7          	jalr	-1166(ra) # 80000d4a <release>
  acquire(&p->lock);
    800021e0:	854e                	mv	a0,s3
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	ab4080e7          	jalr	-1356(ra) # 80000c96 <acquire>
  struct proc *original_parent = p->parent;
    800021ea:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021ee:	854e                	mv	a0,s3
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	b5a080e7          	jalr	-1190(ra) # 80000d4a <release>
  acquire(&original_parent->lock);
    800021f8:	8526                	mv	a0,s1
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	a9c080e7          	jalr	-1380(ra) # 80000c96 <acquire>
  acquire(&p->lock);
    80002202:	854e                	mv	a0,s3
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	a92080e7          	jalr	-1390(ra) # 80000c96 <acquire>
  reparent(p);
    8000220c:	854e                	mv	a0,s3
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	d38080e7          	jalr	-712(ra) # 80001f46 <reparent>
  wakeup1(original_parent);
    80002216:	8526                	mv	a0,s1
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	70c080e7          	jalr	1804(ra) # 80001924 <wakeup1>
  p->xstate = status;
    80002220:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002224:	4791                	li	a5,4
    80002226:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000222a:	8526                	mv	a0,s1
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	b1e080e7          	jalr	-1250(ra) # 80000d4a <release>
  sched();
    80002234:	00000097          	auipc	ra,0x0
    80002238:	e38080e7          	jalr	-456(ra) # 8000206c <sched>
  panic("zombie exit");
    8000223c:	00006517          	auipc	a0,0x6
    80002240:	03450513          	addi	a0,a0,52 # 80008270 <digits+0x218>
    80002244:	ffffe097          	auipc	ra,0xffffe
    80002248:	3b4080e7          	jalr	948(ra) # 800005f8 <panic>

000000008000224c <yield>:
{
    8000224c:	1101                	addi	sp,sp,-32
    8000224e:	ec06                	sd	ra,24(sp)
    80002250:	e822                	sd	s0,16(sp)
    80002252:	e426                	sd	s1,8(sp)
    80002254:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002256:	00000097          	auipc	ra,0x0
    8000225a:	80e080e7          	jalr	-2034(ra) # 80001a64 <myproc>
    8000225e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	a36080e7          	jalr	-1482(ra) # 80000c96 <acquire>
  p->state = RUNNABLE;
    80002268:	4789                	li	a5,2
    8000226a:	cc9c                	sw	a5,24(s1)
  sched();
    8000226c:	00000097          	auipc	ra,0x0
    80002270:	e00080e7          	jalr	-512(ra) # 8000206c <sched>
  release(&p->lock);
    80002274:	8526                	mv	a0,s1
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	ad4080e7          	jalr	-1324(ra) # 80000d4a <release>
}
    8000227e:	60e2                	ld	ra,24(sp)
    80002280:	6442                	ld	s0,16(sp)
    80002282:	64a2                	ld	s1,8(sp)
    80002284:	6105                	addi	sp,sp,32
    80002286:	8082                	ret

0000000080002288 <sleep>:
{
    80002288:	7179                	addi	sp,sp,-48
    8000228a:	f406                	sd	ra,40(sp)
    8000228c:	f022                	sd	s0,32(sp)
    8000228e:	ec26                	sd	s1,24(sp)
    80002290:	e84a                	sd	s2,16(sp)
    80002292:	e44e                	sd	s3,8(sp)
    80002294:	1800                	addi	s0,sp,48
    80002296:	89aa                	mv	s3,a0
    80002298:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	7ca080e7          	jalr	1994(ra) # 80001a64 <myproc>
    800022a2:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800022a4:	05250663          	beq	a0,s2,800022f0 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	9ee080e7          	jalr	-1554(ra) # 80000c96 <acquire>
    release(lk);
    800022b0:	854a                	mv	a0,s2
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	a98080e7          	jalr	-1384(ra) # 80000d4a <release>
  p->chan = chan;
    800022ba:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800022be:	4785                	li	a5,1
    800022c0:	cc9c                	sw	a5,24(s1)
  sched();
    800022c2:	00000097          	auipc	ra,0x0
    800022c6:	daa080e7          	jalr	-598(ra) # 8000206c <sched>
  p->chan = 0;
    800022ca:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800022ce:	8526                	mv	a0,s1
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	a7a080e7          	jalr	-1414(ra) # 80000d4a <release>
    acquire(lk);
    800022d8:	854a                	mv	a0,s2
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	9bc080e7          	jalr	-1604(ra) # 80000c96 <acquire>
}
    800022e2:	70a2                	ld	ra,40(sp)
    800022e4:	7402                	ld	s0,32(sp)
    800022e6:	64e2                	ld	s1,24(sp)
    800022e8:	6942                	ld	s2,16(sp)
    800022ea:	69a2                	ld	s3,8(sp)
    800022ec:	6145                	addi	sp,sp,48
    800022ee:	8082                	ret
  p->chan = chan;
    800022f0:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022f4:	4785                	li	a5,1
    800022f6:	cd1c                	sw	a5,24(a0)
  sched();
    800022f8:	00000097          	auipc	ra,0x0
    800022fc:	d74080e7          	jalr	-652(ra) # 8000206c <sched>
  p->chan = 0;
    80002300:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002304:	bff9                	j	800022e2 <sleep+0x5a>

0000000080002306 <wait>:
{
    80002306:	715d                	addi	sp,sp,-80
    80002308:	e486                	sd	ra,72(sp)
    8000230a:	e0a2                	sd	s0,64(sp)
    8000230c:	fc26                	sd	s1,56(sp)
    8000230e:	f84a                	sd	s2,48(sp)
    80002310:	f44e                	sd	s3,40(sp)
    80002312:	f052                	sd	s4,32(sp)
    80002314:	ec56                	sd	s5,24(sp)
    80002316:	e85a                	sd	s6,16(sp)
    80002318:	e45e                	sd	s7,8(sp)
    8000231a:	e062                	sd	s8,0(sp)
    8000231c:	0880                	addi	s0,sp,80
    8000231e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	744080e7          	jalr	1860(ra) # 80001a64 <myproc>
    80002328:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000232a:	8c2a                	mv	s8,a0
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	96a080e7          	jalr	-1686(ra) # 80000c96 <acquire>
    havekids = 0;
    80002334:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002336:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002338:	0001a997          	auipc	s3,0x1a
    8000233c:	23098993          	addi	s3,s3,560 # 8001c568 <tickslock>
        havekids = 1;
    80002340:	4a85                	li	s5,1
    havekids = 0;
    80002342:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002344:	00010497          	auipc	s1,0x10
    80002348:	a2448493          	addi	s1,s1,-1500 # 80011d68 <proc>
    8000234c:	a08d                	j	800023ae <wait+0xa8>
          pid = np->pid;
    8000234e:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002352:	000b0e63          	beqz	s6,8000236e <wait+0x68>
    80002356:	4691                	li	a3,4
    80002358:	03448613          	addi	a2,s1,52
    8000235c:	85da                	mv	a1,s6
    8000235e:	05093503          	ld	a0,80(s2)
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	3f6080e7          	jalr	1014(ra) # 80001758 <copyout>
    8000236a:	02054263          	bltz	a0,8000238e <wait+0x88>
          freeproc(np);
    8000236e:	8526                	mv	a0,s1
    80002370:	00000097          	auipc	ra,0x0
    80002374:	8a6080e7          	jalr	-1882(ra) # 80001c16 <freeproc>
          release(&np->lock);
    80002378:	8526                	mv	a0,s1
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	9d0080e7          	jalr	-1584(ra) # 80000d4a <release>
          release(&p->lock);
    80002382:	854a                	mv	a0,s2
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	9c6080e7          	jalr	-1594(ra) # 80000d4a <release>
          return pid;
    8000238c:	a8a9                	j	800023e6 <wait+0xe0>
            release(&np->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	9ba080e7          	jalr	-1606(ra) # 80000d4a <release>
            release(&p->lock);
    80002398:	854a                	mv	a0,s2
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	9b0080e7          	jalr	-1616(ra) # 80000d4a <release>
            return -1;
    800023a2:	59fd                	li	s3,-1
    800023a4:	a089                	j	800023e6 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800023a6:	2a048493          	addi	s1,s1,672
    800023aa:	03348463          	beq	s1,s3,800023d2 <wait+0xcc>
      if(np->parent == p){
    800023ae:	709c                	ld	a5,32(s1)
    800023b0:	ff279be3          	bne	a5,s2,800023a6 <wait+0xa0>
        acquire(&np->lock);
    800023b4:	8526                	mv	a0,s1
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	8e0080e7          	jalr	-1824(ra) # 80000c96 <acquire>
        if(np->state == ZOMBIE){
    800023be:	4c9c                	lw	a5,24(s1)
    800023c0:	f94787e3          	beq	a5,s4,8000234e <wait+0x48>
        release(&np->lock);
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	984080e7          	jalr	-1660(ra) # 80000d4a <release>
        havekids = 1;
    800023ce:	8756                	mv	a4,s5
    800023d0:	bfd9                	j	800023a6 <wait+0xa0>
    if(!havekids || p->killed){
    800023d2:	c701                	beqz	a4,800023da <wait+0xd4>
    800023d4:	03092783          	lw	a5,48(s2)
    800023d8:	c785                	beqz	a5,80002400 <wait+0xfa>
      release(&p->lock);
    800023da:	854a                	mv	a0,s2
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	96e080e7          	jalr	-1682(ra) # 80000d4a <release>
      return -1;
    800023e4:	59fd                	li	s3,-1
}
    800023e6:	854e                	mv	a0,s3
    800023e8:	60a6                	ld	ra,72(sp)
    800023ea:	6406                	ld	s0,64(sp)
    800023ec:	74e2                	ld	s1,56(sp)
    800023ee:	7942                	ld	s2,48(sp)
    800023f0:	79a2                	ld	s3,40(sp)
    800023f2:	7a02                	ld	s4,32(sp)
    800023f4:	6ae2                	ld	s5,24(sp)
    800023f6:	6b42                	ld	s6,16(sp)
    800023f8:	6ba2                	ld	s7,8(sp)
    800023fa:	6c02                	ld	s8,0(sp)
    800023fc:	6161                	addi	sp,sp,80
    800023fe:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002400:	85e2                	mv	a1,s8
    80002402:	854a                	mv	a0,s2
    80002404:	00000097          	auipc	ra,0x0
    80002408:	e84080e7          	jalr	-380(ra) # 80002288 <sleep>
    havekids = 0;
    8000240c:	bf1d                	j	80002342 <wait+0x3c>

000000008000240e <wakeup>:
{
    8000240e:	7139                	addi	sp,sp,-64
    80002410:	fc06                	sd	ra,56(sp)
    80002412:	f822                	sd	s0,48(sp)
    80002414:	f426                	sd	s1,40(sp)
    80002416:	f04a                	sd	s2,32(sp)
    80002418:	ec4e                	sd	s3,24(sp)
    8000241a:	e852                	sd	s4,16(sp)
    8000241c:	e456                	sd	s5,8(sp)
    8000241e:	0080                	addi	s0,sp,64
    80002420:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002422:	00010497          	auipc	s1,0x10
    80002426:	94648493          	addi	s1,s1,-1722 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    8000242a:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000242c:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000242e:	0001a917          	auipc	s2,0x1a
    80002432:	13a90913          	addi	s2,s2,314 # 8001c568 <tickslock>
    80002436:	a821                	j	8000244e <wakeup+0x40>
      p->state = RUNNABLE;
    80002438:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    8000243c:	8526                	mv	a0,s1
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	90c080e7          	jalr	-1780(ra) # 80000d4a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002446:	2a048493          	addi	s1,s1,672
    8000244a:	01248e63          	beq	s1,s2,80002466 <wakeup+0x58>
    acquire(&p->lock);
    8000244e:	8526                	mv	a0,s1
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	846080e7          	jalr	-1978(ra) # 80000c96 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002458:	4c9c                	lw	a5,24(s1)
    8000245a:	ff3791e3          	bne	a5,s3,8000243c <wakeup+0x2e>
    8000245e:	749c                	ld	a5,40(s1)
    80002460:	fd479ee3          	bne	a5,s4,8000243c <wakeup+0x2e>
    80002464:	bfd1                	j	80002438 <wakeup+0x2a>
}
    80002466:	70e2                	ld	ra,56(sp)
    80002468:	7442                	ld	s0,48(sp)
    8000246a:	74a2                	ld	s1,40(sp)
    8000246c:	7902                	ld	s2,32(sp)
    8000246e:	69e2                	ld	s3,24(sp)
    80002470:	6a42                	ld	s4,16(sp)
    80002472:	6aa2                	ld	s5,8(sp)
    80002474:	6121                	addi	sp,sp,64
    80002476:	8082                	ret

0000000080002478 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002478:	7179                	addi	sp,sp,-48
    8000247a:	f406                	sd	ra,40(sp)
    8000247c:	f022                	sd	s0,32(sp)
    8000247e:	ec26                	sd	s1,24(sp)
    80002480:	e84a                	sd	s2,16(sp)
    80002482:	e44e                	sd	s3,8(sp)
    80002484:	1800                	addi	s0,sp,48
    80002486:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002488:	00010497          	auipc	s1,0x10
    8000248c:	8e048493          	addi	s1,s1,-1824 # 80011d68 <proc>
    80002490:	0001a997          	auipc	s3,0x1a
    80002494:	0d898993          	addi	s3,s3,216 # 8001c568 <tickslock>
    acquire(&p->lock);
    80002498:	8526                	mv	a0,s1
    8000249a:	ffffe097          	auipc	ra,0xffffe
    8000249e:	7fc080e7          	jalr	2044(ra) # 80000c96 <acquire>
    if(p->pid == pid){
    800024a2:	5c9c                	lw	a5,56(s1)
    800024a4:	01278d63          	beq	a5,s2,800024be <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024a8:	8526                	mv	a0,s1
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	8a0080e7          	jalr	-1888(ra) # 80000d4a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024b2:	2a048493          	addi	s1,s1,672
    800024b6:	ff3491e3          	bne	s1,s3,80002498 <kill+0x20>
  }
  return -1;
    800024ba:	557d                	li	a0,-1
    800024bc:	a829                	j	800024d6 <kill+0x5e>
      p->killed = 1;
    800024be:	4785                	li	a5,1
    800024c0:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800024c2:	4c98                	lw	a4,24(s1)
    800024c4:	4785                	li	a5,1
    800024c6:	00f70f63          	beq	a4,a5,800024e4 <kill+0x6c>
      release(&p->lock);
    800024ca:	8526                	mv	a0,s1
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	87e080e7          	jalr	-1922(ra) # 80000d4a <release>
      return 0;
    800024d4:	4501                	li	a0,0
}
    800024d6:	70a2                	ld	ra,40(sp)
    800024d8:	7402                	ld	s0,32(sp)
    800024da:	64e2                	ld	s1,24(sp)
    800024dc:	6942                	ld	s2,16(sp)
    800024de:	69a2                	ld	s3,8(sp)
    800024e0:	6145                	addi	sp,sp,48
    800024e2:	8082                	ret
        p->state = RUNNABLE;
    800024e4:	4789                	li	a5,2
    800024e6:	cc9c                	sw	a5,24(s1)
    800024e8:	b7cd                	j	800024ca <kill+0x52>

00000000800024ea <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024ea:	7179                	addi	sp,sp,-48
    800024ec:	f406                	sd	ra,40(sp)
    800024ee:	f022                	sd	s0,32(sp)
    800024f0:	ec26                	sd	s1,24(sp)
    800024f2:	e84a                	sd	s2,16(sp)
    800024f4:	e44e                	sd	s3,8(sp)
    800024f6:	e052                	sd	s4,0(sp)
    800024f8:	1800                	addi	s0,sp,48
    800024fa:	84aa                	mv	s1,a0
    800024fc:	892e                	mv	s2,a1
    800024fe:	89b2                	mv	s3,a2
    80002500:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002502:	fffff097          	auipc	ra,0xfffff
    80002506:	562080e7          	jalr	1378(ra) # 80001a64 <myproc>
  if(user_dst){
    8000250a:	c08d                	beqz	s1,8000252c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000250c:	86d2                	mv	a3,s4
    8000250e:	864e                	mv	a2,s3
    80002510:	85ca                	mv	a1,s2
    80002512:	6928                	ld	a0,80(a0)
    80002514:	fffff097          	auipc	ra,0xfffff
    80002518:	244080e7          	jalr	580(ra) # 80001758 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000251c:	70a2                	ld	ra,40(sp)
    8000251e:	7402                	ld	s0,32(sp)
    80002520:	64e2                	ld	s1,24(sp)
    80002522:	6942                	ld	s2,16(sp)
    80002524:	69a2                	ld	s3,8(sp)
    80002526:	6a02                	ld	s4,0(sp)
    80002528:	6145                	addi	sp,sp,48
    8000252a:	8082                	ret
    memmove((char *)dst, src, len);
    8000252c:	000a061b          	sext.w	a2,s4
    80002530:	85ce                	mv	a1,s3
    80002532:	854a                	mv	a0,s2
    80002534:	fffff097          	auipc	ra,0xfffff
    80002538:	8be080e7          	jalr	-1858(ra) # 80000df2 <memmove>
    return 0;
    8000253c:	8526                	mv	a0,s1
    8000253e:	bff9                	j	8000251c <either_copyout+0x32>

0000000080002540 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002540:	7179                	addi	sp,sp,-48
    80002542:	f406                	sd	ra,40(sp)
    80002544:	f022                	sd	s0,32(sp)
    80002546:	ec26                	sd	s1,24(sp)
    80002548:	e84a                	sd	s2,16(sp)
    8000254a:	e44e                	sd	s3,8(sp)
    8000254c:	e052                	sd	s4,0(sp)
    8000254e:	1800                	addi	s0,sp,48
    80002550:	892a                	mv	s2,a0
    80002552:	84ae                	mv	s1,a1
    80002554:	89b2                	mv	s3,a2
    80002556:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002558:	fffff097          	auipc	ra,0xfffff
    8000255c:	50c080e7          	jalr	1292(ra) # 80001a64 <myproc>
  if(user_src){
    80002560:	c08d                	beqz	s1,80002582 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002562:	86d2                	mv	a3,s4
    80002564:	864e                	mv	a2,s3
    80002566:	85ca                	mv	a1,s2
    80002568:	6928                	ld	a0,80(a0)
    8000256a:	fffff097          	auipc	ra,0xfffff
    8000256e:	27a080e7          	jalr	634(ra) # 800017e4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002572:	70a2                	ld	ra,40(sp)
    80002574:	7402                	ld	s0,32(sp)
    80002576:	64e2                	ld	s1,24(sp)
    80002578:	6942                	ld	s2,16(sp)
    8000257a:	69a2                	ld	s3,8(sp)
    8000257c:	6a02                	ld	s4,0(sp)
    8000257e:	6145                	addi	sp,sp,48
    80002580:	8082                	ret
    memmove(dst, (char*)src, len);
    80002582:	000a061b          	sext.w	a2,s4
    80002586:	85ce                	mv	a1,s3
    80002588:	854a                	mv	a0,s2
    8000258a:	fffff097          	auipc	ra,0xfffff
    8000258e:	868080e7          	jalr	-1944(ra) # 80000df2 <memmove>
    return 0;
    80002592:	8526                	mv	a0,s1
    80002594:	bff9                	j	80002572 <either_copyin+0x32>

0000000080002596 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002596:	715d                	addi	sp,sp,-80
    80002598:	e486                	sd	ra,72(sp)
    8000259a:	e0a2                	sd	s0,64(sp)
    8000259c:	fc26                	sd	s1,56(sp)
    8000259e:	f84a                	sd	s2,48(sp)
    800025a0:	f44e                	sd	s3,40(sp)
    800025a2:	f052                	sd	s4,32(sp)
    800025a4:	ec56                	sd	s5,24(sp)
    800025a6:	e85a                	sd	s6,16(sp)
    800025a8:	e45e                	sd	s7,8(sp)
    800025aa:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025ac:	00006517          	auipc	a0,0x6
    800025b0:	b3450513          	addi	a0,a0,-1228 # 800080e0 <digits+0x88>
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	096080e7          	jalr	150(ra) # 8000064a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025bc:	00010497          	auipc	s1,0x10
    800025c0:	90448493          	addi	s1,s1,-1788 # 80011ec0 <proc+0x158>
    800025c4:	0001a917          	auipc	s2,0x1a
    800025c8:	0fc90913          	addi	s2,s2,252 # 8001c6c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025cc:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800025ce:	00006997          	auipc	s3,0x6
    800025d2:	cb298993          	addi	s3,s3,-846 # 80008280 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800025d6:	00006a97          	auipc	s5,0x6
    800025da:	cb2a8a93          	addi	s5,s5,-846 # 80008288 <digits+0x230>
    printf("\n");
    800025de:	00006a17          	auipc	s4,0x6
    800025e2:	b02a0a13          	addi	s4,s4,-1278 # 800080e0 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e6:	00006b97          	auipc	s7,0x6
    800025ea:	cdab8b93          	addi	s7,s7,-806 # 800082c0 <states.1712>
    800025ee:	a00d                	j	80002610 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025f0:	ee06a583          	lw	a1,-288(a3)
    800025f4:	8556                	mv	a0,s5
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	054080e7          	jalr	84(ra) # 8000064a <printf>
    printf("\n");
    800025fe:	8552                	mv	a0,s4
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	04a080e7          	jalr	74(ra) # 8000064a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002608:	2a048493          	addi	s1,s1,672
    8000260c:	03248163          	beq	s1,s2,8000262e <procdump+0x98>
    if(p->state == UNUSED)
    80002610:	86a6                	mv	a3,s1
    80002612:	ec04a783          	lw	a5,-320(s1)
    80002616:	dbed                	beqz	a5,80002608 <procdump+0x72>
      state = "???";
    80002618:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000261a:	fcfb6be3          	bltu	s6,a5,800025f0 <procdump+0x5a>
    8000261e:	1782                	slli	a5,a5,0x20
    80002620:	9381                	srli	a5,a5,0x20
    80002622:	078e                	slli	a5,a5,0x3
    80002624:	97de                	add	a5,a5,s7
    80002626:	6390                	ld	a2,0(a5)
    80002628:	f661                	bnez	a2,800025f0 <procdump+0x5a>
      state = "???";
    8000262a:	864e                	mv	a2,s3
    8000262c:	b7d1                	j	800025f0 <procdump+0x5a>
  }
}
    8000262e:	60a6                	ld	ra,72(sp)
    80002630:	6406                	ld	s0,64(sp)
    80002632:	74e2                	ld	s1,56(sp)
    80002634:	7942                	ld	s2,48(sp)
    80002636:	79a2                	ld	s3,40(sp)
    80002638:	7a02                	ld	s4,32(sp)
    8000263a:	6ae2                	ld	s5,24(sp)
    8000263c:	6b42                	ld	s6,16(sp)
    8000263e:	6ba2                	ld	s7,8(sp)
    80002640:	6161                	addi	sp,sp,80
    80002642:	8082                	ret

0000000080002644 <swtch>:
    80002644:	00153023          	sd	ra,0(a0)
    80002648:	00253423          	sd	sp,8(a0)
    8000264c:	e900                	sd	s0,16(a0)
    8000264e:	ed04                	sd	s1,24(a0)
    80002650:	03253023          	sd	s2,32(a0)
    80002654:	03353423          	sd	s3,40(a0)
    80002658:	03453823          	sd	s4,48(a0)
    8000265c:	03553c23          	sd	s5,56(a0)
    80002660:	05653023          	sd	s6,64(a0)
    80002664:	05753423          	sd	s7,72(a0)
    80002668:	05853823          	sd	s8,80(a0)
    8000266c:	05953c23          	sd	s9,88(a0)
    80002670:	07a53023          	sd	s10,96(a0)
    80002674:	07b53423          	sd	s11,104(a0)
    80002678:	0005b083          	ld	ra,0(a1)
    8000267c:	0085b103          	ld	sp,8(a1)
    80002680:	6980                	ld	s0,16(a1)
    80002682:	6d84                	ld	s1,24(a1)
    80002684:	0205b903          	ld	s2,32(a1)
    80002688:	0285b983          	ld	s3,40(a1)
    8000268c:	0305ba03          	ld	s4,48(a1)
    80002690:	0385ba83          	ld	s5,56(a1)
    80002694:	0405bb03          	ld	s6,64(a1)
    80002698:	0485bb83          	ld	s7,72(a1)
    8000269c:	0505bc03          	ld	s8,80(a1)
    800026a0:	0585bc83          	ld	s9,88(a1)
    800026a4:	0605bd03          	ld	s10,96(a1)
    800026a8:	0685bd83          	ld	s11,104(a1)
    800026ac:	8082                	ret

00000000800026ae <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800026ae:	1141                	addi	sp,sp,-16
    800026b0:	e406                	sd	ra,8(sp)
    800026b2:	e022                	sd	s0,0(sp)
    800026b4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026b6:	00006597          	auipc	a1,0x6
    800026ba:	c3258593          	addi	a1,a1,-974 # 800082e8 <states.1712+0x28>
    800026be:	0001a517          	auipc	a0,0x1a
    800026c2:	eaa50513          	addi	a0,a0,-342 # 8001c568 <tickslock>
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	540080e7          	jalr	1344(ra) # 80000c06 <initlock>
}
    800026ce:	60a2                	ld	ra,8(sp)
    800026d0:	6402                	ld	s0,0(sp)
    800026d2:	0141                	addi	sp,sp,16
    800026d4:	8082                	ret

00000000800026d6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    800026d6:	1141                	addi	sp,sp,-16
    800026d8:	e422                	sd	s0,8(sp)
    800026da:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026dc:	00003797          	auipc	a5,0x3
    800026e0:	60478793          	addi	a5,a5,1540 # 80005ce0 <kernelvec>
    800026e4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026e8:	6422                	ld	s0,8(sp)
    800026ea:	0141                	addi	sp,sp,16
    800026ec:	8082                	ret

00000000800026ee <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    800026ee:	1141                	addi	sp,sp,-16
    800026f0:	e406                	sd	ra,8(sp)
    800026f2:	e022                	sd	s0,0(sp)
    800026f4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026f6:	fffff097          	auipc	ra,0xfffff
    800026fa:	36e080e7          	jalr	878(ra) # 80001a64 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026fe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002702:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002704:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002708:	00005617          	auipc	a2,0x5
    8000270c:	8f860613          	addi	a2,a2,-1800 # 80007000 <_trampoline>
    80002710:	00005697          	auipc	a3,0x5
    80002714:	8f068693          	addi	a3,a3,-1808 # 80007000 <_trampoline>
    80002718:	8e91                	sub	a3,a3,a2
    8000271a:	040007b7          	lui	a5,0x4000
    8000271e:	17fd                	addi	a5,a5,-1
    80002720:	07b2                	slli	a5,a5,0xc
    80002722:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002724:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002728:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000272a:	180026f3          	csrr	a3,satp
    8000272e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002730:	6d38                	ld	a4,88(a0)
    80002732:	6134                	ld	a3,64(a0)
    80002734:	6585                	lui	a1,0x1
    80002736:	96ae                	add	a3,a3,a1
    80002738:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000273a:	6d38                	ld	a4,88(a0)
    8000273c:	00000697          	auipc	a3,0x0
    80002740:	13868693          	addi	a3,a3,312 # 80002874 <usertrap>
    80002744:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002746:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002748:	8692                	mv	a3,tp
    8000274a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000274c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002750:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002754:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002758:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000275c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000275e:	6f18                	ld	a4,24(a4)
    80002760:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002764:	692c                	ld	a1,80(a0)
    80002766:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002768:	00005717          	auipc	a4,0x5
    8000276c:	92870713          	addi	a4,a4,-1752 # 80007090 <userret>
    80002770:	8f11                	sub	a4,a4,a2
    80002772:	97ba                	add	a5,a5,a4
  ((void (*)(uint64, uint64))fn)(TRAPFRAME, satp);
    80002774:	577d                	li	a4,-1
    80002776:	177e                	slli	a4,a4,0x3f
    80002778:	8dd9                	or	a1,a1,a4
    8000277a:	02000537          	lui	a0,0x2000
    8000277e:	157d                	addi	a0,a0,-1
    80002780:	0536                	slli	a0,a0,0xd
    80002782:	9782                	jalr	a5
}
    80002784:	60a2                	ld	ra,8(sp)
    80002786:	6402                	ld	s0,0(sp)
    80002788:	0141                	addi	sp,sp,16
    8000278a:	8082                	ret

000000008000278c <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    8000278c:	1101                	addi	sp,sp,-32
    8000278e:	ec06                	sd	ra,24(sp)
    80002790:	e822                	sd	s0,16(sp)
    80002792:	e426                	sd	s1,8(sp)
    80002794:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002796:	0001a497          	auipc	s1,0x1a
    8000279a:	dd248493          	addi	s1,s1,-558 # 8001c568 <tickslock>
    8000279e:	8526                	mv	a0,s1
    800027a0:	ffffe097          	auipc	ra,0xffffe
    800027a4:	4f6080e7          	jalr	1270(ra) # 80000c96 <acquire>
  ticks++;
    800027a8:	00007517          	auipc	a0,0x7
    800027ac:	87850513          	addi	a0,a0,-1928 # 80009020 <ticks>
    800027b0:	411c                	lw	a5,0(a0)
    800027b2:	2785                	addiw	a5,a5,1
    800027b4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027b6:	00000097          	auipc	ra,0x0
    800027ba:	c58080e7          	jalr	-936(ra) # 8000240e <wakeup>
  release(&tickslock);
    800027be:	8526                	mv	a0,s1
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	58a080e7          	jalr	1418(ra) # 80000d4a <release>
}
    800027c8:	60e2                	ld	ra,24(sp)
    800027ca:	6442                	ld	s0,16(sp)
    800027cc:	64a2                	ld	s1,8(sp)
    800027ce:	6105                	addi	sp,sp,32
    800027d0:	8082                	ret

00000000800027d2 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    800027d2:	1101                	addi	sp,sp,-32
    800027d4:	ec06                	sd	ra,24(sp)
    800027d6:	e822                	sd	s0,16(sp)
    800027d8:	e426                	sd	s1,8(sp)
    800027da:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027dc:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    800027e0:	00074d63          	bltz	a4,800027fa <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    800027e4:	57fd                	li	a5,-1
    800027e6:	17fe                	slli	a5,a5,0x3f
    800027e8:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    800027ea:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    800027ec:	06f70363          	beq	a4,a5,80002852 <devintr+0x80>
  }
}
    800027f0:	60e2                	ld	ra,24(sp)
    800027f2:	6442                	ld	s0,16(sp)
    800027f4:	64a2                	ld	s1,8(sp)
    800027f6:	6105                	addi	sp,sp,32
    800027f8:	8082                	ret
      (scause & 0xff) == 9)
    800027fa:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    800027fe:	46a5                	li	a3,9
    80002800:	fed792e3          	bne	a5,a3,800027e4 <devintr+0x12>
    int irq = plic_claim();
    80002804:	00003097          	auipc	ra,0x3
    80002808:	5e4080e7          	jalr	1508(ra) # 80005de8 <plic_claim>
    8000280c:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    8000280e:	47a9                	li	a5,10
    80002810:	02f50763          	beq	a0,a5,8000283e <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002814:	4785                	li	a5,1
    80002816:	02f50963          	beq	a0,a5,80002848 <devintr+0x76>
    return 1;
    8000281a:	4505                	li	a0,1
    else if (irq)
    8000281c:	d8f1                	beqz	s1,800027f0 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000281e:	85a6                	mv	a1,s1
    80002820:	00006517          	auipc	a0,0x6
    80002824:	ad050513          	addi	a0,a0,-1328 # 800082f0 <states.1712+0x30>
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	e22080e7          	jalr	-478(ra) # 8000064a <printf>
      plic_complete(irq);
    80002830:	8526                	mv	a0,s1
    80002832:	00003097          	auipc	ra,0x3
    80002836:	5da080e7          	jalr	1498(ra) # 80005e0c <plic_complete>
    return 1;
    8000283a:	4505                	li	a0,1
    8000283c:	bf55                	j	800027f0 <devintr+0x1e>
      uartintr();
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	21c080e7          	jalr	540(ra) # 80000a5a <uartintr>
    80002846:	b7ed                	j	80002830 <devintr+0x5e>
      virtio_disk_intr();
    80002848:	00004097          	auipc	ra,0x4
    8000284c:	a5e080e7          	jalr	-1442(ra) # 800062a6 <virtio_disk_intr>
    80002850:	b7c5                	j	80002830 <devintr+0x5e>
    if (cpuid() == 0)
    80002852:	fffff097          	auipc	ra,0xfffff
    80002856:	1e6080e7          	jalr	486(ra) # 80001a38 <cpuid>
    8000285a:	c901                	beqz	a0,8000286a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000285c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002860:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002862:	14479073          	csrw	sip,a5
    return 2;
    80002866:	4509                	li	a0,2
    80002868:	b761                	j	800027f0 <devintr+0x1e>
      clockintr();
    8000286a:	00000097          	auipc	ra,0x0
    8000286e:	f22080e7          	jalr	-222(ra) # 8000278c <clockintr>
    80002872:	b7ed                	j	8000285c <devintr+0x8a>

0000000080002874 <usertrap>:
{
    80002874:	1101                	addi	sp,sp,-32
    80002876:	ec06                	sd	ra,24(sp)
    80002878:	e822                	sd	s0,16(sp)
    8000287a:	e426                	sd	s1,8(sp)
    8000287c:	e04a                	sd	s2,0(sp)
    8000287e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002880:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002884:	1007f793          	andi	a5,a5,256
    80002888:	e3ad                	bnez	a5,800028ea <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000288a:	00003797          	auipc	a5,0x3
    8000288e:	45678793          	addi	a5,a5,1110 # 80005ce0 <kernelvec>
    80002892:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002896:	fffff097          	auipc	ra,0xfffff
    8000289a:	1ce080e7          	jalr	462(ra) # 80001a64 <myproc>
    8000289e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028a0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028a2:	14102773          	csrr	a4,sepc
    800028a6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028a8:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    800028ac:	47a1                	li	a5,8
    800028ae:	04f71c63          	bne	a4,a5,80002906 <usertrap+0x92>
    if (p->killed)
    800028b2:	591c                	lw	a5,48(a0)
    800028b4:	e3b9                	bnez	a5,800028fa <usertrap+0x86>
    p->trapframe->epc += 4;
    800028b6:	6cb8                	ld	a4,88(s1)
    800028b8:	6f1c                	ld	a5,24(a4)
    800028ba:	0791                	addi	a5,a5,4
    800028bc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028be:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028c2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028c6:	10079073          	csrw	sstatus,a5
    syscall();
    800028ca:	00000097          	auipc	ra,0x0
    800028ce:	348080e7          	jalr	840(ra) # 80002c12 <syscall>
  if (p->killed)
    800028d2:	589c                	lw	a5,48(s1)
    800028d4:	e7dd                	bnez	a5,80002982 <usertrap+0x10e>
  usertrapret();
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	e18080e7          	jalr	-488(ra) # 800026ee <usertrapret>
}
    800028de:	60e2                	ld	ra,24(sp)
    800028e0:	6442                	ld	s0,16(sp)
    800028e2:	64a2                	ld	s1,8(sp)
    800028e4:	6902                	ld	s2,0(sp)
    800028e6:	6105                	addi	sp,sp,32
    800028e8:	8082                	ret
    panic("usertrap: not from user mode");
    800028ea:	00006517          	auipc	a0,0x6
    800028ee:	a2650513          	addi	a0,a0,-1498 # 80008310 <states.1712+0x50>
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	d06080e7          	jalr	-762(ra) # 800005f8 <panic>
      exit(-1);
    800028fa:	557d                	li	a0,-1
    800028fc:	00000097          	auipc	ra,0x0
    80002900:	846080e7          	jalr	-1978(ra) # 80002142 <exit>
    80002904:	bf4d                	j	800028b6 <usertrap+0x42>
  else if ((which_dev = devintr()) != 0)
    80002906:	00000097          	auipc	ra,0x0
    8000290a:	ecc080e7          	jalr	-308(ra) # 800027d2 <devintr>
    8000290e:	892a                	mv	s2,a0
    80002910:	c501                	beqz	a0,80002918 <usertrap+0xa4>
  if (p->killed)
    80002912:	589c                	lw	a5,48(s1)
    80002914:	c3a1                	beqz	a5,80002954 <usertrap+0xe0>
    80002916:	a815                	j	8000294a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002918:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000291c:	5c90                	lw	a2,56(s1)
    8000291e:	00006517          	auipc	a0,0x6
    80002922:	a1250513          	addi	a0,a0,-1518 # 80008330 <states.1712+0x70>
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	d24080e7          	jalr	-732(ra) # 8000064a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000292e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002932:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002936:	00006517          	auipc	a0,0x6
    8000293a:	a2a50513          	addi	a0,a0,-1494 # 80008360 <states.1712+0xa0>
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	d0c080e7          	jalr	-756(ra) # 8000064a <printf>
    p->killed = 1;
    80002946:	4785                	li	a5,1
    80002948:	d89c                	sw	a5,48(s1)
    exit(-1);
    8000294a:	557d                	li	a0,-1
    8000294c:	fffff097          	auipc	ra,0xfffff
    80002950:	7f6080e7          	jalr	2038(ra) # 80002142 <exit>
  if (which_dev == 2)
    80002954:	4789                	li	a5,2
    80002956:	f8f910e3          	bne	s2,a5,800028d6 <usertrap+0x62>
    if (p->interval != 0)
    8000295a:	1684a783          	lw	a5,360(s1)
    8000295e:	cf89                	beqz	a5,80002978 <usertrap+0x104>
      if (!p->running_hand)
    80002960:	1784a703          	lw	a4,376(s1)
    80002964:	eb11                	bnez	a4,80002978 <usertrap+0x104>
        p->since_interval = p->since_interval + 1;
    80002966:	16c4a703          	lw	a4,364(s1)
    8000296a:	2705                	addiw	a4,a4,1
    8000296c:	0007069b          	sext.w	a3,a4
    80002970:	16e4a623          	sw	a4,364(s1)
      if (!p->running_hand && p->since_interval == p->interval)
    80002974:	00d78963          	beq	a5,a3,80002986 <usertrap+0x112>
    yield();
    80002978:	00000097          	auipc	ra,0x0
    8000297c:	8d4080e7          	jalr	-1836(ra) # 8000224c <yield>
    80002980:	bf99                	j	800028d6 <usertrap+0x62>
  int which_dev = 0;
    80002982:	4901                	li	s2,0
    80002984:	b7d9                	j	8000294a <usertrap+0xd6>
        printf("alarm!\n");
    80002986:	00006517          	auipc	a0,0x6
    8000298a:	9fa50513          	addi	a0,a0,-1542 # 80008380 <states.1712+0xc0>
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	cbc080e7          	jalr	-836(ra) # 8000064a <printf>
        p->running_hand = 1;
    80002996:	4785                	li	a5,1
    80002998:	16f4ac23          	sw	a5,376(s1)
        p->trapframe_cp = *(p->trapframe);
    8000299c:	0584b803          	ld	a6,88(s1)
    800029a0:	87c2                	mv	a5,a6
    800029a2:	18048713          	addi	a4,s1,384
    800029a6:	12080893          	addi	a7,a6,288
    800029aa:	6388                	ld	a0,0(a5)
    800029ac:	678c                	ld	a1,8(a5)
    800029ae:	6b90                	ld	a2,16(a5)
    800029b0:	6f94                	ld	a3,24(a5)
    800029b2:	e308                	sd	a0,0(a4)
    800029b4:	e70c                	sd	a1,8(a4)
    800029b6:	eb10                	sd	a2,16(a4)
    800029b8:	ef14                	sd	a3,24(a4)
    800029ba:	02078793          	addi	a5,a5,32
    800029be:	02070713          	addi	a4,a4,32
    800029c2:	ff1794e3          	bne	a5,a7,800029aa <usertrap+0x136>
        p->trapframe->epc = (uint64)p->handler;
    800029c6:	1704b783          	ld	a5,368(s1)
    800029ca:	00f83c23          	sd	a5,24(a6)
    800029ce:	b76d                	j	80002978 <usertrap+0x104>

00000000800029d0 <kerneltrap>:
{
    800029d0:	7179                	addi	sp,sp,-48
    800029d2:	f406                	sd	ra,40(sp)
    800029d4:	f022                	sd	s0,32(sp)
    800029d6:	ec26                	sd	s1,24(sp)
    800029d8:	e84a                	sd	s2,16(sp)
    800029da:	e44e                	sd	s3,8(sp)
    800029dc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029de:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029e6:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    800029ea:	1004f793          	andi	a5,s1,256
    800029ee:	cb85                	beqz	a5,80002a1e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029f4:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    800029f6:	ef85                	bnez	a5,80002a2e <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    800029f8:	00000097          	auipc	ra,0x0
    800029fc:	dda080e7          	jalr	-550(ra) # 800027d2 <devintr>
    80002a00:	cd1d                	beqz	a0,80002a3e <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a02:	4789                	li	a5,2
    80002a04:	06f50a63          	beq	a0,a5,80002a78 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a08:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a0c:	10049073          	csrw	sstatus,s1
}
    80002a10:	70a2                	ld	ra,40(sp)
    80002a12:	7402                	ld	s0,32(sp)
    80002a14:	64e2                	ld	s1,24(sp)
    80002a16:	6942                	ld	s2,16(sp)
    80002a18:	69a2                	ld	s3,8(sp)
    80002a1a:	6145                	addi	sp,sp,48
    80002a1c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a1e:	00006517          	auipc	a0,0x6
    80002a22:	96a50513          	addi	a0,a0,-1686 # 80008388 <states.1712+0xc8>
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	bd2080e7          	jalr	-1070(ra) # 800005f8 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a2e:	00006517          	auipc	a0,0x6
    80002a32:	98250513          	addi	a0,a0,-1662 # 800083b0 <states.1712+0xf0>
    80002a36:	ffffe097          	auipc	ra,0xffffe
    80002a3a:	bc2080e7          	jalr	-1086(ra) # 800005f8 <panic>
    printf("scause %p\n", scause);
    80002a3e:	85ce                	mv	a1,s3
    80002a40:	00006517          	auipc	a0,0x6
    80002a44:	99050513          	addi	a0,a0,-1648 # 800083d0 <states.1712+0x110>
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	c02080e7          	jalr	-1022(ra) # 8000064a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a50:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a54:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a58:	00006517          	auipc	a0,0x6
    80002a5c:	98850513          	addi	a0,a0,-1656 # 800083e0 <states.1712+0x120>
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	bea080e7          	jalr	-1046(ra) # 8000064a <printf>
    panic("kerneltrap");
    80002a68:	00006517          	auipc	a0,0x6
    80002a6c:	99050513          	addi	a0,a0,-1648 # 800083f8 <states.1712+0x138>
    80002a70:	ffffe097          	auipc	ra,0xffffe
    80002a74:	b88080e7          	jalr	-1144(ra) # 800005f8 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	fec080e7          	jalr	-20(ra) # 80001a64 <myproc>
    80002a80:	d541                	beqz	a0,80002a08 <kerneltrap+0x38>
    80002a82:	fffff097          	auipc	ra,0xfffff
    80002a86:	fe2080e7          	jalr	-30(ra) # 80001a64 <myproc>
    80002a8a:	4d18                	lw	a4,24(a0)
    80002a8c:	478d                	li	a5,3
    80002a8e:	f6f71de3          	bne	a4,a5,80002a08 <kerneltrap+0x38>
    yield();
    80002a92:	fffff097          	auipc	ra,0xfffff
    80002a96:	7ba080e7          	jalr	1978(ra) # 8000224c <yield>
    80002a9a:	b7bd                	j	80002a08 <kerneltrap+0x38>

0000000080002a9c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a9c:	1101                	addi	sp,sp,-32
    80002a9e:	ec06                	sd	ra,24(sp)
    80002aa0:	e822                	sd	s0,16(sp)
    80002aa2:	e426                	sd	s1,8(sp)
    80002aa4:	1000                	addi	s0,sp,32
    80002aa6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002aa8:	fffff097          	auipc	ra,0xfffff
    80002aac:	fbc080e7          	jalr	-68(ra) # 80001a64 <myproc>
  switch (n) {
    80002ab0:	4795                	li	a5,5
    80002ab2:	0497e163          	bltu	a5,s1,80002af4 <argraw+0x58>
    80002ab6:	048a                	slli	s1,s1,0x2
    80002ab8:	00006717          	auipc	a4,0x6
    80002abc:	97870713          	addi	a4,a4,-1672 # 80008430 <states.1712+0x170>
    80002ac0:	94ba                	add	s1,s1,a4
    80002ac2:	409c                	lw	a5,0(s1)
    80002ac4:	97ba                	add	a5,a5,a4
    80002ac6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ac8:	6d3c                	ld	a5,88(a0)
    80002aca:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002acc:	60e2                	ld	ra,24(sp)
    80002ace:	6442                	ld	s0,16(sp)
    80002ad0:	64a2                	ld	s1,8(sp)
    80002ad2:	6105                	addi	sp,sp,32
    80002ad4:	8082                	ret
    return p->trapframe->a1;
    80002ad6:	6d3c                	ld	a5,88(a0)
    80002ad8:	7fa8                	ld	a0,120(a5)
    80002ada:	bfcd                	j	80002acc <argraw+0x30>
    return p->trapframe->a2;
    80002adc:	6d3c                	ld	a5,88(a0)
    80002ade:	63c8                	ld	a0,128(a5)
    80002ae0:	b7f5                	j	80002acc <argraw+0x30>
    return p->trapframe->a3;
    80002ae2:	6d3c                	ld	a5,88(a0)
    80002ae4:	67c8                	ld	a0,136(a5)
    80002ae6:	b7dd                	j	80002acc <argraw+0x30>
    return p->trapframe->a4;
    80002ae8:	6d3c                	ld	a5,88(a0)
    80002aea:	6bc8                	ld	a0,144(a5)
    80002aec:	b7c5                	j	80002acc <argraw+0x30>
    return p->trapframe->a5;
    80002aee:	6d3c                	ld	a5,88(a0)
    80002af0:	6fc8                	ld	a0,152(a5)
    80002af2:	bfe9                	j	80002acc <argraw+0x30>
  panic("argraw");
    80002af4:	00006517          	auipc	a0,0x6
    80002af8:	91450513          	addi	a0,a0,-1772 # 80008408 <states.1712+0x148>
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	afc080e7          	jalr	-1284(ra) # 800005f8 <panic>

0000000080002b04 <fetchaddr>:
{
    80002b04:	1101                	addi	sp,sp,-32
    80002b06:	ec06                	sd	ra,24(sp)
    80002b08:	e822                	sd	s0,16(sp)
    80002b0a:	e426                	sd	s1,8(sp)
    80002b0c:	e04a                	sd	s2,0(sp)
    80002b0e:	1000                	addi	s0,sp,32
    80002b10:	84aa                	mv	s1,a0
    80002b12:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b14:	fffff097          	auipc	ra,0xfffff
    80002b18:	f50080e7          	jalr	-176(ra) # 80001a64 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b1c:	653c                	ld	a5,72(a0)
    80002b1e:	02f4f863          	bgeu	s1,a5,80002b4e <fetchaddr+0x4a>
    80002b22:	00848713          	addi	a4,s1,8
    80002b26:	02e7e663          	bltu	a5,a4,80002b52 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b2a:	46a1                	li	a3,8
    80002b2c:	8626                	mv	a2,s1
    80002b2e:	85ca                	mv	a1,s2
    80002b30:	6928                	ld	a0,80(a0)
    80002b32:	fffff097          	auipc	ra,0xfffff
    80002b36:	cb2080e7          	jalr	-846(ra) # 800017e4 <copyin>
    80002b3a:	00a03533          	snez	a0,a0
    80002b3e:	40a00533          	neg	a0,a0
}
    80002b42:	60e2                	ld	ra,24(sp)
    80002b44:	6442                	ld	s0,16(sp)
    80002b46:	64a2                	ld	s1,8(sp)
    80002b48:	6902                	ld	s2,0(sp)
    80002b4a:	6105                	addi	sp,sp,32
    80002b4c:	8082                	ret
    return -1;
    80002b4e:	557d                	li	a0,-1
    80002b50:	bfcd                	j	80002b42 <fetchaddr+0x3e>
    80002b52:	557d                	li	a0,-1
    80002b54:	b7fd                	j	80002b42 <fetchaddr+0x3e>

0000000080002b56 <fetchstr>:
{
    80002b56:	7179                	addi	sp,sp,-48
    80002b58:	f406                	sd	ra,40(sp)
    80002b5a:	f022                	sd	s0,32(sp)
    80002b5c:	ec26                	sd	s1,24(sp)
    80002b5e:	e84a                	sd	s2,16(sp)
    80002b60:	e44e                	sd	s3,8(sp)
    80002b62:	1800                	addi	s0,sp,48
    80002b64:	892a                	mv	s2,a0
    80002b66:	84ae                	mv	s1,a1
    80002b68:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b6a:	fffff097          	auipc	ra,0xfffff
    80002b6e:	efa080e7          	jalr	-262(ra) # 80001a64 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b72:	86ce                	mv	a3,s3
    80002b74:	864a                	mv	a2,s2
    80002b76:	85a6                	mv	a1,s1
    80002b78:	6928                	ld	a0,80(a0)
    80002b7a:	fffff097          	auipc	ra,0xfffff
    80002b7e:	cf6080e7          	jalr	-778(ra) # 80001870 <copyinstr>
  if(err < 0)
    80002b82:	00054763          	bltz	a0,80002b90 <fetchstr+0x3a>
  return strlen(buf);
    80002b86:	8526                	mv	a0,s1
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	392080e7          	jalr	914(ra) # 80000f1a <strlen>
}
    80002b90:	70a2                	ld	ra,40(sp)
    80002b92:	7402                	ld	s0,32(sp)
    80002b94:	64e2                	ld	s1,24(sp)
    80002b96:	6942                	ld	s2,16(sp)
    80002b98:	69a2                	ld	s3,8(sp)
    80002b9a:	6145                	addi	sp,sp,48
    80002b9c:	8082                	ret

0000000080002b9e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b9e:	1101                	addi	sp,sp,-32
    80002ba0:	ec06                	sd	ra,24(sp)
    80002ba2:	e822                	sd	s0,16(sp)
    80002ba4:	e426                	sd	s1,8(sp)
    80002ba6:	1000                	addi	s0,sp,32
    80002ba8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002baa:	00000097          	auipc	ra,0x0
    80002bae:	ef2080e7          	jalr	-270(ra) # 80002a9c <argraw>
    80002bb2:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bb4:	4501                	li	a0,0
    80002bb6:	60e2                	ld	ra,24(sp)
    80002bb8:	6442                	ld	s0,16(sp)
    80002bba:	64a2                	ld	s1,8(sp)
    80002bbc:	6105                	addi	sp,sp,32
    80002bbe:	8082                	ret

0000000080002bc0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bc0:	1101                	addi	sp,sp,-32
    80002bc2:	ec06                	sd	ra,24(sp)
    80002bc4:	e822                	sd	s0,16(sp)
    80002bc6:	e426                	sd	s1,8(sp)
    80002bc8:	1000                	addi	s0,sp,32
    80002bca:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bcc:	00000097          	auipc	ra,0x0
    80002bd0:	ed0080e7          	jalr	-304(ra) # 80002a9c <argraw>
    80002bd4:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bd6:	4501                	li	a0,0
    80002bd8:	60e2                	ld	ra,24(sp)
    80002bda:	6442                	ld	s0,16(sp)
    80002bdc:	64a2                	ld	s1,8(sp)
    80002bde:	6105                	addi	sp,sp,32
    80002be0:	8082                	ret

0000000080002be2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002be2:	1101                	addi	sp,sp,-32
    80002be4:	ec06                	sd	ra,24(sp)
    80002be6:	e822                	sd	s0,16(sp)
    80002be8:	e426                	sd	s1,8(sp)
    80002bea:	e04a                	sd	s2,0(sp)
    80002bec:	1000                	addi	s0,sp,32
    80002bee:	84ae                	mv	s1,a1
    80002bf0:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bf2:	00000097          	auipc	ra,0x0
    80002bf6:	eaa080e7          	jalr	-342(ra) # 80002a9c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bfa:	864a                	mv	a2,s2
    80002bfc:	85a6                	mv	a1,s1
    80002bfe:	00000097          	auipc	ra,0x0
    80002c02:	f58080e7          	jalr	-168(ra) # 80002b56 <fetchstr>
}
    80002c06:	60e2                	ld	ra,24(sp)
    80002c08:	6442                	ld	s0,16(sp)
    80002c0a:	64a2                	ld	s1,8(sp)
    80002c0c:	6902                	ld	s2,0(sp)
    80002c0e:	6105                	addi	sp,sp,32
    80002c10:	8082                	ret

0000000080002c12 <syscall>:
[SYS_sigreturn] sys_sigreturn,
};

void
syscall(void)
{
    80002c12:	1101                	addi	sp,sp,-32
    80002c14:	ec06                	sd	ra,24(sp)
    80002c16:	e822                	sd	s0,16(sp)
    80002c18:	e426                	sd	s1,8(sp)
    80002c1a:	e04a                	sd	s2,0(sp)
    80002c1c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c1e:	fffff097          	auipc	ra,0xfffff
    80002c22:	e46080e7          	jalr	-442(ra) # 80001a64 <myproc>
    80002c26:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c28:	05853903          	ld	s2,88(a0)
    80002c2c:	0a893783          	ld	a5,168(s2)
    80002c30:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c34:	37fd                	addiw	a5,a5,-1
    80002c36:	4759                	li	a4,22
    80002c38:	00f76f63          	bltu	a4,a5,80002c56 <syscall+0x44>
    80002c3c:	00369713          	slli	a4,a3,0x3
    80002c40:	00006797          	auipc	a5,0x6
    80002c44:	80878793          	addi	a5,a5,-2040 # 80008448 <syscalls>
    80002c48:	97ba                	add	a5,a5,a4
    80002c4a:	639c                	ld	a5,0(a5)
    80002c4c:	c789                	beqz	a5,80002c56 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c4e:	9782                	jalr	a5
    80002c50:	06a93823          	sd	a0,112(s2)
    80002c54:	a839                	j	80002c72 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c56:	15848613          	addi	a2,s1,344
    80002c5a:	5c8c                	lw	a1,56(s1)
    80002c5c:	00005517          	auipc	a0,0x5
    80002c60:	7b450513          	addi	a0,a0,1972 # 80008410 <states.1712+0x150>
    80002c64:	ffffe097          	auipc	ra,0xffffe
    80002c68:	9e6080e7          	jalr	-1562(ra) # 8000064a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c6c:	6cbc                	ld	a5,88(s1)
    80002c6e:	577d                	li	a4,-1
    80002c70:	fbb8                	sd	a4,112(a5)
  }
}
    80002c72:	60e2                	ld	ra,24(sp)
    80002c74:	6442                	ld	s0,16(sp)
    80002c76:	64a2                	ld	s1,8(sp)
    80002c78:	6902                	ld	s2,0(sp)
    80002c7a:	6105                	addi	sp,sp,32
    80002c7c:	8082                	ret

0000000080002c7e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c7e:	1101                	addi	sp,sp,-32
    80002c80:	ec06                	sd	ra,24(sp)
    80002c82:	e822                	sd	s0,16(sp)
    80002c84:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c86:	fec40593          	addi	a1,s0,-20
    80002c8a:	4501                	li	a0,0
    80002c8c:	00000097          	auipc	ra,0x0
    80002c90:	f12080e7          	jalr	-238(ra) # 80002b9e <argint>
    return -1;
    80002c94:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c96:	00054963          	bltz	a0,80002ca8 <sys_exit+0x2a>
  exit(n);
    80002c9a:	fec42503          	lw	a0,-20(s0)
    80002c9e:	fffff097          	auipc	ra,0xfffff
    80002ca2:	4a4080e7          	jalr	1188(ra) # 80002142 <exit>
  return 0;  // not reached
    80002ca6:	4781                	li	a5,0
}
    80002ca8:	853e                	mv	a0,a5
    80002caa:	60e2                	ld	ra,24(sp)
    80002cac:	6442                	ld	s0,16(sp)
    80002cae:	6105                	addi	sp,sp,32
    80002cb0:	8082                	ret

0000000080002cb2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cb2:	1141                	addi	sp,sp,-16
    80002cb4:	e406                	sd	ra,8(sp)
    80002cb6:	e022                	sd	s0,0(sp)
    80002cb8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	daa080e7          	jalr	-598(ra) # 80001a64 <myproc>
}
    80002cc2:	5d08                	lw	a0,56(a0)
    80002cc4:	60a2                	ld	ra,8(sp)
    80002cc6:	6402                	ld	s0,0(sp)
    80002cc8:	0141                	addi	sp,sp,16
    80002cca:	8082                	ret

0000000080002ccc <sys_fork>:

uint64
sys_fork(void)
{
    80002ccc:	1141                	addi	sp,sp,-16
    80002cce:	e406                	sd	ra,8(sp)
    80002cd0:	e022                	sd	s0,0(sp)
    80002cd2:	0800                	addi	s0,sp,16
  return fork();
    80002cd4:	fffff097          	auipc	ra,0xfffff
    80002cd8:	168080e7          	jalr	360(ra) # 80001e3c <fork>
}
    80002cdc:	60a2                	ld	ra,8(sp)
    80002cde:	6402                	ld	s0,0(sp)
    80002ce0:	0141                	addi	sp,sp,16
    80002ce2:	8082                	ret

0000000080002ce4 <sys_wait>:

uint64
sys_wait(void)
{
    80002ce4:	1101                	addi	sp,sp,-32
    80002ce6:	ec06                	sd	ra,24(sp)
    80002ce8:	e822                	sd	s0,16(sp)
    80002cea:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cec:	fe840593          	addi	a1,s0,-24
    80002cf0:	4501                	li	a0,0
    80002cf2:	00000097          	auipc	ra,0x0
    80002cf6:	ece080e7          	jalr	-306(ra) # 80002bc0 <argaddr>
    80002cfa:	87aa                	mv	a5,a0
    return -1;
    80002cfc:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cfe:	0007c863          	bltz	a5,80002d0e <sys_wait+0x2a>
  return wait(p);
    80002d02:	fe843503          	ld	a0,-24(s0)
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	600080e7          	jalr	1536(ra) # 80002306 <wait>
}
    80002d0e:	60e2                	ld	ra,24(sp)
    80002d10:	6442                	ld	s0,16(sp)
    80002d12:	6105                	addi	sp,sp,32
    80002d14:	8082                	ret

0000000080002d16 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d16:	7179                	addi	sp,sp,-48
    80002d18:	f406                	sd	ra,40(sp)
    80002d1a:	f022                	sd	s0,32(sp)
    80002d1c:	ec26                	sd	s1,24(sp)
    80002d1e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d20:	fdc40593          	addi	a1,s0,-36
    80002d24:	4501                	li	a0,0
    80002d26:	00000097          	auipc	ra,0x0
    80002d2a:	e78080e7          	jalr	-392(ra) # 80002b9e <argint>
    80002d2e:	87aa                	mv	a5,a0
    return -1;
    80002d30:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d32:	0207c063          	bltz	a5,80002d52 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d36:	fffff097          	auipc	ra,0xfffff
    80002d3a:	d2e080e7          	jalr	-722(ra) # 80001a64 <myproc>
    80002d3e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d40:	fdc42503          	lw	a0,-36(s0)
    80002d44:	fffff097          	auipc	ra,0xfffff
    80002d48:	084080e7          	jalr	132(ra) # 80001dc8 <growproc>
    80002d4c:	00054863          	bltz	a0,80002d5c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d50:	8526                	mv	a0,s1
}
    80002d52:	70a2                	ld	ra,40(sp)
    80002d54:	7402                	ld	s0,32(sp)
    80002d56:	64e2                	ld	s1,24(sp)
    80002d58:	6145                	addi	sp,sp,48
    80002d5a:	8082                	ret
    return -1;
    80002d5c:	557d                	li	a0,-1
    80002d5e:	bfd5                	j	80002d52 <sys_sbrk+0x3c>

0000000080002d60 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d60:	7139                	addi	sp,sp,-64
    80002d62:	fc06                	sd	ra,56(sp)
    80002d64:	f822                	sd	s0,48(sp)
    80002d66:	f426                	sd	s1,40(sp)
    80002d68:	f04a                	sd	s2,32(sp)
    80002d6a:	ec4e                	sd	s3,24(sp)
    80002d6c:	0080                	addi	s0,sp,64
  backtrace();
    80002d6e:	ffffe097          	auipc	ra,0xffffe
    80002d72:	80c080e7          	jalr	-2036(ra) # 8000057a <backtrace>
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d76:	fcc40593          	addi	a1,s0,-52
    80002d7a:	4501                	li	a0,0
    80002d7c:	00000097          	auipc	ra,0x0
    80002d80:	e22080e7          	jalr	-478(ra) # 80002b9e <argint>
    return -1;
    80002d84:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d86:	06054563          	bltz	a0,80002df0 <sys_sleep+0x90>
  acquire(&tickslock);
    80002d8a:	00019517          	auipc	a0,0x19
    80002d8e:	7de50513          	addi	a0,a0,2014 # 8001c568 <tickslock>
    80002d92:	ffffe097          	auipc	ra,0xffffe
    80002d96:	f04080e7          	jalr	-252(ra) # 80000c96 <acquire>
  ticks0 = ticks;
    80002d9a:	00006917          	auipc	s2,0x6
    80002d9e:	28692903          	lw	s2,646(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002da2:	fcc42783          	lw	a5,-52(s0)
    80002da6:	cf85                	beqz	a5,80002dde <sys_sleep+0x7e>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002da8:	00019997          	auipc	s3,0x19
    80002dac:	7c098993          	addi	s3,s3,1984 # 8001c568 <tickslock>
    80002db0:	00006497          	auipc	s1,0x6
    80002db4:	27048493          	addi	s1,s1,624 # 80009020 <ticks>
    if(myproc()->killed){
    80002db8:	fffff097          	auipc	ra,0xfffff
    80002dbc:	cac080e7          	jalr	-852(ra) # 80001a64 <myproc>
    80002dc0:	591c                	lw	a5,48(a0)
    80002dc2:	ef9d                	bnez	a5,80002e00 <sys_sleep+0xa0>
    sleep(&ticks, &tickslock);
    80002dc4:	85ce                	mv	a1,s3
    80002dc6:	8526                	mv	a0,s1
    80002dc8:	fffff097          	auipc	ra,0xfffff
    80002dcc:	4c0080e7          	jalr	1216(ra) # 80002288 <sleep>
  while(ticks - ticks0 < n){
    80002dd0:	409c                	lw	a5,0(s1)
    80002dd2:	412787bb          	subw	a5,a5,s2
    80002dd6:	fcc42703          	lw	a4,-52(s0)
    80002dda:	fce7efe3          	bltu	a5,a4,80002db8 <sys_sleep+0x58>
  }
  release(&tickslock);
    80002dde:	00019517          	auipc	a0,0x19
    80002de2:	78a50513          	addi	a0,a0,1930 # 8001c568 <tickslock>
    80002de6:	ffffe097          	auipc	ra,0xffffe
    80002dea:	f64080e7          	jalr	-156(ra) # 80000d4a <release>
  return 0;
    80002dee:	4781                	li	a5,0
}
    80002df0:	853e                	mv	a0,a5
    80002df2:	70e2                	ld	ra,56(sp)
    80002df4:	7442                	ld	s0,48(sp)
    80002df6:	74a2                	ld	s1,40(sp)
    80002df8:	7902                	ld	s2,32(sp)
    80002dfa:	69e2                	ld	s3,24(sp)
    80002dfc:	6121                	addi	sp,sp,64
    80002dfe:	8082                	ret
      release(&tickslock);
    80002e00:	00019517          	auipc	a0,0x19
    80002e04:	76850513          	addi	a0,a0,1896 # 8001c568 <tickslock>
    80002e08:	ffffe097          	auipc	ra,0xffffe
    80002e0c:	f42080e7          	jalr	-190(ra) # 80000d4a <release>
      return -1;
    80002e10:	57fd                	li	a5,-1
    80002e12:	bff9                	j	80002df0 <sys_sleep+0x90>

0000000080002e14 <sys_kill>:

uint64
sys_kill(void)
{
    80002e14:	1101                	addi	sp,sp,-32
    80002e16:	ec06                	sd	ra,24(sp)
    80002e18:	e822                	sd	s0,16(sp)
    80002e1a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e1c:	fec40593          	addi	a1,s0,-20
    80002e20:	4501                	li	a0,0
    80002e22:	00000097          	auipc	ra,0x0
    80002e26:	d7c080e7          	jalr	-644(ra) # 80002b9e <argint>
    80002e2a:	87aa                	mv	a5,a0
    return -1;
    80002e2c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e2e:	0007c863          	bltz	a5,80002e3e <sys_kill+0x2a>
  return kill(pid);
    80002e32:	fec42503          	lw	a0,-20(s0)
    80002e36:	fffff097          	auipc	ra,0xfffff
    80002e3a:	642080e7          	jalr	1602(ra) # 80002478 <kill>
}
    80002e3e:	60e2                	ld	ra,24(sp)
    80002e40:	6442                	ld	s0,16(sp)
    80002e42:	6105                	addi	sp,sp,32
    80002e44:	8082                	ret

0000000080002e46 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e46:	1101                	addi	sp,sp,-32
    80002e48:	ec06                	sd	ra,24(sp)
    80002e4a:	e822                	sd	s0,16(sp)
    80002e4c:	e426                	sd	s1,8(sp)
    80002e4e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e50:	00019517          	auipc	a0,0x19
    80002e54:	71850513          	addi	a0,a0,1816 # 8001c568 <tickslock>
    80002e58:	ffffe097          	auipc	ra,0xffffe
    80002e5c:	e3e080e7          	jalr	-450(ra) # 80000c96 <acquire>
  xticks = ticks;
    80002e60:	00006497          	auipc	s1,0x6
    80002e64:	1c04a483          	lw	s1,448(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e68:	00019517          	auipc	a0,0x19
    80002e6c:	70050513          	addi	a0,a0,1792 # 8001c568 <tickslock>
    80002e70:	ffffe097          	auipc	ra,0xffffe
    80002e74:	eda080e7          	jalr	-294(ra) # 80000d4a <release>
  return xticks;
}
    80002e78:	02049513          	slli	a0,s1,0x20
    80002e7c:	9101                	srli	a0,a0,0x20
    80002e7e:	60e2                	ld	ra,24(sp)
    80002e80:	6442                	ld	s0,16(sp)
    80002e82:	64a2                	ld	s1,8(sp)
    80002e84:	6105                	addi	sp,sp,32
    80002e86:	8082                	ret

0000000080002e88 <sys_sigreturn>:

uint64
sys_sigreturn(void)//恢复被中断的程序的执行，并清除一些相关的状态信息
{
    80002e88:	1141                	addi	sp,sp,-16
    80002e8a:	e406                	sd	ra,8(sp)
    80002e8c:	e022                	sd	s0,0(sp)
    80002e8e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();//通过调用myproc()函数获取当前进程的指针
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	bd4080e7          	jalr	-1068(ra) # 80001a64 <myproc>
  //将当前进程的since_interval成员变量设置为0。
  p->since_interval = 0;//这个变量用于跟踪自上一次定时器中断以来经过的时间。
    80002e98:	16052623          	sw	zero,364(a0)
  //将当前进程的trapframe_cp成员变量的值复制到trapframe成员变量指向的内存中。
  *(p->trapframe) = p->trapframe_cp;//trapframe_cp用于保存中断处理程序的上下文，trapframe用于恢复被中断的程序的执行。
    80002e9c:	18050793          	addi	a5,a0,384
    80002ea0:	6d38                	ld	a4,88(a0)
    80002ea2:	2a050693          	addi	a3,a0,672
    80002ea6:	0007b883          	ld	a7,0(a5)
    80002eaa:	0087b803          	ld	a6,8(a5)
    80002eae:	6b8c                	ld	a1,16(a5)
    80002eb0:	6f90                	ld	a2,24(a5)
    80002eb2:	01173023          	sd	a7,0(a4)
    80002eb6:	01073423          	sd	a6,8(a4)
    80002eba:	eb0c                	sd	a1,16(a4)
    80002ebc:	ef10                	sd	a2,24(a4)
    80002ebe:	02078793          	addi	a5,a5,32
    80002ec2:	02070713          	addi	a4,a4,32
    80002ec6:	fed790e3          	bne	a5,a3,80002ea6 <sys_sigreturn+0x1e>
  p->running_hand = 0;//确保在恢复被中断的程序的执行之前，没有其他中断处理程序正在运行
    80002eca:	16052c23          	sw	zero,376(a0)
  return 0;
}
    80002ece:	4501                	li	a0,0
    80002ed0:	60a2                	ld	ra,8(sp)
    80002ed2:	6402                	ld	s0,0(sp)
    80002ed4:	0141                	addi	sp,sp,16
    80002ed6:	8082                	ret

0000000080002ed8 <sys_sigalarm>:

uint64
sys_sigalarm(void)//设置定时器并关联中断处理函数
{
    80002ed8:	7179                	addi	sp,sp,-48
    80002eda:	f406                	sd	ra,40(sp)
    80002edc:	f022                	sd	s0,32(sp)
    80002ede:	ec26                	sd	s1,24(sp)
    80002ee0:	1800                	addi	s0,sp,48
  int interval;//用于存储定时器的时间间隔
  uint64 pointer;//用于存储中断处理函数的指针
  if(argint(0, &interval) < 0)
    80002ee2:	fdc40593          	addi	a1,s0,-36
    80002ee6:	4501                	li	a0,0
    80002ee8:	00000097          	auipc	ra,0x0
    80002eec:	cb6080e7          	jalr	-842(ra) # 80002b9e <argint>
    80002ef0:	06054463          	bltz	a0,80002f58 <sys_sigalarm+0x80>
    return -1;
  if(interval == 0)//如果定时器的时间间隔为0，直接返回0。这表示停止定时器，不需要设置中断处理函数。
    80002ef4:	fdc42783          	lw	a5,-36(s0)
    return 0;
    80002ef8:	4501                	li	a0,0
  if(interval == 0)//如果定时器的时间间隔为0，直接返回0。这表示停止定时器，不需要设置中断处理函数。
    80002efa:	e791                	bnez	a5,80002f06 <sys_sigalarm+0x2e>
  myproc()->handler = (void *)pointer;//将当前进程的handler成员变量设置为pointer的值，即设置中断处理函数的指针。
  myproc()->since_interval = 0;//将当前进程的since_interval成员变量设置为0。这个变量用于跟踪自上一次定时器中断以来经过的时间。
  myproc()->running_hand = 0;//确保在设置定时器之前，没有其他中断处理程序正在运行
  myproc()->interval = interval;//设置定时器的时间间隔。
  return 0;
    80002efc:	70a2                	ld	ra,40(sp)
    80002efe:	7402                	ld	s0,32(sp)
    80002f00:	64e2                	ld	s1,24(sp)
    80002f02:	6145                	addi	sp,sp,48
    80002f04:	8082                	ret
  if(argaddr(1, &pointer) < 0)
    80002f06:	fd040593          	addi	a1,s0,-48
    80002f0a:	4505                	li	a0,1
    80002f0c:	00000097          	auipc	ra,0x0
    80002f10:	cb4080e7          	jalr	-844(ra) # 80002bc0 <argaddr>
    80002f14:	87aa                	mv	a5,a0
    return -1;
    80002f16:	557d                	li	a0,-1
  if(argaddr(1, &pointer) < 0)
    80002f18:	fe07c2e3          	bltz	a5,80002efc <sys_sigalarm+0x24>
  myproc()->handler = (void *)pointer;//将当前进程的handler成员变量设置为pointer的值，即设置中断处理函数的指针。
    80002f1c:	fd043483          	ld	s1,-48(s0)
    80002f20:	fffff097          	auipc	ra,0xfffff
    80002f24:	b44080e7          	jalr	-1212(ra) # 80001a64 <myproc>
    80002f28:	16953823          	sd	s1,368(a0)
  myproc()->since_interval = 0;//将当前进程的since_interval成员变量设置为0。这个变量用于跟踪自上一次定时器中断以来经过的时间。
    80002f2c:	fffff097          	auipc	ra,0xfffff
    80002f30:	b38080e7          	jalr	-1224(ra) # 80001a64 <myproc>
    80002f34:	16052623          	sw	zero,364(a0)
  myproc()->running_hand = 0;//确保在设置定时器之前，没有其他中断处理程序正在运行
    80002f38:	fffff097          	auipc	ra,0xfffff
    80002f3c:	b2c080e7          	jalr	-1236(ra) # 80001a64 <myproc>
    80002f40:	16052c23          	sw	zero,376(a0)
  myproc()->interval = interval;//设置定时器的时间间隔。
    80002f44:	fffff097          	auipc	ra,0xfffff
    80002f48:	b20080e7          	jalr	-1248(ra) # 80001a64 <myproc>
    80002f4c:	fdc42783          	lw	a5,-36(s0)
    80002f50:	16f52423          	sw	a5,360(a0)
  return 0;
    80002f54:	4501                	li	a0,0
    80002f56:	b75d                	j	80002efc <sys_sigalarm+0x24>
    return -1;
    80002f58:	557d                	li	a0,-1
    80002f5a:	b74d                	j	80002efc <sys_sigalarm+0x24>

0000000080002f5c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f5c:	7179                	addi	sp,sp,-48
    80002f5e:	f406                	sd	ra,40(sp)
    80002f60:	f022                	sd	s0,32(sp)
    80002f62:	ec26                	sd	s1,24(sp)
    80002f64:	e84a                	sd	s2,16(sp)
    80002f66:	e44e                	sd	s3,8(sp)
    80002f68:	e052                	sd	s4,0(sp)
    80002f6a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f6c:	00005597          	auipc	a1,0x5
    80002f70:	59c58593          	addi	a1,a1,1436 # 80008508 <syscalls+0xc0>
    80002f74:	00019517          	auipc	a0,0x19
    80002f78:	60c50513          	addi	a0,a0,1548 # 8001c580 <bcache>
    80002f7c:	ffffe097          	auipc	ra,0xffffe
    80002f80:	c8a080e7          	jalr	-886(ra) # 80000c06 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f84:	00021797          	auipc	a5,0x21
    80002f88:	5fc78793          	addi	a5,a5,1532 # 80024580 <bcache+0x8000>
    80002f8c:	00022717          	auipc	a4,0x22
    80002f90:	85c70713          	addi	a4,a4,-1956 # 800247e8 <bcache+0x8268>
    80002f94:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f98:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f9c:	00019497          	auipc	s1,0x19
    80002fa0:	5fc48493          	addi	s1,s1,1532 # 8001c598 <bcache+0x18>
    b->next = bcache.head.next;
    80002fa4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fa6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fa8:	00005a17          	auipc	s4,0x5
    80002fac:	568a0a13          	addi	s4,s4,1384 # 80008510 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002fb0:	2b893783          	ld	a5,696(s2)
    80002fb4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fb6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fba:	85d2                	mv	a1,s4
    80002fbc:	01048513          	addi	a0,s1,16
    80002fc0:	00001097          	auipc	ra,0x1
    80002fc4:	4ac080e7          	jalr	1196(ra) # 8000446c <initsleeplock>
    bcache.head.next->prev = b;
    80002fc8:	2b893783          	ld	a5,696(s2)
    80002fcc:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fce:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fd2:	45848493          	addi	s1,s1,1112
    80002fd6:	fd349de3          	bne	s1,s3,80002fb0 <binit+0x54>
  }
}
    80002fda:	70a2                	ld	ra,40(sp)
    80002fdc:	7402                	ld	s0,32(sp)
    80002fde:	64e2                	ld	s1,24(sp)
    80002fe0:	6942                	ld	s2,16(sp)
    80002fe2:	69a2                	ld	s3,8(sp)
    80002fe4:	6a02                	ld	s4,0(sp)
    80002fe6:	6145                	addi	sp,sp,48
    80002fe8:	8082                	ret

0000000080002fea <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fea:	7179                	addi	sp,sp,-48
    80002fec:	f406                	sd	ra,40(sp)
    80002fee:	f022                	sd	s0,32(sp)
    80002ff0:	ec26                	sd	s1,24(sp)
    80002ff2:	e84a                	sd	s2,16(sp)
    80002ff4:	e44e                	sd	s3,8(sp)
    80002ff6:	1800                	addi	s0,sp,48
    80002ff8:	89aa                	mv	s3,a0
    80002ffa:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002ffc:	00019517          	auipc	a0,0x19
    80003000:	58450513          	addi	a0,a0,1412 # 8001c580 <bcache>
    80003004:	ffffe097          	auipc	ra,0xffffe
    80003008:	c92080e7          	jalr	-878(ra) # 80000c96 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000300c:	00022497          	auipc	s1,0x22
    80003010:	82c4b483          	ld	s1,-2004(s1) # 80024838 <bcache+0x82b8>
    80003014:	00021797          	auipc	a5,0x21
    80003018:	7d478793          	addi	a5,a5,2004 # 800247e8 <bcache+0x8268>
    8000301c:	02f48f63          	beq	s1,a5,8000305a <bread+0x70>
    80003020:	873e                	mv	a4,a5
    80003022:	a021                	j	8000302a <bread+0x40>
    80003024:	68a4                	ld	s1,80(s1)
    80003026:	02e48a63          	beq	s1,a4,8000305a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000302a:	449c                	lw	a5,8(s1)
    8000302c:	ff379ce3          	bne	a5,s3,80003024 <bread+0x3a>
    80003030:	44dc                	lw	a5,12(s1)
    80003032:	ff2799e3          	bne	a5,s2,80003024 <bread+0x3a>
      b->refcnt++;
    80003036:	40bc                	lw	a5,64(s1)
    80003038:	2785                	addiw	a5,a5,1
    8000303a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000303c:	00019517          	auipc	a0,0x19
    80003040:	54450513          	addi	a0,a0,1348 # 8001c580 <bcache>
    80003044:	ffffe097          	auipc	ra,0xffffe
    80003048:	d06080e7          	jalr	-762(ra) # 80000d4a <release>
      acquiresleep(&b->lock);
    8000304c:	01048513          	addi	a0,s1,16
    80003050:	00001097          	auipc	ra,0x1
    80003054:	456080e7          	jalr	1110(ra) # 800044a6 <acquiresleep>
      return b;
    80003058:	a8b9                	j	800030b6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000305a:	00021497          	auipc	s1,0x21
    8000305e:	7d64b483          	ld	s1,2006(s1) # 80024830 <bcache+0x82b0>
    80003062:	00021797          	auipc	a5,0x21
    80003066:	78678793          	addi	a5,a5,1926 # 800247e8 <bcache+0x8268>
    8000306a:	00f48863          	beq	s1,a5,8000307a <bread+0x90>
    8000306e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003070:	40bc                	lw	a5,64(s1)
    80003072:	cf81                	beqz	a5,8000308a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003074:	64a4                	ld	s1,72(s1)
    80003076:	fee49de3          	bne	s1,a4,80003070 <bread+0x86>
  panic("bget: no buffers");
    8000307a:	00005517          	auipc	a0,0x5
    8000307e:	49e50513          	addi	a0,a0,1182 # 80008518 <syscalls+0xd0>
    80003082:	ffffd097          	auipc	ra,0xffffd
    80003086:	576080e7          	jalr	1398(ra) # 800005f8 <panic>
      b->dev = dev;
    8000308a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000308e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003092:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003096:	4785                	li	a5,1
    80003098:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000309a:	00019517          	auipc	a0,0x19
    8000309e:	4e650513          	addi	a0,a0,1254 # 8001c580 <bcache>
    800030a2:	ffffe097          	auipc	ra,0xffffe
    800030a6:	ca8080e7          	jalr	-856(ra) # 80000d4a <release>
      acquiresleep(&b->lock);
    800030aa:	01048513          	addi	a0,s1,16
    800030ae:	00001097          	auipc	ra,0x1
    800030b2:	3f8080e7          	jalr	1016(ra) # 800044a6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030b6:	409c                	lw	a5,0(s1)
    800030b8:	cb89                	beqz	a5,800030ca <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030ba:	8526                	mv	a0,s1
    800030bc:	70a2                	ld	ra,40(sp)
    800030be:	7402                	ld	s0,32(sp)
    800030c0:	64e2                	ld	s1,24(sp)
    800030c2:	6942                	ld	s2,16(sp)
    800030c4:	69a2                	ld	s3,8(sp)
    800030c6:	6145                	addi	sp,sp,48
    800030c8:	8082                	ret
    virtio_disk_rw(b, 0);
    800030ca:	4581                	li	a1,0
    800030cc:	8526                	mv	a0,s1
    800030ce:	00003097          	auipc	ra,0x3
    800030d2:	f2e080e7          	jalr	-210(ra) # 80005ffc <virtio_disk_rw>
    b->valid = 1;
    800030d6:	4785                	li	a5,1
    800030d8:	c09c                	sw	a5,0(s1)
  return b;
    800030da:	b7c5                	j	800030ba <bread+0xd0>

00000000800030dc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030dc:	1101                	addi	sp,sp,-32
    800030de:	ec06                	sd	ra,24(sp)
    800030e0:	e822                	sd	s0,16(sp)
    800030e2:	e426                	sd	s1,8(sp)
    800030e4:	1000                	addi	s0,sp,32
    800030e6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030e8:	0541                	addi	a0,a0,16
    800030ea:	00001097          	auipc	ra,0x1
    800030ee:	456080e7          	jalr	1110(ra) # 80004540 <holdingsleep>
    800030f2:	cd01                	beqz	a0,8000310a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030f4:	4585                	li	a1,1
    800030f6:	8526                	mv	a0,s1
    800030f8:	00003097          	auipc	ra,0x3
    800030fc:	f04080e7          	jalr	-252(ra) # 80005ffc <virtio_disk_rw>
}
    80003100:	60e2                	ld	ra,24(sp)
    80003102:	6442                	ld	s0,16(sp)
    80003104:	64a2                	ld	s1,8(sp)
    80003106:	6105                	addi	sp,sp,32
    80003108:	8082                	ret
    panic("bwrite");
    8000310a:	00005517          	auipc	a0,0x5
    8000310e:	42650513          	addi	a0,a0,1062 # 80008530 <syscalls+0xe8>
    80003112:	ffffd097          	auipc	ra,0xffffd
    80003116:	4e6080e7          	jalr	1254(ra) # 800005f8 <panic>

000000008000311a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000311a:	1101                	addi	sp,sp,-32
    8000311c:	ec06                	sd	ra,24(sp)
    8000311e:	e822                	sd	s0,16(sp)
    80003120:	e426                	sd	s1,8(sp)
    80003122:	e04a                	sd	s2,0(sp)
    80003124:	1000                	addi	s0,sp,32
    80003126:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003128:	01050913          	addi	s2,a0,16
    8000312c:	854a                	mv	a0,s2
    8000312e:	00001097          	auipc	ra,0x1
    80003132:	412080e7          	jalr	1042(ra) # 80004540 <holdingsleep>
    80003136:	c92d                	beqz	a0,800031a8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003138:	854a                	mv	a0,s2
    8000313a:	00001097          	auipc	ra,0x1
    8000313e:	3c2080e7          	jalr	962(ra) # 800044fc <releasesleep>

  acquire(&bcache.lock);
    80003142:	00019517          	auipc	a0,0x19
    80003146:	43e50513          	addi	a0,a0,1086 # 8001c580 <bcache>
    8000314a:	ffffe097          	auipc	ra,0xffffe
    8000314e:	b4c080e7          	jalr	-1204(ra) # 80000c96 <acquire>
  b->refcnt--;
    80003152:	40bc                	lw	a5,64(s1)
    80003154:	37fd                	addiw	a5,a5,-1
    80003156:	0007871b          	sext.w	a4,a5
    8000315a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000315c:	eb05                	bnez	a4,8000318c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000315e:	68bc                	ld	a5,80(s1)
    80003160:	64b8                	ld	a4,72(s1)
    80003162:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003164:	64bc                	ld	a5,72(s1)
    80003166:	68b8                	ld	a4,80(s1)
    80003168:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000316a:	00021797          	auipc	a5,0x21
    8000316e:	41678793          	addi	a5,a5,1046 # 80024580 <bcache+0x8000>
    80003172:	2b87b703          	ld	a4,696(a5)
    80003176:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003178:	00021717          	auipc	a4,0x21
    8000317c:	67070713          	addi	a4,a4,1648 # 800247e8 <bcache+0x8268>
    80003180:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003182:	2b87b703          	ld	a4,696(a5)
    80003186:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003188:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000318c:	00019517          	auipc	a0,0x19
    80003190:	3f450513          	addi	a0,a0,1012 # 8001c580 <bcache>
    80003194:	ffffe097          	auipc	ra,0xffffe
    80003198:	bb6080e7          	jalr	-1098(ra) # 80000d4a <release>
}
    8000319c:	60e2                	ld	ra,24(sp)
    8000319e:	6442                	ld	s0,16(sp)
    800031a0:	64a2                	ld	s1,8(sp)
    800031a2:	6902                	ld	s2,0(sp)
    800031a4:	6105                	addi	sp,sp,32
    800031a6:	8082                	ret
    panic("brelse");
    800031a8:	00005517          	auipc	a0,0x5
    800031ac:	39050513          	addi	a0,a0,912 # 80008538 <syscalls+0xf0>
    800031b0:	ffffd097          	auipc	ra,0xffffd
    800031b4:	448080e7          	jalr	1096(ra) # 800005f8 <panic>

00000000800031b8 <bpin>:

void
bpin(struct buf *b) {
    800031b8:	1101                	addi	sp,sp,-32
    800031ba:	ec06                	sd	ra,24(sp)
    800031bc:	e822                	sd	s0,16(sp)
    800031be:	e426                	sd	s1,8(sp)
    800031c0:	1000                	addi	s0,sp,32
    800031c2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031c4:	00019517          	auipc	a0,0x19
    800031c8:	3bc50513          	addi	a0,a0,956 # 8001c580 <bcache>
    800031cc:	ffffe097          	auipc	ra,0xffffe
    800031d0:	aca080e7          	jalr	-1334(ra) # 80000c96 <acquire>
  b->refcnt++;
    800031d4:	40bc                	lw	a5,64(s1)
    800031d6:	2785                	addiw	a5,a5,1
    800031d8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031da:	00019517          	auipc	a0,0x19
    800031de:	3a650513          	addi	a0,a0,934 # 8001c580 <bcache>
    800031e2:	ffffe097          	auipc	ra,0xffffe
    800031e6:	b68080e7          	jalr	-1176(ra) # 80000d4a <release>
}
    800031ea:	60e2                	ld	ra,24(sp)
    800031ec:	6442                	ld	s0,16(sp)
    800031ee:	64a2                	ld	s1,8(sp)
    800031f0:	6105                	addi	sp,sp,32
    800031f2:	8082                	ret

00000000800031f4 <bunpin>:

void
bunpin(struct buf *b) {
    800031f4:	1101                	addi	sp,sp,-32
    800031f6:	ec06                	sd	ra,24(sp)
    800031f8:	e822                	sd	s0,16(sp)
    800031fa:	e426                	sd	s1,8(sp)
    800031fc:	1000                	addi	s0,sp,32
    800031fe:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003200:	00019517          	auipc	a0,0x19
    80003204:	38050513          	addi	a0,a0,896 # 8001c580 <bcache>
    80003208:	ffffe097          	auipc	ra,0xffffe
    8000320c:	a8e080e7          	jalr	-1394(ra) # 80000c96 <acquire>
  b->refcnt--;
    80003210:	40bc                	lw	a5,64(s1)
    80003212:	37fd                	addiw	a5,a5,-1
    80003214:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003216:	00019517          	auipc	a0,0x19
    8000321a:	36a50513          	addi	a0,a0,874 # 8001c580 <bcache>
    8000321e:	ffffe097          	auipc	ra,0xffffe
    80003222:	b2c080e7          	jalr	-1236(ra) # 80000d4a <release>
}
    80003226:	60e2                	ld	ra,24(sp)
    80003228:	6442                	ld	s0,16(sp)
    8000322a:	64a2                	ld	s1,8(sp)
    8000322c:	6105                	addi	sp,sp,32
    8000322e:	8082                	ret

0000000080003230 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003230:	1101                	addi	sp,sp,-32
    80003232:	ec06                	sd	ra,24(sp)
    80003234:	e822                	sd	s0,16(sp)
    80003236:	e426                	sd	s1,8(sp)
    80003238:	e04a                	sd	s2,0(sp)
    8000323a:	1000                	addi	s0,sp,32
    8000323c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000323e:	00d5d59b          	srliw	a1,a1,0xd
    80003242:	00022797          	auipc	a5,0x22
    80003246:	a1a7a783          	lw	a5,-1510(a5) # 80024c5c <sb+0x1c>
    8000324a:	9dbd                	addw	a1,a1,a5
    8000324c:	00000097          	auipc	ra,0x0
    80003250:	d9e080e7          	jalr	-610(ra) # 80002fea <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003254:	0074f713          	andi	a4,s1,7
    80003258:	4785                	li	a5,1
    8000325a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000325e:	14ce                	slli	s1,s1,0x33
    80003260:	90d9                	srli	s1,s1,0x36
    80003262:	00950733          	add	a4,a0,s1
    80003266:	05874703          	lbu	a4,88(a4)
    8000326a:	00e7f6b3          	and	a3,a5,a4
    8000326e:	c69d                	beqz	a3,8000329c <bfree+0x6c>
    80003270:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003272:	94aa                	add	s1,s1,a0
    80003274:	fff7c793          	not	a5,a5
    80003278:	8ff9                	and	a5,a5,a4
    8000327a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000327e:	00001097          	auipc	ra,0x1
    80003282:	100080e7          	jalr	256(ra) # 8000437e <log_write>
  brelse(bp);
    80003286:	854a                	mv	a0,s2
    80003288:	00000097          	auipc	ra,0x0
    8000328c:	e92080e7          	jalr	-366(ra) # 8000311a <brelse>
}
    80003290:	60e2                	ld	ra,24(sp)
    80003292:	6442                	ld	s0,16(sp)
    80003294:	64a2                	ld	s1,8(sp)
    80003296:	6902                	ld	s2,0(sp)
    80003298:	6105                	addi	sp,sp,32
    8000329a:	8082                	ret
    panic("freeing free block");
    8000329c:	00005517          	auipc	a0,0x5
    800032a0:	2a450513          	addi	a0,a0,676 # 80008540 <syscalls+0xf8>
    800032a4:	ffffd097          	auipc	ra,0xffffd
    800032a8:	354080e7          	jalr	852(ra) # 800005f8 <panic>

00000000800032ac <balloc>:
{
    800032ac:	711d                	addi	sp,sp,-96
    800032ae:	ec86                	sd	ra,88(sp)
    800032b0:	e8a2                	sd	s0,80(sp)
    800032b2:	e4a6                	sd	s1,72(sp)
    800032b4:	e0ca                	sd	s2,64(sp)
    800032b6:	fc4e                	sd	s3,56(sp)
    800032b8:	f852                	sd	s4,48(sp)
    800032ba:	f456                	sd	s5,40(sp)
    800032bc:	f05a                	sd	s6,32(sp)
    800032be:	ec5e                	sd	s7,24(sp)
    800032c0:	e862                	sd	s8,16(sp)
    800032c2:	e466                	sd	s9,8(sp)
    800032c4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032c6:	00022797          	auipc	a5,0x22
    800032ca:	97e7a783          	lw	a5,-1666(a5) # 80024c44 <sb+0x4>
    800032ce:	cbd1                	beqz	a5,80003362 <balloc+0xb6>
    800032d0:	8baa                	mv	s7,a0
    800032d2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032d4:	00022b17          	auipc	s6,0x22
    800032d8:	96cb0b13          	addi	s6,s6,-1684 # 80024c40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032dc:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032de:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032e0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032e2:	6c89                	lui	s9,0x2
    800032e4:	a831                	j	80003300 <balloc+0x54>
    brelse(bp);
    800032e6:	854a                	mv	a0,s2
    800032e8:	00000097          	auipc	ra,0x0
    800032ec:	e32080e7          	jalr	-462(ra) # 8000311a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032f0:	015c87bb          	addw	a5,s9,s5
    800032f4:	00078a9b          	sext.w	s5,a5
    800032f8:	004b2703          	lw	a4,4(s6)
    800032fc:	06eaf363          	bgeu	s5,a4,80003362 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003300:	41fad79b          	sraiw	a5,s5,0x1f
    80003304:	0137d79b          	srliw	a5,a5,0x13
    80003308:	015787bb          	addw	a5,a5,s5
    8000330c:	40d7d79b          	sraiw	a5,a5,0xd
    80003310:	01cb2583          	lw	a1,28(s6)
    80003314:	9dbd                	addw	a1,a1,a5
    80003316:	855e                	mv	a0,s7
    80003318:	00000097          	auipc	ra,0x0
    8000331c:	cd2080e7          	jalr	-814(ra) # 80002fea <bread>
    80003320:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003322:	004b2503          	lw	a0,4(s6)
    80003326:	000a849b          	sext.w	s1,s5
    8000332a:	8662                	mv	a2,s8
    8000332c:	faa4fde3          	bgeu	s1,a0,800032e6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003330:	41f6579b          	sraiw	a5,a2,0x1f
    80003334:	01d7d69b          	srliw	a3,a5,0x1d
    80003338:	00c6873b          	addw	a4,a3,a2
    8000333c:	00777793          	andi	a5,a4,7
    80003340:	9f95                	subw	a5,a5,a3
    80003342:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003346:	4037571b          	sraiw	a4,a4,0x3
    8000334a:	00e906b3          	add	a3,s2,a4
    8000334e:	0586c683          	lbu	a3,88(a3)
    80003352:	00d7f5b3          	and	a1,a5,a3
    80003356:	cd91                	beqz	a1,80003372 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003358:	2605                	addiw	a2,a2,1
    8000335a:	2485                	addiw	s1,s1,1
    8000335c:	fd4618e3          	bne	a2,s4,8000332c <balloc+0x80>
    80003360:	b759                	j	800032e6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003362:	00005517          	auipc	a0,0x5
    80003366:	1f650513          	addi	a0,a0,502 # 80008558 <syscalls+0x110>
    8000336a:	ffffd097          	auipc	ra,0xffffd
    8000336e:	28e080e7          	jalr	654(ra) # 800005f8 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003372:	974a                	add	a4,a4,s2
    80003374:	8fd5                	or	a5,a5,a3
    80003376:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000337a:	854a                	mv	a0,s2
    8000337c:	00001097          	auipc	ra,0x1
    80003380:	002080e7          	jalr	2(ra) # 8000437e <log_write>
        brelse(bp);
    80003384:	854a                	mv	a0,s2
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	d94080e7          	jalr	-620(ra) # 8000311a <brelse>
  bp = bread(dev, bno);
    8000338e:	85a6                	mv	a1,s1
    80003390:	855e                	mv	a0,s7
    80003392:	00000097          	auipc	ra,0x0
    80003396:	c58080e7          	jalr	-936(ra) # 80002fea <bread>
    8000339a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000339c:	40000613          	li	a2,1024
    800033a0:	4581                	li	a1,0
    800033a2:	05850513          	addi	a0,a0,88
    800033a6:	ffffe097          	auipc	ra,0xffffe
    800033aa:	9ec080e7          	jalr	-1556(ra) # 80000d92 <memset>
  log_write(bp);
    800033ae:	854a                	mv	a0,s2
    800033b0:	00001097          	auipc	ra,0x1
    800033b4:	fce080e7          	jalr	-50(ra) # 8000437e <log_write>
  brelse(bp);
    800033b8:	854a                	mv	a0,s2
    800033ba:	00000097          	auipc	ra,0x0
    800033be:	d60080e7          	jalr	-672(ra) # 8000311a <brelse>
}
    800033c2:	8526                	mv	a0,s1
    800033c4:	60e6                	ld	ra,88(sp)
    800033c6:	6446                	ld	s0,80(sp)
    800033c8:	64a6                	ld	s1,72(sp)
    800033ca:	6906                	ld	s2,64(sp)
    800033cc:	79e2                	ld	s3,56(sp)
    800033ce:	7a42                	ld	s4,48(sp)
    800033d0:	7aa2                	ld	s5,40(sp)
    800033d2:	7b02                	ld	s6,32(sp)
    800033d4:	6be2                	ld	s7,24(sp)
    800033d6:	6c42                	ld	s8,16(sp)
    800033d8:	6ca2                	ld	s9,8(sp)
    800033da:	6125                	addi	sp,sp,96
    800033dc:	8082                	ret

00000000800033de <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033de:	7179                	addi	sp,sp,-48
    800033e0:	f406                	sd	ra,40(sp)
    800033e2:	f022                	sd	s0,32(sp)
    800033e4:	ec26                	sd	s1,24(sp)
    800033e6:	e84a                	sd	s2,16(sp)
    800033e8:	e44e                	sd	s3,8(sp)
    800033ea:	e052                	sd	s4,0(sp)
    800033ec:	1800                	addi	s0,sp,48
    800033ee:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033f0:	47ad                	li	a5,11
    800033f2:	04b7fe63          	bgeu	a5,a1,8000344e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033f6:	ff45849b          	addiw	s1,a1,-12
    800033fa:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033fe:	0ff00793          	li	a5,255
    80003402:	0ae7e363          	bltu	a5,a4,800034a8 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003406:	08052583          	lw	a1,128(a0)
    8000340a:	c5ad                	beqz	a1,80003474 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000340c:	00092503          	lw	a0,0(s2)
    80003410:	00000097          	auipc	ra,0x0
    80003414:	bda080e7          	jalr	-1062(ra) # 80002fea <bread>
    80003418:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000341a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000341e:	02049593          	slli	a1,s1,0x20
    80003422:	9181                	srli	a1,a1,0x20
    80003424:	058a                	slli	a1,a1,0x2
    80003426:	00b784b3          	add	s1,a5,a1
    8000342a:	0004a983          	lw	s3,0(s1)
    8000342e:	04098d63          	beqz	s3,80003488 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003432:	8552                	mv	a0,s4
    80003434:	00000097          	auipc	ra,0x0
    80003438:	ce6080e7          	jalr	-794(ra) # 8000311a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000343c:	854e                	mv	a0,s3
    8000343e:	70a2                	ld	ra,40(sp)
    80003440:	7402                	ld	s0,32(sp)
    80003442:	64e2                	ld	s1,24(sp)
    80003444:	6942                	ld	s2,16(sp)
    80003446:	69a2                	ld	s3,8(sp)
    80003448:	6a02                	ld	s4,0(sp)
    8000344a:	6145                	addi	sp,sp,48
    8000344c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000344e:	02059493          	slli	s1,a1,0x20
    80003452:	9081                	srli	s1,s1,0x20
    80003454:	048a                	slli	s1,s1,0x2
    80003456:	94aa                	add	s1,s1,a0
    80003458:	0504a983          	lw	s3,80(s1)
    8000345c:	fe0990e3          	bnez	s3,8000343c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003460:	4108                	lw	a0,0(a0)
    80003462:	00000097          	auipc	ra,0x0
    80003466:	e4a080e7          	jalr	-438(ra) # 800032ac <balloc>
    8000346a:	0005099b          	sext.w	s3,a0
    8000346e:	0534a823          	sw	s3,80(s1)
    80003472:	b7e9                	j	8000343c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003474:	4108                	lw	a0,0(a0)
    80003476:	00000097          	auipc	ra,0x0
    8000347a:	e36080e7          	jalr	-458(ra) # 800032ac <balloc>
    8000347e:	0005059b          	sext.w	a1,a0
    80003482:	08b92023          	sw	a1,128(s2)
    80003486:	b759                	j	8000340c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003488:	00092503          	lw	a0,0(s2)
    8000348c:	00000097          	auipc	ra,0x0
    80003490:	e20080e7          	jalr	-480(ra) # 800032ac <balloc>
    80003494:	0005099b          	sext.w	s3,a0
    80003498:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000349c:	8552                	mv	a0,s4
    8000349e:	00001097          	auipc	ra,0x1
    800034a2:	ee0080e7          	jalr	-288(ra) # 8000437e <log_write>
    800034a6:	b771                	j	80003432 <bmap+0x54>
  panic("bmap: out of range");
    800034a8:	00005517          	auipc	a0,0x5
    800034ac:	0c850513          	addi	a0,a0,200 # 80008570 <syscalls+0x128>
    800034b0:	ffffd097          	auipc	ra,0xffffd
    800034b4:	148080e7          	jalr	328(ra) # 800005f8 <panic>

00000000800034b8 <iget>:
{
    800034b8:	7179                	addi	sp,sp,-48
    800034ba:	f406                	sd	ra,40(sp)
    800034bc:	f022                	sd	s0,32(sp)
    800034be:	ec26                	sd	s1,24(sp)
    800034c0:	e84a                	sd	s2,16(sp)
    800034c2:	e44e                	sd	s3,8(sp)
    800034c4:	e052                	sd	s4,0(sp)
    800034c6:	1800                	addi	s0,sp,48
    800034c8:	89aa                	mv	s3,a0
    800034ca:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800034cc:	00021517          	auipc	a0,0x21
    800034d0:	79450513          	addi	a0,a0,1940 # 80024c60 <icache>
    800034d4:	ffffd097          	auipc	ra,0xffffd
    800034d8:	7c2080e7          	jalr	1986(ra) # 80000c96 <acquire>
  empty = 0;
    800034dc:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034de:	00021497          	auipc	s1,0x21
    800034e2:	79a48493          	addi	s1,s1,1946 # 80024c78 <icache+0x18>
    800034e6:	00023697          	auipc	a3,0x23
    800034ea:	22268693          	addi	a3,a3,546 # 80026708 <log>
    800034ee:	a039                	j	800034fc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034f0:	02090b63          	beqz	s2,80003526 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034f4:	08848493          	addi	s1,s1,136
    800034f8:	02d48a63          	beq	s1,a3,8000352c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034fc:	449c                	lw	a5,8(s1)
    800034fe:	fef059e3          	blez	a5,800034f0 <iget+0x38>
    80003502:	4098                	lw	a4,0(s1)
    80003504:	ff3716e3          	bne	a4,s3,800034f0 <iget+0x38>
    80003508:	40d8                	lw	a4,4(s1)
    8000350a:	ff4713e3          	bne	a4,s4,800034f0 <iget+0x38>
      ip->ref++;
    8000350e:	2785                	addiw	a5,a5,1
    80003510:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003512:	00021517          	auipc	a0,0x21
    80003516:	74e50513          	addi	a0,a0,1870 # 80024c60 <icache>
    8000351a:	ffffe097          	auipc	ra,0xffffe
    8000351e:	830080e7          	jalr	-2000(ra) # 80000d4a <release>
      return ip;
    80003522:	8926                	mv	s2,s1
    80003524:	a03d                	j	80003552 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003526:	f7f9                	bnez	a5,800034f4 <iget+0x3c>
    80003528:	8926                	mv	s2,s1
    8000352a:	b7e9                	j	800034f4 <iget+0x3c>
  if(empty == 0)
    8000352c:	02090c63          	beqz	s2,80003564 <iget+0xac>
  ip->dev = dev;
    80003530:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003534:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003538:	4785                	li	a5,1
    8000353a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000353e:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003542:	00021517          	auipc	a0,0x21
    80003546:	71e50513          	addi	a0,a0,1822 # 80024c60 <icache>
    8000354a:	ffffe097          	auipc	ra,0xffffe
    8000354e:	800080e7          	jalr	-2048(ra) # 80000d4a <release>
}
    80003552:	854a                	mv	a0,s2
    80003554:	70a2                	ld	ra,40(sp)
    80003556:	7402                	ld	s0,32(sp)
    80003558:	64e2                	ld	s1,24(sp)
    8000355a:	6942                	ld	s2,16(sp)
    8000355c:	69a2                	ld	s3,8(sp)
    8000355e:	6a02                	ld	s4,0(sp)
    80003560:	6145                	addi	sp,sp,48
    80003562:	8082                	ret
    panic("iget: no inodes");
    80003564:	00005517          	auipc	a0,0x5
    80003568:	02450513          	addi	a0,a0,36 # 80008588 <syscalls+0x140>
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	08c080e7          	jalr	140(ra) # 800005f8 <panic>

0000000080003574 <fsinit>:
fsinit(int dev) {
    80003574:	7179                	addi	sp,sp,-48
    80003576:	f406                	sd	ra,40(sp)
    80003578:	f022                	sd	s0,32(sp)
    8000357a:	ec26                	sd	s1,24(sp)
    8000357c:	e84a                	sd	s2,16(sp)
    8000357e:	e44e                	sd	s3,8(sp)
    80003580:	1800                	addi	s0,sp,48
    80003582:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003584:	4585                	li	a1,1
    80003586:	00000097          	auipc	ra,0x0
    8000358a:	a64080e7          	jalr	-1436(ra) # 80002fea <bread>
    8000358e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003590:	00021997          	auipc	s3,0x21
    80003594:	6b098993          	addi	s3,s3,1712 # 80024c40 <sb>
    80003598:	02000613          	li	a2,32
    8000359c:	05850593          	addi	a1,a0,88
    800035a0:	854e                	mv	a0,s3
    800035a2:	ffffe097          	auipc	ra,0xffffe
    800035a6:	850080e7          	jalr	-1968(ra) # 80000df2 <memmove>
  brelse(bp);
    800035aa:	8526                	mv	a0,s1
    800035ac:	00000097          	auipc	ra,0x0
    800035b0:	b6e080e7          	jalr	-1170(ra) # 8000311a <brelse>
  if(sb.magic != FSMAGIC)
    800035b4:	0009a703          	lw	a4,0(s3)
    800035b8:	102037b7          	lui	a5,0x10203
    800035bc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035c0:	02f71263          	bne	a4,a5,800035e4 <fsinit+0x70>
  initlog(dev, &sb);
    800035c4:	00021597          	auipc	a1,0x21
    800035c8:	67c58593          	addi	a1,a1,1660 # 80024c40 <sb>
    800035cc:	854a                	mv	a0,s2
    800035ce:	00001097          	auipc	ra,0x1
    800035d2:	b38080e7          	jalr	-1224(ra) # 80004106 <initlog>
}
    800035d6:	70a2                	ld	ra,40(sp)
    800035d8:	7402                	ld	s0,32(sp)
    800035da:	64e2                	ld	s1,24(sp)
    800035dc:	6942                	ld	s2,16(sp)
    800035de:	69a2                	ld	s3,8(sp)
    800035e0:	6145                	addi	sp,sp,48
    800035e2:	8082                	ret
    panic("invalid file system");
    800035e4:	00005517          	auipc	a0,0x5
    800035e8:	fb450513          	addi	a0,a0,-76 # 80008598 <syscalls+0x150>
    800035ec:	ffffd097          	auipc	ra,0xffffd
    800035f0:	00c080e7          	jalr	12(ra) # 800005f8 <panic>

00000000800035f4 <iinit>:
{
    800035f4:	7179                	addi	sp,sp,-48
    800035f6:	f406                	sd	ra,40(sp)
    800035f8:	f022                	sd	s0,32(sp)
    800035fa:	ec26                	sd	s1,24(sp)
    800035fc:	e84a                	sd	s2,16(sp)
    800035fe:	e44e                	sd	s3,8(sp)
    80003600:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003602:	00005597          	auipc	a1,0x5
    80003606:	fae58593          	addi	a1,a1,-82 # 800085b0 <syscalls+0x168>
    8000360a:	00021517          	auipc	a0,0x21
    8000360e:	65650513          	addi	a0,a0,1622 # 80024c60 <icache>
    80003612:	ffffd097          	auipc	ra,0xffffd
    80003616:	5f4080e7          	jalr	1524(ra) # 80000c06 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000361a:	00021497          	auipc	s1,0x21
    8000361e:	66e48493          	addi	s1,s1,1646 # 80024c88 <icache+0x28>
    80003622:	00023997          	auipc	s3,0x23
    80003626:	0f698993          	addi	s3,s3,246 # 80026718 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000362a:	00005917          	auipc	s2,0x5
    8000362e:	f8e90913          	addi	s2,s2,-114 # 800085b8 <syscalls+0x170>
    80003632:	85ca                	mv	a1,s2
    80003634:	8526                	mv	a0,s1
    80003636:	00001097          	auipc	ra,0x1
    8000363a:	e36080e7          	jalr	-458(ra) # 8000446c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000363e:	08848493          	addi	s1,s1,136
    80003642:	ff3498e3          	bne	s1,s3,80003632 <iinit+0x3e>
}
    80003646:	70a2                	ld	ra,40(sp)
    80003648:	7402                	ld	s0,32(sp)
    8000364a:	64e2                	ld	s1,24(sp)
    8000364c:	6942                	ld	s2,16(sp)
    8000364e:	69a2                	ld	s3,8(sp)
    80003650:	6145                	addi	sp,sp,48
    80003652:	8082                	ret

0000000080003654 <ialloc>:
{
    80003654:	715d                	addi	sp,sp,-80
    80003656:	e486                	sd	ra,72(sp)
    80003658:	e0a2                	sd	s0,64(sp)
    8000365a:	fc26                	sd	s1,56(sp)
    8000365c:	f84a                	sd	s2,48(sp)
    8000365e:	f44e                	sd	s3,40(sp)
    80003660:	f052                	sd	s4,32(sp)
    80003662:	ec56                	sd	s5,24(sp)
    80003664:	e85a                	sd	s6,16(sp)
    80003666:	e45e                	sd	s7,8(sp)
    80003668:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000366a:	00021717          	auipc	a4,0x21
    8000366e:	5e272703          	lw	a4,1506(a4) # 80024c4c <sb+0xc>
    80003672:	4785                	li	a5,1
    80003674:	04e7fa63          	bgeu	a5,a4,800036c8 <ialloc+0x74>
    80003678:	8aaa                	mv	s5,a0
    8000367a:	8bae                	mv	s7,a1
    8000367c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000367e:	00021a17          	auipc	s4,0x21
    80003682:	5c2a0a13          	addi	s4,s4,1474 # 80024c40 <sb>
    80003686:	00048b1b          	sext.w	s6,s1
    8000368a:	0044d593          	srli	a1,s1,0x4
    8000368e:	018a2783          	lw	a5,24(s4)
    80003692:	9dbd                	addw	a1,a1,a5
    80003694:	8556                	mv	a0,s5
    80003696:	00000097          	auipc	ra,0x0
    8000369a:	954080e7          	jalr	-1708(ra) # 80002fea <bread>
    8000369e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036a0:	05850993          	addi	s3,a0,88
    800036a4:	00f4f793          	andi	a5,s1,15
    800036a8:	079a                	slli	a5,a5,0x6
    800036aa:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036ac:	00099783          	lh	a5,0(s3)
    800036b0:	c785                	beqz	a5,800036d8 <ialloc+0x84>
    brelse(bp);
    800036b2:	00000097          	auipc	ra,0x0
    800036b6:	a68080e7          	jalr	-1432(ra) # 8000311a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036ba:	0485                	addi	s1,s1,1
    800036bc:	00ca2703          	lw	a4,12(s4)
    800036c0:	0004879b          	sext.w	a5,s1
    800036c4:	fce7e1e3          	bltu	a5,a4,80003686 <ialloc+0x32>
  panic("ialloc: no inodes");
    800036c8:	00005517          	auipc	a0,0x5
    800036cc:	ef850513          	addi	a0,a0,-264 # 800085c0 <syscalls+0x178>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	f28080e7          	jalr	-216(ra) # 800005f8 <panic>
      memset(dip, 0, sizeof(*dip));
    800036d8:	04000613          	li	a2,64
    800036dc:	4581                	li	a1,0
    800036de:	854e                	mv	a0,s3
    800036e0:	ffffd097          	auipc	ra,0xffffd
    800036e4:	6b2080e7          	jalr	1714(ra) # 80000d92 <memset>
      dip->type = type;
    800036e8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036ec:	854a                	mv	a0,s2
    800036ee:	00001097          	auipc	ra,0x1
    800036f2:	c90080e7          	jalr	-880(ra) # 8000437e <log_write>
      brelse(bp);
    800036f6:	854a                	mv	a0,s2
    800036f8:	00000097          	auipc	ra,0x0
    800036fc:	a22080e7          	jalr	-1502(ra) # 8000311a <brelse>
      return iget(dev, inum);
    80003700:	85da                	mv	a1,s6
    80003702:	8556                	mv	a0,s5
    80003704:	00000097          	auipc	ra,0x0
    80003708:	db4080e7          	jalr	-588(ra) # 800034b8 <iget>
}
    8000370c:	60a6                	ld	ra,72(sp)
    8000370e:	6406                	ld	s0,64(sp)
    80003710:	74e2                	ld	s1,56(sp)
    80003712:	7942                	ld	s2,48(sp)
    80003714:	79a2                	ld	s3,40(sp)
    80003716:	7a02                	ld	s4,32(sp)
    80003718:	6ae2                	ld	s5,24(sp)
    8000371a:	6b42                	ld	s6,16(sp)
    8000371c:	6ba2                	ld	s7,8(sp)
    8000371e:	6161                	addi	sp,sp,80
    80003720:	8082                	ret

0000000080003722 <iupdate>:
{
    80003722:	1101                	addi	sp,sp,-32
    80003724:	ec06                	sd	ra,24(sp)
    80003726:	e822                	sd	s0,16(sp)
    80003728:	e426                	sd	s1,8(sp)
    8000372a:	e04a                	sd	s2,0(sp)
    8000372c:	1000                	addi	s0,sp,32
    8000372e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003730:	415c                	lw	a5,4(a0)
    80003732:	0047d79b          	srliw	a5,a5,0x4
    80003736:	00021597          	auipc	a1,0x21
    8000373a:	5225a583          	lw	a1,1314(a1) # 80024c58 <sb+0x18>
    8000373e:	9dbd                	addw	a1,a1,a5
    80003740:	4108                	lw	a0,0(a0)
    80003742:	00000097          	auipc	ra,0x0
    80003746:	8a8080e7          	jalr	-1880(ra) # 80002fea <bread>
    8000374a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000374c:	05850793          	addi	a5,a0,88
    80003750:	40c8                	lw	a0,4(s1)
    80003752:	893d                	andi	a0,a0,15
    80003754:	051a                	slli	a0,a0,0x6
    80003756:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003758:	04449703          	lh	a4,68(s1)
    8000375c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003760:	04649703          	lh	a4,70(s1)
    80003764:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003768:	04849703          	lh	a4,72(s1)
    8000376c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003770:	04a49703          	lh	a4,74(s1)
    80003774:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003778:	44f8                	lw	a4,76(s1)
    8000377a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000377c:	03400613          	li	a2,52
    80003780:	05048593          	addi	a1,s1,80
    80003784:	0531                	addi	a0,a0,12
    80003786:	ffffd097          	auipc	ra,0xffffd
    8000378a:	66c080e7          	jalr	1644(ra) # 80000df2 <memmove>
  log_write(bp);
    8000378e:	854a                	mv	a0,s2
    80003790:	00001097          	auipc	ra,0x1
    80003794:	bee080e7          	jalr	-1042(ra) # 8000437e <log_write>
  brelse(bp);
    80003798:	854a                	mv	a0,s2
    8000379a:	00000097          	auipc	ra,0x0
    8000379e:	980080e7          	jalr	-1664(ra) # 8000311a <brelse>
}
    800037a2:	60e2                	ld	ra,24(sp)
    800037a4:	6442                	ld	s0,16(sp)
    800037a6:	64a2                	ld	s1,8(sp)
    800037a8:	6902                	ld	s2,0(sp)
    800037aa:	6105                	addi	sp,sp,32
    800037ac:	8082                	ret

00000000800037ae <idup>:
{
    800037ae:	1101                	addi	sp,sp,-32
    800037b0:	ec06                	sd	ra,24(sp)
    800037b2:	e822                	sd	s0,16(sp)
    800037b4:	e426                	sd	s1,8(sp)
    800037b6:	1000                	addi	s0,sp,32
    800037b8:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800037ba:	00021517          	auipc	a0,0x21
    800037be:	4a650513          	addi	a0,a0,1190 # 80024c60 <icache>
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	4d4080e7          	jalr	1236(ra) # 80000c96 <acquire>
  ip->ref++;
    800037ca:	449c                	lw	a5,8(s1)
    800037cc:	2785                	addiw	a5,a5,1
    800037ce:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800037d0:	00021517          	auipc	a0,0x21
    800037d4:	49050513          	addi	a0,a0,1168 # 80024c60 <icache>
    800037d8:	ffffd097          	auipc	ra,0xffffd
    800037dc:	572080e7          	jalr	1394(ra) # 80000d4a <release>
}
    800037e0:	8526                	mv	a0,s1
    800037e2:	60e2                	ld	ra,24(sp)
    800037e4:	6442                	ld	s0,16(sp)
    800037e6:	64a2                	ld	s1,8(sp)
    800037e8:	6105                	addi	sp,sp,32
    800037ea:	8082                	ret

00000000800037ec <ilock>:
{
    800037ec:	1101                	addi	sp,sp,-32
    800037ee:	ec06                	sd	ra,24(sp)
    800037f0:	e822                	sd	s0,16(sp)
    800037f2:	e426                	sd	s1,8(sp)
    800037f4:	e04a                	sd	s2,0(sp)
    800037f6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037f8:	c115                	beqz	a0,8000381c <ilock+0x30>
    800037fa:	84aa                	mv	s1,a0
    800037fc:	451c                	lw	a5,8(a0)
    800037fe:	00f05f63          	blez	a5,8000381c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003802:	0541                	addi	a0,a0,16
    80003804:	00001097          	auipc	ra,0x1
    80003808:	ca2080e7          	jalr	-862(ra) # 800044a6 <acquiresleep>
  if(ip->valid == 0){
    8000380c:	40bc                	lw	a5,64(s1)
    8000380e:	cf99                	beqz	a5,8000382c <ilock+0x40>
}
    80003810:	60e2                	ld	ra,24(sp)
    80003812:	6442                	ld	s0,16(sp)
    80003814:	64a2                	ld	s1,8(sp)
    80003816:	6902                	ld	s2,0(sp)
    80003818:	6105                	addi	sp,sp,32
    8000381a:	8082                	ret
    panic("ilock");
    8000381c:	00005517          	auipc	a0,0x5
    80003820:	dbc50513          	addi	a0,a0,-580 # 800085d8 <syscalls+0x190>
    80003824:	ffffd097          	auipc	ra,0xffffd
    80003828:	dd4080e7          	jalr	-556(ra) # 800005f8 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000382c:	40dc                	lw	a5,4(s1)
    8000382e:	0047d79b          	srliw	a5,a5,0x4
    80003832:	00021597          	auipc	a1,0x21
    80003836:	4265a583          	lw	a1,1062(a1) # 80024c58 <sb+0x18>
    8000383a:	9dbd                	addw	a1,a1,a5
    8000383c:	4088                	lw	a0,0(s1)
    8000383e:	fffff097          	auipc	ra,0xfffff
    80003842:	7ac080e7          	jalr	1964(ra) # 80002fea <bread>
    80003846:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003848:	05850593          	addi	a1,a0,88
    8000384c:	40dc                	lw	a5,4(s1)
    8000384e:	8bbd                	andi	a5,a5,15
    80003850:	079a                	slli	a5,a5,0x6
    80003852:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003854:	00059783          	lh	a5,0(a1)
    80003858:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000385c:	00259783          	lh	a5,2(a1)
    80003860:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003864:	00459783          	lh	a5,4(a1)
    80003868:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000386c:	00659783          	lh	a5,6(a1)
    80003870:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003874:	459c                	lw	a5,8(a1)
    80003876:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003878:	03400613          	li	a2,52
    8000387c:	05b1                	addi	a1,a1,12
    8000387e:	05048513          	addi	a0,s1,80
    80003882:	ffffd097          	auipc	ra,0xffffd
    80003886:	570080e7          	jalr	1392(ra) # 80000df2 <memmove>
    brelse(bp);
    8000388a:	854a                	mv	a0,s2
    8000388c:	00000097          	auipc	ra,0x0
    80003890:	88e080e7          	jalr	-1906(ra) # 8000311a <brelse>
    ip->valid = 1;
    80003894:	4785                	li	a5,1
    80003896:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003898:	04449783          	lh	a5,68(s1)
    8000389c:	fbb5                	bnez	a5,80003810 <ilock+0x24>
      panic("ilock: no type");
    8000389e:	00005517          	auipc	a0,0x5
    800038a2:	d4250513          	addi	a0,a0,-702 # 800085e0 <syscalls+0x198>
    800038a6:	ffffd097          	auipc	ra,0xffffd
    800038aa:	d52080e7          	jalr	-686(ra) # 800005f8 <panic>

00000000800038ae <iunlock>:
{
    800038ae:	1101                	addi	sp,sp,-32
    800038b0:	ec06                	sd	ra,24(sp)
    800038b2:	e822                	sd	s0,16(sp)
    800038b4:	e426                	sd	s1,8(sp)
    800038b6:	e04a                	sd	s2,0(sp)
    800038b8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038ba:	c905                	beqz	a0,800038ea <iunlock+0x3c>
    800038bc:	84aa                	mv	s1,a0
    800038be:	01050913          	addi	s2,a0,16
    800038c2:	854a                	mv	a0,s2
    800038c4:	00001097          	auipc	ra,0x1
    800038c8:	c7c080e7          	jalr	-900(ra) # 80004540 <holdingsleep>
    800038cc:	cd19                	beqz	a0,800038ea <iunlock+0x3c>
    800038ce:	449c                	lw	a5,8(s1)
    800038d0:	00f05d63          	blez	a5,800038ea <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038d4:	854a                	mv	a0,s2
    800038d6:	00001097          	auipc	ra,0x1
    800038da:	c26080e7          	jalr	-986(ra) # 800044fc <releasesleep>
}
    800038de:	60e2                	ld	ra,24(sp)
    800038e0:	6442                	ld	s0,16(sp)
    800038e2:	64a2                	ld	s1,8(sp)
    800038e4:	6902                	ld	s2,0(sp)
    800038e6:	6105                	addi	sp,sp,32
    800038e8:	8082                	ret
    panic("iunlock");
    800038ea:	00005517          	auipc	a0,0x5
    800038ee:	d0650513          	addi	a0,a0,-762 # 800085f0 <syscalls+0x1a8>
    800038f2:	ffffd097          	auipc	ra,0xffffd
    800038f6:	d06080e7          	jalr	-762(ra) # 800005f8 <panic>

00000000800038fa <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038fa:	7179                	addi	sp,sp,-48
    800038fc:	f406                	sd	ra,40(sp)
    800038fe:	f022                	sd	s0,32(sp)
    80003900:	ec26                	sd	s1,24(sp)
    80003902:	e84a                	sd	s2,16(sp)
    80003904:	e44e                	sd	s3,8(sp)
    80003906:	e052                	sd	s4,0(sp)
    80003908:	1800                	addi	s0,sp,48
    8000390a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000390c:	05050493          	addi	s1,a0,80
    80003910:	08050913          	addi	s2,a0,128
    80003914:	a021                	j	8000391c <itrunc+0x22>
    80003916:	0491                	addi	s1,s1,4
    80003918:	01248d63          	beq	s1,s2,80003932 <itrunc+0x38>
    if(ip->addrs[i]){
    8000391c:	408c                	lw	a1,0(s1)
    8000391e:	dde5                	beqz	a1,80003916 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003920:	0009a503          	lw	a0,0(s3)
    80003924:	00000097          	auipc	ra,0x0
    80003928:	90c080e7          	jalr	-1780(ra) # 80003230 <bfree>
      ip->addrs[i] = 0;
    8000392c:	0004a023          	sw	zero,0(s1)
    80003930:	b7dd                	j	80003916 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003932:	0809a583          	lw	a1,128(s3)
    80003936:	e185                	bnez	a1,80003956 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003938:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000393c:	854e                	mv	a0,s3
    8000393e:	00000097          	auipc	ra,0x0
    80003942:	de4080e7          	jalr	-540(ra) # 80003722 <iupdate>
}
    80003946:	70a2                	ld	ra,40(sp)
    80003948:	7402                	ld	s0,32(sp)
    8000394a:	64e2                	ld	s1,24(sp)
    8000394c:	6942                	ld	s2,16(sp)
    8000394e:	69a2                	ld	s3,8(sp)
    80003950:	6a02                	ld	s4,0(sp)
    80003952:	6145                	addi	sp,sp,48
    80003954:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003956:	0009a503          	lw	a0,0(s3)
    8000395a:	fffff097          	auipc	ra,0xfffff
    8000395e:	690080e7          	jalr	1680(ra) # 80002fea <bread>
    80003962:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003964:	05850493          	addi	s1,a0,88
    80003968:	45850913          	addi	s2,a0,1112
    8000396c:	a811                	j	80003980 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000396e:	0009a503          	lw	a0,0(s3)
    80003972:	00000097          	auipc	ra,0x0
    80003976:	8be080e7          	jalr	-1858(ra) # 80003230 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000397a:	0491                	addi	s1,s1,4
    8000397c:	01248563          	beq	s1,s2,80003986 <itrunc+0x8c>
      if(a[j])
    80003980:	408c                	lw	a1,0(s1)
    80003982:	dde5                	beqz	a1,8000397a <itrunc+0x80>
    80003984:	b7ed                	j	8000396e <itrunc+0x74>
    brelse(bp);
    80003986:	8552                	mv	a0,s4
    80003988:	fffff097          	auipc	ra,0xfffff
    8000398c:	792080e7          	jalr	1938(ra) # 8000311a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003990:	0809a583          	lw	a1,128(s3)
    80003994:	0009a503          	lw	a0,0(s3)
    80003998:	00000097          	auipc	ra,0x0
    8000399c:	898080e7          	jalr	-1896(ra) # 80003230 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039a0:	0809a023          	sw	zero,128(s3)
    800039a4:	bf51                	j	80003938 <itrunc+0x3e>

00000000800039a6 <iput>:
{
    800039a6:	1101                	addi	sp,sp,-32
    800039a8:	ec06                	sd	ra,24(sp)
    800039aa:	e822                	sd	s0,16(sp)
    800039ac:	e426                	sd	s1,8(sp)
    800039ae:	e04a                	sd	s2,0(sp)
    800039b0:	1000                	addi	s0,sp,32
    800039b2:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800039b4:	00021517          	auipc	a0,0x21
    800039b8:	2ac50513          	addi	a0,a0,684 # 80024c60 <icache>
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	2da080e7          	jalr	730(ra) # 80000c96 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039c4:	4498                	lw	a4,8(s1)
    800039c6:	4785                	li	a5,1
    800039c8:	02f70363          	beq	a4,a5,800039ee <iput+0x48>
  ip->ref--;
    800039cc:	449c                	lw	a5,8(s1)
    800039ce:	37fd                	addiw	a5,a5,-1
    800039d0:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800039d2:	00021517          	auipc	a0,0x21
    800039d6:	28e50513          	addi	a0,a0,654 # 80024c60 <icache>
    800039da:	ffffd097          	auipc	ra,0xffffd
    800039de:	370080e7          	jalr	880(ra) # 80000d4a <release>
}
    800039e2:	60e2                	ld	ra,24(sp)
    800039e4:	6442                	ld	s0,16(sp)
    800039e6:	64a2                	ld	s1,8(sp)
    800039e8:	6902                	ld	s2,0(sp)
    800039ea:	6105                	addi	sp,sp,32
    800039ec:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039ee:	40bc                	lw	a5,64(s1)
    800039f0:	dff1                	beqz	a5,800039cc <iput+0x26>
    800039f2:	04a49783          	lh	a5,74(s1)
    800039f6:	fbf9                	bnez	a5,800039cc <iput+0x26>
    acquiresleep(&ip->lock);
    800039f8:	01048913          	addi	s2,s1,16
    800039fc:	854a                	mv	a0,s2
    800039fe:	00001097          	auipc	ra,0x1
    80003a02:	aa8080e7          	jalr	-1368(ra) # 800044a6 <acquiresleep>
    release(&icache.lock);
    80003a06:	00021517          	auipc	a0,0x21
    80003a0a:	25a50513          	addi	a0,a0,602 # 80024c60 <icache>
    80003a0e:	ffffd097          	auipc	ra,0xffffd
    80003a12:	33c080e7          	jalr	828(ra) # 80000d4a <release>
    itrunc(ip);
    80003a16:	8526                	mv	a0,s1
    80003a18:	00000097          	auipc	ra,0x0
    80003a1c:	ee2080e7          	jalr	-286(ra) # 800038fa <itrunc>
    ip->type = 0;
    80003a20:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a24:	8526                	mv	a0,s1
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	cfc080e7          	jalr	-772(ra) # 80003722 <iupdate>
    ip->valid = 0;
    80003a2e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a32:	854a                	mv	a0,s2
    80003a34:	00001097          	auipc	ra,0x1
    80003a38:	ac8080e7          	jalr	-1336(ra) # 800044fc <releasesleep>
    acquire(&icache.lock);
    80003a3c:	00021517          	auipc	a0,0x21
    80003a40:	22450513          	addi	a0,a0,548 # 80024c60 <icache>
    80003a44:	ffffd097          	auipc	ra,0xffffd
    80003a48:	252080e7          	jalr	594(ra) # 80000c96 <acquire>
    80003a4c:	b741                	j	800039cc <iput+0x26>

0000000080003a4e <iunlockput>:
{
    80003a4e:	1101                	addi	sp,sp,-32
    80003a50:	ec06                	sd	ra,24(sp)
    80003a52:	e822                	sd	s0,16(sp)
    80003a54:	e426                	sd	s1,8(sp)
    80003a56:	1000                	addi	s0,sp,32
    80003a58:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a5a:	00000097          	auipc	ra,0x0
    80003a5e:	e54080e7          	jalr	-428(ra) # 800038ae <iunlock>
  iput(ip);
    80003a62:	8526                	mv	a0,s1
    80003a64:	00000097          	auipc	ra,0x0
    80003a68:	f42080e7          	jalr	-190(ra) # 800039a6 <iput>
}
    80003a6c:	60e2                	ld	ra,24(sp)
    80003a6e:	6442                	ld	s0,16(sp)
    80003a70:	64a2                	ld	s1,8(sp)
    80003a72:	6105                	addi	sp,sp,32
    80003a74:	8082                	ret

0000000080003a76 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a76:	1141                	addi	sp,sp,-16
    80003a78:	e422                	sd	s0,8(sp)
    80003a7a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a7c:	411c                	lw	a5,0(a0)
    80003a7e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a80:	415c                	lw	a5,4(a0)
    80003a82:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a84:	04451783          	lh	a5,68(a0)
    80003a88:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a8c:	04a51783          	lh	a5,74(a0)
    80003a90:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a94:	04c56783          	lwu	a5,76(a0)
    80003a98:	e99c                	sd	a5,16(a1)
}
    80003a9a:	6422                	ld	s0,8(sp)
    80003a9c:	0141                	addi	sp,sp,16
    80003a9e:	8082                	ret

0000000080003aa0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003aa0:	457c                	lw	a5,76(a0)
    80003aa2:	0ed7e863          	bltu	a5,a3,80003b92 <readi+0xf2>
{
    80003aa6:	7159                	addi	sp,sp,-112
    80003aa8:	f486                	sd	ra,104(sp)
    80003aaa:	f0a2                	sd	s0,96(sp)
    80003aac:	eca6                	sd	s1,88(sp)
    80003aae:	e8ca                	sd	s2,80(sp)
    80003ab0:	e4ce                	sd	s3,72(sp)
    80003ab2:	e0d2                	sd	s4,64(sp)
    80003ab4:	fc56                	sd	s5,56(sp)
    80003ab6:	f85a                	sd	s6,48(sp)
    80003ab8:	f45e                	sd	s7,40(sp)
    80003aba:	f062                	sd	s8,32(sp)
    80003abc:	ec66                	sd	s9,24(sp)
    80003abe:	e86a                	sd	s10,16(sp)
    80003ac0:	e46e                	sd	s11,8(sp)
    80003ac2:	1880                	addi	s0,sp,112
    80003ac4:	8baa                	mv	s7,a0
    80003ac6:	8c2e                	mv	s8,a1
    80003ac8:	8ab2                	mv	s5,a2
    80003aca:	84b6                	mv	s1,a3
    80003acc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ace:	9f35                	addw	a4,a4,a3
    return 0;
    80003ad0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ad2:	08d76f63          	bltu	a4,a3,80003b70 <readi+0xd0>
  if(off + n > ip->size)
    80003ad6:	00e7f463          	bgeu	a5,a4,80003ade <readi+0x3e>
    n = ip->size - off;
    80003ada:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ade:	0a0b0863          	beqz	s6,80003b8e <readi+0xee>
    80003ae2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ae4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ae8:	5cfd                	li	s9,-1
    80003aea:	a82d                	j	80003b24 <readi+0x84>
    80003aec:	020a1d93          	slli	s11,s4,0x20
    80003af0:	020ddd93          	srli	s11,s11,0x20
    80003af4:	05890613          	addi	a2,s2,88
    80003af8:	86ee                	mv	a3,s11
    80003afa:	963a                	add	a2,a2,a4
    80003afc:	85d6                	mv	a1,s5
    80003afe:	8562                	mv	a0,s8
    80003b00:	fffff097          	auipc	ra,0xfffff
    80003b04:	9ea080e7          	jalr	-1558(ra) # 800024ea <either_copyout>
    80003b08:	05950d63          	beq	a0,s9,80003b62 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003b0c:	854a                	mv	a0,s2
    80003b0e:	fffff097          	auipc	ra,0xfffff
    80003b12:	60c080e7          	jalr	1548(ra) # 8000311a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b16:	013a09bb          	addw	s3,s4,s3
    80003b1a:	009a04bb          	addw	s1,s4,s1
    80003b1e:	9aee                	add	s5,s5,s11
    80003b20:	0569f663          	bgeu	s3,s6,80003b6c <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b24:	000ba903          	lw	s2,0(s7)
    80003b28:	00a4d59b          	srliw	a1,s1,0xa
    80003b2c:	855e                	mv	a0,s7
    80003b2e:	00000097          	auipc	ra,0x0
    80003b32:	8b0080e7          	jalr	-1872(ra) # 800033de <bmap>
    80003b36:	0005059b          	sext.w	a1,a0
    80003b3a:	854a                	mv	a0,s2
    80003b3c:	fffff097          	auipc	ra,0xfffff
    80003b40:	4ae080e7          	jalr	1198(ra) # 80002fea <bread>
    80003b44:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b46:	3ff4f713          	andi	a4,s1,1023
    80003b4a:	40ed07bb          	subw	a5,s10,a4
    80003b4e:	413b06bb          	subw	a3,s6,s3
    80003b52:	8a3e                	mv	s4,a5
    80003b54:	2781                	sext.w	a5,a5
    80003b56:	0006861b          	sext.w	a2,a3
    80003b5a:	f8f679e3          	bgeu	a2,a5,80003aec <readi+0x4c>
    80003b5e:	8a36                	mv	s4,a3
    80003b60:	b771                	j	80003aec <readi+0x4c>
      brelse(bp);
    80003b62:	854a                	mv	a0,s2
    80003b64:	fffff097          	auipc	ra,0xfffff
    80003b68:	5b6080e7          	jalr	1462(ra) # 8000311a <brelse>
  }
  return tot;
    80003b6c:	0009851b          	sext.w	a0,s3
}
    80003b70:	70a6                	ld	ra,104(sp)
    80003b72:	7406                	ld	s0,96(sp)
    80003b74:	64e6                	ld	s1,88(sp)
    80003b76:	6946                	ld	s2,80(sp)
    80003b78:	69a6                	ld	s3,72(sp)
    80003b7a:	6a06                	ld	s4,64(sp)
    80003b7c:	7ae2                	ld	s5,56(sp)
    80003b7e:	7b42                	ld	s6,48(sp)
    80003b80:	7ba2                	ld	s7,40(sp)
    80003b82:	7c02                	ld	s8,32(sp)
    80003b84:	6ce2                	ld	s9,24(sp)
    80003b86:	6d42                	ld	s10,16(sp)
    80003b88:	6da2                	ld	s11,8(sp)
    80003b8a:	6165                	addi	sp,sp,112
    80003b8c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b8e:	89da                	mv	s3,s6
    80003b90:	bff1                	j	80003b6c <readi+0xcc>
    return 0;
    80003b92:	4501                	li	a0,0
}
    80003b94:	8082                	ret

0000000080003b96 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b96:	457c                	lw	a5,76(a0)
    80003b98:	10d7e663          	bltu	a5,a3,80003ca4 <writei+0x10e>
{
    80003b9c:	7159                	addi	sp,sp,-112
    80003b9e:	f486                	sd	ra,104(sp)
    80003ba0:	f0a2                	sd	s0,96(sp)
    80003ba2:	eca6                	sd	s1,88(sp)
    80003ba4:	e8ca                	sd	s2,80(sp)
    80003ba6:	e4ce                	sd	s3,72(sp)
    80003ba8:	e0d2                	sd	s4,64(sp)
    80003baa:	fc56                	sd	s5,56(sp)
    80003bac:	f85a                	sd	s6,48(sp)
    80003bae:	f45e                	sd	s7,40(sp)
    80003bb0:	f062                	sd	s8,32(sp)
    80003bb2:	ec66                	sd	s9,24(sp)
    80003bb4:	e86a                	sd	s10,16(sp)
    80003bb6:	e46e                	sd	s11,8(sp)
    80003bb8:	1880                	addi	s0,sp,112
    80003bba:	8baa                	mv	s7,a0
    80003bbc:	8c2e                	mv	s8,a1
    80003bbe:	8ab2                	mv	s5,a2
    80003bc0:	8936                	mv	s2,a3
    80003bc2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bc4:	00e687bb          	addw	a5,a3,a4
    80003bc8:	0ed7e063          	bltu	a5,a3,80003ca8 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bcc:	00043737          	lui	a4,0x43
    80003bd0:	0cf76e63          	bltu	a4,a5,80003cac <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bd4:	0a0b0763          	beqz	s6,80003c82 <writei+0xec>
    80003bd8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bda:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bde:	5cfd                	li	s9,-1
    80003be0:	a091                	j	80003c24 <writei+0x8e>
    80003be2:	02099d93          	slli	s11,s3,0x20
    80003be6:	020ddd93          	srli	s11,s11,0x20
    80003bea:	05848513          	addi	a0,s1,88
    80003bee:	86ee                	mv	a3,s11
    80003bf0:	8656                	mv	a2,s5
    80003bf2:	85e2                	mv	a1,s8
    80003bf4:	953a                	add	a0,a0,a4
    80003bf6:	fffff097          	auipc	ra,0xfffff
    80003bfa:	94a080e7          	jalr	-1718(ra) # 80002540 <either_copyin>
    80003bfe:	07950263          	beq	a0,s9,80003c62 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c02:	8526                	mv	a0,s1
    80003c04:	00000097          	auipc	ra,0x0
    80003c08:	77a080e7          	jalr	1914(ra) # 8000437e <log_write>
    brelse(bp);
    80003c0c:	8526                	mv	a0,s1
    80003c0e:	fffff097          	auipc	ra,0xfffff
    80003c12:	50c080e7          	jalr	1292(ra) # 8000311a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c16:	01498a3b          	addw	s4,s3,s4
    80003c1a:	0129893b          	addw	s2,s3,s2
    80003c1e:	9aee                	add	s5,s5,s11
    80003c20:	056a7663          	bgeu	s4,s6,80003c6c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c24:	000ba483          	lw	s1,0(s7)
    80003c28:	00a9559b          	srliw	a1,s2,0xa
    80003c2c:	855e                	mv	a0,s7
    80003c2e:	fffff097          	auipc	ra,0xfffff
    80003c32:	7b0080e7          	jalr	1968(ra) # 800033de <bmap>
    80003c36:	0005059b          	sext.w	a1,a0
    80003c3a:	8526                	mv	a0,s1
    80003c3c:	fffff097          	auipc	ra,0xfffff
    80003c40:	3ae080e7          	jalr	942(ra) # 80002fea <bread>
    80003c44:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c46:	3ff97713          	andi	a4,s2,1023
    80003c4a:	40ed07bb          	subw	a5,s10,a4
    80003c4e:	414b06bb          	subw	a3,s6,s4
    80003c52:	89be                	mv	s3,a5
    80003c54:	2781                	sext.w	a5,a5
    80003c56:	0006861b          	sext.w	a2,a3
    80003c5a:	f8f674e3          	bgeu	a2,a5,80003be2 <writei+0x4c>
    80003c5e:	89b6                	mv	s3,a3
    80003c60:	b749                	j	80003be2 <writei+0x4c>
      brelse(bp);
    80003c62:	8526                	mv	a0,s1
    80003c64:	fffff097          	auipc	ra,0xfffff
    80003c68:	4b6080e7          	jalr	1206(ra) # 8000311a <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003c6c:	04cba783          	lw	a5,76(s7)
    80003c70:	0127f463          	bgeu	a5,s2,80003c78 <writei+0xe2>
      ip->size = off;
    80003c74:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c78:	855e                	mv	a0,s7
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	aa8080e7          	jalr	-1368(ra) # 80003722 <iupdate>
  }

  return n;
    80003c82:	000b051b          	sext.w	a0,s6
}
    80003c86:	70a6                	ld	ra,104(sp)
    80003c88:	7406                	ld	s0,96(sp)
    80003c8a:	64e6                	ld	s1,88(sp)
    80003c8c:	6946                	ld	s2,80(sp)
    80003c8e:	69a6                	ld	s3,72(sp)
    80003c90:	6a06                	ld	s4,64(sp)
    80003c92:	7ae2                	ld	s5,56(sp)
    80003c94:	7b42                	ld	s6,48(sp)
    80003c96:	7ba2                	ld	s7,40(sp)
    80003c98:	7c02                	ld	s8,32(sp)
    80003c9a:	6ce2                	ld	s9,24(sp)
    80003c9c:	6d42                	ld	s10,16(sp)
    80003c9e:	6da2                	ld	s11,8(sp)
    80003ca0:	6165                	addi	sp,sp,112
    80003ca2:	8082                	ret
    return -1;
    80003ca4:	557d                	li	a0,-1
}
    80003ca6:	8082                	ret
    return -1;
    80003ca8:	557d                	li	a0,-1
    80003caa:	bff1                	j	80003c86 <writei+0xf0>
    return -1;
    80003cac:	557d                	li	a0,-1
    80003cae:	bfe1                	j	80003c86 <writei+0xf0>

0000000080003cb0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cb0:	1141                	addi	sp,sp,-16
    80003cb2:	e406                	sd	ra,8(sp)
    80003cb4:	e022                	sd	s0,0(sp)
    80003cb6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003cb8:	4639                	li	a2,14
    80003cba:	ffffd097          	auipc	ra,0xffffd
    80003cbe:	1b4080e7          	jalr	436(ra) # 80000e6e <strncmp>
}
    80003cc2:	60a2                	ld	ra,8(sp)
    80003cc4:	6402                	ld	s0,0(sp)
    80003cc6:	0141                	addi	sp,sp,16
    80003cc8:	8082                	ret

0000000080003cca <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cca:	7139                	addi	sp,sp,-64
    80003ccc:	fc06                	sd	ra,56(sp)
    80003cce:	f822                	sd	s0,48(sp)
    80003cd0:	f426                	sd	s1,40(sp)
    80003cd2:	f04a                	sd	s2,32(sp)
    80003cd4:	ec4e                	sd	s3,24(sp)
    80003cd6:	e852                	sd	s4,16(sp)
    80003cd8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cda:	04451703          	lh	a4,68(a0)
    80003cde:	4785                	li	a5,1
    80003ce0:	00f71a63          	bne	a4,a5,80003cf4 <dirlookup+0x2a>
    80003ce4:	892a                	mv	s2,a0
    80003ce6:	89ae                	mv	s3,a1
    80003ce8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cea:	457c                	lw	a5,76(a0)
    80003cec:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cee:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cf0:	e79d                	bnez	a5,80003d1e <dirlookup+0x54>
    80003cf2:	a8a5                	j	80003d6a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cf4:	00005517          	auipc	a0,0x5
    80003cf8:	90450513          	addi	a0,a0,-1788 # 800085f8 <syscalls+0x1b0>
    80003cfc:	ffffd097          	auipc	ra,0xffffd
    80003d00:	8fc080e7          	jalr	-1796(ra) # 800005f8 <panic>
      panic("dirlookup read");
    80003d04:	00005517          	auipc	a0,0x5
    80003d08:	90c50513          	addi	a0,a0,-1780 # 80008610 <syscalls+0x1c8>
    80003d0c:	ffffd097          	auipc	ra,0xffffd
    80003d10:	8ec080e7          	jalr	-1812(ra) # 800005f8 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d14:	24c1                	addiw	s1,s1,16
    80003d16:	04c92783          	lw	a5,76(s2)
    80003d1a:	04f4f763          	bgeu	s1,a5,80003d68 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d1e:	4741                	li	a4,16
    80003d20:	86a6                	mv	a3,s1
    80003d22:	fc040613          	addi	a2,s0,-64
    80003d26:	4581                	li	a1,0
    80003d28:	854a                	mv	a0,s2
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	d76080e7          	jalr	-650(ra) # 80003aa0 <readi>
    80003d32:	47c1                	li	a5,16
    80003d34:	fcf518e3          	bne	a0,a5,80003d04 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d38:	fc045783          	lhu	a5,-64(s0)
    80003d3c:	dfe1                	beqz	a5,80003d14 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d3e:	fc240593          	addi	a1,s0,-62
    80003d42:	854e                	mv	a0,s3
    80003d44:	00000097          	auipc	ra,0x0
    80003d48:	f6c080e7          	jalr	-148(ra) # 80003cb0 <namecmp>
    80003d4c:	f561                	bnez	a0,80003d14 <dirlookup+0x4a>
      if(poff)
    80003d4e:	000a0463          	beqz	s4,80003d56 <dirlookup+0x8c>
        *poff = off;
    80003d52:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d56:	fc045583          	lhu	a1,-64(s0)
    80003d5a:	00092503          	lw	a0,0(s2)
    80003d5e:	fffff097          	auipc	ra,0xfffff
    80003d62:	75a080e7          	jalr	1882(ra) # 800034b8 <iget>
    80003d66:	a011                	j	80003d6a <dirlookup+0xa0>
  return 0;
    80003d68:	4501                	li	a0,0
}
    80003d6a:	70e2                	ld	ra,56(sp)
    80003d6c:	7442                	ld	s0,48(sp)
    80003d6e:	74a2                	ld	s1,40(sp)
    80003d70:	7902                	ld	s2,32(sp)
    80003d72:	69e2                	ld	s3,24(sp)
    80003d74:	6a42                	ld	s4,16(sp)
    80003d76:	6121                	addi	sp,sp,64
    80003d78:	8082                	ret

0000000080003d7a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d7a:	711d                	addi	sp,sp,-96
    80003d7c:	ec86                	sd	ra,88(sp)
    80003d7e:	e8a2                	sd	s0,80(sp)
    80003d80:	e4a6                	sd	s1,72(sp)
    80003d82:	e0ca                	sd	s2,64(sp)
    80003d84:	fc4e                	sd	s3,56(sp)
    80003d86:	f852                	sd	s4,48(sp)
    80003d88:	f456                	sd	s5,40(sp)
    80003d8a:	f05a                	sd	s6,32(sp)
    80003d8c:	ec5e                	sd	s7,24(sp)
    80003d8e:	e862                	sd	s8,16(sp)
    80003d90:	e466                	sd	s9,8(sp)
    80003d92:	1080                	addi	s0,sp,96
    80003d94:	84aa                	mv	s1,a0
    80003d96:	8b2e                	mv	s6,a1
    80003d98:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d9a:	00054703          	lbu	a4,0(a0)
    80003d9e:	02f00793          	li	a5,47
    80003da2:	02f70363          	beq	a4,a5,80003dc8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003da6:	ffffe097          	auipc	ra,0xffffe
    80003daa:	cbe080e7          	jalr	-834(ra) # 80001a64 <myproc>
    80003dae:	15053503          	ld	a0,336(a0)
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	9fc080e7          	jalr	-1540(ra) # 800037ae <idup>
    80003dba:	89aa                	mv	s3,a0
  while(*path == '/')
    80003dbc:	02f00913          	li	s2,47
  len = path - s;
    80003dc0:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003dc2:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003dc4:	4c05                	li	s8,1
    80003dc6:	a865                	j	80003e7e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003dc8:	4585                	li	a1,1
    80003dca:	4505                	li	a0,1
    80003dcc:	fffff097          	auipc	ra,0xfffff
    80003dd0:	6ec080e7          	jalr	1772(ra) # 800034b8 <iget>
    80003dd4:	89aa                	mv	s3,a0
    80003dd6:	b7dd                	j	80003dbc <namex+0x42>
      iunlockput(ip);
    80003dd8:	854e                	mv	a0,s3
    80003dda:	00000097          	auipc	ra,0x0
    80003dde:	c74080e7          	jalr	-908(ra) # 80003a4e <iunlockput>
      return 0;
    80003de2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003de4:	854e                	mv	a0,s3
    80003de6:	60e6                	ld	ra,88(sp)
    80003de8:	6446                	ld	s0,80(sp)
    80003dea:	64a6                	ld	s1,72(sp)
    80003dec:	6906                	ld	s2,64(sp)
    80003dee:	79e2                	ld	s3,56(sp)
    80003df0:	7a42                	ld	s4,48(sp)
    80003df2:	7aa2                	ld	s5,40(sp)
    80003df4:	7b02                	ld	s6,32(sp)
    80003df6:	6be2                	ld	s7,24(sp)
    80003df8:	6c42                	ld	s8,16(sp)
    80003dfa:	6ca2                	ld	s9,8(sp)
    80003dfc:	6125                	addi	sp,sp,96
    80003dfe:	8082                	ret
      iunlock(ip);
    80003e00:	854e                	mv	a0,s3
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	aac080e7          	jalr	-1364(ra) # 800038ae <iunlock>
      return ip;
    80003e0a:	bfe9                	j	80003de4 <namex+0x6a>
      iunlockput(ip);
    80003e0c:	854e                	mv	a0,s3
    80003e0e:	00000097          	auipc	ra,0x0
    80003e12:	c40080e7          	jalr	-960(ra) # 80003a4e <iunlockput>
      return 0;
    80003e16:	89d2                	mv	s3,s4
    80003e18:	b7f1                	j	80003de4 <namex+0x6a>
  len = path - s;
    80003e1a:	40b48633          	sub	a2,s1,a1
    80003e1e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e22:	094cd463          	bge	s9,s4,80003eaa <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e26:	4639                	li	a2,14
    80003e28:	8556                	mv	a0,s5
    80003e2a:	ffffd097          	auipc	ra,0xffffd
    80003e2e:	fc8080e7          	jalr	-56(ra) # 80000df2 <memmove>
  while(*path == '/')
    80003e32:	0004c783          	lbu	a5,0(s1)
    80003e36:	01279763          	bne	a5,s2,80003e44 <namex+0xca>
    path++;
    80003e3a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e3c:	0004c783          	lbu	a5,0(s1)
    80003e40:	ff278de3          	beq	a5,s2,80003e3a <namex+0xc0>
    ilock(ip);
    80003e44:	854e                	mv	a0,s3
    80003e46:	00000097          	auipc	ra,0x0
    80003e4a:	9a6080e7          	jalr	-1626(ra) # 800037ec <ilock>
    if(ip->type != T_DIR){
    80003e4e:	04499783          	lh	a5,68(s3)
    80003e52:	f98793e3          	bne	a5,s8,80003dd8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e56:	000b0563          	beqz	s6,80003e60 <namex+0xe6>
    80003e5a:	0004c783          	lbu	a5,0(s1)
    80003e5e:	d3cd                	beqz	a5,80003e00 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e60:	865e                	mv	a2,s7
    80003e62:	85d6                	mv	a1,s5
    80003e64:	854e                	mv	a0,s3
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	e64080e7          	jalr	-412(ra) # 80003cca <dirlookup>
    80003e6e:	8a2a                	mv	s4,a0
    80003e70:	dd51                	beqz	a0,80003e0c <namex+0x92>
    iunlockput(ip);
    80003e72:	854e                	mv	a0,s3
    80003e74:	00000097          	auipc	ra,0x0
    80003e78:	bda080e7          	jalr	-1062(ra) # 80003a4e <iunlockput>
    ip = next;
    80003e7c:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e7e:	0004c783          	lbu	a5,0(s1)
    80003e82:	05279763          	bne	a5,s2,80003ed0 <namex+0x156>
    path++;
    80003e86:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e88:	0004c783          	lbu	a5,0(s1)
    80003e8c:	ff278de3          	beq	a5,s2,80003e86 <namex+0x10c>
  if(*path == 0)
    80003e90:	c79d                	beqz	a5,80003ebe <namex+0x144>
    path++;
    80003e92:	85a6                	mv	a1,s1
  len = path - s;
    80003e94:	8a5e                	mv	s4,s7
    80003e96:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e98:	01278963          	beq	a5,s2,80003eaa <namex+0x130>
    80003e9c:	dfbd                	beqz	a5,80003e1a <namex+0xa0>
    path++;
    80003e9e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ea0:	0004c783          	lbu	a5,0(s1)
    80003ea4:	ff279ce3          	bne	a5,s2,80003e9c <namex+0x122>
    80003ea8:	bf8d                	j	80003e1a <namex+0xa0>
    memmove(name, s, len);
    80003eaa:	2601                	sext.w	a2,a2
    80003eac:	8556                	mv	a0,s5
    80003eae:	ffffd097          	auipc	ra,0xffffd
    80003eb2:	f44080e7          	jalr	-188(ra) # 80000df2 <memmove>
    name[len] = 0;
    80003eb6:	9a56                	add	s4,s4,s5
    80003eb8:	000a0023          	sb	zero,0(s4)
    80003ebc:	bf9d                	j	80003e32 <namex+0xb8>
  if(nameiparent){
    80003ebe:	f20b03e3          	beqz	s6,80003de4 <namex+0x6a>
    iput(ip);
    80003ec2:	854e                	mv	a0,s3
    80003ec4:	00000097          	auipc	ra,0x0
    80003ec8:	ae2080e7          	jalr	-1310(ra) # 800039a6 <iput>
    return 0;
    80003ecc:	4981                	li	s3,0
    80003ece:	bf19                	j	80003de4 <namex+0x6a>
  if(*path == 0)
    80003ed0:	d7fd                	beqz	a5,80003ebe <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ed2:	0004c783          	lbu	a5,0(s1)
    80003ed6:	85a6                	mv	a1,s1
    80003ed8:	b7d1                	j	80003e9c <namex+0x122>

0000000080003eda <dirlink>:
{
    80003eda:	7139                	addi	sp,sp,-64
    80003edc:	fc06                	sd	ra,56(sp)
    80003ede:	f822                	sd	s0,48(sp)
    80003ee0:	f426                	sd	s1,40(sp)
    80003ee2:	f04a                	sd	s2,32(sp)
    80003ee4:	ec4e                	sd	s3,24(sp)
    80003ee6:	e852                	sd	s4,16(sp)
    80003ee8:	0080                	addi	s0,sp,64
    80003eea:	892a                	mv	s2,a0
    80003eec:	8a2e                	mv	s4,a1
    80003eee:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ef0:	4601                	li	a2,0
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	dd8080e7          	jalr	-552(ra) # 80003cca <dirlookup>
    80003efa:	e93d                	bnez	a0,80003f70 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003efc:	04c92483          	lw	s1,76(s2)
    80003f00:	c49d                	beqz	s1,80003f2e <dirlink+0x54>
    80003f02:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f04:	4741                	li	a4,16
    80003f06:	86a6                	mv	a3,s1
    80003f08:	fc040613          	addi	a2,s0,-64
    80003f0c:	4581                	li	a1,0
    80003f0e:	854a                	mv	a0,s2
    80003f10:	00000097          	auipc	ra,0x0
    80003f14:	b90080e7          	jalr	-1136(ra) # 80003aa0 <readi>
    80003f18:	47c1                	li	a5,16
    80003f1a:	06f51163          	bne	a0,a5,80003f7c <dirlink+0xa2>
    if(de.inum == 0)
    80003f1e:	fc045783          	lhu	a5,-64(s0)
    80003f22:	c791                	beqz	a5,80003f2e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f24:	24c1                	addiw	s1,s1,16
    80003f26:	04c92783          	lw	a5,76(s2)
    80003f2a:	fcf4ede3          	bltu	s1,a5,80003f04 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f2e:	4639                	li	a2,14
    80003f30:	85d2                	mv	a1,s4
    80003f32:	fc240513          	addi	a0,s0,-62
    80003f36:	ffffd097          	auipc	ra,0xffffd
    80003f3a:	f74080e7          	jalr	-140(ra) # 80000eaa <strncpy>
  de.inum = inum;
    80003f3e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f42:	4741                	li	a4,16
    80003f44:	86a6                	mv	a3,s1
    80003f46:	fc040613          	addi	a2,s0,-64
    80003f4a:	4581                	li	a1,0
    80003f4c:	854a                	mv	a0,s2
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	c48080e7          	jalr	-952(ra) # 80003b96 <writei>
    80003f56:	872a                	mv	a4,a0
    80003f58:	47c1                	li	a5,16
  return 0;
    80003f5a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f5c:	02f71863          	bne	a4,a5,80003f8c <dirlink+0xb2>
}
    80003f60:	70e2                	ld	ra,56(sp)
    80003f62:	7442                	ld	s0,48(sp)
    80003f64:	74a2                	ld	s1,40(sp)
    80003f66:	7902                	ld	s2,32(sp)
    80003f68:	69e2                	ld	s3,24(sp)
    80003f6a:	6a42                	ld	s4,16(sp)
    80003f6c:	6121                	addi	sp,sp,64
    80003f6e:	8082                	ret
    iput(ip);
    80003f70:	00000097          	auipc	ra,0x0
    80003f74:	a36080e7          	jalr	-1482(ra) # 800039a6 <iput>
    return -1;
    80003f78:	557d                	li	a0,-1
    80003f7a:	b7dd                	j	80003f60 <dirlink+0x86>
      panic("dirlink read");
    80003f7c:	00004517          	auipc	a0,0x4
    80003f80:	6a450513          	addi	a0,a0,1700 # 80008620 <syscalls+0x1d8>
    80003f84:	ffffc097          	auipc	ra,0xffffc
    80003f88:	674080e7          	jalr	1652(ra) # 800005f8 <panic>
    panic("dirlink");
    80003f8c:	00004517          	auipc	a0,0x4
    80003f90:	7b450513          	addi	a0,a0,1972 # 80008740 <syscalls+0x2f8>
    80003f94:	ffffc097          	auipc	ra,0xffffc
    80003f98:	664080e7          	jalr	1636(ra) # 800005f8 <panic>

0000000080003f9c <namei>:

struct inode*
namei(char *path)
{
    80003f9c:	1101                	addi	sp,sp,-32
    80003f9e:	ec06                	sd	ra,24(sp)
    80003fa0:	e822                	sd	s0,16(sp)
    80003fa2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fa4:	fe040613          	addi	a2,s0,-32
    80003fa8:	4581                	li	a1,0
    80003faa:	00000097          	auipc	ra,0x0
    80003fae:	dd0080e7          	jalr	-560(ra) # 80003d7a <namex>
}
    80003fb2:	60e2                	ld	ra,24(sp)
    80003fb4:	6442                	ld	s0,16(sp)
    80003fb6:	6105                	addi	sp,sp,32
    80003fb8:	8082                	ret

0000000080003fba <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fba:	1141                	addi	sp,sp,-16
    80003fbc:	e406                	sd	ra,8(sp)
    80003fbe:	e022                	sd	s0,0(sp)
    80003fc0:	0800                	addi	s0,sp,16
    80003fc2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fc4:	4585                	li	a1,1
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	db4080e7          	jalr	-588(ra) # 80003d7a <namex>
}
    80003fce:	60a2                	ld	ra,8(sp)
    80003fd0:	6402                	ld	s0,0(sp)
    80003fd2:	0141                	addi	sp,sp,16
    80003fd4:	8082                	ret

0000000080003fd6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fd6:	1101                	addi	sp,sp,-32
    80003fd8:	ec06                	sd	ra,24(sp)
    80003fda:	e822                	sd	s0,16(sp)
    80003fdc:	e426                	sd	s1,8(sp)
    80003fde:	e04a                	sd	s2,0(sp)
    80003fe0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fe2:	00022917          	auipc	s2,0x22
    80003fe6:	72690913          	addi	s2,s2,1830 # 80026708 <log>
    80003fea:	01892583          	lw	a1,24(s2)
    80003fee:	02892503          	lw	a0,40(s2)
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	ff8080e7          	jalr	-8(ra) # 80002fea <bread>
    80003ffa:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003ffc:	02c92683          	lw	a3,44(s2)
    80004000:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004002:	02d05763          	blez	a3,80004030 <write_head+0x5a>
    80004006:	00022797          	auipc	a5,0x22
    8000400a:	73278793          	addi	a5,a5,1842 # 80026738 <log+0x30>
    8000400e:	05c50713          	addi	a4,a0,92
    80004012:	36fd                	addiw	a3,a3,-1
    80004014:	1682                	slli	a3,a3,0x20
    80004016:	9281                	srli	a3,a3,0x20
    80004018:	068a                	slli	a3,a3,0x2
    8000401a:	00022617          	auipc	a2,0x22
    8000401e:	72260613          	addi	a2,a2,1826 # 8002673c <log+0x34>
    80004022:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004024:	4390                	lw	a2,0(a5)
    80004026:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004028:	0791                	addi	a5,a5,4
    8000402a:	0711                	addi	a4,a4,4
    8000402c:	fed79ce3          	bne	a5,a3,80004024 <write_head+0x4e>
  }
  bwrite(buf);
    80004030:	8526                	mv	a0,s1
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	0aa080e7          	jalr	170(ra) # 800030dc <bwrite>
  brelse(buf);
    8000403a:	8526                	mv	a0,s1
    8000403c:	fffff097          	auipc	ra,0xfffff
    80004040:	0de080e7          	jalr	222(ra) # 8000311a <brelse>
}
    80004044:	60e2                	ld	ra,24(sp)
    80004046:	6442                	ld	s0,16(sp)
    80004048:	64a2                	ld	s1,8(sp)
    8000404a:	6902                	ld	s2,0(sp)
    8000404c:	6105                	addi	sp,sp,32
    8000404e:	8082                	ret

0000000080004050 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004050:	00022797          	auipc	a5,0x22
    80004054:	6e47a783          	lw	a5,1764(a5) # 80026734 <log+0x2c>
    80004058:	0af05663          	blez	a5,80004104 <install_trans+0xb4>
{
    8000405c:	7139                	addi	sp,sp,-64
    8000405e:	fc06                	sd	ra,56(sp)
    80004060:	f822                	sd	s0,48(sp)
    80004062:	f426                	sd	s1,40(sp)
    80004064:	f04a                	sd	s2,32(sp)
    80004066:	ec4e                	sd	s3,24(sp)
    80004068:	e852                	sd	s4,16(sp)
    8000406a:	e456                	sd	s5,8(sp)
    8000406c:	0080                	addi	s0,sp,64
    8000406e:	00022a97          	auipc	s5,0x22
    80004072:	6caa8a93          	addi	s5,s5,1738 # 80026738 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004076:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004078:	00022997          	auipc	s3,0x22
    8000407c:	69098993          	addi	s3,s3,1680 # 80026708 <log>
    80004080:	0189a583          	lw	a1,24(s3)
    80004084:	014585bb          	addw	a1,a1,s4
    80004088:	2585                	addiw	a1,a1,1
    8000408a:	0289a503          	lw	a0,40(s3)
    8000408e:	fffff097          	auipc	ra,0xfffff
    80004092:	f5c080e7          	jalr	-164(ra) # 80002fea <bread>
    80004096:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004098:	000aa583          	lw	a1,0(s5)
    8000409c:	0289a503          	lw	a0,40(s3)
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	f4a080e7          	jalr	-182(ra) # 80002fea <bread>
    800040a8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040aa:	40000613          	li	a2,1024
    800040ae:	05890593          	addi	a1,s2,88
    800040b2:	05850513          	addi	a0,a0,88
    800040b6:	ffffd097          	auipc	ra,0xffffd
    800040ba:	d3c080e7          	jalr	-708(ra) # 80000df2 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040be:	8526                	mv	a0,s1
    800040c0:	fffff097          	auipc	ra,0xfffff
    800040c4:	01c080e7          	jalr	28(ra) # 800030dc <bwrite>
    bunpin(dbuf);
    800040c8:	8526                	mv	a0,s1
    800040ca:	fffff097          	auipc	ra,0xfffff
    800040ce:	12a080e7          	jalr	298(ra) # 800031f4 <bunpin>
    brelse(lbuf);
    800040d2:	854a                	mv	a0,s2
    800040d4:	fffff097          	auipc	ra,0xfffff
    800040d8:	046080e7          	jalr	70(ra) # 8000311a <brelse>
    brelse(dbuf);
    800040dc:	8526                	mv	a0,s1
    800040de:	fffff097          	auipc	ra,0xfffff
    800040e2:	03c080e7          	jalr	60(ra) # 8000311a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040e6:	2a05                	addiw	s4,s4,1
    800040e8:	0a91                	addi	s5,s5,4
    800040ea:	02c9a783          	lw	a5,44(s3)
    800040ee:	f8fa49e3          	blt	s4,a5,80004080 <install_trans+0x30>
}
    800040f2:	70e2                	ld	ra,56(sp)
    800040f4:	7442                	ld	s0,48(sp)
    800040f6:	74a2                	ld	s1,40(sp)
    800040f8:	7902                	ld	s2,32(sp)
    800040fa:	69e2                	ld	s3,24(sp)
    800040fc:	6a42                	ld	s4,16(sp)
    800040fe:	6aa2                	ld	s5,8(sp)
    80004100:	6121                	addi	sp,sp,64
    80004102:	8082                	ret
    80004104:	8082                	ret

0000000080004106 <initlog>:
{
    80004106:	7179                	addi	sp,sp,-48
    80004108:	f406                	sd	ra,40(sp)
    8000410a:	f022                	sd	s0,32(sp)
    8000410c:	ec26                	sd	s1,24(sp)
    8000410e:	e84a                	sd	s2,16(sp)
    80004110:	e44e                	sd	s3,8(sp)
    80004112:	1800                	addi	s0,sp,48
    80004114:	892a                	mv	s2,a0
    80004116:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004118:	00022497          	auipc	s1,0x22
    8000411c:	5f048493          	addi	s1,s1,1520 # 80026708 <log>
    80004120:	00004597          	auipc	a1,0x4
    80004124:	51058593          	addi	a1,a1,1296 # 80008630 <syscalls+0x1e8>
    80004128:	8526                	mv	a0,s1
    8000412a:	ffffd097          	auipc	ra,0xffffd
    8000412e:	adc080e7          	jalr	-1316(ra) # 80000c06 <initlock>
  log.start = sb->logstart;
    80004132:	0149a583          	lw	a1,20(s3)
    80004136:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004138:	0109a783          	lw	a5,16(s3)
    8000413c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000413e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004142:	854a                	mv	a0,s2
    80004144:	fffff097          	auipc	ra,0xfffff
    80004148:	ea6080e7          	jalr	-346(ra) # 80002fea <bread>
  log.lh.n = lh->n;
    8000414c:	4d3c                	lw	a5,88(a0)
    8000414e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004150:	02f05563          	blez	a5,8000417a <initlog+0x74>
    80004154:	05c50713          	addi	a4,a0,92
    80004158:	00022697          	auipc	a3,0x22
    8000415c:	5e068693          	addi	a3,a3,1504 # 80026738 <log+0x30>
    80004160:	37fd                	addiw	a5,a5,-1
    80004162:	1782                	slli	a5,a5,0x20
    80004164:	9381                	srli	a5,a5,0x20
    80004166:	078a                	slli	a5,a5,0x2
    80004168:	06050613          	addi	a2,a0,96
    8000416c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000416e:	4310                	lw	a2,0(a4)
    80004170:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004172:	0711                	addi	a4,a4,4
    80004174:	0691                	addi	a3,a3,4
    80004176:	fef71ce3          	bne	a4,a5,8000416e <initlog+0x68>
  brelse(buf);
    8000417a:	fffff097          	auipc	ra,0xfffff
    8000417e:	fa0080e7          	jalr	-96(ra) # 8000311a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004182:	00000097          	auipc	ra,0x0
    80004186:	ece080e7          	jalr	-306(ra) # 80004050 <install_trans>
  log.lh.n = 0;
    8000418a:	00022797          	auipc	a5,0x22
    8000418e:	5a07a523          	sw	zero,1450(a5) # 80026734 <log+0x2c>
  write_head(); // clear the log
    80004192:	00000097          	auipc	ra,0x0
    80004196:	e44080e7          	jalr	-444(ra) # 80003fd6 <write_head>
}
    8000419a:	70a2                	ld	ra,40(sp)
    8000419c:	7402                	ld	s0,32(sp)
    8000419e:	64e2                	ld	s1,24(sp)
    800041a0:	6942                	ld	s2,16(sp)
    800041a2:	69a2                	ld	s3,8(sp)
    800041a4:	6145                	addi	sp,sp,48
    800041a6:	8082                	ret

00000000800041a8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041a8:	1101                	addi	sp,sp,-32
    800041aa:	ec06                	sd	ra,24(sp)
    800041ac:	e822                	sd	s0,16(sp)
    800041ae:	e426                	sd	s1,8(sp)
    800041b0:	e04a                	sd	s2,0(sp)
    800041b2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041b4:	00022517          	auipc	a0,0x22
    800041b8:	55450513          	addi	a0,a0,1364 # 80026708 <log>
    800041bc:	ffffd097          	auipc	ra,0xffffd
    800041c0:	ada080e7          	jalr	-1318(ra) # 80000c96 <acquire>
  while(1){
    if(log.committing){
    800041c4:	00022497          	auipc	s1,0x22
    800041c8:	54448493          	addi	s1,s1,1348 # 80026708 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041cc:	4979                	li	s2,30
    800041ce:	a039                	j	800041dc <begin_op+0x34>
      sleep(&log, &log.lock);
    800041d0:	85a6                	mv	a1,s1
    800041d2:	8526                	mv	a0,s1
    800041d4:	ffffe097          	auipc	ra,0xffffe
    800041d8:	0b4080e7          	jalr	180(ra) # 80002288 <sleep>
    if(log.committing){
    800041dc:	50dc                	lw	a5,36(s1)
    800041de:	fbed                	bnez	a5,800041d0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041e0:	509c                	lw	a5,32(s1)
    800041e2:	0017871b          	addiw	a4,a5,1
    800041e6:	0007069b          	sext.w	a3,a4
    800041ea:	0027179b          	slliw	a5,a4,0x2
    800041ee:	9fb9                	addw	a5,a5,a4
    800041f0:	0017979b          	slliw	a5,a5,0x1
    800041f4:	54d8                	lw	a4,44(s1)
    800041f6:	9fb9                	addw	a5,a5,a4
    800041f8:	00f95963          	bge	s2,a5,8000420a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041fc:	85a6                	mv	a1,s1
    800041fe:	8526                	mv	a0,s1
    80004200:	ffffe097          	auipc	ra,0xffffe
    80004204:	088080e7          	jalr	136(ra) # 80002288 <sleep>
    80004208:	bfd1                	j	800041dc <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000420a:	00022517          	auipc	a0,0x22
    8000420e:	4fe50513          	addi	a0,a0,1278 # 80026708 <log>
    80004212:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004214:	ffffd097          	auipc	ra,0xffffd
    80004218:	b36080e7          	jalr	-1226(ra) # 80000d4a <release>
      break;
    }
  }
}
    8000421c:	60e2                	ld	ra,24(sp)
    8000421e:	6442                	ld	s0,16(sp)
    80004220:	64a2                	ld	s1,8(sp)
    80004222:	6902                	ld	s2,0(sp)
    80004224:	6105                	addi	sp,sp,32
    80004226:	8082                	ret

0000000080004228 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004228:	7139                	addi	sp,sp,-64
    8000422a:	fc06                	sd	ra,56(sp)
    8000422c:	f822                	sd	s0,48(sp)
    8000422e:	f426                	sd	s1,40(sp)
    80004230:	f04a                	sd	s2,32(sp)
    80004232:	ec4e                	sd	s3,24(sp)
    80004234:	e852                	sd	s4,16(sp)
    80004236:	e456                	sd	s5,8(sp)
    80004238:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000423a:	00022497          	auipc	s1,0x22
    8000423e:	4ce48493          	addi	s1,s1,1230 # 80026708 <log>
    80004242:	8526                	mv	a0,s1
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	a52080e7          	jalr	-1454(ra) # 80000c96 <acquire>
  log.outstanding -= 1;
    8000424c:	509c                	lw	a5,32(s1)
    8000424e:	37fd                	addiw	a5,a5,-1
    80004250:	0007891b          	sext.w	s2,a5
    80004254:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004256:	50dc                	lw	a5,36(s1)
    80004258:	efb9                	bnez	a5,800042b6 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000425a:	06091663          	bnez	s2,800042c6 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000425e:	00022497          	auipc	s1,0x22
    80004262:	4aa48493          	addi	s1,s1,1194 # 80026708 <log>
    80004266:	4785                	li	a5,1
    80004268:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000426a:	8526                	mv	a0,s1
    8000426c:	ffffd097          	auipc	ra,0xffffd
    80004270:	ade080e7          	jalr	-1314(ra) # 80000d4a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004274:	54dc                	lw	a5,44(s1)
    80004276:	06f04763          	bgtz	a5,800042e4 <end_op+0xbc>
    acquire(&log.lock);
    8000427a:	00022497          	auipc	s1,0x22
    8000427e:	48e48493          	addi	s1,s1,1166 # 80026708 <log>
    80004282:	8526                	mv	a0,s1
    80004284:	ffffd097          	auipc	ra,0xffffd
    80004288:	a12080e7          	jalr	-1518(ra) # 80000c96 <acquire>
    log.committing = 0;
    8000428c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004290:	8526                	mv	a0,s1
    80004292:	ffffe097          	auipc	ra,0xffffe
    80004296:	17c080e7          	jalr	380(ra) # 8000240e <wakeup>
    release(&log.lock);
    8000429a:	8526                	mv	a0,s1
    8000429c:	ffffd097          	auipc	ra,0xffffd
    800042a0:	aae080e7          	jalr	-1362(ra) # 80000d4a <release>
}
    800042a4:	70e2                	ld	ra,56(sp)
    800042a6:	7442                	ld	s0,48(sp)
    800042a8:	74a2                	ld	s1,40(sp)
    800042aa:	7902                	ld	s2,32(sp)
    800042ac:	69e2                	ld	s3,24(sp)
    800042ae:	6a42                	ld	s4,16(sp)
    800042b0:	6aa2                	ld	s5,8(sp)
    800042b2:	6121                	addi	sp,sp,64
    800042b4:	8082                	ret
    panic("log.committing");
    800042b6:	00004517          	auipc	a0,0x4
    800042ba:	38250513          	addi	a0,a0,898 # 80008638 <syscalls+0x1f0>
    800042be:	ffffc097          	auipc	ra,0xffffc
    800042c2:	33a080e7          	jalr	826(ra) # 800005f8 <panic>
    wakeup(&log);
    800042c6:	00022497          	auipc	s1,0x22
    800042ca:	44248493          	addi	s1,s1,1090 # 80026708 <log>
    800042ce:	8526                	mv	a0,s1
    800042d0:	ffffe097          	auipc	ra,0xffffe
    800042d4:	13e080e7          	jalr	318(ra) # 8000240e <wakeup>
  release(&log.lock);
    800042d8:	8526                	mv	a0,s1
    800042da:	ffffd097          	auipc	ra,0xffffd
    800042de:	a70080e7          	jalr	-1424(ra) # 80000d4a <release>
  if(do_commit){
    800042e2:	b7c9                	j	800042a4 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042e4:	00022a97          	auipc	s5,0x22
    800042e8:	454a8a93          	addi	s5,s5,1108 # 80026738 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042ec:	00022a17          	auipc	s4,0x22
    800042f0:	41ca0a13          	addi	s4,s4,1052 # 80026708 <log>
    800042f4:	018a2583          	lw	a1,24(s4)
    800042f8:	012585bb          	addw	a1,a1,s2
    800042fc:	2585                	addiw	a1,a1,1
    800042fe:	028a2503          	lw	a0,40(s4)
    80004302:	fffff097          	auipc	ra,0xfffff
    80004306:	ce8080e7          	jalr	-792(ra) # 80002fea <bread>
    8000430a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000430c:	000aa583          	lw	a1,0(s5)
    80004310:	028a2503          	lw	a0,40(s4)
    80004314:	fffff097          	auipc	ra,0xfffff
    80004318:	cd6080e7          	jalr	-810(ra) # 80002fea <bread>
    8000431c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000431e:	40000613          	li	a2,1024
    80004322:	05850593          	addi	a1,a0,88
    80004326:	05848513          	addi	a0,s1,88
    8000432a:	ffffd097          	auipc	ra,0xffffd
    8000432e:	ac8080e7          	jalr	-1336(ra) # 80000df2 <memmove>
    bwrite(to);  // write the log
    80004332:	8526                	mv	a0,s1
    80004334:	fffff097          	auipc	ra,0xfffff
    80004338:	da8080e7          	jalr	-600(ra) # 800030dc <bwrite>
    brelse(from);
    8000433c:	854e                	mv	a0,s3
    8000433e:	fffff097          	auipc	ra,0xfffff
    80004342:	ddc080e7          	jalr	-548(ra) # 8000311a <brelse>
    brelse(to);
    80004346:	8526                	mv	a0,s1
    80004348:	fffff097          	auipc	ra,0xfffff
    8000434c:	dd2080e7          	jalr	-558(ra) # 8000311a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004350:	2905                	addiw	s2,s2,1
    80004352:	0a91                	addi	s5,s5,4
    80004354:	02ca2783          	lw	a5,44(s4)
    80004358:	f8f94ee3          	blt	s2,a5,800042f4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000435c:	00000097          	auipc	ra,0x0
    80004360:	c7a080e7          	jalr	-902(ra) # 80003fd6 <write_head>
    install_trans(); // Now install writes to home locations
    80004364:	00000097          	auipc	ra,0x0
    80004368:	cec080e7          	jalr	-788(ra) # 80004050 <install_trans>
    log.lh.n = 0;
    8000436c:	00022797          	auipc	a5,0x22
    80004370:	3c07a423          	sw	zero,968(a5) # 80026734 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004374:	00000097          	auipc	ra,0x0
    80004378:	c62080e7          	jalr	-926(ra) # 80003fd6 <write_head>
    8000437c:	bdfd                	j	8000427a <end_op+0x52>

000000008000437e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000437e:	1101                	addi	sp,sp,-32
    80004380:	ec06                	sd	ra,24(sp)
    80004382:	e822                	sd	s0,16(sp)
    80004384:	e426                	sd	s1,8(sp)
    80004386:	e04a                	sd	s2,0(sp)
    80004388:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000438a:	00022717          	auipc	a4,0x22
    8000438e:	3aa72703          	lw	a4,938(a4) # 80026734 <log+0x2c>
    80004392:	47f5                	li	a5,29
    80004394:	08e7c063          	blt	a5,a4,80004414 <log_write+0x96>
    80004398:	84aa                	mv	s1,a0
    8000439a:	00022797          	auipc	a5,0x22
    8000439e:	38a7a783          	lw	a5,906(a5) # 80026724 <log+0x1c>
    800043a2:	37fd                	addiw	a5,a5,-1
    800043a4:	06f75863          	bge	a4,a5,80004414 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043a8:	00022797          	auipc	a5,0x22
    800043ac:	3807a783          	lw	a5,896(a5) # 80026728 <log+0x20>
    800043b0:	06f05a63          	blez	a5,80004424 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800043b4:	00022917          	auipc	s2,0x22
    800043b8:	35490913          	addi	s2,s2,852 # 80026708 <log>
    800043bc:	854a                	mv	a0,s2
    800043be:	ffffd097          	auipc	ra,0xffffd
    800043c2:	8d8080e7          	jalr	-1832(ra) # 80000c96 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800043c6:	02c92603          	lw	a2,44(s2)
    800043ca:	06c05563          	blez	a2,80004434 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043ce:	44cc                	lw	a1,12(s1)
    800043d0:	00022717          	auipc	a4,0x22
    800043d4:	36870713          	addi	a4,a4,872 # 80026738 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043d8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043da:	4314                	lw	a3,0(a4)
    800043dc:	04b68d63          	beq	a3,a1,80004436 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800043e0:	2785                	addiw	a5,a5,1
    800043e2:	0711                	addi	a4,a4,4
    800043e4:	fec79be3          	bne	a5,a2,800043da <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043e8:	0621                	addi	a2,a2,8
    800043ea:	060a                	slli	a2,a2,0x2
    800043ec:	00022797          	auipc	a5,0x22
    800043f0:	31c78793          	addi	a5,a5,796 # 80026708 <log>
    800043f4:	963e                	add	a2,a2,a5
    800043f6:	44dc                	lw	a5,12(s1)
    800043f8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043fa:	8526                	mv	a0,s1
    800043fc:	fffff097          	auipc	ra,0xfffff
    80004400:	dbc080e7          	jalr	-580(ra) # 800031b8 <bpin>
    log.lh.n++;
    80004404:	00022717          	auipc	a4,0x22
    80004408:	30470713          	addi	a4,a4,772 # 80026708 <log>
    8000440c:	575c                	lw	a5,44(a4)
    8000440e:	2785                	addiw	a5,a5,1
    80004410:	d75c                	sw	a5,44(a4)
    80004412:	a83d                	j	80004450 <log_write+0xd2>
    panic("too big a transaction");
    80004414:	00004517          	auipc	a0,0x4
    80004418:	23450513          	addi	a0,a0,564 # 80008648 <syscalls+0x200>
    8000441c:	ffffc097          	auipc	ra,0xffffc
    80004420:	1dc080e7          	jalr	476(ra) # 800005f8 <panic>
    panic("log_write outside of trans");
    80004424:	00004517          	auipc	a0,0x4
    80004428:	23c50513          	addi	a0,a0,572 # 80008660 <syscalls+0x218>
    8000442c:	ffffc097          	auipc	ra,0xffffc
    80004430:	1cc080e7          	jalr	460(ra) # 800005f8 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004434:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004436:	00878713          	addi	a4,a5,8
    8000443a:	00271693          	slli	a3,a4,0x2
    8000443e:	00022717          	auipc	a4,0x22
    80004442:	2ca70713          	addi	a4,a4,714 # 80026708 <log>
    80004446:	9736                	add	a4,a4,a3
    80004448:	44d4                	lw	a3,12(s1)
    8000444a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000444c:	faf607e3          	beq	a2,a5,800043fa <log_write+0x7c>
  }
  release(&log.lock);
    80004450:	00022517          	auipc	a0,0x22
    80004454:	2b850513          	addi	a0,a0,696 # 80026708 <log>
    80004458:	ffffd097          	auipc	ra,0xffffd
    8000445c:	8f2080e7          	jalr	-1806(ra) # 80000d4a <release>
}
    80004460:	60e2                	ld	ra,24(sp)
    80004462:	6442                	ld	s0,16(sp)
    80004464:	64a2                	ld	s1,8(sp)
    80004466:	6902                	ld	s2,0(sp)
    80004468:	6105                	addi	sp,sp,32
    8000446a:	8082                	ret

000000008000446c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000446c:	1101                	addi	sp,sp,-32
    8000446e:	ec06                	sd	ra,24(sp)
    80004470:	e822                	sd	s0,16(sp)
    80004472:	e426                	sd	s1,8(sp)
    80004474:	e04a                	sd	s2,0(sp)
    80004476:	1000                	addi	s0,sp,32
    80004478:	84aa                	mv	s1,a0
    8000447a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000447c:	00004597          	auipc	a1,0x4
    80004480:	20458593          	addi	a1,a1,516 # 80008680 <syscalls+0x238>
    80004484:	0521                	addi	a0,a0,8
    80004486:	ffffc097          	auipc	ra,0xffffc
    8000448a:	780080e7          	jalr	1920(ra) # 80000c06 <initlock>
  lk->name = name;
    8000448e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004492:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004496:	0204a423          	sw	zero,40(s1)
}
    8000449a:	60e2                	ld	ra,24(sp)
    8000449c:	6442                	ld	s0,16(sp)
    8000449e:	64a2                	ld	s1,8(sp)
    800044a0:	6902                	ld	s2,0(sp)
    800044a2:	6105                	addi	sp,sp,32
    800044a4:	8082                	ret

00000000800044a6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044a6:	1101                	addi	sp,sp,-32
    800044a8:	ec06                	sd	ra,24(sp)
    800044aa:	e822                	sd	s0,16(sp)
    800044ac:	e426                	sd	s1,8(sp)
    800044ae:	e04a                	sd	s2,0(sp)
    800044b0:	1000                	addi	s0,sp,32
    800044b2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044b4:	00850913          	addi	s2,a0,8
    800044b8:	854a                	mv	a0,s2
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	7dc080e7          	jalr	2012(ra) # 80000c96 <acquire>
  while (lk->locked) {
    800044c2:	409c                	lw	a5,0(s1)
    800044c4:	cb89                	beqz	a5,800044d6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044c6:	85ca                	mv	a1,s2
    800044c8:	8526                	mv	a0,s1
    800044ca:	ffffe097          	auipc	ra,0xffffe
    800044ce:	dbe080e7          	jalr	-578(ra) # 80002288 <sleep>
  while (lk->locked) {
    800044d2:	409c                	lw	a5,0(s1)
    800044d4:	fbed                	bnez	a5,800044c6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044d6:	4785                	li	a5,1
    800044d8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044da:	ffffd097          	auipc	ra,0xffffd
    800044de:	58a080e7          	jalr	1418(ra) # 80001a64 <myproc>
    800044e2:	5d1c                	lw	a5,56(a0)
    800044e4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044e6:	854a                	mv	a0,s2
    800044e8:	ffffd097          	auipc	ra,0xffffd
    800044ec:	862080e7          	jalr	-1950(ra) # 80000d4a <release>
}
    800044f0:	60e2                	ld	ra,24(sp)
    800044f2:	6442                	ld	s0,16(sp)
    800044f4:	64a2                	ld	s1,8(sp)
    800044f6:	6902                	ld	s2,0(sp)
    800044f8:	6105                	addi	sp,sp,32
    800044fa:	8082                	ret

00000000800044fc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044fc:	1101                	addi	sp,sp,-32
    800044fe:	ec06                	sd	ra,24(sp)
    80004500:	e822                	sd	s0,16(sp)
    80004502:	e426                	sd	s1,8(sp)
    80004504:	e04a                	sd	s2,0(sp)
    80004506:	1000                	addi	s0,sp,32
    80004508:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000450a:	00850913          	addi	s2,a0,8
    8000450e:	854a                	mv	a0,s2
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	786080e7          	jalr	1926(ra) # 80000c96 <acquire>
  lk->locked = 0;
    80004518:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000451c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004520:	8526                	mv	a0,s1
    80004522:	ffffe097          	auipc	ra,0xffffe
    80004526:	eec080e7          	jalr	-276(ra) # 8000240e <wakeup>
  release(&lk->lk);
    8000452a:	854a                	mv	a0,s2
    8000452c:	ffffd097          	auipc	ra,0xffffd
    80004530:	81e080e7          	jalr	-2018(ra) # 80000d4a <release>
}
    80004534:	60e2                	ld	ra,24(sp)
    80004536:	6442                	ld	s0,16(sp)
    80004538:	64a2                	ld	s1,8(sp)
    8000453a:	6902                	ld	s2,0(sp)
    8000453c:	6105                	addi	sp,sp,32
    8000453e:	8082                	ret

0000000080004540 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004540:	7179                	addi	sp,sp,-48
    80004542:	f406                	sd	ra,40(sp)
    80004544:	f022                	sd	s0,32(sp)
    80004546:	ec26                	sd	s1,24(sp)
    80004548:	e84a                	sd	s2,16(sp)
    8000454a:	e44e                	sd	s3,8(sp)
    8000454c:	1800                	addi	s0,sp,48
    8000454e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004550:	00850913          	addi	s2,a0,8
    80004554:	854a                	mv	a0,s2
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	740080e7          	jalr	1856(ra) # 80000c96 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000455e:	409c                	lw	a5,0(s1)
    80004560:	ef99                	bnez	a5,8000457e <holdingsleep+0x3e>
    80004562:	4481                	li	s1,0
  release(&lk->lk);
    80004564:	854a                	mv	a0,s2
    80004566:	ffffc097          	auipc	ra,0xffffc
    8000456a:	7e4080e7          	jalr	2020(ra) # 80000d4a <release>
  return r;
}
    8000456e:	8526                	mv	a0,s1
    80004570:	70a2                	ld	ra,40(sp)
    80004572:	7402                	ld	s0,32(sp)
    80004574:	64e2                	ld	s1,24(sp)
    80004576:	6942                	ld	s2,16(sp)
    80004578:	69a2                	ld	s3,8(sp)
    8000457a:	6145                	addi	sp,sp,48
    8000457c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000457e:	0284a983          	lw	s3,40(s1)
    80004582:	ffffd097          	auipc	ra,0xffffd
    80004586:	4e2080e7          	jalr	1250(ra) # 80001a64 <myproc>
    8000458a:	5d04                	lw	s1,56(a0)
    8000458c:	413484b3          	sub	s1,s1,s3
    80004590:	0014b493          	seqz	s1,s1
    80004594:	bfc1                	j	80004564 <holdingsleep+0x24>

0000000080004596 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004596:	1141                	addi	sp,sp,-16
    80004598:	e406                	sd	ra,8(sp)
    8000459a:	e022                	sd	s0,0(sp)
    8000459c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000459e:	00004597          	auipc	a1,0x4
    800045a2:	0f258593          	addi	a1,a1,242 # 80008690 <syscalls+0x248>
    800045a6:	00022517          	auipc	a0,0x22
    800045aa:	2aa50513          	addi	a0,a0,682 # 80026850 <ftable>
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	658080e7          	jalr	1624(ra) # 80000c06 <initlock>
}
    800045b6:	60a2                	ld	ra,8(sp)
    800045b8:	6402                	ld	s0,0(sp)
    800045ba:	0141                	addi	sp,sp,16
    800045bc:	8082                	ret

00000000800045be <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045be:	1101                	addi	sp,sp,-32
    800045c0:	ec06                	sd	ra,24(sp)
    800045c2:	e822                	sd	s0,16(sp)
    800045c4:	e426                	sd	s1,8(sp)
    800045c6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045c8:	00022517          	auipc	a0,0x22
    800045cc:	28850513          	addi	a0,a0,648 # 80026850 <ftable>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	6c6080e7          	jalr	1734(ra) # 80000c96 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045d8:	00022497          	auipc	s1,0x22
    800045dc:	29048493          	addi	s1,s1,656 # 80026868 <ftable+0x18>
    800045e0:	00023717          	auipc	a4,0x23
    800045e4:	22870713          	addi	a4,a4,552 # 80027808 <ftable+0xfb8>
    if(f->ref == 0){
    800045e8:	40dc                	lw	a5,4(s1)
    800045ea:	cf99                	beqz	a5,80004608 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ec:	02848493          	addi	s1,s1,40
    800045f0:	fee49ce3          	bne	s1,a4,800045e8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045f4:	00022517          	auipc	a0,0x22
    800045f8:	25c50513          	addi	a0,a0,604 # 80026850 <ftable>
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	74e080e7          	jalr	1870(ra) # 80000d4a <release>
  return 0;
    80004604:	4481                	li	s1,0
    80004606:	a819                	j	8000461c <filealloc+0x5e>
      f->ref = 1;
    80004608:	4785                	li	a5,1
    8000460a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000460c:	00022517          	auipc	a0,0x22
    80004610:	24450513          	addi	a0,a0,580 # 80026850 <ftable>
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	736080e7          	jalr	1846(ra) # 80000d4a <release>
}
    8000461c:	8526                	mv	a0,s1
    8000461e:	60e2                	ld	ra,24(sp)
    80004620:	6442                	ld	s0,16(sp)
    80004622:	64a2                	ld	s1,8(sp)
    80004624:	6105                	addi	sp,sp,32
    80004626:	8082                	ret

0000000080004628 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004628:	1101                	addi	sp,sp,-32
    8000462a:	ec06                	sd	ra,24(sp)
    8000462c:	e822                	sd	s0,16(sp)
    8000462e:	e426                	sd	s1,8(sp)
    80004630:	1000                	addi	s0,sp,32
    80004632:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004634:	00022517          	auipc	a0,0x22
    80004638:	21c50513          	addi	a0,a0,540 # 80026850 <ftable>
    8000463c:	ffffc097          	auipc	ra,0xffffc
    80004640:	65a080e7          	jalr	1626(ra) # 80000c96 <acquire>
  if(f->ref < 1)
    80004644:	40dc                	lw	a5,4(s1)
    80004646:	02f05263          	blez	a5,8000466a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000464a:	2785                	addiw	a5,a5,1
    8000464c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000464e:	00022517          	auipc	a0,0x22
    80004652:	20250513          	addi	a0,a0,514 # 80026850 <ftable>
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	6f4080e7          	jalr	1780(ra) # 80000d4a <release>
  return f;
}
    8000465e:	8526                	mv	a0,s1
    80004660:	60e2                	ld	ra,24(sp)
    80004662:	6442                	ld	s0,16(sp)
    80004664:	64a2                	ld	s1,8(sp)
    80004666:	6105                	addi	sp,sp,32
    80004668:	8082                	ret
    panic("filedup");
    8000466a:	00004517          	auipc	a0,0x4
    8000466e:	02e50513          	addi	a0,a0,46 # 80008698 <syscalls+0x250>
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	f86080e7          	jalr	-122(ra) # 800005f8 <panic>

000000008000467a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000467a:	7139                	addi	sp,sp,-64
    8000467c:	fc06                	sd	ra,56(sp)
    8000467e:	f822                	sd	s0,48(sp)
    80004680:	f426                	sd	s1,40(sp)
    80004682:	f04a                	sd	s2,32(sp)
    80004684:	ec4e                	sd	s3,24(sp)
    80004686:	e852                	sd	s4,16(sp)
    80004688:	e456                	sd	s5,8(sp)
    8000468a:	0080                	addi	s0,sp,64
    8000468c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000468e:	00022517          	auipc	a0,0x22
    80004692:	1c250513          	addi	a0,a0,450 # 80026850 <ftable>
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	600080e7          	jalr	1536(ra) # 80000c96 <acquire>
  if(f->ref < 1)
    8000469e:	40dc                	lw	a5,4(s1)
    800046a0:	06f05163          	blez	a5,80004702 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046a4:	37fd                	addiw	a5,a5,-1
    800046a6:	0007871b          	sext.w	a4,a5
    800046aa:	c0dc                	sw	a5,4(s1)
    800046ac:	06e04363          	bgtz	a4,80004712 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046b0:	0004a903          	lw	s2,0(s1)
    800046b4:	0094ca83          	lbu	s5,9(s1)
    800046b8:	0104ba03          	ld	s4,16(s1)
    800046bc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046c0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046c4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046c8:	00022517          	auipc	a0,0x22
    800046cc:	18850513          	addi	a0,a0,392 # 80026850 <ftable>
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	67a080e7          	jalr	1658(ra) # 80000d4a <release>

  if(ff.type == FD_PIPE){
    800046d8:	4785                	li	a5,1
    800046da:	04f90d63          	beq	s2,a5,80004734 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046de:	3979                	addiw	s2,s2,-2
    800046e0:	4785                	li	a5,1
    800046e2:	0527e063          	bltu	a5,s2,80004722 <fileclose+0xa8>
    begin_op();
    800046e6:	00000097          	auipc	ra,0x0
    800046ea:	ac2080e7          	jalr	-1342(ra) # 800041a8 <begin_op>
    iput(ff.ip);
    800046ee:	854e                	mv	a0,s3
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	2b6080e7          	jalr	694(ra) # 800039a6 <iput>
    end_op();
    800046f8:	00000097          	auipc	ra,0x0
    800046fc:	b30080e7          	jalr	-1232(ra) # 80004228 <end_op>
    80004700:	a00d                	j	80004722 <fileclose+0xa8>
    panic("fileclose");
    80004702:	00004517          	auipc	a0,0x4
    80004706:	f9e50513          	addi	a0,a0,-98 # 800086a0 <syscalls+0x258>
    8000470a:	ffffc097          	auipc	ra,0xffffc
    8000470e:	eee080e7          	jalr	-274(ra) # 800005f8 <panic>
    release(&ftable.lock);
    80004712:	00022517          	auipc	a0,0x22
    80004716:	13e50513          	addi	a0,a0,318 # 80026850 <ftable>
    8000471a:	ffffc097          	auipc	ra,0xffffc
    8000471e:	630080e7          	jalr	1584(ra) # 80000d4a <release>
  }
}
    80004722:	70e2                	ld	ra,56(sp)
    80004724:	7442                	ld	s0,48(sp)
    80004726:	74a2                	ld	s1,40(sp)
    80004728:	7902                	ld	s2,32(sp)
    8000472a:	69e2                	ld	s3,24(sp)
    8000472c:	6a42                	ld	s4,16(sp)
    8000472e:	6aa2                	ld	s5,8(sp)
    80004730:	6121                	addi	sp,sp,64
    80004732:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004734:	85d6                	mv	a1,s5
    80004736:	8552                	mv	a0,s4
    80004738:	00000097          	auipc	ra,0x0
    8000473c:	372080e7          	jalr	882(ra) # 80004aaa <pipeclose>
    80004740:	b7cd                	j	80004722 <fileclose+0xa8>

0000000080004742 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004742:	715d                	addi	sp,sp,-80
    80004744:	e486                	sd	ra,72(sp)
    80004746:	e0a2                	sd	s0,64(sp)
    80004748:	fc26                	sd	s1,56(sp)
    8000474a:	f84a                	sd	s2,48(sp)
    8000474c:	f44e                	sd	s3,40(sp)
    8000474e:	0880                	addi	s0,sp,80
    80004750:	84aa                	mv	s1,a0
    80004752:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004754:	ffffd097          	auipc	ra,0xffffd
    80004758:	310080e7          	jalr	784(ra) # 80001a64 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000475c:	409c                	lw	a5,0(s1)
    8000475e:	37f9                	addiw	a5,a5,-2
    80004760:	4705                	li	a4,1
    80004762:	04f76763          	bltu	a4,a5,800047b0 <filestat+0x6e>
    80004766:	892a                	mv	s2,a0
    ilock(f->ip);
    80004768:	6c88                	ld	a0,24(s1)
    8000476a:	fffff097          	auipc	ra,0xfffff
    8000476e:	082080e7          	jalr	130(ra) # 800037ec <ilock>
    stati(f->ip, &st);
    80004772:	fb840593          	addi	a1,s0,-72
    80004776:	6c88                	ld	a0,24(s1)
    80004778:	fffff097          	auipc	ra,0xfffff
    8000477c:	2fe080e7          	jalr	766(ra) # 80003a76 <stati>
    iunlock(f->ip);
    80004780:	6c88                	ld	a0,24(s1)
    80004782:	fffff097          	auipc	ra,0xfffff
    80004786:	12c080e7          	jalr	300(ra) # 800038ae <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000478a:	46e1                	li	a3,24
    8000478c:	fb840613          	addi	a2,s0,-72
    80004790:	85ce                	mv	a1,s3
    80004792:	05093503          	ld	a0,80(s2)
    80004796:	ffffd097          	auipc	ra,0xffffd
    8000479a:	fc2080e7          	jalr	-62(ra) # 80001758 <copyout>
    8000479e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047a2:	60a6                	ld	ra,72(sp)
    800047a4:	6406                	ld	s0,64(sp)
    800047a6:	74e2                	ld	s1,56(sp)
    800047a8:	7942                	ld	s2,48(sp)
    800047aa:	79a2                	ld	s3,40(sp)
    800047ac:	6161                	addi	sp,sp,80
    800047ae:	8082                	ret
  return -1;
    800047b0:	557d                	li	a0,-1
    800047b2:	bfc5                	j	800047a2 <filestat+0x60>

00000000800047b4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047b4:	7179                	addi	sp,sp,-48
    800047b6:	f406                	sd	ra,40(sp)
    800047b8:	f022                	sd	s0,32(sp)
    800047ba:	ec26                	sd	s1,24(sp)
    800047bc:	e84a                	sd	s2,16(sp)
    800047be:	e44e                	sd	s3,8(sp)
    800047c0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047c2:	00854783          	lbu	a5,8(a0)
    800047c6:	c3d5                	beqz	a5,8000486a <fileread+0xb6>
    800047c8:	84aa                	mv	s1,a0
    800047ca:	89ae                	mv	s3,a1
    800047cc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047ce:	411c                	lw	a5,0(a0)
    800047d0:	4705                	li	a4,1
    800047d2:	04e78963          	beq	a5,a4,80004824 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047d6:	470d                	li	a4,3
    800047d8:	04e78d63          	beq	a5,a4,80004832 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047dc:	4709                	li	a4,2
    800047de:	06e79e63          	bne	a5,a4,8000485a <fileread+0xa6>
    ilock(f->ip);
    800047e2:	6d08                	ld	a0,24(a0)
    800047e4:	fffff097          	auipc	ra,0xfffff
    800047e8:	008080e7          	jalr	8(ra) # 800037ec <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047ec:	874a                	mv	a4,s2
    800047ee:	5094                	lw	a3,32(s1)
    800047f0:	864e                	mv	a2,s3
    800047f2:	4585                	li	a1,1
    800047f4:	6c88                	ld	a0,24(s1)
    800047f6:	fffff097          	auipc	ra,0xfffff
    800047fa:	2aa080e7          	jalr	682(ra) # 80003aa0 <readi>
    800047fe:	892a                	mv	s2,a0
    80004800:	00a05563          	blez	a0,8000480a <fileread+0x56>
      f->off += r;
    80004804:	509c                	lw	a5,32(s1)
    80004806:	9fa9                	addw	a5,a5,a0
    80004808:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000480a:	6c88                	ld	a0,24(s1)
    8000480c:	fffff097          	auipc	ra,0xfffff
    80004810:	0a2080e7          	jalr	162(ra) # 800038ae <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004814:	854a                	mv	a0,s2
    80004816:	70a2                	ld	ra,40(sp)
    80004818:	7402                	ld	s0,32(sp)
    8000481a:	64e2                	ld	s1,24(sp)
    8000481c:	6942                	ld	s2,16(sp)
    8000481e:	69a2                	ld	s3,8(sp)
    80004820:	6145                	addi	sp,sp,48
    80004822:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004824:	6908                	ld	a0,16(a0)
    80004826:	00000097          	auipc	ra,0x0
    8000482a:	418080e7          	jalr	1048(ra) # 80004c3e <piperead>
    8000482e:	892a                	mv	s2,a0
    80004830:	b7d5                	j	80004814 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004832:	02451783          	lh	a5,36(a0)
    80004836:	03079693          	slli	a3,a5,0x30
    8000483a:	92c1                	srli	a3,a3,0x30
    8000483c:	4725                	li	a4,9
    8000483e:	02d76863          	bltu	a4,a3,8000486e <fileread+0xba>
    80004842:	0792                	slli	a5,a5,0x4
    80004844:	00022717          	auipc	a4,0x22
    80004848:	f6c70713          	addi	a4,a4,-148 # 800267b0 <devsw>
    8000484c:	97ba                	add	a5,a5,a4
    8000484e:	639c                	ld	a5,0(a5)
    80004850:	c38d                	beqz	a5,80004872 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004852:	4505                	li	a0,1
    80004854:	9782                	jalr	a5
    80004856:	892a                	mv	s2,a0
    80004858:	bf75                	j	80004814 <fileread+0x60>
    panic("fileread");
    8000485a:	00004517          	auipc	a0,0x4
    8000485e:	e5650513          	addi	a0,a0,-426 # 800086b0 <syscalls+0x268>
    80004862:	ffffc097          	auipc	ra,0xffffc
    80004866:	d96080e7          	jalr	-618(ra) # 800005f8 <panic>
    return -1;
    8000486a:	597d                	li	s2,-1
    8000486c:	b765                	j	80004814 <fileread+0x60>
      return -1;
    8000486e:	597d                	li	s2,-1
    80004870:	b755                	j	80004814 <fileread+0x60>
    80004872:	597d                	li	s2,-1
    80004874:	b745                	j	80004814 <fileread+0x60>

0000000080004876 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004876:	00954783          	lbu	a5,9(a0)
    8000487a:	14078563          	beqz	a5,800049c4 <filewrite+0x14e>
{
    8000487e:	715d                	addi	sp,sp,-80
    80004880:	e486                	sd	ra,72(sp)
    80004882:	e0a2                	sd	s0,64(sp)
    80004884:	fc26                	sd	s1,56(sp)
    80004886:	f84a                	sd	s2,48(sp)
    80004888:	f44e                	sd	s3,40(sp)
    8000488a:	f052                	sd	s4,32(sp)
    8000488c:	ec56                	sd	s5,24(sp)
    8000488e:	e85a                	sd	s6,16(sp)
    80004890:	e45e                	sd	s7,8(sp)
    80004892:	e062                	sd	s8,0(sp)
    80004894:	0880                	addi	s0,sp,80
    80004896:	892a                	mv	s2,a0
    80004898:	8aae                	mv	s5,a1
    8000489a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000489c:	411c                	lw	a5,0(a0)
    8000489e:	4705                	li	a4,1
    800048a0:	02e78263          	beq	a5,a4,800048c4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048a4:	470d                	li	a4,3
    800048a6:	02e78563          	beq	a5,a4,800048d0 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048aa:	4709                	li	a4,2
    800048ac:	10e79463          	bne	a5,a4,800049b4 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048b0:	0ec05e63          	blez	a2,800049ac <filewrite+0x136>
    int i = 0;
    800048b4:	4981                	li	s3,0
    800048b6:	6b05                	lui	s6,0x1
    800048b8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048bc:	6b85                	lui	s7,0x1
    800048be:	c00b8b9b          	addiw	s7,s7,-1024
    800048c2:	a851                	j	80004956 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800048c4:	6908                	ld	a0,16(a0)
    800048c6:	00000097          	auipc	ra,0x0
    800048ca:	254080e7          	jalr	596(ra) # 80004b1a <pipewrite>
    800048ce:	a85d                	j	80004984 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048d0:	02451783          	lh	a5,36(a0)
    800048d4:	03079693          	slli	a3,a5,0x30
    800048d8:	92c1                	srli	a3,a3,0x30
    800048da:	4725                	li	a4,9
    800048dc:	0ed76663          	bltu	a4,a3,800049c8 <filewrite+0x152>
    800048e0:	0792                	slli	a5,a5,0x4
    800048e2:	00022717          	auipc	a4,0x22
    800048e6:	ece70713          	addi	a4,a4,-306 # 800267b0 <devsw>
    800048ea:	97ba                	add	a5,a5,a4
    800048ec:	679c                	ld	a5,8(a5)
    800048ee:	cff9                	beqz	a5,800049cc <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800048f0:	4505                	li	a0,1
    800048f2:	9782                	jalr	a5
    800048f4:	a841                	j	80004984 <filewrite+0x10e>
    800048f6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048fa:	00000097          	auipc	ra,0x0
    800048fe:	8ae080e7          	jalr	-1874(ra) # 800041a8 <begin_op>
      ilock(f->ip);
    80004902:	01893503          	ld	a0,24(s2)
    80004906:	fffff097          	auipc	ra,0xfffff
    8000490a:	ee6080e7          	jalr	-282(ra) # 800037ec <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000490e:	8762                	mv	a4,s8
    80004910:	02092683          	lw	a3,32(s2)
    80004914:	01598633          	add	a2,s3,s5
    80004918:	4585                	li	a1,1
    8000491a:	01893503          	ld	a0,24(s2)
    8000491e:	fffff097          	auipc	ra,0xfffff
    80004922:	278080e7          	jalr	632(ra) # 80003b96 <writei>
    80004926:	84aa                	mv	s1,a0
    80004928:	02a05f63          	blez	a0,80004966 <filewrite+0xf0>
        f->off += r;
    8000492c:	02092783          	lw	a5,32(s2)
    80004930:	9fa9                	addw	a5,a5,a0
    80004932:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004936:	01893503          	ld	a0,24(s2)
    8000493a:	fffff097          	auipc	ra,0xfffff
    8000493e:	f74080e7          	jalr	-140(ra) # 800038ae <iunlock>
      end_op();
    80004942:	00000097          	auipc	ra,0x0
    80004946:	8e6080e7          	jalr	-1818(ra) # 80004228 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    8000494a:	049c1963          	bne	s8,s1,8000499c <filewrite+0x126>
        panic("short filewrite");
      i += r;
    8000494e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004952:	0349d663          	bge	s3,s4,8000497e <filewrite+0x108>
      int n1 = n - i;
    80004956:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000495a:	84be                	mv	s1,a5
    8000495c:	2781                	sext.w	a5,a5
    8000495e:	f8fb5ce3          	bge	s6,a5,800048f6 <filewrite+0x80>
    80004962:	84de                	mv	s1,s7
    80004964:	bf49                	j	800048f6 <filewrite+0x80>
      iunlock(f->ip);
    80004966:	01893503          	ld	a0,24(s2)
    8000496a:	fffff097          	auipc	ra,0xfffff
    8000496e:	f44080e7          	jalr	-188(ra) # 800038ae <iunlock>
      end_op();
    80004972:	00000097          	auipc	ra,0x0
    80004976:	8b6080e7          	jalr	-1866(ra) # 80004228 <end_op>
      if(r < 0)
    8000497a:	fc04d8e3          	bgez	s1,8000494a <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    8000497e:	8552                	mv	a0,s4
    80004980:	033a1863          	bne	s4,s3,800049b0 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004984:	60a6                	ld	ra,72(sp)
    80004986:	6406                	ld	s0,64(sp)
    80004988:	74e2                	ld	s1,56(sp)
    8000498a:	7942                	ld	s2,48(sp)
    8000498c:	79a2                	ld	s3,40(sp)
    8000498e:	7a02                	ld	s4,32(sp)
    80004990:	6ae2                	ld	s5,24(sp)
    80004992:	6b42                	ld	s6,16(sp)
    80004994:	6ba2                	ld	s7,8(sp)
    80004996:	6c02                	ld	s8,0(sp)
    80004998:	6161                	addi	sp,sp,80
    8000499a:	8082                	ret
        panic("short filewrite");
    8000499c:	00004517          	auipc	a0,0x4
    800049a0:	d2450513          	addi	a0,a0,-732 # 800086c0 <syscalls+0x278>
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	c54080e7          	jalr	-940(ra) # 800005f8 <panic>
    int i = 0;
    800049ac:	4981                	li	s3,0
    800049ae:	bfc1                	j	8000497e <filewrite+0x108>
    ret = (i == n ? n : -1);
    800049b0:	557d                	li	a0,-1
    800049b2:	bfc9                	j	80004984 <filewrite+0x10e>
    panic("filewrite");
    800049b4:	00004517          	auipc	a0,0x4
    800049b8:	d1c50513          	addi	a0,a0,-740 # 800086d0 <syscalls+0x288>
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	c3c080e7          	jalr	-964(ra) # 800005f8 <panic>
    return -1;
    800049c4:	557d                	li	a0,-1
}
    800049c6:	8082                	ret
      return -1;
    800049c8:	557d                	li	a0,-1
    800049ca:	bf6d                	j	80004984 <filewrite+0x10e>
    800049cc:	557d                	li	a0,-1
    800049ce:	bf5d                	j	80004984 <filewrite+0x10e>

00000000800049d0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049d0:	7179                	addi	sp,sp,-48
    800049d2:	f406                	sd	ra,40(sp)
    800049d4:	f022                	sd	s0,32(sp)
    800049d6:	ec26                	sd	s1,24(sp)
    800049d8:	e84a                	sd	s2,16(sp)
    800049da:	e44e                	sd	s3,8(sp)
    800049dc:	e052                	sd	s4,0(sp)
    800049de:	1800                	addi	s0,sp,48
    800049e0:	84aa                	mv	s1,a0
    800049e2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049e4:	0005b023          	sd	zero,0(a1)
    800049e8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049ec:	00000097          	auipc	ra,0x0
    800049f0:	bd2080e7          	jalr	-1070(ra) # 800045be <filealloc>
    800049f4:	e088                	sd	a0,0(s1)
    800049f6:	c551                	beqz	a0,80004a82 <pipealloc+0xb2>
    800049f8:	00000097          	auipc	ra,0x0
    800049fc:	bc6080e7          	jalr	-1082(ra) # 800045be <filealloc>
    80004a00:	00aa3023          	sd	a0,0(s4)
    80004a04:	c92d                	beqz	a0,80004a76 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a06:	ffffc097          	auipc	ra,0xffffc
    80004a0a:	1a0080e7          	jalr	416(ra) # 80000ba6 <kalloc>
    80004a0e:	892a                	mv	s2,a0
    80004a10:	c125                	beqz	a0,80004a70 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a12:	4985                	li	s3,1
    80004a14:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a18:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a1c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a20:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a24:	00004597          	auipc	a1,0x4
    80004a28:	cbc58593          	addi	a1,a1,-836 # 800086e0 <syscalls+0x298>
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	1da080e7          	jalr	474(ra) # 80000c06 <initlock>
  (*f0)->type = FD_PIPE;
    80004a34:	609c                	ld	a5,0(s1)
    80004a36:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a3a:	609c                	ld	a5,0(s1)
    80004a3c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a40:	609c                	ld	a5,0(s1)
    80004a42:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a46:	609c                	ld	a5,0(s1)
    80004a48:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a4c:	000a3783          	ld	a5,0(s4)
    80004a50:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a54:	000a3783          	ld	a5,0(s4)
    80004a58:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a5c:	000a3783          	ld	a5,0(s4)
    80004a60:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a64:	000a3783          	ld	a5,0(s4)
    80004a68:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a6c:	4501                	li	a0,0
    80004a6e:	a025                	j	80004a96 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a70:	6088                	ld	a0,0(s1)
    80004a72:	e501                	bnez	a0,80004a7a <pipealloc+0xaa>
    80004a74:	a039                	j	80004a82 <pipealloc+0xb2>
    80004a76:	6088                	ld	a0,0(s1)
    80004a78:	c51d                	beqz	a0,80004aa6 <pipealloc+0xd6>
    fileclose(*f0);
    80004a7a:	00000097          	auipc	ra,0x0
    80004a7e:	c00080e7          	jalr	-1024(ra) # 8000467a <fileclose>
  if(*f1)
    80004a82:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a86:	557d                	li	a0,-1
  if(*f1)
    80004a88:	c799                	beqz	a5,80004a96 <pipealloc+0xc6>
    fileclose(*f1);
    80004a8a:	853e                	mv	a0,a5
    80004a8c:	00000097          	auipc	ra,0x0
    80004a90:	bee080e7          	jalr	-1042(ra) # 8000467a <fileclose>
  return -1;
    80004a94:	557d                	li	a0,-1
}
    80004a96:	70a2                	ld	ra,40(sp)
    80004a98:	7402                	ld	s0,32(sp)
    80004a9a:	64e2                	ld	s1,24(sp)
    80004a9c:	6942                	ld	s2,16(sp)
    80004a9e:	69a2                	ld	s3,8(sp)
    80004aa0:	6a02                	ld	s4,0(sp)
    80004aa2:	6145                	addi	sp,sp,48
    80004aa4:	8082                	ret
  return -1;
    80004aa6:	557d                	li	a0,-1
    80004aa8:	b7fd                	j	80004a96 <pipealloc+0xc6>

0000000080004aaa <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004aaa:	1101                	addi	sp,sp,-32
    80004aac:	ec06                	sd	ra,24(sp)
    80004aae:	e822                	sd	s0,16(sp)
    80004ab0:	e426                	sd	s1,8(sp)
    80004ab2:	e04a                	sd	s2,0(sp)
    80004ab4:	1000                	addi	s0,sp,32
    80004ab6:	84aa                	mv	s1,a0
    80004ab8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	1dc080e7          	jalr	476(ra) # 80000c96 <acquire>
  if(writable){
    80004ac2:	02090d63          	beqz	s2,80004afc <pipeclose+0x52>
    pi->writeopen = 0;
    80004ac6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004aca:	21848513          	addi	a0,s1,536
    80004ace:	ffffe097          	auipc	ra,0xffffe
    80004ad2:	940080e7          	jalr	-1728(ra) # 8000240e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ad6:	2204b783          	ld	a5,544(s1)
    80004ada:	eb95                	bnez	a5,80004b0e <pipeclose+0x64>
    release(&pi->lock);
    80004adc:	8526                	mv	a0,s1
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	26c080e7          	jalr	620(ra) # 80000d4a <release>
    kfree((char*)pi);
    80004ae6:	8526                	mv	a0,s1
    80004ae8:	ffffc097          	auipc	ra,0xffffc
    80004aec:	fc2080e7          	jalr	-62(ra) # 80000aaa <kfree>
  } else
    release(&pi->lock);
}
    80004af0:	60e2                	ld	ra,24(sp)
    80004af2:	6442                	ld	s0,16(sp)
    80004af4:	64a2                	ld	s1,8(sp)
    80004af6:	6902                	ld	s2,0(sp)
    80004af8:	6105                	addi	sp,sp,32
    80004afa:	8082                	ret
    pi->readopen = 0;
    80004afc:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b00:	21c48513          	addi	a0,s1,540
    80004b04:	ffffe097          	auipc	ra,0xffffe
    80004b08:	90a080e7          	jalr	-1782(ra) # 8000240e <wakeup>
    80004b0c:	b7e9                	j	80004ad6 <pipeclose+0x2c>
    release(&pi->lock);
    80004b0e:	8526                	mv	a0,s1
    80004b10:	ffffc097          	auipc	ra,0xffffc
    80004b14:	23a080e7          	jalr	570(ra) # 80000d4a <release>
}
    80004b18:	bfe1                	j	80004af0 <pipeclose+0x46>

0000000080004b1a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b1a:	7119                	addi	sp,sp,-128
    80004b1c:	fc86                	sd	ra,120(sp)
    80004b1e:	f8a2                	sd	s0,112(sp)
    80004b20:	f4a6                	sd	s1,104(sp)
    80004b22:	f0ca                	sd	s2,96(sp)
    80004b24:	ecce                	sd	s3,88(sp)
    80004b26:	e8d2                	sd	s4,80(sp)
    80004b28:	e4d6                	sd	s5,72(sp)
    80004b2a:	e0da                	sd	s6,64(sp)
    80004b2c:	fc5e                	sd	s7,56(sp)
    80004b2e:	f862                	sd	s8,48(sp)
    80004b30:	f466                	sd	s9,40(sp)
    80004b32:	f06a                	sd	s10,32(sp)
    80004b34:	ec6e                	sd	s11,24(sp)
    80004b36:	0100                	addi	s0,sp,128
    80004b38:	84aa                	mv	s1,a0
    80004b3a:	8cae                	mv	s9,a1
    80004b3c:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b3e:	ffffd097          	auipc	ra,0xffffd
    80004b42:	f26080e7          	jalr	-218(ra) # 80001a64 <myproc>
    80004b46:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b48:	8526                	mv	a0,s1
    80004b4a:	ffffc097          	auipc	ra,0xffffc
    80004b4e:	14c080e7          	jalr	332(ra) # 80000c96 <acquire>
  for(i = 0; i < n; i++){
    80004b52:	0d605963          	blez	s6,80004c24 <pipewrite+0x10a>
    80004b56:	89a6                	mv	s3,s1
    80004b58:	3b7d                	addiw	s6,s6,-1
    80004b5a:	1b02                	slli	s6,s6,0x20
    80004b5c:	020b5b13          	srli	s6,s6,0x20
    80004b60:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b62:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b66:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b6a:	5dfd                	li	s11,-1
    80004b6c:	000b8d1b          	sext.w	s10,s7
    80004b70:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b72:	2184a783          	lw	a5,536(s1)
    80004b76:	21c4a703          	lw	a4,540(s1)
    80004b7a:	2007879b          	addiw	a5,a5,512
    80004b7e:	02f71b63          	bne	a4,a5,80004bb4 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004b82:	2204a783          	lw	a5,544(s1)
    80004b86:	cbad                	beqz	a5,80004bf8 <pipewrite+0xde>
    80004b88:	03092783          	lw	a5,48(s2)
    80004b8c:	e7b5                	bnez	a5,80004bf8 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004b8e:	8556                	mv	a0,s5
    80004b90:	ffffe097          	auipc	ra,0xffffe
    80004b94:	87e080e7          	jalr	-1922(ra) # 8000240e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b98:	85ce                	mv	a1,s3
    80004b9a:	8552                	mv	a0,s4
    80004b9c:	ffffd097          	auipc	ra,0xffffd
    80004ba0:	6ec080e7          	jalr	1772(ra) # 80002288 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ba4:	2184a783          	lw	a5,536(s1)
    80004ba8:	21c4a703          	lw	a4,540(s1)
    80004bac:	2007879b          	addiw	a5,a5,512
    80004bb0:	fcf709e3          	beq	a4,a5,80004b82 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bb4:	4685                	li	a3,1
    80004bb6:	019b8633          	add	a2,s7,s9
    80004bba:	f8f40593          	addi	a1,s0,-113
    80004bbe:	05093503          	ld	a0,80(s2)
    80004bc2:	ffffd097          	auipc	ra,0xffffd
    80004bc6:	c22080e7          	jalr	-990(ra) # 800017e4 <copyin>
    80004bca:	05b50e63          	beq	a0,s11,80004c26 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bce:	21c4a783          	lw	a5,540(s1)
    80004bd2:	0017871b          	addiw	a4,a5,1
    80004bd6:	20e4ae23          	sw	a4,540(s1)
    80004bda:	1ff7f793          	andi	a5,a5,511
    80004bde:	97a6                	add	a5,a5,s1
    80004be0:	f8f44703          	lbu	a4,-113(s0)
    80004be4:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004be8:	001d0c1b          	addiw	s8,s10,1
    80004bec:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004bf0:	036b8b63          	beq	s7,s6,80004c26 <pipewrite+0x10c>
    80004bf4:	8bbe                	mv	s7,a5
    80004bf6:	bf9d                	j	80004b6c <pipewrite+0x52>
        release(&pi->lock);
    80004bf8:	8526                	mv	a0,s1
    80004bfa:	ffffc097          	auipc	ra,0xffffc
    80004bfe:	150080e7          	jalr	336(ra) # 80000d4a <release>
        return -1;
    80004c02:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004c04:	8562                	mv	a0,s8
    80004c06:	70e6                	ld	ra,120(sp)
    80004c08:	7446                	ld	s0,112(sp)
    80004c0a:	74a6                	ld	s1,104(sp)
    80004c0c:	7906                	ld	s2,96(sp)
    80004c0e:	69e6                	ld	s3,88(sp)
    80004c10:	6a46                	ld	s4,80(sp)
    80004c12:	6aa6                	ld	s5,72(sp)
    80004c14:	6b06                	ld	s6,64(sp)
    80004c16:	7be2                	ld	s7,56(sp)
    80004c18:	7c42                	ld	s8,48(sp)
    80004c1a:	7ca2                	ld	s9,40(sp)
    80004c1c:	7d02                	ld	s10,32(sp)
    80004c1e:	6de2                	ld	s11,24(sp)
    80004c20:	6109                	addi	sp,sp,128
    80004c22:	8082                	ret
  for(i = 0; i < n; i++){
    80004c24:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004c26:	21848513          	addi	a0,s1,536
    80004c2a:	ffffd097          	auipc	ra,0xffffd
    80004c2e:	7e4080e7          	jalr	2020(ra) # 8000240e <wakeup>
  release(&pi->lock);
    80004c32:	8526                	mv	a0,s1
    80004c34:	ffffc097          	auipc	ra,0xffffc
    80004c38:	116080e7          	jalr	278(ra) # 80000d4a <release>
  return i;
    80004c3c:	b7e1                	j	80004c04 <pipewrite+0xea>

0000000080004c3e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c3e:	715d                	addi	sp,sp,-80
    80004c40:	e486                	sd	ra,72(sp)
    80004c42:	e0a2                	sd	s0,64(sp)
    80004c44:	fc26                	sd	s1,56(sp)
    80004c46:	f84a                	sd	s2,48(sp)
    80004c48:	f44e                	sd	s3,40(sp)
    80004c4a:	f052                	sd	s4,32(sp)
    80004c4c:	ec56                	sd	s5,24(sp)
    80004c4e:	e85a                	sd	s6,16(sp)
    80004c50:	0880                	addi	s0,sp,80
    80004c52:	84aa                	mv	s1,a0
    80004c54:	892e                	mv	s2,a1
    80004c56:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c58:	ffffd097          	auipc	ra,0xffffd
    80004c5c:	e0c080e7          	jalr	-500(ra) # 80001a64 <myproc>
    80004c60:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c62:	8b26                	mv	s6,s1
    80004c64:	8526                	mv	a0,s1
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	030080e7          	jalr	48(ra) # 80000c96 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c6e:	2184a703          	lw	a4,536(s1)
    80004c72:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c76:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c7a:	02f71463          	bne	a4,a5,80004ca2 <piperead+0x64>
    80004c7e:	2244a783          	lw	a5,548(s1)
    80004c82:	c385                	beqz	a5,80004ca2 <piperead+0x64>
    if(pr->killed){
    80004c84:	030a2783          	lw	a5,48(s4)
    80004c88:	ebc1                	bnez	a5,80004d18 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c8a:	85da                	mv	a1,s6
    80004c8c:	854e                	mv	a0,s3
    80004c8e:	ffffd097          	auipc	ra,0xffffd
    80004c92:	5fa080e7          	jalr	1530(ra) # 80002288 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c96:	2184a703          	lw	a4,536(s1)
    80004c9a:	21c4a783          	lw	a5,540(s1)
    80004c9e:	fef700e3          	beq	a4,a5,80004c7e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ca2:	09505263          	blez	s5,80004d26 <piperead+0xe8>
    80004ca6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ca8:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004caa:	2184a783          	lw	a5,536(s1)
    80004cae:	21c4a703          	lw	a4,540(s1)
    80004cb2:	02f70d63          	beq	a4,a5,80004cec <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cb6:	0017871b          	addiw	a4,a5,1
    80004cba:	20e4ac23          	sw	a4,536(s1)
    80004cbe:	1ff7f793          	andi	a5,a5,511
    80004cc2:	97a6                	add	a5,a5,s1
    80004cc4:	0187c783          	lbu	a5,24(a5)
    80004cc8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ccc:	4685                	li	a3,1
    80004cce:	fbf40613          	addi	a2,s0,-65
    80004cd2:	85ca                	mv	a1,s2
    80004cd4:	050a3503          	ld	a0,80(s4)
    80004cd8:	ffffd097          	auipc	ra,0xffffd
    80004cdc:	a80080e7          	jalr	-1408(ra) # 80001758 <copyout>
    80004ce0:	01650663          	beq	a0,s6,80004cec <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ce4:	2985                	addiw	s3,s3,1
    80004ce6:	0905                	addi	s2,s2,1
    80004ce8:	fd3a91e3          	bne	s5,s3,80004caa <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cec:	21c48513          	addi	a0,s1,540
    80004cf0:	ffffd097          	auipc	ra,0xffffd
    80004cf4:	71e080e7          	jalr	1822(ra) # 8000240e <wakeup>
  release(&pi->lock);
    80004cf8:	8526                	mv	a0,s1
    80004cfa:	ffffc097          	auipc	ra,0xffffc
    80004cfe:	050080e7          	jalr	80(ra) # 80000d4a <release>
  return i;
}
    80004d02:	854e                	mv	a0,s3
    80004d04:	60a6                	ld	ra,72(sp)
    80004d06:	6406                	ld	s0,64(sp)
    80004d08:	74e2                	ld	s1,56(sp)
    80004d0a:	7942                	ld	s2,48(sp)
    80004d0c:	79a2                	ld	s3,40(sp)
    80004d0e:	7a02                	ld	s4,32(sp)
    80004d10:	6ae2                	ld	s5,24(sp)
    80004d12:	6b42                	ld	s6,16(sp)
    80004d14:	6161                	addi	sp,sp,80
    80004d16:	8082                	ret
      release(&pi->lock);
    80004d18:	8526                	mv	a0,s1
    80004d1a:	ffffc097          	auipc	ra,0xffffc
    80004d1e:	030080e7          	jalr	48(ra) # 80000d4a <release>
      return -1;
    80004d22:	59fd                	li	s3,-1
    80004d24:	bff9                	j	80004d02 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d26:	4981                	li	s3,0
    80004d28:	b7d1                	j	80004cec <piperead+0xae>

0000000080004d2a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d2a:	df010113          	addi	sp,sp,-528
    80004d2e:	20113423          	sd	ra,520(sp)
    80004d32:	20813023          	sd	s0,512(sp)
    80004d36:	ffa6                	sd	s1,504(sp)
    80004d38:	fbca                	sd	s2,496(sp)
    80004d3a:	f7ce                	sd	s3,488(sp)
    80004d3c:	f3d2                	sd	s4,480(sp)
    80004d3e:	efd6                	sd	s5,472(sp)
    80004d40:	ebda                	sd	s6,464(sp)
    80004d42:	e7de                	sd	s7,456(sp)
    80004d44:	e3e2                	sd	s8,448(sp)
    80004d46:	ff66                	sd	s9,440(sp)
    80004d48:	fb6a                	sd	s10,432(sp)
    80004d4a:	f76e                	sd	s11,424(sp)
    80004d4c:	0c00                	addi	s0,sp,528
    80004d4e:	84aa                	mv	s1,a0
    80004d50:	dea43c23          	sd	a0,-520(s0)
    80004d54:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d58:	ffffd097          	auipc	ra,0xffffd
    80004d5c:	d0c080e7          	jalr	-756(ra) # 80001a64 <myproc>
    80004d60:	892a                	mv	s2,a0

  begin_op();
    80004d62:	fffff097          	auipc	ra,0xfffff
    80004d66:	446080e7          	jalr	1094(ra) # 800041a8 <begin_op>

  if((ip = namei(path)) == 0){
    80004d6a:	8526                	mv	a0,s1
    80004d6c:	fffff097          	auipc	ra,0xfffff
    80004d70:	230080e7          	jalr	560(ra) # 80003f9c <namei>
    80004d74:	c92d                	beqz	a0,80004de6 <exec+0xbc>
    80004d76:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d78:	fffff097          	auipc	ra,0xfffff
    80004d7c:	a74080e7          	jalr	-1420(ra) # 800037ec <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d80:	04000713          	li	a4,64
    80004d84:	4681                	li	a3,0
    80004d86:	e4840613          	addi	a2,s0,-440
    80004d8a:	4581                	li	a1,0
    80004d8c:	8526                	mv	a0,s1
    80004d8e:	fffff097          	auipc	ra,0xfffff
    80004d92:	d12080e7          	jalr	-750(ra) # 80003aa0 <readi>
    80004d96:	04000793          	li	a5,64
    80004d9a:	00f51a63          	bne	a0,a5,80004dae <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d9e:	e4842703          	lw	a4,-440(s0)
    80004da2:	464c47b7          	lui	a5,0x464c4
    80004da6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004daa:	04f70463          	beq	a4,a5,80004df2 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dae:	8526                	mv	a0,s1
    80004db0:	fffff097          	auipc	ra,0xfffff
    80004db4:	c9e080e7          	jalr	-866(ra) # 80003a4e <iunlockput>
    end_op();
    80004db8:	fffff097          	auipc	ra,0xfffff
    80004dbc:	470080e7          	jalr	1136(ra) # 80004228 <end_op>
  }
  return -1;
    80004dc0:	557d                	li	a0,-1
}
    80004dc2:	20813083          	ld	ra,520(sp)
    80004dc6:	20013403          	ld	s0,512(sp)
    80004dca:	74fe                	ld	s1,504(sp)
    80004dcc:	795e                	ld	s2,496(sp)
    80004dce:	79be                	ld	s3,488(sp)
    80004dd0:	7a1e                	ld	s4,480(sp)
    80004dd2:	6afe                	ld	s5,472(sp)
    80004dd4:	6b5e                	ld	s6,464(sp)
    80004dd6:	6bbe                	ld	s7,456(sp)
    80004dd8:	6c1e                	ld	s8,448(sp)
    80004dda:	7cfa                	ld	s9,440(sp)
    80004ddc:	7d5a                	ld	s10,432(sp)
    80004dde:	7dba                	ld	s11,424(sp)
    80004de0:	21010113          	addi	sp,sp,528
    80004de4:	8082                	ret
    end_op();
    80004de6:	fffff097          	auipc	ra,0xfffff
    80004dea:	442080e7          	jalr	1090(ra) # 80004228 <end_op>
    return -1;
    80004dee:	557d                	li	a0,-1
    80004df0:	bfc9                	j	80004dc2 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004df2:	854a                	mv	a0,s2
    80004df4:	ffffd097          	auipc	ra,0xffffd
    80004df8:	d34080e7          	jalr	-716(ra) # 80001b28 <proc_pagetable>
    80004dfc:	8baa                	mv	s7,a0
    80004dfe:	d945                	beqz	a0,80004dae <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e00:	e6842983          	lw	s3,-408(s0)
    80004e04:	e8045783          	lhu	a5,-384(s0)
    80004e08:	c7ad                	beqz	a5,80004e72 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e0a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e0c:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004e0e:	6c85                	lui	s9,0x1
    80004e10:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e14:	def43823          	sd	a5,-528(s0)
    80004e18:	a42d                	j	80005042 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e1a:	00004517          	auipc	a0,0x4
    80004e1e:	8ce50513          	addi	a0,a0,-1842 # 800086e8 <syscalls+0x2a0>
    80004e22:	ffffb097          	auipc	ra,0xffffb
    80004e26:	7d6080e7          	jalr	2006(ra) # 800005f8 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e2a:	8756                	mv	a4,s5
    80004e2c:	012d86bb          	addw	a3,s11,s2
    80004e30:	4581                	li	a1,0
    80004e32:	8526                	mv	a0,s1
    80004e34:	fffff097          	auipc	ra,0xfffff
    80004e38:	c6c080e7          	jalr	-916(ra) # 80003aa0 <readi>
    80004e3c:	2501                	sext.w	a0,a0
    80004e3e:	1aaa9963          	bne	s5,a0,80004ff0 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e42:	6785                	lui	a5,0x1
    80004e44:	0127893b          	addw	s2,a5,s2
    80004e48:	77fd                	lui	a5,0xfffff
    80004e4a:	01478a3b          	addw	s4,a5,s4
    80004e4e:	1f897163          	bgeu	s2,s8,80005030 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e52:	02091593          	slli	a1,s2,0x20
    80004e56:	9181                	srli	a1,a1,0x20
    80004e58:	95ea                	add	a1,a1,s10
    80004e5a:	855e                	mv	a0,s7
    80004e5c:	ffffc097          	auipc	ra,0xffffc
    80004e60:	2c8080e7          	jalr	712(ra) # 80001124 <walkaddr>
    80004e64:	862a                	mv	a2,a0
    if(pa == 0)
    80004e66:	d955                	beqz	a0,80004e1a <exec+0xf0>
      n = PGSIZE;
    80004e68:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e6a:	fd9a70e3          	bgeu	s4,s9,80004e2a <exec+0x100>
      n = sz - i;
    80004e6e:	8ad2                	mv	s5,s4
    80004e70:	bf6d                	j	80004e2a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e72:	4901                	li	s2,0
  iunlockput(ip);
    80004e74:	8526                	mv	a0,s1
    80004e76:	fffff097          	auipc	ra,0xfffff
    80004e7a:	bd8080e7          	jalr	-1064(ra) # 80003a4e <iunlockput>
  end_op();
    80004e7e:	fffff097          	auipc	ra,0xfffff
    80004e82:	3aa080e7          	jalr	938(ra) # 80004228 <end_op>
  p = myproc();
    80004e86:	ffffd097          	auipc	ra,0xffffd
    80004e8a:	bde080e7          	jalr	-1058(ra) # 80001a64 <myproc>
    80004e8e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e90:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e94:	6785                	lui	a5,0x1
    80004e96:	17fd                	addi	a5,a5,-1
    80004e98:	993e                	add	s2,s2,a5
    80004e9a:	757d                	lui	a0,0xfffff
    80004e9c:	00a977b3          	and	a5,s2,a0
    80004ea0:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ea4:	6609                	lui	a2,0x2
    80004ea6:	963e                	add	a2,a2,a5
    80004ea8:	85be                	mv	a1,a5
    80004eaa:	855e                	mv	a0,s7
    80004eac:	ffffc097          	auipc	ra,0xffffc
    80004eb0:	65c080e7          	jalr	1628(ra) # 80001508 <uvmalloc>
    80004eb4:	8b2a                	mv	s6,a0
  ip = 0;
    80004eb6:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004eb8:	12050c63          	beqz	a0,80004ff0 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ebc:	75f9                	lui	a1,0xffffe
    80004ebe:	95aa                	add	a1,a1,a0
    80004ec0:	855e                	mv	a0,s7
    80004ec2:	ffffd097          	auipc	ra,0xffffd
    80004ec6:	864080e7          	jalr	-1948(ra) # 80001726 <uvmclear>
  stackbase = sp - PGSIZE;
    80004eca:	7c7d                	lui	s8,0xfffff
    80004ecc:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ece:	e0043783          	ld	a5,-512(s0)
    80004ed2:	6388                	ld	a0,0(a5)
    80004ed4:	c535                	beqz	a0,80004f40 <exec+0x216>
    80004ed6:	e8840993          	addi	s3,s0,-376
    80004eda:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004ede:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004ee0:	ffffc097          	auipc	ra,0xffffc
    80004ee4:	03a080e7          	jalr	58(ra) # 80000f1a <strlen>
    80004ee8:	2505                	addiw	a0,a0,1
    80004eea:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004eee:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ef2:	13896363          	bltu	s2,s8,80005018 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ef6:	e0043d83          	ld	s11,-512(s0)
    80004efa:	000dba03          	ld	s4,0(s11)
    80004efe:	8552                	mv	a0,s4
    80004f00:	ffffc097          	auipc	ra,0xffffc
    80004f04:	01a080e7          	jalr	26(ra) # 80000f1a <strlen>
    80004f08:	0015069b          	addiw	a3,a0,1
    80004f0c:	8652                	mv	a2,s4
    80004f0e:	85ca                	mv	a1,s2
    80004f10:	855e                	mv	a0,s7
    80004f12:	ffffd097          	auipc	ra,0xffffd
    80004f16:	846080e7          	jalr	-1978(ra) # 80001758 <copyout>
    80004f1a:	10054363          	bltz	a0,80005020 <exec+0x2f6>
    ustack[argc] = sp;
    80004f1e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f22:	0485                	addi	s1,s1,1
    80004f24:	008d8793          	addi	a5,s11,8
    80004f28:	e0f43023          	sd	a5,-512(s0)
    80004f2c:	008db503          	ld	a0,8(s11)
    80004f30:	c911                	beqz	a0,80004f44 <exec+0x21a>
    if(argc >= MAXARG)
    80004f32:	09a1                	addi	s3,s3,8
    80004f34:	fb3c96e3          	bne	s9,s3,80004ee0 <exec+0x1b6>
  sz = sz1;
    80004f38:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f3c:	4481                	li	s1,0
    80004f3e:	a84d                	j	80004ff0 <exec+0x2c6>
  sp = sz;
    80004f40:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f42:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f44:	00349793          	slli	a5,s1,0x3
    80004f48:	f9040713          	addi	a4,s0,-112
    80004f4c:	97ba                	add	a5,a5,a4
    80004f4e:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004f52:	00148693          	addi	a3,s1,1
    80004f56:	068e                	slli	a3,a3,0x3
    80004f58:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f5c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f60:	01897663          	bgeu	s2,s8,80004f6c <exec+0x242>
  sz = sz1;
    80004f64:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f68:	4481                	li	s1,0
    80004f6a:	a059                	j	80004ff0 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f6c:	e8840613          	addi	a2,s0,-376
    80004f70:	85ca                	mv	a1,s2
    80004f72:	855e                	mv	a0,s7
    80004f74:	ffffc097          	auipc	ra,0xffffc
    80004f78:	7e4080e7          	jalr	2020(ra) # 80001758 <copyout>
    80004f7c:	0a054663          	bltz	a0,80005028 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f80:	058ab783          	ld	a5,88(s5)
    80004f84:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f88:	df843783          	ld	a5,-520(s0)
    80004f8c:	0007c703          	lbu	a4,0(a5)
    80004f90:	cf11                	beqz	a4,80004fac <exec+0x282>
    80004f92:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f94:	02f00693          	li	a3,47
    80004f98:	a029                	j	80004fa2 <exec+0x278>
  for(last=s=path; *s; s++)
    80004f9a:	0785                	addi	a5,a5,1
    80004f9c:	fff7c703          	lbu	a4,-1(a5)
    80004fa0:	c711                	beqz	a4,80004fac <exec+0x282>
    if(*s == '/')
    80004fa2:	fed71ce3          	bne	a4,a3,80004f9a <exec+0x270>
      last = s+1;
    80004fa6:	def43c23          	sd	a5,-520(s0)
    80004faa:	bfc5                	j	80004f9a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fac:	4641                	li	a2,16
    80004fae:	df843583          	ld	a1,-520(s0)
    80004fb2:	158a8513          	addi	a0,s5,344
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	f32080e7          	jalr	-206(ra) # 80000ee8 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fbe:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fc2:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004fc6:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fca:	058ab783          	ld	a5,88(s5)
    80004fce:	e6043703          	ld	a4,-416(s0)
    80004fd2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fd4:	058ab783          	ld	a5,88(s5)
    80004fd8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fdc:	85ea                	mv	a1,s10
    80004fde:	ffffd097          	auipc	ra,0xffffd
    80004fe2:	be6080e7          	jalr	-1050(ra) # 80001bc4 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fe6:	0004851b          	sext.w	a0,s1
    80004fea:	bbe1                	j	80004dc2 <exec+0x98>
    80004fec:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004ff0:	e0843583          	ld	a1,-504(s0)
    80004ff4:	855e                	mv	a0,s7
    80004ff6:	ffffd097          	auipc	ra,0xffffd
    80004ffa:	bce080e7          	jalr	-1074(ra) # 80001bc4 <proc_freepagetable>
  if(ip){
    80004ffe:	da0498e3          	bnez	s1,80004dae <exec+0x84>
  return -1;
    80005002:	557d                	li	a0,-1
    80005004:	bb7d                	j	80004dc2 <exec+0x98>
    80005006:	e1243423          	sd	s2,-504(s0)
    8000500a:	b7dd                	j	80004ff0 <exec+0x2c6>
    8000500c:	e1243423          	sd	s2,-504(s0)
    80005010:	b7c5                	j	80004ff0 <exec+0x2c6>
    80005012:	e1243423          	sd	s2,-504(s0)
    80005016:	bfe9                	j	80004ff0 <exec+0x2c6>
  sz = sz1;
    80005018:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000501c:	4481                	li	s1,0
    8000501e:	bfc9                	j	80004ff0 <exec+0x2c6>
  sz = sz1;
    80005020:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005024:	4481                	li	s1,0
    80005026:	b7e9                	j	80004ff0 <exec+0x2c6>
  sz = sz1;
    80005028:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000502c:	4481                	li	s1,0
    8000502e:	b7c9                	j	80004ff0 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005030:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005034:	2b05                	addiw	s6,s6,1
    80005036:	0389899b          	addiw	s3,s3,56
    8000503a:	e8045783          	lhu	a5,-384(s0)
    8000503e:	e2fb5be3          	bge	s6,a5,80004e74 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005042:	2981                	sext.w	s3,s3
    80005044:	03800713          	li	a4,56
    80005048:	86ce                	mv	a3,s3
    8000504a:	e1040613          	addi	a2,s0,-496
    8000504e:	4581                	li	a1,0
    80005050:	8526                	mv	a0,s1
    80005052:	fffff097          	auipc	ra,0xfffff
    80005056:	a4e080e7          	jalr	-1458(ra) # 80003aa0 <readi>
    8000505a:	03800793          	li	a5,56
    8000505e:	f8f517e3          	bne	a0,a5,80004fec <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005062:	e1042783          	lw	a5,-496(s0)
    80005066:	4705                	li	a4,1
    80005068:	fce796e3          	bne	a5,a4,80005034 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000506c:	e3843603          	ld	a2,-456(s0)
    80005070:	e3043783          	ld	a5,-464(s0)
    80005074:	f8f669e3          	bltu	a2,a5,80005006 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005078:	e2043783          	ld	a5,-480(s0)
    8000507c:	963e                	add	a2,a2,a5
    8000507e:	f8f667e3          	bltu	a2,a5,8000500c <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005082:	85ca                	mv	a1,s2
    80005084:	855e                	mv	a0,s7
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	482080e7          	jalr	1154(ra) # 80001508 <uvmalloc>
    8000508e:	e0a43423          	sd	a0,-504(s0)
    80005092:	d141                	beqz	a0,80005012 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005094:	e2043d03          	ld	s10,-480(s0)
    80005098:	df043783          	ld	a5,-528(s0)
    8000509c:	00fd77b3          	and	a5,s10,a5
    800050a0:	fba1                	bnez	a5,80004ff0 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050a2:	e1842d83          	lw	s11,-488(s0)
    800050a6:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050aa:	f80c03e3          	beqz	s8,80005030 <exec+0x306>
    800050ae:	8a62                	mv	s4,s8
    800050b0:	4901                	li	s2,0
    800050b2:	b345                	j	80004e52 <exec+0x128>

00000000800050b4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050b4:	7179                	addi	sp,sp,-48
    800050b6:	f406                	sd	ra,40(sp)
    800050b8:	f022                	sd	s0,32(sp)
    800050ba:	ec26                	sd	s1,24(sp)
    800050bc:	e84a                	sd	s2,16(sp)
    800050be:	1800                	addi	s0,sp,48
    800050c0:	892e                	mv	s2,a1
    800050c2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050c4:	fdc40593          	addi	a1,s0,-36
    800050c8:	ffffe097          	auipc	ra,0xffffe
    800050cc:	ad6080e7          	jalr	-1322(ra) # 80002b9e <argint>
    800050d0:	04054063          	bltz	a0,80005110 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050d4:	fdc42703          	lw	a4,-36(s0)
    800050d8:	47bd                	li	a5,15
    800050da:	02e7ed63          	bltu	a5,a4,80005114 <argfd+0x60>
    800050de:	ffffd097          	auipc	ra,0xffffd
    800050e2:	986080e7          	jalr	-1658(ra) # 80001a64 <myproc>
    800050e6:	fdc42703          	lw	a4,-36(s0)
    800050ea:	01a70793          	addi	a5,a4,26
    800050ee:	078e                	slli	a5,a5,0x3
    800050f0:	953e                	add	a0,a0,a5
    800050f2:	611c                	ld	a5,0(a0)
    800050f4:	c395                	beqz	a5,80005118 <argfd+0x64>
    return -1;
  if(pfd)
    800050f6:	00090463          	beqz	s2,800050fe <argfd+0x4a>
    *pfd = fd;
    800050fa:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050fe:	4501                	li	a0,0
  if(pf)
    80005100:	c091                	beqz	s1,80005104 <argfd+0x50>
    *pf = f;
    80005102:	e09c                	sd	a5,0(s1)
}
    80005104:	70a2                	ld	ra,40(sp)
    80005106:	7402                	ld	s0,32(sp)
    80005108:	64e2                	ld	s1,24(sp)
    8000510a:	6942                	ld	s2,16(sp)
    8000510c:	6145                	addi	sp,sp,48
    8000510e:	8082                	ret
    return -1;
    80005110:	557d                	li	a0,-1
    80005112:	bfcd                	j	80005104 <argfd+0x50>
    return -1;
    80005114:	557d                	li	a0,-1
    80005116:	b7fd                	j	80005104 <argfd+0x50>
    80005118:	557d                	li	a0,-1
    8000511a:	b7ed                	j	80005104 <argfd+0x50>

000000008000511c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000511c:	1101                	addi	sp,sp,-32
    8000511e:	ec06                	sd	ra,24(sp)
    80005120:	e822                	sd	s0,16(sp)
    80005122:	e426                	sd	s1,8(sp)
    80005124:	1000                	addi	s0,sp,32
    80005126:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005128:	ffffd097          	auipc	ra,0xffffd
    8000512c:	93c080e7          	jalr	-1732(ra) # 80001a64 <myproc>
    80005130:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005132:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd40d0>
    80005136:	4501                	li	a0,0
    80005138:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000513a:	6398                	ld	a4,0(a5)
    8000513c:	cb19                	beqz	a4,80005152 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000513e:	2505                	addiw	a0,a0,1
    80005140:	07a1                	addi	a5,a5,8
    80005142:	fed51ce3          	bne	a0,a3,8000513a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005146:	557d                	li	a0,-1
}
    80005148:	60e2                	ld	ra,24(sp)
    8000514a:	6442                	ld	s0,16(sp)
    8000514c:	64a2                	ld	s1,8(sp)
    8000514e:	6105                	addi	sp,sp,32
    80005150:	8082                	ret
      p->ofile[fd] = f;
    80005152:	01a50793          	addi	a5,a0,26
    80005156:	078e                	slli	a5,a5,0x3
    80005158:	963e                	add	a2,a2,a5
    8000515a:	e204                	sd	s1,0(a2)
      return fd;
    8000515c:	b7f5                	j	80005148 <fdalloc+0x2c>

000000008000515e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000515e:	715d                	addi	sp,sp,-80
    80005160:	e486                	sd	ra,72(sp)
    80005162:	e0a2                	sd	s0,64(sp)
    80005164:	fc26                	sd	s1,56(sp)
    80005166:	f84a                	sd	s2,48(sp)
    80005168:	f44e                	sd	s3,40(sp)
    8000516a:	f052                	sd	s4,32(sp)
    8000516c:	ec56                	sd	s5,24(sp)
    8000516e:	0880                	addi	s0,sp,80
    80005170:	89ae                	mv	s3,a1
    80005172:	8ab2                	mv	s5,a2
    80005174:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005176:	fb040593          	addi	a1,s0,-80
    8000517a:	fffff097          	auipc	ra,0xfffff
    8000517e:	e40080e7          	jalr	-448(ra) # 80003fba <nameiparent>
    80005182:	892a                	mv	s2,a0
    80005184:	12050f63          	beqz	a0,800052c2 <create+0x164>
    return 0;

  ilock(dp);
    80005188:	ffffe097          	auipc	ra,0xffffe
    8000518c:	664080e7          	jalr	1636(ra) # 800037ec <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005190:	4601                	li	a2,0
    80005192:	fb040593          	addi	a1,s0,-80
    80005196:	854a                	mv	a0,s2
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	b32080e7          	jalr	-1230(ra) # 80003cca <dirlookup>
    800051a0:	84aa                	mv	s1,a0
    800051a2:	c921                	beqz	a0,800051f2 <create+0x94>
    iunlockput(dp);
    800051a4:	854a                	mv	a0,s2
    800051a6:	fffff097          	auipc	ra,0xfffff
    800051aa:	8a8080e7          	jalr	-1880(ra) # 80003a4e <iunlockput>
    ilock(ip);
    800051ae:	8526                	mv	a0,s1
    800051b0:	ffffe097          	auipc	ra,0xffffe
    800051b4:	63c080e7          	jalr	1596(ra) # 800037ec <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051b8:	2981                	sext.w	s3,s3
    800051ba:	4789                	li	a5,2
    800051bc:	02f99463          	bne	s3,a5,800051e4 <create+0x86>
    800051c0:	0444d783          	lhu	a5,68(s1)
    800051c4:	37f9                	addiw	a5,a5,-2
    800051c6:	17c2                	slli	a5,a5,0x30
    800051c8:	93c1                	srli	a5,a5,0x30
    800051ca:	4705                	li	a4,1
    800051cc:	00f76c63          	bltu	a4,a5,800051e4 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051d0:	8526                	mv	a0,s1
    800051d2:	60a6                	ld	ra,72(sp)
    800051d4:	6406                	ld	s0,64(sp)
    800051d6:	74e2                	ld	s1,56(sp)
    800051d8:	7942                	ld	s2,48(sp)
    800051da:	79a2                	ld	s3,40(sp)
    800051dc:	7a02                	ld	s4,32(sp)
    800051de:	6ae2                	ld	s5,24(sp)
    800051e0:	6161                	addi	sp,sp,80
    800051e2:	8082                	ret
    iunlockput(ip);
    800051e4:	8526                	mv	a0,s1
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	868080e7          	jalr	-1944(ra) # 80003a4e <iunlockput>
    return 0;
    800051ee:	4481                	li	s1,0
    800051f0:	b7c5                	j	800051d0 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051f2:	85ce                	mv	a1,s3
    800051f4:	00092503          	lw	a0,0(s2)
    800051f8:	ffffe097          	auipc	ra,0xffffe
    800051fc:	45c080e7          	jalr	1116(ra) # 80003654 <ialloc>
    80005200:	84aa                	mv	s1,a0
    80005202:	c529                	beqz	a0,8000524c <create+0xee>
  ilock(ip);
    80005204:	ffffe097          	auipc	ra,0xffffe
    80005208:	5e8080e7          	jalr	1512(ra) # 800037ec <ilock>
  ip->major = major;
    8000520c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005210:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005214:	4785                	li	a5,1
    80005216:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000521a:	8526                	mv	a0,s1
    8000521c:	ffffe097          	auipc	ra,0xffffe
    80005220:	506080e7          	jalr	1286(ra) # 80003722 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005224:	2981                	sext.w	s3,s3
    80005226:	4785                	li	a5,1
    80005228:	02f98a63          	beq	s3,a5,8000525c <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000522c:	40d0                	lw	a2,4(s1)
    8000522e:	fb040593          	addi	a1,s0,-80
    80005232:	854a                	mv	a0,s2
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	ca6080e7          	jalr	-858(ra) # 80003eda <dirlink>
    8000523c:	06054b63          	bltz	a0,800052b2 <create+0x154>
  iunlockput(dp);
    80005240:	854a                	mv	a0,s2
    80005242:	fffff097          	auipc	ra,0xfffff
    80005246:	80c080e7          	jalr	-2036(ra) # 80003a4e <iunlockput>
  return ip;
    8000524a:	b759                	j	800051d0 <create+0x72>
    panic("create: ialloc");
    8000524c:	00003517          	auipc	a0,0x3
    80005250:	4bc50513          	addi	a0,a0,1212 # 80008708 <syscalls+0x2c0>
    80005254:	ffffb097          	auipc	ra,0xffffb
    80005258:	3a4080e7          	jalr	932(ra) # 800005f8 <panic>
    dp->nlink++;  // for ".."
    8000525c:	04a95783          	lhu	a5,74(s2)
    80005260:	2785                	addiw	a5,a5,1
    80005262:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005266:	854a                	mv	a0,s2
    80005268:	ffffe097          	auipc	ra,0xffffe
    8000526c:	4ba080e7          	jalr	1210(ra) # 80003722 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005270:	40d0                	lw	a2,4(s1)
    80005272:	00003597          	auipc	a1,0x3
    80005276:	4a658593          	addi	a1,a1,1190 # 80008718 <syscalls+0x2d0>
    8000527a:	8526                	mv	a0,s1
    8000527c:	fffff097          	auipc	ra,0xfffff
    80005280:	c5e080e7          	jalr	-930(ra) # 80003eda <dirlink>
    80005284:	00054f63          	bltz	a0,800052a2 <create+0x144>
    80005288:	00492603          	lw	a2,4(s2)
    8000528c:	00003597          	auipc	a1,0x3
    80005290:	49458593          	addi	a1,a1,1172 # 80008720 <syscalls+0x2d8>
    80005294:	8526                	mv	a0,s1
    80005296:	fffff097          	auipc	ra,0xfffff
    8000529a:	c44080e7          	jalr	-956(ra) # 80003eda <dirlink>
    8000529e:	f80557e3          	bgez	a0,8000522c <create+0xce>
      panic("create dots");
    800052a2:	00003517          	auipc	a0,0x3
    800052a6:	48650513          	addi	a0,a0,1158 # 80008728 <syscalls+0x2e0>
    800052aa:	ffffb097          	auipc	ra,0xffffb
    800052ae:	34e080e7          	jalr	846(ra) # 800005f8 <panic>
    panic("create: dirlink");
    800052b2:	00003517          	auipc	a0,0x3
    800052b6:	48650513          	addi	a0,a0,1158 # 80008738 <syscalls+0x2f0>
    800052ba:	ffffb097          	auipc	ra,0xffffb
    800052be:	33e080e7          	jalr	830(ra) # 800005f8 <panic>
    return 0;
    800052c2:	84aa                	mv	s1,a0
    800052c4:	b731                	j	800051d0 <create+0x72>

00000000800052c6 <sys_dup>:
{
    800052c6:	7179                	addi	sp,sp,-48
    800052c8:	f406                	sd	ra,40(sp)
    800052ca:	f022                	sd	s0,32(sp)
    800052cc:	ec26                	sd	s1,24(sp)
    800052ce:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052d0:	fd840613          	addi	a2,s0,-40
    800052d4:	4581                	li	a1,0
    800052d6:	4501                	li	a0,0
    800052d8:	00000097          	auipc	ra,0x0
    800052dc:	ddc080e7          	jalr	-548(ra) # 800050b4 <argfd>
    return -1;
    800052e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052e2:	02054363          	bltz	a0,80005308 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052e6:	fd843503          	ld	a0,-40(s0)
    800052ea:	00000097          	auipc	ra,0x0
    800052ee:	e32080e7          	jalr	-462(ra) # 8000511c <fdalloc>
    800052f2:	84aa                	mv	s1,a0
    return -1;
    800052f4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052f6:	00054963          	bltz	a0,80005308 <sys_dup+0x42>
  filedup(f);
    800052fa:	fd843503          	ld	a0,-40(s0)
    800052fe:	fffff097          	auipc	ra,0xfffff
    80005302:	32a080e7          	jalr	810(ra) # 80004628 <filedup>
  return fd;
    80005306:	87a6                	mv	a5,s1
}
    80005308:	853e                	mv	a0,a5
    8000530a:	70a2                	ld	ra,40(sp)
    8000530c:	7402                	ld	s0,32(sp)
    8000530e:	64e2                	ld	s1,24(sp)
    80005310:	6145                	addi	sp,sp,48
    80005312:	8082                	ret

0000000080005314 <sys_read>:
{
    80005314:	7179                	addi	sp,sp,-48
    80005316:	f406                	sd	ra,40(sp)
    80005318:	f022                	sd	s0,32(sp)
    8000531a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000531c:	fe840613          	addi	a2,s0,-24
    80005320:	4581                	li	a1,0
    80005322:	4501                	li	a0,0
    80005324:	00000097          	auipc	ra,0x0
    80005328:	d90080e7          	jalr	-624(ra) # 800050b4 <argfd>
    return -1;
    8000532c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000532e:	04054163          	bltz	a0,80005370 <sys_read+0x5c>
    80005332:	fe440593          	addi	a1,s0,-28
    80005336:	4509                	li	a0,2
    80005338:	ffffe097          	auipc	ra,0xffffe
    8000533c:	866080e7          	jalr	-1946(ra) # 80002b9e <argint>
    return -1;
    80005340:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005342:	02054763          	bltz	a0,80005370 <sys_read+0x5c>
    80005346:	fd840593          	addi	a1,s0,-40
    8000534a:	4505                	li	a0,1
    8000534c:	ffffe097          	auipc	ra,0xffffe
    80005350:	874080e7          	jalr	-1932(ra) # 80002bc0 <argaddr>
    return -1;
    80005354:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005356:	00054d63          	bltz	a0,80005370 <sys_read+0x5c>
  return fileread(f, p, n);
    8000535a:	fe442603          	lw	a2,-28(s0)
    8000535e:	fd843583          	ld	a1,-40(s0)
    80005362:	fe843503          	ld	a0,-24(s0)
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	44e080e7          	jalr	1102(ra) # 800047b4 <fileread>
    8000536e:	87aa                	mv	a5,a0
}
    80005370:	853e                	mv	a0,a5
    80005372:	70a2                	ld	ra,40(sp)
    80005374:	7402                	ld	s0,32(sp)
    80005376:	6145                	addi	sp,sp,48
    80005378:	8082                	ret

000000008000537a <sys_write>:
{
    8000537a:	7179                	addi	sp,sp,-48
    8000537c:	f406                	sd	ra,40(sp)
    8000537e:	f022                	sd	s0,32(sp)
    80005380:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005382:	fe840613          	addi	a2,s0,-24
    80005386:	4581                	li	a1,0
    80005388:	4501                	li	a0,0
    8000538a:	00000097          	auipc	ra,0x0
    8000538e:	d2a080e7          	jalr	-726(ra) # 800050b4 <argfd>
    return -1;
    80005392:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005394:	04054163          	bltz	a0,800053d6 <sys_write+0x5c>
    80005398:	fe440593          	addi	a1,s0,-28
    8000539c:	4509                	li	a0,2
    8000539e:	ffffe097          	auipc	ra,0xffffe
    800053a2:	800080e7          	jalr	-2048(ra) # 80002b9e <argint>
    return -1;
    800053a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a8:	02054763          	bltz	a0,800053d6 <sys_write+0x5c>
    800053ac:	fd840593          	addi	a1,s0,-40
    800053b0:	4505                	li	a0,1
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	80e080e7          	jalr	-2034(ra) # 80002bc0 <argaddr>
    return -1;
    800053ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053bc:	00054d63          	bltz	a0,800053d6 <sys_write+0x5c>
  return filewrite(f, p, n);
    800053c0:	fe442603          	lw	a2,-28(s0)
    800053c4:	fd843583          	ld	a1,-40(s0)
    800053c8:	fe843503          	ld	a0,-24(s0)
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	4aa080e7          	jalr	1194(ra) # 80004876 <filewrite>
    800053d4:	87aa                	mv	a5,a0
}
    800053d6:	853e                	mv	a0,a5
    800053d8:	70a2                	ld	ra,40(sp)
    800053da:	7402                	ld	s0,32(sp)
    800053dc:	6145                	addi	sp,sp,48
    800053de:	8082                	ret

00000000800053e0 <sys_close>:
{
    800053e0:	1101                	addi	sp,sp,-32
    800053e2:	ec06                	sd	ra,24(sp)
    800053e4:	e822                	sd	s0,16(sp)
    800053e6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053e8:	fe040613          	addi	a2,s0,-32
    800053ec:	fec40593          	addi	a1,s0,-20
    800053f0:	4501                	li	a0,0
    800053f2:	00000097          	auipc	ra,0x0
    800053f6:	cc2080e7          	jalr	-830(ra) # 800050b4 <argfd>
    return -1;
    800053fa:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053fc:	02054463          	bltz	a0,80005424 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005400:	ffffc097          	auipc	ra,0xffffc
    80005404:	664080e7          	jalr	1636(ra) # 80001a64 <myproc>
    80005408:	fec42783          	lw	a5,-20(s0)
    8000540c:	07e9                	addi	a5,a5,26
    8000540e:	078e                	slli	a5,a5,0x3
    80005410:	97aa                	add	a5,a5,a0
    80005412:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005416:	fe043503          	ld	a0,-32(s0)
    8000541a:	fffff097          	auipc	ra,0xfffff
    8000541e:	260080e7          	jalr	608(ra) # 8000467a <fileclose>
  return 0;
    80005422:	4781                	li	a5,0
}
    80005424:	853e                	mv	a0,a5
    80005426:	60e2                	ld	ra,24(sp)
    80005428:	6442                	ld	s0,16(sp)
    8000542a:	6105                	addi	sp,sp,32
    8000542c:	8082                	ret

000000008000542e <sys_fstat>:
{
    8000542e:	1101                	addi	sp,sp,-32
    80005430:	ec06                	sd	ra,24(sp)
    80005432:	e822                	sd	s0,16(sp)
    80005434:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005436:	fe840613          	addi	a2,s0,-24
    8000543a:	4581                	li	a1,0
    8000543c:	4501                	li	a0,0
    8000543e:	00000097          	auipc	ra,0x0
    80005442:	c76080e7          	jalr	-906(ra) # 800050b4 <argfd>
    return -1;
    80005446:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005448:	02054563          	bltz	a0,80005472 <sys_fstat+0x44>
    8000544c:	fe040593          	addi	a1,s0,-32
    80005450:	4505                	li	a0,1
    80005452:	ffffd097          	auipc	ra,0xffffd
    80005456:	76e080e7          	jalr	1902(ra) # 80002bc0 <argaddr>
    return -1;
    8000545a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000545c:	00054b63          	bltz	a0,80005472 <sys_fstat+0x44>
  return filestat(f, st);
    80005460:	fe043583          	ld	a1,-32(s0)
    80005464:	fe843503          	ld	a0,-24(s0)
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	2da080e7          	jalr	730(ra) # 80004742 <filestat>
    80005470:	87aa                	mv	a5,a0
}
    80005472:	853e                	mv	a0,a5
    80005474:	60e2                	ld	ra,24(sp)
    80005476:	6442                	ld	s0,16(sp)
    80005478:	6105                	addi	sp,sp,32
    8000547a:	8082                	ret

000000008000547c <sys_link>:
{
    8000547c:	7169                	addi	sp,sp,-304
    8000547e:	f606                	sd	ra,296(sp)
    80005480:	f222                	sd	s0,288(sp)
    80005482:	ee26                	sd	s1,280(sp)
    80005484:	ea4a                	sd	s2,272(sp)
    80005486:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005488:	08000613          	li	a2,128
    8000548c:	ed040593          	addi	a1,s0,-304
    80005490:	4501                	li	a0,0
    80005492:	ffffd097          	auipc	ra,0xffffd
    80005496:	750080e7          	jalr	1872(ra) # 80002be2 <argstr>
    return -1;
    8000549a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000549c:	10054e63          	bltz	a0,800055b8 <sys_link+0x13c>
    800054a0:	08000613          	li	a2,128
    800054a4:	f5040593          	addi	a1,s0,-176
    800054a8:	4505                	li	a0,1
    800054aa:	ffffd097          	auipc	ra,0xffffd
    800054ae:	738080e7          	jalr	1848(ra) # 80002be2 <argstr>
    return -1;
    800054b2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054b4:	10054263          	bltz	a0,800055b8 <sys_link+0x13c>
  begin_op();
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	cf0080e7          	jalr	-784(ra) # 800041a8 <begin_op>
  if((ip = namei(old)) == 0){
    800054c0:	ed040513          	addi	a0,s0,-304
    800054c4:	fffff097          	auipc	ra,0xfffff
    800054c8:	ad8080e7          	jalr	-1320(ra) # 80003f9c <namei>
    800054cc:	84aa                	mv	s1,a0
    800054ce:	c551                	beqz	a0,8000555a <sys_link+0xde>
  ilock(ip);
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	31c080e7          	jalr	796(ra) # 800037ec <ilock>
  if(ip->type == T_DIR){
    800054d8:	04449703          	lh	a4,68(s1)
    800054dc:	4785                	li	a5,1
    800054de:	08f70463          	beq	a4,a5,80005566 <sys_link+0xea>
  ip->nlink++;
    800054e2:	04a4d783          	lhu	a5,74(s1)
    800054e6:	2785                	addiw	a5,a5,1
    800054e8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054ec:	8526                	mv	a0,s1
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	234080e7          	jalr	564(ra) # 80003722 <iupdate>
  iunlock(ip);
    800054f6:	8526                	mv	a0,s1
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	3b6080e7          	jalr	950(ra) # 800038ae <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005500:	fd040593          	addi	a1,s0,-48
    80005504:	f5040513          	addi	a0,s0,-176
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	ab2080e7          	jalr	-1358(ra) # 80003fba <nameiparent>
    80005510:	892a                	mv	s2,a0
    80005512:	c935                	beqz	a0,80005586 <sys_link+0x10a>
  ilock(dp);
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	2d8080e7          	jalr	728(ra) # 800037ec <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000551c:	00092703          	lw	a4,0(s2)
    80005520:	409c                	lw	a5,0(s1)
    80005522:	04f71d63          	bne	a4,a5,8000557c <sys_link+0x100>
    80005526:	40d0                	lw	a2,4(s1)
    80005528:	fd040593          	addi	a1,s0,-48
    8000552c:	854a                	mv	a0,s2
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	9ac080e7          	jalr	-1620(ra) # 80003eda <dirlink>
    80005536:	04054363          	bltz	a0,8000557c <sys_link+0x100>
  iunlockput(dp);
    8000553a:	854a                	mv	a0,s2
    8000553c:	ffffe097          	auipc	ra,0xffffe
    80005540:	512080e7          	jalr	1298(ra) # 80003a4e <iunlockput>
  iput(ip);
    80005544:	8526                	mv	a0,s1
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	460080e7          	jalr	1120(ra) # 800039a6 <iput>
  end_op();
    8000554e:	fffff097          	auipc	ra,0xfffff
    80005552:	cda080e7          	jalr	-806(ra) # 80004228 <end_op>
  return 0;
    80005556:	4781                	li	a5,0
    80005558:	a085                	j	800055b8 <sys_link+0x13c>
    end_op();
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	cce080e7          	jalr	-818(ra) # 80004228 <end_op>
    return -1;
    80005562:	57fd                	li	a5,-1
    80005564:	a891                	j	800055b8 <sys_link+0x13c>
    iunlockput(ip);
    80005566:	8526                	mv	a0,s1
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	4e6080e7          	jalr	1254(ra) # 80003a4e <iunlockput>
    end_op();
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	cb8080e7          	jalr	-840(ra) # 80004228 <end_op>
    return -1;
    80005578:	57fd                	li	a5,-1
    8000557a:	a83d                	j	800055b8 <sys_link+0x13c>
    iunlockput(dp);
    8000557c:	854a                	mv	a0,s2
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	4d0080e7          	jalr	1232(ra) # 80003a4e <iunlockput>
  ilock(ip);
    80005586:	8526                	mv	a0,s1
    80005588:	ffffe097          	auipc	ra,0xffffe
    8000558c:	264080e7          	jalr	612(ra) # 800037ec <ilock>
  ip->nlink--;
    80005590:	04a4d783          	lhu	a5,74(s1)
    80005594:	37fd                	addiw	a5,a5,-1
    80005596:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000559a:	8526                	mv	a0,s1
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	186080e7          	jalr	390(ra) # 80003722 <iupdate>
  iunlockput(ip);
    800055a4:	8526                	mv	a0,s1
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	4a8080e7          	jalr	1192(ra) # 80003a4e <iunlockput>
  end_op();
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	c7a080e7          	jalr	-902(ra) # 80004228 <end_op>
  return -1;
    800055b6:	57fd                	li	a5,-1
}
    800055b8:	853e                	mv	a0,a5
    800055ba:	70b2                	ld	ra,296(sp)
    800055bc:	7412                	ld	s0,288(sp)
    800055be:	64f2                	ld	s1,280(sp)
    800055c0:	6952                	ld	s2,272(sp)
    800055c2:	6155                	addi	sp,sp,304
    800055c4:	8082                	ret

00000000800055c6 <sys_unlink>:
{
    800055c6:	7151                	addi	sp,sp,-240
    800055c8:	f586                	sd	ra,232(sp)
    800055ca:	f1a2                	sd	s0,224(sp)
    800055cc:	eda6                	sd	s1,216(sp)
    800055ce:	e9ca                	sd	s2,208(sp)
    800055d0:	e5ce                	sd	s3,200(sp)
    800055d2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055d4:	08000613          	li	a2,128
    800055d8:	f3040593          	addi	a1,s0,-208
    800055dc:	4501                	li	a0,0
    800055de:	ffffd097          	auipc	ra,0xffffd
    800055e2:	604080e7          	jalr	1540(ra) # 80002be2 <argstr>
    800055e6:	18054163          	bltz	a0,80005768 <sys_unlink+0x1a2>
  begin_op();
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	bbe080e7          	jalr	-1090(ra) # 800041a8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055f2:	fb040593          	addi	a1,s0,-80
    800055f6:	f3040513          	addi	a0,s0,-208
    800055fa:	fffff097          	auipc	ra,0xfffff
    800055fe:	9c0080e7          	jalr	-1600(ra) # 80003fba <nameiparent>
    80005602:	84aa                	mv	s1,a0
    80005604:	c979                	beqz	a0,800056da <sys_unlink+0x114>
  ilock(dp);
    80005606:	ffffe097          	auipc	ra,0xffffe
    8000560a:	1e6080e7          	jalr	486(ra) # 800037ec <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000560e:	00003597          	auipc	a1,0x3
    80005612:	10a58593          	addi	a1,a1,266 # 80008718 <syscalls+0x2d0>
    80005616:	fb040513          	addi	a0,s0,-80
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	696080e7          	jalr	1686(ra) # 80003cb0 <namecmp>
    80005622:	14050a63          	beqz	a0,80005776 <sys_unlink+0x1b0>
    80005626:	00003597          	auipc	a1,0x3
    8000562a:	0fa58593          	addi	a1,a1,250 # 80008720 <syscalls+0x2d8>
    8000562e:	fb040513          	addi	a0,s0,-80
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	67e080e7          	jalr	1662(ra) # 80003cb0 <namecmp>
    8000563a:	12050e63          	beqz	a0,80005776 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000563e:	f2c40613          	addi	a2,s0,-212
    80005642:	fb040593          	addi	a1,s0,-80
    80005646:	8526                	mv	a0,s1
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	682080e7          	jalr	1666(ra) # 80003cca <dirlookup>
    80005650:	892a                	mv	s2,a0
    80005652:	12050263          	beqz	a0,80005776 <sys_unlink+0x1b0>
  ilock(ip);
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	196080e7          	jalr	406(ra) # 800037ec <ilock>
  if(ip->nlink < 1)
    8000565e:	04a91783          	lh	a5,74(s2)
    80005662:	08f05263          	blez	a5,800056e6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005666:	04491703          	lh	a4,68(s2)
    8000566a:	4785                	li	a5,1
    8000566c:	08f70563          	beq	a4,a5,800056f6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005670:	4641                	li	a2,16
    80005672:	4581                	li	a1,0
    80005674:	fc040513          	addi	a0,s0,-64
    80005678:	ffffb097          	auipc	ra,0xffffb
    8000567c:	71a080e7          	jalr	1818(ra) # 80000d92 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005680:	4741                	li	a4,16
    80005682:	f2c42683          	lw	a3,-212(s0)
    80005686:	fc040613          	addi	a2,s0,-64
    8000568a:	4581                	li	a1,0
    8000568c:	8526                	mv	a0,s1
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	508080e7          	jalr	1288(ra) # 80003b96 <writei>
    80005696:	47c1                	li	a5,16
    80005698:	0af51563          	bne	a0,a5,80005742 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000569c:	04491703          	lh	a4,68(s2)
    800056a0:	4785                	li	a5,1
    800056a2:	0af70863          	beq	a4,a5,80005752 <sys_unlink+0x18c>
  iunlockput(dp);
    800056a6:	8526                	mv	a0,s1
    800056a8:	ffffe097          	auipc	ra,0xffffe
    800056ac:	3a6080e7          	jalr	934(ra) # 80003a4e <iunlockput>
  ip->nlink--;
    800056b0:	04a95783          	lhu	a5,74(s2)
    800056b4:	37fd                	addiw	a5,a5,-1
    800056b6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056ba:	854a                	mv	a0,s2
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	066080e7          	jalr	102(ra) # 80003722 <iupdate>
  iunlockput(ip);
    800056c4:	854a                	mv	a0,s2
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	388080e7          	jalr	904(ra) # 80003a4e <iunlockput>
  end_op();
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	b5a080e7          	jalr	-1190(ra) # 80004228 <end_op>
  return 0;
    800056d6:	4501                	li	a0,0
    800056d8:	a84d                	j	8000578a <sys_unlink+0x1c4>
    end_op();
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	b4e080e7          	jalr	-1202(ra) # 80004228 <end_op>
    return -1;
    800056e2:	557d                	li	a0,-1
    800056e4:	a05d                	j	8000578a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056e6:	00003517          	auipc	a0,0x3
    800056ea:	06250513          	addi	a0,a0,98 # 80008748 <syscalls+0x300>
    800056ee:	ffffb097          	auipc	ra,0xffffb
    800056f2:	f0a080e7          	jalr	-246(ra) # 800005f8 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056f6:	04c92703          	lw	a4,76(s2)
    800056fa:	02000793          	li	a5,32
    800056fe:	f6e7f9e3          	bgeu	a5,a4,80005670 <sys_unlink+0xaa>
    80005702:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005706:	4741                	li	a4,16
    80005708:	86ce                	mv	a3,s3
    8000570a:	f1840613          	addi	a2,s0,-232
    8000570e:	4581                	li	a1,0
    80005710:	854a                	mv	a0,s2
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	38e080e7          	jalr	910(ra) # 80003aa0 <readi>
    8000571a:	47c1                	li	a5,16
    8000571c:	00f51b63          	bne	a0,a5,80005732 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005720:	f1845783          	lhu	a5,-232(s0)
    80005724:	e7a1                	bnez	a5,8000576c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005726:	29c1                	addiw	s3,s3,16
    80005728:	04c92783          	lw	a5,76(s2)
    8000572c:	fcf9ede3          	bltu	s3,a5,80005706 <sys_unlink+0x140>
    80005730:	b781                	j	80005670 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005732:	00003517          	auipc	a0,0x3
    80005736:	02e50513          	addi	a0,a0,46 # 80008760 <syscalls+0x318>
    8000573a:	ffffb097          	auipc	ra,0xffffb
    8000573e:	ebe080e7          	jalr	-322(ra) # 800005f8 <panic>
    panic("unlink: writei");
    80005742:	00003517          	auipc	a0,0x3
    80005746:	03650513          	addi	a0,a0,54 # 80008778 <syscalls+0x330>
    8000574a:	ffffb097          	auipc	ra,0xffffb
    8000574e:	eae080e7          	jalr	-338(ra) # 800005f8 <panic>
    dp->nlink--;
    80005752:	04a4d783          	lhu	a5,74(s1)
    80005756:	37fd                	addiw	a5,a5,-1
    80005758:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000575c:	8526                	mv	a0,s1
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	fc4080e7          	jalr	-60(ra) # 80003722 <iupdate>
    80005766:	b781                	j	800056a6 <sys_unlink+0xe0>
    return -1;
    80005768:	557d                	li	a0,-1
    8000576a:	a005                	j	8000578a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000576c:	854a                	mv	a0,s2
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	2e0080e7          	jalr	736(ra) # 80003a4e <iunlockput>
  iunlockput(dp);
    80005776:	8526                	mv	a0,s1
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	2d6080e7          	jalr	726(ra) # 80003a4e <iunlockput>
  end_op();
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	aa8080e7          	jalr	-1368(ra) # 80004228 <end_op>
  return -1;
    80005788:	557d                	li	a0,-1
}
    8000578a:	70ae                	ld	ra,232(sp)
    8000578c:	740e                	ld	s0,224(sp)
    8000578e:	64ee                	ld	s1,216(sp)
    80005790:	694e                	ld	s2,208(sp)
    80005792:	69ae                	ld	s3,200(sp)
    80005794:	616d                	addi	sp,sp,240
    80005796:	8082                	ret

0000000080005798 <sys_open>:

uint64
sys_open(void)
{
    80005798:	7131                	addi	sp,sp,-192
    8000579a:	fd06                	sd	ra,184(sp)
    8000579c:	f922                	sd	s0,176(sp)
    8000579e:	f526                	sd	s1,168(sp)
    800057a0:	f14a                	sd	s2,160(sp)
    800057a2:	ed4e                	sd	s3,152(sp)
    800057a4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057a6:	08000613          	li	a2,128
    800057aa:	f5040593          	addi	a1,s0,-176
    800057ae:	4501                	li	a0,0
    800057b0:	ffffd097          	auipc	ra,0xffffd
    800057b4:	432080e7          	jalr	1074(ra) # 80002be2 <argstr>
    return -1;
    800057b8:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057ba:	0c054163          	bltz	a0,8000587c <sys_open+0xe4>
    800057be:	f4c40593          	addi	a1,s0,-180
    800057c2:	4505                	li	a0,1
    800057c4:	ffffd097          	auipc	ra,0xffffd
    800057c8:	3da080e7          	jalr	986(ra) # 80002b9e <argint>
    800057cc:	0a054863          	bltz	a0,8000587c <sys_open+0xe4>

  begin_op();
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	9d8080e7          	jalr	-1576(ra) # 800041a8 <begin_op>

  if(omode & O_CREATE){
    800057d8:	f4c42783          	lw	a5,-180(s0)
    800057dc:	2007f793          	andi	a5,a5,512
    800057e0:	cbdd                	beqz	a5,80005896 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057e2:	4681                	li	a3,0
    800057e4:	4601                	li	a2,0
    800057e6:	4589                	li	a1,2
    800057e8:	f5040513          	addi	a0,s0,-176
    800057ec:	00000097          	auipc	ra,0x0
    800057f0:	972080e7          	jalr	-1678(ra) # 8000515e <create>
    800057f4:	892a                	mv	s2,a0
    if(ip == 0){
    800057f6:	c959                	beqz	a0,8000588c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057f8:	04491703          	lh	a4,68(s2)
    800057fc:	478d                	li	a5,3
    800057fe:	00f71763          	bne	a4,a5,8000580c <sys_open+0x74>
    80005802:	04695703          	lhu	a4,70(s2)
    80005806:	47a5                	li	a5,9
    80005808:	0ce7ec63          	bltu	a5,a4,800058e0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	db2080e7          	jalr	-590(ra) # 800045be <filealloc>
    80005814:	89aa                	mv	s3,a0
    80005816:	10050263          	beqz	a0,8000591a <sys_open+0x182>
    8000581a:	00000097          	auipc	ra,0x0
    8000581e:	902080e7          	jalr	-1790(ra) # 8000511c <fdalloc>
    80005822:	84aa                	mv	s1,a0
    80005824:	0e054663          	bltz	a0,80005910 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005828:	04491703          	lh	a4,68(s2)
    8000582c:	478d                	li	a5,3
    8000582e:	0cf70463          	beq	a4,a5,800058f6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005832:	4789                	li	a5,2
    80005834:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005838:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000583c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005840:	f4c42783          	lw	a5,-180(s0)
    80005844:	0017c713          	xori	a4,a5,1
    80005848:	8b05                	andi	a4,a4,1
    8000584a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000584e:	0037f713          	andi	a4,a5,3
    80005852:	00e03733          	snez	a4,a4
    80005856:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000585a:	4007f793          	andi	a5,a5,1024
    8000585e:	c791                	beqz	a5,8000586a <sys_open+0xd2>
    80005860:	04491703          	lh	a4,68(s2)
    80005864:	4789                	li	a5,2
    80005866:	08f70f63          	beq	a4,a5,80005904 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000586a:	854a                	mv	a0,s2
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	042080e7          	jalr	66(ra) # 800038ae <iunlock>
  end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	9b4080e7          	jalr	-1612(ra) # 80004228 <end_op>

  return fd;
}
    8000587c:	8526                	mv	a0,s1
    8000587e:	70ea                	ld	ra,184(sp)
    80005880:	744a                	ld	s0,176(sp)
    80005882:	74aa                	ld	s1,168(sp)
    80005884:	790a                	ld	s2,160(sp)
    80005886:	69ea                	ld	s3,152(sp)
    80005888:	6129                	addi	sp,sp,192
    8000588a:	8082                	ret
      end_op();
    8000588c:	fffff097          	auipc	ra,0xfffff
    80005890:	99c080e7          	jalr	-1636(ra) # 80004228 <end_op>
      return -1;
    80005894:	b7e5                	j	8000587c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005896:	f5040513          	addi	a0,s0,-176
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	702080e7          	jalr	1794(ra) # 80003f9c <namei>
    800058a2:	892a                	mv	s2,a0
    800058a4:	c905                	beqz	a0,800058d4 <sys_open+0x13c>
    ilock(ip);
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	f46080e7          	jalr	-186(ra) # 800037ec <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058ae:	04491703          	lh	a4,68(s2)
    800058b2:	4785                	li	a5,1
    800058b4:	f4f712e3          	bne	a4,a5,800057f8 <sys_open+0x60>
    800058b8:	f4c42783          	lw	a5,-180(s0)
    800058bc:	dba1                	beqz	a5,8000580c <sys_open+0x74>
      iunlockput(ip);
    800058be:	854a                	mv	a0,s2
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	18e080e7          	jalr	398(ra) # 80003a4e <iunlockput>
      end_op();
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	960080e7          	jalr	-1696(ra) # 80004228 <end_op>
      return -1;
    800058d0:	54fd                	li	s1,-1
    800058d2:	b76d                	j	8000587c <sys_open+0xe4>
      end_op();
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	954080e7          	jalr	-1708(ra) # 80004228 <end_op>
      return -1;
    800058dc:	54fd                	li	s1,-1
    800058de:	bf79                	j	8000587c <sys_open+0xe4>
    iunlockput(ip);
    800058e0:	854a                	mv	a0,s2
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	16c080e7          	jalr	364(ra) # 80003a4e <iunlockput>
    end_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	93e080e7          	jalr	-1730(ra) # 80004228 <end_op>
    return -1;
    800058f2:	54fd                	li	s1,-1
    800058f4:	b761                	j	8000587c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058f6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058fa:	04691783          	lh	a5,70(s2)
    800058fe:	02f99223          	sh	a5,36(s3)
    80005902:	bf2d                	j	8000583c <sys_open+0xa4>
    itrunc(ip);
    80005904:	854a                	mv	a0,s2
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	ff4080e7          	jalr	-12(ra) # 800038fa <itrunc>
    8000590e:	bfb1                	j	8000586a <sys_open+0xd2>
      fileclose(f);
    80005910:	854e                	mv	a0,s3
    80005912:	fffff097          	auipc	ra,0xfffff
    80005916:	d68080e7          	jalr	-664(ra) # 8000467a <fileclose>
    iunlockput(ip);
    8000591a:	854a                	mv	a0,s2
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	132080e7          	jalr	306(ra) # 80003a4e <iunlockput>
    end_op();
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	904080e7          	jalr	-1788(ra) # 80004228 <end_op>
    return -1;
    8000592c:	54fd                	li	s1,-1
    8000592e:	b7b9                	j	8000587c <sys_open+0xe4>

0000000080005930 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005930:	7175                	addi	sp,sp,-144
    80005932:	e506                	sd	ra,136(sp)
    80005934:	e122                	sd	s0,128(sp)
    80005936:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	870080e7          	jalr	-1936(ra) # 800041a8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005940:	08000613          	li	a2,128
    80005944:	f7040593          	addi	a1,s0,-144
    80005948:	4501                	li	a0,0
    8000594a:	ffffd097          	auipc	ra,0xffffd
    8000594e:	298080e7          	jalr	664(ra) # 80002be2 <argstr>
    80005952:	02054963          	bltz	a0,80005984 <sys_mkdir+0x54>
    80005956:	4681                	li	a3,0
    80005958:	4601                	li	a2,0
    8000595a:	4585                	li	a1,1
    8000595c:	f7040513          	addi	a0,s0,-144
    80005960:	fffff097          	auipc	ra,0xfffff
    80005964:	7fe080e7          	jalr	2046(ra) # 8000515e <create>
    80005968:	cd11                	beqz	a0,80005984 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	0e4080e7          	jalr	228(ra) # 80003a4e <iunlockput>
  end_op();
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	8b6080e7          	jalr	-1866(ra) # 80004228 <end_op>
  return 0;
    8000597a:	4501                	li	a0,0
}
    8000597c:	60aa                	ld	ra,136(sp)
    8000597e:	640a                	ld	s0,128(sp)
    80005980:	6149                	addi	sp,sp,144
    80005982:	8082                	ret
    end_op();
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	8a4080e7          	jalr	-1884(ra) # 80004228 <end_op>
    return -1;
    8000598c:	557d                	li	a0,-1
    8000598e:	b7fd                	j	8000597c <sys_mkdir+0x4c>

0000000080005990 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005990:	7135                	addi	sp,sp,-160
    80005992:	ed06                	sd	ra,152(sp)
    80005994:	e922                	sd	s0,144(sp)
    80005996:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	810080e7          	jalr	-2032(ra) # 800041a8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059a0:	08000613          	li	a2,128
    800059a4:	f7040593          	addi	a1,s0,-144
    800059a8:	4501                	li	a0,0
    800059aa:	ffffd097          	auipc	ra,0xffffd
    800059ae:	238080e7          	jalr	568(ra) # 80002be2 <argstr>
    800059b2:	04054a63          	bltz	a0,80005a06 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059b6:	f6c40593          	addi	a1,s0,-148
    800059ba:	4505                	li	a0,1
    800059bc:	ffffd097          	auipc	ra,0xffffd
    800059c0:	1e2080e7          	jalr	482(ra) # 80002b9e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059c4:	04054163          	bltz	a0,80005a06 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059c8:	f6840593          	addi	a1,s0,-152
    800059cc:	4509                	li	a0,2
    800059ce:	ffffd097          	auipc	ra,0xffffd
    800059d2:	1d0080e7          	jalr	464(ra) # 80002b9e <argint>
     argint(1, &major) < 0 ||
    800059d6:	02054863          	bltz	a0,80005a06 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059da:	f6841683          	lh	a3,-152(s0)
    800059de:	f6c41603          	lh	a2,-148(s0)
    800059e2:	458d                	li	a1,3
    800059e4:	f7040513          	addi	a0,s0,-144
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	776080e7          	jalr	1910(ra) # 8000515e <create>
     argint(2, &minor) < 0 ||
    800059f0:	c919                	beqz	a0,80005a06 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	05c080e7          	jalr	92(ra) # 80003a4e <iunlockput>
  end_op();
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	82e080e7          	jalr	-2002(ra) # 80004228 <end_op>
  return 0;
    80005a02:	4501                	li	a0,0
    80005a04:	a031                	j	80005a10 <sys_mknod+0x80>
    end_op();
    80005a06:	fffff097          	auipc	ra,0xfffff
    80005a0a:	822080e7          	jalr	-2014(ra) # 80004228 <end_op>
    return -1;
    80005a0e:	557d                	li	a0,-1
}
    80005a10:	60ea                	ld	ra,152(sp)
    80005a12:	644a                	ld	s0,144(sp)
    80005a14:	610d                	addi	sp,sp,160
    80005a16:	8082                	ret

0000000080005a18 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a18:	7135                	addi	sp,sp,-160
    80005a1a:	ed06                	sd	ra,152(sp)
    80005a1c:	e922                	sd	s0,144(sp)
    80005a1e:	e526                	sd	s1,136(sp)
    80005a20:	e14a                	sd	s2,128(sp)
    80005a22:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a24:	ffffc097          	auipc	ra,0xffffc
    80005a28:	040080e7          	jalr	64(ra) # 80001a64 <myproc>
    80005a2c:	892a                	mv	s2,a0
  
  begin_op();
    80005a2e:	ffffe097          	auipc	ra,0xffffe
    80005a32:	77a080e7          	jalr	1914(ra) # 800041a8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a36:	08000613          	li	a2,128
    80005a3a:	f6040593          	addi	a1,s0,-160
    80005a3e:	4501                	li	a0,0
    80005a40:	ffffd097          	auipc	ra,0xffffd
    80005a44:	1a2080e7          	jalr	418(ra) # 80002be2 <argstr>
    80005a48:	04054b63          	bltz	a0,80005a9e <sys_chdir+0x86>
    80005a4c:	f6040513          	addi	a0,s0,-160
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	54c080e7          	jalr	1356(ra) # 80003f9c <namei>
    80005a58:	84aa                	mv	s1,a0
    80005a5a:	c131                	beqz	a0,80005a9e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	d90080e7          	jalr	-624(ra) # 800037ec <ilock>
  if(ip->type != T_DIR){
    80005a64:	04449703          	lh	a4,68(s1)
    80005a68:	4785                	li	a5,1
    80005a6a:	04f71063          	bne	a4,a5,80005aaa <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a6e:	8526                	mv	a0,s1
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	e3e080e7          	jalr	-450(ra) # 800038ae <iunlock>
  iput(p->cwd);
    80005a78:	15093503          	ld	a0,336(s2)
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	f2a080e7          	jalr	-214(ra) # 800039a6 <iput>
  end_op();
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	7a4080e7          	jalr	1956(ra) # 80004228 <end_op>
  p->cwd = ip;
    80005a8c:	14993823          	sd	s1,336(s2)
  return 0;
    80005a90:	4501                	li	a0,0
}
    80005a92:	60ea                	ld	ra,152(sp)
    80005a94:	644a                	ld	s0,144(sp)
    80005a96:	64aa                	ld	s1,136(sp)
    80005a98:	690a                	ld	s2,128(sp)
    80005a9a:	610d                	addi	sp,sp,160
    80005a9c:	8082                	ret
    end_op();
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	78a080e7          	jalr	1930(ra) # 80004228 <end_op>
    return -1;
    80005aa6:	557d                	li	a0,-1
    80005aa8:	b7ed                	j	80005a92 <sys_chdir+0x7a>
    iunlockput(ip);
    80005aaa:	8526                	mv	a0,s1
    80005aac:	ffffe097          	auipc	ra,0xffffe
    80005ab0:	fa2080e7          	jalr	-94(ra) # 80003a4e <iunlockput>
    end_op();
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	774080e7          	jalr	1908(ra) # 80004228 <end_op>
    return -1;
    80005abc:	557d                	li	a0,-1
    80005abe:	bfd1                	j	80005a92 <sys_chdir+0x7a>

0000000080005ac0 <sys_exec>:

uint64
sys_exec(void)
{
    80005ac0:	7145                	addi	sp,sp,-464
    80005ac2:	e786                	sd	ra,456(sp)
    80005ac4:	e3a2                	sd	s0,448(sp)
    80005ac6:	ff26                	sd	s1,440(sp)
    80005ac8:	fb4a                	sd	s2,432(sp)
    80005aca:	f74e                	sd	s3,424(sp)
    80005acc:	f352                	sd	s4,416(sp)
    80005ace:	ef56                	sd	s5,408(sp)
    80005ad0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ad2:	08000613          	li	a2,128
    80005ad6:	f4040593          	addi	a1,s0,-192
    80005ada:	4501                	li	a0,0
    80005adc:	ffffd097          	auipc	ra,0xffffd
    80005ae0:	106080e7          	jalr	262(ra) # 80002be2 <argstr>
    return -1;
    80005ae4:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ae6:	0c054a63          	bltz	a0,80005bba <sys_exec+0xfa>
    80005aea:	e3840593          	addi	a1,s0,-456
    80005aee:	4505                	li	a0,1
    80005af0:	ffffd097          	auipc	ra,0xffffd
    80005af4:	0d0080e7          	jalr	208(ra) # 80002bc0 <argaddr>
    80005af8:	0c054163          	bltz	a0,80005bba <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005afc:	10000613          	li	a2,256
    80005b00:	4581                	li	a1,0
    80005b02:	e4040513          	addi	a0,s0,-448
    80005b06:	ffffb097          	auipc	ra,0xffffb
    80005b0a:	28c080e7          	jalr	652(ra) # 80000d92 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b0e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b12:	89a6                	mv	s3,s1
    80005b14:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b16:	02000a13          	li	s4,32
    80005b1a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b1e:	00391513          	slli	a0,s2,0x3
    80005b22:	e3040593          	addi	a1,s0,-464
    80005b26:	e3843783          	ld	a5,-456(s0)
    80005b2a:	953e                	add	a0,a0,a5
    80005b2c:	ffffd097          	auipc	ra,0xffffd
    80005b30:	fd8080e7          	jalr	-40(ra) # 80002b04 <fetchaddr>
    80005b34:	02054a63          	bltz	a0,80005b68 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b38:	e3043783          	ld	a5,-464(s0)
    80005b3c:	c3b9                	beqz	a5,80005b82 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b3e:	ffffb097          	auipc	ra,0xffffb
    80005b42:	068080e7          	jalr	104(ra) # 80000ba6 <kalloc>
    80005b46:	85aa                	mv	a1,a0
    80005b48:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b4c:	cd11                	beqz	a0,80005b68 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b4e:	6605                	lui	a2,0x1
    80005b50:	e3043503          	ld	a0,-464(s0)
    80005b54:	ffffd097          	auipc	ra,0xffffd
    80005b58:	002080e7          	jalr	2(ra) # 80002b56 <fetchstr>
    80005b5c:	00054663          	bltz	a0,80005b68 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b60:	0905                	addi	s2,s2,1
    80005b62:	09a1                	addi	s3,s3,8
    80005b64:	fb491be3          	bne	s2,s4,80005b1a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b68:	10048913          	addi	s2,s1,256
    80005b6c:	6088                	ld	a0,0(s1)
    80005b6e:	c529                	beqz	a0,80005bb8 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b70:	ffffb097          	auipc	ra,0xffffb
    80005b74:	f3a080e7          	jalr	-198(ra) # 80000aaa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b78:	04a1                	addi	s1,s1,8
    80005b7a:	ff2499e3          	bne	s1,s2,80005b6c <sys_exec+0xac>
  return -1;
    80005b7e:	597d                	li	s2,-1
    80005b80:	a82d                	j	80005bba <sys_exec+0xfa>
      argv[i] = 0;
    80005b82:	0a8e                	slli	s5,s5,0x3
    80005b84:	fc040793          	addi	a5,s0,-64
    80005b88:	9abe                	add	s5,s5,a5
    80005b8a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b8e:	e4040593          	addi	a1,s0,-448
    80005b92:	f4040513          	addi	a0,s0,-192
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	194080e7          	jalr	404(ra) # 80004d2a <exec>
    80005b9e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ba0:	10048993          	addi	s3,s1,256
    80005ba4:	6088                	ld	a0,0(s1)
    80005ba6:	c911                	beqz	a0,80005bba <sys_exec+0xfa>
    kfree(argv[i]);
    80005ba8:	ffffb097          	auipc	ra,0xffffb
    80005bac:	f02080e7          	jalr	-254(ra) # 80000aaa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bb0:	04a1                	addi	s1,s1,8
    80005bb2:	ff3499e3          	bne	s1,s3,80005ba4 <sys_exec+0xe4>
    80005bb6:	a011                	j	80005bba <sys_exec+0xfa>
  return -1;
    80005bb8:	597d                	li	s2,-1
}
    80005bba:	854a                	mv	a0,s2
    80005bbc:	60be                	ld	ra,456(sp)
    80005bbe:	641e                	ld	s0,448(sp)
    80005bc0:	74fa                	ld	s1,440(sp)
    80005bc2:	795a                	ld	s2,432(sp)
    80005bc4:	79ba                	ld	s3,424(sp)
    80005bc6:	7a1a                	ld	s4,416(sp)
    80005bc8:	6afa                	ld	s5,408(sp)
    80005bca:	6179                	addi	sp,sp,464
    80005bcc:	8082                	ret

0000000080005bce <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bce:	7139                	addi	sp,sp,-64
    80005bd0:	fc06                	sd	ra,56(sp)
    80005bd2:	f822                	sd	s0,48(sp)
    80005bd4:	f426                	sd	s1,40(sp)
    80005bd6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bd8:	ffffc097          	auipc	ra,0xffffc
    80005bdc:	e8c080e7          	jalr	-372(ra) # 80001a64 <myproc>
    80005be0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005be2:	fd840593          	addi	a1,s0,-40
    80005be6:	4501                	li	a0,0
    80005be8:	ffffd097          	auipc	ra,0xffffd
    80005bec:	fd8080e7          	jalr	-40(ra) # 80002bc0 <argaddr>
    return -1;
    80005bf0:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005bf2:	0e054063          	bltz	a0,80005cd2 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005bf6:	fc840593          	addi	a1,s0,-56
    80005bfa:	fd040513          	addi	a0,s0,-48
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	dd2080e7          	jalr	-558(ra) # 800049d0 <pipealloc>
    return -1;
    80005c06:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c08:	0c054563          	bltz	a0,80005cd2 <sys_pipe+0x104>
  fd0 = -1;
    80005c0c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c10:	fd043503          	ld	a0,-48(s0)
    80005c14:	fffff097          	auipc	ra,0xfffff
    80005c18:	508080e7          	jalr	1288(ra) # 8000511c <fdalloc>
    80005c1c:	fca42223          	sw	a0,-60(s0)
    80005c20:	08054c63          	bltz	a0,80005cb8 <sys_pipe+0xea>
    80005c24:	fc843503          	ld	a0,-56(s0)
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	4f4080e7          	jalr	1268(ra) # 8000511c <fdalloc>
    80005c30:	fca42023          	sw	a0,-64(s0)
    80005c34:	06054863          	bltz	a0,80005ca4 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c38:	4691                	li	a3,4
    80005c3a:	fc440613          	addi	a2,s0,-60
    80005c3e:	fd843583          	ld	a1,-40(s0)
    80005c42:	68a8                	ld	a0,80(s1)
    80005c44:	ffffc097          	auipc	ra,0xffffc
    80005c48:	b14080e7          	jalr	-1260(ra) # 80001758 <copyout>
    80005c4c:	02054063          	bltz	a0,80005c6c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c50:	4691                	li	a3,4
    80005c52:	fc040613          	addi	a2,s0,-64
    80005c56:	fd843583          	ld	a1,-40(s0)
    80005c5a:	0591                	addi	a1,a1,4
    80005c5c:	68a8                	ld	a0,80(s1)
    80005c5e:	ffffc097          	auipc	ra,0xffffc
    80005c62:	afa080e7          	jalr	-1286(ra) # 80001758 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c66:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c68:	06055563          	bgez	a0,80005cd2 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c6c:	fc442783          	lw	a5,-60(s0)
    80005c70:	07e9                	addi	a5,a5,26
    80005c72:	078e                	slli	a5,a5,0x3
    80005c74:	97a6                	add	a5,a5,s1
    80005c76:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c7a:	fc042503          	lw	a0,-64(s0)
    80005c7e:	0569                	addi	a0,a0,26
    80005c80:	050e                	slli	a0,a0,0x3
    80005c82:	9526                	add	a0,a0,s1
    80005c84:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c88:	fd043503          	ld	a0,-48(s0)
    80005c8c:	fffff097          	auipc	ra,0xfffff
    80005c90:	9ee080e7          	jalr	-1554(ra) # 8000467a <fileclose>
    fileclose(wf);
    80005c94:	fc843503          	ld	a0,-56(s0)
    80005c98:	fffff097          	auipc	ra,0xfffff
    80005c9c:	9e2080e7          	jalr	-1566(ra) # 8000467a <fileclose>
    return -1;
    80005ca0:	57fd                	li	a5,-1
    80005ca2:	a805                	j	80005cd2 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ca4:	fc442783          	lw	a5,-60(s0)
    80005ca8:	0007c863          	bltz	a5,80005cb8 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005cac:	01a78513          	addi	a0,a5,26
    80005cb0:	050e                	slli	a0,a0,0x3
    80005cb2:	9526                	add	a0,a0,s1
    80005cb4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cb8:	fd043503          	ld	a0,-48(s0)
    80005cbc:	fffff097          	auipc	ra,0xfffff
    80005cc0:	9be080e7          	jalr	-1602(ra) # 8000467a <fileclose>
    fileclose(wf);
    80005cc4:	fc843503          	ld	a0,-56(s0)
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	9b2080e7          	jalr	-1614(ra) # 8000467a <fileclose>
    return -1;
    80005cd0:	57fd                	li	a5,-1
}
    80005cd2:	853e                	mv	a0,a5
    80005cd4:	70e2                	ld	ra,56(sp)
    80005cd6:	7442                	ld	s0,48(sp)
    80005cd8:	74a2                	ld	s1,40(sp)
    80005cda:	6121                	addi	sp,sp,64
    80005cdc:	8082                	ret
	...

0000000080005ce0 <kernelvec>:
    80005ce0:	7111                	addi	sp,sp,-256
    80005ce2:	e006                	sd	ra,0(sp)
    80005ce4:	e40a                	sd	sp,8(sp)
    80005ce6:	e80e                	sd	gp,16(sp)
    80005ce8:	ec12                	sd	tp,24(sp)
    80005cea:	f016                	sd	t0,32(sp)
    80005cec:	f41a                	sd	t1,40(sp)
    80005cee:	f81e                	sd	t2,48(sp)
    80005cf0:	fc22                	sd	s0,56(sp)
    80005cf2:	e0a6                	sd	s1,64(sp)
    80005cf4:	e4aa                	sd	a0,72(sp)
    80005cf6:	e8ae                	sd	a1,80(sp)
    80005cf8:	ecb2                	sd	a2,88(sp)
    80005cfa:	f0b6                	sd	a3,96(sp)
    80005cfc:	f4ba                	sd	a4,104(sp)
    80005cfe:	f8be                	sd	a5,112(sp)
    80005d00:	fcc2                	sd	a6,120(sp)
    80005d02:	e146                	sd	a7,128(sp)
    80005d04:	e54a                	sd	s2,136(sp)
    80005d06:	e94e                	sd	s3,144(sp)
    80005d08:	ed52                	sd	s4,152(sp)
    80005d0a:	f156                	sd	s5,160(sp)
    80005d0c:	f55a                	sd	s6,168(sp)
    80005d0e:	f95e                	sd	s7,176(sp)
    80005d10:	fd62                	sd	s8,184(sp)
    80005d12:	e1e6                	sd	s9,192(sp)
    80005d14:	e5ea                	sd	s10,200(sp)
    80005d16:	e9ee                	sd	s11,208(sp)
    80005d18:	edf2                	sd	t3,216(sp)
    80005d1a:	f1f6                	sd	t4,224(sp)
    80005d1c:	f5fa                	sd	t5,232(sp)
    80005d1e:	f9fe                	sd	t6,240(sp)
    80005d20:	cb1fc0ef          	jal	ra,800029d0 <kerneltrap>
    80005d24:	6082                	ld	ra,0(sp)
    80005d26:	6122                	ld	sp,8(sp)
    80005d28:	61c2                	ld	gp,16(sp)
    80005d2a:	7282                	ld	t0,32(sp)
    80005d2c:	7322                	ld	t1,40(sp)
    80005d2e:	73c2                	ld	t2,48(sp)
    80005d30:	7462                	ld	s0,56(sp)
    80005d32:	6486                	ld	s1,64(sp)
    80005d34:	6526                	ld	a0,72(sp)
    80005d36:	65c6                	ld	a1,80(sp)
    80005d38:	6666                	ld	a2,88(sp)
    80005d3a:	7686                	ld	a3,96(sp)
    80005d3c:	7726                	ld	a4,104(sp)
    80005d3e:	77c6                	ld	a5,112(sp)
    80005d40:	7866                	ld	a6,120(sp)
    80005d42:	688a                	ld	a7,128(sp)
    80005d44:	692a                	ld	s2,136(sp)
    80005d46:	69ca                	ld	s3,144(sp)
    80005d48:	6a6a                	ld	s4,152(sp)
    80005d4a:	7a8a                	ld	s5,160(sp)
    80005d4c:	7b2a                	ld	s6,168(sp)
    80005d4e:	7bca                	ld	s7,176(sp)
    80005d50:	7c6a                	ld	s8,184(sp)
    80005d52:	6c8e                	ld	s9,192(sp)
    80005d54:	6d2e                	ld	s10,200(sp)
    80005d56:	6dce                	ld	s11,208(sp)
    80005d58:	6e6e                	ld	t3,216(sp)
    80005d5a:	7e8e                	ld	t4,224(sp)
    80005d5c:	7f2e                	ld	t5,232(sp)
    80005d5e:	7fce                	ld	t6,240(sp)
    80005d60:	6111                	addi	sp,sp,256
    80005d62:	10200073          	sret
    80005d66:	00000013          	nop
    80005d6a:	00000013          	nop
    80005d6e:	0001                	nop

0000000080005d70 <timervec>:
    80005d70:	34051573          	csrrw	a0,mscratch,a0
    80005d74:	e10c                	sd	a1,0(a0)
    80005d76:	e510                	sd	a2,8(a0)
    80005d78:	e914                	sd	a3,16(a0)
    80005d7a:	710c                	ld	a1,32(a0)
    80005d7c:	7510                	ld	a2,40(a0)
    80005d7e:	6194                	ld	a3,0(a1)
    80005d80:	96b2                	add	a3,a3,a2
    80005d82:	e194                	sd	a3,0(a1)
    80005d84:	4589                	li	a1,2
    80005d86:	14459073          	csrw	sip,a1
    80005d8a:	6914                	ld	a3,16(a0)
    80005d8c:	6510                	ld	a2,8(a0)
    80005d8e:	610c                	ld	a1,0(a0)
    80005d90:	34051573          	csrrw	a0,mscratch,a0
    80005d94:	30200073          	mret
	...

0000000080005d9a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d9a:	1141                	addi	sp,sp,-16
    80005d9c:	e422                	sd	s0,8(sp)
    80005d9e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005da0:	0c0007b7          	lui	a5,0xc000
    80005da4:	4705                	li	a4,1
    80005da6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005da8:	c3d8                	sw	a4,4(a5)
}
    80005daa:	6422                	ld	s0,8(sp)
    80005dac:	0141                	addi	sp,sp,16
    80005dae:	8082                	ret

0000000080005db0 <plicinithart>:

void
plicinithart(void)
{
    80005db0:	1141                	addi	sp,sp,-16
    80005db2:	e406                	sd	ra,8(sp)
    80005db4:	e022                	sd	s0,0(sp)
    80005db6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	c80080e7          	jalr	-896(ra) # 80001a38 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005dc0:	0085171b          	slliw	a4,a0,0x8
    80005dc4:	0c0027b7          	lui	a5,0xc002
    80005dc8:	97ba                	add	a5,a5,a4
    80005dca:	40200713          	li	a4,1026
    80005dce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005dd2:	00d5151b          	slliw	a0,a0,0xd
    80005dd6:	0c2017b7          	lui	a5,0xc201
    80005dda:	953e                	add	a0,a0,a5
    80005ddc:	00052023          	sw	zero,0(a0)
}
    80005de0:	60a2                	ld	ra,8(sp)
    80005de2:	6402                	ld	s0,0(sp)
    80005de4:	0141                	addi	sp,sp,16
    80005de6:	8082                	ret

0000000080005de8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005de8:	1141                	addi	sp,sp,-16
    80005dea:	e406                	sd	ra,8(sp)
    80005dec:	e022                	sd	s0,0(sp)
    80005dee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005df0:	ffffc097          	auipc	ra,0xffffc
    80005df4:	c48080e7          	jalr	-952(ra) # 80001a38 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005df8:	00d5179b          	slliw	a5,a0,0xd
    80005dfc:	0c201537          	lui	a0,0xc201
    80005e00:	953e                	add	a0,a0,a5
  return irq;
}
    80005e02:	4148                	lw	a0,4(a0)
    80005e04:	60a2                	ld	ra,8(sp)
    80005e06:	6402                	ld	s0,0(sp)
    80005e08:	0141                	addi	sp,sp,16
    80005e0a:	8082                	ret

0000000080005e0c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e0c:	1101                	addi	sp,sp,-32
    80005e0e:	ec06                	sd	ra,24(sp)
    80005e10:	e822                	sd	s0,16(sp)
    80005e12:	e426                	sd	s1,8(sp)
    80005e14:	1000                	addi	s0,sp,32
    80005e16:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e18:	ffffc097          	auipc	ra,0xffffc
    80005e1c:	c20080e7          	jalr	-992(ra) # 80001a38 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e20:	00d5151b          	slliw	a0,a0,0xd
    80005e24:	0c2017b7          	lui	a5,0xc201
    80005e28:	97aa                	add	a5,a5,a0
    80005e2a:	c3c4                	sw	s1,4(a5)
}
    80005e2c:	60e2                	ld	ra,24(sp)
    80005e2e:	6442                	ld	s0,16(sp)
    80005e30:	64a2                	ld	s1,8(sp)
    80005e32:	6105                	addi	sp,sp,32
    80005e34:	8082                	ret

0000000080005e36 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e36:	1141                	addi	sp,sp,-16
    80005e38:	e406                	sd	ra,8(sp)
    80005e3a:	e022                	sd	s0,0(sp)
    80005e3c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e3e:	479d                	li	a5,7
    80005e40:	04a7cc63          	blt	a5,a0,80005e98 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005e44:	00022797          	auipc	a5,0x22
    80005e48:	1bc78793          	addi	a5,a5,444 # 80028000 <disk>
    80005e4c:	00a78733          	add	a4,a5,a0
    80005e50:	6789                	lui	a5,0x2
    80005e52:	97ba                	add	a5,a5,a4
    80005e54:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e58:	eba1                	bnez	a5,80005ea8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005e5a:	00451713          	slli	a4,a0,0x4
    80005e5e:	00024797          	auipc	a5,0x24
    80005e62:	1a27b783          	ld	a5,418(a5) # 8002a000 <disk+0x2000>
    80005e66:	97ba                	add	a5,a5,a4
    80005e68:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005e6c:	00022797          	auipc	a5,0x22
    80005e70:	19478793          	addi	a5,a5,404 # 80028000 <disk>
    80005e74:	97aa                	add	a5,a5,a0
    80005e76:	6509                	lui	a0,0x2
    80005e78:	953e                	add	a0,a0,a5
    80005e7a:	4785                	li	a5,1
    80005e7c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e80:	00024517          	auipc	a0,0x24
    80005e84:	19850513          	addi	a0,a0,408 # 8002a018 <disk+0x2018>
    80005e88:	ffffc097          	auipc	ra,0xffffc
    80005e8c:	586080e7          	jalr	1414(ra) # 8000240e <wakeup>
}
    80005e90:	60a2                	ld	ra,8(sp)
    80005e92:	6402                	ld	s0,0(sp)
    80005e94:	0141                	addi	sp,sp,16
    80005e96:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e98:	00003517          	auipc	a0,0x3
    80005e9c:	8f050513          	addi	a0,a0,-1808 # 80008788 <syscalls+0x340>
    80005ea0:	ffffa097          	auipc	ra,0xffffa
    80005ea4:	758080e7          	jalr	1880(ra) # 800005f8 <panic>
    panic("virtio_disk_intr 2");
    80005ea8:	00003517          	auipc	a0,0x3
    80005eac:	8f850513          	addi	a0,a0,-1800 # 800087a0 <syscalls+0x358>
    80005eb0:	ffffa097          	auipc	ra,0xffffa
    80005eb4:	748080e7          	jalr	1864(ra) # 800005f8 <panic>

0000000080005eb8 <virtio_disk_init>:
{
    80005eb8:	1101                	addi	sp,sp,-32
    80005eba:	ec06                	sd	ra,24(sp)
    80005ebc:	e822                	sd	s0,16(sp)
    80005ebe:	e426                	sd	s1,8(sp)
    80005ec0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ec2:	00003597          	auipc	a1,0x3
    80005ec6:	8f658593          	addi	a1,a1,-1802 # 800087b8 <syscalls+0x370>
    80005eca:	00024517          	auipc	a0,0x24
    80005ece:	1de50513          	addi	a0,a0,478 # 8002a0a8 <disk+0x20a8>
    80005ed2:	ffffb097          	auipc	ra,0xffffb
    80005ed6:	d34080e7          	jalr	-716(ra) # 80000c06 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eda:	100017b7          	lui	a5,0x10001
    80005ede:	4398                	lw	a4,0(a5)
    80005ee0:	2701                	sext.w	a4,a4
    80005ee2:	747277b7          	lui	a5,0x74727
    80005ee6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005eea:	0ef71163          	bne	a4,a5,80005fcc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005eee:	100017b7          	lui	a5,0x10001
    80005ef2:	43dc                	lw	a5,4(a5)
    80005ef4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ef6:	4705                	li	a4,1
    80005ef8:	0ce79a63          	bne	a5,a4,80005fcc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005efc:	100017b7          	lui	a5,0x10001
    80005f00:	479c                	lw	a5,8(a5)
    80005f02:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f04:	4709                	li	a4,2
    80005f06:	0ce79363          	bne	a5,a4,80005fcc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f0a:	100017b7          	lui	a5,0x10001
    80005f0e:	47d8                	lw	a4,12(a5)
    80005f10:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f12:	554d47b7          	lui	a5,0x554d4
    80005f16:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f1a:	0af71963          	bne	a4,a5,80005fcc <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f1e:	100017b7          	lui	a5,0x10001
    80005f22:	4705                	li	a4,1
    80005f24:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f26:	470d                	li	a4,3
    80005f28:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f2a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f2c:	c7ffe737          	lui	a4,0xc7ffe
    80005f30:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd375f>
    80005f34:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f36:	2701                	sext.w	a4,a4
    80005f38:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f3a:	472d                	li	a4,11
    80005f3c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f3e:	473d                	li	a4,15
    80005f40:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f42:	6705                	lui	a4,0x1
    80005f44:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f46:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f4a:	5bdc                	lw	a5,52(a5)
    80005f4c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f4e:	c7d9                	beqz	a5,80005fdc <virtio_disk_init+0x124>
  if(max < NUM)
    80005f50:	471d                	li	a4,7
    80005f52:	08f77d63          	bgeu	a4,a5,80005fec <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f56:	100014b7          	lui	s1,0x10001
    80005f5a:	47a1                	li	a5,8
    80005f5c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f5e:	6609                	lui	a2,0x2
    80005f60:	4581                	li	a1,0
    80005f62:	00022517          	auipc	a0,0x22
    80005f66:	09e50513          	addi	a0,a0,158 # 80028000 <disk>
    80005f6a:	ffffb097          	auipc	ra,0xffffb
    80005f6e:	e28080e7          	jalr	-472(ra) # 80000d92 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f72:	00022717          	auipc	a4,0x22
    80005f76:	08e70713          	addi	a4,a4,142 # 80028000 <disk>
    80005f7a:	00c75793          	srli	a5,a4,0xc
    80005f7e:	2781                	sext.w	a5,a5
    80005f80:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005f82:	00024797          	auipc	a5,0x24
    80005f86:	07e78793          	addi	a5,a5,126 # 8002a000 <disk+0x2000>
    80005f8a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005f8c:	00022717          	auipc	a4,0x22
    80005f90:	0f470713          	addi	a4,a4,244 # 80028080 <disk+0x80>
    80005f94:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f96:	00023717          	auipc	a4,0x23
    80005f9a:	06a70713          	addi	a4,a4,106 # 80029000 <disk+0x1000>
    80005f9e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fa0:	4705                	li	a4,1
    80005fa2:	00e78c23          	sb	a4,24(a5)
    80005fa6:	00e78ca3          	sb	a4,25(a5)
    80005faa:	00e78d23          	sb	a4,26(a5)
    80005fae:	00e78da3          	sb	a4,27(a5)
    80005fb2:	00e78e23          	sb	a4,28(a5)
    80005fb6:	00e78ea3          	sb	a4,29(a5)
    80005fba:	00e78f23          	sb	a4,30(a5)
    80005fbe:	00e78fa3          	sb	a4,31(a5)
}
    80005fc2:	60e2                	ld	ra,24(sp)
    80005fc4:	6442                	ld	s0,16(sp)
    80005fc6:	64a2                	ld	s1,8(sp)
    80005fc8:	6105                	addi	sp,sp,32
    80005fca:	8082                	ret
    panic("could not find virtio disk");
    80005fcc:	00002517          	auipc	a0,0x2
    80005fd0:	7fc50513          	addi	a0,a0,2044 # 800087c8 <syscalls+0x380>
    80005fd4:	ffffa097          	auipc	ra,0xffffa
    80005fd8:	624080e7          	jalr	1572(ra) # 800005f8 <panic>
    panic("virtio disk has no queue 0");
    80005fdc:	00003517          	auipc	a0,0x3
    80005fe0:	80c50513          	addi	a0,a0,-2036 # 800087e8 <syscalls+0x3a0>
    80005fe4:	ffffa097          	auipc	ra,0xffffa
    80005fe8:	614080e7          	jalr	1556(ra) # 800005f8 <panic>
    panic("virtio disk max queue too short");
    80005fec:	00003517          	auipc	a0,0x3
    80005ff0:	81c50513          	addi	a0,a0,-2020 # 80008808 <syscalls+0x3c0>
    80005ff4:	ffffa097          	auipc	ra,0xffffa
    80005ff8:	604080e7          	jalr	1540(ra) # 800005f8 <panic>

0000000080005ffc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005ffc:	7119                	addi	sp,sp,-128
    80005ffe:	fc86                	sd	ra,120(sp)
    80006000:	f8a2                	sd	s0,112(sp)
    80006002:	f4a6                	sd	s1,104(sp)
    80006004:	f0ca                	sd	s2,96(sp)
    80006006:	ecce                	sd	s3,88(sp)
    80006008:	e8d2                	sd	s4,80(sp)
    8000600a:	e4d6                	sd	s5,72(sp)
    8000600c:	e0da                	sd	s6,64(sp)
    8000600e:	fc5e                	sd	s7,56(sp)
    80006010:	f862                	sd	s8,48(sp)
    80006012:	f466                	sd	s9,40(sp)
    80006014:	f06a                	sd	s10,32(sp)
    80006016:	0100                	addi	s0,sp,128
    80006018:	892a                	mv	s2,a0
    8000601a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000601c:	00c52c83          	lw	s9,12(a0)
    80006020:	001c9c9b          	slliw	s9,s9,0x1
    80006024:	1c82                	slli	s9,s9,0x20
    80006026:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000602a:	00024517          	auipc	a0,0x24
    8000602e:	07e50513          	addi	a0,a0,126 # 8002a0a8 <disk+0x20a8>
    80006032:	ffffb097          	auipc	ra,0xffffb
    80006036:	c64080e7          	jalr	-924(ra) # 80000c96 <acquire>
  for(int i = 0; i < 3; i++){
    8000603a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000603c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000603e:	00022b97          	auipc	s7,0x22
    80006042:	fc2b8b93          	addi	s7,s7,-62 # 80028000 <disk>
    80006046:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006048:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000604a:	8a4e                	mv	s4,s3
    8000604c:	a051                	j	800060d0 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000604e:	00fb86b3          	add	a3,s7,a5
    80006052:	96da                	add	a3,a3,s6
    80006054:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006058:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000605a:	0207c563          	bltz	a5,80006084 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000605e:	2485                	addiw	s1,s1,1
    80006060:	0711                	addi	a4,a4,4
    80006062:	23548d63          	beq	s1,s5,8000629c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006066:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006068:	00024697          	auipc	a3,0x24
    8000606c:	fb068693          	addi	a3,a3,-80 # 8002a018 <disk+0x2018>
    80006070:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006072:	0006c583          	lbu	a1,0(a3)
    80006076:	fde1                	bnez	a1,8000604e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006078:	2785                	addiw	a5,a5,1
    8000607a:	0685                	addi	a3,a3,1
    8000607c:	ff879be3          	bne	a5,s8,80006072 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006080:	57fd                	li	a5,-1
    80006082:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006084:	02905a63          	blez	s1,800060b8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006088:	f9042503          	lw	a0,-112(s0)
    8000608c:	00000097          	auipc	ra,0x0
    80006090:	daa080e7          	jalr	-598(ra) # 80005e36 <free_desc>
      for(int j = 0; j < i; j++)
    80006094:	4785                	li	a5,1
    80006096:	0297d163          	bge	a5,s1,800060b8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000609a:	f9442503          	lw	a0,-108(s0)
    8000609e:	00000097          	auipc	ra,0x0
    800060a2:	d98080e7          	jalr	-616(ra) # 80005e36 <free_desc>
      for(int j = 0; j < i; j++)
    800060a6:	4789                	li	a5,2
    800060a8:	0097d863          	bge	a5,s1,800060b8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060ac:	f9842503          	lw	a0,-104(s0)
    800060b0:	00000097          	auipc	ra,0x0
    800060b4:	d86080e7          	jalr	-634(ra) # 80005e36 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060b8:	00024597          	auipc	a1,0x24
    800060bc:	ff058593          	addi	a1,a1,-16 # 8002a0a8 <disk+0x20a8>
    800060c0:	00024517          	auipc	a0,0x24
    800060c4:	f5850513          	addi	a0,a0,-168 # 8002a018 <disk+0x2018>
    800060c8:	ffffc097          	auipc	ra,0xffffc
    800060cc:	1c0080e7          	jalr	448(ra) # 80002288 <sleep>
  for(int i = 0; i < 3; i++){
    800060d0:	f9040713          	addi	a4,s0,-112
    800060d4:	84ce                	mv	s1,s3
    800060d6:	bf41                	j	80006066 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    800060d8:	4785                	li	a5,1
    800060da:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    800060de:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    800060e2:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800060e6:	f9042983          	lw	s3,-112(s0)
    800060ea:	00499493          	slli	s1,s3,0x4
    800060ee:	00024a17          	auipc	s4,0x24
    800060f2:	f12a0a13          	addi	s4,s4,-238 # 8002a000 <disk+0x2000>
    800060f6:	000a3a83          	ld	s5,0(s4)
    800060fa:	9aa6                	add	s5,s5,s1
    800060fc:	f8040513          	addi	a0,s0,-128
    80006100:	ffffb097          	auipc	ra,0xffffb
    80006104:	066080e7          	jalr	102(ra) # 80001166 <kvmpa>
    80006108:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000610c:	000a3783          	ld	a5,0(s4)
    80006110:	97a6                	add	a5,a5,s1
    80006112:	4741                	li	a4,16
    80006114:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006116:	000a3783          	ld	a5,0(s4)
    8000611a:	97a6                	add	a5,a5,s1
    8000611c:	4705                	li	a4,1
    8000611e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006122:	f9442703          	lw	a4,-108(s0)
    80006126:	000a3783          	ld	a5,0(s4)
    8000612a:	97a6                	add	a5,a5,s1
    8000612c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006130:	0712                	slli	a4,a4,0x4
    80006132:	000a3783          	ld	a5,0(s4)
    80006136:	97ba                	add	a5,a5,a4
    80006138:	05890693          	addi	a3,s2,88
    8000613c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000613e:	000a3783          	ld	a5,0(s4)
    80006142:	97ba                	add	a5,a5,a4
    80006144:	40000693          	li	a3,1024
    80006148:	c794                	sw	a3,8(a5)
  if(write)
    8000614a:	100d0a63          	beqz	s10,8000625e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000614e:	00024797          	auipc	a5,0x24
    80006152:	eb27b783          	ld	a5,-334(a5) # 8002a000 <disk+0x2000>
    80006156:	97ba                	add	a5,a5,a4
    80006158:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000615c:	00022517          	auipc	a0,0x22
    80006160:	ea450513          	addi	a0,a0,-348 # 80028000 <disk>
    80006164:	00024797          	auipc	a5,0x24
    80006168:	e9c78793          	addi	a5,a5,-356 # 8002a000 <disk+0x2000>
    8000616c:	6394                	ld	a3,0(a5)
    8000616e:	96ba                	add	a3,a3,a4
    80006170:	00c6d603          	lhu	a2,12(a3)
    80006174:	00166613          	ori	a2,a2,1
    80006178:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000617c:	f9842683          	lw	a3,-104(s0)
    80006180:	6390                	ld	a2,0(a5)
    80006182:	9732                	add	a4,a4,a2
    80006184:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006188:	20098613          	addi	a2,s3,512
    8000618c:	0612                	slli	a2,a2,0x4
    8000618e:	962a                	add	a2,a2,a0
    80006190:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006194:	00469713          	slli	a4,a3,0x4
    80006198:	6394                	ld	a3,0(a5)
    8000619a:	96ba                	add	a3,a3,a4
    8000619c:	6589                	lui	a1,0x2
    8000619e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800061a2:	94ae                	add	s1,s1,a1
    800061a4:	94aa                	add	s1,s1,a0
    800061a6:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800061a8:	6394                	ld	a3,0(a5)
    800061aa:	96ba                	add	a3,a3,a4
    800061ac:	4585                	li	a1,1
    800061ae:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061b0:	6394                	ld	a3,0(a5)
    800061b2:	96ba                	add	a3,a3,a4
    800061b4:	4509                	li	a0,2
    800061b6:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800061ba:	6394                	ld	a3,0(a5)
    800061bc:	9736                	add	a4,a4,a3
    800061be:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061c2:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800061c6:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800061ca:	6794                	ld	a3,8(a5)
    800061cc:	0026d703          	lhu	a4,2(a3)
    800061d0:	8b1d                	andi	a4,a4,7
    800061d2:	2709                	addiw	a4,a4,2
    800061d4:	0706                	slli	a4,a4,0x1
    800061d6:	9736                	add	a4,a4,a3
    800061d8:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    800061dc:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800061e0:	6798                	ld	a4,8(a5)
    800061e2:	00275783          	lhu	a5,2(a4)
    800061e6:	2785                	addiw	a5,a5,1
    800061e8:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061ec:	100017b7          	lui	a5,0x10001
    800061f0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061f4:	00492703          	lw	a4,4(s2)
    800061f8:	4785                	li	a5,1
    800061fa:	02f71163          	bne	a4,a5,8000621c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    800061fe:	00024997          	auipc	s3,0x24
    80006202:	eaa98993          	addi	s3,s3,-342 # 8002a0a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006206:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006208:	85ce                	mv	a1,s3
    8000620a:	854a                	mv	a0,s2
    8000620c:	ffffc097          	auipc	ra,0xffffc
    80006210:	07c080e7          	jalr	124(ra) # 80002288 <sleep>
  while(b->disk == 1) {
    80006214:	00492783          	lw	a5,4(s2)
    80006218:	fe9788e3          	beq	a5,s1,80006208 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000621c:	f9042483          	lw	s1,-112(s0)
    80006220:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006224:	00479713          	slli	a4,a5,0x4
    80006228:	00022797          	auipc	a5,0x22
    8000622c:	dd878793          	addi	a5,a5,-552 # 80028000 <disk>
    80006230:	97ba                	add	a5,a5,a4
    80006232:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006236:	00024917          	auipc	s2,0x24
    8000623a:	dca90913          	addi	s2,s2,-566 # 8002a000 <disk+0x2000>
    free_desc(i);
    8000623e:	8526                	mv	a0,s1
    80006240:	00000097          	auipc	ra,0x0
    80006244:	bf6080e7          	jalr	-1034(ra) # 80005e36 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006248:	0492                	slli	s1,s1,0x4
    8000624a:	00093783          	ld	a5,0(s2)
    8000624e:	94be                	add	s1,s1,a5
    80006250:	00c4d783          	lhu	a5,12(s1)
    80006254:	8b85                	andi	a5,a5,1
    80006256:	cf89                	beqz	a5,80006270 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006258:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000625c:	b7cd                	j	8000623e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000625e:	00024797          	auipc	a5,0x24
    80006262:	da27b783          	ld	a5,-606(a5) # 8002a000 <disk+0x2000>
    80006266:	97ba                	add	a5,a5,a4
    80006268:	4689                	li	a3,2
    8000626a:	00d79623          	sh	a3,12(a5)
    8000626e:	b5fd                	j	8000615c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006270:	00024517          	auipc	a0,0x24
    80006274:	e3850513          	addi	a0,a0,-456 # 8002a0a8 <disk+0x20a8>
    80006278:	ffffb097          	auipc	ra,0xffffb
    8000627c:	ad2080e7          	jalr	-1326(ra) # 80000d4a <release>
}
    80006280:	70e6                	ld	ra,120(sp)
    80006282:	7446                	ld	s0,112(sp)
    80006284:	74a6                	ld	s1,104(sp)
    80006286:	7906                	ld	s2,96(sp)
    80006288:	69e6                	ld	s3,88(sp)
    8000628a:	6a46                	ld	s4,80(sp)
    8000628c:	6aa6                	ld	s5,72(sp)
    8000628e:	6b06                	ld	s6,64(sp)
    80006290:	7be2                	ld	s7,56(sp)
    80006292:	7c42                	ld	s8,48(sp)
    80006294:	7ca2                	ld	s9,40(sp)
    80006296:	7d02                	ld	s10,32(sp)
    80006298:	6109                	addi	sp,sp,128
    8000629a:	8082                	ret
  if(write)
    8000629c:	e20d1ee3          	bnez	s10,800060d8 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800062a0:	f8042023          	sw	zero,-128(s0)
    800062a4:	bd2d                	j	800060de <virtio_disk_rw+0xe2>

00000000800062a6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062a6:	1101                	addi	sp,sp,-32
    800062a8:	ec06                	sd	ra,24(sp)
    800062aa:	e822                	sd	s0,16(sp)
    800062ac:	e426                	sd	s1,8(sp)
    800062ae:	e04a                	sd	s2,0(sp)
    800062b0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062b2:	00024517          	auipc	a0,0x24
    800062b6:	df650513          	addi	a0,a0,-522 # 8002a0a8 <disk+0x20a8>
    800062ba:	ffffb097          	auipc	ra,0xffffb
    800062be:	9dc080e7          	jalr	-1572(ra) # 80000c96 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062c2:	00024717          	auipc	a4,0x24
    800062c6:	d3e70713          	addi	a4,a4,-706 # 8002a000 <disk+0x2000>
    800062ca:	02075783          	lhu	a5,32(a4)
    800062ce:	6b18                	ld	a4,16(a4)
    800062d0:	00275683          	lhu	a3,2(a4)
    800062d4:	8ebd                	xor	a3,a3,a5
    800062d6:	8a9d                	andi	a3,a3,7
    800062d8:	cab9                	beqz	a3,8000632e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800062da:	00022917          	auipc	s2,0x22
    800062de:	d2690913          	addi	s2,s2,-730 # 80028000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062e2:	00024497          	auipc	s1,0x24
    800062e6:	d1e48493          	addi	s1,s1,-738 # 8002a000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800062ea:	078e                	slli	a5,a5,0x3
    800062ec:	97ba                	add	a5,a5,a4
    800062ee:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800062f0:	20078713          	addi	a4,a5,512
    800062f4:	0712                	slli	a4,a4,0x4
    800062f6:	974a                	add	a4,a4,s2
    800062f8:	03074703          	lbu	a4,48(a4)
    800062fc:	ef21                	bnez	a4,80006354 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800062fe:	20078793          	addi	a5,a5,512
    80006302:	0792                	slli	a5,a5,0x4
    80006304:	97ca                	add	a5,a5,s2
    80006306:	7798                	ld	a4,40(a5)
    80006308:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000630c:	7788                	ld	a0,40(a5)
    8000630e:	ffffc097          	auipc	ra,0xffffc
    80006312:	100080e7          	jalr	256(ra) # 8000240e <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006316:	0204d783          	lhu	a5,32(s1)
    8000631a:	2785                	addiw	a5,a5,1
    8000631c:	8b9d                	andi	a5,a5,7
    8000631e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006322:	6898                	ld	a4,16(s1)
    80006324:	00275683          	lhu	a3,2(a4)
    80006328:	8a9d                	andi	a3,a3,7
    8000632a:	fcf690e3          	bne	a3,a5,800062ea <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000632e:	10001737          	lui	a4,0x10001
    80006332:	533c                	lw	a5,96(a4)
    80006334:	8b8d                	andi	a5,a5,3
    80006336:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006338:	00024517          	auipc	a0,0x24
    8000633c:	d7050513          	addi	a0,a0,-656 # 8002a0a8 <disk+0x20a8>
    80006340:	ffffb097          	auipc	ra,0xffffb
    80006344:	a0a080e7          	jalr	-1526(ra) # 80000d4a <release>
}
    80006348:	60e2                	ld	ra,24(sp)
    8000634a:	6442                	ld	s0,16(sp)
    8000634c:	64a2                	ld	s1,8(sp)
    8000634e:	6902                	ld	s2,0(sp)
    80006350:	6105                	addi	sp,sp,32
    80006352:	8082                	ret
      panic("virtio_disk_intr status");
    80006354:	00002517          	auipc	a0,0x2
    80006358:	4d450513          	addi	a0,a0,1236 # 80008828 <syscalls+0x3e0>
    8000635c:	ffffa097          	auipc	ra,0xffffa
    80006360:	29c080e7          	jalr	668(ra) # 800005f8 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
