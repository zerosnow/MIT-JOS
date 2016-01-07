
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		_start
_start:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fb                   	sti    
f0100009:	4f                   	dec    %edi
f010000a:	52                   	push   %edx
f010000b:	e4 66                	in     $0x66,%al

f010000c <_start>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 

	# Establish our own GDT in place of the boot loader's temporary GDT.
	lgdt	RELOC(mygdtdesc)		# load descriptor table
f0100015:	0f 01 15 18 50 11 00 	lgdtl  0x115018

	# Immediately reload all segment registers (including CS!)
	# with segment selectors from the new GDT.
	movl	$DATA_SEL, %eax			# Data segment selector
f010001c:	b8 10 00 00 00       	mov    $0x10,%eax
	movw	%ax,%ds				# -> DS: Data Segment
f0100021:	8e d8                	mov    %eax,%ds
	movw	%ax,%es				# -> ES: Extra Segment
f0100023:	8e c0                	mov    %eax,%es
	movw	%ax,%ss				# -> SS: Stack Segment
f0100025:	8e d0                	mov    %eax,%ss
	ljmp	$CODE_SEL,$relocated		# reload CS by jumping
f0100027:	ea 2e 00 10 f0 08 00 	ljmp   $0x8,$0xf010002e

f010002e <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002e:	bd 00 00 00 00       	mov    $0x0,%ebp

        # Set the stack pointer
	movl	$(bootstacktop),%esp
f0100033:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100038:	e8 02 00 00 00       	call   f010003f <i386_init>

f010003d <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003d:	eb fe                	jmp    f010003d <spin>

f010003f <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f010003f:	55                   	push   %ebp
f0100040:	89 e5                	mov    %esp,%ebp
f0100042:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100045:	b8 10 5a 11 f0       	mov    $0xf0115a10,%eax
f010004a:	2d 70 53 11 f0       	sub    $0xf0115370,%eax
f010004f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100053:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005a:	00 
f010005b:	c7 04 24 70 53 11 f0 	movl   $0xf0115370,(%esp)
f0100062:	e8 a8 34 00 00       	call   f010350f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100067:	e8 80 05 00 00       	call   f01005ec <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006c:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100073:	00 
f0100074:	c7 04 24 a0 39 10 f0 	movl   $0xf01039a0,(%esp)
f010007b:	e8 19 29 00 00       	call   f0102999 <cprintf>

	// Lab 2 memory management initialization functions
	i386_detect_memory();
f0100080:	e8 b6 09 00 00       	call   f0100a3b <i386_detect_memory>
	i386_vm_init();
f0100085:	e8 14 0f 00 00       	call   f0100f9e <i386_vm_init>



	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100091:	e8 cc 06 00 00       	call   f0100762 <monitor>
f0100096:	eb f2                	jmp    f010008a <i386_init+0x4b>

f0100098 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100098:	55                   	push   %ebp
f0100099:	89 e5                	mov    %esp,%ebp
f010009b:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	if (panicstr)
f010009e:	83 3d 80 53 11 f0 00 	cmpl   $0x0,0xf0115380
f01000a5:	75 40                	jne    f01000e7 <_panic+0x4f>
		goto dead;
	panicstr = fmt;
f01000a7:	8b 45 10             	mov    0x10(%ebp),%eax
f01000aa:	a3 80 53 11 f0       	mov    %eax,0xf0115380

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
f01000af:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01000b9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000bd:	c7 04 24 bb 39 10 f0 	movl   $0xf01039bb,(%esp)
f01000c4:	e8 d0 28 00 00       	call   f0102999 <cprintf>
	vcprintf(fmt, ap);
f01000c9:	8d 45 14             	lea    0x14(%ebp),%eax
f01000cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000d0:	8b 45 10             	mov    0x10(%ebp),%eax
f01000d3:	89 04 24             	mov    %eax,(%esp)
f01000d6:	e8 8b 28 00 00       	call   f0102966 <vcprintf>
	cprintf("\n");
f01000db:	c7 04 24 4b 45 10 f0 	movl   $0xf010454b,(%esp)
f01000e2:	e8 b2 28 00 00       	call   f0102999 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ee:	e8 6f 06 00 00       	call   f0100762 <monitor>
f01000f3:	eb f2                	jmp    f01000e7 <_panic+0x4f>

f01000f5 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f5:	55                   	push   %ebp
f01000f6:	89 e5                	mov    %esp,%ebp
f01000f8:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000fe:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100102:	8b 45 08             	mov    0x8(%ebp),%eax
f0100105:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100109:	c7 04 24 d3 39 10 f0 	movl   $0xf01039d3,(%esp)
f0100110:	e8 84 28 00 00       	call   f0102999 <cprintf>
	vcprintf(fmt, ap);
f0100115:	8d 45 14             	lea    0x14(%ebp),%eax
f0100118:	89 44 24 04          	mov    %eax,0x4(%esp)
f010011c:	8b 45 10             	mov    0x10(%ebp),%eax
f010011f:	89 04 24             	mov    %eax,(%esp)
f0100122:	e8 3f 28 00 00       	call   f0102966 <vcprintf>
	cprintf("\n");
f0100127:	c7 04 24 4b 45 10 f0 	movl   $0xf010454b,(%esp)
f010012e:	e8 66 28 00 00       	call   f0102999 <cprintf>
	va_end(ap);
}
f0100133:	c9                   	leave  
f0100134:	c3                   	ret    
f0100135:	66 90                	xchg   %ax,%ax
f0100137:	66 90                	xchg   %ax,%ax
f0100139:	66 90                	xchg   %ax,%ax
f010013b:	66 90                	xchg   %ax,%ax
f010013d:	66 90                	xchg   %ax,%ax
f010013f:	90                   	nop

f0100140 <serial_proc_data>:

static bool serial_exists;

int
serial_proc_data(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100148:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100149:	a8 01                	test   $0x1,%al
f010014b:	74 08                	je     f0100155 <serial_proc_data+0x15>
f010014d:	b2 f8                	mov    $0xf8,%dl
f010014f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100150:	0f b6 c0             	movzbl %al,%eax
f0100153:	eb 05                	jmp    f010015a <serial_proc_data+0x1a>

int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100155:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010015a:	5d                   	pop    %ebp
f010015b:	c3                   	ret    

f010015c <kbd_proc_data>:
f010015c:	ba 64 00 00 00       	mov    $0x64,%edx
f0100161:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100162:	a8 01                	test   $0x1,%al
f0100164:	0f 84 ef 00 00 00    	je     f0100259 <kbd_proc_data+0xfd>
f010016a:	b2 60                	mov    $0x60,%dl
f010016c:	ec                   	in     (%dx),%al
f010016d:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010016f:	3c e0                	cmp    $0xe0,%al
f0100171:	75 0d                	jne    f0100180 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100173:	83 0d a0 53 11 f0 40 	orl    $0x40,0xf01153a0
		return 0;
f010017a:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010017f:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100180:	55                   	push   %ebp
f0100181:	89 e5                	mov    %esp,%ebp
f0100183:	53                   	push   %ebx
f0100184:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100187:	84 c0                	test   %al,%al
f0100189:	79 37                	jns    f01001c2 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010018b:	8b 0d a0 53 11 f0    	mov    0xf01153a0,%ecx
f0100191:	89 cb                	mov    %ecx,%ebx
f0100193:	83 e3 40             	and    $0x40,%ebx
f0100196:	83 e0 7f             	and    $0x7f,%eax
f0100199:	85 db                	test   %ebx,%ebx
f010019b:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010019e:	0f b6 d2             	movzbl %dl,%edx
f01001a1:	0f b6 82 40 3b 10 f0 	movzbl -0xfefc4c0(%edx),%eax
f01001a8:	83 c8 40             	or     $0x40,%eax
f01001ab:	0f b6 c0             	movzbl %al,%eax
f01001ae:	f7 d0                	not    %eax
f01001b0:	21 c1                	and    %eax,%ecx
f01001b2:	89 0d a0 53 11 f0    	mov    %ecx,0xf01153a0
		return 0;
f01001b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01001bd:	e9 9d 00 00 00       	jmp    f010025f <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f01001c2:	8b 0d a0 53 11 f0    	mov    0xf01153a0,%ecx
f01001c8:	f6 c1 40             	test   $0x40,%cl
f01001cb:	74 0e                	je     f01001db <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001cd:	83 c8 80             	or     $0xffffff80,%eax
f01001d0:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001d2:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001d5:	89 0d a0 53 11 f0    	mov    %ecx,0xf01153a0
	}

	shift |= shiftcode[data];
f01001db:	0f b6 d2             	movzbl %dl,%edx
f01001de:	0f b6 82 40 3b 10 f0 	movzbl -0xfefc4c0(%edx),%eax
f01001e5:	0b 05 a0 53 11 f0    	or     0xf01153a0,%eax
	shift ^= togglecode[data];
f01001eb:	0f b6 8a 40 3a 10 f0 	movzbl -0xfefc5c0(%edx),%ecx
f01001f2:	31 c8                	xor    %ecx,%eax
f01001f4:	a3 a0 53 11 f0       	mov    %eax,0xf01153a0

	c = charcode[shift & (CTL | SHIFT)][data];
f01001f9:	89 c1                	mov    %eax,%ecx
f01001fb:	83 e1 03             	and    $0x3,%ecx
f01001fe:	8b 0c 8d 20 3a 10 f0 	mov    -0xfefc5e0(,%ecx,4),%ecx
f0100205:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100209:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010020c:	a8 08                	test   $0x8,%al
f010020e:	74 1b                	je     f010022b <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f0100210:	89 da                	mov    %ebx,%edx
f0100212:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100215:	83 f9 19             	cmp    $0x19,%ecx
f0100218:	77 05                	ja     f010021f <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f010021a:	83 eb 20             	sub    $0x20,%ebx
f010021d:	eb 0c                	jmp    f010022b <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f010021f:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100222:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100225:	83 fa 19             	cmp    $0x19,%edx
f0100228:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010022b:	f7 d0                	not    %eax
f010022d:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010022f:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100231:	f6 c2 06             	test   $0x6,%dl
f0100234:	75 29                	jne    f010025f <kbd_proc_data+0x103>
f0100236:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010023c:	75 21                	jne    f010025f <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f010023e:	c7 04 24 ed 39 10 f0 	movl   $0xf01039ed,(%esp)
f0100245:	e8 4f 27 00 00       	call   f0102999 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010024a:	ba 92 00 00 00       	mov    $0x92,%edx
f010024f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100254:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100255:	89 d8                	mov    %ebx,%eax
f0100257:	eb 06                	jmp    f010025f <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100259:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010025e:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010025f:	83 c4 14             	add    $0x14,%esp
f0100262:	5b                   	pop    %ebx
f0100263:	5d                   	pop    %ebp
f0100264:	c3                   	ret    

f0100265 <serial_init>:
		cons_intr(serial_proc_data);
}

void
serial_init(void)
{
f0100265:	55                   	push   %ebp
f0100266:	89 e5                	mov    %esp,%ebp
f0100268:	53                   	push   %ebx
f0100269:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f010026e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100273:	89 da                	mov    %ebx,%edx
f0100275:	ee                   	out    %al,(%dx)
f0100276:	b2 fb                	mov    $0xfb,%dl
f0100278:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010027d:	ee                   	out    %al,(%dx)
f010027e:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f0100283:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100288:	89 ca                	mov    %ecx,%edx
f010028a:	ee                   	out    %al,(%dx)
f010028b:	b2 f9                	mov    $0xf9,%dl
f010028d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100292:	ee                   	out    %al,(%dx)
f0100293:	b2 fb                	mov    $0xfb,%dl
f0100295:	b8 03 00 00 00       	mov    $0x3,%eax
f010029a:	ee                   	out    %al,(%dx)
f010029b:	b2 fc                	mov    $0xfc,%dl
f010029d:	b8 00 00 00 00       	mov    $0x0,%eax
f01002a2:	ee                   	out    %al,(%dx)
f01002a3:	b2 f9                	mov    $0xf9,%dl
f01002a5:	b8 01 00 00 00       	mov    $0x1,%eax
f01002aa:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ab:	b2 fd                	mov    $0xfd,%dl
f01002ad:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01002ae:	3c ff                	cmp    $0xff,%al
f01002b0:	0f 95 c0             	setne  %al
f01002b3:	0f b6 c0             	movzbl %al,%eax
f01002b6:	a3 d4 55 11 f0       	mov    %eax,0xf01155d4
f01002bb:	89 da                	mov    %ebx,%edx
f01002bd:	ec                   	in     (%dx),%al
f01002be:	89 ca                	mov    %ecx,%edx
f01002c0:	ec                   	in     (%dx),%al
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

}
f01002c1:	5b                   	pop    %ebx
f01002c2:	5d                   	pop    %ebp
f01002c3:	c3                   	ret    

f01002c4 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
cga_init(void)
{
f01002c4:	55                   	push   %ebp
f01002c5:	89 e5                	mov    %esp,%ebp
f01002c7:	57                   	push   %edi
f01002c8:	56                   	push   %esi
f01002c9:	53                   	push   %ebx
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01002ca:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01002d1:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01002d8:	5a a5 
	if (*cp != 0xA55A) {
f01002da:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01002e1:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01002e5:	74 11                	je     f01002f8 <cga_init+0x34>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01002e7:	c7 05 d0 55 11 f0 b4 	movl   $0x3b4,0xf01155d0
f01002ee:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01002f1:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01002f6:	eb 16                	jmp    f010030e <cga_init+0x4a>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01002f8:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01002ff:	c7 05 d0 55 11 f0 d4 	movl   $0x3d4,0xf01155d0
f0100306:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100309:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f010030e:	8b 0d d0 55 11 f0    	mov    0xf01155d0,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100314:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100319:	89 ca                	mov    %ecx,%edx
f010031b:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010031c:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010031f:	89 da                	mov    %ebx,%edx
f0100321:	ec                   	in     (%dx),%al
f0100322:	0f b6 f0             	movzbl %al,%esi
f0100325:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100328:	b8 0f 00 00 00       	mov    $0xf,%eax
f010032d:	89 ca                	mov    %ecx,%edx
f010032f:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100330:	89 da                	mov    %ebx,%edx
f0100332:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100333:	89 3d cc 55 11 f0    	mov    %edi,0xf01155cc
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100339:	0f b6 d8             	movzbl %al,%ebx
f010033c:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010033e:	66 89 35 c8 55 11 f0 	mov    %si,0xf01155c8
}
f0100345:	5b                   	pop    %ebx
f0100346:	5e                   	pop    %esi
f0100347:	5f                   	pop    %edi
f0100348:	5d                   	pop    %ebp
f0100349:	c3                   	ret    

f010034a <kbd_init>:
	cons_intr(kbd_proc_data);
}

void
kbd_init(void)
{
f010034a:	55                   	push   %ebp
f010034b:	89 e5                	mov    %esp,%ebp
}
f010034d:	5d                   	pop    %ebp
f010034e:	c3                   	ret    

f010034f <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
f010034f:	55                   	push   %ebp
f0100350:	89 e5                	mov    %esp,%ebp
f0100352:	53                   	push   %ebx
f0100353:	83 ec 04             	sub    $0x4,%esp
f0100356:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100359:	eb 2b                	jmp    f0100386 <cons_intr+0x37>
		if (c == 0)
f010035b:	85 c0                	test   %eax,%eax
f010035d:	74 27                	je     f0100386 <cons_intr+0x37>
			continue;
		cons.buf[cons.wpos++] = c;
f010035f:	8b 0d c4 55 11 f0    	mov    0xf01155c4,%ecx
f0100365:	8d 51 01             	lea    0x1(%ecx),%edx
f0100368:	89 15 c4 55 11 f0    	mov    %edx,0xf01155c4
f010036e:	88 81 c0 53 11 f0    	mov    %al,-0xfeeac40(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100374:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010037a:	75 0a                	jne    f0100386 <cons_intr+0x37>
			cons.wpos = 0;
f010037c:	c7 05 c4 55 11 f0 00 	movl   $0x0,0xf01155c4
f0100383:	00 00 00 
void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100386:	ff d3                	call   *%ebx
f0100388:	83 f8 ff             	cmp    $0xffffffff,%eax
f010038b:	75 ce                	jne    f010035b <cons_intr+0xc>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010038d:	83 c4 04             	add    $0x4,%esp
f0100390:	5b                   	pop    %ebx
f0100391:	5d                   	pop    %ebp
f0100392:	c3                   	ret    

f0100393 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100393:	83 3d d4 55 11 f0 00 	cmpl   $0x0,0xf01155d4
f010039a:	74 13                	je     f01003af <serial_intr+0x1c>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010039c:	55                   	push   %ebp
f010039d:	89 e5                	mov    %esp,%ebp
f010039f:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01003a2:	c7 04 24 40 01 10 f0 	movl   $0xf0100140,(%esp)
f01003a9:	e8 a1 ff ff ff       	call   f010034f <cons_intr>
}
f01003ae:	c9                   	leave  
f01003af:	f3 c3                	repz ret 

f01003b1 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01003b1:	55                   	push   %ebp
f01003b2:	89 e5                	mov    %esp,%ebp
f01003b4:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
f01003b7:	c7 04 24 5c 01 10 f0 	movl   $0xf010015c,(%esp)
f01003be:	e8 8c ff ff ff       	call   f010034f <cons_intr>
}
f01003c3:	c9                   	leave  
f01003c4:	c3                   	ret    

f01003c5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01003c5:	55                   	push   %ebp
f01003c6:	89 e5                	mov    %esp,%ebp
f01003c8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01003cb:	e8 c3 ff ff ff       	call   f0100393 <serial_intr>
	kbd_intr();
f01003d0:	e8 dc ff ff ff       	call   f01003b1 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01003d5:	a1 c0 55 11 f0       	mov    0xf01155c0,%eax
f01003da:	3b 05 c4 55 11 f0    	cmp    0xf01155c4,%eax
f01003e0:	74 26                	je     f0100408 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01003e2:	8d 50 01             	lea    0x1(%eax),%edx
f01003e5:	89 15 c0 55 11 f0    	mov    %edx,0xf01155c0
f01003eb:	0f b6 88 c0 53 11 f0 	movzbl -0xfeeac40(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01003f2:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01003f4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01003fa:	75 11                	jne    f010040d <cons_getc+0x48>
			cons.rpos = 0;
f01003fc:	c7 05 c0 55 11 f0 00 	movl   $0x0,0xf01155c0
f0100403:	00 00 00 
f0100406:	eb 05                	jmp    f010040d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100408:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010040d:	c9                   	leave  
f010040e:	c3                   	ret    

f010040f <cons_putc>:

// output a character to the console
void
cons_putc(int c)
{
f010040f:	55                   	push   %ebp
f0100410:	89 e5                	mov    %esp,%ebp
f0100412:	57                   	push   %edi
f0100413:	56                   	push   %esi
f0100414:	53                   	push   %ebx
f0100415:	83 ec 1c             	sub    $0x1c,%esp
f0100418:	8b 7d 08             	mov    0x8(%ebp),%edi
f010041b:	ba 79 03 00 00       	mov    $0x379,%edx
f0100420:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100421:	84 c0                	test   %al,%al
f0100423:	78 21                	js     f0100446 <cons_putc+0x37>
f0100425:	bb 00 32 00 00       	mov    $0x3200,%ebx
f010042a:	b9 84 00 00 00       	mov    $0x84,%ecx
f010042f:	be 79 03 00 00       	mov    $0x379,%esi
f0100434:	89 ca                	mov    %ecx,%edx
f0100436:	ec                   	in     (%dx),%al
f0100437:	ec                   	in     (%dx),%al
f0100438:	ec                   	in     (%dx),%al
f0100439:	ec                   	in     (%dx),%al
f010043a:	89 f2                	mov    %esi,%edx
f010043c:	ec                   	in     (%dx),%al
f010043d:	84 c0                	test   %al,%al
f010043f:	78 05                	js     f0100446 <cons_putc+0x37>
f0100441:	83 eb 01             	sub    $0x1,%ebx
f0100444:	75 ee                	jne    f0100434 <cons_putc+0x25>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100446:	ba 78 03 00 00       	mov    $0x378,%edx
f010044b:	89 f8                	mov    %edi,%eax
f010044d:	ee                   	out    %al,(%dx)
f010044e:	b2 7a                	mov    $0x7a,%dl
f0100450:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100455:	ee                   	out    %al,(%dx)
f0100456:	b8 08 00 00 00       	mov    $0x8,%eax
f010045b:	ee                   	out    %al,(%dx)
// output a character to the console
void
cons_putc(int c)
{
	lpt_putc(c);
	cga_putc(c);
f010045c:	89 3c 24             	mov    %edi,(%esp)
f010045f:	e8 08 00 00 00       	call   f010046c <cga_putc>
}
f0100464:	83 c4 1c             	add    $0x1c,%esp
f0100467:	5b                   	pop    %ebx
f0100468:	5e                   	pop    %esi
f0100469:	5f                   	pop    %edi
f010046a:	5d                   	pop    %ebp
f010046b:	c3                   	ret    

f010046c <cga_putc>:



void
cga_putc(int c)
{
f010046c:	55                   	push   %ebp
f010046d:	89 e5                	mov    %esp,%ebp
f010046f:	56                   	push   %esi
f0100470:	53                   	push   %ebx
f0100471:	83 ec 10             	sub    $0x10,%esp
f0100474:	8b 45 08             	mov    0x8(%ebp),%eax
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100477:	89 c1                	mov    %eax,%ecx
f0100479:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f010047f:	89 c2                	mov    %eax,%edx
f0100481:	80 ce 07             	or     $0x7,%dh
f0100484:	85 c9                	test   %ecx,%ecx
f0100486:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f0100489:	0f b6 d0             	movzbl %al,%edx
f010048c:	83 fa 09             	cmp    $0x9,%edx
f010048f:	74 7d                	je     f010050e <cga_putc+0xa2>
f0100491:	83 fa 09             	cmp    $0x9,%edx
f0100494:	7f 0f                	jg     f01004a5 <cga_putc+0x39>
f0100496:	83 fa 08             	cmp    $0x8,%edx
f0100499:	74 1c                	je     f01004b7 <cga_putc+0x4b>
f010049b:	90                   	nop
f010049c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01004a0:	e9 a7 00 00 00       	jmp    f010054c <cga_putc+0xe0>
f01004a5:	83 fa 0a             	cmp    $0xa,%edx
f01004a8:	74 3e                	je     f01004e8 <cga_putc+0x7c>
f01004aa:	83 fa 0d             	cmp    $0xd,%edx
f01004ad:	8d 76 00             	lea    0x0(%esi),%esi
f01004b0:	74 3e                	je     f01004f0 <cga_putc+0x84>
f01004b2:	e9 95 00 00 00       	jmp    f010054c <cga_putc+0xe0>
	case '\b':
		if (crt_pos > 0) {
f01004b7:	0f b7 15 c8 55 11 f0 	movzwl 0xf01155c8,%edx
f01004be:	66 85 d2             	test   %dx,%dx
f01004c1:	0f 84 f0 00 00 00    	je     f01005b7 <cga_putc+0x14b>
			crt_pos--;
f01004c7:	83 ea 01             	sub    $0x1,%edx
f01004ca:	66 89 15 c8 55 11 f0 	mov    %dx,0xf01155c8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004d1:	0f b7 d2             	movzwl %dx,%edx
f01004d4:	b0 00                	mov    $0x0,%al
f01004d6:	83 c8 20             	or     $0x20,%eax
f01004d9:	8b 0d cc 55 11 f0    	mov    0xf01155cc,%ecx
f01004df:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f01004e3:	e9 82 00 00 00       	jmp    f010056a <cga_putc+0xfe>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004e8:	66 83 05 c8 55 11 f0 	addw   $0x50,0xf01155c8
f01004ef:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004f0:	0f b7 05 c8 55 11 f0 	movzwl 0xf01155c8,%eax
f01004f7:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004fd:	c1 e8 16             	shr    $0x16,%eax
f0100500:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100503:	c1 e0 04             	shl    $0x4,%eax
f0100506:	66 a3 c8 55 11 f0    	mov    %ax,0xf01155c8
		break;
f010050c:	eb 5c                	jmp    f010056a <cga_putc+0xfe>
	case '\t':
		cons_putc(' ');
f010050e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100515:	e8 f5 fe ff ff       	call   f010040f <cons_putc>
		cons_putc(' ');
f010051a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100521:	e8 e9 fe ff ff       	call   f010040f <cons_putc>
		cons_putc(' ');
f0100526:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010052d:	e8 dd fe ff ff       	call   f010040f <cons_putc>
		cons_putc(' ');
f0100532:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100539:	e8 d1 fe ff ff       	call   f010040f <cons_putc>
		cons_putc(' ');
f010053e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100545:	e8 c5 fe ff ff       	call   f010040f <cons_putc>
		break;
f010054a:	eb 1e                	jmp    f010056a <cga_putc+0xfe>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010054c:	0f b7 15 c8 55 11 f0 	movzwl 0xf01155c8,%edx
f0100553:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100556:	66 89 0d c8 55 11 f0 	mov    %cx,0xf01155c8
f010055d:	0f b7 d2             	movzwl %dx,%edx
f0100560:	8b 0d cc 55 11 f0    	mov    0xf01155cc,%ecx
f0100566:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010056a:	66 81 3d c8 55 11 f0 	cmpw   $0x7cf,0xf01155c8
f0100571:	cf 07 
f0100573:	76 42                	jbe    f01005b7 <cga_putc+0x14b>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100575:	a1 cc 55 11 f0       	mov    0xf01155cc,%eax
f010057a:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100581:	00 
f0100582:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100588:	89 54 24 04          	mov    %edx,0x4(%esp)
f010058c:	89 04 24             	mov    %eax,(%esp)
f010058f:	e8 a0 2f 00 00       	call   f0103534 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100594:	8b 15 cc 55 11 f0    	mov    0xf01155cc,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010059a:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010059f:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005a5:	83 c0 01             	add    $0x1,%eax
f01005a8:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01005ad:	75 f0                	jne    f010059f <cga_putc+0x133>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01005af:	66 83 2d c8 55 11 f0 	subw   $0x50,0xf01155c8
f01005b6:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005b7:	8b 0d d0 55 11 f0    	mov    0xf01155d0,%ecx
f01005bd:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c2:	89 ca                	mov    %ecx,%edx
f01005c4:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005c5:	0f b7 1d c8 55 11 f0 	movzwl 0xf01155c8,%ebx
f01005cc:	8d 71 01             	lea    0x1(%ecx),%esi
f01005cf:	89 d8                	mov    %ebx,%eax
f01005d1:	66 c1 e8 08          	shr    $0x8,%ax
f01005d5:	89 f2                	mov    %esi,%edx
f01005d7:	ee                   	out    %al,(%dx)
f01005d8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005dd:	89 ca                	mov    %ecx,%edx
f01005df:	ee                   	out    %al,(%dx)
f01005e0:	89 d8                	mov    %ebx,%eax
f01005e2:	89 f2                	mov    %esi,%edx
f01005e4:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
	outb(addr_6845 + 1, crt_pos);
}
f01005e5:	83 c4 10             	add    $0x10,%esp
f01005e8:	5b                   	pop    %ebx
f01005e9:	5e                   	pop    %esi
f01005ea:	5d                   	pop    %ebp
f01005eb:	c3                   	ret    

f01005ec <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01005ec:	55                   	push   %ebp
f01005ed:	89 e5                	mov    %esp,%ebp
f01005ef:	83 ec 18             	sub    $0x18,%esp
	cga_init();
f01005f2:	e8 cd fc ff ff       	call   f01002c4 <cga_init>
	kbd_init();
	serial_init();
f01005f7:	e8 69 fc ff ff       	call   f0100265 <serial_init>

	if (!serial_exists)
f01005fc:	83 3d d4 55 11 f0 00 	cmpl   $0x0,0xf01155d4
f0100603:	75 0c                	jne    f0100611 <cons_init+0x25>
		cprintf("Serial port does not exist!\n");
f0100605:	c7 04 24 f9 39 10 f0 	movl   $0xf01039f9,(%esp)
f010060c:	e8 88 23 00 00       	call   f0102999 <cprintf>
}
f0100611:	c9                   	leave  
f0100612:	c3                   	ret    

f0100613 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
f0100616:	83 ec 18             	sub    $0x18,%esp
	cons_putc(c);
f0100619:	8b 45 08             	mov    0x8(%ebp),%eax
f010061c:	89 04 24             	mov    %eax,(%esp)
f010061f:	e8 eb fd ff ff       	call   f010040f <cons_putc>
}
f0100624:	c9                   	leave  
f0100625:	c3                   	ret    

f0100626 <getchar>:

int
getchar(void)
{
f0100626:	55                   	push   %ebp
f0100627:	89 e5                	mov    %esp,%ebp
f0100629:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010062c:	e8 94 fd ff ff       	call   f01003c5 <cons_getc>
f0100631:	85 c0                	test   %eax,%eax
f0100633:	74 f7                	je     f010062c <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100635:	c9                   	leave  
f0100636:	c3                   	ret    

f0100637 <iscons>:

int
iscons(int fdnum)
{
f0100637:	55                   	push   %ebp
f0100638:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010063a:	b8 01 00 00 00       	mov    $0x1,%eax
f010063f:	5d                   	pop    %ebp
f0100640:	c3                   	ret    
f0100641:	66 90                	xchg   %ax,%ax
f0100643:	66 90                	xchg   %ax,%ax
f0100645:	66 90                	xchg   %ax,%ax
f0100647:	66 90                	xchg   %ax,%ax
f0100649:	66 90                	xchg   %ax,%ax
f010064b:	66 90                	xchg   %ax,%ax
f010064d:	66 90                	xchg   %ax,%ax
f010064f:	90                   	nop

f0100650 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100650:	55                   	push   %ebp
f0100651:	89 e5                	mov    %esp,%ebp
f0100653:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100656:	c7 44 24 08 40 3c 10 	movl   $0xf0103c40,0x8(%esp)
f010065d:	f0 
f010065e:	c7 44 24 04 5e 3c 10 	movl   $0xf0103c5e,0x4(%esp)
f0100665:	f0 
f0100666:	c7 04 24 63 3c 10 f0 	movl   $0xf0103c63,(%esp)
f010066d:	e8 27 23 00 00       	call   f0102999 <cprintf>
f0100672:	c7 44 24 08 f8 3c 10 	movl   $0xf0103cf8,0x8(%esp)
f0100679:	f0 
f010067a:	c7 44 24 04 6c 3c 10 	movl   $0xf0103c6c,0x4(%esp)
f0100681:	f0 
f0100682:	c7 04 24 63 3c 10 f0 	movl   $0xf0103c63,(%esp)
f0100689:	e8 0b 23 00 00       	call   f0102999 <cprintf>
f010068e:	c7 44 24 08 20 3d 10 	movl   $0xf0103d20,0x8(%esp)
f0100695:	f0 
f0100696:	c7 44 24 04 75 3c 10 	movl   $0xf0103c75,0x4(%esp)
f010069d:	f0 
f010069e:	c7 04 24 63 3c 10 f0 	movl   $0xf0103c63,(%esp)
f01006a5:	e8 ef 22 00 00       	call   f0102999 <cprintf>
	return 0;
}
f01006aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01006af:	c9                   	leave  
f01006b0:	c3                   	ret    

f01006b1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006b1:	55                   	push   %ebp
f01006b2:	89 e5                	mov    %esp,%ebp
f01006b4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006b7:	c7 04 24 7f 3c 10 f0 	movl   $0xf0103c7f,(%esp)
f01006be:	e8 d6 22 00 00       	call   f0102999 <cprintf>
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
f01006c3:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ca:	00 
f01006cb:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006d2:	f0 
f01006d3:	c7 04 24 44 3d 10 f0 	movl   $0xf0103d44,(%esp)
f01006da:	e8 ba 22 00 00       	call   f0102999 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006df:	c7 44 24 08 97 39 10 	movl   $0x103997,0x8(%esp)
f01006e6:	00 
f01006e7:	c7 44 24 04 97 39 10 	movl   $0xf0103997,0x4(%esp)
f01006ee:	f0 
f01006ef:	c7 04 24 68 3d 10 f0 	movl   $0xf0103d68,(%esp)
f01006f6:	e8 9e 22 00 00       	call   f0102999 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006fb:	c7 44 24 08 70 53 11 	movl   $0x115370,0x8(%esp)
f0100702:	00 
f0100703:	c7 44 24 04 70 53 11 	movl   $0xf0115370,0x4(%esp)
f010070a:	f0 
f010070b:	c7 04 24 8c 3d 10 f0 	movl   $0xf0103d8c,(%esp)
f0100712:	e8 82 22 00 00       	call   f0102999 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100717:	c7 44 24 08 10 5a 11 	movl   $0x115a10,0x8(%esp)
f010071e:	00 
f010071f:	c7 44 24 04 10 5a 11 	movl   $0xf0115a10,0x4(%esp)
f0100726:	f0 
f0100727:	c7 04 24 b0 3d 10 f0 	movl   $0xf0103db0,(%esp)
f010072e:	e8 66 22 00 00       	call   f0102999 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-_start+1023)/1024);
f0100733:	b8 0f 5e 11 f0       	mov    $0xf0115e0f,%eax
f0100738:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010073d:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100743:	85 c0                	test   %eax,%eax
f0100745:	0f 48 c2             	cmovs  %edx,%eax
f0100748:	c1 f8 0a             	sar    $0xa,%eax
f010074b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010074f:	c7 04 24 d4 3d 10 f0 	movl   $0xf0103dd4,(%esp)
f0100756:	e8 3e 22 00 00       	call   f0102999 <cprintf>
		(end-_start+1023)/1024);
	return 0;
}
f010075b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100760:	c9                   	leave  
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
f010076b:	c7 04 24 00 3e 10 f0 	movl   $0xf0103e00,(%esp)
f0100772:	e8 22 22 00 00       	call   f0102999 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100777:	c7 04 24 24 3e 10 f0 	movl   $0xf0103e24,(%esp)
f010077e:	e8 16 22 00 00       	call   f0102999 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100783:	c7 04 24 98 3c 10 f0 	movl   $0xf0103c98,(%esp)
f010078a:	e8 e1 2a 00 00       	call   f0103270 <readline>
f010078f:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100791:	85 c0                	test   %eax,%eax
f0100793:	74 ee                	je     f0100783 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100795:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010079c:	be 00 00 00 00       	mov    $0x0,%esi
f01007a1:	eb 0a                	jmp    f01007ad <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007a3:	c6 03 00             	movb   $0x0,(%ebx)
f01007a6:	89 f7                	mov    %esi,%edi
f01007a8:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007ab:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007ad:	0f b6 03             	movzbl (%ebx),%eax
f01007b0:	84 c0                	test   %al,%al
f01007b2:	74 6a                	je     f010081e <monitor+0xbc>
f01007b4:	0f be c0             	movsbl %al,%eax
f01007b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007bb:	c7 04 24 9c 3c 10 f0 	movl   $0xf0103c9c,(%esp)
f01007c2:	e8 e7 2c 00 00       	call   f01034ae <strchr>
f01007c7:	85 c0                	test   %eax,%eax
f01007c9:	75 d8                	jne    f01007a3 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01007cb:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007ce:	74 4e                	je     f010081e <monitor+0xbc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007d0:	83 fe 0f             	cmp    $0xf,%esi
f01007d3:	75 16                	jne    f01007eb <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007d5:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01007dc:	00 
f01007dd:	c7 04 24 a1 3c 10 f0 	movl   $0xf0103ca1,(%esp)
f01007e4:	e8 b0 21 00 00       	call   f0102999 <cprintf>
f01007e9:	eb 98                	jmp    f0100783 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01007eb:	8d 7e 01             	lea    0x1(%esi),%edi
f01007ee:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f01007f2:	0f b6 03             	movzbl (%ebx),%eax
f01007f5:	84 c0                	test   %al,%al
f01007f7:	75 0c                	jne    f0100805 <monitor+0xa3>
f01007f9:	eb b0                	jmp    f01007ab <monitor+0x49>
			buf++;
f01007fb:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007fe:	0f b6 03             	movzbl (%ebx),%eax
f0100801:	84 c0                	test   %al,%al
f0100803:	74 a6                	je     f01007ab <monitor+0x49>
f0100805:	0f be c0             	movsbl %al,%eax
f0100808:	89 44 24 04          	mov    %eax,0x4(%esp)
f010080c:	c7 04 24 9c 3c 10 f0 	movl   $0xf0103c9c,(%esp)
f0100813:	e8 96 2c 00 00       	call   f01034ae <strchr>
f0100818:	85 c0                	test   %eax,%eax
f010081a:	74 df                	je     f01007fb <monitor+0x99>
f010081c:	eb 8d                	jmp    f01007ab <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010081e:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100825:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100826:	85 f6                	test   %esi,%esi
f0100828:	0f 84 55 ff ff ff    	je     f0100783 <monitor+0x21>
f010082e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100833:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100836:	8b 04 85 80 3e 10 f0 	mov    -0xfefc180(,%eax,4),%eax
f010083d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100841:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100844:	89 04 24             	mov    %eax,(%esp)
f0100847:	e8 de 2b 00 00       	call   f010342a <strcmp>
f010084c:	85 c0                	test   %eax,%eax
f010084e:	75 24                	jne    f0100874 <monitor+0x112>
			return commands[i].func(argc, argv, tf);
f0100850:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100853:	8b 55 08             	mov    0x8(%ebp),%edx
f0100856:	89 54 24 08          	mov    %edx,0x8(%esp)
f010085a:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f010085d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100861:	89 34 24             	mov    %esi,(%esp)
f0100864:	ff 14 85 88 3e 10 f0 	call   *-0xfefc178(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010086b:	85 c0                	test   %eax,%eax
f010086d:	78 25                	js     f0100894 <monitor+0x132>
f010086f:	e9 0f ff ff ff       	jmp    f0100783 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100874:	83 c3 01             	add    $0x1,%ebx
f0100877:	83 fb 03             	cmp    $0x3,%ebx
f010087a:	75 b7                	jne    f0100833 <monitor+0xd1>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010087c:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010087f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100883:	c7 04 24 be 3c 10 f0 	movl   $0xf0103cbe,(%esp)
f010088a:	e8 0a 21 00 00       	call   f0102999 <cprintf>
f010088f:	e9 ef fe ff ff       	jmp    f0100783 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100894:	83 c4 5c             	add    $0x5c,%esp
f0100897:	5b                   	pop    %ebx
f0100898:	5e                   	pop    %esi
f0100899:	5f                   	pop    %edi
f010089a:	5d                   	pop    %ebp
f010089b:	c3                   	ret    

f010089c <read_eip>:
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned read_eip() __attribute__((noinline));
unsigned
read_eip()
{
f010089c:	55                   	push   %ebp
f010089d:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f010089f:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01008a2:	5d                   	pop    %ebp
f01008a3:	c3                   	ret    

f01008a4 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008a4:	55                   	push   %ebp
f01008a5:	89 e5                	mov    %esp,%ebp
f01008a7:	57                   	push   %edi
f01008a8:	56                   	push   %esi
f01008a9:	53                   	push   %ebx
f01008aa:	81 ec 4c 01 00 00    	sub    $0x14c,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01008b0:	89 ef                	mov    %ebp,%edi
	// Your code here.
	uint32_t *ebp = (uint32_t *)read_ebp();
	uint32_t eip = read_eip();
f01008b2:	e8 e5 ff ff ff       	call   f010089c <read_eip>
f01008b7:	89 c6                	mov    %eax,%esi
	struct Eipdebuginfo info;
	char fun_name[256];
	cprintf("Stack backtrace\n");
f01008b9:	c7 04 24 d4 3c 10 f0 	movl   $0xf0103cd4,(%esp)
f01008c0:	e8 d4 20 00 00       	call   f0102999 <cprintf>
	
	while(ebp != 0) {
f01008c5:	85 ff                	test   %edi,%edi
f01008c7:	0f 84 a3 00 00 00    	je     f0100970 <mon_backtrace+0xcc>
f01008cd:	89 fb                	mov    %edi,%ebx
		debuginfo_eip(eip, &info);
		strncpy(fun_name, info.eip_fn_name, info.eip_fn_namelen);
f01008cf:	8d bd d0 fe ff ff    	lea    -0x130(%ebp),%edi
	struct Eipdebuginfo info;
	char fun_name[256];
	cprintf("Stack backtrace\n");
	
	while(ebp != 0) {
		debuginfo_eip(eip, &info);
f01008d5:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008d8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008dc:	89 34 24             	mov    %esi,(%esp)
f01008df:	e8 ac 21 00 00       	call   f0102a90 <debuginfo_eip>
		strncpy(fun_name, info.eip_fn_name, info.eip_fn_namelen);
f01008e4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01008e7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008eb:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01008ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008f2:	89 3c 24             	mov    %edi,(%esp)
f01008f5:	e8 b1 2a 00 00       	call   f01033ab <strncpy>
		fun_name[info.eip_fn_namelen] = '\0';
f01008fa:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01008fd:	c6 84 05 d0 fe ff ff 	movb   $0x0,-0x130(%ebp,%eax,1)
f0100904:	00 
		cprintf("%s: %d:  %s+%x\n", info.eip_file, info.eip_line, fun_name, eip-(info.eip_fn_addr));
f0100905:	89 f0                	mov    %esi,%eax
f0100907:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010090a:	89 44 24 10          	mov    %eax,0x10(%esp)
f010090e:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0100912:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100915:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100919:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010091c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100920:	c7 04 24 e5 3c 10 f0 	movl   $0xf0103ce5,(%esp)
f0100927:	e8 6d 20 00 00       	call   f0102999 <cprintf>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, *(ebp+2), *(ebp+3), *(ebp+4), *(ebp+5), *(ebp+6)); 
f010092c:	8b 43 18             	mov    0x18(%ebx),%eax
f010092f:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100933:	8b 43 14             	mov    0x14(%ebx),%eax
f0100936:	89 44 24 18          	mov    %eax,0x18(%esp)
f010093a:	8b 43 10             	mov    0x10(%ebx),%eax
f010093d:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100941:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100944:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100948:	8b 43 08             	mov    0x8(%ebx),%eax
f010094b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010094f:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100953:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100957:	c7 04 24 4c 3e 10 f0 	movl   $0xf0103e4c,(%esp)
f010095e:	e8 36 20 00 00       	call   f0102999 <cprintf>
		eip = *(ebp+1);
f0100963:	8b 73 04             	mov    0x4(%ebx),%esi
		ebp = (unsigned *)*ebp;
f0100966:	8b 1b                	mov    (%ebx),%ebx
	uint32_t eip = read_eip();
	struct Eipdebuginfo info;
	char fun_name[256];
	cprintf("Stack backtrace\n");
	
	while(ebp != 0) {
f0100968:	85 db                	test   %ebx,%ebx
f010096a:	0f 85 65 ff ff ff    	jne    f01008d5 <mon_backtrace+0x31>
		eip = *(ebp+1);
		ebp = (unsigned *)*ebp;
	}
	//cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, *(ebp+1), *(ebp+2), *(ebp+3), *(ebp+4), *(ebp+5), *(ebp+6)); 
	return 0;
}
f0100970:	b8 00 00 00 00       	mov    $0x0,%eax
f0100975:	81 c4 4c 01 00 00    	add    $0x14c,%esp
f010097b:	5b                   	pop    %ebx
f010097c:	5e                   	pop    %esi
f010097d:	5f                   	pop    %edi
f010097e:	5d                   	pop    %ebp
f010097f:	c3                   	ret    

f0100980 <boot_alloc>:
// This function may ONLY be used during initialization,
// before the page_free_list has been set up.
// 
static void*
boot_alloc(uint32_t n, uint32_t align)
{
f0100980:	55                   	push   %ebp
f0100981:	89 e5                	mov    %esp,%ebp
f0100983:	57                   	push   %edi
f0100984:	56                   	push   %esi
f0100985:	53                   	push   %ebx
f0100986:	89 c7                	mov    %eax,%edi
f0100988:	89 d1                	mov    %edx,%ecx
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment -
	// i.e., the first virtual address that the linker
	// did _not_ assign to any kernel code or global variables.
	if (boot_freemem == 0)
		boot_freemem = end;
f010098a:	83 3d dc 55 11 f0 00 	cmpl   $0x0,0xf01155dc
	// LAB 2: Your code here:
	//	Step 1: round boot_freemem up to be aligned properly
	//	Step 2: save current value of boot_freemem as allocated chunk
	//	Step 3: increase boot_freemem to record allocation
	//	Step 4: return allocated chunk
	boot_freemem  = ROUNDUP(boot_freemem, align);
f0100991:	b8 10 5a 11 f0       	mov    $0xf0115a10,%eax
f0100996:	0f 45 05 dc 55 11 f0 	cmovne 0xf01155dc,%eax
f010099d:	8d 5c 10 ff          	lea    -0x1(%eax,%edx,1),%ebx
f01009a1:	89 d8                	mov    %ebx,%eax
f01009a3:	ba 00 00 00 00       	mov    $0x0,%edx
f01009a8:	f7 f1                	div    %ecx
f01009aa:	89 de                	mov    %ebx,%esi
f01009ac:	29 d6                	sub    %edx,%esi
	v = (void *)boot_freemem;
	boot_freemem += ROUNDUP(n, align);
f01009ae:	8d 5c 0f ff          	lea    -0x1(%edi,%ecx,1),%ebx
f01009b2:	89 d8                	mov    %ebx,%eax
f01009b4:	ba 00 00 00 00       	mov    $0x0,%edx
f01009b9:	f7 f1                	div    %ecx
f01009bb:	29 d3                	sub    %edx,%ebx
f01009bd:	01 f3                	add    %esi,%ebx
f01009bf:	89 1d dc 55 11 f0    	mov    %ebx,0xf01155dc

	return v;
}
f01009c5:	89 f0                	mov    %esi,%eax
f01009c7:	5b                   	pop    %ebx
f01009c8:	5e                   	pop    %esi
f01009c9:	5f                   	pop    %edi
f01009ca:	5d                   	pop    %ebp
f01009cb:	c3                   	ret    

f01009cc <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01009cc:	89 d1                	mov    %edx,%ecx
f01009ce:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f01009d1:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01009d4:	a8 01                	test   $0x1,%al
f01009d6:	74 5d                	je     f0100a35 <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01009d8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009dd:	89 c1                	mov    %eax,%ecx
f01009df:	c1 e9 0c             	shr    $0xc,%ecx
f01009e2:	3b 0d 00 5a 11 f0    	cmp    0xf0115a00,%ecx
f01009e8:	72 26                	jb     f0100a10 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_boot_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009ea:	55                   	push   %ebp
f01009eb:	89 e5                	mov    %esp,%ebp
f01009ed:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01009f0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009f4:	c7 44 24 08 a4 3e 10 	movl   $0xf0103ea4,0x8(%esp)
f01009fb:	f0 
f01009fc:	c7 44 24 04 95 01 00 	movl   $0x195,0x4(%esp)
f0100a03:	00 
f0100a04:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0100a0b:	e8 88 f6 ff ff       	call   f0100098 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100a10:	c1 ea 0c             	shr    $0xc,%edx
f0100a13:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a19:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a20:	89 c2                	mov    %eax,%edx
f0100a22:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a25:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a2a:	85 d2                	test   %edx,%edx
f0100a2c:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a31:	0f 44 c2             	cmove  %edx,%eax
f0100a34:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a3a:	c3                   	ret    

f0100a3b <i386_detect_memory>:
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
}

void
i386_detect_memory(void)
{
f0100a3b:	55                   	push   %ebp
f0100a3c:	89 e5                	mov    %esp,%ebp
f0100a3e:	53                   	push   %ebx
f0100a3f:	83 ec 14             	sub    $0x14,%esp
};

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a42:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f0100a49:	e8 db 1e 00 00       	call   f0102929 <mc146818_read>
f0100a4e:	89 c3                	mov    %eax,%ebx
f0100a50:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0100a57:	e8 cd 1e 00 00       	call   f0102929 <mc146818_read>
f0100a5c:	c1 e0 08             	shl    $0x8,%eax
f0100a5f:	09 c3                	or     %eax,%ebx

void
i386_detect_memory(void)
{
	// CMOS tells us how many kilobytes there are
	basemem = ROUNDDOWN(nvram_read(NVRAM_BASELO)*1024, PGSIZE);
f0100a61:	c1 e3 0a             	shl    $0xa,%ebx
f0100a64:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0100a6a:	89 1d e4 55 11 f0    	mov    %ebx,0xf01155e4
};

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a70:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0100a77:	e8 ad 1e 00 00       	call   f0102929 <mc146818_read>
f0100a7c:	89 c3                	mov    %eax,%ebx
f0100a7e:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0100a85:	e8 9f 1e 00 00       	call   f0102929 <mc146818_read>
f0100a8a:	c1 e0 08             	shl    $0x8,%eax
f0100a8d:	09 c3                	or     %eax,%ebx
void
i386_detect_memory(void)
{
	// CMOS tells us how many kilobytes there are
	basemem = ROUNDDOWN(nvram_read(NVRAM_BASELO)*1024, PGSIZE);
	extmem = ROUNDDOWN(nvram_read(NVRAM_EXTLO)*1024, PGSIZE);
f0100a8f:	89 d8                	mov    %ebx,%eax
f0100a91:	c1 e0 0a             	shl    $0xa,%eax
f0100a94:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a99:	a3 e0 55 11 f0       	mov    %eax,0xf01155e0

	// Calculate the maximum physical address based on whether
	// or not there is any extended memory.  See comment in <inc/mmu.h>.
	if (extmem)
f0100a9e:	85 c0                	test   %eax,%eax
f0100aa0:	74 0c                	je     f0100aae <i386_detect_memory+0x73>
		maxpa = EXTPHYSMEM + extmem;
f0100aa2:	05 00 00 10 00       	add    $0x100000,%eax
f0100aa7:	a3 e8 55 11 f0       	mov    %eax,0xf01155e8
f0100aac:	eb 0a                	jmp    f0100ab8 <i386_detect_memory+0x7d>
	else
		maxpa = basemem;
f0100aae:	a1 e4 55 11 f0       	mov    0xf01155e4,%eax
f0100ab3:	a3 e8 55 11 f0       	mov    %eax,0xf01155e8

	npage = maxpa / PGSIZE;
f0100ab8:	a1 e8 55 11 f0       	mov    0xf01155e8,%eax
f0100abd:	89 c2                	mov    %eax,%edx
f0100abf:	c1 ea 0c             	shr    $0xc,%edx
f0100ac2:	89 15 00 5a 11 f0    	mov    %edx,0xf0115a00

	cprintf("Physical memory: %dK available, ", (int)(maxpa/1024));
f0100ac8:	c1 e8 0a             	shr    $0xa,%eax
f0100acb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100acf:	c7 04 24 c8 3e 10 f0 	movl   $0xf0103ec8,(%esp)
f0100ad6:	e8 be 1e 00 00       	call   f0102999 <cprintf>
	cprintf("base = %dK, extended = %dK\n", (int)(basemem/1024), (int)(extmem/1024));
f0100adb:	a1 e0 55 11 f0       	mov    0xf01155e0,%eax
f0100ae0:	c1 e8 0a             	shr    $0xa,%eax
f0100ae3:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ae7:	a1 e4 55 11 f0       	mov    0xf01155e4,%eax
f0100aec:	c1 e8 0a             	shr    $0xa,%eax
f0100aef:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100af3:	c7 04 24 9b 43 10 f0 	movl   $0xf010439b,(%esp)
f0100afa:	e8 9a 1e 00 00       	call   f0102999 <cprintf>
}
f0100aff:	83 c4 14             	add    $0x14,%esp
f0100b02:	5b                   	pop    %ebx
f0100b03:	5d                   	pop    %ebp
f0100b04:	c3                   	ret    

f0100b05 <page_init>:
	//     Some of it is in use, some is free. Where is the kernel?
	//     Which pages are used for page tables and other data structures?
	//
	// Change the code to reflect this.
	int i;
	LIST_INIT(&page_free_list);
f0100b05:	c7 05 d8 55 11 f0 00 	movl   $0x0,0xf01155d8
f0100b0c:	00 00 00 
	pages[0].pp_ref = 1;
f0100b0f:	a1 0c 5a 11 f0       	mov    0xf0115a0c,%eax
f0100b14:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
f0100b1a:	b8 0c 00 00 00       	mov    $0xc,%eax
	for (i = 1; i < IOPHYSMEM/PGSIZE; i++) {
		pages[i].pp_ref = 0;
f0100b1f:	8b 0d 0c 5a 11 f0    	mov    0xf0115a0c,%ecx
f0100b25:	66 c7 44 01 08 00 00 	movw   $0x0,0x8(%ecx,%eax,1)
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
f0100b2c:	8b 15 d8 55 11 f0    	mov    0xf01155d8,%edx
f0100b32:	89 14 01             	mov    %edx,(%ecx,%eax,1)
f0100b35:	85 d2                	test   %edx,%edx
f0100b37:	74 11                	je     f0100b4a <page_init+0x45>
f0100b39:	89 c1                	mov    %eax,%ecx
f0100b3b:	03 0d 0c 5a 11 f0    	add    0xf0115a0c,%ecx
f0100b41:	8b 15 d8 55 11 f0    	mov    0xf01155d8,%edx
f0100b47:	89 4a 04             	mov    %ecx,0x4(%edx)
f0100b4a:	89 c2                	mov    %eax,%edx
f0100b4c:	03 15 0c 5a 11 f0    	add    0xf0115a0c,%edx
f0100b52:	89 15 d8 55 11 f0    	mov    %edx,0xf01155d8
f0100b58:	c7 42 04 d8 55 11 f0 	movl   $0xf01155d8,0x4(%edx)
f0100b5f:	83 c0 0c             	add    $0xc,%eax
	//
	// Change the code to reflect this.
	int i;
	LIST_INIT(&page_free_list);
	pages[0].pp_ref = 1;
	for (i = 1; i < IOPHYSMEM/PGSIZE; i++) {
f0100b62:	3d 80 07 00 00       	cmp    $0x780,%eax
f0100b67:	75 b6                	jne    f0100b1f <page_init+0x1a>
// to allocate and deallocate physical memory via the page_free_list,
// and NEVER use boot_alloc()
//
void
page_init(void)
{
f0100b69:	55                   	push   %ebp
f0100b6a:	89 e5                	mov    %esp,%ebp
f0100b6c:	56                   	push   %esi
f0100b6d:	53                   	push   %ebx
	pages[0].pp_ref = 1;
	for (i = 1; i < IOPHYSMEM/PGSIZE; i++) {
		pages[i].pp_ref = 0;
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
	}
	for (i = IOPHYSMEM/PGSIZE; i < (int)(ROUNDUP(boot_freemem-KERNBASE, PGSIZE))/PGSIZE; i++) {
f0100b6e:	a1 dc 55 11 f0       	mov    0xf01155dc,%eax
f0100b73:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0100b78:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b7d:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0100b83:	85 c0                	test   %eax,%eax
f0100b85:	0f 49 d8             	cmovns %eax,%ebx
f0100b88:	c1 fb 0c             	sar    $0xc,%ebx
f0100b8b:	89 d8                	mov    %ebx,%eax
f0100b8d:	81 fb a0 00 00 00    	cmp    $0xa0,%ebx
f0100b93:	7e 1e                	jle    f0100bb3 <page_init+0xae>
f0100b95:	8b 0d 0c 5a 11 f0    	mov    0xf0115a0c,%ecx
		pages[i].pp_ref = 1;
f0100b9b:	ba a0 00 00 00       	mov    $0xa0,%edx
f0100ba0:	66 c7 81 88 07 00 00 	movw   $0x1,0x788(%ecx)
f0100ba7:	01 00 
	pages[0].pp_ref = 1;
	for (i = 1; i < IOPHYSMEM/PGSIZE; i++) {
		pages[i].pp_ref = 0;
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
	}
	for (i = IOPHYSMEM/PGSIZE; i < (int)(ROUNDUP(boot_freemem-KERNBASE, PGSIZE))/PGSIZE; i++) {
f0100ba9:	83 c2 01             	add    $0x1,%edx
f0100bac:	83 c1 0c             	add    $0xc,%ecx
f0100baf:	39 c2                	cmp    %eax,%edx
f0100bb1:	7c ed                	jl     f0100ba0 <page_init+0x9b>
		pages[i].pp_ref = 1;
	}
	for (i = (int)(ROUNDUP(boot_freemem-KERNBASE, PGSIZE))/PGSIZE; i < npage;i++) {
f0100bb3:	89 da                	mov    %ebx,%edx
f0100bb5:	3b 1d 00 5a 11 f0    	cmp    0xf0115a00,%ebx
f0100bbb:	73 55                	jae    f0100c12 <page_init+0x10d>
		pages[i].pp_ref = 0;
f0100bbd:	8d 34 52             	lea    (%edx,%edx,2),%esi
f0100bc0:	8d 14 b5 00 00 00 00 	lea    0x0(,%esi,4),%edx
f0100bc7:	8b 1d 0c 5a 11 f0    	mov    0xf0115a0c,%ebx
f0100bcd:	66 c7 44 13 08 00 00 	movw   $0x0,0x8(%ebx,%edx,1)
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
f0100bd4:	8b 0d d8 55 11 f0    	mov    0xf01155d8,%ecx
f0100bda:	89 0c b3             	mov    %ecx,(%ebx,%esi,4)
f0100bdd:	85 c9                	test   %ecx,%ecx
f0100bdf:	74 11                	je     f0100bf2 <page_init+0xed>
f0100be1:	89 d3                	mov    %edx,%ebx
f0100be3:	03 1d 0c 5a 11 f0    	add    0xf0115a0c,%ebx
f0100be9:	8b 0d d8 55 11 f0    	mov    0xf01155d8,%ecx
f0100bef:	89 59 04             	mov    %ebx,0x4(%ecx)
f0100bf2:	03 15 0c 5a 11 f0    	add    0xf0115a0c,%edx
f0100bf8:	89 15 d8 55 11 f0    	mov    %edx,0xf01155d8
f0100bfe:	c7 42 04 d8 55 11 f0 	movl   $0xf01155d8,0x4(%edx)
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
	}
	for (i = IOPHYSMEM/PGSIZE; i < (int)(ROUNDUP(boot_freemem-KERNBASE, PGSIZE))/PGSIZE; i++) {
		pages[i].pp_ref = 1;
	}
	for (i = (int)(ROUNDUP(boot_freemem-KERNBASE, PGSIZE))/PGSIZE; i < npage;i++) {
f0100c05:	83 c0 01             	add    $0x1,%eax
f0100c08:	89 c2                	mov    %eax,%edx
f0100c0a:	3b 05 00 5a 11 f0    	cmp    0xf0115a00,%eax
f0100c10:	72 ab                	jb     f0100bbd <page_init+0xb8>
		pages[i].pp_ref = 0;
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
	}

}
f0100c12:	5b                   	pop    %ebx
f0100c13:	5e                   	pop    %esi
f0100c14:	5d                   	pop    %ebp
f0100c15:	c3                   	ret    

f0100c16 <page_alloc>:
//
// Hint: use LIST_FIRST, LIST_REMOVE, and page_initpp
// Hint: pp_ref should not be incremented 
int
page_alloc(struct Page **pp_store)
{
f0100c16:	55                   	push   %ebp
f0100c17:	89 e5                	mov    %esp,%ebp
f0100c19:	8b 55 08             	mov    0x8(%ebp),%edx
	// Fill this function in
	if ((*pp_store = LIST_FIRST(&page_free_list)) != NULL) {
f0100c1c:	a1 d8 55 11 f0       	mov    0xf01155d8,%eax
f0100c21:	89 02                	mov    %eax,(%edx)
f0100c23:	85 c0                	test   %eax,%eax
f0100c25:	74 1c                	je     f0100c43 <page_alloc+0x2d>
		//(*pp_store)->pp_ref = 1;
		LIST_REMOVE(*pp_store, pp_link);
f0100c27:	8b 08                	mov    (%eax),%ecx
f0100c29:	85 c9                	test   %ecx,%ecx
f0100c2b:	74 06                	je     f0100c33 <page_alloc+0x1d>
f0100c2d:	8b 40 04             	mov    0x4(%eax),%eax
f0100c30:	89 41 04             	mov    %eax,0x4(%ecx)
f0100c33:	8b 02                	mov    (%edx),%eax
f0100c35:	8b 50 04             	mov    0x4(%eax),%edx
f0100c38:	8b 00                	mov    (%eax),%eax
f0100c3a:	89 02                	mov    %eax,(%edx)
		return 0;
f0100c3c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c41:	eb 05                	jmp    f0100c48 <page_alloc+0x32>
	}
	return -E_NO_MEM;
f0100c43:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f0100c48:	5d                   	pop    %ebp
f0100c49:	c3                   	ret    

f0100c4a <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100c4a:	55                   	push   %ebp
f0100c4b:	89 e5                	mov    %esp,%ebp
f0100c4d:	53                   	push   %ebx
f0100c4e:	83 ec 14             	sub    $0x14,%esp
f0100c51:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (pp->pp_ref == 0) {
f0100c54:	66 83 7b 08 00       	cmpw   $0x0,0x8(%ebx)
f0100c59:	75 38                	jne    f0100c93 <page_free+0x49>
// Note that the corresponding physical page is NOT initialized!
//
static void
page_initpp(struct Page *pp)
{
	memset(pp, 0, sizeof(*pp));
f0100c5b:	c7 44 24 08 0c 00 00 	movl   $0xc,0x8(%esp)
f0100c62:	00 
f0100c63:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100c6a:	00 
f0100c6b:	89 1c 24             	mov    %ebx,(%esp)
f0100c6e:	e8 9c 28 00 00       	call   f010350f <memset>
void
page_free(struct Page *pp)
{
	if (pp->pp_ref == 0) {
		page_initpp(pp);
		LIST_INSERT_HEAD(&page_free_list, pp, pp_link);
f0100c73:	a1 d8 55 11 f0       	mov    0xf01155d8,%eax
f0100c78:	89 03                	mov    %eax,(%ebx)
f0100c7a:	85 c0                	test   %eax,%eax
f0100c7c:	74 08                	je     f0100c86 <page_free+0x3c>
f0100c7e:	a1 d8 55 11 f0       	mov    0xf01155d8,%eax
f0100c83:	89 58 04             	mov    %ebx,0x4(%eax)
f0100c86:	89 1d d8 55 11 f0    	mov    %ebx,0xf01155d8
f0100c8c:	c7 43 04 d8 55 11 f0 	movl   $0xf01155d8,0x4(%ebx)
	}
	// Fill this function in
}
f0100c93:	83 c4 14             	add    $0x14,%esp
f0100c96:	5b                   	pop    %ebx
f0100c97:	5d                   	pop    %ebp
f0100c98:	c3                   	ret    

f0100c99 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100c99:	55                   	push   %ebp
f0100c9a:	89 e5                	mov    %esp,%ebp
f0100c9c:	83 ec 18             	sub    $0x18,%esp
f0100c9f:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100ca2:	0f b7 48 08          	movzwl 0x8(%eax),%ecx
f0100ca6:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100ca9:	66 89 50 08          	mov    %dx,0x8(%eax)
f0100cad:	66 85 d2             	test   %dx,%dx
f0100cb0:	75 08                	jne    f0100cba <page_decref+0x21>
		page_free(pp);
f0100cb2:	89 04 24             	mov    %eax,(%esp)
f0100cb5:	e8 90 ff ff ff       	call   f0100c4a <page_free>
}
f0100cba:	c9                   	leave  
f0100cbb:	c3                   	ret    

f0100cbc <pgdir_walk>:
//
// Hint: you can turn a Page * into the physical address of the
// page it refers to with page2pa() from kern/pmap.h.
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100cbc:	55                   	push   %ebp
f0100cbd:	89 e5                	mov    %esp,%ebp
f0100cbf:	56                   	push   %esi
f0100cc0:	53                   	push   %ebx
f0100cc1:	83 ec 20             	sub    $0x20,%esp
f0100cc4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pt_addr;
	struct Page *page;
	//cprintf("%x,%x\n", va, (pgdir[PDX(va)] & PTE_P));
	if ((pgdir[PDX(va)] & PTE_P) != 0) {
f0100cc7:	89 de                	mov    %ebx,%esi
f0100cc9:	c1 ee 16             	shr    $0x16,%esi
f0100ccc:	c1 e6 02             	shl    $0x2,%esi
f0100ccf:	03 75 08             	add    0x8(%ebp),%esi
f0100cd2:	8b 06                	mov    (%esi),%eax
f0100cd4:	a8 01                	test   $0x1,%al
f0100cd6:	74 47                	je     f0100d1f <pgdir_walk+0x63>
		
		pt_addr = (pte_t *)KADDR(PTE_ADDR(pgdir[PDX(va)]));
f0100cd8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100cdd:	89 c2                	mov    %eax,%edx
f0100cdf:	c1 ea 0c             	shr    $0xc,%edx
f0100ce2:	3b 15 00 5a 11 f0    	cmp    0xf0115a00,%edx
f0100ce8:	72 20                	jb     f0100d0a <pgdir_walk+0x4e>
f0100cea:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cee:	c7 44 24 08 a4 3e 10 	movl   $0xf0103ea4,0x8(%esp)
f0100cf5:	f0 
f0100cf6:	c7 44 24 04 1b 02 00 	movl   $0x21b,0x4(%esp)
f0100cfd:	00 
f0100cfe:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0100d05:	e8 8e f3 ff ff       	call   f0100098 <_panic>
		//cprintf("%x\n", *pt_addr);
		return &pt_addr[PTX(va)];
f0100d0a:	c1 eb 0a             	shr    $0xa,%ebx
f0100d0d:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100d13:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0100d1a:	e9 a4 00 00 00       	jmp    f0100dc3 <pgdir_walk+0x107>
	}else {
		if (create == 0 ) return NULL;
f0100d1f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100d23:	0f 84 8e 00 00 00    	je     f0100db7 <pgdir_walk+0xfb>
		else {
			if (page_alloc(&page) != 0) return NULL;
f0100d29:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100d2c:	89 04 24             	mov    %eax,(%esp)
f0100d2f:	e8 e2 fe ff ff       	call   f0100c16 <page_alloc>
f0100d34:	85 c0                	test   %eax,%eax
f0100d36:	0f 85 82 00 00 00    	jne    f0100dbe <pgdir_walk+0x102>
			else {
				page->pp_ref = 1;
f0100d3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100d3f:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0100d45:	2b 05 0c 5a 11 f0    	sub    0xf0115a0c,%eax
f0100d4b:	c1 f8 02             	sar    $0x2,%eax
f0100d4e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0100d54:	c1 e0 0c             	shl    $0xc,%eax

				pgdir[PDX(va)] = page2pa(page) |PTE_U | PTE_W | PTE_P;
f0100d57:	89 c2                	mov    %eax,%edx
f0100d59:	83 ca 07             	or     $0x7,%edx
f0100d5c:	89 16                	mov    %edx,(%esi)
				pt_addr =  (pte_t *)KADDR(PTE_ADDR(pgdir[PDX(va)]));
f0100d5e:	89 c2                	mov    %eax,%edx
f0100d60:	c1 ea 0c             	shr    $0xc,%edx
f0100d63:	3b 15 00 5a 11 f0    	cmp    0xf0115a00,%edx
f0100d69:	72 20                	jb     f0100d8b <pgdir_walk+0xcf>
f0100d6b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d6f:	c7 44 24 08 a4 3e 10 	movl   $0xf0103ea4,0x8(%esp)
f0100d76:	f0 
f0100d77:	c7 44 24 04 26 02 00 	movl   $0x226,0x4(%esp)
f0100d7e:	00 
f0100d7f:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0100d86:	e8 0d f3 ff ff       	call   f0100098 <_panic>
f0100d8b:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi
				memset(pt_addr, 0, PGSIZE);
f0100d91:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100d98:	00 
f0100d99:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100da0:	00 
f0100da1:	89 34 24             	mov    %esi,(%esp)
f0100da4:	e8 66 27 00 00       	call   f010350f <memset>
				return &pt_addr[PTX(va)];
f0100da9:	c1 eb 0a             	shr    $0xa,%ebx
f0100dac:	89 d8                	mov    %ebx,%eax
f0100dae:	25 fc 0f 00 00       	and    $0xffc,%eax
f0100db3:	01 f0                	add    %esi,%eax
f0100db5:	eb 0c                	jmp    f0100dc3 <pgdir_walk+0x107>
		
		pt_addr = (pte_t *)KADDR(PTE_ADDR(pgdir[PDX(va)]));
		//cprintf("%x\n", *pt_addr);
		return &pt_addr[PTX(va)];
	}else {
		if (create == 0 ) return NULL;
f0100db7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dbc:	eb 05                	jmp    f0100dc3 <pgdir_walk+0x107>
		else {
			if (page_alloc(&page) != 0) return NULL;
f0100dbe:	b8 00 00 00 00       	mov    $0x0,%eax
				memset(pt_addr, 0, PGSIZE);
				return &pt_addr[PTX(va)];
			}
		}
	}
}
f0100dc3:	83 c4 20             	add    $0x20,%esp
f0100dc6:	5b                   	pop    %ebx
f0100dc7:	5e                   	pop    %esi
f0100dc8:	5d                   	pop    %ebp
f0100dc9:	c3                   	ret    

f0100dca <boot_map_segment>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, physaddr_t pa, int perm)
{
f0100dca:	55                   	push   %ebp
f0100dcb:	89 e5                	mov    %esp,%ebp
f0100dcd:	57                   	push   %edi
f0100dce:	56                   	push   %esi
f0100dcf:	53                   	push   %ebx
f0100dd0:	83 ec 2c             	sub    $0x2c,%esp
f0100dd3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100dd6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
	pte_t *pt_addr;
	// for (i=0;i<n;i++) {
	// 	pt_addr = pgdir_walk(pgdir, (void *)(la+i*PGSIZE), 1);
	// 	*pt_addr =  (pa + i*PGSIZE) | perm | PTE_P;
	// }
	for (i=0;i<size;i+=PGSIZE) {
f0100dd9:	85 c9                	test   %ecx,%ecx
f0100ddb:	74 44                	je     f0100e21 <boot_map_segment+0x57>
f0100ddd:	89 d7                	mov    %edx,%edi
f0100ddf:	be 00 00 00 00       	mov    $0x0,%esi
f0100de4:	bb 00 00 00 00       	mov    $0x0,%ebx
		pt_addr = pgdir_walk(pgdir, (void *)(la+i), 1);
		*pt_addr = (pa+i) |perm |PTE_P;
f0100de9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100dec:	83 c8 01             	or     $0x1,%eax
f0100def:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// for (i=0;i<n;i++) {
	// 	pt_addr = pgdir_walk(pgdir, (void *)(la+i*PGSIZE), 1);
	// 	*pt_addr =  (pa + i*PGSIZE) | perm | PTE_P;
	// }
	for (i=0;i<size;i+=PGSIZE) {
		pt_addr = pgdir_walk(pgdir, (void *)(la+i), 1);
f0100df2:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100df9:	00 
f0100dfa:	8d 04 3e             	lea    (%esi,%edi,1),%eax
f0100dfd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e01:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e04:	89 04 24             	mov    %eax,(%esp)
f0100e07:	e8 b0 fe ff ff       	call   f0100cbc <pgdir_walk>
		*pt_addr = (pa+i) |perm |PTE_P;
f0100e0c:	03 75 08             	add    0x8(%ebp),%esi
f0100e0f:	0b 75 dc             	or     -0x24(%ebp),%esi
f0100e12:	89 30                	mov    %esi,(%eax)
	pte_t *pt_addr;
	// for (i=0;i<n;i++) {
	// 	pt_addr = pgdir_walk(pgdir, (void *)(la+i*PGSIZE), 1);
	// 	*pt_addr =  (pa + i*PGSIZE) | perm | PTE_P;
	// }
	for (i=0;i<size;i+=PGSIZE) {
f0100e14:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100e1a:	89 de                	mov    %ebx,%esi
f0100e1c:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f0100e1f:	72 d1                	jb     f0100df2 <boot_map_segment+0x28>
		pt_addr = pgdir_walk(pgdir, (void *)(la+i), 1);
		*pt_addr = (pa+i) |perm |PTE_P;
	}
	return ;
	// Fill this function in
}
f0100e21:	83 c4 2c             	add    $0x2c,%esp
f0100e24:	5b                   	pop    %ebx
f0100e25:	5e                   	pop    %esi
f0100e26:	5f                   	pop    %edi
f0100e27:	5d                   	pop    %ebp
f0100e28:	c3                   	ret    

f0100e29 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100e29:	55                   	push   %ebp
f0100e2a:	89 e5                	mov    %esp,%ebp
f0100e2c:	53                   	push   %ebx
f0100e2d:	83 ec 14             	sub    $0x14,%esp
f0100e30:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pt_addr;
	pt_addr = pgdir_walk(pgdir, va, 0);
f0100e33:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100e3a:	00 
f0100e3b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e3e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e42:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e45:	89 04 24             	mov    %eax,(%esp)
f0100e48:	e8 6f fe ff ff       	call   f0100cbc <pgdir_walk>
	if (pt_addr == NULL) return NULL;
f0100e4d:	85 c0                	test   %eax,%eax
f0100e4f:	74 3c                	je     f0100e8d <page_lookup+0x64>
	if (pte_store !=NULL)
f0100e51:	85 db                	test   %ebx,%ebx
f0100e53:	74 02                	je     f0100e57 <page_lookup+0x2e>
		*pte_store = pt_addr;
f0100e55:	89 03                	mov    %eax,(%ebx)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PPN(pa) >= npage)
f0100e57:	8b 00                	mov    (%eax),%eax
f0100e59:	c1 e8 0c             	shr    $0xc,%eax
f0100e5c:	3b 05 00 5a 11 f0    	cmp    0xf0115a00,%eax
f0100e62:	72 1c                	jb     f0100e80 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f0100e64:	c7 44 24 08 ec 3e 10 	movl   $0xf0103eec,0x8(%esp)
f0100e6b:	f0 
f0100e6c:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0100e73:	00 
f0100e74:	c7 04 24 b7 43 10 f0 	movl   $0xf01043b7,(%esp)
f0100e7b:	e8 18 f2 ff ff       	call   f0100098 <_panic>
	return &pages[PPN(pa)];
f0100e80:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100e83:	a1 0c 5a 11 f0       	mov    0xf0115a0c,%eax
f0100e88:	8d 04 90             	lea    (%eax,%edx,4),%eax
	return pa2page(*pt_addr);
f0100e8b:	eb 05                	jmp    f0100e92 <page_lookup+0x69>
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pt_addr;
	pt_addr = pgdir_walk(pgdir, va, 0);
	if (pt_addr == NULL) return NULL;
f0100e8d:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store !=NULL)
		*pte_store = pt_addr;
	return pa2page(*pt_addr);
}
f0100e92:	83 c4 14             	add    $0x14,%esp
f0100e95:	5b                   	pop    %ebx
f0100e96:	5d                   	pop    %ebp
f0100e97:	c3                   	ret    

f0100e98 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100e98:	55                   	push   %ebp
f0100e99:	89 e5                	mov    %esp,%ebp
f0100e9b:	53                   	push   %ebx
f0100e9c:	83 ec 24             	sub    $0x24,%esp
f0100e9f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct Page *pg;
	pte_t *pt_addr;
	pg = page_lookup(pgdir, va, &pt_addr);
f0100ea2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100ea5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ea9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ead:	8b 45 08             	mov    0x8(%ebp),%eax
f0100eb0:	89 04 24             	mov    %eax,(%esp)
f0100eb3:	e8 71 ff ff ff       	call   f0100e29 <page_lookup>
	if (pg == NULL) return ;
f0100eb8:	85 c0                	test   %eax,%eax
f0100eba:	74 18                	je     f0100ed4 <page_remove+0x3c>
	else 
		page_decref(pg);
f0100ebc:	89 04 24             	mov    %eax,(%esp)
f0100ebf:	e8 d5 fd ff ff       	call   f0100c99 <page_decref>
	if (pt_addr != NULL)
f0100ec4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100ec7:	85 c0                	test   %eax,%eax
f0100ec9:	74 06                	je     f0100ed1 <page_remove+0x39>
		*pt_addr = 0;
f0100ecb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100ed1:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
}
f0100ed4:	83 c4 24             	add    $0x24,%esp
f0100ed7:	5b                   	pop    %ebx
f0100ed8:	5d                   	pop    %ebp
f0100ed9:	c3                   	ret    

f0100eda <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm) 
{
f0100eda:	55                   	push   %ebp
f0100edb:	89 e5                	mov    %esp,%ebp
f0100edd:	57                   	push   %edi
f0100ede:	56                   	push   %esi
f0100edf:	53                   	push   %ebx
f0100ee0:	83 ec 1c             	sub    $0x1c,%esp
f0100ee3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ee6:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t *pt_addr;
	pt_addr = pgdir_walk(pgdir, va, 1);
f0100ee9:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100ef0:	00 
f0100ef1:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ef5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ef8:	89 04 24             	mov    %eax,(%esp)
f0100efb:	e8 bc fd ff ff       	call   f0100cbc <pgdir_walk>
	if (va == (void *)PTSIZE) return -E_NO_MEM;
f0100f00:	81 fe 00 00 40 00    	cmp    $0x400000,%esi
f0100f06:	74 7b                	je     f0100f83 <page_insert+0xa9>
f0100f08:	89 c7                	mov    %eax,%edi
	if (pt_addr == NULL) return -E_NO_MEM;
f0100f0a:	85 c0                	test   %eax,%eax
f0100f0c:	74 7c                	je     f0100f8a <page_insert+0xb0>
	if ((pp == page_lookup(pgdir, va, NULL)) && (*pt_addr == (page2pa(pp) | perm | PTE_P))) return 0;
f0100f0e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100f15:	00 
f0100f16:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f1a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f1d:	89 04 24             	mov    %eax,(%esp)
f0100f20:	e8 04 ff ff ff       	call   f0100e29 <page_lookup>
f0100f25:	39 d8                	cmp    %ebx,%eax
f0100f27:	75 1e                	jne    f0100f47 <page_insert+0x6d>
f0100f29:	8b 55 14             	mov    0x14(%ebp),%edx
f0100f2c:	83 ca 01             	or     $0x1,%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0100f2f:	2b 05 0c 5a 11 f0    	sub    0xf0115a0c,%eax
f0100f35:	c1 f8 02             	sar    $0x2,%eax
f0100f38:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0100f3e:	c1 e0 0c             	shl    $0xc,%eax
f0100f41:	09 d0                	or     %edx,%eax
f0100f43:	39 07                	cmp    %eax,(%edi)
f0100f45:	74 4a                	je     f0100f91 <page_insert+0xb7>
	if ((*pt_addr & PTE_P) != 0) 
f0100f47:	f6 07 01             	testb  $0x1,(%edi)
f0100f4a:	74 0f                	je     f0100f5b <page_insert+0x81>
		page_remove(pgdir, va);
f0100f4c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f50:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f53:	89 04 24             	mov    %eax,(%esp)
f0100f56:	e8 3d ff ff ff       	call   f0100e98 <page_remove>
	pp->pp_ref ++;
f0100f5b:	66 83 43 08 01       	addw   $0x1,0x8(%ebx)
	*pt_addr = page2pa(pp) | perm | PTE_P;
f0100f60:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f63:	83 c8 01             	or     $0x1,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0100f66:	2b 1d 0c 5a 11 f0    	sub    0xf0115a0c,%ebx
f0100f6c:	c1 fb 02             	sar    $0x2,%ebx
f0100f6f:	69 db ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%ebx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0100f75:	c1 e3 0c             	shl    $0xc,%ebx
f0100f78:	09 c3                	or     %eax,%ebx
f0100f7a:	89 1f                	mov    %ebx,(%edi)
	//cprintf("%x, %x", *pt_addr, npage);
	return 0;
f0100f7c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f81:	eb 13                	jmp    f0100f96 <page_insert+0xbc>
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm) 
{
	pte_t *pt_addr;
	pt_addr = pgdir_walk(pgdir, va, 1);
	if (va == (void *)PTSIZE) return -E_NO_MEM;
f0100f83:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0100f88:	eb 0c                	jmp    f0100f96 <page_insert+0xbc>
	if (pt_addr == NULL) return -E_NO_MEM;
f0100f8a:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0100f8f:	eb 05                	jmp    f0100f96 <page_insert+0xbc>
	if ((pp == page_lookup(pgdir, va, NULL)) && (*pt_addr == (page2pa(pp) | perm | PTE_P))) return 0;
f0100f91:	b8 00 00 00 00       	mov    $0x0,%eax
		page_remove(pgdir, va);
	pp->pp_ref ++;
	*pt_addr = page2pa(pp) | perm | PTE_P;
	//cprintf("%x, %x", *pt_addr, npage);
	return 0;
}
f0100f96:	83 c4 1c             	add    $0x1c,%esp
f0100f99:	5b                   	pop    %ebx
f0100f9a:	5e                   	pop    %esi
f0100f9b:	5f                   	pop    %edi
f0100f9c:	5d                   	pop    %ebp
f0100f9d:	c3                   	ret    

f0100f9e <i386_vm_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
{
f0100f9e:	55                   	push   %ebp
f0100f9f:	89 e5                	mov    %esp,%ebp
f0100fa1:	57                   	push   %edi
f0100fa2:	56                   	push   %esi
f0100fa3:	53                   	push   %ebx
f0100fa4:	83 ec 4c             	sub    $0x4c,%esp
	// Delete this line:
	//panic("i386_vm_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	pgdir = boot_alloc(PGSIZE, PGSIZE);
f0100fa7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0100fac:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100fb1:	e8 ca f9 ff ff       	call   f0100980 <boot_alloc>
f0100fb6:	89 c7                	mov    %eax,%edi
	memset(pgdir, 0, PGSIZE);
f0100fb8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100fbf:	00 
f0100fc0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100fc7:	00 
f0100fc8:	89 04 24             	mov    %eax,(%esp)
f0100fcb:	e8 3f 25 00 00       	call   f010350f <memset>
	boot_pgdir = pgdir;
f0100fd0:	89 3d 08 5a 11 f0    	mov    %edi,0xf0115a08
	boot_cr3 = PADDR(pgdir);
f0100fd6:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0100fdc:	77 20                	ja     f0100ffe <i386_vm_init+0x60>
f0100fde:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0100fe2:	c7 44 24 08 0c 3f 10 	movl   $0xf0103f0c,0x8(%esp)
f0100fe9:	f0 
f0100fea:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
f0100ff1:	00 
f0100ff2:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0100ff9:	e8 9a f0 ff ff       	call   f0100098 <_panic>
f0100ffe:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0101004:	a3 04 5a 11 f0       	mov    %eax,0xf0115a04
	// a virtual page table at virtual address VPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel RW, user NONE
	pgdir[PDX(VPT)] = PADDR(pgdir)|PTE_W|PTE_P;
f0101009:	89 c2                	mov    %eax,%edx
f010100b:	83 ca 03             	or     $0x3,%edx
f010100e:	89 97 fc 0e 00 00    	mov    %edx,0xefc(%edi)

	// same for UVPT
	// Permissions: kernel R, user R 
	pgdir[PDX(UVPT)] = PADDR(pgdir)|PTE_U|PTE_P;
f0101014:	83 c8 05             	or     $0x5,%eax
f0101017:	89 87 f4 0e 00 00    	mov    %eax,0xef4(%edi)
	// The kernel uses this structure to keep track of physical pages;
	// 'npage' equals the number of physical pages in memory.  User-level
	// programs will get read-only access to the array as well.
	// You must allocate the array yourself.
	// Your code goes here: 
	pages = boot_alloc(sizeof(struct Page) * npage, PGSIZE);
f010101d:	a1 00 5a 11 f0       	mov    0xf0115a00,%eax
f0101022:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0101025:	c1 e0 02             	shl    $0x2,%eax
f0101028:	ba 00 10 00 00       	mov    $0x1000,%edx
f010102d:	e8 4e f9 ff ff       	call   f0100980 <boot_alloc>
f0101032:	a3 0c 5a 11 f0       	mov    %eax,0xf0115a0c
	//////////////////////////////////////////////////////////////////////
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_segment or page_insert
	page_init();
f0101037:	e8 c9 fa ff ff       	call   f0100b05 <page_init>
	struct Page_list fl;
	
        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	LIST_FOREACH(pp0, &page_free_list, pp_link)
f010103c:	a1 d8 55 11 f0       	mov    0xf01155d8,%eax
f0101041:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101044:	85 c0                	test   %eax,%eax
f0101046:	0f 84 89 00 00 00    	je     f01010d5 <i386_vm_init+0x137>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f010104c:	2b 05 0c 5a 11 f0    	sub    0xf0115a0c,%eax
f0101052:	c1 f8 02             	sar    $0x2,%eax
f0101055:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f010105b:	c1 e0 0c             	shl    $0xc,%eax
}

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
f010105e:	89 c2                	mov    %eax,%edx
f0101060:	c1 ea 0c             	shr    $0xc,%edx
f0101063:	3b 15 00 5a 11 f0    	cmp    0xf0115a00,%edx
f0101069:	72 41                	jb     f01010ac <i386_vm_init+0x10e>
f010106b:	eb 1f                	jmp    f010108c <i386_vm_init+0xee>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f010106d:	2b 05 0c 5a 11 f0    	sub    0xf0115a0c,%eax
f0101073:	c1 f8 02             	sar    $0x2,%eax
f0101076:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f010107c:	c1 e0 0c             	shl    $0xc,%eax
}

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
f010107f:	89 c2                	mov    %eax,%edx
f0101081:	c1 ea 0c             	shr    $0xc,%edx
f0101084:	3b 15 00 5a 11 f0    	cmp    0xf0115a00,%edx
f010108a:	72 20                	jb     f01010ac <i386_vm_init+0x10e>
f010108c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101090:	c7 44 24 08 a4 3e 10 	movl   $0xf0103ea4,0x8(%esp)
f0101097:	f0 
f0101098:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010109f:	00 
f01010a0:	c7 04 24 b7 43 10 f0 	movl   $0xf01043b7,(%esp)
f01010a7:	e8 ec ef ff ff       	call   f0100098 <_panic>
		memset(page2kva(pp0), 0x97, 128);
f01010ac:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f01010b3:	00 
f01010b4:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f01010bb:	00 
f01010bc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01010c1:	89 04 24             	mov    %eax,(%esp)
f01010c4:	e8 46 24 00 00       	call   f010350f <memset>
	struct Page_list fl;
	
        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	LIST_FOREACH(pp0, &page_free_list, pp_link)
f01010c9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010cc:	8b 00                	mov    (%eax),%eax
f01010ce:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01010d1:	85 c0                	test   %eax,%eax
f01010d3:	75 98                	jne    f010106d <i386_vm_init+0xcf>
		memset(page2kva(pp0), 0x97, 128);

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
f01010d5:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01010dc:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01010e3:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	assert(page_alloc(&pp0) == 0);
f01010ea:	8d 45 dc             	lea    -0x24(%ebp),%eax
f01010ed:	89 04 24             	mov    %eax,(%esp)
f01010f0:	e8 21 fb ff ff       	call   f0100c16 <page_alloc>
f01010f5:	85 c0                	test   %eax,%eax
f01010f7:	74 24                	je     f010111d <i386_vm_init+0x17f>
f01010f9:	c7 44 24 0c c5 43 10 	movl   $0xf01043c5,0xc(%esp)
f0101100:	f0 
f0101101:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101108:	f0 
f0101109:	c7 44 24 04 2a 01 00 	movl   $0x12a,0x4(%esp)
f0101110:	00 
f0101111:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101118:	e8 7b ef ff ff       	call   f0100098 <_panic>
	assert(page_alloc(&pp1) == 0);
f010111d:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0101120:	89 04 24             	mov    %eax,(%esp)
f0101123:	e8 ee fa ff ff       	call   f0100c16 <page_alloc>
f0101128:	85 c0                	test   %eax,%eax
f010112a:	74 24                	je     f0101150 <i386_vm_init+0x1b2>
f010112c:	c7 44 24 0c f0 43 10 	movl   $0xf01043f0,0xc(%esp)
f0101133:	f0 
f0101134:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f010113b:	f0 
f010113c:	c7 44 24 04 2b 01 00 	movl   $0x12b,0x4(%esp)
f0101143:	00 
f0101144:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f010114b:	e8 48 ef ff ff       	call   f0100098 <_panic>
	assert(page_alloc(&pp2) == 0);
f0101150:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101153:	89 04 24             	mov    %eax,(%esp)
f0101156:	e8 bb fa ff ff       	call   f0100c16 <page_alloc>
f010115b:	85 c0                	test   %eax,%eax
f010115d:	74 24                	je     f0101183 <i386_vm_init+0x1e5>
f010115f:	c7 44 24 0c 06 44 10 	movl   $0xf0104406,0xc(%esp)
f0101166:	f0 
f0101167:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f010116e:	f0 
f010116f:	c7 44 24 04 2c 01 00 	movl   $0x12c,0x4(%esp)
f0101176:	00 
f0101177:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f010117e:	e8 15 ef ff ff       	call   f0100098 <_panic>

	assert(pp0);
f0101183:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101186:	85 c9                	test   %ecx,%ecx
f0101188:	75 24                	jne    f01011ae <i386_vm_init+0x210>
f010118a:	c7 44 24 0c 2a 44 10 	movl   $0xf010442a,0xc(%esp)
f0101191:	f0 
f0101192:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101199:	f0 
f010119a:	c7 44 24 04 2e 01 00 	movl   $0x12e,0x4(%esp)
f01011a1:	00 
f01011a2:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01011a9:	e8 ea ee ff ff       	call   f0100098 <_panic>
	assert(pp1 && pp1 != pp0);
f01011ae:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01011b1:	85 d2                	test   %edx,%edx
f01011b3:	74 04                	je     f01011b9 <i386_vm_init+0x21b>
f01011b5:	39 d1                	cmp    %edx,%ecx
f01011b7:	75 24                	jne    f01011dd <i386_vm_init+0x23f>
f01011b9:	c7 44 24 0c 1c 44 10 	movl   $0xf010441c,0xc(%esp)
f01011c0:	f0 
f01011c1:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01011c8:	f0 
f01011c9:	c7 44 24 04 2f 01 00 	movl   $0x12f,0x4(%esp)
f01011d0:	00 
f01011d1:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01011d8:	e8 bb ee ff ff       	call   f0100098 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01011dd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01011e0:	85 c0                	test   %eax,%eax
f01011e2:	74 08                	je     f01011ec <i386_vm_init+0x24e>
f01011e4:	39 c2                	cmp    %eax,%edx
f01011e6:	74 04                	je     f01011ec <i386_vm_init+0x24e>
f01011e8:	39 c1                	cmp    %eax,%ecx
f01011ea:	75 24                	jne    f0101210 <i386_vm_init+0x272>
f01011ec:	c7 44 24 0c 30 3f 10 	movl   $0xf0103f30,0xc(%esp)
f01011f3:	f0 
f01011f4:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01011fb:	f0 
f01011fc:	c7 44 24 04 30 01 00 	movl   $0x130,0x4(%esp)
f0101203:	00 
f0101204:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f010120b:	e8 88 ee ff ff       	call   f0100098 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101210:	8b 35 0c 5a 11 f0    	mov    0xf0115a0c,%esi
        assert(page2pa(pp0) < npage*PGSIZE);
f0101216:	8b 1d 00 5a 11 f0    	mov    0xf0115a00,%ebx
f010121c:	c1 e3 0c             	shl    $0xc,%ebx
f010121f:	29 f1                	sub    %esi,%ecx
f0101221:	c1 f9 02             	sar    $0x2,%ecx
f0101224:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f010122a:	c1 e1 0c             	shl    $0xc,%ecx
f010122d:	39 d9                	cmp    %ebx,%ecx
f010122f:	72 24                	jb     f0101255 <i386_vm_init+0x2b7>
f0101231:	c7 44 24 0c 2e 44 10 	movl   $0xf010442e,0xc(%esp)
f0101238:	f0 
f0101239:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101240:	f0 
f0101241:	c7 44 24 04 31 01 00 	movl   $0x131,0x4(%esp)
f0101248:	00 
f0101249:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101250:	e8 43 ee ff ff       	call   f0100098 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101255:	29 f2                	sub    %esi,%edx
f0101257:	c1 fa 02             	sar    $0x2,%edx
f010125a:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101260:	c1 e2 0c             	shl    $0xc,%edx
        assert(page2pa(pp1) < npage*PGSIZE);
f0101263:	39 d3                	cmp    %edx,%ebx
f0101265:	77 24                	ja     f010128b <i386_vm_init+0x2ed>
f0101267:	c7 44 24 0c 4a 44 10 	movl   $0xf010444a,0xc(%esp)
f010126e:	f0 
f010126f:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101276:	f0 
f0101277:	c7 44 24 04 32 01 00 	movl   $0x132,0x4(%esp)
f010127e:	00 
f010127f:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101286:	e8 0d ee ff ff       	call   f0100098 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f010128b:	29 f0                	sub    %esi,%eax
f010128d:	c1 f8 02             	sar    $0x2,%eax
f0101290:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101296:	c1 e0 0c             	shl    $0xc,%eax
        assert(page2pa(pp2) < npage*PGSIZE);
f0101299:	39 c3                	cmp    %eax,%ebx
f010129b:	77 24                	ja     f01012c1 <i386_vm_init+0x323>
f010129d:	c7 44 24 0c 66 44 10 	movl   $0xf0104466,0xc(%esp)
f01012a4:	f0 
f01012a5:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01012ac:	f0 
f01012ad:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
f01012b4:	00 
f01012b5:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01012bc:	e8 d7 ed ff ff       	call   f0100098 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012c1:	8b 1d d8 55 11 f0    	mov    0xf01155d8,%ebx
	LIST_INIT(&page_free_list);
f01012c7:	c7 05 d8 55 11 f0 00 	movl   $0x0,0xf01155d8
f01012ce:	00 00 00 

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f01012d1:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01012d4:	89 04 24             	mov    %eax,(%esp)
f01012d7:	e8 3a f9 ff ff       	call   f0100c16 <page_alloc>
f01012dc:	83 f8 fc             	cmp    $0xfffffffc,%eax
f01012df:	74 24                	je     f0101305 <i386_vm_init+0x367>
f01012e1:	c7 44 24 0c 82 44 10 	movl   $0xf0104482,0xc(%esp)
f01012e8:	f0 
f01012e9:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01012f0:	f0 
f01012f1:	c7 44 24 04 3a 01 00 	movl   $0x13a,0x4(%esp)
f01012f8:	00 
f01012f9:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101300:	e8 93 ed ff ff       	call   f0100098 <_panic>

        // free and re-allocate?
        page_free(pp0);
f0101305:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101308:	89 04 24             	mov    %eax,(%esp)
f010130b:	e8 3a f9 ff ff       	call   f0100c4a <page_free>
        page_free(pp1);
f0101310:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101313:	89 04 24             	mov    %eax,(%esp)
f0101316:	e8 2f f9 ff ff       	call   f0100c4a <page_free>
        page_free(pp2);
f010131b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010131e:	89 04 24             	mov    %eax,(%esp)
f0101321:	e8 24 f9 ff ff       	call   f0100c4a <page_free>
	pp0 = pp1 = pp2 = 0;
f0101326:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f010132d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0101334:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	assert(page_alloc(&pp0) == 0);
f010133b:	8d 45 dc             	lea    -0x24(%ebp),%eax
f010133e:	89 04 24             	mov    %eax,(%esp)
f0101341:	e8 d0 f8 ff ff       	call   f0100c16 <page_alloc>
f0101346:	85 c0                	test   %eax,%eax
f0101348:	74 24                	je     f010136e <i386_vm_init+0x3d0>
f010134a:	c7 44 24 0c c5 43 10 	movl   $0xf01043c5,0xc(%esp)
f0101351:	f0 
f0101352:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101359:	f0 
f010135a:	c7 44 24 04 41 01 00 	movl   $0x141,0x4(%esp)
f0101361:	00 
f0101362:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101369:	e8 2a ed ff ff       	call   f0100098 <_panic>
	assert(page_alloc(&pp1) == 0);
f010136e:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0101371:	89 04 24             	mov    %eax,(%esp)
f0101374:	e8 9d f8 ff ff       	call   f0100c16 <page_alloc>
f0101379:	85 c0                	test   %eax,%eax
f010137b:	74 24                	je     f01013a1 <i386_vm_init+0x403>
f010137d:	c7 44 24 0c f0 43 10 	movl   $0xf01043f0,0xc(%esp)
f0101384:	f0 
f0101385:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f010138c:	f0 
f010138d:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
f0101394:	00 
f0101395:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f010139c:	e8 f7 ec ff ff       	call   f0100098 <_panic>
	assert(page_alloc(&pp2) == 0);
f01013a1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01013a4:	89 04 24             	mov    %eax,(%esp)
f01013a7:	e8 6a f8 ff ff       	call   f0100c16 <page_alloc>
f01013ac:	85 c0                	test   %eax,%eax
f01013ae:	74 24                	je     f01013d4 <i386_vm_init+0x436>
f01013b0:	c7 44 24 0c 06 44 10 	movl   $0xf0104406,0xc(%esp)
f01013b7:	f0 
f01013b8:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01013bf:	f0 
f01013c0:	c7 44 24 04 43 01 00 	movl   $0x143,0x4(%esp)
f01013c7:	00 
f01013c8:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01013cf:	e8 c4 ec ff ff       	call   f0100098 <_panic>
	assert(pp0);
f01013d4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01013d7:	85 d2                	test   %edx,%edx
f01013d9:	75 24                	jne    f01013ff <i386_vm_init+0x461>
f01013db:	c7 44 24 0c 2a 44 10 	movl   $0xf010442a,0xc(%esp)
f01013e2:	f0 
f01013e3:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01013ea:	f0 
f01013eb:	c7 44 24 04 44 01 00 	movl   $0x144,0x4(%esp)
f01013f2:	00 
f01013f3:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01013fa:	e8 99 ec ff ff       	call   f0100098 <_panic>
	assert(pp1 && pp1 != pp0);
f01013ff:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101402:	85 c9                	test   %ecx,%ecx
f0101404:	74 04                	je     f010140a <i386_vm_init+0x46c>
f0101406:	39 ca                	cmp    %ecx,%edx
f0101408:	75 24                	jne    f010142e <i386_vm_init+0x490>
f010140a:	c7 44 24 0c 1c 44 10 	movl   $0xf010441c,0xc(%esp)
f0101411:	f0 
f0101412:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101419:	f0 
f010141a:	c7 44 24 04 45 01 00 	movl   $0x145,0x4(%esp)
f0101421:	00 
f0101422:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101429:	e8 6a ec ff ff       	call   f0100098 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010142e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101431:	85 c0                	test   %eax,%eax
f0101433:	74 08                	je     f010143d <i386_vm_init+0x49f>
f0101435:	39 c1                	cmp    %eax,%ecx
f0101437:	74 04                	je     f010143d <i386_vm_init+0x49f>
f0101439:	39 c2                	cmp    %eax,%edx
f010143b:	75 24                	jne    f0101461 <i386_vm_init+0x4c3>
f010143d:	c7 44 24 0c 30 3f 10 	movl   $0xf0103f30,0xc(%esp)
f0101444:	f0 
f0101445:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f010144c:	f0 
f010144d:	c7 44 24 04 46 01 00 	movl   $0x146,0x4(%esp)
f0101454:	00 
f0101455:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f010145c:	e8 37 ec ff ff       	call   f0100098 <_panic>
	assert(page_alloc(&pp) == -E_NO_MEM);
f0101461:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0101464:	89 04 24             	mov    %eax,(%esp)
f0101467:	e8 aa f7 ff ff       	call   f0100c16 <page_alloc>
f010146c:	83 f8 fc             	cmp    $0xfffffffc,%eax
f010146f:	74 24                	je     f0101495 <i386_vm_init+0x4f7>
f0101471:	c7 44 24 0c 82 44 10 	movl   $0xf0104482,0xc(%esp)
f0101478:	f0 
f0101479:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101480:	f0 
f0101481:	c7 44 24 04 47 01 00 	movl   $0x147,0x4(%esp)
f0101488:	00 
f0101489:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101490:	e8 03 ec ff ff       	call   f0100098 <_panic>

	// give free list back
	page_free_list = fl;
f0101495:	89 1d d8 55 11 f0    	mov    %ebx,0xf01155d8

	// free the pages we took
	page_free(pp0);
f010149b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010149e:	89 04 24             	mov    %eax,(%esp)
f01014a1:	e8 a4 f7 ff ff       	call   f0100c4a <page_free>
	page_free(pp1);
f01014a6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01014a9:	89 04 24             	mov    %eax,(%esp)
f01014ac:	e8 99 f7 ff ff       	call   f0100c4a <page_free>
	page_free(pp2);
f01014b1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01014b4:	89 04 24             	mov    %eax,(%esp)
f01014b7:	e8 8e f7 ff ff       	call   f0100c4a <page_free>

	cprintf("check_page_alloc() succeeded!\n");
f01014bc:	c7 04 24 50 3f 10 f0 	movl   $0xf0103f50,(%esp)
f01014c3:	e8 d1 14 00 00       	call   f0102999 <cprintf>
	pte_t *ptep, *ptep1;
	void *va;
	int i;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
f01014c8:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01014cf:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01014d6:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
	assert(page_alloc(&pp0) == 0);
f01014dd:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01014e0:	89 04 24             	mov    %eax,(%esp)
f01014e3:	e8 2e f7 ff ff       	call   f0100c16 <page_alloc>
f01014e8:	85 c0                	test   %eax,%eax
f01014ea:	74 24                	je     f0101510 <i386_vm_init+0x572>
f01014ec:	c7 44 24 0c c5 43 10 	movl   $0xf01043c5,0xc(%esp)
f01014f3:	f0 
f01014f4:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01014fb:	f0 
f01014fc:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
f0101503:	00 
f0101504:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f010150b:	e8 88 eb ff ff       	call   f0100098 <_panic>
	assert(page_alloc(&pp1) == 0);
f0101510:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0101513:	89 04 24             	mov    %eax,(%esp)
f0101516:	e8 fb f6 ff ff       	call   f0100c16 <page_alloc>
f010151b:	85 c0                	test   %eax,%eax
f010151d:	74 24                	je     f0101543 <i386_vm_init+0x5a5>
f010151f:	c7 44 24 0c f0 43 10 	movl   $0xf01043f0,0xc(%esp)
f0101526:	f0 
f0101527:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f010152e:	f0 
f010152f:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f0101536:	00 
f0101537:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f010153e:	e8 55 eb ff ff       	call   f0100098 <_panic>
	assert(page_alloc(&pp2) == 0);
f0101543:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0101546:	89 04 24             	mov    %eax,(%esp)
f0101549:	e8 c8 f6 ff ff       	call   f0100c16 <page_alloc>
f010154e:	85 c0                	test   %eax,%eax
f0101550:	74 24                	je     f0101576 <i386_vm_init+0x5d8>
f0101552:	c7 44 24 0c 06 44 10 	movl   $0xf0104406,0xc(%esp)
f0101559:	f0 
f010155a:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101561:	f0 
f0101562:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f0101569:	00 
f010156a:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101571:	e8 22 eb ff ff       	call   f0100098 <_panic>

	assert(pp0);
f0101576:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101579:	85 d2                	test   %edx,%edx
f010157b:	75 24                	jne    f01015a1 <i386_vm_init+0x603>
f010157d:	c7 44 24 0c 2a 44 10 	movl   $0xf010442a,0xc(%esp)
f0101584:	f0 
f0101585:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f010158c:	f0 
f010158d:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f0101594:	00 
f0101595:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f010159c:	e8 f7 ea ff ff       	call   f0100098 <_panic>
	assert(pp1 && pp1 != pp0);
f01015a1:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01015a4:	85 c9                	test   %ecx,%ecx
f01015a6:	74 04                	je     f01015ac <i386_vm_init+0x60e>
f01015a8:	39 ca                	cmp    %ecx,%edx
f01015aa:	75 24                	jne    f01015d0 <i386_vm_init+0x632>
f01015ac:	c7 44 24 0c 1c 44 10 	movl   $0xf010441c,0xc(%esp)
f01015b3:	f0 
f01015b4:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01015bb:	f0 
f01015bc:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f01015c3:	00 
f01015c4:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01015cb:	e8 c8 ea ff ff       	call   f0100098 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015d0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01015d3:	85 c0                	test   %eax,%eax
f01015d5:	74 08                	je     f01015df <i386_vm_init+0x641>
f01015d7:	39 c1                	cmp    %eax,%ecx
f01015d9:	74 04                	je     f01015df <i386_vm_init+0x641>
f01015db:	39 c2                	cmp    %eax,%edx
f01015dd:	75 24                	jne    f0101603 <i386_vm_init+0x665>
f01015df:	c7 44 24 0c 30 3f 10 	movl   $0xf0103f30,0xc(%esp)
f01015e6:	f0 
f01015e7:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01015ee:	f0 
f01015ef:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f01015f6:	00 
f01015f7:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01015fe:	e8 95 ea ff ff       	call   f0100098 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101603:	a1 d8 55 11 f0       	mov    0xf01155d8,%eax
f0101608:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	LIST_INIT(&page_free_list);
f010160b:	c7 05 d8 55 11 f0 00 	movl   $0x0,0xf01155d8
f0101612:	00 00 00 

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f0101615:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0101618:	89 04 24             	mov    %eax,(%esp)
f010161b:	e8 f6 f5 ff ff       	call   f0100c16 <page_alloc>
f0101620:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101623:	74 24                	je     f0101649 <i386_vm_init+0x6ab>
f0101625:	c7 44 24 0c 82 44 10 	movl   $0xf0104482,0xc(%esp)
f010162c:	f0 
f010162d:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101634:	f0 
f0101635:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f010163c:	00 
f010163d:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101644:	e8 4f ea ff ff       	call   f0100098 <_panic>
	// there is no page allocated at address 0
	assert(page_lookup(boot_pgdir, (void *) 0x0, &ptep) == NULL);
f0101649:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010164c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101650:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101657:	00 
f0101658:	a1 08 5a 11 f0       	mov    0xf0115a08,%eax
f010165d:	89 04 24             	mov    %eax,(%esp)
f0101660:	e8 c4 f7 ff ff       	call   f0100e29 <page_lookup>
f0101665:	85 c0                	test   %eax,%eax
f0101667:	74 24                	je     f010168d <i386_vm_init+0x6ef>
f0101669:	c7 44 24 0c 70 3f 10 	movl   $0xf0103f70,0xc(%esp)
f0101670:	f0 
f0101671:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101678:	f0 
f0101679:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f0101680:	00 
f0101681:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101688:	e8 0b ea ff ff       	call   f0100098 <_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(page_insert(boot_pgdir, pp1, 0x0, 0) < 0);
f010168d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101694:	00 
f0101695:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010169c:	00 
f010169d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01016a0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016a4:	a1 08 5a 11 f0       	mov    0xf0115a08,%eax
f01016a9:	89 04 24             	mov    %eax,(%esp)
f01016ac:	e8 29 f8 ff ff       	call   f0100eda <page_insert>
f01016b1:	85 c0                	test   %eax,%eax
f01016b3:	78 24                	js     f01016d9 <i386_vm_init+0x73b>
f01016b5:	c7 44 24 0c a8 3f 10 	movl   $0xf0103fa8,0xc(%esp)
f01016bc:	f0 
f01016bd:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01016c4:	f0 
f01016c5:	c7 44 24 04 c8 02 00 	movl   $0x2c8,0x4(%esp)
f01016cc:	00 
f01016cd:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01016d4:	e8 bf e9 ff ff       	call   f0100098 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01016d9:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01016dc:	89 04 24             	mov    %eax,(%esp)
f01016df:	e8 66 f5 ff ff       	call   f0100c4a <page_free>
	
	assert(page_insert(boot_pgdir, pp1, 0x0, 0) == 0);
f01016e4:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01016eb:	00 
f01016ec:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01016f3:	00 
f01016f4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01016f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016fb:	a1 08 5a 11 f0       	mov    0xf0115a08,%eax
f0101700:	89 04 24             	mov    %eax,(%esp)
f0101703:	e8 d2 f7 ff ff       	call   f0100eda <page_insert>
f0101708:	85 c0                	test   %eax,%eax
f010170a:	74 24                	je     f0101730 <i386_vm_init+0x792>
f010170c:	c7 44 24 0c d4 3f 10 	movl   $0xf0103fd4,0xc(%esp)
f0101713:	f0 
f0101714:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f010171b:	f0 
f010171c:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
f0101723:	00 
f0101724:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f010172b:	e8 68 e9 ff ff       	call   f0100098 <_panic>
	
	assert(PTE_ADDR(boot_pgdir[0]) == page2pa(pp0));
f0101730:	8b 1d 08 5a 11 f0    	mov    0xf0115a08,%ebx
f0101736:	8b 75 d8             	mov    -0x28(%ebp),%esi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101739:	a1 0c 5a 11 f0       	mov    0xf0115a0c,%eax
f010173e:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0101741:	8b 13                	mov    (%ebx),%edx
f0101743:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101749:	89 f1                	mov    %esi,%ecx
f010174b:	29 c1                	sub    %eax,%ecx
f010174d:	89 c8                	mov    %ecx,%eax
f010174f:	c1 f8 02             	sar    $0x2,%eax
f0101752:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101758:	c1 e0 0c             	shl    $0xc,%eax
f010175b:	39 c2                	cmp    %eax,%edx
f010175d:	74 24                	je     f0101783 <i386_vm_init+0x7e5>
f010175f:	c7 44 24 0c 00 40 10 	movl   $0xf0104000,0xc(%esp)
f0101766:	f0 
f0101767:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f010176e:	f0 
f010176f:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
f0101776:	00 
f0101777:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f010177e:	e8 15 e9 ff ff       	call   f0100098 <_panic>

	assert(check_va2pa(boot_pgdir, 0x0) == page2pa(pp1));
f0101783:	ba 00 00 00 00       	mov    $0x0,%edx
f0101788:	89 d8                	mov    %ebx,%eax
f010178a:	e8 3d f2 ff ff       	call   f01009cc <check_va2pa>
f010178f:	8b 55 dc             	mov    -0x24(%ebp),%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101792:	89 d1                	mov    %edx,%ecx
f0101794:	2b 4d c0             	sub    -0x40(%ebp),%ecx
f0101797:	c1 f9 02             	sar    $0x2,%ecx
f010179a:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f01017a0:	c1 e1 0c             	shl    $0xc,%ecx
f01017a3:	39 c8                	cmp    %ecx,%eax
f01017a5:	74 24                	je     f01017cb <i386_vm_init+0x82d>
f01017a7:	c7 44 24 0c 28 40 10 	movl   $0xf0104028,0xc(%esp)
f01017ae:	f0 
f01017af:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01017b6:	f0 
f01017b7:	c7 44 24 04 d1 02 00 	movl   $0x2d1,0x4(%esp)
f01017be:	00 
f01017bf:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01017c6:	e8 cd e8 ff ff       	call   f0100098 <_panic>
	assert(pp1->pp_ref == 1);
f01017cb:	66 83 7a 08 01       	cmpw   $0x1,0x8(%edx)
f01017d0:	74 24                	je     f01017f6 <i386_vm_init+0x858>
f01017d2:	c7 44 24 0c 9f 44 10 	movl   $0xf010449f,0xc(%esp)
f01017d9:	f0 
f01017da:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01017e1:	f0 
f01017e2:	c7 44 24 04 d2 02 00 	movl   $0x2d2,0x4(%esp)
f01017e9:	00 
f01017ea:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01017f1:	e8 a2 e8 ff ff       	call   f0100098 <_panic>
	assert(pp0->pp_ref == 1);
f01017f6:	66 83 7e 08 01       	cmpw   $0x1,0x8(%esi)
f01017fb:	74 24                	je     f0101821 <i386_vm_init+0x883>
f01017fd:	c7 44 24 0c b0 44 10 	movl   $0xf01044b0,0xc(%esp)
f0101804:	f0 
f0101805:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f010180c:	f0 
f010180d:	c7 44 24 04 d3 02 00 	movl   $0x2d3,0x4(%esp)
f0101814:	00 
f0101815:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f010181c:	e8 77 e8 ff ff       	call   f0100098 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, 0) == 0);
f0101821:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101828:	00 
f0101829:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101830:	00 
f0101831:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101834:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101838:	89 1c 24             	mov    %ebx,(%esp)
f010183b:	e8 9a f6 ff ff       	call   f0100eda <page_insert>
f0101840:	85 c0                	test   %eax,%eax
f0101842:	74 24                	je     f0101868 <i386_vm_init+0x8ca>
f0101844:	c7 44 24 0c 58 40 10 	movl   $0xf0104058,0xc(%esp)
f010184b:	f0 
f010184c:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101853:	f0 
f0101854:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
f010185b:	00 
f010185c:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101863:	e8 30 e8 ff ff       	call   f0100098 <_panic>
	//cprintf("3333333333\n");
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
f0101868:	ba 00 10 00 00       	mov    $0x1000,%edx
f010186d:	a1 08 5a 11 f0       	mov    0xf0115a08,%eax
f0101872:	e8 55 f1 ff ff       	call   f01009cc <check_va2pa>
f0101877:	8b 55 e0             	mov    -0x20(%ebp),%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f010187a:	89 d1                	mov    %edx,%ecx
f010187c:	2b 0d 0c 5a 11 f0    	sub    0xf0115a0c,%ecx
f0101882:	c1 f9 02             	sar    $0x2,%ecx
f0101885:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f010188b:	c1 e1 0c             	shl    $0xc,%ecx
f010188e:	39 c8                	cmp    %ecx,%eax
f0101890:	74 24                	je     f01018b6 <i386_vm_init+0x918>
f0101892:	c7 44 24 0c 90 40 10 	movl   $0xf0104090,0xc(%esp)
f0101899:	f0 
f010189a:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01018a1:	f0 
f01018a2:	c7 44 24 04 d8 02 00 	movl   $0x2d8,0x4(%esp)
f01018a9:	00 
f01018aa:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01018b1:	e8 e2 e7 ff ff       	call   f0100098 <_panic>
	assert(pp2->pp_ref == 1);
f01018b6:	66 83 7a 08 01       	cmpw   $0x1,0x8(%edx)
f01018bb:	74 24                	je     f01018e1 <i386_vm_init+0x943>
f01018bd:	c7 44 24 0c c1 44 10 	movl   $0xf01044c1,0xc(%esp)
f01018c4:	f0 
f01018c5:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01018cc:	f0 
f01018cd:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f01018d4:	00 
f01018d5:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01018dc:	e8 b7 e7 ff ff       	call   f0100098 <_panic>

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f01018e1:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f01018e4:	89 04 24             	mov    %eax,(%esp)
f01018e7:	e8 2a f3 ff ff       	call   f0100c16 <page_alloc>
f01018ec:	83 f8 fc             	cmp    $0xfffffffc,%eax
f01018ef:	74 24                	je     f0101915 <i386_vm_init+0x977>
f01018f1:	c7 44 24 0c 82 44 10 	movl   $0xf0104482,0xc(%esp)
f01018f8:	f0 
f01018f9:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101900:	f0 
f0101901:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
f0101908:	00 
f0101909:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101910:	e8 83 e7 ff ff       	call   f0100098 <_panic>
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, 0) == 0);
f0101915:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010191c:	00 
f010191d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101924:	00 
f0101925:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101928:	89 44 24 04          	mov    %eax,0x4(%esp)
f010192c:	a1 08 5a 11 f0       	mov    0xf0115a08,%eax
f0101931:	89 04 24             	mov    %eax,(%esp)
f0101934:	e8 a1 f5 ff ff       	call   f0100eda <page_insert>
f0101939:	85 c0                	test   %eax,%eax
f010193b:	74 24                	je     f0101961 <i386_vm_init+0x9c3>
f010193d:	c7 44 24 0c 58 40 10 	movl   $0xf0104058,0xc(%esp)
f0101944:	f0 
f0101945:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f010194c:	f0 
f010194d:	c7 44 24 04 de 02 00 	movl   $0x2de,0x4(%esp)
f0101954:	00 
f0101955:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f010195c:	e8 37 e7 ff ff       	call   f0100098 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
f0101961:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101966:	a1 08 5a 11 f0       	mov    0xf0115a08,%eax
f010196b:	e8 5c f0 ff ff       	call   f01009cc <check_va2pa>
f0101970:	8b 55 e0             	mov    -0x20(%ebp),%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101973:	89 d1                	mov    %edx,%ecx
f0101975:	2b 0d 0c 5a 11 f0    	sub    0xf0115a0c,%ecx
f010197b:	c1 f9 02             	sar    $0x2,%ecx
f010197e:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101984:	c1 e1 0c             	shl    $0xc,%ecx
f0101987:	39 c8                	cmp    %ecx,%eax
f0101989:	74 24                	je     f01019af <i386_vm_init+0xa11>
f010198b:	c7 44 24 0c 90 40 10 	movl   $0xf0104090,0xc(%esp)
f0101992:	f0 
f0101993:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f010199a:	f0 
f010199b:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f01019a2:	00 
f01019a3:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01019aa:	e8 e9 e6 ff ff       	call   f0100098 <_panic>
	assert(pp2->pp_ref == 1);
f01019af:	66 83 7a 08 01       	cmpw   $0x1,0x8(%edx)
f01019b4:	74 24                	je     f01019da <i386_vm_init+0xa3c>
f01019b6:	c7 44 24 0c c1 44 10 	movl   $0xf01044c1,0xc(%esp)
f01019bd:	f0 
f01019be:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01019c5:	f0 
f01019c6:	c7 44 24 04 e0 02 00 	movl   $0x2e0,0x4(%esp)
f01019cd:	00 
f01019ce:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01019d5:	e8 be e6 ff ff       	call   f0100098 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(page_alloc(&pp) == -E_NO_MEM);
f01019da:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f01019dd:	89 04 24             	mov    %eax,(%esp)
f01019e0:	e8 31 f2 ff ff       	call   f0100c16 <page_alloc>
f01019e5:	83 f8 fc             	cmp    $0xfffffffc,%eax
f01019e8:	74 24                	je     f0101a0e <i386_vm_init+0xa70>
f01019ea:	c7 44 24 0c 82 44 10 	movl   $0xf0104482,0xc(%esp)
f01019f1:	f0 
f01019f2:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01019f9:	f0 
f01019fa:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
f0101a01:	00 
f0101a02:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101a09:	e8 8a e6 ff ff       	call   f0100098 <_panic>
	// check that pgdir_walk returns a pointer to the pte
	ptep = KADDR(PTE_ADDR(boot_pgdir[PDX(PGSIZE)]));
f0101a0e:	8b 15 08 5a 11 f0    	mov    0xf0115a08,%edx
f0101a14:	8b 02                	mov    (%edx),%eax
f0101a16:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101a1b:	89 c1                	mov    %eax,%ecx
f0101a1d:	c1 e9 0c             	shr    $0xc,%ecx
f0101a20:	3b 0d 00 5a 11 f0    	cmp    0xf0115a00,%ecx
f0101a26:	72 20                	jb     f0101a48 <i386_vm_init+0xaaa>
f0101a28:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101a2c:	c7 44 24 08 a4 3e 10 	movl   $0xf0103ea4,0x8(%esp)
f0101a33:	f0 
f0101a34:	c7 44 24 04 e6 02 00 	movl   $0x2e6,0x4(%esp)
f0101a3b:	00 
f0101a3c:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101a43:	e8 50 e6 ff ff       	call   f0100098 <_panic>
f0101a48:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a4d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(boot_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101a50:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a57:	00 
f0101a58:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101a5f:	00 
f0101a60:	89 14 24             	mov    %edx,(%esp)
f0101a63:	e8 54 f2 ff ff       	call   f0100cbc <pgdir_walk>
f0101a68:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101a6b:	8d 56 04             	lea    0x4(%esi),%edx
f0101a6e:	39 d0                	cmp    %edx,%eax
f0101a70:	74 24                	je     f0101a96 <i386_vm_init+0xaf8>
f0101a72:	c7 44 24 0c c0 40 10 	movl   $0xf01040c0,0xc(%esp)
f0101a79:	f0 
f0101a7a:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101a81:	f0 
f0101a82:	c7 44 24 04 e7 02 00 	movl   $0x2e7,0x4(%esp)
f0101a89:	00 
f0101a8a:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101a91:	e8 02 e6 ff ff       	call   f0100098 <_panic>

	// should be able to change permissions too.
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, PTE_U) == 0);
f0101a96:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0101a9d:	00 
f0101a9e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101aa5:	00 
f0101aa6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101aa9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101aad:	a1 08 5a 11 f0       	mov    0xf0115a08,%eax
f0101ab2:	89 04 24             	mov    %eax,(%esp)
f0101ab5:	e8 20 f4 ff ff       	call   f0100eda <page_insert>
f0101aba:	85 c0                	test   %eax,%eax
f0101abc:	74 24                	je     f0101ae2 <i386_vm_init+0xb44>
f0101abe:	c7 44 24 0c 00 41 10 	movl   $0xf0104100,0xc(%esp)
f0101ac5:	f0 
f0101ac6:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101acd:	f0 
f0101ace:	c7 44 24 04 ea 02 00 	movl   $0x2ea,0x4(%esp)
f0101ad5:	00 
f0101ad6:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101add:	e8 b6 e5 ff ff       	call   f0100098 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
f0101ae2:	8b 1d 08 5a 11 f0    	mov    0xf0115a08,%ebx
f0101ae8:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101aed:	89 d8                	mov    %ebx,%eax
f0101aef:	e8 d8 ee ff ff       	call   f01009cc <check_va2pa>
f0101af4:	8b 55 e0             	mov    -0x20(%ebp),%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101af7:	89 d1                	mov    %edx,%ecx
f0101af9:	2b 0d 0c 5a 11 f0    	sub    0xf0115a0c,%ecx
f0101aff:	c1 f9 02             	sar    $0x2,%ecx
f0101b02:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101b08:	c1 e1 0c             	shl    $0xc,%ecx
f0101b0b:	39 c8                	cmp    %ecx,%eax
f0101b0d:	74 24                	je     f0101b33 <i386_vm_init+0xb95>
f0101b0f:	c7 44 24 0c 90 40 10 	movl   $0xf0104090,0xc(%esp)
f0101b16:	f0 
f0101b17:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101b1e:	f0 
f0101b1f:	c7 44 24 04 eb 02 00 	movl   $0x2eb,0x4(%esp)
f0101b26:	00 
f0101b27:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101b2e:	e8 65 e5 ff ff       	call   f0100098 <_panic>
	assert(pp2->pp_ref == 1);
f0101b33:	66 83 7a 08 01       	cmpw   $0x1,0x8(%edx)
f0101b38:	74 24                	je     f0101b5e <i386_vm_init+0xbc0>
f0101b3a:	c7 44 24 0c c1 44 10 	movl   $0xf01044c1,0xc(%esp)
f0101b41:	f0 
f0101b42:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101b49:	f0 
f0101b4a:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f0101b51:	00 
f0101b52:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101b59:	e8 3a e5 ff ff       	call   f0100098 <_panic>
	//cprintf("11111111\n");
	assert(*pgdir_walk(boot_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101b5e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101b65:	00 
f0101b66:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101b6d:	00 
f0101b6e:	89 1c 24             	mov    %ebx,(%esp)
f0101b71:	e8 46 f1 ff ff       	call   f0100cbc <pgdir_walk>
f0101b76:	f6 00 04             	testb  $0x4,(%eax)
f0101b79:	75 24                	jne    f0101b9f <i386_vm_init+0xc01>
f0101b7b:	c7 44 24 0c 3c 41 10 	movl   $0xf010413c,0xc(%esp)
f0101b82:	f0 
f0101b83:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101b8a:	f0 
f0101b8b:	c7 44 24 04 ee 02 00 	movl   $0x2ee,0x4(%esp)
f0101b92:	00 
f0101b93:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101b9a:	e8 f9 e4 ff ff       	call   f0100098 <_panic>
	
	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(boot_pgdir, pp0, (void*) PTSIZE, 0) < 0);
f0101b9f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101ba6:	00 
f0101ba7:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101bae:	00 
f0101baf:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101bb2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101bb6:	a1 08 5a 11 f0       	mov    0xf0115a08,%eax
f0101bbb:	89 04 24             	mov    %eax,(%esp)
f0101bbe:	e8 17 f3 ff ff       	call   f0100eda <page_insert>
f0101bc3:	85 c0                	test   %eax,%eax
f0101bc5:	78 24                	js     f0101beb <i386_vm_init+0xc4d>
f0101bc7:	c7 44 24 0c 70 41 10 	movl   $0xf0104170,0xc(%esp)
f0101bce:	f0 
f0101bcf:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101bd6:	f0 
f0101bd7:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f0101bde:	00 
f0101bdf:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101be6:	e8 ad e4 ff ff       	call   f0100098 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(boot_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101beb:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101bf2:	00 
f0101bf3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101bfa:	00 
f0101bfb:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101bfe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101c02:	a1 08 5a 11 f0       	mov    0xf0115a08,%eax
f0101c07:	89 04 24             	mov    %eax,(%esp)
f0101c0a:	e8 cb f2 ff ff       	call   f0100eda <page_insert>
f0101c0f:	85 c0                	test   %eax,%eax
f0101c11:	74 24                	je     f0101c37 <i386_vm_init+0xc99>
f0101c13:	c7 44 24 0c a4 41 10 	movl   $0xf01041a4,0xc(%esp)
f0101c1a:	f0 
f0101c1b:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101c22:	f0 
f0101c23:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
f0101c2a:	00 
f0101c2b:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101c32:	e8 61 e4 ff ff       	call   f0100098 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(boot_pgdir, 0) == page2pa(pp1));
f0101c37:	a1 08 5a 11 f0       	mov    0xf0115a08,%eax
f0101c3c:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0101c3f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c44:	e8 83 ed ff ff       	call   f01009cc <check_va2pa>
f0101c49:	89 c6                	mov    %eax,%esi
f0101c4b:	8b 5d dc             	mov    -0x24(%ebp),%ebx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101c4e:	89 d8                	mov    %ebx,%eax
f0101c50:	2b 05 0c 5a 11 f0    	sub    0xf0115a0c,%eax
f0101c56:	c1 f8 02             	sar    $0x2,%eax
f0101c59:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101c5f:	c1 e0 0c             	shl    $0xc,%eax
f0101c62:	39 c6                	cmp    %eax,%esi
f0101c64:	74 24                	je     f0101c8a <i386_vm_init+0xcec>
f0101c66:	c7 44 24 0c dc 41 10 	movl   $0xf01041dc,0xc(%esp)
f0101c6d:	f0 
f0101c6e:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101c75:	f0 
f0101c76:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f0101c7d:	00 
f0101c7e:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101c85:	e8 0e e4 ff ff       	call   f0100098 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp1));
f0101c8a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c8f:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0101c92:	e8 35 ed ff ff       	call   f01009cc <check_va2pa>
f0101c97:	39 c6                	cmp    %eax,%esi
f0101c99:	74 24                	je     f0101cbf <i386_vm_init+0xd21>
f0101c9b:	c7 44 24 0c 08 42 10 	movl   $0xf0104208,0xc(%esp)
f0101ca2:	f0 
f0101ca3:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101caa:	f0 
f0101cab:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0101cb2:	00 
f0101cb3:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101cba:	e8 d9 e3 ff ff       	call   f0100098 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101cbf:	66 83 7b 08 02       	cmpw   $0x2,0x8(%ebx)
f0101cc4:	74 24                	je     f0101cea <i386_vm_init+0xd4c>
f0101cc6:	c7 44 24 0c d2 44 10 	movl   $0xf01044d2,0xc(%esp)
f0101ccd:	f0 
f0101cce:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101cd5:	f0 
f0101cd6:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
f0101cdd:	00 
f0101cde:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101ce5:	e8 ae e3 ff ff       	call   f0100098 <_panic>
	assert(pp2->pp_ref == 0);
f0101cea:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101ced:	66 83 78 08 00       	cmpw   $0x0,0x8(%eax)
f0101cf2:	74 24                	je     f0101d18 <i386_vm_init+0xd7a>
f0101cf4:	c7 44 24 0c e3 44 10 	movl   $0xf01044e3,0xc(%esp)
f0101cfb:	f0 
f0101cfc:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101d03:	f0 
f0101d04:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
f0101d0b:	00 
f0101d0c:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101d13:	e8 80 e3 ff ff       	call   f0100098 <_panic>

	// pp2 should be returned by page_alloc
	assert(page_alloc(&pp) == 0 && pp == pp2);
f0101d18:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0101d1b:	89 04 24             	mov    %eax,(%esp)
f0101d1e:	e8 f3 ee ff ff       	call   f0100c16 <page_alloc>
f0101d23:	85 c0                	test   %eax,%eax
f0101d25:	75 08                	jne    f0101d2f <i386_vm_init+0xd91>
f0101d27:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101d2a:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101d2d:	74 24                	je     f0101d53 <i386_vm_init+0xdb5>
f0101d2f:	c7 44 24 0c 38 42 10 	movl   $0xf0104238,0xc(%esp)
f0101d36:	f0 
f0101d37:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101d3e:	f0 
f0101d3f:	c7 44 24 04 fe 02 00 	movl   $0x2fe,0x4(%esp)
f0101d46:	00 
f0101d47:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101d4e:	e8 45 e3 ff ff       	call   f0100098 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(boot_pgdir, 0x0);
f0101d53:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101d5a:	00 
f0101d5b:	a1 08 5a 11 f0       	mov    0xf0115a08,%eax
f0101d60:	89 04 24             	mov    %eax,(%esp)
f0101d63:	e8 30 f1 ff ff       	call   f0100e98 <page_remove>
	assert(check_va2pa(boot_pgdir, 0x0) == ~0);
f0101d68:	8b 1d 08 5a 11 f0    	mov    0xf0115a08,%ebx
f0101d6e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d73:	89 d8                	mov    %ebx,%eax
f0101d75:	e8 52 ec ff ff       	call   f01009cc <check_va2pa>
f0101d7a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d7d:	74 24                	je     f0101da3 <i386_vm_init+0xe05>
f0101d7f:	c7 44 24 0c 5c 42 10 	movl   $0xf010425c,0xc(%esp)
f0101d86:	f0 
f0101d87:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101d8e:	f0 
f0101d8f:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0101d96:	00 
f0101d97:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101d9e:	e8 f5 e2 ff ff       	call   f0100098 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp1));
f0101da3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101da8:	89 d8                	mov    %ebx,%eax
f0101daa:	e8 1d ec ff ff       	call   f01009cc <check_va2pa>
f0101daf:	8b 55 dc             	mov    -0x24(%ebp),%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101db2:	89 d1                	mov    %edx,%ecx
f0101db4:	2b 0d 0c 5a 11 f0    	sub    0xf0115a0c,%ecx
f0101dba:	c1 f9 02             	sar    $0x2,%ecx
f0101dbd:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101dc3:	c1 e1 0c             	shl    $0xc,%ecx
f0101dc6:	39 c8                	cmp    %ecx,%eax
f0101dc8:	74 24                	je     f0101dee <i386_vm_init+0xe50>
f0101dca:	c7 44 24 0c 08 42 10 	movl   $0xf0104208,0xc(%esp)
f0101dd1:	f0 
f0101dd2:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101dd9:	f0 
f0101dda:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0101de1:	00 
f0101de2:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101de9:	e8 aa e2 ff ff       	call   f0100098 <_panic>
	assert(pp1->pp_ref == 1);
f0101dee:	66 83 7a 08 01       	cmpw   $0x1,0x8(%edx)
f0101df3:	74 24                	je     f0101e19 <i386_vm_init+0xe7b>
f0101df5:	c7 44 24 0c 9f 44 10 	movl   $0xf010449f,0xc(%esp)
f0101dfc:	f0 
f0101dfd:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101e04:	f0 
f0101e05:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f0101e0c:	00 
f0101e0d:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101e14:	e8 7f e2 ff ff       	call   f0100098 <_panic>
	assert(pp2->pp_ref == 0);
f0101e19:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101e1c:	66 83 78 08 00       	cmpw   $0x0,0x8(%eax)
f0101e21:	74 24                	je     f0101e47 <i386_vm_init+0xea9>
f0101e23:	c7 44 24 0c e3 44 10 	movl   $0xf01044e3,0xc(%esp)
f0101e2a:	f0 
f0101e2b:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101e32:	f0 
f0101e33:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0101e3a:	00 
f0101e3b:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101e42:	e8 51 e2 ff ff       	call   f0100098 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(boot_pgdir, (void*) PGSIZE);
f0101e47:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e4e:	00 
f0101e4f:	89 1c 24             	mov    %ebx,(%esp)
f0101e52:	e8 41 f0 ff ff       	call   f0100e98 <page_remove>
	assert(check_va2pa(boot_pgdir, 0x0) == ~0);
f0101e57:	8b 1d 08 5a 11 f0    	mov    0xf0115a08,%ebx
f0101e5d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e62:	89 d8                	mov    %ebx,%eax
f0101e64:	e8 63 eb ff ff       	call   f01009cc <check_va2pa>
f0101e69:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e6c:	74 24                	je     f0101e92 <i386_vm_init+0xef4>
f0101e6e:	c7 44 24 0c 5c 42 10 	movl   $0xf010425c,0xc(%esp)
f0101e75:	f0 
f0101e76:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101e7d:	f0 
f0101e7e:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0101e85:	00 
f0101e86:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101e8d:	e8 06 e2 ff ff       	call   f0100098 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == ~0);
f0101e92:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e97:	89 d8                	mov    %ebx,%eax
f0101e99:	e8 2e eb ff ff       	call   f01009cc <check_va2pa>
f0101e9e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ea1:	74 24                	je     f0101ec7 <i386_vm_init+0xf29>
f0101ea3:	c7 44 24 0c 80 42 10 	movl   $0xf0104280,0xc(%esp)
f0101eaa:	f0 
f0101eab:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101eb2:	f0 
f0101eb3:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0101eba:	00 
f0101ebb:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101ec2:	e8 d1 e1 ff ff       	call   f0100098 <_panic>
	assert(pp1->pp_ref == 0);
f0101ec7:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101eca:	66 83 78 08 00       	cmpw   $0x0,0x8(%eax)
f0101ecf:	74 24                	je     f0101ef5 <i386_vm_init+0xf57>
f0101ed1:	c7 44 24 0c f4 44 10 	movl   $0xf01044f4,0xc(%esp)
f0101ed8:	f0 
f0101ed9:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101ee0:	f0 
f0101ee1:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0101ee8:	00 
f0101ee9:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101ef0:	e8 a3 e1 ff ff       	call   f0100098 <_panic>
	assert(pp2->pp_ref == 0);
f0101ef5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101ef8:	66 83 78 08 00       	cmpw   $0x0,0x8(%eax)
f0101efd:	74 24                	je     f0101f23 <i386_vm_init+0xf85>
f0101eff:	c7 44 24 0c e3 44 10 	movl   $0xf01044e3,0xc(%esp)
f0101f06:	f0 
f0101f07:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101f0e:	f0 
f0101f0f:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f0101f16:	00 
f0101f17:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101f1e:	e8 75 e1 ff ff       	call   f0100098 <_panic>

	// so it should be returned by page_alloc
	assert(page_alloc(&pp) == 0 && pp == pp1);
f0101f23:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0101f26:	89 04 24             	mov    %eax,(%esp)
f0101f29:	e8 e8 ec ff ff       	call   f0100c16 <page_alloc>
f0101f2e:	85 c0                	test   %eax,%eax
f0101f30:	75 08                	jne    f0101f3a <i386_vm_init+0xf9c>
f0101f32:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101f35:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101f38:	74 24                	je     f0101f5e <i386_vm_init+0xfc0>
f0101f3a:	c7 44 24 0c a8 42 10 	movl   $0xf01042a8,0xc(%esp)
f0101f41:	f0 
f0101f42:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101f49:	f0 
f0101f4a:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0101f51:	00 
f0101f52:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101f59:	e8 3a e1 ff ff       	call   f0100098 <_panic>

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f0101f5e:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0101f61:	89 04 24             	mov    %eax,(%esp)
f0101f64:	e8 ad ec ff ff       	call   f0100c16 <page_alloc>
f0101f69:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101f6c:	74 24                	je     f0101f92 <i386_vm_init+0xff4>
f0101f6e:	c7 44 24 0c 82 44 10 	movl   $0xf0104482,0xc(%esp)
f0101f75:	f0 
f0101f76:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101f7d:	f0 
f0101f7e:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0101f85:	00 
f0101f86:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101f8d:	e8 06 e1 ff ff       	call   f0100098 <_panic>
	page_remove(boot_pgdir, 0x0);
	assert(pp2->pp_ref == 0);
#endif

	// forcibly take pp0 back
	assert(PTE_ADDR(boot_pgdir[0]) == page2pa(pp0));
f0101f92:	a1 08 5a 11 f0       	mov    0xf0115a08,%eax
f0101f97:	8b 08                	mov    (%eax),%ecx
f0101f99:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101f9f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101fa2:	2b 15 0c 5a 11 f0    	sub    0xf0115a0c,%edx
f0101fa8:	c1 fa 02             	sar    $0x2,%edx
f0101fab:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101fb1:	c1 e2 0c             	shl    $0xc,%edx
f0101fb4:	39 d1                	cmp    %edx,%ecx
f0101fb6:	74 24                	je     f0101fdc <i386_vm_init+0x103e>
f0101fb8:	c7 44 24 0c 00 40 10 	movl   $0xf0104000,0xc(%esp)
f0101fbf:	f0 
f0101fc0:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101fc7:	f0 
f0101fc8:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101fcf:	00 
f0101fd0:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0101fd7:	e8 bc e0 ff ff       	call   f0100098 <_panic>
	boot_pgdir[0] = 0;
f0101fdc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0101fe2:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101fe5:	66 83 78 08 01       	cmpw   $0x1,0x8(%eax)
f0101fea:	74 24                	je     f0102010 <i386_vm_init+0x1072>
f0101fec:	c7 44 24 0c b0 44 10 	movl   $0xf01044b0,0xc(%esp)
f0101ff3:	f0 
f0101ff4:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0101ffb:	f0 
f0101ffc:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0102003:	00 
f0102004:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f010200b:	e8 88 e0 ff ff       	call   f0100098 <_panic>
	pp0->pp_ref = 0;
f0102010:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
	
	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102016:	89 04 24             	mov    %eax,(%esp)
f0102019:	e8 2c ec ff ff       	call   f0100c4a <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(boot_pgdir, va, 1);
f010201e:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102025:	00 
f0102026:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010202d:	00 
f010202e:	a1 08 5a 11 f0       	mov    0xf0115a08,%eax
f0102033:	89 04 24             	mov    %eax,(%esp)
f0102036:	e8 81 ec ff ff       	call   f0100cbc <pgdir_walk>
f010203b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = KADDR(PTE_ADDR(boot_pgdir[PDX(va)]));
f010203e:	8b 1d 08 5a 11 f0    	mov    0xf0115a08,%ebx
f0102044:	8b 53 04             	mov    0x4(%ebx),%edx
f0102047:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010204d:	8b 0d 00 5a 11 f0    	mov    0xf0115a00,%ecx
f0102053:	89 d6                	mov    %edx,%esi
f0102055:	c1 ee 0c             	shr    $0xc,%esi
f0102058:	39 ce                	cmp    %ecx,%esi
f010205a:	72 20                	jb     f010207c <i386_vm_init+0x10de>
f010205c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102060:	c7 44 24 08 a4 3e 10 	movl   $0xf0103ea4,0x8(%esp)
f0102067:	f0 
f0102068:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f010206f:	00 
f0102070:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0102077:	e8 1c e0 ff ff       	call   f0100098 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010207c:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102082:	39 d0                	cmp    %edx,%eax
f0102084:	74 24                	je     f01020aa <i386_vm_init+0x110c>
f0102086:	c7 44 24 0c 05 45 10 	movl   $0xf0104505,0xc(%esp)
f010208d:	f0 
f010208e:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0102095:	f0 
f0102096:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f010209d:	00 
f010209e:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01020a5:	e8 ee df ff ff       	call   f0100098 <_panic>
	boot_pgdir[PDX(va)] = 0;
f01020aa:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f01020b1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01020b4:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f01020ba:	2b 05 0c 5a 11 f0    	sub    0xf0115a0c,%eax
f01020c0:	c1 f8 02             	sar    $0x2,%eax
f01020c3:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f01020c9:	c1 e0 0c             	shl    $0xc,%eax
}

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
f01020cc:	89 c2                	mov    %eax,%edx
f01020ce:	c1 ea 0c             	shr    $0xc,%edx
f01020d1:	39 d1                	cmp    %edx,%ecx
f01020d3:	77 20                	ja     f01020f5 <i386_vm_init+0x1157>
f01020d5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01020d9:	c7 44 24 08 a4 3e 10 	movl   $0xf0103ea4,0x8(%esp)
f01020e0:	f0 
f01020e1:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01020e8:	00 
f01020e9:	c7 04 24 b7 43 10 f0 	movl   $0xf01043b7,(%esp)
f01020f0:	e8 a3 df ff ff       	call   f0100098 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01020f5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01020fc:	00 
f01020fd:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102104:	00 
f0102105:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010210a:	89 04 24             	mov    %eax,(%esp)
f010210d:	e8 fd 13 00 00       	call   f010350f <memset>
	page_free(pp0);
f0102112:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102115:	89 04 24             	mov    %eax,(%esp)
f0102118:	e8 2d eb ff ff       	call   f0100c4a <page_free>
	pgdir_walk(boot_pgdir, 0x0, 1);
f010211d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102124:	00 
f0102125:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010212c:	00 
f010212d:	a1 08 5a 11 f0       	mov    0xf0115a08,%eax
f0102132:	89 04 24             	mov    %eax,(%esp)
f0102135:	e8 82 eb ff ff       	call   f0100cbc <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f010213a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010213d:	2b 15 0c 5a 11 f0    	sub    0xf0115a0c,%edx
f0102143:	c1 fa 02             	sar    $0x2,%edx
f0102146:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f010214c:	c1 e2 0c             	shl    $0xc,%edx
}

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
f010214f:	89 d0                	mov    %edx,%eax
f0102151:	c1 e8 0c             	shr    $0xc,%eax
f0102154:	3b 05 00 5a 11 f0    	cmp    0xf0115a00,%eax
f010215a:	72 20                	jb     f010217c <i386_vm_init+0x11de>
f010215c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102160:	c7 44 24 08 a4 3e 10 	movl   $0xf0103ea4,0x8(%esp)
f0102167:	f0 
f0102168:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010216f:	00 
f0102170:	c7 04 24 b7 43 10 f0 	movl   $0xf01043b7,(%esp)
f0102177:	e8 1c df ff ff       	call   f0100098 <_panic>
f010217c:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = page2kva(pp0);
f0102182:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102185:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f010218c:	75 11                	jne    f010219f <i386_vm_init+0x1201>
f010218e:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
f0102194:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
f010219a:	f6 00 01             	testb  $0x1,(%eax)
f010219d:	74 24                	je     f01021c3 <i386_vm_init+0x1225>
f010219f:	c7 44 24 0c 1d 45 10 	movl   $0xf010451d,0xc(%esp)
f01021a6:	f0 
f01021a7:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01021ae:	f0 
f01021af:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f01021b6:	00 
f01021b7:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01021be:	e8 d5 de ff ff       	call   f0100098 <_panic>
f01021c3:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(boot_pgdir, 0x0, 1);
	ptep = page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01021c6:	39 d0                	cmp    %edx,%eax
f01021c8:	75 d0                	jne    f010219a <i386_vm_init+0x11fc>
		assert((ptep[i] & PTE_P) == 0);
	boot_pgdir[0] = 0;
f01021ca:	a1 08 5a 11 f0       	mov    0xf0115a08,%eax
f01021cf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01021d5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01021d8:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)

	// give free list back
	page_free_list = fl;
f01021de:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01021e1:	89 35 d8 55 11 f0    	mov    %esi,0xf01155d8

	// free the pages we took
	page_free(pp0);
f01021e7:	89 04 24             	mov    %eax,(%esp)
f01021ea:	e8 5b ea ff ff       	call   f0100c4a <page_free>
	page_free(pp1);
f01021ef:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01021f2:	89 04 24             	mov    %eax,(%esp)
f01021f5:	e8 50 ea ff ff       	call   f0100c4a <page_free>
	page_free(pp2);
f01021fa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01021fd:	89 04 24             	mov    %eax,(%esp)
f0102200:	e8 45 ea ff ff       	call   f0100c4a <page_free>
	
	cprintf("page_check() succeeded!\n");
f0102205:	c7 04 24 34 45 10 f0 	movl   $0xf0104534,(%esp)
f010220c:	e8 88 07 00 00       	call   f0102999 <cprintf>
	// Permissions:
	//    - pages -- kernel RW, user NONE
	//    - the read-only version mapped at UPAGES -- kernel R, user R
	// Your code goes here:

	boot_map_segment(pgdir, UPAGES, (void *)boot_freemem-(void *)pages, PADDR(pages), PTE_U | PTE_P);
f0102211:	a1 0c 5a 11 f0       	mov    0xf0115a0c,%eax
f0102216:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010221b:	77 20                	ja     f010223d <i386_vm_init+0x129f>
f010221d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102221:	c7 44 24 08 0c 3f 10 	movl   $0xf0103f0c,0x8(%esp)
f0102228:	f0 
f0102229:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
f0102230:	00 
f0102231:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0102238:	e8 5b de ff ff       	call   f0100098 <_panic>
f010223d:	8b 0d dc 55 11 f0    	mov    0xf01155dc,%ecx
f0102243:	29 c1                	sub    %eax,%ecx
f0102245:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f010224c:	00 
f010224d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102252:	89 04 24             	mov    %eax,(%esp)
f0102255:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010225a:	89 f8                	mov    %edi,%eax
f010225c:	e8 69 eb ff ff       	call   f0100dca <boot_map_segment>
	//     * [KSTACKTOP-KSTKSIZE, KSTACKTOP) -- backed by physical memory
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed => faults
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_segment(pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f0102261:	bb 00 d0 10 f0       	mov    $0xf010d000,%ebx
f0102266:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f010226c:	77 20                	ja     f010228e <i386_vm_init+0x12f0>
f010226e:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102272:	c7 44 24 08 0c 3f 10 	movl   $0xf0103f0c,0x8(%esp)
f0102279:	f0 
f010227a:	c7 44 24 04 d9 00 00 	movl   $0xd9,0x4(%esp)
f0102281:	00 
f0102282:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0102289:	e8 0a de ff ff       	call   f0100098 <_panic>
f010228e:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102295:	00 
f0102296:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f010229d:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01022a2:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f01022a7:	89 f8                	mov    %edi,%eax
f01022a9:	e8 1c eb ff ff       	call   f0100dca <boot_map_segment>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the amapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here: 
	boot_map_segment(pgdir, KERNBASE, 0xFFFFFFFF - KERNBASE + 1, 0, PTE_W | PTE_P);
f01022ae:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01022b5:	00 
f01022b6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022bd:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01022c2:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01022c7:	89 f8                	mov    %edi,%eax
f01022c9:	e8 fc ea ff ff       	call   f0100dca <boot_map_segment>
check_boot_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = boot_pgdir;
f01022ce:	a1 08 5a 11 f0       	mov    0xf0115a08,%eax
f01022d3:	89 c1                	mov    %eax,%ecx
f01022d5:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
f01022d8:	a1 00 5a 11 f0       	mov    0xf0115a00,%eax
f01022dd:	89 45 c0             	mov    %eax,-0x40(%ebp)
f01022e0:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01022e3:	8d 04 85 ff 0f 00 00 	lea    0xfff(,%eax,4),%eax
	for (i = 0; i < n; i += PGSIZE)
f01022ea:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01022ef:	89 45 bc             	mov    %eax,-0x44(%ebp)
f01022f2:	0f 84 85 00 00 00    	je     f010237d <i386_vm_init+0x13df>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01022f8:	8b 35 0c 5a 11 f0    	mov    0xf0115a0c,%esi
f01022fe:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0102304:	89 45 b8             	mov    %eax,-0x48(%ebp)
f0102307:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010230c:	89 c8                	mov    %ecx,%eax
f010230e:	e8 b9 e6 ff ff       	call   f01009cc <check_va2pa>
f0102313:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102319:	77 20                	ja     f010233b <i386_vm_init+0x139d>
f010231b:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010231f:	c7 44 24 08 0c 3f 10 	movl   $0xf0103f0c,0x8(%esp)
f0102326:	f0 
f0102327:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f010232e:	00 
f010232f:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0102336:	e8 5d dd ff ff       	call   f0100098 <_panic>

	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010233b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102340:	8b 75 b8             	mov    -0x48(%ebp),%esi
f0102343:	8d 0c 16             	lea    (%esi,%edx,1),%ecx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102346:	39 c8                	cmp    %ecx,%eax
f0102348:	74 24                	je     f010236e <i386_vm_init+0x13d0>
f010234a:	c7 44 24 0c cc 42 10 	movl   $0xf01042cc,0xc(%esp)
f0102351:	f0 
f0102352:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0102359:	f0 
f010235a:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f0102361:	00 
f0102362:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0102369:	e8 2a dd ff ff       	call   f0100098 <_panic>

	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010236e:	8d b2 00 10 00 00    	lea    0x1000(%edx),%esi
f0102374:	39 75 bc             	cmp    %esi,-0x44(%ebp)
f0102377:	0f 87 c3 01 00 00    	ja     f0102540 <i386_vm_init+0x15a2>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	

	// check phys mem
	for (i = 0; i < npage; i += PGSIZE)
f010237d:	83 7d c0 00          	cmpl   $0x0,-0x40(%ebp)
f0102381:	0f 84 99 01 00 00    	je     f0102520 <i386_vm_init+0x1582>
f0102387:	be 00 00 00 00       	mov    $0x0,%esi
f010238c:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102392:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0102395:	e8 32 e6 ff ff       	call   f01009cc <check_va2pa>
f010239a:	39 c6                	cmp    %eax,%esi
f010239c:	74 24                	je     f01023c2 <i386_vm_init+0x1424>
f010239e:	c7 44 24 0c 00 43 10 	movl   $0xf0104300,0xc(%esp)
f01023a5:	f0 
f01023a6:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01023ad:	f0 
f01023ae:	c7 44 24 04 6e 01 00 	movl   $0x16e,0x4(%esp)
f01023b5:	00 
f01023b6:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01023bd:	e8 d6 dc ff ff       	call   f0100098 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	

	// check phys mem
	for (i = 0; i < npage; i += PGSIZE)
f01023c2:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01023c8:	39 75 c0             	cmp    %esi,-0x40(%ebp)
f01023cb:	77 bf                	ja     f010238c <i386_vm_init+0x13ee>
f01023cd:	e9 4e 01 00 00       	jmp    f0102520 <i386_vm_init+0x1582>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01023d2:	39 f0                	cmp    %esi,%eax
f01023d4:	74 24                	je     f01023fa <i386_vm_init+0x145c>
f01023d6:	c7 44 24 0c 28 43 10 	movl   $0xf0104328,0xc(%esp)
f01023dd:	f0 
f01023de:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f01023e5:	f0 
f01023e6:	c7 44 24 04 72 01 00 	movl   $0x172,0x4(%esp)
f01023ed:	00 
f01023ee:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f01023f5:	e8 9e dc ff ff       	call   f0100098 <_panic>
f01023fa:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npage; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102400:	81 fe 00 50 11 00    	cmp    $0x115000,%esi
f0102406:	0f 85 04 01 00 00    	jne    f0102510 <i386_vm_init+0x1572>
f010240c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102411:	8b 55 c4             	mov    -0x3c(%ebp),%edx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102414:	8d 88 44 fc ff ff    	lea    -0x3bc(%eax),%ecx
f010241a:	83 f9 03             	cmp    $0x3,%ecx
f010241d:	77 2a                	ja     f0102449 <i386_vm_init+0x14ab>
		case PDX(VPT):
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i]);
f010241f:	83 3c 82 00          	cmpl   $0x0,(%edx,%eax,4)
f0102423:	75 7f                	jne    f01024a4 <i386_vm_init+0x1506>
f0102425:	c7 44 24 0c 4d 45 10 	movl   $0xf010454d,0xc(%esp)
f010242c:	f0 
f010242d:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0102434:	f0 
f0102435:	c7 44 24 04 7b 01 00 	movl   $0x17b,0x4(%esp)
f010243c:	00 
f010243d:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0102444:	e8 4f dc ff ff       	call   f0100098 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE))
f0102449:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010244e:	76 2a                	jbe    f010247a <i386_vm_init+0x14dc>
				assert(pgdir[i]);
f0102450:	83 3c 82 00          	cmpl   $0x0,(%edx,%eax,4)
f0102454:	75 4e                	jne    f01024a4 <i386_vm_init+0x1506>
f0102456:	c7 44 24 0c 4d 45 10 	movl   $0xf010454d,0xc(%esp)
f010245d:	f0 
f010245e:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f0102465:	f0 
f0102466:	c7 44 24 04 7f 01 00 	movl   $0x17f,0x4(%esp)
f010246d:	00 
f010246e:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f0102475:	e8 1e dc ff ff       	call   f0100098 <_panic>
			else
				assert(pgdir[i] == 0);
f010247a:	83 3c 82 00          	cmpl   $0x0,(%edx,%eax,4)
f010247e:	74 24                	je     f01024a4 <i386_vm_init+0x1506>
f0102480:	c7 44 24 0c 56 45 10 	movl   $0xf0104556,0xc(%esp)
f0102487:	f0 
f0102488:	c7 44 24 08 db 43 10 	movl   $0xf01043db,0x8(%esp)
f010248f:	f0 
f0102490:	c7 44 24 04 81 01 00 	movl   $0x181,0x4(%esp)
f0102497:	00 
f0102498:	c7 04 24 8f 43 10 f0 	movl   $0xf010438f,(%esp)
f010249f:	e8 f4 db ff ff       	call   f0100098 <_panic>
	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f01024a4:	83 c0 01             	add    $0x1,%eax
f01024a7:	3d 00 04 00 00       	cmp    $0x400,%eax
f01024ac:	0f 85 62 ff ff ff    	jne    f0102414 <i386_vm_init+0x1476>
			else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_boot_pgdir() succeeded!\n");
f01024b2:	c7 04 24 70 43 10 f0 	movl   $0xf0104370,(%esp)
f01024b9:	e8 db 04 00 00       	call   f0102999 <cprintf>
	// mapping, even though we are turning on paging and reconfiguring
	// segmentation.

	// Map VA 0:4MB same as VA KERNBASE, i.e. to PA 0:4MB.
	// (Limits our kernel to <4MB)
	pgdir[0] = pgdir[PDX(KERNBASE)];
f01024be:	8b 87 00 0f 00 00    	mov    0xf00(%edi),%eax
f01024c4:	89 07                	mov    %eax,(%edi)
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01024c6:	a1 04 5a 11 f0       	mov    0xf0115a04,%eax
f01024cb:	0f 22 d8             	mov    %eax,%cr3

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01024ce:	0f 20 c0             	mov    %cr0,%eax
	lcr3(boot_cr3);

	// Turn on paging.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_EM|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f01024d1:	83 e0 f3             	and    $0xfffffff3,%eax
f01024d4:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01024d9:	0f 22 c0             	mov    %eax,%cr0

	// Current mapping: KERNBASE+x => x => x.
	// (x < 4MB so uses paging pgdir[0])

	// Reload all segment registers.
	asm volatile("lgdt gdt_pd");
f01024dc:	0f 01 15 20 53 11 f0 	lgdtl  0xf0115320
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01024e3:	b8 23 00 00 00       	mov    $0x23,%eax
f01024e8:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01024ea:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01024ec:	b0 10                	mov    $0x10,%al
f01024ee:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01024f0:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01024f2:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));  // reload cs
f01024f4:	ea fb 24 10 f0 08 00 	ljmp   $0x8,$0xf01024fb
	asm volatile("lldt %%ax" :: "a" (0));
f01024fb:	b0 00                	mov    $0x0,%al
f01024fd:	0f 00 d0             	lldt   %ax

	// Final mapping: KERNBASE+x => KERNBASE+x => x.

	// This mapping was only used after paging was turned on but
	// before the segment registers were reloaded.
	pgdir[0] = 0;
f0102500:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102506:	a1 04 5a 11 f0       	mov    0xf0115a04,%eax
f010250b:	0f 22 d8             	mov    %eax,%cr3
f010250e:	eb 45                	jmp    f0102555 <i386_vm_init+0x15b7>
f0102510:	8d 14 33             	lea    (%ebx,%esi,1),%edx
	for (i = 0; i < npage; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102513:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0102516:	e8 b1 e4 ff ff       	call   f01009cc <check_va2pa>
f010251b:	e9 b2 fe ff ff       	jmp    f01023d2 <i386_vm_init+0x1434>
f0102520:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102525:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0102528:	e8 9f e4 ff ff       	call   f01009cc <check_va2pa>
f010252d:	be 00 d0 10 00       	mov    $0x10d000,%esi
f0102532:	ba 00 80 bf df       	mov    $0xdfbf8000,%edx
f0102537:	29 da                	sub    %ebx,%edx
f0102539:	89 d3                	mov    %edx,%ebx
f010253b:	e9 92 fe ff ff       	jmp    f01023d2 <i386_vm_init+0x1434>
f0102540:	81 ea 00 f0 ff 10    	sub    $0x10fff000,%edx
	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102546:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0102549:	e8 7e e4 ff ff       	call   f01009cc <check_va2pa>

	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010254e:	89 f2                	mov    %esi,%edx
f0102550:	e9 eb fd ff ff       	jmp    f0102340 <i386_vm_init+0x13a2>
	// before the segment registers were reloaded.
	pgdir[0] = 0;

	// Flush the TLB for good measure, to kill the pgdir[0] mapping.
	lcr3(boot_cr3);
}
f0102555:	83 c4 4c             	add    $0x4c,%esp
f0102558:	5b                   	pop    %ebx
f0102559:	5e                   	pop    %esi
f010255a:	5f                   	pop    %edi
f010255b:	5d                   	pop    %ebp
f010255c:	c3                   	ret    

f010255d <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010255d:	55                   	push   %ebp
f010255e:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102560:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102563:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102566:	5d                   	pop    %ebp
f0102567:	c3                   	ret    

f0102568 <envid2env>:
//   On success, sets *penv to the environment.
//   On error, sets *penv to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102568:	55                   	push   %ebp
f0102569:	89 e5                	mov    %esp,%ebp
f010256b:	8b 45 08             	mov    0x8(%ebp),%eax
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010256e:	85 c0                	test   %eax,%eax
f0102570:	75 11                	jne    f0102583 <envid2env+0x1b>
		*env_store = curenv;
f0102572:	a1 ec 55 11 f0       	mov    0xf01155ec,%eax
f0102577:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010257a:	89 01                	mov    %eax,(%ecx)
		return 0;
f010257c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102581:	eb 5d                	jmp    f01025e0 <envid2env+0x78>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102583:	89 c2                	mov    %eax,%edx
f0102585:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010258b:	6b d2 64             	imul   $0x64,%edx,%edx
f010258e:	03 15 f0 55 11 f0    	add    0xf01155f0,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102594:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0102598:	74 05                	je     f010259f <envid2env+0x37>
f010259a:	39 42 4c             	cmp    %eax,0x4c(%edx)
f010259d:	74 10                	je     f01025af <envid2env+0x47>
		*env_store = 0;
f010259f:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025a2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01025a8:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01025ad:	eb 31                	jmp    f01025e0 <envid2env+0x78>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01025af:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01025b3:	74 21                	je     f01025d6 <envid2env+0x6e>
f01025b5:	a1 ec 55 11 f0       	mov    0xf01155ec,%eax
f01025ba:	39 c2                	cmp    %eax,%edx
f01025bc:	74 18                	je     f01025d6 <envid2env+0x6e>
f01025be:	8b 40 4c             	mov    0x4c(%eax),%eax
f01025c1:	39 42 50             	cmp    %eax,0x50(%edx)
f01025c4:	74 10                	je     f01025d6 <envid2env+0x6e>
		*env_store = 0;
f01025c6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025c9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01025cf:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01025d4:	eb 0a                	jmp    f01025e0 <envid2env+0x78>
	}

	*env_store = e;
f01025d6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025d9:	89 10                	mov    %edx,(%eax)
	return 0;
f01025db:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01025e0:	5d                   	pop    %ebp
f01025e1:	c3                   	ret    

f01025e2 <env_init>:
// Insert in reverse order, so that the first call to env_alloc()
// returns envs[0].
//
void
env_init(void)
{
f01025e2:	55                   	push   %ebp
f01025e3:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f01025e5:	5d                   	pop    %ebp
f01025e6:	c3                   	ret    

f01025e7 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01025e7:	55                   	push   %ebp
f01025e8:	89 e5                	mov    %esp,%ebp
f01025ea:	53                   	push   %ebx
f01025eb:	83 ec 24             	sub    $0x24,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = LIST_FIRST(&env_free_list)))
f01025ee:	8b 1d f4 55 11 f0    	mov    0xf01155f4,%ebx
f01025f4:	85 db                	test   %ebx,%ebx
f01025f6:	0f 84 f9 00 00 00    	je     f01026f5 <env_alloc+0x10e>
//
static int
env_setup_vm(struct Env *e)
{
	int i, r;
	struct Page *p = NULL;
f01025fc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// Allocate a page for the page directory
	if ((r = page_alloc(&p)) < 0)
f0102603:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102606:	89 04 24             	mov    %eax,(%esp)
f0102609:	e8 08 e6 ff ff       	call   f0100c16 <page_alloc>
f010260e:	85 c0                	test   %eax,%eax
f0102610:	0f 88 e4 00 00 00    	js     f01026fa <env_alloc+0x113>

	// LAB 3: Your code here.

	// VPT and UVPT map the env's own page table, with
	// different permissions.
	e->env_pgdir[PDX(VPT)]  = e->env_cr3 | PTE_P | PTE_W;
f0102616:	8b 43 5c             	mov    0x5c(%ebx),%eax
f0102619:	8b 53 60             	mov    0x60(%ebx),%edx
f010261c:	83 ca 03             	or     $0x3,%edx
f010261f:	89 90 fc 0e 00 00    	mov    %edx,0xefc(%eax)
	e->env_pgdir[PDX(UVPT)] = e->env_cr3 | PTE_P | PTE_U;
f0102625:	8b 43 5c             	mov    0x5c(%ebx),%eax
f0102628:	8b 53 60             	mov    0x60(%ebx),%edx
f010262b:	83 ca 05             	or     $0x5,%edx
f010262e:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102634:	8b 43 4c             	mov    0x4c(%ebx),%eax
f0102637:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f010263c:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102641:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102646:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102649:	89 da                	mov    %ebx,%edx
f010264b:	2b 15 f0 55 11 f0    	sub    0xf01155f0,%edx
f0102651:	c1 fa 02             	sar    $0x2,%edx
f0102654:	69 d2 29 5c 8f c2    	imul   $0xc28f5c29,%edx,%edx
f010265a:	09 d0                	or     %edx,%eax
f010265c:	89 43 4c             	mov    %eax,0x4c(%ebx)
	
	// Set the basic status variables.
	e->env_parent_id = parent_id;
f010265f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102662:	89 43 50             	mov    %eax,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102665:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
	e->env_runs = 0;
f010266c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102673:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f010267a:	00 
f010267b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102682:	00 
f0102683:	89 1c 24             	mov    %ebx,(%esp)
f0102686:	e8 84 0e 00 00       	call   f010350f <memset>
	// Set up appropriate initial values for the segment registers.
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.
	e->env_tf.tf_ds = GD_UD | 3;
f010268b:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102691:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102697:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010269d:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01026a4:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	LIST_REMOVE(e, env_link);
f01026aa:	8b 43 44             	mov    0x44(%ebx),%eax
f01026ad:	85 c0                	test   %eax,%eax
f01026af:	74 06                	je     f01026b7 <env_alloc+0xd0>
f01026b1:	8b 53 48             	mov    0x48(%ebx),%edx
f01026b4:	89 50 48             	mov    %edx,0x48(%eax)
f01026b7:	8b 43 48             	mov    0x48(%ebx),%eax
f01026ba:	8b 53 44             	mov    0x44(%ebx),%edx
f01026bd:	89 10                	mov    %edx,(%eax)
	*newenv_store = e;
f01026bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01026c2:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01026c4:	8b 53 4c             	mov    0x4c(%ebx),%edx
f01026c7:	a1 ec 55 11 f0       	mov    0xf01155ec,%eax
f01026cc:	85 c0                	test   %eax,%eax
f01026ce:	74 05                	je     f01026d5 <env_alloc+0xee>
f01026d0:	8b 40 4c             	mov    0x4c(%eax),%eax
f01026d3:	eb 05                	jmp    f01026da <env_alloc+0xf3>
f01026d5:	b8 00 00 00 00       	mov    $0x0,%eax
f01026da:	89 54 24 08          	mov    %edx,0x8(%esp)
f01026de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01026e2:	c7 04 24 64 45 10 f0 	movl   $0xf0104564,(%esp)
f01026e9:	e8 ab 02 00 00       	call   f0102999 <cprintf>
	return 0;
f01026ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01026f3:	eb 05                	jmp    f01026fa <env_alloc+0x113>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = LIST_FIRST(&env_free_list)))
		return -E_NO_FREE_ENV;
f01026f5:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
	LIST_REMOVE(e, env_link);
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01026fa:	83 c4 24             	add    $0x24,%esp
f01026fd:	5b                   	pop    %ebx
f01026fe:	5d                   	pop    %ebp
f01026ff:	c3                   	ret    

f0102700 <env_create>:
// By convention, envs[0] is the first environment allocated, so
// whoever calls env_create simply looks for the newly created
// environment there. 
void
env_create(uint8_t *binary, size_t size)
{
f0102700:	55                   	push   %ebp
f0102701:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f0102703:	5d                   	pop    %ebp
f0102704:	c3                   	ret    

f0102705 <env_free>:
//
// Frees env e and all memory it uses.
// 
void
env_free(struct Env *e)
{
f0102705:	55                   	push   %ebp
f0102706:	89 e5                	mov    %esp,%ebp
f0102708:	57                   	push   %edi
f0102709:	56                   	push   %esi
f010270a:	53                   	push   %ebx
f010270b:	83 ec 2c             	sub    $0x2c,%esp
f010270e:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;
	
	// If freeing the current environment, switch to boot_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102711:	a1 ec 55 11 f0       	mov    0xf01155ec,%eax
f0102716:	39 c7                	cmp    %eax,%edi
f0102718:	75 09                	jne    f0102723 <env_free+0x1e>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010271a:	8b 15 04 5a 11 f0    	mov    0xf0115a04,%edx
f0102720:	0f 22 da             	mov    %edx,%cr3
		lcr3(boot_cr3);

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102723:	8b 57 4c             	mov    0x4c(%edi),%edx
f0102726:	85 c0                	test   %eax,%eax
f0102728:	74 05                	je     f010272f <env_free+0x2a>
f010272a:	8b 40 4c             	mov    0x4c(%eax),%eax
f010272d:	eb 05                	jmp    f0102734 <env_free+0x2f>
f010272f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102734:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102738:	89 44 24 04          	mov    %eax,0x4(%esp)
f010273c:	c7 04 24 79 45 10 f0 	movl   $0xf0104579,(%esp)
f0102743:	e8 51 02 00 00       	call   f0102999 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102748:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010274f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102752:	89 c8                	mov    %ecx,%eax
f0102754:	c1 e0 02             	shl    $0x2,%eax
f0102757:	89 45 d8             	mov    %eax,-0x28(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010275a:	8b 47 5c             	mov    0x5c(%edi),%eax
f010275d:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f0102760:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102766:	0f 84 ba 00 00 00    	je     f0102826 <env_free+0x121>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010276c:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
		pt = (pte_t*) KADDR(pa);
f0102772:	89 f0                	mov    %esi,%eax
f0102774:	c1 e8 0c             	shr    $0xc,%eax
f0102777:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010277a:	3b 05 00 5a 11 f0    	cmp    0xf0115a00,%eax
f0102780:	72 20                	jb     f01027a2 <env_free+0x9d>
f0102782:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102786:	c7 44 24 08 a4 3e 10 	movl   $0xf0103ea4,0x8(%esp)
f010278d:	f0 
f010278e:	c7 44 24 04 32 01 00 	movl   $0x132,0x4(%esp)
f0102795:	00 
f0102796:	c7 04 24 8f 45 10 f0 	movl   $0xf010458f,(%esp)
f010279d:	e8 f6 d8 ff ff       	call   f0100098 <_panic>

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01027a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027a5:	c1 e0 16             	shl    $0x16,%eax
f01027a8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01027ab:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01027b0:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01027b7:	01 
f01027b8:	74 17                	je     f01027d1 <env_free+0xcc>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01027ba:	89 d8                	mov    %ebx,%eax
f01027bc:	c1 e0 0c             	shl    $0xc,%eax
f01027bf:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01027c2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01027c6:	8b 47 5c             	mov    0x5c(%edi),%eax
f01027c9:	89 04 24             	mov    %eax,(%esp)
f01027cc:	e8 c7 e6 ff ff       	call   f0100e98 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01027d1:	83 c3 01             	add    $0x1,%ebx
f01027d4:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01027da:	75 d4                	jne    f01027b0 <env_free+0xab>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01027dc:	8b 47 5c             	mov    0x5c(%edi),%eax
f01027df:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01027e2:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PPN(pa) >= npage)
f01027e9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01027ec:	3b 05 00 5a 11 f0    	cmp    0xf0115a00,%eax
f01027f2:	72 1c                	jb     f0102810 <env_free+0x10b>
		panic("pa2page called with invalid pa");
f01027f4:	c7 44 24 08 ec 3e 10 	movl   $0xf0103eec,0x8(%esp)
f01027fb:	f0 
f01027fc:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0102803:	00 
f0102804:	c7 04 24 b7 43 10 f0 	movl   $0xf01043b7,(%esp)
f010280b:	e8 88 d8 ff ff       	call   f0100098 <_panic>
	return &pages[PPN(pa)];
f0102810:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102813:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102816:	a1 0c 5a 11 f0       	mov    0xf0115a0c,%eax
f010281b:	8d 04 90             	lea    (%eax,%edx,4),%eax
		page_decref(pa2page(pa));
f010281e:	89 04 24             	mov    %eax,(%esp)
f0102821:	e8 73 e4 ff ff       	call   f0100c99 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102826:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f010282a:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0102831:	0f 85 18 ff ff ff    	jne    f010274f <env_free+0x4a>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = e->env_cr3;
f0102837:	8b 47 60             	mov    0x60(%edi),%eax
	e->env_pgdir = 0;
f010283a:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	e->env_cr3 = 0;
f0102841:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PPN(pa) >= npage)
f0102848:	c1 e8 0c             	shr    $0xc,%eax
f010284b:	3b 05 00 5a 11 f0    	cmp    0xf0115a00,%eax
f0102851:	72 1c                	jb     f010286f <env_free+0x16a>
		panic("pa2page called with invalid pa");
f0102853:	c7 44 24 08 ec 3e 10 	movl   $0xf0103eec,0x8(%esp)
f010285a:	f0 
f010285b:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0102862:	00 
f0102863:	c7 04 24 b7 43 10 f0 	movl   $0xf01043b7,(%esp)
f010286a:	e8 29 d8 ff ff       	call   f0100098 <_panic>
	return &pages[PPN(pa)];
f010286f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102872:	a1 0c 5a 11 f0       	mov    0xf0115a0c,%eax
f0102877:	8d 04 90             	lea    (%eax,%edx,4),%eax
	page_decref(pa2page(pa));
f010287a:	89 04 24             	mov    %eax,(%esp)
f010287d:	e8 17 e4 ff ff       	call   f0100c99 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102882:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	LIST_INSERT_HEAD(&env_free_list, e, env_link);
f0102889:	a1 f4 55 11 f0       	mov    0xf01155f4,%eax
f010288e:	89 47 44             	mov    %eax,0x44(%edi)
f0102891:	85 c0                	test   %eax,%eax
f0102893:	74 06                	je     f010289b <env_free+0x196>
f0102895:	8d 57 44             	lea    0x44(%edi),%edx
f0102898:	89 50 48             	mov    %edx,0x48(%eax)
f010289b:	89 3d f4 55 11 f0    	mov    %edi,0xf01155f4
f01028a1:	c7 47 48 f4 55 11 f0 	movl   $0xf01155f4,0x48(%edi)
}
f01028a8:	83 c4 2c             	add    $0x2c,%esp
f01028ab:	5b                   	pop    %ebx
f01028ac:	5e                   	pop    %esi
f01028ad:	5f                   	pop    %edi
f01028ae:	5d                   	pop    %ebp
f01028af:	c3                   	ret    

f01028b0 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e) 
{
f01028b0:	55                   	push   %ebp
f01028b1:	89 e5                	mov    %esp,%ebp
f01028b3:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f01028b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01028b9:	89 04 24             	mov    %eax,(%esp)
f01028bc:	e8 44 fe ff ff       	call   f0102705 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01028c1:	c7 04 24 c4 45 10 f0 	movl   $0xf01045c4,(%esp)
f01028c8:	e8 cc 00 00 00       	call   f0102999 <cprintf>
	while (1)
		monitor(NULL);
f01028cd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028d4:	e8 89 de ff ff       	call   f0100762 <monitor>
f01028d9:	eb f2                	jmp    f01028cd <env_destroy+0x1d>

f01028db <env_pop_tf>:
// This exits the kernel and starts executing some environment's code.
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01028db:	55                   	push   %ebp
f01028dc:	89 e5                	mov    %esp,%ebp
f01028de:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f01028e1:	8b 65 08             	mov    0x8(%ebp),%esp
f01028e4:	61                   	popa   
f01028e5:	07                   	pop    %es
f01028e6:	1f                   	pop    %ds
f01028e7:	83 c4 08             	add    $0x8,%esp
f01028ea:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01028eb:	c7 44 24 08 9a 45 10 	movl   $0xf010459a,0x8(%esp)
f01028f2:	f0 
f01028f3:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f01028fa:	00 
f01028fb:	c7 04 24 8f 45 10 f0 	movl   $0xf010458f,(%esp)
f0102902:	e8 91 d7 ff ff       	call   f0100098 <_panic>

f0102907 <env_run>:
// Note: if this is the first call to env_run, curenv is NULL.
//  (This function does not return.)
//
void
env_run(struct Env *e)
{
f0102907:	55                   	push   %ebp
f0102908:	89 e5                	mov    %esp,%ebp
f010290a:	83 ec 18             	sub    $0x18,%esp
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.
	
	// LAB 3: Your code here.

        panic("env_run not yet implemented");
f010290d:	c7 44 24 08 a6 45 10 	movl   $0xf01045a6,0x8(%esp)
f0102914:	f0 
f0102915:	c7 44 24 04 83 01 00 	movl   $0x183,0x4(%esp)
f010291c:	00 
f010291d:	c7 04 24 8f 45 10 f0 	movl   $0xf010458f,(%esp)
f0102924:	e8 6f d7 ff ff       	call   f0100098 <_panic>

f0102929 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102929:	55                   	push   %ebp
f010292a:	89 e5                	mov    %esp,%ebp
f010292c:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102930:	ba 70 00 00 00       	mov    $0x70,%edx
f0102935:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102936:	b2 71                	mov    $0x71,%dl
f0102938:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102939:	0f b6 c0             	movzbl %al,%eax
}
f010293c:	5d                   	pop    %ebp
f010293d:	c3                   	ret    

f010293e <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010293e:	55                   	push   %ebp
f010293f:	89 e5                	mov    %esp,%ebp
f0102941:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102945:	ba 70 00 00 00       	mov    $0x70,%edx
f010294a:	ee                   	out    %al,(%dx)
f010294b:	b2 71                	mov    $0x71,%dl
f010294d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102950:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102951:	5d                   	pop    %ebp
f0102952:	c3                   	ret    

f0102953 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102953:	55                   	push   %ebp
f0102954:	89 e5                	mov    %esp,%ebp
f0102956:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102959:	8b 45 08             	mov    0x8(%ebp),%eax
f010295c:	89 04 24             	mov    %eax,(%esp)
f010295f:	e8 af dc ff ff       	call   f0100613 <cputchar>
	*cnt++;
}
f0102964:	c9                   	leave  
f0102965:	c3                   	ret    

f0102966 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102966:	55                   	push   %ebp
f0102967:	89 e5                	mov    %esp,%ebp
f0102969:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010296c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102973:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102976:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010297a:	8b 45 08             	mov    0x8(%ebp),%eax
f010297d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102981:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102984:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102988:	c7 04 24 53 29 10 f0 	movl   $0xf0102953,(%esp)
f010298f:	e8 38 04 00 00       	call   f0102dcc <vprintfmt>
	return cnt;
}
f0102994:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102997:	c9                   	leave  
f0102998:	c3                   	ret    

f0102999 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102999:	55                   	push   %ebp
f010299a:	89 e5                	mov    %esp,%ebp
f010299c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
	cnt = vcprintf(fmt, ap);
f010299f:	8d 45 0c             	lea    0xc(%ebp),%eax
f01029a2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01029a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01029a9:	89 04 24             	mov    %eax,(%esp)
f01029ac:	e8 b5 ff ff ff       	call   f0102966 <vcprintf>
	va_end(ap);

	return cnt;
}
f01029b1:	c9                   	leave  
f01029b2:	c3                   	ret    

f01029b3 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01029b3:	55                   	push   %ebp
f01029b4:	89 e5                	mov    %esp,%ebp
f01029b6:	57                   	push   %edi
f01029b7:	56                   	push   %esi
f01029b8:	53                   	push   %ebx
f01029b9:	83 ec 10             	sub    $0x10,%esp
f01029bc:	89 c6                	mov    %eax,%esi
f01029be:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01029c1:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01029c4:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01029c7:	8b 1a                	mov    (%edx),%ebx
f01029c9:	8b 01                	mov    (%ecx),%eax
f01029cb:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01029ce:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f01029d5:	eb 77                	jmp    f0102a4e <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f01029d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01029da:	01 d8                	add    %ebx,%eax
f01029dc:	b9 02 00 00 00       	mov    $0x2,%ecx
f01029e1:	99                   	cltd   
f01029e2:	f7 f9                	idiv   %ecx
f01029e4:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01029e6:	eb 01                	jmp    f01029e9 <stab_binsearch+0x36>
			m--;
f01029e8:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01029e9:	39 d9                	cmp    %ebx,%ecx
f01029eb:	7c 1d                	jl     f0102a0a <stab_binsearch+0x57>
f01029ed:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01029f0:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f01029f5:	39 fa                	cmp    %edi,%edx
f01029f7:	75 ef                	jne    f01029e8 <stab_binsearch+0x35>
f01029f9:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01029fc:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01029ff:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102a03:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102a06:	73 18                	jae    f0102a20 <stab_binsearch+0x6d>
f0102a08:	eb 05                	jmp    f0102a0f <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102a0a:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102a0d:	eb 3f                	jmp    f0102a4e <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102a0f:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102a12:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0102a14:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102a17:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102a1e:	eb 2e                	jmp    f0102a4e <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102a20:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102a23:	73 15                	jae    f0102a3a <stab_binsearch+0x87>
			*region_right = m - 1;
f0102a25:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102a28:	48                   	dec    %eax
f0102a29:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102a2c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102a2f:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102a31:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102a38:	eb 14                	jmp    f0102a4e <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102a3a:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102a3d:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0102a40:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0102a42:	ff 45 0c             	incl   0xc(%ebp)
f0102a45:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102a47:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0102a4e:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102a51:	7e 84                	jle    f01029d7 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102a53:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102a57:	75 0d                	jne    f0102a66 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102a59:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102a5c:	8b 00                	mov    (%eax),%eax
f0102a5e:	48                   	dec    %eax
f0102a5f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102a62:	89 07                	mov    %eax,(%edi)
f0102a64:	eb 22                	jmp    f0102a88 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102a66:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a69:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102a6b:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102a6e:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102a70:	eb 01                	jmp    f0102a73 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102a72:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102a73:	39 c1                	cmp    %eax,%ecx
f0102a75:	7d 0c                	jge    f0102a83 <stab_binsearch+0xd0>
f0102a77:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0102a7a:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102a7f:	39 fa                	cmp    %edi,%edx
f0102a81:	75 ef                	jne    f0102a72 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102a83:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0102a86:	89 07                	mov    %eax,(%edi)
	}
}
f0102a88:	83 c4 10             	add    $0x10,%esp
f0102a8b:	5b                   	pop    %ebx
f0102a8c:	5e                   	pop    %esi
f0102a8d:	5f                   	pop    %edi
f0102a8e:	5d                   	pop    %ebp
f0102a8f:	c3                   	ret    

f0102a90 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102a90:	55                   	push   %ebp
f0102a91:	89 e5                	mov    %esp,%ebp
f0102a93:	57                   	push   %edi
f0102a94:	56                   	push   %esi
f0102a95:	53                   	push   %ebx
f0102a96:	83 ec 3c             	sub    $0x3c,%esp
f0102a99:	8b 75 08             	mov    0x8(%ebp),%esi
f0102a9c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline, largs;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102a9f:	c7 03 fc 45 10 f0    	movl   $0xf01045fc,(%ebx)
	info->eip_line = 0;
f0102aa5:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102aac:	c7 43 08 fc 45 10 f0 	movl   $0xf01045fc,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102ab3:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102aba:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102abd:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102ac4:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102aca:	76 12                	jbe    f0102ade <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102acc:	b8 58 ca 10 f0       	mov    $0xf010ca58,%eax
f0102ad1:	3d d1 a4 10 f0       	cmp    $0xf010a4d1,%eax
f0102ad6:	0f 86 6f 01 00 00    	jbe    f0102c4b <debuginfo_eip+0x1bb>
f0102adc:	eb 1c                	jmp    f0102afa <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102ade:	c7 44 24 08 06 46 10 	movl   $0xf0104606,0x8(%esp)
f0102ae5:	f0 
f0102ae6:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
f0102aed:	00 
f0102aee:	c7 04 24 13 46 10 f0 	movl   $0xf0104613,(%esp)
f0102af5:	e8 9e d5 ff ff       	call   f0100098 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102afa:	80 3d 57 ca 10 f0 00 	cmpb   $0x0,0xf010ca57
f0102b01:	0f 85 4b 01 00 00    	jne    f0102c52 <debuginfo_eip+0x1c2>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102b07:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102b0e:	b8 d0 a4 10 f0       	mov    $0xf010a4d0,%eax
f0102b13:	2d 30 48 10 f0       	sub    $0xf0104830,%eax
f0102b18:	c1 f8 02             	sar    $0x2,%eax
f0102b1b:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102b21:	83 e8 01             	sub    $0x1,%eax
f0102b24:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102b27:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102b2b:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102b32:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102b35:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102b38:	b8 30 48 10 f0       	mov    $0xf0104830,%eax
f0102b3d:	e8 71 fe ff ff       	call   f01029b3 <stab_binsearch>
	if (lfile == 0)
f0102b42:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102b45:	85 c0                	test   %eax,%eax
f0102b47:	0f 84 0c 01 00 00    	je     f0102c59 <debuginfo_eip+0x1c9>
		return -1;

	if (lfile <= rfile) {
f0102b4d:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102b50:	39 d0                	cmp    %edx,%eax
f0102b52:	7f 20                	jg     f0102b74 <debuginfo_eip+0xe4>
		if (stabs[lfile].n_strx < stabstr_end - stabstr)
f0102b54:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0102b57:	8b 89 30 48 10 f0    	mov    -0xfefb7d0(%ecx),%ecx
f0102b5d:	bf 58 ca 10 f0       	mov    $0xf010ca58,%edi
f0102b62:	81 ef d1 a4 10 f0    	sub    $0xf010a4d1,%edi
f0102b68:	39 f9                	cmp    %edi,%ecx
f0102b6a:	73 08                	jae    f0102b74 <debuginfo_eip+0xe4>
			info->eip_file = stabstr + stabs[lfile].n_strx;
f0102b6c:	81 c1 d1 a4 10 f0    	add    $0xf010a4d1,%ecx
f0102b72:	89 0b                	mov    %ecx,(%ebx)
	} 

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102b74:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102b77:	89 55 d8             	mov    %edx,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102b7a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102b7e:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102b85:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102b88:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102b8b:	b8 30 48 10 f0       	mov    $0xf0104830,%eax
f0102b90:	e8 1e fe ff ff       	call   f01029b3 <stab_binsearch>

	if (lfun <= rfun) {
f0102b95:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102b98:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0102b9b:	7f 30                	jg     f0102bcd <debuginfo_eip+0x13d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102b9d:	6b c0 0c             	imul   $0xc,%eax,%eax
f0102ba0:	8d 90 30 48 10 f0    	lea    -0xfefb7d0(%eax),%edx
f0102ba6:	8b 80 30 48 10 f0    	mov    -0xfefb7d0(%eax),%eax
f0102bac:	b9 58 ca 10 f0       	mov    $0xf010ca58,%ecx
f0102bb1:	81 e9 d1 a4 10 f0    	sub    $0xf010a4d1,%ecx
f0102bb7:	39 c8                	cmp    %ecx,%eax
f0102bb9:	73 08                	jae    f0102bc3 <debuginfo_eip+0x133>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102bbb:	05 d1 a4 10 f0       	add    $0xf010a4d1,%eax
f0102bc0:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102bc3:	8b 42 08             	mov    0x8(%edx),%eax
f0102bc6:	89 43 10             	mov    %eax,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102bc9:	29 c6                	sub    %eax,%esi
f0102bcb:	eb 03                	jmp    f0102bd0 <debuginfo_eip+0x140>
		// Search within the function definition for the line number.
		
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102bcd:	89 73 10             	mov    %esi,0x10(%ebx)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102bd0:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102bd7:	00 
f0102bd8:	8b 43 08             	mov    0x8(%ebx),%eax
f0102bdb:	89 04 24             	mov    %eax,(%esp)
f0102bde:	e8 01 09 00 00       	call   f01034e4 <strfind>
f0102be3:	2b 43 08             	sub    0x8(%ebx),%eax
f0102be6:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	lline = lfun;
f0102be9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102bec:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	rline = rfun;
f0102bef:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102bf2:	89 45 d0             	mov    %eax,-0x30(%ebp)
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102bf5:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102bf9:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0102c00:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102c03:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102c06:	b8 30 48 10 f0       	mov    $0xf0104830,%eax
f0102c0b:	e8 a3 fd ff ff       	call   f01029b3 <stab_binsearch>
	if (lline <= rline) {
f0102c10:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c13:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0102c16:	7f 48                	jg     f0102c60 <debuginfo_eip+0x1d0>
		info->eip_line = stabs[rline].n_desc;
f0102c18:	6b c0 0c             	imul   $0xc,%eax,%eax
f0102c1b:	0f b7 80 36 48 10 f0 	movzwl -0xfefb7ca(%eax),%eax
f0102c22:	89 43 04             	mov    %eax,0x4(%ebx)
	// 	info->eip_file = stabstr + stabs[lline].n_strx;

	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.
	largs = lfun+1;
f0102c25:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102c28:	83 c0 01             	add    $0x1,%eax
	while (stabs[largs++].n_type == N_PSYM) {
f0102c2b:	6b c0 0c             	imul   $0xc,%eax,%eax
f0102c2e:	80 b8 34 48 10 f0 a0 	cmpb   $0xa0,-0xfefb7cc(%eax)
f0102c35:	75 30                	jne    f0102c67 <debuginfo_eip+0x1d7>
f0102c37:	05 24 48 10 f0       	add    $0xf0104824,%eax
		info->eip_fn_narg++;
f0102c3c:	83 43 14 01          	addl   $0x1,0x14(%ebx)
f0102c40:	83 c0 0c             	add    $0xc,%eax

	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.
	largs = lfun+1;
	while (stabs[largs++].n_type == N_PSYM) {
f0102c43:	80 78 10 a0          	cmpb   $0xa0,0x10(%eax)
f0102c47:	74 f3                	je     f0102c3c <debuginfo_eip+0x1ac>
f0102c49:	eb 23                	jmp    f0102c6e <debuginfo_eip+0x1de>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102c4b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102c50:	eb 21                	jmp    f0102c73 <debuginfo_eip+0x1e3>
f0102c52:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102c57:	eb 1a                	jmp    f0102c73 <debuginfo_eip+0x1e3>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102c59:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102c5e:	eb 13                	jmp    f0102c73 <debuginfo_eip+0x1e3>
	lline = lfun;
	rline = rfun;
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline <= rline) {
		info->eip_line = stabs[rline].n_desc;
	}else return -1;
f0102c60:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102c65:	eb 0c                	jmp    f0102c73 <debuginfo_eip+0x1e3>
	largs = lfun+1;
	while (stabs[largs++].n_type == N_PSYM) {
		info->eip_fn_narg++;
	}

	return 0;
f0102c67:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c6c:	eb 05                	jmp    f0102c73 <debuginfo_eip+0x1e3>
f0102c6e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102c73:	83 c4 3c             	add    $0x3c,%esp
f0102c76:	5b                   	pop    %ebx
f0102c77:	5e                   	pop    %esi
f0102c78:	5f                   	pop    %edi
f0102c79:	5d                   	pop    %ebp
f0102c7a:	c3                   	ret    
f0102c7b:	66 90                	xchg   %ax,%ax
f0102c7d:	66 90                	xchg   %ax,%ax
f0102c7f:	90                   	nop

f0102c80 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102c80:	55                   	push   %ebp
f0102c81:	89 e5                	mov    %esp,%ebp
f0102c83:	57                   	push   %edi
f0102c84:	56                   	push   %esi
f0102c85:	53                   	push   %ebx
f0102c86:	83 ec 3c             	sub    $0x3c,%esp
f0102c89:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102c8c:	89 d7                	mov    %edx,%edi
f0102c8e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c91:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c94:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102c97:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102c9a:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102c9d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102ca2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ca5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102ca8:	39 f1                	cmp    %esi,%ecx
f0102caa:	72 14                	jb     f0102cc0 <printnum+0x40>
f0102cac:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0102caf:	76 0f                	jbe    f0102cc0 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102cb1:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cb4:	8d 70 ff             	lea    -0x1(%eax),%esi
f0102cb7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102cba:	85 f6                	test   %esi,%esi
f0102cbc:	7f 60                	jg     f0102d1e <printnum+0x9e>
f0102cbe:	eb 72                	jmp    f0102d32 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102cc0:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0102cc3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0102cc7:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0102cca:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0102ccd:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102cd1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102cd5:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102cd9:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0102cdd:	89 c3                	mov    %eax,%ebx
f0102cdf:	89 d6                	mov    %edx,%esi
f0102ce1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102ce4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102ce7:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102ceb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102cef:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102cf2:	89 04 24             	mov    %eax,(%esp)
f0102cf5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102cf8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102cfc:	e8 0f 0a 00 00       	call   f0103710 <__udivdi3>
f0102d01:	89 d9                	mov    %ebx,%ecx
f0102d03:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102d07:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102d0b:	89 04 24             	mov    %eax,(%esp)
f0102d0e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102d12:	89 fa                	mov    %edi,%edx
f0102d14:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d17:	e8 64 ff ff ff       	call   f0102c80 <printnum>
f0102d1c:	eb 14                	jmp    f0102d32 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102d1e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102d22:	8b 45 18             	mov    0x18(%ebp),%eax
f0102d25:	89 04 24             	mov    %eax,(%esp)
f0102d28:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102d2a:	83 ee 01             	sub    $0x1,%esi
f0102d2d:	75 ef                	jne    f0102d1e <printnum+0x9e>
f0102d2f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102d32:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102d36:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0102d3a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102d3d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102d40:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102d44:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102d48:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d4b:	89 04 24             	mov    %eax,(%esp)
f0102d4e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d51:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d55:	e8 e6 0a 00 00       	call   f0103840 <__umoddi3>
f0102d5a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102d5e:	0f be 80 21 46 10 f0 	movsbl -0xfefb9df(%eax),%eax
f0102d65:	89 04 24             	mov    %eax,(%esp)
f0102d68:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d6b:	ff d0                	call   *%eax
}
f0102d6d:	83 c4 3c             	add    $0x3c,%esp
f0102d70:	5b                   	pop    %ebx
f0102d71:	5e                   	pop    %esi
f0102d72:	5f                   	pop    %edi
f0102d73:	5d                   	pop    %ebp
f0102d74:	c3                   	ret    

f0102d75 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102d75:	55                   	push   %ebp
f0102d76:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102d78:	83 fa 01             	cmp    $0x1,%edx
f0102d7b:	7e 0e                	jle    f0102d8b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102d7d:	8b 10                	mov    (%eax),%edx
f0102d7f:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102d82:	89 08                	mov    %ecx,(%eax)
f0102d84:	8b 02                	mov    (%edx),%eax
f0102d86:	8b 52 04             	mov    0x4(%edx),%edx
f0102d89:	eb 22                	jmp    f0102dad <getuint+0x38>
	else if (lflag)
f0102d8b:	85 d2                	test   %edx,%edx
f0102d8d:	74 10                	je     f0102d9f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102d8f:	8b 10                	mov    (%eax),%edx
f0102d91:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102d94:	89 08                	mov    %ecx,(%eax)
f0102d96:	8b 02                	mov    (%edx),%eax
f0102d98:	ba 00 00 00 00       	mov    $0x0,%edx
f0102d9d:	eb 0e                	jmp    f0102dad <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102d9f:	8b 10                	mov    (%eax),%edx
f0102da1:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102da4:	89 08                	mov    %ecx,(%eax)
f0102da6:	8b 02                	mov    (%edx),%eax
f0102da8:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102dad:	5d                   	pop    %ebp
f0102dae:	c3                   	ret    

f0102daf <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102daf:	55                   	push   %ebp
f0102db0:	89 e5                	mov    %esp,%ebp
f0102db2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102db5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102db9:	8b 10                	mov    (%eax),%edx
f0102dbb:	3b 50 04             	cmp    0x4(%eax),%edx
f0102dbe:	73 0a                	jae    f0102dca <sprintputch+0x1b>
		*b->buf++ = ch;
f0102dc0:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102dc3:	89 08                	mov    %ecx,(%eax)
f0102dc5:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dc8:	88 02                	mov    %al,(%edx)
}
f0102dca:	5d                   	pop    %ebp
f0102dcb:	c3                   	ret    

f0102dcc <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102dcc:	55                   	push   %ebp
f0102dcd:	89 e5                	mov    %esp,%ebp
f0102dcf:	57                   	push   %edi
f0102dd0:	56                   	push   %esi
f0102dd1:	53                   	push   %ebx
f0102dd2:	83 ec 4c             	sub    $0x4c,%esp
f0102dd5:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0102dd8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0102ddb:	eb 18                	jmp    f0102df5 <vprintfmt+0x29>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102ddd:	85 c0                	test   %eax,%eax
f0102ddf:	0f 84 da 03 00 00    	je     f01031bf <vprintfmt+0x3f3>
				return;
			putch(ch, putdat);
f0102de5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102de9:	89 04 24             	mov    %eax,(%esp)
f0102dec:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102def:	89 f3                	mov    %esi,%ebx
f0102df1:	eb 02                	jmp    f0102df5 <vprintfmt+0x29>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102df3:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102df5:	8d 73 01             	lea    0x1(%ebx),%esi
f0102df8:	0f b6 03             	movzbl (%ebx),%eax
f0102dfb:	83 f8 25             	cmp    $0x25,%eax
f0102dfe:	75 dd                	jne    f0102ddd <vprintfmt+0x11>
f0102e00:	c6 45 d3 20          	movb   $0x20,-0x2d(%ebp)
f0102e04:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f0102e0b:	c7 45 c4 ff ff ff ff 	movl   $0xffffffff,-0x3c(%ebp)
f0102e12:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0102e19:	ba 00 00 00 00       	mov    $0x0,%edx
f0102e1e:	eb 1d                	jmp    f0102e3d <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e20:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102e22:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%ebp)
f0102e26:	eb 15                	jmp    f0102e3d <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e28:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102e2a:	c6 45 d3 30          	movb   $0x30,-0x2d(%ebp)
f0102e2e:	eb 0d                	jmp    f0102e3d <vprintfmt+0x71>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0102e30:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0102e33:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102e36:	c7 45 c4 ff ff ff ff 	movl   $0xffffffff,-0x3c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e3d:	8d 5e 01             	lea    0x1(%esi),%ebx
f0102e40:	0f b6 06             	movzbl (%esi),%eax
f0102e43:	0f b6 c8             	movzbl %al,%ecx
f0102e46:	83 e8 23             	sub    $0x23,%eax
f0102e49:	3c 55                	cmp    $0x55,%al
f0102e4b:	0f 87 46 03 00 00    	ja     f0103197 <vprintfmt+0x3cb>
f0102e51:	0f b6 c0             	movzbl %al,%eax
f0102e54:	ff 24 85 ac 46 10 f0 	jmp    *-0xfefb954(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102e5b:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0102e5e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
				ch = *fmt;
f0102e61:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0102e65:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0102e68:	83 f9 09             	cmp    $0x9,%ecx
f0102e6b:	77 50                	ja     f0102ebd <vprintfmt+0xf1>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e6d:	89 de                	mov    %ebx,%esi
f0102e6f:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102e72:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0102e75:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0102e78:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0102e7c:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0102e7f:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0102e82:	83 fb 09             	cmp    $0x9,%ebx
f0102e85:	76 eb                	jbe    f0102e72 <vprintfmt+0xa6>
f0102e87:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0102e8a:	eb 33                	jmp    f0102ebf <vprintfmt+0xf3>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102e8c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e8f:	8d 48 04             	lea    0x4(%eax),%ecx
f0102e92:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102e95:	8b 00                	mov    (%eax),%eax
f0102e97:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e9a:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102e9c:	eb 21                	jmp    f0102ebf <vprintfmt+0xf3>
f0102e9e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102ea1:	85 c9                	test   %ecx,%ecx
f0102ea3:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ea8:	0f 49 c1             	cmovns %ecx,%eax
f0102eab:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102eae:	89 de                	mov    %ebx,%esi
f0102eb0:	eb 8b                	jmp    f0102e3d <vprintfmt+0x71>
f0102eb2:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102eb4:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
			goto reswitch;
f0102ebb:	eb 80                	jmp    f0102e3d <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ebd:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0102ebf:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0102ec3:	0f 89 74 ff ff ff    	jns    f0102e3d <vprintfmt+0x71>
f0102ec9:	e9 62 ff ff ff       	jmp    f0102e30 <vprintfmt+0x64>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102ece:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ed1:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102ed3:	e9 65 ff ff ff       	jmp    f0102e3d <vprintfmt+0x71>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102ed8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102edb:	8d 50 04             	lea    0x4(%eax),%edx
f0102ede:	89 55 14             	mov    %edx,0x14(%ebp)
f0102ee1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102ee5:	8b 00                	mov    (%eax),%eax
f0102ee7:	89 04 24             	mov    %eax,(%esp)
f0102eea:	ff 55 08             	call   *0x8(%ebp)
			break;
f0102eed:	e9 03 ff ff ff       	jmp    f0102df5 <vprintfmt+0x29>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102ef2:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ef5:	8d 50 04             	lea    0x4(%eax),%edx
f0102ef8:	89 55 14             	mov    %edx,0x14(%ebp)
f0102efb:	8b 00                	mov    (%eax),%eax
f0102efd:	99                   	cltd   
f0102efe:	31 d0                	xor    %edx,%eax
f0102f00:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f0102f02:	83 f8 06             	cmp    $0x6,%eax
f0102f05:	7f 0a                	jg     f0102f11 <vprintfmt+0x145>
f0102f07:	83 3c 85 04 48 10 f0 	cmpl   $0x0,-0xfefb7fc(,%eax,4)
f0102f0e:	00 
f0102f0f:	75 2a                	jne    f0102f3b <vprintfmt+0x16f>
f0102f11:	c7 45 e0 39 46 10 f0 	movl   $0xf0104639,-0x20(%ebp)
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
	va_list ap;

	va_start(ap, fmt);
	vprintfmt(putch, putdat, fmt, ap);
f0102f18:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102f1b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102f1f:	c7 44 24 08 39 46 10 	movl   $0xf0104639,0x8(%esp)
f0102f26:	f0 
f0102f27:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102f2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f2e:	89 04 24             	mov    %eax,(%esp)
f0102f31:	e8 96 fe ff ff       	call   f0102dcc <vprintfmt>
f0102f36:	e9 ba fe ff ff       	jmp    f0102df5 <vprintfmt+0x29>
f0102f3b:	c7 45 e4 ed 43 10 f0 	movl   $0xf01043ed,-0x1c(%ebp)
f0102f42:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0102f45:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102f49:	c7 44 24 08 ed 43 10 	movl   $0xf01043ed,0x8(%esp)
f0102f50:	f0 
f0102f51:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102f55:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f58:	89 04 24             	mov    %eax,(%esp)
f0102f5b:	e8 6c fe ff ff       	call   f0102dcc <vprintfmt>
f0102f60:	e9 90 fe ff ff       	jmp    f0102df5 <vprintfmt+0x29>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102f65:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0102f68:	8b 75 d4             	mov    -0x2c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102f6b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f6e:	8d 48 04             	lea    0x4(%eax),%ecx
f0102f71:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102f74:	8b 00                	mov    (%eax),%eax
f0102f76:	89 c1                	mov    %eax,%ecx
				p = "(null)";
f0102f78:	85 c0                	test   %eax,%eax
f0102f7a:	b8 32 46 10 f0       	mov    $0xf0104632,%eax
f0102f7f:	0f 45 c1             	cmovne %ecx,%eax
f0102f82:	89 45 c0             	mov    %eax,-0x40(%ebp)
			if (width > 0 && padc != '-')
f0102f85:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%ebp)
f0102f89:	74 04                	je     f0102f8f <vprintfmt+0x1c3>
f0102f8b:	85 f6                	test   %esi,%esi
f0102f8d:	7f 19                	jg     f0102fa8 <vprintfmt+0x1dc>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102f8f:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0102f92:	8d 70 01             	lea    0x1(%eax),%esi
f0102f95:	0f b6 10             	movzbl (%eax),%edx
f0102f98:	0f be c2             	movsbl %dl,%eax
f0102f9b:	85 c0                	test   %eax,%eax
f0102f9d:	0f 85 95 00 00 00    	jne    f0103038 <vprintfmt+0x26c>
f0102fa3:	e9 85 00 00 00       	jmp    f010302d <vprintfmt+0x261>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102fa8:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102fac:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0102faf:	89 04 24             	mov    %eax,(%esp)
f0102fb2:	e8 9b 03 00 00       	call   f0103352 <strnlen>
f0102fb7:	29 c6                	sub    %eax,%esi
f0102fb9:	89 f0                	mov    %esi,%eax
f0102fbb:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102fbe:	85 f6                	test   %esi,%esi
f0102fc0:	7e cd                	jle    f0102f8f <vprintfmt+0x1c3>
					putch(padc, putdat);
f0102fc2:	0f be 75 d3          	movsbl -0x2d(%ebp),%esi
f0102fc6:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0102fc9:	89 c3                	mov    %eax,%ebx
f0102fcb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102fcf:	89 34 24             	mov    %esi,(%esp)
f0102fd2:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102fd5:	83 eb 01             	sub    $0x1,%ebx
f0102fd8:	75 f1                	jne    f0102fcb <vprintfmt+0x1ff>
f0102fda:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0102fdd:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0102fe0:	eb ad                	jmp    f0102f8f <vprintfmt+0x1c3>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102fe2:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
f0102fe6:	74 1e                	je     f0103006 <vprintfmt+0x23a>
f0102fe8:	0f be d2             	movsbl %dl,%edx
f0102feb:	83 ea 20             	sub    $0x20,%edx
f0102fee:	83 fa 5e             	cmp    $0x5e,%edx
f0102ff1:	76 13                	jbe    f0103006 <vprintfmt+0x23a>
					putch('?', putdat);
f0102ff3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ff6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102ffa:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103001:	ff 55 08             	call   *0x8(%ebp)
f0103004:	eb 0d                	jmp    f0103013 <vprintfmt+0x247>
				else
					putch(ch, putdat);
f0103006:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103009:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010300d:	89 04 24             	mov    %eax,(%esp)
f0103010:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103013:	83 ef 01             	sub    $0x1,%edi
f0103016:	83 c6 01             	add    $0x1,%esi
f0103019:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010301d:	0f be c2             	movsbl %dl,%eax
f0103020:	85 c0                	test   %eax,%eax
f0103022:	75 20                	jne    f0103044 <vprintfmt+0x278>
f0103024:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103027:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010302a:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010302d:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0103031:	7f 25                	jg     f0103058 <vprintfmt+0x28c>
f0103033:	e9 bd fd ff ff       	jmp    f0102df5 <vprintfmt+0x29>
f0103038:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010303b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010303e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103041:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103044:	85 db                	test   %ebx,%ebx
f0103046:	78 9a                	js     f0102fe2 <vprintfmt+0x216>
f0103048:	83 eb 01             	sub    $0x1,%ebx
f010304b:	79 95                	jns    f0102fe2 <vprintfmt+0x216>
f010304d:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103050:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103053:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0103056:	eb d5                	jmp    f010302d <vprintfmt+0x261>
f0103058:	8b 75 08             	mov    0x8(%ebp),%esi
f010305b:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010305e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103061:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103065:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010306c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010306e:	83 eb 01             	sub    $0x1,%ebx
f0103071:	75 ee                	jne    f0103061 <vprintfmt+0x295>
f0103073:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0103076:	e9 7a fd ff ff       	jmp    f0102df5 <vprintfmt+0x29>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010307b:	83 fa 01             	cmp    $0x1,%edx
f010307e:	66 90                	xchg   %ax,%ax
f0103080:	7e 16                	jle    f0103098 <vprintfmt+0x2cc>
		return va_arg(*ap, long long);
f0103082:	8b 45 14             	mov    0x14(%ebp),%eax
f0103085:	8d 50 08             	lea    0x8(%eax),%edx
f0103088:	89 55 14             	mov    %edx,0x14(%ebp)
f010308b:	8b 50 04             	mov    0x4(%eax),%edx
f010308e:	8b 00                	mov    (%eax),%eax
f0103090:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0103093:	89 55 cc             	mov    %edx,-0x34(%ebp)
f0103096:	eb 32                	jmp    f01030ca <vprintfmt+0x2fe>
	else if (lflag)
f0103098:	85 d2                	test   %edx,%edx
f010309a:	74 18                	je     f01030b4 <vprintfmt+0x2e8>
		return va_arg(*ap, long);
f010309c:	8b 45 14             	mov    0x14(%ebp),%eax
f010309f:	8d 50 04             	lea    0x4(%eax),%edx
f01030a2:	89 55 14             	mov    %edx,0x14(%ebp)
f01030a5:	8b 30                	mov    (%eax),%esi
f01030a7:	89 75 c8             	mov    %esi,-0x38(%ebp)
f01030aa:	89 f0                	mov    %esi,%eax
f01030ac:	c1 f8 1f             	sar    $0x1f,%eax
f01030af:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01030b2:	eb 16                	jmp    f01030ca <vprintfmt+0x2fe>
	else
		return va_arg(*ap, int);
f01030b4:	8b 45 14             	mov    0x14(%ebp),%eax
f01030b7:	8d 50 04             	lea    0x4(%eax),%edx
f01030ba:	89 55 14             	mov    %edx,0x14(%ebp)
f01030bd:	8b 30                	mov    (%eax),%esi
f01030bf:	89 75 c8             	mov    %esi,-0x38(%ebp)
f01030c2:	89 f0                	mov    %esi,%eax
f01030c4:	c1 f8 1f             	sar    $0x1f,%eax
f01030c7:	89 45 cc             	mov    %eax,-0x34(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01030ca:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01030cd:	8b 55 cc             	mov    -0x34(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01030d0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01030d5:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f01030d9:	0f 89 80 00 00 00    	jns    f010315f <vprintfmt+0x393>
				putch('-', putdat);
f01030df:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030e3:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01030ea:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01030ed:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01030f0:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01030f3:	f7 d8                	neg    %eax
f01030f5:	83 d2 00             	adc    $0x0,%edx
f01030f8:	f7 da                	neg    %edx
			}
			base = 10;
f01030fa:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01030ff:	eb 5e                	jmp    f010315f <vprintfmt+0x393>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103101:	8d 45 14             	lea    0x14(%ebp),%eax
f0103104:	e8 6c fc ff ff       	call   f0102d75 <getuint>
			base = 10;
f0103109:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010310e:	eb 4f                	jmp    f010315f <vprintfmt+0x393>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0103110:	8d 45 14             	lea    0x14(%ebp),%eax
f0103113:	e8 5d fc ff ff       	call   f0102d75 <getuint>
			base = 8;
f0103118:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010311d:	eb 40                	jmp    f010315f <vprintfmt+0x393>
		// pointer
		case 'p':
			putch('0', putdat);
f010311f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103123:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010312a:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010312d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103131:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103138:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010313b:	8b 45 14             	mov    0x14(%ebp),%eax
f010313e:	8d 50 04             	lea    0x4(%eax),%edx
f0103141:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103144:	8b 00                	mov    (%eax),%eax
f0103146:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010314b:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103150:	eb 0d                	jmp    f010315f <vprintfmt+0x393>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103152:	8d 45 14             	lea    0x14(%ebp),%eax
f0103155:	e8 1b fc ff ff       	call   f0102d75 <getuint>
			base = 16;
f010315a:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010315f:	0f be 75 d3          	movsbl -0x2d(%ebp),%esi
f0103163:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103167:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010316a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010316e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103172:	89 04 24             	mov    %eax,(%esp)
f0103175:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103179:	89 fa                	mov    %edi,%edx
f010317b:	8b 45 08             	mov    0x8(%ebp),%eax
f010317e:	e8 fd fa ff ff       	call   f0102c80 <printnum>
			break;
f0103183:	e9 6d fc ff ff       	jmp    f0102df5 <vprintfmt+0x29>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103188:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010318c:	89 0c 24             	mov    %ecx,(%esp)
f010318f:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103192:	e9 5e fc ff ff       	jmp    f0102df5 <vprintfmt+0x29>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103197:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010319b:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01031a2:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01031a5:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01031a9:	0f 84 44 fc ff ff    	je     f0102df3 <vprintfmt+0x27>
f01031af:	89 f3                	mov    %esi,%ebx
f01031b1:	83 eb 01             	sub    $0x1,%ebx
f01031b4:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01031b8:	75 f7                	jne    f01031b1 <vprintfmt+0x3e5>
f01031ba:	e9 36 fc ff ff       	jmp    f0102df5 <vprintfmt+0x29>
				/* do nothing */;
			break;
		}
	}
}
f01031bf:	83 c4 4c             	add    $0x4c,%esp
f01031c2:	5b                   	pop    %ebx
f01031c3:	5e                   	pop    %esi
f01031c4:	5f                   	pop    %edi
f01031c5:	5d                   	pop    %ebp
f01031c6:	c3                   	ret    

f01031c7 <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01031c7:	55                   	push   %ebp
f01031c8:	89 e5                	mov    %esp,%ebp
f01031ca:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
	vprintfmt(putch, putdat, fmt, ap);
f01031cd:	8d 45 14             	lea    0x14(%ebp),%eax
f01031d0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031d4:	8b 45 10             	mov    0x10(%ebp),%eax
f01031d7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01031db:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01031e5:	89 04 24             	mov    %eax,(%esp)
f01031e8:	e8 df fb ff ff       	call   f0102dcc <vprintfmt>
	va_end(ap);
}
f01031ed:	c9                   	leave  
f01031ee:	c3                   	ret    

f01031ef <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01031ef:	55                   	push   %ebp
f01031f0:	89 e5                	mov    %esp,%ebp
f01031f2:	83 ec 28             	sub    $0x28,%esp
f01031f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01031f8:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01031fb:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01031fe:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103202:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103205:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010320c:	85 c0                	test   %eax,%eax
f010320e:	74 30                	je     f0103240 <vsnprintf+0x51>
f0103210:	85 d2                	test   %edx,%edx
f0103212:	7e 2c                	jle    f0103240 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103214:	8b 45 14             	mov    0x14(%ebp),%eax
f0103217:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010321b:	8b 45 10             	mov    0x10(%ebp),%eax
f010321e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103222:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103225:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103229:	c7 04 24 af 2d 10 f0 	movl   $0xf0102daf,(%esp)
f0103230:	e8 97 fb ff ff       	call   f0102dcc <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103235:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103238:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010323b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010323e:	eb 05                	jmp    f0103245 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103240:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103245:	c9                   	leave  
f0103246:	c3                   	ret    

f0103247 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103247:	55                   	push   %ebp
f0103248:	89 e5                	mov    %esp,%ebp
f010324a:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
	rc = vsnprintf(buf, n, fmt, ap);
f010324d:	8d 45 14             	lea    0x14(%ebp),%eax
f0103250:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103254:	8b 45 10             	mov    0x10(%ebp),%eax
f0103257:	89 44 24 08          	mov    %eax,0x8(%esp)
f010325b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010325e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103262:	8b 45 08             	mov    0x8(%ebp),%eax
f0103265:	89 04 24             	mov    %eax,(%esp)
f0103268:	e8 82 ff ff ff       	call   f01031ef <vsnprintf>
	va_end(ap);

	return rc;
}
f010326d:	c9                   	leave  
f010326e:	c3                   	ret    
f010326f:	90                   	nop

f0103270 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103270:	55                   	push   %ebp
f0103271:	89 e5                	mov    %esp,%ebp
f0103273:	57                   	push   %edi
f0103274:	56                   	push   %esi
f0103275:	53                   	push   %ebx
f0103276:	83 ec 1c             	sub    $0x1c,%esp
f0103279:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010327c:	85 c0                	test   %eax,%eax
f010327e:	74 10                	je     f0103290 <readline+0x20>
		cprintf("%s", prompt);
f0103280:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103284:	c7 04 24 ed 43 10 f0 	movl   $0xf01043ed,(%esp)
f010328b:	e8 09 f7 ff ff       	call   f0102999 <cprintf>

	i = 0;
	echoing = iscons(0);
f0103290:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103297:	e8 9b d3 ff ff       	call   f0100637 <iscons>
f010329c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010329e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01032a3:	e8 7e d3 ff ff       	call   f0100626 <getchar>
f01032a8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01032aa:	85 c0                	test   %eax,%eax
f01032ac:	79 17                	jns    f01032c5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01032ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01032b2:	c7 04 24 20 48 10 f0 	movl   $0xf0104820,(%esp)
f01032b9:	e8 db f6 ff ff       	call   f0102999 <cprintf>
			return NULL;
f01032be:	b8 00 00 00 00       	mov    $0x0,%eax
f01032c3:	eb 61                	jmp    f0103326 <readline+0xb6>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01032c5:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01032cb:	7f 1c                	jg     f01032e9 <readline+0x79>
f01032cd:	83 f8 1f             	cmp    $0x1f,%eax
f01032d0:	7e 17                	jle    f01032e9 <readline+0x79>
			if (echoing)
f01032d2:	85 ff                	test   %edi,%edi
f01032d4:	74 08                	je     f01032de <readline+0x6e>
				cputchar(c);
f01032d6:	89 04 24             	mov    %eax,(%esp)
f01032d9:	e8 35 d3 ff ff       	call   f0100613 <cputchar>
			buf[i++] = c;
f01032de:	88 9e 00 56 11 f0    	mov    %bl,-0xfeeaa00(%esi)
f01032e4:	8d 76 01             	lea    0x1(%esi),%esi
f01032e7:	eb ba                	jmp    f01032a3 <readline+0x33>
		} else if (c == '\b' && i > 0) {
f01032e9:	85 f6                	test   %esi,%esi
f01032eb:	7e 16                	jle    f0103303 <readline+0x93>
f01032ed:	83 fb 08             	cmp    $0x8,%ebx
f01032f0:	75 11                	jne    f0103303 <readline+0x93>
			if (echoing)
f01032f2:	85 ff                	test   %edi,%edi
f01032f4:	74 08                	je     f01032fe <readline+0x8e>
				cputchar(c);
f01032f6:	89 1c 24             	mov    %ebx,(%esp)
f01032f9:	e8 15 d3 ff ff       	call   f0100613 <cputchar>
			i--;
f01032fe:	83 ee 01             	sub    $0x1,%esi
f0103301:	eb a0                	jmp    f01032a3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0103303:	83 fb 0d             	cmp    $0xd,%ebx
f0103306:	74 05                	je     f010330d <readline+0x9d>
f0103308:	83 fb 0a             	cmp    $0xa,%ebx
f010330b:	75 96                	jne    f01032a3 <readline+0x33>
			if (echoing)
f010330d:	85 ff                	test   %edi,%edi
f010330f:	90                   	nop
f0103310:	74 08                	je     f010331a <readline+0xaa>
				cputchar(c);
f0103312:	89 1c 24             	mov    %ebx,(%esp)
f0103315:	e8 f9 d2 ff ff       	call   f0100613 <cputchar>
			buf[i] = 0;
f010331a:	c6 86 00 56 11 f0 00 	movb   $0x0,-0xfeeaa00(%esi)
			return buf;
f0103321:	b8 00 56 11 f0       	mov    $0xf0115600,%eax
		}
	}
}
f0103326:	83 c4 1c             	add    $0x1c,%esp
f0103329:	5b                   	pop    %ebx
f010332a:	5e                   	pop    %esi
f010332b:	5f                   	pop    %edi
f010332c:	5d                   	pop    %ebp
f010332d:	c3                   	ret    
f010332e:	66 90                	xchg   %ax,%ax

f0103330 <strlen>:

#include <inc/string.h>

int
strlen(const char *s)
{
f0103330:	55                   	push   %ebp
f0103331:	89 e5                	mov    %esp,%ebp
f0103333:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103336:	80 3a 00             	cmpb   $0x0,(%edx)
f0103339:	74 10                	je     f010334b <strlen+0x1b>
f010333b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0103340:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103343:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103347:	75 f7                	jne    f0103340 <strlen+0x10>
f0103349:	eb 05                	jmp    f0103350 <strlen+0x20>
f010334b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0103350:	5d                   	pop    %ebp
f0103351:	c3                   	ret    

f0103352 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103352:	55                   	push   %ebp
f0103353:	89 e5                	mov    %esp,%ebp
f0103355:	53                   	push   %ebx
f0103356:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103359:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010335c:	85 c9                	test   %ecx,%ecx
f010335e:	74 1c                	je     f010337c <strnlen+0x2a>
f0103360:	80 3b 00             	cmpb   $0x0,(%ebx)
f0103363:	74 1e                	je     f0103383 <strnlen+0x31>
f0103365:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f010336a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010336c:	39 ca                	cmp    %ecx,%edx
f010336e:	74 18                	je     f0103388 <strnlen+0x36>
f0103370:	83 c2 01             	add    $0x1,%edx
f0103373:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0103378:	75 f0                	jne    f010336a <strnlen+0x18>
f010337a:	eb 0c                	jmp    f0103388 <strnlen+0x36>
f010337c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103381:	eb 05                	jmp    f0103388 <strnlen+0x36>
f0103383:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0103388:	5b                   	pop    %ebx
f0103389:	5d                   	pop    %ebp
f010338a:	c3                   	ret    

f010338b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010338b:	55                   	push   %ebp
f010338c:	89 e5                	mov    %esp,%ebp
f010338e:	53                   	push   %ebx
f010338f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103392:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103395:	89 c2                	mov    %eax,%edx
f0103397:	83 c2 01             	add    $0x1,%edx
f010339a:	83 c1 01             	add    $0x1,%ecx
f010339d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01033a1:	88 5a ff             	mov    %bl,-0x1(%edx)
f01033a4:	84 db                	test   %bl,%bl
f01033a6:	75 ef                	jne    f0103397 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01033a8:	5b                   	pop    %ebx
f01033a9:	5d                   	pop    %ebp
f01033aa:	c3                   	ret    

f01033ab <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01033ab:	55                   	push   %ebp
f01033ac:	89 e5                	mov    %esp,%ebp
f01033ae:	56                   	push   %esi
f01033af:	53                   	push   %ebx
f01033b0:	8b 75 08             	mov    0x8(%ebp),%esi
f01033b3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01033b6:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01033b9:	85 db                	test   %ebx,%ebx
f01033bb:	74 17                	je     f01033d4 <strncpy+0x29>
f01033bd:	01 f3                	add    %esi,%ebx
f01033bf:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f01033c1:	83 c1 01             	add    $0x1,%ecx
f01033c4:	0f b6 02             	movzbl (%edx),%eax
f01033c7:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01033ca:	80 3a 01             	cmpb   $0x1,(%edx)
f01033cd:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01033d0:	39 d9                	cmp    %ebx,%ecx
f01033d2:	75 ed                	jne    f01033c1 <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01033d4:	89 f0                	mov    %esi,%eax
f01033d6:	5b                   	pop    %ebx
f01033d7:	5e                   	pop    %esi
f01033d8:	5d                   	pop    %ebp
f01033d9:	c3                   	ret    

f01033da <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01033da:	55                   	push   %ebp
f01033db:	89 e5                	mov    %esp,%ebp
f01033dd:	57                   	push   %edi
f01033de:	56                   	push   %esi
f01033df:	53                   	push   %ebx
f01033e0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01033e3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01033e6:	8b 75 10             	mov    0x10(%ebp),%esi
f01033e9:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01033eb:	85 f6                	test   %esi,%esi
f01033ed:	74 34                	je     f0103423 <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f01033ef:	83 fe 01             	cmp    $0x1,%esi
f01033f2:	74 26                	je     f010341a <strlcpy+0x40>
f01033f4:	0f b6 0b             	movzbl (%ebx),%ecx
f01033f7:	84 c9                	test   %cl,%cl
f01033f9:	74 23                	je     f010341e <strlcpy+0x44>
f01033fb:	83 ee 02             	sub    $0x2,%esi
f01033fe:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f0103403:	83 c0 01             	add    $0x1,%eax
f0103406:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103409:	39 f2                	cmp    %esi,%edx
f010340b:	74 13                	je     f0103420 <strlcpy+0x46>
f010340d:	83 c2 01             	add    $0x1,%edx
f0103410:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103414:	84 c9                	test   %cl,%cl
f0103416:	75 eb                	jne    f0103403 <strlcpy+0x29>
f0103418:	eb 06                	jmp    f0103420 <strlcpy+0x46>
f010341a:	89 f8                	mov    %edi,%eax
f010341c:	eb 02                	jmp    f0103420 <strlcpy+0x46>
f010341e:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103420:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103423:	29 f8                	sub    %edi,%eax
}
f0103425:	5b                   	pop    %ebx
f0103426:	5e                   	pop    %esi
f0103427:	5f                   	pop    %edi
f0103428:	5d                   	pop    %ebp
f0103429:	c3                   	ret    

f010342a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010342a:	55                   	push   %ebp
f010342b:	89 e5                	mov    %esp,%ebp
f010342d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103430:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103433:	0f b6 01             	movzbl (%ecx),%eax
f0103436:	84 c0                	test   %al,%al
f0103438:	74 15                	je     f010344f <strcmp+0x25>
f010343a:	3a 02                	cmp    (%edx),%al
f010343c:	75 11                	jne    f010344f <strcmp+0x25>
		p++, q++;
f010343e:	83 c1 01             	add    $0x1,%ecx
f0103441:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103444:	0f b6 01             	movzbl (%ecx),%eax
f0103447:	84 c0                	test   %al,%al
f0103449:	74 04                	je     f010344f <strcmp+0x25>
f010344b:	3a 02                	cmp    (%edx),%al
f010344d:	74 ef                	je     f010343e <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010344f:	0f b6 c0             	movzbl %al,%eax
f0103452:	0f b6 12             	movzbl (%edx),%edx
f0103455:	29 d0                	sub    %edx,%eax
}
f0103457:	5d                   	pop    %ebp
f0103458:	c3                   	ret    

f0103459 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103459:	55                   	push   %ebp
f010345a:	89 e5                	mov    %esp,%ebp
f010345c:	56                   	push   %esi
f010345d:	53                   	push   %ebx
f010345e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103461:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103464:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0103467:	85 f6                	test   %esi,%esi
f0103469:	74 29                	je     f0103494 <strncmp+0x3b>
f010346b:	0f b6 03             	movzbl (%ebx),%eax
f010346e:	84 c0                	test   %al,%al
f0103470:	74 30                	je     f01034a2 <strncmp+0x49>
f0103472:	3a 02                	cmp    (%edx),%al
f0103474:	75 2c                	jne    f01034a2 <strncmp+0x49>
f0103476:	8d 43 01             	lea    0x1(%ebx),%eax
f0103479:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f010347b:	89 c3                	mov    %eax,%ebx
f010347d:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103480:	39 f0                	cmp    %esi,%eax
f0103482:	74 17                	je     f010349b <strncmp+0x42>
f0103484:	0f b6 08             	movzbl (%eax),%ecx
f0103487:	84 c9                	test   %cl,%cl
f0103489:	74 17                	je     f01034a2 <strncmp+0x49>
f010348b:	83 c0 01             	add    $0x1,%eax
f010348e:	3a 0a                	cmp    (%edx),%cl
f0103490:	74 e9                	je     f010347b <strncmp+0x22>
f0103492:	eb 0e                	jmp    f01034a2 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103494:	b8 00 00 00 00       	mov    $0x0,%eax
f0103499:	eb 0f                	jmp    f01034aa <strncmp+0x51>
f010349b:	b8 00 00 00 00       	mov    $0x0,%eax
f01034a0:	eb 08                	jmp    f01034aa <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01034a2:	0f b6 03             	movzbl (%ebx),%eax
f01034a5:	0f b6 12             	movzbl (%edx),%edx
f01034a8:	29 d0                	sub    %edx,%eax
}
f01034aa:	5b                   	pop    %ebx
f01034ab:	5e                   	pop    %esi
f01034ac:	5d                   	pop    %ebp
f01034ad:	c3                   	ret    

f01034ae <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01034ae:	55                   	push   %ebp
f01034af:	89 e5                	mov    %esp,%ebp
f01034b1:	53                   	push   %ebx
f01034b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01034b5:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f01034b8:	0f b6 18             	movzbl (%eax),%ebx
f01034bb:	84 db                	test   %bl,%bl
f01034bd:	74 1d                	je     f01034dc <strchr+0x2e>
f01034bf:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f01034c1:	38 d3                	cmp    %dl,%bl
f01034c3:	75 06                	jne    f01034cb <strchr+0x1d>
f01034c5:	eb 1a                	jmp    f01034e1 <strchr+0x33>
f01034c7:	38 ca                	cmp    %cl,%dl
f01034c9:	74 16                	je     f01034e1 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01034cb:	83 c0 01             	add    $0x1,%eax
f01034ce:	0f b6 10             	movzbl (%eax),%edx
f01034d1:	84 d2                	test   %dl,%dl
f01034d3:	75 f2                	jne    f01034c7 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f01034d5:	b8 00 00 00 00       	mov    $0x0,%eax
f01034da:	eb 05                	jmp    f01034e1 <strchr+0x33>
f01034dc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01034e1:	5b                   	pop    %ebx
f01034e2:	5d                   	pop    %ebp
f01034e3:	c3                   	ret    

f01034e4 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01034e4:	55                   	push   %ebp
f01034e5:	89 e5                	mov    %esp,%ebp
f01034e7:	53                   	push   %ebx
f01034e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01034eb:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f01034ee:	0f b6 18             	movzbl (%eax),%ebx
f01034f1:	84 db                	test   %bl,%bl
f01034f3:	74 17                	je     f010350c <strfind+0x28>
f01034f5:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f01034f7:	38 d3                	cmp    %dl,%bl
f01034f9:	75 07                	jne    f0103502 <strfind+0x1e>
f01034fb:	eb 0f                	jmp    f010350c <strfind+0x28>
f01034fd:	38 ca                	cmp    %cl,%dl
f01034ff:	90                   	nop
f0103500:	74 0a                	je     f010350c <strfind+0x28>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103502:	83 c0 01             	add    $0x1,%eax
f0103505:	0f b6 10             	movzbl (%eax),%edx
f0103508:	84 d2                	test   %dl,%dl
f010350a:	75 f1                	jne    f01034fd <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f010350c:	5b                   	pop    %ebx
f010350d:	5d                   	pop    %ebp
f010350e:	c3                   	ret    

f010350f <memset>:


void *
memset(void *v, int c, size_t n)
{
f010350f:	55                   	push   %ebp
f0103510:	89 e5                	mov    %esp,%ebp
f0103512:	53                   	push   %ebx
f0103513:	8b 45 08             	mov    0x8(%ebp),%eax
f0103516:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103519:	8b 5d 10             	mov    0x10(%ebp),%ebx
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f010351c:	89 da                	mov    %ebx,%edx
f010351e:	83 ea 01             	sub    $0x1,%edx
f0103521:	78 0e                	js     f0103531 <memset+0x22>
f0103523:	01 c3                	add    %eax,%ebx
memset(void *v, int c, size_t n)
{
	char *p;
	int m;

	p = v;
f0103525:	89 c2                	mov    %eax,%edx
	m = n;
	while (--m >= 0)
		*p++ = c;
f0103527:	83 c2 01             	add    $0x1,%edx
f010352a:	88 4a ff             	mov    %cl,-0x1(%edx)
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f010352d:	39 da                	cmp    %ebx,%edx
f010352f:	75 f6                	jne    f0103527 <memset+0x18>
		*p++ = c;

	return v;
}
f0103531:	5b                   	pop    %ebx
f0103532:	5d                   	pop    %ebp
f0103533:	c3                   	ret    

f0103534 <memmove>:

/* no memcpy - use memmove instead */

void *
memmove(void *dst, const void *src, size_t n)
{
f0103534:	55                   	push   %ebp
f0103535:	89 e5                	mov    %esp,%ebp
f0103537:	57                   	push   %edi
f0103538:	56                   	push   %esi
f0103539:	53                   	push   %ebx
f010353a:	8b 45 08             	mov    0x8(%ebp),%eax
f010353d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103540:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103543:	39 c6                	cmp    %eax,%esi
f0103545:	72 0b                	jb     f0103552 <memmove+0x1e>
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f0103547:	ba 00 00 00 00       	mov    $0x0,%edx
f010354c:	85 db                	test   %ebx,%ebx
f010354e:	75 2b                	jne    f010357b <memmove+0x47>
f0103550:	eb 37                	jmp    f0103589 <memmove+0x55>
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103552:	8d 0c 1e             	lea    (%esi,%ebx,1),%ecx
f0103555:	39 c8                	cmp    %ecx,%eax
f0103557:	73 ee                	jae    f0103547 <memmove+0x13>
		s += n;
		d += n;
f0103559:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
		while (n-- > 0)
f010355c:	8d 53 ff             	lea    -0x1(%ebx),%edx
f010355f:	85 db                	test   %ebx,%ebx
f0103561:	74 26                	je     f0103589 <memmove+0x55>
f0103563:	f7 db                	neg    %ebx
f0103565:	8d 34 19             	lea    (%ecx,%ebx,1),%esi
f0103568:	01 fb                	add    %edi,%ebx
			*--d = *--s;
f010356a:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f010356e:	88 0c 13             	mov    %cl,(%ebx,%edx,1)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
f0103571:	83 ea 01             	sub    $0x1,%edx
f0103574:	83 fa ff             	cmp    $0xffffffff,%edx
f0103577:	75 f1                	jne    f010356a <memmove+0x36>
f0103579:	eb 0e                	jmp    f0103589 <memmove+0x55>
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;
f010357b:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f010357f:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0103582:	83 c2 01             	add    $0x1,%edx
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f0103585:	39 da                	cmp    %ebx,%edx
f0103587:	75 f2                	jne    f010357b <memmove+0x47>
			*d++ = *s++;

	return dst;
}
f0103589:	5b                   	pop    %ebx
f010358a:	5e                   	pop    %esi
f010358b:	5f                   	pop    %edi
f010358c:	5d                   	pop    %ebp
f010358d:	c3                   	ret    

f010358e <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f010358e:	55                   	push   %ebp
f010358f:	89 e5                	mov    %esp,%ebp
f0103591:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103594:	8b 45 10             	mov    0x10(%ebp),%eax
f0103597:	89 44 24 08          	mov    %eax,0x8(%esp)
f010359b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010359e:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01035a5:	89 04 24             	mov    %eax,(%esp)
f01035a8:	e8 87 ff ff ff       	call   f0103534 <memmove>
}
f01035ad:	c9                   	leave  
f01035ae:	c3                   	ret    

f01035af <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01035af:	55                   	push   %ebp
f01035b0:	89 e5                	mov    %esp,%ebp
f01035b2:	57                   	push   %edi
f01035b3:	56                   	push   %esi
f01035b4:	53                   	push   %ebx
f01035b5:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01035b8:	8b 75 0c             	mov    0xc(%ebp),%esi
f01035bb:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01035be:	8d 78 ff             	lea    -0x1(%eax),%edi
f01035c1:	85 c0                	test   %eax,%eax
f01035c3:	74 36                	je     f01035fb <memcmp+0x4c>
		if (*s1 != *s2)
f01035c5:	0f b6 03             	movzbl (%ebx),%eax
f01035c8:	0f b6 0e             	movzbl (%esi),%ecx
f01035cb:	ba 00 00 00 00       	mov    $0x0,%edx
f01035d0:	38 c8                	cmp    %cl,%al
f01035d2:	74 1c                	je     f01035f0 <memcmp+0x41>
f01035d4:	eb 10                	jmp    f01035e6 <memcmp+0x37>
f01035d6:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01035db:	83 c2 01             	add    $0x1,%edx
f01035de:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01035e2:	38 c8                	cmp    %cl,%al
f01035e4:	74 0a                	je     f01035f0 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f01035e6:	0f b6 c0             	movzbl %al,%eax
f01035e9:	0f b6 c9             	movzbl %cl,%ecx
f01035ec:	29 c8                	sub    %ecx,%eax
f01035ee:	eb 10                	jmp    f0103600 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01035f0:	39 fa                	cmp    %edi,%edx
f01035f2:	75 e2                	jne    f01035d6 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01035f4:	b8 00 00 00 00       	mov    $0x0,%eax
f01035f9:	eb 05                	jmp    f0103600 <memcmp+0x51>
f01035fb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103600:	5b                   	pop    %ebx
f0103601:	5e                   	pop    %esi
f0103602:	5f                   	pop    %edi
f0103603:	5d                   	pop    %ebp
f0103604:	c3                   	ret    

f0103605 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103605:	55                   	push   %ebp
f0103606:	89 e5                	mov    %esp,%ebp
f0103608:	53                   	push   %ebx
f0103609:	8b 45 08             	mov    0x8(%ebp),%eax
f010360c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f010360f:	89 c2                	mov    %eax,%edx
f0103611:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103614:	39 d0                	cmp    %edx,%eax
f0103616:	73 13                	jae    f010362b <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103618:	89 d9                	mov    %ebx,%ecx
f010361a:	38 18                	cmp    %bl,(%eax)
f010361c:	75 06                	jne    f0103624 <memfind+0x1f>
f010361e:	eb 0b                	jmp    f010362b <memfind+0x26>
f0103620:	38 08                	cmp    %cl,(%eax)
f0103622:	74 07                	je     f010362b <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103624:	83 c0 01             	add    $0x1,%eax
f0103627:	39 d0                	cmp    %edx,%eax
f0103629:	75 f5                	jne    f0103620 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010362b:	5b                   	pop    %ebx
f010362c:	5d                   	pop    %ebp
f010362d:	c3                   	ret    

f010362e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010362e:	55                   	push   %ebp
f010362f:	89 e5                	mov    %esp,%ebp
f0103631:	57                   	push   %edi
f0103632:	56                   	push   %esi
f0103633:	53                   	push   %ebx
f0103634:	8b 55 08             	mov    0x8(%ebp),%edx
f0103637:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010363a:	0f b6 0a             	movzbl (%edx),%ecx
f010363d:	80 f9 09             	cmp    $0x9,%cl
f0103640:	74 05                	je     f0103647 <strtol+0x19>
f0103642:	80 f9 20             	cmp    $0x20,%cl
f0103645:	75 10                	jne    f0103657 <strtol+0x29>
		s++;
f0103647:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010364a:	0f b6 0a             	movzbl (%edx),%ecx
f010364d:	80 f9 09             	cmp    $0x9,%cl
f0103650:	74 f5                	je     f0103647 <strtol+0x19>
f0103652:	80 f9 20             	cmp    $0x20,%cl
f0103655:	74 f0                	je     f0103647 <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103657:	80 f9 2b             	cmp    $0x2b,%cl
f010365a:	75 0a                	jne    f0103666 <strtol+0x38>
		s++;
f010365c:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010365f:	bf 00 00 00 00       	mov    $0x0,%edi
f0103664:	eb 11                	jmp    f0103677 <strtol+0x49>
f0103666:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010366b:	80 f9 2d             	cmp    $0x2d,%cl
f010366e:	75 07                	jne    f0103677 <strtol+0x49>
		s++, neg = 1;
f0103670:	83 c2 01             	add    $0x1,%edx
f0103673:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103677:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f010367c:	75 15                	jne    f0103693 <strtol+0x65>
f010367e:	80 3a 30             	cmpb   $0x30,(%edx)
f0103681:	75 10                	jne    f0103693 <strtol+0x65>
f0103683:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103687:	75 0a                	jne    f0103693 <strtol+0x65>
		s += 2, base = 16;
f0103689:	83 c2 02             	add    $0x2,%edx
f010368c:	b8 10 00 00 00       	mov    $0x10,%eax
f0103691:	eb 10                	jmp    f01036a3 <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f0103693:	85 c0                	test   %eax,%eax
f0103695:	75 0c                	jne    f01036a3 <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103697:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103699:	80 3a 30             	cmpb   $0x30,(%edx)
f010369c:	75 05                	jne    f01036a3 <strtol+0x75>
		s++, base = 8;
f010369e:	83 c2 01             	add    $0x1,%edx
f01036a1:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f01036a3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01036a8:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01036ab:	0f b6 0a             	movzbl (%edx),%ecx
f01036ae:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01036b1:	89 f0                	mov    %esi,%eax
f01036b3:	3c 09                	cmp    $0x9,%al
f01036b5:	77 08                	ja     f01036bf <strtol+0x91>
			dig = *s - '0';
f01036b7:	0f be c9             	movsbl %cl,%ecx
f01036ba:	83 e9 30             	sub    $0x30,%ecx
f01036bd:	eb 20                	jmp    f01036df <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f01036bf:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01036c2:	89 f0                	mov    %esi,%eax
f01036c4:	3c 19                	cmp    $0x19,%al
f01036c6:	77 08                	ja     f01036d0 <strtol+0xa2>
			dig = *s - 'a' + 10;
f01036c8:	0f be c9             	movsbl %cl,%ecx
f01036cb:	83 e9 57             	sub    $0x57,%ecx
f01036ce:	eb 0f                	jmp    f01036df <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f01036d0:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01036d3:	89 f0                	mov    %esi,%eax
f01036d5:	3c 19                	cmp    $0x19,%al
f01036d7:	77 16                	ja     f01036ef <strtol+0xc1>
			dig = *s - 'A' + 10;
f01036d9:	0f be c9             	movsbl %cl,%ecx
f01036dc:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01036df:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01036e2:	7d 0f                	jge    f01036f3 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01036e4:	83 c2 01             	add    $0x1,%edx
f01036e7:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01036eb:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01036ed:	eb bc                	jmp    f01036ab <strtol+0x7d>
f01036ef:	89 d8                	mov    %ebx,%eax
f01036f1:	eb 02                	jmp    f01036f5 <strtol+0xc7>
f01036f3:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01036f5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01036f9:	74 05                	je     f0103700 <strtol+0xd2>
		*endptr = (char *) s;
f01036fb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01036fe:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0103700:	f7 d8                	neg    %eax
f0103702:	85 ff                	test   %edi,%edi
f0103704:	0f 44 c3             	cmove  %ebx,%eax
}
f0103707:	5b                   	pop    %ebx
f0103708:	5e                   	pop    %esi
f0103709:	5f                   	pop    %edi
f010370a:	5d                   	pop    %ebp
f010370b:	c3                   	ret    
f010370c:	66 90                	xchg   %ax,%ax
f010370e:	66 90                	xchg   %ax,%ax

f0103710 <__udivdi3>:
f0103710:	55                   	push   %ebp
f0103711:	57                   	push   %edi
f0103712:	56                   	push   %esi
f0103713:	83 ec 0c             	sub    $0xc,%esp
f0103716:	8b 44 24 28          	mov    0x28(%esp),%eax
f010371a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010371e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0103722:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103726:	85 c0                	test   %eax,%eax
f0103728:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010372c:	89 ea                	mov    %ebp,%edx
f010372e:	89 0c 24             	mov    %ecx,(%esp)
f0103731:	75 2d                	jne    f0103760 <__udivdi3+0x50>
f0103733:	39 e9                	cmp    %ebp,%ecx
f0103735:	77 61                	ja     f0103798 <__udivdi3+0x88>
f0103737:	85 c9                	test   %ecx,%ecx
f0103739:	89 ce                	mov    %ecx,%esi
f010373b:	75 0b                	jne    f0103748 <__udivdi3+0x38>
f010373d:	b8 01 00 00 00       	mov    $0x1,%eax
f0103742:	31 d2                	xor    %edx,%edx
f0103744:	f7 f1                	div    %ecx
f0103746:	89 c6                	mov    %eax,%esi
f0103748:	31 d2                	xor    %edx,%edx
f010374a:	89 e8                	mov    %ebp,%eax
f010374c:	f7 f6                	div    %esi
f010374e:	89 c5                	mov    %eax,%ebp
f0103750:	89 f8                	mov    %edi,%eax
f0103752:	f7 f6                	div    %esi
f0103754:	89 ea                	mov    %ebp,%edx
f0103756:	83 c4 0c             	add    $0xc,%esp
f0103759:	5e                   	pop    %esi
f010375a:	5f                   	pop    %edi
f010375b:	5d                   	pop    %ebp
f010375c:	c3                   	ret    
f010375d:	8d 76 00             	lea    0x0(%esi),%esi
f0103760:	39 e8                	cmp    %ebp,%eax
f0103762:	77 24                	ja     f0103788 <__udivdi3+0x78>
f0103764:	0f bd e8             	bsr    %eax,%ebp
f0103767:	83 f5 1f             	xor    $0x1f,%ebp
f010376a:	75 3c                	jne    f01037a8 <__udivdi3+0x98>
f010376c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103770:	39 34 24             	cmp    %esi,(%esp)
f0103773:	0f 86 9f 00 00 00    	jbe    f0103818 <__udivdi3+0x108>
f0103779:	39 d0                	cmp    %edx,%eax
f010377b:	0f 82 97 00 00 00    	jb     f0103818 <__udivdi3+0x108>
f0103781:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103788:	31 d2                	xor    %edx,%edx
f010378a:	31 c0                	xor    %eax,%eax
f010378c:	83 c4 0c             	add    $0xc,%esp
f010378f:	5e                   	pop    %esi
f0103790:	5f                   	pop    %edi
f0103791:	5d                   	pop    %ebp
f0103792:	c3                   	ret    
f0103793:	90                   	nop
f0103794:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103798:	89 f8                	mov    %edi,%eax
f010379a:	f7 f1                	div    %ecx
f010379c:	31 d2                	xor    %edx,%edx
f010379e:	83 c4 0c             	add    $0xc,%esp
f01037a1:	5e                   	pop    %esi
f01037a2:	5f                   	pop    %edi
f01037a3:	5d                   	pop    %ebp
f01037a4:	c3                   	ret    
f01037a5:	8d 76 00             	lea    0x0(%esi),%esi
f01037a8:	89 e9                	mov    %ebp,%ecx
f01037aa:	8b 3c 24             	mov    (%esp),%edi
f01037ad:	d3 e0                	shl    %cl,%eax
f01037af:	89 c6                	mov    %eax,%esi
f01037b1:	b8 20 00 00 00       	mov    $0x20,%eax
f01037b6:	29 e8                	sub    %ebp,%eax
f01037b8:	89 c1                	mov    %eax,%ecx
f01037ba:	d3 ef                	shr    %cl,%edi
f01037bc:	89 e9                	mov    %ebp,%ecx
f01037be:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01037c2:	8b 3c 24             	mov    (%esp),%edi
f01037c5:	09 74 24 08          	or     %esi,0x8(%esp)
f01037c9:	89 d6                	mov    %edx,%esi
f01037cb:	d3 e7                	shl    %cl,%edi
f01037cd:	89 c1                	mov    %eax,%ecx
f01037cf:	89 3c 24             	mov    %edi,(%esp)
f01037d2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01037d6:	d3 ee                	shr    %cl,%esi
f01037d8:	89 e9                	mov    %ebp,%ecx
f01037da:	d3 e2                	shl    %cl,%edx
f01037dc:	89 c1                	mov    %eax,%ecx
f01037de:	d3 ef                	shr    %cl,%edi
f01037e0:	09 d7                	or     %edx,%edi
f01037e2:	89 f2                	mov    %esi,%edx
f01037e4:	89 f8                	mov    %edi,%eax
f01037e6:	f7 74 24 08          	divl   0x8(%esp)
f01037ea:	89 d6                	mov    %edx,%esi
f01037ec:	89 c7                	mov    %eax,%edi
f01037ee:	f7 24 24             	mull   (%esp)
f01037f1:	39 d6                	cmp    %edx,%esi
f01037f3:	89 14 24             	mov    %edx,(%esp)
f01037f6:	72 30                	jb     f0103828 <__udivdi3+0x118>
f01037f8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01037fc:	89 e9                	mov    %ebp,%ecx
f01037fe:	d3 e2                	shl    %cl,%edx
f0103800:	39 c2                	cmp    %eax,%edx
f0103802:	73 05                	jae    f0103809 <__udivdi3+0xf9>
f0103804:	3b 34 24             	cmp    (%esp),%esi
f0103807:	74 1f                	je     f0103828 <__udivdi3+0x118>
f0103809:	89 f8                	mov    %edi,%eax
f010380b:	31 d2                	xor    %edx,%edx
f010380d:	e9 7a ff ff ff       	jmp    f010378c <__udivdi3+0x7c>
f0103812:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103818:	31 d2                	xor    %edx,%edx
f010381a:	b8 01 00 00 00       	mov    $0x1,%eax
f010381f:	e9 68 ff ff ff       	jmp    f010378c <__udivdi3+0x7c>
f0103824:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103828:	8d 47 ff             	lea    -0x1(%edi),%eax
f010382b:	31 d2                	xor    %edx,%edx
f010382d:	83 c4 0c             	add    $0xc,%esp
f0103830:	5e                   	pop    %esi
f0103831:	5f                   	pop    %edi
f0103832:	5d                   	pop    %ebp
f0103833:	c3                   	ret    
f0103834:	66 90                	xchg   %ax,%ax
f0103836:	66 90                	xchg   %ax,%ax
f0103838:	66 90                	xchg   %ax,%ax
f010383a:	66 90                	xchg   %ax,%ax
f010383c:	66 90                	xchg   %ax,%ax
f010383e:	66 90                	xchg   %ax,%ax

f0103840 <__umoddi3>:
f0103840:	55                   	push   %ebp
f0103841:	57                   	push   %edi
f0103842:	56                   	push   %esi
f0103843:	83 ec 14             	sub    $0x14,%esp
f0103846:	8b 44 24 28          	mov    0x28(%esp),%eax
f010384a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010384e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0103852:	89 c7                	mov    %eax,%edi
f0103854:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103858:	8b 44 24 30          	mov    0x30(%esp),%eax
f010385c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103860:	89 34 24             	mov    %esi,(%esp)
f0103863:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103867:	85 c0                	test   %eax,%eax
f0103869:	89 c2                	mov    %eax,%edx
f010386b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010386f:	75 17                	jne    f0103888 <__umoddi3+0x48>
f0103871:	39 fe                	cmp    %edi,%esi
f0103873:	76 4b                	jbe    f01038c0 <__umoddi3+0x80>
f0103875:	89 c8                	mov    %ecx,%eax
f0103877:	89 fa                	mov    %edi,%edx
f0103879:	f7 f6                	div    %esi
f010387b:	89 d0                	mov    %edx,%eax
f010387d:	31 d2                	xor    %edx,%edx
f010387f:	83 c4 14             	add    $0x14,%esp
f0103882:	5e                   	pop    %esi
f0103883:	5f                   	pop    %edi
f0103884:	5d                   	pop    %ebp
f0103885:	c3                   	ret    
f0103886:	66 90                	xchg   %ax,%ax
f0103888:	39 f8                	cmp    %edi,%eax
f010388a:	77 54                	ja     f01038e0 <__umoddi3+0xa0>
f010388c:	0f bd e8             	bsr    %eax,%ebp
f010388f:	83 f5 1f             	xor    $0x1f,%ebp
f0103892:	75 5c                	jne    f01038f0 <__umoddi3+0xb0>
f0103894:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103898:	39 3c 24             	cmp    %edi,(%esp)
f010389b:	0f 87 e7 00 00 00    	ja     f0103988 <__umoddi3+0x148>
f01038a1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01038a5:	29 f1                	sub    %esi,%ecx
f01038a7:	19 c7                	sbb    %eax,%edi
f01038a9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01038ad:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01038b1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01038b5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01038b9:	83 c4 14             	add    $0x14,%esp
f01038bc:	5e                   	pop    %esi
f01038bd:	5f                   	pop    %edi
f01038be:	5d                   	pop    %ebp
f01038bf:	c3                   	ret    
f01038c0:	85 f6                	test   %esi,%esi
f01038c2:	89 f5                	mov    %esi,%ebp
f01038c4:	75 0b                	jne    f01038d1 <__umoddi3+0x91>
f01038c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01038cb:	31 d2                	xor    %edx,%edx
f01038cd:	f7 f6                	div    %esi
f01038cf:	89 c5                	mov    %eax,%ebp
f01038d1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01038d5:	31 d2                	xor    %edx,%edx
f01038d7:	f7 f5                	div    %ebp
f01038d9:	89 c8                	mov    %ecx,%eax
f01038db:	f7 f5                	div    %ebp
f01038dd:	eb 9c                	jmp    f010387b <__umoddi3+0x3b>
f01038df:	90                   	nop
f01038e0:	89 c8                	mov    %ecx,%eax
f01038e2:	89 fa                	mov    %edi,%edx
f01038e4:	83 c4 14             	add    $0x14,%esp
f01038e7:	5e                   	pop    %esi
f01038e8:	5f                   	pop    %edi
f01038e9:	5d                   	pop    %ebp
f01038ea:	c3                   	ret    
f01038eb:	90                   	nop
f01038ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01038f0:	8b 04 24             	mov    (%esp),%eax
f01038f3:	be 20 00 00 00       	mov    $0x20,%esi
f01038f8:	89 e9                	mov    %ebp,%ecx
f01038fa:	29 ee                	sub    %ebp,%esi
f01038fc:	d3 e2                	shl    %cl,%edx
f01038fe:	89 f1                	mov    %esi,%ecx
f0103900:	d3 e8                	shr    %cl,%eax
f0103902:	89 e9                	mov    %ebp,%ecx
f0103904:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103908:	8b 04 24             	mov    (%esp),%eax
f010390b:	09 54 24 04          	or     %edx,0x4(%esp)
f010390f:	89 fa                	mov    %edi,%edx
f0103911:	d3 e0                	shl    %cl,%eax
f0103913:	89 f1                	mov    %esi,%ecx
f0103915:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103919:	8b 44 24 10          	mov    0x10(%esp),%eax
f010391d:	d3 ea                	shr    %cl,%edx
f010391f:	89 e9                	mov    %ebp,%ecx
f0103921:	d3 e7                	shl    %cl,%edi
f0103923:	89 f1                	mov    %esi,%ecx
f0103925:	d3 e8                	shr    %cl,%eax
f0103927:	89 e9                	mov    %ebp,%ecx
f0103929:	09 f8                	or     %edi,%eax
f010392b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010392f:	f7 74 24 04          	divl   0x4(%esp)
f0103933:	d3 e7                	shl    %cl,%edi
f0103935:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103939:	89 d7                	mov    %edx,%edi
f010393b:	f7 64 24 08          	mull   0x8(%esp)
f010393f:	39 d7                	cmp    %edx,%edi
f0103941:	89 c1                	mov    %eax,%ecx
f0103943:	89 14 24             	mov    %edx,(%esp)
f0103946:	72 2c                	jb     f0103974 <__umoddi3+0x134>
f0103948:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010394c:	72 22                	jb     f0103970 <__umoddi3+0x130>
f010394e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103952:	29 c8                	sub    %ecx,%eax
f0103954:	19 d7                	sbb    %edx,%edi
f0103956:	89 e9                	mov    %ebp,%ecx
f0103958:	89 fa                	mov    %edi,%edx
f010395a:	d3 e8                	shr    %cl,%eax
f010395c:	89 f1                	mov    %esi,%ecx
f010395e:	d3 e2                	shl    %cl,%edx
f0103960:	89 e9                	mov    %ebp,%ecx
f0103962:	d3 ef                	shr    %cl,%edi
f0103964:	09 d0                	or     %edx,%eax
f0103966:	89 fa                	mov    %edi,%edx
f0103968:	83 c4 14             	add    $0x14,%esp
f010396b:	5e                   	pop    %esi
f010396c:	5f                   	pop    %edi
f010396d:	5d                   	pop    %ebp
f010396e:	c3                   	ret    
f010396f:	90                   	nop
f0103970:	39 d7                	cmp    %edx,%edi
f0103972:	75 da                	jne    f010394e <__umoddi3+0x10e>
f0103974:	8b 14 24             	mov    (%esp),%edx
f0103977:	89 c1                	mov    %eax,%ecx
f0103979:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010397d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0103981:	eb cb                	jmp    f010394e <__umoddi3+0x10e>
f0103983:	90                   	nop
f0103984:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103988:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010398c:	0f 82 0f ff ff ff    	jb     f01038a1 <__umoddi3+0x61>
f0103992:	e9 1a ff ff ff       	jmp    f01038b1 <__umoddi3+0x71>
