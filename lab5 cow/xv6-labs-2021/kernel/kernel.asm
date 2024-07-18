
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
    80000060:	f0478793          	addi	a5,a5,-252 # 80005f60 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	f8e78793          	addi	a5,a5,-114 # 80001034 <main>
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
    80000110:	c7a080e7          	jalr	-902(ra) # 80000d86 <acquire>
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
    8000012a:	5da080e7          	jalr	1498(ra) # 80002700 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	cec080e7          	jalr	-788(ra) # 80000e3a <release>

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
    800001a2:	be8080e7          	jalr	-1048(ra) # 80000d86 <acquire>
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
    800001d2:	a6a080e7          	jalr	-1430(ra) # 80001c38 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	26a080e7          	jalr	618(ra) # 80002448 <sleep>
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
    8000021e:	490080e7          	jalr	1168(ra) # 800026aa <either_copyout>
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
    8000023a:	c04080e7          	jalr	-1020(ra) # 80000e3a <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	bee080e7          	jalr	-1042(ra) # 80000e3a <release>
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
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
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
    800002e2:	aa8080e7          	jalr	-1368(ra) # 80000d86 <acquire>

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
    80000300:	45a080e7          	jalr	1114(ra) # 80002756 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	b2e080e7          	jalr	-1234(ra) # 80000e3a <release>
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
    80000454:	17e080e7          	jalr	382(ra) # 800025ce <wakeup>
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
    80000472:	00001097          	auipc	ra,0x1
    80000476:	884080e7          	jalr	-1916(ra) # 80000cf6 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	54e78793          	addi	a5,a5,1358 # 800219d0 <devsw>
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
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
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

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	dda50513          	addi	a0,a0,-550 # 80008350 <states.1710+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	77c080e7          	jalr	1916(ra) # 80000d86 <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	6cc080e7          	jalr	1740(ra) # 80000e3a <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	562080e7          	jalr	1378(ra) # 80000cf6 <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	50c080e7          	jalr	1292(ra) # 80000cf6 <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	534080e7          	jalr	1332(ra) # 80000d3a <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	5a2080e7          	jalr	1442(ra) # 80000dda <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	d18080e7          	jalr	-744(ra) # 800025ce <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	48c080e7          	jalr	1164(ra) # 80000d86 <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	af8080e7          	jalr	-1288(ra) # 80002448 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	4a6080e7          	jalr	1190(ra) # 80000e3a <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	386080e7          	jalr	902(ra) # 80000d86 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	428080e7          	jalr	1064(ra) # 80000e3a <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	efd1                	bnez	a5,80000ad0 <kfree+0xac>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00025797          	auipc	a5,0x25
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80026000 <end>
    80000a40:	08f56863          	bltu	a0,a5,80000ad0 <kfree+0xac>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	08f57463          	bgeu	a0,a5,80000ad0 <kfree+0xac>
    panic("kfree");
//释放内存时查看引用计数是否为0，为0释放内存，否则返回，由其他进程继续使用
  acquire(&kmem.lock);
    80000a4c:	00011917          	auipc	s2,0x11
    80000a50:	ee490913          	addi	s2,s2,-284 # 80011930 <kmem>
    80000a54:	854a                	mv	a0,s2
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	330080e7          	jalr	816(ra) # 80000d86 <acquire>
   return ((char*)pa - (char*)PGROUNDUP((uint64)end)) >> 12;
    80000a5e:	00026797          	auipc	a5,0x26
    80000a62:	5a178793          	addi	a5,a5,1441 # 80026fff <end+0xfff>
    80000a66:	777d                	lui	a4,0xfffff
    80000a68:	8ff9                	and	a5,a5,a4
    80000a6a:	40f487b3          	sub	a5,s1,a5
    80000a6e:	87b1                	srai	a5,a5,0xc
  if(--kmem.ref_count[kgetrefindex(pa)])
    80000a70:	2781                	sext.w	a5,a5
    80000a72:	078a                	slli	a5,a5,0x2
    80000a74:	03893703          	ld	a4,56(s2)
    80000a78:	97ba                	add	a5,a5,a4
    80000a7a:	4398                	lw	a4,0(a5)
    80000a7c:	377d                	addiw	a4,a4,-1
    80000a7e:	0007069b          	sext.w	a3,a4
    80000a82:	c398                	sw	a4,0(a5)
    80000a84:	eeb1                	bnez	a3,80000ae0 <kfree+0xbc>
  {
    release(&kmem.lock);
    return;
  }
  release(&kmem.lock);
    80000a86:	00011917          	auipc	s2,0x11
    80000a8a:	eaa90913          	addi	s2,s2,-342 # 80011930 <kmem>
    80000a8e:	854a                	mv	a0,s2
    80000a90:	00000097          	auipc	ra,0x0
    80000a94:	3aa080e7          	jalr	938(ra) # 80000e3a <release>

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a98:	6605                	lui	a2,0x1
    80000a9a:	4585                	li	a1,1
    80000a9c:	8526                	mv	a0,s1
    80000a9e:	00000097          	auipc	ra,0x0
    80000aa2:	3e4080e7          	jalr	996(ra) # 80000e82 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000aa6:	854a                	mv	a0,s2
    80000aa8:	00000097          	auipc	ra,0x0
    80000aac:	2de080e7          	jalr	734(ra) # 80000d86 <acquire>
  r->next = kmem.freelist;
    80000ab0:	01893783          	ld	a5,24(s2)
    80000ab4:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000ab6:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000aba:	854a                	mv	a0,s2
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	37e080e7          	jalr	894(ra) # 80000e3a <release>
}
    80000ac4:	60e2                	ld	ra,24(sp)
    80000ac6:	6442                	ld	s0,16(sp)
    80000ac8:	64a2                	ld	s1,8(sp)
    80000aca:	6902                	ld	s2,0(sp)
    80000acc:	6105                	addi	sp,sp,32
    80000ace:	8082                	ret
    panic("kfree");
    80000ad0:	00007517          	auipc	a0,0x7
    80000ad4:	59050513          	addi	a0,a0,1424 # 80008060 <digits+0x20>
    80000ad8:	00000097          	auipc	ra,0x0
    80000adc:	a70080e7          	jalr	-1424(ra) # 80000548 <panic>
    release(&kmem.lock);
    80000ae0:	854a                	mv	a0,s2
    80000ae2:	00000097          	auipc	ra,0x0
    80000ae6:	358080e7          	jalr	856(ra) # 80000e3a <release>
    return;
    80000aea:	bfe9                	j	80000ac4 <kfree+0xa0>

0000000080000aec <freerange>:
{
    80000aec:	715d                	addi	sp,sp,-80
    80000aee:	e486                	sd	ra,72(sp)
    80000af0:	e0a2                	sd	s0,64(sp)
    80000af2:	fc26                	sd	s1,56(sp)
    80000af4:	f84a                	sd	s2,48(sp)
    80000af6:	f44e                	sd	s3,40(sp)
    80000af8:	f052                	sd	s4,32(sp)
    80000afa:	ec56                	sd	s5,24(sp)
    80000afc:	e85a                	sd	s6,16(sp)
    80000afe:	e45e                	sd	s7,8(sp)
    80000b00:	0880                	addi	s0,sp,80
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b02:	6785                	lui	a5,0x1
    80000b04:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b08:	94aa                	add	s1,s1,a0
    80000b0a:	757d                	lui	a0,0xfffff
    80000b0c:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
    80000b0e:	94be                	add	s1,s1,a5
    80000b10:	0495e363          	bltu	a1,s1,80000b56 <freerange+0x6a>
    80000b14:	892e                	mv	s2,a1
    80000b16:	7a7d                	lui	s4,0xfffff
     kmem.ref_count[kgetrefindex((void *)p)] = 1;
    80000b18:	00011b97          	auipc	s7,0x11
    80000b1c:	e18b8b93          	addi	s7,s7,-488 # 80011930 <kmem>
   return ((char*)pa - (char*)PGROUNDUP((uint64)end)) >> 12;
    80000b20:	6b05                	lui	s6,0x1
    80000b22:	00026997          	auipc	s3,0x26
    80000b26:	4dd98993          	addi	s3,s3,1245 # 80026fff <end+0xfff>
    80000b2a:	0149f9b3          	and	s3,s3,s4
     kmem.ref_count[kgetrefindex((void *)p)] = 1;
    80000b2e:	4a85                	li	s5,1
    80000b30:	01448533          	add	a0,s1,s4
   return ((char*)pa - (char*)PGROUNDUP((uint64)end)) >> 12;
    80000b34:	413507b3          	sub	a5,a0,s3
    80000b38:	87b1                	srai	a5,a5,0xc
     kmem.ref_count[kgetrefindex((void *)p)] = 1;
    80000b3a:	2781                	sext.w	a5,a5
    80000b3c:	038bb703          	ld	a4,56(s7)
    80000b40:	078a                	slli	a5,a5,0x2
    80000b42:	97ba                	add	a5,a5,a4
    80000b44:	0157a023          	sw	s5,0(a5)
    kfree(p);
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	edc080e7          	jalr	-292(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
    80000b50:	94da                	add	s1,s1,s6
    80000b52:	fc997fe3          	bgeu	s2,s1,80000b30 <freerange+0x44>
}
    80000b56:	60a6                	ld	ra,72(sp)
    80000b58:	6406                	ld	s0,64(sp)
    80000b5a:	74e2                	ld	s1,56(sp)
    80000b5c:	7942                	ld	s2,48(sp)
    80000b5e:	79a2                	ld	s3,40(sp)
    80000b60:	7a02                	ld	s4,32(sp)
    80000b62:	6ae2                	ld	s5,24(sp)
    80000b64:	6b42                	ld	s6,16(sp)
    80000b66:	6ba2                	ld	s7,8(sp)
    80000b68:	6161                	addi	sp,sp,80
    80000b6a:	8082                	ret

0000000080000b6c <kinit>:
{
    80000b6c:	1101                	addi	sp,sp,-32
    80000b6e:	ec06                	sd	ra,24(sp)
    80000b70:	e822                	sd	s0,16(sp)
    80000b72:	e426                	sd	s1,8(sp)
    80000b74:	1000                	addi	s0,sp,32
  initlock(&kmem.lock, "kmem");// 初始化内存分配器的锁
    80000b76:	00011497          	auipc	s1,0x11
    80000b7a:	dba48493          	addi	s1,s1,-582 # 80011930 <kmem>
    80000b7e:	00007597          	auipc	a1,0x7
    80000b82:	4ea58593          	addi	a1,a1,1258 # 80008068 <digits+0x28>
    80000b86:	8526                	mv	a0,s1
    80000b88:	00000097          	auipc	ra,0x0
    80000b8c:	16e080e7          	jalr	366(ra) # 80000cf6 <initlock>
  initlock(&kmem.reflock,"kmemref");// 初始化页面引用计数器的锁
    80000b90:	00007597          	auipc	a1,0x7
    80000b94:	4e058593          	addi	a1,a1,1248 # 80008070 <digits+0x30>
    80000b98:	00011517          	auipc	a0,0x11
    80000b9c:	db850513          	addi	a0,a0,-584 # 80011950 <kmem+0x20>
    80000ba0:	00000097          	auipc	ra,0x0
    80000ba4:	156080e7          	jalr	342(ra) # 80000cf6 <initlock>
  uint64 rc_pages = ((PHYSTOP - (uint64)end) >> 12) +1; // 物理页数
    80000ba8:	45c5                	li	a1,17
    80000baa:	05ee                	slli	a1,a1,0x1b
    80000bac:	00025517          	auipc	a0,0x25
    80000bb0:	45450513          	addi	a0,a0,1108 # 80026000 <end>
    80000bb4:	40a587b3          	sub	a5,a1,a0
    80000bb8:	83b1                	srli	a5,a5,0xc
    80000bba:	0785                	addi	a5,a5,1
  rc_pages = ((rc_pages * sizeof(uint)) >> 12) + 1;// 计算引用计数器占用的页数
    80000bbc:	83a9                	srli	a5,a5,0xa
  kmem.ref_count = (uint*)end;//将存放引用计数器的起始地址设置为 end，即内核之后的第一个可用内存单元地址
    80000bbe:	fc88                	sd	a0,56(s1)
  rc_pages = ((rc_pages * sizeof(uint)) >> 12) + 1;// 计算引用计数器占用的页数
    80000bc0:	0785                	addi	a5,a5,1
  uint64 rc_offset = rc_pages << 12;  // 计算引用计数器存储空间大小
    80000bc2:	07b2                	slli	a5,a5,0xc
  freerange(end + rc_offset, (void*)PHYSTOP);// 调用freerange函数初始化空闲链表
    80000bc4:	953e                	add	a0,a0,a5
    80000bc6:	00000097          	auipc	ra,0x0
    80000bca:	f26080e7          	jalr	-218(ra) # 80000aec <freerange>
}
    80000bce:	60e2                	ld	ra,24(sp)
    80000bd0:	6442                	ld	s0,16(sp)
    80000bd2:	64a2                	ld	s1,8(sp)
    80000bd4:	6105                	addi	sp,sp,32
    80000bd6:	8082                	ret

0000000080000bd8 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000bd8:	1101                	addi	sp,sp,-32
    80000bda:	ec06                	sd	ra,24(sp)
    80000bdc:	e822                	sd	s0,16(sp)
    80000bde:	e426                	sd	s1,8(sp)
    80000be0:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000be2:	00011497          	auipc	s1,0x11
    80000be6:	d4e48493          	addi	s1,s1,-690 # 80011930 <kmem>
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	19a080e7          	jalr	410(ra) # 80000d86 <acquire>
  r = kmem.freelist;
    80000bf4:	6c84                	ld	s1,24(s1)
  if (r)
    80000bf6:	c4b9                	beqz	s1,80000c44 <kalloc+0x6c>
  {
    kmem.freelist = r->next;
    80000bf8:	609c                	ld	a5,0(s1)
    80000bfa:	00011517          	auipc	a0,0x11
    80000bfe:	d3650513          	addi	a0,a0,-714 # 80011930 <kmem>
    80000c02:	ed1c                	sd	a5,24(a0)
   return ((char*)pa - (char*)PGROUNDUP((uint64)end)) >> 12;
    80000c04:	00026797          	auipc	a5,0x26
    80000c08:	3fb78793          	addi	a5,a5,1019 # 80026fff <end+0xfff>
    80000c0c:	777d                	lui	a4,0xfffff
    80000c0e:	8ff9                	and	a5,a5,a4
    80000c10:	40f487b3          	sub	a5,s1,a5
    80000c14:	87b1                	srai	a5,a5,0xc
    kmem.ref_count[kgetrefindex((void *)r)]=1;//在分配页面时将引用计数器设置为1
    80000c16:	2781                	sext.w	a5,a5
    80000c18:	7d18                	ld	a4,56(a0)
    80000c1a:	078a                	slli	a5,a5,0x2
    80000c1c:	97ba                	add	a5,a5,a4
    80000c1e:	4705                	li	a4,1
    80000c20:	c398                	sw	a4,0(a5)
  }
  release(&kmem.lock);
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	218080e7          	jalr	536(ra) # 80000e3a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000c2a:	6605                	lui	a2,0x1
    80000c2c:	4595                	li	a1,5
    80000c2e:	8526                	mv	a0,s1
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	252080e7          	jalr	594(ra) # 80000e82 <memset>
  return (void*)r;
}
    80000c38:	8526                	mv	a0,s1
    80000c3a:	60e2                	ld	ra,24(sp)
    80000c3c:	6442                	ld	s0,16(sp)
    80000c3e:	64a2                	ld	s1,8(sp)
    80000c40:	6105                	addi	sp,sp,32
    80000c42:	8082                	ret
  release(&kmem.lock);
    80000c44:	00011517          	auipc	a0,0x11
    80000c48:	cec50513          	addi	a0,a0,-788 # 80011930 <kmem>
    80000c4c:	00000097          	auipc	ra,0x0
    80000c50:	1ee080e7          	jalr	494(ra) # 80000e3a <release>
  if(r)
    80000c54:	b7d5                	j	80000c38 <kalloc+0x60>

0000000080000c56 <kgetref>:
//辅助函数
int kgetref(void *pa)
{//获取给定物理地址 pa 对应的引用计数
    80000c56:	1141                	addi	sp,sp,-16
    80000c58:	e422                	sd	s0,8(sp)
    80000c5a:	0800                	addi	s0,sp,16
   return ((char*)pa - (char*)PGROUNDUP((uint64)end)) >> 12;
    80000c5c:	00026797          	auipc	a5,0x26
    80000c60:	3a378793          	addi	a5,a5,931 # 80026fff <end+0xfff>
    80000c64:	777d                	lui	a4,0xfffff
    80000c66:	8ff9                	and	a5,a5,a4
    80000c68:	40f507b3          	sub	a5,a0,a5
    80000c6c:	87b1                	srai	a5,a5,0xc
  return kmem.ref_count[kgetrefindex(pa)];
    80000c6e:	2781                	sext.w	a5,a5
    80000c70:	078a                	slli	a5,a5,0x2
    80000c72:	00011717          	auipc	a4,0x11
    80000c76:	cf673703          	ld	a4,-778(a4) # 80011968 <kmem+0x38>
    80000c7a:	97ba                	add	a5,a5,a4
}
    80000c7c:	4388                	lw	a0,0(a5)
    80000c7e:	6422                	ld	s0,8(sp)
    80000c80:	0141                	addi	sp,sp,16
    80000c82:	8082                	ret

0000000080000c84 <kaddref>:

void kaddref(void *pa)
{//给给定的物理地址 pa 对应的引用计数加一
    80000c84:	1141                	addi	sp,sp,-16
    80000c86:	e422                	sd	s0,8(sp)
    80000c88:	0800                	addi	s0,sp,16
   return ((char*)pa - (char*)PGROUNDUP((uint64)end)) >> 12;
    80000c8a:	00026797          	auipc	a5,0x26
    80000c8e:	37578793          	addi	a5,a5,885 # 80026fff <end+0xfff>
    80000c92:	777d                	lui	a4,0xfffff
    80000c94:	8ff9                	and	a5,a5,a4
    80000c96:	40f507b3          	sub	a5,a0,a5
    80000c9a:	87b1                	srai	a5,a5,0xc
  kmem.ref_count[kgetrefindex(pa)]++;
    80000c9c:	2781                	sext.w	a5,a5
    80000c9e:	078a                	slli	a5,a5,0x2
    80000ca0:	00011717          	auipc	a4,0x11
    80000ca4:	cc873703          	ld	a4,-824(a4) # 80011968 <kmem+0x38>
    80000ca8:	97ba                	add	a5,a5,a4
    80000caa:	4398                	lw	a4,0(a5)
    80000cac:	2705                	addiw	a4,a4,1
    80000cae:	c398                	sw	a4,0(a5)
}
    80000cb0:	6422                	ld	s0,8(sp)
    80000cb2:	0141                	addi	sp,sp,16
    80000cb4:	8082                	ret

0000000080000cb6 <acquire_refcnt>:

inline void
acquire_refcnt()
{//获取页面引用计数器的锁
    80000cb6:	1141                	addi	sp,sp,-16
    80000cb8:	e406                	sd	ra,8(sp)
    80000cba:	e022                	sd	s0,0(sp)
    80000cbc:	0800                	addi	s0,sp,16
  acquire(&kmem.reflock);
    80000cbe:	00011517          	auipc	a0,0x11
    80000cc2:	c9250513          	addi	a0,a0,-878 # 80011950 <kmem+0x20>
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	0c0080e7          	jalr	192(ra) # 80000d86 <acquire>
}
    80000cce:	60a2                	ld	ra,8(sp)
    80000cd0:	6402                	ld	s0,0(sp)
    80000cd2:	0141                	addi	sp,sp,16
    80000cd4:	8082                	ret

0000000080000cd6 <release_refcnt>:

inline void
release_refcnt()
{//释放之前获取的页面引用计数器的锁
    80000cd6:	1141                	addi	sp,sp,-16
    80000cd8:	e406                	sd	ra,8(sp)
    80000cda:	e022                	sd	s0,0(sp)
    80000cdc:	0800                	addi	s0,sp,16
  release(&kmem.reflock);
    80000cde:	00011517          	auipc	a0,0x11
    80000ce2:	c7250513          	addi	a0,a0,-910 # 80011950 <kmem+0x20>
    80000ce6:	00000097          	auipc	ra,0x0
    80000cea:	154080e7          	jalr	340(ra) # 80000e3a <release>
    80000cee:	60a2                	ld	ra,8(sp)
    80000cf0:	6402                	ld	s0,0(sp)
    80000cf2:	0141                	addi	sp,sp,16
    80000cf4:	8082                	ret

0000000080000cf6 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000cf6:	1141                	addi	sp,sp,-16
    80000cf8:	e422                	sd	s0,8(sp)
    80000cfa:	0800                	addi	s0,sp,16
  lk->name = name;
    80000cfc:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000cfe:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000d02:	00053823          	sd	zero,16(a0)
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000d0c:	411c                	lw	a5,0(a0)
    80000d0e:	e399                	bnez	a5,80000d14 <holding+0x8>
    80000d10:	4501                	li	a0,0
  return r;
}
    80000d12:	8082                	ret
{
    80000d14:	1101                	addi	sp,sp,-32
    80000d16:	ec06                	sd	ra,24(sp)
    80000d18:	e822                	sd	s0,16(sp)
    80000d1a:	e426                	sd	s1,8(sp)
    80000d1c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000d1e:	6904                	ld	s1,16(a0)
    80000d20:	00001097          	auipc	ra,0x1
    80000d24:	efc080e7          	jalr	-260(ra) # 80001c1c <mycpu>
    80000d28:	40a48533          	sub	a0,s1,a0
    80000d2c:	00153513          	seqz	a0,a0
}
    80000d30:	60e2                	ld	ra,24(sp)
    80000d32:	6442                	ld	s0,16(sp)
    80000d34:	64a2                	ld	s1,8(sp)
    80000d36:	6105                	addi	sp,sp,32
    80000d38:	8082                	ret

0000000080000d3a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d3a:	1101                	addi	sp,sp,-32
    80000d3c:	ec06                	sd	ra,24(sp)
    80000d3e:	e822                	sd	s0,16(sp)
    80000d40:	e426                	sd	s1,8(sp)
    80000d42:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d44:	100024f3          	csrr	s1,sstatus
    80000d48:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d4c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d4e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d52:	00001097          	auipc	ra,0x1
    80000d56:	eca080e7          	jalr	-310(ra) # 80001c1c <mycpu>
    80000d5a:	5d3c                	lw	a5,120(a0)
    80000d5c:	cf89                	beqz	a5,80000d76 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d5e:	00001097          	auipc	ra,0x1
    80000d62:	ebe080e7          	jalr	-322(ra) # 80001c1c <mycpu>
    80000d66:	5d3c                	lw	a5,120(a0)
    80000d68:	2785                	addiw	a5,a5,1
    80000d6a:	dd3c                	sw	a5,120(a0)
}
    80000d6c:	60e2                	ld	ra,24(sp)
    80000d6e:	6442                	ld	s0,16(sp)
    80000d70:	64a2                	ld	s1,8(sp)
    80000d72:	6105                	addi	sp,sp,32
    80000d74:	8082                	ret
    mycpu()->intena = old;
    80000d76:	00001097          	auipc	ra,0x1
    80000d7a:	ea6080e7          	jalr	-346(ra) # 80001c1c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d7e:	8085                	srli	s1,s1,0x1
    80000d80:	8885                	andi	s1,s1,1
    80000d82:	dd64                	sw	s1,124(a0)
    80000d84:	bfe9                	j	80000d5e <push_off+0x24>

0000000080000d86 <acquire>:
{
    80000d86:	1101                	addi	sp,sp,-32
    80000d88:	ec06                	sd	ra,24(sp)
    80000d8a:	e822                	sd	s0,16(sp)
    80000d8c:	e426                	sd	s1,8(sp)
    80000d8e:	1000                	addi	s0,sp,32
    80000d90:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	fa8080e7          	jalr	-88(ra) # 80000d3a <push_off>
  if(holding(lk))
    80000d9a:	8526                	mv	a0,s1
    80000d9c:	00000097          	auipc	ra,0x0
    80000da0:	f70080e7          	jalr	-144(ra) # 80000d0c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000da4:	4705                	li	a4,1
  if(holding(lk))
    80000da6:	e115                	bnez	a0,80000dca <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000da8:	87ba                	mv	a5,a4
    80000daa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000dae:	2781                	sext.w	a5,a5
    80000db0:	ffe5                	bnez	a5,80000da8 <acquire+0x22>
  __sync_synchronize();
    80000db2:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000db6:	00001097          	auipc	ra,0x1
    80000dba:	e66080e7          	jalr	-410(ra) # 80001c1c <mycpu>
    80000dbe:	e888                	sd	a0,16(s1)
}
    80000dc0:	60e2                	ld	ra,24(sp)
    80000dc2:	6442                	ld	s0,16(sp)
    80000dc4:	64a2                	ld	s1,8(sp)
    80000dc6:	6105                	addi	sp,sp,32
    80000dc8:	8082                	ret
    panic("acquire");
    80000dca:	00007517          	auipc	a0,0x7
    80000dce:	2ae50513          	addi	a0,a0,686 # 80008078 <digits+0x38>
    80000dd2:	fffff097          	auipc	ra,0xfffff
    80000dd6:	776080e7          	jalr	1910(ra) # 80000548 <panic>

0000000080000dda <pop_off>:

void
pop_off(void)
{
    80000dda:	1141                	addi	sp,sp,-16
    80000ddc:	e406                	sd	ra,8(sp)
    80000dde:	e022                	sd	s0,0(sp)
    80000de0:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000de2:	00001097          	auipc	ra,0x1
    80000de6:	e3a080e7          	jalr	-454(ra) # 80001c1c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dea:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000dee:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000df0:	e78d                	bnez	a5,80000e1a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000df2:	5d3c                	lw	a5,120(a0)
    80000df4:	02f05b63          	blez	a5,80000e2a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000df8:	37fd                	addiw	a5,a5,-1
    80000dfa:	0007871b          	sext.w	a4,a5
    80000dfe:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000e00:	eb09                	bnez	a4,80000e12 <pop_off+0x38>
    80000e02:	5d7c                	lw	a5,124(a0)
    80000e04:	c799                	beqz	a5,80000e12 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e06:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000e0a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e0e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000e12:	60a2                	ld	ra,8(sp)
    80000e14:	6402                	ld	s0,0(sp)
    80000e16:	0141                	addi	sp,sp,16
    80000e18:	8082                	ret
    panic("pop_off - interruptible");
    80000e1a:	00007517          	auipc	a0,0x7
    80000e1e:	26650513          	addi	a0,a0,614 # 80008080 <digits+0x40>
    80000e22:	fffff097          	auipc	ra,0xfffff
    80000e26:	726080e7          	jalr	1830(ra) # 80000548 <panic>
    panic("pop_off");
    80000e2a:	00007517          	auipc	a0,0x7
    80000e2e:	26e50513          	addi	a0,a0,622 # 80008098 <digits+0x58>
    80000e32:	fffff097          	auipc	ra,0xfffff
    80000e36:	716080e7          	jalr	1814(ra) # 80000548 <panic>

0000000080000e3a <release>:
{
    80000e3a:	1101                	addi	sp,sp,-32
    80000e3c:	ec06                	sd	ra,24(sp)
    80000e3e:	e822                	sd	s0,16(sp)
    80000e40:	e426                	sd	s1,8(sp)
    80000e42:	1000                	addi	s0,sp,32
    80000e44:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e46:	00000097          	auipc	ra,0x0
    80000e4a:	ec6080e7          	jalr	-314(ra) # 80000d0c <holding>
    80000e4e:	c115                	beqz	a0,80000e72 <release+0x38>
  lk->cpu = 0;
    80000e50:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e54:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e58:	0f50000f          	fence	iorw,ow
    80000e5c:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e60:	00000097          	auipc	ra,0x0
    80000e64:	f7a080e7          	jalr	-134(ra) # 80000dda <pop_off>
}
    80000e68:	60e2                	ld	ra,24(sp)
    80000e6a:	6442                	ld	s0,16(sp)
    80000e6c:	64a2                	ld	s1,8(sp)
    80000e6e:	6105                	addi	sp,sp,32
    80000e70:	8082                	ret
    panic("release");
    80000e72:	00007517          	auipc	a0,0x7
    80000e76:	22e50513          	addi	a0,a0,558 # 800080a0 <digits+0x60>
    80000e7a:	fffff097          	auipc	ra,0xfffff
    80000e7e:	6ce080e7          	jalr	1742(ra) # 80000548 <panic>

0000000080000e82 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e82:	1141                	addi	sp,sp,-16
    80000e84:	e422                	sd	s0,8(sp)
    80000e86:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e88:	ce09                	beqz	a2,80000ea2 <memset+0x20>
    80000e8a:	87aa                	mv	a5,a0
    80000e8c:	fff6071b          	addiw	a4,a2,-1
    80000e90:	1702                	slli	a4,a4,0x20
    80000e92:	9301                	srli	a4,a4,0x20
    80000e94:	0705                	addi	a4,a4,1
    80000e96:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000e98:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e9c:	0785                	addi	a5,a5,1
    80000e9e:	fee79de3          	bne	a5,a4,80000e98 <memset+0x16>
  }
  return dst;
}
    80000ea2:	6422                	ld	s0,8(sp)
    80000ea4:	0141                	addi	sp,sp,16
    80000ea6:	8082                	ret

0000000080000ea8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ea8:	1141                	addi	sp,sp,-16
    80000eaa:	e422                	sd	s0,8(sp)
    80000eac:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000eae:	ca05                	beqz	a2,80000ede <memcmp+0x36>
    80000eb0:	fff6069b          	addiw	a3,a2,-1
    80000eb4:	1682                	slli	a3,a3,0x20
    80000eb6:	9281                	srli	a3,a3,0x20
    80000eb8:	0685                	addi	a3,a3,1
    80000eba:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000ebc:	00054783          	lbu	a5,0(a0)
    80000ec0:	0005c703          	lbu	a4,0(a1)
    80000ec4:	00e79863          	bne	a5,a4,80000ed4 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ec8:	0505                	addi	a0,a0,1
    80000eca:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ecc:	fed518e3          	bne	a0,a3,80000ebc <memcmp+0x14>
  }

  return 0;
    80000ed0:	4501                	li	a0,0
    80000ed2:	a019                	j	80000ed8 <memcmp+0x30>
      return *s1 - *s2;
    80000ed4:	40e7853b          	subw	a0,a5,a4
}
    80000ed8:	6422                	ld	s0,8(sp)
    80000eda:	0141                	addi	sp,sp,16
    80000edc:	8082                	ret
  return 0;
    80000ede:	4501                	li	a0,0
    80000ee0:	bfe5                	j	80000ed8 <memcmp+0x30>

0000000080000ee2 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000ee2:	1141                	addi	sp,sp,-16
    80000ee4:	e422                	sd	s0,8(sp)
    80000ee6:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000ee8:	00a5f963          	bgeu	a1,a0,80000efa <memmove+0x18>
    80000eec:	02061713          	slli	a4,a2,0x20
    80000ef0:	9301                	srli	a4,a4,0x20
    80000ef2:	00e587b3          	add	a5,a1,a4
    80000ef6:	02f56563          	bltu	a0,a5,80000f20 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000efa:	fff6069b          	addiw	a3,a2,-1
    80000efe:	ce11                	beqz	a2,80000f1a <memmove+0x38>
    80000f00:	1682                	slli	a3,a3,0x20
    80000f02:	9281                	srli	a3,a3,0x20
    80000f04:	0685                	addi	a3,a3,1
    80000f06:	96ae                	add	a3,a3,a1
    80000f08:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000f0a:	0585                	addi	a1,a1,1
    80000f0c:	0785                	addi	a5,a5,1
    80000f0e:	fff5c703          	lbu	a4,-1(a1)
    80000f12:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000f16:	fed59ae3          	bne	a1,a3,80000f0a <memmove+0x28>

  return dst;
}
    80000f1a:	6422                	ld	s0,8(sp)
    80000f1c:	0141                	addi	sp,sp,16
    80000f1e:	8082                	ret
    d += n;
    80000f20:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000f22:	fff6069b          	addiw	a3,a2,-1
    80000f26:	da75                	beqz	a2,80000f1a <memmove+0x38>
    80000f28:	02069613          	slli	a2,a3,0x20
    80000f2c:	9201                	srli	a2,a2,0x20
    80000f2e:	fff64613          	not	a2,a2
    80000f32:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000f34:	17fd                	addi	a5,a5,-1
    80000f36:	177d                	addi	a4,a4,-1
    80000f38:	0007c683          	lbu	a3,0(a5)
    80000f3c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000f40:	fec79ae3          	bne	a5,a2,80000f34 <memmove+0x52>
    80000f44:	bfd9                	j	80000f1a <memmove+0x38>

0000000080000f46 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f46:	1141                	addi	sp,sp,-16
    80000f48:	e406                	sd	ra,8(sp)
    80000f4a:	e022                	sd	s0,0(sp)
    80000f4c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	f94080e7          	jalr	-108(ra) # 80000ee2 <memmove>
}
    80000f56:	60a2                	ld	ra,8(sp)
    80000f58:	6402                	ld	s0,0(sp)
    80000f5a:	0141                	addi	sp,sp,16
    80000f5c:	8082                	ret

0000000080000f5e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f5e:	1141                	addi	sp,sp,-16
    80000f60:	e422                	sd	s0,8(sp)
    80000f62:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f64:	ce11                	beqz	a2,80000f80 <strncmp+0x22>
    80000f66:	00054783          	lbu	a5,0(a0)
    80000f6a:	cf89                	beqz	a5,80000f84 <strncmp+0x26>
    80000f6c:	0005c703          	lbu	a4,0(a1)
    80000f70:	00f71a63          	bne	a4,a5,80000f84 <strncmp+0x26>
    n--, p++, q++;
    80000f74:	367d                	addiw	a2,a2,-1
    80000f76:	0505                	addi	a0,a0,1
    80000f78:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f7a:	f675                	bnez	a2,80000f66 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f7c:	4501                	li	a0,0
    80000f7e:	a809                	j	80000f90 <strncmp+0x32>
    80000f80:	4501                	li	a0,0
    80000f82:	a039                	j	80000f90 <strncmp+0x32>
  if(n == 0)
    80000f84:	ca09                	beqz	a2,80000f96 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f86:	00054503          	lbu	a0,0(a0)
    80000f8a:	0005c783          	lbu	a5,0(a1)
    80000f8e:	9d1d                	subw	a0,a0,a5
}
    80000f90:	6422                	ld	s0,8(sp)
    80000f92:	0141                	addi	sp,sp,16
    80000f94:	8082                	ret
    return 0;
    80000f96:	4501                	li	a0,0
    80000f98:	bfe5                	j	80000f90 <strncmp+0x32>

0000000080000f9a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f9a:	1141                	addi	sp,sp,-16
    80000f9c:	e422                	sd	s0,8(sp)
    80000f9e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000fa0:	872a                	mv	a4,a0
    80000fa2:	8832                	mv	a6,a2
    80000fa4:	367d                	addiw	a2,a2,-1
    80000fa6:	01005963          	blez	a6,80000fb8 <strncpy+0x1e>
    80000faa:	0705                	addi	a4,a4,1
    80000fac:	0005c783          	lbu	a5,0(a1)
    80000fb0:	fef70fa3          	sb	a5,-1(a4)
    80000fb4:	0585                	addi	a1,a1,1
    80000fb6:	f7f5                	bnez	a5,80000fa2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000fb8:	00c05d63          	blez	a2,80000fd2 <strncpy+0x38>
    80000fbc:	86ba                	mv	a3,a4
    *s++ = 0;
    80000fbe:	0685                	addi	a3,a3,1
    80000fc0:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000fc4:	fff6c793          	not	a5,a3
    80000fc8:	9fb9                	addw	a5,a5,a4
    80000fca:	010787bb          	addw	a5,a5,a6
    80000fce:	fef048e3          	bgtz	a5,80000fbe <strncpy+0x24>
  return os;
}
    80000fd2:	6422                	ld	s0,8(sp)
    80000fd4:	0141                	addi	sp,sp,16
    80000fd6:	8082                	ret

0000000080000fd8 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000fd8:	1141                	addi	sp,sp,-16
    80000fda:	e422                	sd	s0,8(sp)
    80000fdc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000fde:	02c05363          	blez	a2,80001004 <safestrcpy+0x2c>
    80000fe2:	fff6069b          	addiw	a3,a2,-1
    80000fe6:	1682                	slli	a3,a3,0x20
    80000fe8:	9281                	srli	a3,a3,0x20
    80000fea:	96ae                	add	a3,a3,a1
    80000fec:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000fee:	00d58963          	beq	a1,a3,80001000 <safestrcpy+0x28>
    80000ff2:	0585                	addi	a1,a1,1
    80000ff4:	0785                	addi	a5,a5,1
    80000ff6:	fff5c703          	lbu	a4,-1(a1)
    80000ffa:	fee78fa3          	sb	a4,-1(a5)
    80000ffe:	fb65                	bnez	a4,80000fee <safestrcpy+0x16>
    ;
  *s = 0;
    80001000:	00078023          	sb	zero,0(a5)
  return os;
}
    80001004:	6422                	ld	s0,8(sp)
    80001006:	0141                	addi	sp,sp,16
    80001008:	8082                	ret

000000008000100a <strlen>:

int
strlen(const char *s)
{
    8000100a:	1141                	addi	sp,sp,-16
    8000100c:	e422                	sd	s0,8(sp)
    8000100e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001010:	00054783          	lbu	a5,0(a0)
    80001014:	cf91                	beqz	a5,80001030 <strlen+0x26>
    80001016:	0505                	addi	a0,a0,1
    80001018:	87aa                	mv	a5,a0
    8000101a:	4685                	li	a3,1
    8000101c:	9e89                	subw	a3,a3,a0
    8000101e:	00f6853b          	addw	a0,a3,a5
    80001022:	0785                	addi	a5,a5,1
    80001024:	fff7c703          	lbu	a4,-1(a5)
    80001028:	fb7d                	bnez	a4,8000101e <strlen+0x14>
    ;
  return n;
}
    8000102a:	6422                	ld	s0,8(sp)
    8000102c:	0141                	addi	sp,sp,16
    8000102e:	8082                	ret
  for(n = 0; s[n]; n++)
    80001030:	4501                	li	a0,0
    80001032:	bfe5                	j	8000102a <strlen+0x20>

0000000080001034 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001034:	1141                	addi	sp,sp,-16
    80001036:	e406                	sd	ra,8(sp)
    80001038:	e022                	sd	s0,0(sp)
    8000103a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    8000103c:	00001097          	auipc	ra,0x1
    80001040:	bd0080e7          	jalr	-1072(ra) # 80001c0c <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001044:	00008717          	auipc	a4,0x8
    80001048:	fc870713          	addi	a4,a4,-56 # 8000900c <started>
  if(cpuid() == 0){
    8000104c:	c139                	beqz	a0,80001092 <main+0x5e>
    while(started == 0)
    8000104e:	431c                	lw	a5,0(a4)
    80001050:	2781                	sext.w	a5,a5
    80001052:	dff5                	beqz	a5,8000104e <main+0x1a>
      ;
    __sync_synchronize();
    80001054:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001058:	00001097          	auipc	ra,0x1
    8000105c:	bb4080e7          	jalr	-1100(ra) # 80001c0c <cpuid>
    80001060:	85aa                	mv	a1,a0
    80001062:	00007517          	auipc	a0,0x7
    80001066:	05e50513          	addi	a0,a0,94 # 800080c0 <digits+0x80>
    8000106a:	fffff097          	auipc	ra,0xfffff
    8000106e:	528080e7          	jalr	1320(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80001072:	00000097          	auipc	ra,0x0
    80001076:	0d8080e7          	jalr	216(ra) # 8000114a <kvminithart>
    trapinithart();   // install kernel trap vector
    8000107a:	00002097          	auipc	ra,0x2
    8000107e:	81c080e7          	jalr	-2020(ra) # 80002896 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001082:	00005097          	auipc	ra,0x5
    80001086:	f1e080e7          	jalr	-226(ra) # 80005fa0 <plicinithart>
  }

  scheduler();        
    8000108a:	00001097          	auipc	ra,0x1
    8000108e:	0de080e7          	jalr	222(ra) # 80002168 <scheduler>
    consoleinit();
    80001092:	fffff097          	auipc	ra,0xfffff
    80001096:	3c8080e7          	jalr	968(ra) # 8000045a <consoleinit>
    printfinit();
    8000109a:	fffff097          	auipc	ra,0xfffff
    8000109e:	6de080e7          	jalr	1758(ra) # 80000778 <printfinit>
    printf("\n");
    800010a2:	00007517          	auipc	a0,0x7
    800010a6:	2ae50513          	addi	a0,a0,686 # 80008350 <states.1710+0x88>
    800010aa:	fffff097          	auipc	ra,0xfffff
    800010ae:	4e8080e7          	jalr	1256(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    800010b2:	00007517          	auipc	a0,0x7
    800010b6:	ff650513          	addi	a0,a0,-10 # 800080a8 <digits+0x68>
    800010ba:	fffff097          	auipc	ra,0xfffff
    800010be:	4d8080e7          	jalr	1240(ra) # 80000592 <printf>
    printf("\n");
    800010c2:	00007517          	auipc	a0,0x7
    800010c6:	28e50513          	addi	a0,a0,654 # 80008350 <states.1710+0x88>
    800010ca:	fffff097          	auipc	ra,0xfffff
    800010ce:	4c8080e7          	jalr	1224(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	a9a080e7          	jalr	-1382(ra) # 80000b6c <kinit>
    kvminit();       // create kernel page table
    800010da:	00000097          	auipc	ra,0x0
    800010de:	28a080e7          	jalr	650(ra) # 80001364 <kvminit>
    kvminithart();   // turn on paging
    800010e2:	00000097          	auipc	ra,0x0
    800010e6:	068080e7          	jalr	104(ra) # 8000114a <kvminithart>
    procinit();      // process table
    800010ea:	00001097          	auipc	ra,0x1
    800010ee:	a52080e7          	jalr	-1454(ra) # 80001b3c <procinit>
    trapinit();      // trap vectors
    800010f2:	00001097          	auipc	ra,0x1
    800010f6:	77c080e7          	jalr	1916(ra) # 8000286e <trapinit>
    trapinithart();  // install kernel trap vector
    800010fa:	00001097          	auipc	ra,0x1
    800010fe:	79c080e7          	jalr	1948(ra) # 80002896 <trapinithart>
    plicinit();      // set up interrupt controller
    80001102:	00005097          	auipc	ra,0x5
    80001106:	e88080e7          	jalr	-376(ra) # 80005f8a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000110a:	00005097          	auipc	ra,0x5
    8000110e:	e96080e7          	jalr	-362(ra) # 80005fa0 <plicinithart>
    binit();         // buffer cache
    80001112:	00002097          	auipc	ra,0x2
    80001116:	032080e7          	jalr	50(ra) # 80003144 <binit>
    iinit();         // inode cache
    8000111a:	00002097          	auipc	ra,0x2
    8000111e:	6c2080e7          	jalr	1730(ra) # 800037dc <iinit>
    fileinit();      // file table
    80001122:	00003097          	auipc	ra,0x3
    80001126:	660080e7          	jalr	1632(ra) # 80004782 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000112a:	00005097          	auipc	ra,0x5
    8000112e:	f7e080e7          	jalr	-130(ra) # 800060a8 <virtio_disk_init>
    userinit();      // first user process
    80001132:	00001097          	auipc	ra,0x1
    80001136:	dd0080e7          	jalr	-560(ra) # 80001f02 <userinit>
    __sync_synchronize();
    8000113a:	0ff0000f          	fence
    started = 1;
    8000113e:	4785                	li	a5,1
    80001140:	00008717          	auipc	a4,0x8
    80001144:	ecf72623          	sw	a5,-308(a4) # 8000900c <started>
    80001148:	b789                	j	8000108a <main+0x56>

000000008000114a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000114a:	1141                	addi	sp,sp,-16
    8000114c:	e422                	sd	s0,8(sp)
    8000114e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001150:	00008797          	auipc	a5,0x8
    80001154:	ec07b783          	ld	a5,-320(a5) # 80009010 <kernel_pagetable>
    80001158:	83b1                	srli	a5,a5,0xc
    8000115a:	577d                	li	a4,-1
    8000115c:	177e                	slli	a4,a4,0x3f
    8000115e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001160:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001164:	12000073          	sfence.vma
  sfence_vma();
}
    80001168:	6422                	ld	s0,8(sp)
    8000116a:	0141                	addi	sp,sp,16
    8000116c:	8082                	ret

000000008000116e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000116e:	7139                	addi	sp,sp,-64
    80001170:	fc06                	sd	ra,56(sp)
    80001172:	f822                	sd	s0,48(sp)
    80001174:	f426                	sd	s1,40(sp)
    80001176:	f04a                	sd	s2,32(sp)
    80001178:	ec4e                	sd	s3,24(sp)
    8000117a:	e852                	sd	s4,16(sp)
    8000117c:	e456                	sd	s5,8(sp)
    8000117e:	e05a                	sd	s6,0(sp)
    80001180:	0080                	addi	s0,sp,64
    80001182:	84aa                	mv	s1,a0
    80001184:	89ae                	mv	s3,a1
    80001186:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001188:	57fd                	li	a5,-1
    8000118a:	83e9                	srli	a5,a5,0x1a
    8000118c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000118e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001190:	04b7f263          	bgeu	a5,a1,800011d4 <walk+0x66>
    panic("walk");
    80001194:	00007517          	auipc	a0,0x7
    80001198:	f4450513          	addi	a0,a0,-188 # 800080d8 <digits+0x98>
    8000119c:	fffff097          	auipc	ra,0xfffff
    800011a0:	3ac080e7          	jalr	940(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800011a4:	060a8663          	beqz	s5,80001210 <walk+0xa2>
    800011a8:	00000097          	auipc	ra,0x0
    800011ac:	a30080e7          	jalr	-1488(ra) # 80000bd8 <kalloc>
    800011b0:	84aa                	mv	s1,a0
    800011b2:	c529                	beqz	a0,800011fc <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800011b4:	6605                	lui	a2,0x1
    800011b6:	4581                	li	a1,0
    800011b8:	00000097          	auipc	ra,0x0
    800011bc:	cca080e7          	jalr	-822(ra) # 80000e82 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800011c0:	00c4d793          	srli	a5,s1,0xc
    800011c4:	07aa                	slli	a5,a5,0xa
    800011c6:	0017e793          	ori	a5,a5,1
    800011ca:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800011ce:	3a5d                	addiw	s4,s4,-9
    800011d0:	036a0063          	beq	s4,s6,800011f0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800011d4:	0149d933          	srl	s2,s3,s4
    800011d8:	1ff97913          	andi	s2,s2,511
    800011dc:	090e                	slli	s2,s2,0x3
    800011de:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800011e0:	00093483          	ld	s1,0(s2)
    800011e4:	0014f793          	andi	a5,s1,1
    800011e8:	dfd5                	beqz	a5,800011a4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011ea:	80a9                	srli	s1,s1,0xa
    800011ec:	04b2                	slli	s1,s1,0xc
    800011ee:	b7c5                	j	800011ce <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800011f0:	00c9d513          	srli	a0,s3,0xc
    800011f4:	1ff57513          	andi	a0,a0,511
    800011f8:	050e                	slli	a0,a0,0x3
    800011fa:	9526                	add	a0,a0,s1
}
    800011fc:	70e2                	ld	ra,56(sp)
    800011fe:	7442                	ld	s0,48(sp)
    80001200:	74a2                	ld	s1,40(sp)
    80001202:	7902                	ld	s2,32(sp)
    80001204:	69e2                	ld	s3,24(sp)
    80001206:	6a42                	ld	s4,16(sp)
    80001208:	6aa2                	ld	s5,8(sp)
    8000120a:	6b02                	ld	s6,0(sp)
    8000120c:	6121                	addi	sp,sp,64
    8000120e:	8082                	ret
        return 0;
    80001210:	4501                	li	a0,0
    80001212:	b7ed                	j	800011fc <walk+0x8e>

0000000080001214 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001214:	57fd                	li	a5,-1
    80001216:	83e9                	srli	a5,a5,0x1a
    80001218:	00b7f463          	bgeu	a5,a1,80001220 <walkaddr+0xc>
    return 0;
    8000121c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000121e:	8082                	ret
{
    80001220:	1141                	addi	sp,sp,-16
    80001222:	e406                	sd	ra,8(sp)
    80001224:	e022                	sd	s0,0(sp)
    80001226:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001228:	4601                	li	a2,0
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	f44080e7          	jalr	-188(ra) # 8000116e <walk>
  if(pte == 0)
    80001232:	c105                	beqz	a0,80001252 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001234:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001236:	0117f693          	andi	a3,a5,17
    8000123a:	4745                	li	a4,17
    return 0;
    8000123c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000123e:	00e68663          	beq	a3,a4,8000124a <walkaddr+0x36>
}
    80001242:	60a2                	ld	ra,8(sp)
    80001244:	6402                	ld	s0,0(sp)
    80001246:	0141                	addi	sp,sp,16
    80001248:	8082                	ret
  pa = PTE2PA(*pte);
    8000124a:	00a7d513          	srli	a0,a5,0xa
    8000124e:	0532                	slli	a0,a0,0xc
  return pa;
    80001250:	bfcd                	j	80001242 <walkaddr+0x2e>
    return 0;
    80001252:	4501                	li	a0,0
    80001254:	b7fd                	j	80001242 <walkaddr+0x2e>

0000000080001256 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001256:	1101                	addi	sp,sp,-32
    80001258:	ec06                	sd	ra,24(sp)
    8000125a:	e822                	sd	s0,16(sp)
    8000125c:	e426                	sd	s1,8(sp)
    8000125e:	1000                	addi	s0,sp,32
    80001260:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001262:	1552                	slli	a0,a0,0x34
    80001264:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001268:	4601                	li	a2,0
    8000126a:	00008517          	auipc	a0,0x8
    8000126e:	da653503          	ld	a0,-602(a0) # 80009010 <kernel_pagetable>
    80001272:	00000097          	auipc	ra,0x0
    80001276:	efc080e7          	jalr	-260(ra) # 8000116e <walk>
  if(pte == 0)
    8000127a:	cd09                	beqz	a0,80001294 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    8000127c:	6108                	ld	a0,0(a0)
    8000127e:	00157793          	andi	a5,a0,1
    80001282:	c38d                	beqz	a5,800012a4 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001284:	8129                	srli	a0,a0,0xa
    80001286:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001288:	9526                	add	a0,a0,s1
    8000128a:	60e2                	ld	ra,24(sp)
    8000128c:	6442                	ld	s0,16(sp)
    8000128e:	64a2                	ld	s1,8(sp)
    80001290:	6105                	addi	sp,sp,32
    80001292:	8082                	ret
    panic("kvmpa");
    80001294:	00007517          	auipc	a0,0x7
    80001298:	e4c50513          	addi	a0,a0,-436 # 800080e0 <digits+0xa0>
    8000129c:	fffff097          	auipc	ra,0xfffff
    800012a0:	2ac080e7          	jalr	684(ra) # 80000548 <panic>
    panic("kvmpa");
    800012a4:	00007517          	auipc	a0,0x7
    800012a8:	e3c50513          	addi	a0,a0,-452 # 800080e0 <digits+0xa0>
    800012ac:	fffff097          	auipc	ra,0xfffff
    800012b0:	29c080e7          	jalr	668(ra) # 80000548 <panic>

00000000800012b4 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800012b4:	715d                	addi	sp,sp,-80
    800012b6:	e486                	sd	ra,72(sp)
    800012b8:	e0a2                	sd	s0,64(sp)
    800012ba:	fc26                	sd	s1,56(sp)
    800012bc:	f84a                	sd	s2,48(sp)
    800012be:	f44e                	sd	s3,40(sp)
    800012c0:	f052                	sd	s4,32(sp)
    800012c2:	ec56                	sd	s5,24(sp)
    800012c4:	e85a                	sd	s6,16(sp)
    800012c6:	e45e                	sd	s7,8(sp)
    800012c8:	0880                	addi	s0,sp,80
    800012ca:	8aaa                	mv	s5,a0
    800012cc:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800012ce:	777d                	lui	a4,0xfffff
    800012d0:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800012d4:	167d                	addi	a2,a2,-1
    800012d6:	00b609b3          	add	s3,a2,a1
    800012da:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800012de:	893e                	mv	s2,a5
    800012e0:	40f68a33          	sub	s4,a3,a5
    //这里不需要进行这项判断，因为本来就需要重映射
    //   panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800012e4:	6b85                	lui	s7,0x1
    800012e6:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800012ea:	4605                	li	a2,1
    800012ec:	85ca                	mv	a1,s2
    800012ee:	8556                	mv	a0,s5
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	e7e080e7          	jalr	-386(ra) # 8000116e <walk>
    800012f8:	cd01                	beqz	a0,80001310 <mappages+0x5c>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800012fa:	80b1                	srli	s1,s1,0xc
    800012fc:	04aa                	slli	s1,s1,0xa
    800012fe:	0164e4b3          	or	s1,s1,s6
    80001302:	0014e493          	ori	s1,s1,1
    80001306:	e104                	sd	s1,0(a0)
    if(a == last)
    80001308:	03390063          	beq	s2,s3,80001328 <mappages+0x74>
    a += PGSIZE;
    8000130c:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000130e:	bfe1                	j	800012e6 <mappages+0x32>
      return -1;
    80001310:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001312:	60a6                	ld	ra,72(sp)
    80001314:	6406                	ld	s0,64(sp)
    80001316:	74e2                	ld	s1,56(sp)
    80001318:	7942                	ld	s2,48(sp)
    8000131a:	79a2                	ld	s3,40(sp)
    8000131c:	7a02                	ld	s4,32(sp)
    8000131e:	6ae2                	ld	s5,24(sp)
    80001320:	6b42                	ld	s6,16(sp)
    80001322:	6ba2                	ld	s7,8(sp)
    80001324:	6161                	addi	sp,sp,80
    80001326:	8082                	ret
  return 0;
    80001328:	4501                	li	a0,0
    8000132a:	b7e5                	j	80001312 <mappages+0x5e>

000000008000132c <kvmmap>:
{
    8000132c:	1141                	addi	sp,sp,-16
    8000132e:	e406                	sd	ra,8(sp)
    80001330:	e022                	sd	s0,0(sp)
    80001332:	0800                	addi	s0,sp,16
    80001334:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001336:	86ae                	mv	a3,a1
    80001338:	85aa                	mv	a1,a0
    8000133a:	00008517          	auipc	a0,0x8
    8000133e:	cd653503          	ld	a0,-810(a0) # 80009010 <kernel_pagetable>
    80001342:	00000097          	auipc	ra,0x0
    80001346:	f72080e7          	jalr	-142(ra) # 800012b4 <mappages>
    8000134a:	e509                	bnez	a0,80001354 <kvmmap+0x28>
}
    8000134c:	60a2                	ld	ra,8(sp)
    8000134e:	6402                	ld	s0,0(sp)
    80001350:	0141                	addi	sp,sp,16
    80001352:	8082                	ret
    panic("kvmmap");
    80001354:	00007517          	auipc	a0,0x7
    80001358:	d9450513          	addi	a0,a0,-620 # 800080e8 <digits+0xa8>
    8000135c:	fffff097          	auipc	ra,0xfffff
    80001360:	1ec080e7          	jalr	492(ra) # 80000548 <panic>

0000000080001364 <kvminit>:
{
    80001364:	1101                	addi	sp,sp,-32
    80001366:	ec06                	sd	ra,24(sp)
    80001368:	e822                	sd	s0,16(sp)
    8000136a:	e426                	sd	s1,8(sp)
    8000136c:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000136e:	00000097          	auipc	ra,0x0
    80001372:	86a080e7          	jalr	-1942(ra) # 80000bd8 <kalloc>
    80001376:	00008797          	auipc	a5,0x8
    8000137a:	c8a7bd23          	sd	a0,-870(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000137e:	6605                	lui	a2,0x1
    80001380:	4581                	li	a1,0
    80001382:	00000097          	auipc	ra,0x0
    80001386:	b00080e7          	jalr	-1280(ra) # 80000e82 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000138a:	4699                	li	a3,6
    8000138c:	6605                	lui	a2,0x1
    8000138e:	100005b7          	lui	a1,0x10000
    80001392:	10000537          	lui	a0,0x10000
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	f96080e7          	jalr	-106(ra) # 8000132c <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000139e:	4699                	li	a3,6
    800013a0:	6605                	lui	a2,0x1
    800013a2:	100015b7          	lui	a1,0x10001
    800013a6:	10001537          	lui	a0,0x10001
    800013aa:	00000097          	auipc	ra,0x0
    800013ae:	f82080e7          	jalr	-126(ra) # 8000132c <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800013b2:	4699                	li	a3,6
    800013b4:	6641                	lui	a2,0x10
    800013b6:	020005b7          	lui	a1,0x2000
    800013ba:	02000537          	lui	a0,0x2000
    800013be:	00000097          	auipc	ra,0x0
    800013c2:	f6e080e7          	jalr	-146(ra) # 8000132c <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800013c6:	4699                	li	a3,6
    800013c8:	00400637          	lui	a2,0x400
    800013cc:	0c0005b7          	lui	a1,0xc000
    800013d0:	0c000537          	lui	a0,0xc000
    800013d4:	00000097          	auipc	ra,0x0
    800013d8:	f58080e7          	jalr	-168(ra) # 8000132c <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800013dc:	00007497          	auipc	s1,0x7
    800013e0:	c2448493          	addi	s1,s1,-988 # 80008000 <etext>
    800013e4:	46a9                	li	a3,10
    800013e6:	80007617          	auipc	a2,0x80007
    800013ea:	c1a60613          	addi	a2,a2,-998 # 8000 <_entry-0x7fff8000>
    800013ee:	4585                	li	a1,1
    800013f0:	05fe                	slli	a1,a1,0x1f
    800013f2:	852e                	mv	a0,a1
    800013f4:	00000097          	auipc	ra,0x0
    800013f8:	f38080e7          	jalr	-200(ra) # 8000132c <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800013fc:	4699                	li	a3,6
    800013fe:	4645                	li	a2,17
    80001400:	066e                	slli	a2,a2,0x1b
    80001402:	8e05                	sub	a2,a2,s1
    80001404:	85a6                	mv	a1,s1
    80001406:	8526                	mv	a0,s1
    80001408:	00000097          	auipc	ra,0x0
    8000140c:	f24080e7          	jalr	-220(ra) # 8000132c <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001410:	46a9                	li	a3,10
    80001412:	6605                	lui	a2,0x1
    80001414:	00006597          	auipc	a1,0x6
    80001418:	bec58593          	addi	a1,a1,-1044 # 80007000 <_trampoline>
    8000141c:	04000537          	lui	a0,0x4000
    80001420:	157d                	addi	a0,a0,-1
    80001422:	0532                	slli	a0,a0,0xc
    80001424:	00000097          	auipc	ra,0x0
    80001428:	f08080e7          	jalr	-248(ra) # 8000132c <kvmmap>
}
    8000142c:	60e2                	ld	ra,24(sp)
    8000142e:	6442                	ld	s0,16(sp)
    80001430:	64a2                	ld	s1,8(sp)
    80001432:	6105                	addi	sp,sp,32
    80001434:	8082                	ret

0000000080001436 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001436:	715d                	addi	sp,sp,-80
    80001438:	e486                	sd	ra,72(sp)
    8000143a:	e0a2                	sd	s0,64(sp)
    8000143c:	fc26                	sd	s1,56(sp)
    8000143e:	f84a                	sd	s2,48(sp)
    80001440:	f44e                	sd	s3,40(sp)
    80001442:	f052                	sd	s4,32(sp)
    80001444:	ec56                	sd	s5,24(sp)
    80001446:	e85a                	sd	s6,16(sp)
    80001448:	e45e                	sd	s7,8(sp)
    8000144a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000144c:	03459793          	slli	a5,a1,0x34
    80001450:	e795                	bnez	a5,8000147c <uvmunmap+0x46>
    80001452:	8a2a                	mv	s4,a0
    80001454:	892e                	mv	s2,a1
    80001456:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001458:	0632                	slli	a2,a2,0xc
    8000145a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000145e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001460:	6b05                	lui	s6,0x1
    80001462:	0735e863          	bltu	a1,s3,800014d2 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001466:	60a6                	ld	ra,72(sp)
    80001468:	6406                	ld	s0,64(sp)
    8000146a:	74e2                	ld	s1,56(sp)
    8000146c:	7942                	ld	s2,48(sp)
    8000146e:	79a2                	ld	s3,40(sp)
    80001470:	7a02                	ld	s4,32(sp)
    80001472:	6ae2                	ld	s5,24(sp)
    80001474:	6b42                	ld	s6,16(sp)
    80001476:	6ba2                	ld	s7,8(sp)
    80001478:	6161                	addi	sp,sp,80
    8000147a:	8082                	ret
    panic("uvmunmap: not aligned");
    8000147c:	00007517          	auipc	a0,0x7
    80001480:	c7450513          	addi	a0,a0,-908 # 800080f0 <digits+0xb0>
    80001484:	fffff097          	auipc	ra,0xfffff
    80001488:	0c4080e7          	jalr	196(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    8000148c:	00007517          	auipc	a0,0x7
    80001490:	c7c50513          	addi	a0,a0,-900 # 80008108 <digits+0xc8>
    80001494:	fffff097          	auipc	ra,0xfffff
    80001498:	0b4080e7          	jalr	180(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    8000149c:	00007517          	auipc	a0,0x7
    800014a0:	c7c50513          	addi	a0,a0,-900 # 80008118 <digits+0xd8>
    800014a4:	fffff097          	auipc	ra,0xfffff
    800014a8:	0a4080e7          	jalr	164(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    800014ac:	00007517          	auipc	a0,0x7
    800014b0:	c8450513          	addi	a0,a0,-892 # 80008130 <digits+0xf0>
    800014b4:	fffff097          	auipc	ra,0xfffff
    800014b8:	094080e7          	jalr	148(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800014bc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800014be:	0532                	slli	a0,a0,0xc
    800014c0:	fffff097          	auipc	ra,0xfffff
    800014c4:	564080e7          	jalr	1380(ra) # 80000a24 <kfree>
    *pte = 0;
    800014c8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014cc:	995a                	add	s2,s2,s6
    800014ce:	f9397ce3          	bgeu	s2,s3,80001466 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800014d2:	4601                	li	a2,0
    800014d4:	85ca                	mv	a1,s2
    800014d6:	8552                	mv	a0,s4
    800014d8:	00000097          	auipc	ra,0x0
    800014dc:	c96080e7          	jalr	-874(ra) # 8000116e <walk>
    800014e0:	84aa                	mv	s1,a0
    800014e2:	d54d                	beqz	a0,8000148c <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800014e4:	6108                	ld	a0,0(a0)
    800014e6:	00157793          	andi	a5,a0,1
    800014ea:	dbcd                	beqz	a5,8000149c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800014ec:	3ff57793          	andi	a5,a0,1023
    800014f0:	fb778ee3          	beq	a5,s7,800014ac <uvmunmap+0x76>
    if(do_free){
    800014f4:	fc0a8ae3          	beqz	s5,800014c8 <uvmunmap+0x92>
    800014f8:	b7d1                	j	800014bc <uvmunmap+0x86>

00000000800014fa <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014fa:	1101                	addi	sp,sp,-32
    800014fc:	ec06                	sd	ra,24(sp)
    800014fe:	e822                	sd	s0,16(sp)
    80001500:	e426                	sd	s1,8(sp)
    80001502:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	6d4080e7          	jalr	1748(ra) # 80000bd8 <kalloc>
    8000150c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000150e:	c519                	beqz	a0,8000151c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001510:	6605                	lui	a2,0x1
    80001512:	4581                	li	a1,0
    80001514:	00000097          	auipc	ra,0x0
    80001518:	96e080e7          	jalr	-1682(ra) # 80000e82 <memset>
  return pagetable;
}
    8000151c:	8526                	mv	a0,s1
    8000151e:	60e2                	ld	ra,24(sp)
    80001520:	6442                	ld	s0,16(sp)
    80001522:	64a2                	ld	s1,8(sp)
    80001524:	6105                	addi	sp,sp,32
    80001526:	8082                	ret

0000000080001528 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001528:	7179                	addi	sp,sp,-48
    8000152a:	f406                	sd	ra,40(sp)
    8000152c:	f022                	sd	s0,32(sp)
    8000152e:	ec26                	sd	s1,24(sp)
    80001530:	e84a                	sd	s2,16(sp)
    80001532:	e44e                	sd	s3,8(sp)
    80001534:	e052                	sd	s4,0(sp)
    80001536:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001538:	6785                	lui	a5,0x1
    8000153a:	04f67863          	bgeu	a2,a5,8000158a <uvminit+0x62>
    8000153e:	8a2a                	mv	s4,a0
    80001540:	89ae                	mv	s3,a1
    80001542:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001544:	fffff097          	auipc	ra,0xfffff
    80001548:	694080e7          	jalr	1684(ra) # 80000bd8 <kalloc>
    8000154c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000154e:	6605                	lui	a2,0x1
    80001550:	4581                	li	a1,0
    80001552:	00000097          	auipc	ra,0x0
    80001556:	930080e7          	jalr	-1744(ra) # 80000e82 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000155a:	4779                	li	a4,30
    8000155c:	86ca                	mv	a3,s2
    8000155e:	6605                	lui	a2,0x1
    80001560:	4581                	li	a1,0
    80001562:	8552                	mv	a0,s4
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d50080e7          	jalr	-688(ra) # 800012b4 <mappages>
  memmove(mem, src, sz);
    8000156c:	8626                	mv	a2,s1
    8000156e:	85ce                	mv	a1,s3
    80001570:	854a                	mv	a0,s2
    80001572:	00000097          	auipc	ra,0x0
    80001576:	970080e7          	jalr	-1680(ra) # 80000ee2 <memmove>
}
    8000157a:	70a2                	ld	ra,40(sp)
    8000157c:	7402                	ld	s0,32(sp)
    8000157e:	64e2                	ld	s1,24(sp)
    80001580:	6942                	ld	s2,16(sp)
    80001582:	69a2                	ld	s3,8(sp)
    80001584:	6a02                	ld	s4,0(sp)
    80001586:	6145                	addi	sp,sp,48
    80001588:	8082                	ret
    panic("inituvm: more than a page");
    8000158a:	00007517          	auipc	a0,0x7
    8000158e:	bbe50513          	addi	a0,a0,-1090 # 80008148 <digits+0x108>
    80001592:	fffff097          	auipc	ra,0xfffff
    80001596:	fb6080e7          	jalr	-74(ra) # 80000548 <panic>

000000008000159a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000159a:	1101                	addi	sp,sp,-32
    8000159c:	ec06                	sd	ra,24(sp)
    8000159e:	e822                	sd	s0,16(sp)
    800015a0:	e426                	sd	s1,8(sp)
    800015a2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800015a4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800015a6:	00b67d63          	bgeu	a2,a1,800015c0 <uvmdealloc+0x26>
    800015aa:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800015ac:	6785                	lui	a5,0x1
    800015ae:	17fd                	addi	a5,a5,-1
    800015b0:	00f60733          	add	a4,a2,a5
    800015b4:	767d                	lui	a2,0xfffff
    800015b6:	8f71                	and	a4,a4,a2
    800015b8:	97ae                	add	a5,a5,a1
    800015ba:	8ff1                	and	a5,a5,a2
    800015bc:	00f76863          	bltu	a4,a5,800015cc <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800015c0:	8526                	mv	a0,s1
    800015c2:	60e2                	ld	ra,24(sp)
    800015c4:	6442                	ld	s0,16(sp)
    800015c6:	64a2                	ld	s1,8(sp)
    800015c8:	6105                	addi	sp,sp,32
    800015ca:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800015cc:	8f99                	sub	a5,a5,a4
    800015ce:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015d0:	4685                	li	a3,1
    800015d2:	0007861b          	sext.w	a2,a5
    800015d6:	85ba                	mv	a1,a4
    800015d8:	00000097          	auipc	ra,0x0
    800015dc:	e5e080e7          	jalr	-418(ra) # 80001436 <uvmunmap>
    800015e0:	b7c5                	j	800015c0 <uvmdealloc+0x26>

00000000800015e2 <uvmalloc>:
  if(newsz < oldsz)
    800015e2:	0ab66163          	bltu	a2,a1,80001684 <uvmalloc+0xa2>
{
    800015e6:	7139                	addi	sp,sp,-64
    800015e8:	fc06                	sd	ra,56(sp)
    800015ea:	f822                	sd	s0,48(sp)
    800015ec:	f426                	sd	s1,40(sp)
    800015ee:	f04a                	sd	s2,32(sp)
    800015f0:	ec4e                	sd	s3,24(sp)
    800015f2:	e852                	sd	s4,16(sp)
    800015f4:	e456                	sd	s5,8(sp)
    800015f6:	0080                	addi	s0,sp,64
    800015f8:	8aaa                	mv	s5,a0
    800015fa:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015fc:	6985                	lui	s3,0x1
    800015fe:	19fd                	addi	s3,s3,-1
    80001600:	95ce                	add	a1,a1,s3
    80001602:	79fd                	lui	s3,0xfffff
    80001604:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001608:	08c9f063          	bgeu	s3,a2,80001688 <uvmalloc+0xa6>
    8000160c:	894e                	mv	s2,s3
    mem = kalloc();
    8000160e:	fffff097          	auipc	ra,0xfffff
    80001612:	5ca080e7          	jalr	1482(ra) # 80000bd8 <kalloc>
    80001616:	84aa                	mv	s1,a0
    if(mem == 0){
    80001618:	c51d                	beqz	a0,80001646 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000161a:	6605                	lui	a2,0x1
    8000161c:	4581                	li	a1,0
    8000161e:	00000097          	auipc	ra,0x0
    80001622:	864080e7          	jalr	-1948(ra) # 80000e82 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001626:	4779                	li	a4,30
    80001628:	86a6                	mv	a3,s1
    8000162a:	6605                	lui	a2,0x1
    8000162c:	85ca                	mv	a1,s2
    8000162e:	8556                	mv	a0,s5
    80001630:	00000097          	auipc	ra,0x0
    80001634:	c84080e7          	jalr	-892(ra) # 800012b4 <mappages>
    80001638:	e905                	bnez	a0,80001668 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000163a:	6785                	lui	a5,0x1
    8000163c:	993e                	add	s2,s2,a5
    8000163e:	fd4968e3          	bltu	s2,s4,8000160e <uvmalloc+0x2c>
  return newsz;
    80001642:	8552                	mv	a0,s4
    80001644:	a809                	j	80001656 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001646:	864e                	mv	a2,s3
    80001648:	85ca                	mv	a1,s2
    8000164a:	8556                	mv	a0,s5
    8000164c:	00000097          	auipc	ra,0x0
    80001650:	f4e080e7          	jalr	-178(ra) # 8000159a <uvmdealloc>
      return 0;
    80001654:	4501                	li	a0,0
}
    80001656:	70e2                	ld	ra,56(sp)
    80001658:	7442                	ld	s0,48(sp)
    8000165a:	74a2                	ld	s1,40(sp)
    8000165c:	7902                	ld	s2,32(sp)
    8000165e:	69e2                	ld	s3,24(sp)
    80001660:	6a42                	ld	s4,16(sp)
    80001662:	6aa2                	ld	s5,8(sp)
    80001664:	6121                	addi	sp,sp,64
    80001666:	8082                	ret
      kfree(mem);
    80001668:	8526                	mv	a0,s1
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	3ba080e7          	jalr	954(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001672:	864e                	mv	a2,s3
    80001674:	85ca                	mv	a1,s2
    80001676:	8556                	mv	a0,s5
    80001678:	00000097          	auipc	ra,0x0
    8000167c:	f22080e7          	jalr	-222(ra) # 8000159a <uvmdealloc>
      return 0;
    80001680:	4501                	li	a0,0
    80001682:	bfd1                	j	80001656 <uvmalloc+0x74>
    return oldsz;
    80001684:	852e                	mv	a0,a1
}
    80001686:	8082                	ret
  return newsz;
    80001688:	8532                	mv	a0,a2
    8000168a:	b7f1                	j	80001656 <uvmalloc+0x74>

000000008000168c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000168c:	7179                	addi	sp,sp,-48
    8000168e:	f406                	sd	ra,40(sp)
    80001690:	f022                	sd	s0,32(sp)
    80001692:	ec26                	sd	s1,24(sp)
    80001694:	e84a                	sd	s2,16(sp)
    80001696:	e44e                	sd	s3,8(sp)
    80001698:	e052                	sd	s4,0(sp)
    8000169a:	1800                	addi	s0,sp,48
    8000169c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000169e:	84aa                	mv	s1,a0
    800016a0:	6905                	lui	s2,0x1
    800016a2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016a4:	4985                	li	s3,1
    800016a6:	a821                	j	800016be <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800016a8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800016aa:	0532                	slli	a0,a0,0xc
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	fe0080e7          	jalr	-32(ra) # 8000168c <freewalk>
      pagetable[i] = 0;
    800016b4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800016b8:	04a1                	addi	s1,s1,8
    800016ba:	03248163          	beq	s1,s2,800016dc <freewalk+0x50>
    pte_t pte = pagetable[i];
    800016be:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016c0:	00f57793          	andi	a5,a0,15
    800016c4:	ff3782e3          	beq	a5,s3,800016a8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800016c8:	8905                	andi	a0,a0,1
    800016ca:	d57d                	beqz	a0,800016b8 <freewalk+0x2c>
      panic("freewalk: leaf");
    800016cc:	00007517          	auipc	a0,0x7
    800016d0:	a9c50513          	addi	a0,a0,-1380 # 80008168 <digits+0x128>
    800016d4:	fffff097          	auipc	ra,0xfffff
    800016d8:	e74080e7          	jalr	-396(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800016dc:	8552                	mv	a0,s4
    800016de:	fffff097          	auipc	ra,0xfffff
    800016e2:	346080e7          	jalr	838(ra) # 80000a24 <kfree>
}
    800016e6:	70a2                	ld	ra,40(sp)
    800016e8:	7402                	ld	s0,32(sp)
    800016ea:	64e2                	ld	s1,24(sp)
    800016ec:	6942                	ld	s2,16(sp)
    800016ee:	69a2                	ld	s3,8(sp)
    800016f0:	6a02                	ld	s4,0(sp)
    800016f2:	6145                	addi	sp,sp,48
    800016f4:	8082                	ret

00000000800016f6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016f6:	1101                	addi	sp,sp,-32
    800016f8:	ec06                	sd	ra,24(sp)
    800016fa:	e822                	sd	s0,16(sp)
    800016fc:	e426                	sd	s1,8(sp)
    800016fe:	1000                	addi	s0,sp,32
    80001700:	84aa                	mv	s1,a0
  if(sz > 0)
    80001702:	e999                	bnez	a1,80001718 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001704:	8526                	mv	a0,s1
    80001706:	00000097          	auipc	ra,0x0
    8000170a:	f86080e7          	jalr	-122(ra) # 8000168c <freewalk>
}
    8000170e:	60e2                	ld	ra,24(sp)
    80001710:	6442                	ld	s0,16(sp)
    80001712:	64a2                	ld	s1,8(sp)
    80001714:	6105                	addi	sp,sp,32
    80001716:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001718:	6605                	lui	a2,0x1
    8000171a:	167d                	addi	a2,a2,-1
    8000171c:	962e                	add	a2,a2,a1
    8000171e:	4685                	li	a3,1
    80001720:	8231                	srli	a2,a2,0xc
    80001722:	4581                	li	a1,0
    80001724:	00000097          	auipc	ra,0x0
    80001728:	d12080e7          	jalr	-750(ra) # 80001436 <uvmunmap>
    8000172c:	bfe1                	j	80001704 <uvmfree+0xe>

000000008000172e <uvmcopy>:
// Copies both the page table and the
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    8000172e:	7139                	addi	sp,sp,-64
    80001730:	fc06                	sd	ra,56(sp)
    80001732:	f822                	sd	s0,48(sp)
    80001734:	f426                	sd	s1,40(sp)
    80001736:	f04a                	sd	s2,32(sp)
    80001738:	ec4e                	sd	s3,24(sp)
    8000173a:	e852                	sd	s4,16(sp)
    8000173c:	e456                	sd	s5,8(sp)
    8000173e:	e05a                	sd	s6,0(sp)
    80001740:	0080                	addi	s0,sp,64
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for (i = 0; i < sz; i += PGSIZE)
    80001742:	c645                	beqz	a2,800017ea <uvmcopy+0xbc>
    80001744:	8aaa                	mv	s5,a0
    80001746:	8a2e                	mv	s4,a1
    80001748:	89b2                	mv	s3,a2
    8000174a:	4481                	li	s1,0
  {
    if ((pte = walk(old, i, 0)) == 0)//// 使用walk函数查找旧页表中虚拟地址为i的页表项
    8000174c:	4601                	li	a2,0
    8000174e:	85a6                	mv	a1,s1
    80001750:	8556                	mv	a0,s5
    80001752:	00000097          	auipc	ra,0x0
    80001756:	a1c080e7          	jalr	-1508(ra) # 8000116e <walk>
    8000175a:	c139                	beqz	a0,800017a0 <uvmcopy+0x72>
      panic("uvmcopy: pte should exist");
    if ((*pte & PTE_V) == 0)// 检查页表项是否有效，即页是否已经被映射到物理内存
    8000175c:	6118                	ld	a4,0(a0)
    8000175e:	00177793          	andi	a5,a4,1
    80001762:	c7b9                	beqz	a5,800017b0 <uvmcopy+0x82>
      panic("uvmcopy: page not present");
    // 设置父进程的PTE_W为不可写，并且设置为COW页
    *pte = ((*pte) & (~PTE_W)) | PTE_COW;
    80001764:	efb77713          	andi	a4,a4,-261
    80001768:	10076713          	ori	a4,a4,256
    8000176c:	e118                	sd	a4,0(a0)
    flags = PTE_FLAGS(*pte); // 获取页表项的属性字段
    pa = PTE2PA(*pte);// 将页表项转换为物理地址
    8000176e:	00a75913          	srli	s2,a4,0xa
    80001772:	0932                	slli	s2,s2,0xc
    // 在新页表中映射子进程的虚拟地址到父进程的物理地址（共享页面）
    if (mappages(new, i, PGSIZE, pa, flags) != 0)
    80001774:	3fb77713          	andi	a4,a4,1019
    80001778:	86ca                	mv	a3,s2
    8000177a:	6605                	lui	a2,0x1
    8000177c:	85a6                	mv	a1,s1
    8000177e:	8552                	mv	a0,s4
    80001780:	00000097          	auipc	ra,0x0
    80001784:	b34080e7          	jalr	-1228(ra) # 800012b4 <mappages>
    80001788:	8b2a                	mv	s6,a0
    8000178a:	e91d                	bnez	a0,800017c0 <uvmcopy+0x92>
    {
      goto err;// 如果映射失败，跳转到错误处理部分
    }
    kaddref((void *)pa);// 增加物理页的引用计数
    8000178c:	854a                	mv	a0,s2
    8000178e:	fffff097          	auipc	ra,0xfffff
    80001792:	4f6080e7          	jalr	1270(ra) # 80000c84 <kaddref>
  for (i = 0; i < sz; i += PGSIZE)
    80001796:	6785                	lui	a5,0x1
    80001798:	94be                	add	s1,s1,a5
    8000179a:	fb34e9e3          	bltu	s1,s3,8000174c <uvmcopy+0x1e>
    8000179e:	a81d                	j	800017d4 <uvmcopy+0xa6>
      panic("uvmcopy: pte should exist");
    800017a0:	00007517          	auipc	a0,0x7
    800017a4:	9d850513          	addi	a0,a0,-1576 # 80008178 <digits+0x138>
    800017a8:	fffff097          	auipc	ra,0xfffff
    800017ac:	da0080e7          	jalr	-608(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800017b0:	00007517          	auipc	a0,0x7
    800017b4:	9e850513          	addi	a0,a0,-1560 # 80008198 <digits+0x158>
    800017b8:	fffff097          	auipc	ra,0xfffff
    800017bc:	d90080e7          	jalr	-624(ra) # 80000548 <panic>

err:
  // 当发生错误时，是否需要恢复错误之前对父进程
  // 页表的修改？如果不恢复，后面的程序是否能够纠正？
  // 在设计后面的程序时需要考虑到这一点
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017c0:	4685                	li	a3,1
    800017c2:	00c4d613          	srli	a2,s1,0xc
    800017c6:	4581                	li	a1,0
    800017c8:	8552                	mv	a0,s4
    800017ca:	00000097          	auipc	ra,0x0
    800017ce:	c6c080e7          	jalr	-916(ra) # 80001436 <uvmunmap>
  return -1;
    800017d2:	5b7d                	li	s6,-1
}
    800017d4:	855a                	mv	a0,s6
    800017d6:	70e2                	ld	ra,56(sp)
    800017d8:	7442                	ld	s0,48(sp)
    800017da:	74a2                	ld	s1,40(sp)
    800017dc:	7902                	ld	s2,32(sp)
    800017de:	69e2                	ld	s3,24(sp)
    800017e0:	6a42                	ld	s4,16(sp)
    800017e2:	6aa2                	ld	s5,8(sp)
    800017e4:	6b02                	ld	s6,0(sp)
    800017e6:	6121                	addi	sp,sp,64
    800017e8:	8082                	ret
  return 0;
    800017ea:	4b01                	li	s6,0
    800017ec:	b7e5                	j	800017d4 <uvmcopy+0xa6>

00000000800017ee <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800017ee:	1141                	addi	sp,sp,-16
    800017f0:	e406                	sd	ra,8(sp)
    800017f2:	e022                	sd	s0,0(sp)
    800017f4:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800017f6:	4601                	li	a2,0
    800017f8:	00000097          	auipc	ra,0x0
    800017fc:	976080e7          	jalr	-1674(ra) # 8000116e <walk>
  if(pte == 0)
    80001800:	c901                	beqz	a0,80001810 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001802:	611c                	ld	a5,0(a0)
    80001804:	9bbd                	andi	a5,a5,-17
    80001806:	e11c                	sd	a5,0(a0)
}
    80001808:	60a2                	ld	ra,8(sp)
    8000180a:	6402                	ld	s0,0(sp)
    8000180c:	0141                	addi	sp,sp,16
    8000180e:	8082                	ret
    panic("uvmclear");
    80001810:	00007517          	auipc	a0,0x7
    80001814:	9a850513          	addi	a0,a0,-1624 # 800081b8 <digits+0x178>
    80001818:	fffff097          	auipc	ra,0xfffff
    8000181c:	d30080e7          	jalr	-720(ra) # 80000548 <panic>

0000000080001820 <copyout>:
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;
  pte_t *pte; // add

  while (len > 0)
    80001820:	16068263          	beqz	a3,80001984 <copyout+0x164>
{
    80001824:	7119                	addi	sp,sp,-128
    80001826:	fc86                	sd	ra,120(sp)
    80001828:	f8a2                	sd	s0,112(sp)
    8000182a:	f4a6                	sd	s1,104(sp)
    8000182c:	f0ca                	sd	s2,96(sp)
    8000182e:	ecce                	sd	s3,88(sp)
    80001830:	e8d2                	sd	s4,80(sp)
    80001832:	e4d6                	sd	s5,72(sp)
    80001834:	e0da                	sd	s6,64(sp)
    80001836:	fc5e                	sd	s7,56(sp)
    80001838:	f862                	sd	s8,48(sp)
    8000183a:	f466                	sd	s9,40(sp)
    8000183c:	f06a                	sd	s10,32(sp)
    8000183e:	ec6e                	sd	s11,24(sp)
    80001840:	0100                	addi	s0,sp,128
    80001842:	8baa                	mv	s7,a0
    80001844:	8aae                	mv	s5,a1
    80001846:	8b32                	mv	s6,a2
    80001848:	8a36                	mv	s4,a3
  {
    va0 = PGROUNDDOWN(dstva);// 将目标虚拟地址向下舍入到页边界
    8000184a:	74fd                	lui	s1,0xfffff
    8000184c:	8ced                	and	s1,s1,a1
    if (va0 >= MAXVA)// 检查目标虚拟地址是否超出范围
    8000184e:	57fd                	li	a5,-1
    80001850:	83e9                	srli	a5,a5,0x1a
    80001852:	1297eb63          	bltu	a5,s1,80001988 <copyout+0x168>
      return -1;
    if ((pte = walk(pagetable, va0, 0)) == 0) // 在页表中查询目标虚拟地址对应的页表项
      return -1;
    if (((*pte & PTE_V) == 0) || ((*pte & PTE_U)) == 0) // 检查页表项是否有效且可用户访问
    80001856:	4cc5                	li	s9,17
      return -1;
    pa0 = PTE2PA(*pte); // 获取页表项对应的物理地址
    if (((*pte & PTE_W) == 0) && (*pte & PTE_COW))
    80001858:	10000d13          	li	s10,256
    {// 如果页表项为COW页，但不可写，则进行Copy-on-Write处理
      acquire_refcnt();
      if (kgetref((void *)pa0) == 1)
    8000185c:	4d85                	li	s11,1
    if (va0 >= MAXVA)// 检查目标虚拟地址是否超出范围
    8000185e:	8c3e                	mv	s8,a5
    80001860:	a8f1                	j	8000193c <copyout+0x11c>
      acquire_refcnt();
    80001862:	fffff097          	auipc	ra,0xfffff
    80001866:	454080e7          	jalr	1108(ra) # 80000cb6 <acquire_refcnt>
    pa0 = PTE2PA(*pte); // 获取页表项对应的物理地址
    8000186a:	00a9d993          	srli	s3,s3,0xa
    8000186e:	09b2                	slli	s3,s3,0xc
      if (kgetref((void *)pa0) == 1)
    80001870:	854e                	mv	a0,s3
    80001872:	fffff097          	auipc	ra,0xfffff
    80001876:	3e4080e7          	jalr	996(ra) # 80000c56 <kgetref>
    8000187a:	01b51f63          	bne	a0,s11,80001898 <copyout+0x78>
      { // 如果物理页的引用计数为1，直接设置页表项为可写
        *pte = (*pte | PTE_W) & (~PTE_COW);
    8000187e:	00093783          	ld	a5,0(s2) # 1000 <_entry-0x7ffff000>
    80001882:	efb7f793          	andi	a5,a5,-261
    80001886:	0047e793          	ori	a5,a5,4
    8000188a:	00f93023          	sd	a5,0(s2)
          release_refcnt();
          return -1;
        }
        kfree((void *)pa0);// 释放旧的物理页
      }
      release_refcnt();
    8000188e:	fffff097          	auipc	ra,0xfffff
    80001892:	448080e7          	jalr	1096(ra) # 80000cd6 <release_refcnt>
    80001896:	a0f1                	j	80001962 <copyout+0x142>
        char *mem = kalloc();
    80001898:	fffff097          	auipc	ra,0xfffff
    8000189c:	340080e7          	jalr	832(ra) # 80000bd8 <kalloc>
    800018a0:	f8a43423          	sd	a0,-120(s0)
        if (mem == 0)
    800018a4:	cd1d                	beqz	a0,800018e2 <copyout+0xc2>
        memmove(mem, (void *)pa0, PGSIZE);
    800018a6:	6605                	lui	a2,0x1
    800018a8:	85ce                	mv	a1,s3
    800018aa:	f8843503          	ld	a0,-120(s0)
    800018ae:	fffff097          	auipc	ra,0xfffff
    800018b2:	634080e7          	jalr	1588(ra) # 80000ee2 <memmove>
        uint newflags = (PTE_FLAGS(*pte) & (~PTE_COW)) | PTE_W;
    800018b6:	00093703          	ld	a4,0(s2)
    800018ba:	2fb77713          	andi	a4,a4,763
        if (mappages(pagetable, va0, PGSIZE, (uint64)mem, newflags) != 0)
    800018be:	00476713          	ori	a4,a4,4
    800018c2:	f8843683          	ld	a3,-120(s0)
    800018c6:	6605                	lui	a2,0x1
    800018c8:	85a6                	mv	a1,s1
    800018ca:	855e                	mv	a0,s7
    800018cc:	00000097          	auipc	ra,0x0
    800018d0:	9e8080e7          	jalr	-1560(ra) # 800012b4 <mappages>
    800018d4:	e50d                	bnez	a0,800018fe <copyout+0xde>
        kfree((void *)pa0);// 释放旧的物理页
    800018d6:	854e                	mv	a0,s3
    800018d8:	fffff097          	auipc	ra,0xfffff
    800018dc:	14c080e7          	jalr	332(ra) # 80000a24 <kfree>
    800018e0:	b77d                	j	8000188e <copyout+0x6e>
          printf("copyout(): memery alloc fault\n");
    800018e2:	00007517          	auipc	a0,0x7
    800018e6:	8e650513          	addi	a0,a0,-1818 # 800081c8 <digits+0x188>
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	ca8080e7          	jalr	-856(ra) # 80000592 <printf>
          release_refcnt();
    800018f2:	fffff097          	auipc	ra,0xfffff
    800018f6:	3e4080e7          	jalr	996(ra) # 80000cd6 <release_refcnt>
          return -1;
    800018fa:	557d                	li	a0,-1
    800018fc:	a859                	j	80001992 <copyout+0x172>
          kfree(mem);
    800018fe:	f8843503          	ld	a0,-120(s0)
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	122080e7          	jalr	290(ra) # 80000a24 <kfree>
          release_refcnt();
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	3cc080e7          	jalr	972(ra) # 80000cd6 <release_refcnt>
          return -1;
    80001912:	557d                	li	a0,-1
    80001914:	a8bd                	j	80001992 <copyout+0x172>
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if (n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001916:	409a84b3          	sub	s1,s5,s1
    8000191a:	0009861b          	sext.w	a2,s3
    8000191e:	85da                	mv	a1,s6
    80001920:	9526                	add	a0,a0,s1
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	5c0080e7          	jalr	1472(ra) # 80000ee2 <memmove>

    len -= n;
    8000192a:	413a0a33          	sub	s4,s4,s3
    src += n;
    8000192e:	9b4e                	add	s6,s6,s3
  while (len > 0)
    80001930:	040a0863          	beqz	s4,80001980 <copyout+0x160>
    if (va0 >= MAXVA)// 检查目标虚拟地址是否超出范围
    80001934:	052c6c63          	bltu	s8,s2,8000198c <copyout+0x16c>
    va0 = PGROUNDDOWN(dstva);// 将目标虚拟地址向下舍入到页边界
    80001938:	84ca                	mv	s1,s2
    dstva = va0 + PGSIZE;
    8000193a:	8aca                	mv	s5,s2
    if ((pte = walk(pagetable, va0, 0)) == 0) // 在页表中查询目标虚拟地址对应的页表项
    8000193c:	4601                	li	a2,0
    8000193e:	85a6                	mv	a1,s1
    80001940:	855e                	mv	a0,s7
    80001942:	00000097          	auipc	ra,0x0
    80001946:	82c080e7          	jalr	-2004(ra) # 8000116e <walk>
    8000194a:	892a                	mv	s2,a0
    8000194c:	c131                	beqz	a0,80001990 <copyout+0x170>
    if (((*pte & PTE_V) == 0) || ((*pte & PTE_U)) == 0) // 检查页表项是否有效且可用户访问
    8000194e:	00053983          	ld	s3,0(a0)
    80001952:	0119f793          	andi	a5,s3,17
    80001956:	05979d63          	bne	a5,s9,800019b0 <copyout+0x190>
    if (((*pte & PTE_W) == 0) && (*pte & PTE_COW))
    8000195a:	1049f793          	andi	a5,s3,260
    8000195e:	f1a782e3          	beq	a5,s10,80001862 <copyout+0x42>
    pa0 = walkaddr(pagetable, va0);// 获取目标虚拟地址对应的物理地址
    80001962:	85a6                	mv	a1,s1
    80001964:	855e                	mv	a0,s7
    80001966:	00000097          	auipc	ra,0x0
    8000196a:	8ae080e7          	jalr	-1874(ra) # 80001214 <walkaddr>
    if (pa0 == 0)
    8000196e:	c139                	beqz	a0,800019b4 <copyout+0x194>
    n = PGSIZE - (dstva - va0);
    80001970:	6905                	lui	s2,0x1
    80001972:	9926                	add	s2,s2,s1
    80001974:	415909b3          	sub	s3,s2,s5
    if (n > len)
    80001978:	f93a7fe3          	bgeu	s4,s3,80001916 <copyout+0xf6>
    8000197c:	89d2                	mv	s3,s4
    8000197e:	bf61                	j	80001916 <copyout+0xf6>
  }
  return 0;
    80001980:	4501                	li	a0,0
    80001982:	a801                	j	80001992 <copyout+0x172>
    80001984:	4501                	li	a0,0
}
    80001986:	8082                	ret
      return -1;
    80001988:	557d                	li	a0,-1
    8000198a:	a021                	j	80001992 <copyout+0x172>
    8000198c:	557d                	li	a0,-1
    8000198e:	a011                	j	80001992 <copyout+0x172>
      return -1;
    80001990:	557d                	li	a0,-1
}
    80001992:	70e6                	ld	ra,120(sp)
    80001994:	7446                	ld	s0,112(sp)
    80001996:	74a6                	ld	s1,104(sp)
    80001998:	7906                	ld	s2,96(sp)
    8000199a:	69e6                	ld	s3,88(sp)
    8000199c:	6a46                	ld	s4,80(sp)
    8000199e:	6aa6                	ld	s5,72(sp)
    800019a0:	6b06                	ld	s6,64(sp)
    800019a2:	7be2                	ld	s7,56(sp)
    800019a4:	7c42                	ld	s8,48(sp)
    800019a6:	7ca2                	ld	s9,40(sp)
    800019a8:	7d02                	ld	s10,32(sp)
    800019aa:	6de2                	ld	s11,24(sp)
    800019ac:	6109                	addi	sp,sp,128
    800019ae:	8082                	ret
      return -1;
    800019b0:	557d                	li	a0,-1
    800019b2:	b7c5                	j	80001992 <copyout+0x172>
      return -1;
    800019b4:	557d                	li	a0,-1
    800019b6:	bff1                	j	80001992 <copyout+0x172>

00000000800019b8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800019b8:	c6bd                	beqz	a3,80001a26 <copyin+0x6e>
{
    800019ba:	715d                	addi	sp,sp,-80
    800019bc:	e486                	sd	ra,72(sp)
    800019be:	e0a2                	sd	s0,64(sp)
    800019c0:	fc26                	sd	s1,56(sp)
    800019c2:	f84a                	sd	s2,48(sp)
    800019c4:	f44e                	sd	s3,40(sp)
    800019c6:	f052                	sd	s4,32(sp)
    800019c8:	ec56                	sd	s5,24(sp)
    800019ca:	e85a                	sd	s6,16(sp)
    800019cc:	e45e                	sd	s7,8(sp)
    800019ce:	e062                	sd	s8,0(sp)
    800019d0:	0880                	addi	s0,sp,80
    800019d2:	8b2a                	mv	s6,a0
    800019d4:	8a2e                	mv	s4,a1
    800019d6:	8c32                	mv	s8,a2
    800019d8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800019da:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800019dc:	6a85                	lui	s5,0x1
    800019de:	a015                	j	80001a02 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800019e0:	9562                	add	a0,a0,s8
    800019e2:	0004861b          	sext.w	a2,s1
    800019e6:	412505b3          	sub	a1,a0,s2
    800019ea:	8552                	mv	a0,s4
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	4f6080e7          	jalr	1270(ra) # 80000ee2 <memmove>

    len -= n;
    800019f4:	409989b3          	sub	s3,s3,s1
    dst += n;
    800019f8:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800019fa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800019fe:	02098263          	beqz	s3,80001a22 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001a02:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001a06:	85ca                	mv	a1,s2
    80001a08:	855a                	mv	a0,s6
    80001a0a:	00000097          	auipc	ra,0x0
    80001a0e:	80a080e7          	jalr	-2038(ra) # 80001214 <walkaddr>
    if(pa0 == 0)
    80001a12:	cd01                	beqz	a0,80001a2a <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001a14:	418904b3          	sub	s1,s2,s8
    80001a18:	94d6                	add	s1,s1,s5
    if(n > len)
    80001a1a:	fc99f3e3          	bgeu	s3,s1,800019e0 <copyin+0x28>
    80001a1e:	84ce                	mv	s1,s3
    80001a20:	b7c1                	j	800019e0 <copyin+0x28>
  }
  return 0;
    80001a22:	4501                	li	a0,0
    80001a24:	a021                	j	80001a2c <copyin+0x74>
    80001a26:	4501                	li	a0,0
}
    80001a28:	8082                	ret
      return -1;
    80001a2a:	557d                	li	a0,-1
}
    80001a2c:	60a6                	ld	ra,72(sp)
    80001a2e:	6406                	ld	s0,64(sp)
    80001a30:	74e2                	ld	s1,56(sp)
    80001a32:	7942                	ld	s2,48(sp)
    80001a34:	79a2                	ld	s3,40(sp)
    80001a36:	7a02                	ld	s4,32(sp)
    80001a38:	6ae2                	ld	s5,24(sp)
    80001a3a:	6b42                	ld	s6,16(sp)
    80001a3c:	6ba2                	ld	s7,8(sp)
    80001a3e:	6c02                	ld	s8,0(sp)
    80001a40:	6161                	addi	sp,sp,80
    80001a42:	8082                	ret

0000000080001a44 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001a44:	c6c5                	beqz	a3,80001aec <copyinstr+0xa8>
{
    80001a46:	715d                	addi	sp,sp,-80
    80001a48:	e486                	sd	ra,72(sp)
    80001a4a:	e0a2                	sd	s0,64(sp)
    80001a4c:	fc26                	sd	s1,56(sp)
    80001a4e:	f84a                	sd	s2,48(sp)
    80001a50:	f44e                	sd	s3,40(sp)
    80001a52:	f052                	sd	s4,32(sp)
    80001a54:	ec56                	sd	s5,24(sp)
    80001a56:	e85a                	sd	s6,16(sp)
    80001a58:	e45e                	sd	s7,8(sp)
    80001a5a:	0880                	addi	s0,sp,80
    80001a5c:	8a2a                	mv	s4,a0
    80001a5e:	8b2e                	mv	s6,a1
    80001a60:	8bb2                	mv	s7,a2
    80001a62:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001a64:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001a66:	6985                	lui	s3,0x1
    80001a68:	a035                	j	80001a94 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001a6a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001a6e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001a70:	0017b793          	seqz	a5,a5
    80001a74:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001a78:	60a6                	ld	ra,72(sp)
    80001a7a:	6406                	ld	s0,64(sp)
    80001a7c:	74e2                	ld	s1,56(sp)
    80001a7e:	7942                	ld	s2,48(sp)
    80001a80:	79a2                	ld	s3,40(sp)
    80001a82:	7a02                	ld	s4,32(sp)
    80001a84:	6ae2                	ld	s5,24(sp)
    80001a86:	6b42                	ld	s6,16(sp)
    80001a88:	6ba2                	ld	s7,8(sp)
    80001a8a:	6161                	addi	sp,sp,80
    80001a8c:	8082                	ret
    srcva = va0 + PGSIZE;
    80001a8e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001a92:	c8a9                	beqz	s1,80001ae4 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001a94:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001a98:	85ca                	mv	a1,s2
    80001a9a:	8552                	mv	a0,s4
    80001a9c:	fffff097          	auipc	ra,0xfffff
    80001aa0:	778080e7          	jalr	1912(ra) # 80001214 <walkaddr>
    if(pa0 == 0)
    80001aa4:	c131                	beqz	a0,80001ae8 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001aa6:	41790833          	sub	a6,s2,s7
    80001aaa:	984e                	add	a6,a6,s3
    if(n > max)
    80001aac:	0104f363          	bgeu	s1,a6,80001ab2 <copyinstr+0x6e>
    80001ab0:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001ab2:	955e                	add	a0,a0,s7
    80001ab4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001ab8:	fc080be3          	beqz	a6,80001a8e <copyinstr+0x4a>
    80001abc:	985a                	add	a6,a6,s6
    80001abe:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001ac0:	41650633          	sub	a2,a0,s6
    80001ac4:	14fd                	addi	s1,s1,-1
    80001ac6:	9b26                	add	s6,s6,s1
    80001ac8:	00f60733          	add	a4,a2,a5
    80001acc:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001ad0:	df49                	beqz	a4,80001a6a <copyinstr+0x26>
        *dst = *p;
    80001ad2:	00e78023          	sb	a4,0(a5)
      --max;
    80001ad6:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001ada:	0785                	addi	a5,a5,1
    while(n > 0){
    80001adc:	ff0796e3          	bne	a5,a6,80001ac8 <copyinstr+0x84>
      dst++;
    80001ae0:	8b42                	mv	s6,a6
    80001ae2:	b775                	j	80001a8e <copyinstr+0x4a>
    80001ae4:	4781                	li	a5,0
    80001ae6:	b769                	j	80001a70 <copyinstr+0x2c>
      return -1;
    80001ae8:	557d                	li	a0,-1
    80001aea:	b779                	j	80001a78 <copyinstr+0x34>
  int got_null = 0;
    80001aec:	4781                	li	a5,0
  if(got_null){
    80001aee:	0017b793          	seqz	a5,a5
    80001af2:	40f00533          	neg	a0,a5
}
    80001af6:	8082                	ret

0000000080001af8 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001af8:	1101                	addi	sp,sp,-32
    80001afa:	ec06                	sd	ra,24(sp)
    80001afc:	e822                	sd	s0,16(sp)
    80001afe:	e426                	sd	s1,8(sp)
    80001b00:	1000                	addi	s0,sp,32
    80001b02:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001b04:	fffff097          	auipc	ra,0xfffff
    80001b08:	208080e7          	jalr	520(ra) # 80000d0c <holding>
    80001b0c:	c909                	beqz	a0,80001b1e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001b0e:	749c                	ld	a5,40(s1)
    80001b10:	00978f63          	beq	a5,s1,80001b2e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001b14:	60e2                	ld	ra,24(sp)
    80001b16:	6442                	ld	s0,16(sp)
    80001b18:	64a2                	ld	s1,8(sp)
    80001b1a:	6105                	addi	sp,sp,32
    80001b1c:	8082                	ret
    panic("wakeup1");
    80001b1e:	00006517          	auipc	a0,0x6
    80001b22:	6ca50513          	addi	a0,a0,1738 # 800081e8 <digits+0x1a8>
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	a22080e7          	jalr	-1502(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001b2e:	4c98                	lw	a4,24(s1)
    80001b30:	4785                	li	a5,1
    80001b32:	fef711e3          	bne	a4,a5,80001b14 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001b36:	4789                	li	a5,2
    80001b38:	cc9c                	sw	a5,24(s1)
}
    80001b3a:	bfe9                	j	80001b14 <wakeup1+0x1c>

0000000080001b3c <procinit>:
{
    80001b3c:	715d                	addi	sp,sp,-80
    80001b3e:	e486                	sd	ra,72(sp)
    80001b40:	e0a2                	sd	s0,64(sp)
    80001b42:	fc26                	sd	s1,56(sp)
    80001b44:	f84a                	sd	s2,48(sp)
    80001b46:	f44e                	sd	s3,40(sp)
    80001b48:	f052                	sd	s4,32(sp)
    80001b4a:	ec56                	sd	s5,24(sp)
    80001b4c:	e85a                	sd	s6,16(sp)
    80001b4e:	e45e                	sd	s7,8(sp)
    80001b50:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001b52:	00006597          	auipc	a1,0x6
    80001b56:	69e58593          	addi	a1,a1,1694 # 800081f0 <digits+0x1b0>
    80001b5a:	00010517          	auipc	a0,0x10
    80001b5e:	e1650513          	addi	a0,a0,-490 # 80011970 <pid_lock>
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	194080e7          	jalr	404(ra) # 80000cf6 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b6a:	00010917          	auipc	s2,0x10
    80001b6e:	21e90913          	addi	s2,s2,542 # 80011d88 <proc>
      initlock(&p->lock, "proc");
    80001b72:	00006b97          	auipc	s7,0x6
    80001b76:	686b8b93          	addi	s7,s7,1670 # 800081f8 <digits+0x1b8>
      uint64 va = KSTACK((int) (p - proc));
    80001b7a:	8b4a                	mv	s6,s2
    80001b7c:	00006a97          	auipc	s5,0x6
    80001b80:	484a8a93          	addi	s5,s5,1156 # 80008000 <etext>
    80001b84:	040009b7          	lui	s3,0x4000
    80001b88:	19fd                	addi	s3,s3,-1
    80001b8a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b8c:	00016a17          	auipc	s4,0x16
    80001b90:	bfca0a13          	addi	s4,s4,-1028 # 80017788 <tickslock>
      initlock(&p->lock, "proc");
    80001b94:	85de                	mv	a1,s7
    80001b96:	854a                	mv	a0,s2
    80001b98:	fffff097          	auipc	ra,0xfffff
    80001b9c:	15e080e7          	jalr	350(ra) # 80000cf6 <initlock>
      char *pa = kalloc();
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	038080e7          	jalr	56(ra) # 80000bd8 <kalloc>
    80001ba8:	85aa                	mv	a1,a0
      if(pa == 0)
    80001baa:	c929                	beqz	a0,80001bfc <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001bac:	416904b3          	sub	s1,s2,s6
    80001bb0:	848d                	srai	s1,s1,0x3
    80001bb2:	000ab783          	ld	a5,0(s5)
    80001bb6:	02f484b3          	mul	s1,s1,a5
    80001bba:	2485                	addiw	s1,s1,1
    80001bbc:	00d4949b          	slliw	s1,s1,0xd
    80001bc0:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001bc4:	4699                	li	a3,6
    80001bc6:	6605                	lui	a2,0x1
    80001bc8:	8526                	mv	a0,s1
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	762080e7          	jalr	1890(ra) # 8000132c <kvmmap>
      p->kstack = va;
    80001bd2:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd6:	16890913          	addi	s2,s2,360
    80001bda:	fb491de3          	bne	s2,s4,80001b94 <procinit+0x58>
  kvminithart();
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	56c080e7          	jalr	1388(ra) # 8000114a <kvminithart>
}
    80001be6:	60a6                	ld	ra,72(sp)
    80001be8:	6406                	ld	s0,64(sp)
    80001bea:	74e2                	ld	s1,56(sp)
    80001bec:	7942                	ld	s2,48(sp)
    80001bee:	79a2                	ld	s3,40(sp)
    80001bf0:	7a02                	ld	s4,32(sp)
    80001bf2:	6ae2                	ld	s5,24(sp)
    80001bf4:	6b42                	ld	s6,16(sp)
    80001bf6:	6ba2                	ld	s7,8(sp)
    80001bf8:	6161                	addi	sp,sp,80
    80001bfa:	8082                	ret
        panic("kalloc");
    80001bfc:	00006517          	auipc	a0,0x6
    80001c00:	60450513          	addi	a0,a0,1540 # 80008200 <digits+0x1c0>
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	944080e7          	jalr	-1724(ra) # 80000548 <panic>

0000000080001c0c <cpuid>:
{
    80001c0c:	1141                	addi	sp,sp,-16
    80001c0e:	e422                	sd	s0,8(sp)
    80001c10:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c12:	8512                	mv	a0,tp
}
    80001c14:	2501                	sext.w	a0,a0
    80001c16:	6422                	ld	s0,8(sp)
    80001c18:	0141                	addi	sp,sp,16
    80001c1a:	8082                	ret

0000000080001c1c <mycpu>:
mycpu(void) {
    80001c1c:	1141                	addi	sp,sp,-16
    80001c1e:	e422                	sd	s0,8(sp)
    80001c20:	0800                	addi	s0,sp,16
    80001c22:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001c24:	2781                	sext.w	a5,a5
    80001c26:	079e                	slli	a5,a5,0x7
}
    80001c28:	00010517          	auipc	a0,0x10
    80001c2c:	d6050513          	addi	a0,a0,-672 # 80011988 <cpus>
    80001c30:	953e                	add	a0,a0,a5
    80001c32:	6422                	ld	s0,8(sp)
    80001c34:	0141                	addi	sp,sp,16
    80001c36:	8082                	ret

0000000080001c38 <myproc>:
myproc(void) {
    80001c38:	1101                	addi	sp,sp,-32
    80001c3a:	ec06                	sd	ra,24(sp)
    80001c3c:	e822                	sd	s0,16(sp)
    80001c3e:	e426                	sd	s1,8(sp)
    80001c40:	1000                	addi	s0,sp,32
  push_off();
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	0f8080e7          	jalr	248(ra) # 80000d3a <push_off>
    80001c4a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001c4c:	2781                	sext.w	a5,a5
    80001c4e:	079e                	slli	a5,a5,0x7
    80001c50:	00010717          	auipc	a4,0x10
    80001c54:	d2070713          	addi	a4,a4,-736 # 80011970 <pid_lock>
    80001c58:	97ba                	add	a5,a5,a4
    80001c5a:	6f84                	ld	s1,24(a5)
  pop_off();
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	17e080e7          	jalr	382(ra) # 80000dda <pop_off>
}
    80001c64:	8526                	mv	a0,s1
    80001c66:	60e2                	ld	ra,24(sp)
    80001c68:	6442                	ld	s0,16(sp)
    80001c6a:	64a2                	ld	s1,8(sp)
    80001c6c:	6105                	addi	sp,sp,32
    80001c6e:	8082                	ret

0000000080001c70 <forkret>:
{
    80001c70:	1141                	addi	sp,sp,-16
    80001c72:	e406                	sd	ra,8(sp)
    80001c74:	e022                	sd	s0,0(sp)
    80001c76:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	fc0080e7          	jalr	-64(ra) # 80001c38 <myproc>
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	1ba080e7          	jalr	442(ra) # 80000e3a <release>
  if (first) {
    80001c88:	00007797          	auipc	a5,0x7
    80001c8c:	c787a783          	lw	a5,-904(a5) # 80008900 <first.1670>
    80001c90:	eb89                	bnez	a5,80001ca2 <forkret+0x32>
  usertrapret();
    80001c92:	00001097          	auipc	ra,0x1
    80001c96:	c1c080e7          	jalr	-996(ra) # 800028ae <usertrapret>
}
    80001c9a:	60a2                	ld	ra,8(sp)
    80001c9c:	6402                	ld	s0,0(sp)
    80001c9e:	0141                	addi	sp,sp,16
    80001ca0:	8082                	ret
    first = 0;
    80001ca2:	00007797          	auipc	a5,0x7
    80001ca6:	c407af23          	sw	zero,-930(a5) # 80008900 <first.1670>
    fsinit(ROOTDEV);
    80001caa:	4505                	li	a0,1
    80001cac:	00002097          	auipc	ra,0x2
    80001cb0:	ab0080e7          	jalr	-1360(ra) # 8000375c <fsinit>
    80001cb4:	bff9                	j	80001c92 <forkret+0x22>

0000000080001cb6 <allocpid>:
allocpid() {
    80001cb6:	1101                	addi	sp,sp,-32
    80001cb8:	ec06                	sd	ra,24(sp)
    80001cba:	e822                	sd	s0,16(sp)
    80001cbc:	e426                	sd	s1,8(sp)
    80001cbe:	e04a                	sd	s2,0(sp)
    80001cc0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001cc2:	00010917          	auipc	s2,0x10
    80001cc6:	cae90913          	addi	s2,s2,-850 # 80011970 <pid_lock>
    80001cca:	854a                	mv	a0,s2
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	0ba080e7          	jalr	186(ra) # 80000d86 <acquire>
  pid = nextpid;
    80001cd4:	00007797          	auipc	a5,0x7
    80001cd8:	c3078793          	addi	a5,a5,-976 # 80008904 <nextpid>
    80001cdc:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001cde:	0014871b          	addiw	a4,s1,1
    80001ce2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ce4:	854a                	mv	a0,s2
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	154080e7          	jalr	340(ra) # 80000e3a <release>
}
    80001cee:	8526                	mv	a0,s1
    80001cf0:	60e2                	ld	ra,24(sp)
    80001cf2:	6442                	ld	s0,16(sp)
    80001cf4:	64a2                	ld	s1,8(sp)
    80001cf6:	6902                	ld	s2,0(sp)
    80001cf8:	6105                	addi	sp,sp,32
    80001cfa:	8082                	ret

0000000080001cfc <proc_pagetable>:
{
    80001cfc:	1101                	addi	sp,sp,-32
    80001cfe:	ec06                	sd	ra,24(sp)
    80001d00:	e822                	sd	s0,16(sp)
    80001d02:	e426                	sd	s1,8(sp)
    80001d04:	e04a                	sd	s2,0(sp)
    80001d06:	1000                	addi	s0,sp,32
    80001d08:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	7f0080e7          	jalr	2032(ra) # 800014fa <uvmcreate>
    80001d12:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001d14:	c121                	beqz	a0,80001d54 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d16:	4729                	li	a4,10
    80001d18:	00005697          	auipc	a3,0x5
    80001d1c:	2e868693          	addi	a3,a3,744 # 80007000 <_trampoline>
    80001d20:	6605                	lui	a2,0x1
    80001d22:	040005b7          	lui	a1,0x4000
    80001d26:	15fd                	addi	a1,a1,-1
    80001d28:	05b2                	slli	a1,a1,0xc
    80001d2a:	fffff097          	auipc	ra,0xfffff
    80001d2e:	58a080e7          	jalr	1418(ra) # 800012b4 <mappages>
    80001d32:	02054863          	bltz	a0,80001d62 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d36:	4719                	li	a4,6
    80001d38:	05893683          	ld	a3,88(s2)
    80001d3c:	6605                	lui	a2,0x1
    80001d3e:	020005b7          	lui	a1,0x2000
    80001d42:	15fd                	addi	a1,a1,-1
    80001d44:	05b6                	slli	a1,a1,0xd
    80001d46:	8526                	mv	a0,s1
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	56c080e7          	jalr	1388(ra) # 800012b4 <mappages>
    80001d50:	02054163          	bltz	a0,80001d72 <proc_pagetable+0x76>
}
    80001d54:	8526                	mv	a0,s1
    80001d56:	60e2                	ld	ra,24(sp)
    80001d58:	6442                	ld	s0,16(sp)
    80001d5a:	64a2                	ld	s1,8(sp)
    80001d5c:	6902                	ld	s2,0(sp)
    80001d5e:	6105                	addi	sp,sp,32
    80001d60:	8082                	ret
    uvmfree(pagetable, 0);
    80001d62:	4581                	li	a1,0
    80001d64:	8526                	mv	a0,s1
    80001d66:	00000097          	auipc	ra,0x0
    80001d6a:	990080e7          	jalr	-1648(ra) # 800016f6 <uvmfree>
    return 0;
    80001d6e:	4481                	li	s1,0
    80001d70:	b7d5                	j	80001d54 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d72:	4681                	li	a3,0
    80001d74:	4605                	li	a2,1
    80001d76:	040005b7          	lui	a1,0x4000
    80001d7a:	15fd                	addi	a1,a1,-1
    80001d7c:	05b2                	slli	a1,a1,0xc
    80001d7e:	8526                	mv	a0,s1
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	6b6080e7          	jalr	1718(ra) # 80001436 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d88:	4581                	li	a1,0
    80001d8a:	8526                	mv	a0,s1
    80001d8c:	00000097          	auipc	ra,0x0
    80001d90:	96a080e7          	jalr	-1686(ra) # 800016f6 <uvmfree>
    return 0;
    80001d94:	4481                	li	s1,0
    80001d96:	bf7d                	j	80001d54 <proc_pagetable+0x58>

0000000080001d98 <proc_freepagetable>:
{
    80001d98:	1101                	addi	sp,sp,-32
    80001d9a:	ec06                	sd	ra,24(sp)
    80001d9c:	e822                	sd	s0,16(sp)
    80001d9e:	e426                	sd	s1,8(sp)
    80001da0:	e04a                	sd	s2,0(sp)
    80001da2:	1000                	addi	s0,sp,32
    80001da4:	84aa                	mv	s1,a0
    80001da6:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001da8:	4681                	li	a3,0
    80001daa:	4605                	li	a2,1
    80001dac:	040005b7          	lui	a1,0x4000
    80001db0:	15fd                	addi	a1,a1,-1
    80001db2:	05b2                	slli	a1,a1,0xc
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	682080e7          	jalr	1666(ra) # 80001436 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001dbc:	4681                	li	a3,0
    80001dbe:	4605                	li	a2,1
    80001dc0:	020005b7          	lui	a1,0x2000
    80001dc4:	15fd                	addi	a1,a1,-1
    80001dc6:	05b6                	slli	a1,a1,0xd
    80001dc8:	8526                	mv	a0,s1
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	66c080e7          	jalr	1644(ra) # 80001436 <uvmunmap>
  uvmfree(pagetable, sz);
    80001dd2:	85ca                	mv	a1,s2
    80001dd4:	8526                	mv	a0,s1
    80001dd6:	00000097          	auipc	ra,0x0
    80001dda:	920080e7          	jalr	-1760(ra) # 800016f6 <uvmfree>
}
    80001dde:	60e2                	ld	ra,24(sp)
    80001de0:	6442                	ld	s0,16(sp)
    80001de2:	64a2                	ld	s1,8(sp)
    80001de4:	6902                	ld	s2,0(sp)
    80001de6:	6105                	addi	sp,sp,32
    80001de8:	8082                	ret

0000000080001dea <freeproc>:
{
    80001dea:	1101                	addi	sp,sp,-32
    80001dec:	ec06                	sd	ra,24(sp)
    80001dee:	e822                	sd	s0,16(sp)
    80001df0:	e426                	sd	s1,8(sp)
    80001df2:	1000                	addi	s0,sp,32
    80001df4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001df6:	6d28                	ld	a0,88(a0)
    80001df8:	c509                	beqz	a0,80001e02 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	c2a080e7          	jalr	-982(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001e02:	0404bc23          	sd	zero,88(s1) # fffffffffffff058 <end+0xffffffff7ffd9058>
  if(p->pagetable)
    80001e06:	68a8                	ld	a0,80(s1)
    80001e08:	c511                	beqz	a0,80001e14 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e0a:	64ac                	ld	a1,72(s1)
    80001e0c:	00000097          	auipc	ra,0x0
    80001e10:	f8c080e7          	jalr	-116(ra) # 80001d98 <proc_freepagetable>
  p->pagetable = 0;
    80001e14:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001e18:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001e1c:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001e20:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001e24:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001e28:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001e2c:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001e30:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001e34:	0004ac23          	sw	zero,24(s1)
}
    80001e38:	60e2                	ld	ra,24(sp)
    80001e3a:	6442                	ld	s0,16(sp)
    80001e3c:	64a2                	ld	s1,8(sp)
    80001e3e:	6105                	addi	sp,sp,32
    80001e40:	8082                	ret

0000000080001e42 <allocproc>:
{
    80001e42:	1101                	addi	sp,sp,-32
    80001e44:	ec06                	sd	ra,24(sp)
    80001e46:	e822                	sd	s0,16(sp)
    80001e48:	e426                	sd	s1,8(sp)
    80001e4a:	e04a                	sd	s2,0(sp)
    80001e4c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e4e:	00010497          	auipc	s1,0x10
    80001e52:	f3a48493          	addi	s1,s1,-198 # 80011d88 <proc>
    80001e56:	00016917          	auipc	s2,0x16
    80001e5a:	93290913          	addi	s2,s2,-1742 # 80017788 <tickslock>
    acquire(&p->lock);
    80001e5e:	8526                	mv	a0,s1
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	f26080e7          	jalr	-218(ra) # 80000d86 <acquire>
    if(p->state == UNUSED) {
    80001e68:	4c9c                	lw	a5,24(s1)
    80001e6a:	cf81                	beqz	a5,80001e82 <allocproc+0x40>
      release(&p->lock);
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	fcc080e7          	jalr	-52(ra) # 80000e3a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e76:	16848493          	addi	s1,s1,360
    80001e7a:	ff2492e3          	bne	s1,s2,80001e5e <allocproc+0x1c>
  return 0;
    80001e7e:	4481                	li	s1,0
    80001e80:	a0b9                	j	80001ece <allocproc+0x8c>
  p->pid = allocpid();
    80001e82:	00000097          	auipc	ra,0x0
    80001e86:	e34080e7          	jalr	-460(ra) # 80001cb6 <allocpid>
    80001e8a:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	d4c080e7          	jalr	-692(ra) # 80000bd8 <kalloc>
    80001e94:	892a                	mv	s2,a0
    80001e96:	eca8                	sd	a0,88(s1)
    80001e98:	c131                	beqz	a0,80001edc <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	00000097          	auipc	ra,0x0
    80001ea0:	e60080e7          	jalr	-416(ra) # 80001cfc <proc_pagetable>
    80001ea4:	892a                	mv	s2,a0
    80001ea6:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001ea8:	c129                	beqz	a0,80001eea <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001eaa:	07000613          	li	a2,112
    80001eae:	4581                	li	a1,0
    80001eb0:	06048513          	addi	a0,s1,96
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	fce080e7          	jalr	-50(ra) # 80000e82 <memset>
  p->context.ra = (uint64)forkret;
    80001ebc:	00000797          	auipc	a5,0x0
    80001ec0:	db478793          	addi	a5,a5,-588 # 80001c70 <forkret>
    80001ec4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ec6:	60bc                	ld	a5,64(s1)
    80001ec8:	6705                	lui	a4,0x1
    80001eca:	97ba                	add	a5,a5,a4
    80001ecc:	f4bc                	sd	a5,104(s1)
}
    80001ece:	8526                	mv	a0,s1
    80001ed0:	60e2                	ld	ra,24(sp)
    80001ed2:	6442                	ld	s0,16(sp)
    80001ed4:	64a2                	ld	s1,8(sp)
    80001ed6:	6902                	ld	s2,0(sp)
    80001ed8:	6105                	addi	sp,sp,32
    80001eda:	8082                	ret
    release(&p->lock);
    80001edc:	8526                	mv	a0,s1
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	f5c080e7          	jalr	-164(ra) # 80000e3a <release>
    return 0;
    80001ee6:	84ca                	mv	s1,s2
    80001ee8:	b7dd                	j	80001ece <allocproc+0x8c>
    freeproc(p);
    80001eea:	8526                	mv	a0,s1
    80001eec:	00000097          	auipc	ra,0x0
    80001ef0:	efe080e7          	jalr	-258(ra) # 80001dea <freeproc>
    release(&p->lock);
    80001ef4:	8526                	mv	a0,s1
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	f44080e7          	jalr	-188(ra) # 80000e3a <release>
    return 0;
    80001efe:	84ca                	mv	s1,s2
    80001f00:	b7f9                	j	80001ece <allocproc+0x8c>

0000000080001f02 <userinit>:
{
    80001f02:	1101                	addi	sp,sp,-32
    80001f04:	ec06                	sd	ra,24(sp)
    80001f06:	e822                	sd	s0,16(sp)
    80001f08:	e426                	sd	s1,8(sp)
    80001f0a:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f0c:	00000097          	auipc	ra,0x0
    80001f10:	f36080e7          	jalr	-202(ra) # 80001e42 <allocproc>
    80001f14:	84aa                	mv	s1,a0
  initproc = p;
    80001f16:	00007797          	auipc	a5,0x7
    80001f1a:	10a7b123          	sd	a0,258(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f1e:	03400613          	li	a2,52
    80001f22:	00007597          	auipc	a1,0x7
    80001f26:	9ee58593          	addi	a1,a1,-1554 # 80008910 <initcode>
    80001f2a:	6928                	ld	a0,80(a0)
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	5fc080e7          	jalr	1532(ra) # 80001528 <uvminit>
  p->sz = PGSIZE;
    80001f34:	6785                	lui	a5,0x1
    80001f36:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f38:	6cb8                	ld	a4,88(s1)
    80001f3a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f3e:	6cb8                	ld	a4,88(s1)
    80001f40:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f42:	4641                	li	a2,16
    80001f44:	00006597          	auipc	a1,0x6
    80001f48:	2c458593          	addi	a1,a1,708 # 80008208 <digits+0x1c8>
    80001f4c:	15848513          	addi	a0,s1,344
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	088080e7          	jalr	136(ra) # 80000fd8 <safestrcpy>
  p->cwd = namei("/");
    80001f58:	00006517          	auipc	a0,0x6
    80001f5c:	2c050513          	addi	a0,a0,704 # 80008218 <digits+0x1d8>
    80001f60:	00002097          	auipc	ra,0x2
    80001f64:	228080e7          	jalr	552(ra) # 80004188 <namei>
    80001f68:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f6c:	4789                	li	a5,2
    80001f6e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f70:	8526                	mv	a0,s1
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	ec8080e7          	jalr	-312(ra) # 80000e3a <release>
}
    80001f7a:	60e2                	ld	ra,24(sp)
    80001f7c:	6442                	ld	s0,16(sp)
    80001f7e:	64a2                	ld	s1,8(sp)
    80001f80:	6105                	addi	sp,sp,32
    80001f82:	8082                	ret

0000000080001f84 <growproc>:
{
    80001f84:	1101                	addi	sp,sp,-32
    80001f86:	ec06                	sd	ra,24(sp)
    80001f88:	e822                	sd	s0,16(sp)
    80001f8a:	e426                	sd	s1,8(sp)
    80001f8c:	e04a                	sd	s2,0(sp)
    80001f8e:	1000                	addi	s0,sp,32
    80001f90:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001f92:	00000097          	auipc	ra,0x0
    80001f96:	ca6080e7          	jalr	-858(ra) # 80001c38 <myproc>
    80001f9a:	892a                	mv	s2,a0
  sz = p->sz;
    80001f9c:	652c                	ld	a1,72(a0)
    80001f9e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001fa2:	00904f63          	bgtz	s1,80001fc0 <growproc+0x3c>
  } else if(n < 0){
    80001fa6:	0204cc63          	bltz	s1,80001fde <growproc+0x5a>
  p->sz = sz;
    80001faa:	1602                	slli	a2,a2,0x20
    80001fac:	9201                	srli	a2,a2,0x20
    80001fae:	04c93423          	sd	a2,72(s2)
  return 0;
    80001fb2:	4501                	li	a0,0
}
    80001fb4:	60e2                	ld	ra,24(sp)
    80001fb6:	6442                	ld	s0,16(sp)
    80001fb8:	64a2                	ld	s1,8(sp)
    80001fba:	6902                	ld	s2,0(sp)
    80001fbc:	6105                	addi	sp,sp,32
    80001fbe:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001fc0:	9e25                	addw	a2,a2,s1
    80001fc2:	1602                	slli	a2,a2,0x20
    80001fc4:	9201                	srli	a2,a2,0x20
    80001fc6:	1582                	slli	a1,a1,0x20
    80001fc8:	9181                	srli	a1,a1,0x20
    80001fca:	6928                	ld	a0,80(a0)
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	616080e7          	jalr	1558(ra) # 800015e2 <uvmalloc>
    80001fd4:	0005061b          	sext.w	a2,a0
    80001fd8:	fa69                	bnez	a2,80001faa <growproc+0x26>
      return -1;
    80001fda:	557d                	li	a0,-1
    80001fdc:	bfe1                	j	80001fb4 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fde:	9e25                	addw	a2,a2,s1
    80001fe0:	1602                	slli	a2,a2,0x20
    80001fe2:	9201                	srli	a2,a2,0x20
    80001fe4:	1582                	slli	a1,a1,0x20
    80001fe6:	9181                	srli	a1,a1,0x20
    80001fe8:	6928                	ld	a0,80(a0)
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	5b0080e7          	jalr	1456(ra) # 8000159a <uvmdealloc>
    80001ff2:	0005061b          	sext.w	a2,a0
    80001ff6:	bf55                	j	80001faa <growproc+0x26>

0000000080001ff8 <fork>:
{
    80001ff8:	7179                	addi	sp,sp,-48
    80001ffa:	f406                	sd	ra,40(sp)
    80001ffc:	f022                	sd	s0,32(sp)
    80001ffe:	ec26                	sd	s1,24(sp)
    80002000:	e84a                	sd	s2,16(sp)
    80002002:	e44e                	sd	s3,8(sp)
    80002004:	e052                	sd	s4,0(sp)
    80002006:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002008:	00000097          	auipc	ra,0x0
    8000200c:	c30080e7          	jalr	-976(ra) # 80001c38 <myproc>
    80002010:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002012:	00000097          	auipc	ra,0x0
    80002016:	e30080e7          	jalr	-464(ra) # 80001e42 <allocproc>
    8000201a:	c175                	beqz	a0,800020fe <fork+0x106>
    8000201c:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000201e:	04893603          	ld	a2,72(s2)
    80002022:	692c                	ld	a1,80(a0)
    80002024:	05093503          	ld	a0,80(s2)
    80002028:	fffff097          	auipc	ra,0xfffff
    8000202c:	706080e7          	jalr	1798(ra) # 8000172e <uvmcopy>
    80002030:	04054863          	bltz	a0,80002080 <fork+0x88>
  np->sz = p->sz;
    80002034:	04893783          	ld	a5,72(s2)
    80002038:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    8000203c:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80002040:	05893683          	ld	a3,88(s2)
    80002044:	87b6                	mv	a5,a3
    80002046:	0589b703          	ld	a4,88(s3)
    8000204a:	12068693          	addi	a3,a3,288
    8000204e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002052:	6788                	ld	a0,8(a5)
    80002054:	6b8c                	ld	a1,16(a5)
    80002056:	6f90                	ld	a2,24(a5)
    80002058:	01073023          	sd	a6,0(a4)
    8000205c:	e708                	sd	a0,8(a4)
    8000205e:	eb0c                	sd	a1,16(a4)
    80002060:	ef10                	sd	a2,24(a4)
    80002062:	02078793          	addi	a5,a5,32
    80002066:	02070713          	addi	a4,a4,32
    8000206a:	fed792e3          	bne	a5,a3,8000204e <fork+0x56>
  np->trapframe->a0 = 0;
    8000206e:	0589b783          	ld	a5,88(s3)
    80002072:	0607b823          	sd	zero,112(a5)
    80002076:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    8000207a:	15000a13          	li	s4,336
    8000207e:	a03d                	j	800020ac <fork+0xb4>
    freeproc(np);
    80002080:	854e                	mv	a0,s3
    80002082:	00000097          	auipc	ra,0x0
    80002086:	d68080e7          	jalr	-664(ra) # 80001dea <freeproc>
    release(&np->lock);
    8000208a:	854e                	mv	a0,s3
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	dae080e7          	jalr	-594(ra) # 80000e3a <release>
    return -1;
    80002094:	54fd                	li	s1,-1
    80002096:	a899                	j	800020ec <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002098:	00002097          	auipc	ra,0x2
    8000209c:	77c080e7          	jalr	1916(ra) # 80004814 <filedup>
    800020a0:	009987b3          	add	a5,s3,s1
    800020a4:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800020a6:	04a1                	addi	s1,s1,8
    800020a8:	01448763          	beq	s1,s4,800020b6 <fork+0xbe>
    if(p->ofile[i])
    800020ac:	009907b3          	add	a5,s2,s1
    800020b0:	6388                	ld	a0,0(a5)
    800020b2:	f17d                	bnez	a0,80002098 <fork+0xa0>
    800020b4:	bfcd                	j	800020a6 <fork+0xae>
  np->cwd = idup(p->cwd);
    800020b6:	15093503          	ld	a0,336(s2)
    800020ba:	00002097          	auipc	ra,0x2
    800020be:	8dc080e7          	jalr	-1828(ra) # 80003996 <idup>
    800020c2:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020c6:	4641                	li	a2,16
    800020c8:	15890593          	addi	a1,s2,344
    800020cc:	15898513          	addi	a0,s3,344
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	f08080e7          	jalr	-248(ra) # 80000fd8 <safestrcpy>
  pid = np->pid;
    800020d8:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    800020dc:	4789                	li	a5,2
    800020de:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800020e2:	854e                	mv	a0,s3
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	d56080e7          	jalr	-682(ra) # 80000e3a <release>
}
    800020ec:	8526                	mv	a0,s1
    800020ee:	70a2                	ld	ra,40(sp)
    800020f0:	7402                	ld	s0,32(sp)
    800020f2:	64e2                	ld	s1,24(sp)
    800020f4:	6942                	ld	s2,16(sp)
    800020f6:	69a2                	ld	s3,8(sp)
    800020f8:	6a02                	ld	s4,0(sp)
    800020fa:	6145                	addi	sp,sp,48
    800020fc:	8082                	ret
    return -1;
    800020fe:	54fd                	li	s1,-1
    80002100:	b7f5                	j	800020ec <fork+0xf4>

0000000080002102 <reparent>:
{
    80002102:	7179                	addi	sp,sp,-48
    80002104:	f406                	sd	ra,40(sp)
    80002106:	f022                	sd	s0,32(sp)
    80002108:	ec26                	sd	s1,24(sp)
    8000210a:	e84a                	sd	s2,16(sp)
    8000210c:	e44e                	sd	s3,8(sp)
    8000210e:	e052                	sd	s4,0(sp)
    80002110:	1800                	addi	s0,sp,48
    80002112:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002114:	00010497          	auipc	s1,0x10
    80002118:	c7448493          	addi	s1,s1,-908 # 80011d88 <proc>
      pp->parent = initproc;
    8000211c:	00007a17          	auipc	s4,0x7
    80002120:	efca0a13          	addi	s4,s4,-260 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002124:	00015997          	auipc	s3,0x15
    80002128:	66498993          	addi	s3,s3,1636 # 80017788 <tickslock>
    8000212c:	a029                	j	80002136 <reparent+0x34>
    8000212e:	16848493          	addi	s1,s1,360
    80002132:	03348363          	beq	s1,s3,80002158 <reparent+0x56>
    if(pp->parent == p){
    80002136:	709c                	ld	a5,32(s1)
    80002138:	ff279be3          	bne	a5,s2,8000212e <reparent+0x2c>
      acquire(&pp->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	c48080e7          	jalr	-952(ra) # 80000d86 <acquire>
      pp->parent = initproc;
    80002146:	000a3783          	ld	a5,0(s4)
    8000214a:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    8000214c:	8526                	mv	a0,s1
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	cec080e7          	jalr	-788(ra) # 80000e3a <release>
    80002156:	bfe1                	j	8000212e <reparent+0x2c>
}
    80002158:	70a2                	ld	ra,40(sp)
    8000215a:	7402                	ld	s0,32(sp)
    8000215c:	64e2                	ld	s1,24(sp)
    8000215e:	6942                	ld	s2,16(sp)
    80002160:	69a2                	ld	s3,8(sp)
    80002162:	6a02                	ld	s4,0(sp)
    80002164:	6145                	addi	sp,sp,48
    80002166:	8082                	ret

0000000080002168 <scheduler>:
{
    80002168:	711d                	addi	sp,sp,-96
    8000216a:	ec86                	sd	ra,88(sp)
    8000216c:	e8a2                	sd	s0,80(sp)
    8000216e:	e4a6                	sd	s1,72(sp)
    80002170:	e0ca                	sd	s2,64(sp)
    80002172:	fc4e                	sd	s3,56(sp)
    80002174:	f852                	sd	s4,48(sp)
    80002176:	f456                	sd	s5,40(sp)
    80002178:	f05a                	sd	s6,32(sp)
    8000217a:	ec5e                	sd	s7,24(sp)
    8000217c:	e862                	sd	s8,16(sp)
    8000217e:	e466                	sd	s9,8(sp)
    80002180:	1080                	addi	s0,sp,96
    80002182:	8792                	mv	a5,tp
  int id = r_tp();
    80002184:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002186:	00779c13          	slli	s8,a5,0x7
    8000218a:	0000f717          	auipc	a4,0xf
    8000218e:	7e670713          	addi	a4,a4,2022 # 80011970 <pid_lock>
    80002192:	9762                	add	a4,a4,s8
    80002194:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002198:	0000f717          	auipc	a4,0xf
    8000219c:	7f870713          	addi	a4,a4,2040 # 80011990 <cpus+0x8>
    800021a0:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    800021a2:	4a89                	li	s5,2
        c->proc = p;
    800021a4:	079e                	slli	a5,a5,0x7
    800021a6:	0000fb17          	auipc	s6,0xf
    800021aa:	7cab0b13          	addi	s6,s6,1994 # 80011970 <pid_lock>
    800021ae:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800021b0:	00015a17          	auipc	s4,0x15
    800021b4:	5d8a0a13          	addi	s4,s4,1496 # 80017788 <tickslock>
    int nproc = 0;
    800021b8:	4c81                	li	s9,0
    800021ba:	a8a1                	j	80002212 <scheduler+0xaa>
        p->state = RUNNING;
    800021bc:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    800021c0:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    800021c4:	06048593          	addi	a1,s1,96
    800021c8:	8562                	mv	a0,s8
    800021ca:	00000097          	auipc	ra,0x0
    800021ce:	63a080e7          	jalr	1594(ra) # 80002804 <swtch>
        c->proc = 0;
    800021d2:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    800021d6:	8526                	mv	a0,s1
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	c62080e7          	jalr	-926(ra) # 80000e3a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800021e0:	16848493          	addi	s1,s1,360
    800021e4:	01448d63          	beq	s1,s4,800021fe <scheduler+0x96>
      acquire(&p->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	b9c080e7          	jalr	-1124(ra) # 80000d86 <acquire>
      if(p->state != UNUSED) {
    800021f2:	4c9c                	lw	a5,24(s1)
    800021f4:	d3ed                	beqz	a5,800021d6 <scheduler+0x6e>
        nproc++;
    800021f6:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    800021f8:	fd579fe3          	bne	a5,s5,800021d6 <scheduler+0x6e>
    800021fc:	b7c1                	j	800021bc <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    800021fe:	013aca63          	blt	s5,s3,80002212 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002202:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002206:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000220a:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    8000220e:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002212:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002216:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000221a:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    8000221e:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002220:	00010497          	auipc	s1,0x10
    80002224:	b6848493          	addi	s1,s1,-1176 # 80011d88 <proc>
        p->state = RUNNING;
    80002228:	4b8d                	li	s7,3
    8000222a:	bf7d                	j	800021e8 <scheduler+0x80>

000000008000222c <sched>:
{
    8000222c:	7179                	addi	sp,sp,-48
    8000222e:	f406                	sd	ra,40(sp)
    80002230:	f022                	sd	s0,32(sp)
    80002232:	ec26                	sd	s1,24(sp)
    80002234:	e84a                	sd	s2,16(sp)
    80002236:	e44e                	sd	s3,8(sp)
    80002238:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000223a:	00000097          	auipc	ra,0x0
    8000223e:	9fe080e7          	jalr	-1538(ra) # 80001c38 <myproc>
    80002242:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	ac8080e7          	jalr	-1336(ra) # 80000d0c <holding>
    8000224c:	c93d                	beqz	a0,800022c2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000224e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002250:	2781                	sext.w	a5,a5
    80002252:	079e                	slli	a5,a5,0x7
    80002254:	0000f717          	auipc	a4,0xf
    80002258:	71c70713          	addi	a4,a4,1820 # 80011970 <pid_lock>
    8000225c:	97ba                	add	a5,a5,a4
    8000225e:	0907a703          	lw	a4,144(a5)
    80002262:	4785                	li	a5,1
    80002264:	06f71763          	bne	a4,a5,800022d2 <sched+0xa6>
  if(p->state == RUNNING)
    80002268:	4c98                	lw	a4,24(s1)
    8000226a:	478d                	li	a5,3
    8000226c:	06f70b63          	beq	a4,a5,800022e2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002270:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002274:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002276:	efb5                	bnez	a5,800022f2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002278:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000227a:	0000f917          	auipc	s2,0xf
    8000227e:	6f690913          	addi	s2,s2,1782 # 80011970 <pid_lock>
    80002282:	2781                	sext.w	a5,a5
    80002284:	079e                	slli	a5,a5,0x7
    80002286:	97ca                	add	a5,a5,s2
    80002288:	0947a983          	lw	s3,148(a5)
    8000228c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000228e:	2781                	sext.w	a5,a5
    80002290:	079e                	slli	a5,a5,0x7
    80002292:	0000f597          	auipc	a1,0xf
    80002296:	6fe58593          	addi	a1,a1,1790 # 80011990 <cpus+0x8>
    8000229a:	95be                	add	a1,a1,a5
    8000229c:	06048513          	addi	a0,s1,96
    800022a0:	00000097          	auipc	ra,0x0
    800022a4:	564080e7          	jalr	1380(ra) # 80002804 <swtch>
    800022a8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022aa:	2781                	sext.w	a5,a5
    800022ac:	079e                	slli	a5,a5,0x7
    800022ae:	97ca                	add	a5,a5,s2
    800022b0:	0937aa23          	sw	s3,148(a5)
}
    800022b4:	70a2                	ld	ra,40(sp)
    800022b6:	7402                	ld	s0,32(sp)
    800022b8:	64e2                	ld	s1,24(sp)
    800022ba:	6942                	ld	s2,16(sp)
    800022bc:	69a2                	ld	s3,8(sp)
    800022be:	6145                	addi	sp,sp,48
    800022c0:	8082                	ret
    panic("sched p->lock");
    800022c2:	00006517          	auipc	a0,0x6
    800022c6:	f5e50513          	addi	a0,a0,-162 # 80008220 <digits+0x1e0>
    800022ca:	ffffe097          	auipc	ra,0xffffe
    800022ce:	27e080e7          	jalr	638(ra) # 80000548 <panic>
    panic("sched locks");
    800022d2:	00006517          	auipc	a0,0x6
    800022d6:	f5e50513          	addi	a0,a0,-162 # 80008230 <digits+0x1f0>
    800022da:	ffffe097          	auipc	ra,0xffffe
    800022de:	26e080e7          	jalr	622(ra) # 80000548 <panic>
    panic("sched running");
    800022e2:	00006517          	auipc	a0,0x6
    800022e6:	f5e50513          	addi	a0,a0,-162 # 80008240 <digits+0x200>
    800022ea:	ffffe097          	auipc	ra,0xffffe
    800022ee:	25e080e7          	jalr	606(ra) # 80000548 <panic>
    panic("sched interruptible");
    800022f2:	00006517          	auipc	a0,0x6
    800022f6:	f5e50513          	addi	a0,a0,-162 # 80008250 <digits+0x210>
    800022fa:	ffffe097          	auipc	ra,0xffffe
    800022fe:	24e080e7          	jalr	590(ra) # 80000548 <panic>

0000000080002302 <exit>:
{
    80002302:	7179                	addi	sp,sp,-48
    80002304:	f406                	sd	ra,40(sp)
    80002306:	f022                	sd	s0,32(sp)
    80002308:	ec26                	sd	s1,24(sp)
    8000230a:	e84a                	sd	s2,16(sp)
    8000230c:	e44e                	sd	s3,8(sp)
    8000230e:	e052                	sd	s4,0(sp)
    80002310:	1800                	addi	s0,sp,48
    80002312:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002314:	00000097          	auipc	ra,0x0
    80002318:	924080e7          	jalr	-1756(ra) # 80001c38 <myproc>
    8000231c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000231e:	00007797          	auipc	a5,0x7
    80002322:	cfa7b783          	ld	a5,-774(a5) # 80009018 <initproc>
    80002326:	0d050493          	addi	s1,a0,208
    8000232a:	15050913          	addi	s2,a0,336
    8000232e:	02a79363          	bne	a5,a0,80002354 <exit+0x52>
    panic("init exiting");
    80002332:	00006517          	auipc	a0,0x6
    80002336:	f3650513          	addi	a0,a0,-202 # 80008268 <digits+0x228>
    8000233a:	ffffe097          	auipc	ra,0xffffe
    8000233e:	20e080e7          	jalr	526(ra) # 80000548 <panic>
      fileclose(f);
    80002342:	00002097          	auipc	ra,0x2
    80002346:	524080e7          	jalr	1316(ra) # 80004866 <fileclose>
      p->ofile[fd] = 0;
    8000234a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000234e:	04a1                	addi	s1,s1,8
    80002350:	01248563          	beq	s1,s2,8000235a <exit+0x58>
    if(p->ofile[fd]){
    80002354:	6088                	ld	a0,0(s1)
    80002356:	f575                	bnez	a0,80002342 <exit+0x40>
    80002358:	bfdd                	j	8000234e <exit+0x4c>
  begin_op();
    8000235a:	00002097          	auipc	ra,0x2
    8000235e:	03a080e7          	jalr	58(ra) # 80004394 <begin_op>
  iput(p->cwd);
    80002362:	1509b503          	ld	a0,336(s3)
    80002366:	00002097          	auipc	ra,0x2
    8000236a:	828080e7          	jalr	-2008(ra) # 80003b8e <iput>
  end_op();
    8000236e:	00002097          	auipc	ra,0x2
    80002372:	0a6080e7          	jalr	166(ra) # 80004414 <end_op>
  p->cwd = 0;
    80002376:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000237a:	00007497          	auipc	s1,0x7
    8000237e:	c9e48493          	addi	s1,s1,-866 # 80009018 <initproc>
    80002382:	6088                	ld	a0,0(s1)
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	a02080e7          	jalr	-1534(ra) # 80000d86 <acquire>
  wakeup1(initproc);
    8000238c:	6088                	ld	a0,0(s1)
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	76a080e7          	jalr	1898(ra) # 80001af8 <wakeup1>
  release(&initproc->lock);
    80002396:	6088                	ld	a0,0(s1)
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	aa2080e7          	jalr	-1374(ra) # 80000e3a <release>
  acquire(&p->lock);
    800023a0:	854e                	mv	a0,s3
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	9e4080e7          	jalr	-1564(ra) # 80000d86 <acquire>
  struct proc *original_parent = p->parent;
    800023aa:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800023ae:	854e                	mv	a0,s3
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	a8a080e7          	jalr	-1398(ra) # 80000e3a <release>
  acquire(&original_parent->lock);
    800023b8:	8526                	mv	a0,s1
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	9cc080e7          	jalr	-1588(ra) # 80000d86 <acquire>
  acquire(&p->lock);
    800023c2:	854e                	mv	a0,s3
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	9c2080e7          	jalr	-1598(ra) # 80000d86 <acquire>
  reparent(p);
    800023cc:	854e                	mv	a0,s3
    800023ce:	00000097          	auipc	ra,0x0
    800023d2:	d34080e7          	jalr	-716(ra) # 80002102 <reparent>
  wakeup1(original_parent);
    800023d6:	8526                	mv	a0,s1
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	720080e7          	jalr	1824(ra) # 80001af8 <wakeup1>
  p->xstate = status;
    800023e0:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800023e4:	4791                	li	a5,4
    800023e6:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800023ea:	8526                	mv	a0,s1
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	a4e080e7          	jalr	-1458(ra) # 80000e3a <release>
  sched();
    800023f4:	00000097          	auipc	ra,0x0
    800023f8:	e38080e7          	jalr	-456(ra) # 8000222c <sched>
  panic("zombie exit");
    800023fc:	00006517          	auipc	a0,0x6
    80002400:	e7c50513          	addi	a0,a0,-388 # 80008278 <digits+0x238>
    80002404:	ffffe097          	auipc	ra,0xffffe
    80002408:	144080e7          	jalr	324(ra) # 80000548 <panic>

000000008000240c <yield>:
{
    8000240c:	1101                	addi	sp,sp,-32
    8000240e:	ec06                	sd	ra,24(sp)
    80002410:	e822                	sd	s0,16(sp)
    80002412:	e426                	sd	s1,8(sp)
    80002414:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002416:	00000097          	auipc	ra,0x0
    8000241a:	822080e7          	jalr	-2014(ra) # 80001c38 <myproc>
    8000241e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002420:	fffff097          	auipc	ra,0xfffff
    80002424:	966080e7          	jalr	-1690(ra) # 80000d86 <acquire>
  p->state = RUNNABLE;
    80002428:	4789                	li	a5,2
    8000242a:	cc9c                	sw	a5,24(s1)
  sched();
    8000242c:	00000097          	auipc	ra,0x0
    80002430:	e00080e7          	jalr	-512(ra) # 8000222c <sched>
  release(&p->lock);
    80002434:	8526                	mv	a0,s1
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	a04080e7          	jalr	-1532(ra) # 80000e3a <release>
}
    8000243e:	60e2                	ld	ra,24(sp)
    80002440:	6442                	ld	s0,16(sp)
    80002442:	64a2                	ld	s1,8(sp)
    80002444:	6105                	addi	sp,sp,32
    80002446:	8082                	ret

0000000080002448 <sleep>:
{
    80002448:	7179                	addi	sp,sp,-48
    8000244a:	f406                	sd	ra,40(sp)
    8000244c:	f022                	sd	s0,32(sp)
    8000244e:	ec26                	sd	s1,24(sp)
    80002450:	e84a                	sd	s2,16(sp)
    80002452:	e44e                	sd	s3,8(sp)
    80002454:	1800                	addi	s0,sp,48
    80002456:	89aa                	mv	s3,a0
    80002458:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	7de080e7          	jalr	2014(ra) # 80001c38 <myproc>
    80002462:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002464:	05250663          	beq	a0,s2,800024b0 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	91e080e7          	jalr	-1762(ra) # 80000d86 <acquire>
    release(lk);
    80002470:	854a                	mv	a0,s2
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	9c8080e7          	jalr	-1592(ra) # 80000e3a <release>
  p->chan = chan;
    8000247a:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000247e:	4785                	li	a5,1
    80002480:	cc9c                	sw	a5,24(s1)
  sched();
    80002482:	00000097          	auipc	ra,0x0
    80002486:	daa080e7          	jalr	-598(ra) # 8000222c <sched>
  p->chan = 0;
    8000248a:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000248e:	8526                	mv	a0,s1
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	9aa080e7          	jalr	-1622(ra) # 80000e3a <release>
    acquire(lk);
    80002498:	854a                	mv	a0,s2
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	8ec080e7          	jalr	-1812(ra) # 80000d86 <acquire>
}
    800024a2:	70a2                	ld	ra,40(sp)
    800024a4:	7402                	ld	s0,32(sp)
    800024a6:	64e2                	ld	s1,24(sp)
    800024a8:	6942                	ld	s2,16(sp)
    800024aa:	69a2                	ld	s3,8(sp)
    800024ac:	6145                	addi	sp,sp,48
    800024ae:	8082                	ret
  p->chan = chan;
    800024b0:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800024b4:	4785                	li	a5,1
    800024b6:	cd1c                	sw	a5,24(a0)
  sched();
    800024b8:	00000097          	auipc	ra,0x0
    800024bc:	d74080e7          	jalr	-652(ra) # 8000222c <sched>
  p->chan = 0;
    800024c0:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800024c4:	bff9                	j	800024a2 <sleep+0x5a>

00000000800024c6 <wait>:
{
    800024c6:	715d                	addi	sp,sp,-80
    800024c8:	e486                	sd	ra,72(sp)
    800024ca:	e0a2                	sd	s0,64(sp)
    800024cc:	fc26                	sd	s1,56(sp)
    800024ce:	f84a                	sd	s2,48(sp)
    800024d0:	f44e                	sd	s3,40(sp)
    800024d2:	f052                	sd	s4,32(sp)
    800024d4:	ec56                	sd	s5,24(sp)
    800024d6:	e85a                	sd	s6,16(sp)
    800024d8:	e45e                	sd	s7,8(sp)
    800024da:	e062                	sd	s8,0(sp)
    800024dc:	0880                	addi	s0,sp,80
    800024de:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	758080e7          	jalr	1880(ra) # 80001c38 <myproc>
    800024e8:	892a                	mv	s2,a0
  acquire(&p->lock);
    800024ea:	8c2a                	mv	s8,a0
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	89a080e7          	jalr	-1894(ra) # 80000d86 <acquire>
    havekids = 0;
    800024f4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800024f6:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800024f8:	00015997          	auipc	s3,0x15
    800024fc:	29098993          	addi	s3,s3,656 # 80017788 <tickslock>
        havekids = 1;
    80002500:	4a85                	li	s5,1
    havekids = 0;
    80002502:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002504:	00010497          	auipc	s1,0x10
    80002508:	88448493          	addi	s1,s1,-1916 # 80011d88 <proc>
    8000250c:	a08d                	j	8000256e <wait+0xa8>
          pid = np->pid;
    8000250e:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002512:	000b0e63          	beqz	s6,8000252e <wait+0x68>
    80002516:	4691                	li	a3,4
    80002518:	03448613          	addi	a2,s1,52
    8000251c:	85da                	mv	a1,s6
    8000251e:	05093503          	ld	a0,80(s2)
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	2fe080e7          	jalr	766(ra) # 80001820 <copyout>
    8000252a:	02054263          	bltz	a0,8000254e <wait+0x88>
          freeproc(np);
    8000252e:	8526                	mv	a0,s1
    80002530:	00000097          	auipc	ra,0x0
    80002534:	8ba080e7          	jalr	-1862(ra) # 80001dea <freeproc>
          release(&np->lock);
    80002538:	8526                	mv	a0,s1
    8000253a:	fffff097          	auipc	ra,0xfffff
    8000253e:	900080e7          	jalr	-1792(ra) # 80000e3a <release>
          release(&p->lock);
    80002542:	854a                	mv	a0,s2
    80002544:	fffff097          	auipc	ra,0xfffff
    80002548:	8f6080e7          	jalr	-1802(ra) # 80000e3a <release>
          return pid;
    8000254c:	a8a9                	j	800025a6 <wait+0xe0>
            release(&np->lock);
    8000254e:	8526                	mv	a0,s1
    80002550:	fffff097          	auipc	ra,0xfffff
    80002554:	8ea080e7          	jalr	-1814(ra) # 80000e3a <release>
            release(&p->lock);
    80002558:	854a                	mv	a0,s2
    8000255a:	fffff097          	auipc	ra,0xfffff
    8000255e:	8e0080e7          	jalr	-1824(ra) # 80000e3a <release>
            return -1;
    80002562:	59fd                	li	s3,-1
    80002564:	a089                	j	800025a6 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002566:	16848493          	addi	s1,s1,360
    8000256a:	03348463          	beq	s1,s3,80002592 <wait+0xcc>
      if(np->parent == p){
    8000256e:	709c                	ld	a5,32(s1)
    80002570:	ff279be3          	bne	a5,s2,80002566 <wait+0xa0>
        acquire(&np->lock);
    80002574:	8526                	mv	a0,s1
    80002576:	fffff097          	auipc	ra,0xfffff
    8000257a:	810080e7          	jalr	-2032(ra) # 80000d86 <acquire>
        if(np->state == ZOMBIE){
    8000257e:	4c9c                	lw	a5,24(s1)
    80002580:	f94787e3          	beq	a5,s4,8000250e <wait+0x48>
        release(&np->lock);
    80002584:	8526                	mv	a0,s1
    80002586:	fffff097          	auipc	ra,0xfffff
    8000258a:	8b4080e7          	jalr	-1868(ra) # 80000e3a <release>
        havekids = 1;
    8000258e:	8756                	mv	a4,s5
    80002590:	bfd9                	j	80002566 <wait+0xa0>
    if(!havekids || p->killed){
    80002592:	c701                	beqz	a4,8000259a <wait+0xd4>
    80002594:	03092783          	lw	a5,48(s2)
    80002598:	c785                	beqz	a5,800025c0 <wait+0xfa>
      release(&p->lock);
    8000259a:	854a                	mv	a0,s2
    8000259c:	fffff097          	auipc	ra,0xfffff
    800025a0:	89e080e7          	jalr	-1890(ra) # 80000e3a <release>
      return -1;
    800025a4:	59fd                	li	s3,-1
}
    800025a6:	854e                	mv	a0,s3
    800025a8:	60a6                	ld	ra,72(sp)
    800025aa:	6406                	ld	s0,64(sp)
    800025ac:	74e2                	ld	s1,56(sp)
    800025ae:	7942                	ld	s2,48(sp)
    800025b0:	79a2                	ld	s3,40(sp)
    800025b2:	7a02                	ld	s4,32(sp)
    800025b4:	6ae2                	ld	s5,24(sp)
    800025b6:	6b42                	ld	s6,16(sp)
    800025b8:	6ba2                	ld	s7,8(sp)
    800025ba:	6c02                	ld	s8,0(sp)
    800025bc:	6161                	addi	sp,sp,80
    800025be:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800025c0:	85e2                	mv	a1,s8
    800025c2:	854a                	mv	a0,s2
    800025c4:	00000097          	auipc	ra,0x0
    800025c8:	e84080e7          	jalr	-380(ra) # 80002448 <sleep>
    havekids = 0;
    800025cc:	bf1d                	j	80002502 <wait+0x3c>

00000000800025ce <wakeup>:
{
    800025ce:	7139                	addi	sp,sp,-64
    800025d0:	fc06                	sd	ra,56(sp)
    800025d2:	f822                	sd	s0,48(sp)
    800025d4:	f426                	sd	s1,40(sp)
    800025d6:	f04a                	sd	s2,32(sp)
    800025d8:	ec4e                	sd	s3,24(sp)
    800025da:	e852                	sd	s4,16(sp)
    800025dc:	e456                	sd	s5,8(sp)
    800025de:	0080                	addi	s0,sp,64
    800025e0:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800025e2:	0000f497          	auipc	s1,0xf
    800025e6:	7a648493          	addi	s1,s1,1958 # 80011d88 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800025ea:	4985                	li	s3,1
      p->state = RUNNABLE;
    800025ec:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800025ee:	00015917          	auipc	s2,0x15
    800025f2:	19a90913          	addi	s2,s2,410 # 80017788 <tickslock>
    800025f6:	a821                	j	8000260e <wakeup+0x40>
      p->state = RUNNABLE;
    800025f8:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800025fc:	8526                	mv	a0,s1
    800025fe:	fffff097          	auipc	ra,0xfffff
    80002602:	83c080e7          	jalr	-1988(ra) # 80000e3a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002606:	16848493          	addi	s1,s1,360
    8000260a:	01248e63          	beq	s1,s2,80002626 <wakeup+0x58>
    acquire(&p->lock);
    8000260e:	8526                	mv	a0,s1
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	776080e7          	jalr	1910(ra) # 80000d86 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002618:	4c9c                	lw	a5,24(s1)
    8000261a:	ff3791e3          	bne	a5,s3,800025fc <wakeup+0x2e>
    8000261e:	749c                	ld	a5,40(s1)
    80002620:	fd479ee3          	bne	a5,s4,800025fc <wakeup+0x2e>
    80002624:	bfd1                	j	800025f8 <wakeup+0x2a>
}
    80002626:	70e2                	ld	ra,56(sp)
    80002628:	7442                	ld	s0,48(sp)
    8000262a:	74a2                	ld	s1,40(sp)
    8000262c:	7902                	ld	s2,32(sp)
    8000262e:	69e2                	ld	s3,24(sp)
    80002630:	6a42                	ld	s4,16(sp)
    80002632:	6aa2                	ld	s5,8(sp)
    80002634:	6121                	addi	sp,sp,64
    80002636:	8082                	ret

0000000080002638 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002638:	7179                	addi	sp,sp,-48
    8000263a:	f406                	sd	ra,40(sp)
    8000263c:	f022                	sd	s0,32(sp)
    8000263e:	ec26                	sd	s1,24(sp)
    80002640:	e84a                	sd	s2,16(sp)
    80002642:	e44e                	sd	s3,8(sp)
    80002644:	1800                	addi	s0,sp,48
    80002646:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002648:	0000f497          	auipc	s1,0xf
    8000264c:	74048493          	addi	s1,s1,1856 # 80011d88 <proc>
    80002650:	00015997          	auipc	s3,0x15
    80002654:	13898993          	addi	s3,s3,312 # 80017788 <tickslock>
    acquire(&p->lock);
    80002658:	8526                	mv	a0,s1
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	72c080e7          	jalr	1836(ra) # 80000d86 <acquire>
    if(p->pid == pid){
    80002662:	5c9c                	lw	a5,56(s1)
    80002664:	01278d63          	beq	a5,s2,8000267e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002668:	8526                	mv	a0,s1
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	7d0080e7          	jalr	2000(ra) # 80000e3a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002672:	16848493          	addi	s1,s1,360
    80002676:	ff3491e3          	bne	s1,s3,80002658 <kill+0x20>
  }
  return -1;
    8000267a:	557d                	li	a0,-1
    8000267c:	a829                	j	80002696 <kill+0x5e>
      p->killed = 1;
    8000267e:	4785                	li	a5,1
    80002680:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002682:	4c98                	lw	a4,24(s1)
    80002684:	4785                	li	a5,1
    80002686:	00f70f63          	beq	a4,a5,800026a4 <kill+0x6c>
      release(&p->lock);
    8000268a:	8526                	mv	a0,s1
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	7ae080e7          	jalr	1966(ra) # 80000e3a <release>
      return 0;
    80002694:	4501                	li	a0,0
}
    80002696:	70a2                	ld	ra,40(sp)
    80002698:	7402                	ld	s0,32(sp)
    8000269a:	64e2                	ld	s1,24(sp)
    8000269c:	6942                	ld	s2,16(sp)
    8000269e:	69a2                	ld	s3,8(sp)
    800026a0:	6145                	addi	sp,sp,48
    800026a2:	8082                	ret
        p->state = RUNNABLE;
    800026a4:	4789                	li	a5,2
    800026a6:	cc9c                	sw	a5,24(s1)
    800026a8:	b7cd                	j	8000268a <kill+0x52>

00000000800026aa <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026aa:	7179                	addi	sp,sp,-48
    800026ac:	f406                	sd	ra,40(sp)
    800026ae:	f022                	sd	s0,32(sp)
    800026b0:	ec26                	sd	s1,24(sp)
    800026b2:	e84a                	sd	s2,16(sp)
    800026b4:	e44e                	sd	s3,8(sp)
    800026b6:	e052                	sd	s4,0(sp)
    800026b8:	1800                	addi	s0,sp,48
    800026ba:	84aa                	mv	s1,a0
    800026bc:	892e                	mv	s2,a1
    800026be:	89b2                	mv	s3,a2
    800026c0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026c2:	fffff097          	auipc	ra,0xfffff
    800026c6:	576080e7          	jalr	1398(ra) # 80001c38 <myproc>
  if(user_dst){
    800026ca:	c08d                	beqz	s1,800026ec <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026cc:	86d2                	mv	a3,s4
    800026ce:	864e                	mv	a2,s3
    800026d0:	85ca                	mv	a1,s2
    800026d2:	6928                	ld	a0,80(a0)
    800026d4:	fffff097          	auipc	ra,0xfffff
    800026d8:	14c080e7          	jalr	332(ra) # 80001820 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026dc:	70a2                	ld	ra,40(sp)
    800026de:	7402                	ld	s0,32(sp)
    800026e0:	64e2                	ld	s1,24(sp)
    800026e2:	6942                	ld	s2,16(sp)
    800026e4:	69a2                	ld	s3,8(sp)
    800026e6:	6a02                	ld	s4,0(sp)
    800026e8:	6145                	addi	sp,sp,48
    800026ea:	8082                	ret
    memmove((char *)dst, src, len);
    800026ec:	000a061b          	sext.w	a2,s4
    800026f0:	85ce                	mv	a1,s3
    800026f2:	854a                	mv	a0,s2
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	7ee080e7          	jalr	2030(ra) # 80000ee2 <memmove>
    return 0;
    800026fc:	8526                	mv	a0,s1
    800026fe:	bff9                	j	800026dc <either_copyout+0x32>

0000000080002700 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002700:	7179                	addi	sp,sp,-48
    80002702:	f406                	sd	ra,40(sp)
    80002704:	f022                	sd	s0,32(sp)
    80002706:	ec26                	sd	s1,24(sp)
    80002708:	e84a                	sd	s2,16(sp)
    8000270a:	e44e                	sd	s3,8(sp)
    8000270c:	e052                	sd	s4,0(sp)
    8000270e:	1800                	addi	s0,sp,48
    80002710:	892a                	mv	s2,a0
    80002712:	84ae                	mv	s1,a1
    80002714:	89b2                	mv	s3,a2
    80002716:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	520080e7          	jalr	1312(ra) # 80001c38 <myproc>
  if(user_src){
    80002720:	c08d                	beqz	s1,80002742 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002722:	86d2                	mv	a3,s4
    80002724:	864e                	mv	a2,s3
    80002726:	85ca                	mv	a1,s2
    80002728:	6928                	ld	a0,80(a0)
    8000272a:	fffff097          	auipc	ra,0xfffff
    8000272e:	28e080e7          	jalr	654(ra) # 800019b8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002732:	70a2                	ld	ra,40(sp)
    80002734:	7402                	ld	s0,32(sp)
    80002736:	64e2                	ld	s1,24(sp)
    80002738:	6942                	ld	s2,16(sp)
    8000273a:	69a2                	ld	s3,8(sp)
    8000273c:	6a02                	ld	s4,0(sp)
    8000273e:	6145                	addi	sp,sp,48
    80002740:	8082                	ret
    memmove(dst, (char*)src, len);
    80002742:	000a061b          	sext.w	a2,s4
    80002746:	85ce                	mv	a1,s3
    80002748:	854a                	mv	a0,s2
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	798080e7          	jalr	1944(ra) # 80000ee2 <memmove>
    return 0;
    80002752:	8526                	mv	a0,s1
    80002754:	bff9                	j	80002732 <either_copyin+0x32>

0000000080002756 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002756:	715d                	addi	sp,sp,-80
    80002758:	e486                	sd	ra,72(sp)
    8000275a:	e0a2                	sd	s0,64(sp)
    8000275c:	fc26                	sd	s1,56(sp)
    8000275e:	f84a                	sd	s2,48(sp)
    80002760:	f44e                	sd	s3,40(sp)
    80002762:	f052                	sd	s4,32(sp)
    80002764:	ec56                	sd	s5,24(sp)
    80002766:	e85a                	sd	s6,16(sp)
    80002768:	e45e                	sd	s7,8(sp)
    8000276a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000276c:	00006517          	auipc	a0,0x6
    80002770:	be450513          	addi	a0,a0,-1052 # 80008350 <states.1710+0x88>
    80002774:	ffffe097          	auipc	ra,0xffffe
    80002778:	e1e080e7          	jalr	-482(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000277c:	0000f497          	auipc	s1,0xf
    80002780:	76448493          	addi	s1,s1,1892 # 80011ee0 <proc+0x158>
    80002784:	00015917          	auipc	s2,0x15
    80002788:	15c90913          	addi	s2,s2,348 # 800178e0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000278c:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000278e:	00006997          	auipc	s3,0x6
    80002792:	afa98993          	addi	s3,s3,-1286 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    80002796:	00006a97          	auipc	s5,0x6
    8000279a:	afaa8a93          	addi	s5,s5,-1286 # 80008290 <digits+0x250>
    printf("\n");
    8000279e:	00006a17          	auipc	s4,0x6
    800027a2:	bb2a0a13          	addi	s4,s4,-1102 # 80008350 <states.1710+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027a6:	00006b97          	auipc	s7,0x6
    800027aa:	b22b8b93          	addi	s7,s7,-1246 # 800082c8 <states.1710>
    800027ae:	a00d                	j	800027d0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027b0:	ee06a583          	lw	a1,-288(a3)
    800027b4:	8556                	mv	a0,s5
    800027b6:	ffffe097          	auipc	ra,0xffffe
    800027ba:	ddc080e7          	jalr	-548(ra) # 80000592 <printf>
    printf("\n");
    800027be:	8552                	mv	a0,s4
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	dd2080e7          	jalr	-558(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027c8:	16848493          	addi	s1,s1,360
    800027cc:	03248163          	beq	s1,s2,800027ee <procdump+0x98>
    if(p->state == UNUSED)
    800027d0:	86a6                	mv	a3,s1
    800027d2:	ec04a783          	lw	a5,-320(s1)
    800027d6:	dbed                	beqz	a5,800027c8 <procdump+0x72>
      state = "???";
    800027d8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027da:	fcfb6be3          	bltu	s6,a5,800027b0 <procdump+0x5a>
    800027de:	1782                	slli	a5,a5,0x20
    800027e0:	9381                	srli	a5,a5,0x20
    800027e2:	078e                	slli	a5,a5,0x3
    800027e4:	97de                	add	a5,a5,s7
    800027e6:	6390                	ld	a2,0(a5)
    800027e8:	f661                	bnez	a2,800027b0 <procdump+0x5a>
      state = "???";
    800027ea:	864e                	mv	a2,s3
    800027ec:	b7d1                	j	800027b0 <procdump+0x5a>
  }
}
    800027ee:	60a6                	ld	ra,72(sp)
    800027f0:	6406                	ld	s0,64(sp)
    800027f2:	74e2                	ld	s1,56(sp)
    800027f4:	7942                	ld	s2,48(sp)
    800027f6:	79a2                	ld	s3,40(sp)
    800027f8:	7a02                	ld	s4,32(sp)
    800027fa:	6ae2                	ld	s5,24(sp)
    800027fc:	6b42                	ld	s6,16(sp)
    800027fe:	6ba2                	ld	s7,8(sp)
    80002800:	6161                	addi	sp,sp,80
    80002802:	8082                	ret

0000000080002804 <swtch>:
    80002804:	00153023          	sd	ra,0(a0)
    80002808:	00253423          	sd	sp,8(a0)
    8000280c:	e900                	sd	s0,16(a0)
    8000280e:	ed04                	sd	s1,24(a0)
    80002810:	03253023          	sd	s2,32(a0)
    80002814:	03353423          	sd	s3,40(a0)
    80002818:	03453823          	sd	s4,48(a0)
    8000281c:	03553c23          	sd	s5,56(a0)
    80002820:	05653023          	sd	s6,64(a0)
    80002824:	05753423          	sd	s7,72(a0)
    80002828:	05853823          	sd	s8,80(a0)
    8000282c:	05953c23          	sd	s9,88(a0)
    80002830:	07a53023          	sd	s10,96(a0)
    80002834:	07b53423          	sd	s11,104(a0)
    80002838:	0005b083          	ld	ra,0(a1)
    8000283c:	0085b103          	ld	sp,8(a1)
    80002840:	6980                	ld	s0,16(a1)
    80002842:	6d84                	ld	s1,24(a1)
    80002844:	0205b903          	ld	s2,32(a1)
    80002848:	0285b983          	ld	s3,40(a1)
    8000284c:	0305ba03          	ld	s4,48(a1)
    80002850:	0385ba83          	ld	s5,56(a1)
    80002854:	0405bb03          	ld	s6,64(a1)
    80002858:	0485bb83          	ld	s7,72(a1)
    8000285c:	0505bc03          	ld	s8,80(a1)
    80002860:	0585bc83          	ld	s9,88(a1)
    80002864:	0605bd03          	ld	s10,96(a1)
    80002868:	0685bd83          	ld	s11,104(a1)
    8000286c:	8082                	ret

000000008000286e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000286e:	1141                	addi	sp,sp,-16
    80002870:	e406                	sd	ra,8(sp)
    80002872:	e022                	sd	s0,0(sp)
    80002874:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002876:	00006597          	auipc	a1,0x6
    8000287a:	a7a58593          	addi	a1,a1,-1414 # 800082f0 <states.1710+0x28>
    8000287e:	00015517          	auipc	a0,0x15
    80002882:	f0a50513          	addi	a0,a0,-246 # 80017788 <tickslock>
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	470080e7          	jalr	1136(ra) # 80000cf6 <initlock>
}
    8000288e:	60a2                	ld	ra,8(sp)
    80002890:	6402                	ld	s0,0(sp)
    80002892:	0141                	addi	sp,sp,16
    80002894:	8082                	ret

0000000080002896 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002896:	1141                	addi	sp,sp,-16
    80002898:	e422                	sd	s0,8(sp)
    8000289a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000289c:	00003797          	auipc	a5,0x3
    800028a0:	63478793          	addi	a5,a5,1588 # 80005ed0 <kernelvec>
    800028a4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028a8:	6422                	ld	s0,8(sp)
    800028aa:	0141                	addi	sp,sp,16
    800028ac:	8082                	ret

00000000800028ae <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028ae:	1141                	addi	sp,sp,-16
    800028b0:	e406                	sd	ra,8(sp)
    800028b2:	e022                	sd	s0,0(sp)
    800028b4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028b6:	fffff097          	auipc	ra,0xfffff
    800028ba:	382080e7          	jalr	898(ra) # 80001c38 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028be:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028c2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028c4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028c8:	00004617          	auipc	a2,0x4
    800028cc:	73860613          	addi	a2,a2,1848 # 80007000 <_trampoline>
    800028d0:	00004697          	auipc	a3,0x4
    800028d4:	73068693          	addi	a3,a3,1840 # 80007000 <_trampoline>
    800028d8:	8e91                	sub	a3,a3,a2
    800028da:	040007b7          	lui	a5,0x4000
    800028de:	17fd                	addi	a5,a5,-1
    800028e0:	07b2                	slli	a5,a5,0xc
    800028e2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028e4:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028e8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028ea:	180026f3          	csrr	a3,satp
    800028ee:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028f0:	6d38                	ld	a4,88(a0)
    800028f2:	6134                	ld	a3,64(a0)
    800028f4:	6585                	lui	a1,0x1
    800028f6:	96ae                	add	a3,a3,a1
    800028f8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028fa:	6d38                	ld	a4,88(a0)
    800028fc:	00000697          	auipc	a3,0x0
    80002900:	13868693          	addi	a3,a3,312 # 80002a34 <usertrap>
    80002904:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002906:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002908:	8692                	mv	a3,tp
    8000290a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000290c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002910:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002914:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002918:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000291c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000291e:	6f18                	ld	a4,24(a4)
    80002920:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002924:	692c                	ld	a1,80(a0)
    80002926:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002928:	00004717          	auipc	a4,0x4
    8000292c:	76870713          	addi	a4,a4,1896 # 80007090 <userret>
    80002930:	8f11                	sub	a4,a4,a2
    80002932:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002934:	577d                	li	a4,-1
    80002936:	177e                	slli	a4,a4,0x3f
    80002938:	8dd9                	or	a1,a1,a4
    8000293a:	02000537          	lui	a0,0x2000
    8000293e:	157d                	addi	a0,a0,-1
    80002940:	0536                	slli	a0,a0,0xd
    80002942:	9782                	jalr	a5
}
    80002944:	60a2                	ld	ra,8(sp)
    80002946:	6402                	ld	s0,0(sp)
    80002948:	0141                	addi	sp,sp,16
    8000294a:	8082                	ret

000000008000294c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000294c:	1101                	addi	sp,sp,-32
    8000294e:	ec06                	sd	ra,24(sp)
    80002950:	e822                	sd	s0,16(sp)
    80002952:	e426                	sd	s1,8(sp)
    80002954:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002956:	00015497          	auipc	s1,0x15
    8000295a:	e3248493          	addi	s1,s1,-462 # 80017788 <tickslock>
    8000295e:	8526                	mv	a0,s1
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	426080e7          	jalr	1062(ra) # 80000d86 <acquire>
  ticks++;
    80002968:	00006517          	auipc	a0,0x6
    8000296c:	6b850513          	addi	a0,a0,1720 # 80009020 <ticks>
    80002970:	411c                	lw	a5,0(a0)
    80002972:	2785                	addiw	a5,a5,1
    80002974:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002976:	00000097          	auipc	ra,0x0
    8000297a:	c58080e7          	jalr	-936(ra) # 800025ce <wakeup>
  release(&tickslock);
    8000297e:	8526                	mv	a0,s1
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	4ba080e7          	jalr	1210(ra) # 80000e3a <release>
}
    80002988:	60e2                	ld	ra,24(sp)
    8000298a:	6442                	ld	s0,16(sp)
    8000298c:	64a2                	ld	s1,8(sp)
    8000298e:	6105                	addi	sp,sp,32
    80002990:	8082                	ret

0000000080002992 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002992:	1101                	addi	sp,sp,-32
    80002994:	ec06                	sd	ra,24(sp)
    80002996:	e822                	sd	s0,16(sp)
    80002998:	e426                	sd	s1,8(sp)
    8000299a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000299c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029a0:	00074d63          	bltz	a4,800029ba <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029a4:	57fd                	li	a5,-1
    800029a6:	17fe                	slli	a5,a5,0x3f
    800029a8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029aa:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029ac:	06f70363          	beq	a4,a5,80002a12 <devintr+0x80>
  }
}
    800029b0:	60e2                	ld	ra,24(sp)
    800029b2:	6442                	ld	s0,16(sp)
    800029b4:	64a2                	ld	s1,8(sp)
    800029b6:	6105                	addi	sp,sp,32
    800029b8:	8082                	ret
     (scause & 0xff) == 9){
    800029ba:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029be:	46a5                	li	a3,9
    800029c0:	fed792e3          	bne	a5,a3,800029a4 <devintr+0x12>
    int irq = plic_claim();
    800029c4:	00003097          	auipc	ra,0x3
    800029c8:	614080e7          	jalr	1556(ra) # 80005fd8 <plic_claim>
    800029cc:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029ce:	47a9                	li	a5,10
    800029d0:	02f50763          	beq	a0,a5,800029fe <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029d4:	4785                	li	a5,1
    800029d6:	02f50963          	beq	a0,a5,80002a08 <devintr+0x76>
    return 1;
    800029da:	4505                	li	a0,1
    } else if(irq){
    800029dc:	d8f1                	beqz	s1,800029b0 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029de:	85a6                	mv	a1,s1
    800029e0:	00006517          	auipc	a0,0x6
    800029e4:	91850513          	addi	a0,a0,-1768 # 800082f8 <states.1710+0x30>
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	baa080e7          	jalr	-1110(ra) # 80000592 <printf>
      plic_complete(irq);
    800029f0:	8526                	mv	a0,s1
    800029f2:	00003097          	auipc	ra,0x3
    800029f6:	60a080e7          	jalr	1546(ra) # 80005ffc <plic_complete>
    return 1;
    800029fa:	4505                	li	a0,1
    800029fc:	bf55                	j	800029b0 <devintr+0x1e>
      uartintr();
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	fd6080e7          	jalr	-42(ra) # 800009d4 <uartintr>
    80002a06:	b7ed                	j	800029f0 <devintr+0x5e>
      virtio_disk_intr();
    80002a08:	00004097          	auipc	ra,0x4
    80002a0c:	a8e080e7          	jalr	-1394(ra) # 80006496 <virtio_disk_intr>
    80002a10:	b7c5                	j	800029f0 <devintr+0x5e>
    if(cpuid() == 0){
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	1fa080e7          	jalr	506(ra) # 80001c0c <cpuid>
    80002a1a:	c901                	beqz	a0,80002a2a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a1c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a20:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a22:	14479073          	csrw	sip,a5
    return 2;
    80002a26:	4509                	li	a0,2
    80002a28:	b761                	j	800029b0 <devintr+0x1e>
      clockintr();
    80002a2a:	00000097          	auipc	ra,0x0
    80002a2e:	f22080e7          	jalr	-222(ra) # 8000294c <clockintr>
    80002a32:	b7ed                	j	80002a1c <devintr+0x8a>

0000000080002a34 <usertrap>:
{
    80002a34:	7139                	addi	sp,sp,-64
    80002a36:	fc06                	sd	ra,56(sp)
    80002a38:	f822                	sd	s0,48(sp)
    80002a3a:	f426                	sd	s1,40(sp)
    80002a3c:	f04a                	sd	s2,32(sp)
    80002a3e:	ec4e                	sd	s3,24(sp)
    80002a40:	e852                	sd	s4,16(sp)
    80002a42:	e456                	sd	s5,8(sp)
    80002a44:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a46:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002a4a:	1007f793          	andi	a5,a5,256
    80002a4e:	e3d1                	bnez	a5,80002ad2 <usertrap+0x9e>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a50:	00003797          	auipc	a5,0x3
    80002a54:	48078793          	addi	a5,a5,1152 # 80005ed0 <kernelvec>
    80002a58:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a5c:	fffff097          	auipc	ra,0xfffff
    80002a60:	1dc080e7          	jalr	476(ra) # 80001c38 <myproc>
    80002a64:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a66:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a68:	14102773          	csrr	a4,sepc
    80002a6c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a6e:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002a72:	47a1                	li	a5,8
    80002a74:	06f70763          	beq	a4,a5,80002ae2 <usertrap+0xae>
    80002a78:	14202773          	csrr	a4,scause
  else if (r_scause() == 15)
    80002a7c:	47bd                	li	a5,15
    80002a7e:	1af71963          	bne	a4,a5,80002c30 <usertrap+0x1fc>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a82:	14302973          	csrr	s2,stval
    uint64 va = PGROUNDDOWN(r_stval());
    80002a86:	77fd                	lui	a5,0xfffff
    80002a88:	00f97933          	and	s2,s2,a5
    if (va >= MAXVA)
    80002a8c:	57fd                	li	a5,-1
    80002a8e:	83e9                	srli	a5,a5,0x1a
    80002a90:	0927ef63          	bltu	a5,s2,80002b2e <usertrap+0xfa>
    if (va > p->sz)
    80002a94:	653c                	ld	a5,72(a0)
    80002a96:	0b27e763          	bltu	a5,s2,80002b44 <usertrap+0x110>
    if ((pte = walk(p->pagetable, va, 0)) == 0)
    80002a9a:	4601                	li	a2,0
    80002a9c:	85ca                	mv	a1,s2
    80002a9e:	6928                	ld	a0,80(a0)
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	6ce080e7          	jalr	1742(ra) # 8000116e <walk>
    80002aa8:	89aa                	mv	s3,a0
    80002aaa:	c945                	beqz	a0,80002b5a <usertrap+0x126>
    if (((*pte) & PTE_COW) == 0 || ((*pte) & PTE_V) == 0 || ((*pte) & PTE_U) == 0)
    80002aac:	00053a03          	ld	s4,0(a0)
    80002ab0:	111a7713          	andi	a4,s4,273
    80002ab4:	11100793          	li	a5,273
    80002ab8:	0af70c63          	beq	a4,a5,80002b70 <usertrap+0x13c>
      printf("usertrap: pte not exist or it's not cow page\n");
    80002abc:	00006517          	auipc	a0,0x6
    80002ac0:	8d450513          	addi	a0,a0,-1836 # 80008390 <states.1710+0xc8>
    80002ac4:	ffffe097          	auipc	ra,0xffffe
    80002ac8:	ace080e7          	jalr	-1330(ra) # 80000592 <printf>
      p->killed = 1;
    80002acc:	4785                	li	a5,1
    80002ace:	d89c                	sw	a5,48(s1)
      goto end;
    80002ad0:	a255                	j	80002c74 <usertrap+0x240>
    panic("usertrap: not from user mode");
    80002ad2:	00006517          	auipc	a0,0x6
    80002ad6:	84650513          	addi	a0,a0,-1978 # 80008318 <states.1710+0x50>
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	a6e080e7          	jalr	-1426(ra) # 80000548 <panic>
    if (p->killed)
    80002ae2:	591c                	lw	a5,48(a0)
    80002ae4:	ef9d                	bnez	a5,80002b22 <usertrap+0xee>
    p->trapframe->epc += 4;
    80002ae6:	6cb8                	ld	a4,88(s1)
    80002ae8:	6f1c                	ld	a5,24(a4)
    80002aea:	0791                	addi	a5,a5,4
    80002aec:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002af2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002af6:	10079073          	csrw	sstatus,a5
    syscall();
    80002afa:	00000097          	auipc	ra,0x0
    80002afe:	3dc080e7          	jalr	988(ra) # 80002ed6 <syscall>
  if (p->killed)
    80002b02:	589c                	lw	a5,48(s1)
    80002b04:	18079663          	bnez	a5,80002c90 <usertrap+0x25c>
  usertrapret();
    80002b08:	00000097          	auipc	ra,0x0
    80002b0c:	da6080e7          	jalr	-602(ra) # 800028ae <usertrapret>
}
    80002b10:	70e2                	ld	ra,56(sp)
    80002b12:	7442                	ld	s0,48(sp)
    80002b14:	74a2                	ld	s1,40(sp)
    80002b16:	7902                	ld	s2,32(sp)
    80002b18:	69e2                	ld	s3,24(sp)
    80002b1a:	6a42                	ld	s4,16(sp)
    80002b1c:	6aa2                	ld	s5,8(sp)
    80002b1e:	6121                	addi	sp,sp,64
    80002b20:	8082                	ret
      exit(-1);
    80002b22:	557d                	li	a0,-1
    80002b24:	fffff097          	auipc	ra,0xfffff
    80002b28:	7de080e7          	jalr	2014(ra) # 80002302 <exit>
    80002b2c:	bf6d                	j	80002ae6 <usertrap+0xb2>
      printf("va is larger than MAXVA!\n");
    80002b2e:	00006517          	auipc	a0,0x6
    80002b32:	80a50513          	addi	a0,a0,-2038 # 80008338 <states.1710+0x70>
    80002b36:	ffffe097          	auipc	ra,0xffffe
    80002b3a:	a5c080e7          	jalr	-1444(ra) # 80000592 <printf>
      p->killed = 1;
    80002b3e:	4785                	li	a5,1
    80002b40:	d89c                	sw	a5,48(s1)
      goto end;
    80002b42:	aa0d                	j	80002c74 <usertrap+0x240>
      printf("va is larger than sz!\n");
    80002b44:	00006517          	auipc	a0,0x6
    80002b48:	81450513          	addi	a0,a0,-2028 # 80008358 <states.1710+0x90>
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	a46080e7          	jalr	-1466(ra) # 80000592 <printf>
      p->killed = 1;
    80002b54:	4785                	li	a5,1
    80002b56:	d89c                	sw	a5,48(s1)
      goto end;
    80002b58:	aa31                	j	80002c74 <usertrap+0x240>
      printf("usertrap(): page not found\n");
    80002b5a:	00006517          	auipc	a0,0x6
    80002b5e:	81650513          	addi	a0,a0,-2026 # 80008370 <states.1710+0xa8>
    80002b62:	ffffe097          	auipc	ra,0xffffe
    80002b66:	a30080e7          	jalr	-1488(ra) # 80000592 <printf>
      p->killed = 1;
    80002b6a:	4785                	li	a5,1
    80002b6c:	d89c                	sw	a5,48(s1)
      goto end;
    80002b6e:	a219                	j	80002c74 <usertrap+0x240>
    acquire_refcnt();
    80002b70:	ffffe097          	auipc	ra,0xffffe
    80002b74:	146080e7          	jalr	326(ra) # 80000cb6 <acquire_refcnt>
    uint64 pa = PTE2PA(*pte);
    80002b78:	00aa5a13          	srli	s4,s4,0xa
    80002b7c:	0a32                	slli	s4,s4,0xc
    uint ref = kgetref((void *)pa);
    80002b7e:	8552                	mv	a0,s4
    80002b80:	ffffe097          	auipc	ra,0xffffe
    80002b84:	0d6080e7          	jalr	214(ra) # 80000c56 <kgetref>
    if (ref == 1)
    80002b88:	4785                	li	a5,1
    80002b8a:	00f51f63          	bne	a0,a5,80002ba8 <usertrap+0x174>
      *pte = ((*pte) & (~PTE_COW)) | PTE_W;
    80002b8e:	0009b783          	ld	a5,0(s3)
    80002b92:	efb7f793          	andi	a5,a5,-261
    80002b96:	0047e793          	ori	a5,a5,4
    80002b9a:	00f9b023          	sd	a5,0(s3)
    release_refcnt();
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	138080e7          	jalr	312(ra) # 80000cd6 <release_refcnt>
    80002ba6:	bfb1                	j	80002b02 <usertrap+0xce>
      char *mem = kalloc();
    80002ba8:	ffffe097          	auipc	ra,0xffffe
    80002bac:	030080e7          	jalr	48(ra) # 80000bd8 <kalloc>
    80002bb0:	8aaa                	mv	s5,a0
      if (mem == 0)
    80002bb2:	cd05                	beqz	a0,80002bea <usertrap+0x1b6>
      memmove(mem, (char *)pa, PGSIZE);
    80002bb4:	6605                	lui	a2,0x1
    80002bb6:	85d2                	mv	a1,s4
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	32a080e7          	jalr	810(ra) # 80000ee2 <memmove>
      uint flag = (PTE_FLAGS(*pte) | PTE_W) & (~PTE_COW);
    80002bc0:	0009b703          	ld	a4,0(s3)
    80002bc4:	2fb77713          	andi	a4,a4,763
      if (mappages(p->pagetable, va, PGSIZE, (uint64)mem, flag) != 0)
    80002bc8:	00476713          	ori	a4,a4,4
    80002bcc:	86d6                	mv	a3,s5
    80002bce:	6605                	lui	a2,0x1
    80002bd0:	85ca                	mv	a1,s2
    80002bd2:	68a8                	ld	a0,80(s1)
    80002bd4:	ffffe097          	auipc	ra,0xffffe
    80002bd8:	6e0080e7          	jalr	1760(ra) # 800012b4 <mappages>
    80002bdc:	e515                	bnez	a0,80002c08 <usertrap+0x1d4>
      kfree((void *)pa); // 旧页引用次数减1
    80002bde:	8552                	mv	a0,s4
    80002be0:	ffffe097          	auipc	ra,0xffffe
    80002be4:	e44080e7          	jalr	-444(ra) # 80000a24 <kfree>
    80002be8:	bf5d                	j	80002b9e <usertrap+0x16a>
        printf("usertrap(): memery alloc fault\n");
    80002bea:	00005517          	auipc	a0,0x5
    80002bee:	7d650513          	addi	a0,a0,2006 # 800083c0 <states.1710+0xf8>
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	9a0080e7          	jalr	-1632(ra) # 80000592 <printf>
        p->killed = 1;
    80002bfa:	4785                	li	a5,1
    80002bfc:	d89c                	sw	a5,48(s1)
        release_refcnt();
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	0d8080e7          	jalr	216(ra) # 80000cd6 <release_refcnt>
        goto end;
    80002c06:	bdf5                	j	80002b02 <usertrap+0xce>
        kfree(mem);
    80002c08:	8556                	mv	a0,s5
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	e1a080e7          	jalr	-486(ra) # 80000a24 <kfree>
        printf("usertrap(): can not map page\n");
    80002c12:	00005517          	auipc	a0,0x5
    80002c16:	7ce50513          	addi	a0,a0,1998 # 800083e0 <states.1710+0x118>
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	978080e7          	jalr	-1672(ra) # 80000592 <printf>
        p->killed = 1;
    80002c22:	4785                	li	a5,1
    80002c24:	d89c                	sw	a5,48(s1)
        release_refcnt();
    80002c26:	ffffe097          	auipc	ra,0xffffe
    80002c2a:	0b0080e7          	jalr	176(ra) # 80000cd6 <release_refcnt>
        goto end;
    80002c2e:	bdd1                	j	80002b02 <usertrap+0xce>
  else if ((which_dev = devintr()) != 0)
    80002c30:	00000097          	auipc	ra,0x0
    80002c34:	d62080e7          	jalr	-670(ra) # 80002992 <devintr>
    80002c38:	892a                	mv	s2,a0
    80002c3a:	c501                	beqz	a0,80002c42 <usertrap+0x20e>
  if (p->killed)
    80002c3c:	589c                	lw	a5,48(s1)
    80002c3e:	c3a9                	beqz	a5,80002c80 <usertrap+0x24c>
    80002c40:	a81d                	j	80002c76 <usertrap+0x242>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c42:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c46:	5c90                	lw	a2,56(s1)
    80002c48:	00005517          	auipc	a0,0x5
    80002c4c:	7b850513          	addi	a0,a0,1976 # 80008400 <states.1710+0x138>
    80002c50:	ffffe097          	auipc	ra,0xffffe
    80002c54:	942080e7          	jalr	-1726(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c58:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c5c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c60:	00005517          	auipc	a0,0x5
    80002c64:	7d050513          	addi	a0,a0,2000 # 80008430 <states.1710+0x168>
    80002c68:	ffffe097          	auipc	ra,0xffffe
    80002c6c:	92a080e7          	jalr	-1750(ra) # 80000592 <printf>
    p->killed = 1;
    80002c70:	4785                	li	a5,1
    80002c72:	d89c                	sw	a5,48(s1)
{
    80002c74:	4901                	li	s2,0
    exit(-1);
    80002c76:	557d                	li	a0,-1
    80002c78:	fffff097          	auipc	ra,0xfffff
    80002c7c:	68a080e7          	jalr	1674(ra) # 80002302 <exit>
  if (which_dev == 2)
    80002c80:	4789                	li	a5,2
    80002c82:	e8f913e3          	bne	s2,a5,80002b08 <usertrap+0xd4>
    yield();
    80002c86:	fffff097          	auipc	ra,0xfffff
    80002c8a:	786080e7          	jalr	1926(ra) # 8000240c <yield>
    80002c8e:	bdad                	j	80002b08 <usertrap+0xd4>
  if (p->killed)
    80002c90:	4901                	li	s2,0
    80002c92:	b7d5                	j	80002c76 <usertrap+0x242>

0000000080002c94 <kerneltrap>:
{
    80002c94:	7179                	addi	sp,sp,-48
    80002c96:	f406                	sd	ra,40(sp)
    80002c98:	f022                	sd	s0,32(sp)
    80002c9a:	ec26                	sd	s1,24(sp)
    80002c9c:	e84a                	sd	s2,16(sp)
    80002c9e:	e44e                	sd	s3,8(sp)
    80002ca0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ca2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ca6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002caa:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002cae:	1004f793          	andi	a5,s1,256
    80002cb2:	cb85                	beqz	a5,80002ce2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cb4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002cb8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002cba:	ef85                	bnez	a5,80002cf2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002cbc:	00000097          	auipc	ra,0x0
    80002cc0:	cd6080e7          	jalr	-810(ra) # 80002992 <devintr>
    80002cc4:	cd1d                	beqz	a0,80002d02 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cc6:	4789                	li	a5,2
    80002cc8:	06f50a63          	beq	a0,a5,80002d3c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ccc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cd0:	10049073          	csrw	sstatus,s1
}
    80002cd4:	70a2                	ld	ra,40(sp)
    80002cd6:	7402                	ld	s0,32(sp)
    80002cd8:	64e2                	ld	s1,24(sp)
    80002cda:	6942                	ld	s2,16(sp)
    80002cdc:	69a2                	ld	s3,8(sp)
    80002cde:	6145                	addi	sp,sp,48
    80002ce0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ce2:	00005517          	auipc	a0,0x5
    80002ce6:	76e50513          	addi	a0,a0,1902 # 80008450 <states.1710+0x188>
    80002cea:	ffffe097          	auipc	ra,0xffffe
    80002cee:	85e080e7          	jalr	-1954(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002cf2:	00005517          	auipc	a0,0x5
    80002cf6:	78650513          	addi	a0,a0,1926 # 80008478 <states.1710+0x1b0>
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	84e080e7          	jalr	-1970(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002d02:	85ce                	mv	a1,s3
    80002d04:	00005517          	auipc	a0,0x5
    80002d08:	79450513          	addi	a0,a0,1940 # 80008498 <states.1710+0x1d0>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	886080e7          	jalr	-1914(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d14:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d18:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d1c:	00005517          	auipc	a0,0x5
    80002d20:	78c50513          	addi	a0,a0,1932 # 800084a8 <states.1710+0x1e0>
    80002d24:	ffffe097          	auipc	ra,0xffffe
    80002d28:	86e080e7          	jalr	-1938(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002d2c:	00005517          	auipc	a0,0x5
    80002d30:	79450513          	addi	a0,a0,1940 # 800084c0 <states.1710+0x1f8>
    80002d34:	ffffe097          	auipc	ra,0xffffe
    80002d38:	814080e7          	jalr	-2028(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	efc080e7          	jalr	-260(ra) # 80001c38 <myproc>
    80002d44:	d541                	beqz	a0,80002ccc <kerneltrap+0x38>
    80002d46:	fffff097          	auipc	ra,0xfffff
    80002d4a:	ef2080e7          	jalr	-270(ra) # 80001c38 <myproc>
    80002d4e:	4d18                	lw	a4,24(a0)
    80002d50:	478d                	li	a5,3
    80002d52:	f6f71de3          	bne	a4,a5,80002ccc <kerneltrap+0x38>
    yield();
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	6b6080e7          	jalr	1718(ra) # 8000240c <yield>
    80002d5e:	b7bd                	j	80002ccc <kerneltrap+0x38>

0000000080002d60 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d60:	1101                	addi	sp,sp,-32
    80002d62:	ec06                	sd	ra,24(sp)
    80002d64:	e822                	sd	s0,16(sp)
    80002d66:	e426                	sd	s1,8(sp)
    80002d68:	1000                	addi	s0,sp,32
    80002d6a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	ecc080e7          	jalr	-308(ra) # 80001c38 <myproc>
  switch (n) {
    80002d74:	4795                	li	a5,5
    80002d76:	0497e163          	bltu	a5,s1,80002db8 <argraw+0x58>
    80002d7a:	048a                	slli	s1,s1,0x2
    80002d7c:	00005717          	auipc	a4,0x5
    80002d80:	77c70713          	addi	a4,a4,1916 # 800084f8 <states.1710+0x230>
    80002d84:	94ba                	add	s1,s1,a4
    80002d86:	409c                	lw	a5,0(s1)
    80002d88:	97ba                	add	a5,a5,a4
    80002d8a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d8c:	6d3c                	ld	a5,88(a0)
    80002d8e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d90:	60e2                	ld	ra,24(sp)
    80002d92:	6442                	ld	s0,16(sp)
    80002d94:	64a2                	ld	s1,8(sp)
    80002d96:	6105                	addi	sp,sp,32
    80002d98:	8082                	ret
    return p->trapframe->a1;
    80002d9a:	6d3c                	ld	a5,88(a0)
    80002d9c:	7fa8                	ld	a0,120(a5)
    80002d9e:	bfcd                	j	80002d90 <argraw+0x30>
    return p->trapframe->a2;
    80002da0:	6d3c                	ld	a5,88(a0)
    80002da2:	63c8                	ld	a0,128(a5)
    80002da4:	b7f5                	j	80002d90 <argraw+0x30>
    return p->trapframe->a3;
    80002da6:	6d3c                	ld	a5,88(a0)
    80002da8:	67c8                	ld	a0,136(a5)
    80002daa:	b7dd                	j	80002d90 <argraw+0x30>
    return p->trapframe->a4;
    80002dac:	6d3c                	ld	a5,88(a0)
    80002dae:	6bc8                	ld	a0,144(a5)
    80002db0:	b7c5                	j	80002d90 <argraw+0x30>
    return p->trapframe->a5;
    80002db2:	6d3c                	ld	a5,88(a0)
    80002db4:	6fc8                	ld	a0,152(a5)
    80002db6:	bfe9                	j	80002d90 <argraw+0x30>
  panic("argraw");
    80002db8:	00005517          	auipc	a0,0x5
    80002dbc:	71850513          	addi	a0,a0,1816 # 800084d0 <states.1710+0x208>
    80002dc0:	ffffd097          	auipc	ra,0xffffd
    80002dc4:	788080e7          	jalr	1928(ra) # 80000548 <panic>

0000000080002dc8 <fetchaddr>:
{
    80002dc8:	1101                	addi	sp,sp,-32
    80002dca:	ec06                	sd	ra,24(sp)
    80002dcc:	e822                	sd	s0,16(sp)
    80002dce:	e426                	sd	s1,8(sp)
    80002dd0:	e04a                	sd	s2,0(sp)
    80002dd2:	1000                	addi	s0,sp,32
    80002dd4:	84aa                	mv	s1,a0
    80002dd6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	e60080e7          	jalr	-416(ra) # 80001c38 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002de0:	653c                	ld	a5,72(a0)
    80002de2:	02f4f863          	bgeu	s1,a5,80002e12 <fetchaddr+0x4a>
    80002de6:	00848713          	addi	a4,s1,8
    80002dea:	02e7e663          	bltu	a5,a4,80002e16 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002dee:	46a1                	li	a3,8
    80002df0:	8626                	mv	a2,s1
    80002df2:	85ca                	mv	a1,s2
    80002df4:	6928                	ld	a0,80(a0)
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	bc2080e7          	jalr	-1086(ra) # 800019b8 <copyin>
    80002dfe:	00a03533          	snez	a0,a0
    80002e02:	40a00533          	neg	a0,a0
}
    80002e06:	60e2                	ld	ra,24(sp)
    80002e08:	6442                	ld	s0,16(sp)
    80002e0a:	64a2                	ld	s1,8(sp)
    80002e0c:	6902                	ld	s2,0(sp)
    80002e0e:	6105                	addi	sp,sp,32
    80002e10:	8082                	ret
    return -1;
    80002e12:	557d                	li	a0,-1
    80002e14:	bfcd                	j	80002e06 <fetchaddr+0x3e>
    80002e16:	557d                	li	a0,-1
    80002e18:	b7fd                	j	80002e06 <fetchaddr+0x3e>

0000000080002e1a <fetchstr>:
{
    80002e1a:	7179                	addi	sp,sp,-48
    80002e1c:	f406                	sd	ra,40(sp)
    80002e1e:	f022                	sd	s0,32(sp)
    80002e20:	ec26                	sd	s1,24(sp)
    80002e22:	e84a                	sd	s2,16(sp)
    80002e24:	e44e                	sd	s3,8(sp)
    80002e26:	1800                	addi	s0,sp,48
    80002e28:	892a                	mv	s2,a0
    80002e2a:	84ae                	mv	s1,a1
    80002e2c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	e0a080e7          	jalr	-502(ra) # 80001c38 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e36:	86ce                	mv	a3,s3
    80002e38:	864a                	mv	a2,s2
    80002e3a:	85a6                	mv	a1,s1
    80002e3c:	6928                	ld	a0,80(a0)
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	c06080e7          	jalr	-1018(ra) # 80001a44 <copyinstr>
  if(err < 0)
    80002e46:	00054763          	bltz	a0,80002e54 <fetchstr+0x3a>
  return strlen(buf);
    80002e4a:	8526                	mv	a0,s1
    80002e4c:	ffffe097          	auipc	ra,0xffffe
    80002e50:	1be080e7          	jalr	446(ra) # 8000100a <strlen>
}
    80002e54:	70a2                	ld	ra,40(sp)
    80002e56:	7402                	ld	s0,32(sp)
    80002e58:	64e2                	ld	s1,24(sp)
    80002e5a:	6942                	ld	s2,16(sp)
    80002e5c:	69a2                	ld	s3,8(sp)
    80002e5e:	6145                	addi	sp,sp,48
    80002e60:	8082                	ret

0000000080002e62 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e62:	1101                	addi	sp,sp,-32
    80002e64:	ec06                	sd	ra,24(sp)
    80002e66:	e822                	sd	s0,16(sp)
    80002e68:	e426                	sd	s1,8(sp)
    80002e6a:	1000                	addi	s0,sp,32
    80002e6c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e6e:	00000097          	auipc	ra,0x0
    80002e72:	ef2080e7          	jalr	-270(ra) # 80002d60 <argraw>
    80002e76:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e78:	4501                	li	a0,0
    80002e7a:	60e2                	ld	ra,24(sp)
    80002e7c:	6442                	ld	s0,16(sp)
    80002e7e:	64a2                	ld	s1,8(sp)
    80002e80:	6105                	addi	sp,sp,32
    80002e82:	8082                	ret

0000000080002e84 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e84:	1101                	addi	sp,sp,-32
    80002e86:	ec06                	sd	ra,24(sp)
    80002e88:	e822                	sd	s0,16(sp)
    80002e8a:	e426                	sd	s1,8(sp)
    80002e8c:	1000                	addi	s0,sp,32
    80002e8e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e90:	00000097          	auipc	ra,0x0
    80002e94:	ed0080e7          	jalr	-304(ra) # 80002d60 <argraw>
    80002e98:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e9a:	4501                	li	a0,0
    80002e9c:	60e2                	ld	ra,24(sp)
    80002e9e:	6442                	ld	s0,16(sp)
    80002ea0:	64a2                	ld	s1,8(sp)
    80002ea2:	6105                	addi	sp,sp,32
    80002ea4:	8082                	ret

0000000080002ea6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ea6:	1101                	addi	sp,sp,-32
    80002ea8:	ec06                	sd	ra,24(sp)
    80002eaa:	e822                	sd	s0,16(sp)
    80002eac:	e426                	sd	s1,8(sp)
    80002eae:	e04a                	sd	s2,0(sp)
    80002eb0:	1000                	addi	s0,sp,32
    80002eb2:	84ae                	mv	s1,a1
    80002eb4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002eb6:	00000097          	auipc	ra,0x0
    80002eba:	eaa080e7          	jalr	-342(ra) # 80002d60 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ebe:	864a                	mv	a2,s2
    80002ec0:	85a6                	mv	a1,s1
    80002ec2:	00000097          	auipc	ra,0x0
    80002ec6:	f58080e7          	jalr	-168(ra) # 80002e1a <fetchstr>
}
    80002eca:	60e2                	ld	ra,24(sp)
    80002ecc:	6442                	ld	s0,16(sp)
    80002ece:	64a2                	ld	s1,8(sp)
    80002ed0:	6902                	ld	s2,0(sp)
    80002ed2:	6105                	addi	sp,sp,32
    80002ed4:	8082                	ret

0000000080002ed6 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002ed6:	1101                	addi	sp,sp,-32
    80002ed8:	ec06                	sd	ra,24(sp)
    80002eda:	e822                	sd	s0,16(sp)
    80002edc:	e426                	sd	s1,8(sp)
    80002ede:	e04a                	sd	s2,0(sp)
    80002ee0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ee2:	fffff097          	auipc	ra,0xfffff
    80002ee6:	d56080e7          	jalr	-682(ra) # 80001c38 <myproc>
    80002eea:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002eec:	05853903          	ld	s2,88(a0)
    80002ef0:	0a893783          	ld	a5,168(s2)
    80002ef4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ef8:	37fd                	addiw	a5,a5,-1
    80002efa:	4751                	li	a4,20
    80002efc:	00f76f63          	bltu	a4,a5,80002f1a <syscall+0x44>
    80002f00:	00369713          	slli	a4,a3,0x3
    80002f04:	00005797          	auipc	a5,0x5
    80002f08:	60c78793          	addi	a5,a5,1548 # 80008510 <syscalls>
    80002f0c:	97ba                	add	a5,a5,a4
    80002f0e:	639c                	ld	a5,0(a5)
    80002f10:	c789                	beqz	a5,80002f1a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002f12:	9782                	jalr	a5
    80002f14:	06a93823          	sd	a0,112(s2)
    80002f18:	a839                	j	80002f36 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f1a:	15848613          	addi	a2,s1,344
    80002f1e:	5c8c                	lw	a1,56(s1)
    80002f20:	00005517          	auipc	a0,0x5
    80002f24:	5b850513          	addi	a0,a0,1464 # 800084d8 <states.1710+0x210>
    80002f28:	ffffd097          	auipc	ra,0xffffd
    80002f2c:	66a080e7          	jalr	1642(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f30:	6cbc                	ld	a5,88(s1)
    80002f32:	577d                	li	a4,-1
    80002f34:	fbb8                	sd	a4,112(a5)
  }
}
    80002f36:	60e2                	ld	ra,24(sp)
    80002f38:	6442                	ld	s0,16(sp)
    80002f3a:	64a2                	ld	s1,8(sp)
    80002f3c:	6902                	ld	s2,0(sp)
    80002f3e:	6105                	addi	sp,sp,32
    80002f40:	8082                	ret

0000000080002f42 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f42:	1101                	addi	sp,sp,-32
    80002f44:	ec06                	sd	ra,24(sp)
    80002f46:	e822                	sd	s0,16(sp)
    80002f48:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f4a:	fec40593          	addi	a1,s0,-20
    80002f4e:	4501                	li	a0,0
    80002f50:	00000097          	auipc	ra,0x0
    80002f54:	f12080e7          	jalr	-238(ra) # 80002e62 <argint>
    return -1;
    80002f58:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f5a:	00054963          	bltz	a0,80002f6c <sys_exit+0x2a>
  exit(n);
    80002f5e:	fec42503          	lw	a0,-20(s0)
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	3a0080e7          	jalr	928(ra) # 80002302 <exit>
  return 0;  // not reached
    80002f6a:	4781                	li	a5,0
}
    80002f6c:	853e                	mv	a0,a5
    80002f6e:	60e2                	ld	ra,24(sp)
    80002f70:	6442                	ld	s0,16(sp)
    80002f72:	6105                	addi	sp,sp,32
    80002f74:	8082                	ret

0000000080002f76 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f76:	1141                	addi	sp,sp,-16
    80002f78:	e406                	sd	ra,8(sp)
    80002f7a:	e022                	sd	s0,0(sp)
    80002f7c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f7e:	fffff097          	auipc	ra,0xfffff
    80002f82:	cba080e7          	jalr	-838(ra) # 80001c38 <myproc>
}
    80002f86:	5d08                	lw	a0,56(a0)
    80002f88:	60a2                	ld	ra,8(sp)
    80002f8a:	6402                	ld	s0,0(sp)
    80002f8c:	0141                	addi	sp,sp,16
    80002f8e:	8082                	ret

0000000080002f90 <sys_fork>:

uint64
sys_fork(void)
{
    80002f90:	1141                	addi	sp,sp,-16
    80002f92:	e406                	sd	ra,8(sp)
    80002f94:	e022                	sd	s0,0(sp)
    80002f96:	0800                	addi	s0,sp,16
  return fork();
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	060080e7          	jalr	96(ra) # 80001ff8 <fork>
}
    80002fa0:	60a2                	ld	ra,8(sp)
    80002fa2:	6402                	ld	s0,0(sp)
    80002fa4:	0141                	addi	sp,sp,16
    80002fa6:	8082                	ret

0000000080002fa8 <sys_wait>:

uint64
sys_wait(void)
{
    80002fa8:	1101                	addi	sp,sp,-32
    80002faa:	ec06                	sd	ra,24(sp)
    80002fac:	e822                	sd	s0,16(sp)
    80002fae:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002fb0:	fe840593          	addi	a1,s0,-24
    80002fb4:	4501                	li	a0,0
    80002fb6:	00000097          	auipc	ra,0x0
    80002fba:	ece080e7          	jalr	-306(ra) # 80002e84 <argaddr>
    80002fbe:	87aa                	mv	a5,a0
    return -1;
    80002fc0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fc2:	0007c863          	bltz	a5,80002fd2 <sys_wait+0x2a>
  return wait(p);
    80002fc6:	fe843503          	ld	a0,-24(s0)
    80002fca:	fffff097          	auipc	ra,0xfffff
    80002fce:	4fc080e7          	jalr	1276(ra) # 800024c6 <wait>
}
    80002fd2:	60e2                	ld	ra,24(sp)
    80002fd4:	6442                	ld	s0,16(sp)
    80002fd6:	6105                	addi	sp,sp,32
    80002fd8:	8082                	ret

0000000080002fda <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002fda:	7179                	addi	sp,sp,-48
    80002fdc:	f406                	sd	ra,40(sp)
    80002fde:	f022                	sd	s0,32(sp)
    80002fe0:	ec26                	sd	s1,24(sp)
    80002fe2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002fe4:	fdc40593          	addi	a1,s0,-36
    80002fe8:	4501                	li	a0,0
    80002fea:	00000097          	auipc	ra,0x0
    80002fee:	e78080e7          	jalr	-392(ra) # 80002e62 <argint>
    80002ff2:	87aa                	mv	a5,a0
    return -1;
    80002ff4:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002ff6:	0207c063          	bltz	a5,80003016 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002ffa:	fffff097          	auipc	ra,0xfffff
    80002ffe:	c3e080e7          	jalr	-962(ra) # 80001c38 <myproc>
    80003002:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003004:	fdc42503          	lw	a0,-36(s0)
    80003008:	fffff097          	auipc	ra,0xfffff
    8000300c:	f7c080e7          	jalr	-132(ra) # 80001f84 <growproc>
    80003010:	00054863          	bltz	a0,80003020 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003014:	8526                	mv	a0,s1
}
    80003016:	70a2                	ld	ra,40(sp)
    80003018:	7402                	ld	s0,32(sp)
    8000301a:	64e2                	ld	s1,24(sp)
    8000301c:	6145                	addi	sp,sp,48
    8000301e:	8082                	ret
    return -1;
    80003020:	557d                	li	a0,-1
    80003022:	bfd5                	j	80003016 <sys_sbrk+0x3c>

0000000080003024 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003024:	7139                	addi	sp,sp,-64
    80003026:	fc06                	sd	ra,56(sp)
    80003028:	f822                	sd	s0,48(sp)
    8000302a:	f426                	sd	s1,40(sp)
    8000302c:	f04a                	sd	s2,32(sp)
    8000302e:	ec4e                	sd	s3,24(sp)
    80003030:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003032:	fcc40593          	addi	a1,s0,-52
    80003036:	4501                	li	a0,0
    80003038:	00000097          	auipc	ra,0x0
    8000303c:	e2a080e7          	jalr	-470(ra) # 80002e62 <argint>
    return -1;
    80003040:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003042:	06054563          	bltz	a0,800030ac <sys_sleep+0x88>
  acquire(&tickslock);
    80003046:	00014517          	auipc	a0,0x14
    8000304a:	74250513          	addi	a0,a0,1858 # 80017788 <tickslock>
    8000304e:	ffffe097          	auipc	ra,0xffffe
    80003052:	d38080e7          	jalr	-712(ra) # 80000d86 <acquire>
  ticks0 = ticks;
    80003056:	00006917          	auipc	s2,0x6
    8000305a:	fca92903          	lw	s2,-54(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    8000305e:	fcc42783          	lw	a5,-52(s0)
    80003062:	cf85                	beqz	a5,8000309a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003064:	00014997          	auipc	s3,0x14
    80003068:	72498993          	addi	s3,s3,1828 # 80017788 <tickslock>
    8000306c:	00006497          	auipc	s1,0x6
    80003070:	fb448493          	addi	s1,s1,-76 # 80009020 <ticks>
    if(myproc()->killed){
    80003074:	fffff097          	auipc	ra,0xfffff
    80003078:	bc4080e7          	jalr	-1084(ra) # 80001c38 <myproc>
    8000307c:	591c                	lw	a5,48(a0)
    8000307e:	ef9d                	bnez	a5,800030bc <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003080:	85ce                	mv	a1,s3
    80003082:	8526                	mv	a0,s1
    80003084:	fffff097          	auipc	ra,0xfffff
    80003088:	3c4080e7          	jalr	964(ra) # 80002448 <sleep>
  while(ticks - ticks0 < n){
    8000308c:	409c                	lw	a5,0(s1)
    8000308e:	412787bb          	subw	a5,a5,s2
    80003092:	fcc42703          	lw	a4,-52(s0)
    80003096:	fce7efe3          	bltu	a5,a4,80003074 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000309a:	00014517          	auipc	a0,0x14
    8000309e:	6ee50513          	addi	a0,a0,1774 # 80017788 <tickslock>
    800030a2:	ffffe097          	auipc	ra,0xffffe
    800030a6:	d98080e7          	jalr	-616(ra) # 80000e3a <release>
  return 0;
    800030aa:	4781                	li	a5,0
}
    800030ac:	853e                	mv	a0,a5
    800030ae:	70e2                	ld	ra,56(sp)
    800030b0:	7442                	ld	s0,48(sp)
    800030b2:	74a2                	ld	s1,40(sp)
    800030b4:	7902                	ld	s2,32(sp)
    800030b6:	69e2                	ld	s3,24(sp)
    800030b8:	6121                	addi	sp,sp,64
    800030ba:	8082                	ret
      release(&tickslock);
    800030bc:	00014517          	auipc	a0,0x14
    800030c0:	6cc50513          	addi	a0,a0,1740 # 80017788 <tickslock>
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	d76080e7          	jalr	-650(ra) # 80000e3a <release>
      return -1;
    800030cc:	57fd                	li	a5,-1
    800030ce:	bff9                	j	800030ac <sys_sleep+0x88>

00000000800030d0 <sys_kill>:

uint64
sys_kill(void)
{
    800030d0:	1101                	addi	sp,sp,-32
    800030d2:	ec06                	sd	ra,24(sp)
    800030d4:	e822                	sd	s0,16(sp)
    800030d6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030d8:	fec40593          	addi	a1,s0,-20
    800030dc:	4501                	li	a0,0
    800030de:	00000097          	auipc	ra,0x0
    800030e2:	d84080e7          	jalr	-636(ra) # 80002e62 <argint>
    800030e6:	87aa                	mv	a5,a0
    return -1;
    800030e8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030ea:	0007c863          	bltz	a5,800030fa <sys_kill+0x2a>
  return kill(pid);
    800030ee:	fec42503          	lw	a0,-20(s0)
    800030f2:	fffff097          	auipc	ra,0xfffff
    800030f6:	546080e7          	jalr	1350(ra) # 80002638 <kill>
}
    800030fa:	60e2                	ld	ra,24(sp)
    800030fc:	6442                	ld	s0,16(sp)
    800030fe:	6105                	addi	sp,sp,32
    80003100:	8082                	ret

0000000080003102 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003102:	1101                	addi	sp,sp,-32
    80003104:	ec06                	sd	ra,24(sp)
    80003106:	e822                	sd	s0,16(sp)
    80003108:	e426                	sd	s1,8(sp)
    8000310a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000310c:	00014517          	auipc	a0,0x14
    80003110:	67c50513          	addi	a0,a0,1660 # 80017788 <tickslock>
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	c72080e7          	jalr	-910(ra) # 80000d86 <acquire>
  xticks = ticks;
    8000311c:	00006497          	auipc	s1,0x6
    80003120:	f044a483          	lw	s1,-252(s1) # 80009020 <ticks>
  release(&tickslock);
    80003124:	00014517          	auipc	a0,0x14
    80003128:	66450513          	addi	a0,a0,1636 # 80017788 <tickslock>
    8000312c:	ffffe097          	auipc	ra,0xffffe
    80003130:	d0e080e7          	jalr	-754(ra) # 80000e3a <release>
  return xticks;
}
    80003134:	02049513          	slli	a0,s1,0x20
    80003138:	9101                	srli	a0,a0,0x20
    8000313a:	60e2                	ld	ra,24(sp)
    8000313c:	6442                	ld	s0,16(sp)
    8000313e:	64a2                	ld	s1,8(sp)
    80003140:	6105                	addi	sp,sp,32
    80003142:	8082                	ret

0000000080003144 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003144:	7179                	addi	sp,sp,-48
    80003146:	f406                	sd	ra,40(sp)
    80003148:	f022                	sd	s0,32(sp)
    8000314a:	ec26                	sd	s1,24(sp)
    8000314c:	e84a                	sd	s2,16(sp)
    8000314e:	e44e                	sd	s3,8(sp)
    80003150:	e052                	sd	s4,0(sp)
    80003152:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003154:	00005597          	auipc	a1,0x5
    80003158:	46c58593          	addi	a1,a1,1132 # 800085c0 <syscalls+0xb0>
    8000315c:	00014517          	auipc	a0,0x14
    80003160:	64450513          	addi	a0,a0,1604 # 800177a0 <bcache>
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	b92080e7          	jalr	-1134(ra) # 80000cf6 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000316c:	0001c797          	auipc	a5,0x1c
    80003170:	63478793          	addi	a5,a5,1588 # 8001f7a0 <bcache+0x8000>
    80003174:	0001d717          	auipc	a4,0x1d
    80003178:	89470713          	addi	a4,a4,-1900 # 8001fa08 <bcache+0x8268>
    8000317c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003180:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003184:	00014497          	auipc	s1,0x14
    80003188:	63448493          	addi	s1,s1,1588 # 800177b8 <bcache+0x18>
    b->next = bcache.head.next;
    8000318c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000318e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003190:	00005a17          	auipc	s4,0x5
    80003194:	438a0a13          	addi	s4,s4,1080 # 800085c8 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003198:	2b893783          	ld	a5,696(s2)
    8000319c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000319e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800031a2:	85d2                	mv	a1,s4
    800031a4:	01048513          	addi	a0,s1,16
    800031a8:	00001097          	auipc	ra,0x1
    800031ac:	4b0080e7          	jalr	1200(ra) # 80004658 <initsleeplock>
    bcache.head.next->prev = b;
    800031b0:	2b893783          	ld	a5,696(s2)
    800031b4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031b6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031ba:	45848493          	addi	s1,s1,1112
    800031be:	fd349de3          	bne	s1,s3,80003198 <binit+0x54>
  }
}
    800031c2:	70a2                	ld	ra,40(sp)
    800031c4:	7402                	ld	s0,32(sp)
    800031c6:	64e2                	ld	s1,24(sp)
    800031c8:	6942                	ld	s2,16(sp)
    800031ca:	69a2                	ld	s3,8(sp)
    800031cc:	6a02                	ld	s4,0(sp)
    800031ce:	6145                	addi	sp,sp,48
    800031d0:	8082                	ret

00000000800031d2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031d2:	7179                	addi	sp,sp,-48
    800031d4:	f406                	sd	ra,40(sp)
    800031d6:	f022                	sd	s0,32(sp)
    800031d8:	ec26                	sd	s1,24(sp)
    800031da:	e84a                	sd	s2,16(sp)
    800031dc:	e44e                	sd	s3,8(sp)
    800031de:	1800                	addi	s0,sp,48
    800031e0:	89aa                	mv	s3,a0
    800031e2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800031e4:	00014517          	auipc	a0,0x14
    800031e8:	5bc50513          	addi	a0,a0,1468 # 800177a0 <bcache>
    800031ec:	ffffe097          	auipc	ra,0xffffe
    800031f0:	b9a080e7          	jalr	-1126(ra) # 80000d86 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031f4:	0001d497          	auipc	s1,0x1d
    800031f8:	8644b483          	ld	s1,-1948(s1) # 8001fa58 <bcache+0x82b8>
    800031fc:	0001d797          	auipc	a5,0x1d
    80003200:	80c78793          	addi	a5,a5,-2036 # 8001fa08 <bcache+0x8268>
    80003204:	02f48f63          	beq	s1,a5,80003242 <bread+0x70>
    80003208:	873e                	mv	a4,a5
    8000320a:	a021                	j	80003212 <bread+0x40>
    8000320c:	68a4                	ld	s1,80(s1)
    8000320e:	02e48a63          	beq	s1,a4,80003242 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003212:	449c                	lw	a5,8(s1)
    80003214:	ff379ce3          	bne	a5,s3,8000320c <bread+0x3a>
    80003218:	44dc                	lw	a5,12(s1)
    8000321a:	ff2799e3          	bne	a5,s2,8000320c <bread+0x3a>
      b->refcnt++;
    8000321e:	40bc                	lw	a5,64(s1)
    80003220:	2785                	addiw	a5,a5,1
    80003222:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003224:	00014517          	auipc	a0,0x14
    80003228:	57c50513          	addi	a0,a0,1404 # 800177a0 <bcache>
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	c0e080e7          	jalr	-1010(ra) # 80000e3a <release>
      acquiresleep(&b->lock);
    80003234:	01048513          	addi	a0,s1,16
    80003238:	00001097          	auipc	ra,0x1
    8000323c:	45a080e7          	jalr	1114(ra) # 80004692 <acquiresleep>
      return b;
    80003240:	a8b9                	j	8000329e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003242:	0001d497          	auipc	s1,0x1d
    80003246:	80e4b483          	ld	s1,-2034(s1) # 8001fa50 <bcache+0x82b0>
    8000324a:	0001c797          	auipc	a5,0x1c
    8000324e:	7be78793          	addi	a5,a5,1982 # 8001fa08 <bcache+0x8268>
    80003252:	00f48863          	beq	s1,a5,80003262 <bread+0x90>
    80003256:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003258:	40bc                	lw	a5,64(s1)
    8000325a:	cf81                	beqz	a5,80003272 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000325c:	64a4                	ld	s1,72(s1)
    8000325e:	fee49de3          	bne	s1,a4,80003258 <bread+0x86>
  panic("bget: no buffers");
    80003262:	00005517          	auipc	a0,0x5
    80003266:	36e50513          	addi	a0,a0,878 # 800085d0 <syscalls+0xc0>
    8000326a:	ffffd097          	auipc	ra,0xffffd
    8000326e:	2de080e7          	jalr	734(ra) # 80000548 <panic>
      b->dev = dev;
    80003272:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003276:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000327a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000327e:	4785                	li	a5,1
    80003280:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003282:	00014517          	auipc	a0,0x14
    80003286:	51e50513          	addi	a0,a0,1310 # 800177a0 <bcache>
    8000328a:	ffffe097          	auipc	ra,0xffffe
    8000328e:	bb0080e7          	jalr	-1104(ra) # 80000e3a <release>
      acquiresleep(&b->lock);
    80003292:	01048513          	addi	a0,s1,16
    80003296:	00001097          	auipc	ra,0x1
    8000329a:	3fc080e7          	jalr	1020(ra) # 80004692 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000329e:	409c                	lw	a5,0(s1)
    800032a0:	cb89                	beqz	a5,800032b2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032a2:	8526                	mv	a0,s1
    800032a4:	70a2                	ld	ra,40(sp)
    800032a6:	7402                	ld	s0,32(sp)
    800032a8:	64e2                	ld	s1,24(sp)
    800032aa:	6942                	ld	s2,16(sp)
    800032ac:	69a2                	ld	s3,8(sp)
    800032ae:	6145                	addi	sp,sp,48
    800032b0:	8082                	ret
    virtio_disk_rw(b, 0);
    800032b2:	4581                	li	a1,0
    800032b4:	8526                	mv	a0,s1
    800032b6:	00003097          	auipc	ra,0x3
    800032ba:	f36080e7          	jalr	-202(ra) # 800061ec <virtio_disk_rw>
    b->valid = 1;
    800032be:	4785                	li	a5,1
    800032c0:	c09c                	sw	a5,0(s1)
  return b;
    800032c2:	b7c5                	j	800032a2 <bread+0xd0>

00000000800032c4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032c4:	1101                	addi	sp,sp,-32
    800032c6:	ec06                	sd	ra,24(sp)
    800032c8:	e822                	sd	s0,16(sp)
    800032ca:	e426                	sd	s1,8(sp)
    800032cc:	1000                	addi	s0,sp,32
    800032ce:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032d0:	0541                	addi	a0,a0,16
    800032d2:	00001097          	auipc	ra,0x1
    800032d6:	45a080e7          	jalr	1114(ra) # 8000472c <holdingsleep>
    800032da:	cd01                	beqz	a0,800032f2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032dc:	4585                	li	a1,1
    800032de:	8526                	mv	a0,s1
    800032e0:	00003097          	auipc	ra,0x3
    800032e4:	f0c080e7          	jalr	-244(ra) # 800061ec <virtio_disk_rw>
}
    800032e8:	60e2                	ld	ra,24(sp)
    800032ea:	6442                	ld	s0,16(sp)
    800032ec:	64a2                	ld	s1,8(sp)
    800032ee:	6105                	addi	sp,sp,32
    800032f0:	8082                	ret
    panic("bwrite");
    800032f2:	00005517          	auipc	a0,0x5
    800032f6:	2f650513          	addi	a0,a0,758 # 800085e8 <syscalls+0xd8>
    800032fa:	ffffd097          	auipc	ra,0xffffd
    800032fe:	24e080e7          	jalr	590(ra) # 80000548 <panic>

0000000080003302 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003302:	1101                	addi	sp,sp,-32
    80003304:	ec06                	sd	ra,24(sp)
    80003306:	e822                	sd	s0,16(sp)
    80003308:	e426                	sd	s1,8(sp)
    8000330a:	e04a                	sd	s2,0(sp)
    8000330c:	1000                	addi	s0,sp,32
    8000330e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003310:	01050913          	addi	s2,a0,16
    80003314:	854a                	mv	a0,s2
    80003316:	00001097          	auipc	ra,0x1
    8000331a:	416080e7          	jalr	1046(ra) # 8000472c <holdingsleep>
    8000331e:	c92d                	beqz	a0,80003390 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003320:	854a                	mv	a0,s2
    80003322:	00001097          	auipc	ra,0x1
    80003326:	3c6080e7          	jalr	966(ra) # 800046e8 <releasesleep>

  acquire(&bcache.lock);
    8000332a:	00014517          	auipc	a0,0x14
    8000332e:	47650513          	addi	a0,a0,1142 # 800177a0 <bcache>
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	a54080e7          	jalr	-1452(ra) # 80000d86 <acquire>
  b->refcnt--;
    8000333a:	40bc                	lw	a5,64(s1)
    8000333c:	37fd                	addiw	a5,a5,-1
    8000333e:	0007871b          	sext.w	a4,a5
    80003342:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003344:	eb05                	bnez	a4,80003374 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003346:	68bc                	ld	a5,80(s1)
    80003348:	64b8                	ld	a4,72(s1)
    8000334a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000334c:	64bc                	ld	a5,72(s1)
    8000334e:	68b8                	ld	a4,80(s1)
    80003350:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003352:	0001c797          	auipc	a5,0x1c
    80003356:	44e78793          	addi	a5,a5,1102 # 8001f7a0 <bcache+0x8000>
    8000335a:	2b87b703          	ld	a4,696(a5)
    8000335e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003360:	0001c717          	auipc	a4,0x1c
    80003364:	6a870713          	addi	a4,a4,1704 # 8001fa08 <bcache+0x8268>
    80003368:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000336a:	2b87b703          	ld	a4,696(a5)
    8000336e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003370:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003374:	00014517          	auipc	a0,0x14
    80003378:	42c50513          	addi	a0,a0,1068 # 800177a0 <bcache>
    8000337c:	ffffe097          	auipc	ra,0xffffe
    80003380:	abe080e7          	jalr	-1346(ra) # 80000e3a <release>
}
    80003384:	60e2                	ld	ra,24(sp)
    80003386:	6442                	ld	s0,16(sp)
    80003388:	64a2                	ld	s1,8(sp)
    8000338a:	6902                	ld	s2,0(sp)
    8000338c:	6105                	addi	sp,sp,32
    8000338e:	8082                	ret
    panic("brelse");
    80003390:	00005517          	auipc	a0,0x5
    80003394:	26050513          	addi	a0,a0,608 # 800085f0 <syscalls+0xe0>
    80003398:	ffffd097          	auipc	ra,0xffffd
    8000339c:	1b0080e7          	jalr	432(ra) # 80000548 <panic>

00000000800033a0 <bpin>:

void
bpin(struct buf *b) {
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	e426                	sd	s1,8(sp)
    800033a8:	1000                	addi	s0,sp,32
    800033aa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033ac:	00014517          	auipc	a0,0x14
    800033b0:	3f450513          	addi	a0,a0,1012 # 800177a0 <bcache>
    800033b4:	ffffe097          	auipc	ra,0xffffe
    800033b8:	9d2080e7          	jalr	-1582(ra) # 80000d86 <acquire>
  b->refcnt++;
    800033bc:	40bc                	lw	a5,64(s1)
    800033be:	2785                	addiw	a5,a5,1
    800033c0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033c2:	00014517          	auipc	a0,0x14
    800033c6:	3de50513          	addi	a0,a0,990 # 800177a0 <bcache>
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	a70080e7          	jalr	-1424(ra) # 80000e3a <release>
}
    800033d2:	60e2                	ld	ra,24(sp)
    800033d4:	6442                	ld	s0,16(sp)
    800033d6:	64a2                	ld	s1,8(sp)
    800033d8:	6105                	addi	sp,sp,32
    800033da:	8082                	ret

00000000800033dc <bunpin>:

void
bunpin(struct buf *b) {
    800033dc:	1101                	addi	sp,sp,-32
    800033de:	ec06                	sd	ra,24(sp)
    800033e0:	e822                	sd	s0,16(sp)
    800033e2:	e426                	sd	s1,8(sp)
    800033e4:	1000                	addi	s0,sp,32
    800033e6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033e8:	00014517          	auipc	a0,0x14
    800033ec:	3b850513          	addi	a0,a0,952 # 800177a0 <bcache>
    800033f0:	ffffe097          	auipc	ra,0xffffe
    800033f4:	996080e7          	jalr	-1642(ra) # 80000d86 <acquire>
  b->refcnt--;
    800033f8:	40bc                	lw	a5,64(s1)
    800033fa:	37fd                	addiw	a5,a5,-1
    800033fc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033fe:	00014517          	auipc	a0,0x14
    80003402:	3a250513          	addi	a0,a0,930 # 800177a0 <bcache>
    80003406:	ffffe097          	auipc	ra,0xffffe
    8000340a:	a34080e7          	jalr	-1484(ra) # 80000e3a <release>
}
    8000340e:	60e2                	ld	ra,24(sp)
    80003410:	6442                	ld	s0,16(sp)
    80003412:	64a2                	ld	s1,8(sp)
    80003414:	6105                	addi	sp,sp,32
    80003416:	8082                	ret

0000000080003418 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003418:	1101                	addi	sp,sp,-32
    8000341a:	ec06                	sd	ra,24(sp)
    8000341c:	e822                	sd	s0,16(sp)
    8000341e:	e426                	sd	s1,8(sp)
    80003420:	e04a                	sd	s2,0(sp)
    80003422:	1000                	addi	s0,sp,32
    80003424:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003426:	00d5d59b          	srliw	a1,a1,0xd
    8000342a:	0001d797          	auipc	a5,0x1d
    8000342e:	a527a783          	lw	a5,-1454(a5) # 8001fe7c <sb+0x1c>
    80003432:	9dbd                	addw	a1,a1,a5
    80003434:	00000097          	auipc	ra,0x0
    80003438:	d9e080e7          	jalr	-610(ra) # 800031d2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000343c:	0074f713          	andi	a4,s1,7
    80003440:	4785                	li	a5,1
    80003442:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003446:	14ce                	slli	s1,s1,0x33
    80003448:	90d9                	srli	s1,s1,0x36
    8000344a:	00950733          	add	a4,a0,s1
    8000344e:	05874703          	lbu	a4,88(a4)
    80003452:	00e7f6b3          	and	a3,a5,a4
    80003456:	c69d                	beqz	a3,80003484 <bfree+0x6c>
    80003458:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000345a:	94aa                	add	s1,s1,a0
    8000345c:	fff7c793          	not	a5,a5
    80003460:	8ff9                	and	a5,a5,a4
    80003462:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003466:	00001097          	auipc	ra,0x1
    8000346a:	104080e7          	jalr	260(ra) # 8000456a <log_write>
  brelse(bp);
    8000346e:	854a                	mv	a0,s2
    80003470:	00000097          	auipc	ra,0x0
    80003474:	e92080e7          	jalr	-366(ra) # 80003302 <brelse>
}
    80003478:	60e2                	ld	ra,24(sp)
    8000347a:	6442                	ld	s0,16(sp)
    8000347c:	64a2                	ld	s1,8(sp)
    8000347e:	6902                	ld	s2,0(sp)
    80003480:	6105                	addi	sp,sp,32
    80003482:	8082                	ret
    panic("freeing free block");
    80003484:	00005517          	auipc	a0,0x5
    80003488:	17450513          	addi	a0,a0,372 # 800085f8 <syscalls+0xe8>
    8000348c:	ffffd097          	auipc	ra,0xffffd
    80003490:	0bc080e7          	jalr	188(ra) # 80000548 <panic>

0000000080003494 <balloc>:
{
    80003494:	711d                	addi	sp,sp,-96
    80003496:	ec86                	sd	ra,88(sp)
    80003498:	e8a2                	sd	s0,80(sp)
    8000349a:	e4a6                	sd	s1,72(sp)
    8000349c:	e0ca                	sd	s2,64(sp)
    8000349e:	fc4e                	sd	s3,56(sp)
    800034a0:	f852                	sd	s4,48(sp)
    800034a2:	f456                	sd	s5,40(sp)
    800034a4:	f05a                	sd	s6,32(sp)
    800034a6:	ec5e                	sd	s7,24(sp)
    800034a8:	e862                	sd	s8,16(sp)
    800034aa:	e466                	sd	s9,8(sp)
    800034ac:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034ae:	0001d797          	auipc	a5,0x1d
    800034b2:	9b67a783          	lw	a5,-1610(a5) # 8001fe64 <sb+0x4>
    800034b6:	cbd1                	beqz	a5,8000354a <balloc+0xb6>
    800034b8:	8baa                	mv	s7,a0
    800034ba:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034bc:	0001db17          	auipc	s6,0x1d
    800034c0:	9a4b0b13          	addi	s6,s6,-1628 # 8001fe60 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034c4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034c6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034c8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034ca:	6c89                	lui	s9,0x2
    800034cc:	a831                	j	800034e8 <balloc+0x54>
    brelse(bp);
    800034ce:	854a                	mv	a0,s2
    800034d0:	00000097          	auipc	ra,0x0
    800034d4:	e32080e7          	jalr	-462(ra) # 80003302 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034d8:	015c87bb          	addw	a5,s9,s5
    800034dc:	00078a9b          	sext.w	s5,a5
    800034e0:	004b2703          	lw	a4,4(s6)
    800034e4:	06eaf363          	bgeu	s5,a4,8000354a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800034e8:	41fad79b          	sraiw	a5,s5,0x1f
    800034ec:	0137d79b          	srliw	a5,a5,0x13
    800034f0:	015787bb          	addw	a5,a5,s5
    800034f4:	40d7d79b          	sraiw	a5,a5,0xd
    800034f8:	01cb2583          	lw	a1,28(s6)
    800034fc:	9dbd                	addw	a1,a1,a5
    800034fe:	855e                	mv	a0,s7
    80003500:	00000097          	auipc	ra,0x0
    80003504:	cd2080e7          	jalr	-814(ra) # 800031d2 <bread>
    80003508:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000350a:	004b2503          	lw	a0,4(s6)
    8000350e:	000a849b          	sext.w	s1,s5
    80003512:	8662                	mv	a2,s8
    80003514:	faa4fde3          	bgeu	s1,a0,800034ce <balloc+0x3a>
      m = 1 << (bi % 8);
    80003518:	41f6579b          	sraiw	a5,a2,0x1f
    8000351c:	01d7d69b          	srliw	a3,a5,0x1d
    80003520:	00c6873b          	addw	a4,a3,a2
    80003524:	00777793          	andi	a5,a4,7
    80003528:	9f95                	subw	a5,a5,a3
    8000352a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000352e:	4037571b          	sraiw	a4,a4,0x3
    80003532:	00e906b3          	add	a3,s2,a4
    80003536:	0586c683          	lbu	a3,88(a3)
    8000353a:	00d7f5b3          	and	a1,a5,a3
    8000353e:	cd91                	beqz	a1,8000355a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003540:	2605                	addiw	a2,a2,1
    80003542:	2485                	addiw	s1,s1,1
    80003544:	fd4618e3          	bne	a2,s4,80003514 <balloc+0x80>
    80003548:	b759                	j	800034ce <balloc+0x3a>
  panic("balloc: out of blocks");
    8000354a:	00005517          	auipc	a0,0x5
    8000354e:	0c650513          	addi	a0,a0,198 # 80008610 <syscalls+0x100>
    80003552:	ffffd097          	auipc	ra,0xffffd
    80003556:	ff6080e7          	jalr	-10(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000355a:	974a                	add	a4,a4,s2
    8000355c:	8fd5                	or	a5,a5,a3
    8000355e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003562:	854a                	mv	a0,s2
    80003564:	00001097          	auipc	ra,0x1
    80003568:	006080e7          	jalr	6(ra) # 8000456a <log_write>
        brelse(bp);
    8000356c:	854a                	mv	a0,s2
    8000356e:	00000097          	auipc	ra,0x0
    80003572:	d94080e7          	jalr	-620(ra) # 80003302 <brelse>
  bp = bread(dev, bno);
    80003576:	85a6                	mv	a1,s1
    80003578:	855e                	mv	a0,s7
    8000357a:	00000097          	auipc	ra,0x0
    8000357e:	c58080e7          	jalr	-936(ra) # 800031d2 <bread>
    80003582:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003584:	40000613          	li	a2,1024
    80003588:	4581                	li	a1,0
    8000358a:	05850513          	addi	a0,a0,88
    8000358e:	ffffe097          	auipc	ra,0xffffe
    80003592:	8f4080e7          	jalr	-1804(ra) # 80000e82 <memset>
  log_write(bp);
    80003596:	854a                	mv	a0,s2
    80003598:	00001097          	auipc	ra,0x1
    8000359c:	fd2080e7          	jalr	-46(ra) # 8000456a <log_write>
  brelse(bp);
    800035a0:	854a                	mv	a0,s2
    800035a2:	00000097          	auipc	ra,0x0
    800035a6:	d60080e7          	jalr	-672(ra) # 80003302 <brelse>
}
    800035aa:	8526                	mv	a0,s1
    800035ac:	60e6                	ld	ra,88(sp)
    800035ae:	6446                	ld	s0,80(sp)
    800035b0:	64a6                	ld	s1,72(sp)
    800035b2:	6906                	ld	s2,64(sp)
    800035b4:	79e2                	ld	s3,56(sp)
    800035b6:	7a42                	ld	s4,48(sp)
    800035b8:	7aa2                	ld	s5,40(sp)
    800035ba:	7b02                	ld	s6,32(sp)
    800035bc:	6be2                	ld	s7,24(sp)
    800035be:	6c42                	ld	s8,16(sp)
    800035c0:	6ca2                	ld	s9,8(sp)
    800035c2:	6125                	addi	sp,sp,96
    800035c4:	8082                	ret

00000000800035c6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800035c6:	7179                	addi	sp,sp,-48
    800035c8:	f406                	sd	ra,40(sp)
    800035ca:	f022                	sd	s0,32(sp)
    800035cc:	ec26                	sd	s1,24(sp)
    800035ce:	e84a                	sd	s2,16(sp)
    800035d0:	e44e                	sd	s3,8(sp)
    800035d2:	e052                	sd	s4,0(sp)
    800035d4:	1800                	addi	s0,sp,48
    800035d6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035d8:	47ad                	li	a5,11
    800035da:	04b7fe63          	bgeu	a5,a1,80003636 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800035de:	ff45849b          	addiw	s1,a1,-12
    800035e2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035e6:	0ff00793          	li	a5,255
    800035ea:	0ae7e363          	bltu	a5,a4,80003690 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035ee:	08052583          	lw	a1,128(a0)
    800035f2:	c5ad                	beqz	a1,8000365c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035f4:	00092503          	lw	a0,0(s2)
    800035f8:	00000097          	auipc	ra,0x0
    800035fc:	bda080e7          	jalr	-1062(ra) # 800031d2 <bread>
    80003600:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003602:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003606:	02049593          	slli	a1,s1,0x20
    8000360a:	9181                	srli	a1,a1,0x20
    8000360c:	058a                	slli	a1,a1,0x2
    8000360e:	00b784b3          	add	s1,a5,a1
    80003612:	0004a983          	lw	s3,0(s1)
    80003616:	04098d63          	beqz	s3,80003670 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000361a:	8552                	mv	a0,s4
    8000361c:	00000097          	auipc	ra,0x0
    80003620:	ce6080e7          	jalr	-794(ra) # 80003302 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003624:	854e                	mv	a0,s3
    80003626:	70a2                	ld	ra,40(sp)
    80003628:	7402                	ld	s0,32(sp)
    8000362a:	64e2                	ld	s1,24(sp)
    8000362c:	6942                	ld	s2,16(sp)
    8000362e:	69a2                	ld	s3,8(sp)
    80003630:	6a02                	ld	s4,0(sp)
    80003632:	6145                	addi	sp,sp,48
    80003634:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003636:	02059493          	slli	s1,a1,0x20
    8000363a:	9081                	srli	s1,s1,0x20
    8000363c:	048a                	slli	s1,s1,0x2
    8000363e:	94aa                	add	s1,s1,a0
    80003640:	0504a983          	lw	s3,80(s1)
    80003644:	fe0990e3          	bnez	s3,80003624 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003648:	4108                	lw	a0,0(a0)
    8000364a:	00000097          	auipc	ra,0x0
    8000364e:	e4a080e7          	jalr	-438(ra) # 80003494 <balloc>
    80003652:	0005099b          	sext.w	s3,a0
    80003656:	0534a823          	sw	s3,80(s1)
    8000365a:	b7e9                	j	80003624 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000365c:	4108                	lw	a0,0(a0)
    8000365e:	00000097          	auipc	ra,0x0
    80003662:	e36080e7          	jalr	-458(ra) # 80003494 <balloc>
    80003666:	0005059b          	sext.w	a1,a0
    8000366a:	08b92023          	sw	a1,128(s2)
    8000366e:	b759                	j	800035f4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003670:	00092503          	lw	a0,0(s2)
    80003674:	00000097          	auipc	ra,0x0
    80003678:	e20080e7          	jalr	-480(ra) # 80003494 <balloc>
    8000367c:	0005099b          	sext.w	s3,a0
    80003680:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003684:	8552                	mv	a0,s4
    80003686:	00001097          	auipc	ra,0x1
    8000368a:	ee4080e7          	jalr	-284(ra) # 8000456a <log_write>
    8000368e:	b771                	j	8000361a <bmap+0x54>
  panic("bmap: out of range");
    80003690:	00005517          	auipc	a0,0x5
    80003694:	f9850513          	addi	a0,a0,-104 # 80008628 <syscalls+0x118>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	eb0080e7          	jalr	-336(ra) # 80000548 <panic>

00000000800036a0 <iget>:
{
    800036a0:	7179                	addi	sp,sp,-48
    800036a2:	f406                	sd	ra,40(sp)
    800036a4:	f022                	sd	s0,32(sp)
    800036a6:	ec26                	sd	s1,24(sp)
    800036a8:	e84a                	sd	s2,16(sp)
    800036aa:	e44e                	sd	s3,8(sp)
    800036ac:	e052                	sd	s4,0(sp)
    800036ae:	1800                	addi	s0,sp,48
    800036b0:	89aa                	mv	s3,a0
    800036b2:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800036b4:	0001c517          	auipc	a0,0x1c
    800036b8:	7cc50513          	addi	a0,a0,1996 # 8001fe80 <icache>
    800036bc:	ffffd097          	auipc	ra,0xffffd
    800036c0:	6ca080e7          	jalr	1738(ra) # 80000d86 <acquire>
  empty = 0;
    800036c4:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800036c6:	0001c497          	auipc	s1,0x1c
    800036ca:	7d248493          	addi	s1,s1,2002 # 8001fe98 <icache+0x18>
    800036ce:	0001e697          	auipc	a3,0x1e
    800036d2:	25a68693          	addi	a3,a3,602 # 80021928 <log>
    800036d6:	a039                	j	800036e4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036d8:	02090b63          	beqz	s2,8000370e <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800036dc:	08848493          	addi	s1,s1,136
    800036e0:	02d48a63          	beq	s1,a3,80003714 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036e4:	449c                	lw	a5,8(s1)
    800036e6:	fef059e3          	blez	a5,800036d8 <iget+0x38>
    800036ea:	4098                	lw	a4,0(s1)
    800036ec:	ff3716e3          	bne	a4,s3,800036d8 <iget+0x38>
    800036f0:	40d8                	lw	a4,4(s1)
    800036f2:	ff4713e3          	bne	a4,s4,800036d8 <iget+0x38>
      ip->ref++;
    800036f6:	2785                	addiw	a5,a5,1
    800036f8:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800036fa:	0001c517          	auipc	a0,0x1c
    800036fe:	78650513          	addi	a0,a0,1926 # 8001fe80 <icache>
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	738080e7          	jalr	1848(ra) # 80000e3a <release>
      return ip;
    8000370a:	8926                	mv	s2,s1
    8000370c:	a03d                	j	8000373a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000370e:	f7f9                	bnez	a5,800036dc <iget+0x3c>
    80003710:	8926                	mv	s2,s1
    80003712:	b7e9                	j	800036dc <iget+0x3c>
  if(empty == 0)
    80003714:	02090c63          	beqz	s2,8000374c <iget+0xac>
  ip->dev = dev;
    80003718:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000371c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003720:	4785                	li	a5,1
    80003722:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003726:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    8000372a:	0001c517          	auipc	a0,0x1c
    8000372e:	75650513          	addi	a0,a0,1878 # 8001fe80 <icache>
    80003732:	ffffd097          	auipc	ra,0xffffd
    80003736:	708080e7          	jalr	1800(ra) # 80000e3a <release>
}
    8000373a:	854a                	mv	a0,s2
    8000373c:	70a2                	ld	ra,40(sp)
    8000373e:	7402                	ld	s0,32(sp)
    80003740:	64e2                	ld	s1,24(sp)
    80003742:	6942                	ld	s2,16(sp)
    80003744:	69a2                	ld	s3,8(sp)
    80003746:	6a02                	ld	s4,0(sp)
    80003748:	6145                	addi	sp,sp,48
    8000374a:	8082                	ret
    panic("iget: no inodes");
    8000374c:	00005517          	auipc	a0,0x5
    80003750:	ef450513          	addi	a0,a0,-268 # 80008640 <syscalls+0x130>
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	df4080e7          	jalr	-524(ra) # 80000548 <panic>

000000008000375c <fsinit>:
fsinit(int dev) {
    8000375c:	7179                	addi	sp,sp,-48
    8000375e:	f406                	sd	ra,40(sp)
    80003760:	f022                	sd	s0,32(sp)
    80003762:	ec26                	sd	s1,24(sp)
    80003764:	e84a                	sd	s2,16(sp)
    80003766:	e44e                	sd	s3,8(sp)
    80003768:	1800                	addi	s0,sp,48
    8000376a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000376c:	4585                	li	a1,1
    8000376e:	00000097          	auipc	ra,0x0
    80003772:	a64080e7          	jalr	-1436(ra) # 800031d2 <bread>
    80003776:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003778:	0001c997          	auipc	s3,0x1c
    8000377c:	6e898993          	addi	s3,s3,1768 # 8001fe60 <sb>
    80003780:	02000613          	li	a2,32
    80003784:	05850593          	addi	a1,a0,88
    80003788:	854e                	mv	a0,s3
    8000378a:	ffffd097          	auipc	ra,0xffffd
    8000378e:	758080e7          	jalr	1880(ra) # 80000ee2 <memmove>
  brelse(bp);
    80003792:	8526                	mv	a0,s1
    80003794:	00000097          	auipc	ra,0x0
    80003798:	b6e080e7          	jalr	-1170(ra) # 80003302 <brelse>
  if(sb.magic != FSMAGIC)
    8000379c:	0009a703          	lw	a4,0(s3)
    800037a0:	102037b7          	lui	a5,0x10203
    800037a4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037a8:	02f71263          	bne	a4,a5,800037cc <fsinit+0x70>
  initlog(dev, &sb);
    800037ac:	0001c597          	auipc	a1,0x1c
    800037b0:	6b458593          	addi	a1,a1,1716 # 8001fe60 <sb>
    800037b4:	854a                	mv	a0,s2
    800037b6:	00001097          	auipc	ra,0x1
    800037ba:	b3c080e7          	jalr	-1220(ra) # 800042f2 <initlog>
}
    800037be:	70a2                	ld	ra,40(sp)
    800037c0:	7402                	ld	s0,32(sp)
    800037c2:	64e2                	ld	s1,24(sp)
    800037c4:	6942                	ld	s2,16(sp)
    800037c6:	69a2                	ld	s3,8(sp)
    800037c8:	6145                	addi	sp,sp,48
    800037ca:	8082                	ret
    panic("invalid file system");
    800037cc:	00005517          	auipc	a0,0x5
    800037d0:	e8450513          	addi	a0,a0,-380 # 80008650 <syscalls+0x140>
    800037d4:	ffffd097          	auipc	ra,0xffffd
    800037d8:	d74080e7          	jalr	-652(ra) # 80000548 <panic>

00000000800037dc <iinit>:
{
    800037dc:	7179                	addi	sp,sp,-48
    800037de:	f406                	sd	ra,40(sp)
    800037e0:	f022                	sd	s0,32(sp)
    800037e2:	ec26                	sd	s1,24(sp)
    800037e4:	e84a                	sd	s2,16(sp)
    800037e6:	e44e                	sd	s3,8(sp)
    800037e8:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800037ea:	00005597          	auipc	a1,0x5
    800037ee:	e7e58593          	addi	a1,a1,-386 # 80008668 <syscalls+0x158>
    800037f2:	0001c517          	auipc	a0,0x1c
    800037f6:	68e50513          	addi	a0,a0,1678 # 8001fe80 <icache>
    800037fa:	ffffd097          	auipc	ra,0xffffd
    800037fe:	4fc080e7          	jalr	1276(ra) # 80000cf6 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003802:	0001c497          	auipc	s1,0x1c
    80003806:	6a648493          	addi	s1,s1,1702 # 8001fea8 <icache+0x28>
    8000380a:	0001e997          	auipc	s3,0x1e
    8000380e:	12e98993          	addi	s3,s3,302 # 80021938 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003812:	00005917          	auipc	s2,0x5
    80003816:	e5e90913          	addi	s2,s2,-418 # 80008670 <syscalls+0x160>
    8000381a:	85ca                	mv	a1,s2
    8000381c:	8526                	mv	a0,s1
    8000381e:	00001097          	auipc	ra,0x1
    80003822:	e3a080e7          	jalr	-454(ra) # 80004658 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003826:	08848493          	addi	s1,s1,136
    8000382a:	ff3498e3          	bne	s1,s3,8000381a <iinit+0x3e>
}
    8000382e:	70a2                	ld	ra,40(sp)
    80003830:	7402                	ld	s0,32(sp)
    80003832:	64e2                	ld	s1,24(sp)
    80003834:	6942                	ld	s2,16(sp)
    80003836:	69a2                	ld	s3,8(sp)
    80003838:	6145                	addi	sp,sp,48
    8000383a:	8082                	ret

000000008000383c <ialloc>:
{
    8000383c:	715d                	addi	sp,sp,-80
    8000383e:	e486                	sd	ra,72(sp)
    80003840:	e0a2                	sd	s0,64(sp)
    80003842:	fc26                	sd	s1,56(sp)
    80003844:	f84a                	sd	s2,48(sp)
    80003846:	f44e                	sd	s3,40(sp)
    80003848:	f052                	sd	s4,32(sp)
    8000384a:	ec56                	sd	s5,24(sp)
    8000384c:	e85a                	sd	s6,16(sp)
    8000384e:	e45e                	sd	s7,8(sp)
    80003850:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003852:	0001c717          	auipc	a4,0x1c
    80003856:	61a72703          	lw	a4,1562(a4) # 8001fe6c <sb+0xc>
    8000385a:	4785                	li	a5,1
    8000385c:	04e7fa63          	bgeu	a5,a4,800038b0 <ialloc+0x74>
    80003860:	8aaa                	mv	s5,a0
    80003862:	8bae                	mv	s7,a1
    80003864:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003866:	0001ca17          	auipc	s4,0x1c
    8000386a:	5faa0a13          	addi	s4,s4,1530 # 8001fe60 <sb>
    8000386e:	00048b1b          	sext.w	s6,s1
    80003872:	0044d593          	srli	a1,s1,0x4
    80003876:	018a2783          	lw	a5,24(s4)
    8000387a:	9dbd                	addw	a1,a1,a5
    8000387c:	8556                	mv	a0,s5
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	954080e7          	jalr	-1708(ra) # 800031d2 <bread>
    80003886:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003888:	05850993          	addi	s3,a0,88
    8000388c:	00f4f793          	andi	a5,s1,15
    80003890:	079a                	slli	a5,a5,0x6
    80003892:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003894:	00099783          	lh	a5,0(s3)
    80003898:	c785                	beqz	a5,800038c0 <ialloc+0x84>
    brelse(bp);
    8000389a:	00000097          	auipc	ra,0x0
    8000389e:	a68080e7          	jalr	-1432(ra) # 80003302 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800038a2:	0485                	addi	s1,s1,1
    800038a4:	00ca2703          	lw	a4,12(s4)
    800038a8:	0004879b          	sext.w	a5,s1
    800038ac:	fce7e1e3          	bltu	a5,a4,8000386e <ialloc+0x32>
  panic("ialloc: no inodes");
    800038b0:	00005517          	auipc	a0,0x5
    800038b4:	dc850513          	addi	a0,a0,-568 # 80008678 <syscalls+0x168>
    800038b8:	ffffd097          	auipc	ra,0xffffd
    800038bc:	c90080e7          	jalr	-880(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    800038c0:	04000613          	li	a2,64
    800038c4:	4581                	li	a1,0
    800038c6:	854e                	mv	a0,s3
    800038c8:	ffffd097          	auipc	ra,0xffffd
    800038cc:	5ba080e7          	jalr	1466(ra) # 80000e82 <memset>
      dip->type = type;
    800038d0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038d4:	854a                	mv	a0,s2
    800038d6:	00001097          	auipc	ra,0x1
    800038da:	c94080e7          	jalr	-876(ra) # 8000456a <log_write>
      brelse(bp);
    800038de:	854a                	mv	a0,s2
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	a22080e7          	jalr	-1502(ra) # 80003302 <brelse>
      return iget(dev, inum);
    800038e8:	85da                	mv	a1,s6
    800038ea:	8556                	mv	a0,s5
    800038ec:	00000097          	auipc	ra,0x0
    800038f0:	db4080e7          	jalr	-588(ra) # 800036a0 <iget>
}
    800038f4:	60a6                	ld	ra,72(sp)
    800038f6:	6406                	ld	s0,64(sp)
    800038f8:	74e2                	ld	s1,56(sp)
    800038fa:	7942                	ld	s2,48(sp)
    800038fc:	79a2                	ld	s3,40(sp)
    800038fe:	7a02                	ld	s4,32(sp)
    80003900:	6ae2                	ld	s5,24(sp)
    80003902:	6b42                	ld	s6,16(sp)
    80003904:	6ba2                	ld	s7,8(sp)
    80003906:	6161                	addi	sp,sp,80
    80003908:	8082                	ret

000000008000390a <iupdate>:
{
    8000390a:	1101                	addi	sp,sp,-32
    8000390c:	ec06                	sd	ra,24(sp)
    8000390e:	e822                	sd	s0,16(sp)
    80003910:	e426                	sd	s1,8(sp)
    80003912:	e04a                	sd	s2,0(sp)
    80003914:	1000                	addi	s0,sp,32
    80003916:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003918:	415c                	lw	a5,4(a0)
    8000391a:	0047d79b          	srliw	a5,a5,0x4
    8000391e:	0001c597          	auipc	a1,0x1c
    80003922:	55a5a583          	lw	a1,1370(a1) # 8001fe78 <sb+0x18>
    80003926:	9dbd                	addw	a1,a1,a5
    80003928:	4108                	lw	a0,0(a0)
    8000392a:	00000097          	auipc	ra,0x0
    8000392e:	8a8080e7          	jalr	-1880(ra) # 800031d2 <bread>
    80003932:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003934:	05850793          	addi	a5,a0,88
    80003938:	40c8                	lw	a0,4(s1)
    8000393a:	893d                	andi	a0,a0,15
    8000393c:	051a                	slli	a0,a0,0x6
    8000393e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003940:	04449703          	lh	a4,68(s1)
    80003944:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003948:	04649703          	lh	a4,70(s1)
    8000394c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003950:	04849703          	lh	a4,72(s1)
    80003954:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003958:	04a49703          	lh	a4,74(s1)
    8000395c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003960:	44f8                	lw	a4,76(s1)
    80003962:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003964:	03400613          	li	a2,52
    80003968:	05048593          	addi	a1,s1,80
    8000396c:	0531                	addi	a0,a0,12
    8000396e:	ffffd097          	auipc	ra,0xffffd
    80003972:	574080e7          	jalr	1396(ra) # 80000ee2 <memmove>
  log_write(bp);
    80003976:	854a                	mv	a0,s2
    80003978:	00001097          	auipc	ra,0x1
    8000397c:	bf2080e7          	jalr	-1038(ra) # 8000456a <log_write>
  brelse(bp);
    80003980:	854a                	mv	a0,s2
    80003982:	00000097          	auipc	ra,0x0
    80003986:	980080e7          	jalr	-1664(ra) # 80003302 <brelse>
}
    8000398a:	60e2                	ld	ra,24(sp)
    8000398c:	6442                	ld	s0,16(sp)
    8000398e:	64a2                	ld	s1,8(sp)
    80003990:	6902                	ld	s2,0(sp)
    80003992:	6105                	addi	sp,sp,32
    80003994:	8082                	ret

0000000080003996 <idup>:
{
    80003996:	1101                	addi	sp,sp,-32
    80003998:	ec06                	sd	ra,24(sp)
    8000399a:	e822                	sd	s0,16(sp)
    8000399c:	e426                	sd	s1,8(sp)
    8000399e:	1000                	addi	s0,sp,32
    800039a0:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800039a2:	0001c517          	auipc	a0,0x1c
    800039a6:	4de50513          	addi	a0,a0,1246 # 8001fe80 <icache>
    800039aa:	ffffd097          	auipc	ra,0xffffd
    800039ae:	3dc080e7          	jalr	988(ra) # 80000d86 <acquire>
  ip->ref++;
    800039b2:	449c                	lw	a5,8(s1)
    800039b4:	2785                	addiw	a5,a5,1
    800039b6:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800039b8:	0001c517          	auipc	a0,0x1c
    800039bc:	4c850513          	addi	a0,a0,1224 # 8001fe80 <icache>
    800039c0:	ffffd097          	auipc	ra,0xffffd
    800039c4:	47a080e7          	jalr	1146(ra) # 80000e3a <release>
}
    800039c8:	8526                	mv	a0,s1
    800039ca:	60e2                	ld	ra,24(sp)
    800039cc:	6442                	ld	s0,16(sp)
    800039ce:	64a2                	ld	s1,8(sp)
    800039d0:	6105                	addi	sp,sp,32
    800039d2:	8082                	ret

00000000800039d4 <ilock>:
{
    800039d4:	1101                	addi	sp,sp,-32
    800039d6:	ec06                	sd	ra,24(sp)
    800039d8:	e822                	sd	s0,16(sp)
    800039da:	e426                	sd	s1,8(sp)
    800039dc:	e04a                	sd	s2,0(sp)
    800039de:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039e0:	c115                	beqz	a0,80003a04 <ilock+0x30>
    800039e2:	84aa                	mv	s1,a0
    800039e4:	451c                	lw	a5,8(a0)
    800039e6:	00f05f63          	blez	a5,80003a04 <ilock+0x30>
  acquiresleep(&ip->lock);
    800039ea:	0541                	addi	a0,a0,16
    800039ec:	00001097          	auipc	ra,0x1
    800039f0:	ca6080e7          	jalr	-858(ra) # 80004692 <acquiresleep>
  if(ip->valid == 0){
    800039f4:	40bc                	lw	a5,64(s1)
    800039f6:	cf99                	beqz	a5,80003a14 <ilock+0x40>
}
    800039f8:	60e2                	ld	ra,24(sp)
    800039fa:	6442                	ld	s0,16(sp)
    800039fc:	64a2                	ld	s1,8(sp)
    800039fe:	6902                	ld	s2,0(sp)
    80003a00:	6105                	addi	sp,sp,32
    80003a02:	8082                	ret
    panic("ilock");
    80003a04:	00005517          	auipc	a0,0x5
    80003a08:	c8c50513          	addi	a0,a0,-884 # 80008690 <syscalls+0x180>
    80003a0c:	ffffd097          	auipc	ra,0xffffd
    80003a10:	b3c080e7          	jalr	-1220(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a14:	40dc                	lw	a5,4(s1)
    80003a16:	0047d79b          	srliw	a5,a5,0x4
    80003a1a:	0001c597          	auipc	a1,0x1c
    80003a1e:	45e5a583          	lw	a1,1118(a1) # 8001fe78 <sb+0x18>
    80003a22:	9dbd                	addw	a1,a1,a5
    80003a24:	4088                	lw	a0,0(s1)
    80003a26:	fffff097          	auipc	ra,0xfffff
    80003a2a:	7ac080e7          	jalr	1964(ra) # 800031d2 <bread>
    80003a2e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a30:	05850593          	addi	a1,a0,88
    80003a34:	40dc                	lw	a5,4(s1)
    80003a36:	8bbd                	andi	a5,a5,15
    80003a38:	079a                	slli	a5,a5,0x6
    80003a3a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a3c:	00059783          	lh	a5,0(a1)
    80003a40:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a44:	00259783          	lh	a5,2(a1)
    80003a48:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a4c:	00459783          	lh	a5,4(a1)
    80003a50:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a54:	00659783          	lh	a5,6(a1)
    80003a58:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a5c:	459c                	lw	a5,8(a1)
    80003a5e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a60:	03400613          	li	a2,52
    80003a64:	05b1                	addi	a1,a1,12
    80003a66:	05048513          	addi	a0,s1,80
    80003a6a:	ffffd097          	auipc	ra,0xffffd
    80003a6e:	478080e7          	jalr	1144(ra) # 80000ee2 <memmove>
    brelse(bp);
    80003a72:	854a                	mv	a0,s2
    80003a74:	00000097          	auipc	ra,0x0
    80003a78:	88e080e7          	jalr	-1906(ra) # 80003302 <brelse>
    ip->valid = 1;
    80003a7c:	4785                	li	a5,1
    80003a7e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a80:	04449783          	lh	a5,68(s1)
    80003a84:	fbb5                	bnez	a5,800039f8 <ilock+0x24>
      panic("ilock: no type");
    80003a86:	00005517          	auipc	a0,0x5
    80003a8a:	c1250513          	addi	a0,a0,-1006 # 80008698 <syscalls+0x188>
    80003a8e:	ffffd097          	auipc	ra,0xffffd
    80003a92:	aba080e7          	jalr	-1350(ra) # 80000548 <panic>

0000000080003a96 <iunlock>:
{
    80003a96:	1101                	addi	sp,sp,-32
    80003a98:	ec06                	sd	ra,24(sp)
    80003a9a:	e822                	sd	s0,16(sp)
    80003a9c:	e426                	sd	s1,8(sp)
    80003a9e:	e04a                	sd	s2,0(sp)
    80003aa0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003aa2:	c905                	beqz	a0,80003ad2 <iunlock+0x3c>
    80003aa4:	84aa                	mv	s1,a0
    80003aa6:	01050913          	addi	s2,a0,16
    80003aaa:	854a                	mv	a0,s2
    80003aac:	00001097          	auipc	ra,0x1
    80003ab0:	c80080e7          	jalr	-896(ra) # 8000472c <holdingsleep>
    80003ab4:	cd19                	beqz	a0,80003ad2 <iunlock+0x3c>
    80003ab6:	449c                	lw	a5,8(s1)
    80003ab8:	00f05d63          	blez	a5,80003ad2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003abc:	854a                	mv	a0,s2
    80003abe:	00001097          	auipc	ra,0x1
    80003ac2:	c2a080e7          	jalr	-982(ra) # 800046e8 <releasesleep>
}
    80003ac6:	60e2                	ld	ra,24(sp)
    80003ac8:	6442                	ld	s0,16(sp)
    80003aca:	64a2                	ld	s1,8(sp)
    80003acc:	6902                	ld	s2,0(sp)
    80003ace:	6105                	addi	sp,sp,32
    80003ad0:	8082                	ret
    panic("iunlock");
    80003ad2:	00005517          	auipc	a0,0x5
    80003ad6:	bd650513          	addi	a0,a0,-1066 # 800086a8 <syscalls+0x198>
    80003ada:	ffffd097          	auipc	ra,0xffffd
    80003ade:	a6e080e7          	jalr	-1426(ra) # 80000548 <panic>

0000000080003ae2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ae2:	7179                	addi	sp,sp,-48
    80003ae4:	f406                	sd	ra,40(sp)
    80003ae6:	f022                	sd	s0,32(sp)
    80003ae8:	ec26                	sd	s1,24(sp)
    80003aea:	e84a                	sd	s2,16(sp)
    80003aec:	e44e                	sd	s3,8(sp)
    80003aee:	e052                	sd	s4,0(sp)
    80003af0:	1800                	addi	s0,sp,48
    80003af2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003af4:	05050493          	addi	s1,a0,80
    80003af8:	08050913          	addi	s2,a0,128
    80003afc:	a021                	j	80003b04 <itrunc+0x22>
    80003afe:	0491                	addi	s1,s1,4
    80003b00:	01248d63          	beq	s1,s2,80003b1a <itrunc+0x38>
    if(ip->addrs[i]){
    80003b04:	408c                	lw	a1,0(s1)
    80003b06:	dde5                	beqz	a1,80003afe <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b08:	0009a503          	lw	a0,0(s3)
    80003b0c:	00000097          	auipc	ra,0x0
    80003b10:	90c080e7          	jalr	-1780(ra) # 80003418 <bfree>
      ip->addrs[i] = 0;
    80003b14:	0004a023          	sw	zero,0(s1)
    80003b18:	b7dd                	j	80003afe <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b1a:	0809a583          	lw	a1,128(s3)
    80003b1e:	e185                	bnez	a1,80003b3e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b20:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b24:	854e                	mv	a0,s3
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	de4080e7          	jalr	-540(ra) # 8000390a <iupdate>
}
    80003b2e:	70a2                	ld	ra,40(sp)
    80003b30:	7402                	ld	s0,32(sp)
    80003b32:	64e2                	ld	s1,24(sp)
    80003b34:	6942                	ld	s2,16(sp)
    80003b36:	69a2                	ld	s3,8(sp)
    80003b38:	6a02                	ld	s4,0(sp)
    80003b3a:	6145                	addi	sp,sp,48
    80003b3c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b3e:	0009a503          	lw	a0,0(s3)
    80003b42:	fffff097          	auipc	ra,0xfffff
    80003b46:	690080e7          	jalr	1680(ra) # 800031d2 <bread>
    80003b4a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b4c:	05850493          	addi	s1,a0,88
    80003b50:	45850913          	addi	s2,a0,1112
    80003b54:	a811                	j	80003b68 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003b56:	0009a503          	lw	a0,0(s3)
    80003b5a:	00000097          	auipc	ra,0x0
    80003b5e:	8be080e7          	jalr	-1858(ra) # 80003418 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b62:	0491                	addi	s1,s1,4
    80003b64:	01248563          	beq	s1,s2,80003b6e <itrunc+0x8c>
      if(a[j])
    80003b68:	408c                	lw	a1,0(s1)
    80003b6a:	dde5                	beqz	a1,80003b62 <itrunc+0x80>
    80003b6c:	b7ed                	j	80003b56 <itrunc+0x74>
    brelse(bp);
    80003b6e:	8552                	mv	a0,s4
    80003b70:	fffff097          	auipc	ra,0xfffff
    80003b74:	792080e7          	jalr	1938(ra) # 80003302 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b78:	0809a583          	lw	a1,128(s3)
    80003b7c:	0009a503          	lw	a0,0(s3)
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	898080e7          	jalr	-1896(ra) # 80003418 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b88:	0809a023          	sw	zero,128(s3)
    80003b8c:	bf51                	j	80003b20 <itrunc+0x3e>

0000000080003b8e <iput>:
{
    80003b8e:	1101                	addi	sp,sp,-32
    80003b90:	ec06                	sd	ra,24(sp)
    80003b92:	e822                	sd	s0,16(sp)
    80003b94:	e426                	sd	s1,8(sp)
    80003b96:	e04a                	sd	s2,0(sp)
    80003b98:	1000                	addi	s0,sp,32
    80003b9a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b9c:	0001c517          	auipc	a0,0x1c
    80003ba0:	2e450513          	addi	a0,a0,740 # 8001fe80 <icache>
    80003ba4:	ffffd097          	auipc	ra,0xffffd
    80003ba8:	1e2080e7          	jalr	482(ra) # 80000d86 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bac:	4498                	lw	a4,8(s1)
    80003bae:	4785                	li	a5,1
    80003bb0:	02f70363          	beq	a4,a5,80003bd6 <iput+0x48>
  ip->ref--;
    80003bb4:	449c                	lw	a5,8(s1)
    80003bb6:	37fd                	addiw	a5,a5,-1
    80003bb8:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003bba:	0001c517          	auipc	a0,0x1c
    80003bbe:	2c650513          	addi	a0,a0,710 # 8001fe80 <icache>
    80003bc2:	ffffd097          	auipc	ra,0xffffd
    80003bc6:	278080e7          	jalr	632(ra) # 80000e3a <release>
}
    80003bca:	60e2                	ld	ra,24(sp)
    80003bcc:	6442                	ld	s0,16(sp)
    80003bce:	64a2                	ld	s1,8(sp)
    80003bd0:	6902                	ld	s2,0(sp)
    80003bd2:	6105                	addi	sp,sp,32
    80003bd4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bd6:	40bc                	lw	a5,64(s1)
    80003bd8:	dff1                	beqz	a5,80003bb4 <iput+0x26>
    80003bda:	04a49783          	lh	a5,74(s1)
    80003bde:	fbf9                	bnez	a5,80003bb4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003be0:	01048913          	addi	s2,s1,16
    80003be4:	854a                	mv	a0,s2
    80003be6:	00001097          	auipc	ra,0x1
    80003bea:	aac080e7          	jalr	-1364(ra) # 80004692 <acquiresleep>
    release(&icache.lock);
    80003bee:	0001c517          	auipc	a0,0x1c
    80003bf2:	29250513          	addi	a0,a0,658 # 8001fe80 <icache>
    80003bf6:	ffffd097          	auipc	ra,0xffffd
    80003bfa:	244080e7          	jalr	580(ra) # 80000e3a <release>
    itrunc(ip);
    80003bfe:	8526                	mv	a0,s1
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	ee2080e7          	jalr	-286(ra) # 80003ae2 <itrunc>
    ip->type = 0;
    80003c08:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c0c:	8526                	mv	a0,s1
    80003c0e:	00000097          	auipc	ra,0x0
    80003c12:	cfc080e7          	jalr	-772(ra) # 8000390a <iupdate>
    ip->valid = 0;
    80003c16:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c1a:	854a                	mv	a0,s2
    80003c1c:	00001097          	auipc	ra,0x1
    80003c20:	acc080e7          	jalr	-1332(ra) # 800046e8 <releasesleep>
    acquire(&icache.lock);
    80003c24:	0001c517          	auipc	a0,0x1c
    80003c28:	25c50513          	addi	a0,a0,604 # 8001fe80 <icache>
    80003c2c:	ffffd097          	auipc	ra,0xffffd
    80003c30:	15a080e7          	jalr	346(ra) # 80000d86 <acquire>
    80003c34:	b741                	j	80003bb4 <iput+0x26>

0000000080003c36 <iunlockput>:
{
    80003c36:	1101                	addi	sp,sp,-32
    80003c38:	ec06                	sd	ra,24(sp)
    80003c3a:	e822                	sd	s0,16(sp)
    80003c3c:	e426                	sd	s1,8(sp)
    80003c3e:	1000                	addi	s0,sp,32
    80003c40:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c42:	00000097          	auipc	ra,0x0
    80003c46:	e54080e7          	jalr	-428(ra) # 80003a96 <iunlock>
  iput(ip);
    80003c4a:	8526                	mv	a0,s1
    80003c4c:	00000097          	auipc	ra,0x0
    80003c50:	f42080e7          	jalr	-190(ra) # 80003b8e <iput>
}
    80003c54:	60e2                	ld	ra,24(sp)
    80003c56:	6442                	ld	s0,16(sp)
    80003c58:	64a2                	ld	s1,8(sp)
    80003c5a:	6105                	addi	sp,sp,32
    80003c5c:	8082                	ret

0000000080003c5e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c5e:	1141                	addi	sp,sp,-16
    80003c60:	e422                	sd	s0,8(sp)
    80003c62:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c64:	411c                	lw	a5,0(a0)
    80003c66:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c68:	415c                	lw	a5,4(a0)
    80003c6a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c6c:	04451783          	lh	a5,68(a0)
    80003c70:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c74:	04a51783          	lh	a5,74(a0)
    80003c78:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c7c:	04c56783          	lwu	a5,76(a0)
    80003c80:	e99c                	sd	a5,16(a1)
}
    80003c82:	6422                	ld	s0,8(sp)
    80003c84:	0141                	addi	sp,sp,16
    80003c86:	8082                	ret

0000000080003c88 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c88:	457c                	lw	a5,76(a0)
    80003c8a:	0ed7e963          	bltu	a5,a3,80003d7c <readi+0xf4>
{
    80003c8e:	7159                	addi	sp,sp,-112
    80003c90:	f486                	sd	ra,104(sp)
    80003c92:	f0a2                	sd	s0,96(sp)
    80003c94:	eca6                	sd	s1,88(sp)
    80003c96:	e8ca                	sd	s2,80(sp)
    80003c98:	e4ce                	sd	s3,72(sp)
    80003c9a:	e0d2                	sd	s4,64(sp)
    80003c9c:	fc56                	sd	s5,56(sp)
    80003c9e:	f85a                	sd	s6,48(sp)
    80003ca0:	f45e                	sd	s7,40(sp)
    80003ca2:	f062                	sd	s8,32(sp)
    80003ca4:	ec66                	sd	s9,24(sp)
    80003ca6:	e86a                	sd	s10,16(sp)
    80003ca8:	e46e                	sd	s11,8(sp)
    80003caa:	1880                	addi	s0,sp,112
    80003cac:	8baa                	mv	s7,a0
    80003cae:	8c2e                	mv	s8,a1
    80003cb0:	8ab2                	mv	s5,a2
    80003cb2:	84b6                	mv	s1,a3
    80003cb4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cb6:	9f35                	addw	a4,a4,a3
    return 0;
    80003cb8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cba:	0ad76063          	bltu	a4,a3,80003d5a <readi+0xd2>
  if(off + n > ip->size)
    80003cbe:	00e7f463          	bgeu	a5,a4,80003cc6 <readi+0x3e>
    n = ip->size - off;
    80003cc2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cc6:	0a0b0963          	beqz	s6,80003d78 <readi+0xf0>
    80003cca:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ccc:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cd0:	5cfd                	li	s9,-1
    80003cd2:	a82d                	j	80003d0c <readi+0x84>
    80003cd4:	020a1d93          	slli	s11,s4,0x20
    80003cd8:	020ddd93          	srli	s11,s11,0x20
    80003cdc:	05890613          	addi	a2,s2,88
    80003ce0:	86ee                	mv	a3,s11
    80003ce2:	963a                	add	a2,a2,a4
    80003ce4:	85d6                	mv	a1,s5
    80003ce6:	8562                	mv	a0,s8
    80003ce8:	fffff097          	auipc	ra,0xfffff
    80003cec:	9c2080e7          	jalr	-1598(ra) # 800026aa <either_copyout>
    80003cf0:	05950d63          	beq	a0,s9,80003d4a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003cf4:	854a                	mv	a0,s2
    80003cf6:	fffff097          	auipc	ra,0xfffff
    80003cfa:	60c080e7          	jalr	1548(ra) # 80003302 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cfe:	013a09bb          	addw	s3,s4,s3
    80003d02:	009a04bb          	addw	s1,s4,s1
    80003d06:	9aee                	add	s5,s5,s11
    80003d08:	0569f763          	bgeu	s3,s6,80003d56 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d0c:	000ba903          	lw	s2,0(s7)
    80003d10:	00a4d59b          	srliw	a1,s1,0xa
    80003d14:	855e                	mv	a0,s7
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	8b0080e7          	jalr	-1872(ra) # 800035c6 <bmap>
    80003d1e:	0005059b          	sext.w	a1,a0
    80003d22:	854a                	mv	a0,s2
    80003d24:	fffff097          	auipc	ra,0xfffff
    80003d28:	4ae080e7          	jalr	1198(ra) # 800031d2 <bread>
    80003d2c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d2e:	3ff4f713          	andi	a4,s1,1023
    80003d32:	40ed07bb          	subw	a5,s10,a4
    80003d36:	413b06bb          	subw	a3,s6,s3
    80003d3a:	8a3e                	mv	s4,a5
    80003d3c:	2781                	sext.w	a5,a5
    80003d3e:	0006861b          	sext.w	a2,a3
    80003d42:	f8f679e3          	bgeu	a2,a5,80003cd4 <readi+0x4c>
    80003d46:	8a36                	mv	s4,a3
    80003d48:	b771                	j	80003cd4 <readi+0x4c>
      brelse(bp);
    80003d4a:	854a                	mv	a0,s2
    80003d4c:	fffff097          	auipc	ra,0xfffff
    80003d50:	5b6080e7          	jalr	1462(ra) # 80003302 <brelse>
      tot = -1;
    80003d54:	59fd                	li	s3,-1
  }
  return tot;
    80003d56:	0009851b          	sext.w	a0,s3
}
    80003d5a:	70a6                	ld	ra,104(sp)
    80003d5c:	7406                	ld	s0,96(sp)
    80003d5e:	64e6                	ld	s1,88(sp)
    80003d60:	6946                	ld	s2,80(sp)
    80003d62:	69a6                	ld	s3,72(sp)
    80003d64:	6a06                	ld	s4,64(sp)
    80003d66:	7ae2                	ld	s5,56(sp)
    80003d68:	7b42                	ld	s6,48(sp)
    80003d6a:	7ba2                	ld	s7,40(sp)
    80003d6c:	7c02                	ld	s8,32(sp)
    80003d6e:	6ce2                	ld	s9,24(sp)
    80003d70:	6d42                	ld	s10,16(sp)
    80003d72:	6da2                	ld	s11,8(sp)
    80003d74:	6165                	addi	sp,sp,112
    80003d76:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d78:	89da                	mv	s3,s6
    80003d7a:	bff1                	j	80003d56 <readi+0xce>
    return 0;
    80003d7c:	4501                	li	a0,0
}
    80003d7e:	8082                	ret

0000000080003d80 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d80:	457c                	lw	a5,76(a0)
    80003d82:	10d7e763          	bltu	a5,a3,80003e90 <writei+0x110>
{
    80003d86:	7159                	addi	sp,sp,-112
    80003d88:	f486                	sd	ra,104(sp)
    80003d8a:	f0a2                	sd	s0,96(sp)
    80003d8c:	eca6                	sd	s1,88(sp)
    80003d8e:	e8ca                	sd	s2,80(sp)
    80003d90:	e4ce                	sd	s3,72(sp)
    80003d92:	e0d2                	sd	s4,64(sp)
    80003d94:	fc56                	sd	s5,56(sp)
    80003d96:	f85a                	sd	s6,48(sp)
    80003d98:	f45e                	sd	s7,40(sp)
    80003d9a:	f062                	sd	s8,32(sp)
    80003d9c:	ec66                	sd	s9,24(sp)
    80003d9e:	e86a                	sd	s10,16(sp)
    80003da0:	e46e                	sd	s11,8(sp)
    80003da2:	1880                	addi	s0,sp,112
    80003da4:	8baa                	mv	s7,a0
    80003da6:	8c2e                	mv	s8,a1
    80003da8:	8ab2                	mv	s5,a2
    80003daa:	8936                	mv	s2,a3
    80003dac:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003dae:	00e687bb          	addw	a5,a3,a4
    80003db2:	0ed7e163          	bltu	a5,a3,80003e94 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003db6:	00043737          	lui	a4,0x43
    80003dba:	0cf76f63          	bltu	a4,a5,80003e98 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dbe:	0a0b0863          	beqz	s6,80003e6e <writei+0xee>
    80003dc2:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dc4:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003dc8:	5cfd                	li	s9,-1
    80003dca:	a091                	j	80003e0e <writei+0x8e>
    80003dcc:	02099d93          	slli	s11,s3,0x20
    80003dd0:	020ddd93          	srli	s11,s11,0x20
    80003dd4:	05848513          	addi	a0,s1,88
    80003dd8:	86ee                	mv	a3,s11
    80003dda:	8656                	mv	a2,s5
    80003ddc:	85e2                	mv	a1,s8
    80003dde:	953a                	add	a0,a0,a4
    80003de0:	fffff097          	auipc	ra,0xfffff
    80003de4:	920080e7          	jalr	-1760(ra) # 80002700 <either_copyin>
    80003de8:	07950263          	beq	a0,s9,80003e4c <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003dec:	8526                	mv	a0,s1
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	77c080e7          	jalr	1916(ra) # 8000456a <log_write>
    brelse(bp);
    80003df6:	8526                	mv	a0,s1
    80003df8:	fffff097          	auipc	ra,0xfffff
    80003dfc:	50a080e7          	jalr	1290(ra) # 80003302 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e00:	01498a3b          	addw	s4,s3,s4
    80003e04:	0129893b          	addw	s2,s3,s2
    80003e08:	9aee                	add	s5,s5,s11
    80003e0a:	056a7763          	bgeu	s4,s6,80003e58 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e0e:	000ba483          	lw	s1,0(s7)
    80003e12:	00a9559b          	srliw	a1,s2,0xa
    80003e16:	855e                	mv	a0,s7
    80003e18:	fffff097          	auipc	ra,0xfffff
    80003e1c:	7ae080e7          	jalr	1966(ra) # 800035c6 <bmap>
    80003e20:	0005059b          	sext.w	a1,a0
    80003e24:	8526                	mv	a0,s1
    80003e26:	fffff097          	auipc	ra,0xfffff
    80003e2a:	3ac080e7          	jalr	940(ra) # 800031d2 <bread>
    80003e2e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e30:	3ff97713          	andi	a4,s2,1023
    80003e34:	40ed07bb          	subw	a5,s10,a4
    80003e38:	414b06bb          	subw	a3,s6,s4
    80003e3c:	89be                	mv	s3,a5
    80003e3e:	2781                	sext.w	a5,a5
    80003e40:	0006861b          	sext.w	a2,a3
    80003e44:	f8f674e3          	bgeu	a2,a5,80003dcc <writei+0x4c>
    80003e48:	89b6                	mv	s3,a3
    80003e4a:	b749                	j	80003dcc <writei+0x4c>
      brelse(bp);
    80003e4c:	8526                	mv	a0,s1
    80003e4e:	fffff097          	auipc	ra,0xfffff
    80003e52:	4b4080e7          	jalr	1204(ra) # 80003302 <brelse>
      n = -1;
    80003e56:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003e58:	04cba783          	lw	a5,76(s7)
    80003e5c:	0127f463          	bgeu	a5,s2,80003e64 <writei+0xe4>
      ip->size = off;
    80003e60:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003e64:	855e                	mv	a0,s7
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	aa4080e7          	jalr	-1372(ra) # 8000390a <iupdate>
  }

  return n;
    80003e6e:	000b051b          	sext.w	a0,s6
}
    80003e72:	70a6                	ld	ra,104(sp)
    80003e74:	7406                	ld	s0,96(sp)
    80003e76:	64e6                	ld	s1,88(sp)
    80003e78:	6946                	ld	s2,80(sp)
    80003e7a:	69a6                	ld	s3,72(sp)
    80003e7c:	6a06                	ld	s4,64(sp)
    80003e7e:	7ae2                	ld	s5,56(sp)
    80003e80:	7b42                	ld	s6,48(sp)
    80003e82:	7ba2                	ld	s7,40(sp)
    80003e84:	7c02                	ld	s8,32(sp)
    80003e86:	6ce2                	ld	s9,24(sp)
    80003e88:	6d42                	ld	s10,16(sp)
    80003e8a:	6da2                	ld	s11,8(sp)
    80003e8c:	6165                	addi	sp,sp,112
    80003e8e:	8082                	ret
    return -1;
    80003e90:	557d                	li	a0,-1
}
    80003e92:	8082                	ret
    return -1;
    80003e94:	557d                	li	a0,-1
    80003e96:	bff1                	j	80003e72 <writei+0xf2>
    return -1;
    80003e98:	557d                	li	a0,-1
    80003e9a:	bfe1                	j	80003e72 <writei+0xf2>

0000000080003e9c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e9c:	1141                	addi	sp,sp,-16
    80003e9e:	e406                	sd	ra,8(sp)
    80003ea0:	e022                	sd	s0,0(sp)
    80003ea2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ea4:	4639                	li	a2,14
    80003ea6:	ffffd097          	auipc	ra,0xffffd
    80003eaa:	0b8080e7          	jalr	184(ra) # 80000f5e <strncmp>
}
    80003eae:	60a2                	ld	ra,8(sp)
    80003eb0:	6402                	ld	s0,0(sp)
    80003eb2:	0141                	addi	sp,sp,16
    80003eb4:	8082                	ret

0000000080003eb6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003eb6:	7139                	addi	sp,sp,-64
    80003eb8:	fc06                	sd	ra,56(sp)
    80003eba:	f822                	sd	s0,48(sp)
    80003ebc:	f426                	sd	s1,40(sp)
    80003ebe:	f04a                	sd	s2,32(sp)
    80003ec0:	ec4e                	sd	s3,24(sp)
    80003ec2:	e852                	sd	s4,16(sp)
    80003ec4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ec6:	04451703          	lh	a4,68(a0)
    80003eca:	4785                	li	a5,1
    80003ecc:	00f71a63          	bne	a4,a5,80003ee0 <dirlookup+0x2a>
    80003ed0:	892a                	mv	s2,a0
    80003ed2:	89ae                	mv	s3,a1
    80003ed4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed6:	457c                	lw	a5,76(a0)
    80003ed8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003eda:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003edc:	e79d                	bnez	a5,80003f0a <dirlookup+0x54>
    80003ede:	a8a5                	j	80003f56 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ee0:	00004517          	auipc	a0,0x4
    80003ee4:	7d050513          	addi	a0,a0,2000 # 800086b0 <syscalls+0x1a0>
    80003ee8:	ffffc097          	auipc	ra,0xffffc
    80003eec:	660080e7          	jalr	1632(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003ef0:	00004517          	auipc	a0,0x4
    80003ef4:	7d850513          	addi	a0,a0,2008 # 800086c8 <syscalls+0x1b8>
    80003ef8:	ffffc097          	auipc	ra,0xffffc
    80003efc:	650080e7          	jalr	1616(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f00:	24c1                	addiw	s1,s1,16
    80003f02:	04c92783          	lw	a5,76(s2)
    80003f06:	04f4f763          	bgeu	s1,a5,80003f54 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f0a:	4741                	li	a4,16
    80003f0c:	86a6                	mv	a3,s1
    80003f0e:	fc040613          	addi	a2,s0,-64
    80003f12:	4581                	li	a1,0
    80003f14:	854a                	mv	a0,s2
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	d72080e7          	jalr	-654(ra) # 80003c88 <readi>
    80003f1e:	47c1                	li	a5,16
    80003f20:	fcf518e3          	bne	a0,a5,80003ef0 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f24:	fc045783          	lhu	a5,-64(s0)
    80003f28:	dfe1                	beqz	a5,80003f00 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f2a:	fc240593          	addi	a1,s0,-62
    80003f2e:	854e                	mv	a0,s3
    80003f30:	00000097          	auipc	ra,0x0
    80003f34:	f6c080e7          	jalr	-148(ra) # 80003e9c <namecmp>
    80003f38:	f561                	bnez	a0,80003f00 <dirlookup+0x4a>
      if(poff)
    80003f3a:	000a0463          	beqz	s4,80003f42 <dirlookup+0x8c>
        *poff = off;
    80003f3e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f42:	fc045583          	lhu	a1,-64(s0)
    80003f46:	00092503          	lw	a0,0(s2)
    80003f4a:	fffff097          	auipc	ra,0xfffff
    80003f4e:	756080e7          	jalr	1878(ra) # 800036a0 <iget>
    80003f52:	a011                	j	80003f56 <dirlookup+0xa0>
  return 0;
    80003f54:	4501                	li	a0,0
}
    80003f56:	70e2                	ld	ra,56(sp)
    80003f58:	7442                	ld	s0,48(sp)
    80003f5a:	74a2                	ld	s1,40(sp)
    80003f5c:	7902                	ld	s2,32(sp)
    80003f5e:	69e2                	ld	s3,24(sp)
    80003f60:	6a42                	ld	s4,16(sp)
    80003f62:	6121                	addi	sp,sp,64
    80003f64:	8082                	ret

0000000080003f66 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f66:	711d                	addi	sp,sp,-96
    80003f68:	ec86                	sd	ra,88(sp)
    80003f6a:	e8a2                	sd	s0,80(sp)
    80003f6c:	e4a6                	sd	s1,72(sp)
    80003f6e:	e0ca                	sd	s2,64(sp)
    80003f70:	fc4e                	sd	s3,56(sp)
    80003f72:	f852                	sd	s4,48(sp)
    80003f74:	f456                	sd	s5,40(sp)
    80003f76:	f05a                	sd	s6,32(sp)
    80003f78:	ec5e                	sd	s7,24(sp)
    80003f7a:	e862                	sd	s8,16(sp)
    80003f7c:	e466                	sd	s9,8(sp)
    80003f7e:	1080                	addi	s0,sp,96
    80003f80:	84aa                	mv	s1,a0
    80003f82:	8b2e                	mv	s6,a1
    80003f84:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f86:	00054703          	lbu	a4,0(a0)
    80003f8a:	02f00793          	li	a5,47
    80003f8e:	02f70363          	beq	a4,a5,80003fb4 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f92:	ffffe097          	auipc	ra,0xffffe
    80003f96:	ca6080e7          	jalr	-858(ra) # 80001c38 <myproc>
    80003f9a:	15053503          	ld	a0,336(a0)
    80003f9e:	00000097          	auipc	ra,0x0
    80003fa2:	9f8080e7          	jalr	-1544(ra) # 80003996 <idup>
    80003fa6:	89aa                	mv	s3,a0
  while(*path == '/')
    80003fa8:	02f00913          	li	s2,47
  len = path - s;
    80003fac:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003fae:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fb0:	4c05                	li	s8,1
    80003fb2:	a865                	j	8000406a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003fb4:	4585                	li	a1,1
    80003fb6:	4505                	li	a0,1
    80003fb8:	fffff097          	auipc	ra,0xfffff
    80003fbc:	6e8080e7          	jalr	1768(ra) # 800036a0 <iget>
    80003fc0:	89aa                	mv	s3,a0
    80003fc2:	b7dd                	j	80003fa8 <namex+0x42>
      iunlockput(ip);
    80003fc4:	854e                	mv	a0,s3
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	c70080e7          	jalr	-912(ra) # 80003c36 <iunlockput>
      return 0;
    80003fce:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fd0:	854e                	mv	a0,s3
    80003fd2:	60e6                	ld	ra,88(sp)
    80003fd4:	6446                	ld	s0,80(sp)
    80003fd6:	64a6                	ld	s1,72(sp)
    80003fd8:	6906                	ld	s2,64(sp)
    80003fda:	79e2                	ld	s3,56(sp)
    80003fdc:	7a42                	ld	s4,48(sp)
    80003fde:	7aa2                	ld	s5,40(sp)
    80003fe0:	7b02                	ld	s6,32(sp)
    80003fe2:	6be2                	ld	s7,24(sp)
    80003fe4:	6c42                	ld	s8,16(sp)
    80003fe6:	6ca2                	ld	s9,8(sp)
    80003fe8:	6125                	addi	sp,sp,96
    80003fea:	8082                	ret
      iunlock(ip);
    80003fec:	854e                	mv	a0,s3
    80003fee:	00000097          	auipc	ra,0x0
    80003ff2:	aa8080e7          	jalr	-1368(ra) # 80003a96 <iunlock>
      return ip;
    80003ff6:	bfe9                	j	80003fd0 <namex+0x6a>
      iunlockput(ip);
    80003ff8:	854e                	mv	a0,s3
    80003ffa:	00000097          	auipc	ra,0x0
    80003ffe:	c3c080e7          	jalr	-964(ra) # 80003c36 <iunlockput>
      return 0;
    80004002:	89d2                	mv	s3,s4
    80004004:	b7f1                	j	80003fd0 <namex+0x6a>
  len = path - s;
    80004006:	40b48633          	sub	a2,s1,a1
    8000400a:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000400e:	094cd463          	bge	s9,s4,80004096 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004012:	4639                	li	a2,14
    80004014:	8556                	mv	a0,s5
    80004016:	ffffd097          	auipc	ra,0xffffd
    8000401a:	ecc080e7          	jalr	-308(ra) # 80000ee2 <memmove>
  while(*path == '/')
    8000401e:	0004c783          	lbu	a5,0(s1)
    80004022:	01279763          	bne	a5,s2,80004030 <namex+0xca>
    path++;
    80004026:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004028:	0004c783          	lbu	a5,0(s1)
    8000402c:	ff278de3          	beq	a5,s2,80004026 <namex+0xc0>
    ilock(ip);
    80004030:	854e                	mv	a0,s3
    80004032:	00000097          	auipc	ra,0x0
    80004036:	9a2080e7          	jalr	-1630(ra) # 800039d4 <ilock>
    if(ip->type != T_DIR){
    8000403a:	04499783          	lh	a5,68(s3)
    8000403e:	f98793e3          	bne	a5,s8,80003fc4 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004042:	000b0563          	beqz	s6,8000404c <namex+0xe6>
    80004046:	0004c783          	lbu	a5,0(s1)
    8000404a:	d3cd                	beqz	a5,80003fec <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000404c:	865e                	mv	a2,s7
    8000404e:	85d6                	mv	a1,s5
    80004050:	854e                	mv	a0,s3
    80004052:	00000097          	auipc	ra,0x0
    80004056:	e64080e7          	jalr	-412(ra) # 80003eb6 <dirlookup>
    8000405a:	8a2a                	mv	s4,a0
    8000405c:	dd51                	beqz	a0,80003ff8 <namex+0x92>
    iunlockput(ip);
    8000405e:	854e                	mv	a0,s3
    80004060:	00000097          	auipc	ra,0x0
    80004064:	bd6080e7          	jalr	-1066(ra) # 80003c36 <iunlockput>
    ip = next;
    80004068:	89d2                	mv	s3,s4
  while(*path == '/')
    8000406a:	0004c783          	lbu	a5,0(s1)
    8000406e:	05279763          	bne	a5,s2,800040bc <namex+0x156>
    path++;
    80004072:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004074:	0004c783          	lbu	a5,0(s1)
    80004078:	ff278de3          	beq	a5,s2,80004072 <namex+0x10c>
  if(*path == 0)
    8000407c:	c79d                	beqz	a5,800040aa <namex+0x144>
    path++;
    8000407e:	85a6                	mv	a1,s1
  len = path - s;
    80004080:	8a5e                	mv	s4,s7
    80004082:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004084:	01278963          	beq	a5,s2,80004096 <namex+0x130>
    80004088:	dfbd                	beqz	a5,80004006 <namex+0xa0>
    path++;
    8000408a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000408c:	0004c783          	lbu	a5,0(s1)
    80004090:	ff279ce3          	bne	a5,s2,80004088 <namex+0x122>
    80004094:	bf8d                	j	80004006 <namex+0xa0>
    memmove(name, s, len);
    80004096:	2601                	sext.w	a2,a2
    80004098:	8556                	mv	a0,s5
    8000409a:	ffffd097          	auipc	ra,0xffffd
    8000409e:	e48080e7          	jalr	-440(ra) # 80000ee2 <memmove>
    name[len] = 0;
    800040a2:	9a56                	add	s4,s4,s5
    800040a4:	000a0023          	sb	zero,0(s4)
    800040a8:	bf9d                	j	8000401e <namex+0xb8>
  if(nameiparent){
    800040aa:	f20b03e3          	beqz	s6,80003fd0 <namex+0x6a>
    iput(ip);
    800040ae:	854e                	mv	a0,s3
    800040b0:	00000097          	auipc	ra,0x0
    800040b4:	ade080e7          	jalr	-1314(ra) # 80003b8e <iput>
    return 0;
    800040b8:	4981                	li	s3,0
    800040ba:	bf19                	j	80003fd0 <namex+0x6a>
  if(*path == 0)
    800040bc:	d7fd                	beqz	a5,800040aa <namex+0x144>
  while(*path != '/' && *path != 0)
    800040be:	0004c783          	lbu	a5,0(s1)
    800040c2:	85a6                	mv	a1,s1
    800040c4:	b7d1                	j	80004088 <namex+0x122>

00000000800040c6 <dirlink>:
{
    800040c6:	7139                	addi	sp,sp,-64
    800040c8:	fc06                	sd	ra,56(sp)
    800040ca:	f822                	sd	s0,48(sp)
    800040cc:	f426                	sd	s1,40(sp)
    800040ce:	f04a                	sd	s2,32(sp)
    800040d0:	ec4e                	sd	s3,24(sp)
    800040d2:	e852                	sd	s4,16(sp)
    800040d4:	0080                	addi	s0,sp,64
    800040d6:	892a                	mv	s2,a0
    800040d8:	8a2e                	mv	s4,a1
    800040da:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040dc:	4601                	li	a2,0
    800040de:	00000097          	auipc	ra,0x0
    800040e2:	dd8080e7          	jalr	-552(ra) # 80003eb6 <dirlookup>
    800040e6:	e93d                	bnez	a0,8000415c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040e8:	04c92483          	lw	s1,76(s2)
    800040ec:	c49d                	beqz	s1,8000411a <dirlink+0x54>
    800040ee:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040f0:	4741                	li	a4,16
    800040f2:	86a6                	mv	a3,s1
    800040f4:	fc040613          	addi	a2,s0,-64
    800040f8:	4581                	li	a1,0
    800040fa:	854a                	mv	a0,s2
    800040fc:	00000097          	auipc	ra,0x0
    80004100:	b8c080e7          	jalr	-1140(ra) # 80003c88 <readi>
    80004104:	47c1                	li	a5,16
    80004106:	06f51163          	bne	a0,a5,80004168 <dirlink+0xa2>
    if(de.inum == 0)
    8000410a:	fc045783          	lhu	a5,-64(s0)
    8000410e:	c791                	beqz	a5,8000411a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004110:	24c1                	addiw	s1,s1,16
    80004112:	04c92783          	lw	a5,76(s2)
    80004116:	fcf4ede3          	bltu	s1,a5,800040f0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000411a:	4639                	li	a2,14
    8000411c:	85d2                	mv	a1,s4
    8000411e:	fc240513          	addi	a0,s0,-62
    80004122:	ffffd097          	auipc	ra,0xffffd
    80004126:	e78080e7          	jalr	-392(ra) # 80000f9a <strncpy>
  de.inum = inum;
    8000412a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000412e:	4741                	li	a4,16
    80004130:	86a6                	mv	a3,s1
    80004132:	fc040613          	addi	a2,s0,-64
    80004136:	4581                	li	a1,0
    80004138:	854a                	mv	a0,s2
    8000413a:	00000097          	auipc	ra,0x0
    8000413e:	c46080e7          	jalr	-954(ra) # 80003d80 <writei>
    80004142:	872a                	mv	a4,a0
    80004144:	47c1                	li	a5,16
  return 0;
    80004146:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004148:	02f71863          	bne	a4,a5,80004178 <dirlink+0xb2>
}
    8000414c:	70e2                	ld	ra,56(sp)
    8000414e:	7442                	ld	s0,48(sp)
    80004150:	74a2                	ld	s1,40(sp)
    80004152:	7902                	ld	s2,32(sp)
    80004154:	69e2                	ld	s3,24(sp)
    80004156:	6a42                	ld	s4,16(sp)
    80004158:	6121                	addi	sp,sp,64
    8000415a:	8082                	ret
    iput(ip);
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	a32080e7          	jalr	-1486(ra) # 80003b8e <iput>
    return -1;
    80004164:	557d                	li	a0,-1
    80004166:	b7dd                	j	8000414c <dirlink+0x86>
      panic("dirlink read");
    80004168:	00004517          	auipc	a0,0x4
    8000416c:	57050513          	addi	a0,a0,1392 # 800086d8 <syscalls+0x1c8>
    80004170:	ffffc097          	auipc	ra,0xffffc
    80004174:	3d8080e7          	jalr	984(ra) # 80000548 <panic>
    panic("dirlink");
    80004178:	00004517          	auipc	a0,0x4
    8000417c:	68050513          	addi	a0,a0,1664 # 800087f8 <syscalls+0x2e8>
    80004180:	ffffc097          	auipc	ra,0xffffc
    80004184:	3c8080e7          	jalr	968(ra) # 80000548 <panic>

0000000080004188 <namei>:

struct inode*
namei(char *path)
{
    80004188:	1101                	addi	sp,sp,-32
    8000418a:	ec06                	sd	ra,24(sp)
    8000418c:	e822                	sd	s0,16(sp)
    8000418e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004190:	fe040613          	addi	a2,s0,-32
    80004194:	4581                	li	a1,0
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	dd0080e7          	jalr	-560(ra) # 80003f66 <namex>
}
    8000419e:	60e2                	ld	ra,24(sp)
    800041a0:	6442                	ld	s0,16(sp)
    800041a2:	6105                	addi	sp,sp,32
    800041a4:	8082                	ret

00000000800041a6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041a6:	1141                	addi	sp,sp,-16
    800041a8:	e406                	sd	ra,8(sp)
    800041aa:	e022                	sd	s0,0(sp)
    800041ac:	0800                	addi	s0,sp,16
    800041ae:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041b0:	4585                	li	a1,1
    800041b2:	00000097          	auipc	ra,0x0
    800041b6:	db4080e7          	jalr	-588(ra) # 80003f66 <namex>
}
    800041ba:	60a2                	ld	ra,8(sp)
    800041bc:	6402                	ld	s0,0(sp)
    800041be:	0141                	addi	sp,sp,16
    800041c0:	8082                	ret

00000000800041c2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041c2:	1101                	addi	sp,sp,-32
    800041c4:	ec06                	sd	ra,24(sp)
    800041c6:	e822                	sd	s0,16(sp)
    800041c8:	e426                	sd	s1,8(sp)
    800041ca:	e04a                	sd	s2,0(sp)
    800041cc:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041ce:	0001d917          	auipc	s2,0x1d
    800041d2:	75a90913          	addi	s2,s2,1882 # 80021928 <log>
    800041d6:	01892583          	lw	a1,24(s2)
    800041da:	02892503          	lw	a0,40(s2)
    800041de:	fffff097          	auipc	ra,0xfffff
    800041e2:	ff4080e7          	jalr	-12(ra) # 800031d2 <bread>
    800041e6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041e8:	02c92683          	lw	a3,44(s2)
    800041ec:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041ee:	02d05763          	blez	a3,8000421c <write_head+0x5a>
    800041f2:	0001d797          	auipc	a5,0x1d
    800041f6:	76678793          	addi	a5,a5,1894 # 80021958 <log+0x30>
    800041fa:	05c50713          	addi	a4,a0,92
    800041fe:	36fd                	addiw	a3,a3,-1
    80004200:	1682                	slli	a3,a3,0x20
    80004202:	9281                	srli	a3,a3,0x20
    80004204:	068a                	slli	a3,a3,0x2
    80004206:	0001d617          	auipc	a2,0x1d
    8000420a:	75660613          	addi	a2,a2,1878 # 8002195c <log+0x34>
    8000420e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004210:	4390                	lw	a2,0(a5)
    80004212:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004214:	0791                	addi	a5,a5,4
    80004216:	0711                	addi	a4,a4,4
    80004218:	fed79ce3          	bne	a5,a3,80004210 <write_head+0x4e>
  }
  bwrite(buf);
    8000421c:	8526                	mv	a0,s1
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	0a6080e7          	jalr	166(ra) # 800032c4 <bwrite>
  brelse(buf);
    80004226:	8526                	mv	a0,s1
    80004228:	fffff097          	auipc	ra,0xfffff
    8000422c:	0da080e7          	jalr	218(ra) # 80003302 <brelse>
}
    80004230:	60e2                	ld	ra,24(sp)
    80004232:	6442                	ld	s0,16(sp)
    80004234:	64a2                	ld	s1,8(sp)
    80004236:	6902                	ld	s2,0(sp)
    80004238:	6105                	addi	sp,sp,32
    8000423a:	8082                	ret

000000008000423c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000423c:	0001d797          	auipc	a5,0x1d
    80004240:	7187a783          	lw	a5,1816(a5) # 80021954 <log+0x2c>
    80004244:	0af05663          	blez	a5,800042f0 <install_trans+0xb4>
{
    80004248:	7139                	addi	sp,sp,-64
    8000424a:	fc06                	sd	ra,56(sp)
    8000424c:	f822                	sd	s0,48(sp)
    8000424e:	f426                	sd	s1,40(sp)
    80004250:	f04a                	sd	s2,32(sp)
    80004252:	ec4e                	sd	s3,24(sp)
    80004254:	e852                	sd	s4,16(sp)
    80004256:	e456                	sd	s5,8(sp)
    80004258:	0080                	addi	s0,sp,64
    8000425a:	0001da97          	auipc	s5,0x1d
    8000425e:	6fea8a93          	addi	s5,s5,1790 # 80021958 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004262:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004264:	0001d997          	auipc	s3,0x1d
    80004268:	6c498993          	addi	s3,s3,1732 # 80021928 <log>
    8000426c:	0189a583          	lw	a1,24(s3)
    80004270:	014585bb          	addw	a1,a1,s4
    80004274:	2585                	addiw	a1,a1,1
    80004276:	0289a503          	lw	a0,40(s3)
    8000427a:	fffff097          	auipc	ra,0xfffff
    8000427e:	f58080e7          	jalr	-168(ra) # 800031d2 <bread>
    80004282:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004284:	000aa583          	lw	a1,0(s5)
    80004288:	0289a503          	lw	a0,40(s3)
    8000428c:	fffff097          	auipc	ra,0xfffff
    80004290:	f46080e7          	jalr	-186(ra) # 800031d2 <bread>
    80004294:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004296:	40000613          	li	a2,1024
    8000429a:	05890593          	addi	a1,s2,88
    8000429e:	05850513          	addi	a0,a0,88
    800042a2:	ffffd097          	auipc	ra,0xffffd
    800042a6:	c40080e7          	jalr	-960(ra) # 80000ee2 <memmove>
    bwrite(dbuf);  // write dst to disk
    800042aa:	8526                	mv	a0,s1
    800042ac:	fffff097          	auipc	ra,0xfffff
    800042b0:	018080e7          	jalr	24(ra) # 800032c4 <bwrite>
    bunpin(dbuf);
    800042b4:	8526                	mv	a0,s1
    800042b6:	fffff097          	auipc	ra,0xfffff
    800042ba:	126080e7          	jalr	294(ra) # 800033dc <bunpin>
    brelse(lbuf);
    800042be:	854a                	mv	a0,s2
    800042c0:	fffff097          	auipc	ra,0xfffff
    800042c4:	042080e7          	jalr	66(ra) # 80003302 <brelse>
    brelse(dbuf);
    800042c8:	8526                	mv	a0,s1
    800042ca:	fffff097          	auipc	ra,0xfffff
    800042ce:	038080e7          	jalr	56(ra) # 80003302 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042d2:	2a05                	addiw	s4,s4,1
    800042d4:	0a91                	addi	s5,s5,4
    800042d6:	02c9a783          	lw	a5,44(s3)
    800042da:	f8fa49e3          	blt	s4,a5,8000426c <install_trans+0x30>
}
    800042de:	70e2                	ld	ra,56(sp)
    800042e0:	7442                	ld	s0,48(sp)
    800042e2:	74a2                	ld	s1,40(sp)
    800042e4:	7902                	ld	s2,32(sp)
    800042e6:	69e2                	ld	s3,24(sp)
    800042e8:	6a42                	ld	s4,16(sp)
    800042ea:	6aa2                	ld	s5,8(sp)
    800042ec:	6121                	addi	sp,sp,64
    800042ee:	8082                	ret
    800042f0:	8082                	ret

00000000800042f2 <initlog>:
{
    800042f2:	7179                	addi	sp,sp,-48
    800042f4:	f406                	sd	ra,40(sp)
    800042f6:	f022                	sd	s0,32(sp)
    800042f8:	ec26                	sd	s1,24(sp)
    800042fa:	e84a                	sd	s2,16(sp)
    800042fc:	e44e                	sd	s3,8(sp)
    800042fe:	1800                	addi	s0,sp,48
    80004300:	892a                	mv	s2,a0
    80004302:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004304:	0001d497          	auipc	s1,0x1d
    80004308:	62448493          	addi	s1,s1,1572 # 80021928 <log>
    8000430c:	00004597          	auipc	a1,0x4
    80004310:	3dc58593          	addi	a1,a1,988 # 800086e8 <syscalls+0x1d8>
    80004314:	8526                	mv	a0,s1
    80004316:	ffffd097          	auipc	ra,0xffffd
    8000431a:	9e0080e7          	jalr	-1568(ra) # 80000cf6 <initlock>
  log.start = sb->logstart;
    8000431e:	0149a583          	lw	a1,20(s3)
    80004322:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004324:	0109a783          	lw	a5,16(s3)
    80004328:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000432a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000432e:	854a                	mv	a0,s2
    80004330:	fffff097          	auipc	ra,0xfffff
    80004334:	ea2080e7          	jalr	-350(ra) # 800031d2 <bread>
  log.lh.n = lh->n;
    80004338:	4d3c                	lw	a5,88(a0)
    8000433a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000433c:	02f05563          	blez	a5,80004366 <initlog+0x74>
    80004340:	05c50713          	addi	a4,a0,92
    80004344:	0001d697          	auipc	a3,0x1d
    80004348:	61468693          	addi	a3,a3,1556 # 80021958 <log+0x30>
    8000434c:	37fd                	addiw	a5,a5,-1
    8000434e:	1782                	slli	a5,a5,0x20
    80004350:	9381                	srli	a5,a5,0x20
    80004352:	078a                	slli	a5,a5,0x2
    80004354:	06050613          	addi	a2,a0,96
    80004358:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000435a:	4310                	lw	a2,0(a4)
    8000435c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000435e:	0711                	addi	a4,a4,4
    80004360:	0691                	addi	a3,a3,4
    80004362:	fef71ce3          	bne	a4,a5,8000435a <initlog+0x68>
  brelse(buf);
    80004366:	fffff097          	auipc	ra,0xfffff
    8000436a:	f9c080e7          	jalr	-100(ra) # 80003302 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000436e:	00000097          	auipc	ra,0x0
    80004372:	ece080e7          	jalr	-306(ra) # 8000423c <install_trans>
  log.lh.n = 0;
    80004376:	0001d797          	auipc	a5,0x1d
    8000437a:	5c07af23          	sw	zero,1502(a5) # 80021954 <log+0x2c>
  write_head(); // clear the log
    8000437e:	00000097          	auipc	ra,0x0
    80004382:	e44080e7          	jalr	-444(ra) # 800041c2 <write_head>
}
    80004386:	70a2                	ld	ra,40(sp)
    80004388:	7402                	ld	s0,32(sp)
    8000438a:	64e2                	ld	s1,24(sp)
    8000438c:	6942                	ld	s2,16(sp)
    8000438e:	69a2                	ld	s3,8(sp)
    80004390:	6145                	addi	sp,sp,48
    80004392:	8082                	ret

0000000080004394 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004394:	1101                	addi	sp,sp,-32
    80004396:	ec06                	sd	ra,24(sp)
    80004398:	e822                	sd	s0,16(sp)
    8000439a:	e426                	sd	s1,8(sp)
    8000439c:	e04a                	sd	s2,0(sp)
    8000439e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043a0:	0001d517          	auipc	a0,0x1d
    800043a4:	58850513          	addi	a0,a0,1416 # 80021928 <log>
    800043a8:	ffffd097          	auipc	ra,0xffffd
    800043ac:	9de080e7          	jalr	-1570(ra) # 80000d86 <acquire>
  while(1){
    if(log.committing){
    800043b0:	0001d497          	auipc	s1,0x1d
    800043b4:	57848493          	addi	s1,s1,1400 # 80021928 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043b8:	4979                	li	s2,30
    800043ba:	a039                	j	800043c8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800043bc:	85a6                	mv	a1,s1
    800043be:	8526                	mv	a0,s1
    800043c0:	ffffe097          	auipc	ra,0xffffe
    800043c4:	088080e7          	jalr	136(ra) # 80002448 <sleep>
    if(log.committing){
    800043c8:	50dc                	lw	a5,36(s1)
    800043ca:	fbed                	bnez	a5,800043bc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043cc:	509c                	lw	a5,32(s1)
    800043ce:	0017871b          	addiw	a4,a5,1
    800043d2:	0007069b          	sext.w	a3,a4
    800043d6:	0027179b          	slliw	a5,a4,0x2
    800043da:	9fb9                	addw	a5,a5,a4
    800043dc:	0017979b          	slliw	a5,a5,0x1
    800043e0:	54d8                	lw	a4,44(s1)
    800043e2:	9fb9                	addw	a5,a5,a4
    800043e4:	00f95963          	bge	s2,a5,800043f6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043e8:	85a6                	mv	a1,s1
    800043ea:	8526                	mv	a0,s1
    800043ec:	ffffe097          	auipc	ra,0xffffe
    800043f0:	05c080e7          	jalr	92(ra) # 80002448 <sleep>
    800043f4:	bfd1                	j	800043c8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043f6:	0001d517          	auipc	a0,0x1d
    800043fa:	53250513          	addi	a0,a0,1330 # 80021928 <log>
    800043fe:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004400:	ffffd097          	auipc	ra,0xffffd
    80004404:	a3a080e7          	jalr	-1478(ra) # 80000e3a <release>
      break;
    }
  }
}
    80004408:	60e2                	ld	ra,24(sp)
    8000440a:	6442                	ld	s0,16(sp)
    8000440c:	64a2                	ld	s1,8(sp)
    8000440e:	6902                	ld	s2,0(sp)
    80004410:	6105                	addi	sp,sp,32
    80004412:	8082                	ret

0000000080004414 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004414:	7139                	addi	sp,sp,-64
    80004416:	fc06                	sd	ra,56(sp)
    80004418:	f822                	sd	s0,48(sp)
    8000441a:	f426                	sd	s1,40(sp)
    8000441c:	f04a                	sd	s2,32(sp)
    8000441e:	ec4e                	sd	s3,24(sp)
    80004420:	e852                	sd	s4,16(sp)
    80004422:	e456                	sd	s5,8(sp)
    80004424:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004426:	0001d497          	auipc	s1,0x1d
    8000442a:	50248493          	addi	s1,s1,1282 # 80021928 <log>
    8000442e:	8526                	mv	a0,s1
    80004430:	ffffd097          	auipc	ra,0xffffd
    80004434:	956080e7          	jalr	-1706(ra) # 80000d86 <acquire>
  log.outstanding -= 1;
    80004438:	509c                	lw	a5,32(s1)
    8000443a:	37fd                	addiw	a5,a5,-1
    8000443c:	0007891b          	sext.w	s2,a5
    80004440:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004442:	50dc                	lw	a5,36(s1)
    80004444:	efb9                	bnez	a5,800044a2 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004446:	06091663          	bnez	s2,800044b2 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000444a:	0001d497          	auipc	s1,0x1d
    8000444e:	4de48493          	addi	s1,s1,1246 # 80021928 <log>
    80004452:	4785                	li	a5,1
    80004454:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004456:	8526                	mv	a0,s1
    80004458:	ffffd097          	auipc	ra,0xffffd
    8000445c:	9e2080e7          	jalr	-1566(ra) # 80000e3a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004460:	54dc                	lw	a5,44(s1)
    80004462:	06f04763          	bgtz	a5,800044d0 <end_op+0xbc>
    acquire(&log.lock);
    80004466:	0001d497          	auipc	s1,0x1d
    8000446a:	4c248493          	addi	s1,s1,1218 # 80021928 <log>
    8000446e:	8526                	mv	a0,s1
    80004470:	ffffd097          	auipc	ra,0xffffd
    80004474:	916080e7          	jalr	-1770(ra) # 80000d86 <acquire>
    log.committing = 0;
    80004478:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000447c:	8526                	mv	a0,s1
    8000447e:	ffffe097          	auipc	ra,0xffffe
    80004482:	150080e7          	jalr	336(ra) # 800025ce <wakeup>
    release(&log.lock);
    80004486:	8526                	mv	a0,s1
    80004488:	ffffd097          	auipc	ra,0xffffd
    8000448c:	9b2080e7          	jalr	-1614(ra) # 80000e3a <release>
}
    80004490:	70e2                	ld	ra,56(sp)
    80004492:	7442                	ld	s0,48(sp)
    80004494:	74a2                	ld	s1,40(sp)
    80004496:	7902                	ld	s2,32(sp)
    80004498:	69e2                	ld	s3,24(sp)
    8000449a:	6a42                	ld	s4,16(sp)
    8000449c:	6aa2                	ld	s5,8(sp)
    8000449e:	6121                	addi	sp,sp,64
    800044a0:	8082                	ret
    panic("log.committing");
    800044a2:	00004517          	auipc	a0,0x4
    800044a6:	24e50513          	addi	a0,a0,590 # 800086f0 <syscalls+0x1e0>
    800044aa:	ffffc097          	auipc	ra,0xffffc
    800044ae:	09e080e7          	jalr	158(ra) # 80000548 <panic>
    wakeup(&log);
    800044b2:	0001d497          	auipc	s1,0x1d
    800044b6:	47648493          	addi	s1,s1,1142 # 80021928 <log>
    800044ba:	8526                	mv	a0,s1
    800044bc:	ffffe097          	auipc	ra,0xffffe
    800044c0:	112080e7          	jalr	274(ra) # 800025ce <wakeup>
  release(&log.lock);
    800044c4:	8526                	mv	a0,s1
    800044c6:	ffffd097          	auipc	ra,0xffffd
    800044ca:	974080e7          	jalr	-1676(ra) # 80000e3a <release>
  if(do_commit){
    800044ce:	b7c9                	j	80004490 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044d0:	0001da97          	auipc	s5,0x1d
    800044d4:	488a8a93          	addi	s5,s5,1160 # 80021958 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044d8:	0001da17          	auipc	s4,0x1d
    800044dc:	450a0a13          	addi	s4,s4,1104 # 80021928 <log>
    800044e0:	018a2583          	lw	a1,24(s4)
    800044e4:	012585bb          	addw	a1,a1,s2
    800044e8:	2585                	addiw	a1,a1,1
    800044ea:	028a2503          	lw	a0,40(s4)
    800044ee:	fffff097          	auipc	ra,0xfffff
    800044f2:	ce4080e7          	jalr	-796(ra) # 800031d2 <bread>
    800044f6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044f8:	000aa583          	lw	a1,0(s5)
    800044fc:	028a2503          	lw	a0,40(s4)
    80004500:	fffff097          	auipc	ra,0xfffff
    80004504:	cd2080e7          	jalr	-814(ra) # 800031d2 <bread>
    80004508:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000450a:	40000613          	li	a2,1024
    8000450e:	05850593          	addi	a1,a0,88
    80004512:	05848513          	addi	a0,s1,88
    80004516:	ffffd097          	auipc	ra,0xffffd
    8000451a:	9cc080e7          	jalr	-1588(ra) # 80000ee2 <memmove>
    bwrite(to);  // write the log
    8000451e:	8526                	mv	a0,s1
    80004520:	fffff097          	auipc	ra,0xfffff
    80004524:	da4080e7          	jalr	-604(ra) # 800032c4 <bwrite>
    brelse(from);
    80004528:	854e                	mv	a0,s3
    8000452a:	fffff097          	auipc	ra,0xfffff
    8000452e:	dd8080e7          	jalr	-552(ra) # 80003302 <brelse>
    brelse(to);
    80004532:	8526                	mv	a0,s1
    80004534:	fffff097          	auipc	ra,0xfffff
    80004538:	dce080e7          	jalr	-562(ra) # 80003302 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000453c:	2905                	addiw	s2,s2,1
    8000453e:	0a91                	addi	s5,s5,4
    80004540:	02ca2783          	lw	a5,44(s4)
    80004544:	f8f94ee3          	blt	s2,a5,800044e0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	c7a080e7          	jalr	-902(ra) # 800041c2 <write_head>
    install_trans(); // Now install writes to home locations
    80004550:	00000097          	auipc	ra,0x0
    80004554:	cec080e7          	jalr	-788(ra) # 8000423c <install_trans>
    log.lh.n = 0;
    80004558:	0001d797          	auipc	a5,0x1d
    8000455c:	3e07ae23          	sw	zero,1020(a5) # 80021954 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004560:	00000097          	auipc	ra,0x0
    80004564:	c62080e7          	jalr	-926(ra) # 800041c2 <write_head>
    80004568:	bdfd                	j	80004466 <end_op+0x52>

000000008000456a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000456a:	1101                	addi	sp,sp,-32
    8000456c:	ec06                	sd	ra,24(sp)
    8000456e:	e822                	sd	s0,16(sp)
    80004570:	e426                	sd	s1,8(sp)
    80004572:	e04a                	sd	s2,0(sp)
    80004574:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004576:	0001d717          	auipc	a4,0x1d
    8000457a:	3de72703          	lw	a4,990(a4) # 80021954 <log+0x2c>
    8000457e:	47f5                	li	a5,29
    80004580:	08e7c063          	blt	a5,a4,80004600 <log_write+0x96>
    80004584:	84aa                	mv	s1,a0
    80004586:	0001d797          	auipc	a5,0x1d
    8000458a:	3be7a783          	lw	a5,958(a5) # 80021944 <log+0x1c>
    8000458e:	37fd                	addiw	a5,a5,-1
    80004590:	06f75863          	bge	a4,a5,80004600 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004594:	0001d797          	auipc	a5,0x1d
    80004598:	3b47a783          	lw	a5,948(a5) # 80021948 <log+0x20>
    8000459c:	06f05a63          	blez	a5,80004610 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800045a0:	0001d917          	auipc	s2,0x1d
    800045a4:	38890913          	addi	s2,s2,904 # 80021928 <log>
    800045a8:	854a                	mv	a0,s2
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	7dc080e7          	jalr	2012(ra) # 80000d86 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800045b2:	02c92603          	lw	a2,44(s2)
    800045b6:	06c05563          	blez	a2,80004620 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800045ba:	44cc                	lw	a1,12(s1)
    800045bc:	0001d717          	auipc	a4,0x1d
    800045c0:	39c70713          	addi	a4,a4,924 # 80021958 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045c4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800045c6:	4314                	lw	a3,0(a4)
    800045c8:	04b68d63          	beq	a3,a1,80004622 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800045cc:	2785                	addiw	a5,a5,1
    800045ce:	0711                	addi	a4,a4,4
    800045d0:	fec79be3          	bne	a5,a2,800045c6 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045d4:	0621                	addi	a2,a2,8
    800045d6:	060a                	slli	a2,a2,0x2
    800045d8:	0001d797          	auipc	a5,0x1d
    800045dc:	35078793          	addi	a5,a5,848 # 80021928 <log>
    800045e0:	963e                	add	a2,a2,a5
    800045e2:	44dc                	lw	a5,12(s1)
    800045e4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045e6:	8526                	mv	a0,s1
    800045e8:	fffff097          	auipc	ra,0xfffff
    800045ec:	db8080e7          	jalr	-584(ra) # 800033a0 <bpin>
    log.lh.n++;
    800045f0:	0001d717          	auipc	a4,0x1d
    800045f4:	33870713          	addi	a4,a4,824 # 80021928 <log>
    800045f8:	575c                	lw	a5,44(a4)
    800045fa:	2785                	addiw	a5,a5,1
    800045fc:	d75c                	sw	a5,44(a4)
    800045fe:	a83d                	j	8000463c <log_write+0xd2>
    panic("too big a transaction");
    80004600:	00004517          	auipc	a0,0x4
    80004604:	10050513          	addi	a0,a0,256 # 80008700 <syscalls+0x1f0>
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	f40080e7          	jalr	-192(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004610:	00004517          	auipc	a0,0x4
    80004614:	10850513          	addi	a0,a0,264 # 80008718 <syscalls+0x208>
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	f30080e7          	jalr	-208(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004620:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004622:	00878713          	addi	a4,a5,8
    80004626:	00271693          	slli	a3,a4,0x2
    8000462a:	0001d717          	auipc	a4,0x1d
    8000462e:	2fe70713          	addi	a4,a4,766 # 80021928 <log>
    80004632:	9736                	add	a4,a4,a3
    80004634:	44d4                	lw	a3,12(s1)
    80004636:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004638:	faf607e3          	beq	a2,a5,800045e6 <log_write+0x7c>
  }
  release(&log.lock);
    8000463c:	0001d517          	auipc	a0,0x1d
    80004640:	2ec50513          	addi	a0,a0,748 # 80021928 <log>
    80004644:	ffffc097          	auipc	ra,0xffffc
    80004648:	7f6080e7          	jalr	2038(ra) # 80000e3a <release>
}
    8000464c:	60e2                	ld	ra,24(sp)
    8000464e:	6442                	ld	s0,16(sp)
    80004650:	64a2                	ld	s1,8(sp)
    80004652:	6902                	ld	s2,0(sp)
    80004654:	6105                	addi	sp,sp,32
    80004656:	8082                	ret

0000000080004658 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004658:	1101                	addi	sp,sp,-32
    8000465a:	ec06                	sd	ra,24(sp)
    8000465c:	e822                	sd	s0,16(sp)
    8000465e:	e426                	sd	s1,8(sp)
    80004660:	e04a                	sd	s2,0(sp)
    80004662:	1000                	addi	s0,sp,32
    80004664:	84aa                	mv	s1,a0
    80004666:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004668:	00004597          	auipc	a1,0x4
    8000466c:	0d058593          	addi	a1,a1,208 # 80008738 <syscalls+0x228>
    80004670:	0521                	addi	a0,a0,8
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	684080e7          	jalr	1668(ra) # 80000cf6 <initlock>
  lk->name = name;
    8000467a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000467e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004682:	0204a423          	sw	zero,40(s1)
}
    80004686:	60e2                	ld	ra,24(sp)
    80004688:	6442                	ld	s0,16(sp)
    8000468a:	64a2                	ld	s1,8(sp)
    8000468c:	6902                	ld	s2,0(sp)
    8000468e:	6105                	addi	sp,sp,32
    80004690:	8082                	ret

0000000080004692 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004692:	1101                	addi	sp,sp,-32
    80004694:	ec06                	sd	ra,24(sp)
    80004696:	e822                	sd	s0,16(sp)
    80004698:	e426                	sd	s1,8(sp)
    8000469a:	e04a                	sd	s2,0(sp)
    8000469c:	1000                	addi	s0,sp,32
    8000469e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046a0:	00850913          	addi	s2,a0,8
    800046a4:	854a                	mv	a0,s2
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	6e0080e7          	jalr	1760(ra) # 80000d86 <acquire>
  while (lk->locked) {
    800046ae:	409c                	lw	a5,0(s1)
    800046b0:	cb89                	beqz	a5,800046c2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046b2:	85ca                	mv	a1,s2
    800046b4:	8526                	mv	a0,s1
    800046b6:	ffffe097          	auipc	ra,0xffffe
    800046ba:	d92080e7          	jalr	-622(ra) # 80002448 <sleep>
  while (lk->locked) {
    800046be:	409c                	lw	a5,0(s1)
    800046c0:	fbed                	bnez	a5,800046b2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046c2:	4785                	li	a5,1
    800046c4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046c6:	ffffd097          	auipc	ra,0xffffd
    800046ca:	572080e7          	jalr	1394(ra) # 80001c38 <myproc>
    800046ce:	5d1c                	lw	a5,56(a0)
    800046d0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046d2:	854a                	mv	a0,s2
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	766080e7          	jalr	1894(ra) # 80000e3a <release>
}
    800046dc:	60e2                	ld	ra,24(sp)
    800046de:	6442                	ld	s0,16(sp)
    800046e0:	64a2                	ld	s1,8(sp)
    800046e2:	6902                	ld	s2,0(sp)
    800046e4:	6105                	addi	sp,sp,32
    800046e6:	8082                	ret

00000000800046e8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046e8:	1101                	addi	sp,sp,-32
    800046ea:	ec06                	sd	ra,24(sp)
    800046ec:	e822                	sd	s0,16(sp)
    800046ee:	e426                	sd	s1,8(sp)
    800046f0:	e04a                	sd	s2,0(sp)
    800046f2:	1000                	addi	s0,sp,32
    800046f4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046f6:	00850913          	addi	s2,a0,8
    800046fa:	854a                	mv	a0,s2
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	68a080e7          	jalr	1674(ra) # 80000d86 <acquire>
  lk->locked = 0;
    80004704:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004708:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000470c:	8526                	mv	a0,s1
    8000470e:	ffffe097          	auipc	ra,0xffffe
    80004712:	ec0080e7          	jalr	-320(ra) # 800025ce <wakeup>
  release(&lk->lk);
    80004716:	854a                	mv	a0,s2
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	722080e7          	jalr	1826(ra) # 80000e3a <release>
}
    80004720:	60e2                	ld	ra,24(sp)
    80004722:	6442                	ld	s0,16(sp)
    80004724:	64a2                	ld	s1,8(sp)
    80004726:	6902                	ld	s2,0(sp)
    80004728:	6105                	addi	sp,sp,32
    8000472a:	8082                	ret

000000008000472c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000472c:	7179                	addi	sp,sp,-48
    8000472e:	f406                	sd	ra,40(sp)
    80004730:	f022                	sd	s0,32(sp)
    80004732:	ec26                	sd	s1,24(sp)
    80004734:	e84a                	sd	s2,16(sp)
    80004736:	e44e                	sd	s3,8(sp)
    80004738:	1800                	addi	s0,sp,48
    8000473a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000473c:	00850913          	addi	s2,a0,8
    80004740:	854a                	mv	a0,s2
    80004742:	ffffc097          	auipc	ra,0xffffc
    80004746:	644080e7          	jalr	1604(ra) # 80000d86 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000474a:	409c                	lw	a5,0(s1)
    8000474c:	ef99                	bnez	a5,8000476a <holdingsleep+0x3e>
    8000474e:	4481                	li	s1,0
  release(&lk->lk);
    80004750:	854a                	mv	a0,s2
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	6e8080e7          	jalr	1768(ra) # 80000e3a <release>
  return r;
}
    8000475a:	8526                	mv	a0,s1
    8000475c:	70a2                	ld	ra,40(sp)
    8000475e:	7402                	ld	s0,32(sp)
    80004760:	64e2                	ld	s1,24(sp)
    80004762:	6942                	ld	s2,16(sp)
    80004764:	69a2                	ld	s3,8(sp)
    80004766:	6145                	addi	sp,sp,48
    80004768:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000476a:	0284a983          	lw	s3,40(s1)
    8000476e:	ffffd097          	auipc	ra,0xffffd
    80004772:	4ca080e7          	jalr	1226(ra) # 80001c38 <myproc>
    80004776:	5d04                	lw	s1,56(a0)
    80004778:	413484b3          	sub	s1,s1,s3
    8000477c:	0014b493          	seqz	s1,s1
    80004780:	bfc1                	j	80004750 <holdingsleep+0x24>

0000000080004782 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004782:	1141                	addi	sp,sp,-16
    80004784:	e406                	sd	ra,8(sp)
    80004786:	e022                	sd	s0,0(sp)
    80004788:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000478a:	00004597          	auipc	a1,0x4
    8000478e:	fbe58593          	addi	a1,a1,-66 # 80008748 <syscalls+0x238>
    80004792:	0001d517          	auipc	a0,0x1d
    80004796:	2de50513          	addi	a0,a0,734 # 80021a70 <ftable>
    8000479a:	ffffc097          	auipc	ra,0xffffc
    8000479e:	55c080e7          	jalr	1372(ra) # 80000cf6 <initlock>
}
    800047a2:	60a2                	ld	ra,8(sp)
    800047a4:	6402                	ld	s0,0(sp)
    800047a6:	0141                	addi	sp,sp,16
    800047a8:	8082                	ret

00000000800047aa <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047aa:	1101                	addi	sp,sp,-32
    800047ac:	ec06                	sd	ra,24(sp)
    800047ae:	e822                	sd	s0,16(sp)
    800047b0:	e426                	sd	s1,8(sp)
    800047b2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047b4:	0001d517          	auipc	a0,0x1d
    800047b8:	2bc50513          	addi	a0,a0,700 # 80021a70 <ftable>
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	5ca080e7          	jalr	1482(ra) # 80000d86 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047c4:	0001d497          	auipc	s1,0x1d
    800047c8:	2c448493          	addi	s1,s1,708 # 80021a88 <ftable+0x18>
    800047cc:	0001e717          	auipc	a4,0x1e
    800047d0:	25c70713          	addi	a4,a4,604 # 80022a28 <ftable+0xfb8>
    if(f->ref == 0){
    800047d4:	40dc                	lw	a5,4(s1)
    800047d6:	cf99                	beqz	a5,800047f4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047d8:	02848493          	addi	s1,s1,40
    800047dc:	fee49ce3          	bne	s1,a4,800047d4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047e0:	0001d517          	auipc	a0,0x1d
    800047e4:	29050513          	addi	a0,a0,656 # 80021a70 <ftable>
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	652080e7          	jalr	1618(ra) # 80000e3a <release>
  return 0;
    800047f0:	4481                	li	s1,0
    800047f2:	a819                	j	80004808 <filealloc+0x5e>
      f->ref = 1;
    800047f4:	4785                	li	a5,1
    800047f6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047f8:	0001d517          	auipc	a0,0x1d
    800047fc:	27850513          	addi	a0,a0,632 # 80021a70 <ftable>
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	63a080e7          	jalr	1594(ra) # 80000e3a <release>
}
    80004808:	8526                	mv	a0,s1
    8000480a:	60e2                	ld	ra,24(sp)
    8000480c:	6442                	ld	s0,16(sp)
    8000480e:	64a2                	ld	s1,8(sp)
    80004810:	6105                	addi	sp,sp,32
    80004812:	8082                	ret

0000000080004814 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004814:	1101                	addi	sp,sp,-32
    80004816:	ec06                	sd	ra,24(sp)
    80004818:	e822                	sd	s0,16(sp)
    8000481a:	e426                	sd	s1,8(sp)
    8000481c:	1000                	addi	s0,sp,32
    8000481e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004820:	0001d517          	auipc	a0,0x1d
    80004824:	25050513          	addi	a0,a0,592 # 80021a70 <ftable>
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	55e080e7          	jalr	1374(ra) # 80000d86 <acquire>
  if(f->ref < 1)
    80004830:	40dc                	lw	a5,4(s1)
    80004832:	02f05263          	blez	a5,80004856 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004836:	2785                	addiw	a5,a5,1
    80004838:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000483a:	0001d517          	auipc	a0,0x1d
    8000483e:	23650513          	addi	a0,a0,566 # 80021a70 <ftable>
    80004842:	ffffc097          	auipc	ra,0xffffc
    80004846:	5f8080e7          	jalr	1528(ra) # 80000e3a <release>
  return f;
}
    8000484a:	8526                	mv	a0,s1
    8000484c:	60e2                	ld	ra,24(sp)
    8000484e:	6442                	ld	s0,16(sp)
    80004850:	64a2                	ld	s1,8(sp)
    80004852:	6105                	addi	sp,sp,32
    80004854:	8082                	ret
    panic("filedup");
    80004856:	00004517          	auipc	a0,0x4
    8000485a:	efa50513          	addi	a0,a0,-262 # 80008750 <syscalls+0x240>
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	cea080e7          	jalr	-790(ra) # 80000548 <panic>

0000000080004866 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004866:	7139                	addi	sp,sp,-64
    80004868:	fc06                	sd	ra,56(sp)
    8000486a:	f822                	sd	s0,48(sp)
    8000486c:	f426                	sd	s1,40(sp)
    8000486e:	f04a                	sd	s2,32(sp)
    80004870:	ec4e                	sd	s3,24(sp)
    80004872:	e852                	sd	s4,16(sp)
    80004874:	e456                	sd	s5,8(sp)
    80004876:	0080                	addi	s0,sp,64
    80004878:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000487a:	0001d517          	auipc	a0,0x1d
    8000487e:	1f650513          	addi	a0,a0,502 # 80021a70 <ftable>
    80004882:	ffffc097          	auipc	ra,0xffffc
    80004886:	504080e7          	jalr	1284(ra) # 80000d86 <acquire>
  if(f->ref < 1)
    8000488a:	40dc                	lw	a5,4(s1)
    8000488c:	06f05163          	blez	a5,800048ee <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004890:	37fd                	addiw	a5,a5,-1
    80004892:	0007871b          	sext.w	a4,a5
    80004896:	c0dc                	sw	a5,4(s1)
    80004898:	06e04363          	bgtz	a4,800048fe <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000489c:	0004a903          	lw	s2,0(s1)
    800048a0:	0094ca83          	lbu	s5,9(s1)
    800048a4:	0104ba03          	ld	s4,16(s1)
    800048a8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048ac:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048b0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048b4:	0001d517          	auipc	a0,0x1d
    800048b8:	1bc50513          	addi	a0,a0,444 # 80021a70 <ftable>
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	57e080e7          	jalr	1406(ra) # 80000e3a <release>

  if(ff.type == FD_PIPE){
    800048c4:	4785                	li	a5,1
    800048c6:	04f90d63          	beq	s2,a5,80004920 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048ca:	3979                	addiw	s2,s2,-2
    800048cc:	4785                	li	a5,1
    800048ce:	0527e063          	bltu	a5,s2,8000490e <fileclose+0xa8>
    begin_op();
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	ac2080e7          	jalr	-1342(ra) # 80004394 <begin_op>
    iput(ff.ip);
    800048da:	854e                	mv	a0,s3
    800048dc:	fffff097          	auipc	ra,0xfffff
    800048e0:	2b2080e7          	jalr	690(ra) # 80003b8e <iput>
    end_op();
    800048e4:	00000097          	auipc	ra,0x0
    800048e8:	b30080e7          	jalr	-1232(ra) # 80004414 <end_op>
    800048ec:	a00d                	j	8000490e <fileclose+0xa8>
    panic("fileclose");
    800048ee:	00004517          	auipc	a0,0x4
    800048f2:	e6a50513          	addi	a0,a0,-406 # 80008758 <syscalls+0x248>
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	c52080e7          	jalr	-942(ra) # 80000548 <panic>
    release(&ftable.lock);
    800048fe:	0001d517          	auipc	a0,0x1d
    80004902:	17250513          	addi	a0,a0,370 # 80021a70 <ftable>
    80004906:	ffffc097          	auipc	ra,0xffffc
    8000490a:	534080e7          	jalr	1332(ra) # 80000e3a <release>
  }
}
    8000490e:	70e2                	ld	ra,56(sp)
    80004910:	7442                	ld	s0,48(sp)
    80004912:	74a2                	ld	s1,40(sp)
    80004914:	7902                	ld	s2,32(sp)
    80004916:	69e2                	ld	s3,24(sp)
    80004918:	6a42                	ld	s4,16(sp)
    8000491a:	6aa2                	ld	s5,8(sp)
    8000491c:	6121                	addi	sp,sp,64
    8000491e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004920:	85d6                	mv	a1,s5
    80004922:	8552                	mv	a0,s4
    80004924:	00000097          	auipc	ra,0x0
    80004928:	372080e7          	jalr	882(ra) # 80004c96 <pipeclose>
    8000492c:	b7cd                	j	8000490e <fileclose+0xa8>

000000008000492e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000492e:	715d                	addi	sp,sp,-80
    80004930:	e486                	sd	ra,72(sp)
    80004932:	e0a2                	sd	s0,64(sp)
    80004934:	fc26                	sd	s1,56(sp)
    80004936:	f84a                	sd	s2,48(sp)
    80004938:	f44e                	sd	s3,40(sp)
    8000493a:	0880                	addi	s0,sp,80
    8000493c:	84aa                	mv	s1,a0
    8000493e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004940:	ffffd097          	auipc	ra,0xffffd
    80004944:	2f8080e7          	jalr	760(ra) # 80001c38 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004948:	409c                	lw	a5,0(s1)
    8000494a:	37f9                	addiw	a5,a5,-2
    8000494c:	4705                	li	a4,1
    8000494e:	04f76763          	bltu	a4,a5,8000499c <filestat+0x6e>
    80004952:	892a                	mv	s2,a0
    ilock(f->ip);
    80004954:	6c88                	ld	a0,24(s1)
    80004956:	fffff097          	auipc	ra,0xfffff
    8000495a:	07e080e7          	jalr	126(ra) # 800039d4 <ilock>
    stati(f->ip, &st);
    8000495e:	fb840593          	addi	a1,s0,-72
    80004962:	6c88                	ld	a0,24(s1)
    80004964:	fffff097          	auipc	ra,0xfffff
    80004968:	2fa080e7          	jalr	762(ra) # 80003c5e <stati>
    iunlock(f->ip);
    8000496c:	6c88                	ld	a0,24(s1)
    8000496e:	fffff097          	auipc	ra,0xfffff
    80004972:	128080e7          	jalr	296(ra) # 80003a96 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004976:	46e1                	li	a3,24
    80004978:	fb840613          	addi	a2,s0,-72
    8000497c:	85ce                	mv	a1,s3
    8000497e:	05093503          	ld	a0,80(s2)
    80004982:	ffffd097          	auipc	ra,0xffffd
    80004986:	e9e080e7          	jalr	-354(ra) # 80001820 <copyout>
    8000498a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000498e:	60a6                	ld	ra,72(sp)
    80004990:	6406                	ld	s0,64(sp)
    80004992:	74e2                	ld	s1,56(sp)
    80004994:	7942                	ld	s2,48(sp)
    80004996:	79a2                	ld	s3,40(sp)
    80004998:	6161                	addi	sp,sp,80
    8000499a:	8082                	ret
  return -1;
    8000499c:	557d                	li	a0,-1
    8000499e:	bfc5                	j	8000498e <filestat+0x60>

00000000800049a0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049a0:	7179                	addi	sp,sp,-48
    800049a2:	f406                	sd	ra,40(sp)
    800049a4:	f022                	sd	s0,32(sp)
    800049a6:	ec26                	sd	s1,24(sp)
    800049a8:	e84a                	sd	s2,16(sp)
    800049aa:	e44e                	sd	s3,8(sp)
    800049ac:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049ae:	00854783          	lbu	a5,8(a0)
    800049b2:	c3d5                	beqz	a5,80004a56 <fileread+0xb6>
    800049b4:	84aa                	mv	s1,a0
    800049b6:	89ae                	mv	s3,a1
    800049b8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049ba:	411c                	lw	a5,0(a0)
    800049bc:	4705                	li	a4,1
    800049be:	04e78963          	beq	a5,a4,80004a10 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049c2:	470d                	li	a4,3
    800049c4:	04e78d63          	beq	a5,a4,80004a1e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049c8:	4709                	li	a4,2
    800049ca:	06e79e63          	bne	a5,a4,80004a46 <fileread+0xa6>
    ilock(f->ip);
    800049ce:	6d08                	ld	a0,24(a0)
    800049d0:	fffff097          	auipc	ra,0xfffff
    800049d4:	004080e7          	jalr	4(ra) # 800039d4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049d8:	874a                	mv	a4,s2
    800049da:	5094                	lw	a3,32(s1)
    800049dc:	864e                	mv	a2,s3
    800049de:	4585                	li	a1,1
    800049e0:	6c88                	ld	a0,24(s1)
    800049e2:	fffff097          	auipc	ra,0xfffff
    800049e6:	2a6080e7          	jalr	678(ra) # 80003c88 <readi>
    800049ea:	892a                	mv	s2,a0
    800049ec:	00a05563          	blez	a0,800049f6 <fileread+0x56>
      f->off += r;
    800049f0:	509c                	lw	a5,32(s1)
    800049f2:	9fa9                	addw	a5,a5,a0
    800049f4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049f6:	6c88                	ld	a0,24(s1)
    800049f8:	fffff097          	auipc	ra,0xfffff
    800049fc:	09e080e7          	jalr	158(ra) # 80003a96 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a00:	854a                	mv	a0,s2
    80004a02:	70a2                	ld	ra,40(sp)
    80004a04:	7402                	ld	s0,32(sp)
    80004a06:	64e2                	ld	s1,24(sp)
    80004a08:	6942                	ld	s2,16(sp)
    80004a0a:	69a2                	ld	s3,8(sp)
    80004a0c:	6145                	addi	sp,sp,48
    80004a0e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a10:	6908                	ld	a0,16(a0)
    80004a12:	00000097          	auipc	ra,0x0
    80004a16:	418080e7          	jalr	1048(ra) # 80004e2a <piperead>
    80004a1a:	892a                	mv	s2,a0
    80004a1c:	b7d5                	j	80004a00 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a1e:	02451783          	lh	a5,36(a0)
    80004a22:	03079693          	slli	a3,a5,0x30
    80004a26:	92c1                	srli	a3,a3,0x30
    80004a28:	4725                	li	a4,9
    80004a2a:	02d76863          	bltu	a4,a3,80004a5a <fileread+0xba>
    80004a2e:	0792                	slli	a5,a5,0x4
    80004a30:	0001d717          	auipc	a4,0x1d
    80004a34:	fa070713          	addi	a4,a4,-96 # 800219d0 <devsw>
    80004a38:	97ba                	add	a5,a5,a4
    80004a3a:	639c                	ld	a5,0(a5)
    80004a3c:	c38d                	beqz	a5,80004a5e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a3e:	4505                	li	a0,1
    80004a40:	9782                	jalr	a5
    80004a42:	892a                	mv	s2,a0
    80004a44:	bf75                	j	80004a00 <fileread+0x60>
    panic("fileread");
    80004a46:	00004517          	auipc	a0,0x4
    80004a4a:	d2250513          	addi	a0,a0,-734 # 80008768 <syscalls+0x258>
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	afa080e7          	jalr	-1286(ra) # 80000548 <panic>
    return -1;
    80004a56:	597d                	li	s2,-1
    80004a58:	b765                	j	80004a00 <fileread+0x60>
      return -1;
    80004a5a:	597d                	li	s2,-1
    80004a5c:	b755                	j	80004a00 <fileread+0x60>
    80004a5e:	597d                	li	s2,-1
    80004a60:	b745                	j	80004a00 <fileread+0x60>

0000000080004a62 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004a62:	00954783          	lbu	a5,9(a0)
    80004a66:	14078563          	beqz	a5,80004bb0 <filewrite+0x14e>
{
    80004a6a:	715d                	addi	sp,sp,-80
    80004a6c:	e486                	sd	ra,72(sp)
    80004a6e:	e0a2                	sd	s0,64(sp)
    80004a70:	fc26                	sd	s1,56(sp)
    80004a72:	f84a                	sd	s2,48(sp)
    80004a74:	f44e                	sd	s3,40(sp)
    80004a76:	f052                	sd	s4,32(sp)
    80004a78:	ec56                	sd	s5,24(sp)
    80004a7a:	e85a                	sd	s6,16(sp)
    80004a7c:	e45e                	sd	s7,8(sp)
    80004a7e:	e062                	sd	s8,0(sp)
    80004a80:	0880                	addi	s0,sp,80
    80004a82:	892a                	mv	s2,a0
    80004a84:	8aae                	mv	s5,a1
    80004a86:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a88:	411c                	lw	a5,0(a0)
    80004a8a:	4705                	li	a4,1
    80004a8c:	02e78263          	beq	a5,a4,80004ab0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a90:	470d                	li	a4,3
    80004a92:	02e78563          	beq	a5,a4,80004abc <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a96:	4709                	li	a4,2
    80004a98:	10e79463          	bne	a5,a4,80004ba0 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a9c:	0ec05e63          	blez	a2,80004b98 <filewrite+0x136>
    int i = 0;
    80004aa0:	4981                	li	s3,0
    80004aa2:	6b05                	lui	s6,0x1
    80004aa4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004aa8:	6b85                	lui	s7,0x1
    80004aaa:	c00b8b9b          	addiw	s7,s7,-1024
    80004aae:	a851                	j	80004b42 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004ab0:	6908                	ld	a0,16(a0)
    80004ab2:	00000097          	auipc	ra,0x0
    80004ab6:	254080e7          	jalr	596(ra) # 80004d06 <pipewrite>
    80004aba:	a85d                	j	80004b70 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004abc:	02451783          	lh	a5,36(a0)
    80004ac0:	03079693          	slli	a3,a5,0x30
    80004ac4:	92c1                	srli	a3,a3,0x30
    80004ac6:	4725                	li	a4,9
    80004ac8:	0ed76663          	bltu	a4,a3,80004bb4 <filewrite+0x152>
    80004acc:	0792                	slli	a5,a5,0x4
    80004ace:	0001d717          	auipc	a4,0x1d
    80004ad2:	f0270713          	addi	a4,a4,-254 # 800219d0 <devsw>
    80004ad6:	97ba                	add	a5,a5,a4
    80004ad8:	679c                	ld	a5,8(a5)
    80004ada:	cff9                	beqz	a5,80004bb8 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004adc:	4505                	li	a0,1
    80004ade:	9782                	jalr	a5
    80004ae0:	a841                	j	80004b70 <filewrite+0x10e>
    80004ae2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ae6:	00000097          	auipc	ra,0x0
    80004aea:	8ae080e7          	jalr	-1874(ra) # 80004394 <begin_op>
      ilock(f->ip);
    80004aee:	01893503          	ld	a0,24(s2)
    80004af2:	fffff097          	auipc	ra,0xfffff
    80004af6:	ee2080e7          	jalr	-286(ra) # 800039d4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004afa:	8762                	mv	a4,s8
    80004afc:	02092683          	lw	a3,32(s2)
    80004b00:	01598633          	add	a2,s3,s5
    80004b04:	4585                	li	a1,1
    80004b06:	01893503          	ld	a0,24(s2)
    80004b0a:	fffff097          	auipc	ra,0xfffff
    80004b0e:	276080e7          	jalr	630(ra) # 80003d80 <writei>
    80004b12:	84aa                	mv	s1,a0
    80004b14:	02a05f63          	blez	a0,80004b52 <filewrite+0xf0>
        f->off += r;
    80004b18:	02092783          	lw	a5,32(s2)
    80004b1c:	9fa9                	addw	a5,a5,a0
    80004b1e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b22:	01893503          	ld	a0,24(s2)
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	f70080e7          	jalr	-144(ra) # 80003a96 <iunlock>
      end_op();
    80004b2e:	00000097          	auipc	ra,0x0
    80004b32:	8e6080e7          	jalr	-1818(ra) # 80004414 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004b36:	049c1963          	bne	s8,s1,80004b88 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004b3a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b3e:	0349d663          	bge	s3,s4,80004b6a <filewrite+0x108>
      int n1 = n - i;
    80004b42:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b46:	84be                	mv	s1,a5
    80004b48:	2781                	sext.w	a5,a5
    80004b4a:	f8fb5ce3          	bge	s6,a5,80004ae2 <filewrite+0x80>
    80004b4e:	84de                	mv	s1,s7
    80004b50:	bf49                	j	80004ae2 <filewrite+0x80>
      iunlock(f->ip);
    80004b52:	01893503          	ld	a0,24(s2)
    80004b56:	fffff097          	auipc	ra,0xfffff
    80004b5a:	f40080e7          	jalr	-192(ra) # 80003a96 <iunlock>
      end_op();
    80004b5e:	00000097          	auipc	ra,0x0
    80004b62:	8b6080e7          	jalr	-1866(ra) # 80004414 <end_op>
      if(r < 0)
    80004b66:	fc04d8e3          	bgez	s1,80004b36 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004b6a:	8552                	mv	a0,s4
    80004b6c:	033a1863          	bne	s4,s3,80004b9c <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b70:	60a6                	ld	ra,72(sp)
    80004b72:	6406                	ld	s0,64(sp)
    80004b74:	74e2                	ld	s1,56(sp)
    80004b76:	7942                	ld	s2,48(sp)
    80004b78:	79a2                	ld	s3,40(sp)
    80004b7a:	7a02                	ld	s4,32(sp)
    80004b7c:	6ae2                	ld	s5,24(sp)
    80004b7e:	6b42                	ld	s6,16(sp)
    80004b80:	6ba2                	ld	s7,8(sp)
    80004b82:	6c02                	ld	s8,0(sp)
    80004b84:	6161                	addi	sp,sp,80
    80004b86:	8082                	ret
        panic("short filewrite");
    80004b88:	00004517          	auipc	a0,0x4
    80004b8c:	bf050513          	addi	a0,a0,-1040 # 80008778 <syscalls+0x268>
    80004b90:	ffffc097          	auipc	ra,0xffffc
    80004b94:	9b8080e7          	jalr	-1608(ra) # 80000548 <panic>
    int i = 0;
    80004b98:	4981                	li	s3,0
    80004b9a:	bfc1                	j	80004b6a <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b9c:	557d                	li	a0,-1
    80004b9e:	bfc9                	j	80004b70 <filewrite+0x10e>
    panic("filewrite");
    80004ba0:	00004517          	auipc	a0,0x4
    80004ba4:	be850513          	addi	a0,a0,-1048 # 80008788 <syscalls+0x278>
    80004ba8:	ffffc097          	auipc	ra,0xffffc
    80004bac:	9a0080e7          	jalr	-1632(ra) # 80000548 <panic>
    return -1;
    80004bb0:	557d                	li	a0,-1
}
    80004bb2:	8082                	ret
      return -1;
    80004bb4:	557d                	li	a0,-1
    80004bb6:	bf6d                	j	80004b70 <filewrite+0x10e>
    80004bb8:	557d                	li	a0,-1
    80004bba:	bf5d                	j	80004b70 <filewrite+0x10e>

0000000080004bbc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004bbc:	7179                	addi	sp,sp,-48
    80004bbe:	f406                	sd	ra,40(sp)
    80004bc0:	f022                	sd	s0,32(sp)
    80004bc2:	ec26                	sd	s1,24(sp)
    80004bc4:	e84a                	sd	s2,16(sp)
    80004bc6:	e44e                	sd	s3,8(sp)
    80004bc8:	e052                	sd	s4,0(sp)
    80004bca:	1800                	addi	s0,sp,48
    80004bcc:	84aa                	mv	s1,a0
    80004bce:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004bd0:	0005b023          	sd	zero,0(a1)
    80004bd4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bd8:	00000097          	auipc	ra,0x0
    80004bdc:	bd2080e7          	jalr	-1070(ra) # 800047aa <filealloc>
    80004be0:	e088                	sd	a0,0(s1)
    80004be2:	c551                	beqz	a0,80004c6e <pipealloc+0xb2>
    80004be4:	00000097          	auipc	ra,0x0
    80004be8:	bc6080e7          	jalr	-1082(ra) # 800047aa <filealloc>
    80004bec:	00aa3023          	sd	a0,0(s4)
    80004bf0:	c92d                	beqz	a0,80004c62 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bf2:	ffffc097          	auipc	ra,0xffffc
    80004bf6:	fe6080e7          	jalr	-26(ra) # 80000bd8 <kalloc>
    80004bfa:	892a                	mv	s2,a0
    80004bfc:	c125                	beqz	a0,80004c5c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bfe:	4985                	li	s3,1
    80004c00:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c04:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c08:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c0c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c10:	00004597          	auipc	a1,0x4
    80004c14:	b8858593          	addi	a1,a1,-1144 # 80008798 <syscalls+0x288>
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	0de080e7          	jalr	222(ra) # 80000cf6 <initlock>
  (*f0)->type = FD_PIPE;
    80004c20:	609c                	ld	a5,0(s1)
    80004c22:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c26:	609c                	ld	a5,0(s1)
    80004c28:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c2c:	609c                	ld	a5,0(s1)
    80004c2e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c32:	609c                	ld	a5,0(s1)
    80004c34:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c38:	000a3783          	ld	a5,0(s4)
    80004c3c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c40:	000a3783          	ld	a5,0(s4)
    80004c44:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c48:	000a3783          	ld	a5,0(s4)
    80004c4c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c50:	000a3783          	ld	a5,0(s4)
    80004c54:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c58:	4501                	li	a0,0
    80004c5a:	a025                	j	80004c82 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c5c:	6088                	ld	a0,0(s1)
    80004c5e:	e501                	bnez	a0,80004c66 <pipealloc+0xaa>
    80004c60:	a039                	j	80004c6e <pipealloc+0xb2>
    80004c62:	6088                	ld	a0,0(s1)
    80004c64:	c51d                	beqz	a0,80004c92 <pipealloc+0xd6>
    fileclose(*f0);
    80004c66:	00000097          	auipc	ra,0x0
    80004c6a:	c00080e7          	jalr	-1024(ra) # 80004866 <fileclose>
  if(*f1)
    80004c6e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c72:	557d                	li	a0,-1
  if(*f1)
    80004c74:	c799                	beqz	a5,80004c82 <pipealloc+0xc6>
    fileclose(*f1);
    80004c76:	853e                	mv	a0,a5
    80004c78:	00000097          	auipc	ra,0x0
    80004c7c:	bee080e7          	jalr	-1042(ra) # 80004866 <fileclose>
  return -1;
    80004c80:	557d                	li	a0,-1
}
    80004c82:	70a2                	ld	ra,40(sp)
    80004c84:	7402                	ld	s0,32(sp)
    80004c86:	64e2                	ld	s1,24(sp)
    80004c88:	6942                	ld	s2,16(sp)
    80004c8a:	69a2                	ld	s3,8(sp)
    80004c8c:	6a02                	ld	s4,0(sp)
    80004c8e:	6145                	addi	sp,sp,48
    80004c90:	8082                	ret
  return -1;
    80004c92:	557d                	li	a0,-1
    80004c94:	b7fd                	j	80004c82 <pipealloc+0xc6>

0000000080004c96 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c96:	1101                	addi	sp,sp,-32
    80004c98:	ec06                	sd	ra,24(sp)
    80004c9a:	e822                	sd	s0,16(sp)
    80004c9c:	e426                	sd	s1,8(sp)
    80004c9e:	e04a                	sd	s2,0(sp)
    80004ca0:	1000                	addi	s0,sp,32
    80004ca2:	84aa                	mv	s1,a0
    80004ca4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ca6:	ffffc097          	auipc	ra,0xffffc
    80004caa:	0e0080e7          	jalr	224(ra) # 80000d86 <acquire>
  if(writable){
    80004cae:	02090d63          	beqz	s2,80004ce8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004cb2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004cb6:	21848513          	addi	a0,s1,536
    80004cba:	ffffe097          	auipc	ra,0xffffe
    80004cbe:	914080e7          	jalr	-1772(ra) # 800025ce <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004cc2:	2204b783          	ld	a5,544(s1)
    80004cc6:	eb95                	bnez	a5,80004cfa <pipeclose+0x64>
    release(&pi->lock);
    80004cc8:	8526                	mv	a0,s1
    80004cca:	ffffc097          	auipc	ra,0xffffc
    80004cce:	170080e7          	jalr	368(ra) # 80000e3a <release>
    kfree((char*)pi);
    80004cd2:	8526                	mv	a0,s1
    80004cd4:	ffffc097          	auipc	ra,0xffffc
    80004cd8:	d50080e7          	jalr	-688(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004cdc:	60e2                	ld	ra,24(sp)
    80004cde:	6442                	ld	s0,16(sp)
    80004ce0:	64a2                	ld	s1,8(sp)
    80004ce2:	6902                	ld	s2,0(sp)
    80004ce4:	6105                	addi	sp,sp,32
    80004ce6:	8082                	ret
    pi->readopen = 0;
    80004ce8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004cec:	21c48513          	addi	a0,s1,540
    80004cf0:	ffffe097          	auipc	ra,0xffffe
    80004cf4:	8de080e7          	jalr	-1826(ra) # 800025ce <wakeup>
    80004cf8:	b7e9                	j	80004cc2 <pipeclose+0x2c>
    release(&pi->lock);
    80004cfa:	8526                	mv	a0,s1
    80004cfc:	ffffc097          	auipc	ra,0xffffc
    80004d00:	13e080e7          	jalr	318(ra) # 80000e3a <release>
}
    80004d04:	bfe1                	j	80004cdc <pipeclose+0x46>

0000000080004d06 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d06:	7119                	addi	sp,sp,-128
    80004d08:	fc86                	sd	ra,120(sp)
    80004d0a:	f8a2                	sd	s0,112(sp)
    80004d0c:	f4a6                	sd	s1,104(sp)
    80004d0e:	f0ca                	sd	s2,96(sp)
    80004d10:	ecce                	sd	s3,88(sp)
    80004d12:	e8d2                	sd	s4,80(sp)
    80004d14:	e4d6                	sd	s5,72(sp)
    80004d16:	e0da                	sd	s6,64(sp)
    80004d18:	fc5e                	sd	s7,56(sp)
    80004d1a:	f862                	sd	s8,48(sp)
    80004d1c:	f466                	sd	s9,40(sp)
    80004d1e:	f06a                	sd	s10,32(sp)
    80004d20:	ec6e                	sd	s11,24(sp)
    80004d22:	0100                	addi	s0,sp,128
    80004d24:	84aa                	mv	s1,a0
    80004d26:	8cae                	mv	s9,a1
    80004d28:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004d2a:	ffffd097          	auipc	ra,0xffffd
    80004d2e:	f0e080e7          	jalr	-242(ra) # 80001c38 <myproc>
    80004d32:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004d34:	8526                	mv	a0,s1
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	050080e7          	jalr	80(ra) # 80000d86 <acquire>
  for(i = 0; i < n; i++){
    80004d3e:	0d605963          	blez	s6,80004e10 <pipewrite+0x10a>
    80004d42:	89a6                	mv	s3,s1
    80004d44:	3b7d                	addiw	s6,s6,-1
    80004d46:	1b02                	slli	s6,s6,0x20
    80004d48:	020b5b13          	srli	s6,s6,0x20
    80004d4c:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004d4e:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d52:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d56:	5dfd                	li	s11,-1
    80004d58:	000b8d1b          	sext.w	s10,s7
    80004d5c:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d5e:	2184a783          	lw	a5,536(s1)
    80004d62:	21c4a703          	lw	a4,540(s1)
    80004d66:	2007879b          	addiw	a5,a5,512
    80004d6a:	02f71b63          	bne	a4,a5,80004da0 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004d6e:	2204a783          	lw	a5,544(s1)
    80004d72:	cbad                	beqz	a5,80004de4 <pipewrite+0xde>
    80004d74:	03092783          	lw	a5,48(s2)
    80004d78:	e7b5                	bnez	a5,80004de4 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004d7a:	8556                	mv	a0,s5
    80004d7c:	ffffe097          	auipc	ra,0xffffe
    80004d80:	852080e7          	jalr	-1966(ra) # 800025ce <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d84:	85ce                	mv	a1,s3
    80004d86:	8552                	mv	a0,s4
    80004d88:	ffffd097          	auipc	ra,0xffffd
    80004d8c:	6c0080e7          	jalr	1728(ra) # 80002448 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d90:	2184a783          	lw	a5,536(s1)
    80004d94:	21c4a703          	lw	a4,540(s1)
    80004d98:	2007879b          	addiw	a5,a5,512
    80004d9c:	fcf709e3          	beq	a4,a5,80004d6e <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004da0:	4685                	li	a3,1
    80004da2:	019b8633          	add	a2,s7,s9
    80004da6:	f8f40593          	addi	a1,s0,-113
    80004daa:	05093503          	ld	a0,80(s2)
    80004dae:	ffffd097          	auipc	ra,0xffffd
    80004db2:	c0a080e7          	jalr	-1014(ra) # 800019b8 <copyin>
    80004db6:	05b50e63          	beq	a0,s11,80004e12 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004dba:	21c4a783          	lw	a5,540(s1)
    80004dbe:	0017871b          	addiw	a4,a5,1
    80004dc2:	20e4ae23          	sw	a4,540(s1)
    80004dc6:	1ff7f793          	andi	a5,a5,511
    80004dca:	97a6                	add	a5,a5,s1
    80004dcc:	f8f44703          	lbu	a4,-113(s0)
    80004dd0:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004dd4:	001d0c1b          	addiw	s8,s10,1
    80004dd8:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004ddc:	036b8b63          	beq	s7,s6,80004e12 <pipewrite+0x10c>
    80004de0:	8bbe                	mv	s7,a5
    80004de2:	bf9d                	j	80004d58 <pipewrite+0x52>
        release(&pi->lock);
    80004de4:	8526                	mv	a0,s1
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	054080e7          	jalr	84(ra) # 80000e3a <release>
        return -1;
    80004dee:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004df0:	8562                	mv	a0,s8
    80004df2:	70e6                	ld	ra,120(sp)
    80004df4:	7446                	ld	s0,112(sp)
    80004df6:	74a6                	ld	s1,104(sp)
    80004df8:	7906                	ld	s2,96(sp)
    80004dfa:	69e6                	ld	s3,88(sp)
    80004dfc:	6a46                	ld	s4,80(sp)
    80004dfe:	6aa6                	ld	s5,72(sp)
    80004e00:	6b06                	ld	s6,64(sp)
    80004e02:	7be2                	ld	s7,56(sp)
    80004e04:	7c42                	ld	s8,48(sp)
    80004e06:	7ca2                	ld	s9,40(sp)
    80004e08:	7d02                	ld	s10,32(sp)
    80004e0a:	6de2                	ld	s11,24(sp)
    80004e0c:	6109                	addi	sp,sp,128
    80004e0e:	8082                	ret
  for(i = 0; i < n; i++){
    80004e10:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004e12:	21848513          	addi	a0,s1,536
    80004e16:	ffffd097          	auipc	ra,0xffffd
    80004e1a:	7b8080e7          	jalr	1976(ra) # 800025ce <wakeup>
  release(&pi->lock);
    80004e1e:	8526                	mv	a0,s1
    80004e20:	ffffc097          	auipc	ra,0xffffc
    80004e24:	01a080e7          	jalr	26(ra) # 80000e3a <release>
  return i;
    80004e28:	b7e1                	j	80004df0 <pipewrite+0xea>

0000000080004e2a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e2a:	715d                	addi	sp,sp,-80
    80004e2c:	e486                	sd	ra,72(sp)
    80004e2e:	e0a2                	sd	s0,64(sp)
    80004e30:	fc26                	sd	s1,56(sp)
    80004e32:	f84a                	sd	s2,48(sp)
    80004e34:	f44e                	sd	s3,40(sp)
    80004e36:	f052                	sd	s4,32(sp)
    80004e38:	ec56                	sd	s5,24(sp)
    80004e3a:	e85a                	sd	s6,16(sp)
    80004e3c:	0880                	addi	s0,sp,80
    80004e3e:	84aa                	mv	s1,a0
    80004e40:	892e                	mv	s2,a1
    80004e42:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e44:	ffffd097          	auipc	ra,0xffffd
    80004e48:	df4080e7          	jalr	-524(ra) # 80001c38 <myproc>
    80004e4c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e4e:	8b26                	mv	s6,s1
    80004e50:	8526                	mv	a0,s1
    80004e52:	ffffc097          	auipc	ra,0xffffc
    80004e56:	f34080e7          	jalr	-204(ra) # 80000d86 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e5a:	2184a703          	lw	a4,536(s1)
    80004e5e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e62:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e66:	02f71463          	bne	a4,a5,80004e8e <piperead+0x64>
    80004e6a:	2244a783          	lw	a5,548(s1)
    80004e6e:	c385                	beqz	a5,80004e8e <piperead+0x64>
    if(pr->killed){
    80004e70:	030a2783          	lw	a5,48(s4)
    80004e74:	ebc1                	bnez	a5,80004f04 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e76:	85da                	mv	a1,s6
    80004e78:	854e                	mv	a0,s3
    80004e7a:	ffffd097          	auipc	ra,0xffffd
    80004e7e:	5ce080e7          	jalr	1486(ra) # 80002448 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e82:	2184a703          	lw	a4,536(s1)
    80004e86:	21c4a783          	lw	a5,540(s1)
    80004e8a:	fef700e3          	beq	a4,a5,80004e6a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e8e:	09505263          	blez	s5,80004f12 <piperead+0xe8>
    80004e92:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e94:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004e96:	2184a783          	lw	a5,536(s1)
    80004e9a:	21c4a703          	lw	a4,540(s1)
    80004e9e:	02f70d63          	beq	a4,a5,80004ed8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ea2:	0017871b          	addiw	a4,a5,1
    80004ea6:	20e4ac23          	sw	a4,536(s1)
    80004eaa:	1ff7f793          	andi	a5,a5,511
    80004eae:	97a6                	add	a5,a5,s1
    80004eb0:	0187c783          	lbu	a5,24(a5)
    80004eb4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004eb8:	4685                	li	a3,1
    80004eba:	fbf40613          	addi	a2,s0,-65
    80004ebe:	85ca                	mv	a1,s2
    80004ec0:	050a3503          	ld	a0,80(s4)
    80004ec4:	ffffd097          	auipc	ra,0xffffd
    80004ec8:	95c080e7          	jalr	-1700(ra) # 80001820 <copyout>
    80004ecc:	01650663          	beq	a0,s6,80004ed8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ed0:	2985                	addiw	s3,s3,1
    80004ed2:	0905                	addi	s2,s2,1
    80004ed4:	fd3a91e3          	bne	s5,s3,80004e96 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ed8:	21c48513          	addi	a0,s1,540
    80004edc:	ffffd097          	auipc	ra,0xffffd
    80004ee0:	6f2080e7          	jalr	1778(ra) # 800025ce <wakeup>
  release(&pi->lock);
    80004ee4:	8526                	mv	a0,s1
    80004ee6:	ffffc097          	auipc	ra,0xffffc
    80004eea:	f54080e7          	jalr	-172(ra) # 80000e3a <release>
  return i;
}
    80004eee:	854e                	mv	a0,s3
    80004ef0:	60a6                	ld	ra,72(sp)
    80004ef2:	6406                	ld	s0,64(sp)
    80004ef4:	74e2                	ld	s1,56(sp)
    80004ef6:	7942                	ld	s2,48(sp)
    80004ef8:	79a2                	ld	s3,40(sp)
    80004efa:	7a02                	ld	s4,32(sp)
    80004efc:	6ae2                	ld	s5,24(sp)
    80004efe:	6b42                	ld	s6,16(sp)
    80004f00:	6161                	addi	sp,sp,80
    80004f02:	8082                	ret
      release(&pi->lock);
    80004f04:	8526                	mv	a0,s1
    80004f06:	ffffc097          	auipc	ra,0xffffc
    80004f0a:	f34080e7          	jalr	-204(ra) # 80000e3a <release>
      return -1;
    80004f0e:	59fd                	li	s3,-1
    80004f10:	bff9                	j	80004eee <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f12:	4981                	li	s3,0
    80004f14:	b7d1                	j	80004ed8 <piperead+0xae>

0000000080004f16 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004f16:	df010113          	addi	sp,sp,-528
    80004f1a:	20113423          	sd	ra,520(sp)
    80004f1e:	20813023          	sd	s0,512(sp)
    80004f22:	ffa6                	sd	s1,504(sp)
    80004f24:	fbca                	sd	s2,496(sp)
    80004f26:	f7ce                	sd	s3,488(sp)
    80004f28:	f3d2                	sd	s4,480(sp)
    80004f2a:	efd6                	sd	s5,472(sp)
    80004f2c:	ebda                	sd	s6,464(sp)
    80004f2e:	e7de                	sd	s7,456(sp)
    80004f30:	e3e2                	sd	s8,448(sp)
    80004f32:	ff66                	sd	s9,440(sp)
    80004f34:	fb6a                	sd	s10,432(sp)
    80004f36:	f76e                	sd	s11,424(sp)
    80004f38:	0c00                	addi	s0,sp,528
    80004f3a:	84aa                	mv	s1,a0
    80004f3c:	dea43c23          	sd	a0,-520(s0)
    80004f40:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f44:	ffffd097          	auipc	ra,0xffffd
    80004f48:	cf4080e7          	jalr	-780(ra) # 80001c38 <myproc>
    80004f4c:	892a                	mv	s2,a0

  begin_op();
    80004f4e:	fffff097          	auipc	ra,0xfffff
    80004f52:	446080e7          	jalr	1094(ra) # 80004394 <begin_op>

  if((ip = namei(path)) == 0){
    80004f56:	8526                	mv	a0,s1
    80004f58:	fffff097          	auipc	ra,0xfffff
    80004f5c:	230080e7          	jalr	560(ra) # 80004188 <namei>
    80004f60:	c92d                	beqz	a0,80004fd2 <exec+0xbc>
    80004f62:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f64:	fffff097          	auipc	ra,0xfffff
    80004f68:	a70080e7          	jalr	-1424(ra) # 800039d4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f6c:	04000713          	li	a4,64
    80004f70:	4681                	li	a3,0
    80004f72:	e4840613          	addi	a2,s0,-440
    80004f76:	4581                	li	a1,0
    80004f78:	8526                	mv	a0,s1
    80004f7a:	fffff097          	auipc	ra,0xfffff
    80004f7e:	d0e080e7          	jalr	-754(ra) # 80003c88 <readi>
    80004f82:	04000793          	li	a5,64
    80004f86:	00f51a63          	bne	a0,a5,80004f9a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f8a:	e4842703          	lw	a4,-440(s0)
    80004f8e:	464c47b7          	lui	a5,0x464c4
    80004f92:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f96:	04f70463          	beq	a4,a5,80004fde <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f9a:	8526                	mv	a0,s1
    80004f9c:	fffff097          	auipc	ra,0xfffff
    80004fa0:	c9a080e7          	jalr	-870(ra) # 80003c36 <iunlockput>
    end_op();
    80004fa4:	fffff097          	auipc	ra,0xfffff
    80004fa8:	470080e7          	jalr	1136(ra) # 80004414 <end_op>
  }
  return -1;
    80004fac:	557d                	li	a0,-1
}
    80004fae:	20813083          	ld	ra,520(sp)
    80004fb2:	20013403          	ld	s0,512(sp)
    80004fb6:	74fe                	ld	s1,504(sp)
    80004fb8:	795e                	ld	s2,496(sp)
    80004fba:	79be                	ld	s3,488(sp)
    80004fbc:	7a1e                	ld	s4,480(sp)
    80004fbe:	6afe                	ld	s5,472(sp)
    80004fc0:	6b5e                	ld	s6,464(sp)
    80004fc2:	6bbe                	ld	s7,456(sp)
    80004fc4:	6c1e                	ld	s8,448(sp)
    80004fc6:	7cfa                	ld	s9,440(sp)
    80004fc8:	7d5a                	ld	s10,432(sp)
    80004fca:	7dba                	ld	s11,424(sp)
    80004fcc:	21010113          	addi	sp,sp,528
    80004fd0:	8082                	ret
    end_op();
    80004fd2:	fffff097          	auipc	ra,0xfffff
    80004fd6:	442080e7          	jalr	1090(ra) # 80004414 <end_op>
    return -1;
    80004fda:	557d                	li	a0,-1
    80004fdc:	bfc9                	j	80004fae <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fde:	854a                	mv	a0,s2
    80004fe0:	ffffd097          	auipc	ra,0xffffd
    80004fe4:	d1c080e7          	jalr	-740(ra) # 80001cfc <proc_pagetable>
    80004fe8:	8baa                	mv	s7,a0
    80004fea:	d945                	beqz	a0,80004f9a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fec:	e6842983          	lw	s3,-408(s0)
    80004ff0:	e8045783          	lhu	a5,-384(s0)
    80004ff4:	c7ad                	beqz	a5,8000505e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ff6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ff8:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004ffa:	6c85                	lui	s9,0x1
    80004ffc:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005000:	def43823          	sd	a5,-528(s0)
    80005004:	a42d                	j	8000522e <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005006:	00003517          	auipc	a0,0x3
    8000500a:	79a50513          	addi	a0,a0,1946 # 800087a0 <syscalls+0x290>
    8000500e:	ffffb097          	auipc	ra,0xffffb
    80005012:	53a080e7          	jalr	1338(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005016:	8756                	mv	a4,s5
    80005018:	012d86bb          	addw	a3,s11,s2
    8000501c:	4581                	li	a1,0
    8000501e:	8526                	mv	a0,s1
    80005020:	fffff097          	auipc	ra,0xfffff
    80005024:	c68080e7          	jalr	-920(ra) # 80003c88 <readi>
    80005028:	2501                	sext.w	a0,a0
    8000502a:	1aaa9963          	bne	s5,a0,800051dc <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000502e:	6785                	lui	a5,0x1
    80005030:	0127893b          	addw	s2,a5,s2
    80005034:	77fd                	lui	a5,0xfffff
    80005036:	01478a3b          	addw	s4,a5,s4
    8000503a:	1f897163          	bgeu	s2,s8,8000521c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000503e:	02091593          	slli	a1,s2,0x20
    80005042:	9181                	srli	a1,a1,0x20
    80005044:	95ea                	add	a1,a1,s10
    80005046:	855e                	mv	a0,s7
    80005048:	ffffc097          	auipc	ra,0xffffc
    8000504c:	1cc080e7          	jalr	460(ra) # 80001214 <walkaddr>
    80005050:	862a                	mv	a2,a0
    if(pa == 0)
    80005052:	d955                	beqz	a0,80005006 <exec+0xf0>
      n = PGSIZE;
    80005054:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005056:	fd9a70e3          	bgeu	s4,s9,80005016 <exec+0x100>
      n = sz - i;
    8000505a:	8ad2                	mv	s5,s4
    8000505c:	bf6d                	j	80005016 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000505e:	4901                	li	s2,0
  iunlockput(ip);
    80005060:	8526                	mv	a0,s1
    80005062:	fffff097          	auipc	ra,0xfffff
    80005066:	bd4080e7          	jalr	-1068(ra) # 80003c36 <iunlockput>
  end_op();
    8000506a:	fffff097          	auipc	ra,0xfffff
    8000506e:	3aa080e7          	jalr	938(ra) # 80004414 <end_op>
  p = myproc();
    80005072:	ffffd097          	auipc	ra,0xffffd
    80005076:	bc6080e7          	jalr	-1082(ra) # 80001c38 <myproc>
    8000507a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000507c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005080:	6785                	lui	a5,0x1
    80005082:	17fd                	addi	a5,a5,-1
    80005084:	993e                	add	s2,s2,a5
    80005086:	757d                	lui	a0,0xfffff
    80005088:	00a977b3          	and	a5,s2,a0
    8000508c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005090:	6609                	lui	a2,0x2
    80005092:	963e                	add	a2,a2,a5
    80005094:	85be                	mv	a1,a5
    80005096:	855e                	mv	a0,s7
    80005098:	ffffc097          	auipc	ra,0xffffc
    8000509c:	54a080e7          	jalr	1354(ra) # 800015e2 <uvmalloc>
    800050a0:	8b2a                	mv	s6,a0
  ip = 0;
    800050a2:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800050a4:	12050c63          	beqz	a0,800051dc <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800050a8:	75f9                	lui	a1,0xffffe
    800050aa:	95aa                	add	a1,a1,a0
    800050ac:	855e                	mv	a0,s7
    800050ae:	ffffc097          	auipc	ra,0xffffc
    800050b2:	740080e7          	jalr	1856(ra) # 800017ee <uvmclear>
  stackbase = sp - PGSIZE;
    800050b6:	7c7d                	lui	s8,0xfffff
    800050b8:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800050ba:	e0043783          	ld	a5,-512(s0)
    800050be:	6388                	ld	a0,0(a5)
    800050c0:	c535                	beqz	a0,8000512c <exec+0x216>
    800050c2:	e8840993          	addi	s3,s0,-376
    800050c6:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800050ca:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800050cc:	ffffc097          	auipc	ra,0xffffc
    800050d0:	f3e080e7          	jalr	-194(ra) # 8000100a <strlen>
    800050d4:	2505                	addiw	a0,a0,1
    800050d6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050da:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800050de:	13896363          	bltu	s2,s8,80005204 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050e2:	e0043d83          	ld	s11,-512(s0)
    800050e6:	000dba03          	ld	s4,0(s11)
    800050ea:	8552                	mv	a0,s4
    800050ec:	ffffc097          	auipc	ra,0xffffc
    800050f0:	f1e080e7          	jalr	-226(ra) # 8000100a <strlen>
    800050f4:	0015069b          	addiw	a3,a0,1
    800050f8:	8652                	mv	a2,s4
    800050fa:	85ca                	mv	a1,s2
    800050fc:	855e                	mv	a0,s7
    800050fe:	ffffc097          	auipc	ra,0xffffc
    80005102:	722080e7          	jalr	1826(ra) # 80001820 <copyout>
    80005106:	10054363          	bltz	a0,8000520c <exec+0x2f6>
    ustack[argc] = sp;
    8000510a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000510e:	0485                	addi	s1,s1,1
    80005110:	008d8793          	addi	a5,s11,8
    80005114:	e0f43023          	sd	a5,-512(s0)
    80005118:	008db503          	ld	a0,8(s11)
    8000511c:	c911                	beqz	a0,80005130 <exec+0x21a>
    if(argc >= MAXARG)
    8000511e:	09a1                	addi	s3,s3,8
    80005120:	fb3c96e3          	bne	s9,s3,800050cc <exec+0x1b6>
  sz = sz1;
    80005124:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005128:	4481                	li	s1,0
    8000512a:	a84d                	j	800051dc <exec+0x2c6>
  sp = sz;
    8000512c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000512e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005130:	00349793          	slli	a5,s1,0x3
    80005134:	f9040713          	addi	a4,s0,-112
    80005138:	97ba                	add	a5,a5,a4
    8000513a:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    8000513e:	00148693          	addi	a3,s1,1
    80005142:	068e                	slli	a3,a3,0x3
    80005144:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005148:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000514c:	01897663          	bgeu	s2,s8,80005158 <exec+0x242>
  sz = sz1;
    80005150:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005154:	4481                	li	s1,0
    80005156:	a059                	j	800051dc <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005158:	e8840613          	addi	a2,s0,-376
    8000515c:	85ca                	mv	a1,s2
    8000515e:	855e                	mv	a0,s7
    80005160:	ffffc097          	auipc	ra,0xffffc
    80005164:	6c0080e7          	jalr	1728(ra) # 80001820 <copyout>
    80005168:	0a054663          	bltz	a0,80005214 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000516c:	058ab783          	ld	a5,88(s5)
    80005170:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005174:	df843783          	ld	a5,-520(s0)
    80005178:	0007c703          	lbu	a4,0(a5)
    8000517c:	cf11                	beqz	a4,80005198 <exec+0x282>
    8000517e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005180:	02f00693          	li	a3,47
    80005184:	a029                	j	8000518e <exec+0x278>
  for(last=s=path; *s; s++)
    80005186:	0785                	addi	a5,a5,1
    80005188:	fff7c703          	lbu	a4,-1(a5)
    8000518c:	c711                	beqz	a4,80005198 <exec+0x282>
    if(*s == '/')
    8000518e:	fed71ce3          	bne	a4,a3,80005186 <exec+0x270>
      last = s+1;
    80005192:	def43c23          	sd	a5,-520(s0)
    80005196:	bfc5                	j	80005186 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005198:	4641                	li	a2,16
    8000519a:	df843583          	ld	a1,-520(s0)
    8000519e:	158a8513          	addi	a0,s5,344
    800051a2:	ffffc097          	auipc	ra,0xffffc
    800051a6:	e36080e7          	jalr	-458(ra) # 80000fd8 <safestrcpy>
  oldpagetable = p->pagetable;
    800051aa:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800051ae:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800051b2:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051b6:	058ab783          	ld	a5,88(s5)
    800051ba:	e6043703          	ld	a4,-416(s0)
    800051be:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051c0:	058ab783          	ld	a5,88(s5)
    800051c4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051c8:	85ea                	mv	a1,s10
    800051ca:	ffffd097          	auipc	ra,0xffffd
    800051ce:	bce080e7          	jalr	-1074(ra) # 80001d98 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051d2:	0004851b          	sext.w	a0,s1
    800051d6:	bbe1                	j	80004fae <exec+0x98>
    800051d8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800051dc:	e0843583          	ld	a1,-504(s0)
    800051e0:	855e                	mv	a0,s7
    800051e2:	ffffd097          	auipc	ra,0xffffd
    800051e6:	bb6080e7          	jalr	-1098(ra) # 80001d98 <proc_freepagetable>
  if(ip){
    800051ea:	da0498e3          	bnez	s1,80004f9a <exec+0x84>
  return -1;
    800051ee:	557d                	li	a0,-1
    800051f0:	bb7d                	j	80004fae <exec+0x98>
    800051f2:	e1243423          	sd	s2,-504(s0)
    800051f6:	b7dd                	j	800051dc <exec+0x2c6>
    800051f8:	e1243423          	sd	s2,-504(s0)
    800051fc:	b7c5                	j	800051dc <exec+0x2c6>
    800051fe:	e1243423          	sd	s2,-504(s0)
    80005202:	bfe9                	j	800051dc <exec+0x2c6>
  sz = sz1;
    80005204:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005208:	4481                	li	s1,0
    8000520a:	bfc9                	j	800051dc <exec+0x2c6>
  sz = sz1;
    8000520c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005210:	4481                	li	s1,0
    80005212:	b7e9                	j	800051dc <exec+0x2c6>
  sz = sz1;
    80005214:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005218:	4481                	li	s1,0
    8000521a:	b7c9                	j	800051dc <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000521c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005220:	2b05                	addiw	s6,s6,1
    80005222:	0389899b          	addiw	s3,s3,56
    80005226:	e8045783          	lhu	a5,-384(s0)
    8000522a:	e2fb5be3          	bge	s6,a5,80005060 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000522e:	2981                	sext.w	s3,s3
    80005230:	03800713          	li	a4,56
    80005234:	86ce                	mv	a3,s3
    80005236:	e1040613          	addi	a2,s0,-496
    8000523a:	4581                	li	a1,0
    8000523c:	8526                	mv	a0,s1
    8000523e:	fffff097          	auipc	ra,0xfffff
    80005242:	a4a080e7          	jalr	-1462(ra) # 80003c88 <readi>
    80005246:	03800793          	li	a5,56
    8000524a:	f8f517e3          	bne	a0,a5,800051d8 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000524e:	e1042783          	lw	a5,-496(s0)
    80005252:	4705                	li	a4,1
    80005254:	fce796e3          	bne	a5,a4,80005220 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005258:	e3843603          	ld	a2,-456(s0)
    8000525c:	e3043783          	ld	a5,-464(s0)
    80005260:	f8f669e3          	bltu	a2,a5,800051f2 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005264:	e2043783          	ld	a5,-480(s0)
    80005268:	963e                	add	a2,a2,a5
    8000526a:	f8f667e3          	bltu	a2,a5,800051f8 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000526e:	85ca                	mv	a1,s2
    80005270:	855e                	mv	a0,s7
    80005272:	ffffc097          	auipc	ra,0xffffc
    80005276:	370080e7          	jalr	880(ra) # 800015e2 <uvmalloc>
    8000527a:	e0a43423          	sd	a0,-504(s0)
    8000527e:	d141                	beqz	a0,800051fe <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005280:	e2043d03          	ld	s10,-480(s0)
    80005284:	df043783          	ld	a5,-528(s0)
    80005288:	00fd77b3          	and	a5,s10,a5
    8000528c:	fba1                	bnez	a5,800051dc <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000528e:	e1842d83          	lw	s11,-488(s0)
    80005292:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005296:	f80c03e3          	beqz	s8,8000521c <exec+0x306>
    8000529a:	8a62                	mv	s4,s8
    8000529c:	4901                	li	s2,0
    8000529e:	b345                	j	8000503e <exec+0x128>

00000000800052a0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052a0:	7179                	addi	sp,sp,-48
    800052a2:	f406                	sd	ra,40(sp)
    800052a4:	f022                	sd	s0,32(sp)
    800052a6:	ec26                	sd	s1,24(sp)
    800052a8:	e84a                	sd	s2,16(sp)
    800052aa:	1800                	addi	s0,sp,48
    800052ac:	892e                	mv	s2,a1
    800052ae:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800052b0:	fdc40593          	addi	a1,s0,-36
    800052b4:	ffffe097          	auipc	ra,0xffffe
    800052b8:	bae080e7          	jalr	-1106(ra) # 80002e62 <argint>
    800052bc:	04054063          	bltz	a0,800052fc <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052c0:	fdc42703          	lw	a4,-36(s0)
    800052c4:	47bd                	li	a5,15
    800052c6:	02e7ed63          	bltu	a5,a4,80005300 <argfd+0x60>
    800052ca:	ffffd097          	auipc	ra,0xffffd
    800052ce:	96e080e7          	jalr	-1682(ra) # 80001c38 <myproc>
    800052d2:	fdc42703          	lw	a4,-36(s0)
    800052d6:	01a70793          	addi	a5,a4,26
    800052da:	078e                	slli	a5,a5,0x3
    800052dc:	953e                	add	a0,a0,a5
    800052de:	611c                	ld	a5,0(a0)
    800052e0:	c395                	beqz	a5,80005304 <argfd+0x64>
    return -1;
  if(pfd)
    800052e2:	00090463          	beqz	s2,800052ea <argfd+0x4a>
    *pfd = fd;
    800052e6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052ea:	4501                	li	a0,0
  if(pf)
    800052ec:	c091                	beqz	s1,800052f0 <argfd+0x50>
    *pf = f;
    800052ee:	e09c                	sd	a5,0(s1)
}
    800052f0:	70a2                	ld	ra,40(sp)
    800052f2:	7402                	ld	s0,32(sp)
    800052f4:	64e2                	ld	s1,24(sp)
    800052f6:	6942                	ld	s2,16(sp)
    800052f8:	6145                	addi	sp,sp,48
    800052fa:	8082                	ret
    return -1;
    800052fc:	557d                	li	a0,-1
    800052fe:	bfcd                	j	800052f0 <argfd+0x50>
    return -1;
    80005300:	557d                	li	a0,-1
    80005302:	b7fd                	j	800052f0 <argfd+0x50>
    80005304:	557d                	li	a0,-1
    80005306:	b7ed                	j	800052f0 <argfd+0x50>

0000000080005308 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005308:	1101                	addi	sp,sp,-32
    8000530a:	ec06                	sd	ra,24(sp)
    8000530c:	e822                	sd	s0,16(sp)
    8000530e:	e426                	sd	s1,8(sp)
    80005310:	1000                	addi	s0,sp,32
    80005312:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005314:	ffffd097          	auipc	ra,0xffffd
    80005318:	924080e7          	jalr	-1756(ra) # 80001c38 <myproc>
    8000531c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000531e:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005322:	4501                	li	a0,0
    80005324:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005326:	6398                	ld	a4,0(a5)
    80005328:	cb19                	beqz	a4,8000533e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000532a:	2505                	addiw	a0,a0,1
    8000532c:	07a1                	addi	a5,a5,8
    8000532e:	fed51ce3          	bne	a0,a3,80005326 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005332:	557d                	li	a0,-1
}
    80005334:	60e2                	ld	ra,24(sp)
    80005336:	6442                	ld	s0,16(sp)
    80005338:	64a2                	ld	s1,8(sp)
    8000533a:	6105                	addi	sp,sp,32
    8000533c:	8082                	ret
      p->ofile[fd] = f;
    8000533e:	01a50793          	addi	a5,a0,26
    80005342:	078e                	slli	a5,a5,0x3
    80005344:	963e                	add	a2,a2,a5
    80005346:	e204                	sd	s1,0(a2)
      return fd;
    80005348:	b7f5                	j	80005334 <fdalloc+0x2c>

000000008000534a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000534a:	715d                	addi	sp,sp,-80
    8000534c:	e486                	sd	ra,72(sp)
    8000534e:	e0a2                	sd	s0,64(sp)
    80005350:	fc26                	sd	s1,56(sp)
    80005352:	f84a                	sd	s2,48(sp)
    80005354:	f44e                	sd	s3,40(sp)
    80005356:	f052                	sd	s4,32(sp)
    80005358:	ec56                	sd	s5,24(sp)
    8000535a:	0880                	addi	s0,sp,80
    8000535c:	89ae                	mv	s3,a1
    8000535e:	8ab2                	mv	s5,a2
    80005360:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005362:	fb040593          	addi	a1,s0,-80
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	e40080e7          	jalr	-448(ra) # 800041a6 <nameiparent>
    8000536e:	892a                	mv	s2,a0
    80005370:	12050f63          	beqz	a0,800054ae <create+0x164>
    return 0;

  ilock(dp);
    80005374:	ffffe097          	auipc	ra,0xffffe
    80005378:	660080e7          	jalr	1632(ra) # 800039d4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000537c:	4601                	li	a2,0
    8000537e:	fb040593          	addi	a1,s0,-80
    80005382:	854a                	mv	a0,s2
    80005384:	fffff097          	auipc	ra,0xfffff
    80005388:	b32080e7          	jalr	-1230(ra) # 80003eb6 <dirlookup>
    8000538c:	84aa                	mv	s1,a0
    8000538e:	c921                	beqz	a0,800053de <create+0x94>
    iunlockput(dp);
    80005390:	854a                	mv	a0,s2
    80005392:	fffff097          	auipc	ra,0xfffff
    80005396:	8a4080e7          	jalr	-1884(ra) # 80003c36 <iunlockput>
    ilock(ip);
    8000539a:	8526                	mv	a0,s1
    8000539c:	ffffe097          	auipc	ra,0xffffe
    800053a0:	638080e7          	jalr	1592(ra) # 800039d4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053a4:	2981                	sext.w	s3,s3
    800053a6:	4789                	li	a5,2
    800053a8:	02f99463          	bne	s3,a5,800053d0 <create+0x86>
    800053ac:	0444d783          	lhu	a5,68(s1)
    800053b0:	37f9                	addiw	a5,a5,-2
    800053b2:	17c2                	slli	a5,a5,0x30
    800053b4:	93c1                	srli	a5,a5,0x30
    800053b6:	4705                	li	a4,1
    800053b8:	00f76c63          	bltu	a4,a5,800053d0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800053bc:	8526                	mv	a0,s1
    800053be:	60a6                	ld	ra,72(sp)
    800053c0:	6406                	ld	s0,64(sp)
    800053c2:	74e2                	ld	s1,56(sp)
    800053c4:	7942                	ld	s2,48(sp)
    800053c6:	79a2                	ld	s3,40(sp)
    800053c8:	7a02                	ld	s4,32(sp)
    800053ca:	6ae2                	ld	s5,24(sp)
    800053cc:	6161                	addi	sp,sp,80
    800053ce:	8082                	ret
    iunlockput(ip);
    800053d0:	8526                	mv	a0,s1
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	864080e7          	jalr	-1948(ra) # 80003c36 <iunlockput>
    return 0;
    800053da:	4481                	li	s1,0
    800053dc:	b7c5                	j	800053bc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800053de:	85ce                	mv	a1,s3
    800053e0:	00092503          	lw	a0,0(s2)
    800053e4:	ffffe097          	auipc	ra,0xffffe
    800053e8:	458080e7          	jalr	1112(ra) # 8000383c <ialloc>
    800053ec:	84aa                	mv	s1,a0
    800053ee:	c529                	beqz	a0,80005438 <create+0xee>
  ilock(ip);
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	5e4080e7          	jalr	1508(ra) # 800039d4 <ilock>
  ip->major = major;
    800053f8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800053fc:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005400:	4785                	li	a5,1
    80005402:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005406:	8526                	mv	a0,s1
    80005408:	ffffe097          	auipc	ra,0xffffe
    8000540c:	502080e7          	jalr	1282(ra) # 8000390a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005410:	2981                	sext.w	s3,s3
    80005412:	4785                	li	a5,1
    80005414:	02f98a63          	beq	s3,a5,80005448 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005418:	40d0                	lw	a2,4(s1)
    8000541a:	fb040593          	addi	a1,s0,-80
    8000541e:	854a                	mv	a0,s2
    80005420:	fffff097          	auipc	ra,0xfffff
    80005424:	ca6080e7          	jalr	-858(ra) # 800040c6 <dirlink>
    80005428:	06054b63          	bltz	a0,8000549e <create+0x154>
  iunlockput(dp);
    8000542c:	854a                	mv	a0,s2
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	808080e7          	jalr	-2040(ra) # 80003c36 <iunlockput>
  return ip;
    80005436:	b759                	j	800053bc <create+0x72>
    panic("create: ialloc");
    80005438:	00003517          	auipc	a0,0x3
    8000543c:	38850513          	addi	a0,a0,904 # 800087c0 <syscalls+0x2b0>
    80005440:	ffffb097          	auipc	ra,0xffffb
    80005444:	108080e7          	jalr	264(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005448:	04a95783          	lhu	a5,74(s2)
    8000544c:	2785                	addiw	a5,a5,1
    8000544e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005452:	854a                	mv	a0,s2
    80005454:	ffffe097          	auipc	ra,0xffffe
    80005458:	4b6080e7          	jalr	1206(ra) # 8000390a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000545c:	40d0                	lw	a2,4(s1)
    8000545e:	00003597          	auipc	a1,0x3
    80005462:	37258593          	addi	a1,a1,882 # 800087d0 <syscalls+0x2c0>
    80005466:	8526                	mv	a0,s1
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	c5e080e7          	jalr	-930(ra) # 800040c6 <dirlink>
    80005470:	00054f63          	bltz	a0,8000548e <create+0x144>
    80005474:	00492603          	lw	a2,4(s2)
    80005478:	00003597          	auipc	a1,0x3
    8000547c:	36058593          	addi	a1,a1,864 # 800087d8 <syscalls+0x2c8>
    80005480:	8526                	mv	a0,s1
    80005482:	fffff097          	auipc	ra,0xfffff
    80005486:	c44080e7          	jalr	-956(ra) # 800040c6 <dirlink>
    8000548a:	f80557e3          	bgez	a0,80005418 <create+0xce>
      panic("create dots");
    8000548e:	00003517          	auipc	a0,0x3
    80005492:	35250513          	addi	a0,a0,850 # 800087e0 <syscalls+0x2d0>
    80005496:	ffffb097          	auipc	ra,0xffffb
    8000549a:	0b2080e7          	jalr	178(ra) # 80000548 <panic>
    panic("create: dirlink");
    8000549e:	00003517          	auipc	a0,0x3
    800054a2:	35250513          	addi	a0,a0,850 # 800087f0 <syscalls+0x2e0>
    800054a6:	ffffb097          	auipc	ra,0xffffb
    800054aa:	0a2080e7          	jalr	162(ra) # 80000548 <panic>
    return 0;
    800054ae:	84aa                	mv	s1,a0
    800054b0:	b731                	j	800053bc <create+0x72>

00000000800054b2 <sys_dup>:
{
    800054b2:	7179                	addi	sp,sp,-48
    800054b4:	f406                	sd	ra,40(sp)
    800054b6:	f022                	sd	s0,32(sp)
    800054b8:	ec26                	sd	s1,24(sp)
    800054ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054bc:	fd840613          	addi	a2,s0,-40
    800054c0:	4581                	li	a1,0
    800054c2:	4501                	li	a0,0
    800054c4:	00000097          	auipc	ra,0x0
    800054c8:	ddc080e7          	jalr	-548(ra) # 800052a0 <argfd>
    return -1;
    800054cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054ce:	02054363          	bltz	a0,800054f4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800054d2:	fd843503          	ld	a0,-40(s0)
    800054d6:	00000097          	auipc	ra,0x0
    800054da:	e32080e7          	jalr	-462(ra) # 80005308 <fdalloc>
    800054de:	84aa                	mv	s1,a0
    return -1;
    800054e0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800054e2:	00054963          	bltz	a0,800054f4 <sys_dup+0x42>
  filedup(f);
    800054e6:	fd843503          	ld	a0,-40(s0)
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	32a080e7          	jalr	810(ra) # 80004814 <filedup>
  return fd;
    800054f2:	87a6                	mv	a5,s1
}
    800054f4:	853e                	mv	a0,a5
    800054f6:	70a2                	ld	ra,40(sp)
    800054f8:	7402                	ld	s0,32(sp)
    800054fa:	64e2                	ld	s1,24(sp)
    800054fc:	6145                	addi	sp,sp,48
    800054fe:	8082                	ret

0000000080005500 <sys_read>:
{
    80005500:	7179                	addi	sp,sp,-48
    80005502:	f406                	sd	ra,40(sp)
    80005504:	f022                	sd	s0,32(sp)
    80005506:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005508:	fe840613          	addi	a2,s0,-24
    8000550c:	4581                	li	a1,0
    8000550e:	4501                	li	a0,0
    80005510:	00000097          	auipc	ra,0x0
    80005514:	d90080e7          	jalr	-624(ra) # 800052a0 <argfd>
    return -1;
    80005518:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000551a:	04054163          	bltz	a0,8000555c <sys_read+0x5c>
    8000551e:	fe440593          	addi	a1,s0,-28
    80005522:	4509                	li	a0,2
    80005524:	ffffe097          	auipc	ra,0xffffe
    80005528:	93e080e7          	jalr	-1730(ra) # 80002e62 <argint>
    return -1;
    8000552c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000552e:	02054763          	bltz	a0,8000555c <sys_read+0x5c>
    80005532:	fd840593          	addi	a1,s0,-40
    80005536:	4505                	li	a0,1
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	94c080e7          	jalr	-1716(ra) # 80002e84 <argaddr>
    return -1;
    80005540:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005542:	00054d63          	bltz	a0,8000555c <sys_read+0x5c>
  return fileread(f, p, n);
    80005546:	fe442603          	lw	a2,-28(s0)
    8000554a:	fd843583          	ld	a1,-40(s0)
    8000554e:	fe843503          	ld	a0,-24(s0)
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	44e080e7          	jalr	1102(ra) # 800049a0 <fileread>
    8000555a:	87aa                	mv	a5,a0
}
    8000555c:	853e                	mv	a0,a5
    8000555e:	70a2                	ld	ra,40(sp)
    80005560:	7402                	ld	s0,32(sp)
    80005562:	6145                	addi	sp,sp,48
    80005564:	8082                	ret

0000000080005566 <sys_write>:
{
    80005566:	7179                	addi	sp,sp,-48
    80005568:	f406                	sd	ra,40(sp)
    8000556a:	f022                	sd	s0,32(sp)
    8000556c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000556e:	fe840613          	addi	a2,s0,-24
    80005572:	4581                	li	a1,0
    80005574:	4501                	li	a0,0
    80005576:	00000097          	auipc	ra,0x0
    8000557a:	d2a080e7          	jalr	-726(ra) # 800052a0 <argfd>
    return -1;
    8000557e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005580:	04054163          	bltz	a0,800055c2 <sys_write+0x5c>
    80005584:	fe440593          	addi	a1,s0,-28
    80005588:	4509                	li	a0,2
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	8d8080e7          	jalr	-1832(ra) # 80002e62 <argint>
    return -1;
    80005592:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005594:	02054763          	bltz	a0,800055c2 <sys_write+0x5c>
    80005598:	fd840593          	addi	a1,s0,-40
    8000559c:	4505                	li	a0,1
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	8e6080e7          	jalr	-1818(ra) # 80002e84 <argaddr>
    return -1;
    800055a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055a8:	00054d63          	bltz	a0,800055c2 <sys_write+0x5c>
  return filewrite(f, p, n);
    800055ac:	fe442603          	lw	a2,-28(s0)
    800055b0:	fd843583          	ld	a1,-40(s0)
    800055b4:	fe843503          	ld	a0,-24(s0)
    800055b8:	fffff097          	auipc	ra,0xfffff
    800055bc:	4aa080e7          	jalr	1194(ra) # 80004a62 <filewrite>
    800055c0:	87aa                	mv	a5,a0
}
    800055c2:	853e                	mv	a0,a5
    800055c4:	70a2                	ld	ra,40(sp)
    800055c6:	7402                	ld	s0,32(sp)
    800055c8:	6145                	addi	sp,sp,48
    800055ca:	8082                	ret

00000000800055cc <sys_close>:
{
    800055cc:	1101                	addi	sp,sp,-32
    800055ce:	ec06                	sd	ra,24(sp)
    800055d0:	e822                	sd	s0,16(sp)
    800055d2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055d4:	fe040613          	addi	a2,s0,-32
    800055d8:	fec40593          	addi	a1,s0,-20
    800055dc:	4501                	li	a0,0
    800055de:	00000097          	auipc	ra,0x0
    800055e2:	cc2080e7          	jalr	-830(ra) # 800052a0 <argfd>
    return -1;
    800055e6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800055e8:	02054463          	bltz	a0,80005610 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055ec:	ffffc097          	auipc	ra,0xffffc
    800055f0:	64c080e7          	jalr	1612(ra) # 80001c38 <myproc>
    800055f4:	fec42783          	lw	a5,-20(s0)
    800055f8:	07e9                	addi	a5,a5,26
    800055fa:	078e                	slli	a5,a5,0x3
    800055fc:	97aa                	add	a5,a5,a0
    800055fe:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005602:	fe043503          	ld	a0,-32(s0)
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	260080e7          	jalr	608(ra) # 80004866 <fileclose>
  return 0;
    8000560e:	4781                	li	a5,0
}
    80005610:	853e                	mv	a0,a5
    80005612:	60e2                	ld	ra,24(sp)
    80005614:	6442                	ld	s0,16(sp)
    80005616:	6105                	addi	sp,sp,32
    80005618:	8082                	ret

000000008000561a <sys_fstat>:
{
    8000561a:	1101                	addi	sp,sp,-32
    8000561c:	ec06                	sd	ra,24(sp)
    8000561e:	e822                	sd	s0,16(sp)
    80005620:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005622:	fe840613          	addi	a2,s0,-24
    80005626:	4581                	li	a1,0
    80005628:	4501                	li	a0,0
    8000562a:	00000097          	auipc	ra,0x0
    8000562e:	c76080e7          	jalr	-906(ra) # 800052a0 <argfd>
    return -1;
    80005632:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005634:	02054563          	bltz	a0,8000565e <sys_fstat+0x44>
    80005638:	fe040593          	addi	a1,s0,-32
    8000563c:	4505                	li	a0,1
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	846080e7          	jalr	-1978(ra) # 80002e84 <argaddr>
    return -1;
    80005646:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005648:	00054b63          	bltz	a0,8000565e <sys_fstat+0x44>
  return filestat(f, st);
    8000564c:	fe043583          	ld	a1,-32(s0)
    80005650:	fe843503          	ld	a0,-24(s0)
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	2da080e7          	jalr	730(ra) # 8000492e <filestat>
    8000565c:	87aa                	mv	a5,a0
}
    8000565e:	853e                	mv	a0,a5
    80005660:	60e2                	ld	ra,24(sp)
    80005662:	6442                	ld	s0,16(sp)
    80005664:	6105                	addi	sp,sp,32
    80005666:	8082                	ret

0000000080005668 <sys_link>:
{
    80005668:	7169                	addi	sp,sp,-304
    8000566a:	f606                	sd	ra,296(sp)
    8000566c:	f222                	sd	s0,288(sp)
    8000566e:	ee26                	sd	s1,280(sp)
    80005670:	ea4a                	sd	s2,272(sp)
    80005672:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005674:	08000613          	li	a2,128
    80005678:	ed040593          	addi	a1,s0,-304
    8000567c:	4501                	li	a0,0
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	828080e7          	jalr	-2008(ra) # 80002ea6 <argstr>
    return -1;
    80005686:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005688:	10054e63          	bltz	a0,800057a4 <sys_link+0x13c>
    8000568c:	08000613          	li	a2,128
    80005690:	f5040593          	addi	a1,s0,-176
    80005694:	4505                	li	a0,1
    80005696:	ffffe097          	auipc	ra,0xffffe
    8000569a:	810080e7          	jalr	-2032(ra) # 80002ea6 <argstr>
    return -1;
    8000569e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056a0:	10054263          	bltz	a0,800057a4 <sys_link+0x13c>
  begin_op();
    800056a4:	fffff097          	auipc	ra,0xfffff
    800056a8:	cf0080e7          	jalr	-784(ra) # 80004394 <begin_op>
  if((ip = namei(old)) == 0){
    800056ac:	ed040513          	addi	a0,s0,-304
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	ad8080e7          	jalr	-1320(ra) # 80004188 <namei>
    800056b8:	84aa                	mv	s1,a0
    800056ba:	c551                	beqz	a0,80005746 <sys_link+0xde>
  ilock(ip);
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	318080e7          	jalr	792(ra) # 800039d4 <ilock>
  if(ip->type == T_DIR){
    800056c4:	04449703          	lh	a4,68(s1)
    800056c8:	4785                	li	a5,1
    800056ca:	08f70463          	beq	a4,a5,80005752 <sys_link+0xea>
  ip->nlink++;
    800056ce:	04a4d783          	lhu	a5,74(s1)
    800056d2:	2785                	addiw	a5,a5,1
    800056d4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056d8:	8526                	mv	a0,s1
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	230080e7          	jalr	560(ra) # 8000390a <iupdate>
  iunlock(ip);
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	3b2080e7          	jalr	946(ra) # 80003a96 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056ec:	fd040593          	addi	a1,s0,-48
    800056f0:	f5040513          	addi	a0,s0,-176
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	ab2080e7          	jalr	-1358(ra) # 800041a6 <nameiparent>
    800056fc:	892a                	mv	s2,a0
    800056fe:	c935                	beqz	a0,80005772 <sys_link+0x10a>
  ilock(dp);
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	2d4080e7          	jalr	724(ra) # 800039d4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005708:	00092703          	lw	a4,0(s2)
    8000570c:	409c                	lw	a5,0(s1)
    8000570e:	04f71d63          	bne	a4,a5,80005768 <sys_link+0x100>
    80005712:	40d0                	lw	a2,4(s1)
    80005714:	fd040593          	addi	a1,s0,-48
    80005718:	854a                	mv	a0,s2
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	9ac080e7          	jalr	-1620(ra) # 800040c6 <dirlink>
    80005722:	04054363          	bltz	a0,80005768 <sys_link+0x100>
  iunlockput(dp);
    80005726:	854a                	mv	a0,s2
    80005728:	ffffe097          	auipc	ra,0xffffe
    8000572c:	50e080e7          	jalr	1294(ra) # 80003c36 <iunlockput>
  iput(ip);
    80005730:	8526                	mv	a0,s1
    80005732:	ffffe097          	auipc	ra,0xffffe
    80005736:	45c080e7          	jalr	1116(ra) # 80003b8e <iput>
  end_op();
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	cda080e7          	jalr	-806(ra) # 80004414 <end_op>
  return 0;
    80005742:	4781                	li	a5,0
    80005744:	a085                	j	800057a4 <sys_link+0x13c>
    end_op();
    80005746:	fffff097          	auipc	ra,0xfffff
    8000574a:	cce080e7          	jalr	-818(ra) # 80004414 <end_op>
    return -1;
    8000574e:	57fd                	li	a5,-1
    80005750:	a891                	j	800057a4 <sys_link+0x13c>
    iunlockput(ip);
    80005752:	8526                	mv	a0,s1
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	4e2080e7          	jalr	1250(ra) # 80003c36 <iunlockput>
    end_op();
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	cb8080e7          	jalr	-840(ra) # 80004414 <end_op>
    return -1;
    80005764:	57fd                	li	a5,-1
    80005766:	a83d                	j	800057a4 <sys_link+0x13c>
    iunlockput(dp);
    80005768:	854a                	mv	a0,s2
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	4cc080e7          	jalr	1228(ra) # 80003c36 <iunlockput>
  ilock(ip);
    80005772:	8526                	mv	a0,s1
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	260080e7          	jalr	608(ra) # 800039d4 <ilock>
  ip->nlink--;
    8000577c:	04a4d783          	lhu	a5,74(s1)
    80005780:	37fd                	addiw	a5,a5,-1
    80005782:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005786:	8526                	mv	a0,s1
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	182080e7          	jalr	386(ra) # 8000390a <iupdate>
  iunlockput(ip);
    80005790:	8526                	mv	a0,s1
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	4a4080e7          	jalr	1188(ra) # 80003c36 <iunlockput>
  end_op();
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	c7a080e7          	jalr	-902(ra) # 80004414 <end_op>
  return -1;
    800057a2:	57fd                	li	a5,-1
}
    800057a4:	853e                	mv	a0,a5
    800057a6:	70b2                	ld	ra,296(sp)
    800057a8:	7412                	ld	s0,288(sp)
    800057aa:	64f2                	ld	s1,280(sp)
    800057ac:	6952                	ld	s2,272(sp)
    800057ae:	6155                	addi	sp,sp,304
    800057b0:	8082                	ret

00000000800057b2 <sys_unlink>:
{
    800057b2:	7151                	addi	sp,sp,-240
    800057b4:	f586                	sd	ra,232(sp)
    800057b6:	f1a2                	sd	s0,224(sp)
    800057b8:	eda6                	sd	s1,216(sp)
    800057ba:	e9ca                	sd	s2,208(sp)
    800057bc:	e5ce                	sd	s3,200(sp)
    800057be:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057c0:	08000613          	li	a2,128
    800057c4:	f3040593          	addi	a1,s0,-208
    800057c8:	4501                	li	a0,0
    800057ca:	ffffd097          	auipc	ra,0xffffd
    800057ce:	6dc080e7          	jalr	1756(ra) # 80002ea6 <argstr>
    800057d2:	18054163          	bltz	a0,80005954 <sys_unlink+0x1a2>
  begin_op();
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	bbe080e7          	jalr	-1090(ra) # 80004394 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057de:	fb040593          	addi	a1,s0,-80
    800057e2:	f3040513          	addi	a0,s0,-208
    800057e6:	fffff097          	auipc	ra,0xfffff
    800057ea:	9c0080e7          	jalr	-1600(ra) # 800041a6 <nameiparent>
    800057ee:	84aa                	mv	s1,a0
    800057f0:	c979                	beqz	a0,800058c6 <sys_unlink+0x114>
  ilock(dp);
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	1e2080e7          	jalr	482(ra) # 800039d4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057fa:	00003597          	auipc	a1,0x3
    800057fe:	fd658593          	addi	a1,a1,-42 # 800087d0 <syscalls+0x2c0>
    80005802:	fb040513          	addi	a0,s0,-80
    80005806:	ffffe097          	auipc	ra,0xffffe
    8000580a:	696080e7          	jalr	1686(ra) # 80003e9c <namecmp>
    8000580e:	14050a63          	beqz	a0,80005962 <sys_unlink+0x1b0>
    80005812:	00003597          	auipc	a1,0x3
    80005816:	fc658593          	addi	a1,a1,-58 # 800087d8 <syscalls+0x2c8>
    8000581a:	fb040513          	addi	a0,s0,-80
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	67e080e7          	jalr	1662(ra) # 80003e9c <namecmp>
    80005826:	12050e63          	beqz	a0,80005962 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000582a:	f2c40613          	addi	a2,s0,-212
    8000582e:	fb040593          	addi	a1,s0,-80
    80005832:	8526                	mv	a0,s1
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	682080e7          	jalr	1666(ra) # 80003eb6 <dirlookup>
    8000583c:	892a                	mv	s2,a0
    8000583e:	12050263          	beqz	a0,80005962 <sys_unlink+0x1b0>
  ilock(ip);
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	192080e7          	jalr	402(ra) # 800039d4 <ilock>
  if(ip->nlink < 1)
    8000584a:	04a91783          	lh	a5,74(s2)
    8000584e:	08f05263          	blez	a5,800058d2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005852:	04491703          	lh	a4,68(s2)
    80005856:	4785                	li	a5,1
    80005858:	08f70563          	beq	a4,a5,800058e2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000585c:	4641                	li	a2,16
    8000585e:	4581                	li	a1,0
    80005860:	fc040513          	addi	a0,s0,-64
    80005864:	ffffb097          	auipc	ra,0xffffb
    80005868:	61e080e7          	jalr	1566(ra) # 80000e82 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000586c:	4741                	li	a4,16
    8000586e:	f2c42683          	lw	a3,-212(s0)
    80005872:	fc040613          	addi	a2,s0,-64
    80005876:	4581                	li	a1,0
    80005878:	8526                	mv	a0,s1
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	506080e7          	jalr	1286(ra) # 80003d80 <writei>
    80005882:	47c1                	li	a5,16
    80005884:	0af51563          	bne	a0,a5,8000592e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005888:	04491703          	lh	a4,68(s2)
    8000588c:	4785                	li	a5,1
    8000588e:	0af70863          	beq	a4,a5,8000593e <sys_unlink+0x18c>
  iunlockput(dp);
    80005892:	8526                	mv	a0,s1
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	3a2080e7          	jalr	930(ra) # 80003c36 <iunlockput>
  ip->nlink--;
    8000589c:	04a95783          	lhu	a5,74(s2)
    800058a0:	37fd                	addiw	a5,a5,-1
    800058a2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058a6:	854a                	mv	a0,s2
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	062080e7          	jalr	98(ra) # 8000390a <iupdate>
  iunlockput(ip);
    800058b0:	854a                	mv	a0,s2
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	384080e7          	jalr	900(ra) # 80003c36 <iunlockput>
  end_op();
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	b5a080e7          	jalr	-1190(ra) # 80004414 <end_op>
  return 0;
    800058c2:	4501                	li	a0,0
    800058c4:	a84d                	j	80005976 <sys_unlink+0x1c4>
    end_op();
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	b4e080e7          	jalr	-1202(ra) # 80004414 <end_op>
    return -1;
    800058ce:	557d                	li	a0,-1
    800058d0:	a05d                	j	80005976 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058d2:	00003517          	auipc	a0,0x3
    800058d6:	f2e50513          	addi	a0,a0,-210 # 80008800 <syscalls+0x2f0>
    800058da:	ffffb097          	auipc	ra,0xffffb
    800058de:	c6e080e7          	jalr	-914(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058e2:	04c92703          	lw	a4,76(s2)
    800058e6:	02000793          	li	a5,32
    800058ea:	f6e7f9e3          	bgeu	a5,a4,8000585c <sys_unlink+0xaa>
    800058ee:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058f2:	4741                	li	a4,16
    800058f4:	86ce                	mv	a3,s3
    800058f6:	f1840613          	addi	a2,s0,-232
    800058fa:	4581                	li	a1,0
    800058fc:	854a                	mv	a0,s2
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	38a080e7          	jalr	906(ra) # 80003c88 <readi>
    80005906:	47c1                	li	a5,16
    80005908:	00f51b63          	bne	a0,a5,8000591e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000590c:	f1845783          	lhu	a5,-232(s0)
    80005910:	e7a1                	bnez	a5,80005958 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005912:	29c1                	addiw	s3,s3,16
    80005914:	04c92783          	lw	a5,76(s2)
    80005918:	fcf9ede3          	bltu	s3,a5,800058f2 <sys_unlink+0x140>
    8000591c:	b781                	j	8000585c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000591e:	00003517          	auipc	a0,0x3
    80005922:	efa50513          	addi	a0,a0,-262 # 80008818 <syscalls+0x308>
    80005926:	ffffb097          	auipc	ra,0xffffb
    8000592a:	c22080e7          	jalr	-990(ra) # 80000548 <panic>
    panic("unlink: writei");
    8000592e:	00003517          	auipc	a0,0x3
    80005932:	f0250513          	addi	a0,a0,-254 # 80008830 <syscalls+0x320>
    80005936:	ffffb097          	auipc	ra,0xffffb
    8000593a:	c12080e7          	jalr	-1006(ra) # 80000548 <panic>
    dp->nlink--;
    8000593e:	04a4d783          	lhu	a5,74(s1)
    80005942:	37fd                	addiw	a5,a5,-1
    80005944:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005948:	8526                	mv	a0,s1
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	fc0080e7          	jalr	-64(ra) # 8000390a <iupdate>
    80005952:	b781                	j	80005892 <sys_unlink+0xe0>
    return -1;
    80005954:	557d                	li	a0,-1
    80005956:	a005                	j	80005976 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005958:	854a                	mv	a0,s2
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	2dc080e7          	jalr	732(ra) # 80003c36 <iunlockput>
  iunlockput(dp);
    80005962:	8526                	mv	a0,s1
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	2d2080e7          	jalr	722(ra) # 80003c36 <iunlockput>
  end_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	aa8080e7          	jalr	-1368(ra) # 80004414 <end_op>
  return -1;
    80005974:	557d                	li	a0,-1
}
    80005976:	70ae                	ld	ra,232(sp)
    80005978:	740e                	ld	s0,224(sp)
    8000597a:	64ee                	ld	s1,216(sp)
    8000597c:	694e                	ld	s2,208(sp)
    8000597e:	69ae                	ld	s3,200(sp)
    80005980:	616d                	addi	sp,sp,240
    80005982:	8082                	ret

0000000080005984 <sys_open>:

uint64
sys_open(void)
{
    80005984:	7131                	addi	sp,sp,-192
    80005986:	fd06                	sd	ra,184(sp)
    80005988:	f922                	sd	s0,176(sp)
    8000598a:	f526                	sd	s1,168(sp)
    8000598c:	f14a                	sd	s2,160(sp)
    8000598e:	ed4e                	sd	s3,152(sp)
    80005990:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005992:	08000613          	li	a2,128
    80005996:	f5040593          	addi	a1,s0,-176
    8000599a:	4501                	li	a0,0
    8000599c:	ffffd097          	auipc	ra,0xffffd
    800059a0:	50a080e7          	jalr	1290(ra) # 80002ea6 <argstr>
    return -1;
    800059a4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059a6:	0c054163          	bltz	a0,80005a68 <sys_open+0xe4>
    800059aa:	f4c40593          	addi	a1,s0,-180
    800059ae:	4505                	li	a0,1
    800059b0:	ffffd097          	auipc	ra,0xffffd
    800059b4:	4b2080e7          	jalr	1202(ra) # 80002e62 <argint>
    800059b8:	0a054863          	bltz	a0,80005a68 <sys_open+0xe4>

  begin_op();
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	9d8080e7          	jalr	-1576(ra) # 80004394 <begin_op>

  if(omode & O_CREATE){
    800059c4:	f4c42783          	lw	a5,-180(s0)
    800059c8:	2007f793          	andi	a5,a5,512
    800059cc:	cbdd                	beqz	a5,80005a82 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059ce:	4681                	li	a3,0
    800059d0:	4601                	li	a2,0
    800059d2:	4589                	li	a1,2
    800059d4:	f5040513          	addi	a0,s0,-176
    800059d8:	00000097          	auipc	ra,0x0
    800059dc:	972080e7          	jalr	-1678(ra) # 8000534a <create>
    800059e0:	892a                	mv	s2,a0
    if(ip == 0){
    800059e2:	c959                	beqz	a0,80005a78 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059e4:	04491703          	lh	a4,68(s2)
    800059e8:	478d                	li	a5,3
    800059ea:	00f71763          	bne	a4,a5,800059f8 <sys_open+0x74>
    800059ee:	04695703          	lhu	a4,70(s2)
    800059f2:	47a5                	li	a5,9
    800059f4:	0ce7ec63          	bltu	a5,a4,80005acc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	db2080e7          	jalr	-590(ra) # 800047aa <filealloc>
    80005a00:	89aa                	mv	s3,a0
    80005a02:	10050263          	beqz	a0,80005b06 <sys_open+0x182>
    80005a06:	00000097          	auipc	ra,0x0
    80005a0a:	902080e7          	jalr	-1790(ra) # 80005308 <fdalloc>
    80005a0e:	84aa                	mv	s1,a0
    80005a10:	0e054663          	bltz	a0,80005afc <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a14:	04491703          	lh	a4,68(s2)
    80005a18:	478d                	li	a5,3
    80005a1a:	0cf70463          	beq	a4,a5,80005ae2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a1e:	4789                	li	a5,2
    80005a20:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a24:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a28:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a2c:	f4c42783          	lw	a5,-180(s0)
    80005a30:	0017c713          	xori	a4,a5,1
    80005a34:	8b05                	andi	a4,a4,1
    80005a36:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a3a:	0037f713          	andi	a4,a5,3
    80005a3e:	00e03733          	snez	a4,a4
    80005a42:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a46:	4007f793          	andi	a5,a5,1024
    80005a4a:	c791                	beqz	a5,80005a56 <sys_open+0xd2>
    80005a4c:	04491703          	lh	a4,68(s2)
    80005a50:	4789                	li	a5,2
    80005a52:	08f70f63          	beq	a4,a5,80005af0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a56:	854a                	mv	a0,s2
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	03e080e7          	jalr	62(ra) # 80003a96 <iunlock>
  end_op();
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	9b4080e7          	jalr	-1612(ra) # 80004414 <end_op>

  return fd;
}
    80005a68:	8526                	mv	a0,s1
    80005a6a:	70ea                	ld	ra,184(sp)
    80005a6c:	744a                	ld	s0,176(sp)
    80005a6e:	74aa                	ld	s1,168(sp)
    80005a70:	790a                	ld	s2,160(sp)
    80005a72:	69ea                	ld	s3,152(sp)
    80005a74:	6129                	addi	sp,sp,192
    80005a76:	8082                	ret
      end_op();
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	99c080e7          	jalr	-1636(ra) # 80004414 <end_op>
      return -1;
    80005a80:	b7e5                	j	80005a68 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a82:	f5040513          	addi	a0,s0,-176
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	702080e7          	jalr	1794(ra) # 80004188 <namei>
    80005a8e:	892a                	mv	s2,a0
    80005a90:	c905                	beqz	a0,80005ac0 <sys_open+0x13c>
    ilock(ip);
    80005a92:	ffffe097          	auipc	ra,0xffffe
    80005a96:	f42080e7          	jalr	-190(ra) # 800039d4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a9a:	04491703          	lh	a4,68(s2)
    80005a9e:	4785                	li	a5,1
    80005aa0:	f4f712e3          	bne	a4,a5,800059e4 <sys_open+0x60>
    80005aa4:	f4c42783          	lw	a5,-180(s0)
    80005aa8:	dba1                	beqz	a5,800059f8 <sys_open+0x74>
      iunlockput(ip);
    80005aaa:	854a                	mv	a0,s2
    80005aac:	ffffe097          	auipc	ra,0xffffe
    80005ab0:	18a080e7          	jalr	394(ra) # 80003c36 <iunlockput>
      end_op();
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	960080e7          	jalr	-1696(ra) # 80004414 <end_op>
      return -1;
    80005abc:	54fd                	li	s1,-1
    80005abe:	b76d                	j	80005a68 <sys_open+0xe4>
      end_op();
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	954080e7          	jalr	-1708(ra) # 80004414 <end_op>
      return -1;
    80005ac8:	54fd                	li	s1,-1
    80005aca:	bf79                	j	80005a68 <sys_open+0xe4>
    iunlockput(ip);
    80005acc:	854a                	mv	a0,s2
    80005ace:	ffffe097          	auipc	ra,0xffffe
    80005ad2:	168080e7          	jalr	360(ra) # 80003c36 <iunlockput>
    end_op();
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	93e080e7          	jalr	-1730(ra) # 80004414 <end_op>
    return -1;
    80005ade:	54fd                	li	s1,-1
    80005ae0:	b761                	j	80005a68 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ae2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ae6:	04691783          	lh	a5,70(s2)
    80005aea:	02f99223          	sh	a5,36(s3)
    80005aee:	bf2d                	j	80005a28 <sys_open+0xa4>
    itrunc(ip);
    80005af0:	854a                	mv	a0,s2
    80005af2:	ffffe097          	auipc	ra,0xffffe
    80005af6:	ff0080e7          	jalr	-16(ra) # 80003ae2 <itrunc>
    80005afa:	bfb1                	j	80005a56 <sys_open+0xd2>
      fileclose(f);
    80005afc:	854e                	mv	a0,s3
    80005afe:	fffff097          	auipc	ra,0xfffff
    80005b02:	d68080e7          	jalr	-664(ra) # 80004866 <fileclose>
    iunlockput(ip);
    80005b06:	854a                	mv	a0,s2
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	12e080e7          	jalr	302(ra) # 80003c36 <iunlockput>
    end_op();
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	904080e7          	jalr	-1788(ra) # 80004414 <end_op>
    return -1;
    80005b18:	54fd                	li	s1,-1
    80005b1a:	b7b9                	j	80005a68 <sys_open+0xe4>

0000000080005b1c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b1c:	7175                	addi	sp,sp,-144
    80005b1e:	e506                	sd	ra,136(sp)
    80005b20:	e122                	sd	s0,128(sp)
    80005b22:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	870080e7          	jalr	-1936(ra) # 80004394 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b2c:	08000613          	li	a2,128
    80005b30:	f7040593          	addi	a1,s0,-144
    80005b34:	4501                	li	a0,0
    80005b36:	ffffd097          	auipc	ra,0xffffd
    80005b3a:	370080e7          	jalr	880(ra) # 80002ea6 <argstr>
    80005b3e:	02054963          	bltz	a0,80005b70 <sys_mkdir+0x54>
    80005b42:	4681                	li	a3,0
    80005b44:	4601                	li	a2,0
    80005b46:	4585                	li	a1,1
    80005b48:	f7040513          	addi	a0,s0,-144
    80005b4c:	fffff097          	auipc	ra,0xfffff
    80005b50:	7fe080e7          	jalr	2046(ra) # 8000534a <create>
    80005b54:	cd11                	beqz	a0,80005b70 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	0e0080e7          	jalr	224(ra) # 80003c36 <iunlockput>
  end_op();
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	8b6080e7          	jalr	-1866(ra) # 80004414 <end_op>
  return 0;
    80005b66:	4501                	li	a0,0
}
    80005b68:	60aa                	ld	ra,136(sp)
    80005b6a:	640a                	ld	s0,128(sp)
    80005b6c:	6149                	addi	sp,sp,144
    80005b6e:	8082                	ret
    end_op();
    80005b70:	fffff097          	auipc	ra,0xfffff
    80005b74:	8a4080e7          	jalr	-1884(ra) # 80004414 <end_op>
    return -1;
    80005b78:	557d                	li	a0,-1
    80005b7a:	b7fd                	j	80005b68 <sys_mkdir+0x4c>

0000000080005b7c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b7c:	7135                	addi	sp,sp,-160
    80005b7e:	ed06                	sd	ra,152(sp)
    80005b80:	e922                	sd	s0,144(sp)
    80005b82:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	810080e7          	jalr	-2032(ra) # 80004394 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b8c:	08000613          	li	a2,128
    80005b90:	f7040593          	addi	a1,s0,-144
    80005b94:	4501                	li	a0,0
    80005b96:	ffffd097          	auipc	ra,0xffffd
    80005b9a:	310080e7          	jalr	784(ra) # 80002ea6 <argstr>
    80005b9e:	04054a63          	bltz	a0,80005bf2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005ba2:	f6c40593          	addi	a1,s0,-148
    80005ba6:	4505                	li	a0,1
    80005ba8:	ffffd097          	auipc	ra,0xffffd
    80005bac:	2ba080e7          	jalr	698(ra) # 80002e62 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bb0:	04054163          	bltz	a0,80005bf2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005bb4:	f6840593          	addi	a1,s0,-152
    80005bb8:	4509                	li	a0,2
    80005bba:	ffffd097          	auipc	ra,0xffffd
    80005bbe:	2a8080e7          	jalr	680(ra) # 80002e62 <argint>
     argint(1, &major) < 0 ||
    80005bc2:	02054863          	bltz	a0,80005bf2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bc6:	f6841683          	lh	a3,-152(s0)
    80005bca:	f6c41603          	lh	a2,-148(s0)
    80005bce:	458d                	li	a1,3
    80005bd0:	f7040513          	addi	a0,s0,-144
    80005bd4:	fffff097          	auipc	ra,0xfffff
    80005bd8:	776080e7          	jalr	1910(ra) # 8000534a <create>
     argint(2, &minor) < 0 ||
    80005bdc:	c919                	beqz	a0,80005bf2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bde:	ffffe097          	auipc	ra,0xffffe
    80005be2:	058080e7          	jalr	88(ra) # 80003c36 <iunlockput>
  end_op();
    80005be6:	fffff097          	auipc	ra,0xfffff
    80005bea:	82e080e7          	jalr	-2002(ra) # 80004414 <end_op>
  return 0;
    80005bee:	4501                	li	a0,0
    80005bf0:	a031                	j	80005bfc <sys_mknod+0x80>
    end_op();
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	822080e7          	jalr	-2014(ra) # 80004414 <end_op>
    return -1;
    80005bfa:	557d                	li	a0,-1
}
    80005bfc:	60ea                	ld	ra,152(sp)
    80005bfe:	644a                	ld	s0,144(sp)
    80005c00:	610d                	addi	sp,sp,160
    80005c02:	8082                	ret

0000000080005c04 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c04:	7135                	addi	sp,sp,-160
    80005c06:	ed06                	sd	ra,152(sp)
    80005c08:	e922                	sd	s0,144(sp)
    80005c0a:	e526                	sd	s1,136(sp)
    80005c0c:	e14a                	sd	s2,128(sp)
    80005c0e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c10:	ffffc097          	auipc	ra,0xffffc
    80005c14:	028080e7          	jalr	40(ra) # 80001c38 <myproc>
    80005c18:	892a                	mv	s2,a0
  
  begin_op();
    80005c1a:	ffffe097          	auipc	ra,0xffffe
    80005c1e:	77a080e7          	jalr	1914(ra) # 80004394 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c22:	08000613          	li	a2,128
    80005c26:	f6040593          	addi	a1,s0,-160
    80005c2a:	4501                	li	a0,0
    80005c2c:	ffffd097          	auipc	ra,0xffffd
    80005c30:	27a080e7          	jalr	634(ra) # 80002ea6 <argstr>
    80005c34:	04054b63          	bltz	a0,80005c8a <sys_chdir+0x86>
    80005c38:	f6040513          	addi	a0,s0,-160
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	54c080e7          	jalr	1356(ra) # 80004188 <namei>
    80005c44:	84aa                	mv	s1,a0
    80005c46:	c131                	beqz	a0,80005c8a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c48:	ffffe097          	auipc	ra,0xffffe
    80005c4c:	d8c080e7          	jalr	-628(ra) # 800039d4 <ilock>
  if(ip->type != T_DIR){
    80005c50:	04449703          	lh	a4,68(s1)
    80005c54:	4785                	li	a5,1
    80005c56:	04f71063          	bne	a4,a5,80005c96 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c5a:	8526                	mv	a0,s1
    80005c5c:	ffffe097          	auipc	ra,0xffffe
    80005c60:	e3a080e7          	jalr	-454(ra) # 80003a96 <iunlock>
  iput(p->cwd);
    80005c64:	15093503          	ld	a0,336(s2)
    80005c68:	ffffe097          	auipc	ra,0xffffe
    80005c6c:	f26080e7          	jalr	-218(ra) # 80003b8e <iput>
  end_op();
    80005c70:	ffffe097          	auipc	ra,0xffffe
    80005c74:	7a4080e7          	jalr	1956(ra) # 80004414 <end_op>
  p->cwd = ip;
    80005c78:	14993823          	sd	s1,336(s2)
  return 0;
    80005c7c:	4501                	li	a0,0
}
    80005c7e:	60ea                	ld	ra,152(sp)
    80005c80:	644a                	ld	s0,144(sp)
    80005c82:	64aa                	ld	s1,136(sp)
    80005c84:	690a                	ld	s2,128(sp)
    80005c86:	610d                	addi	sp,sp,160
    80005c88:	8082                	ret
    end_op();
    80005c8a:	ffffe097          	auipc	ra,0xffffe
    80005c8e:	78a080e7          	jalr	1930(ra) # 80004414 <end_op>
    return -1;
    80005c92:	557d                	li	a0,-1
    80005c94:	b7ed                	j	80005c7e <sys_chdir+0x7a>
    iunlockput(ip);
    80005c96:	8526                	mv	a0,s1
    80005c98:	ffffe097          	auipc	ra,0xffffe
    80005c9c:	f9e080e7          	jalr	-98(ra) # 80003c36 <iunlockput>
    end_op();
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	774080e7          	jalr	1908(ra) # 80004414 <end_op>
    return -1;
    80005ca8:	557d                	li	a0,-1
    80005caa:	bfd1                	j	80005c7e <sys_chdir+0x7a>

0000000080005cac <sys_exec>:

uint64
sys_exec(void)
{
    80005cac:	7145                	addi	sp,sp,-464
    80005cae:	e786                	sd	ra,456(sp)
    80005cb0:	e3a2                	sd	s0,448(sp)
    80005cb2:	ff26                	sd	s1,440(sp)
    80005cb4:	fb4a                	sd	s2,432(sp)
    80005cb6:	f74e                	sd	s3,424(sp)
    80005cb8:	f352                	sd	s4,416(sp)
    80005cba:	ef56                	sd	s5,408(sp)
    80005cbc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cbe:	08000613          	li	a2,128
    80005cc2:	f4040593          	addi	a1,s0,-192
    80005cc6:	4501                	li	a0,0
    80005cc8:	ffffd097          	auipc	ra,0xffffd
    80005ccc:	1de080e7          	jalr	478(ra) # 80002ea6 <argstr>
    return -1;
    80005cd0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cd2:	0c054a63          	bltz	a0,80005da6 <sys_exec+0xfa>
    80005cd6:	e3840593          	addi	a1,s0,-456
    80005cda:	4505                	li	a0,1
    80005cdc:	ffffd097          	auipc	ra,0xffffd
    80005ce0:	1a8080e7          	jalr	424(ra) # 80002e84 <argaddr>
    80005ce4:	0c054163          	bltz	a0,80005da6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ce8:	10000613          	li	a2,256
    80005cec:	4581                	li	a1,0
    80005cee:	e4040513          	addi	a0,s0,-448
    80005cf2:	ffffb097          	auipc	ra,0xffffb
    80005cf6:	190080e7          	jalr	400(ra) # 80000e82 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005cfa:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cfe:	89a6                	mv	s3,s1
    80005d00:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d02:	02000a13          	li	s4,32
    80005d06:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d0a:	00391513          	slli	a0,s2,0x3
    80005d0e:	e3040593          	addi	a1,s0,-464
    80005d12:	e3843783          	ld	a5,-456(s0)
    80005d16:	953e                	add	a0,a0,a5
    80005d18:	ffffd097          	auipc	ra,0xffffd
    80005d1c:	0b0080e7          	jalr	176(ra) # 80002dc8 <fetchaddr>
    80005d20:	02054a63          	bltz	a0,80005d54 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005d24:	e3043783          	ld	a5,-464(s0)
    80005d28:	c3b9                	beqz	a5,80005d6e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d2a:	ffffb097          	auipc	ra,0xffffb
    80005d2e:	eae080e7          	jalr	-338(ra) # 80000bd8 <kalloc>
    80005d32:	85aa                	mv	a1,a0
    80005d34:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d38:	cd11                	beqz	a0,80005d54 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d3a:	6605                	lui	a2,0x1
    80005d3c:	e3043503          	ld	a0,-464(s0)
    80005d40:	ffffd097          	auipc	ra,0xffffd
    80005d44:	0da080e7          	jalr	218(ra) # 80002e1a <fetchstr>
    80005d48:	00054663          	bltz	a0,80005d54 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d4c:	0905                	addi	s2,s2,1
    80005d4e:	09a1                	addi	s3,s3,8
    80005d50:	fb491be3          	bne	s2,s4,80005d06 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d54:	10048913          	addi	s2,s1,256
    80005d58:	6088                	ld	a0,0(s1)
    80005d5a:	c529                	beqz	a0,80005da4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005d5c:	ffffb097          	auipc	ra,0xffffb
    80005d60:	cc8080e7          	jalr	-824(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d64:	04a1                	addi	s1,s1,8
    80005d66:	ff2499e3          	bne	s1,s2,80005d58 <sys_exec+0xac>
  return -1;
    80005d6a:	597d                	li	s2,-1
    80005d6c:	a82d                	j	80005da6 <sys_exec+0xfa>
      argv[i] = 0;
    80005d6e:	0a8e                	slli	s5,s5,0x3
    80005d70:	fc040793          	addi	a5,s0,-64
    80005d74:	9abe                	add	s5,s5,a5
    80005d76:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d7a:	e4040593          	addi	a1,s0,-448
    80005d7e:	f4040513          	addi	a0,s0,-192
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	194080e7          	jalr	404(ra) # 80004f16 <exec>
    80005d8a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d8c:	10048993          	addi	s3,s1,256
    80005d90:	6088                	ld	a0,0(s1)
    80005d92:	c911                	beqz	a0,80005da6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d94:	ffffb097          	auipc	ra,0xffffb
    80005d98:	c90080e7          	jalr	-880(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d9c:	04a1                	addi	s1,s1,8
    80005d9e:	ff3499e3          	bne	s1,s3,80005d90 <sys_exec+0xe4>
    80005da2:	a011                	j	80005da6 <sys_exec+0xfa>
  return -1;
    80005da4:	597d                	li	s2,-1
}
    80005da6:	854a                	mv	a0,s2
    80005da8:	60be                	ld	ra,456(sp)
    80005daa:	641e                	ld	s0,448(sp)
    80005dac:	74fa                	ld	s1,440(sp)
    80005dae:	795a                	ld	s2,432(sp)
    80005db0:	79ba                	ld	s3,424(sp)
    80005db2:	7a1a                	ld	s4,416(sp)
    80005db4:	6afa                	ld	s5,408(sp)
    80005db6:	6179                	addi	sp,sp,464
    80005db8:	8082                	ret

0000000080005dba <sys_pipe>:

uint64
sys_pipe(void)
{
    80005dba:	7139                	addi	sp,sp,-64
    80005dbc:	fc06                	sd	ra,56(sp)
    80005dbe:	f822                	sd	s0,48(sp)
    80005dc0:	f426                	sd	s1,40(sp)
    80005dc2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005dc4:	ffffc097          	auipc	ra,0xffffc
    80005dc8:	e74080e7          	jalr	-396(ra) # 80001c38 <myproc>
    80005dcc:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005dce:	fd840593          	addi	a1,s0,-40
    80005dd2:	4501                	li	a0,0
    80005dd4:	ffffd097          	auipc	ra,0xffffd
    80005dd8:	0b0080e7          	jalr	176(ra) # 80002e84 <argaddr>
    return -1;
    80005ddc:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005dde:	0e054063          	bltz	a0,80005ebe <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005de2:	fc840593          	addi	a1,s0,-56
    80005de6:	fd040513          	addi	a0,s0,-48
    80005dea:	fffff097          	auipc	ra,0xfffff
    80005dee:	dd2080e7          	jalr	-558(ra) # 80004bbc <pipealloc>
    return -1;
    80005df2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005df4:	0c054563          	bltz	a0,80005ebe <sys_pipe+0x104>
  fd0 = -1;
    80005df8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005dfc:	fd043503          	ld	a0,-48(s0)
    80005e00:	fffff097          	auipc	ra,0xfffff
    80005e04:	508080e7          	jalr	1288(ra) # 80005308 <fdalloc>
    80005e08:	fca42223          	sw	a0,-60(s0)
    80005e0c:	08054c63          	bltz	a0,80005ea4 <sys_pipe+0xea>
    80005e10:	fc843503          	ld	a0,-56(s0)
    80005e14:	fffff097          	auipc	ra,0xfffff
    80005e18:	4f4080e7          	jalr	1268(ra) # 80005308 <fdalloc>
    80005e1c:	fca42023          	sw	a0,-64(s0)
    80005e20:	06054863          	bltz	a0,80005e90 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e24:	4691                	li	a3,4
    80005e26:	fc440613          	addi	a2,s0,-60
    80005e2a:	fd843583          	ld	a1,-40(s0)
    80005e2e:	68a8                	ld	a0,80(s1)
    80005e30:	ffffc097          	auipc	ra,0xffffc
    80005e34:	9f0080e7          	jalr	-1552(ra) # 80001820 <copyout>
    80005e38:	02054063          	bltz	a0,80005e58 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e3c:	4691                	li	a3,4
    80005e3e:	fc040613          	addi	a2,s0,-64
    80005e42:	fd843583          	ld	a1,-40(s0)
    80005e46:	0591                	addi	a1,a1,4
    80005e48:	68a8                	ld	a0,80(s1)
    80005e4a:	ffffc097          	auipc	ra,0xffffc
    80005e4e:	9d6080e7          	jalr	-1578(ra) # 80001820 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e52:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e54:	06055563          	bgez	a0,80005ebe <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e58:	fc442783          	lw	a5,-60(s0)
    80005e5c:	07e9                	addi	a5,a5,26
    80005e5e:	078e                	slli	a5,a5,0x3
    80005e60:	97a6                	add	a5,a5,s1
    80005e62:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e66:	fc042503          	lw	a0,-64(s0)
    80005e6a:	0569                	addi	a0,a0,26
    80005e6c:	050e                	slli	a0,a0,0x3
    80005e6e:	9526                	add	a0,a0,s1
    80005e70:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e74:	fd043503          	ld	a0,-48(s0)
    80005e78:	fffff097          	auipc	ra,0xfffff
    80005e7c:	9ee080e7          	jalr	-1554(ra) # 80004866 <fileclose>
    fileclose(wf);
    80005e80:	fc843503          	ld	a0,-56(s0)
    80005e84:	fffff097          	auipc	ra,0xfffff
    80005e88:	9e2080e7          	jalr	-1566(ra) # 80004866 <fileclose>
    return -1;
    80005e8c:	57fd                	li	a5,-1
    80005e8e:	a805                	j	80005ebe <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e90:	fc442783          	lw	a5,-60(s0)
    80005e94:	0007c863          	bltz	a5,80005ea4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e98:	01a78513          	addi	a0,a5,26
    80005e9c:	050e                	slli	a0,a0,0x3
    80005e9e:	9526                	add	a0,a0,s1
    80005ea0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ea4:	fd043503          	ld	a0,-48(s0)
    80005ea8:	fffff097          	auipc	ra,0xfffff
    80005eac:	9be080e7          	jalr	-1602(ra) # 80004866 <fileclose>
    fileclose(wf);
    80005eb0:	fc843503          	ld	a0,-56(s0)
    80005eb4:	fffff097          	auipc	ra,0xfffff
    80005eb8:	9b2080e7          	jalr	-1614(ra) # 80004866 <fileclose>
    return -1;
    80005ebc:	57fd                	li	a5,-1
}
    80005ebe:	853e                	mv	a0,a5
    80005ec0:	70e2                	ld	ra,56(sp)
    80005ec2:	7442                	ld	s0,48(sp)
    80005ec4:	74a2                	ld	s1,40(sp)
    80005ec6:	6121                	addi	sp,sp,64
    80005ec8:	8082                	ret
    80005eca:	0000                	unimp
    80005ecc:	0000                	unimp
	...

0000000080005ed0 <kernelvec>:
    80005ed0:	7111                	addi	sp,sp,-256
    80005ed2:	e006                	sd	ra,0(sp)
    80005ed4:	e40a                	sd	sp,8(sp)
    80005ed6:	e80e                	sd	gp,16(sp)
    80005ed8:	ec12                	sd	tp,24(sp)
    80005eda:	f016                	sd	t0,32(sp)
    80005edc:	f41a                	sd	t1,40(sp)
    80005ede:	f81e                	sd	t2,48(sp)
    80005ee0:	fc22                	sd	s0,56(sp)
    80005ee2:	e0a6                	sd	s1,64(sp)
    80005ee4:	e4aa                	sd	a0,72(sp)
    80005ee6:	e8ae                	sd	a1,80(sp)
    80005ee8:	ecb2                	sd	a2,88(sp)
    80005eea:	f0b6                	sd	a3,96(sp)
    80005eec:	f4ba                	sd	a4,104(sp)
    80005eee:	f8be                	sd	a5,112(sp)
    80005ef0:	fcc2                	sd	a6,120(sp)
    80005ef2:	e146                	sd	a7,128(sp)
    80005ef4:	e54a                	sd	s2,136(sp)
    80005ef6:	e94e                	sd	s3,144(sp)
    80005ef8:	ed52                	sd	s4,152(sp)
    80005efa:	f156                	sd	s5,160(sp)
    80005efc:	f55a                	sd	s6,168(sp)
    80005efe:	f95e                	sd	s7,176(sp)
    80005f00:	fd62                	sd	s8,184(sp)
    80005f02:	e1e6                	sd	s9,192(sp)
    80005f04:	e5ea                	sd	s10,200(sp)
    80005f06:	e9ee                	sd	s11,208(sp)
    80005f08:	edf2                	sd	t3,216(sp)
    80005f0a:	f1f6                	sd	t4,224(sp)
    80005f0c:	f5fa                	sd	t5,232(sp)
    80005f0e:	f9fe                	sd	t6,240(sp)
    80005f10:	d85fc0ef          	jal	ra,80002c94 <kerneltrap>
    80005f14:	6082                	ld	ra,0(sp)
    80005f16:	6122                	ld	sp,8(sp)
    80005f18:	61c2                	ld	gp,16(sp)
    80005f1a:	7282                	ld	t0,32(sp)
    80005f1c:	7322                	ld	t1,40(sp)
    80005f1e:	73c2                	ld	t2,48(sp)
    80005f20:	7462                	ld	s0,56(sp)
    80005f22:	6486                	ld	s1,64(sp)
    80005f24:	6526                	ld	a0,72(sp)
    80005f26:	65c6                	ld	a1,80(sp)
    80005f28:	6666                	ld	a2,88(sp)
    80005f2a:	7686                	ld	a3,96(sp)
    80005f2c:	7726                	ld	a4,104(sp)
    80005f2e:	77c6                	ld	a5,112(sp)
    80005f30:	7866                	ld	a6,120(sp)
    80005f32:	688a                	ld	a7,128(sp)
    80005f34:	692a                	ld	s2,136(sp)
    80005f36:	69ca                	ld	s3,144(sp)
    80005f38:	6a6a                	ld	s4,152(sp)
    80005f3a:	7a8a                	ld	s5,160(sp)
    80005f3c:	7b2a                	ld	s6,168(sp)
    80005f3e:	7bca                	ld	s7,176(sp)
    80005f40:	7c6a                	ld	s8,184(sp)
    80005f42:	6c8e                	ld	s9,192(sp)
    80005f44:	6d2e                	ld	s10,200(sp)
    80005f46:	6dce                	ld	s11,208(sp)
    80005f48:	6e6e                	ld	t3,216(sp)
    80005f4a:	7e8e                	ld	t4,224(sp)
    80005f4c:	7f2e                	ld	t5,232(sp)
    80005f4e:	7fce                	ld	t6,240(sp)
    80005f50:	6111                	addi	sp,sp,256
    80005f52:	10200073          	sret
    80005f56:	00000013          	nop
    80005f5a:	00000013          	nop
    80005f5e:	0001                	nop

0000000080005f60 <timervec>:
    80005f60:	34051573          	csrrw	a0,mscratch,a0
    80005f64:	e10c                	sd	a1,0(a0)
    80005f66:	e510                	sd	a2,8(a0)
    80005f68:	e914                	sd	a3,16(a0)
    80005f6a:	710c                	ld	a1,32(a0)
    80005f6c:	7510                	ld	a2,40(a0)
    80005f6e:	6194                	ld	a3,0(a1)
    80005f70:	96b2                	add	a3,a3,a2
    80005f72:	e194                	sd	a3,0(a1)
    80005f74:	4589                	li	a1,2
    80005f76:	14459073          	csrw	sip,a1
    80005f7a:	6914                	ld	a3,16(a0)
    80005f7c:	6510                	ld	a2,8(a0)
    80005f7e:	610c                	ld	a1,0(a0)
    80005f80:	34051573          	csrrw	a0,mscratch,a0
    80005f84:	30200073          	mret
	...

0000000080005f8a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f8a:	1141                	addi	sp,sp,-16
    80005f8c:	e422                	sd	s0,8(sp)
    80005f8e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f90:	0c0007b7          	lui	a5,0xc000
    80005f94:	4705                	li	a4,1
    80005f96:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f98:	c3d8                	sw	a4,4(a5)
}
    80005f9a:	6422                	ld	s0,8(sp)
    80005f9c:	0141                	addi	sp,sp,16
    80005f9e:	8082                	ret

0000000080005fa0 <plicinithart>:

void
plicinithart(void)
{
    80005fa0:	1141                	addi	sp,sp,-16
    80005fa2:	e406                	sd	ra,8(sp)
    80005fa4:	e022                	sd	s0,0(sp)
    80005fa6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fa8:	ffffc097          	auipc	ra,0xffffc
    80005fac:	c64080e7          	jalr	-924(ra) # 80001c0c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fb0:	0085171b          	slliw	a4,a0,0x8
    80005fb4:	0c0027b7          	lui	a5,0xc002
    80005fb8:	97ba                	add	a5,a5,a4
    80005fba:	40200713          	li	a4,1026
    80005fbe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005fc2:	00d5151b          	slliw	a0,a0,0xd
    80005fc6:	0c2017b7          	lui	a5,0xc201
    80005fca:	953e                	add	a0,a0,a5
    80005fcc:	00052023          	sw	zero,0(a0)
}
    80005fd0:	60a2                	ld	ra,8(sp)
    80005fd2:	6402                	ld	s0,0(sp)
    80005fd4:	0141                	addi	sp,sp,16
    80005fd6:	8082                	ret

0000000080005fd8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fd8:	1141                	addi	sp,sp,-16
    80005fda:	e406                	sd	ra,8(sp)
    80005fdc:	e022                	sd	s0,0(sp)
    80005fde:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fe0:	ffffc097          	auipc	ra,0xffffc
    80005fe4:	c2c080e7          	jalr	-980(ra) # 80001c0c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fe8:	00d5179b          	slliw	a5,a0,0xd
    80005fec:	0c201537          	lui	a0,0xc201
    80005ff0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ff2:	4148                	lw	a0,4(a0)
    80005ff4:	60a2                	ld	ra,8(sp)
    80005ff6:	6402                	ld	s0,0(sp)
    80005ff8:	0141                	addi	sp,sp,16
    80005ffa:	8082                	ret

0000000080005ffc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ffc:	1101                	addi	sp,sp,-32
    80005ffe:	ec06                	sd	ra,24(sp)
    80006000:	e822                	sd	s0,16(sp)
    80006002:	e426                	sd	s1,8(sp)
    80006004:	1000                	addi	s0,sp,32
    80006006:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006008:	ffffc097          	auipc	ra,0xffffc
    8000600c:	c04080e7          	jalr	-1020(ra) # 80001c0c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006010:	00d5151b          	slliw	a0,a0,0xd
    80006014:	0c2017b7          	lui	a5,0xc201
    80006018:	97aa                	add	a5,a5,a0
    8000601a:	c3c4                	sw	s1,4(a5)
}
    8000601c:	60e2                	ld	ra,24(sp)
    8000601e:	6442                	ld	s0,16(sp)
    80006020:	64a2                	ld	s1,8(sp)
    80006022:	6105                	addi	sp,sp,32
    80006024:	8082                	ret

0000000080006026 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006026:	1141                	addi	sp,sp,-16
    80006028:	e406                	sd	ra,8(sp)
    8000602a:	e022                	sd	s0,0(sp)
    8000602c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000602e:	479d                	li	a5,7
    80006030:	04a7cc63          	blt	a5,a0,80006088 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80006034:	0001d797          	auipc	a5,0x1d
    80006038:	fcc78793          	addi	a5,a5,-52 # 80023000 <disk>
    8000603c:	00a78733          	add	a4,a5,a0
    80006040:	6789                	lui	a5,0x2
    80006042:	97ba                	add	a5,a5,a4
    80006044:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006048:	eba1                	bnez	a5,80006098 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    8000604a:	00451713          	slli	a4,a0,0x4
    8000604e:	0001f797          	auipc	a5,0x1f
    80006052:	fb27b783          	ld	a5,-78(a5) # 80025000 <disk+0x2000>
    80006056:	97ba                	add	a5,a5,a4
    80006058:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    8000605c:	0001d797          	auipc	a5,0x1d
    80006060:	fa478793          	addi	a5,a5,-92 # 80023000 <disk>
    80006064:	97aa                	add	a5,a5,a0
    80006066:	6509                	lui	a0,0x2
    80006068:	953e                	add	a0,a0,a5
    8000606a:	4785                	li	a5,1
    8000606c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006070:	0001f517          	auipc	a0,0x1f
    80006074:	fa850513          	addi	a0,a0,-88 # 80025018 <disk+0x2018>
    80006078:	ffffc097          	auipc	ra,0xffffc
    8000607c:	556080e7          	jalr	1366(ra) # 800025ce <wakeup>
}
    80006080:	60a2                	ld	ra,8(sp)
    80006082:	6402                	ld	s0,0(sp)
    80006084:	0141                	addi	sp,sp,16
    80006086:	8082                	ret
    panic("virtio_disk_intr 1");
    80006088:	00002517          	auipc	a0,0x2
    8000608c:	7b850513          	addi	a0,a0,1976 # 80008840 <syscalls+0x330>
    80006090:	ffffa097          	auipc	ra,0xffffa
    80006094:	4b8080e7          	jalr	1208(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80006098:	00002517          	auipc	a0,0x2
    8000609c:	7c050513          	addi	a0,a0,1984 # 80008858 <syscalls+0x348>
    800060a0:	ffffa097          	auipc	ra,0xffffa
    800060a4:	4a8080e7          	jalr	1192(ra) # 80000548 <panic>

00000000800060a8 <virtio_disk_init>:
{
    800060a8:	1101                	addi	sp,sp,-32
    800060aa:	ec06                	sd	ra,24(sp)
    800060ac:	e822                	sd	s0,16(sp)
    800060ae:	e426                	sd	s1,8(sp)
    800060b0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060b2:	00002597          	auipc	a1,0x2
    800060b6:	7be58593          	addi	a1,a1,1982 # 80008870 <syscalls+0x360>
    800060ba:	0001f517          	auipc	a0,0x1f
    800060be:	fee50513          	addi	a0,a0,-18 # 800250a8 <disk+0x20a8>
    800060c2:	ffffb097          	auipc	ra,0xffffb
    800060c6:	c34080e7          	jalr	-972(ra) # 80000cf6 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060ca:	100017b7          	lui	a5,0x10001
    800060ce:	4398                	lw	a4,0(a5)
    800060d0:	2701                	sext.w	a4,a4
    800060d2:	747277b7          	lui	a5,0x74727
    800060d6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060da:	0ef71163          	bne	a4,a5,800061bc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060de:	100017b7          	lui	a5,0x10001
    800060e2:	43dc                	lw	a5,4(a5)
    800060e4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060e6:	4705                	li	a4,1
    800060e8:	0ce79a63          	bne	a5,a4,800061bc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060ec:	100017b7          	lui	a5,0x10001
    800060f0:	479c                	lw	a5,8(a5)
    800060f2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060f4:	4709                	li	a4,2
    800060f6:	0ce79363          	bne	a5,a4,800061bc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060fa:	100017b7          	lui	a5,0x10001
    800060fe:	47d8                	lw	a4,12(a5)
    80006100:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006102:	554d47b7          	lui	a5,0x554d4
    80006106:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000610a:	0af71963          	bne	a4,a5,800061bc <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000610e:	100017b7          	lui	a5,0x10001
    80006112:	4705                	li	a4,1
    80006114:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006116:	470d                	li	a4,3
    80006118:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000611a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000611c:	c7ffe737          	lui	a4,0xc7ffe
    80006120:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80006124:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006126:	2701                	sext.w	a4,a4
    80006128:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000612a:	472d                	li	a4,11
    8000612c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000612e:	473d                	li	a4,15
    80006130:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006132:	6705                	lui	a4,0x1
    80006134:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006136:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000613a:	5bdc                	lw	a5,52(a5)
    8000613c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000613e:	c7d9                	beqz	a5,800061cc <virtio_disk_init+0x124>
  if(max < NUM)
    80006140:	471d                	li	a4,7
    80006142:	08f77d63          	bgeu	a4,a5,800061dc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006146:	100014b7          	lui	s1,0x10001
    8000614a:	47a1                	li	a5,8
    8000614c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000614e:	6609                	lui	a2,0x2
    80006150:	4581                	li	a1,0
    80006152:	0001d517          	auipc	a0,0x1d
    80006156:	eae50513          	addi	a0,a0,-338 # 80023000 <disk>
    8000615a:	ffffb097          	auipc	ra,0xffffb
    8000615e:	d28080e7          	jalr	-728(ra) # 80000e82 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006162:	0001d717          	auipc	a4,0x1d
    80006166:	e9e70713          	addi	a4,a4,-354 # 80023000 <disk>
    8000616a:	00c75793          	srli	a5,a4,0xc
    8000616e:	2781                	sext.w	a5,a5
    80006170:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006172:	0001f797          	auipc	a5,0x1f
    80006176:	e8e78793          	addi	a5,a5,-370 # 80025000 <disk+0x2000>
    8000617a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000617c:	0001d717          	auipc	a4,0x1d
    80006180:	f0470713          	addi	a4,a4,-252 # 80023080 <disk+0x80>
    80006184:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006186:	0001e717          	auipc	a4,0x1e
    8000618a:	e7a70713          	addi	a4,a4,-390 # 80024000 <disk+0x1000>
    8000618e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006190:	4705                	li	a4,1
    80006192:	00e78c23          	sb	a4,24(a5)
    80006196:	00e78ca3          	sb	a4,25(a5)
    8000619a:	00e78d23          	sb	a4,26(a5)
    8000619e:	00e78da3          	sb	a4,27(a5)
    800061a2:	00e78e23          	sb	a4,28(a5)
    800061a6:	00e78ea3          	sb	a4,29(a5)
    800061aa:	00e78f23          	sb	a4,30(a5)
    800061ae:	00e78fa3          	sb	a4,31(a5)
}
    800061b2:	60e2                	ld	ra,24(sp)
    800061b4:	6442                	ld	s0,16(sp)
    800061b6:	64a2                	ld	s1,8(sp)
    800061b8:	6105                	addi	sp,sp,32
    800061ba:	8082                	ret
    panic("could not find virtio disk");
    800061bc:	00002517          	auipc	a0,0x2
    800061c0:	6c450513          	addi	a0,a0,1732 # 80008880 <syscalls+0x370>
    800061c4:	ffffa097          	auipc	ra,0xffffa
    800061c8:	384080e7          	jalr	900(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    800061cc:	00002517          	auipc	a0,0x2
    800061d0:	6d450513          	addi	a0,a0,1748 # 800088a0 <syscalls+0x390>
    800061d4:	ffffa097          	auipc	ra,0xffffa
    800061d8:	374080e7          	jalr	884(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    800061dc:	00002517          	auipc	a0,0x2
    800061e0:	6e450513          	addi	a0,a0,1764 # 800088c0 <syscalls+0x3b0>
    800061e4:	ffffa097          	auipc	ra,0xffffa
    800061e8:	364080e7          	jalr	868(ra) # 80000548 <panic>

00000000800061ec <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061ec:	7119                	addi	sp,sp,-128
    800061ee:	fc86                	sd	ra,120(sp)
    800061f0:	f8a2                	sd	s0,112(sp)
    800061f2:	f4a6                	sd	s1,104(sp)
    800061f4:	f0ca                	sd	s2,96(sp)
    800061f6:	ecce                	sd	s3,88(sp)
    800061f8:	e8d2                	sd	s4,80(sp)
    800061fa:	e4d6                	sd	s5,72(sp)
    800061fc:	e0da                	sd	s6,64(sp)
    800061fe:	fc5e                	sd	s7,56(sp)
    80006200:	f862                	sd	s8,48(sp)
    80006202:	f466                	sd	s9,40(sp)
    80006204:	f06a                	sd	s10,32(sp)
    80006206:	0100                	addi	s0,sp,128
    80006208:	892a                	mv	s2,a0
    8000620a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000620c:	00c52c83          	lw	s9,12(a0)
    80006210:	001c9c9b          	slliw	s9,s9,0x1
    80006214:	1c82                	slli	s9,s9,0x20
    80006216:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000621a:	0001f517          	auipc	a0,0x1f
    8000621e:	e8e50513          	addi	a0,a0,-370 # 800250a8 <disk+0x20a8>
    80006222:	ffffb097          	auipc	ra,0xffffb
    80006226:	b64080e7          	jalr	-1180(ra) # 80000d86 <acquire>
  for(int i = 0; i < 3; i++){
    8000622a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000622c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000622e:	0001db97          	auipc	s7,0x1d
    80006232:	dd2b8b93          	addi	s7,s7,-558 # 80023000 <disk>
    80006236:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006238:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000623a:	8a4e                	mv	s4,s3
    8000623c:	a051                	j	800062c0 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000623e:	00fb86b3          	add	a3,s7,a5
    80006242:	96da                	add	a3,a3,s6
    80006244:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006248:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000624a:	0207c563          	bltz	a5,80006274 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000624e:	2485                	addiw	s1,s1,1
    80006250:	0711                	addi	a4,a4,4
    80006252:	23548d63          	beq	s1,s5,8000648c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006256:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006258:	0001f697          	auipc	a3,0x1f
    8000625c:	dc068693          	addi	a3,a3,-576 # 80025018 <disk+0x2018>
    80006260:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006262:	0006c583          	lbu	a1,0(a3)
    80006266:	fde1                	bnez	a1,8000623e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006268:	2785                	addiw	a5,a5,1
    8000626a:	0685                	addi	a3,a3,1
    8000626c:	ff879be3          	bne	a5,s8,80006262 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006270:	57fd                	li	a5,-1
    80006272:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006274:	02905a63          	blez	s1,800062a8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006278:	f9042503          	lw	a0,-112(s0)
    8000627c:	00000097          	auipc	ra,0x0
    80006280:	daa080e7          	jalr	-598(ra) # 80006026 <free_desc>
      for(int j = 0; j < i; j++)
    80006284:	4785                	li	a5,1
    80006286:	0297d163          	bge	a5,s1,800062a8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000628a:	f9442503          	lw	a0,-108(s0)
    8000628e:	00000097          	auipc	ra,0x0
    80006292:	d98080e7          	jalr	-616(ra) # 80006026 <free_desc>
      for(int j = 0; j < i; j++)
    80006296:	4789                	li	a5,2
    80006298:	0097d863          	bge	a5,s1,800062a8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000629c:	f9842503          	lw	a0,-104(s0)
    800062a0:	00000097          	auipc	ra,0x0
    800062a4:	d86080e7          	jalr	-634(ra) # 80006026 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062a8:	0001f597          	auipc	a1,0x1f
    800062ac:	e0058593          	addi	a1,a1,-512 # 800250a8 <disk+0x20a8>
    800062b0:	0001f517          	auipc	a0,0x1f
    800062b4:	d6850513          	addi	a0,a0,-664 # 80025018 <disk+0x2018>
    800062b8:	ffffc097          	auipc	ra,0xffffc
    800062bc:	190080e7          	jalr	400(ra) # 80002448 <sleep>
  for(int i = 0; i < 3; i++){
    800062c0:	f9040713          	addi	a4,s0,-112
    800062c4:	84ce                	mv	s1,s3
    800062c6:	bf41                	j	80006256 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    800062c8:	4785                	li	a5,1
    800062ca:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    800062ce:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    800062d2:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800062d6:	f9042983          	lw	s3,-112(s0)
    800062da:	00499493          	slli	s1,s3,0x4
    800062de:	0001fa17          	auipc	s4,0x1f
    800062e2:	d22a0a13          	addi	s4,s4,-734 # 80025000 <disk+0x2000>
    800062e6:	000a3a83          	ld	s5,0(s4)
    800062ea:	9aa6                	add	s5,s5,s1
    800062ec:	f8040513          	addi	a0,s0,-128
    800062f0:	ffffb097          	auipc	ra,0xffffb
    800062f4:	f66080e7          	jalr	-154(ra) # 80001256 <kvmpa>
    800062f8:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    800062fc:	000a3783          	ld	a5,0(s4)
    80006300:	97a6                	add	a5,a5,s1
    80006302:	4741                	li	a4,16
    80006304:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006306:	000a3783          	ld	a5,0(s4)
    8000630a:	97a6                	add	a5,a5,s1
    8000630c:	4705                	li	a4,1
    8000630e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006312:	f9442703          	lw	a4,-108(s0)
    80006316:	000a3783          	ld	a5,0(s4)
    8000631a:	97a6                	add	a5,a5,s1
    8000631c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006320:	0712                	slli	a4,a4,0x4
    80006322:	000a3783          	ld	a5,0(s4)
    80006326:	97ba                	add	a5,a5,a4
    80006328:	05890693          	addi	a3,s2,88
    8000632c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000632e:	000a3783          	ld	a5,0(s4)
    80006332:	97ba                	add	a5,a5,a4
    80006334:	40000693          	li	a3,1024
    80006338:	c794                	sw	a3,8(a5)
  if(write)
    8000633a:	100d0a63          	beqz	s10,8000644e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000633e:	0001f797          	auipc	a5,0x1f
    80006342:	cc27b783          	ld	a5,-830(a5) # 80025000 <disk+0x2000>
    80006346:	97ba                	add	a5,a5,a4
    80006348:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000634c:	0001d517          	auipc	a0,0x1d
    80006350:	cb450513          	addi	a0,a0,-844 # 80023000 <disk>
    80006354:	0001f797          	auipc	a5,0x1f
    80006358:	cac78793          	addi	a5,a5,-852 # 80025000 <disk+0x2000>
    8000635c:	6394                	ld	a3,0(a5)
    8000635e:	96ba                	add	a3,a3,a4
    80006360:	00c6d603          	lhu	a2,12(a3)
    80006364:	00166613          	ori	a2,a2,1
    80006368:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000636c:	f9842683          	lw	a3,-104(s0)
    80006370:	6390                	ld	a2,0(a5)
    80006372:	9732                	add	a4,a4,a2
    80006374:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006378:	20098613          	addi	a2,s3,512
    8000637c:	0612                	slli	a2,a2,0x4
    8000637e:	962a                	add	a2,a2,a0
    80006380:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006384:	00469713          	slli	a4,a3,0x4
    80006388:	6394                	ld	a3,0(a5)
    8000638a:	96ba                	add	a3,a3,a4
    8000638c:	6589                	lui	a1,0x2
    8000638e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006392:	94ae                	add	s1,s1,a1
    80006394:	94aa                	add	s1,s1,a0
    80006396:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006398:	6394                	ld	a3,0(a5)
    8000639a:	96ba                	add	a3,a3,a4
    8000639c:	4585                	li	a1,1
    8000639e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063a0:	6394                	ld	a3,0(a5)
    800063a2:	96ba                	add	a3,a3,a4
    800063a4:	4509                	li	a0,2
    800063a6:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800063aa:	6394                	ld	a3,0(a5)
    800063ac:	9736                	add	a4,a4,a3
    800063ae:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800063b2:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800063b6:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800063ba:	6794                	ld	a3,8(a5)
    800063bc:	0026d703          	lhu	a4,2(a3)
    800063c0:	8b1d                	andi	a4,a4,7
    800063c2:	2709                	addiw	a4,a4,2
    800063c4:	0706                	slli	a4,a4,0x1
    800063c6:	9736                	add	a4,a4,a3
    800063c8:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    800063cc:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800063d0:	6798                	ld	a4,8(a5)
    800063d2:	00275783          	lhu	a5,2(a4)
    800063d6:	2785                	addiw	a5,a5,1
    800063d8:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800063dc:	100017b7          	lui	a5,0x10001
    800063e0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063e4:	00492703          	lw	a4,4(s2)
    800063e8:	4785                	li	a5,1
    800063ea:	02f71163          	bne	a4,a5,8000640c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    800063ee:	0001f997          	auipc	s3,0x1f
    800063f2:	cba98993          	addi	s3,s3,-838 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800063f6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800063f8:	85ce                	mv	a1,s3
    800063fa:	854a                	mv	a0,s2
    800063fc:	ffffc097          	auipc	ra,0xffffc
    80006400:	04c080e7          	jalr	76(ra) # 80002448 <sleep>
  while(b->disk == 1) {
    80006404:	00492783          	lw	a5,4(s2)
    80006408:	fe9788e3          	beq	a5,s1,800063f8 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000640c:	f9042483          	lw	s1,-112(s0)
    80006410:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006414:	00479713          	slli	a4,a5,0x4
    80006418:	0001d797          	auipc	a5,0x1d
    8000641c:	be878793          	addi	a5,a5,-1048 # 80023000 <disk>
    80006420:	97ba                	add	a5,a5,a4
    80006422:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006426:	0001f917          	auipc	s2,0x1f
    8000642a:	bda90913          	addi	s2,s2,-1062 # 80025000 <disk+0x2000>
    free_desc(i);
    8000642e:	8526                	mv	a0,s1
    80006430:	00000097          	auipc	ra,0x0
    80006434:	bf6080e7          	jalr	-1034(ra) # 80006026 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006438:	0492                	slli	s1,s1,0x4
    8000643a:	00093783          	ld	a5,0(s2)
    8000643e:	94be                	add	s1,s1,a5
    80006440:	00c4d783          	lhu	a5,12(s1)
    80006444:	8b85                	andi	a5,a5,1
    80006446:	cf89                	beqz	a5,80006460 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006448:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000644c:	b7cd                	j	8000642e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000644e:	0001f797          	auipc	a5,0x1f
    80006452:	bb27b783          	ld	a5,-1102(a5) # 80025000 <disk+0x2000>
    80006456:	97ba                	add	a5,a5,a4
    80006458:	4689                	li	a3,2
    8000645a:	00d79623          	sh	a3,12(a5)
    8000645e:	b5fd                	j	8000634c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006460:	0001f517          	auipc	a0,0x1f
    80006464:	c4850513          	addi	a0,a0,-952 # 800250a8 <disk+0x20a8>
    80006468:	ffffb097          	auipc	ra,0xffffb
    8000646c:	9d2080e7          	jalr	-1582(ra) # 80000e3a <release>
}
    80006470:	70e6                	ld	ra,120(sp)
    80006472:	7446                	ld	s0,112(sp)
    80006474:	74a6                	ld	s1,104(sp)
    80006476:	7906                	ld	s2,96(sp)
    80006478:	69e6                	ld	s3,88(sp)
    8000647a:	6a46                	ld	s4,80(sp)
    8000647c:	6aa6                	ld	s5,72(sp)
    8000647e:	6b06                	ld	s6,64(sp)
    80006480:	7be2                	ld	s7,56(sp)
    80006482:	7c42                	ld	s8,48(sp)
    80006484:	7ca2                	ld	s9,40(sp)
    80006486:	7d02                	ld	s10,32(sp)
    80006488:	6109                	addi	sp,sp,128
    8000648a:	8082                	ret
  if(write)
    8000648c:	e20d1ee3          	bnez	s10,800062c8 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006490:	f8042023          	sw	zero,-128(s0)
    80006494:	bd2d                	j	800062ce <virtio_disk_rw+0xe2>

0000000080006496 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006496:	1101                	addi	sp,sp,-32
    80006498:	ec06                	sd	ra,24(sp)
    8000649a:	e822                	sd	s0,16(sp)
    8000649c:	e426                	sd	s1,8(sp)
    8000649e:	e04a                	sd	s2,0(sp)
    800064a0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064a2:	0001f517          	auipc	a0,0x1f
    800064a6:	c0650513          	addi	a0,a0,-1018 # 800250a8 <disk+0x20a8>
    800064aa:	ffffb097          	auipc	ra,0xffffb
    800064ae:	8dc080e7          	jalr	-1828(ra) # 80000d86 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800064b2:	0001f717          	auipc	a4,0x1f
    800064b6:	b4e70713          	addi	a4,a4,-1202 # 80025000 <disk+0x2000>
    800064ba:	02075783          	lhu	a5,32(a4)
    800064be:	6b18                	ld	a4,16(a4)
    800064c0:	00275683          	lhu	a3,2(a4)
    800064c4:	8ebd                	xor	a3,a3,a5
    800064c6:	8a9d                	andi	a3,a3,7
    800064c8:	cab9                	beqz	a3,8000651e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800064ca:	0001d917          	auipc	s2,0x1d
    800064ce:	b3690913          	addi	s2,s2,-1226 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800064d2:	0001f497          	auipc	s1,0x1f
    800064d6:	b2e48493          	addi	s1,s1,-1234 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800064da:	078e                	slli	a5,a5,0x3
    800064dc:	97ba                	add	a5,a5,a4
    800064de:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800064e0:	20078713          	addi	a4,a5,512
    800064e4:	0712                	slli	a4,a4,0x4
    800064e6:	974a                	add	a4,a4,s2
    800064e8:	03074703          	lbu	a4,48(a4)
    800064ec:	ef21                	bnez	a4,80006544 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800064ee:	20078793          	addi	a5,a5,512
    800064f2:	0792                	slli	a5,a5,0x4
    800064f4:	97ca                	add	a5,a5,s2
    800064f6:	7798                	ld	a4,40(a5)
    800064f8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800064fc:	7788                	ld	a0,40(a5)
    800064fe:	ffffc097          	auipc	ra,0xffffc
    80006502:	0d0080e7          	jalr	208(ra) # 800025ce <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006506:	0204d783          	lhu	a5,32(s1)
    8000650a:	2785                	addiw	a5,a5,1
    8000650c:	8b9d                	andi	a5,a5,7
    8000650e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006512:	6898                	ld	a4,16(s1)
    80006514:	00275683          	lhu	a3,2(a4)
    80006518:	8a9d                	andi	a3,a3,7
    8000651a:	fcf690e3          	bne	a3,a5,800064da <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000651e:	10001737          	lui	a4,0x10001
    80006522:	533c                	lw	a5,96(a4)
    80006524:	8b8d                	andi	a5,a5,3
    80006526:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006528:	0001f517          	auipc	a0,0x1f
    8000652c:	b8050513          	addi	a0,a0,-1152 # 800250a8 <disk+0x20a8>
    80006530:	ffffb097          	auipc	ra,0xffffb
    80006534:	90a080e7          	jalr	-1782(ra) # 80000e3a <release>
}
    80006538:	60e2                	ld	ra,24(sp)
    8000653a:	6442                	ld	s0,16(sp)
    8000653c:	64a2                	ld	s1,8(sp)
    8000653e:	6902                	ld	s2,0(sp)
    80006540:	6105                	addi	sp,sp,32
    80006542:	8082                	ret
      panic("virtio_disk_intr status");
    80006544:	00002517          	auipc	a0,0x2
    80006548:	39c50513          	addi	a0,a0,924 # 800088e0 <syscalls+0x3d0>
    8000654c:	ffffa097          	auipc	ra,0xffffa
    80006550:	ffc080e7          	jalr	-4(ra) # 80000548 <panic>
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
