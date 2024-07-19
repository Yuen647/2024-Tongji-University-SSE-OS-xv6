
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	17010113          	addi	sp,sp,368 # 80009170 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fde70713          	addi	a4,a4,-34 # 80009030 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	16c78793          	addi	a5,a5,364 # 800061d0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd37d7>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	25278793          	addi	a5,a5,594 # 80001300 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
    80000106:	8a2a                	mv	s4,a0
    80000108:	84ae                	mv	s1,a1
    8000010a:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    8000010c:	00011517          	auipc	a0,0x11
    80000110:	06450513          	addi	a0,a0,100 # 80011170 <cons>
    80000114:	00001097          	auipc	ra,0x1
    80000118:	c5a080e7          	jalr	-934(ra) # 80000d6e <acquire>
  for(i = 0; i < n; i++){
    8000011c:	05305b63          	blez	s3,80000172 <consolewrite+0x7e>
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	addi	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	750080e7          	jalr	1872(ra) # 8000287e <either_copyin>
    80000136:	01550c63          	beq	a0,s5,8000014e <consolewrite+0x5a>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	7aa080e7          	jalr	1962(ra) # 800008e8 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addiw	s2,s2,1
    80000148:	0485                	addi	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x30>
  }
  release(&cons.lock);
    8000014e:	00011517          	auipc	a0,0x11
    80000152:	02250513          	addi	a0,a0,34 # 80011170 <cons>
    80000156:	00001097          	auipc	ra,0x1
    8000015a:	ce8080e7          	jalr	-792(ra) # 80000e3e <release>

  return i;
}
    8000015e:	854a                	mv	a0,s2
    80000160:	60a6                	ld	ra,72(sp)
    80000162:	6406                	ld	s0,64(sp)
    80000164:	74e2                	ld	s1,56(sp)
    80000166:	7942                	ld	s2,48(sp)
    80000168:	79a2                	ld	s3,40(sp)
    8000016a:	7a02                	ld	s4,32(sp)
    8000016c:	6ae2                	ld	s5,24(sp)
    8000016e:	6161                	addi	sp,sp,80
    80000170:	8082                	ret
  for(i = 0; i < n; i++){
    80000172:	4901                	li	s2,0
    80000174:	bfe9                	j	8000014e <consolewrite+0x5a>

0000000080000176 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000176:	7119                	addi	sp,sp,-128
    80000178:	fc86                	sd	ra,120(sp)
    8000017a:	f8a2                	sd	s0,112(sp)
    8000017c:	f4a6                	sd	s1,104(sp)
    8000017e:	f0ca                	sd	s2,96(sp)
    80000180:	ecce                	sd	s3,88(sp)
    80000182:	e8d2                	sd	s4,80(sp)
    80000184:	e4d6                	sd	s5,72(sp)
    80000186:	e0da                	sd	s6,64(sp)
    80000188:	fc5e                	sd	s7,56(sp)
    8000018a:	f862                	sd	s8,48(sp)
    8000018c:	f466                	sd	s9,40(sp)
    8000018e:	f06a                	sd	s10,32(sp)
    80000190:	ec6e                	sd	s11,24(sp)
    80000192:	0100                	addi	s0,sp,128
    80000194:	8b2a                	mv	s6,a0
    80000196:	8aae                	mv	s5,a1
    80000198:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000019a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000019e:	00011517          	auipc	a0,0x11
    800001a2:	fd250513          	addi	a0,a0,-46 # 80011170 <cons>
    800001a6:	00001097          	auipc	ra,0x1
    800001aa:	bc8080e7          	jalr	-1080(ra) # 80000d6e <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001ae:	00011497          	auipc	s1,0x11
    800001b2:	fc248493          	addi	s1,s1,-62 # 80011170 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001b6:	89a6                	mv	s3,s1
    800001b8:	00011917          	auipc	s2,0x11
    800001bc:	05890913          	addi	s2,s2,88 # 80011210 <cons+0xa0>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001c0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001c2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001c4:	4da9                	li	s11,10
  while(n > 0){
    800001c6:	07405863          	blez	s4,80000236 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001ca:	0a04a783          	lw	a5,160(s1)
    800001ce:	0a44a703          	lw	a4,164(s1)
    800001d2:	02f71463          	bne	a4,a5,800001fa <consoleread+0x84>
      if(myproc()->killed){
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	be0080e7          	jalr	-1056(ra) # 80001db6 <myproc>
    800001de:	5d1c                	lw	a5,56(a0)
    800001e0:	e7b5                	bnez	a5,8000024c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001e2:	85ce                	mv	a1,s3
    800001e4:	854a                	mv	a0,s2
    800001e6:	00002097          	auipc	ra,0x2
    800001ea:	3e0080e7          	jalr	992(ra) # 800025c6 <sleep>
    while(cons.r == cons.w){
    800001ee:	0a04a783          	lw	a5,160(s1)
    800001f2:	0a44a703          	lw	a4,164(s1)
    800001f6:	fef700e3          	beq	a4,a5,800001d6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001fa:	0017871b          	addiw	a4,a5,1
    800001fe:	0ae4a023          	sw	a4,160(s1)
    80000202:	07f7f713          	andi	a4,a5,127
    80000206:	9726                	add	a4,a4,s1
    80000208:	02074703          	lbu	a4,32(a4)
    8000020c:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000210:	079c0663          	beq	s8,s9,8000027c <consoleread+0x106>
    cbuf = c;
    80000214:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000218:	4685                	li	a3,1
    8000021a:	f8f40613          	addi	a2,s0,-113
    8000021e:	85d6                	mv	a1,s5
    80000220:	855a                	mv	a0,s6
    80000222:	00002097          	auipc	ra,0x2
    80000226:	606080e7          	jalr	1542(ra) # 80002828 <either_copyout>
    8000022a:	01a50663          	beq	a0,s10,80000236 <consoleread+0xc0>
    dst++;
    8000022e:	0a85                	addi	s5,s5,1
    --n;
    80000230:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000232:	f9bc1ae3          	bne	s8,s11,800001c6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f3a50513          	addi	a0,a0,-198 # 80011170 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	c00080e7          	jalr	-1024(ra) # 80000e3e <release>

  return target - n;
    80000246:	414b853b          	subw	a0,s7,s4
    8000024a:	a811                	j	8000025e <consoleread+0xe8>
        release(&cons.lock);
    8000024c:	00011517          	auipc	a0,0x11
    80000250:	f2450513          	addi	a0,a0,-220 # 80011170 <cons>
    80000254:	00001097          	auipc	ra,0x1
    80000258:	bea080e7          	jalr	-1046(ra) # 80000e3e <release>
        return -1;
    8000025c:	557d                	li	a0,-1
}
    8000025e:	70e6                	ld	ra,120(sp)
    80000260:	7446                	ld	s0,112(sp)
    80000262:	74a6                	ld	s1,104(sp)
    80000264:	7906                	ld	s2,96(sp)
    80000266:	69e6                	ld	s3,88(sp)
    80000268:	6a46                	ld	s4,80(sp)
    8000026a:	6aa6                	ld	s5,72(sp)
    8000026c:	6b06                	ld	s6,64(sp)
    8000026e:	7be2                	ld	s7,56(sp)
    80000270:	7c42                	ld	s8,48(sp)
    80000272:	7ca2                	ld	s9,40(sp)
    80000274:	7d02                	ld	s10,32(sp)
    80000276:	6de2                	ld	s11,24(sp)
    80000278:	6109                	addi	sp,sp,128
    8000027a:	8082                	ret
      if(n < target){
    8000027c:	000a071b          	sext.w	a4,s4
    80000280:	fb777be3          	bgeu	a4,s7,80000236 <consoleread+0xc0>
        cons.r--;
    80000284:	00011717          	auipc	a4,0x11
    80000288:	f8f72623          	sw	a5,-116(a4) # 80011210 <cons+0xa0>
    8000028c:	b76d                	j	80000236 <consoleread+0xc0>

000000008000028e <consputc>:
{
    8000028e:	1141                	addi	sp,sp,-16
    80000290:	e406                	sd	ra,8(sp)
    80000292:	e022                	sd	s0,0(sp)
    80000294:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000296:	10000793          	li	a5,256
    8000029a:	00f50a63          	beq	a0,a5,800002ae <consputc+0x20>
    uartputc_sync(c);
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	564080e7          	jalr	1380(ra) # 80000802 <uartputc_sync>
}
    800002a6:	60a2                	ld	ra,8(sp)
    800002a8:	6402                	ld	s0,0(sp)
    800002aa:	0141                	addi	sp,sp,16
    800002ac:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	552080e7          	jalr	1362(ra) # 80000802 <uartputc_sync>
    800002b8:	02000513          	li	a0,32
    800002bc:	00000097          	auipc	ra,0x0
    800002c0:	546080e7          	jalr	1350(ra) # 80000802 <uartputc_sync>
    800002c4:	4521                	li	a0,8
    800002c6:	00000097          	auipc	ra,0x0
    800002ca:	53c080e7          	jalr	1340(ra) # 80000802 <uartputc_sync>
    800002ce:	bfe1                	j	800002a6 <consputc+0x18>

00000000800002d0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d0:	1101                	addi	sp,sp,-32
    800002d2:	ec06                	sd	ra,24(sp)
    800002d4:	e822                	sd	s0,16(sp)
    800002d6:	e426                	sd	s1,8(sp)
    800002d8:	e04a                	sd	s2,0(sp)
    800002da:	1000                	addi	s0,sp,32
    800002dc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002de:	00011517          	auipc	a0,0x11
    800002e2:	e9250513          	addi	a0,a0,-366 # 80011170 <cons>
    800002e6:	00001097          	auipc	ra,0x1
    800002ea:	a88080e7          	jalr	-1400(ra) # 80000d6e <acquire>

  switch(c){
    800002ee:	47d5                	li	a5,21
    800002f0:	0af48663          	beq	s1,a5,8000039c <consoleintr+0xcc>
    800002f4:	0297ca63          	blt	a5,s1,80000328 <consoleintr+0x58>
    800002f8:	47a1                	li	a5,8
    800002fa:	0ef48763          	beq	s1,a5,800003e8 <consoleintr+0x118>
    800002fe:	47c1                	li	a5,16
    80000300:	10f49a63          	bne	s1,a5,80000414 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    80000304:	00002097          	auipc	ra,0x2
    80000308:	5d0080e7          	jalr	1488(ra) # 800028d4 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000030c:	00011517          	auipc	a0,0x11
    80000310:	e6450513          	addi	a0,a0,-412 # 80011170 <cons>
    80000314:	00001097          	auipc	ra,0x1
    80000318:	b2a080e7          	jalr	-1238(ra) # 80000e3e <release>
}
    8000031c:	60e2                	ld	ra,24(sp)
    8000031e:	6442                	ld	s0,16(sp)
    80000320:	64a2                	ld	s1,8(sp)
    80000322:	6902                	ld	s2,0(sp)
    80000324:	6105                	addi	sp,sp,32
    80000326:	8082                	ret
  switch(c){
    80000328:	07f00793          	li	a5,127
    8000032c:	0af48e63          	beq	s1,a5,800003e8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000330:	00011717          	auipc	a4,0x11
    80000334:	e4070713          	addi	a4,a4,-448 # 80011170 <cons>
    80000338:	0a872783          	lw	a5,168(a4)
    8000033c:	0a072703          	lw	a4,160(a4)
    80000340:	9f99                	subw	a5,a5,a4
    80000342:	07f00713          	li	a4,127
    80000346:	fcf763e3          	bltu	a4,a5,8000030c <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000034a:	47b5                	li	a5,13
    8000034c:	0cf48763          	beq	s1,a5,8000041a <consoleintr+0x14a>
      consputc(c);
    80000350:	8526                	mv	a0,s1
    80000352:	00000097          	auipc	ra,0x0
    80000356:	f3c080e7          	jalr	-196(ra) # 8000028e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000035a:	00011797          	auipc	a5,0x11
    8000035e:	e1678793          	addi	a5,a5,-490 # 80011170 <cons>
    80000362:	0a87a703          	lw	a4,168(a5)
    80000366:	0017069b          	addiw	a3,a4,1
    8000036a:	0006861b          	sext.w	a2,a3
    8000036e:	0ad7a423          	sw	a3,168(a5)
    80000372:	07f77713          	andi	a4,a4,127
    80000376:	97ba                	add	a5,a5,a4
    80000378:	02978023          	sb	s1,32(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000037c:	47a9                	li	a5,10
    8000037e:	0cf48563          	beq	s1,a5,80000448 <consoleintr+0x178>
    80000382:	4791                	li	a5,4
    80000384:	0cf48263          	beq	s1,a5,80000448 <consoleintr+0x178>
    80000388:	00011797          	auipc	a5,0x11
    8000038c:	e887a783          	lw	a5,-376(a5) # 80011210 <cons+0xa0>
    80000390:	0807879b          	addiw	a5,a5,128
    80000394:	f6f61ce3          	bne	a2,a5,8000030c <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000398:	863e                	mv	a2,a5
    8000039a:	a07d                	j	80000448 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000039c:	00011717          	auipc	a4,0x11
    800003a0:	dd470713          	addi	a4,a4,-556 # 80011170 <cons>
    800003a4:	0a872783          	lw	a5,168(a4)
    800003a8:	0a472703          	lw	a4,164(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	00011497          	auipc	s1,0x11
    800003b0:	dc448493          	addi	s1,s1,-572 # 80011170 <cons>
    while(cons.e != cons.w &&
    800003b4:	4929                	li	s2,10
    800003b6:	f4f70be3          	beq	a4,a5,8000030c <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ba:	37fd                	addiw	a5,a5,-1
    800003bc:	07f7f713          	andi	a4,a5,127
    800003c0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c2:	02074703          	lbu	a4,32(a4)
    800003c6:	f52703e3          	beq	a4,s2,8000030c <consoleintr+0x3c>
      cons.e--;
    800003ca:	0af4a423          	sw	a5,168(s1)
      consputc(BACKSPACE);
    800003ce:	10000513          	li	a0,256
    800003d2:	00000097          	auipc	ra,0x0
    800003d6:	ebc080e7          	jalr	-324(ra) # 8000028e <consputc>
    while(cons.e != cons.w &&
    800003da:	0a84a783          	lw	a5,168(s1)
    800003de:	0a44a703          	lw	a4,164(s1)
    800003e2:	fcf71ce3          	bne	a4,a5,800003ba <consoleintr+0xea>
    800003e6:	b71d                	j	8000030c <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	d8870713          	addi	a4,a4,-632 # 80011170 <cons>
    800003f0:	0a872783          	lw	a5,168(a4)
    800003f4:	0a472703          	lw	a4,164(a4)
    800003f8:	f0f70ae3          	beq	a4,a5,8000030c <consoleintr+0x3c>
      cons.e--;
    800003fc:	37fd                	addiw	a5,a5,-1
    800003fe:	00011717          	auipc	a4,0x11
    80000402:	e0f72d23          	sw	a5,-486(a4) # 80011218 <cons+0xa8>
      consputc(BACKSPACE);
    80000406:	10000513          	li	a0,256
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e84080e7          	jalr	-380(ra) # 8000028e <consputc>
    80000412:	bded                	j	8000030c <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000414:	ee048ce3          	beqz	s1,8000030c <consoleintr+0x3c>
    80000418:	bf21                	j	80000330 <consoleintr+0x60>
      consputc(c);
    8000041a:	4529                	li	a0,10
    8000041c:	00000097          	auipc	ra,0x0
    80000420:	e72080e7          	jalr	-398(ra) # 8000028e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000424:	00011797          	auipc	a5,0x11
    80000428:	d4c78793          	addi	a5,a5,-692 # 80011170 <cons>
    8000042c:	0a87a703          	lw	a4,168(a5)
    80000430:	0017069b          	addiw	a3,a4,1
    80000434:	0006861b          	sext.w	a2,a3
    80000438:	0ad7a423          	sw	a3,168(a5)
    8000043c:	07f77713          	andi	a4,a4,127
    80000440:	97ba                	add	a5,a5,a4
    80000442:	4729                	li	a4,10
    80000444:	02e78023          	sb	a4,32(a5)
        cons.w = cons.e;
    80000448:	00011797          	auipc	a5,0x11
    8000044c:	dcc7a623          	sw	a2,-564(a5) # 80011214 <cons+0xa4>
        wakeup(&cons.r);
    80000450:	00011517          	auipc	a0,0x11
    80000454:	dc050513          	addi	a0,a0,-576 # 80011210 <cons+0xa0>
    80000458:	00002097          	auipc	ra,0x2
    8000045c:	2f4080e7          	jalr	756(ra) # 8000274c <wakeup>
    80000460:	b575                	j	8000030c <consoleintr+0x3c>

0000000080000462 <consoleinit>:

void
consoleinit(void)
{
    80000462:	1141                	addi	sp,sp,-16
    80000464:	e406                	sd	ra,8(sp)
    80000466:	e022                	sd	s0,0(sp)
    80000468:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000046a:	00008597          	auipc	a1,0x8
    8000046e:	ba658593          	addi	a1,a1,-1114 # 80008010 <etext+0x10>
    80000472:	00011517          	auipc	a0,0x11
    80000476:	cfe50513          	addi	a0,a0,-770 # 80011170 <cons>
    8000047a:	00001097          	auipc	ra,0x1
    8000047e:	a70080e7          	jalr	-1424(ra) # 80000eea <initlock>

  uartinit();
    80000482:	00000097          	auipc	ra,0x0
    80000486:	330080e7          	jalr	816(ra) # 800007b2 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000048a:	00026797          	auipc	a5,0x26
    8000048e:	91678793          	addi	a5,a5,-1770 # 80025da0 <devsw>
    80000492:	00000717          	auipc	a4,0x0
    80000496:	ce470713          	addi	a4,a4,-796 # 80000176 <consoleread>
    8000049a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000049c:	00000717          	auipc	a4,0x0
    800004a0:	c5870713          	addi	a4,a4,-936 # 800000f4 <consolewrite>
    800004a4:	ef98                	sd	a4,24(a5)
}
    800004a6:	60a2                	ld	ra,8(sp)
    800004a8:	6402                	ld	s0,0(sp)
    800004aa:	0141                	addi	sp,sp,16
    800004ac:	8082                	ret

00000000800004ae <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004ae:	7179                	addi	sp,sp,-48
    800004b0:	f406                	sd	ra,40(sp)
    800004b2:	f022                	sd	s0,32(sp)
    800004b4:	ec26                	sd	s1,24(sp)
    800004b6:	e84a                	sd	s2,16(sp)
    800004b8:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ba:	c219                	beqz	a2,800004c0 <printint+0x12>
    800004bc:	08054663          	bltz	a0,80000548 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004c0:	2501                	sext.w	a0,a0
    800004c2:	4881                	li	a7,0
    800004c4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004ca:	2581                	sext.w	a1,a1
    800004cc:	00008617          	auipc	a2,0x8
    800004d0:	b7460613          	addi	a2,a2,-1164 # 80008040 <digits>
    800004d4:	883a                	mv	a6,a4
    800004d6:	2705                	addiw	a4,a4,1
    800004d8:	02b577bb          	remuw	a5,a0,a1
    800004dc:	1782                	slli	a5,a5,0x20
    800004de:	9381                	srli	a5,a5,0x20
    800004e0:	97b2                	add	a5,a5,a2
    800004e2:	0007c783          	lbu	a5,0(a5)
    800004e6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ea:	0005079b          	sext.w	a5,a0
    800004ee:	02b5553b          	divuw	a0,a0,a1
    800004f2:	0685                	addi	a3,a3,1
    800004f4:	feb7f0e3          	bgeu	a5,a1,800004d4 <printint+0x26>

  if(sign)
    800004f8:	00088b63          	beqz	a7,8000050e <printint+0x60>
    buf[i++] = '-';
    800004fc:	fe040793          	addi	a5,s0,-32
    80000500:	973e                	add	a4,a4,a5
    80000502:	02d00793          	li	a5,45
    80000506:	fef70823          	sb	a5,-16(a4)
    8000050a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000050e:	02e05763          	blez	a4,8000053c <printint+0x8e>
    80000512:	fd040793          	addi	a5,s0,-48
    80000516:	00e784b3          	add	s1,a5,a4
    8000051a:	fff78913          	addi	s2,a5,-1
    8000051e:	993a                	add	s2,s2,a4
    80000520:	377d                	addiw	a4,a4,-1
    80000522:	1702                	slli	a4,a4,0x20
    80000524:	9301                	srli	a4,a4,0x20
    80000526:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000052a:	fff4c503          	lbu	a0,-1(s1)
    8000052e:	00000097          	auipc	ra,0x0
    80000532:	d60080e7          	jalr	-672(ra) # 8000028e <consputc>
  while(--i >= 0)
    80000536:	14fd                	addi	s1,s1,-1
    80000538:	ff2499e3          	bne	s1,s2,8000052a <printint+0x7c>
}
    8000053c:	70a2                	ld	ra,40(sp)
    8000053e:	7402                	ld	s0,32(sp)
    80000540:	64e2                	ld	s1,24(sp)
    80000542:	6942                	ld	s2,16(sp)
    80000544:	6145                	addi	sp,sp,48
    80000546:	8082                	ret
    x = -xx;
    80000548:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000054c:	4885                	li	a7,1
    x = -xx;
    8000054e:	bf9d                	j	800004c4 <printint+0x16>

0000000080000550 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000550:	1101                	addi	sp,sp,-32
    80000552:	ec06                	sd	ra,24(sp)
    80000554:	e822                	sd	s0,16(sp)
    80000556:	e426                	sd	s1,8(sp)
    80000558:	1000                	addi	s0,sp,32
    8000055a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000055c:	00011797          	auipc	a5,0x11
    80000560:	ce07a223          	sw	zero,-796(a5) # 80011240 <pr+0x20>
  printf("panic: ");
    80000564:	00008517          	auipc	a0,0x8
    80000568:	ab450513          	addi	a0,a0,-1356 # 80008018 <etext+0x18>
    8000056c:	00000097          	auipc	ra,0x0
    80000570:	02e080e7          	jalr	46(ra) # 8000059a <printf>
  printf(s);
    80000574:	8526                	mv	a0,s1
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	024080e7          	jalr	36(ra) # 8000059a <printf>
  printf("\n");
    8000057e:	00008517          	auipc	a0,0x8
    80000582:	bea50513          	addi	a0,a0,-1046 # 80008168 <digits+0x128>
    80000586:	00000097          	auipc	ra,0x0
    8000058a:	014080e7          	jalr	20(ra) # 8000059a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000058e:	4785                	li	a5,1
    80000590:	00009717          	auipc	a4,0x9
    80000594:	a6f72823          	sw	a5,-1424(a4) # 80009000 <panicked>
  for(;;)
    80000598:	a001                	j	80000598 <panic+0x48>

000000008000059a <printf>:
{
    8000059a:	7131                	addi	sp,sp,-192
    8000059c:	fc86                	sd	ra,120(sp)
    8000059e:	f8a2                	sd	s0,112(sp)
    800005a0:	f4a6                	sd	s1,104(sp)
    800005a2:	f0ca                	sd	s2,96(sp)
    800005a4:	ecce                	sd	s3,88(sp)
    800005a6:	e8d2                	sd	s4,80(sp)
    800005a8:	e4d6                	sd	s5,72(sp)
    800005aa:	e0da                	sd	s6,64(sp)
    800005ac:	fc5e                	sd	s7,56(sp)
    800005ae:	f862                	sd	s8,48(sp)
    800005b0:	f466                	sd	s9,40(sp)
    800005b2:	f06a                	sd	s10,32(sp)
    800005b4:	ec6e                	sd	s11,24(sp)
    800005b6:	0100                	addi	s0,sp,128
    800005b8:	8a2a                	mv	s4,a0
    800005ba:	e40c                	sd	a1,8(s0)
    800005bc:	e810                	sd	a2,16(s0)
    800005be:	ec14                	sd	a3,24(s0)
    800005c0:	f018                	sd	a4,32(s0)
    800005c2:	f41c                	sd	a5,40(s0)
    800005c4:	03043823          	sd	a6,48(s0)
    800005c8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005cc:	00011d97          	auipc	s11,0x11
    800005d0:	c74dad83          	lw	s11,-908(s11) # 80011240 <pr+0x20>
  if(locking)
    800005d4:	020d9b63          	bnez	s11,8000060a <printf+0x70>
  if (fmt == 0)
    800005d8:	040a0263          	beqz	s4,8000061c <printf+0x82>
  va_start(ap, fmt);
    800005dc:	00840793          	addi	a5,s0,8
    800005e0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e4:	000a4503          	lbu	a0,0(s4)
    800005e8:	16050263          	beqz	a0,8000074c <printf+0x1b2>
    800005ec:	4481                	li	s1,0
    if(c != '%'){
    800005ee:	02500a93          	li	s5,37
    switch(c){
    800005f2:	07000b13          	li	s6,112
  consputc('x');
    800005f6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f8:	00008b97          	auipc	s7,0x8
    800005fc:	a48b8b93          	addi	s7,s7,-1464 # 80008040 <digits>
    switch(c){
    80000600:	07300c93          	li	s9,115
    80000604:	06400c13          	li	s8,100
    80000608:	a82d                	j	80000642 <printf+0xa8>
    acquire(&pr.lock);
    8000060a:	00011517          	auipc	a0,0x11
    8000060e:	c1650513          	addi	a0,a0,-1002 # 80011220 <pr>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	75c080e7          	jalr	1884(ra) # 80000d6e <acquire>
    8000061a:	bf7d                	j	800005d8 <printf+0x3e>
    panic("null fmt");
    8000061c:	00008517          	auipc	a0,0x8
    80000620:	a0c50513          	addi	a0,a0,-1524 # 80008028 <etext+0x28>
    80000624:	00000097          	auipc	ra,0x0
    80000628:	f2c080e7          	jalr	-212(ra) # 80000550 <panic>
      consputc(c);
    8000062c:	00000097          	auipc	ra,0x0
    80000630:	c62080e7          	jalr	-926(ra) # 8000028e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c503          	lbu	a0,0(a5)
    8000063e:	10050763          	beqz	a0,8000074c <printf+0x1b2>
    if(c != '%'){
    80000642:	ff5515e3          	bne	a0,s5,8000062c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000646:	2485                	addiw	s1,s1,1
    80000648:	009a07b3          	add	a5,s4,s1
    8000064c:	0007c783          	lbu	a5,0(a5)
    80000650:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000654:	cfe5                	beqz	a5,8000074c <printf+0x1b2>
    switch(c){
    80000656:	05678a63          	beq	a5,s6,800006aa <printf+0x110>
    8000065a:	02fb7663          	bgeu	s6,a5,80000686 <printf+0xec>
    8000065e:	09978963          	beq	a5,s9,800006f0 <printf+0x156>
    80000662:	07800713          	li	a4,120
    80000666:	0ce79863          	bne	a5,a4,80000736 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000066a:	f8843783          	ld	a5,-120(s0)
    8000066e:	00878713          	addi	a4,a5,8
    80000672:	f8e43423          	sd	a4,-120(s0)
    80000676:	4605                	li	a2,1
    80000678:	85ea                	mv	a1,s10
    8000067a:	4388                	lw	a0,0(a5)
    8000067c:	00000097          	auipc	ra,0x0
    80000680:	e32080e7          	jalr	-462(ra) # 800004ae <printint>
      break;
    80000684:	bf45                	j	80000634 <printf+0x9a>
    switch(c){
    80000686:	0b578263          	beq	a5,s5,8000072a <printf+0x190>
    8000068a:	0b879663          	bne	a5,s8,80000736 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878713          	addi	a4,a5,8
    80000696:	f8e43423          	sd	a4,-120(s0)
    8000069a:	4605                	li	a2,1
    8000069c:	45a9                	li	a1,10
    8000069e:	4388                	lw	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	e0e080e7          	jalr	-498(ra) # 800004ae <printint>
      break;
    800006a8:	b771                	j	80000634 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006aa:	f8843783          	ld	a5,-120(s0)
    800006ae:	00878713          	addi	a4,a5,8
    800006b2:	f8e43423          	sd	a4,-120(s0)
    800006b6:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ba:	03000513          	li	a0,48
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bd0080e7          	jalr	-1072(ra) # 8000028e <consputc>
  consputc('x');
    800006c6:	07800513          	li	a0,120
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bc4080e7          	jalr	-1084(ra) # 8000028e <consputc>
    800006d2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d4:	03c9d793          	srli	a5,s3,0x3c
    800006d8:	97de                	add	a5,a5,s7
    800006da:	0007c503          	lbu	a0,0(a5)
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	bb0080e7          	jalr	-1104(ra) # 8000028e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e6:	0992                	slli	s3,s3,0x4
    800006e8:	397d                	addiw	s2,s2,-1
    800006ea:	fe0915e3          	bnez	s2,800006d4 <printf+0x13a>
    800006ee:	b799                	j	80000634 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006f0:	f8843783          	ld	a5,-120(s0)
    800006f4:	00878713          	addi	a4,a5,8
    800006f8:	f8e43423          	sd	a4,-120(s0)
    800006fc:	0007b903          	ld	s2,0(a5)
    80000700:	00090e63          	beqz	s2,8000071c <printf+0x182>
      for(; *s; s++)
    80000704:	00094503          	lbu	a0,0(s2)
    80000708:	d515                	beqz	a0,80000634 <printf+0x9a>
        consputc(*s);
    8000070a:	00000097          	auipc	ra,0x0
    8000070e:	b84080e7          	jalr	-1148(ra) # 8000028e <consputc>
      for(; *s; s++)
    80000712:	0905                	addi	s2,s2,1
    80000714:	00094503          	lbu	a0,0(s2)
    80000718:	f96d                	bnez	a0,8000070a <printf+0x170>
    8000071a:	bf29                	j	80000634 <printf+0x9a>
        s = "(null)";
    8000071c:	00008917          	auipc	s2,0x8
    80000720:	90490913          	addi	s2,s2,-1788 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000724:	02800513          	li	a0,40
    80000728:	b7cd                	j	8000070a <printf+0x170>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b62080e7          	jalr	-1182(ra) # 8000028e <consputc>
      break;
    80000734:	b701                	j	80000634 <printf+0x9a>
      consputc('%');
    80000736:	8556                	mv	a0,s5
    80000738:	00000097          	auipc	ra,0x0
    8000073c:	b56080e7          	jalr	-1194(ra) # 8000028e <consputc>
      consputc(c);
    80000740:	854a                	mv	a0,s2
    80000742:	00000097          	auipc	ra,0x0
    80000746:	b4c080e7          	jalr	-1204(ra) # 8000028e <consputc>
      break;
    8000074a:	b5ed                	j	80000634 <printf+0x9a>
  if(locking)
    8000074c:	020d9163          	bnez	s11,8000076e <printf+0x1d4>
}
    80000750:	70e6                	ld	ra,120(sp)
    80000752:	7446                	ld	s0,112(sp)
    80000754:	74a6                	ld	s1,104(sp)
    80000756:	7906                	ld	s2,96(sp)
    80000758:	69e6                	ld	s3,88(sp)
    8000075a:	6a46                	ld	s4,80(sp)
    8000075c:	6aa6                	ld	s5,72(sp)
    8000075e:	6b06                	ld	s6,64(sp)
    80000760:	7be2                	ld	s7,56(sp)
    80000762:	7c42                	ld	s8,48(sp)
    80000764:	7ca2                	ld	s9,40(sp)
    80000766:	7d02                	ld	s10,32(sp)
    80000768:	6de2                	ld	s11,24(sp)
    8000076a:	6129                	addi	sp,sp,192
    8000076c:	8082                	ret
    release(&pr.lock);
    8000076e:	00011517          	auipc	a0,0x11
    80000772:	ab250513          	addi	a0,a0,-1358 # 80011220 <pr>
    80000776:	00000097          	auipc	ra,0x0
    8000077a:	6c8080e7          	jalr	1736(ra) # 80000e3e <release>
}
    8000077e:	bfc9                	j	80000750 <printf+0x1b6>

0000000080000780 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000780:	1101                	addi	sp,sp,-32
    80000782:	ec06                	sd	ra,24(sp)
    80000784:	e822                	sd	s0,16(sp)
    80000786:	e426                	sd	s1,8(sp)
    80000788:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000078a:	00011497          	auipc	s1,0x11
    8000078e:	a9648493          	addi	s1,s1,-1386 # 80011220 <pr>
    80000792:	00008597          	auipc	a1,0x8
    80000796:	8a658593          	addi	a1,a1,-1882 # 80008038 <etext+0x38>
    8000079a:	8526                	mv	a0,s1
    8000079c:	00000097          	auipc	ra,0x0
    800007a0:	74e080e7          	jalr	1870(ra) # 80000eea <initlock>
  pr.locking = 1;
    800007a4:	4785                	li	a5,1
    800007a6:	d09c                	sw	a5,32(s1)
}
    800007a8:	60e2                	ld	ra,24(sp)
    800007aa:	6442                	ld	s0,16(sp)
    800007ac:	64a2                	ld	s1,8(sp)
    800007ae:	6105                	addi	sp,sp,32
    800007b0:	8082                	ret

00000000800007b2 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007b2:	1141                	addi	sp,sp,-16
    800007b4:	e406                	sd	ra,8(sp)
    800007b6:	e022                	sd	s0,0(sp)
    800007b8:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ba:	100007b7          	lui	a5,0x10000
    800007be:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007c2:	f8000713          	li	a4,-128
    800007c6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ca:	470d                	li	a4,3
    800007cc:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007d0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007d4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d8:	469d                	li	a3,7
    800007da:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007de:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007e2:	00008597          	auipc	a1,0x8
    800007e6:	87658593          	addi	a1,a1,-1930 # 80008058 <digits+0x18>
    800007ea:	00011517          	auipc	a0,0x11
    800007ee:	a5e50513          	addi	a0,a0,-1442 # 80011248 <uart_tx_lock>
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	6f8080e7          	jalr	1784(ra) # 80000eea <initlock>
}
    800007fa:	60a2                	ld	ra,8(sp)
    800007fc:	6402                	ld	s0,0(sp)
    800007fe:	0141                	addi	sp,sp,16
    80000800:	8082                	ret

0000000080000802 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000802:	1101                	addi	sp,sp,-32
    80000804:	ec06                	sd	ra,24(sp)
    80000806:	e822                	sd	s0,16(sp)
    80000808:	e426                	sd	s1,8(sp)
    8000080a:	1000                	addi	s0,sp,32
    8000080c:	84aa                	mv	s1,a0
  push_off();
    8000080e:	00000097          	auipc	ra,0x0
    80000812:	514080e7          	jalr	1300(ra) # 80000d22 <push_off>

  if(panicked){
    80000816:	00008797          	auipc	a5,0x8
    8000081a:	7ea7a783          	lw	a5,2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	10000737          	lui	a4,0x10000
  if(panicked){
    80000822:	c391                	beqz	a5,80000826 <uartputc_sync+0x24>
    for(;;)
    80000824:	a001                	j	80000824 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000826:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000082a:	0ff7f793          	andi	a5,a5,255
    8000082e:	0207f793          	andi	a5,a5,32
    80000832:	dbf5                	beqz	a5,80000826 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000834:	0ff4f793          	andi	a5,s1,255
    80000838:	10000737          	lui	a4,0x10000
    8000083c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000840:	00000097          	auipc	ra,0x0
    80000844:	59e080e7          	jalr	1438(ra) # 80000dde <pop_off>
}
    80000848:	60e2                	ld	ra,24(sp)
    8000084a:	6442                	ld	s0,16(sp)
    8000084c:	64a2                	ld	s1,8(sp)
    8000084e:	6105                	addi	sp,sp,32
    80000850:	8082                	ret

0000000080000852 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000852:	00008797          	auipc	a5,0x8
    80000856:	7b27a783          	lw	a5,1970(a5) # 80009004 <uart_tx_r>
    8000085a:	00008717          	auipc	a4,0x8
    8000085e:	7ae72703          	lw	a4,1966(a4) # 80009008 <uart_tx_w>
    80000862:	08f70263          	beq	a4,a5,800008e6 <uartstart+0x94>
{
    80000866:	7139                	addi	sp,sp,-64
    80000868:	fc06                	sd	ra,56(sp)
    8000086a:	f822                	sd	s0,48(sp)
    8000086c:	f426                	sd	s1,40(sp)
    8000086e:	f04a                	sd	s2,32(sp)
    80000870:	ec4e                	sd	s3,24(sp)
    80000872:	e852                	sd	s4,16(sp)
    80000874:	e456                	sd	s5,8(sp)
    80000876:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    8000087c:	00011a17          	auipc	s4,0x11
    80000880:	9cca0a13          	addi	s4,s4,-1588 # 80011248 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000884:	00008497          	auipc	s1,0x8
    80000888:	78048493          	addi	s1,s1,1920 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000088c:	00008997          	auipc	s3,0x8
    80000890:	77c98993          	addi	s3,s3,1916 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000894:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000898:	0ff77713          	andi	a4,a4,255
    8000089c:	02077713          	andi	a4,a4,32
    800008a0:	cb15                	beqz	a4,800008d4 <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    800008a2:	00fa0733          	add	a4,s4,a5
    800008a6:	02074a83          	lbu	s5,32(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008aa:	2785                	addiw	a5,a5,1
    800008ac:	41f7d71b          	sraiw	a4,a5,0x1f
    800008b0:	01b7571b          	srliw	a4,a4,0x1b
    800008b4:	9fb9                	addw	a5,a5,a4
    800008b6:	8bfd                	andi	a5,a5,31
    800008b8:	9f99                	subw	a5,a5,a4
    800008ba:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008bc:	8526                	mv	a0,s1
    800008be:	00002097          	auipc	ra,0x2
    800008c2:	e8e080e7          	jalr	-370(ra) # 8000274c <wakeup>
    
    WriteReg(THR, c);
    800008c6:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ca:	409c                	lw	a5,0(s1)
    800008cc:	0009a703          	lw	a4,0(s3)
    800008d0:	fcf712e3          	bne	a4,a5,80000894 <uartstart+0x42>
  }
}
    800008d4:	70e2                	ld	ra,56(sp)
    800008d6:	7442                	ld	s0,48(sp)
    800008d8:	74a2                	ld	s1,40(sp)
    800008da:	7902                	ld	s2,32(sp)
    800008dc:	69e2                	ld	s3,24(sp)
    800008de:	6a42                	ld	s4,16(sp)
    800008e0:	6aa2                	ld	s5,8(sp)
    800008e2:	6121                	addi	sp,sp,64
    800008e4:	8082                	ret
    800008e6:	8082                	ret

00000000800008e8 <uartputc>:
{
    800008e8:	7179                	addi	sp,sp,-48
    800008ea:	f406                	sd	ra,40(sp)
    800008ec:	f022                	sd	s0,32(sp)
    800008ee:	ec26                	sd	s1,24(sp)
    800008f0:	e84a                	sd	s2,16(sp)
    800008f2:	e44e                	sd	s3,8(sp)
    800008f4:	e052                	sd	s4,0(sp)
    800008f6:	1800                	addi	s0,sp,48
    800008f8:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008fa:	00011517          	auipc	a0,0x11
    800008fe:	94e50513          	addi	a0,a0,-1714 # 80011248 <uart_tx_lock>
    80000902:	00000097          	auipc	ra,0x0
    80000906:	46c080e7          	jalr	1132(ra) # 80000d6e <acquire>
  if(panicked){
    8000090a:	00008797          	auipc	a5,0x8
    8000090e:	6f67a783          	lw	a5,1782(a5) # 80009000 <panicked>
    80000912:	c391                	beqz	a5,80000916 <uartputc+0x2e>
    for(;;)
    80000914:	a001                	j	80000914 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000916:	00008717          	auipc	a4,0x8
    8000091a:	6f272703          	lw	a4,1778(a4) # 80009008 <uart_tx_w>
    8000091e:	0017079b          	addiw	a5,a4,1
    80000922:	41f7d69b          	sraiw	a3,a5,0x1f
    80000926:	01b6d69b          	srliw	a3,a3,0x1b
    8000092a:	9fb5                	addw	a5,a5,a3
    8000092c:	8bfd                	andi	a5,a5,31
    8000092e:	9f95                	subw	a5,a5,a3
    80000930:	00008697          	auipc	a3,0x8
    80000934:	6d46a683          	lw	a3,1748(a3) # 80009004 <uart_tx_r>
    80000938:	04f69263          	bne	a3,a5,8000097c <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000093c:	00011a17          	auipc	s4,0x11
    80000940:	90ca0a13          	addi	s4,s4,-1780 # 80011248 <uart_tx_lock>
    80000944:	00008497          	auipc	s1,0x8
    80000948:	6c048493          	addi	s1,s1,1728 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000094c:	00008917          	auipc	s2,0x8
    80000950:	6bc90913          	addi	s2,s2,1724 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000954:	85d2                	mv	a1,s4
    80000956:	8526                	mv	a0,s1
    80000958:	00002097          	auipc	ra,0x2
    8000095c:	c6e080e7          	jalr	-914(ra) # 800025c6 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000960:	00092703          	lw	a4,0(s2)
    80000964:	0017079b          	addiw	a5,a4,1
    80000968:	41f7d69b          	sraiw	a3,a5,0x1f
    8000096c:	01b6d69b          	srliw	a3,a3,0x1b
    80000970:	9fb5                	addw	a5,a5,a3
    80000972:	8bfd                	andi	a5,a5,31
    80000974:	9f95                	subw	a5,a5,a3
    80000976:	4094                	lw	a3,0(s1)
    80000978:	fcf68ee3          	beq	a3,a5,80000954 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    8000097c:	00011497          	auipc	s1,0x11
    80000980:	8cc48493          	addi	s1,s1,-1844 # 80011248 <uart_tx_lock>
    80000984:	9726                	add	a4,a4,s1
    80000986:	03370023          	sb	s3,32(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    8000098a:	00008717          	auipc	a4,0x8
    8000098e:	66f72f23          	sw	a5,1662(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000992:	00000097          	auipc	ra,0x0
    80000996:	ec0080e7          	jalr	-320(ra) # 80000852 <uartstart>
      release(&uart_tx_lock);
    8000099a:	8526                	mv	a0,s1
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	4a2080e7          	jalr	1186(ra) # 80000e3e <release>
}
    800009a4:	70a2                	ld	ra,40(sp)
    800009a6:	7402                	ld	s0,32(sp)
    800009a8:	64e2                	ld	s1,24(sp)
    800009aa:	6942                	ld	s2,16(sp)
    800009ac:	69a2                	ld	s3,8(sp)
    800009ae:	6a02                	ld	s4,0(sp)
    800009b0:	6145                	addi	sp,sp,48
    800009b2:	8082                	ret

00000000800009b4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009b4:	1141                	addi	sp,sp,-16
    800009b6:	e422                	sd	s0,8(sp)
    800009b8:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009ba:	100007b7          	lui	a5,0x10000
    800009be:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009c2:	8b85                	andi	a5,a5,1
    800009c4:	cb91                	beqz	a5,800009d8 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009c6:	100007b7          	lui	a5,0x10000
    800009ca:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009ce:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009d2:	6422                	ld	s0,8(sp)
    800009d4:	0141                	addi	sp,sp,16
    800009d6:	8082                	ret
    return -1;
    800009d8:	557d                	li	a0,-1
    800009da:	bfe5                	j	800009d2 <uartgetc+0x1e>

00000000800009dc <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009dc:	1101                	addi	sp,sp,-32
    800009de:	ec06                	sd	ra,24(sp)
    800009e0:	e822                	sd	s0,16(sp)
    800009e2:	e426                	sd	s1,8(sp)
    800009e4:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009e6:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e8:	00000097          	auipc	ra,0x0
    800009ec:	fcc080e7          	jalr	-52(ra) # 800009b4 <uartgetc>
    if(c == -1)
    800009f0:	00950763          	beq	a0,s1,800009fe <uartintr+0x22>
      break;
    consoleintr(c);
    800009f4:	00000097          	auipc	ra,0x0
    800009f8:	8dc080e7          	jalr	-1828(ra) # 800002d0 <consoleintr>
  while(1){
    800009fc:	b7f5                	j	800009e8 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009fe:	00011497          	auipc	s1,0x11
    80000a02:	84a48493          	addi	s1,s1,-1974 # 80011248 <uart_tx_lock>
    80000a06:	8526                	mv	a0,s1
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	366080e7          	jalr	870(ra) # 80000d6e <acquire>
  uartstart();
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	e42080e7          	jalr	-446(ra) # 80000852 <uartstart>
  release(&uart_tx_lock);
    80000a18:	8526                	mv	a0,s1
    80000a1a:	00000097          	auipc	ra,0x0
    80000a1e:	424080e7          	jalr	1060(ra) # 80000e3e <release>
}
    80000a22:	60e2                	ld	ra,24(sp)
    80000a24:	6442                	ld	s0,16(sp)
    80000a26:	64a2                	ld	s1,8(sp)
    80000a28:	6105                	addi	sp,sp,32
    80000a2a:	8082                	ret

0000000080000a2c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a2c:	7139                	addi	sp,sp,-64
    80000a2e:	fc06                	sd	ra,56(sp)
    80000a30:	f822                	sd	s0,48(sp)
    80000a32:	f426                	sd	s1,40(sp)
    80000a34:	f04a                	sd	s2,32(sp)
    80000a36:	ec4e                	sd	s3,24(sp)
    80000a38:	e852                	sd	s4,16(sp)
    80000a3a:	e456                	sd	s5,8(sp)
    80000a3c:	0080                	addi	s0,sp,64
  struct run *r;//用来指向要释放的内存块
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)// 检查释放的内存块是否合法
    80000a3e:	03451793          	slli	a5,a0,0x34
    80000a42:	e3c1                	bnez	a5,80000ac2 <kfree+0x96>
    80000a44:	84aa                	mv	s1,a0
    80000a46:	0002a797          	auipc	a5,0x2a
    80000a4a:	5e278793          	addi	a5,a5,1506 # 8002b028 <end>
    80000a4e:	06f56a63          	bltu	a0,a5,80000ac2 <kfree+0x96>
    80000a52:	47c5                	li	a5,17
    80000a54:	07ee                	slli	a5,a5,0x1b
    80000a56:	06f57663          	bgeu	a0,a5,80000ac2 <kfree+0x96>
    panic("kfree");
  // 将内存块填充为垃圾值，以捕获悬空引用
  memset(pa, 1, PGSIZE);
    80000a5a:	6605                	lui	a2,0x1
    80000a5c:	4585                	li	a1,1
    80000a5e:	00000097          	auipc	ra,0x0
    80000a62:	6f0080e7          	jalr	1776(ra) # 8000114e <memset>
  r = (struct run*)pa;
  push_off();// 关闭中断，禁止CPU切换
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	2bc080e7          	jalr	700(ra) # 80000d22 <push_off>
  int id = cpuid();// 获取当前CPU的ID
    80000a6e:	00001097          	auipc	ra,0x1
    80000a72:	31c080e7          	jalr	796(ra) # 80001d8a <cpuid>

  acquire(&kmem[id].lock);//获取当前CPU对应的锁，确保对空闲资源链表的互斥访问
    80000a76:	00011a97          	auipc	s5,0x11
    80000a7a:	812a8a93          	addi	s5,s5,-2030 # 80011288 <kmem>
    80000a7e:	00151993          	slli	s3,a0,0x1
    80000a82:	00a98933          	add	s2,s3,a0
    80000a86:	0912                	slli	s2,s2,0x4
    80000a88:	9956                	add	s2,s2,s5
    80000a8a:	854a                	mv	a0,s2
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	2e2080e7          	jalr	738(ra) # 80000d6e <acquire>
  r->next = kmem[id].freelist;//将释放的内存块插入到当前CPU的空闲资源链表头部
    80000a94:	02093783          	ld	a5,32(s2)
    80000a98:	e09c                	sd	a5,0(s1)
  kmem[id].freelist = r;//更新当前CPU的空闲资源链表头指针
    80000a9a:	02993023          	sd	s1,32(s2)
  release(&kmem[id].lock);//释放当前CPU对应的锁
    80000a9e:	854a                	mv	a0,s2
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	39e080e7          	jalr	926(ra) # 80000e3e <release>

  pop_off();//打开中断，允许CPU切换
    80000aa8:	00000097          	auipc	ra,0x0
    80000aac:	336080e7          	jalr	822(ra) # 80000dde <pop_off>
}
    80000ab0:	70e2                	ld	ra,56(sp)
    80000ab2:	7442                	ld	s0,48(sp)
    80000ab4:	74a2                	ld	s1,40(sp)
    80000ab6:	7902                	ld	s2,32(sp)
    80000ab8:	69e2                	ld	s3,24(sp)
    80000aba:	6a42                	ld	s4,16(sp)
    80000abc:	6aa2                	ld	s5,8(sp)
    80000abe:	6121                	addi	sp,sp,64
    80000ac0:	8082                	ret
    panic("kfree");
    80000ac2:	00007517          	auipc	a0,0x7
    80000ac6:	59e50513          	addi	a0,a0,1438 # 80008060 <digits+0x20>
    80000aca:	00000097          	auipc	ra,0x0
    80000ace:	a86080e7          	jalr	-1402(ra) # 80000550 <panic>

0000000080000ad2 <freerange>:
{
    80000ad2:	7179                	addi	sp,sp,-48
    80000ad4:	f406                	sd	ra,40(sp)
    80000ad6:	f022                	sd	s0,32(sp)
    80000ad8:	ec26                	sd	s1,24(sp)
    80000ada:	e84a                	sd	s2,16(sp)
    80000adc:	e44e                	sd	s3,8(sp)
    80000ade:	e052                	sd	s4,0(sp)
    80000ae0:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ae2:	6785                	lui	a5,0x1
    80000ae4:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ae8:	94aa                	add	s1,s1,a0
    80000aea:	757d                	lui	a0,0xfffff
    80000aec:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aee:	94be                	add	s1,s1,a5
    80000af0:	0095ee63          	bltu	a1,s1,80000b0c <freerange+0x3a>
    80000af4:	892e                	mv	s2,a1
    kfree(p);
    80000af6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af8:	6985                	lui	s3,0x1
    kfree(p);
    80000afa:	01448533          	add	a0,s1,s4
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f2e080e7          	jalr	-210(ra) # 80000a2c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b06:	94ce                	add	s1,s1,s3
    80000b08:	fe9979e3          	bgeu	s2,s1,80000afa <freerange+0x28>
}
    80000b0c:	70a2                	ld	ra,40(sp)
    80000b0e:	7402                	ld	s0,32(sp)
    80000b10:	64e2                	ld	s1,24(sp)
    80000b12:	6942                	ld	s2,16(sp)
    80000b14:	69a2                	ld	s3,8(sp)
    80000b16:	6a02                	ld	s4,0(sp)
    80000b18:	6145                	addi	sp,sp,48
    80000b1a:	8082                	ret

0000000080000b1c <kinit>:
{
    80000b1c:	7139                	addi	sp,sp,-64
    80000b1e:	fc06                	sd	ra,56(sp)
    80000b20:	f822                	sd	s0,48(sp)
    80000b22:	f426                	sd	s1,40(sp)
    80000b24:	f04a                	sd	s2,32(sp)
    80000b26:	ec4e                	sd	s3,24(sp)
    80000b28:	e852                	sd	s4,16(sp)
    80000b2a:	e456                	sd	s5,8(sp)
    80000b2c:	0080                	addi	s0,sp,64
  for (int i = 0; i < NCPU; i++) {//给每个CPU设置锁
    80000b2e:	00010917          	auipc	s2,0x10
    80000b32:	75a90913          	addi	s2,s2,1882 # 80011288 <kmem>
    80000b36:	4481                	li	s1,0
    snprintf(kmem[i].lock_name, sizeof(kmem[i].lock_name), "kmem_%d", i);// 格式化锁的名称
    80000b38:	00007a97          	auipc	s5,0x7
    80000b3c:	530a8a93          	addi	s5,s5,1328 # 80008068 <digits+0x28>
  for (int i = 0; i < NCPU; i++) {//给每个CPU设置锁
    80000b40:	4a21                	li	s4,8
    snprintf(kmem[i].lock_name, sizeof(kmem[i].lock_name), "kmem_%d", i);// 格式化锁的名称
    80000b42:	02890993          	addi	s3,s2,40
    80000b46:	86a6                	mv	a3,s1
    80000b48:	8656                	mv	a2,s5
    80000b4a:	459d                	li	a1,7
    80000b4c:	854e                	mv	a0,s3
    80000b4e:	00006097          	auipc	ra,0x6
    80000b52:	e84080e7          	jalr	-380(ra) # 800069d2 <snprintf>
    initlock(&kmem[i].lock, kmem[i].lock_name);// 初始化锁
    80000b56:	85ce                	mv	a1,s3
    80000b58:	854a                	mv	a0,s2
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	390080e7          	jalr	912(ra) # 80000eea <initlock>
  for (int i = 0; i < NCPU; i++) {//给每个CPU设置锁
    80000b62:	2485                	addiw	s1,s1,1
    80000b64:	03090913          	addi	s2,s2,48
    80000b68:	fd449de3          	bne	s1,s4,80000b42 <kinit+0x26>
  freerange(end, (void*)PHYSTOP);// 初始化空闲资源
    80000b6c:	45c5                	li	a1,17
    80000b6e:	05ee                	slli	a1,a1,0x1b
    80000b70:	0002a517          	auipc	a0,0x2a
    80000b74:	4b850513          	addi	a0,a0,1208 # 8002b028 <end>
    80000b78:	00000097          	auipc	ra,0x0
    80000b7c:	f5a080e7          	jalr	-166(ra) # 80000ad2 <freerange>
}
    80000b80:	70e2                	ld	ra,56(sp)
    80000b82:	7442                	ld	s0,48(sp)
    80000b84:	74a2                	ld	s1,40(sp)
    80000b86:	7902                	ld	s2,32(sp)
    80000b88:	69e2                	ld	s3,24(sp)
    80000b8a:	6a42                	ld	s4,16(sp)
    80000b8c:	6aa2                	ld	s5,8(sp)
    80000b8e:	6121                	addi	sp,sp,64
    80000b90:	8082                	ret

0000000080000b92 <kalloc>:
//分配一个4096字节的物理内存页。
//返回一个内核可以使用的指针。
//如果无法分配内存，则返回0。
void *
kalloc(void)
{
    80000b92:	715d                	addi	sp,sp,-80
    80000b94:	e486                	sd	ra,72(sp)
    80000b96:	e0a2                	sd	s0,64(sp)
    80000b98:	fc26                	sd	s1,56(sp)
    80000b9a:	f84a                	sd	s2,48(sp)
    80000b9c:	f44e                	sd	s3,40(sp)
    80000b9e:	f052                	sd	s4,32(sp)
    80000ba0:	ec56                	sd	s5,24(sp)
    80000ba2:	e85a                	sd	s6,16(sp)
    80000ba4:	e45e                	sd	s7,8(sp)
    80000ba6:	0880                	addi	s0,sp,80
  struct run *r;

  push_off();// 关闭中断，禁止CPU切换
    80000ba8:	00000097          	auipc	ra,0x0
    80000bac:	17a080e7          	jalr	378(ra) # 80000d22 <push_off>
  int id = cpuid();
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	1da080e7          	jalr	474(ra) # 80001d8a <cpuid>
    80000bb8:	84aa                	mv	s1,a0

  acquire(&kmem[id].lock);// 获取当前CPU对应的锁，确保互斥操作
    80000bba:	00151793          	slli	a5,a0,0x1
    80000bbe:	97aa                	add	a5,a5,a0
    80000bc0:	0792                	slli	a5,a5,0x4
    80000bc2:	00010a17          	auipc	s4,0x10
    80000bc6:	6c6a0a13          	addi	s4,s4,1734 # 80011288 <kmem>
    80000bca:	9a3e                	add	s4,s4,a5
    80000bcc:	8552                	mv	a0,s4
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	1a0080e7          	jalr	416(ra) # 80000d6e <acquire>
  r = kmem[id].freelist;// 将当前CPU空闲资源链表的头节点赋值给r
    80000bd6:	020a3b03          	ld	s6,32(s4)
  if(r) {// 如果空闲资源链表非空，将头节点指向下一个节点
    80000bda:	040b0263          	beqz	s6,80000c1e <kalloc+0x8c>
    kmem[id].freelist = r->next;
    80000bde:	000b3703          	ld	a4,0(s6)
    80000be2:	02ea3023          	sd	a4,32(s4)
        kmem[id].freelist = r->next;// 更新当前CPU空闲资源链表的头指针
        break;
      }
    }
  }
  release(&kmem[id].lock);// 释放当前CPU对应的锁
    80000be6:	8552                	mv	a0,s4
    80000be8:	00000097          	auipc	ra,0x0
    80000bec:	256080e7          	jalr	598(ra) # 80000e3e <release>
  pop_off();// 打开中断，允许CPU切换
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	1ee080e7          	jalr	494(ra) # 80000dde <pop_off>

  if(r)
    memset((char*)r, 5, PGSIZE); // 填充垃圾值到分配的内存块
    80000bf8:	6605                	lui	a2,0x1
    80000bfa:	4595                	li	a1,5
    80000bfc:	855a                	mv	a0,s6
    80000bfe:	00000097          	auipc	ra,0x0
    80000c02:	550080e7          	jalr	1360(ra) # 8000114e <memset>
  return (void*)r;// 返回分配的内存块的指针
}
    80000c06:	855a                	mv	a0,s6
    80000c08:	60a6                	ld	ra,72(sp)
    80000c0a:	6406                	ld	s0,64(sp)
    80000c0c:	74e2                	ld	s1,56(sp)
    80000c0e:	7942                	ld	s2,48(sp)
    80000c10:	79a2                	ld	s3,40(sp)
    80000c12:	7a02                	ld	s4,32(sp)
    80000c14:	6ae2                	ld	s5,24(sp)
    80000c16:	6b42                	ld	s6,16(sp)
    80000c18:	6ba2                	ld	s7,8(sp)
    80000c1a:	6161                	addi	sp,sp,80
    80000c1c:	8082                	ret
    80000c1e:	00010917          	auipc	s2,0x10
    80000c22:	66a90913          	addi	s2,s2,1642 # 80011288 <kmem>
    for(i = 0; i < NCPU; i++) {
    80000c26:	4981                	li	s3,0
    80000c28:	4ba1                	li	s7,8
    80000c2a:	a069                	j	80000cb4 <kalloc+0x122>
          p = p->next;
    80000c2c:	87b6                	mv	a5,a3
        kmem[id].freelist = kmem[i].freelist; // 将窃取的一半内存分配给当前CPU
    80000c2e:	00149713          	slli	a4,s1,0x1
    80000c32:	9726                	add	a4,a4,s1
    80000c34:	0712                	slli	a4,a4,0x4
    80000c36:	00010697          	auipc	a3,0x10
    80000c3a:	65268693          	addi	a3,a3,1618 # 80011288 <kmem>
    80000c3e:	9736                	add	a4,a4,a3
    80000c40:	f30c                	sd	a1,32(a4)
        if (p == kmem[i].freelist) {
    80000c42:	04f58763          	beq	a1,a5,80000c90 <kalloc+0xfe>
          kmem[i].freelist = p; // 更新其他CPU空闲资源链表的头指针
    80000c46:	00199713          	slli	a4,s3,0x1
    80000c4a:	99ba                	add	s3,s3,a4
    80000c4c:	0992                	slli	s3,s3,0x4
    80000c4e:	00010717          	auipc	a4,0x10
    80000c52:	63a70713          	addi	a4,a4,1594 # 80011288 <kmem>
    80000c56:	99ba                	add	s3,s3,a4
    80000c58:	02f9b023          	sd	a5,32(s3) # 1020 <_entry-0x7fffefe0>
          pre->next = 0;// 断开链表
    80000c5c:	00063023          	sd	zero,0(a2) # 1000 <_entry-0x7ffff000>
      release(&kmem[i].lock); // 释放其他CPU对应的锁
    80000c60:	8556                	mv	a0,s5
    80000c62:	00000097          	auipc	ra,0x0
    80000c66:	1dc080e7          	jalr	476(ra) # 80000e3e <release>
        r = kmem[id].freelist;// 将当前CPU空闲资源链表的头节点赋值给r
    80000c6a:	00010697          	auipc	a3,0x10
    80000c6e:	61e68693          	addi	a3,a3,1566 # 80011288 <kmem>
    80000c72:	00149793          	slli	a5,s1,0x1
    80000c76:	00978733          	add	a4,a5,s1
    80000c7a:	0712                	slli	a4,a4,0x4
    80000c7c:	9736                	add	a4,a4,a3
    80000c7e:	02073b03          	ld	s6,32(a4)
        kmem[id].freelist = r->next;// 更新当前CPU空闲资源链表的头指针
    80000c82:	000b3703          	ld	a4,0(s6)
    80000c86:	97a6                	add	a5,a5,s1
    80000c88:	0792                	slli	a5,a5,0x4
    80000c8a:	97b6                	add	a5,a5,a3
    80000c8c:	f398                	sd	a4,32(a5)
        break;
    80000c8e:	bfa1                	j	80000be6 <kalloc+0x54>
          kmem[i].freelist = 0;
    80000c90:	00199793          	slli	a5,s3,0x1
    80000c94:	99be                	add	s3,s3,a5
    80000c96:	0992                	slli	s3,s3,0x4
    80000c98:	99b6                	add	s3,s3,a3
    80000c9a:	0209b023          	sd	zero,32(s3)
    80000c9e:	b7c9                	j	80000c60 <kalloc+0xce>
      release(&kmem[i].lock); // 释放其他CPU对应的锁
    80000ca0:	854a                	mv	a0,s2
    80000ca2:	00000097          	auipc	ra,0x0
    80000ca6:	19c080e7          	jalr	412(ra) # 80000e3e <release>
    for(i = 0; i < NCPU; i++) {
    80000caa:	2985                	addiw	s3,s3,1
    80000cac:	03090913          	addi	s2,s2,48
    80000cb0:	03798863          	beq	s3,s7,80000ce0 <kalloc+0x14e>
      if (i == id) continue;
    80000cb4:	ff348be3          	beq	s1,s3,80000caa <kalloc+0x118>
      acquire(&kmem[i].lock);// 获取其他CPU对应的锁
    80000cb8:	8aca                	mv	s5,s2
    80000cba:	854a                	mv	a0,s2
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	0b2080e7          	jalr	178(ra) # 80000d6e <acquire>
      struct run *p = kmem[i].freelist; // 将其他CPU空闲资源链表的头节点赋值给p
    80000cc4:	02093583          	ld	a1,32(s2)
      if(p) {
    80000cc8:	dde1                	beqz	a1,80000ca0 <kalloc+0x10e>
      struct run *p = kmem[i].freelist; // 将其他CPU空闲资源链表的头节点赋值给p
    80000cca:	862e                	mv	a2,a1
    80000ccc:	872e                	mv	a4,a1
    80000cce:	87ae                	mv	a5,a1
        while (fp && fp->next) {//fp 指针每次向后移动两个节点，而 p 指针和 pre 指针则每次向后移动一个节点
    80000cd0:	6318                	ld	a4,0(a4)
    80000cd2:	df31                	beqz	a4,80000c2e <kalloc+0x9c>
          fp = fp->next->next;
    80000cd4:	6318                	ld	a4,0(a4)
          p = p->next;
    80000cd6:	6394                	ld	a3,0(a5)
        while (fp && fp->next) {//fp 指针每次向后移动两个节点，而 p 指针和 pre 指针则每次向后移动一个节点
    80000cd8:	863e                	mv	a2,a5
    80000cda:	db29                	beqz	a4,80000c2c <kalloc+0x9a>
          p = p->next;
    80000cdc:	87b6                	mv	a5,a3
    80000cde:	bfcd                	j	80000cd0 <kalloc+0x13e>
  release(&kmem[id].lock);// 释放当前CPU对应的锁
    80000ce0:	8552                	mv	a0,s4
    80000ce2:	00000097          	auipc	ra,0x0
    80000ce6:	15c080e7          	jalr	348(ra) # 80000e3e <release>
  pop_off();// 打开中断，允许CPU切换
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	0f4080e7          	jalr	244(ra) # 80000dde <pop_off>
  if(r)
    80000cf2:	bf11                	j	80000c06 <kalloc+0x74>

0000000080000cf4 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000cf4:	411c                	lw	a5,0(a0)
    80000cf6:	e399                	bnez	a5,80000cfc <holding+0x8>
    80000cf8:	4501                	li	a0,0
  return r;
}
    80000cfa:	8082                	ret
{
    80000cfc:	1101                	addi	sp,sp,-32
    80000cfe:	ec06                	sd	ra,24(sp)
    80000d00:	e822                	sd	s0,16(sp)
    80000d02:	e426                	sd	s1,8(sp)
    80000d04:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000d06:	6904                	ld	s1,16(a0)
    80000d08:	00001097          	auipc	ra,0x1
    80000d0c:	092080e7          	jalr	146(ra) # 80001d9a <mycpu>
    80000d10:	40a48533          	sub	a0,s1,a0
    80000d14:	00153513          	seqz	a0,a0
}
    80000d18:	60e2                	ld	ra,24(sp)
    80000d1a:	6442                	ld	s0,16(sp)
    80000d1c:	64a2                	ld	s1,8(sp)
    80000d1e:	6105                	addi	sp,sp,32
    80000d20:	8082                	ret

0000000080000d22 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d22:	1101                	addi	sp,sp,-32
    80000d24:	ec06                	sd	ra,24(sp)
    80000d26:	e822                	sd	s0,16(sp)
    80000d28:	e426                	sd	s1,8(sp)
    80000d2a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d2c:	100024f3          	csrr	s1,sstatus
    80000d30:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d34:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d36:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d3a:	00001097          	auipc	ra,0x1
    80000d3e:	060080e7          	jalr	96(ra) # 80001d9a <mycpu>
    80000d42:	5d3c                	lw	a5,120(a0)
    80000d44:	cf89                	beqz	a5,80000d5e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d46:	00001097          	auipc	ra,0x1
    80000d4a:	054080e7          	jalr	84(ra) # 80001d9a <mycpu>
    80000d4e:	5d3c                	lw	a5,120(a0)
    80000d50:	2785                	addiw	a5,a5,1
    80000d52:	dd3c                	sw	a5,120(a0)
}
    80000d54:	60e2                	ld	ra,24(sp)
    80000d56:	6442                	ld	s0,16(sp)
    80000d58:	64a2                	ld	s1,8(sp)
    80000d5a:	6105                	addi	sp,sp,32
    80000d5c:	8082                	ret
    mycpu()->intena = old;
    80000d5e:	00001097          	auipc	ra,0x1
    80000d62:	03c080e7          	jalr	60(ra) # 80001d9a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d66:	8085                	srli	s1,s1,0x1
    80000d68:	8885                	andi	s1,s1,1
    80000d6a:	dd64                	sw	s1,124(a0)
    80000d6c:	bfe9                	j	80000d46 <push_off+0x24>

0000000080000d6e <acquire>:
{
    80000d6e:	1101                	addi	sp,sp,-32
    80000d70:	ec06                	sd	ra,24(sp)
    80000d72:	e822                	sd	s0,16(sp)
    80000d74:	e426                	sd	s1,8(sp)
    80000d76:	1000                	addi	s0,sp,32
    80000d78:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d7a:	00000097          	auipc	ra,0x0
    80000d7e:	fa8080e7          	jalr	-88(ra) # 80000d22 <push_off>
  if(holding(lk))
    80000d82:	8526                	mv	a0,s1
    80000d84:	00000097          	auipc	ra,0x0
    80000d88:	f70080e7          	jalr	-144(ra) # 80000cf4 <holding>
    80000d8c:	e911                	bnez	a0,80000da0 <acquire+0x32>
    __sync_fetch_and_add(&(lk->n), 1);
    80000d8e:	4785                	li	a5,1
    80000d90:	01c48713          	addi	a4,s1,28
    80000d94:	0f50000f          	fence	iorw,ow
    80000d98:	04f7202f          	amoadd.w.aq	zero,a5,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d9c:	4705                	li	a4,1
    80000d9e:	a839                	j	80000dbc <acquire+0x4e>
    panic("acquire");
    80000da0:	00007517          	auipc	a0,0x7
    80000da4:	2d050513          	addi	a0,a0,720 # 80008070 <digits+0x30>
    80000da8:	fffff097          	auipc	ra,0xfffff
    80000dac:	7a8080e7          	jalr	1960(ra) # 80000550 <panic>
    __sync_fetch_and_add(&(lk->nts), 1);
    80000db0:	01848793          	addi	a5,s1,24
    80000db4:	0f50000f          	fence	iorw,ow
    80000db8:	04e7a02f          	amoadd.w.aq	zero,a4,(a5)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000dbc:	87ba                	mv	a5,a4
    80000dbe:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000dc2:	2781                	sext.w	a5,a5
    80000dc4:	f7f5                	bnez	a5,80000db0 <acquire+0x42>
  __sync_synchronize();
    80000dc6:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000dca:	00001097          	auipc	ra,0x1
    80000dce:	fd0080e7          	jalr	-48(ra) # 80001d9a <mycpu>
    80000dd2:	e888                	sd	a0,16(s1)
}
    80000dd4:	60e2                	ld	ra,24(sp)
    80000dd6:	6442                	ld	s0,16(sp)
    80000dd8:	64a2                	ld	s1,8(sp)
    80000dda:	6105                	addi	sp,sp,32
    80000ddc:	8082                	ret

0000000080000dde <pop_off>:

void
pop_off(void)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e406                	sd	ra,8(sp)
    80000de2:	e022                	sd	s0,0(sp)
    80000de4:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000de6:	00001097          	auipc	ra,0x1
    80000dea:	fb4080e7          	jalr	-76(ra) # 80001d9a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dee:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000df2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000df4:	e78d                	bnez	a5,80000e1e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000df6:	5d3c                	lw	a5,120(a0)
    80000df8:	02f05b63          	blez	a5,80000e2e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000dfc:	37fd                	addiw	a5,a5,-1
    80000dfe:	0007871b          	sext.w	a4,a5
    80000e02:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000e04:	eb09                	bnez	a4,80000e16 <pop_off+0x38>
    80000e06:	5d7c                	lw	a5,124(a0)
    80000e08:	c799                	beqz	a5,80000e16 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e0a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000e0e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e12:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000e16:	60a2                	ld	ra,8(sp)
    80000e18:	6402                	ld	s0,0(sp)
    80000e1a:	0141                	addi	sp,sp,16
    80000e1c:	8082                	ret
    panic("pop_off - interruptible");
    80000e1e:	00007517          	auipc	a0,0x7
    80000e22:	25a50513          	addi	a0,a0,602 # 80008078 <digits+0x38>
    80000e26:	fffff097          	auipc	ra,0xfffff
    80000e2a:	72a080e7          	jalr	1834(ra) # 80000550 <panic>
    panic("pop_off");
    80000e2e:	00007517          	auipc	a0,0x7
    80000e32:	26250513          	addi	a0,a0,610 # 80008090 <digits+0x50>
    80000e36:	fffff097          	auipc	ra,0xfffff
    80000e3a:	71a080e7          	jalr	1818(ra) # 80000550 <panic>

0000000080000e3e <release>:
{
    80000e3e:	1101                	addi	sp,sp,-32
    80000e40:	ec06                	sd	ra,24(sp)
    80000e42:	e822                	sd	s0,16(sp)
    80000e44:	e426                	sd	s1,8(sp)
    80000e46:	1000                	addi	s0,sp,32
    80000e48:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e4a:	00000097          	auipc	ra,0x0
    80000e4e:	eaa080e7          	jalr	-342(ra) # 80000cf4 <holding>
    80000e52:	c115                	beqz	a0,80000e76 <release+0x38>
  lk->cpu = 0;
    80000e54:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e58:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e5c:	0f50000f          	fence	iorw,ow
    80000e60:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e64:	00000097          	auipc	ra,0x0
    80000e68:	f7a080e7          	jalr	-134(ra) # 80000dde <pop_off>
}
    80000e6c:	60e2                	ld	ra,24(sp)
    80000e6e:	6442                	ld	s0,16(sp)
    80000e70:	64a2                	ld	s1,8(sp)
    80000e72:	6105                	addi	sp,sp,32
    80000e74:	8082                	ret
    panic("release");
    80000e76:	00007517          	auipc	a0,0x7
    80000e7a:	22250513          	addi	a0,a0,546 # 80008098 <digits+0x58>
    80000e7e:	fffff097          	auipc	ra,0xfffff
    80000e82:	6d2080e7          	jalr	1746(ra) # 80000550 <panic>

0000000080000e86 <freelock>:
{
    80000e86:	1101                	addi	sp,sp,-32
    80000e88:	ec06                	sd	ra,24(sp)
    80000e8a:	e822                	sd	s0,16(sp)
    80000e8c:	e426                	sd	s1,8(sp)
    80000e8e:	1000                	addi	s0,sp,32
    80000e90:	84aa                	mv	s1,a0
  acquire(&lock_locks);
    80000e92:	00010517          	auipc	a0,0x10
    80000e96:	57650513          	addi	a0,a0,1398 # 80011408 <lock_locks>
    80000e9a:	00000097          	auipc	ra,0x0
    80000e9e:	ed4080e7          	jalr	-300(ra) # 80000d6e <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000ea2:	00010717          	auipc	a4,0x10
    80000ea6:	58670713          	addi	a4,a4,1414 # 80011428 <locks>
    80000eaa:	4781                	li	a5,0
    80000eac:	1f400613          	li	a2,500
    if(locks[i] == lk) {
    80000eb0:	6314                	ld	a3,0(a4)
    80000eb2:	00968763          	beq	a3,s1,80000ec0 <freelock+0x3a>
  for (i = 0; i < NLOCK; i++) {
    80000eb6:	2785                	addiw	a5,a5,1
    80000eb8:	0721                	addi	a4,a4,8
    80000eba:	fec79be3          	bne	a5,a2,80000eb0 <freelock+0x2a>
    80000ebe:	a809                	j	80000ed0 <freelock+0x4a>
      locks[i] = 0;
    80000ec0:	078e                	slli	a5,a5,0x3
    80000ec2:	00010717          	auipc	a4,0x10
    80000ec6:	56670713          	addi	a4,a4,1382 # 80011428 <locks>
    80000eca:	97ba                	add	a5,a5,a4
    80000ecc:	0007b023          	sd	zero,0(a5)
  release(&lock_locks);
    80000ed0:	00010517          	auipc	a0,0x10
    80000ed4:	53850513          	addi	a0,a0,1336 # 80011408 <lock_locks>
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	f66080e7          	jalr	-154(ra) # 80000e3e <release>
}
    80000ee0:	60e2                	ld	ra,24(sp)
    80000ee2:	6442                	ld	s0,16(sp)
    80000ee4:	64a2                	ld	s1,8(sp)
    80000ee6:	6105                	addi	sp,sp,32
    80000ee8:	8082                	ret

0000000080000eea <initlock>:
{
    80000eea:	1101                	addi	sp,sp,-32
    80000eec:	ec06                	sd	ra,24(sp)
    80000eee:	e822                	sd	s0,16(sp)
    80000ef0:	e426                	sd	s1,8(sp)
    80000ef2:	1000                	addi	s0,sp,32
    80000ef4:	84aa                	mv	s1,a0
  lk->name = name;
    80000ef6:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000ef8:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000efc:	00053823          	sd	zero,16(a0)
  lk->nts = 0;
    80000f00:	00052c23          	sw	zero,24(a0)
  lk->n = 0;
    80000f04:	00052e23          	sw	zero,28(a0)
  acquire(&lock_locks);
    80000f08:	00010517          	auipc	a0,0x10
    80000f0c:	50050513          	addi	a0,a0,1280 # 80011408 <lock_locks>
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	e5e080e7          	jalr	-418(ra) # 80000d6e <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000f18:	00010717          	auipc	a4,0x10
    80000f1c:	51070713          	addi	a4,a4,1296 # 80011428 <locks>
    80000f20:	4781                	li	a5,0
    80000f22:	1f400693          	li	a3,500
    if(locks[i] == 0) {
    80000f26:	6310                	ld	a2,0(a4)
    80000f28:	ce09                	beqz	a2,80000f42 <initlock+0x58>
  for (i = 0; i < NLOCK; i++) {
    80000f2a:	2785                	addiw	a5,a5,1
    80000f2c:	0721                	addi	a4,a4,8
    80000f2e:	fed79ce3          	bne	a5,a3,80000f26 <initlock+0x3c>
  panic("findslot");
    80000f32:	00007517          	auipc	a0,0x7
    80000f36:	16e50513          	addi	a0,a0,366 # 800080a0 <digits+0x60>
    80000f3a:	fffff097          	auipc	ra,0xfffff
    80000f3e:	616080e7          	jalr	1558(ra) # 80000550 <panic>
      locks[i] = lk;
    80000f42:	078e                	slli	a5,a5,0x3
    80000f44:	00010717          	auipc	a4,0x10
    80000f48:	4e470713          	addi	a4,a4,1252 # 80011428 <locks>
    80000f4c:	97ba                	add	a5,a5,a4
    80000f4e:	e384                	sd	s1,0(a5)
      release(&lock_locks);
    80000f50:	00010517          	auipc	a0,0x10
    80000f54:	4b850513          	addi	a0,a0,1208 # 80011408 <lock_locks>
    80000f58:	00000097          	auipc	ra,0x0
    80000f5c:	ee6080e7          	jalr	-282(ra) # 80000e3e <release>
}
    80000f60:	60e2                	ld	ra,24(sp)
    80000f62:	6442                	ld	s0,16(sp)
    80000f64:	64a2                	ld	s1,8(sp)
    80000f66:	6105                	addi	sp,sp,32
    80000f68:	8082                	ret

0000000080000f6a <snprint_lock>:
#ifdef LAB_LOCK
int
snprint_lock(char *buf, int sz, struct spinlock *lk)
{
  int n = 0;
  if(lk->n > 0) {
    80000f6a:	4e5c                	lw	a5,28(a2)
    80000f6c:	00f04463          	bgtz	a5,80000f74 <snprint_lock+0xa>
  int n = 0;
    80000f70:	4501                	li	a0,0
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
                 lk->name, lk->nts, lk->n);
  }
  return n;
}
    80000f72:	8082                	ret
{
    80000f74:	1141                	addi	sp,sp,-16
    80000f76:	e406                	sd	ra,8(sp)
    80000f78:	e022                	sd	s0,0(sp)
    80000f7a:	0800                	addi	s0,sp,16
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
    80000f7c:	4e18                	lw	a4,24(a2)
    80000f7e:	6614                	ld	a3,8(a2)
    80000f80:	00007617          	auipc	a2,0x7
    80000f84:	13060613          	addi	a2,a2,304 # 800080b0 <digits+0x70>
    80000f88:	00006097          	auipc	ra,0x6
    80000f8c:	a4a080e7          	jalr	-1462(ra) # 800069d2 <snprintf>
}
    80000f90:	60a2                	ld	ra,8(sp)
    80000f92:	6402                	ld	s0,0(sp)
    80000f94:	0141                	addi	sp,sp,16
    80000f96:	8082                	ret

0000000080000f98 <statslock>:

int
statslock(char *buf, int sz) {
    80000f98:	7159                	addi	sp,sp,-112
    80000f9a:	f486                	sd	ra,104(sp)
    80000f9c:	f0a2                	sd	s0,96(sp)
    80000f9e:	eca6                	sd	s1,88(sp)
    80000fa0:	e8ca                	sd	s2,80(sp)
    80000fa2:	e4ce                	sd	s3,72(sp)
    80000fa4:	e0d2                	sd	s4,64(sp)
    80000fa6:	fc56                	sd	s5,56(sp)
    80000fa8:	f85a                	sd	s6,48(sp)
    80000faa:	f45e                	sd	s7,40(sp)
    80000fac:	f062                	sd	s8,32(sp)
    80000fae:	ec66                	sd	s9,24(sp)
    80000fb0:	e86a                	sd	s10,16(sp)
    80000fb2:	e46e                	sd	s11,8(sp)
    80000fb4:	1880                	addi	s0,sp,112
    80000fb6:	8aaa                	mv	s5,a0
    80000fb8:	8b2e                	mv	s6,a1
  int n;
  int tot = 0;

  acquire(&lock_locks);
    80000fba:	00010517          	auipc	a0,0x10
    80000fbe:	44e50513          	addi	a0,a0,1102 # 80011408 <lock_locks>
    80000fc2:	00000097          	auipc	ra,0x0
    80000fc6:	dac080e7          	jalr	-596(ra) # 80000d6e <acquire>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000fca:	00007617          	auipc	a2,0x7
    80000fce:	11660613          	addi	a2,a2,278 # 800080e0 <digits+0xa0>
    80000fd2:	85da                	mv	a1,s6
    80000fd4:	8556                	mv	a0,s5
    80000fd6:	00006097          	auipc	ra,0x6
    80000fda:	9fc080e7          	jalr	-1540(ra) # 800069d2 <snprintf>
    80000fde:	892a                	mv	s2,a0
  for(int i = 0; i < NLOCK; i++) {
    80000fe0:	00010c97          	auipc	s9,0x10
    80000fe4:	448c8c93          	addi	s9,s9,1096 # 80011428 <locks>
    80000fe8:	00011c17          	auipc	s8,0x11
    80000fec:	3e0c0c13          	addi	s8,s8,992 # 800123c8 <pid_lock>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000ff0:	84e6                	mv	s1,s9
  int tot = 0;
    80000ff2:	4a01                	li	s4,0
    if(locks[i] == 0)
      break;
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000ff4:	00007b97          	auipc	s7,0x7
    80000ff8:	10cb8b93          	addi	s7,s7,268 # 80008100 <digits+0xc0>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000ffc:	00007d17          	auipc	s10,0x7
    80001000:	10cd0d13          	addi	s10,s10,268 # 80008108 <digits+0xc8>
    80001004:	a01d                	j	8000102a <statslock+0x92>
      tot += locks[i]->nts;
    80001006:	0009b603          	ld	a2,0(s3)
    8000100a:	4e1c                	lw	a5,24(a2)
    8000100c:	01478a3b          	addw	s4,a5,s4
      n += snprint_lock(buf +n, sz-n, locks[i]);
    80001010:	412b05bb          	subw	a1,s6,s2
    80001014:	012a8533          	add	a0,s5,s2
    80001018:	00000097          	auipc	ra,0x0
    8000101c:	f52080e7          	jalr	-174(ra) # 80000f6a <snprint_lock>
    80001020:	0125093b          	addw	s2,a0,s2
  for(int i = 0; i < NLOCK; i++) {
    80001024:	04a1                	addi	s1,s1,8
    80001026:	05848763          	beq	s1,s8,80001074 <statslock+0xdc>
    if(locks[i] == 0)
    8000102a:	89a6                	mv	s3,s1
    8000102c:	609c                	ld	a5,0(s1)
    8000102e:	c3b9                	beqz	a5,80001074 <statslock+0xdc>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80001030:	0087bd83          	ld	s11,8(a5)
    80001034:	855e                	mv	a0,s7
    80001036:	00000097          	auipc	ra,0x0
    8000103a:	2a0080e7          	jalr	672(ra) # 800012d6 <strlen>
    8000103e:	0005061b          	sext.w	a2,a0
    80001042:	85de                	mv	a1,s7
    80001044:	856e                	mv	a0,s11
    80001046:	00000097          	auipc	ra,0x0
    8000104a:	1e4080e7          	jalr	484(ra) # 8000122a <strncmp>
    8000104e:	dd45                	beqz	a0,80001006 <statslock+0x6e>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80001050:	609c                	ld	a5,0(s1)
    80001052:	0087bd83          	ld	s11,8(a5)
    80001056:	856a                	mv	a0,s10
    80001058:	00000097          	auipc	ra,0x0
    8000105c:	27e080e7          	jalr	638(ra) # 800012d6 <strlen>
    80001060:	0005061b          	sext.w	a2,a0
    80001064:	85ea                	mv	a1,s10
    80001066:	856e                	mv	a0,s11
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	1c2080e7          	jalr	450(ra) # 8000122a <strncmp>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80001070:	f955                	bnez	a0,80001024 <statslock+0x8c>
    80001072:	bf51                	j	80001006 <statslock+0x6e>
    }
  }
  
  n += snprintf(buf+n, sz-n, "--- top 5 contended locks:\n");
    80001074:	00007617          	auipc	a2,0x7
    80001078:	09c60613          	addi	a2,a2,156 # 80008110 <digits+0xd0>
    8000107c:	412b05bb          	subw	a1,s6,s2
    80001080:	012a8533          	add	a0,s5,s2
    80001084:	00006097          	auipc	ra,0x6
    80001088:	94e080e7          	jalr	-1714(ra) # 800069d2 <snprintf>
    8000108c:	012509bb          	addw	s3,a0,s2
    80001090:	4b95                	li	s7,5
  int last = 100000000;
    80001092:	05f5e537          	lui	a0,0x5f5e
    80001096:	10050513          	addi	a0,a0,256 # 5f5e100 <_entry-0x7a0a1f00>
  // stupid way to compute top 5 contended locks
  for(int t = 0; t < 5; t++) {
    int top = 0;
    for(int i = 0; i < NLOCK; i++) {
    8000109a:	4c01                	li	s8,0
      if(locks[i] == 0)
        break;
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    8000109c:	00010497          	auipc	s1,0x10
    800010a0:	38c48493          	addi	s1,s1,908 # 80011428 <locks>
    for(int i = 0; i < NLOCK; i++) {
    800010a4:	1f400913          	li	s2,500
    800010a8:	a881                	j	800010f8 <statslock+0x160>
    800010aa:	2705                	addiw	a4,a4,1
    800010ac:	06a1                	addi	a3,a3,8
    800010ae:	03270063          	beq	a4,s2,800010ce <statslock+0x136>
      if(locks[i] == 0)
    800010b2:	629c                	ld	a5,0(a3)
    800010b4:	cf89                	beqz	a5,800010ce <statslock+0x136>
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    800010b6:	4f90                	lw	a2,24(a5)
    800010b8:	00359793          	slli	a5,a1,0x3
    800010bc:	97a6                	add	a5,a5,s1
    800010be:	639c                	ld	a5,0(a5)
    800010c0:	4f9c                	lw	a5,24(a5)
    800010c2:	fec7d4e3          	bge	a5,a2,800010aa <statslock+0x112>
    800010c6:	fea652e3          	bge	a2,a0,800010aa <statslock+0x112>
    800010ca:	85ba                	mv	a1,a4
    800010cc:	bff9                	j	800010aa <statslock+0x112>
        top = i;
      }
    }
    n += snprint_lock(buf+n, sz-n, locks[top]);
    800010ce:	058e                	slli	a1,a1,0x3
    800010d0:	00b48d33          	add	s10,s1,a1
    800010d4:	000d3603          	ld	a2,0(s10)
    800010d8:	413b05bb          	subw	a1,s6,s3
    800010dc:	013a8533          	add	a0,s5,s3
    800010e0:	00000097          	auipc	ra,0x0
    800010e4:	e8a080e7          	jalr	-374(ra) # 80000f6a <snprint_lock>
    800010e8:	013509bb          	addw	s3,a0,s3
    last = locks[top]->nts;
    800010ec:	000d3783          	ld	a5,0(s10)
    800010f0:	4f88                	lw	a0,24(a5)
  for(int t = 0; t < 5; t++) {
    800010f2:	3bfd                	addiw	s7,s7,-1
    800010f4:	000b8663          	beqz	s7,80001100 <statslock+0x168>
  int tot = 0;
    800010f8:	86e6                	mv	a3,s9
    for(int i = 0; i < NLOCK; i++) {
    800010fa:	8762                	mv	a4,s8
    int top = 0;
    800010fc:	85e2                	mv	a1,s8
    800010fe:	bf55                	j	800010b2 <statslock+0x11a>
  }
  n += snprintf(buf+n, sz-n, "tot= %d\n", tot);
    80001100:	86d2                	mv	a3,s4
    80001102:	00007617          	auipc	a2,0x7
    80001106:	02e60613          	addi	a2,a2,46 # 80008130 <digits+0xf0>
    8000110a:	413b05bb          	subw	a1,s6,s3
    8000110e:	013a8533          	add	a0,s5,s3
    80001112:	00006097          	auipc	ra,0x6
    80001116:	8c0080e7          	jalr	-1856(ra) # 800069d2 <snprintf>
    8000111a:	013509bb          	addw	s3,a0,s3
  release(&lock_locks);  
    8000111e:	00010517          	auipc	a0,0x10
    80001122:	2ea50513          	addi	a0,a0,746 # 80011408 <lock_locks>
    80001126:	00000097          	auipc	ra,0x0
    8000112a:	d18080e7          	jalr	-744(ra) # 80000e3e <release>
  return n;
}
    8000112e:	854e                	mv	a0,s3
    80001130:	70a6                	ld	ra,104(sp)
    80001132:	7406                	ld	s0,96(sp)
    80001134:	64e6                	ld	s1,88(sp)
    80001136:	6946                	ld	s2,80(sp)
    80001138:	69a6                	ld	s3,72(sp)
    8000113a:	6a06                	ld	s4,64(sp)
    8000113c:	7ae2                	ld	s5,56(sp)
    8000113e:	7b42                	ld	s6,48(sp)
    80001140:	7ba2                	ld	s7,40(sp)
    80001142:	7c02                	ld	s8,32(sp)
    80001144:	6ce2                	ld	s9,24(sp)
    80001146:	6d42                	ld	s10,16(sp)
    80001148:	6da2                	ld	s11,8(sp)
    8000114a:	6165                	addi	sp,sp,112
    8000114c:	8082                	ret

000000008000114e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    8000114e:	1141                	addi	sp,sp,-16
    80001150:	e422                	sd	s0,8(sp)
    80001152:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80001154:	ce09                	beqz	a2,8000116e <memset+0x20>
    80001156:	87aa                	mv	a5,a0
    80001158:	fff6071b          	addiw	a4,a2,-1
    8000115c:	1702                	slli	a4,a4,0x20
    8000115e:	9301                	srli	a4,a4,0x20
    80001160:	0705                	addi	a4,a4,1
    80001162:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80001164:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80001168:	0785                	addi	a5,a5,1
    8000116a:	fee79de3          	bne	a5,a4,80001164 <memset+0x16>
  }
  return dst;
}
    8000116e:	6422                	ld	s0,8(sp)
    80001170:	0141                	addi	sp,sp,16
    80001172:	8082                	ret

0000000080001174 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80001174:	1141                	addi	sp,sp,-16
    80001176:	e422                	sd	s0,8(sp)
    80001178:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    8000117a:	ca05                	beqz	a2,800011aa <memcmp+0x36>
    8000117c:	fff6069b          	addiw	a3,a2,-1
    80001180:	1682                	slli	a3,a3,0x20
    80001182:	9281                	srli	a3,a3,0x20
    80001184:	0685                	addi	a3,a3,1
    80001186:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80001188:	00054783          	lbu	a5,0(a0)
    8000118c:	0005c703          	lbu	a4,0(a1)
    80001190:	00e79863          	bne	a5,a4,800011a0 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80001194:	0505                	addi	a0,a0,1
    80001196:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80001198:	fed518e3          	bne	a0,a3,80001188 <memcmp+0x14>
  }

  return 0;
    8000119c:	4501                	li	a0,0
    8000119e:	a019                	j	800011a4 <memcmp+0x30>
      return *s1 - *s2;
    800011a0:	40e7853b          	subw	a0,a5,a4
}
    800011a4:	6422                	ld	s0,8(sp)
    800011a6:	0141                	addi	sp,sp,16
    800011a8:	8082                	ret
  return 0;
    800011aa:	4501                	li	a0,0
    800011ac:	bfe5                	j	800011a4 <memcmp+0x30>

00000000800011ae <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    800011ae:	1141                	addi	sp,sp,-16
    800011b0:	e422                	sd	s0,8(sp)
    800011b2:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    800011b4:	00a5f963          	bgeu	a1,a0,800011c6 <memmove+0x18>
    800011b8:	02061713          	slli	a4,a2,0x20
    800011bc:	9301                	srli	a4,a4,0x20
    800011be:	00e587b3          	add	a5,a1,a4
    800011c2:	02f56563          	bltu	a0,a5,800011ec <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    800011c6:	fff6069b          	addiw	a3,a2,-1
    800011ca:	ce11                	beqz	a2,800011e6 <memmove+0x38>
    800011cc:	1682                	slli	a3,a3,0x20
    800011ce:	9281                	srli	a3,a3,0x20
    800011d0:	0685                	addi	a3,a3,1
    800011d2:	96ae                	add	a3,a3,a1
    800011d4:	87aa                	mv	a5,a0
      *d++ = *s++;
    800011d6:	0585                	addi	a1,a1,1
    800011d8:	0785                	addi	a5,a5,1
    800011da:	fff5c703          	lbu	a4,-1(a1)
    800011de:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    800011e2:	fed59ae3          	bne	a1,a3,800011d6 <memmove+0x28>

  return dst;
}
    800011e6:	6422                	ld	s0,8(sp)
    800011e8:	0141                	addi	sp,sp,16
    800011ea:	8082                	ret
    d += n;
    800011ec:	972a                	add	a4,a4,a0
    while(n-- > 0)
    800011ee:	fff6069b          	addiw	a3,a2,-1
    800011f2:	da75                	beqz	a2,800011e6 <memmove+0x38>
    800011f4:	02069613          	slli	a2,a3,0x20
    800011f8:	9201                	srli	a2,a2,0x20
    800011fa:	fff64613          	not	a2,a2
    800011fe:	963e                	add	a2,a2,a5
      *--d = *--s;
    80001200:	17fd                	addi	a5,a5,-1
    80001202:	177d                	addi	a4,a4,-1
    80001204:	0007c683          	lbu	a3,0(a5)
    80001208:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    8000120c:	fec79ae3          	bne	a5,a2,80001200 <memmove+0x52>
    80001210:	bfd9                	j	800011e6 <memmove+0x38>

0000000080001212 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80001212:	1141                	addi	sp,sp,-16
    80001214:	e406                	sd	ra,8(sp)
    80001216:	e022                	sd	s0,0(sp)
    80001218:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f94080e7          	jalr	-108(ra) # 800011ae <memmove>
}
    80001222:	60a2                	ld	ra,8(sp)
    80001224:	6402                	ld	s0,0(sp)
    80001226:	0141                	addi	sp,sp,16
    80001228:	8082                	ret

000000008000122a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    8000122a:	1141                	addi	sp,sp,-16
    8000122c:	e422                	sd	s0,8(sp)
    8000122e:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80001230:	ce11                	beqz	a2,8000124c <strncmp+0x22>
    80001232:	00054783          	lbu	a5,0(a0)
    80001236:	cf89                	beqz	a5,80001250 <strncmp+0x26>
    80001238:	0005c703          	lbu	a4,0(a1)
    8000123c:	00f71a63          	bne	a4,a5,80001250 <strncmp+0x26>
    n--, p++, q++;
    80001240:	367d                	addiw	a2,a2,-1
    80001242:	0505                	addi	a0,a0,1
    80001244:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80001246:	f675                	bnez	a2,80001232 <strncmp+0x8>
  if(n == 0)
    return 0;
    80001248:	4501                	li	a0,0
    8000124a:	a809                	j	8000125c <strncmp+0x32>
    8000124c:	4501                	li	a0,0
    8000124e:	a039                	j	8000125c <strncmp+0x32>
  if(n == 0)
    80001250:	ca09                	beqz	a2,80001262 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80001252:	00054503          	lbu	a0,0(a0)
    80001256:	0005c783          	lbu	a5,0(a1)
    8000125a:	9d1d                	subw	a0,a0,a5
}
    8000125c:	6422                	ld	s0,8(sp)
    8000125e:	0141                	addi	sp,sp,16
    80001260:	8082                	ret
    return 0;
    80001262:	4501                	li	a0,0
    80001264:	bfe5                	j	8000125c <strncmp+0x32>

0000000080001266 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80001266:	1141                	addi	sp,sp,-16
    80001268:	e422                	sd	s0,8(sp)
    8000126a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    8000126c:	872a                	mv	a4,a0
    8000126e:	8832                	mv	a6,a2
    80001270:	367d                	addiw	a2,a2,-1
    80001272:	01005963          	blez	a6,80001284 <strncpy+0x1e>
    80001276:	0705                	addi	a4,a4,1
    80001278:	0005c783          	lbu	a5,0(a1)
    8000127c:	fef70fa3          	sb	a5,-1(a4)
    80001280:	0585                	addi	a1,a1,1
    80001282:	f7f5                	bnez	a5,8000126e <strncpy+0x8>
    ;
  while(n-- > 0)
    80001284:	00c05d63          	blez	a2,8000129e <strncpy+0x38>
    80001288:	86ba                	mv	a3,a4
    *s++ = 0;
    8000128a:	0685                	addi	a3,a3,1
    8000128c:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80001290:	fff6c793          	not	a5,a3
    80001294:	9fb9                	addw	a5,a5,a4
    80001296:	010787bb          	addw	a5,a5,a6
    8000129a:	fef048e3          	bgtz	a5,8000128a <strncpy+0x24>
  return os;
}
    8000129e:	6422                	ld	s0,8(sp)
    800012a0:	0141                	addi	sp,sp,16
    800012a2:	8082                	ret

00000000800012a4 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    800012a4:	1141                	addi	sp,sp,-16
    800012a6:	e422                	sd	s0,8(sp)
    800012a8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    800012aa:	02c05363          	blez	a2,800012d0 <safestrcpy+0x2c>
    800012ae:	fff6069b          	addiw	a3,a2,-1
    800012b2:	1682                	slli	a3,a3,0x20
    800012b4:	9281                	srli	a3,a3,0x20
    800012b6:	96ae                	add	a3,a3,a1
    800012b8:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    800012ba:	00d58963          	beq	a1,a3,800012cc <safestrcpy+0x28>
    800012be:	0585                	addi	a1,a1,1
    800012c0:	0785                	addi	a5,a5,1
    800012c2:	fff5c703          	lbu	a4,-1(a1)
    800012c6:	fee78fa3          	sb	a4,-1(a5)
    800012ca:	fb65                	bnez	a4,800012ba <safestrcpy+0x16>
    ;
  *s = 0;
    800012cc:	00078023          	sb	zero,0(a5)
  return os;
}
    800012d0:	6422                	ld	s0,8(sp)
    800012d2:	0141                	addi	sp,sp,16
    800012d4:	8082                	ret

00000000800012d6 <strlen>:

int
strlen(const char *s)
{
    800012d6:	1141                	addi	sp,sp,-16
    800012d8:	e422                	sd	s0,8(sp)
    800012da:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    800012dc:	00054783          	lbu	a5,0(a0)
    800012e0:	cf91                	beqz	a5,800012fc <strlen+0x26>
    800012e2:	0505                	addi	a0,a0,1
    800012e4:	87aa                	mv	a5,a0
    800012e6:	4685                	li	a3,1
    800012e8:	9e89                	subw	a3,a3,a0
    800012ea:	00f6853b          	addw	a0,a3,a5
    800012ee:	0785                	addi	a5,a5,1
    800012f0:	fff7c703          	lbu	a4,-1(a5)
    800012f4:	fb7d                	bnez	a4,800012ea <strlen+0x14>
    ;
  return n;
}
    800012f6:	6422                	ld	s0,8(sp)
    800012f8:	0141                	addi	sp,sp,16
    800012fa:	8082                	ret
  for(n = 0; s[n]; n++)
    800012fc:	4501                	li	a0,0
    800012fe:	bfe5                	j	800012f6 <strlen+0x20>

0000000080001300 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001300:	1141                	addi	sp,sp,-16
    80001302:	e406                	sd	ra,8(sp)
    80001304:	e022                	sd	s0,0(sp)
    80001306:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001308:	00001097          	auipc	ra,0x1
    8000130c:	a82080e7          	jalr	-1406(ra) # 80001d8a <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001310:	00008717          	auipc	a4,0x8
    80001314:	cfc70713          	addi	a4,a4,-772 # 8000900c <started>
  if(cpuid() == 0){
    80001318:	c139                	beqz	a0,8000135e <main+0x5e>
    while(started == 0)
    8000131a:	431c                	lw	a5,0(a4)
    8000131c:	2781                	sext.w	a5,a5
    8000131e:	dff5                	beqz	a5,8000131a <main+0x1a>
      ;
    __sync_synchronize();
    80001320:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001324:	00001097          	auipc	ra,0x1
    80001328:	a66080e7          	jalr	-1434(ra) # 80001d8a <cpuid>
    8000132c:	85aa                	mv	a1,a0
    8000132e:	00007517          	auipc	a0,0x7
    80001332:	e2a50513          	addi	a0,a0,-470 # 80008158 <digits+0x118>
    80001336:	fffff097          	auipc	ra,0xfffff
    8000133a:	264080e7          	jalr	612(ra) # 8000059a <printf>
    kvminithart();    // turn on paging
    8000133e:	00000097          	auipc	ra,0x0
    80001342:	186080e7          	jalr	390(ra) # 800014c4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001346:	00001097          	auipc	ra,0x1
    8000134a:	6ce080e7          	jalr	1742(ra) # 80002a14 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000134e:	00005097          	auipc	ra,0x5
    80001352:	ec2080e7          	jalr	-318(ra) # 80006210 <plicinithart>
  }

  scheduler();        
    80001356:	00001097          	auipc	ra,0x1
    8000135a:	f90080e7          	jalr	-112(ra) # 800022e6 <scheduler>
    consoleinit();
    8000135e:	fffff097          	auipc	ra,0xfffff
    80001362:	104080e7          	jalr	260(ra) # 80000462 <consoleinit>
    statsinit();
    80001366:	00005097          	auipc	ra,0x5
    8000136a:	590080e7          	jalr	1424(ra) # 800068f6 <statsinit>
    printfinit();
    8000136e:	fffff097          	auipc	ra,0xfffff
    80001372:	412080e7          	jalr	1042(ra) # 80000780 <printfinit>
    printf("\n");
    80001376:	00007517          	auipc	a0,0x7
    8000137a:	df250513          	addi	a0,a0,-526 # 80008168 <digits+0x128>
    8000137e:	fffff097          	auipc	ra,0xfffff
    80001382:	21c080e7          	jalr	540(ra) # 8000059a <printf>
    printf("xv6 kernel is booting\n");
    80001386:	00007517          	auipc	a0,0x7
    8000138a:	dba50513          	addi	a0,a0,-582 # 80008140 <digits+0x100>
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	20c080e7          	jalr	524(ra) # 8000059a <printf>
    printf("\n");
    80001396:	00007517          	auipc	a0,0x7
    8000139a:	dd250513          	addi	a0,a0,-558 # 80008168 <digits+0x128>
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	1fc080e7          	jalr	508(ra) # 8000059a <printf>
    kinit();         // physical page allocator
    800013a6:	fffff097          	auipc	ra,0xfffff
    800013aa:	776080e7          	jalr	1910(ra) # 80000b1c <kinit>
    kvminit();       // create kernel page table
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	242080e7          	jalr	578(ra) # 800015f0 <kvminit>
    kvminithart();   // turn on paging
    800013b6:	00000097          	auipc	ra,0x0
    800013ba:	10e080e7          	jalr	270(ra) # 800014c4 <kvminithart>
    procinit();      // process table
    800013be:	00001097          	auipc	ra,0x1
    800013c2:	8fc080e7          	jalr	-1796(ra) # 80001cba <procinit>
    trapinit();      // trap vectors
    800013c6:	00001097          	auipc	ra,0x1
    800013ca:	626080e7          	jalr	1574(ra) # 800029ec <trapinit>
    trapinithart();  // install kernel trap vector
    800013ce:	00001097          	auipc	ra,0x1
    800013d2:	646080e7          	jalr	1606(ra) # 80002a14 <trapinithart>
    plicinit();      // set up interrupt controller
    800013d6:	00005097          	auipc	ra,0x5
    800013da:	e24080e7          	jalr	-476(ra) # 800061fa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800013de:	00005097          	auipc	ra,0x5
    800013e2:	e32080e7          	jalr	-462(ra) # 80006210 <plicinithart>
    binit();         // buffer cache
    800013e6:	00002097          	auipc	ra,0x2
    800013ea:	d70080e7          	jalr	-656(ra) # 80003156 <binit>
    iinit();         // inode cache
    800013ee:	00002097          	auipc	ra,0x2
    800013f2:	644080e7          	jalr	1604(ra) # 80003a32 <iinit>
    fileinit();      // file table
    800013f6:	00003097          	auipc	ra,0x3
    800013fa:	5f4080e7          	jalr	1524(ra) # 800049ea <fileinit>
    virtio_disk_init(); // emulated hard disk
    800013fe:	00005097          	auipc	ra,0x5
    80001402:	f34080e7          	jalr	-204(ra) # 80006332 <virtio_disk_init>
    userinit();      // first user process
    80001406:	00001097          	auipc	ra,0x1
    8000140a:	c7a080e7          	jalr	-902(ra) # 80002080 <userinit>
    __sync_synchronize();
    8000140e:	0ff0000f          	fence
    started = 1;
    80001412:	4785                	li	a5,1
    80001414:	00008717          	auipc	a4,0x8
    80001418:	bef72c23          	sw	a5,-1032(a4) # 8000900c <started>
    8000141c:	bf2d                	j	80001356 <main+0x56>

000000008000141e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000141e:	7139                	addi	sp,sp,-64
    80001420:	fc06                	sd	ra,56(sp)
    80001422:	f822                	sd	s0,48(sp)
    80001424:	f426                	sd	s1,40(sp)
    80001426:	f04a                	sd	s2,32(sp)
    80001428:	ec4e                	sd	s3,24(sp)
    8000142a:	e852                	sd	s4,16(sp)
    8000142c:	e456                	sd	s5,8(sp)
    8000142e:	e05a                	sd	s6,0(sp)
    80001430:	0080                	addi	s0,sp,64
    80001432:	84aa                	mv	s1,a0
    80001434:	89ae                	mv	s3,a1
    80001436:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001438:	57fd                	li	a5,-1
    8000143a:	83e9                	srli	a5,a5,0x1a
    8000143c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000143e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001440:	04b7f263          	bgeu	a5,a1,80001484 <walk+0x66>
    panic("walk");
    80001444:	00007517          	auipc	a0,0x7
    80001448:	d2c50513          	addi	a0,a0,-724 # 80008170 <digits+0x130>
    8000144c:	fffff097          	auipc	ra,0xfffff
    80001450:	104080e7          	jalr	260(ra) # 80000550 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001454:	060a8663          	beqz	s5,800014c0 <walk+0xa2>
    80001458:	fffff097          	auipc	ra,0xfffff
    8000145c:	73a080e7          	jalr	1850(ra) # 80000b92 <kalloc>
    80001460:	84aa                	mv	s1,a0
    80001462:	c529                	beqz	a0,800014ac <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001464:	6605                	lui	a2,0x1
    80001466:	4581                	li	a1,0
    80001468:	00000097          	auipc	ra,0x0
    8000146c:	ce6080e7          	jalr	-794(ra) # 8000114e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001470:	00c4d793          	srli	a5,s1,0xc
    80001474:	07aa                	slli	a5,a5,0xa
    80001476:	0017e793          	ori	a5,a5,1
    8000147a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000147e:	3a5d                	addiw	s4,s4,-9
    80001480:	036a0063          	beq	s4,s6,800014a0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001484:	0149d933          	srl	s2,s3,s4
    80001488:	1ff97913          	andi	s2,s2,511
    8000148c:	090e                	slli	s2,s2,0x3
    8000148e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001490:	00093483          	ld	s1,0(s2)
    80001494:	0014f793          	andi	a5,s1,1
    80001498:	dfd5                	beqz	a5,80001454 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000149a:	80a9                	srli	s1,s1,0xa
    8000149c:	04b2                	slli	s1,s1,0xc
    8000149e:	b7c5                	j	8000147e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800014a0:	00c9d513          	srli	a0,s3,0xc
    800014a4:	1ff57513          	andi	a0,a0,511
    800014a8:	050e                	slli	a0,a0,0x3
    800014aa:	9526                	add	a0,a0,s1
}
    800014ac:	70e2                	ld	ra,56(sp)
    800014ae:	7442                	ld	s0,48(sp)
    800014b0:	74a2                	ld	s1,40(sp)
    800014b2:	7902                	ld	s2,32(sp)
    800014b4:	69e2                	ld	s3,24(sp)
    800014b6:	6a42                	ld	s4,16(sp)
    800014b8:	6aa2                	ld	s5,8(sp)
    800014ba:	6b02                	ld	s6,0(sp)
    800014bc:	6121                	addi	sp,sp,64
    800014be:	8082                	ret
        return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	b7ed                	j	800014ac <walk+0x8e>

00000000800014c4 <kvminithart>:
{
    800014c4:	1141                	addi	sp,sp,-16
    800014c6:	e422                	sd	s0,8(sp)
    800014c8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800014ca:	00008797          	auipc	a5,0x8
    800014ce:	b467b783          	ld	a5,-1210(a5) # 80009010 <kernel_pagetable>
    800014d2:	83b1                	srli	a5,a5,0xc
    800014d4:	577d                	li	a4,-1
    800014d6:	177e                	slli	a4,a4,0x3f
    800014d8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800014da:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800014de:	12000073          	sfence.vma
}
    800014e2:	6422                	ld	s0,8(sp)
    800014e4:	0141                	addi	sp,sp,16
    800014e6:	8082                	ret

00000000800014e8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800014e8:	57fd                	li	a5,-1
    800014ea:	83e9                	srli	a5,a5,0x1a
    800014ec:	00b7f463          	bgeu	a5,a1,800014f4 <walkaddr+0xc>
    return 0;
    800014f0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800014f2:	8082                	ret
{
    800014f4:	1141                	addi	sp,sp,-16
    800014f6:	e406                	sd	ra,8(sp)
    800014f8:	e022                	sd	s0,0(sp)
    800014fa:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800014fc:	4601                	li	a2,0
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	f20080e7          	jalr	-224(ra) # 8000141e <walk>
  if(pte == 0)
    80001506:	c105                	beqz	a0,80001526 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001508:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000150a:	0117f693          	andi	a3,a5,17
    8000150e:	4745                	li	a4,17
    return 0;
    80001510:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001512:	00e68663          	beq	a3,a4,8000151e <walkaddr+0x36>
}
    80001516:	60a2                	ld	ra,8(sp)
    80001518:	6402                	ld	s0,0(sp)
    8000151a:	0141                	addi	sp,sp,16
    8000151c:	8082                	ret
  pa = PTE2PA(*pte);
    8000151e:	00a7d513          	srli	a0,a5,0xa
    80001522:	0532                	slli	a0,a0,0xc
  return pa;
    80001524:	bfcd                	j	80001516 <walkaddr+0x2e>
    return 0;
    80001526:	4501                	li	a0,0
    80001528:	b7fd                	j	80001516 <walkaddr+0x2e>

000000008000152a <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000152a:	715d                	addi	sp,sp,-80
    8000152c:	e486                	sd	ra,72(sp)
    8000152e:	e0a2                	sd	s0,64(sp)
    80001530:	fc26                	sd	s1,56(sp)
    80001532:	f84a                	sd	s2,48(sp)
    80001534:	f44e                	sd	s3,40(sp)
    80001536:	f052                	sd	s4,32(sp)
    80001538:	ec56                	sd	s5,24(sp)
    8000153a:	e85a                	sd	s6,16(sp)
    8000153c:	e45e                	sd	s7,8(sp)
    8000153e:	0880                	addi	s0,sp,80
    80001540:	8aaa                	mv	s5,a0
    80001542:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001544:	777d                	lui	a4,0xfffff
    80001546:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000154a:	167d                	addi	a2,a2,-1
    8000154c:	00b609b3          	add	s3,a2,a1
    80001550:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001554:	893e                	mv	s2,a5
    80001556:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000155a:	6b85                	lui	s7,0x1
    8000155c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001560:	4605                	li	a2,1
    80001562:	85ca                	mv	a1,s2
    80001564:	8556                	mv	a0,s5
    80001566:	00000097          	auipc	ra,0x0
    8000156a:	eb8080e7          	jalr	-328(ra) # 8000141e <walk>
    8000156e:	c51d                	beqz	a0,8000159c <mappages+0x72>
    if(*pte & PTE_V)
    80001570:	611c                	ld	a5,0(a0)
    80001572:	8b85                	andi	a5,a5,1
    80001574:	ef81                	bnez	a5,8000158c <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001576:	80b1                	srli	s1,s1,0xc
    80001578:	04aa                	slli	s1,s1,0xa
    8000157a:	0164e4b3          	or	s1,s1,s6
    8000157e:	0014e493          	ori	s1,s1,1
    80001582:	e104                	sd	s1,0(a0)
    if(a == last)
    80001584:	03390863          	beq	s2,s3,800015b4 <mappages+0x8a>
    a += PGSIZE;
    80001588:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000158a:	bfc9                	j	8000155c <mappages+0x32>
      panic("remap");
    8000158c:	00007517          	auipc	a0,0x7
    80001590:	bec50513          	addi	a0,a0,-1044 # 80008178 <digits+0x138>
    80001594:	fffff097          	auipc	ra,0xfffff
    80001598:	fbc080e7          	jalr	-68(ra) # 80000550 <panic>
      return -1;
    8000159c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000159e:	60a6                	ld	ra,72(sp)
    800015a0:	6406                	ld	s0,64(sp)
    800015a2:	74e2                	ld	s1,56(sp)
    800015a4:	7942                	ld	s2,48(sp)
    800015a6:	79a2                	ld	s3,40(sp)
    800015a8:	7a02                	ld	s4,32(sp)
    800015aa:	6ae2                	ld	s5,24(sp)
    800015ac:	6b42                	ld	s6,16(sp)
    800015ae:	6ba2                	ld	s7,8(sp)
    800015b0:	6161                	addi	sp,sp,80
    800015b2:	8082                	ret
  return 0;
    800015b4:	4501                	li	a0,0
    800015b6:	b7e5                	j	8000159e <mappages+0x74>

00000000800015b8 <kvmmap>:
{
    800015b8:	1141                	addi	sp,sp,-16
    800015ba:	e406                	sd	ra,8(sp)
    800015bc:	e022                	sd	s0,0(sp)
    800015be:	0800                	addi	s0,sp,16
    800015c0:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800015c2:	86ae                	mv	a3,a1
    800015c4:	85aa                	mv	a1,a0
    800015c6:	00008517          	auipc	a0,0x8
    800015ca:	a4a53503          	ld	a0,-1462(a0) # 80009010 <kernel_pagetable>
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	f5c080e7          	jalr	-164(ra) # 8000152a <mappages>
    800015d6:	e509                	bnez	a0,800015e0 <kvmmap+0x28>
}
    800015d8:	60a2                	ld	ra,8(sp)
    800015da:	6402                	ld	s0,0(sp)
    800015dc:	0141                	addi	sp,sp,16
    800015de:	8082                	ret
    panic("kvmmap");
    800015e0:	00007517          	auipc	a0,0x7
    800015e4:	ba050513          	addi	a0,a0,-1120 # 80008180 <digits+0x140>
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	f68080e7          	jalr	-152(ra) # 80000550 <panic>

00000000800015f0 <kvminit>:
{
    800015f0:	1101                	addi	sp,sp,-32
    800015f2:	ec06                	sd	ra,24(sp)
    800015f4:	e822                	sd	s0,16(sp)
    800015f6:	e426                	sd	s1,8(sp)
    800015f8:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	598080e7          	jalr	1432(ra) # 80000b92 <kalloc>
    80001602:	00008797          	auipc	a5,0x8
    80001606:	a0a7b723          	sd	a0,-1522(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000160a:	6605                	lui	a2,0x1
    8000160c:	4581                	li	a1,0
    8000160e:	00000097          	auipc	ra,0x0
    80001612:	b40080e7          	jalr	-1216(ra) # 8000114e <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001616:	4699                	li	a3,6
    80001618:	6605                	lui	a2,0x1
    8000161a:	100005b7          	lui	a1,0x10000
    8000161e:	10000537          	lui	a0,0x10000
    80001622:	00000097          	auipc	ra,0x0
    80001626:	f96080e7          	jalr	-106(ra) # 800015b8 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000162a:	4699                	li	a3,6
    8000162c:	6605                	lui	a2,0x1
    8000162e:	100015b7          	lui	a1,0x10001
    80001632:	10001537          	lui	a0,0x10001
    80001636:	00000097          	auipc	ra,0x0
    8000163a:	f82080e7          	jalr	-126(ra) # 800015b8 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000163e:	4699                	li	a3,6
    80001640:	00400637          	lui	a2,0x400
    80001644:	0c0005b7          	lui	a1,0xc000
    80001648:	0c000537          	lui	a0,0xc000
    8000164c:	00000097          	auipc	ra,0x0
    80001650:	f6c080e7          	jalr	-148(ra) # 800015b8 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001654:	00007497          	auipc	s1,0x7
    80001658:	9ac48493          	addi	s1,s1,-1620 # 80008000 <etext>
    8000165c:	46a9                	li	a3,10
    8000165e:	80007617          	auipc	a2,0x80007
    80001662:	9a260613          	addi	a2,a2,-1630 # 8000 <_entry-0x7fff8000>
    80001666:	4585                	li	a1,1
    80001668:	05fe                	slli	a1,a1,0x1f
    8000166a:	852e                	mv	a0,a1
    8000166c:	00000097          	auipc	ra,0x0
    80001670:	f4c080e7          	jalr	-180(ra) # 800015b8 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001674:	4699                	li	a3,6
    80001676:	4645                	li	a2,17
    80001678:	066e                	slli	a2,a2,0x1b
    8000167a:	8e05                	sub	a2,a2,s1
    8000167c:	85a6                	mv	a1,s1
    8000167e:	8526                	mv	a0,s1
    80001680:	00000097          	auipc	ra,0x0
    80001684:	f38080e7          	jalr	-200(ra) # 800015b8 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001688:	46a9                	li	a3,10
    8000168a:	6605                	lui	a2,0x1
    8000168c:	00006597          	auipc	a1,0x6
    80001690:	97458593          	addi	a1,a1,-1676 # 80007000 <_trampoline>
    80001694:	04000537          	lui	a0,0x4000
    80001698:	157d                	addi	a0,a0,-1
    8000169a:	0532                	slli	a0,a0,0xc
    8000169c:	00000097          	auipc	ra,0x0
    800016a0:	f1c080e7          	jalr	-228(ra) # 800015b8 <kvmmap>
}
    800016a4:	60e2                	ld	ra,24(sp)
    800016a6:	6442                	ld	s0,16(sp)
    800016a8:	64a2                	ld	s1,8(sp)
    800016aa:	6105                	addi	sp,sp,32
    800016ac:	8082                	ret

00000000800016ae <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800016ae:	715d                	addi	sp,sp,-80
    800016b0:	e486                	sd	ra,72(sp)
    800016b2:	e0a2                	sd	s0,64(sp)
    800016b4:	fc26                	sd	s1,56(sp)
    800016b6:	f84a                	sd	s2,48(sp)
    800016b8:	f44e                	sd	s3,40(sp)
    800016ba:	f052                	sd	s4,32(sp)
    800016bc:	ec56                	sd	s5,24(sp)
    800016be:	e85a                	sd	s6,16(sp)
    800016c0:	e45e                	sd	s7,8(sp)
    800016c2:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800016c4:	03459793          	slli	a5,a1,0x34
    800016c8:	e795                	bnez	a5,800016f4 <uvmunmap+0x46>
    800016ca:	8a2a                	mv	s4,a0
    800016cc:	892e                	mv	s2,a1
    800016ce:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800016d0:	0632                	slli	a2,a2,0xc
    800016d2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800016d6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800016d8:	6b05                	lui	s6,0x1
    800016da:	0735e863          	bltu	a1,s3,8000174a <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800016de:	60a6                	ld	ra,72(sp)
    800016e0:	6406                	ld	s0,64(sp)
    800016e2:	74e2                	ld	s1,56(sp)
    800016e4:	7942                	ld	s2,48(sp)
    800016e6:	79a2                	ld	s3,40(sp)
    800016e8:	7a02                	ld	s4,32(sp)
    800016ea:	6ae2                	ld	s5,24(sp)
    800016ec:	6b42                	ld	s6,16(sp)
    800016ee:	6ba2                	ld	s7,8(sp)
    800016f0:	6161                	addi	sp,sp,80
    800016f2:	8082                	ret
    panic("uvmunmap: not aligned");
    800016f4:	00007517          	auipc	a0,0x7
    800016f8:	a9450513          	addi	a0,a0,-1388 # 80008188 <digits+0x148>
    800016fc:	fffff097          	auipc	ra,0xfffff
    80001700:	e54080e7          	jalr	-428(ra) # 80000550 <panic>
      panic("uvmunmap: walk");
    80001704:	00007517          	auipc	a0,0x7
    80001708:	a9c50513          	addi	a0,a0,-1380 # 800081a0 <digits+0x160>
    8000170c:	fffff097          	auipc	ra,0xfffff
    80001710:	e44080e7          	jalr	-444(ra) # 80000550 <panic>
      panic("uvmunmap: not mapped");
    80001714:	00007517          	auipc	a0,0x7
    80001718:	a9c50513          	addi	a0,a0,-1380 # 800081b0 <digits+0x170>
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	e34080e7          	jalr	-460(ra) # 80000550 <panic>
      panic("uvmunmap: not a leaf");
    80001724:	00007517          	auipc	a0,0x7
    80001728:	aa450513          	addi	a0,a0,-1372 # 800081c8 <digits+0x188>
    8000172c:	fffff097          	auipc	ra,0xfffff
    80001730:	e24080e7          	jalr	-476(ra) # 80000550 <panic>
      uint64 pa = PTE2PA(*pte);
    80001734:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001736:	0532                	slli	a0,a0,0xc
    80001738:	fffff097          	auipc	ra,0xfffff
    8000173c:	2f4080e7          	jalr	756(ra) # 80000a2c <kfree>
    *pte = 0;
    80001740:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001744:	995a                	add	s2,s2,s6
    80001746:	f9397ce3          	bgeu	s2,s3,800016de <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000174a:	4601                	li	a2,0
    8000174c:	85ca                	mv	a1,s2
    8000174e:	8552                	mv	a0,s4
    80001750:	00000097          	auipc	ra,0x0
    80001754:	cce080e7          	jalr	-818(ra) # 8000141e <walk>
    80001758:	84aa                	mv	s1,a0
    8000175a:	d54d                	beqz	a0,80001704 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000175c:	6108                	ld	a0,0(a0)
    8000175e:	00157793          	andi	a5,a0,1
    80001762:	dbcd                	beqz	a5,80001714 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001764:	3ff57793          	andi	a5,a0,1023
    80001768:	fb778ee3          	beq	a5,s7,80001724 <uvmunmap+0x76>
    if(do_free){
    8000176c:	fc0a8ae3          	beqz	s5,80001740 <uvmunmap+0x92>
    80001770:	b7d1                	j	80001734 <uvmunmap+0x86>

0000000080001772 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001772:	1101                	addi	sp,sp,-32
    80001774:	ec06                	sd	ra,24(sp)
    80001776:	e822                	sd	s0,16(sp)
    80001778:	e426                	sd	s1,8(sp)
    8000177a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000177c:	fffff097          	auipc	ra,0xfffff
    80001780:	416080e7          	jalr	1046(ra) # 80000b92 <kalloc>
    80001784:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001786:	c519                	beqz	a0,80001794 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001788:	6605                	lui	a2,0x1
    8000178a:	4581                	li	a1,0
    8000178c:	00000097          	auipc	ra,0x0
    80001790:	9c2080e7          	jalr	-1598(ra) # 8000114e <memset>
  return pagetable;
}
    80001794:	8526                	mv	a0,s1
    80001796:	60e2                	ld	ra,24(sp)
    80001798:	6442                	ld	s0,16(sp)
    8000179a:	64a2                	ld	s1,8(sp)
    8000179c:	6105                	addi	sp,sp,32
    8000179e:	8082                	ret

00000000800017a0 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800017a0:	7179                	addi	sp,sp,-48
    800017a2:	f406                	sd	ra,40(sp)
    800017a4:	f022                	sd	s0,32(sp)
    800017a6:	ec26                	sd	s1,24(sp)
    800017a8:	e84a                	sd	s2,16(sp)
    800017aa:	e44e                	sd	s3,8(sp)
    800017ac:	e052                	sd	s4,0(sp)
    800017ae:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800017b0:	6785                	lui	a5,0x1
    800017b2:	04f67863          	bgeu	a2,a5,80001802 <uvminit+0x62>
    800017b6:	8a2a                	mv	s4,a0
    800017b8:	89ae                	mv	s3,a1
    800017ba:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800017bc:	fffff097          	auipc	ra,0xfffff
    800017c0:	3d6080e7          	jalr	982(ra) # 80000b92 <kalloc>
    800017c4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800017c6:	6605                	lui	a2,0x1
    800017c8:	4581                	li	a1,0
    800017ca:	00000097          	auipc	ra,0x0
    800017ce:	984080e7          	jalr	-1660(ra) # 8000114e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800017d2:	4779                	li	a4,30
    800017d4:	86ca                	mv	a3,s2
    800017d6:	6605                	lui	a2,0x1
    800017d8:	4581                	li	a1,0
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	d4e080e7          	jalr	-690(ra) # 8000152a <mappages>
  memmove(mem, src, sz);
    800017e4:	8626                	mv	a2,s1
    800017e6:	85ce                	mv	a1,s3
    800017e8:	854a                	mv	a0,s2
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	9c4080e7          	jalr	-1596(ra) # 800011ae <memmove>
}
    800017f2:	70a2                	ld	ra,40(sp)
    800017f4:	7402                	ld	s0,32(sp)
    800017f6:	64e2                	ld	s1,24(sp)
    800017f8:	6942                	ld	s2,16(sp)
    800017fa:	69a2                	ld	s3,8(sp)
    800017fc:	6a02                	ld	s4,0(sp)
    800017fe:	6145                	addi	sp,sp,48
    80001800:	8082                	ret
    panic("inituvm: more than a page");
    80001802:	00007517          	auipc	a0,0x7
    80001806:	9de50513          	addi	a0,a0,-1570 # 800081e0 <digits+0x1a0>
    8000180a:	fffff097          	auipc	ra,0xfffff
    8000180e:	d46080e7          	jalr	-698(ra) # 80000550 <panic>

0000000080001812 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001812:	1101                	addi	sp,sp,-32
    80001814:	ec06                	sd	ra,24(sp)
    80001816:	e822                	sd	s0,16(sp)
    80001818:	e426                	sd	s1,8(sp)
    8000181a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000181c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000181e:	00b67d63          	bgeu	a2,a1,80001838 <uvmdealloc+0x26>
    80001822:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001824:	6785                	lui	a5,0x1
    80001826:	17fd                	addi	a5,a5,-1
    80001828:	00f60733          	add	a4,a2,a5
    8000182c:	767d                	lui	a2,0xfffff
    8000182e:	8f71                	and	a4,a4,a2
    80001830:	97ae                	add	a5,a5,a1
    80001832:	8ff1                	and	a5,a5,a2
    80001834:	00f76863          	bltu	a4,a5,80001844 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001838:	8526                	mv	a0,s1
    8000183a:	60e2                	ld	ra,24(sp)
    8000183c:	6442                	ld	s0,16(sp)
    8000183e:	64a2                	ld	s1,8(sp)
    80001840:	6105                	addi	sp,sp,32
    80001842:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001844:	8f99                	sub	a5,a5,a4
    80001846:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001848:	4685                	li	a3,1
    8000184a:	0007861b          	sext.w	a2,a5
    8000184e:	85ba                	mv	a1,a4
    80001850:	00000097          	auipc	ra,0x0
    80001854:	e5e080e7          	jalr	-418(ra) # 800016ae <uvmunmap>
    80001858:	b7c5                	j	80001838 <uvmdealloc+0x26>

000000008000185a <uvmalloc>:
  if(newsz < oldsz)
    8000185a:	0ab66163          	bltu	a2,a1,800018fc <uvmalloc+0xa2>
{
    8000185e:	7139                	addi	sp,sp,-64
    80001860:	fc06                	sd	ra,56(sp)
    80001862:	f822                	sd	s0,48(sp)
    80001864:	f426                	sd	s1,40(sp)
    80001866:	f04a                	sd	s2,32(sp)
    80001868:	ec4e                	sd	s3,24(sp)
    8000186a:	e852                	sd	s4,16(sp)
    8000186c:	e456                	sd	s5,8(sp)
    8000186e:	0080                	addi	s0,sp,64
    80001870:	8aaa                	mv	s5,a0
    80001872:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001874:	6985                	lui	s3,0x1
    80001876:	19fd                	addi	s3,s3,-1
    80001878:	95ce                	add	a1,a1,s3
    8000187a:	79fd                	lui	s3,0xfffff
    8000187c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001880:	08c9f063          	bgeu	s3,a2,80001900 <uvmalloc+0xa6>
    80001884:	894e                	mv	s2,s3
    mem = kalloc();
    80001886:	fffff097          	auipc	ra,0xfffff
    8000188a:	30c080e7          	jalr	780(ra) # 80000b92 <kalloc>
    8000188e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001890:	c51d                	beqz	a0,800018be <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001892:	6605                	lui	a2,0x1
    80001894:	4581                	li	a1,0
    80001896:	00000097          	auipc	ra,0x0
    8000189a:	8b8080e7          	jalr	-1864(ra) # 8000114e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000189e:	4779                	li	a4,30
    800018a0:	86a6                	mv	a3,s1
    800018a2:	6605                	lui	a2,0x1
    800018a4:	85ca                	mv	a1,s2
    800018a6:	8556                	mv	a0,s5
    800018a8:	00000097          	auipc	ra,0x0
    800018ac:	c82080e7          	jalr	-894(ra) # 8000152a <mappages>
    800018b0:	e905                	bnez	a0,800018e0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800018b2:	6785                	lui	a5,0x1
    800018b4:	993e                	add	s2,s2,a5
    800018b6:	fd4968e3          	bltu	s2,s4,80001886 <uvmalloc+0x2c>
  return newsz;
    800018ba:	8552                	mv	a0,s4
    800018bc:	a809                	j	800018ce <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800018be:	864e                	mv	a2,s3
    800018c0:	85ca                	mv	a1,s2
    800018c2:	8556                	mv	a0,s5
    800018c4:	00000097          	auipc	ra,0x0
    800018c8:	f4e080e7          	jalr	-178(ra) # 80001812 <uvmdealloc>
      return 0;
    800018cc:	4501                	li	a0,0
}
    800018ce:	70e2                	ld	ra,56(sp)
    800018d0:	7442                	ld	s0,48(sp)
    800018d2:	74a2                	ld	s1,40(sp)
    800018d4:	7902                	ld	s2,32(sp)
    800018d6:	69e2                	ld	s3,24(sp)
    800018d8:	6a42                	ld	s4,16(sp)
    800018da:	6aa2                	ld	s5,8(sp)
    800018dc:	6121                	addi	sp,sp,64
    800018de:	8082                	ret
      kfree(mem);
    800018e0:	8526                	mv	a0,s1
    800018e2:	fffff097          	auipc	ra,0xfffff
    800018e6:	14a080e7          	jalr	330(ra) # 80000a2c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800018ea:	864e                	mv	a2,s3
    800018ec:	85ca                	mv	a1,s2
    800018ee:	8556                	mv	a0,s5
    800018f0:	00000097          	auipc	ra,0x0
    800018f4:	f22080e7          	jalr	-222(ra) # 80001812 <uvmdealloc>
      return 0;
    800018f8:	4501                	li	a0,0
    800018fa:	bfd1                	j	800018ce <uvmalloc+0x74>
    return oldsz;
    800018fc:	852e                	mv	a0,a1
}
    800018fe:	8082                	ret
  return newsz;
    80001900:	8532                	mv	a0,a2
    80001902:	b7f1                	j	800018ce <uvmalloc+0x74>

0000000080001904 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001904:	7179                	addi	sp,sp,-48
    80001906:	f406                	sd	ra,40(sp)
    80001908:	f022                	sd	s0,32(sp)
    8000190a:	ec26                	sd	s1,24(sp)
    8000190c:	e84a                	sd	s2,16(sp)
    8000190e:	e44e                	sd	s3,8(sp)
    80001910:	e052                	sd	s4,0(sp)
    80001912:	1800                	addi	s0,sp,48
    80001914:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001916:	84aa                	mv	s1,a0
    80001918:	6905                	lui	s2,0x1
    8000191a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000191c:	4985                	li	s3,1
    8000191e:	a821                	j	80001936 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001920:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001922:	0532                	slli	a0,a0,0xc
    80001924:	00000097          	auipc	ra,0x0
    80001928:	fe0080e7          	jalr	-32(ra) # 80001904 <freewalk>
      pagetable[i] = 0;
    8000192c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001930:	04a1                	addi	s1,s1,8
    80001932:	03248163          	beq	s1,s2,80001954 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001936:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001938:	00f57793          	andi	a5,a0,15
    8000193c:	ff3782e3          	beq	a5,s3,80001920 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001940:	8905                	andi	a0,a0,1
    80001942:	d57d                	beqz	a0,80001930 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001944:	00007517          	auipc	a0,0x7
    80001948:	8bc50513          	addi	a0,a0,-1860 # 80008200 <digits+0x1c0>
    8000194c:	fffff097          	auipc	ra,0xfffff
    80001950:	c04080e7          	jalr	-1020(ra) # 80000550 <panic>
    }
  }
  kfree((void*)pagetable);
    80001954:	8552                	mv	a0,s4
    80001956:	fffff097          	auipc	ra,0xfffff
    8000195a:	0d6080e7          	jalr	214(ra) # 80000a2c <kfree>
}
    8000195e:	70a2                	ld	ra,40(sp)
    80001960:	7402                	ld	s0,32(sp)
    80001962:	64e2                	ld	s1,24(sp)
    80001964:	6942                	ld	s2,16(sp)
    80001966:	69a2                	ld	s3,8(sp)
    80001968:	6a02                	ld	s4,0(sp)
    8000196a:	6145                	addi	sp,sp,48
    8000196c:	8082                	ret

000000008000196e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000196e:	1101                	addi	sp,sp,-32
    80001970:	ec06                	sd	ra,24(sp)
    80001972:	e822                	sd	s0,16(sp)
    80001974:	e426                	sd	s1,8(sp)
    80001976:	1000                	addi	s0,sp,32
    80001978:	84aa                	mv	s1,a0
  if(sz > 0)
    8000197a:	e999                	bnez	a1,80001990 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000197c:	8526                	mv	a0,s1
    8000197e:	00000097          	auipc	ra,0x0
    80001982:	f86080e7          	jalr	-122(ra) # 80001904 <freewalk>
}
    80001986:	60e2                	ld	ra,24(sp)
    80001988:	6442                	ld	s0,16(sp)
    8000198a:	64a2                	ld	s1,8(sp)
    8000198c:	6105                	addi	sp,sp,32
    8000198e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001990:	6605                	lui	a2,0x1
    80001992:	167d                	addi	a2,a2,-1
    80001994:	962e                	add	a2,a2,a1
    80001996:	4685                	li	a3,1
    80001998:	8231                	srli	a2,a2,0xc
    8000199a:	4581                	li	a1,0
    8000199c:	00000097          	auipc	ra,0x0
    800019a0:	d12080e7          	jalr	-750(ra) # 800016ae <uvmunmap>
    800019a4:	bfe1                	j	8000197c <uvmfree+0xe>

00000000800019a6 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800019a6:	c679                	beqz	a2,80001a74 <uvmcopy+0xce>
{
    800019a8:	715d                	addi	sp,sp,-80
    800019aa:	e486                	sd	ra,72(sp)
    800019ac:	e0a2                	sd	s0,64(sp)
    800019ae:	fc26                	sd	s1,56(sp)
    800019b0:	f84a                	sd	s2,48(sp)
    800019b2:	f44e                	sd	s3,40(sp)
    800019b4:	f052                	sd	s4,32(sp)
    800019b6:	ec56                	sd	s5,24(sp)
    800019b8:	e85a                	sd	s6,16(sp)
    800019ba:	e45e                	sd	s7,8(sp)
    800019bc:	0880                	addi	s0,sp,80
    800019be:	8b2a                	mv	s6,a0
    800019c0:	8aae                	mv	s5,a1
    800019c2:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800019c4:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800019c6:	4601                	li	a2,0
    800019c8:	85ce                	mv	a1,s3
    800019ca:	855a                	mv	a0,s6
    800019cc:	00000097          	auipc	ra,0x0
    800019d0:	a52080e7          	jalr	-1454(ra) # 8000141e <walk>
    800019d4:	c531                	beqz	a0,80001a20 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800019d6:	6118                	ld	a4,0(a0)
    800019d8:	00177793          	andi	a5,a4,1
    800019dc:	cbb1                	beqz	a5,80001a30 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800019de:	00a75593          	srli	a1,a4,0xa
    800019e2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800019e6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	1a8080e7          	jalr	424(ra) # 80000b92 <kalloc>
    800019f2:	892a                	mv	s2,a0
    800019f4:	c939                	beqz	a0,80001a4a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800019f6:	6605                	lui	a2,0x1
    800019f8:	85de                	mv	a1,s7
    800019fa:	fffff097          	auipc	ra,0xfffff
    800019fe:	7b4080e7          	jalr	1972(ra) # 800011ae <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001a02:	8726                	mv	a4,s1
    80001a04:	86ca                	mv	a3,s2
    80001a06:	6605                	lui	a2,0x1
    80001a08:	85ce                	mv	a1,s3
    80001a0a:	8556                	mv	a0,s5
    80001a0c:	00000097          	auipc	ra,0x0
    80001a10:	b1e080e7          	jalr	-1250(ra) # 8000152a <mappages>
    80001a14:	e515                	bnez	a0,80001a40 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001a16:	6785                	lui	a5,0x1
    80001a18:	99be                	add	s3,s3,a5
    80001a1a:	fb49e6e3          	bltu	s3,s4,800019c6 <uvmcopy+0x20>
    80001a1e:	a081                	j	80001a5e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001a20:	00006517          	auipc	a0,0x6
    80001a24:	7f050513          	addi	a0,a0,2032 # 80008210 <digits+0x1d0>
    80001a28:	fffff097          	auipc	ra,0xfffff
    80001a2c:	b28080e7          	jalr	-1240(ra) # 80000550 <panic>
      panic("uvmcopy: page not present");
    80001a30:	00007517          	auipc	a0,0x7
    80001a34:	80050513          	addi	a0,a0,-2048 # 80008230 <digits+0x1f0>
    80001a38:	fffff097          	auipc	ra,0xfffff
    80001a3c:	b18080e7          	jalr	-1256(ra) # 80000550 <panic>
      kfree(mem);
    80001a40:	854a                	mv	a0,s2
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	fea080e7          	jalr	-22(ra) # 80000a2c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001a4a:	4685                	li	a3,1
    80001a4c:	00c9d613          	srli	a2,s3,0xc
    80001a50:	4581                	li	a1,0
    80001a52:	8556                	mv	a0,s5
    80001a54:	00000097          	auipc	ra,0x0
    80001a58:	c5a080e7          	jalr	-934(ra) # 800016ae <uvmunmap>
  return -1;
    80001a5c:	557d                	li	a0,-1
}
    80001a5e:	60a6                	ld	ra,72(sp)
    80001a60:	6406                	ld	s0,64(sp)
    80001a62:	74e2                	ld	s1,56(sp)
    80001a64:	7942                	ld	s2,48(sp)
    80001a66:	79a2                	ld	s3,40(sp)
    80001a68:	7a02                	ld	s4,32(sp)
    80001a6a:	6ae2                	ld	s5,24(sp)
    80001a6c:	6b42                	ld	s6,16(sp)
    80001a6e:	6ba2                	ld	s7,8(sp)
    80001a70:	6161                	addi	sp,sp,80
    80001a72:	8082                	ret
  return 0;
    80001a74:	4501                	li	a0,0
}
    80001a76:	8082                	ret

0000000080001a78 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001a78:	1141                	addi	sp,sp,-16
    80001a7a:	e406                	sd	ra,8(sp)
    80001a7c:	e022                	sd	s0,0(sp)
    80001a7e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001a80:	4601                	li	a2,0
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	99c080e7          	jalr	-1636(ra) # 8000141e <walk>
  if(pte == 0)
    80001a8a:	c901                	beqz	a0,80001a9a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001a8c:	611c                	ld	a5,0(a0)
    80001a8e:	9bbd                	andi	a5,a5,-17
    80001a90:	e11c                	sd	a5,0(a0)
}
    80001a92:	60a2                	ld	ra,8(sp)
    80001a94:	6402                	ld	s0,0(sp)
    80001a96:	0141                	addi	sp,sp,16
    80001a98:	8082                	ret
    panic("uvmclear");
    80001a9a:	00006517          	auipc	a0,0x6
    80001a9e:	7b650513          	addi	a0,a0,1974 # 80008250 <digits+0x210>
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	aae080e7          	jalr	-1362(ra) # 80000550 <panic>

0000000080001aaa <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001aaa:	c6bd                	beqz	a3,80001b18 <copyout+0x6e>
{
    80001aac:	715d                	addi	sp,sp,-80
    80001aae:	e486                	sd	ra,72(sp)
    80001ab0:	e0a2                	sd	s0,64(sp)
    80001ab2:	fc26                	sd	s1,56(sp)
    80001ab4:	f84a                	sd	s2,48(sp)
    80001ab6:	f44e                	sd	s3,40(sp)
    80001ab8:	f052                	sd	s4,32(sp)
    80001aba:	ec56                	sd	s5,24(sp)
    80001abc:	e85a                	sd	s6,16(sp)
    80001abe:	e45e                	sd	s7,8(sp)
    80001ac0:	e062                	sd	s8,0(sp)
    80001ac2:	0880                	addi	s0,sp,80
    80001ac4:	8b2a                	mv	s6,a0
    80001ac6:	8c2e                	mv	s8,a1
    80001ac8:	8a32                	mv	s4,a2
    80001aca:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001acc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001ace:	6a85                	lui	s5,0x1
    80001ad0:	a015                	j	80001af4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001ad2:	9562                	add	a0,a0,s8
    80001ad4:	0004861b          	sext.w	a2,s1
    80001ad8:	85d2                	mv	a1,s4
    80001ada:	41250533          	sub	a0,a0,s2
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	6d0080e7          	jalr	1744(ra) # 800011ae <memmove>

    len -= n;
    80001ae6:	409989b3          	sub	s3,s3,s1
    src += n;
    80001aea:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001aec:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001af0:	02098263          	beqz	s3,80001b14 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001af4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001af8:	85ca                	mv	a1,s2
    80001afa:	855a                	mv	a0,s6
    80001afc:	00000097          	auipc	ra,0x0
    80001b00:	9ec080e7          	jalr	-1556(ra) # 800014e8 <walkaddr>
    if(pa0 == 0)
    80001b04:	cd01                	beqz	a0,80001b1c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001b06:	418904b3          	sub	s1,s2,s8
    80001b0a:	94d6                	add	s1,s1,s5
    if(n > len)
    80001b0c:	fc99f3e3          	bgeu	s3,s1,80001ad2 <copyout+0x28>
    80001b10:	84ce                	mv	s1,s3
    80001b12:	b7c1                	j	80001ad2 <copyout+0x28>
  }
  return 0;
    80001b14:	4501                	li	a0,0
    80001b16:	a021                	j	80001b1e <copyout+0x74>
    80001b18:	4501                	li	a0,0
}
    80001b1a:	8082                	ret
      return -1;
    80001b1c:	557d                	li	a0,-1
}
    80001b1e:	60a6                	ld	ra,72(sp)
    80001b20:	6406                	ld	s0,64(sp)
    80001b22:	74e2                	ld	s1,56(sp)
    80001b24:	7942                	ld	s2,48(sp)
    80001b26:	79a2                	ld	s3,40(sp)
    80001b28:	7a02                	ld	s4,32(sp)
    80001b2a:	6ae2                	ld	s5,24(sp)
    80001b2c:	6b42                	ld	s6,16(sp)
    80001b2e:	6ba2                	ld	s7,8(sp)
    80001b30:	6c02                	ld	s8,0(sp)
    80001b32:	6161                	addi	sp,sp,80
    80001b34:	8082                	ret

0000000080001b36 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001b36:	c6bd                	beqz	a3,80001ba4 <copyin+0x6e>
{
    80001b38:	715d                	addi	sp,sp,-80
    80001b3a:	e486                	sd	ra,72(sp)
    80001b3c:	e0a2                	sd	s0,64(sp)
    80001b3e:	fc26                	sd	s1,56(sp)
    80001b40:	f84a                	sd	s2,48(sp)
    80001b42:	f44e                	sd	s3,40(sp)
    80001b44:	f052                	sd	s4,32(sp)
    80001b46:	ec56                	sd	s5,24(sp)
    80001b48:	e85a                	sd	s6,16(sp)
    80001b4a:	e45e                	sd	s7,8(sp)
    80001b4c:	e062                	sd	s8,0(sp)
    80001b4e:	0880                	addi	s0,sp,80
    80001b50:	8b2a                	mv	s6,a0
    80001b52:	8a2e                	mv	s4,a1
    80001b54:	8c32                	mv	s8,a2
    80001b56:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001b58:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001b5a:	6a85                	lui	s5,0x1
    80001b5c:	a015                	j	80001b80 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001b5e:	9562                	add	a0,a0,s8
    80001b60:	0004861b          	sext.w	a2,s1
    80001b64:	412505b3          	sub	a1,a0,s2
    80001b68:	8552                	mv	a0,s4
    80001b6a:	fffff097          	auipc	ra,0xfffff
    80001b6e:	644080e7          	jalr	1604(ra) # 800011ae <memmove>

    len -= n;
    80001b72:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001b76:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001b78:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001b7c:	02098263          	beqz	s3,80001ba0 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001b80:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001b84:	85ca                	mv	a1,s2
    80001b86:	855a                	mv	a0,s6
    80001b88:	00000097          	auipc	ra,0x0
    80001b8c:	960080e7          	jalr	-1696(ra) # 800014e8 <walkaddr>
    if(pa0 == 0)
    80001b90:	cd01                	beqz	a0,80001ba8 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001b92:	418904b3          	sub	s1,s2,s8
    80001b96:	94d6                	add	s1,s1,s5
    if(n > len)
    80001b98:	fc99f3e3          	bgeu	s3,s1,80001b5e <copyin+0x28>
    80001b9c:	84ce                	mv	s1,s3
    80001b9e:	b7c1                	j	80001b5e <copyin+0x28>
  }
  return 0;
    80001ba0:	4501                	li	a0,0
    80001ba2:	a021                	j	80001baa <copyin+0x74>
    80001ba4:	4501                	li	a0,0
}
    80001ba6:	8082                	ret
      return -1;
    80001ba8:	557d                	li	a0,-1
}
    80001baa:	60a6                	ld	ra,72(sp)
    80001bac:	6406                	ld	s0,64(sp)
    80001bae:	74e2                	ld	s1,56(sp)
    80001bb0:	7942                	ld	s2,48(sp)
    80001bb2:	79a2                	ld	s3,40(sp)
    80001bb4:	7a02                	ld	s4,32(sp)
    80001bb6:	6ae2                	ld	s5,24(sp)
    80001bb8:	6b42                	ld	s6,16(sp)
    80001bba:	6ba2                	ld	s7,8(sp)
    80001bbc:	6c02                	ld	s8,0(sp)
    80001bbe:	6161                	addi	sp,sp,80
    80001bc0:	8082                	ret

0000000080001bc2 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001bc2:	c6c5                	beqz	a3,80001c6a <copyinstr+0xa8>
{
    80001bc4:	715d                	addi	sp,sp,-80
    80001bc6:	e486                	sd	ra,72(sp)
    80001bc8:	e0a2                	sd	s0,64(sp)
    80001bca:	fc26                	sd	s1,56(sp)
    80001bcc:	f84a                	sd	s2,48(sp)
    80001bce:	f44e                	sd	s3,40(sp)
    80001bd0:	f052                	sd	s4,32(sp)
    80001bd2:	ec56                	sd	s5,24(sp)
    80001bd4:	e85a                	sd	s6,16(sp)
    80001bd6:	e45e                	sd	s7,8(sp)
    80001bd8:	0880                	addi	s0,sp,80
    80001bda:	8a2a                	mv	s4,a0
    80001bdc:	8b2e                	mv	s6,a1
    80001bde:	8bb2                	mv	s7,a2
    80001be0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001be2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001be4:	6985                	lui	s3,0x1
    80001be6:	a035                	j	80001c12 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001be8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001bec:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001bee:	0017b793          	seqz	a5,a5
    80001bf2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001bf6:	60a6                	ld	ra,72(sp)
    80001bf8:	6406                	ld	s0,64(sp)
    80001bfa:	74e2                	ld	s1,56(sp)
    80001bfc:	7942                	ld	s2,48(sp)
    80001bfe:	79a2                	ld	s3,40(sp)
    80001c00:	7a02                	ld	s4,32(sp)
    80001c02:	6ae2                	ld	s5,24(sp)
    80001c04:	6b42                	ld	s6,16(sp)
    80001c06:	6ba2                	ld	s7,8(sp)
    80001c08:	6161                	addi	sp,sp,80
    80001c0a:	8082                	ret
    srcva = va0 + PGSIZE;
    80001c0c:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001c10:	c8a9                	beqz	s1,80001c62 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001c12:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001c16:	85ca                	mv	a1,s2
    80001c18:	8552                	mv	a0,s4
    80001c1a:	00000097          	auipc	ra,0x0
    80001c1e:	8ce080e7          	jalr	-1842(ra) # 800014e8 <walkaddr>
    if(pa0 == 0)
    80001c22:	c131                	beqz	a0,80001c66 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001c24:	41790833          	sub	a6,s2,s7
    80001c28:	984e                	add	a6,a6,s3
    if(n > max)
    80001c2a:	0104f363          	bgeu	s1,a6,80001c30 <copyinstr+0x6e>
    80001c2e:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001c30:	955e                	add	a0,a0,s7
    80001c32:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001c36:	fc080be3          	beqz	a6,80001c0c <copyinstr+0x4a>
    80001c3a:	985a                	add	a6,a6,s6
    80001c3c:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001c3e:	41650633          	sub	a2,a0,s6
    80001c42:	14fd                	addi	s1,s1,-1
    80001c44:	9b26                	add	s6,s6,s1
    80001c46:	00f60733          	add	a4,a2,a5
    80001c4a:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd3fd8>
    80001c4e:	df49                	beqz	a4,80001be8 <copyinstr+0x26>
        *dst = *p;
    80001c50:	00e78023          	sb	a4,0(a5)
      --max;
    80001c54:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001c58:	0785                	addi	a5,a5,1
    while(n > 0){
    80001c5a:	ff0796e3          	bne	a5,a6,80001c46 <copyinstr+0x84>
      dst++;
    80001c5e:	8b42                	mv	s6,a6
    80001c60:	b775                	j	80001c0c <copyinstr+0x4a>
    80001c62:	4781                	li	a5,0
    80001c64:	b769                	j	80001bee <copyinstr+0x2c>
      return -1;
    80001c66:	557d                	li	a0,-1
    80001c68:	b779                	j	80001bf6 <copyinstr+0x34>
  int got_null = 0;
    80001c6a:	4781                	li	a5,0
  if(got_null){
    80001c6c:	0017b793          	seqz	a5,a5
    80001c70:	40f00533          	neg	a0,a5
}
    80001c74:	8082                	ret

0000000080001c76 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001c76:	1101                	addi	sp,sp,-32
    80001c78:	ec06                	sd	ra,24(sp)
    80001c7a:	e822                	sd	s0,16(sp)
    80001c7c:	e426                	sd	s1,8(sp)
    80001c7e:	1000                	addi	s0,sp,32
    80001c80:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	072080e7          	jalr	114(ra) # 80000cf4 <holding>
    80001c8a:	c909                	beqz	a0,80001c9c <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001c8c:	789c                	ld	a5,48(s1)
    80001c8e:	00978f63          	beq	a5,s1,80001cac <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001c92:	60e2                	ld	ra,24(sp)
    80001c94:	6442                	ld	s0,16(sp)
    80001c96:	64a2                	ld	s1,8(sp)
    80001c98:	6105                	addi	sp,sp,32
    80001c9a:	8082                	ret
    panic("wakeup1");
    80001c9c:	00006517          	auipc	a0,0x6
    80001ca0:	5c450513          	addi	a0,a0,1476 # 80008260 <digits+0x220>
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	8ac080e7          	jalr	-1876(ra) # 80000550 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001cac:	5098                	lw	a4,32(s1)
    80001cae:	4785                	li	a5,1
    80001cb0:	fef711e3          	bne	a4,a5,80001c92 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001cb4:	4789                	li	a5,2
    80001cb6:	d09c                	sw	a5,32(s1)
}
    80001cb8:	bfe9                	j	80001c92 <wakeup1+0x1c>

0000000080001cba <procinit>:
{
    80001cba:	715d                	addi	sp,sp,-80
    80001cbc:	e486                	sd	ra,72(sp)
    80001cbe:	e0a2                	sd	s0,64(sp)
    80001cc0:	fc26                	sd	s1,56(sp)
    80001cc2:	f84a                	sd	s2,48(sp)
    80001cc4:	f44e                	sd	s3,40(sp)
    80001cc6:	f052                	sd	s4,32(sp)
    80001cc8:	ec56                	sd	s5,24(sp)
    80001cca:	e85a                	sd	s6,16(sp)
    80001ccc:	e45e                	sd	s7,8(sp)
    80001cce:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001cd0:	00006597          	auipc	a1,0x6
    80001cd4:	59858593          	addi	a1,a1,1432 # 80008268 <digits+0x228>
    80001cd8:	00010517          	auipc	a0,0x10
    80001cdc:	6f050513          	addi	a0,a0,1776 # 800123c8 <pid_lock>
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	20a080e7          	jalr	522(ra) # 80000eea <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ce8:	00011917          	auipc	s2,0x11
    80001cec:	b0090913          	addi	s2,s2,-1280 # 800127e8 <proc>
      initlock(&p->lock, "proc");
    80001cf0:	00006b97          	auipc	s7,0x6
    80001cf4:	580b8b93          	addi	s7,s7,1408 # 80008270 <digits+0x230>
      uint64 va = KSTACK((int) (p - proc));
    80001cf8:	8b4a                	mv	s6,s2
    80001cfa:	00006a97          	auipc	s5,0x6
    80001cfe:	306a8a93          	addi	s5,s5,774 # 80008000 <etext>
    80001d02:	040009b7          	lui	s3,0x4000
    80001d06:	19fd                	addi	s3,s3,-1
    80001d08:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d0a:	00016a17          	auipc	s4,0x16
    80001d0e:	6dea0a13          	addi	s4,s4,1758 # 800183e8 <tickslock>
      initlock(&p->lock, "proc");
    80001d12:	85de                	mv	a1,s7
    80001d14:	854a                	mv	a0,s2
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	1d4080e7          	jalr	468(ra) # 80000eea <initlock>
      char *pa = kalloc();
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	e74080e7          	jalr	-396(ra) # 80000b92 <kalloc>
    80001d26:	85aa                	mv	a1,a0
      if(pa == 0)
    80001d28:	c929                	beqz	a0,80001d7a <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001d2a:	416904b3          	sub	s1,s2,s6
    80001d2e:	8491                	srai	s1,s1,0x4
    80001d30:	000ab783          	ld	a5,0(s5)
    80001d34:	02f484b3          	mul	s1,s1,a5
    80001d38:	2485                	addiw	s1,s1,1
    80001d3a:	00d4949b          	slliw	s1,s1,0xd
    80001d3e:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001d42:	4699                	li	a3,6
    80001d44:	6605                	lui	a2,0x1
    80001d46:	8526                	mv	a0,s1
    80001d48:	00000097          	auipc	ra,0x0
    80001d4c:	870080e7          	jalr	-1936(ra) # 800015b8 <kvmmap>
      p->kstack = va;
    80001d50:	04993423          	sd	s1,72(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d54:	17090913          	addi	s2,s2,368
    80001d58:	fb491de3          	bne	s2,s4,80001d12 <procinit+0x58>
  kvminithart();
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	768080e7          	jalr	1896(ra) # 800014c4 <kvminithart>
}
    80001d64:	60a6                	ld	ra,72(sp)
    80001d66:	6406                	ld	s0,64(sp)
    80001d68:	74e2                	ld	s1,56(sp)
    80001d6a:	7942                	ld	s2,48(sp)
    80001d6c:	79a2                	ld	s3,40(sp)
    80001d6e:	7a02                	ld	s4,32(sp)
    80001d70:	6ae2                	ld	s5,24(sp)
    80001d72:	6b42                	ld	s6,16(sp)
    80001d74:	6ba2                	ld	s7,8(sp)
    80001d76:	6161                	addi	sp,sp,80
    80001d78:	8082                	ret
        panic("kalloc");
    80001d7a:	00006517          	auipc	a0,0x6
    80001d7e:	4fe50513          	addi	a0,a0,1278 # 80008278 <digits+0x238>
    80001d82:	ffffe097          	auipc	ra,0xffffe
    80001d86:	7ce080e7          	jalr	1998(ra) # 80000550 <panic>

0000000080001d8a <cpuid>:
{
    80001d8a:	1141                	addi	sp,sp,-16
    80001d8c:	e422                	sd	s0,8(sp)
    80001d8e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d90:	8512                	mv	a0,tp
}
    80001d92:	2501                	sext.w	a0,a0
    80001d94:	6422                	ld	s0,8(sp)
    80001d96:	0141                	addi	sp,sp,16
    80001d98:	8082                	ret

0000000080001d9a <mycpu>:
mycpu(void) {
    80001d9a:	1141                	addi	sp,sp,-16
    80001d9c:	e422                	sd	s0,8(sp)
    80001d9e:	0800                	addi	s0,sp,16
    80001da0:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001da2:	2781                	sext.w	a5,a5
    80001da4:	079e                	slli	a5,a5,0x7
}
    80001da6:	00010517          	auipc	a0,0x10
    80001daa:	64250513          	addi	a0,a0,1602 # 800123e8 <cpus>
    80001dae:	953e                	add	a0,a0,a5
    80001db0:	6422                	ld	s0,8(sp)
    80001db2:	0141                	addi	sp,sp,16
    80001db4:	8082                	ret

0000000080001db6 <myproc>:
myproc(void) {
    80001db6:	1101                	addi	sp,sp,-32
    80001db8:	ec06                	sd	ra,24(sp)
    80001dba:	e822                	sd	s0,16(sp)
    80001dbc:	e426                	sd	s1,8(sp)
    80001dbe:	1000                	addi	s0,sp,32
  push_off();
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	f62080e7          	jalr	-158(ra) # 80000d22 <push_off>
    80001dc8:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001dca:	2781                	sext.w	a5,a5
    80001dcc:	079e                	slli	a5,a5,0x7
    80001dce:	00010717          	auipc	a4,0x10
    80001dd2:	5fa70713          	addi	a4,a4,1530 # 800123c8 <pid_lock>
    80001dd6:	97ba                	add	a5,a5,a4
    80001dd8:	7384                	ld	s1,32(a5)
  pop_off();
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	004080e7          	jalr	4(ra) # 80000dde <pop_off>
}
    80001de2:	8526                	mv	a0,s1
    80001de4:	60e2                	ld	ra,24(sp)
    80001de6:	6442                	ld	s0,16(sp)
    80001de8:	64a2                	ld	s1,8(sp)
    80001dea:	6105                	addi	sp,sp,32
    80001dec:	8082                	ret

0000000080001dee <forkret>:
{
    80001dee:	1141                	addi	sp,sp,-16
    80001df0:	e406                	sd	ra,8(sp)
    80001df2:	e022                	sd	s0,0(sp)
    80001df4:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001df6:	00000097          	auipc	ra,0x0
    80001dfa:	fc0080e7          	jalr	-64(ra) # 80001db6 <myproc>
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	040080e7          	jalr	64(ra) # 80000e3e <release>
  if (first) {
    80001e06:	00007797          	auipc	a5,0x7
    80001e0a:	aca7a783          	lw	a5,-1334(a5) # 800088d0 <first.1672>
    80001e0e:	eb89                	bnez	a5,80001e20 <forkret+0x32>
  usertrapret();
    80001e10:	00001097          	auipc	ra,0x1
    80001e14:	c1c080e7          	jalr	-996(ra) # 80002a2c <usertrapret>
}
    80001e18:	60a2                	ld	ra,8(sp)
    80001e1a:	6402                	ld	s0,0(sp)
    80001e1c:	0141                	addi	sp,sp,16
    80001e1e:	8082                	ret
    first = 0;
    80001e20:	00007797          	auipc	a5,0x7
    80001e24:	aa07a823          	sw	zero,-1360(a5) # 800088d0 <first.1672>
    fsinit(ROOTDEV);
    80001e28:	4505                	li	a0,1
    80001e2a:	00002097          	auipc	ra,0x2
    80001e2e:	b88080e7          	jalr	-1144(ra) # 800039b2 <fsinit>
    80001e32:	bff9                	j	80001e10 <forkret+0x22>

0000000080001e34 <allocpid>:
allocpid() {
    80001e34:	1101                	addi	sp,sp,-32
    80001e36:	ec06                	sd	ra,24(sp)
    80001e38:	e822                	sd	s0,16(sp)
    80001e3a:	e426                	sd	s1,8(sp)
    80001e3c:	e04a                	sd	s2,0(sp)
    80001e3e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001e40:	00010917          	auipc	s2,0x10
    80001e44:	58890913          	addi	s2,s2,1416 # 800123c8 <pid_lock>
    80001e48:	854a                	mv	a0,s2
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	f24080e7          	jalr	-220(ra) # 80000d6e <acquire>
  pid = nextpid;
    80001e52:	00007797          	auipc	a5,0x7
    80001e56:	a8278793          	addi	a5,a5,-1406 # 800088d4 <nextpid>
    80001e5a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001e5c:	0014871b          	addiw	a4,s1,1
    80001e60:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001e62:	854a                	mv	a0,s2
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	fda080e7          	jalr	-38(ra) # 80000e3e <release>
}
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	60e2                	ld	ra,24(sp)
    80001e70:	6442                	ld	s0,16(sp)
    80001e72:	64a2                	ld	s1,8(sp)
    80001e74:	6902                	ld	s2,0(sp)
    80001e76:	6105                	addi	sp,sp,32
    80001e78:	8082                	ret

0000000080001e7a <proc_pagetable>:
{
    80001e7a:	1101                	addi	sp,sp,-32
    80001e7c:	ec06                	sd	ra,24(sp)
    80001e7e:	e822                	sd	s0,16(sp)
    80001e80:	e426                	sd	s1,8(sp)
    80001e82:	e04a                	sd	s2,0(sp)
    80001e84:	1000                	addi	s0,sp,32
    80001e86:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e88:	00000097          	auipc	ra,0x0
    80001e8c:	8ea080e7          	jalr	-1814(ra) # 80001772 <uvmcreate>
    80001e90:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001e92:	c121                	beqz	a0,80001ed2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e94:	4729                	li	a4,10
    80001e96:	00005697          	auipc	a3,0x5
    80001e9a:	16a68693          	addi	a3,a3,362 # 80007000 <_trampoline>
    80001e9e:	6605                	lui	a2,0x1
    80001ea0:	040005b7          	lui	a1,0x4000
    80001ea4:	15fd                	addi	a1,a1,-1
    80001ea6:	05b2                	slli	a1,a1,0xc
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	682080e7          	jalr	1666(ra) # 8000152a <mappages>
    80001eb0:	02054863          	bltz	a0,80001ee0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001eb4:	4719                	li	a4,6
    80001eb6:	06093683          	ld	a3,96(s2)
    80001eba:	6605                	lui	a2,0x1
    80001ebc:	020005b7          	lui	a1,0x2000
    80001ec0:	15fd                	addi	a1,a1,-1
    80001ec2:	05b6                	slli	a1,a1,0xd
    80001ec4:	8526                	mv	a0,s1
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	664080e7          	jalr	1636(ra) # 8000152a <mappages>
    80001ece:	02054163          	bltz	a0,80001ef0 <proc_pagetable+0x76>
}
    80001ed2:	8526                	mv	a0,s1
    80001ed4:	60e2                	ld	ra,24(sp)
    80001ed6:	6442                	ld	s0,16(sp)
    80001ed8:	64a2                	ld	s1,8(sp)
    80001eda:	6902                	ld	s2,0(sp)
    80001edc:	6105                	addi	sp,sp,32
    80001ede:	8082                	ret
    uvmfree(pagetable, 0);
    80001ee0:	4581                	li	a1,0
    80001ee2:	8526                	mv	a0,s1
    80001ee4:	00000097          	auipc	ra,0x0
    80001ee8:	a8a080e7          	jalr	-1398(ra) # 8000196e <uvmfree>
    return 0;
    80001eec:	4481                	li	s1,0
    80001eee:	b7d5                	j	80001ed2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ef0:	4681                	li	a3,0
    80001ef2:	4605                	li	a2,1
    80001ef4:	040005b7          	lui	a1,0x4000
    80001ef8:	15fd                	addi	a1,a1,-1
    80001efa:	05b2                	slli	a1,a1,0xc
    80001efc:	8526                	mv	a0,s1
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	7b0080e7          	jalr	1968(ra) # 800016ae <uvmunmap>
    uvmfree(pagetable, 0);
    80001f06:	4581                	li	a1,0
    80001f08:	8526                	mv	a0,s1
    80001f0a:	00000097          	auipc	ra,0x0
    80001f0e:	a64080e7          	jalr	-1436(ra) # 8000196e <uvmfree>
    return 0;
    80001f12:	4481                	li	s1,0
    80001f14:	bf7d                	j	80001ed2 <proc_pagetable+0x58>

0000000080001f16 <proc_freepagetable>:
{
    80001f16:	1101                	addi	sp,sp,-32
    80001f18:	ec06                	sd	ra,24(sp)
    80001f1a:	e822                	sd	s0,16(sp)
    80001f1c:	e426                	sd	s1,8(sp)
    80001f1e:	e04a                	sd	s2,0(sp)
    80001f20:	1000                	addi	s0,sp,32
    80001f22:	84aa                	mv	s1,a0
    80001f24:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f26:	4681                	li	a3,0
    80001f28:	4605                	li	a2,1
    80001f2a:	040005b7          	lui	a1,0x4000
    80001f2e:	15fd                	addi	a1,a1,-1
    80001f30:	05b2                	slli	a1,a1,0xc
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	77c080e7          	jalr	1916(ra) # 800016ae <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001f3a:	4681                	li	a3,0
    80001f3c:	4605                	li	a2,1
    80001f3e:	020005b7          	lui	a1,0x2000
    80001f42:	15fd                	addi	a1,a1,-1
    80001f44:	05b6                	slli	a1,a1,0xd
    80001f46:	8526                	mv	a0,s1
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	766080e7          	jalr	1894(ra) # 800016ae <uvmunmap>
  uvmfree(pagetable, sz);
    80001f50:	85ca                	mv	a1,s2
    80001f52:	8526                	mv	a0,s1
    80001f54:	00000097          	auipc	ra,0x0
    80001f58:	a1a080e7          	jalr	-1510(ra) # 8000196e <uvmfree>
}
    80001f5c:	60e2                	ld	ra,24(sp)
    80001f5e:	6442                	ld	s0,16(sp)
    80001f60:	64a2                	ld	s1,8(sp)
    80001f62:	6902                	ld	s2,0(sp)
    80001f64:	6105                	addi	sp,sp,32
    80001f66:	8082                	ret

0000000080001f68 <freeproc>:
{
    80001f68:	1101                	addi	sp,sp,-32
    80001f6a:	ec06                	sd	ra,24(sp)
    80001f6c:	e822                	sd	s0,16(sp)
    80001f6e:	e426                	sd	s1,8(sp)
    80001f70:	1000                	addi	s0,sp,32
    80001f72:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001f74:	7128                	ld	a0,96(a0)
    80001f76:	c509                	beqz	a0,80001f80 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	ab4080e7          	jalr	-1356(ra) # 80000a2c <kfree>
  p->trapframe = 0;
    80001f80:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001f84:	6ca8                	ld	a0,88(s1)
    80001f86:	c511                	beqz	a0,80001f92 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f88:	68ac                	ld	a1,80(s1)
    80001f8a:	00000097          	auipc	ra,0x0
    80001f8e:	f8c080e7          	jalr	-116(ra) # 80001f16 <proc_freepagetable>
  p->pagetable = 0;
    80001f92:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001f96:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001f9a:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80001f9e:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80001fa2:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001fa6:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001faa:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80001fae:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80001fb2:	0204a023          	sw	zero,32(s1)
}
    80001fb6:	60e2                	ld	ra,24(sp)
    80001fb8:	6442                	ld	s0,16(sp)
    80001fba:	64a2                	ld	s1,8(sp)
    80001fbc:	6105                	addi	sp,sp,32
    80001fbe:	8082                	ret

0000000080001fc0 <allocproc>:
{
    80001fc0:	1101                	addi	sp,sp,-32
    80001fc2:	ec06                	sd	ra,24(sp)
    80001fc4:	e822                	sd	s0,16(sp)
    80001fc6:	e426                	sd	s1,8(sp)
    80001fc8:	e04a                	sd	s2,0(sp)
    80001fca:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fcc:	00011497          	auipc	s1,0x11
    80001fd0:	81c48493          	addi	s1,s1,-2020 # 800127e8 <proc>
    80001fd4:	00016917          	auipc	s2,0x16
    80001fd8:	41490913          	addi	s2,s2,1044 # 800183e8 <tickslock>
    acquire(&p->lock);
    80001fdc:	8526                	mv	a0,s1
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	d90080e7          	jalr	-624(ra) # 80000d6e <acquire>
    if(p->state == UNUSED) {
    80001fe6:	509c                	lw	a5,32(s1)
    80001fe8:	cf81                	beqz	a5,80002000 <allocproc+0x40>
      release(&p->lock);
    80001fea:	8526                	mv	a0,s1
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	e52080e7          	jalr	-430(ra) # 80000e3e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ff4:	17048493          	addi	s1,s1,368
    80001ff8:	ff2492e3          	bne	s1,s2,80001fdc <allocproc+0x1c>
  return 0;
    80001ffc:	4481                	li	s1,0
    80001ffe:	a0b9                	j	8000204c <allocproc+0x8c>
  p->pid = allocpid();
    80002000:	00000097          	auipc	ra,0x0
    80002004:	e34080e7          	jalr	-460(ra) # 80001e34 <allocpid>
    80002008:	c0a8                	sw	a0,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    8000200a:	fffff097          	auipc	ra,0xfffff
    8000200e:	b88080e7          	jalr	-1144(ra) # 80000b92 <kalloc>
    80002012:	892a                	mv	s2,a0
    80002014:	f0a8                	sd	a0,96(s1)
    80002016:	c131                	beqz	a0,8000205a <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80002018:	8526                	mv	a0,s1
    8000201a:	00000097          	auipc	ra,0x0
    8000201e:	e60080e7          	jalr	-416(ra) # 80001e7a <proc_pagetable>
    80002022:	892a                	mv	s2,a0
    80002024:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80002026:	c129                	beqz	a0,80002068 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80002028:	07000613          	li	a2,112
    8000202c:	4581                	li	a1,0
    8000202e:	06848513          	addi	a0,s1,104
    80002032:	fffff097          	auipc	ra,0xfffff
    80002036:	11c080e7          	jalr	284(ra) # 8000114e <memset>
  p->context.ra = (uint64)forkret;
    8000203a:	00000797          	auipc	a5,0x0
    8000203e:	db478793          	addi	a5,a5,-588 # 80001dee <forkret>
    80002042:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002044:	64bc                	ld	a5,72(s1)
    80002046:	6705                	lui	a4,0x1
    80002048:	97ba                	add	a5,a5,a4
    8000204a:	f8bc                	sd	a5,112(s1)
}
    8000204c:	8526                	mv	a0,s1
    8000204e:	60e2                	ld	ra,24(sp)
    80002050:	6442                	ld	s0,16(sp)
    80002052:	64a2                	ld	s1,8(sp)
    80002054:	6902                	ld	s2,0(sp)
    80002056:	6105                	addi	sp,sp,32
    80002058:	8082                	ret
    release(&p->lock);
    8000205a:	8526                	mv	a0,s1
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	de2080e7          	jalr	-542(ra) # 80000e3e <release>
    return 0;
    80002064:	84ca                	mv	s1,s2
    80002066:	b7dd                	j	8000204c <allocproc+0x8c>
    freeproc(p);
    80002068:	8526                	mv	a0,s1
    8000206a:	00000097          	auipc	ra,0x0
    8000206e:	efe080e7          	jalr	-258(ra) # 80001f68 <freeproc>
    release(&p->lock);
    80002072:	8526                	mv	a0,s1
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	dca080e7          	jalr	-566(ra) # 80000e3e <release>
    return 0;
    8000207c:	84ca                	mv	s1,s2
    8000207e:	b7f9                	j	8000204c <allocproc+0x8c>

0000000080002080 <userinit>:
{
    80002080:	1101                	addi	sp,sp,-32
    80002082:	ec06                	sd	ra,24(sp)
    80002084:	e822                	sd	s0,16(sp)
    80002086:	e426                	sd	s1,8(sp)
    80002088:	1000                	addi	s0,sp,32
  p = allocproc();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	f36080e7          	jalr	-202(ra) # 80001fc0 <allocproc>
    80002092:	84aa                	mv	s1,a0
  initproc = p;
    80002094:	00007797          	auipc	a5,0x7
    80002098:	f8a7b223          	sd	a0,-124(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000209c:	03400613          	li	a2,52
    800020a0:	00007597          	auipc	a1,0x7
    800020a4:	84058593          	addi	a1,a1,-1984 # 800088e0 <initcode>
    800020a8:	6d28                	ld	a0,88(a0)
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	6f6080e7          	jalr	1782(ra) # 800017a0 <uvminit>
  p->sz = PGSIZE;
    800020b2:	6785                	lui	a5,0x1
    800020b4:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    800020b6:	70b8                	ld	a4,96(s1)
    800020b8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800020bc:	70b8                	ld	a4,96(s1)
    800020be:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800020c0:	4641                	li	a2,16
    800020c2:	00006597          	auipc	a1,0x6
    800020c6:	1be58593          	addi	a1,a1,446 # 80008280 <digits+0x240>
    800020ca:	16048513          	addi	a0,s1,352
    800020ce:	fffff097          	auipc	ra,0xfffff
    800020d2:	1d6080e7          	jalr	470(ra) # 800012a4 <safestrcpy>
  p->cwd = namei("/");
    800020d6:	00006517          	auipc	a0,0x6
    800020da:	1ba50513          	addi	a0,a0,442 # 80008290 <digits+0x250>
    800020de:	00002097          	auipc	ra,0x2
    800020e2:	300080e7          	jalr	768(ra) # 800043de <namei>
    800020e6:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    800020ea:	4789                	li	a5,2
    800020ec:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    800020ee:	8526                	mv	a0,s1
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	d4e080e7          	jalr	-690(ra) # 80000e3e <release>
}
    800020f8:	60e2                	ld	ra,24(sp)
    800020fa:	6442                	ld	s0,16(sp)
    800020fc:	64a2                	ld	s1,8(sp)
    800020fe:	6105                	addi	sp,sp,32
    80002100:	8082                	ret

0000000080002102 <growproc>:
{
    80002102:	1101                	addi	sp,sp,-32
    80002104:	ec06                	sd	ra,24(sp)
    80002106:	e822                	sd	s0,16(sp)
    80002108:	e426                	sd	s1,8(sp)
    8000210a:	e04a                	sd	s2,0(sp)
    8000210c:	1000                	addi	s0,sp,32
    8000210e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002110:	00000097          	auipc	ra,0x0
    80002114:	ca6080e7          	jalr	-858(ra) # 80001db6 <myproc>
    80002118:	892a                	mv	s2,a0
  sz = p->sz;
    8000211a:	692c                	ld	a1,80(a0)
    8000211c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002120:	00904f63          	bgtz	s1,8000213e <growproc+0x3c>
  } else if(n < 0){
    80002124:	0204cc63          	bltz	s1,8000215c <growproc+0x5a>
  p->sz = sz;
    80002128:	1602                	slli	a2,a2,0x20
    8000212a:	9201                	srli	a2,a2,0x20
    8000212c:	04c93823          	sd	a2,80(s2)
  return 0;
    80002130:	4501                	li	a0,0
}
    80002132:	60e2                	ld	ra,24(sp)
    80002134:	6442                	ld	s0,16(sp)
    80002136:	64a2                	ld	s1,8(sp)
    80002138:	6902                	ld	s2,0(sp)
    8000213a:	6105                	addi	sp,sp,32
    8000213c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000213e:	9e25                	addw	a2,a2,s1
    80002140:	1602                	slli	a2,a2,0x20
    80002142:	9201                	srli	a2,a2,0x20
    80002144:	1582                	slli	a1,a1,0x20
    80002146:	9181                	srli	a1,a1,0x20
    80002148:	6d28                	ld	a0,88(a0)
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	710080e7          	jalr	1808(ra) # 8000185a <uvmalloc>
    80002152:	0005061b          	sext.w	a2,a0
    80002156:	fa69                	bnez	a2,80002128 <growproc+0x26>
      return -1;
    80002158:	557d                	li	a0,-1
    8000215a:	bfe1                	j	80002132 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000215c:	9e25                	addw	a2,a2,s1
    8000215e:	1602                	slli	a2,a2,0x20
    80002160:	9201                	srli	a2,a2,0x20
    80002162:	1582                	slli	a1,a1,0x20
    80002164:	9181                	srli	a1,a1,0x20
    80002166:	6d28                	ld	a0,88(a0)
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	6aa080e7          	jalr	1706(ra) # 80001812 <uvmdealloc>
    80002170:	0005061b          	sext.w	a2,a0
    80002174:	bf55                	j	80002128 <growproc+0x26>

0000000080002176 <fork>:
{
    80002176:	7179                	addi	sp,sp,-48
    80002178:	f406                	sd	ra,40(sp)
    8000217a:	f022                	sd	s0,32(sp)
    8000217c:	ec26                	sd	s1,24(sp)
    8000217e:	e84a                	sd	s2,16(sp)
    80002180:	e44e                	sd	s3,8(sp)
    80002182:	e052                	sd	s4,0(sp)
    80002184:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002186:	00000097          	auipc	ra,0x0
    8000218a:	c30080e7          	jalr	-976(ra) # 80001db6 <myproc>
    8000218e:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002190:	00000097          	auipc	ra,0x0
    80002194:	e30080e7          	jalr	-464(ra) # 80001fc0 <allocproc>
    80002198:	c175                	beqz	a0,8000227c <fork+0x106>
    8000219a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000219c:	05093603          	ld	a2,80(s2)
    800021a0:	6d2c                	ld	a1,88(a0)
    800021a2:	05893503          	ld	a0,88(s2)
    800021a6:	00000097          	auipc	ra,0x0
    800021aa:	800080e7          	jalr	-2048(ra) # 800019a6 <uvmcopy>
    800021ae:	04054863          	bltz	a0,800021fe <fork+0x88>
  np->sz = p->sz;
    800021b2:	05093783          	ld	a5,80(s2)
    800021b6:	04f9b823          	sd	a5,80(s3) # 4000050 <_entry-0x7bffffb0>
  np->parent = p;
    800021ba:	0329b423          	sd	s2,40(s3)
  *(np->trapframe) = *(p->trapframe);
    800021be:	06093683          	ld	a3,96(s2)
    800021c2:	87b6                	mv	a5,a3
    800021c4:	0609b703          	ld	a4,96(s3)
    800021c8:	12068693          	addi	a3,a3,288
    800021cc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800021d0:	6788                	ld	a0,8(a5)
    800021d2:	6b8c                	ld	a1,16(a5)
    800021d4:	6f90                	ld	a2,24(a5)
    800021d6:	01073023          	sd	a6,0(a4)
    800021da:	e708                	sd	a0,8(a4)
    800021dc:	eb0c                	sd	a1,16(a4)
    800021de:	ef10                	sd	a2,24(a4)
    800021e0:	02078793          	addi	a5,a5,32
    800021e4:	02070713          	addi	a4,a4,32
    800021e8:	fed792e3          	bne	a5,a3,800021cc <fork+0x56>
  np->trapframe->a0 = 0;
    800021ec:	0609b783          	ld	a5,96(s3)
    800021f0:	0607b823          	sd	zero,112(a5)
    800021f4:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    800021f8:	15800a13          	li	s4,344
    800021fc:	a03d                	j	8000222a <fork+0xb4>
    freeproc(np);
    800021fe:	854e                	mv	a0,s3
    80002200:	00000097          	auipc	ra,0x0
    80002204:	d68080e7          	jalr	-664(ra) # 80001f68 <freeproc>
    release(&np->lock);
    80002208:	854e                	mv	a0,s3
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	c34080e7          	jalr	-972(ra) # 80000e3e <release>
    return -1;
    80002212:	54fd                	li	s1,-1
    80002214:	a899                	j	8000226a <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002216:	00003097          	auipc	ra,0x3
    8000221a:	866080e7          	jalr	-1946(ra) # 80004a7c <filedup>
    8000221e:	009987b3          	add	a5,s3,s1
    80002222:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002224:	04a1                	addi	s1,s1,8
    80002226:	01448763          	beq	s1,s4,80002234 <fork+0xbe>
    if(p->ofile[i])
    8000222a:	009907b3          	add	a5,s2,s1
    8000222e:	6388                	ld	a0,0(a5)
    80002230:	f17d                	bnez	a0,80002216 <fork+0xa0>
    80002232:	bfcd                	j	80002224 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002234:	15893503          	ld	a0,344(s2)
    80002238:	00002097          	auipc	ra,0x2
    8000223c:	9b4080e7          	jalr	-1612(ra) # 80003bec <idup>
    80002240:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002244:	4641                	li	a2,16
    80002246:	16090593          	addi	a1,s2,352
    8000224a:	16098513          	addi	a0,s3,352
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	056080e7          	jalr	86(ra) # 800012a4 <safestrcpy>
  pid = np->pid;
    80002256:	0409a483          	lw	s1,64(s3)
  np->state = RUNNABLE;
    8000225a:	4789                	li	a5,2
    8000225c:	02f9a023          	sw	a5,32(s3)
  release(&np->lock);
    80002260:	854e                	mv	a0,s3
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	bdc080e7          	jalr	-1060(ra) # 80000e3e <release>
}
    8000226a:	8526                	mv	a0,s1
    8000226c:	70a2                	ld	ra,40(sp)
    8000226e:	7402                	ld	s0,32(sp)
    80002270:	64e2                	ld	s1,24(sp)
    80002272:	6942                	ld	s2,16(sp)
    80002274:	69a2                	ld	s3,8(sp)
    80002276:	6a02                	ld	s4,0(sp)
    80002278:	6145                	addi	sp,sp,48
    8000227a:	8082                	ret
    return -1;
    8000227c:	54fd                	li	s1,-1
    8000227e:	b7f5                	j	8000226a <fork+0xf4>

0000000080002280 <reparent>:
{
    80002280:	7179                	addi	sp,sp,-48
    80002282:	f406                	sd	ra,40(sp)
    80002284:	f022                	sd	s0,32(sp)
    80002286:	ec26                	sd	s1,24(sp)
    80002288:	e84a                	sd	s2,16(sp)
    8000228a:	e44e                	sd	s3,8(sp)
    8000228c:	e052                	sd	s4,0(sp)
    8000228e:	1800                	addi	s0,sp,48
    80002290:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002292:	00010497          	auipc	s1,0x10
    80002296:	55648493          	addi	s1,s1,1366 # 800127e8 <proc>
      pp->parent = initproc;
    8000229a:	00007a17          	auipc	s4,0x7
    8000229e:	d7ea0a13          	addi	s4,s4,-642 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022a2:	00016997          	auipc	s3,0x16
    800022a6:	14698993          	addi	s3,s3,326 # 800183e8 <tickslock>
    800022aa:	a029                	j	800022b4 <reparent+0x34>
    800022ac:	17048493          	addi	s1,s1,368
    800022b0:	03348363          	beq	s1,s3,800022d6 <reparent+0x56>
    if(pp->parent == p){
    800022b4:	749c                	ld	a5,40(s1)
    800022b6:	ff279be3          	bne	a5,s2,800022ac <reparent+0x2c>
      acquire(&pp->lock);
    800022ba:	8526                	mv	a0,s1
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	ab2080e7          	jalr	-1358(ra) # 80000d6e <acquire>
      pp->parent = initproc;
    800022c4:	000a3783          	ld	a5,0(s4)
    800022c8:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    800022ca:	8526                	mv	a0,s1
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	b72080e7          	jalr	-1166(ra) # 80000e3e <release>
    800022d4:	bfe1                	j	800022ac <reparent+0x2c>
}
    800022d6:	70a2                	ld	ra,40(sp)
    800022d8:	7402                	ld	s0,32(sp)
    800022da:	64e2                	ld	s1,24(sp)
    800022dc:	6942                	ld	s2,16(sp)
    800022de:	69a2                	ld	s3,8(sp)
    800022e0:	6a02                	ld	s4,0(sp)
    800022e2:	6145                	addi	sp,sp,48
    800022e4:	8082                	ret

00000000800022e6 <scheduler>:
{
    800022e6:	711d                	addi	sp,sp,-96
    800022e8:	ec86                	sd	ra,88(sp)
    800022ea:	e8a2                	sd	s0,80(sp)
    800022ec:	e4a6                	sd	s1,72(sp)
    800022ee:	e0ca                	sd	s2,64(sp)
    800022f0:	fc4e                	sd	s3,56(sp)
    800022f2:	f852                	sd	s4,48(sp)
    800022f4:	f456                	sd	s5,40(sp)
    800022f6:	f05a                	sd	s6,32(sp)
    800022f8:	ec5e                	sd	s7,24(sp)
    800022fa:	e862                	sd	s8,16(sp)
    800022fc:	e466                	sd	s9,8(sp)
    800022fe:	1080                	addi	s0,sp,96
    80002300:	8792                	mv	a5,tp
  int id = r_tp();
    80002302:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002304:	00779c13          	slli	s8,a5,0x7
    80002308:	00010717          	auipc	a4,0x10
    8000230c:	0c070713          	addi	a4,a4,192 # 800123c8 <pid_lock>
    80002310:	9762                	add	a4,a4,s8
    80002312:	02073023          	sd	zero,32(a4)
        swtch(&c->context, &p->context);
    80002316:	00010717          	auipc	a4,0x10
    8000231a:	0da70713          	addi	a4,a4,218 # 800123f0 <cpus+0x8>
    8000231e:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80002320:	4a89                	li	s5,2
        c->proc = p;
    80002322:	079e                	slli	a5,a5,0x7
    80002324:	00010b17          	auipc	s6,0x10
    80002328:	0a4b0b13          	addi	s6,s6,164 # 800123c8 <pid_lock>
    8000232c:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000232e:	00016a17          	auipc	s4,0x16
    80002332:	0baa0a13          	addi	s4,s4,186 # 800183e8 <tickslock>
    int nproc = 0;
    80002336:	4c81                	li	s9,0
    80002338:	a8a1                	j	80002390 <scheduler+0xaa>
        p->state = RUNNING;
    8000233a:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    8000233e:	029b3023          	sd	s1,32(s6)
        swtch(&c->context, &p->context);
    80002342:	06848593          	addi	a1,s1,104
    80002346:	8562                	mv	a0,s8
    80002348:	00000097          	auipc	ra,0x0
    8000234c:	63a080e7          	jalr	1594(ra) # 80002982 <swtch>
        c->proc = 0;
    80002350:	020b3023          	sd	zero,32(s6)
      release(&p->lock);
    80002354:	8526                	mv	a0,s1
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	ae8080e7          	jalr	-1304(ra) # 80000e3e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000235e:	17048493          	addi	s1,s1,368
    80002362:	01448d63          	beq	s1,s4,8000237c <scheduler+0x96>
      acquire(&p->lock);
    80002366:	8526                	mv	a0,s1
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	a06080e7          	jalr	-1530(ra) # 80000d6e <acquire>
      if(p->state != UNUSED) {
    80002370:	509c                	lw	a5,32(s1)
    80002372:	d3ed                	beqz	a5,80002354 <scheduler+0x6e>
        nproc++;
    80002374:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80002376:	fd579fe3          	bne	a5,s5,80002354 <scheduler+0x6e>
    8000237a:	b7c1                	j	8000233a <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    8000237c:	013aca63          	blt	s5,s3,80002390 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002380:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002384:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002388:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    8000238c:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002390:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002394:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002398:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    8000239c:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    8000239e:	00010497          	auipc	s1,0x10
    800023a2:	44a48493          	addi	s1,s1,1098 # 800127e8 <proc>
        p->state = RUNNING;
    800023a6:	4b8d                	li	s7,3
    800023a8:	bf7d                	j	80002366 <scheduler+0x80>

00000000800023aa <sched>:
{
    800023aa:	7179                	addi	sp,sp,-48
    800023ac:	f406                	sd	ra,40(sp)
    800023ae:	f022                	sd	s0,32(sp)
    800023b0:	ec26                	sd	s1,24(sp)
    800023b2:	e84a                	sd	s2,16(sp)
    800023b4:	e44e                	sd	s3,8(sp)
    800023b6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800023b8:	00000097          	auipc	ra,0x0
    800023bc:	9fe080e7          	jalr	-1538(ra) # 80001db6 <myproc>
    800023c0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	932080e7          	jalr	-1742(ra) # 80000cf4 <holding>
    800023ca:	c93d                	beqz	a0,80002440 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023cc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800023ce:	2781                	sext.w	a5,a5
    800023d0:	079e                	slli	a5,a5,0x7
    800023d2:	00010717          	auipc	a4,0x10
    800023d6:	ff670713          	addi	a4,a4,-10 # 800123c8 <pid_lock>
    800023da:	97ba                	add	a5,a5,a4
    800023dc:	0987a703          	lw	a4,152(a5)
    800023e0:	4785                	li	a5,1
    800023e2:	06f71763          	bne	a4,a5,80002450 <sched+0xa6>
  if(p->state == RUNNING)
    800023e6:	5098                	lw	a4,32(s1)
    800023e8:	478d                	li	a5,3
    800023ea:	06f70b63          	beq	a4,a5,80002460 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023ee:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800023f2:	8b89                	andi	a5,a5,2
  if(intr_get())
    800023f4:	efb5                	bnez	a5,80002470 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023f6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800023f8:	00010917          	auipc	s2,0x10
    800023fc:	fd090913          	addi	s2,s2,-48 # 800123c8 <pid_lock>
    80002400:	2781                	sext.w	a5,a5
    80002402:	079e                	slli	a5,a5,0x7
    80002404:	97ca                	add	a5,a5,s2
    80002406:	09c7a983          	lw	s3,156(a5)
    8000240a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000240c:	2781                	sext.w	a5,a5
    8000240e:	079e                	slli	a5,a5,0x7
    80002410:	00010597          	auipc	a1,0x10
    80002414:	fe058593          	addi	a1,a1,-32 # 800123f0 <cpus+0x8>
    80002418:	95be                	add	a1,a1,a5
    8000241a:	06848513          	addi	a0,s1,104
    8000241e:	00000097          	auipc	ra,0x0
    80002422:	564080e7          	jalr	1380(ra) # 80002982 <swtch>
    80002426:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002428:	2781                	sext.w	a5,a5
    8000242a:	079e                	slli	a5,a5,0x7
    8000242c:	97ca                	add	a5,a5,s2
    8000242e:	0937ae23          	sw	s3,156(a5)
}
    80002432:	70a2                	ld	ra,40(sp)
    80002434:	7402                	ld	s0,32(sp)
    80002436:	64e2                	ld	s1,24(sp)
    80002438:	6942                	ld	s2,16(sp)
    8000243a:	69a2                	ld	s3,8(sp)
    8000243c:	6145                	addi	sp,sp,48
    8000243e:	8082                	ret
    panic("sched p->lock");
    80002440:	00006517          	auipc	a0,0x6
    80002444:	e5850513          	addi	a0,a0,-424 # 80008298 <digits+0x258>
    80002448:	ffffe097          	auipc	ra,0xffffe
    8000244c:	108080e7          	jalr	264(ra) # 80000550 <panic>
    panic("sched locks");
    80002450:	00006517          	auipc	a0,0x6
    80002454:	e5850513          	addi	a0,a0,-424 # 800082a8 <digits+0x268>
    80002458:	ffffe097          	auipc	ra,0xffffe
    8000245c:	0f8080e7          	jalr	248(ra) # 80000550 <panic>
    panic("sched running");
    80002460:	00006517          	auipc	a0,0x6
    80002464:	e5850513          	addi	a0,a0,-424 # 800082b8 <digits+0x278>
    80002468:	ffffe097          	auipc	ra,0xffffe
    8000246c:	0e8080e7          	jalr	232(ra) # 80000550 <panic>
    panic("sched interruptible");
    80002470:	00006517          	auipc	a0,0x6
    80002474:	e5850513          	addi	a0,a0,-424 # 800082c8 <digits+0x288>
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	0d8080e7          	jalr	216(ra) # 80000550 <panic>

0000000080002480 <exit>:
{
    80002480:	7179                	addi	sp,sp,-48
    80002482:	f406                	sd	ra,40(sp)
    80002484:	f022                	sd	s0,32(sp)
    80002486:	ec26                	sd	s1,24(sp)
    80002488:	e84a                	sd	s2,16(sp)
    8000248a:	e44e                	sd	s3,8(sp)
    8000248c:	e052                	sd	s4,0(sp)
    8000248e:	1800                	addi	s0,sp,48
    80002490:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002492:	00000097          	auipc	ra,0x0
    80002496:	924080e7          	jalr	-1756(ra) # 80001db6 <myproc>
    8000249a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000249c:	00007797          	auipc	a5,0x7
    800024a0:	b7c7b783          	ld	a5,-1156(a5) # 80009018 <initproc>
    800024a4:	0d850493          	addi	s1,a0,216
    800024a8:	15850913          	addi	s2,a0,344
    800024ac:	02a79363          	bne	a5,a0,800024d2 <exit+0x52>
    panic("init exiting");
    800024b0:	00006517          	auipc	a0,0x6
    800024b4:	e3050513          	addi	a0,a0,-464 # 800082e0 <digits+0x2a0>
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	098080e7          	jalr	152(ra) # 80000550 <panic>
      fileclose(f);
    800024c0:	00002097          	auipc	ra,0x2
    800024c4:	60e080e7          	jalr	1550(ra) # 80004ace <fileclose>
      p->ofile[fd] = 0;
    800024c8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024cc:	04a1                	addi	s1,s1,8
    800024ce:	01248563          	beq	s1,s2,800024d8 <exit+0x58>
    if(p->ofile[fd]){
    800024d2:	6088                	ld	a0,0(s1)
    800024d4:	f575                	bnez	a0,800024c0 <exit+0x40>
    800024d6:	bfdd                	j	800024cc <exit+0x4c>
  begin_op();
    800024d8:	00002097          	auipc	ra,0x2
    800024dc:	122080e7          	jalr	290(ra) # 800045fa <begin_op>
  iput(p->cwd);
    800024e0:	1589b503          	ld	a0,344(s3)
    800024e4:	00002097          	auipc	ra,0x2
    800024e8:	900080e7          	jalr	-1792(ra) # 80003de4 <iput>
  end_op();
    800024ec:	00002097          	auipc	ra,0x2
    800024f0:	18e080e7          	jalr	398(ra) # 8000467a <end_op>
  p->cwd = 0;
    800024f4:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    800024f8:	00007497          	auipc	s1,0x7
    800024fc:	b2048493          	addi	s1,s1,-1248 # 80009018 <initproc>
    80002500:	6088                	ld	a0,0(s1)
    80002502:	fffff097          	auipc	ra,0xfffff
    80002506:	86c080e7          	jalr	-1940(ra) # 80000d6e <acquire>
  wakeup1(initproc);
    8000250a:	6088                	ld	a0,0(s1)
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	76a080e7          	jalr	1898(ra) # 80001c76 <wakeup1>
  release(&initproc->lock);
    80002514:	6088                	ld	a0,0(s1)
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	928080e7          	jalr	-1752(ra) # 80000e3e <release>
  acquire(&p->lock);
    8000251e:	854e                	mv	a0,s3
    80002520:	fffff097          	auipc	ra,0xfffff
    80002524:	84e080e7          	jalr	-1970(ra) # 80000d6e <acquire>
  struct proc *original_parent = p->parent;
    80002528:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    8000252c:	854e                	mv	a0,s3
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	910080e7          	jalr	-1776(ra) # 80000e3e <release>
  acquire(&original_parent->lock);
    80002536:	8526                	mv	a0,s1
    80002538:	fffff097          	auipc	ra,0xfffff
    8000253c:	836080e7          	jalr	-1994(ra) # 80000d6e <acquire>
  acquire(&p->lock);
    80002540:	854e                	mv	a0,s3
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	82c080e7          	jalr	-2004(ra) # 80000d6e <acquire>
  reparent(p);
    8000254a:	854e                	mv	a0,s3
    8000254c:	00000097          	auipc	ra,0x0
    80002550:	d34080e7          	jalr	-716(ra) # 80002280 <reparent>
  wakeup1(original_parent);
    80002554:	8526                	mv	a0,s1
    80002556:	fffff097          	auipc	ra,0xfffff
    8000255a:	720080e7          	jalr	1824(ra) # 80001c76 <wakeup1>
  p->xstate = status;
    8000255e:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    80002562:	4791                	li	a5,4
    80002564:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    80002568:	8526                	mv	a0,s1
    8000256a:	fffff097          	auipc	ra,0xfffff
    8000256e:	8d4080e7          	jalr	-1836(ra) # 80000e3e <release>
  sched();
    80002572:	00000097          	auipc	ra,0x0
    80002576:	e38080e7          	jalr	-456(ra) # 800023aa <sched>
  panic("zombie exit");
    8000257a:	00006517          	auipc	a0,0x6
    8000257e:	d7650513          	addi	a0,a0,-650 # 800082f0 <digits+0x2b0>
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	fce080e7          	jalr	-50(ra) # 80000550 <panic>

000000008000258a <yield>:
{
    8000258a:	1101                	addi	sp,sp,-32
    8000258c:	ec06                	sd	ra,24(sp)
    8000258e:	e822                	sd	s0,16(sp)
    80002590:	e426                	sd	s1,8(sp)
    80002592:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002594:	00000097          	auipc	ra,0x0
    80002598:	822080e7          	jalr	-2014(ra) # 80001db6 <myproc>
    8000259c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	7d0080e7          	jalr	2000(ra) # 80000d6e <acquire>
  p->state = RUNNABLE;
    800025a6:	4789                	li	a5,2
    800025a8:	d09c                	sw	a5,32(s1)
  sched();
    800025aa:	00000097          	auipc	ra,0x0
    800025ae:	e00080e7          	jalr	-512(ra) # 800023aa <sched>
  release(&p->lock);
    800025b2:	8526                	mv	a0,s1
    800025b4:	fffff097          	auipc	ra,0xfffff
    800025b8:	88a080e7          	jalr	-1910(ra) # 80000e3e <release>
}
    800025bc:	60e2                	ld	ra,24(sp)
    800025be:	6442                	ld	s0,16(sp)
    800025c0:	64a2                	ld	s1,8(sp)
    800025c2:	6105                	addi	sp,sp,32
    800025c4:	8082                	ret

00000000800025c6 <sleep>:
{
    800025c6:	7179                	addi	sp,sp,-48
    800025c8:	f406                	sd	ra,40(sp)
    800025ca:	f022                	sd	s0,32(sp)
    800025cc:	ec26                	sd	s1,24(sp)
    800025ce:	e84a                	sd	s2,16(sp)
    800025d0:	e44e                	sd	s3,8(sp)
    800025d2:	1800                	addi	s0,sp,48
    800025d4:	89aa                	mv	s3,a0
    800025d6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800025d8:	fffff097          	auipc	ra,0xfffff
    800025dc:	7de080e7          	jalr	2014(ra) # 80001db6 <myproc>
    800025e0:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800025e2:	05250663          	beq	a0,s2,8000262e <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	788080e7          	jalr	1928(ra) # 80000d6e <acquire>
    release(lk);
    800025ee:	854a                	mv	a0,s2
    800025f0:	fffff097          	auipc	ra,0xfffff
    800025f4:	84e080e7          	jalr	-1970(ra) # 80000e3e <release>
  p->chan = chan;
    800025f8:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    800025fc:	4785                	li	a5,1
    800025fe:	d09c                	sw	a5,32(s1)
  sched();
    80002600:	00000097          	auipc	ra,0x0
    80002604:	daa080e7          	jalr	-598(ra) # 800023aa <sched>
  p->chan = 0;
    80002608:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    8000260c:	8526                	mv	a0,s1
    8000260e:	fffff097          	auipc	ra,0xfffff
    80002612:	830080e7          	jalr	-2000(ra) # 80000e3e <release>
    acquire(lk);
    80002616:	854a                	mv	a0,s2
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	756080e7          	jalr	1878(ra) # 80000d6e <acquire>
}
    80002620:	70a2                	ld	ra,40(sp)
    80002622:	7402                	ld	s0,32(sp)
    80002624:	64e2                	ld	s1,24(sp)
    80002626:	6942                	ld	s2,16(sp)
    80002628:	69a2                	ld	s3,8(sp)
    8000262a:	6145                	addi	sp,sp,48
    8000262c:	8082                	ret
  p->chan = chan;
    8000262e:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    80002632:	4785                	li	a5,1
    80002634:	d11c                	sw	a5,32(a0)
  sched();
    80002636:	00000097          	auipc	ra,0x0
    8000263a:	d74080e7          	jalr	-652(ra) # 800023aa <sched>
  p->chan = 0;
    8000263e:	0204b823          	sd	zero,48(s1)
  if(lk != &p->lock){
    80002642:	bff9                	j	80002620 <sleep+0x5a>

0000000080002644 <wait>:
{
    80002644:	715d                	addi	sp,sp,-80
    80002646:	e486                	sd	ra,72(sp)
    80002648:	e0a2                	sd	s0,64(sp)
    8000264a:	fc26                	sd	s1,56(sp)
    8000264c:	f84a                	sd	s2,48(sp)
    8000264e:	f44e                	sd	s3,40(sp)
    80002650:	f052                	sd	s4,32(sp)
    80002652:	ec56                	sd	s5,24(sp)
    80002654:	e85a                	sd	s6,16(sp)
    80002656:	e45e                	sd	s7,8(sp)
    80002658:	e062                	sd	s8,0(sp)
    8000265a:	0880                	addi	s0,sp,80
    8000265c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000265e:	fffff097          	auipc	ra,0xfffff
    80002662:	758080e7          	jalr	1880(ra) # 80001db6 <myproc>
    80002666:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002668:	8c2a                	mv	s8,a0
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	704080e7          	jalr	1796(ra) # 80000d6e <acquire>
    havekids = 0;
    80002672:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002674:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002676:	00016997          	auipc	s3,0x16
    8000267a:	d7298993          	addi	s3,s3,-654 # 800183e8 <tickslock>
        havekids = 1;
    8000267e:	4a85                	li	s5,1
    havekids = 0;
    80002680:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002682:	00010497          	auipc	s1,0x10
    80002686:	16648493          	addi	s1,s1,358 # 800127e8 <proc>
    8000268a:	a08d                	j	800026ec <wait+0xa8>
          pid = np->pid;
    8000268c:	0404a983          	lw	s3,64(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002690:	000b0e63          	beqz	s6,800026ac <wait+0x68>
    80002694:	4691                	li	a3,4
    80002696:	03c48613          	addi	a2,s1,60
    8000269a:	85da                	mv	a1,s6
    8000269c:	05893503          	ld	a0,88(s2)
    800026a0:	fffff097          	auipc	ra,0xfffff
    800026a4:	40a080e7          	jalr	1034(ra) # 80001aaa <copyout>
    800026a8:	02054263          	bltz	a0,800026cc <wait+0x88>
          freeproc(np);
    800026ac:	8526                	mv	a0,s1
    800026ae:	00000097          	auipc	ra,0x0
    800026b2:	8ba080e7          	jalr	-1862(ra) # 80001f68 <freeproc>
          release(&np->lock);
    800026b6:	8526                	mv	a0,s1
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	786080e7          	jalr	1926(ra) # 80000e3e <release>
          release(&p->lock);
    800026c0:	854a                	mv	a0,s2
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	77c080e7          	jalr	1916(ra) # 80000e3e <release>
          return pid;
    800026ca:	a8a9                	j	80002724 <wait+0xe0>
            release(&np->lock);
    800026cc:	8526                	mv	a0,s1
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	770080e7          	jalr	1904(ra) # 80000e3e <release>
            release(&p->lock);
    800026d6:	854a                	mv	a0,s2
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	766080e7          	jalr	1894(ra) # 80000e3e <release>
            return -1;
    800026e0:	59fd                	li	s3,-1
    800026e2:	a089                	j	80002724 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800026e4:	17048493          	addi	s1,s1,368
    800026e8:	03348463          	beq	s1,s3,80002710 <wait+0xcc>
      if(np->parent == p){
    800026ec:	749c                	ld	a5,40(s1)
    800026ee:	ff279be3          	bne	a5,s2,800026e4 <wait+0xa0>
        acquire(&np->lock);
    800026f2:	8526                	mv	a0,s1
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	67a080e7          	jalr	1658(ra) # 80000d6e <acquire>
        if(np->state == ZOMBIE){
    800026fc:	509c                	lw	a5,32(s1)
    800026fe:	f94787e3          	beq	a5,s4,8000268c <wait+0x48>
        release(&np->lock);
    80002702:	8526                	mv	a0,s1
    80002704:	ffffe097          	auipc	ra,0xffffe
    80002708:	73a080e7          	jalr	1850(ra) # 80000e3e <release>
        havekids = 1;
    8000270c:	8756                	mv	a4,s5
    8000270e:	bfd9                	j	800026e4 <wait+0xa0>
    if(!havekids || p->killed){
    80002710:	c701                	beqz	a4,80002718 <wait+0xd4>
    80002712:	03892783          	lw	a5,56(s2)
    80002716:	c785                	beqz	a5,8000273e <wait+0xfa>
      release(&p->lock);
    80002718:	854a                	mv	a0,s2
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	724080e7          	jalr	1828(ra) # 80000e3e <release>
      return -1;
    80002722:	59fd                	li	s3,-1
}
    80002724:	854e                	mv	a0,s3
    80002726:	60a6                	ld	ra,72(sp)
    80002728:	6406                	ld	s0,64(sp)
    8000272a:	74e2                	ld	s1,56(sp)
    8000272c:	7942                	ld	s2,48(sp)
    8000272e:	79a2                	ld	s3,40(sp)
    80002730:	7a02                	ld	s4,32(sp)
    80002732:	6ae2                	ld	s5,24(sp)
    80002734:	6b42                	ld	s6,16(sp)
    80002736:	6ba2                	ld	s7,8(sp)
    80002738:	6c02                	ld	s8,0(sp)
    8000273a:	6161                	addi	sp,sp,80
    8000273c:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000273e:	85e2                	mv	a1,s8
    80002740:	854a                	mv	a0,s2
    80002742:	00000097          	auipc	ra,0x0
    80002746:	e84080e7          	jalr	-380(ra) # 800025c6 <sleep>
    havekids = 0;
    8000274a:	bf1d                	j	80002680 <wait+0x3c>

000000008000274c <wakeup>:
{
    8000274c:	7139                	addi	sp,sp,-64
    8000274e:	fc06                	sd	ra,56(sp)
    80002750:	f822                	sd	s0,48(sp)
    80002752:	f426                	sd	s1,40(sp)
    80002754:	f04a                	sd	s2,32(sp)
    80002756:	ec4e                	sd	s3,24(sp)
    80002758:	e852                	sd	s4,16(sp)
    8000275a:	e456                	sd	s5,8(sp)
    8000275c:	0080                	addi	s0,sp,64
    8000275e:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002760:	00010497          	auipc	s1,0x10
    80002764:	08848493          	addi	s1,s1,136 # 800127e8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002768:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000276a:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000276c:	00016917          	auipc	s2,0x16
    80002770:	c7c90913          	addi	s2,s2,-900 # 800183e8 <tickslock>
    80002774:	a821                	j	8000278c <wakeup+0x40>
      p->state = RUNNABLE;
    80002776:	0354a023          	sw	s5,32(s1)
    release(&p->lock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	6c2080e7          	jalr	1730(ra) # 80000e3e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002784:	17048493          	addi	s1,s1,368
    80002788:	01248e63          	beq	s1,s2,800027a4 <wakeup+0x58>
    acquire(&p->lock);
    8000278c:	8526                	mv	a0,s1
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	5e0080e7          	jalr	1504(ra) # 80000d6e <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002796:	509c                	lw	a5,32(s1)
    80002798:	ff3791e3          	bne	a5,s3,8000277a <wakeup+0x2e>
    8000279c:	789c                	ld	a5,48(s1)
    8000279e:	fd479ee3          	bne	a5,s4,8000277a <wakeup+0x2e>
    800027a2:	bfd1                	j	80002776 <wakeup+0x2a>
}
    800027a4:	70e2                	ld	ra,56(sp)
    800027a6:	7442                	ld	s0,48(sp)
    800027a8:	74a2                	ld	s1,40(sp)
    800027aa:	7902                	ld	s2,32(sp)
    800027ac:	69e2                	ld	s3,24(sp)
    800027ae:	6a42                	ld	s4,16(sp)
    800027b0:	6aa2                	ld	s5,8(sp)
    800027b2:	6121                	addi	sp,sp,64
    800027b4:	8082                	ret

00000000800027b6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800027b6:	7179                	addi	sp,sp,-48
    800027b8:	f406                	sd	ra,40(sp)
    800027ba:	f022                	sd	s0,32(sp)
    800027bc:	ec26                	sd	s1,24(sp)
    800027be:	e84a                	sd	s2,16(sp)
    800027c0:	e44e                	sd	s3,8(sp)
    800027c2:	1800                	addi	s0,sp,48
    800027c4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800027c6:	00010497          	auipc	s1,0x10
    800027ca:	02248493          	addi	s1,s1,34 # 800127e8 <proc>
    800027ce:	00016997          	auipc	s3,0x16
    800027d2:	c1a98993          	addi	s3,s3,-998 # 800183e8 <tickslock>
    acquire(&p->lock);
    800027d6:	8526                	mv	a0,s1
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	596080e7          	jalr	1430(ra) # 80000d6e <acquire>
    if(p->pid == pid){
    800027e0:	40bc                	lw	a5,64(s1)
    800027e2:	01278d63          	beq	a5,s2,800027fc <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027e6:	8526                	mv	a0,s1
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	656080e7          	jalr	1622(ra) # 80000e3e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027f0:	17048493          	addi	s1,s1,368
    800027f4:	ff3491e3          	bne	s1,s3,800027d6 <kill+0x20>
  }
  return -1;
    800027f8:	557d                	li	a0,-1
    800027fa:	a829                	j	80002814 <kill+0x5e>
      p->killed = 1;
    800027fc:	4785                	li	a5,1
    800027fe:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    80002800:	5098                	lw	a4,32(s1)
    80002802:	4785                	li	a5,1
    80002804:	00f70f63          	beq	a4,a5,80002822 <kill+0x6c>
      release(&p->lock);
    80002808:	8526                	mv	a0,s1
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	634080e7          	jalr	1588(ra) # 80000e3e <release>
      return 0;
    80002812:	4501                	li	a0,0
}
    80002814:	70a2                	ld	ra,40(sp)
    80002816:	7402                	ld	s0,32(sp)
    80002818:	64e2                	ld	s1,24(sp)
    8000281a:	6942                	ld	s2,16(sp)
    8000281c:	69a2                	ld	s3,8(sp)
    8000281e:	6145                	addi	sp,sp,48
    80002820:	8082                	ret
        p->state = RUNNABLE;
    80002822:	4789                	li	a5,2
    80002824:	d09c                	sw	a5,32(s1)
    80002826:	b7cd                	j	80002808 <kill+0x52>

0000000080002828 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002828:	7179                	addi	sp,sp,-48
    8000282a:	f406                	sd	ra,40(sp)
    8000282c:	f022                	sd	s0,32(sp)
    8000282e:	ec26                	sd	s1,24(sp)
    80002830:	e84a                	sd	s2,16(sp)
    80002832:	e44e                	sd	s3,8(sp)
    80002834:	e052                	sd	s4,0(sp)
    80002836:	1800                	addi	s0,sp,48
    80002838:	84aa                	mv	s1,a0
    8000283a:	892e                	mv	s2,a1
    8000283c:	89b2                	mv	s3,a2
    8000283e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002840:	fffff097          	auipc	ra,0xfffff
    80002844:	576080e7          	jalr	1398(ra) # 80001db6 <myproc>
  if(user_dst){
    80002848:	c08d                	beqz	s1,8000286a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000284a:	86d2                	mv	a3,s4
    8000284c:	864e                	mv	a2,s3
    8000284e:	85ca                	mv	a1,s2
    80002850:	6d28                	ld	a0,88(a0)
    80002852:	fffff097          	auipc	ra,0xfffff
    80002856:	258080e7          	jalr	600(ra) # 80001aaa <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000285a:	70a2                	ld	ra,40(sp)
    8000285c:	7402                	ld	s0,32(sp)
    8000285e:	64e2                	ld	s1,24(sp)
    80002860:	6942                	ld	s2,16(sp)
    80002862:	69a2                	ld	s3,8(sp)
    80002864:	6a02                	ld	s4,0(sp)
    80002866:	6145                	addi	sp,sp,48
    80002868:	8082                	ret
    memmove((char *)dst, src, len);
    8000286a:	000a061b          	sext.w	a2,s4
    8000286e:	85ce                	mv	a1,s3
    80002870:	854a                	mv	a0,s2
    80002872:	fffff097          	auipc	ra,0xfffff
    80002876:	93c080e7          	jalr	-1732(ra) # 800011ae <memmove>
    return 0;
    8000287a:	8526                	mv	a0,s1
    8000287c:	bff9                	j	8000285a <either_copyout+0x32>

000000008000287e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000287e:	7179                	addi	sp,sp,-48
    80002880:	f406                	sd	ra,40(sp)
    80002882:	f022                	sd	s0,32(sp)
    80002884:	ec26                	sd	s1,24(sp)
    80002886:	e84a                	sd	s2,16(sp)
    80002888:	e44e                	sd	s3,8(sp)
    8000288a:	e052                	sd	s4,0(sp)
    8000288c:	1800                	addi	s0,sp,48
    8000288e:	892a                	mv	s2,a0
    80002890:	84ae                	mv	s1,a1
    80002892:	89b2                	mv	s3,a2
    80002894:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002896:	fffff097          	auipc	ra,0xfffff
    8000289a:	520080e7          	jalr	1312(ra) # 80001db6 <myproc>
  if(user_src){
    8000289e:	c08d                	beqz	s1,800028c0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800028a0:	86d2                	mv	a3,s4
    800028a2:	864e                	mv	a2,s3
    800028a4:	85ca                	mv	a1,s2
    800028a6:	6d28                	ld	a0,88(a0)
    800028a8:	fffff097          	auipc	ra,0xfffff
    800028ac:	28e080e7          	jalr	654(ra) # 80001b36 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800028b0:	70a2                	ld	ra,40(sp)
    800028b2:	7402                	ld	s0,32(sp)
    800028b4:	64e2                	ld	s1,24(sp)
    800028b6:	6942                	ld	s2,16(sp)
    800028b8:	69a2                	ld	s3,8(sp)
    800028ba:	6a02                	ld	s4,0(sp)
    800028bc:	6145                	addi	sp,sp,48
    800028be:	8082                	ret
    memmove(dst, (char*)src, len);
    800028c0:	000a061b          	sext.w	a2,s4
    800028c4:	85ce                	mv	a1,s3
    800028c6:	854a                	mv	a0,s2
    800028c8:	fffff097          	auipc	ra,0xfffff
    800028cc:	8e6080e7          	jalr	-1818(ra) # 800011ae <memmove>
    return 0;
    800028d0:	8526                	mv	a0,s1
    800028d2:	bff9                	j	800028b0 <either_copyin+0x32>

00000000800028d4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800028d4:	715d                	addi	sp,sp,-80
    800028d6:	e486                	sd	ra,72(sp)
    800028d8:	e0a2                	sd	s0,64(sp)
    800028da:	fc26                	sd	s1,56(sp)
    800028dc:	f84a                	sd	s2,48(sp)
    800028de:	f44e                	sd	s3,40(sp)
    800028e0:	f052                	sd	s4,32(sp)
    800028e2:	ec56                	sd	s5,24(sp)
    800028e4:	e85a                	sd	s6,16(sp)
    800028e6:	e45e                	sd	s7,8(sp)
    800028e8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800028ea:	00006517          	auipc	a0,0x6
    800028ee:	87e50513          	addi	a0,a0,-1922 # 80008168 <digits+0x128>
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	ca8080e7          	jalr	-856(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028fa:	00010497          	auipc	s1,0x10
    800028fe:	04e48493          	addi	s1,s1,78 # 80012948 <proc+0x160>
    80002902:	00016917          	auipc	s2,0x16
    80002906:	c4690913          	addi	s2,s2,-954 # 80018548 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000290a:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000290c:	00006997          	auipc	s3,0x6
    80002910:	9f498993          	addi	s3,s3,-1548 # 80008300 <digits+0x2c0>
    printf("%d %s %s", p->pid, state, p->name);
    80002914:	00006a97          	auipc	s5,0x6
    80002918:	9f4a8a93          	addi	s5,s5,-1548 # 80008308 <digits+0x2c8>
    printf("\n");
    8000291c:	00006a17          	auipc	s4,0x6
    80002920:	84ca0a13          	addi	s4,s4,-1972 # 80008168 <digits+0x128>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002924:	00006b97          	auipc	s7,0x6
    80002928:	a1cb8b93          	addi	s7,s7,-1508 # 80008340 <states.1712>
    8000292c:	a00d                	j	8000294e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000292e:	ee06a583          	lw	a1,-288(a3)
    80002932:	8556                	mv	a0,s5
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	c66080e7          	jalr	-922(ra) # 8000059a <printf>
    printf("\n");
    8000293c:	8552                	mv	a0,s4
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	c5c080e7          	jalr	-932(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002946:	17048493          	addi	s1,s1,368
    8000294a:	03248163          	beq	s1,s2,8000296c <procdump+0x98>
    if(p->state == UNUSED)
    8000294e:	86a6                	mv	a3,s1
    80002950:	ec04a783          	lw	a5,-320(s1)
    80002954:	dbed                	beqz	a5,80002946 <procdump+0x72>
      state = "???";
    80002956:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002958:	fcfb6be3          	bltu	s6,a5,8000292e <procdump+0x5a>
    8000295c:	1782                	slli	a5,a5,0x20
    8000295e:	9381                	srli	a5,a5,0x20
    80002960:	078e                	slli	a5,a5,0x3
    80002962:	97de                	add	a5,a5,s7
    80002964:	6390                	ld	a2,0(a5)
    80002966:	f661                	bnez	a2,8000292e <procdump+0x5a>
      state = "???";
    80002968:	864e                	mv	a2,s3
    8000296a:	b7d1                	j	8000292e <procdump+0x5a>
  }
}
    8000296c:	60a6                	ld	ra,72(sp)
    8000296e:	6406                	ld	s0,64(sp)
    80002970:	74e2                	ld	s1,56(sp)
    80002972:	7942                	ld	s2,48(sp)
    80002974:	79a2                	ld	s3,40(sp)
    80002976:	7a02                	ld	s4,32(sp)
    80002978:	6ae2                	ld	s5,24(sp)
    8000297a:	6b42                	ld	s6,16(sp)
    8000297c:	6ba2                	ld	s7,8(sp)
    8000297e:	6161                	addi	sp,sp,80
    80002980:	8082                	ret

0000000080002982 <swtch>:
    80002982:	00153023          	sd	ra,0(a0)
    80002986:	00253423          	sd	sp,8(a0)
    8000298a:	e900                	sd	s0,16(a0)
    8000298c:	ed04                	sd	s1,24(a0)
    8000298e:	03253023          	sd	s2,32(a0)
    80002992:	03353423          	sd	s3,40(a0)
    80002996:	03453823          	sd	s4,48(a0)
    8000299a:	03553c23          	sd	s5,56(a0)
    8000299e:	05653023          	sd	s6,64(a0)
    800029a2:	05753423          	sd	s7,72(a0)
    800029a6:	05853823          	sd	s8,80(a0)
    800029aa:	05953c23          	sd	s9,88(a0)
    800029ae:	07a53023          	sd	s10,96(a0)
    800029b2:	07b53423          	sd	s11,104(a0)
    800029b6:	0005b083          	ld	ra,0(a1)
    800029ba:	0085b103          	ld	sp,8(a1)
    800029be:	6980                	ld	s0,16(a1)
    800029c0:	6d84                	ld	s1,24(a1)
    800029c2:	0205b903          	ld	s2,32(a1)
    800029c6:	0285b983          	ld	s3,40(a1)
    800029ca:	0305ba03          	ld	s4,48(a1)
    800029ce:	0385ba83          	ld	s5,56(a1)
    800029d2:	0405bb03          	ld	s6,64(a1)
    800029d6:	0485bb83          	ld	s7,72(a1)
    800029da:	0505bc03          	ld	s8,80(a1)
    800029de:	0585bc83          	ld	s9,88(a1)
    800029e2:	0605bd03          	ld	s10,96(a1)
    800029e6:	0685bd83          	ld	s11,104(a1)
    800029ea:	8082                	ret

00000000800029ec <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029ec:	1141                	addi	sp,sp,-16
    800029ee:	e406                	sd	ra,8(sp)
    800029f0:	e022                	sd	s0,0(sp)
    800029f2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029f4:	00006597          	auipc	a1,0x6
    800029f8:	97458593          	addi	a1,a1,-1676 # 80008368 <states.1712+0x28>
    800029fc:	00016517          	auipc	a0,0x16
    80002a00:	9ec50513          	addi	a0,a0,-1556 # 800183e8 <tickslock>
    80002a04:	ffffe097          	auipc	ra,0xffffe
    80002a08:	4e6080e7          	jalr	1254(ra) # 80000eea <initlock>
}
    80002a0c:	60a2                	ld	ra,8(sp)
    80002a0e:	6402                	ld	s0,0(sp)
    80002a10:	0141                	addi	sp,sp,16
    80002a12:	8082                	ret

0000000080002a14 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a14:	1141                	addi	sp,sp,-16
    80002a16:	e422                	sd	s0,8(sp)
    80002a18:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a1a:	00003797          	auipc	a5,0x3
    80002a1e:	72678793          	addi	a5,a5,1830 # 80006140 <kernelvec>
    80002a22:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a26:	6422                	ld	s0,8(sp)
    80002a28:	0141                	addi	sp,sp,16
    80002a2a:	8082                	ret

0000000080002a2c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a2c:	1141                	addi	sp,sp,-16
    80002a2e:	e406                	sd	ra,8(sp)
    80002a30:	e022                	sd	s0,0(sp)
    80002a32:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a34:	fffff097          	auipc	ra,0xfffff
    80002a38:	382080e7          	jalr	898(ra) # 80001db6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a3c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a40:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a42:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a46:	00004617          	auipc	a2,0x4
    80002a4a:	5ba60613          	addi	a2,a2,1466 # 80007000 <_trampoline>
    80002a4e:	00004697          	auipc	a3,0x4
    80002a52:	5b268693          	addi	a3,a3,1458 # 80007000 <_trampoline>
    80002a56:	8e91                	sub	a3,a3,a2
    80002a58:	040007b7          	lui	a5,0x4000
    80002a5c:	17fd                	addi	a5,a5,-1
    80002a5e:	07b2                	slli	a5,a5,0xc
    80002a60:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a62:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a66:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a68:	180026f3          	csrr	a3,satp
    80002a6c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a6e:	7138                	ld	a4,96(a0)
    80002a70:	6534                	ld	a3,72(a0)
    80002a72:	6585                	lui	a1,0x1
    80002a74:	96ae                	add	a3,a3,a1
    80002a76:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a78:	7138                	ld	a4,96(a0)
    80002a7a:	00000697          	auipc	a3,0x0
    80002a7e:	13868693          	addi	a3,a3,312 # 80002bb2 <usertrap>
    80002a82:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a84:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a86:	8692                	mv	a3,tp
    80002a88:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a8a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a8e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a92:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a96:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a9a:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a9c:	6f18                	ld	a4,24(a4)
    80002a9e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002aa2:	6d2c                	ld	a1,88(a0)
    80002aa4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002aa6:	00004717          	auipc	a4,0x4
    80002aaa:	5ea70713          	addi	a4,a4,1514 # 80007090 <userret>
    80002aae:	8f11                	sub	a4,a4,a2
    80002ab0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002ab2:	577d                	li	a4,-1
    80002ab4:	177e                	slli	a4,a4,0x3f
    80002ab6:	8dd9                	or	a1,a1,a4
    80002ab8:	02000537          	lui	a0,0x2000
    80002abc:	157d                	addi	a0,a0,-1
    80002abe:	0536                	slli	a0,a0,0xd
    80002ac0:	9782                	jalr	a5
}
    80002ac2:	60a2                	ld	ra,8(sp)
    80002ac4:	6402                	ld	s0,0(sp)
    80002ac6:	0141                	addi	sp,sp,16
    80002ac8:	8082                	ret

0000000080002aca <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002aca:	1101                	addi	sp,sp,-32
    80002acc:	ec06                	sd	ra,24(sp)
    80002ace:	e822                	sd	s0,16(sp)
    80002ad0:	e426                	sd	s1,8(sp)
    80002ad2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ad4:	00016497          	auipc	s1,0x16
    80002ad8:	91448493          	addi	s1,s1,-1772 # 800183e8 <tickslock>
    80002adc:	8526                	mv	a0,s1
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	290080e7          	jalr	656(ra) # 80000d6e <acquire>
  ticks++;
    80002ae6:	00006517          	auipc	a0,0x6
    80002aea:	53a50513          	addi	a0,a0,1338 # 80009020 <ticks>
    80002aee:	411c                	lw	a5,0(a0)
    80002af0:	2785                	addiw	a5,a5,1
    80002af2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002af4:	00000097          	auipc	ra,0x0
    80002af8:	c58080e7          	jalr	-936(ra) # 8000274c <wakeup>
  release(&tickslock);
    80002afc:	8526                	mv	a0,s1
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	340080e7          	jalr	832(ra) # 80000e3e <release>
}
    80002b06:	60e2                	ld	ra,24(sp)
    80002b08:	6442                	ld	s0,16(sp)
    80002b0a:	64a2                	ld	s1,8(sp)
    80002b0c:	6105                	addi	sp,sp,32
    80002b0e:	8082                	ret

0000000080002b10 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b10:	1101                	addi	sp,sp,-32
    80002b12:	ec06                	sd	ra,24(sp)
    80002b14:	e822                	sd	s0,16(sp)
    80002b16:	e426                	sd	s1,8(sp)
    80002b18:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b1a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b1e:	00074d63          	bltz	a4,80002b38 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b22:	57fd                	li	a5,-1
    80002b24:	17fe                	slli	a5,a5,0x3f
    80002b26:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b28:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b2a:	06f70363          	beq	a4,a5,80002b90 <devintr+0x80>
  }
}
    80002b2e:	60e2                	ld	ra,24(sp)
    80002b30:	6442                	ld	s0,16(sp)
    80002b32:	64a2                	ld	s1,8(sp)
    80002b34:	6105                	addi	sp,sp,32
    80002b36:	8082                	ret
     (scause & 0xff) == 9){
    80002b38:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b3c:	46a5                	li	a3,9
    80002b3e:	fed792e3          	bne	a5,a3,80002b22 <devintr+0x12>
    int irq = plic_claim();
    80002b42:	00003097          	auipc	ra,0x3
    80002b46:	706080e7          	jalr	1798(ra) # 80006248 <plic_claim>
    80002b4a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b4c:	47a9                	li	a5,10
    80002b4e:	02f50763          	beq	a0,a5,80002b7c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b52:	4785                	li	a5,1
    80002b54:	02f50963          	beq	a0,a5,80002b86 <devintr+0x76>
    return 1;
    80002b58:	4505                	li	a0,1
    } else if(irq){
    80002b5a:	d8f1                	beqz	s1,80002b2e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b5c:	85a6                	mv	a1,s1
    80002b5e:	00006517          	auipc	a0,0x6
    80002b62:	81250513          	addi	a0,a0,-2030 # 80008370 <states.1712+0x30>
    80002b66:	ffffe097          	auipc	ra,0xffffe
    80002b6a:	a34080e7          	jalr	-1484(ra) # 8000059a <printf>
      plic_complete(irq);
    80002b6e:	8526                	mv	a0,s1
    80002b70:	00003097          	auipc	ra,0x3
    80002b74:	6fc080e7          	jalr	1788(ra) # 8000626c <plic_complete>
    return 1;
    80002b78:	4505                	li	a0,1
    80002b7a:	bf55                	j	80002b2e <devintr+0x1e>
      uartintr();
    80002b7c:	ffffe097          	auipc	ra,0xffffe
    80002b80:	e60080e7          	jalr	-416(ra) # 800009dc <uartintr>
    80002b84:	b7ed                	j	80002b6e <devintr+0x5e>
      virtio_disk_intr();
    80002b86:	00004097          	auipc	ra,0x4
    80002b8a:	bc6080e7          	jalr	-1082(ra) # 8000674c <virtio_disk_intr>
    80002b8e:	b7c5                	j	80002b6e <devintr+0x5e>
    if(cpuid() == 0){
    80002b90:	fffff097          	auipc	ra,0xfffff
    80002b94:	1fa080e7          	jalr	506(ra) # 80001d8a <cpuid>
    80002b98:	c901                	beqz	a0,80002ba8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b9a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b9e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ba0:	14479073          	csrw	sip,a5
    return 2;
    80002ba4:	4509                	li	a0,2
    80002ba6:	b761                	j	80002b2e <devintr+0x1e>
      clockintr();
    80002ba8:	00000097          	auipc	ra,0x0
    80002bac:	f22080e7          	jalr	-222(ra) # 80002aca <clockintr>
    80002bb0:	b7ed                	j	80002b9a <devintr+0x8a>

0000000080002bb2 <usertrap>:
{
    80002bb2:	1101                	addi	sp,sp,-32
    80002bb4:	ec06                	sd	ra,24(sp)
    80002bb6:	e822                	sd	s0,16(sp)
    80002bb8:	e426                	sd	s1,8(sp)
    80002bba:	e04a                	sd	s2,0(sp)
    80002bbc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bbe:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002bc2:	1007f793          	andi	a5,a5,256
    80002bc6:	e3ad                	bnez	a5,80002c28 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bc8:	00003797          	auipc	a5,0x3
    80002bcc:	57878793          	addi	a5,a5,1400 # 80006140 <kernelvec>
    80002bd0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	1e2080e7          	jalr	482(ra) # 80001db6 <myproc>
    80002bdc:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bde:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002be0:	14102773          	csrr	a4,sepc
    80002be4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002be6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002bea:	47a1                	li	a5,8
    80002bec:	04f71c63          	bne	a4,a5,80002c44 <usertrap+0x92>
    if(p->killed)
    80002bf0:	5d1c                	lw	a5,56(a0)
    80002bf2:	e3b9                	bnez	a5,80002c38 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002bf4:	70b8                	ld	a4,96(s1)
    80002bf6:	6f1c                	ld	a5,24(a4)
    80002bf8:	0791                	addi	a5,a5,4
    80002bfa:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bfc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c00:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c04:	10079073          	csrw	sstatus,a5
    syscall();
    80002c08:	00000097          	auipc	ra,0x0
    80002c0c:	2e0080e7          	jalr	736(ra) # 80002ee8 <syscall>
  if(p->killed)
    80002c10:	5c9c                	lw	a5,56(s1)
    80002c12:	ebc1                	bnez	a5,80002ca2 <usertrap+0xf0>
  usertrapret();
    80002c14:	00000097          	auipc	ra,0x0
    80002c18:	e18080e7          	jalr	-488(ra) # 80002a2c <usertrapret>
}
    80002c1c:	60e2                	ld	ra,24(sp)
    80002c1e:	6442                	ld	s0,16(sp)
    80002c20:	64a2                	ld	s1,8(sp)
    80002c22:	6902                	ld	s2,0(sp)
    80002c24:	6105                	addi	sp,sp,32
    80002c26:	8082                	ret
    panic("usertrap: not from user mode");
    80002c28:	00005517          	auipc	a0,0x5
    80002c2c:	76850513          	addi	a0,a0,1896 # 80008390 <states.1712+0x50>
    80002c30:	ffffe097          	auipc	ra,0xffffe
    80002c34:	920080e7          	jalr	-1760(ra) # 80000550 <panic>
      exit(-1);
    80002c38:	557d                	li	a0,-1
    80002c3a:	00000097          	auipc	ra,0x0
    80002c3e:	846080e7          	jalr	-1978(ra) # 80002480 <exit>
    80002c42:	bf4d                	j	80002bf4 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002c44:	00000097          	auipc	ra,0x0
    80002c48:	ecc080e7          	jalr	-308(ra) # 80002b10 <devintr>
    80002c4c:	892a                	mv	s2,a0
    80002c4e:	c501                	beqz	a0,80002c56 <usertrap+0xa4>
  if(p->killed)
    80002c50:	5c9c                	lw	a5,56(s1)
    80002c52:	c3a1                	beqz	a5,80002c92 <usertrap+0xe0>
    80002c54:	a815                	j	80002c88 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c56:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c5a:	40b0                	lw	a2,64(s1)
    80002c5c:	00005517          	auipc	a0,0x5
    80002c60:	75450513          	addi	a0,a0,1876 # 800083b0 <states.1712+0x70>
    80002c64:	ffffe097          	auipc	ra,0xffffe
    80002c68:	936080e7          	jalr	-1738(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c6c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c70:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c74:	00005517          	auipc	a0,0x5
    80002c78:	76c50513          	addi	a0,a0,1900 # 800083e0 <states.1712+0xa0>
    80002c7c:	ffffe097          	auipc	ra,0xffffe
    80002c80:	91e080e7          	jalr	-1762(ra) # 8000059a <printf>
    p->killed = 1;
    80002c84:	4785                	li	a5,1
    80002c86:	dc9c                	sw	a5,56(s1)
    exit(-1);
    80002c88:	557d                	li	a0,-1
    80002c8a:	fffff097          	auipc	ra,0xfffff
    80002c8e:	7f6080e7          	jalr	2038(ra) # 80002480 <exit>
  if(which_dev == 2)
    80002c92:	4789                	li	a5,2
    80002c94:	f8f910e3          	bne	s2,a5,80002c14 <usertrap+0x62>
    yield();
    80002c98:	00000097          	auipc	ra,0x0
    80002c9c:	8f2080e7          	jalr	-1806(ra) # 8000258a <yield>
    80002ca0:	bf95                	j	80002c14 <usertrap+0x62>
  int which_dev = 0;
    80002ca2:	4901                	li	s2,0
    80002ca4:	b7d5                	j	80002c88 <usertrap+0xd6>

0000000080002ca6 <kerneltrap>:
{
    80002ca6:	7179                	addi	sp,sp,-48
    80002ca8:	f406                	sd	ra,40(sp)
    80002caa:	f022                	sd	s0,32(sp)
    80002cac:	ec26                	sd	s1,24(sp)
    80002cae:	e84a                	sd	s2,16(sp)
    80002cb0:	e44e                	sd	s3,8(sp)
    80002cb2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cb4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cb8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cbc:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002cc0:	1004f793          	andi	a5,s1,256
    80002cc4:	cb85                	beqz	a5,80002cf4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cc6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002cca:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ccc:	ef85                	bnez	a5,80002d04 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002cce:	00000097          	auipc	ra,0x0
    80002cd2:	e42080e7          	jalr	-446(ra) # 80002b10 <devintr>
    80002cd6:	cd1d                	beqz	a0,80002d14 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cd8:	4789                	li	a5,2
    80002cda:	06f50a63          	beq	a0,a5,80002d4e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cde:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ce2:	10049073          	csrw	sstatus,s1
}
    80002ce6:	70a2                	ld	ra,40(sp)
    80002ce8:	7402                	ld	s0,32(sp)
    80002cea:	64e2                	ld	s1,24(sp)
    80002cec:	6942                	ld	s2,16(sp)
    80002cee:	69a2                	ld	s3,8(sp)
    80002cf0:	6145                	addi	sp,sp,48
    80002cf2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002cf4:	00005517          	auipc	a0,0x5
    80002cf8:	70c50513          	addi	a0,a0,1804 # 80008400 <states.1712+0xc0>
    80002cfc:	ffffe097          	auipc	ra,0xffffe
    80002d00:	854080e7          	jalr	-1964(ra) # 80000550 <panic>
    panic("kerneltrap: interrupts enabled");
    80002d04:	00005517          	auipc	a0,0x5
    80002d08:	72450513          	addi	a0,a0,1828 # 80008428 <states.1712+0xe8>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	844080e7          	jalr	-1980(ra) # 80000550 <panic>
    printf("scause %p\n", scause);
    80002d14:	85ce                	mv	a1,s3
    80002d16:	00005517          	auipc	a0,0x5
    80002d1a:	73250513          	addi	a0,a0,1842 # 80008448 <states.1712+0x108>
    80002d1e:	ffffe097          	auipc	ra,0xffffe
    80002d22:	87c080e7          	jalr	-1924(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d26:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d2a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d2e:	00005517          	auipc	a0,0x5
    80002d32:	72a50513          	addi	a0,a0,1834 # 80008458 <states.1712+0x118>
    80002d36:	ffffe097          	auipc	ra,0xffffe
    80002d3a:	864080e7          	jalr	-1948(ra) # 8000059a <printf>
    panic("kerneltrap");
    80002d3e:	00005517          	auipc	a0,0x5
    80002d42:	73250513          	addi	a0,a0,1842 # 80008470 <states.1712+0x130>
    80002d46:	ffffe097          	auipc	ra,0xffffe
    80002d4a:	80a080e7          	jalr	-2038(ra) # 80000550 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d4e:	fffff097          	auipc	ra,0xfffff
    80002d52:	068080e7          	jalr	104(ra) # 80001db6 <myproc>
    80002d56:	d541                	beqz	a0,80002cde <kerneltrap+0x38>
    80002d58:	fffff097          	auipc	ra,0xfffff
    80002d5c:	05e080e7          	jalr	94(ra) # 80001db6 <myproc>
    80002d60:	5118                	lw	a4,32(a0)
    80002d62:	478d                	li	a5,3
    80002d64:	f6f71de3          	bne	a4,a5,80002cde <kerneltrap+0x38>
    yield();
    80002d68:	00000097          	auipc	ra,0x0
    80002d6c:	822080e7          	jalr	-2014(ra) # 8000258a <yield>
    80002d70:	b7bd                	j	80002cde <kerneltrap+0x38>

0000000080002d72 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d72:	1101                	addi	sp,sp,-32
    80002d74:	ec06                	sd	ra,24(sp)
    80002d76:	e822                	sd	s0,16(sp)
    80002d78:	e426                	sd	s1,8(sp)
    80002d7a:	1000                	addi	s0,sp,32
    80002d7c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d7e:	fffff097          	auipc	ra,0xfffff
    80002d82:	038080e7          	jalr	56(ra) # 80001db6 <myproc>
  switch (n) {
    80002d86:	4795                	li	a5,5
    80002d88:	0497e163          	bltu	a5,s1,80002dca <argraw+0x58>
    80002d8c:	048a                	slli	s1,s1,0x2
    80002d8e:	00005717          	auipc	a4,0x5
    80002d92:	71a70713          	addi	a4,a4,1818 # 800084a8 <states.1712+0x168>
    80002d96:	94ba                	add	s1,s1,a4
    80002d98:	409c                	lw	a5,0(s1)
    80002d9a:	97ba                	add	a5,a5,a4
    80002d9c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d9e:	713c                	ld	a5,96(a0)
    80002da0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002da2:	60e2                	ld	ra,24(sp)
    80002da4:	6442                	ld	s0,16(sp)
    80002da6:	64a2                	ld	s1,8(sp)
    80002da8:	6105                	addi	sp,sp,32
    80002daa:	8082                	ret
    return p->trapframe->a1;
    80002dac:	713c                	ld	a5,96(a0)
    80002dae:	7fa8                	ld	a0,120(a5)
    80002db0:	bfcd                	j	80002da2 <argraw+0x30>
    return p->trapframe->a2;
    80002db2:	713c                	ld	a5,96(a0)
    80002db4:	63c8                	ld	a0,128(a5)
    80002db6:	b7f5                	j	80002da2 <argraw+0x30>
    return p->trapframe->a3;
    80002db8:	713c                	ld	a5,96(a0)
    80002dba:	67c8                	ld	a0,136(a5)
    80002dbc:	b7dd                	j	80002da2 <argraw+0x30>
    return p->trapframe->a4;
    80002dbe:	713c                	ld	a5,96(a0)
    80002dc0:	6bc8                	ld	a0,144(a5)
    80002dc2:	b7c5                	j	80002da2 <argraw+0x30>
    return p->trapframe->a5;
    80002dc4:	713c                	ld	a5,96(a0)
    80002dc6:	6fc8                	ld	a0,152(a5)
    80002dc8:	bfe9                	j	80002da2 <argraw+0x30>
  panic("argraw");
    80002dca:	00005517          	auipc	a0,0x5
    80002dce:	6b650513          	addi	a0,a0,1718 # 80008480 <states.1712+0x140>
    80002dd2:	ffffd097          	auipc	ra,0xffffd
    80002dd6:	77e080e7          	jalr	1918(ra) # 80000550 <panic>

0000000080002dda <fetchaddr>:
{
    80002dda:	1101                	addi	sp,sp,-32
    80002ddc:	ec06                	sd	ra,24(sp)
    80002dde:	e822                	sd	s0,16(sp)
    80002de0:	e426                	sd	s1,8(sp)
    80002de2:	e04a                	sd	s2,0(sp)
    80002de4:	1000                	addi	s0,sp,32
    80002de6:	84aa                	mv	s1,a0
    80002de8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	fcc080e7          	jalr	-52(ra) # 80001db6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002df2:	693c                	ld	a5,80(a0)
    80002df4:	02f4f863          	bgeu	s1,a5,80002e24 <fetchaddr+0x4a>
    80002df8:	00848713          	addi	a4,s1,8
    80002dfc:	02e7e663          	bltu	a5,a4,80002e28 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e00:	46a1                	li	a3,8
    80002e02:	8626                	mv	a2,s1
    80002e04:	85ca                	mv	a1,s2
    80002e06:	6d28                	ld	a0,88(a0)
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	d2e080e7          	jalr	-722(ra) # 80001b36 <copyin>
    80002e10:	00a03533          	snez	a0,a0
    80002e14:	40a00533          	neg	a0,a0
}
    80002e18:	60e2                	ld	ra,24(sp)
    80002e1a:	6442                	ld	s0,16(sp)
    80002e1c:	64a2                	ld	s1,8(sp)
    80002e1e:	6902                	ld	s2,0(sp)
    80002e20:	6105                	addi	sp,sp,32
    80002e22:	8082                	ret
    return -1;
    80002e24:	557d                	li	a0,-1
    80002e26:	bfcd                	j	80002e18 <fetchaddr+0x3e>
    80002e28:	557d                	li	a0,-1
    80002e2a:	b7fd                	j	80002e18 <fetchaddr+0x3e>

0000000080002e2c <fetchstr>:
{
    80002e2c:	7179                	addi	sp,sp,-48
    80002e2e:	f406                	sd	ra,40(sp)
    80002e30:	f022                	sd	s0,32(sp)
    80002e32:	ec26                	sd	s1,24(sp)
    80002e34:	e84a                	sd	s2,16(sp)
    80002e36:	e44e                	sd	s3,8(sp)
    80002e38:	1800                	addi	s0,sp,48
    80002e3a:	892a                	mv	s2,a0
    80002e3c:	84ae                	mv	s1,a1
    80002e3e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e40:	fffff097          	auipc	ra,0xfffff
    80002e44:	f76080e7          	jalr	-138(ra) # 80001db6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e48:	86ce                	mv	a3,s3
    80002e4a:	864a                	mv	a2,s2
    80002e4c:	85a6                	mv	a1,s1
    80002e4e:	6d28                	ld	a0,88(a0)
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	d72080e7          	jalr	-654(ra) # 80001bc2 <copyinstr>
  if(err < 0)
    80002e58:	00054763          	bltz	a0,80002e66 <fetchstr+0x3a>
  return strlen(buf);
    80002e5c:	8526                	mv	a0,s1
    80002e5e:	ffffe097          	auipc	ra,0xffffe
    80002e62:	478080e7          	jalr	1144(ra) # 800012d6 <strlen>
}
    80002e66:	70a2                	ld	ra,40(sp)
    80002e68:	7402                	ld	s0,32(sp)
    80002e6a:	64e2                	ld	s1,24(sp)
    80002e6c:	6942                	ld	s2,16(sp)
    80002e6e:	69a2                	ld	s3,8(sp)
    80002e70:	6145                	addi	sp,sp,48
    80002e72:	8082                	ret

0000000080002e74 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e74:	1101                	addi	sp,sp,-32
    80002e76:	ec06                	sd	ra,24(sp)
    80002e78:	e822                	sd	s0,16(sp)
    80002e7a:	e426                	sd	s1,8(sp)
    80002e7c:	1000                	addi	s0,sp,32
    80002e7e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e80:	00000097          	auipc	ra,0x0
    80002e84:	ef2080e7          	jalr	-270(ra) # 80002d72 <argraw>
    80002e88:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e8a:	4501                	li	a0,0
    80002e8c:	60e2                	ld	ra,24(sp)
    80002e8e:	6442                	ld	s0,16(sp)
    80002e90:	64a2                	ld	s1,8(sp)
    80002e92:	6105                	addi	sp,sp,32
    80002e94:	8082                	ret

0000000080002e96 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e96:	1101                	addi	sp,sp,-32
    80002e98:	ec06                	sd	ra,24(sp)
    80002e9a:	e822                	sd	s0,16(sp)
    80002e9c:	e426                	sd	s1,8(sp)
    80002e9e:	1000                	addi	s0,sp,32
    80002ea0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ea2:	00000097          	auipc	ra,0x0
    80002ea6:	ed0080e7          	jalr	-304(ra) # 80002d72 <argraw>
    80002eaa:	e088                	sd	a0,0(s1)
  return 0;
}
    80002eac:	4501                	li	a0,0
    80002eae:	60e2                	ld	ra,24(sp)
    80002eb0:	6442                	ld	s0,16(sp)
    80002eb2:	64a2                	ld	s1,8(sp)
    80002eb4:	6105                	addi	sp,sp,32
    80002eb6:	8082                	ret

0000000080002eb8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002eb8:	1101                	addi	sp,sp,-32
    80002eba:	ec06                	sd	ra,24(sp)
    80002ebc:	e822                	sd	s0,16(sp)
    80002ebe:	e426                	sd	s1,8(sp)
    80002ec0:	e04a                	sd	s2,0(sp)
    80002ec2:	1000                	addi	s0,sp,32
    80002ec4:	84ae                	mv	s1,a1
    80002ec6:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ec8:	00000097          	auipc	ra,0x0
    80002ecc:	eaa080e7          	jalr	-342(ra) # 80002d72 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ed0:	864a                	mv	a2,s2
    80002ed2:	85a6                	mv	a1,s1
    80002ed4:	00000097          	auipc	ra,0x0
    80002ed8:	f58080e7          	jalr	-168(ra) # 80002e2c <fetchstr>
}
    80002edc:	60e2                	ld	ra,24(sp)
    80002ede:	6442                	ld	s0,16(sp)
    80002ee0:	64a2                	ld	s1,8(sp)
    80002ee2:	6902                	ld	s2,0(sp)
    80002ee4:	6105                	addi	sp,sp,32
    80002ee6:	8082                	ret

0000000080002ee8 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002ee8:	1101                	addi	sp,sp,-32
    80002eea:	ec06                	sd	ra,24(sp)
    80002eec:	e822                	sd	s0,16(sp)
    80002eee:	e426                	sd	s1,8(sp)
    80002ef0:	e04a                	sd	s2,0(sp)
    80002ef2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ef4:	fffff097          	auipc	ra,0xfffff
    80002ef8:	ec2080e7          	jalr	-318(ra) # 80001db6 <myproc>
    80002efc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002efe:	06053903          	ld	s2,96(a0)
    80002f02:	0a893783          	ld	a5,168(s2)
    80002f06:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f0a:	37fd                	addiw	a5,a5,-1
    80002f0c:	4751                	li	a4,20
    80002f0e:	00f76f63          	bltu	a4,a5,80002f2c <syscall+0x44>
    80002f12:	00369713          	slli	a4,a3,0x3
    80002f16:	00005797          	auipc	a5,0x5
    80002f1a:	5aa78793          	addi	a5,a5,1450 # 800084c0 <syscalls>
    80002f1e:	97ba                	add	a5,a5,a4
    80002f20:	639c                	ld	a5,0(a5)
    80002f22:	c789                	beqz	a5,80002f2c <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002f24:	9782                	jalr	a5
    80002f26:	06a93823          	sd	a0,112(s2)
    80002f2a:	a839                	j	80002f48 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f2c:	16048613          	addi	a2,s1,352
    80002f30:	40ac                	lw	a1,64(s1)
    80002f32:	00005517          	auipc	a0,0x5
    80002f36:	55650513          	addi	a0,a0,1366 # 80008488 <states.1712+0x148>
    80002f3a:	ffffd097          	auipc	ra,0xffffd
    80002f3e:	660080e7          	jalr	1632(ra) # 8000059a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f42:	70bc                	ld	a5,96(s1)
    80002f44:	577d                	li	a4,-1
    80002f46:	fbb8                	sd	a4,112(a5)
  }
}
    80002f48:	60e2                	ld	ra,24(sp)
    80002f4a:	6442                	ld	s0,16(sp)
    80002f4c:	64a2                	ld	s1,8(sp)
    80002f4e:	6902                	ld	s2,0(sp)
    80002f50:	6105                	addi	sp,sp,32
    80002f52:	8082                	ret

0000000080002f54 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f54:	1101                	addi	sp,sp,-32
    80002f56:	ec06                	sd	ra,24(sp)
    80002f58:	e822                	sd	s0,16(sp)
    80002f5a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f5c:	fec40593          	addi	a1,s0,-20
    80002f60:	4501                	li	a0,0
    80002f62:	00000097          	auipc	ra,0x0
    80002f66:	f12080e7          	jalr	-238(ra) # 80002e74 <argint>
    return -1;
    80002f6a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f6c:	00054963          	bltz	a0,80002f7e <sys_exit+0x2a>
  exit(n);
    80002f70:	fec42503          	lw	a0,-20(s0)
    80002f74:	fffff097          	auipc	ra,0xfffff
    80002f78:	50c080e7          	jalr	1292(ra) # 80002480 <exit>
  return 0;  // not reached
    80002f7c:	4781                	li	a5,0
}
    80002f7e:	853e                	mv	a0,a5
    80002f80:	60e2                	ld	ra,24(sp)
    80002f82:	6442                	ld	s0,16(sp)
    80002f84:	6105                	addi	sp,sp,32
    80002f86:	8082                	ret

0000000080002f88 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f88:	1141                	addi	sp,sp,-16
    80002f8a:	e406                	sd	ra,8(sp)
    80002f8c:	e022                	sd	s0,0(sp)
    80002f8e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f90:	fffff097          	auipc	ra,0xfffff
    80002f94:	e26080e7          	jalr	-474(ra) # 80001db6 <myproc>
}
    80002f98:	4128                	lw	a0,64(a0)
    80002f9a:	60a2                	ld	ra,8(sp)
    80002f9c:	6402                	ld	s0,0(sp)
    80002f9e:	0141                	addi	sp,sp,16
    80002fa0:	8082                	ret

0000000080002fa2 <sys_fork>:

uint64
sys_fork(void)
{
    80002fa2:	1141                	addi	sp,sp,-16
    80002fa4:	e406                	sd	ra,8(sp)
    80002fa6:	e022                	sd	s0,0(sp)
    80002fa8:	0800                	addi	s0,sp,16
  return fork();
    80002faa:	fffff097          	auipc	ra,0xfffff
    80002fae:	1cc080e7          	jalr	460(ra) # 80002176 <fork>
}
    80002fb2:	60a2                	ld	ra,8(sp)
    80002fb4:	6402                	ld	s0,0(sp)
    80002fb6:	0141                	addi	sp,sp,16
    80002fb8:	8082                	ret

0000000080002fba <sys_wait>:

uint64
sys_wait(void)
{
    80002fba:	1101                	addi	sp,sp,-32
    80002fbc:	ec06                	sd	ra,24(sp)
    80002fbe:	e822                	sd	s0,16(sp)
    80002fc0:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002fc2:	fe840593          	addi	a1,s0,-24
    80002fc6:	4501                	li	a0,0
    80002fc8:	00000097          	auipc	ra,0x0
    80002fcc:	ece080e7          	jalr	-306(ra) # 80002e96 <argaddr>
    80002fd0:	87aa                	mv	a5,a0
    return -1;
    80002fd2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fd4:	0007c863          	bltz	a5,80002fe4 <sys_wait+0x2a>
  return wait(p);
    80002fd8:	fe843503          	ld	a0,-24(s0)
    80002fdc:	fffff097          	auipc	ra,0xfffff
    80002fe0:	668080e7          	jalr	1640(ra) # 80002644 <wait>
}
    80002fe4:	60e2                	ld	ra,24(sp)
    80002fe6:	6442                	ld	s0,16(sp)
    80002fe8:	6105                	addi	sp,sp,32
    80002fea:	8082                	ret

0000000080002fec <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002fec:	7179                	addi	sp,sp,-48
    80002fee:	f406                	sd	ra,40(sp)
    80002ff0:	f022                	sd	s0,32(sp)
    80002ff2:	ec26                	sd	s1,24(sp)
    80002ff4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ff6:	fdc40593          	addi	a1,s0,-36
    80002ffa:	4501                	li	a0,0
    80002ffc:	00000097          	auipc	ra,0x0
    80003000:	e78080e7          	jalr	-392(ra) # 80002e74 <argint>
    80003004:	87aa                	mv	a5,a0
    return -1;
    80003006:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003008:	0207c063          	bltz	a5,80003028 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	daa080e7          	jalr	-598(ra) # 80001db6 <myproc>
    80003014:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80003016:	fdc42503          	lw	a0,-36(s0)
    8000301a:	fffff097          	auipc	ra,0xfffff
    8000301e:	0e8080e7          	jalr	232(ra) # 80002102 <growproc>
    80003022:	00054863          	bltz	a0,80003032 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003026:	8526                	mv	a0,s1
}
    80003028:	70a2                	ld	ra,40(sp)
    8000302a:	7402                	ld	s0,32(sp)
    8000302c:	64e2                	ld	s1,24(sp)
    8000302e:	6145                	addi	sp,sp,48
    80003030:	8082                	ret
    return -1;
    80003032:	557d                	li	a0,-1
    80003034:	bfd5                	j	80003028 <sys_sbrk+0x3c>

0000000080003036 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003036:	7139                	addi	sp,sp,-64
    80003038:	fc06                	sd	ra,56(sp)
    8000303a:	f822                	sd	s0,48(sp)
    8000303c:	f426                	sd	s1,40(sp)
    8000303e:	f04a                	sd	s2,32(sp)
    80003040:	ec4e                	sd	s3,24(sp)
    80003042:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003044:	fcc40593          	addi	a1,s0,-52
    80003048:	4501                	li	a0,0
    8000304a:	00000097          	auipc	ra,0x0
    8000304e:	e2a080e7          	jalr	-470(ra) # 80002e74 <argint>
    return -1;
    80003052:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003054:	06054563          	bltz	a0,800030be <sys_sleep+0x88>
  acquire(&tickslock);
    80003058:	00015517          	auipc	a0,0x15
    8000305c:	39050513          	addi	a0,a0,912 # 800183e8 <tickslock>
    80003060:	ffffe097          	auipc	ra,0xffffe
    80003064:	d0e080e7          	jalr	-754(ra) # 80000d6e <acquire>
  ticks0 = ticks;
    80003068:	00006917          	auipc	s2,0x6
    8000306c:	fb892903          	lw	s2,-72(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80003070:	fcc42783          	lw	a5,-52(s0)
    80003074:	cf85                	beqz	a5,800030ac <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003076:	00015997          	auipc	s3,0x15
    8000307a:	37298993          	addi	s3,s3,882 # 800183e8 <tickslock>
    8000307e:	00006497          	auipc	s1,0x6
    80003082:	fa248493          	addi	s1,s1,-94 # 80009020 <ticks>
    if(myproc()->killed){
    80003086:	fffff097          	auipc	ra,0xfffff
    8000308a:	d30080e7          	jalr	-720(ra) # 80001db6 <myproc>
    8000308e:	5d1c                	lw	a5,56(a0)
    80003090:	ef9d                	bnez	a5,800030ce <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003092:	85ce                	mv	a1,s3
    80003094:	8526                	mv	a0,s1
    80003096:	fffff097          	auipc	ra,0xfffff
    8000309a:	530080e7          	jalr	1328(ra) # 800025c6 <sleep>
  while(ticks - ticks0 < n){
    8000309e:	409c                	lw	a5,0(s1)
    800030a0:	412787bb          	subw	a5,a5,s2
    800030a4:	fcc42703          	lw	a4,-52(s0)
    800030a8:	fce7efe3          	bltu	a5,a4,80003086 <sys_sleep+0x50>
  }
  release(&tickslock);
    800030ac:	00015517          	auipc	a0,0x15
    800030b0:	33c50513          	addi	a0,a0,828 # 800183e8 <tickslock>
    800030b4:	ffffe097          	auipc	ra,0xffffe
    800030b8:	d8a080e7          	jalr	-630(ra) # 80000e3e <release>
  return 0;
    800030bc:	4781                	li	a5,0
}
    800030be:	853e                	mv	a0,a5
    800030c0:	70e2                	ld	ra,56(sp)
    800030c2:	7442                	ld	s0,48(sp)
    800030c4:	74a2                	ld	s1,40(sp)
    800030c6:	7902                	ld	s2,32(sp)
    800030c8:	69e2                	ld	s3,24(sp)
    800030ca:	6121                	addi	sp,sp,64
    800030cc:	8082                	ret
      release(&tickslock);
    800030ce:	00015517          	auipc	a0,0x15
    800030d2:	31a50513          	addi	a0,a0,794 # 800183e8 <tickslock>
    800030d6:	ffffe097          	auipc	ra,0xffffe
    800030da:	d68080e7          	jalr	-664(ra) # 80000e3e <release>
      return -1;
    800030de:	57fd                	li	a5,-1
    800030e0:	bff9                	j	800030be <sys_sleep+0x88>

00000000800030e2 <sys_kill>:

uint64
sys_kill(void)
{
    800030e2:	1101                	addi	sp,sp,-32
    800030e4:	ec06                	sd	ra,24(sp)
    800030e6:	e822                	sd	s0,16(sp)
    800030e8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030ea:	fec40593          	addi	a1,s0,-20
    800030ee:	4501                	li	a0,0
    800030f0:	00000097          	auipc	ra,0x0
    800030f4:	d84080e7          	jalr	-636(ra) # 80002e74 <argint>
    800030f8:	87aa                	mv	a5,a0
    return -1;
    800030fa:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030fc:	0007c863          	bltz	a5,8000310c <sys_kill+0x2a>
  return kill(pid);
    80003100:	fec42503          	lw	a0,-20(s0)
    80003104:	fffff097          	auipc	ra,0xfffff
    80003108:	6b2080e7          	jalr	1714(ra) # 800027b6 <kill>
}
    8000310c:	60e2                	ld	ra,24(sp)
    8000310e:	6442                	ld	s0,16(sp)
    80003110:	6105                	addi	sp,sp,32
    80003112:	8082                	ret

0000000080003114 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003114:	1101                	addi	sp,sp,-32
    80003116:	ec06                	sd	ra,24(sp)
    80003118:	e822                	sd	s0,16(sp)
    8000311a:	e426                	sd	s1,8(sp)
    8000311c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000311e:	00015517          	auipc	a0,0x15
    80003122:	2ca50513          	addi	a0,a0,714 # 800183e8 <tickslock>
    80003126:	ffffe097          	auipc	ra,0xffffe
    8000312a:	c48080e7          	jalr	-952(ra) # 80000d6e <acquire>
  xticks = ticks;
    8000312e:	00006497          	auipc	s1,0x6
    80003132:	ef24a483          	lw	s1,-270(s1) # 80009020 <ticks>
  release(&tickslock);
    80003136:	00015517          	auipc	a0,0x15
    8000313a:	2b250513          	addi	a0,a0,690 # 800183e8 <tickslock>
    8000313e:	ffffe097          	auipc	ra,0xffffe
    80003142:	d00080e7          	jalr	-768(ra) # 80000e3e <release>
  return xticks;
}
    80003146:	02049513          	slli	a0,s1,0x20
    8000314a:	9101                	srli	a0,a0,0x20
    8000314c:	60e2                	ld	ra,24(sp)
    8000314e:	6442                	ld	s0,16(sp)
    80003150:	64a2                	ld	s1,8(sp)
    80003152:	6105                	addi	sp,sp,32
    80003154:	8082                	ret

0000000080003156 <binit>:
  struct spinlock bufmap_locks[NBUFMAP_BUCKET];// 桶的锁，用于保护并发访问桶的操作
} bcache;//块缓存

void
binit(void)
{
    80003156:	7179                	addi	sp,sp,-48
    80003158:	f406                	sd	ra,40(sp)
    8000315a:	f022                	sd	s0,32(sp)
    8000315c:	ec26                	sd	s1,24(sp)
    8000315e:	e84a                	sd	s2,16(sp)
    80003160:	e44e                	sd	s3,8(sp)
    80003162:	e052                	sd	s4,0(sp)
    80003164:	1800                	addi	s0,sp,48
  // 初始化bufmap
  for(int i=0;i<NBUFMAP_BUCKET;i++) {
    80003166:	00021917          	auipc	s2,0x21
    8000316a:	d8a90913          	addi	s2,s2,-630 # 80023ef0 <bcache+0xbae8>
    8000316e:	0001d497          	auipc	s1,0x1d
    80003172:	55a48493          	addi	s1,s1,1370 # 800206c8 <bcache+0x82c0>
    80003176:	00021a17          	auipc	s4,0x21
    8000317a:	dcaa0a13          	addi	s4,s4,-566 # 80023f40 <bcache+0xbb38>
    initlock(&bcache.bufmap_locks[i], "bcache_bufmap");// 初始化bufmap的锁
    8000317e:	00005997          	auipc	s3,0x5
    80003182:	3f298993          	addi	s3,s3,1010 # 80008570 <syscalls+0xb0>
    80003186:	85ce                	mv	a1,s3
    80003188:	854a                	mv	a0,s2
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	d60080e7          	jalr	-672(ra) # 80000eea <initlock>
    bcache.bufmap[i].next = 0;// 将bufmap的next字段初始化为0
    80003192:	0004b023          	sd	zero,0(s1)
  for(int i=0;i<NBUFMAP_BUCKET;i++) {
    80003196:	02090913          	addi	s2,s2,32
    8000319a:	45848493          	addi	s1,s1,1112
    8000319e:	ff4494e3          	bne	s1,s4,80003186 <binit+0x30>
    800031a2:	00015497          	auipc	s1,0x15
    800031a6:	27648493          	addi	s1,s1,630 # 80018418 <bcache+0x10>
    800031aa:	00015997          	auipc	s3,0x15
    800031ae:	25e98993          	addi	s3,s3,606 # 80018408 <bcache>
    800031b2:	67a1                	lui	a5,0x8
    800031b4:	26078793          	addi	a5,a5,608 # 8260 <_entry-0x7fff7da0>
    800031b8:	99be                	add	s3,s3,a5
  }

   // 初始化buffers
  for(int i=0;i<NBUF;i++){
    struct buf *b = &bcache.buf[i];
    initsleeplock(&b->lock, "buffer");
    800031ba:	00005a17          	auipc	s4,0x5
    800031be:	3c6a0a13          	addi	s4,s4,966 # 80008580 <syscalls+0xc0>
    b->lastuse = 0; // 将buffer的lastuse字段初始化为0
    b->refcnt = 0;
    // put all the buffers into bufmap[0]
    b->next = bcache.bufmap[0].next;
    800031c2:	0001d917          	auipc	s2,0x1d
    800031c6:	24690913          	addi	s2,s2,582 # 80020408 <bcache+0x8000>
    initsleeplock(&b->lock, "buffer");
    800031ca:	85d2                	mv	a1,s4
    800031cc:	8526                	mv	a0,s1
    800031ce:	00001097          	auipc	ra,0x1
    800031d2:	6f2080e7          	jalr	1778(ra) # 800048c0 <initsleeplock>
    b->lastuse = 0; // 将buffer的lastuse字段初始化为0
    800031d6:	0204ae23          	sw	zero,60(s1)
    b->refcnt = 0;
    800031da:	0204ac23          	sw	zero,56(s1)
    b->next = bcache.bufmap[0].next;
    800031de:	2c093783          	ld	a5,704(s2)
    800031e2:	e0bc                	sd	a5,64(s1)
    bcache.bufmap[0].next = b;
    800031e4:	ff048793          	addi	a5,s1,-16
    800031e8:	2cf93023          	sd	a5,704(s2)
  for(int i=0;i<NBUF;i++){
    800031ec:	45848493          	addi	s1,s1,1112
    800031f0:	fd349de3          	bne	s1,s3,800031ca <binit+0x74>
  }

  initlock(&bcache.eviction_lock, "bcache_eviction");
    800031f4:	00005597          	auipc	a1,0x5
    800031f8:	39458593          	addi	a1,a1,916 # 80008588 <syscalls+0xc8>
    800031fc:	0001d517          	auipc	a0,0x1d
    80003200:	45c50513          	addi	a0,a0,1116 # 80020658 <bcache+0x8250>
    80003204:	ffffe097          	auipc	ra,0xffffe
    80003208:	ce6080e7          	jalr	-794(ra) # 80000eea <initlock>
}
    8000320c:	70a2                	ld	ra,40(sp)
    8000320e:	7402                	ld	s0,32(sp)
    80003210:	64e2                	ld	s1,24(sp)
    80003212:	6942                	ld	s2,16(sp)
    80003214:	69a2                	ld	s3,8(sp)
    80003216:	6a02                	ld	s4,0(sp)
    80003218:	6145                	addi	sp,sp,48
    8000321a:	8082                	ret

000000008000321c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000321c:	7119                	addi	sp,sp,-128
    8000321e:	fc86                	sd	ra,120(sp)
    80003220:	f8a2                	sd	s0,112(sp)
    80003222:	f4a6                	sd	s1,104(sp)
    80003224:	f0ca                	sd	s2,96(sp)
    80003226:	ecce                	sd	s3,88(sp)
    80003228:	e8d2                	sd	s4,80(sp)
    8000322a:	e4d6                	sd	s5,72(sp)
    8000322c:	e0da                	sd	s6,64(sp)
    8000322e:	fc5e                	sd	s7,56(sp)
    80003230:	f862                	sd	s8,48(sp)
    80003232:	f466                	sd	s9,40(sp)
    80003234:	f06a                	sd	s10,32(sp)
    80003236:	ec6e                	sd	s11,24(sp)
    80003238:	0100                	addi	s0,sp,128
    8000323a:	8aaa                	mv	s5,a0
    8000323c:	8a2e                	mv	s4,a1
  uint key = BUFMAP_HASH(dev, blockno);// 根据设备和块号计算哈希值，确定bufmap的索引位置
    8000323e:	01b5199b          	slliw	s3,a0,0x1b
    80003242:	0135e9b3          	or	s3,a1,s3
    80003246:	47b5                	li	a5,13
    80003248:	02f9f9bb          	remuw	s3,s3,a5
    8000324c:	00098d1b          	sext.w	s10,s3
  acquire(&bcache.bufmap_locks[key]);// 获取bufmap对应的锁
    80003250:	02099b13          	slli	s6,s3,0x20
    80003254:	020b5b13          	srli	s6,s6,0x20
    80003258:	5d7b0913          	addi	s2,s6,1495
    8000325c:	0916                	slli	s2,s2,0x5
    8000325e:	0921                	addi	s2,s2,8
    80003260:	00015497          	auipc	s1,0x15
    80003264:	1a848493          	addi	s1,s1,424 # 80018408 <bcache>
    80003268:	9926                	add	s2,s2,s1
    8000326a:	854a                	mv	a0,s2
    8000326c:	ffffe097          	auipc	ra,0xffffe
    80003270:	b02080e7          	jalr	-1278(ra) # 80000d6e <acquire>
  for(b = bcache.bufmap[key].next; b; b = b->next){
    80003274:	45800793          	li	a5,1112
    80003278:	02fb0b33          	mul	s6,s6,a5
    8000327c:	94da                	add	s1,s1,s6
    8000327e:	67a1                	lui	a5,0x8
    80003280:	94be                	add	s1,s1,a5
    80003282:	2c04bb83          	ld	s7,704(s1)
    80003286:	060b9263          	bnez	s7,800032ea <bread+0xce>
  release(&bcache.bufmap_locks[key]);// 释放bufmap的锁
    8000328a:	854a                	mv	a0,s2
    8000328c:	ffffe097          	auipc	ra,0xffffe
    80003290:	bb2080e7          	jalr	-1102(ra) # 80000e3e <release>
  acquire(&bcache.eviction_lock);// 获取eviction锁，保护缓冲区的驱逐（eviction）过程
    80003294:	0001d517          	auipc	a0,0x1d
    80003298:	3c450513          	addi	a0,a0,964 # 80020658 <bcache+0x8250>
    8000329c:	ffffe097          	auipc	ra,0xffffe
    800032a0:	ad2080e7          	jalr	-1326(ra) # 80000d6e <acquire>
   for(b = bcache.bufmap[key].next; b; b = b->next){
    800032a4:	02099713          	slli	a4,s3,0x20
    800032a8:	9301                	srli	a4,a4,0x20
    800032aa:	45800793          	li	a5,1112
    800032ae:	02f70733          	mul	a4,a4,a5
    800032b2:	00015797          	auipc	a5,0x15
    800032b6:	15678793          	addi	a5,a5,342 # 80018408 <bcache>
    800032ba:	973e                	add	a4,a4,a5
    800032bc:	67a1                	lui	a5,0x8
    800032be:	97ba                	add	a5,a5,a4
    800032c0:	2c07bb83          	ld	s7,704(a5) # 82c0 <_entry-0x7fff7d40>
    800032c4:	060b9063          	bnez	s7,80003324 <bread+0x108>
    800032c8:	00021c97          	auipc	s9,0x21
    800032cc:	c28c8c93          	addi	s9,s9,-984 # 80023ef0 <bcache+0xbae8>
    800032d0:	0001dc17          	auipc	s8,0x1d
    800032d4:	3a8c0c13          	addi	s8,s8,936 # 80020678 <bcache+0x8270>
{
    800032d8:	4b01                	li	s6,0
    800032da:	54fd                	li	s1,-1
    800032dc:	4b81                	li	s7,0
      if(holding_bucket != -1) release(&bcache.bufmap_locks[holding_bucket]);
    800032de:	5dfd                	li	s11,-1
    800032e0:	a8c1                	j	800033b0 <bread+0x194>
  for(b = bcache.bufmap[key].next; b; b = b->next){
    800032e2:	050bbb83          	ld	s7,80(s7)
    800032e6:	fa0b82e3          	beqz	s7,8000328a <bread+0x6e>
    if(b->dev == dev && b->blockno == blockno){
    800032ea:	008ba783          	lw	a5,8(s7)
    800032ee:	ff579ae3          	bne	a5,s5,800032e2 <bread+0xc6>
    800032f2:	00cba783          	lw	a5,12(s7)
    800032f6:	ff4796e3          	bne	a5,s4,800032e2 <bread+0xc6>
      b->refcnt++;// 引用计数加1
    800032fa:	048ba783          	lw	a5,72(s7)
    800032fe:	2785                	addiw	a5,a5,1
    80003300:	04fba423          	sw	a5,72(s7)
      release(&bcache.bufmap_locks[key]);// 释放bufmap的锁
    80003304:	854a                	mv	a0,s2
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	b38080e7          	jalr	-1224(ra) # 80000e3e <release>
      acquiresleep(&b->lock);// 获取缓冲区的睡眠锁
    8000330e:	010b8513          	addi	a0,s7,16
    80003312:	00001097          	auipc	ra,0x1
    80003316:	5e8080e7          	jalr	1512(ra) # 800048fa <acquiresleep>
      return b;// 返回被锁定的缓冲区
    8000331a:	a215                	j	8000343e <bread+0x222>
   for(b = bcache.bufmap[key].next; b; b = b->next){
    8000331c:	050bbb83          	ld	s7,80(s7)
    80003320:	fa0b84e3          	beqz	s7,800032c8 <bread+0xac>
    if(b->dev == dev && b->blockno == blockno){
    80003324:	008ba783          	lw	a5,8(s7)
    80003328:	ff579ae3          	bne	a5,s5,8000331c <bread+0x100>
    8000332c:	00cba783          	lw	a5,12(s7)
    80003330:	ff4796e3          	bne	a5,s4,8000331c <bread+0x100>
      acquire(&bcache.bufmap_locks[key]); // 获取bufmap锁
    80003334:	854a                	mv	a0,s2
    80003336:	ffffe097          	auipc	ra,0xffffe
    8000333a:	a38080e7          	jalr	-1480(ra) # 80000d6e <acquire>
      b->refcnt++;//引用计数加1
    8000333e:	048ba783          	lw	a5,72(s7)
    80003342:	2785                	addiw	a5,a5,1
    80003344:	04fba423          	sw	a5,72(s7)
      release(&bcache.bufmap_locks[key]);// 释放bufmap的锁
    80003348:	854a                	mv	a0,s2
    8000334a:	ffffe097          	auipc	ra,0xffffe
    8000334e:	af4080e7          	jalr	-1292(ra) # 80000e3e <release>
      release(&bcache.eviction_lock);// 释放eviction锁
    80003352:	0001d517          	auipc	a0,0x1d
    80003356:	30650513          	addi	a0,a0,774 # 80020658 <bcache+0x8250>
    8000335a:	ffffe097          	auipc	ra,0xffffe
    8000335e:	ae4080e7          	jalr	-1308(ra) # 80000e3e <release>
      acquiresleep(&b->lock);
    80003362:	010b8513          	addi	a0,s7,16
    80003366:	00001097          	auipc	ra,0x1
    8000336a:	594080e7          	jalr	1428(ra) # 800048fa <acquiresleep>
      return b;
    8000336e:	a8c1                	j	8000343e <bread+0x222>
    80003370:	8b36                	mv	s6,a3
        newfound = 1;
    80003372:	4705                	li	a4,1
    for(b = &bcache.bufmap[i]; b->next; b = b->next) {
    80003374:	6bb0                	ld	a2,80(a5)
    80003376:	86be                	mv	a3,a5
    80003378:	ce19                	beqz	a2,80003396 <bread+0x17a>
    8000337a:	87b2                	mv	a5,a2
      if(b->next->refcnt == 0 && (!before_least || b->next->lastuse < before_least->next->lastuse)) {
    8000337c:	47b0                	lw	a2,72(a5)
    8000337e:	fa7d                	bnez	a2,80003374 <bread+0x158>
    80003380:	fe0b08e3          	beqz	s6,80003370 <bread+0x154>
    80003384:	050b3603          	ld	a2,80(s6)
    80003388:	47ec                	lw	a1,76(a5)
    8000338a:	4670                	lw	a2,76(a2)
    8000338c:	fec5f4e3          	bgeu	a1,a2,80003374 <bread+0x158>
    80003390:	8b36                	mv	s6,a3
        newfound = 1;
    80003392:	4705                	li	a4,1
    80003394:	b7c5                	j	80003374 <bread+0x158>
    if(!newfound) {// 如果在当前桶中没有找到最近未使用的缓冲区，则释放该锁
    80003396:	cb15                	beqz	a4,800033ca <bread+0x1ae>
      if(holding_bucket != -1) release(&bcache.bufmap_locks[holding_bucket]);
    80003398:	05b49063          	bne	s1,s11,800033d8 <bread+0x1bc>
      holding_bucket = i;
    8000339c:	000b849b          	sext.w	s1,s7
  for(int i = 0; i < NBUFMAP_BUCKET; i++){
    800033a0:	2b85                	addiw	s7,s7,1
    800033a2:	020c8c93          	addi	s9,s9,32
    800033a6:	458c0c13          	addi	s8,s8,1112
    800033aa:	47b5                	li	a5,13
    800033ac:	04fb8763          	beq	s7,a5,800033fa <bread+0x1de>
    acquire(&bcache.bufmap_locks[i]);// 获取bufmap中桶对应的锁
    800033b0:	f9943423          	sd	s9,-120(s0)
    800033b4:	8566                	mv	a0,s9
    800033b6:	ffffe097          	auipc	ra,0xffffe
    800033ba:	9b8080e7          	jalr	-1608(ra) # 80000d6e <acquire>
    for(b = &bcache.bufmap[i]; b->next; b = b->next) {
    800033be:	86e2                	mv	a3,s8
    800033c0:	050c3783          	ld	a5,80(s8)
    800033c4:	c399                	beqz	a5,800033ca <bread+0x1ae>
    int newfound = 0; // new least-recently-used buf found in this bucket
    800033c6:	4701                	li	a4,0
    800033c8:	bf55                	j	8000337c <bread+0x160>
      release(&bcache.bufmap_locks[i]);
    800033ca:	f8843503          	ld	a0,-120(s0)
    800033ce:	ffffe097          	auipc	ra,0xffffe
    800033d2:	a70080e7          	jalr	-1424(ra) # 80000e3e <release>
    800033d6:	b7e9                	j	800033a0 <bread+0x184>
      if(holding_bucket != -1) release(&bcache.bufmap_locks[holding_bucket]);
    800033d8:	02049513          	slli	a0,s1,0x20
    800033dc:	9101                	srli	a0,a0,0x20
    800033de:	5d750513          	addi	a0,a0,1495
    800033e2:	0516                	slli	a0,a0,0x5
    800033e4:	0521                	addi	a0,a0,8
    800033e6:	00015797          	auipc	a5,0x15
    800033ea:	02278793          	addi	a5,a5,34 # 80018408 <bcache>
    800033ee:	953e                	add	a0,a0,a5
    800033f0:	ffffe097          	auipc	ra,0xffffe
    800033f4:	a4e080e7          	jalr	-1458(ra) # 80000e3e <release>
    800033f8:	b755                	j	8000339c <bread+0x180>
  if(!before_least) { // 如果没有找到未使用的缓冲区，则发生错误
    800033fa:	060b0563          	beqz	s6,80003464 <bread+0x248>
  b = before_least->next;
    800033fe:	050b3b83          	ld	s7,80(s6)
  if(holding_bucket != key) {
    80003402:	069d1963          	bne	s10,s1,80003474 <bread+0x258>
  b->dev = dev; // 设置缓冲区的设备号
    80003406:	015ba423          	sw	s5,8(s7)
  b->blockno = blockno; // 设置缓冲区的块号
    8000340a:	014ba623          	sw	s4,12(s7)
  b->refcnt = 1; // 引用计数设置为1，表示有一个进程使用了该缓冲区
    8000340e:	4785                	li	a5,1
    80003410:	04fba423          	sw	a5,72(s7)
  b->valid = 0; // 缓冲区的内容无效
    80003414:	000ba023          	sw	zero,0(s7)
  release(&bcache.bufmap_locks[key]); // 释放bufmap的锁
    80003418:	854a                	mv	a0,s2
    8000341a:	ffffe097          	auipc	ra,0xffffe
    8000341e:	a24080e7          	jalr	-1500(ra) # 80000e3e <release>
  release(&bcache.eviction_lock); // 释放eviction锁
    80003422:	0001d517          	auipc	a0,0x1d
    80003426:	23650513          	addi	a0,a0,566 # 80020658 <bcache+0x8250>
    8000342a:	ffffe097          	auipc	ra,0xffffe
    8000342e:	a14080e7          	jalr	-1516(ra) # 80000e3e <release>
  acquiresleep(&b->lock); // 获取缓冲区的睡眠锁
    80003432:	010b8513          	addi	a0,s7,16
    80003436:	00001097          	auipc	ra,0x1
    8000343a:	4c4080e7          	jalr	1220(ra) # 800048fa <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000343e:	000ba783          	lw	a5,0(s7)
    80003442:	c3d9                	beqz	a5,800034c8 <bread+0x2ac>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003444:	855e                	mv	a0,s7
    80003446:	70e6                	ld	ra,120(sp)
    80003448:	7446                	ld	s0,112(sp)
    8000344a:	74a6                	ld	s1,104(sp)
    8000344c:	7906                	ld	s2,96(sp)
    8000344e:	69e6                	ld	s3,88(sp)
    80003450:	6a46                	ld	s4,80(sp)
    80003452:	6aa6                	ld	s5,72(sp)
    80003454:	6b06                	ld	s6,64(sp)
    80003456:	7be2                	ld	s7,56(sp)
    80003458:	7c42                	ld	s8,48(sp)
    8000345a:	7ca2                	ld	s9,40(sp)
    8000345c:	7d02                	ld	s10,32(sp)
    8000345e:	6de2                	ld	s11,24(sp)
    80003460:	6109                	addi	sp,sp,128
    80003462:	8082                	ret
    panic("bget: no buffers");
    80003464:	00005517          	auipc	a0,0x5
    80003468:	13450513          	addi	a0,a0,308 # 80008598 <syscalls+0xd8>
    8000346c:	ffffd097          	auipc	ra,0xffffd
    80003470:	0e4080e7          	jalr	228(ra) # 80000550 <panic>
    before_least->next = b->next;
    80003474:	050bb783          	ld	a5,80(s7)
    80003478:	04fb3823          	sd	a5,80(s6)
    release(&bcache.bufmap_locks[holding_bucket]);// 释放持有的桶的锁
    8000347c:	02049513          	slli	a0,s1,0x20
    80003480:	9101                	srli	a0,a0,0x20
    80003482:	5d750513          	addi	a0,a0,1495
    80003486:	0516                	slli	a0,a0,0x5
    80003488:	0521                	addi	a0,a0,8
    8000348a:	00015497          	auipc	s1,0x15
    8000348e:	f7e48493          	addi	s1,s1,-130 # 80018408 <bcache>
    80003492:	9526                	add	a0,a0,s1
    80003494:	ffffe097          	auipc	ra,0xffffe
    80003498:	9aa080e7          	jalr	-1622(ra) # 80000e3e <release>
    acquire(&bcache.bufmap_locks[key]);
    8000349c:	854a                	mv	a0,s2
    8000349e:	ffffe097          	auipc	ra,0xffffe
    800034a2:	8d0080e7          	jalr	-1840(ra) # 80000d6e <acquire>
    b->next = bcache.bufmap[key].next;
    800034a6:	1982                	slli	s3,s3,0x20
    800034a8:	0209d993          	srli	s3,s3,0x20
    800034ac:	45800793          	li	a5,1112
    800034b0:	02f989b3          	mul	s3,s3,a5
    800034b4:	94ce                	add	s1,s1,s3
    800034b6:	69a1                	lui	s3,0x8
    800034b8:	99a6                	add	s3,s3,s1
    800034ba:	2c09b783          	ld	a5,704(s3) # 82c0 <_entry-0x7fff7d40>
    800034be:	04fbb823          	sd	a5,80(s7)
    bcache.bufmap[key].next = b;
    800034c2:	2d79b023          	sd	s7,704(s3)
    800034c6:	b781                	j	80003406 <bread+0x1ea>
    virtio_disk_rw(b, 0);
    800034c8:	4581                	li	a1,0
    800034ca:	855e                	mv	a0,s7
    800034cc:	00003097          	auipc	ra,0x3
    800034d0:	faa080e7          	jalr	-86(ra) # 80006476 <virtio_disk_rw>
    b->valid = 1;
    800034d4:	4785                	li	a5,1
    800034d6:	00fba023          	sw	a5,0(s7)
  return b;
    800034da:	b7ad                	j	80003444 <bread+0x228>

00000000800034dc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034dc:	1101                	addi	sp,sp,-32
    800034de:	ec06                	sd	ra,24(sp)
    800034e0:	e822                	sd	s0,16(sp)
    800034e2:	e426                	sd	s1,8(sp)
    800034e4:	1000                	addi	s0,sp,32
    800034e6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034e8:	0541                	addi	a0,a0,16
    800034ea:	00001097          	auipc	ra,0x1
    800034ee:	4aa080e7          	jalr	1194(ra) # 80004994 <holdingsleep>
    800034f2:	cd01                	beqz	a0,8000350a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034f4:	4585                	li	a1,1
    800034f6:	8526                	mv	a0,s1
    800034f8:	00003097          	auipc	ra,0x3
    800034fc:	f7e080e7          	jalr	-130(ra) # 80006476 <virtio_disk_rw>
}
    80003500:	60e2                	ld	ra,24(sp)
    80003502:	6442                	ld	s0,16(sp)
    80003504:	64a2                	ld	s1,8(sp)
    80003506:	6105                	addi	sp,sp,32
    80003508:	8082                	ret
    panic("bwrite");
    8000350a:	00005517          	auipc	a0,0x5
    8000350e:	0a650513          	addi	a0,a0,166 # 800085b0 <syscalls+0xf0>
    80003512:	ffffd097          	auipc	ra,0xffffd
    80003516:	03e080e7          	jalr	62(ra) # 80000550 <panic>

000000008000351a <brelse>:

// 释放一个被锁定的缓冲区。
void brelse(struct buf *b) {
    8000351a:	1101                	addi	sp,sp,-32
    8000351c:	ec06                	sd	ra,24(sp)
    8000351e:	e822                	sd	s0,16(sp)
    80003520:	e426                	sd	s1,8(sp)
    80003522:	e04a                	sd	s2,0(sp)
    80003524:	1000                	addi	s0,sp,32
    80003526:	892a                	mv	s2,a0
  if(!holdingsleep(&b->lock)) // 检查当前线程是否持有睡眠锁，如果没有持有，则发生错误
    80003528:	01050493          	addi	s1,a0,16
    8000352c:	8526                	mv	a0,s1
    8000352e:	00001097          	auipc	ra,0x1
    80003532:	466080e7          	jalr	1126(ra) # 80004994 <holdingsleep>
    80003536:	c925                	beqz	a0,800035a6 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock); // 释放睡眠锁
    80003538:	8526                	mv	a0,s1
    8000353a:	00001097          	auipc	ra,0x1
    8000353e:	416080e7          	jalr	1046(ra) # 80004950 <releasesleep>

  uint key = BUFMAP_HASH(b->dev, b->blockno); // 根据设备和块号计算哈希值，确定bufmap的索引位置
    80003542:	00892483          	lw	s1,8(s2)
    80003546:	01b4949b          	slliw	s1,s1,0x1b
    8000354a:	00c92783          	lw	a5,12(s2)
    8000354e:	8cdd                	or	s1,s1,a5
    80003550:	47b5                	li	a5,13
    80003552:	02f4f4bb          	remuw	s1,s1,a5
  acquire(&bcache.bufmap_locks[key]); // 获取bufmap对应的锁
    80003556:	1482                	slli	s1,s1,0x20
    80003558:	9081                	srli	s1,s1,0x20
    8000355a:	5d748493          	addi	s1,s1,1495
    8000355e:	0496                	slli	s1,s1,0x5
    80003560:	00015797          	auipc	a5,0x15
    80003564:	eb078793          	addi	a5,a5,-336 # 80018410 <bcache+0x8>
    80003568:	94be                	add	s1,s1,a5
    8000356a:	8526                	mv	a0,s1
    8000356c:	ffffe097          	auipc	ra,0xffffe
    80003570:	802080e7          	jalr	-2046(ra) # 80000d6e <acquire>
  b->refcnt--; // 引用计数减1，表示当前线程不再使用该缓冲区
    80003574:	04892783          	lw	a5,72(s2)
    80003578:	37fd                	addiw	a5,a5,-1
    8000357a:	0007871b          	sext.w	a4,a5
    8000357e:	04f92423          	sw	a5,72(s2)
  if (b->refcnt == 0) { // 如果引用计数为0，则表示缓冲区没有被其他线程使用
    80003582:	e719                	bnez	a4,80003590 <brelse+0x76>
    b->lastuse = ticks; // 更新最后使用时间为当前系统滴答数
    80003584:	00006797          	auipc	a5,0x6
    80003588:	a9c7a783          	lw	a5,-1380(a5) # 80009020 <ticks>
    8000358c:	04f92623          	sw	a5,76(s2)
  }
  release(&bcache.bufmap_locks[key]); // 释放bufmap的锁
    80003590:	8526                	mv	a0,s1
    80003592:	ffffe097          	auipc	ra,0xffffe
    80003596:	8ac080e7          	jalr	-1876(ra) # 80000e3e <release>

}
    8000359a:	60e2                	ld	ra,24(sp)
    8000359c:	6442                	ld	s0,16(sp)
    8000359e:	64a2                	ld	s1,8(sp)
    800035a0:	6902                	ld	s2,0(sp)
    800035a2:	6105                	addi	sp,sp,32
    800035a4:	8082                	ret
    panic("brelse");
    800035a6:	00005517          	auipc	a0,0x5
    800035aa:	01250513          	addi	a0,a0,18 # 800085b8 <syscalls+0xf8>
    800035ae:	ffffd097          	auipc	ra,0xffffd
    800035b2:	fa2080e7          	jalr	-94(ra) # 80000550 <panic>

00000000800035b6 <bpin>:

// 将缓冲区锁定，使其不能被回收。
void bpin(struct buf *b) {
    800035b6:	1101                	addi	sp,sp,-32
    800035b8:	ec06                	sd	ra,24(sp)
    800035ba:	e822                	sd	s0,16(sp)
    800035bc:	e426                	sd	s1,8(sp)
    800035be:	e04a                	sd	s2,0(sp)
    800035c0:	1000                	addi	s0,sp,32
    800035c2:	892a                	mv	s2,a0
  uint key = BUFMAP_HASH(b->dev, b->blockno); // 根据设备和块号计算哈希值，确定bufmap的索引位置
    800035c4:	4504                	lw	s1,8(a0)
    800035c6:	01b4949b          	slliw	s1,s1,0x1b
    800035ca:	455c                	lw	a5,12(a0)
    800035cc:	8cdd                	or	s1,s1,a5
    800035ce:	47b5                	li	a5,13
    800035d0:	02f4f4bb          	remuw	s1,s1,a5

  acquire(&bcache.bufmap_locks[key]); // 获取bufmap对应的锁
    800035d4:	1482                	slli	s1,s1,0x20
    800035d6:	9081                	srli	s1,s1,0x20
    800035d8:	5d748493          	addi	s1,s1,1495
    800035dc:	0496                	slli	s1,s1,0x5
    800035de:	00015797          	auipc	a5,0x15
    800035e2:	e3278793          	addi	a5,a5,-462 # 80018410 <bcache+0x8>
    800035e6:	94be                	add	s1,s1,a5
    800035e8:	8526                	mv	a0,s1
    800035ea:	ffffd097          	auipc	ra,0xffffd
    800035ee:	784080e7          	jalr	1924(ra) # 80000d6e <acquire>
  b->refcnt++; // 引用计数加1，表示有一个进程正在使用该缓冲区
    800035f2:	04892783          	lw	a5,72(s2)
    800035f6:	2785                	addiw	a5,a5,1
    800035f8:	04f92423          	sw	a5,72(s2)
  release(&bcache.bufmap_locks[key]); // 释放bufmap的锁
    800035fc:	8526                	mv	a0,s1
    800035fe:	ffffe097          	auipc	ra,0xffffe
    80003602:	840080e7          	jalr	-1984(ra) # 80000e3e <release>
}
    80003606:	60e2                	ld	ra,24(sp)
    80003608:	6442                	ld	s0,16(sp)
    8000360a:	64a2                	ld	s1,8(sp)
    8000360c:	6902                	ld	s2,0(sp)
    8000360e:	6105                	addi	sp,sp,32
    80003610:	8082                	ret

0000000080003612 <bunpin>:

// 取消对缓冲区的锁定，允许其被回收。
void bunpin(struct buf *b) {
    80003612:	1101                	addi	sp,sp,-32
    80003614:	ec06                	sd	ra,24(sp)
    80003616:	e822                	sd	s0,16(sp)
    80003618:	e426                	sd	s1,8(sp)
    8000361a:	e04a                	sd	s2,0(sp)
    8000361c:	1000                	addi	s0,sp,32
    8000361e:	892a                	mv	s2,a0
  uint key = BUFMAP_HASH(b->dev, b->blockno); // 根据设备和块号计算哈希值，确定bufmap的索引位置
    80003620:	4504                	lw	s1,8(a0)
    80003622:	01b4949b          	slliw	s1,s1,0x1b
    80003626:	455c                	lw	a5,12(a0)
    80003628:	8cdd                	or	s1,s1,a5
    8000362a:	47b5                	li	a5,13
    8000362c:	02f4f4bb          	remuw	s1,s1,a5

  acquire(&bcache.bufmap_locks[key]); // 获取bufmap对应的锁
    80003630:	1482                	slli	s1,s1,0x20
    80003632:	9081                	srli	s1,s1,0x20
    80003634:	5d748493          	addi	s1,s1,1495
    80003638:	0496                	slli	s1,s1,0x5
    8000363a:	00015797          	auipc	a5,0x15
    8000363e:	dd678793          	addi	a5,a5,-554 # 80018410 <bcache+0x8>
    80003642:	94be                	add	s1,s1,a5
    80003644:	8526                	mv	a0,s1
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	728080e7          	jalr	1832(ra) # 80000d6e <acquire>
  b->refcnt--; // 引用计数减1，表示有一个进程不再使用该缓冲区
    8000364e:	04892783          	lw	a5,72(s2)
    80003652:	37fd                	addiw	a5,a5,-1
    80003654:	04f92423          	sw	a5,72(s2)
  release(&bcache.bufmap_locks[key]); // 释放bufmap的锁
    80003658:	8526                	mv	a0,s1
    8000365a:	ffffd097          	auipc	ra,0xffffd
    8000365e:	7e4080e7          	jalr	2020(ra) # 80000e3e <release>
}
    80003662:	60e2                	ld	ra,24(sp)
    80003664:	6442                	ld	s0,16(sp)
    80003666:	64a2                	ld	s1,8(sp)
    80003668:	6902                	ld	s2,0(sp)
    8000366a:	6105                	addi	sp,sp,32
    8000366c:	8082                	ret

000000008000366e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000366e:	1101                	addi	sp,sp,-32
    80003670:	ec06                	sd	ra,24(sp)
    80003672:	e822                	sd	s0,16(sp)
    80003674:	e426                	sd	s1,8(sp)
    80003676:	e04a                	sd	s2,0(sp)
    80003678:	1000                	addi	s0,sp,32
    8000367a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000367c:	00d5d59b          	srliw	a1,a1,0xd
    80003680:	00021797          	auipc	a5,0x21
    80003684:	a2c7a783          	lw	a5,-1492(a5) # 800240ac <sb+0x1c>
    80003688:	9dbd                	addw	a1,a1,a5
    8000368a:	00000097          	auipc	ra,0x0
    8000368e:	b92080e7          	jalr	-1134(ra) # 8000321c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003692:	0074f713          	andi	a4,s1,7
    80003696:	4785                	li	a5,1
    80003698:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000369c:	14ce                	slli	s1,s1,0x33
    8000369e:	90d9                	srli	s1,s1,0x36
    800036a0:	00950733          	add	a4,a0,s1
    800036a4:	05874703          	lbu	a4,88(a4)
    800036a8:	00e7f6b3          	and	a3,a5,a4
    800036ac:	c69d                	beqz	a3,800036da <bfree+0x6c>
    800036ae:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036b0:	94aa                	add	s1,s1,a0
    800036b2:	fff7c793          	not	a5,a5
    800036b6:	8ff9                	and	a5,a5,a4
    800036b8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800036bc:	00001097          	auipc	ra,0x1
    800036c0:	116080e7          	jalr	278(ra) # 800047d2 <log_write>
  brelse(bp);
    800036c4:	854a                	mv	a0,s2
    800036c6:	00000097          	auipc	ra,0x0
    800036ca:	e54080e7          	jalr	-428(ra) # 8000351a <brelse>
}
    800036ce:	60e2                	ld	ra,24(sp)
    800036d0:	6442                	ld	s0,16(sp)
    800036d2:	64a2                	ld	s1,8(sp)
    800036d4:	6902                	ld	s2,0(sp)
    800036d6:	6105                	addi	sp,sp,32
    800036d8:	8082                	ret
    panic("freeing free block");
    800036da:	00005517          	auipc	a0,0x5
    800036de:	ee650513          	addi	a0,a0,-282 # 800085c0 <syscalls+0x100>
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	e6e080e7          	jalr	-402(ra) # 80000550 <panic>

00000000800036ea <balloc>:
{
    800036ea:	711d                	addi	sp,sp,-96
    800036ec:	ec86                	sd	ra,88(sp)
    800036ee:	e8a2                	sd	s0,80(sp)
    800036f0:	e4a6                	sd	s1,72(sp)
    800036f2:	e0ca                	sd	s2,64(sp)
    800036f4:	fc4e                	sd	s3,56(sp)
    800036f6:	f852                	sd	s4,48(sp)
    800036f8:	f456                	sd	s5,40(sp)
    800036fa:	f05a                	sd	s6,32(sp)
    800036fc:	ec5e                	sd	s7,24(sp)
    800036fe:	e862                	sd	s8,16(sp)
    80003700:	e466                	sd	s9,8(sp)
    80003702:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003704:	00021797          	auipc	a5,0x21
    80003708:	9907a783          	lw	a5,-1648(a5) # 80024094 <sb+0x4>
    8000370c:	cbd1                	beqz	a5,800037a0 <balloc+0xb6>
    8000370e:	8baa                	mv	s7,a0
    80003710:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003712:	00021b17          	auipc	s6,0x21
    80003716:	97eb0b13          	addi	s6,s6,-1666 # 80024090 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000371a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000371c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000371e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003720:	6c89                	lui	s9,0x2
    80003722:	a831                	j	8000373e <balloc+0x54>
    brelse(bp);
    80003724:	854a                	mv	a0,s2
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	df4080e7          	jalr	-524(ra) # 8000351a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000372e:	015c87bb          	addw	a5,s9,s5
    80003732:	00078a9b          	sext.w	s5,a5
    80003736:	004b2703          	lw	a4,4(s6)
    8000373a:	06eaf363          	bgeu	s5,a4,800037a0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000373e:	41fad79b          	sraiw	a5,s5,0x1f
    80003742:	0137d79b          	srliw	a5,a5,0x13
    80003746:	015787bb          	addw	a5,a5,s5
    8000374a:	40d7d79b          	sraiw	a5,a5,0xd
    8000374e:	01cb2583          	lw	a1,28(s6)
    80003752:	9dbd                	addw	a1,a1,a5
    80003754:	855e                	mv	a0,s7
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	ac6080e7          	jalr	-1338(ra) # 8000321c <bread>
    8000375e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003760:	004b2503          	lw	a0,4(s6)
    80003764:	000a849b          	sext.w	s1,s5
    80003768:	8662                	mv	a2,s8
    8000376a:	faa4fde3          	bgeu	s1,a0,80003724 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000376e:	41f6579b          	sraiw	a5,a2,0x1f
    80003772:	01d7d69b          	srliw	a3,a5,0x1d
    80003776:	00c6873b          	addw	a4,a3,a2
    8000377a:	00777793          	andi	a5,a4,7
    8000377e:	9f95                	subw	a5,a5,a3
    80003780:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003784:	4037571b          	sraiw	a4,a4,0x3
    80003788:	00e906b3          	add	a3,s2,a4
    8000378c:	0586c683          	lbu	a3,88(a3)
    80003790:	00d7f5b3          	and	a1,a5,a3
    80003794:	cd91                	beqz	a1,800037b0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003796:	2605                	addiw	a2,a2,1
    80003798:	2485                	addiw	s1,s1,1
    8000379a:	fd4618e3          	bne	a2,s4,8000376a <balloc+0x80>
    8000379e:	b759                	j	80003724 <balloc+0x3a>
  panic("balloc: out of blocks");
    800037a0:	00005517          	auipc	a0,0x5
    800037a4:	e3850513          	addi	a0,a0,-456 # 800085d8 <syscalls+0x118>
    800037a8:	ffffd097          	auipc	ra,0xffffd
    800037ac:	da8080e7          	jalr	-600(ra) # 80000550 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800037b0:	974a                	add	a4,a4,s2
    800037b2:	8fd5                	or	a5,a5,a3
    800037b4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800037b8:	854a                	mv	a0,s2
    800037ba:	00001097          	auipc	ra,0x1
    800037be:	018080e7          	jalr	24(ra) # 800047d2 <log_write>
        brelse(bp);
    800037c2:	854a                	mv	a0,s2
    800037c4:	00000097          	auipc	ra,0x0
    800037c8:	d56080e7          	jalr	-682(ra) # 8000351a <brelse>
  bp = bread(dev, bno);
    800037cc:	85a6                	mv	a1,s1
    800037ce:	855e                	mv	a0,s7
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	a4c080e7          	jalr	-1460(ra) # 8000321c <bread>
    800037d8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037da:	40000613          	li	a2,1024
    800037de:	4581                	li	a1,0
    800037e0:	05850513          	addi	a0,a0,88
    800037e4:	ffffe097          	auipc	ra,0xffffe
    800037e8:	96a080e7          	jalr	-1686(ra) # 8000114e <memset>
  log_write(bp);
    800037ec:	854a                	mv	a0,s2
    800037ee:	00001097          	auipc	ra,0x1
    800037f2:	fe4080e7          	jalr	-28(ra) # 800047d2 <log_write>
  brelse(bp);
    800037f6:	854a                	mv	a0,s2
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	d22080e7          	jalr	-734(ra) # 8000351a <brelse>
}
    80003800:	8526                	mv	a0,s1
    80003802:	60e6                	ld	ra,88(sp)
    80003804:	6446                	ld	s0,80(sp)
    80003806:	64a6                	ld	s1,72(sp)
    80003808:	6906                	ld	s2,64(sp)
    8000380a:	79e2                	ld	s3,56(sp)
    8000380c:	7a42                	ld	s4,48(sp)
    8000380e:	7aa2                	ld	s5,40(sp)
    80003810:	7b02                	ld	s6,32(sp)
    80003812:	6be2                	ld	s7,24(sp)
    80003814:	6c42                	ld	s8,16(sp)
    80003816:	6ca2                	ld	s9,8(sp)
    80003818:	6125                	addi	sp,sp,96
    8000381a:	8082                	ret

000000008000381c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000381c:	7179                	addi	sp,sp,-48
    8000381e:	f406                	sd	ra,40(sp)
    80003820:	f022                	sd	s0,32(sp)
    80003822:	ec26                	sd	s1,24(sp)
    80003824:	e84a                	sd	s2,16(sp)
    80003826:	e44e                	sd	s3,8(sp)
    80003828:	e052                	sd	s4,0(sp)
    8000382a:	1800                	addi	s0,sp,48
    8000382c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000382e:	47ad                	li	a5,11
    80003830:	04b7fe63          	bgeu	a5,a1,8000388c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003834:	ff45849b          	addiw	s1,a1,-12
    80003838:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000383c:	0ff00793          	li	a5,255
    80003840:	0ae7e363          	bltu	a5,a4,800038e6 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003844:	08852583          	lw	a1,136(a0)
    80003848:	c5ad                	beqz	a1,800038b2 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000384a:	00092503          	lw	a0,0(s2)
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	9ce080e7          	jalr	-1586(ra) # 8000321c <bread>
    80003856:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003858:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000385c:	02049593          	slli	a1,s1,0x20
    80003860:	9181                	srli	a1,a1,0x20
    80003862:	058a                	slli	a1,a1,0x2
    80003864:	00b784b3          	add	s1,a5,a1
    80003868:	0004a983          	lw	s3,0(s1)
    8000386c:	04098d63          	beqz	s3,800038c6 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003870:	8552                	mv	a0,s4
    80003872:	00000097          	auipc	ra,0x0
    80003876:	ca8080e7          	jalr	-856(ra) # 8000351a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000387a:	854e                	mv	a0,s3
    8000387c:	70a2                	ld	ra,40(sp)
    8000387e:	7402                	ld	s0,32(sp)
    80003880:	64e2                	ld	s1,24(sp)
    80003882:	6942                	ld	s2,16(sp)
    80003884:	69a2                	ld	s3,8(sp)
    80003886:	6a02                	ld	s4,0(sp)
    80003888:	6145                	addi	sp,sp,48
    8000388a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000388c:	02059493          	slli	s1,a1,0x20
    80003890:	9081                	srli	s1,s1,0x20
    80003892:	048a                	slli	s1,s1,0x2
    80003894:	94aa                	add	s1,s1,a0
    80003896:	0584a983          	lw	s3,88(s1)
    8000389a:	fe0990e3          	bnez	s3,8000387a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000389e:	4108                	lw	a0,0(a0)
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	e4a080e7          	jalr	-438(ra) # 800036ea <balloc>
    800038a8:	0005099b          	sext.w	s3,a0
    800038ac:	0534ac23          	sw	s3,88(s1)
    800038b0:	b7e9                	j	8000387a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800038b2:	4108                	lw	a0,0(a0)
    800038b4:	00000097          	auipc	ra,0x0
    800038b8:	e36080e7          	jalr	-458(ra) # 800036ea <balloc>
    800038bc:	0005059b          	sext.w	a1,a0
    800038c0:	08b92423          	sw	a1,136(s2)
    800038c4:	b759                	j	8000384a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800038c6:	00092503          	lw	a0,0(s2)
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	e20080e7          	jalr	-480(ra) # 800036ea <balloc>
    800038d2:	0005099b          	sext.w	s3,a0
    800038d6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800038da:	8552                	mv	a0,s4
    800038dc:	00001097          	auipc	ra,0x1
    800038e0:	ef6080e7          	jalr	-266(ra) # 800047d2 <log_write>
    800038e4:	b771                	j	80003870 <bmap+0x54>
  panic("bmap: out of range");
    800038e6:	00005517          	auipc	a0,0x5
    800038ea:	d0a50513          	addi	a0,a0,-758 # 800085f0 <syscalls+0x130>
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	c62080e7          	jalr	-926(ra) # 80000550 <panic>

00000000800038f6 <iget>:
{
    800038f6:	7179                	addi	sp,sp,-48
    800038f8:	f406                	sd	ra,40(sp)
    800038fa:	f022                	sd	s0,32(sp)
    800038fc:	ec26                	sd	s1,24(sp)
    800038fe:	e84a                	sd	s2,16(sp)
    80003900:	e44e                	sd	s3,8(sp)
    80003902:	e052                	sd	s4,0(sp)
    80003904:	1800                	addi	s0,sp,48
    80003906:	89aa                	mv	s3,a0
    80003908:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000390a:	00020517          	auipc	a0,0x20
    8000390e:	7a650513          	addi	a0,a0,1958 # 800240b0 <icache>
    80003912:	ffffd097          	auipc	ra,0xffffd
    80003916:	45c080e7          	jalr	1116(ra) # 80000d6e <acquire>
  empty = 0;
    8000391a:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000391c:	00020497          	auipc	s1,0x20
    80003920:	7b448493          	addi	s1,s1,1972 # 800240d0 <icache+0x20>
    80003924:	00022697          	auipc	a3,0x22
    80003928:	3cc68693          	addi	a3,a3,972 # 80025cf0 <log>
    8000392c:	a039                	j	8000393a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000392e:	02090b63          	beqz	s2,80003964 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003932:	09048493          	addi	s1,s1,144
    80003936:	02d48a63          	beq	s1,a3,8000396a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000393a:	449c                	lw	a5,8(s1)
    8000393c:	fef059e3          	blez	a5,8000392e <iget+0x38>
    80003940:	4098                	lw	a4,0(s1)
    80003942:	ff3716e3          	bne	a4,s3,8000392e <iget+0x38>
    80003946:	40d8                	lw	a4,4(s1)
    80003948:	ff4713e3          	bne	a4,s4,8000392e <iget+0x38>
      ip->ref++;
    8000394c:	2785                	addiw	a5,a5,1
    8000394e:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003950:	00020517          	auipc	a0,0x20
    80003954:	76050513          	addi	a0,a0,1888 # 800240b0 <icache>
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	4e6080e7          	jalr	1254(ra) # 80000e3e <release>
      return ip;
    80003960:	8926                	mv	s2,s1
    80003962:	a03d                	j	80003990 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003964:	f7f9                	bnez	a5,80003932 <iget+0x3c>
    80003966:	8926                	mv	s2,s1
    80003968:	b7e9                	j	80003932 <iget+0x3c>
  if(empty == 0)
    8000396a:	02090c63          	beqz	s2,800039a2 <iget+0xac>
  ip->dev = dev;
    8000396e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003972:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003976:	4785                	li	a5,1
    80003978:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000397c:	04092423          	sw	zero,72(s2)
  release(&icache.lock);
    80003980:	00020517          	auipc	a0,0x20
    80003984:	73050513          	addi	a0,a0,1840 # 800240b0 <icache>
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	4b6080e7          	jalr	1206(ra) # 80000e3e <release>
}
    80003990:	854a                	mv	a0,s2
    80003992:	70a2                	ld	ra,40(sp)
    80003994:	7402                	ld	s0,32(sp)
    80003996:	64e2                	ld	s1,24(sp)
    80003998:	6942                	ld	s2,16(sp)
    8000399a:	69a2                	ld	s3,8(sp)
    8000399c:	6a02                	ld	s4,0(sp)
    8000399e:	6145                	addi	sp,sp,48
    800039a0:	8082                	ret
    panic("iget: no inodes");
    800039a2:	00005517          	auipc	a0,0x5
    800039a6:	c6650513          	addi	a0,a0,-922 # 80008608 <syscalls+0x148>
    800039aa:	ffffd097          	auipc	ra,0xffffd
    800039ae:	ba6080e7          	jalr	-1114(ra) # 80000550 <panic>

00000000800039b2 <fsinit>:
fsinit(int dev) {
    800039b2:	7179                	addi	sp,sp,-48
    800039b4:	f406                	sd	ra,40(sp)
    800039b6:	f022                	sd	s0,32(sp)
    800039b8:	ec26                	sd	s1,24(sp)
    800039ba:	e84a                	sd	s2,16(sp)
    800039bc:	e44e                	sd	s3,8(sp)
    800039be:	1800                	addi	s0,sp,48
    800039c0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039c2:	4585                	li	a1,1
    800039c4:	00000097          	auipc	ra,0x0
    800039c8:	858080e7          	jalr	-1960(ra) # 8000321c <bread>
    800039cc:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039ce:	00020997          	auipc	s3,0x20
    800039d2:	6c298993          	addi	s3,s3,1730 # 80024090 <sb>
    800039d6:	02000613          	li	a2,32
    800039da:	05850593          	addi	a1,a0,88
    800039de:	854e                	mv	a0,s3
    800039e0:	ffffd097          	auipc	ra,0xffffd
    800039e4:	7ce080e7          	jalr	1998(ra) # 800011ae <memmove>
  brelse(bp);
    800039e8:	8526                	mv	a0,s1
    800039ea:	00000097          	auipc	ra,0x0
    800039ee:	b30080e7          	jalr	-1232(ra) # 8000351a <brelse>
  if(sb.magic != FSMAGIC)
    800039f2:	0009a703          	lw	a4,0(s3)
    800039f6:	102037b7          	lui	a5,0x10203
    800039fa:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039fe:	02f71263          	bne	a4,a5,80003a22 <fsinit+0x70>
  initlog(dev, &sb);
    80003a02:	00020597          	auipc	a1,0x20
    80003a06:	68e58593          	addi	a1,a1,1678 # 80024090 <sb>
    80003a0a:	854a                	mv	a0,s2
    80003a0c:	00001097          	auipc	ra,0x1
    80003a10:	b4a080e7          	jalr	-1206(ra) # 80004556 <initlog>
}
    80003a14:	70a2                	ld	ra,40(sp)
    80003a16:	7402                	ld	s0,32(sp)
    80003a18:	64e2                	ld	s1,24(sp)
    80003a1a:	6942                	ld	s2,16(sp)
    80003a1c:	69a2                	ld	s3,8(sp)
    80003a1e:	6145                	addi	sp,sp,48
    80003a20:	8082                	ret
    panic("invalid file system");
    80003a22:	00005517          	auipc	a0,0x5
    80003a26:	bf650513          	addi	a0,a0,-1034 # 80008618 <syscalls+0x158>
    80003a2a:	ffffd097          	auipc	ra,0xffffd
    80003a2e:	b26080e7          	jalr	-1242(ra) # 80000550 <panic>

0000000080003a32 <iinit>:
{
    80003a32:	7179                	addi	sp,sp,-48
    80003a34:	f406                	sd	ra,40(sp)
    80003a36:	f022                	sd	s0,32(sp)
    80003a38:	ec26                	sd	s1,24(sp)
    80003a3a:	e84a                	sd	s2,16(sp)
    80003a3c:	e44e                	sd	s3,8(sp)
    80003a3e:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003a40:	00005597          	auipc	a1,0x5
    80003a44:	bf058593          	addi	a1,a1,-1040 # 80008630 <syscalls+0x170>
    80003a48:	00020517          	auipc	a0,0x20
    80003a4c:	66850513          	addi	a0,a0,1640 # 800240b0 <icache>
    80003a50:	ffffd097          	auipc	ra,0xffffd
    80003a54:	49a080e7          	jalr	1178(ra) # 80000eea <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a58:	00020497          	auipc	s1,0x20
    80003a5c:	68848493          	addi	s1,s1,1672 # 800240e0 <icache+0x30>
    80003a60:	00022997          	auipc	s3,0x22
    80003a64:	2a098993          	addi	s3,s3,672 # 80025d00 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003a68:	00005917          	auipc	s2,0x5
    80003a6c:	bd090913          	addi	s2,s2,-1072 # 80008638 <syscalls+0x178>
    80003a70:	85ca                	mv	a1,s2
    80003a72:	8526                	mv	a0,s1
    80003a74:	00001097          	auipc	ra,0x1
    80003a78:	e4c080e7          	jalr	-436(ra) # 800048c0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a7c:	09048493          	addi	s1,s1,144
    80003a80:	ff3498e3          	bne	s1,s3,80003a70 <iinit+0x3e>
}
    80003a84:	70a2                	ld	ra,40(sp)
    80003a86:	7402                	ld	s0,32(sp)
    80003a88:	64e2                	ld	s1,24(sp)
    80003a8a:	6942                	ld	s2,16(sp)
    80003a8c:	69a2                	ld	s3,8(sp)
    80003a8e:	6145                	addi	sp,sp,48
    80003a90:	8082                	ret

0000000080003a92 <ialloc>:
{
    80003a92:	715d                	addi	sp,sp,-80
    80003a94:	e486                	sd	ra,72(sp)
    80003a96:	e0a2                	sd	s0,64(sp)
    80003a98:	fc26                	sd	s1,56(sp)
    80003a9a:	f84a                	sd	s2,48(sp)
    80003a9c:	f44e                	sd	s3,40(sp)
    80003a9e:	f052                	sd	s4,32(sp)
    80003aa0:	ec56                	sd	s5,24(sp)
    80003aa2:	e85a                	sd	s6,16(sp)
    80003aa4:	e45e                	sd	s7,8(sp)
    80003aa6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003aa8:	00020717          	auipc	a4,0x20
    80003aac:	5f472703          	lw	a4,1524(a4) # 8002409c <sb+0xc>
    80003ab0:	4785                	li	a5,1
    80003ab2:	04e7fa63          	bgeu	a5,a4,80003b06 <ialloc+0x74>
    80003ab6:	8aaa                	mv	s5,a0
    80003ab8:	8bae                	mv	s7,a1
    80003aba:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003abc:	00020a17          	auipc	s4,0x20
    80003ac0:	5d4a0a13          	addi	s4,s4,1492 # 80024090 <sb>
    80003ac4:	00048b1b          	sext.w	s6,s1
    80003ac8:	0044d593          	srli	a1,s1,0x4
    80003acc:	018a2783          	lw	a5,24(s4)
    80003ad0:	9dbd                	addw	a1,a1,a5
    80003ad2:	8556                	mv	a0,s5
    80003ad4:	fffff097          	auipc	ra,0xfffff
    80003ad8:	748080e7          	jalr	1864(ra) # 8000321c <bread>
    80003adc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ade:	05850993          	addi	s3,a0,88
    80003ae2:	00f4f793          	andi	a5,s1,15
    80003ae6:	079a                	slli	a5,a5,0x6
    80003ae8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003aea:	00099783          	lh	a5,0(s3)
    80003aee:	c785                	beqz	a5,80003b16 <ialloc+0x84>
    brelse(bp);
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	a2a080e7          	jalr	-1494(ra) # 8000351a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003af8:	0485                	addi	s1,s1,1
    80003afa:	00ca2703          	lw	a4,12(s4)
    80003afe:	0004879b          	sext.w	a5,s1
    80003b02:	fce7e1e3          	bltu	a5,a4,80003ac4 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b06:	00005517          	auipc	a0,0x5
    80003b0a:	b3a50513          	addi	a0,a0,-1222 # 80008640 <syscalls+0x180>
    80003b0e:	ffffd097          	auipc	ra,0xffffd
    80003b12:	a42080e7          	jalr	-1470(ra) # 80000550 <panic>
      memset(dip, 0, sizeof(*dip));
    80003b16:	04000613          	li	a2,64
    80003b1a:	4581                	li	a1,0
    80003b1c:	854e                	mv	a0,s3
    80003b1e:	ffffd097          	auipc	ra,0xffffd
    80003b22:	630080e7          	jalr	1584(ra) # 8000114e <memset>
      dip->type = type;
    80003b26:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b2a:	854a                	mv	a0,s2
    80003b2c:	00001097          	auipc	ra,0x1
    80003b30:	ca6080e7          	jalr	-858(ra) # 800047d2 <log_write>
      brelse(bp);
    80003b34:	854a                	mv	a0,s2
    80003b36:	00000097          	auipc	ra,0x0
    80003b3a:	9e4080e7          	jalr	-1564(ra) # 8000351a <brelse>
      return iget(dev, inum);
    80003b3e:	85da                	mv	a1,s6
    80003b40:	8556                	mv	a0,s5
    80003b42:	00000097          	auipc	ra,0x0
    80003b46:	db4080e7          	jalr	-588(ra) # 800038f6 <iget>
}
    80003b4a:	60a6                	ld	ra,72(sp)
    80003b4c:	6406                	ld	s0,64(sp)
    80003b4e:	74e2                	ld	s1,56(sp)
    80003b50:	7942                	ld	s2,48(sp)
    80003b52:	79a2                	ld	s3,40(sp)
    80003b54:	7a02                	ld	s4,32(sp)
    80003b56:	6ae2                	ld	s5,24(sp)
    80003b58:	6b42                	ld	s6,16(sp)
    80003b5a:	6ba2                	ld	s7,8(sp)
    80003b5c:	6161                	addi	sp,sp,80
    80003b5e:	8082                	ret

0000000080003b60 <iupdate>:
{
    80003b60:	1101                	addi	sp,sp,-32
    80003b62:	ec06                	sd	ra,24(sp)
    80003b64:	e822                	sd	s0,16(sp)
    80003b66:	e426                	sd	s1,8(sp)
    80003b68:	e04a                	sd	s2,0(sp)
    80003b6a:	1000                	addi	s0,sp,32
    80003b6c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b6e:	415c                	lw	a5,4(a0)
    80003b70:	0047d79b          	srliw	a5,a5,0x4
    80003b74:	00020597          	auipc	a1,0x20
    80003b78:	5345a583          	lw	a1,1332(a1) # 800240a8 <sb+0x18>
    80003b7c:	9dbd                	addw	a1,a1,a5
    80003b7e:	4108                	lw	a0,0(a0)
    80003b80:	fffff097          	auipc	ra,0xfffff
    80003b84:	69c080e7          	jalr	1692(ra) # 8000321c <bread>
    80003b88:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b8a:	05850793          	addi	a5,a0,88
    80003b8e:	40c8                	lw	a0,4(s1)
    80003b90:	893d                	andi	a0,a0,15
    80003b92:	051a                	slli	a0,a0,0x6
    80003b94:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b96:	04c49703          	lh	a4,76(s1)
    80003b9a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b9e:	04e49703          	lh	a4,78(s1)
    80003ba2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003ba6:	05049703          	lh	a4,80(s1)
    80003baa:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003bae:	05249703          	lh	a4,82(s1)
    80003bb2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003bb6:	48f8                	lw	a4,84(s1)
    80003bb8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bba:	03400613          	li	a2,52
    80003bbe:	05848593          	addi	a1,s1,88
    80003bc2:	0531                	addi	a0,a0,12
    80003bc4:	ffffd097          	auipc	ra,0xffffd
    80003bc8:	5ea080e7          	jalr	1514(ra) # 800011ae <memmove>
  log_write(bp);
    80003bcc:	854a                	mv	a0,s2
    80003bce:	00001097          	auipc	ra,0x1
    80003bd2:	c04080e7          	jalr	-1020(ra) # 800047d2 <log_write>
  brelse(bp);
    80003bd6:	854a                	mv	a0,s2
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	942080e7          	jalr	-1726(ra) # 8000351a <brelse>
}
    80003be0:	60e2                	ld	ra,24(sp)
    80003be2:	6442                	ld	s0,16(sp)
    80003be4:	64a2                	ld	s1,8(sp)
    80003be6:	6902                	ld	s2,0(sp)
    80003be8:	6105                	addi	sp,sp,32
    80003bea:	8082                	ret

0000000080003bec <idup>:
{
    80003bec:	1101                	addi	sp,sp,-32
    80003bee:	ec06                	sd	ra,24(sp)
    80003bf0:	e822                	sd	s0,16(sp)
    80003bf2:	e426                	sd	s1,8(sp)
    80003bf4:	1000                	addi	s0,sp,32
    80003bf6:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003bf8:	00020517          	auipc	a0,0x20
    80003bfc:	4b850513          	addi	a0,a0,1208 # 800240b0 <icache>
    80003c00:	ffffd097          	auipc	ra,0xffffd
    80003c04:	16e080e7          	jalr	366(ra) # 80000d6e <acquire>
  ip->ref++;
    80003c08:	449c                	lw	a5,8(s1)
    80003c0a:	2785                	addiw	a5,a5,1
    80003c0c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003c0e:	00020517          	auipc	a0,0x20
    80003c12:	4a250513          	addi	a0,a0,1186 # 800240b0 <icache>
    80003c16:	ffffd097          	auipc	ra,0xffffd
    80003c1a:	228080e7          	jalr	552(ra) # 80000e3e <release>
}
    80003c1e:	8526                	mv	a0,s1
    80003c20:	60e2                	ld	ra,24(sp)
    80003c22:	6442                	ld	s0,16(sp)
    80003c24:	64a2                	ld	s1,8(sp)
    80003c26:	6105                	addi	sp,sp,32
    80003c28:	8082                	ret

0000000080003c2a <ilock>:
{
    80003c2a:	1101                	addi	sp,sp,-32
    80003c2c:	ec06                	sd	ra,24(sp)
    80003c2e:	e822                	sd	s0,16(sp)
    80003c30:	e426                	sd	s1,8(sp)
    80003c32:	e04a                	sd	s2,0(sp)
    80003c34:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c36:	c115                	beqz	a0,80003c5a <ilock+0x30>
    80003c38:	84aa                	mv	s1,a0
    80003c3a:	451c                	lw	a5,8(a0)
    80003c3c:	00f05f63          	blez	a5,80003c5a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c40:	0541                	addi	a0,a0,16
    80003c42:	00001097          	auipc	ra,0x1
    80003c46:	cb8080e7          	jalr	-840(ra) # 800048fa <acquiresleep>
  if(ip->valid == 0){
    80003c4a:	44bc                	lw	a5,72(s1)
    80003c4c:	cf99                	beqz	a5,80003c6a <ilock+0x40>
}
    80003c4e:	60e2                	ld	ra,24(sp)
    80003c50:	6442                	ld	s0,16(sp)
    80003c52:	64a2                	ld	s1,8(sp)
    80003c54:	6902                	ld	s2,0(sp)
    80003c56:	6105                	addi	sp,sp,32
    80003c58:	8082                	ret
    panic("ilock");
    80003c5a:	00005517          	auipc	a0,0x5
    80003c5e:	9fe50513          	addi	a0,a0,-1538 # 80008658 <syscalls+0x198>
    80003c62:	ffffd097          	auipc	ra,0xffffd
    80003c66:	8ee080e7          	jalr	-1810(ra) # 80000550 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c6a:	40dc                	lw	a5,4(s1)
    80003c6c:	0047d79b          	srliw	a5,a5,0x4
    80003c70:	00020597          	auipc	a1,0x20
    80003c74:	4385a583          	lw	a1,1080(a1) # 800240a8 <sb+0x18>
    80003c78:	9dbd                	addw	a1,a1,a5
    80003c7a:	4088                	lw	a0,0(s1)
    80003c7c:	fffff097          	auipc	ra,0xfffff
    80003c80:	5a0080e7          	jalr	1440(ra) # 8000321c <bread>
    80003c84:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c86:	05850593          	addi	a1,a0,88
    80003c8a:	40dc                	lw	a5,4(s1)
    80003c8c:	8bbd                	andi	a5,a5,15
    80003c8e:	079a                	slli	a5,a5,0x6
    80003c90:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c92:	00059783          	lh	a5,0(a1)
    80003c96:	04f49623          	sh	a5,76(s1)
    ip->major = dip->major;
    80003c9a:	00259783          	lh	a5,2(a1)
    80003c9e:	04f49723          	sh	a5,78(s1)
    ip->minor = dip->minor;
    80003ca2:	00459783          	lh	a5,4(a1)
    80003ca6:	04f49823          	sh	a5,80(s1)
    ip->nlink = dip->nlink;
    80003caa:	00659783          	lh	a5,6(a1)
    80003cae:	04f49923          	sh	a5,82(s1)
    ip->size = dip->size;
    80003cb2:	459c                	lw	a5,8(a1)
    80003cb4:	c8fc                	sw	a5,84(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003cb6:	03400613          	li	a2,52
    80003cba:	05b1                	addi	a1,a1,12
    80003cbc:	05848513          	addi	a0,s1,88
    80003cc0:	ffffd097          	auipc	ra,0xffffd
    80003cc4:	4ee080e7          	jalr	1262(ra) # 800011ae <memmove>
    brelse(bp);
    80003cc8:	854a                	mv	a0,s2
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	850080e7          	jalr	-1968(ra) # 8000351a <brelse>
    ip->valid = 1;
    80003cd2:	4785                	li	a5,1
    80003cd4:	c4bc                	sw	a5,72(s1)
    if(ip->type == 0)
    80003cd6:	04c49783          	lh	a5,76(s1)
    80003cda:	fbb5                	bnez	a5,80003c4e <ilock+0x24>
      panic("ilock: no type");
    80003cdc:	00005517          	auipc	a0,0x5
    80003ce0:	98450513          	addi	a0,a0,-1660 # 80008660 <syscalls+0x1a0>
    80003ce4:	ffffd097          	auipc	ra,0xffffd
    80003ce8:	86c080e7          	jalr	-1940(ra) # 80000550 <panic>

0000000080003cec <iunlock>:
{
    80003cec:	1101                	addi	sp,sp,-32
    80003cee:	ec06                	sd	ra,24(sp)
    80003cf0:	e822                	sd	s0,16(sp)
    80003cf2:	e426                	sd	s1,8(sp)
    80003cf4:	e04a                	sd	s2,0(sp)
    80003cf6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003cf8:	c905                	beqz	a0,80003d28 <iunlock+0x3c>
    80003cfa:	84aa                	mv	s1,a0
    80003cfc:	01050913          	addi	s2,a0,16
    80003d00:	854a                	mv	a0,s2
    80003d02:	00001097          	auipc	ra,0x1
    80003d06:	c92080e7          	jalr	-878(ra) # 80004994 <holdingsleep>
    80003d0a:	cd19                	beqz	a0,80003d28 <iunlock+0x3c>
    80003d0c:	449c                	lw	a5,8(s1)
    80003d0e:	00f05d63          	blez	a5,80003d28 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d12:	854a                	mv	a0,s2
    80003d14:	00001097          	auipc	ra,0x1
    80003d18:	c3c080e7          	jalr	-964(ra) # 80004950 <releasesleep>
}
    80003d1c:	60e2                	ld	ra,24(sp)
    80003d1e:	6442                	ld	s0,16(sp)
    80003d20:	64a2                	ld	s1,8(sp)
    80003d22:	6902                	ld	s2,0(sp)
    80003d24:	6105                	addi	sp,sp,32
    80003d26:	8082                	ret
    panic("iunlock");
    80003d28:	00005517          	auipc	a0,0x5
    80003d2c:	94850513          	addi	a0,a0,-1720 # 80008670 <syscalls+0x1b0>
    80003d30:	ffffd097          	auipc	ra,0xffffd
    80003d34:	820080e7          	jalr	-2016(ra) # 80000550 <panic>

0000000080003d38 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d38:	7179                	addi	sp,sp,-48
    80003d3a:	f406                	sd	ra,40(sp)
    80003d3c:	f022                	sd	s0,32(sp)
    80003d3e:	ec26                	sd	s1,24(sp)
    80003d40:	e84a                	sd	s2,16(sp)
    80003d42:	e44e                	sd	s3,8(sp)
    80003d44:	e052                	sd	s4,0(sp)
    80003d46:	1800                	addi	s0,sp,48
    80003d48:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d4a:	05850493          	addi	s1,a0,88
    80003d4e:	08850913          	addi	s2,a0,136
    80003d52:	a021                	j	80003d5a <itrunc+0x22>
    80003d54:	0491                	addi	s1,s1,4
    80003d56:	01248d63          	beq	s1,s2,80003d70 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d5a:	408c                	lw	a1,0(s1)
    80003d5c:	dde5                	beqz	a1,80003d54 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d5e:	0009a503          	lw	a0,0(s3)
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	90c080e7          	jalr	-1780(ra) # 8000366e <bfree>
      ip->addrs[i] = 0;
    80003d6a:	0004a023          	sw	zero,0(s1)
    80003d6e:	b7dd                	j	80003d54 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d70:	0889a583          	lw	a1,136(s3)
    80003d74:	e185                	bnez	a1,80003d94 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d76:	0409aa23          	sw	zero,84(s3)
  iupdate(ip);
    80003d7a:	854e                	mv	a0,s3
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	de4080e7          	jalr	-540(ra) # 80003b60 <iupdate>
}
    80003d84:	70a2                	ld	ra,40(sp)
    80003d86:	7402                	ld	s0,32(sp)
    80003d88:	64e2                	ld	s1,24(sp)
    80003d8a:	6942                	ld	s2,16(sp)
    80003d8c:	69a2                	ld	s3,8(sp)
    80003d8e:	6a02                	ld	s4,0(sp)
    80003d90:	6145                	addi	sp,sp,48
    80003d92:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d94:	0009a503          	lw	a0,0(s3)
    80003d98:	fffff097          	auipc	ra,0xfffff
    80003d9c:	484080e7          	jalr	1156(ra) # 8000321c <bread>
    80003da0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003da2:	05850493          	addi	s1,a0,88
    80003da6:	45850913          	addi	s2,a0,1112
    80003daa:	a811                	j	80003dbe <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003dac:	0009a503          	lw	a0,0(s3)
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	8be080e7          	jalr	-1858(ra) # 8000366e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003db8:	0491                	addi	s1,s1,4
    80003dba:	01248563          	beq	s1,s2,80003dc4 <itrunc+0x8c>
      if(a[j])
    80003dbe:	408c                	lw	a1,0(s1)
    80003dc0:	dde5                	beqz	a1,80003db8 <itrunc+0x80>
    80003dc2:	b7ed                	j	80003dac <itrunc+0x74>
    brelse(bp);
    80003dc4:	8552                	mv	a0,s4
    80003dc6:	fffff097          	auipc	ra,0xfffff
    80003dca:	754080e7          	jalr	1876(ra) # 8000351a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003dce:	0889a583          	lw	a1,136(s3)
    80003dd2:	0009a503          	lw	a0,0(s3)
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	898080e7          	jalr	-1896(ra) # 8000366e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003dde:	0809a423          	sw	zero,136(s3)
    80003de2:	bf51                	j	80003d76 <itrunc+0x3e>

0000000080003de4 <iput>:
{
    80003de4:	1101                	addi	sp,sp,-32
    80003de6:	ec06                	sd	ra,24(sp)
    80003de8:	e822                	sd	s0,16(sp)
    80003dea:	e426                	sd	s1,8(sp)
    80003dec:	e04a                	sd	s2,0(sp)
    80003dee:	1000                	addi	s0,sp,32
    80003df0:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003df2:	00020517          	auipc	a0,0x20
    80003df6:	2be50513          	addi	a0,a0,702 # 800240b0 <icache>
    80003dfa:	ffffd097          	auipc	ra,0xffffd
    80003dfe:	f74080e7          	jalr	-140(ra) # 80000d6e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e02:	4498                	lw	a4,8(s1)
    80003e04:	4785                	li	a5,1
    80003e06:	02f70363          	beq	a4,a5,80003e2c <iput+0x48>
  ip->ref--;
    80003e0a:	449c                	lw	a5,8(s1)
    80003e0c:	37fd                	addiw	a5,a5,-1
    80003e0e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003e10:	00020517          	auipc	a0,0x20
    80003e14:	2a050513          	addi	a0,a0,672 # 800240b0 <icache>
    80003e18:	ffffd097          	auipc	ra,0xffffd
    80003e1c:	026080e7          	jalr	38(ra) # 80000e3e <release>
}
    80003e20:	60e2                	ld	ra,24(sp)
    80003e22:	6442                	ld	s0,16(sp)
    80003e24:	64a2                	ld	s1,8(sp)
    80003e26:	6902                	ld	s2,0(sp)
    80003e28:	6105                	addi	sp,sp,32
    80003e2a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e2c:	44bc                	lw	a5,72(s1)
    80003e2e:	dff1                	beqz	a5,80003e0a <iput+0x26>
    80003e30:	05249783          	lh	a5,82(s1)
    80003e34:	fbf9                	bnez	a5,80003e0a <iput+0x26>
    acquiresleep(&ip->lock);
    80003e36:	01048913          	addi	s2,s1,16
    80003e3a:	854a                	mv	a0,s2
    80003e3c:	00001097          	auipc	ra,0x1
    80003e40:	abe080e7          	jalr	-1346(ra) # 800048fa <acquiresleep>
    release(&icache.lock);
    80003e44:	00020517          	auipc	a0,0x20
    80003e48:	26c50513          	addi	a0,a0,620 # 800240b0 <icache>
    80003e4c:	ffffd097          	auipc	ra,0xffffd
    80003e50:	ff2080e7          	jalr	-14(ra) # 80000e3e <release>
    itrunc(ip);
    80003e54:	8526                	mv	a0,s1
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	ee2080e7          	jalr	-286(ra) # 80003d38 <itrunc>
    ip->type = 0;
    80003e5e:	04049623          	sh	zero,76(s1)
    iupdate(ip);
    80003e62:	8526                	mv	a0,s1
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	cfc080e7          	jalr	-772(ra) # 80003b60 <iupdate>
    ip->valid = 0;
    80003e6c:	0404a423          	sw	zero,72(s1)
    releasesleep(&ip->lock);
    80003e70:	854a                	mv	a0,s2
    80003e72:	00001097          	auipc	ra,0x1
    80003e76:	ade080e7          	jalr	-1314(ra) # 80004950 <releasesleep>
    acquire(&icache.lock);
    80003e7a:	00020517          	auipc	a0,0x20
    80003e7e:	23650513          	addi	a0,a0,566 # 800240b0 <icache>
    80003e82:	ffffd097          	auipc	ra,0xffffd
    80003e86:	eec080e7          	jalr	-276(ra) # 80000d6e <acquire>
    80003e8a:	b741                	j	80003e0a <iput+0x26>

0000000080003e8c <iunlockput>:
{
    80003e8c:	1101                	addi	sp,sp,-32
    80003e8e:	ec06                	sd	ra,24(sp)
    80003e90:	e822                	sd	s0,16(sp)
    80003e92:	e426                	sd	s1,8(sp)
    80003e94:	1000                	addi	s0,sp,32
    80003e96:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	e54080e7          	jalr	-428(ra) # 80003cec <iunlock>
  iput(ip);
    80003ea0:	8526                	mv	a0,s1
    80003ea2:	00000097          	auipc	ra,0x0
    80003ea6:	f42080e7          	jalr	-190(ra) # 80003de4 <iput>
}
    80003eaa:	60e2                	ld	ra,24(sp)
    80003eac:	6442                	ld	s0,16(sp)
    80003eae:	64a2                	ld	s1,8(sp)
    80003eb0:	6105                	addi	sp,sp,32
    80003eb2:	8082                	ret

0000000080003eb4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003eb4:	1141                	addi	sp,sp,-16
    80003eb6:	e422                	sd	s0,8(sp)
    80003eb8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003eba:	411c                	lw	a5,0(a0)
    80003ebc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ebe:	415c                	lw	a5,4(a0)
    80003ec0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ec2:	04c51783          	lh	a5,76(a0)
    80003ec6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003eca:	05251783          	lh	a5,82(a0)
    80003ece:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ed2:	05456783          	lwu	a5,84(a0)
    80003ed6:	e99c                	sd	a5,16(a1)
}
    80003ed8:	6422                	ld	s0,8(sp)
    80003eda:	0141                	addi	sp,sp,16
    80003edc:	8082                	ret

0000000080003ede <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ede:	497c                	lw	a5,84(a0)
    80003ee0:	0ed7e963          	bltu	a5,a3,80003fd2 <readi+0xf4>
{
    80003ee4:	7159                	addi	sp,sp,-112
    80003ee6:	f486                	sd	ra,104(sp)
    80003ee8:	f0a2                	sd	s0,96(sp)
    80003eea:	eca6                	sd	s1,88(sp)
    80003eec:	e8ca                	sd	s2,80(sp)
    80003eee:	e4ce                	sd	s3,72(sp)
    80003ef0:	e0d2                	sd	s4,64(sp)
    80003ef2:	fc56                	sd	s5,56(sp)
    80003ef4:	f85a                	sd	s6,48(sp)
    80003ef6:	f45e                	sd	s7,40(sp)
    80003ef8:	f062                	sd	s8,32(sp)
    80003efa:	ec66                	sd	s9,24(sp)
    80003efc:	e86a                	sd	s10,16(sp)
    80003efe:	e46e                	sd	s11,8(sp)
    80003f00:	1880                	addi	s0,sp,112
    80003f02:	8baa                	mv	s7,a0
    80003f04:	8c2e                	mv	s8,a1
    80003f06:	8ab2                	mv	s5,a2
    80003f08:	84b6                	mv	s1,a3
    80003f0a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f0c:	9f35                	addw	a4,a4,a3
    return 0;
    80003f0e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f10:	0ad76063          	bltu	a4,a3,80003fb0 <readi+0xd2>
  if(off + n > ip->size)
    80003f14:	00e7f463          	bgeu	a5,a4,80003f1c <readi+0x3e>
    n = ip->size - off;
    80003f18:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f1c:	0a0b0963          	beqz	s6,80003fce <readi+0xf0>
    80003f20:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f22:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f26:	5cfd                	li	s9,-1
    80003f28:	a82d                	j	80003f62 <readi+0x84>
    80003f2a:	020a1d93          	slli	s11,s4,0x20
    80003f2e:	020ddd93          	srli	s11,s11,0x20
    80003f32:	05890613          	addi	a2,s2,88
    80003f36:	86ee                	mv	a3,s11
    80003f38:	963a                	add	a2,a2,a4
    80003f3a:	85d6                	mv	a1,s5
    80003f3c:	8562                	mv	a0,s8
    80003f3e:	fffff097          	auipc	ra,0xfffff
    80003f42:	8ea080e7          	jalr	-1814(ra) # 80002828 <either_copyout>
    80003f46:	05950d63          	beq	a0,s9,80003fa0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f4a:	854a                	mv	a0,s2
    80003f4c:	fffff097          	auipc	ra,0xfffff
    80003f50:	5ce080e7          	jalr	1486(ra) # 8000351a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f54:	013a09bb          	addw	s3,s4,s3
    80003f58:	009a04bb          	addw	s1,s4,s1
    80003f5c:	9aee                	add	s5,s5,s11
    80003f5e:	0569f763          	bgeu	s3,s6,80003fac <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f62:	000ba903          	lw	s2,0(s7)
    80003f66:	00a4d59b          	srliw	a1,s1,0xa
    80003f6a:	855e                	mv	a0,s7
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	8b0080e7          	jalr	-1872(ra) # 8000381c <bmap>
    80003f74:	0005059b          	sext.w	a1,a0
    80003f78:	854a                	mv	a0,s2
    80003f7a:	fffff097          	auipc	ra,0xfffff
    80003f7e:	2a2080e7          	jalr	674(ra) # 8000321c <bread>
    80003f82:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f84:	3ff4f713          	andi	a4,s1,1023
    80003f88:	40ed07bb          	subw	a5,s10,a4
    80003f8c:	413b06bb          	subw	a3,s6,s3
    80003f90:	8a3e                	mv	s4,a5
    80003f92:	2781                	sext.w	a5,a5
    80003f94:	0006861b          	sext.w	a2,a3
    80003f98:	f8f679e3          	bgeu	a2,a5,80003f2a <readi+0x4c>
    80003f9c:	8a36                	mv	s4,a3
    80003f9e:	b771                	j	80003f2a <readi+0x4c>
      brelse(bp);
    80003fa0:	854a                	mv	a0,s2
    80003fa2:	fffff097          	auipc	ra,0xfffff
    80003fa6:	578080e7          	jalr	1400(ra) # 8000351a <brelse>
      tot = -1;
    80003faa:	59fd                	li	s3,-1
  }
  return tot;
    80003fac:	0009851b          	sext.w	a0,s3
}
    80003fb0:	70a6                	ld	ra,104(sp)
    80003fb2:	7406                	ld	s0,96(sp)
    80003fb4:	64e6                	ld	s1,88(sp)
    80003fb6:	6946                	ld	s2,80(sp)
    80003fb8:	69a6                	ld	s3,72(sp)
    80003fba:	6a06                	ld	s4,64(sp)
    80003fbc:	7ae2                	ld	s5,56(sp)
    80003fbe:	7b42                	ld	s6,48(sp)
    80003fc0:	7ba2                	ld	s7,40(sp)
    80003fc2:	7c02                	ld	s8,32(sp)
    80003fc4:	6ce2                	ld	s9,24(sp)
    80003fc6:	6d42                	ld	s10,16(sp)
    80003fc8:	6da2                	ld	s11,8(sp)
    80003fca:	6165                	addi	sp,sp,112
    80003fcc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fce:	89da                	mv	s3,s6
    80003fd0:	bff1                	j	80003fac <readi+0xce>
    return 0;
    80003fd2:	4501                	li	a0,0
}
    80003fd4:	8082                	ret

0000000080003fd6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fd6:	497c                	lw	a5,84(a0)
    80003fd8:	10d7e763          	bltu	a5,a3,800040e6 <writei+0x110>
{
    80003fdc:	7159                	addi	sp,sp,-112
    80003fde:	f486                	sd	ra,104(sp)
    80003fe0:	f0a2                	sd	s0,96(sp)
    80003fe2:	eca6                	sd	s1,88(sp)
    80003fe4:	e8ca                	sd	s2,80(sp)
    80003fe6:	e4ce                	sd	s3,72(sp)
    80003fe8:	e0d2                	sd	s4,64(sp)
    80003fea:	fc56                	sd	s5,56(sp)
    80003fec:	f85a                	sd	s6,48(sp)
    80003fee:	f45e                	sd	s7,40(sp)
    80003ff0:	f062                	sd	s8,32(sp)
    80003ff2:	ec66                	sd	s9,24(sp)
    80003ff4:	e86a                	sd	s10,16(sp)
    80003ff6:	e46e                	sd	s11,8(sp)
    80003ff8:	1880                	addi	s0,sp,112
    80003ffa:	8baa                	mv	s7,a0
    80003ffc:	8c2e                	mv	s8,a1
    80003ffe:	8ab2                	mv	s5,a2
    80004000:	8936                	mv	s2,a3
    80004002:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004004:	00e687bb          	addw	a5,a3,a4
    80004008:	0ed7e163          	bltu	a5,a3,800040ea <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000400c:	00043737          	lui	a4,0x43
    80004010:	0cf76f63          	bltu	a4,a5,800040ee <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004014:	0a0b0863          	beqz	s6,800040c4 <writei+0xee>
    80004018:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000401a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000401e:	5cfd                	li	s9,-1
    80004020:	a091                	j	80004064 <writei+0x8e>
    80004022:	02099d93          	slli	s11,s3,0x20
    80004026:	020ddd93          	srli	s11,s11,0x20
    8000402a:	05848513          	addi	a0,s1,88
    8000402e:	86ee                	mv	a3,s11
    80004030:	8656                	mv	a2,s5
    80004032:	85e2                	mv	a1,s8
    80004034:	953a                	add	a0,a0,a4
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	848080e7          	jalr	-1976(ra) # 8000287e <either_copyin>
    8000403e:	07950263          	beq	a0,s9,800040a2 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80004042:	8526                	mv	a0,s1
    80004044:	00000097          	auipc	ra,0x0
    80004048:	78e080e7          	jalr	1934(ra) # 800047d2 <log_write>
    brelse(bp);
    8000404c:	8526                	mv	a0,s1
    8000404e:	fffff097          	auipc	ra,0xfffff
    80004052:	4cc080e7          	jalr	1228(ra) # 8000351a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004056:	01498a3b          	addw	s4,s3,s4
    8000405a:	0129893b          	addw	s2,s3,s2
    8000405e:	9aee                	add	s5,s5,s11
    80004060:	056a7763          	bgeu	s4,s6,800040ae <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004064:	000ba483          	lw	s1,0(s7)
    80004068:	00a9559b          	srliw	a1,s2,0xa
    8000406c:	855e                	mv	a0,s7
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	7ae080e7          	jalr	1966(ra) # 8000381c <bmap>
    80004076:	0005059b          	sext.w	a1,a0
    8000407a:	8526                	mv	a0,s1
    8000407c:	fffff097          	auipc	ra,0xfffff
    80004080:	1a0080e7          	jalr	416(ra) # 8000321c <bread>
    80004084:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004086:	3ff97713          	andi	a4,s2,1023
    8000408a:	40ed07bb          	subw	a5,s10,a4
    8000408e:	414b06bb          	subw	a3,s6,s4
    80004092:	89be                	mv	s3,a5
    80004094:	2781                	sext.w	a5,a5
    80004096:	0006861b          	sext.w	a2,a3
    8000409a:	f8f674e3          	bgeu	a2,a5,80004022 <writei+0x4c>
    8000409e:	89b6                	mv	s3,a3
    800040a0:	b749                	j	80004022 <writei+0x4c>
      brelse(bp);
    800040a2:	8526                	mv	a0,s1
    800040a4:	fffff097          	auipc	ra,0xfffff
    800040a8:	476080e7          	jalr	1142(ra) # 8000351a <brelse>
      n = -1;
    800040ac:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    800040ae:	054ba783          	lw	a5,84(s7)
    800040b2:	0127f463          	bgeu	a5,s2,800040ba <writei+0xe4>
      ip->size = off;
    800040b6:	052baa23          	sw	s2,84(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    800040ba:	855e                	mv	a0,s7
    800040bc:	00000097          	auipc	ra,0x0
    800040c0:	aa4080e7          	jalr	-1372(ra) # 80003b60 <iupdate>
  }

  return n;
    800040c4:	000b051b          	sext.w	a0,s6
}
    800040c8:	70a6                	ld	ra,104(sp)
    800040ca:	7406                	ld	s0,96(sp)
    800040cc:	64e6                	ld	s1,88(sp)
    800040ce:	6946                	ld	s2,80(sp)
    800040d0:	69a6                	ld	s3,72(sp)
    800040d2:	6a06                	ld	s4,64(sp)
    800040d4:	7ae2                	ld	s5,56(sp)
    800040d6:	7b42                	ld	s6,48(sp)
    800040d8:	7ba2                	ld	s7,40(sp)
    800040da:	7c02                	ld	s8,32(sp)
    800040dc:	6ce2                	ld	s9,24(sp)
    800040de:	6d42                	ld	s10,16(sp)
    800040e0:	6da2                	ld	s11,8(sp)
    800040e2:	6165                	addi	sp,sp,112
    800040e4:	8082                	ret
    return -1;
    800040e6:	557d                	li	a0,-1
}
    800040e8:	8082                	ret
    return -1;
    800040ea:	557d                	li	a0,-1
    800040ec:	bff1                	j	800040c8 <writei+0xf2>
    return -1;
    800040ee:	557d                	li	a0,-1
    800040f0:	bfe1                	j	800040c8 <writei+0xf2>

00000000800040f2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040f2:	1141                	addi	sp,sp,-16
    800040f4:	e406                	sd	ra,8(sp)
    800040f6:	e022                	sd	s0,0(sp)
    800040f8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040fa:	4639                	li	a2,14
    800040fc:	ffffd097          	auipc	ra,0xffffd
    80004100:	12e080e7          	jalr	302(ra) # 8000122a <strncmp>
}
    80004104:	60a2                	ld	ra,8(sp)
    80004106:	6402                	ld	s0,0(sp)
    80004108:	0141                	addi	sp,sp,16
    8000410a:	8082                	ret

000000008000410c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000410c:	7139                	addi	sp,sp,-64
    8000410e:	fc06                	sd	ra,56(sp)
    80004110:	f822                	sd	s0,48(sp)
    80004112:	f426                	sd	s1,40(sp)
    80004114:	f04a                	sd	s2,32(sp)
    80004116:	ec4e                	sd	s3,24(sp)
    80004118:	e852                	sd	s4,16(sp)
    8000411a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000411c:	04c51703          	lh	a4,76(a0)
    80004120:	4785                	li	a5,1
    80004122:	00f71a63          	bne	a4,a5,80004136 <dirlookup+0x2a>
    80004126:	892a                	mv	s2,a0
    80004128:	89ae                	mv	s3,a1
    8000412a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000412c:	497c                	lw	a5,84(a0)
    8000412e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004130:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004132:	e79d                	bnez	a5,80004160 <dirlookup+0x54>
    80004134:	a8a5                	j	800041ac <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004136:	00004517          	auipc	a0,0x4
    8000413a:	54250513          	addi	a0,a0,1346 # 80008678 <syscalls+0x1b8>
    8000413e:	ffffc097          	auipc	ra,0xffffc
    80004142:	412080e7          	jalr	1042(ra) # 80000550 <panic>
      panic("dirlookup read");
    80004146:	00004517          	auipc	a0,0x4
    8000414a:	54a50513          	addi	a0,a0,1354 # 80008690 <syscalls+0x1d0>
    8000414e:	ffffc097          	auipc	ra,0xffffc
    80004152:	402080e7          	jalr	1026(ra) # 80000550 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004156:	24c1                	addiw	s1,s1,16
    80004158:	05492783          	lw	a5,84(s2)
    8000415c:	04f4f763          	bgeu	s1,a5,800041aa <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004160:	4741                	li	a4,16
    80004162:	86a6                	mv	a3,s1
    80004164:	fc040613          	addi	a2,s0,-64
    80004168:	4581                	li	a1,0
    8000416a:	854a                	mv	a0,s2
    8000416c:	00000097          	auipc	ra,0x0
    80004170:	d72080e7          	jalr	-654(ra) # 80003ede <readi>
    80004174:	47c1                	li	a5,16
    80004176:	fcf518e3          	bne	a0,a5,80004146 <dirlookup+0x3a>
    if(de.inum == 0)
    8000417a:	fc045783          	lhu	a5,-64(s0)
    8000417e:	dfe1                	beqz	a5,80004156 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004180:	fc240593          	addi	a1,s0,-62
    80004184:	854e                	mv	a0,s3
    80004186:	00000097          	auipc	ra,0x0
    8000418a:	f6c080e7          	jalr	-148(ra) # 800040f2 <namecmp>
    8000418e:	f561                	bnez	a0,80004156 <dirlookup+0x4a>
      if(poff)
    80004190:	000a0463          	beqz	s4,80004198 <dirlookup+0x8c>
        *poff = off;
    80004194:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004198:	fc045583          	lhu	a1,-64(s0)
    8000419c:	00092503          	lw	a0,0(s2)
    800041a0:	fffff097          	auipc	ra,0xfffff
    800041a4:	756080e7          	jalr	1878(ra) # 800038f6 <iget>
    800041a8:	a011                	j	800041ac <dirlookup+0xa0>
  return 0;
    800041aa:	4501                	li	a0,0
}
    800041ac:	70e2                	ld	ra,56(sp)
    800041ae:	7442                	ld	s0,48(sp)
    800041b0:	74a2                	ld	s1,40(sp)
    800041b2:	7902                	ld	s2,32(sp)
    800041b4:	69e2                	ld	s3,24(sp)
    800041b6:	6a42                	ld	s4,16(sp)
    800041b8:	6121                	addi	sp,sp,64
    800041ba:	8082                	ret

00000000800041bc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041bc:	711d                	addi	sp,sp,-96
    800041be:	ec86                	sd	ra,88(sp)
    800041c0:	e8a2                	sd	s0,80(sp)
    800041c2:	e4a6                	sd	s1,72(sp)
    800041c4:	e0ca                	sd	s2,64(sp)
    800041c6:	fc4e                	sd	s3,56(sp)
    800041c8:	f852                	sd	s4,48(sp)
    800041ca:	f456                	sd	s5,40(sp)
    800041cc:	f05a                	sd	s6,32(sp)
    800041ce:	ec5e                	sd	s7,24(sp)
    800041d0:	e862                	sd	s8,16(sp)
    800041d2:	e466                	sd	s9,8(sp)
    800041d4:	1080                	addi	s0,sp,96
    800041d6:	84aa                	mv	s1,a0
    800041d8:	8b2e                	mv	s6,a1
    800041da:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041dc:	00054703          	lbu	a4,0(a0)
    800041e0:	02f00793          	li	a5,47
    800041e4:	02f70363          	beq	a4,a5,8000420a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041e8:	ffffe097          	auipc	ra,0xffffe
    800041ec:	bce080e7          	jalr	-1074(ra) # 80001db6 <myproc>
    800041f0:	15853503          	ld	a0,344(a0)
    800041f4:	00000097          	auipc	ra,0x0
    800041f8:	9f8080e7          	jalr	-1544(ra) # 80003bec <idup>
    800041fc:	89aa                	mv	s3,a0
  while(*path == '/')
    800041fe:	02f00913          	li	s2,47
  len = path - s;
    80004202:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004204:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004206:	4c05                	li	s8,1
    80004208:	a865                	j	800042c0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000420a:	4585                	li	a1,1
    8000420c:	4505                	li	a0,1
    8000420e:	fffff097          	auipc	ra,0xfffff
    80004212:	6e8080e7          	jalr	1768(ra) # 800038f6 <iget>
    80004216:	89aa                	mv	s3,a0
    80004218:	b7dd                	j	800041fe <namex+0x42>
      iunlockput(ip);
    8000421a:	854e                	mv	a0,s3
    8000421c:	00000097          	auipc	ra,0x0
    80004220:	c70080e7          	jalr	-912(ra) # 80003e8c <iunlockput>
      return 0;
    80004224:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004226:	854e                	mv	a0,s3
    80004228:	60e6                	ld	ra,88(sp)
    8000422a:	6446                	ld	s0,80(sp)
    8000422c:	64a6                	ld	s1,72(sp)
    8000422e:	6906                	ld	s2,64(sp)
    80004230:	79e2                	ld	s3,56(sp)
    80004232:	7a42                	ld	s4,48(sp)
    80004234:	7aa2                	ld	s5,40(sp)
    80004236:	7b02                	ld	s6,32(sp)
    80004238:	6be2                	ld	s7,24(sp)
    8000423a:	6c42                	ld	s8,16(sp)
    8000423c:	6ca2                	ld	s9,8(sp)
    8000423e:	6125                	addi	sp,sp,96
    80004240:	8082                	ret
      iunlock(ip);
    80004242:	854e                	mv	a0,s3
    80004244:	00000097          	auipc	ra,0x0
    80004248:	aa8080e7          	jalr	-1368(ra) # 80003cec <iunlock>
      return ip;
    8000424c:	bfe9                	j	80004226 <namex+0x6a>
      iunlockput(ip);
    8000424e:	854e                	mv	a0,s3
    80004250:	00000097          	auipc	ra,0x0
    80004254:	c3c080e7          	jalr	-964(ra) # 80003e8c <iunlockput>
      return 0;
    80004258:	89d2                	mv	s3,s4
    8000425a:	b7f1                	j	80004226 <namex+0x6a>
  len = path - s;
    8000425c:	40b48633          	sub	a2,s1,a1
    80004260:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004264:	094cd463          	bge	s9,s4,800042ec <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004268:	4639                	li	a2,14
    8000426a:	8556                	mv	a0,s5
    8000426c:	ffffd097          	auipc	ra,0xffffd
    80004270:	f42080e7          	jalr	-190(ra) # 800011ae <memmove>
  while(*path == '/')
    80004274:	0004c783          	lbu	a5,0(s1)
    80004278:	01279763          	bne	a5,s2,80004286 <namex+0xca>
    path++;
    8000427c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000427e:	0004c783          	lbu	a5,0(s1)
    80004282:	ff278de3          	beq	a5,s2,8000427c <namex+0xc0>
    ilock(ip);
    80004286:	854e                	mv	a0,s3
    80004288:	00000097          	auipc	ra,0x0
    8000428c:	9a2080e7          	jalr	-1630(ra) # 80003c2a <ilock>
    if(ip->type != T_DIR){
    80004290:	04c99783          	lh	a5,76(s3)
    80004294:	f98793e3          	bne	a5,s8,8000421a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004298:	000b0563          	beqz	s6,800042a2 <namex+0xe6>
    8000429c:	0004c783          	lbu	a5,0(s1)
    800042a0:	d3cd                	beqz	a5,80004242 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042a2:	865e                	mv	a2,s7
    800042a4:	85d6                	mv	a1,s5
    800042a6:	854e                	mv	a0,s3
    800042a8:	00000097          	auipc	ra,0x0
    800042ac:	e64080e7          	jalr	-412(ra) # 8000410c <dirlookup>
    800042b0:	8a2a                	mv	s4,a0
    800042b2:	dd51                	beqz	a0,8000424e <namex+0x92>
    iunlockput(ip);
    800042b4:	854e                	mv	a0,s3
    800042b6:	00000097          	auipc	ra,0x0
    800042ba:	bd6080e7          	jalr	-1066(ra) # 80003e8c <iunlockput>
    ip = next;
    800042be:	89d2                	mv	s3,s4
  while(*path == '/')
    800042c0:	0004c783          	lbu	a5,0(s1)
    800042c4:	05279763          	bne	a5,s2,80004312 <namex+0x156>
    path++;
    800042c8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042ca:	0004c783          	lbu	a5,0(s1)
    800042ce:	ff278de3          	beq	a5,s2,800042c8 <namex+0x10c>
  if(*path == 0)
    800042d2:	c79d                	beqz	a5,80004300 <namex+0x144>
    path++;
    800042d4:	85a6                	mv	a1,s1
  len = path - s;
    800042d6:	8a5e                	mv	s4,s7
    800042d8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800042da:	01278963          	beq	a5,s2,800042ec <namex+0x130>
    800042de:	dfbd                	beqz	a5,8000425c <namex+0xa0>
    path++;
    800042e0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800042e2:	0004c783          	lbu	a5,0(s1)
    800042e6:	ff279ce3          	bne	a5,s2,800042de <namex+0x122>
    800042ea:	bf8d                	j	8000425c <namex+0xa0>
    memmove(name, s, len);
    800042ec:	2601                	sext.w	a2,a2
    800042ee:	8556                	mv	a0,s5
    800042f0:	ffffd097          	auipc	ra,0xffffd
    800042f4:	ebe080e7          	jalr	-322(ra) # 800011ae <memmove>
    name[len] = 0;
    800042f8:	9a56                	add	s4,s4,s5
    800042fa:	000a0023          	sb	zero,0(s4)
    800042fe:	bf9d                	j	80004274 <namex+0xb8>
  if(nameiparent){
    80004300:	f20b03e3          	beqz	s6,80004226 <namex+0x6a>
    iput(ip);
    80004304:	854e                	mv	a0,s3
    80004306:	00000097          	auipc	ra,0x0
    8000430a:	ade080e7          	jalr	-1314(ra) # 80003de4 <iput>
    return 0;
    8000430e:	4981                	li	s3,0
    80004310:	bf19                	j	80004226 <namex+0x6a>
  if(*path == 0)
    80004312:	d7fd                	beqz	a5,80004300 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004314:	0004c783          	lbu	a5,0(s1)
    80004318:	85a6                	mv	a1,s1
    8000431a:	b7d1                	j	800042de <namex+0x122>

000000008000431c <dirlink>:
{
    8000431c:	7139                	addi	sp,sp,-64
    8000431e:	fc06                	sd	ra,56(sp)
    80004320:	f822                	sd	s0,48(sp)
    80004322:	f426                	sd	s1,40(sp)
    80004324:	f04a                	sd	s2,32(sp)
    80004326:	ec4e                	sd	s3,24(sp)
    80004328:	e852                	sd	s4,16(sp)
    8000432a:	0080                	addi	s0,sp,64
    8000432c:	892a                	mv	s2,a0
    8000432e:	8a2e                	mv	s4,a1
    80004330:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004332:	4601                	li	a2,0
    80004334:	00000097          	auipc	ra,0x0
    80004338:	dd8080e7          	jalr	-552(ra) # 8000410c <dirlookup>
    8000433c:	e93d                	bnez	a0,800043b2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000433e:	05492483          	lw	s1,84(s2)
    80004342:	c49d                	beqz	s1,80004370 <dirlink+0x54>
    80004344:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004346:	4741                	li	a4,16
    80004348:	86a6                	mv	a3,s1
    8000434a:	fc040613          	addi	a2,s0,-64
    8000434e:	4581                	li	a1,0
    80004350:	854a                	mv	a0,s2
    80004352:	00000097          	auipc	ra,0x0
    80004356:	b8c080e7          	jalr	-1140(ra) # 80003ede <readi>
    8000435a:	47c1                	li	a5,16
    8000435c:	06f51163          	bne	a0,a5,800043be <dirlink+0xa2>
    if(de.inum == 0)
    80004360:	fc045783          	lhu	a5,-64(s0)
    80004364:	c791                	beqz	a5,80004370 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004366:	24c1                	addiw	s1,s1,16
    80004368:	05492783          	lw	a5,84(s2)
    8000436c:	fcf4ede3          	bltu	s1,a5,80004346 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004370:	4639                	li	a2,14
    80004372:	85d2                	mv	a1,s4
    80004374:	fc240513          	addi	a0,s0,-62
    80004378:	ffffd097          	auipc	ra,0xffffd
    8000437c:	eee080e7          	jalr	-274(ra) # 80001266 <strncpy>
  de.inum = inum;
    80004380:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004384:	4741                	li	a4,16
    80004386:	86a6                	mv	a3,s1
    80004388:	fc040613          	addi	a2,s0,-64
    8000438c:	4581                	li	a1,0
    8000438e:	854a                	mv	a0,s2
    80004390:	00000097          	auipc	ra,0x0
    80004394:	c46080e7          	jalr	-954(ra) # 80003fd6 <writei>
    80004398:	872a                	mv	a4,a0
    8000439a:	47c1                	li	a5,16
  return 0;
    8000439c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000439e:	02f71863          	bne	a4,a5,800043ce <dirlink+0xb2>
}
    800043a2:	70e2                	ld	ra,56(sp)
    800043a4:	7442                	ld	s0,48(sp)
    800043a6:	74a2                	ld	s1,40(sp)
    800043a8:	7902                	ld	s2,32(sp)
    800043aa:	69e2                	ld	s3,24(sp)
    800043ac:	6a42                	ld	s4,16(sp)
    800043ae:	6121                	addi	sp,sp,64
    800043b0:	8082                	ret
    iput(ip);
    800043b2:	00000097          	auipc	ra,0x0
    800043b6:	a32080e7          	jalr	-1486(ra) # 80003de4 <iput>
    return -1;
    800043ba:	557d                	li	a0,-1
    800043bc:	b7dd                	j	800043a2 <dirlink+0x86>
      panic("dirlink read");
    800043be:	00004517          	auipc	a0,0x4
    800043c2:	2e250513          	addi	a0,a0,738 # 800086a0 <syscalls+0x1e0>
    800043c6:	ffffc097          	auipc	ra,0xffffc
    800043ca:	18a080e7          	jalr	394(ra) # 80000550 <panic>
    panic("dirlink");
    800043ce:	00004517          	auipc	a0,0x4
    800043d2:	3f250513          	addi	a0,a0,1010 # 800087c0 <syscalls+0x300>
    800043d6:	ffffc097          	auipc	ra,0xffffc
    800043da:	17a080e7          	jalr	378(ra) # 80000550 <panic>

00000000800043de <namei>:

struct inode*
namei(char *path)
{
    800043de:	1101                	addi	sp,sp,-32
    800043e0:	ec06                	sd	ra,24(sp)
    800043e2:	e822                	sd	s0,16(sp)
    800043e4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043e6:	fe040613          	addi	a2,s0,-32
    800043ea:	4581                	li	a1,0
    800043ec:	00000097          	auipc	ra,0x0
    800043f0:	dd0080e7          	jalr	-560(ra) # 800041bc <namex>
}
    800043f4:	60e2                	ld	ra,24(sp)
    800043f6:	6442                	ld	s0,16(sp)
    800043f8:	6105                	addi	sp,sp,32
    800043fa:	8082                	ret

00000000800043fc <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043fc:	1141                	addi	sp,sp,-16
    800043fe:	e406                	sd	ra,8(sp)
    80004400:	e022                	sd	s0,0(sp)
    80004402:	0800                	addi	s0,sp,16
    80004404:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004406:	4585                	li	a1,1
    80004408:	00000097          	auipc	ra,0x0
    8000440c:	db4080e7          	jalr	-588(ra) # 800041bc <namex>
}
    80004410:	60a2                	ld	ra,8(sp)
    80004412:	6402                	ld	s0,0(sp)
    80004414:	0141                	addi	sp,sp,16
    80004416:	8082                	ret

0000000080004418 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004418:	1101                	addi	sp,sp,-32
    8000441a:	ec06                	sd	ra,24(sp)
    8000441c:	e822                	sd	s0,16(sp)
    8000441e:	e426                	sd	s1,8(sp)
    80004420:	e04a                	sd	s2,0(sp)
    80004422:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004424:	00022917          	auipc	s2,0x22
    80004428:	8cc90913          	addi	s2,s2,-1844 # 80025cf0 <log>
    8000442c:	02092583          	lw	a1,32(s2)
    80004430:	03092503          	lw	a0,48(s2)
    80004434:	fffff097          	auipc	ra,0xfffff
    80004438:	de8080e7          	jalr	-536(ra) # 8000321c <bread>
    8000443c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000443e:	03492683          	lw	a3,52(s2)
    80004442:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004444:	02d05763          	blez	a3,80004472 <write_head+0x5a>
    80004448:	00022797          	auipc	a5,0x22
    8000444c:	8e078793          	addi	a5,a5,-1824 # 80025d28 <log+0x38>
    80004450:	05c50713          	addi	a4,a0,92
    80004454:	36fd                	addiw	a3,a3,-1
    80004456:	1682                	slli	a3,a3,0x20
    80004458:	9281                	srli	a3,a3,0x20
    8000445a:	068a                	slli	a3,a3,0x2
    8000445c:	00022617          	auipc	a2,0x22
    80004460:	8d060613          	addi	a2,a2,-1840 # 80025d2c <log+0x3c>
    80004464:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004466:	4390                	lw	a2,0(a5)
    80004468:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000446a:	0791                	addi	a5,a5,4
    8000446c:	0711                	addi	a4,a4,4
    8000446e:	fed79ce3          	bne	a5,a3,80004466 <write_head+0x4e>
  }
  bwrite(buf);
    80004472:	8526                	mv	a0,s1
    80004474:	fffff097          	auipc	ra,0xfffff
    80004478:	068080e7          	jalr	104(ra) # 800034dc <bwrite>
  brelse(buf);
    8000447c:	8526                	mv	a0,s1
    8000447e:	fffff097          	auipc	ra,0xfffff
    80004482:	09c080e7          	jalr	156(ra) # 8000351a <brelse>
}
    80004486:	60e2                	ld	ra,24(sp)
    80004488:	6442                	ld	s0,16(sp)
    8000448a:	64a2                	ld	s1,8(sp)
    8000448c:	6902                	ld	s2,0(sp)
    8000448e:	6105                	addi	sp,sp,32
    80004490:	8082                	ret

0000000080004492 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004492:	00022797          	auipc	a5,0x22
    80004496:	8927a783          	lw	a5,-1902(a5) # 80025d24 <log+0x34>
    8000449a:	0af05d63          	blez	a5,80004554 <install_trans+0xc2>
{
    8000449e:	7139                	addi	sp,sp,-64
    800044a0:	fc06                	sd	ra,56(sp)
    800044a2:	f822                	sd	s0,48(sp)
    800044a4:	f426                	sd	s1,40(sp)
    800044a6:	f04a                	sd	s2,32(sp)
    800044a8:	ec4e                	sd	s3,24(sp)
    800044aa:	e852                	sd	s4,16(sp)
    800044ac:	e456                	sd	s5,8(sp)
    800044ae:	e05a                	sd	s6,0(sp)
    800044b0:	0080                	addi	s0,sp,64
    800044b2:	8b2a                	mv	s6,a0
    800044b4:	00022a97          	auipc	s5,0x22
    800044b8:	874a8a93          	addi	s5,s5,-1932 # 80025d28 <log+0x38>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044bc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044be:	00022997          	auipc	s3,0x22
    800044c2:	83298993          	addi	s3,s3,-1998 # 80025cf0 <log>
    800044c6:	a035                	j	800044f2 <install_trans+0x60>
      bunpin(dbuf);
    800044c8:	8526                	mv	a0,s1
    800044ca:	fffff097          	auipc	ra,0xfffff
    800044ce:	148080e7          	jalr	328(ra) # 80003612 <bunpin>
    brelse(lbuf);
    800044d2:	854a                	mv	a0,s2
    800044d4:	fffff097          	auipc	ra,0xfffff
    800044d8:	046080e7          	jalr	70(ra) # 8000351a <brelse>
    brelse(dbuf);
    800044dc:	8526                	mv	a0,s1
    800044de:	fffff097          	auipc	ra,0xfffff
    800044e2:	03c080e7          	jalr	60(ra) # 8000351a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044e6:	2a05                	addiw	s4,s4,1
    800044e8:	0a91                	addi	s5,s5,4
    800044ea:	0349a783          	lw	a5,52(s3)
    800044ee:	04fa5963          	bge	s4,a5,80004540 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044f2:	0209a583          	lw	a1,32(s3)
    800044f6:	014585bb          	addw	a1,a1,s4
    800044fa:	2585                	addiw	a1,a1,1
    800044fc:	0309a503          	lw	a0,48(s3)
    80004500:	fffff097          	auipc	ra,0xfffff
    80004504:	d1c080e7          	jalr	-740(ra) # 8000321c <bread>
    80004508:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000450a:	000aa583          	lw	a1,0(s5)
    8000450e:	0309a503          	lw	a0,48(s3)
    80004512:	fffff097          	auipc	ra,0xfffff
    80004516:	d0a080e7          	jalr	-758(ra) # 8000321c <bread>
    8000451a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000451c:	40000613          	li	a2,1024
    80004520:	05890593          	addi	a1,s2,88
    80004524:	05850513          	addi	a0,a0,88
    80004528:	ffffd097          	auipc	ra,0xffffd
    8000452c:	c86080e7          	jalr	-890(ra) # 800011ae <memmove>
    bwrite(dbuf);  // write dst to disk
    80004530:	8526                	mv	a0,s1
    80004532:	fffff097          	auipc	ra,0xfffff
    80004536:	faa080e7          	jalr	-86(ra) # 800034dc <bwrite>
    if(recovering == 0)
    8000453a:	f80b1ce3          	bnez	s6,800044d2 <install_trans+0x40>
    8000453e:	b769                	j	800044c8 <install_trans+0x36>
}
    80004540:	70e2                	ld	ra,56(sp)
    80004542:	7442                	ld	s0,48(sp)
    80004544:	74a2                	ld	s1,40(sp)
    80004546:	7902                	ld	s2,32(sp)
    80004548:	69e2                	ld	s3,24(sp)
    8000454a:	6a42                	ld	s4,16(sp)
    8000454c:	6aa2                	ld	s5,8(sp)
    8000454e:	6b02                	ld	s6,0(sp)
    80004550:	6121                	addi	sp,sp,64
    80004552:	8082                	ret
    80004554:	8082                	ret

0000000080004556 <initlog>:
{
    80004556:	7179                	addi	sp,sp,-48
    80004558:	f406                	sd	ra,40(sp)
    8000455a:	f022                	sd	s0,32(sp)
    8000455c:	ec26                	sd	s1,24(sp)
    8000455e:	e84a                	sd	s2,16(sp)
    80004560:	e44e                	sd	s3,8(sp)
    80004562:	1800                	addi	s0,sp,48
    80004564:	892a                	mv	s2,a0
    80004566:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004568:	00021497          	auipc	s1,0x21
    8000456c:	78848493          	addi	s1,s1,1928 # 80025cf0 <log>
    80004570:	00004597          	auipc	a1,0x4
    80004574:	14058593          	addi	a1,a1,320 # 800086b0 <syscalls+0x1f0>
    80004578:	8526                	mv	a0,s1
    8000457a:	ffffd097          	auipc	ra,0xffffd
    8000457e:	970080e7          	jalr	-1680(ra) # 80000eea <initlock>
  log.start = sb->logstart;
    80004582:	0149a583          	lw	a1,20(s3)
    80004586:	d08c                	sw	a1,32(s1)
  log.size = sb->nlog;
    80004588:	0109a783          	lw	a5,16(s3)
    8000458c:	d0dc                	sw	a5,36(s1)
  log.dev = dev;
    8000458e:	0324a823          	sw	s2,48(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004592:	854a                	mv	a0,s2
    80004594:	fffff097          	auipc	ra,0xfffff
    80004598:	c88080e7          	jalr	-888(ra) # 8000321c <bread>
  log.lh.n = lh->n;
    8000459c:	4d3c                	lw	a5,88(a0)
    8000459e:	d8dc                	sw	a5,52(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045a0:	02f05563          	blez	a5,800045ca <initlog+0x74>
    800045a4:	05c50713          	addi	a4,a0,92
    800045a8:	00021697          	auipc	a3,0x21
    800045ac:	78068693          	addi	a3,a3,1920 # 80025d28 <log+0x38>
    800045b0:	37fd                	addiw	a5,a5,-1
    800045b2:	1782                	slli	a5,a5,0x20
    800045b4:	9381                	srli	a5,a5,0x20
    800045b6:	078a                	slli	a5,a5,0x2
    800045b8:	06050613          	addi	a2,a0,96
    800045bc:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800045be:	4310                	lw	a2,0(a4)
    800045c0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800045c2:	0711                	addi	a4,a4,4
    800045c4:	0691                	addi	a3,a3,4
    800045c6:	fef71ce3          	bne	a4,a5,800045be <initlog+0x68>
  brelse(buf);
    800045ca:	fffff097          	auipc	ra,0xfffff
    800045ce:	f50080e7          	jalr	-176(ra) # 8000351a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045d2:	4505                	li	a0,1
    800045d4:	00000097          	auipc	ra,0x0
    800045d8:	ebe080e7          	jalr	-322(ra) # 80004492 <install_trans>
  log.lh.n = 0;
    800045dc:	00021797          	auipc	a5,0x21
    800045e0:	7407a423          	sw	zero,1864(a5) # 80025d24 <log+0x34>
  write_head(); // clear the log
    800045e4:	00000097          	auipc	ra,0x0
    800045e8:	e34080e7          	jalr	-460(ra) # 80004418 <write_head>
}
    800045ec:	70a2                	ld	ra,40(sp)
    800045ee:	7402                	ld	s0,32(sp)
    800045f0:	64e2                	ld	s1,24(sp)
    800045f2:	6942                	ld	s2,16(sp)
    800045f4:	69a2                	ld	s3,8(sp)
    800045f6:	6145                	addi	sp,sp,48
    800045f8:	8082                	ret

00000000800045fa <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045fa:	1101                	addi	sp,sp,-32
    800045fc:	ec06                	sd	ra,24(sp)
    800045fe:	e822                	sd	s0,16(sp)
    80004600:	e426                	sd	s1,8(sp)
    80004602:	e04a                	sd	s2,0(sp)
    80004604:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004606:	00021517          	auipc	a0,0x21
    8000460a:	6ea50513          	addi	a0,a0,1770 # 80025cf0 <log>
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	760080e7          	jalr	1888(ra) # 80000d6e <acquire>
  while(1){
    if(log.committing){
    80004616:	00021497          	auipc	s1,0x21
    8000461a:	6da48493          	addi	s1,s1,1754 # 80025cf0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000461e:	4979                	li	s2,30
    80004620:	a039                	j	8000462e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004622:	85a6                	mv	a1,s1
    80004624:	8526                	mv	a0,s1
    80004626:	ffffe097          	auipc	ra,0xffffe
    8000462a:	fa0080e7          	jalr	-96(ra) # 800025c6 <sleep>
    if(log.committing){
    8000462e:	54dc                	lw	a5,44(s1)
    80004630:	fbed                	bnez	a5,80004622 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004632:	549c                	lw	a5,40(s1)
    80004634:	0017871b          	addiw	a4,a5,1
    80004638:	0007069b          	sext.w	a3,a4
    8000463c:	0027179b          	slliw	a5,a4,0x2
    80004640:	9fb9                	addw	a5,a5,a4
    80004642:	0017979b          	slliw	a5,a5,0x1
    80004646:	58d8                	lw	a4,52(s1)
    80004648:	9fb9                	addw	a5,a5,a4
    8000464a:	00f95963          	bge	s2,a5,8000465c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000464e:	85a6                	mv	a1,s1
    80004650:	8526                	mv	a0,s1
    80004652:	ffffe097          	auipc	ra,0xffffe
    80004656:	f74080e7          	jalr	-140(ra) # 800025c6 <sleep>
    8000465a:	bfd1                	j	8000462e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000465c:	00021517          	auipc	a0,0x21
    80004660:	69450513          	addi	a0,a0,1684 # 80025cf0 <log>
    80004664:	d514                	sw	a3,40(a0)
      release(&log.lock);
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	7d8080e7          	jalr	2008(ra) # 80000e3e <release>
      break;
    }
  }
}
    8000466e:	60e2                	ld	ra,24(sp)
    80004670:	6442                	ld	s0,16(sp)
    80004672:	64a2                	ld	s1,8(sp)
    80004674:	6902                	ld	s2,0(sp)
    80004676:	6105                	addi	sp,sp,32
    80004678:	8082                	ret

000000008000467a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
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
  int do_commit = 0;

  acquire(&log.lock);
    8000468c:	00021497          	auipc	s1,0x21
    80004690:	66448493          	addi	s1,s1,1636 # 80025cf0 <log>
    80004694:	8526                	mv	a0,s1
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	6d8080e7          	jalr	1752(ra) # 80000d6e <acquire>
  log.outstanding -= 1;
    8000469e:	549c                	lw	a5,40(s1)
    800046a0:	37fd                	addiw	a5,a5,-1
    800046a2:	0007891b          	sext.w	s2,a5
    800046a6:	d49c                	sw	a5,40(s1)
  if(log.committing)
    800046a8:	54dc                	lw	a5,44(s1)
    800046aa:	efb9                	bnez	a5,80004708 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046ac:	06091663          	bnez	s2,80004718 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800046b0:	00021497          	auipc	s1,0x21
    800046b4:	64048493          	addi	s1,s1,1600 # 80025cf0 <log>
    800046b8:	4785                	li	a5,1
    800046ba:	d4dc                	sw	a5,44(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046bc:	8526                	mv	a0,s1
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	780080e7          	jalr	1920(ra) # 80000e3e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046c6:	58dc                	lw	a5,52(s1)
    800046c8:	06f04763          	bgtz	a5,80004736 <end_op+0xbc>
    acquire(&log.lock);
    800046cc:	00021497          	auipc	s1,0x21
    800046d0:	62448493          	addi	s1,s1,1572 # 80025cf0 <log>
    800046d4:	8526                	mv	a0,s1
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	698080e7          	jalr	1688(ra) # 80000d6e <acquire>
    log.committing = 0;
    800046de:	0204a623          	sw	zero,44(s1)
    wakeup(&log);
    800046e2:	8526                	mv	a0,s1
    800046e4:	ffffe097          	auipc	ra,0xffffe
    800046e8:	068080e7          	jalr	104(ra) # 8000274c <wakeup>
    release(&log.lock);
    800046ec:	8526                	mv	a0,s1
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	750080e7          	jalr	1872(ra) # 80000e3e <release>
}
    800046f6:	70e2                	ld	ra,56(sp)
    800046f8:	7442                	ld	s0,48(sp)
    800046fa:	74a2                	ld	s1,40(sp)
    800046fc:	7902                	ld	s2,32(sp)
    800046fe:	69e2                	ld	s3,24(sp)
    80004700:	6a42                	ld	s4,16(sp)
    80004702:	6aa2                	ld	s5,8(sp)
    80004704:	6121                	addi	sp,sp,64
    80004706:	8082                	ret
    panic("log.committing");
    80004708:	00004517          	auipc	a0,0x4
    8000470c:	fb050513          	addi	a0,a0,-80 # 800086b8 <syscalls+0x1f8>
    80004710:	ffffc097          	auipc	ra,0xffffc
    80004714:	e40080e7          	jalr	-448(ra) # 80000550 <panic>
    wakeup(&log);
    80004718:	00021497          	auipc	s1,0x21
    8000471c:	5d848493          	addi	s1,s1,1496 # 80025cf0 <log>
    80004720:	8526                	mv	a0,s1
    80004722:	ffffe097          	auipc	ra,0xffffe
    80004726:	02a080e7          	jalr	42(ra) # 8000274c <wakeup>
  release(&log.lock);
    8000472a:	8526                	mv	a0,s1
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	712080e7          	jalr	1810(ra) # 80000e3e <release>
  if(do_commit){
    80004734:	b7c9                	j	800046f6 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004736:	00021a97          	auipc	s5,0x21
    8000473a:	5f2a8a93          	addi	s5,s5,1522 # 80025d28 <log+0x38>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000473e:	00021a17          	auipc	s4,0x21
    80004742:	5b2a0a13          	addi	s4,s4,1458 # 80025cf0 <log>
    80004746:	020a2583          	lw	a1,32(s4)
    8000474a:	012585bb          	addw	a1,a1,s2
    8000474e:	2585                	addiw	a1,a1,1
    80004750:	030a2503          	lw	a0,48(s4)
    80004754:	fffff097          	auipc	ra,0xfffff
    80004758:	ac8080e7          	jalr	-1336(ra) # 8000321c <bread>
    8000475c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000475e:	000aa583          	lw	a1,0(s5)
    80004762:	030a2503          	lw	a0,48(s4)
    80004766:	fffff097          	auipc	ra,0xfffff
    8000476a:	ab6080e7          	jalr	-1354(ra) # 8000321c <bread>
    8000476e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004770:	40000613          	li	a2,1024
    80004774:	05850593          	addi	a1,a0,88
    80004778:	05848513          	addi	a0,s1,88
    8000477c:	ffffd097          	auipc	ra,0xffffd
    80004780:	a32080e7          	jalr	-1486(ra) # 800011ae <memmove>
    bwrite(to);  // write the log
    80004784:	8526                	mv	a0,s1
    80004786:	fffff097          	auipc	ra,0xfffff
    8000478a:	d56080e7          	jalr	-682(ra) # 800034dc <bwrite>
    brelse(from);
    8000478e:	854e                	mv	a0,s3
    80004790:	fffff097          	auipc	ra,0xfffff
    80004794:	d8a080e7          	jalr	-630(ra) # 8000351a <brelse>
    brelse(to);
    80004798:	8526                	mv	a0,s1
    8000479a:	fffff097          	auipc	ra,0xfffff
    8000479e:	d80080e7          	jalr	-640(ra) # 8000351a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047a2:	2905                	addiw	s2,s2,1
    800047a4:	0a91                	addi	s5,s5,4
    800047a6:	034a2783          	lw	a5,52(s4)
    800047aa:	f8f94ee3          	blt	s2,a5,80004746 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047ae:	00000097          	auipc	ra,0x0
    800047b2:	c6a080e7          	jalr	-918(ra) # 80004418 <write_head>
    install_trans(0); // Now install writes to home locations
    800047b6:	4501                	li	a0,0
    800047b8:	00000097          	auipc	ra,0x0
    800047bc:	cda080e7          	jalr	-806(ra) # 80004492 <install_trans>
    log.lh.n = 0;
    800047c0:	00021797          	auipc	a5,0x21
    800047c4:	5607a223          	sw	zero,1380(a5) # 80025d24 <log+0x34>
    write_head();    // Erase the transaction from the log
    800047c8:	00000097          	auipc	ra,0x0
    800047cc:	c50080e7          	jalr	-944(ra) # 80004418 <write_head>
    800047d0:	bdf5                	j	800046cc <end_op+0x52>

00000000800047d2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047d2:	1101                	addi	sp,sp,-32
    800047d4:	ec06                	sd	ra,24(sp)
    800047d6:	e822                	sd	s0,16(sp)
    800047d8:	e426                	sd	s1,8(sp)
    800047da:	e04a                	sd	s2,0(sp)
    800047dc:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047de:	00021717          	auipc	a4,0x21
    800047e2:	54672703          	lw	a4,1350(a4) # 80025d24 <log+0x34>
    800047e6:	47f5                	li	a5,29
    800047e8:	08e7c063          	blt	a5,a4,80004868 <log_write+0x96>
    800047ec:	84aa                	mv	s1,a0
    800047ee:	00021797          	auipc	a5,0x21
    800047f2:	5267a783          	lw	a5,1318(a5) # 80025d14 <log+0x24>
    800047f6:	37fd                	addiw	a5,a5,-1
    800047f8:	06f75863          	bge	a4,a5,80004868 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047fc:	00021797          	auipc	a5,0x21
    80004800:	51c7a783          	lw	a5,1308(a5) # 80025d18 <log+0x28>
    80004804:	06f05a63          	blez	a5,80004878 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004808:	00021917          	auipc	s2,0x21
    8000480c:	4e890913          	addi	s2,s2,1256 # 80025cf0 <log>
    80004810:	854a                	mv	a0,s2
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	55c080e7          	jalr	1372(ra) # 80000d6e <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000481a:	03492603          	lw	a2,52(s2)
    8000481e:	06c05563          	blez	a2,80004888 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004822:	44cc                	lw	a1,12(s1)
    80004824:	00021717          	auipc	a4,0x21
    80004828:	50470713          	addi	a4,a4,1284 # 80025d28 <log+0x38>
  for (i = 0; i < log.lh.n; i++) {
    8000482c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000482e:	4314                	lw	a3,0(a4)
    80004830:	04b68d63          	beq	a3,a1,8000488a <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004834:	2785                	addiw	a5,a5,1
    80004836:	0711                	addi	a4,a4,4
    80004838:	fec79be3          	bne	a5,a2,8000482e <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000483c:	0631                	addi	a2,a2,12
    8000483e:	060a                	slli	a2,a2,0x2
    80004840:	00021797          	auipc	a5,0x21
    80004844:	4b078793          	addi	a5,a5,1200 # 80025cf0 <log>
    80004848:	963e                	add	a2,a2,a5
    8000484a:	44dc                	lw	a5,12(s1)
    8000484c:	c61c                	sw	a5,8(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000484e:	8526                	mv	a0,s1
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	d66080e7          	jalr	-666(ra) # 800035b6 <bpin>
    log.lh.n++;
    80004858:	00021717          	auipc	a4,0x21
    8000485c:	49870713          	addi	a4,a4,1176 # 80025cf0 <log>
    80004860:	5b5c                	lw	a5,52(a4)
    80004862:	2785                	addiw	a5,a5,1
    80004864:	db5c                	sw	a5,52(a4)
    80004866:	a83d                	j	800048a4 <log_write+0xd2>
    panic("too big a transaction");
    80004868:	00004517          	auipc	a0,0x4
    8000486c:	e6050513          	addi	a0,a0,-416 # 800086c8 <syscalls+0x208>
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	ce0080e7          	jalr	-800(ra) # 80000550 <panic>
    panic("log_write outside of trans");
    80004878:	00004517          	auipc	a0,0x4
    8000487c:	e6850513          	addi	a0,a0,-408 # 800086e0 <syscalls+0x220>
    80004880:	ffffc097          	auipc	ra,0xffffc
    80004884:	cd0080e7          	jalr	-816(ra) # 80000550 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004888:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000488a:	00c78713          	addi	a4,a5,12
    8000488e:	00271693          	slli	a3,a4,0x2
    80004892:	00021717          	auipc	a4,0x21
    80004896:	45e70713          	addi	a4,a4,1118 # 80025cf0 <log>
    8000489a:	9736                	add	a4,a4,a3
    8000489c:	44d4                	lw	a3,12(s1)
    8000489e:	c714                	sw	a3,8(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800048a0:	faf607e3          	beq	a2,a5,8000484e <log_write+0x7c>
  }
  release(&log.lock);
    800048a4:	00021517          	auipc	a0,0x21
    800048a8:	44c50513          	addi	a0,a0,1100 # 80025cf0 <log>
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	592080e7          	jalr	1426(ra) # 80000e3e <release>
}
    800048b4:	60e2                	ld	ra,24(sp)
    800048b6:	6442                	ld	s0,16(sp)
    800048b8:	64a2                	ld	s1,8(sp)
    800048ba:	6902                	ld	s2,0(sp)
    800048bc:	6105                	addi	sp,sp,32
    800048be:	8082                	ret

00000000800048c0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048c0:	1101                	addi	sp,sp,-32
    800048c2:	ec06                	sd	ra,24(sp)
    800048c4:	e822                	sd	s0,16(sp)
    800048c6:	e426                	sd	s1,8(sp)
    800048c8:	e04a                	sd	s2,0(sp)
    800048ca:	1000                	addi	s0,sp,32
    800048cc:	84aa                	mv	s1,a0
    800048ce:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048d0:	00004597          	auipc	a1,0x4
    800048d4:	e3058593          	addi	a1,a1,-464 # 80008700 <syscalls+0x240>
    800048d8:	0521                	addi	a0,a0,8
    800048da:	ffffc097          	auipc	ra,0xffffc
    800048de:	610080e7          	jalr	1552(ra) # 80000eea <initlock>
  lk->name = name;
    800048e2:	0324b423          	sd	s2,40(s1)
  lk->locked = 0;
    800048e6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048ea:	0204a823          	sw	zero,48(s1)
}
    800048ee:	60e2                	ld	ra,24(sp)
    800048f0:	6442                	ld	s0,16(sp)
    800048f2:	64a2                	ld	s1,8(sp)
    800048f4:	6902                	ld	s2,0(sp)
    800048f6:	6105                	addi	sp,sp,32
    800048f8:	8082                	ret

00000000800048fa <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048fa:	1101                	addi	sp,sp,-32
    800048fc:	ec06                	sd	ra,24(sp)
    800048fe:	e822                	sd	s0,16(sp)
    80004900:	e426                	sd	s1,8(sp)
    80004902:	e04a                	sd	s2,0(sp)
    80004904:	1000                	addi	s0,sp,32
    80004906:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004908:	00850913          	addi	s2,a0,8
    8000490c:	854a                	mv	a0,s2
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	460080e7          	jalr	1120(ra) # 80000d6e <acquire>
  while (lk->locked) {
    80004916:	409c                	lw	a5,0(s1)
    80004918:	cb89                	beqz	a5,8000492a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000491a:	85ca                	mv	a1,s2
    8000491c:	8526                	mv	a0,s1
    8000491e:	ffffe097          	auipc	ra,0xffffe
    80004922:	ca8080e7          	jalr	-856(ra) # 800025c6 <sleep>
  while (lk->locked) {
    80004926:	409c                	lw	a5,0(s1)
    80004928:	fbed                	bnez	a5,8000491a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000492a:	4785                	li	a5,1
    8000492c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000492e:	ffffd097          	auipc	ra,0xffffd
    80004932:	488080e7          	jalr	1160(ra) # 80001db6 <myproc>
    80004936:	413c                	lw	a5,64(a0)
    80004938:	d89c                	sw	a5,48(s1)
  release(&lk->lk);
    8000493a:	854a                	mv	a0,s2
    8000493c:	ffffc097          	auipc	ra,0xffffc
    80004940:	502080e7          	jalr	1282(ra) # 80000e3e <release>
}
    80004944:	60e2                	ld	ra,24(sp)
    80004946:	6442                	ld	s0,16(sp)
    80004948:	64a2                	ld	s1,8(sp)
    8000494a:	6902                	ld	s2,0(sp)
    8000494c:	6105                	addi	sp,sp,32
    8000494e:	8082                	ret

0000000080004950 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004950:	1101                	addi	sp,sp,-32
    80004952:	ec06                	sd	ra,24(sp)
    80004954:	e822                	sd	s0,16(sp)
    80004956:	e426                	sd	s1,8(sp)
    80004958:	e04a                	sd	s2,0(sp)
    8000495a:	1000                	addi	s0,sp,32
    8000495c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000495e:	00850913          	addi	s2,a0,8
    80004962:	854a                	mv	a0,s2
    80004964:	ffffc097          	auipc	ra,0xffffc
    80004968:	40a080e7          	jalr	1034(ra) # 80000d6e <acquire>
  lk->locked = 0;
    8000496c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004970:	0204a823          	sw	zero,48(s1)
  wakeup(lk);
    80004974:	8526                	mv	a0,s1
    80004976:	ffffe097          	auipc	ra,0xffffe
    8000497a:	dd6080e7          	jalr	-554(ra) # 8000274c <wakeup>
  release(&lk->lk);
    8000497e:	854a                	mv	a0,s2
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	4be080e7          	jalr	1214(ra) # 80000e3e <release>
}
    80004988:	60e2                	ld	ra,24(sp)
    8000498a:	6442                	ld	s0,16(sp)
    8000498c:	64a2                	ld	s1,8(sp)
    8000498e:	6902                	ld	s2,0(sp)
    80004990:	6105                	addi	sp,sp,32
    80004992:	8082                	ret

0000000080004994 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004994:	7179                	addi	sp,sp,-48
    80004996:	f406                	sd	ra,40(sp)
    80004998:	f022                	sd	s0,32(sp)
    8000499a:	ec26                	sd	s1,24(sp)
    8000499c:	e84a                	sd	s2,16(sp)
    8000499e:	e44e                	sd	s3,8(sp)
    800049a0:	1800                	addi	s0,sp,48
    800049a2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049a4:	00850913          	addi	s2,a0,8
    800049a8:	854a                	mv	a0,s2
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	3c4080e7          	jalr	964(ra) # 80000d6e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800049b2:	409c                	lw	a5,0(s1)
    800049b4:	ef99                	bnez	a5,800049d2 <holdingsleep+0x3e>
    800049b6:	4481                	li	s1,0
  release(&lk->lk);
    800049b8:	854a                	mv	a0,s2
    800049ba:	ffffc097          	auipc	ra,0xffffc
    800049be:	484080e7          	jalr	1156(ra) # 80000e3e <release>
  return r;
}
    800049c2:	8526                	mv	a0,s1
    800049c4:	70a2                	ld	ra,40(sp)
    800049c6:	7402                	ld	s0,32(sp)
    800049c8:	64e2                	ld	s1,24(sp)
    800049ca:	6942                	ld	s2,16(sp)
    800049cc:	69a2                	ld	s3,8(sp)
    800049ce:	6145                	addi	sp,sp,48
    800049d0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049d2:	0304a983          	lw	s3,48(s1)
    800049d6:	ffffd097          	auipc	ra,0xffffd
    800049da:	3e0080e7          	jalr	992(ra) # 80001db6 <myproc>
    800049de:	4124                	lw	s1,64(a0)
    800049e0:	413484b3          	sub	s1,s1,s3
    800049e4:	0014b493          	seqz	s1,s1
    800049e8:	bfc1                	j	800049b8 <holdingsleep+0x24>

00000000800049ea <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049ea:	1141                	addi	sp,sp,-16
    800049ec:	e406                	sd	ra,8(sp)
    800049ee:	e022                	sd	s0,0(sp)
    800049f0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049f2:	00004597          	auipc	a1,0x4
    800049f6:	d1e58593          	addi	a1,a1,-738 # 80008710 <syscalls+0x250>
    800049fa:	00021517          	auipc	a0,0x21
    800049fe:	44650513          	addi	a0,a0,1094 # 80025e40 <ftable>
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	4e8080e7          	jalr	1256(ra) # 80000eea <initlock>
}
    80004a0a:	60a2                	ld	ra,8(sp)
    80004a0c:	6402                	ld	s0,0(sp)
    80004a0e:	0141                	addi	sp,sp,16
    80004a10:	8082                	ret

0000000080004a12 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a12:	1101                	addi	sp,sp,-32
    80004a14:	ec06                	sd	ra,24(sp)
    80004a16:	e822                	sd	s0,16(sp)
    80004a18:	e426                	sd	s1,8(sp)
    80004a1a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a1c:	00021517          	auipc	a0,0x21
    80004a20:	42450513          	addi	a0,a0,1060 # 80025e40 <ftable>
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	34a080e7          	jalr	842(ra) # 80000d6e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a2c:	00021497          	auipc	s1,0x21
    80004a30:	43448493          	addi	s1,s1,1076 # 80025e60 <ftable+0x20>
    80004a34:	00022717          	auipc	a4,0x22
    80004a38:	3cc70713          	addi	a4,a4,972 # 80026e00 <ftable+0xfc0>
    if(f->ref == 0){
    80004a3c:	40dc                	lw	a5,4(s1)
    80004a3e:	cf99                	beqz	a5,80004a5c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a40:	02848493          	addi	s1,s1,40
    80004a44:	fee49ce3          	bne	s1,a4,80004a3c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a48:	00021517          	auipc	a0,0x21
    80004a4c:	3f850513          	addi	a0,a0,1016 # 80025e40 <ftable>
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	3ee080e7          	jalr	1006(ra) # 80000e3e <release>
  return 0;
    80004a58:	4481                	li	s1,0
    80004a5a:	a819                	j	80004a70 <filealloc+0x5e>
      f->ref = 1;
    80004a5c:	4785                	li	a5,1
    80004a5e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a60:	00021517          	auipc	a0,0x21
    80004a64:	3e050513          	addi	a0,a0,992 # 80025e40 <ftable>
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	3d6080e7          	jalr	982(ra) # 80000e3e <release>
}
    80004a70:	8526                	mv	a0,s1
    80004a72:	60e2                	ld	ra,24(sp)
    80004a74:	6442                	ld	s0,16(sp)
    80004a76:	64a2                	ld	s1,8(sp)
    80004a78:	6105                	addi	sp,sp,32
    80004a7a:	8082                	ret

0000000080004a7c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a7c:	1101                	addi	sp,sp,-32
    80004a7e:	ec06                	sd	ra,24(sp)
    80004a80:	e822                	sd	s0,16(sp)
    80004a82:	e426                	sd	s1,8(sp)
    80004a84:	1000                	addi	s0,sp,32
    80004a86:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a88:	00021517          	auipc	a0,0x21
    80004a8c:	3b850513          	addi	a0,a0,952 # 80025e40 <ftable>
    80004a90:	ffffc097          	auipc	ra,0xffffc
    80004a94:	2de080e7          	jalr	734(ra) # 80000d6e <acquire>
  if(f->ref < 1)
    80004a98:	40dc                	lw	a5,4(s1)
    80004a9a:	02f05263          	blez	a5,80004abe <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a9e:	2785                	addiw	a5,a5,1
    80004aa0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004aa2:	00021517          	auipc	a0,0x21
    80004aa6:	39e50513          	addi	a0,a0,926 # 80025e40 <ftable>
    80004aaa:	ffffc097          	auipc	ra,0xffffc
    80004aae:	394080e7          	jalr	916(ra) # 80000e3e <release>
  return f;
}
    80004ab2:	8526                	mv	a0,s1
    80004ab4:	60e2                	ld	ra,24(sp)
    80004ab6:	6442                	ld	s0,16(sp)
    80004ab8:	64a2                	ld	s1,8(sp)
    80004aba:	6105                	addi	sp,sp,32
    80004abc:	8082                	ret
    panic("filedup");
    80004abe:	00004517          	auipc	a0,0x4
    80004ac2:	c5a50513          	addi	a0,a0,-934 # 80008718 <syscalls+0x258>
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	a8a080e7          	jalr	-1398(ra) # 80000550 <panic>

0000000080004ace <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ace:	7139                	addi	sp,sp,-64
    80004ad0:	fc06                	sd	ra,56(sp)
    80004ad2:	f822                	sd	s0,48(sp)
    80004ad4:	f426                	sd	s1,40(sp)
    80004ad6:	f04a                	sd	s2,32(sp)
    80004ad8:	ec4e                	sd	s3,24(sp)
    80004ada:	e852                	sd	s4,16(sp)
    80004adc:	e456                	sd	s5,8(sp)
    80004ade:	0080                	addi	s0,sp,64
    80004ae0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ae2:	00021517          	auipc	a0,0x21
    80004ae6:	35e50513          	addi	a0,a0,862 # 80025e40 <ftable>
    80004aea:	ffffc097          	auipc	ra,0xffffc
    80004aee:	284080e7          	jalr	644(ra) # 80000d6e <acquire>
  if(f->ref < 1)
    80004af2:	40dc                	lw	a5,4(s1)
    80004af4:	06f05163          	blez	a5,80004b56 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004af8:	37fd                	addiw	a5,a5,-1
    80004afa:	0007871b          	sext.w	a4,a5
    80004afe:	c0dc                	sw	a5,4(s1)
    80004b00:	06e04363          	bgtz	a4,80004b66 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b04:	0004a903          	lw	s2,0(s1)
    80004b08:	0094ca83          	lbu	s5,9(s1)
    80004b0c:	0104ba03          	ld	s4,16(s1)
    80004b10:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b14:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b18:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b1c:	00021517          	auipc	a0,0x21
    80004b20:	32450513          	addi	a0,a0,804 # 80025e40 <ftable>
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	31a080e7          	jalr	794(ra) # 80000e3e <release>

  if(ff.type == FD_PIPE){
    80004b2c:	4785                	li	a5,1
    80004b2e:	04f90d63          	beq	s2,a5,80004b88 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b32:	3979                	addiw	s2,s2,-2
    80004b34:	4785                	li	a5,1
    80004b36:	0527e063          	bltu	a5,s2,80004b76 <fileclose+0xa8>
    begin_op();
    80004b3a:	00000097          	auipc	ra,0x0
    80004b3e:	ac0080e7          	jalr	-1344(ra) # 800045fa <begin_op>
    iput(ff.ip);
    80004b42:	854e                	mv	a0,s3
    80004b44:	fffff097          	auipc	ra,0xfffff
    80004b48:	2a0080e7          	jalr	672(ra) # 80003de4 <iput>
    end_op();
    80004b4c:	00000097          	auipc	ra,0x0
    80004b50:	b2e080e7          	jalr	-1234(ra) # 8000467a <end_op>
    80004b54:	a00d                	j	80004b76 <fileclose+0xa8>
    panic("fileclose");
    80004b56:	00004517          	auipc	a0,0x4
    80004b5a:	bca50513          	addi	a0,a0,-1078 # 80008720 <syscalls+0x260>
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	9f2080e7          	jalr	-1550(ra) # 80000550 <panic>
    release(&ftable.lock);
    80004b66:	00021517          	auipc	a0,0x21
    80004b6a:	2da50513          	addi	a0,a0,730 # 80025e40 <ftable>
    80004b6e:	ffffc097          	auipc	ra,0xffffc
    80004b72:	2d0080e7          	jalr	720(ra) # 80000e3e <release>
  }
}
    80004b76:	70e2                	ld	ra,56(sp)
    80004b78:	7442                	ld	s0,48(sp)
    80004b7a:	74a2                	ld	s1,40(sp)
    80004b7c:	7902                	ld	s2,32(sp)
    80004b7e:	69e2                	ld	s3,24(sp)
    80004b80:	6a42                	ld	s4,16(sp)
    80004b82:	6aa2                	ld	s5,8(sp)
    80004b84:	6121                	addi	sp,sp,64
    80004b86:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b88:	85d6                	mv	a1,s5
    80004b8a:	8552                	mv	a0,s4
    80004b8c:	00000097          	auipc	ra,0x0
    80004b90:	372080e7          	jalr	882(ra) # 80004efe <pipeclose>
    80004b94:	b7cd                	j	80004b76 <fileclose+0xa8>

0000000080004b96 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b96:	715d                	addi	sp,sp,-80
    80004b98:	e486                	sd	ra,72(sp)
    80004b9a:	e0a2                	sd	s0,64(sp)
    80004b9c:	fc26                	sd	s1,56(sp)
    80004b9e:	f84a                	sd	s2,48(sp)
    80004ba0:	f44e                	sd	s3,40(sp)
    80004ba2:	0880                	addi	s0,sp,80
    80004ba4:	84aa                	mv	s1,a0
    80004ba6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ba8:	ffffd097          	auipc	ra,0xffffd
    80004bac:	20e080e7          	jalr	526(ra) # 80001db6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004bb0:	409c                	lw	a5,0(s1)
    80004bb2:	37f9                	addiw	a5,a5,-2
    80004bb4:	4705                	li	a4,1
    80004bb6:	04f76763          	bltu	a4,a5,80004c04 <filestat+0x6e>
    80004bba:	892a                	mv	s2,a0
    ilock(f->ip);
    80004bbc:	6c88                	ld	a0,24(s1)
    80004bbe:	fffff097          	auipc	ra,0xfffff
    80004bc2:	06c080e7          	jalr	108(ra) # 80003c2a <ilock>
    stati(f->ip, &st);
    80004bc6:	fb840593          	addi	a1,s0,-72
    80004bca:	6c88                	ld	a0,24(s1)
    80004bcc:	fffff097          	auipc	ra,0xfffff
    80004bd0:	2e8080e7          	jalr	744(ra) # 80003eb4 <stati>
    iunlock(f->ip);
    80004bd4:	6c88                	ld	a0,24(s1)
    80004bd6:	fffff097          	auipc	ra,0xfffff
    80004bda:	116080e7          	jalr	278(ra) # 80003cec <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004bde:	46e1                	li	a3,24
    80004be0:	fb840613          	addi	a2,s0,-72
    80004be4:	85ce                	mv	a1,s3
    80004be6:	05893503          	ld	a0,88(s2)
    80004bea:	ffffd097          	auipc	ra,0xffffd
    80004bee:	ec0080e7          	jalr	-320(ra) # 80001aaa <copyout>
    80004bf2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004bf6:	60a6                	ld	ra,72(sp)
    80004bf8:	6406                	ld	s0,64(sp)
    80004bfa:	74e2                	ld	s1,56(sp)
    80004bfc:	7942                	ld	s2,48(sp)
    80004bfe:	79a2                	ld	s3,40(sp)
    80004c00:	6161                	addi	sp,sp,80
    80004c02:	8082                	ret
  return -1;
    80004c04:	557d                	li	a0,-1
    80004c06:	bfc5                	j	80004bf6 <filestat+0x60>

0000000080004c08 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c08:	7179                	addi	sp,sp,-48
    80004c0a:	f406                	sd	ra,40(sp)
    80004c0c:	f022                	sd	s0,32(sp)
    80004c0e:	ec26                	sd	s1,24(sp)
    80004c10:	e84a                	sd	s2,16(sp)
    80004c12:	e44e                	sd	s3,8(sp)
    80004c14:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c16:	00854783          	lbu	a5,8(a0)
    80004c1a:	c3d5                	beqz	a5,80004cbe <fileread+0xb6>
    80004c1c:	84aa                	mv	s1,a0
    80004c1e:	89ae                	mv	s3,a1
    80004c20:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c22:	411c                	lw	a5,0(a0)
    80004c24:	4705                	li	a4,1
    80004c26:	04e78963          	beq	a5,a4,80004c78 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c2a:	470d                	li	a4,3
    80004c2c:	04e78d63          	beq	a5,a4,80004c86 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c30:	4709                	li	a4,2
    80004c32:	06e79e63          	bne	a5,a4,80004cae <fileread+0xa6>
    ilock(f->ip);
    80004c36:	6d08                	ld	a0,24(a0)
    80004c38:	fffff097          	auipc	ra,0xfffff
    80004c3c:	ff2080e7          	jalr	-14(ra) # 80003c2a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c40:	874a                	mv	a4,s2
    80004c42:	5094                	lw	a3,32(s1)
    80004c44:	864e                	mv	a2,s3
    80004c46:	4585                	li	a1,1
    80004c48:	6c88                	ld	a0,24(s1)
    80004c4a:	fffff097          	auipc	ra,0xfffff
    80004c4e:	294080e7          	jalr	660(ra) # 80003ede <readi>
    80004c52:	892a                	mv	s2,a0
    80004c54:	00a05563          	blez	a0,80004c5e <fileread+0x56>
      f->off += r;
    80004c58:	509c                	lw	a5,32(s1)
    80004c5a:	9fa9                	addw	a5,a5,a0
    80004c5c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c5e:	6c88                	ld	a0,24(s1)
    80004c60:	fffff097          	auipc	ra,0xfffff
    80004c64:	08c080e7          	jalr	140(ra) # 80003cec <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c68:	854a                	mv	a0,s2
    80004c6a:	70a2                	ld	ra,40(sp)
    80004c6c:	7402                	ld	s0,32(sp)
    80004c6e:	64e2                	ld	s1,24(sp)
    80004c70:	6942                	ld	s2,16(sp)
    80004c72:	69a2                	ld	s3,8(sp)
    80004c74:	6145                	addi	sp,sp,48
    80004c76:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c78:	6908                	ld	a0,16(a0)
    80004c7a:	00000097          	auipc	ra,0x0
    80004c7e:	422080e7          	jalr	1058(ra) # 8000509c <piperead>
    80004c82:	892a                	mv	s2,a0
    80004c84:	b7d5                	j	80004c68 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c86:	02451783          	lh	a5,36(a0)
    80004c8a:	03079693          	slli	a3,a5,0x30
    80004c8e:	92c1                	srli	a3,a3,0x30
    80004c90:	4725                	li	a4,9
    80004c92:	02d76863          	bltu	a4,a3,80004cc2 <fileread+0xba>
    80004c96:	0792                	slli	a5,a5,0x4
    80004c98:	00021717          	auipc	a4,0x21
    80004c9c:	10870713          	addi	a4,a4,264 # 80025da0 <devsw>
    80004ca0:	97ba                	add	a5,a5,a4
    80004ca2:	639c                	ld	a5,0(a5)
    80004ca4:	c38d                	beqz	a5,80004cc6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ca6:	4505                	li	a0,1
    80004ca8:	9782                	jalr	a5
    80004caa:	892a                	mv	s2,a0
    80004cac:	bf75                	j	80004c68 <fileread+0x60>
    panic("fileread");
    80004cae:	00004517          	auipc	a0,0x4
    80004cb2:	a8250513          	addi	a0,a0,-1406 # 80008730 <syscalls+0x270>
    80004cb6:	ffffc097          	auipc	ra,0xffffc
    80004cba:	89a080e7          	jalr	-1894(ra) # 80000550 <panic>
    return -1;
    80004cbe:	597d                	li	s2,-1
    80004cc0:	b765                	j	80004c68 <fileread+0x60>
      return -1;
    80004cc2:	597d                	li	s2,-1
    80004cc4:	b755                	j	80004c68 <fileread+0x60>
    80004cc6:	597d                	li	s2,-1
    80004cc8:	b745                	j	80004c68 <fileread+0x60>

0000000080004cca <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004cca:	00954783          	lbu	a5,9(a0)
    80004cce:	14078563          	beqz	a5,80004e18 <filewrite+0x14e>
{
    80004cd2:	715d                	addi	sp,sp,-80
    80004cd4:	e486                	sd	ra,72(sp)
    80004cd6:	e0a2                	sd	s0,64(sp)
    80004cd8:	fc26                	sd	s1,56(sp)
    80004cda:	f84a                	sd	s2,48(sp)
    80004cdc:	f44e                	sd	s3,40(sp)
    80004cde:	f052                	sd	s4,32(sp)
    80004ce0:	ec56                	sd	s5,24(sp)
    80004ce2:	e85a                	sd	s6,16(sp)
    80004ce4:	e45e                	sd	s7,8(sp)
    80004ce6:	e062                	sd	s8,0(sp)
    80004ce8:	0880                	addi	s0,sp,80
    80004cea:	892a                	mv	s2,a0
    80004cec:	8aae                	mv	s5,a1
    80004cee:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cf0:	411c                	lw	a5,0(a0)
    80004cf2:	4705                	li	a4,1
    80004cf4:	02e78263          	beq	a5,a4,80004d18 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cf8:	470d                	li	a4,3
    80004cfa:	02e78563          	beq	a5,a4,80004d24 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cfe:	4709                	li	a4,2
    80004d00:	10e79463          	bne	a5,a4,80004e08 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d04:	0ec05e63          	blez	a2,80004e00 <filewrite+0x136>
    int i = 0;
    80004d08:	4981                	li	s3,0
    80004d0a:	6b05                	lui	s6,0x1
    80004d0c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d10:	6b85                	lui	s7,0x1
    80004d12:	c00b8b9b          	addiw	s7,s7,-1024
    80004d16:	a851                	j	80004daa <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004d18:	6908                	ld	a0,16(a0)
    80004d1a:	00000097          	auipc	ra,0x0
    80004d1e:	25e080e7          	jalr	606(ra) # 80004f78 <pipewrite>
    80004d22:	a85d                	j	80004dd8 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d24:	02451783          	lh	a5,36(a0)
    80004d28:	03079693          	slli	a3,a5,0x30
    80004d2c:	92c1                	srli	a3,a3,0x30
    80004d2e:	4725                	li	a4,9
    80004d30:	0ed76663          	bltu	a4,a3,80004e1c <filewrite+0x152>
    80004d34:	0792                	slli	a5,a5,0x4
    80004d36:	00021717          	auipc	a4,0x21
    80004d3a:	06a70713          	addi	a4,a4,106 # 80025da0 <devsw>
    80004d3e:	97ba                	add	a5,a5,a4
    80004d40:	679c                	ld	a5,8(a5)
    80004d42:	cff9                	beqz	a5,80004e20 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004d44:	4505                	li	a0,1
    80004d46:	9782                	jalr	a5
    80004d48:	a841                	j	80004dd8 <filewrite+0x10e>
    80004d4a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d4e:	00000097          	auipc	ra,0x0
    80004d52:	8ac080e7          	jalr	-1876(ra) # 800045fa <begin_op>
      ilock(f->ip);
    80004d56:	01893503          	ld	a0,24(s2)
    80004d5a:	fffff097          	auipc	ra,0xfffff
    80004d5e:	ed0080e7          	jalr	-304(ra) # 80003c2a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d62:	8762                	mv	a4,s8
    80004d64:	02092683          	lw	a3,32(s2)
    80004d68:	01598633          	add	a2,s3,s5
    80004d6c:	4585                	li	a1,1
    80004d6e:	01893503          	ld	a0,24(s2)
    80004d72:	fffff097          	auipc	ra,0xfffff
    80004d76:	264080e7          	jalr	612(ra) # 80003fd6 <writei>
    80004d7a:	84aa                	mv	s1,a0
    80004d7c:	02a05f63          	blez	a0,80004dba <filewrite+0xf0>
        f->off += r;
    80004d80:	02092783          	lw	a5,32(s2)
    80004d84:	9fa9                	addw	a5,a5,a0
    80004d86:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d8a:	01893503          	ld	a0,24(s2)
    80004d8e:	fffff097          	auipc	ra,0xfffff
    80004d92:	f5e080e7          	jalr	-162(ra) # 80003cec <iunlock>
      end_op();
    80004d96:	00000097          	auipc	ra,0x0
    80004d9a:	8e4080e7          	jalr	-1820(ra) # 8000467a <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004d9e:	049c1963          	bne	s8,s1,80004df0 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004da2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004da6:	0349d663          	bge	s3,s4,80004dd2 <filewrite+0x108>
      int n1 = n - i;
    80004daa:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004dae:	84be                	mv	s1,a5
    80004db0:	2781                	sext.w	a5,a5
    80004db2:	f8fb5ce3          	bge	s6,a5,80004d4a <filewrite+0x80>
    80004db6:	84de                	mv	s1,s7
    80004db8:	bf49                	j	80004d4a <filewrite+0x80>
      iunlock(f->ip);
    80004dba:	01893503          	ld	a0,24(s2)
    80004dbe:	fffff097          	auipc	ra,0xfffff
    80004dc2:	f2e080e7          	jalr	-210(ra) # 80003cec <iunlock>
      end_op();
    80004dc6:	00000097          	auipc	ra,0x0
    80004dca:	8b4080e7          	jalr	-1868(ra) # 8000467a <end_op>
      if(r < 0)
    80004dce:	fc04d8e3          	bgez	s1,80004d9e <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004dd2:	8552                	mv	a0,s4
    80004dd4:	033a1863          	bne	s4,s3,80004e04 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004dd8:	60a6                	ld	ra,72(sp)
    80004dda:	6406                	ld	s0,64(sp)
    80004ddc:	74e2                	ld	s1,56(sp)
    80004dde:	7942                	ld	s2,48(sp)
    80004de0:	79a2                	ld	s3,40(sp)
    80004de2:	7a02                	ld	s4,32(sp)
    80004de4:	6ae2                	ld	s5,24(sp)
    80004de6:	6b42                	ld	s6,16(sp)
    80004de8:	6ba2                	ld	s7,8(sp)
    80004dea:	6c02                	ld	s8,0(sp)
    80004dec:	6161                	addi	sp,sp,80
    80004dee:	8082                	ret
        panic("short filewrite");
    80004df0:	00004517          	auipc	a0,0x4
    80004df4:	95050513          	addi	a0,a0,-1712 # 80008740 <syscalls+0x280>
    80004df8:	ffffb097          	auipc	ra,0xffffb
    80004dfc:	758080e7          	jalr	1880(ra) # 80000550 <panic>
    int i = 0;
    80004e00:	4981                	li	s3,0
    80004e02:	bfc1                	j	80004dd2 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004e04:	557d                	li	a0,-1
    80004e06:	bfc9                	j	80004dd8 <filewrite+0x10e>
    panic("filewrite");
    80004e08:	00004517          	auipc	a0,0x4
    80004e0c:	94850513          	addi	a0,a0,-1720 # 80008750 <syscalls+0x290>
    80004e10:	ffffb097          	auipc	ra,0xffffb
    80004e14:	740080e7          	jalr	1856(ra) # 80000550 <panic>
    return -1;
    80004e18:	557d                	li	a0,-1
}
    80004e1a:	8082                	ret
      return -1;
    80004e1c:	557d                	li	a0,-1
    80004e1e:	bf6d                	j	80004dd8 <filewrite+0x10e>
    80004e20:	557d                	li	a0,-1
    80004e22:	bf5d                	j	80004dd8 <filewrite+0x10e>

0000000080004e24 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e24:	7179                	addi	sp,sp,-48
    80004e26:	f406                	sd	ra,40(sp)
    80004e28:	f022                	sd	s0,32(sp)
    80004e2a:	ec26                	sd	s1,24(sp)
    80004e2c:	e84a                	sd	s2,16(sp)
    80004e2e:	e44e                	sd	s3,8(sp)
    80004e30:	e052                	sd	s4,0(sp)
    80004e32:	1800                	addi	s0,sp,48
    80004e34:	84aa                	mv	s1,a0
    80004e36:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e38:	0005b023          	sd	zero,0(a1)
    80004e3c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e40:	00000097          	auipc	ra,0x0
    80004e44:	bd2080e7          	jalr	-1070(ra) # 80004a12 <filealloc>
    80004e48:	e088                	sd	a0,0(s1)
    80004e4a:	c551                	beqz	a0,80004ed6 <pipealloc+0xb2>
    80004e4c:	00000097          	auipc	ra,0x0
    80004e50:	bc6080e7          	jalr	-1082(ra) # 80004a12 <filealloc>
    80004e54:	00aa3023          	sd	a0,0(s4)
    80004e58:	c92d                	beqz	a0,80004eca <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e5a:	ffffc097          	auipc	ra,0xffffc
    80004e5e:	d38080e7          	jalr	-712(ra) # 80000b92 <kalloc>
    80004e62:	892a                	mv	s2,a0
    80004e64:	c125                	beqz	a0,80004ec4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e66:	4985                	li	s3,1
    80004e68:	23352423          	sw	s3,552(a0)
  pi->writeopen = 1;
    80004e6c:	23352623          	sw	s3,556(a0)
  pi->nwrite = 0;
    80004e70:	22052223          	sw	zero,548(a0)
  pi->nread = 0;
    80004e74:	22052023          	sw	zero,544(a0)
  initlock(&pi->lock, "pipe");
    80004e78:	00004597          	auipc	a1,0x4
    80004e7c:	8e858593          	addi	a1,a1,-1816 # 80008760 <syscalls+0x2a0>
    80004e80:	ffffc097          	auipc	ra,0xffffc
    80004e84:	06a080e7          	jalr	106(ra) # 80000eea <initlock>
  (*f0)->type = FD_PIPE;
    80004e88:	609c                	ld	a5,0(s1)
    80004e8a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e8e:	609c                	ld	a5,0(s1)
    80004e90:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e94:	609c                	ld	a5,0(s1)
    80004e96:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e9a:	609c                	ld	a5,0(s1)
    80004e9c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ea0:	000a3783          	ld	a5,0(s4)
    80004ea4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ea8:	000a3783          	ld	a5,0(s4)
    80004eac:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004eb0:	000a3783          	ld	a5,0(s4)
    80004eb4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004eb8:	000a3783          	ld	a5,0(s4)
    80004ebc:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ec0:	4501                	li	a0,0
    80004ec2:	a025                	j	80004eea <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ec4:	6088                	ld	a0,0(s1)
    80004ec6:	e501                	bnez	a0,80004ece <pipealloc+0xaa>
    80004ec8:	a039                	j	80004ed6 <pipealloc+0xb2>
    80004eca:	6088                	ld	a0,0(s1)
    80004ecc:	c51d                	beqz	a0,80004efa <pipealloc+0xd6>
    fileclose(*f0);
    80004ece:	00000097          	auipc	ra,0x0
    80004ed2:	c00080e7          	jalr	-1024(ra) # 80004ace <fileclose>
  if(*f1)
    80004ed6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004eda:	557d                	li	a0,-1
  if(*f1)
    80004edc:	c799                	beqz	a5,80004eea <pipealloc+0xc6>
    fileclose(*f1);
    80004ede:	853e                	mv	a0,a5
    80004ee0:	00000097          	auipc	ra,0x0
    80004ee4:	bee080e7          	jalr	-1042(ra) # 80004ace <fileclose>
  return -1;
    80004ee8:	557d                	li	a0,-1
}
    80004eea:	70a2                	ld	ra,40(sp)
    80004eec:	7402                	ld	s0,32(sp)
    80004eee:	64e2                	ld	s1,24(sp)
    80004ef0:	6942                	ld	s2,16(sp)
    80004ef2:	69a2                	ld	s3,8(sp)
    80004ef4:	6a02                	ld	s4,0(sp)
    80004ef6:	6145                	addi	sp,sp,48
    80004ef8:	8082                	ret
  return -1;
    80004efa:	557d                	li	a0,-1
    80004efc:	b7fd                	j	80004eea <pipealloc+0xc6>

0000000080004efe <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004efe:	1101                	addi	sp,sp,-32
    80004f00:	ec06                	sd	ra,24(sp)
    80004f02:	e822                	sd	s0,16(sp)
    80004f04:	e426                	sd	s1,8(sp)
    80004f06:	e04a                	sd	s2,0(sp)
    80004f08:	1000                	addi	s0,sp,32
    80004f0a:	84aa                	mv	s1,a0
    80004f0c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f0e:	ffffc097          	auipc	ra,0xffffc
    80004f12:	e60080e7          	jalr	-416(ra) # 80000d6e <acquire>
  if(writable){
    80004f16:	04090263          	beqz	s2,80004f5a <pipeclose+0x5c>
    pi->writeopen = 0;
    80004f1a:	2204a623          	sw	zero,556(s1)
    wakeup(&pi->nread);
    80004f1e:	22048513          	addi	a0,s1,544
    80004f22:	ffffe097          	auipc	ra,0xffffe
    80004f26:	82a080e7          	jalr	-2006(ra) # 8000274c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f2a:	2284b783          	ld	a5,552(s1)
    80004f2e:	ef9d                	bnez	a5,80004f6c <pipeclose+0x6e>
    release(&pi->lock);
    80004f30:	8526                	mv	a0,s1
    80004f32:	ffffc097          	auipc	ra,0xffffc
    80004f36:	f0c080e7          	jalr	-244(ra) # 80000e3e <release>
#ifdef LAB_LOCK
    freelock(&pi->lock);
    80004f3a:	8526                	mv	a0,s1
    80004f3c:	ffffc097          	auipc	ra,0xffffc
    80004f40:	f4a080e7          	jalr	-182(ra) # 80000e86 <freelock>
#endif    
    kfree((char*)pi);
    80004f44:	8526                	mv	a0,s1
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	ae6080e7          	jalr	-1306(ra) # 80000a2c <kfree>
  } else
    release(&pi->lock);
}
    80004f4e:	60e2                	ld	ra,24(sp)
    80004f50:	6442                	ld	s0,16(sp)
    80004f52:	64a2                	ld	s1,8(sp)
    80004f54:	6902                	ld	s2,0(sp)
    80004f56:	6105                	addi	sp,sp,32
    80004f58:	8082                	ret
    pi->readopen = 0;
    80004f5a:	2204a423          	sw	zero,552(s1)
    wakeup(&pi->nwrite);
    80004f5e:	22448513          	addi	a0,s1,548
    80004f62:	ffffd097          	auipc	ra,0xffffd
    80004f66:	7ea080e7          	jalr	2026(ra) # 8000274c <wakeup>
    80004f6a:	b7c1                	j	80004f2a <pipeclose+0x2c>
    release(&pi->lock);
    80004f6c:	8526                	mv	a0,s1
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	ed0080e7          	jalr	-304(ra) # 80000e3e <release>
}
    80004f76:	bfe1                	j	80004f4e <pipeclose+0x50>

0000000080004f78 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f78:	7119                	addi	sp,sp,-128
    80004f7a:	fc86                	sd	ra,120(sp)
    80004f7c:	f8a2                	sd	s0,112(sp)
    80004f7e:	f4a6                	sd	s1,104(sp)
    80004f80:	f0ca                	sd	s2,96(sp)
    80004f82:	ecce                	sd	s3,88(sp)
    80004f84:	e8d2                	sd	s4,80(sp)
    80004f86:	e4d6                	sd	s5,72(sp)
    80004f88:	e0da                	sd	s6,64(sp)
    80004f8a:	fc5e                	sd	s7,56(sp)
    80004f8c:	f862                	sd	s8,48(sp)
    80004f8e:	f466                	sd	s9,40(sp)
    80004f90:	f06a                	sd	s10,32(sp)
    80004f92:	ec6e                	sd	s11,24(sp)
    80004f94:	0100                	addi	s0,sp,128
    80004f96:	84aa                	mv	s1,a0
    80004f98:	8cae                	mv	s9,a1
    80004f9a:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004f9c:	ffffd097          	auipc	ra,0xffffd
    80004fa0:	e1a080e7          	jalr	-486(ra) # 80001db6 <myproc>
    80004fa4:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004fa6:	8526                	mv	a0,s1
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	dc6080e7          	jalr	-570(ra) # 80000d6e <acquire>
  for(i = 0; i < n; i++){
    80004fb0:	0d605963          	blez	s6,80005082 <pipewrite+0x10a>
    80004fb4:	89a6                	mv	s3,s1
    80004fb6:	3b7d                	addiw	s6,s6,-1
    80004fb8:	1b02                	slli	s6,s6,0x20
    80004fba:	020b5b13          	srli	s6,s6,0x20
    80004fbe:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004fc0:	22048a93          	addi	s5,s1,544
      sleep(&pi->nwrite, &pi->lock);
    80004fc4:	22448a13          	addi	s4,s1,548
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fc8:	5dfd                	li	s11,-1
    80004fca:	000b8d1b          	sext.w	s10,s7
    80004fce:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004fd0:	2204a783          	lw	a5,544(s1)
    80004fd4:	2244a703          	lw	a4,548(s1)
    80004fd8:	2007879b          	addiw	a5,a5,512
    80004fdc:	02f71b63          	bne	a4,a5,80005012 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004fe0:	2284a783          	lw	a5,552(s1)
    80004fe4:	cbad                	beqz	a5,80005056 <pipewrite+0xde>
    80004fe6:	03892783          	lw	a5,56(s2)
    80004fea:	e7b5                	bnez	a5,80005056 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004fec:	8556                	mv	a0,s5
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	75e080e7          	jalr	1886(ra) # 8000274c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ff6:	85ce                	mv	a1,s3
    80004ff8:	8552                	mv	a0,s4
    80004ffa:	ffffd097          	auipc	ra,0xffffd
    80004ffe:	5cc080e7          	jalr	1484(ra) # 800025c6 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80005002:	2204a783          	lw	a5,544(s1)
    80005006:	2244a703          	lw	a4,548(s1)
    8000500a:	2007879b          	addiw	a5,a5,512
    8000500e:	fcf709e3          	beq	a4,a5,80004fe0 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005012:	4685                	li	a3,1
    80005014:	019b8633          	add	a2,s7,s9
    80005018:	f8f40593          	addi	a1,s0,-113
    8000501c:	05893503          	ld	a0,88(s2)
    80005020:	ffffd097          	auipc	ra,0xffffd
    80005024:	b16080e7          	jalr	-1258(ra) # 80001b36 <copyin>
    80005028:	05b50e63          	beq	a0,s11,80005084 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000502c:	2244a783          	lw	a5,548(s1)
    80005030:	0017871b          	addiw	a4,a5,1
    80005034:	22e4a223          	sw	a4,548(s1)
    80005038:	1ff7f793          	andi	a5,a5,511
    8000503c:	97a6                	add	a5,a5,s1
    8000503e:	f8f44703          	lbu	a4,-113(s0)
    80005042:	02e78023          	sb	a4,32(a5)
  for(i = 0; i < n; i++){
    80005046:	001d0c1b          	addiw	s8,s10,1
    8000504a:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    8000504e:	036b8b63          	beq	s7,s6,80005084 <pipewrite+0x10c>
    80005052:	8bbe                	mv	s7,a5
    80005054:	bf9d                	j	80004fca <pipewrite+0x52>
        release(&pi->lock);
    80005056:	8526                	mv	a0,s1
    80005058:	ffffc097          	auipc	ra,0xffffc
    8000505c:	de6080e7          	jalr	-538(ra) # 80000e3e <release>
        return -1;
    80005060:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80005062:	8562                	mv	a0,s8
    80005064:	70e6                	ld	ra,120(sp)
    80005066:	7446                	ld	s0,112(sp)
    80005068:	74a6                	ld	s1,104(sp)
    8000506a:	7906                	ld	s2,96(sp)
    8000506c:	69e6                	ld	s3,88(sp)
    8000506e:	6a46                	ld	s4,80(sp)
    80005070:	6aa6                	ld	s5,72(sp)
    80005072:	6b06                	ld	s6,64(sp)
    80005074:	7be2                	ld	s7,56(sp)
    80005076:	7c42                	ld	s8,48(sp)
    80005078:	7ca2                	ld	s9,40(sp)
    8000507a:	7d02                	ld	s10,32(sp)
    8000507c:	6de2                	ld	s11,24(sp)
    8000507e:	6109                	addi	sp,sp,128
    80005080:	8082                	ret
  for(i = 0; i < n; i++){
    80005082:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80005084:	22048513          	addi	a0,s1,544
    80005088:	ffffd097          	auipc	ra,0xffffd
    8000508c:	6c4080e7          	jalr	1732(ra) # 8000274c <wakeup>
  release(&pi->lock);
    80005090:	8526                	mv	a0,s1
    80005092:	ffffc097          	auipc	ra,0xffffc
    80005096:	dac080e7          	jalr	-596(ra) # 80000e3e <release>
  return i;
    8000509a:	b7e1                	j	80005062 <pipewrite+0xea>

000000008000509c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000509c:	715d                	addi	sp,sp,-80
    8000509e:	e486                	sd	ra,72(sp)
    800050a0:	e0a2                	sd	s0,64(sp)
    800050a2:	fc26                	sd	s1,56(sp)
    800050a4:	f84a                	sd	s2,48(sp)
    800050a6:	f44e                	sd	s3,40(sp)
    800050a8:	f052                	sd	s4,32(sp)
    800050aa:	ec56                	sd	s5,24(sp)
    800050ac:	e85a                	sd	s6,16(sp)
    800050ae:	0880                	addi	s0,sp,80
    800050b0:	84aa                	mv	s1,a0
    800050b2:	892e                	mv	s2,a1
    800050b4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800050b6:	ffffd097          	auipc	ra,0xffffd
    800050ba:	d00080e7          	jalr	-768(ra) # 80001db6 <myproc>
    800050be:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800050c0:	8b26                	mv	s6,s1
    800050c2:	8526                	mv	a0,s1
    800050c4:	ffffc097          	auipc	ra,0xffffc
    800050c8:	caa080e7          	jalr	-854(ra) # 80000d6e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050cc:	2204a703          	lw	a4,544(s1)
    800050d0:	2244a783          	lw	a5,548(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050d4:	22048993          	addi	s3,s1,544
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050d8:	02f71463          	bne	a4,a5,80005100 <piperead+0x64>
    800050dc:	22c4a783          	lw	a5,556(s1)
    800050e0:	c385                	beqz	a5,80005100 <piperead+0x64>
    if(pr->killed){
    800050e2:	038a2783          	lw	a5,56(s4)
    800050e6:	ebc1                	bnez	a5,80005176 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050e8:	85da                	mv	a1,s6
    800050ea:	854e                	mv	a0,s3
    800050ec:	ffffd097          	auipc	ra,0xffffd
    800050f0:	4da080e7          	jalr	1242(ra) # 800025c6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050f4:	2204a703          	lw	a4,544(s1)
    800050f8:	2244a783          	lw	a5,548(s1)
    800050fc:	fef700e3          	beq	a4,a5,800050dc <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005100:	09505263          	blez	s5,80005184 <piperead+0xe8>
    80005104:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005106:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005108:	2204a783          	lw	a5,544(s1)
    8000510c:	2244a703          	lw	a4,548(s1)
    80005110:	02f70d63          	beq	a4,a5,8000514a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005114:	0017871b          	addiw	a4,a5,1
    80005118:	22e4a023          	sw	a4,544(s1)
    8000511c:	1ff7f793          	andi	a5,a5,511
    80005120:	97a6                	add	a5,a5,s1
    80005122:	0207c783          	lbu	a5,32(a5)
    80005126:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000512a:	4685                	li	a3,1
    8000512c:	fbf40613          	addi	a2,s0,-65
    80005130:	85ca                	mv	a1,s2
    80005132:	058a3503          	ld	a0,88(s4)
    80005136:	ffffd097          	auipc	ra,0xffffd
    8000513a:	974080e7          	jalr	-1676(ra) # 80001aaa <copyout>
    8000513e:	01650663          	beq	a0,s6,8000514a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005142:	2985                	addiw	s3,s3,1
    80005144:	0905                	addi	s2,s2,1
    80005146:	fd3a91e3          	bne	s5,s3,80005108 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000514a:	22448513          	addi	a0,s1,548
    8000514e:	ffffd097          	auipc	ra,0xffffd
    80005152:	5fe080e7          	jalr	1534(ra) # 8000274c <wakeup>
  release(&pi->lock);
    80005156:	8526                	mv	a0,s1
    80005158:	ffffc097          	auipc	ra,0xffffc
    8000515c:	ce6080e7          	jalr	-794(ra) # 80000e3e <release>
  return i;
}
    80005160:	854e                	mv	a0,s3
    80005162:	60a6                	ld	ra,72(sp)
    80005164:	6406                	ld	s0,64(sp)
    80005166:	74e2                	ld	s1,56(sp)
    80005168:	7942                	ld	s2,48(sp)
    8000516a:	79a2                	ld	s3,40(sp)
    8000516c:	7a02                	ld	s4,32(sp)
    8000516e:	6ae2                	ld	s5,24(sp)
    80005170:	6b42                	ld	s6,16(sp)
    80005172:	6161                	addi	sp,sp,80
    80005174:	8082                	ret
      release(&pi->lock);
    80005176:	8526                	mv	a0,s1
    80005178:	ffffc097          	auipc	ra,0xffffc
    8000517c:	cc6080e7          	jalr	-826(ra) # 80000e3e <release>
      return -1;
    80005180:	59fd                	li	s3,-1
    80005182:	bff9                	j	80005160 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005184:	4981                	li	s3,0
    80005186:	b7d1                	j	8000514a <piperead+0xae>

0000000080005188 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005188:	df010113          	addi	sp,sp,-528
    8000518c:	20113423          	sd	ra,520(sp)
    80005190:	20813023          	sd	s0,512(sp)
    80005194:	ffa6                	sd	s1,504(sp)
    80005196:	fbca                	sd	s2,496(sp)
    80005198:	f7ce                	sd	s3,488(sp)
    8000519a:	f3d2                	sd	s4,480(sp)
    8000519c:	efd6                	sd	s5,472(sp)
    8000519e:	ebda                	sd	s6,464(sp)
    800051a0:	e7de                	sd	s7,456(sp)
    800051a2:	e3e2                	sd	s8,448(sp)
    800051a4:	ff66                	sd	s9,440(sp)
    800051a6:	fb6a                	sd	s10,432(sp)
    800051a8:	f76e                	sd	s11,424(sp)
    800051aa:	0c00                	addi	s0,sp,528
    800051ac:	84aa                	mv	s1,a0
    800051ae:	dea43c23          	sd	a0,-520(s0)
    800051b2:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800051b6:	ffffd097          	auipc	ra,0xffffd
    800051ba:	c00080e7          	jalr	-1024(ra) # 80001db6 <myproc>
    800051be:	892a                	mv	s2,a0

  begin_op();
    800051c0:	fffff097          	auipc	ra,0xfffff
    800051c4:	43a080e7          	jalr	1082(ra) # 800045fa <begin_op>

  if((ip = namei(path)) == 0){
    800051c8:	8526                	mv	a0,s1
    800051ca:	fffff097          	auipc	ra,0xfffff
    800051ce:	214080e7          	jalr	532(ra) # 800043de <namei>
    800051d2:	c92d                	beqz	a0,80005244 <exec+0xbc>
    800051d4:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051d6:	fffff097          	auipc	ra,0xfffff
    800051da:	a54080e7          	jalr	-1452(ra) # 80003c2a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800051de:	04000713          	li	a4,64
    800051e2:	4681                	li	a3,0
    800051e4:	e4840613          	addi	a2,s0,-440
    800051e8:	4581                	li	a1,0
    800051ea:	8526                	mv	a0,s1
    800051ec:	fffff097          	auipc	ra,0xfffff
    800051f0:	cf2080e7          	jalr	-782(ra) # 80003ede <readi>
    800051f4:	04000793          	li	a5,64
    800051f8:	00f51a63          	bne	a0,a5,8000520c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800051fc:	e4842703          	lw	a4,-440(s0)
    80005200:	464c47b7          	lui	a5,0x464c4
    80005204:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005208:	04f70463          	beq	a4,a5,80005250 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000520c:	8526                	mv	a0,s1
    8000520e:	fffff097          	auipc	ra,0xfffff
    80005212:	c7e080e7          	jalr	-898(ra) # 80003e8c <iunlockput>
    end_op();
    80005216:	fffff097          	auipc	ra,0xfffff
    8000521a:	464080e7          	jalr	1124(ra) # 8000467a <end_op>
  }
  return -1;
    8000521e:	557d                	li	a0,-1
}
    80005220:	20813083          	ld	ra,520(sp)
    80005224:	20013403          	ld	s0,512(sp)
    80005228:	74fe                	ld	s1,504(sp)
    8000522a:	795e                	ld	s2,496(sp)
    8000522c:	79be                	ld	s3,488(sp)
    8000522e:	7a1e                	ld	s4,480(sp)
    80005230:	6afe                	ld	s5,472(sp)
    80005232:	6b5e                	ld	s6,464(sp)
    80005234:	6bbe                	ld	s7,456(sp)
    80005236:	6c1e                	ld	s8,448(sp)
    80005238:	7cfa                	ld	s9,440(sp)
    8000523a:	7d5a                	ld	s10,432(sp)
    8000523c:	7dba                	ld	s11,424(sp)
    8000523e:	21010113          	addi	sp,sp,528
    80005242:	8082                	ret
    end_op();
    80005244:	fffff097          	auipc	ra,0xfffff
    80005248:	436080e7          	jalr	1078(ra) # 8000467a <end_op>
    return -1;
    8000524c:	557d                	li	a0,-1
    8000524e:	bfc9                	j	80005220 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005250:	854a                	mv	a0,s2
    80005252:	ffffd097          	auipc	ra,0xffffd
    80005256:	c28080e7          	jalr	-984(ra) # 80001e7a <proc_pagetable>
    8000525a:	8baa                	mv	s7,a0
    8000525c:	d945                	beqz	a0,8000520c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000525e:	e6842983          	lw	s3,-408(s0)
    80005262:	e8045783          	lhu	a5,-384(s0)
    80005266:	c7ad                	beqz	a5,800052d0 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005268:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000526a:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    8000526c:	6c85                	lui	s9,0x1
    8000526e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005272:	def43823          	sd	a5,-528(s0)
    80005276:	a42d                	j	800054a0 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005278:	00003517          	auipc	a0,0x3
    8000527c:	4f050513          	addi	a0,a0,1264 # 80008768 <syscalls+0x2a8>
    80005280:	ffffb097          	auipc	ra,0xffffb
    80005284:	2d0080e7          	jalr	720(ra) # 80000550 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005288:	8756                	mv	a4,s5
    8000528a:	012d86bb          	addw	a3,s11,s2
    8000528e:	4581                	li	a1,0
    80005290:	8526                	mv	a0,s1
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	c4c080e7          	jalr	-948(ra) # 80003ede <readi>
    8000529a:	2501                	sext.w	a0,a0
    8000529c:	1aaa9963          	bne	s5,a0,8000544e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800052a0:	6785                	lui	a5,0x1
    800052a2:	0127893b          	addw	s2,a5,s2
    800052a6:	77fd                	lui	a5,0xfffff
    800052a8:	01478a3b          	addw	s4,a5,s4
    800052ac:	1f897163          	bgeu	s2,s8,8000548e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800052b0:	02091593          	slli	a1,s2,0x20
    800052b4:	9181                	srli	a1,a1,0x20
    800052b6:	95ea                	add	a1,a1,s10
    800052b8:	855e                	mv	a0,s7
    800052ba:	ffffc097          	auipc	ra,0xffffc
    800052be:	22e080e7          	jalr	558(ra) # 800014e8 <walkaddr>
    800052c2:	862a                	mv	a2,a0
    if(pa == 0)
    800052c4:	d955                	beqz	a0,80005278 <exec+0xf0>
      n = PGSIZE;
    800052c6:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800052c8:	fd9a70e3          	bgeu	s4,s9,80005288 <exec+0x100>
      n = sz - i;
    800052cc:	8ad2                	mv	s5,s4
    800052ce:	bf6d                	j	80005288 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800052d0:	4901                	li	s2,0
  iunlockput(ip);
    800052d2:	8526                	mv	a0,s1
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	bb8080e7          	jalr	-1096(ra) # 80003e8c <iunlockput>
  end_op();
    800052dc:	fffff097          	auipc	ra,0xfffff
    800052e0:	39e080e7          	jalr	926(ra) # 8000467a <end_op>
  p = myproc();
    800052e4:	ffffd097          	auipc	ra,0xffffd
    800052e8:	ad2080e7          	jalr	-1326(ra) # 80001db6 <myproc>
    800052ec:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800052ee:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    800052f2:	6785                	lui	a5,0x1
    800052f4:	17fd                	addi	a5,a5,-1
    800052f6:	993e                	add	s2,s2,a5
    800052f8:	757d                	lui	a0,0xfffff
    800052fa:	00a977b3          	and	a5,s2,a0
    800052fe:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005302:	6609                	lui	a2,0x2
    80005304:	963e                	add	a2,a2,a5
    80005306:	85be                	mv	a1,a5
    80005308:	855e                	mv	a0,s7
    8000530a:	ffffc097          	auipc	ra,0xffffc
    8000530e:	550080e7          	jalr	1360(ra) # 8000185a <uvmalloc>
    80005312:	8b2a                	mv	s6,a0
  ip = 0;
    80005314:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005316:	12050c63          	beqz	a0,8000544e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000531a:	75f9                	lui	a1,0xffffe
    8000531c:	95aa                	add	a1,a1,a0
    8000531e:	855e                	mv	a0,s7
    80005320:	ffffc097          	auipc	ra,0xffffc
    80005324:	758080e7          	jalr	1880(ra) # 80001a78 <uvmclear>
  stackbase = sp - PGSIZE;
    80005328:	7c7d                	lui	s8,0xfffff
    8000532a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000532c:	e0043783          	ld	a5,-512(s0)
    80005330:	6388                	ld	a0,0(a5)
    80005332:	c535                	beqz	a0,8000539e <exec+0x216>
    80005334:	e8840993          	addi	s3,s0,-376
    80005338:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000533c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000533e:	ffffc097          	auipc	ra,0xffffc
    80005342:	f98080e7          	jalr	-104(ra) # 800012d6 <strlen>
    80005346:	2505                	addiw	a0,a0,1
    80005348:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000534c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005350:	13896363          	bltu	s2,s8,80005476 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005354:	e0043d83          	ld	s11,-512(s0)
    80005358:	000dba03          	ld	s4,0(s11)
    8000535c:	8552                	mv	a0,s4
    8000535e:	ffffc097          	auipc	ra,0xffffc
    80005362:	f78080e7          	jalr	-136(ra) # 800012d6 <strlen>
    80005366:	0015069b          	addiw	a3,a0,1
    8000536a:	8652                	mv	a2,s4
    8000536c:	85ca                	mv	a1,s2
    8000536e:	855e                	mv	a0,s7
    80005370:	ffffc097          	auipc	ra,0xffffc
    80005374:	73a080e7          	jalr	1850(ra) # 80001aaa <copyout>
    80005378:	10054363          	bltz	a0,8000547e <exec+0x2f6>
    ustack[argc] = sp;
    8000537c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005380:	0485                	addi	s1,s1,1
    80005382:	008d8793          	addi	a5,s11,8
    80005386:	e0f43023          	sd	a5,-512(s0)
    8000538a:	008db503          	ld	a0,8(s11)
    8000538e:	c911                	beqz	a0,800053a2 <exec+0x21a>
    if(argc >= MAXARG)
    80005390:	09a1                	addi	s3,s3,8
    80005392:	fb3c96e3          	bne	s9,s3,8000533e <exec+0x1b6>
  sz = sz1;
    80005396:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000539a:	4481                	li	s1,0
    8000539c:	a84d                	j	8000544e <exec+0x2c6>
  sp = sz;
    8000539e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800053a0:	4481                	li	s1,0
  ustack[argc] = 0;
    800053a2:	00349793          	slli	a5,s1,0x3
    800053a6:	f9040713          	addi	a4,s0,-112
    800053aa:	97ba                	add	a5,a5,a4
    800053ac:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    800053b0:	00148693          	addi	a3,s1,1
    800053b4:	068e                	slli	a3,a3,0x3
    800053b6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053ba:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800053be:	01897663          	bgeu	s2,s8,800053ca <exec+0x242>
  sz = sz1;
    800053c2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053c6:	4481                	li	s1,0
    800053c8:	a059                	j	8000544e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053ca:	e8840613          	addi	a2,s0,-376
    800053ce:	85ca                	mv	a1,s2
    800053d0:	855e                	mv	a0,s7
    800053d2:	ffffc097          	auipc	ra,0xffffc
    800053d6:	6d8080e7          	jalr	1752(ra) # 80001aaa <copyout>
    800053da:	0a054663          	bltz	a0,80005486 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800053de:	060ab783          	ld	a5,96(s5)
    800053e2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053e6:	df843783          	ld	a5,-520(s0)
    800053ea:	0007c703          	lbu	a4,0(a5)
    800053ee:	cf11                	beqz	a4,8000540a <exec+0x282>
    800053f0:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053f2:	02f00693          	li	a3,47
    800053f6:	a029                	j	80005400 <exec+0x278>
  for(last=s=path; *s; s++)
    800053f8:	0785                	addi	a5,a5,1
    800053fa:	fff7c703          	lbu	a4,-1(a5)
    800053fe:	c711                	beqz	a4,8000540a <exec+0x282>
    if(*s == '/')
    80005400:	fed71ce3          	bne	a4,a3,800053f8 <exec+0x270>
      last = s+1;
    80005404:	def43c23          	sd	a5,-520(s0)
    80005408:	bfc5                	j	800053f8 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000540a:	4641                	li	a2,16
    8000540c:	df843583          	ld	a1,-520(s0)
    80005410:	160a8513          	addi	a0,s5,352
    80005414:	ffffc097          	auipc	ra,0xffffc
    80005418:	e90080e7          	jalr	-368(ra) # 800012a4 <safestrcpy>
  oldpagetable = p->pagetable;
    8000541c:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    80005420:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    80005424:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005428:	060ab783          	ld	a5,96(s5)
    8000542c:	e6043703          	ld	a4,-416(s0)
    80005430:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005432:	060ab783          	ld	a5,96(s5)
    80005436:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000543a:	85ea                	mv	a1,s10
    8000543c:	ffffd097          	auipc	ra,0xffffd
    80005440:	ada080e7          	jalr	-1318(ra) # 80001f16 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005444:	0004851b          	sext.w	a0,s1
    80005448:	bbe1                	j	80005220 <exec+0x98>
    8000544a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000544e:	e0843583          	ld	a1,-504(s0)
    80005452:	855e                	mv	a0,s7
    80005454:	ffffd097          	auipc	ra,0xffffd
    80005458:	ac2080e7          	jalr	-1342(ra) # 80001f16 <proc_freepagetable>
  if(ip){
    8000545c:	da0498e3          	bnez	s1,8000520c <exec+0x84>
  return -1;
    80005460:	557d                	li	a0,-1
    80005462:	bb7d                	j	80005220 <exec+0x98>
    80005464:	e1243423          	sd	s2,-504(s0)
    80005468:	b7dd                	j	8000544e <exec+0x2c6>
    8000546a:	e1243423          	sd	s2,-504(s0)
    8000546e:	b7c5                	j	8000544e <exec+0x2c6>
    80005470:	e1243423          	sd	s2,-504(s0)
    80005474:	bfe9                	j	8000544e <exec+0x2c6>
  sz = sz1;
    80005476:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000547a:	4481                	li	s1,0
    8000547c:	bfc9                	j	8000544e <exec+0x2c6>
  sz = sz1;
    8000547e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005482:	4481                	li	s1,0
    80005484:	b7e9                	j	8000544e <exec+0x2c6>
  sz = sz1;
    80005486:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000548a:	4481                	li	s1,0
    8000548c:	b7c9                	j	8000544e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000548e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005492:	2b05                	addiw	s6,s6,1
    80005494:	0389899b          	addiw	s3,s3,56
    80005498:	e8045783          	lhu	a5,-384(s0)
    8000549c:	e2fb5be3          	bge	s6,a5,800052d2 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800054a0:	2981                	sext.w	s3,s3
    800054a2:	03800713          	li	a4,56
    800054a6:	86ce                	mv	a3,s3
    800054a8:	e1040613          	addi	a2,s0,-496
    800054ac:	4581                	li	a1,0
    800054ae:	8526                	mv	a0,s1
    800054b0:	fffff097          	auipc	ra,0xfffff
    800054b4:	a2e080e7          	jalr	-1490(ra) # 80003ede <readi>
    800054b8:	03800793          	li	a5,56
    800054bc:	f8f517e3          	bne	a0,a5,8000544a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800054c0:	e1042783          	lw	a5,-496(s0)
    800054c4:	4705                	li	a4,1
    800054c6:	fce796e3          	bne	a5,a4,80005492 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800054ca:	e3843603          	ld	a2,-456(s0)
    800054ce:	e3043783          	ld	a5,-464(s0)
    800054d2:	f8f669e3          	bltu	a2,a5,80005464 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054d6:	e2043783          	ld	a5,-480(s0)
    800054da:	963e                	add	a2,a2,a5
    800054dc:	f8f667e3          	bltu	a2,a5,8000546a <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800054e0:	85ca                	mv	a1,s2
    800054e2:	855e                	mv	a0,s7
    800054e4:	ffffc097          	auipc	ra,0xffffc
    800054e8:	376080e7          	jalr	886(ra) # 8000185a <uvmalloc>
    800054ec:	e0a43423          	sd	a0,-504(s0)
    800054f0:	d141                	beqz	a0,80005470 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    800054f2:	e2043d03          	ld	s10,-480(s0)
    800054f6:	df043783          	ld	a5,-528(s0)
    800054fa:	00fd77b3          	and	a5,s10,a5
    800054fe:	fba1                	bnez	a5,8000544e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005500:	e1842d83          	lw	s11,-488(s0)
    80005504:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005508:	f80c03e3          	beqz	s8,8000548e <exec+0x306>
    8000550c:	8a62                	mv	s4,s8
    8000550e:	4901                	li	s2,0
    80005510:	b345                	j	800052b0 <exec+0x128>

0000000080005512 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005512:	7179                	addi	sp,sp,-48
    80005514:	f406                	sd	ra,40(sp)
    80005516:	f022                	sd	s0,32(sp)
    80005518:	ec26                	sd	s1,24(sp)
    8000551a:	e84a                	sd	s2,16(sp)
    8000551c:	1800                	addi	s0,sp,48
    8000551e:	892e                	mv	s2,a1
    80005520:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005522:	fdc40593          	addi	a1,s0,-36
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	94e080e7          	jalr	-1714(ra) # 80002e74 <argint>
    8000552e:	04054063          	bltz	a0,8000556e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005532:	fdc42703          	lw	a4,-36(s0)
    80005536:	47bd                	li	a5,15
    80005538:	02e7ed63          	bltu	a5,a4,80005572 <argfd+0x60>
    8000553c:	ffffd097          	auipc	ra,0xffffd
    80005540:	87a080e7          	jalr	-1926(ra) # 80001db6 <myproc>
    80005544:	fdc42703          	lw	a4,-36(s0)
    80005548:	01a70793          	addi	a5,a4,26
    8000554c:	078e                	slli	a5,a5,0x3
    8000554e:	953e                	add	a0,a0,a5
    80005550:	651c                	ld	a5,8(a0)
    80005552:	c395                	beqz	a5,80005576 <argfd+0x64>
    return -1;
  if(pfd)
    80005554:	00090463          	beqz	s2,8000555c <argfd+0x4a>
    *pfd = fd;
    80005558:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000555c:	4501                	li	a0,0
  if(pf)
    8000555e:	c091                	beqz	s1,80005562 <argfd+0x50>
    *pf = f;
    80005560:	e09c                	sd	a5,0(s1)
}
    80005562:	70a2                	ld	ra,40(sp)
    80005564:	7402                	ld	s0,32(sp)
    80005566:	64e2                	ld	s1,24(sp)
    80005568:	6942                	ld	s2,16(sp)
    8000556a:	6145                	addi	sp,sp,48
    8000556c:	8082                	ret
    return -1;
    8000556e:	557d                	li	a0,-1
    80005570:	bfcd                	j	80005562 <argfd+0x50>
    return -1;
    80005572:	557d                	li	a0,-1
    80005574:	b7fd                	j	80005562 <argfd+0x50>
    80005576:	557d                	li	a0,-1
    80005578:	b7ed                	j	80005562 <argfd+0x50>

000000008000557a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000557a:	1101                	addi	sp,sp,-32
    8000557c:	ec06                	sd	ra,24(sp)
    8000557e:	e822                	sd	s0,16(sp)
    80005580:	e426                	sd	s1,8(sp)
    80005582:	1000                	addi	s0,sp,32
    80005584:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005586:	ffffd097          	auipc	ra,0xffffd
    8000558a:	830080e7          	jalr	-2000(ra) # 80001db6 <myproc>
    8000558e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005590:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffd40b0>
    80005594:	4501                	li	a0,0
    80005596:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005598:	6398                	ld	a4,0(a5)
    8000559a:	cb19                	beqz	a4,800055b0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000559c:	2505                	addiw	a0,a0,1
    8000559e:	07a1                	addi	a5,a5,8
    800055a0:	fed51ce3          	bne	a0,a3,80005598 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800055a4:	557d                	li	a0,-1
}
    800055a6:	60e2                	ld	ra,24(sp)
    800055a8:	6442                	ld	s0,16(sp)
    800055aa:	64a2                	ld	s1,8(sp)
    800055ac:	6105                	addi	sp,sp,32
    800055ae:	8082                	ret
      p->ofile[fd] = f;
    800055b0:	01a50793          	addi	a5,a0,26
    800055b4:	078e                	slli	a5,a5,0x3
    800055b6:	963e                	add	a2,a2,a5
    800055b8:	e604                	sd	s1,8(a2)
      return fd;
    800055ba:	b7f5                	j	800055a6 <fdalloc+0x2c>

00000000800055bc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055bc:	715d                	addi	sp,sp,-80
    800055be:	e486                	sd	ra,72(sp)
    800055c0:	e0a2                	sd	s0,64(sp)
    800055c2:	fc26                	sd	s1,56(sp)
    800055c4:	f84a                	sd	s2,48(sp)
    800055c6:	f44e                	sd	s3,40(sp)
    800055c8:	f052                	sd	s4,32(sp)
    800055ca:	ec56                	sd	s5,24(sp)
    800055cc:	0880                	addi	s0,sp,80
    800055ce:	89ae                	mv	s3,a1
    800055d0:	8ab2                	mv	s5,a2
    800055d2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055d4:	fb040593          	addi	a1,s0,-80
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	e24080e7          	jalr	-476(ra) # 800043fc <nameiparent>
    800055e0:	892a                	mv	s2,a0
    800055e2:	12050f63          	beqz	a0,80005720 <create+0x164>
    return 0;

  ilock(dp);
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	644080e7          	jalr	1604(ra) # 80003c2a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055ee:	4601                	li	a2,0
    800055f0:	fb040593          	addi	a1,s0,-80
    800055f4:	854a                	mv	a0,s2
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	b16080e7          	jalr	-1258(ra) # 8000410c <dirlookup>
    800055fe:	84aa                	mv	s1,a0
    80005600:	c921                	beqz	a0,80005650 <create+0x94>
    iunlockput(dp);
    80005602:	854a                	mv	a0,s2
    80005604:	fffff097          	auipc	ra,0xfffff
    80005608:	888080e7          	jalr	-1912(ra) # 80003e8c <iunlockput>
    ilock(ip);
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	61c080e7          	jalr	1564(ra) # 80003c2a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005616:	2981                	sext.w	s3,s3
    80005618:	4789                	li	a5,2
    8000561a:	02f99463          	bne	s3,a5,80005642 <create+0x86>
    8000561e:	04c4d783          	lhu	a5,76(s1)
    80005622:	37f9                	addiw	a5,a5,-2
    80005624:	17c2                	slli	a5,a5,0x30
    80005626:	93c1                	srli	a5,a5,0x30
    80005628:	4705                	li	a4,1
    8000562a:	00f76c63          	bltu	a4,a5,80005642 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000562e:	8526                	mv	a0,s1
    80005630:	60a6                	ld	ra,72(sp)
    80005632:	6406                	ld	s0,64(sp)
    80005634:	74e2                	ld	s1,56(sp)
    80005636:	7942                	ld	s2,48(sp)
    80005638:	79a2                	ld	s3,40(sp)
    8000563a:	7a02                	ld	s4,32(sp)
    8000563c:	6ae2                	ld	s5,24(sp)
    8000563e:	6161                	addi	sp,sp,80
    80005640:	8082                	ret
    iunlockput(ip);
    80005642:	8526                	mv	a0,s1
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	848080e7          	jalr	-1976(ra) # 80003e8c <iunlockput>
    return 0;
    8000564c:	4481                	li	s1,0
    8000564e:	b7c5                	j	8000562e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005650:	85ce                	mv	a1,s3
    80005652:	00092503          	lw	a0,0(s2)
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	43c080e7          	jalr	1084(ra) # 80003a92 <ialloc>
    8000565e:	84aa                	mv	s1,a0
    80005660:	c529                	beqz	a0,800056aa <create+0xee>
  ilock(ip);
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	5c8080e7          	jalr	1480(ra) # 80003c2a <ilock>
  ip->major = major;
    8000566a:	05549723          	sh	s5,78(s1)
  ip->minor = minor;
    8000566e:	05449823          	sh	s4,80(s1)
  ip->nlink = 1;
    80005672:	4785                	li	a5,1
    80005674:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005678:	8526                	mv	a0,s1
    8000567a:	ffffe097          	auipc	ra,0xffffe
    8000567e:	4e6080e7          	jalr	1254(ra) # 80003b60 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005682:	2981                	sext.w	s3,s3
    80005684:	4785                	li	a5,1
    80005686:	02f98a63          	beq	s3,a5,800056ba <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000568a:	40d0                	lw	a2,4(s1)
    8000568c:	fb040593          	addi	a1,s0,-80
    80005690:	854a                	mv	a0,s2
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	c8a080e7          	jalr	-886(ra) # 8000431c <dirlink>
    8000569a:	06054b63          	bltz	a0,80005710 <create+0x154>
  iunlockput(dp);
    8000569e:	854a                	mv	a0,s2
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	7ec080e7          	jalr	2028(ra) # 80003e8c <iunlockput>
  return ip;
    800056a8:	b759                	j	8000562e <create+0x72>
    panic("create: ialloc");
    800056aa:	00003517          	auipc	a0,0x3
    800056ae:	0de50513          	addi	a0,a0,222 # 80008788 <syscalls+0x2c8>
    800056b2:	ffffb097          	auipc	ra,0xffffb
    800056b6:	e9e080e7          	jalr	-354(ra) # 80000550 <panic>
    dp->nlink++;  // for ".."
    800056ba:	05295783          	lhu	a5,82(s2)
    800056be:	2785                	addiw	a5,a5,1
    800056c0:	04f91923          	sh	a5,82(s2)
    iupdate(dp);
    800056c4:	854a                	mv	a0,s2
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	49a080e7          	jalr	1178(ra) # 80003b60 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056ce:	40d0                	lw	a2,4(s1)
    800056d0:	00003597          	auipc	a1,0x3
    800056d4:	0c858593          	addi	a1,a1,200 # 80008798 <syscalls+0x2d8>
    800056d8:	8526                	mv	a0,s1
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	c42080e7          	jalr	-958(ra) # 8000431c <dirlink>
    800056e2:	00054f63          	bltz	a0,80005700 <create+0x144>
    800056e6:	00492603          	lw	a2,4(s2)
    800056ea:	00003597          	auipc	a1,0x3
    800056ee:	0b658593          	addi	a1,a1,182 # 800087a0 <syscalls+0x2e0>
    800056f2:	8526                	mv	a0,s1
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	c28080e7          	jalr	-984(ra) # 8000431c <dirlink>
    800056fc:	f80557e3          	bgez	a0,8000568a <create+0xce>
      panic("create dots");
    80005700:	00003517          	auipc	a0,0x3
    80005704:	0a850513          	addi	a0,a0,168 # 800087a8 <syscalls+0x2e8>
    80005708:	ffffb097          	auipc	ra,0xffffb
    8000570c:	e48080e7          	jalr	-440(ra) # 80000550 <panic>
    panic("create: dirlink");
    80005710:	00003517          	auipc	a0,0x3
    80005714:	0a850513          	addi	a0,a0,168 # 800087b8 <syscalls+0x2f8>
    80005718:	ffffb097          	auipc	ra,0xffffb
    8000571c:	e38080e7          	jalr	-456(ra) # 80000550 <panic>
    return 0;
    80005720:	84aa                	mv	s1,a0
    80005722:	b731                	j	8000562e <create+0x72>

0000000080005724 <sys_dup>:
{
    80005724:	7179                	addi	sp,sp,-48
    80005726:	f406                	sd	ra,40(sp)
    80005728:	f022                	sd	s0,32(sp)
    8000572a:	ec26                	sd	s1,24(sp)
    8000572c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000572e:	fd840613          	addi	a2,s0,-40
    80005732:	4581                	li	a1,0
    80005734:	4501                	li	a0,0
    80005736:	00000097          	auipc	ra,0x0
    8000573a:	ddc080e7          	jalr	-548(ra) # 80005512 <argfd>
    return -1;
    8000573e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005740:	02054363          	bltz	a0,80005766 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005744:	fd843503          	ld	a0,-40(s0)
    80005748:	00000097          	auipc	ra,0x0
    8000574c:	e32080e7          	jalr	-462(ra) # 8000557a <fdalloc>
    80005750:	84aa                	mv	s1,a0
    return -1;
    80005752:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005754:	00054963          	bltz	a0,80005766 <sys_dup+0x42>
  filedup(f);
    80005758:	fd843503          	ld	a0,-40(s0)
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	320080e7          	jalr	800(ra) # 80004a7c <filedup>
  return fd;
    80005764:	87a6                	mv	a5,s1
}
    80005766:	853e                	mv	a0,a5
    80005768:	70a2                	ld	ra,40(sp)
    8000576a:	7402                	ld	s0,32(sp)
    8000576c:	64e2                	ld	s1,24(sp)
    8000576e:	6145                	addi	sp,sp,48
    80005770:	8082                	ret

0000000080005772 <sys_read>:
{
    80005772:	7179                	addi	sp,sp,-48
    80005774:	f406                	sd	ra,40(sp)
    80005776:	f022                	sd	s0,32(sp)
    80005778:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000577a:	fe840613          	addi	a2,s0,-24
    8000577e:	4581                	li	a1,0
    80005780:	4501                	li	a0,0
    80005782:	00000097          	auipc	ra,0x0
    80005786:	d90080e7          	jalr	-624(ra) # 80005512 <argfd>
    return -1;
    8000578a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000578c:	04054163          	bltz	a0,800057ce <sys_read+0x5c>
    80005790:	fe440593          	addi	a1,s0,-28
    80005794:	4509                	li	a0,2
    80005796:	ffffd097          	auipc	ra,0xffffd
    8000579a:	6de080e7          	jalr	1758(ra) # 80002e74 <argint>
    return -1;
    8000579e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057a0:	02054763          	bltz	a0,800057ce <sys_read+0x5c>
    800057a4:	fd840593          	addi	a1,s0,-40
    800057a8:	4505                	li	a0,1
    800057aa:	ffffd097          	auipc	ra,0xffffd
    800057ae:	6ec080e7          	jalr	1772(ra) # 80002e96 <argaddr>
    return -1;
    800057b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057b4:	00054d63          	bltz	a0,800057ce <sys_read+0x5c>
  return fileread(f, p, n);
    800057b8:	fe442603          	lw	a2,-28(s0)
    800057bc:	fd843583          	ld	a1,-40(s0)
    800057c0:	fe843503          	ld	a0,-24(s0)
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	444080e7          	jalr	1092(ra) # 80004c08 <fileread>
    800057cc:	87aa                	mv	a5,a0
}
    800057ce:	853e                	mv	a0,a5
    800057d0:	70a2                	ld	ra,40(sp)
    800057d2:	7402                	ld	s0,32(sp)
    800057d4:	6145                	addi	sp,sp,48
    800057d6:	8082                	ret

00000000800057d8 <sys_write>:
{
    800057d8:	7179                	addi	sp,sp,-48
    800057da:	f406                	sd	ra,40(sp)
    800057dc:	f022                	sd	s0,32(sp)
    800057de:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057e0:	fe840613          	addi	a2,s0,-24
    800057e4:	4581                	li	a1,0
    800057e6:	4501                	li	a0,0
    800057e8:	00000097          	auipc	ra,0x0
    800057ec:	d2a080e7          	jalr	-726(ra) # 80005512 <argfd>
    return -1;
    800057f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057f2:	04054163          	bltz	a0,80005834 <sys_write+0x5c>
    800057f6:	fe440593          	addi	a1,s0,-28
    800057fa:	4509                	li	a0,2
    800057fc:	ffffd097          	auipc	ra,0xffffd
    80005800:	678080e7          	jalr	1656(ra) # 80002e74 <argint>
    return -1;
    80005804:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005806:	02054763          	bltz	a0,80005834 <sys_write+0x5c>
    8000580a:	fd840593          	addi	a1,s0,-40
    8000580e:	4505                	li	a0,1
    80005810:	ffffd097          	auipc	ra,0xffffd
    80005814:	686080e7          	jalr	1670(ra) # 80002e96 <argaddr>
    return -1;
    80005818:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000581a:	00054d63          	bltz	a0,80005834 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000581e:	fe442603          	lw	a2,-28(s0)
    80005822:	fd843583          	ld	a1,-40(s0)
    80005826:	fe843503          	ld	a0,-24(s0)
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	4a0080e7          	jalr	1184(ra) # 80004cca <filewrite>
    80005832:	87aa                	mv	a5,a0
}
    80005834:	853e                	mv	a0,a5
    80005836:	70a2                	ld	ra,40(sp)
    80005838:	7402                	ld	s0,32(sp)
    8000583a:	6145                	addi	sp,sp,48
    8000583c:	8082                	ret

000000008000583e <sys_close>:
{
    8000583e:	1101                	addi	sp,sp,-32
    80005840:	ec06                	sd	ra,24(sp)
    80005842:	e822                	sd	s0,16(sp)
    80005844:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005846:	fe040613          	addi	a2,s0,-32
    8000584a:	fec40593          	addi	a1,s0,-20
    8000584e:	4501                	li	a0,0
    80005850:	00000097          	auipc	ra,0x0
    80005854:	cc2080e7          	jalr	-830(ra) # 80005512 <argfd>
    return -1;
    80005858:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000585a:	02054463          	bltz	a0,80005882 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000585e:	ffffc097          	auipc	ra,0xffffc
    80005862:	558080e7          	jalr	1368(ra) # 80001db6 <myproc>
    80005866:	fec42783          	lw	a5,-20(s0)
    8000586a:	07e9                	addi	a5,a5,26
    8000586c:	078e                	slli	a5,a5,0x3
    8000586e:	97aa                	add	a5,a5,a0
    80005870:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005874:	fe043503          	ld	a0,-32(s0)
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	256080e7          	jalr	598(ra) # 80004ace <fileclose>
  return 0;
    80005880:	4781                	li	a5,0
}
    80005882:	853e                	mv	a0,a5
    80005884:	60e2                	ld	ra,24(sp)
    80005886:	6442                	ld	s0,16(sp)
    80005888:	6105                	addi	sp,sp,32
    8000588a:	8082                	ret

000000008000588c <sys_fstat>:
{
    8000588c:	1101                	addi	sp,sp,-32
    8000588e:	ec06                	sd	ra,24(sp)
    80005890:	e822                	sd	s0,16(sp)
    80005892:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005894:	fe840613          	addi	a2,s0,-24
    80005898:	4581                	li	a1,0
    8000589a:	4501                	li	a0,0
    8000589c:	00000097          	auipc	ra,0x0
    800058a0:	c76080e7          	jalr	-906(ra) # 80005512 <argfd>
    return -1;
    800058a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058a6:	02054563          	bltz	a0,800058d0 <sys_fstat+0x44>
    800058aa:	fe040593          	addi	a1,s0,-32
    800058ae:	4505                	li	a0,1
    800058b0:	ffffd097          	auipc	ra,0xffffd
    800058b4:	5e6080e7          	jalr	1510(ra) # 80002e96 <argaddr>
    return -1;
    800058b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058ba:	00054b63          	bltz	a0,800058d0 <sys_fstat+0x44>
  return filestat(f, st);
    800058be:	fe043583          	ld	a1,-32(s0)
    800058c2:	fe843503          	ld	a0,-24(s0)
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	2d0080e7          	jalr	720(ra) # 80004b96 <filestat>
    800058ce:	87aa                	mv	a5,a0
}
    800058d0:	853e                	mv	a0,a5
    800058d2:	60e2                	ld	ra,24(sp)
    800058d4:	6442                	ld	s0,16(sp)
    800058d6:	6105                	addi	sp,sp,32
    800058d8:	8082                	ret

00000000800058da <sys_link>:
{
    800058da:	7169                	addi	sp,sp,-304
    800058dc:	f606                	sd	ra,296(sp)
    800058de:	f222                	sd	s0,288(sp)
    800058e0:	ee26                	sd	s1,280(sp)
    800058e2:	ea4a                	sd	s2,272(sp)
    800058e4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058e6:	08000613          	li	a2,128
    800058ea:	ed040593          	addi	a1,s0,-304
    800058ee:	4501                	li	a0,0
    800058f0:	ffffd097          	auipc	ra,0xffffd
    800058f4:	5c8080e7          	jalr	1480(ra) # 80002eb8 <argstr>
    return -1;
    800058f8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058fa:	10054e63          	bltz	a0,80005a16 <sys_link+0x13c>
    800058fe:	08000613          	li	a2,128
    80005902:	f5040593          	addi	a1,s0,-176
    80005906:	4505                	li	a0,1
    80005908:	ffffd097          	auipc	ra,0xffffd
    8000590c:	5b0080e7          	jalr	1456(ra) # 80002eb8 <argstr>
    return -1;
    80005910:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005912:	10054263          	bltz	a0,80005a16 <sys_link+0x13c>
  begin_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	ce4080e7          	jalr	-796(ra) # 800045fa <begin_op>
  if((ip = namei(old)) == 0){
    8000591e:	ed040513          	addi	a0,s0,-304
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	abc080e7          	jalr	-1348(ra) # 800043de <namei>
    8000592a:	84aa                	mv	s1,a0
    8000592c:	c551                	beqz	a0,800059b8 <sys_link+0xde>
  ilock(ip);
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	2fc080e7          	jalr	764(ra) # 80003c2a <ilock>
  if(ip->type == T_DIR){
    80005936:	04c49703          	lh	a4,76(s1)
    8000593a:	4785                	li	a5,1
    8000593c:	08f70463          	beq	a4,a5,800059c4 <sys_link+0xea>
  ip->nlink++;
    80005940:	0524d783          	lhu	a5,82(s1)
    80005944:	2785                	addiw	a5,a5,1
    80005946:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    8000594a:	8526                	mv	a0,s1
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	214080e7          	jalr	532(ra) # 80003b60 <iupdate>
  iunlock(ip);
    80005954:	8526                	mv	a0,s1
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	396080e7          	jalr	918(ra) # 80003cec <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000595e:	fd040593          	addi	a1,s0,-48
    80005962:	f5040513          	addi	a0,s0,-176
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	a96080e7          	jalr	-1386(ra) # 800043fc <nameiparent>
    8000596e:	892a                	mv	s2,a0
    80005970:	c935                	beqz	a0,800059e4 <sys_link+0x10a>
  ilock(dp);
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	2b8080e7          	jalr	696(ra) # 80003c2a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000597a:	00092703          	lw	a4,0(s2)
    8000597e:	409c                	lw	a5,0(s1)
    80005980:	04f71d63          	bne	a4,a5,800059da <sys_link+0x100>
    80005984:	40d0                	lw	a2,4(s1)
    80005986:	fd040593          	addi	a1,s0,-48
    8000598a:	854a                	mv	a0,s2
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	990080e7          	jalr	-1648(ra) # 8000431c <dirlink>
    80005994:	04054363          	bltz	a0,800059da <sys_link+0x100>
  iunlockput(dp);
    80005998:	854a                	mv	a0,s2
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	4f2080e7          	jalr	1266(ra) # 80003e8c <iunlockput>
  iput(ip);
    800059a2:	8526                	mv	a0,s1
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	440080e7          	jalr	1088(ra) # 80003de4 <iput>
  end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	cce080e7          	jalr	-818(ra) # 8000467a <end_op>
  return 0;
    800059b4:	4781                	li	a5,0
    800059b6:	a085                	j	80005a16 <sys_link+0x13c>
    end_op();
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	cc2080e7          	jalr	-830(ra) # 8000467a <end_op>
    return -1;
    800059c0:	57fd                	li	a5,-1
    800059c2:	a891                	j	80005a16 <sys_link+0x13c>
    iunlockput(ip);
    800059c4:	8526                	mv	a0,s1
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	4c6080e7          	jalr	1222(ra) # 80003e8c <iunlockput>
    end_op();
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	cac080e7          	jalr	-852(ra) # 8000467a <end_op>
    return -1;
    800059d6:	57fd                	li	a5,-1
    800059d8:	a83d                	j	80005a16 <sys_link+0x13c>
    iunlockput(dp);
    800059da:	854a                	mv	a0,s2
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	4b0080e7          	jalr	1200(ra) # 80003e8c <iunlockput>
  ilock(ip);
    800059e4:	8526                	mv	a0,s1
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	244080e7          	jalr	580(ra) # 80003c2a <ilock>
  ip->nlink--;
    800059ee:	0524d783          	lhu	a5,82(s1)
    800059f2:	37fd                	addiw	a5,a5,-1
    800059f4:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    800059f8:	8526                	mv	a0,s1
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	166080e7          	jalr	358(ra) # 80003b60 <iupdate>
  iunlockput(ip);
    80005a02:	8526                	mv	a0,s1
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	488080e7          	jalr	1160(ra) # 80003e8c <iunlockput>
  end_op();
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	c6e080e7          	jalr	-914(ra) # 8000467a <end_op>
  return -1;
    80005a14:	57fd                	li	a5,-1
}
    80005a16:	853e                	mv	a0,a5
    80005a18:	70b2                	ld	ra,296(sp)
    80005a1a:	7412                	ld	s0,288(sp)
    80005a1c:	64f2                	ld	s1,280(sp)
    80005a1e:	6952                	ld	s2,272(sp)
    80005a20:	6155                	addi	sp,sp,304
    80005a22:	8082                	ret

0000000080005a24 <sys_unlink>:
{
    80005a24:	7151                	addi	sp,sp,-240
    80005a26:	f586                	sd	ra,232(sp)
    80005a28:	f1a2                	sd	s0,224(sp)
    80005a2a:	eda6                	sd	s1,216(sp)
    80005a2c:	e9ca                	sd	s2,208(sp)
    80005a2e:	e5ce                	sd	s3,200(sp)
    80005a30:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a32:	08000613          	li	a2,128
    80005a36:	f3040593          	addi	a1,s0,-208
    80005a3a:	4501                	li	a0,0
    80005a3c:	ffffd097          	auipc	ra,0xffffd
    80005a40:	47c080e7          	jalr	1148(ra) # 80002eb8 <argstr>
    80005a44:	18054163          	bltz	a0,80005bc6 <sys_unlink+0x1a2>
  begin_op();
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	bb2080e7          	jalr	-1102(ra) # 800045fa <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a50:	fb040593          	addi	a1,s0,-80
    80005a54:	f3040513          	addi	a0,s0,-208
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	9a4080e7          	jalr	-1628(ra) # 800043fc <nameiparent>
    80005a60:	84aa                	mv	s1,a0
    80005a62:	c979                	beqz	a0,80005b38 <sys_unlink+0x114>
  ilock(dp);
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	1c6080e7          	jalr	454(ra) # 80003c2a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a6c:	00003597          	auipc	a1,0x3
    80005a70:	d2c58593          	addi	a1,a1,-724 # 80008798 <syscalls+0x2d8>
    80005a74:	fb040513          	addi	a0,s0,-80
    80005a78:	ffffe097          	auipc	ra,0xffffe
    80005a7c:	67a080e7          	jalr	1658(ra) # 800040f2 <namecmp>
    80005a80:	14050a63          	beqz	a0,80005bd4 <sys_unlink+0x1b0>
    80005a84:	00003597          	auipc	a1,0x3
    80005a88:	d1c58593          	addi	a1,a1,-740 # 800087a0 <syscalls+0x2e0>
    80005a8c:	fb040513          	addi	a0,s0,-80
    80005a90:	ffffe097          	auipc	ra,0xffffe
    80005a94:	662080e7          	jalr	1634(ra) # 800040f2 <namecmp>
    80005a98:	12050e63          	beqz	a0,80005bd4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a9c:	f2c40613          	addi	a2,s0,-212
    80005aa0:	fb040593          	addi	a1,s0,-80
    80005aa4:	8526                	mv	a0,s1
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	666080e7          	jalr	1638(ra) # 8000410c <dirlookup>
    80005aae:	892a                	mv	s2,a0
    80005ab0:	12050263          	beqz	a0,80005bd4 <sys_unlink+0x1b0>
  ilock(ip);
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	176080e7          	jalr	374(ra) # 80003c2a <ilock>
  if(ip->nlink < 1)
    80005abc:	05291783          	lh	a5,82(s2)
    80005ac0:	08f05263          	blez	a5,80005b44 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ac4:	04c91703          	lh	a4,76(s2)
    80005ac8:	4785                	li	a5,1
    80005aca:	08f70563          	beq	a4,a5,80005b54 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ace:	4641                	li	a2,16
    80005ad0:	4581                	li	a1,0
    80005ad2:	fc040513          	addi	a0,s0,-64
    80005ad6:	ffffb097          	auipc	ra,0xffffb
    80005ada:	678080e7          	jalr	1656(ra) # 8000114e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ade:	4741                	li	a4,16
    80005ae0:	f2c42683          	lw	a3,-212(s0)
    80005ae4:	fc040613          	addi	a2,s0,-64
    80005ae8:	4581                	li	a1,0
    80005aea:	8526                	mv	a0,s1
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	4ea080e7          	jalr	1258(ra) # 80003fd6 <writei>
    80005af4:	47c1                	li	a5,16
    80005af6:	0af51563          	bne	a0,a5,80005ba0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005afa:	04c91703          	lh	a4,76(s2)
    80005afe:	4785                	li	a5,1
    80005b00:	0af70863          	beq	a4,a5,80005bb0 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b04:	8526                	mv	a0,s1
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	386080e7          	jalr	902(ra) # 80003e8c <iunlockput>
  ip->nlink--;
    80005b0e:	05295783          	lhu	a5,82(s2)
    80005b12:	37fd                	addiw	a5,a5,-1
    80005b14:	04f91923          	sh	a5,82(s2)
  iupdate(ip);
    80005b18:	854a                	mv	a0,s2
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	046080e7          	jalr	70(ra) # 80003b60 <iupdate>
  iunlockput(ip);
    80005b22:	854a                	mv	a0,s2
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	368080e7          	jalr	872(ra) # 80003e8c <iunlockput>
  end_op();
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	b4e080e7          	jalr	-1202(ra) # 8000467a <end_op>
  return 0;
    80005b34:	4501                	li	a0,0
    80005b36:	a84d                	j	80005be8 <sys_unlink+0x1c4>
    end_op();
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	b42080e7          	jalr	-1214(ra) # 8000467a <end_op>
    return -1;
    80005b40:	557d                	li	a0,-1
    80005b42:	a05d                	j	80005be8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b44:	00003517          	auipc	a0,0x3
    80005b48:	c8450513          	addi	a0,a0,-892 # 800087c8 <syscalls+0x308>
    80005b4c:	ffffb097          	auipc	ra,0xffffb
    80005b50:	a04080e7          	jalr	-1532(ra) # 80000550 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b54:	05492703          	lw	a4,84(s2)
    80005b58:	02000793          	li	a5,32
    80005b5c:	f6e7f9e3          	bgeu	a5,a4,80005ace <sys_unlink+0xaa>
    80005b60:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b64:	4741                	li	a4,16
    80005b66:	86ce                	mv	a3,s3
    80005b68:	f1840613          	addi	a2,s0,-232
    80005b6c:	4581                	li	a1,0
    80005b6e:	854a                	mv	a0,s2
    80005b70:	ffffe097          	auipc	ra,0xffffe
    80005b74:	36e080e7          	jalr	878(ra) # 80003ede <readi>
    80005b78:	47c1                	li	a5,16
    80005b7a:	00f51b63          	bne	a0,a5,80005b90 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b7e:	f1845783          	lhu	a5,-232(s0)
    80005b82:	e7a1                	bnez	a5,80005bca <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b84:	29c1                	addiw	s3,s3,16
    80005b86:	05492783          	lw	a5,84(s2)
    80005b8a:	fcf9ede3          	bltu	s3,a5,80005b64 <sys_unlink+0x140>
    80005b8e:	b781                	j	80005ace <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b90:	00003517          	auipc	a0,0x3
    80005b94:	c5050513          	addi	a0,a0,-944 # 800087e0 <syscalls+0x320>
    80005b98:	ffffb097          	auipc	ra,0xffffb
    80005b9c:	9b8080e7          	jalr	-1608(ra) # 80000550 <panic>
    panic("unlink: writei");
    80005ba0:	00003517          	auipc	a0,0x3
    80005ba4:	c5850513          	addi	a0,a0,-936 # 800087f8 <syscalls+0x338>
    80005ba8:	ffffb097          	auipc	ra,0xffffb
    80005bac:	9a8080e7          	jalr	-1624(ra) # 80000550 <panic>
    dp->nlink--;
    80005bb0:	0524d783          	lhu	a5,82(s1)
    80005bb4:	37fd                	addiw	a5,a5,-1
    80005bb6:	04f49923          	sh	a5,82(s1)
    iupdate(dp);
    80005bba:	8526                	mv	a0,s1
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	fa4080e7          	jalr	-92(ra) # 80003b60 <iupdate>
    80005bc4:	b781                	j	80005b04 <sys_unlink+0xe0>
    return -1;
    80005bc6:	557d                	li	a0,-1
    80005bc8:	a005                	j	80005be8 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005bca:	854a                	mv	a0,s2
    80005bcc:	ffffe097          	auipc	ra,0xffffe
    80005bd0:	2c0080e7          	jalr	704(ra) # 80003e8c <iunlockput>
  iunlockput(dp);
    80005bd4:	8526                	mv	a0,s1
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	2b6080e7          	jalr	694(ra) # 80003e8c <iunlockput>
  end_op();
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	a9c080e7          	jalr	-1380(ra) # 8000467a <end_op>
  return -1;
    80005be6:	557d                	li	a0,-1
}
    80005be8:	70ae                	ld	ra,232(sp)
    80005bea:	740e                	ld	s0,224(sp)
    80005bec:	64ee                	ld	s1,216(sp)
    80005bee:	694e                	ld	s2,208(sp)
    80005bf0:	69ae                	ld	s3,200(sp)
    80005bf2:	616d                	addi	sp,sp,240
    80005bf4:	8082                	ret

0000000080005bf6 <sys_open>:

uint64
sys_open(void)
{
    80005bf6:	7131                	addi	sp,sp,-192
    80005bf8:	fd06                	sd	ra,184(sp)
    80005bfa:	f922                	sd	s0,176(sp)
    80005bfc:	f526                	sd	s1,168(sp)
    80005bfe:	f14a                	sd	s2,160(sp)
    80005c00:	ed4e                	sd	s3,152(sp)
    80005c02:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c04:	08000613          	li	a2,128
    80005c08:	f5040593          	addi	a1,s0,-176
    80005c0c:	4501                	li	a0,0
    80005c0e:	ffffd097          	auipc	ra,0xffffd
    80005c12:	2aa080e7          	jalr	682(ra) # 80002eb8 <argstr>
    return -1;
    80005c16:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c18:	0c054163          	bltz	a0,80005cda <sys_open+0xe4>
    80005c1c:	f4c40593          	addi	a1,s0,-180
    80005c20:	4505                	li	a0,1
    80005c22:	ffffd097          	auipc	ra,0xffffd
    80005c26:	252080e7          	jalr	594(ra) # 80002e74 <argint>
    80005c2a:	0a054863          	bltz	a0,80005cda <sys_open+0xe4>

  begin_op();
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	9cc080e7          	jalr	-1588(ra) # 800045fa <begin_op>

  if(omode & O_CREATE){
    80005c36:	f4c42783          	lw	a5,-180(s0)
    80005c3a:	2007f793          	andi	a5,a5,512
    80005c3e:	cbdd                	beqz	a5,80005cf4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c40:	4681                	li	a3,0
    80005c42:	4601                	li	a2,0
    80005c44:	4589                	li	a1,2
    80005c46:	f5040513          	addi	a0,s0,-176
    80005c4a:	00000097          	auipc	ra,0x0
    80005c4e:	972080e7          	jalr	-1678(ra) # 800055bc <create>
    80005c52:	892a                	mv	s2,a0
    if(ip == 0){
    80005c54:	c959                	beqz	a0,80005cea <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c56:	04c91703          	lh	a4,76(s2)
    80005c5a:	478d                	li	a5,3
    80005c5c:	00f71763          	bne	a4,a5,80005c6a <sys_open+0x74>
    80005c60:	04e95703          	lhu	a4,78(s2)
    80005c64:	47a5                	li	a5,9
    80005c66:	0ce7ec63          	bltu	a5,a4,80005d3e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	da8080e7          	jalr	-600(ra) # 80004a12 <filealloc>
    80005c72:	89aa                	mv	s3,a0
    80005c74:	10050263          	beqz	a0,80005d78 <sys_open+0x182>
    80005c78:	00000097          	auipc	ra,0x0
    80005c7c:	902080e7          	jalr	-1790(ra) # 8000557a <fdalloc>
    80005c80:	84aa                	mv	s1,a0
    80005c82:	0e054663          	bltz	a0,80005d6e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c86:	04c91703          	lh	a4,76(s2)
    80005c8a:	478d                	li	a5,3
    80005c8c:	0cf70463          	beq	a4,a5,80005d54 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c90:	4789                	li	a5,2
    80005c92:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c96:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c9a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c9e:	f4c42783          	lw	a5,-180(s0)
    80005ca2:	0017c713          	xori	a4,a5,1
    80005ca6:	8b05                	andi	a4,a4,1
    80005ca8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005cac:	0037f713          	andi	a4,a5,3
    80005cb0:	00e03733          	snez	a4,a4
    80005cb4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005cb8:	4007f793          	andi	a5,a5,1024
    80005cbc:	c791                	beqz	a5,80005cc8 <sys_open+0xd2>
    80005cbe:	04c91703          	lh	a4,76(s2)
    80005cc2:	4789                	li	a5,2
    80005cc4:	08f70f63          	beq	a4,a5,80005d62 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005cc8:	854a                	mv	a0,s2
    80005cca:	ffffe097          	auipc	ra,0xffffe
    80005cce:	022080e7          	jalr	34(ra) # 80003cec <iunlock>
  end_op();
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	9a8080e7          	jalr	-1624(ra) # 8000467a <end_op>

  return fd;
}
    80005cda:	8526                	mv	a0,s1
    80005cdc:	70ea                	ld	ra,184(sp)
    80005cde:	744a                	ld	s0,176(sp)
    80005ce0:	74aa                	ld	s1,168(sp)
    80005ce2:	790a                	ld	s2,160(sp)
    80005ce4:	69ea                	ld	s3,152(sp)
    80005ce6:	6129                	addi	sp,sp,192
    80005ce8:	8082                	ret
      end_op();
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	990080e7          	jalr	-1648(ra) # 8000467a <end_op>
      return -1;
    80005cf2:	b7e5                	j	80005cda <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005cf4:	f5040513          	addi	a0,s0,-176
    80005cf8:	ffffe097          	auipc	ra,0xffffe
    80005cfc:	6e6080e7          	jalr	1766(ra) # 800043de <namei>
    80005d00:	892a                	mv	s2,a0
    80005d02:	c905                	beqz	a0,80005d32 <sys_open+0x13c>
    ilock(ip);
    80005d04:	ffffe097          	auipc	ra,0xffffe
    80005d08:	f26080e7          	jalr	-218(ra) # 80003c2a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d0c:	04c91703          	lh	a4,76(s2)
    80005d10:	4785                	li	a5,1
    80005d12:	f4f712e3          	bne	a4,a5,80005c56 <sys_open+0x60>
    80005d16:	f4c42783          	lw	a5,-180(s0)
    80005d1a:	dba1                	beqz	a5,80005c6a <sys_open+0x74>
      iunlockput(ip);
    80005d1c:	854a                	mv	a0,s2
    80005d1e:	ffffe097          	auipc	ra,0xffffe
    80005d22:	16e080e7          	jalr	366(ra) # 80003e8c <iunlockput>
      end_op();
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	954080e7          	jalr	-1708(ra) # 8000467a <end_op>
      return -1;
    80005d2e:	54fd                	li	s1,-1
    80005d30:	b76d                	j	80005cda <sys_open+0xe4>
      end_op();
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	948080e7          	jalr	-1720(ra) # 8000467a <end_op>
      return -1;
    80005d3a:	54fd                	li	s1,-1
    80005d3c:	bf79                	j	80005cda <sys_open+0xe4>
    iunlockput(ip);
    80005d3e:	854a                	mv	a0,s2
    80005d40:	ffffe097          	auipc	ra,0xffffe
    80005d44:	14c080e7          	jalr	332(ra) # 80003e8c <iunlockput>
    end_op();
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	932080e7          	jalr	-1742(ra) # 8000467a <end_op>
    return -1;
    80005d50:	54fd                	li	s1,-1
    80005d52:	b761                	j	80005cda <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d54:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d58:	04e91783          	lh	a5,78(s2)
    80005d5c:	02f99223          	sh	a5,36(s3)
    80005d60:	bf2d                	j	80005c9a <sys_open+0xa4>
    itrunc(ip);
    80005d62:	854a                	mv	a0,s2
    80005d64:	ffffe097          	auipc	ra,0xffffe
    80005d68:	fd4080e7          	jalr	-44(ra) # 80003d38 <itrunc>
    80005d6c:	bfb1                	j	80005cc8 <sys_open+0xd2>
      fileclose(f);
    80005d6e:	854e                	mv	a0,s3
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	d5e080e7          	jalr	-674(ra) # 80004ace <fileclose>
    iunlockput(ip);
    80005d78:	854a                	mv	a0,s2
    80005d7a:	ffffe097          	auipc	ra,0xffffe
    80005d7e:	112080e7          	jalr	274(ra) # 80003e8c <iunlockput>
    end_op();
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	8f8080e7          	jalr	-1800(ra) # 8000467a <end_op>
    return -1;
    80005d8a:	54fd                	li	s1,-1
    80005d8c:	b7b9                	j	80005cda <sys_open+0xe4>

0000000080005d8e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d8e:	7175                	addi	sp,sp,-144
    80005d90:	e506                	sd	ra,136(sp)
    80005d92:	e122                	sd	s0,128(sp)
    80005d94:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	864080e7          	jalr	-1948(ra) # 800045fa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d9e:	08000613          	li	a2,128
    80005da2:	f7040593          	addi	a1,s0,-144
    80005da6:	4501                	li	a0,0
    80005da8:	ffffd097          	auipc	ra,0xffffd
    80005dac:	110080e7          	jalr	272(ra) # 80002eb8 <argstr>
    80005db0:	02054963          	bltz	a0,80005de2 <sys_mkdir+0x54>
    80005db4:	4681                	li	a3,0
    80005db6:	4601                	li	a2,0
    80005db8:	4585                	li	a1,1
    80005dba:	f7040513          	addi	a0,s0,-144
    80005dbe:	fffff097          	auipc	ra,0xfffff
    80005dc2:	7fe080e7          	jalr	2046(ra) # 800055bc <create>
    80005dc6:	cd11                	beqz	a0,80005de2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	0c4080e7          	jalr	196(ra) # 80003e8c <iunlockput>
  end_op();
    80005dd0:	fffff097          	auipc	ra,0xfffff
    80005dd4:	8aa080e7          	jalr	-1878(ra) # 8000467a <end_op>
  return 0;
    80005dd8:	4501                	li	a0,0
}
    80005dda:	60aa                	ld	ra,136(sp)
    80005ddc:	640a                	ld	s0,128(sp)
    80005dde:	6149                	addi	sp,sp,144
    80005de0:	8082                	ret
    end_op();
    80005de2:	fffff097          	auipc	ra,0xfffff
    80005de6:	898080e7          	jalr	-1896(ra) # 8000467a <end_op>
    return -1;
    80005dea:	557d                	li	a0,-1
    80005dec:	b7fd                	j	80005dda <sys_mkdir+0x4c>

0000000080005dee <sys_mknod>:

uint64
sys_mknod(void)
{
    80005dee:	7135                	addi	sp,sp,-160
    80005df0:	ed06                	sd	ra,152(sp)
    80005df2:	e922                	sd	s0,144(sp)
    80005df4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005df6:	fffff097          	auipc	ra,0xfffff
    80005dfa:	804080e7          	jalr	-2044(ra) # 800045fa <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005dfe:	08000613          	li	a2,128
    80005e02:	f7040593          	addi	a1,s0,-144
    80005e06:	4501                	li	a0,0
    80005e08:	ffffd097          	auipc	ra,0xffffd
    80005e0c:	0b0080e7          	jalr	176(ra) # 80002eb8 <argstr>
    80005e10:	04054a63          	bltz	a0,80005e64 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e14:	f6c40593          	addi	a1,s0,-148
    80005e18:	4505                	li	a0,1
    80005e1a:	ffffd097          	auipc	ra,0xffffd
    80005e1e:	05a080e7          	jalr	90(ra) # 80002e74 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e22:	04054163          	bltz	a0,80005e64 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005e26:	f6840593          	addi	a1,s0,-152
    80005e2a:	4509                	li	a0,2
    80005e2c:	ffffd097          	auipc	ra,0xffffd
    80005e30:	048080e7          	jalr	72(ra) # 80002e74 <argint>
     argint(1, &major) < 0 ||
    80005e34:	02054863          	bltz	a0,80005e64 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e38:	f6841683          	lh	a3,-152(s0)
    80005e3c:	f6c41603          	lh	a2,-148(s0)
    80005e40:	458d                	li	a1,3
    80005e42:	f7040513          	addi	a0,s0,-144
    80005e46:	fffff097          	auipc	ra,0xfffff
    80005e4a:	776080e7          	jalr	1910(ra) # 800055bc <create>
     argint(2, &minor) < 0 ||
    80005e4e:	c919                	beqz	a0,80005e64 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e50:	ffffe097          	auipc	ra,0xffffe
    80005e54:	03c080e7          	jalr	60(ra) # 80003e8c <iunlockput>
  end_op();
    80005e58:	fffff097          	auipc	ra,0xfffff
    80005e5c:	822080e7          	jalr	-2014(ra) # 8000467a <end_op>
  return 0;
    80005e60:	4501                	li	a0,0
    80005e62:	a031                	j	80005e6e <sys_mknod+0x80>
    end_op();
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	816080e7          	jalr	-2026(ra) # 8000467a <end_op>
    return -1;
    80005e6c:	557d                	li	a0,-1
}
    80005e6e:	60ea                	ld	ra,152(sp)
    80005e70:	644a                	ld	s0,144(sp)
    80005e72:	610d                	addi	sp,sp,160
    80005e74:	8082                	ret

0000000080005e76 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e76:	7135                	addi	sp,sp,-160
    80005e78:	ed06                	sd	ra,152(sp)
    80005e7a:	e922                	sd	s0,144(sp)
    80005e7c:	e526                	sd	s1,136(sp)
    80005e7e:	e14a                	sd	s2,128(sp)
    80005e80:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e82:	ffffc097          	auipc	ra,0xffffc
    80005e86:	f34080e7          	jalr	-204(ra) # 80001db6 <myproc>
    80005e8a:	892a                	mv	s2,a0
  
  begin_op();
    80005e8c:	ffffe097          	auipc	ra,0xffffe
    80005e90:	76e080e7          	jalr	1902(ra) # 800045fa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e94:	08000613          	li	a2,128
    80005e98:	f6040593          	addi	a1,s0,-160
    80005e9c:	4501                	li	a0,0
    80005e9e:	ffffd097          	auipc	ra,0xffffd
    80005ea2:	01a080e7          	jalr	26(ra) # 80002eb8 <argstr>
    80005ea6:	04054b63          	bltz	a0,80005efc <sys_chdir+0x86>
    80005eaa:	f6040513          	addi	a0,s0,-160
    80005eae:	ffffe097          	auipc	ra,0xffffe
    80005eb2:	530080e7          	jalr	1328(ra) # 800043de <namei>
    80005eb6:	84aa                	mv	s1,a0
    80005eb8:	c131                	beqz	a0,80005efc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005eba:	ffffe097          	auipc	ra,0xffffe
    80005ebe:	d70080e7          	jalr	-656(ra) # 80003c2a <ilock>
  if(ip->type != T_DIR){
    80005ec2:	04c49703          	lh	a4,76(s1)
    80005ec6:	4785                	li	a5,1
    80005ec8:	04f71063          	bne	a4,a5,80005f08 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ecc:	8526                	mv	a0,s1
    80005ece:	ffffe097          	auipc	ra,0xffffe
    80005ed2:	e1e080e7          	jalr	-482(ra) # 80003cec <iunlock>
  iput(p->cwd);
    80005ed6:	15893503          	ld	a0,344(s2)
    80005eda:	ffffe097          	auipc	ra,0xffffe
    80005ede:	f0a080e7          	jalr	-246(ra) # 80003de4 <iput>
  end_op();
    80005ee2:	ffffe097          	auipc	ra,0xffffe
    80005ee6:	798080e7          	jalr	1944(ra) # 8000467a <end_op>
  p->cwd = ip;
    80005eea:	14993c23          	sd	s1,344(s2)
  return 0;
    80005eee:	4501                	li	a0,0
}
    80005ef0:	60ea                	ld	ra,152(sp)
    80005ef2:	644a                	ld	s0,144(sp)
    80005ef4:	64aa                	ld	s1,136(sp)
    80005ef6:	690a                	ld	s2,128(sp)
    80005ef8:	610d                	addi	sp,sp,160
    80005efa:	8082                	ret
    end_op();
    80005efc:	ffffe097          	auipc	ra,0xffffe
    80005f00:	77e080e7          	jalr	1918(ra) # 8000467a <end_op>
    return -1;
    80005f04:	557d                	li	a0,-1
    80005f06:	b7ed                	j	80005ef0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f08:	8526                	mv	a0,s1
    80005f0a:	ffffe097          	auipc	ra,0xffffe
    80005f0e:	f82080e7          	jalr	-126(ra) # 80003e8c <iunlockput>
    end_op();
    80005f12:	ffffe097          	auipc	ra,0xffffe
    80005f16:	768080e7          	jalr	1896(ra) # 8000467a <end_op>
    return -1;
    80005f1a:	557d                	li	a0,-1
    80005f1c:	bfd1                	j	80005ef0 <sys_chdir+0x7a>

0000000080005f1e <sys_exec>:

uint64
sys_exec(void)
{
    80005f1e:	7145                	addi	sp,sp,-464
    80005f20:	e786                	sd	ra,456(sp)
    80005f22:	e3a2                	sd	s0,448(sp)
    80005f24:	ff26                	sd	s1,440(sp)
    80005f26:	fb4a                	sd	s2,432(sp)
    80005f28:	f74e                	sd	s3,424(sp)
    80005f2a:	f352                	sd	s4,416(sp)
    80005f2c:	ef56                	sd	s5,408(sp)
    80005f2e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f30:	08000613          	li	a2,128
    80005f34:	f4040593          	addi	a1,s0,-192
    80005f38:	4501                	li	a0,0
    80005f3a:	ffffd097          	auipc	ra,0xffffd
    80005f3e:	f7e080e7          	jalr	-130(ra) # 80002eb8 <argstr>
    return -1;
    80005f42:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f44:	0c054a63          	bltz	a0,80006018 <sys_exec+0xfa>
    80005f48:	e3840593          	addi	a1,s0,-456
    80005f4c:	4505                	li	a0,1
    80005f4e:	ffffd097          	auipc	ra,0xffffd
    80005f52:	f48080e7          	jalr	-184(ra) # 80002e96 <argaddr>
    80005f56:	0c054163          	bltz	a0,80006018 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f5a:	10000613          	li	a2,256
    80005f5e:	4581                	li	a1,0
    80005f60:	e4040513          	addi	a0,s0,-448
    80005f64:	ffffb097          	auipc	ra,0xffffb
    80005f68:	1ea080e7          	jalr	490(ra) # 8000114e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f6c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f70:	89a6                	mv	s3,s1
    80005f72:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f74:	02000a13          	li	s4,32
    80005f78:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f7c:	00391513          	slli	a0,s2,0x3
    80005f80:	e3040593          	addi	a1,s0,-464
    80005f84:	e3843783          	ld	a5,-456(s0)
    80005f88:	953e                	add	a0,a0,a5
    80005f8a:	ffffd097          	auipc	ra,0xffffd
    80005f8e:	e50080e7          	jalr	-432(ra) # 80002dda <fetchaddr>
    80005f92:	02054a63          	bltz	a0,80005fc6 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f96:	e3043783          	ld	a5,-464(s0)
    80005f9a:	c3b9                	beqz	a5,80005fe0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f9c:	ffffb097          	auipc	ra,0xffffb
    80005fa0:	bf6080e7          	jalr	-1034(ra) # 80000b92 <kalloc>
    80005fa4:	85aa                	mv	a1,a0
    80005fa6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005faa:	cd11                	beqz	a0,80005fc6 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005fac:	6605                	lui	a2,0x1
    80005fae:	e3043503          	ld	a0,-464(s0)
    80005fb2:	ffffd097          	auipc	ra,0xffffd
    80005fb6:	e7a080e7          	jalr	-390(ra) # 80002e2c <fetchstr>
    80005fba:	00054663          	bltz	a0,80005fc6 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005fbe:	0905                	addi	s2,s2,1
    80005fc0:	09a1                	addi	s3,s3,8
    80005fc2:	fb491be3          	bne	s2,s4,80005f78 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fc6:	10048913          	addi	s2,s1,256
    80005fca:	6088                	ld	a0,0(s1)
    80005fcc:	c529                	beqz	a0,80006016 <sys_exec+0xf8>
    kfree(argv[i]);
    80005fce:	ffffb097          	auipc	ra,0xffffb
    80005fd2:	a5e080e7          	jalr	-1442(ra) # 80000a2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fd6:	04a1                	addi	s1,s1,8
    80005fd8:	ff2499e3          	bne	s1,s2,80005fca <sys_exec+0xac>
  return -1;
    80005fdc:	597d                	li	s2,-1
    80005fde:	a82d                	j	80006018 <sys_exec+0xfa>
      argv[i] = 0;
    80005fe0:	0a8e                	slli	s5,s5,0x3
    80005fe2:	fc040793          	addi	a5,s0,-64
    80005fe6:	9abe                	add	s5,s5,a5
    80005fe8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005fec:	e4040593          	addi	a1,s0,-448
    80005ff0:	f4040513          	addi	a0,s0,-192
    80005ff4:	fffff097          	auipc	ra,0xfffff
    80005ff8:	194080e7          	jalr	404(ra) # 80005188 <exec>
    80005ffc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ffe:	10048993          	addi	s3,s1,256
    80006002:	6088                	ld	a0,0(s1)
    80006004:	c911                	beqz	a0,80006018 <sys_exec+0xfa>
    kfree(argv[i]);
    80006006:	ffffb097          	auipc	ra,0xffffb
    8000600a:	a26080e7          	jalr	-1498(ra) # 80000a2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000600e:	04a1                	addi	s1,s1,8
    80006010:	ff3499e3          	bne	s1,s3,80006002 <sys_exec+0xe4>
    80006014:	a011                	j	80006018 <sys_exec+0xfa>
  return -1;
    80006016:	597d                	li	s2,-1
}
    80006018:	854a                	mv	a0,s2
    8000601a:	60be                	ld	ra,456(sp)
    8000601c:	641e                	ld	s0,448(sp)
    8000601e:	74fa                	ld	s1,440(sp)
    80006020:	795a                	ld	s2,432(sp)
    80006022:	79ba                	ld	s3,424(sp)
    80006024:	7a1a                	ld	s4,416(sp)
    80006026:	6afa                	ld	s5,408(sp)
    80006028:	6179                	addi	sp,sp,464
    8000602a:	8082                	ret

000000008000602c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000602c:	7139                	addi	sp,sp,-64
    8000602e:	fc06                	sd	ra,56(sp)
    80006030:	f822                	sd	s0,48(sp)
    80006032:	f426                	sd	s1,40(sp)
    80006034:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006036:	ffffc097          	auipc	ra,0xffffc
    8000603a:	d80080e7          	jalr	-640(ra) # 80001db6 <myproc>
    8000603e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006040:	fd840593          	addi	a1,s0,-40
    80006044:	4501                	li	a0,0
    80006046:	ffffd097          	auipc	ra,0xffffd
    8000604a:	e50080e7          	jalr	-432(ra) # 80002e96 <argaddr>
    return -1;
    8000604e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006050:	0e054063          	bltz	a0,80006130 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006054:	fc840593          	addi	a1,s0,-56
    80006058:	fd040513          	addi	a0,s0,-48
    8000605c:	fffff097          	auipc	ra,0xfffff
    80006060:	dc8080e7          	jalr	-568(ra) # 80004e24 <pipealloc>
    return -1;
    80006064:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006066:	0c054563          	bltz	a0,80006130 <sys_pipe+0x104>
  fd0 = -1;
    8000606a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000606e:	fd043503          	ld	a0,-48(s0)
    80006072:	fffff097          	auipc	ra,0xfffff
    80006076:	508080e7          	jalr	1288(ra) # 8000557a <fdalloc>
    8000607a:	fca42223          	sw	a0,-60(s0)
    8000607e:	08054c63          	bltz	a0,80006116 <sys_pipe+0xea>
    80006082:	fc843503          	ld	a0,-56(s0)
    80006086:	fffff097          	auipc	ra,0xfffff
    8000608a:	4f4080e7          	jalr	1268(ra) # 8000557a <fdalloc>
    8000608e:	fca42023          	sw	a0,-64(s0)
    80006092:	06054863          	bltz	a0,80006102 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006096:	4691                	li	a3,4
    80006098:	fc440613          	addi	a2,s0,-60
    8000609c:	fd843583          	ld	a1,-40(s0)
    800060a0:	6ca8                	ld	a0,88(s1)
    800060a2:	ffffc097          	auipc	ra,0xffffc
    800060a6:	a08080e7          	jalr	-1528(ra) # 80001aaa <copyout>
    800060aa:	02054063          	bltz	a0,800060ca <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060ae:	4691                	li	a3,4
    800060b0:	fc040613          	addi	a2,s0,-64
    800060b4:	fd843583          	ld	a1,-40(s0)
    800060b8:	0591                	addi	a1,a1,4
    800060ba:	6ca8                	ld	a0,88(s1)
    800060bc:	ffffc097          	auipc	ra,0xffffc
    800060c0:	9ee080e7          	jalr	-1554(ra) # 80001aaa <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800060c4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060c6:	06055563          	bgez	a0,80006130 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800060ca:	fc442783          	lw	a5,-60(s0)
    800060ce:	07e9                	addi	a5,a5,26
    800060d0:	078e                	slli	a5,a5,0x3
    800060d2:	97a6                	add	a5,a5,s1
    800060d4:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    800060d8:	fc042503          	lw	a0,-64(s0)
    800060dc:	0569                	addi	a0,a0,26
    800060de:	050e                	slli	a0,a0,0x3
    800060e0:	9526                	add	a0,a0,s1
    800060e2:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    800060e6:	fd043503          	ld	a0,-48(s0)
    800060ea:	fffff097          	auipc	ra,0xfffff
    800060ee:	9e4080e7          	jalr	-1564(ra) # 80004ace <fileclose>
    fileclose(wf);
    800060f2:	fc843503          	ld	a0,-56(s0)
    800060f6:	fffff097          	auipc	ra,0xfffff
    800060fa:	9d8080e7          	jalr	-1576(ra) # 80004ace <fileclose>
    return -1;
    800060fe:	57fd                	li	a5,-1
    80006100:	a805                	j	80006130 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006102:	fc442783          	lw	a5,-60(s0)
    80006106:	0007c863          	bltz	a5,80006116 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000610a:	01a78513          	addi	a0,a5,26
    8000610e:	050e                	slli	a0,a0,0x3
    80006110:	9526                	add	a0,a0,s1
    80006112:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006116:	fd043503          	ld	a0,-48(s0)
    8000611a:	fffff097          	auipc	ra,0xfffff
    8000611e:	9b4080e7          	jalr	-1612(ra) # 80004ace <fileclose>
    fileclose(wf);
    80006122:	fc843503          	ld	a0,-56(s0)
    80006126:	fffff097          	auipc	ra,0xfffff
    8000612a:	9a8080e7          	jalr	-1624(ra) # 80004ace <fileclose>
    return -1;
    8000612e:	57fd                	li	a5,-1
}
    80006130:	853e                	mv	a0,a5
    80006132:	70e2                	ld	ra,56(sp)
    80006134:	7442                	ld	s0,48(sp)
    80006136:	74a2                	ld	s1,40(sp)
    80006138:	6121                	addi	sp,sp,64
    8000613a:	8082                	ret
    8000613c:	0000                	unimp
	...

0000000080006140 <kernelvec>:
    80006140:	7111                	addi	sp,sp,-256
    80006142:	e006                	sd	ra,0(sp)
    80006144:	e40a                	sd	sp,8(sp)
    80006146:	e80e                	sd	gp,16(sp)
    80006148:	ec12                	sd	tp,24(sp)
    8000614a:	f016                	sd	t0,32(sp)
    8000614c:	f41a                	sd	t1,40(sp)
    8000614e:	f81e                	sd	t2,48(sp)
    80006150:	fc22                	sd	s0,56(sp)
    80006152:	e0a6                	sd	s1,64(sp)
    80006154:	e4aa                	sd	a0,72(sp)
    80006156:	e8ae                	sd	a1,80(sp)
    80006158:	ecb2                	sd	a2,88(sp)
    8000615a:	f0b6                	sd	a3,96(sp)
    8000615c:	f4ba                	sd	a4,104(sp)
    8000615e:	f8be                	sd	a5,112(sp)
    80006160:	fcc2                	sd	a6,120(sp)
    80006162:	e146                	sd	a7,128(sp)
    80006164:	e54a                	sd	s2,136(sp)
    80006166:	e94e                	sd	s3,144(sp)
    80006168:	ed52                	sd	s4,152(sp)
    8000616a:	f156                	sd	s5,160(sp)
    8000616c:	f55a                	sd	s6,168(sp)
    8000616e:	f95e                	sd	s7,176(sp)
    80006170:	fd62                	sd	s8,184(sp)
    80006172:	e1e6                	sd	s9,192(sp)
    80006174:	e5ea                	sd	s10,200(sp)
    80006176:	e9ee                	sd	s11,208(sp)
    80006178:	edf2                	sd	t3,216(sp)
    8000617a:	f1f6                	sd	t4,224(sp)
    8000617c:	f5fa                	sd	t5,232(sp)
    8000617e:	f9fe                	sd	t6,240(sp)
    80006180:	b27fc0ef          	jal	ra,80002ca6 <kerneltrap>
    80006184:	6082                	ld	ra,0(sp)
    80006186:	6122                	ld	sp,8(sp)
    80006188:	61c2                	ld	gp,16(sp)
    8000618a:	7282                	ld	t0,32(sp)
    8000618c:	7322                	ld	t1,40(sp)
    8000618e:	73c2                	ld	t2,48(sp)
    80006190:	7462                	ld	s0,56(sp)
    80006192:	6486                	ld	s1,64(sp)
    80006194:	6526                	ld	a0,72(sp)
    80006196:	65c6                	ld	a1,80(sp)
    80006198:	6666                	ld	a2,88(sp)
    8000619a:	7686                	ld	a3,96(sp)
    8000619c:	7726                	ld	a4,104(sp)
    8000619e:	77c6                	ld	a5,112(sp)
    800061a0:	7866                	ld	a6,120(sp)
    800061a2:	688a                	ld	a7,128(sp)
    800061a4:	692a                	ld	s2,136(sp)
    800061a6:	69ca                	ld	s3,144(sp)
    800061a8:	6a6a                	ld	s4,152(sp)
    800061aa:	7a8a                	ld	s5,160(sp)
    800061ac:	7b2a                	ld	s6,168(sp)
    800061ae:	7bca                	ld	s7,176(sp)
    800061b0:	7c6a                	ld	s8,184(sp)
    800061b2:	6c8e                	ld	s9,192(sp)
    800061b4:	6d2e                	ld	s10,200(sp)
    800061b6:	6dce                	ld	s11,208(sp)
    800061b8:	6e6e                	ld	t3,216(sp)
    800061ba:	7e8e                	ld	t4,224(sp)
    800061bc:	7f2e                	ld	t5,232(sp)
    800061be:	7fce                	ld	t6,240(sp)
    800061c0:	6111                	addi	sp,sp,256
    800061c2:	10200073          	sret
    800061c6:	00000013          	nop
    800061ca:	00000013          	nop
    800061ce:	0001                	nop

00000000800061d0 <timervec>:
    800061d0:	34051573          	csrrw	a0,mscratch,a0
    800061d4:	e10c                	sd	a1,0(a0)
    800061d6:	e510                	sd	a2,8(a0)
    800061d8:	e914                	sd	a3,16(a0)
    800061da:	6d0c                	ld	a1,24(a0)
    800061dc:	7110                	ld	a2,32(a0)
    800061de:	6194                	ld	a3,0(a1)
    800061e0:	96b2                	add	a3,a3,a2
    800061e2:	e194                	sd	a3,0(a1)
    800061e4:	4589                	li	a1,2
    800061e6:	14459073          	csrw	sip,a1
    800061ea:	6914                	ld	a3,16(a0)
    800061ec:	6510                	ld	a2,8(a0)
    800061ee:	610c                	ld	a1,0(a0)
    800061f0:	34051573          	csrrw	a0,mscratch,a0
    800061f4:	30200073          	mret
	...

00000000800061fa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061fa:	1141                	addi	sp,sp,-16
    800061fc:	e422                	sd	s0,8(sp)
    800061fe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006200:	0c0007b7          	lui	a5,0xc000
    80006204:	4705                	li	a4,1
    80006206:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006208:	c3d8                	sw	a4,4(a5)
}
    8000620a:	6422                	ld	s0,8(sp)
    8000620c:	0141                	addi	sp,sp,16
    8000620e:	8082                	ret

0000000080006210 <plicinithart>:

void
plicinithart(void)
{
    80006210:	1141                	addi	sp,sp,-16
    80006212:	e406                	sd	ra,8(sp)
    80006214:	e022                	sd	s0,0(sp)
    80006216:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006218:	ffffc097          	auipc	ra,0xffffc
    8000621c:	b72080e7          	jalr	-1166(ra) # 80001d8a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006220:	0085171b          	slliw	a4,a0,0x8
    80006224:	0c0027b7          	lui	a5,0xc002
    80006228:	97ba                	add	a5,a5,a4
    8000622a:	40200713          	li	a4,1026
    8000622e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006232:	00d5151b          	slliw	a0,a0,0xd
    80006236:	0c2017b7          	lui	a5,0xc201
    8000623a:	953e                	add	a0,a0,a5
    8000623c:	00052023          	sw	zero,0(a0)
}
    80006240:	60a2                	ld	ra,8(sp)
    80006242:	6402                	ld	s0,0(sp)
    80006244:	0141                	addi	sp,sp,16
    80006246:	8082                	ret

0000000080006248 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006248:	1141                	addi	sp,sp,-16
    8000624a:	e406                	sd	ra,8(sp)
    8000624c:	e022                	sd	s0,0(sp)
    8000624e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006250:	ffffc097          	auipc	ra,0xffffc
    80006254:	b3a080e7          	jalr	-1222(ra) # 80001d8a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006258:	00d5179b          	slliw	a5,a0,0xd
    8000625c:	0c201537          	lui	a0,0xc201
    80006260:	953e                	add	a0,a0,a5
  return irq;
}
    80006262:	4148                	lw	a0,4(a0)
    80006264:	60a2                	ld	ra,8(sp)
    80006266:	6402                	ld	s0,0(sp)
    80006268:	0141                	addi	sp,sp,16
    8000626a:	8082                	ret

000000008000626c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000626c:	1101                	addi	sp,sp,-32
    8000626e:	ec06                	sd	ra,24(sp)
    80006270:	e822                	sd	s0,16(sp)
    80006272:	e426                	sd	s1,8(sp)
    80006274:	1000                	addi	s0,sp,32
    80006276:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006278:	ffffc097          	auipc	ra,0xffffc
    8000627c:	b12080e7          	jalr	-1262(ra) # 80001d8a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006280:	00d5151b          	slliw	a0,a0,0xd
    80006284:	0c2017b7          	lui	a5,0xc201
    80006288:	97aa                	add	a5,a5,a0
    8000628a:	c3c4                	sw	s1,4(a5)
}
    8000628c:	60e2                	ld	ra,24(sp)
    8000628e:	6442                	ld	s0,16(sp)
    80006290:	64a2                	ld	s1,8(sp)
    80006292:	6105                	addi	sp,sp,32
    80006294:	8082                	ret

0000000080006296 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006296:	1141                	addi	sp,sp,-16
    80006298:	e406                	sd	ra,8(sp)
    8000629a:	e022                	sd	s0,0(sp)
    8000629c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000629e:	479d                	li	a5,7
    800062a0:	06a7c963          	blt	a5,a0,80006312 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800062a4:	00021797          	auipc	a5,0x21
    800062a8:	d5c78793          	addi	a5,a5,-676 # 80027000 <disk>
    800062ac:	00a78733          	add	a4,a5,a0
    800062b0:	6789                	lui	a5,0x2
    800062b2:	97ba                	add	a5,a5,a4
    800062b4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800062b8:	e7ad                	bnez	a5,80006322 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062ba:	00451793          	slli	a5,a0,0x4
    800062be:	00023717          	auipc	a4,0x23
    800062c2:	d4270713          	addi	a4,a4,-702 # 80029000 <disk+0x2000>
    800062c6:	6314                	ld	a3,0(a4)
    800062c8:	96be                	add	a3,a3,a5
    800062ca:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800062ce:	6314                	ld	a3,0(a4)
    800062d0:	96be                	add	a3,a3,a5
    800062d2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800062d6:	6314                	ld	a3,0(a4)
    800062d8:	96be                	add	a3,a3,a5
    800062da:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800062de:	6318                	ld	a4,0(a4)
    800062e0:	97ba                	add	a5,a5,a4
    800062e2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800062e6:	00021797          	auipc	a5,0x21
    800062ea:	d1a78793          	addi	a5,a5,-742 # 80027000 <disk>
    800062ee:	97aa                	add	a5,a5,a0
    800062f0:	6509                	lui	a0,0x2
    800062f2:	953e                	add	a0,a0,a5
    800062f4:	4785                	li	a5,1
    800062f6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800062fa:	00023517          	auipc	a0,0x23
    800062fe:	d1e50513          	addi	a0,a0,-738 # 80029018 <disk+0x2018>
    80006302:	ffffc097          	auipc	ra,0xffffc
    80006306:	44a080e7          	jalr	1098(ra) # 8000274c <wakeup>
}
    8000630a:	60a2                	ld	ra,8(sp)
    8000630c:	6402                	ld	s0,0(sp)
    8000630e:	0141                	addi	sp,sp,16
    80006310:	8082                	ret
    panic("free_desc 1");
    80006312:	00002517          	auipc	a0,0x2
    80006316:	4f650513          	addi	a0,a0,1270 # 80008808 <syscalls+0x348>
    8000631a:	ffffa097          	auipc	ra,0xffffa
    8000631e:	236080e7          	jalr	566(ra) # 80000550 <panic>
    panic("free_desc 2");
    80006322:	00002517          	auipc	a0,0x2
    80006326:	4f650513          	addi	a0,a0,1270 # 80008818 <syscalls+0x358>
    8000632a:	ffffa097          	auipc	ra,0xffffa
    8000632e:	226080e7          	jalr	550(ra) # 80000550 <panic>

0000000080006332 <virtio_disk_init>:
{
    80006332:	1101                	addi	sp,sp,-32
    80006334:	ec06                	sd	ra,24(sp)
    80006336:	e822                	sd	s0,16(sp)
    80006338:	e426                	sd	s1,8(sp)
    8000633a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000633c:	00002597          	auipc	a1,0x2
    80006340:	4ec58593          	addi	a1,a1,1260 # 80008828 <syscalls+0x368>
    80006344:	00023517          	auipc	a0,0x23
    80006348:	de450513          	addi	a0,a0,-540 # 80029128 <disk+0x2128>
    8000634c:	ffffb097          	auipc	ra,0xffffb
    80006350:	b9e080e7          	jalr	-1122(ra) # 80000eea <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006354:	100017b7          	lui	a5,0x10001
    80006358:	4398                	lw	a4,0(a5)
    8000635a:	2701                	sext.w	a4,a4
    8000635c:	747277b7          	lui	a5,0x74727
    80006360:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006364:	0ef71163          	bne	a4,a5,80006446 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006368:	100017b7          	lui	a5,0x10001
    8000636c:	43dc                	lw	a5,4(a5)
    8000636e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006370:	4705                	li	a4,1
    80006372:	0ce79a63          	bne	a5,a4,80006446 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006376:	100017b7          	lui	a5,0x10001
    8000637a:	479c                	lw	a5,8(a5)
    8000637c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000637e:	4709                	li	a4,2
    80006380:	0ce79363          	bne	a5,a4,80006446 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006384:	100017b7          	lui	a5,0x10001
    80006388:	47d8                	lw	a4,12(a5)
    8000638a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000638c:	554d47b7          	lui	a5,0x554d4
    80006390:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006394:	0af71963          	bne	a4,a5,80006446 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006398:	100017b7          	lui	a5,0x10001
    8000639c:	4705                	li	a4,1
    8000639e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063a0:	470d                	li	a4,3
    800063a2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800063a4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800063a6:	c7ffe737          	lui	a4,0xc7ffe
    800063aa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd3737>
    800063ae:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800063b0:	2701                	sext.w	a4,a4
    800063b2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063b4:	472d                	li	a4,11
    800063b6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063b8:	473d                	li	a4,15
    800063ba:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800063bc:	6705                	lui	a4,0x1
    800063be:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063c0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063c4:	5bdc                	lw	a5,52(a5)
    800063c6:	2781                	sext.w	a5,a5
  if(max == 0)
    800063c8:	c7d9                	beqz	a5,80006456 <virtio_disk_init+0x124>
  if(max < NUM)
    800063ca:	471d                	li	a4,7
    800063cc:	08f77d63          	bgeu	a4,a5,80006466 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063d0:	100014b7          	lui	s1,0x10001
    800063d4:	47a1                	li	a5,8
    800063d6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800063d8:	6609                	lui	a2,0x2
    800063da:	4581                	li	a1,0
    800063dc:	00021517          	auipc	a0,0x21
    800063e0:	c2450513          	addi	a0,a0,-988 # 80027000 <disk>
    800063e4:	ffffb097          	auipc	ra,0xffffb
    800063e8:	d6a080e7          	jalr	-662(ra) # 8000114e <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800063ec:	00021717          	auipc	a4,0x21
    800063f0:	c1470713          	addi	a4,a4,-1004 # 80027000 <disk>
    800063f4:	00c75793          	srli	a5,a4,0xc
    800063f8:	2781                	sext.w	a5,a5
    800063fa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800063fc:	00023797          	auipc	a5,0x23
    80006400:	c0478793          	addi	a5,a5,-1020 # 80029000 <disk+0x2000>
    80006404:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006406:	00021717          	auipc	a4,0x21
    8000640a:	c7a70713          	addi	a4,a4,-902 # 80027080 <disk+0x80>
    8000640e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006410:	00022717          	auipc	a4,0x22
    80006414:	bf070713          	addi	a4,a4,-1040 # 80028000 <disk+0x1000>
    80006418:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000641a:	4705                	li	a4,1
    8000641c:	00e78c23          	sb	a4,24(a5)
    80006420:	00e78ca3          	sb	a4,25(a5)
    80006424:	00e78d23          	sb	a4,26(a5)
    80006428:	00e78da3          	sb	a4,27(a5)
    8000642c:	00e78e23          	sb	a4,28(a5)
    80006430:	00e78ea3          	sb	a4,29(a5)
    80006434:	00e78f23          	sb	a4,30(a5)
    80006438:	00e78fa3          	sb	a4,31(a5)
}
    8000643c:	60e2                	ld	ra,24(sp)
    8000643e:	6442                	ld	s0,16(sp)
    80006440:	64a2                	ld	s1,8(sp)
    80006442:	6105                	addi	sp,sp,32
    80006444:	8082                	ret
    panic("could not find virtio disk");
    80006446:	00002517          	auipc	a0,0x2
    8000644a:	3f250513          	addi	a0,a0,1010 # 80008838 <syscalls+0x378>
    8000644e:	ffffa097          	auipc	ra,0xffffa
    80006452:	102080e7          	jalr	258(ra) # 80000550 <panic>
    panic("virtio disk has no queue 0");
    80006456:	00002517          	auipc	a0,0x2
    8000645a:	40250513          	addi	a0,a0,1026 # 80008858 <syscalls+0x398>
    8000645e:	ffffa097          	auipc	ra,0xffffa
    80006462:	0f2080e7          	jalr	242(ra) # 80000550 <panic>
    panic("virtio disk max queue too short");
    80006466:	00002517          	auipc	a0,0x2
    8000646a:	41250513          	addi	a0,a0,1042 # 80008878 <syscalls+0x3b8>
    8000646e:	ffffa097          	auipc	ra,0xffffa
    80006472:	0e2080e7          	jalr	226(ra) # 80000550 <panic>

0000000080006476 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006476:	7159                	addi	sp,sp,-112
    80006478:	f486                	sd	ra,104(sp)
    8000647a:	f0a2                	sd	s0,96(sp)
    8000647c:	eca6                	sd	s1,88(sp)
    8000647e:	e8ca                	sd	s2,80(sp)
    80006480:	e4ce                	sd	s3,72(sp)
    80006482:	e0d2                	sd	s4,64(sp)
    80006484:	fc56                	sd	s5,56(sp)
    80006486:	f85a                	sd	s6,48(sp)
    80006488:	f45e                	sd	s7,40(sp)
    8000648a:	f062                	sd	s8,32(sp)
    8000648c:	ec66                	sd	s9,24(sp)
    8000648e:	e86a                	sd	s10,16(sp)
    80006490:	1880                	addi	s0,sp,112
    80006492:	892a                	mv	s2,a0
    80006494:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006496:	00c52c83          	lw	s9,12(a0)
    8000649a:	001c9c9b          	slliw	s9,s9,0x1
    8000649e:	1c82                	slli	s9,s9,0x20
    800064a0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800064a4:	00023517          	auipc	a0,0x23
    800064a8:	c8450513          	addi	a0,a0,-892 # 80029128 <disk+0x2128>
    800064ac:	ffffb097          	auipc	ra,0xffffb
    800064b0:	8c2080e7          	jalr	-1854(ra) # 80000d6e <acquire>
  for(int i = 0; i < 3; i++){
    800064b4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800064b6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800064b8:	00021b97          	auipc	s7,0x21
    800064bc:	b48b8b93          	addi	s7,s7,-1208 # 80027000 <disk>
    800064c0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800064c2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800064c4:	8a4e                	mv	s4,s3
    800064c6:	a051                	j	8000654a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800064c8:	00fb86b3          	add	a3,s7,a5
    800064cc:	96da                	add	a3,a3,s6
    800064ce:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800064d2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800064d4:	0207c563          	bltz	a5,800064fe <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800064d8:	2485                	addiw	s1,s1,1
    800064da:	0711                	addi	a4,a4,4
    800064dc:	25548063          	beq	s1,s5,8000671c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800064e0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800064e2:	00023697          	auipc	a3,0x23
    800064e6:	b3668693          	addi	a3,a3,-1226 # 80029018 <disk+0x2018>
    800064ea:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800064ec:	0006c583          	lbu	a1,0(a3)
    800064f0:	fde1                	bnez	a1,800064c8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800064f2:	2785                	addiw	a5,a5,1
    800064f4:	0685                	addi	a3,a3,1
    800064f6:	ff879be3          	bne	a5,s8,800064ec <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800064fa:	57fd                	li	a5,-1
    800064fc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800064fe:	02905a63          	blez	s1,80006532 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006502:	f9042503          	lw	a0,-112(s0)
    80006506:	00000097          	auipc	ra,0x0
    8000650a:	d90080e7          	jalr	-624(ra) # 80006296 <free_desc>
      for(int j = 0; j < i; j++)
    8000650e:	4785                	li	a5,1
    80006510:	0297d163          	bge	a5,s1,80006532 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006514:	f9442503          	lw	a0,-108(s0)
    80006518:	00000097          	auipc	ra,0x0
    8000651c:	d7e080e7          	jalr	-642(ra) # 80006296 <free_desc>
      for(int j = 0; j < i; j++)
    80006520:	4789                	li	a5,2
    80006522:	0097d863          	bge	a5,s1,80006532 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006526:	f9842503          	lw	a0,-104(s0)
    8000652a:	00000097          	auipc	ra,0x0
    8000652e:	d6c080e7          	jalr	-660(ra) # 80006296 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006532:	00023597          	auipc	a1,0x23
    80006536:	bf658593          	addi	a1,a1,-1034 # 80029128 <disk+0x2128>
    8000653a:	00023517          	auipc	a0,0x23
    8000653e:	ade50513          	addi	a0,a0,-1314 # 80029018 <disk+0x2018>
    80006542:	ffffc097          	auipc	ra,0xffffc
    80006546:	084080e7          	jalr	132(ra) # 800025c6 <sleep>
  for(int i = 0; i < 3; i++){
    8000654a:	f9040713          	addi	a4,s0,-112
    8000654e:	84ce                	mv	s1,s3
    80006550:	bf41                	j	800064e0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006552:	20058713          	addi	a4,a1,512
    80006556:	00471693          	slli	a3,a4,0x4
    8000655a:	00021717          	auipc	a4,0x21
    8000655e:	aa670713          	addi	a4,a4,-1370 # 80027000 <disk>
    80006562:	9736                	add	a4,a4,a3
    80006564:	4685                	li	a3,1
    80006566:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000656a:	20058713          	addi	a4,a1,512
    8000656e:	00471693          	slli	a3,a4,0x4
    80006572:	00021717          	auipc	a4,0x21
    80006576:	a8e70713          	addi	a4,a4,-1394 # 80027000 <disk>
    8000657a:	9736                	add	a4,a4,a3
    8000657c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006580:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006584:	7679                	lui	a2,0xffffe
    80006586:	963e                	add	a2,a2,a5
    80006588:	00023697          	auipc	a3,0x23
    8000658c:	a7868693          	addi	a3,a3,-1416 # 80029000 <disk+0x2000>
    80006590:	6298                	ld	a4,0(a3)
    80006592:	9732                	add	a4,a4,a2
    80006594:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006596:	6298                	ld	a4,0(a3)
    80006598:	9732                	add	a4,a4,a2
    8000659a:	4541                	li	a0,16
    8000659c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000659e:	6298                	ld	a4,0(a3)
    800065a0:	9732                	add	a4,a4,a2
    800065a2:	4505                	li	a0,1
    800065a4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800065a8:	f9442703          	lw	a4,-108(s0)
    800065ac:	6288                	ld	a0,0(a3)
    800065ae:	962a                	add	a2,a2,a0
    800065b0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd2fe6>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065b4:	0712                	slli	a4,a4,0x4
    800065b6:	6290                	ld	a2,0(a3)
    800065b8:	963a                	add	a2,a2,a4
    800065ba:	05890513          	addi	a0,s2,88
    800065be:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800065c0:	6294                	ld	a3,0(a3)
    800065c2:	96ba                	add	a3,a3,a4
    800065c4:	40000613          	li	a2,1024
    800065c8:	c690                	sw	a2,8(a3)
  if(write)
    800065ca:	140d0063          	beqz	s10,8000670a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800065ce:	00023697          	auipc	a3,0x23
    800065d2:	a326b683          	ld	a3,-1486(a3) # 80029000 <disk+0x2000>
    800065d6:	96ba                	add	a3,a3,a4
    800065d8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065dc:	00021817          	auipc	a6,0x21
    800065e0:	a2480813          	addi	a6,a6,-1500 # 80027000 <disk>
    800065e4:	00023517          	auipc	a0,0x23
    800065e8:	a1c50513          	addi	a0,a0,-1508 # 80029000 <disk+0x2000>
    800065ec:	6114                	ld	a3,0(a0)
    800065ee:	96ba                	add	a3,a3,a4
    800065f0:	00c6d603          	lhu	a2,12(a3)
    800065f4:	00166613          	ori	a2,a2,1
    800065f8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800065fc:	f9842683          	lw	a3,-104(s0)
    80006600:	6110                	ld	a2,0(a0)
    80006602:	9732                	add	a4,a4,a2
    80006604:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006608:	20058613          	addi	a2,a1,512
    8000660c:	0612                	slli	a2,a2,0x4
    8000660e:	9642                	add	a2,a2,a6
    80006610:	577d                	li	a4,-1
    80006612:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006616:	00469713          	slli	a4,a3,0x4
    8000661a:	6114                	ld	a3,0(a0)
    8000661c:	96ba                	add	a3,a3,a4
    8000661e:	03078793          	addi	a5,a5,48
    80006622:	97c2                	add	a5,a5,a6
    80006624:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006626:	611c                	ld	a5,0(a0)
    80006628:	97ba                	add	a5,a5,a4
    8000662a:	4685                	li	a3,1
    8000662c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000662e:	611c                	ld	a5,0(a0)
    80006630:	97ba                	add	a5,a5,a4
    80006632:	4809                	li	a6,2
    80006634:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006638:	611c                	ld	a5,0(a0)
    8000663a:	973e                	add	a4,a4,a5
    8000663c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006640:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006644:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006648:	6518                	ld	a4,8(a0)
    8000664a:	00275783          	lhu	a5,2(a4)
    8000664e:	8b9d                	andi	a5,a5,7
    80006650:	0786                	slli	a5,a5,0x1
    80006652:	97ba                	add	a5,a5,a4
    80006654:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006658:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000665c:	6518                	ld	a4,8(a0)
    8000665e:	00275783          	lhu	a5,2(a4)
    80006662:	2785                	addiw	a5,a5,1
    80006664:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006668:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000666c:	100017b7          	lui	a5,0x10001
    80006670:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006674:	00492703          	lw	a4,4(s2)
    80006678:	4785                	li	a5,1
    8000667a:	02f71163          	bne	a4,a5,8000669c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000667e:	00023997          	auipc	s3,0x23
    80006682:	aaa98993          	addi	s3,s3,-1366 # 80029128 <disk+0x2128>
  while(b->disk == 1) {
    80006686:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006688:	85ce                	mv	a1,s3
    8000668a:	854a                	mv	a0,s2
    8000668c:	ffffc097          	auipc	ra,0xffffc
    80006690:	f3a080e7          	jalr	-198(ra) # 800025c6 <sleep>
  while(b->disk == 1) {
    80006694:	00492783          	lw	a5,4(s2)
    80006698:	fe9788e3          	beq	a5,s1,80006688 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000669c:	f9042903          	lw	s2,-112(s0)
    800066a0:	20090793          	addi	a5,s2,512
    800066a4:	00479713          	slli	a4,a5,0x4
    800066a8:	00021797          	auipc	a5,0x21
    800066ac:	95878793          	addi	a5,a5,-1704 # 80027000 <disk>
    800066b0:	97ba                	add	a5,a5,a4
    800066b2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800066b6:	00023997          	auipc	s3,0x23
    800066ba:	94a98993          	addi	s3,s3,-1718 # 80029000 <disk+0x2000>
    800066be:	00491713          	slli	a4,s2,0x4
    800066c2:	0009b783          	ld	a5,0(s3)
    800066c6:	97ba                	add	a5,a5,a4
    800066c8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066cc:	854a                	mv	a0,s2
    800066ce:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066d2:	00000097          	auipc	ra,0x0
    800066d6:	bc4080e7          	jalr	-1084(ra) # 80006296 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066da:	8885                	andi	s1,s1,1
    800066dc:	f0ed                	bnez	s1,800066be <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066de:	00023517          	auipc	a0,0x23
    800066e2:	a4a50513          	addi	a0,a0,-1462 # 80029128 <disk+0x2128>
    800066e6:	ffffa097          	auipc	ra,0xffffa
    800066ea:	758080e7          	jalr	1880(ra) # 80000e3e <release>
}
    800066ee:	70a6                	ld	ra,104(sp)
    800066f0:	7406                	ld	s0,96(sp)
    800066f2:	64e6                	ld	s1,88(sp)
    800066f4:	6946                	ld	s2,80(sp)
    800066f6:	69a6                	ld	s3,72(sp)
    800066f8:	6a06                	ld	s4,64(sp)
    800066fa:	7ae2                	ld	s5,56(sp)
    800066fc:	7b42                	ld	s6,48(sp)
    800066fe:	7ba2                	ld	s7,40(sp)
    80006700:	7c02                	ld	s8,32(sp)
    80006702:	6ce2                	ld	s9,24(sp)
    80006704:	6d42                	ld	s10,16(sp)
    80006706:	6165                	addi	sp,sp,112
    80006708:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000670a:	00023697          	auipc	a3,0x23
    8000670e:	8f66b683          	ld	a3,-1802(a3) # 80029000 <disk+0x2000>
    80006712:	96ba                	add	a3,a3,a4
    80006714:	4609                	li	a2,2
    80006716:	00c69623          	sh	a2,12(a3)
    8000671a:	b5c9                	j	800065dc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000671c:	f9042583          	lw	a1,-112(s0)
    80006720:	20058793          	addi	a5,a1,512
    80006724:	0792                	slli	a5,a5,0x4
    80006726:	00021517          	auipc	a0,0x21
    8000672a:	98250513          	addi	a0,a0,-1662 # 800270a8 <disk+0xa8>
    8000672e:	953e                	add	a0,a0,a5
  if(write)
    80006730:	e20d11e3          	bnez	s10,80006552 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006734:	20058713          	addi	a4,a1,512
    80006738:	00471693          	slli	a3,a4,0x4
    8000673c:	00021717          	auipc	a4,0x21
    80006740:	8c470713          	addi	a4,a4,-1852 # 80027000 <disk>
    80006744:	9736                	add	a4,a4,a3
    80006746:	0a072423          	sw	zero,168(a4)
    8000674a:	b505                	j	8000656a <virtio_disk_rw+0xf4>

000000008000674c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000674c:	1101                	addi	sp,sp,-32
    8000674e:	ec06                	sd	ra,24(sp)
    80006750:	e822                	sd	s0,16(sp)
    80006752:	e426                	sd	s1,8(sp)
    80006754:	e04a                	sd	s2,0(sp)
    80006756:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006758:	00023517          	auipc	a0,0x23
    8000675c:	9d050513          	addi	a0,a0,-1584 # 80029128 <disk+0x2128>
    80006760:	ffffa097          	auipc	ra,0xffffa
    80006764:	60e080e7          	jalr	1550(ra) # 80000d6e <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006768:	10001737          	lui	a4,0x10001
    8000676c:	533c                	lw	a5,96(a4)
    8000676e:	8b8d                	andi	a5,a5,3
    80006770:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006772:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006776:	00023797          	auipc	a5,0x23
    8000677a:	88a78793          	addi	a5,a5,-1910 # 80029000 <disk+0x2000>
    8000677e:	6b94                	ld	a3,16(a5)
    80006780:	0207d703          	lhu	a4,32(a5)
    80006784:	0026d783          	lhu	a5,2(a3)
    80006788:	06f70163          	beq	a4,a5,800067ea <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000678c:	00021917          	auipc	s2,0x21
    80006790:	87490913          	addi	s2,s2,-1932 # 80027000 <disk>
    80006794:	00023497          	auipc	s1,0x23
    80006798:	86c48493          	addi	s1,s1,-1940 # 80029000 <disk+0x2000>
    __sync_synchronize();
    8000679c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067a0:	6898                	ld	a4,16(s1)
    800067a2:	0204d783          	lhu	a5,32(s1)
    800067a6:	8b9d                	andi	a5,a5,7
    800067a8:	078e                	slli	a5,a5,0x3
    800067aa:	97ba                	add	a5,a5,a4
    800067ac:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800067ae:	20078713          	addi	a4,a5,512
    800067b2:	0712                	slli	a4,a4,0x4
    800067b4:	974a                	add	a4,a4,s2
    800067b6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800067ba:	e731                	bnez	a4,80006806 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800067bc:	20078793          	addi	a5,a5,512
    800067c0:	0792                	slli	a5,a5,0x4
    800067c2:	97ca                	add	a5,a5,s2
    800067c4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800067c6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800067ca:	ffffc097          	auipc	ra,0xffffc
    800067ce:	f82080e7          	jalr	-126(ra) # 8000274c <wakeup>

    disk.used_idx += 1;
    800067d2:	0204d783          	lhu	a5,32(s1)
    800067d6:	2785                	addiw	a5,a5,1
    800067d8:	17c2                	slli	a5,a5,0x30
    800067da:	93c1                	srli	a5,a5,0x30
    800067dc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800067e0:	6898                	ld	a4,16(s1)
    800067e2:	00275703          	lhu	a4,2(a4)
    800067e6:	faf71be3          	bne	a4,a5,8000679c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800067ea:	00023517          	auipc	a0,0x23
    800067ee:	93e50513          	addi	a0,a0,-1730 # 80029128 <disk+0x2128>
    800067f2:	ffffa097          	auipc	ra,0xffffa
    800067f6:	64c080e7          	jalr	1612(ra) # 80000e3e <release>
}
    800067fa:	60e2                	ld	ra,24(sp)
    800067fc:	6442                	ld	s0,16(sp)
    800067fe:	64a2                	ld	s1,8(sp)
    80006800:	6902                	ld	s2,0(sp)
    80006802:	6105                	addi	sp,sp,32
    80006804:	8082                	ret
      panic("virtio_disk_intr status");
    80006806:	00002517          	auipc	a0,0x2
    8000680a:	09250513          	addi	a0,a0,146 # 80008898 <syscalls+0x3d8>
    8000680e:	ffffa097          	auipc	ra,0xffffa
    80006812:	d42080e7          	jalr	-702(ra) # 80000550 <panic>

0000000080006816 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006816:	1141                	addi	sp,sp,-16
    80006818:	e422                	sd	s0,8(sp)
    8000681a:	0800                	addi	s0,sp,16
  return -1;
}
    8000681c:	557d                	li	a0,-1
    8000681e:	6422                	ld	s0,8(sp)
    80006820:	0141                	addi	sp,sp,16
    80006822:	8082                	ret

0000000080006824 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006824:	7179                	addi	sp,sp,-48
    80006826:	f406                	sd	ra,40(sp)
    80006828:	f022                	sd	s0,32(sp)
    8000682a:	ec26                	sd	s1,24(sp)
    8000682c:	e84a                	sd	s2,16(sp)
    8000682e:	e44e                	sd	s3,8(sp)
    80006830:	e052                	sd	s4,0(sp)
    80006832:	1800                	addi	s0,sp,48
    80006834:	892a                	mv	s2,a0
    80006836:	89ae                	mv	s3,a1
    80006838:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    8000683a:	00023517          	auipc	a0,0x23
    8000683e:	7c650513          	addi	a0,a0,1990 # 8002a000 <stats>
    80006842:	ffffa097          	auipc	ra,0xffffa
    80006846:	52c080e7          	jalr	1324(ra) # 80000d6e <acquire>

  if(stats.sz == 0) {
    8000684a:	00024797          	auipc	a5,0x24
    8000684e:	7d67a783          	lw	a5,2006(a5) # 8002b020 <stats+0x1020>
    80006852:	cbb5                	beqz	a5,800068c6 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006854:	00024797          	auipc	a5,0x24
    80006858:	7ac78793          	addi	a5,a5,1964 # 8002b000 <stats+0x1000>
    8000685c:	53d8                	lw	a4,36(a5)
    8000685e:	539c                	lw	a5,32(a5)
    80006860:	9f99                	subw	a5,a5,a4
    80006862:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006866:	06d05e63          	blez	a3,800068e2 <statsread+0xbe>
    if(m > n)
    8000686a:	8a3e                	mv	s4,a5
    8000686c:	00d4d363          	bge	s1,a3,80006872 <statsread+0x4e>
    80006870:	8a26                	mv	s4,s1
    80006872:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006876:	86a6                	mv	a3,s1
    80006878:	00023617          	auipc	a2,0x23
    8000687c:	7a860613          	addi	a2,a2,1960 # 8002a020 <stats+0x20>
    80006880:	963a                	add	a2,a2,a4
    80006882:	85ce                	mv	a1,s3
    80006884:	854a                	mv	a0,s2
    80006886:	ffffc097          	auipc	ra,0xffffc
    8000688a:	fa2080e7          	jalr	-94(ra) # 80002828 <either_copyout>
    8000688e:	57fd                	li	a5,-1
    80006890:	00f50a63          	beq	a0,a5,800068a4 <statsread+0x80>
      stats.off += m;
    80006894:	00024717          	auipc	a4,0x24
    80006898:	76c70713          	addi	a4,a4,1900 # 8002b000 <stats+0x1000>
    8000689c:	535c                	lw	a5,36(a4)
    8000689e:	014787bb          	addw	a5,a5,s4
    800068a2:	d35c                	sw	a5,36(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    800068a4:	00023517          	auipc	a0,0x23
    800068a8:	75c50513          	addi	a0,a0,1884 # 8002a000 <stats>
    800068ac:	ffffa097          	auipc	ra,0xffffa
    800068b0:	592080e7          	jalr	1426(ra) # 80000e3e <release>
  return m;
}
    800068b4:	8526                	mv	a0,s1
    800068b6:	70a2                	ld	ra,40(sp)
    800068b8:	7402                	ld	s0,32(sp)
    800068ba:	64e2                	ld	s1,24(sp)
    800068bc:	6942                	ld	s2,16(sp)
    800068be:	69a2                	ld	s3,8(sp)
    800068c0:	6a02                	ld	s4,0(sp)
    800068c2:	6145                	addi	sp,sp,48
    800068c4:	8082                	ret
    stats.sz = statslock(stats.buf, BUFSZ);
    800068c6:	6585                	lui	a1,0x1
    800068c8:	00023517          	auipc	a0,0x23
    800068cc:	75850513          	addi	a0,a0,1880 # 8002a020 <stats+0x20>
    800068d0:	ffffa097          	auipc	ra,0xffffa
    800068d4:	6c8080e7          	jalr	1736(ra) # 80000f98 <statslock>
    800068d8:	00024797          	auipc	a5,0x24
    800068dc:	74a7a423          	sw	a0,1864(a5) # 8002b020 <stats+0x1020>
    800068e0:	bf95                	j	80006854 <statsread+0x30>
    stats.sz = 0;
    800068e2:	00024797          	auipc	a5,0x24
    800068e6:	71e78793          	addi	a5,a5,1822 # 8002b000 <stats+0x1000>
    800068ea:	0207a023          	sw	zero,32(a5)
    stats.off = 0;
    800068ee:	0207a223          	sw	zero,36(a5)
    m = -1;
    800068f2:	54fd                	li	s1,-1
    800068f4:	bf45                	j	800068a4 <statsread+0x80>

00000000800068f6 <statsinit>:

void
statsinit(void)
{
    800068f6:	1141                	addi	sp,sp,-16
    800068f8:	e406                	sd	ra,8(sp)
    800068fa:	e022                	sd	s0,0(sp)
    800068fc:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    800068fe:	00002597          	auipc	a1,0x2
    80006902:	fb258593          	addi	a1,a1,-78 # 800088b0 <syscalls+0x3f0>
    80006906:	00023517          	auipc	a0,0x23
    8000690a:	6fa50513          	addi	a0,a0,1786 # 8002a000 <stats>
    8000690e:	ffffa097          	auipc	ra,0xffffa
    80006912:	5dc080e7          	jalr	1500(ra) # 80000eea <initlock>

  devsw[STATS].read = statsread;
    80006916:	0001f797          	auipc	a5,0x1f
    8000691a:	48a78793          	addi	a5,a5,1162 # 80025da0 <devsw>
    8000691e:	00000717          	auipc	a4,0x0
    80006922:	f0670713          	addi	a4,a4,-250 # 80006824 <statsread>
    80006926:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006928:	00000717          	auipc	a4,0x0
    8000692c:	eee70713          	addi	a4,a4,-274 # 80006816 <statswrite>
    80006930:	f798                	sd	a4,40(a5)
}
    80006932:	60a2                	ld	ra,8(sp)
    80006934:	6402                	ld	s0,0(sp)
    80006936:	0141                	addi	sp,sp,16
    80006938:	8082                	ret

000000008000693a <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    8000693a:	1101                	addi	sp,sp,-32
    8000693c:	ec22                	sd	s0,24(sp)
    8000693e:	1000                	addi	s0,sp,32
    80006940:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    80006942:	c299                	beqz	a3,80006948 <sprintint+0xe>
    80006944:	0805c163          	bltz	a1,800069c6 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006948:	2581                	sext.w	a1,a1
    8000694a:	4301                	li	t1,0

  i = 0;
    8000694c:	fe040713          	addi	a4,s0,-32
    80006950:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    80006952:	2601                	sext.w	a2,a2
    80006954:	00002697          	auipc	a3,0x2
    80006958:	f6468693          	addi	a3,a3,-156 # 800088b8 <digits>
    8000695c:	88aa                	mv	a7,a0
    8000695e:	2505                	addiw	a0,a0,1
    80006960:	02c5f7bb          	remuw	a5,a1,a2
    80006964:	1782                	slli	a5,a5,0x20
    80006966:	9381                	srli	a5,a5,0x20
    80006968:	97b6                	add	a5,a5,a3
    8000696a:	0007c783          	lbu	a5,0(a5)
    8000696e:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    80006972:	0005879b          	sext.w	a5,a1
    80006976:	02c5d5bb          	divuw	a1,a1,a2
    8000697a:	0705                	addi	a4,a4,1
    8000697c:	fec7f0e3          	bgeu	a5,a2,8000695c <sprintint+0x22>

  if(sign)
    80006980:	00030b63          	beqz	t1,80006996 <sprintint+0x5c>
    buf[i++] = '-';
    80006984:	ff040793          	addi	a5,s0,-16
    80006988:	97aa                	add	a5,a5,a0
    8000698a:	02d00713          	li	a4,45
    8000698e:	fee78823          	sb	a4,-16(a5)
    80006992:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006996:	02a05c63          	blez	a0,800069ce <sprintint+0x94>
    8000699a:	fe040793          	addi	a5,s0,-32
    8000699e:	00a78733          	add	a4,a5,a0
    800069a2:	87c2                	mv	a5,a6
    800069a4:	0805                	addi	a6,a6,1
    800069a6:	fff5061b          	addiw	a2,a0,-1
    800069aa:	1602                	slli	a2,a2,0x20
    800069ac:	9201                	srli	a2,a2,0x20
    800069ae:	9642                	add	a2,a2,a6
  *s = c;
    800069b0:	fff74683          	lbu	a3,-1(a4)
    800069b4:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    800069b8:	177d                	addi	a4,a4,-1
    800069ba:	0785                	addi	a5,a5,1
    800069bc:	fec79ae3          	bne	a5,a2,800069b0 <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    800069c0:	6462                	ld	s0,24(sp)
    800069c2:	6105                	addi	sp,sp,32
    800069c4:	8082                	ret
    x = -xx;
    800069c6:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    800069ca:	4305                	li	t1,1
    x = -xx;
    800069cc:	b741                	j	8000694c <sprintint+0x12>
  while(--i >= 0)
    800069ce:	4501                	li	a0,0
    800069d0:	bfc5                	j	800069c0 <sprintint+0x86>

00000000800069d2 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    800069d2:	7171                	addi	sp,sp,-176
    800069d4:	fc86                	sd	ra,120(sp)
    800069d6:	f8a2                	sd	s0,112(sp)
    800069d8:	f4a6                	sd	s1,104(sp)
    800069da:	f0ca                	sd	s2,96(sp)
    800069dc:	ecce                	sd	s3,88(sp)
    800069de:	e8d2                	sd	s4,80(sp)
    800069e0:	e4d6                	sd	s5,72(sp)
    800069e2:	e0da                	sd	s6,64(sp)
    800069e4:	fc5e                	sd	s7,56(sp)
    800069e6:	f862                	sd	s8,48(sp)
    800069e8:	f466                	sd	s9,40(sp)
    800069ea:	f06a                	sd	s10,32(sp)
    800069ec:	ec6e                	sd	s11,24(sp)
    800069ee:	0100                	addi	s0,sp,128
    800069f0:	e414                	sd	a3,8(s0)
    800069f2:	e818                	sd	a4,16(s0)
    800069f4:	ec1c                	sd	a5,24(s0)
    800069f6:	03043023          	sd	a6,32(s0)
    800069fa:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    800069fe:	ca0d                	beqz	a2,80006a30 <snprintf+0x5e>
    80006a00:	8baa                	mv	s7,a0
    80006a02:	89ae                	mv	s3,a1
    80006a04:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006a06:	00840793          	addi	a5,s0,8
    80006a0a:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    80006a0e:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006a10:	4901                	li	s2,0
    80006a12:	02b05763          	blez	a1,80006a40 <snprintf+0x6e>
    if(c != '%'){
    80006a16:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006a1a:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    80006a1e:	02800d93          	li	s11,40
  *s = c;
    80006a22:	02500d13          	li	s10,37
    switch(c){
    80006a26:	07800c93          	li	s9,120
    80006a2a:	06400c13          	li	s8,100
    80006a2e:	a01d                	j	80006a54 <snprintf+0x82>
    panic("null fmt");
    80006a30:	00001517          	auipc	a0,0x1
    80006a34:	5f850513          	addi	a0,a0,1528 # 80008028 <etext+0x28>
    80006a38:	ffffa097          	auipc	ra,0xffffa
    80006a3c:	b18080e7          	jalr	-1256(ra) # 80000550 <panic>
  int off = 0;
    80006a40:	4481                	li	s1,0
    80006a42:	a86d                	j	80006afc <snprintf+0x12a>
  *s = c;
    80006a44:	009b8733          	add	a4,s7,s1
    80006a48:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006a4c:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006a4e:	2905                	addiw	s2,s2,1
    80006a50:	0b34d663          	bge	s1,s3,80006afc <snprintf+0x12a>
    80006a54:	012a07b3          	add	a5,s4,s2
    80006a58:	0007c783          	lbu	a5,0(a5)
    80006a5c:	0007871b          	sext.w	a4,a5
    80006a60:	cfd1                	beqz	a5,80006afc <snprintf+0x12a>
    if(c != '%'){
    80006a62:	ff5711e3          	bne	a4,s5,80006a44 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    80006a66:	2905                	addiw	s2,s2,1
    80006a68:	012a07b3          	add	a5,s4,s2
    80006a6c:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    80006a70:	c7d1                	beqz	a5,80006afc <snprintf+0x12a>
    switch(c){
    80006a72:	05678c63          	beq	a5,s6,80006aca <snprintf+0xf8>
    80006a76:	02fb6763          	bltu	s6,a5,80006aa4 <snprintf+0xd2>
    80006a7a:	0b578763          	beq	a5,s5,80006b28 <snprintf+0x156>
    80006a7e:	0b879b63          	bne	a5,s8,80006b34 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    80006a82:	f8843783          	ld	a5,-120(s0)
    80006a86:	00878713          	addi	a4,a5,8
    80006a8a:	f8e43423          	sd	a4,-120(s0)
    80006a8e:	4685                	li	a3,1
    80006a90:	4629                	li	a2,10
    80006a92:	438c                	lw	a1,0(a5)
    80006a94:	009b8533          	add	a0,s7,s1
    80006a98:	00000097          	auipc	ra,0x0
    80006a9c:	ea2080e7          	jalr	-350(ra) # 8000693a <sprintint>
    80006aa0:	9ca9                	addw	s1,s1,a0
      break;
    80006aa2:	b775                	j	80006a4e <snprintf+0x7c>
    switch(c){
    80006aa4:	09979863          	bne	a5,s9,80006b34 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006aa8:	f8843783          	ld	a5,-120(s0)
    80006aac:	00878713          	addi	a4,a5,8
    80006ab0:	f8e43423          	sd	a4,-120(s0)
    80006ab4:	4685                	li	a3,1
    80006ab6:	4641                	li	a2,16
    80006ab8:	438c                	lw	a1,0(a5)
    80006aba:	009b8533          	add	a0,s7,s1
    80006abe:	00000097          	auipc	ra,0x0
    80006ac2:	e7c080e7          	jalr	-388(ra) # 8000693a <sprintint>
    80006ac6:	9ca9                	addw	s1,s1,a0
      break;
    80006ac8:	b759                	j	80006a4e <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006aca:	f8843783          	ld	a5,-120(s0)
    80006ace:	00878713          	addi	a4,a5,8
    80006ad2:	f8e43423          	sd	a4,-120(s0)
    80006ad6:	639c                	ld	a5,0(a5)
    80006ad8:	c3b1                	beqz	a5,80006b1c <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006ada:	0007c703          	lbu	a4,0(a5)
    80006ade:	db25                	beqz	a4,80006a4e <snprintf+0x7c>
    80006ae0:	0134de63          	bge	s1,s3,80006afc <snprintf+0x12a>
    80006ae4:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006ae8:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006aec:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006aee:	0785                	addi	a5,a5,1
    80006af0:	0007c703          	lbu	a4,0(a5)
    80006af4:	df29                	beqz	a4,80006a4e <snprintf+0x7c>
    80006af6:	0685                	addi	a3,a3,1
    80006af8:	fe9998e3          	bne	s3,s1,80006ae8 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006afc:	8526                	mv	a0,s1
    80006afe:	70e6                	ld	ra,120(sp)
    80006b00:	7446                	ld	s0,112(sp)
    80006b02:	74a6                	ld	s1,104(sp)
    80006b04:	7906                	ld	s2,96(sp)
    80006b06:	69e6                	ld	s3,88(sp)
    80006b08:	6a46                	ld	s4,80(sp)
    80006b0a:	6aa6                	ld	s5,72(sp)
    80006b0c:	6b06                	ld	s6,64(sp)
    80006b0e:	7be2                	ld	s7,56(sp)
    80006b10:	7c42                	ld	s8,48(sp)
    80006b12:	7ca2                	ld	s9,40(sp)
    80006b14:	7d02                	ld	s10,32(sp)
    80006b16:	6de2                	ld	s11,24(sp)
    80006b18:	614d                	addi	sp,sp,176
    80006b1a:	8082                	ret
        s = "(null)";
    80006b1c:	00001797          	auipc	a5,0x1
    80006b20:	50478793          	addi	a5,a5,1284 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    80006b24:	876e                	mv	a4,s11
    80006b26:	bf6d                	j	80006ae0 <snprintf+0x10e>
  *s = c;
    80006b28:	009b87b3          	add	a5,s7,s1
    80006b2c:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    80006b30:	2485                	addiw	s1,s1,1
      break;
    80006b32:	bf31                	j	80006a4e <snprintf+0x7c>
  *s = c;
    80006b34:	009b8733          	add	a4,s7,s1
    80006b38:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006b3c:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006b40:	975e                	add	a4,a4,s7
    80006b42:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006b46:	2489                	addiw	s1,s1,2
      break;
    80006b48:	b719                	j	80006a4e <snprintf+0x7c>
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
