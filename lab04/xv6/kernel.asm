
kernel:     file format elf32-i386


Disassembly of section .text:

00100000 <multiboot_header>:
  100000:	02 b0 ad 1b 01 00    	add    0x11bad(%eax),%dh
  100006:	01 00                	add    %eax,(%eax)
  100008:	fd                   	std    
  100009:	4f                   	dec    %edi
  10000a:	51                   	push   %ecx
  10000b:	e4 00                	in     $0x0,%al
  10000d:	00 10                	add    %dl,(%eax)
  10000f:	00 00                	add    %al,(%eax)
  100011:	00 10                	add    %dl,(%eax)
  100013:	00 06                	add    %al,(%esi)
  100015:	78 10                	js     100027 <multiboot_entry+0x7>
  100017:	00 04 e9             	add    %al,(%ecx,%ebp,8)
  10001a:	10 00                	adc    %al,(%eax)
  10001c:	20 00                	and    %al,(%eax)
  10001e:	10 00                	adc    %al,(%eax)

00100020 <multiboot_entry>:
# Multiboot entry point.  Machine is mostly set up.
# Configure the GDT to match the environment that our usual
# boot loader - bootasm.S - sets up.
.globl multiboot_entry
multiboot_entry:
  lgdt gdtdesc
  100020:	0f 01 15 64 00 10 00 	lgdtl  0x100064
  ljmp $(SEG_KCODE<<3), $mbstart32
  100027:	ea 2e 00 10 00 08 00 	ljmp   $0x8,$0x10002e

0010002e <mbstart32>:

mbstart32:
  # Set up the protected-mode data segment registers
  movw    $(SEG_KDATA<<3), %ax    # Our data segment selector
  10002e:	66 b8 10 00          	mov    $0x10,%ax
  movw    %ax, %ds                # -> DS: Data Segment
  100032:	8e d8                	mov    %eax,%ds
  movw    %ax, %es                # -> ES: Extra Segment
  100034:	8e c0                	mov    %eax,%es
  movw    %ax, %ss                # -> SS: Stack Segment
  100036:	8e d0                	mov    %eax,%ss
  movw    $0, %ax                 # Zero segments not ready for use
  100038:	66 b8 00 00          	mov    $0x0,%ax
  movw    %ax, %fs                # -> FS
  10003c:	8e e0                	mov    %eax,%fs
  movw    %ax, %gs                # -> GS
  10003e:	8e e8                	mov    %eax,%gs

  # Set up the stack pointer and call into C.
  movl $(stack + STACK), %esp
  100040:	bc e0 88 10 00       	mov    $0x1088e0,%esp
  call main
  100045:	e8 86 28 00 00       	call   1028d0 <main>

0010004a <spin>:
spin:
  jmp spin
  10004a:	eb fe                	jmp    10004a <spin>

0010004c <gdt>:
	...
  100054:	ff                   	(bad)  
  100055:	ff 00                	incl   (%eax)
  100057:	00 00                	add    %al,(%eax)
  100059:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
  100060:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

00100064 <gdtdesc>:
  100064:	17                   	pop    %ss
  100065:	00 4c 00 10          	add    %cl,0x10(%eax,%eax,1)
  100069:	00 90 90 90 90 90    	add    %dl,-0x6f6f6f70(%eax)
  10006f:	90                   	nop

00100070 <brelse>:
}

// Release the buffer b.
void
brelse(struct buf *b)
{
  100070:	55                   	push   %ebp
  100071:	89 e5                	mov    %esp,%ebp
  100073:	53                   	push   %ebx
  100074:	83 ec 14             	sub    $0x14,%esp
  100077:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if((b->flags & B_BUSY) == 0)
  10007a:	f6 03 01             	testb  $0x1,(%ebx)
  10007d:	74 57                	je     1000d6 <brelse+0x66>
    panic("brelse");

  acquire(&bcache.lock);
  10007f:	c7 04 24 e0 88 10 00 	movl   $0x1088e0,(%esp)
  100086:	e8 c5 3a 00 00       	call   103b50 <acquire>

  b->next->prev = b->prev;
  10008b:	8b 43 10             	mov    0x10(%ebx),%eax
  10008e:	8b 53 0c             	mov    0xc(%ebx),%edx
  100091:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
  100094:	8b 43 0c             	mov    0xc(%ebx),%eax
  100097:	8b 53 10             	mov    0x10(%ebx),%edx
  10009a:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
  10009d:	a1 14 9e 10 00       	mov    0x109e14,%eax
  b->prev = &bcache.head;
  1000a2:	c7 43 0c 04 9e 10 00 	movl   $0x109e04,0xc(%ebx)

  acquire(&bcache.lock);

  b->next->prev = b->prev;
  b->prev->next = b->next;
  b->next = bcache.head.next;
  1000a9:	89 43 10             	mov    %eax,0x10(%ebx)
  b->prev = &bcache.head;
  bcache.head.next->prev = b;
  1000ac:	a1 14 9e 10 00       	mov    0x109e14,%eax
  1000b1:	89 58 0c             	mov    %ebx,0xc(%eax)
  bcache.head.next = b;
  1000b4:	89 1d 14 9e 10 00    	mov    %ebx,0x109e14

  b->flags &= ~B_BUSY;
  1000ba:	83 23 fe             	andl   $0xfffffffe,(%ebx)
  wakeup(b);
  1000bd:	89 1c 24             	mov    %ebx,(%esp)
  1000c0:	e8 8b 30 00 00       	call   103150 <wakeup>

  release(&bcache.lock);
  1000c5:	c7 45 08 e0 88 10 00 	movl   $0x1088e0,0x8(%ebp)
}
  1000cc:	83 c4 14             	add    $0x14,%esp
  1000cf:	5b                   	pop    %ebx
  1000d0:	5d                   	pop    %ebp
  bcache.head.next = b;

  b->flags &= ~B_BUSY;
  wakeup(b);

  release(&bcache.lock);
  1000d1:	e9 2a 3a 00 00       	jmp    103b00 <release>
// Release the buffer b.
void
brelse(struct buf *b)
{
  if((b->flags & B_BUSY) == 0)
    panic("brelse");
  1000d6:	c7 04 24 00 65 10 00 	movl   $0x106500,(%esp)
  1000dd:	e8 3e 08 00 00       	call   100920 <panic>
  1000e2:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  1000e9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

001000f0 <bwrite>:
}

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
  1000f0:	55                   	push   %ebp
  1000f1:	89 e5                	mov    %esp,%ebp
  1000f3:	83 ec 18             	sub    $0x18,%esp
  1000f6:	8b 45 08             	mov    0x8(%ebp),%eax
  if((b->flags & B_BUSY) == 0)
  1000f9:	8b 10                	mov    (%eax),%edx
  1000fb:	f6 c2 01             	test   $0x1,%dl
  1000fe:	74 0e                	je     10010e <bwrite+0x1e>
    panic("bwrite");
  b->flags |= B_DIRTY;
  100100:	83 ca 04             	or     $0x4,%edx
  100103:	89 10                	mov    %edx,(%eax)
  iderw(b);
  100105:	89 45 08             	mov    %eax,0x8(%ebp)
}
  100108:	c9                   	leave  
bwrite(struct buf *b)
{
  if((b->flags & B_BUSY) == 0)
    panic("bwrite");
  b->flags |= B_DIRTY;
  iderw(b);
  100109:	e9 32 1e 00 00       	jmp    101f40 <iderw>
// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
  if((b->flags & B_BUSY) == 0)
    panic("bwrite");
  10010e:	c7 04 24 07 65 10 00 	movl   $0x106507,(%esp)
  100115:	e8 06 08 00 00       	call   100920 <panic>
  10011a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

00100120 <bread>:
}

// Return a B_BUSY buf with the contents of the indicated disk sector.
struct buf*
bread(uint dev, uint sector)
{
  100120:	55                   	push   %ebp
  100121:	89 e5                	mov    %esp,%ebp
  100123:	57                   	push   %edi
  100124:	56                   	push   %esi
  100125:	53                   	push   %ebx
  100126:	83 ec 1c             	sub    $0x1c,%esp
  100129:	8b 75 08             	mov    0x8(%ebp),%esi
  10012c:	8b 7d 0c             	mov    0xc(%ebp),%edi
static struct buf*
bget(uint dev, uint sector)
{
  struct buf *b;

  acquire(&bcache.lock);
  10012f:	c7 04 24 e0 88 10 00 	movl   $0x1088e0,(%esp)
  100136:	e8 15 3a 00 00       	call   103b50 <acquire>

 loop:
  // Try for cached block.
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
  10013b:	8b 1d 14 9e 10 00    	mov    0x109e14,%ebx
  100141:	81 fb 04 9e 10 00    	cmp    $0x109e04,%ebx
  100147:	75 12                	jne    10015b <bread+0x3b>
  100149:	eb 35                	jmp    100180 <bread+0x60>
  10014b:	90                   	nop
  10014c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  100150:	8b 5b 10             	mov    0x10(%ebx),%ebx
  100153:	81 fb 04 9e 10 00    	cmp    $0x109e04,%ebx
  100159:	74 25                	je     100180 <bread+0x60>
    if(b->dev == dev && b->sector == sector){
  10015b:	3b 73 04             	cmp    0x4(%ebx),%esi
  10015e:	66 90                	xchg   %ax,%ax
  100160:	75 ee                	jne    100150 <bread+0x30>
  100162:	3b 7b 08             	cmp    0x8(%ebx),%edi
  100165:	75 e9                	jne    100150 <bread+0x30>
      if(!(b->flags & B_BUSY)){
  100167:	8b 03                	mov    (%ebx),%eax
  100169:	a8 01                	test   $0x1,%al
  10016b:	74 64                	je     1001d1 <bread+0xb1>
        b->flags |= B_BUSY;
        release(&bcache.lock);
        return b;
      }
      sleep(b, &bcache.lock);
  10016d:	c7 44 24 04 e0 88 10 	movl   $0x1088e0,0x4(%esp)
  100174:	00 
  100175:	89 1c 24             	mov    %ebx,(%esp)
  100178:	e8 f3 30 00 00       	call   103270 <sleep>
  10017d:	eb bc                	jmp    10013b <bread+0x1b>
  10017f:	90                   	nop
      goto loop;
    }
  }

  // Allocate fresh block.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
  100180:	8b 1d 10 9e 10 00    	mov    0x109e10,%ebx
  100186:	81 fb 04 9e 10 00    	cmp    $0x109e04,%ebx
  10018c:	75 0d                	jne    10019b <bread+0x7b>
  10018e:	eb 54                	jmp    1001e4 <bread+0xc4>
  100190:	8b 5b 0c             	mov    0xc(%ebx),%ebx
  100193:	81 fb 04 9e 10 00    	cmp    $0x109e04,%ebx
  100199:	74 49                	je     1001e4 <bread+0xc4>
    if((b->flags & B_BUSY) == 0){
  10019b:	f6 03 01             	testb  $0x1,(%ebx)
  10019e:	66 90                	xchg   %ax,%ax
  1001a0:	75 ee                	jne    100190 <bread+0x70>
      b->dev = dev;
  1001a2:	89 73 04             	mov    %esi,0x4(%ebx)
      b->sector = sector;
  1001a5:	89 7b 08             	mov    %edi,0x8(%ebx)
      b->flags = B_BUSY;
  1001a8:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
      release(&bcache.lock);
  1001ae:	c7 04 24 e0 88 10 00 	movl   $0x1088e0,(%esp)
  1001b5:	e8 46 39 00 00       	call   103b00 <release>
bread(uint dev, uint sector)
{
  struct buf *b;

  b = bget(dev, sector);
  if(!(b->flags & B_VALID))
  1001ba:	f6 03 02             	testb  $0x2,(%ebx)
  1001bd:	75 08                	jne    1001c7 <bread+0xa7>
    iderw(b);
  1001bf:	89 1c 24             	mov    %ebx,(%esp)
  1001c2:	e8 79 1d 00 00       	call   101f40 <iderw>
  return b;
}
  1001c7:	83 c4 1c             	add    $0x1c,%esp
  1001ca:	89 d8                	mov    %ebx,%eax
  1001cc:	5b                   	pop    %ebx
  1001cd:	5e                   	pop    %esi
  1001ce:	5f                   	pop    %edi
  1001cf:	5d                   	pop    %ebp
  1001d0:	c3                   	ret    
 loop:
  // Try for cached block.
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    if(b->dev == dev && b->sector == sector){
      if(!(b->flags & B_BUSY)){
        b->flags |= B_BUSY;
  1001d1:	83 c8 01             	or     $0x1,%eax
  1001d4:	89 03                	mov    %eax,(%ebx)
        release(&bcache.lock);
  1001d6:	c7 04 24 e0 88 10 00 	movl   $0x1088e0,(%esp)
  1001dd:	e8 1e 39 00 00       	call   103b00 <release>
  1001e2:	eb d6                	jmp    1001ba <bread+0x9a>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
  1001e4:	c7 04 24 0e 65 10 00 	movl   $0x10650e,(%esp)
  1001eb:	e8 30 07 00 00       	call   100920 <panic>

001001f0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
  1001f0:	55                   	push   %ebp
  1001f1:	89 e5                	mov    %esp,%ebp
  1001f3:	83 ec 18             	sub    $0x18,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
  1001f6:	c7 44 24 04 1f 65 10 	movl   $0x10651f,0x4(%esp)
  1001fd:	00 
  1001fe:	c7 04 24 e0 88 10 00 	movl   $0x1088e0,(%esp)
  100205:	e8 b6 37 00 00       	call   1039c0 <initlock>
  // head.next is most recently used.
  struct buf head;
} bcache;

void
binit(void)
  10020a:	ba 04 9e 10 00       	mov    $0x109e04,%edx
  10020f:	b8 14 89 10 00       	mov    $0x108914,%eax
  struct buf *b;

  initlock(&bcache.lock, "bcache");

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  100214:	c7 05 10 9e 10 00 04 	movl   $0x109e04,0x109e10
  10021b:	9e 10 00 
  bcache.head.next = &bcache.head;
  10021e:	c7 05 14 9e 10 00 04 	movl   $0x109e04,0x109e14
  100225:	9e 10 00 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    b->next = bcache.head.next;
  100228:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
  10022b:	c7 40 0c 04 9e 10 00 	movl   $0x109e04,0xc(%eax)
    b->dev = -1;
  100232:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
  100239:	8b 15 14 9e 10 00    	mov    0x109e14,%edx
  10023f:	89 42 0c             	mov    %eax,0xc(%edx)
  initlock(&bcache.lock, "bcache");

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
  100242:	89 c2                	mov    %eax,%edx
    b->next = bcache.head.next;
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  100244:	a3 14 9e 10 00       	mov    %eax,0x109e14
  initlock(&bcache.lock, "bcache");

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
  100249:	05 18 02 00 00       	add    $0x218,%eax
  10024e:	3d 04 9e 10 00       	cmp    $0x109e04,%eax
  100253:	75 d3                	jne    100228 <binit+0x38>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
  100255:	c9                   	leave  
  100256:	c3                   	ret    
  100257:	90                   	nop
  100258:	90                   	nop
  100259:	90                   	nop
  10025a:	90                   	nop
  10025b:	90                   	nop
  10025c:	90                   	nop
  10025d:	90                   	nop
  10025e:	90                   	nop
  10025f:	90                   	nop

00100260 <consoleinit>:
  return n;
}

void
consoleinit(void)
{
  100260:	55                   	push   %ebp
  100261:	89 e5                	mov    %esp,%ebp
  100263:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
  100266:	c7 44 24 04 26 65 10 	movl   $0x106526,0x4(%esp)
  10026d:	00 
  10026e:	c7 04 24 40 78 10 00 	movl   $0x107840,(%esp)
  100275:	e8 46 37 00 00       	call   1039c0 <initlock>
  initlock(&input.lock, "input");
  10027a:	c7 44 24 04 2e 65 10 	movl   $0x10652e,0x4(%esp)
  100281:	00 
  100282:	c7 04 24 20 a0 10 00 	movl   $0x10a020,(%esp)
  100289:	e8 32 37 00 00       	call   1039c0 <initlock>

  devsw[CONSOLE].write = consolewrite;
  devsw[CONSOLE].read = consoleread;
  cons.locking = 1;

  picenable(IRQ_KBD);
  10028e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
consoleinit(void)
{
  initlock(&cons.lock, "console");
  initlock(&input.lock, "input");

  devsw[CONSOLE].write = consolewrite;
  100295:	c7 05 8c aa 10 00 40 	movl   $0x100440,0x10aa8c
  10029c:	04 10 00 
  devsw[CONSOLE].read = consoleread;
  10029f:	c7 05 88 aa 10 00 90 	movl   $0x100690,0x10aa88
  1002a6:	06 10 00 
  cons.locking = 1;
  1002a9:	c7 05 74 78 10 00 01 	movl   $0x1,0x107874
  1002b0:	00 00 00 

  picenable(IRQ_KBD);
  1002b3:	e8 f8 28 00 00       	call   102bb0 <picenable>
  ioapicenable(IRQ_KBD, 0);
  1002b8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1002bf:	00 
  1002c0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1002c7:	e8 74 1e 00 00       	call   102140 <ioapicenable>
}
  1002cc:	c9                   	leave  
  1002cd:	c3                   	ret    
  1002ce:	66 90                	xchg   %ax,%ax

001002d0 <consputc>:
  crt[pos] = ' ' | 0x0700;
}

void
consputc(int c)
{
  1002d0:	55                   	push   %ebp
  1002d1:	89 e5                	mov    %esp,%ebp
  1002d3:	57                   	push   %edi
  1002d4:	56                   	push   %esi
  1002d5:	89 c6                	mov    %eax,%esi
  1002d7:	53                   	push   %ebx
  1002d8:	83 ec 1c             	sub    $0x1c,%esp
  if(panicked){
  1002db:	83 3d 20 78 10 00 00 	cmpl   $0x0,0x107820
  1002e2:	74 03                	je     1002e7 <consputc+0x17>
}

static inline void
cli(void)
{
  asm volatile("cli");
  1002e4:	fa                   	cli    
  1002e5:	eb fe                	jmp    1002e5 <consputc+0x15>
    cli();
    for(;;)
      ;
  }

  if(c == BACKSPACE){
  1002e7:	3d 00 01 00 00       	cmp    $0x100,%eax
  1002ec:	0f 84 a0 00 00 00    	je     100392 <consputc+0xc2>
    uartputc('\b'); uartputc(' '); uartputc('\b');
  } else
    uartputc(c);
  1002f2:	89 04 24             	mov    %eax,(%esp)
  1002f5:	e8 06 4e 00 00       	call   105100 <uartputc>
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  1002fa:	b9 d4 03 00 00       	mov    $0x3d4,%ecx
  1002ff:	b8 0e 00 00 00       	mov    $0xe,%eax
  100304:	89 ca                	mov    %ecx,%edx
  100306:	ee                   	out    %al,(%dx)
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  100307:	bf d5 03 00 00       	mov    $0x3d5,%edi
  10030c:	89 fa                	mov    %edi,%edx
  10030e:	ec                   	in     (%dx),%al
{
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
  pos = inb(CRTPORT+1) << 8;
  10030f:	0f b6 d8             	movzbl %al,%ebx
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  100312:	89 ca                	mov    %ecx,%edx
  100314:	c1 e3 08             	shl    $0x8,%ebx
  100317:	b8 0f 00 00 00       	mov    $0xf,%eax
  10031c:	ee                   	out    %al,(%dx)
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  10031d:	89 fa                	mov    %edi,%edx
  10031f:	ec                   	in     (%dx),%al
  outb(CRTPORT, 15);
  pos |= inb(CRTPORT+1);
  100320:	0f b6 c0             	movzbl %al,%eax
  100323:	09 c3                	or     %eax,%ebx

  if(c == '\n')
  100325:	83 fe 0a             	cmp    $0xa,%esi
  100328:	0f 84 ee 00 00 00    	je     10041c <consputc+0x14c>
    pos += 80 - pos%80;
  else if(c == BACKSPACE){
  10032e:	81 fe 00 01 00 00    	cmp    $0x100,%esi
  100334:	0f 84 cb 00 00 00    	je     100405 <consputc+0x135>
    if(pos > 0) --pos;
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
  10033a:	66 81 e6 ff 00       	and    $0xff,%si
  10033f:	66 81 ce 00 07       	or     $0x700,%si
  100344:	66 89 b4 1b 00 80 0b 	mov    %si,0xb8000(%ebx,%ebx,1)
  10034b:	00 
  10034c:	83 c3 01             	add    $0x1,%ebx
  
  if((pos/80) >= 24){  // Scroll up.
  10034f:	81 fb 7f 07 00 00    	cmp    $0x77f,%ebx
  100355:	8d 8c 1b 00 80 0b 00 	lea    0xb8000(%ebx,%ebx,1),%ecx
  10035c:	7f 5d                	jg     1003bb <consputc+0xeb>
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  10035e:	be d4 03 00 00       	mov    $0x3d4,%esi
  100363:	b8 0e 00 00 00       	mov    $0xe,%eax
  100368:	89 f2                	mov    %esi,%edx
  10036a:	ee                   	out    %al,(%dx)
  10036b:	bf d5 03 00 00       	mov    $0x3d5,%edi
  100370:	89 d8                	mov    %ebx,%eax
  100372:	c1 f8 08             	sar    $0x8,%eax
  100375:	89 fa                	mov    %edi,%edx
  100377:	ee                   	out    %al,(%dx)
  100378:	b8 0f 00 00 00       	mov    $0xf,%eax
  10037d:	89 f2                	mov    %esi,%edx
  10037f:	ee                   	out    %al,(%dx)
  100380:	89 d8                	mov    %ebx,%eax
  100382:	89 fa                	mov    %edi,%edx
  100384:	ee                   	out    %al,(%dx)
  
  outb(CRTPORT, 14);
  outb(CRTPORT+1, pos>>8);
  outb(CRTPORT, 15);
  outb(CRTPORT+1, pos);
  crt[pos] = ' ' | 0x0700;
  100385:	66 c7 01 20 07       	movw   $0x720,(%ecx)
  if(c == BACKSPACE){
    uartputc('\b'); uartputc(' '); uartputc('\b');
  } else
    uartputc(c);
  cgaputc(c);
}
  10038a:	83 c4 1c             	add    $0x1c,%esp
  10038d:	5b                   	pop    %ebx
  10038e:	5e                   	pop    %esi
  10038f:	5f                   	pop    %edi
  100390:	5d                   	pop    %ebp
  100391:	c3                   	ret    
    for(;;)
      ;
  }

  if(c == BACKSPACE){
    uartputc('\b'); uartputc(' '); uartputc('\b');
  100392:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  100399:	e8 62 4d 00 00       	call   105100 <uartputc>
  10039e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1003a5:	e8 56 4d 00 00       	call   105100 <uartputc>
  1003aa:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  1003b1:	e8 4a 4d 00 00       	call   105100 <uartputc>
  1003b6:	e9 3f ff ff ff       	jmp    1002fa <consputc+0x2a>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
  
  if((pos/80) >= 24){  // Scroll up.
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
    pos -= 80;
  1003bb:	83 eb 50             	sub    $0x50,%ebx
    if(pos > 0) --pos;
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
  
  if((pos/80) >= 24){  // Scroll up.
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
  1003be:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
  1003c5:	00 
    pos -= 80;
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
  1003c6:	8d b4 1b 00 80 0b 00 	lea    0xb8000(%ebx,%ebx,1),%esi
    if(pos > 0) --pos;
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
  
  if((pos/80) >= 24){  // Scroll up.
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
  1003cd:	c7 44 24 04 a0 80 0b 	movl   $0xb80a0,0x4(%esp)
  1003d4:	00 
  1003d5:	c7 04 24 00 80 0b 00 	movl   $0xb8000,(%esp)
  1003dc:	e8 8f 38 00 00       	call   103c70 <memmove>
    pos -= 80;
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
  1003e1:	b8 80 07 00 00       	mov    $0x780,%eax
  1003e6:	29 d8                	sub    %ebx,%eax
  1003e8:	01 c0                	add    %eax,%eax
  1003ea:	89 44 24 08          	mov    %eax,0x8(%esp)
  1003ee:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1003f5:	00 
  1003f6:	89 34 24             	mov    %esi,(%esp)
  1003f9:	e8 f2 37 00 00       	call   103bf0 <memset>
  outb(CRTPORT+1, pos);
  crt[pos] = ' ' | 0x0700;
}

void
consputc(int c)
  1003fe:	89 f1                	mov    %esi,%ecx
  100400:	e9 59 ff ff ff       	jmp    10035e <consputc+0x8e>
  pos |= inb(CRTPORT+1);

  if(c == '\n')
    pos += 80 - pos%80;
  else if(c == BACKSPACE){
    if(pos > 0) --pos;
  100405:	85 db                	test   %ebx,%ebx
  100407:	8d 8c 1b 00 80 0b 00 	lea    0xb8000(%ebx,%ebx,1),%ecx
  10040e:	0f 8e 4a ff ff ff    	jle    10035e <consputc+0x8e>
  100414:	83 eb 01             	sub    $0x1,%ebx
  100417:	e9 33 ff ff ff       	jmp    10034f <consputc+0x7f>
  pos = inb(CRTPORT+1) << 8;
  outb(CRTPORT, 15);
  pos |= inb(CRTPORT+1);

  if(c == '\n')
    pos += 80 - pos%80;
  10041c:	89 da                	mov    %ebx,%edx
  10041e:	89 d8                	mov    %ebx,%eax
  100420:	b9 50 00 00 00       	mov    $0x50,%ecx
  100425:	83 c3 50             	add    $0x50,%ebx
  100428:	c1 fa 1f             	sar    $0x1f,%edx
  10042b:	f7 f9                	idiv   %ecx
  10042d:	29 d3                	sub    %edx,%ebx
  10042f:	e9 1b ff ff ff       	jmp    10034f <consputc+0x7f>
  100434:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  10043a:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

00100440 <consolewrite>:
  return target - n;
}

int
consolewrite(struct inode *ip, char *buf, int n)
{
  100440:	55                   	push   %ebp
  100441:	89 e5                	mov    %esp,%ebp
  100443:	57                   	push   %edi
  100444:	56                   	push   %esi
  100445:	53                   	push   %ebx
  100446:	83 ec 1c             	sub    $0x1c,%esp
  int i;

  iunlock(ip);
  100449:	8b 45 08             	mov    0x8(%ebp),%eax
  return target - n;
}

int
consolewrite(struct inode *ip, char *buf, int n)
{
  10044c:	8b 75 10             	mov    0x10(%ebp),%esi
  10044f:	8b 7d 0c             	mov    0xc(%ebp),%edi
  int i;

  iunlock(ip);
  100452:	89 04 24             	mov    %eax,(%esp)
  100455:	e8 16 13 00 00       	call   101770 <iunlock>
  acquire(&cons.lock);
  10045a:	c7 04 24 40 78 10 00 	movl   $0x107840,(%esp)
  100461:	e8 ea 36 00 00       	call   103b50 <acquire>
  for(i = 0; i < n; i++)
  100466:	85 f6                	test   %esi,%esi
  100468:	7e 16                	jle    100480 <consolewrite+0x40>
  10046a:	31 db                	xor    %ebx,%ebx
  10046c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    consputc(buf[i] & 0xff);
  100470:	0f b6 04 1f          	movzbl (%edi,%ebx,1),%eax
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
  100474:	83 c3 01             	add    $0x1,%ebx
    consputc(buf[i] & 0xff);
  100477:	e8 54 fe ff ff       	call   1002d0 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
  10047c:	39 de                	cmp    %ebx,%esi
  10047e:	7f f0                	jg     100470 <consolewrite+0x30>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
  100480:	c7 04 24 40 78 10 00 	movl   $0x107840,(%esp)
  100487:	e8 74 36 00 00       	call   103b00 <release>
  ilock(ip);
  10048c:	8b 45 08             	mov    0x8(%ebp),%eax
  10048f:	89 04 24             	mov    %eax,(%esp)
  100492:	e8 19 17 00 00       	call   101bb0 <ilock>

  return n;
}
  100497:	83 c4 1c             	add    $0x1c,%esp
  10049a:	89 f0                	mov    %esi,%eax
  10049c:	5b                   	pop    %ebx
  10049d:	5e                   	pop    %esi
  10049e:	5f                   	pop    %edi
  10049f:	5d                   	pop    %ebp
  1004a0:	c3                   	ret    
  1004a1:	eb 0d                	jmp    1004b0 <printint>
  1004a3:	90                   	nop
  1004a4:	90                   	nop
  1004a5:	90                   	nop
  1004a6:	90                   	nop
  1004a7:	90                   	nop
  1004a8:	90                   	nop
  1004a9:	90                   	nop
  1004aa:	90                   	nop
  1004ab:	90                   	nop
  1004ac:	90                   	nop
  1004ad:	90                   	nop
  1004ae:	90                   	nop
  1004af:	90                   	nop

001004b0 <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
  1004b0:	55                   	push   %ebp
  1004b1:	89 e5                	mov    %esp,%ebp
  1004b3:	57                   	push   %edi
  1004b4:	56                   	push   %esi
  1004b5:	89 d6                	mov    %edx,%esi
  1004b7:	53                   	push   %ebx
  1004b8:	83 ec 1c             	sub    $0x1c,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
  1004bb:	85 c9                	test   %ecx,%ecx
  1004bd:	74 04                	je     1004c3 <printint+0x13>
  1004bf:	85 c0                	test   %eax,%eax
  1004c1:	78 55                	js     100518 <printint+0x68>
    x = -xx;
  else
    x = xx;
  1004c3:	31 ff                	xor    %edi,%edi
  1004c5:	31 c9                	xor    %ecx,%ecx
  1004c7:	8d 5d d8             	lea    -0x28(%ebp),%ebx
  1004ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

  i = 0;
  do{
    buf[i++] = digits[x % base];
  1004d0:	31 d2                	xor    %edx,%edx
  1004d2:	f7 f6                	div    %esi
  1004d4:	0f b6 92 4e 65 10 00 	movzbl 0x10654e(%edx),%edx
  1004db:	88 14 0b             	mov    %dl,(%ebx,%ecx,1)
  1004de:	83 c1 01             	add    $0x1,%ecx
  }while((x /= base) != 0);
  1004e1:	85 c0                	test   %eax,%eax
  1004e3:	75 eb                	jne    1004d0 <printint+0x20>

  if(sign)
  1004e5:	85 ff                	test   %edi,%edi
  1004e7:	74 08                	je     1004f1 <printint+0x41>
    buf[i++] = '-';
  1004e9:	c6 44 0d d8 2d       	movb   $0x2d,-0x28(%ebp,%ecx,1)
  1004ee:	83 c1 01             	add    $0x1,%ecx

  while(--i >= 0)
  1004f1:	8d 71 ff             	lea    -0x1(%ecx),%esi
  1004f4:	01 f3                	add    %esi,%ebx
  1004f6:	66 90                	xchg   %ax,%ax
    consputc(buf[i]);
  1004f8:	0f be 03             	movsbl (%ebx),%eax
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
  1004fb:	83 ee 01             	sub    $0x1,%esi
  1004fe:	83 eb 01             	sub    $0x1,%ebx
    consputc(buf[i]);
  100501:	e8 ca fd ff ff       	call   1002d0 <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
  100506:	83 fe ff             	cmp    $0xffffffff,%esi
  100509:	75 ed                	jne    1004f8 <printint+0x48>
    consputc(buf[i]);
}
  10050b:	83 c4 1c             	add    $0x1c,%esp
  10050e:	5b                   	pop    %ebx
  10050f:	5e                   	pop    %esi
  100510:	5f                   	pop    %edi
  100511:	5d                   	pop    %ebp
  100512:	c3                   	ret    
  100513:	90                   	nop
  100514:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    x = -xx;
  100518:	f7 d8                	neg    %eax
  10051a:	bf 01 00 00 00       	mov    $0x1,%edi
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
  10051f:	eb a4                	jmp    1004c5 <printint+0x15>
  100521:	eb 0d                	jmp    100530 <cprintf>
  100523:	90                   	nop
  100524:	90                   	nop
  100525:	90                   	nop
  100526:	90                   	nop
  100527:	90                   	nop
  100528:	90                   	nop
  100529:	90                   	nop
  10052a:	90                   	nop
  10052b:	90                   	nop
  10052c:	90                   	nop
  10052d:	90                   	nop
  10052e:	90                   	nop
  10052f:	90                   	nop

00100530 <cprintf>:
}

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
  100530:	55                   	push   %ebp
  100531:	89 e5                	mov    %esp,%ebp
  100533:	57                   	push   %edi
  100534:	56                   	push   %esi
  100535:	53                   	push   %ebx
  100536:	83 ec 2c             	sub    $0x2c,%esp
  int i, c, state, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
  100539:	8b 3d 74 78 10 00    	mov    0x107874,%edi
  if(locking)
  10053f:	85 ff                	test   %edi,%edi
  100541:	0f 85 29 01 00 00    	jne    100670 <cprintf+0x140>
    acquire(&cons.lock);

  argp = (uint*)(void*)(&fmt + 1);
  state = 0;
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
  100547:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10054a:	0f b6 01             	movzbl (%ecx),%eax
  10054d:	85 c0                	test   %eax,%eax
  10054f:	0f 84 93 00 00 00    	je     1005e8 <cprintf+0xb8>

  locking = cons.locking;
  if(locking)
    acquire(&cons.lock);

  argp = (uint*)(void*)(&fmt + 1);
  100555:	8d 75 0c             	lea    0xc(%ebp),%esi
  100558:	31 db                	xor    %ebx,%ebx
  10055a:	eb 3f                	jmp    10059b <cprintf+0x6b>
  10055c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
  100560:	83 fa 25             	cmp    $0x25,%edx
  100563:	0f 84 b7 00 00 00    	je     100620 <cprintf+0xf0>
  100569:	83 fa 64             	cmp    $0x64,%edx
  10056c:	0f 84 8e 00 00 00    	je     100600 <cprintf+0xd0>
    case '%':
      consputc('%');
      break;
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
  100572:	b8 25 00 00 00       	mov    $0x25,%eax
  100577:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  10057a:	e8 51 fd ff ff       	call   1002d0 <consputc>
      consputc(c);
  10057f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100582:	89 d0                	mov    %edx,%eax
  100584:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  100588:	e8 43 fd ff ff       	call   1002d0 <consputc>
  10058d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  if(locking)
    acquire(&cons.lock);

  argp = (uint*)(void*)(&fmt + 1);
  state = 0;
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
  100590:	83 c3 01             	add    $0x1,%ebx
  100593:	0f b6 04 19          	movzbl (%ecx,%ebx,1),%eax
  100597:	85 c0                	test   %eax,%eax
  100599:	74 4d                	je     1005e8 <cprintf+0xb8>
    if(c != '%'){
  10059b:	83 f8 25             	cmp    $0x25,%eax
  10059e:	75 e8                	jne    100588 <cprintf+0x58>
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
  1005a0:	83 c3 01             	add    $0x1,%ebx
  1005a3:	0f b6 14 19          	movzbl (%ecx,%ebx,1),%edx
    if(c == 0)
  1005a7:	85 d2                	test   %edx,%edx
  1005a9:	74 3d                	je     1005e8 <cprintf+0xb8>
      break;
    switch(c){
  1005ab:	83 fa 70             	cmp    $0x70,%edx
  1005ae:	74 12                	je     1005c2 <cprintf+0x92>
  1005b0:	7e ae                	jle    100560 <cprintf+0x30>
  1005b2:	83 fa 73             	cmp    $0x73,%edx
  1005b5:	8d 76 00             	lea    0x0(%esi),%esi
  1005b8:	74 7e                	je     100638 <cprintf+0x108>
  1005ba:	83 fa 78             	cmp    $0x78,%edx
  1005bd:	8d 76 00             	lea    0x0(%esi),%esi
  1005c0:	75 b0                	jne    100572 <cprintf+0x42>
    case 'd':
      printint(*argp++, 10, 1);
      break;
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
  1005c2:	8b 06                	mov    (%esi),%eax
  1005c4:	31 c9                	xor    %ecx,%ecx
  1005c6:	ba 10 00 00 00       	mov    $0x10,%edx
  if(locking)
    acquire(&cons.lock);

  argp = (uint*)(void*)(&fmt + 1);
  state = 0;
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
  1005cb:	83 c3 01             	add    $0x1,%ebx
    case 'd':
      printint(*argp++, 10, 1);
      break;
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
  1005ce:	83 c6 04             	add    $0x4,%esi
  1005d1:	e8 da fe ff ff       	call   1004b0 <printint>
  1005d6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  if(locking)
    acquire(&cons.lock);

  argp = (uint*)(void*)(&fmt + 1);
  state = 0;
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
  1005d9:	0f b6 04 19          	movzbl (%ecx,%ebx,1),%eax
  1005dd:	85 c0                	test   %eax,%eax
  1005df:	75 ba                	jne    10059b <cprintf+0x6b>
  1005e1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
      consputc(c);
      break;
    }
  }

  if(locking)
  1005e8:	85 ff                	test   %edi,%edi
  1005ea:	74 0c                	je     1005f8 <cprintf+0xc8>
    release(&cons.lock);
  1005ec:	c7 04 24 40 78 10 00 	movl   $0x107840,(%esp)
  1005f3:	e8 08 35 00 00       	call   103b00 <release>
}
  1005f8:	83 c4 2c             	add    $0x2c,%esp
  1005fb:	5b                   	pop    %ebx
  1005fc:	5e                   	pop    %esi
  1005fd:	5f                   	pop    %edi
  1005fe:	5d                   	pop    %ebp
  1005ff:	c3                   	ret    
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    case 'd':
      printint(*argp++, 10, 1);
  100600:	8b 06                	mov    (%esi),%eax
  100602:	b9 01 00 00 00       	mov    $0x1,%ecx
  100607:	ba 0a 00 00 00       	mov    $0xa,%edx
  10060c:	83 c6 04             	add    $0x4,%esi
  10060f:	e8 9c fe ff ff       	call   1004b0 <printint>
  100614:	8b 4d 08             	mov    0x8(%ebp),%ecx
      break;
  100617:	e9 74 ff ff ff       	jmp    100590 <cprintf+0x60>
  10061c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
      break;
    case '%':
      consputc('%');
  100620:	b8 25 00 00 00       	mov    $0x25,%eax
  100625:	e8 a6 fc ff ff       	call   1002d0 <consputc>
  10062a:	8b 4d 08             	mov    0x8(%ebp),%ecx
      break;
  10062d:	e9 5e ff ff ff       	jmp    100590 <cprintf+0x60>
  100632:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
  100638:	8b 16                	mov    (%esi),%edx
  10063a:	83 c6 04             	add    $0x4,%esi
  10063d:	85 d2                	test   %edx,%edx
  10063f:	74 47                	je     100688 <cprintf+0x158>
        s = "(null)";
      for(; *s; s++)
  100641:	0f b6 02             	movzbl (%edx),%eax
  100644:	84 c0                	test   %al,%al
  100646:	0f 84 44 ff ff ff    	je     100590 <cprintf+0x60>
  10064c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
        consputc(*s);
  100650:	0f be c0             	movsbl %al,%eax
  100653:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  100656:	e8 75 fc ff ff       	call   1002d0 <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
  10065b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  10065e:	83 c2 01             	add    $0x1,%edx
  100661:	0f b6 02             	movzbl (%edx),%eax
  100664:	84 c0                	test   %al,%al
  100666:	75 e8                	jne    100650 <cprintf+0x120>
  100668:	e9 20 ff ff ff       	jmp    10058d <cprintf+0x5d>
  10066d:	8d 76 00             	lea    0x0(%esi),%esi
  uint *argp;
  char *s;

  locking = cons.locking;
  if(locking)
    acquire(&cons.lock);
  100670:	c7 04 24 40 78 10 00 	movl   $0x107840,(%esp)
  100677:	e8 d4 34 00 00       	call   103b50 <acquire>
  10067c:	e9 c6 fe ff ff       	jmp    100547 <cprintf+0x17>
  100681:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
  100688:	ba 34 65 10 00       	mov    $0x106534,%edx
  10068d:	eb b2                	jmp    100641 <cprintf+0x111>
  10068f:	90                   	nop

00100690 <consoleread>:
  release(&input.lock);
}

int
consoleread(struct inode *ip, char *dst, int n)
{
  100690:	55                   	push   %ebp
  100691:	89 e5                	mov    %esp,%ebp
  100693:	57                   	push   %edi
  100694:	56                   	push   %esi
  100695:	53                   	push   %ebx
  100696:	83 ec 3c             	sub    $0x3c,%esp
  100699:	8b 5d 10             	mov    0x10(%ebp),%ebx
  10069c:	8b 7d 08             	mov    0x8(%ebp),%edi
  10069f:	8b 75 0c             	mov    0xc(%ebp),%esi
  uint target;
  int c;

  iunlock(ip);
  1006a2:	89 3c 24             	mov    %edi,(%esp)
  1006a5:	e8 c6 10 00 00       	call   101770 <iunlock>
  target = n;
  1006aa:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  acquire(&input.lock);
  1006ad:	c7 04 24 20 a0 10 00 	movl   $0x10a020,(%esp)
  1006b4:	e8 97 34 00 00       	call   103b50 <acquire>
  while(n > 0){
  1006b9:	85 db                	test   %ebx,%ebx
  1006bb:	7f 2c                	jg     1006e9 <consoleread+0x59>
  1006bd:	e9 c0 00 00 00       	jmp    100782 <consoleread+0xf2>
  1006c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    while(input.r == input.w){
      if(proc->killed){
  1006c8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1006ce:	8b 40 24             	mov    0x24(%eax),%eax
  1006d1:	85 c0                	test   %eax,%eax
  1006d3:	75 5b                	jne    100730 <consoleread+0xa0>
        release(&input.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
  1006d5:	c7 44 24 04 20 a0 10 	movl   $0x10a020,0x4(%esp)
  1006dc:	00 
  1006dd:	c7 04 24 d4 a0 10 00 	movl   $0x10a0d4,(%esp)
  1006e4:	e8 87 2b 00 00       	call   103270 <sleep>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
  1006e9:	a1 d4 a0 10 00       	mov    0x10a0d4,%eax
  1006ee:	3b 05 d8 a0 10 00    	cmp    0x10a0d8,%eax
  1006f4:	74 d2                	je     1006c8 <consoleread+0x38>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
  1006f6:	89 c2                	mov    %eax,%edx
  1006f8:	83 e2 7f             	and    $0x7f,%edx
  1006fb:	0f b6 8a 54 a0 10 00 	movzbl 0x10a054(%edx),%ecx
  100702:	0f be d1             	movsbl %cl,%edx
  100705:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  100708:	8d 50 01             	lea    0x1(%eax),%edx
    if(c == C('D')){  // EOF
  10070b:	83 7d d4 04          	cmpl   $0x4,-0x2c(%ebp)
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
  10070f:	89 15 d4 a0 10 00    	mov    %edx,0x10a0d4
    if(c == C('D')){  // EOF
  100715:	74 3a                	je     100751 <consoleread+0xc1>
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
    }
    *dst++ = c;
  100717:	88 0e                	mov    %cl,(%esi)
    --n;
  100719:	83 eb 01             	sub    $0x1,%ebx
    if(c == '\n')
  10071c:	83 7d d4 0a          	cmpl   $0xa,-0x2c(%ebp)
  100720:	74 39                	je     10075b <consoleread+0xcb>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
  100722:	85 db                	test   %ebx,%ebx
  100724:	7e 35                	jle    10075b <consoleread+0xcb>
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
    }
    *dst++ = c;
  100726:	83 c6 01             	add    $0x1,%esi
  100729:	eb be                	jmp    1006e9 <consoleread+0x59>
  10072b:	90                   	nop
  10072c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
      if(proc->killed){
        release(&input.lock);
  100730:	c7 04 24 20 a0 10 00 	movl   $0x10a020,(%esp)
  100737:	e8 c4 33 00 00       	call   103b00 <release>
        ilock(ip);
  10073c:	89 3c 24             	mov    %edi,(%esp)
  10073f:	e8 6c 14 00 00       	call   101bb0 <ilock>
  }
  release(&input.lock);
  ilock(ip);

  return target - n;
}
  100744:	83 c4 3c             	add    $0x3c,%esp
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
      if(proc->killed){
        release(&input.lock);
        ilock(ip);
  100747:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  release(&input.lock);
  ilock(ip);

  return target - n;
}
  10074c:	5b                   	pop    %ebx
  10074d:	5e                   	pop    %esi
  10074e:	5f                   	pop    %edi
  10074f:	5d                   	pop    %ebp
  100750:	c3                   	ret    
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
    if(c == C('D')){  // EOF
      if(n < target){
  100751:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
  100754:	76 05                	jbe    10075b <consoleread+0xcb>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
  100756:	a3 d4 a0 10 00       	mov    %eax,0x10a0d4
  10075b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10075e:	29 d8                	sub    %ebx,%eax
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
  }
  release(&input.lock);
  100760:	c7 04 24 20 a0 10 00 	movl   $0x10a020,(%esp)
  100767:	89 45 e0             	mov    %eax,-0x20(%ebp)
  10076a:	e8 91 33 00 00       	call   103b00 <release>
  ilock(ip);
  10076f:	89 3c 24             	mov    %edi,(%esp)
  100772:	e8 39 14 00 00       	call   101bb0 <ilock>
  100777:	8b 45 e0             	mov    -0x20(%ebp),%eax

  return target - n;
}
  10077a:	83 c4 3c             	add    $0x3c,%esp
  10077d:	5b                   	pop    %ebx
  10077e:	5e                   	pop    %esi
  10077f:	5f                   	pop    %edi
  100780:	5d                   	pop    %ebp
  100781:	c3                   	ret    
  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
      if(proc->killed){
  100782:	31 c0                	xor    %eax,%eax
  100784:	eb da                	jmp    100760 <consoleread+0xd0>
  100786:	8d 76 00             	lea    0x0(%esi),%esi
  100789:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00100790 <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
  100790:	55                   	push   %ebp
  100791:	89 e5                	mov    %esp,%ebp
  100793:	57                   	push   %edi
      }
      break;
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
        c = (c == '\r') ? '\n' : c;
        input.buf[input.e++ % INPUT_BUF] = c;
  100794:	bf 50 a0 10 00       	mov    $0x10a050,%edi

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
  100799:	56                   	push   %esi
  10079a:	53                   	push   %ebx
  10079b:	83 ec 1c             	sub    $0x1c,%esp
  10079e:	8b 75 08             	mov    0x8(%ebp),%esi
  int c;

  acquire(&input.lock);
  1007a1:	c7 04 24 20 a0 10 00 	movl   $0x10a020,(%esp)
  1007a8:	e8 a3 33 00 00       	call   103b50 <acquire>
  1007ad:	8d 76 00             	lea    0x0(%esi),%esi
  while((c = getc()) >= 0){
  1007b0:	ff d6                	call   *%esi
  1007b2:	85 c0                	test   %eax,%eax
  1007b4:	89 c3                	mov    %eax,%ebx
  1007b6:	0f 88 9c 00 00 00    	js     100858 <consoleintr+0xc8>
    switch(c){
  1007bc:	83 fb 10             	cmp    $0x10,%ebx
  1007bf:	90                   	nop
  1007c0:	0f 84 1a 01 00 00    	je     1008e0 <consoleintr+0x150>
  1007c6:	0f 8f a4 00 00 00    	jg     100870 <consoleintr+0xe0>
  1007cc:	83 fb 08             	cmp    $0x8,%ebx
  1007cf:	90                   	nop
  1007d0:	0f 84 a8 00 00 00    	je     10087e <consoleintr+0xee>
        input.e--;
        consputc(BACKSPACE);
      }
      break;
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
  1007d6:	85 db                	test   %ebx,%ebx
  1007d8:	74 d6                	je     1007b0 <consoleintr+0x20>
  1007da:	a1 dc a0 10 00       	mov    0x10a0dc,%eax
  1007df:	89 c2                	mov    %eax,%edx
  1007e1:	2b 15 d4 a0 10 00    	sub    0x10a0d4,%edx
  1007e7:	83 fa 7f             	cmp    $0x7f,%edx
  1007ea:	77 c4                	ja     1007b0 <consoleintr+0x20>
        c = (c == '\r') ? '\n' : c;
  1007ec:	83 fb 0d             	cmp    $0xd,%ebx
  1007ef:	0f 84 f8 00 00 00    	je     1008ed <consoleintr+0x15d>
        input.buf[input.e++ % INPUT_BUF] = c;
  1007f5:	89 c2                	mov    %eax,%edx
  1007f7:	83 c0 01             	add    $0x1,%eax
  1007fa:	83 e2 7f             	and    $0x7f,%edx
  1007fd:	88 5c 17 04          	mov    %bl,0x4(%edi,%edx,1)
  100801:	a3 dc a0 10 00       	mov    %eax,0x10a0dc
        consputc(c);
  100806:	89 d8                	mov    %ebx,%eax
  100808:	e8 c3 fa ff ff       	call   1002d0 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
  10080d:	83 fb 04             	cmp    $0x4,%ebx
  100810:	0f 84 f3 00 00 00    	je     100909 <consoleintr+0x179>
  100816:	83 fb 0a             	cmp    $0xa,%ebx
  100819:	0f 84 ea 00 00 00    	je     100909 <consoleintr+0x179>
  10081f:	8b 15 d4 a0 10 00    	mov    0x10a0d4,%edx
  100825:	a1 dc a0 10 00       	mov    0x10a0dc,%eax
  10082a:	83 ea 80             	sub    $0xffffff80,%edx
  10082d:	39 d0                	cmp    %edx,%eax
  10082f:	0f 85 7b ff ff ff    	jne    1007b0 <consoleintr+0x20>
          input.w = input.e;
  100835:	a3 d8 a0 10 00       	mov    %eax,0x10a0d8
          wakeup(&input.r);
  10083a:	c7 04 24 d4 a0 10 00 	movl   $0x10a0d4,(%esp)
  100841:	e8 0a 29 00 00       	call   103150 <wakeup>
consoleintr(int (*getc)(void))
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
  100846:	ff d6                	call   *%esi
  100848:	85 c0                	test   %eax,%eax
  10084a:	89 c3                	mov    %eax,%ebx
  10084c:	0f 89 6a ff ff ff    	jns    1007bc <consoleintr+0x2c>
  100852:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
        }
      }
      break;
    }
  }
  release(&input.lock);
  100858:	c7 45 08 20 a0 10 00 	movl   $0x10a020,0x8(%ebp)
}
  10085f:	83 c4 1c             	add    $0x1c,%esp
  100862:	5b                   	pop    %ebx
  100863:	5e                   	pop    %esi
  100864:	5f                   	pop    %edi
  100865:	5d                   	pop    %ebp
        }
      }
      break;
    }
  }
  release(&input.lock);
  100866:	e9 95 32 00 00       	jmp    103b00 <release>
  10086b:	90                   	nop
  10086c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
    switch(c){
  100870:	83 fb 15             	cmp    $0x15,%ebx
  100873:	74 57                	je     1008cc <consoleintr+0x13c>
  100875:	83 fb 7f             	cmp    $0x7f,%ebx
  100878:	0f 85 58 ff ff ff    	jne    1007d6 <consoleintr+0x46>
        input.e--;
        consputc(BACKSPACE);
      }
      break;
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
  10087e:	a1 dc a0 10 00       	mov    0x10a0dc,%eax
  100883:	3b 05 d8 a0 10 00    	cmp    0x10a0d8,%eax
  100889:	0f 84 21 ff ff ff    	je     1007b0 <consoleintr+0x20>
        input.e--;
  10088f:	83 e8 01             	sub    $0x1,%eax
  100892:	a3 dc a0 10 00       	mov    %eax,0x10a0dc
        consputc(BACKSPACE);
  100897:	b8 00 01 00 00       	mov    $0x100,%eax
  10089c:	e8 2f fa ff ff       	call   1002d0 <consputc>
  1008a1:	e9 0a ff ff ff       	jmp    1007b0 <consoleintr+0x20>
  1008a6:	66 90                	xchg   %ax,%ax
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
  1008a8:	83 e8 01             	sub    $0x1,%eax
  1008ab:	89 c2                	mov    %eax,%edx
  1008ad:	83 e2 7f             	and    $0x7f,%edx
  1008b0:	80 ba 54 a0 10 00 0a 	cmpb   $0xa,0x10a054(%edx)
  1008b7:	0f 84 f3 fe ff ff    	je     1007b0 <consoleintr+0x20>
        input.e--;
  1008bd:	a3 dc a0 10 00       	mov    %eax,0x10a0dc
        consputc(BACKSPACE);
  1008c2:	b8 00 01 00 00       	mov    $0x100,%eax
  1008c7:	e8 04 fa ff ff       	call   1002d0 <consputc>
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
  1008cc:	a1 dc a0 10 00       	mov    0x10a0dc,%eax
  1008d1:	3b 05 d8 a0 10 00    	cmp    0x10a0d8,%eax
  1008d7:	75 cf                	jne    1008a8 <consoleintr+0x118>
  1008d9:	e9 d2 fe ff ff       	jmp    1007b0 <consoleintr+0x20>
  1008de:	66 90                	xchg   %ax,%ax

  acquire(&input.lock);
  while((c = getc()) >= 0){
    switch(c){
    case C('P'):  // Process listing.
      procdump();
  1008e0:	e8 0b 27 00 00       	call   102ff0 <procdump>
  1008e5:	8d 76 00             	lea    0x0(%esi),%esi
      break;
  1008e8:	e9 c3 fe ff ff       	jmp    1007b0 <consoleintr+0x20>
      }
      break;
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
        c = (c == '\r') ? '\n' : c;
        input.buf[input.e++ % INPUT_BUF] = c;
  1008ed:	89 c2                	mov    %eax,%edx
  1008ef:	83 c0 01             	add    $0x1,%eax
  1008f2:	83 e2 7f             	and    $0x7f,%edx
  1008f5:	c6 44 17 04 0a       	movb   $0xa,0x4(%edi,%edx,1)
  1008fa:	a3 dc a0 10 00       	mov    %eax,0x10a0dc
        consputc(c);
  1008ff:	b8 0a 00 00 00       	mov    $0xa,%eax
  100904:	e8 c7 f9 ff ff       	call   1002d0 <consputc>
  100909:	a1 dc a0 10 00       	mov    0x10a0dc,%eax
  10090e:	e9 22 ff ff ff       	jmp    100835 <consoleintr+0xa5>
  100913:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  100919:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00100920 <panic>:
    release(&cons.lock);
}

void
panic(char *s)
{
  100920:	55                   	push   %ebp
  100921:	89 e5                	mov    %esp,%ebp
  100923:	56                   	push   %esi
  100924:	53                   	push   %ebx
  100925:	83 ec 40             	sub    $0x40,%esp
}

static inline void
cli(void)
{
  asm volatile("cli");
  100928:	fa                   	cli    
  int i;
  uint pcs[10];
  
  cli();
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  100929:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  10092f:	8d 75 d0             	lea    -0x30(%ebp),%esi
  100932:	31 db                	xor    %ebx,%ebx
{
  int i;
  uint pcs[10];
  
  cli();
  cons.locking = 0;
  100934:	c7 05 74 78 10 00 00 	movl   $0x0,0x107874
  10093b:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
  10093e:	0f b6 00             	movzbl (%eax),%eax
  100941:	c7 04 24 3b 65 10 00 	movl   $0x10653b,(%esp)
  100948:	89 44 24 04          	mov    %eax,0x4(%esp)
  10094c:	e8 df fb ff ff       	call   100530 <cprintf>
  cprintf(s);
  100951:	8b 45 08             	mov    0x8(%ebp),%eax
  100954:	89 04 24             	mov    %eax,(%esp)
  100957:	e8 d4 fb ff ff       	call   100530 <cprintf>
  cprintf("\n");
  10095c:	c7 04 24 56 69 10 00 	movl   $0x106956,(%esp)
  100963:	e8 c8 fb ff ff       	call   100530 <cprintf>
  getcallerpcs(&s, pcs);
  100968:	8d 45 08             	lea    0x8(%ebp),%eax
  10096b:	89 74 24 04          	mov    %esi,0x4(%esp)
  10096f:	89 04 24             	mov    %eax,(%esp)
  100972:	e8 69 30 00 00       	call   1039e0 <getcallerpcs>
  100977:	90                   	nop
  for(i=0; i<10; i++)
    cprintf(" %p", pcs[i]);
  100978:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
  10097b:	83 c3 01             	add    $0x1,%ebx
    cprintf(" %p", pcs[i]);
  10097e:	c7 04 24 4a 65 10 00 	movl   $0x10654a,(%esp)
  100985:	89 44 24 04          	mov    %eax,0x4(%esp)
  100989:	e8 a2 fb ff ff       	call   100530 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
  10098e:	83 fb 0a             	cmp    $0xa,%ebx
  100991:	75 e5                	jne    100978 <panic+0x58>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
  100993:	c7 05 20 78 10 00 01 	movl   $0x1,0x107820
  10099a:	00 00 00 
  10099d:	eb fe                	jmp    10099d <panic+0x7d>
  10099f:	90                   	nop

001009a0 <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
  1009a0:	55                   	push   %ebp
  1009a1:	89 e5                	mov    %esp,%ebp
  1009a3:	57                   	push   %edi
  1009a4:	56                   	push   %esi
  1009a5:	53                   	push   %ebx
  1009a6:	81 ec 2c 01 00 00    	sub    $0x12c,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  if((ip = namei(path)) == 0)
  1009ac:	8b 45 08             	mov    0x8(%ebp),%eax
  1009af:	89 04 24             	mov    %eax,(%esp)
  1009b2:	e8 99 14 00 00       	call   101e50 <namei>
  1009b7:	85 c0                	test   %eax,%eax
  1009b9:	89 c7                	mov    %eax,%edi
  1009bb:	0f 84 25 01 00 00    	je     100ae6 <exec+0x146>
    return -1;
  ilock(ip);
  1009c1:	89 04 24             	mov    %eax,(%esp)
  1009c4:	e8 e7 11 00 00       	call   101bb0 <ilock>
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
  1009c9:	8d 45 94             	lea    -0x6c(%ebp),%eax
  1009cc:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
  1009d3:	00 
  1009d4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1009db:	00 
  1009dc:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009e0:	89 3c 24             	mov    %edi,(%esp)
  1009e3:	e8 88 09 00 00       	call   101370 <readi>
  1009e8:	83 f8 33             	cmp    $0x33,%eax
  1009eb:	0f 86 cf 01 00 00    	jbe    100bc0 <exec+0x220>
    goto bad;
  if(elf.magic != ELF_MAGIC)
  1009f1:	81 7d 94 7f 45 4c 46 	cmpl   $0x464c457f,-0x6c(%ebp)
  1009f8:	0f 85 c2 01 00 00    	jne    100bc0 <exec+0x220>
  1009fe:	66 90                	xchg   %ax,%ax
    goto bad;

  if((pgdir = setupkvm()) == 0)
  100a00:	e8 7b 54 00 00       	call   105e80 <setupkvm>
  100a05:	85 c0                	test   %eax,%eax
  100a07:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
  100a0d:	0f 84 ad 01 00 00    	je     100bc0 <exec+0x220>
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
  100a13:	66 83 7d c0 00       	cmpw   $0x0,-0x40(%ebp)
  100a18:	8b 75 b0             	mov    -0x50(%ebp),%esi
  100a1b:	0f 84 c6 02 00 00    	je     100ce7 <exec+0x347>
  100a21:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  100a28:	00 00 00 
  100a2b:	31 db                	xor    %ebx,%ebx
  100a2d:	eb 13                	jmp    100a42 <exec+0xa2>
  100a2f:	90                   	nop
  100a30:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
  100a34:	83 c3 01             	add    $0x1,%ebx
  100a37:	39 d8                	cmp    %ebx,%eax
  100a39:	0f 8e b9 00 00 00    	jle    100af8 <exec+0x158>
  100a3f:	83 c6 20             	add    $0x20,%esi
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
  100a42:	8d 55 c8             	lea    -0x38(%ebp),%edx
  100a45:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
  100a4c:	00 
  100a4d:	89 74 24 08          	mov    %esi,0x8(%esp)
  100a51:	89 54 24 04          	mov    %edx,0x4(%esp)
  100a55:	89 3c 24             	mov    %edi,(%esp)
  100a58:	e8 13 09 00 00       	call   101370 <readi>
  100a5d:	83 f8 20             	cmp    $0x20,%eax
  100a60:	75 6e                	jne    100ad0 <exec+0x130>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
  100a62:	83 7d c8 01          	cmpl   $0x1,-0x38(%ebp)
  100a66:	75 c8                	jne    100a30 <exec+0x90>
      continue;
    if(ph.memsz < ph.filesz)
  100a68:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100a6b:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  100a6e:	66 90                	xchg   %ax,%ax
  100a70:	72 5e                	jb     100ad0 <exec+0x130>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.va + ph.memsz)) == 0)
  100a72:	03 45 d0             	add    -0x30(%ebp),%eax
  100a75:	8b 8d f4 fe ff ff    	mov    -0x10c(%ebp),%ecx
  100a7b:	89 44 24 08          	mov    %eax,0x8(%esp)
  100a7f:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  100a85:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  100a89:	89 04 24             	mov    %eax,(%esp)
  100a8c:	e8 ef 56 00 00       	call   106180 <allocuvm>
  100a91:	85 c0                	test   %eax,%eax
  100a93:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)
  100a99:	74 35                	je     100ad0 <exec+0x130>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.va, ip, ph.offset, ph.filesz) < 0)
  100a9b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  100a9e:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
  100aa4:	89 7c 24 08          	mov    %edi,0x8(%esp)
  100aa8:	89 44 24 10          	mov    %eax,0x10(%esp)
  100aac:	8b 45 cc             	mov    -0x34(%ebp),%eax
  100aaf:	89 14 24             	mov    %edx,(%esp)
  100ab2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  100ab6:	8b 45 d0             	mov    -0x30(%ebp),%eax
  100ab9:	89 44 24 04          	mov    %eax,0x4(%esp)
  100abd:	e8 8e 57 00 00       	call   106250 <loaduvm>
  100ac2:	85 c0                	test   %eax,%eax
  100ac4:	0f 89 66 ff ff ff    	jns    100a30 <exec+0x90>
  100aca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

  return 0;

 bad:
  if(pgdir)
    freevm(pgdir);
  100ad0:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  100ad6:	89 04 24             	mov    %eax,(%esp)
  100ad9:	e8 62 55 00 00       	call   106040 <freevm>
  if(ip)
  100ade:	85 ff                	test   %edi,%edi
  100ae0:	0f 85 da 00 00 00    	jne    100bc0 <exec+0x220>
    iunlockput(ip);
  100ae6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  return -1;
}
  100aeb:	81 c4 2c 01 00 00    	add    $0x12c,%esp
  100af1:	5b                   	pop    %ebx
  100af2:	5e                   	pop    %esi
  100af3:	5f                   	pop    %edi
  100af4:	5d                   	pop    %ebp
  100af5:	c3                   	ret    
  100af6:	66 90                	xchg   %ax,%ax
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
  100af8:	8b 9d f4 fe ff ff    	mov    -0x10c(%ebp),%ebx
  100afe:	81 c3 ff 0f 00 00    	add    $0xfff,%ebx
  100b04:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  100b0a:	8d b3 00 10 00 00    	lea    0x1000(%ebx),%esi
    if((sz = allocuvm(pgdir, sz, ph.va + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.va, ip, ph.offset, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
  100b10:	89 3c 24             	mov    %edi,(%esp)
  100b13:	e8 a8 0f 00 00       	call   101ac0 <iunlockput>
  ip = 0;

  // Allocate a one-page stack at the next page boundary
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + PGSIZE)) == 0)
  100b18:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
  100b1e:	89 74 24 08          	mov    %esi,0x8(%esp)
  100b22:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  100b26:	89 0c 24             	mov    %ecx,(%esp)
  100b29:	e8 52 56 00 00       	call   106180 <allocuvm>
  100b2e:	85 c0                	test   %eax,%eax
  100b30:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)
  100b36:	74 7f                	je     100bb7 <exec+0x217>
    goto bad;

  // Push argument strings, prepare rest of stack in ustack.
  sp = sz;
  for(argc = 0; argv[argc]; argc++) {
  100b38:	8b 55 0c             	mov    0xc(%ebp),%edx
  100b3b:	8b 02                	mov    (%edx),%eax
  100b3d:	85 c0                	test   %eax,%eax
  100b3f:	0f 84 83 01 00 00    	je     100cc8 <exec+0x328>
  100b45:	8b 7d 0c             	mov    0xc(%ebp),%edi
  100b48:	31 f6                	xor    %esi,%esi
  100b4a:	8b 9d f4 fe ff ff    	mov    -0x10c(%ebp),%ebx
  100b50:	eb 28                	jmp    100b7a <exec+0x1da>
  100b52:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
      goto bad;
    sp -= strlen(argv[argc]) + 1;
    sp &= ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  100b58:	89 9c b5 10 ff ff ff 	mov    %ebx,-0xf0(%ebp,%esi,4)
#include "defs.h"
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
  100b5f:	8b 45 0c             	mov    0xc(%ebp),%eax
  if((sz = allocuvm(pgdir, sz, sz + PGSIZE)) == 0)
    goto bad;

  // Push argument strings, prepare rest of stack in ustack.
  sp = sz;
  for(argc = 0; argv[argc]; argc++) {
  100b62:	83 c6 01             	add    $0x1,%esi
      goto bad;
    sp -= strlen(argv[argc]) + 1;
    sp &= ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  100b65:	8d 95 04 ff ff ff    	lea    -0xfc(%ebp),%edx
#include "defs.h"
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
  100b6b:	8d 3c b0             	lea    (%eax,%esi,4),%edi
  if((sz = allocuvm(pgdir, sz, sz + PGSIZE)) == 0)
    goto bad;

  // Push argument strings, prepare rest of stack in ustack.
  sp = sz;
  for(argc = 0; argv[argc]; argc++) {
  100b6e:	8b 04 b0             	mov    (%eax,%esi,4),%eax
  100b71:	85 c0                	test   %eax,%eax
  100b73:	74 5d                	je     100bd2 <exec+0x232>
    if(argc >= MAXARG)
  100b75:	83 fe 20             	cmp    $0x20,%esi
  100b78:	74 3d                	je     100bb7 <exec+0x217>
      goto bad;
    sp -= strlen(argv[argc]) + 1;
  100b7a:	89 04 24             	mov    %eax,(%esp)
  100b7d:	e8 4e 32 00 00       	call   103dd0 <strlen>
  100b82:	f7 d0                	not    %eax
  100b84:	8d 1c 18             	lea    (%eax,%ebx,1),%ebx
    sp &= ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
  100b87:	8b 07                	mov    (%edi),%eax
  sp = sz;
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
    sp -= strlen(argv[argc]) + 1;
    sp &= ~3;
  100b89:	83 e3 fc             	and    $0xfffffffc,%ebx
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
  100b8c:	89 04 24             	mov    %eax,(%esp)
  100b8f:	e8 3c 32 00 00       	call   103dd0 <strlen>
  100b94:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
  100b9a:	83 c0 01             	add    $0x1,%eax
  100b9d:	89 44 24 0c          	mov    %eax,0xc(%esp)
  100ba1:	8b 07                	mov    (%edi),%eax
  100ba3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  100ba7:	89 0c 24             	mov    %ecx,(%esp)
  100baa:	89 44 24 08          	mov    %eax,0x8(%esp)
  100bae:	e8 ad 51 00 00       	call   105d60 <copyout>
  100bb3:	85 c0                	test   %eax,%eax
  100bb5:	79 a1                	jns    100b58 <exec+0x1b8>

 bad:
  if(pgdir)
    freevm(pgdir);
  if(ip)
    iunlockput(ip);
  100bb7:	31 ff                	xor    %edi,%edi
  100bb9:	e9 12 ff ff ff       	jmp    100ad0 <exec+0x130>
  100bbe:	66 90                	xchg   %ax,%ax
  100bc0:	89 3c 24             	mov    %edi,(%esp)
  100bc3:	e8 f8 0e 00 00       	call   101ac0 <iunlockput>
  100bc8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  100bcd:	e9 19 ff ff ff       	jmp    100aeb <exec+0x14b>
  if((sz = allocuvm(pgdir, sz, sz + PGSIZE)) == 0)
    goto bad;

  // Push argument strings, prepare rest of stack in ustack.
  sp = sz;
  for(argc = 0; argv[argc]; argc++) {
  100bd2:	8d 4e 03             	lea    0x3(%esi),%ecx
  100bd5:	8d 3c b5 04 00 00 00 	lea    0x4(,%esi,4),%edi
  100bdc:	8d 04 b5 10 00 00 00 	lea    0x10(,%esi,4),%eax
    sp &= ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
  100be3:	c7 84 8d 04 ff ff ff 	movl   $0x0,-0xfc(%ebp,%ecx,4)
  100bea:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer
  100bee:	89 d9                	mov    %ebx,%ecx

  sp -= (3+argc+1) * 4;
  100bf0:	29 c3                	sub    %eax,%ebx
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
  100bf2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  100bf6:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  }
  ustack[3+argc] = 0;

  ustack[0] = 0xffffffff;  // fake return PC
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer
  100bfc:	29 f9                	sub    %edi,%ecx
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;

  ustack[0] = 0xffffffff;  // fake return PC
  100bfe:	c7 85 04 ff ff ff ff 	movl   $0xffffffff,-0xfc(%ebp)
  100c05:	ff ff ff 
  ustack[1] = argc;
  100c08:	89 b5 08 ff ff ff    	mov    %esi,-0xf8(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
  100c0e:	89 8d 0c ff ff ff    	mov    %ecx,-0xf4(%ebp)

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
  100c14:	89 54 24 08          	mov    %edx,0x8(%esp)
  100c18:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  100c1c:	89 04 24             	mov    %eax,(%esp)
  100c1f:	e8 3c 51 00 00       	call   105d60 <copyout>
  100c24:	85 c0                	test   %eax,%eax
  100c26:	78 8f                	js     100bb7 <exec+0x217>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
  100c28:	8b 4d 08             	mov    0x8(%ebp),%ecx
  100c2b:	0f b6 11             	movzbl (%ecx),%edx
  100c2e:	84 d2                	test   %dl,%dl
  100c30:	74 21                	je     100c53 <exec+0x2b3>
  100c32:	89 c8                	mov    %ecx,%eax
  100c34:	83 c0 01             	add    $0x1,%eax
  100c37:	eb 11                	jmp    100c4a <exec+0x2aa>
  100c39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  100c40:	0f b6 10             	movzbl (%eax),%edx
  100c43:	83 c0 01             	add    $0x1,%eax
  100c46:	84 d2                	test   %dl,%dl
  100c48:	74 09                	je     100c53 <exec+0x2b3>
    if(*s == '/')
  100c4a:	80 fa 2f             	cmp    $0x2f,%dl
  100c4d:	75 f1                	jne    100c40 <exec+0x2a0>
  100c4f:	89 c1                	mov    %eax,%ecx
  100c51:	eb ed                	jmp    100c40 <exec+0x2a0>
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
  100c53:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  100c59:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  100c5d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
  100c64:	00 
  100c65:	83 c0 6c             	add    $0x6c,%eax
  100c68:	89 04 24             	mov    %eax,(%esp)
  100c6b:	e8 20 31 00 00       	call   103d90 <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
  100c70:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  proc->pgdir = pgdir;
  100c76:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));

  // Commit to the user image.
  oldpgdir = proc->pgdir;
  100c7c:	8b 70 04             	mov    0x4(%eax),%esi
  proc->pgdir = pgdir;
  100c7f:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
  100c82:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  100c88:	8b 8d f4 fe ff ff    	mov    -0x10c(%ebp),%ecx
  100c8e:	89 08                	mov    %ecx,(%eax)
  proc->tf->eip = elf.entry;  // main
  100c90:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  100c96:	8b 55 ac             	mov    -0x54(%ebp),%edx
  100c99:	8b 40 18             	mov    0x18(%eax),%eax
  100c9c:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
  100c9f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  100ca5:	8b 40 18             	mov    0x18(%eax),%eax
  100ca8:	89 58 44             	mov    %ebx,0x44(%eax)
  switchuvm(proc);
  100cab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  100cb1:	89 04 24             	mov    %eax,(%esp)
  100cb4:	e8 57 56 00 00       	call   106310 <switchuvm>
  freevm(oldpgdir);
  100cb9:	89 34 24             	mov    %esi,(%esp)
  100cbc:	e8 7f 53 00 00       	call   106040 <freevm>
  100cc1:	31 c0                	xor    %eax,%eax

  return 0;
  100cc3:	e9 23 fe ff ff       	jmp    100aeb <exec+0x14b>
  if((sz = allocuvm(pgdir, sz, sz + PGSIZE)) == 0)
    goto bad;

  // Push argument strings, prepare rest of stack in ustack.
  sp = sz;
  for(argc = 0; argv[argc]; argc++) {
  100cc8:	8b 9d f4 fe ff ff    	mov    -0x10c(%ebp),%ebx
  100cce:	b0 10                	mov    $0x10,%al
  100cd0:	bf 04 00 00 00       	mov    $0x4,%edi
  100cd5:	b9 03 00 00 00       	mov    $0x3,%ecx
  100cda:	31 f6                	xor    %esi,%esi
  100cdc:	8d 95 04 ff ff ff    	lea    -0xfc(%ebp),%edx
  100ce2:	e9 fc fe ff ff       	jmp    100be3 <exec+0x243>
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
  100ce7:	be 00 10 00 00       	mov    $0x1000,%esi
  100cec:	31 db                	xor    %ebx,%ebx
  100cee:	e9 1d fe ff ff       	jmp    100b10 <exec+0x170>
  100cf3:	90                   	nop
  100cf4:	90                   	nop
  100cf5:	90                   	nop
  100cf6:	90                   	nop
  100cf7:	90                   	nop
  100cf8:	90                   	nop
  100cf9:	90                   	nop
  100cfa:	90                   	nop
  100cfb:	90                   	nop
  100cfc:	90                   	nop
  100cfd:	90                   	nop
  100cfe:	90                   	nop
  100cff:	90                   	nop

00100d00 <filewrite>:
}

// Write to file f.  Addr is kernel address.
int
filewrite(struct file *f, char *addr, int n)
{
  100d00:	55                   	push   %ebp
  100d01:	89 e5                	mov    %esp,%ebp
  100d03:	83 ec 38             	sub    $0x38,%esp
  100d06:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  100d09:	8b 5d 08             	mov    0x8(%ebp),%ebx
  100d0c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  100d0f:	8b 75 0c             	mov    0xc(%ebp),%esi
  100d12:	89 7d fc             	mov    %edi,-0x4(%ebp)
  100d15:	8b 7d 10             	mov    0x10(%ebp),%edi
  int r;

  if(f->writable == 0)
  100d18:	80 7b 09 00          	cmpb   $0x0,0x9(%ebx)
  100d1c:	74 5a                	je     100d78 <filewrite+0x78>
    return -1;
  if(f->type == FD_PIPE)
  100d1e:	8b 03                	mov    (%ebx),%eax
  100d20:	83 f8 01             	cmp    $0x1,%eax
  100d23:	74 5b                	je     100d80 <filewrite+0x80>
    return pipewrite(f->pipe, addr, n);
  if(f->type == FD_INODE){
  100d25:	83 f8 02             	cmp    $0x2,%eax
  100d28:	75 6d                	jne    100d97 <filewrite+0x97>
    ilock(f->ip);
  100d2a:	8b 43 10             	mov    0x10(%ebx),%eax
  100d2d:	89 04 24             	mov    %eax,(%esp)
  100d30:	e8 7b 0e 00 00       	call   101bb0 <ilock>
    if((r = writei(f->ip, addr, f->off, n)) > 0)
  100d35:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  100d39:	8b 43 14             	mov    0x14(%ebx),%eax
  100d3c:	89 74 24 04          	mov    %esi,0x4(%esp)
  100d40:	89 44 24 08          	mov    %eax,0x8(%esp)
  100d44:	8b 43 10             	mov    0x10(%ebx),%eax
  100d47:	89 04 24             	mov    %eax,(%esp)
  100d4a:	e8 b1 07 00 00       	call   101500 <writei>
  100d4f:	85 c0                	test   %eax,%eax
  100d51:	7e 03                	jle    100d56 <filewrite+0x56>
      f->off += r;
  100d53:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
  100d56:	8b 53 10             	mov    0x10(%ebx),%edx
  100d59:	89 14 24             	mov    %edx,(%esp)
  100d5c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100d5f:	e8 0c 0a 00 00       	call   101770 <iunlock>
    return r;
  100d64:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  }
  panic("filewrite");
}
  100d67:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  100d6a:	8b 75 f8             	mov    -0x8(%ebp),%esi
  100d6d:	8b 7d fc             	mov    -0x4(%ebp),%edi
  100d70:	89 ec                	mov    %ebp,%esp
  100d72:	5d                   	pop    %ebp
  100d73:	c3                   	ret    
  100d74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    if((r = writei(f->ip, addr, f->off, n)) > 0)
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("filewrite");
  100d78:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  100d7d:	eb e8                	jmp    100d67 <filewrite+0x67>
  100d7f:	90                   	nop
  int r;

  if(f->writable == 0)
    return -1;
  if(f->type == FD_PIPE)
    return pipewrite(f->pipe, addr, n);
  100d80:	8b 43 0c             	mov    0xc(%ebx),%eax
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("filewrite");
}
  100d83:	8b 75 f8             	mov    -0x8(%ebp),%esi
  100d86:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  100d89:	8b 7d fc             	mov    -0x4(%ebp),%edi
  int r;

  if(f->writable == 0)
    return -1;
  if(f->type == FD_PIPE)
    return pipewrite(f->pipe, addr, n);
  100d8c:	89 45 08             	mov    %eax,0x8(%ebp)
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("filewrite");
}
  100d8f:	89 ec                	mov    %ebp,%esp
  100d91:	5d                   	pop    %ebp
  int r;

  if(f->writable == 0)
    return -1;
  if(f->type == FD_PIPE)
    return pipewrite(f->pipe, addr, n);
  100d92:	e9 e9 1f 00 00       	jmp    102d80 <pipewrite>
    if((r = writei(f->ip, addr, f->off, n)) > 0)
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("filewrite");
  100d97:	c7 04 24 5f 65 10 00 	movl   $0x10655f,(%esp)
  100d9e:	e8 7d fb ff ff       	call   100920 <panic>
  100da3:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  100da9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00100db0 <fileread>:
}

// Read from file f.  Addr is kernel address.
int
fileread(struct file *f, char *addr, int n)
{
  100db0:	55                   	push   %ebp
  100db1:	89 e5                	mov    %esp,%ebp
  100db3:	83 ec 38             	sub    $0x38,%esp
  100db6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  100db9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  100dbc:	89 75 f8             	mov    %esi,-0x8(%ebp)
  100dbf:	8b 75 0c             	mov    0xc(%ebp),%esi
  100dc2:	89 7d fc             	mov    %edi,-0x4(%ebp)
  100dc5:	8b 7d 10             	mov    0x10(%ebp),%edi
  int r;

  if(f->readable == 0)
  100dc8:	80 7b 08 00          	cmpb   $0x0,0x8(%ebx)
  100dcc:	74 5a                	je     100e28 <fileread+0x78>
    return -1;
  if(f->type == FD_PIPE)
  100dce:	8b 03                	mov    (%ebx),%eax
  100dd0:	83 f8 01             	cmp    $0x1,%eax
  100dd3:	74 5b                	je     100e30 <fileread+0x80>
    return piperead(f->pipe, addr, n);
  if(f->type == FD_INODE){
  100dd5:	83 f8 02             	cmp    $0x2,%eax
  100dd8:	75 6d                	jne    100e47 <fileread+0x97>
    ilock(f->ip);
  100dda:	8b 43 10             	mov    0x10(%ebx),%eax
  100ddd:	89 04 24             	mov    %eax,(%esp)
  100de0:	e8 cb 0d 00 00       	call   101bb0 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
  100de5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  100de9:	8b 43 14             	mov    0x14(%ebx),%eax
  100dec:	89 74 24 04          	mov    %esi,0x4(%esp)
  100df0:	89 44 24 08          	mov    %eax,0x8(%esp)
  100df4:	8b 43 10             	mov    0x10(%ebx),%eax
  100df7:	89 04 24             	mov    %eax,(%esp)
  100dfa:	e8 71 05 00 00       	call   101370 <readi>
  100dff:	85 c0                	test   %eax,%eax
  100e01:	7e 03                	jle    100e06 <fileread+0x56>
      f->off += r;
  100e03:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
  100e06:	8b 53 10             	mov    0x10(%ebx),%edx
  100e09:	89 14 24             	mov    %edx,(%esp)
  100e0c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100e0f:	e8 5c 09 00 00       	call   101770 <iunlock>
    return r;
  100e14:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  }
  panic("fileread");
}
  100e17:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  100e1a:	8b 75 f8             	mov    -0x8(%ebp),%esi
  100e1d:	8b 7d fc             	mov    -0x4(%ebp),%edi
  100e20:	89 ec                	mov    %ebp,%esp
  100e22:	5d                   	pop    %ebp
  100e23:	c3                   	ret    
  100e24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    if((r = readi(f->ip, addr, f->off, n)) > 0)
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("fileread");
  100e28:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  100e2d:	eb e8                	jmp    100e17 <fileread+0x67>
  100e2f:	90                   	nop
  int r;

  if(f->readable == 0)
    return -1;
  if(f->type == FD_PIPE)
    return piperead(f->pipe, addr, n);
  100e30:	8b 43 0c             	mov    0xc(%ebx),%eax
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("fileread");
}
  100e33:	8b 75 f8             	mov    -0x8(%ebp),%esi
  100e36:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  100e39:	8b 7d fc             	mov    -0x4(%ebp),%edi
  int r;

  if(f->readable == 0)
    return -1;
  if(f->type == FD_PIPE)
    return piperead(f->pipe, addr, n);
  100e3c:	89 45 08             	mov    %eax,0x8(%ebp)
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("fileread");
}
  100e3f:	89 ec                	mov    %ebp,%esp
  100e41:	5d                   	pop    %ebp
  int r;

  if(f->readable == 0)
    return -1;
  if(f->type == FD_PIPE)
    return piperead(f->pipe, addr, n);
  100e42:	e9 39 1e 00 00       	jmp    102c80 <piperead>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("fileread");
  100e47:	c7 04 24 69 65 10 00 	movl   $0x106569,(%esp)
  100e4e:	e8 cd fa ff ff       	call   100920 <panic>
  100e53:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  100e59:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00100e60 <filestat>:
}

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
  100e60:	55                   	push   %ebp
  if(f->type == FD_INODE){
  100e61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
  100e66:	89 e5                	mov    %esp,%ebp
  100e68:	53                   	push   %ebx
  100e69:	83 ec 14             	sub    $0x14,%esp
  100e6c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(f->type == FD_INODE){
  100e6f:	83 3b 02             	cmpl   $0x2,(%ebx)
  100e72:	74 0c                	je     100e80 <filestat+0x20>
    stati(f->ip, st);
    iunlock(f->ip);
    return 0;
  }
  return -1;
}
  100e74:	83 c4 14             	add    $0x14,%esp
  100e77:	5b                   	pop    %ebx
  100e78:	5d                   	pop    %ebp
  100e79:	c3                   	ret    
  100e7a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
  if(f->type == FD_INODE){
    ilock(f->ip);
  100e80:	8b 43 10             	mov    0x10(%ebx),%eax
  100e83:	89 04 24             	mov    %eax,(%esp)
  100e86:	e8 25 0d 00 00       	call   101bb0 <ilock>
    stati(f->ip, st);
  100e8b:	8b 45 0c             	mov    0xc(%ebp),%eax
  100e8e:	89 44 24 04          	mov    %eax,0x4(%esp)
  100e92:	8b 43 10             	mov    0x10(%ebx),%eax
  100e95:	89 04 24             	mov    %eax,(%esp)
  100e98:	e8 e3 01 00 00       	call   101080 <stati>
    iunlock(f->ip);
  100e9d:	8b 43 10             	mov    0x10(%ebx),%eax
  100ea0:	89 04 24             	mov    %eax,(%esp)
  100ea3:	e8 c8 08 00 00       	call   101770 <iunlock>
    return 0;
  }
  return -1;
}
  100ea8:	83 c4 14             	add    $0x14,%esp
filestat(struct file *f, struct stat *st)
{
  if(f->type == FD_INODE){
    ilock(f->ip);
    stati(f->ip, st);
    iunlock(f->ip);
  100eab:	31 c0                	xor    %eax,%eax
    return 0;
  }
  return -1;
}
  100ead:	5b                   	pop    %ebx
  100eae:	5d                   	pop    %ebp
  100eaf:	c3                   	ret    

00100eb0 <filedup>:
}

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
  100eb0:	55                   	push   %ebp
  100eb1:	89 e5                	mov    %esp,%ebp
  100eb3:	53                   	push   %ebx
  100eb4:	83 ec 14             	sub    $0x14,%esp
  100eb7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ftable.lock);
  100eba:	c7 04 24 e0 a0 10 00 	movl   $0x10a0e0,(%esp)
  100ec1:	e8 8a 2c 00 00       	call   103b50 <acquire>
  if(f->ref < 1)
  100ec6:	8b 43 04             	mov    0x4(%ebx),%eax
  100ec9:	85 c0                	test   %eax,%eax
  100ecb:	7e 1a                	jle    100ee7 <filedup+0x37>
    panic("filedup");
  f->ref++;
  100ecd:	83 c0 01             	add    $0x1,%eax
  100ed0:	89 43 04             	mov    %eax,0x4(%ebx)
  release(&ftable.lock);
  100ed3:	c7 04 24 e0 a0 10 00 	movl   $0x10a0e0,(%esp)
  100eda:	e8 21 2c 00 00       	call   103b00 <release>
  return f;
}
  100edf:	89 d8                	mov    %ebx,%eax
  100ee1:	83 c4 14             	add    $0x14,%esp
  100ee4:	5b                   	pop    %ebx
  100ee5:	5d                   	pop    %ebp
  100ee6:	c3                   	ret    
struct file*
filedup(struct file *f)
{
  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("filedup");
  100ee7:	c7 04 24 72 65 10 00 	movl   $0x106572,(%esp)
  100eee:	e8 2d fa ff ff       	call   100920 <panic>
  100ef3:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  100ef9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00100f00 <filealloc>:
}

// Allocate a file structure.
struct file*
filealloc(void)
{
  100f00:	55                   	push   %ebp
  100f01:	89 e5                	mov    %esp,%ebp
  100f03:	53                   	push   %ebx
  initlock(&ftable.lock, "ftable");
}

// Allocate a file structure.
struct file*
filealloc(void)
  100f04:	bb 2c a1 10 00       	mov    $0x10a12c,%ebx
{
  100f09:	83 ec 14             	sub    $0x14,%esp
  struct file *f;

  acquire(&ftable.lock);
  100f0c:	c7 04 24 e0 a0 10 00 	movl   $0x10a0e0,(%esp)
  100f13:	e8 38 2c 00 00       	call   103b50 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
  100f18:	8b 15 18 a1 10 00    	mov    0x10a118,%edx
  100f1e:	85 d2                	test   %edx,%edx
  100f20:	75 11                	jne    100f33 <filealloc+0x33>
  100f22:	eb 4a                	jmp    100f6e <filealloc+0x6e>
  100f24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
  100f28:	83 c3 18             	add    $0x18,%ebx
  100f2b:	81 fb 74 aa 10 00    	cmp    $0x10aa74,%ebx
  100f31:	74 25                	je     100f58 <filealloc+0x58>
    if(f->ref == 0){
  100f33:	8b 43 04             	mov    0x4(%ebx),%eax
  100f36:	85 c0                	test   %eax,%eax
  100f38:	75 ee                	jne    100f28 <filealloc+0x28>
      f->ref = 1;
  100f3a:	c7 43 04 01 00 00 00 	movl   $0x1,0x4(%ebx)
      release(&ftable.lock);
  100f41:	c7 04 24 e0 a0 10 00 	movl   $0x10a0e0,(%esp)
  100f48:	e8 b3 2b 00 00       	call   103b00 <release>
      return f;
    }
  }
  release(&ftable.lock);
  return 0;
}
  100f4d:	89 d8                	mov    %ebx,%eax
  100f4f:	83 c4 14             	add    $0x14,%esp
  100f52:	5b                   	pop    %ebx
  100f53:	5d                   	pop    %ebp
  100f54:	c3                   	ret    
  100f55:	8d 76 00             	lea    0x0(%esi),%esi
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
  100f58:	31 db                	xor    %ebx,%ebx
  100f5a:	c7 04 24 e0 a0 10 00 	movl   $0x10a0e0,(%esp)
  100f61:	e8 9a 2b 00 00       	call   103b00 <release>
  return 0;
}
  100f66:	89 d8                	mov    %ebx,%eax
  100f68:	83 c4 14             	add    $0x14,%esp
  100f6b:	5b                   	pop    %ebx
  100f6c:	5d                   	pop    %ebp
  100f6d:	c3                   	ret    
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
  100f6e:	bb 14 a1 10 00       	mov    $0x10a114,%ebx
  100f73:	eb c5                	jmp    100f3a <filealloc+0x3a>
  100f75:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  100f79:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00100f80 <fileclose>:
}

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
  100f80:	55                   	push   %ebp
  100f81:	89 e5                	mov    %esp,%ebp
  100f83:	83 ec 38             	sub    $0x38,%esp
  100f86:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  100f89:	8b 5d 08             	mov    0x8(%ebp),%ebx
  100f8c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  100f8f:	89 7d fc             	mov    %edi,-0x4(%ebp)
  struct file ff;

  acquire(&ftable.lock);
  100f92:	c7 04 24 e0 a0 10 00 	movl   $0x10a0e0,(%esp)
  100f99:	e8 b2 2b 00 00       	call   103b50 <acquire>
  if(f->ref < 1)
  100f9e:	8b 43 04             	mov    0x4(%ebx),%eax
  100fa1:	85 c0                	test   %eax,%eax
  100fa3:	0f 8e 9c 00 00 00    	jle    101045 <fileclose+0xc5>
    panic("fileclose");
  if(--f->ref > 0){
  100fa9:	83 e8 01             	sub    $0x1,%eax
  100fac:	85 c0                	test   %eax,%eax
  100fae:	89 43 04             	mov    %eax,0x4(%ebx)
  100fb1:	74 1d                	je     100fd0 <fileclose+0x50>
    release(&ftable.lock);
  100fb3:	c7 45 08 e0 a0 10 00 	movl   $0x10a0e0,0x8(%ebp)
  
  if(ff.type == FD_PIPE)
    pipeclose(ff.pipe, ff.writable);
  else if(ff.type == FD_INODE)
    iput(ff.ip);
}
  100fba:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  100fbd:	8b 75 f8             	mov    -0x8(%ebp),%esi
  100fc0:	8b 7d fc             	mov    -0x4(%ebp),%edi
  100fc3:	89 ec                	mov    %ebp,%esp
  100fc5:	5d                   	pop    %ebp

  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("fileclose");
  if(--f->ref > 0){
    release(&ftable.lock);
  100fc6:	e9 35 2b 00 00       	jmp    103b00 <release>
  100fcb:	90                   	nop
  100fcc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    return;
  }
  ff = *f;
  100fd0:	8b 43 0c             	mov    0xc(%ebx),%eax
  100fd3:	8b 7b 10             	mov    0x10(%ebx),%edi
  100fd6:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100fd9:	0f b6 43 09          	movzbl 0x9(%ebx),%eax
  100fdd:	88 45 e7             	mov    %al,-0x19(%ebp)
  100fe0:	8b 33                	mov    (%ebx),%esi
  f->ref = 0;
  100fe2:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
  f->type = FD_NONE;
  100fe9:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  release(&ftable.lock);
  100fef:	c7 04 24 e0 a0 10 00 	movl   $0x10a0e0,(%esp)
  100ff6:	e8 05 2b 00 00       	call   103b00 <release>
  
  if(ff.type == FD_PIPE)
  100ffb:	83 fe 01             	cmp    $0x1,%esi
  100ffe:	74 30                	je     101030 <fileclose+0xb0>
    pipeclose(ff.pipe, ff.writable);
  else if(ff.type == FD_INODE)
  101000:	83 fe 02             	cmp    $0x2,%esi
  101003:	74 13                	je     101018 <fileclose+0x98>
    iput(ff.ip);
}
  101005:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  101008:	8b 75 f8             	mov    -0x8(%ebp),%esi
  10100b:	8b 7d fc             	mov    -0x4(%ebp),%edi
  10100e:	89 ec                	mov    %ebp,%esp
  101010:	5d                   	pop    %ebp
  101011:	c3                   	ret    
  101012:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  release(&ftable.lock);
  
  if(ff.type == FD_PIPE)
    pipeclose(ff.pipe, ff.writable);
  else if(ff.type == FD_INODE)
    iput(ff.ip);
  101018:	89 7d 08             	mov    %edi,0x8(%ebp)
}
  10101b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  10101e:	8b 75 f8             	mov    -0x8(%ebp),%esi
  101021:	8b 7d fc             	mov    -0x4(%ebp),%edi
  101024:	89 ec                	mov    %ebp,%esp
  101026:	5d                   	pop    %ebp
  release(&ftable.lock);
  
  if(ff.type == FD_PIPE)
    pipeclose(ff.pipe, ff.writable);
  else if(ff.type == FD_INODE)
    iput(ff.ip);
  101027:	e9 54 08 00 00       	jmp    101880 <iput>
  10102c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  f->ref = 0;
  f->type = FD_NONE;
  release(&ftable.lock);
  
  if(ff.type == FD_PIPE)
    pipeclose(ff.pipe, ff.writable);
  101030:	0f be 45 e7          	movsbl -0x19(%ebp),%eax
  101034:	89 44 24 04          	mov    %eax,0x4(%esp)
  101038:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10103b:	89 04 24             	mov    %eax,(%esp)
  10103e:	e8 2d 1e 00 00       	call   102e70 <pipeclose>
  101043:	eb c0                	jmp    101005 <fileclose+0x85>
{
  struct file ff;

  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("fileclose");
  101045:	c7 04 24 7a 65 10 00 	movl   $0x10657a,(%esp)
  10104c:	e8 cf f8 ff ff       	call   100920 <panic>
  101051:	eb 0d                	jmp    101060 <fileinit>
  101053:	90                   	nop
  101054:	90                   	nop
  101055:	90                   	nop
  101056:	90                   	nop
  101057:	90                   	nop
  101058:	90                   	nop
  101059:	90                   	nop
  10105a:	90                   	nop
  10105b:	90                   	nop
  10105c:	90                   	nop
  10105d:	90                   	nop
  10105e:	90                   	nop
  10105f:	90                   	nop

00101060 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
  101060:	55                   	push   %ebp
  101061:	89 e5                	mov    %esp,%ebp
  101063:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
  101066:	c7 44 24 04 84 65 10 	movl   $0x106584,0x4(%esp)
  10106d:	00 
  10106e:	c7 04 24 e0 a0 10 00 	movl   $0x10a0e0,(%esp)
  101075:	e8 46 29 00 00       	call   1039c0 <initlock>
}
  10107a:	c9                   	leave  
  10107b:	c3                   	ret    
  10107c:	90                   	nop
  10107d:	90                   	nop
  10107e:	90                   	nop
  10107f:	90                   	nop

00101080 <stati>:
}

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
  101080:	55                   	push   %ebp
  101081:	89 e5                	mov    %esp,%ebp
  101083:	8b 55 08             	mov    0x8(%ebp),%edx
  101086:	8b 45 0c             	mov    0xc(%ebp),%eax
  st->dev = ip->dev;
  101089:	8b 0a                	mov    (%edx),%ecx
  10108b:	89 48 04             	mov    %ecx,0x4(%eax)
  st->ino = ip->inum;
  10108e:	8b 4a 04             	mov    0x4(%edx),%ecx
  101091:	89 48 08             	mov    %ecx,0x8(%eax)
  st->type = ip->type;
  101094:	0f b7 4a 10          	movzwl 0x10(%edx),%ecx
  101098:	66 89 08             	mov    %cx,(%eax)
  st->nlink = ip->nlink;
  10109b:	0f b7 4a 16          	movzwl 0x16(%edx),%ecx
  10109f:	66 89 48 0c          	mov    %cx,0xc(%eax)
  st->size = ip->size;
  1010a3:	8b 52 18             	mov    0x18(%edx),%edx
  1010a6:	89 50 10             	mov    %edx,0x10(%eax)
}
  1010a9:	5d                   	pop    %ebp
  1010aa:	c3                   	ret    
  1010ab:	90                   	nop
  1010ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

001010b0 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
  1010b0:	55                   	push   %ebp
  1010b1:	89 e5                	mov    %esp,%ebp
  1010b3:	53                   	push   %ebx
  1010b4:	83 ec 14             	sub    $0x14,%esp
  1010b7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&icache.lock);
  1010ba:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  1010c1:	e8 8a 2a 00 00       	call   103b50 <acquire>
  ip->ref++;
  1010c6:	83 43 08 01          	addl   $0x1,0x8(%ebx)
  release(&icache.lock);
  1010ca:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  1010d1:	e8 2a 2a 00 00       	call   103b00 <release>
  return ip;
}
  1010d6:	89 d8                	mov    %ebx,%eax
  1010d8:	83 c4 14             	add    $0x14,%esp
  1010db:	5b                   	pop    %ebx
  1010dc:	5d                   	pop    %ebp
  1010dd:	c3                   	ret    
  1010de:	66 90                	xchg   %ax,%ax

001010e0 <iget>:

// Find the inode with number inum on device dev
// and return the in-memory copy.
static struct inode*
iget(uint dev, uint inum)
{
  1010e0:	55                   	push   %ebp
  1010e1:	89 e5                	mov    %esp,%ebp
  1010e3:	57                   	push   %edi
  1010e4:	89 d7                	mov    %edx,%edi
  1010e6:	56                   	push   %esi
}

// Find the inode with number inum on device dev
// and return the in-memory copy.
static struct inode*
iget(uint dev, uint inum)
  1010e7:	31 f6                	xor    %esi,%esi
{
  1010e9:	53                   	push   %ebx
  1010ea:	89 c3                	mov    %eax,%ebx
  1010ec:	83 ec 2c             	sub    $0x2c,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
  1010ef:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  1010f6:	e8 55 2a 00 00       	call   103b50 <acquire>
}

// Find the inode with number inum on device dev
// and return the in-memory copy.
static struct inode*
iget(uint dev, uint inum)
  1010fb:	b8 14 ab 10 00       	mov    $0x10ab14,%eax
  101100:	eb 14                	jmp    101116 <iget+0x36>
  101102:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
      ip->ref++;
      release(&icache.lock);
      return ip;
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
  101108:	85 f6                	test   %esi,%esi
  10110a:	74 3c                	je     101148 <iget+0x68>

  acquire(&icache.lock);

  // Try for cached inode.
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
  10110c:	83 c0 50             	add    $0x50,%eax
  10110f:	3d b4 ba 10 00       	cmp    $0x10bab4,%eax
  101114:	74 42                	je     101158 <iget+0x78>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
  101116:	8b 48 08             	mov    0x8(%eax),%ecx
  101119:	85 c9                	test   %ecx,%ecx
  10111b:	7e eb                	jle    101108 <iget+0x28>
  10111d:	39 18                	cmp    %ebx,(%eax)
  10111f:	75 e7                	jne    101108 <iget+0x28>
  101121:	39 78 04             	cmp    %edi,0x4(%eax)
  101124:	75 e2                	jne    101108 <iget+0x28>
      ip->ref++;
  101126:	83 c1 01             	add    $0x1,%ecx
  101129:	89 48 08             	mov    %ecx,0x8(%eax)
      release(&icache.lock);
  10112c:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  101133:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  101136:	e8 c5 29 00 00       	call   103b00 <release>
      return ip;
  10113b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  ip->ref = 1;
  ip->flags = 0;
  release(&icache.lock);

  return ip;
}
  10113e:	83 c4 2c             	add    $0x2c,%esp
  101141:	5b                   	pop    %ebx
  101142:	5e                   	pop    %esi
  101143:	5f                   	pop    %edi
  101144:	5d                   	pop    %ebp
  101145:	c3                   	ret    
  101146:	66 90                	xchg   %ax,%ax
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
      ip->ref++;
      release(&icache.lock);
      return ip;
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
  101148:	85 c9                	test   %ecx,%ecx
  10114a:	75 c0                	jne    10110c <iget+0x2c>
  10114c:	89 c6                	mov    %eax,%esi

  acquire(&icache.lock);

  // Try for cached inode.
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
  10114e:	83 c0 50             	add    $0x50,%eax
  101151:	3d b4 ba 10 00       	cmp    $0x10bab4,%eax
  101156:	75 be                	jne    101116 <iget+0x36>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Allocate fresh inode.
  if(empty == 0)
  101158:	85 f6                	test   %esi,%esi
  10115a:	74 29                	je     101185 <iget+0xa5>
    panic("iget: no inodes");

  ip = empty;
  ip->dev = dev;
  10115c:	89 1e                	mov    %ebx,(%esi)
  ip->inum = inum;
  10115e:	89 7e 04             	mov    %edi,0x4(%esi)
  ip->ref = 1;
  101161:	c7 46 08 01 00 00 00 	movl   $0x1,0x8(%esi)
  ip->flags = 0;
  101168:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
  release(&icache.lock);
  10116f:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  101176:	e8 85 29 00 00       	call   103b00 <release>

  return ip;
}
  10117b:	83 c4 2c             	add    $0x2c,%esp
  ip = empty;
  ip->dev = dev;
  ip->inum = inum;
  ip->ref = 1;
  ip->flags = 0;
  release(&icache.lock);
  10117e:	89 f0                	mov    %esi,%eax

  return ip;
}
  101180:	5b                   	pop    %ebx
  101181:	5e                   	pop    %esi
  101182:	5f                   	pop    %edi
  101183:	5d                   	pop    %ebp
  101184:	c3                   	ret    
      empty = ip;
  }

  // Allocate fresh inode.
  if(empty == 0)
    panic("iget: no inodes");
  101185:	c7 04 24 8b 65 10 00 	movl   $0x10658b,(%esp)
  10118c:	e8 8f f7 ff ff       	call   100920 <panic>
  101191:	eb 0d                	jmp    1011a0 <readsb>
  101193:	90                   	nop
  101194:	90                   	nop
  101195:	90                   	nop
  101196:	90                   	nop
  101197:	90                   	nop
  101198:	90                   	nop
  101199:	90                   	nop
  10119a:	90                   	nop
  10119b:	90                   	nop
  10119c:	90                   	nop
  10119d:	90                   	nop
  10119e:	90                   	nop
  10119f:	90                   	nop

001011a0 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
static void
readsb(int dev, struct superblock *sb)
{
  1011a0:	55                   	push   %ebp
  1011a1:	89 e5                	mov    %esp,%ebp
  1011a3:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
  1011a6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1011ad:	00 
static void itrunc(struct inode*);

// Read the super block.
static void
readsb(int dev, struct superblock *sb)
{
  1011ae:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  1011b1:	89 75 fc             	mov    %esi,-0x4(%ebp)
  1011b4:	89 d6                	mov    %edx,%esi
  struct buf *bp;
  
  bp = bread(dev, 1);
  1011b6:	89 04 24             	mov    %eax,(%esp)
  1011b9:	e8 62 ef ff ff       	call   100120 <bread>
  memmove(sb, bp->data, sizeof(*sb));
  1011be:	89 34 24             	mov    %esi,(%esp)
  1011c1:	c7 44 24 08 0c 00 00 	movl   $0xc,0x8(%esp)
  1011c8:	00 
static void
readsb(int dev, struct superblock *sb)
{
  struct buf *bp;
  
  bp = bread(dev, 1);
  1011c9:	89 c3                	mov    %eax,%ebx
  memmove(sb, bp->data, sizeof(*sb));
  1011cb:	8d 40 18             	lea    0x18(%eax),%eax
  1011ce:	89 44 24 04          	mov    %eax,0x4(%esp)
  1011d2:	e8 99 2a 00 00       	call   103c70 <memmove>
  brelse(bp);
  1011d7:	89 1c 24             	mov    %ebx,(%esp)
  1011da:	e8 91 ee ff ff       	call   100070 <brelse>
}
  1011df:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  1011e2:	8b 75 fc             	mov    -0x4(%ebp),%esi
  1011e5:	89 ec                	mov    %ebp,%esp
  1011e7:	5d                   	pop    %ebp
  1011e8:	c3                   	ret    
  1011e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

001011f0 <balloc>:
// Blocks. 

// Allocate a disk block.
static uint
balloc(uint dev)
{
  1011f0:	55                   	push   %ebp
  1011f1:	89 e5                	mov    %esp,%ebp
  1011f3:	57                   	push   %edi
  1011f4:	56                   	push   %esi
  1011f5:	53                   	push   %ebx
  1011f6:	83 ec 3c             	sub    $0x3c,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  1011f9:	8d 55 dc             	lea    -0x24(%ebp),%edx
// Blocks. 

// Allocate a disk block.
static uint
balloc(uint dev)
{
  1011fc:	89 45 d0             	mov    %eax,-0x30(%ebp)
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  1011ff:	e8 9c ff ff ff       	call   1011a0 <readsb>
  for(b = 0; b < sb.size; b += BPB){
  101204:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101207:	85 c0                	test   %eax,%eax
  101209:	0f 84 9c 00 00 00    	je     1012ab <balloc+0xbb>
  10120f:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
    bp = bread(dev, BBLOCK(b, sb.ninodes));
  101216:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101219:	31 db                	xor    %ebx,%ebx
  10121b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10121e:	c1 e8 03             	shr    $0x3,%eax
  101221:	c1 fa 0c             	sar    $0xc,%edx
  101224:	8d 44 10 03          	lea    0x3(%eax,%edx,1),%eax
  101228:	89 44 24 04          	mov    %eax,0x4(%esp)
  10122c:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10122f:	89 04 24             	mov    %eax,(%esp)
  101232:	e8 e9 ee ff ff       	call   100120 <bread>
  101237:	89 c6                	mov    %eax,%esi
  101239:	eb 10                	jmp    10124b <balloc+0x5b>
  10123b:	90                   	nop
  10123c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    for(bi = 0; bi < BPB; bi++){
  101240:	83 c3 01             	add    $0x1,%ebx
  101243:	81 fb 00 10 00 00    	cmp    $0x1000,%ebx
  101249:	74 45                	je     101290 <balloc+0xa0>
      m = 1 << (bi % 8);
  10124b:	89 d9                	mov    %ebx,%ecx
  10124d:	ba 01 00 00 00       	mov    $0x1,%edx
  101252:	83 e1 07             	and    $0x7,%ecx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
  101255:	89 d8                	mov    %ebx,%eax
  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB; bi++){
      m = 1 << (bi % 8);
  101257:	d3 e2                	shl    %cl,%edx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
  101259:	c1 f8 03             	sar    $0x3,%eax
  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB; bi++){
      m = 1 << (bi % 8);
  10125c:	89 d1                	mov    %edx,%ecx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
  10125e:	0f b6 54 06 18       	movzbl 0x18(%esi,%eax,1),%edx
  101263:	0f b6 fa             	movzbl %dl,%edi
  101266:	85 cf                	test   %ecx,%edi
  101268:	75 d6                	jne    101240 <balloc+0x50>
        bp->data[bi/8] |= m;  // Mark block in use on disk.
  10126a:	09 d1                	or     %edx,%ecx
  10126c:	88 4c 06 18          	mov    %cl,0x18(%esi,%eax,1)
        bwrite(bp);
  101270:	89 34 24             	mov    %esi,(%esp)
  101273:	e8 78 ee ff ff       	call   1000f0 <bwrite>
        brelse(bp);
  101278:	89 34 24             	mov    %esi,(%esp)
  10127b:	e8 f0 ed ff ff       	call   100070 <brelse>
  101280:	8b 55 d4             	mov    -0x2c(%ebp),%edx
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
  101283:	83 c4 3c             	add    $0x3c,%esp
    for(bi = 0; bi < BPB; bi++){
      m = 1 << (bi % 8);
      if((bp->data[bi/8] & m) == 0){  // Is block free?
        bp->data[bi/8] |= m;  // Mark block in use on disk.
        bwrite(bp);
        brelse(bp);
  101286:	8d 04 13             	lea    (%ebx,%edx,1),%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
  101289:	5b                   	pop    %ebx
  10128a:	5e                   	pop    %esi
  10128b:	5f                   	pop    %edi
  10128c:	5d                   	pop    %ebp
  10128d:	c3                   	ret    
  10128e:	66 90                	xchg   %ax,%ax
        bwrite(bp);
        brelse(bp);
        return b + bi;
      }
    }
    brelse(bp);
  101290:	89 34 24             	mov    %esi,(%esp)
  101293:	e8 d8 ed ff ff       	call   100070 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
  101298:	81 45 d4 00 10 00 00 	addl   $0x1000,-0x2c(%ebp)
  10129f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1012a2:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  1012a5:	0f 87 6b ff ff ff    	ja     101216 <balloc+0x26>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
  1012ab:	c7 04 24 9b 65 10 00 	movl   $0x10659b,(%esp)
  1012b2:	e8 69 f6 ff ff       	call   100920 <panic>
  1012b7:	89 f6                	mov    %esi,%esi
  1012b9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

001012c0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
  1012c0:	55                   	push   %ebp
  1012c1:	89 e5                	mov    %esp,%ebp
  1012c3:	83 ec 38             	sub    $0x38,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
  1012c6:	83 fa 0b             	cmp    $0xb,%edx

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
  1012c9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  1012cc:	89 c3                	mov    %eax,%ebx
  1012ce:	89 75 f8             	mov    %esi,-0x8(%ebp)
  1012d1:	89 7d fc             	mov    %edi,-0x4(%ebp)
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
  1012d4:	77 1a                	ja     1012f0 <bmap+0x30>
    if((addr = ip->addrs[bn]) == 0)
  1012d6:	8d 7a 04             	lea    0x4(%edx),%edi
  1012d9:	8b 44 b8 0c          	mov    0xc(%eax,%edi,4),%eax
  1012dd:	85 c0                	test   %eax,%eax
  1012df:	74 5f                	je     101340 <bmap+0x80>
    brelse(bp);
    return addr;
  }

  panic("bmap: out of range");
}
  1012e1:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  1012e4:	8b 75 f8             	mov    -0x8(%ebp),%esi
  1012e7:	8b 7d fc             	mov    -0x4(%ebp),%edi
  1012ea:	89 ec                	mov    %ebp,%esp
  1012ec:	5d                   	pop    %ebp
  1012ed:	c3                   	ret    
  1012ee:	66 90                	xchg   %ax,%ax
  if(bn < NDIRECT){
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
  1012f0:	8d 7a f4             	lea    -0xc(%edx),%edi

  if(bn < NINDIRECT){
  1012f3:	83 ff 7f             	cmp    $0x7f,%edi
  1012f6:	77 64                	ja     10135c <bmap+0x9c>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
  1012f8:	8b 40 4c             	mov    0x4c(%eax),%eax
  1012fb:	85 c0                	test   %eax,%eax
  1012fd:	74 51                	je     101350 <bmap+0x90>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
  1012ff:	89 44 24 04          	mov    %eax,0x4(%esp)
  101303:	8b 03                	mov    (%ebx),%eax
  101305:	89 04 24             	mov    %eax,(%esp)
  101308:	e8 13 ee ff ff       	call   100120 <bread>
    a = (uint*)bp->data;
    if((addr = a[bn]) == 0){
  10130d:	8d 7c b8 18          	lea    0x18(%eax,%edi,4),%edi

  if(bn < NINDIRECT){
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
  101311:	89 c6                	mov    %eax,%esi
    a = (uint*)bp->data;
    if((addr = a[bn]) == 0){
  101313:	8b 07                	mov    (%edi),%eax
  101315:	85 c0                	test   %eax,%eax
  101317:	75 17                	jne    101330 <bmap+0x70>
      a[bn] = addr = balloc(ip->dev);
  101319:	8b 03                	mov    (%ebx),%eax
  10131b:	e8 d0 fe ff ff       	call   1011f0 <balloc>
  101320:	89 07                	mov    %eax,(%edi)
      bwrite(bp);
  101322:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  101325:	89 34 24             	mov    %esi,(%esp)
  101328:	e8 c3 ed ff ff       	call   1000f0 <bwrite>
  10132d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
    }
    brelse(bp);
  101330:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  101333:	89 34 24             	mov    %esi,(%esp)
  101336:	e8 35 ed ff ff       	call   100070 <brelse>
    return addr;
  10133b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10133e:	eb a1                	jmp    1012e1 <bmap+0x21>
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
  101340:	8b 03                	mov    (%ebx),%eax
  101342:	e8 a9 fe ff ff       	call   1011f0 <balloc>
  101347:	89 44 bb 0c          	mov    %eax,0xc(%ebx,%edi,4)
  10134b:	eb 94                	jmp    1012e1 <bmap+0x21>
  10134d:	8d 76 00             	lea    0x0(%esi),%esi
  bn -= NDIRECT;

  if(bn < NINDIRECT){
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
  101350:	8b 03                	mov    (%ebx),%eax
  101352:	e8 99 fe ff ff       	call   1011f0 <balloc>
  101357:	89 43 4c             	mov    %eax,0x4c(%ebx)
  10135a:	eb a3                	jmp    1012ff <bmap+0x3f>
    }
    brelse(bp);
    return addr;
  }

  panic("bmap: out of range");
  10135c:	c7 04 24 b1 65 10 00 	movl   $0x1065b1,(%esp)
  101363:	e8 b8 f5 ff ff       	call   100920 <panic>
  101368:	90                   	nop
  101369:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00101370 <readi>:
}

// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
  101370:	55                   	push   %ebp
  101371:	89 e5                	mov    %esp,%ebp
  101373:	83 ec 38             	sub    $0x38,%esp
  101376:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  101379:	8b 5d 08             	mov    0x8(%ebp),%ebx
  10137c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  10137f:	8b 4d 14             	mov    0x14(%ebp),%ecx
  101382:	89 7d fc             	mov    %edi,-0x4(%ebp)
  101385:	8b 75 10             	mov    0x10(%ebp),%esi
  101388:	8b 7d 0c             	mov    0xc(%ebp),%edi
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
  10138b:	66 83 7b 10 03       	cmpw   $0x3,0x10(%ebx)
  101390:	74 1e                	je     1013b0 <readi+0x40>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
      return -1;
    return devsw[ip->major].read(ip, dst, n);
  }

  if(off > ip->size || off + n < off)
  101392:	8b 43 18             	mov    0x18(%ebx),%eax
  101395:	39 f0                	cmp    %esi,%eax
  101397:	73 3f                	jae    1013d8 <readi+0x68>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
  101399:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  10139e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  1013a1:	8b 75 f8             	mov    -0x8(%ebp),%esi
  1013a4:	8b 7d fc             	mov    -0x4(%ebp),%edi
  1013a7:	89 ec                	mov    %ebp,%esp
  1013a9:	5d                   	pop    %ebp
  1013aa:	c3                   	ret    
  1013ab:	90                   	nop
  1013ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
{
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
  1013b0:	0f b7 43 12          	movzwl 0x12(%ebx),%eax
  1013b4:	66 83 f8 09          	cmp    $0x9,%ax
  1013b8:	77 df                	ja     101399 <readi+0x29>
  1013ba:	98                   	cwtl   
  1013bb:	8b 04 c5 80 aa 10 00 	mov    0x10aa80(,%eax,8),%eax
  1013c2:	85 c0                	test   %eax,%eax
  1013c4:	74 d3                	je     101399 <readi+0x29>
      return -1;
    return devsw[ip->major].read(ip, dst, n);
  1013c6:	89 4d 10             	mov    %ecx,0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
}
  1013c9:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  1013cc:	8b 75 f8             	mov    -0x8(%ebp),%esi
  1013cf:	8b 7d fc             	mov    -0x4(%ebp),%edi
  1013d2:	89 ec                	mov    %ebp,%esp
  1013d4:	5d                   	pop    %ebp
  struct buf *bp;

  if(ip->type == T_DEV){
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
      return -1;
    return devsw[ip->major].read(ip, dst, n);
  1013d5:	ff e0                	jmp    *%eax
  1013d7:	90                   	nop
  }

  if(off > ip->size || off + n < off)
  1013d8:	89 ca                	mov    %ecx,%edx
  1013da:	01 f2                	add    %esi,%edx
  1013dc:	72 bb                	jb     101399 <readi+0x29>
    return -1;
  if(off + n > ip->size)
  1013de:	39 d0                	cmp    %edx,%eax
  1013e0:	73 04                	jae    1013e6 <readi+0x76>
    n = ip->size - off;
  1013e2:	89 c1                	mov    %eax,%ecx
  1013e4:	29 f1                	sub    %esi,%ecx

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
  1013e6:	85 c9                	test   %ecx,%ecx
  1013e8:	74 7c                	je     101466 <readi+0xf6>
  1013ea:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
  1013f1:	89 7d e0             	mov    %edi,-0x20(%ebp)
  1013f4:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  1013f7:	90                   	nop
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
  1013f8:	89 f2                	mov    %esi,%edx
  1013fa:	89 d8                	mov    %ebx,%eax
  1013fc:	c1 ea 09             	shr    $0x9,%edx
    m = min(n - tot, BSIZE - off%BSIZE);
  1013ff:	bf 00 02 00 00       	mov    $0x200,%edi
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
  101404:	e8 b7 fe ff ff       	call   1012c0 <bmap>
  101409:	89 44 24 04          	mov    %eax,0x4(%esp)
  10140d:	8b 03                	mov    (%ebx),%eax
  10140f:	89 04 24             	mov    %eax,(%esp)
  101412:	e8 09 ed ff ff       	call   100120 <bread>
    m = min(n - tot, BSIZE - off%BSIZE);
  101417:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  10141a:	2b 4d e4             	sub    -0x1c(%ebp),%ecx
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
  10141d:	89 c2                	mov    %eax,%edx
    m = min(n - tot, BSIZE - off%BSIZE);
  10141f:	89 f0                	mov    %esi,%eax
  101421:	25 ff 01 00 00       	and    $0x1ff,%eax
  101426:	29 c7                	sub    %eax,%edi
  101428:	39 cf                	cmp    %ecx,%edi
  10142a:	76 02                	jbe    10142e <readi+0xbe>
  10142c:	89 cf                	mov    %ecx,%edi
    memmove(dst, bp->data + off%BSIZE, m);
  10142e:	8d 44 02 18          	lea    0x18(%edx,%eax,1),%eax
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
  101432:	01 fe                	add    %edi,%esi
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
  101434:	89 7c 24 08          	mov    %edi,0x8(%esp)
  101438:	89 44 24 04          	mov    %eax,0x4(%esp)
  10143c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10143f:	89 04 24             	mov    %eax,(%esp)
  101442:	89 55 d8             	mov    %edx,-0x28(%ebp)
  101445:	e8 26 28 00 00       	call   103c70 <memmove>
    brelse(bp);
  10144a:	8b 55 d8             	mov    -0x28(%ebp),%edx
  10144d:	89 14 24             	mov    %edx,(%esp)
  101450:	e8 1b ec ff ff       	call   100070 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
  101455:	01 7d e4             	add    %edi,-0x1c(%ebp)
  101458:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10145b:	01 7d e0             	add    %edi,-0x20(%ebp)
  10145e:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  101461:	77 95                	ja     1013f8 <readi+0x88>
  101463:	8b 4d dc             	mov    -0x24(%ebp),%ecx
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
  101466:	89 c8                	mov    %ecx,%eax
  101468:	e9 31 ff ff ff       	jmp    10139e <readi+0x2e>
  10146d:	8d 76 00             	lea    0x0(%esi),%esi

00101470 <iupdate>:
}

// Copy inode, which has changed, from memory to disk.
void
iupdate(struct inode *ip)
{
  101470:	55                   	push   %ebp
  101471:	89 e5                	mov    %esp,%ebp
  101473:	56                   	push   %esi
  101474:	53                   	push   %ebx
  101475:	83 ec 10             	sub    $0x10,%esp
  101478:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
  10147b:	8b 43 04             	mov    0x4(%ebx),%eax
  10147e:	c1 e8 03             	shr    $0x3,%eax
  101481:	83 c0 02             	add    $0x2,%eax
  101484:	89 44 24 04          	mov    %eax,0x4(%esp)
  101488:	8b 03                	mov    (%ebx),%eax
  10148a:	89 04 24             	mov    %eax,(%esp)
  10148d:	e8 8e ec ff ff       	call   100120 <bread>
  dip = (struct dinode*)bp->data + ip->inum%IPB;
  dip->type = ip->type;
  101492:	0f b7 53 10          	movzwl 0x10(%ebx),%edx
iupdate(struct inode *ip)
{
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
  101496:	89 c6                	mov    %eax,%esi
  dip = (struct dinode*)bp->data + ip->inum%IPB;
  101498:	8b 43 04             	mov    0x4(%ebx),%eax
  10149b:	83 e0 07             	and    $0x7,%eax
  10149e:	c1 e0 06             	shl    $0x6,%eax
  1014a1:	8d 44 06 18          	lea    0x18(%esi,%eax,1),%eax
  dip->type = ip->type;
  1014a5:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
  1014a8:	0f b7 53 12          	movzwl 0x12(%ebx),%edx
  1014ac:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
  1014b0:	0f b7 53 14          	movzwl 0x14(%ebx),%edx
  1014b4:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
  1014b8:	0f b7 53 16          	movzwl 0x16(%ebx),%edx
  1014bc:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
  1014c0:	8b 53 18             	mov    0x18(%ebx),%edx
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
  1014c3:	83 c3 1c             	add    $0x1c,%ebx
  dip = (struct dinode*)bp->data + ip->inum%IPB;
  dip->type = ip->type;
  dip->major = ip->major;
  dip->minor = ip->minor;
  dip->nlink = ip->nlink;
  dip->size = ip->size;
  1014c6:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
  1014c9:	83 c0 0c             	add    $0xc,%eax
  1014cc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  1014d0:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
  1014d7:	00 
  1014d8:	89 04 24             	mov    %eax,(%esp)
  1014db:	e8 90 27 00 00       	call   103c70 <memmove>
  bwrite(bp);
  1014e0:	89 34 24             	mov    %esi,(%esp)
  1014e3:	e8 08 ec ff ff       	call   1000f0 <bwrite>
  brelse(bp);
  1014e8:	89 75 08             	mov    %esi,0x8(%ebp)
}
  1014eb:	83 c4 10             	add    $0x10,%esp
  1014ee:	5b                   	pop    %ebx
  1014ef:	5e                   	pop    %esi
  1014f0:	5d                   	pop    %ebp
  dip->minor = ip->minor;
  dip->nlink = ip->nlink;
  dip->size = ip->size;
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
  bwrite(bp);
  brelse(bp);
  1014f1:	e9 7a eb ff ff       	jmp    100070 <brelse>
  1014f6:	8d 76 00             	lea    0x0(%esi),%esi
  1014f9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00101500 <writei>:
}

// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
  101500:	55                   	push   %ebp
  101501:	89 e5                	mov    %esp,%ebp
  101503:	83 ec 38             	sub    $0x38,%esp
  101506:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  101509:	8b 5d 08             	mov    0x8(%ebp),%ebx
  10150c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  10150f:	8b 4d 14             	mov    0x14(%ebp),%ecx
  101512:	89 7d fc             	mov    %edi,-0x4(%ebp)
  101515:	8b 75 10             	mov    0x10(%ebp),%esi
  101518:	8b 7d 0c             	mov    0xc(%ebp),%edi
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
  10151b:	66 83 7b 10 03       	cmpw   $0x3,0x10(%ebx)
  101520:	74 1e                	je     101540 <writei+0x40>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
      return -1;
    return devsw[ip->major].write(ip, src, n);
  }

  if(off > ip->size || off + n < off)
  101522:	39 73 18             	cmp    %esi,0x18(%ebx)
  101525:	73 41                	jae    101568 <writei+0x68>

  if(n > 0 && off > ip->size){
    ip->size = off;
    iupdate(ip);
  }
  return n;
  101527:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  10152c:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  10152f:	8b 75 f8             	mov    -0x8(%ebp),%esi
  101532:	8b 7d fc             	mov    -0x4(%ebp),%edi
  101535:	89 ec                	mov    %ebp,%esp
  101537:	5d                   	pop    %ebp
  101538:	c3                   	ret    
  101539:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
{
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
  101540:	0f b7 43 12          	movzwl 0x12(%ebx),%eax
  101544:	66 83 f8 09          	cmp    $0x9,%ax
  101548:	77 dd                	ja     101527 <writei+0x27>
  10154a:	98                   	cwtl   
  10154b:	8b 04 c5 84 aa 10 00 	mov    0x10aa84(,%eax,8),%eax
  101552:	85 c0                	test   %eax,%eax
  101554:	74 d1                	je     101527 <writei+0x27>
      return -1;
    return devsw[ip->major].write(ip, src, n);
  101556:	89 4d 10             	mov    %ecx,0x10(%ebp)
  if(n > 0 && off > ip->size){
    ip->size = off;
    iupdate(ip);
  }
  return n;
}
  101559:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  10155c:	8b 75 f8             	mov    -0x8(%ebp),%esi
  10155f:	8b 7d fc             	mov    -0x4(%ebp),%edi
  101562:	89 ec                	mov    %ebp,%esp
  101564:	5d                   	pop    %ebp
  struct buf *bp;

  if(ip->type == T_DEV){
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
      return -1;
    return devsw[ip->major].write(ip, src, n);
  101565:	ff e0                	jmp    *%eax
  101567:	90                   	nop
  }

  if(off > ip->size || off + n < off)
  101568:	89 c8                	mov    %ecx,%eax
  10156a:	01 f0                	add    %esi,%eax
  10156c:	72 b9                	jb     101527 <writei+0x27>
    return -1;
  if(off + n > MAXFILE*BSIZE)
  10156e:	3d 00 18 01 00       	cmp    $0x11800,%eax
  101573:	76 07                	jbe    10157c <writei+0x7c>
    n = MAXFILE*BSIZE - off;
  101575:	b9 00 18 01 00       	mov    $0x11800,%ecx
  10157a:	29 f1                	sub    %esi,%ecx

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
  10157c:	85 c9                	test   %ecx,%ecx
  10157e:	0f 84 92 00 00 00    	je     101616 <writei+0x116>
  101584:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
  10158b:	89 7d e0             	mov    %edi,-0x20(%ebp)
  10158e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  101591:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
    return -1;
  if(off + n > MAXFILE*BSIZE)
    n = MAXFILE*BSIZE - off;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
  101598:	89 f2                	mov    %esi,%edx
  10159a:	89 d8                	mov    %ebx,%eax
  10159c:	c1 ea 09             	shr    $0x9,%edx
    m = min(n - tot, BSIZE - off%BSIZE);
  10159f:	bf 00 02 00 00       	mov    $0x200,%edi
    return -1;
  if(off + n > MAXFILE*BSIZE)
    n = MAXFILE*BSIZE - off;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
  1015a4:	e8 17 fd ff ff       	call   1012c0 <bmap>
  1015a9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1015ad:	8b 03                	mov    (%ebx),%eax
  1015af:	89 04 24             	mov    %eax,(%esp)
  1015b2:	e8 69 eb ff ff       	call   100120 <bread>
    m = min(n - tot, BSIZE - off%BSIZE);
  1015b7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  1015ba:	2b 4d e4             	sub    -0x1c(%ebp),%ecx
    return -1;
  if(off + n > MAXFILE*BSIZE)
    n = MAXFILE*BSIZE - off;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
  1015bd:	89 c2                	mov    %eax,%edx
    m = min(n - tot, BSIZE - off%BSIZE);
  1015bf:	89 f0                	mov    %esi,%eax
  1015c1:	25 ff 01 00 00       	and    $0x1ff,%eax
  1015c6:	29 c7                	sub    %eax,%edi
  1015c8:	39 cf                	cmp    %ecx,%edi
  1015ca:	76 02                	jbe    1015ce <writei+0xce>
  1015cc:	89 cf                	mov    %ecx,%edi
    memmove(bp->data + off%BSIZE, src, m);
  1015ce:	89 7c 24 08          	mov    %edi,0x8(%esp)
  1015d2:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  1015d5:	8d 44 02 18          	lea    0x18(%edx,%eax,1),%eax
  1015d9:	89 04 24             	mov    %eax,(%esp)
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    n = MAXFILE*BSIZE - off;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
  1015dc:	01 fe                	add    %edi,%esi
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(bp->data + off%BSIZE, src, m);
  1015de:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  1015e2:	89 55 d8             	mov    %edx,-0x28(%ebp)
  1015e5:	e8 86 26 00 00       	call   103c70 <memmove>
    bwrite(bp);
  1015ea:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1015ed:	89 14 24             	mov    %edx,(%esp)
  1015f0:	e8 fb ea ff ff       	call   1000f0 <bwrite>
    brelse(bp);
  1015f5:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1015f8:	89 14 24             	mov    %edx,(%esp)
  1015fb:	e8 70 ea ff ff       	call   100070 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    n = MAXFILE*BSIZE - off;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
  101600:	01 7d e4             	add    %edi,-0x1c(%ebp)
  101603:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101606:	01 7d e0             	add    %edi,-0x20(%ebp)
  101609:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  10160c:	77 8a                	ja     101598 <writei+0x98>
    memmove(bp->data + off%BSIZE, src, m);
    bwrite(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
  10160e:	3b 73 18             	cmp    0x18(%ebx),%esi
  101611:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  101614:	77 07                	ja     10161d <writei+0x11d>
    ip->size = off;
    iupdate(ip);
  }
  return n;
  101616:	89 c8                	mov    %ecx,%eax
  101618:	e9 0f ff ff ff       	jmp    10152c <writei+0x2c>
    bwrite(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
    ip->size = off;
  10161d:	89 73 18             	mov    %esi,0x18(%ebx)
    iupdate(ip);
  101620:	89 1c 24             	mov    %ebx,(%esp)
  101623:	89 4d d8             	mov    %ecx,-0x28(%ebp)
  101626:	e8 45 fe ff ff       	call   101470 <iupdate>
  10162b:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  }
  return n;
  10162e:	89 c8                	mov    %ecx,%eax
  101630:	e9 f7 fe ff ff       	jmp    10152c <writei+0x2c>
  101635:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  101639:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00101640 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
  101640:	55                   	push   %ebp
  101641:	89 e5                	mov    %esp,%ebp
  101643:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
  101646:	8b 45 0c             	mov    0xc(%ebp),%eax
  101649:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
  101650:	00 
  101651:	89 44 24 04          	mov    %eax,0x4(%esp)
  101655:	8b 45 08             	mov    0x8(%ebp),%eax
  101658:	89 04 24             	mov    %eax,(%esp)
  10165b:	e8 80 26 00 00       	call   103ce0 <strncmp>
}
  101660:	c9                   	leave  
  101661:	c3                   	ret    
  101662:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  101669:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00101670 <dirlookup>:
// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
// Caller must have already locked dp.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
  101670:	55                   	push   %ebp
  101671:	89 e5                	mov    %esp,%ebp
  101673:	57                   	push   %edi
  101674:	56                   	push   %esi
  101675:	53                   	push   %ebx
  101676:	83 ec 3c             	sub    $0x3c,%esp
  101679:	8b 45 08             	mov    0x8(%ebp),%eax
  10167c:	8b 55 10             	mov    0x10(%ebp),%edx
  10167f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  101682:	89 45 dc             	mov    %eax,-0x24(%ebp)
  101685:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  uint off, inum;
  struct buf *bp;
  struct dirent *de;

  if(dp->type != T_DIR)
  101688:	66 83 78 10 01       	cmpw   $0x1,0x10(%eax)
  10168d:	0f 85 d0 00 00 00    	jne    101763 <dirlookup+0xf3>
    panic("dirlookup not DIR");
  101693:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)

  for(off = 0; off < dp->size; off += BSIZE){
  10169a:	8b 48 18             	mov    0x18(%eax),%ecx
  10169d:	85 c9                	test   %ecx,%ecx
  10169f:	0f 84 b4 00 00 00    	je     101759 <dirlookup+0xe9>
    bp = bread(dp->dev, bmap(dp, off / BSIZE));
  1016a5:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1016a8:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1016ab:	c1 ea 09             	shr    $0x9,%edx
  1016ae:	e8 0d fc ff ff       	call   1012c0 <bmap>
  1016b3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016b7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  1016ba:	8b 01                	mov    (%ecx),%eax
  1016bc:	89 04 24             	mov    %eax,(%esp)
  1016bf:	e8 5c ea ff ff       	call   100120 <bread>
  1016c4:	89 45 e4             	mov    %eax,-0x1c(%ebp)

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
// Caller must have already locked dp.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
  1016c7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += BSIZE){
    bp = bread(dp->dev, bmap(dp, off / BSIZE));
    for(de = (struct dirent*)bp->data;
  1016ca:	83 c0 18             	add    $0x18,%eax
  1016cd:	89 45 d8             	mov    %eax,-0x28(%ebp)
  1016d0:	89 c6                	mov    %eax,%esi

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
// Caller must have already locked dp.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
  1016d2:	81 c7 18 02 00 00    	add    $0x218,%edi
  1016d8:	eb 0d                	jmp    1016e7 <dirlookup+0x77>
  1016da:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

  for(off = 0; off < dp->size; off += BSIZE){
    bp = bread(dp->dev, bmap(dp, off / BSIZE));
    for(de = (struct dirent*)bp->data;
        de < (struct dirent*)(bp->data + BSIZE);
        de++){
  1016e0:	83 c6 10             	add    $0x10,%esi
  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += BSIZE){
    bp = bread(dp->dev, bmap(dp, off / BSIZE));
    for(de = (struct dirent*)bp->data;
  1016e3:	39 fe                	cmp    %edi,%esi
  1016e5:	74 51                	je     101738 <dirlookup+0xc8>
        de < (struct dirent*)(bp->data + BSIZE);
        de++){
      if(de->inum == 0)
  1016e7:	66 83 3e 00          	cmpw   $0x0,(%esi)
  1016eb:	74 f3                	je     1016e0 <dirlookup+0x70>
        continue;
      if(namecmp(name, de->name) == 0){
  1016ed:	8d 46 02             	lea    0x2(%esi),%eax
  1016f0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016f4:	89 1c 24             	mov    %ebx,(%esp)
  1016f7:	e8 44 ff ff ff       	call   101640 <namecmp>
  1016fc:	85 c0                	test   %eax,%eax
  1016fe:	75 e0                	jne    1016e0 <dirlookup+0x70>
        // entry matches path element
        if(poff)
  101700:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101703:	85 d2                	test   %edx,%edx
  101705:	74 0e                	je     101715 <dirlookup+0xa5>
          *poff = off + (uchar*)de - bp->data;
  101707:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10170a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  10170d:	8d 04 16             	lea    (%esi,%edx,1),%eax
  101710:	2b 45 d8             	sub    -0x28(%ebp),%eax
  101713:	89 01                	mov    %eax,(%ecx)
        inum = de->inum;
        brelse(bp);
  101715:	8b 45 e4             	mov    -0x1c(%ebp),%eax
        continue;
      if(namecmp(name, de->name) == 0){
        // entry matches path element
        if(poff)
          *poff = off + (uchar*)de - bp->data;
        inum = de->inum;
  101718:	0f b7 1e             	movzwl (%esi),%ebx
        brelse(bp);
  10171b:	89 04 24             	mov    %eax,(%esp)
  10171e:	e8 4d e9 ff ff       	call   100070 <brelse>
        return iget(dp->dev, inum);
  101723:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  101726:	89 da                	mov    %ebx,%edx
  101728:	8b 01                	mov    (%ecx),%eax
      }
    }
    brelse(bp);
  }
  return 0;
}
  10172a:	83 c4 3c             	add    $0x3c,%esp
  10172d:	5b                   	pop    %ebx
  10172e:	5e                   	pop    %esi
  10172f:	5f                   	pop    %edi
  101730:	5d                   	pop    %ebp
        // entry matches path element
        if(poff)
          *poff = off + (uchar*)de - bp->data;
        inum = de->inum;
        brelse(bp);
        return iget(dp->dev, inum);
  101731:	e9 aa f9 ff ff       	jmp    1010e0 <iget>
  101736:	66 90                	xchg   %ax,%ax
      }
    }
    brelse(bp);
  101738:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10173b:	89 04 24             	mov    %eax,(%esp)
  10173e:	e8 2d e9 ff ff       	call   100070 <brelse>
  struct dirent *de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += BSIZE){
  101743:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101746:	81 45 e0 00 02 00 00 	addl   $0x200,-0x20(%ebp)
  10174d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  101750:	39 4a 18             	cmp    %ecx,0x18(%edx)
  101753:	0f 87 4c ff ff ff    	ja     1016a5 <dirlookup+0x35>
      }
    }
    brelse(bp);
  }
  return 0;
}
  101759:	83 c4 3c             	add    $0x3c,%esp
  10175c:	31 c0                	xor    %eax,%eax
  10175e:	5b                   	pop    %ebx
  10175f:	5e                   	pop    %esi
  101760:	5f                   	pop    %edi
  101761:	5d                   	pop    %ebp
  101762:	c3                   	ret    
  uint off, inum;
  struct buf *bp;
  struct dirent *de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");
  101763:	c7 04 24 c4 65 10 00 	movl   $0x1065c4,(%esp)
  10176a:	e8 b1 f1 ff ff       	call   100920 <panic>
  10176f:	90                   	nop

00101770 <iunlock>:
}

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
  101770:	55                   	push   %ebp
  101771:	89 e5                	mov    %esp,%ebp
  101773:	53                   	push   %ebx
  101774:	83 ec 14             	sub    $0x14,%esp
  101777:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
  10177a:	85 db                	test   %ebx,%ebx
  10177c:	74 36                	je     1017b4 <iunlock+0x44>
  10177e:	f6 43 0c 01          	testb  $0x1,0xc(%ebx)
  101782:	74 30                	je     1017b4 <iunlock+0x44>
  101784:	8b 43 08             	mov    0x8(%ebx),%eax
  101787:	85 c0                	test   %eax,%eax
  101789:	7e 29                	jle    1017b4 <iunlock+0x44>
    panic("iunlock");

  acquire(&icache.lock);
  10178b:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  101792:	e8 b9 23 00 00       	call   103b50 <acquire>
  ip->flags &= ~I_BUSY;
  101797:	83 63 0c fe          	andl   $0xfffffffe,0xc(%ebx)
  wakeup(ip);
  10179b:	89 1c 24             	mov    %ebx,(%esp)
  10179e:	e8 ad 19 00 00       	call   103150 <wakeup>
  release(&icache.lock);
  1017a3:	c7 45 08 e0 aa 10 00 	movl   $0x10aae0,0x8(%ebp)
}
  1017aa:	83 c4 14             	add    $0x14,%esp
  1017ad:	5b                   	pop    %ebx
  1017ae:	5d                   	pop    %ebp
    panic("iunlock");

  acquire(&icache.lock);
  ip->flags &= ~I_BUSY;
  wakeup(ip);
  release(&icache.lock);
  1017af:	e9 4c 23 00 00       	jmp    103b00 <release>
// Unlock the given inode.
void
iunlock(struct inode *ip)
{
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
    panic("iunlock");
  1017b4:	c7 04 24 d6 65 10 00 	movl   $0x1065d6,(%esp)
  1017bb:	e8 60 f1 ff ff       	call   100920 <panic>

001017c0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
  1017c0:	55                   	push   %ebp
  1017c1:	89 e5                	mov    %esp,%ebp
  1017c3:	57                   	push   %edi
  1017c4:	56                   	push   %esi
  1017c5:	89 c6                	mov    %eax,%esi
  1017c7:	53                   	push   %ebx
  1017c8:	89 d3                	mov    %edx,%ebx
  1017ca:	83 ec 2c             	sub    $0x2c,%esp
static void
bzero(int dev, int bno)
{
  struct buf *bp;
  
  bp = bread(dev, bno);
  1017cd:	89 54 24 04          	mov    %edx,0x4(%esp)
  1017d1:	89 04 24             	mov    %eax,(%esp)
  1017d4:	e8 47 e9 ff ff       	call   100120 <bread>
  memset(bp->data, 0, BSIZE);
  1017d9:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
  1017e0:	00 
  1017e1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1017e8:	00 
static void
bzero(int dev, int bno)
{
  struct buf *bp;
  
  bp = bread(dev, bno);
  1017e9:	89 c7                	mov    %eax,%edi
  memset(bp->data, 0, BSIZE);
  1017eb:	8d 40 18             	lea    0x18(%eax),%eax
  1017ee:	89 04 24             	mov    %eax,(%esp)
  1017f1:	e8 fa 23 00 00       	call   103bf0 <memset>
  bwrite(bp);
  1017f6:	89 3c 24             	mov    %edi,(%esp)
  1017f9:	e8 f2 e8 ff ff       	call   1000f0 <bwrite>
  brelse(bp);
  1017fe:	89 3c 24             	mov    %edi,(%esp)
  101801:	e8 6a e8 ff ff       	call   100070 <brelse>
  struct superblock sb;
  int bi, m;

  bzero(dev, b);

  readsb(dev, &sb);
  101806:	89 f0                	mov    %esi,%eax
  101808:	8d 55 dc             	lea    -0x24(%ebp),%edx
  10180b:	e8 90 f9 ff ff       	call   1011a0 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
  101810:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101813:	89 da                	mov    %ebx,%edx
  101815:	c1 ea 0c             	shr    $0xc,%edx
  101818:	89 34 24             	mov    %esi,(%esp)
  bi = b % BPB;
  m = 1 << (bi % 8);
  10181b:	be 01 00 00 00       	mov    $0x1,%esi
  int bi, m;

  bzero(dev, b);

  readsb(dev, &sb);
  bp = bread(dev, BBLOCK(b, sb.ninodes));
  101820:	c1 e8 03             	shr    $0x3,%eax
  101823:	8d 44 10 03          	lea    0x3(%eax,%edx,1),%eax
  101827:	89 44 24 04          	mov    %eax,0x4(%esp)
  10182b:	e8 f0 e8 ff ff       	call   100120 <bread>
  bi = b % BPB;
  101830:	89 da                	mov    %ebx,%edx
  m = 1 << (bi % 8);
  101832:	89 d9                	mov    %ebx,%ecx

  bzero(dev, b);

  readsb(dev, &sb);
  bp = bread(dev, BBLOCK(b, sb.ninodes));
  bi = b % BPB;
  101834:	81 e2 ff 0f 00 00    	and    $0xfff,%edx
  m = 1 << (bi % 8);
  10183a:	83 e1 07             	and    $0x7,%ecx
  if((bp->data[bi/8] & m) == 0)
  10183d:	c1 fa 03             	sar    $0x3,%edx
  bzero(dev, b);

  readsb(dev, &sb);
  bp = bread(dev, BBLOCK(b, sb.ninodes));
  bi = b % BPB;
  m = 1 << (bi % 8);
  101840:	d3 e6                	shl    %cl,%esi
  if((bp->data[bi/8] & m) == 0)
  101842:	0f b6 4c 10 18       	movzbl 0x18(%eax,%edx,1),%ecx
  int bi, m;

  bzero(dev, b);

  readsb(dev, &sb);
  bp = bread(dev, BBLOCK(b, sb.ninodes));
  101847:	89 c7                	mov    %eax,%edi
  bi = b % BPB;
  m = 1 << (bi % 8);
  if((bp->data[bi/8] & m) == 0)
  101849:	0f b6 c1             	movzbl %cl,%eax
  10184c:	85 f0                	test   %esi,%eax
  10184e:	74 22                	je     101872 <bfree+0xb2>
    panic("freeing free block");
  bp->data[bi/8] &= ~m;  // Mark block free on disk.
  101850:	89 f0                	mov    %esi,%eax
  101852:	f7 d0                	not    %eax
  101854:	21 c8                	and    %ecx,%eax
  101856:	88 44 17 18          	mov    %al,0x18(%edi,%edx,1)
  bwrite(bp);
  10185a:	89 3c 24             	mov    %edi,(%esp)
  10185d:	e8 8e e8 ff ff       	call   1000f0 <bwrite>
  brelse(bp);
  101862:	89 3c 24             	mov    %edi,(%esp)
  101865:	e8 06 e8 ff ff       	call   100070 <brelse>
}
  10186a:	83 c4 2c             	add    $0x2c,%esp
  10186d:	5b                   	pop    %ebx
  10186e:	5e                   	pop    %esi
  10186f:	5f                   	pop    %edi
  101870:	5d                   	pop    %ebp
  101871:	c3                   	ret    
  readsb(dev, &sb);
  bp = bread(dev, BBLOCK(b, sb.ninodes));
  bi = b % BPB;
  m = 1 << (bi % 8);
  if((bp->data[bi/8] & m) == 0)
    panic("freeing free block");
  101872:	c7 04 24 de 65 10 00 	movl   $0x1065de,(%esp)
  101879:	e8 a2 f0 ff ff       	call   100920 <panic>
  10187e:	66 90                	xchg   %ax,%ax

00101880 <iput>:
}

// Caller holds reference to unlocked ip.  Drop reference.
void
iput(struct inode *ip)
{
  101880:	55                   	push   %ebp
  101881:	89 e5                	mov    %esp,%ebp
  101883:	57                   	push   %edi
  101884:	56                   	push   %esi
  101885:	53                   	push   %ebx
  101886:	83 ec 2c             	sub    $0x2c,%esp
  101889:	8b 75 08             	mov    0x8(%ebp),%esi
  acquire(&icache.lock);
  10188c:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  101893:	e8 b8 22 00 00       	call   103b50 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
  101898:	8b 46 08             	mov    0x8(%esi),%eax
  10189b:	83 f8 01             	cmp    $0x1,%eax
  10189e:	0f 85 a1 00 00 00    	jne    101945 <iput+0xc5>
  1018a4:	8b 56 0c             	mov    0xc(%esi),%edx
  1018a7:	f6 c2 02             	test   $0x2,%dl
  1018aa:	0f 84 95 00 00 00    	je     101945 <iput+0xc5>
  1018b0:	66 83 7e 16 00       	cmpw   $0x0,0x16(%esi)
  1018b5:	0f 85 8a 00 00 00    	jne    101945 <iput+0xc5>
    // inode is no longer used: truncate and free inode.
    if(ip->flags & I_BUSY)
  1018bb:	f6 c2 01             	test   $0x1,%dl
  1018be:	66 90                	xchg   %ax,%ax
  1018c0:	0f 85 f8 00 00 00    	jne    1019be <iput+0x13e>
      panic("iput busy");
    ip->flags |= I_BUSY;
  1018c6:	83 ca 01             	or     $0x1,%edx
    release(&icache.lock);
  1018c9:	89 f3                	mov    %esi,%ebx
  acquire(&icache.lock);
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
    // inode is no longer used: truncate and free inode.
    if(ip->flags & I_BUSY)
      panic("iput busy");
    ip->flags |= I_BUSY;
  1018cb:	89 56 0c             	mov    %edx,0xc(%esi)
  release(&icache.lock);
}

// Caller holds reference to unlocked ip.  Drop reference.
void
iput(struct inode *ip)
  1018ce:	8d 7e 30             	lea    0x30(%esi),%edi
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
    // inode is no longer used: truncate and free inode.
    if(ip->flags & I_BUSY)
      panic("iput busy");
    ip->flags |= I_BUSY;
    release(&icache.lock);
  1018d1:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  1018d8:	e8 23 22 00 00       	call   103b00 <release>
  1018dd:	eb 08                	jmp    1018e7 <iput+0x67>
  1018df:	90                   	nop
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    if(ip->addrs[i]){
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
  1018e0:	83 c3 04             	add    $0x4,%ebx
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
  1018e3:	39 fb                	cmp    %edi,%ebx
  1018e5:	74 1c                	je     101903 <iput+0x83>
    if(ip->addrs[i]){
  1018e7:	8b 53 1c             	mov    0x1c(%ebx),%edx
  1018ea:	85 d2                	test   %edx,%edx
  1018ec:	74 f2                	je     1018e0 <iput+0x60>
      bfree(ip->dev, ip->addrs[i]);
  1018ee:	8b 06                	mov    (%esi),%eax
  1018f0:	e8 cb fe ff ff       	call   1017c0 <bfree>
      ip->addrs[i] = 0;
  1018f5:	c7 43 1c 00 00 00 00 	movl   $0x0,0x1c(%ebx)
  1018fc:	83 c3 04             	add    $0x4,%ebx
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
  1018ff:	39 fb                	cmp    %edi,%ebx
  101901:	75 e4                	jne    1018e7 <iput+0x67>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
  101903:	8b 46 4c             	mov    0x4c(%esi),%eax
  101906:	85 c0                	test   %eax,%eax
  101908:	75 56                	jne    101960 <iput+0xe0>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
  10190a:	c7 46 18 00 00 00 00 	movl   $0x0,0x18(%esi)
  iupdate(ip);
  101911:	89 34 24             	mov    %esi,(%esp)
  101914:	e8 57 fb ff ff       	call   101470 <iupdate>
    if(ip->flags & I_BUSY)
      panic("iput busy");
    ip->flags |= I_BUSY;
    release(&icache.lock);
    itrunc(ip);
    ip->type = 0;
  101919:	66 c7 46 10 00 00    	movw   $0x0,0x10(%esi)
    iupdate(ip);
  10191f:	89 34 24             	mov    %esi,(%esp)
  101922:	e8 49 fb ff ff       	call   101470 <iupdate>
    acquire(&icache.lock);
  101927:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  10192e:	e8 1d 22 00 00       	call   103b50 <acquire>
    ip->flags = 0;
  101933:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
    wakeup(ip);
  10193a:	89 34 24             	mov    %esi,(%esp)
  10193d:	e8 0e 18 00 00       	call   103150 <wakeup>
  101942:	8b 46 08             	mov    0x8(%esi),%eax
  }
  ip->ref--;
  101945:	83 e8 01             	sub    $0x1,%eax
  101948:	89 46 08             	mov    %eax,0x8(%esi)
  release(&icache.lock);
  10194b:	c7 45 08 e0 aa 10 00 	movl   $0x10aae0,0x8(%ebp)
}
  101952:	83 c4 2c             	add    $0x2c,%esp
  101955:	5b                   	pop    %ebx
  101956:	5e                   	pop    %esi
  101957:	5f                   	pop    %edi
  101958:	5d                   	pop    %ebp
    acquire(&icache.lock);
    ip->flags = 0;
    wakeup(ip);
  }
  ip->ref--;
  release(&icache.lock);
  101959:	e9 a2 21 00 00       	jmp    103b00 <release>
  10195e:	66 90                	xchg   %ax,%ax
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
  101960:	89 44 24 04          	mov    %eax,0x4(%esp)
  101964:	8b 06                	mov    (%esi),%eax
    a = (uint*)bp->data;
  101966:	31 db                	xor    %ebx,%ebx
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
  101968:	89 04 24             	mov    %eax,(%esp)
  10196b:	e8 b0 e7 ff ff       	call   100120 <bread>
    a = (uint*)bp->data;
  101970:	89 c7                	mov    %eax,%edi
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
  101972:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    a = (uint*)bp->data;
  101975:	83 c7 18             	add    $0x18,%edi
  101978:	31 c0                	xor    %eax,%eax
  10197a:	eb 11                	jmp    10198d <iput+0x10d>
  10197c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    for(j = 0; j < NINDIRECT; j++){
  101980:	83 c3 01             	add    $0x1,%ebx
  101983:	81 fb 80 00 00 00    	cmp    $0x80,%ebx
  101989:	89 d8                	mov    %ebx,%eax
  10198b:	74 10                	je     10199d <iput+0x11d>
      if(a[j])
  10198d:	8b 14 87             	mov    (%edi,%eax,4),%edx
  101990:	85 d2                	test   %edx,%edx
  101992:	74 ec                	je     101980 <iput+0x100>
        bfree(ip->dev, a[j]);
  101994:	8b 06                	mov    (%esi),%eax
  101996:	e8 25 fe ff ff       	call   1017c0 <bfree>
  10199b:	eb e3                	jmp    101980 <iput+0x100>
    }
    brelse(bp);
  10199d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1019a0:	89 04 24             	mov    %eax,(%esp)
  1019a3:	e8 c8 e6 ff ff       	call   100070 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
  1019a8:	8b 56 4c             	mov    0x4c(%esi),%edx
  1019ab:	8b 06                	mov    (%esi),%eax
  1019ad:	e8 0e fe ff ff       	call   1017c0 <bfree>
    ip->addrs[NDIRECT] = 0;
  1019b2:	c7 46 4c 00 00 00 00 	movl   $0x0,0x4c(%esi)
  1019b9:	e9 4c ff ff ff       	jmp    10190a <iput+0x8a>
{
  acquire(&icache.lock);
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
    // inode is no longer used: truncate and free inode.
    if(ip->flags & I_BUSY)
      panic("iput busy");
  1019be:	c7 04 24 f1 65 10 00 	movl   $0x1065f1,(%esp)
  1019c5:	e8 56 ef ff ff       	call   100920 <panic>
  1019ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

001019d0 <dirlink>:
}

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
  1019d0:	55                   	push   %ebp
  1019d1:	89 e5                	mov    %esp,%ebp
  1019d3:	57                   	push   %edi
  1019d4:	56                   	push   %esi
  1019d5:	53                   	push   %ebx
  1019d6:	83 ec 2c             	sub    $0x2c,%esp
  1019d9:	8b 75 08             	mov    0x8(%ebp),%esi
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
  1019dc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1019df:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1019e6:	00 
  1019e7:	89 34 24             	mov    %esi,(%esp)
  1019ea:	89 44 24 04          	mov    %eax,0x4(%esp)
  1019ee:	e8 7d fc ff ff       	call   101670 <dirlookup>
  1019f3:	85 c0                	test   %eax,%eax
  1019f5:	0f 85 89 00 00 00    	jne    101a84 <dirlink+0xb4>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
  1019fb:	8b 56 18             	mov    0x18(%esi),%edx
  1019fe:	85 d2                	test   %edx,%edx
  101a00:	0f 84 8d 00 00 00    	je     101a93 <dirlink+0xc3>
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
    iput(ip);
    return -1;
  101a06:	8d 7d d8             	lea    -0x28(%ebp),%edi
  101a09:	31 db                	xor    %ebx,%ebx
  101a0b:	eb 0b                	jmp    101a18 <dirlink+0x48>
  101a0d:	8d 76 00             	lea    0x0(%esi),%esi
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
  101a10:	83 c3 10             	add    $0x10,%ebx
  101a13:	39 5e 18             	cmp    %ebx,0x18(%esi)
  101a16:	76 24                	jbe    101a3c <dirlink+0x6c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
  101a18:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  101a1f:	00 
  101a20:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  101a24:	89 7c 24 04          	mov    %edi,0x4(%esp)
  101a28:	89 34 24             	mov    %esi,(%esp)
  101a2b:	e8 40 f9 ff ff       	call   101370 <readi>
  101a30:	83 f8 10             	cmp    $0x10,%eax
  101a33:	75 65                	jne    101a9a <dirlink+0xca>
      panic("dirlink read");
    if(de.inum == 0)
  101a35:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
  101a3a:	75 d4                	jne    101a10 <dirlink+0x40>
      break;
  }

  strncpy(de.name, name, DIRSIZ);
  101a3c:	8b 45 0c             	mov    0xc(%ebp),%eax
  101a3f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
  101a46:	00 
  101a47:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a4b:	8d 45 da             	lea    -0x26(%ebp),%eax
  101a4e:	89 04 24             	mov    %eax,(%esp)
  101a51:	e8 ea 22 00 00       	call   103d40 <strncpy>
  de.inum = inum;
  101a56:	8b 45 10             	mov    0x10(%ebp),%eax
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
  101a59:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  101a60:	00 
  101a61:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  101a65:	89 7c 24 04          	mov    %edi,0x4(%esp)
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
  de.inum = inum;
  101a69:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
  101a6d:	89 34 24             	mov    %esi,(%esp)
  101a70:	e8 8b fa ff ff       	call   101500 <writei>
  101a75:	83 f8 10             	cmp    $0x10,%eax
  101a78:	75 2c                	jne    101aa6 <dirlink+0xd6>
    panic("dirlink");
  101a7a:	31 c0                	xor    %eax,%eax
  
  return 0;
}
  101a7c:	83 c4 2c             	add    $0x2c,%esp
  101a7f:	5b                   	pop    %ebx
  101a80:	5e                   	pop    %esi
  101a81:	5f                   	pop    %edi
  101a82:	5d                   	pop    %ebp
  101a83:	c3                   	ret    
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
    iput(ip);
  101a84:	89 04 24             	mov    %eax,(%esp)
  101a87:	e8 f4 fd ff ff       	call   101880 <iput>
  101a8c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    return -1;
  101a91:	eb e9                	jmp    101a7c <dirlink+0xac>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
  101a93:	8d 7d d8             	lea    -0x28(%ebp),%edi
  101a96:	31 db                	xor    %ebx,%ebx
  101a98:	eb a2                	jmp    101a3c <dirlink+0x6c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
  101a9a:	c7 04 24 fb 65 10 00 	movl   $0x1065fb,(%esp)
  101aa1:	e8 7a ee ff ff       	call   100920 <panic>
  }

  strncpy(de.name, name, DIRSIZ);
  de.inum = inum;
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
    panic("dirlink");
  101aa6:	c7 04 24 a2 6b 10 00 	movl   $0x106ba2,(%esp)
  101aad:	e8 6e ee ff ff       	call   100920 <panic>
  101ab2:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  101ab9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00101ac0 <iunlockput>:
}

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
  101ac0:	55                   	push   %ebp
  101ac1:	89 e5                	mov    %esp,%ebp
  101ac3:	53                   	push   %ebx
  101ac4:	83 ec 14             	sub    $0x14,%esp
  101ac7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  iunlock(ip);
  101aca:	89 1c 24             	mov    %ebx,(%esp)
  101acd:	e8 9e fc ff ff       	call   101770 <iunlock>
  iput(ip);
  101ad2:	89 5d 08             	mov    %ebx,0x8(%ebp)
}
  101ad5:	83 c4 14             	add    $0x14,%esp
  101ad8:	5b                   	pop    %ebx
  101ad9:	5d                   	pop    %ebp
// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
  iunlock(ip);
  iput(ip);
  101ada:	e9 a1 fd ff ff       	jmp    101880 <iput>
  101adf:	90                   	nop

00101ae0 <ialloc>:
static struct inode* iget(uint dev, uint inum);

// Allocate a new inode with the given type on device dev.
struct inode*
ialloc(uint dev, short type)
{
  101ae0:	55                   	push   %ebp
  101ae1:	89 e5                	mov    %esp,%ebp
  101ae3:	57                   	push   %edi
  101ae4:	56                   	push   %esi
  101ae5:	53                   	push   %ebx
  101ae6:	83 ec 3c             	sub    $0x3c,%esp
  101ae9:	0f b7 45 0c          	movzwl 0xc(%ebp),%eax
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
  101aed:	8d 55 dc             	lea    -0x24(%ebp),%edx
static struct inode* iget(uint dev, uint inum);

// Allocate a new inode with the given type on device dev.
struct inode*
ialloc(uint dev, short type)
{
  101af0:	66 89 45 d6          	mov    %ax,-0x2a(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
  101af4:	8b 45 08             	mov    0x8(%ebp),%eax
  101af7:	e8 a4 f6 ff ff       	call   1011a0 <readsb>
  for(inum = 1; inum < sb.ninodes; inum++){  // loop over inode blocks
  101afc:	83 7d e4 01          	cmpl   $0x1,-0x1c(%ebp)
  101b00:	0f 86 96 00 00 00    	jbe    101b9c <ialloc+0xbc>
  101b06:	be 01 00 00 00       	mov    $0x1,%esi
  101b0b:	bb 01 00 00 00       	mov    $0x1,%ebx
  101b10:	eb 18                	jmp    101b2a <ialloc+0x4a>
  101b12:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  101b18:	83 c3 01             	add    $0x1,%ebx
      dip->type = type;
      bwrite(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  101b1b:	89 3c 24             	mov    %edi,(%esp)
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
  for(inum = 1; inum < sb.ninodes; inum++){  // loop over inode blocks
  101b1e:	89 de                	mov    %ebx,%esi
      dip->type = type;
      bwrite(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  101b20:	e8 4b e5 ff ff       	call   100070 <brelse>
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
  for(inum = 1; inum < sb.ninodes; inum++){  // loop over inode blocks
  101b25:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
  101b28:	76 72                	jbe    101b9c <ialloc+0xbc>
    bp = bread(dev, IBLOCK(inum));
  101b2a:	89 f0                	mov    %esi,%eax
  101b2c:	c1 e8 03             	shr    $0x3,%eax
  101b2f:	83 c0 02             	add    $0x2,%eax
  101b32:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b36:	8b 45 08             	mov    0x8(%ebp),%eax
  101b39:	89 04 24             	mov    %eax,(%esp)
  101b3c:	e8 df e5 ff ff       	call   100120 <bread>
  101b41:	89 c7                	mov    %eax,%edi
    dip = (struct dinode*)bp->data + inum%IPB;
  101b43:	89 f0                	mov    %esi,%eax
  101b45:	83 e0 07             	and    $0x7,%eax
  101b48:	c1 e0 06             	shl    $0x6,%eax
  101b4b:	8d 54 07 18          	lea    0x18(%edi,%eax,1),%edx
    if(dip->type == 0){  // a free inode
  101b4f:	66 83 3a 00          	cmpw   $0x0,(%edx)
  101b53:	75 c3                	jne    101b18 <ialloc+0x38>
      memset(dip, 0, sizeof(*dip));
  101b55:	89 14 24             	mov    %edx,(%esp)
  101b58:	89 55 d0             	mov    %edx,-0x30(%ebp)
  101b5b:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
  101b62:	00 
  101b63:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101b6a:	00 
  101b6b:	e8 80 20 00 00       	call   103bf0 <memset>
      dip->type = type;
  101b70:	8b 55 d0             	mov    -0x30(%ebp),%edx
  101b73:	0f b7 45 d6          	movzwl -0x2a(%ebp),%eax
  101b77:	66 89 02             	mov    %ax,(%edx)
      bwrite(bp);   // mark it allocated on the disk
  101b7a:	89 3c 24             	mov    %edi,(%esp)
  101b7d:	e8 6e e5 ff ff       	call   1000f0 <bwrite>
      brelse(bp);
  101b82:	89 3c 24             	mov    %edi,(%esp)
  101b85:	e8 e6 e4 ff ff       	call   100070 <brelse>
      return iget(dev, inum);
  101b8a:	8b 45 08             	mov    0x8(%ebp),%eax
  101b8d:	89 f2                	mov    %esi,%edx
  101b8f:	e8 4c f5 ff ff       	call   1010e0 <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
  101b94:	83 c4 3c             	add    $0x3c,%esp
  101b97:	5b                   	pop    %ebx
  101b98:	5e                   	pop    %esi
  101b99:	5f                   	pop    %edi
  101b9a:	5d                   	pop    %ebp
  101b9b:	c3                   	ret    
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
  101b9c:	c7 04 24 08 66 10 00 	movl   $0x106608,(%esp)
  101ba3:	e8 78 ed ff ff       	call   100920 <panic>
  101ba8:	90                   	nop
  101ba9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00101bb0 <ilock>:
}

// Lock the given inode.
void
ilock(struct inode *ip)
{
  101bb0:	55                   	push   %ebp
  101bb1:	89 e5                	mov    %esp,%ebp
  101bb3:	56                   	push   %esi
  101bb4:	53                   	push   %ebx
  101bb5:	83 ec 10             	sub    $0x10,%esp
  101bb8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
  101bbb:	85 db                	test   %ebx,%ebx
  101bbd:	0f 84 e5 00 00 00    	je     101ca8 <ilock+0xf8>
  101bc3:	8b 4b 08             	mov    0x8(%ebx),%ecx
  101bc6:	85 c9                	test   %ecx,%ecx
  101bc8:	0f 8e da 00 00 00    	jle    101ca8 <ilock+0xf8>
    panic("ilock");

  acquire(&icache.lock);
  101bce:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  101bd5:	e8 76 1f 00 00       	call   103b50 <acquire>
  while(ip->flags & I_BUSY)
  101bda:	8b 43 0c             	mov    0xc(%ebx),%eax
  101bdd:	a8 01                	test   $0x1,%al
  101bdf:	74 1e                	je     101bff <ilock+0x4f>
  101be1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
    sleep(ip, &icache.lock);
  101be8:	c7 44 24 04 e0 aa 10 	movl   $0x10aae0,0x4(%esp)
  101bef:	00 
  101bf0:	89 1c 24             	mov    %ebx,(%esp)
  101bf3:	e8 78 16 00 00       	call   103270 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
  101bf8:	8b 43 0c             	mov    0xc(%ebx),%eax
  101bfb:	a8 01                	test   $0x1,%al
  101bfd:	75 e9                	jne    101be8 <ilock+0x38>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
  101bff:	83 c8 01             	or     $0x1,%eax
  101c02:	89 43 0c             	mov    %eax,0xc(%ebx)
  release(&icache.lock);
  101c05:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  101c0c:	e8 ef 1e 00 00       	call   103b00 <release>

  if(!(ip->flags & I_VALID)){
  101c11:	f6 43 0c 02          	testb  $0x2,0xc(%ebx)
  101c15:	74 09                	je     101c20 <ilock+0x70>
    brelse(bp);
    ip->flags |= I_VALID;
    if(ip->type == 0)
      panic("ilock: no type");
  }
}
  101c17:	83 c4 10             	add    $0x10,%esp
  101c1a:	5b                   	pop    %ebx
  101c1b:	5e                   	pop    %esi
  101c1c:	5d                   	pop    %ebp
  101c1d:	c3                   	ret    
  101c1e:	66 90                	xchg   %ax,%ax
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
  release(&icache.lock);

  if(!(ip->flags & I_VALID)){
    bp = bread(ip->dev, IBLOCK(ip->inum));
  101c20:	8b 43 04             	mov    0x4(%ebx),%eax
  101c23:	c1 e8 03             	shr    $0x3,%eax
  101c26:	83 c0 02             	add    $0x2,%eax
  101c29:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c2d:	8b 03                	mov    (%ebx),%eax
  101c2f:	89 04 24             	mov    %eax,(%esp)
  101c32:	e8 e9 e4 ff ff       	call   100120 <bread>
  101c37:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + ip->inum%IPB;
  101c39:	8b 43 04             	mov    0x4(%ebx),%eax
  101c3c:	83 e0 07             	and    $0x7,%eax
  101c3f:	c1 e0 06             	shl    $0x6,%eax
  101c42:	8d 44 06 18          	lea    0x18(%esi,%eax,1),%eax
    ip->type = dip->type;
  101c46:	0f b7 10             	movzwl (%eax),%edx
  101c49:	66 89 53 10          	mov    %dx,0x10(%ebx)
    ip->major = dip->major;
  101c4d:	0f b7 50 02          	movzwl 0x2(%eax),%edx
  101c51:	66 89 53 12          	mov    %dx,0x12(%ebx)
    ip->minor = dip->minor;
  101c55:	0f b7 50 04          	movzwl 0x4(%eax),%edx
  101c59:	66 89 53 14          	mov    %dx,0x14(%ebx)
    ip->nlink = dip->nlink;
  101c5d:	0f b7 50 06          	movzwl 0x6(%eax),%edx
  101c61:	66 89 53 16          	mov    %dx,0x16(%ebx)
    ip->size = dip->size;
  101c65:	8b 50 08             	mov    0x8(%eax),%edx
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
  101c68:	83 c0 0c             	add    $0xc,%eax
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    ip->type = dip->type;
    ip->major = dip->major;
    ip->minor = dip->minor;
    ip->nlink = dip->nlink;
    ip->size = dip->size;
  101c6b:	89 53 18             	mov    %edx,0x18(%ebx)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
  101c6e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c72:	8d 43 1c             	lea    0x1c(%ebx),%eax
  101c75:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
  101c7c:	00 
  101c7d:	89 04 24             	mov    %eax,(%esp)
  101c80:	e8 eb 1f 00 00       	call   103c70 <memmove>
    brelse(bp);
  101c85:	89 34 24             	mov    %esi,(%esp)
  101c88:	e8 e3 e3 ff ff       	call   100070 <brelse>
    ip->flags |= I_VALID;
  101c8d:	83 4b 0c 02          	orl    $0x2,0xc(%ebx)
    if(ip->type == 0)
  101c91:	66 83 7b 10 00       	cmpw   $0x0,0x10(%ebx)
  101c96:	0f 85 7b ff ff ff    	jne    101c17 <ilock+0x67>
      panic("ilock: no type");
  101c9c:	c7 04 24 20 66 10 00 	movl   $0x106620,(%esp)
  101ca3:	e8 78 ec ff ff       	call   100920 <panic>
{
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
    panic("ilock");
  101ca8:	c7 04 24 1a 66 10 00 	movl   $0x10661a,(%esp)
  101caf:	e8 6c ec ff ff       	call   100920 <panic>
  101cb4:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  101cba:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

00101cc0 <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
  101cc0:	55                   	push   %ebp
  101cc1:	89 e5                	mov    %esp,%ebp
  101cc3:	57                   	push   %edi
  101cc4:	56                   	push   %esi
  101cc5:	53                   	push   %ebx
  101cc6:	89 c3                	mov    %eax,%ebx
  101cc8:	83 ec 2c             	sub    $0x2c,%esp
  101ccb:	89 55 e0             	mov    %edx,-0x20(%ebp)
  101cce:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  struct inode *ip, *next;

  if(*path == '/')
  101cd1:	80 38 2f             	cmpb   $0x2f,(%eax)
  101cd4:	0f 84 14 01 00 00    	je     101dee <namex+0x12e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
  101cda:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  101ce0:	8b 40 68             	mov    0x68(%eax),%eax
  101ce3:	89 04 24             	mov    %eax,(%esp)
  101ce6:	e8 c5 f3 ff ff       	call   1010b0 <idup>
  101ceb:	89 c7                	mov    %eax,%edi
  101ced:	eb 04                	jmp    101cf3 <namex+0x33>
  101cef:	90                   	nop
{
  char *s;
  int len;

  while(*path == '/')
    path++;
  101cf0:	83 c3 01             	add    $0x1,%ebx
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
  101cf3:	0f b6 03             	movzbl (%ebx),%eax
  101cf6:	3c 2f                	cmp    $0x2f,%al
  101cf8:	74 f6                	je     101cf0 <namex+0x30>
    path++;
  if(*path == 0)
  101cfa:	84 c0                	test   %al,%al
  101cfc:	75 1a                	jne    101d18 <namex+0x58>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
  101cfe:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  101d01:	85 db                	test   %ebx,%ebx
  101d03:	0f 85 0d 01 00 00    	jne    101e16 <namex+0x156>
    iput(ip);
    return 0;
  }
  return ip;
}
  101d09:	83 c4 2c             	add    $0x2c,%esp
  101d0c:	89 f8                	mov    %edi,%eax
  101d0e:	5b                   	pop    %ebx
  101d0f:	5e                   	pop    %esi
  101d10:	5f                   	pop    %edi
  101d11:	5d                   	pop    %ebp
  101d12:	c3                   	ret    
  101d13:	90                   	nop
  101d14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
  101d18:	3c 2f                	cmp    $0x2f,%al
  101d1a:	0f 84 94 00 00 00    	je     101db4 <namex+0xf4>
  101d20:	89 de                	mov    %ebx,%esi
  101d22:	eb 08                	jmp    101d2c <namex+0x6c>
  101d24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  101d28:	3c 2f                	cmp    $0x2f,%al
  101d2a:	74 0a                	je     101d36 <namex+0x76>
    path++;
  101d2c:	83 c6 01             	add    $0x1,%esi
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
  101d2f:	0f b6 06             	movzbl (%esi),%eax
  101d32:	84 c0                	test   %al,%al
  101d34:	75 f2                	jne    101d28 <namex+0x68>
  101d36:	89 f2                	mov    %esi,%edx
  101d38:	29 da                	sub    %ebx,%edx
    path++;
  len = path - s;
  if(len >= DIRSIZ)
  101d3a:	83 fa 0d             	cmp    $0xd,%edx
  101d3d:	7e 79                	jle    101db8 <namex+0xf8>
    memmove(name, s, DIRSIZ);
  101d3f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
  101d46:	00 
  101d47:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  101d4b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101d4e:	89 04 24             	mov    %eax,(%esp)
  101d51:	e8 1a 1f 00 00       	call   103c70 <memmove>
  101d56:	eb 03                	jmp    101d5b <namex+0x9b>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
    path++;
  101d58:	83 c6 01             	add    $0x1,%esi
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
  101d5b:	80 3e 2f             	cmpb   $0x2f,(%esi)
  101d5e:	74 f8                	je     101d58 <namex+0x98>
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
  101d60:	85 f6                	test   %esi,%esi
  101d62:	74 9a                	je     101cfe <namex+0x3e>
    ilock(ip);
  101d64:	89 3c 24             	mov    %edi,(%esp)
  101d67:	e8 44 fe ff ff       	call   101bb0 <ilock>
    if(ip->type != T_DIR){
  101d6c:	66 83 7f 10 01       	cmpw   $0x1,0x10(%edi)
  101d71:	75 67                	jne    101dda <namex+0x11a>
      iunlockput(ip);
      return 0;
    }
    if(nameiparent && *path == '\0'){
  101d73:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101d76:	85 c0                	test   %eax,%eax
  101d78:	74 0c                	je     101d86 <namex+0xc6>
  101d7a:	80 3e 00             	cmpb   $0x0,(%esi)
  101d7d:	8d 76 00             	lea    0x0(%esi),%esi
  101d80:	0f 84 7e 00 00 00    	je     101e04 <namex+0x144>
      // Stop one level early.
      iunlock(ip);
      return ip;
    }
    if((next = dirlookup(ip, name, 0)) == 0){
  101d86:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  101d8d:	00 
  101d8e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101d91:	89 3c 24             	mov    %edi,(%esp)
  101d94:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d98:	e8 d3 f8 ff ff       	call   101670 <dirlookup>
  101d9d:	85 c0                	test   %eax,%eax
  101d9f:	89 c3                	mov    %eax,%ebx
  101da1:	74 37                	je     101dda <namex+0x11a>
      iunlockput(ip);
      return 0;
    }
    iunlockput(ip);
  101da3:	89 3c 24             	mov    %edi,(%esp)
  101da6:	89 df                	mov    %ebx,%edi
  101da8:	89 f3                	mov    %esi,%ebx
  101daa:	e8 11 fd ff ff       	call   101ac0 <iunlockput>
  101daf:	e9 3f ff ff ff       	jmp    101cf3 <namex+0x33>
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
  101db4:	89 de                	mov    %ebx,%esi
  101db6:	31 d2                	xor    %edx,%edx
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
  101db8:	89 54 24 08          	mov    %edx,0x8(%esp)
  101dbc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  101dc0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101dc3:	89 04 24             	mov    %eax,(%esp)
  101dc6:	89 55 dc             	mov    %edx,-0x24(%ebp)
  101dc9:	e8 a2 1e 00 00       	call   103c70 <memmove>
    name[len] = 0;
  101dce:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101dd1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101dd4:	c6 04 10 00          	movb   $0x0,(%eax,%edx,1)
  101dd8:	eb 81                	jmp    101d5b <namex+0x9b>
      // Stop one level early.
      iunlock(ip);
      return ip;
    }
    if((next = dirlookup(ip, name, 0)) == 0){
      iunlockput(ip);
  101dda:	89 3c 24             	mov    %edi,(%esp)
  101ddd:	31 ff                	xor    %edi,%edi
  101ddf:	e8 dc fc ff ff       	call   101ac0 <iunlockput>
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
  101de4:	83 c4 2c             	add    $0x2c,%esp
  101de7:	89 f8                	mov    %edi,%eax
  101de9:	5b                   	pop    %ebx
  101dea:	5e                   	pop    %esi
  101deb:	5f                   	pop    %edi
  101dec:	5d                   	pop    %ebp
  101ded:	c3                   	ret    
namex(char *path, int nameiparent, char *name)
{
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  101dee:	ba 01 00 00 00       	mov    $0x1,%edx
  101df3:	b8 01 00 00 00       	mov    $0x1,%eax
  101df8:	e8 e3 f2 ff ff       	call   1010e0 <iget>
  101dfd:	89 c7                	mov    %eax,%edi
  101dff:	e9 ef fe ff ff       	jmp    101cf3 <namex+0x33>
      iunlockput(ip);
      return 0;
    }
    if(nameiparent && *path == '\0'){
      // Stop one level early.
      iunlock(ip);
  101e04:	89 3c 24             	mov    %edi,(%esp)
  101e07:	e8 64 f9 ff ff       	call   101770 <iunlock>
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
  101e0c:	83 c4 2c             	add    $0x2c,%esp
  101e0f:	89 f8                	mov    %edi,%eax
  101e11:	5b                   	pop    %ebx
  101e12:	5e                   	pop    %esi
  101e13:	5f                   	pop    %edi
  101e14:	5d                   	pop    %ebp
  101e15:	c3                   	ret    
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
    iput(ip);
  101e16:	89 3c 24             	mov    %edi,(%esp)
  101e19:	31 ff                	xor    %edi,%edi
  101e1b:	e8 60 fa ff ff       	call   101880 <iput>
    return 0;
  101e20:	e9 e4 fe ff ff       	jmp    101d09 <namex+0x49>
  101e25:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  101e29:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00101e30 <nameiparent>:
  return namex(path, 0, name);
}

struct inode*
nameiparent(char *path, char *name)
{
  101e30:	55                   	push   %ebp
  return namex(path, 1, name);
  101e31:	ba 01 00 00 00       	mov    $0x1,%edx
  return namex(path, 0, name);
}

struct inode*
nameiparent(char *path, char *name)
{
  101e36:	89 e5                	mov    %esp,%ebp
  101e38:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
  101e3b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  101e3e:	8b 45 08             	mov    0x8(%ebp),%eax
}
  101e41:	c9                   	leave  
}

struct inode*
nameiparent(char *path, char *name)
{
  return namex(path, 1, name);
  101e42:	e9 79 fe ff ff       	jmp    101cc0 <namex>
  101e47:	89 f6                	mov    %esi,%esi
  101e49:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00101e50 <namei>:
  return ip;
}

struct inode*
namei(char *path)
{
  101e50:	55                   	push   %ebp
  char name[DIRSIZ];
  return namex(path, 0, name);
  101e51:	31 d2                	xor    %edx,%edx
  return ip;
}

struct inode*
namei(char *path)
{
  101e53:	89 e5                	mov    %esp,%ebp
  101e55:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
  101e58:	8b 45 08             	mov    0x8(%ebp),%eax
  101e5b:	8d 4d ea             	lea    -0x16(%ebp),%ecx
  101e5e:	e8 5d fe ff ff       	call   101cc0 <namex>
}
  101e63:	c9                   	leave  
  101e64:	c3                   	ret    
  101e65:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  101e69:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00101e70 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
  101e70:	55                   	push   %ebp
  101e71:	89 e5                	mov    %esp,%ebp
  101e73:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
  101e76:	c7 44 24 04 2f 66 10 	movl   $0x10662f,0x4(%esp)
  101e7d:	00 
  101e7e:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  101e85:	e8 36 1b 00 00       	call   1039c0 <initlock>
}
  101e8a:	c9                   	leave  
  101e8b:	c3                   	ret    
  101e8c:	90                   	nop
  101e8d:	90                   	nop
  101e8e:	90                   	nop
  101e8f:	90                   	nop

00101e90 <idestart>:
}

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
  101e90:	55                   	push   %ebp
  101e91:	89 e5                	mov    %esp,%ebp
  101e93:	56                   	push   %esi
  101e94:	89 c6                	mov    %eax,%esi
  101e96:	83 ec 14             	sub    $0x14,%esp
  if(b == 0)
  101e99:	85 c0                	test   %eax,%eax
  101e9b:	0f 84 8d 00 00 00    	je     101f2e <idestart+0x9e>
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  101ea1:	ba f7 01 00 00       	mov    $0x1f7,%edx
  101ea6:	66 90                	xchg   %ax,%ax
  101ea8:	ec                   	in     (%dx),%al
static int
idewait(int checkerr)
{
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
  101ea9:	25 c0 00 00 00       	and    $0xc0,%eax
  101eae:	83 f8 40             	cmp    $0x40,%eax
  101eb1:	75 f5                	jne    101ea8 <idestart+0x18>
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  101eb3:	ba f6 03 00 00       	mov    $0x3f6,%edx
  101eb8:	31 c0                	xor    %eax,%eax
  101eba:	ee                   	out    %al,(%dx)
  101ebb:	ba f2 01 00 00       	mov    $0x1f2,%edx
  101ec0:	b8 01 00 00 00       	mov    $0x1,%eax
  101ec5:	ee                   	out    %al,(%dx)
    panic("idestart");

  idewait(0);
  outb(0x3f6, 0);  // generate interrupt
  outb(0x1f2, 1);  // number of sectors
  outb(0x1f3, b->sector & 0xff);
  101ec6:	8b 4e 08             	mov    0x8(%esi),%ecx
  101ec9:	b2 f3                	mov    $0xf3,%dl
  101ecb:	89 c8                	mov    %ecx,%eax
  101ecd:	ee                   	out    %al,(%dx)
  101ece:	89 c8                	mov    %ecx,%eax
  101ed0:	b2 f4                	mov    $0xf4,%dl
  101ed2:	c1 e8 08             	shr    $0x8,%eax
  101ed5:	ee                   	out    %al,(%dx)
  101ed6:	89 c8                	mov    %ecx,%eax
  101ed8:	b2 f5                	mov    $0xf5,%dl
  101eda:	c1 e8 10             	shr    $0x10,%eax
  101edd:	ee                   	out    %al,(%dx)
  101ede:	8b 46 04             	mov    0x4(%esi),%eax
  101ee1:	c1 e9 18             	shr    $0x18,%ecx
  101ee4:	b2 f6                	mov    $0xf6,%dl
  101ee6:	83 e1 0f             	and    $0xf,%ecx
  101ee9:	83 e0 01             	and    $0x1,%eax
  101eec:	c1 e0 04             	shl    $0x4,%eax
  101eef:	09 c8                	or     %ecx,%eax
  101ef1:	83 c8 e0             	or     $0xffffffe0,%eax
  101ef4:	ee                   	out    %al,(%dx)
  outb(0x1f4, (b->sector >> 8) & 0xff);
  outb(0x1f5, (b->sector >> 16) & 0xff);
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
  if(b->flags & B_DIRTY){
  101ef5:	f6 06 04             	testb  $0x4,(%esi)
  101ef8:	75 16                	jne    101f10 <idestart+0x80>
  101efa:	ba f7 01 00 00       	mov    $0x1f7,%edx
  101eff:	b8 20 00 00 00       	mov    $0x20,%eax
  101f04:	ee                   	out    %al,(%dx)
    outb(0x1f7, IDE_CMD_WRITE);
    outsl(0x1f0, b->data, 512/4);
  } else {
    outb(0x1f7, IDE_CMD_READ);
  }
}
  101f05:	83 c4 14             	add    $0x14,%esp
  101f08:	5e                   	pop    %esi
  101f09:	5d                   	pop    %ebp
  101f0a:	c3                   	ret    
  101f0b:	90                   	nop
  101f0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  101f10:	b2 f7                	mov    $0xf7,%dl
  101f12:	b8 30 00 00 00       	mov    $0x30,%eax
  101f17:	ee                   	out    %al,(%dx)
}

static inline void
outsl(int port, const void *addr, int cnt)
{
  asm volatile("cld; rep outsl" :
  101f18:	b9 80 00 00 00       	mov    $0x80,%ecx
  101f1d:	83 c6 18             	add    $0x18,%esi
  101f20:	ba f0 01 00 00       	mov    $0x1f0,%edx
  101f25:	fc                   	cld    
  101f26:	f3 6f                	rep outsl %ds:(%esi),(%dx)
  101f28:	83 c4 14             	add    $0x14,%esp
  101f2b:	5e                   	pop    %esi
  101f2c:	5d                   	pop    %ebp
  101f2d:	c3                   	ret    
// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
  if(b == 0)
    panic("idestart");
  101f2e:	c7 04 24 36 66 10 00 	movl   $0x106636,(%esp)
  101f35:	e8 e6 e9 ff ff       	call   100920 <panic>
  101f3a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

00101f40 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
  101f40:	55                   	push   %ebp
  101f41:	89 e5                	mov    %esp,%ebp
  101f43:	53                   	push   %ebx
  101f44:	83 ec 14             	sub    $0x14,%esp
  101f47:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf **pp;

  if(!(b->flags & B_BUSY))
  101f4a:	8b 03                	mov    (%ebx),%eax
  101f4c:	a8 01                	test   $0x1,%al
  101f4e:	0f 84 90 00 00 00    	je     101fe4 <iderw+0xa4>
    panic("iderw: buf not busy");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
  101f54:	83 e0 06             	and    $0x6,%eax
  101f57:	83 f8 02             	cmp    $0x2,%eax
  101f5a:	0f 84 9c 00 00 00    	je     101ffc <iderw+0xbc>
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
  101f60:	8b 53 04             	mov    0x4(%ebx),%edx
  101f63:	85 d2                	test   %edx,%edx
  101f65:	74 0d                	je     101f74 <iderw+0x34>
  101f67:	a1 b8 78 10 00       	mov    0x1078b8,%eax
  101f6c:	85 c0                	test   %eax,%eax
  101f6e:	0f 84 7c 00 00 00    	je     101ff0 <iderw+0xb0>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);
  101f74:	c7 04 24 80 78 10 00 	movl   $0x107880,(%esp)
  101f7b:	e8 d0 1b 00 00       	call   103b50 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)
  101f80:	ba b4 78 10 00       	mov    $0x1078b4,%edx
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);

  // Append b to idequeue.
  b->qnext = 0;
  101f85:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  101f8c:	a1 b4 78 10 00       	mov    0x1078b4,%eax
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)
  101f91:	85 c0                	test   %eax,%eax
  101f93:	74 0d                	je     101fa2 <iderw+0x62>
  101f95:	8d 76 00             	lea    0x0(%esi),%esi
  101f98:	8d 50 14             	lea    0x14(%eax),%edx
  101f9b:	8b 40 14             	mov    0x14(%eax),%eax
  101f9e:	85 c0                	test   %eax,%eax
  101fa0:	75 f6                	jne    101f98 <iderw+0x58>
    ;
  *pp = b;
  101fa2:	89 1a                	mov    %ebx,(%edx)
  
  // Start disk if necessary.
  if(idequeue == b)
  101fa4:	39 1d b4 78 10 00    	cmp    %ebx,0x1078b4
  101faa:	75 14                	jne    101fc0 <iderw+0x80>
  101fac:	eb 2d                	jmp    101fdb <iderw+0x9b>
  101fae:	66 90                	xchg   %ax,%ax
    idestart(b);
  
  // Wait for request to finish.
  // Assuming will not sleep too long: ignore proc->killed.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
  101fb0:	c7 44 24 04 80 78 10 	movl   $0x107880,0x4(%esp)
  101fb7:	00 
  101fb8:	89 1c 24             	mov    %ebx,(%esp)
  101fbb:	e8 b0 12 00 00       	call   103270 <sleep>
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  // Assuming will not sleep too long: ignore proc->killed.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
  101fc0:	8b 03                	mov    (%ebx),%eax
  101fc2:	83 e0 06             	and    $0x6,%eax
  101fc5:	83 f8 02             	cmp    $0x2,%eax
  101fc8:	75 e6                	jne    101fb0 <iderw+0x70>
    sleep(b, &idelock);
  }

  release(&idelock);
  101fca:	c7 45 08 80 78 10 00 	movl   $0x107880,0x8(%ebp)
}
  101fd1:	83 c4 14             	add    $0x14,%esp
  101fd4:	5b                   	pop    %ebx
  101fd5:	5d                   	pop    %ebp
  // Assuming will not sleep too long: ignore proc->killed.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
  }

  release(&idelock);
  101fd6:	e9 25 1b 00 00       	jmp    103b00 <release>
    ;
  *pp = b;
  
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  101fdb:	89 d8                	mov    %ebx,%eax
  101fdd:	e8 ae fe ff ff       	call   101e90 <idestart>
  101fe2:	eb dc                	jmp    101fc0 <iderw+0x80>
iderw(struct buf *b)
{
  struct buf **pp;

  if(!(b->flags & B_BUSY))
    panic("iderw: buf not busy");
  101fe4:	c7 04 24 3f 66 10 00 	movl   $0x10663f,(%esp)
  101feb:	e8 30 e9 ff ff       	call   100920 <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
    panic("iderw: ide disk 1 not present");
  101ff0:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  101ff7:	e8 24 e9 ff ff       	call   100920 <panic>
  struct buf **pp;

  if(!(b->flags & B_BUSY))
    panic("iderw: buf not busy");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
    panic("iderw: nothing to do");
  101ffc:	c7 04 24 53 66 10 00 	movl   $0x106653,(%esp)
  102003:	e8 18 e9 ff ff       	call   100920 <panic>
  102008:	90                   	nop
  102009:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00102010 <ideintr>:
}

// Interrupt handler.
void
ideintr(void)
{
  102010:	55                   	push   %ebp
  102011:	89 e5                	mov    %esp,%ebp
  102013:	57                   	push   %edi
  102014:	53                   	push   %ebx
  102015:	83 ec 10             	sub    $0x10,%esp
  struct buf *b;

  // Take first buffer off queue.
  acquire(&idelock);
  102018:	c7 04 24 80 78 10 00 	movl   $0x107880,(%esp)
  10201f:	e8 2c 1b 00 00       	call   103b50 <acquire>
  if((b = idequeue) == 0){
  102024:	8b 1d b4 78 10 00    	mov    0x1078b4,%ebx
  10202a:	85 db                	test   %ebx,%ebx
  10202c:	74 2d                	je     10205b <ideintr+0x4b>
    release(&idelock);
    // cprintf("spurious IDE interrupt\n");
    return;
  }
  idequeue = b->qnext;
  10202e:	8b 43 14             	mov    0x14(%ebx),%eax
  102031:	a3 b4 78 10 00       	mov    %eax,0x1078b4

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
  102036:	8b 0b                	mov    (%ebx),%ecx
  102038:	f6 c1 04             	test   $0x4,%cl
  10203b:	74 33                	je     102070 <ideintr+0x60>
    insl(0x1f0, b->data, 512/4);
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
  b->flags &= ~B_DIRTY;
  10203d:	83 c9 02             	or     $0x2,%ecx
  102040:	83 e1 fb             	and    $0xfffffffb,%ecx
  102043:	89 0b                	mov    %ecx,(%ebx)
  wakeup(b);
  102045:	89 1c 24             	mov    %ebx,(%esp)
  102048:	e8 03 11 00 00       	call   103150 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
  10204d:	a1 b4 78 10 00       	mov    0x1078b4,%eax
  102052:	85 c0                	test   %eax,%eax
  102054:	74 05                	je     10205b <ideintr+0x4b>
    idestart(idequeue);
  102056:	e8 35 fe ff ff       	call   101e90 <idestart>

  release(&idelock);
  10205b:	c7 04 24 80 78 10 00 	movl   $0x107880,(%esp)
  102062:	e8 99 1a 00 00       	call   103b00 <release>
}
  102067:	83 c4 10             	add    $0x10,%esp
  10206a:	5b                   	pop    %ebx
  10206b:	5f                   	pop    %edi
  10206c:	5d                   	pop    %ebp
  10206d:	c3                   	ret    
  10206e:	66 90                	xchg   %ax,%ax
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  102070:	ba f7 01 00 00       	mov    $0x1f7,%edx
  102075:	8d 76 00             	lea    0x0(%esi),%esi
  102078:	ec                   	in     (%dx),%al
static int
idewait(int checkerr)
{
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
  102079:	0f b6 c0             	movzbl %al,%eax
  10207c:	89 c7                	mov    %eax,%edi
  10207e:	81 e7 c0 00 00 00    	and    $0xc0,%edi
  102084:	83 ff 40             	cmp    $0x40,%edi
  102087:	75 ef                	jne    102078 <ideintr+0x68>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
  102089:	a8 21                	test   $0x21,%al
  10208b:	75 b0                	jne    10203d <ideintr+0x2d>
}

static inline void
insl(int port, void *addr, int cnt)
{
  asm volatile("cld; rep insl" :
  10208d:	8d 7b 18             	lea    0x18(%ebx),%edi
  102090:	b9 80 00 00 00       	mov    $0x80,%ecx
  102095:	ba f0 01 00 00       	mov    $0x1f0,%edx
  10209a:	fc                   	cld    
  10209b:	f3 6d                	rep insl (%dx),%es:(%edi)
  10209d:	8b 0b                	mov    (%ebx),%ecx
  10209f:	eb 9c                	jmp    10203d <ideintr+0x2d>
  1020a1:	eb 0d                	jmp    1020b0 <ideinit>
  1020a3:	90                   	nop
  1020a4:	90                   	nop
  1020a5:	90                   	nop
  1020a6:	90                   	nop
  1020a7:	90                   	nop
  1020a8:	90                   	nop
  1020a9:	90                   	nop
  1020aa:	90                   	nop
  1020ab:	90                   	nop
  1020ac:	90                   	nop
  1020ad:	90                   	nop
  1020ae:	90                   	nop
  1020af:	90                   	nop

001020b0 <ideinit>:
  return 0;
}

void
ideinit(void)
{
  1020b0:	55                   	push   %ebp
  1020b1:	89 e5                	mov    %esp,%ebp
  1020b3:	83 ec 18             	sub    $0x18,%esp
  int i;

  initlock(&idelock, "ide");
  1020b6:	c7 44 24 04 86 66 10 	movl   $0x106686,0x4(%esp)
  1020bd:	00 
  1020be:	c7 04 24 80 78 10 00 	movl   $0x107880,(%esp)
  1020c5:	e8 f6 18 00 00       	call   1039c0 <initlock>
  picenable(IRQ_IDE);
  1020ca:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
  1020d1:	e8 da 0a 00 00       	call   102bb0 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
  1020d6:	a1 00 c1 10 00       	mov    0x10c100,%eax
  1020db:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
  1020e2:	83 e8 01             	sub    $0x1,%eax
  1020e5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1020e9:	e8 52 00 00 00       	call   102140 <ioapicenable>
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  1020ee:	ba f7 01 00 00       	mov    $0x1f7,%edx
  1020f3:	90                   	nop
  1020f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1020f8:	ec                   	in     (%dx),%al
static int
idewait(int checkerr)
{
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
  1020f9:	25 c0 00 00 00       	and    $0xc0,%eax
  1020fe:	83 f8 40             	cmp    $0x40,%eax
  102101:	75 f5                	jne    1020f8 <ideinit+0x48>
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  102103:	ba f6 01 00 00       	mov    $0x1f6,%edx
  102108:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  10210d:	ee                   	out    %al,(%dx)
  10210e:	31 c9                	xor    %ecx,%ecx
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  102110:	b2 f7                	mov    $0xf7,%dl
  102112:	eb 0f                	jmp    102123 <ideinit+0x73>
  102114:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
  102118:	83 c1 01             	add    $0x1,%ecx
  10211b:	81 f9 e8 03 00 00    	cmp    $0x3e8,%ecx
  102121:	74 0f                	je     102132 <ideinit+0x82>
  102123:	ec                   	in     (%dx),%al
    if(inb(0x1f7) != 0){
  102124:	84 c0                	test   %al,%al
  102126:	74 f0                	je     102118 <ideinit+0x68>
      havedisk1 = 1;
  102128:	c7 05 b8 78 10 00 01 	movl   $0x1,0x1078b8
  10212f:	00 00 00 
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  102132:	ba f6 01 00 00       	mov    $0x1f6,%edx
  102137:	b8 e0 ff ff ff       	mov    $0xffffffe0,%eax
  10213c:	ee                   	out    %al,(%dx)
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
}
  10213d:	c9                   	leave  
  10213e:	c3                   	ret    
  10213f:	90                   	nop

00102140 <ioapicenable>:
}

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
  102140:	8b 15 04 bb 10 00    	mov    0x10bb04,%edx
  }
}

void
ioapicenable(int irq, int cpunum)
{
  102146:	55                   	push   %ebp
  102147:	89 e5                	mov    %esp,%ebp
  102149:	8b 45 08             	mov    0x8(%ebp),%eax
  if(!ismp)
  10214c:	85 d2                	test   %edx,%edx
  10214e:	74 31                	je     102181 <ioapicenable+0x41>
}

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  102150:	8b 15 b4 ba 10 00    	mov    0x10bab4,%edx
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  102156:	8d 48 20             	lea    0x20(%eax),%ecx
  102159:	8d 44 00 10          	lea    0x10(%eax,%eax,1),%eax
}

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  10215d:	89 02                	mov    %eax,(%edx)
  ioapic->data = data;
  10215f:	8b 15 b4 ba 10 00    	mov    0x10bab4,%edx
}

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  102165:	83 c0 01             	add    $0x1,%eax
  ioapic->data = data;
  102168:	89 4a 10             	mov    %ecx,0x10(%edx)
}

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  10216b:	8b 0d b4 ba 10 00    	mov    0x10bab4,%ecx

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
  102171:	8b 55 0c             	mov    0xc(%ebp),%edx
}

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  102174:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
  102176:	a1 b4 ba 10 00       	mov    0x10bab4,%eax

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
  10217b:	c1 e2 18             	shl    $0x18,%edx

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  ioapic->data = data;
  10217e:	89 50 10             	mov    %edx,0x10(%eax)
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
  102181:	5d                   	pop    %ebp
  102182:	c3                   	ret    
  102183:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  102189:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00102190 <ioapicinit>:
  ioapic->data = data;
}

void
ioapicinit(void)
{
  102190:	55                   	push   %ebp
  102191:	89 e5                	mov    %esp,%ebp
  102193:	56                   	push   %esi
  102194:	53                   	push   %ebx
  102195:	83 ec 10             	sub    $0x10,%esp
  int i, id, maxintr;

  if(!ismp)
  102198:	8b 0d 04 bb 10 00    	mov    0x10bb04,%ecx
  10219e:	85 c9                	test   %ecx,%ecx
  1021a0:	0f 84 9e 00 00 00    	je     102244 <ioapicinit+0xb4>
};

static uint
ioapicread(int reg)
{
  ioapic->reg = reg;
  1021a6:	c7 05 00 00 c0 fe 01 	movl   $0x1,0xfec00000
  1021ad:	00 00 00 
  return ioapic->data;
  1021b0:	8b 35 10 00 c0 fe    	mov    0xfec00010,%esi
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
  id = ioapicread(REG_ID) >> 24;
  if(id != ioapicid)
  1021b6:	bb 00 00 c0 fe       	mov    $0xfec00000,%ebx
};

static uint
ioapicread(int reg)
{
  ioapic->reg = reg;
  1021bb:	c7 05 00 00 c0 fe 00 	movl   $0x0,0xfec00000
  1021c2:	00 00 00 
  return ioapic->data;
  1021c5:	a1 10 00 c0 fe       	mov    0xfec00010,%eax
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
  id = ioapicread(REG_ID) >> 24;
  if(id != ioapicid)
  1021ca:	0f b6 15 00 bb 10 00 	movzbl 0x10bb00,%edx
  int i, id, maxintr;

  if(!ismp)
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
  1021d1:	c7 05 b4 ba 10 00 00 	movl   $0xfec00000,0x10bab4
  1021d8:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
  1021db:	c1 ee 10             	shr    $0x10,%esi
  id = ioapicread(REG_ID) >> 24;
  if(id != ioapicid)
  1021de:	c1 e8 18             	shr    $0x18,%eax

  if(!ismp)
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
  1021e1:	81 e6 ff 00 00 00    	and    $0xff,%esi
  id = ioapicread(REG_ID) >> 24;
  if(id != ioapicid)
  1021e7:	39 c2                	cmp    %eax,%edx
  1021e9:	74 12                	je     1021fd <ioapicinit+0x6d>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
  1021eb:	c7 04 24 8c 66 10 00 	movl   $0x10668c,(%esp)
  1021f2:	e8 39 e3 ff ff       	call   100530 <cprintf>
  1021f7:	8b 1d b4 ba 10 00    	mov    0x10bab4,%ebx
  1021fd:	ba 10 00 00 00       	mov    $0x10,%edx
  102202:	31 c0                	xor    %eax,%eax
  102204:	eb 08                	jmp    10220e <ioapicinit+0x7e>
  102206:	66 90                	xchg   %ax,%ax

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
  102208:	8b 1d b4 ba 10 00    	mov    0x10bab4,%ebx
}

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  10220e:	89 13                	mov    %edx,(%ebx)
  ioapic->data = data;
  102210:	8b 1d b4 ba 10 00    	mov    0x10bab4,%ebx
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  102216:	8d 48 20             	lea    0x20(%eax),%ecx
  102219:	81 c9 00 00 01 00    	or     $0x10000,%ecx
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
  10221f:	83 c0 01             	add    $0x1,%eax

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  ioapic->data = data;
  102222:	89 4b 10             	mov    %ecx,0x10(%ebx)
}

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  102225:	8b 0d b4 ba 10 00    	mov    0x10bab4,%ecx
  10222b:	8d 5a 01             	lea    0x1(%edx),%ebx
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
  10222e:	83 c2 02             	add    $0x2,%edx
  102231:	39 c6                	cmp    %eax,%esi
}

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  102233:	89 19                	mov    %ebx,(%ecx)
  ioapic->data = data;
  102235:	8b 0d b4 ba 10 00    	mov    0x10bab4,%ecx
  10223b:	c7 41 10 00 00 00 00 	movl   $0x0,0x10(%ecx)
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
  102242:	7d c4                	jge    102208 <ioapicinit+0x78>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
  102244:	83 c4 10             	add    $0x10,%esp
  102247:	5b                   	pop    %ebx
  102248:	5e                   	pop    %esi
  102249:	5d                   	pop    %ebp
  10224a:	c3                   	ret    
  10224b:	90                   	nop
  10224c:	90                   	nop
  10224d:	90                   	nop
  10224e:	90                   	nop
  10224f:	90                   	nop

00102250 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
  102250:	55                   	push   %ebp
  102251:	89 e5                	mov    %esp,%ebp
  102253:	53                   	push   %ebx
  102254:	83 ec 14             	sub    $0x14,%esp
  struct run *r;

  acquire(&kmem.lock);
  102257:	c7 04 24 c0 ba 10 00 	movl   $0x10bac0,(%esp)
  10225e:	e8 ed 18 00 00       	call   103b50 <acquire>
  r = kmem.freelist;
  102263:	8b 1d f4 ba 10 00    	mov    0x10baf4,%ebx
  if(r)
  102269:	85 db                	test   %ebx,%ebx
  10226b:	74 07                	je     102274 <kalloc+0x24>
    kmem.freelist = r->next;
  10226d:	8b 03                	mov    (%ebx),%eax
  10226f:	a3 f4 ba 10 00       	mov    %eax,0x10baf4
  release(&kmem.lock);
  102274:	c7 04 24 c0 ba 10 00 	movl   $0x10bac0,(%esp)
  10227b:	e8 80 18 00 00       	call   103b00 <release>
  return (char*)r;
}
  102280:	89 d8                	mov    %ebx,%eax
  102282:	83 c4 14             	add    $0x14,%esp
  102285:	5b                   	pop    %ebx
  102286:	5d                   	pop    %ebp
  102287:	c3                   	ret    
  102288:	90                   	nop
  102289:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00102290 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
  102290:	55                   	push   %ebp
  102291:	89 e5                	mov    %esp,%ebp
  102293:	53                   	push   %ebx
  102294:	83 ec 14             	sub    $0x14,%esp
  102297:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if((uint)v % PGSIZE || v < end || (uint)v >= PHYSTOP) 
  10229a:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
  1022a0:	75 52                	jne    1022f4 <kfree+0x64>
  1022a2:	81 fb ff ff ff 00    	cmp    $0xffffff,%ebx
  1022a8:	77 4a                	ja     1022f4 <kfree+0x64>
  1022aa:	81 fb 04 e9 10 00    	cmp    $0x10e904,%ebx
  1022b0:	72 42                	jb     1022f4 <kfree+0x64>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
  1022b2:	89 1c 24             	mov    %ebx,(%esp)
  1022b5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1022bc:	00 
  1022bd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1022c4:	00 
  1022c5:	e8 26 19 00 00       	call   103bf0 <memset>

  acquire(&kmem.lock);
  1022ca:	c7 04 24 c0 ba 10 00 	movl   $0x10bac0,(%esp)
  1022d1:	e8 7a 18 00 00       	call   103b50 <acquire>
  r = (struct run*)v;
  r->next = kmem.freelist;
  1022d6:	a1 f4 ba 10 00       	mov    0x10baf4,%eax
  1022db:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
  1022dd:	89 1d f4 ba 10 00    	mov    %ebx,0x10baf4
  release(&kmem.lock);
  1022e3:	c7 45 08 c0 ba 10 00 	movl   $0x10bac0,0x8(%ebp)
}
  1022ea:	83 c4 14             	add    $0x14,%esp
  1022ed:	5b                   	pop    %ebx
  1022ee:	5d                   	pop    %ebp

  acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
  1022ef:	e9 0c 18 00 00       	jmp    103b00 <release>
kfree(char *v)
{
  struct run *r;

  if((uint)v % PGSIZE || v < end || (uint)v >= PHYSTOP) 
    panic("kfree");
  1022f4:	c7 04 24 be 66 10 00 	movl   $0x1066be,(%esp)
  1022fb:	e8 20 e6 ff ff       	call   100920 <panic>

00102300 <kinit>:
extern char end[]; // first address after kernel loaded from ELF file

// Initialize free list of physical pages.
void
kinit(void)
{
  102300:	55                   	push   %ebp
  102301:	89 e5                	mov    %esp,%ebp
  102303:	53                   	push   %ebx
  102304:	83 ec 14             	sub    $0x14,%esp
  char *p;

  initlock(&kmem.lock, "kmem");
  102307:	c7 44 24 04 c4 66 10 	movl   $0x1066c4,0x4(%esp)
  10230e:	00 
  10230f:	c7 04 24 c0 ba 10 00 	movl   $0x10bac0,(%esp)
  102316:	e8 a5 16 00 00       	call   1039c0 <initlock>
  p = (char*)PGROUNDUP((uint)end);
  10231b:	ba 03 f9 10 00       	mov    $0x10f903,%edx
  102320:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  for(; p + PGSIZE <= (char*)PHYSTOP; p += PGSIZE)
  102326:	8d 9a 00 10 00 00    	lea    0x1000(%edx),%ebx
  10232c:	81 fb 00 00 00 01    	cmp    $0x1000000,%ebx
  102332:	76 08                	jbe    10233c <kinit+0x3c>
  102334:	eb 1b                	jmp    102351 <kinit+0x51>
  102336:	66 90                	xchg   %ax,%ax
  102338:	89 da                	mov    %ebx,%edx
  10233a:	89 c3                	mov    %eax,%ebx
    kfree(p);
  10233c:	89 14 24             	mov    %edx,(%esp)
  10233f:	e8 4c ff ff ff       	call   102290 <kfree>
{
  char *p;

  initlock(&kmem.lock, "kmem");
  p = (char*)PGROUNDUP((uint)end);
  for(; p + PGSIZE <= (char*)PHYSTOP; p += PGSIZE)
  102344:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
  10234a:	3d 00 00 00 01       	cmp    $0x1000000,%eax
  10234f:	76 e7                	jbe    102338 <kinit+0x38>
    kfree(p);
}
  102351:	83 c4 14             	add    $0x14,%esp
  102354:	5b                   	pop    %ebx
  102355:	5d                   	pop    %ebp
  102356:	c3                   	ret    
  102357:	90                   	nop
  102358:	90                   	nop
  102359:	90                   	nop
  10235a:	90                   	nop
  10235b:	90                   	nop
  10235c:	90                   	nop
  10235d:	90                   	nop
  10235e:	90                   	nop
  10235f:	90                   	nop

00102360 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
  102360:	55                   	push   %ebp
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  102361:	ba 64 00 00 00       	mov    $0x64,%edx
  102366:	89 e5                	mov    %esp,%ebp
  102368:	ec                   	in     (%dx),%al
  102369:	89 c2                	mov    %eax,%edx
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
  10236b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  102370:	83 e2 01             	and    $0x1,%edx
  102373:	74 3e                	je     1023b3 <kbdgetc+0x53>
  102375:	ba 60 00 00 00       	mov    $0x60,%edx
  10237a:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
  10237b:	0f b6 c0             	movzbl %al,%eax

  if(data == 0xE0){
  10237e:	3d e0 00 00 00       	cmp    $0xe0,%eax
  102383:	0f 84 7f 00 00 00    	je     102408 <kbdgetc+0xa8>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
  102389:	84 c0                	test   %al,%al
  10238b:	79 2b                	jns    1023b8 <kbdgetc+0x58>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
  10238d:	8b 15 bc 78 10 00    	mov    0x1078bc,%edx
  102393:	f6 c2 40             	test   $0x40,%dl
  102396:	75 03                	jne    10239b <kbdgetc+0x3b>
  102398:	83 e0 7f             	and    $0x7f,%eax
    shift &= ~(shiftcode[data] | E0ESC);
  10239b:	0f b6 80 e0 66 10 00 	movzbl 0x1066e0(%eax),%eax
  1023a2:	83 c8 40             	or     $0x40,%eax
  1023a5:	0f b6 c0             	movzbl %al,%eax
  1023a8:	f7 d0                	not    %eax
  1023aa:	21 d0                	and    %edx,%eax
  1023ac:	a3 bc 78 10 00       	mov    %eax,0x1078bc
  1023b1:	31 c0                	xor    %eax,%eax
      c += 'A' - 'a';
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
  1023b3:	5d                   	pop    %ebp
  1023b4:	c3                   	ret    
  1023b5:	8d 76 00             	lea    0x0(%esi),%esi
  } else if(data & 0x80){
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
  1023b8:	8b 0d bc 78 10 00    	mov    0x1078bc,%ecx
  1023be:	f6 c1 40             	test   $0x40,%cl
  1023c1:	74 05                	je     1023c8 <kbdgetc+0x68>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
  1023c3:	0c 80                	or     $0x80,%al
    shift &= ~E0ESC;
  1023c5:	83 e1 bf             	and    $0xffffffbf,%ecx
  }

  shift |= shiftcode[data];
  shift ^= togglecode[data];
  1023c8:	0f b6 90 e0 66 10 00 	movzbl 0x1066e0(%eax),%edx
  1023cf:	09 ca                	or     %ecx,%edx
  1023d1:	0f b6 88 e0 67 10 00 	movzbl 0x1067e0(%eax),%ecx
  1023d8:	31 ca                	xor    %ecx,%edx
  c = charcode[shift & (CTL | SHIFT)][data];
  1023da:	89 d1                	mov    %edx,%ecx
  1023dc:	83 e1 03             	and    $0x3,%ecx
  1023df:	8b 0c 8d e0 68 10 00 	mov    0x1068e0(,%ecx,4),%ecx
    data |= 0x80;
    shift &= ~E0ESC;
  }

  shift |= shiftcode[data];
  shift ^= togglecode[data];
  1023e6:	89 15 bc 78 10 00    	mov    %edx,0x1078bc
  c = charcode[shift & (CTL | SHIFT)][data];
  if(shift & CAPSLOCK){
  1023ec:	83 e2 08             	and    $0x8,%edx
    shift &= ~E0ESC;
  }

  shift |= shiftcode[data];
  shift ^= togglecode[data];
  c = charcode[shift & (CTL | SHIFT)][data];
  1023ef:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
  if(shift & CAPSLOCK){
  1023f3:	74 be                	je     1023b3 <kbdgetc+0x53>
    if('a' <= c && c <= 'z')
  1023f5:	8d 50 9f             	lea    -0x61(%eax),%edx
  1023f8:	83 fa 19             	cmp    $0x19,%edx
  1023fb:	77 1b                	ja     102418 <kbdgetc+0xb8>
      c += 'A' - 'a';
  1023fd:	83 e8 20             	sub    $0x20,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
  102400:	5d                   	pop    %ebp
  102401:	c3                   	ret    
  102402:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  if((st & KBS_DIB) == 0)
    return -1;
  data = inb(KBDATAP);

  if(data == 0xE0){
    shift |= E0ESC;
  102408:	30 c0                	xor    %al,%al
  10240a:	83 0d bc 78 10 00 40 	orl    $0x40,0x1078bc
      c += 'A' - 'a';
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
  102411:	5d                   	pop    %ebp
  102412:	c3                   	ret    
  102413:	90                   	nop
  102414:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  shift ^= togglecode[data];
  c = charcode[shift & (CTL | SHIFT)][data];
  if(shift & CAPSLOCK){
    if('a' <= c && c <= 'z')
      c += 'A' - 'a';
    else if('A' <= c && c <= 'Z')
  102418:	8d 50 bf             	lea    -0x41(%eax),%edx
  10241b:	83 fa 19             	cmp    $0x19,%edx
  10241e:	77 93                	ja     1023b3 <kbdgetc+0x53>
      c += 'a' - 'A';
  102420:	83 c0 20             	add    $0x20,%eax
  }
  return c;
}
  102423:	5d                   	pop    %ebp
  102424:	c3                   	ret    
  102425:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102429:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00102430 <kbdintr>:

void
kbdintr(void)
{
  102430:	55                   	push   %ebp
  102431:	89 e5                	mov    %esp,%ebp
  102433:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
  102436:	c7 04 24 60 23 10 00 	movl   $0x102360,(%esp)
  10243d:	e8 4e e3 ff ff       	call   100790 <consoleintr>
}
  102442:	c9                   	leave  
  102443:	c3                   	ret    
  102444:	90                   	nop
  102445:	90                   	nop
  102446:	90                   	nop
  102447:	90                   	nop
  102448:	90                   	nop
  102449:	90                   	nop
  10244a:	90                   	nop
  10244b:	90                   	nop
  10244c:	90                   	nop
  10244d:	90                   	nop
  10244e:	90                   	nop
  10244f:	90                   	nop

00102450 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
  if(lapic)
  102450:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
}

// Acknowledge interrupt.
void
lapiceoi(void)
{
  102455:	55                   	push   %ebp
  102456:	89 e5                	mov    %esp,%ebp
  if(lapic)
  102458:	85 c0                	test   %eax,%eax
  10245a:	74 12                	je     10246e <lapiceoi+0x1e>
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  10245c:	c7 80 b0 00 00 00 00 	movl   $0x0,0xb0(%eax)
  102463:	00 00 00 
  lapic[ID];  // wait for write to finish, by reading
  102466:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  10246b:	8b 40 20             	mov    0x20(%eax),%eax
void
lapiceoi(void)
{
  if(lapic)
    lapicw(EOI, 0);
}
  10246e:	5d                   	pop    %ebp
  10246f:	c3                   	ret    

00102470 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  102470:	55                   	push   %ebp
  102471:	89 e5                	mov    %esp,%ebp
}
  102473:	5d                   	pop    %ebp
  102474:	c3                   	ret    
  102475:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102479:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00102480 <lapicstartap>:

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
  102480:	55                   	push   %ebp
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  102481:	ba 70 00 00 00       	mov    $0x70,%edx
  102486:	89 e5                	mov    %esp,%ebp
  102488:	b8 0f 00 00 00       	mov    $0xf,%eax
  10248d:	53                   	push   %ebx
  10248e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  102491:	0f b6 5d 08          	movzbl 0x8(%ebp),%ebx
  102495:	ee                   	out    %al,(%dx)
  102496:	b8 0a 00 00 00       	mov    $0xa,%eax
  10249b:	b2 71                	mov    $0x71,%dl
  10249d:	ee                   	out    %al,(%dx)
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
  outb(IO_RTC+1, 0x0A);
  wrv = (ushort*)(0x40<<4 | 0x67);  // Warm reset vector
  wrv[0] = 0;
  wrv[1] = addr >> 4;
  10249e:	89 c8                	mov    %ecx,%eax
  1024a0:	c1 e8 04             	shr    $0x4,%eax
  1024a3:	66 a3 69 04 00 00    	mov    %ax,0x469
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1024a9:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1024ae:	c1 e3 18             	shl    $0x18,%ebx
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
  outb(IO_RTC+1, 0x0A);
  wrv = (ushort*)(0x40<<4 | 0x67);  // Warm reset vector
  wrv[0] = 0;
  1024b1:	66 c7 05 67 04 00 00 	movw   $0x0,0x467
  1024b8:	00 00 

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  lapic[ID];  // wait for write to finish, by reading
  1024ba:	c1 e9 0c             	shr    $0xc,%ecx
  1024bd:	80 cd 06             	or     $0x6,%ch
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1024c0:	89 98 10 03 00 00    	mov    %ebx,0x310(%eax)
  lapic[ID];  // wait for write to finish, by reading
  1024c6:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1024cb:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1024ce:	c7 80 00 03 00 00 00 	movl   $0xc500,0x300(%eax)
  1024d5:	c5 00 00 
  lapic[ID];  // wait for write to finish, by reading
  1024d8:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1024dd:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1024e0:	c7 80 00 03 00 00 00 	movl   $0x8500,0x300(%eax)
  1024e7:	85 00 00 
  lapic[ID];  // wait for write to finish, by reading
  1024ea:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1024ef:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1024f2:	89 98 10 03 00 00    	mov    %ebx,0x310(%eax)
  lapic[ID];  // wait for write to finish, by reading
  1024f8:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1024fd:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  102500:	89 88 00 03 00 00    	mov    %ecx,0x300(%eax)
  lapic[ID];  // wait for write to finish, by reading
  102506:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  10250b:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  10250e:	89 98 10 03 00 00    	mov    %ebx,0x310(%eax)
  lapic[ID];  // wait for write to finish, by reading
  102514:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  102519:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  10251c:	89 88 00 03 00 00    	mov    %ecx,0x300(%eax)
  lapic[ID];  // wait for write to finish, by reading
  102522:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  for(i = 0; i < 2; i++){
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
  102527:	5b                   	pop    %ebx
  102528:	5d                   	pop    %ebp

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  lapic[ID];  // wait for write to finish, by reading
  102529:	8b 40 20             	mov    0x20(%eax),%eax
  for(i = 0; i < 2; i++){
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
  10252c:	c3                   	ret    
  10252d:	8d 76 00             	lea    0x0(%esi),%esi

00102530 <cpunum>:
  lapicw(TPR, 0);
}

int
cpunum(void)
{
  102530:	55                   	push   %ebp
  102531:	89 e5                	mov    %esp,%ebp
  102533:	83 ec 18             	sub    $0x18,%esp

static inline uint
readeflags(void)
{
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
  102536:	9c                   	pushf  
  102537:	58                   	pop    %eax
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
  102538:	f6 c4 02             	test   $0x2,%ah
  10253b:	74 12                	je     10254f <cpunum+0x1f>
    static int n;
    if(n++ == 0)
  10253d:	a1 c0 78 10 00       	mov    0x1078c0,%eax
  102542:	8d 50 01             	lea    0x1(%eax),%edx
  102545:	85 c0                	test   %eax,%eax
  102547:	89 15 c0 78 10 00    	mov    %edx,0x1078c0
  10254d:	74 19                	je     102568 <cpunum+0x38>
      cprintf("cpu called from %x with interrupts enabled\n",
        __builtin_return_address(0));
  }

  if(lapic)
  10254f:	8b 15 f8 ba 10 00    	mov    0x10baf8,%edx
  102555:	31 c0                	xor    %eax,%eax
  102557:	85 d2                	test   %edx,%edx
  102559:	74 06                	je     102561 <cpunum+0x31>
    return lapic[ID]>>24;
  10255b:	8b 42 20             	mov    0x20(%edx),%eax
  10255e:	c1 e8 18             	shr    $0x18,%eax
  return 0;
}
  102561:	c9                   	leave  
  102562:	c3                   	ret    
  102563:	90                   	nop
  102564:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
    static int n;
    if(n++ == 0)
      cprintf("cpu called from %x with interrupts enabled\n",
  102568:	8b 45 04             	mov    0x4(%ebp),%eax
  10256b:	c7 04 24 f0 68 10 00 	movl   $0x1068f0,(%esp)
  102572:	89 44 24 04          	mov    %eax,0x4(%esp)
  102576:	e8 b5 df ff ff       	call   100530 <cprintf>
  10257b:	eb d2                	jmp    10254f <cpunum+0x1f>
  10257d:	8d 76 00             	lea    0x0(%esi),%esi

00102580 <lapicinit>:
  lapic[ID];  // wait for write to finish, by reading
}

void
lapicinit(int c)
{
  102580:	55                   	push   %ebp
  102581:	89 e5                	mov    %esp,%ebp
  102583:	83 ec 18             	sub    $0x18,%esp
  cprintf("lapicinit: %d 0x%x\n", c, lapic);
  102586:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  10258b:	c7 04 24 1c 69 10 00 	movl   $0x10691c,(%esp)
  102592:	89 44 24 08          	mov    %eax,0x8(%esp)
  102596:	8b 45 08             	mov    0x8(%ebp),%eax
  102599:	89 44 24 04          	mov    %eax,0x4(%esp)
  10259d:	e8 8e df ff ff       	call   100530 <cprintf>
  if(!lapic) 
  1025a2:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1025a7:	85 c0                	test   %eax,%eax
  1025a9:	0f 84 0a 01 00 00    	je     1026b9 <lapicinit+0x139>
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1025af:	c7 80 f0 00 00 00 3f 	movl   $0x13f,0xf0(%eax)
  1025b6:	01 00 00 
  lapic[ID];  // wait for write to finish, by reading
  1025b9:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1025be:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1025c1:	c7 80 e0 03 00 00 0b 	movl   $0xb,0x3e0(%eax)
  1025c8:	00 00 00 
  lapic[ID];  // wait for write to finish, by reading
  1025cb:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1025d0:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1025d3:	c7 80 20 03 00 00 20 	movl   $0x20020,0x320(%eax)
  1025da:	00 02 00 
  lapic[ID];  // wait for write to finish, by reading
  1025dd:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1025e2:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1025e5:	c7 80 80 03 00 00 80 	movl   $0x989680,0x380(%eax)
  1025ec:	96 98 00 
  lapic[ID];  // wait for write to finish, by reading
  1025ef:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1025f4:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1025f7:	c7 80 50 03 00 00 00 	movl   $0x10000,0x350(%eax)
  1025fe:	00 01 00 
  lapic[ID];  // wait for write to finish, by reading
  102601:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  102606:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  102609:	c7 80 60 03 00 00 00 	movl   $0x10000,0x360(%eax)
  102610:	00 01 00 
  lapic[ID];  // wait for write to finish, by reading
  102613:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  102618:	8b 50 20             	mov    0x20(%eax),%edx
  lapicw(LINT0, MASKED);
  lapicw(LINT1, MASKED);

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
  10261b:	8b 50 30             	mov    0x30(%eax),%edx
  10261e:	c1 ea 10             	shr    $0x10,%edx
  102621:	80 fa 03             	cmp    $0x3,%dl
  102624:	0f 87 96 00 00 00    	ja     1026c0 <lapicinit+0x140>
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  10262a:	c7 80 70 03 00 00 33 	movl   $0x33,0x370(%eax)
  102631:	00 00 00 
  lapic[ID];  // wait for write to finish, by reading
  102634:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  102639:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  10263c:	c7 80 80 02 00 00 00 	movl   $0x0,0x280(%eax)
  102643:	00 00 00 
  lapic[ID];  // wait for write to finish, by reading
  102646:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  10264b:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  10264e:	c7 80 80 02 00 00 00 	movl   $0x0,0x280(%eax)
  102655:	00 00 00 
  lapic[ID];  // wait for write to finish, by reading
  102658:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  10265d:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  102660:	c7 80 b0 00 00 00 00 	movl   $0x0,0xb0(%eax)
  102667:	00 00 00 
  lapic[ID];  // wait for write to finish, by reading
  10266a:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  10266f:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  102672:	c7 80 10 03 00 00 00 	movl   $0x0,0x310(%eax)
  102679:	00 00 00 
  lapic[ID];  // wait for write to finish, by reading
  10267c:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  102681:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  102684:	c7 80 00 03 00 00 00 	movl   $0x88500,0x300(%eax)
  10268b:	85 08 00 
  lapic[ID];  // wait for write to finish, by reading
  10268e:	8b 0d f8 ba 10 00    	mov    0x10baf8,%ecx
  102694:	8b 41 20             	mov    0x20(%ecx),%eax
  102697:	8d 91 00 03 00 00    	lea    0x300(%ecx),%edx
  10269d:	8d 76 00             	lea    0x0(%esi),%esi
  lapicw(EOI, 0);

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
  lapicw(ICRLO, BCAST | INIT | LEVEL);
  while(lapic[ICRLO] & DELIVS)
  1026a0:	8b 02                	mov    (%edx),%eax
  1026a2:	f6 c4 10             	test   $0x10,%ah
  1026a5:	75 f9                	jne    1026a0 <lapicinit+0x120>
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1026a7:	c7 81 80 00 00 00 00 	movl   $0x0,0x80(%ecx)
  1026ae:	00 00 00 
  lapic[ID];  // wait for write to finish, by reading
  1026b1:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1026b6:	8b 40 20             	mov    0x20(%eax),%eax
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
  1026b9:	c9                   	leave  
  1026ba:	c3                   	ret    
  1026bb:	90                   	nop
  1026bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1026c0:	c7 80 40 03 00 00 00 	movl   $0x10000,0x340(%eax)
  1026c7:	00 01 00 
  lapic[ID];  // wait for write to finish, by reading
  1026ca:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1026cf:	8b 50 20             	mov    0x20(%eax),%edx
  1026d2:	e9 53 ff ff ff       	jmp    10262a <lapicinit+0xaa>
  1026d7:	90                   	nop
  1026d8:	90                   	nop
  1026d9:	90                   	nop
  1026da:	90                   	nop
  1026db:	90                   	nop
  1026dc:	90                   	nop
  1026dd:	90                   	nop
  1026de:	90                   	nop
  1026df:	90                   	nop

001026e0 <mpmain>:
// Common CPU setup code.
// Bootstrap CPU comes here from mainc().
// Other CPUs jump here from bootother.S.
static void
mpmain(void)
{
  1026e0:	55                   	push   %ebp
  1026e1:	89 e5                	mov    %esp,%ebp
  1026e3:	53                   	push   %ebx
  1026e4:	83 ec 14             	sub    $0x14,%esp
  if(cpunum() != mpbcpu()){
  1026e7:	e8 44 fe ff ff       	call   102530 <cpunum>
  1026ec:	89 c3                	mov    %eax,%ebx
  1026ee:	e8 0d 02 00 00       	call   102900 <mpbcpu>
  1026f3:	39 c3                	cmp    %eax,%ebx
  1026f5:	74 16                	je     10270d <mpmain+0x2d>
    seginit();
  1026f7:	e8 c4 3c 00 00       	call   1063c0 <seginit>
  1026fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    lapicinit(cpunum());
  102700:	e8 2b fe ff ff       	call   102530 <cpunum>
  102705:	89 04 24             	mov    %eax,(%esp)
  102708:	e8 73 fe ff ff       	call   102580 <lapicinit>
  }
  vmenable();        // turn on paging
  10270d:	e8 6e 35 00 00       	call   105c80 <vmenable>
  cprintf("cpu%d: starting\n", cpu->id);
  102712:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  102718:	0f b6 00             	movzbl (%eax),%eax
  10271b:	c7 04 24 30 69 10 00 	movl   $0x106930,(%esp)
  102722:	89 44 24 04          	mov    %eax,0x4(%esp)
  102726:	e8 05 de ff ff       	call   100530 <cprintf>
  idtinit();       // load idt register
  10272b:	e8 60 26 00 00       	call   104d90 <idtinit>
  xchg(&cpu->booted, 1); // tell bootothers() we're up
  102730:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
  102737:	b8 01 00 00 00       	mov    $0x1,%eax
  10273c:	f0 87 82 a8 00 00 00 	lock xchg %eax,0xa8(%edx)
  scheduler();     // start running processes
  102743:	e8 38 0c 00 00       	call   103380 <scheduler>
  102748:	90                   	nop
  102749:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00102750 <mainc>:

// Set up hardware and software.
// Runs only on the boostrap processor.
void
mainc(void)
{
  102750:	55                   	push   %ebp
  102751:	89 e5                	mov    %esp,%ebp
  102753:	53                   	push   %ebx
  102754:	83 ec 14             	sub    $0x14,%esp
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
  102757:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  10275d:	0f b6 00             	movzbl (%eax),%eax
  102760:	c7 04 24 41 69 10 00 	movl   $0x106941,(%esp)
  102767:	89 44 24 04          	mov    %eax,0x4(%esp)
  10276b:	e8 c0 dd ff ff       	call   100530 <cprintf>
  picinit();       // interrupt controller
  102770:	e8 6b 04 00 00       	call   102be0 <picinit>
  ioapicinit();    // another interrupt controller
  102775:	e8 16 fa ff ff       	call   102190 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
  10277a:	e8 e1 da ff ff       	call   100260 <consoleinit>
  10277f:	90                   	nop
  uartinit();      // serial port
  102780:	e8 cb 29 00 00       	call   105150 <uartinit>
  kvmalloc();      // initialize the kernel page table
  102785:	e8 76 37 00 00       	call   105f00 <kvmalloc>
  pinit();         // process table
  10278a:	e8 11 12 00 00       	call   1039a0 <pinit>
  10278f:	90                   	nop
  tvinit();        // trap vectors
  102790:	e8 8b 28 00 00       	call   105020 <tvinit>
  binit();         // buffer cache
  102795:	e8 56 da ff ff       	call   1001f0 <binit>
  fileinit();      // file table
  10279a:	e8 c1 e8 ff ff       	call   101060 <fileinit>
  10279f:	90                   	nop
  iinit();         // inode cache
  1027a0:	e8 cb f6 ff ff       	call   101e70 <iinit>
  ideinit();       // disk
  1027a5:	e8 06 f9 ff ff       	call   1020b0 <ideinit>
  1027aa:	31 c0                	xor    %eax,%eax
  1027ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

  int i;
  for( i=0; i<22;i++)
  {
    syscall_counts[i] = 0;
  1027b0:	c7 04 85 60 e0 10 00 	movl   $0x0,0x10e060(,%eax,4)
  1027b7:	00 00 00 00 
  fileinit();      // file table
  iinit();         // inode cache
  ideinit();       // disk

  int i;
  for( i=0; i<22;i++)
  1027bb:	83 c0 01             	add    $0x1,%eax
  1027be:	83 f8 16             	cmp    $0x16,%eax
  1027c1:	75 ed                	jne    1027b0 <mainc+0x60>
    syscall_counts[i] = 0;

  }


  if(!ismp)
  1027c3:	a1 04 bb 10 00       	mov    0x10bb04,%eax
  1027c8:	85 c0                	test   %eax,%eax
  1027ca:	0f 84 ad 00 00 00    	je     10287d <mainc+0x12d>
    timerinit();   // uniprocessor timer
  userinit();      // first user process
  1027d0:	e8 db 10 00 00       	call   1038b0 <userinit>

  // Write bootstrap code to unused memory at 0x7000.
  // The linker has placed the image of bootother.S in
  // _binary_bootother_start.
  code = (uchar*)0x7000;
  memmove(code, _binary_bootother_start, (uint)_binary_bootother_size);
  1027d5:	c7 44 24 08 6a 00 00 	movl   $0x6a,0x8(%esp)
  1027dc:	00 
  1027dd:	c7 44 24 04 9c 77 10 	movl   $0x10779c,0x4(%esp)
  1027e4:	00 
  1027e5:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
  1027ec:	e8 7f 14 00 00       	call   103c70 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
  1027f1:	69 05 00 c1 10 00 bc 	imul   $0xbc,0x10c100,%eax
  1027f8:	00 00 00 
  1027fb:	05 20 bb 10 00       	add    $0x10bb20,%eax
  102800:	3d 20 bb 10 00       	cmp    $0x10bb20,%eax
  102805:	76 6c                	jbe    102873 <mainc+0x123>
  102807:	bb 20 bb 10 00       	mov    $0x10bb20,%ebx
  10280c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    if(c == cpus+cpunum())  // We've started already.
  102810:	e8 1b fd ff ff       	call   102530 <cpunum>
  102815:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
  10281b:	05 20 bb 10 00       	add    $0x10bb20,%eax
  102820:	39 c3                	cmp    %eax,%ebx
  102822:	74 36                	je     10285a <mainc+0x10a>
      continue;

    // Tell bootother.S what stack to use and the address of mpmain;
    // it expects to find these two addresses stored just before
    // its first instruction.
    stack = kalloc();
  102824:	e8 27 fa ff ff       	call   102250 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
    *(void**)(code-8) = mpmain;
  102829:	c7 05 f8 6f 00 00 e0 	movl   $0x1026e0,0x6ff8
  102830:	26 10 00 

    // Tell bootother.S what stack to use and the address of mpmain;
    // it expects to find these two addresses stored just before
    // its first instruction.
    stack = kalloc();
    *(void**)(code-4) = stack + KSTACKSIZE;
  102833:	05 00 10 00 00       	add    $0x1000,%eax
  102838:	a3 fc 6f 00 00       	mov    %eax,0x6ffc
    *(void**)(code-8) = mpmain;

    lapicstartap(c->id, (uint)code);
  10283d:	c7 44 24 04 00 70 00 	movl   $0x7000,0x4(%esp)
  102844:	00 
  102845:	0f b6 03             	movzbl (%ebx),%eax
  102848:	89 04 24             	mov    %eax,(%esp)
  10284b:	e8 30 fc ff ff       	call   102480 <lapicstartap>

    // Wait for cpu to finish mpmain()
    while(c->booted == 0)
  102850:	8b 83 a8 00 00 00    	mov    0xa8(%ebx),%eax
  102856:	85 c0                	test   %eax,%eax
  102858:	74 f6                	je     102850 <mainc+0x100>
  // The linker has placed the image of bootother.S in
  // _binary_bootother_start.
  code = (uchar*)0x7000;
  memmove(code, _binary_bootother_start, (uint)_binary_bootother_size);

  for(c = cpus; c < cpus+ncpu; c++){
  10285a:	69 05 00 c1 10 00 bc 	imul   $0xbc,0x10c100,%eax
  102861:	00 00 00 
  102864:	81 c3 bc 00 00 00    	add    $0xbc,%ebx
  10286a:	05 20 bb 10 00       	add    $0x10bb20,%eax
  10286f:	39 c3                	cmp    %eax,%ebx
  102871:	72 9d                	jb     102810 <mainc+0xc0>
  userinit();      // first user process
  bootothers();    // start other processors

  // Finish setting up this processor in mpmain.
  mpmain();
}
  102873:	83 c4 14             	add    $0x14,%esp
  102876:	5b                   	pop    %ebx
  102877:	5d                   	pop    %ebp
    timerinit();   // uniprocessor timer
  userinit();      // first user process
  bootothers();    // start other processors

  // Finish setting up this processor in mpmain.
  mpmain();
  102878:	e9 63 fe ff ff       	jmp    1026e0 <mpmain>

  }


  if(!ismp)
    timerinit();   // uniprocessor timer
  10287d:	e8 ae 24 00 00       	call   104d30 <timerinit>
  102882:	e9 49 ff ff ff       	jmp    1027d0 <mainc+0x80>
  102887:	89 f6                	mov    %esi,%esi
  102889:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00102890 <jmpkstack>:
  jmpkstack();       // call mainc() on a properly-allocated stack 
}

void
jmpkstack(void)
{
  102890:	55                   	push   %ebp
  102891:	89 e5                	mov    %esp,%ebp
  102893:	83 ec 18             	sub    $0x18,%esp
  char *kstack, *top;
  
  kstack = kalloc();
  102896:	e8 b5 f9 ff ff       	call   102250 <kalloc>
  if(kstack == 0)
  10289b:	85 c0                	test   %eax,%eax
  10289d:	74 19                	je     1028b8 <jmpkstack+0x28>
    panic("jmpkstack kalloc");
  top = kstack + PGSIZE;
  asm volatile("movl %0,%%esp; call mainc" : : "r" (top));
  10289f:	05 00 10 00 00       	add    $0x1000,%eax
  1028a4:	89 c4                	mov    %eax,%esp
  1028a6:	e8 a5 fe ff ff       	call   102750 <mainc>
  panic("jmpkstack");
  1028ab:	c7 04 24 69 69 10 00 	movl   $0x106969,(%esp)
  1028b2:	e8 69 e0 ff ff       	call   100920 <panic>
  1028b7:	90                   	nop
{
  char *kstack, *top;
  
  kstack = kalloc();
  if(kstack == 0)
    panic("jmpkstack kalloc");
  1028b8:	c7 04 24 58 69 10 00 	movl   $0x106958,(%esp)
  1028bf:	e8 5c e0 ff ff       	call   100920 <panic>
  1028c4:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1028ca:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

001028d0 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
  1028d0:	55                   	push   %ebp
  1028d1:	89 e5                	mov    %esp,%ebp
  1028d3:	83 e4 f0             	and    $0xfffffff0,%esp
  1028d6:	83 ec 10             	sub    $0x10,%esp
  mpinit();        // collect info about this machine
  1028d9:	e8 b2 00 00 00       	call   102990 <mpinit>
  lapicinit(mpbcpu());
  1028de:	e8 1d 00 00 00       	call   102900 <mpbcpu>
  1028e3:	89 04 24             	mov    %eax,(%esp)
  1028e6:	e8 95 fc ff ff       	call   102580 <lapicinit>
  seginit();       // set up segments
  1028eb:	e8 d0 3a 00 00       	call   1063c0 <seginit>
  kinit();         // initialize memory allocator
  1028f0:	e8 0b fa ff ff       	call   102300 <kinit>
  jmpkstack();       // call mainc() on a properly-allocated stack 
  1028f5:	e8 96 ff ff ff       	call   102890 <jmpkstack>
  1028fa:	90                   	nop
  1028fb:	90                   	nop
  1028fc:	90                   	nop
  1028fd:	90                   	nop
  1028fe:	90                   	nop
  1028ff:	90                   	nop

00102900 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
  102900:	a1 c4 78 10 00       	mov    0x1078c4,%eax
  102905:	55                   	push   %ebp
  102906:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
}
  102908:	5d                   	pop    %ebp
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
  102909:	2d 20 bb 10 00       	sub    $0x10bb20,%eax
  10290e:	c1 f8 02             	sar    $0x2,%eax
  102911:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
  return bcpu-cpus;
}
  102917:	c3                   	ret    
  102918:	90                   	nop
  102919:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00102920 <mpsearch1>:
}

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uchar *addr, int len)
{
  102920:	55                   	push   %ebp
  102921:	89 e5                	mov    %esp,%ebp
  102923:	56                   	push   %esi
  102924:	53                   	push   %ebx
  uchar *e, *p;

  e = addr+len;
  102925:	8d 34 10             	lea    (%eax,%edx,1),%esi
}

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uchar *addr, int len)
{
  102928:	83 ec 10             	sub    $0x10,%esp
  uchar *e, *p;

  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
  10292b:	39 f0                	cmp    %esi,%eax
  10292d:	73 42                	jae    102971 <mpsearch1+0x51>
  10292f:	89 c3                	mov    %eax,%ebx
  102931:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  102938:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  10293f:	00 
  102940:	c7 44 24 04 73 69 10 	movl   $0x106973,0x4(%esp)
  102947:	00 
  102948:	89 1c 24             	mov    %ebx,(%esp)
  10294b:	e8 c0 12 00 00       	call   103c10 <memcmp>
  102950:	85 c0                	test   %eax,%eax
  102952:	75 16                	jne    10296a <mpsearch1+0x4a>
  102954:	31 d2                	xor    %edx,%edx
  102956:	66 90                	xchg   %ax,%ax
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
    sum += addr[i];
  102958:	0f b6 0c 03          	movzbl (%ebx,%eax,1),%ecx
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
  10295c:	83 c0 01             	add    $0x1,%eax
    sum += addr[i];
  10295f:	01 ca                	add    %ecx,%edx
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
  102961:	83 f8 10             	cmp    $0x10,%eax
  102964:	75 f2                	jne    102958 <mpsearch1+0x38>
{
  uchar *e, *p;

  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  102966:	84 d2                	test   %dl,%dl
  102968:	74 10                	je     10297a <mpsearch1+0x5a>
mpsearch1(uchar *addr, int len)
{
  uchar *e, *p;

  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
  10296a:	83 c3 10             	add    $0x10,%ebx
  10296d:	39 de                	cmp    %ebx,%esi
  10296f:	77 c7                	ja     102938 <mpsearch1+0x18>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
}
  102971:	83 c4 10             	add    $0x10,%esp
mpsearch1(uchar *addr, int len)
{
  uchar *e, *p;

  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
  102974:	31 c0                	xor    %eax,%eax
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
}
  102976:	5b                   	pop    %ebx
  102977:	5e                   	pop    %esi
  102978:	5d                   	pop    %ebp
  102979:	c3                   	ret    
  10297a:	83 c4 10             	add    $0x10,%esp
  uchar *e, *p;

  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  10297d:	89 d8                	mov    %ebx,%eax
  return 0;
}
  10297f:	5b                   	pop    %ebx
  102980:	5e                   	pop    %esi
  102981:	5d                   	pop    %ebp
  102982:	c3                   	ret    
  102983:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  102989:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00102990 <mpinit>:
  return conf;
}

void
mpinit(void)
{
  102990:	55                   	push   %ebp
  102991:	89 e5                	mov    %esp,%ebp
  102993:	57                   	push   %edi
  102994:	56                   	push   %esi
  102995:	53                   	push   %ebx
  102996:	83 ec 1c             	sub    $0x1c,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar*)0x400;
  if((p = ((bda[0x0F]<<8)|bda[0x0E]) << 4)){
  102999:	0f b6 05 0f 04 00 00 	movzbl 0x40f,%eax
  1029a0:	0f b6 15 0e 04 00 00 	movzbl 0x40e,%edx
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  1029a7:	c7 05 c4 78 10 00 20 	movl   $0x10bb20,0x1078c4
  1029ae:	bb 10 00 
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar*)0x400;
  if((p = ((bda[0x0F]<<8)|bda[0x0E]) << 4)){
  1029b1:	c1 e0 08             	shl    $0x8,%eax
  1029b4:	09 d0                	or     %edx,%eax
  1029b6:	c1 e0 04             	shl    $0x4,%eax
  1029b9:	85 c0                	test   %eax,%eax
  1029bb:	75 1b                	jne    1029d8 <mpinit+0x48>
    if((mp = mpsearch1((uchar*)p, 1024)))
      return mp;
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1((uchar*)p-1024, 1024)))
  1029bd:	0f b6 05 14 04 00 00 	movzbl 0x414,%eax
  1029c4:	0f b6 15 13 04 00 00 	movzbl 0x413,%edx
  1029cb:	c1 e0 08             	shl    $0x8,%eax
  1029ce:	09 d0                	or     %edx,%eax
  1029d0:	c1 e0 0a             	shl    $0xa,%eax
  1029d3:	2d 00 04 00 00       	sub    $0x400,%eax
  1029d8:	ba 00 04 00 00       	mov    $0x400,%edx
  1029dd:	e8 3e ff ff ff       	call   102920 <mpsearch1>
  1029e2:	85 c0                	test   %eax,%eax
  1029e4:	89 c6                	mov    %eax,%esi
  1029e6:	0f 84 94 01 00 00    	je     102b80 <mpinit+0x1f0>
mpconfig(struct mp **pmp)
{
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
  1029ec:	8b 5e 04             	mov    0x4(%esi),%ebx
  1029ef:	85 db                	test   %ebx,%ebx
  1029f1:	74 1c                	je     102a0f <mpinit+0x7f>
    return 0;
  conf = (struct mpconf*)mp->physaddr;
  if(memcmp(conf, "PCMP", 4) != 0)
  1029f3:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  1029fa:	00 
  1029fb:	c7 44 24 04 78 69 10 	movl   $0x106978,0x4(%esp)
  102a02:	00 
  102a03:	89 1c 24             	mov    %ebx,(%esp)
  102a06:	e8 05 12 00 00       	call   103c10 <memcmp>
  102a0b:	85 c0                	test   %eax,%eax
  102a0d:	74 09                	je     102a18 <mpinit+0x88>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
  102a0f:	83 c4 1c             	add    $0x1c,%esp
  102a12:	5b                   	pop    %ebx
  102a13:	5e                   	pop    %esi
  102a14:	5f                   	pop    %edi
  102a15:	5d                   	pop    %ebp
  102a16:	c3                   	ret    
  102a17:	90                   	nop
  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
    return 0;
  conf = (struct mpconf*)mp->physaddr;
  if(memcmp(conf, "PCMP", 4) != 0)
    return 0;
  if(conf->version != 1 && conf->version != 4)
  102a18:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
  102a1c:	3c 04                	cmp    $0x4,%al
  102a1e:	74 04                	je     102a24 <mpinit+0x94>
  102a20:	3c 01                	cmp    $0x1,%al
  102a22:	75 eb                	jne    102a0f <mpinit+0x7f>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
  102a24:	0f b7 7b 04          	movzwl 0x4(%ebx),%edi
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
  102a28:	85 ff                	test   %edi,%edi
  102a2a:	74 15                	je     102a41 <mpinit+0xb1>
  102a2c:	31 d2                	xor    %edx,%edx
  102a2e:	31 c0                	xor    %eax,%eax
    sum += addr[i];
  102a30:	0f b6 0c 03          	movzbl (%ebx,%eax,1),%ecx
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
  102a34:	83 c0 01             	add    $0x1,%eax
    sum += addr[i];
  102a37:	01 ca                	add    %ecx,%edx
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
  102a39:	39 c7                	cmp    %eax,%edi
  102a3b:	7f f3                	jg     102a30 <mpinit+0xa0>
  conf = (struct mpconf*)mp->physaddr;
  if(memcmp(conf, "PCMP", 4) != 0)
    return 0;
  if(conf->version != 1 && conf->version != 4)
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
  102a3d:	84 d2                	test   %dl,%dl
  102a3f:	75 ce                	jne    102a0f <mpinit+0x7f>
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  102a41:	c7 05 04 bb 10 00 01 	movl   $0x1,0x10bb04
  102a48:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
  102a4b:	8b 43 24             	mov    0x24(%ebx),%eax
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
  102a4e:	8d 7b 2c             	lea    0x2c(%ebx),%edi

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  102a51:	a3 f8 ba 10 00       	mov    %eax,0x10baf8
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
  102a56:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
  102a5a:	01 c3                	add    %eax,%ebx
  102a5c:	39 df                	cmp    %ebx,%edi
  102a5e:	72 29                	jb     102a89 <mpinit+0xf9>
  102a60:	eb 52                	jmp    102ab4 <mpinit+0x124>
  102a62:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    case MPIOINTR:
    case MPLINTR:
      p += 8;
      continue;
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
  102a68:	0f b6 c0             	movzbl %al,%eax
  102a6b:	89 44 24 04          	mov    %eax,0x4(%esp)
  102a6f:	c7 04 24 98 69 10 00 	movl   $0x106998,(%esp)
  102a76:	e8 b5 da ff ff       	call   100530 <cprintf>
      ismp = 0;
  102a7b:	c7 05 04 bb 10 00 00 	movl   $0x0,0x10bb04
  102a82:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
  102a85:	39 fb                	cmp    %edi,%ebx
  102a87:	76 1e                	jbe    102aa7 <mpinit+0x117>
    switch(*p){
  102a89:	0f b6 07             	movzbl (%edi),%eax
  102a8c:	3c 04                	cmp    $0x4,%al
  102a8e:	77 d8                	ja     102a68 <mpinit+0xd8>
  102a90:	0f b6 c0             	movzbl %al,%eax
  102a93:	ff 24 85 b8 69 10 00 	jmp    *0x1069b8(,%eax,4)
  102a9a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
      p += sizeof(struct mpioapic);
      continue;
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
  102aa0:	83 c7 08             	add    $0x8,%edi
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
  102aa3:	39 fb                	cmp    %edi,%ebx
  102aa5:	77 e2                	ja     102a89 <mpinit+0xf9>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
  102aa7:	a1 04 bb 10 00       	mov    0x10bb04,%eax
  102aac:	85 c0                	test   %eax,%eax
  102aae:	0f 84 a4 00 00 00    	je     102b58 <mpinit+0x1c8>
    lapic = 0;
    ioapicid = 0;
    return;
  }

  if(mp->imcrp){
  102ab4:	80 7e 0c 00          	cmpb   $0x0,0xc(%esi)
  102ab8:	0f 84 51 ff ff ff    	je     102a0f <mpinit+0x7f>
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  102abe:	ba 22 00 00 00       	mov    $0x22,%edx
  102ac3:	b8 70 00 00 00       	mov    $0x70,%eax
  102ac8:	ee                   	out    %al,(%dx)
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  102ac9:	b2 23                	mov    $0x23,%dl
  102acb:	ec                   	in     (%dx),%al
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  102acc:	83 c8 01             	or     $0x1,%eax
  102acf:	ee                   	out    %al,(%dx)
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
  102ad0:	83 c4 1c             	add    $0x1c,%esp
  102ad3:	5b                   	pop    %ebx
  102ad4:	5e                   	pop    %esi
  102ad5:	5f                   	pop    %edi
  102ad6:	5d                   	pop    %ebp
  102ad7:	c3                   	ret    
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu != proc->apicid){
  102ad8:	0f b6 57 01          	movzbl 0x1(%edi),%edx
  102adc:	a1 00 c1 10 00       	mov    0x10c100,%eax
  102ae1:	39 c2                	cmp    %eax,%edx
  102ae3:	74 23                	je     102b08 <mpinit+0x178>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
  102ae5:	89 44 24 04          	mov    %eax,0x4(%esp)
  102ae9:	89 54 24 08          	mov    %edx,0x8(%esp)
  102aed:	c7 04 24 7d 69 10 00 	movl   $0x10697d,(%esp)
  102af4:	e8 37 da ff ff       	call   100530 <cprintf>
        ismp = 0;
  102af9:	a1 00 c1 10 00       	mov    0x10c100,%eax
  102afe:	c7 05 04 bb 10 00 00 	movl   $0x0,0x10bb04
  102b05:	00 00 00 
      }
      if(proc->flags & MPBOOT)
  102b08:	f6 47 03 02          	testb  $0x2,0x3(%edi)
  102b0c:	74 12                	je     102b20 <mpinit+0x190>
        bcpu = &cpus[ncpu];
  102b0e:	69 d0 bc 00 00 00    	imul   $0xbc,%eax,%edx
  102b14:	81 c2 20 bb 10 00    	add    $0x10bb20,%edx
  102b1a:	89 15 c4 78 10 00    	mov    %edx,0x1078c4
      cpus[ncpu].id = ncpu;
  102b20:	69 d0 bc 00 00 00    	imul   $0xbc,%eax,%edx
      ncpu++;
      p += sizeof(struct mpproc);
  102b26:	83 c7 14             	add    $0x14,%edi
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
        ismp = 0;
      }
      if(proc->flags & MPBOOT)
        bcpu = &cpus[ncpu];
      cpus[ncpu].id = ncpu;
  102b29:	88 82 20 bb 10 00    	mov    %al,0x10bb20(%edx)
      ncpu++;
  102b2f:	83 c0 01             	add    $0x1,%eax
  102b32:	a3 00 c1 10 00       	mov    %eax,0x10c100
      p += sizeof(struct mpproc);
      continue;
  102b37:	e9 49 ff ff ff       	jmp    102a85 <mpinit+0xf5>
  102b3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
  102b40:	0f b6 47 01          	movzbl 0x1(%edi),%eax
      p += sizeof(struct mpioapic);
  102b44:	83 c7 08             	add    $0x8,%edi
      ncpu++;
      p += sizeof(struct mpproc);
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
  102b47:	a2 00 bb 10 00       	mov    %al,0x10bb00
      p += sizeof(struct mpioapic);
      continue;
  102b4c:	e9 34 ff ff ff       	jmp    102a85 <mpinit+0xf5>
  102b51:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
      ismp = 0;
    }
  }
  if(!ismp){
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
  102b58:	c7 05 00 c1 10 00 01 	movl   $0x1,0x10c100
  102b5f:	00 00 00 
    lapic = 0;
  102b62:	c7 05 f8 ba 10 00 00 	movl   $0x0,0x10baf8
  102b69:	00 00 00 
    ioapicid = 0;
  102b6c:	c6 05 00 bb 10 00 00 	movb   $0x0,0x10bb00
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
  102b73:	83 c4 1c             	add    $0x1c,%esp
  102b76:	5b                   	pop    %ebx
  102b77:	5e                   	pop    %esi
  102b78:	5f                   	pop    %edi
  102b79:	5d                   	pop    %ebp
  102b7a:	c3                   	ret    
  102b7b:	90                   	nop
  102b7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1((uchar*)p-1024, 1024)))
      return mp;
  }
  return mpsearch1((uchar*)0xF0000, 0x10000);
  102b80:	ba 00 00 01 00       	mov    $0x10000,%edx
  102b85:	b8 00 00 0f 00       	mov    $0xf0000,%eax
  102b8a:	e8 91 fd ff ff       	call   102920 <mpsearch1>
mpconfig(struct mp **pmp)
{
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
  102b8f:	85 c0                	test   %eax,%eax
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1((uchar*)p-1024, 1024)))
      return mp;
  }
  return mpsearch1((uchar*)0xF0000, 0x10000);
  102b91:	89 c6                	mov    %eax,%esi
mpconfig(struct mp **pmp)
{
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
  102b93:	0f 85 53 fe ff ff    	jne    1029ec <mpinit+0x5c>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
  102b99:	83 c4 1c             	add    $0x1c,%esp
  102b9c:	5b                   	pop    %ebx
  102b9d:	5e                   	pop    %esi
  102b9e:	5f                   	pop    %edi
  102b9f:	5d                   	pop    %ebp
  102ba0:	c3                   	ret    
  102ba1:	90                   	nop
  102ba2:	90                   	nop
  102ba3:	90                   	nop
  102ba4:	90                   	nop
  102ba5:	90                   	nop
  102ba6:	90                   	nop
  102ba7:	90                   	nop
  102ba8:	90                   	nop
  102ba9:	90                   	nop
  102baa:	90                   	nop
  102bab:	90                   	nop
  102bac:	90                   	nop
  102bad:	90                   	nop
  102bae:	90                   	nop
  102baf:	90                   	nop

00102bb0 <picenable>:
  outb(IO_PIC2+1, mask >> 8);
}

void
picenable(int irq)
{
  102bb0:	55                   	push   %ebp
  picsetmask(irqmask & ~(1<<irq));
  102bb1:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
  outb(IO_PIC2+1, mask >> 8);
}

void
picenable(int irq)
{
  102bb6:	89 e5                	mov    %esp,%ebp
  102bb8:	ba 21 00 00 00       	mov    $0x21,%edx
  picsetmask(irqmask & ~(1<<irq));
  102bbd:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102bc0:	d3 c0                	rol    %cl,%eax
  102bc2:	66 23 05 20 73 10 00 	and    0x107320,%ax
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
  irqmask = mask;
  102bc9:	66 a3 20 73 10 00    	mov    %ax,0x107320
  102bcf:	ee                   	out    %al,(%dx)
  102bd0:	66 c1 e8 08          	shr    $0x8,%ax
  102bd4:	b2 a1                	mov    $0xa1,%dl
  102bd6:	ee                   	out    %al,(%dx)

void
picenable(int irq)
{
  picsetmask(irqmask & ~(1<<irq));
}
  102bd7:	5d                   	pop    %ebp
  102bd8:	c3                   	ret    
  102bd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00102be0 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
  102be0:	55                   	push   %ebp
  102be1:	b9 21 00 00 00       	mov    $0x21,%ecx
  102be6:	89 e5                	mov    %esp,%ebp
  102be8:	83 ec 0c             	sub    $0xc,%esp
  102beb:	89 1c 24             	mov    %ebx,(%esp)
  102bee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  102bf3:	89 ca                	mov    %ecx,%edx
  102bf5:	89 74 24 04          	mov    %esi,0x4(%esp)
  102bf9:	89 7c 24 08          	mov    %edi,0x8(%esp)
  102bfd:	ee                   	out    %al,(%dx)
  102bfe:	bb a1 00 00 00       	mov    $0xa1,%ebx
  102c03:	89 da                	mov    %ebx,%edx
  102c05:	ee                   	out    %al,(%dx)
  102c06:	be 11 00 00 00       	mov    $0x11,%esi
  102c0b:	b2 20                	mov    $0x20,%dl
  102c0d:	89 f0                	mov    %esi,%eax
  102c0f:	ee                   	out    %al,(%dx)
  102c10:	b8 20 00 00 00       	mov    $0x20,%eax
  102c15:	89 ca                	mov    %ecx,%edx
  102c17:	ee                   	out    %al,(%dx)
  102c18:	b8 04 00 00 00       	mov    $0x4,%eax
  102c1d:	ee                   	out    %al,(%dx)
  102c1e:	bf 03 00 00 00       	mov    $0x3,%edi
  102c23:	89 f8                	mov    %edi,%eax
  102c25:	ee                   	out    %al,(%dx)
  102c26:	b1 a0                	mov    $0xa0,%cl
  102c28:	89 f0                	mov    %esi,%eax
  102c2a:	89 ca                	mov    %ecx,%edx
  102c2c:	ee                   	out    %al,(%dx)
  102c2d:	b8 28 00 00 00       	mov    $0x28,%eax
  102c32:	89 da                	mov    %ebx,%edx
  102c34:	ee                   	out    %al,(%dx)
  102c35:	b8 02 00 00 00       	mov    $0x2,%eax
  102c3a:	ee                   	out    %al,(%dx)
  102c3b:	89 f8                	mov    %edi,%eax
  102c3d:	ee                   	out    %al,(%dx)
  102c3e:	be 68 00 00 00       	mov    $0x68,%esi
  102c43:	b2 20                	mov    $0x20,%dl
  102c45:	89 f0                	mov    %esi,%eax
  102c47:	ee                   	out    %al,(%dx)
  102c48:	bb 0a 00 00 00       	mov    $0xa,%ebx
  102c4d:	89 d8                	mov    %ebx,%eax
  102c4f:	ee                   	out    %al,(%dx)
  102c50:	89 f0                	mov    %esi,%eax
  102c52:	89 ca                	mov    %ecx,%edx
  102c54:	ee                   	out    %al,(%dx)
  102c55:	89 d8                	mov    %ebx,%eax
  102c57:	ee                   	out    %al,(%dx)
  outb(IO_PIC1, 0x0a);             // read IRR by default

  outb(IO_PIC2, 0x68);             // OCW3
  outb(IO_PIC2, 0x0a);             // OCW3

  if(irqmask != 0xFFFF)
  102c58:	0f b7 05 20 73 10 00 	movzwl 0x107320,%eax
  102c5f:	66 83 f8 ff          	cmp    $0xffffffff,%ax
  102c63:	74 0a                	je     102c6f <picinit+0x8f>
  102c65:	b2 21                	mov    $0x21,%dl
  102c67:	ee                   	out    %al,(%dx)
  102c68:	66 c1 e8 08          	shr    $0x8,%ax
  102c6c:	b2 a1                	mov    $0xa1,%dl
  102c6e:	ee                   	out    %al,(%dx)
    picsetmask(irqmask);
}
  102c6f:	8b 1c 24             	mov    (%esp),%ebx
  102c72:	8b 74 24 04          	mov    0x4(%esp),%esi
  102c76:	8b 7c 24 08          	mov    0x8(%esp),%edi
  102c7a:	89 ec                	mov    %ebp,%esp
  102c7c:	5d                   	pop    %ebp
  102c7d:	c3                   	ret    
  102c7e:	90                   	nop
  102c7f:	90                   	nop

00102c80 <piperead>:
  return n;
}

int
piperead(struct pipe *p, char *addr, int n)
{
  102c80:	55                   	push   %ebp
  102c81:	89 e5                	mov    %esp,%ebp
  102c83:	57                   	push   %edi
  102c84:	56                   	push   %esi
  102c85:	53                   	push   %ebx
  102c86:	83 ec 1c             	sub    $0x1c,%esp
  102c89:	8b 5d 08             	mov    0x8(%ebp),%ebx
  102c8c:	8b 7d 10             	mov    0x10(%ebp),%edi
  int i;

  acquire(&p->lock);
  102c8f:	89 1c 24             	mov    %ebx,(%esp)
  102c92:	e8 b9 0e 00 00       	call   103b50 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
  102c97:	8b 93 34 02 00 00    	mov    0x234(%ebx),%edx
  102c9d:	3b 93 38 02 00 00    	cmp    0x238(%ebx),%edx
  102ca3:	75 58                	jne    102cfd <piperead+0x7d>
  102ca5:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
  102cab:	85 f6                	test   %esi,%esi
  102cad:	74 4e                	je     102cfd <piperead+0x7d>
    if(proc->killed){
  102caf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  102cb5:	8d b3 34 02 00 00    	lea    0x234(%ebx),%esi
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
    if(proc->killed){
  102cbb:	8b 48 24             	mov    0x24(%eax),%ecx
  102cbe:	85 c9                	test   %ecx,%ecx
  102cc0:	74 21                	je     102ce3 <piperead+0x63>
  102cc2:	e9 99 00 00 00       	jmp    102d60 <piperead+0xe0>
  102cc7:	90                   	nop
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
  102cc8:	8b 83 40 02 00 00    	mov    0x240(%ebx),%eax
  102cce:	85 c0                	test   %eax,%eax
  102cd0:	74 2b                	je     102cfd <piperead+0x7d>
    if(proc->killed){
  102cd2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  102cd8:	8b 50 24             	mov    0x24(%eax),%edx
  102cdb:	85 d2                	test   %edx,%edx
  102cdd:	0f 85 7d 00 00 00    	jne    102d60 <piperead+0xe0>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  102ce3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  102ce7:	89 34 24             	mov    %esi,(%esp)
  102cea:	e8 81 05 00 00       	call   103270 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
  102cef:	8b 93 34 02 00 00    	mov    0x234(%ebx),%edx
  102cf5:	3b 93 38 02 00 00    	cmp    0x238(%ebx),%edx
  102cfb:	74 cb                	je     102cc8 <piperead+0x48>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
  102cfd:	85 ff                	test   %edi,%edi
  102cff:	7e 76                	jle    102d77 <piperead+0xf7>
    if(p->nread == p->nwrite)
  102d01:	31 f6                	xor    %esi,%esi
  102d03:	3b 93 38 02 00 00    	cmp    0x238(%ebx),%edx
  102d09:	75 0d                	jne    102d18 <piperead+0x98>
  102d0b:	eb 6a                	jmp    102d77 <piperead+0xf7>
  102d0d:	8d 76 00             	lea    0x0(%esi),%esi
  102d10:	39 93 38 02 00 00    	cmp    %edx,0x238(%ebx)
  102d16:	74 22                	je     102d3a <piperead+0xba>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  102d18:	89 d0                	mov    %edx,%eax
  102d1a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  102d1d:	83 c2 01             	add    $0x1,%edx
  102d20:	25 ff 01 00 00       	and    $0x1ff,%eax
  102d25:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
  102d2a:	88 04 31             	mov    %al,(%ecx,%esi,1)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
  102d2d:	83 c6 01             	add    $0x1,%esi
  102d30:	39 f7                	cmp    %esi,%edi
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  102d32:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
  102d38:	7f d6                	jg     102d10 <piperead+0x90>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
  102d3a:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
  102d40:	89 04 24             	mov    %eax,(%esp)
  102d43:	e8 08 04 00 00       	call   103150 <wakeup>
  release(&p->lock);
  102d48:	89 1c 24             	mov    %ebx,(%esp)
  102d4b:	e8 b0 0d 00 00       	call   103b00 <release>
  return i;
}
  102d50:	83 c4 1c             	add    $0x1c,%esp
  102d53:	89 f0                	mov    %esi,%eax
  102d55:	5b                   	pop    %ebx
  102d56:	5e                   	pop    %esi
  102d57:	5f                   	pop    %edi
  102d58:	5d                   	pop    %ebp
  102d59:	c3                   	ret    
  102d5a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
    if(proc->killed){
      release(&p->lock);
  102d60:	be ff ff ff ff       	mov    $0xffffffff,%esi
  102d65:	89 1c 24             	mov    %ebx,(%esp)
  102d68:	e8 93 0d 00 00       	call   103b00 <release>
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
  release(&p->lock);
  return i;
}
  102d6d:	83 c4 1c             	add    $0x1c,%esp
  102d70:	89 f0                	mov    %esi,%eax
  102d72:	5b                   	pop    %ebx
  102d73:	5e                   	pop    %esi
  102d74:	5f                   	pop    %edi
  102d75:	5d                   	pop    %ebp
  102d76:	c3                   	ret    
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
  102d77:	31 f6                	xor    %esi,%esi
  102d79:	eb bf                	jmp    102d3a <piperead+0xba>
  102d7b:	90                   	nop
  102d7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00102d80 <pipewrite>:
    release(&p->lock);
}

int
pipewrite(struct pipe *p, char *addr, int n)
{
  102d80:	55                   	push   %ebp
  102d81:	89 e5                	mov    %esp,%ebp
  102d83:	57                   	push   %edi
  102d84:	56                   	push   %esi
  102d85:	53                   	push   %ebx
  102d86:	83 ec 3c             	sub    $0x3c,%esp
  102d89:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
  102d8c:	89 1c 24             	mov    %ebx,(%esp)
  102d8f:	8d b3 34 02 00 00    	lea    0x234(%ebx),%esi
  102d95:	e8 b6 0d 00 00       	call   103b50 <acquire>
  for(i = 0; i < n; i++){
  102d9a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102d9d:	85 c9                	test   %ecx,%ecx
  102d9f:	0f 8e 8d 00 00 00    	jle    102e32 <pipewrite+0xb2>
  102da5:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
      if(p->readopen == 0 || proc->killed){
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
  102dab:	8d bb 38 02 00 00    	lea    0x238(%ebx),%edi
  102db1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  102db8:	eb 37                	jmp    102df1 <pipewrite+0x71>
  102dba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
  102dc0:	8b 83 3c 02 00 00    	mov    0x23c(%ebx),%eax
  102dc6:	85 c0                	test   %eax,%eax
  102dc8:	74 7e                	je     102e48 <pipewrite+0xc8>
  102dca:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  102dd0:	8b 50 24             	mov    0x24(%eax),%edx
  102dd3:	85 d2                	test   %edx,%edx
  102dd5:	75 71                	jne    102e48 <pipewrite+0xc8>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
  102dd7:	89 34 24             	mov    %esi,(%esp)
  102dda:	e8 71 03 00 00       	call   103150 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
  102ddf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  102de3:	89 3c 24             	mov    %edi,(%esp)
  102de6:	e8 85 04 00 00       	call   103270 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
  102deb:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
  102df1:	8b 93 34 02 00 00    	mov    0x234(%ebx),%edx
  102df7:	81 c2 00 02 00 00    	add    $0x200,%edx
  102dfd:	39 d0                	cmp    %edx,%eax
  102dff:	74 bf                	je     102dc0 <pipewrite+0x40>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  102e01:	89 c2                	mov    %eax,%edx
  102e03:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  102e06:	83 c0 01             	add    $0x1,%eax
  102e09:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
  102e0f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  102e12:	8b 55 0c             	mov    0xc(%ebp),%edx
  102e15:	0f b6 0c 0a          	movzbl (%edx,%ecx,1),%ecx
  102e19:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  102e1c:	88 4c 13 34          	mov    %cl,0x34(%ebx,%edx,1)
  102e20:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
  102e26:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
  102e2a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  102e2d:	39 4d 10             	cmp    %ecx,0x10(%ebp)
  102e30:	7f bf                	jg     102df1 <pipewrite+0x71>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  102e32:	89 34 24             	mov    %esi,(%esp)
  102e35:	e8 16 03 00 00       	call   103150 <wakeup>
  release(&p->lock);
  102e3a:	89 1c 24             	mov    %ebx,(%esp)
  102e3d:	e8 be 0c 00 00       	call   103b00 <release>
  return n;
  102e42:	eb 13                	jmp    102e57 <pipewrite+0xd7>
  102e44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
        release(&p->lock);
  102e48:	89 1c 24             	mov    %ebx,(%esp)
  102e4b:	e8 b0 0c 00 00       	call   103b00 <release>
  102e50:	c7 45 10 ff ff ff ff 	movl   $0xffffffff,0x10(%ebp)
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
  102e57:	8b 45 10             	mov    0x10(%ebp),%eax
  102e5a:	83 c4 3c             	add    $0x3c,%esp
  102e5d:	5b                   	pop    %ebx
  102e5e:	5e                   	pop    %esi
  102e5f:	5f                   	pop    %edi
  102e60:	5d                   	pop    %ebp
  102e61:	c3                   	ret    
  102e62:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  102e69:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00102e70 <pipeclose>:
  return -1;
}

void
pipeclose(struct pipe *p, int writable)
{
  102e70:	55                   	push   %ebp
  102e71:	89 e5                	mov    %esp,%ebp
  102e73:	83 ec 18             	sub    $0x18,%esp
  102e76:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  102e79:	8b 5d 08             	mov    0x8(%ebp),%ebx
  102e7c:	89 75 fc             	mov    %esi,-0x4(%ebp)
  102e7f:	8b 75 0c             	mov    0xc(%ebp),%esi
  acquire(&p->lock);
  102e82:	89 1c 24             	mov    %ebx,(%esp)
  102e85:	e8 c6 0c 00 00       	call   103b50 <acquire>
  if(writable){
  102e8a:	85 f6                	test   %esi,%esi
  102e8c:	74 42                	je     102ed0 <pipeclose+0x60>
    p->writeopen = 0;
    wakeup(&p->nread);
  102e8e:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
void
pipeclose(struct pipe *p, int writable)
{
  acquire(&p->lock);
  if(writable){
    p->writeopen = 0;
  102e94:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
  102e9b:	00 00 00 
    wakeup(&p->nread);
  102e9e:	89 04 24             	mov    %eax,(%esp)
  102ea1:	e8 aa 02 00 00       	call   103150 <wakeup>
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
  102ea6:	8b 83 3c 02 00 00    	mov    0x23c(%ebx),%eax
  102eac:	85 c0                	test   %eax,%eax
  102eae:	75 0a                	jne    102eba <pipeclose+0x4a>
  102eb0:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
  102eb6:	85 f6                	test   %esi,%esi
  102eb8:	74 36                	je     102ef0 <pipeclose+0x80>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
  102eba:	89 5d 08             	mov    %ebx,0x8(%ebp)
}
  102ebd:	8b 75 fc             	mov    -0x4(%ebp),%esi
  102ec0:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  102ec3:	89 ec                	mov    %ebp,%esp
  102ec5:	5d                   	pop    %ebp
  }
  if(p->readopen == 0 && p->writeopen == 0){
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
  102ec6:	e9 35 0c 00 00       	jmp    103b00 <release>
  102ecb:	90                   	nop
  102ecc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  if(writable){
    p->writeopen = 0;
    wakeup(&p->nread);
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  102ed0:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
  acquire(&p->lock);
  if(writable){
    p->writeopen = 0;
    wakeup(&p->nread);
  } else {
    p->readopen = 0;
  102ed6:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
  102edd:	00 00 00 
    wakeup(&p->nwrite);
  102ee0:	89 04 24             	mov    %eax,(%esp)
  102ee3:	e8 68 02 00 00       	call   103150 <wakeup>
  102ee8:	eb bc                	jmp    102ea6 <pipeclose+0x36>
  102eea:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  }
  if(p->readopen == 0 && p->writeopen == 0){
    release(&p->lock);
  102ef0:	89 1c 24             	mov    %ebx,(%esp)
  102ef3:	e8 08 0c 00 00       	call   103b00 <release>
    kfree((char*)p);
  } else
    release(&p->lock);
}
  102ef8:	8b 75 fc             	mov    -0x4(%ebp),%esi
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
    release(&p->lock);
    kfree((char*)p);
  102efb:	89 5d 08             	mov    %ebx,0x8(%ebp)
  } else
    release(&p->lock);
}
  102efe:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  102f01:	89 ec                	mov    %ebp,%esp
  102f03:	5d                   	pop    %ebp
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
    release(&p->lock);
    kfree((char*)p);
  102f04:	e9 87 f3 ff ff       	jmp    102290 <kfree>
  102f09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00102f10 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
  102f10:	55                   	push   %ebp
  102f11:	89 e5                	mov    %esp,%ebp
  102f13:	57                   	push   %edi
  102f14:	56                   	push   %esi
  102f15:	53                   	push   %ebx
  102f16:	83 ec 1c             	sub    $0x1c,%esp
  102f19:	8b 75 08             	mov    0x8(%ebp),%esi
  102f1c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
  102f1f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  102f25:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
  102f2b:	e8 d0 df ff ff       	call   100f00 <filealloc>
  102f30:	85 c0                	test   %eax,%eax
  102f32:	89 06                	mov    %eax,(%esi)
  102f34:	0f 84 9c 00 00 00    	je     102fd6 <pipealloc+0xc6>
  102f3a:	e8 c1 df ff ff       	call   100f00 <filealloc>
  102f3f:	85 c0                	test   %eax,%eax
  102f41:	89 03                	mov    %eax,(%ebx)
  102f43:	0f 84 7f 00 00 00    	je     102fc8 <pipealloc+0xb8>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
  102f49:	e8 02 f3 ff ff       	call   102250 <kalloc>
  102f4e:	85 c0                	test   %eax,%eax
  102f50:	89 c7                	mov    %eax,%edi
  102f52:	74 74                	je     102fc8 <pipealloc+0xb8>
    goto bad;
  p->readopen = 1;
  102f54:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
  102f5b:	00 00 00 
  p->writeopen = 1;
  102f5e:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
  102f65:	00 00 00 
  p->nwrite = 0;
  102f68:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
  102f6f:	00 00 00 
  p->nread = 0;
  102f72:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
  102f79:	00 00 00 
  initlock(&p->lock, "pipe");
  102f7c:	89 04 24             	mov    %eax,(%esp)
  102f7f:	c7 44 24 04 cc 69 10 	movl   $0x1069cc,0x4(%esp)
  102f86:	00 
  102f87:	e8 34 0a 00 00       	call   1039c0 <initlock>
  (*f0)->type = FD_PIPE;
  102f8c:	8b 06                	mov    (%esi),%eax
  102f8e:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
  102f94:	8b 06                	mov    (%esi),%eax
  102f96:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
  102f9a:	8b 06                	mov    (%esi),%eax
  102f9c:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
  102fa0:	8b 06                	mov    (%esi),%eax
  102fa2:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
  102fa5:	8b 03                	mov    (%ebx),%eax
  102fa7:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
  102fad:	8b 03                	mov    (%ebx),%eax
  102faf:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
  102fb3:	8b 03                	mov    (%ebx),%eax
  102fb5:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
  102fb9:	8b 03                	mov    (%ebx),%eax
  102fbb:	89 78 0c             	mov    %edi,0xc(%eax)
  102fbe:	31 c0                	xor    %eax,%eax
  if(*f0)
    fileclose(*f0);
  if(*f1)
    fileclose(*f1);
  return -1;
}
  102fc0:	83 c4 1c             	add    $0x1c,%esp
  102fc3:	5b                   	pop    %ebx
  102fc4:	5e                   	pop    %esi
  102fc5:	5f                   	pop    %edi
  102fc6:	5d                   	pop    %ebp
  102fc7:	c3                   	ret    
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
  102fc8:	8b 06                	mov    (%esi),%eax
  102fca:	85 c0                	test   %eax,%eax
  102fcc:	74 08                	je     102fd6 <pipealloc+0xc6>
    fileclose(*f0);
  102fce:	89 04 24             	mov    %eax,(%esp)
  102fd1:	e8 aa df ff ff       	call   100f80 <fileclose>
  if(*f1)
  102fd6:	8b 13                	mov    (%ebx),%edx
  102fd8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  102fdd:	85 d2                	test   %edx,%edx
  102fdf:	74 df                	je     102fc0 <pipealloc+0xb0>
    fileclose(*f1);
  102fe1:	89 14 24             	mov    %edx,(%esp)
  102fe4:	e8 97 df ff ff       	call   100f80 <fileclose>
  102fe9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  102fee:	eb d0                	jmp    102fc0 <pipealloc+0xb0>

00102ff0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  102ff0:	55                   	push   %ebp
  102ff1:	89 e5                	mov    %esp,%ebp
  102ff3:	57                   	push   %edi
  102ff4:	56                   	push   %esi
  102ff5:	53                   	push   %ebx

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
  102ff6:	bb 54 c1 10 00       	mov    $0x10c154,%ebx
{
  102ffb:	83 ec 4c             	sub    $0x4c,%esp
      state = states[p->state];
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
  102ffe:	8d 7d c0             	lea    -0x40(%ebp),%edi
  103001:	eb 4b                	jmp    10304e <procdump+0x5e>
  103003:	90                   	nop
  103004:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
  103008:	8b 04 85 a4 6a 10 00 	mov    0x106aa4(,%eax,4),%eax
  10300f:	85 c0                	test   %eax,%eax
  103011:	74 47                	je     10305a <procdump+0x6a>
      state = states[p->state];
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
  103013:	8b 53 10             	mov    0x10(%ebx),%edx
  103016:	8d 4b 6c             	lea    0x6c(%ebx),%ecx
  103019:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  10301d:	89 44 24 08          	mov    %eax,0x8(%esp)
  103021:	c7 04 24 d5 69 10 00 	movl   $0x1069d5,(%esp)
  103028:	89 54 24 04          	mov    %edx,0x4(%esp)
  10302c:	e8 ff d4 ff ff       	call   100530 <cprintf>
    if(p->state == SLEEPING){
  103031:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
  103035:	74 31                	je     103068 <procdump+0x78>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  103037:	c7 04 24 56 69 10 00 	movl   $0x106956,(%esp)
  10303e:	e8 ed d4 ff ff       	call   100530 <cprintf>
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  103043:	83 c3 7c             	add    $0x7c,%ebx
  103046:	81 fb 54 e0 10 00    	cmp    $0x10e054,%ebx
  10304c:	74 5a                	je     1030a8 <procdump+0xb8>
    if(p->state == UNUSED)
  10304e:	8b 43 0c             	mov    0xc(%ebx),%eax
  103051:	85 c0                	test   %eax,%eax
  103053:	74 ee                	je     103043 <procdump+0x53>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
  103055:	83 f8 05             	cmp    $0x5,%eax
  103058:	76 ae                	jbe    103008 <procdump+0x18>
  10305a:	b8 d1 69 10 00       	mov    $0x1069d1,%eax
  10305f:	eb b2                	jmp    103013 <procdump+0x23>
  103061:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
      state = states[p->state];
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
  103068:	8b 43 1c             	mov    0x1c(%ebx),%eax
  10306b:	31 f6                	xor    %esi,%esi
  10306d:	89 7c 24 04          	mov    %edi,0x4(%esp)
  103071:	8b 40 0c             	mov    0xc(%eax),%eax
  103074:	83 c0 08             	add    $0x8,%eax
  103077:	89 04 24             	mov    %eax,(%esp)
  10307a:	e8 61 09 00 00       	call   1039e0 <getcallerpcs>
  10307f:	90                   	nop
      for(i=0; i<10 && pc[i] != 0; i++)
  103080:	8b 04 b7             	mov    (%edi,%esi,4),%eax
  103083:	85 c0                	test   %eax,%eax
  103085:	74 b0                	je     103037 <procdump+0x47>
  103087:	83 c6 01             	add    $0x1,%esi
        cprintf(" %p", pc[i]);
  10308a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10308e:	c7 04 24 4a 65 10 00 	movl   $0x10654a,(%esp)
  103095:	e8 96 d4 ff ff       	call   100530 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
  10309a:	83 fe 0a             	cmp    $0xa,%esi
  10309d:	75 e1                	jne    103080 <procdump+0x90>
  10309f:	eb 96                	jmp    103037 <procdump+0x47>
  1030a1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
  1030a8:	83 c4 4c             	add    $0x4c,%esp
  1030ab:	5b                   	pop    %ebx
  1030ac:	5e                   	pop    %esi
  1030ad:	5f                   	pop    %edi
  1030ae:	5d                   	pop    %ebp
  1030af:	90                   	nop
  1030b0:	c3                   	ret    
  1030b1:	eb 0d                	jmp    1030c0 <kill>
  1030b3:	90                   	nop
  1030b4:	90                   	nop
  1030b5:	90                   	nop
  1030b6:	90                   	nop
  1030b7:	90                   	nop
  1030b8:	90                   	nop
  1030b9:	90                   	nop
  1030ba:	90                   	nop
  1030bb:	90                   	nop
  1030bc:	90                   	nop
  1030bd:	90                   	nop
  1030be:	90                   	nop
  1030bf:	90                   	nop

001030c0 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
  1030c0:	55                   	push   %ebp
  1030c1:	89 e5                	mov    %esp,%ebp
  1030c3:	53                   	push   %ebx
  1030c4:	83 ec 14             	sub    $0x14,%esp
  1030c7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
  1030ca:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  1030d1:	e8 7a 0a 00 00       	call   103b50 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->pid == pid){
  1030d6:	8b 15 64 c1 10 00    	mov    0x10c164,%edx

// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
  1030dc:	b8 d0 c1 10 00       	mov    $0x10c1d0,%eax
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->pid == pid){
  1030e1:	39 da                	cmp    %ebx,%edx
  1030e3:	75 0d                	jne    1030f2 <kill+0x32>
  1030e5:	eb 60                	jmp    103147 <kill+0x87>
  1030e7:	90                   	nop
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  1030e8:	83 c0 7c             	add    $0x7c,%eax
  1030eb:	3d 54 e0 10 00       	cmp    $0x10e054,%eax
  1030f0:	74 3e                	je     103130 <kill+0x70>
    if(p->pid == pid){
  1030f2:	8b 50 10             	mov    0x10(%eax),%edx
  1030f5:	39 da                	cmp    %ebx,%edx
  1030f7:	75 ef                	jne    1030e8 <kill+0x28>
      p->killed = 1;
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
  1030f9:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->pid == pid){
      p->killed = 1;
  1030fd:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
  103104:	74 1a                	je     103120 <kill+0x60>
        p->state = RUNNABLE;
      release(&ptable.lock);
  103106:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  10310d:	e8 ee 09 00 00       	call   103b00 <release>
      return 0;
    }
  }
  release(&ptable.lock);
  return -1;
}
  103112:	83 c4 14             	add    $0x14,%esp
    if(p->pid == pid){
      p->killed = 1;
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
        p->state = RUNNABLE;
      release(&ptable.lock);
  103115:	31 c0                	xor    %eax,%eax
      return 0;
    }
  }
  release(&ptable.lock);
  return -1;
}
  103117:	5b                   	pop    %ebx
  103118:	5d                   	pop    %ebp
  103119:	c3                   	ret    
  10311a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->pid == pid){
      p->killed = 1;
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
        p->state = RUNNABLE;
  103120:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  103127:	eb dd                	jmp    103106 <kill+0x46>
  103129:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
  103130:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  103137:	e8 c4 09 00 00       	call   103b00 <release>
  return -1;
}
  10313c:	83 c4 14             	add    $0x14,%esp
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
  10313f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  return -1;
}
  103144:	5b                   	pop    %ebx
  103145:	5d                   	pop    %ebp
  103146:	c3                   	ret    
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->pid == pid){
  103147:	b8 54 c1 10 00       	mov    $0x10c154,%eax
  10314c:	eb ab                	jmp    1030f9 <kill+0x39>
  10314e:	66 90                	xchg   %ax,%ax

00103150 <wakeup>:
}

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
  103150:	55                   	push   %ebp
  103151:	89 e5                	mov    %esp,%ebp
  103153:	53                   	push   %ebx
  103154:	83 ec 14             	sub    $0x14,%esp
  103157:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ptable.lock);
  10315a:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  103161:	e8 ea 09 00 00       	call   103b50 <acquire>
      p->state = RUNNABLE;
}

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
  103166:	b8 54 c1 10 00       	mov    $0x10c154,%eax
  10316b:	eb 0d                	jmp    10317a <wakeup+0x2a>
  10316d:	8d 76 00             	lea    0x0(%esi),%esi
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  103170:	83 c0 7c             	add    $0x7c,%eax
  103173:	3d 54 e0 10 00       	cmp    $0x10e054,%eax
  103178:	74 1e                	je     103198 <wakeup+0x48>
    if(p->state == SLEEPING && p->chan == chan)
  10317a:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
  10317e:	75 f0                	jne    103170 <wakeup+0x20>
  103180:	3b 58 20             	cmp    0x20(%eax),%ebx
  103183:	75 eb                	jne    103170 <wakeup+0x20>
      p->state = RUNNABLE;
  103185:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  10318c:	83 c0 7c             	add    $0x7c,%eax
  10318f:	3d 54 e0 10 00       	cmp    $0x10e054,%eax
  103194:	75 e4                	jne    10317a <wakeup+0x2a>
  103196:	66 90                	xchg   %ax,%ax
void
wakeup(void *chan)
{
  acquire(&ptable.lock);
  wakeup1(chan);
  release(&ptable.lock);
  103198:	c7 45 08 20 c1 10 00 	movl   $0x10c120,0x8(%ebp)
}
  10319f:	83 c4 14             	add    $0x14,%esp
  1031a2:	5b                   	pop    %ebx
  1031a3:	5d                   	pop    %ebp
void
wakeup(void *chan)
{
  acquire(&ptable.lock);
  wakeup1(chan);
  release(&ptable.lock);
  1031a4:	e9 57 09 00 00       	jmp    103b00 <release>
  1031a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

001031b0 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
  1031b0:	55                   	push   %ebp
  1031b1:	89 e5                	mov    %esp,%ebp
  1031b3:	83 ec 18             	sub    $0x18,%esp
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
  1031b6:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  1031bd:	e8 3e 09 00 00       	call   103b00 <release>
  
  // Return to "caller", actually trapret (see allocproc).
}
  1031c2:	c9                   	leave  
  1031c3:	c3                   	ret    
  1031c4:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1031ca:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

001031d0 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
  1031d0:	55                   	push   %ebp
  1031d1:	89 e5                	mov    %esp,%ebp
  1031d3:	53                   	push   %ebx
  1031d4:	83 ec 14             	sub    $0x14,%esp
  int intena;

  if(!holding(&ptable.lock))
  1031d7:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  1031de:	e8 5d 08 00 00       	call   103a40 <holding>
  1031e3:	85 c0                	test   %eax,%eax
  1031e5:	74 4d                	je     103234 <sched+0x64>
    panic("sched ptable.lock");
  if(cpu->ncli != 1)
  1031e7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  1031ed:	83 b8 ac 00 00 00 01 	cmpl   $0x1,0xac(%eax)
  1031f4:	75 62                	jne    103258 <sched+0x88>
    panic("sched locks");
  if(proc->state == RUNNING)
  1031f6:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  1031fd:	83 7a 0c 04          	cmpl   $0x4,0xc(%edx)
  103201:	74 49                	je     10324c <sched+0x7c>

static inline uint
readeflags(void)
{
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
  103203:	9c                   	pushf  
  103204:	59                   	pop    %ecx
    panic("sched running");
  if(readeflags()&FL_IF)
  103205:	80 e5 02             	and    $0x2,%ch
  103208:	75 36                	jne    103240 <sched+0x70>
    panic("sched interruptible");
  intena = cpu->intena;
  10320a:	8b 98 b0 00 00 00    	mov    0xb0(%eax),%ebx
  swtch(&proc->context, cpu->scheduler);
  103210:	83 c2 1c             	add    $0x1c,%edx
  103213:	8b 40 04             	mov    0x4(%eax),%eax
  103216:	89 14 24             	mov    %edx,(%esp)
  103219:	89 44 24 04          	mov    %eax,0x4(%esp)
  10321d:	e8 ca 0b 00 00       	call   103dec <swtch>
  cpu->intena = intena;
  103222:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  103228:	89 98 b0 00 00 00    	mov    %ebx,0xb0(%eax)
}
  10322e:	83 c4 14             	add    $0x14,%esp
  103231:	5b                   	pop    %ebx
  103232:	5d                   	pop    %ebp
  103233:	c3                   	ret    
sched(void)
{
  int intena;

  if(!holding(&ptable.lock))
    panic("sched ptable.lock");
  103234:	c7 04 24 de 69 10 00 	movl   $0x1069de,(%esp)
  10323b:	e8 e0 d6 ff ff       	call   100920 <panic>
  if(cpu->ncli != 1)
    panic("sched locks");
  if(proc->state == RUNNING)
    panic("sched running");
  if(readeflags()&FL_IF)
    panic("sched interruptible");
  103240:	c7 04 24 0a 6a 10 00 	movl   $0x106a0a,(%esp)
  103247:	e8 d4 d6 ff ff       	call   100920 <panic>
  if(!holding(&ptable.lock))
    panic("sched ptable.lock");
  if(cpu->ncli != 1)
    panic("sched locks");
  if(proc->state == RUNNING)
    panic("sched running");
  10324c:	c7 04 24 fc 69 10 00 	movl   $0x1069fc,(%esp)
  103253:	e8 c8 d6 ff ff       	call   100920 <panic>
  int intena;

  if(!holding(&ptable.lock))
    panic("sched ptable.lock");
  if(cpu->ncli != 1)
    panic("sched locks");
  103258:	c7 04 24 f0 69 10 00 	movl   $0x1069f0,(%esp)
  10325f:	e8 bc d6 ff ff       	call   100920 <panic>
  103264:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  10326a:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

00103270 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  103270:	55                   	push   %ebp
  103271:	89 e5                	mov    %esp,%ebp
  103273:	56                   	push   %esi
  103274:	53                   	push   %ebx
  103275:	83 ec 10             	sub    $0x10,%esp
  if(proc == 0)
  103278:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  10327e:	8b 75 08             	mov    0x8(%ebp),%esi
  103281:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  if(proc == 0)
  103284:	85 c0                	test   %eax,%eax
  103286:	0f 84 a1 00 00 00    	je     10332d <sleep+0xbd>
    panic("sleep");

  if(lk == 0)
  10328c:	85 db                	test   %ebx,%ebx
  10328e:	0f 84 8d 00 00 00    	je     103321 <sleep+0xb1>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
  103294:	81 fb 20 c1 10 00    	cmp    $0x10c120,%ebx
  10329a:	74 5c                	je     1032f8 <sleep+0x88>
    acquire(&ptable.lock);  //DOC: sleeplock1
  10329c:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  1032a3:	e8 a8 08 00 00       	call   103b50 <acquire>
    release(lk);
  1032a8:	89 1c 24             	mov    %ebx,(%esp)
  1032ab:	e8 50 08 00 00       	call   103b00 <release>
  }

  // Go to sleep.
  proc->chan = chan;
  1032b0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1032b6:	89 70 20             	mov    %esi,0x20(%eax)
  proc->state = SLEEPING;
  1032b9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1032bf:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
  1032c6:	e8 05 ff ff ff       	call   1031d0 <sched>

  // Tidy up.
  proc->chan = 0;
  1032cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1032d1:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
    release(&ptable.lock);
  1032d8:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  1032df:	e8 1c 08 00 00       	call   103b00 <release>
    acquire(lk);
  1032e4:	89 5d 08             	mov    %ebx,0x8(%ebp)
  }
}
  1032e7:	83 c4 10             	add    $0x10,%esp
  1032ea:	5b                   	pop    %ebx
  1032eb:	5e                   	pop    %esi
  1032ec:	5d                   	pop    %ebp
  proc->chan = 0;

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
    release(&ptable.lock);
    acquire(lk);
  1032ed:	e9 5e 08 00 00       	jmp    103b50 <acquire>
  1032f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    acquire(&ptable.lock);  //DOC: sleeplock1
    release(lk);
  }

  // Go to sleep.
  proc->chan = chan;
  1032f8:	89 70 20             	mov    %esi,0x20(%eax)
  proc->state = SLEEPING;
  1032fb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103301:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
  103308:	e8 c3 fe ff ff       	call   1031d0 <sched>

  // Tidy up.
  proc->chan = 0;
  10330d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103313:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)
  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
    release(&ptable.lock);
    acquire(lk);
  }
}
  10331a:	83 c4 10             	add    $0x10,%esp
  10331d:	5b                   	pop    %ebx
  10331e:	5e                   	pop    %esi
  10331f:	5d                   	pop    %ebp
  103320:	c3                   	ret    
{
  if(proc == 0)
    panic("sleep");

  if(lk == 0)
    panic("sleep without lk");
  103321:	c7 04 24 24 6a 10 00 	movl   $0x106a24,(%esp)
  103328:	e8 f3 d5 ff ff       	call   100920 <panic>
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  if(proc == 0)
    panic("sleep");
  10332d:	c7 04 24 1e 6a 10 00 	movl   $0x106a1e,(%esp)
  103334:	e8 e7 d5 ff ff       	call   100920 <panic>
  103339:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00103340 <yield>:
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  103340:	55                   	push   %ebp
  103341:	89 e5                	mov    %esp,%ebp
  103343:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
  103346:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  10334d:	e8 fe 07 00 00       	call   103b50 <acquire>
  proc->state = RUNNABLE;
  103352:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103358:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
  10335f:	e8 6c fe ff ff       	call   1031d0 <sched>
  release(&ptable.lock);
  103364:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  10336b:	e8 90 07 00 00       	call   103b00 <release>
}
  103370:	c9                   	leave  
  103371:	c3                   	ret    
  103372:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  103379:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103380 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
  103380:	55                   	push   %ebp
  103381:	89 e5                	mov    %esp,%ebp
  103383:	53                   	push   %ebx
  103384:	83 ec 14             	sub    $0x14,%esp
  103387:	90                   	nop
}

static inline void
sti(void)
{
  asm volatile("sti");
  103388:	fb                   	sti    
//  - choose a process to run
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
  103389:	bb 54 c1 10 00       	mov    $0x10c154,%ebx
  for(;;){
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
  10338e:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  103395:	e8 b6 07 00 00       	call   103b50 <acquire>
  10339a:	eb 0f                	jmp    1033ab <scheduler+0x2b>
  10339c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  1033a0:	83 c3 7c             	add    $0x7c,%ebx
  1033a3:	81 fb 54 e0 10 00    	cmp    $0x10e054,%ebx
  1033a9:	74 5d                	je     103408 <scheduler+0x88>
      if(p->state != RUNNABLE)
  1033ab:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
  1033af:	90                   	nop
  1033b0:	75 ee                	jne    1033a0 <scheduler+0x20>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
  1033b2:	65 89 1d 04 00 00 00 	mov    %ebx,%gs:0x4
      switchuvm(p);
  1033b9:	89 1c 24             	mov    %ebx,(%esp)
  1033bc:	e8 4f 2f 00 00       	call   106310 <switchuvm>
      p->state = RUNNING;
      swtch(&cpu->scheduler, proc->context);
  1033c1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
      switchuvm(p);
      p->state = RUNNING;
  1033c7:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  1033ce:	83 c3 7c             	add    $0x7c,%ebx
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
      switchuvm(p);
      p->state = RUNNING;
      swtch(&cpu->scheduler, proc->context);
  1033d1:	8b 40 1c             	mov    0x1c(%eax),%eax
  1033d4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1033d8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  1033de:	83 c0 04             	add    $0x4,%eax
  1033e1:	89 04 24             	mov    %eax,(%esp)
  1033e4:	e8 03 0a 00 00       	call   103dec <swtch>
      switchkvm();
  1033e9:	e8 b2 28 00 00       	call   105ca0 <switchkvm>
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  1033ee:	81 fb 54 e0 10 00    	cmp    $0x10e054,%ebx
      swtch(&cpu->scheduler, proc->context);
      switchkvm();

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
  1033f4:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
  1033fb:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  1033ff:	75 aa                	jne    1033ab <scheduler+0x2b>
  103401:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
  103408:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  10340f:	e8 ec 06 00 00       	call   103b00 <release>

  }
  103414:	e9 6f ff ff ff       	jmp    103388 <scheduler+0x8>
  103419:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00103420 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
  103420:	55                   	push   %ebp
  103421:	89 e5                	mov    %esp,%ebp
  103423:	53                   	push   %ebx
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
  103424:	bb 54 c1 10 00       	mov    $0x10c154,%ebx

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
  103429:	83 ec 24             	sub    $0x24,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
  10342c:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  103433:	e8 18 07 00 00       	call   103b50 <acquire>
  103438:	31 c0                	xor    %eax,%eax
  10343a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  103440:	81 fb 54 e0 10 00    	cmp    $0x10e054,%ebx
  103446:	72 30                	jb     103478 <wait+0x58>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
  103448:	85 c0                	test   %eax,%eax
  10344a:	74 5c                	je     1034a8 <wait+0x88>
  10344c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103452:	8b 50 24             	mov    0x24(%eax),%edx
  103455:	85 d2                	test   %edx,%edx
  103457:	75 4f                	jne    1034a8 <wait+0x88>
      release(&ptable.lock);
      return -1;
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
  103459:	bb 54 c1 10 00       	mov    $0x10c154,%ebx
  10345e:	89 04 24             	mov    %eax,(%esp)
  103461:	c7 44 24 04 20 c1 10 	movl   $0x10c120,0x4(%esp)
  103468:	00 
  103469:	e8 02 fe ff ff       	call   103270 <sleep>
  10346e:	31 c0                	xor    %eax,%eax

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  103470:	81 fb 54 e0 10 00    	cmp    $0x10e054,%ebx
  103476:	73 d0                	jae    103448 <wait+0x28>
      if(p->parent != proc)
  103478:	8b 53 14             	mov    0x14(%ebx),%edx
  10347b:	65 3b 15 04 00 00 00 	cmp    %gs:0x4,%edx
  103482:	74 0c                	je     103490 <wait+0x70>

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  103484:	83 c3 7c             	add    $0x7c,%ebx
  103487:	eb b7                	jmp    103440 <wait+0x20>
  103489:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
      if(p->parent != proc)
        continue;
      havekids = 1;
      if(p->state == ZOMBIE){
  103490:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
  103494:	74 29                	je     1034bf <wait+0x9f>
        p->pid = 0;
        p->parent = 0;
        p->name[0] = 0;
        p->killed = 0;
        release(&ptable.lock);
        return pid;
  103496:	b8 01 00 00 00       	mov    $0x1,%eax
  10349b:	90                   	nop
  10349c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1034a0:	eb e2                	jmp    103484 <wait+0x64>
  1034a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
      release(&ptable.lock);
  1034a8:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  1034af:	e8 4c 06 00 00       	call   103b00 <release>
  1034b4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
  }
}
  1034b9:	83 c4 24             	add    $0x24,%esp
  1034bc:	5b                   	pop    %ebx
  1034bd:	5d                   	pop    %ebp
  1034be:	c3                   	ret    
      if(p->parent != proc)
        continue;
      havekids = 1;
      if(p->state == ZOMBIE){
        // Found one.
        pid = p->pid;
  1034bf:	8b 43 10             	mov    0x10(%ebx),%eax
        kfree(p->kstack);
  1034c2:	8b 53 08             	mov    0x8(%ebx),%edx
  1034c5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1034c8:	89 14 24             	mov    %edx,(%esp)
  1034cb:	e8 c0 ed ff ff       	call   102290 <kfree>
        p->kstack = 0;
        freevm(p->pgdir);
  1034d0:	8b 53 04             	mov    0x4(%ebx),%edx
      havekids = 1;
      if(p->state == ZOMBIE){
        // Found one.
        pid = p->pid;
        kfree(p->kstack);
        p->kstack = 0;
  1034d3:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
  1034da:	89 14 24             	mov    %edx,(%esp)
  1034dd:	e8 5e 2b 00 00       	call   106040 <freevm>
        p->state = UNUSED;
  1034e2:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        p->pid = 0;
  1034e9:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
  1034f0:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
  1034f7:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
  1034fb:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        release(&ptable.lock);
  103502:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  103509:	e8 f2 05 00 00       	call   103b00 <release>
        return pid;
  10350e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103511:	eb a6                	jmp    1034b9 <wait+0x99>
  103513:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  103519:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103520 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
  103520:	55                   	push   %ebp
  103521:	89 e5                	mov    %esp,%ebp
  103523:	56                   	push   %esi
  103524:	53                   	push   %ebx
  struct proc *p;
  int fd;

  if(proc == initproc)
    panic("init exiting");
  103525:	31 db                	xor    %ebx,%ebx
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
  103527:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
  10352a:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  103531:	3b 15 c8 78 10 00    	cmp    0x1078c8,%edx
  103537:	0f 84 fd 00 00 00    	je     10363a <exit+0x11a>
  10353d:	8d 76 00             	lea    0x0(%esi),%esi
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd]){
  103540:	8d 73 08             	lea    0x8(%ebx),%esi
  103543:	8b 44 b2 08          	mov    0x8(%edx,%esi,4),%eax
  103547:	85 c0                	test   %eax,%eax
  103549:	74 1d                	je     103568 <exit+0x48>
      fileclose(proc->ofile[fd]);
  10354b:	89 04 24             	mov    %eax,(%esp)
  10354e:	e8 2d da ff ff       	call   100f80 <fileclose>
      proc->ofile[fd] = 0;
  103553:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103559:	c7 44 b0 08 00 00 00 	movl   $0x0,0x8(%eax,%esi,4)
  103560:	00 
  103561:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
  103568:	83 c3 01             	add    $0x1,%ebx
  10356b:	83 fb 10             	cmp    $0x10,%ebx
  10356e:	75 d0                	jne    103540 <exit+0x20>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
  103570:	8b 42 68             	mov    0x68(%edx),%eax
  103573:	89 04 24             	mov    %eax,(%esp)
  103576:	e8 05 e3 ff ff       	call   101880 <iput>
  proc->cwd = 0;
  10357b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103581:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
  103588:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  10358f:	e8 bc 05 00 00       	call   103b50 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
  103594:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
  10359b:	b8 54 c1 10 00       	mov    $0x10c154,%eax
  proc->cwd = 0;

  acquire(&ptable.lock);

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
  1035a0:	8b 51 14             	mov    0x14(%ecx),%edx
  1035a3:	eb 0d                	jmp    1035b2 <exit+0x92>
  1035a5:	8d 76 00             	lea    0x0(%esi),%esi
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  1035a8:	83 c0 7c             	add    $0x7c,%eax
  1035ab:	3d 54 e0 10 00       	cmp    $0x10e054,%eax
  1035b0:	74 1c                	je     1035ce <exit+0xae>
    if(p->state == SLEEPING && p->chan == chan)
  1035b2:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
  1035b6:	75 f0                	jne    1035a8 <exit+0x88>
  1035b8:	3b 50 20             	cmp    0x20(%eax),%edx
  1035bb:	75 eb                	jne    1035a8 <exit+0x88>
      p->state = RUNNABLE;
  1035bd:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  1035c4:	83 c0 7c             	add    $0x7c,%eax
  1035c7:	3d 54 e0 10 00       	cmp    $0x10e054,%eax
  1035cc:	75 e4                	jne    1035b2 <exit+0x92>
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->parent == proc){
      p->parent = initproc;
  1035ce:	8b 1d c8 78 10 00    	mov    0x1078c8,%ebx
  1035d4:	ba 54 c1 10 00       	mov    $0x10c154,%edx
  1035d9:	eb 10                	jmp    1035eb <exit+0xcb>
  1035db:	90                   	nop
  1035dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  1035e0:	83 c2 7c             	add    $0x7c,%edx
  1035e3:	81 fa 54 e0 10 00    	cmp    $0x10e054,%edx
  1035e9:	74 37                	je     103622 <exit+0x102>
    if(p->parent == proc){
  1035eb:	3b 4a 14             	cmp    0x14(%edx),%ecx
  1035ee:	75 f0                	jne    1035e0 <exit+0xc0>
      p->parent = initproc;
      if(p->state == ZOMBIE)
  1035f0:	83 7a 0c 05          	cmpl   $0x5,0xc(%edx)
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->parent == proc){
      p->parent = initproc;
  1035f4:	89 5a 14             	mov    %ebx,0x14(%edx)
      if(p->state == ZOMBIE)
  1035f7:	75 e7                	jne    1035e0 <exit+0xc0>
  1035f9:	b8 54 c1 10 00       	mov    $0x10c154,%eax
  1035fe:	eb 0a                	jmp    10360a <exit+0xea>
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  103600:	83 c0 7c             	add    $0x7c,%eax
  103603:	3d 54 e0 10 00       	cmp    $0x10e054,%eax
  103608:	74 d6                	je     1035e0 <exit+0xc0>
    if(p->state == SLEEPING && p->chan == chan)
  10360a:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
  10360e:	75 f0                	jne    103600 <exit+0xe0>
  103610:	3b 58 20             	cmp    0x20(%eax),%ebx
  103613:	75 eb                	jne    103600 <exit+0xe0>
      p->state = RUNNABLE;
  103615:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  10361c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  103620:	eb de                	jmp    103600 <exit+0xe0>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
  103622:	c7 41 0c 05 00 00 00 	movl   $0x5,0xc(%ecx)
  sched();
  103629:	e8 a2 fb ff ff       	call   1031d0 <sched>
  panic("zombie exit");
  10362e:	c7 04 24 42 6a 10 00 	movl   $0x106a42,(%esp)
  103635:	e8 e6 d2 ff ff       	call   100920 <panic>
{
  struct proc *p;
  int fd;

  if(proc == initproc)
    panic("init exiting");
  10363a:	c7 04 24 35 6a 10 00 	movl   $0x106a35,(%esp)
  103641:	e8 da d2 ff ff       	call   100920 <panic>
  103646:	8d 76 00             	lea    0x0(%esi),%esi
  103649:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103650 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
  103650:	55                   	push   %ebp
  103651:	89 e5                	mov    %esp,%ebp
  103653:	53                   	push   %ebx
  103654:	83 ec 14             	sub    $0x14,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  103657:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  10365e:	e8 ed 04 00 00       	call   103b50 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
  103663:	8b 1d 60 c1 10 00    	mov    0x10c160,%ebx
  103669:	85 db                	test   %ebx,%ebx
  10366b:	0f 84 a5 00 00 00    	je     103716 <allocproc+0xc6>
// Look in the process table for an UNUSED proc.
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
  103671:	bb d0 c1 10 00       	mov    $0x10c1d0,%ebx
  103676:	eb 0b                	jmp    103683 <allocproc+0x33>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  103678:	83 c3 7c             	add    $0x7c,%ebx
  10367b:	81 fb 54 e0 10 00    	cmp    $0x10e054,%ebx
  103681:	74 7d                	je     103700 <allocproc+0xb0>
    if(p->state == UNUSED)
  103683:	8b 4b 0c             	mov    0xc(%ebx),%ecx
  103686:	85 c9                	test   %ecx,%ecx
  103688:	75 ee                	jne    103678 <allocproc+0x28>
      goto found;
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
  10368a:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
  103691:	a1 24 73 10 00       	mov    0x107324,%eax
  103696:	89 43 10             	mov    %eax,0x10(%ebx)
  103699:	83 c0 01             	add    $0x1,%eax
  10369c:	a3 24 73 10 00       	mov    %eax,0x107324
  release(&ptable.lock);
  1036a1:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  1036a8:	e8 53 04 00 00       	call   103b00 <release>

  // Allocate kernel stack if possible.
  if((p->kstack = kalloc()) == 0){
  1036ad:	e8 9e eb ff ff       	call   102250 <kalloc>
  1036b2:	85 c0                	test   %eax,%eax
  1036b4:	89 43 08             	mov    %eax,0x8(%ebx)
  1036b7:	74 67                	je     103720 <allocproc+0xd0>
    return 0;
  }
  sp = p->kstack + KSTACKSIZE;
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
  1036b9:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
  1036bf:	89 53 18             	mov    %edx,0x18(%ebx)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
  *(uint*)sp = (uint)trapret;
  1036c2:	c7 80 b0 0f 00 00 80 	movl   $0x104d80,0xfb0(%eax)
  1036c9:	4d 10 00 

  sp -= sizeof *p->context;
  p->context = (struct context*)sp;
  1036cc:	05 9c 0f 00 00       	add    $0xf9c,%eax
  1036d1:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
  1036d4:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
  1036db:	00 
  1036dc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1036e3:	00 
  1036e4:	89 04 24             	mov    %eax,(%esp)
  1036e7:	e8 04 05 00 00       	call   103bf0 <memset>
  p->context->eip = (uint)forkret;
  1036ec:	8b 43 1c             	mov    0x1c(%ebx),%eax
  1036ef:	c7 40 10 b0 31 10 00 	movl   $0x1031b0,0x10(%eax)

  return p;
}
  1036f6:	89 d8                	mov    %ebx,%eax
  1036f8:	83 c4 14             	add    $0x14,%esp
  1036fb:	5b                   	pop    %ebx
  1036fc:	5d                   	pop    %ebp
  1036fd:	c3                   	ret    
  1036fe:	66 90                	xchg   %ax,%ax

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
  103700:	31 db                	xor    %ebx,%ebx
  103702:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  103709:	e8 f2 03 00 00       	call   103b00 <release>
  p->context = (struct context*)sp;
  memset(p->context, 0, sizeof *p->context);
  p->context->eip = (uint)forkret;

  return p;
}
  10370e:	89 d8                	mov    %ebx,%eax
  103710:	83 c4 14             	add    $0x14,%esp
  103713:	5b                   	pop    %ebx
  103714:	5d                   	pop    %ebp
  103715:	c3                   	ret    
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
  return 0;
  103716:	bb 54 c1 10 00       	mov    $0x10c154,%ebx
  10371b:	e9 6a ff ff ff       	jmp    10368a <allocproc+0x3a>
  p->pid = nextpid++;
  release(&ptable.lock);

  // Allocate kernel stack if possible.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
  103720:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  103727:	31 db                	xor    %ebx,%ebx
    return 0;
  103729:	eb cb                	jmp    1036f6 <allocproc+0xa6>
  10372b:	90                   	nop
  10372c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00103730 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
  103730:	55                   	push   %ebp
  103731:	89 e5                	mov    %esp,%ebp
  103733:	57                   	push   %edi
  103734:	56                   	push   %esi
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
  103735:	be ff ff ff ff       	mov    $0xffffffff,%esi
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
  10373a:	53                   	push   %ebx
  10373b:	83 ec 1c             	sub    $0x1c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
  10373e:	e8 0d ff ff ff       	call   103650 <allocproc>
  103743:	85 c0                	test   %eax,%eax
  103745:	89 c3                	mov    %eax,%ebx
  103747:	0f 84 be 00 00 00    	je     10380b <fork+0xdb>
    return -1;

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
  10374d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103753:	8b 10                	mov    (%eax),%edx
  103755:	89 54 24 04          	mov    %edx,0x4(%esp)
  103759:	8b 40 04             	mov    0x4(%eax),%eax
  10375c:	89 04 24             	mov    %eax,(%esp)
  10375f:	e8 5c 29 00 00       	call   1060c0 <copyuvm>
  103764:	85 c0                	test   %eax,%eax
  103766:	89 43 04             	mov    %eax,0x4(%ebx)
  103769:	0f 84 a6 00 00 00    	je     103815 <fork+0xe5>
    kfree(np->kstack);
    np->kstack = 0;
    np->state = UNUSED;
    return -1;
  }
  np->sz = proc->sz;
  10376f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  np->parent = proc;
  *np->tf = *proc->tf;
  103775:	b9 13 00 00 00       	mov    $0x13,%ecx
    kfree(np->kstack);
    np->kstack = 0;
    np->state = UNUSED;
    return -1;
  }
  np->sz = proc->sz;
  10377a:	8b 00                	mov    (%eax),%eax
  10377c:	89 03                	mov    %eax,(%ebx)
  np->parent = proc;
  10377e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103784:	89 43 14             	mov    %eax,0x14(%ebx)
  *np->tf = *proc->tf;
  103787:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  10378e:	8b 43 18             	mov    0x18(%ebx),%eax
  103791:	8b 72 18             	mov    0x18(%edx),%esi
  103794:	89 c7                	mov    %eax,%edi
  103796:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
  103798:	31 f6                	xor    %esi,%esi
  10379a:	8b 43 18             	mov    0x18(%ebx),%eax
  10379d:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  1037a4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  1037ab:	90                   	nop
  1037ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

  for(i = 0; i < NOFILE; i++)
    if(proc->ofile[i])
  1037b0:	8b 44 b2 28          	mov    0x28(%edx,%esi,4),%eax
  1037b4:	85 c0                	test   %eax,%eax
  1037b6:	74 13                	je     1037cb <fork+0x9b>
      np->ofile[i] = filedup(proc->ofile[i]);
  1037b8:	89 04 24             	mov    %eax,(%esp)
  1037bb:	e8 f0 d6 ff ff       	call   100eb0 <filedup>
  1037c0:	89 44 b3 28          	mov    %eax,0x28(%ebx,%esi,4)
  1037c4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
  1037cb:	83 c6 01             	add    $0x1,%esi
  1037ce:	83 fe 10             	cmp    $0x10,%esi
  1037d1:	75 dd                	jne    1037b0 <fork+0x80>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
  1037d3:	8b 42 68             	mov    0x68(%edx),%eax
  1037d6:	89 04 24             	mov    %eax,(%esp)
  1037d9:	e8 d2 d8 ff ff       	call   1010b0 <idup>
 
  pid = np->pid;
  1037de:	8b 73 10             	mov    0x10(%ebx),%esi
  np->state = RUNNABLE;
  1037e1:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
  1037e8:	89 43 68             	mov    %eax,0x68(%ebx)
 
  pid = np->pid;
  np->state = RUNNABLE;
  safestrcpy(np->name, proc->name, sizeof(proc->name));
  1037eb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1037f1:	83 c3 6c             	add    $0x6c,%ebx
  1037f4:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
  1037fb:	00 
  1037fc:	89 1c 24             	mov    %ebx,(%esp)
  1037ff:	83 c0 6c             	add    $0x6c,%eax
  103802:	89 44 24 04          	mov    %eax,0x4(%esp)
  103806:	e8 85 05 00 00       	call   103d90 <safestrcpy>
  return pid;
}
  10380b:	83 c4 1c             	add    $0x1c,%esp
  10380e:	89 f0                	mov    %esi,%eax
  103810:	5b                   	pop    %ebx
  103811:	5e                   	pop    %esi
  103812:	5f                   	pop    %edi
  103813:	5d                   	pop    %ebp
  103814:	c3                   	ret    
  if((np = allocproc()) == 0)
    return -1;

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
    kfree(np->kstack);
  103815:	8b 43 08             	mov    0x8(%ebx),%eax
  103818:	89 04 24             	mov    %eax,(%esp)
  10381b:	e8 70 ea ff ff       	call   102290 <kfree>
    np->kstack = 0;
  103820:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
  103827:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
  10382e:	eb db                	jmp    10380b <fork+0xdb>

00103830 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  103830:	55                   	push   %ebp
  103831:	89 e5                	mov    %esp,%ebp
  103833:	83 ec 18             	sub    $0x18,%esp
  uint sz;
  
  sz = proc->sz;
  103836:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  10383d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  uint sz;
  
  sz = proc->sz;
  103840:	8b 02                	mov    (%edx),%eax
  if(n > 0){
  103842:	83 f9 00             	cmp    $0x0,%ecx
  103845:	7f 19                	jg     103860 <growproc+0x30>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
      return -1;
  } else if(n < 0){
  103847:	75 39                	jne    103882 <growproc+0x52>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
      return -1;
  }
  proc->sz = sz;
  103849:	89 02                	mov    %eax,(%edx)
  switchuvm(proc);
  10384b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103851:	89 04 24             	mov    %eax,(%esp)
  103854:	e8 b7 2a 00 00       	call   106310 <switchuvm>
  103859:	31 c0                	xor    %eax,%eax
  return 0;
}
  10385b:	c9                   	leave  
  10385c:	c3                   	ret    
  10385d:	8d 76 00             	lea    0x0(%esi),%esi
{
  uint sz;
  
  sz = proc->sz;
  if(n > 0){
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
  103860:	01 c1                	add    %eax,%ecx
  103862:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  103866:	89 44 24 04          	mov    %eax,0x4(%esp)
  10386a:	8b 42 04             	mov    0x4(%edx),%eax
  10386d:	89 04 24             	mov    %eax,(%esp)
  103870:	e8 0b 29 00 00       	call   106180 <allocuvm>
  103875:	85 c0                	test   %eax,%eax
  103877:	74 27                	je     1038a0 <growproc+0x70>
      return -1;
  } else if(n < 0){
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
  103879:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  103880:	eb c7                	jmp    103849 <growproc+0x19>
  103882:	01 c1                	add    %eax,%ecx
  103884:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  103888:	89 44 24 04          	mov    %eax,0x4(%esp)
  10388c:	8b 42 04             	mov    0x4(%edx),%eax
  10388f:	89 04 24             	mov    %eax,(%esp)
  103892:	e8 19 27 00 00       	call   105fb0 <deallocuvm>
  103897:	85 c0                	test   %eax,%eax
  103899:	75 de                	jne    103879 <growproc+0x49>
  10389b:	90                   	nop
  10389c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
      return -1;
  }
  proc->sz = sz;
  switchuvm(proc);
  return 0;
  1038a0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  1038a5:	c9                   	leave  
  1038a6:	c3                   	ret    
  1038a7:	89 f6                	mov    %esi,%esi
  1038a9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

001038b0 <userinit>:
}

// Set up first user process.
void
userinit(void)
{
  1038b0:	55                   	push   %ebp
  1038b1:	89 e5                	mov    %esp,%ebp
  1038b3:	53                   	push   %ebx
  1038b4:	83 ec 14             	sub    $0x14,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
  1038b7:	e8 94 fd ff ff       	call   103650 <allocproc>
  1038bc:	89 c3                	mov    %eax,%ebx
  initproc = p;
  1038be:	a3 c8 78 10 00       	mov    %eax,0x1078c8
  if((p->pgdir = setupkvm()) == 0)
  1038c3:	e8 b8 25 00 00       	call   105e80 <setupkvm>
  1038c8:	85 c0                	test   %eax,%eax
  1038ca:	89 43 04             	mov    %eax,0x4(%ebx)
  1038cd:	0f 84 b6 00 00 00    	je     103989 <userinit+0xd9>
    panic("userinit: out of memory?");
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
  1038d3:	89 04 24             	mov    %eax,(%esp)
  1038d6:	c7 44 24 08 2c 00 00 	movl   $0x2c,0x8(%esp)
  1038dd:	00 
  1038de:	c7 44 24 04 70 77 10 	movl   $0x107770,0x4(%esp)
  1038e5:	00 
  1038e6:	e8 35 26 00 00       	call   105f20 <inituvm>
  p->sz = PGSIZE;
  1038eb:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
  1038f1:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  1038f8:	00 
  1038f9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103900:	00 
  103901:	8b 43 18             	mov    0x18(%ebx),%eax
  103904:	89 04 24             	mov    %eax,(%esp)
  103907:	e8 e4 02 00 00       	call   103bf0 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
  10390c:	8b 43 18             	mov    0x18(%ebx),%eax
  10390f:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
  103915:	8b 43 18             	mov    0x18(%ebx),%eax
  103918:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
  10391e:	8b 43 18             	mov    0x18(%ebx),%eax
  103921:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
  103925:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
  103929:	8b 43 18             	mov    0x18(%ebx),%eax
  10392c:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
  103930:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
  103934:	8b 43 18             	mov    0x18(%ebx),%eax
  103937:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
  10393e:	8b 43 18             	mov    0x18(%ebx),%eax
  103941:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
  103948:	8b 43 18             	mov    0x18(%ebx),%eax
  10394b:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
  103952:	8d 43 6c             	lea    0x6c(%ebx),%eax
  103955:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
  10395c:	00 
  10395d:	c7 44 24 04 67 6a 10 	movl   $0x106a67,0x4(%esp)
  103964:	00 
  103965:	89 04 24             	mov    %eax,(%esp)
  103968:	e8 23 04 00 00       	call   103d90 <safestrcpy>
  p->cwd = namei("/");
  10396d:	c7 04 24 70 6a 10 00 	movl   $0x106a70,(%esp)
  103974:	e8 d7 e4 ff ff       	call   101e50 <namei>

  p->state = RUNNABLE;
  103979:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  p->tf->eflags = FL_IF;
  p->tf->esp = PGSIZE;
  p->tf->eip = 0;  // beginning of initcode.S

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");
  103980:	89 43 68             	mov    %eax,0x68(%ebx)

  p->state = RUNNABLE;
}
  103983:	83 c4 14             	add    $0x14,%esp
  103986:	5b                   	pop    %ebx
  103987:	5d                   	pop    %ebp
  103988:	c3                   	ret    
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
  initproc = p;
  if((p->pgdir = setupkvm()) == 0)
    panic("userinit: out of memory?");
  103989:	c7 04 24 4e 6a 10 00 	movl   $0x106a4e,(%esp)
  103990:	e8 8b cf ff ff       	call   100920 <panic>
  103995:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  103999:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

001039a0 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
  1039a0:	55                   	push   %ebp
  1039a1:	89 e5                	mov    %esp,%ebp
  1039a3:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
  1039a6:	c7 44 24 04 72 6a 10 	movl   $0x106a72,0x4(%esp)
  1039ad:	00 
  1039ae:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  1039b5:	e8 06 00 00 00       	call   1039c0 <initlock>
}
  1039ba:	c9                   	leave  
  1039bb:	c3                   	ret    
  1039bc:	90                   	nop
  1039bd:	90                   	nop
  1039be:	90                   	nop
  1039bf:	90                   	nop

001039c0 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
  1039c0:	55                   	push   %ebp
  1039c1:	89 e5                	mov    %esp,%ebp
  1039c3:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
  1039c6:	8b 55 0c             	mov    0xc(%ebp),%edx
  lk->locked = 0;
  1039c9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
  lk->name = name;
  1039cf:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
  lk->cpu = 0;
  1039d2:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
  1039d9:	5d                   	pop    %ebp
  1039da:	c3                   	ret    
  1039db:	90                   	nop
  1039dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

001039e0 <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
  1039e0:	55                   	push   %ebp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  1039e1:	31 c0                	xor    %eax,%eax
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
  1039e3:	89 e5                	mov    %esp,%ebp
  1039e5:	53                   	push   %ebx
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  1039e6:	8b 55 08             	mov    0x8(%ebp),%edx
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
  1039e9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  1039ec:	83 ea 08             	sub    $0x8,%edx
  1039ef:	90                   	nop
  for(i = 0; i < 10; i++){
    if(ebp == 0 || ebp < (uint*)0x100000 || ebp == (uint*)0xffffffff)
  1039f0:	8d 8a 00 00 f0 ff    	lea    -0x100000(%edx),%ecx
  1039f6:	81 f9 fe ff ef ff    	cmp    $0xffeffffe,%ecx
  1039fc:	77 1a                	ja     103a18 <getcallerpcs+0x38>
      break;
    pcs[i] = ebp[1];     // saved %eip
  1039fe:	8b 4a 04             	mov    0x4(%edx),%ecx
  103a01:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
  103a04:	83 c0 01             	add    $0x1,%eax
    if(ebp == 0 || ebp < (uint*)0x100000 || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  103a07:	8b 12                	mov    (%edx),%edx
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
  103a09:	83 f8 0a             	cmp    $0xa,%eax
  103a0c:	75 e2                	jne    1039f0 <getcallerpcs+0x10>
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
    pcs[i] = 0;
}
  103a0e:	5b                   	pop    %ebx
  103a0f:	5d                   	pop    %ebp
  103a10:	c3                   	ret    
  103a11:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
    if(ebp == 0 || ebp < (uint*)0x100000 || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
  103a18:	83 f8 09             	cmp    $0x9,%eax
  103a1b:	7f f1                	jg     103a0e <getcallerpcs+0x2e>
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
    if(ebp == 0 || ebp < (uint*)0x100000 || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  103a1d:	8d 14 83             	lea    (%ebx,%eax,4),%edx
  }
  for(; i < 10; i++)
  103a20:	83 c0 01             	add    $0x1,%eax
    pcs[i] = 0;
  103a23:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
    if(ebp == 0 || ebp < (uint*)0x100000 || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
  103a29:	83 c2 04             	add    $0x4,%edx
  103a2c:	83 f8 0a             	cmp    $0xa,%eax
  103a2f:	75 ef                	jne    103a20 <getcallerpcs+0x40>
    pcs[i] = 0;
}
  103a31:	5b                   	pop    %ebx
  103a32:	5d                   	pop    %ebp
  103a33:	c3                   	ret    
  103a34:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  103a3a:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

00103a40 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
  103a40:	55                   	push   %ebp
  return lock->locked && lock->cpu == cpu;
  103a41:	31 c0                	xor    %eax,%eax
}

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
  103a43:	89 e5                	mov    %esp,%ebp
  103a45:	8b 55 08             	mov    0x8(%ebp),%edx
  return lock->locked && lock->cpu == cpu;
  103a48:	8b 0a                	mov    (%edx),%ecx
  103a4a:	85 c9                	test   %ecx,%ecx
  103a4c:	74 10                	je     103a5e <holding+0x1e>
  103a4e:	8b 42 08             	mov    0x8(%edx),%eax
  103a51:	65 3b 05 00 00 00 00 	cmp    %gs:0x0,%eax
  103a58:	0f 94 c0             	sete   %al
  103a5b:	0f b6 c0             	movzbl %al,%eax
}
  103a5e:	5d                   	pop    %ebp
  103a5f:	c3                   	ret    

00103a60 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
  103a60:	55                   	push   %ebp
  103a61:	89 e5                	mov    %esp,%ebp
  103a63:	53                   	push   %ebx

static inline uint
readeflags(void)
{
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
  103a64:	9c                   	pushf  
  103a65:	5b                   	pop    %ebx
}

static inline void
cli(void)
{
  asm volatile("cli");
  103a66:	fa                   	cli    
  int eflags;
  
  eflags = readeflags();
  cli();
  if(cpu->ncli++ == 0)
  103a67:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
  103a6e:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
  103a74:	8d 48 01             	lea    0x1(%eax),%ecx
  103a77:	85 c0                	test   %eax,%eax
  103a79:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
  103a7f:	75 12                	jne    103a93 <pushcli+0x33>
    cpu->intena = eflags & FL_IF;
  103a81:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  103a87:	81 e3 00 02 00 00    	and    $0x200,%ebx
  103a8d:	89 98 b0 00 00 00    	mov    %ebx,0xb0(%eax)
}
  103a93:	5b                   	pop    %ebx
  103a94:	5d                   	pop    %ebp
  103a95:	c3                   	ret    
  103a96:	8d 76 00             	lea    0x0(%esi),%esi
  103a99:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103aa0 <popcli>:

void
popcli(void)
{
  103aa0:	55                   	push   %ebp
  103aa1:	89 e5                	mov    %esp,%ebp
  103aa3:	83 ec 18             	sub    $0x18,%esp

static inline uint
readeflags(void)
{
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
  103aa6:	9c                   	pushf  
  103aa7:	58                   	pop    %eax
  if(readeflags()&FL_IF)
  103aa8:	f6 c4 02             	test   $0x2,%ah
  103aab:	75 43                	jne    103af0 <popcli+0x50>
    panic("popcli - interruptible");
  if(--cpu->ncli < 0)
  103aad:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
  103ab4:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
  103aba:	83 e8 01             	sub    $0x1,%eax
  103abd:	85 c0                	test   %eax,%eax
  103abf:	89 82 ac 00 00 00    	mov    %eax,0xac(%edx)
  103ac5:	78 1d                	js     103ae4 <popcli+0x44>
    panic("popcli");
  if(cpu->ncli == 0 && cpu->intena)
  103ac7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  103acd:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
  103ad3:	85 d2                	test   %edx,%edx
  103ad5:	75 0b                	jne    103ae2 <popcli+0x42>
  103ad7:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
  103add:	85 c0                	test   %eax,%eax
  103adf:	74 01                	je     103ae2 <popcli+0x42>
}

static inline void
sti(void)
{
  asm volatile("sti");
  103ae1:	fb                   	sti    
    sti();
}
  103ae2:	c9                   	leave  
  103ae3:	c3                   	ret    
popcli(void)
{
  if(readeflags()&FL_IF)
    panic("popcli - interruptible");
  if(--cpu->ncli < 0)
    panic("popcli");
  103ae4:	c7 04 24 d3 6a 10 00 	movl   $0x106ad3,(%esp)
  103aeb:	e8 30 ce ff ff       	call   100920 <panic>

void
popcli(void)
{
  if(readeflags()&FL_IF)
    panic("popcli - interruptible");
  103af0:	c7 04 24 bc 6a 10 00 	movl   $0x106abc,(%esp)
  103af7:	e8 24 ce ff ff       	call   100920 <panic>
  103afc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00103b00 <release>:
}

// Release the lock.
void
release(struct spinlock *lk)
{
  103b00:	55                   	push   %ebp
  103b01:	89 e5                	mov    %esp,%ebp
  103b03:	83 ec 18             	sub    $0x18,%esp
  103b06:	8b 55 08             	mov    0x8(%ebp),%edx

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
  return lock->locked && lock->cpu == cpu;
  103b09:	8b 0a                	mov    (%edx),%ecx
  103b0b:	85 c9                	test   %ecx,%ecx
  103b0d:	74 0c                	je     103b1b <release+0x1b>
  103b0f:	8b 42 08             	mov    0x8(%edx),%eax
  103b12:	65 3b 05 00 00 00 00 	cmp    %gs:0x0,%eax
  103b19:	74 0d                	je     103b28 <release+0x28>
// Release the lock.
void
release(struct spinlock *lk)
{
  if(!holding(lk))
    panic("release");
  103b1b:	c7 04 24 da 6a 10 00 	movl   $0x106ada,(%esp)
  103b22:	e8 f9 cd ff ff       	call   100920 <panic>
  103b27:	90                   	nop

  lk->pcs[0] = 0;
  103b28:	c7 42 0c 00 00 00 00 	movl   $0x0,0xc(%edx)
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
  103b2f:	31 c0                	xor    %eax,%eax
  lk->cpu = 0;
  103b31:	c7 42 08 00 00 00 00 	movl   $0x0,0x8(%edx)
  103b38:	f0 87 02             	lock xchg %eax,(%edx)
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);

  popcli();
}
  103b3b:	c9                   	leave  
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);

  popcli();
  103b3c:	e9 5f ff ff ff       	jmp    103aa0 <popcli>
  103b41:	eb 0d                	jmp    103b50 <acquire>
  103b43:	90                   	nop
  103b44:	90                   	nop
  103b45:	90                   	nop
  103b46:	90                   	nop
  103b47:	90                   	nop
  103b48:	90                   	nop
  103b49:	90                   	nop
  103b4a:	90                   	nop
  103b4b:	90                   	nop
  103b4c:	90                   	nop
  103b4d:	90                   	nop
  103b4e:	90                   	nop
  103b4f:	90                   	nop

00103b50 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
  103b50:	55                   	push   %ebp
  103b51:	89 e5                	mov    %esp,%ebp
  103b53:	53                   	push   %ebx
  103b54:	83 ec 14             	sub    $0x14,%esp

static inline uint
readeflags(void)
{
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
  103b57:	9c                   	pushf  
  103b58:	5b                   	pop    %ebx
}

static inline void
cli(void)
{
  asm volatile("cli");
  103b59:	fa                   	cli    
{
  int eflags;
  
  eflags = readeflags();
  cli();
  if(cpu->ncli++ == 0)
  103b5a:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
  103b61:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
  103b67:	8d 48 01             	lea    0x1(%eax),%ecx
  103b6a:	85 c0                	test   %eax,%eax
  103b6c:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
  103b72:	75 12                	jne    103b86 <acquire+0x36>
    cpu->intena = eflags & FL_IF;
  103b74:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  103b7a:	81 e3 00 02 00 00    	and    $0x200,%ebx
  103b80:	89 98 b0 00 00 00    	mov    %ebx,0xb0(%eax)
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
  pushcli(); // disable interrupts to avoid deadlock.
  if(holding(lk))
  103b86:	8b 55 08             	mov    0x8(%ebp),%edx

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
  return lock->locked && lock->cpu == cpu;
  103b89:	8b 1a                	mov    (%edx),%ebx
  103b8b:	85 db                	test   %ebx,%ebx
  103b8d:	74 0c                	je     103b9b <acquire+0x4b>
  103b8f:	8b 42 08             	mov    0x8(%edx),%eax
  103b92:	65 3b 05 00 00 00 00 	cmp    %gs:0x0,%eax
  103b99:	74 45                	je     103be0 <acquire+0x90>
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
  103b9b:	b9 01 00 00 00       	mov    $0x1,%ecx
  103ba0:	eb 09                	jmp    103bab <acquire+0x5b>
  103ba2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    panic("acquire");

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
  103ba8:	8b 55 08             	mov    0x8(%ebp),%edx
  103bab:	89 c8                	mov    %ecx,%eax
  103bad:	f0 87 02             	lock xchg %eax,(%edx)
  103bb0:	85 c0                	test   %eax,%eax
  103bb2:	75 f4                	jne    103ba8 <acquire+0x58>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
  103bb4:	8b 45 08             	mov    0x8(%ebp),%eax
  103bb7:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
  103bbe:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
  103bc1:	8b 45 08             	mov    0x8(%ebp),%eax
  103bc4:	83 c0 0c             	add    $0xc,%eax
  103bc7:	89 44 24 04          	mov    %eax,0x4(%esp)
  103bcb:	8d 45 08             	lea    0x8(%ebp),%eax
  103bce:	89 04 24             	mov    %eax,(%esp)
  103bd1:	e8 0a fe ff ff       	call   1039e0 <getcallerpcs>
}
  103bd6:	83 c4 14             	add    $0x14,%esp
  103bd9:	5b                   	pop    %ebx
  103bda:	5d                   	pop    %ebp
  103bdb:	c3                   	ret    
  103bdc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
void
acquire(struct spinlock *lk)
{
  pushcli(); // disable interrupts to avoid deadlock.
  if(holding(lk))
    panic("acquire");
  103be0:	c7 04 24 e2 6a 10 00 	movl   $0x106ae2,(%esp)
  103be7:	e8 34 cd ff ff       	call   100920 <panic>
  103bec:	90                   	nop
  103bed:	90                   	nop
  103bee:	90                   	nop
  103bef:	90                   	nop

00103bf0 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
  103bf0:	55                   	push   %ebp
  103bf1:	89 e5                	mov    %esp,%ebp
  103bf3:	8b 55 08             	mov    0x8(%ebp),%edx
  103bf6:	57                   	push   %edi
}

static inline void
stosb(void *addr, int data, int cnt)
{
  asm volatile("cld; rep stosb" :
  103bf7:	8b 4d 10             	mov    0x10(%ebp),%ecx
  103bfa:	8b 45 0c             	mov    0xc(%ebp),%eax
  103bfd:	89 d7                	mov    %edx,%edi
  103bff:	fc                   	cld    
  103c00:	f3 aa                	rep stos %al,%es:(%edi)
  stosb(dst, c, n);
  return dst;
}
  103c02:	89 d0                	mov    %edx,%eax
  103c04:	5f                   	pop    %edi
  103c05:	5d                   	pop    %ebp
  103c06:	c3                   	ret    
  103c07:	89 f6                	mov    %esi,%esi
  103c09:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103c10 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
  103c10:	55                   	push   %ebp
  103c11:	89 e5                	mov    %esp,%ebp
  103c13:	57                   	push   %edi
  103c14:	56                   	push   %esi
  103c15:	53                   	push   %ebx
  103c16:	8b 55 10             	mov    0x10(%ebp),%edx
  103c19:	8b 75 08             	mov    0x8(%ebp),%esi
  103c1c:	8b 7d 0c             	mov    0xc(%ebp),%edi
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
  103c1f:	85 d2                	test   %edx,%edx
  103c21:	74 2d                	je     103c50 <memcmp+0x40>
    if(*s1 != *s2)
  103c23:	0f b6 1e             	movzbl (%esi),%ebx
  103c26:	0f b6 0f             	movzbl (%edi),%ecx
  103c29:	38 cb                	cmp    %cl,%bl
  103c2b:	75 2b                	jne    103c58 <memcmp+0x48>
      return *s1 - *s2;
  103c2d:	83 ea 01             	sub    $0x1,%edx
  103c30:	31 c0                	xor    %eax,%eax
  103c32:	eb 18                	jmp    103c4c <memcmp+0x3c>
  103c34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    if(*s1 != *s2)
  103c38:	0f b6 5c 06 01       	movzbl 0x1(%esi,%eax,1),%ebx
  103c3d:	83 ea 01             	sub    $0x1,%edx
  103c40:	0f b6 4c 07 01       	movzbl 0x1(%edi,%eax,1),%ecx
  103c45:	83 c0 01             	add    $0x1,%eax
  103c48:	38 cb                	cmp    %cl,%bl
  103c4a:	75 0c                	jne    103c58 <memcmp+0x48>
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
  103c4c:	85 d2                	test   %edx,%edx
  103c4e:	75 e8                	jne    103c38 <memcmp+0x28>
  103c50:	31 c0                	xor    %eax,%eax
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
}
  103c52:	5b                   	pop    %ebx
  103c53:	5e                   	pop    %esi
  103c54:	5f                   	pop    %edi
  103c55:	5d                   	pop    %ebp
  103c56:	c3                   	ret    
  103c57:	90                   	nop
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    if(*s1 != *s2)
      return *s1 - *s2;
  103c58:	0f b6 c3             	movzbl %bl,%eax
  103c5b:	0f b6 c9             	movzbl %cl,%ecx
  103c5e:	29 c8                	sub    %ecx,%eax
    s1++, s2++;
  }

  return 0;
}
  103c60:	5b                   	pop    %ebx
  103c61:	5e                   	pop    %esi
  103c62:	5f                   	pop    %edi
  103c63:	5d                   	pop    %ebp
  103c64:	c3                   	ret    
  103c65:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  103c69:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103c70 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
  103c70:	55                   	push   %ebp
  103c71:	89 e5                	mov    %esp,%ebp
  103c73:	57                   	push   %edi
  103c74:	56                   	push   %esi
  103c75:	53                   	push   %ebx
  103c76:	8b 45 08             	mov    0x8(%ebp),%eax
  103c79:	8b 75 0c             	mov    0xc(%ebp),%esi
  103c7c:	8b 5d 10             	mov    0x10(%ebp),%ebx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
  103c7f:	39 c6                	cmp    %eax,%esi
  103c81:	73 2d                	jae    103cb0 <memmove+0x40>
  103c83:	8d 3c 1e             	lea    (%esi,%ebx,1),%edi
  103c86:	39 f8                	cmp    %edi,%eax
  103c88:	73 26                	jae    103cb0 <memmove+0x40>
    s += n;
    d += n;
    while(n-- > 0)
  103c8a:	85 db                	test   %ebx,%ebx
  103c8c:	74 1d                	je     103cab <memmove+0x3b>

  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
  103c8e:	8d 34 18             	lea    (%eax,%ebx,1),%esi
  103c91:	31 d2                	xor    %edx,%edx
  103c93:	90                   	nop
  103c94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    while(n-- > 0)
      *--d = *--s;
  103c98:	0f b6 4c 17 ff       	movzbl -0x1(%edi,%edx,1),%ecx
  103c9d:	88 4c 16 ff          	mov    %cl,-0x1(%esi,%edx,1)
  103ca1:	83 ea 01             	sub    $0x1,%edx
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
  103ca4:	8d 0c 1a             	lea    (%edx,%ebx,1),%ecx
  103ca7:	85 c9                	test   %ecx,%ecx
  103ca9:	75 ed                	jne    103c98 <memmove+0x28>
  } else
    while(n-- > 0)
      *d++ = *s++;

  return dst;
}
  103cab:	5b                   	pop    %ebx
  103cac:	5e                   	pop    %esi
  103cad:	5f                   	pop    %edi
  103cae:	5d                   	pop    %ebp
  103caf:	c3                   	ret    
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
  103cb0:	31 d2                	xor    %edx,%edx
      *--d = *--s;
  } else
    while(n-- > 0)
  103cb2:	85 db                	test   %ebx,%ebx
  103cb4:	74 f5                	je     103cab <memmove+0x3b>
  103cb6:	66 90                	xchg   %ax,%ax
      *d++ = *s++;
  103cb8:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  103cbc:	88 0c 10             	mov    %cl,(%eax,%edx,1)
  103cbf:	83 c2 01             	add    $0x1,%edx
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
  103cc2:	39 d3                	cmp    %edx,%ebx
  103cc4:	75 f2                	jne    103cb8 <memmove+0x48>
      *d++ = *s++;

  return dst;
}
  103cc6:	5b                   	pop    %ebx
  103cc7:	5e                   	pop    %esi
  103cc8:	5f                   	pop    %edi
  103cc9:	5d                   	pop    %ebp
  103cca:	c3                   	ret    
  103ccb:	90                   	nop
  103ccc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00103cd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
  103cd0:	55                   	push   %ebp
  103cd1:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
}
  103cd3:	5d                   	pop    %ebp

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
  return memmove(dst, src, n);
  103cd4:	e9 97 ff ff ff       	jmp    103c70 <memmove>
  103cd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00103ce0 <strncmp>:
}

int
strncmp(const char *p, const char *q, uint n)
{
  103ce0:	55                   	push   %ebp
  103ce1:	89 e5                	mov    %esp,%ebp
  103ce3:	57                   	push   %edi
  103ce4:	56                   	push   %esi
  103ce5:	53                   	push   %ebx
  103ce6:	8b 7d 10             	mov    0x10(%ebp),%edi
  103ce9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  103cec:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  while(n > 0 && *p && *p == *q)
  103cef:	85 ff                	test   %edi,%edi
  103cf1:	74 3d                	je     103d30 <strncmp+0x50>
  103cf3:	0f b6 01             	movzbl (%ecx),%eax
  103cf6:	84 c0                	test   %al,%al
  103cf8:	75 18                	jne    103d12 <strncmp+0x32>
  103cfa:	eb 3c                	jmp    103d38 <strncmp+0x58>
  103cfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  103d00:	83 ef 01             	sub    $0x1,%edi
  103d03:	74 2b                	je     103d30 <strncmp+0x50>
    n--, p++, q++;
  103d05:	83 c1 01             	add    $0x1,%ecx
  103d08:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
  103d0b:	0f b6 01             	movzbl (%ecx),%eax
  103d0e:	84 c0                	test   %al,%al
  103d10:	74 26                	je     103d38 <strncmp+0x58>
  103d12:	0f b6 33             	movzbl (%ebx),%esi
  103d15:	89 f2                	mov    %esi,%edx
  103d17:	38 d0                	cmp    %dl,%al
  103d19:	74 e5                	je     103d00 <strncmp+0x20>
    n--, p++, q++;
  if(n == 0)
    return 0;
  return (uchar)*p - (uchar)*q;
  103d1b:	81 e6 ff 00 00 00    	and    $0xff,%esi
  103d21:	0f b6 c0             	movzbl %al,%eax
  103d24:	29 f0                	sub    %esi,%eax
}
  103d26:	5b                   	pop    %ebx
  103d27:	5e                   	pop    %esi
  103d28:	5f                   	pop    %edi
  103d29:	5d                   	pop    %ebp
  103d2a:	c3                   	ret    
  103d2b:	90                   	nop
  103d2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
  103d30:	31 c0                	xor    %eax,%eax
    n--, p++, q++;
  if(n == 0)
    return 0;
  return (uchar)*p - (uchar)*q;
}
  103d32:	5b                   	pop    %ebx
  103d33:	5e                   	pop    %esi
  103d34:	5f                   	pop    %edi
  103d35:	5d                   	pop    %ebp
  103d36:	c3                   	ret    
  103d37:	90                   	nop
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
  103d38:	0f b6 33             	movzbl (%ebx),%esi
  103d3b:	eb de                	jmp    103d1b <strncmp+0x3b>
  103d3d:	8d 76 00             	lea    0x0(%esi),%esi

00103d40 <strncpy>:
  return (uchar)*p - (uchar)*q;
}

char*
strncpy(char *s, const char *t, int n)
{
  103d40:	55                   	push   %ebp
  103d41:	89 e5                	mov    %esp,%ebp
  103d43:	8b 45 08             	mov    0x8(%ebp),%eax
  103d46:	56                   	push   %esi
  103d47:	8b 4d 10             	mov    0x10(%ebp),%ecx
  103d4a:	53                   	push   %ebx
  103d4b:	8b 75 0c             	mov    0xc(%ebp),%esi
  103d4e:	89 c3                	mov    %eax,%ebx
  103d50:	eb 09                	jmp    103d5b <strncpy+0x1b>
  103d52:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
  103d58:	83 c6 01             	add    $0x1,%esi
  103d5b:	83 e9 01             	sub    $0x1,%ecx
    return 0;
  return (uchar)*p - (uchar)*q;
}

char*
strncpy(char *s, const char *t, int n)
  103d5e:	8d 51 01             	lea    0x1(%ecx),%edx
{
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
  103d61:	85 d2                	test   %edx,%edx
  103d63:	7e 0c                	jle    103d71 <strncpy+0x31>
  103d65:	0f b6 16             	movzbl (%esi),%edx
  103d68:	88 13                	mov    %dl,(%ebx)
  103d6a:	83 c3 01             	add    $0x1,%ebx
  103d6d:	84 d2                	test   %dl,%dl
  103d6f:	75 e7                	jne    103d58 <strncpy+0x18>
    return 0;
  return (uchar)*p - (uchar)*q;
}

char*
strncpy(char *s, const char *t, int n)
  103d71:	31 d2                	xor    %edx,%edx
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
  103d73:	85 c9                	test   %ecx,%ecx
  103d75:	7e 0c                	jle    103d83 <strncpy+0x43>
  103d77:	90                   	nop
    *s++ = 0;
  103d78:	c6 04 13 00          	movb   $0x0,(%ebx,%edx,1)
  103d7c:	83 c2 01             	add    $0x1,%edx
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
  103d7f:	39 ca                	cmp    %ecx,%edx
  103d81:	75 f5                	jne    103d78 <strncpy+0x38>
    *s++ = 0;
  return os;
}
  103d83:	5b                   	pop    %ebx
  103d84:	5e                   	pop    %esi
  103d85:	5d                   	pop    %ebp
  103d86:	c3                   	ret    
  103d87:	89 f6                	mov    %esi,%esi
  103d89:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103d90 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
  103d90:	55                   	push   %ebp
  103d91:	89 e5                	mov    %esp,%ebp
  103d93:	8b 55 10             	mov    0x10(%ebp),%edx
  103d96:	56                   	push   %esi
  103d97:	8b 45 08             	mov    0x8(%ebp),%eax
  103d9a:	53                   	push   %ebx
  103d9b:	8b 75 0c             	mov    0xc(%ebp),%esi
  char *os;
  
  os = s;
  if(n <= 0)
  103d9e:	85 d2                	test   %edx,%edx
  103da0:	7e 1f                	jle    103dc1 <safestrcpy+0x31>
  103da2:	89 c1                	mov    %eax,%ecx
  103da4:	eb 05                	jmp    103dab <safestrcpy+0x1b>
  103da6:	66 90                	xchg   %ax,%ax
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
  103da8:	83 c6 01             	add    $0x1,%esi
  103dab:	83 ea 01             	sub    $0x1,%edx
  103dae:	85 d2                	test   %edx,%edx
  103db0:	7e 0c                	jle    103dbe <safestrcpy+0x2e>
  103db2:	0f b6 1e             	movzbl (%esi),%ebx
  103db5:	88 19                	mov    %bl,(%ecx)
  103db7:	83 c1 01             	add    $0x1,%ecx
  103dba:	84 db                	test   %bl,%bl
  103dbc:	75 ea                	jne    103da8 <safestrcpy+0x18>
    ;
  *s = 0;
  103dbe:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
  103dc1:	5b                   	pop    %ebx
  103dc2:	5e                   	pop    %esi
  103dc3:	5d                   	pop    %ebp
  103dc4:	c3                   	ret    
  103dc5:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  103dc9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103dd0 <strlen>:

int
strlen(const char *s)
{
  103dd0:	55                   	push   %ebp
  int n;

  for(n = 0; s[n]; n++)
  103dd1:	31 c0                	xor    %eax,%eax
  return os;
}

int
strlen(const char *s)
{
  103dd3:	89 e5                	mov    %esp,%ebp
  103dd5:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
  103dd8:	80 3a 00             	cmpb   $0x0,(%edx)
  103ddb:	74 0c                	je     103de9 <strlen+0x19>
  103ddd:	8d 76 00             	lea    0x0(%esi),%esi
  103de0:	83 c0 01             	add    $0x1,%eax
  103de3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  103de7:	75 f7                	jne    103de0 <strlen+0x10>
    ;
  return n;
}
  103de9:	5d                   	pop    %ebp
  103dea:	c3                   	ret    
  103deb:	90                   	nop

00103dec <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
  103dec:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
  103df0:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
  103df4:	55                   	push   %ebp
  pushl %ebx
  103df5:	53                   	push   %ebx
  pushl %esi
  103df6:	56                   	push   %esi
  pushl %edi
  103df7:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
  103df8:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
  103dfa:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
  103dfc:	5f                   	pop    %edi
  popl %esi
  103dfd:	5e                   	pop    %esi
  popl %ebx
  103dfe:	5b                   	pop    %ebx
  popl %ebp
  103dff:	5d                   	pop    %ebp
  ret
  103e00:	c3                   	ret    
  103e01:	90                   	nop
  103e02:	90                   	nop
  103e03:	90                   	nop
  103e04:	90                   	nop
  103e05:	90                   	nop
  103e06:	90                   	nop
  103e07:	90                   	nop
  103e08:	90                   	nop
  103e09:	90                   	nop
  103e0a:	90                   	nop
  103e0b:	90                   	nop
  103e0c:	90                   	nop
  103e0d:	90                   	nop
  103e0e:	90                   	nop
  103e0f:	90                   	nop

00103e10 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  103e10:	55                   	push   %ebp
  103e11:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
  103e13:	8b 55 08             	mov    0x8(%ebp),%edx
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  103e16:	8b 45 0c             	mov    0xc(%ebp),%eax
  if(addr >= p->sz || addr+4 > p->sz)
  103e19:	8b 12                	mov    (%edx),%edx
  103e1b:	39 c2                	cmp    %eax,%edx
  103e1d:	77 09                	ja     103e28 <fetchint+0x18>
    return -1;
  *ip = *(int*)(addr);
  return 0;
  103e1f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  103e24:	5d                   	pop    %ebp
  103e25:	c3                   	ret    
  103e26:	66 90                	xchg   %ax,%ax

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  103e28:	8d 48 04             	lea    0x4(%eax),%ecx
  103e2b:	39 ca                	cmp    %ecx,%edx
  103e2d:	72 f0                	jb     103e1f <fetchint+0xf>
    return -1;
  *ip = *(int*)(addr);
  103e2f:	8b 10                	mov    (%eax),%edx
  103e31:	8b 45 10             	mov    0x10(%ebp),%eax
  103e34:	89 10                	mov    %edx,(%eax)
  103e36:	31 c0                	xor    %eax,%eax
  return 0;
}
  103e38:	5d                   	pop    %ebp
  103e39:	c3                   	ret    
  103e3a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

00103e40 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
  103e40:	55                   	push   %ebp
  103e41:	89 e5                	mov    %esp,%ebp
  103e43:	8b 45 08             	mov    0x8(%ebp),%eax
  103e46:	8b 55 0c             	mov    0xc(%ebp),%edx
  103e49:	53                   	push   %ebx
  char *s, *ep;

  if(addr >= p->sz)
  103e4a:	39 10                	cmp    %edx,(%eax)
  103e4c:	77 0a                	ja     103e58 <fetchstr+0x18>
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
  103e4e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    if(*s == 0)
      return s - *pp;
  return -1;
}
  103e53:	5b                   	pop    %ebx
  103e54:	5d                   	pop    %ebp
  103e55:	c3                   	ret    
  103e56:	66 90                	xchg   %ax,%ax
{
  char *s, *ep;

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  103e58:	8b 4d 10             	mov    0x10(%ebp),%ecx
  103e5b:	89 11                	mov    %edx,(%ecx)
  ep = (char*)p->sz;
  103e5d:	8b 18                	mov    (%eax),%ebx
  for(s = *pp; s < ep; s++)
  103e5f:	39 da                	cmp    %ebx,%edx
  103e61:	73 eb                	jae    103e4e <fetchstr+0xe>
    if(*s == 0)
  103e63:	31 c0                	xor    %eax,%eax
  103e65:	89 d1                	mov    %edx,%ecx
  103e67:	80 3a 00             	cmpb   $0x0,(%edx)
  103e6a:	74 e7                	je     103e53 <fetchstr+0x13>
  103e6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
  103e70:	83 c1 01             	add    $0x1,%ecx
  103e73:	39 cb                	cmp    %ecx,%ebx
  103e75:	76 d7                	jbe    103e4e <fetchstr+0xe>
    if(*s == 0)
  103e77:	80 39 00             	cmpb   $0x0,(%ecx)
  103e7a:	75 f4                	jne    103e70 <fetchstr+0x30>
  103e7c:	89 c8                	mov    %ecx,%eax
  103e7e:	29 d0                	sub    %edx,%eax
  103e80:	eb d1                	jmp    103e53 <fetchstr+0x13>
  103e82:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  103e89:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103e90 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  103e90:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
}

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  103e96:	55                   	push   %ebp
  103e97:	89 e5                	mov    %esp,%ebp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  103e99:	8b 4d 08             	mov    0x8(%ebp),%ecx
  103e9c:	8b 50 18             	mov    0x18(%eax),%edx

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  103e9f:	8b 00                	mov    (%eax),%eax

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  103ea1:	8b 52 44             	mov    0x44(%edx),%edx
  103ea4:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  103ea8:	39 c2                	cmp    %eax,%edx
  103eaa:	72 0c                	jb     103eb8 <argint+0x28>
    return -1;
  *ip = *(int*)(addr);
  103eac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
}
  103eb1:	5d                   	pop    %ebp
  103eb2:	c3                   	ret    
  103eb3:	90                   	nop
  103eb4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  103eb8:	8d 4a 04             	lea    0x4(%edx),%ecx
  103ebb:	39 c8                	cmp    %ecx,%eax
  103ebd:	72 ed                	jb     103eac <argint+0x1c>
    return -1;
  *ip = *(int*)(addr);
  103ebf:	8b 45 0c             	mov    0xc(%ebp),%eax
  103ec2:	8b 12                	mov    (%edx),%edx
  103ec4:	89 10                	mov    %edx,(%eax)
  103ec6:	31 c0                	xor    %eax,%eax
// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
}
  103ec8:	5d                   	pop    %ebp
  103ec9:	c3                   	ret    
  103eca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

00103ed0 <argptr>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  103ed0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
  103ed6:	55                   	push   %ebp
  103ed7:	89 e5                	mov    %esp,%ebp

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  103ed9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  103edc:	8b 50 18             	mov    0x18(%eax),%edx

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  103edf:	8b 00                	mov    (%eax),%eax

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  103ee1:	8b 52 44             	mov    0x44(%edx),%edx
  103ee4:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  103ee8:	39 c2                	cmp    %eax,%edx
  103eea:	73 07                	jae    103ef3 <argptr+0x23>
  103eec:	8d 4a 04             	lea    0x4(%edx),%ecx
  103eef:	39 c8                	cmp    %ecx,%eax
  103ef1:	73 0d                	jae    103f00 <argptr+0x30>
  if(argint(n, &i) < 0)
    return -1;
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
    return -1;
  *pp = (char*)i;
  return 0;
  103ef3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  103ef8:	5d                   	pop    %ebp
  103ef9:	c3                   	ret    
  103efa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
    return -1;
  *ip = *(int*)(addr);
  103f00:	8b 12                	mov    (%edx),%edx
{
  int i;
  
  if(argint(n, &i) < 0)
    return -1;
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
  103f02:	39 c2                	cmp    %eax,%edx
  103f04:	73 ed                	jae    103ef3 <argptr+0x23>
  103f06:	8b 4d 10             	mov    0x10(%ebp),%ecx
  103f09:	01 d1                	add    %edx,%ecx
  103f0b:	39 c1                	cmp    %eax,%ecx
  103f0d:	77 e4                	ja     103ef3 <argptr+0x23>
    return -1;
  *pp = (char*)i;
  103f0f:	8b 45 0c             	mov    0xc(%ebp),%eax
  103f12:	89 10                	mov    %edx,(%eax)
  103f14:	31 c0                	xor    %eax,%eax
  return 0;
}
  103f16:	5d                   	pop    %ebp
  103f17:	c3                   	ret    
  103f18:	90                   	nop
  103f19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00103f20 <argstr>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  103f20:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
  103f27:	55                   	push   %ebp
  103f28:	89 e5                	mov    %esp,%ebp
  103f2a:	53                   	push   %ebx

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  103f2b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  103f2e:	8b 42 18             	mov    0x18(%edx),%eax
  103f31:	8b 40 44             	mov    0x44(%eax),%eax
  103f34:	8d 44 88 04          	lea    0x4(%eax,%ecx,4),%eax

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  103f38:	8b 0a                	mov    (%edx),%ecx
  103f3a:	39 c8                	cmp    %ecx,%eax
  103f3c:	73 07                	jae    103f45 <argstr+0x25>
  103f3e:	8d 58 04             	lea    0x4(%eax),%ebx
  103f41:	39 d9                	cmp    %ebx,%ecx
  103f43:	73 0b                	jae    103f50 <argstr+0x30>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
  103f45:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
{
  int addr;
  if(argint(n, &addr) < 0)
    return -1;
  return fetchstr(proc, addr, pp);
}
  103f4a:	5b                   	pop    %ebx
  103f4b:	5d                   	pop    %ebp
  103f4c:	c3                   	ret    
  103f4d:	8d 76 00             	lea    0x0(%esi),%esi
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
    return -1;
  *ip = *(int*)(addr);
  103f50:	8b 18                	mov    (%eax),%ebx
int
fetchstr(struct proc *p, uint addr, char **pp)
{
  char *s, *ep;

  if(addr >= p->sz)
  103f52:	39 cb                	cmp    %ecx,%ebx
  103f54:	73 ef                	jae    103f45 <argstr+0x25>
    return -1;
  *pp = (char*)addr;
  103f56:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  103f59:	89 d8                	mov    %ebx,%eax
  103f5b:	89 19                	mov    %ebx,(%ecx)
  ep = (char*)p->sz;
  103f5d:	8b 12                	mov    (%edx),%edx
  for(s = *pp; s < ep; s++)
  103f5f:	39 d3                	cmp    %edx,%ebx
  103f61:	73 e2                	jae    103f45 <argstr+0x25>
    if(*s == 0)
  103f63:	80 3b 00             	cmpb   $0x0,(%ebx)
  103f66:	75 12                	jne    103f7a <argstr+0x5a>
  103f68:	eb 1e                	jmp    103f88 <argstr+0x68>
  103f6a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  103f70:	80 38 00             	cmpb   $0x0,(%eax)
  103f73:	90                   	nop
  103f74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  103f78:	74 0e                	je     103f88 <argstr+0x68>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
  103f7a:	83 c0 01             	add    $0x1,%eax
  103f7d:	39 c2                	cmp    %eax,%edx
  103f7f:	90                   	nop
  103f80:	77 ee                	ja     103f70 <argstr+0x50>
  103f82:	eb c1                	jmp    103f45 <argstr+0x25>
  103f84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    if(*s == 0)
      return s - *pp;
  103f88:	29 d8                	sub    %ebx,%eax
{
  int addr;
  if(argint(n, &addr) < 0)
    return -1;
  return fetchstr(proc, addr, pp);
}
  103f8a:	5b                   	pop    %ebx
  103f8b:	5d                   	pop    %ebp
  103f8c:	c3                   	ret    
  103f8d:	8d 76 00             	lea    0x0(%esi),%esi

00103f90 <sys_getcount>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  103f90:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
}


int
sys_getcount(void)
{
  103f96:	55                   	push   %ebp
  103f97:	89 e5                	mov    %esp,%ebp

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  103f99:	8b 50 18             	mov    0x18(%eax),%edx

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  103f9c:	8b 00                	mov    (%eax),%eax

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  103f9e:	8b 52 44             	mov    0x44(%edx),%edx
  103fa1:	8d 4a 04             	lea    0x4(%edx),%ecx

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  103fa4:	39 c1                	cmp    %eax,%ecx
  103fa6:	72 08                	jb     103fb0 <sys_getcount+0x20>
  int num = 0;
  argint(0, &num); 

  if(num>22 || num <1) return -1;
  //cprintf("syscall_counts[%d] = %d",num-1,syscall_counts[num-1]);
  return syscall_counts[num-1];
  103fa8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

}
  103fad:	5d                   	pop    %ebp
  103fae:	c3                   	ret    
  103faf:	90                   	nop

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  103fb0:	8d 4a 08             	lea    0x8(%edx),%ecx
  103fb3:	39 c8                	cmp    %ecx,%eax
  103fb5:	72 f1                	jb     103fa8 <sys_getcount+0x18>
    return -1;
  *ip = *(int*)(addr);
  103fb7:	8b 42 04             	mov    0x4(%edx),%eax
sys_getcount(void)
{
  int num = 0;
  argint(0, &num); 

  if(num>22 || num <1) return -1;
  103fba:	83 e8 01             	sub    $0x1,%eax
  103fbd:	83 f8 15             	cmp    $0x15,%eax
  103fc0:	77 e6                	ja     103fa8 <sys_getcount+0x18>
  //cprintf("syscall_counts[%d] = %d",num-1,syscall_counts[num-1]);
  return syscall_counts[num-1];
  103fc2:	8b 04 85 60 e0 10 00 	mov    0x10e060(,%eax,4),%eax

}
  103fc9:	5d                   	pop    %ebp
  103fca:	c3                   	ret    
  103fcb:	90                   	nop
  103fcc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00103fd0 <syscall>:
int syscall_counts[22];


void
syscall(void)
{
  103fd0:	55                   	push   %ebp
  103fd1:	89 e5                	mov    %esp,%ebp
  103fd3:	83 ec 18             	sub    $0x18,%esp
  103fd6:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  103fd9:	89 75 fc             	mov    %esi,-0x4(%ebp)
  int num;
  
  num = proc->tf->eax;
  103fdc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103fe2:	8b 70 18             	mov    0x18(%eax),%esi
  103fe5:	8b 5e 1c             	mov    0x1c(%esi),%ebx
  if(num >= 0 && num < NELEM(syscalls) && syscalls[num])
  103fe8:	83 fb 16             	cmp    $0x16,%ebx
  103feb:	77 23                	ja     104010 <syscall+0x40>
  103fed:	8b 14 9d 20 6b 10 00 	mov    0x106b20(,%ebx,4),%edx
  103ff4:	85 d2                	test   %edx,%edx
  103ff6:	74 18                	je     104010 <syscall+0x40>
  {  
    proc->tf->eax = syscalls[num]();
  103ff8:	ff d2                	call   *%edx
  103ffa:	89 46 1c             	mov    %eax,0x1c(%esi)
    syscall_counts[num-1] += 1;
  103ffd:	83 04 9d 5c e0 10 00 	addl   $0x1,0x10e05c(,%ebx,4)
  104004:	01 
  else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
  }
}
  104005:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  104008:	8b 75 fc             	mov    -0x4(%ebp),%esi
  10400b:	89 ec                	mov    %ebp,%esp
  10400d:	5d                   	pop    %ebp
  10400e:	c3                   	ret    
  10400f:	90                   	nop
  {  
    proc->tf->eax = syscalls[num]();
    syscall_counts[num-1] += 1;
  }
  else {
    cprintf("%d %s: unknown sys call %d\n",
  104010:	8b 50 10             	mov    0x10(%eax),%edx
  104013:	83 c0 6c             	add    $0x6c,%eax
  104016:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  10401a:	89 44 24 08          	mov    %eax,0x8(%esp)
  10401e:	c7 04 24 ea 6a 10 00 	movl   $0x106aea,(%esp)
  104025:	89 54 24 04          	mov    %edx,0x4(%esp)
  104029:	e8 02 c5 ff ff       	call   100530 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
  10402e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104034:	8b 40 18             	mov    0x18(%eax),%eax
  104037:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
  10403e:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  104041:	8b 75 fc             	mov    -0x4(%ebp),%esi
  104044:	89 ec                	mov    %ebp,%esp
  104046:	5d                   	pop    %ebp
  104047:	c3                   	ret    
  104048:	90                   	nop
  104049:	90                   	nop
  10404a:	90                   	nop
  10404b:	90                   	nop
  10404c:	90                   	nop
  10404d:	90                   	nop
  10404e:	90                   	nop
  10404f:	90                   	nop

00104050 <sys_pipe>:
  return exec(path, argv);
}

int
sys_pipe(void)
{
  104050:	55                   	push   %ebp
  104051:	89 e5                	mov    %esp,%ebp
  104053:	83 ec 28             	sub    $0x28,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
  104056:	8d 45 f4             	lea    -0xc(%ebp),%eax
  return exec(path, argv);
}

int
sys_pipe(void)
{
  104059:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  10405c:	89 75 fc             	mov    %esi,-0x4(%ebp)
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
  10405f:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
  104066:	00 
  104067:	89 44 24 04          	mov    %eax,0x4(%esp)
  10406b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104072:	e8 59 fe ff ff       	call   103ed0 <argptr>
  104077:	85 c0                	test   %eax,%eax
  104079:	79 15                	jns    104090 <sys_pipe+0x40>
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    if(fd0 >= 0)
      proc->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  10407b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  fd[0] = fd0;
  fd[1] = fd1;
  return 0;
}
  104080:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  104083:	8b 75 fc             	mov    -0x4(%ebp),%esi
  104086:	89 ec                	mov    %ebp,%esp
  104088:	5d                   	pop    %ebp
  104089:	c3                   	ret    
  10408a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
    return -1;
  if(pipealloc(&rf, &wf) < 0)
  104090:	8d 45 ec             	lea    -0x14(%ebp),%eax
  104093:	89 44 24 04          	mov    %eax,0x4(%esp)
  104097:	8d 45 f0             	lea    -0x10(%ebp),%eax
  10409a:	89 04 24             	mov    %eax,(%esp)
  10409d:	e8 6e ee ff ff       	call   102f10 <pipealloc>
  1040a2:	85 c0                	test   %eax,%eax
  1040a4:	78 d5                	js     10407b <sys_pipe+0x2b>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
  1040a6:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  1040a9:	31 c0                	xor    %eax,%eax
  1040ab:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  1040b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd] == 0){
  1040b8:	8b 5c 82 28          	mov    0x28(%edx,%eax,4),%ebx
  1040bc:	85 db                	test   %ebx,%ebx
  1040be:	74 28                	je     1040e8 <sys_pipe+0x98>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
  1040c0:	83 c0 01             	add    $0x1,%eax
  1040c3:	83 f8 10             	cmp    $0x10,%eax
  1040c6:	75 f0                	jne    1040b8 <sys_pipe+0x68>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    if(fd0 >= 0)
      proc->ofile[fd0] = 0;
    fileclose(rf);
  1040c8:	89 0c 24             	mov    %ecx,(%esp)
  1040cb:	e8 b0 ce ff ff       	call   100f80 <fileclose>
    fileclose(wf);
  1040d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1040d3:	89 04 24             	mov    %eax,(%esp)
  1040d6:	e8 a5 ce ff ff       	call   100f80 <fileclose>
  1040db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    return -1;
  1040e0:	eb 9e                	jmp    104080 <sys_pipe+0x30>
  1040e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
  1040e8:	8d 58 08             	lea    0x8(%eax),%ebx
  1040eb:	89 4c 9a 08          	mov    %ecx,0x8(%edx,%ebx,4)
  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
    return -1;
  if(pipealloc(&rf, &wf) < 0)
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
  1040ef:	8b 75 ec             	mov    -0x14(%ebp),%esi
  1040f2:	31 d2                	xor    %edx,%edx
  1040f4:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
  1040fb:	90                   	nop
  1040fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd] == 0){
  104100:	83 7c 91 28 00       	cmpl   $0x0,0x28(%ecx,%edx,4)
  104105:	74 19                	je     104120 <sys_pipe+0xd0>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
  104107:	83 c2 01             	add    $0x1,%edx
  10410a:	83 fa 10             	cmp    $0x10,%edx
  10410d:	75 f1                	jne    104100 <sys_pipe+0xb0>
  if(pipealloc(&rf, &wf) < 0)
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    if(fd0 >= 0)
      proc->ofile[fd0] = 0;
  10410f:	c7 44 99 08 00 00 00 	movl   $0x0,0x8(%ecx,%ebx,4)
  104116:	00 
  104117:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  10411a:	eb ac                	jmp    1040c8 <sys_pipe+0x78>
  10411c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
  104120:	89 74 91 28          	mov    %esi,0x28(%ecx,%edx,4)
      proc->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
  104124:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  104127:	89 01                	mov    %eax,(%ecx)
  fd[1] = fd1;
  104129:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10412c:	89 50 04             	mov    %edx,0x4(%eax)
  10412f:	31 c0                	xor    %eax,%eax
  return 0;
  104131:	e9 4a ff ff ff       	jmp    104080 <sys_pipe+0x30>
  104136:	8d 76 00             	lea    0x0(%esi),%esi
  104139:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00104140 <sys_exec>:
  return 0;
}

int
sys_exec(void)
{
  104140:	55                   	push   %ebp
  104141:	89 e5                	mov    %esp,%ebp
  104143:	81 ec b8 00 00 00    	sub    $0xb8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
  104149:	8d 45 e4             	lea    -0x1c(%ebp),%eax
  return 0;
}

int
sys_exec(void)
{
  10414c:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  10414f:	89 75 f8             	mov    %esi,-0x8(%ebp)
  104152:	89 7d fc             	mov    %edi,-0x4(%ebp)
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
  104155:	89 44 24 04          	mov    %eax,0x4(%esp)
  104159:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104160:	e8 bb fd ff ff       	call   103f20 <argstr>
  104165:	85 c0                	test   %eax,%eax
  104167:	79 17                	jns    104180 <sys_exec+0x40>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
    if(i >= NELEM(argv))
  104169:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
}
  10416e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  104171:	8b 75 f8             	mov    -0x8(%ebp),%esi
  104174:	8b 7d fc             	mov    -0x4(%ebp),%edi
  104177:	89 ec                	mov    %ebp,%esp
  104179:	5d                   	pop    %ebp
  10417a:	c3                   	ret    
  10417b:	90                   	nop
  10417c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
{
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
  104180:	8d 45 e0             	lea    -0x20(%ebp),%eax
  104183:	89 44 24 04          	mov    %eax,0x4(%esp)
  104187:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10418e:	e8 fd fc ff ff       	call   103e90 <argint>
  104193:	85 c0                	test   %eax,%eax
  104195:	78 d2                	js     104169 <sys_exec+0x29>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  104197:	8d bd 5c ff ff ff    	lea    -0xa4(%ebp),%edi
  10419d:	31 f6                	xor    %esi,%esi
  10419f:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  1041a6:	00 
  1041a7:	31 db                	xor    %ebx,%ebx
  1041a9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1041b0:	00 
  1041b1:	89 3c 24             	mov    %edi,(%esp)
  1041b4:	e8 37 fa ff ff       	call   103bf0 <memset>
  1041b9:	eb 2c                	jmp    1041e7 <sys_exec+0xa7>
  1041bb:	90                   	nop
  1041bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
  1041c0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1041c4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1041ca:	8d 14 b7             	lea    (%edi,%esi,4),%edx
  1041cd:	89 54 24 08          	mov    %edx,0x8(%esp)
  1041d1:	89 04 24             	mov    %eax,(%esp)
  1041d4:	e8 67 fc ff ff       	call   103e40 <fetchstr>
  1041d9:	85 c0                	test   %eax,%eax
  1041db:	78 8c                	js     104169 <sys_exec+0x29>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
  1041dd:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
  1041e0:	83 fb 20             	cmp    $0x20,%ebx

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
  1041e3:	89 de                	mov    %ebx,%esi
    if(i >= NELEM(argv))
  1041e5:	74 82                	je     104169 <sys_exec+0x29>
      return -1;
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
  1041e7:	8d 45 dc             	lea    -0x24(%ebp),%eax
  1041ea:	89 44 24 08          	mov    %eax,0x8(%esp)
  1041ee:	8d 04 9d 00 00 00 00 	lea    0x0(,%ebx,4),%eax
  1041f5:	03 45 e0             	add    -0x20(%ebp),%eax
  1041f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1041fc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104202:	89 04 24             	mov    %eax,(%esp)
  104205:	e8 06 fc ff ff       	call   103e10 <fetchint>
  10420a:	85 c0                	test   %eax,%eax
  10420c:	0f 88 57 ff ff ff    	js     104169 <sys_exec+0x29>
      return -1;
    if(uarg == 0){
  104212:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104215:	85 c0                	test   %eax,%eax
  104217:	75 a7                	jne    1041c0 <sys_exec+0x80>
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
  104219:	8b 45 e4             	mov    -0x1c(%ebp),%eax
    if(i >= NELEM(argv))
      return -1;
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
      return -1;
    if(uarg == 0){
      argv[i] = 0;
  10421c:	c7 84 9d 5c ff ff ff 	movl   $0x0,-0xa4(%ebp,%ebx,4)
  104223:	00 00 00 00 
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
  104227:	89 7c 24 04          	mov    %edi,0x4(%esp)
  10422b:	89 04 24             	mov    %eax,(%esp)
  10422e:	e8 6d c7 ff ff       	call   1009a0 <exec>
  104233:	e9 36 ff ff ff       	jmp    10416e <sys_exec+0x2e>
  104238:	90                   	nop
  104239:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00104240 <sys_chdir>:
  return 0;
}

int
sys_chdir(void)
{
  104240:	55                   	push   %ebp
  104241:	89 e5                	mov    %esp,%ebp
  104243:	53                   	push   %ebx
  104244:	83 ec 24             	sub    $0x24,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
  104247:	8d 45 f4             	lea    -0xc(%ebp),%eax
  10424a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10424e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104255:	e8 c6 fc ff ff       	call   103f20 <argstr>
  10425a:	85 c0                	test   %eax,%eax
  10425c:	79 12                	jns    104270 <sys_chdir+0x30>
    return -1;
  }
  iunlock(ip);
  iput(proc->cwd);
  proc->cwd = ip;
  return 0;
  10425e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  104263:	83 c4 24             	add    $0x24,%esp
  104266:	5b                   	pop    %ebx
  104267:	5d                   	pop    %ebp
  104268:	c3                   	ret    
  104269:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
sys_chdir(void)
{
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
  104270:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104273:	89 04 24             	mov    %eax,(%esp)
  104276:	e8 d5 db ff ff       	call   101e50 <namei>
  10427b:	85 c0                	test   %eax,%eax
  10427d:	89 c3                	mov    %eax,%ebx
  10427f:	74 dd                	je     10425e <sys_chdir+0x1e>
    return -1;
  ilock(ip);
  104281:	89 04 24             	mov    %eax,(%esp)
  104284:	e8 27 d9 ff ff       	call   101bb0 <ilock>
  if(ip->type != T_DIR){
  104289:	66 83 7b 10 01       	cmpw   $0x1,0x10(%ebx)
  10428e:	75 26                	jne    1042b6 <sys_chdir+0x76>
    iunlockput(ip);
    return -1;
  }
  iunlock(ip);
  104290:	89 1c 24             	mov    %ebx,(%esp)
  104293:	e8 d8 d4 ff ff       	call   101770 <iunlock>
  iput(proc->cwd);
  104298:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  10429e:	8b 40 68             	mov    0x68(%eax),%eax
  1042a1:	89 04 24             	mov    %eax,(%esp)
  1042a4:	e8 d7 d5 ff ff       	call   101880 <iput>
  proc->cwd = ip;
  1042a9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1042af:	89 58 68             	mov    %ebx,0x68(%eax)
  1042b2:	31 c0                	xor    %eax,%eax
  return 0;
  1042b4:	eb ad                	jmp    104263 <sys_chdir+0x23>

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
    return -1;
  ilock(ip);
  if(ip->type != T_DIR){
    iunlockput(ip);
  1042b6:	89 1c 24             	mov    %ebx,(%esp)
  1042b9:	e8 02 d8 ff ff       	call   101ac0 <iunlockput>
  1042be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    return -1;
  1042c3:	eb 9e                	jmp    104263 <sys_chdir+0x23>
  1042c5:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1042c9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

001042d0 <create>:
  return 0;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
  1042d0:	55                   	push   %ebp
  1042d1:	89 e5                	mov    %esp,%ebp
  1042d3:	83 ec 58             	sub    $0x58,%esp
  1042d6:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
  1042d9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1042dc:	89 75 f8             	mov    %esi,-0x8(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
  1042df:	8d 75 d6             	lea    -0x2a(%ebp),%esi
  return 0;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
  1042e2:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
  1042e5:	31 db                	xor    %ebx,%ebx
  return 0;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
  1042e7:	89 7d fc             	mov    %edi,-0x4(%ebp)
  1042ea:	89 d7                	mov    %edx,%edi
  1042ec:	89 4d c0             	mov    %ecx,-0x40(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
  1042ef:	89 74 24 04          	mov    %esi,0x4(%esp)
  1042f3:	89 04 24             	mov    %eax,(%esp)
  1042f6:	e8 35 db ff ff       	call   101e30 <nameiparent>
  1042fb:	85 c0                	test   %eax,%eax
  1042fd:	74 47                	je     104346 <create+0x76>
    return 0;
  ilock(dp);
  1042ff:	89 04 24             	mov    %eax,(%esp)
  104302:	89 45 bc             	mov    %eax,-0x44(%ebp)
  104305:	e8 a6 d8 ff ff       	call   101bb0 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
  10430a:	8b 55 bc             	mov    -0x44(%ebp),%edx
  10430d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
  104310:	89 44 24 08          	mov    %eax,0x8(%esp)
  104314:	89 74 24 04          	mov    %esi,0x4(%esp)
  104318:	89 14 24             	mov    %edx,(%esp)
  10431b:	e8 50 d3 ff ff       	call   101670 <dirlookup>
  104320:	8b 55 bc             	mov    -0x44(%ebp),%edx
  104323:	85 c0                	test   %eax,%eax
  104325:	89 c3                	mov    %eax,%ebx
  104327:	74 3f                	je     104368 <create+0x98>
    iunlockput(dp);
  104329:	89 14 24             	mov    %edx,(%esp)
  10432c:	e8 8f d7 ff ff       	call   101ac0 <iunlockput>
    ilock(ip);
  104331:	89 1c 24             	mov    %ebx,(%esp)
  104334:	e8 77 d8 ff ff       	call   101bb0 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
  104339:	66 83 ff 02          	cmp    $0x2,%di
  10433d:	75 19                	jne    104358 <create+0x88>
  10433f:	66 83 7b 10 02       	cmpw   $0x2,0x10(%ebx)
  104344:	75 12                	jne    104358 <create+0x88>
  if(dirlink(dp, name, ip->inum) < 0)
    panic("create: dirlink");

  iunlockput(dp);
  return ip;
}
  104346:	89 d8                	mov    %ebx,%eax
  104348:	8b 75 f8             	mov    -0x8(%ebp),%esi
  10434b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  10434e:	8b 7d fc             	mov    -0x4(%ebp),%edi
  104351:	89 ec                	mov    %ebp,%esp
  104353:	5d                   	pop    %ebp
  104354:	c3                   	ret    
  104355:	8d 76 00             	lea    0x0(%esi),%esi
  if((ip = dirlookup(dp, name, &off)) != 0){
    iunlockput(dp);
    ilock(ip);
    if(type == T_FILE && ip->type == T_FILE)
      return ip;
    iunlockput(ip);
  104358:	89 1c 24             	mov    %ebx,(%esp)
  10435b:	31 db                	xor    %ebx,%ebx
  10435d:	e8 5e d7 ff ff       	call   101ac0 <iunlockput>
    return 0;
  104362:	eb e2                	jmp    104346 <create+0x76>
  104364:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  }

  if((ip = ialloc(dp->dev, type)) == 0)
  104368:	0f bf c7             	movswl %di,%eax
  10436b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10436f:	8b 02                	mov    (%edx),%eax
  104371:	89 55 bc             	mov    %edx,-0x44(%ebp)
  104374:	89 04 24             	mov    %eax,(%esp)
  104377:	e8 64 d7 ff ff       	call   101ae0 <ialloc>
  10437c:	8b 55 bc             	mov    -0x44(%ebp),%edx
  10437f:	85 c0                	test   %eax,%eax
  104381:	89 c3                	mov    %eax,%ebx
  104383:	0f 84 b7 00 00 00    	je     104440 <create+0x170>
    panic("create: ialloc");

  ilock(ip);
  104389:	89 55 bc             	mov    %edx,-0x44(%ebp)
  10438c:	89 04 24             	mov    %eax,(%esp)
  10438f:	e8 1c d8 ff ff       	call   101bb0 <ilock>
  ip->major = major;
  104394:	0f b7 45 c4          	movzwl -0x3c(%ebp),%eax
  104398:	66 89 43 12          	mov    %ax,0x12(%ebx)
  ip->minor = minor;
  10439c:	0f b7 4d c0          	movzwl -0x40(%ebp),%ecx
  ip->nlink = 1;
  1043a0:	66 c7 43 16 01 00    	movw   $0x1,0x16(%ebx)
  if((ip = ialloc(dp->dev, type)) == 0)
    panic("create: ialloc");

  ilock(ip);
  ip->major = major;
  ip->minor = minor;
  1043a6:	66 89 4b 14          	mov    %cx,0x14(%ebx)
  ip->nlink = 1;
  iupdate(ip);
  1043aa:	89 1c 24             	mov    %ebx,(%esp)
  1043ad:	e8 be d0 ff ff       	call   101470 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
  1043b2:	66 83 ff 01          	cmp    $0x1,%di
  1043b6:	8b 55 bc             	mov    -0x44(%ebp),%edx
  1043b9:	74 2d                	je     1043e8 <create+0x118>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
      panic("create dots");
  }

  if(dirlink(dp, name, ip->inum) < 0)
  1043bb:	8b 43 04             	mov    0x4(%ebx),%eax
  1043be:	89 14 24             	mov    %edx,(%esp)
  1043c1:	89 55 bc             	mov    %edx,-0x44(%ebp)
  1043c4:	89 74 24 04          	mov    %esi,0x4(%esp)
  1043c8:	89 44 24 08          	mov    %eax,0x8(%esp)
  1043cc:	e8 ff d5 ff ff       	call   1019d0 <dirlink>
  1043d1:	8b 55 bc             	mov    -0x44(%ebp),%edx
  1043d4:	85 c0                	test   %eax,%eax
  1043d6:	78 74                	js     10444c <create+0x17c>
    panic("create: dirlink");

  iunlockput(dp);
  1043d8:	89 14 24             	mov    %edx,(%esp)
  1043db:	e8 e0 d6 ff ff       	call   101ac0 <iunlockput>
  return ip;
  1043e0:	e9 61 ff ff ff       	jmp    104346 <create+0x76>
  1043e5:	8d 76 00             	lea    0x0(%esi),%esi
  ip->minor = minor;
  ip->nlink = 1;
  iupdate(ip);

  if(type == T_DIR){  // Create . and .. entries.
    dp->nlink++;  // for ".."
  1043e8:	66 83 42 16 01       	addw   $0x1,0x16(%edx)
    iupdate(dp);
  1043ed:	89 14 24             	mov    %edx,(%esp)
  1043f0:	89 55 bc             	mov    %edx,-0x44(%ebp)
  1043f3:	e8 78 d0 ff ff       	call   101470 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
  1043f8:	8b 43 04             	mov    0x4(%ebx),%eax
  1043fb:	c7 44 24 04 8c 6b 10 	movl   $0x106b8c,0x4(%esp)
  104402:	00 
  104403:	89 1c 24             	mov    %ebx,(%esp)
  104406:	89 44 24 08          	mov    %eax,0x8(%esp)
  10440a:	e8 c1 d5 ff ff       	call   1019d0 <dirlink>
  10440f:	8b 55 bc             	mov    -0x44(%ebp),%edx
  104412:	85 c0                	test   %eax,%eax
  104414:	78 1e                	js     104434 <create+0x164>
  104416:	8b 42 04             	mov    0x4(%edx),%eax
  104419:	c7 44 24 04 8b 6b 10 	movl   $0x106b8b,0x4(%esp)
  104420:	00 
  104421:	89 1c 24             	mov    %ebx,(%esp)
  104424:	89 44 24 08          	mov    %eax,0x8(%esp)
  104428:	e8 a3 d5 ff ff       	call   1019d0 <dirlink>
  10442d:	8b 55 bc             	mov    -0x44(%ebp),%edx
  104430:	85 c0                	test   %eax,%eax
  104432:	79 87                	jns    1043bb <create+0xeb>
      panic("create dots");
  104434:	c7 04 24 8e 6b 10 00 	movl   $0x106b8e,(%esp)
  10443b:	e8 e0 c4 ff ff       	call   100920 <panic>
    iunlockput(ip);
    return 0;
  }

  if((ip = ialloc(dp->dev, type)) == 0)
    panic("create: ialloc");
  104440:	c7 04 24 7c 6b 10 00 	movl   $0x106b7c,(%esp)
  104447:	e8 d4 c4 ff ff       	call   100920 <panic>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
      panic("create dots");
  }

  if(dirlink(dp, name, ip->inum) < 0)
    panic("create: dirlink");
  10444c:	c7 04 24 9a 6b 10 00 	movl   $0x106b9a,(%esp)
  104453:	e8 c8 c4 ff ff       	call   100920 <panic>
  104458:	90                   	nop
  104459:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00104460 <sys_mknod>:
  return 0;
}

int
sys_mknod(void)
{
  104460:	55                   	push   %ebp
  104461:	89 e5                	mov    %esp,%ebp
  104463:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  if((len=argstr(0, &path)) < 0 ||
  104466:	8d 45 f4             	lea    -0xc(%ebp),%eax
  104469:	89 44 24 04          	mov    %eax,0x4(%esp)
  10446d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104474:	e8 a7 fa ff ff       	call   103f20 <argstr>
  104479:	85 c0                	test   %eax,%eax
  10447b:	79 0b                	jns    104488 <sys_mknod+0x28>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0)
    return -1;
  iunlockput(ip);
  return 0;
  10447d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  104482:	c9                   	leave  
  104483:	c3                   	ret    
  104484:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  char *path;
  int len;
  int major, minor;
  
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
  104488:	8d 45 f0             	lea    -0x10(%ebp),%eax
  10448b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10448f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104496:	e8 f5 f9 ff ff       	call   103e90 <argint>
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  if((len=argstr(0, &path)) < 0 ||
  10449b:	85 c0                	test   %eax,%eax
  10449d:	78 de                	js     10447d <sys_mknod+0x1d>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
  10449f:	8d 45 ec             	lea    -0x14(%ebp),%eax
  1044a2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1044a6:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  1044ad:	e8 de f9 ff ff       	call   103e90 <argint>
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  if((len=argstr(0, &path)) < 0 ||
  1044b2:	85 c0                	test   %eax,%eax
  1044b4:	78 c7                	js     10447d <sys_mknod+0x1d>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0)
  1044b6:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
  1044ba:	ba 03 00 00 00       	mov    $0x3,%edx
  1044bf:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
  1044c3:	89 04 24             	mov    %eax,(%esp)
  1044c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1044c9:	e8 02 fe ff ff       	call   1042d0 <create>
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  if((len=argstr(0, &path)) < 0 ||
  1044ce:	85 c0                	test   %eax,%eax
  1044d0:	74 ab                	je     10447d <sys_mknod+0x1d>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0)
    return -1;
  iunlockput(ip);
  1044d2:	89 04 24             	mov    %eax,(%esp)
  1044d5:	e8 e6 d5 ff ff       	call   101ac0 <iunlockput>
  1044da:	31 c0                	xor    %eax,%eax
  return 0;
}
  1044dc:	c9                   	leave  
  1044dd:	c3                   	ret    
  1044de:	66 90                	xchg   %ax,%ax

001044e0 <sys_mkdir>:
  return fd;
}

int
sys_mkdir(void)
{
  1044e0:	55                   	push   %ebp
  1044e1:	89 e5                	mov    %esp,%ebp
  1044e3:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0)
  1044e6:	8d 45 f4             	lea    -0xc(%ebp),%eax
  1044e9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1044ed:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1044f4:	e8 27 fa ff ff       	call   103f20 <argstr>
  1044f9:	85 c0                	test   %eax,%eax
  1044fb:	79 0b                	jns    104508 <sys_mkdir+0x28>
    return -1;
  iunlockput(ip);
  return 0;
  1044fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  104502:	c9                   	leave  
  104503:	c3                   	ret    
  104504:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
sys_mkdir(void)
{
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0)
  104508:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10450f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104512:	31 c9                	xor    %ecx,%ecx
  104514:	ba 01 00 00 00       	mov    $0x1,%edx
  104519:	e8 b2 fd ff ff       	call   1042d0 <create>
  10451e:	85 c0                	test   %eax,%eax
  104520:	74 db                	je     1044fd <sys_mkdir+0x1d>
    return -1;
  iunlockput(ip);
  104522:	89 04 24             	mov    %eax,(%esp)
  104525:	e8 96 d5 ff ff       	call   101ac0 <iunlockput>
  10452a:	31 c0                	xor    %eax,%eax
  return 0;
}
  10452c:	c9                   	leave  
  10452d:	c3                   	ret    
  10452e:	66 90                	xchg   %ax,%ax

00104530 <sys_link>:
}

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
  104530:	55                   	push   %ebp
  104531:	89 e5                	mov    %esp,%ebp
  104533:	83 ec 48             	sub    $0x48,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
  104536:	8d 45 e0             	lea    -0x20(%ebp),%eax
}

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
  104539:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  10453c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  10453f:	89 7d fc             	mov    %edi,-0x4(%ebp)
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
  104542:	89 44 24 04          	mov    %eax,0x4(%esp)
  104546:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10454d:	e8 ce f9 ff ff       	call   103f20 <argstr>
  104552:	85 c0                	test   %eax,%eax
  104554:	79 12                	jns    104568 <sys_link+0x38>
bad:
  ilock(ip);
  ip->nlink--;
  iupdate(ip);
  iunlockput(ip);
  return -1;
  104556:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  10455b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  10455e:	8b 75 f8             	mov    -0x8(%ebp),%esi
  104561:	8b 7d fc             	mov    -0x4(%ebp),%edi
  104564:	89 ec                	mov    %ebp,%esp
  104566:	5d                   	pop    %ebp
  104567:	c3                   	ret    
sys_link(void)
{
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
  104568:	8d 45 e4             	lea    -0x1c(%ebp),%eax
  10456b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10456f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104576:	e8 a5 f9 ff ff       	call   103f20 <argstr>
  10457b:	85 c0                	test   %eax,%eax
  10457d:	78 d7                	js     104556 <sys_link+0x26>
    return -1;
  if((ip = namei(old)) == 0)
  10457f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104582:	89 04 24             	mov    %eax,(%esp)
  104585:	e8 c6 d8 ff ff       	call   101e50 <namei>
  10458a:	85 c0                	test   %eax,%eax
  10458c:	89 c3                	mov    %eax,%ebx
  10458e:	74 c6                	je     104556 <sys_link+0x26>
    return -1;
  ilock(ip);
  104590:	89 04 24             	mov    %eax,(%esp)
  104593:	e8 18 d6 ff ff       	call   101bb0 <ilock>
  if(ip->type == T_DIR){
  104598:	66 83 7b 10 01       	cmpw   $0x1,0x10(%ebx)
  10459d:	0f 84 86 00 00 00    	je     104629 <sys_link+0xf9>
    iunlockput(ip);
    return -1;
  }
  ip->nlink++;
  1045a3:	66 83 43 16 01       	addw   $0x1,0x16(%ebx)
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
  1045a8:	8d 7d d2             	lea    -0x2e(%ebp),%edi
  if(ip->type == T_DIR){
    iunlockput(ip);
    return -1;
  }
  ip->nlink++;
  iupdate(ip);
  1045ab:	89 1c 24             	mov    %ebx,(%esp)
  1045ae:	e8 bd ce ff ff       	call   101470 <iupdate>
  iunlock(ip);
  1045b3:	89 1c 24             	mov    %ebx,(%esp)
  1045b6:	e8 b5 d1 ff ff       	call   101770 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
  1045bb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1045be:	89 7c 24 04          	mov    %edi,0x4(%esp)
  1045c2:	89 04 24             	mov    %eax,(%esp)
  1045c5:	e8 66 d8 ff ff       	call   101e30 <nameiparent>
  1045ca:	85 c0                	test   %eax,%eax
  1045cc:	89 c6                	mov    %eax,%esi
  1045ce:	74 44                	je     104614 <sys_link+0xe4>
    goto bad;
  ilock(dp);
  1045d0:	89 04 24             	mov    %eax,(%esp)
  1045d3:	e8 d8 d5 ff ff       	call   101bb0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
  1045d8:	8b 06                	mov    (%esi),%eax
  1045da:	3b 03                	cmp    (%ebx),%eax
  1045dc:	75 2e                	jne    10460c <sys_link+0xdc>
  1045de:	8b 43 04             	mov    0x4(%ebx),%eax
  1045e1:	89 7c 24 04          	mov    %edi,0x4(%esp)
  1045e5:	89 34 24             	mov    %esi,(%esp)
  1045e8:	89 44 24 08          	mov    %eax,0x8(%esp)
  1045ec:	e8 df d3 ff ff       	call   1019d0 <dirlink>
  1045f1:	85 c0                	test   %eax,%eax
  1045f3:	78 17                	js     10460c <sys_link+0xdc>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
  1045f5:	89 34 24             	mov    %esi,(%esp)
  1045f8:	e8 c3 d4 ff ff       	call   101ac0 <iunlockput>
  iput(ip);
  1045fd:	89 1c 24             	mov    %ebx,(%esp)
  104600:	e8 7b d2 ff ff       	call   101880 <iput>
  104605:	31 c0                	xor    %eax,%eax
  return 0;
  104607:	e9 4f ff ff ff       	jmp    10455b <sys_link+0x2b>

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
  ilock(dp);
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    iunlockput(dp);
  10460c:	89 34 24             	mov    %esi,(%esp)
  10460f:	e8 ac d4 ff ff       	call   101ac0 <iunlockput>
  iunlockput(dp);
  iput(ip);
  return 0;

bad:
  ilock(ip);
  104614:	89 1c 24             	mov    %ebx,(%esp)
  104617:	e8 94 d5 ff ff       	call   101bb0 <ilock>
  ip->nlink--;
  10461c:	66 83 6b 16 01       	subw   $0x1,0x16(%ebx)
  iupdate(ip);
  104621:	89 1c 24             	mov    %ebx,(%esp)
  104624:	e8 47 ce ff ff       	call   101470 <iupdate>
  iunlockput(ip);
  104629:	89 1c 24             	mov    %ebx,(%esp)
  10462c:	e8 8f d4 ff ff       	call   101ac0 <iunlockput>
  104631:	83 c8 ff             	or     $0xffffffff,%eax
  return -1;
  104634:	e9 22 ff ff ff       	jmp    10455b <sys_link+0x2b>
  104639:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00104640 <sys_open>:
  return ip;
}

int
sys_open(void)
{
  104640:	55                   	push   %ebp
  104641:	89 e5                	mov    %esp,%ebp
  104643:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
  104646:	8d 45 f4             	lea    -0xc(%ebp),%eax
  return ip;
}

int
sys_open(void)
{
  104649:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  10464c:	89 75 fc             	mov    %esi,-0x4(%ebp)
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
  10464f:	89 44 24 04          	mov    %eax,0x4(%esp)
  104653:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10465a:	e8 c1 f8 ff ff       	call   103f20 <argstr>
  10465f:	85 c0                	test   %eax,%eax
  104661:	79 15                	jns    104678 <sys_open+0x38>

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    if(f)
      fileclose(f);
    iunlockput(ip);
    return -1;
  104663:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  f->ip = ip;
  f->off = 0;
  f->readable = !(omode & O_WRONLY);
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
  return fd;
}
  104668:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  10466b:	8b 75 fc             	mov    -0x4(%ebp),%esi
  10466e:	89 ec                	mov    %ebp,%esp
  104670:	5d                   	pop    %ebp
  104671:	c3                   	ret    
  104672:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
  104678:	8d 45 f0             	lea    -0x10(%ebp),%eax
  10467b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10467f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104686:	e8 05 f8 ff ff       	call   103e90 <argint>
  10468b:	85 c0                	test   %eax,%eax
  10468d:	78 d4                	js     104663 <sys_open+0x23>
    return -1;
  if(omode & O_CREATE){
  10468f:	f6 45 f1 02          	testb  $0x2,-0xf(%ebp)
  104693:	74 63                	je     1046f8 <sys_open+0xb8>
    if((ip = create(path, T_FILE, 0, 0)) == 0)
  104695:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104698:	31 c9                	xor    %ecx,%ecx
  10469a:	ba 02 00 00 00       	mov    $0x2,%edx
  10469f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1046a6:	e8 25 fc ff ff       	call   1042d0 <create>
  1046ab:	85 c0                	test   %eax,%eax
  1046ad:	89 c3                	mov    %eax,%ebx
  1046af:	74 b2                	je     104663 <sys_open+0x23>
      iunlockput(ip);
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
  1046b1:	e8 4a c8 ff ff       	call   100f00 <filealloc>
  1046b6:	85 c0                	test   %eax,%eax
  1046b8:	89 c6                	mov    %eax,%esi
  1046ba:	74 24                	je     1046e0 <sys_open+0xa0>
  1046bc:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  1046c3:	31 c0                	xor    %eax,%eax
  1046c5:	8d 76 00             	lea    0x0(%esi),%esi
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd] == 0){
  1046c8:	8b 4c 82 28          	mov    0x28(%edx,%eax,4),%ecx
  1046cc:	85 c9                	test   %ecx,%ecx
  1046ce:	74 58                	je     104728 <sys_open+0xe8>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
  1046d0:	83 c0 01             	add    $0x1,%eax
  1046d3:	83 f8 10             	cmp    $0x10,%eax
  1046d6:	75 f0                	jne    1046c8 <sys_open+0x88>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    if(f)
      fileclose(f);
  1046d8:	89 34 24             	mov    %esi,(%esp)
  1046db:	e8 a0 c8 ff ff       	call   100f80 <fileclose>
    iunlockput(ip);
  1046e0:	89 1c 24             	mov    %ebx,(%esp)
  1046e3:	e8 d8 d3 ff ff       	call   101ac0 <iunlockput>
  1046e8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    return -1;
  1046ed:	e9 76 ff ff ff       	jmp    104668 <sys_open+0x28>
  1046f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    return -1;
  if(omode & O_CREATE){
    if((ip = create(path, T_FILE, 0, 0)) == 0)
      return -1;
  } else {
    if((ip = namei(path)) == 0)
  1046f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1046fb:	89 04 24             	mov    %eax,(%esp)
  1046fe:	e8 4d d7 ff ff       	call   101e50 <namei>
  104703:	85 c0                	test   %eax,%eax
  104705:	89 c3                	mov    %eax,%ebx
  104707:	0f 84 56 ff ff ff    	je     104663 <sys_open+0x23>
      return -1;
    ilock(ip);
  10470d:	89 04 24             	mov    %eax,(%esp)
  104710:	e8 9b d4 ff ff       	call   101bb0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
  104715:	66 83 7b 10 01       	cmpw   $0x1,0x10(%ebx)
  10471a:	75 95                	jne    1046b1 <sys_open+0x71>
  10471c:	8b 75 f0             	mov    -0x10(%ebp),%esi
  10471f:	85 f6                	test   %esi,%esi
  104721:	74 8e                	je     1046b1 <sys_open+0x71>
  104723:	eb bb                	jmp    1046e0 <sys_open+0xa0>
  104725:	8d 76 00             	lea    0x0(%esi),%esi
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
  104728:	89 74 82 28          	mov    %esi,0x28(%edx,%eax,4)
    if(f)
      fileclose(f);
    iunlockput(ip);
    return -1;
  }
  iunlock(ip);
  10472c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  10472f:	89 1c 24             	mov    %ebx,(%esp)
  104732:	e8 39 d0 ff ff       	call   101770 <iunlock>

  f->type = FD_INODE;
  104737:	c7 06 02 00 00 00    	movl   $0x2,(%esi)
  f->ip = ip;
  10473d:	89 5e 10             	mov    %ebx,0x10(%esi)
  f->off = 0;
  104740:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)
  f->readable = !(omode & O_WRONLY);
  104747:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10474a:	83 f2 01             	xor    $0x1,%edx
  10474d:	83 e2 01             	and    $0x1,%edx
  104750:	88 56 08             	mov    %dl,0x8(%esi)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
  104753:	f6 45 f0 03          	testb  $0x3,-0x10(%ebp)
  104757:	0f 95 46 09          	setne  0x9(%esi)
  return fd;
  10475b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10475e:	e9 05 ff ff ff       	jmp    104668 <sys_open+0x28>
  104763:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  104769:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00104770 <sys_unlink>:
  return 1;
}

int
sys_unlink(void)
{
  104770:	55                   	push   %ebp
  104771:	89 e5                	mov    %esp,%ebp
  104773:	83 ec 78             	sub    $0x78,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
  104776:	8d 45 e4             	lea    -0x1c(%ebp),%eax
  return 1;
}

int
sys_unlink(void)
{
  104779:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  10477c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  10477f:	89 7d fc             	mov    %edi,-0x4(%ebp)
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
  104782:	89 44 24 04          	mov    %eax,0x4(%esp)
  104786:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10478d:	e8 8e f7 ff ff       	call   103f20 <argstr>
  104792:	85 c0                	test   %eax,%eax
  104794:	79 12                	jns    1047a8 <sys_unlink+0x38>
  iunlockput(dp);

  ip->nlink--;
  iupdate(ip);
  iunlockput(ip);
  return 0;
  104796:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  10479b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  10479e:	8b 75 f8             	mov    -0x8(%ebp),%esi
  1047a1:	8b 7d fc             	mov    -0x4(%ebp),%edi
  1047a4:	89 ec                	mov    %ebp,%esp
  1047a6:	5d                   	pop    %ebp
  1047a7:	c3                   	ret    
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
    return -1;
  if((dp = nameiparent(path, name)) == 0)
  1047a8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1047ab:	8d 5d d2             	lea    -0x2e(%ebp),%ebx
  1047ae:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  1047b2:	89 04 24             	mov    %eax,(%esp)
  1047b5:	e8 76 d6 ff ff       	call   101e30 <nameiparent>
  1047ba:	85 c0                	test   %eax,%eax
  1047bc:	89 45 a4             	mov    %eax,-0x5c(%ebp)
  1047bf:	74 d5                	je     104796 <sys_unlink+0x26>
    return -1;
  ilock(dp);
  1047c1:	89 04 24             	mov    %eax,(%esp)
  1047c4:	e8 e7 d3 ff ff       	call   101bb0 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0){
  1047c9:	c7 44 24 04 8c 6b 10 	movl   $0x106b8c,0x4(%esp)
  1047d0:	00 
  1047d1:	89 1c 24             	mov    %ebx,(%esp)
  1047d4:	e8 67 ce ff ff       	call   101640 <namecmp>
  1047d9:	85 c0                	test   %eax,%eax
  1047db:	0f 84 a4 00 00 00    	je     104885 <sys_unlink+0x115>
  1047e1:	c7 44 24 04 8b 6b 10 	movl   $0x106b8b,0x4(%esp)
  1047e8:	00 
  1047e9:	89 1c 24             	mov    %ebx,(%esp)
  1047ec:	e8 4f ce ff ff       	call   101640 <namecmp>
  1047f1:	85 c0                	test   %eax,%eax
  1047f3:	0f 84 8c 00 00 00    	je     104885 <sys_unlink+0x115>
    iunlockput(dp);
    return -1;
  }

  if((ip = dirlookup(dp, name, &off)) == 0){
  1047f9:	8d 45 e0             	lea    -0x20(%ebp),%eax
  1047fc:	89 44 24 08          	mov    %eax,0x8(%esp)
  104800:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  104803:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  104807:	89 04 24             	mov    %eax,(%esp)
  10480a:	e8 61 ce ff ff       	call   101670 <dirlookup>
  10480f:	85 c0                	test   %eax,%eax
  104811:	89 c6                	mov    %eax,%esi
  104813:	74 70                	je     104885 <sys_unlink+0x115>
    iunlockput(dp);
    return -1;
  }
  ilock(ip);
  104815:	89 04 24             	mov    %eax,(%esp)
  104818:	e8 93 d3 ff ff       	call   101bb0 <ilock>

  if(ip->nlink < 1)
  10481d:	66 83 7e 16 00       	cmpw   $0x0,0x16(%esi)
  104822:	0f 8e 0e 01 00 00    	jle    104936 <sys_unlink+0x1c6>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
  104828:	66 83 7e 10 01       	cmpw   $0x1,0x10(%esi)
  10482d:	75 71                	jne    1048a0 <sys_unlink+0x130>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
  10482f:	83 7e 18 20          	cmpl   $0x20,0x18(%esi)
  104833:	76 6b                	jbe    1048a0 <sys_unlink+0x130>
  104835:	8d 7d b2             	lea    -0x4e(%ebp),%edi
  104838:	bb 20 00 00 00       	mov    $0x20,%ebx
  10483d:	8d 76 00             	lea    0x0(%esi),%esi
  104840:	eb 0e                	jmp    104850 <sys_unlink+0xe0>
  104842:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  104848:	83 c3 10             	add    $0x10,%ebx
  10484b:	3b 5e 18             	cmp    0x18(%esi),%ebx
  10484e:	73 50                	jae    1048a0 <sys_unlink+0x130>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
  104850:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  104857:	00 
  104858:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  10485c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  104860:	89 34 24             	mov    %esi,(%esp)
  104863:	e8 08 cb ff ff       	call   101370 <readi>
  104868:	83 f8 10             	cmp    $0x10,%eax
  10486b:	0f 85 ad 00 00 00    	jne    10491e <sys_unlink+0x1ae>
      panic("isdirempty: readi");
    if(de.inum != 0)
  104871:	66 83 7d b2 00       	cmpw   $0x0,-0x4e(%ebp)
  104876:	74 d0                	je     104848 <sys_unlink+0xd8>
  ilock(ip);

  if(ip->nlink < 1)
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    iunlockput(ip);
  104878:	89 34 24             	mov    %esi,(%esp)
  10487b:	90                   	nop
  10487c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  104880:	e8 3b d2 ff ff       	call   101ac0 <iunlockput>
    iunlockput(dp);
  104885:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  104888:	89 04 24             	mov    %eax,(%esp)
  10488b:	e8 30 d2 ff ff       	call   101ac0 <iunlockput>
  104890:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    return -1;
  104895:	e9 01 ff ff ff       	jmp    10479b <sys_unlink+0x2b>
  10489a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  }

  memset(&de, 0, sizeof(de));
  1048a0:	8d 5d c2             	lea    -0x3e(%ebp),%ebx
  1048a3:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
  1048aa:	00 
  1048ab:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1048b2:	00 
  1048b3:	89 1c 24             	mov    %ebx,(%esp)
  1048b6:	e8 35 f3 ff ff       	call   103bf0 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
  1048bb:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1048be:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  1048c5:	00 
  1048c6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  1048ca:	89 44 24 08          	mov    %eax,0x8(%esp)
  1048ce:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  1048d1:	89 04 24             	mov    %eax,(%esp)
  1048d4:	e8 27 cc ff ff       	call   101500 <writei>
  1048d9:	83 f8 10             	cmp    $0x10,%eax
  1048dc:	75 4c                	jne    10492a <sys_unlink+0x1ba>
    panic("unlink: writei");
  if(ip->type == T_DIR){
  1048de:	66 83 7e 10 01       	cmpw   $0x1,0x10(%esi)
  1048e3:	74 27                	je     10490c <sys_unlink+0x19c>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
  1048e5:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  1048e8:	89 04 24             	mov    %eax,(%esp)
  1048eb:	e8 d0 d1 ff ff       	call   101ac0 <iunlockput>

  ip->nlink--;
  1048f0:	66 83 6e 16 01       	subw   $0x1,0x16(%esi)
  iupdate(ip);
  1048f5:	89 34 24             	mov    %esi,(%esp)
  1048f8:	e8 73 cb ff ff       	call   101470 <iupdate>
  iunlockput(ip);
  1048fd:	89 34 24             	mov    %esi,(%esp)
  104900:	e8 bb d1 ff ff       	call   101ac0 <iunlockput>
  104905:	31 c0                	xor    %eax,%eax
  return 0;
  104907:	e9 8f fe ff ff       	jmp    10479b <sys_unlink+0x2b>

  memset(&de, 0, sizeof(de));
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
    panic("unlink: writei");
  if(ip->type == T_DIR){
    dp->nlink--;
  10490c:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  10490f:	66 83 68 16 01       	subw   $0x1,0x16(%eax)
    iupdate(dp);
  104914:	89 04 24             	mov    %eax,(%esp)
  104917:	e8 54 cb ff ff       	call   101470 <iupdate>
  10491c:	eb c7                	jmp    1048e5 <sys_unlink+0x175>
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
  10491e:	c7 04 24 bc 6b 10 00 	movl   $0x106bbc,(%esp)
  104925:	e8 f6 bf ff ff       	call   100920 <panic>
    return -1;
  }

  memset(&de, 0, sizeof(de));
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
    panic("unlink: writei");
  10492a:	c7 04 24 ce 6b 10 00 	movl   $0x106bce,(%esp)
  104931:	e8 ea bf ff ff       	call   100920 <panic>
    return -1;
  }
  ilock(ip);

  if(ip->nlink < 1)
    panic("unlink: nlink < 1");
  104936:	c7 04 24 aa 6b 10 00 	movl   $0x106baa,(%esp)
  10493d:	e8 de bf ff ff       	call   100920 <panic>
  104942:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  104949:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00104950 <T.67>:
#include "fcntl.h"

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
  104950:	55                   	push   %ebp
  104951:	89 e5                	mov    %esp,%ebp
  104953:	83 ec 28             	sub    $0x28,%esp
  104956:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  104959:	89 c3                	mov    %eax,%ebx
{
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
  10495b:	8d 45 f4             	lea    -0xc(%ebp),%eax
#include "fcntl.h"

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
  10495e:	89 75 fc             	mov    %esi,-0x4(%ebp)
  104961:	89 d6                	mov    %edx,%esi
{
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
  104963:	89 44 24 04          	mov    %eax,0x4(%esp)
  104967:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10496e:	e8 1d f5 ff ff       	call   103e90 <argint>
  104973:	85 c0                	test   %eax,%eax
  104975:	79 11                	jns    104988 <T.67+0x38>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
    return -1;
  if(pfd)
    *pfd = fd;
  if(pf)
    *pf = f;
  104977:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  return 0;
}
  10497c:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  10497f:	8b 75 fc             	mov    -0x4(%ebp),%esi
  104982:	89 ec                	mov    %ebp,%esp
  104984:	5d                   	pop    %ebp
  104985:	c3                   	ret    
  104986:	66 90                	xchg   %ax,%ax
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
  104988:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10498b:	83 f8 0f             	cmp    $0xf,%eax
  10498e:	77 e7                	ja     104977 <T.67+0x27>
  104990:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  104997:	8b 54 82 28          	mov    0x28(%edx,%eax,4),%edx
  10499b:	85 d2                	test   %edx,%edx
  10499d:	74 d8                	je     104977 <T.67+0x27>
    return -1;
  if(pfd)
  10499f:	85 db                	test   %ebx,%ebx
  1049a1:	74 02                	je     1049a5 <T.67+0x55>
    *pfd = fd;
  1049a3:	89 03                	mov    %eax,(%ebx)
  if(pf)
  1049a5:	31 c0                	xor    %eax,%eax
  1049a7:	85 f6                	test   %esi,%esi
  1049a9:	74 d1                	je     10497c <T.67+0x2c>
    *pf = f;
  1049ab:	89 16                	mov    %edx,(%esi)
  1049ad:	eb cd                	jmp    10497c <T.67+0x2c>
  1049af:	90                   	nop

001049b0 <sys_dup>:
  return -1;
}

int
sys_dup(void)
{
  1049b0:	55                   	push   %ebp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
  1049b1:	31 c0                	xor    %eax,%eax
  return -1;
}

int
sys_dup(void)
{
  1049b3:	89 e5                	mov    %esp,%ebp
  1049b5:	53                   	push   %ebx
  1049b6:	83 ec 24             	sub    $0x24,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
  1049b9:	8d 55 f4             	lea    -0xc(%ebp),%edx
  1049bc:	e8 8f ff ff ff       	call   104950 <T.67>
  1049c1:	85 c0                	test   %eax,%eax
  1049c3:	79 13                	jns    1049d8 <sys_dup+0x28>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
  1049c5:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
    return -1;
  if((fd=fdalloc(f)) < 0)
    return -1;
  filedup(f);
  return fd;
}
  1049ca:	89 d8                	mov    %ebx,%eax
  1049cc:	83 c4 24             	add    $0x24,%esp
  1049cf:	5b                   	pop    %ebx
  1049d0:	5d                   	pop    %ebp
  1049d1:	c3                   	ret    
  1049d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
    return -1;
  if((fd=fdalloc(f)) < 0)
  1049d8:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1049db:	31 db                	xor    %ebx,%ebx
  1049dd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1049e3:	eb 0b                	jmp    1049f0 <sys_dup+0x40>
  1049e5:	8d 76 00             	lea    0x0(%esi),%esi
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
  1049e8:	83 c3 01             	add    $0x1,%ebx
  1049eb:	83 fb 10             	cmp    $0x10,%ebx
  1049ee:	74 d5                	je     1049c5 <sys_dup+0x15>
    if(proc->ofile[fd] == 0){
  1049f0:	8b 4c 98 28          	mov    0x28(%eax,%ebx,4),%ecx
  1049f4:	85 c9                	test   %ecx,%ecx
  1049f6:	75 f0                	jne    1049e8 <sys_dup+0x38>
      proc->ofile[fd] = f;
  1049f8:	89 54 98 28          	mov    %edx,0x28(%eax,%ebx,4)
  
  if(argfd(0, 0, &f) < 0)
    return -1;
  if((fd=fdalloc(f)) < 0)
    return -1;
  filedup(f);
  1049fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1049ff:	89 04 24             	mov    %eax,(%esp)
  104a02:	e8 a9 c4 ff ff       	call   100eb0 <filedup>
  return fd;
  104a07:	eb c1                	jmp    1049ca <sys_dup+0x1a>
  104a09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00104a10 <sys_read>:
}

int
sys_read(void)
{
  104a10:	55                   	push   %ebp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
  104a11:	31 c0                	xor    %eax,%eax
  return fd;
}

int
sys_read(void)
{
  104a13:	89 e5                	mov    %esp,%ebp
  104a15:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
  104a18:	8d 55 f4             	lea    -0xc(%ebp),%edx
  104a1b:	e8 30 ff ff ff       	call   104950 <T.67>
  104a20:	85 c0                	test   %eax,%eax
  104a22:	79 0c                	jns    104a30 <sys_read+0x20>
    return -1;
  return fileread(f, p, n);
  104a24:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  104a29:	c9                   	leave  
  104a2a:	c3                   	ret    
  104a2b:	90                   	nop
  104a2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
{
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
  104a30:	8d 45 f0             	lea    -0x10(%ebp),%eax
  104a33:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a37:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  104a3e:	e8 4d f4 ff ff       	call   103e90 <argint>
  104a43:	85 c0                	test   %eax,%eax
  104a45:	78 dd                	js     104a24 <sys_read+0x14>
  104a47:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104a4a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104a51:	89 44 24 08          	mov    %eax,0x8(%esp)
  104a55:	8d 45 ec             	lea    -0x14(%ebp),%eax
  104a58:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a5c:	e8 6f f4 ff ff       	call   103ed0 <argptr>
  104a61:	85 c0                	test   %eax,%eax
  104a63:	78 bf                	js     104a24 <sys_read+0x14>
    return -1;
  return fileread(f, p, n);
  104a65:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104a68:	89 44 24 08          	mov    %eax,0x8(%esp)
  104a6c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104a6f:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a73:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104a76:	89 04 24             	mov    %eax,(%esp)
  104a79:	e8 32 c3 ff ff       	call   100db0 <fileread>
}
  104a7e:	c9                   	leave  
  104a7f:	c3                   	ret    

00104a80 <sys_write>:

int
sys_write(void)
{
  104a80:	55                   	push   %ebp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
  104a81:	31 c0                	xor    %eax,%eax
  return fileread(f, p, n);
}

int
sys_write(void)
{
  104a83:	89 e5                	mov    %esp,%ebp
  104a85:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
  104a88:	8d 55 f4             	lea    -0xc(%ebp),%edx
  104a8b:	e8 c0 fe ff ff       	call   104950 <T.67>
  104a90:	85 c0                	test   %eax,%eax
  104a92:	79 0c                	jns    104aa0 <sys_write+0x20>
    return -1;
  return filewrite(f, p, n);
  104a94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  104a99:	c9                   	leave  
  104a9a:	c3                   	ret    
  104a9b:	90                   	nop
  104a9c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
{
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
  104aa0:	8d 45 f0             	lea    -0x10(%ebp),%eax
  104aa3:	89 44 24 04          	mov    %eax,0x4(%esp)
  104aa7:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  104aae:	e8 dd f3 ff ff       	call   103e90 <argint>
  104ab3:	85 c0                	test   %eax,%eax
  104ab5:	78 dd                	js     104a94 <sys_write+0x14>
  104ab7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104aba:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104ac1:	89 44 24 08          	mov    %eax,0x8(%esp)
  104ac5:	8d 45 ec             	lea    -0x14(%ebp),%eax
  104ac8:	89 44 24 04          	mov    %eax,0x4(%esp)
  104acc:	e8 ff f3 ff ff       	call   103ed0 <argptr>
  104ad1:	85 c0                	test   %eax,%eax
  104ad3:	78 bf                	js     104a94 <sys_write+0x14>
    return -1;
  return filewrite(f, p, n);
  104ad5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104ad8:	89 44 24 08          	mov    %eax,0x8(%esp)
  104adc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104adf:	89 44 24 04          	mov    %eax,0x4(%esp)
  104ae3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104ae6:	89 04 24             	mov    %eax,(%esp)
  104ae9:	e8 12 c2 ff ff       	call   100d00 <filewrite>
}
  104aee:	c9                   	leave  
  104aef:	c3                   	ret    

00104af0 <sys_fstat>:
  return 0;
}

int
sys_fstat(void)
{
  104af0:	55                   	push   %ebp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
  104af1:	31 c0                	xor    %eax,%eax
  return 0;
}

int
sys_fstat(void)
{
  104af3:	89 e5                	mov    %esp,%ebp
  104af5:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
  104af8:	8d 55 f4             	lea    -0xc(%ebp),%edx
  104afb:	e8 50 fe ff ff       	call   104950 <T.67>
  104b00:	85 c0                	test   %eax,%eax
  104b02:	79 0c                	jns    104b10 <sys_fstat+0x20>
    return -1;
  return filestat(f, st);
  104b04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  104b09:	c9                   	leave  
  104b0a:	c3                   	ret    
  104b0b:	90                   	nop
  104b0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
sys_fstat(void)
{
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
  104b10:	8d 45 f0             	lea    -0x10(%ebp),%eax
  104b13:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
  104b1a:	00 
  104b1b:	89 44 24 04          	mov    %eax,0x4(%esp)
  104b1f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104b26:	e8 a5 f3 ff ff       	call   103ed0 <argptr>
  104b2b:	85 c0                	test   %eax,%eax
  104b2d:	78 d5                	js     104b04 <sys_fstat+0x14>
    return -1;
  return filestat(f, st);
  104b2f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104b32:	89 44 24 04          	mov    %eax,0x4(%esp)
  104b36:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104b39:	89 04 24             	mov    %eax,(%esp)
  104b3c:	e8 1f c3 ff ff       	call   100e60 <filestat>
}
  104b41:	c9                   	leave  
  104b42:	c3                   	ret    
  104b43:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  104b49:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00104b50 <sys_close>:
  return filewrite(f, p, n);
}

int
sys_close(void)
{
  104b50:	55                   	push   %ebp
  104b51:	89 e5                	mov    %esp,%ebp
  104b53:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
  104b56:	8d 55 f0             	lea    -0x10(%ebp),%edx
  104b59:	8d 45 f4             	lea    -0xc(%ebp),%eax
  104b5c:	e8 ef fd ff ff       	call   104950 <T.67>
  104b61:	89 c2                	mov    %eax,%edx
  104b63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  104b68:	85 d2                	test   %edx,%edx
  104b6a:	78 1e                	js     104b8a <sys_close+0x3a>
    return -1;
  proc->ofile[fd] = 0;
  104b6c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104b72:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104b75:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
  104b7c:	00 
  fileclose(f);
  104b7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104b80:	89 04 24             	mov    %eax,(%esp)
  104b83:	e8 f8 c3 ff ff       	call   100f80 <fileclose>
  104b88:	31 c0                	xor    %eax,%eax
  return 0;
}
  104b8a:	c9                   	leave  
  104b8b:	c3                   	ret    
  104b8c:	90                   	nop
  104b8d:	90                   	nop
  104b8e:	90                   	nop
  104b8f:	90                   	nop

00104b90 <sys_getpid>:
}

int
sys_getpid(void)
{
  return proc->pid;
  104b90:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  return kill(pid);
}

int
sys_getpid(void)
{
  104b96:	55                   	push   %ebp
  104b97:	89 e5                	mov    %esp,%ebp
  return proc->pid;
}
  104b99:	5d                   	pop    %ebp
}

int
sys_getpid(void)
{
  return proc->pid;
  104b9a:	8b 40 10             	mov    0x10(%eax),%eax
}
  104b9d:	c3                   	ret    
  104b9e:	66 90                	xchg   %ax,%ax

00104ba0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since boot.
int
sys_uptime(void)
{
  104ba0:	55                   	push   %ebp
  104ba1:	89 e5                	mov    %esp,%ebp
  104ba3:	53                   	push   %ebx
  104ba4:	83 ec 14             	sub    $0x14,%esp
  uint xticks;
  
  acquire(&tickslock);
  104ba7:	c7 04 24 c0 e0 10 00 	movl   $0x10e0c0,(%esp)
  104bae:	e8 9d ef ff ff       	call   103b50 <acquire>
  xticks = ticks;
  104bb3:	8b 1d 00 e9 10 00    	mov    0x10e900,%ebx
  release(&tickslock);
  104bb9:	c7 04 24 c0 e0 10 00 	movl   $0x10e0c0,(%esp)
  104bc0:	e8 3b ef ff ff       	call   103b00 <release>
  return xticks;
}
  104bc5:	83 c4 14             	add    $0x14,%esp
  104bc8:	89 d8                	mov    %ebx,%eax
  104bca:	5b                   	pop    %ebx
  104bcb:	5d                   	pop    %ebp
  104bcc:	c3                   	ret    
  104bcd:	8d 76 00             	lea    0x0(%esi),%esi

00104bd0 <sys_sleep>:
  return addr;
}

int
sys_sleep(void)
{
  104bd0:	55                   	push   %ebp
  104bd1:	89 e5                	mov    %esp,%ebp
  104bd3:	53                   	push   %ebx
  104bd4:	83 ec 24             	sub    $0x24,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
  104bd7:	8d 45 f4             	lea    -0xc(%ebp),%eax
  104bda:	89 44 24 04          	mov    %eax,0x4(%esp)
  104bde:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104be5:	e8 a6 f2 ff ff       	call   103e90 <argint>
  104bea:	89 c2                	mov    %eax,%edx
  104bec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  104bf1:	85 d2                	test   %edx,%edx
  104bf3:	78 59                	js     104c4e <sys_sleep+0x7e>
    return -1;
  acquire(&tickslock);
  104bf5:	c7 04 24 c0 e0 10 00 	movl   $0x10e0c0,(%esp)
  104bfc:	e8 4f ef ff ff       	call   103b50 <acquire>
  ticks0 = ticks;
  while(ticks - ticks0 < n){
  104c01:	8b 55 f4             	mov    -0xc(%ebp),%edx
  uint ticks0;
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  104c04:	8b 1d 00 e9 10 00    	mov    0x10e900,%ebx
  while(ticks - ticks0 < n){
  104c0a:	85 d2                	test   %edx,%edx
  104c0c:	75 22                	jne    104c30 <sys_sleep+0x60>
  104c0e:	eb 48                	jmp    104c58 <sys_sleep+0x88>
    if(proc->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  104c10:	c7 44 24 04 c0 e0 10 	movl   $0x10e0c0,0x4(%esp)
  104c17:	00 
  104c18:	c7 04 24 00 e9 10 00 	movl   $0x10e900,(%esp)
  104c1f:	e8 4c e6 ff ff       	call   103270 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
  104c24:	a1 00 e9 10 00       	mov    0x10e900,%eax
  104c29:	29 d8                	sub    %ebx,%eax
  104c2b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  104c2e:	73 28                	jae    104c58 <sys_sleep+0x88>
    if(proc->killed){
  104c30:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104c36:	8b 40 24             	mov    0x24(%eax),%eax
  104c39:	85 c0                	test   %eax,%eax
  104c3b:	74 d3                	je     104c10 <sys_sleep+0x40>
      release(&tickslock);
  104c3d:	c7 04 24 c0 e0 10 00 	movl   $0x10e0c0,(%esp)
  104c44:	e8 b7 ee ff ff       	call   103b00 <release>
  104c49:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}
  104c4e:	83 c4 24             	add    $0x24,%esp
  104c51:	5b                   	pop    %ebx
  104c52:	5d                   	pop    %ebp
  104c53:	c3                   	ret    
  104c54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  104c58:	c7 04 24 c0 e0 10 00 	movl   $0x10e0c0,(%esp)
  104c5f:	e8 9c ee ff ff       	call   103b00 <release>
  return 0;
}
  104c64:	83 c4 24             	add    $0x24,%esp
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  104c67:	31 c0                	xor    %eax,%eax
  return 0;
}
  104c69:	5b                   	pop    %ebx
  104c6a:	5d                   	pop    %ebp
  104c6b:	c3                   	ret    
  104c6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00104c70 <sys_sbrk>:
  return proc->pid;
}

int
sys_sbrk(void)
{
  104c70:	55                   	push   %ebp
  104c71:	89 e5                	mov    %esp,%ebp
  104c73:	53                   	push   %ebx
  104c74:	83 ec 24             	sub    $0x24,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
  104c77:	8d 45 f4             	lea    -0xc(%ebp),%eax
  104c7a:	89 44 24 04          	mov    %eax,0x4(%esp)
  104c7e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104c85:	e8 06 f2 ff ff       	call   103e90 <argint>
  104c8a:	85 c0                	test   %eax,%eax
  104c8c:	79 12                	jns    104ca0 <sys_sbrk+0x30>
    return -1;
  addr = proc->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
  104c8e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  104c93:	83 c4 24             	add    $0x24,%esp
  104c96:	5b                   	pop    %ebx
  104c97:	5d                   	pop    %ebp
  104c98:	c3                   	ret    
  104c99:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = proc->sz;
  104ca0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104ca6:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
  104ca8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104cab:	89 04 24             	mov    %eax,(%esp)
  104cae:	e8 7d eb ff ff       	call   103830 <growproc>
  104cb3:	89 c2                	mov    %eax,%edx
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = proc->sz;
  104cb5:	89 d8                	mov    %ebx,%eax
  if(growproc(n) < 0)
  104cb7:	85 d2                	test   %edx,%edx
  104cb9:	79 d8                	jns    104c93 <sys_sbrk+0x23>
  104cbb:	eb d1                	jmp    104c8e <sys_sbrk+0x1e>
  104cbd:	8d 76 00             	lea    0x0(%esi),%esi

00104cc0 <sys_kill>:
  return wait();
}

int
sys_kill(void)
{
  104cc0:	55                   	push   %ebp
  104cc1:	89 e5                	mov    %esp,%ebp
  104cc3:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
  104cc6:	8d 45 f4             	lea    -0xc(%ebp),%eax
  104cc9:	89 44 24 04          	mov    %eax,0x4(%esp)
  104ccd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104cd4:	e8 b7 f1 ff ff       	call   103e90 <argint>
  104cd9:	89 c2                	mov    %eax,%edx
  104cdb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  104ce0:	85 d2                	test   %edx,%edx
  104ce2:	78 0b                	js     104cef <sys_kill+0x2f>
    return -1;
  return kill(pid);
  104ce4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104ce7:	89 04 24             	mov    %eax,(%esp)
  104cea:	e8 d1 e3 ff ff       	call   1030c0 <kill>
}
  104cef:	c9                   	leave  
  104cf0:	c3                   	ret    
  104cf1:	eb 0d                	jmp    104d00 <sys_wait>
  104cf3:	90                   	nop
  104cf4:	90                   	nop
  104cf5:	90                   	nop
  104cf6:	90                   	nop
  104cf7:	90                   	nop
  104cf8:	90                   	nop
  104cf9:	90                   	nop
  104cfa:	90                   	nop
  104cfb:	90                   	nop
  104cfc:	90                   	nop
  104cfd:	90                   	nop
  104cfe:	90                   	nop
  104cff:	90                   	nop

00104d00 <sys_wait>:
  return 0;  // not reached
}

int
sys_wait(void)
{
  104d00:	55                   	push   %ebp
  104d01:	89 e5                	mov    %esp,%ebp
  104d03:	83 ec 08             	sub    $0x8,%esp
  return wait();
}
  104d06:	c9                   	leave  
}

int
sys_wait(void)
{
  return wait();
  104d07:	e9 14 e7 ff ff       	jmp    103420 <wait>
  104d0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00104d10 <sys_exit>:
  return fork();
}

int
sys_exit(void)
{
  104d10:	55                   	push   %ebp
  104d11:	89 e5                	mov    %esp,%ebp
  104d13:	83 ec 08             	sub    $0x8,%esp
  exit();
  104d16:	e8 05 e8 ff ff       	call   103520 <exit>
  return 0;  // not reached
}
  104d1b:	31 c0                	xor    %eax,%eax
  104d1d:	c9                   	leave  
  104d1e:	c3                   	ret    
  104d1f:	90                   	nop

00104d20 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
  104d20:	55                   	push   %ebp
  104d21:	89 e5                	mov    %esp,%ebp
  104d23:	83 ec 08             	sub    $0x8,%esp
  return fork();
}
  104d26:	c9                   	leave  
#include "proc.h"

int
sys_fork(void)
{
  return fork();
  104d27:	e9 04 ea ff ff       	jmp    103730 <fork>
  104d2c:	90                   	nop
  104d2d:	90                   	nop
  104d2e:	90                   	nop
  104d2f:	90                   	nop

00104d30 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
  104d30:	55                   	push   %ebp
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  104d31:	ba 43 00 00 00       	mov    $0x43,%edx
  104d36:	89 e5                	mov    %esp,%ebp
  104d38:	83 ec 18             	sub    $0x18,%esp
  104d3b:	b8 34 00 00 00       	mov    $0x34,%eax
  104d40:	ee                   	out    %al,(%dx)
  104d41:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
  104d46:	b2 40                	mov    $0x40,%dl
  104d48:	ee                   	out    %al,(%dx)
  104d49:	b8 2e 00 00 00       	mov    $0x2e,%eax
  104d4e:	ee                   	out    %al,(%dx)
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
  picenable(IRQ_TIMER);
  104d4f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104d56:	e8 55 de ff ff       	call   102bb0 <picenable>
}
  104d5b:	c9                   	leave  
  104d5c:	c3                   	ret    
  104d5d:	90                   	nop
  104d5e:	90                   	nop
  104d5f:	90                   	nop

00104d60 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
  104d60:	1e                   	push   %ds
  pushl %es
  104d61:	06                   	push   %es
  pushl %fs
  104d62:	0f a0                	push   %fs
  pushl %gs
  104d64:	0f a8                	push   %gs
  pushal
  104d66:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
  104d67:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
  104d6b:	8e d8                	mov    %eax,%ds
  movw %ax, %es
  104d6d:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
  104d6f:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
  104d73:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
  104d75:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
  104d77:	54                   	push   %esp
  call trap
  104d78:	e8 43 00 00 00       	call   104dc0 <trap>
  addl $4, %esp
  104d7d:	83 c4 04             	add    $0x4,%esp

00104d80 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
  104d80:	61                   	popa   
  popl %gs
  104d81:	0f a9                	pop    %gs
  popl %fs
  104d83:	0f a1                	pop    %fs
  popl %es
  104d85:	07                   	pop    %es
  popl %ds
  104d86:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
  104d87:	83 c4 08             	add    $0x8,%esp
  iret
  104d8a:	cf                   	iret   
  104d8b:	90                   	nop
  104d8c:	90                   	nop
  104d8d:	90                   	nop
  104d8e:	90                   	nop
  104d8f:	90                   	nop

00104d90 <idtinit>:
  initlock(&tickslock, "time");
}

void
idtinit(void)
{
  104d90:	55                   	push   %ebp
lidt(struct gatedesc *p, int size)
{
  volatile ushort pd[3];

  pd[0] = size-1;
  pd[1] = (uint)p;
  104d91:	b8 00 e1 10 00       	mov    $0x10e100,%eax
  104d96:	89 e5                	mov    %esp,%ebp
  104d98:	83 ec 10             	sub    $0x10,%esp
static inline void
lidt(struct gatedesc *p, int size)
{
  volatile ushort pd[3];

  pd[0] = size-1;
  104d9b:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
  104da1:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
  104da5:	c1 e8 10             	shr    $0x10,%eax
  104da8:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
  104dac:	8d 45 fa             	lea    -0x6(%ebp),%eax
  104daf:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
  104db2:	c9                   	leave  
  104db3:	c3                   	ret    
  104db4:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  104dba:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

00104dc0 <trap>:

void
trap(struct trapframe *tf)
{
  104dc0:	55                   	push   %ebp
  104dc1:	89 e5                	mov    %esp,%ebp
  104dc3:	56                   	push   %esi
  104dc4:	53                   	push   %ebx
  104dc5:	83 ec 20             	sub    $0x20,%esp
  104dc8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
  104dcb:	8b 43 30             	mov    0x30(%ebx),%eax
  104dce:	83 f8 40             	cmp    $0x40,%eax
  104dd1:	0f 84 c9 00 00 00    	je     104ea0 <trap+0xe0>
    if(proc->killed)
      exit();
    return;
  }

  switch(tf->trapno){
  104dd7:	8d 50 e0             	lea    -0x20(%eax),%edx
  104dda:	83 fa 1f             	cmp    $0x1f,%edx
  104ddd:	0f 86 b5 00 00 00    	jbe    104e98 <trap+0xd8>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
    break;
   
  default:
    if(proc == 0 || (tf->cs&3) == 0){
  104de3:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  104dea:	85 d2                	test   %edx,%edx
  104dec:	0f 84 f6 01 00 00    	je     104fe8 <trap+0x228>
  104df2:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
  104df6:	0f 84 ec 01 00 00    	je     104fe8 <trap+0x228>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
  104dfc:	0f 20 d6             	mov    %cr2,%esi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
  104dff:	8b 4a 10             	mov    0x10(%edx),%ecx
  104e02:	83 c2 6c             	add    $0x6c,%edx
  104e05:	89 74 24 1c          	mov    %esi,0x1c(%esp)
  104e09:	8b 73 38             	mov    0x38(%ebx),%esi
  104e0c:	89 74 24 18          	mov    %esi,0x18(%esp)
  104e10:	65 8b 35 00 00 00 00 	mov    %gs:0x0,%esi
  104e17:	0f b6 36             	movzbl (%esi),%esi
  104e1a:	89 74 24 14          	mov    %esi,0x14(%esp)
  104e1e:	8b 73 34             	mov    0x34(%ebx),%esi
  104e21:	89 44 24 0c          	mov    %eax,0xc(%esp)
  104e25:	89 54 24 08          	mov    %edx,0x8(%esp)
  104e29:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  104e2d:	89 74 24 10          	mov    %esi,0x10(%esp)
  104e31:	c7 04 24 38 6c 10 00 	movl   $0x106c38,(%esp)
  104e38:	e8 f3 b6 ff ff       	call   100530 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
  104e3d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104e43:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
  104e4a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
  104e50:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104e56:	85 c0                	test   %eax,%eax
  104e58:	74 34                	je     104e8e <trap+0xce>
  104e5a:	8b 50 24             	mov    0x24(%eax),%edx
  104e5d:	85 d2                	test   %edx,%edx
  104e5f:	74 10                	je     104e71 <trap+0xb1>
  104e61:	0f b7 53 3c          	movzwl 0x3c(%ebx),%edx
  104e65:	83 e2 03             	and    $0x3,%edx
  104e68:	83 fa 03             	cmp    $0x3,%edx
  104e6b:	0f 84 5f 01 00 00    	je     104fd0 <trap+0x210>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
  104e71:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
  104e75:	0f 84 2d 01 00 00    	je     104fa8 <trap+0x1e8>
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
  104e7b:	8b 40 24             	mov    0x24(%eax),%eax
  104e7e:	85 c0                	test   %eax,%eax
  104e80:	74 0c                	je     104e8e <trap+0xce>
  104e82:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
  104e86:	83 e0 03             	and    $0x3,%eax
  104e89:	83 f8 03             	cmp    $0x3,%eax
  104e8c:	74 34                	je     104ec2 <trap+0x102>
    exit();
}
  104e8e:	83 c4 20             	add    $0x20,%esp
  104e91:	5b                   	pop    %ebx
  104e92:	5e                   	pop    %esi
  104e93:	5d                   	pop    %ebp
  104e94:	c3                   	ret    
  104e95:	8d 76 00             	lea    0x0(%esi),%esi
    if(proc->killed)
      exit();
    return;
  }

  switch(tf->trapno){
  104e98:	ff 24 95 88 6c 10 00 	jmp    *0x106c88(,%edx,4)
  104e9f:	90                   	nop

void
trap(struct trapframe *tf)
{
  if(tf->trapno == T_SYSCALL){
    if(proc->killed)
  104ea0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104ea6:	8b 70 24             	mov    0x24(%eax),%esi
  104ea9:	85 f6                	test   %esi,%esi
  104eab:	75 23                	jne    104ed0 <trap+0x110>
      exit();
    proc->tf = tf;
  104ead:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
  104eb0:	e8 1b f1 ff ff       	call   103fd0 <syscall>
    if(proc->killed)
  104eb5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104ebb:	8b 48 24             	mov    0x24(%eax),%ecx
  104ebe:	85 c9                	test   %ecx,%ecx
  104ec0:	74 cc                	je     104e8e <trap+0xce>
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
  104ec2:	83 c4 20             	add    $0x20,%esp
  104ec5:	5b                   	pop    %ebx
  104ec6:	5e                   	pop    %esi
  104ec7:	5d                   	pop    %ebp
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
  104ec8:	e9 53 e6 ff ff       	jmp    103520 <exit>
  104ecd:	8d 76 00             	lea    0x0(%esi),%esi
void
trap(struct trapframe *tf)
{
  if(tf->trapno == T_SYSCALL){
    if(proc->killed)
      exit();
  104ed0:	e8 4b e6 ff ff       	call   103520 <exit>
  104ed5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104edb:	eb d0                	jmp    104ead <trap+0xed>
  104edd:	8d 76 00             	lea    0x0(%esi),%esi
      release(&tickslock);
    }
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE:
    ideintr();
  104ee0:	e8 2b d1 ff ff       	call   102010 <ideintr>
    lapiceoi();
  104ee5:	e8 66 d5 ff ff       	call   102450 <lapiceoi>
    break;
  104eea:	e9 61 ff ff ff       	jmp    104e50 <trap+0x90>
  104eef:	90                   	nop
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
  104ef0:	8b 43 38             	mov    0x38(%ebx),%eax
  104ef3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  104ef7:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
  104efb:	89 44 24 08          	mov    %eax,0x8(%esp)
  104eff:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  104f05:	0f b6 00             	movzbl (%eax),%eax
  104f08:	c7 04 24 e0 6b 10 00 	movl   $0x106be0,(%esp)
  104f0f:	89 44 24 04          	mov    %eax,0x4(%esp)
  104f13:	e8 18 b6 ff ff       	call   100530 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
  104f18:	e8 33 d5 ff ff       	call   102450 <lapiceoi>
    break;
  104f1d:	e9 2e ff ff ff       	jmp    104e50 <trap+0x90>
  104f22:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  104f28:	90                   	nop
  104f29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_COM1:
    uartintr();
  104f30:	e8 ab 01 00 00       	call   1050e0 <uartintr>
  104f35:	8d 76 00             	lea    0x0(%esi),%esi
    lapiceoi();
  104f38:	e8 13 d5 ff ff       	call   102450 <lapiceoi>
  104f3d:	8d 76 00             	lea    0x0(%esi),%esi
    break;
  104f40:	e9 0b ff ff ff       	jmp    104e50 <trap+0x90>
  104f45:	8d 76 00             	lea    0x0(%esi),%esi
  104f48:	90                   	nop
  104f49:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
  104f50:	e8 db d4 ff ff       	call   102430 <kbdintr>
  104f55:	8d 76 00             	lea    0x0(%esi),%esi
    lapiceoi();
  104f58:	e8 f3 d4 ff ff       	call   102450 <lapiceoi>
  104f5d:	8d 76 00             	lea    0x0(%esi),%esi
    break;
  104f60:	e9 eb fe ff ff       	jmp    104e50 <trap+0x90>
  104f65:	8d 76 00             	lea    0x0(%esi),%esi
    return;
  }

  switch(tf->trapno){
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
  104f68:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  104f6e:	80 38 00             	cmpb   $0x0,(%eax)
  104f71:	0f 85 6e ff ff ff    	jne    104ee5 <trap+0x125>
      acquire(&tickslock);
  104f77:	c7 04 24 c0 e0 10 00 	movl   $0x10e0c0,(%esp)
  104f7e:	e8 cd eb ff ff       	call   103b50 <acquire>
      ticks++;
  104f83:	83 05 00 e9 10 00 01 	addl   $0x1,0x10e900
      wakeup(&ticks);
  104f8a:	c7 04 24 00 e9 10 00 	movl   $0x10e900,(%esp)
  104f91:	e8 ba e1 ff ff       	call   103150 <wakeup>
      release(&tickslock);
  104f96:	c7 04 24 c0 e0 10 00 	movl   $0x10e0c0,(%esp)
  104f9d:	e8 5e eb ff ff       	call   103b00 <release>
  104fa2:	e9 3e ff ff ff       	jmp    104ee5 <trap+0x125>
  104fa7:	90                   	nop
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
  104fa8:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
  104fac:	0f 85 c9 fe ff ff    	jne    104e7b <trap+0xbb>
  104fb2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    yield();
  104fb8:	e8 83 e3 ff ff       	call   103340 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
  104fbd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104fc3:	85 c0                	test   %eax,%eax
  104fc5:	0f 85 b0 fe ff ff    	jne    104e7b <trap+0xbb>
  104fcb:	e9 be fe ff ff       	jmp    104e8e <trap+0xce>

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
  104fd0:	e8 4b e5 ff ff       	call   103520 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
  104fd5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104fdb:	85 c0                	test   %eax,%eax
  104fdd:	0f 85 8e fe ff ff    	jne    104e71 <trap+0xb1>
  104fe3:	e9 a6 fe ff ff       	jmp    104e8e <trap+0xce>
  104fe8:	0f 20 d2             	mov    %cr2,%edx
    break;
   
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
  104feb:	89 54 24 10          	mov    %edx,0x10(%esp)
  104fef:	8b 53 38             	mov    0x38(%ebx),%edx
  104ff2:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104ff6:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
  104ffd:	0f b6 12             	movzbl (%edx),%edx
  105000:	89 44 24 04          	mov    %eax,0x4(%esp)
  105004:	c7 04 24 04 6c 10 00 	movl   $0x106c04,(%esp)
  10500b:	89 54 24 08          	mov    %edx,0x8(%esp)
  10500f:	e8 1c b5 ff ff       	call   100530 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
  105014:	c7 04 24 7b 6c 10 00 	movl   $0x106c7b,(%esp)
  10501b:	e8 00 b9 ff ff       	call   100920 <panic>

00105020 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
  105020:	55                   	push   %ebp
  105021:	31 c0                	xor    %eax,%eax
  105023:	89 e5                	mov    %esp,%ebp
  105025:	ba 00 e1 10 00       	mov    $0x10e100,%edx
  10502a:	83 ec 18             	sub    $0x18,%esp
  10502d:	8d 76 00             	lea    0x0(%esi),%esi
  int i;

  for(i = 0; i < 256; i++)
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  105030:	8b 0c 85 28 73 10 00 	mov    0x107328(,%eax,4),%ecx
  105037:	66 89 0c c5 00 e1 10 	mov    %cx,0x10e100(,%eax,8)
  10503e:	00 
  10503f:	c1 e9 10             	shr    $0x10,%ecx
  105042:	66 c7 44 c2 02 08 00 	movw   $0x8,0x2(%edx,%eax,8)
  105049:	c6 44 c2 04 00       	movb   $0x0,0x4(%edx,%eax,8)
  10504e:	c6 44 c2 05 8e       	movb   $0x8e,0x5(%edx,%eax,8)
  105053:	66 89 4c c2 06       	mov    %cx,0x6(%edx,%eax,8)
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
  105058:	83 c0 01             	add    $0x1,%eax
  10505b:	3d 00 01 00 00       	cmp    $0x100,%eax
  105060:	75 ce                	jne    105030 <tvinit+0x10>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
  105062:	a1 28 74 10 00       	mov    0x107428,%eax
  
  initlock(&tickslock, "time");
  105067:	c7 44 24 04 80 6c 10 	movl   $0x106c80,0x4(%esp)
  10506e:	00 
  10506f:	c7 04 24 c0 e0 10 00 	movl   $0x10e0c0,(%esp)
{
  int i;

  for(i = 0; i < 256; i++)
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
  105076:	66 c7 05 02 e3 10 00 	movw   $0x8,0x10e302
  10507d:	08 00 
  10507f:	66 a3 00 e3 10 00    	mov    %ax,0x10e300
  105085:	c1 e8 10             	shr    $0x10,%eax
  105088:	c6 05 04 e3 10 00 00 	movb   $0x0,0x10e304
  10508f:	c6 05 05 e3 10 00 ef 	movb   $0xef,0x10e305
  105096:	66 a3 06 e3 10 00    	mov    %ax,0x10e306
  
  initlock(&tickslock, "time");
  10509c:	e8 1f e9 ff ff       	call   1039c0 <initlock>
}
  1050a1:	c9                   	leave  
  1050a2:	c3                   	ret    
  1050a3:	90                   	nop
  1050a4:	90                   	nop
  1050a5:	90                   	nop
  1050a6:	90                   	nop
  1050a7:	90                   	nop
  1050a8:	90                   	nop
  1050a9:	90                   	nop
  1050aa:	90                   	nop
  1050ab:	90                   	nop
  1050ac:	90                   	nop
  1050ad:	90                   	nop
  1050ae:	90                   	nop
  1050af:	90                   	nop

001050b0 <uartgetc>:
}

static int
uartgetc(void)
{
  if(!uart)
  1050b0:	a1 cc 78 10 00       	mov    0x1078cc,%eax
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
  1050b5:	55                   	push   %ebp
  1050b6:	89 e5                	mov    %esp,%ebp
  if(!uart)
  1050b8:	85 c0                	test   %eax,%eax
  1050ba:	75 0c                	jne    1050c8 <uartgetc+0x18>
    return -1;
  if(!(inb(COM1+5) & 0x01))
    return -1;
  return inb(COM1+0);
  1050bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  1050c1:	5d                   	pop    %ebp
  1050c2:	c3                   	ret    
  1050c3:	90                   	nop
  1050c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  1050c8:	ba fd 03 00 00       	mov    $0x3fd,%edx
  1050cd:	ec                   	in     (%dx),%al
static int
uartgetc(void)
{
  if(!uart)
    return -1;
  if(!(inb(COM1+5) & 0x01))
  1050ce:	a8 01                	test   $0x1,%al
  1050d0:	74 ea                	je     1050bc <uartgetc+0xc>
  1050d2:	b2 f8                	mov    $0xf8,%dl
  1050d4:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
  1050d5:	0f b6 c0             	movzbl %al,%eax
}
  1050d8:	5d                   	pop    %ebp
  1050d9:	c3                   	ret    
  1050da:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

001050e0 <uartintr>:

void
uartintr(void)
{
  1050e0:	55                   	push   %ebp
  1050e1:	89 e5                	mov    %esp,%ebp
  1050e3:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
  1050e6:	c7 04 24 b0 50 10 00 	movl   $0x1050b0,(%esp)
  1050ed:	e8 9e b6 ff ff       	call   100790 <consoleintr>
}
  1050f2:	c9                   	leave  
  1050f3:	c3                   	ret    
  1050f4:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1050fa:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

00105100 <uartputc>:
    uartputc(*p);
}

void
uartputc(int c)
{
  105100:	55                   	push   %ebp
  105101:	89 e5                	mov    %esp,%ebp
  105103:	56                   	push   %esi
  105104:	be fd 03 00 00       	mov    $0x3fd,%esi
  105109:	53                   	push   %ebx
  int i;

  if(!uart)
  10510a:	31 db                	xor    %ebx,%ebx
    uartputc(*p);
}

void
uartputc(int c)
{
  10510c:	83 ec 10             	sub    $0x10,%esp
  int i;

  if(!uart)
  10510f:	8b 15 cc 78 10 00    	mov    0x1078cc,%edx
  105115:	85 d2                	test   %edx,%edx
  105117:	75 1e                	jne    105137 <uartputc+0x37>
  105119:	eb 2c                	jmp    105147 <uartputc+0x47>
  10511b:	90                   	nop
  10511c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
  105120:	83 c3 01             	add    $0x1,%ebx
    microdelay(10);
  105123:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
  10512a:	e8 41 d3 ff ff       	call   102470 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
  10512f:	81 fb 80 00 00 00    	cmp    $0x80,%ebx
  105135:	74 07                	je     10513e <uartputc+0x3e>
  105137:	89 f2                	mov    %esi,%edx
  105139:	ec                   	in     (%dx),%al
  10513a:	a8 20                	test   $0x20,%al
  10513c:	74 e2                	je     105120 <uartputc+0x20>
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  10513e:	ba f8 03 00 00       	mov    $0x3f8,%edx
  105143:	8b 45 08             	mov    0x8(%ebp),%eax
  105146:	ee                   	out    %al,(%dx)
    microdelay(10);
  outb(COM1+0, c);
}
  105147:	83 c4 10             	add    $0x10,%esp
  10514a:	5b                   	pop    %ebx
  10514b:	5e                   	pop    %esi
  10514c:	5d                   	pop    %ebp
  10514d:	c3                   	ret    
  10514e:	66 90                	xchg   %ax,%ax

00105150 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
  105150:	55                   	push   %ebp
  105151:	31 c9                	xor    %ecx,%ecx
  105153:	89 e5                	mov    %esp,%ebp
  105155:	89 c8                	mov    %ecx,%eax
  105157:	57                   	push   %edi
  105158:	bf fa 03 00 00       	mov    $0x3fa,%edi
  10515d:	56                   	push   %esi
  10515e:	89 fa                	mov    %edi,%edx
  105160:	53                   	push   %ebx
  105161:	83 ec 1c             	sub    $0x1c,%esp
  105164:	ee                   	out    %al,(%dx)
  105165:	bb fb 03 00 00       	mov    $0x3fb,%ebx
  10516a:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
  10516f:	89 da                	mov    %ebx,%edx
  105171:	ee                   	out    %al,(%dx)
  105172:	b8 0c 00 00 00       	mov    $0xc,%eax
  105177:	b2 f8                	mov    $0xf8,%dl
  105179:	ee                   	out    %al,(%dx)
  10517a:	be f9 03 00 00       	mov    $0x3f9,%esi
  10517f:	89 c8                	mov    %ecx,%eax
  105181:	89 f2                	mov    %esi,%edx
  105183:	ee                   	out    %al,(%dx)
  105184:	b8 03 00 00 00       	mov    $0x3,%eax
  105189:	89 da                	mov    %ebx,%edx
  10518b:	ee                   	out    %al,(%dx)
  10518c:	b2 fc                	mov    $0xfc,%dl
  10518e:	89 c8                	mov    %ecx,%eax
  105190:	ee                   	out    %al,(%dx)
  105191:	b8 01 00 00 00       	mov    $0x1,%eax
  105196:	89 f2                	mov    %esi,%edx
  105198:	ee                   	out    %al,(%dx)
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  105199:	b2 fd                	mov    $0xfd,%dl
  10519b:	ec                   	in     (%dx),%al
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
  10519c:	3c ff                	cmp    $0xff,%al
  10519e:	74 55                	je     1051f5 <uartinit+0xa5>
    return;
  uart = 1;
  1051a0:	c7 05 cc 78 10 00 01 	movl   $0x1,0x1078cc
  1051a7:	00 00 00 
  1051aa:	89 fa                	mov    %edi,%edx
  1051ac:	ec                   	in     (%dx),%al
  1051ad:	b2 f8                	mov    $0xf8,%dl
  1051af:	ec                   	in     (%dx),%al
  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  1051b0:	bb 08 6d 10 00       	mov    $0x106d08,%ebx

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
  inb(COM1+0);
  picenable(IRQ_COM1);
  1051b5:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  1051bc:	e8 ef d9 ff ff       	call   102bb0 <picenable>
  ioapicenable(IRQ_COM1, 0);
  1051c1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1051c8:	00 
  1051c9:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  1051d0:	e8 6b cf ff ff       	call   102140 <ioapicenable>
  1051d5:	b8 78 00 00 00       	mov    $0x78,%eax
  1051da:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
  1051e0:	0f be c0             	movsbl %al,%eax
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
  1051e3:	83 c3 01             	add    $0x1,%ebx
    uartputc(*p);
  1051e6:	89 04 24             	mov    %eax,(%esp)
  1051e9:	e8 12 ff ff ff       	call   105100 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
  1051ee:	0f b6 03             	movzbl (%ebx),%eax
  1051f1:	84 c0                	test   %al,%al
  1051f3:	75 eb                	jne    1051e0 <uartinit+0x90>
    uartputc(*p);
}
  1051f5:	83 c4 1c             	add    $0x1c,%esp
  1051f8:	5b                   	pop    %ebx
  1051f9:	5e                   	pop    %esi
  1051fa:	5f                   	pop    %edi
  1051fb:	5d                   	pop    %ebp
  1051fc:	c3                   	ret    
  1051fd:	90                   	nop
  1051fe:	90                   	nop
  1051ff:	90                   	nop

00105200 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
  105200:	6a 00                	push   $0x0
  pushl $0
  105202:	6a 00                	push   $0x0
  jmp alltraps
  105204:	e9 57 fb ff ff       	jmp    104d60 <alltraps>

00105209 <vector1>:
.globl vector1
vector1:
  pushl $0
  105209:	6a 00                	push   $0x0
  pushl $1
  10520b:	6a 01                	push   $0x1
  jmp alltraps
  10520d:	e9 4e fb ff ff       	jmp    104d60 <alltraps>

00105212 <vector2>:
.globl vector2
vector2:
  pushl $0
  105212:	6a 00                	push   $0x0
  pushl $2
  105214:	6a 02                	push   $0x2
  jmp alltraps
  105216:	e9 45 fb ff ff       	jmp    104d60 <alltraps>

0010521b <vector3>:
.globl vector3
vector3:
  pushl $0
  10521b:	6a 00                	push   $0x0
  pushl $3
  10521d:	6a 03                	push   $0x3
  jmp alltraps
  10521f:	e9 3c fb ff ff       	jmp    104d60 <alltraps>

00105224 <vector4>:
.globl vector4
vector4:
  pushl $0
  105224:	6a 00                	push   $0x0
  pushl $4
  105226:	6a 04                	push   $0x4
  jmp alltraps
  105228:	e9 33 fb ff ff       	jmp    104d60 <alltraps>

0010522d <vector5>:
.globl vector5
vector5:
  pushl $0
  10522d:	6a 00                	push   $0x0
  pushl $5
  10522f:	6a 05                	push   $0x5
  jmp alltraps
  105231:	e9 2a fb ff ff       	jmp    104d60 <alltraps>

00105236 <vector6>:
.globl vector6
vector6:
  pushl $0
  105236:	6a 00                	push   $0x0
  pushl $6
  105238:	6a 06                	push   $0x6
  jmp alltraps
  10523a:	e9 21 fb ff ff       	jmp    104d60 <alltraps>

0010523f <vector7>:
.globl vector7
vector7:
  pushl $0
  10523f:	6a 00                	push   $0x0
  pushl $7
  105241:	6a 07                	push   $0x7
  jmp alltraps
  105243:	e9 18 fb ff ff       	jmp    104d60 <alltraps>

00105248 <vector8>:
.globl vector8
vector8:
  pushl $8
  105248:	6a 08                	push   $0x8
  jmp alltraps
  10524a:	e9 11 fb ff ff       	jmp    104d60 <alltraps>

0010524f <vector9>:
.globl vector9
vector9:
  pushl $0
  10524f:	6a 00                	push   $0x0
  pushl $9
  105251:	6a 09                	push   $0x9
  jmp alltraps
  105253:	e9 08 fb ff ff       	jmp    104d60 <alltraps>

00105258 <vector10>:
.globl vector10
vector10:
  pushl $10
  105258:	6a 0a                	push   $0xa
  jmp alltraps
  10525a:	e9 01 fb ff ff       	jmp    104d60 <alltraps>

0010525f <vector11>:
.globl vector11
vector11:
  pushl $11
  10525f:	6a 0b                	push   $0xb
  jmp alltraps
  105261:	e9 fa fa ff ff       	jmp    104d60 <alltraps>

00105266 <vector12>:
.globl vector12
vector12:
  pushl $12
  105266:	6a 0c                	push   $0xc
  jmp alltraps
  105268:	e9 f3 fa ff ff       	jmp    104d60 <alltraps>

0010526d <vector13>:
.globl vector13
vector13:
  pushl $13
  10526d:	6a 0d                	push   $0xd
  jmp alltraps
  10526f:	e9 ec fa ff ff       	jmp    104d60 <alltraps>

00105274 <vector14>:
.globl vector14
vector14:
  pushl $14
  105274:	6a 0e                	push   $0xe
  jmp alltraps
  105276:	e9 e5 fa ff ff       	jmp    104d60 <alltraps>

0010527b <vector15>:
.globl vector15
vector15:
  pushl $0
  10527b:	6a 00                	push   $0x0
  pushl $15
  10527d:	6a 0f                	push   $0xf
  jmp alltraps
  10527f:	e9 dc fa ff ff       	jmp    104d60 <alltraps>

00105284 <vector16>:
.globl vector16
vector16:
  pushl $0
  105284:	6a 00                	push   $0x0
  pushl $16
  105286:	6a 10                	push   $0x10
  jmp alltraps
  105288:	e9 d3 fa ff ff       	jmp    104d60 <alltraps>

0010528d <vector17>:
.globl vector17
vector17:
  pushl $17
  10528d:	6a 11                	push   $0x11
  jmp alltraps
  10528f:	e9 cc fa ff ff       	jmp    104d60 <alltraps>

00105294 <vector18>:
.globl vector18
vector18:
  pushl $0
  105294:	6a 00                	push   $0x0
  pushl $18
  105296:	6a 12                	push   $0x12
  jmp alltraps
  105298:	e9 c3 fa ff ff       	jmp    104d60 <alltraps>

0010529d <vector19>:
.globl vector19
vector19:
  pushl $0
  10529d:	6a 00                	push   $0x0
  pushl $19
  10529f:	6a 13                	push   $0x13
  jmp alltraps
  1052a1:	e9 ba fa ff ff       	jmp    104d60 <alltraps>

001052a6 <vector20>:
.globl vector20
vector20:
  pushl $0
  1052a6:	6a 00                	push   $0x0
  pushl $20
  1052a8:	6a 14                	push   $0x14
  jmp alltraps
  1052aa:	e9 b1 fa ff ff       	jmp    104d60 <alltraps>

001052af <vector21>:
.globl vector21
vector21:
  pushl $0
  1052af:	6a 00                	push   $0x0
  pushl $21
  1052b1:	6a 15                	push   $0x15
  jmp alltraps
  1052b3:	e9 a8 fa ff ff       	jmp    104d60 <alltraps>

001052b8 <vector22>:
.globl vector22
vector22:
  pushl $0
  1052b8:	6a 00                	push   $0x0
  pushl $22
  1052ba:	6a 16                	push   $0x16
  jmp alltraps
  1052bc:	e9 9f fa ff ff       	jmp    104d60 <alltraps>

001052c1 <vector23>:
.globl vector23
vector23:
  pushl $0
  1052c1:	6a 00                	push   $0x0
  pushl $23
  1052c3:	6a 17                	push   $0x17
  jmp alltraps
  1052c5:	e9 96 fa ff ff       	jmp    104d60 <alltraps>

001052ca <vector24>:
.globl vector24
vector24:
  pushl $0
  1052ca:	6a 00                	push   $0x0
  pushl $24
  1052cc:	6a 18                	push   $0x18
  jmp alltraps
  1052ce:	e9 8d fa ff ff       	jmp    104d60 <alltraps>

001052d3 <vector25>:
.globl vector25
vector25:
  pushl $0
  1052d3:	6a 00                	push   $0x0
  pushl $25
  1052d5:	6a 19                	push   $0x19
  jmp alltraps
  1052d7:	e9 84 fa ff ff       	jmp    104d60 <alltraps>

001052dc <vector26>:
.globl vector26
vector26:
  pushl $0
  1052dc:	6a 00                	push   $0x0
  pushl $26
  1052de:	6a 1a                	push   $0x1a
  jmp alltraps
  1052e0:	e9 7b fa ff ff       	jmp    104d60 <alltraps>

001052e5 <vector27>:
.globl vector27
vector27:
  pushl $0
  1052e5:	6a 00                	push   $0x0
  pushl $27
  1052e7:	6a 1b                	push   $0x1b
  jmp alltraps
  1052e9:	e9 72 fa ff ff       	jmp    104d60 <alltraps>

001052ee <vector28>:
.globl vector28
vector28:
  pushl $0
  1052ee:	6a 00                	push   $0x0
  pushl $28
  1052f0:	6a 1c                	push   $0x1c
  jmp alltraps
  1052f2:	e9 69 fa ff ff       	jmp    104d60 <alltraps>

001052f7 <vector29>:
.globl vector29
vector29:
  pushl $0
  1052f7:	6a 00                	push   $0x0
  pushl $29
  1052f9:	6a 1d                	push   $0x1d
  jmp alltraps
  1052fb:	e9 60 fa ff ff       	jmp    104d60 <alltraps>

00105300 <vector30>:
.globl vector30
vector30:
  pushl $0
  105300:	6a 00                	push   $0x0
  pushl $30
  105302:	6a 1e                	push   $0x1e
  jmp alltraps
  105304:	e9 57 fa ff ff       	jmp    104d60 <alltraps>

00105309 <vector31>:
.globl vector31
vector31:
  pushl $0
  105309:	6a 00                	push   $0x0
  pushl $31
  10530b:	6a 1f                	push   $0x1f
  jmp alltraps
  10530d:	e9 4e fa ff ff       	jmp    104d60 <alltraps>

00105312 <vector32>:
.globl vector32
vector32:
  pushl $0
  105312:	6a 00                	push   $0x0
  pushl $32
  105314:	6a 20                	push   $0x20
  jmp alltraps
  105316:	e9 45 fa ff ff       	jmp    104d60 <alltraps>

0010531b <vector33>:
.globl vector33
vector33:
  pushl $0
  10531b:	6a 00                	push   $0x0
  pushl $33
  10531d:	6a 21                	push   $0x21
  jmp alltraps
  10531f:	e9 3c fa ff ff       	jmp    104d60 <alltraps>

00105324 <vector34>:
.globl vector34
vector34:
  pushl $0
  105324:	6a 00                	push   $0x0
  pushl $34
  105326:	6a 22                	push   $0x22
  jmp alltraps
  105328:	e9 33 fa ff ff       	jmp    104d60 <alltraps>

0010532d <vector35>:
.globl vector35
vector35:
  pushl $0
  10532d:	6a 00                	push   $0x0
  pushl $35
  10532f:	6a 23                	push   $0x23
  jmp alltraps
  105331:	e9 2a fa ff ff       	jmp    104d60 <alltraps>

00105336 <vector36>:
.globl vector36
vector36:
  pushl $0
  105336:	6a 00                	push   $0x0
  pushl $36
  105338:	6a 24                	push   $0x24
  jmp alltraps
  10533a:	e9 21 fa ff ff       	jmp    104d60 <alltraps>

0010533f <vector37>:
.globl vector37
vector37:
  pushl $0
  10533f:	6a 00                	push   $0x0
  pushl $37
  105341:	6a 25                	push   $0x25
  jmp alltraps
  105343:	e9 18 fa ff ff       	jmp    104d60 <alltraps>

00105348 <vector38>:
.globl vector38
vector38:
  pushl $0
  105348:	6a 00                	push   $0x0
  pushl $38
  10534a:	6a 26                	push   $0x26
  jmp alltraps
  10534c:	e9 0f fa ff ff       	jmp    104d60 <alltraps>

00105351 <vector39>:
.globl vector39
vector39:
  pushl $0
  105351:	6a 00                	push   $0x0
  pushl $39
  105353:	6a 27                	push   $0x27
  jmp alltraps
  105355:	e9 06 fa ff ff       	jmp    104d60 <alltraps>

0010535a <vector40>:
.globl vector40
vector40:
  pushl $0
  10535a:	6a 00                	push   $0x0
  pushl $40
  10535c:	6a 28                	push   $0x28
  jmp alltraps
  10535e:	e9 fd f9 ff ff       	jmp    104d60 <alltraps>

00105363 <vector41>:
.globl vector41
vector41:
  pushl $0
  105363:	6a 00                	push   $0x0
  pushl $41
  105365:	6a 29                	push   $0x29
  jmp alltraps
  105367:	e9 f4 f9 ff ff       	jmp    104d60 <alltraps>

0010536c <vector42>:
.globl vector42
vector42:
  pushl $0
  10536c:	6a 00                	push   $0x0
  pushl $42
  10536e:	6a 2a                	push   $0x2a
  jmp alltraps
  105370:	e9 eb f9 ff ff       	jmp    104d60 <alltraps>

00105375 <vector43>:
.globl vector43
vector43:
  pushl $0
  105375:	6a 00                	push   $0x0
  pushl $43
  105377:	6a 2b                	push   $0x2b
  jmp alltraps
  105379:	e9 e2 f9 ff ff       	jmp    104d60 <alltraps>

0010537e <vector44>:
.globl vector44
vector44:
  pushl $0
  10537e:	6a 00                	push   $0x0
  pushl $44
  105380:	6a 2c                	push   $0x2c
  jmp alltraps
  105382:	e9 d9 f9 ff ff       	jmp    104d60 <alltraps>

00105387 <vector45>:
.globl vector45
vector45:
  pushl $0
  105387:	6a 00                	push   $0x0
  pushl $45
  105389:	6a 2d                	push   $0x2d
  jmp alltraps
  10538b:	e9 d0 f9 ff ff       	jmp    104d60 <alltraps>

00105390 <vector46>:
.globl vector46
vector46:
  pushl $0
  105390:	6a 00                	push   $0x0
  pushl $46
  105392:	6a 2e                	push   $0x2e
  jmp alltraps
  105394:	e9 c7 f9 ff ff       	jmp    104d60 <alltraps>

00105399 <vector47>:
.globl vector47
vector47:
  pushl $0
  105399:	6a 00                	push   $0x0
  pushl $47
  10539b:	6a 2f                	push   $0x2f
  jmp alltraps
  10539d:	e9 be f9 ff ff       	jmp    104d60 <alltraps>

001053a2 <vector48>:
.globl vector48
vector48:
  pushl $0
  1053a2:	6a 00                	push   $0x0
  pushl $48
  1053a4:	6a 30                	push   $0x30
  jmp alltraps
  1053a6:	e9 b5 f9 ff ff       	jmp    104d60 <alltraps>

001053ab <vector49>:
.globl vector49
vector49:
  pushl $0
  1053ab:	6a 00                	push   $0x0
  pushl $49
  1053ad:	6a 31                	push   $0x31
  jmp alltraps
  1053af:	e9 ac f9 ff ff       	jmp    104d60 <alltraps>

001053b4 <vector50>:
.globl vector50
vector50:
  pushl $0
  1053b4:	6a 00                	push   $0x0
  pushl $50
  1053b6:	6a 32                	push   $0x32
  jmp alltraps
  1053b8:	e9 a3 f9 ff ff       	jmp    104d60 <alltraps>

001053bd <vector51>:
.globl vector51
vector51:
  pushl $0
  1053bd:	6a 00                	push   $0x0
  pushl $51
  1053bf:	6a 33                	push   $0x33
  jmp alltraps
  1053c1:	e9 9a f9 ff ff       	jmp    104d60 <alltraps>

001053c6 <vector52>:
.globl vector52
vector52:
  pushl $0
  1053c6:	6a 00                	push   $0x0
  pushl $52
  1053c8:	6a 34                	push   $0x34
  jmp alltraps
  1053ca:	e9 91 f9 ff ff       	jmp    104d60 <alltraps>

001053cf <vector53>:
.globl vector53
vector53:
  pushl $0
  1053cf:	6a 00                	push   $0x0
  pushl $53
  1053d1:	6a 35                	push   $0x35
  jmp alltraps
  1053d3:	e9 88 f9 ff ff       	jmp    104d60 <alltraps>

001053d8 <vector54>:
.globl vector54
vector54:
  pushl $0
  1053d8:	6a 00                	push   $0x0
  pushl $54
  1053da:	6a 36                	push   $0x36
  jmp alltraps
  1053dc:	e9 7f f9 ff ff       	jmp    104d60 <alltraps>

001053e1 <vector55>:
.globl vector55
vector55:
  pushl $0
  1053e1:	6a 00                	push   $0x0
  pushl $55
  1053e3:	6a 37                	push   $0x37
  jmp alltraps
  1053e5:	e9 76 f9 ff ff       	jmp    104d60 <alltraps>

001053ea <vector56>:
.globl vector56
vector56:
  pushl $0
  1053ea:	6a 00                	push   $0x0
  pushl $56
  1053ec:	6a 38                	push   $0x38
  jmp alltraps
  1053ee:	e9 6d f9 ff ff       	jmp    104d60 <alltraps>

001053f3 <vector57>:
.globl vector57
vector57:
  pushl $0
  1053f3:	6a 00                	push   $0x0
  pushl $57
  1053f5:	6a 39                	push   $0x39
  jmp alltraps
  1053f7:	e9 64 f9 ff ff       	jmp    104d60 <alltraps>

001053fc <vector58>:
.globl vector58
vector58:
  pushl $0
  1053fc:	6a 00                	push   $0x0
  pushl $58
  1053fe:	6a 3a                	push   $0x3a
  jmp alltraps
  105400:	e9 5b f9 ff ff       	jmp    104d60 <alltraps>

00105405 <vector59>:
.globl vector59
vector59:
  pushl $0
  105405:	6a 00                	push   $0x0
  pushl $59
  105407:	6a 3b                	push   $0x3b
  jmp alltraps
  105409:	e9 52 f9 ff ff       	jmp    104d60 <alltraps>

0010540e <vector60>:
.globl vector60
vector60:
  pushl $0
  10540e:	6a 00                	push   $0x0
  pushl $60
  105410:	6a 3c                	push   $0x3c
  jmp alltraps
  105412:	e9 49 f9 ff ff       	jmp    104d60 <alltraps>

00105417 <vector61>:
.globl vector61
vector61:
  pushl $0
  105417:	6a 00                	push   $0x0
  pushl $61
  105419:	6a 3d                	push   $0x3d
  jmp alltraps
  10541b:	e9 40 f9 ff ff       	jmp    104d60 <alltraps>

00105420 <vector62>:
.globl vector62
vector62:
  pushl $0
  105420:	6a 00                	push   $0x0
  pushl $62
  105422:	6a 3e                	push   $0x3e
  jmp alltraps
  105424:	e9 37 f9 ff ff       	jmp    104d60 <alltraps>

00105429 <vector63>:
.globl vector63
vector63:
  pushl $0
  105429:	6a 00                	push   $0x0
  pushl $63
  10542b:	6a 3f                	push   $0x3f
  jmp alltraps
  10542d:	e9 2e f9 ff ff       	jmp    104d60 <alltraps>

00105432 <vector64>:
.globl vector64
vector64:
  pushl $0
  105432:	6a 00                	push   $0x0
  pushl $64
  105434:	6a 40                	push   $0x40
  jmp alltraps
  105436:	e9 25 f9 ff ff       	jmp    104d60 <alltraps>

0010543b <vector65>:
.globl vector65
vector65:
  pushl $0
  10543b:	6a 00                	push   $0x0
  pushl $65
  10543d:	6a 41                	push   $0x41
  jmp alltraps
  10543f:	e9 1c f9 ff ff       	jmp    104d60 <alltraps>

00105444 <vector66>:
.globl vector66
vector66:
  pushl $0
  105444:	6a 00                	push   $0x0
  pushl $66
  105446:	6a 42                	push   $0x42
  jmp alltraps
  105448:	e9 13 f9 ff ff       	jmp    104d60 <alltraps>

0010544d <vector67>:
.globl vector67
vector67:
  pushl $0
  10544d:	6a 00                	push   $0x0
  pushl $67
  10544f:	6a 43                	push   $0x43
  jmp alltraps
  105451:	e9 0a f9 ff ff       	jmp    104d60 <alltraps>

00105456 <vector68>:
.globl vector68
vector68:
  pushl $0
  105456:	6a 00                	push   $0x0
  pushl $68
  105458:	6a 44                	push   $0x44
  jmp alltraps
  10545a:	e9 01 f9 ff ff       	jmp    104d60 <alltraps>

0010545f <vector69>:
.globl vector69
vector69:
  pushl $0
  10545f:	6a 00                	push   $0x0
  pushl $69
  105461:	6a 45                	push   $0x45
  jmp alltraps
  105463:	e9 f8 f8 ff ff       	jmp    104d60 <alltraps>

00105468 <vector70>:
.globl vector70
vector70:
  pushl $0
  105468:	6a 00                	push   $0x0
  pushl $70
  10546a:	6a 46                	push   $0x46
  jmp alltraps
  10546c:	e9 ef f8 ff ff       	jmp    104d60 <alltraps>

00105471 <vector71>:
.globl vector71
vector71:
  pushl $0
  105471:	6a 00                	push   $0x0
  pushl $71
  105473:	6a 47                	push   $0x47
  jmp alltraps
  105475:	e9 e6 f8 ff ff       	jmp    104d60 <alltraps>

0010547a <vector72>:
.globl vector72
vector72:
  pushl $0
  10547a:	6a 00                	push   $0x0
  pushl $72
  10547c:	6a 48                	push   $0x48
  jmp alltraps
  10547e:	e9 dd f8 ff ff       	jmp    104d60 <alltraps>

00105483 <vector73>:
.globl vector73
vector73:
  pushl $0
  105483:	6a 00                	push   $0x0
  pushl $73
  105485:	6a 49                	push   $0x49
  jmp alltraps
  105487:	e9 d4 f8 ff ff       	jmp    104d60 <alltraps>

0010548c <vector74>:
.globl vector74
vector74:
  pushl $0
  10548c:	6a 00                	push   $0x0
  pushl $74
  10548e:	6a 4a                	push   $0x4a
  jmp alltraps
  105490:	e9 cb f8 ff ff       	jmp    104d60 <alltraps>

00105495 <vector75>:
.globl vector75
vector75:
  pushl $0
  105495:	6a 00                	push   $0x0
  pushl $75
  105497:	6a 4b                	push   $0x4b
  jmp alltraps
  105499:	e9 c2 f8 ff ff       	jmp    104d60 <alltraps>

0010549e <vector76>:
.globl vector76
vector76:
  pushl $0
  10549e:	6a 00                	push   $0x0
  pushl $76
  1054a0:	6a 4c                	push   $0x4c
  jmp alltraps
  1054a2:	e9 b9 f8 ff ff       	jmp    104d60 <alltraps>

001054a7 <vector77>:
.globl vector77
vector77:
  pushl $0
  1054a7:	6a 00                	push   $0x0
  pushl $77
  1054a9:	6a 4d                	push   $0x4d
  jmp alltraps
  1054ab:	e9 b0 f8 ff ff       	jmp    104d60 <alltraps>

001054b0 <vector78>:
.globl vector78
vector78:
  pushl $0
  1054b0:	6a 00                	push   $0x0
  pushl $78
  1054b2:	6a 4e                	push   $0x4e
  jmp alltraps
  1054b4:	e9 a7 f8 ff ff       	jmp    104d60 <alltraps>

001054b9 <vector79>:
.globl vector79
vector79:
  pushl $0
  1054b9:	6a 00                	push   $0x0
  pushl $79
  1054bb:	6a 4f                	push   $0x4f
  jmp alltraps
  1054bd:	e9 9e f8 ff ff       	jmp    104d60 <alltraps>

001054c2 <vector80>:
.globl vector80
vector80:
  pushl $0
  1054c2:	6a 00                	push   $0x0
  pushl $80
  1054c4:	6a 50                	push   $0x50
  jmp alltraps
  1054c6:	e9 95 f8 ff ff       	jmp    104d60 <alltraps>

001054cb <vector81>:
.globl vector81
vector81:
  pushl $0
  1054cb:	6a 00                	push   $0x0
  pushl $81
  1054cd:	6a 51                	push   $0x51
  jmp alltraps
  1054cf:	e9 8c f8 ff ff       	jmp    104d60 <alltraps>

001054d4 <vector82>:
.globl vector82
vector82:
  pushl $0
  1054d4:	6a 00                	push   $0x0
  pushl $82
  1054d6:	6a 52                	push   $0x52
  jmp alltraps
  1054d8:	e9 83 f8 ff ff       	jmp    104d60 <alltraps>

001054dd <vector83>:
.globl vector83
vector83:
  pushl $0
  1054dd:	6a 00                	push   $0x0
  pushl $83
  1054df:	6a 53                	push   $0x53
  jmp alltraps
  1054e1:	e9 7a f8 ff ff       	jmp    104d60 <alltraps>

001054e6 <vector84>:
.globl vector84
vector84:
  pushl $0
  1054e6:	6a 00                	push   $0x0
  pushl $84
  1054e8:	6a 54                	push   $0x54
  jmp alltraps
  1054ea:	e9 71 f8 ff ff       	jmp    104d60 <alltraps>

001054ef <vector85>:
.globl vector85
vector85:
  pushl $0
  1054ef:	6a 00                	push   $0x0
  pushl $85
  1054f1:	6a 55                	push   $0x55
  jmp alltraps
  1054f3:	e9 68 f8 ff ff       	jmp    104d60 <alltraps>

001054f8 <vector86>:
.globl vector86
vector86:
  pushl $0
  1054f8:	6a 00                	push   $0x0
  pushl $86
  1054fa:	6a 56                	push   $0x56
  jmp alltraps
  1054fc:	e9 5f f8 ff ff       	jmp    104d60 <alltraps>

00105501 <vector87>:
.globl vector87
vector87:
  pushl $0
  105501:	6a 00                	push   $0x0
  pushl $87
  105503:	6a 57                	push   $0x57
  jmp alltraps
  105505:	e9 56 f8 ff ff       	jmp    104d60 <alltraps>

0010550a <vector88>:
.globl vector88
vector88:
  pushl $0
  10550a:	6a 00                	push   $0x0
  pushl $88
  10550c:	6a 58                	push   $0x58
  jmp alltraps
  10550e:	e9 4d f8 ff ff       	jmp    104d60 <alltraps>

00105513 <vector89>:
.globl vector89
vector89:
  pushl $0
  105513:	6a 00                	push   $0x0
  pushl $89
  105515:	6a 59                	push   $0x59
  jmp alltraps
  105517:	e9 44 f8 ff ff       	jmp    104d60 <alltraps>

0010551c <vector90>:
.globl vector90
vector90:
  pushl $0
  10551c:	6a 00                	push   $0x0
  pushl $90
  10551e:	6a 5a                	push   $0x5a
  jmp alltraps
  105520:	e9 3b f8 ff ff       	jmp    104d60 <alltraps>

00105525 <vector91>:
.globl vector91
vector91:
  pushl $0
  105525:	6a 00                	push   $0x0
  pushl $91
  105527:	6a 5b                	push   $0x5b
  jmp alltraps
  105529:	e9 32 f8 ff ff       	jmp    104d60 <alltraps>

0010552e <vector92>:
.globl vector92
vector92:
  pushl $0
  10552e:	6a 00                	push   $0x0
  pushl $92
  105530:	6a 5c                	push   $0x5c
  jmp alltraps
  105532:	e9 29 f8 ff ff       	jmp    104d60 <alltraps>

00105537 <vector93>:
.globl vector93
vector93:
  pushl $0
  105537:	6a 00                	push   $0x0
  pushl $93
  105539:	6a 5d                	push   $0x5d
  jmp alltraps
  10553b:	e9 20 f8 ff ff       	jmp    104d60 <alltraps>

00105540 <vector94>:
.globl vector94
vector94:
  pushl $0
  105540:	6a 00                	push   $0x0
  pushl $94
  105542:	6a 5e                	push   $0x5e
  jmp alltraps
  105544:	e9 17 f8 ff ff       	jmp    104d60 <alltraps>

00105549 <vector95>:
.globl vector95
vector95:
  pushl $0
  105549:	6a 00                	push   $0x0
  pushl $95
  10554b:	6a 5f                	push   $0x5f
  jmp alltraps
  10554d:	e9 0e f8 ff ff       	jmp    104d60 <alltraps>

00105552 <vector96>:
.globl vector96
vector96:
  pushl $0
  105552:	6a 00                	push   $0x0
  pushl $96
  105554:	6a 60                	push   $0x60
  jmp alltraps
  105556:	e9 05 f8 ff ff       	jmp    104d60 <alltraps>

0010555b <vector97>:
.globl vector97
vector97:
  pushl $0
  10555b:	6a 00                	push   $0x0
  pushl $97
  10555d:	6a 61                	push   $0x61
  jmp alltraps
  10555f:	e9 fc f7 ff ff       	jmp    104d60 <alltraps>

00105564 <vector98>:
.globl vector98
vector98:
  pushl $0
  105564:	6a 00                	push   $0x0
  pushl $98
  105566:	6a 62                	push   $0x62
  jmp alltraps
  105568:	e9 f3 f7 ff ff       	jmp    104d60 <alltraps>

0010556d <vector99>:
.globl vector99
vector99:
  pushl $0
  10556d:	6a 00                	push   $0x0
  pushl $99
  10556f:	6a 63                	push   $0x63
  jmp alltraps
  105571:	e9 ea f7 ff ff       	jmp    104d60 <alltraps>

00105576 <vector100>:
.globl vector100
vector100:
  pushl $0
  105576:	6a 00                	push   $0x0
  pushl $100
  105578:	6a 64                	push   $0x64
  jmp alltraps
  10557a:	e9 e1 f7 ff ff       	jmp    104d60 <alltraps>

0010557f <vector101>:
.globl vector101
vector101:
  pushl $0
  10557f:	6a 00                	push   $0x0
  pushl $101
  105581:	6a 65                	push   $0x65
  jmp alltraps
  105583:	e9 d8 f7 ff ff       	jmp    104d60 <alltraps>

00105588 <vector102>:
.globl vector102
vector102:
  pushl $0
  105588:	6a 00                	push   $0x0
  pushl $102
  10558a:	6a 66                	push   $0x66
  jmp alltraps
  10558c:	e9 cf f7 ff ff       	jmp    104d60 <alltraps>

00105591 <vector103>:
.globl vector103
vector103:
  pushl $0
  105591:	6a 00                	push   $0x0
  pushl $103
  105593:	6a 67                	push   $0x67
  jmp alltraps
  105595:	e9 c6 f7 ff ff       	jmp    104d60 <alltraps>

0010559a <vector104>:
.globl vector104
vector104:
  pushl $0
  10559a:	6a 00                	push   $0x0
  pushl $104
  10559c:	6a 68                	push   $0x68
  jmp alltraps
  10559e:	e9 bd f7 ff ff       	jmp    104d60 <alltraps>

001055a3 <vector105>:
.globl vector105
vector105:
  pushl $0
  1055a3:	6a 00                	push   $0x0
  pushl $105
  1055a5:	6a 69                	push   $0x69
  jmp alltraps
  1055a7:	e9 b4 f7 ff ff       	jmp    104d60 <alltraps>

001055ac <vector106>:
.globl vector106
vector106:
  pushl $0
  1055ac:	6a 00                	push   $0x0
  pushl $106
  1055ae:	6a 6a                	push   $0x6a
  jmp alltraps
  1055b0:	e9 ab f7 ff ff       	jmp    104d60 <alltraps>

001055b5 <vector107>:
.globl vector107
vector107:
  pushl $0
  1055b5:	6a 00                	push   $0x0
  pushl $107
  1055b7:	6a 6b                	push   $0x6b
  jmp alltraps
  1055b9:	e9 a2 f7 ff ff       	jmp    104d60 <alltraps>

001055be <vector108>:
.globl vector108
vector108:
  pushl $0
  1055be:	6a 00                	push   $0x0
  pushl $108
  1055c0:	6a 6c                	push   $0x6c
  jmp alltraps
  1055c2:	e9 99 f7 ff ff       	jmp    104d60 <alltraps>

001055c7 <vector109>:
.globl vector109
vector109:
  pushl $0
  1055c7:	6a 00                	push   $0x0
  pushl $109
  1055c9:	6a 6d                	push   $0x6d
  jmp alltraps
  1055cb:	e9 90 f7 ff ff       	jmp    104d60 <alltraps>

001055d0 <vector110>:
.globl vector110
vector110:
  pushl $0
  1055d0:	6a 00                	push   $0x0
  pushl $110
  1055d2:	6a 6e                	push   $0x6e
  jmp alltraps
  1055d4:	e9 87 f7 ff ff       	jmp    104d60 <alltraps>

001055d9 <vector111>:
.globl vector111
vector111:
  pushl $0
  1055d9:	6a 00                	push   $0x0
  pushl $111
  1055db:	6a 6f                	push   $0x6f
  jmp alltraps
  1055dd:	e9 7e f7 ff ff       	jmp    104d60 <alltraps>

001055e2 <vector112>:
.globl vector112
vector112:
  pushl $0
  1055e2:	6a 00                	push   $0x0
  pushl $112
  1055e4:	6a 70                	push   $0x70
  jmp alltraps
  1055e6:	e9 75 f7 ff ff       	jmp    104d60 <alltraps>

001055eb <vector113>:
.globl vector113
vector113:
  pushl $0
  1055eb:	6a 00                	push   $0x0
  pushl $113
  1055ed:	6a 71                	push   $0x71
  jmp alltraps
  1055ef:	e9 6c f7 ff ff       	jmp    104d60 <alltraps>

001055f4 <vector114>:
.globl vector114
vector114:
  pushl $0
  1055f4:	6a 00                	push   $0x0
  pushl $114
  1055f6:	6a 72                	push   $0x72
  jmp alltraps
  1055f8:	e9 63 f7 ff ff       	jmp    104d60 <alltraps>

001055fd <vector115>:
.globl vector115
vector115:
  pushl $0
  1055fd:	6a 00                	push   $0x0
  pushl $115
  1055ff:	6a 73                	push   $0x73
  jmp alltraps
  105601:	e9 5a f7 ff ff       	jmp    104d60 <alltraps>

00105606 <vector116>:
.globl vector116
vector116:
  pushl $0
  105606:	6a 00                	push   $0x0
  pushl $116
  105608:	6a 74                	push   $0x74
  jmp alltraps
  10560a:	e9 51 f7 ff ff       	jmp    104d60 <alltraps>

0010560f <vector117>:
.globl vector117
vector117:
  pushl $0
  10560f:	6a 00                	push   $0x0
  pushl $117
  105611:	6a 75                	push   $0x75
  jmp alltraps
  105613:	e9 48 f7 ff ff       	jmp    104d60 <alltraps>

00105618 <vector118>:
.globl vector118
vector118:
  pushl $0
  105618:	6a 00                	push   $0x0
  pushl $118
  10561a:	6a 76                	push   $0x76
  jmp alltraps
  10561c:	e9 3f f7 ff ff       	jmp    104d60 <alltraps>

00105621 <vector119>:
.globl vector119
vector119:
  pushl $0
  105621:	6a 00                	push   $0x0
  pushl $119
  105623:	6a 77                	push   $0x77
  jmp alltraps
  105625:	e9 36 f7 ff ff       	jmp    104d60 <alltraps>

0010562a <vector120>:
.globl vector120
vector120:
  pushl $0
  10562a:	6a 00                	push   $0x0
  pushl $120
  10562c:	6a 78                	push   $0x78
  jmp alltraps
  10562e:	e9 2d f7 ff ff       	jmp    104d60 <alltraps>

00105633 <vector121>:
.globl vector121
vector121:
  pushl $0
  105633:	6a 00                	push   $0x0
  pushl $121
  105635:	6a 79                	push   $0x79
  jmp alltraps
  105637:	e9 24 f7 ff ff       	jmp    104d60 <alltraps>

0010563c <vector122>:
.globl vector122
vector122:
  pushl $0
  10563c:	6a 00                	push   $0x0
  pushl $122
  10563e:	6a 7a                	push   $0x7a
  jmp alltraps
  105640:	e9 1b f7 ff ff       	jmp    104d60 <alltraps>

00105645 <vector123>:
.globl vector123
vector123:
  pushl $0
  105645:	6a 00                	push   $0x0
  pushl $123
  105647:	6a 7b                	push   $0x7b
  jmp alltraps
  105649:	e9 12 f7 ff ff       	jmp    104d60 <alltraps>

0010564e <vector124>:
.globl vector124
vector124:
  pushl $0
  10564e:	6a 00                	push   $0x0
  pushl $124
  105650:	6a 7c                	push   $0x7c
  jmp alltraps
  105652:	e9 09 f7 ff ff       	jmp    104d60 <alltraps>

00105657 <vector125>:
.globl vector125
vector125:
  pushl $0
  105657:	6a 00                	push   $0x0
  pushl $125
  105659:	6a 7d                	push   $0x7d
  jmp alltraps
  10565b:	e9 00 f7 ff ff       	jmp    104d60 <alltraps>

00105660 <vector126>:
.globl vector126
vector126:
  pushl $0
  105660:	6a 00                	push   $0x0
  pushl $126
  105662:	6a 7e                	push   $0x7e
  jmp alltraps
  105664:	e9 f7 f6 ff ff       	jmp    104d60 <alltraps>

00105669 <vector127>:
.globl vector127
vector127:
  pushl $0
  105669:	6a 00                	push   $0x0
  pushl $127
  10566b:	6a 7f                	push   $0x7f
  jmp alltraps
  10566d:	e9 ee f6 ff ff       	jmp    104d60 <alltraps>

00105672 <vector128>:
.globl vector128
vector128:
  pushl $0
  105672:	6a 00                	push   $0x0
  pushl $128
  105674:	68 80 00 00 00       	push   $0x80
  jmp alltraps
  105679:	e9 e2 f6 ff ff       	jmp    104d60 <alltraps>

0010567e <vector129>:
.globl vector129
vector129:
  pushl $0
  10567e:	6a 00                	push   $0x0
  pushl $129
  105680:	68 81 00 00 00       	push   $0x81
  jmp alltraps
  105685:	e9 d6 f6 ff ff       	jmp    104d60 <alltraps>

0010568a <vector130>:
.globl vector130
vector130:
  pushl $0
  10568a:	6a 00                	push   $0x0
  pushl $130
  10568c:	68 82 00 00 00       	push   $0x82
  jmp alltraps
  105691:	e9 ca f6 ff ff       	jmp    104d60 <alltraps>

00105696 <vector131>:
.globl vector131
vector131:
  pushl $0
  105696:	6a 00                	push   $0x0
  pushl $131
  105698:	68 83 00 00 00       	push   $0x83
  jmp alltraps
  10569d:	e9 be f6 ff ff       	jmp    104d60 <alltraps>

001056a2 <vector132>:
.globl vector132
vector132:
  pushl $0
  1056a2:	6a 00                	push   $0x0
  pushl $132
  1056a4:	68 84 00 00 00       	push   $0x84
  jmp alltraps
  1056a9:	e9 b2 f6 ff ff       	jmp    104d60 <alltraps>

001056ae <vector133>:
.globl vector133
vector133:
  pushl $0
  1056ae:	6a 00                	push   $0x0
  pushl $133
  1056b0:	68 85 00 00 00       	push   $0x85
  jmp alltraps
  1056b5:	e9 a6 f6 ff ff       	jmp    104d60 <alltraps>

001056ba <vector134>:
.globl vector134
vector134:
  pushl $0
  1056ba:	6a 00                	push   $0x0
  pushl $134
  1056bc:	68 86 00 00 00       	push   $0x86
  jmp alltraps
  1056c1:	e9 9a f6 ff ff       	jmp    104d60 <alltraps>

001056c6 <vector135>:
.globl vector135
vector135:
  pushl $0
  1056c6:	6a 00                	push   $0x0
  pushl $135
  1056c8:	68 87 00 00 00       	push   $0x87
  jmp alltraps
  1056cd:	e9 8e f6 ff ff       	jmp    104d60 <alltraps>

001056d2 <vector136>:
.globl vector136
vector136:
  pushl $0
  1056d2:	6a 00                	push   $0x0
  pushl $136
  1056d4:	68 88 00 00 00       	push   $0x88
  jmp alltraps
  1056d9:	e9 82 f6 ff ff       	jmp    104d60 <alltraps>

001056de <vector137>:
.globl vector137
vector137:
  pushl $0
  1056de:	6a 00                	push   $0x0
  pushl $137
  1056e0:	68 89 00 00 00       	push   $0x89
  jmp alltraps
  1056e5:	e9 76 f6 ff ff       	jmp    104d60 <alltraps>

001056ea <vector138>:
.globl vector138
vector138:
  pushl $0
  1056ea:	6a 00                	push   $0x0
  pushl $138
  1056ec:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
  1056f1:	e9 6a f6 ff ff       	jmp    104d60 <alltraps>

001056f6 <vector139>:
.globl vector139
vector139:
  pushl $0
  1056f6:	6a 00                	push   $0x0
  pushl $139
  1056f8:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
  1056fd:	e9 5e f6 ff ff       	jmp    104d60 <alltraps>

00105702 <vector140>:
.globl vector140
vector140:
  pushl $0
  105702:	6a 00                	push   $0x0
  pushl $140
  105704:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
  105709:	e9 52 f6 ff ff       	jmp    104d60 <alltraps>

0010570e <vector141>:
.globl vector141
vector141:
  pushl $0
  10570e:	6a 00                	push   $0x0
  pushl $141
  105710:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
  105715:	e9 46 f6 ff ff       	jmp    104d60 <alltraps>

0010571a <vector142>:
.globl vector142
vector142:
  pushl $0
  10571a:	6a 00                	push   $0x0
  pushl $142
  10571c:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
  105721:	e9 3a f6 ff ff       	jmp    104d60 <alltraps>

00105726 <vector143>:
.globl vector143
vector143:
  pushl $0
  105726:	6a 00                	push   $0x0
  pushl $143
  105728:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
  10572d:	e9 2e f6 ff ff       	jmp    104d60 <alltraps>

00105732 <vector144>:
.globl vector144
vector144:
  pushl $0
  105732:	6a 00                	push   $0x0
  pushl $144
  105734:	68 90 00 00 00       	push   $0x90
  jmp alltraps
  105739:	e9 22 f6 ff ff       	jmp    104d60 <alltraps>

0010573e <vector145>:
.globl vector145
vector145:
  pushl $0
  10573e:	6a 00                	push   $0x0
  pushl $145
  105740:	68 91 00 00 00       	push   $0x91
  jmp alltraps
  105745:	e9 16 f6 ff ff       	jmp    104d60 <alltraps>

0010574a <vector146>:
.globl vector146
vector146:
  pushl $0
  10574a:	6a 00                	push   $0x0
  pushl $146
  10574c:	68 92 00 00 00       	push   $0x92
  jmp alltraps
  105751:	e9 0a f6 ff ff       	jmp    104d60 <alltraps>

00105756 <vector147>:
.globl vector147
vector147:
  pushl $0
  105756:	6a 00                	push   $0x0
  pushl $147
  105758:	68 93 00 00 00       	push   $0x93
  jmp alltraps
  10575d:	e9 fe f5 ff ff       	jmp    104d60 <alltraps>

00105762 <vector148>:
.globl vector148
vector148:
  pushl $0
  105762:	6a 00                	push   $0x0
  pushl $148
  105764:	68 94 00 00 00       	push   $0x94
  jmp alltraps
  105769:	e9 f2 f5 ff ff       	jmp    104d60 <alltraps>

0010576e <vector149>:
.globl vector149
vector149:
  pushl $0
  10576e:	6a 00                	push   $0x0
  pushl $149
  105770:	68 95 00 00 00       	push   $0x95
  jmp alltraps
  105775:	e9 e6 f5 ff ff       	jmp    104d60 <alltraps>

0010577a <vector150>:
.globl vector150
vector150:
  pushl $0
  10577a:	6a 00                	push   $0x0
  pushl $150
  10577c:	68 96 00 00 00       	push   $0x96
  jmp alltraps
  105781:	e9 da f5 ff ff       	jmp    104d60 <alltraps>

00105786 <vector151>:
.globl vector151
vector151:
  pushl $0
  105786:	6a 00                	push   $0x0
  pushl $151
  105788:	68 97 00 00 00       	push   $0x97
  jmp alltraps
  10578d:	e9 ce f5 ff ff       	jmp    104d60 <alltraps>

00105792 <vector152>:
.globl vector152
vector152:
  pushl $0
  105792:	6a 00                	push   $0x0
  pushl $152
  105794:	68 98 00 00 00       	push   $0x98
  jmp alltraps
  105799:	e9 c2 f5 ff ff       	jmp    104d60 <alltraps>

0010579e <vector153>:
.globl vector153
vector153:
  pushl $0
  10579e:	6a 00                	push   $0x0
  pushl $153
  1057a0:	68 99 00 00 00       	push   $0x99
  jmp alltraps
  1057a5:	e9 b6 f5 ff ff       	jmp    104d60 <alltraps>

001057aa <vector154>:
.globl vector154
vector154:
  pushl $0
  1057aa:	6a 00                	push   $0x0
  pushl $154
  1057ac:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
  1057b1:	e9 aa f5 ff ff       	jmp    104d60 <alltraps>

001057b6 <vector155>:
.globl vector155
vector155:
  pushl $0
  1057b6:	6a 00                	push   $0x0
  pushl $155
  1057b8:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
  1057bd:	e9 9e f5 ff ff       	jmp    104d60 <alltraps>

001057c2 <vector156>:
.globl vector156
vector156:
  pushl $0
  1057c2:	6a 00                	push   $0x0
  pushl $156
  1057c4:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
  1057c9:	e9 92 f5 ff ff       	jmp    104d60 <alltraps>

001057ce <vector157>:
.globl vector157
vector157:
  pushl $0
  1057ce:	6a 00                	push   $0x0
  pushl $157
  1057d0:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
  1057d5:	e9 86 f5 ff ff       	jmp    104d60 <alltraps>

001057da <vector158>:
.globl vector158
vector158:
  pushl $0
  1057da:	6a 00                	push   $0x0
  pushl $158
  1057dc:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
  1057e1:	e9 7a f5 ff ff       	jmp    104d60 <alltraps>

001057e6 <vector159>:
.globl vector159
vector159:
  pushl $0
  1057e6:	6a 00                	push   $0x0
  pushl $159
  1057e8:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
  1057ed:	e9 6e f5 ff ff       	jmp    104d60 <alltraps>

001057f2 <vector160>:
.globl vector160
vector160:
  pushl $0
  1057f2:	6a 00                	push   $0x0
  pushl $160
  1057f4:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
  1057f9:	e9 62 f5 ff ff       	jmp    104d60 <alltraps>

001057fe <vector161>:
.globl vector161
vector161:
  pushl $0
  1057fe:	6a 00                	push   $0x0
  pushl $161
  105800:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
  105805:	e9 56 f5 ff ff       	jmp    104d60 <alltraps>

0010580a <vector162>:
.globl vector162
vector162:
  pushl $0
  10580a:	6a 00                	push   $0x0
  pushl $162
  10580c:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
  105811:	e9 4a f5 ff ff       	jmp    104d60 <alltraps>

00105816 <vector163>:
.globl vector163
vector163:
  pushl $0
  105816:	6a 00                	push   $0x0
  pushl $163
  105818:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
  10581d:	e9 3e f5 ff ff       	jmp    104d60 <alltraps>

00105822 <vector164>:
.globl vector164
vector164:
  pushl $0
  105822:	6a 00                	push   $0x0
  pushl $164
  105824:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
  105829:	e9 32 f5 ff ff       	jmp    104d60 <alltraps>

0010582e <vector165>:
.globl vector165
vector165:
  pushl $0
  10582e:	6a 00                	push   $0x0
  pushl $165
  105830:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
  105835:	e9 26 f5 ff ff       	jmp    104d60 <alltraps>

0010583a <vector166>:
.globl vector166
vector166:
  pushl $0
  10583a:	6a 00                	push   $0x0
  pushl $166
  10583c:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
  105841:	e9 1a f5 ff ff       	jmp    104d60 <alltraps>

00105846 <vector167>:
.globl vector167
vector167:
  pushl $0
  105846:	6a 00                	push   $0x0
  pushl $167
  105848:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
  10584d:	e9 0e f5 ff ff       	jmp    104d60 <alltraps>

00105852 <vector168>:
.globl vector168
vector168:
  pushl $0
  105852:	6a 00                	push   $0x0
  pushl $168
  105854:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
  105859:	e9 02 f5 ff ff       	jmp    104d60 <alltraps>

0010585e <vector169>:
.globl vector169
vector169:
  pushl $0
  10585e:	6a 00                	push   $0x0
  pushl $169
  105860:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
  105865:	e9 f6 f4 ff ff       	jmp    104d60 <alltraps>

0010586a <vector170>:
.globl vector170
vector170:
  pushl $0
  10586a:	6a 00                	push   $0x0
  pushl $170
  10586c:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
  105871:	e9 ea f4 ff ff       	jmp    104d60 <alltraps>

00105876 <vector171>:
.globl vector171
vector171:
  pushl $0
  105876:	6a 00                	push   $0x0
  pushl $171
  105878:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
  10587d:	e9 de f4 ff ff       	jmp    104d60 <alltraps>

00105882 <vector172>:
.globl vector172
vector172:
  pushl $0
  105882:	6a 00                	push   $0x0
  pushl $172
  105884:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
  105889:	e9 d2 f4 ff ff       	jmp    104d60 <alltraps>

0010588e <vector173>:
.globl vector173
vector173:
  pushl $0
  10588e:	6a 00                	push   $0x0
  pushl $173
  105890:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
  105895:	e9 c6 f4 ff ff       	jmp    104d60 <alltraps>

0010589a <vector174>:
.globl vector174
vector174:
  pushl $0
  10589a:	6a 00                	push   $0x0
  pushl $174
  10589c:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
  1058a1:	e9 ba f4 ff ff       	jmp    104d60 <alltraps>

001058a6 <vector175>:
.globl vector175
vector175:
  pushl $0
  1058a6:	6a 00                	push   $0x0
  pushl $175
  1058a8:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
  1058ad:	e9 ae f4 ff ff       	jmp    104d60 <alltraps>

001058b2 <vector176>:
.globl vector176
vector176:
  pushl $0
  1058b2:	6a 00                	push   $0x0
  pushl $176
  1058b4:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
  1058b9:	e9 a2 f4 ff ff       	jmp    104d60 <alltraps>

001058be <vector177>:
.globl vector177
vector177:
  pushl $0
  1058be:	6a 00                	push   $0x0
  pushl $177
  1058c0:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
  1058c5:	e9 96 f4 ff ff       	jmp    104d60 <alltraps>

001058ca <vector178>:
.globl vector178
vector178:
  pushl $0
  1058ca:	6a 00                	push   $0x0
  pushl $178
  1058cc:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
  1058d1:	e9 8a f4 ff ff       	jmp    104d60 <alltraps>

001058d6 <vector179>:
.globl vector179
vector179:
  pushl $0
  1058d6:	6a 00                	push   $0x0
  pushl $179
  1058d8:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
  1058dd:	e9 7e f4 ff ff       	jmp    104d60 <alltraps>

001058e2 <vector180>:
.globl vector180
vector180:
  pushl $0
  1058e2:	6a 00                	push   $0x0
  pushl $180
  1058e4:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
  1058e9:	e9 72 f4 ff ff       	jmp    104d60 <alltraps>

001058ee <vector181>:
.globl vector181
vector181:
  pushl $0
  1058ee:	6a 00                	push   $0x0
  pushl $181
  1058f0:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
  1058f5:	e9 66 f4 ff ff       	jmp    104d60 <alltraps>

001058fa <vector182>:
.globl vector182
vector182:
  pushl $0
  1058fa:	6a 00                	push   $0x0
  pushl $182
  1058fc:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
  105901:	e9 5a f4 ff ff       	jmp    104d60 <alltraps>

00105906 <vector183>:
.globl vector183
vector183:
  pushl $0
  105906:	6a 00                	push   $0x0
  pushl $183
  105908:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
  10590d:	e9 4e f4 ff ff       	jmp    104d60 <alltraps>

00105912 <vector184>:
.globl vector184
vector184:
  pushl $0
  105912:	6a 00                	push   $0x0
  pushl $184
  105914:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
  105919:	e9 42 f4 ff ff       	jmp    104d60 <alltraps>

0010591e <vector185>:
.globl vector185
vector185:
  pushl $0
  10591e:	6a 00                	push   $0x0
  pushl $185
  105920:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
  105925:	e9 36 f4 ff ff       	jmp    104d60 <alltraps>

0010592a <vector186>:
.globl vector186
vector186:
  pushl $0
  10592a:	6a 00                	push   $0x0
  pushl $186
  10592c:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
  105931:	e9 2a f4 ff ff       	jmp    104d60 <alltraps>

00105936 <vector187>:
.globl vector187
vector187:
  pushl $0
  105936:	6a 00                	push   $0x0
  pushl $187
  105938:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
  10593d:	e9 1e f4 ff ff       	jmp    104d60 <alltraps>

00105942 <vector188>:
.globl vector188
vector188:
  pushl $0
  105942:	6a 00                	push   $0x0
  pushl $188
  105944:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
  105949:	e9 12 f4 ff ff       	jmp    104d60 <alltraps>

0010594e <vector189>:
.globl vector189
vector189:
  pushl $0
  10594e:	6a 00                	push   $0x0
  pushl $189
  105950:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
  105955:	e9 06 f4 ff ff       	jmp    104d60 <alltraps>

0010595a <vector190>:
.globl vector190
vector190:
  pushl $0
  10595a:	6a 00                	push   $0x0
  pushl $190
  10595c:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
  105961:	e9 fa f3 ff ff       	jmp    104d60 <alltraps>

00105966 <vector191>:
.globl vector191
vector191:
  pushl $0
  105966:	6a 00                	push   $0x0
  pushl $191
  105968:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
  10596d:	e9 ee f3 ff ff       	jmp    104d60 <alltraps>

00105972 <vector192>:
.globl vector192
vector192:
  pushl $0
  105972:	6a 00                	push   $0x0
  pushl $192
  105974:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
  105979:	e9 e2 f3 ff ff       	jmp    104d60 <alltraps>

0010597e <vector193>:
.globl vector193
vector193:
  pushl $0
  10597e:	6a 00                	push   $0x0
  pushl $193
  105980:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
  105985:	e9 d6 f3 ff ff       	jmp    104d60 <alltraps>

0010598a <vector194>:
.globl vector194
vector194:
  pushl $0
  10598a:	6a 00                	push   $0x0
  pushl $194
  10598c:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
  105991:	e9 ca f3 ff ff       	jmp    104d60 <alltraps>

00105996 <vector195>:
.globl vector195
vector195:
  pushl $0
  105996:	6a 00                	push   $0x0
  pushl $195
  105998:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
  10599d:	e9 be f3 ff ff       	jmp    104d60 <alltraps>

001059a2 <vector196>:
.globl vector196
vector196:
  pushl $0
  1059a2:	6a 00                	push   $0x0
  pushl $196
  1059a4:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
  1059a9:	e9 b2 f3 ff ff       	jmp    104d60 <alltraps>

001059ae <vector197>:
.globl vector197
vector197:
  pushl $0
  1059ae:	6a 00                	push   $0x0
  pushl $197
  1059b0:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
  1059b5:	e9 a6 f3 ff ff       	jmp    104d60 <alltraps>

001059ba <vector198>:
.globl vector198
vector198:
  pushl $0
  1059ba:	6a 00                	push   $0x0
  pushl $198
  1059bc:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
  1059c1:	e9 9a f3 ff ff       	jmp    104d60 <alltraps>

001059c6 <vector199>:
.globl vector199
vector199:
  pushl $0
  1059c6:	6a 00                	push   $0x0
  pushl $199
  1059c8:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
  1059cd:	e9 8e f3 ff ff       	jmp    104d60 <alltraps>

001059d2 <vector200>:
.globl vector200
vector200:
  pushl $0
  1059d2:	6a 00                	push   $0x0
  pushl $200
  1059d4:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
  1059d9:	e9 82 f3 ff ff       	jmp    104d60 <alltraps>

001059de <vector201>:
.globl vector201
vector201:
  pushl $0
  1059de:	6a 00                	push   $0x0
  pushl $201
  1059e0:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
  1059e5:	e9 76 f3 ff ff       	jmp    104d60 <alltraps>

001059ea <vector202>:
.globl vector202
vector202:
  pushl $0
  1059ea:	6a 00                	push   $0x0
  pushl $202
  1059ec:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
  1059f1:	e9 6a f3 ff ff       	jmp    104d60 <alltraps>

001059f6 <vector203>:
.globl vector203
vector203:
  pushl $0
  1059f6:	6a 00                	push   $0x0
  pushl $203
  1059f8:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
  1059fd:	e9 5e f3 ff ff       	jmp    104d60 <alltraps>

00105a02 <vector204>:
.globl vector204
vector204:
  pushl $0
  105a02:	6a 00                	push   $0x0
  pushl $204
  105a04:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
  105a09:	e9 52 f3 ff ff       	jmp    104d60 <alltraps>

00105a0e <vector205>:
.globl vector205
vector205:
  pushl $0
  105a0e:	6a 00                	push   $0x0
  pushl $205
  105a10:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
  105a15:	e9 46 f3 ff ff       	jmp    104d60 <alltraps>

00105a1a <vector206>:
.globl vector206
vector206:
  pushl $0
  105a1a:	6a 00                	push   $0x0
  pushl $206
  105a1c:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
  105a21:	e9 3a f3 ff ff       	jmp    104d60 <alltraps>

00105a26 <vector207>:
.globl vector207
vector207:
  pushl $0
  105a26:	6a 00                	push   $0x0
  pushl $207
  105a28:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
  105a2d:	e9 2e f3 ff ff       	jmp    104d60 <alltraps>

00105a32 <vector208>:
.globl vector208
vector208:
  pushl $0
  105a32:	6a 00                	push   $0x0
  pushl $208
  105a34:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
  105a39:	e9 22 f3 ff ff       	jmp    104d60 <alltraps>

00105a3e <vector209>:
.globl vector209
vector209:
  pushl $0
  105a3e:	6a 00                	push   $0x0
  pushl $209
  105a40:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
  105a45:	e9 16 f3 ff ff       	jmp    104d60 <alltraps>

00105a4a <vector210>:
.globl vector210
vector210:
  pushl $0
  105a4a:	6a 00                	push   $0x0
  pushl $210
  105a4c:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
  105a51:	e9 0a f3 ff ff       	jmp    104d60 <alltraps>

00105a56 <vector211>:
.globl vector211
vector211:
  pushl $0
  105a56:	6a 00                	push   $0x0
  pushl $211
  105a58:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
  105a5d:	e9 fe f2 ff ff       	jmp    104d60 <alltraps>

00105a62 <vector212>:
.globl vector212
vector212:
  pushl $0
  105a62:	6a 00                	push   $0x0
  pushl $212
  105a64:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
  105a69:	e9 f2 f2 ff ff       	jmp    104d60 <alltraps>

00105a6e <vector213>:
.globl vector213
vector213:
  pushl $0
  105a6e:	6a 00                	push   $0x0
  pushl $213
  105a70:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
  105a75:	e9 e6 f2 ff ff       	jmp    104d60 <alltraps>

00105a7a <vector214>:
.globl vector214
vector214:
  pushl $0
  105a7a:	6a 00                	push   $0x0
  pushl $214
  105a7c:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
  105a81:	e9 da f2 ff ff       	jmp    104d60 <alltraps>

00105a86 <vector215>:
.globl vector215
vector215:
  pushl $0
  105a86:	6a 00                	push   $0x0
  pushl $215
  105a88:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
  105a8d:	e9 ce f2 ff ff       	jmp    104d60 <alltraps>

00105a92 <vector216>:
.globl vector216
vector216:
  pushl $0
  105a92:	6a 00                	push   $0x0
  pushl $216
  105a94:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
  105a99:	e9 c2 f2 ff ff       	jmp    104d60 <alltraps>

00105a9e <vector217>:
.globl vector217
vector217:
  pushl $0
  105a9e:	6a 00                	push   $0x0
  pushl $217
  105aa0:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
  105aa5:	e9 b6 f2 ff ff       	jmp    104d60 <alltraps>

00105aaa <vector218>:
.globl vector218
vector218:
  pushl $0
  105aaa:	6a 00                	push   $0x0
  pushl $218
  105aac:	68 da 00 00 00       	push   $0xda
  jmp alltraps
  105ab1:	e9 aa f2 ff ff       	jmp    104d60 <alltraps>

00105ab6 <vector219>:
.globl vector219
vector219:
  pushl $0
  105ab6:	6a 00                	push   $0x0
  pushl $219
  105ab8:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
  105abd:	e9 9e f2 ff ff       	jmp    104d60 <alltraps>

00105ac2 <vector220>:
.globl vector220
vector220:
  pushl $0
  105ac2:	6a 00                	push   $0x0
  pushl $220
  105ac4:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
  105ac9:	e9 92 f2 ff ff       	jmp    104d60 <alltraps>

00105ace <vector221>:
.globl vector221
vector221:
  pushl $0
  105ace:	6a 00                	push   $0x0
  pushl $221
  105ad0:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
  105ad5:	e9 86 f2 ff ff       	jmp    104d60 <alltraps>

00105ada <vector222>:
.globl vector222
vector222:
  pushl $0
  105ada:	6a 00                	push   $0x0
  pushl $222
  105adc:	68 de 00 00 00       	push   $0xde
  jmp alltraps
  105ae1:	e9 7a f2 ff ff       	jmp    104d60 <alltraps>

00105ae6 <vector223>:
.globl vector223
vector223:
  pushl $0
  105ae6:	6a 00                	push   $0x0
  pushl $223
  105ae8:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
  105aed:	e9 6e f2 ff ff       	jmp    104d60 <alltraps>

00105af2 <vector224>:
.globl vector224
vector224:
  pushl $0
  105af2:	6a 00                	push   $0x0
  pushl $224
  105af4:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
  105af9:	e9 62 f2 ff ff       	jmp    104d60 <alltraps>

00105afe <vector225>:
.globl vector225
vector225:
  pushl $0
  105afe:	6a 00                	push   $0x0
  pushl $225
  105b00:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
  105b05:	e9 56 f2 ff ff       	jmp    104d60 <alltraps>

00105b0a <vector226>:
.globl vector226
vector226:
  pushl $0
  105b0a:	6a 00                	push   $0x0
  pushl $226
  105b0c:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
  105b11:	e9 4a f2 ff ff       	jmp    104d60 <alltraps>

00105b16 <vector227>:
.globl vector227
vector227:
  pushl $0
  105b16:	6a 00                	push   $0x0
  pushl $227
  105b18:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
  105b1d:	e9 3e f2 ff ff       	jmp    104d60 <alltraps>

00105b22 <vector228>:
.globl vector228
vector228:
  pushl $0
  105b22:	6a 00                	push   $0x0
  pushl $228
  105b24:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
  105b29:	e9 32 f2 ff ff       	jmp    104d60 <alltraps>

00105b2e <vector229>:
.globl vector229
vector229:
  pushl $0
  105b2e:	6a 00                	push   $0x0
  pushl $229
  105b30:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
  105b35:	e9 26 f2 ff ff       	jmp    104d60 <alltraps>

00105b3a <vector230>:
.globl vector230
vector230:
  pushl $0
  105b3a:	6a 00                	push   $0x0
  pushl $230
  105b3c:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
  105b41:	e9 1a f2 ff ff       	jmp    104d60 <alltraps>

00105b46 <vector231>:
.globl vector231
vector231:
  pushl $0
  105b46:	6a 00                	push   $0x0
  pushl $231
  105b48:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
  105b4d:	e9 0e f2 ff ff       	jmp    104d60 <alltraps>

00105b52 <vector232>:
.globl vector232
vector232:
  pushl $0
  105b52:	6a 00                	push   $0x0
  pushl $232
  105b54:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
  105b59:	e9 02 f2 ff ff       	jmp    104d60 <alltraps>

00105b5e <vector233>:
.globl vector233
vector233:
  pushl $0
  105b5e:	6a 00                	push   $0x0
  pushl $233
  105b60:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
  105b65:	e9 f6 f1 ff ff       	jmp    104d60 <alltraps>

00105b6a <vector234>:
.globl vector234
vector234:
  pushl $0
  105b6a:	6a 00                	push   $0x0
  pushl $234
  105b6c:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
  105b71:	e9 ea f1 ff ff       	jmp    104d60 <alltraps>

00105b76 <vector235>:
.globl vector235
vector235:
  pushl $0
  105b76:	6a 00                	push   $0x0
  pushl $235
  105b78:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
  105b7d:	e9 de f1 ff ff       	jmp    104d60 <alltraps>

00105b82 <vector236>:
.globl vector236
vector236:
  pushl $0
  105b82:	6a 00                	push   $0x0
  pushl $236
  105b84:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
  105b89:	e9 d2 f1 ff ff       	jmp    104d60 <alltraps>

00105b8e <vector237>:
.globl vector237
vector237:
  pushl $0
  105b8e:	6a 00                	push   $0x0
  pushl $237
  105b90:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
  105b95:	e9 c6 f1 ff ff       	jmp    104d60 <alltraps>

00105b9a <vector238>:
.globl vector238
vector238:
  pushl $0
  105b9a:	6a 00                	push   $0x0
  pushl $238
  105b9c:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
  105ba1:	e9 ba f1 ff ff       	jmp    104d60 <alltraps>

00105ba6 <vector239>:
.globl vector239
vector239:
  pushl $0
  105ba6:	6a 00                	push   $0x0
  pushl $239
  105ba8:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
  105bad:	e9 ae f1 ff ff       	jmp    104d60 <alltraps>

00105bb2 <vector240>:
.globl vector240
vector240:
  pushl $0
  105bb2:	6a 00                	push   $0x0
  pushl $240
  105bb4:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
  105bb9:	e9 a2 f1 ff ff       	jmp    104d60 <alltraps>

00105bbe <vector241>:
.globl vector241
vector241:
  pushl $0
  105bbe:	6a 00                	push   $0x0
  pushl $241
  105bc0:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
  105bc5:	e9 96 f1 ff ff       	jmp    104d60 <alltraps>

00105bca <vector242>:
.globl vector242
vector242:
  pushl $0
  105bca:	6a 00                	push   $0x0
  pushl $242
  105bcc:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
  105bd1:	e9 8a f1 ff ff       	jmp    104d60 <alltraps>

00105bd6 <vector243>:
.globl vector243
vector243:
  pushl $0
  105bd6:	6a 00                	push   $0x0
  pushl $243
  105bd8:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
  105bdd:	e9 7e f1 ff ff       	jmp    104d60 <alltraps>

00105be2 <vector244>:
.globl vector244
vector244:
  pushl $0
  105be2:	6a 00                	push   $0x0
  pushl $244
  105be4:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
  105be9:	e9 72 f1 ff ff       	jmp    104d60 <alltraps>

00105bee <vector245>:
.globl vector245
vector245:
  pushl $0
  105bee:	6a 00                	push   $0x0
  pushl $245
  105bf0:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
  105bf5:	e9 66 f1 ff ff       	jmp    104d60 <alltraps>

00105bfa <vector246>:
.globl vector246
vector246:
  pushl $0
  105bfa:	6a 00                	push   $0x0
  pushl $246
  105bfc:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
  105c01:	e9 5a f1 ff ff       	jmp    104d60 <alltraps>

00105c06 <vector247>:
.globl vector247
vector247:
  pushl $0
  105c06:	6a 00                	push   $0x0
  pushl $247
  105c08:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
  105c0d:	e9 4e f1 ff ff       	jmp    104d60 <alltraps>

00105c12 <vector248>:
.globl vector248
vector248:
  pushl $0
  105c12:	6a 00                	push   $0x0
  pushl $248
  105c14:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
  105c19:	e9 42 f1 ff ff       	jmp    104d60 <alltraps>

00105c1e <vector249>:
.globl vector249
vector249:
  pushl $0
  105c1e:	6a 00                	push   $0x0
  pushl $249
  105c20:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
  105c25:	e9 36 f1 ff ff       	jmp    104d60 <alltraps>

00105c2a <vector250>:
.globl vector250
vector250:
  pushl $0
  105c2a:	6a 00                	push   $0x0
  pushl $250
  105c2c:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
  105c31:	e9 2a f1 ff ff       	jmp    104d60 <alltraps>

00105c36 <vector251>:
.globl vector251
vector251:
  pushl $0
  105c36:	6a 00                	push   $0x0
  pushl $251
  105c38:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
  105c3d:	e9 1e f1 ff ff       	jmp    104d60 <alltraps>

00105c42 <vector252>:
.globl vector252
vector252:
  pushl $0
  105c42:	6a 00                	push   $0x0
  pushl $252
  105c44:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
  105c49:	e9 12 f1 ff ff       	jmp    104d60 <alltraps>

00105c4e <vector253>:
.globl vector253
vector253:
  pushl $0
  105c4e:	6a 00                	push   $0x0
  pushl $253
  105c50:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
  105c55:	e9 06 f1 ff ff       	jmp    104d60 <alltraps>

00105c5a <vector254>:
.globl vector254
vector254:
  pushl $0
  105c5a:	6a 00                	push   $0x0
  pushl $254
  105c5c:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
  105c61:	e9 fa f0 ff ff       	jmp    104d60 <alltraps>

00105c66 <vector255>:
.globl vector255
vector255:
  pushl $0
  105c66:	6a 00                	push   $0x0
  pushl $255
  105c68:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
  105c6d:	e9 ee f0 ff ff       	jmp    104d60 <alltraps>
  105c72:	90                   	nop
  105c73:	90                   	nop
  105c74:	90                   	nop
  105c75:	90                   	nop
  105c76:	90                   	nop
  105c77:	90                   	nop
  105c78:	90                   	nop
  105c79:	90                   	nop
  105c7a:	90                   	nop
  105c7b:	90                   	nop
  105c7c:	90                   	nop
  105c7d:	90                   	nop
  105c7e:	90                   	nop
  105c7f:	90                   	nop

00105c80 <vmenable>:
}

// Turn on paging.
void
vmenable(void)
{
  105c80:	55                   	push   %ebp
}

static inline void
lcr3(uint val) 
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
  105c81:	a1 d0 78 10 00       	mov    0x1078d0,%eax
  105c86:	89 e5                	mov    %esp,%ebp
  105c88:	0f 22 d8             	mov    %eax,%cr3

static inline uint
rcr0(void)
{
  uint val;
  asm volatile("movl %%cr0,%0" : "=r" (val));
  105c8b:	0f 20 c0             	mov    %cr0,%eax
}

static inline void
lcr0(uint val)
{
  asm volatile("movl %0,%%cr0" : : "r" (val));
  105c8e:	0d 00 00 00 80       	or     $0x80000000,%eax
  105c93:	0f 22 c0             	mov    %eax,%cr0

  switchkvm(); // load kpgdir into cr3
  cr0 = rcr0();
  cr0 |= CR0_PG;
  lcr0(cr0);
}
  105c96:	5d                   	pop    %ebp
  105c97:	c3                   	ret    
  105c98:	90                   	nop
  105c99:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00105ca0 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
  105ca0:	55                   	push   %ebp
}

static inline void
lcr3(uint val) 
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
  105ca1:	a1 d0 78 10 00       	mov    0x1078d0,%eax
  105ca6:	89 e5                	mov    %esp,%ebp
  105ca8:	0f 22 d8             	mov    %eax,%cr3
  lcr3(PADDR(kpgdir));   // switch to the kernel page table
}
  105cab:	5d                   	pop    %ebp
  105cac:	c3                   	ret    
  105cad:	8d 76 00             	lea    0x0(%esi),%esi

00105cb0 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to linear address va.  If create!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int create)
{
  105cb0:	55                   	push   %ebp
  105cb1:	89 e5                	mov    %esp,%ebp
  105cb3:	83 ec 28             	sub    $0x28,%esp
  105cb6:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
  105cb9:	89 d3                	mov    %edx,%ebx
  105cbb:	c1 eb 16             	shr    $0x16,%ebx
  105cbe:	8d 1c 98             	lea    (%eax,%ebx,4),%ebx
// Return the address of the PTE in page table pgdir
// that corresponds to linear address va.  If create!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int create)
{
  105cc1:	89 75 fc             	mov    %esi,-0x4(%ebp)
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
  if(*pde & PTE_P){
  105cc4:	8b 33                	mov    (%ebx),%esi
  105cc6:	f7 c6 01 00 00 00    	test   $0x1,%esi
  105ccc:	74 22                	je     105cf0 <walkpgdir+0x40>
    pgtab = (pte_t*)PTE_ADDR(*pde);
  105cce:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = PADDR(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
  105cd4:	c1 ea 0a             	shr    $0xa,%edx
  105cd7:	81 e2 fc 0f 00 00    	and    $0xffc,%edx
  105cdd:	8d 04 16             	lea    (%esi,%edx,1),%eax
}
  105ce0:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  105ce3:	8b 75 fc             	mov    -0x4(%ebp),%esi
  105ce6:	89 ec                	mov    %ebp,%esp
  105ce8:	5d                   	pop    %ebp
  105ce9:	c3                   	ret    
  105cea:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

  pde = &pgdir[PDX(va)];
  if(*pde & PTE_P){
    pgtab = (pte_t*)PTE_ADDR(*pde);
  } else {
    if(!create || (pgtab = (pte_t*)kalloc()) == 0)
  105cf0:	85 c9                	test   %ecx,%ecx
  105cf2:	75 04                	jne    105cf8 <walkpgdir+0x48>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = PADDR(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
  105cf4:	31 c0                	xor    %eax,%eax
  105cf6:	eb e8                	jmp    105ce0 <walkpgdir+0x30>

  pde = &pgdir[PDX(va)];
  if(*pde & PTE_P){
    pgtab = (pte_t*)PTE_ADDR(*pde);
  } else {
    if(!create || (pgtab = (pte_t*)kalloc()) == 0)
  105cf8:	89 55 f4             	mov    %edx,-0xc(%ebp)
  105cfb:	90                   	nop
  105cfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105d00:	e8 4b c5 ff ff       	call   102250 <kalloc>
  105d05:	85 c0                	test   %eax,%eax
  105d07:	89 c6                	mov    %eax,%esi
  105d09:	74 e9                	je     105cf4 <walkpgdir+0x44>
      return 0;
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
  105d0b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105d12:	00 
  105d13:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  105d1a:	00 
  105d1b:	89 04 24             	mov    %eax,(%esp)
  105d1e:	e8 cd de ff ff       	call   103bf0 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = PADDR(pgtab) | PTE_P | PTE_W | PTE_U;
  105d23:	89 f0                	mov    %esi,%eax
  105d25:	83 c8 07             	or     $0x7,%eax
  105d28:	89 03                	mov    %eax,(%ebx)
  105d2a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105d2d:	eb a5                	jmp    105cd4 <walkpgdir+0x24>
  105d2f:	90                   	nop

00105d30 <uva2ka>:
}

// Map user virtual address to kernel physical address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
  105d30:	55                   	push   %ebp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
  105d31:	31 c9                	xor    %ecx,%ecx
}

// Map user virtual address to kernel physical address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
  105d33:	89 e5                	mov    %esp,%ebp
  105d35:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
  105d38:	8b 55 0c             	mov    0xc(%ebp),%edx
  105d3b:	8b 45 08             	mov    0x8(%ebp),%eax
  105d3e:	e8 6d ff ff ff       	call   105cb0 <walkpgdir>
  if((*pte & PTE_P) == 0)
  105d43:	8b 00                	mov    (%eax),%eax
  105d45:	a8 01                	test   $0x1,%al
  105d47:	75 07                	jne    105d50 <uva2ka+0x20>
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  return (char*)PTE_ADDR(*pte);
  105d49:	31 c0                	xor    %eax,%eax
}
  105d4b:	c9                   	leave  
  105d4c:	c3                   	ret    
  105d4d:	8d 76 00             	lea    0x0(%esi),%esi
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
  if((*pte & PTE_P) == 0)
    return 0;
  if((*pte & PTE_U) == 0)
  105d50:	a8 04                	test   $0x4,%al
  105d52:	74 f5                	je     105d49 <uva2ka+0x19>
    return 0;
  return (char*)PTE_ADDR(*pte);
  105d54:	25 00 f0 ff ff       	and    $0xfffff000,%eax
}
  105d59:	c9                   	leave  
  105d5a:	c3                   	ret    
  105d5b:	90                   	nop
  105d5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00105d60 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
  105d60:	55                   	push   %ebp
  105d61:	89 e5                	mov    %esp,%ebp
  105d63:	57                   	push   %edi
  105d64:	56                   	push   %esi
  105d65:	53                   	push   %ebx
  105d66:	83 ec 2c             	sub    $0x2c,%esp
  105d69:	8b 7d 14             	mov    0x14(%ebp),%edi
  105d6c:	8b 55 0c             	mov    0xc(%ebp),%edx
  char *buf, *pa0;
  uint n, va0;
  
  buf = (char*)p;
  while(len > 0){
  105d6f:	85 ff                	test   %edi,%edi
  105d71:	74 75                	je     105de8 <copyout+0x88>
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
  char *buf, *pa0;
  uint n, va0;
  
  buf = (char*)p;
  105d73:	8b 45 10             	mov    0x10(%ebp),%eax
  105d76:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  105d79:	eb 3a                	jmp    105db5 <copyout+0x55>
  105d7b:	90                   	nop
  105d7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  while(len > 0){
    va0 = (uint)PGROUNDDOWN(va);
    pa0 = uva2ka(pgdir, (char*)va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
  105d80:	89 f3                	mov    %esi,%ebx
  105d82:	29 d3                	sub    %edx,%ebx
  105d84:	81 c3 00 10 00 00    	add    $0x1000,%ebx
  105d8a:	39 fb                	cmp    %edi,%ebx
  105d8c:	76 02                	jbe    105d90 <copyout+0x30>
  105d8e:	89 fb                	mov    %edi,%ebx
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
  105d90:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  105d94:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  105d97:	29 f2                	sub    %esi,%edx
  105d99:	8d 14 10             	lea    (%eax,%edx,1),%edx
  105d9c:	89 14 24             	mov    %edx,(%esp)
  105d9f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  105da3:	e8 c8 de ff ff       	call   103c70 <memmove>
{
  char *buf, *pa0;
  uint n, va0;
  
  buf = (char*)p;
  while(len > 0){
  105da8:	29 df                	sub    %ebx,%edi
  105daa:	74 3c                	je     105de8 <copyout+0x88>
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
  105dac:	01 5d e4             	add    %ebx,-0x1c(%ebp)
    va = va0 + PGSIZE;
  105daf:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
  char *buf, *pa0;
  uint n, va0;
  
  buf = (char*)p;
  while(len > 0){
    va0 = (uint)PGROUNDDOWN(va);
  105db5:	89 d6                	mov    %edx,%esi
  105db7:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
  105dbd:	89 74 24 04          	mov    %esi,0x4(%esp)
  105dc1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  105dc4:	89 0c 24             	mov    %ecx,(%esp)
  105dc7:	89 55 e0             	mov    %edx,-0x20(%ebp)
  105dca:	e8 61 ff ff ff       	call   105d30 <uva2ka>
    if(pa0 == 0)
  105dcf:	8b 55 e0             	mov    -0x20(%ebp),%edx
  105dd2:	85 c0                	test   %eax,%eax
  105dd4:	75 aa                	jne    105d80 <copyout+0x20>
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
}
  105dd6:	83 c4 2c             	add    $0x2c,%esp
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  105dd9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
  105dde:	5b                   	pop    %ebx
  105ddf:	5e                   	pop    %esi
  105de0:	5f                   	pop    %edi
  105de1:	5d                   	pop    %ebp
  105de2:	c3                   	ret    
  105de3:	90                   	nop
  105de4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105de8:	83 c4 2c             	add    $0x2c,%esp
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  105deb:	31 c0                	xor    %eax,%eax
  }
  return 0;
}
  105ded:	5b                   	pop    %ebx
  105dee:	5e                   	pop    %esi
  105def:	5f                   	pop    %edi
  105df0:	5d                   	pop    %ebp
  105df1:	c3                   	ret    
  105df2:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  105df9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00105e00 <mappages>:
// Create PTEs for linear addresses starting at la that refer to
// physical addresses starting at pa. la and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *la, uint size, uint pa, int perm)
{
  105e00:	55                   	push   %ebp
  105e01:	89 e5                	mov    %esp,%ebp
  105e03:	57                   	push   %edi
  105e04:	56                   	push   %esi
  105e05:	53                   	push   %ebx
  char *a, *last;
  pte_t *pte;
  
  a = PGROUNDDOWN(la);
  105e06:	89 d3                	mov    %edx,%ebx
  last = PGROUNDDOWN(la + size - 1);
  105e08:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
// Create PTEs for linear addresses starting at la that refer to
// physical addresses starting at pa. la and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *la, uint size, uint pa, int perm)
{
  105e0c:	83 ec 2c             	sub    $0x2c,%esp
  105e0f:	8b 75 08             	mov    0x8(%ebp),%esi
  105e12:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  char *a, *last;
  pte_t *pte;
  
  a = PGROUNDDOWN(la);
  105e15:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = PGROUNDDOWN(la + size - 1);
  105e1b:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
    pte = walkpgdir(pgdir, a, 1);
    if(pte == 0)
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
  105e21:	83 4d 0c 01          	orl    $0x1,0xc(%ebp)
  105e25:	eb 1d                	jmp    105e44 <mappages+0x44>
  105e27:	90                   	nop
  last = PGROUNDDOWN(la + size - 1);
  for(;;){
    pte = walkpgdir(pgdir, a, 1);
    if(pte == 0)
      return -1;
    if(*pte & PTE_P)
  105e28:	f6 00 01             	testb  $0x1,(%eax)
  105e2b:	75 45                	jne    105e72 <mappages+0x72>
      panic("remap");
    *pte = pa | perm | PTE_P;
  105e2d:	8b 55 0c             	mov    0xc(%ebp),%edx
  105e30:	09 f2                	or     %esi,%edx
    if(a == last)
  105e32:	39 fb                	cmp    %edi,%ebx
    pte = walkpgdir(pgdir, a, 1);
    if(pte == 0)
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
  105e34:	89 10                	mov    %edx,(%eax)
    if(a == last)
  105e36:	74 30                	je     105e68 <mappages+0x68>
      break;
    a += PGSIZE;
  105e38:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
  105e3e:	81 c6 00 10 00 00    	add    $0x1000,%esi
  pte_t *pte;
  
  a = PGROUNDDOWN(la);
  last = PGROUNDDOWN(la + size - 1);
  for(;;){
    pte = walkpgdir(pgdir, a, 1);
  105e44:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105e47:	b9 01 00 00 00       	mov    $0x1,%ecx
  105e4c:	89 da                	mov    %ebx,%edx
  105e4e:	e8 5d fe ff ff       	call   105cb0 <walkpgdir>
    if(pte == 0)
  105e53:	85 c0                	test   %eax,%eax
  105e55:	75 d1                	jne    105e28 <mappages+0x28>
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}
  105e57:	83 c4 2c             	add    $0x2c,%esp
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  105e5a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  return 0;
}
  105e5f:	5b                   	pop    %ebx
  105e60:	5e                   	pop    %esi
  105e61:	5f                   	pop    %edi
  105e62:	5d                   	pop    %ebp
  105e63:	c3                   	ret    
  105e64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105e68:	83 c4 2c             	add    $0x2c,%esp
    if(pte == 0)
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
  105e6b:	31 c0                	xor    %eax,%eax
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}
  105e6d:	5b                   	pop    %ebx
  105e6e:	5e                   	pop    %esi
  105e6f:	5f                   	pop    %edi
  105e70:	5d                   	pop    %ebp
  105e71:	c3                   	ret    
  for(;;){
    pte = walkpgdir(pgdir, a, 1);
    if(pte == 0)
      return -1;
    if(*pte & PTE_P)
      panic("remap");
  105e72:	c7 04 24 10 6d 10 00 	movl   $0x106d10,(%esp)
  105e79:	e8 a2 aa ff ff       	call   100920 <panic>
  105e7e:	66 90                	xchg   %ax,%ax

00105e80 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
  105e80:	55                   	push   %ebp
  105e81:	89 e5                	mov    %esp,%ebp
  105e83:	56                   	push   %esi
  105e84:	53                   	push   %ebx
  105e85:	83 ec 10             	sub    $0x10,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
  105e88:	e8 c3 c3 ff ff       	call   102250 <kalloc>
  105e8d:	85 c0                	test   %eax,%eax
  105e8f:	89 c6                	mov    %eax,%esi
  105e91:	74 50                	je     105ee3 <setupkvm+0x63>
    return 0;
  memset(pgdir, 0, PGSIZE);
  105e93:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105e9a:	00 
  105e9b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  105ea2:	00 
  105ea3:	89 04 24             	mov    %eax,(%esp)
  105ea6:	e8 45 dd ff ff       	call   103bf0 <memset>
  k = kmap;
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
  105eab:	b8 70 77 10 00       	mov    $0x107770,%eax
  105eb0:	3d 40 77 10 00       	cmp    $0x107740,%eax
  105eb5:	76 2c                	jbe    105ee3 <setupkvm+0x63>
  {(void*)0xFE000000, 0,               PTE_W},  // device mappings
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
  105eb7:	bb 40 77 10 00       	mov    $0x107740,%ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  k = kmap;
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->p, k->e - k->p, (uint)k->p, k->perm) < 0)
  105ebc:	8b 13                	mov    (%ebx),%edx
  105ebe:	8b 4b 04             	mov    0x4(%ebx),%ecx
  105ec1:	8b 43 08             	mov    0x8(%ebx),%eax
  105ec4:	89 14 24             	mov    %edx,(%esp)
  105ec7:	29 d1                	sub    %edx,%ecx
  105ec9:	89 44 24 04          	mov    %eax,0x4(%esp)
  105ecd:	89 f0                	mov    %esi,%eax
  105ecf:	e8 2c ff ff ff       	call   105e00 <mappages>
  105ed4:	85 c0                	test   %eax,%eax
  105ed6:	78 18                	js     105ef0 <setupkvm+0x70>

  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  k = kmap;
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
  105ed8:	83 c3 0c             	add    $0xc,%ebx
  105edb:	81 fb 70 77 10 00    	cmp    $0x107770,%ebx
  105ee1:	75 d9                	jne    105ebc <setupkvm+0x3c>
    if(mappages(pgdir, k->p, k->e - k->p, (uint)k->p, k->perm) < 0)
      return 0;

  return pgdir;
}
  105ee3:	83 c4 10             	add    $0x10,%esp
  105ee6:	89 f0                	mov    %esi,%eax
  105ee8:	5b                   	pop    %ebx
  105ee9:	5e                   	pop    %esi
  105eea:	5d                   	pop    %ebp
  105eeb:	c3                   	ret    
  105eec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  k = kmap;
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->p, k->e - k->p, (uint)k->p, k->perm) < 0)
  105ef0:	31 f6                	xor    %esi,%esi
      return 0;

  return pgdir;
}
  105ef2:	83 c4 10             	add    $0x10,%esp
  105ef5:	89 f0                	mov    %esi,%eax
  105ef7:	5b                   	pop    %ebx
  105ef8:	5e                   	pop    %esi
  105ef9:	5d                   	pop    %ebp
  105efa:	c3                   	ret    
  105efb:	90                   	nop
  105efc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00105f00 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
  105f00:	55                   	push   %ebp
  105f01:	89 e5                	mov    %esp,%ebp
  105f03:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
  105f06:	e8 75 ff ff ff       	call   105e80 <setupkvm>
  105f0b:	a3 d0 78 10 00       	mov    %eax,0x1078d0
}
  105f10:	c9                   	leave  
  105f11:	c3                   	ret    
  105f12:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  105f19:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00105f20 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
  105f20:	55                   	push   %ebp
  105f21:	89 e5                	mov    %esp,%ebp
  105f23:	83 ec 38             	sub    $0x38,%esp
  105f26:	89 75 f8             	mov    %esi,-0x8(%ebp)
  105f29:	8b 75 10             	mov    0x10(%ebp),%esi
  105f2c:	8b 45 08             	mov    0x8(%ebp),%eax
  105f2f:	89 7d fc             	mov    %edi,-0x4(%ebp)
  105f32:	8b 7d 0c             	mov    0xc(%ebp),%edi
  105f35:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  char *mem;
  
  if(sz >= PGSIZE)
  105f38:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
  105f3e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  char *mem;
  
  if(sz >= PGSIZE)
  105f41:	77 53                	ja     105f96 <inituvm+0x76>
    panic("inituvm: more than a page");
  mem = kalloc();
  105f43:	e8 08 c3 ff ff       	call   102250 <kalloc>
  memset(mem, 0, PGSIZE);
  105f48:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105f4f:	00 
  105f50:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  105f57:	00 
{
  char *mem;
  
  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  105f58:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
  105f5a:	89 04 24             	mov    %eax,(%esp)
  105f5d:	e8 8e dc ff ff       	call   103bf0 <memset>
  mappages(pgdir, 0, PGSIZE, PADDR(mem), PTE_W|PTE_U);
  105f62:	b9 00 10 00 00       	mov    $0x1000,%ecx
  105f67:	31 d2                	xor    %edx,%edx
  105f69:	89 1c 24             	mov    %ebx,(%esp)
  105f6c:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
  105f73:	00 
  105f74:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105f77:	e8 84 fe ff ff       	call   105e00 <mappages>
  memmove(mem, init, sz);
  105f7c:	89 75 10             	mov    %esi,0x10(%ebp)
}
  105f7f:	8b 75 f8             	mov    -0x8(%ebp),%esi
  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  memset(mem, 0, PGSIZE);
  mappages(pgdir, 0, PGSIZE, PADDR(mem), PTE_W|PTE_U);
  memmove(mem, init, sz);
  105f82:	89 7d 0c             	mov    %edi,0xc(%ebp)
}
  105f85:	8b 7d fc             	mov    -0x4(%ebp),%edi
  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  memset(mem, 0, PGSIZE);
  mappages(pgdir, 0, PGSIZE, PADDR(mem), PTE_W|PTE_U);
  memmove(mem, init, sz);
  105f88:	89 5d 08             	mov    %ebx,0x8(%ebp)
}
  105f8b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  105f8e:	89 ec                	mov    %ebp,%esp
  105f90:	5d                   	pop    %ebp
  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  memset(mem, 0, PGSIZE);
  mappages(pgdir, 0, PGSIZE, PADDR(mem), PTE_W|PTE_U);
  memmove(mem, init, sz);
  105f91:	e9 da dc ff ff       	jmp    103c70 <memmove>
inituvm(pde_t *pgdir, char *init, uint sz)
{
  char *mem;
  
  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  105f96:	c7 04 24 16 6d 10 00 	movl   $0x106d16,(%esp)
  105f9d:	e8 7e a9 ff ff       	call   100920 <panic>
  105fa2:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  105fa9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00105fb0 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
  105fb0:	55                   	push   %ebp
  105fb1:	89 e5                	mov    %esp,%ebp
  105fb3:	57                   	push   %edi
  105fb4:	56                   	push   %esi
  105fb5:	53                   	push   %ebx
  105fb6:	83 ec 2c             	sub    $0x2c,%esp
  105fb9:	8b 75 0c             	mov    0xc(%ebp),%esi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
  105fbc:	39 75 10             	cmp    %esi,0x10(%ebp)
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
  105fbf:	8b 7d 08             	mov    0x8(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
    return oldsz;
  105fc2:	89 f0                	mov    %esi,%eax
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
  105fc4:	73 59                	jae    10601f <deallocuvm+0x6f>
    return oldsz;

  a = PGROUNDUP(newsz);
  105fc6:	8b 5d 10             	mov    0x10(%ebp),%ebx
  105fc9:	81 c3 ff 0f 00 00    	add    $0xfff,%ebx
  105fcf:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
  105fd5:	39 de                	cmp    %ebx,%esi
  105fd7:	76 43                	jbe    10601c <deallocuvm+0x6c>
  105fd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
    pte = walkpgdir(pgdir, (char*)a, 0);
  105fe0:	31 c9                	xor    %ecx,%ecx
  105fe2:	89 da                	mov    %ebx,%edx
  105fe4:	89 f8                	mov    %edi,%eax
  105fe6:	e8 c5 fc ff ff       	call   105cb0 <walkpgdir>
    if(pte && (*pte & PTE_P) != 0){
  105feb:	85 c0                	test   %eax,%eax
  105fed:	74 23                	je     106012 <deallocuvm+0x62>
  105fef:	8b 10                	mov    (%eax),%edx
  105ff1:	f6 c2 01             	test   $0x1,%dl
  105ff4:	74 1c                	je     106012 <deallocuvm+0x62>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
  105ff6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  105ffc:	74 29                	je     106027 <deallocuvm+0x77>
        panic("kfree");
      kfree((char*)pa);
  105ffe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  106001:	89 14 24             	mov    %edx,(%esp)
  106004:	e8 87 c2 ff ff       	call   102290 <kfree>
      *pte = 0;
  106009:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10600c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
  106012:	81 c3 00 10 00 00    	add    $0x1000,%ebx
  106018:	39 de                	cmp    %ebx,%esi
  10601a:	77 c4                	ja     105fe0 <deallocuvm+0x30>
        panic("kfree");
      kfree((char*)pa);
      *pte = 0;
    }
  }
  return newsz;
  10601c:	8b 45 10             	mov    0x10(%ebp),%eax
}
  10601f:	83 c4 2c             	add    $0x2c,%esp
  106022:	5b                   	pop    %ebx
  106023:	5e                   	pop    %esi
  106024:	5f                   	pop    %edi
  106025:	5d                   	pop    %ebp
  106026:	c3                   	ret    
  for(; a  < oldsz; a += PGSIZE){
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(pte && (*pte & PTE_P) != 0){
      pa = PTE_ADDR(*pte);
      if(pa == 0)
        panic("kfree");
  106027:	c7 04 24 be 66 10 00 	movl   $0x1066be,(%esp)
  10602e:	e8 ed a8 ff ff       	call   100920 <panic>
  106033:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  106039:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00106040 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
  106040:	55                   	push   %ebp
  106041:	89 e5                	mov    %esp,%ebp
  106043:	56                   	push   %esi
  106044:	53                   	push   %ebx
  106045:	83 ec 10             	sub    $0x10,%esp
  106048:	8b 5d 08             	mov    0x8(%ebp),%ebx
  uint i;

  if(pgdir == 0)
  10604b:	85 db                	test   %ebx,%ebx
  10604d:	74 59                	je     1060a8 <freevm+0x68>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, USERTOP, 0);
  10604f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  106056:	00 
  106057:	31 f6                	xor    %esi,%esi
  106059:	c7 44 24 04 00 00 0a 	movl   $0xa0000,0x4(%esp)
  106060:	00 
  106061:	89 1c 24             	mov    %ebx,(%esp)
  106064:	e8 47 ff ff ff       	call   105fb0 <deallocuvm>
  106069:	eb 10                	jmp    10607b <freevm+0x3b>
  10606b:	90                   	nop
  10606c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  for(i = 0; i < NPDENTRIES; i++){
  106070:	83 c6 01             	add    $0x1,%esi
  106073:	81 fe 00 04 00 00    	cmp    $0x400,%esi
  106079:	74 1f                	je     10609a <freevm+0x5a>
    if(pgdir[i] & PTE_P)
  10607b:	8b 04 b3             	mov    (%ebx,%esi,4),%eax
  10607e:	a8 01                	test   $0x1,%al
  106080:	74 ee                	je     106070 <freevm+0x30>
      kfree((char*)PTE_ADDR(pgdir[i]));
  106082:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, USERTOP, 0);
  for(i = 0; i < NPDENTRIES; i++){
  106087:	83 c6 01             	add    $0x1,%esi
    if(pgdir[i] & PTE_P)
      kfree((char*)PTE_ADDR(pgdir[i]));
  10608a:	89 04 24             	mov    %eax,(%esp)
  10608d:	e8 fe c1 ff ff       	call   102290 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, USERTOP, 0);
  for(i = 0; i < NPDENTRIES; i++){
  106092:	81 fe 00 04 00 00    	cmp    $0x400,%esi
  106098:	75 e1                	jne    10607b <freevm+0x3b>
    if(pgdir[i] & PTE_P)
      kfree((char*)PTE_ADDR(pgdir[i]));
  }
  kfree((char*)pgdir);
  10609a:	89 5d 08             	mov    %ebx,0x8(%ebp)
}
  10609d:	83 c4 10             	add    $0x10,%esp
  1060a0:	5b                   	pop    %ebx
  1060a1:	5e                   	pop    %esi
  1060a2:	5d                   	pop    %ebp
  deallocuvm(pgdir, USERTOP, 0);
  for(i = 0; i < NPDENTRIES; i++){
    if(pgdir[i] & PTE_P)
      kfree((char*)PTE_ADDR(pgdir[i]));
  }
  kfree((char*)pgdir);
  1060a3:	e9 e8 c1 ff ff       	jmp    102290 <kfree>
freevm(pde_t *pgdir)
{
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  1060a8:	c7 04 24 30 6d 10 00 	movl   $0x106d30,(%esp)
  1060af:	e8 6c a8 ff ff       	call   100920 <panic>
  1060b4:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1060ba:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

001060c0 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
  1060c0:	55                   	push   %ebp
  1060c1:	89 e5                	mov    %esp,%ebp
  1060c3:	57                   	push   %edi
  1060c4:	56                   	push   %esi
  1060c5:	53                   	push   %ebx
  1060c6:	83 ec 2c             	sub    $0x2c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
  1060c9:	e8 b2 fd ff ff       	call   105e80 <setupkvm>
  1060ce:	85 c0                	test   %eax,%eax
  1060d0:	89 c6                	mov    %eax,%esi
  1060d2:	0f 84 84 00 00 00    	je     10615c <copyuvm+0x9c>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
  1060d8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1060db:	85 c0                	test   %eax,%eax
  1060dd:	74 7d                	je     10615c <copyuvm+0x9c>
  1060df:	31 db                	xor    %ebx,%ebx
  1060e1:	eb 47                	jmp    10612a <copyuvm+0x6a>
  1060e3:	90                   	nop
  1060e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
    memmove(mem, (char*)pa, PGSIZE);
  1060e8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  1060ee:	89 54 24 04          	mov    %edx,0x4(%esp)
  1060f2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1060f9:	00 
  1060fa:	89 04 24             	mov    %eax,(%esp)
  1060fd:	e8 6e db ff ff       	call   103c70 <memmove>
    if(mappages(d, (void*)i, PGSIZE, PADDR(mem), PTE_W|PTE_U) < 0)
  106102:	b9 00 10 00 00       	mov    $0x1000,%ecx
  106107:	89 da                	mov    %ebx,%edx
  106109:	89 f0                	mov    %esi,%eax
  10610b:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
  106112:	00 
  106113:	89 3c 24             	mov    %edi,(%esp)
  106116:	e8 e5 fc ff ff       	call   105e00 <mappages>
  10611b:	85 c0                	test   %eax,%eax
  10611d:	78 33                	js     106152 <copyuvm+0x92>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
  10611f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
  106125:	39 5d 0c             	cmp    %ebx,0xc(%ebp)
  106128:	76 32                	jbe    10615c <copyuvm+0x9c>
    if((pte = walkpgdir(pgdir, (void*)i, 0)) == 0)
  10612a:	8b 45 08             	mov    0x8(%ebp),%eax
  10612d:	31 c9                	xor    %ecx,%ecx
  10612f:	89 da                	mov    %ebx,%edx
  106131:	e8 7a fb ff ff       	call   105cb0 <walkpgdir>
  106136:	85 c0                	test   %eax,%eax
  106138:	74 2c                	je     106166 <copyuvm+0xa6>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
  10613a:	8b 10                	mov    (%eax),%edx
  10613c:	f6 c2 01             	test   $0x1,%dl
  10613f:	74 31                	je     106172 <copyuvm+0xb2>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
  106141:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  106144:	e8 07 c1 ff ff       	call   102250 <kalloc>
  106149:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  10614c:	85 c0                	test   %eax,%eax
  10614e:	89 c7                	mov    %eax,%edi
  106150:	75 96                	jne    1060e8 <copyuvm+0x28>
      goto bad;
  }
  return d;

bad:
  freevm(d);
  106152:	89 34 24             	mov    %esi,(%esp)
  106155:	31 f6                	xor    %esi,%esi
  106157:	e8 e4 fe ff ff       	call   106040 <freevm>
  return 0;
}
  10615c:	83 c4 2c             	add    $0x2c,%esp
  10615f:	89 f0                	mov    %esi,%eax
  106161:	5b                   	pop    %ebx
  106162:	5e                   	pop    %esi
  106163:	5f                   	pop    %edi
  106164:	5d                   	pop    %ebp
  106165:	c3                   	ret    

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walkpgdir(pgdir, (void*)i, 0)) == 0)
      panic("copyuvm: pte should exist");
  106166:	c7 04 24 41 6d 10 00 	movl   $0x106d41,(%esp)
  10616d:	e8 ae a7 ff ff       	call   100920 <panic>
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
  106172:	c7 04 24 5b 6d 10 00 	movl   $0x106d5b,(%esp)
  106179:	e8 a2 a7 ff ff       	call   100920 <panic>
  10617e:	66 90                	xchg   %ax,%ax

00106180 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
  106180:	55                   	push   %ebp
  char *mem;
  uint a;

  if(newsz > USERTOP)
  106181:	31 c0                	xor    %eax,%eax

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
  106183:	89 e5                	mov    %esp,%ebp
  106185:	57                   	push   %edi
  106186:	56                   	push   %esi
  106187:	53                   	push   %ebx
  106188:	83 ec 2c             	sub    $0x2c,%esp
  10618b:	8b 75 10             	mov    0x10(%ebp),%esi
  10618e:	8b 7d 08             	mov    0x8(%ebp),%edi
  char *mem;
  uint a;

  if(newsz > USERTOP)
  106191:	81 fe 00 00 0a 00    	cmp    $0xa0000,%esi
  106197:	0f 87 8e 00 00 00    	ja     10622b <allocuvm+0xab>
    return 0;
  if(newsz < oldsz)
    return oldsz;
  10619d:	8b 45 0c             	mov    0xc(%ebp),%eax
  char *mem;
  uint a;

  if(newsz > USERTOP)
    return 0;
  if(newsz < oldsz)
  1061a0:	39 c6                	cmp    %eax,%esi
  1061a2:	0f 82 83 00 00 00    	jb     10622b <allocuvm+0xab>
    return oldsz;

  a = PGROUNDUP(oldsz);
  1061a8:	89 c3                	mov    %eax,%ebx
  1061aa:	81 c3 ff 0f 00 00    	add    $0xfff,%ebx
  1061b0:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
  1061b6:	39 de                	cmp    %ebx,%esi
  1061b8:	77 47                	ja     106201 <allocuvm+0x81>
  1061ba:	eb 7c                	jmp    106238 <allocuvm+0xb8>
  1061bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    if(mem == 0){
      cprintf("allocuvm out of memory\n");
      deallocuvm(pgdir, newsz, oldsz);
      return 0;
    }
    memset(mem, 0, PGSIZE);
  1061c0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1061c7:	00 
  1061c8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1061cf:	00 
  1061d0:	89 04 24             	mov    %eax,(%esp)
  1061d3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1061d6:	e8 15 da ff ff       	call   103bf0 <memset>
    mappages(pgdir, (char*)a, PGSIZE, PADDR(mem), PTE_W|PTE_U);
  1061db:	b9 00 10 00 00       	mov    $0x1000,%ecx
  1061e0:	89 f8                	mov    %edi,%eax
  1061e2:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
  1061e9:	00 
  1061ea:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1061ed:	89 14 24             	mov    %edx,(%esp)
  1061f0:	89 da                	mov    %ebx,%edx
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
  1061f2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
      cprintf("allocuvm out of memory\n");
      deallocuvm(pgdir, newsz, oldsz);
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, PADDR(mem), PTE_W|PTE_U);
  1061f8:	e8 03 fc ff ff       	call   105e00 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
  1061fd:	39 de                	cmp    %ebx,%esi
  1061ff:	76 37                	jbe    106238 <allocuvm+0xb8>
    mem = kalloc();
  106201:	e8 4a c0 ff ff       	call   102250 <kalloc>
    if(mem == 0){
  106206:	85 c0                	test   %eax,%eax
  106208:	75 b6                	jne    1061c0 <allocuvm+0x40>
      cprintf("allocuvm out of memory\n");
  10620a:	c7 04 24 75 6d 10 00 	movl   $0x106d75,(%esp)
  106211:	e8 1a a3 ff ff       	call   100530 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
  106216:	8b 45 0c             	mov    0xc(%ebp),%eax
  106219:	89 74 24 04          	mov    %esi,0x4(%esp)
  10621d:	89 3c 24             	mov    %edi,(%esp)
  106220:	89 44 24 08          	mov    %eax,0x8(%esp)
  106224:	e8 87 fd ff ff       	call   105fb0 <deallocuvm>
  106229:	31 c0                	xor    %eax,%eax
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, PADDR(mem), PTE_W|PTE_U);
  }
  return newsz;
}
  10622b:	83 c4 2c             	add    $0x2c,%esp
  10622e:	5b                   	pop    %ebx
  10622f:	5e                   	pop    %esi
  106230:	5f                   	pop    %edi
  106231:	5d                   	pop    %ebp
  106232:	c3                   	ret    
  106233:	90                   	nop
  106234:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  106238:	83 c4 2c             	add    $0x2c,%esp
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, PADDR(mem), PTE_W|PTE_U);
  }
  return newsz;
  10623b:	89 f0                	mov    %esi,%eax
}
  10623d:	5b                   	pop    %ebx
  10623e:	5e                   	pop    %esi
  10623f:	5f                   	pop    %edi
  106240:	5d                   	pop    %ebp
  106241:	c3                   	ret    
  106242:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  106249:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00106250 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
  106250:	55                   	push   %ebp
  106251:	89 e5                	mov    %esp,%ebp
  106253:	57                   	push   %edi
  106254:	56                   	push   %esi
  106255:	53                   	push   %ebx
  106256:	83 ec 3c             	sub    $0x3c,%esp
  106259:	8b 7d 0c             	mov    0xc(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint)addr % PGSIZE != 0)
  10625c:	f7 c7 ff 0f 00 00    	test   $0xfff,%edi
  106262:	0f 85 96 00 00 00    	jne    1062fe <loaduvm+0xae>
    panic("loaduvm: addr must be page aligned");
  106268:	8b 75 18             	mov    0x18(%ebp),%esi
  10626b:	31 db                	xor    %ebx,%ebx
  for(i = 0; i < sz; i += PGSIZE){
  10626d:	85 f6                	test   %esi,%esi
  10626f:	74 77                	je     1062e8 <loaduvm+0x98>
  106271:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  106274:	eb 13                	jmp    106289 <loaduvm+0x39>
  106276:	66 90                	xchg   %ax,%ax
  106278:	81 c3 00 10 00 00    	add    $0x1000,%ebx
  10627e:	81 ee 00 10 00 00    	sub    $0x1000,%esi
  106284:	39 5d 18             	cmp    %ebx,0x18(%ebp)
  106287:	76 5f                	jbe    1062e8 <loaduvm+0x98>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
  106289:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10628c:	31 c9                	xor    %ecx,%ecx
  10628e:	8b 45 08             	mov    0x8(%ebp),%eax
  106291:	01 da                	add    %ebx,%edx
  106293:	e8 18 fa ff ff       	call   105cb0 <walkpgdir>
  106298:	85 c0                	test   %eax,%eax
  10629a:	74 56                	je     1062f2 <loaduvm+0xa2>
      panic("loaduvm: address should exist");
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
  10629c:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
  if((uint)addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
    pa = PTE_ADDR(*pte);
  1062a2:	8b 00                	mov    (%eax),%eax
    if(sz - i < PGSIZE)
  1062a4:	ba 00 10 00 00       	mov    $0x1000,%edx
  1062a9:	77 02                	ja     1062ad <loaduvm+0x5d>
  1062ab:	89 f2                	mov    %esi,%edx
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, (char*)pa, offset+i, n) != n)
  1062ad:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1062b1:	8b 7d 14             	mov    0x14(%ebp),%edi
  1062b4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1062b9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1062bd:	8d 0c 3b             	lea    (%ebx,%edi,1),%ecx
  1062c0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  1062c4:	8b 45 10             	mov    0x10(%ebp),%eax
  1062c7:	89 04 24             	mov    %eax,(%esp)
  1062ca:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  1062cd:	e8 9e b0 ff ff       	call   101370 <readi>
  1062d2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1062d5:	39 d0                	cmp    %edx,%eax
  1062d7:	74 9f                	je     106278 <loaduvm+0x28>
      return -1;
  }
  return 0;
}
  1062d9:	83 c4 3c             	add    $0x3c,%esp
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, (char*)pa, offset+i, n) != n)
  1062dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
      return -1;
  }
  return 0;
}
  1062e1:	5b                   	pop    %ebx
  1062e2:	5e                   	pop    %esi
  1062e3:	5f                   	pop    %edi
  1062e4:	5d                   	pop    %ebp
  1062e5:	c3                   	ret    
  1062e6:	66 90                	xchg   %ax,%ax
  1062e8:	83 c4 3c             	add    $0x3c,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint)addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
  1062eb:	31 c0                	xor    %eax,%eax
      n = PGSIZE;
    if(readi(ip, (char*)pa, offset+i, n) != n)
      return -1;
  }
  return 0;
}
  1062ed:	5b                   	pop    %ebx
  1062ee:	5e                   	pop    %esi
  1062ef:	5f                   	pop    %edi
  1062f0:	5d                   	pop    %ebp
  1062f1:	c3                   	ret    

  if((uint)addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
  1062f2:	c7 04 24 8d 6d 10 00 	movl   $0x106d8d,(%esp)
  1062f9:	e8 22 a6 ff ff       	call   100920 <panic>
{
  uint i, pa, n;
  pte_t *pte;

  if((uint)addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  1062fe:	c7 04 24 c0 6d 10 00 	movl   $0x106dc0,(%esp)
  106305:	e8 16 a6 ff ff       	call   100920 <panic>
  10630a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

00106310 <switchuvm>:
}

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
  106310:	55                   	push   %ebp
  106311:	89 e5                	mov    %esp,%ebp
  106313:	53                   	push   %ebx
  106314:	83 ec 14             	sub    $0x14,%esp
  106317:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
  10631a:	e8 41 d7 ff ff       	call   103a60 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
  10631f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  106325:	8d 50 08             	lea    0x8(%eax),%edx
  106328:	89 d1                	mov    %edx,%ecx
  10632a:	66 89 90 a2 00 00 00 	mov    %dx,0xa2(%eax)
  106331:	c1 e9 10             	shr    $0x10,%ecx
  106334:	c1 ea 18             	shr    $0x18,%edx
  106337:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
  10633d:	c6 80 a5 00 00 00 99 	movb   $0x99,0xa5(%eax)
  106344:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  10634a:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
  106351:	67 00 
  106353:	c6 80 a6 00 00 00 40 	movb   $0x40,0xa6(%eax)
  cpu->gdt[SEG_TSS].s = 0;
  10635a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  106360:	80 a0 a5 00 00 00 ef 	andb   $0xef,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
  106367:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  10636d:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
  106373:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  106379:	8b 50 08             	mov    0x8(%eax),%edx
  10637c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  106382:	81 c2 00 10 00 00    	add    $0x1000,%edx
  106388:	89 50 0c             	mov    %edx,0xc(%eax)
}

static inline void
ltr(ushort sel)
{
  asm volatile("ltr %0" : : "r" (sel));
  10638b:	b8 30 00 00 00       	mov    $0x30,%eax
  106390:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  if(p->pgdir == 0)
  106393:	8b 43 04             	mov    0x4(%ebx),%eax
  106396:	85 c0                	test   %eax,%eax
  106398:	74 0d                	je     1063a7 <switchuvm+0x97>
}

static inline void
lcr3(uint val) 
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
  10639a:	0f 22 d8             	mov    %eax,%cr3
    panic("switchuvm: no pgdir");
  lcr3(PADDR(p->pgdir));  // switch to new address space
  popcli();
}
  10639d:	83 c4 14             	add    $0x14,%esp
  1063a0:	5b                   	pop    %ebx
  1063a1:	5d                   	pop    %ebp
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
  ltr(SEG_TSS << 3);
  if(p->pgdir == 0)
    panic("switchuvm: no pgdir");
  lcr3(PADDR(p->pgdir));  // switch to new address space
  popcli();
  1063a2:	e9 f9 d6 ff ff       	jmp    103aa0 <popcli>
  cpu->gdt[SEG_TSS].s = 0;
  cpu->ts.ss0 = SEG_KDATA << 3;
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
  ltr(SEG_TSS << 3);
  if(p->pgdir == 0)
    panic("switchuvm: no pgdir");
  1063a7:	c7 04 24 ab 6d 10 00 	movl   $0x106dab,(%esp)
  1063ae:	e8 6d a5 ff ff       	call   100920 <panic>
  1063b3:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1063b9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

001063c0 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once at boot time on each CPU.
void
seginit(void)
{
  1063c0:	55                   	push   %ebp
  1063c1:	89 e5                	mov    %esp,%ebp
  1063c3:	83 ec 18             	sub    $0x18,%esp

  // Map virtual addresses to linear addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
  1063c6:	e8 65 c1 ff ff       	call   102530 <cpunum>
  1063cb:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
  1063d1:	05 20 bb 10 00       	add    $0x10bb20,%eax
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
  1063d6:	8d 90 b4 00 00 00    	lea    0xb4(%eax),%edx
  1063dc:	66 89 90 8a 00 00 00 	mov    %dx,0x8a(%eax)
  1063e3:	89 d1                	mov    %edx,%ecx
  1063e5:	c1 ea 18             	shr    $0x18,%edx
  1063e8:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)
  1063ee:	c1 e9 10             	shr    $0x10,%ecx

  lgdt(c->gdt, sizeof(c->gdt));
  1063f1:	8d 50 70             	lea    0x70(%eax),%edx
  // Map virtual addresses to linear addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
  1063f4:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
  1063fa:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
  106400:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
  106404:	c6 40 7d 9a          	movb   $0x9a,0x7d(%eax)
  106408:	c6 40 7e cf          	movb   $0xcf,0x7e(%eax)
  10640c:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
  106410:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
  106417:	ff ff 
  106419:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
  106420:	00 00 
  106422:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
  106429:	c6 80 85 00 00 00 92 	movb   $0x92,0x85(%eax)
  106430:	c6 80 86 00 00 00 cf 	movb   $0xcf,0x86(%eax)
  106437:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
  10643e:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
  106445:	ff ff 
  106447:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
  10644e:	00 00 
  106450:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
  106457:	c6 80 95 00 00 00 fa 	movb   $0xfa,0x95(%eax)
  10645e:	c6 80 96 00 00 00 cf 	movb   $0xcf,0x96(%eax)
  106465:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
  10646c:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
  106473:	ff ff 
  106475:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
  10647c:	00 00 
  10647e:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
  106485:	c6 80 9d 00 00 00 f2 	movb   $0xf2,0x9d(%eax)
  10648c:	c6 80 9e 00 00 00 cf 	movb   $0xcf,0x9e(%eax)
  106493:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
  10649a:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
  1064a1:	00 00 
  1064a3:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
  1064a9:	c6 80 8d 00 00 00 92 	movb   $0x92,0x8d(%eax)
  1064b0:	c6 80 8e 00 00 00 c0 	movb   $0xc0,0x8e(%eax)
static inline void
lgdt(struct segdesc *p, int size)
{
  volatile ushort pd[3];

  pd[0] = size-1;
  1064b7:	66 c7 45 f2 37 00    	movw   $0x37,-0xe(%ebp)
  pd[1] = (uint)p;
  1064bd:	66 89 55 f4          	mov    %dx,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
  1064c1:	c1 ea 10             	shr    $0x10,%edx
  1064c4:	66 89 55 f6          	mov    %dx,-0xa(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
  1064c8:	8d 55 f2             	lea    -0xe(%ebp),%edx
  1064cb:	0f 01 12             	lgdtl  (%edx)
}

static inline void
loadgs(ushort v)
{
  asm volatile("movw %0, %%gs" : : "r" (v));
  1064ce:	ba 18 00 00 00       	mov    $0x18,%edx
  1064d3:	8e ea                	mov    %edx,%gs

  lgdt(c->gdt, sizeof(c->gdt));
  loadgs(SEG_KCPU << 3);
  
  // Initialize cpu-local storage.
  cpu = c;
  1064d5:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
  1064db:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
  1064e2:	00 00 00 00 
}
  1064e6:	c9                   	leave  
  1064e7:	c3                   	ret    
