
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 70 11 00       	mov    $0x117000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 70 11 f0       	mov    $0xf0117000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 a0 17 10 f0 	movl   $0xf01017a0,(%esp)
f0100055:	e8 84 08 00 00       	call   f01008de <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 d1 06 00 00       	call   f0100758 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 bc 17 10 f0 	movl   $0xf01017bc,(%esp)
f0100092:	e8 47 08 00 00       	call   f01008de <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 40 99 11 f0       	mov    $0xf0119940,%eax
f01000a8:	2d 00 93 11 f0       	sub    $0xf0119300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 93 11 f0 	movl   $0xf0119300,(%esp)
f01000c0:	e8 85 12 00 00       	call   f010134a <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 77 04 00 00       	call   f0100541 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 d7 17 10 f0 	movl   $0xf01017d7,(%esp)
f01000d9:	e8 00 08 00 00       	call   f01008de <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 6c 06 00 00       	call   f0100762 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 44 99 11 f0 00 	cmpl   $0x0,0xf0119944
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 44 99 11 f0    	mov    %esi,0xf0119944

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 f2 17 10 f0 	movl   $0xf01017f2,(%esp)
f010012c:	e8 ad 07 00 00       	call   f01008de <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 6e 07 00 00       	call   f01008ab <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 2e 18 10 f0 	movl   $0xf010182e,(%esp)
f0100144:	e8 95 07 00 00       	call   f01008de <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 0d 06 00 00       	call   f0100762 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 0a 18 10 f0 	movl   $0xf010180a,(%esp)
f0100176:	e8 63 07 00 00       	call   f01008de <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 21 07 00 00       	call   f01008ab <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 2e 18 10 f0 	movl   $0xf010182e,(%esp)
f0100191:	e8 48 07 00 00       	call   f01008de <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    

f010019c <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f010019c:	55                   	push   %ebp
f010019d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010019f:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a4:	ec                   	in     (%dx),%al
f01001a5:	ec                   	in     (%dx),%al
f01001a6:	ec                   	in     (%dx),%al
f01001a7:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001a8:	5d                   	pop    %ebp
f01001a9:	c3                   	ret    

f01001aa <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001aa:	55                   	push   %ebp
f01001ab:	89 e5                	mov    %esp,%ebp
f01001ad:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b2:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b3:	a8 01                	test   $0x1,%al
f01001b5:	74 08                	je     f01001bf <serial_proc_data+0x15>
f01001b7:	b2 f8                	mov    $0xf8,%dl
f01001b9:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001ba:	0f b6 c0             	movzbl %al,%eax
f01001bd:	eb 05                	jmp    f01001c4 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001c4:	5d                   	pop    %ebp
f01001c5:	c3                   	ret    

f01001c6 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001c6:	55                   	push   %ebp
f01001c7:	89 e5                	mov    %esp,%ebp
f01001c9:	53                   	push   %ebx
f01001ca:	83 ec 04             	sub    $0x4,%esp
f01001cd:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001cf:	eb 29                	jmp    f01001fa <cons_intr+0x34>
		if (c == 0)
f01001d1:	85 c0                	test   %eax,%eax
f01001d3:	74 25                	je     f01001fa <cons_intr+0x34>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d5:	8b 15 24 95 11 f0    	mov    0xf0119524,%edx
f01001db:	88 82 20 93 11 f0    	mov    %al,-0xfee6ce0(%edx)
f01001e1:	8d 42 01             	lea    0x1(%edx),%eax
f01001e4:	a3 24 95 11 f0       	mov    %eax,0xf0119524
		if (cons.wpos == CONSBUFSIZE)
f01001e9:	3d 00 02 00 00       	cmp    $0x200,%eax
f01001ee:	75 0a                	jne    f01001fa <cons_intr+0x34>
			cons.wpos = 0;
f01001f0:	c7 05 24 95 11 f0 00 	movl   $0x0,0xf0119524
f01001f7:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fa:	ff d3                	call   *%ebx
f01001fc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001ff:	75 d0                	jne    f01001d1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100201:	83 c4 04             	add    $0x4,%esp
f0100204:	5b                   	pop    %ebx
f0100205:	5d                   	pop    %ebp
f0100206:	c3                   	ret    

f0100207 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100207:	55                   	push   %ebp
f0100208:	89 e5                	mov    %esp,%ebp
f010020a:	57                   	push   %edi
f010020b:	56                   	push   %esi
f010020c:	53                   	push   %ebx
f010020d:	83 ec 2c             	sub    $0x2c,%esp
f0100210:	89 c6                	mov    %eax,%esi
f0100212:	bb 01 32 00 00       	mov    $0x3201,%ebx
f0100217:	bf fd 03 00 00       	mov    $0x3fd,%edi
f010021c:	eb 05                	jmp    f0100223 <cons_putc+0x1c>
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f010021e:	e8 79 ff ff ff       	call   f010019c <delay>
f0100223:	89 fa                	mov    %edi,%edx
f0100225:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100226:	a8 20                	test   $0x20,%al
f0100228:	75 03                	jne    f010022d <cons_putc+0x26>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010022a:	4b                   	dec    %ebx
f010022b:	75 f1                	jne    f010021e <cons_putc+0x17>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f010022d:	89 f2                	mov    %esi,%edx
f010022f:	89 f0                	mov    %esi,%eax
f0100231:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100234:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100239:	ee                   	out    %al,(%dx)
f010023a:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010023f:	bf 79 03 00 00       	mov    $0x379,%edi
f0100244:	eb 05                	jmp    f010024b <cons_putc+0x44>
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
		delay();
f0100246:	e8 51 ff ff ff       	call   f010019c <delay>
f010024b:	89 fa                	mov    %edi,%edx
f010024d:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010024e:	84 c0                	test   %al,%al
f0100250:	78 03                	js     f0100255 <cons_putc+0x4e>
f0100252:	4b                   	dec    %ebx
f0100253:	75 f1                	jne    f0100246 <cons_putc+0x3f>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100255:	ba 78 03 00 00       	mov    $0x378,%edx
f010025a:	8a 45 e7             	mov    -0x19(%ebp),%al
f010025d:	ee                   	out    %al,(%dx)
f010025e:	b2 7a                	mov    $0x7a,%dl
f0100260:	b0 0d                	mov    $0xd,%al
f0100262:	ee                   	out    %al,(%dx)
f0100263:	b0 08                	mov    $0x8,%al
f0100265:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100266:	f7 c6 00 ff ff ff    	test   $0xffffff00,%esi
f010026c:	75 06                	jne    f0100274 <cons_putc+0x6d>
		c |= 0x0700;
f010026e:	81 ce 00 07 00 00    	or     $0x700,%esi

	switch (c & 0xff) {
f0100274:	89 f0                	mov    %esi,%eax
f0100276:	25 ff 00 00 00       	and    $0xff,%eax
f010027b:	83 f8 09             	cmp    $0x9,%eax
f010027e:	74 78                	je     f01002f8 <cons_putc+0xf1>
f0100280:	83 f8 09             	cmp    $0x9,%eax
f0100283:	7f 0b                	jg     f0100290 <cons_putc+0x89>
f0100285:	83 f8 08             	cmp    $0x8,%eax
f0100288:	0f 85 9e 00 00 00    	jne    f010032c <cons_putc+0x125>
f010028e:	eb 10                	jmp    f01002a0 <cons_putc+0x99>
f0100290:	83 f8 0a             	cmp    $0xa,%eax
f0100293:	74 39                	je     f01002ce <cons_putc+0xc7>
f0100295:	83 f8 0d             	cmp    $0xd,%eax
f0100298:	0f 85 8e 00 00 00    	jne    f010032c <cons_putc+0x125>
f010029e:	eb 36                	jmp    f01002d6 <cons_putc+0xcf>
	case '\b':
		if (crt_pos > 0) {
f01002a0:	66 a1 34 95 11 f0    	mov    0xf0119534,%ax
f01002a6:	66 85 c0             	test   %ax,%ax
f01002a9:	0f 84 e2 00 00 00    	je     f0100391 <cons_putc+0x18a>
			crt_pos--;
f01002af:	48                   	dec    %eax
f01002b0:	66 a3 34 95 11 f0    	mov    %ax,0xf0119534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002b6:	0f b7 c0             	movzwl %ax,%eax
f01002b9:	81 e6 00 ff ff ff    	and    $0xffffff00,%esi
f01002bf:	83 ce 20             	or     $0x20,%esi
f01002c2:	8b 15 30 95 11 f0    	mov    0xf0119530,%edx
f01002c8:	66 89 34 42          	mov    %si,(%edx,%eax,2)
f01002cc:	eb 78                	jmp    f0100346 <cons_putc+0x13f>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002ce:	66 83 05 34 95 11 f0 	addw   $0x50,0xf0119534
f01002d5:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002d6:	66 8b 0d 34 95 11 f0 	mov    0xf0119534,%cx
f01002dd:	bb 50 00 00 00       	mov    $0x50,%ebx
f01002e2:	89 c8                	mov    %ecx,%eax
f01002e4:	ba 00 00 00 00       	mov    $0x0,%edx
f01002e9:	66 f7 f3             	div    %bx
f01002ec:	66 29 d1             	sub    %dx,%cx
f01002ef:	66 89 0d 34 95 11 f0 	mov    %cx,0xf0119534
f01002f6:	eb 4e                	jmp    f0100346 <cons_putc+0x13f>
		break;
	case '\t':
		cons_putc(' ');
f01002f8:	b8 20 00 00 00       	mov    $0x20,%eax
f01002fd:	e8 05 ff ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100302:	b8 20 00 00 00       	mov    $0x20,%eax
f0100307:	e8 fb fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f010030c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100311:	e8 f1 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100316:	b8 20 00 00 00       	mov    $0x20,%eax
f010031b:	e8 e7 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100320:	b8 20 00 00 00       	mov    $0x20,%eax
f0100325:	e8 dd fe ff ff       	call   f0100207 <cons_putc>
f010032a:	eb 1a                	jmp    f0100346 <cons_putc+0x13f>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010032c:	66 a1 34 95 11 f0    	mov    0xf0119534,%ax
f0100332:	0f b7 c8             	movzwl %ax,%ecx
f0100335:	8b 15 30 95 11 f0    	mov    0xf0119530,%edx
f010033b:	66 89 34 4a          	mov    %si,(%edx,%ecx,2)
f010033f:	40                   	inc    %eax
f0100340:	66 a3 34 95 11 f0    	mov    %ax,0xf0119534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100346:	66 81 3d 34 95 11 f0 	cmpw   $0x7cf,0xf0119534
f010034d:	cf 07 
f010034f:	76 40                	jbe    f0100391 <cons_putc+0x18a>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100351:	a1 30 95 11 f0       	mov    0xf0119530,%eax
f0100356:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010035d:	00 
f010035e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100364:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100368:	89 04 24             	mov    %eax,(%esp)
f010036b:	e8 24 10 00 00       	call   f0101394 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100370:	8b 15 30 95 11 f0    	mov    0xf0119530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100376:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010037b:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100381:	40                   	inc    %eax
f0100382:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100387:	75 f2                	jne    f010037b <cons_putc+0x174>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100389:	66 83 2d 34 95 11 f0 	subw   $0x50,0xf0119534
f0100390:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100391:	8b 0d 2c 95 11 f0    	mov    0xf011952c,%ecx
f0100397:	b0 0e                	mov    $0xe,%al
f0100399:	89 ca                	mov    %ecx,%edx
f010039b:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010039c:	66 8b 35 34 95 11 f0 	mov    0xf0119534,%si
f01003a3:	8d 59 01             	lea    0x1(%ecx),%ebx
f01003a6:	89 f0                	mov    %esi,%eax
f01003a8:	66 c1 e8 08          	shr    $0x8,%ax
f01003ac:	89 da                	mov    %ebx,%edx
f01003ae:	ee                   	out    %al,(%dx)
f01003af:	b0 0f                	mov    $0xf,%al
f01003b1:	89 ca                	mov    %ecx,%edx
f01003b3:	ee                   	out    %al,(%dx)
f01003b4:	89 f0                	mov    %esi,%eax
f01003b6:	89 da                	mov    %ebx,%edx
f01003b8:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003b9:	83 c4 2c             	add    $0x2c,%esp
f01003bc:	5b                   	pop    %ebx
f01003bd:	5e                   	pop    %esi
f01003be:	5f                   	pop    %edi
f01003bf:	5d                   	pop    %ebp
f01003c0:	c3                   	ret    

f01003c1 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003c1:	55                   	push   %ebp
f01003c2:	89 e5                	mov    %esp,%ebp
f01003c4:	53                   	push   %ebx
f01003c5:	83 ec 14             	sub    $0x14,%esp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003c8:	ba 64 00 00 00       	mov    $0x64,%edx
f01003cd:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01003ce:	0f b6 c0             	movzbl %al,%eax
f01003d1:	a8 01                	test   $0x1,%al
f01003d3:	0f 84 e0 00 00 00    	je     f01004b9 <kbd_proc_data+0xf8>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01003d9:	a8 20                	test   $0x20,%al
f01003db:	0f 85 df 00 00 00    	jne    f01004c0 <kbd_proc_data+0xff>
f01003e1:	b2 60                	mov    $0x60,%dl
f01003e3:	ec                   	in     (%dx),%al
f01003e4:	88 c2                	mov    %al,%dl
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003e6:	3c e0                	cmp    $0xe0,%al
f01003e8:	75 11                	jne    f01003fb <kbd_proc_data+0x3a>
		// E0 escape character
		shift |= E0ESC;
f01003ea:	83 0d 28 95 11 f0 40 	orl    $0x40,0xf0119528
		return 0;
f01003f1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f6:	e9 ca 00 00 00       	jmp    f01004c5 <kbd_proc_data+0x104>
	} else if (data & 0x80) {
f01003fb:	84 c0                	test   %al,%al
f01003fd:	79 33                	jns    f0100432 <kbd_proc_data+0x71>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003ff:	8b 0d 28 95 11 f0    	mov    0xf0119528,%ecx
f0100405:	f6 c1 40             	test   $0x40,%cl
f0100408:	75 05                	jne    f010040f <kbd_proc_data+0x4e>
f010040a:	88 c2                	mov    %al,%dl
f010040c:	83 e2 7f             	and    $0x7f,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010040f:	0f b6 d2             	movzbl %dl,%edx
f0100412:	8a 82 60 18 10 f0    	mov    -0xfefe7a0(%edx),%al
f0100418:	83 c8 40             	or     $0x40,%eax
f010041b:	0f b6 c0             	movzbl %al,%eax
f010041e:	f7 d0                	not    %eax
f0100420:	21 c1                	and    %eax,%ecx
f0100422:	89 0d 28 95 11 f0    	mov    %ecx,0xf0119528
		return 0;
f0100428:	bb 00 00 00 00       	mov    $0x0,%ebx
f010042d:	e9 93 00 00 00       	jmp    f01004c5 <kbd_proc_data+0x104>
	} else if (shift & E0ESC) {
f0100432:	8b 0d 28 95 11 f0    	mov    0xf0119528,%ecx
f0100438:	f6 c1 40             	test   $0x40,%cl
f010043b:	74 0e                	je     f010044b <kbd_proc_data+0x8a>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010043d:	88 c2                	mov    %al,%dl
f010043f:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100442:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100445:	89 0d 28 95 11 f0    	mov    %ecx,0xf0119528
	}

	shift |= shiftcode[data];
f010044b:	0f b6 d2             	movzbl %dl,%edx
f010044e:	0f b6 82 60 18 10 f0 	movzbl -0xfefe7a0(%edx),%eax
f0100455:	0b 05 28 95 11 f0    	or     0xf0119528,%eax
	shift ^= togglecode[data];
f010045b:	0f b6 8a 60 19 10 f0 	movzbl -0xfefe6a0(%edx),%ecx
f0100462:	31 c8                	xor    %ecx,%eax
f0100464:	a3 28 95 11 f0       	mov    %eax,0xf0119528

	c = charcode[shift & (CTL | SHIFT)][data];
f0100469:	89 c1                	mov    %eax,%ecx
f010046b:	83 e1 03             	and    $0x3,%ecx
f010046e:	8b 0c 8d 60 1a 10 f0 	mov    -0xfefe5a0(,%ecx,4),%ecx
f0100475:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100479:	a8 08                	test   $0x8,%al
f010047b:	74 18                	je     f0100495 <kbd_proc_data+0xd4>
		if ('a' <= c && c <= 'z')
f010047d:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100480:	83 fa 19             	cmp    $0x19,%edx
f0100483:	77 05                	ja     f010048a <kbd_proc_data+0xc9>
			c += 'A' - 'a';
f0100485:	83 eb 20             	sub    $0x20,%ebx
f0100488:	eb 0b                	jmp    f0100495 <kbd_proc_data+0xd4>
		else if ('A' <= c && c <= 'Z')
f010048a:	8d 53 bf             	lea    -0x41(%ebx),%edx
f010048d:	83 fa 19             	cmp    $0x19,%edx
f0100490:	77 03                	ja     f0100495 <kbd_proc_data+0xd4>
			c += 'a' - 'A';
f0100492:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100495:	f7 d0                	not    %eax
f0100497:	a8 06                	test   $0x6,%al
f0100499:	75 2a                	jne    f01004c5 <kbd_proc_data+0x104>
f010049b:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004a1:	75 22                	jne    f01004c5 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01004a3:	c7 04 24 24 18 10 f0 	movl   $0xf0101824,(%esp)
f01004aa:	e8 2f 04 00 00       	call   f01008de <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004af:	ba 92 00 00 00       	mov    $0x92,%edx
f01004b4:	b0 03                	mov    $0x3,%al
f01004b6:	ee                   	out    %al,(%dx)
f01004b7:	eb 0c                	jmp    f01004c5 <kbd_proc_data+0x104>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01004b9:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01004be:	eb 05                	jmp    f01004c5 <kbd_proc_data+0x104>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01004c0:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004c5:	89 d8                	mov    %ebx,%eax
f01004c7:	83 c4 14             	add    $0x14,%esp
f01004ca:	5b                   	pop    %ebx
f01004cb:	5d                   	pop    %ebp
f01004cc:	c3                   	ret    

f01004cd <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004cd:	55                   	push   %ebp
f01004ce:	89 e5                	mov    %esp,%ebp
f01004d0:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f01004d3:	80 3d 00 93 11 f0 00 	cmpb   $0x0,0xf0119300
f01004da:	74 0a                	je     f01004e6 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f01004dc:	b8 aa 01 10 f0       	mov    $0xf01001aa,%eax
f01004e1:	e8 e0 fc ff ff       	call   f01001c6 <cons_intr>
}
f01004e6:	c9                   	leave  
f01004e7:	c3                   	ret    

f01004e8 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e8:	55                   	push   %ebp
f01004e9:	89 e5                	mov    %esp,%ebp
f01004eb:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ee:	b8 c1 03 10 f0       	mov    $0xf01003c1,%eax
f01004f3:	e8 ce fc ff ff       	call   f01001c6 <cons_intr>
}
f01004f8:	c9                   	leave  
f01004f9:	c3                   	ret    

f01004fa <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004fa:	55                   	push   %ebp
f01004fb:	89 e5                	mov    %esp,%ebp
f01004fd:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100500:	e8 c8 ff ff ff       	call   f01004cd <serial_intr>
	kbd_intr();
f0100505:	e8 de ff ff ff       	call   f01004e8 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010050a:	8b 15 20 95 11 f0    	mov    0xf0119520,%edx
f0100510:	3b 15 24 95 11 f0    	cmp    0xf0119524,%edx
f0100516:	74 22                	je     f010053a <cons_getc+0x40>
		c = cons.buf[cons.rpos++];
f0100518:	0f b6 82 20 93 11 f0 	movzbl -0xfee6ce0(%edx),%eax
f010051f:	42                   	inc    %edx
f0100520:	89 15 20 95 11 f0    	mov    %edx,0xf0119520
		if (cons.rpos == CONSBUFSIZE)
f0100526:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010052c:	75 11                	jne    f010053f <cons_getc+0x45>
			cons.rpos = 0;
f010052e:	c7 05 20 95 11 f0 00 	movl   $0x0,0xf0119520
f0100535:	00 00 00 
f0100538:	eb 05                	jmp    f010053f <cons_getc+0x45>
		return c;
	}
	return 0;
f010053a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010053f:	c9                   	leave  
f0100540:	c3                   	ret    

f0100541 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100541:	55                   	push   %ebp
f0100542:	89 e5                	mov    %esp,%ebp
f0100544:	57                   	push   %edi
f0100545:	56                   	push   %esi
f0100546:	53                   	push   %ebx
f0100547:	83 ec 2c             	sub    $0x2c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010054a:	66 8b 15 00 80 0b f0 	mov    0xf00b8000,%dx
	*cp = (uint16_t) 0xA55A;
f0100551:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100558:	5a a5 
	if (*cp != 0xA55A) {
f010055a:	66 a1 00 80 0b f0    	mov    0xf00b8000,%ax
f0100560:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100564:	74 11                	je     f0100577 <cons_init+0x36>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100566:	c7 05 2c 95 11 f0 b4 	movl   $0x3b4,0xf011952c
f010056d:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100570:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100575:	eb 16                	jmp    f010058d <cons_init+0x4c>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100577:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010057e:	c7 05 2c 95 11 f0 d4 	movl   $0x3d4,0xf011952c
f0100585:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100588:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010058d:	8b 0d 2c 95 11 f0    	mov    0xf011952c,%ecx
f0100593:	b0 0e                	mov    $0xe,%al
f0100595:	89 ca                	mov    %ecx,%edx
f0100597:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100598:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010059b:	89 da                	mov    %ebx,%edx
f010059d:	ec                   	in     (%dx),%al
f010059e:	0f b6 f8             	movzbl %al,%edi
f01005a1:	c1 e7 08             	shl    $0x8,%edi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005a4:	b0 0f                	mov    $0xf,%al
f01005a6:	89 ca                	mov    %ecx,%edx
f01005a8:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a9:	89 da                	mov    %ebx,%edx
f01005ab:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005ac:	89 35 30 95 11 f0    	mov    %esi,0xf0119530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005b2:	0f b6 d8             	movzbl %al,%ebx
f01005b5:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005b7:	66 89 3d 34 95 11 f0 	mov    %di,0xf0119534
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005be:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005c3:	b0 00                	mov    $0x0,%al
f01005c5:	89 da                	mov    %ebx,%edx
f01005c7:	ee                   	out    %al,(%dx)
f01005c8:	b2 fb                	mov    $0xfb,%dl
f01005ca:	b0 80                	mov    $0x80,%al
f01005cc:	ee                   	out    %al,(%dx)
f01005cd:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01005d2:	b0 0c                	mov    $0xc,%al
f01005d4:	89 ca                	mov    %ecx,%edx
f01005d6:	ee                   	out    %al,(%dx)
f01005d7:	b2 f9                	mov    $0xf9,%dl
f01005d9:	b0 00                	mov    $0x0,%al
f01005db:	ee                   	out    %al,(%dx)
f01005dc:	b2 fb                	mov    $0xfb,%dl
f01005de:	b0 03                	mov    $0x3,%al
f01005e0:	ee                   	out    %al,(%dx)
f01005e1:	b2 fc                	mov    $0xfc,%dl
f01005e3:	b0 00                	mov    $0x0,%al
f01005e5:	ee                   	out    %al,(%dx)
f01005e6:	b2 f9                	mov    $0xf9,%dl
f01005e8:	b0 01                	mov    $0x1,%al
f01005ea:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005eb:	b2 fd                	mov    $0xfd,%dl
f01005ed:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005ee:	3c ff                	cmp    $0xff,%al
f01005f0:	0f 95 45 e7          	setne  -0x19(%ebp)
f01005f4:	8a 45 e7             	mov    -0x19(%ebp),%al
f01005f7:	a2 00 93 11 f0       	mov    %al,0xf0119300
f01005fc:	89 da                	mov    %ebx,%edx
f01005fe:	ec                   	in     (%dx),%al
f01005ff:	89 ca                	mov    %ecx,%edx
f0100601:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100602:	80 7d e7 00          	cmpb   $0x0,-0x19(%ebp)
f0100606:	75 0c                	jne    f0100614 <cons_init+0xd3>
		cprintf("Serial port does not exist!\n");
f0100608:	c7 04 24 30 18 10 f0 	movl   $0xf0101830,(%esp)
f010060f:	e8 ca 02 00 00       	call   f01008de <cprintf>
}
f0100614:	83 c4 2c             	add    $0x2c,%esp
f0100617:	5b                   	pop    %ebx
f0100618:	5e                   	pop    %esi
f0100619:	5f                   	pop    %edi
f010061a:	5d                   	pop    %ebp
f010061b:	c3                   	ret    

f010061c <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010061c:	55                   	push   %ebp
f010061d:	89 e5                	mov    %esp,%ebp
f010061f:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100622:	8b 45 08             	mov    0x8(%ebp),%eax
f0100625:	e8 dd fb ff ff       	call   f0100207 <cons_putc>
}
f010062a:	c9                   	leave  
f010062b:	c3                   	ret    

f010062c <getchar>:

int
getchar(void)
{
f010062c:	55                   	push   %ebp
f010062d:	89 e5                	mov    %esp,%ebp
f010062f:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100632:	e8 c3 fe ff ff       	call   f01004fa <cons_getc>
f0100637:	85 c0                	test   %eax,%eax
f0100639:	74 f7                	je     f0100632 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010063b:	c9                   	leave  
f010063c:	c3                   	ret    

f010063d <iscons>:

int
iscons(int fdnum)
{
f010063d:	55                   	push   %ebp
f010063e:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100640:	b8 01 00 00 00       	mov    $0x1,%eax
f0100645:	5d                   	pop    %ebp
f0100646:	c3                   	ret    
	...

f0100648 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100648:	55                   	push   %ebp
f0100649:	89 e5                	mov    %esp,%ebp
f010064b:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010064e:	c7 04 24 70 1a 10 f0 	movl   $0xf0101a70,(%esp)
f0100655:	e8 84 02 00 00       	call   f01008de <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010065a:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100661:	00 
f0100662:	c7 04 24 fc 1a 10 f0 	movl   $0xf0101afc,(%esp)
f0100669:	e8 70 02 00 00       	call   f01008de <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010066e:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100675:	00 
f0100676:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f010067d:	f0 
f010067e:	c7 04 24 24 1b 10 f0 	movl   $0xf0101b24,(%esp)
f0100685:	e8 54 02 00 00       	call   f01008de <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010068a:	c7 44 24 08 8e 17 10 	movl   $0x10178e,0x8(%esp)
f0100691:	00 
f0100692:	c7 44 24 04 8e 17 10 	movl   $0xf010178e,0x4(%esp)
f0100699:	f0 
f010069a:	c7 04 24 48 1b 10 f0 	movl   $0xf0101b48,(%esp)
f01006a1:	e8 38 02 00 00       	call   f01008de <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006a6:	c7 44 24 08 00 93 11 	movl   $0x119300,0x8(%esp)
f01006ad:	00 
f01006ae:	c7 44 24 04 00 93 11 	movl   $0xf0119300,0x4(%esp)
f01006b5:	f0 
f01006b6:	c7 04 24 6c 1b 10 f0 	movl   $0xf0101b6c,(%esp)
f01006bd:	e8 1c 02 00 00       	call   f01008de <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006c2:	c7 44 24 08 40 99 11 	movl   $0x119940,0x8(%esp)
f01006c9:	00 
f01006ca:	c7 44 24 04 40 99 11 	movl   $0xf0119940,0x4(%esp)
f01006d1:	f0 
f01006d2:	c7 04 24 90 1b 10 f0 	movl   $0xf0101b90,(%esp)
f01006d9:	e8 00 02 00 00       	call   f01008de <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006de:	b8 3f 9d 11 f0       	mov    $0xf0119d3f,%eax
f01006e3:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01006e8:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006ed:	89 c2                	mov    %eax,%edx
f01006ef:	85 c0                	test   %eax,%eax
f01006f1:	79 06                	jns    f01006f9 <mon_kerninfo+0xb1>
f01006f3:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006f9:	c1 fa 0a             	sar    $0xa,%edx
f01006fc:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100700:	c7 04 24 b4 1b 10 f0 	movl   $0xf0101bb4,(%esp)
f0100707:	e8 d2 01 00 00       	call   f01008de <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010070c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100711:	c9                   	leave  
f0100712:	c3                   	ret    

f0100713 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100713:	55                   	push   %ebp
f0100714:	89 e5                	mov    %esp,%ebp
f0100716:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100719:	c7 44 24 08 89 1a 10 	movl   $0xf0101a89,0x8(%esp)
f0100720:	f0 
f0100721:	c7 44 24 04 a7 1a 10 	movl   $0xf0101aa7,0x4(%esp)
f0100728:	f0 
f0100729:	c7 04 24 ac 1a 10 f0 	movl   $0xf0101aac,(%esp)
f0100730:	e8 a9 01 00 00       	call   f01008de <cprintf>
f0100735:	c7 44 24 08 e0 1b 10 	movl   $0xf0101be0,0x8(%esp)
f010073c:	f0 
f010073d:	c7 44 24 04 b5 1a 10 	movl   $0xf0101ab5,0x4(%esp)
f0100744:	f0 
f0100745:	c7 04 24 ac 1a 10 f0 	movl   $0xf0101aac,(%esp)
f010074c:	e8 8d 01 00 00       	call   f01008de <cprintf>
	return 0;
}
f0100751:	b8 00 00 00 00       	mov    $0x0,%eax
f0100756:	c9                   	leave  
f0100757:	c3                   	ret    

f0100758 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100758:	55                   	push   %ebp
f0100759:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f010075b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100760:	5d                   	pop    %ebp
f0100761:	c3                   	ret    

f0100762 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100762:	55                   	push   %ebp
f0100763:	89 e5                	mov    %esp,%ebp
f0100765:	57                   	push   %edi
f0100766:	56                   	push   %esi
f0100767:	53                   	push   %ebx
f0100768:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010076b:	c7 04 24 08 1c 10 f0 	movl   $0xf0101c08,(%esp)
f0100772:	e8 67 01 00 00       	call   f01008de <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100777:	c7 04 24 2c 1c 10 f0 	movl   $0xf0101c2c,(%esp)
f010077e:	e8 5b 01 00 00       	call   f01008de <cprintf>
	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f0100783:	8d 7d a8             	lea    -0x58(%ebp),%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f0100786:	c7 04 24 be 1a 10 f0 	movl   $0xf0101abe,(%esp)
f010078d:	e8 8e 09 00 00       	call   f0101120 <readline>
f0100792:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100794:	85 c0                	test   %eax,%eax
f0100796:	74 ee                	je     f0100786 <monitor+0x24>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100798:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010079f:	be 00 00 00 00       	mov    $0x0,%esi
f01007a4:	eb 04                	jmp    f01007aa <monitor+0x48>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007a6:	c6 03 00             	movb   $0x0,(%ebx)
f01007a9:	43                   	inc    %ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007aa:	8a 03                	mov    (%ebx),%al
f01007ac:	84 c0                	test   %al,%al
f01007ae:	74 5e                	je     f010080e <monitor+0xac>
f01007b0:	0f be c0             	movsbl %al,%eax
f01007b3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b7:	c7 04 24 c2 1a 10 f0 	movl   $0xf0101ac2,(%esp)
f01007be:	e8 52 0b 00 00       	call   f0101315 <strchr>
f01007c3:	85 c0                	test   %eax,%eax
f01007c5:	75 df                	jne    f01007a6 <monitor+0x44>
			*buf++ = 0;
		if (*buf == 0)
f01007c7:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007ca:	74 42                	je     f010080e <monitor+0xac>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007cc:	83 fe 0f             	cmp    $0xf,%esi
f01007cf:	75 16                	jne    f01007e7 <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007d1:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01007d8:	00 
f01007d9:	c7 04 24 c7 1a 10 f0 	movl   $0xf0101ac7,(%esp)
f01007e0:	e8 f9 00 00 00       	call   f01008de <cprintf>
f01007e5:	eb 9f                	jmp    f0100786 <monitor+0x24>
			return 0;
		}
		argv[argc++] = buf;
f01007e7:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007eb:	46                   	inc    %esi
f01007ec:	eb 01                	jmp    f01007ef <monitor+0x8d>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01007ee:	43                   	inc    %ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007ef:	8a 03                	mov    (%ebx),%al
f01007f1:	84 c0                	test   %al,%al
f01007f3:	74 b5                	je     f01007aa <monitor+0x48>
f01007f5:	0f be c0             	movsbl %al,%eax
f01007f8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007fc:	c7 04 24 c2 1a 10 f0 	movl   $0xf0101ac2,(%esp)
f0100803:	e8 0d 0b 00 00       	call   f0101315 <strchr>
f0100808:	85 c0                	test   %eax,%eax
f010080a:	74 e2                	je     f01007ee <monitor+0x8c>
f010080c:	eb 9c                	jmp    f01007aa <monitor+0x48>
			buf++;
	}
	argv[argc] = 0;
f010080e:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100815:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100816:	85 f6                	test   %esi,%esi
f0100818:	0f 84 68 ff ff ff    	je     f0100786 <monitor+0x24>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010081e:	c7 44 24 04 a7 1a 10 	movl   $0xf0101aa7,0x4(%esp)
f0100825:	f0 
f0100826:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100829:	89 04 24             	mov    %eax,(%esp)
f010082c:	e8 91 0a 00 00       	call   f01012c2 <strcmp>
f0100831:	85 c0                	test   %eax,%eax
f0100833:	74 1b                	je     f0100850 <monitor+0xee>
f0100835:	c7 44 24 04 b5 1a 10 	movl   $0xf0101ab5,0x4(%esp)
f010083c:	f0 
f010083d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100840:	89 04 24             	mov    %eax,(%esp)
f0100843:	e8 7a 0a 00 00       	call   f01012c2 <strcmp>
f0100848:	85 c0                	test   %eax,%eax
f010084a:	75 2c                	jne    f0100878 <monitor+0x116>
f010084c:	b0 01                	mov    $0x1,%al
f010084e:	eb 05                	jmp    f0100855 <monitor+0xf3>
f0100850:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100855:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100858:	01 d0                	add    %edx,%eax
f010085a:	8b 55 08             	mov    0x8(%ebp),%edx
f010085d:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100861:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100865:	89 34 24             	mov    %esi,(%esp)
f0100868:	ff 14 85 5c 1c 10 f0 	call   *-0xfefe3a4(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010086f:	85 c0                	test   %eax,%eax
f0100871:	78 1d                	js     f0100890 <monitor+0x12e>
f0100873:	e9 0e ff ff ff       	jmp    f0100786 <monitor+0x24>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100878:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010087b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010087f:	c7 04 24 e4 1a 10 f0 	movl   $0xf0101ae4,(%esp)
f0100886:	e8 53 00 00 00       	call   f01008de <cprintf>
f010088b:	e9 f6 fe ff ff       	jmp    f0100786 <monitor+0x24>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100890:	83 c4 5c             	add    $0x5c,%esp
f0100893:	5b                   	pop    %ebx
f0100894:	5e                   	pop    %esi
f0100895:	5f                   	pop    %edi
f0100896:	5d                   	pop    %ebp
f0100897:	c3                   	ret    

f0100898 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100898:	55                   	push   %ebp
f0100899:	89 e5                	mov    %esp,%ebp
f010089b:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010089e:	8b 45 08             	mov    0x8(%ebp),%eax
f01008a1:	89 04 24             	mov    %eax,(%esp)
f01008a4:	e8 73 fd ff ff       	call   f010061c <cputchar>
	*cnt++;
}
f01008a9:	c9                   	leave  
f01008aa:	c3                   	ret    

f01008ab <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008ab:	55                   	push   %ebp
f01008ac:	89 e5                	mov    %esp,%ebp
f01008ae:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01008b1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01008b8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01008bb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01008bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01008c2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008c6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01008c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008cd:	c7 04 24 98 08 10 f0 	movl   $0xf0100898,(%esp)
f01008d4:	e8 11 04 00 00       	call   f0100cea <vprintfmt>
	return cnt;
}
f01008d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01008dc:	c9                   	leave  
f01008dd:	c3                   	ret    

f01008de <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01008de:	55                   	push   %ebp
f01008df:	89 e5                	mov    %esp,%ebp
f01008e1:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01008e4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01008e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01008ee:	89 04 24             	mov    %eax,(%esp)
f01008f1:	e8 b5 ff ff ff       	call   f01008ab <vcprintf>
	va_end(ap);

	return cnt;
}
f01008f6:	c9                   	leave  
f01008f7:	c3                   	ret    

f01008f8 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01008f8:	55                   	push   %ebp
f01008f9:	89 e5                	mov    %esp,%ebp
f01008fb:	57                   	push   %edi
f01008fc:	56                   	push   %esi
f01008fd:	53                   	push   %ebx
f01008fe:	83 ec 10             	sub    $0x10,%esp
f0100901:	89 c3                	mov    %eax,%ebx
f0100903:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100906:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100909:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f010090c:	8b 0a                	mov    (%edx),%ecx
f010090e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100911:	8b 00                	mov    (%eax),%eax
f0100913:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100916:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f010091d:	eb 77                	jmp    f0100996 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f010091f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100922:	01 c8                	add    %ecx,%eax
f0100924:	bf 02 00 00 00       	mov    $0x2,%edi
f0100929:	99                   	cltd   
f010092a:	f7 ff                	idiv   %edi
f010092c:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010092e:	eb 01                	jmp    f0100931 <stab_binsearch+0x39>
			m--;
f0100930:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100931:	39 ca                	cmp    %ecx,%edx
f0100933:	7c 1d                	jl     f0100952 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100935:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100938:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f010093d:	39 f7                	cmp    %esi,%edi
f010093f:	75 ef                	jne    f0100930 <stab_binsearch+0x38>
f0100941:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100944:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100947:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f010094b:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f010094e:	73 18                	jae    f0100968 <stab_binsearch+0x70>
f0100950:	eb 05                	jmp    f0100957 <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100952:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100955:	eb 3f                	jmp    f0100996 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100957:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f010095a:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f010095c:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010095f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100966:	eb 2e                	jmp    f0100996 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100968:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f010096b:	76 15                	jbe    f0100982 <stab_binsearch+0x8a>
			*region_right = m - 1;
f010096d:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100970:	4f                   	dec    %edi
f0100971:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100974:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100977:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100979:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100980:	eb 14                	jmp    f0100996 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100982:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100985:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100988:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f010098a:	ff 45 0c             	incl   0xc(%ebp)
f010098d:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010098f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100996:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100999:	7e 84                	jle    f010091f <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010099b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f010099f:	75 0d                	jne    f01009ae <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f01009a1:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009a4:	8b 02                	mov    (%edx),%eax
f01009a6:	48                   	dec    %eax
f01009a7:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009aa:	89 01                	mov    %eax,(%ecx)
f01009ac:	eb 22                	jmp    f01009d0 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009ae:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009b1:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f01009b3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009b6:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009b8:	eb 01                	jmp    f01009bb <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01009ba:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009bb:	39 c1                	cmp    %eax,%ecx
f01009bd:	7d 0c                	jge    f01009cb <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01009bf:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f01009c2:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f01009c7:	39 f2                	cmp    %esi,%edx
f01009c9:	75 ef                	jne    f01009ba <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f01009cb:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009ce:	89 02                	mov    %eax,(%edx)
	}
}
f01009d0:	83 c4 10             	add    $0x10,%esp
f01009d3:	5b                   	pop    %ebx
f01009d4:	5e                   	pop    %esi
f01009d5:	5f                   	pop    %edi
f01009d6:	5d                   	pop    %ebp
f01009d7:	c3                   	ret    

f01009d8 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01009d8:	55                   	push   %ebp
f01009d9:	89 e5                	mov    %esp,%ebp
f01009db:	57                   	push   %edi
f01009dc:	56                   	push   %esi
f01009dd:	53                   	push   %ebx
f01009de:	83 ec 2c             	sub    $0x2c,%esp
f01009e1:	8b 75 08             	mov    0x8(%ebp),%esi
f01009e4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01009e7:	c7 03 6c 1c 10 f0    	movl   $0xf0101c6c,(%ebx)
	info->eip_line = 0;
f01009ed:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01009f4:	c7 43 08 6c 1c 10 f0 	movl   $0xf0101c6c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01009fb:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100a02:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a05:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a0c:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100a12:	76 12                	jbe    f0100a26 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a14:	b8 5a ee 10 f0       	mov    $0xf010ee5a,%eax
f0100a19:	3d 75 63 10 f0       	cmp    $0xf0106375,%eax
f0100a1e:	0f 86 50 01 00 00    	jbe    f0100b74 <debuginfo_eip+0x19c>
f0100a24:	eb 1c                	jmp    f0100a42 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a26:	c7 44 24 08 76 1c 10 	movl   $0xf0101c76,0x8(%esp)
f0100a2d:	f0 
f0100a2e:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100a35:	00 
f0100a36:	c7 04 24 83 1c 10 f0 	movl   $0xf0101c83,(%esp)
f0100a3d:	e8 b6 f6 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100a42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a47:	80 3d 59 ee 10 f0 00 	cmpb   $0x0,0xf010ee59
f0100a4e:	0f 85 2c 01 00 00    	jne    f0100b80 <debuginfo_eip+0x1a8>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a54:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100a5b:	b8 74 63 10 f0       	mov    $0xf0106374,%eax
f0100a60:	2d a4 1e 10 f0       	sub    $0xf0101ea4,%eax
f0100a65:	c1 f8 02             	sar    $0x2,%eax
f0100a68:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100a6e:	48                   	dec    %eax
f0100a6f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100a72:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100a76:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100a7d:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100a80:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100a83:	b8 a4 1e 10 f0       	mov    $0xf0101ea4,%eax
f0100a88:	e8 6b fe ff ff       	call   f01008f8 <stab_binsearch>
	if (lfile == 0)
f0100a8d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100a90:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100a95:	85 d2                	test   %edx,%edx
f0100a97:	0f 84 e3 00 00 00    	je     f0100b80 <debuginfo_eip+0x1a8>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100a9d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100aa0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100aa3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100aa6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100aaa:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100ab1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100ab4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ab7:	b8 a4 1e 10 f0       	mov    $0xf0101ea4,%eax
f0100abc:	e8 37 fe ff ff       	call   f01008f8 <stab_binsearch>

	if (lfun <= rfun) {
f0100ac1:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100ac4:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100ac7:	7f 2e                	jg     f0100af7 <debuginfo_eip+0x11f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100ac9:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100acc:	8d 90 a4 1e 10 f0    	lea    -0xfefe15c(%eax),%edx
f0100ad2:	8b 80 a4 1e 10 f0    	mov    -0xfefe15c(%eax),%eax
f0100ad8:	b9 5a ee 10 f0       	mov    $0xf010ee5a,%ecx
f0100add:	81 e9 75 63 10 f0    	sub    $0xf0106375,%ecx
f0100ae3:	39 c8                	cmp    %ecx,%eax
f0100ae5:	73 08                	jae    f0100aef <debuginfo_eip+0x117>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100ae7:	05 75 63 10 f0       	add    $0xf0106375,%eax
f0100aec:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100aef:	8b 42 08             	mov    0x8(%edx),%eax
f0100af2:	89 43 10             	mov    %eax,0x10(%ebx)
f0100af5:	eb 06                	jmp    f0100afd <debuginfo_eip+0x125>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100af7:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100afa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100afd:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100b04:	00 
f0100b05:	8b 43 08             	mov    0x8(%ebx),%eax
f0100b08:	89 04 24             	mov    %eax,(%esp)
f0100b0b:	e8 22 08 00 00       	call   f0101332 <strfind>
f0100b10:	2b 43 08             	sub    0x8(%ebx),%eax
f0100b13:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b16:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b19:	eb 01                	jmp    f0100b1c <debuginfo_eip+0x144>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b1b:	4f                   	dec    %edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b1c:	39 cf                	cmp    %ecx,%edi
f0100b1e:	7c 24                	jl     f0100b44 <debuginfo_eip+0x16c>
	       && stabs[lline].n_type != N_SOL
f0100b20:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100b23:	8d 14 85 a4 1e 10 f0 	lea    -0xfefe15c(,%eax,4),%edx
f0100b2a:	8a 42 04             	mov    0x4(%edx),%al
f0100b2d:	3c 84                	cmp    $0x84,%al
f0100b2f:	74 57                	je     f0100b88 <debuginfo_eip+0x1b0>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b31:	3c 64                	cmp    $0x64,%al
f0100b33:	75 e6                	jne    f0100b1b <debuginfo_eip+0x143>
f0100b35:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100b39:	74 e0                	je     f0100b1b <debuginfo_eip+0x143>
f0100b3b:	eb 4b                	jmp    f0100b88 <debuginfo_eip+0x1b0>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100b3d:	05 75 63 10 f0       	add    $0xf0106375,%eax
f0100b42:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b44:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100b47:	8b 55 d8             	mov    -0x28(%ebp),%edx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b4a:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b4f:	39 d1                	cmp    %edx,%ecx
f0100b51:	7d 2d                	jge    f0100b80 <debuginfo_eip+0x1a8>
		for (lline = lfun + 1;
f0100b53:	8d 41 01             	lea    0x1(%ecx),%eax
f0100b56:	eb 04                	jmp    f0100b5c <debuginfo_eip+0x184>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100b58:	ff 43 14             	incl   0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100b5b:	40                   	inc    %eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100b5c:	39 d0                	cmp    %edx,%eax
f0100b5e:	74 1b                	je     f0100b7b <debuginfo_eip+0x1a3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100b60:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100b63:	80 3c 8d a8 1e 10 f0 	cmpb   $0xa0,-0xfefe158(,%ecx,4)
f0100b6a:	a0 
f0100b6b:	74 eb                	je     f0100b58 <debuginfo_eip+0x180>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b6d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b72:	eb 0c                	jmp    f0100b80 <debuginfo_eip+0x1a8>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100b74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b79:	eb 05                	jmp    f0100b80 <debuginfo_eip+0x1a8>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b7b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100b80:	83 c4 2c             	add    $0x2c,%esp
f0100b83:	5b                   	pop    %ebx
f0100b84:	5e                   	pop    %esi
f0100b85:	5f                   	pop    %edi
f0100b86:	5d                   	pop    %ebp
f0100b87:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b88:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100b8b:	8b 87 a4 1e 10 f0    	mov    -0xfefe15c(%edi),%eax
f0100b91:	ba 5a ee 10 f0       	mov    $0xf010ee5a,%edx
f0100b96:	81 ea 75 63 10 f0    	sub    $0xf0106375,%edx
f0100b9c:	39 d0                	cmp    %edx,%eax
f0100b9e:	72 9d                	jb     f0100b3d <debuginfo_eip+0x165>
f0100ba0:	eb a2                	jmp    f0100b44 <debuginfo_eip+0x16c>
	...

f0100ba4 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100ba4:	55                   	push   %ebp
f0100ba5:	89 e5                	mov    %esp,%ebp
f0100ba7:	57                   	push   %edi
f0100ba8:	56                   	push   %esi
f0100ba9:	53                   	push   %ebx
f0100baa:	83 ec 3c             	sub    $0x3c,%esp
f0100bad:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100bb0:	89 d7                	mov    %edx,%edi
f0100bb2:	8b 45 08             	mov    0x8(%ebp),%eax
f0100bb5:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100bb8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bbb:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100bbe:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100bc1:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100bc4:	85 c0                	test   %eax,%eax
f0100bc6:	75 08                	jne    f0100bd0 <printnum+0x2c>
f0100bc8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100bcb:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100bce:	77 57                	ja     f0100c27 <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100bd0:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100bd4:	4b                   	dec    %ebx
f0100bd5:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100bd9:	8b 45 10             	mov    0x10(%ebp),%eax
f0100bdc:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100be0:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0100be4:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0100be8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100bef:	00 
f0100bf0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100bf3:	89 04 24             	mov    %eax,(%esp)
f0100bf6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bf9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bfd:	e8 3e 09 00 00       	call   f0101540 <__udivdi3>
f0100c02:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100c06:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100c0a:	89 04 24             	mov    %eax,(%esp)
f0100c0d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c11:	89 fa                	mov    %edi,%edx
f0100c13:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c16:	e8 89 ff ff ff       	call   f0100ba4 <printnum>
f0100c1b:	eb 0f                	jmp    f0100c2c <printnum+0x88>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c1d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c21:	89 34 24             	mov    %esi,(%esp)
f0100c24:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c27:	4b                   	dec    %ebx
f0100c28:	85 db                	test   %ebx,%ebx
f0100c2a:	7f f1                	jg     f0100c1d <printnum+0x79>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100c2c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c30:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100c34:	8b 45 10             	mov    0x10(%ebp),%eax
f0100c37:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100c3b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100c42:	00 
f0100c43:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c46:	89 04 24             	mov    %eax,(%esp)
f0100c49:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c4c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c50:	e8 0b 0a 00 00       	call   f0101660 <__umoddi3>
f0100c55:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c59:	0f be 80 91 1c 10 f0 	movsbl -0xfefe36f(%eax),%eax
f0100c60:	89 04 24             	mov    %eax,(%esp)
f0100c63:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100c66:	83 c4 3c             	add    $0x3c,%esp
f0100c69:	5b                   	pop    %ebx
f0100c6a:	5e                   	pop    %esi
f0100c6b:	5f                   	pop    %edi
f0100c6c:	5d                   	pop    %ebp
f0100c6d:	c3                   	ret    

f0100c6e <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100c6e:	55                   	push   %ebp
f0100c6f:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100c71:	83 fa 01             	cmp    $0x1,%edx
f0100c74:	7e 0e                	jle    f0100c84 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100c76:	8b 10                	mov    (%eax),%edx
f0100c78:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100c7b:	89 08                	mov    %ecx,(%eax)
f0100c7d:	8b 02                	mov    (%edx),%eax
f0100c7f:	8b 52 04             	mov    0x4(%edx),%edx
f0100c82:	eb 22                	jmp    f0100ca6 <getuint+0x38>
	else if (lflag)
f0100c84:	85 d2                	test   %edx,%edx
f0100c86:	74 10                	je     f0100c98 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100c88:	8b 10                	mov    (%eax),%edx
f0100c8a:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100c8d:	89 08                	mov    %ecx,(%eax)
f0100c8f:	8b 02                	mov    (%edx),%eax
f0100c91:	ba 00 00 00 00       	mov    $0x0,%edx
f0100c96:	eb 0e                	jmp    f0100ca6 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100c98:	8b 10                	mov    (%eax),%edx
f0100c9a:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100c9d:	89 08                	mov    %ecx,(%eax)
f0100c9f:	8b 02                	mov    (%edx),%eax
f0100ca1:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100ca6:	5d                   	pop    %ebp
f0100ca7:	c3                   	ret    

f0100ca8 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100ca8:	55                   	push   %ebp
f0100ca9:	89 e5                	mov    %esp,%ebp
f0100cab:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100cae:	ff 40 08             	incl   0x8(%eax)
	if (b->buf < b->ebuf)
f0100cb1:	8b 10                	mov    (%eax),%edx
f0100cb3:	3b 50 04             	cmp    0x4(%eax),%edx
f0100cb6:	73 08                	jae    f0100cc0 <sprintputch+0x18>
		*b->buf++ = ch;
f0100cb8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100cbb:	88 0a                	mov    %cl,(%edx)
f0100cbd:	42                   	inc    %edx
f0100cbe:	89 10                	mov    %edx,(%eax)
}
f0100cc0:	5d                   	pop    %ebp
f0100cc1:	c3                   	ret    

f0100cc2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100cc2:	55                   	push   %ebp
f0100cc3:	89 e5                	mov    %esp,%ebp
f0100cc5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100cc8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100ccb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ccf:	8b 45 10             	mov    0x10(%ebp),%eax
f0100cd2:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cd6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100cd9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cdd:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ce0:	89 04 24             	mov    %eax,(%esp)
f0100ce3:	e8 02 00 00 00       	call   f0100cea <vprintfmt>
	va_end(ap);
}
f0100ce8:	c9                   	leave  
f0100ce9:	c3                   	ret    

f0100cea <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100cea:	55                   	push   %ebp
f0100ceb:	89 e5                	mov    %esp,%ebp
f0100ced:	57                   	push   %edi
f0100cee:	56                   	push   %esi
f0100cef:	53                   	push   %ebx
f0100cf0:	83 ec 4c             	sub    $0x4c,%esp
f0100cf3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100cf6:	8b 75 10             	mov    0x10(%ebp),%esi
f0100cf9:	eb 12                	jmp    f0100d0d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100cfb:	85 c0                	test   %eax,%eax
f0100cfd:	0f 84 8b 03 00 00    	je     f010108e <vprintfmt+0x3a4>
				return;
			putch(ch, putdat);
f0100d03:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100d07:	89 04 24             	mov    %eax,(%esp)
f0100d0a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d0d:	0f b6 06             	movzbl (%esi),%eax
f0100d10:	46                   	inc    %esi
f0100d11:	83 f8 25             	cmp    $0x25,%eax
f0100d14:	75 e5                	jne    f0100cfb <vprintfmt+0x11>
f0100d16:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100d1a:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100d21:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100d26:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100d2d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d32:	eb 26                	jmp    f0100d5a <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d34:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100d37:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100d3b:	eb 1d                	jmp    f0100d5a <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d3d:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100d40:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100d44:	eb 14                	jmp    f0100d5a <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d46:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100d49:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100d50:	eb 08                	jmp    f0100d5a <vprintfmt+0x70>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100d52:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0100d55:	bf ff ff ff ff       	mov    $0xffffffff,%edi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d5a:	0f b6 06             	movzbl (%esi),%eax
f0100d5d:	8d 56 01             	lea    0x1(%esi),%edx
f0100d60:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100d63:	8a 16                	mov    (%esi),%dl
f0100d65:	83 ea 23             	sub    $0x23,%edx
f0100d68:	80 fa 55             	cmp    $0x55,%dl
f0100d6b:	0f 87 01 03 00 00    	ja     f0101072 <vprintfmt+0x388>
f0100d71:	0f b6 d2             	movzbl %dl,%edx
f0100d74:	ff 24 95 20 1d 10 f0 	jmp    *-0xfefe2e0(,%edx,4)
f0100d7b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100d7e:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100d83:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0100d86:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0100d8a:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100d8d:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100d90:	83 fa 09             	cmp    $0x9,%edx
f0100d93:	77 2a                	ja     f0100dbf <vprintfmt+0xd5>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100d95:	46                   	inc    %esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100d96:	eb eb                	jmp    f0100d83 <vprintfmt+0x99>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100d98:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d9b:	8d 50 04             	lea    0x4(%eax),%edx
f0100d9e:	89 55 14             	mov    %edx,0x14(%ebp)
f0100da1:	8b 38                	mov    (%eax),%edi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100da3:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100da6:	eb 17                	jmp    f0100dbf <vprintfmt+0xd5>

		case '.':
			if (width < 0)
f0100da8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100dac:	78 98                	js     f0100d46 <vprintfmt+0x5c>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dae:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100db1:	eb a7                	jmp    f0100d5a <vprintfmt+0x70>
f0100db3:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100db6:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0100dbd:	eb 9b                	jmp    f0100d5a <vprintfmt+0x70>

		process_precision:
			if (width < 0)
f0100dbf:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100dc3:	79 95                	jns    f0100d5a <vprintfmt+0x70>
f0100dc5:	eb 8b                	jmp    f0100d52 <vprintfmt+0x68>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100dc7:	41                   	inc    %ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dc8:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100dcb:	eb 8d                	jmp    f0100d5a <vprintfmt+0x70>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100dcd:	8b 45 14             	mov    0x14(%ebp),%eax
f0100dd0:	8d 50 04             	lea    0x4(%eax),%edx
f0100dd3:	89 55 14             	mov    %edx,0x14(%ebp)
f0100dd6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100dda:	8b 00                	mov    (%eax),%eax
f0100ddc:	89 04 24             	mov    %eax,(%esp)
f0100ddf:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100de2:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100de5:	e9 23 ff ff ff       	jmp    f0100d0d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100dea:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ded:	8d 50 04             	lea    0x4(%eax),%edx
f0100df0:	89 55 14             	mov    %edx,0x14(%ebp)
f0100df3:	8b 00                	mov    (%eax),%eax
f0100df5:	85 c0                	test   %eax,%eax
f0100df7:	79 02                	jns    f0100dfb <vprintfmt+0x111>
f0100df9:	f7 d8                	neg    %eax
f0100dfb:	89 c2                	mov    %eax,%edx
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100dfd:	83 f8 06             	cmp    $0x6,%eax
f0100e00:	7f 0b                	jg     f0100e0d <vprintfmt+0x123>
f0100e02:	8b 04 85 78 1e 10 f0 	mov    -0xfefe188(,%eax,4),%eax
f0100e09:	85 c0                	test   %eax,%eax
f0100e0b:	75 23                	jne    f0100e30 <vprintfmt+0x146>
				printfmt(putch, putdat, "error %d", err);
f0100e0d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100e11:	c7 44 24 08 a9 1c 10 	movl   $0xf0101ca9,0x8(%esp)
f0100e18:	f0 
f0100e19:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e1d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e20:	89 04 24             	mov    %eax,(%esp)
f0100e23:	e8 9a fe ff ff       	call   f0100cc2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e28:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100e2b:	e9 dd fe ff ff       	jmp    f0100d0d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0100e30:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e34:	c7 44 24 08 b2 1c 10 	movl   $0xf0101cb2,0x8(%esp)
f0100e3b:	f0 
f0100e3c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e40:	8b 55 08             	mov    0x8(%ebp),%edx
f0100e43:	89 14 24             	mov    %edx,(%esp)
f0100e46:	e8 77 fe ff ff       	call   f0100cc2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e4b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100e4e:	e9 ba fe ff ff       	jmp    f0100d0d <vprintfmt+0x23>
f0100e53:	89 f9                	mov    %edi,%ecx
f0100e55:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e58:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100e5b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e5e:	8d 50 04             	lea    0x4(%eax),%edx
f0100e61:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e64:	8b 30                	mov    (%eax),%esi
f0100e66:	85 f6                	test   %esi,%esi
f0100e68:	75 05                	jne    f0100e6f <vprintfmt+0x185>
				p = "(null)";
f0100e6a:	be a2 1c 10 f0       	mov    $0xf0101ca2,%esi
			if (width > 0 && padc != '-')
f0100e6f:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0100e73:	0f 8e 84 00 00 00    	jle    f0100efd <vprintfmt+0x213>
f0100e79:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0100e7d:	74 7e                	je     f0100efd <vprintfmt+0x213>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e7f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100e83:	89 34 24             	mov    %esi,(%esp)
f0100e86:	e8 73 03 00 00       	call   f01011fe <strnlen>
f0100e8b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100e8e:	29 c2                	sub    %eax,%edx
f0100e90:	89 55 e4             	mov    %edx,-0x1c(%ebp)
					putch(padc, putdat);
f0100e93:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0100e97:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0100e9a:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0100e9d:	89 de                	mov    %ebx,%esi
f0100e9f:	89 d3                	mov    %edx,%ebx
f0100ea1:	89 c7                	mov    %eax,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ea3:	eb 0b                	jmp    f0100eb0 <vprintfmt+0x1c6>
					putch(padc, putdat);
f0100ea5:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ea9:	89 3c 24             	mov    %edi,(%esp)
f0100eac:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100eaf:	4b                   	dec    %ebx
f0100eb0:	85 db                	test   %ebx,%ebx
f0100eb2:	7f f1                	jg     f0100ea5 <vprintfmt+0x1bb>
f0100eb4:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0100eb7:	89 f3                	mov    %esi,%ebx
f0100eb9:	8b 75 d0             	mov    -0x30(%ebp),%esi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f0100ebc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ebf:	85 c0                	test   %eax,%eax
f0100ec1:	79 05                	jns    f0100ec8 <vprintfmt+0x1de>
f0100ec3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ec8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100ecb:	29 c2                	sub    %eax,%edx
f0100ecd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100ed0:	eb 2b                	jmp    f0100efd <vprintfmt+0x213>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100ed2:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100ed6:	74 18                	je     f0100ef0 <vprintfmt+0x206>
f0100ed8:	8d 50 e0             	lea    -0x20(%eax),%edx
f0100edb:	83 fa 5e             	cmp    $0x5e,%edx
f0100ede:	76 10                	jbe    f0100ef0 <vprintfmt+0x206>
					putch('?', putdat);
f0100ee0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ee4:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100eeb:	ff 55 08             	call   *0x8(%ebp)
f0100eee:	eb 0a                	jmp    f0100efa <vprintfmt+0x210>
				else
					putch(ch, putdat);
f0100ef0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ef4:	89 04 24             	mov    %eax,(%esp)
f0100ef7:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100efa:	ff 4d e4             	decl   -0x1c(%ebp)
f0100efd:	0f be 06             	movsbl (%esi),%eax
f0100f00:	46                   	inc    %esi
f0100f01:	85 c0                	test   %eax,%eax
f0100f03:	74 21                	je     f0100f26 <vprintfmt+0x23c>
f0100f05:	85 ff                	test   %edi,%edi
f0100f07:	78 c9                	js     f0100ed2 <vprintfmt+0x1e8>
f0100f09:	4f                   	dec    %edi
f0100f0a:	79 c6                	jns    f0100ed2 <vprintfmt+0x1e8>
f0100f0c:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100f0f:	89 de                	mov    %ebx,%esi
f0100f11:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100f14:	eb 18                	jmp    f0100f2e <vprintfmt+0x244>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100f16:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f1a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100f21:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100f23:	4b                   	dec    %ebx
f0100f24:	eb 08                	jmp    f0100f2e <vprintfmt+0x244>
f0100f26:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100f29:	89 de                	mov    %ebx,%esi
f0100f2b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100f2e:	85 db                	test   %ebx,%ebx
f0100f30:	7f e4                	jg     f0100f16 <vprintfmt+0x22c>
f0100f32:	89 7d 08             	mov    %edi,0x8(%ebp)
f0100f35:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f37:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100f3a:	e9 ce fd ff ff       	jmp    f0100d0d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100f3f:	83 f9 01             	cmp    $0x1,%ecx
f0100f42:	7e 10                	jle    f0100f54 <vprintfmt+0x26a>
		return va_arg(*ap, long long);
f0100f44:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f47:	8d 50 08             	lea    0x8(%eax),%edx
f0100f4a:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f4d:	8b 30                	mov    (%eax),%esi
f0100f4f:	8b 78 04             	mov    0x4(%eax),%edi
f0100f52:	eb 26                	jmp    f0100f7a <vprintfmt+0x290>
	else if (lflag)
f0100f54:	85 c9                	test   %ecx,%ecx
f0100f56:	74 12                	je     f0100f6a <vprintfmt+0x280>
		return va_arg(*ap, long);
f0100f58:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f5b:	8d 50 04             	lea    0x4(%eax),%edx
f0100f5e:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f61:	8b 30                	mov    (%eax),%esi
f0100f63:	89 f7                	mov    %esi,%edi
f0100f65:	c1 ff 1f             	sar    $0x1f,%edi
f0100f68:	eb 10                	jmp    f0100f7a <vprintfmt+0x290>
	else
		return va_arg(*ap, int);
f0100f6a:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f6d:	8d 50 04             	lea    0x4(%eax),%edx
f0100f70:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f73:	8b 30                	mov    (%eax),%esi
f0100f75:	89 f7                	mov    %esi,%edi
f0100f77:	c1 ff 1f             	sar    $0x1f,%edi
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0100f7a:	85 ff                	test   %edi,%edi
f0100f7c:	78 0a                	js     f0100f88 <vprintfmt+0x29e>
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0100f7e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100f83:	e9 ac 00 00 00       	jmp    f0101034 <vprintfmt+0x34a>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
f0100f88:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f8c:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0100f93:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0100f96:	f7 de                	neg    %esi
f0100f98:	83 d7 00             	adc    $0x0,%edi
f0100f9b:	f7 df                	neg    %edi
			}
			base = 10;
f0100f9d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100fa2:	e9 8d 00 00 00       	jmp    f0101034 <vprintfmt+0x34a>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0100fa7:	89 ca                	mov    %ecx,%edx
f0100fa9:	8d 45 14             	lea    0x14(%ebp),%eax
f0100fac:	e8 bd fc ff ff       	call   f0100c6e <getuint>
f0100fb1:	89 c6                	mov    %eax,%esi
f0100fb3:	89 d7                	mov    %edx,%edi
			base = 10;
f0100fb5:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f0100fba:	eb 78                	jmp    f0101034 <vprintfmt+0x34a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0100fbc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fc0:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0100fc7:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f0100fca:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fce:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0100fd5:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f0100fd8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fdc:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0100fe3:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fe6:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0100fe9:	e9 1f fd ff ff       	jmp    f0100d0d <vprintfmt+0x23>

		// pointer
		case 'p':
			putch('0', putdat);
f0100fee:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ff2:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0100ff9:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0100ffc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101000:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101007:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010100a:	8b 45 14             	mov    0x14(%ebp),%eax
f010100d:	8d 50 04             	lea    0x4(%eax),%edx
f0101010:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101013:	8b 30                	mov    (%eax),%esi
f0101015:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010101a:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010101f:	eb 13                	jmp    f0101034 <vprintfmt+0x34a>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101021:	89 ca                	mov    %ecx,%edx
f0101023:	8d 45 14             	lea    0x14(%ebp),%eax
f0101026:	e8 43 fc ff ff       	call   f0100c6e <getuint>
f010102b:	89 c6                	mov    %eax,%esi
f010102d:	89 d7                	mov    %edx,%edi
			base = 16;
f010102f:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101034:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f0101038:	89 54 24 10          	mov    %edx,0x10(%esp)
f010103c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010103f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101043:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101047:	89 34 24             	mov    %esi,(%esp)
f010104a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010104e:	89 da                	mov    %ebx,%edx
f0101050:	8b 45 08             	mov    0x8(%ebp),%eax
f0101053:	e8 4c fb ff ff       	call   f0100ba4 <printnum>
			break;
f0101058:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010105b:	e9 ad fc ff ff       	jmp    f0100d0d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101060:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101064:	89 04 24             	mov    %eax,(%esp)
f0101067:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010106a:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010106d:	e9 9b fc ff ff       	jmp    f0100d0d <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101072:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101076:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f010107d:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101080:	eb 01                	jmp    f0101083 <vprintfmt+0x399>
f0101082:	4e                   	dec    %esi
f0101083:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101087:	75 f9                	jne    f0101082 <vprintfmt+0x398>
f0101089:	e9 7f fc ff ff       	jmp    f0100d0d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f010108e:	83 c4 4c             	add    $0x4c,%esp
f0101091:	5b                   	pop    %ebx
f0101092:	5e                   	pop    %esi
f0101093:	5f                   	pop    %edi
f0101094:	5d                   	pop    %ebp
f0101095:	c3                   	ret    

f0101096 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101096:	55                   	push   %ebp
f0101097:	89 e5                	mov    %esp,%ebp
f0101099:	83 ec 28             	sub    $0x28,%esp
f010109c:	8b 45 08             	mov    0x8(%ebp),%eax
f010109f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01010a2:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01010a5:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01010a9:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01010ac:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01010b3:	85 c0                	test   %eax,%eax
f01010b5:	74 30                	je     f01010e7 <vsnprintf+0x51>
f01010b7:	85 d2                	test   %edx,%edx
f01010b9:	7e 33                	jle    f01010ee <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01010bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01010be:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01010c2:	8b 45 10             	mov    0x10(%ebp),%eax
f01010c5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01010c9:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01010cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010d0:	c7 04 24 a8 0c 10 f0 	movl   $0xf0100ca8,(%esp)
f01010d7:	e8 0e fc ff ff       	call   f0100cea <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01010dc:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01010df:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01010e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01010e5:	eb 0c                	jmp    f01010f3 <vsnprintf+0x5d>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01010e7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01010ec:	eb 05                	jmp    f01010f3 <vsnprintf+0x5d>
f01010ee:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01010f3:	c9                   	leave  
f01010f4:	c3                   	ret    

f01010f5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01010f5:	55                   	push   %ebp
f01010f6:	89 e5                	mov    %esp,%ebp
f01010f8:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01010fb:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01010fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101102:	8b 45 10             	mov    0x10(%ebp),%eax
f0101105:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101109:	8b 45 0c             	mov    0xc(%ebp),%eax
f010110c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101110:	8b 45 08             	mov    0x8(%ebp),%eax
f0101113:	89 04 24             	mov    %eax,(%esp)
f0101116:	e8 7b ff ff ff       	call   f0101096 <vsnprintf>
	va_end(ap);

	return rc;
}
f010111b:	c9                   	leave  
f010111c:	c3                   	ret    
f010111d:	00 00                	add    %al,(%eax)
	...

f0101120 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101120:	55                   	push   %ebp
f0101121:	89 e5                	mov    %esp,%ebp
f0101123:	57                   	push   %edi
f0101124:	56                   	push   %esi
f0101125:	53                   	push   %ebx
f0101126:	83 ec 1c             	sub    $0x1c,%esp
f0101129:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010112c:	85 c0                	test   %eax,%eax
f010112e:	74 10                	je     f0101140 <readline+0x20>
		cprintf("%s", prompt);
f0101130:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101134:	c7 04 24 b2 1c 10 f0 	movl   $0xf0101cb2,(%esp)
f010113b:	e8 9e f7 ff ff       	call   f01008de <cprintf>

	i = 0;
	echoing = iscons(0);
f0101140:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101147:	e8 f1 f4 ff ff       	call   f010063d <iscons>
f010114c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010114e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101153:	e8 d4 f4 ff ff       	call   f010062c <getchar>
f0101158:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010115a:	85 c0                	test   %eax,%eax
f010115c:	79 17                	jns    f0101175 <readline+0x55>
			cprintf("read error: %e\n", c);
f010115e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101162:	c7 04 24 94 1e 10 f0 	movl   $0xf0101e94,(%esp)
f0101169:	e8 70 f7 ff ff       	call   f01008de <cprintf>
			return NULL;
f010116e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101173:	eb 69                	jmp    f01011de <readline+0xbe>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101175:	83 f8 08             	cmp    $0x8,%eax
f0101178:	74 05                	je     f010117f <readline+0x5f>
f010117a:	83 f8 7f             	cmp    $0x7f,%eax
f010117d:	75 17                	jne    f0101196 <readline+0x76>
f010117f:	85 f6                	test   %esi,%esi
f0101181:	7e 13                	jle    f0101196 <readline+0x76>
			if (echoing)
f0101183:	85 ff                	test   %edi,%edi
f0101185:	74 0c                	je     f0101193 <readline+0x73>
				cputchar('\b');
f0101187:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010118e:	e8 89 f4 ff ff       	call   f010061c <cputchar>
			i--;
f0101193:	4e                   	dec    %esi
f0101194:	eb bd                	jmp    f0101153 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101196:	83 fb 1f             	cmp    $0x1f,%ebx
f0101199:	7e 1d                	jle    f01011b8 <readline+0x98>
f010119b:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01011a1:	7f 15                	jg     f01011b8 <readline+0x98>
			if (echoing)
f01011a3:	85 ff                	test   %edi,%edi
f01011a5:	74 08                	je     f01011af <readline+0x8f>
				cputchar(c);
f01011a7:	89 1c 24             	mov    %ebx,(%esp)
f01011aa:	e8 6d f4 ff ff       	call   f010061c <cputchar>
			buf[i++] = c;
f01011af:	88 9e 40 95 11 f0    	mov    %bl,-0xfee6ac0(%esi)
f01011b5:	46                   	inc    %esi
f01011b6:	eb 9b                	jmp    f0101153 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01011b8:	83 fb 0a             	cmp    $0xa,%ebx
f01011bb:	74 05                	je     f01011c2 <readline+0xa2>
f01011bd:	83 fb 0d             	cmp    $0xd,%ebx
f01011c0:	75 91                	jne    f0101153 <readline+0x33>
			if (echoing)
f01011c2:	85 ff                	test   %edi,%edi
f01011c4:	74 0c                	je     f01011d2 <readline+0xb2>
				cputchar('\n');
f01011c6:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01011cd:	e8 4a f4 ff ff       	call   f010061c <cputchar>
			buf[i] = 0;
f01011d2:	c6 86 40 95 11 f0 00 	movb   $0x0,-0xfee6ac0(%esi)
			return buf;
f01011d9:	b8 40 95 11 f0       	mov    $0xf0119540,%eax
		}
	}
}
f01011de:	83 c4 1c             	add    $0x1c,%esp
f01011e1:	5b                   	pop    %ebx
f01011e2:	5e                   	pop    %esi
f01011e3:	5f                   	pop    %edi
f01011e4:	5d                   	pop    %ebp
f01011e5:	c3                   	ret    
	...

f01011e8 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01011e8:	55                   	push   %ebp
f01011e9:	89 e5                	mov    %esp,%ebp
f01011eb:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01011ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01011f3:	eb 01                	jmp    f01011f6 <strlen+0xe>
		n++;
f01011f5:	40                   	inc    %eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01011f6:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01011fa:	75 f9                	jne    f01011f5 <strlen+0xd>
		n++;
	return n;
}
f01011fc:	5d                   	pop    %ebp
f01011fd:	c3                   	ret    

f01011fe <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01011fe:	55                   	push   %ebp
f01011ff:	89 e5                	mov    %esp,%ebp
f0101201:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
f0101204:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101207:	b8 00 00 00 00       	mov    $0x0,%eax
f010120c:	eb 01                	jmp    f010120f <strnlen+0x11>
		n++;
f010120e:	40                   	inc    %eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010120f:	39 d0                	cmp    %edx,%eax
f0101211:	74 06                	je     f0101219 <strnlen+0x1b>
f0101213:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101217:	75 f5                	jne    f010120e <strnlen+0x10>
		n++;
	return n;
}
f0101219:	5d                   	pop    %ebp
f010121a:	c3                   	ret    

f010121b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010121b:	55                   	push   %ebp
f010121c:	89 e5                	mov    %esp,%ebp
f010121e:	53                   	push   %ebx
f010121f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101222:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101225:	ba 00 00 00 00       	mov    $0x0,%edx
f010122a:	8a 0c 13             	mov    (%ebx,%edx,1),%cl
f010122d:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101230:	42                   	inc    %edx
f0101231:	84 c9                	test   %cl,%cl
f0101233:	75 f5                	jne    f010122a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101235:	5b                   	pop    %ebx
f0101236:	5d                   	pop    %ebp
f0101237:	c3                   	ret    

f0101238 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101238:	55                   	push   %ebp
f0101239:	89 e5                	mov    %esp,%ebp
f010123b:	53                   	push   %ebx
f010123c:	83 ec 08             	sub    $0x8,%esp
f010123f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101242:	89 1c 24             	mov    %ebx,(%esp)
f0101245:	e8 9e ff ff ff       	call   f01011e8 <strlen>
	strcpy(dst + len, src);
f010124a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010124d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101251:	01 d8                	add    %ebx,%eax
f0101253:	89 04 24             	mov    %eax,(%esp)
f0101256:	e8 c0 ff ff ff       	call   f010121b <strcpy>
	return dst;
}
f010125b:	89 d8                	mov    %ebx,%eax
f010125d:	83 c4 08             	add    $0x8,%esp
f0101260:	5b                   	pop    %ebx
f0101261:	5d                   	pop    %ebp
f0101262:	c3                   	ret    

f0101263 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101263:	55                   	push   %ebp
f0101264:	89 e5                	mov    %esp,%ebp
f0101266:	56                   	push   %esi
f0101267:	53                   	push   %ebx
f0101268:	8b 45 08             	mov    0x8(%ebp),%eax
f010126b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010126e:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101271:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101276:	eb 0c                	jmp    f0101284 <strncpy+0x21>
		*dst++ = *src;
f0101278:	8a 1a                	mov    (%edx),%bl
f010127a:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010127d:	80 3a 01             	cmpb   $0x1,(%edx)
f0101280:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101283:	41                   	inc    %ecx
f0101284:	39 f1                	cmp    %esi,%ecx
f0101286:	75 f0                	jne    f0101278 <strncpy+0x15>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101288:	5b                   	pop    %ebx
f0101289:	5e                   	pop    %esi
f010128a:	5d                   	pop    %ebp
f010128b:	c3                   	ret    

f010128c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010128c:	55                   	push   %ebp
f010128d:	89 e5                	mov    %esp,%ebp
f010128f:	56                   	push   %esi
f0101290:	53                   	push   %ebx
f0101291:	8b 75 08             	mov    0x8(%ebp),%esi
f0101294:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101297:	8b 55 10             	mov    0x10(%ebp),%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010129a:	85 d2                	test   %edx,%edx
f010129c:	75 0a                	jne    f01012a8 <strlcpy+0x1c>
f010129e:	89 f0                	mov    %esi,%eax
f01012a0:	eb 1a                	jmp    f01012bc <strlcpy+0x30>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01012a2:	88 18                	mov    %bl,(%eax)
f01012a4:	40                   	inc    %eax
f01012a5:	41                   	inc    %ecx
f01012a6:	eb 02                	jmp    f01012aa <strlcpy+0x1e>
strlcpy(char *dst, const char *src, size_t size)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01012a8:	89 f0                	mov    %esi,%eax
		while (--size > 0 && *src != '\0')
f01012aa:	4a                   	dec    %edx
f01012ab:	74 0a                	je     f01012b7 <strlcpy+0x2b>
f01012ad:	8a 19                	mov    (%ecx),%bl
f01012af:	84 db                	test   %bl,%bl
f01012b1:	75 ef                	jne    f01012a2 <strlcpy+0x16>
f01012b3:	89 c2                	mov    %eax,%edx
f01012b5:	eb 02                	jmp    f01012b9 <strlcpy+0x2d>
f01012b7:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01012b9:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01012bc:	29 f0                	sub    %esi,%eax
}
f01012be:	5b                   	pop    %ebx
f01012bf:	5e                   	pop    %esi
f01012c0:	5d                   	pop    %ebp
f01012c1:	c3                   	ret    

f01012c2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01012c2:	55                   	push   %ebp
f01012c3:	89 e5                	mov    %esp,%ebp
f01012c5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012c8:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01012cb:	eb 02                	jmp    f01012cf <strcmp+0xd>
		p++, q++;
f01012cd:	41                   	inc    %ecx
f01012ce:	42                   	inc    %edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01012cf:	8a 01                	mov    (%ecx),%al
f01012d1:	84 c0                	test   %al,%al
f01012d3:	74 04                	je     f01012d9 <strcmp+0x17>
f01012d5:	3a 02                	cmp    (%edx),%al
f01012d7:	74 f4                	je     f01012cd <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01012d9:	0f b6 c0             	movzbl %al,%eax
f01012dc:	0f b6 12             	movzbl (%edx),%edx
f01012df:	29 d0                	sub    %edx,%eax
}
f01012e1:	5d                   	pop    %ebp
f01012e2:	c3                   	ret    

f01012e3 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01012e3:	55                   	push   %ebp
f01012e4:	89 e5                	mov    %esp,%ebp
f01012e6:	53                   	push   %ebx
f01012e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01012ea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01012ed:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
f01012f0:	eb 03                	jmp    f01012f5 <strncmp+0x12>
		n--, p++, q++;
f01012f2:	4a                   	dec    %edx
f01012f3:	40                   	inc    %eax
f01012f4:	41                   	inc    %ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01012f5:	85 d2                	test   %edx,%edx
f01012f7:	74 14                	je     f010130d <strncmp+0x2a>
f01012f9:	8a 18                	mov    (%eax),%bl
f01012fb:	84 db                	test   %bl,%bl
f01012fd:	74 04                	je     f0101303 <strncmp+0x20>
f01012ff:	3a 19                	cmp    (%ecx),%bl
f0101301:	74 ef                	je     f01012f2 <strncmp+0xf>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101303:	0f b6 00             	movzbl (%eax),%eax
f0101306:	0f b6 11             	movzbl (%ecx),%edx
f0101309:	29 d0                	sub    %edx,%eax
f010130b:	eb 05                	jmp    f0101312 <strncmp+0x2f>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010130d:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101312:	5b                   	pop    %ebx
f0101313:	5d                   	pop    %ebp
f0101314:	c3                   	ret    

f0101315 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101315:	55                   	push   %ebp
f0101316:	89 e5                	mov    %esp,%ebp
f0101318:	8b 45 08             	mov    0x8(%ebp),%eax
f010131b:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f010131e:	eb 05                	jmp    f0101325 <strchr+0x10>
		if (*s == c)
f0101320:	38 ca                	cmp    %cl,%dl
f0101322:	74 0c                	je     f0101330 <strchr+0x1b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101324:	40                   	inc    %eax
f0101325:	8a 10                	mov    (%eax),%dl
f0101327:	84 d2                	test   %dl,%dl
f0101329:	75 f5                	jne    f0101320 <strchr+0xb>
		if (*s == c)
			return (char *) s;
	return 0;
f010132b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101330:	5d                   	pop    %ebp
f0101331:	c3                   	ret    

f0101332 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101332:	55                   	push   %ebp
f0101333:	89 e5                	mov    %esp,%ebp
f0101335:	8b 45 08             	mov    0x8(%ebp),%eax
f0101338:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f010133b:	eb 05                	jmp    f0101342 <strfind+0x10>
		if (*s == c)
f010133d:	38 ca                	cmp    %cl,%dl
f010133f:	74 07                	je     f0101348 <strfind+0x16>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101341:	40                   	inc    %eax
f0101342:	8a 10                	mov    (%eax),%dl
f0101344:	84 d2                	test   %dl,%dl
f0101346:	75 f5                	jne    f010133d <strfind+0xb>
		if (*s == c)
			break;
	return (char *) s;
}
f0101348:	5d                   	pop    %ebp
f0101349:	c3                   	ret    

f010134a <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010134a:	55                   	push   %ebp
f010134b:	89 e5                	mov    %esp,%ebp
f010134d:	57                   	push   %edi
f010134e:	56                   	push   %esi
f010134f:	53                   	push   %ebx
f0101350:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101353:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101356:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101359:	85 c9                	test   %ecx,%ecx
f010135b:	74 30                	je     f010138d <memset+0x43>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010135d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101363:	75 25                	jne    f010138a <memset+0x40>
f0101365:	f6 c1 03             	test   $0x3,%cl
f0101368:	75 20                	jne    f010138a <memset+0x40>
		c &= 0xFF;
f010136a:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010136d:	89 d3                	mov    %edx,%ebx
f010136f:	c1 e3 08             	shl    $0x8,%ebx
f0101372:	89 d6                	mov    %edx,%esi
f0101374:	c1 e6 18             	shl    $0x18,%esi
f0101377:	89 d0                	mov    %edx,%eax
f0101379:	c1 e0 10             	shl    $0x10,%eax
f010137c:	09 f0                	or     %esi,%eax
f010137e:	09 d0                	or     %edx,%eax
f0101380:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101382:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101385:	fc                   	cld    
f0101386:	f3 ab                	rep stos %eax,%es:(%edi)
f0101388:	eb 03                	jmp    f010138d <memset+0x43>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010138a:	fc                   	cld    
f010138b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010138d:	89 f8                	mov    %edi,%eax
f010138f:	5b                   	pop    %ebx
f0101390:	5e                   	pop    %esi
f0101391:	5f                   	pop    %edi
f0101392:	5d                   	pop    %ebp
f0101393:	c3                   	ret    

f0101394 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101394:	55                   	push   %ebp
f0101395:	89 e5                	mov    %esp,%ebp
f0101397:	57                   	push   %edi
f0101398:	56                   	push   %esi
f0101399:	8b 45 08             	mov    0x8(%ebp),%eax
f010139c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010139f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01013a2:	39 c6                	cmp    %eax,%esi
f01013a4:	73 34                	jae    f01013da <memmove+0x46>
f01013a6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01013a9:	39 d0                	cmp    %edx,%eax
f01013ab:	73 2d                	jae    f01013da <memmove+0x46>
		s += n;
		d += n;
f01013ad:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01013b0:	f6 c2 03             	test   $0x3,%dl
f01013b3:	75 1b                	jne    f01013d0 <memmove+0x3c>
f01013b5:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01013bb:	75 13                	jne    f01013d0 <memmove+0x3c>
f01013bd:	f6 c1 03             	test   $0x3,%cl
f01013c0:	75 0e                	jne    f01013d0 <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01013c2:	83 ef 04             	sub    $0x4,%edi
f01013c5:	8d 72 fc             	lea    -0x4(%edx),%esi
f01013c8:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01013cb:	fd                   	std    
f01013cc:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01013ce:	eb 07                	jmp    f01013d7 <memmove+0x43>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01013d0:	4f                   	dec    %edi
f01013d1:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01013d4:	fd                   	std    
f01013d5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01013d7:	fc                   	cld    
f01013d8:	eb 20                	jmp    f01013fa <memmove+0x66>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01013da:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01013e0:	75 13                	jne    f01013f5 <memmove+0x61>
f01013e2:	a8 03                	test   $0x3,%al
f01013e4:	75 0f                	jne    f01013f5 <memmove+0x61>
f01013e6:	f6 c1 03             	test   $0x3,%cl
f01013e9:	75 0a                	jne    f01013f5 <memmove+0x61>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01013eb:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01013ee:	89 c7                	mov    %eax,%edi
f01013f0:	fc                   	cld    
f01013f1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01013f3:	eb 05                	jmp    f01013fa <memmove+0x66>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01013f5:	89 c7                	mov    %eax,%edi
f01013f7:	fc                   	cld    
f01013f8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01013fa:	5e                   	pop    %esi
f01013fb:	5f                   	pop    %edi
f01013fc:	5d                   	pop    %ebp
f01013fd:	c3                   	ret    

f01013fe <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01013fe:	55                   	push   %ebp
f01013ff:	89 e5                	mov    %esp,%ebp
f0101401:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101404:	8b 45 10             	mov    0x10(%ebp),%eax
f0101407:	89 44 24 08          	mov    %eax,0x8(%esp)
f010140b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010140e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101412:	8b 45 08             	mov    0x8(%ebp),%eax
f0101415:	89 04 24             	mov    %eax,(%esp)
f0101418:	e8 77 ff ff ff       	call   f0101394 <memmove>
}
f010141d:	c9                   	leave  
f010141e:	c3                   	ret    

f010141f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010141f:	55                   	push   %ebp
f0101420:	89 e5                	mov    %esp,%ebp
f0101422:	57                   	push   %edi
f0101423:	56                   	push   %esi
f0101424:	53                   	push   %ebx
f0101425:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101428:	8b 75 0c             	mov    0xc(%ebp),%esi
f010142b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010142e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101433:	eb 16                	jmp    f010144b <memcmp+0x2c>
		if (*s1 != *s2)
f0101435:	8a 04 17             	mov    (%edi,%edx,1),%al
f0101438:	42                   	inc    %edx
f0101439:	8a 4c 16 ff          	mov    -0x1(%esi,%edx,1),%cl
f010143d:	38 c8                	cmp    %cl,%al
f010143f:	74 0a                	je     f010144b <memcmp+0x2c>
			return (int) *s1 - (int) *s2;
f0101441:	0f b6 c0             	movzbl %al,%eax
f0101444:	0f b6 c9             	movzbl %cl,%ecx
f0101447:	29 c8                	sub    %ecx,%eax
f0101449:	eb 09                	jmp    f0101454 <memcmp+0x35>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010144b:	39 da                	cmp    %ebx,%edx
f010144d:	75 e6                	jne    f0101435 <memcmp+0x16>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010144f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101454:	5b                   	pop    %ebx
f0101455:	5e                   	pop    %esi
f0101456:	5f                   	pop    %edi
f0101457:	5d                   	pop    %ebp
f0101458:	c3                   	ret    

f0101459 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101459:	55                   	push   %ebp
f010145a:	89 e5                	mov    %esp,%ebp
f010145c:	8b 45 08             	mov    0x8(%ebp),%eax
f010145f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101462:	89 c2                	mov    %eax,%edx
f0101464:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101467:	eb 05                	jmp    f010146e <memfind+0x15>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101469:	38 08                	cmp    %cl,(%eax)
f010146b:	74 05                	je     f0101472 <memfind+0x19>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010146d:	40                   	inc    %eax
f010146e:	39 d0                	cmp    %edx,%eax
f0101470:	72 f7                	jb     f0101469 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101472:	5d                   	pop    %ebp
f0101473:	c3                   	ret    

f0101474 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101474:	55                   	push   %ebp
f0101475:	89 e5                	mov    %esp,%ebp
f0101477:	57                   	push   %edi
f0101478:	56                   	push   %esi
f0101479:	53                   	push   %ebx
f010147a:	8b 55 08             	mov    0x8(%ebp),%edx
f010147d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101480:	eb 01                	jmp    f0101483 <strtol+0xf>
		s++;
f0101482:	42                   	inc    %edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101483:	8a 02                	mov    (%edx),%al
f0101485:	3c 20                	cmp    $0x20,%al
f0101487:	74 f9                	je     f0101482 <strtol+0xe>
f0101489:	3c 09                	cmp    $0x9,%al
f010148b:	74 f5                	je     f0101482 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010148d:	3c 2b                	cmp    $0x2b,%al
f010148f:	75 08                	jne    f0101499 <strtol+0x25>
		s++;
f0101491:	42                   	inc    %edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101492:	bf 00 00 00 00       	mov    $0x0,%edi
f0101497:	eb 13                	jmp    f01014ac <strtol+0x38>
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101499:	3c 2d                	cmp    $0x2d,%al
f010149b:	75 0a                	jne    f01014a7 <strtol+0x33>
		s++, neg = 1;
f010149d:	8d 52 01             	lea    0x1(%edx),%edx
f01014a0:	bf 01 00 00 00       	mov    $0x1,%edi
f01014a5:	eb 05                	jmp    f01014ac <strtol+0x38>
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01014a7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01014ac:	85 db                	test   %ebx,%ebx
f01014ae:	74 05                	je     f01014b5 <strtol+0x41>
f01014b0:	83 fb 10             	cmp    $0x10,%ebx
f01014b3:	75 28                	jne    f01014dd <strtol+0x69>
f01014b5:	8a 02                	mov    (%edx),%al
f01014b7:	3c 30                	cmp    $0x30,%al
f01014b9:	75 10                	jne    f01014cb <strtol+0x57>
f01014bb:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01014bf:	75 0a                	jne    f01014cb <strtol+0x57>
		s += 2, base = 16;
f01014c1:	83 c2 02             	add    $0x2,%edx
f01014c4:	bb 10 00 00 00       	mov    $0x10,%ebx
f01014c9:	eb 12                	jmp    f01014dd <strtol+0x69>
	else if (base == 0 && s[0] == '0')
f01014cb:	85 db                	test   %ebx,%ebx
f01014cd:	75 0e                	jne    f01014dd <strtol+0x69>
f01014cf:	3c 30                	cmp    $0x30,%al
f01014d1:	75 05                	jne    f01014d8 <strtol+0x64>
		s++, base = 8;
f01014d3:	42                   	inc    %edx
f01014d4:	b3 08                	mov    $0x8,%bl
f01014d6:	eb 05                	jmp    f01014dd <strtol+0x69>
	else if (base == 0)
		base = 10;
f01014d8:	bb 0a 00 00 00       	mov    $0xa,%ebx
f01014dd:	b8 00 00 00 00       	mov    $0x0,%eax
f01014e2:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01014e4:	8a 0a                	mov    (%edx),%cl
f01014e6:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f01014e9:	80 fb 09             	cmp    $0x9,%bl
f01014ec:	77 08                	ja     f01014f6 <strtol+0x82>
			dig = *s - '0';
f01014ee:	0f be c9             	movsbl %cl,%ecx
f01014f1:	83 e9 30             	sub    $0x30,%ecx
f01014f4:	eb 1e                	jmp    f0101514 <strtol+0xa0>
		else if (*s >= 'a' && *s <= 'z')
f01014f6:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f01014f9:	80 fb 19             	cmp    $0x19,%bl
f01014fc:	77 08                	ja     f0101506 <strtol+0x92>
			dig = *s - 'a' + 10;
f01014fe:	0f be c9             	movsbl %cl,%ecx
f0101501:	83 e9 57             	sub    $0x57,%ecx
f0101504:	eb 0e                	jmp    f0101514 <strtol+0xa0>
		else if (*s >= 'A' && *s <= 'Z')
f0101506:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0101509:	80 fb 19             	cmp    $0x19,%bl
f010150c:	77 12                	ja     f0101520 <strtol+0xac>
			dig = *s - 'A' + 10;
f010150e:	0f be c9             	movsbl %cl,%ecx
f0101511:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101514:	39 f1                	cmp    %esi,%ecx
f0101516:	7d 0c                	jge    f0101524 <strtol+0xb0>
			break;
		s++, val = (val * base) + dig;
f0101518:	42                   	inc    %edx
f0101519:	0f af c6             	imul   %esi,%eax
f010151c:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f010151e:	eb c4                	jmp    f01014e4 <strtol+0x70>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101520:	89 c1                	mov    %eax,%ecx
f0101522:	eb 02                	jmp    f0101526 <strtol+0xb2>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101524:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101526:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010152a:	74 05                	je     f0101531 <strtol+0xbd>
		*endptr = (char *) s;
f010152c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010152f:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101531:	85 ff                	test   %edi,%edi
f0101533:	74 04                	je     f0101539 <strtol+0xc5>
f0101535:	89 c8                	mov    %ecx,%eax
f0101537:	f7 d8                	neg    %eax
}
f0101539:	5b                   	pop    %ebx
f010153a:	5e                   	pop    %esi
f010153b:	5f                   	pop    %edi
f010153c:	5d                   	pop    %ebp
f010153d:	c3                   	ret    
	...

f0101540 <__udivdi3>:
#endif

#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
f0101540:	55                   	push   %ebp
f0101541:	57                   	push   %edi
f0101542:	56                   	push   %esi
f0101543:	83 ec 10             	sub    $0x10,%esp
f0101546:	8b 74 24 20          	mov    0x20(%esp),%esi
f010154a:	8b 4c 24 28          	mov    0x28(%esp),%ecx
static inline __attribute__ ((__always_inline__))
#endif
UDWtype
__udivmoddi4 (UDWtype n, UDWtype d, UDWtype *rp)
{
  const DWunion nn = {.ll = n};
f010154e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101552:	8b 7c 24 24          	mov    0x24(%esp),%edi
  const DWunion dd = {.ll = d};
f0101556:	89 cd                	mov    %ecx,%ebp
f0101558:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  d1 = dd.s.high;
  n0 = nn.s.low;
  n1 = nn.s.high;

#if !UDIV_NEEDS_NORMALIZATION
  if (d1 == 0)
f010155c:	85 c0                	test   %eax,%eax
f010155e:	75 2c                	jne    f010158c <__udivdi3+0x4c>
    {
      if (d0 > n1)
f0101560:	39 f9                	cmp    %edi,%ecx
f0101562:	77 68                	ja     f01015cc <__udivdi3+0x8c>
	}
      else
	{
	  /* qq = NN / 0d */

	  if (d0 == 0)
f0101564:	85 c9                	test   %ecx,%ecx
f0101566:	75 0b                	jne    f0101573 <__udivdi3+0x33>
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */
f0101568:	b8 01 00 00 00       	mov    $0x1,%eax
f010156d:	31 d2                	xor    %edx,%edx
f010156f:	f7 f1                	div    %ecx
f0101571:	89 c1                	mov    %eax,%ecx

	  udiv_qrnnd (q1, n1, 0, n1, d0);
f0101573:	31 d2                	xor    %edx,%edx
f0101575:	89 f8                	mov    %edi,%eax
f0101577:	f7 f1                	div    %ecx
f0101579:	89 c7                	mov    %eax,%edi
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f010157b:	89 f0                	mov    %esi,%eax
f010157d:	f7 f1                	div    %ecx
f010157f:	89 c6                	mov    %eax,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f0101581:	89 f0                	mov    %esi,%eax
f0101583:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f0101585:	83 c4 10             	add    $0x10,%esp
f0101588:	5e                   	pop    %esi
f0101589:	5f                   	pop    %edi
f010158a:	5d                   	pop    %ebp
f010158b:	c3                   	ret    
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f010158c:	39 f8                	cmp    %edi,%eax
f010158e:	77 2c                	ja     f01015bc <__udivdi3+0x7c>
	}
      else
	{
	  /* 0q = NN / dd */

	  count_leading_zeros (bm, d1);
f0101590:	0f bd f0             	bsr    %eax,%esi
	  if (bm == 0)
f0101593:	83 f6 1f             	xor    $0x1f,%esi
f0101596:	75 4c                	jne    f01015e4 <__udivdi3+0xa4>

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f0101598:	39 f8                	cmp    %edi,%eax
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f010159a:	bf 00 00 00 00       	mov    $0x0,%edi

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f010159f:	72 0a                	jb     f01015ab <__udivdi3+0x6b>
f01015a1:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f01015a5:	0f 87 ad 00 00 00    	ja     f0101658 <__udivdi3+0x118>
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f01015ab:	be 01 00 00 00       	mov    $0x1,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f01015b0:	89 f0                	mov    %esi,%eax
f01015b2:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f01015b4:	83 c4 10             	add    $0x10,%esp
f01015b7:	5e                   	pop    %esi
f01015b8:	5f                   	pop    %edi
f01015b9:	5d                   	pop    %ebp
f01015ba:	c3                   	ret    
f01015bb:	90                   	nop
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f01015bc:	31 ff                	xor    %edi,%edi
f01015be:	31 f6                	xor    %esi,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f01015c0:	89 f0                	mov    %esi,%eax
f01015c2:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f01015c4:	83 c4 10             	add    $0x10,%esp
f01015c7:	5e                   	pop    %esi
f01015c8:	5f                   	pop    %edi
f01015c9:	5d                   	pop    %ebp
f01015ca:	c3                   	ret    
f01015cb:	90                   	nop
    {
      if (d0 > n1)
	{
	  /* 0q = nn / 0D */

	  udiv_qrnnd (q0, n0, n1, n0, d0);
f01015cc:	89 fa                	mov    %edi,%edx
f01015ce:	89 f0                	mov    %esi,%eax
f01015d0:	f7 f1                	div    %ecx
f01015d2:	89 c6                	mov    %eax,%esi
f01015d4:	31 ff                	xor    %edi,%edi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f01015d6:	89 f0                	mov    %esi,%eax
f01015d8:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f01015da:	83 c4 10             	add    $0x10,%esp
f01015dd:	5e                   	pop    %esi
f01015de:	5f                   	pop    %edi
f01015df:	5d                   	pop    %ebp
f01015e0:	c3                   	ret    
f01015e1:	8d 76 00             	lea    0x0(%esi),%esi
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
f01015e4:	89 f1                	mov    %esi,%ecx
f01015e6:	d3 e0                	shl    %cl,%eax
f01015e8:	89 44 24 0c          	mov    %eax,0xc(%esp)
	  else
	    {
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;
f01015ec:	b8 20 00 00 00       	mov    $0x20,%eax
f01015f1:	29 f0                	sub    %esi,%eax

	      d1 = (d1 << bm) | (d0 >> b);
f01015f3:	89 ea                	mov    %ebp,%edx
f01015f5:	88 c1                	mov    %al,%cl
f01015f7:	d3 ea                	shr    %cl,%edx
f01015f9:	8b 4c 24 0c          	mov    0xc(%esp),%ecx
f01015fd:	09 ca                	or     %ecx,%edx
f01015ff:	89 54 24 08          	mov    %edx,0x8(%esp)
	      d0 = d0 << bm;
f0101603:	89 f1                	mov    %esi,%ecx
f0101605:	d3 e5                	shl    %cl,%ebp
f0101607:	89 6c 24 0c          	mov    %ebp,0xc(%esp)
	      n2 = n1 >> b;
f010160b:	89 fd                	mov    %edi,%ebp
f010160d:	88 c1                	mov    %al,%cl
f010160f:	d3 ed                	shr    %cl,%ebp
	      n1 = (n1 << bm) | (n0 >> b);
f0101611:	89 fa                	mov    %edi,%edx
f0101613:	89 f1                	mov    %esi,%ecx
f0101615:	d3 e2                	shl    %cl,%edx
f0101617:	8b 7c 24 04          	mov    0x4(%esp),%edi
f010161b:	88 c1                	mov    %al,%cl
f010161d:	d3 ef                	shr    %cl,%edi
f010161f:	09 d7                	or     %edx,%edi
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
f0101621:	89 f8                	mov    %edi,%eax
f0101623:	89 ea                	mov    %ebp,%edx
f0101625:	f7 74 24 08          	divl   0x8(%esp)
f0101629:	89 d1                	mov    %edx,%ecx
f010162b:	89 c7                	mov    %eax,%edi
	      umul_ppmm (m1, m0, q0, d0);
f010162d:	f7 64 24 0c          	mull   0xc(%esp)

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0101631:	39 d1                	cmp    %edx,%ecx
f0101633:	72 17                	jb     f010164c <__udivdi3+0x10c>
f0101635:	74 09                	je     f0101640 <__udivdi3+0x100>
f0101637:	89 fe                	mov    %edi,%esi
f0101639:	31 ff                	xor    %edi,%edi
f010163b:	e9 41 ff ff ff       	jmp    f0101581 <__udivdi3+0x41>

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
	      n0 = n0 << bm;
f0101640:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101644:	89 f1                	mov    %esi,%ecx
f0101646:	d3 e2                	shl    %cl,%edx

	      udiv_qrnnd (q0, n1, n2, n1, d1);
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0101648:	39 c2                	cmp    %eax,%edx
f010164a:	73 eb                	jae    f0101637 <__udivdi3+0xf7>
		{
		  q0--;
f010164c:	8d 77 ff             	lea    -0x1(%edi),%esi
		  sub_ddmmss (m1, m0, m1, m0, d1, d0);
f010164f:	31 ff                	xor    %edi,%edi
f0101651:	e9 2b ff ff ff       	jmp    f0101581 <__udivdi3+0x41>
f0101656:	66 90                	xchg   %ax,%ax

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f0101658:	31 f6                	xor    %esi,%esi
f010165a:	e9 22 ff ff ff       	jmp    f0101581 <__udivdi3+0x41>
	...

f0101660 <__umoddi3>:
#endif

#ifdef L_umoddi3
UDWtype
__umoddi3 (UDWtype u, UDWtype v)
{
f0101660:	55                   	push   %ebp
f0101661:	57                   	push   %edi
f0101662:	56                   	push   %esi
f0101663:	83 ec 20             	sub    $0x20,%esp
f0101666:	8b 44 24 30          	mov    0x30(%esp),%eax
f010166a:	8b 4c 24 38          	mov    0x38(%esp),%ecx
static inline __attribute__ ((__always_inline__))
#endif
UDWtype
__udivmoddi4 (UDWtype n, UDWtype d, UDWtype *rp)
{
  const DWunion nn = {.ll = n};
f010166e:	89 44 24 14          	mov    %eax,0x14(%esp)
f0101672:	8b 74 24 34          	mov    0x34(%esp),%esi
  const DWunion dd = {.ll = d};
f0101676:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010167a:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
  UWtype q0, q1;
  UWtype b, bm;

  d0 = dd.s.low;
  d1 = dd.s.high;
  n0 = nn.s.low;
f010167e:	89 c7                	mov    %eax,%edi
  n1 = nn.s.high;
f0101680:	89 f2                	mov    %esi,%edx

#if !UDIV_NEEDS_NORMALIZATION
  if (d1 == 0)
f0101682:	85 ed                	test   %ebp,%ebp
f0101684:	75 16                	jne    f010169c <__umoddi3+0x3c>
    {
      if (d0 > n1)
f0101686:	39 f1                	cmp    %esi,%ecx
f0101688:	0f 86 a6 00 00 00    	jbe    f0101734 <__umoddi3+0xd4>

	  if (d0 == 0)
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */

	  udiv_qrnnd (q1, n1, 0, n1, d0);
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f010168e:	f7 f1                	div    %ecx

      if (rp != 0)
	{
	  rr.s.low = n0;
	  rr.s.high = 0;
	  *rp = rr.ll;
f0101690:	89 d0                	mov    %edx,%eax
f0101692:	31 d2                	xor    %edx,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f0101694:	83 c4 20             	add    $0x20,%esp
f0101697:	5e                   	pop    %esi
f0101698:	5f                   	pop    %edi
f0101699:	5d                   	pop    %ebp
f010169a:	c3                   	ret    
f010169b:	90                   	nop
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f010169c:	39 f5                	cmp    %esi,%ebp
f010169e:	0f 87 ac 00 00 00    	ja     f0101750 <__umoddi3+0xf0>
	}
      else
	{
	  /* 0q = NN / dd */

	  count_leading_zeros (bm, d1);
f01016a4:	0f bd c5             	bsr    %ebp,%eax
	  if (bm == 0)
f01016a7:	83 f0 1f             	xor    $0x1f,%eax
f01016aa:	89 44 24 10          	mov    %eax,0x10(%esp)
f01016ae:	0f 84 a8 00 00 00    	je     f010175c <__umoddi3+0xfc>
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
f01016b4:	8a 4c 24 10          	mov    0x10(%esp),%cl
f01016b8:	d3 e5                	shl    %cl,%ebp
	  else
	    {
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;
f01016ba:	bf 20 00 00 00       	mov    $0x20,%edi
f01016bf:	2b 7c 24 10          	sub    0x10(%esp),%edi

	      d1 = (d1 << bm) | (d0 >> b);
f01016c3:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01016c7:	89 f9                	mov    %edi,%ecx
f01016c9:	d3 e8                	shr    %cl,%eax
f01016cb:	09 e8                	or     %ebp,%eax
f01016cd:	89 44 24 18          	mov    %eax,0x18(%esp)
	      d0 = d0 << bm;
f01016d1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01016d5:	8a 4c 24 10          	mov    0x10(%esp),%cl
f01016d9:	d3 e0                	shl    %cl,%eax
f01016db:	89 44 24 0c          	mov    %eax,0xc(%esp)
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
f01016df:	89 f2                	mov    %esi,%edx
f01016e1:	d3 e2                	shl    %cl,%edx
	      n0 = n0 << bm;
f01016e3:	8b 44 24 14          	mov    0x14(%esp),%eax
f01016e7:	d3 e0                	shl    %cl,%eax
f01016e9:	89 44 24 1c          	mov    %eax,0x1c(%esp)
	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
f01016ed:	8b 44 24 14          	mov    0x14(%esp),%eax
f01016f1:	89 f9                	mov    %edi,%ecx
f01016f3:	d3 e8                	shr    %cl,%eax
f01016f5:	09 d0                	or     %edx,%eax

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
f01016f7:	d3 ee                	shr    %cl,%esi
	      n1 = (n1 << bm) | (n0 >> b);
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
f01016f9:	89 f2                	mov    %esi,%edx
f01016fb:	f7 74 24 18          	divl   0x18(%esp)
f01016ff:	89 d6                	mov    %edx,%esi
	      umul_ppmm (m1, m0, q0, d0);
f0101701:	f7 64 24 0c          	mull   0xc(%esp)
f0101705:	89 c5                	mov    %eax,%ebp
f0101707:	89 d1                	mov    %edx,%ecx

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0101709:	39 d6                	cmp    %edx,%esi
f010170b:	72 67                	jb     f0101774 <__umoddi3+0x114>
f010170d:	74 75                	je     f0101784 <__umoddi3+0x124>
	      q1 = 0;

	      /* Remainder in (n1n0 - m1m0) >> bm.  */
	      if (rp != 0)
		{
		  sub_ddmmss (n1, n0, n1, n0, m1, m0);
f010170f:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0101713:	29 e8                	sub    %ebp,%eax
f0101715:	19 ce                	sbb    %ecx,%esi
		  rr.s.low = (n1 << b) | (n0 >> bm);
f0101717:	8a 4c 24 10          	mov    0x10(%esp),%cl
f010171b:	d3 e8                	shr    %cl,%eax
f010171d:	89 f2                	mov    %esi,%edx
f010171f:	89 f9                	mov    %edi,%ecx
f0101721:	d3 e2                	shl    %cl,%edx
		  rr.s.high = n1 >> bm;
		  *rp = rr.ll;
f0101723:	09 d0                	or     %edx,%eax
f0101725:	89 f2                	mov    %esi,%edx
f0101727:	8a 4c 24 10          	mov    0x10(%esp),%cl
f010172b:	d3 ea                	shr    %cl,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f010172d:	83 c4 20             	add    $0x20,%esp
f0101730:	5e                   	pop    %esi
f0101731:	5f                   	pop    %edi
f0101732:	5d                   	pop    %ebp
f0101733:	c3                   	ret    
	}
      else
	{
	  /* qq = NN / 0d */

	  if (d0 == 0)
f0101734:	85 c9                	test   %ecx,%ecx
f0101736:	75 0b                	jne    f0101743 <__umoddi3+0xe3>
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */
f0101738:	b8 01 00 00 00       	mov    $0x1,%eax
f010173d:	31 d2                	xor    %edx,%edx
f010173f:	f7 f1                	div    %ecx
f0101741:	89 c1                	mov    %eax,%ecx

	  udiv_qrnnd (q1, n1, 0, n1, d0);
f0101743:	89 f0                	mov    %esi,%eax
f0101745:	31 d2                	xor    %edx,%edx
f0101747:	f7 f1                	div    %ecx
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f0101749:	89 f8                	mov    %edi,%eax
f010174b:	e9 3e ff ff ff       	jmp    f010168e <__umoddi3+0x2e>
	  /* Remainder in n1n0.  */
	  if (rp != 0)
	    {
	      rr.s.low = n0;
	      rr.s.high = n1;
	      *rp = rr.ll;
f0101750:	89 f2                	mov    %esi,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f0101752:	83 c4 20             	add    $0x20,%esp
f0101755:	5e                   	pop    %esi
f0101756:	5f                   	pop    %edi
f0101757:	5d                   	pop    %ebp
f0101758:	c3                   	ret    
f0101759:	8d 76 00             	lea    0x0(%esi),%esi

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f010175c:	39 f5                	cmp    %esi,%ebp
f010175e:	72 04                	jb     f0101764 <__umoddi3+0x104>
f0101760:	39 f9                	cmp    %edi,%ecx
f0101762:	77 06                	ja     f010176a <__umoddi3+0x10a>
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f0101764:	89 f2                	mov    %esi,%edx
f0101766:	29 cf                	sub    %ecx,%edi
f0101768:	19 ea                	sbb    %ebp,%edx

	      if (rp != 0)
		{
		  rr.s.low = n0;
		  rr.s.high = n1;
		  *rp = rr.ll;
f010176a:	89 f8                	mov    %edi,%eax
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f010176c:	83 c4 20             	add    $0x20,%esp
f010176f:	5e                   	pop    %esi
f0101770:	5f                   	pop    %edi
f0101771:	5d                   	pop    %ebp
f0101772:	c3                   	ret    
f0101773:	90                   	nop
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
		{
		  q0--;
		  sub_ddmmss (m1, m0, m1, m0, d1, d0);
f0101774:	89 d1                	mov    %edx,%ecx
f0101776:	89 c5                	mov    %eax,%ebp
f0101778:	2b 6c 24 0c          	sub    0xc(%esp),%ebp
f010177c:	1b 4c 24 18          	sbb    0x18(%esp),%ecx
f0101780:	eb 8d                	jmp    f010170f <__umoddi3+0xaf>
f0101782:	66 90                	xchg   %ax,%ax
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0101784:	39 44 24 1c          	cmp    %eax,0x1c(%esp)
f0101788:	72 ea                	jb     f0101774 <__umoddi3+0x114>
f010178a:	89 f1                	mov    %esi,%ecx
f010178c:	eb 81                	jmp    f010170f <__umoddi3+0xaf>
