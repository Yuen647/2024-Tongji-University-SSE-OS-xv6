
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
    80000060:	ec478793          	addi	a5,a5,-316 # 80005f20 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e1878793          	addi	a5,a5,-488 # 80000ebe <main>
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
    80000110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
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
    8000012a:	6be080e7          	jalr	1726(ra) # 800027e4 <either_copyin>
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
    80000152:	b76080e7          	jalr	-1162(ra) # 80000cc4 <release>

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
    800001a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
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
    800001d2:	950080e7          	jalr	-1712(ra) # 80001b1e <myproc>
    800001d6:	5d1c                	lw	a5,56(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	34e080e7          	jalr	846(ra) # 8000252c <sleep>
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
    8000021e:	574080e7          	jalr	1396(ra) # 8000278e <either_copyout>
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
    8000023a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a78080e7          	jalr	-1416(ra) # 80000cc4 <release>
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
    800002e2:	932080e7          	jalr	-1742(ra) # 80000c10 <acquire>

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
    80000300:	53e080e7          	jalr	1342(ra) # 8000283a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9b8080e7          	jalr	-1608(ra) # 80000cc4 <release>
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
    80000454:	262080e7          	jalr	610(ra) # 800026b2 <wakeup>
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
    80000476:	70e080e7          	jalr	1806(ra) # 80000b80 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	72e78793          	addi	a5,a5,1838 # 80021bb0 <devsw>
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
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
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
    8000060e:	606080e7          	jalr	1542(ra) # 80000c10 <acquire>
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
    80000772:	556080e7          	jalr	1366(ra) # 80000cc4 <release>
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
    80000798:	3ec080e7          	jalr	1004(ra) # 80000b80 <initlock>
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
    800007ee:	396080e7          	jalr	918(ra) # 80000b80 <initlock>
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
    8000080a:	3be080e7          	jalr	958(ra) # 80000bc4 <push_off>

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
    8000083c:	42c080e7          	jalr	1068(ra) # 80000c64 <pop_off>
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
    800008ba:	dfc080e7          	jalr	-516(ra) # 800026b2 <wakeup>
    
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
    800008fe:	316080e7          	jalr	790(ra) # 80000c10 <acquire>
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
    80000954:	bdc080e7          	jalr	-1060(ra) # 8000252c <sleep>
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
    80000998:	330080e7          	jalr	816(ra) # 80000cc4 <release>
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
    80000a04:	210080e7          	jalr	528(ra) # 80000c10 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2b2080e7          	jalr	690(ra) # 80000cc4 <release>
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
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00026797          	auipc	a5,0x26
    80000a3c:	5e878793          	addi	a5,a5,1512 # 80027020 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	2bc080e7          	jalr	700(ra) # 80000d0c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1ae080e7          	jalr	430(ra) # 80000c10 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	24e080e7          	jalr	590(ra) # 80000cc4 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00026517          	auipc	a0,0x26
    80000b0c:	51850513          	addi	a0,a0,1304 # 80027020 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	0dc080e7          	jalr	220(ra) # 80000c10 <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	178080e7          	jalr	376(ra) # 80000cc4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	14e080e7          	jalr	334(ra) # 80000cc4 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b86:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b88:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b8c:	00053823          	sd	zero,16(a0)
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	411c                	lw	a5,0(a0)
    80000b98:	e399                	bnez	a5,80000b9e <holding+0x8>
    80000b9a:	4501                	li	a0,0
  return r;
}
    80000b9c:	8082                	ret
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	6904                	ld	s1,16(a0)
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	f58080e7          	jalr	-168(ra) # 80001b02 <mycpu>
    80000bb2:	40a48533          	sub	a0,s1,a0
    80000bb6:	00153513          	seqz	a0,a0
}
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret

0000000080000bc4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc4:	1101                	addi	sp,sp,-32
    80000bc6:	ec06                	sd	ra,24(sp)
    80000bc8:	e822                	sd	s0,16(sp)
    80000bca:	e426                	sd	s1,8(sp)
    80000bcc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bce:	100024f3          	csrr	s1,sstatus
    80000bd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bdc:	00001097          	auipc	ra,0x1
    80000be0:	f26080e7          	jalr	-218(ra) # 80001b02 <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	f1a080e7          	jalr	-230(ra) # 80001b02 <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	2785                	addiw	a5,a5,1
    80000bf4:	dd3c                	sw	a5,120(a0)
}
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
    mycpu()->intena = old;
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	f02080e7          	jalr	-254(ra) # 80001b02 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c08:	8085                	srli	s1,s1,0x1
    80000c0a:	8885                	andi	s1,s1,1
    80000c0c:	dd64                	sw	s1,124(a0)
    80000c0e:	bfe9                	j	80000be8 <push_off+0x24>

0000000080000c10 <acquire>:
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	fa8080e7          	jalr	-88(ra) # 80000bc4 <push_off>
  if(holding(lk))
    80000c24:	8526                	mv	a0,s1
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	f70080e7          	jalr	-144(ra) # 80000b96 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2e:	4705                	li	a4,1
  if(holding(lk))
    80000c30:	e115                	bnez	a0,80000c54 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c32:	87ba                	mv	a5,a4
    80000c34:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c38:	2781                	sext.w	a5,a5
    80000c3a:	ffe5                	bnez	a5,80000c32 <acquire+0x22>
  __sync_synchronize();
    80000c3c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	ec2080e7          	jalr	-318(ra) # 80001b02 <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    panic("acquire");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	41c50513          	addi	a0,a0,1052 # 80008070 <digits+0x30>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	8ec080e7          	jalr	-1812(ra) # 80000548 <panic>

0000000080000c64 <pop_off>:

void
pop_off(void)
{
    80000c64:	1141                	addi	sp,sp,-16
    80000c66:	e406                	sd	ra,8(sp)
    80000c68:	e022                	sd	s0,0(sp)
    80000c6a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	e96080e7          	jalr	-362(ra) # 80001b02 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c78:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c7a:	e78d                	bnez	a5,80000ca4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c7c:	5d3c                	lw	a5,120(a0)
    80000c7e:	02f05b63          	blez	a5,80000cb4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c82:	37fd                	addiw	a5,a5,-1
    80000c84:	0007871b          	sext.w	a4,a5
    80000c88:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c8a:	eb09                	bnez	a4,80000c9c <pop_off+0x38>
    80000c8c:	5d7c                	lw	a5,124(a0)
    80000c8e:	c799                	beqz	a5,80000c9c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c98:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c9c:	60a2                	ld	ra,8(sp)
    80000c9e:	6402                	ld	s0,0(sp)
    80000ca0:	0141                	addi	sp,sp,16
    80000ca2:	8082                	ret
    panic("pop_off - interruptible");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3d450513          	addi	a0,a0,980 # 80008078 <digits+0x38>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
    panic("pop_off");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3dc50513          	addi	a0,a0,988 # 80008090 <digits+0x50>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	88c080e7          	jalr	-1908(ra) # 80000548 <panic>

0000000080000cc4 <release>:
{
    80000cc4:	1101                	addi	sp,sp,-32
    80000cc6:	ec06                	sd	ra,24(sp)
    80000cc8:	e822                	sd	s0,16(sp)
    80000cca:	e426                	sd	s1,8(sp)
    80000ccc:	1000                	addi	s0,sp,32
    80000cce:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	ec6080e7          	jalr	-314(ra) # 80000b96 <holding>
    80000cd8:	c115                	beqz	a0,80000cfc <release+0x38>
  lk->cpu = 0;
    80000cda:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cde:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ce2:	0f50000f          	fence	iorw,ow
    80000ce6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	f7a080e7          	jalr	-134(ra) # 80000c64 <pop_off>
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    panic("release");
    80000cfc:	00007517          	auipc	a0,0x7
    80000d00:	39c50513          	addi	a0,a0,924 # 80008098 <digits+0x58>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	844080e7          	jalr	-1980(ra) # 80000548 <panic>

0000000080000d0c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d12:	ce09                	beqz	a2,80000d2c <memset+0x20>
    80000d14:	87aa                	mv	a5,a0
    80000d16:	fff6071b          	addiw	a4,a2,-1
    80000d1a:	1702                	slli	a4,a4,0x20
    80000d1c:	9301                	srli	a4,a4,0x20
    80000d1e:	0705                	addi	a4,a4,1
    80000d20:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d22:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d26:	0785                	addi	a5,a5,1
    80000d28:	fee79de3          	bne	a5,a4,80000d22 <memset+0x16>
  }
  return dst;
}
    80000d2c:	6422                	ld	s0,8(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret

0000000080000d32 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d38:	ca05                	beqz	a2,80000d68 <memcmp+0x36>
    80000d3a:	fff6069b          	addiw	a3,a2,-1
    80000d3e:	1682                	slli	a3,a3,0x20
    80000d40:	9281                	srli	a3,a3,0x20
    80000d42:	0685                	addi	a3,a3,1
    80000d44:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d46:	00054783          	lbu	a5,0(a0)
    80000d4a:	0005c703          	lbu	a4,0(a1)
    80000d4e:	00e79863          	bne	a5,a4,80000d5e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d52:	0505                	addi	a0,a0,1
    80000d54:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d56:	fed518e3          	bne	a0,a3,80000d46 <memcmp+0x14>
  }

  return 0;
    80000d5a:	4501                	li	a0,0
    80000d5c:	a019                	j	80000d62 <memcmp+0x30>
      return *s1 - *s2;
    80000d5e:	40e7853b          	subw	a0,a5,a4
}
    80000d62:	6422                	ld	s0,8(sp)
    80000d64:	0141                	addi	sp,sp,16
    80000d66:	8082                	ret
  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	bfe5                	j	80000d62 <memcmp+0x30>

0000000080000d6c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d72:	00a5f963          	bgeu	a1,a0,80000d84 <memmove+0x18>
    80000d76:	02061713          	slli	a4,a2,0x20
    80000d7a:	9301                	srli	a4,a4,0x20
    80000d7c:	00e587b3          	add	a5,a1,a4
    80000d80:	02f56563          	bltu	a0,a5,80000daa <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x38>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x28>

  return dst;
}
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
    d += n;
    80000daa:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dac:	fff6069b          	addiw	a3,a2,-1
    80000db0:	da75                	beqz	a2,80000da4 <memmove+0x38>
    80000db2:	02069613          	slli	a2,a3,0x20
    80000db6:	9201                	srli	a2,a2,0x20
    80000db8:	fff64613          	not	a2,a2
    80000dbc:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dbe:	17fd                	addi	a5,a5,-1
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	0007c683          	lbu	a3,0(a5)
    80000dc6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dca:	fec79ae3          	bne	a5,a2,80000dbe <memmove+0x52>
    80000dce:	bfd9                	j	80000da4 <memmove+0x38>

0000000080000dd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f94080e7          	jalr	-108(ra) # 80000d6c <memmove>
}
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    n--, p++, q++;
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
  if(n == 0)
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e42:	00c05d63          	blez	a2,80000e5c <strncpy+0x38>
    80000e46:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4e:	fff6c793          	not	a5,a3
    80000e52:	9fb9                	addw	a5,a5,a4
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
  return os;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:

int
strlen(const char *s)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf91                	beqz	a5,80000eba <strlen+0x26>
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	87aa                	mv	a5,a0
    80000ea4:	4685                	li	a3,1
    80000ea6:	9e89                	subw	a3,a3,a0
    80000ea8:	00f6853b          	addw	a0,a3,a5
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff7c703          	lbu	a4,-1(a5)
    80000eb2:	fb7d                	bnez	a4,80000ea8 <strlen+0x14>
    ;
  return n;
}
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eba:	4501                	li	a0,0
    80000ebc:	bfe5                	j	80000eb4 <strlen+0x20>

0000000080000ebe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e406                	sd	ra,8(sp)
    80000ec2:	e022                	sd	s0,0(sp)
    80000ec4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	c2c080e7          	jalr	-980(ra) # 80001af2 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ece:	00008717          	auipc	a4,0x8
    80000ed2:	13e70713          	addi	a4,a4,318 # 8000900c <started>
  if(cpuid() == 0){
    80000ed6:	c139                	beqz	a0,80000f1c <main+0x5e>
    while(started == 0)
    80000ed8:	431c                	lw	a5,0(a4)
    80000eda:	2781                	sext.w	a5,a5
    80000edc:	dff5                	beqz	a5,80000ed8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	c10080e7          	jalr	-1008(ra) # 80001af2 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0e0080e7          	jalr	224(ra) # 80000fdc <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	a76080e7          	jalr	-1418(ra) # 8000297a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	054080e7          	jalr	84(ra) # 80005f60 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	322080e7          	jalr	802(ra) # 80002236 <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    statsinit();
    80000f24:	00005097          	auipc	ra,0x5
    80000f28:	7fe080e7          	jalr	2046(ra) # 80006722 <statsinit>
    printfinit();
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	84c080e7          	jalr	-1972(ra) # 80000778 <printfinit>
    printf("\n");
    80000f34:	00007517          	auipc	a0,0x7
    80000f38:	19450513          	addi	a0,a0,404 # 800080c8 <digits+0x88>
    80000f3c:	fffff097          	auipc	ra,0xfffff
    80000f40:	656080e7          	jalr	1622(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f44:	00007517          	auipc	a0,0x7
    80000f48:	15c50513          	addi	a0,a0,348 # 800080a0 <digits+0x60>
    80000f4c:	fffff097          	auipc	ra,0xfffff
    80000f50:	646080e7          	jalr	1606(ra) # 80000592 <printf>
    printf("\n");
    80000f54:	00007517          	auipc	a0,0x7
    80000f58:	17450513          	addi	a0,a0,372 # 800080c8 <digits+0x88>
    80000f5c:	fffff097          	auipc	ra,0xfffff
    80000f60:	636080e7          	jalr	1590(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	b80080e7          	jalr	-1152(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	2a8080e7          	jalr	680(ra) # 80001214 <kvminit>
    kvminithart();   // turn on paging
    80000f74:	00000097          	auipc	ra,0x0
    80000f78:	068080e7          	jalr	104(ra) # 80000fdc <kvminithart>
    procinit();      // process table
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	b16080e7          	jalr	-1258(ra) # 80001a92 <procinit>
    trapinit();      // trap vectors
    80000f84:	00002097          	auipc	ra,0x2
    80000f88:	9ce080e7          	jalr	-1586(ra) # 80002952 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	9ee080e7          	jalr	-1554(ra) # 8000297a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	fb6080e7          	jalr	-74(ra) # 80005f4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	fc4080e7          	jalr	-60(ra) # 80005f60 <plicinithart>
    binit();         // buffer cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	118080e7          	jalr	280(ra) # 800030bc <binit>
    iinit();         // inode cache
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	7a8080e7          	jalr	1960(ra) # 80003754 <iinit>
    fileinit();      // file table
    80000fb4:	00003097          	auipc	ra,0x3
    80000fb8:	742080e7          	jalr	1858(ra) # 800046f6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fbc:	00005097          	auipc	ra,0x5
    80000fc0:	0ac080e7          	jalr	172(ra) # 80006068 <virtio_disk_init>
    userinit();      // first user process
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	f92080e7          	jalr	-110(ra) # 80001f56 <userinit>
    __sync_synchronize();
    80000fcc:	0ff0000f          	fence
    started = 1;
    80000fd0:	4785                	li	a5,1
    80000fd2:	00008717          	auipc	a4,0x8
    80000fd6:	02f72d23          	sw	a5,58(a4) # 8000900c <started>
    80000fda:	bf2d                	j	80000f14 <main+0x56>

0000000080000fdc <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fdc:	1141                	addi	sp,sp,-16
    80000fde:	e422                	sd	s0,8(sp)
    80000fe0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fe2:	00008797          	auipc	a5,0x8
    80000fe6:	02e7b783          	ld	a5,46(a5) # 80009010 <kernel_pagetable>
    80000fea:	83b1                	srli	a5,a5,0xc
    80000fec:	577d                	li	a4,-1
    80000fee:	177e                	slli	a4,a4,0x3f
    80000ff0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ff2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ff6:	12000073          	sfence.vma
  sfence_vma();
}
    80000ffa:	6422                	ld	s0,8(sp)
    80000ffc:	0141                	addi	sp,sp,16
    80000ffe:	8082                	ret

0000000080001000 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001000:	7139                	addi	sp,sp,-64
    80001002:	fc06                	sd	ra,56(sp)
    80001004:	f822                	sd	s0,48(sp)
    80001006:	f426                	sd	s1,40(sp)
    80001008:	f04a                	sd	s2,32(sp)
    8000100a:	ec4e                	sd	s3,24(sp)
    8000100c:	e852                	sd	s4,16(sp)
    8000100e:	e456                	sd	s5,8(sp)
    80001010:	e05a                	sd	s6,0(sp)
    80001012:	0080                	addi	s0,sp,64
    80001014:	84aa                	mv	s1,a0
    80001016:	89ae                	mv	s3,a1
    80001018:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000101a:	57fd                	li	a5,-1
    8000101c:	83e9                	srli	a5,a5,0x1a
    8000101e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001020:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001022:	04b7f263          	bgeu	a5,a1,80001066 <walk+0x66>
    panic("walk");
    80001026:	00007517          	auipc	a0,0x7
    8000102a:	0aa50513          	addi	a0,a0,170 # 800080d0 <digits+0x90>
    8000102e:	fffff097          	auipc	ra,0xfffff
    80001032:	51a080e7          	jalr	1306(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001036:	060a8663          	beqz	s5,800010a2 <walk+0xa2>
    8000103a:	00000097          	auipc	ra,0x0
    8000103e:	ae6080e7          	jalr	-1306(ra) # 80000b20 <kalloc>
    80001042:	84aa                	mv	s1,a0
    80001044:	c529                	beqz	a0,8000108e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001046:	6605                	lui	a2,0x1
    80001048:	4581                	li	a1,0
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	cc2080e7          	jalr	-830(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001052:	00c4d793          	srli	a5,s1,0xc
    80001056:	07aa                	slli	a5,a5,0xa
    80001058:	0017e793          	ori	a5,a5,1
    8000105c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001060:	3a5d                	addiw	s4,s4,-9
    80001062:	036a0063          	beq	s4,s6,80001082 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001066:	0149d933          	srl	s2,s3,s4
    8000106a:	1ff97913          	andi	s2,s2,511
    8000106e:	090e                	slli	s2,s2,0x3
    80001070:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001072:	00093483          	ld	s1,0(s2)
    80001076:	0014f793          	andi	a5,s1,1
    8000107a:	dfd5                	beqz	a5,80001036 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000107c:	80a9                	srli	s1,s1,0xa
    8000107e:	04b2                	slli	s1,s1,0xc
    80001080:	b7c5                	j	80001060 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001082:	00c9d513          	srli	a0,s3,0xc
    80001086:	1ff57513          	andi	a0,a0,511
    8000108a:	050e                	slli	a0,a0,0x3
    8000108c:	9526                	add	a0,a0,s1
}
    8000108e:	70e2                	ld	ra,56(sp)
    80001090:	7442                	ld	s0,48(sp)
    80001092:	74a2                	ld	s1,40(sp)
    80001094:	7902                	ld	s2,32(sp)
    80001096:	69e2                	ld	s3,24(sp)
    80001098:	6a42                	ld	s4,16(sp)
    8000109a:	6aa2                	ld	s5,8(sp)
    8000109c:	6b02                	ld	s6,0(sp)
    8000109e:	6121                	addi	sp,sp,64
    800010a0:	8082                	ret
        return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7ed                	j	8000108e <walk+0x8e>

00000000800010a6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010a6:	57fd                	li	a5,-1
    800010a8:	83e9                	srli	a5,a5,0x1a
    800010aa:	00b7f463          	bgeu	a5,a1,800010b2 <walkaddr+0xc>
    return 0;
    800010ae:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010b0:	8082                	ret
{
    800010b2:	1141                	addi	sp,sp,-16
    800010b4:	e406                	sd	ra,8(sp)
    800010b6:	e022                	sd	s0,0(sp)
    800010b8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ba:	4601                	li	a2,0
    800010bc:	00000097          	auipc	ra,0x0
    800010c0:	f44080e7          	jalr	-188(ra) # 80001000 <walk>
  if(pte == 0)
    800010c4:	c105                	beqz	a0,800010e4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010c6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c8:	0117f693          	andi	a3,a5,17
    800010cc:	4745                	li	a4,17
    return 0;
    800010ce:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010d0:	00e68663          	beq	a3,a4,800010dc <walkaddr+0x36>
}
    800010d4:	60a2                	ld	ra,8(sp)
    800010d6:	6402                	ld	s0,0(sp)
    800010d8:	0141                	addi	sp,sp,16
    800010da:	8082                	ret
  pa = PTE2PA(*pte);
    800010dc:	00a7d513          	srli	a0,a5,0xa
    800010e0:	0532                	slli	a0,a0,0xc
  return pa;
    800010e2:	bfcd                	j	800010d4 <walkaddr+0x2e>
    return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7fd                	j	800010d4 <walkaddr+0x2e>

00000000800010e8 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010e8:	1101                	addi	sp,sp,-32
    800010ea:	ec06                	sd	ra,24(sp)
    800010ec:	e822                	sd	s0,16(sp)
    800010ee:	e426                	sd	s1,8(sp)
    800010f0:	e04a                	sd	s2,0(sp)
    800010f2:	1000                	addi	s0,sp,32
    800010f4:	84aa                	mv	s1,a0
  uint64 off = va % PGSIZE;
    800010f6:	1552                	slli	a0,a0,0x34
    800010f8:	03455913          	srli	s2,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(myproc()->kpagetable, va, 0);
    800010fc:	00001097          	auipc	ra,0x1
    80001100:	a22080e7          	jalr	-1502(ra) # 80001b1e <myproc>
    80001104:	4601                	li	a2,0
    80001106:	85a6                	mv	a1,s1
    80001108:	6d08                	ld	a0,24(a0)
    8000110a:	00000097          	auipc	ra,0x0
    8000110e:	ef6080e7          	jalr	-266(ra) # 80001000 <walk>
  if(pte == 0)
    80001112:	cd11                	beqz	a0,8000112e <kvmpa+0x46>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001114:	6108                	ld	a0,0(a0)
    80001116:	00157793          	andi	a5,a0,1
    8000111a:	c395                	beqz	a5,8000113e <kvmpa+0x56>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000111c:	8129                	srli	a0,a0,0xa
    8000111e:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001120:	954a                	add	a0,a0,s2
    80001122:	60e2                	ld	ra,24(sp)
    80001124:	6442                	ld	s0,16(sp)
    80001126:	64a2                	ld	s1,8(sp)
    80001128:	6902                	ld	s2,0(sp)
    8000112a:	6105                	addi	sp,sp,32
    8000112c:	8082                	ret
    panic("kvmpa");
    8000112e:	00007517          	auipc	a0,0x7
    80001132:	faa50513          	addi	a0,a0,-86 # 800080d8 <digits+0x98>
    80001136:	fffff097          	auipc	ra,0xfffff
    8000113a:	412080e7          	jalr	1042(ra) # 80000548 <panic>
    panic("kvmpa");
    8000113e:	00007517          	auipc	a0,0x7
    80001142:	f9a50513          	addi	a0,a0,-102 # 800080d8 <digits+0x98>
    80001146:	fffff097          	auipc	ra,0xfffff
    8000114a:	402080e7          	jalr	1026(ra) # 80000548 <panic>

000000008000114e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000114e:	715d                	addi	sp,sp,-80
    80001150:	e486                	sd	ra,72(sp)
    80001152:	e0a2                	sd	s0,64(sp)
    80001154:	fc26                	sd	s1,56(sp)
    80001156:	f84a                	sd	s2,48(sp)
    80001158:	f44e                	sd	s3,40(sp)
    8000115a:	f052                	sd	s4,32(sp)
    8000115c:	ec56                	sd	s5,24(sp)
    8000115e:	e85a                	sd	s6,16(sp)
    80001160:	e45e                	sd	s7,8(sp)
    80001162:	0880                	addi	s0,sp,80
    80001164:	8aaa                	mv	s5,a0
    80001166:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001168:	777d                	lui	a4,0xfffff
    8000116a:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000116e:	167d                	addi	a2,a2,-1
    80001170:	00b609b3          	add	s3,a2,a1
    80001174:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001178:	893e                	mv	s2,a5
    8000117a:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000117e:	6b85                	lui	s7,0x1
    80001180:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001184:	4605                	li	a2,1
    80001186:	85ca                	mv	a1,s2
    80001188:	8556                	mv	a0,s5
    8000118a:	00000097          	auipc	ra,0x0
    8000118e:	e76080e7          	jalr	-394(ra) # 80001000 <walk>
    80001192:	c51d                	beqz	a0,800011c0 <mappages+0x72>
    if(*pte & PTE_V)
    80001194:	611c                	ld	a5,0(a0)
    80001196:	8b85                	andi	a5,a5,1
    80001198:	ef81                	bnez	a5,800011b0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000119a:	80b1                	srli	s1,s1,0xc
    8000119c:	04aa                	slli	s1,s1,0xa
    8000119e:	0164e4b3          	or	s1,s1,s6
    800011a2:	0014e493          	ori	s1,s1,1
    800011a6:	e104                	sd	s1,0(a0)
    if(a == last)
    800011a8:	03390863          	beq	s2,s3,800011d8 <mappages+0x8a>
    a += PGSIZE;
    800011ac:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011ae:	bfc9                	j	80001180 <mappages+0x32>
      panic("remap");
    800011b0:	00007517          	auipc	a0,0x7
    800011b4:	f3050513          	addi	a0,a0,-208 # 800080e0 <digits+0xa0>
    800011b8:	fffff097          	auipc	ra,0xfffff
    800011bc:	390080e7          	jalr	912(ra) # 80000548 <panic>
      return -1;
    800011c0:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011c2:	60a6                	ld	ra,72(sp)
    800011c4:	6406                	ld	s0,64(sp)
    800011c6:	74e2                	ld	s1,56(sp)
    800011c8:	7942                	ld	s2,48(sp)
    800011ca:	79a2                	ld	s3,40(sp)
    800011cc:	7a02                	ld	s4,32(sp)
    800011ce:	6ae2                	ld	s5,24(sp)
    800011d0:	6b42                	ld	s6,16(sp)
    800011d2:	6ba2                	ld	s7,8(sp)
    800011d4:	6161                	addi	sp,sp,80
    800011d6:	8082                	ret
  return 0;
    800011d8:	4501                	li	a0,0
    800011da:	b7e5                	j	800011c2 <mappages+0x74>

00000000800011dc <kvmmap>:
{
    800011dc:	1141                	addi	sp,sp,-16
    800011de:	e406                	sd	ra,8(sp)
    800011e0:	e022                	sd	s0,0(sp)
    800011e2:	0800                	addi	s0,sp,16
    800011e4:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011e6:	86ae                	mv	a3,a1
    800011e8:	85aa                	mv	a1,a0
    800011ea:	00008517          	auipc	a0,0x8
    800011ee:	e2653503          	ld	a0,-474(a0) # 80009010 <kernel_pagetable>
    800011f2:	00000097          	auipc	ra,0x0
    800011f6:	f5c080e7          	jalr	-164(ra) # 8000114e <mappages>
    800011fa:	e509                	bnez	a0,80001204 <kvmmap+0x28>
}
    800011fc:	60a2                	ld	ra,8(sp)
    800011fe:	6402                	ld	s0,0(sp)
    80001200:	0141                	addi	sp,sp,16
    80001202:	8082                	ret
    panic("kvmmap");
    80001204:	00007517          	auipc	a0,0x7
    80001208:	ee450513          	addi	a0,a0,-284 # 800080e8 <digits+0xa8>
    8000120c:	fffff097          	auipc	ra,0xfffff
    80001210:	33c080e7          	jalr	828(ra) # 80000548 <panic>

0000000080001214 <kvminit>:
{
    80001214:	1101                	addi	sp,sp,-32
    80001216:	ec06                	sd	ra,24(sp)
    80001218:	e822                	sd	s0,16(sp)
    8000121a:	e426                	sd	s1,8(sp)
    8000121c:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000121e:	00000097          	auipc	ra,0x0
    80001222:	902080e7          	jalr	-1790(ra) # 80000b20 <kalloc>
    80001226:	00008797          	auipc	a5,0x8
    8000122a:	dea7b523          	sd	a0,-534(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000122e:	6605                	lui	a2,0x1
    80001230:	4581                	li	a1,0
    80001232:	00000097          	auipc	ra,0x0
    80001236:	ada080e7          	jalr	-1318(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000123a:	4699                	li	a3,6
    8000123c:	6605                	lui	a2,0x1
    8000123e:	100005b7          	lui	a1,0x10000
    80001242:	10000537          	lui	a0,0x10000
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f96080e7          	jalr	-106(ra) # 800011dc <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000124e:	4699                	li	a3,6
    80001250:	6605                	lui	a2,0x1
    80001252:	100015b7          	lui	a1,0x10001
    80001256:	10001537          	lui	a0,0x10001
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	f82080e7          	jalr	-126(ra) # 800011dc <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001262:	4699                	li	a3,6
    80001264:	6641                	lui	a2,0x10
    80001266:	020005b7          	lui	a1,0x2000
    8000126a:	02000537          	lui	a0,0x2000
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	f6e080e7          	jalr	-146(ra) # 800011dc <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001276:	4699                	li	a3,6
    80001278:	00400637          	lui	a2,0x400
    8000127c:	0c0005b7          	lui	a1,0xc000
    80001280:	0c000537          	lui	a0,0xc000
    80001284:	00000097          	auipc	ra,0x0
    80001288:	f58080e7          	jalr	-168(ra) # 800011dc <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000128c:	00007497          	auipc	s1,0x7
    80001290:	d7448493          	addi	s1,s1,-652 # 80008000 <etext>
    80001294:	46a9                	li	a3,10
    80001296:	80007617          	auipc	a2,0x80007
    8000129a:	d6a60613          	addi	a2,a2,-662 # 8000 <_entry-0x7fff8000>
    8000129e:	4585                	li	a1,1
    800012a0:	05fe                	slli	a1,a1,0x1f
    800012a2:	852e                	mv	a0,a1
    800012a4:	00000097          	auipc	ra,0x0
    800012a8:	f38080e7          	jalr	-200(ra) # 800011dc <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012ac:	4699                	li	a3,6
    800012ae:	4645                	li	a2,17
    800012b0:	066e                	slli	a2,a2,0x1b
    800012b2:	8e05                	sub	a2,a2,s1
    800012b4:	85a6                	mv	a1,s1
    800012b6:	8526                	mv	a0,s1
    800012b8:	00000097          	auipc	ra,0x0
    800012bc:	f24080e7          	jalr	-220(ra) # 800011dc <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012c0:	46a9                	li	a3,10
    800012c2:	6605                	lui	a2,0x1
    800012c4:	00006597          	auipc	a1,0x6
    800012c8:	d3c58593          	addi	a1,a1,-708 # 80007000 <_trampoline>
    800012cc:	04000537          	lui	a0,0x4000
    800012d0:	157d                	addi	a0,a0,-1
    800012d2:	0532                	slli	a0,a0,0xc
    800012d4:	00000097          	auipc	ra,0x0
    800012d8:	f08080e7          	jalr	-248(ra) # 800011dc <kvmmap>
}
    800012dc:	60e2                	ld	ra,24(sp)
    800012de:	6442                	ld	s0,16(sp)
    800012e0:	64a2                	ld	s1,8(sp)
    800012e2:	6105                	addi	sp,sp,32
    800012e4:	8082                	ret

00000000800012e6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012e6:	715d                	addi	sp,sp,-80
    800012e8:	e486                	sd	ra,72(sp)
    800012ea:	e0a2                	sd	s0,64(sp)
    800012ec:	fc26                	sd	s1,56(sp)
    800012ee:	f84a                	sd	s2,48(sp)
    800012f0:	f44e                	sd	s3,40(sp)
    800012f2:	f052                	sd	s4,32(sp)
    800012f4:	ec56                	sd	s5,24(sp)
    800012f6:	e85a                	sd	s6,16(sp)
    800012f8:	e45e                	sd	s7,8(sp)
    800012fa:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012fc:	03459793          	slli	a5,a1,0x34
    80001300:	e795                	bnez	a5,8000132c <uvmunmap+0x46>
    80001302:	8a2a                	mv	s4,a0
    80001304:	892e                	mv	s2,a1
    80001306:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001308:	0632                	slli	a2,a2,0xc
    8000130a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001310:	6b05                	lui	s6,0x1
    80001312:	0735e863          	bltu	a1,s3,80001382 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001316:	60a6                	ld	ra,72(sp)
    80001318:	6406                	ld	s0,64(sp)
    8000131a:	74e2                	ld	s1,56(sp)
    8000131c:	7942                	ld	s2,48(sp)
    8000131e:	79a2                	ld	s3,40(sp)
    80001320:	7a02                	ld	s4,32(sp)
    80001322:	6ae2                	ld	s5,24(sp)
    80001324:	6b42                	ld	s6,16(sp)
    80001326:	6ba2                	ld	s7,8(sp)
    80001328:	6161                	addi	sp,sp,80
    8000132a:	8082                	ret
    panic("uvmunmap: not aligned");
    8000132c:	00007517          	auipc	a0,0x7
    80001330:	dc450513          	addi	a0,a0,-572 # 800080f0 <digits+0xb0>
    80001334:	fffff097          	auipc	ra,0xfffff
    80001338:	214080e7          	jalr	532(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    8000133c:	00007517          	auipc	a0,0x7
    80001340:	dcc50513          	addi	a0,a0,-564 # 80008108 <digits+0xc8>
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	204080e7          	jalr	516(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    8000134c:	00007517          	auipc	a0,0x7
    80001350:	dcc50513          	addi	a0,a0,-564 # 80008118 <digits+0xd8>
    80001354:	fffff097          	auipc	ra,0xfffff
    80001358:	1f4080e7          	jalr	500(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    8000135c:	00007517          	auipc	a0,0x7
    80001360:	dd450513          	addi	a0,a0,-556 # 80008130 <digits+0xf0>
    80001364:	fffff097          	auipc	ra,0xfffff
    80001368:	1e4080e7          	jalr	484(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    8000136c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000136e:	0532                	slli	a0,a0,0xc
    80001370:	fffff097          	auipc	ra,0xfffff
    80001374:	6b4080e7          	jalr	1716(ra) # 80000a24 <kfree>
    *pte = 0;
    80001378:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000137c:	995a                	add	s2,s2,s6
    8000137e:	f9397ce3          	bgeu	s2,s3,80001316 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001382:	4601                	li	a2,0
    80001384:	85ca                	mv	a1,s2
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	c78080e7          	jalr	-904(ra) # 80001000 <walk>
    80001390:	84aa                	mv	s1,a0
    80001392:	d54d                	beqz	a0,8000133c <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001394:	6108                	ld	a0,0(a0)
    80001396:	00157793          	andi	a5,a0,1
    8000139a:	dbcd                	beqz	a5,8000134c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000139c:	3ff57793          	andi	a5,a0,1023
    800013a0:	fb778ee3          	beq	a5,s7,8000135c <uvmunmap+0x76>
    if(do_free){
    800013a4:	fc0a8ae3          	beqz	s5,80001378 <uvmunmap+0x92>
    800013a8:	b7d1                	j	8000136c <uvmunmap+0x86>

00000000800013aa <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013aa:	1101                	addi	sp,sp,-32
    800013ac:	ec06                	sd	ra,24(sp)
    800013ae:	e822                	sd	s0,16(sp)
    800013b0:	e426                	sd	s1,8(sp)
    800013b2:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013b4:	fffff097          	auipc	ra,0xfffff
    800013b8:	76c080e7          	jalr	1900(ra) # 80000b20 <kalloc>
    800013bc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013be:	c519                	beqz	a0,800013cc <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013c0:	6605                	lui	a2,0x1
    800013c2:	4581                	li	a1,0
    800013c4:	00000097          	auipc	ra,0x0
    800013c8:	948080e7          	jalr	-1720(ra) # 80000d0c <memset>
  return pagetable;
}
    800013cc:	8526                	mv	a0,s1
    800013ce:	60e2                	ld	ra,24(sp)
    800013d0:	6442                	ld	s0,16(sp)
    800013d2:	64a2                	ld	s1,8(sp)
    800013d4:	6105                	addi	sp,sp,32
    800013d6:	8082                	ret

00000000800013d8 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013d8:	7179                	addi	sp,sp,-48
    800013da:	f406                	sd	ra,40(sp)
    800013dc:	f022                	sd	s0,32(sp)
    800013de:	ec26                	sd	s1,24(sp)
    800013e0:	e84a                	sd	s2,16(sp)
    800013e2:	e44e                	sd	s3,8(sp)
    800013e4:	e052                	sd	s4,0(sp)
    800013e6:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013e8:	6785                	lui	a5,0x1
    800013ea:	04f67863          	bgeu	a2,a5,8000143a <uvminit+0x62>
    800013ee:	8a2a                	mv	s4,a0
    800013f0:	89ae                	mv	s3,a1
    800013f2:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013f4:	fffff097          	auipc	ra,0xfffff
    800013f8:	72c080e7          	jalr	1836(ra) # 80000b20 <kalloc>
    800013fc:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013fe:	6605                	lui	a2,0x1
    80001400:	4581                	li	a1,0
    80001402:	00000097          	auipc	ra,0x0
    80001406:	90a080e7          	jalr	-1782(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000140a:	4779                	li	a4,30
    8000140c:	86ca                	mv	a3,s2
    8000140e:	6605                	lui	a2,0x1
    80001410:	4581                	li	a1,0
    80001412:	8552                	mv	a0,s4
    80001414:	00000097          	auipc	ra,0x0
    80001418:	d3a080e7          	jalr	-710(ra) # 8000114e <mappages>
  memmove(mem, src, sz);
    8000141c:	8626                	mv	a2,s1
    8000141e:	85ce                	mv	a1,s3
    80001420:	854a                	mv	a0,s2
    80001422:	00000097          	auipc	ra,0x0
    80001426:	94a080e7          	jalr	-1718(ra) # 80000d6c <memmove>
}
    8000142a:	70a2                	ld	ra,40(sp)
    8000142c:	7402                	ld	s0,32(sp)
    8000142e:	64e2                	ld	s1,24(sp)
    80001430:	6942                	ld	s2,16(sp)
    80001432:	69a2                	ld	s3,8(sp)
    80001434:	6a02                	ld	s4,0(sp)
    80001436:	6145                	addi	sp,sp,48
    80001438:	8082                	ret
    panic("inituvm: more than a page");
    8000143a:	00007517          	auipc	a0,0x7
    8000143e:	d0e50513          	addi	a0,a0,-754 # 80008148 <digits+0x108>
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	106080e7          	jalr	262(ra) # 80000548 <panic>

000000008000144a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000144a:	1101                	addi	sp,sp,-32
    8000144c:	ec06                	sd	ra,24(sp)
    8000144e:	e822                	sd	s0,16(sp)
    80001450:	e426                	sd	s1,8(sp)
    80001452:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001454:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001456:	00b67d63          	bgeu	a2,a1,80001470 <uvmdealloc+0x26>
    8000145a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000145c:	6785                	lui	a5,0x1
    8000145e:	17fd                	addi	a5,a5,-1
    80001460:	00f60733          	add	a4,a2,a5
    80001464:	767d                	lui	a2,0xfffff
    80001466:	8f71                	and	a4,a4,a2
    80001468:	97ae                	add	a5,a5,a1
    8000146a:	8ff1                	and	a5,a5,a2
    8000146c:	00f76863          	bltu	a4,a5,8000147c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001470:	8526                	mv	a0,s1
    80001472:	60e2                	ld	ra,24(sp)
    80001474:	6442                	ld	s0,16(sp)
    80001476:	64a2                	ld	s1,8(sp)
    80001478:	6105                	addi	sp,sp,32
    8000147a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000147c:	8f99                	sub	a5,a5,a4
    8000147e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001480:	4685                	li	a3,1
    80001482:	0007861b          	sext.w	a2,a5
    80001486:	85ba                	mv	a1,a4
    80001488:	00000097          	auipc	ra,0x0
    8000148c:	e5e080e7          	jalr	-418(ra) # 800012e6 <uvmunmap>
    80001490:	b7c5                	j	80001470 <uvmdealloc+0x26>

0000000080001492 <uvmalloc>:
  if(newsz < oldsz)
    80001492:	0ab66163          	bltu	a2,a1,80001534 <uvmalloc+0xa2>
{
    80001496:	7139                	addi	sp,sp,-64
    80001498:	fc06                	sd	ra,56(sp)
    8000149a:	f822                	sd	s0,48(sp)
    8000149c:	f426                	sd	s1,40(sp)
    8000149e:	f04a                	sd	s2,32(sp)
    800014a0:	ec4e                	sd	s3,24(sp)
    800014a2:	e852                	sd	s4,16(sp)
    800014a4:	e456                	sd	s5,8(sp)
    800014a6:	0080                	addi	s0,sp,64
    800014a8:	8aaa                	mv	s5,a0
    800014aa:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014ac:	6985                	lui	s3,0x1
    800014ae:	19fd                	addi	s3,s3,-1
    800014b0:	95ce                	add	a1,a1,s3
    800014b2:	79fd                	lui	s3,0xfffff
    800014b4:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b8:	08c9f063          	bgeu	s3,a2,80001538 <uvmalloc+0xa6>
    800014bc:	894e                	mv	s2,s3
    mem = kalloc();
    800014be:	fffff097          	auipc	ra,0xfffff
    800014c2:	662080e7          	jalr	1634(ra) # 80000b20 <kalloc>
    800014c6:	84aa                	mv	s1,a0
    if(mem == 0){
    800014c8:	c51d                	beqz	a0,800014f6 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014ca:	6605                	lui	a2,0x1
    800014cc:	4581                	li	a1,0
    800014ce:	00000097          	auipc	ra,0x0
    800014d2:	83e080e7          	jalr	-1986(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014d6:	4779                	li	a4,30
    800014d8:	86a6                	mv	a3,s1
    800014da:	6605                	lui	a2,0x1
    800014dc:	85ca                	mv	a1,s2
    800014de:	8556                	mv	a0,s5
    800014e0:	00000097          	auipc	ra,0x0
    800014e4:	c6e080e7          	jalr	-914(ra) # 8000114e <mappages>
    800014e8:	e905                	bnez	a0,80001518 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ea:	6785                	lui	a5,0x1
    800014ec:	993e                	add	s2,s2,a5
    800014ee:	fd4968e3          	bltu	s2,s4,800014be <uvmalloc+0x2c>
  return newsz;
    800014f2:	8552                	mv	a0,s4
    800014f4:	a809                	j	80001506 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014f6:	864e                	mv	a2,s3
    800014f8:	85ca                	mv	a1,s2
    800014fa:	8556                	mv	a0,s5
    800014fc:	00000097          	auipc	ra,0x0
    80001500:	f4e080e7          	jalr	-178(ra) # 8000144a <uvmdealloc>
      return 0;
    80001504:	4501                	li	a0,0
}
    80001506:	70e2                	ld	ra,56(sp)
    80001508:	7442                	ld	s0,48(sp)
    8000150a:	74a2                	ld	s1,40(sp)
    8000150c:	7902                	ld	s2,32(sp)
    8000150e:	69e2                	ld	s3,24(sp)
    80001510:	6a42                	ld	s4,16(sp)
    80001512:	6aa2                	ld	s5,8(sp)
    80001514:	6121                	addi	sp,sp,64
    80001516:	8082                	ret
      kfree(mem);
    80001518:	8526                	mv	a0,s1
    8000151a:	fffff097          	auipc	ra,0xfffff
    8000151e:	50a080e7          	jalr	1290(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001522:	864e                	mv	a2,s3
    80001524:	85ca                	mv	a1,s2
    80001526:	8556                	mv	a0,s5
    80001528:	00000097          	auipc	ra,0x0
    8000152c:	f22080e7          	jalr	-222(ra) # 8000144a <uvmdealloc>
      return 0;
    80001530:	4501                	li	a0,0
    80001532:	bfd1                	j	80001506 <uvmalloc+0x74>
    return oldsz;
    80001534:	852e                	mv	a0,a1
}
    80001536:	8082                	ret
  return newsz;
    80001538:	8532                	mv	a0,a2
    8000153a:	b7f1                	j	80001506 <uvmalloc+0x74>

000000008000153c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000153c:	7179                	addi	sp,sp,-48
    8000153e:	f406                	sd	ra,40(sp)
    80001540:	f022                	sd	s0,32(sp)
    80001542:	ec26                	sd	s1,24(sp)
    80001544:	e84a                	sd	s2,16(sp)
    80001546:	e44e                	sd	s3,8(sp)
    80001548:	e052                	sd	s4,0(sp)
    8000154a:	1800                	addi	s0,sp,48
    8000154c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000154e:	84aa                	mv	s1,a0
    80001550:	6905                	lui	s2,0x1
    80001552:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001554:	4985                	li	s3,1
    80001556:	a821                	j	8000156e <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001558:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000155a:	0532                	slli	a0,a0,0xc
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	fe0080e7          	jalr	-32(ra) # 8000153c <freewalk>
      pagetable[i] = 0;
    80001564:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001568:	04a1                	addi	s1,s1,8
    8000156a:	03248163          	beq	s1,s2,8000158c <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000156e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001570:	00f57793          	andi	a5,a0,15
    80001574:	ff3782e3          	beq	a5,s3,80001558 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001578:	8905                	andi	a0,a0,1
    8000157a:	d57d                	beqz	a0,80001568 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000157c:	00007517          	auipc	a0,0x7
    80001580:	bec50513          	addi	a0,a0,-1044 # 80008168 <digits+0x128>
    80001584:	fffff097          	auipc	ra,0xfffff
    80001588:	fc4080e7          	jalr	-60(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158c:	8552                	mv	a0,s4
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	496080e7          	jalr	1174(ra) # 80000a24 <kfree>
}
    80001596:	70a2                	ld	ra,40(sp)
    80001598:	7402                	ld	s0,32(sp)
    8000159a:	64e2                	ld	s1,24(sp)
    8000159c:	6942                	ld	s2,16(sp)
    8000159e:	69a2                	ld	s3,8(sp)
    800015a0:	6a02                	ld	s4,0(sp)
    800015a2:	6145                	addi	sp,sp,48
    800015a4:	8082                	ret

00000000800015a6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a6:	1101                	addi	sp,sp,-32
    800015a8:	ec06                	sd	ra,24(sp)
    800015aa:	e822                	sd	s0,16(sp)
    800015ac:	e426                	sd	s1,8(sp)
    800015ae:	1000                	addi	s0,sp,32
    800015b0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b2:	e999                	bnez	a1,800015c8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b4:	8526                	mv	a0,s1
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	f86080e7          	jalr	-122(ra) # 8000153c <freewalk>
}
    800015be:	60e2                	ld	ra,24(sp)
    800015c0:	6442                	ld	s0,16(sp)
    800015c2:	64a2                	ld	s1,8(sp)
    800015c4:	6105                	addi	sp,sp,32
    800015c6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c8:	6605                	lui	a2,0x1
    800015ca:	167d                	addi	a2,a2,-1
    800015cc:	962e                	add	a2,a2,a1
    800015ce:	4685                	li	a3,1
    800015d0:	8231                	srli	a2,a2,0xc
    800015d2:	4581                	li	a1,0
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	d12080e7          	jalr	-750(ra) # 800012e6 <uvmunmap>
    800015dc:	bfe1                	j	800015b4 <uvmfree+0xe>

00000000800015de <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015de:	c679                	beqz	a2,800016ac <uvmcopy+0xce>
{
    800015e0:	715d                	addi	sp,sp,-80
    800015e2:	e486                	sd	ra,72(sp)
    800015e4:	e0a2                	sd	s0,64(sp)
    800015e6:	fc26                	sd	s1,56(sp)
    800015e8:	f84a                	sd	s2,48(sp)
    800015ea:	f44e                	sd	s3,40(sp)
    800015ec:	f052                	sd	s4,32(sp)
    800015ee:	ec56                	sd	s5,24(sp)
    800015f0:	e85a                	sd	s6,16(sp)
    800015f2:	e45e                	sd	s7,8(sp)
    800015f4:	0880                	addi	s0,sp,80
    800015f6:	8b2a                	mv	s6,a0
    800015f8:	8aae                	mv	s5,a1
    800015fa:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fc:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015fe:	4601                	li	a2,0
    80001600:	85ce                	mv	a1,s3
    80001602:	855a                	mv	a0,s6
    80001604:	00000097          	auipc	ra,0x0
    80001608:	9fc080e7          	jalr	-1540(ra) # 80001000 <walk>
    8000160c:	c531                	beqz	a0,80001658 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000160e:	6118                	ld	a4,0(a0)
    80001610:	00177793          	andi	a5,a4,1
    80001614:	cbb1                	beqz	a5,80001668 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001616:	00a75593          	srli	a1,a4,0xa
    8000161a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000161e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001622:	fffff097          	auipc	ra,0xfffff
    80001626:	4fe080e7          	jalr	1278(ra) # 80000b20 <kalloc>
    8000162a:	892a                	mv	s2,a0
    8000162c:	c939                	beqz	a0,80001682 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000162e:	6605                	lui	a2,0x1
    80001630:	85de                	mv	a1,s7
    80001632:	fffff097          	auipc	ra,0xfffff
    80001636:	73a080e7          	jalr	1850(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000163a:	8726                	mv	a4,s1
    8000163c:	86ca                	mv	a3,s2
    8000163e:	6605                	lui	a2,0x1
    80001640:	85ce                	mv	a1,s3
    80001642:	8556                	mv	a0,s5
    80001644:	00000097          	auipc	ra,0x0
    80001648:	b0a080e7          	jalr	-1270(ra) # 8000114e <mappages>
    8000164c:	e515                	bnez	a0,80001678 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000164e:	6785                	lui	a5,0x1
    80001650:	99be                	add	s3,s3,a5
    80001652:	fb49e6e3          	bltu	s3,s4,800015fe <uvmcopy+0x20>
    80001656:	a081                	j	80001696 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b2050513          	addi	a0,a0,-1248 # 80008178 <digits+0x138>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ee8080e7          	jalr	-280(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    80001668:	00007517          	auipc	a0,0x7
    8000166c:	b3050513          	addi	a0,a0,-1232 # 80008198 <digits+0x158>
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	ed8080e7          	jalr	-296(ra) # 80000548 <panic>
      kfree(mem);
    80001678:	854a                	mv	a0,s2
    8000167a:	fffff097          	auipc	ra,0xfffff
    8000167e:	3aa080e7          	jalr	938(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001682:	4685                	li	a3,1
    80001684:	00c9d613          	srli	a2,s3,0xc
    80001688:	4581                	li	a1,0
    8000168a:	8556                	mv	a0,s5
    8000168c:	00000097          	auipc	ra,0x0
    80001690:	c5a080e7          	jalr	-934(ra) # 800012e6 <uvmunmap>
  return -1;
    80001694:	557d                	li	a0,-1
}
    80001696:	60a6                	ld	ra,72(sp)
    80001698:	6406                	ld	s0,64(sp)
    8000169a:	74e2                	ld	s1,56(sp)
    8000169c:	7942                	ld	s2,48(sp)
    8000169e:	79a2                	ld	s3,40(sp)
    800016a0:	7a02                	ld	s4,32(sp)
    800016a2:	6ae2                	ld	s5,24(sp)
    800016a4:	6b42                	ld	s6,16(sp)
    800016a6:	6ba2                	ld	s7,8(sp)
    800016a8:	6161                	addi	sp,sp,80
    800016aa:	8082                	ret
  return 0;
    800016ac:	4501                	li	a0,0
}
    800016ae:	8082                	ret

00000000800016b0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016b0:	1141                	addi	sp,sp,-16
    800016b2:	e406                	sd	ra,8(sp)
    800016b4:	e022                	sd	s0,0(sp)
    800016b6:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016b8:	4601                	li	a2,0
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	946080e7          	jalr	-1722(ra) # 80001000 <walk>
  if(pte == 0)
    800016c2:	c901                	beqz	a0,800016d2 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016c4:	611c                	ld	a5,0(a0)
    800016c6:	9bbd                	andi	a5,a5,-17
    800016c8:	e11c                	sd	a5,0(a0)
}
    800016ca:	60a2                	ld	ra,8(sp)
    800016cc:	6402                	ld	s0,0(sp)
    800016ce:	0141                	addi	sp,sp,16
    800016d0:	8082                	ret
    panic("uvmclear");
    800016d2:	00007517          	auipc	a0,0x7
    800016d6:	ae650513          	addi	a0,a0,-1306 # 800081b8 <digits+0x178>
    800016da:	fffff097          	auipc	ra,0xfffff
    800016de:	e6e080e7          	jalr	-402(ra) # 80000548 <panic>

00000000800016e2 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e2:	c6bd                	beqz	a3,80001750 <copyout+0x6e>
{
    800016e4:	715d                	addi	sp,sp,-80
    800016e6:	e486                	sd	ra,72(sp)
    800016e8:	e0a2                	sd	s0,64(sp)
    800016ea:	fc26                	sd	s1,56(sp)
    800016ec:	f84a                	sd	s2,48(sp)
    800016ee:	f44e                	sd	s3,40(sp)
    800016f0:	f052                	sd	s4,32(sp)
    800016f2:	ec56                	sd	s5,24(sp)
    800016f4:	e85a                	sd	s6,16(sp)
    800016f6:	e45e                	sd	s7,8(sp)
    800016f8:	e062                	sd	s8,0(sp)
    800016fa:	0880                	addi	s0,sp,80
    800016fc:	8b2a                	mv	s6,a0
    800016fe:	8c2e                	mv	s8,a1
    80001700:	8a32                	mv	s4,a2
    80001702:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001704:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001706:	6a85                	lui	s5,0x1
    80001708:	a015                	j	8000172c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000170a:	9562                	add	a0,a0,s8
    8000170c:	0004861b          	sext.w	a2,s1
    80001710:	85d2                	mv	a1,s4
    80001712:	41250533          	sub	a0,a0,s2
    80001716:	fffff097          	auipc	ra,0xfffff
    8000171a:	656080e7          	jalr	1622(ra) # 80000d6c <memmove>

    len -= n;
    8000171e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001722:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001724:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001728:	02098263          	beqz	s3,8000174c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000172c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001730:	85ca                	mv	a1,s2
    80001732:	855a                	mv	a0,s6
    80001734:	00000097          	auipc	ra,0x0
    80001738:	972080e7          	jalr	-1678(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    8000173c:	cd01                	beqz	a0,80001754 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000173e:	418904b3          	sub	s1,s2,s8
    80001742:	94d6                	add	s1,s1,s5
    if(n > len)
    80001744:	fc99f3e3          	bgeu	s3,s1,8000170a <copyout+0x28>
    80001748:	84ce                	mv	s1,s3
    8000174a:	b7c1                	j	8000170a <copyout+0x28>
  }
  return 0;
    8000174c:	4501                	li	a0,0
    8000174e:	a021                	j	80001756 <copyout+0x74>
    80001750:	4501                	li	a0,0
}
    80001752:	8082                	ret
      return -1;
    80001754:	557d                	li	a0,-1
}
    80001756:	60a6                	ld	ra,72(sp)
    80001758:	6406                	ld	s0,64(sp)
    8000175a:	74e2                	ld	s1,56(sp)
    8000175c:	7942                	ld	s2,48(sp)
    8000175e:	79a2                	ld	s3,40(sp)
    80001760:	7a02                	ld	s4,32(sp)
    80001762:	6ae2                	ld	s5,24(sp)
    80001764:	6b42                	ld	s6,16(sp)
    80001766:	6ba2                	ld	s7,8(sp)
    80001768:	6c02                	ld	s8,0(sp)
    8000176a:	6161                	addi	sp,sp,80
    8000176c:	8082                	ret

000000008000176e <copyin>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    8000176e:	1141                	addi	sp,sp,-16
    80001770:	e406                	sd	ra,8(sp)
    80001772:	e022                	sd	s0,0(sp)
    80001774:	0800                	addi	s0,sp,16
  return copyin_new(pagetable, dst, srcva, len);
    80001776:	00005097          	auipc	ra,0x5
    8000177a:	dfa080e7          	jalr	-518(ra) # 80006570 <copyin_new>
  //   len -= n;
  //   dst += n;
  //   srcva = va0 + PGSIZE;
  // }
  // return 0;
}
    8000177e:	60a2                	ld	ra,8(sp)
    80001780:	6402                	ld	s0,0(sp)
    80001782:	0141                	addi	sp,sp,16
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80001786:	1141                	addi	sp,sp,-16
    80001788:	e406                	sd	ra,8(sp)
    8000178a:	e022                	sd	s0,0(sp)
    8000178c:	0800                	addi	s0,sp,16
  return copyinstr_new(pagetable, dst, srcva, max);
    8000178e:	00005097          	auipc	ra,0x5
    80001792:	e4a080e7          	jalr	-438(ra) # 800065d8 <copyinstr_new>
  // if(got_null){
  //   return 0;
  // } else {
  //   return -1;
  // }
}
    80001796:	60a2                	ld	ra,8(sp)
    80001798:	6402                	ld	s0,0(sp)
    8000179a:	0141                	addi	sp,sp,16
    8000179c:	8082                	ret

000000008000179e <_vmprint>:
//递归打印
void _vmprint(pagetable_t pagetable, int level)
{//打印页表的内容，以及根据页表的层级缩进打印每个条目的层次结构信息
    8000179e:	7159                	addi	sp,sp,-112
    800017a0:	f486                	sd	ra,104(sp)
    800017a2:	f0a2                	sd	s0,96(sp)
    800017a4:	eca6                	sd	s1,88(sp)
    800017a6:	e8ca                	sd	s2,80(sp)
    800017a8:	e4ce                	sd	s3,72(sp)
    800017aa:	e0d2                	sd	s4,64(sp)
    800017ac:	fc56                	sd	s5,56(sp)
    800017ae:	f85a                	sd	s6,48(sp)
    800017b0:	f45e                	sd	s7,40(sp)
    800017b2:	f062                	sd	s8,32(sp)
    800017b4:	ec66                	sd	s9,24(sp)
    800017b6:	e86a                	sd	s10,16(sp)
    800017b8:	e46e                	sd	s11,8(sp)
    800017ba:	1880                	addi	s0,sp,112
    800017bc:	8aae                	mv	s5,a1
  for (int i = 0; i < 512; i++)
    800017be:	8a2a                	mv	s4,a0
    800017c0:	4981                	li	s3,0
      uint64 pa = PTE2PA(pte);//将页表条目转换为物理地址，并赋值给变量 pa
      for (int j = 0; j < level; j++)
      {//根据当前层级 level ,用 for 循环打印缩进符号
        if (j)
          printf(" ");
        printf("..");
    800017c2:	00007b17          	auipc	s6,0x7
    800017c6:	a0eb0b13          	addi	s6,s6,-1522 # 800081d0 <digits+0x190>
          printf(" ");
    800017ca:	00007c17          	auipc	s8,0x7
    800017ce:	9fec0c13          	addi	s8,s8,-1538 # 800081c8 <digits+0x188>
      }
      //打印条目的索引 i、页表条目的值 pte 和物理地址 pa
      printf("%d: pte %p pa %p\n", i, pte, pa);
    800017d2:	00007d17          	auipc	s10,0x7
    800017d6:	a06d0d13          	addi	s10,s10,-1530 # 800081d8 <digits+0x198>
      if ((pte & (PTE_R | PTE_W | PTE_X)) == 0)
      {//检查页表条目中的读、写和执行标志位是否都为零。如果都为零，表示该条目对应的下一级页表存在，并且没有权限限制。
        _vmprint((pagetable_t)pa, level + 1);// 递归调用_vmprint函数，传递下一级页表的地址pa，并将层级level加1
    800017da:	00158d9b          	addiw	s11,a1,1
  for (int i = 0; i < 512; i++)
    800017de:	20000c93          	li	s9,512
    800017e2:	a081                	j	80001822 <_vmprint+0x84>
          printf(" ");
    800017e4:	8562                	mv	a0,s8
    800017e6:	fffff097          	auipc	ra,0xfffff
    800017ea:	dac080e7          	jalr	-596(ra) # 80000592 <printf>
        printf("..");
    800017ee:	855a                	mv	a0,s6
    800017f0:	fffff097          	auipc	ra,0xfffff
    800017f4:	da2080e7          	jalr	-606(ra) # 80000592 <printf>
      for (int j = 0; j < level; j++)
    800017f8:	2485                	addiw	s1,s1,1
    800017fa:	009a8463          	beq	s5,s1,80001802 <_vmprint+0x64>
        if (j)
    800017fe:	f0fd                	bnez	s1,800017e4 <_vmprint+0x46>
    80001800:	b7fd                	j	800017ee <_vmprint+0x50>
      printf("%d: pte %p pa %p\n", i, pte, pa);
    80001802:	86de                	mv	a3,s7
    80001804:	864a                	mv	a2,s2
    80001806:	85ce                	mv	a1,s3
    80001808:	856a                	mv	a0,s10
    8000180a:	fffff097          	auipc	ra,0xfffff
    8000180e:	d88080e7          	jalr	-632(ra) # 80000592 <printf>
      if ((pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001812:	00e97913          	andi	s2,s2,14
    80001816:	02090263          	beqz	s2,8000183a <_vmprint+0x9c>
  for (int i = 0; i < 512; i++)
    8000181a:	2985                	addiw	s3,s3,1
    8000181c:	0a21                	addi	s4,s4,8
    8000181e:	03998563          	beq	s3,s9,80001848 <_vmprint+0xaa>
    pte_t pte = pagetable[i];//将第 i 个条目赋值给变量 pte
    80001822:	000a3903          	ld	s2,0(s4) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    if (pte & PTE_V)//检查页表条目的有效位。如果有效位为真，表示该条目有效。
    80001826:	00197793          	andi	a5,s2,1
    8000182a:	dbe5                	beqz	a5,8000181a <_vmprint+0x7c>
      uint64 pa = PTE2PA(pte);//将页表条目转换为物理地址，并赋值给变量 pa
    8000182c:	00a95b93          	srli	s7,s2,0xa
    80001830:	0bb2                	slli	s7,s7,0xc
      for (int j = 0; j < level; j++)
    80001832:	4481                	li	s1,0
    80001834:	fb504de3          	bgtz	s5,800017ee <_vmprint+0x50>
    80001838:	b7e9                	j	80001802 <_vmprint+0x64>
        _vmprint((pagetable_t)pa, level + 1);// 递归调用_vmprint函数，传递下一级页表的地址pa，并将层级level加1
    8000183a:	85ee                	mv	a1,s11
    8000183c:	855e                	mv	a0,s7
    8000183e:	00000097          	auipc	ra,0x0
    80001842:	f60080e7          	jalr	-160(ra) # 8000179e <_vmprint>
    80001846:	bfd1                	j	8000181a <_vmprint+0x7c>
      }
    }
  }
}
    80001848:	70a6                	ld	ra,104(sp)
    8000184a:	7406                	ld	s0,96(sp)
    8000184c:	64e6                	ld	s1,88(sp)
    8000184e:	6946                	ld	s2,80(sp)
    80001850:	69a6                	ld	s3,72(sp)
    80001852:	6a06                	ld	s4,64(sp)
    80001854:	7ae2                	ld	s5,56(sp)
    80001856:	7b42                	ld	s6,48(sp)
    80001858:	7ba2                	ld	s7,40(sp)
    8000185a:	7c02                	ld	s8,32(sp)
    8000185c:	6ce2                	ld	s9,24(sp)
    8000185e:	6d42                	ld	s10,16(sp)
    80001860:	6da2                	ld	s11,8(sp)
    80001862:	6165                	addi	sp,sp,112
    80001864:	8082                	ret

0000000080001866 <vmprint>:

void vmprint(pagetable_t pagetable) {
    80001866:	1101                	addi	sp,sp,-32
    80001868:	ec06                	sd	ra,24(sp)
    8000186a:	e822                	sd	s0,16(sp)
    8000186c:	e426                	sd	s1,8(sp)
    8000186e:	1000                	addi	s0,sp,32
    80001870:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);//用&p，打印 pagetable 变量的指针值的十六进制表示形式
    80001872:	85aa                	mv	a1,a0
    80001874:	00007517          	auipc	a0,0x7
    80001878:	97c50513          	addi	a0,a0,-1668 # 800081f0 <digits+0x1b0>
    8000187c:	fffff097          	auipc	ra,0xfffff
    80001880:	d16080e7          	jalr	-746(ra) # 80000592 <printf>
  _vmprint(pagetable, 1);
    80001884:	4585                	li	a1,1
    80001886:	8526                	mv	a0,s1
    80001888:	00000097          	auipc	ra,0x0
    8000188c:	f16080e7          	jalr	-234(ra) # 8000179e <_vmprint>
}
    80001890:	60e2                	ld	ra,24(sp)
    80001892:	6442                	ld	s0,16(sp)
    80001894:	64a2                	ld	s1,8(sp)
    80001896:	6105                	addi	sp,sp,32
    80001898:	8082                	ret

000000008000189a <ukvmmap>:

//参照kvminit
void ukvmmap(pagetable_t kpagetable, uint64 va, uint64 pa, uint64 sz, int perm) 
{//将一段虚拟地址范围 va 到 va+sz 映射到物理地址范围 pa 到 pa+sz
    8000189a:	1141                	addi	sp,sp,-16
    8000189c:	e406                	sd	ra,8(sp)
    8000189e:	e022                	sd	s0,0(sp)
    800018a0:	0800                	addi	s0,sp,16
    800018a2:	87b6                	mv	a5,a3
  if(mappages(kpagetable, va, sz, pa, perm) != 0)//调用 mappages 函数来将虚拟地址范围映射到物理地址范围
    800018a4:	86b2                	mv	a3,a2
    800018a6:	863e                	mv	a2,a5
    800018a8:	00000097          	auipc	ra,0x0
    800018ac:	8a6080e7          	jalr	-1882(ra) # 8000114e <mappages>
    800018b0:	e509                	bnez	a0,800018ba <ukvmmap+0x20>
    panic("uvmmap");
}
    800018b2:	60a2                	ld	ra,8(sp)
    800018b4:	6402                	ld	s0,0(sp)
    800018b6:	0141                	addi	sp,sp,16
    800018b8:	8082                	ret
    panic("uvmmap");
    800018ba:	00007517          	auipc	a0,0x7
    800018be:	94650513          	addi	a0,a0,-1722 # 80008200 <digits+0x1c0>
    800018c2:	fffff097          	auipc	ra,0xfffff
    800018c6:	c86080e7          	jalr	-890(ra) # 80000548 <panic>

00000000800018ca <ukvminit>:
pagetable_t ukvminit() //初始化内核页表
{//使用 kalloc 函数在内核堆中分配一块内存，用于存储内核页表，并将分配的内存强制类型转换为 pagetable_t 类型的指针 kpagetable
    800018ca:	1101                	addi	sp,sp,-32
    800018cc:	ec06                	sd	ra,24(sp)
    800018ce:	e822                	sd	s0,16(sp)
    800018d0:	e426                	sd	s1,8(sp)
    800018d2:	e04a                	sd	s2,0(sp)
    800018d4:	1000                	addi	s0,sp,32
  pagetable_t kpagetable = (pagetable_t) kalloc(); 
    800018d6:	fffff097          	auipc	ra,0xfffff
    800018da:	24a080e7          	jalr	586(ra) # 80000b20 <kalloc>
    800018de:	84aa                	mv	s1,a0
  memset(kpagetable, 0, PGSIZE);//使用 memset 函数将 kpagetable 内存块的内容全部初始化为零
    800018e0:	6605                	lui	a2,0x1
    800018e2:	4581                	li	a1,0
    800018e4:	fffff097          	auipc	ra,0xfffff
    800018e8:	428080e7          	jalr	1064(ra) # 80000d0c <memset>
  ukvmmap(kpagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W);//将UART0的虚拟地址范围映射到UART0的物理地址范围，并设置读写权限
    800018ec:	4719                	li	a4,6
    800018ee:	6685                	lui	a3,0x1
    800018f0:	10000637          	lui	a2,0x10000
    800018f4:	100005b7          	lui	a1,0x10000
    800018f8:	8526                	mv	a0,s1
    800018fa:	00000097          	auipc	ra,0x0
    800018fe:	fa0080e7          	jalr	-96(ra) # 8000189a <ukvmmap>
  ukvmmap(kpagetable, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001902:	4719                	li	a4,6
    80001904:	6685                	lui	a3,0x1
    80001906:	10001637          	lui	a2,0x10001
    8000190a:	100015b7          	lui	a1,0x10001
    8000190e:	8526                	mv	a0,s1
    80001910:	00000097          	auipc	ra,0x0
    80001914:	f8a080e7          	jalr	-118(ra) # 8000189a <ukvmmap>
  ukvmmap(kpagetable, CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001918:	4719                	li	a4,6
    8000191a:	66c1                	lui	a3,0x10
    8000191c:	02000637          	lui	a2,0x2000
    80001920:	020005b7          	lui	a1,0x2000
    80001924:	8526                	mv	a0,s1
    80001926:	00000097          	auipc	ra,0x0
    8000192a:	f74080e7          	jalr	-140(ra) # 8000189a <ukvmmap>
  ukvmmap(kpagetable, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000192e:	4719                	li	a4,6
    80001930:	004006b7          	lui	a3,0x400
    80001934:	0c000637          	lui	a2,0xc000
    80001938:	0c0005b7          	lui	a1,0xc000
    8000193c:	8526                	mv	a0,s1
    8000193e:	00000097          	auipc	ra,0x0
    80001942:	f5c080e7          	jalr	-164(ra) # 8000189a <ukvmmap>
  ukvmmap(kpagetable, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001946:	00006917          	auipc	s2,0x6
    8000194a:	6ba90913          	addi	s2,s2,1722 # 80008000 <etext>
    8000194e:	4729                	li	a4,10
    80001950:	80006697          	auipc	a3,0x80006
    80001954:	6b068693          	addi	a3,a3,1712 # 8000 <_entry-0x7fff8000>
    80001958:	4605                	li	a2,1
    8000195a:	067e                	slli	a2,a2,0x1f
    8000195c:	85b2                	mv	a1,a2
    8000195e:	8526                	mv	a0,s1
    80001960:	00000097          	auipc	ra,0x0
    80001964:	f3a080e7          	jalr	-198(ra) # 8000189a <ukvmmap>
  ukvmmap(kpagetable, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001968:	4719                	li	a4,6
    8000196a:	46c5                	li	a3,17
    8000196c:	06ee                	slli	a3,a3,0x1b
    8000196e:	412686b3          	sub	a3,a3,s2
    80001972:	864a                	mv	a2,s2
    80001974:	85ca                	mv	a1,s2
    80001976:	8526                	mv	a0,s1
    80001978:	00000097          	auipc	ra,0x0
    8000197c:	f22080e7          	jalr	-222(ra) # 8000189a <ukvmmap>
  ukvmmap(kpagetable, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001980:	4729                	li	a4,10
    80001982:	6685                	lui	a3,0x1
    80001984:	00005617          	auipc	a2,0x5
    80001988:	67c60613          	addi	a2,a2,1660 # 80007000 <_trampoline>
    8000198c:	040005b7          	lui	a1,0x4000
    80001990:	15fd                	addi	a1,a1,-1
    80001992:	05b2                	slli	a1,a1,0xc
    80001994:	8526                	mv	a0,s1
    80001996:	00000097          	auipc	ra,0x0
    8000199a:	f04080e7          	jalr	-252(ra) # 8000189a <ukvmmap>
  return kpagetable;//将创建好的内核页表 kpagetable 返回
}
    8000199e:	8526                	mv	a0,s1
    800019a0:	60e2                	ld	ra,24(sp)
    800019a2:	6442                	ld	s0,16(sp)
    800019a4:	64a2                	ld	s1,8(sp)
    800019a6:	6902                	ld	s2,0(sp)
    800019a8:	6105                	addi	sp,sp,32
    800019aa:	8082                	ret

00000000800019ac <u2kvmcopy>:
u2kvmcopy(pagetable_t pagetable, pagetable_t kpagetable, uint64 oldsz, uint64 newsz)
{//pagetable 是用户页表指针，kpagetable 是内核页表指针，oldsz 是旧的用户空间大小，newsz 是新的用户空间大小。
  pte_t *pte_from, *pte_to;//定义两个指向页表项的指针，用于遍历用户页表和内核页表
  uint64 a, pa;//用于保存虚拟地址和物理地址
  uint flags;//用于保存页表项的标志
  if (newsz < oldsz)//如果新的用户空间大小小于旧的用户空间大小，则直接返回
    800019ac:	0ac6e063          	bltu	a3,a2,80001a4c <u2kvmcopy+0xa0>
{//pagetable 是用户页表指针，kpagetable 是内核页表指针，oldsz 是旧的用户空间大小，newsz 是新的用户空间大小。
    800019b0:	715d                	addi	sp,sp,-80
    800019b2:	e486                	sd	ra,72(sp)
    800019b4:	e0a2                	sd	s0,64(sp)
    800019b6:	fc26                	sd	s1,56(sp)
    800019b8:	f84a                	sd	s2,48(sp)
    800019ba:	f44e                	sd	s3,40(sp)
    800019bc:	f052                	sd	s4,32(sp)
    800019be:	ec56                	sd	s5,24(sp)
    800019c0:	e85a                	sd	s6,16(sp)
    800019c2:	e45e                	sd	s7,8(sp)
    800019c4:	0880                	addi	s0,sp,80
    800019c6:	8a2a                	mv	s4,a0
    800019c8:	8aae                	mv	s5,a1
    800019ca:	89b6                	mv	s3,a3
    return; 
  oldsz = PGROUNDUP(oldsz);//将旧的用户空间大小向上对齐到页的边界
    800019cc:	6485                	lui	s1,0x1
    800019ce:	14fd                	addi	s1,s1,-1
    800019d0:	9626                	add	a2,a2,s1
    800019d2:	74fd                	lui	s1,0xfffff
    800019d4:	8cf1                	and	s1,s1,a2
  for (a = oldsz; a < newsz; a += PGSIZE)
    800019d6:	04d4f063          	bgeu	s1,a3,80001a16 <u2kvmcopy+0x6a>
    if ((pte_to = walk(kpagetable, a, 1)) == 0)
      panic("u2kvmcopy: walk fails");
    pa = PTE2PA(*pte_from);//从用户页表项中提取物理地址，并将结果保存在 pa 变量
    // 清除PTE_U的标记位
    flags = (PTE_FLAGS(*pte_from) & (~PTE_U));//从用户页表项中提取标志，并通过按位与运算符来清除 PTE_U 标志位
    *pte_to = PA2PTE(pa) | flags;//将经过处理后的物理地址和标志写入内核页表项
    800019da:	7b7d                	lui	s6,0xfffff
    800019dc:	002b5b13          	srli	s6,s6,0x2
  for (a = oldsz; a < newsz; a += PGSIZE)
    800019e0:	6b85                	lui	s7,0x1
    if ((pte_from = walk(pagetable, a, 0)) == 0)
    800019e2:	4601                	li	a2,0
    800019e4:	85a6                	mv	a1,s1
    800019e6:	8552                	mv	a0,s4
    800019e8:	fffff097          	auipc	ra,0xfffff
    800019ec:	618080e7          	jalr	1560(ra) # 80001000 <walk>
    800019f0:	892a                	mv	s2,a0
    800019f2:	cd0d                	beqz	a0,80001a2c <u2kvmcopy+0x80>
    if ((pte_to = walk(kpagetable, a, 1)) == 0)
    800019f4:	4605                	li	a2,1
    800019f6:	85a6                	mv	a1,s1
    800019f8:	8556                	mv	a0,s5
    800019fa:	fffff097          	auipc	ra,0xfffff
    800019fe:	606080e7          	jalr	1542(ra) # 80001000 <walk>
    80001a02:	cd0d                	beqz	a0,80001a3c <u2kvmcopy+0x90>
    pa = PTE2PA(*pte_from);//从用户页表项中提取物理地址，并将结果保存在 pa 变量
    80001a04:	00093703          	ld	a4,0(s2)
    *pte_to = PA2PTE(pa) | flags;//将经过处理后的物理地址和标志写入内核页表项
    80001a08:	3efb6793          	ori	a5,s6,1007
    80001a0c:	8ff9                	and	a5,a5,a4
    80001a0e:	e11c                	sd	a5,0(a0)
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001a10:	94de                	add	s1,s1,s7
    80001a12:	fd34e8e3          	bltu	s1,s3,800019e2 <u2kvmcopy+0x36>
  }
    80001a16:	60a6                	ld	ra,72(sp)
    80001a18:	6406                	ld	s0,64(sp)
    80001a1a:	74e2                	ld	s1,56(sp)
    80001a1c:	7942                	ld	s2,48(sp)
    80001a1e:	79a2                	ld	s3,40(sp)
    80001a20:	7a02                	ld	s4,32(sp)
    80001a22:	6ae2                	ld	s5,24(sp)
    80001a24:	6b42                	ld	s6,16(sp)
    80001a26:	6ba2                	ld	s7,8(sp)
    80001a28:	6161                	addi	sp,sp,80
    80001a2a:	8082                	ret
      panic("u2kvmcopy: pte should exist");
    80001a2c:	00006517          	auipc	a0,0x6
    80001a30:	7dc50513          	addi	a0,a0,2012 # 80008208 <digits+0x1c8>
    80001a34:	fffff097          	auipc	ra,0xfffff
    80001a38:	b14080e7          	jalr	-1260(ra) # 80000548 <panic>
      panic("u2kvmcopy: walk fails");
    80001a3c:	00006517          	auipc	a0,0x6
    80001a40:	7ec50513          	addi	a0,a0,2028 # 80008228 <digits+0x1e8>
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	b04080e7          	jalr	-1276(ra) # 80000548 <panic>
    80001a4c:	8082                	ret

0000000080001a4e <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001a4e:	1101                	addi	sp,sp,-32
    80001a50:	ec06                	sd	ra,24(sp)
    80001a52:	e822                	sd	s0,16(sp)
    80001a54:	e426                	sd	s1,8(sp)
    80001a56:	1000                	addi	s0,sp,32
    80001a58:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	13c080e7          	jalr	316(ra) # 80000b96 <holding>
    80001a62:	c909                	beqz	a0,80001a74 <wakeup1+0x26>
    panic("wakeup1");
  if (p->chan == p && p->state == SLEEPING)
    80001a64:	789c                	ld	a5,48(s1)
    80001a66:	00978f63          	beq	a5,s1,80001a84 <wakeup1+0x36>
  {
    p->state = RUNNABLE;
  }
}
    80001a6a:	60e2                	ld	ra,24(sp)
    80001a6c:	6442                	ld	s0,16(sp)
    80001a6e:	64a2                	ld	s1,8(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret
    panic("wakeup1");
    80001a74:	00006517          	auipc	a0,0x6
    80001a78:	7cc50513          	addi	a0,a0,1996 # 80008240 <digits+0x200>
    80001a7c:	fffff097          	auipc	ra,0xfffff
    80001a80:	acc080e7          	jalr	-1332(ra) # 80000548 <panic>
  if (p->chan == p && p->state == SLEEPING)
    80001a84:	5098                	lw	a4,32(s1)
    80001a86:	4785                	li	a5,1
    80001a88:	fef711e3          	bne	a4,a5,80001a6a <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001a8c:	4789                	li	a5,2
    80001a8e:	d09c                	sw	a5,32(s1)
}
    80001a90:	bfe9                	j	80001a6a <wakeup1+0x1c>

0000000080001a92 <procinit>:
{
    80001a92:	7179                	addi	sp,sp,-48
    80001a94:	f406                	sd	ra,40(sp)
    80001a96:	f022                	sd	s0,32(sp)
    80001a98:	ec26                	sd	s1,24(sp)
    80001a9a:	e84a                	sd	s2,16(sp)
    80001a9c:	e44e                	sd	s3,8(sp)
    80001a9e:	1800                	addi	s0,sp,48
  initlock(&pid_lock, "nextpid");
    80001aa0:	00006597          	auipc	a1,0x6
    80001aa4:	7a858593          	addi	a1,a1,1960 # 80008248 <digits+0x208>
    80001aa8:	00010517          	auipc	a0,0x10
    80001aac:	ea850513          	addi	a0,a0,-344 # 80011950 <pid_lock>
    80001ab0:	fffff097          	auipc	ra,0xfffff
    80001ab4:	0d0080e7          	jalr	208(ra) # 80000b80 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001ab8:	00010497          	auipc	s1,0x10
    80001abc:	2b048493          	addi	s1,s1,688 # 80011d68 <proc>
    initlock(&p->lock, "proc");
    80001ac0:	00006997          	auipc	s3,0x6
    80001ac4:	79098993          	addi	s3,s3,1936 # 80008250 <digits+0x210>
  for (p = proc; p < &proc[NPROC]; p++)
    80001ac8:	00016917          	auipc	s2,0x16
    80001acc:	ea090913          	addi	s2,s2,-352 # 80017968 <tickslock>
    initlock(&p->lock, "proc");
    80001ad0:	85ce                	mv	a1,s3
    80001ad2:	8526                	mv	a0,s1
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	0ac080e7          	jalr	172(ra) # 80000b80 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001adc:	17048493          	addi	s1,s1,368
    80001ae0:	ff2498e3          	bne	s1,s2,80001ad0 <procinit+0x3e>
}
    80001ae4:	70a2                	ld	ra,40(sp)
    80001ae6:	7402                	ld	s0,32(sp)
    80001ae8:	64e2                	ld	s1,24(sp)
    80001aea:	6942                	ld	s2,16(sp)
    80001aec:	69a2                	ld	s3,8(sp)
    80001aee:	6145                	addi	sp,sp,48
    80001af0:	8082                	ret

0000000080001af2 <cpuid>:
{
    80001af2:	1141                	addi	sp,sp,-16
    80001af4:	e422                	sd	s0,8(sp)
    80001af6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001af8:	8512                	mv	a0,tp
}
    80001afa:	2501                	sext.w	a0,a0
    80001afc:	6422                	ld	s0,8(sp)
    80001afe:	0141                	addi	sp,sp,16
    80001b00:	8082                	ret

0000000080001b02 <mycpu>:
{
    80001b02:	1141                	addi	sp,sp,-16
    80001b04:	e422                	sd	s0,8(sp)
    80001b06:	0800                	addi	s0,sp,16
    80001b08:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001b0a:	2781                	sext.w	a5,a5
    80001b0c:	079e                	slli	a5,a5,0x7
}
    80001b0e:	00010517          	auipc	a0,0x10
    80001b12:	e5a50513          	addi	a0,a0,-422 # 80011968 <cpus>
    80001b16:	953e                	add	a0,a0,a5
    80001b18:	6422                	ld	s0,8(sp)
    80001b1a:	0141                	addi	sp,sp,16
    80001b1c:	8082                	ret

0000000080001b1e <myproc>:
{
    80001b1e:	1101                	addi	sp,sp,-32
    80001b20:	ec06                	sd	ra,24(sp)
    80001b22:	e822                	sd	s0,16(sp)
    80001b24:	e426                	sd	s1,8(sp)
    80001b26:	1000                	addi	s0,sp,32
  push_off();
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	09c080e7          	jalr	156(ra) # 80000bc4 <push_off>
    80001b30:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b32:	2781                	sext.w	a5,a5
    80001b34:	079e                	slli	a5,a5,0x7
    80001b36:	00010717          	auipc	a4,0x10
    80001b3a:	e1a70713          	addi	a4,a4,-486 # 80011950 <pid_lock>
    80001b3e:	97ba                	add	a5,a5,a4
    80001b40:	6f84                	ld	s1,24(a5)
  pop_off();
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	122080e7          	jalr	290(ra) # 80000c64 <pop_off>
}
    80001b4a:	8526                	mv	a0,s1
    80001b4c:	60e2                	ld	ra,24(sp)
    80001b4e:	6442                	ld	s0,16(sp)
    80001b50:	64a2                	ld	s1,8(sp)
    80001b52:	6105                	addi	sp,sp,32
    80001b54:	8082                	ret

0000000080001b56 <forkret>:
{
    80001b56:	1141                	addi	sp,sp,-16
    80001b58:	e406                	sd	ra,8(sp)
    80001b5a:	e022                	sd	s0,0(sp)
    80001b5c:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b5e:	00000097          	auipc	ra,0x0
    80001b62:	fc0080e7          	jalr	-64(ra) # 80001b1e <myproc>
    80001b66:	fffff097          	auipc	ra,0xfffff
    80001b6a:	15e080e7          	jalr	350(ra) # 80000cc4 <release>
  if (first)
    80001b6e:	00007797          	auipc	a5,0x7
    80001b72:	d627a783          	lw	a5,-670(a5) # 800088d0 <first.1715>
    80001b76:	eb89                	bnez	a5,80001b88 <forkret+0x32>
  usertrapret();
    80001b78:	00001097          	auipc	ra,0x1
    80001b7c:	e1a080e7          	jalr	-486(ra) # 80002992 <usertrapret>
}
    80001b80:	60a2                	ld	ra,8(sp)
    80001b82:	6402                	ld	s0,0(sp)
    80001b84:	0141                	addi	sp,sp,16
    80001b86:	8082                	ret
    first = 0;
    80001b88:	00007797          	auipc	a5,0x7
    80001b8c:	d407a423          	sw	zero,-696(a5) # 800088d0 <first.1715>
    fsinit(ROOTDEV);
    80001b90:	4505                	li	a0,1
    80001b92:	00002097          	auipc	ra,0x2
    80001b96:	b42080e7          	jalr	-1214(ra) # 800036d4 <fsinit>
    80001b9a:	bff9                	j	80001b78 <forkret+0x22>

0000000080001b9c <allocpid>:
{
    80001b9c:	1101                	addi	sp,sp,-32
    80001b9e:	ec06                	sd	ra,24(sp)
    80001ba0:	e822                	sd	s0,16(sp)
    80001ba2:	e426                	sd	s1,8(sp)
    80001ba4:	e04a                	sd	s2,0(sp)
    80001ba6:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ba8:	00010917          	auipc	s2,0x10
    80001bac:	da890913          	addi	s2,s2,-600 # 80011950 <pid_lock>
    80001bb0:	854a                	mv	a0,s2
    80001bb2:	fffff097          	auipc	ra,0xfffff
    80001bb6:	05e080e7          	jalr	94(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001bba:	00007797          	auipc	a5,0x7
    80001bbe:	d1a78793          	addi	a5,a5,-742 # 800088d4 <nextpid>
    80001bc2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bc4:	0014871b          	addiw	a4,s1,1
    80001bc8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bca:	854a                	mv	a0,s2
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	0f8080e7          	jalr	248(ra) # 80000cc4 <release>
}
    80001bd4:	8526                	mv	a0,s1
    80001bd6:	60e2                	ld	ra,24(sp)
    80001bd8:	6442                	ld	s0,16(sp)
    80001bda:	64a2                	ld	s1,8(sp)
    80001bdc:	6902                	ld	s2,0(sp)
    80001bde:	6105                	addi	sp,sp,32
    80001be0:	8082                	ret

0000000080001be2 <free_kernel_pagetable>:
{
    80001be2:	7179                	addi	sp,sp,-48
    80001be4:	f406                	sd	ra,40(sp)
    80001be6:	f022                	sd	s0,32(sp)
    80001be8:	ec26                	sd	s1,24(sp)
    80001bea:	e84a                	sd	s2,16(sp)
    80001bec:	e44e                	sd	s3,8(sp)
    80001bee:	e052                	sd	s4,0(sp)
    80001bf0:	1800                	addi	s0,sp,48
    80001bf2:	8a2a                	mv	s4,a0
  for(int i = 0; i < 512; ++i)//在Xv6中，一个页表有512个页表项
    80001bf4:	84aa                	mv	s1,a0
    80001bf6:	6905                	lui	s2,0x1
    80001bf8:	992a                	add	s2,s2,a0
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0)//检查页表项是否有效且只包含页表目录项的标志
    80001bfa:	4985                	li	s3,1
    80001bfc:	a821                	j	80001c14 <free_kernel_pagetable+0x32>
      pagetable[i] = 0;//如果页表项是页表目录项，则将其标记为无效
    80001bfe:	0004b023          	sd	zero,0(s1)
      free_kernel_pagetable((pagetable_t)PTE2PA(pte));//递归调用 free_kernel_pagetable 函数，释放页表目录项对应的子页表
    80001c02:	8129                	srli	a0,a0,0xa
    80001c04:	0532                	slli	a0,a0,0xc
    80001c06:	00000097          	auipc	ra,0x0
    80001c0a:	fdc080e7          	jalr	-36(ra) # 80001be2 <free_kernel_pagetable>
  for(int i = 0; i < 512; ++i)//在Xv6中，一个页表有512个页表项
    80001c0e:	04a1                	addi	s1,s1,8
    80001c10:	01248c63          	beq	s1,s2,80001c28 <free_kernel_pagetable+0x46>
    pte_t pte = pagetable[i];//获取页表中索引为 i 的页表项的值，并将其存储在变量 pte 中
    80001c14:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0)//检查页表项是否有效且只包含页表目录项的标志
    80001c16:	00f57793          	andi	a5,a0,15
    80001c1a:	ff3782e3          	beq	a5,s3,80001bfe <free_kernel_pagetable+0x1c>
    else if(pte & PTE_V)//如果页表项是普通的页表项（非页表目录项）
    80001c1e:	8905                	andi	a0,a0,1
    80001c20:	d57d                	beqz	a0,80001c0e <free_kernel_pagetable+0x2c>
      pagetable[i] = 0;//标记为无效
    80001c22:	0004b023          	sd	zero,0(s1)
    80001c26:	b7e5                	j	80001c0e <free_kernel_pagetable+0x2c>
  kfree((void *)pagetable);//释放 pagetable 所指向的内存
    80001c28:	8552                	mv	a0,s4
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	dfa080e7          	jalr	-518(ra) # 80000a24 <kfree>
}
    80001c32:	70a2                	ld	ra,40(sp)
    80001c34:	7402                	ld	s0,32(sp)
    80001c36:	64e2                	ld	s1,24(sp)
    80001c38:	6942                	ld	s2,16(sp)
    80001c3a:	69a2                	ld	s3,8(sp)
    80001c3c:	6a02                	ld	s4,0(sp)
    80001c3e:	6145                	addi	sp,sp,48
    80001c40:	8082                	ret

0000000080001c42 <proc_free_kernel_pagetable>:
{
    80001c42:	1101                	addi	sp,sp,-32
    80001c44:	ec06                	sd	ra,24(sp)
    80001c46:	e822                	sd	s0,16(sp)
    80001c48:	e426                	sd	s1,8(sp)
    80001c4a:	1000                	addi	s0,sp,32
    80001c4c:	84aa                	mv	s1,a0
  if (p->kstack)//检查进程的内核栈是否存在
    80001c4e:	652c                	ld	a1,72(a0)
    80001c50:	e999                	bnez	a1,80001c66 <proc_free_kernel_pagetable+0x24>
  free_kernel_pagetable(p->kpagetable);//释放进程的内核页表及其子页表
    80001c52:	6c88                	ld	a0,24(s1)
    80001c54:	00000097          	auipc	ra,0x0
    80001c58:	f8e080e7          	jalr	-114(ra) # 80001be2 <free_kernel_pagetable>
}
    80001c5c:	60e2                	ld	ra,24(sp)
    80001c5e:	6442                	ld	s0,16(sp)
    80001c60:	64a2                	ld	s1,8(sp)
    80001c62:	6105                	addi	sp,sp,32
    80001c64:	8082                	ret
    pte_t *pte = walk(p->kpagetable, p->kstack, 0);//使用 walk 函数从进程的内核页表中获取与内核栈相关的页表项的指针
    80001c66:	4601                	li	a2,0
    80001c68:	6d08                	ld	a0,24(a0)
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	396080e7          	jalr	918(ra) # 80001000 <walk>
    kfree((void *)PTE2PA(*pte));//释放与内核栈相关的物理内存
    80001c72:	6108                	ld	a0,0(a0)
    80001c74:	8129                	srli	a0,a0,0xa
    80001c76:	0532                	slli	a0,a0,0xc
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	dac080e7          	jalr	-596(ra) # 80000a24 <kfree>
    p->kstack = 0;//将进程的内核栈设置为 0，表示内核栈已释放
    80001c80:	0404b423          	sd	zero,72(s1)
    80001c84:	b7f9                	j	80001c52 <proc_free_kernel_pagetable+0x10>

0000000080001c86 <proc_pagetable>:
{
    80001c86:	1101                	addi	sp,sp,-32
    80001c88:	ec06                	sd	ra,24(sp)
    80001c8a:	e822                	sd	s0,16(sp)
    80001c8c:	e426                	sd	s1,8(sp)
    80001c8e:	e04a                	sd	s2,0(sp)
    80001c90:	1000                	addi	s0,sp,32
    80001c92:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	716080e7          	jalr	1814(ra) # 800013aa <uvmcreate>
    80001c9c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c9e:	c121                	beqz	a0,80001cde <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ca0:	4729                	li	a4,10
    80001ca2:	00005697          	auipc	a3,0x5
    80001ca6:	35e68693          	addi	a3,a3,862 # 80007000 <_trampoline>
    80001caa:	6605                	lui	a2,0x1
    80001cac:	040005b7          	lui	a1,0x4000
    80001cb0:	15fd                	addi	a1,a1,-1
    80001cb2:	05b2                	slli	a1,a1,0xc
    80001cb4:	fffff097          	auipc	ra,0xfffff
    80001cb8:	49a080e7          	jalr	1178(ra) # 8000114e <mappages>
    80001cbc:	02054863          	bltz	a0,80001cec <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cc0:	4719                	li	a4,6
    80001cc2:	06093683          	ld	a3,96(s2) # 1060 <_entry-0x7fffefa0>
    80001cc6:	6605                	lui	a2,0x1
    80001cc8:	020005b7          	lui	a1,0x2000
    80001ccc:	15fd                	addi	a1,a1,-1
    80001cce:	05b6                	slli	a1,a1,0xd
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	47c080e7          	jalr	1148(ra) # 8000114e <mappages>
    80001cda:	02054163          	bltz	a0,80001cfc <proc_pagetable+0x76>
}
    80001cde:	8526                	mv	a0,s1
    80001ce0:	60e2                	ld	ra,24(sp)
    80001ce2:	6442                	ld	s0,16(sp)
    80001ce4:	64a2                	ld	s1,8(sp)
    80001ce6:	6902                	ld	s2,0(sp)
    80001ce8:	6105                	addi	sp,sp,32
    80001cea:	8082                	ret
    uvmfree(pagetable, 0);
    80001cec:	4581                	li	a1,0
    80001cee:	8526                	mv	a0,s1
    80001cf0:	00000097          	auipc	ra,0x0
    80001cf4:	8b6080e7          	jalr	-1866(ra) # 800015a6 <uvmfree>
    return 0;
    80001cf8:	4481                	li	s1,0
    80001cfa:	b7d5                	j	80001cde <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cfc:	4681                	li	a3,0
    80001cfe:	4605                	li	a2,1
    80001d00:	040005b7          	lui	a1,0x4000
    80001d04:	15fd                	addi	a1,a1,-1
    80001d06:	05b2                	slli	a1,a1,0xc
    80001d08:	8526                	mv	a0,s1
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	5dc080e7          	jalr	1500(ra) # 800012e6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d12:	4581                	li	a1,0
    80001d14:	8526                	mv	a0,s1
    80001d16:	00000097          	auipc	ra,0x0
    80001d1a:	890080e7          	jalr	-1904(ra) # 800015a6 <uvmfree>
    return 0;
    80001d1e:	4481                	li	s1,0
    80001d20:	bf7d                	j	80001cde <proc_pagetable+0x58>

0000000080001d22 <proc_freepagetable>:
{
    80001d22:	1101                	addi	sp,sp,-32
    80001d24:	ec06                	sd	ra,24(sp)
    80001d26:	e822                	sd	s0,16(sp)
    80001d28:	e426                	sd	s1,8(sp)
    80001d2a:	e04a                	sd	s2,0(sp)
    80001d2c:	1000                	addi	s0,sp,32
    80001d2e:	84aa                	mv	s1,a0
    80001d30:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d32:	4681                	li	a3,0
    80001d34:	4605                	li	a2,1
    80001d36:	040005b7          	lui	a1,0x4000
    80001d3a:	15fd                	addi	a1,a1,-1
    80001d3c:	05b2                	slli	a1,a1,0xc
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	5a8080e7          	jalr	1448(ra) # 800012e6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d46:	4681                	li	a3,0
    80001d48:	4605                	li	a2,1
    80001d4a:	020005b7          	lui	a1,0x2000
    80001d4e:	15fd                	addi	a1,a1,-1
    80001d50:	05b6                	slli	a1,a1,0xd
    80001d52:	8526                	mv	a0,s1
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	592080e7          	jalr	1426(ra) # 800012e6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d5c:	85ca                	mv	a1,s2
    80001d5e:	8526                	mv	a0,s1
    80001d60:	00000097          	auipc	ra,0x0
    80001d64:	846080e7          	jalr	-1978(ra) # 800015a6 <uvmfree>
}
    80001d68:	60e2                	ld	ra,24(sp)
    80001d6a:	6442                	ld	s0,16(sp)
    80001d6c:	64a2                	ld	s1,8(sp)
    80001d6e:	6902                	ld	s2,0(sp)
    80001d70:	6105                	addi	sp,sp,32
    80001d72:	8082                	ret

0000000080001d74 <freeproc>:
{
    80001d74:	1101                	addi	sp,sp,-32
    80001d76:	ec06                	sd	ra,24(sp)
    80001d78:	e822                	sd	s0,16(sp)
    80001d7a:	e426                	sd	s1,8(sp)
    80001d7c:	1000                	addi	s0,sp,32
    80001d7e:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001d80:	7128                	ld	a0,96(a0)
    80001d82:	c509                	beqz	a0,80001d8c <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	ca0080e7          	jalr	-864(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001d8c:	0604b023          	sd	zero,96(s1)
  if (p->pagetable)
    80001d90:	6ca8                	ld	a0,88(s1)
    80001d92:	c511                	beqz	a0,80001d9e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d94:	68ac                	ld	a1,80(s1)
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	f8c080e7          	jalr	-116(ra) # 80001d22 <proc_freepagetable>
  p->pagetable = 0;
    80001d9e:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001da2:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001da6:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80001daa:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80001dae:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001db2:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001db6:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80001dba:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80001dbe:	0204a023          	sw	zero,32(s1)
  if (p->kstack)
    80001dc2:	64ac                	ld	a1,72(s1)
    80001dc4:	e18d                	bnez	a1,80001de6 <freeproc+0x72>
  p->kstack = 0;
    80001dc6:	0404b423          	sd	zero,72(s1)
  if (p->kpagetable)
    80001dca:	6c9c                	ld	a5,24(s1)
    80001dcc:	c791                	beqz	a5,80001dd8 <freeproc+0x64>
    proc_free_kernel_pagetable(p);
    80001dce:	8526                	mv	a0,s1
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	e72080e7          	jalr	-398(ra) # 80001c42 <proc_free_kernel_pagetable>
  p->kpagetable = 0;
    80001dd8:	0004bc23          	sd	zero,24(s1)
}
    80001ddc:	60e2                	ld	ra,24(sp)
    80001dde:	6442                	ld	s0,16(sp)
    80001de0:	64a2                	ld	s1,8(sp)
    80001de2:	6105                	addi	sp,sp,32
    80001de4:	8082                	ret
    pte_t *pte = walk(p->kpagetable, p->kstack, 0);
    80001de6:	4601                	li	a2,0
    80001de8:	6c88                	ld	a0,24(s1)
    80001dea:	fffff097          	auipc	ra,0xfffff
    80001dee:	216080e7          	jalr	534(ra) # 80001000 <walk>
    if (pte == 0)
    80001df2:	c909                	beqz	a0,80001e04 <freeproc+0x90>
    kfree((void *)PTE2PA(*pte));
    80001df4:	6108                	ld	a0,0(a0)
    80001df6:	8129                	srli	a0,a0,0xa
    80001df8:	0532                	slli	a0,a0,0xc
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	c2a080e7          	jalr	-982(ra) # 80000a24 <kfree>
    80001e02:	b7d1                	j	80001dc6 <freeproc+0x52>
      panic("freeproc: walk");
    80001e04:	00006517          	auipc	a0,0x6
    80001e08:	45450513          	addi	a0,a0,1108 # 80008258 <digits+0x218>
    80001e0c:	ffffe097          	auipc	ra,0xffffe
    80001e10:	73c080e7          	jalr	1852(ra) # 80000548 <panic>

0000000080001e14 <allocproc>:
{
    80001e14:	1101                	addi	sp,sp,-32
    80001e16:	ec06                	sd	ra,24(sp)
    80001e18:	e822                	sd	s0,16(sp)
    80001e1a:	e426                	sd	s1,8(sp)
    80001e1c:	e04a                	sd	s2,0(sp)
    80001e1e:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001e20:	00010497          	auipc	s1,0x10
    80001e24:	f4848493          	addi	s1,s1,-184 # 80011d68 <proc>
    80001e28:	00016917          	auipc	s2,0x16
    80001e2c:	b4090913          	addi	s2,s2,-1216 # 80017968 <tickslock>
    acquire(&p->lock);
    80001e30:	8526                	mv	a0,s1
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	dde080e7          	jalr	-546(ra) # 80000c10 <acquire>
    if (p->state == UNUSED)
    80001e3a:	509c                	lw	a5,32(s1)
    80001e3c:	cf81                	beqz	a5,80001e54 <allocproc+0x40>
      release(&p->lock);
    80001e3e:	8526                	mv	a0,s1
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	e84080e7          	jalr	-380(ra) # 80000cc4 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001e48:	17048493          	addi	s1,s1,368
    80001e4c:	ff2492e3          	bne	s1,s2,80001e30 <allocproc+0x1c>
  return 0;
    80001e50:	4481                	li	s1,0
    80001e52:	a065                	j	80001efa <allocproc+0xe6>
  p->pid = allocpid();
    80001e54:	00000097          	auipc	ra,0x0
    80001e58:	d48080e7          	jalr	-696(ra) # 80001b9c <allocpid>
    80001e5c:	c0a8                	sw	a0,64(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	cc2080e7          	jalr	-830(ra) # 80000b20 <kalloc>
    80001e66:	892a                	mv	s2,a0
    80001e68:	f0a8                	sd	a0,96(s1)
    80001e6a:	cd59                	beqz	a0,80001f08 <allocproc+0xf4>
  p->pagetable = proc_pagetable(p);
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	00000097          	auipc	ra,0x0
    80001e72:	e18080e7          	jalr	-488(ra) # 80001c86 <proc_pagetable>
    80001e76:	892a                	mv	s2,a0
    80001e78:	eca8                	sd	a0,88(s1)
  if (p->pagetable == 0)
    80001e7a:	cd51                	beqz	a0,80001f16 <allocproc+0x102>
  p->kpagetable = ukvminit();//创建和初始化了一个用户空间的页表
    80001e7c:	00000097          	auipc	ra,0x0
    80001e80:	a4e080e7          	jalr	-1458(ra) # 800018ca <ukvminit>
    80001e84:	892a                	mv	s2,a0
    80001e86:	ec88                	sd	a0,24(s1)
  if (p->kpagetable == 0)//如果创建用户空间页表失败
    80001e88:	c15d                	beqz	a0,80001f2e <allocproc+0x11a>
  char *pa = kalloc();//和原本的procinit函数一样，为进程分配一个物理页作为内核栈的存储空间
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	c96080e7          	jalr	-874(ra) # 80000b20 <kalloc>
    80001e92:	862a                	mv	a2,a0
  if (pa == 0)
    80001e94:	c94d                	beqz	a0,80001f46 <allocproc+0x132>
  uint64 va = KSTACK((int)(p - proc));//计算进程在 proc 数组中的索引，为其分配一个虚拟地址
    80001e96:	00010797          	auipc	a5,0x10
    80001e9a:	ed278793          	addi	a5,a5,-302 # 80011d68 <proc>
    80001e9e:	40f487b3          	sub	a5,s1,a5
    80001ea2:	8791                	srai	a5,a5,0x4
    80001ea4:	00006717          	auipc	a4,0x6
    80001ea8:	15c73703          	ld	a4,348(a4) # 80008000 <etext>
    80001eac:	02e787b3          	mul	a5,a5,a4
    80001eb0:	2785                	addiw	a5,a5,1
    80001eb2:	00d7979b          	slliw	a5,a5,0xd
    80001eb6:	04000937          	lui	s2,0x4000
    80001eba:	197d                	addi	s2,s2,-1
    80001ebc:	0932                	slli	s2,s2,0xc
    80001ebe:	40f90933          	sub	s2,s2,a5
  ukvmmap(p->kpagetable, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);//把内核态页表映射到物理地址
    80001ec2:	4719                	li	a4,6
    80001ec4:	6685                	lui	a3,0x1
    80001ec6:	85ca                	mv	a1,s2
    80001ec8:	6c88                	ld	a0,24(s1)
    80001eca:	00000097          	auipc	ra,0x0
    80001ece:	9d0080e7          	jalr	-1584(ra) # 8000189a <ukvmmap>
  p->kstack = va;//在进程切换到内核态时使用该虚拟地址作为用户空间的内核栈的起始地址
    80001ed2:	0524b423          	sd	s2,72(s1)
  memset(&p->context, 0, sizeof(p->context));
    80001ed6:	07000613          	li	a2,112
    80001eda:	4581                	li	a1,0
    80001edc:	06848513          	addi	a0,s1,104
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	e2c080e7          	jalr	-468(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001ee8:	00000797          	auipc	a5,0x0
    80001eec:	c6e78793          	addi	a5,a5,-914 # 80001b56 <forkret>
    80001ef0:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ef2:	64bc                	ld	a5,72(s1)
    80001ef4:	6705                	lui	a4,0x1
    80001ef6:	97ba                	add	a5,a5,a4
    80001ef8:	f8bc                	sd	a5,112(s1)
}
    80001efa:	8526                	mv	a0,s1
    80001efc:	60e2                	ld	ra,24(sp)
    80001efe:	6442                	ld	s0,16(sp)
    80001f00:	64a2                	ld	s1,8(sp)
    80001f02:	6902                	ld	s2,0(sp)
    80001f04:	6105                	addi	sp,sp,32
    80001f06:	8082                	ret
    release(&p->lock);
    80001f08:	8526                	mv	a0,s1
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	dba080e7          	jalr	-582(ra) # 80000cc4 <release>
    return 0;
    80001f12:	84ca                	mv	s1,s2
    80001f14:	b7dd                	j	80001efa <allocproc+0xe6>
    freeproc(p);
    80001f16:	8526                	mv	a0,s1
    80001f18:	00000097          	auipc	ra,0x0
    80001f1c:	e5c080e7          	jalr	-420(ra) # 80001d74 <freeproc>
    release(&p->lock);
    80001f20:	8526                	mv	a0,s1
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	da2080e7          	jalr	-606(ra) # 80000cc4 <release>
    return 0;
    80001f2a:	84ca                	mv	s1,s2
    80001f2c:	b7f9                	j	80001efa <allocproc+0xe6>
    freeproc(p);
    80001f2e:	8526                	mv	a0,s1
    80001f30:	00000097          	auipc	ra,0x0
    80001f34:	e44080e7          	jalr	-444(ra) # 80001d74 <freeproc>
    release(&p->lock);
    80001f38:	8526                	mv	a0,s1
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	d8a080e7          	jalr	-630(ra) # 80000cc4 <release>
    return 0;
    80001f42:	84ca                	mv	s1,s2
    80001f44:	bf5d                	j	80001efa <allocproc+0xe6>
    panic("kalloc");
    80001f46:	00006517          	auipc	a0,0x6
    80001f4a:	32250513          	addi	a0,a0,802 # 80008268 <digits+0x228>
    80001f4e:	ffffe097          	auipc	ra,0xffffe
    80001f52:	5fa080e7          	jalr	1530(ra) # 80000548 <panic>

0000000080001f56 <userinit>:
{
    80001f56:	1101                	addi	sp,sp,-32
    80001f58:	ec06                	sd	ra,24(sp)
    80001f5a:	e822                	sd	s0,16(sp)
    80001f5c:	e426                	sd	s1,8(sp)
    80001f5e:	e04a                	sd	s2,0(sp)
    80001f60:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f62:	00000097          	auipc	ra,0x0
    80001f66:	eb2080e7          	jalr	-334(ra) # 80001e14 <allocproc>
    80001f6a:	84aa                	mv	s1,a0
  initproc = p;
    80001f6c:	00007797          	auipc	a5,0x7
    80001f70:	0aa7b623          	sd	a0,172(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f74:	03400613          	li	a2,52
    80001f78:	00007597          	auipc	a1,0x7
    80001f7c:	96858593          	addi	a1,a1,-1688 # 800088e0 <initcode>
    80001f80:	6d28                	ld	a0,88(a0)
    80001f82:	fffff097          	auipc	ra,0xfffff
    80001f86:	456080e7          	jalr	1110(ra) # 800013d8 <uvminit>
  p->sz = PGSIZE;
    80001f8a:	6905                	lui	s2,0x1
    80001f8c:	0524b823          	sd	s2,80(s1)
  u2kvmcopy(p->pagetable, p->kpagetable, 0, p->sz);
    80001f90:	6685                	lui	a3,0x1
    80001f92:	4601                	li	a2,0
    80001f94:	6c8c                	ld	a1,24(s1)
    80001f96:	6ca8                	ld	a0,88(s1)
    80001f98:	00000097          	auipc	ra,0x0
    80001f9c:	a14080e7          	jalr	-1516(ra) # 800019ac <u2kvmcopy>
  p->trapframe->epc = 0;     // user program counter
    80001fa0:	70bc                	ld	a5,96(s1)
    80001fa2:	0007bc23          	sd	zero,24(a5)
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001fa6:	70bc                	ld	a5,96(s1)
    80001fa8:	0327b823          	sd	s2,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fac:	4641                	li	a2,16
    80001fae:	00006597          	auipc	a1,0x6
    80001fb2:	2c258593          	addi	a1,a1,706 # 80008270 <digits+0x230>
    80001fb6:	16048513          	addi	a0,s1,352
    80001fba:	fffff097          	auipc	ra,0xfffff
    80001fbe:	ea8080e7          	jalr	-344(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001fc2:	00006517          	auipc	a0,0x6
    80001fc6:	2be50513          	addi	a0,a0,702 # 80008280 <digits+0x240>
    80001fca:	00002097          	auipc	ra,0x2
    80001fce:	132080e7          	jalr	306(ra) # 800040fc <namei>
    80001fd2:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001fd6:	4789                	li	a5,2
    80001fd8:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    80001fda:	8526                	mv	a0,s1
    80001fdc:	fffff097          	auipc	ra,0xfffff
    80001fe0:	ce8080e7          	jalr	-792(ra) # 80000cc4 <release>
}
    80001fe4:	60e2                	ld	ra,24(sp)
    80001fe6:	6442                	ld	s0,16(sp)
    80001fe8:	64a2                	ld	s1,8(sp)
    80001fea:	6902                	ld	s2,0(sp)
    80001fec:	6105                	addi	sp,sp,32
    80001fee:	8082                	ret

0000000080001ff0 <growproc>:
{
    80001ff0:	7179                	addi	sp,sp,-48
    80001ff2:	f406                	sd	ra,40(sp)
    80001ff4:	f022                	sd	s0,32(sp)
    80001ff6:	ec26                	sd	s1,24(sp)
    80001ff8:	e84a                	sd	s2,16(sp)
    80001ffa:	e44e                	sd	s3,8(sp)
    80001ffc:	e052                	sd	s4,0(sp)
    80001ffe:	1800                	addi	s0,sp,48
    80002000:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002002:	00000097          	auipc	ra,0x0
    80002006:	b1c080e7          	jalr	-1252(ra) # 80001b1e <myproc>
    8000200a:	892a                	mv	s2,a0
  sz = p->sz;
    8000200c:	692c                	ld	a1,80(a0)
    8000200e:	0005899b          	sext.w	s3,a1
  if (n > 0)
    80002012:	06905b63          	blez	s1,80002088 <growproc+0x98>
    if (PGROUNDUP(sz + n) >= PLIC)
    80002016:	00048a1b          	sext.w	s4,s1
    8000201a:	013484bb          	addw	s1,s1,s3
    8000201e:	6785                	lui	a5,0x1
    80002020:	37fd                	addiw	a5,a5,-1
    80002022:	9fa5                	addw	a5,a5,s1
    80002024:	777d                	lui	a4,0xfffff
    80002026:	8ff9                	and	a5,a5,a4
    80002028:	2781                	sext.w	a5,a5
    8000202a:	0c000737          	lui	a4,0xc000
    8000202e:	06e7fd63          	bgeu	a5,a4,800020a8 <growproc+0xb8>
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80002032:	02049613          	slli	a2,s1,0x20
    80002036:	9201                	srli	a2,a2,0x20
    80002038:	1582                	slli	a1,a1,0x20
    8000203a:	9181                	srli	a1,a1,0x20
    8000203c:	6d28                	ld	a0,88(a0)
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	454080e7          	jalr	1108(ra) # 80001492 <uvmalloc>
    80002046:	0005099b          	sext.w	s3,a0
    8000204a:	06098163          	beqz	s3,800020ac <growproc+0xbc>
    u2kvmcopy(p->pagetable, p->kpagetable, sz - n, sz);
    8000204e:	4149863b          	subw	a2,s3,s4
    80002052:	02051693          	slli	a3,a0,0x20
    80002056:	9281                	srli	a3,a3,0x20
    80002058:	1602                	slli	a2,a2,0x20
    8000205a:	9201                	srli	a2,a2,0x20
    8000205c:	01893583          	ld	a1,24(s2) # 1018 <_entry-0x7fffefe8>
    80002060:	05893503          	ld	a0,88(s2)
    80002064:	00000097          	auipc	ra,0x0
    80002068:	948080e7          	jalr	-1720(ra) # 800019ac <u2kvmcopy>
  p->sz = sz;
    8000206c:	02099613          	slli	a2,s3,0x20
    80002070:	9201                	srli	a2,a2,0x20
    80002072:	04c93823          	sd	a2,80(s2)
  return 0;
    80002076:	4501                	li	a0,0
}
    80002078:	70a2                	ld	ra,40(sp)
    8000207a:	7402                	ld	s0,32(sp)
    8000207c:	64e2                	ld	s1,24(sp)
    8000207e:	6942                	ld	s2,16(sp)
    80002080:	69a2                	ld	s3,8(sp)
    80002082:	6a02                	ld	s4,0(sp)
    80002084:	6145                	addi	sp,sp,48
    80002086:	8082                	ret
  else if (n < 0)
    80002088:	fe04d2e3          	bgez	s1,8000206c <growproc+0x7c>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000208c:	0134863b          	addw	a2,s1,s3
    80002090:	1602                	slli	a2,a2,0x20
    80002092:	9201                	srli	a2,a2,0x20
    80002094:	1582                	slli	a1,a1,0x20
    80002096:	9181                	srli	a1,a1,0x20
    80002098:	6d28                	ld	a0,88(a0)
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	3b0080e7          	jalr	944(ra) # 8000144a <uvmdealloc>
    800020a2:	0005099b          	sext.w	s3,a0
    800020a6:	b7d9                	j	8000206c <growproc+0x7c>
      return -1;//如果将进程的大小增加 n 之后，向上对齐到页的边界后的结果大于等于 PLIC（外部中断控制器）的地址，就返回 -1
    800020a8:	557d                	li	a0,-1
    800020aa:	b7f9                	j	80002078 <growproc+0x88>
      return -1;//调用 uvmalloc 函数，根据参数 sz 和 sz + n 来分配新的用户虚拟内存空间。如果分配失败，返回 -1。
    800020ac:	557d                	li	a0,-1
    800020ae:	b7e9                	j	80002078 <growproc+0x88>

00000000800020b0 <fork>:
{
    800020b0:	7179                	addi	sp,sp,-48
    800020b2:	f406                	sd	ra,40(sp)
    800020b4:	f022                	sd	s0,32(sp)
    800020b6:	ec26                	sd	s1,24(sp)
    800020b8:	e84a                	sd	s2,16(sp)
    800020ba:	e44e                	sd	s3,8(sp)
    800020bc:	e052                	sd	s4,0(sp)
    800020be:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020c0:	00000097          	auipc	ra,0x0
    800020c4:	a5e080e7          	jalr	-1442(ra) # 80001b1e <myproc>
    800020c8:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    800020ca:	00000097          	auipc	ra,0x0
    800020ce:	d4a080e7          	jalr	-694(ra) # 80001e14 <allocproc>
    800020d2:	cd6d                	beqz	a0,800021cc <fork+0x11c>
    800020d4:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800020d6:	05093603          	ld	a2,80(s2)
    800020da:	6d2c                	ld	a1,88(a0)
    800020dc:	05893503          	ld	a0,88(s2)
    800020e0:	fffff097          	auipc	ra,0xfffff
    800020e4:	4fe080e7          	jalr	1278(ra) # 800015de <uvmcopy>
    800020e8:	04054863          	bltz	a0,80002138 <fork+0x88>
  np->sz = p->sz;
    800020ec:	05093783          	ld	a5,80(s2)
    800020f0:	04f9b823          	sd	a5,80(s3)
  np->parent = p;
    800020f4:	0329b423          	sd	s2,40(s3)
  *(np->trapframe) = *(p->trapframe);
    800020f8:	06093683          	ld	a3,96(s2)
    800020fc:	87b6                	mv	a5,a3
    800020fe:	0609b703          	ld	a4,96(s3)
    80002102:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    80002106:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000210a:	6788                	ld	a0,8(a5)
    8000210c:	6b8c                	ld	a1,16(a5)
    8000210e:	6f90                	ld	a2,24(a5)
    80002110:	01073023          	sd	a6,0(a4) # c000000 <_entry-0x74000000>
    80002114:	e708                	sd	a0,8(a4)
    80002116:	eb0c                	sd	a1,16(a4)
    80002118:	ef10                	sd	a2,24(a4)
    8000211a:	02078793          	addi	a5,a5,32
    8000211e:	02070713          	addi	a4,a4,32
    80002122:	fed792e3          	bne	a5,a3,80002106 <fork+0x56>
  np->trapframe->a0 = 0;
    80002126:	0609b783          	ld	a5,96(s3)
    8000212a:	0607b823          	sd	zero,112(a5)
    8000212e:	0d800493          	li	s1,216
  for (i = 0; i < NOFILE; i++)
    80002132:	15800a13          	li	s4,344
    80002136:	a03d                	j	80002164 <fork+0xb4>
    freeproc(np);
    80002138:	854e                	mv	a0,s3
    8000213a:	00000097          	auipc	ra,0x0
    8000213e:	c3a080e7          	jalr	-966(ra) # 80001d74 <freeproc>
    release(&np->lock);
    80002142:	854e                	mv	a0,s3
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	b80080e7          	jalr	-1152(ra) # 80000cc4 <release>
    return -1;
    8000214c:	54fd                	li	s1,-1
    8000214e:	a0b5                	j	800021ba <fork+0x10a>
      np->ofile[i] = filedup(p->ofile[i]);
    80002150:	00002097          	auipc	ra,0x2
    80002154:	638080e7          	jalr	1592(ra) # 80004788 <filedup>
    80002158:	009987b3          	add	a5,s3,s1
    8000215c:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    8000215e:	04a1                	addi	s1,s1,8
    80002160:	01448763          	beq	s1,s4,8000216e <fork+0xbe>
    if (p->ofile[i])
    80002164:	009907b3          	add	a5,s2,s1
    80002168:	6388                	ld	a0,0(a5)
    8000216a:	f17d                	bnez	a0,80002150 <fork+0xa0>
    8000216c:	bfcd                	j	8000215e <fork+0xae>
  np->cwd = idup(p->cwd);
    8000216e:	15893503          	ld	a0,344(s2)
    80002172:	00001097          	auipc	ra,0x1
    80002176:	79c080e7          	jalr	1948(ra) # 8000390e <idup>
    8000217a:	14a9bc23          	sd	a0,344(s3)
  u2kvmcopy(np->pagetable, np->kpagetable, 0, np->sz);
    8000217e:	0509b683          	ld	a3,80(s3)
    80002182:	4601                	li	a2,0
    80002184:	0189b583          	ld	a1,24(s3)
    80002188:	0589b503          	ld	a0,88(s3)
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	820080e7          	jalr	-2016(ra) # 800019ac <u2kvmcopy>
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002194:	4641                	li	a2,16
    80002196:	16090593          	addi	a1,s2,352
    8000219a:	16098513          	addi	a0,s3,352
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	cc4080e7          	jalr	-828(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    800021a6:	0409a483          	lw	s1,64(s3)
  np->state = RUNNABLE;
    800021aa:	4789                	li	a5,2
    800021ac:	02f9a023          	sw	a5,32(s3)
  release(&np->lock);
    800021b0:	854e                	mv	a0,s3
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	b12080e7          	jalr	-1262(ra) # 80000cc4 <release>
}
    800021ba:	8526                	mv	a0,s1
    800021bc:	70a2                	ld	ra,40(sp)
    800021be:	7402                	ld	s0,32(sp)
    800021c0:	64e2                	ld	s1,24(sp)
    800021c2:	6942                	ld	s2,16(sp)
    800021c4:	69a2                	ld	s3,8(sp)
    800021c6:	6a02                	ld	s4,0(sp)
    800021c8:	6145                	addi	sp,sp,48
    800021ca:	8082                	ret
    return -1;
    800021cc:	54fd                	li	s1,-1
    800021ce:	b7f5                	j	800021ba <fork+0x10a>

00000000800021d0 <reparent>:
{
    800021d0:	7179                	addi	sp,sp,-48
    800021d2:	f406                	sd	ra,40(sp)
    800021d4:	f022                	sd	s0,32(sp)
    800021d6:	ec26                	sd	s1,24(sp)
    800021d8:	e84a                	sd	s2,16(sp)
    800021da:	e44e                	sd	s3,8(sp)
    800021dc:	e052                	sd	s4,0(sp)
    800021de:	1800                	addi	s0,sp,48
    800021e0:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800021e2:	00010497          	auipc	s1,0x10
    800021e6:	b8648493          	addi	s1,s1,-1146 # 80011d68 <proc>
      pp->parent = initproc;
    800021ea:	00007a17          	auipc	s4,0x7
    800021ee:	e2ea0a13          	addi	s4,s4,-466 # 80009018 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800021f2:	00015997          	auipc	s3,0x15
    800021f6:	77698993          	addi	s3,s3,1910 # 80017968 <tickslock>
    800021fa:	a029                	j	80002204 <reparent+0x34>
    800021fc:	17048493          	addi	s1,s1,368
    80002200:	03348363          	beq	s1,s3,80002226 <reparent+0x56>
    if (pp->parent == p)
    80002204:	749c                	ld	a5,40(s1)
    80002206:	ff279be3          	bne	a5,s2,800021fc <reparent+0x2c>
      acquire(&pp->lock);
    8000220a:	8526                	mv	a0,s1
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	a04080e7          	jalr	-1532(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    80002214:	000a3783          	ld	a5,0(s4)
    80002218:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    8000221a:	8526                	mv	a0,s1
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	aa8080e7          	jalr	-1368(ra) # 80000cc4 <release>
    80002224:	bfe1                	j	800021fc <reparent+0x2c>
}
    80002226:	70a2                	ld	ra,40(sp)
    80002228:	7402                	ld	s0,32(sp)
    8000222a:	64e2                	ld	s1,24(sp)
    8000222c:	6942                	ld	s2,16(sp)
    8000222e:	69a2                	ld	s3,8(sp)
    80002230:	6a02                	ld	s4,0(sp)
    80002232:	6145                	addi	sp,sp,48
    80002234:	8082                	ret

0000000080002236 <scheduler>:
{
    80002236:	715d                	addi	sp,sp,-80
    80002238:	e486                	sd	ra,72(sp)
    8000223a:	e0a2                	sd	s0,64(sp)
    8000223c:	fc26                	sd	s1,56(sp)
    8000223e:	f84a                	sd	s2,48(sp)
    80002240:	f44e                	sd	s3,40(sp)
    80002242:	f052                	sd	s4,32(sp)
    80002244:	ec56                	sd	s5,24(sp)
    80002246:	e85a                	sd	s6,16(sp)
    80002248:	e45e                	sd	s7,8(sp)
    8000224a:	e062                	sd	s8,0(sp)
    8000224c:	0880                	addi	s0,sp,80
    8000224e:	8792                	mv	a5,tp
  int id = r_tp();
    80002250:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002252:	00779b13          	slli	s6,a5,0x7
    80002256:	0000f717          	auipc	a4,0xf
    8000225a:	6fa70713          	addi	a4,a4,1786 # 80011950 <pid_lock>
    8000225e:	975a                	add	a4,a4,s6
    80002260:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002264:	0000f717          	auipc	a4,0xf
    80002268:	70c70713          	addi	a4,a4,1804 # 80011970 <cpus+0x8>
    8000226c:	9b3a                	add	s6,s6,a4
        c->proc = p;
    8000226e:	079e                	slli	a5,a5,0x7
    80002270:	0000fa17          	auipc	s4,0xf
    80002274:	6e0a0a13          	addi	s4,s4,1760 # 80011950 <pid_lock>
    80002278:	9a3e                	add	s4,s4,a5
        w_satp(MAKE_SATP(p->kpagetable));
    8000227a:	5bfd                	li	s7,-1
    8000227c:	1bfe                	slli	s7,s7,0x3f
    for (p = proc; p < &proc[NPROC]; p++)
    8000227e:	00015997          	auipc	s3,0x15
    80002282:	6ea98993          	addi	s3,s3,1770 # 80017968 <tickslock>
    80002286:	a0bd                	j	800022f4 <scheduler+0xbe>
        p->state = RUNNING;
    80002288:	0354a023          	sw	s5,32(s1)
        c->proc = p;
    8000228c:	009a3c23          	sd	s1,24(s4)
        w_satp(MAKE_SATP(p->kpagetable));
    80002290:	6c9c                	ld	a5,24(s1)
    80002292:	83b1                	srli	a5,a5,0xc
    80002294:	0177e7b3          	or	a5,a5,s7
  asm volatile("csrw satp, %0" : : "r" (x));
    80002298:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000229c:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    800022a0:	06848593          	addi	a1,s1,104
    800022a4:	855a                	mv	a0,s6
    800022a6:	00000097          	auipc	ra,0x0
    800022aa:	642080e7          	jalr	1602(ra) # 800028e8 <swtch>
        kvminithart();
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	d2e080e7          	jalr	-722(ra) # 80000fdc <kvminithart>
        c->proc = 0;
    800022b6:	000a3c23          	sd	zero,24(s4)
        found = 1;
    800022ba:	4c05                	li	s8,1
      release(&p->lock);
    800022bc:	8526                	mv	a0,s1
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	a06080e7          	jalr	-1530(ra) # 80000cc4 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800022c6:	17048493          	addi	s1,s1,368
    800022ca:	01348b63          	beq	s1,s3,800022e0 <scheduler+0xaa>
      acquire(&p->lock);
    800022ce:	8526                	mv	a0,s1
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	940080e7          	jalr	-1728(ra) # 80000c10 <acquire>
      if (p->state == RUNNABLE)
    800022d8:	509c                	lw	a5,32(s1)
    800022da:	ff2791e3          	bne	a5,s2,800022bc <scheduler+0x86>
    800022de:	b76d                	j	80002288 <scheduler+0x52>
    if (found == 0)
    800022e0:	000c1a63          	bnez	s8,800022f4 <scheduler+0xbe>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022e4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022e8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022ec:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800022f0:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022f4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022f8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022fc:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002300:	4c01                	li	s8,0
    for (p = proc; p < &proc[NPROC]; p++)
    80002302:	00010497          	auipc	s1,0x10
    80002306:	a6648493          	addi	s1,s1,-1434 # 80011d68 <proc>
      if (p->state == RUNNABLE)
    8000230a:	4909                	li	s2,2
        p->state = RUNNING;
    8000230c:	4a8d                	li	s5,3
    8000230e:	b7c1                	j	800022ce <scheduler+0x98>

0000000080002310 <sched>:
{
    80002310:	7179                	addi	sp,sp,-48
    80002312:	f406                	sd	ra,40(sp)
    80002314:	f022                	sd	s0,32(sp)
    80002316:	ec26                	sd	s1,24(sp)
    80002318:	e84a                	sd	s2,16(sp)
    8000231a:	e44e                	sd	s3,8(sp)
    8000231c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000231e:	00000097          	auipc	ra,0x0
    80002322:	800080e7          	jalr	-2048(ra) # 80001b1e <myproc>
    80002326:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	86e080e7          	jalr	-1938(ra) # 80000b96 <holding>
    80002330:	c93d                	beqz	a0,800023a6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002332:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002334:	2781                	sext.w	a5,a5
    80002336:	079e                	slli	a5,a5,0x7
    80002338:	0000f717          	auipc	a4,0xf
    8000233c:	61870713          	addi	a4,a4,1560 # 80011950 <pid_lock>
    80002340:	97ba                	add	a5,a5,a4
    80002342:	0907a703          	lw	a4,144(a5)
    80002346:	4785                	li	a5,1
    80002348:	06f71763          	bne	a4,a5,800023b6 <sched+0xa6>
  if (p->state == RUNNING)
    8000234c:	5098                	lw	a4,32(s1)
    8000234e:	478d                	li	a5,3
    80002350:	06f70b63          	beq	a4,a5,800023c6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002354:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002358:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000235a:	efb5                	bnez	a5,800023d6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000235c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000235e:	0000f917          	auipc	s2,0xf
    80002362:	5f290913          	addi	s2,s2,1522 # 80011950 <pid_lock>
    80002366:	2781                	sext.w	a5,a5
    80002368:	079e                	slli	a5,a5,0x7
    8000236a:	97ca                	add	a5,a5,s2
    8000236c:	0947a983          	lw	s3,148(a5)
    80002370:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002372:	2781                	sext.w	a5,a5
    80002374:	079e                	slli	a5,a5,0x7
    80002376:	0000f597          	auipc	a1,0xf
    8000237a:	5fa58593          	addi	a1,a1,1530 # 80011970 <cpus+0x8>
    8000237e:	95be                	add	a1,a1,a5
    80002380:	06848513          	addi	a0,s1,104
    80002384:	00000097          	auipc	ra,0x0
    80002388:	564080e7          	jalr	1380(ra) # 800028e8 <swtch>
    8000238c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000238e:	2781                	sext.w	a5,a5
    80002390:	079e                	slli	a5,a5,0x7
    80002392:	97ca                	add	a5,a5,s2
    80002394:	0937aa23          	sw	s3,148(a5)
}
    80002398:	70a2                	ld	ra,40(sp)
    8000239a:	7402                	ld	s0,32(sp)
    8000239c:	64e2                	ld	s1,24(sp)
    8000239e:	6942                	ld	s2,16(sp)
    800023a0:	69a2                	ld	s3,8(sp)
    800023a2:	6145                	addi	sp,sp,48
    800023a4:	8082                	ret
    panic("sched p->lock");
    800023a6:	00006517          	auipc	a0,0x6
    800023aa:	ee250513          	addi	a0,a0,-286 # 80008288 <digits+0x248>
    800023ae:	ffffe097          	auipc	ra,0xffffe
    800023b2:	19a080e7          	jalr	410(ra) # 80000548 <panic>
    panic("sched locks");
    800023b6:	00006517          	auipc	a0,0x6
    800023ba:	ee250513          	addi	a0,a0,-286 # 80008298 <digits+0x258>
    800023be:	ffffe097          	auipc	ra,0xffffe
    800023c2:	18a080e7          	jalr	394(ra) # 80000548 <panic>
    panic("sched running");
    800023c6:	00006517          	auipc	a0,0x6
    800023ca:	ee250513          	addi	a0,a0,-286 # 800082a8 <digits+0x268>
    800023ce:	ffffe097          	auipc	ra,0xffffe
    800023d2:	17a080e7          	jalr	378(ra) # 80000548 <panic>
    panic("sched interruptible");
    800023d6:	00006517          	auipc	a0,0x6
    800023da:	ee250513          	addi	a0,a0,-286 # 800082b8 <digits+0x278>
    800023de:	ffffe097          	auipc	ra,0xffffe
    800023e2:	16a080e7          	jalr	362(ra) # 80000548 <panic>

00000000800023e6 <exit>:
{
    800023e6:	7179                	addi	sp,sp,-48
    800023e8:	f406                	sd	ra,40(sp)
    800023ea:	f022                	sd	s0,32(sp)
    800023ec:	ec26                	sd	s1,24(sp)
    800023ee:	e84a                	sd	s2,16(sp)
    800023f0:	e44e                	sd	s3,8(sp)
    800023f2:	e052                	sd	s4,0(sp)
    800023f4:	1800                	addi	s0,sp,48
    800023f6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	726080e7          	jalr	1830(ra) # 80001b1e <myproc>
    80002400:	89aa                	mv	s3,a0
  if (p == initproc)
    80002402:	00007797          	auipc	a5,0x7
    80002406:	c167b783          	ld	a5,-1002(a5) # 80009018 <initproc>
    8000240a:	0d850493          	addi	s1,a0,216
    8000240e:	15850913          	addi	s2,a0,344
    80002412:	02a79363          	bne	a5,a0,80002438 <exit+0x52>
    panic("init exiting");
    80002416:	00006517          	auipc	a0,0x6
    8000241a:	eba50513          	addi	a0,a0,-326 # 800082d0 <digits+0x290>
    8000241e:	ffffe097          	auipc	ra,0xffffe
    80002422:	12a080e7          	jalr	298(ra) # 80000548 <panic>
      fileclose(f);
    80002426:	00002097          	auipc	ra,0x2
    8000242a:	3b4080e7          	jalr	948(ra) # 800047da <fileclose>
      p->ofile[fd] = 0;
    8000242e:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002432:	04a1                	addi	s1,s1,8
    80002434:	01248563          	beq	s1,s2,8000243e <exit+0x58>
    if (p->ofile[fd])
    80002438:	6088                	ld	a0,0(s1)
    8000243a:	f575                	bnez	a0,80002426 <exit+0x40>
    8000243c:	bfdd                	j	80002432 <exit+0x4c>
  begin_op();
    8000243e:	00002097          	auipc	ra,0x2
    80002442:	eca080e7          	jalr	-310(ra) # 80004308 <begin_op>
  iput(p->cwd);
    80002446:	1589b503          	ld	a0,344(s3)
    8000244a:	00001097          	auipc	ra,0x1
    8000244e:	6bc080e7          	jalr	1724(ra) # 80003b06 <iput>
  end_op();
    80002452:	00002097          	auipc	ra,0x2
    80002456:	f36080e7          	jalr	-202(ra) # 80004388 <end_op>
  p->cwd = 0;
    8000245a:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    8000245e:	00007497          	auipc	s1,0x7
    80002462:	bba48493          	addi	s1,s1,-1094 # 80009018 <initproc>
    80002466:	6088                	ld	a0,0(s1)
    80002468:	ffffe097          	auipc	ra,0xffffe
    8000246c:	7a8080e7          	jalr	1960(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    80002470:	6088                	ld	a0,0(s1)
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	5dc080e7          	jalr	1500(ra) # 80001a4e <wakeup1>
  release(&initproc->lock);
    8000247a:	6088                	ld	a0,0(s1)
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	848080e7          	jalr	-1976(ra) # 80000cc4 <release>
  acquire(&p->lock);
    80002484:	854e                	mv	a0,s3
    80002486:	ffffe097          	auipc	ra,0xffffe
    8000248a:	78a080e7          	jalr	1930(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    8000248e:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    80002492:	854e                	mv	a0,s3
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	830080e7          	jalr	-2000(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    8000249c:	8526                	mv	a0,s1
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	772080e7          	jalr	1906(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    800024a6:	854e                	mv	a0,s3
    800024a8:	ffffe097          	auipc	ra,0xffffe
    800024ac:	768080e7          	jalr	1896(ra) # 80000c10 <acquire>
  reparent(p);
    800024b0:	854e                	mv	a0,s3
    800024b2:	00000097          	auipc	ra,0x0
    800024b6:	d1e080e7          	jalr	-738(ra) # 800021d0 <reparent>
  wakeup1(original_parent);
    800024ba:	8526                	mv	a0,s1
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	592080e7          	jalr	1426(ra) # 80001a4e <wakeup1>
  p->xstate = status;
    800024c4:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    800024c8:	4791                	li	a5,4
    800024ca:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    800024ce:	8526                	mv	a0,s1
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	7f4080e7          	jalr	2036(ra) # 80000cc4 <release>
  sched();
    800024d8:	00000097          	auipc	ra,0x0
    800024dc:	e38080e7          	jalr	-456(ra) # 80002310 <sched>
  panic("zombie exit");
    800024e0:	00006517          	auipc	a0,0x6
    800024e4:	e0050513          	addi	a0,a0,-512 # 800082e0 <digits+0x2a0>
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	060080e7          	jalr	96(ra) # 80000548 <panic>

00000000800024f0 <yield>:
{
    800024f0:	1101                	addi	sp,sp,-32
    800024f2:	ec06                	sd	ra,24(sp)
    800024f4:	e822                	sd	s0,16(sp)
    800024f6:	e426                	sd	s1,8(sp)
    800024f8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024fa:	fffff097          	auipc	ra,0xfffff
    800024fe:	624080e7          	jalr	1572(ra) # 80001b1e <myproc>
    80002502:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	70c080e7          	jalr	1804(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    8000250c:	4789                	li	a5,2
    8000250e:	d09c                	sw	a5,32(s1)
  sched();
    80002510:	00000097          	auipc	ra,0x0
    80002514:	e00080e7          	jalr	-512(ra) # 80002310 <sched>
  release(&p->lock);
    80002518:	8526                	mv	a0,s1
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	7aa080e7          	jalr	1962(ra) # 80000cc4 <release>
}
    80002522:	60e2                	ld	ra,24(sp)
    80002524:	6442                	ld	s0,16(sp)
    80002526:	64a2                	ld	s1,8(sp)
    80002528:	6105                	addi	sp,sp,32
    8000252a:	8082                	ret

000000008000252c <sleep>:
{
    8000252c:	7179                	addi	sp,sp,-48
    8000252e:	f406                	sd	ra,40(sp)
    80002530:	f022                	sd	s0,32(sp)
    80002532:	ec26                	sd	s1,24(sp)
    80002534:	e84a                	sd	s2,16(sp)
    80002536:	e44e                	sd	s3,8(sp)
    80002538:	1800                	addi	s0,sp,48
    8000253a:	89aa                	mv	s3,a0
    8000253c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	5e0080e7          	jalr	1504(ra) # 80001b1e <myproc>
    80002546:	84aa                	mv	s1,a0
  if (lk != &p->lock)
    80002548:	05250663          	beq	a0,s2,80002594 <sleep+0x68>
    acquire(&p->lock); // DOC: sleeplock1
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	6c4080e7          	jalr	1732(ra) # 80000c10 <acquire>
    release(lk);
    80002554:	854a                	mv	a0,s2
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	76e080e7          	jalr	1902(ra) # 80000cc4 <release>
  p->chan = chan;
    8000255e:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    80002562:	4785                	li	a5,1
    80002564:	d09c                	sw	a5,32(s1)
  sched();
    80002566:	00000097          	auipc	ra,0x0
    8000256a:	daa080e7          	jalr	-598(ra) # 80002310 <sched>
  p->chan = 0;
    8000256e:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    80002572:	8526                	mv	a0,s1
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	750080e7          	jalr	1872(ra) # 80000cc4 <release>
    acquire(lk);
    8000257c:	854a                	mv	a0,s2
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	692080e7          	jalr	1682(ra) # 80000c10 <acquire>
}
    80002586:	70a2                	ld	ra,40(sp)
    80002588:	7402                	ld	s0,32(sp)
    8000258a:	64e2                	ld	s1,24(sp)
    8000258c:	6942                	ld	s2,16(sp)
    8000258e:	69a2                	ld	s3,8(sp)
    80002590:	6145                	addi	sp,sp,48
    80002592:	8082                	ret
  p->chan = chan;
    80002594:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    80002598:	4785                	li	a5,1
    8000259a:	d11c                	sw	a5,32(a0)
  sched();
    8000259c:	00000097          	auipc	ra,0x0
    800025a0:	d74080e7          	jalr	-652(ra) # 80002310 <sched>
  p->chan = 0;
    800025a4:	0204b823          	sd	zero,48(s1)
  if (lk != &p->lock)
    800025a8:	bff9                	j	80002586 <sleep+0x5a>

00000000800025aa <wait>:
{
    800025aa:	715d                	addi	sp,sp,-80
    800025ac:	e486                	sd	ra,72(sp)
    800025ae:	e0a2                	sd	s0,64(sp)
    800025b0:	fc26                	sd	s1,56(sp)
    800025b2:	f84a                	sd	s2,48(sp)
    800025b4:	f44e                	sd	s3,40(sp)
    800025b6:	f052                	sd	s4,32(sp)
    800025b8:	ec56                	sd	s5,24(sp)
    800025ba:	e85a                	sd	s6,16(sp)
    800025bc:	e45e                	sd	s7,8(sp)
    800025be:	e062                	sd	s8,0(sp)
    800025c0:	0880                	addi	s0,sp,80
    800025c2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025c4:	fffff097          	auipc	ra,0xfffff
    800025c8:	55a080e7          	jalr	1370(ra) # 80001b1e <myproc>
    800025cc:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025ce:	8c2a                	mv	s8,a0
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	640080e7          	jalr	1600(ra) # 80000c10 <acquire>
    havekids = 0;
    800025d8:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    800025da:	4a11                	li	s4,4
    for (np = proc; np < &proc[NPROC]; np++)
    800025dc:	00015997          	auipc	s3,0x15
    800025e0:	38c98993          	addi	s3,s3,908 # 80017968 <tickslock>
        havekids = 1;
    800025e4:	4a85                	li	s5,1
    havekids = 0;
    800025e6:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800025e8:	0000f497          	auipc	s1,0xf
    800025ec:	78048493          	addi	s1,s1,1920 # 80011d68 <proc>
    800025f0:	a08d                	j	80002652 <wait+0xa8>
          pid = np->pid;
    800025f2:	0404a983          	lw	s3,64(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025f6:	000b0e63          	beqz	s6,80002612 <wait+0x68>
    800025fa:	4691                	li	a3,4
    800025fc:	03c48613          	addi	a2,s1,60
    80002600:	85da                	mv	a1,s6
    80002602:	05893503          	ld	a0,88(s2)
    80002606:	fffff097          	auipc	ra,0xfffff
    8000260a:	0dc080e7          	jalr	220(ra) # 800016e2 <copyout>
    8000260e:	02054263          	bltz	a0,80002632 <wait+0x88>
          freeproc(np);
    80002612:	8526                	mv	a0,s1
    80002614:	fffff097          	auipc	ra,0xfffff
    80002618:	760080e7          	jalr	1888(ra) # 80001d74 <freeproc>
          release(&np->lock);
    8000261c:	8526                	mv	a0,s1
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	6a6080e7          	jalr	1702(ra) # 80000cc4 <release>
          release(&p->lock);
    80002626:	854a                	mv	a0,s2
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	69c080e7          	jalr	1692(ra) # 80000cc4 <release>
          return pid;
    80002630:	a8a9                	j	8000268a <wait+0xe0>
            release(&np->lock);
    80002632:	8526                	mv	a0,s1
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	690080e7          	jalr	1680(ra) # 80000cc4 <release>
            release(&p->lock);
    8000263c:	854a                	mv	a0,s2
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	686080e7          	jalr	1670(ra) # 80000cc4 <release>
            return -1;
    80002646:	59fd                	li	s3,-1
    80002648:	a089                	j	8000268a <wait+0xe0>
    for (np = proc; np < &proc[NPROC]; np++)
    8000264a:	17048493          	addi	s1,s1,368
    8000264e:	03348463          	beq	s1,s3,80002676 <wait+0xcc>
      if (np->parent == p)
    80002652:	749c                	ld	a5,40(s1)
    80002654:	ff279be3          	bne	a5,s2,8000264a <wait+0xa0>
        acquire(&np->lock);
    80002658:	8526                	mv	a0,s1
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	5b6080e7          	jalr	1462(ra) # 80000c10 <acquire>
        if (np->state == ZOMBIE)
    80002662:	509c                	lw	a5,32(s1)
    80002664:	f94787e3          	beq	a5,s4,800025f2 <wait+0x48>
        release(&np->lock);
    80002668:	8526                	mv	a0,s1
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	65a080e7          	jalr	1626(ra) # 80000cc4 <release>
        havekids = 1;
    80002672:	8756                	mv	a4,s5
    80002674:	bfd9                	j	8000264a <wait+0xa0>
    if (!havekids || p->killed)
    80002676:	c701                	beqz	a4,8000267e <wait+0xd4>
    80002678:	03892783          	lw	a5,56(s2)
    8000267c:	c785                	beqz	a5,800026a4 <wait+0xfa>
      release(&p->lock);
    8000267e:	854a                	mv	a0,s2
    80002680:	ffffe097          	auipc	ra,0xffffe
    80002684:	644080e7          	jalr	1604(ra) # 80000cc4 <release>
      return -1;
    80002688:	59fd                	li	s3,-1
}
    8000268a:	854e                	mv	a0,s3
    8000268c:	60a6                	ld	ra,72(sp)
    8000268e:	6406                	ld	s0,64(sp)
    80002690:	74e2                	ld	s1,56(sp)
    80002692:	7942                	ld	s2,48(sp)
    80002694:	79a2                	ld	s3,40(sp)
    80002696:	7a02                	ld	s4,32(sp)
    80002698:	6ae2                	ld	s5,24(sp)
    8000269a:	6b42                	ld	s6,16(sp)
    8000269c:	6ba2                	ld	s7,8(sp)
    8000269e:	6c02                	ld	s8,0(sp)
    800026a0:	6161                	addi	sp,sp,80
    800026a2:	8082                	ret
    sleep(p, &p->lock); // DOC: wait-sleep
    800026a4:	85e2                	mv	a1,s8
    800026a6:	854a                	mv	a0,s2
    800026a8:	00000097          	auipc	ra,0x0
    800026ac:	e84080e7          	jalr	-380(ra) # 8000252c <sleep>
    havekids = 0;
    800026b0:	bf1d                	j	800025e6 <wait+0x3c>

00000000800026b2 <wakeup>:
{
    800026b2:	7139                	addi	sp,sp,-64
    800026b4:	fc06                	sd	ra,56(sp)
    800026b6:	f822                	sd	s0,48(sp)
    800026b8:	f426                	sd	s1,40(sp)
    800026ba:	f04a                	sd	s2,32(sp)
    800026bc:	ec4e                	sd	s3,24(sp)
    800026be:	e852                	sd	s4,16(sp)
    800026c0:	e456                	sd	s5,8(sp)
    800026c2:	0080                	addi	s0,sp,64
    800026c4:	8a2a                	mv	s4,a0
  for (p = proc; p < &proc[NPROC]; p++)
    800026c6:	0000f497          	auipc	s1,0xf
    800026ca:	6a248493          	addi	s1,s1,1698 # 80011d68 <proc>
    if (p->state == SLEEPING && p->chan == chan)
    800026ce:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026d0:	4a89                	li	s5,2
  for (p = proc; p < &proc[NPROC]; p++)
    800026d2:	00015917          	auipc	s2,0x15
    800026d6:	29690913          	addi	s2,s2,662 # 80017968 <tickslock>
    800026da:	a821                	j	800026f2 <wakeup+0x40>
      p->state = RUNNABLE;
    800026dc:	0354a023          	sw	s5,32(s1)
    release(&p->lock);
    800026e0:	8526                	mv	a0,s1
    800026e2:	ffffe097          	auipc	ra,0xffffe
    800026e6:	5e2080e7          	jalr	1506(ra) # 80000cc4 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800026ea:	17048493          	addi	s1,s1,368
    800026ee:	01248e63          	beq	s1,s2,8000270a <wakeup+0x58>
    acquire(&p->lock);
    800026f2:	8526                	mv	a0,s1
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	51c080e7          	jalr	1308(ra) # 80000c10 <acquire>
    if (p->state == SLEEPING && p->chan == chan)
    800026fc:	509c                	lw	a5,32(s1)
    800026fe:	ff3791e3          	bne	a5,s3,800026e0 <wakeup+0x2e>
    80002702:	789c                	ld	a5,48(s1)
    80002704:	fd479ee3          	bne	a5,s4,800026e0 <wakeup+0x2e>
    80002708:	bfd1                	j	800026dc <wakeup+0x2a>
}
    8000270a:	70e2                	ld	ra,56(sp)
    8000270c:	7442                	ld	s0,48(sp)
    8000270e:	74a2                	ld	s1,40(sp)
    80002710:	7902                	ld	s2,32(sp)
    80002712:	69e2                	ld	s3,24(sp)
    80002714:	6a42                	ld	s4,16(sp)
    80002716:	6aa2                	ld	s5,8(sp)
    80002718:	6121                	addi	sp,sp,64
    8000271a:	8082                	ret

000000008000271c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000271c:	7179                	addi	sp,sp,-48
    8000271e:	f406                	sd	ra,40(sp)
    80002720:	f022                	sd	s0,32(sp)
    80002722:	ec26                	sd	s1,24(sp)
    80002724:	e84a                	sd	s2,16(sp)
    80002726:	e44e                	sd	s3,8(sp)
    80002728:	1800                	addi	s0,sp,48
    8000272a:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000272c:	0000f497          	auipc	s1,0xf
    80002730:	63c48493          	addi	s1,s1,1596 # 80011d68 <proc>
    80002734:	00015997          	auipc	s3,0x15
    80002738:	23498993          	addi	s3,s3,564 # 80017968 <tickslock>
  {
    acquire(&p->lock);
    8000273c:	8526                	mv	a0,s1
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	4d2080e7          	jalr	1234(ra) # 80000c10 <acquire>
    if (p->pid == pid)
    80002746:	40bc                	lw	a5,64(s1)
    80002748:	01278d63          	beq	a5,s2,80002762 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000274c:	8526                	mv	a0,s1
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	576080e7          	jalr	1398(ra) # 80000cc4 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002756:	17048493          	addi	s1,s1,368
    8000275a:	ff3491e3          	bne	s1,s3,8000273c <kill+0x20>
  }
  return -1;
    8000275e:	557d                	li	a0,-1
    80002760:	a829                	j	8000277a <kill+0x5e>
      p->killed = 1;
    80002762:	4785                	li	a5,1
    80002764:	dc9c                	sw	a5,56(s1)
      if (p->state == SLEEPING)
    80002766:	5098                	lw	a4,32(s1)
    80002768:	4785                	li	a5,1
    8000276a:	00f70f63          	beq	a4,a5,80002788 <kill+0x6c>
      release(&p->lock);
    8000276e:	8526                	mv	a0,s1
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	554080e7          	jalr	1364(ra) # 80000cc4 <release>
      return 0;
    80002778:	4501                	li	a0,0
}
    8000277a:	70a2                	ld	ra,40(sp)
    8000277c:	7402                	ld	s0,32(sp)
    8000277e:	64e2                	ld	s1,24(sp)
    80002780:	6942                	ld	s2,16(sp)
    80002782:	69a2                	ld	s3,8(sp)
    80002784:	6145                	addi	sp,sp,48
    80002786:	8082                	ret
        p->state = RUNNABLE;
    80002788:	4789                	li	a5,2
    8000278a:	d09c                	sw	a5,32(s1)
    8000278c:	b7cd                	j	8000276e <kill+0x52>

000000008000278e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000278e:	7179                	addi	sp,sp,-48
    80002790:	f406                	sd	ra,40(sp)
    80002792:	f022                	sd	s0,32(sp)
    80002794:	ec26                	sd	s1,24(sp)
    80002796:	e84a                	sd	s2,16(sp)
    80002798:	e44e                	sd	s3,8(sp)
    8000279a:	e052                	sd	s4,0(sp)
    8000279c:	1800                	addi	s0,sp,48
    8000279e:	84aa                	mv	s1,a0
    800027a0:	892e                	mv	s2,a1
    800027a2:	89b2                	mv	s3,a2
    800027a4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027a6:	fffff097          	auipc	ra,0xfffff
    800027aa:	378080e7          	jalr	888(ra) # 80001b1e <myproc>
  if (user_dst)
    800027ae:	c08d                	beqz	s1,800027d0 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800027b0:	86d2                	mv	a3,s4
    800027b2:	864e                	mv	a2,s3
    800027b4:	85ca                	mv	a1,s2
    800027b6:	6d28                	ld	a0,88(a0)
    800027b8:	fffff097          	auipc	ra,0xfffff
    800027bc:	f2a080e7          	jalr	-214(ra) # 800016e2 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027c0:	70a2                	ld	ra,40(sp)
    800027c2:	7402                	ld	s0,32(sp)
    800027c4:	64e2                	ld	s1,24(sp)
    800027c6:	6942                	ld	s2,16(sp)
    800027c8:	69a2                	ld	s3,8(sp)
    800027ca:	6a02                	ld	s4,0(sp)
    800027cc:	6145                	addi	sp,sp,48
    800027ce:	8082                	ret
    memmove((char *)dst, src, len);
    800027d0:	000a061b          	sext.w	a2,s4
    800027d4:	85ce                	mv	a1,s3
    800027d6:	854a                	mv	a0,s2
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	594080e7          	jalr	1428(ra) # 80000d6c <memmove>
    return 0;
    800027e0:	8526                	mv	a0,s1
    800027e2:	bff9                	j	800027c0 <either_copyout+0x32>

00000000800027e4 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027e4:	7179                	addi	sp,sp,-48
    800027e6:	f406                	sd	ra,40(sp)
    800027e8:	f022                	sd	s0,32(sp)
    800027ea:	ec26                	sd	s1,24(sp)
    800027ec:	e84a                	sd	s2,16(sp)
    800027ee:	e44e                	sd	s3,8(sp)
    800027f0:	e052                	sd	s4,0(sp)
    800027f2:	1800                	addi	s0,sp,48
    800027f4:	892a                	mv	s2,a0
    800027f6:	84ae                	mv	s1,a1
    800027f8:	89b2                	mv	s3,a2
    800027fa:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027fc:	fffff097          	auipc	ra,0xfffff
    80002800:	322080e7          	jalr	802(ra) # 80001b1e <myproc>
  if (user_src)
    80002804:	c08d                	beqz	s1,80002826 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002806:	86d2                	mv	a3,s4
    80002808:	864e                	mv	a2,s3
    8000280a:	85ca                	mv	a1,s2
    8000280c:	6d28                	ld	a0,88(a0)
    8000280e:	fffff097          	auipc	ra,0xfffff
    80002812:	f60080e7          	jalr	-160(ra) # 8000176e <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002816:	70a2                	ld	ra,40(sp)
    80002818:	7402                	ld	s0,32(sp)
    8000281a:	64e2                	ld	s1,24(sp)
    8000281c:	6942                	ld	s2,16(sp)
    8000281e:	69a2                	ld	s3,8(sp)
    80002820:	6a02                	ld	s4,0(sp)
    80002822:	6145                	addi	sp,sp,48
    80002824:	8082                	ret
    memmove(dst, (char *)src, len);
    80002826:	000a061b          	sext.w	a2,s4
    8000282a:	85ce                	mv	a1,s3
    8000282c:	854a                	mv	a0,s2
    8000282e:	ffffe097          	auipc	ra,0xffffe
    80002832:	53e080e7          	jalr	1342(ra) # 80000d6c <memmove>
    return 0;
    80002836:	8526                	mv	a0,s1
    80002838:	bff9                	j	80002816 <either_copyin+0x32>

000000008000283a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000283a:	715d                	addi	sp,sp,-80
    8000283c:	e486                	sd	ra,72(sp)
    8000283e:	e0a2                	sd	s0,64(sp)
    80002840:	fc26                	sd	s1,56(sp)
    80002842:	f84a                	sd	s2,48(sp)
    80002844:	f44e                	sd	s3,40(sp)
    80002846:	f052                	sd	s4,32(sp)
    80002848:	ec56                	sd	s5,24(sp)
    8000284a:	e85a                	sd	s6,16(sp)
    8000284c:	e45e                	sd	s7,8(sp)
    8000284e:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002850:	00006517          	auipc	a0,0x6
    80002854:	87850513          	addi	a0,a0,-1928 # 800080c8 <digits+0x88>
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	d3a080e7          	jalr	-710(ra) # 80000592 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002860:	0000f497          	auipc	s1,0xf
    80002864:	66848493          	addi	s1,s1,1640 # 80011ec8 <proc+0x160>
    80002868:	00015917          	auipc	s2,0x15
    8000286c:	26090913          	addi	s2,s2,608 # 80017ac8 <bcache+0x148>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002870:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002872:	00006997          	auipc	s3,0x6
    80002876:	a7e98993          	addi	s3,s3,-1410 # 800082f0 <digits+0x2b0>
    printf("%d %s %s", p->pid, state, p->name);
    8000287a:	00006a97          	auipc	s5,0x6
    8000287e:	a7ea8a93          	addi	s5,s5,-1410 # 800082f8 <digits+0x2b8>
    printf("\n");
    80002882:	00006a17          	auipc	s4,0x6
    80002886:	846a0a13          	addi	s4,s4,-1978 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000288a:	00006b97          	auipc	s7,0x6
    8000288e:	aa6b8b93          	addi	s7,s7,-1370 # 80008330 <states.1755>
    80002892:	a00d                	j	800028b4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002894:	ee06a583          	lw	a1,-288(a3)
    80002898:	8556                	mv	a0,s5
    8000289a:	ffffe097          	auipc	ra,0xffffe
    8000289e:	cf8080e7          	jalr	-776(ra) # 80000592 <printf>
    printf("\n");
    800028a2:	8552                	mv	a0,s4
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	cee080e7          	jalr	-786(ra) # 80000592 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028ac:	17048493          	addi	s1,s1,368
    800028b0:	03248163          	beq	s1,s2,800028d2 <procdump+0x98>
    if (p->state == UNUSED)
    800028b4:	86a6                	mv	a3,s1
    800028b6:	ec04a783          	lw	a5,-320(s1)
    800028ba:	dbed                	beqz	a5,800028ac <procdump+0x72>
      state = "???";
    800028bc:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028be:	fcfb6be3          	bltu	s6,a5,80002894 <procdump+0x5a>
    800028c2:	1782                	slli	a5,a5,0x20
    800028c4:	9381                	srli	a5,a5,0x20
    800028c6:	078e                	slli	a5,a5,0x3
    800028c8:	97de                	add	a5,a5,s7
    800028ca:	6390                	ld	a2,0(a5)
    800028cc:	f661                	bnez	a2,80002894 <procdump+0x5a>
      state = "???";
    800028ce:	864e                	mv	a2,s3
    800028d0:	b7d1                	j	80002894 <procdump+0x5a>
  }
}
    800028d2:	60a6                	ld	ra,72(sp)
    800028d4:	6406                	ld	s0,64(sp)
    800028d6:	74e2                	ld	s1,56(sp)
    800028d8:	7942                	ld	s2,48(sp)
    800028da:	79a2                	ld	s3,40(sp)
    800028dc:	7a02                	ld	s4,32(sp)
    800028de:	6ae2                	ld	s5,24(sp)
    800028e0:	6b42                	ld	s6,16(sp)
    800028e2:	6ba2                	ld	s7,8(sp)
    800028e4:	6161                	addi	sp,sp,80
    800028e6:	8082                	ret

00000000800028e8 <swtch>:
    800028e8:	00153023          	sd	ra,0(a0)
    800028ec:	00253423          	sd	sp,8(a0)
    800028f0:	e900                	sd	s0,16(a0)
    800028f2:	ed04                	sd	s1,24(a0)
    800028f4:	03253023          	sd	s2,32(a0)
    800028f8:	03353423          	sd	s3,40(a0)
    800028fc:	03453823          	sd	s4,48(a0)
    80002900:	03553c23          	sd	s5,56(a0)
    80002904:	05653023          	sd	s6,64(a0)
    80002908:	05753423          	sd	s7,72(a0)
    8000290c:	05853823          	sd	s8,80(a0)
    80002910:	05953c23          	sd	s9,88(a0)
    80002914:	07a53023          	sd	s10,96(a0)
    80002918:	07b53423          	sd	s11,104(a0)
    8000291c:	0005b083          	ld	ra,0(a1)
    80002920:	0085b103          	ld	sp,8(a1)
    80002924:	6980                	ld	s0,16(a1)
    80002926:	6d84                	ld	s1,24(a1)
    80002928:	0205b903          	ld	s2,32(a1)
    8000292c:	0285b983          	ld	s3,40(a1)
    80002930:	0305ba03          	ld	s4,48(a1)
    80002934:	0385ba83          	ld	s5,56(a1)
    80002938:	0405bb03          	ld	s6,64(a1)
    8000293c:	0485bb83          	ld	s7,72(a1)
    80002940:	0505bc03          	ld	s8,80(a1)
    80002944:	0585bc83          	ld	s9,88(a1)
    80002948:	0605bd03          	ld	s10,96(a1)
    8000294c:	0685bd83          	ld	s11,104(a1)
    80002950:	8082                	ret

0000000080002952 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002952:	1141                	addi	sp,sp,-16
    80002954:	e406                	sd	ra,8(sp)
    80002956:	e022                	sd	s0,0(sp)
    80002958:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000295a:	00006597          	auipc	a1,0x6
    8000295e:	9fe58593          	addi	a1,a1,-1538 # 80008358 <states.1755+0x28>
    80002962:	00015517          	auipc	a0,0x15
    80002966:	00650513          	addi	a0,a0,6 # 80017968 <tickslock>
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	216080e7          	jalr	534(ra) # 80000b80 <initlock>
}
    80002972:	60a2                	ld	ra,8(sp)
    80002974:	6402                	ld	s0,0(sp)
    80002976:	0141                	addi	sp,sp,16
    80002978:	8082                	ret

000000008000297a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000297a:	1141                	addi	sp,sp,-16
    8000297c:	e422                	sd	s0,8(sp)
    8000297e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002980:	00003797          	auipc	a5,0x3
    80002984:	51078793          	addi	a5,a5,1296 # 80005e90 <kernelvec>
    80002988:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000298c:	6422                	ld	s0,8(sp)
    8000298e:	0141                	addi	sp,sp,16
    80002990:	8082                	ret

0000000080002992 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002992:	1141                	addi	sp,sp,-16
    80002994:	e406                	sd	ra,8(sp)
    80002996:	e022                	sd	s0,0(sp)
    80002998:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000299a:	fffff097          	auipc	ra,0xfffff
    8000299e:	184080e7          	jalr	388(ra) # 80001b1e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029a6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029a8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029ac:	00004617          	auipc	a2,0x4
    800029b0:	65460613          	addi	a2,a2,1620 # 80007000 <_trampoline>
    800029b4:	00004697          	auipc	a3,0x4
    800029b8:	64c68693          	addi	a3,a3,1612 # 80007000 <_trampoline>
    800029bc:	8e91                	sub	a3,a3,a2
    800029be:	040007b7          	lui	a5,0x4000
    800029c2:	17fd                	addi	a5,a5,-1
    800029c4:	07b2                	slli	a5,a5,0xc
    800029c6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029c8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029cc:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029ce:	180026f3          	csrr	a3,satp
    800029d2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029d4:	7138                	ld	a4,96(a0)
    800029d6:	6534                	ld	a3,72(a0)
    800029d8:	6585                	lui	a1,0x1
    800029da:	96ae                	add	a3,a3,a1
    800029dc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029de:	7138                	ld	a4,96(a0)
    800029e0:	00000697          	auipc	a3,0x0
    800029e4:	13868693          	addi	a3,a3,312 # 80002b18 <usertrap>
    800029e8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029ea:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029ec:	8692                	mv	a3,tp
    800029ee:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029f4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029f8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029fc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a00:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a02:	6f18                	ld	a4,24(a4)
    80002a04:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a08:	6d2c                	ld	a1,88(a0)
    80002a0a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a0c:	00004717          	auipc	a4,0x4
    80002a10:	68470713          	addi	a4,a4,1668 # 80007090 <userret>
    80002a14:	8f11                	sub	a4,a4,a2
    80002a16:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a18:	577d                	li	a4,-1
    80002a1a:	177e                	slli	a4,a4,0x3f
    80002a1c:	8dd9                	or	a1,a1,a4
    80002a1e:	02000537          	lui	a0,0x2000
    80002a22:	157d                	addi	a0,a0,-1
    80002a24:	0536                	slli	a0,a0,0xd
    80002a26:	9782                	jalr	a5
}
    80002a28:	60a2                	ld	ra,8(sp)
    80002a2a:	6402                	ld	s0,0(sp)
    80002a2c:	0141                	addi	sp,sp,16
    80002a2e:	8082                	ret

0000000080002a30 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a30:	1101                	addi	sp,sp,-32
    80002a32:	ec06                	sd	ra,24(sp)
    80002a34:	e822                	sd	s0,16(sp)
    80002a36:	e426                	sd	s1,8(sp)
    80002a38:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a3a:	00015497          	auipc	s1,0x15
    80002a3e:	f2e48493          	addi	s1,s1,-210 # 80017968 <tickslock>
    80002a42:	8526                	mv	a0,s1
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	1cc080e7          	jalr	460(ra) # 80000c10 <acquire>
  ticks++;
    80002a4c:	00006517          	auipc	a0,0x6
    80002a50:	5d450513          	addi	a0,a0,1492 # 80009020 <ticks>
    80002a54:	411c                	lw	a5,0(a0)
    80002a56:	2785                	addiw	a5,a5,1
    80002a58:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a5a:	00000097          	auipc	ra,0x0
    80002a5e:	c58080e7          	jalr	-936(ra) # 800026b2 <wakeup>
  release(&tickslock);
    80002a62:	8526                	mv	a0,s1
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	260080e7          	jalr	608(ra) # 80000cc4 <release>
}
    80002a6c:	60e2                	ld	ra,24(sp)
    80002a6e:	6442                	ld	s0,16(sp)
    80002a70:	64a2                	ld	s1,8(sp)
    80002a72:	6105                	addi	sp,sp,32
    80002a74:	8082                	ret

0000000080002a76 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a76:	1101                	addi	sp,sp,-32
    80002a78:	ec06                	sd	ra,24(sp)
    80002a7a:	e822                	sd	s0,16(sp)
    80002a7c:	e426                	sd	s1,8(sp)
    80002a7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a80:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a84:	00074d63          	bltz	a4,80002a9e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a88:	57fd                	li	a5,-1
    80002a8a:	17fe                	slli	a5,a5,0x3f
    80002a8c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a8e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a90:	06f70363          	beq	a4,a5,80002af6 <devintr+0x80>
  }
}
    80002a94:	60e2                	ld	ra,24(sp)
    80002a96:	6442                	ld	s0,16(sp)
    80002a98:	64a2                	ld	s1,8(sp)
    80002a9a:	6105                	addi	sp,sp,32
    80002a9c:	8082                	ret
     (scause & 0xff) == 9){
    80002a9e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002aa2:	46a5                	li	a3,9
    80002aa4:	fed792e3          	bne	a5,a3,80002a88 <devintr+0x12>
    int irq = plic_claim();
    80002aa8:	00003097          	auipc	ra,0x3
    80002aac:	4f0080e7          	jalr	1264(ra) # 80005f98 <plic_claim>
    80002ab0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ab2:	47a9                	li	a5,10
    80002ab4:	02f50763          	beq	a0,a5,80002ae2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ab8:	4785                	li	a5,1
    80002aba:	02f50963          	beq	a0,a5,80002aec <devintr+0x76>
    return 1;
    80002abe:	4505                	li	a0,1
    } else if(irq){
    80002ac0:	d8f1                	beqz	s1,80002a94 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ac2:	85a6                	mv	a1,s1
    80002ac4:	00006517          	auipc	a0,0x6
    80002ac8:	89c50513          	addi	a0,a0,-1892 # 80008360 <states.1755+0x30>
    80002acc:	ffffe097          	auipc	ra,0xffffe
    80002ad0:	ac6080e7          	jalr	-1338(ra) # 80000592 <printf>
      plic_complete(irq);
    80002ad4:	8526                	mv	a0,s1
    80002ad6:	00003097          	auipc	ra,0x3
    80002ada:	4e6080e7          	jalr	1254(ra) # 80005fbc <plic_complete>
    return 1;
    80002ade:	4505                	li	a0,1
    80002ae0:	bf55                	j	80002a94 <devintr+0x1e>
      uartintr();
    80002ae2:	ffffe097          	auipc	ra,0xffffe
    80002ae6:	ef2080e7          	jalr	-270(ra) # 800009d4 <uartintr>
    80002aea:	b7ed                	j	80002ad4 <devintr+0x5e>
      virtio_disk_intr();
    80002aec:	00004097          	auipc	ra,0x4
    80002af0:	96a080e7          	jalr	-1686(ra) # 80006456 <virtio_disk_intr>
    80002af4:	b7c5                	j	80002ad4 <devintr+0x5e>
    if(cpuid() == 0){
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	ffc080e7          	jalr	-4(ra) # 80001af2 <cpuid>
    80002afe:	c901                	beqz	a0,80002b0e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b00:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b04:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b06:	14479073          	csrw	sip,a5
    return 2;
    80002b0a:	4509                	li	a0,2
    80002b0c:	b761                	j	80002a94 <devintr+0x1e>
      clockintr();
    80002b0e:	00000097          	auipc	ra,0x0
    80002b12:	f22080e7          	jalr	-222(ra) # 80002a30 <clockintr>
    80002b16:	b7ed                	j	80002b00 <devintr+0x8a>

0000000080002b18 <usertrap>:
{
    80002b18:	1101                	addi	sp,sp,-32
    80002b1a:	ec06                	sd	ra,24(sp)
    80002b1c:	e822                	sd	s0,16(sp)
    80002b1e:	e426                	sd	s1,8(sp)
    80002b20:	e04a                	sd	s2,0(sp)
    80002b22:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b24:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b28:	1007f793          	andi	a5,a5,256
    80002b2c:	e3ad                	bnez	a5,80002b8e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b2e:	00003797          	auipc	a5,0x3
    80002b32:	36278793          	addi	a5,a5,866 # 80005e90 <kernelvec>
    80002b36:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b3a:	fffff097          	auipc	ra,0xfffff
    80002b3e:	fe4080e7          	jalr	-28(ra) # 80001b1e <myproc>
    80002b42:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b44:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b46:	14102773          	csrr	a4,sepc
    80002b4a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b4c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b50:	47a1                	li	a5,8
    80002b52:	04f71c63          	bne	a4,a5,80002baa <usertrap+0x92>
    if(p->killed)
    80002b56:	5d1c                	lw	a5,56(a0)
    80002b58:	e3b9                	bnez	a5,80002b9e <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b5a:	70b8                	ld	a4,96(s1)
    80002b5c:	6f1c                	ld	a5,24(a4)
    80002b5e:	0791                	addi	a5,a5,4
    80002b60:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b62:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b66:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b6a:	10079073          	csrw	sstatus,a5
    syscall();
    80002b6e:	00000097          	auipc	ra,0x0
    80002b72:	2e0080e7          	jalr	736(ra) # 80002e4e <syscall>
  if(p->killed)
    80002b76:	5c9c                	lw	a5,56(s1)
    80002b78:	ebc1                	bnez	a5,80002c08 <usertrap+0xf0>
  usertrapret();
    80002b7a:	00000097          	auipc	ra,0x0
    80002b7e:	e18080e7          	jalr	-488(ra) # 80002992 <usertrapret>
}
    80002b82:	60e2                	ld	ra,24(sp)
    80002b84:	6442                	ld	s0,16(sp)
    80002b86:	64a2                	ld	s1,8(sp)
    80002b88:	6902                	ld	s2,0(sp)
    80002b8a:	6105                	addi	sp,sp,32
    80002b8c:	8082                	ret
    panic("usertrap: not from user mode");
    80002b8e:	00005517          	auipc	a0,0x5
    80002b92:	7f250513          	addi	a0,a0,2034 # 80008380 <states.1755+0x50>
    80002b96:	ffffe097          	auipc	ra,0xffffe
    80002b9a:	9b2080e7          	jalr	-1614(ra) # 80000548 <panic>
      exit(-1);
    80002b9e:	557d                	li	a0,-1
    80002ba0:	00000097          	auipc	ra,0x0
    80002ba4:	846080e7          	jalr	-1978(ra) # 800023e6 <exit>
    80002ba8:	bf4d                	j	80002b5a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002baa:	00000097          	auipc	ra,0x0
    80002bae:	ecc080e7          	jalr	-308(ra) # 80002a76 <devintr>
    80002bb2:	892a                	mv	s2,a0
    80002bb4:	c501                	beqz	a0,80002bbc <usertrap+0xa4>
  if(p->killed)
    80002bb6:	5c9c                	lw	a5,56(s1)
    80002bb8:	c3a1                	beqz	a5,80002bf8 <usertrap+0xe0>
    80002bba:	a815                	j	80002bee <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bbc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bc0:	40b0                	lw	a2,64(s1)
    80002bc2:	00005517          	auipc	a0,0x5
    80002bc6:	7de50513          	addi	a0,a0,2014 # 800083a0 <states.1755+0x70>
    80002bca:	ffffe097          	auipc	ra,0xffffe
    80002bce:	9c8080e7          	jalr	-1592(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bd6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bda:	00005517          	auipc	a0,0x5
    80002bde:	7f650513          	addi	a0,a0,2038 # 800083d0 <states.1755+0xa0>
    80002be2:	ffffe097          	auipc	ra,0xffffe
    80002be6:	9b0080e7          	jalr	-1616(ra) # 80000592 <printf>
    p->killed = 1;
    80002bea:	4785                	li	a5,1
    80002bec:	dc9c                	sw	a5,56(s1)
    exit(-1);
    80002bee:	557d                	li	a0,-1
    80002bf0:	fffff097          	auipc	ra,0xfffff
    80002bf4:	7f6080e7          	jalr	2038(ra) # 800023e6 <exit>
  if(which_dev == 2)
    80002bf8:	4789                	li	a5,2
    80002bfa:	f8f910e3          	bne	s2,a5,80002b7a <usertrap+0x62>
    yield();
    80002bfe:	00000097          	auipc	ra,0x0
    80002c02:	8f2080e7          	jalr	-1806(ra) # 800024f0 <yield>
    80002c06:	bf95                	j	80002b7a <usertrap+0x62>
  int which_dev = 0;
    80002c08:	4901                	li	s2,0
    80002c0a:	b7d5                	j	80002bee <usertrap+0xd6>

0000000080002c0c <kerneltrap>:
{
    80002c0c:	7179                	addi	sp,sp,-48
    80002c0e:	f406                	sd	ra,40(sp)
    80002c10:	f022                	sd	s0,32(sp)
    80002c12:	ec26                	sd	s1,24(sp)
    80002c14:	e84a                	sd	s2,16(sp)
    80002c16:	e44e                	sd	s3,8(sp)
    80002c18:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c1a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c1e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c22:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c26:	1004f793          	andi	a5,s1,256
    80002c2a:	cb85                	beqz	a5,80002c5a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c2c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c30:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c32:	ef85                	bnez	a5,80002c6a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c34:	00000097          	auipc	ra,0x0
    80002c38:	e42080e7          	jalr	-446(ra) # 80002a76 <devintr>
    80002c3c:	cd1d                	beqz	a0,80002c7a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c3e:	4789                	li	a5,2
    80002c40:	06f50a63          	beq	a0,a5,80002cb4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c44:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c48:	10049073          	csrw	sstatus,s1
}
    80002c4c:	70a2                	ld	ra,40(sp)
    80002c4e:	7402                	ld	s0,32(sp)
    80002c50:	64e2                	ld	s1,24(sp)
    80002c52:	6942                	ld	s2,16(sp)
    80002c54:	69a2                	ld	s3,8(sp)
    80002c56:	6145                	addi	sp,sp,48
    80002c58:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c5a:	00005517          	auipc	a0,0x5
    80002c5e:	79650513          	addi	a0,a0,1942 # 800083f0 <states.1755+0xc0>
    80002c62:	ffffe097          	auipc	ra,0xffffe
    80002c66:	8e6080e7          	jalr	-1818(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c6a:	00005517          	auipc	a0,0x5
    80002c6e:	7ae50513          	addi	a0,a0,1966 # 80008418 <states.1755+0xe8>
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	8d6080e7          	jalr	-1834(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002c7a:	85ce                	mv	a1,s3
    80002c7c:	00005517          	auipc	a0,0x5
    80002c80:	7bc50513          	addi	a0,a0,1980 # 80008438 <states.1755+0x108>
    80002c84:	ffffe097          	auipc	ra,0xffffe
    80002c88:	90e080e7          	jalr	-1778(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c8c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c90:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c94:	00005517          	auipc	a0,0x5
    80002c98:	7b450513          	addi	a0,a0,1972 # 80008448 <states.1755+0x118>
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	8f6080e7          	jalr	-1802(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002ca4:	00005517          	auipc	a0,0x5
    80002ca8:	7bc50513          	addi	a0,a0,1980 # 80008460 <states.1755+0x130>
    80002cac:	ffffe097          	auipc	ra,0xffffe
    80002cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	e6a080e7          	jalr	-406(ra) # 80001b1e <myproc>
    80002cbc:	d541                	beqz	a0,80002c44 <kerneltrap+0x38>
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	e60080e7          	jalr	-416(ra) # 80001b1e <myproc>
    80002cc6:	5118                	lw	a4,32(a0)
    80002cc8:	478d                	li	a5,3
    80002cca:	f6f71de3          	bne	a4,a5,80002c44 <kerneltrap+0x38>
    yield();
    80002cce:	00000097          	auipc	ra,0x0
    80002cd2:	822080e7          	jalr	-2014(ra) # 800024f0 <yield>
    80002cd6:	b7bd                	j	80002c44 <kerneltrap+0x38>

0000000080002cd8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cd8:	1101                	addi	sp,sp,-32
    80002cda:	ec06                	sd	ra,24(sp)
    80002cdc:	e822                	sd	s0,16(sp)
    80002cde:	e426                	sd	s1,8(sp)
    80002ce0:	1000                	addi	s0,sp,32
    80002ce2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	e3a080e7          	jalr	-454(ra) # 80001b1e <myproc>
  switch (n) {
    80002cec:	4795                	li	a5,5
    80002cee:	0497e163          	bltu	a5,s1,80002d30 <argraw+0x58>
    80002cf2:	048a                	slli	s1,s1,0x2
    80002cf4:	00005717          	auipc	a4,0x5
    80002cf8:	7a470713          	addi	a4,a4,1956 # 80008498 <states.1755+0x168>
    80002cfc:	94ba                	add	s1,s1,a4
    80002cfe:	409c                	lw	a5,0(s1)
    80002d00:	97ba                	add	a5,a5,a4
    80002d02:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d04:	713c                	ld	a5,96(a0)
    80002d06:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d08:	60e2                	ld	ra,24(sp)
    80002d0a:	6442                	ld	s0,16(sp)
    80002d0c:	64a2                	ld	s1,8(sp)
    80002d0e:	6105                	addi	sp,sp,32
    80002d10:	8082                	ret
    return p->trapframe->a1;
    80002d12:	713c                	ld	a5,96(a0)
    80002d14:	7fa8                	ld	a0,120(a5)
    80002d16:	bfcd                	j	80002d08 <argraw+0x30>
    return p->trapframe->a2;
    80002d18:	713c                	ld	a5,96(a0)
    80002d1a:	63c8                	ld	a0,128(a5)
    80002d1c:	b7f5                	j	80002d08 <argraw+0x30>
    return p->trapframe->a3;
    80002d1e:	713c                	ld	a5,96(a0)
    80002d20:	67c8                	ld	a0,136(a5)
    80002d22:	b7dd                	j	80002d08 <argraw+0x30>
    return p->trapframe->a4;
    80002d24:	713c                	ld	a5,96(a0)
    80002d26:	6bc8                	ld	a0,144(a5)
    80002d28:	b7c5                	j	80002d08 <argraw+0x30>
    return p->trapframe->a5;
    80002d2a:	713c                	ld	a5,96(a0)
    80002d2c:	6fc8                	ld	a0,152(a5)
    80002d2e:	bfe9                	j	80002d08 <argraw+0x30>
  panic("argraw");
    80002d30:	00005517          	auipc	a0,0x5
    80002d34:	74050513          	addi	a0,a0,1856 # 80008470 <states.1755+0x140>
    80002d38:	ffffe097          	auipc	ra,0xffffe
    80002d3c:	810080e7          	jalr	-2032(ra) # 80000548 <panic>

0000000080002d40 <fetchaddr>:
{
    80002d40:	1101                	addi	sp,sp,-32
    80002d42:	ec06                	sd	ra,24(sp)
    80002d44:	e822                	sd	s0,16(sp)
    80002d46:	e426                	sd	s1,8(sp)
    80002d48:	e04a                	sd	s2,0(sp)
    80002d4a:	1000                	addi	s0,sp,32
    80002d4c:	84aa                	mv	s1,a0
    80002d4e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d50:	fffff097          	auipc	ra,0xfffff
    80002d54:	dce080e7          	jalr	-562(ra) # 80001b1e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d58:	693c                	ld	a5,80(a0)
    80002d5a:	02f4f863          	bgeu	s1,a5,80002d8a <fetchaddr+0x4a>
    80002d5e:	00848713          	addi	a4,s1,8
    80002d62:	02e7e663          	bltu	a5,a4,80002d8e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d66:	46a1                	li	a3,8
    80002d68:	8626                	mv	a2,s1
    80002d6a:	85ca                	mv	a1,s2
    80002d6c:	6d28                	ld	a0,88(a0)
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	a00080e7          	jalr	-1536(ra) # 8000176e <copyin>
    80002d76:	00a03533          	snez	a0,a0
    80002d7a:	40a00533          	neg	a0,a0
}
    80002d7e:	60e2                	ld	ra,24(sp)
    80002d80:	6442                	ld	s0,16(sp)
    80002d82:	64a2                	ld	s1,8(sp)
    80002d84:	6902                	ld	s2,0(sp)
    80002d86:	6105                	addi	sp,sp,32
    80002d88:	8082                	ret
    return -1;
    80002d8a:	557d                	li	a0,-1
    80002d8c:	bfcd                	j	80002d7e <fetchaddr+0x3e>
    80002d8e:	557d                	li	a0,-1
    80002d90:	b7fd                	j	80002d7e <fetchaddr+0x3e>

0000000080002d92 <fetchstr>:
{
    80002d92:	7179                	addi	sp,sp,-48
    80002d94:	f406                	sd	ra,40(sp)
    80002d96:	f022                	sd	s0,32(sp)
    80002d98:	ec26                	sd	s1,24(sp)
    80002d9a:	e84a                	sd	s2,16(sp)
    80002d9c:	e44e                	sd	s3,8(sp)
    80002d9e:	1800                	addi	s0,sp,48
    80002da0:	892a                	mv	s2,a0
    80002da2:	84ae                	mv	s1,a1
    80002da4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	d78080e7          	jalr	-648(ra) # 80001b1e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dae:	86ce                	mv	a3,s3
    80002db0:	864a                	mv	a2,s2
    80002db2:	85a6                	mv	a1,s1
    80002db4:	6d28                	ld	a0,88(a0)
    80002db6:	fffff097          	auipc	ra,0xfffff
    80002dba:	9d0080e7          	jalr	-1584(ra) # 80001786 <copyinstr>
  if(err < 0)
    80002dbe:	00054763          	bltz	a0,80002dcc <fetchstr+0x3a>
  return strlen(buf);
    80002dc2:	8526                	mv	a0,s1
    80002dc4:	ffffe097          	auipc	ra,0xffffe
    80002dc8:	0d0080e7          	jalr	208(ra) # 80000e94 <strlen>
}
    80002dcc:	70a2                	ld	ra,40(sp)
    80002dce:	7402                	ld	s0,32(sp)
    80002dd0:	64e2                	ld	s1,24(sp)
    80002dd2:	6942                	ld	s2,16(sp)
    80002dd4:	69a2                	ld	s3,8(sp)
    80002dd6:	6145                	addi	sp,sp,48
    80002dd8:	8082                	ret

0000000080002dda <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002dda:	1101                	addi	sp,sp,-32
    80002ddc:	ec06                	sd	ra,24(sp)
    80002dde:	e822                	sd	s0,16(sp)
    80002de0:	e426                	sd	s1,8(sp)
    80002de2:	1000                	addi	s0,sp,32
    80002de4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002de6:	00000097          	auipc	ra,0x0
    80002dea:	ef2080e7          	jalr	-270(ra) # 80002cd8 <argraw>
    80002dee:	c088                	sw	a0,0(s1)
  return 0;
}
    80002df0:	4501                	li	a0,0
    80002df2:	60e2                	ld	ra,24(sp)
    80002df4:	6442                	ld	s0,16(sp)
    80002df6:	64a2                	ld	s1,8(sp)
    80002df8:	6105                	addi	sp,sp,32
    80002dfa:	8082                	ret

0000000080002dfc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002dfc:	1101                	addi	sp,sp,-32
    80002dfe:	ec06                	sd	ra,24(sp)
    80002e00:	e822                	sd	s0,16(sp)
    80002e02:	e426                	sd	s1,8(sp)
    80002e04:	1000                	addi	s0,sp,32
    80002e06:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e08:	00000097          	auipc	ra,0x0
    80002e0c:	ed0080e7          	jalr	-304(ra) # 80002cd8 <argraw>
    80002e10:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e12:	4501                	li	a0,0
    80002e14:	60e2                	ld	ra,24(sp)
    80002e16:	6442                	ld	s0,16(sp)
    80002e18:	64a2                	ld	s1,8(sp)
    80002e1a:	6105                	addi	sp,sp,32
    80002e1c:	8082                	ret

0000000080002e1e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e1e:	1101                	addi	sp,sp,-32
    80002e20:	ec06                	sd	ra,24(sp)
    80002e22:	e822                	sd	s0,16(sp)
    80002e24:	e426                	sd	s1,8(sp)
    80002e26:	e04a                	sd	s2,0(sp)
    80002e28:	1000                	addi	s0,sp,32
    80002e2a:	84ae                	mv	s1,a1
    80002e2c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e2e:	00000097          	auipc	ra,0x0
    80002e32:	eaa080e7          	jalr	-342(ra) # 80002cd8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e36:	864a                	mv	a2,s2
    80002e38:	85a6                	mv	a1,s1
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	f58080e7          	jalr	-168(ra) # 80002d92 <fetchstr>
}
    80002e42:	60e2                	ld	ra,24(sp)
    80002e44:	6442                	ld	s0,16(sp)
    80002e46:	64a2                	ld	s1,8(sp)
    80002e48:	6902                	ld	s2,0(sp)
    80002e4a:	6105                	addi	sp,sp,32
    80002e4c:	8082                	ret

0000000080002e4e <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e4e:	1101                	addi	sp,sp,-32
    80002e50:	ec06                	sd	ra,24(sp)
    80002e52:	e822                	sd	s0,16(sp)
    80002e54:	e426                	sd	s1,8(sp)
    80002e56:	e04a                	sd	s2,0(sp)
    80002e58:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e5a:	fffff097          	auipc	ra,0xfffff
    80002e5e:	cc4080e7          	jalr	-828(ra) # 80001b1e <myproc>
    80002e62:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e64:	06053903          	ld	s2,96(a0)
    80002e68:	0a893783          	ld	a5,168(s2)
    80002e6c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e70:	37fd                	addiw	a5,a5,-1
    80002e72:	4751                	li	a4,20
    80002e74:	00f76f63          	bltu	a4,a5,80002e92 <syscall+0x44>
    80002e78:	00369713          	slli	a4,a3,0x3
    80002e7c:	00005797          	auipc	a5,0x5
    80002e80:	63478793          	addi	a5,a5,1588 # 800084b0 <syscalls>
    80002e84:	97ba                	add	a5,a5,a4
    80002e86:	639c                	ld	a5,0(a5)
    80002e88:	c789                	beqz	a5,80002e92 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e8a:	9782                	jalr	a5
    80002e8c:	06a93823          	sd	a0,112(s2)
    80002e90:	a839                	j	80002eae <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e92:	16048613          	addi	a2,s1,352
    80002e96:	40ac                	lw	a1,64(s1)
    80002e98:	00005517          	auipc	a0,0x5
    80002e9c:	5e050513          	addi	a0,a0,1504 # 80008478 <states.1755+0x148>
    80002ea0:	ffffd097          	auipc	ra,0xffffd
    80002ea4:	6f2080e7          	jalr	1778(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ea8:	70bc                	ld	a5,96(s1)
    80002eaa:	577d                	li	a4,-1
    80002eac:	fbb8                	sd	a4,112(a5)
  }
}
    80002eae:	60e2                	ld	ra,24(sp)
    80002eb0:	6442                	ld	s0,16(sp)
    80002eb2:	64a2                	ld	s1,8(sp)
    80002eb4:	6902                	ld	s2,0(sp)
    80002eb6:	6105                	addi	sp,sp,32
    80002eb8:	8082                	ret

0000000080002eba <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002eba:	1101                	addi	sp,sp,-32
    80002ebc:	ec06                	sd	ra,24(sp)
    80002ebe:	e822                	sd	s0,16(sp)
    80002ec0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ec2:	fec40593          	addi	a1,s0,-20
    80002ec6:	4501                	li	a0,0
    80002ec8:	00000097          	auipc	ra,0x0
    80002ecc:	f12080e7          	jalr	-238(ra) # 80002dda <argint>
    return -1;
    80002ed0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ed2:	00054963          	bltz	a0,80002ee4 <sys_exit+0x2a>
  exit(n);
    80002ed6:	fec42503          	lw	a0,-20(s0)
    80002eda:	fffff097          	auipc	ra,0xfffff
    80002ede:	50c080e7          	jalr	1292(ra) # 800023e6 <exit>
  return 0;  // not reached
    80002ee2:	4781                	li	a5,0
}
    80002ee4:	853e                	mv	a0,a5
    80002ee6:	60e2                	ld	ra,24(sp)
    80002ee8:	6442                	ld	s0,16(sp)
    80002eea:	6105                	addi	sp,sp,32
    80002eec:	8082                	ret

0000000080002eee <sys_getpid>:

uint64
sys_getpid(void)
{
    80002eee:	1141                	addi	sp,sp,-16
    80002ef0:	e406                	sd	ra,8(sp)
    80002ef2:	e022                	sd	s0,0(sp)
    80002ef4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	c28080e7          	jalr	-984(ra) # 80001b1e <myproc>
}
    80002efe:	4128                	lw	a0,64(a0)
    80002f00:	60a2                	ld	ra,8(sp)
    80002f02:	6402                	ld	s0,0(sp)
    80002f04:	0141                	addi	sp,sp,16
    80002f06:	8082                	ret

0000000080002f08 <sys_fork>:

uint64
sys_fork(void)
{
    80002f08:	1141                	addi	sp,sp,-16
    80002f0a:	e406                	sd	ra,8(sp)
    80002f0c:	e022                	sd	s0,0(sp)
    80002f0e:	0800                	addi	s0,sp,16
  return fork();
    80002f10:	fffff097          	auipc	ra,0xfffff
    80002f14:	1a0080e7          	jalr	416(ra) # 800020b0 <fork>
}
    80002f18:	60a2                	ld	ra,8(sp)
    80002f1a:	6402                	ld	s0,0(sp)
    80002f1c:	0141                	addi	sp,sp,16
    80002f1e:	8082                	ret

0000000080002f20 <sys_wait>:

uint64
sys_wait(void)
{
    80002f20:	1101                	addi	sp,sp,-32
    80002f22:	ec06                	sd	ra,24(sp)
    80002f24:	e822                	sd	s0,16(sp)
    80002f26:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f28:	fe840593          	addi	a1,s0,-24
    80002f2c:	4501                	li	a0,0
    80002f2e:	00000097          	auipc	ra,0x0
    80002f32:	ece080e7          	jalr	-306(ra) # 80002dfc <argaddr>
    80002f36:	87aa                	mv	a5,a0
    return -1;
    80002f38:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f3a:	0007c863          	bltz	a5,80002f4a <sys_wait+0x2a>
  return wait(p);
    80002f3e:	fe843503          	ld	a0,-24(s0)
    80002f42:	fffff097          	auipc	ra,0xfffff
    80002f46:	668080e7          	jalr	1640(ra) # 800025aa <wait>
}
    80002f4a:	60e2                	ld	ra,24(sp)
    80002f4c:	6442                	ld	s0,16(sp)
    80002f4e:	6105                	addi	sp,sp,32
    80002f50:	8082                	ret

0000000080002f52 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f52:	7179                	addi	sp,sp,-48
    80002f54:	f406                	sd	ra,40(sp)
    80002f56:	f022                	sd	s0,32(sp)
    80002f58:	ec26                	sd	s1,24(sp)
    80002f5a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f5c:	fdc40593          	addi	a1,s0,-36
    80002f60:	4501                	li	a0,0
    80002f62:	00000097          	auipc	ra,0x0
    80002f66:	e78080e7          	jalr	-392(ra) # 80002dda <argint>
    80002f6a:	87aa                	mv	a5,a0
    return -1;
    80002f6c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f6e:	0207c063          	bltz	a5,80002f8e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f72:	fffff097          	auipc	ra,0xfffff
    80002f76:	bac080e7          	jalr	-1108(ra) # 80001b1e <myproc>
    80002f7a:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002f7c:	fdc42503          	lw	a0,-36(s0)
    80002f80:	fffff097          	auipc	ra,0xfffff
    80002f84:	070080e7          	jalr	112(ra) # 80001ff0 <growproc>
    80002f88:	00054863          	bltz	a0,80002f98 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f8c:	8526                	mv	a0,s1
}
    80002f8e:	70a2                	ld	ra,40(sp)
    80002f90:	7402                	ld	s0,32(sp)
    80002f92:	64e2                	ld	s1,24(sp)
    80002f94:	6145                	addi	sp,sp,48
    80002f96:	8082                	ret
    return -1;
    80002f98:	557d                	li	a0,-1
    80002f9a:	bfd5                	j	80002f8e <sys_sbrk+0x3c>

0000000080002f9c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f9c:	7139                	addi	sp,sp,-64
    80002f9e:	fc06                	sd	ra,56(sp)
    80002fa0:	f822                	sd	s0,48(sp)
    80002fa2:	f426                	sd	s1,40(sp)
    80002fa4:	f04a                	sd	s2,32(sp)
    80002fa6:	ec4e                	sd	s3,24(sp)
    80002fa8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002faa:	fcc40593          	addi	a1,s0,-52
    80002fae:	4501                	li	a0,0
    80002fb0:	00000097          	auipc	ra,0x0
    80002fb4:	e2a080e7          	jalr	-470(ra) # 80002dda <argint>
    return -1;
    80002fb8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fba:	06054563          	bltz	a0,80003024 <sys_sleep+0x88>
  acquire(&tickslock);
    80002fbe:	00015517          	auipc	a0,0x15
    80002fc2:	9aa50513          	addi	a0,a0,-1622 # 80017968 <tickslock>
    80002fc6:	ffffe097          	auipc	ra,0xffffe
    80002fca:	c4a080e7          	jalr	-950(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002fce:	00006917          	auipc	s2,0x6
    80002fd2:	05292903          	lw	s2,82(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002fd6:	fcc42783          	lw	a5,-52(s0)
    80002fda:	cf85                	beqz	a5,80003012 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fdc:	00015997          	auipc	s3,0x15
    80002fe0:	98c98993          	addi	s3,s3,-1652 # 80017968 <tickslock>
    80002fe4:	00006497          	auipc	s1,0x6
    80002fe8:	03c48493          	addi	s1,s1,60 # 80009020 <ticks>
    if(myproc()->killed){
    80002fec:	fffff097          	auipc	ra,0xfffff
    80002ff0:	b32080e7          	jalr	-1230(ra) # 80001b1e <myproc>
    80002ff4:	5d1c                	lw	a5,56(a0)
    80002ff6:	ef9d                	bnez	a5,80003034 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002ff8:	85ce                	mv	a1,s3
    80002ffa:	8526                	mv	a0,s1
    80002ffc:	fffff097          	auipc	ra,0xfffff
    80003000:	530080e7          	jalr	1328(ra) # 8000252c <sleep>
  while(ticks - ticks0 < n){
    80003004:	409c                	lw	a5,0(s1)
    80003006:	412787bb          	subw	a5,a5,s2
    8000300a:	fcc42703          	lw	a4,-52(s0)
    8000300e:	fce7efe3          	bltu	a5,a4,80002fec <sys_sleep+0x50>
  }
  release(&tickslock);
    80003012:	00015517          	auipc	a0,0x15
    80003016:	95650513          	addi	a0,a0,-1706 # 80017968 <tickslock>
    8000301a:	ffffe097          	auipc	ra,0xffffe
    8000301e:	caa080e7          	jalr	-854(ra) # 80000cc4 <release>
  return 0;
    80003022:	4781                	li	a5,0
}
    80003024:	853e                	mv	a0,a5
    80003026:	70e2                	ld	ra,56(sp)
    80003028:	7442                	ld	s0,48(sp)
    8000302a:	74a2                	ld	s1,40(sp)
    8000302c:	7902                	ld	s2,32(sp)
    8000302e:	69e2                	ld	s3,24(sp)
    80003030:	6121                	addi	sp,sp,64
    80003032:	8082                	ret
      release(&tickslock);
    80003034:	00015517          	auipc	a0,0x15
    80003038:	93450513          	addi	a0,a0,-1740 # 80017968 <tickslock>
    8000303c:	ffffe097          	auipc	ra,0xffffe
    80003040:	c88080e7          	jalr	-888(ra) # 80000cc4 <release>
      return -1;
    80003044:	57fd                	li	a5,-1
    80003046:	bff9                	j	80003024 <sys_sleep+0x88>

0000000080003048 <sys_kill>:

uint64
sys_kill(void)
{
    80003048:	1101                	addi	sp,sp,-32
    8000304a:	ec06                	sd	ra,24(sp)
    8000304c:	e822                	sd	s0,16(sp)
    8000304e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003050:	fec40593          	addi	a1,s0,-20
    80003054:	4501                	li	a0,0
    80003056:	00000097          	auipc	ra,0x0
    8000305a:	d84080e7          	jalr	-636(ra) # 80002dda <argint>
    8000305e:	87aa                	mv	a5,a0
    return -1;
    80003060:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003062:	0007c863          	bltz	a5,80003072 <sys_kill+0x2a>
  return kill(pid);
    80003066:	fec42503          	lw	a0,-20(s0)
    8000306a:	fffff097          	auipc	ra,0xfffff
    8000306e:	6b2080e7          	jalr	1714(ra) # 8000271c <kill>
}
    80003072:	60e2                	ld	ra,24(sp)
    80003074:	6442                	ld	s0,16(sp)
    80003076:	6105                	addi	sp,sp,32
    80003078:	8082                	ret

000000008000307a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000307a:	1101                	addi	sp,sp,-32
    8000307c:	ec06                	sd	ra,24(sp)
    8000307e:	e822                	sd	s0,16(sp)
    80003080:	e426                	sd	s1,8(sp)
    80003082:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003084:	00015517          	auipc	a0,0x15
    80003088:	8e450513          	addi	a0,a0,-1820 # 80017968 <tickslock>
    8000308c:	ffffe097          	auipc	ra,0xffffe
    80003090:	b84080e7          	jalr	-1148(ra) # 80000c10 <acquire>
  xticks = ticks;
    80003094:	00006497          	auipc	s1,0x6
    80003098:	f8c4a483          	lw	s1,-116(s1) # 80009020 <ticks>
  release(&tickslock);
    8000309c:	00015517          	auipc	a0,0x15
    800030a0:	8cc50513          	addi	a0,a0,-1844 # 80017968 <tickslock>
    800030a4:	ffffe097          	auipc	ra,0xffffe
    800030a8:	c20080e7          	jalr	-992(ra) # 80000cc4 <release>
  return xticks;
}
    800030ac:	02049513          	slli	a0,s1,0x20
    800030b0:	9101                	srli	a0,a0,0x20
    800030b2:	60e2                	ld	ra,24(sp)
    800030b4:	6442                	ld	s0,16(sp)
    800030b6:	64a2                	ld	s1,8(sp)
    800030b8:	6105                	addi	sp,sp,32
    800030ba:	8082                	ret

00000000800030bc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030bc:	7179                	addi	sp,sp,-48
    800030be:	f406                	sd	ra,40(sp)
    800030c0:	f022                	sd	s0,32(sp)
    800030c2:	ec26                	sd	s1,24(sp)
    800030c4:	e84a                	sd	s2,16(sp)
    800030c6:	e44e                	sd	s3,8(sp)
    800030c8:	e052                	sd	s4,0(sp)
    800030ca:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030cc:	00005597          	auipc	a1,0x5
    800030d0:	49458593          	addi	a1,a1,1172 # 80008560 <syscalls+0xb0>
    800030d4:	00015517          	auipc	a0,0x15
    800030d8:	8ac50513          	addi	a0,a0,-1876 # 80017980 <bcache>
    800030dc:	ffffe097          	auipc	ra,0xffffe
    800030e0:	aa4080e7          	jalr	-1372(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030e4:	0001d797          	auipc	a5,0x1d
    800030e8:	89c78793          	addi	a5,a5,-1892 # 8001f980 <bcache+0x8000>
    800030ec:	0001d717          	auipc	a4,0x1d
    800030f0:	afc70713          	addi	a4,a4,-1284 # 8001fbe8 <bcache+0x8268>
    800030f4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030f8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030fc:	00015497          	auipc	s1,0x15
    80003100:	89c48493          	addi	s1,s1,-1892 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80003104:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003106:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003108:	00005a17          	auipc	s4,0x5
    8000310c:	460a0a13          	addi	s4,s4,1120 # 80008568 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003110:	2b893783          	ld	a5,696(s2)
    80003114:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003116:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000311a:	85d2                	mv	a1,s4
    8000311c:	01048513          	addi	a0,s1,16
    80003120:	00001097          	auipc	ra,0x1
    80003124:	4ac080e7          	jalr	1196(ra) # 800045cc <initsleeplock>
    bcache.head.next->prev = b;
    80003128:	2b893783          	ld	a5,696(s2)
    8000312c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000312e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003132:	45848493          	addi	s1,s1,1112
    80003136:	fd349de3          	bne	s1,s3,80003110 <binit+0x54>
  }
}
    8000313a:	70a2                	ld	ra,40(sp)
    8000313c:	7402                	ld	s0,32(sp)
    8000313e:	64e2                	ld	s1,24(sp)
    80003140:	6942                	ld	s2,16(sp)
    80003142:	69a2                	ld	s3,8(sp)
    80003144:	6a02                	ld	s4,0(sp)
    80003146:	6145                	addi	sp,sp,48
    80003148:	8082                	ret

000000008000314a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000314a:	7179                	addi	sp,sp,-48
    8000314c:	f406                	sd	ra,40(sp)
    8000314e:	f022                	sd	s0,32(sp)
    80003150:	ec26                	sd	s1,24(sp)
    80003152:	e84a                	sd	s2,16(sp)
    80003154:	e44e                	sd	s3,8(sp)
    80003156:	1800                	addi	s0,sp,48
    80003158:	89aa                	mv	s3,a0
    8000315a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000315c:	00015517          	auipc	a0,0x15
    80003160:	82450513          	addi	a0,a0,-2012 # 80017980 <bcache>
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	aac080e7          	jalr	-1364(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000316c:	0001d497          	auipc	s1,0x1d
    80003170:	acc4b483          	ld	s1,-1332(s1) # 8001fc38 <bcache+0x82b8>
    80003174:	0001d797          	auipc	a5,0x1d
    80003178:	a7478793          	addi	a5,a5,-1420 # 8001fbe8 <bcache+0x8268>
    8000317c:	02f48f63          	beq	s1,a5,800031ba <bread+0x70>
    80003180:	873e                	mv	a4,a5
    80003182:	a021                	j	8000318a <bread+0x40>
    80003184:	68a4                	ld	s1,80(s1)
    80003186:	02e48a63          	beq	s1,a4,800031ba <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000318a:	449c                	lw	a5,8(s1)
    8000318c:	ff379ce3          	bne	a5,s3,80003184 <bread+0x3a>
    80003190:	44dc                	lw	a5,12(s1)
    80003192:	ff2799e3          	bne	a5,s2,80003184 <bread+0x3a>
      b->refcnt++;
    80003196:	40bc                	lw	a5,64(s1)
    80003198:	2785                	addiw	a5,a5,1
    8000319a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000319c:	00014517          	auipc	a0,0x14
    800031a0:	7e450513          	addi	a0,a0,2020 # 80017980 <bcache>
    800031a4:	ffffe097          	auipc	ra,0xffffe
    800031a8:	b20080e7          	jalr	-1248(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    800031ac:	01048513          	addi	a0,s1,16
    800031b0:	00001097          	auipc	ra,0x1
    800031b4:	456080e7          	jalr	1110(ra) # 80004606 <acquiresleep>
      return b;
    800031b8:	a8b9                	j	80003216 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031ba:	0001d497          	auipc	s1,0x1d
    800031be:	a764b483          	ld	s1,-1418(s1) # 8001fc30 <bcache+0x82b0>
    800031c2:	0001d797          	auipc	a5,0x1d
    800031c6:	a2678793          	addi	a5,a5,-1498 # 8001fbe8 <bcache+0x8268>
    800031ca:	00f48863          	beq	s1,a5,800031da <bread+0x90>
    800031ce:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031d0:	40bc                	lw	a5,64(s1)
    800031d2:	cf81                	beqz	a5,800031ea <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031d4:	64a4                	ld	s1,72(s1)
    800031d6:	fee49de3          	bne	s1,a4,800031d0 <bread+0x86>
  panic("bget: no buffers");
    800031da:	00005517          	auipc	a0,0x5
    800031de:	39650513          	addi	a0,a0,918 # 80008570 <syscalls+0xc0>
    800031e2:	ffffd097          	auipc	ra,0xffffd
    800031e6:	366080e7          	jalr	870(ra) # 80000548 <panic>
      b->dev = dev;
    800031ea:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800031ee:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800031f2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031f6:	4785                	li	a5,1
    800031f8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031fa:	00014517          	auipc	a0,0x14
    800031fe:	78650513          	addi	a0,a0,1926 # 80017980 <bcache>
    80003202:	ffffe097          	auipc	ra,0xffffe
    80003206:	ac2080e7          	jalr	-1342(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    8000320a:	01048513          	addi	a0,s1,16
    8000320e:	00001097          	auipc	ra,0x1
    80003212:	3f8080e7          	jalr	1016(ra) # 80004606 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003216:	409c                	lw	a5,0(s1)
    80003218:	cb89                	beqz	a5,8000322a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000321a:	8526                	mv	a0,s1
    8000321c:	70a2                	ld	ra,40(sp)
    8000321e:	7402                	ld	s0,32(sp)
    80003220:	64e2                	ld	s1,24(sp)
    80003222:	6942                	ld	s2,16(sp)
    80003224:	69a2                	ld	s3,8(sp)
    80003226:	6145                	addi	sp,sp,48
    80003228:	8082                	ret
    virtio_disk_rw(b, 0);
    8000322a:	4581                	li	a1,0
    8000322c:	8526                	mv	a0,s1
    8000322e:	00003097          	auipc	ra,0x3
    80003232:	f7e080e7          	jalr	-130(ra) # 800061ac <virtio_disk_rw>
    b->valid = 1;
    80003236:	4785                	li	a5,1
    80003238:	c09c                	sw	a5,0(s1)
  return b;
    8000323a:	b7c5                	j	8000321a <bread+0xd0>

000000008000323c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000323c:	1101                	addi	sp,sp,-32
    8000323e:	ec06                	sd	ra,24(sp)
    80003240:	e822                	sd	s0,16(sp)
    80003242:	e426                	sd	s1,8(sp)
    80003244:	1000                	addi	s0,sp,32
    80003246:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003248:	0541                	addi	a0,a0,16
    8000324a:	00001097          	auipc	ra,0x1
    8000324e:	456080e7          	jalr	1110(ra) # 800046a0 <holdingsleep>
    80003252:	cd01                	beqz	a0,8000326a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003254:	4585                	li	a1,1
    80003256:	8526                	mv	a0,s1
    80003258:	00003097          	auipc	ra,0x3
    8000325c:	f54080e7          	jalr	-172(ra) # 800061ac <virtio_disk_rw>
}
    80003260:	60e2                	ld	ra,24(sp)
    80003262:	6442                	ld	s0,16(sp)
    80003264:	64a2                	ld	s1,8(sp)
    80003266:	6105                	addi	sp,sp,32
    80003268:	8082                	ret
    panic("bwrite");
    8000326a:	00005517          	auipc	a0,0x5
    8000326e:	31e50513          	addi	a0,a0,798 # 80008588 <syscalls+0xd8>
    80003272:	ffffd097          	auipc	ra,0xffffd
    80003276:	2d6080e7          	jalr	726(ra) # 80000548 <panic>

000000008000327a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000327a:	1101                	addi	sp,sp,-32
    8000327c:	ec06                	sd	ra,24(sp)
    8000327e:	e822                	sd	s0,16(sp)
    80003280:	e426                	sd	s1,8(sp)
    80003282:	e04a                	sd	s2,0(sp)
    80003284:	1000                	addi	s0,sp,32
    80003286:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003288:	01050913          	addi	s2,a0,16
    8000328c:	854a                	mv	a0,s2
    8000328e:	00001097          	auipc	ra,0x1
    80003292:	412080e7          	jalr	1042(ra) # 800046a0 <holdingsleep>
    80003296:	c92d                	beqz	a0,80003308 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003298:	854a                	mv	a0,s2
    8000329a:	00001097          	auipc	ra,0x1
    8000329e:	3c2080e7          	jalr	962(ra) # 8000465c <releasesleep>

  acquire(&bcache.lock);
    800032a2:	00014517          	auipc	a0,0x14
    800032a6:	6de50513          	addi	a0,a0,1758 # 80017980 <bcache>
    800032aa:	ffffe097          	auipc	ra,0xffffe
    800032ae:	966080e7          	jalr	-1690(ra) # 80000c10 <acquire>
  b->refcnt--;
    800032b2:	40bc                	lw	a5,64(s1)
    800032b4:	37fd                	addiw	a5,a5,-1
    800032b6:	0007871b          	sext.w	a4,a5
    800032ba:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032bc:	eb05                	bnez	a4,800032ec <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032be:	68bc                	ld	a5,80(s1)
    800032c0:	64b8                	ld	a4,72(s1)
    800032c2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032c4:	64bc                	ld	a5,72(s1)
    800032c6:	68b8                	ld	a4,80(s1)
    800032c8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032ca:	0001c797          	auipc	a5,0x1c
    800032ce:	6b678793          	addi	a5,a5,1718 # 8001f980 <bcache+0x8000>
    800032d2:	2b87b703          	ld	a4,696(a5)
    800032d6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032d8:	0001d717          	auipc	a4,0x1d
    800032dc:	91070713          	addi	a4,a4,-1776 # 8001fbe8 <bcache+0x8268>
    800032e0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032e2:	2b87b703          	ld	a4,696(a5)
    800032e6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032e8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032ec:	00014517          	auipc	a0,0x14
    800032f0:	69450513          	addi	a0,a0,1684 # 80017980 <bcache>
    800032f4:	ffffe097          	auipc	ra,0xffffe
    800032f8:	9d0080e7          	jalr	-1584(ra) # 80000cc4 <release>
}
    800032fc:	60e2                	ld	ra,24(sp)
    800032fe:	6442                	ld	s0,16(sp)
    80003300:	64a2                	ld	s1,8(sp)
    80003302:	6902                	ld	s2,0(sp)
    80003304:	6105                	addi	sp,sp,32
    80003306:	8082                	ret
    panic("brelse");
    80003308:	00005517          	auipc	a0,0x5
    8000330c:	28850513          	addi	a0,a0,648 # 80008590 <syscalls+0xe0>
    80003310:	ffffd097          	auipc	ra,0xffffd
    80003314:	238080e7          	jalr	568(ra) # 80000548 <panic>

0000000080003318 <bpin>:

void
bpin(struct buf *b) {
    80003318:	1101                	addi	sp,sp,-32
    8000331a:	ec06                	sd	ra,24(sp)
    8000331c:	e822                	sd	s0,16(sp)
    8000331e:	e426                	sd	s1,8(sp)
    80003320:	1000                	addi	s0,sp,32
    80003322:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003324:	00014517          	auipc	a0,0x14
    80003328:	65c50513          	addi	a0,a0,1628 # 80017980 <bcache>
    8000332c:	ffffe097          	auipc	ra,0xffffe
    80003330:	8e4080e7          	jalr	-1820(ra) # 80000c10 <acquire>
  b->refcnt++;
    80003334:	40bc                	lw	a5,64(s1)
    80003336:	2785                	addiw	a5,a5,1
    80003338:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000333a:	00014517          	auipc	a0,0x14
    8000333e:	64650513          	addi	a0,a0,1606 # 80017980 <bcache>
    80003342:	ffffe097          	auipc	ra,0xffffe
    80003346:	982080e7          	jalr	-1662(ra) # 80000cc4 <release>
}
    8000334a:	60e2                	ld	ra,24(sp)
    8000334c:	6442                	ld	s0,16(sp)
    8000334e:	64a2                	ld	s1,8(sp)
    80003350:	6105                	addi	sp,sp,32
    80003352:	8082                	ret

0000000080003354 <bunpin>:

void
bunpin(struct buf *b) {
    80003354:	1101                	addi	sp,sp,-32
    80003356:	ec06                	sd	ra,24(sp)
    80003358:	e822                	sd	s0,16(sp)
    8000335a:	e426                	sd	s1,8(sp)
    8000335c:	1000                	addi	s0,sp,32
    8000335e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003360:	00014517          	auipc	a0,0x14
    80003364:	62050513          	addi	a0,a0,1568 # 80017980 <bcache>
    80003368:	ffffe097          	auipc	ra,0xffffe
    8000336c:	8a8080e7          	jalr	-1880(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003370:	40bc                	lw	a5,64(s1)
    80003372:	37fd                	addiw	a5,a5,-1
    80003374:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003376:	00014517          	auipc	a0,0x14
    8000337a:	60a50513          	addi	a0,a0,1546 # 80017980 <bcache>
    8000337e:	ffffe097          	auipc	ra,0xffffe
    80003382:	946080e7          	jalr	-1722(ra) # 80000cc4 <release>
}
    80003386:	60e2                	ld	ra,24(sp)
    80003388:	6442                	ld	s0,16(sp)
    8000338a:	64a2                	ld	s1,8(sp)
    8000338c:	6105                	addi	sp,sp,32
    8000338e:	8082                	ret

0000000080003390 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003390:	1101                	addi	sp,sp,-32
    80003392:	ec06                	sd	ra,24(sp)
    80003394:	e822                	sd	s0,16(sp)
    80003396:	e426                	sd	s1,8(sp)
    80003398:	e04a                	sd	s2,0(sp)
    8000339a:	1000                	addi	s0,sp,32
    8000339c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000339e:	00d5d59b          	srliw	a1,a1,0xd
    800033a2:	0001d797          	auipc	a5,0x1d
    800033a6:	cba7a783          	lw	a5,-838(a5) # 8002005c <sb+0x1c>
    800033aa:	9dbd                	addw	a1,a1,a5
    800033ac:	00000097          	auipc	ra,0x0
    800033b0:	d9e080e7          	jalr	-610(ra) # 8000314a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033b4:	0074f713          	andi	a4,s1,7
    800033b8:	4785                	li	a5,1
    800033ba:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033be:	14ce                	slli	s1,s1,0x33
    800033c0:	90d9                	srli	s1,s1,0x36
    800033c2:	00950733          	add	a4,a0,s1
    800033c6:	05874703          	lbu	a4,88(a4)
    800033ca:	00e7f6b3          	and	a3,a5,a4
    800033ce:	c69d                	beqz	a3,800033fc <bfree+0x6c>
    800033d0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033d2:	94aa                	add	s1,s1,a0
    800033d4:	fff7c793          	not	a5,a5
    800033d8:	8ff9                	and	a5,a5,a4
    800033da:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033de:	00001097          	auipc	ra,0x1
    800033e2:	100080e7          	jalr	256(ra) # 800044de <log_write>
  brelse(bp);
    800033e6:	854a                	mv	a0,s2
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	e92080e7          	jalr	-366(ra) # 8000327a <brelse>
}
    800033f0:	60e2                	ld	ra,24(sp)
    800033f2:	6442                	ld	s0,16(sp)
    800033f4:	64a2                	ld	s1,8(sp)
    800033f6:	6902                	ld	s2,0(sp)
    800033f8:	6105                	addi	sp,sp,32
    800033fa:	8082                	ret
    panic("freeing free block");
    800033fc:	00005517          	auipc	a0,0x5
    80003400:	19c50513          	addi	a0,a0,412 # 80008598 <syscalls+0xe8>
    80003404:	ffffd097          	auipc	ra,0xffffd
    80003408:	144080e7          	jalr	324(ra) # 80000548 <panic>

000000008000340c <balloc>:
{
    8000340c:	711d                	addi	sp,sp,-96
    8000340e:	ec86                	sd	ra,88(sp)
    80003410:	e8a2                	sd	s0,80(sp)
    80003412:	e4a6                	sd	s1,72(sp)
    80003414:	e0ca                	sd	s2,64(sp)
    80003416:	fc4e                	sd	s3,56(sp)
    80003418:	f852                	sd	s4,48(sp)
    8000341a:	f456                	sd	s5,40(sp)
    8000341c:	f05a                	sd	s6,32(sp)
    8000341e:	ec5e                	sd	s7,24(sp)
    80003420:	e862                	sd	s8,16(sp)
    80003422:	e466                	sd	s9,8(sp)
    80003424:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003426:	0001d797          	auipc	a5,0x1d
    8000342a:	c1e7a783          	lw	a5,-994(a5) # 80020044 <sb+0x4>
    8000342e:	cbd1                	beqz	a5,800034c2 <balloc+0xb6>
    80003430:	8baa                	mv	s7,a0
    80003432:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003434:	0001db17          	auipc	s6,0x1d
    80003438:	c0cb0b13          	addi	s6,s6,-1012 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000343c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000343e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003440:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003442:	6c89                	lui	s9,0x2
    80003444:	a831                	j	80003460 <balloc+0x54>
    brelse(bp);
    80003446:	854a                	mv	a0,s2
    80003448:	00000097          	auipc	ra,0x0
    8000344c:	e32080e7          	jalr	-462(ra) # 8000327a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003450:	015c87bb          	addw	a5,s9,s5
    80003454:	00078a9b          	sext.w	s5,a5
    80003458:	004b2703          	lw	a4,4(s6)
    8000345c:	06eaf363          	bgeu	s5,a4,800034c2 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003460:	41fad79b          	sraiw	a5,s5,0x1f
    80003464:	0137d79b          	srliw	a5,a5,0x13
    80003468:	015787bb          	addw	a5,a5,s5
    8000346c:	40d7d79b          	sraiw	a5,a5,0xd
    80003470:	01cb2583          	lw	a1,28(s6)
    80003474:	9dbd                	addw	a1,a1,a5
    80003476:	855e                	mv	a0,s7
    80003478:	00000097          	auipc	ra,0x0
    8000347c:	cd2080e7          	jalr	-814(ra) # 8000314a <bread>
    80003480:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003482:	004b2503          	lw	a0,4(s6)
    80003486:	000a849b          	sext.w	s1,s5
    8000348a:	8662                	mv	a2,s8
    8000348c:	faa4fde3          	bgeu	s1,a0,80003446 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003490:	41f6579b          	sraiw	a5,a2,0x1f
    80003494:	01d7d69b          	srliw	a3,a5,0x1d
    80003498:	00c6873b          	addw	a4,a3,a2
    8000349c:	00777793          	andi	a5,a4,7
    800034a0:	9f95                	subw	a5,a5,a3
    800034a2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034a6:	4037571b          	sraiw	a4,a4,0x3
    800034aa:	00e906b3          	add	a3,s2,a4
    800034ae:	0586c683          	lbu	a3,88(a3)
    800034b2:	00d7f5b3          	and	a1,a5,a3
    800034b6:	cd91                	beqz	a1,800034d2 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034b8:	2605                	addiw	a2,a2,1
    800034ba:	2485                	addiw	s1,s1,1
    800034bc:	fd4618e3          	bne	a2,s4,8000348c <balloc+0x80>
    800034c0:	b759                	j	80003446 <balloc+0x3a>
  panic("balloc: out of blocks");
    800034c2:	00005517          	auipc	a0,0x5
    800034c6:	0ee50513          	addi	a0,a0,238 # 800085b0 <syscalls+0x100>
    800034ca:	ffffd097          	auipc	ra,0xffffd
    800034ce:	07e080e7          	jalr	126(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034d2:	974a                	add	a4,a4,s2
    800034d4:	8fd5                	or	a5,a5,a3
    800034d6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034da:	854a                	mv	a0,s2
    800034dc:	00001097          	auipc	ra,0x1
    800034e0:	002080e7          	jalr	2(ra) # 800044de <log_write>
        brelse(bp);
    800034e4:	854a                	mv	a0,s2
    800034e6:	00000097          	auipc	ra,0x0
    800034ea:	d94080e7          	jalr	-620(ra) # 8000327a <brelse>
  bp = bread(dev, bno);
    800034ee:	85a6                	mv	a1,s1
    800034f0:	855e                	mv	a0,s7
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	c58080e7          	jalr	-936(ra) # 8000314a <bread>
    800034fa:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034fc:	40000613          	li	a2,1024
    80003500:	4581                	li	a1,0
    80003502:	05850513          	addi	a0,a0,88
    80003506:	ffffe097          	auipc	ra,0xffffe
    8000350a:	806080e7          	jalr	-2042(ra) # 80000d0c <memset>
  log_write(bp);
    8000350e:	854a                	mv	a0,s2
    80003510:	00001097          	auipc	ra,0x1
    80003514:	fce080e7          	jalr	-50(ra) # 800044de <log_write>
  brelse(bp);
    80003518:	854a                	mv	a0,s2
    8000351a:	00000097          	auipc	ra,0x0
    8000351e:	d60080e7          	jalr	-672(ra) # 8000327a <brelse>
}
    80003522:	8526                	mv	a0,s1
    80003524:	60e6                	ld	ra,88(sp)
    80003526:	6446                	ld	s0,80(sp)
    80003528:	64a6                	ld	s1,72(sp)
    8000352a:	6906                	ld	s2,64(sp)
    8000352c:	79e2                	ld	s3,56(sp)
    8000352e:	7a42                	ld	s4,48(sp)
    80003530:	7aa2                	ld	s5,40(sp)
    80003532:	7b02                	ld	s6,32(sp)
    80003534:	6be2                	ld	s7,24(sp)
    80003536:	6c42                	ld	s8,16(sp)
    80003538:	6ca2                	ld	s9,8(sp)
    8000353a:	6125                	addi	sp,sp,96
    8000353c:	8082                	ret

000000008000353e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000353e:	7179                	addi	sp,sp,-48
    80003540:	f406                	sd	ra,40(sp)
    80003542:	f022                	sd	s0,32(sp)
    80003544:	ec26                	sd	s1,24(sp)
    80003546:	e84a                	sd	s2,16(sp)
    80003548:	e44e                	sd	s3,8(sp)
    8000354a:	e052                	sd	s4,0(sp)
    8000354c:	1800                	addi	s0,sp,48
    8000354e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003550:	47ad                	li	a5,11
    80003552:	04b7fe63          	bgeu	a5,a1,800035ae <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003556:	ff45849b          	addiw	s1,a1,-12
    8000355a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000355e:	0ff00793          	li	a5,255
    80003562:	0ae7e363          	bltu	a5,a4,80003608 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003566:	08052583          	lw	a1,128(a0)
    8000356a:	c5ad                	beqz	a1,800035d4 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000356c:	00092503          	lw	a0,0(s2)
    80003570:	00000097          	auipc	ra,0x0
    80003574:	bda080e7          	jalr	-1062(ra) # 8000314a <bread>
    80003578:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000357a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000357e:	02049593          	slli	a1,s1,0x20
    80003582:	9181                	srli	a1,a1,0x20
    80003584:	058a                	slli	a1,a1,0x2
    80003586:	00b784b3          	add	s1,a5,a1
    8000358a:	0004a983          	lw	s3,0(s1)
    8000358e:	04098d63          	beqz	s3,800035e8 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003592:	8552                	mv	a0,s4
    80003594:	00000097          	auipc	ra,0x0
    80003598:	ce6080e7          	jalr	-794(ra) # 8000327a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000359c:	854e                	mv	a0,s3
    8000359e:	70a2                	ld	ra,40(sp)
    800035a0:	7402                	ld	s0,32(sp)
    800035a2:	64e2                	ld	s1,24(sp)
    800035a4:	6942                	ld	s2,16(sp)
    800035a6:	69a2                	ld	s3,8(sp)
    800035a8:	6a02                	ld	s4,0(sp)
    800035aa:	6145                	addi	sp,sp,48
    800035ac:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035ae:	02059493          	slli	s1,a1,0x20
    800035b2:	9081                	srli	s1,s1,0x20
    800035b4:	048a                	slli	s1,s1,0x2
    800035b6:	94aa                	add	s1,s1,a0
    800035b8:	0504a983          	lw	s3,80(s1)
    800035bc:	fe0990e3          	bnez	s3,8000359c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035c0:	4108                	lw	a0,0(a0)
    800035c2:	00000097          	auipc	ra,0x0
    800035c6:	e4a080e7          	jalr	-438(ra) # 8000340c <balloc>
    800035ca:	0005099b          	sext.w	s3,a0
    800035ce:	0534a823          	sw	s3,80(s1)
    800035d2:	b7e9                	j	8000359c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035d4:	4108                	lw	a0,0(a0)
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	e36080e7          	jalr	-458(ra) # 8000340c <balloc>
    800035de:	0005059b          	sext.w	a1,a0
    800035e2:	08b92023          	sw	a1,128(s2)
    800035e6:	b759                	j	8000356c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800035e8:	00092503          	lw	a0,0(s2)
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	e20080e7          	jalr	-480(ra) # 8000340c <balloc>
    800035f4:	0005099b          	sext.w	s3,a0
    800035f8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800035fc:	8552                	mv	a0,s4
    800035fe:	00001097          	auipc	ra,0x1
    80003602:	ee0080e7          	jalr	-288(ra) # 800044de <log_write>
    80003606:	b771                	j	80003592 <bmap+0x54>
  panic("bmap: out of range");
    80003608:	00005517          	auipc	a0,0x5
    8000360c:	fc050513          	addi	a0,a0,-64 # 800085c8 <syscalls+0x118>
    80003610:	ffffd097          	auipc	ra,0xffffd
    80003614:	f38080e7          	jalr	-200(ra) # 80000548 <panic>

0000000080003618 <iget>:
{
    80003618:	7179                	addi	sp,sp,-48
    8000361a:	f406                	sd	ra,40(sp)
    8000361c:	f022                	sd	s0,32(sp)
    8000361e:	ec26                	sd	s1,24(sp)
    80003620:	e84a                	sd	s2,16(sp)
    80003622:	e44e                	sd	s3,8(sp)
    80003624:	e052                	sd	s4,0(sp)
    80003626:	1800                	addi	s0,sp,48
    80003628:	89aa                	mv	s3,a0
    8000362a:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000362c:	0001d517          	auipc	a0,0x1d
    80003630:	a3450513          	addi	a0,a0,-1484 # 80020060 <icache>
    80003634:	ffffd097          	auipc	ra,0xffffd
    80003638:	5dc080e7          	jalr	1500(ra) # 80000c10 <acquire>
  empty = 0;
    8000363c:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000363e:	0001d497          	auipc	s1,0x1d
    80003642:	a3a48493          	addi	s1,s1,-1478 # 80020078 <icache+0x18>
    80003646:	0001e697          	auipc	a3,0x1e
    8000364a:	4c268693          	addi	a3,a3,1218 # 80021b08 <log>
    8000364e:	a039                	j	8000365c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003650:	02090b63          	beqz	s2,80003686 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003654:	08848493          	addi	s1,s1,136
    80003658:	02d48a63          	beq	s1,a3,8000368c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000365c:	449c                	lw	a5,8(s1)
    8000365e:	fef059e3          	blez	a5,80003650 <iget+0x38>
    80003662:	4098                	lw	a4,0(s1)
    80003664:	ff3716e3          	bne	a4,s3,80003650 <iget+0x38>
    80003668:	40d8                	lw	a4,4(s1)
    8000366a:	ff4713e3          	bne	a4,s4,80003650 <iget+0x38>
      ip->ref++;
    8000366e:	2785                	addiw	a5,a5,1
    80003670:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003672:	0001d517          	auipc	a0,0x1d
    80003676:	9ee50513          	addi	a0,a0,-1554 # 80020060 <icache>
    8000367a:	ffffd097          	auipc	ra,0xffffd
    8000367e:	64a080e7          	jalr	1610(ra) # 80000cc4 <release>
      return ip;
    80003682:	8926                	mv	s2,s1
    80003684:	a03d                	j	800036b2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003686:	f7f9                	bnez	a5,80003654 <iget+0x3c>
    80003688:	8926                	mv	s2,s1
    8000368a:	b7e9                	j	80003654 <iget+0x3c>
  if(empty == 0)
    8000368c:	02090c63          	beqz	s2,800036c4 <iget+0xac>
  ip->dev = dev;
    80003690:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003694:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003698:	4785                	li	a5,1
    8000369a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000369e:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800036a2:	0001d517          	auipc	a0,0x1d
    800036a6:	9be50513          	addi	a0,a0,-1602 # 80020060 <icache>
    800036aa:	ffffd097          	auipc	ra,0xffffd
    800036ae:	61a080e7          	jalr	1562(ra) # 80000cc4 <release>
}
    800036b2:	854a                	mv	a0,s2
    800036b4:	70a2                	ld	ra,40(sp)
    800036b6:	7402                	ld	s0,32(sp)
    800036b8:	64e2                	ld	s1,24(sp)
    800036ba:	6942                	ld	s2,16(sp)
    800036bc:	69a2                	ld	s3,8(sp)
    800036be:	6a02                	ld	s4,0(sp)
    800036c0:	6145                	addi	sp,sp,48
    800036c2:	8082                	ret
    panic("iget: no inodes");
    800036c4:	00005517          	auipc	a0,0x5
    800036c8:	f1c50513          	addi	a0,a0,-228 # 800085e0 <syscalls+0x130>
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	e7c080e7          	jalr	-388(ra) # 80000548 <panic>

00000000800036d4 <fsinit>:
fsinit(int dev) {
    800036d4:	7179                	addi	sp,sp,-48
    800036d6:	f406                	sd	ra,40(sp)
    800036d8:	f022                	sd	s0,32(sp)
    800036da:	ec26                	sd	s1,24(sp)
    800036dc:	e84a                	sd	s2,16(sp)
    800036de:	e44e                	sd	s3,8(sp)
    800036e0:	1800                	addi	s0,sp,48
    800036e2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036e4:	4585                	li	a1,1
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	a64080e7          	jalr	-1436(ra) # 8000314a <bread>
    800036ee:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036f0:	0001d997          	auipc	s3,0x1d
    800036f4:	95098993          	addi	s3,s3,-1712 # 80020040 <sb>
    800036f8:	02000613          	li	a2,32
    800036fc:	05850593          	addi	a1,a0,88
    80003700:	854e                	mv	a0,s3
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	66a080e7          	jalr	1642(ra) # 80000d6c <memmove>
  brelse(bp);
    8000370a:	8526                	mv	a0,s1
    8000370c:	00000097          	auipc	ra,0x0
    80003710:	b6e080e7          	jalr	-1170(ra) # 8000327a <brelse>
  if(sb.magic != FSMAGIC)
    80003714:	0009a703          	lw	a4,0(s3)
    80003718:	102037b7          	lui	a5,0x10203
    8000371c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003720:	02f71263          	bne	a4,a5,80003744 <fsinit+0x70>
  initlog(dev, &sb);
    80003724:	0001d597          	auipc	a1,0x1d
    80003728:	91c58593          	addi	a1,a1,-1764 # 80020040 <sb>
    8000372c:	854a                	mv	a0,s2
    8000372e:	00001097          	auipc	ra,0x1
    80003732:	b38080e7          	jalr	-1224(ra) # 80004266 <initlog>
}
    80003736:	70a2                	ld	ra,40(sp)
    80003738:	7402                	ld	s0,32(sp)
    8000373a:	64e2                	ld	s1,24(sp)
    8000373c:	6942                	ld	s2,16(sp)
    8000373e:	69a2                	ld	s3,8(sp)
    80003740:	6145                	addi	sp,sp,48
    80003742:	8082                	ret
    panic("invalid file system");
    80003744:	00005517          	auipc	a0,0x5
    80003748:	eac50513          	addi	a0,a0,-340 # 800085f0 <syscalls+0x140>
    8000374c:	ffffd097          	auipc	ra,0xffffd
    80003750:	dfc080e7          	jalr	-516(ra) # 80000548 <panic>

0000000080003754 <iinit>:
{
    80003754:	7179                	addi	sp,sp,-48
    80003756:	f406                	sd	ra,40(sp)
    80003758:	f022                	sd	s0,32(sp)
    8000375a:	ec26                	sd	s1,24(sp)
    8000375c:	e84a                	sd	s2,16(sp)
    8000375e:	e44e                	sd	s3,8(sp)
    80003760:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003762:	00005597          	auipc	a1,0x5
    80003766:	ea658593          	addi	a1,a1,-346 # 80008608 <syscalls+0x158>
    8000376a:	0001d517          	auipc	a0,0x1d
    8000376e:	8f650513          	addi	a0,a0,-1802 # 80020060 <icache>
    80003772:	ffffd097          	auipc	ra,0xffffd
    80003776:	40e080e7          	jalr	1038(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000377a:	0001d497          	auipc	s1,0x1d
    8000377e:	90e48493          	addi	s1,s1,-1778 # 80020088 <icache+0x28>
    80003782:	0001e997          	auipc	s3,0x1e
    80003786:	39698993          	addi	s3,s3,918 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000378a:	00005917          	auipc	s2,0x5
    8000378e:	e8690913          	addi	s2,s2,-378 # 80008610 <syscalls+0x160>
    80003792:	85ca                	mv	a1,s2
    80003794:	8526                	mv	a0,s1
    80003796:	00001097          	auipc	ra,0x1
    8000379a:	e36080e7          	jalr	-458(ra) # 800045cc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000379e:	08848493          	addi	s1,s1,136
    800037a2:	ff3498e3          	bne	s1,s3,80003792 <iinit+0x3e>
}
    800037a6:	70a2                	ld	ra,40(sp)
    800037a8:	7402                	ld	s0,32(sp)
    800037aa:	64e2                	ld	s1,24(sp)
    800037ac:	6942                	ld	s2,16(sp)
    800037ae:	69a2                	ld	s3,8(sp)
    800037b0:	6145                	addi	sp,sp,48
    800037b2:	8082                	ret

00000000800037b4 <ialloc>:
{
    800037b4:	715d                	addi	sp,sp,-80
    800037b6:	e486                	sd	ra,72(sp)
    800037b8:	e0a2                	sd	s0,64(sp)
    800037ba:	fc26                	sd	s1,56(sp)
    800037bc:	f84a                	sd	s2,48(sp)
    800037be:	f44e                	sd	s3,40(sp)
    800037c0:	f052                	sd	s4,32(sp)
    800037c2:	ec56                	sd	s5,24(sp)
    800037c4:	e85a                	sd	s6,16(sp)
    800037c6:	e45e                	sd	s7,8(sp)
    800037c8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037ca:	0001d717          	auipc	a4,0x1d
    800037ce:	88272703          	lw	a4,-1918(a4) # 8002004c <sb+0xc>
    800037d2:	4785                	li	a5,1
    800037d4:	04e7fa63          	bgeu	a5,a4,80003828 <ialloc+0x74>
    800037d8:	8aaa                	mv	s5,a0
    800037da:	8bae                	mv	s7,a1
    800037dc:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037de:	0001da17          	auipc	s4,0x1d
    800037e2:	862a0a13          	addi	s4,s4,-1950 # 80020040 <sb>
    800037e6:	00048b1b          	sext.w	s6,s1
    800037ea:	0044d593          	srli	a1,s1,0x4
    800037ee:	018a2783          	lw	a5,24(s4)
    800037f2:	9dbd                	addw	a1,a1,a5
    800037f4:	8556                	mv	a0,s5
    800037f6:	00000097          	auipc	ra,0x0
    800037fa:	954080e7          	jalr	-1708(ra) # 8000314a <bread>
    800037fe:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003800:	05850993          	addi	s3,a0,88
    80003804:	00f4f793          	andi	a5,s1,15
    80003808:	079a                	slli	a5,a5,0x6
    8000380a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000380c:	00099783          	lh	a5,0(s3)
    80003810:	c785                	beqz	a5,80003838 <ialloc+0x84>
    brelse(bp);
    80003812:	00000097          	auipc	ra,0x0
    80003816:	a68080e7          	jalr	-1432(ra) # 8000327a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000381a:	0485                	addi	s1,s1,1
    8000381c:	00ca2703          	lw	a4,12(s4)
    80003820:	0004879b          	sext.w	a5,s1
    80003824:	fce7e1e3          	bltu	a5,a4,800037e6 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003828:	00005517          	auipc	a0,0x5
    8000382c:	df050513          	addi	a0,a0,-528 # 80008618 <syscalls+0x168>
    80003830:	ffffd097          	auipc	ra,0xffffd
    80003834:	d18080e7          	jalr	-744(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003838:	04000613          	li	a2,64
    8000383c:	4581                	li	a1,0
    8000383e:	854e                	mv	a0,s3
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	4cc080e7          	jalr	1228(ra) # 80000d0c <memset>
      dip->type = type;
    80003848:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000384c:	854a                	mv	a0,s2
    8000384e:	00001097          	auipc	ra,0x1
    80003852:	c90080e7          	jalr	-880(ra) # 800044de <log_write>
      brelse(bp);
    80003856:	854a                	mv	a0,s2
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	a22080e7          	jalr	-1502(ra) # 8000327a <brelse>
      return iget(dev, inum);
    80003860:	85da                	mv	a1,s6
    80003862:	8556                	mv	a0,s5
    80003864:	00000097          	auipc	ra,0x0
    80003868:	db4080e7          	jalr	-588(ra) # 80003618 <iget>
}
    8000386c:	60a6                	ld	ra,72(sp)
    8000386e:	6406                	ld	s0,64(sp)
    80003870:	74e2                	ld	s1,56(sp)
    80003872:	7942                	ld	s2,48(sp)
    80003874:	79a2                	ld	s3,40(sp)
    80003876:	7a02                	ld	s4,32(sp)
    80003878:	6ae2                	ld	s5,24(sp)
    8000387a:	6b42                	ld	s6,16(sp)
    8000387c:	6ba2                	ld	s7,8(sp)
    8000387e:	6161                	addi	sp,sp,80
    80003880:	8082                	ret

0000000080003882 <iupdate>:
{
    80003882:	1101                	addi	sp,sp,-32
    80003884:	ec06                	sd	ra,24(sp)
    80003886:	e822                	sd	s0,16(sp)
    80003888:	e426                	sd	s1,8(sp)
    8000388a:	e04a                	sd	s2,0(sp)
    8000388c:	1000                	addi	s0,sp,32
    8000388e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003890:	415c                	lw	a5,4(a0)
    80003892:	0047d79b          	srliw	a5,a5,0x4
    80003896:	0001c597          	auipc	a1,0x1c
    8000389a:	7c25a583          	lw	a1,1986(a1) # 80020058 <sb+0x18>
    8000389e:	9dbd                	addw	a1,a1,a5
    800038a0:	4108                	lw	a0,0(a0)
    800038a2:	00000097          	auipc	ra,0x0
    800038a6:	8a8080e7          	jalr	-1880(ra) # 8000314a <bread>
    800038aa:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038ac:	05850793          	addi	a5,a0,88
    800038b0:	40c8                	lw	a0,4(s1)
    800038b2:	893d                	andi	a0,a0,15
    800038b4:	051a                	slli	a0,a0,0x6
    800038b6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038b8:	04449703          	lh	a4,68(s1)
    800038bc:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038c0:	04649703          	lh	a4,70(s1)
    800038c4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038c8:	04849703          	lh	a4,72(s1)
    800038cc:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038d0:	04a49703          	lh	a4,74(s1)
    800038d4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038d8:	44f8                	lw	a4,76(s1)
    800038da:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038dc:	03400613          	li	a2,52
    800038e0:	05048593          	addi	a1,s1,80
    800038e4:	0531                	addi	a0,a0,12
    800038e6:	ffffd097          	auipc	ra,0xffffd
    800038ea:	486080e7          	jalr	1158(ra) # 80000d6c <memmove>
  log_write(bp);
    800038ee:	854a                	mv	a0,s2
    800038f0:	00001097          	auipc	ra,0x1
    800038f4:	bee080e7          	jalr	-1042(ra) # 800044de <log_write>
  brelse(bp);
    800038f8:	854a                	mv	a0,s2
    800038fa:	00000097          	auipc	ra,0x0
    800038fe:	980080e7          	jalr	-1664(ra) # 8000327a <brelse>
}
    80003902:	60e2                	ld	ra,24(sp)
    80003904:	6442                	ld	s0,16(sp)
    80003906:	64a2                	ld	s1,8(sp)
    80003908:	6902                	ld	s2,0(sp)
    8000390a:	6105                	addi	sp,sp,32
    8000390c:	8082                	ret

000000008000390e <idup>:
{
    8000390e:	1101                	addi	sp,sp,-32
    80003910:	ec06                	sd	ra,24(sp)
    80003912:	e822                	sd	s0,16(sp)
    80003914:	e426                	sd	s1,8(sp)
    80003916:	1000                	addi	s0,sp,32
    80003918:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000391a:	0001c517          	auipc	a0,0x1c
    8000391e:	74650513          	addi	a0,a0,1862 # 80020060 <icache>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	2ee080e7          	jalr	750(ra) # 80000c10 <acquire>
  ip->ref++;
    8000392a:	449c                	lw	a5,8(s1)
    8000392c:	2785                	addiw	a5,a5,1
    8000392e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003930:	0001c517          	auipc	a0,0x1c
    80003934:	73050513          	addi	a0,a0,1840 # 80020060 <icache>
    80003938:	ffffd097          	auipc	ra,0xffffd
    8000393c:	38c080e7          	jalr	908(ra) # 80000cc4 <release>
}
    80003940:	8526                	mv	a0,s1
    80003942:	60e2                	ld	ra,24(sp)
    80003944:	6442                	ld	s0,16(sp)
    80003946:	64a2                	ld	s1,8(sp)
    80003948:	6105                	addi	sp,sp,32
    8000394a:	8082                	ret

000000008000394c <ilock>:
{
    8000394c:	1101                	addi	sp,sp,-32
    8000394e:	ec06                	sd	ra,24(sp)
    80003950:	e822                	sd	s0,16(sp)
    80003952:	e426                	sd	s1,8(sp)
    80003954:	e04a                	sd	s2,0(sp)
    80003956:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003958:	c115                	beqz	a0,8000397c <ilock+0x30>
    8000395a:	84aa                	mv	s1,a0
    8000395c:	451c                	lw	a5,8(a0)
    8000395e:	00f05f63          	blez	a5,8000397c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003962:	0541                	addi	a0,a0,16
    80003964:	00001097          	auipc	ra,0x1
    80003968:	ca2080e7          	jalr	-862(ra) # 80004606 <acquiresleep>
  if(ip->valid == 0){
    8000396c:	40bc                	lw	a5,64(s1)
    8000396e:	cf99                	beqz	a5,8000398c <ilock+0x40>
}
    80003970:	60e2                	ld	ra,24(sp)
    80003972:	6442                	ld	s0,16(sp)
    80003974:	64a2                	ld	s1,8(sp)
    80003976:	6902                	ld	s2,0(sp)
    80003978:	6105                	addi	sp,sp,32
    8000397a:	8082                	ret
    panic("ilock");
    8000397c:	00005517          	auipc	a0,0x5
    80003980:	cb450513          	addi	a0,a0,-844 # 80008630 <syscalls+0x180>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	bc4080e7          	jalr	-1084(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000398c:	40dc                	lw	a5,4(s1)
    8000398e:	0047d79b          	srliw	a5,a5,0x4
    80003992:	0001c597          	auipc	a1,0x1c
    80003996:	6c65a583          	lw	a1,1734(a1) # 80020058 <sb+0x18>
    8000399a:	9dbd                	addw	a1,a1,a5
    8000399c:	4088                	lw	a0,0(s1)
    8000399e:	fffff097          	auipc	ra,0xfffff
    800039a2:	7ac080e7          	jalr	1964(ra) # 8000314a <bread>
    800039a6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039a8:	05850593          	addi	a1,a0,88
    800039ac:	40dc                	lw	a5,4(s1)
    800039ae:	8bbd                	andi	a5,a5,15
    800039b0:	079a                	slli	a5,a5,0x6
    800039b2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039b4:	00059783          	lh	a5,0(a1)
    800039b8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039bc:	00259783          	lh	a5,2(a1)
    800039c0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039c4:	00459783          	lh	a5,4(a1)
    800039c8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039cc:	00659783          	lh	a5,6(a1)
    800039d0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039d4:	459c                	lw	a5,8(a1)
    800039d6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039d8:	03400613          	li	a2,52
    800039dc:	05b1                	addi	a1,a1,12
    800039de:	05048513          	addi	a0,s1,80
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	38a080e7          	jalr	906(ra) # 80000d6c <memmove>
    brelse(bp);
    800039ea:	854a                	mv	a0,s2
    800039ec:	00000097          	auipc	ra,0x0
    800039f0:	88e080e7          	jalr	-1906(ra) # 8000327a <brelse>
    ip->valid = 1;
    800039f4:	4785                	li	a5,1
    800039f6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039f8:	04449783          	lh	a5,68(s1)
    800039fc:	fbb5                	bnez	a5,80003970 <ilock+0x24>
      panic("ilock: no type");
    800039fe:	00005517          	auipc	a0,0x5
    80003a02:	c3a50513          	addi	a0,a0,-966 # 80008638 <syscalls+0x188>
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	b42080e7          	jalr	-1214(ra) # 80000548 <panic>

0000000080003a0e <iunlock>:
{
    80003a0e:	1101                	addi	sp,sp,-32
    80003a10:	ec06                	sd	ra,24(sp)
    80003a12:	e822                	sd	s0,16(sp)
    80003a14:	e426                	sd	s1,8(sp)
    80003a16:	e04a                	sd	s2,0(sp)
    80003a18:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a1a:	c905                	beqz	a0,80003a4a <iunlock+0x3c>
    80003a1c:	84aa                	mv	s1,a0
    80003a1e:	01050913          	addi	s2,a0,16
    80003a22:	854a                	mv	a0,s2
    80003a24:	00001097          	auipc	ra,0x1
    80003a28:	c7c080e7          	jalr	-900(ra) # 800046a0 <holdingsleep>
    80003a2c:	cd19                	beqz	a0,80003a4a <iunlock+0x3c>
    80003a2e:	449c                	lw	a5,8(s1)
    80003a30:	00f05d63          	blez	a5,80003a4a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a34:	854a                	mv	a0,s2
    80003a36:	00001097          	auipc	ra,0x1
    80003a3a:	c26080e7          	jalr	-986(ra) # 8000465c <releasesleep>
}
    80003a3e:	60e2                	ld	ra,24(sp)
    80003a40:	6442                	ld	s0,16(sp)
    80003a42:	64a2                	ld	s1,8(sp)
    80003a44:	6902                	ld	s2,0(sp)
    80003a46:	6105                	addi	sp,sp,32
    80003a48:	8082                	ret
    panic("iunlock");
    80003a4a:	00005517          	auipc	a0,0x5
    80003a4e:	bfe50513          	addi	a0,a0,-1026 # 80008648 <syscalls+0x198>
    80003a52:	ffffd097          	auipc	ra,0xffffd
    80003a56:	af6080e7          	jalr	-1290(ra) # 80000548 <panic>

0000000080003a5a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a5a:	7179                	addi	sp,sp,-48
    80003a5c:	f406                	sd	ra,40(sp)
    80003a5e:	f022                	sd	s0,32(sp)
    80003a60:	ec26                	sd	s1,24(sp)
    80003a62:	e84a                	sd	s2,16(sp)
    80003a64:	e44e                	sd	s3,8(sp)
    80003a66:	e052                	sd	s4,0(sp)
    80003a68:	1800                	addi	s0,sp,48
    80003a6a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a6c:	05050493          	addi	s1,a0,80
    80003a70:	08050913          	addi	s2,a0,128
    80003a74:	a021                	j	80003a7c <itrunc+0x22>
    80003a76:	0491                	addi	s1,s1,4
    80003a78:	01248d63          	beq	s1,s2,80003a92 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a7c:	408c                	lw	a1,0(s1)
    80003a7e:	dde5                	beqz	a1,80003a76 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a80:	0009a503          	lw	a0,0(s3)
    80003a84:	00000097          	auipc	ra,0x0
    80003a88:	90c080e7          	jalr	-1780(ra) # 80003390 <bfree>
      ip->addrs[i] = 0;
    80003a8c:	0004a023          	sw	zero,0(s1)
    80003a90:	b7dd                	j	80003a76 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a92:	0809a583          	lw	a1,128(s3)
    80003a96:	e185                	bnez	a1,80003ab6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a98:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a9c:	854e                	mv	a0,s3
    80003a9e:	00000097          	auipc	ra,0x0
    80003aa2:	de4080e7          	jalr	-540(ra) # 80003882 <iupdate>
}
    80003aa6:	70a2                	ld	ra,40(sp)
    80003aa8:	7402                	ld	s0,32(sp)
    80003aaa:	64e2                	ld	s1,24(sp)
    80003aac:	6942                	ld	s2,16(sp)
    80003aae:	69a2                	ld	s3,8(sp)
    80003ab0:	6a02                	ld	s4,0(sp)
    80003ab2:	6145                	addi	sp,sp,48
    80003ab4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ab6:	0009a503          	lw	a0,0(s3)
    80003aba:	fffff097          	auipc	ra,0xfffff
    80003abe:	690080e7          	jalr	1680(ra) # 8000314a <bread>
    80003ac2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ac4:	05850493          	addi	s1,a0,88
    80003ac8:	45850913          	addi	s2,a0,1112
    80003acc:	a811                	j	80003ae0 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003ace:	0009a503          	lw	a0,0(s3)
    80003ad2:	00000097          	auipc	ra,0x0
    80003ad6:	8be080e7          	jalr	-1858(ra) # 80003390 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003ada:	0491                	addi	s1,s1,4
    80003adc:	01248563          	beq	s1,s2,80003ae6 <itrunc+0x8c>
      if(a[j])
    80003ae0:	408c                	lw	a1,0(s1)
    80003ae2:	dde5                	beqz	a1,80003ada <itrunc+0x80>
    80003ae4:	b7ed                	j	80003ace <itrunc+0x74>
    brelse(bp);
    80003ae6:	8552                	mv	a0,s4
    80003ae8:	fffff097          	auipc	ra,0xfffff
    80003aec:	792080e7          	jalr	1938(ra) # 8000327a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003af0:	0809a583          	lw	a1,128(s3)
    80003af4:	0009a503          	lw	a0,0(s3)
    80003af8:	00000097          	auipc	ra,0x0
    80003afc:	898080e7          	jalr	-1896(ra) # 80003390 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b00:	0809a023          	sw	zero,128(s3)
    80003b04:	bf51                	j	80003a98 <itrunc+0x3e>

0000000080003b06 <iput>:
{
    80003b06:	1101                	addi	sp,sp,-32
    80003b08:	ec06                	sd	ra,24(sp)
    80003b0a:	e822                	sd	s0,16(sp)
    80003b0c:	e426                	sd	s1,8(sp)
    80003b0e:	e04a                	sd	s2,0(sp)
    80003b10:	1000                	addi	s0,sp,32
    80003b12:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b14:	0001c517          	auipc	a0,0x1c
    80003b18:	54c50513          	addi	a0,a0,1356 # 80020060 <icache>
    80003b1c:	ffffd097          	auipc	ra,0xffffd
    80003b20:	0f4080e7          	jalr	244(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b24:	4498                	lw	a4,8(s1)
    80003b26:	4785                	li	a5,1
    80003b28:	02f70363          	beq	a4,a5,80003b4e <iput+0x48>
  ip->ref--;
    80003b2c:	449c                	lw	a5,8(s1)
    80003b2e:	37fd                	addiw	a5,a5,-1
    80003b30:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b32:	0001c517          	auipc	a0,0x1c
    80003b36:	52e50513          	addi	a0,a0,1326 # 80020060 <icache>
    80003b3a:	ffffd097          	auipc	ra,0xffffd
    80003b3e:	18a080e7          	jalr	394(ra) # 80000cc4 <release>
}
    80003b42:	60e2                	ld	ra,24(sp)
    80003b44:	6442                	ld	s0,16(sp)
    80003b46:	64a2                	ld	s1,8(sp)
    80003b48:	6902                	ld	s2,0(sp)
    80003b4a:	6105                	addi	sp,sp,32
    80003b4c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b4e:	40bc                	lw	a5,64(s1)
    80003b50:	dff1                	beqz	a5,80003b2c <iput+0x26>
    80003b52:	04a49783          	lh	a5,74(s1)
    80003b56:	fbf9                	bnez	a5,80003b2c <iput+0x26>
    acquiresleep(&ip->lock);
    80003b58:	01048913          	addi	s2,s1,16
    80003b5c:	854a                	mv	a0,s2
    80003b5e:	00001097          	auipc	ra,0x1
    80003b62:	aa8080e7          	jalr	-1368(ra) # 80004606 <acquiresleep>
    release(&icache.lock);
    80003b66:	0001c517          	auipc	a0,0x1c
    80003b6a:	4fa50513          	addi	a0,a0,1274 # 80020060 <icache>
    80003b6e:	ffffd097          	auipc	ra,0xffffd
    80003b72:	156080e7          	jalr	342(ra) # 80000cc4 <release>
    itrunc(ip);
    80003b76:	8526                	mv	a0,s1
    80003b78:	00000097          	auipc	ra,0x0
    80003b7c:	ee2080e7          	jalr	-286(ra) # 80003a5a <itrunc>
    ip->type = 0;
    80003b80:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b84:	8526                	mv	a0,s1
    80003b86:	00000097          	auipc	ra,0x0
    80003b8a:	cfc080e7          	jalr	-772(ra) # 80003882 <iupdate>
    ip->valid = 0;
    80003b8e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b92:	854a                	mv	a0,s2
    80003b94:	00001097          	auipc	ra,0x1
    80003b98:	ac8080e7          	jalr	-1336(ra) # 8000465c <releasesleep>
    acquire(&icache.lock);
    80003b9c:	0001c517          	auipc	a0,0x1c
    80003ba0:	4c450513          	addi	a0,a0,1220 # 80020060 <icache>
    80003ba4:	ffffd097          	auipc	ra,0xffffd
    80003ba8:	06c080e7          	jalr	108(ra) # 80000c10 <acquire>
    80003bac:	b741                	j	80003b2c <iput+0x26>

0000000080003bae <iunlockput>:
{
    80003bae:	1101                	addi	sp,sp,-32
    80003bb0:	ec06                	sd	ra,24(sp)
    80003bb2:	e822                	sd	s0,16(sp)
    80003bb4:	e426                	sd	s1,8(sp)
    80003bb6:	1000                	addi	s0,sp,32
    80003bb8:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bba:	00000097          	auipc	ra,0x0
    80003bbe:	e54080e7          	jalr	-428(ra) # 80003a0e <iunlock>
  iput(ip);
    80003bc2:	8526                	mv	a0,s1
    80003bc4:	00000097          	auipc	ra,0x0
    80003bc8:	f42080e7          	jalr	-190(ra) # 80003b06 <iput>
}
    80003bcc:	60e2                	ld	ra,24(sp)
    80003bce:	6442                	ld	s0,16(sp)
    80003bd0:	64a2                	ld	s1,8(sp)
    80003bd2:	6105                	addi	sp,sp,32
    80003bd4:	8082                	ret

0000000080003bd6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bd6:	1141                	addi	sp,sp,-16
    80003bd8:	e422                	sd	s0,8(sp)
    80003bda:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bdc:	411c                	lw	a5,0(a0)
    80003bde:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003be0:	415c                	lw	a5,4(a0)
    80003be2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003be4:	04451783          	lh	a5,68(a0)
    80003be8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bec:	04a51783          	lh	a5,74(a0)
    80003bf0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003bf4:	04c56783          	lwu	a5,76(a0)
    80003bf8:	e99c                	sd	a5,16(a1)
}
    80003bfa:	6422                	ld	s0,8(sp)
    80003bfc:	0141                	addi	sp,sp,16
    80003bfe:	8082                	ret

0000000080003c00 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c00:	457c                	lw	a5,76(a0)
    80003c02:	0ed7e863          	bltu	a5,a3,80003cf2 <readi+0xf2>
{
    80003c06:	7159                	addi	sp,sp,-112
    80003c08:	f486                	sd	ra,104(sp)
    80003c0a:	f0a2                	sd	s0,96(sp)
    80003c0c:	eca6                	sd	s1,88(sp)
    80003c0e:	e8ca                	sd	s2,80(sp)
    80003c10:	e4ce                	sd	s3,72(sp)
    80003c12:	e0d2                	sd	s4,64(sp)
    80003c14:	fc56                	sd	s5,56(sp)
    80003c16:	f85a                	sd	s6,48(sp)
    80003c18:	f45e                	sd	s7,40(sp)
    80003c1a:	f062                	sd	s8,32(sp)
    80003c1c:	ec66                	sd	s9,24(sp)
    80003c1e:	e86a                	sd	s10,16(sp)
    80003c20:	e46e                	sd	s11,8(sp)
    80003c22:	1880                	addi	s0,sp,112
    80003c24:	8baa                	mv	s7,a0
    80003c26:	8c2e                	mv	s8,a1
    80003c28:	8ab2                	mv	s5,a2
    80003c2a:	84b6                	mv	s1,a3
    80003c2c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c2e:	9f35                	addw	a4,a4,a3
    return 0;
    80003c30:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c32:	08d76f63          	bltu	a4,a3,80003cd0 <readi+0xd0>
  if(off + n > ip->size)
    80003c36:	00e7f463          	bgeu	a5,a4,80003c3e <readi+0x3e>
    n = ip->size - off;
    80003c3a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c3e:	0a0b0863          	beqz	s6,80003cee <readi+0xee>
    80003c42:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c44:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c48:	5cfd                	li	s9,-1
    80003c4a:	a82d                	j	80003c84 <readi+0x84>
    80003c4c:	020a1d93          	slli	s11,s4,0x20
    80003c50:	020ddd93          	srli	s11,s11,0x20
    80003c54:	05890613          	addi	a2,s2,88
    80003c58:	86ee                	mv	a3,s11
    80003c5a:	963a                	add	a2,a2,a4
    80003c5c:	85d6                	mv	a1,s5
    80003c5e:	8562                	mv	a0,s8
    80003c60:	fffff097          	auipc	ra,0xfffff
    80003c64:	b2e080e7          	jalr	-1234(ra) # 8000278e <either_copyout>
    80003c68:	05950d63          	beq	a0,s9,80003cc2 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003c6c:	854a                	mv	a0,s2
    80003c6e:	fffff097          	auipc	ra,0xfffff
    80003c72:	60c080e7          	jalr	1548(ra) # 8000327a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c76:	013a09bb          	addw	s3,s4,s3
    80003c7a:	009a04bb          	addw	s1,s4,s1
    80003c7e:	9aee                	add	s5,s5,s11
    80003c80:	0569f663          	bgeu	s3,s6,80003ccc <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c84:	000ba903          	lw	s2,0(s7)
    80003c88:	00a4d59b          	srliw	a1,s1,0xa
    80003c8c:	855e                	mv	a0,s7
    80003c8e:	00000097          	auipc	ra,0x0
    80003c92:	8b0080e7          	jalr	-1872(ra) # 8000353e <bmap>
    80003c96:	0005059b          	sext.w	a1,a0
    80003c9a:	854a                	mv	a0,s2
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	4ae080e7          	jalr	1198(ra) # 8000314a <bread>
    80003ca4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ca6:	3ff4f713          	andi	a4,s1,1023
    80003caa:	40ed07bb          	subw	a5,s10,a4
    80003cae:	413b06bb          	subw	a3,s6,s3
    80003cb2:	8a3e                	mv	s4,a5
    80003cb4:	2781                	sext.w	a5,a5
    80003cb6:	0006861b          	sext.w	a2,a3
    80003cba:	f8f679e3          	bgeu	a2,a5,80003c4c <readi+0x4c>
    80003cbe:	8a36                	mv	s4,a3
    80003cc0:	b771                	j	80003c4c <readi+0x4c>
      brelse(bp);
    80003cc2:	854a                	mv	a0,s2
    80003cc4:	fffff097          	auipc	ra,0xfffff
    80003cc8:	5b6080e7          	jalr	1462(ra) # 8000327a <brelse>
  }
  return tot;
    80003ccc:	0009851b          	sext.w	a0,s3
}
    80003cd0:	70a6                	ld	ra,104(sp)
    80003cd2:	7406                	ld	s0,96(sp)
    80003cd4:	64e6                	ld	s1,88(sp)
    80003cd6:	6946                	ld	s2,80(sp)
    80003cd8:	69a6                	ld	s3,72(sp)
    80003cda:	6a06                	ld	s4,64(sp)
    80003cdc:	7ae2                	ld	s5,56(sp)
    80003cde:	7b42                	ld	s6,48(sp)
    80003ce0:	7ba2                	ld	s7,40(sp)
    80003ce2:	7c02                	ld	s8,32(sp)
    80003ce4:	6ce2                	ld	s9,24(sp)
    80003ce6:	6d42                	ld	s10,16(sp)
    80003ce8:	6da2                	ld	s11,8(sp)
    80003cea:	6165                	addi	sp,sp,112
    80003cec:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cee:	89da                	mv	s3,s6
    80003cf0:	bff1                	j	80003ccc <readi+0xcc>
    return 0;
    80003cf2:	4501                	li	a0,0
}
    80003cf4:	8082                	ret

0000000080003cf6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cf6:	457c                	lw	a5,76(a0)
    80003cf8:	10d7e663          	bltu	a5,a3,80003e04 <writei+0x10e>
{
    80003cfc:	7159                	addi	sp,sp,-112
    80003cfe:	f486                	sd	ra,104(sp)
    80003d00:	f0a2                	sd	s0,96(sp)
    80003d02:	eca6                	sd	s1,88(sp)
    80003d04:	e8ca                	sd	s2,80(sp)
    80003d06:	e4ce                	sd	s3,72(sp)
    80003d08:	e0d2                	sd	s4,64(sp)
    80003d0a:	fc56                	sd	s5,56(sp)
    80003d0c:	f85a                	sd	s6,48(sp)
    80003d0e:	f45e                	sd	s7,40(sp)
    80003d10:	f062                	sd	s8,32(sp)
    80003d12:	ec66                	sd	s9,24(sp)
    80003d14:	e86a                	sd	s10,16(sp)
    80003d16:	e46e                	sd	s11,8(sp)
    80003d18:	1880                	addi	s0,sp,112
    80003d1a:	8baa                	mv	s7,a0
    80003d1c:	8c2e                	mv	s8,a1
    80003d1e:	8ab2                	mv	s5,a2
    80003d20:	8936                	mv	s2,a3
    80003d22:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d24:	00e687bb          	addw	a5,a3,a4
    80003d28:	0ed7e063          	bltu	a5,a3,80003e08 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d2c:	00043737          	lui	a4,0x43
    80003d30:	0cf76e63          	bltu	a4,a5,80003e0c <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d34:	0a0b0763          	beqz	s6,80003de2 <writei+0xec>
    80003d38:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d3a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d3e:	5cfd                	li	s9,-1
    80003d40:	a091                	j	80003d84 <writei+0x8e>
    80003d42:	02099d93          	slli	s11,s3,0x20
    80003d46:	020ddd93          	srli	s11,s11,0x20
    80003d4a:	05848513          	addi	a0,s1,88
    80003d4e:	86ee                	mv	a3,s11
    80003d50:	8656                	mv	a2,s5
    80003d52:	85e2                	mv	a1,s8
    80003d54:	953a                	add	a0,a0,a4
    80003d56:	fffff097          	auipc	ra,0xfffff
    80003d5a:	a8e080e7          	jalr	-1394(ra) # 800027e4 <either_copyin>
    80003d5e:	07950263          	beq	a0,s9,80003dc2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d62:	8526                	mv	a0,s1
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	77a080e7          	jalr	1914(ra) # 800044de <log_write>
    brelse(bp);
    80003d6c:	8526                	mv	a0,s1
    80003d6e:	fffff097          	auipc	ra,0xfffff
    80003d72:	50c080e7          	jalr	1292(ra) # 8000327a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d76:	01498a3b          	addw	s4,s3,s4
    80003d7a:	0129893b          	addw	s2,s3,s2
    80003d7e:	9aee                	add	s5,s5,s11
    80003d80:	056a7663          	bgeu	s4,s6,80003dcc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d84:	000ba483          	lw	s1,0(s7)
    80003d88:	00a9559b          	srliw	a1,s2,0xa
    80003d8c:	855e                	mv	a0,s7
    80003d8e:	fffff097          	auipc	ra,0xfffff
    80003d92:	7b0080e7          	jalr	1968(ra) # 8000353e <bmap>
    80003d96:	0005059b          	sext.w	a1,a0
    80003d9a:	8526                	mv	a0,s1
    80003d9c:	fffff097          	auipc	ra,0xfffff
    80003da0:	3ae080e7          	jalr	942(ra) # 8000314a <bread>
    80003da4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003da6:	3ff97713          	andi	a4,s2,1023
    80003daa:	40ed07bb          	subw	a5,s10,a4
    80003dae:	414b06bb          	subw	a3,s6,s4
    80003db2:	89be                	mv	s3,a5
    80003db4:	2781                	sext.w	a5,a5
    80003db6:	0006861b          	sext.w	a2,a3
    80003dba:	f8f674e3          	bgeu	a2,a5,80003d42 <writei+0x4c>
    80003dbe:	89b6                	mv	s3,a3
    80003dc0:	b749                	j	80003d42 <writei+0x4c>
      brelse(bp);
    80003dc2:	8526                	mv	a0,s1
    80003dc4:	fffff097          	auipc	ra,0xfffff
    80003dc8:	4b6080e7          	jalr	1206(ra) # 8000327a <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003dcc:	04cba783          	lw	a5,76(s7)
    80003dd0:	0127f463          	bgeu	a5,s2,80003dd8 <writei+0xe2>
      ip->size = off;
    80003dd4:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003dd8:	855e                	mv	a0,s7
    80003dda:	00000097          	auipc	ra,0x0
    80003dde:	aa8080e7          	jalr	-1368(ra) # 80003882 <iupdate>
  }

  return n;
    80003de2:	000b051b          	sext.w	a0,s6
}
    80003de6:	70a6                	ld	ra,104(sp)
    80003de8:	7406                	ld	s0,96(sp)
    80003dea:	64e6                	ld	s1,88(sp)
    80003dec:	6946                	ld	s2,80(sp)
    80003dee:	69a6                	ld	s3,72(sp)
    80003df0:	6a06                	ld	s4,64(sp)
    80003df2:	7ae2                	ld	s5,56(sp)
    80003df4:	7b42                	ld	s6,48(sp)
    80003df6:	7ba2                	ld	s7,40(sp)
    80003df8:	7c02                	ld	s8,32(sp)
    80003dfa:	6ce2                	ld	s9,24(sp)
    80003dfc:	6d42                	ld	s10,16(sp)
    80003dfe:	6da2                	ld	s11,8(sp)
    80003e00:	6165                	addi	sp,sp,112
    80003e02:	8082                	ret
    return -1;
    80003e04:	557d                	li	a0,-1
}
    80003e06:	8082                	ret
    return -1;
    80003e08:	557d                	li	a0,-1
    80003e0a:	bff1                	j	80003de6 <writei+0xf0>
    return -1;
    80003e0c:	557d                	li	a0,-1
    80003e0e:	bfe1                	j	80003de6 <writei+0xf0>

0000000080003e10 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e10:	1141                	addi	sp,sp,-16
    80003e12:	e406                	sd	ra,8(sp)
    80003e14:	e022                	sd	s0,0(sp)
    80003e16:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e18:	4639                	li	a2,14
    80003e1a:	ffffd097          	auipc	ra,0xffffd
    80003e1e:	fce080e7          	jalr	-50(ra) # 80000de8 <strncmp>
}
    80003e22:	60a2                	ld	ra,8(sp)
    80003e24:	6402                	ld	s0,0(sp)
    80003e26:	0141                	addi	sp,sp,16
    80003e28:	8082                	ret

0000000080003e2a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e2a:	7139                	addi	sp,sp,-64
    80003e2c:	fc06                	sd	ra,56(sp)
    80003e2e:	f822                	sd	s0,48(sp)
    80003e30:	f426                	sd	s1,40(sp)
    80003e32:	f04a                	sd	s2,32(sp)
    80003e34:	ec4e                	sd	s3,24(sp)
    80003e36:	e852                	sd	s4,16(sp)
    80003e38:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e3a:	04451703          	lh	a4,68(a0)
    80003e3e:	4785                	li	a5,1
    80003e40:	00f71a63          	bne	a4,a5,80003e54 <dirlookup+0x2a>
    80003e44:	892a                	mv	s2,a0
    80003e46:	89ae                	mv	s3,a1
    80003e48:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e4a:	457c                	lw	a5,76(a0)
    80003e4c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e4e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e50:	e79d                	bnez	a5,80003e7e <dirlookup+0x54>
    80003e52:	a8a5                	j	80003eca <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e54:	00004517          	auipc	a0,0x4
    80003e58:	7fc50513          	addi	a0,a0,2044 # 80008650 <syscalls+0x1a0>
    80003e5c:	ffffc097          	auipc	ra,0xffffc
    80003e60:	6ec080e7          	jalr	1772(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003e64:	00005517          	auipc	a0,0x5
    80003e68:	80450513          	addi	a0,a0,-2044 # 80008668 <syscalls+0x1b8>
    80003e6c:	ffffc097          	auipc	ra,0xffffc
    80003e70:	6dc080e7          	jalr	1756(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e74:	24c1                	addiw	s1,s1,16
    80003e76:	04c92783          	lw	a5,76(s2)
    80003e7a:	04f4f763          	bgeu	s1,a5,80003ec8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e7e:	4741                	li	a4,16
    80003e80:	86a6                	mv	a3,s1
    80003e82:	fc040613          	addi	a2,s0,-64
    80003e86:	4581                	li	a1,0
    80003e88:	854a                	mv	a0,s2
    80003e8a:	00000097          	auipc	ra,0x0
    80003e8e:	d76080e7          	jalr	-650(ra) # 80003c00 <readi>
    80003e92:	47c1                	li	a5,16
    80003e94:	fcf518e3          	bne	a0,a5,80003e64 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e98:	fc045783          	lhu	a5,-64(s0)
    80003e9c:	dfe1                	beqz	a5,80003e74 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e9e:	fc240593          	addi	a1,s0,-62
    80003ea2:	854e                	mv	a0,s3
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	f6c080e7          	jalr	-148(ra) # 80003e10 <namecmp>
    80003eac:	f561                	bnez	a0,80003e74 <dirlookup+0x4a>
      if(poff)
    80003eae:	000a0463          	beqz	s4,80003eb6 <dirlookup+0x8c>
        *poff = off;
    80003eb2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003eb6:	fc045583          	lhu	a1,-64(s0)
    80003eba:	00092503          	lw	a0,0(s2)
    80003ebe:	fffff097          	auipc	ra,0xfffff
    80003ec2:	75a080e7          	jalr	1882(ra) # 80003618 <iget>
    80003ec6:	a011                	j	80003eca <dirlookup+0xa0>
  return 0;
    80003ec8:	4501                	li	a0,0
}
    80003eca:	70e2                	ld	ra,56(sp)
    80003ecc:	7442                	ld	s0,48(sp)
    80003ece:	74a2                	ld	s1,40(sp)
    80003ed0:	7902                	ld	s2,32(sp)
    80003ed2:	69e2                	ld	s3,24(sp)
    80003ed4:	6a42                	ld	s4,16(sp)
    80003ed6:	6121                	addi	sp,sp,64
    80003ed8:	8082                	ret

0000000080003eda <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003eda:	711d                	addi	sp,sp,-96
    80003edc:	ec86                	sd	ra,88(sp)
    80003ede:	e8a2                	sd	s0,80(sp)
    80003ee0:	e4a6                	sd	s1,72(sp)
    80003ee2:	e0ca                	sd	s2,64(sp)
    80003ee4:	fc4e                	sd	s3,56(sp)
    80003ee6:	f852                	sd	s4,48(sp)
    80003ee8:	f456                	sd	s5,40(sp)
    80003eea:	f05a                	sd	s6,32(sp)
    80003eec:	ec5e                	sd	s7,24(sp)
    80003eee:	e862                	sd	s8,16(sp)
    80003ef0:	e466                	sd	s9,8(sp)
    80003ef2:	1080                	addi	s0,sp,96
    80003ef4:	84aa                	mv	s1,a0
    80003ef6:	8b2e                	mv	s6,a1
    80003ef8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003efa:	00054703          	lbu	a4,0(a0)
    80003efe:	02f00793          	li	a5,47
    80003f02:	02f70363          	beq	a4,a5,80003f28 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f06:	ffffe097          	auipc	ra,0xffffe
    80003f0a:	c18080e7          	jalr	-1000(ra) # 80001b1e <myproc>
    80003f0e:	15853503          	ld	a0,344(a0)
    80003f12:	00000097          	auipc	ra,0x0
    80003f16:	9fc080e7          	jalr	-1540(ra) # 8000390e <idup>
    80003f1a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f1c:	02f00913          	li	s2,47
  len = path - s;
    80003f20:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f22:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f24:	4c05                	li	s8,1
    80003f26:	a865                	j	80003fde <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f28:	4585                	li	a1,1
    80003f2a:	4505                	li	a0,1
    80003f2c:	fffff097          	auipc	ra,0xfffff
    80003f30:	6ec080e7          	jalr	1772(ra) # 80003618 <iget>
    80003f34:	89aa                	mv	s3,a0
    80003f36:	b7dd                	j	80003f1c <namex+0x42>
      iunlockput(ip);
    80003f38:	854e                	mv	a0,s3
    80003f3a:	00000097          	auipc	ra,0x0
    80003f3e:	c74080e7          	jalr	-908(ra) # 80003bae <iunlockput>
      return 0;
    80003f42:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f44:	854e                	mv	a0,s3
    80003f46:	60e6                	ld	ra,88(sp)
    80003f48:	6446                	ld	s0,80(sp)
    80003f4a:	64a6                	ld	s1,72(sp)
    80003f4c:	6906                	ld	s2,64(sp)
    80003f4e:	79e2                	ld	s3,56(sp)
    80003f50:	7a42                	ld	s4,48(sp)
    80003f52:	7aa2                	ld	s5,40(sp)
    80003f54:	7b02                	ld	s6,32(sp)
    80003f56:	6be2                	ld	s7,24(sp)
    80003f58:	6c42                	ld	s8,16(sp)
    80003f5a:	6ca2                	ld	s9,8(sp)
    80003f5c:	6125                	addi	sp,sp,96
    80003f5e:	8082                	ret
      iunlock(ip);
    80003f60:	854e                	mv	a0,s3
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	aac080e7          	jalr	-1364(ra) # 80003a0e <iunlock>
      return ip;
    80003f6a:	bfe9                	j	80003f44 <namex+0x6a>
      iunlockput(ip);
    80003f6c:	854e                	mv	a0,s3
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	c40080e7          	jalr	-960(ra) # 80003bae <iunlockput>
      return 0;
    80003f76:	89d2                	mv	s3,s4
    80003f78:	b7f1                	j	80003f44 <namex+0x6a>
  len = path - s;
    80003f7a:	40b48633          	sub	a2,s1,a1
    80003f7e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f82:	094cd463          	bge	s9,s4,8000400a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f86:	4639                	li	a2,14
    80003f88:	8556                	mv	a0,s5
    80003f8a:	ffffd097          	auipc	ra,0xffffd
    80003f8e:	de2080e7          	jalr	-542(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003f92:	0004c783          	lbu	a5,0(s1)
    80003f96:	01279763          	bne	a5,s2,80003fa4 <namex+0xca>
    path++;
    80003f9a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f9c:	0004c783          	lbu	a5,0(s1)
    80003fa0:	ff278de3          	beq	a5,s2,80003f9a <namex+0xc0>
    ilock(ip);
    80003fa4:	854e                	mv	a0,s3
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	9a6080e7          	jalr	-1626(ra) # 8000394c <ilock>
    if(ip->type != T_DIR){
    80003fae:	04499783          	lh	a5,68(s3)
    80003fb2:	f98793e3          	bne	a5,s8,80003f38 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fb6:	000b0563          	beqz	s6,80003fc0 <namex+0xe6>
    80003fba:	0004c783          	lbu	a5,0(s1)
    80003fbe:	d3cd                	beqz	a5,80003f60 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fc0:	865e                	mv	a2,s7
    80003fc2:	85d6                	mv	a1,s5
    80003fc4:	854e                	mv	a0,s3
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	e64080e7          	jalr	-412(ra) # 80003e2a <dirlookup>
    80003fce:	8a2a                	mv	s4,a0
    80003fd0:	dd51                	beqz	a0,80003f6c <namex+0x92>
    iunlockput(ip);
    80003fd2:	854e                	mv	a0,s3
    80003fd4:	00000097          	auipc	ra,0x0
    80003fd8:	bda080e7          	jalr	-1062(ra) # 80003bae <iunlockput>
    ip = next;
    80003fdc:	89d2                	mv	s3,s4
  while(*path == '/')
    80003fde:	0004c783          	lbu	a5,0(s1)
    80003fe2:	05279763          	bne	a5,s2,80004030 <namex+0x156>
    path++;
    80003fe6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fe8:	0004c783          	lbu	a5,0(s1)
    80003fec:	ff278de3          	beq	a5,s2,80003fe6 <namex+0x10c>
  if(*path == 0)
    80003ff0:	c79d                	beqz	a5,8000401e <namex+0x144>
    path++;
    80003ff2:	85a6                	mv	a1,s1
  len = path - s;
    80003ff4:	8a5e                	mv	s4,s7
    80003ff6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ff8:	01278963          	beq	a5,s2,8000400a <namex+0x130>
    80003ffc:	dfbd                	beqz	a5,80003f7a <namex+0xa0>
    path++;
    80003ffe:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004000:	0004c783          	lbu	a5,0(s1)
    80004004:	ff279ce3          	bne	a5,s2,80003ffc <namex+0x122>
    80004008:	bf8d                	j	80003f7a <namex+0xa0>
    memmove(name, s, len);
    8000400a:	2601                	sext.w	a2,a2
    8000400c:	8556                	mv	a0,s5
    8000400e:	ffffd097          	auipc	ra,0xffffd
    80004012:	d5e080e7          	jalr	-674(ra) # 80000d6c <memmove>
    name[len] = 0;
    80004016:	9a56                	add	s4,s4,s5
    80004018:	000a0023          	sb	zero,0(s4)
    8000401c:	bf9d                	j	80003f92 <namex+0xb8>
  if(nameiparent){
    8000401e:	f20b03e3          	beqz	s6,80003f44 <namex+0x6a>
    iput(ip);
    80004022:	854e                	mv	a0,s3
    80004024:	00000097          	auipc	ra,0x0
    80004028:	ae2080e7          	jalr	-1310(ra) # 80003b06 <iput>
    return 0;
    8000402c:	4981                	li	s3,0
    8000402e:	bf19                	j	80003f44 <namex+0x6a>
  if(*path == 0)
    80004030:	d7fd                	beqz	a5,8000401e <namex+0x144>
  while(*path != '/' && *path != 0)
    80004032:	0004c783          	lbu	a5,0(s1)
    80004036:	85a6                	mv	a1,s1
    80004038:	b7d1                	j	80003ffc <namex+0x122>

000000008000403a <dirlink>:
{
    8000403a:	7139                	addi	sp,sp,-64
    8000403c:	fc06                	sd	ra,56(sp)
    8000403e:	f822                	sd	s0,48(sp)
    80004040:	f426                	sd	s1,40(sp)
    80004042:	f04a                	sd	s2,32(sp)
    80004044:	ec4e                	sd	s3,24(sp)
    80004046:	e852                	sd	s4,16(sp)
    80004048:	0080                	addi	s0,sp,64
    8000404a:	892a                	mv	s2,a0
    8000404c:	8a2e                	mv	s4,a1
    8000404e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004050:	4601                	li	a2,0
    80004052:	00000097          	auipc	ra,0x0
    80004056:	dd8080e7          	jalr	-552(ra) # 80003e2a <dirlookup>
    8000405a:	e93d                	bnez	a0,800040d0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000405c:	04c92483          	lw	s1,76(s2)
    80004060:	c49d                	beqz	s1,8000408e <dirlink+0x54>
    80004062:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004064:	4741                	li	a4,16
    80004066:	86a6                	mv	a3,s1
    80004068:	fc040613          	addi	a2,s0,-64
    8000406c:	4581                	li	a1,0
    8000406e:	854a                	mv	a0,s2
    80004070:	00000097          	auipc	ra,0x0
    80004074:	b90080e7          	jalr	-1136(ra) # 80003c00 <readi>
    80004078:	47c1                	li	a5,16
    8000407a:	06f51163          	bne	a0,a5,800040dc <dirlink+0xa2>
    if(de.inum == 0)
    8000407e:	fc045783          	lhu	a5,-64(s0)
    80004082:	c791                	beqz	a5,8000408e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004084:	24c1                	addiw	s1,s1,16
    80004086:	04c92783          	lw	a5,76(s2)
    8000408a:	fcf4ede3          	bltu	s1,a5,80004064 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000408e:	4639                	li	a2,14
    80004090:	85d2                	mv	a1,s4
    80004092:	fc240513          	addi	a0,s0,-62
    80004096:	ffffd097          	auipc	ra,0xffffd
    8000409a:	d8e080e7          	jalr	-626(ra) # 80000e24 <strncpy>
  de.inum = inum;
    8000409e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040a2:	4741                	li	a4,16
    800040a4:	86a6                	mv	a3,s1
    800040a6:	fc040613          	addi	a2,s0,-64
    800040aa:	4581                	li	a1,0
    800040ac:	854a                	mv	a0,s2
    800040ae:	00000097          	auipc	ra,0x0
    800040b2:	c48080e7          	jalr	-952(ra) # 80003cf6 <writei>
    800040b6:	872a                	mv	a4,a0
    800040b8:	47c1                	li	a5,16
  return 0;
    800040ba:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040bc:	02f71863          	bne	a4,a5,800040ec <dirlink+0xb2>
}
    800040c0:	70e2                	ld	ra,56(sp)
    800040c2:	7442                	ld	s0,48(sp)
    800040c4:	74a2                	ld	s1,40(sp)
    800040c6:	7902                	ld	s2,32(sp)
    800040c8:	69e2                	ld	s3,24(sp)
    800040ca:	6a42                	ld	s4,16(sp)
    800040cc:	6121                	addi	sp,sp,64
    800040ce:	8082                	ret
    iput(ip);
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	a36080e7          	jalr	-1482(ra) # 80003b06 <iput>
    return -1;
    800040d8:	557d                	li	a0,-1
    800040da:	b7dd                	j	800040c0 <dirlink+0x86>
      panic("dirlink read");
    800040dc:	00004517          	auipc	a0,0x4
    800040e0:	59c50513          	addi	a0,a0,1436 # 80008678 <syscalls+0x1c8>
    800040e4:	ffffc097          	auipc	ra,0xffffc
    800040e8:	464080e7          	jalr	1124(ra) # 80000548 <panic>
    panic("dirlink");
    800040ec:	00004517          	auipc	a0,0x4
    800040f0:	6a450513          	addi	a0,a0,1700 # 80008790 <syscalls+0x2e0>
    800040f4:	ffffc097          	auipc	ra,0xffffc
    800040f8:	454080e7          	jalr	1108(ra) # 80000548 <panic>

00000000800040fc <namei>:

struct inode*
namei(char *path)
{
    800040fc:	1101                	addi	sp,sp,-32
    800040fe:	ec06                	sd	ra,24(sp)
    80004100:	e822                	sd	s0,16(sp)
    80004102:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004104:	fe040613          	addi	a2,s0,-32
    80004108:	4581                	li	a1,0
    8000410a:	00000097          	auipc	ra,0x0
    8000410e:	dd0080e7          	jalr	-560(ra) # 80003eda <namex>
}
    80004112:	60e2                	ld	ra,24(sp)
    80004114:	6442                	ld	s0,16(sp)
    80004116:	6105                	addi	sp,sp,32
    80004118:	8082                	ret

000000008000411a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000411a:	1141                	addi	sp,sp,-16
    8000411c:	e406                	sd	ra,8(sp)
    8000411e:	e022                	sd	s0,0(sp)
    80004120:	0800                	addi	s0,sp,16
    80004122:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004124:	4585                	li	a1,1
    80004126:	00000097          	auipc	ra,0x0
    8000412a:	db4080e7          	jalr	-588(ra) # 80003eda <namex>
}
    8000412e:	60a2                	ld	ra,8(sp)
    80004130:	6402                	ld	s0,0(sp)
    80004132:	0141                	addi	sp,sp,16
    80004134:	8082                	ret

0000000080004136 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004136:	1101                	addi	sp,sp,-32
    80004138:	ec06                	sd	ra,24(sp)
    8000413a:	e822                	sd	s0,16(sp)
    8000413c:	e426                	sd	s1,8(sp)
    8000413e:	e04a                	sd	s2,0(sp)
    80004140:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004142:	0001e917          	auipc	s2,0x1e
    80004146:	9c690913          	addi	s2,s2,-1594 # 80021b08 <log>
    8000414a:	01892583          	lw	a1,24(s2)
    8000414e:	02892503          	lw	a0,40(s2)
    80004152:	fffff097          	auipc	ra,0xfffff
    80004156:	ff8080e7          	jalr	-8(ra) # 8000314a <bread>
    8000415a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000415c:	02c92683          	lw	a3,44(s2)
    80004160:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004162:	02d05763          	blez	a3,80004190 <write_head+0x5a>
    80004166:	0001e797          	auipc	a5,0x1e
    8000416a:	9d278793          	addi	a5,a5,-1582 # 80021b38 <log+0x30>
    8000416e:	05c50713          	addi	a4,a0,92
    80004172:	36fd                	addiw	a3,a3,-1
    80004174:	1682                	slli	a3,a3,0x20
    80004176:	9281                	srli	a3,a3,0x20
    80004178:	068a                	slli	a3,a3,0x2
    8000417a:	0001e617          	auipc	a2,0x1e
    8000417e:	9c260613          	addi	a2,a2,-1598 # 80021b3c <log+0x34>
    80004182:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004184:	4390                	lw	a2,0(a5)
    80004186:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004188:	0791                	addi	a5,a5,4
    8000418a:	0711                	addi	a4,a4,4
    8000418c:	fed79ce3          	bne	a5,a3,80004184 <write_head+0x4e>
  }
  bwrite(buf);
    80004190:	8526                	mv	a0,s1
    80004192:	fffff097          	auipc	ra,0xfffff
    80004196:	0aa080e7          	jalr	170(ra) # 8000323c <bwrite>
  brelse(buf);
    8000419a:	8526                	mv	a0,s1
    8000419c:	fffff097          	auipc	ra,0xfffff
    800041a0:	0de080e7          	jalr	222(ra) # 8000327a <brelse>
}
    800041a4:	60e2                	ld	ra,24(sp)
    800041a6:	6442                	ld	s0,16(sp)
    800041a8:	64a2                	ld	s1,8(sp)
    800041aa:	6902                	ld	s2,0(sp)
    800041ac:	6105                	addi	sp,sp,32
    800041ae:	8082                	ret

00000000800041b0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041b0:	0001e797          	auipc	a5,0x1e
    800041b4:	9847a783          	lw	a5,-1660(a5) # 80021b34 <log+0x2c>
    800041b8:	0af05663          	blez	a5,80004264 <install_trans+0xb4>
{
    800041bc:	7139                	addi	sp,sp,-64
    800041be:	fc06                	sd	ra,56(sp)
    800041c0:	f822                	sd	s0,48(sp)
    800041c2:	f426                	sd	s1,40(sp)
    800041c4:	f04a                	sd	s2,32(sp)
    800041c6:	ec4e                	sd	s3,24(sp)
    800041c8:	e852                	sd	s4,16(sp)
    800041ca:	e456                	sd	s5,8(sp)
    800041cc:	0080                	addi	s0,sp,64
    800041ce:	0001ea97          	auipc	s5,0x1e
    800041d2:	96aa8a93          	addi	s5,s5,-1686 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041d6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041d8:	0001e997          	auipc	s3,0x1e
    800041dc:	93098993          	addi	s3,s3,-1744 # 80021b08 <log>
    800041e0:	0189a583          	lw	a1,24(s3)
    800041e4:	014585bb          	addw	a1,a1,s4
    800041e8:	2585                	addiw	a1,a1,1
    800041ea:	0289a503          	lw	a0,40(s3)
    800041ee:	fffff097          	auipc	ra,0xfffff
    800041f2:	f5c080e7          	jalr	-164(ra) # 8000314a <bread>
    800041f6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041f8:	000aa583          	lw	a1,0(s5)
    800041fc:	0289a503          	lw	a0,40(s3)
    80004200:	fffff097          	auipc	ra,0xfffff
    80004204:	f4a080e7          	jalr	-182(ra) # 8000314a <bread>
    80004208:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000420a:	40000613          	li	a2,1024
    8000420e:	05890593          	addi	a1,s2,88
    80004212:	05850513          	addi	a0,a0,88
    80004216:	ffffd097          	auipc	ra,0xffffd
    8000421a:	b56080e7          	jalr	-1194(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    8000421e:	8526                	mv	a0,s1
    80004220:	fffff097          	auipc	ra,0xfffff
    80004224:	01c080e7          	jalr	28(ra) # 8000323c <bwrite>
    bunpin(dbuf);
    80004228:	8526                	mv	a0,s1
    8000422a:	fffff097          	auipc	ra,0xfffff
    8000422e:	12a080e7          	jalr	298(ra) # 80003354 <bunpin>
    brelse(lbuf);
    80004232:	854a                	mv	a0,s2
    80004234:	fffff097          	auipc	ra,0xfffff
    80004238:	046080e7          	jalr	70(ra) # 8000327a <brelse>
    brelse(dbuf);
    8000423c:	8526                	mv	a0,s1
    8000423e:	fffff097          	auipc	ra,0xfffff
    80004242:	03c080e7          	jalr	60(ra) # 8000327a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004246:	2a05                	addiw	s4,s4,1
    80004248:	0a91                	addi	s5,s5,4
    8000424a:	02c9a783          	lw	a5,44(s3)
    8000424e:	f8fa49e3          	blt	s4,a5,800041e0 <install_trans+0x30>
}
    80004252:	70e2                	ld	ra,56(sp)
    80004254:	7442                	ld	s0,48(sp)
    80004256:	74a2                	ld	s1,40(sp)
    80004258:	7902                	ld	s2,32(sp)
    8000425a:	69e2                	ld	s3,24(sp)
    8000425c:	6a42                	ld	s4,16(sp)
    8000425e:	6aa2                	ld	s5,8(sp)
    80004260:	6121                	addi	sp,sp,64
    80004262:	8082                	ret
    80004264:	8082                	ret

0000000080004266 <initlog>:
{
    80004266:	7179                	addi	sp,sp,-48
    80004268:	f406                	sd	ra,40(sp)
    8000426a:	f022                	sd	s0,32(sp)
    8000426c:	ec26                	sd	s1,24(sp)
    8000426e:	e84a                	sd	s2,16(sp)
    80004270:	e44e                	sd	s3,8(sp)
    80004272:	1800                	addi	s0,sp,48
    80004274:	892a                	mv	s2,a0
    80004276:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004278:	0001e497          	auipc	s1,0x1e
    8000427c:	89048493          	addi	s1,s1,-1904 # 80021b08 <log>
    80004280:	00004597          	auipc	a1,0x4
    80004284:	40858593          	addi	a1,a1,1032 # 80008688 <syscalls+0x1d8>
    80004288:	8526                	mv	a0,s1
    8000428a:	ffffd097          	auipc	ra,0xffffd
    8000428e:	8f6080e7          	jalr	-1802(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    80004292:	0149a583          	lw	a1,20(s3)
    80004296:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004298:	0109a783          	lw	a5,16(s3)
    8000429c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000429e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042a2:	854a                	mv	a0,s2
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	ea6080e7          	jalr	-346(ra) # 8000314a <bread>
  log.lh.n = lh->n;
    800042ac:	4d3c                	lw	a5,88(a0)
    800042ae:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042b0:	02f05563          	blez	a5,800042da <initlog+0x74>
    800042b4:	05c50713          	addi	a4,a0,92
    800042b8:	0001e697          	auipc	a3,0x1e
    800042bc:	88068693          	addi	a3,a3,-1920 # 80021b38 <log+0x30>
    800042c0:	37fd                	addiw	a5,a5,-1
    800042c2:	1782                	slli	a5,a5,0x20
    800042c4:	9381                	srli	a5,a5,0x20
    800042c6:	078a                	slli	a5,a5,0x2
    800042c8:	06050613          	addi	a2,a0,96
    800042cc:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800042ce:	4310                	lw	a2,0(a4)
    800042d0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800042d2:	0711                	addi	a4,a4,4
    800042d4:	0691                	addi	a3,a3,4
    800042d6:	fef71ce3          	bne	a4,a5,800042ce <initlog+0x68>
  brelse(buf);
    800042da:	fffff097          	auipc	ra,0xfffff
    800042de:	fa0080e7          	jalr	-96(ra) # 8000327a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800042e2:	00000097          	auipc	ra,0x0
    800042e6:	ece080e7          	jalr	-306(ra) # 800041b0 <install_trans>
  log.lh.n = 0;
    800042ea:	0001e797          	auipc	a5,0x1e
    800042ee:	8407a523          	sw	zero,-1974(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    800042f2:	00000097          	auipc	ra,0x0
    800042f6:	e44080e7          	jalr	-444(ra) # 80004136 <write_head>
}
    800042fa:	70a2                	ld	ra,40(sp)
    800042fc:	7402                	ld	s0,32(sp)
    800042fe:	64e2                	ld	s1,24(sp)
    80004300:	6942                	ld	s2,16(sp)
    80004302:	69a2                	ld	s3,8(sp)
    80004304:	6145                	addi	sp,sp,48
    80004306:	8082                	ret

0000000080004308 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004308:	1101                	addi	sp,sp,-32
    8000430a:	ec06                	sd	ra,24(sp)
    8000430c:	e822                	sd	s0,16(sp)
    8000430e:	e426                	sd	s1,8(sp)
    80004310:	e04a                	sd	s2,0(sp)
    80004312:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004314:	0001d517          	auipc	a0,0x1d
    80004318:	7f450513          	addi	a0,a0,2036 # 80021b08 <log>
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	8f4080e7          	jalr	-1804(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    80004324:	0001d497          	auipc	s1,0x1d
    80004328:	7e448493          	addi	s1,s1,2020 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000432c:	4979                	li	s2,30
    8000432e:	a039                	j	8000433c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004330:	85a6                	mv	a1,s1
    80004332:	8526                	mv	a0,s1
    80004334:	ffffe097          	auipc	ra,0xffffe
    80004338:	1f8080e7          	jalr	504(ra) # 8000252c <sleep>
    if(log.committing){
    8000433c:	50dc                	lw	a5,36(s1)
    8000433e:	fbed                	bnez	a5,80004330 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004340:	509c                	lw	a5,32(s1)
    80004342:	0017871b          	addiw	a4,a5,1
    80004346:	0007069b          	sext.w	a3,a4
    8000434a:	0027179b          	slliw	a5,a4,0x2
    8000434e:	9fb9                	addw	a5,a5,a4
    80004350:	0017979b          	slliw	a5,a5,0x1
    80004354:	54d8                	lw	a4,44(s1)
    80004356:	9fb9                	addw	a5,a5,a4
    80004358:	00f95963          	bge	s2,a5,8000436a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000435c:	85a6                	mv	a1,s1
    8000435e:	8526                	mv	a0,s1
    80004360:	ffffe097          	auipc	ra,0xffffe
    80004364:	1cc080e7          	jalr	460(ra) # 8000252c <sleep>
    80004368:	bfd1                	j	8000433c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000436a:	0001d517          	auipc	a0,0x1d
    8000436e:	79e50513          	addi	a0,a0,1950 # 80021b08 <log>
    80004372:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004374:	ffffd097          	auipc	ra,0xffffd
    80004378:	950080e7          	jalr	-1712(ra) # 80000cc4 <release>
      break;
    }
  }
}
    8000437c:	60e2                	ld	ra,24(sp)
    8000437e:	6442                	ld	s0,16(sp)
    80004380:	64a2                	ld	s1,8(sp)
    80004382:	6902                	ld	s2,0(sp)
    80004384:	6105                	addi	sp,sp,32
    80004386:	8082                	ret

0000000080004388 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004388:	7139                	addi	sp,sp,-64
    8000438a:	fc06                	sd	ra,56(sp)
    8000438c:	f822                	sd	s0,48(sp)
    8000438e:	f426                	sd	s1,40(sp)
    80004390:	f04a                	sd	s2,32(sp)
    80004392:	ec4e                	sd	s3,24(sp)
    80004394:	e852                	sd	s4,16(sp)
    80004396:	e456                	sd	s5,8(sp)
    80004398:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000439a:	0001d497          	auipc	s1,0x1d
    8000439e:	76e48493          	addi	s1,s1,1902 # 80021b08 <log>
    800043a2:	8526                	mv	a0,s1
    800043a4:	ffffd097          	auipc	ra,0xffffd
    800043a8:	86c080e7          	jalr	-1940(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    800043ac:	509c                	lw	a5,32(s1)
    800043ae:	37fd                	addiw	a5,a5,-1
    800043b0:	0007891b          	sext.w	s2,a5
    800043b4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043b6:	50dc                	lw	a5,36(s1)
    800043b8:	efb9                	bnez	a5,80004416 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043ba:	06091663          	bnez	s2,80004426 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043be:	0001d497          	auipc	s1,0x1d
    800043c2:	74a48493          	addi	s1,s1,1866 # 80021b08 <log>
    800043c6:	4785                	li	a5,1
    800043c8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043ca:	8526                	mv	a0,s1
    800043cc:	ffffd097          	auipc	ra,0xffffd
    800043d0:	8f8080e7          	jalr	-1800(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043d4:	54dc                	lw	a5,44(s1)
    800043d6:	06f04763          	bgtz	a5,80004444 <end_op+0xbc>
    acquire(&log.lock);
    800043da:	0001d497          	auipc	s1,0x1d
    800043de:	72e48493          	addi	s1,s1,1838 # 80021b08 <log>
    800043e2:	8526                	mv	a0,s1
    800043e4:	ffffd097          	auipc	ra,0xffffd
    800043e8:	82c080e7          	jalr	-2004(ra) # 80000c10 <acquire>
    log.committing = 0;
    800043ec:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043f0:	8526                	mv	a0,s1
    800043f2:	ffffe097          	auipc	ra,0xffffe
    800043f6:	2c0080e7          	jalr	704(ra) # 800026b2 <wakeup>
    release(&log.lock);
    800043fa:	8526                	mv	a0,s1
    800043fc:	ffffd097          	auipc	ra,0xffffd
    80004400:	8c8080e7          	jalr	-1848(ra) # 80000cc4 <release>
}
    80004404:	70e2                	ld	ra,56(sp)
    80004406:	7442                	ld	s0,48(sp)
    80004408:	74a2                	ld	s1,40(sp)
    8000440a:	7902                	ld	s2,32(sp)
    8000440c:	69e2                	ld	s3,24(sp)
    8000440e:	6a42                	ld	s4,16(sp)
    80004410:	6aa2                	ld	s5,8(sp)
    80004412:	6121                	addi	sp,sp,64
    80004414:	8082                	ret
    panic("log.committing");
    80004416:	00004517          	auipc	a0,0x4
    8000441a:	27a50513          	addi	a0,a0,634 # 80008690 <syscalls+0x1e0>
    8000441e:	ffffc097          	auipc	ra,0xffffc
    80004422:	12a080e7          	jalr	298(ra) # 80000548 <panic>
    wakeup(&log);
    80004426:	0001d497          	auipc	s1,0x1d
    8000442a:	6e248493          	addi	s1,s1,1762 # 80021b08 <log>
    8000442e:	8526                	mv	a0,s1
    80004430:	ffffe097          	auipc	ra,0xffffe
    80004434:	282080e7          	jalr	642(ra) # 800026b2 <wakeup>
  release(&log.lock);
    80004438:	8526                	mv	a0,s1
    8000443a:	ffffd097          	auipc	ra,0xffffd
    8000443e:	88a080e7          	jalr	-1910(ra) # 80000cc4 <release>
  if(do_commit){
    80004442:	b7c9                	j	80004404 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004444:	0001da97          	auipc	s5,0x1d
    80004448:	6f4a8a93          	addi	s5,s5,1780 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000444c:	0001da17          	auipc	s4,0x1d
    80004450:	6bca0a13          	addi	s4,s4,1724 # 80021b08 <log>
    80004454:	018a2583          	lw	a1,24(s4)
    80004458:	012585bb          	addw	a1,a1,s2
    8000445c:	2585                	addiw	a1,a1,1
    8000445e:	028a2503          	lw	a0,40(s4)
    80004462:	fffff097          	auipc	ra,0xfffff
    80004466:	ce8080e7          	jalr	-792(ra) # 8000314a <bread>
    8000446a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000446c:	000aa583          	lw	a1,0(s5)
    80004470:	028a2503          	lw	a0,40(s4)
    80004474:	fffff097          	auipc	ra,0xfffff
    80004478:	cd6080e7          	jalr	-810(ra) # 8000314a <bread>
    8000447c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000447e:	40000613          	li	a2,1024
    80004482:	05850593          	addi	a1,a0,88
    80004486:	05848513          	addi	a0,s1,88
    8000448a:	ffffd097          	auipc	ra,0xffffd
    8000448e:	8e2080e7          	jalr	-1822(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    80004492:	8526                	mv	a0,s1
    80004494:	fffff097          	auipc	ra,0xfffff
    80004498:	da8080e7          	jalr	-600(ra) # 8000323c <bwrite>
    brelse(from);
    8000449c:	854e                	mv	a0,s3
    8000449e:	fffff097          	auipc	ra,0xfffff
    800044a2:	ddc080e7          	jalr	-548(ra) # 8000327a <brelse>
    brelse(to);
    800044a6:	8526                	mv	a0,s1
    800044a8:	fffff097          	auipc	ra,0xfffff
    800044ac:	dd2080e7          	jalr	-558(ra) # 8000327a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044b0:	2905                	addiw	s2,s2,1
    800044b2:	0a91                	addi	s5,s5,4
    800044b4:	02ca2783          	lw	a5,44(s4)
    800044b8:	f8f94ee3          	blt	s2,a5,80004454 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044bc:	00000097          	auipc	ra,0x0
    800044c0:	c7a080e7          	jalr	-902(ra) # 80004136 <write_head>
    install_trans(); // Now install writes to home locations
    800044c4:	00000097          	auipc	ra,0x0
    800044c8:	cec080e7          	jalr	-788(ra) # 800041b0 <install_trans>
    log.lh.n = 0;
    800044cc:	0001d797          	auipc	a5,0x1d
    800044d0:	6607a423          	sw	zero,1640(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044d4:	00000097          	auipc	ra,0x0
    800044d8:	c62080e7          	jalr	-926(ra) # 80004136 <write_head>
    800044dc:	bdfd                	j	800043da <end_op+0x52>

00000000800044de <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044de:	1101                	addi	sp,sp,-32
    800044e0:	ec06                	sd	ra,24(sp)
    800044e2:	e822                	sd	s0,16(sp)
    800044e4:	e426                	sd	s1,8(sp)
    800044e6:	e04a                	sd	s2,0(sp)
    800044e8:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044ea:	0001d717          	auipc	a4,0x1d
    800044ee:	64a72703          	lw	a4,1610(a4) # 80021b34 <log+0x2c>
    800044f2:	47f5                	li	a5,29
    800044f4:	08e7c063          	blt	a5,a4,80004574 <log_write+0x96>
    800044f8:	84aa                	mv	s1,a0
    800044fa:	0001d797          	auipc	a5,0x1d
    800044fe:	62a7a783          	lw	a5,1578(a5) # 80021b24 <log+0x1c>
    80004502:	37fd                	addiw	a5,a5,-1
    80004504:	06f75863          	bge	a4,a5,80004574 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004508:	0001d797          	auipc	a5,0x1d
    8000450c:	6207a783          	lw	a5,1568(a5) # 80021b28 <log+0x20>
    80004510:	06f05a63          	blez	a5,80004584 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004514:	0001d917          	auipc	s2,0x1d
    80004518:	5f490913          	addi	s2,s2,1524 # 80021b08 <log>
    8000451c:	854a                	mv	a0,s2
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	6f2080e7          	jalr	1778(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004526:	02c92603          	lw	a2,44(s2)
    8000452a:	06c05563          	blez	a2,80004594 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000452e:	44cc                	lw	a1,12(s1)
    80004530:	0001d717          	auipc	a4,0x1d
    80004534:	60870713          	addi	a4,a4,1544 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004538:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000453a:	4314                	lw	a3,0(a4)
    8000453c:	04b68d63          	beq	a3,a1,80004596 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004540:	2785                	addiw	a5,a5,1
    80004542:	0711                	addi	a4,a4,4
    80004544:	fec79be3          	bne	a5,a2,8000453a <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004548:	0621                	addi	a2,a2,8
    8000454a:	060a                	slli	a2,a2,0x2
    8000454c:	0001d797          	auipc	a5,0x1d
    80004550:	5bc78793          	addi	a5,a5,1468 # 80021b08 <log>
    80004554:	963e                	add	a2,a2,a5
    80004556:	44dc                	lw	a5,12(s1)
    80004558:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000455a:	8526                	mv	a0,s1
    8000455c:	fffff097          	auipc	ra,0xfffff
    80004560:	dbc080e7          	jalr	-580(ra) # 80003318 <bpin>
    log.lh.n++;
    80004564:	0001d717          	auipc	a4,0x1d
    80004568:	5a470713          	addi	a4,a4,1444 # 80021b08 <log>
    8000456c:	575c                	lw	a5,44(a4)
    8000456e:	2785                	addiw	a5,a5,1
    80004570:	d75c                	sw	a5,44(a4)
    80004572:	a83d                	j	800045b0 <log_write+0xd2>
    panic("too big a transaction");
    80004574:	00004517          	auipc	a0,0x4
    80004578:	12c50513          	addi	a0,a0,300 # 800086a0 <syscalls+0x1f0>
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	fcc080e7          	jalr	-52(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004584:	00004517          	auipc	a0,0x4
    80004588:	13450513          	addi	a0,a0,308 # 800086b8 <syscalls+0x208>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	fbc080e7          	jalr	-68(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004594:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004596:	00878713          	addi	a4,a5,8
    8000459a:	00271693          	slli	a3,a4,0x2
    8000459e:	0001d717          	auipc	a4,0x1d
    800045a2:	56a70713          	addi	a4,a4,1386 # 80021b08 <log>
    800045a6:	9736                	add	a4,a4,a3
    800045a8:	44d4                	lw	a3,12(s1)
    800045aa:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045ac:	faf607e3          	beq	a2,a5,8000455a <log_write+0x7c>
  }
  release(&log.lock);
    800045b0:	0001d517          	auipc	a0,0x1d
    800045b4:	55850513          	addi	a0,a0,1368 # 80021b08 <log>
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	70c080e7          	jalr	1804(ra) # 80000cc4 <release>
}
    800045c0:	60e2                	ld	ra,24(sp)
    800045c2:	6442                	ld	s0,16(sp)
    800045c4:	64a2                	ld	s1,8(sp)
    800045c6:	6902                	ld	s2,0(sp)
    800045c8:	6105                	addi	sp,sp,32
    800045ca:	8082                	ret

00000000800045cc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045cc:	1101                	addi	sp,sp,-32
    800045ce:	ec06                	sd	ra,24(sp)
    800045d0:	e822                	sd	s0,16(sp)
    800045d2:	e426                	sd	s1,8(sp)
    800045d4:	e04a                	sd	s2,0(sp)
    800045d6:	1000                	addi	s0,sp,32
    800045d8:	84aa                	mv	s1,a0
    800045da:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045dc:	00004597          	auipc	a1,0x4
    800045e0:	0fc58593          	addi	a1,a1,252 # 800086d8 <syscalls+0x228>
    800045e4:	0521                	addi	a0,a0,8
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	59a080e7          	jalr	1434(ra) # 80000b80 <initlock>
  lk->name = name;
    800045ee:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045f2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045f6:	0204a423          	sw	zero,40(s1)
}
    800045fa:	60e2                	ld	ra,24(sp)
    800045fc:	6442                	ld	s0,16(sp)
    800045fe:	64a2                	ld	s1,8(sp)
    80004600:	6902                	ld	s2,0(sp)
    80004602:	6105                	addi	sp,sp,32
    80004604:	8082                	ret

0000000080004606 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004606:	1101                	addi	sp,sp,-32
    80004608:	ec06                	sd	ra,24(sp)
    8000460a:	e822                	sd	s0,16(sp)
    8000460c:	e426                	sd	s1,8(sp)
    8000460e:	e04a                	sd	s2,0(sp)
    80004610:	1000                	addi	s0,sp,32
    80004612:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004614:	00850913          	addi	s2,a0,8
    80004618:	854a                	mv	a0,s2
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	5f6080e7          	jalr	1526(ra) # 80000c10 <acquire>
  while (lk->locked) {
    80004622:	409c                	lw	a5,0(s1)
    80004624:	cb89                	beqz	a5,80004636 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004626:	85ca                	mv	a1,s2
    80004628:	8526                	mv	a0,s1
    8000462a:	ffffe097          	auipc	ra,0xffffe
    8000462e:	f02080e7          	jalr	-254(ra) # 8000252c <sleep>
  while (lk->locked) {
    80004632:	409c                	lw	a5,0(s1)
    80004634:	fbed                	bnez	a5,80004626 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004636:	4785                	li	a5,1
    80004638:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000463a:	ffffd097          	auipc	ra,0xffffd
    8000463e:	4e4080e7          	jalr	1252(ra) # 80001b1e <myproc>
    80004642:	413c                	lw	a5,64(a0)
    80004644:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004646:	854a                	mv	a0,s2
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	67c080e7          	jalr	1660(ra) # 80000cc4 <release>
}
    80004650:	60e2                	ld	ra,24(sp)
    80004652:	6442                	ld	s0,16(sp)
    80004654:	64a2                	ld	s1,8(sp)
    80004656:	6902                	ld	s2,0(sp)
    80004658:	6105                	addi	sp,sp,32
    8000465a:	8082                	ret

000000008000465c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000465c:	1101                	addi	sp,sp,-32
    8000465e:	ec06                	sd	ra,24(sp)
    80004660:	e822                	sd	s0,16(sp)
    80004662:	e426                	sd	s1,8(sp)
    80004664:	e04a                	sd	s2,0(sp)
    80004666:	1000                	addi	s0,sp,32
    80004668:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000466a:	00850913          	addi	s2,a0,8
    8000466e:	854a                	mv	a0,s2
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	5a0080e7          	jalr	1440(ra) # 80000c10 <acquire>
  lk->locked = 0;
    80004678:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000467c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004680:	8526                	mv	a0,s1
    80004682:	ffffe097          	auipc	ra,0xffffe
    80004686:	030080e7          	jalr	48(ra) # 800026b2 <wakeup>
  release(&lk->lk);
    8000468a:	854a                	mv	a0,s2
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	638080e7          	jalr	1592(ra) # 80000cc4 <release>
}
    80004694:	60e2                	ld	ra,24(sp)
    80004696:	6442                	ld	s0,16(sp)
    80004698:	64a2                	ld	s1,8(sp)
    8000469a:	6902                	ld	s2,0(sp)
    8000469c:	6105                	addi	sp,sp,32
    8000469e:	8082                	ret

00000000800046a0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046a0:	7179                	addi	sp,sp,-48
    800046a2:	f406                	sd	ra,40(sp)
    800046a4:	f022                	sd	s0,32(sp)
    800046a6:	ec26                	sd	s1,24(sp)
    800046a8:	e84a                	sd	s2,16(sp)
    800046aa:	e44e                	sd	s3,8(sp)
    800046ac:	1800                	addi	s0,sp,48
    800046ae:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046b0:	00850913          	addi	s2,a0,8
    800046b4:	854a                	mv	a0,s2
    800046b6:	ffffc097          	auipc	ra,0xffffc
    800046ba:	55a080e7          	jalr	1370(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046be:	409c                	lw	a5,0(s1)
    800046c0:	ef99                	bnez	a5,800046de <holdingsleep+0x3e>
    800046c2:	4481                	li	s1,0
  release(&lk->lk);
    800046c4:	854a                	mv	a0,s2
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	5fe080e7          	jalr	1534(ra) # 80000cc4 <release>
  return r;
}
    800046ce:	8526                	mv	a0,s1
    800046d0:	70a2                	ld	ra,40(sp)
    800046d2:	7402                	ld	s0,32(sp)
    800046d4:	64e2                	ld	s1,24(sp)
    800046d6:	6942                	ld	s2,16(sp)
    800046d8:	69a2                	ld	s3,8(sp)
    800046da:	6145                	addi	sp,sp,48
    800046dc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046de:	0284a983          	lw	s3,40(s1)
    800046e2:	ffffd097          	auipc	ra,0xffffd
    800046e6:	43c080e7          	jalr	1084(ra) # 80001b1e <myproc>
    800046ea:	4124                	lw	s1,64(a0)
    800046ec:	413484b3          	sub	s1,s1,s3
    800046f0:	0014b493          	seqz	s1,s1
    800046f4:	bfc1                	j	800046c4 <holdingsleep+0x24>

00000000800046f6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046f6:	1141                	addi	sp,sp,-16
    800046f8:	e406                	sd	ra,8(sp)
    800046fa:	e022                	sd	s0,0(sp)
    800046fc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046fe:	00004597          	auipc	a1,0x4
    80004702:	fea58593          	addi	a1,a1,-22 # 800086e8 <syscalls+0x238>
    80004706:	0001d517          	auipc	a0,0x1d
    8000470a:	54a50513          	addi	a0,a0,1354 # 80021c50 <ftable>
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	472080e7          	jalr	1138(ra) # 80000b80 <initlock>
}
    80004716:	60a2                	ld	ra,8(sp)
    80004718:	6402                	ld	s0,0(sp)
    8000471a:	0141                	addi	sp,sp,16
    8000471c:	8082                	ret

000000008000471e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000471e:	1101                	addi	sp,sp,-32
    80004720:	ec06                	sd	ra,24(sp)
    80004722:	e822                	sd	s0,16(sp)
    80004724:	e426                	sd	s1,8(sp)
    80004726:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004728:	0001d517          	auipc	a0,0x1d
    8000472c:	52850513          	addi	a0,a0,1320 # 80021c50 <ftable>
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	4e0080e7          	jalr	1248(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004738:	0001d497          	auipc	s1,0x1d
    8000473c:	53048493          	addi	s1,s1,1328 # 80021c68 <ftable+0x18>
    80004740:	0001e717          	auipc	a4,0x1e
    80004744:	4c870713          	addi	a4,a4,1224 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    80004748:	40dc                	lw	a5,4(s1)
    8000474a:	cf99                	beqz	a5,80004768 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000474c:	02848493          	addi	s1,s1,40
    80004750:	fee49ce3          	bne	s1,a4,80004748 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004754:	0001d517          	auipc	a0,0x1d
    80004758:	4fc50513          	addi	a0,a0,1276 # 80021c50 <ftable>
    8000475c:	ffffc097          	auipc	ra,0xffffc
    80004760:	568080e7          	jalr	1384(ra) # 80000cc4 <release>
  return 0;
    80004764:	4481                	li	s1,0
    80004766:	a819                	j	8000477c <filealloc+0x5e>
      f->ref = 1;
    80004768:	4785                	li	a5,1
    8000476a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000476c:	0001d517          	auipc	a0,0x1d
    80004770:	4e450513          	addi	a0,a0,1252 # 80021c50 <ftable>
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	550080e7          	jalr	1360(ra) # 80000cc4 <release>
}
    8000477c:	8526                	mv	a0,s1
    8000477e:	60e2                	ld	ra,24(sp)
    80004780:	6442                	ld	s0,16(sp)
    80004782:	64a2                	ld	s1,8(sp)
    80004784:	6105                	addi	sp,sp,32
    80004786:	8082                	ret

0000000080004788 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004788:	1101                	addi	sp,sp,-32
    8000478a:	ec06                	sd	ra,24(sp)
    8000478c:	e822                	sd	s0,16(sp)
    8000478e:	e426                	sd	s1,8(sp)
    80004790:	1000                	addi	s0,sp,32
    80004792:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004794:	0001d517          	auipc	a0,0x1d
    80004798:	4bc50513          	addi	a0,a0,1212 # 80021c50 <ftable>
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	474080e7          	jalr	1140(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800047a4:	40dc                	lw	a5,4(s1)
    800047a6:	02f05263          	blez	a5,800047ca <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047aa:	2785                	addiw	a5,a5,1
    800047ac:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047ae:	0001d517          	auipc	a0,0x1d
    800047b2:	4a250513          	addi	a0,a0,1186 # 80021c50 <ftable>
    800047b6:	ffffc097          	auipc	ra,0xffffc
    800047ba:	50e080e7          	jalr	1294(ra) # 80000cc4 <release>
  return f;
}
    800047be:	8526                	mv	a0,s1
    800047c0:	60e2                	ld	ra,24(sp)
    800047c2:	6442                	ld	s0,16(sp)
    800047c4:	64a2                	ld	s1,8(sp)
    800047c6:	6105                	addi	sp,sp,32
    800047c8:	8082                	ret
    panic("filedup");
    800047ca:	00004517          	auipc	a0,0x4
    800047ce:	f2650513          	addi	a0,a0,-218 # 800086f0 <syscalls+0x240>
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	d76080e7          	jalr	-650(ra) # 80000548 <panic>

00000000800047da <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047da:	7139                	addi	sp,sp,-64
    800047dc:	fc06                	sd	ra,56(sp)
    800047de:	f822                	sd	s0,48(sp)
    800047e0:	f426                	sd	s1,40(sp)
    800047e2:	f04a                	sd	s2,32(sp)
    800047e4:	ec4e                	sd	s3,24(sp)
    800047e6:	e852                	sd	s4,16(sp)
    800047e8:	e456                	sd	s5,8(sp)
    800047ea:	0080                	addi	s0,sp,64
    800047ec:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047ee:	0001d517          	auipc	a0,0x1d
    800047f2:	46250513          	addi	a0,a0,1122 # 80021c50 <ftable>
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	41a080e7          	jalr	1050(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800047fe:	40dc                	lw	a5,4(s1)
    80004800:	06f05163          	blez	a5,80004862 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004804:	37fd                	addiw	a5,a5,-1
    80004806:	0007871b          	sext.w	a4,a5
    8000480a:	c0dc                	sw	a5,4(s1)
    8000480c:	06e04363          	bgtz	a4,80004872 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004810:	0004a903          	lw	s2,0(s1)
    80004814:	0094ca83          	lbu	s5,9(s1)
    80004818:	0104ba03          	ld	s4,16(s1)
    8000481c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004820:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004824:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004828:	0001d517          	auipc	a0,0x1d
    8000482c:	42850513          	addi	a0,a0,1064 # 80021c50 <ftable>
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	494080e7          	jalr	1172(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    80004838:	4785                	li	a5,1
    8000483a:	04f90d63          	beq	s2,a5,80004894 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000483e:	3979                	addiw	s2,s2,-2
    80004840:	4785                	li	a5,1
    80004842:	0527e063          	bltu	a5,s2,80004882 <fileclose+0xa8>
    begin_op();
    80004846:	00000097          	auipc	ra,0x0
    8000484a:	ac2080e7          	jalr	-1342(ra) # 80004308 <begin_op>
    iput(ff.ip);
    8000484e:	854e                	mv	a0,s3
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	2b6080e7          	jalr	694(ra) # 80003b06 <iput>
    end_op();
    80004858:	00000097          	auipc	ra,0x0
    8000485c:	b30080e7          	jalr	-1232(ra) # 80004388 <end_op>
    80004860:	a00d                	j	80004882 <fileclose+0xa8>
    panic("fileclose");
    80004862:	00004517          	auipc	a0,0x4
    80004866:	e9650513          	addi	a0,a0,-362 # 800086f8 <syscalls+0x248>
    8000486a:	ffffc097          	auipc	ra,0xffffc
    8000486e:	cde080e7          	jalr	-802(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004872:	0001d517          	auipc	a0,0x1d
    80004876:	3de50513          	addi	a0,a0,990 # 80021c50 <ftable>
    8000487a:	ffffc097          	auipc	ra,0xffffc
    8000487e:	44a080e7          	jalr	1098(ra) # 80000cc4 <release>
  }
}
    80004882:	70e2                	ld	ra,56(sp)
    80004884:	7442                	ld	s0,48(sp)
    80004886:	74a2                	ld	s1,40(sp)
    80004888:	7902                	ld	s2,32(sp)
    8000488a:	69e2                	ld	s3,24(sp)
    8000488c:	6a42                	ld	s4,16(sp)
    8000488e:	6aa2                	ld	s5,8(sp)
    80004890:	6121                	addi	sp,sp,64
    80004892:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004894:	85d6                	mv	a1,s5
    80004896:	8552                	mv	a0,s4
    80004898:	00000097          	auipc	ra,0x0
    8000489c:	372080e7          	jalr	882(ra) # 80004c0a <pipeclose>
    800048a0:	b7cd                	j	80004882 <fileclose+0xa8>

00000000800048a2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048a2:	715d                	addi	sp,sp,-80
    800048a4:	e486                	sd	ra,72(sp)
    800048a6:	e0a2                	sd	s0,64(sp)
    800048a8:	fc26                	sd	s1,56(sp)
    800048aa:	f84a                	sd	s2,48(sp)
    800048ac:	f44e                	sd	s3,40(sp)
    800048ae:	0880                	addi	s0,sp,80
    800048b0:	84aa                	mv	s1,a0
    800048b2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048b4:	ffffd097          	auipc	ra,0xffffd
    800048b8:	26a080e7          	jalr	618(ra) # 80001b1e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048bc:	409c                	lw	a5,0(s1)
    800048be:	37f9                	addiw	a5,a5,-2
    800048c0:	4705                	li	a4,1
    800048c2:	04f76763          	bltu	a4,a5,80004910 <filestat+0x6e>
    800048c6:	892a                	mv	s2,a0
    ilock(f->ip);
    800048c8:	6c88                	ld	a0,24(s1)
    800048ca:	fffff097          	auipc	ra,0xfffff
    800048ce:	082080e7          	jalr	130(ra) # 8000394c <ilock>
    stati(f->ip, &st);
    800048d2:	fb840593          	addi	a1,s0,-72
    800048d6:	6c88                	ld	a0,24(s1)
    800048d8:	fffff097          	auipc	ra,0xfffff
    800048dc:	2fe080e7          	jalr	766(ra) # 80003bd6 <stati>
    iunlock(f->ip);
    800048e0:	6c88                	ld	a0,24(s1)
    800048e2:	fffff097          	auipc	ra,0xfffff
    800048e6:	12c080e7          	jalr	300(ra) # 80003a0e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048ea:	46e1                	li	a3,24
    800048ec:	fb840613          	addi	a2,s0,-72
    800048f0:	85ce                	mv	a1,s3
    800048f2:	05893503          	ld	a0,88(s2)
    800048f6:	ffffd097          	auipc	ra,0xffffd
    800048fa:	dec080e7          	jalr	-532(ra) # 800016e2 <copyout>
    800048fe:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004902:	60a6                	ld	ra,72(sp)
    80004904:	6406                	ld	s0,64(sp)
    80004906:	74e2                	ld	s1,56(sp)
    80004908:	7942                	ld	s2,48(sp)
    8000490a:	79a2                	ld	s3,40(sp)
    8000490c:	6161                	addi	sp,sp,80
    8000490e:	8082                	ret
  return -1;
    80004910:	557d                	li	a0,-1
    80004912:	bfc5                	j	80004902 <filestat+0x60>

0000000080004914 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004914:	7179                	addi	sp,sp,-48
    80004916:	f406                	sd	ra,40(sp)
    80004918:	f022                	sd	s0,32(sp)
    8000491a:	ec26                	sd	s1,24(sp)
    8000491c:	e84a                	sd	s2,16(sp)
    8000491e:	e44e                	sd	s3,8(sp)
    80004920:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004922:	00854783          	lbu	a5,8(a0)
    80004926:	c3d5                	beqz	a5,800049ca <fileread+0xb6>
    80004928:	84aa                	mv	s1,a0
    8000492a:	89ae                	mv	s3,a1
    8000492c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000492e:	411c                	lw	a5,0(a0)
    80004930:	4705                	li	a4,1
    80004932:	04e78963          	beq	a5,a4,80004984 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004936:	470d                	li	a4,3
    80004938:	04e78d63          	beq	a5,a4,80004992 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000493c:	4709                	li	a4,2
    8000493e:	06e79e63          	bne	a5,a4,800049ba <fileread+0xa6>
    ilock(f->ip);
    80004942:	6d08                	ld	a0,24(a0)
    80004944:	fffff097          	auipc	ra,0xfffff
    80004948:	008080e7          	jalr	8(ra) # 8000394c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000494c:	874a                	mv	a4,s2
    8000494e:	5094                	lw	a3,32(s1)
    80004950:	864e                	mv	a2,s3
    80004952:	4585                	li	a1,1
    80004954:	6c88                	ld	a0,24(s1)
    80004956:	fffff097          	auipc	ra,0xfffff
    8000495a:	2aa080e7          	jalr	682(ra) # 80003c00 <readi>
    8000495e:	892a                	mv	s2,a0
    80004960:	00a05563          	blez	a0,8000496a <fileread+0x56>
      f->off += r;
    80004964:	509c                	lw	a5,32(s1)
    80004966:	9fa9                	addw	a5,a5,a0
    80004968:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000496a:	6c88                	ld	a0,24(s1)
    8000496c:	fffff097          	auipc	ra,0xfffff
    80004970:	0a2080e7          	jalr	162(ra) # 80003a0e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004974:	854a                	mv	a0,s2
    80004976:	70a2                	ld	ra,40(sp)
    80004978:	7402                	ld	s0,32(sp)
    8000497a:	64e2                	ld	s1,24(sp)
    8000497c:	6942                	ld	s2,16(sp)
    8000497e:	69a2                	ld	s3,8(sp)
    80004980:	6145                	addi	sp,sp,48
    80004982:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004984:	6908                	ld	a0,16(a0)
    80004986:	00000097          	auipc	ra,0x0
    8000498a:	418080e7          	jalr	1048(ra) # 80004d9e <piperead>
    8000498e:	892a                	mv	s2,a0
    80004990:	b7d5                	j	80004974 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004992:	02451783          	lh	a5,36(a0)
    80004996:	03079693          	slli	a3,a5,0x30
    8000499a:	92c1                	srli	a3,a3,0x30
    8000499c:	4725                	li	a4,9
    8000499e:	02d76863          	bltu	a4,a3,800049ce <fileread+0xba>
    800049a2:	0792                	slli	a5,a5,0x4
    800049a4:	0001d717          	auipc	a4,0x1d
    800049a8:	20c70713          	addi	a4,a4,524 # 80021bb0 <devsw>
    800049ac:	97ba                	add	a5,a5,a4
    800049ae:	639c                	ld	a5,0(a5)
    800049b0:	c38d                	beqz	a5,800049d2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049b2:	4505                	li	a0,1
    800049b4:	9782                	jalr	a5
    800049b6:	892a                	mv	s2,a0
    800049b8:	bf75                	j	80004974 <fileread+0x60>
    panic("fileread");
    800049ba:	00004517          	auipc	a0,0x4
    800049be:	d4e50513          	addi	a0,a0,-690 # 80008708 <syscalls+0x258>
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	b86080e7          	jalr	-1146(ra) # 80000548 <panic>
    return -1;
    800049ca:	597d                	li	s2,-1
    800049cc:	b765                	j	80004974 <fileread+0x60>
      return -1;
    800049ce:	597d                	li	s2,-1
    800049d0:	b755                	j	80004974 <fileread+0x60>
    800049d2:	597d                	li	s2,-1
    800049d4:	b745                	j	80004974 <fileread+0x60>

00000000800049d6 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800049d6:	00954783          	lbu	a5,9(a0)
    800049da:	14078563          	beqz	a5,80004b24 <filewrite+0x14e>
{
    800049de:	715d                	addi	sp,sp,-80
    800049e0:	e486                	sd	ra,72(sp)
    800049e2:	e0a2                	sd	s0,64(sp)
    800049e4:	fc26                	sd	s1,56(sp)
    800049e6:	f84a                	sd	s2,48(sp)
    800049e8:	f44e                	sd	s3,40(sp)
    800049ea:	f052                	sd	s4,32(sp)
    800049ec:	ec56                	sd	s5,24(sp)
    800049ee:	e85a                	sd	s6,16(sp)
    800049f0:	e45e                	sd	s7,8(sp)
    800049f2:	e062                	sd	s8,0(sp)
    800049f4:	0880                	addi	s0,sp,80
    800049f6:	892a                	mv	s2,a0
    800049f8:	8aae                	mv	s5,a1
    800049fa:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049fc:	411c                	lw	a5,0(a0)
    800049fe:	4705                	li	a4,1
    80004a00:	02e78263          	beq	a5,a4,80004a24 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a04:	470d                	li	a4,3
    80004a06:	02e78563          	beq	a5,a4,80004a30 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a0a:	4709                	li	a4,2
    80004a0c:	10e79463          	bne	a5,a4,80004b14 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a10:	0ec05e63          	blez	a2,80004b0c <filewrite+0x136>
    int i = 0;
    80004a14:	4981                	li	s3,0
    80004a16:	6b05                	lui	s6,0x1
    80004a18:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a1c:	6b85                	lui	s7,0x1
    80004a1e:	c00b8b9b          	addiw	s7,s7,-1024
    80004a22:	a851                	j	80004ab6 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a24:	6908                	ld	a0,16(a0)
    80004a26:	00000097          	auipc	ra,0x0
    80004a2a:	254080e7          	jalr	596(ra) # 80004c7a <pipewrite>
    80004a2e:	a85d                	j	80004ae4 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a30:	02451783          	lh	a5,36(a0)
    80004a34:	03079693          	slli	a3,a5,0x30
    80004a38:	92c1                	srli	a3,a3,0x30
    80004a3a:	4725                	li	a4,9
    80004a3c:	0ed76663          	bltu	a4,a3,80004b28 <filewrite+0x152>
    80004a40:	0792                	slli	a5,a5,0x4
    80004a42:	0001d717          	auipc	a4,0x1d
    80004a46:	16e70713          	addi	a4,a4,366 # 80021bb0 <devsw>
    80004a4a:	97ba                	add	a5,a5,a4
    80004a4c:	679c                	ld	a5,8(a5)
    80004a4e:	cff9                	beqz	a5,80004b2c <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a50:	4505                	li	a0,1
    80004a52:	9782                	jalr	a5
    80004a54:	a841                	j	80004ae4 <filewrite+0x10e>
    80004a56:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a5a:	00000097          	auipc	ra,0x0
    80004a5e:	8ae080e7          	jalr	-1874(ra) # 80004308 <begin_op>
      ilock(f->ip);
    80004a62:	01893503          	ld	a0,24(s2)
    80004a66:	fffff097          	auipc	ra,0xfffff
    80004a6a:	ee6080e7          	jalr	-282(ra) # 8000394c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a6e:	8762                	mv	a4,s8
    80004a70:	02092683          	lw	a3,32(s2)
    80004a74:	01598633          	add	a2,s3,s5
    80004a78:	4585                	li	a1,1
    80004a7a:	01893503          	ld	a0,24(s2)
    80004a7e:	fffff097          	auipc	ra,0xfffff
    80004a82:	278080e7          	jalr	632(ra) # 80003cf6 <writei>
    80004a86:	84aa                	mv	s1,a0
    80004a88:	02a05f63          	blez	a0,80004ac6 <filewrite+0xf0>
        f->off += r;
    80004a8c:	02092783          	lw	a5,32(s2)
    80004a90:	9fa9                	addw	a5,a5,a0
    80004a92:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a96:	01893503          	ld	a0,24(s2)
    80004a9a:	fffff097          	auipc	ra,0xfffff
    80004a9e:	f74080e7          	jalr	-140(ra) # 80003a0e <iunlock>
      end_op();
    80004aa2:	00000097          	auipc	ra,0x0
    80004aa6:	8e6080e7          	jalr	-1818(ra) # 80004388 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004aaa:	049c1963          	bne	s8,s1,80004afc <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004aae:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ab2:	0349d663          	bge	s3,s4,80004ade <filewrite+0x108>
      int n1 = n - i;
    80004ab6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004aba:	84be                	mv	s1,a5
    80004abc:	2781                	sext.w	a5,a5
    80004abe:	f8fb5ce3          	bge	s6,a5,80004a56 <filewrite+0x80>
    80004ac2:	84de                	mv	s1,s7
    80004ac4:	bf49                	j	80004a56 <filewrite+0x80>
      iunlock(f->ip);
    80004ac6:	01893503          	ld	a0,24(s2)
    80004aca:	fffff097          	auipc	ra,0xfffff
    80004ace:	f44080e7          	jalr	-188(ra) # 80003a0e <iunlock>
      end_op();
    80004ad2:	00000097          	auipc	ra,0x0
    80004ad6:	8b6080e7          	jalr	-1866(ra) # 80004388 <end_op>
      if(r < 0)
    80004ada:	fc04d8e3          	bgez	s1,80004aaa <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004ade:	8552                	mv	a0,s4
    80004ae0:	033a1863          	bne	s4,s3,80004b10 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ae4:	60a6                	ld	ra,72(sp)
    80004ae6:	6406                	ld	s0,64(sp)
    80004ae8:	74e2                	ld	s1,56(sp)
    80004aea:	7942                	ld	s2,48(sp)
    80004aec:	79a2                	ld	s3,40(sp)
    80004aee:	7a02                	ld	s4,32(sp)
    80004af0:	6ae2                	ld	s5,24(sp)
    80004af2:	6b42                	ld	s6,16(sp)
    80004af4:	6ba2                	ld	s7,8(sp)
    80004af6:	6c02                	ld	s8,0(sp)
    80004af8:	6161                	addi	sp,sp,80
    80004afa:	8082                	ret
        panic("short filewrite");
    80004afc:	00004517          	auipc	a0,0x4
    80004b00:	c1c50513          	addi	a0,a0,-996 # 80008718 <syscalls+0x268>
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	a44080e7          	jalr	-1468(ra) # 80000548 <panic>
    int i = 0;
    80004b0c:	4981                	li	s3,0
    80004b0e:	bfc1                	j	80004ade <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b10:	557d                	li	a0,-1
    80004b12:	bfc9                	j	80004ae4 <filewrite+0x10e>
    panic("filewrite");
    80004b14:	00004517          	auipc	a0,0x4
    80004b18:	c1450513          	addi	a0,a0,-1004 # 80008728 <syscalls+0x278>
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	a2c080e7          	jalr	-1492(ra) # 80000548 <panic>
    return -1;
    80004b24:	557d                	li	a0,-1
}
    80004b26:	8082                	ret
      return -1;
    80004b28:	557d                	li	a0,-1
    80004b2a:	bf6d                	j	80004ae4 <filewrite+0x10e>
    80004b2c:	557d                	li	a0,-1
    80004b2e:	bf5d                	j	80004ae4 <filewrite+0x10e>

0000000080004b30 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b30:	7179                	addi	sp,sp,-48
    80004b32:	f406                	sd	ra,40(sp)
    80004b34:	f022                	sd	s0,32(sp)
    80004b36:	ec26                	sd	s1,24(sp)
    80004b38:	e84a                	sd	s2,16(sp)
    80004b3a:	e44e                	sd	s3,8(sp)
    80004b3c:	e052                	sd	s4,0(sp)
    80004b3e:	1800                	addi	s0,sp,48
    80004b40:	84aa                	mv	s1,a0
    80004b42:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b44:	0005b023          	sd	zero,0(a1)
    80004b48:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b4c:	00000097          	auipc	ra,0x0
    80004b50:	bd2080e7          	jalr	-1070(ra) # 8000471e <filealloc>
    80004b54:	e088                	sd	a0,0(s1)
    80004b56:	c551                	beqz	a0,80004be2 <pipealloc+0xb2>
    80004b58:	00000097          	auipc	ra,0x0
    80004b5c:	bc6080e7          	jalr	-1082(ra) # 8000471e <filealloc>
    80004b60:	00aa3023          	sd	a0,0(s4)
    80004b64:	c92d                	beqz	a0,80004bd6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	fba080e7          	jalr	-70(ra) # 80000b20 <kalloc>
    80004b6e:	892a                	mv	s2,a0
    80004b70:	c125                	beqz	a0,80004bd0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b72:	4985                	li	s3,1
    80004b74:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b78:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b7c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b80:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b84:	00004597          	auipc	a1,0x4
    80004b88:	bb458593          	addi	a1,a1,-1100 # 80008738 <syscalls+0x288>
    80004b8c:	ffffc097          	auipc	ra,0xffffc
    80004b90:	ff4080e7          	jalr	-12(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004b94:	609c                	ld	a5,0(s1)
    80004b96:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b9a:	609c                	ld	a5,0(s1)
    80004b9c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ba0:	609c                	ld	a5,0(s1)
    80004ba2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ba6:	609c                	ld	a5,0(s1)
    80004ba8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bac:	000a3783          	ld	a5,0(s4)
    80004bb0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bb4:	000a3783          	ld	a5,0(s4)
    80004bb8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bbc:	000a3783          	ld	a5,0(s4)
    80004bc0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bc4:	000a3783          	ld	a5,0(s4)
    80004bc8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bcc:	4501                	li	a0,0
    80004bce:	a025                	j	80004bf6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bd0:	6088                	ld	a0,0(s1)
    80004bd2:	e501                	bnez	a0,80004bda <pipealloc+0xaa>
    80004bd4:	a039                	j	80004be2 <pipealloc+0xb2>
    80004bd6:	6088                	ld	a0,0(s1)
    80004bd8:	c51d                	beqz	a0,80004c06 <pipealloc+0xd6>
    fileclose(*f0);
    80004bda:	00000097          	auipc	ra,0x0
    80004bde:	c00080e7          	jalr	-1024(ra) # 800047da <fileclose>
  if(*f1)
    80004be2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004be6:	557d                	li	a0,-1
  if(*f1)
    80004be8:	c799                	beqz	a5,80004bf6 <pipealloc+0xc6>
    fileclose(*f1);
    80004bea:	853e                	mv	a0,a5
    80004bec:	00000097          	auipc	ra,0x0
    80004bf0:	bee080e7          	jalr	-1042(ra) # 800047da <fileclose>
  return -1;
    80004bf4:	557d                	li	a0,-1
}
    80004bf6:	70a2                	ld	ra,40(sp)
    80004bf8:	7402                	ld	s0,32(sp)
    80004bfa:	64e2                	ld	s1,24(sp)
    80004bfc:	6942                	ld	s2,16(sp)
    80004bfe:	69a2                	ld	s3,8(sp)
    80004c00:	6a02                	ld	s4,0(sp)
    80004c02:	6145                	addi	sp,sp,48
    80004c04:	8082                	ret
  return -1;
    80004c06:	557d                	li	a0,-1
    80004c08:	b7fd                	j	80004bf6 <pipealloc+0xc6>

0000000080004c0a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c0a:	1101                	addi	sp,sp,-32
    80004c0c:	ec06                	sd	ra,24(sp)
    80004c0e:	e822                	sd	s0,16(sp)
    80004c10:	e426                	sd	s1,8(sp)
    80004c12:	e04a                	sd	s2,0(sp)
    80004c14:	1000                	addi	s0,sp,32
    80004c16:	84aa                	mv	s1,a0
    80004c18:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c1a:	ffffc097          	auipc	ra,0xffffc
    80004c1e:	ff6080e7          	jalr	-10(ra) # 80000c10 <acquire>
  if(writable){
    80004c22:	02090d63          	beqz	s2,80004c5c <pipeclose+0x52>
    pi->writeopen = 0;
    80004c26:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c2a:	21848513          	addi	a0,s1,536
    80004c2e:	ffffe097          	auipc	ra,0xffffe
    80004c32:	a84080e7          	jalr	-1404(ra) # 800026b2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c36:	2204b783          	ld	a5,544(s1)
    80004c3a:	eb95                	bnez	a5,80004c6e <pipeclose+0x64>
    release(&pi->lock);
    80004c3c:	8526                	mv	a0,s1
    80004c3e:	ffffc097          	auipc	ra,0xffffc
    80004c42:	086080e7          	jalr	134(ra) # 80000cc4 <release>
    kfree((char*)pi);
    80004c46:	8526                	mv	a0,s1
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	ddc080e7          	jalr	-548(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004c50:	60e2                	ld	ra,24(sp)
    80004c52:	6442                	ld	s0,16(sp)
    80004c54:	64a2                	ld	s1,8(sp)
    80004c56:	6902                	ld	s2,0(sp)
    80004c58:	6105                	addi	sp,sp,32
    80004c5a:	8082                	ret
    pi->readopen = 0;
    80004c5c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c60:	21c48513          	addi	a0,s1,540
    80004c64:	ffffe097          	auipc	ra,0xffffe
    80004c68:	a4e080e7          	jalr	-1458(ra) # 800026b2 <wakeup>
    80004c6c:	b7e9                	j	80004c36 <pipeclose+0x2c>
    release(&pi->lock);
    80004c6e:	8526                	mv	a0,s1
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	054080e7          	jalr	84(ra) # 80000cc4 <release>
}
    80004c78:	bfe1                	j	80004c50 <pipeclose+0x46>

0000000080004c7a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c7a:	7119                	addi	sp,sp,-128
    80004c7c:	fc86                	sd	ra,120(sp)
    80004c7e:	f8a2                	sd	s0,112(sp)
    80004c80:	f4a6                	sd	s1,104(sp)
    80004c82:	f0ca                	sd	s2,96(sp)
    80004c84:	ecce                	sd	s3,88(sp)
    80004c86:	e8d2                	sd	s4,80(sp)
    80004c88:	e4d6                	sd	s5,72(sp)
    80004c8a:	e0da                	sd	s6,64(sp)
    80004c8c:	fc5e                	sd	s7,56(sp)
    80004c8e:	f862                	sd	s8,48(sp)
    80004c90:	f466                	sd	s9,40(sp)
    80004c92:	f06a                	sd	s10,32(sp)
    80004c94:	ec6e                	sd	s11,24(sp)
    80004c96:	0100                	addi	s0,sp,128
    80004c98:	84aa                	mv	s1,a0
    80004c9a:	8cae                	mv	s9,a1
    80004c9c:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004c9e:	ffffd097          	auipc	ra,0xffffd
    80004ca2:	e80080e7          	jalr	-384(ra) # 80001b1e <myproc>
    80004ca6:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004ca8:	8526                	mv	a0,s1
    80004caa:	ffffc097          	auipc	ra,0xffffc
    80004cae:	f66080e7          	jalr	-154(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004cb2:	0d605963          	blez	s6,80004d84 <pipewrite+0x10a>
    80004cb6:	89a6                	mv	s3,s1
    80004cb8:	3b7d                	addiw	s6,s6,-1
    80004cba:	1b02                	slli	s6,s6,0x20
    80004cbc:	020b5b13          	srli	s6,s6,0x20
    80004cc0:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004cc2:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cc6:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cca:	5dfd                	li	s11,-1
    80004ccc:	000b8d1b          	sext.w	s10,s7
    80004cd0:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004cd2:	2184a783          	lw	a5,536(s1)
    80004cd6:	21c4a703          	lw	a4,540(s1)
    80004cda:	2007879b          	addiw	a5,a5,512
    80004cde:	02f71b63          	bne	a4,a5,80004d14 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004ce2:	2204a783          	lw	a5,544(s1)
    80004ce6:	cbad                	beqz	a5,80004d58 <pipewrite+0xde>
    80004ce8:	03892783          	lw	a5,56(s2)
    80004cec:	e7b5                	bnez	a5,80004d58 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004cee:	8556                	mv	a0,s5
    80004cf0:	ffffe097          	auipc	ra,0xffffe
    80004cf4:	9c2080e7          	jalr	-1598(ra) # 800026b2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cf8:	85ce                	mv	a1,s3
    80004cfa:	8552                	mv	a0,s4
    80004cfc:	ffffe097          	auipc	ra,0xffffe
    80004d00:	830080e7          	jalr	-2000(ra) # 8000252c <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d04:	2184a783          	lw	a5,536(s1)
    80004d08:	21c4a703          	lw	a4,540(s1)
    80004d0c:	2007879b          	addiw	a5,a5,512
    80004d10:	fcf709e3          	beq	a4,a5,80004ce2 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d14:	4685                	li	a3,1
    80004d16:	019b8633          	add	a2,s7,s9
    80004d1a:	f8f40593          	addi	a1,s0,-113
    80004d1e:	05893503          	ld	a0,88(s2)
    80004d22:	ffffd097          	auipc	ra,0xffffd
    80004d26:	a4c080e7          	jalr	-1460(ra) # 8000176e <copyin>
    80004d2a:	05b50e63          	beq	a0,s11,80004d86 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d2e:	21c4a783          	lw	a5,540(s1)
    80004d32:	0017871b          	addiw	a4,a5,1
    80004d36:	20e4ae23          	sw	a4,540(s1)
    80004d3a:	1ff7f793          	andi	a5,a5,511
    80004d3e:	97a6                	add	a5,a5,s1
    80004d40:	f8f44703          	lbu	a4,-113(s0)
    80004d44:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004d48:	001d0c1b          	addiw	s8,s10,1
    80004d4c:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004d50:	036b8b63          	beq	s7,s6,80004d86 <pipewrite+0x10c>
    80004d54:	8bbe                	mv	s7,a5
    80004d56:	bf9d                	j	80004ccc <pipewrite+0x52>
        release(&pi->lock);
    80004d58:	8526                	mv	a0,s1
    80004d5a:	ffffc097          	auipc	ra,0xffffc
    80004d5e:	f6a080e7          	jalr	-150(ra) # 80000cc4 <release>
        return -1;
    80004d62:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004d64:	8562                	mv	a0,s8
    80004d66:	70e6                	ld	ra,120(sp)
    80004d68:	7446                	ld	s0,112(sp)
    80004d6a:	74a6                	ld	s1,104(sp)
    80004d6c:	7906                	ld	s2,96(sp)
    80004d6e:	69e6                	ld	s3,88(sp)
    80004d70:	6a46                	ld	s4,80(sp)
    80004d72:	6aa6                	ld	s5,72(sp)
    80004d74:	6b06                	ld	s6,64(sp)
    80004d76:	7be2                	ld	s7,56(sp)
    80004d78:	7c42                	ld	s8,48(sp)
    80004d7a:	7ca2                	ld	s9,40(sp)
    80004d7c:	7d02                	ld	s10,32(sp)
    80004d7e:	6de2                	ld	s11,24(sp)
    80004d80:	6109                	addi	sp,sp,128
    80004d82:	8082                	ret
  for(i = 0; i < n; i++){
    80004d84:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004d86:	21848513          	addi	a0,s1,536
    80004d8a:	ffffe097          	auipc	ra,0xffffe
    80004d8e:	928080e7          	jalr	-1752(ra) # 800026b2 <wakeup>
  release(&pi->lock);
    80004d92:	8526                	mv	a0,s1
    80004d94:	ffffc097          	auipc	ra,0xffffc
    80004d98:	f30080e7          	jalr	-208(ra) # 80000cc4 <release>
  return i;
    80004d9c:	b7e1                	j	80004d64 <pipewrite+0xea>

0000000080004d9e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d9e:	715d                	addi	sp,sp,-80
    80004da0:	e486                	sd	ra,72(sp)
    80004da2:	e0a2                	sd	s0,64(sp)
    80004da4:	fc26                	sd	s1,56(sp)
    80004da6:	f84a                	sd	s2,48(sp)
    80004da8:	f44e                	sd	s3,40(sp)
    80004daa:	f052                	sd	s4,32(sp)
    80004dac:	ec56                	sd	s5,24(sp)
    80004dae:	e85a                	sd	s6,16(sp)
    80004db0:	0880                	addi	s0,sp,80
    80004db2:	84aa                	mv	s1,a0
    80004db4:	892e                	mv	s2,a1
    80004db6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004db8:	ffffd097          	auipc	ra,0xffffd
    80004dbc:	d66080e7          	jalr	-666(ra) # 80001b1e <myproc>
    80004dc0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004dc2:	8b26                	mv	s6,s1
    80004dc4:	8526                	mv	a0,s1
    80004dc6:	ffffc097          	auipc	ra,0xffffc
    80004dca:	e4a080e7          	jalr	-438(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dce:	2184a703          	lw	a4,536(s1)
    80004dd2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dd6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dda:	02f71463          	bne	a4,a5,80004e02 <piperead+0x64>
    80004dde:	2244a783          	lw	a5,548(s1)
    80004de2:	c385                	beqz	a5,80004e02 <piperead+0x64>
    if(pr->killed){
    80004de4:	038a2783          	lw	a5,56(s4)
    80004de8:	ebc1                	bnez	a5,80004e78 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dea:	85da                	mv	a1,s6
    80004dec:	854e                	mv	a0,s3
    80004dee:	ffffd097          	auipc	ra,0xffffd
    80004df2:	73e080e7          	jalr	1854(ra) # 8000252c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004df6:	2184a703          	lw	a4,536(s1)
    80004dfa:	21c4a783          	lw	a5,540(s1)
    80004dfe:	fef700e3          	beq	a4,a5,80004dde <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e02:	09505263          	blez	s5,80004e86 <piperead+0xe8>
    80004e06:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e08:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004e0a:	2184a783          	lw	a5,536(s1)
    80004e0e:	21c4a703          	lw	a4,540(s1)
    80004e12:	02f70d63          	beq	a4,a5,80004e4c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e16:	0017871b          	addiw	a4,a5,1
    80004e1a:	20e4ac23          	sw	a4,536(s1)
    80004e1e:	1ff7f793          	andi	a5,a5,511
    80004e22:	97a6                	add	a5,a5,s1
    80004e24:	0187c783          	lbu	a5,24(a5)
    80004e28:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e2c:	4685                	li	a3,1
    80004e2e:	fbf40613          	addi	a2,s0,-65
    80004e32:	85ca                	mv	a1,s2
    80004e34:	058a3503          	ld	a0,88(s4)
    80004e38:	ffffd097          	auipc	ra,0xffffd
    80004e3c:	8aa080e7          	jalr	-1878(ra) # 800016e2 <copyout>
    80004e40:	01650663          	beq	a0,s6,80004e4c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e44:	2985                	addiw	s3,s3,1
    80004e46:	0905                	addi	s2,s2,1
    80004e48:	fd3a91e3          	bne	s5,s3,80004e0a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e4c:	21c48513          	addi	a0,s1,540
    80004e50:	ffffe097          	auipc	ra,0xffffe
    80004e54:	862080e7          	jalr	-1950(ra) # 800026b2 <wakeup>
  release(&pi->lock);
    80004e58:	8526                	mv	a0,s1
    80004e5a:	ffffc097          	auipc	ra,0xffffc
    80004e5e:	e6a080e7          	jalr	-406(ra) # 80000cc4 <release>
  return i;
}
    80004e62:	854e                	mv	a0,s3
    80004e64:	60a6                	ld	ra,72(sp)
    80004e66:	6406                	ld	s0,64(sp)
    80004e68:	74e2                	ld	s1,56(sp)
    80004e6a:	7942                	ld	s2,48(sp)
    80004e6c:	79a2                	ld	s3,40(sp)
    80004e6e:	7a02                	ld	s4,32(sp)
    80004e70:	6ae2                	ld	s5,24(sp)
    80004e72:	6b42                	ld	s6,16(sp)
    80004e74:	6161                	addi	sp,sp,80
    80004e76:	8082                	ret
      release(&pi->lock);
    80004e78:	8526                	mv	a0,s1
    80004e7a:	ffffc097          	auipc	ra,0xffffc
    80004e7e:	e4a080e7          	jalr	-438(ra) # 80000cc4 <release>
      return -1;
    80004e82:	59fd                	li	s3,-1
    80004e84:	bff9                	j	80004e62 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e86:	4981                	li	s3,0
    80004e88:	b7d1                	j	80004e4c <piperead+0xae>

0000000080004e8a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e8a:	df010113          	addi	sp,sp,-528
    80004e8e:	20113423          	sd	ra,520(sp)
    80004e92:	20813023          	sd	s0,512(sp)
    80004e96:	ffa6                	sd	s1,504(sp)
    80004e98:	fbca                	sd	s2,496(sp)
    80004e9a:	f7ce                	sd	s3,488(sp)
    80004e9c:	f3d2                	sd	s4,480(sp)
    80004e9e:	efd6                	sd	s5,472(sp)
    80004ea0:	ebda                	sd	s6,464(sp)
    80004ea2:	e7de                	sd	s7,456(sp)
    80004ea4:	e3e2                	sd	s8,448(sp)
    80004ea6:	ff66                	sd	s9,440(sp)
    80004ea8:	fb6a                	sd	s10,432(sp)
    80004eaa:	f76e                	sd	s11,424(sp)
    80004eac:	0c00                	addi	s0,sp,528
    80004eae:	84aa                	mv	s1,a0
    80004eb0:	dea43c23          	sd	a0,-520(s0)
    80004eb4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004eb8:	ffffd097          	auipc	ra,0xffffd
    80004ebc:	c66080e7          	jalr	-922(ra) # 80001b1e <myproc>
    80004ec0:	892a                	mv	s2,a0

  begin_op();
    80004ec2:	fffff097          	auipc	ra,0xfffff
    80004ec6:	446080e7          	jalr	1094(ra) # 80004308 <begin_op>

  if((ip = namei(path)) == 0){
    80004eca:	8526                	mv	a0,s1
    80004ecc:	fffff097          	auipc	ra,0xfffff
    80004ed0:	230080e7          	jalr	560(ra) # 800040fc <namei>
    80004ed4:	c92d                	beqz	a0,80004f46 <exec+0xbc>
    80004ed6:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	a74080e7          	jalr	-1420(ra) # 8000394c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ee0:	04000713          	li	a4,64
    80004ee4:	4681                	li	a3,0
    80004ee6:	e4840613          	addi	a2,s0,-440
    80004eea:	4581                	li	a1,0
    80004eec:	8526                	mv	a0,s1
    80004eee:	fffff097          	auipc	ra,0xfffff
    80004ef2:	d12080e7          	jalr	-750(ra) # 80003c00 <readi>
    80004ef6:	04000793          	li	a5,64
    80004efa:	00f51a63          	bne	a0,a5,80004f0e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004efe:	e4842703          	lw	a4,-440(s0)
    80004f02:	464c47b7          	lui	a5,0x464c4
    80004f06:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f0a:	04f70463          	beq	a4,a5,80004f52 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f0e:	8526                	mv	a0,s1
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	c9e080e7          	jalr	-866(ra) # 80003bae <iunlockput>
    end_op();
    80004f18:	fffff097          	auipc	ra,0xfffff
    80004f1c:	470080e7          	jalr	1136(ra) # 80004388 <end_op>
  }
  return -1;
    80004f20:	557d                	li	a0,-1
}
    80004f22:	20813083          	ld	ra,520(sp)
    80004f26:	20013403          	ld	s0,512(sp)
    80004f2a:	74fe                	ld	s1,504(sp)
    80004f2c:	795e                	ld	s2,496(sp)
    80004f2e:	79be                	ld	s3,488(sp)
    80004f30:	7a1e                	ld	s4,480(sp)
    80004f32:	6afe                	ld	s5,472(sp)
    80004f34:	6b5e                	ld	s6,464(sp)
    80004f36:	6bbe                	ld	s7,456(sp)
    80004f38:	6c1e                	ld	s8,448(sp)
    80004f3a:	7cfa                	ld	s9,440(sp)
    80004f3c:	7d5a                	ld	s10,432(sp)
    80004f3e:	7dba                	ld	s11,424(sp)
    80004f40:	21010113          	addi	sp,sp,528
    80004f44:	8082                	ret
    end_op();
    80004f46:	fffff097          	auipc	ra,0xfffff
    80004f4a:	442080e7          	jalr	1090(ra) # 80004388 <end_op>
    return -1;
    80004f4e:	557d                	li	a0,-1
    80004f50:	bfc9                	j	80004f22 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f52:	854a                	mv	a0,s2
    80004f54:	ffffd097          	auipc	ra,0xffffd
    80004f58:	d32080e7          	jalr	-718(ra) # 80001c86 <proc_pagetable>
    80004f5c:	8baa                	mv	s7,a0
    80004f5e:	d945                	beqz	a0,80004f0e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f60:	e6842983          	lw	s3,-408(s0)
    80004f64:	e8045783          	lhu	a5,-384(s0)
    80004f68:	c7ad                	beqz	a5,80004fd2 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f6a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f6c:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004f6e:	6c85                	lui	s9,0x1
    80004f70:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f74:	def43823          	sd	a5,-528(s0)
    80004f78:	a4bd                	j	800051e6 <exec+0x35c>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f7a:	00003517          	auipc	a0,0x3
    80004f7e:	7c650513          	addi	a0,a0,1990 # 80008740 <syscalls+0x290>
    80004f82:	ffffb097          	auipc	ra,0xffffb
    80004f86:	5c6080e7          	jalr	1478(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f8a:	8756                	mv	a4,s5
    80004f8c:	012d86bb          	addw	a3,s11,s2
    80004f90:	4581                	li	a1,0
    80004f92:	8526                	mv	a0,s1
    80004f94:	fffff097          	auipc	ra,0xfffff
    80004f98:	c6c080e7          	jalr	-916(ra) # 80003c00 <readi>
    80004f9c:	2501                	sext.w	a0,a0
    80004f9e:	1eaa9b63          	bne	s5,a0,80005194 <exec+0x30a>
  for(i = 0; i < sz; i += PGSIZE){
    80004fa2:	6785                	lui	a5,0x1
    80004fa4:	0127893b          	addw	s2,a5,s2
    80004fa8:	77fd                	lui	a5,0xfffff
    80004faa:	01478a3b          	addw	s4,a5,s4
    80004fae:	23897363          	bgeu	s2,s8,800051d4 <exec+0x34a>
    pa = walkaddr(pagetable, va + i);
    80004fb2:	02091593          	slli	a1,s2,0x20
    80004fb6:	9181                	srli	a1,a1,0x20
    80004fb8:	95ea                	add	a1,a1,s10
    80004fba:	855e                	mv	a0,s7
    80004fbc:	ffffc097          	auipc	ra,0xffffc
    80004fc0:	0ea080e7          	jalr	234(ra) # 800010a6 <walkaddr>
    80004fc4:	862a                	mv	a2,a0
    if(pa == 0)
    80004fc6:	d955                	beqz	a0,80004f7a <exec+0xf0>
      n = PGSIZE;
    80004fc8:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004fca:	fd9a70e3          	bgeu	s4,s9,80004f8a <exec+0x100>
      n = sz - i;
    80004fce:	8ad2                	mv	s5,s4
    80004fd0:	bf6d                	j	80004f8a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004fd2:	4901                	li	s2,0
  iunlockput(ip);
    80004fd4:	8526                	mv	a0,s1
    80004fd6:	fffff097          	auipc	ra,0xfffff
    80004fda:	bd8080e7          	jalr	-1064(ra) # 80003bae <iunlockput>
  end_op();
    80004fde:	fffff097          	auipc	ra,0xfffff
    80004fe2:	3aa080e7          	jalr	938(ra) # 80004388 <end_op>
  p = myproc();
    80004fe6:	ffffd097          	auipc	ra,0xffffd
    80004fea:	b38080e7          	jalr	-1224(ra) # 80001b1e <myproc>
    80004fee:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004ff0:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80004ff4:	6785                	lui	a5,0x1
    80004ff6:	17fd                	addi	a5,a5,-1
    80004ff8:	993e                	add	s2,s2,a5
    80004ffa:	757d                	lui	a0,0xfffff
    80004ffc:	00a977b3          	and	a5,s2,a0
    80005000:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005004:	6609                	lui	a2,0x2
    80005006:	963e                	add	a2,a2,a5
    80005008:	85be                	mv	a1,a5
    8000500a:	855e                	mv	a0,s7
    8000500c:	ffffc097          	auipc	ra,0xffffc
    80005010:	486080e7          	jalr	1158(ra) # 80001492 <uvmalloc>
    80005014:	8b2a                	mv	s6,a0
  ip = 0;
    80005016:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005018:	16050e63          	beqz	a0,80005194 <exec+0x30a>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000501c:	75f9                	lui	a1,0xffffe
    8000501e:	95aa                	add	a1,a1,a0
    80005020:	855e                	mv	a0,s7
    80005022:	ffffc097          	auipc	ra,0xffffc
    80005026:	68e080e7          	jalr	1678(ra) # 800016b0 <uvmclear>
  stackbase = sp - PGSIZE;
    8000502a:	7c7d                	lui	s8,0xfffff
    8000502c:	9c5a                	add	s8,s8,s6
  u2kvmcopy(pagetable, p->kpagetable, 0, sz);
    8000502e:	86da                	mv	a3,s6
    80005030:	4601                	li	a2,0
    80005032:	018ab583          	ld	a1,24(s5)
    80005036:	855e                	mv	a0,s7
    80005038:	ffffd097          	auipc	ra,0xffffd
    8000503c:	974080e7          	jalr	-1676(ra) # 800019ac <u2kvmcopy>
  if(p->pid == 1)
    80005040:	040aa703          	lw	a4,64(s5)
    80005044:	4785                	li	a5,1
    80005046:	06f70c63          	beq	a4,a5,800050be <exec+0x234>
  for(argc = 0; argv[argc]; argc++) {
    8000504a:	e0043783          	ld	a5,-512(s0)
    8000504e:	6388                	ld	a0,0(a5)
    80005050:	cd35                	beqz	a0,800050cc <exec+0x242>
    80005052:	e8840993          	addi	s3,s0,-376
    80005056:	f8840c93          	addi	s9,s0,-120
    8000505a:	895a                	mv	s2,s6
    8000505c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	e36080e7          	jalr	-458(ra) # 80000e94 <strlen>
    80005066:	2505                	addiw	a0,a0,1
    80005068:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000506c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005070:	15896663          	bltu	s2,s8,800051bc <exec+0x332>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005074:	e0043d83          	ld	s11,-512(s0)
    80005078:	000dba03          	ld	s4,0(s11)
    8000507c:	8552                	mv	a0,s4
    8000507e:	ffffc097          	auipc	ra,0xffffc
    80005082:	e16080e7          	jalr	-490(ra) # 80000e94 <strlen>
    80005086:	0015069b          	addiw	a3,a0,1
    8000508a:	8652                	mv	a2,s4
    8000508c:	85ca                	mv	a1,s2
    8000508e:	855e                	mv	a0,s7
    80005090:	ffffc097          	auipc	ra,0xffffc
    80005094:	652080e7          	jalr	1618(ra) # 800016e2 <copyout>
    80005098:	12054663          	bltz	a0,800051c4 <exec+0x33a>
    ustack[argc] = sp;
    8000509c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050a0:	0485                	addi	s1,s1,1
    800050a2:	008d8793          	addi	a5,s11,8
    800050a6:	e0f43023          	sd	a5,-512(s0)
    800050aa:	008db503          	ld	a0,8(s11)
    800050ae:	c10d                	beqz	a0,800050d0 <exec+0x246>
    if(argc >= MAXARG)
    800050b0:	09a1                	addi	s3,s3,8
    800050b2:	fb3c96e3          	bne	s9,s3,8000505e <exec+0x1d4>
  sz = sz1;
    800050b6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050ba:	4481                	li	s1,0
    800050bc:	a8e1                	j	80005194 <exec+0x30a>
    vmprint(p->pagetable);
    800050be:	058ab503          	ld	a0,88(s5)
    800050c2:	ffffc097          	auipc	ra,0xffffc
    800050c6:	7a4080e7          	jalr	1956(ra) # 80001866 <vmprint>
    800050ca:	b741                	j	8000504a <exec+0x1c0>
  for(argc = 0; argv[argc]; argc++) {
    800050cc:	895a                	mv	s2,s6
    800050ce:	4481                	li	s1,0
  ustack[argc] = 0;
    800050d0:	00349793          	slli	a5,s1,0x3
    800050d4:	f9040713          	addi	a4,s0,-112
    800050d8:	97ba                	add	a5,a5,a4
    800050da:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    800050de:	00148693          	addi	a3,s1,1
    800050e2:	068e                	slli	a3,a3,0x3
    800050e4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050e8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050ec:	01897663          	bgeu	s2,s8,800050f8 <exec+0x26e>
  sz = sz1;
    800050f0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050f4:	4481                	li	s1,0
    800050f6:	a879                	j	80005194 <exec+0x30a>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050f8:	e8840613          	addi	a2,s0,-376
    800050fc:	85ca                	mv	a1,s2
    800050fe:	855e                	mv	a0,s7
    80005100:	ffffc097          	auipc	ra,0xffffc
    80005104:	5e2080e7          	jalr	1506(ra) # 800016e2 <copyout>
    80005108:	0c054263          	bltz	a0,800051cc <exec+0x342>
  p->trapframe->a1 = sp;
    8000510c:	060ab783          	ld	a5,96(s5)
    80005110:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005114:	df843783          	ld	a5,-520(s0)
    80005118:	0007c703          	lbu	a4,0(a5)
    8000511c:	cf11                	beqz	a4,80005138 <exec+0x2ae>
    8000511e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005120:	02f00693          	li	a3,47
    80005124:	a039                	j	80005132 <exec+0x2a8>
      last = s+1;
    80005126:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000512a:	0785                	addi	a5,a5,1
    8000512c:	fff7c703          	lbu	a4,-1(a5)
    80005130:	c701                	beqz	a4,80005138 <exec+0x2ae>
    if(*s == '/')
    80005132:	fed71ce3          	bne	a4,a3,8000512a <exec+0x2a0>
    80005136:	bfc5                	j	80005126 <exec+0x29c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005138:	4641                	li	a2,16
    8000513a:	df843583          	ld	a1,-520(s0)
    8000513e:	160a8513          	addi	a0,s5,352
    80005142:	ffffc097          	auipc	ra,0xffffc
    80005146:	d20080e7          	jalr	-736(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    8000514a:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    8000514e:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    80005152:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005156:	060ab783          	ld	a5,96(s5)
    8000515a:	e6043703          	ld	a4,-416(s0)
    8000515e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005160:	060ab783          	ld	a5,96(s5)
    80005164:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005168:	85ea                	mv	a1,s10
    8000516a:	ffffd097          	auipc	ra,0xffffd
    8000516e:	bb8080e7          	jalr	-1096(ra) # 80001d22 <proc_freepagetable>
  if (p->pid == 1) { vmprint(p->pagetable); }
    80005172:	040aa703          	lw	a4,64(s5)
    80005176:	4785                	li	a5,1
    80005178:	00f70563          	beq	a4,a5,80005182 <exec+0x2f8>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000517c:	0004851b          	sext.w	a0,s1
    80005180:	b34d                	j	80004f22 <exec+0x98>
  if (p->pid == 1) { vmprint(p->pagetable); }
    80005182:	058ab503          	ld	a0,88(s5)
    80005186:	ffffc097          	auipc	ra,0xffffc
    8000518a:	6e0080e7          	jalr	1760(ra) # 80001866 <vmprint>
    8000518e:	b7fd                	j	8000517c <exec+0x2f2>
    80005190:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005194:	e0843583          	ld	a1,-504(s0)
    80005198:	855e                	mv	a0,s7
    8000519a:	ffffd097          	auipc	ra,0xffffd
    8000519e:	b88080e7          	jalr	-1144(ra) # 80001d22 <proc_freepagetable>
  if(ip){
    800051a2:	d60496e3          	bnez	s1,80004f0e <exec+0x84>
  return -1;
    800051a6:	557d                	li	a0,-1
    800051a8:	bbad                	j	80004f22 <exec+0x98>
    800051aa:	e1243423          	sd	s2,-504(s0)
    800051ae:	b7dd                	j	80005194 <exec+0x30a>
    800051b0:	e1243423          	sd	s2,-504(s0)
    800051b4:	b7c5                	j	80005194 <exec+0x30a>
    800051b6:	e1243423          	sd	s2,-504(s0)
    800051ba:	bfe9                	j	80005194 <exec+0x30a>
  sz = sz1;
    800051bc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051c0:	4481                	li	s1,0
    800051c2:	bfc9                	j	80005194 <exec+0x30a>
  sz = sz1;
    800051c4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051c8:	4481                	li	s1,0
    800051ca:	b7e9                	j	80005194 <exec+0x30a>
  sz = sz1;
    800051cc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051d0:	4481                	li	s1,0
    800051d2:	b7c9                	j	80005194 <exec+0x30a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051d4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051d8:	2b05                	addiw	s6,s6,1
    800051da:	0389899b          	addiw	s3,s3,56
    800051de:	e8045783          	lhu	a5,-384(s0)
    800051e2:	defb59e3          	bge	s6,a5,80004fd4 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051e6:	2981                	sext.w	s3,s3
    800051e8:	03800713          	li	a4,56
    800051ec:	86ce                	mv	a3,s3
    800051ee:	e1040613          	addi	a2,s0,-496
    800051f2:	4581                	li	a1,0
    800051f4:	8526                	mv	a0,s1
    800051f6:	fffff097          	auipc	ra,0xfffff
    800051fa:	a0a080e7          	jalr	-1526(ra) # 80003c00 <readi>
    800051fe:	03800793          	li	a5,56
    80005202:	f8f517e3          	bne	a0,a5,80005190 <exec+0x306>
    if(ph.type != ELF_PROG_LOAD)
    80005206:	e1042783          	lw	a5,-496(s0)
    8000520a:	4705                	li	a4,1
    8000520c:	fce796e3          	bne	a5,a4,800051d8 <exec+0x34e>
    if(ph.memsz < ph.filesz)
    80005210:	e3843603          	ld	a2,-456(s0)
    80005214:	e3043783          	ld	a5,-464(s0)
    80005218:	f8f669e3          	bltu	a2,a5,800051aa <exec+0x320>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000521c:	e2043783          	ld	a5,-480(s0)
    80005220:	963e                	add	a2,a2,a5
    80005222:	f8f667e3          	bltu	a2,a5,800051b0 <exec+0x326>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005226:	85ca                	mv	a1,s2
    80005228:	855e                	mv	a0,s7
    8000522a:	ffffc097          	auipc	ra,0xffffc
    8000522e:	268080e7          	jalr	616(ra) # 80001492 <uvmalloc>
    80005232:	e0a43423          	sd	a0,-504(s0)
    80005236:	fff50713          	addi	a4,a0,-1 # ffffffffffffefff <end+0xffffffff7ffd7fdf>
    8000523a:	0c0007b7          	lui	a5,0xc000
    8000523e:	f6f77ce3          	bgeu	a4,a5,800051b6 <exec+0x32c>
    if(ph.vaddr % PGSIZE != 0)
    80005242:	e2043d03          	ld	s10,-480(s0)
    80005246:	df043783          	ld	a5,-528(s0)
    8000524a:	00fd77b3          	and	a5,s10,a5
    8000524e:	f3b9                	bnez	a5,80005194 <exec+0x30a>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005250:	e1842d83          	lw	s11,-488(s0)
    80005254:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005258:	f60c0ee3          	beqz	s8,800051d4 <exec+0x34a>
    8000525c:	8a62                	mv	s4,s8
    8000525e:	4901                	li	s2,0
    80005260:	bb89                	j	80004fb2 <exec+0x128>

0000000080005262 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005262:	7179                	addi	sp,sp,-48
    80005264:	f406                	sd	ra,40(sp)
    80005266:	f022                	sd	s0,32(sp)
    80005268:	ec26                	sd	s1,24(sp)
    8000526a:	e84a                	sd	s2,16(sp)
    8000526c:	1800                	addi	s0,sp,48
    8000526e:	892e                	mv	s2,a1
    80005270:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005272:	fdc40593          	addi	a1,s0,-36
    80005276:	ffffe097          	auipc	ra,0xffffe
    8000527a:	b64080e7          	jalr	-1180(ra) # 80002dda <argint>
    8000527e:	04054063          	bltz	a0,800052be <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005282:	fdc42703          	lw	a4,-36(s0)
    80005286:	47bd                	li	a5,15
    80005288:	02e7ed63          	bltu	a5,a4,800052c2 <argfd+0x60>
    8000528c:	ffffd097          	auipc	ra,0xffffd
    80005290:	892080e7          	jalr	-1902(ra) # 80001b1e <myproc>
    80005294:	fdc42703          	lw	a4,-36(s0)
    80005298:	01a70793          	addi	a5,a4,26
    8000529c:	078e                	slli	a5,a5,0x3
    8000529e:	953e                	add	a0,a0,a5
    800052a0:	651c                	ld	a5,8(a0)
    800052a2:	c395                	beqz	a5,800052c6 <argfd+0x64>
    return -1;
  if(pfd)
    800052a4:	00090463          	beqz	s2,800052ac <argfd+0x4a>
    *pfd = fd;
    800052a8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052ac:	4501                	li	a0,0
  if(pf)
    800052ae:	c091                	beqz	s1,800052b2 <argfd+0x50>
    *pf = f;
    800052b0:	e09c                	sd	a5,0(s1)
}
    800052b2:	70a2                	ld	ra,40(sp)
    800052b4:	7402                	ld	s0,32(sp)
    800052b6:	64e2                	ld	s1,24(sp)
    800052b8:	6942                	ld	s2,16(sp)
    800052ba:	6145                	addi	sp,sp,48
    800052bc:	8082                	ret
    return -1;
    800052be:	557d                	li	a0,-1
    800052c0:	bfcd                	j	800052b2 <argfd+0x50>
    return -1;
    800052c2:	557d                	li	a0,-1
    800052c4:	b7fd                	j	800052b2 <argfd+0x50>
    800052c6:	557d                	li	a0,-1
    800052c8:	b7ed                	j	800052b2 <argfd+0x50>

00000000800052ca <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052ca:	1101                	addi	sp,sp,-32
    800052cc:	ec06                	sd	ra,24(sp)
    800052ce:	e822                	sd	s0,16(sp)
    800052d0:	e426                	sd	s1,8(sp)
    800052d2:	1000                	addi	s0,sp,32
    800052d4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052d6:	ffffd097          	auipc	ra,0xffffd
    800052da:	848080e7          	jalr	-1976(ra) # 80001b1e <myproc>
    800052de:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052e0:	0d850793          	addi	a5,a0,216
    800052e4:	4501                	li	a0,0
    800052e6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052e8:	6398                	ld	a4,0(a5)
    800052ea:	cb19                	beqz	a4,80005300 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052ec:	2505                	addiw	a0,a0,1
    800052ee:	07a1                	addi	a5,a5,8
    800052f0:	fed51ce3          	bne	a0,a3,800052e8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052f4:	557d                	li	a0,-1
}
    800052f6:	60e2                	ld	ra,24(sp)
    800052f8:	6442                	ld	s0,16(sp)
    800052fa:	64a2                	ld	s1,8(sp)
    800052fc:	6105                	addi	sp,sp,32
    800052fe:	8082                	ret
      p->ofile[fd] = f;
    80005300:	01a50793          	addi	a5,a0,26
    80005304:	078e                	slli	a5,a5,0x3
    80005306:	963e                	add	a2,a2,a5
    80005308:	e604                	sd	s1,8(a2)
      return fd;
    8000530a:	b7f5                	j	800052f6 <fdalloc+0x2c>

000000008000530c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000530c:	715d                	addi	sp,sp,-80
    8000530e:	e486                	sd	ra,72(sp)
    80005310:	e0a2                	sd	s0,64(sp)
    80005312:	fc26                	sd	s1,56(sp)
    80005314:	f84a                	sd	s2,48(sp)
    80005316:	f44e                	sd	s3,40(sp)
    80005318:	f052                	sd	s4,32(sp)
    8000531a:	ec56                	sd	s5,24(sp)
    8000531c:	0880                	addi	s0,sp,80
    8000531e:	89ae                	mv	s3,a1
    80005320:	8ab2                	mv	s5,a2
    80005322:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005324:	fb040593          	addi	a1,s0,-80
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	df2080e7          	jalr	-526(ra) # 8000411a <nameiparent>
    80005330:	892a                	mv	s2,a0
    80005332:	12050f63          	beqz	a0,80005470 <create+0x164>
    return 0;

  ilock(dp);
    80005336:	ffffe097          	auipc	ra,0xffffe
    8000533a:	616080e7          	jalr	1558(ra) # 8000394c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000533e:	4601                	li	a2,0
    80005340:	fb040593          	addi	a1,s0,-80
    80005344:	854a                	mv	a0,s2
    80005346:	fffff097          	auipc	ra,0xfffff
    8000534a:	ae4080e7          	jalr	-1308(ra) # 80003e2a <dirlookup>
    8000534e:	84aa                	mv	s1,a0
    80005350:	c921                	beqz	a0,800053a0 <create+0x94>
    iunlockput(dp);
    80005352:	854a                	mv	a0,s2
    80005354:	fffff097          	auipc	ra,0xfffff
    80005358:	85a080e7          	jalr	-1958(ra) # 80003bae <iunlockput>
    ilock(ip);
    8000535c:	8526                	mv	a0,s1
    8000535e:	ffffe097          	auipc	ra,0xffffe
    80005362:	5ee080e7          	jalr	1518(ra) # 8000394c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005366:	2981                	sext.w	s3,s3
    80005368:	4789                	li	a5,2
    8000536a:	02f99463          	bne	s3,a5,80005392 <create+0x86>
    8000536e:	0444d783          	lhu	a5,68(s1)
    80005372:	37f9                	addiw	a5,a5,-2
    80005374:	17c2                	slli	a5,a5,0x30
    80005376:	93c1                	srli	a5,a5,0x30
    80005378:	4705                	li	a4,1
    8000537a:	00f76c63          	bltu	a4,a5,80005392 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000537e:	8526                	mv	a0,s1
    80005380:	60a6                	ld	ra,72(sp)
    80005382:	6406                	ld	s0,64(sp)
    80005384:	74e2                	ld	s1,56(sp)
    80005386:	7942                	ld	s2,48(sp)
    80005388:	79a2                	ld	s3,40(sp)
    8000538a:	7a02                	ld	s4,32(sp)
    8000538c:	6ae2                	ld	s5,24(sp)
    8000538e:	6161                	addi	sp,sp,80
    80005390:	8082                	ret
    iunlockput(ip);
    80005392:	8526                	mv	a0,s1
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	81a080e7          	jalr	-2022(ra) # 80003bae <iunlockput>
    return 0;
    8000539c:	4481                	li	s1,0
    8000539e:	b7c5                	j	8000537e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800053a0:	85ce                	mv	a1,s3
    800053a2:	00092503          	lw	a0,0(s2)
    800053a6:	ffffe097          	auipc	ra,0xffffe
    800053aa:	40e080e7          	jalr	1038(ra) # 800037b4 <ialloc>
    800053ae:	84aa                	mv	s1,a0
    800053b0:	c529                	beqz	a0,800053fa <create+0xee>
  ilock(ip);
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	59a080e7          	jalr	1434(ra) # 8000394c <ilock>
  ip->major = major;
    800053ba:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800053be:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800053c2:	4785                	li	a5,1
    800053c4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053c8:	8526                	mv	a0,s1
    800053ca:	ffffe097          	auipc	ra,0xffffe
    800053ce:	4b8080e7          	jalr	1208(ra) # 80003882 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053d2:	2981                	sext.w	s3,s3
    800053d4:	4785                	li	a5,1
    800053d6:	02f98a63          	beq	s3,a5,8000540a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800053da:	40d0                	lw	a2,4(s1)
    800053dc:	fb040593          	addi	a1,s0,-80
    800053e0:	854a                	mv	a0,s2
    800053e2:	fffff097          	auipc	ra,0xfffff
    800053e6:	c58080e7          	jalr	-936(ra) # 8000403a <dirlink>
    800053ea:	06054b63          	bltz	a0,80005460 <create+0x154>
  iunlockput(dp);
    800053ee:	854a                	mv	a0,s2
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	7be080e7          	jalr	1982(ra) # 80003bae <iunlockput>
  return ip;
    800053f8:	b759                	j	8000537e <create+0x72>
    panic("create: ialloc");
    800053fa:	00003517          	auipc	a0,0x3
    800053fe:	36650513          	addi	a0,a0,870 # 80008760 <syscalls+0x2b0>
    80005402:	ffffb097          	auipc	ra,0xffffb
    80005406:	146080e7          	jalr	326(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    8000540a:	04a95783          	lhu	a5,74(s2)
    8000540e:	2785                	addiw	a5,a5,1
    80005410:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005414:	854a                	mv	a0,s2
    80005416:	ffffe097          	auipc	ra,0xffffe
    8000541a:	46c080e7          	jalr	1132(ra) # 80003882 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000541e:	40d0                	lw	a2,4(s1)
    80005420:	00003597          	auipc	a1,0x3
    80005424:	35058593          	addi	a1,a1,848 # 80008770 <syscalls+0x2c0>
    80005428:	8526                	mv	a0,s1
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	c10080e7          	jalr	-1008(ra) # 8000403a <dirlink>
    80005432:	00054f63          	bltz	a0,80005450 <create+0x144>
    80005436:	00492603          	lw	a2,4(s2)
    8000543a:	00003597          	auipc	a1,0x3
    8000543e:	d9658593          	addi	a1,a1,-618 # 800081d0 <digits+0x190>
    80005442:	8526                	mv	a0,s1
    80005444:	fffff097          	auipc	ra,0xfffff
    80005448:	bf6080e7          	jalr	-1034(ra) # 8000403a <dirlink>
    8000544c:	f80557e3          	bgez	a0,800053da <create+0xce>
      panic("create dots");
    80005450:	00003517          	auipc	a0,0x3
    80005454:	32850513          	addi	a0,a0,808 # 80008778 <syscalls+0x2c8>
    80005458:	ffffb097          	auipc	ra,0xffffb
    8000545c:	0f0080e7          	jalr	240(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005460:	00003517          	auipc	a0,0x3
    80005464:	32850513          	addi	a0,a0,808 # 80008788 <syscalls+0x2d8>
    80005468:	ffffb097          	auipc	ra,0xffffb
    8000546c:	0e0080e7          	jalr	224(ra) # 80000548 <panic>
    return 0;
    80005470:	84aa                	mv	s1,a0
    80005472:	b731                	j	8000537e <create+0x72>

0000000080005474 <sys_dup>:
{
    80005474:	7179                	addi	sp,sp,-48
    80005476:	f406                	sd	ra,40(sp)
    80005478:	f022                	sd	s0,32(sp)
    8000547a:	ec26                	sd	s1,24(sp)
    8000547c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000547e:	fd840613          	addi	a2,s0,-40
    80005482:	4581                	li	a1,0
    80005484:	4501                	li	a0,0
    80005486:	00000097          	auipc	ra,0x0
    8000548a:	ddc080e7          	jalr	-548(ra) # 80005262 <argfd>
    return -1;
    8000548e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005490:	02054363          	bltz	a0,800054b6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005494:	fd843503          	ld	a0,-40(s0)
    80005498:	00000097          	auipc	ra,0x0
    8000549c:	e32080e7          	jalr	-462(ra) # 800052ca <fdalloc>
    800054a0:	84aa                	mv	s1,a0
    return -1;
    800054a2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800054a4:	00054963          	bltz	a0,800054b6 <sys_dup+0x42>
  filedup(f);
    800054a8:	fd843503          	ld	a0,-40(s0)
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	2dc080e7          	jalr	732(ra) # 80004788 <filedup>
  return fd;
    800054b4:	87a6                	mv	a5,s1
}
    800054b6:	853e                	mv	a0,a5
    800054b8:	70a2                	ld	ra,40(sp)
    800054ba:	7402                	ld	s0,32(sp)
    800054bc:	64e2                	ld	s1,24(sp)
    800054be:	6145                	addi	sp,sp,48
    800054c0:	8082                	ret

00000000800054c2 <sys_read>:
{
    800054c2:	7179                	addi	sp,sp,-48
    800054c4:	f406                	sd	ra,40(sp)
    800054c6:	f022                	sd	s0,32(sp)
    800054c8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ca:	fe840613          	addi	a2,s0,-24
    800054ce:	4581                	li	a1,0
    800054d0:	4501                	li	a0,0
    800054d2:	00000097          	auipc	ra,0x0
    800054d6:	d90080e7          	jalr	-624(ra) # 80005262 <argfd>
    return -1;
    800054da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054dc:	04054163          	bltz	a0,8000551e <sys_read+0x5c>
    800054e0:	fe440593          	addi	a1,s0,-28
    800054e4:	4509                	li	a0,2
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	8f4080e7          	jalr	-1804(ra) # 80002dda <argint>
    return -1;
    800054ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054f0:	02054763          	bltz	a0,8000551e <sys_read+0x5c>
    800054f4:	fd840593          	addi	a1,s0,-40
    800054f8:	4505                	li	a0,1
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	902080e7          	jalr	-1790(ra) # 80002dfc <argaddr>
    return -1;
    80005502:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005504:	00054d63          	bltz	a0,8000551e <sys_read+0x5c>
  return fileread(f, p, n);
    80005508:	fe442603          	lw	a2,-28(s0)
    8000550c:	fd843583          	ld	a1,-40(s0)
    80005510:	fe843503          	ld	a0,-24(s0)
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	400080e7          	jalr	1024(ra) # 80004914 <fileread>
    8000551c:	87aa                	mv	a5,a0
}
    8000551e:	853e                	mv	a0,a5
    80005520:	70a2                	ld	ra,40(sp)
    80005522:	7402                	ld	s0,32(sp)
    80005524:	6145                	addi	sp,sp,48
    80005526:	8082                	ret

0000000080005528 <sys_write>:
{
    80005528:	7179                	addi	sp,sp,-48
    8000552a:	f406                	sd	ra,40(sp)
    8000552c:	f022                	sd	s0,32(sp)
    8000552e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005530:	fe840613          	addi	a2,s0,-24
    80005534:	4581                	li	a1,0
    80005536:	4501                	li	a0,0
    80005538:	00000097          	auipc	ra,0x0
    8000553c:	d2a080e7          	jalr	-726(ra) # 80005262 <argfd>
    return -1;
    80005540:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005542:	04054163          	bltz	a0,80005584 <sys_write+0x5c>
    80005546:	fe440593          	addi	a1,s0,-28
    8000554a:	4509                	li	a0,2
    8000554c:	ffffe097          	auipc	ra,0xffffe
    80005550:	88e080e7          	jalr	-1906(ra) # 80002dda <argint>
    return -1;
    80005554:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005556:	02054763          	bltz	a0,80005584 <sys_write+0x5c>
    8000555a:	fd840593          	addi	a1,s0,-40
    8000555e:	4505                	li	a0,1
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	89c080e7          	jalr	-1892(ra) # 80002dfc <argaddr>
    return -1;
    80005568:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000556a:	00054d63          	bltz	a0,80005584 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000556e:	fe442603          	lw	a2,-28(s0)
    80005572:	fd843583          	ld	a1,-40(s0)
    80005576:	fe843503          	ld	a0,-24(s0)
    8000557a:	fffff097          	auipc	ra,0xfffff
    8000557e:	45c080e7          	jalr	1116(ra) # 800049d6 <filewrite>
    80005582:	87aa                	mv	a5,a0
}
    80005584:	853e                	mv	a0,a5
    80005586:	70a2                	ld	ra,40(sp)
    80005588:	7402                	ld	s0,32(sp)
    8000558a:	6145                	addi	sp,sp,48
    8000558c:	8082                	ret

000000008000558e <sys_close>:
{
    8000558e:	1101                	addi	sp,sp,-32
    80005590:	ec06                	sd	ra,24(sp)
    80005592:	e822                	sd	s0,16(sp)
    80005594:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005596:	fe040613          	addi	a2,s0,-32
    8000559a:	fec40593          	addi	a1,s0,-20
    8000559e:	4501                	li	a0,0
    800055a0:	00000097          	auipc	ra,0x0
    800055a4:	cc2080e7          	jalr	-830(ra) # 80005262 <argfd>
    return -1;
    800055a8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800055aa:	02054463          	bltz	a0,800055d2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055ae:	ffffc097          	auipc	ra,0xffffc
    800055b2:	570080e7          	jalr	1392(ra) # 80001b1e <myproc>
    800055b6:	fec42783          	lw	a5,-20(s0)
    800055ba:	07e9                	addi	a5,a5,26
    800055bc:	078e                	slli	a5,a5,0x3
    800055be:	97aa                	add	a5,a5,a0
    800055c0:	0007b423          	sd	zero,8(a5) # c000008 <_entry-0x73fffff8>
  fileclose(f);
    800055c4:	fe043503          	ld	a0,-32(s0)
    800055c8:	fffff097          	auipc	ra,0xfffff
    800055cc:	212080e7          	jalr	530(ra) # 800047da <fileclose>
  return 0;
    800055d0:	4781                	li	a5,0
}
    800055d2:	853e                	mv	a0,a5
    800055d4:	60e2                	ld	ra,24(sp)
    800055d6:	6442                	ld	s0,16(sp)
    800055d8:	6105                	addi	sp,sp,32
    800055da:	8082                	ret

00000000800055dc <sys_fstat>:
{
    800055dc:	1101                	addi	sp,sp,-32
    800055de:	ec06                	sd	ra,24(sp)
    800055e0:	e822                	sd	s0,16(sp)
    800055e2:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055e4:	fe840613          	addi	a2,s0,-24
    800055e8:	4581                	li	a1,0
    800055ea:	4501                	li	a0,0
    800055ec:	00000097          	auipc	ra,0x0
    800055f0:	c76080e7          	jalr	-906(ra) # 80005262 <argfd>
    return -1;
    800055f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055f6:	02054563          	bltz	a0,80005620 <sys_fstat+0x44>
    800055fa:	fe040593          	addi	a1,s0,-32
    800055fe:	4505                	li	a0,1
    80005600:	ffffd097          	auipc	ra,0xffffd
    80005604:	7fc080e7          	jalr	2044(ra) # 80002dfc <argaddr>
    return -1;
    80005608:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000560a:	00054b63          	bltz	a0,80005620 <sys_fstat+0x44>
  return filestat(f, st);
    8000560e:	fe043583          	ld	a1,-32(s0)
    80005612:	fe843503          	ld	a0,-24(s0)
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	28c080e7          	jalr	652(ra) # 800048a2 <filestat>
    8000561e:	87aa                	mv	a5,a0
}
    80005620:	853e                	mv	a0,a5
    80005622:	60e2                	ld	ra,24(sp)
    80005624:	6442                	ld	s0,16(sp)
    80005626:	6105                	addi	sp,sp,32
    80005628:	8082                	ret

000000008000562a <sys_link>:
{
    8000562a:	7169                	addi	sp,sp,-304
    8000562c:	f606                	sd	ra,296(sp)
    8000562e:	f222                	sd	s0,288(sp)
    80005630:	ee26                	sd	s1,280(sp)
    80005632:	ea4a                	sd	s2,272(sp)
    80005634:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005636:	08000613          	li	a2,128
    8000563a:	ed040593          	addi	a1,s0,-304
    8000563e:	4501                	li	a0,0
    80005640:	ffffd097          	auipc	ra,0xffffd
    80005644:	7de080e7          	jalr	2014(ra) # 80002e1e <argstr>
    return -1;
    80005648:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000564a:	10054e63          	bltz	a0,80005766 <sys_link+0x13c>
    8000564e:	08000613          	li	a2,128
    80005652:	f5040593          	addi	a1,s0,-176
    80005656:	4505                	li	a0,1
    80005658:	ffffd097          	auipc	ra,0xffffd
    8000565c:	7c6080e7          	jalr	1990(ra) # 80002e1e <argstr>
    return -1;
    80005660:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005662:	10054263          	bltz	a0,80005766 <sys_link+0x13c>
  begin_op();
    80005666:	fffff097          	auipc	ra,0xfffff
    8000566a:	ca2080e7          	jalr	-862(ra) # 80004308 <begin_op>
  if((ip = namei(old)) == 0){
    8000566e:	ed040513          	addi	a0,s0,-304
    80005672:	fffff097          	auipc	ra,0xfffff
    80005676:	a8a080e7          	jalr	-1398(ra) # 800040fc <namei>
    8000567a:	84aa                	mv	s1,a0
    8000567c:	c551                	beqz	a0,80005708 <sys_link+0xde>
  ilock(ip);
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	2ce080e7          	jalr	718(ra) # 8000394c <ilock>
  if(ip->type == T_DIR){
    80005686:	04449703          	lh	a4,68(s1)
    8000568a:	4785                	li	a5,1
    8000568c:	08f70463          	beq	a4,a5,80005714 <sys_link+0xea>
  ip->nlink++;
    80005690:	04a4d783          	lhu	a5,74(s1)
    80005694:	2785                	addiw	a5,a5,1
    80005696:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000569a:	8526                	mv	a0,s1
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	1e6080e7          	jalr	486(ra) # 80003882 <iupdate>
  iunlock(ip);
    800056a4:	8526                	mv	a0,s1
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	368080e7          	jalr	872(ra) # 80003a0e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056ae:	fd040593          	addi	a1,s0,-48
    800056b2:	f5040513          	addi	a0,s0,-176
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	a64080e7          	jalr	-1436(ra) # 8000411a <nameiparent>
    800056be:	892a                	mv	s2,a0
    800056c0:	c935                	beqz	a0,80005734 <sys_link+0x10a>
  ilock(dp);
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	28a080e7          	jalr	650(ra) # 8000394c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056ca:	00092703          	lw	a4,0(s2)
    800056ce:	409c                	lw	a5,0(s1)
    800056d0:	04f71d63          	bne	a4,a5,8000572a <sys_link+0x100>
    800056d4:	40d0                	lw	a2,4(s1)
    800056d6:	fd040593          	addi	a1,s0,-48
    800056da:	854a                	mv	a0,s2
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	95e080e7          	jalr	-1698(ra) # 8000403a <dirlink>
    800056e4:	04054363          	bltz	a0,8000572a <sys_link+0x100>
  iunlockput(dp);
    800056e8:	854a                	mv	a0,s2
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	4c4080e7          	jalr	1220(ra) # 80003bae <iunlockput>
  iput(ip);
    800056f2:	8526                	mv	a0,s1
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	412080e7          	jalr	1042(ra) # 80003b06 <iput>
  end_op();
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	c8c080e7          	jalr	-884(ra) # 80004388 <end_op>
  return 0;
    80005704:	4781                	li	a5,0
    80005706:	a085                	j	80005766 <sys_link+0x13c>
    end_op();
    80005708:	fffff097          	auipc	ra,0xfffff
    8000570c:	c80080e7          	jalr	-896(ra) # 80004388 <end_op>
    return -1;
    80005710:	57fd                	li	a5,-1
    80005712:	a891                	j	80005766 <sys_link+0x13c>
    iunlockput(ip);
    80005714:	8526                	mv	a0,s1
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	498080e7          	jalr	1176(ra) # 80003bae <iunlockput>
    end_op();
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	c6a080e7          	jalr	-918(ra) # 80004388 <end_op>
    return -1;
    80005726:	57fd                	li	a5,-1
    80005728:	a83d                	j	80005766 <sys_link+0x13c>
    iunlockput(dp);
    8000572a:	854a                	mv	a0,s2
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	482080e7          	jalr	1154(ra) # 80003bae <iunlockput>
  ilock(ip);
    80005734:	8526                	mv	a0,s1
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	216080e7          	jalr	534(ra) # 8000394c <ilock>
  ip->nlink--;
    8000573e:	04a4d783          	lhu	a5,74(s1)
    80005742:	37fd                	addiw	a5,a5,-1
    80005744:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005748:	8526                	mv	a0,s1
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	138080e7          	jalr	312(ra) # 80003882 <iupdate>
  iunlockput(ip);
    80005752:	8526                	mv	a0,s1
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	45a080e7          	jalr	1114(ra) # 80003bae <iunlockput>
  end_op();
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	c2c080e7          	jalr	-980(ra) # 80004388 <end_op>
  return -1;
    80005764:	57fd                	li	a5,-1
}
    80005766:	853e                	mv	a0,a5
    80005768:	70b2                	ld	ra,296(sp)
    8000576a:	7412                	ld	s0,288(sp)
    8000576c:	64f2                	ld	s1,280(sp)
    8000576e:	6952                	ld	s2,272(sp)
    80005770:	6155                	addi	sp,sp,304
    80005772:	8082                	ret

0000000080005774 <sys_unlink>:
{
    80005774:	7151                	addi	sp,sp,-240
    80005776:	f586                	sd	ra,232(sp)
    80005778:	f1a2                	sd	s0,224(sp)
    8000577a:	eda6                	sd	s1,216(sp)
    8000577c:	e9ca                	sd	s2,208(sp)
    8000577e:	e5ce                	sd	s3,200(sp)
    80005780:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005782:	08000613          	li	a2,128
    80005786:	f3040593          	addi	a1,s0,-208
    8000578a:	4501                	li	a0,0
    8000578c:	ffffd097          	auipc	ra,0xffffd
    80005790:	692080e7          	jalr	1682(ra) # 80002e1e <argstr>
    80005794:	18054163          	bltz	a0,80005916 <sys_unlink+0x1a2>
  begin_op();
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	b70080e7          	jalr	-1168(ra) # 80004308 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057a0:	fb040593          	addi	a1,s0,-80
    800057a4:	f3040513          	addi	a0,s0,-208
    800057a8:	fffff097          	auipc	ra,0xfffff
    800057ac:	972080e7          	jalr	-1678(ra) # 8000411a <nameiparent>
    800057b0:	84aa                	mv	s1,a0
    800057b2:	c979                	beqz	a0,80005888 <sys_unlink+0x114>
  ilock(dp);
    800057b4:	ffffe097          	auipc	ra,0xffffe
    800057b8:	198080e7          	jalr	408(ra) # 8000394c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057bc:	00003597          	auipc	a1,0x3
    800057c0:	fb458593          	addi	a1,a1,-76 # 80008770 <syscalls+0x2c0>
    800057c4:	fb040513          	addi	a0,s0,-80
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	648080e7          	jalr	1608(ra) # 80003e10 <namecmp>
    800057d0:	14050a63          	beqz	a0,80005924 <sys_unlink+0x1b0>
    800057d4:	00003597          	auipc	a1,0x3
    800057d8:	9fc58593          	addi	a1,a1,-1540 # 800081d0 <digits+0x190>
    800057dc:	fb040513          	addi	a0,s0,-80
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	630080e7          	jalr	1584(ra) # 80003e10 <namecmp>
    800057e8:	12050e63          	beqz	a0,80005924 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057ec:	f2c40613          	addi	a2,s0,-212
    800057f0:	fb040593          	addi	a1,s0,-80
    800057f4:	8526                	mv	a0,s1
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	634080e7          	jalr	1588(ra) # 80003e2a <dirlookup>
    800057fe:	892a                	mv	s2,a0
    80005800:	12050263          	beqz	a0,80005924 <sys_unlink+0x1b0>
  ilock(ip);
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	148080e7          	jalr	328(ra) # 8000394c <ilock>
  if(ip->nlink < 1)
    8000580c:	04a91783          	lh	a5,74(s2)
    80005810:	08f05263          	blez	a5,80005894 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005814:	04491703          	lh	a4,68(s2)
    80005818:	4785                	li	a5,1
    8000581a:	08f70563          	beq	a4,a5,800058a4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000581e:	4641                	li	a2,16
    80005820:	4581                	li	a1,0
    80005822:	fc040513          	addi	a0,s0,-64
    80005826:	ffffb097          	auipc	ra,0xffffb
    8000582a:	4e6080e7          	jalr	1254(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000582e:	4741                	li	a4,16
    80005830:	f2c42683          	lw	a3,-212(s0)
    80005834:	fc040613          	addi	a2,s0,-64
    80005838:	4581                	li	a1,0
    8000583a:	8526                	mv	a0,s1
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	4ba080e7          	jalr	1210(ra) # 80003cf6 <writei>
    80005844:	47c1                	li	a5,16
    80005846:	0af51563          	bne	a0,a5,800058f0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000584a:	04491703          	lh	a4,68(s2)
    8000584e:	4785                	li	a5,1
    80005850:	0af70863          	beq	a4,a5,80005900 <sys_unlink+0x18c>
  iunlockput(dp);
    80005854:	8526                	mv	a0,s1
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	358080e7          	jalr	856(ra) # 80003bae <iunlockput>
  ip->nlink--;
    8000585e:	04a95783          	lhu	a5,74(s2)
    80005862:	37fd                	addiw	a5,a5,-1
    80005864:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005868:	854a                	mv	a0,s2
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	018080e7          	jalr	24(ra) # 80003882 <iupdate>
  iunlockput(ip);
    80005872:	854a                	mv	a0,s2
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	33a080e7          	jalr	826(ra) # 80003bae <iunlockput>
  end_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	b0c080e7          	jalr	-1268(ra) # 80004388 <end_op>
  return 0;
    80005884:	4501                	li	a0,0
    80005886:	a84d                	j	80005938 <sys_unlink+0x1c4>
    end_op();
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	b00080e7          	jalr	-1280(ra) # 80004388 <end_op>
    return -1;
    80005890:	557d                	li	a0,-1
    80005892:	a05d                	j	80005938 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005894:	00003517          	auipc	a0,0x3
    80005898:	f0450513          	addi	a0,a0,-252 # 80008798 <syscalls+0x2e8>
    8000589c:	ffffb097          	auipc	ra,0xffffb
    800058a0:	cac080e7          	jalr	-852(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058a4:	04c92703          	lw	a4,76(s2)
    800058a8:	02000793          	li	a5,32
    800058ac:	f6e7f9e3          	bgeu	a5,a4,8000581e <sys_unlink+0xaa>
    800058b0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058b4:	4741                	li	a4,16
    800058b6:	86ce                	mv	a3,s3
    800058b8:	f1840613          	addi	a2,s0,-232
    800058bc:	4581                	li	a1,0
    800058be:	854a                	mv	a0,s2
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	340080e7          	jalr	832(ra) # 80003c00 <readi>
    800058c8:	47c1                	li	a5,16
    800058ca:	00f51b63          	bne	a0,a5,800058e0 <sys_unlink+0x16c>
    if(de.inum != 0)
    800058ce:	f1845783          	lhu	a5,-232(s0)
    800058d2:	e7a1                	bnez	a5,8000591a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058d4:	29c1                	addiw	s3,s3,16
    800058d6:	04c92783          	lw	a5,76(s2)
    800058da:	fcf9ede3          	bltu	s3,a5,800058b4 <sys_unlink+0x140>
    800058de:	b781                	j	8000581e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058e0:	00003517          	auipc	a0,0x3
    800058e4:	ed050513          	addi	a0,a0,-304 # 800087b0 <syscalls+0x300>
    800058e8:	ffffb097          	auipc	ra,0xffffb
    800058ec:	c60080e7          	jalr	-928(ra) # 80000548 <panic>
    panic("unlink: writei");
    800058f0:	00003517          	auipc	a0,0x3
    800058f4:	ed850513          	addi	a0,a0,-296 # 800087c8 <syscalls+0x318>
    800058f8:	ffffb097          	auipc	ra,0xffffb
    800058fc:	c50080e7          	jalr	-944(ra) # 80000548 <panic>
    dp->nlink--;
    80005900:	04a4d783          	lhu	a5,74(s1)
    80005904:	37fd                	addiw	a5,a5,-1
    80005906:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000590a:	8526                	mv	a0,s1
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	f76080e7          	jalr	-138(ra) # 80003882 <iupdate>
    80005914:	b781                	j	80005854 <sys_unlink+0xe0>
    return -1;
    80005916:	557d                	li	a0,-1
    80005918:	a005                	j	80005938 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000591a:	854a                	mv	a0,s2
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	292080e7          	jalr	658(ra) # 80003bae <iunlockput>
  iunlockput(dp);
    80005924:	8526                	mv	a0,s1
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	288080e7          	jalr	648(ra) # 80003bae <iunlockput>
  end_op();
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	a5a080e7          	jalr	-1446(ra) # 80004388 <end_op>
  return -1;
    80005936:	557d                	li	a0,-1
}
    80005938:	70ae                	ld	ra,232(sp)
    8000593a:	740e                	ld	s0,224(sp)
    8000593c:	64ee                	ld	s1,216(sp)
    8000593e:	694e                	ld	s2,208(sp)
    80005940:	69ae                	ld	s3,200(sp)
    80005942:	616d                	addi	sp,sp,240
    80005944:	8082                	ret

0000000080005946 <sys_open>:

uint64
sys_open(void)
{
    80005946:	7131                	addi	sp,sp,-192
    80005948:	fd06                	sd	ra,184(sp)
    8000594a:	f922                	sd	s0,176(sp)
    8000594c:	f526                	sd	s1,168(sp)
    8000594e:	f14a                	sd	s2,160(sp)
    80005950:	ed4e                	sd	s3,152(sp)
    80005952:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005954:	08000613          	li	a2,128
    80005958:	f5040593          	addi	a1,s0,-176
    8000595c:	4501                	li	a0,0
    8000595e:	ffffd097          	auipc	ra,0xffffd
    80005962:	4c0080e7          	jalr	1216(ra) # 80002e1e <argstr>
    return -1;
    80005966:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005968:	0c054163          	bltz	a0,80005a2a <sys_open+0xe4>
    8000596c:	f4c40593          	addi	a1,s0,-180
    80005970:	4505                	li	a0,1
    80005972:	ffffd097          	auipc	ra,0xffffd
    80005976:	468080e7          	jalr	1128(ra) # 80002dda <argint>
    8000597a:	0a054863          	bltz	a0,80005a2a <sys_open+0xe4>

  begin_op();
    8000597e:	fffff097          	auipc	ra,0xfffff
    80005982:	98a080e7          	jalr	-1654(ra) # 80004308 <begin_op>

  if(omode & O_CREATE){
    80005986:	f4c42783          	lw	a5,-180(s0)
    8000598a:	2007f793          	andi	a5,a5,512
    8000598e:	cbdd                	beqz	a5,80005a44 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005990:	4681                	li	a3,0
    80005992:	4601                	li	a2,0
    80005994:	4589                	li	a1,2
    80005996:	f5040513          	addi	a0,s0,-176
    8000599a:	00000097          	auipc	ra,0x0
    8000599e:	972080e7          	jalr	-1678(ra) # 8000530c <create>
    800059a2:	892a                	mv	s2,a0
    if(ip == 0){
    800059a4:	c959                	beqz	a0,80005a3a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059a6:	04491703          	lh	a4,68(s2)
    800059aa:	478d                	li	a5,3
    800059ac:	00f71763          	bne	a4,a5,800059ba <sys_open+0x74>
    800059b0:	04695703          	lhu	a4,70(s2)
    800059b4:	47a5                	li	a5,9
    800059b6:	0ce7ec63          	bltu	a5,a4,80005a8e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	d64080e7          	jalr	-668(ra) # 8000471e <filealloc>
    800059c2:	89aa                	mv	s3,a0
    800059c4:	10050263          	beqz	a0,80005ac8 <sys_open+0x182>
    800059c8:	00000097          	auipc	ra,0x0
    800059cc:	902080e7          	jalr	-1790(ra) # 800052ca <fdalloc>
    800059d0:	84aa                	mv	s1,a0
    800059d2:	0e054663          	bltz	a0,80005abe <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059d6:	04491703          	lh	a4,68(s2)
    800059da:	478d                	li	a5,3
    800059dc:	0cf70463          	beq	a4,a5,80005aa4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059e0:	4789                	li	a5,2
    800059e2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059e6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059ea:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059ee:	f4c42783          	lw	a5,-180(s0)
    800059f2:	0017c713          	xori	a4,a5,1
    800059f6:	8b05                	andi	a4,a4,1
    800059f8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059fc:	0037f713          	andi	a4,a5,3
    80005a00:	00e03733          	snez	a4,a4
    80005a04:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a08:	4007f793          	andi	a5,a5,1024
    80005a0c:	c791                	beqz	a5,80005a18 <sys_open+0xd2>
    80005a0e:	04491703          	lh	a4,68(s2)
    80005a12:	4789                	li	a5,2
    80005a14:	08f70f63          	beq	a4,a5,80005ab2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a18:	854a                	mv	a0,s2
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	ff4080e7          	jalr	-12(ra) # 80003a0e <iunlock>
  end_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	966080e7          	jalr	-1690(ra) # 80004388 <end_op>

  return fd;
}
    80005a2a:	8526                	mv	a0,s1
    80005a2c:	70ea                	ld	ra,184(sp)
    80005a2e:	744a                	ld	s0,176(sp)
    80005a30:	74aa                	ld	s1,168(sp)
    80005a32:	790a                	ld	s2,160(sp)
    80005a34:	69ea                	ld	s3,152(sp)
    80005a36:	6129                	addi	sp,sp,192
    80005a38:	8082                	ret
      end_op();
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	94e080e7          	jalr	-1714(ra) # 80004388 <end_op>
      return -1;
    80005a42:	b7e5                	j	80005a2a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a44:	f5040513          	addi	a0,s0,-176
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	6b4080e7          	jalr	1716(ra) # 800040fc <namei>
    80005a50:	892a                	mv	s2,a0
    80005a52:	c905                	beqz	a0,80005a82 <sys_open+0x13c>
    ilock(ip);
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	ef8080e7          	jalr	-264(ra) # 8000394c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a5c:	04491703          	lh	a4,68(s2)
    80005a60:	4785                	li	a5,1
    80005a62:	f4f712e3          	bne	a4,a5,800059a6 <sys_open+0x60>
    80005a66:	f4c42783          	lw	a5,-180(s0)
    80005a6a:	dba1                	beqz	a5,800059ba <sys_open+0x74>
      iunlockput(ip);
    80005a6c:	854a                	mv	a0,s2
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	140080e7          	jalr	320(ra) # 80003bae <iunlockput>
      end_op();
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	912080e7          	jalr	-1774(ra) # 80004388 <end_op>
      return -1;
    80005a7e:	54fd                	li	s1,-1
    80005a80:	b76d                	j	80005a2a <sys_open+0xe4>
      end_op();
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	906080e7          	jalr	-1786(ra) # 80004388 <end_op>
      return -1;
    80005a8a:	54fd                	li	s1,-1
    80005a8c:	bf79                	j	80005a2a <sys_open+0xe4>
    iunlockput(ip);
    80005a8e:	854a                	mv	a0,s2
    80005a90:	ffffe097          	auipc	ra,0xffffe
    80005a94:	11e080e7          	jalr	286(ra) # 80003bae <iunlockput>
    end_op();
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	8f0080e7          	jalr	-1808(ra) # 80004388 <end_op>
    return -1;
    80005aa0:	54fd                	li	s1,-1
    80005aa2:	b761                	j	80005a2a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005aa4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005aa8:	04691783          	lh	a5,70(s2)
    80005aac:	02f99223          	sh	a5,36(s3)
    80005ab0:	bf2d                	j	800059ea <sys_open+0xa4>
    itrunc(ip);
    80005ab2:	854a                	mv	a0,s2
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	fa6080e7          	jalr	-90(ra) # 80003a5a <itrunc>
    80005abc:	bfb1                	j	80005a18 <sys_open+0xd2>
      fileclose(f);
    80005abe:	854e                	mv	a0,s3
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	d1a080e7          	jalr	-742(ra) # 800047da <fileclose>
    iunlockput(ip);
    80005ac8:	854a                	mv	a0,s2
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	0e4080e7          	jalr	228(ra) # 80003bae <iunlockput>
    end_op();
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	8b6080e7          	jalr	-1866(ra) # 80004388 <end_op>
    return -1;
    80005ada:	54fd                	li	s1,-1
    80005adc:	b7b9                	j	80005a2a <sys_open+0xe4>

0000000080005ade <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ade:	7175                	addi	sp,sp,-144
    80005ae0:	e506                	sd	ra,136(sp)
    80005ae2:	e122                	sd	s0,128(sp)
    80005ae4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	822080e7          	jalr	-2014(ra) # 80004308 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005aee:	08000613          	li	a2,128
    80005af2:	f7040593          	addi	a1,s0,-144
    80005af6:	4501                	li	a0,0
    80005af8:	ffffd097          	auipc	ra,0xffffd
    80005afc:	326080e7          	jalr	806(ra) # 80002e1e <argstr>
    80005b00:	02054963          	bltz	a0,80005b32 <sys_mkdir+0x54>
    80005b04:	4681                	li	a3,0
    80005b06:	4601                	li	a2,0
    80005b08:	4585                	li	a1,1
    80005b0a:	f7040513          	addi	a0,s0,-144
    80005b0e:	fffff097          	auipc	ra,0xfffff
    80005b12:	7fe080e7          	jalr	2046(ra) # 8000530c <create>
    80005b16:	cd11                	beqz	a0,80005b32 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	096080e7          	jalr	150(ra) # 80003bae <iunlockput>
  end_op();
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	868080e7          	jalr	-1944(ra) # 80004388 <end_op>
  return 0;
    80005b28:	4501                	li	a0,0
}
    80005b2a:	60aa                	ld	ra,136(sp)
    80005b2c:	640a                	ld	s0,128(sp)
    80005b2e:	6149                	addi	sp,sp,144
    80005b30:	8082                	ret
    end_op();
    80005b32:	fffff097          	auipc	ra,0xfffff
    80005b36:	856080e7          	jalr	-1962(ra) # 80004388 <end_op>
    return -1;
    80005b3a:	557d                	li	a0,-1
    80005b3c:	b7fd                	j	80005b2a <sys_mkdir+0x4c>

0000000080005b3e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b3e:	7135                	addi	sp,sp,-160
    80005b40:	ed06                	sd	ra,152(sp)
    80005b42:	e922                	sd	s0,144(sp)
    80005b44:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b46:	ffffe097          	auipc	ra,0xffffe
    80005b4a:	7c2080e7          	jalr	1986(ra) # 80004308 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b4e:	08000613          	li	a2,128
    80005b52:	f7040593          	addi	a1,s0,-144
    80005b56:	4501                	li	a0,0
    80005b58:	ffffd097          	auipc	ra,0xffffd
    80005b5c:	2c6080e7          	jalr	710(ra) # 80002e1e <argstr>
    80005b60:	04054a63          	bltz	a0,80005bb4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b64:	f6c40593          	addi	a1,s0,-148
    80005b68:	4505                	li	a0,1
    80005b6a:	ffffd097          	auipc	ra,0xffffd
    80005b6e:	270080e7          	jalr	624(ra) # 80002dda <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b72:	04054163          	bltz	a0,80005bb4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b76:	f6840593          	addi	a1,s0,-152
    80005b7a:	4509                	li	a0,2
    80005b7c:	ffffd097          	auipc	ra,0xffffd
    80005b80:	25e080e7          	jalr	606(ra) # 80002dda <argint>
     argint(1, &major) < 0 ||
    80005b84:	02054863          	bltz	a0,80005bb4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b88:	f6841683          	lh	a3,-152(s0)
    80005b8c:	f6c41603          	lh	a2,-148(s0)
    80005b90:	458d                	li	a1,3
    80005b92:	f7040513          	addi	a0,s0,-144
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	776080e7          	jalr	1910(ra) # 8000530c <create>
     argint(2, &minor) < 0 ||
    80005b9e:	c919                	beqz	a0,80005bb4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ba0:	ffffe097          	auipc	ra,0xffffe
    80005ba4:	00e080e7          	jalr	14(ra) # 80003bae <iunlockput>
  end_op();
    80005ba8:	ffffe097          	auipc	ra,0xffffe
    80005bac:	7e0080e7          	jalr	2016(ra) # 80004388 <end_op>
  return 0;
    80005bb0:	4501                	li	a0,0
    80005bb2:	a031                	j	80005bbe <sys_mknod+0x80>
    end_op();
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	7d4080e7          	jalr	2004(ra) # 80004388 <end_op>
    return -1;
    80005bbc:	557d                	li	a0,-1
}
    80005bbe:	60ea                	ld	ra,152(sp)
    80005bc0:	644a                	ld	s0,144(sp)
    80005bc2:	610d                	addi	sp,sp,160
    80005bc4:	8082                	ret

0000000080005bc6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005bc6:	7135                	addi	sp,sp,-160
    80005bc8:	ed06                	sd	ra,152(sp)
    80005bca:	e922                	sd	s0,144(sp)
    80005bcc:	e526                	sd	s1,136(sp)
    80005bce:	e14a                	sd	s2,128(sp)
    80005bd0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005bd2:	ffffc097          	auipc	ra,0xffffc
    80005bd6:	f4c080e7          	jalr	-180(ra) # 80001b1e <myproc>
    80005bda:	892a                	mv	s2,a0
  
  begin_op();
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	72c080e7          	jalr	1836(ra) # 80004308 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005be4:	08000613          	li	a2,128
    80005be8:	f6040593          	addi	a1,s0,-160
    80005bec:	4501                	li	a0,0
    80005bee:	ffffd097          	auipc	ra,0xffffd
    80005bf2:	230080e7          	jalr	560(ra) # 80002e1e <argstr>
    80005bf6:	04054b63          	bltz	a0,80005c4c <sys_chdir+0x86>
    80005bfa:	f6040513          	addi	a0,s0,-160
    80005bfe:	ffffe097          	auipc	ra,0xffffe
    80005c02:	4fe080e7          	jalr	1278(ra) # 800040fc <namei>
    80005c06:	84aa                	mv	s1,a0
    80005c08:	c131                	beqz	a0,80005c4c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c0a:	ffffe097          	auipc	ra,0xffffe
    80005c0e:	d42080e7          	jalr	-702(ra) # 8000394c <ilock>
  if(ip->type != T_DIR){
    80005c12:	04449703          	lh	a4,68(s1)
    80005c16:	4785                	li	a5,1
    80005c18:	04f71063          	bne	a4,a5,80005c58 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c1c:	8526                	mv	a0,s1
    80005c1e:	ffffe097          	auipc	ra,0xffffe
    80005c22:	df0080e7          	jalr	-528(ra) # 80003a0e <iunlock>
  iput(p->cwd);
    80005c26:	15893503          	ld	a0,344(s2)
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	edc080e7          	jalr	-292(ra) # 80003b06 <iput>
  end_op();
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	756080e7          	jalr	1878(ra) # 80004388 <end_op>
  p->cwd = ip;
    80005c3a:	14993c23          	sd	s1,344(s2)
  return 0;
    80005c3e:	4501                	li	a0,0
}
    80005c40:	60ea                	ld	ra,152(sp)
    80005c42:	644a                	ld	s0,144(sp)
    80005c44:	64aa                	ld	s1,136(sp)
    80005c46:	690a                	ld	s2,128(sp)
    80005c48:	610d                	addi	sp,sp,160
    80005c4a:	8082                	ret
    end_op();
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	73c080e7          	jalr	1852(ra) # 80004388 <end_op>
    return -1;
    80005c54:	557d                	li	a0,-1
    80005c56:	b7ed                	j	80005c40 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c58:	8526                	mv	a0,s1
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	f54080e7          	jalr	-172(ra) # 80003bae <iunlockput>
    end_op();
    80005c62:	ffffe097          	auipc	ra,0xffffe
    80005c66:	726080e7          	jalr	1830(ra) # 80004388 <end_op>
    return -1;
    80005c6a:	557d                	li	a0,-1
    80005c6c:	bfd1                	j	80005c40 <sys_chdir+0x7a>

0000000080005c6e <sys_exec>:

uint64
sys_exec(void)
{
    80005c6e:	7145                	addi	sp,sp,-464
    80005c70:	e786                	sd	ra,456(sp)
    80005c72:	e3a2                	sd	s0,448(sp)
    80005c74:	ff26                	sd	s1,440(sp)
    80005c76:	fb4a                	sd	s2,432(sp)
    80005c78:	f74e                	sd	s3,424(sp)
    80005c7a:	f352                	sd	s4,416(sp)
    80005c7c:	ef56                	sd	s5,408(sp)
    80005c7e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c80:	08000613          	li	a2,128
    80005c84:	f4040593          	addi	a1,s0,-192
    80005c88:	4501                	li	a0,0
    80005c8a:	ffffd097          	auipc	ra,0xffffd
    80005c8e:	194080e7          	jalr	404(ra) # 80002e1e <argstr>
    return -1;
    80005c92:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c94:	0c054a63          	bltz	a0,80005d68 <sys_exec+0xfa>
    80005c98:	e3840593          	addi	a1,s0,-456
    80005c9c:	4505                	li	a0,1
    80005c9e:	ffffd097          	auipc	ra,0xffffd
    80005ca2:	15e080e7          	jalr	350(ra) # 80002dfc <argaddr>
    80005ca6:	0c054163          	bltz	a0,80005d68 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005caa:	10000613          	li	a2,256
    80005cae:	4581                	li	a1,0
    80005cb0:	e4040513          	addi	a0,s0,-448
    80005cb4:	ffffb097          	auipc	ra,0xffffb
    80005cb8:	058080e7          	jalr	88(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005cbc:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cc0:	89a6                	mv	s3,s1
    80005cc2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cc4:	02000a13          	li	s4,32
    80005cc8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ccc:	00391513          	slli	a0,s2,0x3
    80005cd0:	e3040593          	addi	a1,s0,-464
    80005cd4:	e3843783          	ld	a5,-456(s0)
    80005cd8:	953e                	add	a0,a0,a5
    80005cda:	ffffd097          	auipc	ra,0xffffd
    80005cde:	066080e7          	jalr	102(ra) # 80002d40 <fetchaddr>
    80005ce2:	02054a63          	bltz	a0,80005d16 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ce6:	e3043783          	ld	a5,-464(s0)
    80005cea:	c3b9                	beqz	a5,80005d30 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005cec:	ffffb097          	auipc	ra,0xffffb
    80005cf0:	e34080e7          	jalr	-460(ra) # 80000b20 <kalloc>
    80005cf4:	85aa                	mv	a1,a0
    80005cf6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cfa:	cd11                	beqz	a0,80005d16 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cfc:	6605                	lui	a2,0x1
    80005cfe:	e3043503          	ld	a0,-464(s0)
    80005d02:	ffffd097          	auipc	ra,0xffffd
    80005d06:	090080e7          	jalr	144(ra) # 80002d92 <fetchstr>
    80005d0a:	00054663          	bltz	a0,80005d16 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d0e:	0905                	addi	s2,s2,1
    80005d10:	09a1                	addi	s3,s3,8
    80005d12:	fb491be3          	bne	s2,s4,80005cc8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d16:	10048913          	addi	s2,s1,256
    80005d1a:	6088                	ld	a0,0(s1)
    80005d1c:	c529                	beqz	a0,80005d66 <sys_exec+0xf8>
    kfree(argv[i]);
    80005d1e:	ffffb097          	auipc	ra,0xffffb
    80005d22:	d06080e7          	jalr	-762(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d26:	04a1                	addi	s1,s1,8
    80005d28:	ff2499e3          	bne	s1,s2,80005d1a <sys_exec+0xac>
  return -1;
    80005d2c:	597d                	li	s2,-1
    80005d2e:	a82d                	j	80005d68 <sys_exec+0xfa>
      argv[i] = 0;
    80005d30:	0a8e                	slli	s5,s5,0x3
    80005d32:	fc040793          	addi	a5,s0,-64
    80005d36:	9abe                	add	s5,s5,a5
    80005d38:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d3c:	e4040593          	addi	a1,s0,-448
    80005d40:	f4040513          	addi	a0,s0,-192
    80005d44:	fffff097          	auipc	ra,0xfffff
    80005d48:	146080e7          	jalr	326(ra) # 80004e8a <exec>
    80005d4c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d4e:	10048993          	addi	s3,s1,256
    80005d52:	6088                	ld	a0,0(s1)
    80005d54:	c911                	beqz	a0,80005d68 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d56:	ffffb097          	auipc	ra,0xffffb
    80005d5a:	cce080e7          	jalr	-818(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d5e:	04a1                	addi	s1,s1,8
    80005d60:	ff3499e3          	bne	s1,s3,80005d52 <sys_exec+0xe4>
    80005d64:	a011                	j	80005d68 <sys_exec+0xfa>
  return -1;
    80005d66:	597d                	li	s2,-1
}
    80005d68:	854a                	mv	a0,s2
    80005d6a:	60be                	ld	ra,456(sp)
    80005d6c:	641e                	ld	s0,448(sp)
    80005d6e:	74fa                	ld	s1,440(sp)
    80005d70:	795a                	ld	s2,432(sp)
    80005d72:	79ba                	ld	s3,424(sp)
    80005d74:	7a1a                	ld	s4,416(sp)
    80005d76:	6afa                	ld	s5,408(sp)
    80005d78:	6179                	addi	sp,sp,464
    80005d7a:	8082                	ret

0000000080005d7c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d7c:	7139                	addi	sp,sp,-64
    80005d7e:	fc06                	sd	ra,56(sp)
    80005d80:	f822                	sd	s0,48(sp)
    80005d82:	f426                	sd	s1,40(sp)
    80005d84:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d86:	ffffc097          	auipc	ra,0xffffc
    80005d8a:	d98080e7          	jalr	-616(ra) # 80001b1e <myproc>
    80005d8e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d90:	fd840593          	addi	a1,s0,-40
    80005d94:	4501                	li	a0,0
    80005d96:	ffffd097          	auipc	ra,0xffffd
    80005d9a:	066080e7          	jalr	102(ra) # 80002dfc <argaddr>
    return -1;
    80005d9e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005da0:	0e054063          	bltz	a0,80005e80 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005da4:	fc840593          	addi	a1,s0,-56
    80005da8:	fd040513          	addi	a0,s0,-48
    80005dac:	fffff097          	auipc	ra,0xfffff
    80005db0:	d84080e7          	jalr	-636(ra) # 80004b30 <pipealloc>
    return -1;
    80005db4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005db6:	0c054563          	bltz	a0,80005e80 <sys_pipe+0x104>
  fd0 = -1;
    80005dba:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005dbe:	fd043503          	ld	a0,-48(s0)
    80005dc2:	fffff097          	auipc	ra,0xfffff
    80005dc6:	508080e7          	jalr	1288(ra) # 800052ca <fdalloc>
    80005dca:	fca42223          	sw	a0,-60(s0)
    80005dce:	08054c63          	bltz	a0,80005e66 <sys_pipe+0xea>
    80005dd2:	fc843503          	ld	a0,-56(s0)
    80005dd6:	fffff097          	auipc	ra,0xfffff
    80005dda:	4f4080e7          	jalr	1268(ra) # 800052ca <fdalloc>
    80005dde:	fca42023          	sw	a0,-64(s0)
    80005de2:	06054863          	bltz	a0,80005e52 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005de6:	4691                	li	a3,4
    80005de8:	fc440613          	addi	a2,s0,-60
    80005dec:	fd843583          	ld	a1,-40(s0)
    80005df0:	6ca8                	ld	a0,88(s1)
    80005df2:	ffffc097          	auipc	ra,0xffffc
    80005df6:	8f0080e7          	jalr	-1808(ra) # 800016e2 <copyout>
    80005dfa:	02054063          	bltz	a0,80005e1a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005dfe:	4691                	li	a3,4
    80005e00:	fc040613          	addi	a2,s0,-64
    80005e04:	fd843583          	ld	a1,-40(s0)
    80005e08:	0591                	addi	a1,a1,4
    80005e0a:	6ca8                	ld	a0,88(s1)
    80005e0c:	ffffc097          	auipc	ra,0xffffc
    80005e10:	8d6080e7          	jalr	-1834(ra) # 800016e2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e14:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e16:	06055563          	bgez	a0,80005e80 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e1a:	fc442783          	lw	a5,-60(s0)
    80005e1e:	07e9                	addi	a5,a5,26
    80005e20:	078e                	slli	a5,a5,0x3
    80005e22:	97a6                	add	a5,a5,s1
    80005e24:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005e28:	fc042503          	lw	a0,-64(s0)
    80005e2c:	0569                	addi	a0,a0,26
    80005e2e:	050e                	slli	a0,a0,0x3
    80005e30:	9526                	add	a0,a0,s1
    80005e32:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005e36:	fd043503          	ld	a0,-48(s0)
    80005e3a:	fffff097          	auipc	ra,0xfffff
    80005e3e:	9a0080e7          	jalr	-1632(ra) # 800047da <fileclose>
    fileclose(wf);
    80005e42:	fc843503          	ld	a0,-56(s0)
    80005e46:	fffff097          	auipc	ra,0xfffff
    80005e4a:	994080e7          	jalr	-1644(ra) # 800047da <fileclose>
    return -1;
    80005e4e:	57fd                	li	a5,-1
    80005e50:	a805                	j	80005e80 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e52:	fc442783          	lw	a5,-60(s0)
    80005e56:	0007c863          	bltz	a5,80005e66 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e5a:	01a78513          	addi	a0,a5,26
    80005e5e:	050e                	slli	a0,a0,0x3
    80005e60:	9526                	add	a0,a0,s1
    80005e62:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005e66:	fd043503          	ld	a0,-48(s0)
    80005e6a:	fffff097          	auipc	ra,0xfffff
    80005e6e:	970080e7          	jalr	-1680(ra) # 800047da <fileclose>
    fileclose(wf);
    80005e72:	fc843503          	ld	a0,-56(s0)
    80005e76:	fffff097          	auipc	ra,0xfffff
    80005e7a:	964080e7          	jalr	-1692(ra) # 800047da <fileclose>
    return -1;
    80005e7e:	57fd                	li	a5,-1
}
    80005e80:	853e                	mv	a0,a5
    80005e82:	70e2                	ld	ra,56(sp)
    80005e84:	7442                	ld	s0,48(sp)
    80005e86:	74a2                	ld	s1,40(sp)
    80005e88:	6121                	addi	sp,sp,64
    80005e8a:	8082                	ret
    80005e8c:	0000                	unimp
	...

0000000080005e90 <kernelvec>:
    80005e90:	7111                	addi	sp,sp,-256
    80005e92:	e006                	sd	ra,0(sp)
    80005e94:	e40a                	sd	sp,8(sp)
    80005e96:	e80e                	sd	gp,16(sp)
    80005e98:	ec12                	sd	tp,24(sp)
    80005e9a:	f016                	sd	t0,32(sp)
    80005e9c:	f41a                	sd	t1,40(sp)
    80005e9e:	f81e                	sd	t2,48(sp)
    80005ea0:	fc22                	sd	s0,56(sp)
    80005ea2:	e0a6                	sd	s1,64(sp)
    80005ea4:	e4aa                	sd	a0,72(sp)
    80005ea6:	e8ae                	sd	a1,80(sp)
    80005ea8:	ecb2                	sd	a2,88(sp)
    80005eaa:	f0b6                	sd	a3,96(sp)
    80005eac:	f4ba                	sd	a4,104(sp)
    80005eae:	f8be                	sd	a5,112(sp)
    80005eb0:	fcc2                	sd	a6,120(sp)
    80005eb2:	e146                	sd	a7,128(sp)
    80005eb4:	e54a                	sd	s2,136(sp)
    80005eb6:	e94e                	sd	s3,144(sp)
    80005eb8:	ed52                	sd	s4,152(sp)
    80005eba:	f156                	sd	s5,160(sp)
    80005ebc:	f55a                	sd	s6,168(sp)
    80005ebe:	f95e                	sd	s7,176(sp)
    80005ec0:	fd62                	sd	s8,184(sp)
    80005ec2:	e1e6                	sd	s9,192(sp)
    80005ec4:	e5ea                	sd	s10,200(sp)
    80005ec6:	e9ee                	sd	s11,208(sp)
    80005ec8:	edf2                	sd	t3,216(sp)
    80005eca:	f1f6                	sd	t4,224(sp)
    80005ecc:	f5fa                	sd	t5,232(sp)
    80005ece:	f9fe                	sd	t6,240(sp)
    80005ed0:	d3dfc0ef          	jal	ra,80002c0c <kerneltrap>
    80005ed4:	6082                	ld	ra,0(sp)
    80005ed6:	6122                	ld	sp,8(sp)
    80005ed8:	61c2                	ld	gp,16(sp)
    80005eda:	7282                	ld	t0,32(sp)
    80005edc:	7322                	ld	t1,40(sp)
    80005ede:	73c2                	ld	t2,48(sp)
    80005ee0:	7462                	ld	s0,56(sp)
    80005ee2:	6486                	ld	s1,64(sp)
    80005ee4:	6526                	ld	a0,72(sp)
    80005ee6:	65c6                	ld	a1,80(sp)
    80005ee8:	6666                	ld	a2,88(sp)
    80005eea:	7686                	ld	a3,96(sp)
    80005eec:	7726                	ld	a4,104(sp)
    80005eee:	77c6                	ld	a5,112(sp)
    80005ef0:	7866                	ld	a6,120(sp)
    80005ef2:	688a                	ld	a7,128(sp)
    80005ef4:	692a                	ld	s2,136(sp)
    80005ef6:	69ca                	ld	s3,144(sp)
    80005ef8:	6a6a                	ld	s4,152(sp)
    80005efa:	7a8a                	ld	s5,160(sp)
    80005efc:	7b2a                	ld	s6,168(sp)
    80005efe:	7bca                	ld	s7,176(sp)
    80005f00:	7c6a                	ld	s8,184(sp)
    80005f02:	6c8e                	ld	s9,192(sp)
    80005f04:	6d2e                	ld	s10,200(sp)
    80005f06:	6dce                	ld	s11,208(sp)
    80005f08:	6e6e                	ld	t3,216(sp)
    80005f0a:	7e8e                	ld	t4,224(sp)
    80005f0c:	7f2e                	ld	t5,232(sp)
    80005f0e:	7fce                	ld	t6,240(sp)
    80005f10:	6111                	addi	sp,sp,256
    80005f12:	10200073          	sret
    80005f16:	00000013          	nop
    80005f1a:	00000013          	nop
    80005f1e:	0001                	nop

0000000080005f20 <timervec>:
    80005f20:	34051573          	csrrw	a0,mscratch,a0
    80005f24:	e10c                	sd	a1,0(a0)
    80005f26:	e510                	sd	a2,8(a0)
    80005f28:	e914                	sd	a3,16(a0)
    80005f2a:	710c                	ld	a1,32(a0)
    80005f2c:	7510                	ld	a2,40(a0)
    80005f2e:	6194                	ld	a3,0(a1)
    80005f30:	96b2                	add	a3,a3,a2
    80005f32:	e194                	sd	a3,0(a1)
    80005f34:	4589                	li	a1,2
    80005f36:	14459073          	csrw	sip,a1
    80005f3a:	6914                	ld	a3,16(a0)
    80005f3c:	6510                	ld	a2,8(a0)
    80005f3e:	610c                	ld	a1,0(a0)
    80005f40:	34051573          	csrrw	a0,mscratch,a0
    80005f44:	30200073          	mret
	...

0000000080005f4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f4a:	1141                	addi	sp,sp,-16
    80005f4c:	e422                	sd	s0,8(sp)
    80005f4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f50:	0c0007b7          	lui	a5,0xc000
    80005f54:	4705                	li	a4,1
    80005f56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f58:	c3d8                	sw	a4,4(a5)
}
    80005f5a:	6422                	ld	s0,8(sp)
    80005f5c:	0141                	addi	sp,sp,16
    80005f5e:	8082                	ret

0000000080005f60 <plicinithart>:

void
plicinithart(void)
{
    80005f60:	1141                	addi	sp,sp,-16
    80005f62:	e406                	sd	ra,8(sp)
    80005f64:	e022                	sd	s0,0(sp)
    80005f66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f68:	ffffc097          	auipc	ra,0xffffc
    80005f6c:	b8a080e7          	jalr	-1142(ra) # 80001af2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f70:	0085171b          	slliw	a4,a0,0x8
    80005f74:	0c0027b7          	lui	a5,0xc002
    80005f78:	97ba                	add	a5,a5,a4
    80005f7a:	40200713          	li	a4,1026
    80005f7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f82:	00d5151b          	slliw	a0,a0,0xd
    80005f86:	0c2017b7          	lui	a5,0xc201
    80005f8a:	953e                	add	a0,a0,a5
    80005f8c:	00052023          	sw	zero,0(a0)
}
    80005f90:	60a2                	ld	ra,8(sp)
    80005f92:	6402                	ld	s0,0(sp)
    80005f94:	0141                	addi	sp,sp,16
    80005f96:	8082                	ret

0000000080005f98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f98:	1141                	addi	sp,sp,-16
    80005f9a:	e406                	sd	ra,8(sp)
    80005f9c:	e022                	sd	s0,0(sp)
    80005f9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fa0:	ffffc097          	auipc	ra,0xffffc
    80005fa4:	b52080e7          	jalr	-1198(ra) # 80001af2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fa8:	00d5179b          	slliw	a5,a0,0xd
    80005fac:	0c201537          	lui	a0,0xc201
    80005fb0:	953e                	add	a0,a0,a5
  return irq;
}
    80005fb2:	4148                	lw	a0,4(a0)
    80005fb4:	60a2                	ld	ra,8(sp)
    80005fb6:	6402                	ld	s0,0(sp)
    80005fb8:	0141                	addi	sp,sp,16
    80005fba:	8082                	ret

0000000080005fbc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fbc:	1101                	addi	sp,sp,-32
    80005fbe:	ec06                	sd	ra,24(sp)
    80005fc0:	e822                	sd	s0,16(sp)
    80005fc2:	e426                	sd	s1,8(sp)
    80005fc4:	1000                	addi	s0,sp,32
    80005fc6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	b2a080e7          	jalr	-1238(ra) # 80001af2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fd0:	00d5151b          	slliw	a0,a0,0xd
    80005fd4:	0c2017b7          	lui	a5,0xc201
    80005fd8:	97aa                	add	a5,a5,a0
    80005fda:	c3c4                	sw	s1,4(a5)
}
    80005fdc:	60e2                	ld	ra,24(sp)
    80005fde:	6442                	ld	s0,16(sp)
    80005fe0:	64a2                	ld	s1,8(sp)
    80005fe2:	6105                	addi	sp,sp,32
    80005fe4:	8082                	ret

0000000080005fe6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fe6:	1141                	addi	sp,sp,-16
    80005fe8:	e406                	sd	ra,8(sp)
    80005fea:	e022                	sd	s0,0(sp)
    80005fec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fee:	479d                	li	a5,7
    80005ff0:	04a7cc63          	blt	a5,a0,80006048 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005ff4:	0001d797          	auipc	a5,0x1d
    80005ff8:	00c78793          	addi	a5,a5,12 # 80023000 <disk>
    80005ffc:	00a78733          	add	a4,a5,a0
    80006000:	6789                	lui	a5,0x2
    80006002:	97ba                	add	a5,a5,a4
    80006004:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006008:	eba1                	bnez	a5,80006058 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    8000600a:	00451713          	slli	a4,a0,0x4
    8000600e:	0001f797          	auipc	a5,0x1f
    80006012:	ff27b783          	ld	a5,-14(a5) # 80025000 <disk+0x2000>
    80006016:	97ba                	add	a5,a5,a4
    80006018:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    8000601c:	0001d797          	auipc	a5,0x1d
    80006020:	fe478793          	addi	a5,a5,-28 # 80023000 <disk>
    80006024:	97aa                	add	a5,a5,a0
    80006026:	6509                	lui	a0,0x2
    80006028:	953e                	add	a0,a0,a5
    8000602a:	4785                	li	a5,1
    8000602c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006030:	0001f517          	auipc	a0,0x1f
    80006034:	fe850513          	addi	a0,a0,-24 # 80025018 <disk+0x2018>
    80006038:	ffffc097          	auipc	ra,0xffffc
    8000603c:	67a080e7          	jalr	1658(ra) # 800026b2 <wakeup>
}
    80006040:	60a2                	ld	ra,8(sp)
    80006042:	6402                	ld	s0,0(sp)
    80006044:	0141                	addi	sp,sp,16
    80006046:	8082                	ret
    panic("virtio_disk_intr 1");
    80006048:	00002517          	auipc	a0,0x2
    8000604c:	79050513          	addi	a0,a0,1936 # 800087d8 <syscalls+0x328>
    80006050:	ffffa097          	auipc	ra,0xffffa
    80006054:	4f8080e7          	jalr	1272(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80006058:	00002517          	auipc	a0,0x2
    8000605c:	79850513          	addi	a0,a0,1944 # 800087f0 <syscalls+0x340>
    80006060:	ffffa097          	auipc	ra,0xffffa
    80006064:	4e8080e7          	jalr	1256(ra) # 80000548 <panic>

0000000080006068 <virtio_disk_init>:
{
    80006068:	1101                	addi	sp,sp,-32
    8000606a:	ec06                	sd	ra,24(sp)
    8000606c:	e822                	sd	s0,16(sp)
    8000606e:	e426                	sd	s1,8(sp)
    80006070:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006072:	00002597          	auipc	a1,0x2
    80006076:	79658593          	addi	a1,a1,1942 # 80008808 <syscalls+0x358>
    8000607a:	0001f517          	auipc	a0,0x1f
    8000607e:	02e50513          	addi	a0,a0,46 # 800250a8 <disk+0x20a8>
    80006082:	ffffb097          	auipc	ra,0xffffb
    80006086:	afe080e7          	jalr	-1282(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000608a:	100017b7          	lui	a5,0x10001
    8000608e:	4398                	lw	a4,0(a5)
    80006090:	2701                	sext.w	a4,a4
    80006092:	747277b7          	lui	a5,0x74727
    80006096:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000609a:	0ef71163          	bne	a4,a5,8000617c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000609e:	100017b7          	lui	a5,0x10001
    800060a2:	43dc                	lw	a5,4(a5)
    800060a4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060a6:	4705                	li	a4,1
    800060a8:	0ce79a63          	bne	a5,a4,8000617c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060ac:	100017b7          	lui	a5,0x10001
    800060b0:	479c                	lw	a5,8(a5)
    800060b2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060b4:	4709                	li	a4,2
    800060b6:	0ce79363          	bne	a5,a4,8000617c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060ba:	100017b7          	lui	a5,0x10001
    800060be:	47d8                	lw	a4,12(a5)
    800060c0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060c2:	554d47b7          	lui	a5,0x554d4
    800060c6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060ca:	0af71963          	bne	a4,a5,8000617c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ce:	100017b7          	lui	a5,0x10001
    800060d2:	4705                	li	a4,1
    800060d4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060d6:	470d                	li	a4,3
    800060d8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060da:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060dc:	c7ffe737          	lui	a4,0xc7ffe
    800060e0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    800060e4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060e6:	2701                	sext.w	a4,a4
    800060e8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ea:	472d                	li	a4,11
    800060ec:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ee:	473d                	li	a4,15
    800060f0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060f2:	6705                	lui	a4,0x1
    800060f4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060f6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060fa:	5bdc                	lw	a5,52(a5)
    800060fc:	2781                	sext.w	a5,a5
  if(max == 0)
    800060fe:	c7d9                	beqz	a5,8000618c <virtio_disk_init+0x124>
  if(max < NUM)
    80006100:	471d                	li	a4,7
    80006102:	08f77d63          	bgeu	a4,a5,8000619c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006106:	100014b7          	lui	s1,0x10001
    8000610a:	47a1                	li	a5,8
    8000610c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000610e:	6609                	lui	a2,0x2
    80006110:	4581                	li	a1,0
    80006112:	0001d517          	auipc	a0,0x1d
    80006116:	eee50513          	addi	a0,a0,-274 # 80023000 <disk>
    8000611a:	ffffb097          	auipc	ra,0xffffb
    8000611e:	bf2080e7          	jalr	-1038(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006122:	0001d717          	auipc	a4,0x1d
    80006126:	ede70713          	addi	a4,a4,-290 # 80023000 <disk>
    8000612a:	00c75793          	srli	a5,a4,0xc
    8000612e:	2781                	sext.w	a5,a5
    80006130:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006132:	0001f797          	auipc	a5,0x1f
    80006136:	ece78793          	addi	a5,a5,-306 # 80025000 <disk+0x2000>
    8000613a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000613c:	0001d717          	auipc	a4,0x1d
    80006140:	f4470713          	addi	a4,a4,-188 # 80023080 <disk+0x80>
    80006144:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006146:	0001e717          	auipc	a4,0x1e
    8000614a:	eba70713          	addi	a4,a4,-326 # 80024000 <disk+0x1000>
    8000614e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006150:	4705                	li	a4,1
    80006152:	00e78c23          	sb	a4,24(a5)
    80006156:	00e78ca3          	sb	a4,25(a5)
    8000615a:	00e78d23          	sb	a4,26(a5)
    8000615e:	00e78da3          	sb	a4,27(a5)
    80006162:	00e78e23          	sb	a4,28(a5)
    80006166:	00e78ea3          	sb	a4,29(a5)
    8000616a:	00e78f23          	sb	a4,30(a5)
    8000616e:	00e78fa3          	sb	a4,31(a5)
}
    80006172:	60e2                	ld	ra,24(sp)
    80006174:	6442                	ld	s0,16(sp)
    80006176:	64a2                	ld	s1,8(sp)
    80006178:	6105                	addi	sp,sp,32
    8000617a:	8082                	ret
    panic("could not find virtio disk");
    8000617c:	00002517          	auipc	a0,0x2
    80006180:	69c50513          	addi	a0,a0,1692 # 80008818 <syscalls+0x368>
    80006184:	ffffa097          	auipc	ra,0xffffa
    80006188:	3c4080e7          	jalr	964(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    8000618c:	00002517          	auipc	a0,0x2
    80006190:	6ac50513          	addi	a0,a0,1708 # 80008838 <syscalls+0x388>
    80006194:	ffffa097          	auipc	ra,0xffffa
    80006198:	3b4080e7          	jalr	948(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    8000619c:	00002517          	auipc	a0,0x2
    800061a0:	6bc50513          	addi	a0,a0,1724 # 80008858 <syscalls+0x3a8>
    800061a4:	ffffa097          	auipc	ra,0xffffa
    800061a8:	3a4080e7          	jalr	932(ra) # 80000548 <panic>

00000000800061ac <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061ac:	7119                	addi	sp,sp,-128
    800061ae:	fc86                	sd	ra,120(sp)
    800061b0:	f8a2                	sd	s0,112(sp)
    800061b2:	f4a6                	sd	s1,104(sp)
    800061b4:	f0ca                	sd	s2,96(sp)
    800061b6:	ecce                	sd	s3,88(sp)
    800061b8:	e8d2                	sd	s4,80(sp)
    800061ba:	e4d6                	sd	s5,72(sp)
    800061bc:	e0da                	sd	s6,64(sp)
    800061be:	fc5e                	sd	s7,56(sp)
    800061c0:	f862                	sd	s8,48(sp)
    800061c2:	f466                	sd	s9,40(sp)
    800061c4:	f06a                	sd	s10,32(sp)
    800061c6:	0100                	addi	s0,sp,128
    800061c8:	892a                	mv	s2,a0
    800061ca:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061cc:	00c52c83          	lw	s9,12(a0)
    800061d0:	001c9c9b          	slliw	s9,s9,0x1
    800061d4:	1c82                	slli	s9,s9,0x20
    800061d6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061da:	0001f517          	auipc	a0,0x1f
    800061de:	ece50513          	addi	a0,a0,-306 # 800250a8 <disk+0x20a8>
    800061e2:	ffffb097          	auipc	ra,0xffffb
    800061e6:	a2e080e7          	jalr	-1490(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    800061ea:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061ec:	4c21                	li	s8,8
      disk.free[i] = 0;
    800061ee:	0001db97          	auipc	s7,0x1d
    800061f2:	e12b8b93          	addi	s7,s7,-494 # 80023000 <disk>
    800061f6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800061f8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800061fa:	8a4e                	mv	s4,s3
    800061fc:	a051                	j	80006280 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800061fe:	00fb86b3          	add	a3,s7,a5
    80006202:	96da                	add	a3,a3,s6
    80006204:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006208:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000620a:	0207c563          	bltz	a5,80006234 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000620e:	2485                	addiw	s1,s1,1
    80006210:	0711                	addi	a4,a4,4
    80006212:	23548d63          	beq	s1,s5,8000644c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006216:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006218:	0001f697          	auipc	a3,0x1f
    8000621c:	e0068693          	addi	a3,a3,-512 # 80025018 <disk+0x2018>
    80006220:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006222:	0006c583          	lbu	a1,0(a3)
    80006226:	fde1                	bnez	a1,800061fe <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006228:	2785                	addiw	a5,a5,1
    8000622a:	0685                	addi	a3,a3,1
    8000622c:	ff879be3          	bne	a5,s8,80006222 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006230:	57fd                	li	a5,-1
    80006232:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006234:	02905a63          	blez	s1,80006268 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006238:	f9042503          	lw	a0,-112(s0)
    8000623c:	00000097          	auipc	ra,0x0
    80006240:	daa080e7          	jalr	-598(ra) # 80005fe6 <free_desc>
      for(int j = 0; j < i; j++)
    80006244:	4785                	li	a5,1
    80006246:	0297d163          	bge	a5,s1,80006268 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000624a:	f9442503          	lw	a0,-108(s0)
    8000624e:	00000097          	auipc	ra,0x0
    80006252:	d98080e7          	jalr	-616(ra) # 80005fe6 <free_desc>
      for(int j = 0; j < i; j++)
    80006256:	4789                	li	a5,2
    80006258:	0097d863          	bge	a5,s1,80006268 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000625c:	f9842503          	lw	a0,-104(s0)
    80006260:	00000097          	auipc	ra,0x0
    80006264:	d86080e7          	jalr	-634(ra) # 80005fe6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006268:	0001f597          	auipc	a1,0x1f
    8000626c:	e4058593          	addi	a1,a1,-448 # 800250a8 <disk+0x20a8>
    80006270:	0001f517          	auipc	a0,0x1f
    80006274:	da850513          	addi	a0,a0,-600 # 80025018 <disk+0x2018>
    80006278:	ffffc097          	auipc	ra,0xffffc
    8000627c:	2b4080e7          	jalr	692(ra) # 8000252c <sleep>
  for(int i = 0; i < 3; i++){
    80006280:	f9040713          	addi	a4,s0,-112
    80006284:	84ce                	mv	s1,s3
    80006286:	bf41                	j	80006216 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006288:	4785                	li	a5,1
    8000628a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000628e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006292:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006296:	f9042983          	lw	s3,-112(s0)
    8000629a:	00499493          	slli	s1,s3,0x4
    8000629e:	0001fa17          	auipc	s4,0x1f
    800062a2:	d62a0a13          	addi	s4,s4,-670 # 80025000 <disk+0x2000>
    800062a6:	000a3a83          	ld	s5,0(s4)
    800062aa:	9aa6                	add	s5,s5,s1
    800062ac:	f8040513          	addi	a0,s0,-128
    800062b0:	ffffb097          	auipc	ra,0xffffb
    800062b4:	e38080e7          	jalr	-456(ra) # 800010e8 <kvmpa>
    800062b8:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    800062bc:	000a3783          	ld	a5,0(s4)
    800062c0:	97a6                	add	a5,a5,s1
    800062c2:	4741                	li	a4,16
    800062c4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062c6:	000a3783          	ld	a5,0(s4)
    800062ca:	97a6                	add	a5,a5,s1
    800062cc:	4705                	li	a4,1
    800062ce:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800062d2:	f9442703          	lw	a4,-108(s0)
    800062d6:	000a3783          	ld	a5,0(s4)
    800062da:	97a6                	add	a5,a5,s1
    800062dc:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062e0:	0712                	slli	a4,a4,0x4
    800062e2:	000a3783          	ld	a5,0(s4)
    800062e6:	97ba                	add	a5,a5,a4
    800062e8:	05890693          	addi	a3,s2,88
    800062ec:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800062ee:	000a3783          	ld	a5,0(s4)
    800062f2:	97ba                	add	a5,a5,a4
    800062f4:	40000693          	li	a3,1024
    800062f8:	c794                	sw	a3,8(a5)
  if(write)
    800062fa:	100d0a63          	beqz	s10,8000640e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062fe:	0001f797          	auipc	a5,0x1f
    80006302:	d027b783          	ld	a5,-766(a5) # 80025000 <disk+0x2000>
    80006306:	97ba                	add	a5,a5,a4
    80006308:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000630c:	0001d517          	auipc	a0,0x1d
    80006310:	cf450513          	addi	a0,a0,-780 # 80023000 <disk>
    80006314:	0001f797          	auipc	a5,0x1f
    80006318:	cec78793          	addi	a5,a5,-788 # 80025000 <disk+0x2000>
    8000631c:	6394                	ld	a3,0(a5)
    8000631e:	96ba                	add	a3,a3,a4
    80006320:	00c6d603          	lhu	a2,12(a3)
    80006324:	00166613          	ori	a2,a2,1
    80006328:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000632c:	f9842683          	lw	a3,-104(s0)
    80006330:	6390                	ld	a2,0(a5)
    80006332:	9732                	add	a4,a4,a2
    80006334:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006338:	20098613          	addi	a2,s3,512
    8000633c:	0612                	slli	a2,a2,0x4
    8000633e:	962a                	add	a2,a2,a0
    80006340:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006344:	00469713          	slli	a4,a3,0x4
    80006348:	6394                	ld	a3,0(a5)
    8000634a:	96ba                	add	a3,a3,a4
    8000634c:	6589                	lui	a1,0x2
    8000634e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006352:	94ae                	add	s1,s1,a1
    80006354:	94aa                	add	s1,s1,a0
    80006356:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006358:	6394                	ld	a3,0(a5)
    8000635a:	96ba                	add	a3,a3,a4
    8000635c:	4585                	li	a1,1
    8000635e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006360:	6394                	ld	a3,0(a5)
    80006362:	96ba                	add	a3,a3,a4
    80006364:	4509                	li	a0,2
    80006366:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000636a:	6394                	ld	a3,0(a5)
    8000636c:	9736                	add	a4,a4,a3
    8000636e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006372:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006376:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000637a:	6794                	ld	a3,8(a5)
    8000637c:	0026d703          	lhu	a4,2(a3)
    80006380:	8b1d                	andi	a4,a4,7
    80006382:	2709                	addiw	a4,a4,2
    80006384:	0706                	slli	a4,a4,0x1
    80006386:	9736                	add	a4,a4,a3
    80006388:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000638c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006390:	6798                	ld	a4,8(a5)
    80006392:	00275783          	lhu	a5,2(a4)
    80006396:	2785                	addiw	a5,a5,1
    80006398:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000639c:	100017b7          	lui	a5,0x10001
    800063a0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063a4:	00492703          	lw	a4,4(s2)
    800063a8:	4785                	li	a5,1
    800063aa:	02f71163          	bne	a4,a5,800063cc <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    800063ae:	0001f997          	auipc	s3,0x1f
    800063b2:	cfa98993          	addi	s3,s3,-774 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800063b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800063b8:	85ce                	mv	a1,s3
    800063ba:	854a                	mv	a0,s2
    800063bc:	ffffc097          	auipc	ra,0xffffc
    800063c0:	170080e7          	jalr	368(ra) # 8000252c <sleep>
  while(b->disk == 1) {
    800063c4:	00492783          	lw	a5,4(s2)
    800063c8:	fe9788e3          	beq	a5,s1,800063b8 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800063cc:	f9042483          	lw	s1,-112(s0)
    800063d0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800063d4:	00479713          	slli	a4,a5,0x4
    800063d8:	0001d797          	auipc	a5,0x1d
    800063dc:	c2878793          	addi	a5,a5,-984 # 80023000 <disk>
    800063e0:	97ba                	add	a5,a5,a4
    800063e2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800063e6:	0001f917          	auipc	s2,0x1f
    800063ea:	c1a90913          	addi	s2,s2,-998 # 80025000 <disk+0x2000>
    free_desc(i);
    800063ee:	8526                	mv	a0,s1
    800063f0:	00000097          	auipc	ra,0x0
    800063f4:	bf6080e7          	jalr	-1034(ra) # 80005fe6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800063f8:	0492                	slli	s1,s1,0x4
    800063fa:	00093783          	ld	a5,0(s2)
    800063fe:	94be                	add	s1,s1,a5
    80006400:	00c4d783          	lhu	a5,12(s1)
    80006404:	8b85                	andi	a5,a5,1
    80006406:	cf89                	beqz	a5,80006420 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006408:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000640c:	b7cd                	j	800063ee <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000640e:	0001f797          	auipc	a5,0x1f
    80006412:	bf27b783          	ld	a5,-1038(a5) # 80025000 <disk+0x2000>
    80006416:	97ba                	add	a5,a5,a4
    80006418:	4689                	li	a3,2
    8000641a:	00d79623          	sh	a3,12(a5)
    8000641e:	b5fd                	j	8000630c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006420:	0001f517          	auipc	a0,0x1f
    80006424:	c8850513          	addi	a0,a0,-888 # 800250a8 <disk+0x20a8>
    80006428:	ffffb097          	auipc	ra,0xffffb
    8000642c:	89c080e7          	jalr	-1892(ra) # 80000cc4 <release>
}
    80006430:	70e6                	ld	ra,120(sp)
    80006432:	7446                	ld	s0,112(sp)
    80006434:	74a6                	ld	s1,104(sp)
    80006436:	7906                	ld	s2,96(sp)
    80006438:	69e6                	ld	s3,88(sp)
    8000643a:	6a46                	ld	s4,80(sp)
    8000643c:	6aa6                	ld	s5,72(sp)
    8000643e:	6b06                	ld	s6,64(sp)
    80006440:	7be2                	ld	s7,56(sp)
    80006442:	7c42                	ld	s8,48(sp)
    80006444:	7ca2                	ld	s9,40(sp)
    80006446:	7d02                	ld	s10,32(sp)
    80006448:	6109                	addi	sp,sp,128
    8000644a:	8082                	ret
  if(write)
    8000644c:	e20d1ee3          	bnez	s10,80006288 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006450:	f8042023          	sw	zero,-128(s0)
    80006454:	bd2d                	j	8000628e <virtio_disk_rw+0xe2>

0000000080006456 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006456:	1101                	addi	sp,sp,-32
    80006458:	ec06                	sd	ra,24(sp)
    8000645a:	e822                	sd	s0,16(sp)
    8000645c:	e426                	sd	s1,8(sp)
    8000645e:	e04a                	sd	s2,0(sp)
    80006460:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006462:	0001f517          	auipc	a0,0x1f
    80006466:	c4650513          	addi	a0,a0,-954 # 800250a8 <disk+0x20a8>
    8000646a:	ffffa097          	auipc	ra,0xffffa
    8000646e:	7a6080e7          	jalr	1958(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006472:	0001f717          	auipc	a4,0x1f
    80006476:	b8e70713          	addi	a4,a4,-1138 # 80025000 <disk+0x2000>
    8000647a:	02075783          	lhu	a5,32(a4)
    8000647e:	6b18                	ld	a4,16(a4)
    80006480:	00275683          	lhu	a3,2(a4)
    80006484:	8ebd                	xor	a3,a3,a5
    80006486:	8a9d                	andi	a3,a3,7
    80006488:	cab9                	beqz	a3,800064de <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000648a:	0001d917          	auipc	s2,0x1d
    8000648e:	b7690913          	addi	s2,s2,-1162 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006492:	0001f497          	auipc	s1,0x1f
    80006496:	b6e48493          	addi	s1,s1,-1170 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000649a:	078e                	slli	a5,a5,0x3
    8000649c:	97ba                	add	a5,a5,a4
    8000649e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800064a0:	20078713          	addi	a4,a5,512
    800064a4:	0712                	slli	a4,a4,0x4
    800064a6:	974a                	add	a4,a4,s2
    800064a8:	03074703          	lbu	a4,48(a4)
    800064ac:	ef21                	bnez	a4,80006504 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800064ae:	20078793          	addi	a5,a5,512
    800064b2:	0792                	slli	a5,a5,0x4
    800064b4:	97ca                	add	a5,a5,s2
    800064b6:	7798                	ld	a4,40(a5)
    800064b8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800064bc:	7788                	ld	a0,40(a5)
    800064be:	ffffc097          	auipc	ra,0xffffc
    800064c2:	1f4080e7          	jalr	500(ra) # 800026b2 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800064c6:	0204d783          	lhu	a5,32(s1)
    800064ca:	2785                	addiw	a5,a5,1
    800064cc:	8b9d                	andi	a5,a5,7
    800064ce:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800064d2:	6898                	ld	a4,16(s1)
    800064d4:	00275683          	lhu	a3,2(a4)
    800064d8:	8a9d                	andi	a3,a3,7
    800064da:	fcf690e3          	bne	a3,a5,8000649a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064de:	10001737          	lui	a4,0x10001
    800064e2:	533c                	lw	a5,96(a4)
    800064e4:	8b8d                	andi	a5,a5,3
    800064e6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800064e8:	0001f517          	auipc	a0,0x1f
    800064ec:	bc050513          	addi	a0,a0,-1088 # 800250a8 <disk+0x20a8>
    800064f0:	ffffa097          	auipc	ra,0xffffa
    800064f4:	7d4080e7          	jalr	2004(ra) # 80000cc4 <release>
}
    800064f8:	60e2                	ld	ra,24(sp)
    800064fa:	6442                	ld	s0,16(sp)
    800064fc:	64a2                	ld	s1,8(sp)
    800064fe:	6902                	ld	s2,0(sp)
    80006500:	6105                	addi	sp,sp,32
    80006502:	8082                	ret
      panic("virtio_disk_intr status");
    80006504:	00002517          	auipc	a0,0x2
    80006508:	37450513          	addi	a0,a0,884 # 80008878 <syscalls+0x3c8>
    8000650c:	ffffa097          	auipc	ra,0xffffa
    80006510:	03c080e7          	jalr	60(ra) # 80000548 <panic>

0000000080006514 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    80006514:	7179                	addi	sp,sp,-48
    80006516:	f406                	sd	ra,40(sp)
    80006518:	f022                	sd	s0,32(sp)
    8000651a:	ec26                	sd	s1,24(sp)
    8000651c:	e84a                	sd	s2,16(sp)
    8000651e:	e44e                	sd	s3,8(sp)
    80006520:	e052                	sd	s4,0(sp)
    80006522:	1800                	addi	s0,sp,48
    80006524:	892a                	mv	s2,a0
    80006526:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    80006528:	00003a17          	auipc	s4,0x3
    8000652c:	b00a0a13          	addi	s4,s4,-1280 # 80009028 <stats>
    80006530:	000a2683          	lw	a3,0(s4)
    80006534:	00002617          	auipc	a2,0x2
    80006538:	35c60613          	addi	a2,a2,860 # 80008890 <syscalls+0x3e0>
    8000653c:	00000097          	auipc	ra,0x0
    80006540:	2c2080e7          	jalr	706(ra) # 800067fe <snprintf>
    80006544:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    80006546:	004a2683          	lw	a3,4(s4)
    8000654a:	00002617          	auipc	a2,0x2
    8000654e:	35660613          	addi	a2,a2,854 # 800088a0 <syscalls+0x3f0>
    80006552:	85ce                	mv	a1,s3
    80006554:	954a                	add	a0,a0,s2
    80006556:	00000097          	auipc	ra,0x0
    8000655a:	2a8080e7          	jalr	680(ra) # 800067fe <snprintf>
  return n;
}
    8000655e:	9d25                	addw	a0,a0,s1
    80006560:	70a2                	ld	ra,40(sp)
    80006562:	7402                	ld	s0,32(sp)
    80006564:	64e2                	ld	s1,24(sp)
    80006566:	6942                	ld	s2,16(sp)
    80006568:	69a2                	ld	s3,8(sp)
    8000656a:	6a02                	ld	s4,0(sp)
    8000656c:	6145                	addi	sp,sp,48
    8000656e:	8082                	ret

0000000080006570 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80006570:	7179                	addi	sp,sp,-48
    80006572:	f406                	sd	ra,40(sp)
    80006574:	f022                	sd	s0,32(sp)
    80006576:	ec26                	sd	s1,24(sp)
    80006578:	e84a                	sd	s2,16(sp)
    8000657a:	e44e                	sd	s3,8(sp)
    8000657c:	1800                	addi	s0,sp,48
    8000657e:	89ae                	mv	s3,a1
    80006580:	84b2                	mv	s1,a2
    80006582:	8936                	mv	s2,a3
  struct proc *p = myproc();
    80006584:	ffffb097          	auipc	ra,0xffffb
    80006588:	59a080e7          	jalr	1434(ra) # 80001b1e <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    8000658c:	693c                	ld	a5,80(a0)
    8000658e:	02f4ff63          	bgeu	s1,a5,800065cc <copyin_new+0x5c>
    80006592:	01248733          	add	a4,s1,s2
    80006596:	02f77d63          	bgeu	a4,a5,800065d0 <copyin_new+0x60>
    8000659a:	02976d63          	bltu	a4,s1,800065d4 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    8000659e:	0009061b          	sext.w	a2,s2
    800065a2:	85a6                	mv	a1,s1
    800065a4:	854e                	mv	a0,s3
    800065a6:	ffffa097          	auipc	ra,0xffffa
    800065aa:	7c6080e7          	jalr	1990(ra) # 80000d6c <memmove>
  stats.ncopyin++;   // XXX lock
    800065ae:	00003717          	auipc	a4,0x3
    800065b2:	a7a70713          	addi	a4,a4,-1414 # 80009028 <stats>
    800065b6:	431c                	lw	a5,0(a4)
    800065b8:	2785                	addiw	a5,a5,1
    800065ba:	c31c                	sw	a5,0(a4)
  return 0;
    800065bc:	4501                	li	a0,0
}
    800065be:	70a2                	ld	ra,40(sp)
    800065c0:	7402                	ld	s0,32(sp)
    800065c2:	64e2                	ld	s1,24(sp)
    800065c4:	6942                	ld	s2,16(sp)
    800065c6:	69a2                	ld	s3,8(sp)
    800065c8:	6145                	addi	sp,sp,48
    800065ca:	8082                	ret
    return -1;
    800065cc:	557d                	li	a0,-1
    800065ce:	bfc5                	j	800065be <copyin_new+0x4e>
    800065d0:	557d                	li	a0,-1
    800065d2:	b7f5                	j	800065be <copyin_new+0x4e>
    800065d4:	557d                	li	a0,-1
    800065d6:	b7e5                	j	800065be <copyin_new+0x4e>

00000000800065d8 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    800065d8:	7179                	addi	sp,sp,-48
    800065da:	f406                	sd	ra,40(sp)
    800065dc:	f022                	sd	s0,32(sp)
    800065de:	ec26                	sd	s1,24(sp)
    800065e0:	e84a                	sd	s2,16(sp)
    800065e2:	e44e                	sd	s3,8(sp)
    800065e4:	1800                	addi	s0,sp,48
    800065e6:	89ae                	mv	s3,a1
    800065e8:	8932                	mv	s2,a2
    800065ea:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    800065ec:	ffffb097          	auipc	ra,0xffffb
    800065f0:	532080e7          	jalr	1330(ra) # 80001b1e <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    800065f4:	00003717          	auipc	a4,0x3
    800065f8:	a3470713          	addi	a4,a4,-1484 # 80009028 <stats>
    800065fc:	435c                	lw	a5,4(a4)
    800065fe:	2785                	addiw	a5,a5,1
    80006600:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006602:	cc85                	beqz	s1,8000663a <copyinstr_new+0x62>
    80006604:	00990833          	add	a6,s2,s1
    80006608:	87ca                	mv	a5,s2
    8000660a:	6938                	ld	a4,80(a0)
    8000660c:	00e7ff63          	bgeu	a5,a4,8000662a <copyinstr_new+0x52>
    dst[i] = s[i];
    80006610:	0007c683          	lbu	a3,0(a5)
    80006614:	41278733          	sub	a4,a5,s2
    80006618:	974e                	add	a4,a4,s3
    8000661a:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    8000661e:	c285                	beqz	a3,8000663e <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006620:	0785                	addi	a5,a5,1
    80006622:	ff0794e3          	bne	a5,a6,8000660a <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    80006626:	557d                	li	a0,-1
    80006628:	a011                	j	8000662c <copyinstr_new+0x54>
    8000662a:	557d                	li	a0,-1
}
    8000662c:	70a2                	ld	ra,40(sp)
    8000662e:	7402                	ld	s0,32(sp)
    80006630:	64e2                	ld	s1,24(sp)
    80006632:	6942                	ld	s2,16(sp)
    80006634:	69a2                	ld	s3,8(sp)
    80006636:	6145                	addi	sp,sp,48
    80006638:	8082                	ret
  return -1;
    8000663a:	557d                	li	a0,-1
    8000663c:	bfc5                	j	8000662c <copyinstr_new+0x54>
      return 0;
    8000663e:	4501                	li	a0,0
    80006640:	b7f5                	j	8000662c <copyinstr_new+0x54>

0000000080006642 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006642:	1141                	addi	sp,sp,-16
    80006644:	e422                	sd	s0,8(sp)
    80006646:	0800                	addi	s0,sp,16
  return -1;
}
    80006648:	557d                	li	a0,-1
    8000664a:	6422                	ld	s0,8(sp)
    8000664c:	0141                	addi	sp,sp,16
    8000664e:	8082                	ret

0000000080006650 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006650:	7179                	addi	sp,sp,-48
    80006652:	f406                	sd	ra,40(sp)
    80006654:	f022                	sd	s0,32(sp)
    80006656:	ec26                	sd	s1,24(sp)
    80006658:	e84a                	sd	s2,16(sp)
    8000665a:	e44e                	sd	s3,8(sp)
    8000665c:	e052                	sd	s4,0(sp)
    8000665e:	1800                	addi	s0,sp,48
    80006660:	892a                	mv	s2,a0
    80006662:	89ae                	mv	s3,a1
    80006664:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    80006666:	00020517          	auipc	a0,0x20
    8000666a:	99a50513          	addi	a0,a0,-1638 # 80026000 <stats>
    8000666e:	ffffa097          	auipc	ra,0xffffa
    80006672:	5a2080e7          	jalr	1442(ra) # 80000c10 <acquire>

  if(stats.sz == 0) {
    80006676:	00021797          	auipc	a5,0x21
    8000667a:	9a27a783          	lw	a5,-1630(a5) # 80027018 <stats+0x1018>
    8000667e:	cbb5                	beqz	a5,800066f2 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006680:	00021797          	auipc	a5,0x21
    80006684:	98078793          	addi	a5,a5,-1664 # 80027000 <stats+0x1000>
    80006688:	4fd8                	lw	a4,28(a5)
    8000668a:	4f9c                	lw	a5,24(a5)
    8000668c:	9f99                	subw	a5,a5,a4
    8000668e:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006692:	06d05e63          	blez	a3,8000670e <statsread+0xbe>
    if(m > n)
    80006696:	8a3e                	mv	s4,a5
    80006698:	00d4d363          	bge	s1,a3,8000669e <statsread+0x4e>
    8000669c:	8a26                	mv	s4,s1
    8000669e:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800066a2:	86a6                	mv	a3,s1
    800066a4:	00020617          	auipc	a2,0x20
    800066a8:	97460613          	addi	a2,a2,-1676 # 80026018 <stats+0x18>
    800066ac:	963a                	add	a2,a2,a4
    800066ae:	85ce                	mv	a1,s3
    800066b0:	854a                	mv	a0,s2
    800066b2:	ffffc097          	auipc	ra,0xffffc
    800066b6:	0dc080e7          	jalr	220(ra) # 8000278e <either_copyout>
    800066ba:	57fd                	li	a5,-1
    800066bc:	00f50a63          	beq	a0,a5,800066d0 <statsread+0x80>
      stats.off += m;
    800066c0:	00021717          	auipc	a4,0x21
    800066c4:	94070713          	addi	a4,a4,-1728 # 80027000 <stats+0x1000>
    800066c8:	4f5c                	lw	a5,28(a4)
    800066ca:	014787bb          	addw	a5,a5,s4
    800066ce:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    800066d0:	00020517          	auipc	a0,0x20
    800066d4:	93050513          	addi	a0,a0,-1744 # 80026000 <stats>
    800066d8:	ffffa097          	auipc	ra,0xffffa
    800066dc:	5ec080e7          	jalr	1516(ra) # 80000cc4 <release>
  return m;
}
    800066e0:	8526                	mv	a0,s1
    800066e2:	70a2                	ld	ra,40(sp)
    800066e4:	7402                	ld	s0,32(sp)
    800066e6:	64e2                	ld	s1,24(sp)
    800066e8:	6942                	ld	s2,16(sp)
    800066ea:	69a2                	ld	s3,8(sp)
    800066ec:	6a02                	ld	s4,0(sp)
    800066ee:	6145                	addi	sp,sp,48
    800066f0:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    800066f2:	6585                	lui	a1,0x1
    800066f4:	00020517          	auipc	a0,0x20
    800066f8:	92450513          	addi	a0,a0,-1756 # 80026018 <stats+0x18>
    800066fc:	00000097          	auipc	ra,0x0
    80006700:	e18080e7          	jalr	-488(ra) # 80006514 <statscopyin>
    80006704:	00021797          	auipc	a5,0x21
    80006708:	90a7aa23          	sw	a0,-1772(a5) # 80027018 <stats+0x1018>
    8000670c:	bf95                	j	80006680 <statsread+0x30>
    stats.sz = 0;
    8000670e:	00021797          	auipc	a5,0x21
    80006712:	8f278793          	addi	a5,a5,-1806 # 80027000 <stats+0x1000>
    80006716:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    8000671a:	0007ae23          	sw	zero,28(a5)
    m = -1;
    8000671e:	54fd                	li	s1,-1
    80006720:	bf45                	j	800066d0 <statsread+0x80>

0000000080006722 <statsinit>:

void
statsinit(void)
{
    80006722:	1141                	addi	sp,sp,-16
    80006724:	e406                	sd	ra,8(sp)
    80006726:	e022                	sd	s0,0(sp)
    80006728:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    8000672a:	00002597          	auipc	a1,0x2
    8000672e:	18658593          	addi	a1,a1,390 # 800088b0 <syscalls+0x400>
    80006732:	00020517          	auipc	a0,0x20
    80006736:	8ce50513          	addi	a0,a0,-1842 # 80026000 <stats>
    8000673a:	ffffa097          	auipc	ra,0xffffa
    8000673e:	446080e7          	jalr	1094(ra) # 80000b80 <initlock>

  devsw[STATS].read = statsread;
    80006742:	0001b797          	auipc	a5,0x1b
    80006746:	46e78793          	addi	a5,a5,1134 # 80021bb0 <devsw>
    8000674a:	00000717          	auipc	a4,0x0
    8000674e:	f0670713          	addi	a4,a4,-250 # 80006650 <statsread>
    80006752:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006754:	00000717          	auipc	a4,0x0
    80006758:	eee70713          	addi	a4,a4,-274 # 80006642 <statswrite>
    8000675c:	f798                	sd	a4,40(a5)
}
    8000675e:	60a2                	ld	ra,8(sp)
    80006760:	6402                	ld	s0,0(sp)
    80006762:	0141                	addi	sp,sp,16
    80006764:	8082                	ret

0000000080006766 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    80006766:	1101                	addi	sp,sp,-32
    80006768:	ec22                	sd	s0,24(sp)
    8000676a:	1000                	addi	s0,sp,32
    8000676c:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    8000676e:	c299                	beqz	a3,80006774 <sprintint+0xe>
    80006770:	0805c163          	bltz	a1,800067f2 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006774:	2581                	sext.w	a1,a1
    80006776:	4301                	li	t1,0

  i = 0;
    80006778:	fe040713          	addi	a4,s0,-32
    8000677c:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    8000677e:	2601                	sext.w	a2,a2
    80006780:	00002697          	auipc	a3,0x2
    80006784:	13868693          	addi	a3,a3,312 # 800088b8 <digits>
    80006788:	88aa                	mv	a7,a0
    8000678a:	2505                	addiw	a0,a0,1
    8000678c:	02c5f7bb          	remuw	a5,a1,a2
    80006790:	1782                	slli	a5,a5,0x20
    80006792:	9381                	srli	a5,a5,0x20
    80006794:	97b6                	add	a5,a5,a3
    80006796:	0007c783          	lbu	a5,0(a5)
    8000679a:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000679e:	0005879b          	sext.w	a5,a1
    800067a2:	02c5d5bb          	divuw	a1,a1,a2
    800067a6:	0705                	addi	a4,a4,1
    800067a8:	fec7f0e3          	bgeu	a5,a2,80006788 <sprintint+0x22>

  if(sign)
    800067ac:	00030b63          	beqz	t1,800067c2 <sprintint+0x5c>
    buf[i++] = '-';
    800067b0:	ff040793          	addi	a5,s0,-16
    800067b4:	97aa                	add	a5,a5,a0
    800067b6:	02d00713          	li	a4,45
    800067ba:	fee78823          	sb	a4,-16(a5)
    800067be:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    800067c2:	02a05c63          	blez	a0,800067fa <sprintint+0x94>
    800067c6:	fe040793          	addi	a5,s0,-32
    800067ca:	00a78733          	add	a4,a5,a0
    800067ce:	87c2                	mv	a5,a6
    800067d0:	0805                	addi	a6,a6,1
    800067d2:	fff5061b          	addiw	a2,a0,-1
    800067d6:	1602                	slli	a2,a2,0x20
    800067d8:	9201                	srli	a2,a2,0x20
    800067da:	9642                	add	a2,a2,a6
  *s = c;
    800067dc:	fff74683          	lbu	a3,-1(a4)
    800067e0:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    800067e4:	177d                	addi	a4,a4,-1
    800067e6:	0785                	addi	a5,a5,1
    800067e8:	fec79ae3          	bne	a5,a2,800067dc <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    800067ec:	6462                	ld	s0,24(sp)
    800067ee:	6105                	addi	sp,sp,32
    800067f0:	8082                	ret
    x = -xx;
    800067f2:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    800067f6:	4305                	li	t1,1
    x = -xx;
    800067f8:	b741                	j	80006778 <sprintint+0x12>
  while(--i >= 0)
    800067fa:	4501                	li	a0,0
    800067fc:	bfc5                	j	800067ec <sprintint+0x86>

00000000800067fe <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    800067fe:	7171                	addi	sp,sp,-176
    80006800:	fc86                	sd	ra,120(sp)
    80006802:	f8a2                	sd	s0,112(sp)
    80006804:	f4a6                	sd	s1,104(sp)
    80006806:	f0ca                	sd	s2,96(sp)
    80006808:	ecce                	sd	s3,88(sp)
    8000680a:	e8d2                	sd	s4,80(sp)
    8000680c:	e4d6                	sd	s5,72(sp)
    8000680e:	e0da                	sd	s6,64(sp)
    80006810:	fc5e                	sd	s7,56(sp)
    80006812:	f862                	sd	s8,48(sp)
    80006814:	f466                	sd	s9,40(sp)
    80006816:	f06a                	sd	s10,32(sp)
    80006818:	ec6e                	sd	s11,24(sp)
    8000681a:	0100                	addi	s0,sp,128
    8000681c:	e414                	sd	a3,8(s0)
    8000681e:	e818                	sd	a4,16(s0)
    80006820:	ec1c                	sd	a5,24(s0)
    80006822:	03043023          	sd	a6,32(s0)
    80006826:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    8000682a:	ca0d                	beqz	a2,8000685c <snprintf+0x5e>
    8000682c:	8baa                	mv	s7,a0
    8000682e:	89ae                	mv	s3,a1
    80006830:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006832:	00840793          	addi	a5,s0,8
    80006836:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    8000683a:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000683c:	4901                	li	s2,0
    8000683e:	02b05763          	blez	a1,8000686c <snprintf+0x6e>
    if(c != '%'){
    80006842:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006846:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    8000684a:	02800d93          	li	s11,40
  *s = c;
    8000684e:	02500d13          	li	s10,37
    switch(c){
    80006852:	07800c93          	li	s9,120
    80006856:	06400c13          	li	s8,100
    8000685a:	a01d                	j	80006880 <snprintf+0x82>
    panic("null fmt");
    8000685c:	00001517          	auipc	a0,0x1
    80006860:	7cc50513          	addi	a0,a0,1996 # 80008028 <etext+0x28>
    80006864:	ffffa097          	auipc	ra,0xffffa
    80006868:	ce4080e7          	jalr	-796(ra) # 80000548 <panic>
  int off = 0;
    8000686c:	4481                	li	s1,0
    8000686e:	a86d                	j	80006928 <snprintf+0x12a>
  *s = c;
    80006870:	009b8733          	add	a4,s7,s1
    80006874:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006878:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000687a:	2905                	addiw	s2,s2,1
    8000687c:	0b34d663          	bge	s1,s3,80006928 <snprintf+0x12a>
    80006880:	012a07b3          	add	a5,s4,s2
    80006884:	0007c783          	lbu	a5,0(a5)
    80006888:	0007871b          	sext.w	a4,a5
    8000688c:	cfd1                	beqz	a5,80006928 <snprintf+0x12a>
    if(c != '%'){
    8000688e:	ff5711e3          	bne	a4,s5,80006870 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    80006892:	2905                	addiw	s2,s2,1
    80006894:	012a07b3          	add	a5,s4,s2
    80006898:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    8000689c:	c7d1                	beqz	a5,80006928 <snprintf+0x12a>
    switch(c){
    8000689e:	05678c63          	beq	a5,s6,800068f6 <snprintf+0xf8>
    800068a2:	02fb6763          	bltu	s6,a5,800068d0 <snprintf+0xd2>
    800068a6:	0b578763          	beq	a5,s5,80006954 <snprintf+0x156>
    800068aa:	0b879b63          	bne	a5,s8,80006960 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    800068ae:	f8843783          	ld	a5,-120(s0)
    800068b2:	00878713          	addi	a4,a5,8
    800068b6:	f8e43423          	sd	a4,-120(s0)
    800068ba:	4685                	li	a3,1
    800068bc:	4629                	li	a2,10
    800068be:	438c                	lw	a1,0(a5)
    800068c0:	009b8533          	add	a0,s7,s1
    800068c4:	00000097          	auipc	ra,0x0
    800068c8:	ea2080e7          	jalr	-350(ra) # 80006766 <sprintint>
    800068cc:	9ca9                	addw	s1,s1,a0
      break;
    800068ce:	b775                	j	8000687a <snprintf+0x7c>
    switch(c){
    800068d0:	09979863          	bne	a5,s9,80006960 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    800068d4:	f8843783          	ld	a5,-120(s0)
    800068d8:	00878713          	addi	a4,a5,8
    800068dc:	f8e43423          	sd	a4,-120(s0)
    800068e0:	4685                	li	a3,1
    800068e2:	4641                	li	a2,16
    800068e4:	438c                	lw	a1,0(a5)
    800068e6:	009b8533          	add	a0,s7,s1
    800068ea:	00000097          	auipc	ra,0x0
    800068ee:	e7c080e7          	jalr	-388(ra) # 80006766 <sprintint>
    800068f2:	9ca9                	addw	s1,s1,a0
      break;
    800068f4:	b759                	j	8000687a <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    800068f6:	f8843783          	ld	a5,-120(s0)
    800068fa:	00878713          	addi	a4,a5,8
    800068fe:	f8e43423          	sd	a4,-120(s0)
    80006902:	639c                	ld	a5,0(a5)
    80006904:	c3b1                	beqz	a5,80006948 <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006906:	0007c703          	lbu	a4,0(a5)
    8000690a:	db25                	beqz	a4,8000687a <snprintf+0x7c>
    8000690c:	0134de63          	bge	s1,s3,80006928 <snprintf+0x12a>
    80006910:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006914:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006918:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    8000691a:	0785                	addi	a5,a5,1
    8000691c:	0007c703          	lbu	a4,0(a5)
    80006920:	df29                	beqz	a4,8000687a <snprintf+0x7c>
    80006922:	0685                	addi	a3,a3,1
    80006924:	fe9998e3          	bne	s3,s1,80006914 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006928:	8526                	mv	a0,s1
    8000692a:	70e6                	ld	ra,120(sp)
    8000692c:	7446                	ld	s0,112(sp)
    8000692e:	74a6                	ld	s1,104(sp)
    80006930:	7906                	ld	s2,96(sp)
    80006932:	69e6                	ld	s3,88(sp)
    80006934:	6a46                	ld	s4,80(sp)
    80006936:	6aa6                	ld	s5,72(sp)
    80006938:	6b06                	ld	s6,64(sp)
    8000693a:	7be2                	ld	s7,56(sp)
    8000693c:	7c42                	ld	s8,48(sp)
    8000693e:	7ca2                	ld	s9,40(sp)
    80006940:	7d02                	ld	s10,32(sp)
    80006942:	6de2                	ld	s11,24(sp)
    80006944:	614d                	addi	sp,sp,176
    80006946:	8082                	ret
        s = "(null)";
    80006948:	00001797          	auipc	a5,0x1
    8000694c:	6d878793          	addi	a5,a5,1752 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    80006950:	876e                	mv	a4,s11
    80006952:	bf6d                	j	8000690c <snprintf+0x10e>
  *s = c;
    80006954:	009b87b3          	add	a5,s7,s1
    80006958:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    8000695c:	2485                	addiw	s1,s1,1
      break;
    8000695e:	bf31                	j	8000687a <snprintf+0x7c>
  *s = c;
    80006960:	009b8733          	add	a4,s7,s1
    80006964:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006968:	0014871b          	addiw	a4,s1,1
  *s = c;
    8000696c:	975e                	add	a4,a4,s7
    8000696e:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006972:	2489                	addiw	s1,s1,2
      break;
    80006974:	b719                	j	8000687a <snprintf+0x7c>
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
