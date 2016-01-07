
obj/boot/boot.out：     文件格式 elf32-i386


Disassembly of section .text:

00007c00 <start>:
.set CR0_PE_ON,      0x1         # protected mode enable flag

.globl start
start:
  .code16                     # Assemble for 16-bit mode
  cli                         # Disable interrupts
    7c00:	fa                   	cli    
  cld                         # String operations increment
    7c01:	fc                   	cld    

  # Set up the important data segment registers (DS, ES, SS).
  xorw    %ax,%ax             # Segment number zero
    7c02:	31 c0                	xor    %eax,%eax
  movw    %ax,%ds             # -> Data Segment
    7c04:	8e d8                	mov    %eax,%ds
  movw    %ax,%es             # -> Extra Segment
    7c06:	8e c0                	mov    %eax,%es
  movw    %ax,%ss             # -> Stack Segment
    7c08:	8e d0                	mov    %eax,%ss

00007c0a <seta20.1>:
  # Enable A20:
  #   For backwards compatibility with the earliest PCs, physical
  #   address line 20 is tied low, so that addresses higher than
  #   1MB wrap around to zero by default.  This code undoes this.
seta20.1:
  inb     $0x64,%al               # Wait for not busy
    7c0a:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c0c:	a8 02                	test   $0x2,%al
  jnz     seta20.1
    7c0e:	75 fa                	jne    7c0a <seta20.1>

  movb    $0xd1,%al               # 0xd1 -> port 0x64
    7c10:	b0 d1                	mov    $0xd1,%al
  outb    %al,$0x64
    7c12:	e6 64                	out    %al,$0x64

00007c14 <seta20.2>:

seta20.2:
  inb     $0x64,%al               # Wait for not busy
    7c14:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c16:	a8 02                	test   $0x2,%al
  jnz     seta20.2
    7c18:	75 fa                	jne    7c14 <seta20.2>

  movb    $0xdf,%al               # 0xdf -> port 0x60
    7c1a:	b0 df                	mov    $0xdf,%al
  outb    %al,$0x60
    7c1c:	e6 60                	out    %al,$0x60

  # Switch from real to protected mode, using a bootstrap GDT
  # and segment translation that makes virtual addresses 
  # identical to their physical addresses, so that the 
  # effective memory map does not change during the switch.
  lgdt    gdtdesc
    7c1e:	0f 01 16             	lgdtl  (%esi)
    7c21:	64                   	fs
    7c22:	7c 0f                	jl     7c33 <protcseg+0x1>
  movl    %cr0, %eax
    7c24:	20 c0                	and    %al,%al
  orl     $CR0_PE_ON, %eax
    7c26:	66 83 c8 01          	or     $0x1,%ax
  movl    %eax, %cr0
    7c2a:	0f 22 c0             	mov    %eax,%cr0
  
  # Jump to next instruction, but in 32-bit code segment.
  # Switches processor into 32-bit mode.
  ljmp    $PROT_MODE_CSEG, $protcseg
    7c2d:	ea 32 7c 08 00 66 b8 	ljmp   $0xb866,$0x87c32

00007c32 <protcseg>:

  .code32                     # Assemble for 32-bit mode
protcseg:
  # Set up the protected-mode data segment registers
  movw    $PROT_MODE_DSEG, %ax    # Our data segment selector
    7c32:	66 b8 10 00          	mov    $0x10,%ax
  movw    %ax, %ds                # -> DS: Data Segment
    7c36:	8e d8                	mov    %eax,%ds
  movw    %ax, %es                # -> ES: Extra Segment
    7c38:	8e c0                	mov    %eax,%es
  movw    %ax, %fs                # -> FS
    7c3a:	8e e0                	mov    %eax,%fs
  movw    %ax, %gs                # -> GS
    7c3c:	8e e8                	mov    %eax,%gs
  movw    %ax, %ss                # -> SS: Stack Segment
    7c3e:	8e d0                	mov    %eax,%ss
  
  # Set up the stack pointer and call into C.
  movl    $start, %esp
    7c40:	bc 00 7c 00 00       	mov    $0x7c00,%esp
  call bootmain
    7c45:	e8 7c 00 00 00       	call   7cc6 <bootmain>

00007c4a <spin>:

  # If bootmain returns (it shouldn't), loop.
spin:
  jmp spin
    7c4a:	eb fe                	jmp    7c4a <spin>

00007c4c <gdt>:
	...
    7c54:	ff                   	(bad)  
    7c55:	ff 00                	incl   (%eax)
    7c57:	00 00                	add    %al,(%eax)
    7c59:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    7c60:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

00007c64 <gdtdesc>:
    7c64:	17                   	pop    %ss
    7c65:	00 4c 7c 00          	add    %cl,0x0(%esp,%edi,2)
	...

00007c6a <readsect>:
		/* do nothing */;
}

static void
readsect(void *dst, uint32_t offset)
{
    7c6a:	55                   	push   %ebp
    7c6b:	89 d1                	mov    %edx,%ecx
    7c6d:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
    7c6f:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7c74:	57                   	push   %edi
    7c75:	89 c7                	mov    %eax,%edi
    7c77:	ec                   	in     (%dx),%al

static void
waitdisk(void)
{
	// wait for disk reaady
	while ((inb(0x1F7) & 0xC0) != 0x40)
    7c78:	83 e0 c0             	and    $0xffffffc0,%eax
    7c7b:	3c 40                	cmp    $0x40,%al
    7c7d:	75 f8                	jne    7c77 <readsect+0xd>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
    7c7f:	ba f2 01 00 00       	mov    $0x1f2,%edx
    7c84:	b0 01                	mov    $0x1,%al
    7c86:	ee                   	out    %al,(%dx)
    7c87:	0f b6 c1             	movzbl %cl,%eax
    7c8a:	b2 f3                	mov    $0xf3,%dl
    7c8c:	ee                   	out    %al,(%dx)
    7c8d:	0f b6 c5             	movzbl %ch,%eax
    7c90:	b2 f4                	mov    $0xf4,%dl
    7c92:	ee                   	out    %al,(%dx)
	waitdisk();

	outb(0x1F2, 1);		// count = 1
	outb(0x1F3, offset);
	outb(0x1F4, offset >> 8);
	outb(0x1F5, offset >> 16);
    7c93:	89 c8                	mov    %ecx,%eax
    7c95:	b2 f5                	mov    $0xf5,%dl
    7c97:	c1 e8 10             	shr    $0x10,%eax
    7c9a:	0f b6 c0             	movzbl %al,%eax
    7c9d:	ee                   	out    %al,(%dx)
	outb(0x1F6, (offset >> 24) | 0xE0);
    7c9e:	c1 e9 18             	shr    $0x18,%ecx
    7ca1:	b2 f6                	mov    $0xf6,%dl
    7ca3:	88 c8                	mov    %cl,%al
    7ca5:	83 c8 e0             	or     $0xffffffe0,%eax
    7ca8:	ee                   	out    %al,(%dx)
    7ca9:	b0 20                	mov    $0x20,%al
    7cab:	b2 f7                	mov    $0xf7,%dl
    7cad:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
    7cae:	ec                   	in     (%dx),%al

static void
waitdisk(void)
{
	// wait for disk reaady
	while ((inb(0x1F7) & 0xC0) != 0x40)
    7caf:	83 e0 c0             	and    $0xffffffc0,%eax
    7cb2:	3c 40                	cmp    $0x40,%al
    7cb4:	75 f8                	jne    7cae <readsect+0x44>
}

static __inline void
insl(int port, void *addr, int cnt)
{
	__asm __volatile("cld\n\trepne\n\tinsl"			:
    7cb6:	b9 80 00 00 00       	mov    $0x80,%ecx
    7cbb:	ba f0 01 00 00       	mov    $0x1f0,%edx
    7cc0:	fc                   	cld    
    7cc1:	f2 6d                	repnz insl (%dx),%es:(%edi)
	// wait for disk to be ready
	waitdisk();

	// read a sector
	insl(0x1F0, dst, SECTSIZE/4);
}
    7cc3:	5f                   	pop    %edi
    7cc4:	5d                   	pop    %ebp
    7cc5:	c3                   	ret    

00007cc6 <bootmain>:
static void readsect(void*, uint32_t);
static void readseg(uint32_t, uint32_t, uint32_t);

void
bootmain(void)
{
    7cc6:	55                   	push   %ebp
    7cc7:	89 e5                	mov    %esp,%ebp
    7cc9:	57                   	push   %edi
    7cca:	56                   	push   %esi
    7ccb:	53                   	push   %ebx
	
	// round down to sector boundary
	va &= ~(SECTSIZE - 1);

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;
    7ccc:	bb 01 00 00 00       	mov    $0x1,%ebx
static void readsect(void*, uint32_t);
static void readseg(uint32_t, uint32_t, uint32_t);

void
bootmain(void)
{
    7cd1:	83 ec 1c             	sub    $0x1c,%esp
    7cd4:	8d 43 7f             	lea    0x7f(%ebx),%eax

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (va < end_va) {
		readsect((uint8_t*) va, offset);
    7cd7:	89 da                	mov    %ebx,%edx
    7cd9:	c1 e0 09             	shl    $0x9,%eax
		va += SECTSIZE;
		offset++;
    7cdc:	43                   	inc    %ebx

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (va < end_va) {
		readsect((uint8_t*) va, offset);
    7cdd:	e8 88 ff ff ff       	call   7c6a <readsect>
	offset = (offset / SECTSIZE) + 1;

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (va < end_va) {
    7ce2:	83 fb 09             	cmp    $0x9,%ebx
    7ce5:	75 ed                	jne    7cd4 <bootmain+0xe>

	// read 1st page off disk
	readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);

	// is this a valid ELF?
	if (ELFHDR->e_magic != ELF_MAGIC)
    7ce7:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
    7cee:	45 4c 46 
    7cf1:	75 66                	jne    7d59 <bootmain+0x93>
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    7cf3:	a1 1c 00 01 00       	mov    0x1001c,%eax
    7cf8:	8d 98 00 00 01 00    	lea    0x10000(%eax),%ebx
	eph = ph + ELFHDR->e_phnum;
    7cfe:	0f b7 05 2c 00 01 00 	movzwl 0x1002c,%eax
    7d05:	c1 e0 05             	shl    $0x5,%eax
    7d08:	01 d8                	add    %ebx,%eax
    7d0a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (; ph < eph; ph++)
    7d0d:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
    7d10:	73 3b                	jae    7d4d <bootmain+0x87>
		readseg(ph->p_va, ph->p_memsz, ph->p_offset);
    7d12:	8b 73 08             	mov    0x8(%ebx),%esi
	
	// round down to sector boundary
	va &= ~(SECTSIZE - 1);

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;
    7d15:	8b 4b 04             	mov    0x4(%ebx),%ecx
static void
readseg(uint32_t va, uint32_t count, uint32_t offset)
{
	uint32_t end_va;

	va &= 0xFFFFFF;
    7d18:	89 f7                	mov    %esi,%edi
	end_va = va + count;
	
	// round down to sector boundary
	va &= ~(SECTSIZE - 1);
    7d1a:	81 e6 00 fe ff 00    	and    $0xfffe00,%esi
static void
readseg(uint32_t va, uint32_t count, uint32_t offset)
{
	uint32_t end_va;

	va &= 0xFFFFFF;
    7d20:	81 e7 ff ff ff 00    	and    $0xffffff,%edi
	end_va = va + count;
    7d26:	03 7b 14             	add    0x14(%ebx),%edi
	
	// round down to sector boundary
	va &= ~(SECTSIZE - 1);

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;
    7d29:	c1 e9 09             	shr    $0x9,%ecx
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (va < end_va) {
		readsect((uint8_t*) va, offset);
		va += SECTSIZE;
		offset++;
    7d2c:	41                   	inc    %ecx
	offset = (offset / SECTSIZE) + 1;

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (va < end_va) {
    7d2d:	39 fe                	cmp    %edi,%esi
    7d2f:	73 17                	jae    7d48 <bootmain+0x82>
		readsect((uint8_t*) va, offset);
    7d31:	89 ca                	mov    %ecx,%edx
    7d33:	89 f0                	mov    %esi,%eax
    7d35:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		va += SECTSIZE;
    7d38:	81 c6 00 02 00 00    	add    $0x200,%esi

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (va < end_va) {
		readsect((uint8_t*) va, offset);
    7d3e:	e8 27 ff ff ff       	call   7c6a <readsect>
		va += SECTSIZE;
		offset++;
    7d43:	8b 4d e0             	mov    -0x20(%ebp),%ecx
    7d46:	eb e4                	jmp    7d2c <bootmain+0x66>
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	for (; ph < eph; ph++)
    7d48:	83 c3 20             	add    $0x20,%ebx
    7d4b:	eb c0                	jmp    7d0d <bootmain+0x47>
		readseg(ph->p_va, ph->p_memsz, ph->p_offset);

	// call the entry point from the ELF header
	// note: does not return!
	((void (*)(void)) (ELFHDR->e_entry & 0xFFFFFF))();
    7d4d:	a1 18 00 01 00       	mov    0x10018,%eax
    7d52:	25 ff ff ff 00       	and    $0xffffff,%eax
    7d57:	ff d0                	call   *%eax
}

static __inline void
outw(int port, uint16_t data)
{
	__asm __volatile("outw %0,%w1" : : "a" (data), "d" (port));
    7d59:	ba 00 8a 00 00       	mov    $0x8a00,%edx
    7d5e:	b8 00 8a ff ff       	mov    $0xffff8a00,%eax
    7d63:	66 ef                	out    %ax,(%dx)
    7d65:	b8 00 8e ff ff       	mov    $0xffff8e00,%eax
    7d6a:	66 ef                	out    %ax,(%dx)
    7d6c:	eb fe                	jmp    7d6c <bootmain+0xa6>
