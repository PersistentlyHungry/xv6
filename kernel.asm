
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4 0f                	in     $0xf,%al

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 50 c6 10 80       	mov    $0x8010c650,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 5b 35 10 80       	mov    $0x8010355b,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 20 83 10 	movl   $0x80108320,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 94 4c 00 00       	call   80104ce2 <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 90 db 10 80 84 	movl   $0x8010db84,0x8010db90
80100055:	db 10 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 94 db 10 80 84 	movl   $0x8010db84,0x8010db94
8010005f:	db 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 c6 10 80 	movl   $0x8010c694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 94 db 10 80    	mov    0x8010db94,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 84 db 10 80 	movl   $0x8010db84,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 94 db 10 80       	mov    0x8010db94,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 94 db 10 80       	mov    %eax,0x8010db94

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
801000ac:	72 bd                	jb     8010006b <binit+0x37>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000ae:	c9                   	leave  
801000af:	c3                   	ret    

801000b0 <bget>:
// Look through buffer cache for sector on device dev.
// If not found, allocate fresh block.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint sector)
{
801000b0:	55                   	push   %ebp
801000b1:	89 e5                	mov    %esp,%ebp
801000b3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000b6:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801000bd:	e8 41 4c 00 00       	call   80104d03 <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 94 db 10 80       	mov    0x8010db94,%eax
801000c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000ca:	eb 63                	jmp    8010012f <bget+0x7f>
    if(b->dev == dev && b->sector == sector){
801000cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000cf:	8b 40 04             	mov    0x4(%eax),%eax
801000d2:	3b 45 08             	cmp    0x8(%ebp),%eax
801000d5:	75 4f                	jne    80100126 <bget+0x76>
801000d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000da:	8b 40 08             	mov    0x8(%eax),%eax
801000dd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000e0:	75 44                	jne    80100126 <bget+0x76>
      if(!(b->flags & B_BUSY)){
801000e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e5:	8b 00                	mov    (%eax),%eax
801000e7:	83 e0 01             	and    $0x1,%eax
801000ea:	85 c0                	test   %eax,%eax
801000ec:	75 23                	jne    80100111 <bget+0x61>
        b->flags |= B_BUSY;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 00                	mov    (%eax),%eax
801000f3:	89 c2                	mov    %eax,%edx
801000f5:	83 ca 01             	or     $0x1,%edx
801000f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fb:	89 10                	mov    %edx,(%eax)
        release(&bcache.lock);
801000fd:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100104:	e8 5c 4c 00 00       	call   80104d65 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 01 49 00 00       	call   80104a25 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 90 db 10 80       	mov    0x8010db90,%eax
8010013d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100140:	eb 4d                	jmp    8010018f <bget+0xdf>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
80100142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100145:	8b 00                	mov    (%eax),%eax
80100147:	83 e0 01             	and    $0x1,%eax
8010014a:	85 c0                	test   %eax,%eax
8010014c:	75 38                	jne    80100186 <bget+0xd6>
8010014e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100151:	8b 00                	mov    (%eax),%eax
80100153:	83 e0 04             	and    $0x4,%eax
80100156:	85 c0                	test   %eax,%eax
80100158:	75 2c                	jne    80100186 <bget+0xd6>
      b->dev = dev;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 08             	mov    0x8(%ebp),%edx
80100160:	89 50 04             	mov    %edx,0x4(%eax)
      b->sector = sector;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	8b 55 0c             	mov    0xc(%ebp),%edx
80100169:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = B_BUSY;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      release(&bcache.lock);
80100175:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010017c:	e8 e4 4b 00 00       	call   80104d65 <release>
      return b;
80100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100184:	eb 1e                	jmp    801001a4 <bget+0xf4>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100189:	8b 40 0c             	mov    0xc(%eax),%eax
8010018c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010018f:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 27 83 10 80 	movl   $0x80108327,(%esp)
8010019f:	e8 a2 03 00 00       	call   80100546 <panic>
}
801001a4:	c9                   	leave  
801001a5:	c3                   	ret    

801001a6 <bread>:

// Return a B_BUSY buf with the contents of the indicated disk sector.
struct buf*
bread(uint dev, uint sector)
{
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, sector);
801001ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801001af:	89 44 24 04          	mov    %eax,0x4(%esp)
801001b3:	8b 45 08             	mov    0x8(%ebp),%eax
801001b6:	89 04 24             	mov    %eax,(%esp)
801001b9:	e8 f2 fe ff ff       	call   801000b0 <bget>
801001be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!(b->flags & B_VALID))
801001c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001c4:	8b 00                	mov    (%eax),%eax
801001c6:	83 e0 02             	and    $0x2,%eax
801001c9:	85 c0                	test   %eax,%eax
801001cb:	75 0b                	jne    801001d8 <bread+0x32>
    iderw(b);
801001cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d0:	89 04 24             	mov    %eax,(%esp)
801001d3:	e8 24 27 00 00       	call   801028fc <iderw>
  return b;
801001d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001db:	c9                   	leave  
801001dc:	c3                   	ret    

801001dd <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
801001dd:	55                   	push   %ebp
801001de:	89 e5                	mov    %esp,%ebp
801001e0:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
801001e3:	8b 45 08             	mov    0x8(%ebp),%eax
801001e6:	8b 00                	mov    (%eax),%eax
801001e8:	83 e0 01             	and    $0x1,%eax
801001eb:	85 c0                	test   %eax,%eax
801001ed:	75 0c                	jne    801001fb <bwrite+0x1e>
    panic("bwrite");
801001ef:	c7 04 24 38 83 10 80 	movl   $0x80108338,(%esp)
801001f6:	e8 4b 03 00 00       	call   80100546 <panic>
  b->flags |= B_DIRTY;
801001fb:	8b 45 08             	mov    0x8(%ebp),%eax
801001fe:	8b 00                	mov    (%eax),%eax
80100200:	89 c2                	mov    %eax,%edx
80100202:	83 ca 04             	or     $0x4,%edx
80100205:	8b 45 08             	mov    0x8(%ebp),%eax
80100208:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010020a:	8b 45 08             	mov    0x8(%ebp),%eax
8010020d:	89 04 24             	mov    %eax,(%esp)
80100210:	e8 e7 26 00 00       	call   801028fc <iderw>
}
80100215:	c9                   	leave  
80100216:	c3                   	ret    

80100217 <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100217:	55                   	push   %ebp
80100218:	89 e5                	mov    %esp,%ebp
8010021a:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
8010021d:	8b 45 08             	mov    0x8(%ebp),%eax
80100220:	8b 00                	mov    (%eax),%eax
80100222:	83 e0 01             	and    $0x1,%eax
80100225:	85 c0                	test   %eax,%eax
80100227:	75 0c                	jne    80100235 <brelse+0x1e>
    panic("brelse");
80100229:	c7 04 24 3f 83 10 80 	movl   $0x8010833f,(%esp)
80100230:	e8 11 03 00 00       	call   80100546 <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 c2 4a 00 00       	call   80104d03 <acquire>

  b->next->prev = b->prev;
80100241:	8b 45 08             	mov    0x8(%ebp),%eax
80100244:	8b 40 10             	mov    0x10(%eax),%eax
80100247:	8b 55 08             	mov    0x8(%ebp),%edx
8010024a:	8b 52 0c             	mov    0xc(%edx),%edx
8010024d:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	8b 40 0c             	mov    0xc(%eax),%eax
80100256:	8b 55 08             	mov    0x8(%ebp),%edx
80100259:	8b 52 10             	mov    0x10(%edx),%edx
8010025c:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
8010025f:	8b 15 94 db 10 80    	mov    0x8010db94,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 84 db 10 80 	movl   $0x8010db84,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 94 db 10 80       	mov    0x8010db94,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 94 db 10 80       	mov    %eax,0x8010db94

  b->flags &= ~B_BUSY;
80100288:	8b 45 08             	mov    0x8(%ebp),%eax
8010028b:	8b 00                	mov    (%eax),%eax
8010028d:	89 c2                	mov    %eax,%edx
8010028f:	83 e2 fe             	and    $0xfffffffe,%edx
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80100297:	8b 45 08             	mov    0x8(%ebp),%eax
8010029a:	89 04 24             	mov    %eax,(%esp)
8010029d:	e8 5c 48 00 00       	call   80104afe <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 b7 4a 00 00       	call   80104d65 <release>
}
801002ae:	c9                   	leave  
801002af:	c3                   	ret    

801002b0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002b0:	55                   	push   %ebp
801002b1:	89 e5                	mov    %esp,%ebp
801002b3:	53                   	push   %ebx
801002b4:	83 ec 14             	sub    $0x14,%esp
801002b7:	8b 45 08             	mov    0x8(%ebp),%eax
801002ba:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002be:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801002c2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801002c6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801002ca:	ec                   	in     (%dx),%al
801002cb:	89 c3                	mov    %eax,%ebx
801002cd:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801002d0:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801002d4:	83 c4 14             	add    $0x14,%esp
801002d7:	5b                   	pop    %ebx
801002d8:	5d                   	pop    %ebp
801002d9:	c3                   	ret    

801002da <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002da:	55                   	push   %ebp
801002db:	89 e5                	mov    %esp,%ebp
801002dd:	83 ec 08             	sub    $0x8,%esp
801002e0:	8b 55 08             	mov    0x8(%ebp),%edx
801002e3:	8b 45 0c             	mov    0xc(%ebp),%eax
801002e6:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801002ea:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801002ed:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801002f1:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801002f5:	ee                   	out    %al,(%dx)
}
801002f6:	c9                   	leave  
801002f7:	c3                   	ret    

801002f8 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801002f8:	55                   	push   %ebp
801002f9:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801002fb:	fa                   	cli    
}
801002fc:	5d                   	pop    %ebp
801002fd:	c3                   	ret    

801002fe <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
801002fe:	55                   	push   %ebp
801002ff:	89 e5                	mov    %esp,%ebp
80100301:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
80100304:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100308:	74 1c                	je     80100326 <printint+0x28>
8010030a:	8b 45 08             	mov    0x8(%ebp),%eax
8010030d:	c1 e8 1f             	shr    $0x1f,%eax
80100310:	0f b6 c0             	movzbl %al,%eax
80100313:	89 45 10             	mov    %eax,0x10(%ebp)
80100316:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010031a:	74 0a                	je     80100326 <printint+0x28>
    x = -xx;
8010031c:	8b 45 08             	mov    0x8(%ebp),%eax
8010031f:	f7 d8                	neg    %eax
80100321:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100324:	eb 06                	jmp    8010032c <printint+0x2e>
  else
    x = xx;
80100326:	8b 45 08             	mov    0x8(%ebp),%eax
80100329:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
8010032c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100333:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80100336:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100339:	ba 00 00 00 00       	mov    $0x0,%edx
8010033e:	f7 f1                	div    %ecx
80100340:	89 d0                	mov    %edx,%eax
80100342:	0f b6 80 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%eax
80100349:	8d 4d e0             	lea    -0x20(%ebp),%ecx
8010034c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010034f:	01 ca                	add    %ecx,%edx
80100351:	88 02                	mov    %al,(%edx)
80100353:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
80100357:	8b 55 0c             	mov    0xc(%ebp),%edx
8010035a:	89 55 d4             	mov    %edx,-0x2c(%ebp)
8010035d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100360:	ba 00 00 00 00       	mov    $0x0,%edx
80100365:	f7 75 d4             	divl   -0x2c(%ebp)
80100368:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010036b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010036f:	75 c2                	jne    80100333 <printint+0x35>

  if(sign)
80100371:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100375:	74 27                	je     8010039e <printint+0xa0>
    buf[i++] = '-';
80100377:	8d 55 e0             	lea    -0x20(%ebp),%edx
8010037a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010037d:	01 d0                	add    %edx,%eax
8010037f:	c6 00 2d             	movb   $0x2d,(%eax)
80100382:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
80100386:	eb 16                	jmp    8010039e <printint+0xa0>
    consputc(buf[i]);
80100388:	8d 55 e0             	lea    -0x20(%ebp),%edx
8010038b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010038e:	01 d0                	add    %edx,%eax
80100390:	0f b6 00             	movzbl (%eax),%eax
80100393:	0f be c0             	movsbl %al,%eax
80100396:	89 04 24             	mov    %eax,(%esp)
80100399:	e8 bb 03 00 00       	call   80100759 <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
8010039e:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
801003a2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801003a6:	79 e0                	jns    80100388 <printint+0x8a>
    consputc(buf[i]);
}
801003a8:	c9                   	leave  
801003a9:	c3                   	ret    

801003aa <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003aa:	55                   	push   %ebp
801003ab:	89 e5                	mov    %esp,%ebp
801003ad:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003b0:	a1 f4 b5 10 80       	mov    0x8010b5f4,%eax
801003b5:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003b8:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003bc:	74 0c                	je     801003ca <cprintf+0x20>
    acquire(&cons.lock);
801003be:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
801003c5:	e8 39 49 00 00       	call   80104d03 <acquire>

  if (fmt == 0)
801003ca:	8b 45 08             	mov    0x8(%ebp),%eax
801003cd:	85 c0                	test   %eax,%eax
801003cf:	75 0c                	jne    801003dd <cprintf+0x33>
    panic("null fmt");
801003d1:	c7 04 24 46 83 10 80 	movl   $0x80108346,(%esp)
801003d8:	e8 69 01 00 00       	call   80100546 <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003dd:	8d 45 0c             	lea    0xc(%ebp),%eax
801003e0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003e3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003ea:	e9 20 01 00 00       	jmp    8010050f <cprintf+0x165>
    if(c != '%'){
801003ef:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003f3:	74 10                	je     80100405 <cprintf+0x5b>
      consputc(c);
801003f5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003f8:	89 04 24             	mov    %eax,(%esp)
801003fb:	e8 59 03 00 00       	call   80100759 <consputc>
      continue;
80100400:	e9 06 01 00 00       	jmp    8010050b <cprintf+0x161>
    }
    c = fmt[++i] & 0xff;
80100405:	8b 55 08             	mov    0x8(%ebp),%edx
80100408:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010040c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010040f:	01 d0                	add    %edx,%eax
80100411:	0f b6 00             	movzbl (%eax),%eax
80100414:	0f be c0             	movsbl %al,%eax
80100417:	25 ff 00 00 00       	and    $0xff,%eax
8010041c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
8010041f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100423:	0f 84 08 01 00 00    	je     80100531 <cprintf+0x187>
      break;
    switch(c){
80100429:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010042c:	83 f8 70             	cmp    $0x70,%eax
8010042f:	74 4d                	je     8010047e <cprintf+0xd4>
80100431:	83 f8 70             	cmp    $0x70,%eax
80100434:	7f 13                	jg     80100449 <cprintf+0x9f>
80100436:	83 f8 25             	cmp    $0x25,%eax
80100439:	0f 84 a6 00 00 00    	je     801004e5 <cprintf+0x13b>
8010043f:	83 f8 64             	cmp    $0x64,%eax
80100442:	74 14                	je     80100458 <cprintf+0xae>
80100444:	e9 aa 00 00 00       	jmp    801004f3 <cprintf+0x149>
80100449:	83 f8 73             	cmp    $0x73,%eax
8010044c:	74 53                	je     801004a1 <cprintf+0xf7>
8010044e:	83 f8 78             	cmp    $0x78,%eax
80100451:	74 2b                	je     8010047e <cprintf+0xd4>
80100453:	e9 9b 00 00 00       	jmp    801004f3 <cprintf+0x149>
    case 'd':
      printint(*argp++, 10, 1);
80100458:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010045b:	8b 00                	mov    (%eax),%eax
8010045d:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
80100461:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80100468:	00 
80100469:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100470:	00 
80100471:	89 04 24             	mov    %eax,(%esp)
80100474:	e8 85 fe ff ff       	call   801002fe <printint>
      break;
80100479:	e9 8d 00 00 00       	jmp    8010050b <cprintf+0x161>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
8010047e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100481:	8b 00                	mov    (%eax),%eax
80100483:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
80100487:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010048e:	00 
8010048f:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80100496:	00 
80100497:	89 04 24             	mov    %eax,(%esp)
8010049a:	e8 5f fe ff ff       	call   801002fe <printint>
      break;
8010049f:	eb 6a                	jmp    8010050b <cprintf+0x161>
    case 's':
      if((s = (char*)*argp++) == 0)
801004a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801004a4:	8b 00                	mov    (%eax),%eax
801004a6:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004a9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004ad:	0f 94 c0             	sete   %al
801004b0:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
801004b4:	84 c0                	test   %al,%al
801004b6:	74 20                	je     801004d8 <cprintf+0x12e>
        s = "(null)";
801004b8:	c7 45 ec 4f 83 10 80 	movl   $0x8010834f,-0x14(%ebp)
      for(; *s; s++)
801004bf:	eb 17                	jmp    801004d8 <cprintf+0x12e>
        consputc(*s);
801004c1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004c4:	0f b6 00             	movzbl (%eax),%eax
801004c7:	0f be c0             	movsbl %al,%eax
801004ca:	89 04 24             	mov    %eax,(%esp)
801004cd:	e8 87 02 00 00       	call   80100759 <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004d2:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004d6:	eb 01                	jmp    801004d9 <cprintf+0x12f>
801004d8:	90                   	nop
801004d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004dc:	0f b6 00             	movzbl (%eax),%eax
801004df:	84 c0                	test   %al,%al
801004e1:	75 de                	jne    801004c1 <cprintf+0x117>
        consputc(*s);
      break;
801004e3:	eb 26                	jmp    8010050b <cprintf+0x161>
    case '%':
      consputc('%');
801004e5:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004ec:	e8 68 02 00 00       	call   80100759 <consputc>
      break;
801004f1:	eb 18                	jmp    8010050b <cprintf+0x161>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004f3:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004fa:	e8 5a 02 00 00       	call   80100759 <consputc>
      consputc(c);
801004ff:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100502:	89 04 24             	mov    %eax,(%esp)
80100505:	e8 4f 02 00 00       	call   80100759 <consputc>
      break;
8010050a:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
8010050b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010050f:	8b 55 08             	mov    0x8(%ebp),%edx
80100512:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100515:	01 d0                	add    %edx,%eax
80100517:	0f b6 00             	movzbl (%eax),%eax
8010051a:	0f be c0             	movsbl %al,%eax
8010051d:	25 ff 00 00 00       	and    $0xff,%eax
80100522:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80100525:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100529:	0f 85 c0 fe ff ff    	jne    801003ef <cprintf+0x45>
8010052f:	eb 01                	jmp    80100532 <cprintf+0x188>
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
80100531:	90                   	nop
      consputc(c);
      break;
    }
  }

  if(locking)
80100532:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80100536:	74 0c                	je     80100544 <cprintf+0x19a>
    release(&cons.lock);
80100538:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
8010053f:	e8 21 48 00 00       	call   80104d65 <release>
}
80100544:	c9                   	leave  
80100545:	c3                   	ret    

80100546 <panic>:

void
panic(char *s)
{
80100546:	55                   	push   %ebp
80100547:	89 e5                	mov    %esp,%ebp
80100549:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
8010054c:	e8 a7 fd ff ff       	call   801002f8 <cli>
  cons.locking = 0;
80100551:	c7 05 f4 b5 10 80 00 	movl   $0x0,0x8010b5f4
80100558:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
8010055b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100561:	0f b6 00             	movzbl (%eax),%eax
80100564:	0f b6 c0             	movzbl %al,%eax
80100567:	89 44 24 04          	mov    %eax,0x4(%esp)
8010056b:	c7 04 24 56 83 10 80 	movl   $0x80108356,(%esp)
80100572:	e8 33 fe ff ff       	call   801003aa <cprintf>
  cprintf(s);
80100577:	8b 45 08             	mov    0x8(%ebp),%eax
8010057a:	89 04 24             	mov    %eax,(%esp)
8010057d:	e8 28 fe ff ff       	call   801003aa <cprintf>
  cprintf("\n");
80100582:	c7 04 24 65 83 10 80 	movl   $0x80108365,(%esp)
80100589:	e8 1c fe ff ff       	call   801003aa <cprintf>
  getcallerpcs(&s, pcs);
8010058e:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100591:	89 44 24 04          	mov    %eax,0x4(%esp)
80100595:	8d 45 08             	lea    0x8(%ebp),%eax
80100598:	89 04 24             	mov    %eax,(%esp)
8010059b:	e8 14 48 00 00       	call   80104db4 <getcallerpcs>
  for(i=0; i<10; i++)
801005a0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801005a7:	eb 1b                	jmp    801005c4 <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005ac:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005b0:	89 44 24 04          	mov    %eax,0x4(%esp)
801005b4:	c7 04 24 67 83 10 80 	movl   $0x80108367,(%esp)
801005bb:	e8 ea fd ff ff       	call   801003aa <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005c0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005c4:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005c8:	7e df                	jle    801005a9 <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005ca:	c7 05 a0 b5 10 80 01 	movl   $0x1,0x8010b5a0
801005d1:	00 00 00 
  for(;;)
    ;
801005d4:	eb fe                	jmp    801005d4 <panic+0x8e>

801005d6 <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005d6:	55                   	push   %ebp
801005d7:	89 e5                	mov    %esp,%ebp
801005d9:	83 ec 28             	sub    $0x28,%esp
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005dc:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005e3:	00 
801005e4:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801005eb:	e8 ea fc ff ff       	call   801002da <outb>
  pos = inb(CRTPORT+1) << 8;
801005f0:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
801005f7:	e8 b4 fc ff ff       	call   801002b0 <inb>
801005fc:	0f b6 c0             	movzbl %al,%eax
801005ff:	c1 e0 08             	shl    $0x8,%eax
80100602:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
80100605:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010060c:	00 
8010060d:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100614:	e8 c1 fc ff ff       	call   801002da <outb>
  pos |= inb(CRTPORT+1);
80100619:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100620:	e8 8b fc ff ff       	call   801002b0 <inb>
80100625:	0f b6 c0             	movzbl %al,%eax
80100628:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
8010062b:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
8010062f:	75 30                	jne    80100661 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100631:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80100634:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100639:	89 c8                	mov    %ecx,%eax
8010063b:	f7 ea                	imul   %edx
8010063d:	c1 fa 05             	sar    $0x5,%edx
80100640:	89 c8                	mov    %ecx,%eax
80100642:	c1 f8 1f             	sar    $0x1f,%eax
80100645:	29 c2                	sub    %eax,%edx
80100647:	89 d0                	mov    %edx,%eax
80100649:	c1 e0 02             	shl    $0x2,%eax
8010064c:	01 d0                	add    %edx,%eax
8010064e:	c1 e0 04             	shl    $0x4,%eax
80100651:	89 ca                	mov    %ecx,%edx
80100653:	29 c2                	sub    %eax,%edx
80100655:	b8 50 00 00 00       	mov    $0x50,%eax
8010065a:	29 d0                	sub    %edx,%eax
8010065c:	01 45 f4             	add    %eax,-0xc(%ebp)
8010065f:	eb 32                	jmp    80100693 <cgaputc+0xbd>
  else if(c == BACKSPACE){
80100661:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
80100668:	75 0c                	jne    80100676 <cgaputc+0xa0>
    if(pos > 0) --pos;
8010066a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010066e:	7e 23                	jle    80100693 <cgaputc+0xbd>
80100670:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100674:	eb 1d                	jmp    80100693 <cgaputc+0xbd>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
80100676:	a1 00 90 10 80       	mov    0x80109000,%eax
8010067b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010067e:	01 d2                	add    %edx,%edx
80100680:	01 c2                	add    %eax,%edx
80100682:	8b 45 08             	mov    0x8(%ebp),%eax
80100685:	66 25 ff 00          	and    $0xff,%ax
80100689:	80 cc 07             	or     $0x7,%ah
8010068c:	66 89 02             	mov    %ax,(%edx)
8010068f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  
  if((pos/80) >= 24){  // Scroll up.
80100693:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
8010069a:	7e 53                	jle    801006ef <cgaputc+0x119>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
8010069c:	a1 00 90 10 80       	mov    0x80109000,%eax
801006a1:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
801006a7:	a1 00 90 10 80       	mov    0x80109000,%eax
801006ac:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006b3:	00 
801006b4:	89 54 24 04          	mov    %edx,0x4(%esp)
801006b8:	89 04 24             	mov    %eax,(%esp)
801006bb:	e8 71 49 00 00       	call   80105031 <memmove>
    pos -= 80;
801006c0:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006c4:	b8 80 07 00 00       	mov    $0x780,%eax
801006c9:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006cc:	01 c0                	add    %eax,%eax
801006ce:	8b 15 00 90 10 80    	mov    0x80109000,%edx
801006d4:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006d7:	01 c9                	add    %ecx,%ecx
801006d9:	01 ca                	add    %ecx,%edx
801006db:	89 44 24 08          	mov    %eax,0x8(%esp)
801006df:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006e6:	00 
801006e7:	89 14 24             	mov    %edx,(%esp)
801006ea:	e8 6f 48 00 00       	call   80104f5e <memset>
  }
  
  outb(CRTPORT, 14);
801006ef:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801006f6:	00 
801006f7:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801006fe:	e8 d7 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos>>8);
80100703:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100706:	c1 f8 08             	sar    $0x8,%eax
80100709:	0f b6 c0             	movzbl %al,%eax
8010070c:	89 44 24 04          	mov    %eax,0x4(%esp)
80100710:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100717:	e8 be fb ff ff       	call   801002da <outb>
  outb(CRTPORT, 15);
8010071c:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100723:	00 
80100724:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
8010072b:	e8 aa fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos);
80100730:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100733:	0f b6 c0             	movzbl %al,%eax
80100736:	89 44 24 04          	mov    %eax,0x4(%esp)
8010073a:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100741:	e8 94 fb ff ff       	call   801002da <outb>
  crt[pos] = ' ' | 0x0700;
80100746:	a1 00 90 10 80       	mov    0x80109000,%eax
8010074b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010074e:	01 d2                	add    %edx,%edx
80100750:	01 d0                	add    %edx,%eax
80100752:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
80100757:	c9                   	leave  
80100758:	c3                   	ret    

80100759 <consputc>:

void
consputc(int c)
{
80100759:	55                   	push   %ebp
8010075a:	89 e5                	mov    %esp,%ebp
8010075c:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
8010075f:	a1 a0 b5 10 80       	mov    0x8010b5a0,%eax
80100764:	85 c0                	test   %eax,%eax
80100766:	74 07                	je     8010076f <consputc+0x16>
    cli();
80100768:	e8 8b fb ff ff       	call   801002f8 <cli>
    for(;;)
      ;
8010076d:	eb fe                	jmp    8010076d <consputc+0x14>
  }

  if(c == BACKSPACE){
8010076f:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
80100776:	75 26                	jne    8010079e <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
80100778:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010077f:	e8 e9 61 00 00       	call   8010696d <uartputc>
80100784:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010078b:	e8 dd 61 00 00       	call   8010696d <uartputc>
80100790:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100797:	e8 d1 61 00 00       	call   8010696d <uartputc>
8010079c:	eb 0b                	jmp    801007a9 <consputc+0x50>
  } else
    uartputc(c);
8010079e:	8b 45 08             	mov    0x8(%ebp),%eax
801007a1:	89 04 24             	mov    %eax,(%esp)
801007a4:	e8 c4 61 00 00       	call   8010696d <uartputc>
  cgaputc(c);
801007a9:	8b 45 08             	mov    0x8(%ebp),%eax
801007ac:	89 04 24             	mov    %eax,(%esp)
801007af:	e8 22 fe ff ff       	call   801005d6 <cgaputc>
}
801007b4:	c9                   	leave  
801007b5:	c3                   	ret    

801007b6 <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007b6:	55                   	push   %ebp
801007b7:	89 e5                	mov    %esp,%ebp
801007b9:	83 ec 28             	sub    $0x28,%esp
  int c;

  acquire(&input.lock);
801007bc:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
801007c3:	e8 3b 45 00 00       	call   80104d03 <acquire>
  while((c = getc()) >= 0){
801007c8:	e9 41 01 00 00       	jmp    8010090e <consoleintr+0x158>
    switch(c){
801007cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801007d0:	83 f8 10             	cmp    $0x10,%eax
801007d3:	74 1e                	je     801007f3 <consoleintr+0x3d>
801007d5:	83 f8 10             	cmp    $0x10,%eax
801007d8:	7f 0a                	jg     801007e4 <consoleintr+0x2e>
801007da:	83 f8 08             	cmp    $0x8,%eax
801007dd:	74 68                	je     80100847 <consoleintr+0x91>
801007df:	e9 94 00 00 00       	jmp    80100878 <consoleintr+0xc2>
801007e4:	83 f8 15             	cmp    $0x15,%eax
801007e7:	74 2f                	je     80100818 <consoleintr+0x62>
801007e9:	83 f8 7f             	cmp    $0x7f,%eax
801007ec:	74 59                	je     80100847 <consoleintr+0x91>
801007ee:	e9 85 00 00 00       	jmp    80100878 <consoleintr+0xc2>
    case C('P'):  // Process listing.
      procdump();
801007f3:	e8 a9 43 00 00       	call   80104ba1 <procdump>
      break;
801007f8:	e9 11 01 00 00       	jmp    8010090e <consoleintr+0x158>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007fd:	a1 5c de 10 80       	mov    0x8010de5c,%eax
80100802:	83 e8 01             	sub    $0x1,%eax
80100805:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(BACKSPACE);
8010080a:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100811:	e8 43 ff ff ff       	call   80100759 <consputc>
80100816:	eb 01                	jmp    80100819 <consoleintr+0x63>
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100818:	90                   	nop
80100819:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
8010081f:	a1 58 de 10 80       	mov    0x8010de58,%eax
80100824:	39 c2                	cmp    %eax,%edx
80100826:	0f 84 db 00 00 00    	je     80100907 <consoleintr+0x151>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
8010082c:	a1 5c de 10 80       	mov    0x8010de5c,%eax
80100831:	83 e8 01             	sub    $0x1,%eax
80100834:	83 e0 7f             	and    $0x7f,%eax
80100837:	0f b6 80 d4 dd 10 80 	movzbl -0x7fef222c(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
8010083e:	3c 0a                	cmp    $0xa,%al
80100840:	75 bb                	jne    801007fd <consoleintr+0x47>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100842:	e9 c0 00 00 00       	jmp    80100907 <consoleintr+0x151>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
80100847:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
8010084d:	a1 58 de 10 80       	mov    0x8010de58,%eax
80100852:	39 c2                	cmp    %eax,%edx
80100854:	0f 84 b0 00 00 00    	je     8010090a <consoleintr+0x154>
        input.e--;
8010085a:	a1 5c de 10 80       	mov    0x8010de5c,%eax
8010085f:	83 e8 01             	sub    $0x1,%eax
80100862:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(BACKSPACE);
80100867:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
8010086e:	e8 e6 fe ff ff       	call   80100759 <consputc>
      }
      break;
80100873:	e9 92 00 00 00       	jmp    8010090a <consoleintr+0x154>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
80100878:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010087c:	0f 84 8b 00 00 00    	je     8010090d <consoleintr+0x157>
80100882:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
80100888:	a1 54 de 10 80       	mov    0x8010de54,%eax
8010088d:	89 d1                	mov    %edx,%ecx
8010088f:	29 c1                	sub    %eax,%ecx
80100891:	89 c8                	mov    %ecx,%eax
80100893:	83 f8 7f             	cmp    $0x7f,%eax
80100896:	77 75                	ja     8010090d <consoleintr+0x157>
        c = (c == '\r') ? '\n' : c;
80100898:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
8010089c:	74 05                	je     801008a3 <consoleintr+0xed>
8010089e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008a1:	eb 05                	jmp    801008a8 <consoleintr+0xf2>
801008a3:	b8 0a 00 00 00       	mov    $0xa,%eax
801008a8:	89 45 f4             	mov    %eax,-0xc(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
801008ab:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008b0:	89 c1                	mov    %eax,%ecx
801008b2:	83 e1 7f             	and    $0x7f,%ecx
801008b5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801008b8:	88 91 d4 dd 10 80    	mov    %dl,-0x7fef222c(%ecx)
801008be:	83 c0 01             	add    $0x1,%eax
801008c1:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(c);
801008c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008c9:	89 04 24             	mov    %eax,(%esp)
801008cc:	e8 88 fe ff ff       	call   80100759 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008d1:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008d5:	74 18                	je     801008ef <consoleintr+0x139>
801008d7:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008db:	74 12                	je     801008ef <consoleintr+0x139>
801008dd:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008e2:	8b 15 54 de 10 80    	mov    0x8010de54,%edx
801008e8:	83 ea 80             	sub    $0xffffff80,%edx
801008eb:	39 d0                	cmp    %edx,%eax
801008ed:	75 1e                	jne    8010090d <consoleintr+0x157>
          input.w = input.e;
801008ef:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008f4:	a3 58 de 10 80       	mov    %eax,0x8010de58
          wakeup(&input.r);
801008f9:	c7 04 24 54 de 10 80 	movl   $0x8010de54,(%esp)
80100900:	e8 f9 41 00 00       	call   80104afe <wakeup>
        }
      }
      break;
80100905:	eb 06                	jmp    8010090d <consoleintr+0x157>
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100907:	90                   	nop
80100908:	eb 04                	jmp    8010090e <consoleintr+0x158>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
8010090a:	90                   	nop
8010090b:	eb 01                	jmp    8010090e <consoleintr+0x158>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
          input.w = input.e;
          wakeup(&input.r);
        }
      }
      break;
8010090d:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
8010090e:	8b 45 08             	mov    0x8(%ebp),%eax
80100911:	ff d0                	call   *%eax
80100913:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100916:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010091a:	0f 89 ad fe ff ff    	jns    801007cd <consoleintr+0x17>
        }
      }
      break;
    }
  }
  release(&input.lock);
80100920:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100927:	e8 39 44 00 00       	call   80104d65 <release>
}
8010092c:	c9                   	leave  
8010092d:	c3                   	ret    

8010092e <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
8010092e:	55                   	push   %ebp
8010092f:	89 e5                	mov    %esp,%ebp
80100931:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
80100934:	8b 45 08             	mov    0x8(%ebp),%eax
80100937:	89 04 24             	mov    %eax,(%esp)
8010093a:	e8 9f 11 00 00       	call   80101ade <iunlock>
  target = n;
8010093f:	8b 45 10             	mov    0x10(%ebp),%eax
80100942:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
80100945:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
8010094c:	e8 b2 43 00 00       	call   80104d03 <acquire>
  while(n > 0){
80100951:	e9 a8 00 00 00       	jmp    801009fe <consoleread+0xd0>
    while(input.r == input.w){
      if(proc->killed){
80100956:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010095c:	8b 40 24             	mov    0x24(%eax),%eax
8010095f:	85 c0                	test   %eax,%eax
80100961:	74 21                	je     80100984 <consoleread+0x56>
        release(&input.lock);
80100963:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
8010096a:	e8 f6 43 00 00       	call   80104d65 <release>
        ilock(ip);
8010096f:	8b 45 08             	mov    0x8(%ebp),%eax
80100972:	89 04 24             	mov    %eax,(%esp)
80100975:	e8 16 10 00 00       	call   80101990 <ilock>
        return -1;
8010097a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010097f:	e9 a9 00 00 00       	jmp    80100a2d <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
80100984:	c7 44 24 04 a0 dd 10 	movl   $0x8010dda0,0x4(%esp)
8010098b:	80 
8010098c:	c7 04 24 54 de 10 80 	movl   $0x8010de54,(%esp)
80100993:	e8 8d 40 00 00       	call   80104a25 <sleep>
80100998:	eb 01                	jmp    8010099b <consoleread+0x6d>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
8010099a:	90                   	nop
8010099b:	8b 15 54 de 10 80    	mov    0x8010de54,%edx
801009a1:	a1 58 de 10 80       	mov    0x8010de58,%eax
801009a6:	39 c2                	cmp    %eax,%edx
801009a8:	74 ac                	je     80100956 <consoleread+0x28>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009aa:	a1 54 de 10 80       	mov    0x8010de54,%eax
801009af:	89 c2                	mov    %eax,%edx
801009b1:	83 e2 7f             	and    $0x7f,%edx
801009b4:	0f b6 92 d4 dd 10 80 	movzbl -0x7fef222c(%edx),%edx
801009bb:	0f be d2             	movsbl %dl,%edx
801009be:	89 55 f0             	mov    %edx,-0x10(%ebp)
801009c1:	83 c0 01             	add    $0x1,%eax
801009c4:	a3 54 de 10 80       	mov    %eax,0x8010de54
    if(c == C('D')){  // EOF
801009c9:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801009cd:	75 17                	jne    801009e6 <consoleread+0xb8>
      if(n < target){
801009cf:	8b 45 10             	mov    0x10(%ebp),%eax
801009d2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801009d5:	73 2f                	jae    80100a06 <consoleread+0xd8>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
801009d7:	a1 54 de 10 80       	mov    0x8010de54,%eax
801009dc:	83 e8 01             	sub    $0x1,%eax
801009df:	a3 54 de 10 80       	mov    %eax,0x8010de54
      }
      break;
801009e4:	eb 20                	jmp    80100a06 <consoleread+0xd8>
    }
    *dst++ = c;
801009e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801009e9:	89 c2                	mov    %eax,%edx
801009eb:	8b 45 0c             	mov    0xc(%ebp),%eax
801009ee:	88 10                	mov    %dl,(%eax)
801009f0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
    --n;
801009f4:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
801009f8:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
801009fc:	74 0b                	je     80100a09 <consoleread+0xdb>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
801009fe:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100a02:	7f 96                	jg     8010099a <consoleread+0x6c>
80100a04:	eb 04                	jmp    80100a0a <consoleread+0xdc>
      if(n < target){
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
80100a06:	90                   	nop
80100a07:	eb 01                	jmp    80100a0a <consoleread+0xdc>
    }
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
80100a09:	90                   	nop
  }
  release(&input.lock);
80100a0a:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100a11:	e8 4f 43 00 00       	call   80104d65 <release>
  ilock(ip);
80100a16:	8b 45 08             	mov    0x8(%ebp),%eax
80100a19:	89 04 24             	mov    %eax,(%esp)
80100a1c:	e8 6f 0f 00 00       	call   80101990 <ilock>

  return target - n;
80100a21:	8b 45 10             	mov    0x10(%ebp),%eax
80100a24:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a27:	89 d1                	mov    %edx,%ecx
80100a29:	29 c1                	sub    %eax,%ecx
80100a2b:	89 c8                	mov    %ecx,%eax
}
80100a2d:	c9                   	leave  
80100a2e:	c3                   	ret    

80100a2f <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a2f:	55                   	push   %ebp
80100a30:	89 e5                	mov    %esp,%ebp
80100a32:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a35:	8b 45 08             	mov    0x8(%ebp),%eax
80100a38:	89 04 24             	mov    %eax,(%esp)
80100a3b:	e8 9e 10 00 00       	call   80101ade <iunlock>
  acquire(&cons.lock);
80100a40:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a47:	e8 b7 42 00 00       	call   80104d03 <acquire>
  for(i = 0; i < n; i++)
80100a4c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a53:	eb 1f                	jmp    80100a74 <consolewrite+0x45>
    consputc(buf[i] & 0xff);
80100a55:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a58:	8b 45 0c             	mov    0xc(%ebp),%eax
80100a5b:	01 d0                	add    %edx,%eax
80100a5d:	0f b6 00             	movzbl (%eax),%eax
80100a60:	0f be c0             	movsbl %al,%eax
80100a63:	25 ff 00 00 00       	and    $0xff,%eax
80100a68:	89 04 24             	mov    %eax,(%esp)
80100a6b:	e8 e9 fc ff ff       	call   80100759 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100a70:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a77:	3b 45 10             	cmp    0x10(%ebp),%eax
80100a7a:	7c d9                	jl     80100a55 <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100a7c:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a83:	e8 dd 42 00 00       	call   80104d65 <release>
  ilock(ip);
80100a88:	8b 45 08             	mov    0x8(%ebp),%eax
80100a8b:	89 04 24             	mov    %eax,(%esp)
80100a8e:	e8 fd 0e 00 00       	call   80101990 <ilock>

  return n;
80100a93:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100a96:	c9                   	leave  
80100a97:	c3                   	ret    

80100a98 <consoleinit>:

void
consoleinit(void)
{
80100a98:	55                   	push   %ebp
80100a99:	89 e5                	mov    %esp,%ebp
80100a9b:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100a9e:	c7 44 24 04 6b 83 10 	movl   $0x8010836b,0x4(%esp)
80100aa5:	80 
80100aa6:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100aad:	e8 30 42 00 00       	call   80104ce2 <initlock>
  initlock(&input.lock, "input");
80100ab2:	c7 44 24 04 73 83 10 	movl   $0x80108373,0x4(%esp)
80100ab9:	80 
80100aba:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100ac1:	e8 1c 42 00 00       	call   80104ce2 <initlock>

  devsw[CONSOLE].write = consolewrite;
80100ac6:	c7 05 2c ed 10 80 2f 	movl   $0x80100a2f,0x8010ed2c
80100acd:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ad0:	c7 05 28 ed 10 80 2e 	movl   $0x8010092e,0x8010ed28
80100ad7:	09 10 80 
  cons.locking = 1;
80100ada:	c7 05 f4 b5 10 80 01 	movl   $0x1,0x8010b5f4
80100ae1:	00 00 00 

  picenable(IRQ_KBD);
80100ae4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100aeb:	e8 29 31 00 00       	call   80103c19 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100af0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100af7:	00 
80100af8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100aff:	e8 ba 1f 00 00       	call   80102abe <ioapicenable>
}
80100b04:	c9                   	leave  
80100b05:	c3                   	ret    
80100b06:	66 90                	xchg   %ax,%ax

80100b08 <exec>:
char path_variable[MAX_PATH_ENTRIES][INPUT_BUF];
int path_variable_count = 1;

int
exec(char *path, char **argv)
{
80100b08:	55                   	push   %ebp
80100b09:	89 e5                	mov    %esp,%ebp
80100b0b:	56                   	push   %esi
80100b0c:	53                   	push   %ebx
80100b0d:	81 ec 50 01 00 00    	sub    $0x150,%esp
80100b13:	89 e0                	mov    %esp,%eax
80100b15:	89 c6                	mov    %eax,%esi
  safestrcpy(path_variable[0],"/os/",sizeof(path_variable[0]));
80100b17:	c7 44 24 08 81 00 00 	movl   $0x81,0x8(%esp)
80100b1e:	00 
80100b1f:	c7 44 24 04 79 83 10 	movl   $0x80108379,0x4(%esp)
80100b26:	80 
80100b27:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100b2e:	e8 5b 46 00 00       	call   8010518e <safestrcpy>
  int i, off;
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  int pathLength = strlen(path);
80100b33:	8b 45 08             	mov    0x8(%ebp),%eax
80100b36:	89 04 24             	mov    %eax,(%esp)
80100b39:	e8 9e 46 00 00       	call   801051dc <strlen>
80100b3e:	89 45 d0             	mov    %eax,-0x30(%ebp)
  char tempPath[pathLength+INPUT_BUF];
80100b41:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100b44:	05 81 00 00 00       	add    $0x81,%eax
80100b49:	8d 50 ff             	lea    -0x1(%eax),%edx
80100b4c:	89 55 cc             	mov    %edx,-0x34(%ebp)
80100b4f:	ba 10 00 00 00       	mov    $0x10,%edx
80100b54:	83 ea 01             	sub    $0x1,%edx
80100b57:	01 d0                	add    %edx,%eax
80100b59:	c7 85 d4 fe ff ff 10 	movl   $0x10,-0x12c(%ebp)
80100b60:	00 00 00 
80100b63:	ba 00 00 00 00       	mov    $0x0,%edx
80100b68:	f7 b5 d4 fe ff ff    	divl   -0x12c(%ebp)
80100b6e:	6b c0 10             	imul   $0x10,%eax,%eax
80100b71:	29 c4                	sub    %eax,%esp
80100b73:	8d 44 24 14          	lea    0x14(%esp),%eax
80100b77:	83 c0 00             	add    $0x0,%eax
80100b7a:	89 45 c8             	mov    %eax,-0x38(%ebp)
  pde_t *pgdir, *oldpgdir;

  if((ip = namei(path)) == 0)
80100b7d:	8b 45 08             	mov    0x8(%ebp),%eax
80100b80:	89 04 24             	mov    %eax,(%esp)
80100b83:	e8 c9 19 00 00       	call   80102551 <namei>
80100b88:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b8b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b8f:	0f 85 80 00 00 00    	jne    80100c15 <exec+0x10d>
    for(i=0;i<path_variable_count;i++)
80100b95:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100b9c:	eb 6d                	jmp    80100c0b <exec+0x103>
    {
      //
      safestrcpy(tempPath, path_variable[i], INPUT_BUF);
80100b9e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80100ba1:	89 d0                	mov    %edx,%eax
80100ba3:	c1 e0 07             	shl    $0x7,%eax
80100ba6:	01 d0                	add    %edx,%eax
80100ba8:	8d 90 60 de 10 80    	lea    -0x7fef21a0(%eax),%edx
80100bae:	8b 45 c8             	mov    -0x38(%ebp),%eax
80100bb1:	c7 44 24 08 81 00 00 	movl   $0x81,0x8(%esp)
80100bb8:	00 
80100bb9:	89 54 24 04          	mov    %edx,0x4(%esp)
80100bbd:	89 04 24             	mov    %eax,(%esp)
80100bc0:	e8 c9 45 00 00       	call   8010518e <safestrcpy>
      safestrcpy(&tempPath[strlen(tempPath)],path,(strlen(path)));
80100bc5:	8b 45 08             	mov    0x8(%ebp),%eax
80100bc8:	89 04 24             	mov    %eax,(%esp)
80100bcb:	e8 0c 46 00 00       	call   801051dc <strlen>
80100bd0:	89 c3                	mov    %eax,%ebx
80100bd2:	8b 45 c8             	mov    -0x38(%ebp),%eax
80100bd5:	89 04 24             	mov    %eax,(%esp)
80100bd8:	e8 ff 45 00 00       	call   801051dc <strlen>
80100bdd:	8b 55 c8             	mov    -0x38(%ebp),%edx
80100be0:	01 c2                	add    %eax,%edx
80100be2:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80100be6:	8b 45 08             	mov    0x8(%ebp),%eax
80100be9:	89 44 24 04          	mov    %eax,0x4(%esp)
80100bed:	89 14 24             	mov    %edx,(%esp)
80100bf0:	e8 99 45 00 00       	call   8010518e <safestrcpy>
      //panic(tempPath);
      if((ip = namei(tempPath)) != 0)
80100bf5:	8b 45 c8             	mov    -0x38(%ebp),%eax
80100bf8:	89 04 24             	mov    %eax,(%esp)
80100bfb:	e8 51 19 00 00       	call   80102551 <namei>
80100c00:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100c03:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  int pathLength = strlen(path);
  char tempPath[pathLength+INPUT_BUF];
  pde_t *pgdir, *oldpgdir;

  if((ip = namei(path)) == 0)
    for(i=0;i<path_variable_count;i++)
80100c07:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100c0b:	a1 18 90 10 80       	mov    0x80109018,%eax
80100c10:	39 45 ec             	cmp    %eax,-0x14(%ebp)
80100c13:	7c 89                	jl     80100b9e <exec+0x96>
      if((ip = namei(tempPath)) != 0)
      {
        continue;
      }
    }
  if(ip==0)
80100c15:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100c19:	75 0a                	jne    80100c25 <exec+0x11d>
      return -1;
80100c1b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100c20:	e9 f6 03 00 00       	jmp    8010101b <exec+0x513>
  ilock(ip);
80100c25:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c28:	89 04 24             	mov    %eax,(%esp)
80100c2b:	e8 60 0d 00 00       	call   80101990 <ilock>
  pgdir = 0;
80100c30:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100c37:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100c3e:	00 
80100c3f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100c46:	00 
80100c47:	8d 85 00 ff ff ff    	lea    -0x100(%ebp),%eax
80100c4d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c51:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c54:	89 04 24             	mov    %eax,(%esp)
80100c57:	e8 41 12 00 00       	call   80101e9d <readi>
80100c5c:	83 f8 33             	cmp    $0x33,%eax
80100c5f:	0f 86 70 03 00 00    	jbe    80100fd5 <exec+0x4cd>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100c65:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
80100c6b:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100c70:	0f 85 62 03 00 00    	jne    80100fd8 <exec+0x4d0>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
80100c76:	c7 04 24 47 2c 10 80 	movl   $0x80102c47,(%esp)
80100c7d:	e8 3d 6e 00 00       	call   80107abf <setupkvm>
80100c82:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100c85:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100c89:	0f 84 4c 03 00 00    	je     80100fdb <exec+0x4d3>
    goto bad;

  // Load program into memory.
  sz = 0;
80100c8f:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c96:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100c9d:	8b 85 1c ff ff ff    	mov    -0xe4(%ebp),%eax
80100ca3:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100ca6:	e9 c5 00 00 00       	jmp    80100d70 <exec+0x268>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100cab:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100cae:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100cb5:	00 
80100cb6:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cba:	8d 85 e0 fe ff ff    	lea    -0x120(%ebp),%eax
80100cc0:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cc4:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100cc7:	89 04 24             	mov    %eax,(%esp)
80100cca:	e8 ce 11 00 00       	call   80101e9d <readi>
80100ccf:	83 f8 20             	cmp    $0x20,%eax
80100cd2:	0f 85 06 03 00 00    	jne    80100fde <exec+0x4d6>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
80100cd8:	8b 85 e0 fe ff ff    	mov    -0x120(%ebp),%eax
80100cde:	83 f8 01             	cmp    $0x1,%eax
80100ce1:	75 7f                	jne    80100d62 <exec+0x25a>
      continue;
    if(ph.memsz < ph.filesz)
80100ce3:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80100ce9:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100cef:	39 c2                	cmp    %eax,%edx
80100cf1:	0f 82 ea 02 00 00    	jb     80100fe1 <exec+0x4d9>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100cf7:	8b 95 e8 fe ff ff    	mov    -0x118(%ebp),%edx
80100cfd:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
80100d03:	01 d0                	add    %edx,%eax
80100d05:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d09:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d0c:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d10:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d13:	89 04 24             	mov    %eax,(%esp)
80100d16:	e8 76 71 00 00       	call   80107e91 <allocuvm>
80100d1b:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d1e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100d22:	0f 84 bc 02 00 00    	je     80100fe4 <exec+0x4dc>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100d28:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100d2e:	8b 95 e4 fe ff ff    	mov    -0x11c(%ebp),%edx
80100d34:	8b 85 e8 fe ff ff    	mov    -0x118(%ebp),%eax
80100d3a:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100d3e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d42:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100d45:	89 54 24 08          	mov    %edx,0x8(%esp)
80100d49:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d4d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d50:	89 04 24             	mov    %eax,(%esp)
80100d53:	e8 4a 70 00 00       	call   80107da2 <loaduvm>
80100d58:	85 c0                	test   %eax,%eax
80100d5a:	0f 88 87 02 00 00    	js     80100fe7 <exec+0x4df>
80100d60:	eb 01                	jmp    80100d63 <exec+0x25b>
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
80100d62:	90                   	nop
  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100d63:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100d67:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100d6a:	83 c0 20             	add    $0x20,%eax
80100d6d:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d70:	0f b7 85 2c ff ff ff 	movzwl -0xd4(%ebp),%eax
80100d77:	0f b7 c0             	movzwl %ax,%eax
80100d7a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100d7d:	0f 8f 28 ff ff ff    	jg     80100cab <exec+0x1a3>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100d83:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100d86:	89 04 24             	mov    %eax,(%esp)
80100d89:	e8 86 0e 00 00       	call   80101c14 <iunlockput>
  ip = 0;
80100d8e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100d95:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d98:	05 ff 0f 00 00       	add    $0xfff,%eax
80100d9d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100da2:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100da5:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100da8:	05 00 20 00 00       	add    $0x2000,%eax
80100dad:	89 44 24 08          	mov    %eax,0x8(%esp)
80100db1:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100db4:	89 44 24 04          	mov    %eax,0x4(%esp)
80100db8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100dbb:	89 04 24             	mov    %eax,(%esp)
80100dbe:	e8 ce 70 00 00       	call   80107e91 <allocuvm>
80100dc3:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100dc6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100dca:	0f 84 1a 02 00 00    	je     80100fea <exec+0x4e2>
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100dd0:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100dd3:	2d 00 20 00 00       	sub    $0x2000,%eax
80100dd8:	89 44 24 04          	mov    %eax,0x4(%esp)
80100ddc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ddf:	89 04 24             	mov    %eax,(%esp)
80100de2:	e8 da 72 00 00       	call   801080c1 <clearpteu>
  sp = sz;
80100de7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100dea:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100ded:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100df4:	e9 97 00 00 00       	jmp    80100e90 <exec+0x388>
    if(argc >= MAXARG)
80100df9:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100dfd:	0f 87 ea 01 00 00    	ja     80100fed <exec+0x4e5>
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100e03:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e06:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e0d:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e10:	01 d0                	add    %edx,%eax
80100e12:	8b 00                	mov    (%eax),%eax
80100e14:	89 04 24             	mov    %eax,(%esp)
80100e17:	e8 c0 43 00 00       	call   801051dc <strlen>
80100e1c:	f7 d0                	not    %eax
80100e1e:	89 c2                	mov    %eax,%edx
80100e20:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e23:	01 d0                	add    %edx,%eax
80100e25:	83 e0 fc             	and    $0xfffffffc,%eax
80100e28:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100e2b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e2e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e35:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e38:	01 d0                	add    %edx,%eax
80100e3a:	8b 00                	mov    (%eax),%eax
80100e3c:	89 04 24             	mov    %eax,(%esp)
80100e3f:	e8 98 43 00 00       	call   801051dc <strlen>
80100e44:	83 c0 01             	add    $0x1,%eax
80100e47:	89 c2                	mov    %eax,%edx
80100e49:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e4c:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80100e53:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e56:	01 c8                	add    %ecx,%eax
80100e58:	8b 00                	mov    (%eax),%eax
80100e5a:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100e5e:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e62:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e65:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e69:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e6c:	89 04 24             	mov    %eax,(%esp)
80100e6f:	e8 01 74 00 00       	call   80108275 <copyout>
80100e74:	85 c0                	test   %eax,%eax
80100e76:	0f 88 74 01 00 00    	js     80100ff0 <exec+0x4e8>
      goto bad;
    ustack[3+argc] = sp;
80100e7c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e7f:	8d 50 03             	lea    0x3(%eax),%edx
80100e82:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e85:	89 84 95 34 ff ff ff 	mov    %eax,-0xcc(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100e8c:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100e90:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e93:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e9a:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e9d:	01 d0                	add    %edx,%eax
80100e9f:	8b 00                	mov    (%eax),%eax
80100ea1:	85 c0                	test   %eax,%eax
80100ea3:	0f 85 50 ff ff ff    	jne    80100df9 <exec+0x2f1>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100ea9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100eac:	83 c0 03             	add    $0x3,%eax
80100eaf:	c7 84 85 34 ff ff ff 	movl   $0x0,-0xcc(%ebp,%eax,4)
80100eb6:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100eba:	c7 85 34 ff ff ff ff 	movl   $0xffffffff,-0xcc(%ebp)
80100ec1:	ff ff ff 
  ustack[1] = argc;
80100ec4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100ec7:	89 85 38 ff ff ff    	mov    %eax,-0xc8(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100ecd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100ed0:	83 c0 01             	add    $0x1,%eax
80100ed3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100eda:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100edd:	29 d0                	sub    %edx,%eax
80100edf:	89 85 3c ff ff ff    	mov    %eax,-0xc4(%ebp)

  sp -= (3+argc+1) * 4;
80100ee5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100ee8:	83 c0 04             	add    $0x4,%eax
80100eeb:	c1 e0 02             	shl    $0x2,%eax
80100eee:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100ef1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100ef4:	83 c0 04             	add    $0x4,%eax
80100ef7:	c1 e0 02             	shl    $0x2,%eax
80100efa:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100efe:	8d 85 34 ff ff ff    	lea    -0xcc(%ebp),%eax
80100f04:	89 44 24 08          	mov    %eax,0x8(%esp)
80100f08:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100f0b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100f0f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100f12:	89 04 24             	mov    %eax,(%esp)
80100f15:	e8 5b 73 00 00       	call   80108275 <copyout>
80100f1a:	85 c0                	test   %eax,%eax
80100f1c:	0f 88 d1 00 00 00    	js     80100ff3 <exec+0x4eb>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100f22:	8b 45 08             	mov    0x8(%ebp),%eax
80100f25:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100f28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f2b:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100f2e:	eb 17                	jmp    80100f47 <exec+0x43f>
    if(*s == '/')
80100f30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f33:	0f b6 00             	movzbl (%eax),%eax
80100f36:	3c 2f                	cmp    $0x2f,%al
80100f38:	75 09                	jne    80100f43 <exec+0x43b>
      last = s+1;
80100f3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f3d:	83 c0 01             	add    $0x1,%eax
80100f40:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100f43:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100f47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f4a:	0f b6 00             	movzbl (%eax),%eax
80100f4d:	84 c0                	test   %al,%al
80100f4f:	75 df                	jne    80100f30 <exec+0x428>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100f51:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f57:	8d 50 6c             	lea    0x6c(%eax),%edx
80100f5a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100f61:	00 
80100f62:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100f65:	89 44 24 04          	mov    %eax,0x4(%esp)
80100f69:	89 14 24             	mov    %edx,(%esp)
80100f6c:	e8 1d 42 00 00       	call   8010518e <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100f71:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f77:	8b 40 04             	mov    0x4(%eax),%eax
80100f7a:	89 45 c4             	mov    %eax,-0x3c(%ebp)
  proc->pgdir = pgdir;
80100f7d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f83:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100f86:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100f89:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f8f:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100f92:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100f94:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f9a:	8b 40 18             	mov    0x18(%eax),%eax
80100f9d:	8b 95 18 ff ff ff    	mov    -0xe8(%ebp),%edx
80100fa3:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100fa6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fac:	8b 40 18             	mov    0x18(%eax),%eax
80100faf:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100fb2:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100fb5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fbb:	89 04 24             	mov    %eax,(%esp)
80100fbe:	e8 ed 6b 00 00       	call   80107bb0 <switchuvm>
  freevm(oldpgdir);
80100fc3:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80100fc6:	89 04 24             	mov    %eax,(%esp)
80100fc9:	e8 59 70 00 00       	call   80108027 <freevm>
  return 0;
80100fce:	b8 00 00 00 00       	mov    $0x0,%eax
80100fd3:	eb 46                	jmp    8010101b <exec+0x513>
  ilock(ip);
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
    goto bad;
80100fd5:	90                   	nop
80100fd6:	eb 1c                	jmp    80100ff4 <exec+0x4ec>
  if(elf.magic != ELF_MAGIC)
    goto bad;
80100fd8:	90                   	nop
80100fd9:	eb 19                	jmp    80100ff4 <exec+0x4ec>

  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;
80100fdb:	90                   	nop
80100fdc:	eb 16                	jmp    80100ff4 <exec+0x4ec>

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
80100fde:	90                   	nop
80100fdf:	eb 13                	jmp    80100ff4 <exec+0x4ec>
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
80100fe1:	90                   	nop
80100fe2:	eb 10                	jmp    80100ff4 <exec+0x4ec>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
80100fe4:	90                   	nop
80100fe5:	eb 0d                	jmp    80100ff4 <exec+0x4ec>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
80100fe7:	90                   	nop
80100fe8:	eb 0a                	jmp    80100ff4 <exec+0x4ec>

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
80100fea:	90                   	nop
80100feb:	eb 07                	jmp    80100ff4 <exec+0x4ec>
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
80100fed:	90                   	nop
80100fee:	eb 04                	jmp    80100ff4 <exec+0x4ec>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
80100ff0:	90                   	nop
80100ff1:	eb 01                	jmp    80100ff4 <exec+0x4ec>
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;
80100ff3:	90                   	nop
  switchuvm(proc);
  freevm(oldpgdir);
  return 0;

 bad:
  if(pgdir)
80100ff4:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100ff8:	74 0b                	je     80101005 <exec+0x4fd>
    freevm(pgdir);
80100ffa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ffd:	89 04 24             	mov    %eax,(%esp)
80101000:	e8 22 70 00 00       	call   80108027 <freevm>
  if(ip)
80101005:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80101009:	74 0b                	je     80101016 <exec+0x50e>
    iunlockput(ip);
8010100b:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010100e:	89 04 24             	mov    %eax,(%esp)
80101011:	e8 fe 0b 00 00       	call   80101c14 <iunlockput>
  return -1;
80101016:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010101b:	89 f4                	mov    %esi,%esp
}
8010101d:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101020:	5b                   	pop    %ebx
80101021:	5e                   	pop    %esi
80101022:	5d                   	pop    %ebp
80101023:	c3                   	ret    

80101024 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80101024:	55                   	push   %ebp
80101025:	89 e5                	mov    %esp,%ebp
80101027:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
8010102a:	c7 44 24 04 7e 83 10 	movl   $0x8010837e,0x4(%esp)
80101031:	80 
80101032:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
80101039:	e8 a4 3c 00 00       	call   80104ce2 <initlock>
}
8010103e:	c9                   	leave  
8010103f:	c3                   	ret    

80101040 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80101040:	55                   	push   %ebp
80101041:	89 e5                	mov    %esp,%ebp
80101043:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80101046:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
8010104d:	e8 b1 3c 00 00       	call   80104d03 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80101052:	c7 45 f4 b4 e3 10 80 	movl   $0x8010e3b4,-0xc(%ebp)
80101059:	eb 29                	jmp    80101084 <filealloc+0x44>
    if(f->ref == 0){
8010105b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010105e:	8b 40 04             	mov    0x4(%eax),%eax
80101061:	85 c0                	test   %eax,%eax
80101063:	75 1b                	jne    80101080 <filealloc+0x40>
      f->ref = 1;
80101065:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101068:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
8010106f:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
80101076:	e8 ea 3c 00 00       	call   80104d65 <release>
      return f;
8010107b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010107e:	eb 1e                	jmp    8010109e <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80101080:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80101084:	81 7d f4 14 ed 10 80 	cmpl   $0x8010ed14,-0xc(%ebp)
8010108b:	72 ce                	jb     8010105b <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
8010108d:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
80101094:	e8 cc 3c 00 00       	call   80104d65 <release>
  return 0;
80101099:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010109e:	c9                   	leave  
8010109f:	c3                   	ret    

801010a0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
801010a0:	55                   	push   %ebp
801010a1:	89 e5                	mov    %esp,%ebp
801010a3:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
801010a6:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
801010ad:	e8 51 3c 00 00       	call   80104d03 <acquire>
  if(f->ref < 1)
801010b2:	8b 45 08             	mov    0x8(%ebp),%eax
801010b5:	8b 40 04             	mov    0x4(%eax),%eax
801010b8:	85 c0                	test   %eax,%eax
801010ba:	7f 0c                	jg     801010c8 <filedup+0x28>
    panic("filedup");
801010bc:	c7 04 24 85 83 10 80 	movl   $0x80108385,(%esp)
801010c3:	e8 7e f4 ff ff       	call   80100546 <panic>
  f->ref++;
801010c8:	8b 45 08             	mov    0x8(%ebp),%eax
801010cb:	8b 40 04             	mov    0x4(%eax),%eax
801010ce:	8d 50 01             	lea    0x1(%eax),%edx
801010d1:	8b 45 08             	mov    0x8(%ebp),%eax
801010d4:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
801010d7:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
801010de:	e8 82 3c 00 00       	call   80104d65 <release>
  return f;
801010e3:	8b 45 08             	mov    0x8(%ebp),%eax
}
801010e6:	c9                   	leave  
801010e7:	c3                   	ret    

801010e8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
801010e8:	55                   	push   %ebp
801010e9:	89 e5                	mov    %esp,%ebp
801010eb:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
801010ee:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
801010f5:	e8 09 3c 00 00       	call   80104d03 <acquire>
  if(f->ref < 1)
801010fa:	8b 45 08             	mov    0x8(%ebp),%eax
801010fd:	8b 40 04             	mov    0x4(%eax),%eax
80101100:	85 c0                	test   %eax,%eax
80101102:	7f 0c                	jg     80101110 <fileclose+0x28>
    panic("fileclose");
80101104:	c7 04 24 8d 83 10 80 	movl   $0x8010838d,(%esp)
8010110b:	e8 36 f4 ff ff       	call   80100546 <panic>
  if(--f->ref > 0){
80101110:	8b 45 08             	mov    0x8(%ebp),%eax
80101113:	8b 40 04             	mov    0x4(%eax),%eax
80101116:	8d 50 ff             	lea    -0x1(%eax),%edx
80101119:	8b 45 08             	mov    0x8(%ebp),%eax
8010111c:	89 50 04             	mov    %edx,0x4(%eax)
8010111f:	8b 45 08             	mov    0x8(%ebp),%eax
80101122:	8b 40 04             	mov    0x4(%eax),%eax
80101125:	85 c0                	test   %eax,%eax
80101127:	7e 11                	jle    8010113a <fileclose+0x52>
    release(&ftable.lock);
80101129:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
80101130:	e8 30 3c 00 00       	call   80104d65 <release>
80101135:	e9 82 00 00 00       	jmp    801011bc <fileclose+0xd4>
    return;
  }
  ff = *f;
8010113a:	8b 45 08             	mov    0x8(%ebp),%eax
8010113d:	8b 10                	mov    (%eax),%edx
8010113f:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101142:	8b 50 04             	mov    0x4(%eax),%edx
80101145:	89 55 e4             	mov    %edx,-0x1c(%ebp)
80101148:	8b 50 08             	mov    0x8(%eax),%edx
8010114b:	89 55 e8             	mov    %edx,-0x18(%ebp)
8010114e:	8b 50 0c             	mov    0xc(%eax),%edx
80101151:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101154:	8b 50 10             	mov    0x10(%eax),%edx
80101157:	89 55 f0             	mov    %edx,-0x10(%ebp)
8010115a:	8b 40 14             	mov    0x14(%eax),%eax
8010115d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101160:	8b 45 08             	mov    0x8(%ebp),%eax
80101163:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
8010116a:	8b 45 08             	mov    0x8(%ebp),%eax
8010116d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101173:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
8010117a:	e8 e6 3b 00 00       	call   80104d65 <release>
  
  if(ff.type == FD_PIPE)
8010117f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101182:	83 f8 01             	cmp    $0x1,%eax
80101185:	75 18                	jne    8010119f <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
80101187:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
8010118b:	0f be d0             	movsbl %al,%edx
8010118e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101191:	89 54 24 04          	mov    %edx,0x4(%esp)
80101195:	89 04 24             	mov    %eax,(%esp)
80101198:	e8 36 2d 00 00       	call   80103ed3 <pipeclose>
8010119d:	eb 1d                	jmp    801011bc <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010119f:	8b 45 e0             	mov    -0x20(%ebp),%eax
801011a2:	83 f8 02             	cmp    $0x2,%eax
801011a5:	75 15                	jne    801011bc <fileclose+0xd4>
    begin_trans();
801011a7:	e8 c0 21 00 00       	call   8010336c <begin_trans>
    iput(ff.ip);
801011ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801011af:	89 04 24             	mov    %eax,(%esp)
801011b2:	e8 8c 09 00 00       	call   80101b43 <iput>
    commit_trans();
801011b7:	e8 f9 21 00 00       	call   801033b5 <commit_trans>
  }
}
801011bc:	c9                   	leave  
801011bd:	c3                   	ret    

801011be <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801011be:	55                   	push   %ebp
801011bf:	89 e5                	mov    %esp,%ebp
801011c1:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801011c4:	8b 45 08             	mov    0x8(%ebp),%eax
801011c7:	8b 00                	mov    (%eax),%eax
801011c9:	83 f8 02             	cmp    $0x2,%eax
801011cc:	75 38                	jne    80101206 <filestat+0x48>
    ilock(f->ip);
801011ce:	8b 45 08             	mov    0x8(%ebp),%eax
801011d1:	8b 40 10             	mov    0x10(%eax),%eax
801011d4:	89 04 24             	mov    %eax,(%esp)
801011d7:	e8 b4 07 00 00       	call   80101990 <ilock>
    stati(f->ip, st);
801011dc:	8b 45 08             	mov    0x8(%ebp),%eax
801011df:	8b 40 10             	mov    0x10(%eax),%eax
801011e2:	8b 55 0c             	mov    0xc(%ebp),%edx
801011e5:	89 54 24 04          	mov    %edx,0x4(%esp)
801011e9:	89 04 24             	mov    %eax,(%esp)
801011ec:	e8 67 0c 00 00       	call   80101e58 <stati>
    iunlock(f->ip);
801011f1:	8b 45 08             	mov    0x8(%ebp),%eax
801011f4:	8b 40 10             	mov    0x10(%eax),%eax
801011f7:	89 04 24             	mov    %eax,(%esp)
801011fa:	e8 df 08 00 00       	call   80101ade <iunlock>
    return 0;
801011ff:	b8 00 00 00 00       	mov    $0x0,%eax
80101204:	eb 05                	jmp    8010120b <filestat+0x4d>
  }
  return -1;
80101206:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010120b:	c9                   	leave  
8010120c:	c3                   	ret    

8010120d <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
8010120d:	55                   	push   %ebp
8010120e:	89 e5                	mov    %esp,%ebp
80101210:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
80101213:	8b 45 08             	mov    0x8(%ebp),%eax
80101216:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010121a:	84 c0                	test   %al,%al
8010121c:	75 0a                	jne    80101228 <fileread+0x1b>
    return -1;
8010121e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101223:	e9 9f 00 00 00       	jmp    801012c7 <fileread+0xba>
  if(f->type == FD_PIPE)
80101228:	8b 45 08             	mov    0x8(%ebp),%eax
8010122b:	8b 00                	mov    (%eax),%eax
8010122d:	83 f8 01             	cmp    $0x1,%eax
80101230:	75 1e                	jne    80101250 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101232:	8b 45 08             	mov    0x8(%ebp),%eax
80101235:	8b 40 0c             	mov    0xc(%eax),%eax
80101238:	8b 55 10             	mov    0x10(%ebp),%edx
8010123b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010123f:	8b 55 0c             	mov    0xc(%ebp),%edx
80101242:	89 54 24 04          	mov    %edx,0x4(%esp)
80101246:	89 04 24             	mov    %eax,(%esp)
80101249:	e8 09 2e 00 00       	call   80104057 <piperead>
8010124e:	eb 77                	jmp    801012c7 <fileread+0xba>
  if(f->type == FD_INODE){
80101250:	8b 45 08             	mov    0x8(%ebp),%eax
80101253:	8b 00                	mov    (%eax),%eax
80101255:	83 f8 02             	cmp    $0x2,%eax
80101258:	75 61                	jne    801012bb <fileread+0xae>
    ilock(f->ip);
8010125a:	8b 45 08             	mov    0x8(%ebp),%eax
8010125d:	8b 40 10             	mov    0x10(%eax),%eax
80101260:	89 04 24             	mov    %eax,(%esp)
80101263:	e8 28 07 00 00       	call   80101990 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80101268:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010126b:	8b 45 08             	mov    0x8(%ebp),%eax
8010126e:	8b 50 14             	mov    0x14(%eax),%edx
80101271:	8b 45 08             	mov    0x8(%ebp),%eax
80101274:	8b 40 10             	mov    0x10(%eax),%eax
80101277:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010127b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010127f:	8b 55 0c             	mov    0xc(%ebp),%edx
80101282:	89 54 24 04          	mov    %edx,0x4(%esp)
80101286:	89 04 24             	mov    %eax,(%esp)
80101289:	e8 0f 0c 00 00       	call   80101e9d <readi>
8010128e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101291:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101295:	7e 11                	jle    801012a8 <fileread+0x9b>
      f->off += r;
80101297:	8b 45 08             	mov    0x8(%ebp),%eax
8010129a:	8b 50 14             	mov    0x14(%eax),%edx
8010129d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012a0:	01 c2                	add    %eax,%edx
801012a2:	8b 45 08             	mov    0x8(%ebp),%eax
801012a5:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
801012a8:	8b 45 08             	mov    0x8(%ebp),%eax
801012ab:	8b 40 10             	mov    0x10(%eax),%eax
801012ae:	89 04 24             	mov    %eax,(%esp)
801012b1:	e8 28 08 00 00       	call   80101ade <iunlock>
    return r;
801012b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012b9:	eb 0c                	jmp    801012c7 <fileread+0xba>
  }
  panic("fileread");
801012bb:	c7 04 24 97 83 10 80 	movl   $0x80108397,(%esp)
801012c2:	e8 7f f2 ff ff       	call   80100546 <panic>
}
801012c7:	c9                   	leave  
801012c8:	c3                   	ret    

801012c9 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801012c9:	55                   	push   %ebp
801012ca:	89 e5                	mov    %esp,%ebp
801012cc:	53                   	push   %ebx
801012cd:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801012d0:	8b 45 08             	mov    0x8(%ebp),%eax
801012d3:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801012d7:	84 c0                	test   %al,%al
801012d9:	75 0a                	jne    801012e5 <filewrite+0x1c>
    return -1;
801012db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012e0:	e9 23 01 00 00       	jmp    80101408 <filewrite+0x13f>
  if(f->type == FD_PIPE)
801012e5:	8b 45 08             	mov    0x8(%ebp),%eax
801012e8:	8b 00                	mov    (%eax),%eax
801012ea:	83 f8 01             	cmp    $0x1,%eax
801012ed:	75 21                	jne    80101310 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
801012ef:	8b 45 08             	mov    0x8(%ebp),%eax
801012f2:	8b 40 0c             	mov    0xc(%eax),%eax
801012f5:	8b 55 10             	mov    0x10(%ebp),%edx
801012f8:	89 54 24 08          	mov    %edx,0x8(%esp)
801012fc:	8b 55 0c             	mov    0xc(%ebp),%edx
801012ff:	89 54 24 04          	mov    %edx,0x4(%esp)
80101303:	89 04 24             	mov    %eax,(%esp)
80101306:	e8 5a 2c 00 00       	call   80103f65 <pipewrite>
8010130b:	e9 f8 00 00 00       	jmp    80101408 <filewrite+0x13f>
  if(f->type == FD_INODE){
80101310:	8b 45 08             	mov    0x8(%ebp),%eax
80101313:	8b 00                	mov    (%eax),%eax
80101315:	83 f8 02             	cmp    $0x2,%eax
80101318:	0f 85 de 00 00 00    	jne    801013fc <filewrite+0x133>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
8010131e:	c7 45 ec 00 06 00 00 	movl   $0x600,-0x14(%ebp)
    int i = 0;
80101325:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
8010132c:	e9 a8 00 00 00       	jmp    801013d9 <filewrite+0x110>
      int n1 = n - i;
80101331:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101334:	8b 55 10             	mov    0x10(%ebp),%edx
80101337:	89 d1                	mov    %edx,%ecx
80101339:	29 c1                	sub    %eax,%ecx
8010133b:	89 c8                	mov    %ecx,%eax
8010133d:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101340:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101343:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80101346:	7e 06                	jle    8010134e <filewrite+0x85>
        n1 = max;
80101348:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010134b:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_trans();
8010134e:	e8 19 20 00 00       	call   8010336c <begin_trans>
      ilock(f->ip);
80101353:	8b 45 08             	mov    0x8(%ebp),%eax
80101356:	8b 40 10             	mov    0x10(%eax),%eax
80101359:	89 04 24             	mov    %eax,(%esp)
8010135c:	e8 2f 06 00 00       	call   80101990 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101361:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80101364:	8b 45 08             	mov    0x8(%ebp),%eax
80101367:	8b 50 14             	mov    0x14(%eax),%edx
8010136a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
8010136d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101370:	01 c3                	add    %eax,%ebx
80101372:	8b 45 08             	mov    0x8(%ebp),%eax
80101375:	8b 40 10             	mov    0x10(%eax),%eax
80101378:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010137c:	89 54 24 08          	mov    %edx,0x8(%esp)
80101380:	89 5c 24 04          	mov    %ebx,0x4(%esp)
80101384:	89 04 24             	mov    %eax,(%esp)
80101387:	e8 7f 0c 00 00       	call   8010200b <writei>
8010138c:	89 45 e8             	mov    %eax,-0x18(%ebp)
8010138f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101393:	7e 11                	jle    801013a6 <filewrite+0xdd>
        f->off += r;
80101395:	8b 45 08             	mov    0x8(%ebp),%eax
80101398:	8b 50 14             	mov    0x14(%eax),%edx
8010139b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010139e:	01 c2                	add    %eax,%edx
801013a0:	8b 45 08             	mov    0x8(%ebp),%eax
801013a3:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
801013a6:	8b 45 08             	mov    0x8(%ebp),%eax
801013a9:	8b 40 10             	mov    0x10(%eax),%eax
801013ac:	89 04 24             	mov    %eax,(%esp)
801013af:	e8 2a 07 00 00       	call   80101ade <iunlock>
      commit_trans();
801013b4:	e8 fc 1f 00 00       	call   801033b5 <commit_trans>

      if(r < 0)
801013b9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801013bd:	78 28                	js     801013e7 <filewrite+0x11e>
        break;
      if(r != n1)
801013bf:	8b 45 e8             	mov    -0x18(%ebp),%eax
801013c2:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801013c5:	74 0c                	je     801013d3 <filewrite+0x10a>
        panic("short filewrite");
801013c7:	c7 04 24 a0 83 10 80 	movl   $0x801083a0,(%esp)
801013ce:	e8 73 f1 ff ff       	call   80100546 <panic>
      i += r;
801013d3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801013d6:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801013d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013dc:	3b 45 10             	cmp    0x10(%ebp),%eax
801013df:	0f 8c 4c ff ff ff    	jl     80101331 <filewrite+0x68>
801013e5:	eb 01                	jmp    801013e8 <filewrite+0x11f>
        f->off += r;
      iunlock(f->ip);
      commit_trans();

      if(r < 0)
        break;
801013e7:	90                   	nop
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801013e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013eb:	3b 45 10             	cmp    0x10(%ebp),%eax
801013ee:	75 05                	jne    801013f5 <filewrite+0x12c>
801013f0:	8b 45 10             	mov    0x10(%ebp),%eax
801013f3:	eb 05                	jmp    801013fa <filewrite+0x131>
801013f5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801013fa:	eb 0c                	jmp    80101408 <filewrite+0x13f>
  }
  panic("filewrite");
801013fc:	c7 04 24 b0 83 10 80 	movl   $0x801083b0,(%esp)
80101403:	e8 3e f1 ff ff       	call   80100546 <panic>
}
80101408:	83 c4 24             	add    $0x24,%esp
8010140b:	5b                   	pop    %ebx
8010140c:	5d                   	pop    %ebp
8010140d:	c3                   	ret    
8010140e:	66 90                	xchg   %ax,%ax

80101410 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80101410:	55                   	push   %ebp
80101411:	89 e5                	mov    %esp,%ebp
80101413:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
80101416:	8b 45 08             	mov    0x8(%ebp),%eax
80101419:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101420:	00 
80101421:	89 04 24             	mov    %eax,(%esp)
80101424:	e8 7d ed ff ff       	call   801001a6 <bread>
80101429:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
8010142c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010142f:	83 c0 18             	add    $0x18,%eax
80101432:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80101439:	00 
8010143a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010143e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101441:	89 04 24             	mov    %eax,(%esp)
80101444:	e8 e8 3b 00 00       	call   80105031 <memmove>
  brelse(bp);
80101449:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010144c:	89 04 24             	mov    %eax,(%esp)
8010144f:	e8 c3 ed ff ff       	call   80100217 <brelse>
}
80101454:	c9                   	leave  
80101455:	c3                   	ret    

80101456 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101456:	55                   	push   %ebp
80101457:	89 e5                	mov    %esp,%ebp
80101459:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
8010145c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010145f:	8b 45 08             	mov    0x8(%ebp),%eax
80101462:	89 54 24 04          	mov    %edx,0x4(%esp)
80101466:	89 04 24             	mov    %eax,(%esp)
80101469:	e8 38 ed ff ff       	call   801001a6 <bread>
8010146e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101471:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101474:	83 c0 18             	add    $0x18,%eax
80101477:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010147e:	00 
8010147f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101486:	00 
80101487:	89 04 24             	mov    %eax,(%esp)
8010148a:	e8 cf 3a 00 00       	call   80104f5e <memset>
  log_write(bp);
8010148f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101492:	89 04 24             	mov    %eax,(%esp)
80101495:	e8 73 1f 00 00       	call   8010340d <log_write>
  brelse(bp);
8010149a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010149d:	89 04 24             	mov    %eax,(%esp)
801014a0:	e8 72 ed ff ff       	call   80100217 <brelse>
}
801014a5:	c9                   	leave  
801014a6:	c3                   	ret    

801014a7 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
801014a7:	55                   	push   %ebp
801014a8:	89 e5                	mov    %esp,%ebp
801014aa:	53                   	push   %ebx
801014ab:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
801014ae:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
801014b5:	8b 45 08             	mov    0x8(%ebp),%eax
801014b8:	8d 55 d8             	lea    -0x28(%ebp),%edx
801014bb:	89 54 24 04          	mov    %edx,0x4(%esp)
801014bf:	89 04 24             	mov    %eax,(%esp)
801014c2:	e8 49 ff ff ff       	call   80101410 <readsb>
  for(b = 0; b < sb.size; b += BPB){
801014c7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801014ce:	e9 0d 01 00 00       	jmp    801015e0 <balloc+0x139>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
801014d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801014d6:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801014dc:	85 c0                	test   %eax,%eax
801014de:	0f 48 c2             	cmovs  %edx,%eax
801014e1:	c1 f8 0c             	sar    $0xc,%eax
801014e4:	8b 55 e0             	mov    -0x20(%ebp),%edx
801014e7:	c1 ea 03             	shr    $0x3,%edx
801014ea:	01 d0                	add    %edx,%eax
801014ec:	83 c0 03             	add    $0x3,%eax
801014ef:	89 44 24 04          	mov    %eax,0x4(%esp)
801014f3:	8b 45 08             	mov    0x8(%ebp),%eax
801014f6:	89 04 24             	mov    %eax,(%esp)
801014f9:	e8 a8 ec ff ff       	call   801001a6 <bread>
801014fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101501:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101508:	e9 a3 00 00 00       	jmp    801015b0 <balloc+0x109>
      m = 1 << (bi % 8);
8010150d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101510:	89 c2                	mov    %eax,%edx
80101512:	c1 fa 1f             	sar    $0x1f,%edx
80101515:	c1 ea 1d             	shr    $0x1d,%edx
80101518:	01 d0                	add    %edx,%eax
8010151a:	83 e0 07             	and    $0x7,%eax
8010151d:	29 d0                	sub    %edx,%eax
8010151f:	ba 01 00 00 00       	mov    $0x1,%edx
80101524:	89 d3                	mov    %edx,%ebx
80101526:	89 c1                	mov    %eax,%ecx
80101528:	d3 e3                	shl    %cl,%ebx
8010152a:	89 d8                	mov    %ebx,%eax
8010152c:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010152f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101532:	8d 50 07             	lea    0x7(%eax),%edx
80101535:	85 c0                	test   %eax,%eax
80101537:	0f 48 c2             	cmovs  %edx,%eax
8010153a:	c1 f8 03             	sar    $0x3,%eax
8010153d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101540:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101545:	0f b6 c0             	movzbl %al,%eax
80101548:	23 45 e8             	and    -0x18(%ebp),%eax
8010154b:	85 c0                	test   %eax,%eax
8010154d:	75 5d                	jne    801015ac <balloc+0x105>
        bp->data[bi/8] |= m;  // Mark block in use.
8010154f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101552:	8d 50 07             	lea    0x7(%eax),%edx
80101555:	85 c0                	test   %eax,%eax
80101557:	0f 48 c2             	cmovs  %edx,%eax
8010155a:	c1 f8 03             	sar    $0x3,%eax
8010155d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101560:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101565:	89 d1                	mov    %edx,%ecx
80101567:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010156a:	09 ca                	or     %ecx,%edx
8010156c:	89 d1                	mov    %edx,%ecx
8010156e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101571:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101575:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101578:	89 04 24             	mov    %eax,(%esp)
8010157b:	e8 8d 1e 00 00       	call   8010340d <log_write>
        brelse(bp);
80101580:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101583:	89 04 24             	mov    %eax,(%esp)
80101586:	e8 8c ec ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
8010158b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010158e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101591:	01 c2                	add    %eax,%edx
80101593:	8b 45 08             	mov    0x8(%ebp),%eax
80101596:	89 54 24 04          	mov    %edx,0x4(%esp)
8010159a:	89 04 24             	mov    %eax,(%esp)
8010159d:	e8 b4 fe ff ff       	call   80101456 <bzero>
        return b + bi;
801015a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015a8:	01 d0                	add    %edx,%eax
801015aa:	eb 4e                	jmp    801015fa <balloc+0x153>

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801015ac:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801015b0:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
801015b7:	7f 15                	jg     801015ce <balloc+0x127>
801015b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015bf:	01 d0                	add    %edx,%eax
801015c1:	89 c2                	mov    %eax,%edx
801015c3:	8b 45 d8             	mov    -0x28(%ebp),%eax
801015c6:	39 c2                	cmp    %eax,%edx
801015c8:	0f 82 3f ff ff ff    	jb     8010150d <balloc+0x66>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801015ce:	8b 45 ec             	mov    -0x14(%ebp),%eax
801015d1:	89 04 24             	mov    %eax,(%esp)
801015d4:	e8 3e ec ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
801015d9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801015e0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015e3:	8b 45 d8             	mov    -0x28(%ebp),%eax
801015e6:	39 c2                	cmp    %eax,%edx
801015e8:	0f 82 e5 fe ff ff    	jb     801014d3 <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801015ee:	c7 04 24 ba 83 10 80 	movl   $0x801083ba,(%esp)
801015f5:	e8 4c ef ff ff       	call   80100546 <panic>
}
801015fa:	83 c4 34             	add    $0x34,%esp
801015fd:	5b                   	pop    %ebx
801015fe:	5d                   	pop    %ebp
801015ff:	c3                   	ret    

80101600 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
80101600:	55                   	push   %ebp
80101601:	89 e5                	mov    %esp,%ebp
80101603:	53                   	push   %ebx
80101604:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
80101607:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010160a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010160e:	8b 45 08             	mov    0x8(%ebp),%eax
80101611:	89 04 24             	mov    %eax,(%esp)
80101614:	e8 f7 fd ff ff       	call   80101410 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
80101619:	8b 45 0c             	mov    0xc(%ebp),%eax
8010161c:	89 c2                	mov    %eax,%edx
8010161e:	c1 ea 0c             	shr    $0xc,%edx
80101621:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101624:	c1 e8 03             	shr    $0x3,%eax
80101627:	01 d0                	add    %edx,%eax
80101629:	8d 50 03             	lea    0x3(%eax),%edx
8010162c:	8b 45 08             	mov    0x8(%ebp),%eax
8010162f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101633:	89 04 24             	mov    %eax,(%esp)
80101636:	e8 6b eb ff ff       	call   801001a6 <bread>
8010163b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
8010163e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101641:	25 ff 0f 00 00       	and    $0xfff,%eax
80101646:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
80101649:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010164c:	89 c2                	mov    %eax,%edx
8010164e:	c1 fa 1f             	sar    $0x1f,%edx
80101651:	c1 ea 1d             	shr    $0x1d,%edx
80101654:	01 d0                	add    %edx,%eax
80101656:	83 e0 07             	and    $0x7,%eax
80101659:	29 d0                	sub    %edx,%eax
8010165b:	ba 01 00 00 00       	mov    $0x1,%edx
80101660:	89 d3                	mov    %edx,%ebx
80101662:	89 c1                	mov    %eax,%ecx
80101664:	d3 e3                	shl    %cl,%ebx
80101666:	89 d8                	mov    %ebx,%eax
80101668:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
8010166b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010166e:	8d 50 07             	lea    0x7(%eax),%edx
80101671:	85 c0                	test   %eax,%eax
80101673:	0f 48 c2             	cmovs  %edx,%eax
80101676:	c1 f8 03             	sar    $0x3,%eax
80101679:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010167c:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101681:	0f b6 c0             	movzbl %al,%eax
80101684:	23 45 ec             	and    -0x14(%ebp),%eax
80101687:	85 c0                	test   %eax,%eax
80101689:	75 0c                	jne    80101697 <bfree+0x97>
    panic("freeing free block");
8010168b:	c7 04 24 d0 83 10 80 	movl   $0x801083d0,(%esp)
80101692:	e8 af ee ff ff       	call   80100546 <panic>
  bp->data[bi/8] &= ~m;
80101697:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010169a:	8d 50 07             	lea    0x7(%eax),%edx
8010169d:	85 c0                	test   %eax,%eax
8010169f:	0f 48 c2             	cmovs  %edx,%eax
801016a2:	c1 f8 03             	sar    $0x3,%eax
801016a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801016a8:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801016ad:	8b 4d ec             	mov    -0x14(%ebp),%ecx
801016b0:	f7 d1                	not    %ecx
801016b2:	21 ca                	and    %ecx,%edx
801016b4:	89 d1                	mov    %edx,%ecx
801016b6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801016b9:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
801016bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016c0:	89 04 24             	mov    %eax,(%esp)
801016c3:	e8 45 1d 00 00       	call   8010340d <log_write>
  brelse(bp);
801016c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016cb:	89 04 24             	mov    %eax,(%esp)
801016ce:	e8 44 eb ff ff       	call   80100217 <brelse>
}
801016d3:	83 c4 34             	add    $0x34,%esp
801016d6:	5b                   	pop    %ebx
801016d7:	5d                   	pop    %ebp
801016d8:	c3                   	ret    

801016d9 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
801016d9:	55                   	push   %ebp
801016da:	89 e5                	mov    %esp,%ebp
801016dc:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
801016df:	c7 44 24 04 e3 83 10 	movl   $0x801083e3,0x4(%esp)
801016e6:	80 
801016e7:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
801016ee:	e8 ef 35 00 00       	call   80104ce2 <initlock>
}
801016f3:	c9                   	leave  
801016f4:	c3                   	ret    

801016f5 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
801016f5:	55                   	push   %ebp
801016f6:	89 e5                	mov    %esp,%ebp
801016f8:	83 ec 48             	sub    $0x48,%esp
801016fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801016fe:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
80101702:	8b 45 08             	mov    0x8(%ebp),%eax
80101705:	8d 55 dc             	lea    -0x24(%ebp),%edx
80101708:	89 54 24 04          	mov    %edx,0x4(%esp)
8010170c:	89 04 24             	mov    %eax,(%esp)
8010170f:	e8 fc fc ff ff       	call   80101410 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
80101714:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
8010171b:	e9 98 00 00 00       	jmp    801017b8 <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
80101720:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101723:	c1 e8 03             	shr    $0x3,%eax
80101726:	83 c0 02             	add    $0x2,%eax
80101729:	89 44 24 04          	mov    %eax,0x4(%esp)
8010172d:	8b 45 08             	mov    0x8(%ebp),%eax
80101730:	89 04 24             	mov    %eax,(%esp)
80101733:	e8 6e ea ff ff       	call   801001a6 <bread>
80101738:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
8010173b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010173e:	8d 50 18             	lea    0x18(%eax),%edx
80101741:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101744:	83 e0 07             	and    $0x7,%eax
80101747:	c1 e0 06             	shl    $0x6,%eax
8010174a:	01 d0                	add    %edx,%eax
8010174c:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
8010174f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101752:	0f b7 00             	movzwl (%eax),%eax
80101755:	66 85 c0             	test   %ax,%ax
80101758:	75 4f                	jne    801017a9 <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
8010175a:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
80101761:	00 
80101762:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101769:	00 
8010176a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010176d:	89 04 24             	mov    %eax,(%esp)
80101770:	e8 e9 37 00 00       	call   80104f5e <memset>
      dip->type = type;
80101775:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101778:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
8010177c:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
8010177f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101782:	89 04 24             	mov    %eax,(%esp)
80101785:	e8 83 1c 00 00       	call   8010340d <log_write>
      brelse(bp);
8010178a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010178d:	89 04 24             	mov    %eax,(%esp)
80101790:	e8 82 ea ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101795:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101798:	89 44 24 04          	mov    %eax,0x4(%esp)
8010179c:	8b 45 08             	mov    0x8(%ebp),%eax
8010179f:	89 04 24             	mov    %eax,(%esp)
801017a2:	e8 e5 00 00 00       	call   8010188c <iget>
801017a7:	eb 29                	jmp    801017d2 <ialloc+0xdd>
    }
    brelse(bp);
801017a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017ac:	89 04 24             	mov    %eax,(%esp)
801017af:	e8 63 ea ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
801017b4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801017b8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801017bb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801017be:	39 c2                	cmp    %eax,%edx
801017c0:	0f 82 5a ff ff ff    	jb     80101720 <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
801017c6:	c7 04 24 ea 83 10 80 	movl   $0x801083ea,(%esp)
801017cd:	e8 74 ed ff ff       	call   80100546 <panic>
}
801017d2:	c9                   	leave  
801017d3:	c3                   	ret    

801017d4 <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
801017d4:	55                   	push   %ebp
801017d5:	89 e5                	mov    %esp,%ebp
801017d7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
801017da:	8b 45 08             	mov    0x8(%ebp),%eax
801017dd:	8b 40 04             	mov    0x4(%eax),%eax
801017e0:	c1 e8 03             	shr    $0x3,%eax
801017e3:	8d 50 02             	lea    0x2(%eax),%edx
801017e6:	8b 45 08             	mov    0x8(%ebp),%eax
801017e9:	8b 00                	mov    (%eax),%eax
801017eb:	89 54 24 04          	mov    %edx,0x4(%esp)
801017ef:	89 04 24             	mov    %eax,(%esp)
801017f2:	e8 af e9 ff ff       	call   801001a6 <bread>
801017f7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801017fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017fd:	8d 50 18             	lea    0x18(%eax),%edx
80101800:	8b 45 08             	mov    0x8(%ebp),%eax
80101803:	8b 40 04             	mov    0x4(%eax),%eax
80101806:	83 e0 07             	and    $0x7,%eax
80101809:	c1 e0 06             	shl    $0x6,%eax
8010180c:	01 d0                	add    %edx,%eax
8010180e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80101811:	8b 45 08             	mov    0x8(%ebp),%eax
80101814:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101818:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010181b:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
8010181e:	8b 45 08             	mov    0x8(%ebp),%eax
80101821:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80101825:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101828:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
8010182c:	8b 45 08             	mov    0x8(%ebp),%eax
8010182f:	0f b7 50 14          	movzwl 0x14(%eax),%edx
80101833:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101836:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
8010183a:	8b 45 08             	mov    0x8(%ebp),%eax
8010183d:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101841:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101844:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101848:	8b 45 08             	mov    0x8(%ebp),%eax
8010184b:	8b 50 18             	mov    0x18(%eax),%edx
8010184e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101851:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101854:	8b 45 08             	mov    0x8(%ebp),%eax
80101857:	8d 50 1c             	lea    0x1c(%eax),%edx
8010185a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010185d:	83 c0 0c             	add    $0xc,%eax
80101860:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101867:	00 
80101868:	89 54 24 04          	mov    %edx,0x4(%esp)
8010186c:	89 04 24             	mov    %eax,(%esp)
8010186f:	e8 bd 37 00 00       	call   80105031 <memmove>
  log_write(bp);
80101874:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101877:	89 04 24             	mov    %eax,(%esp)
8010187a:	e8 8e 1b 00 00       	call   8010340d <log_write>
  brelse(bp);
8010187f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101882:	89 04 24             	mov    %eax,(%esp)
80101885:	e8 8d e9 ff ff       	call   80100217 <brelse>
}
8010188a:	c9                   	leave  
8010188b:	c3                   	ret    

8010188c <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
8010188c:	55                   	push   %ebp
8010188d:	89 e5                	mov    %esp,%ebp
8010188f:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
80101892:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101899:	e8 65 34 00 00       	call   80104d03 <acquire>

  // Is the inode already cached?
  empty = 0;
8010189e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801018a5:	c7 45 f4 b4 ed 10 80 	movl   $0x8010edb4,-0xc(%ebp)
801018ac:	eb 59                	jmp    80101907 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801018ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018b1:	8b 40 08             	mov    0x8(%eax),%eax
801018b4:	85 c0                	test   %eax,%eax
801018b6:	7e 35                	jle    801018ed <iget+0x61>
801018b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018bb:	8b 00                	mov    (%eax),%eax
801018bd:	3b 45 08             	cmp    0x8(%ebp),%eax
801018c0:	75 2b                	jne    801018ed <iget+0x61>
801018c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018c5:	8b 40 04             	mov    0x4(%eax),%eax
801018c8:	3b 45 0c             	cmp    0xc(%ebp),%eax
801018cb:	75 20                	jne    801018ed <iget+0x61>
      ip->ref++;
801018cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018d0:	8b 40 08             	mov    0x8(%eax),%eax
801018d3:	8d 50 01             	lea    0x1(%eax),%edx
801018d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018d9:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
801018dc:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
801018e3:	e8 7d 34 00 00       	call   80104d65 <release>
      return ip;
801018e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018eb:	eb 6f                	jmp    8010195c <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801018ed:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801018f1:	75 10                	jne    80101903 <iget+0x77>
801018f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018f6:	8b 40 08             	mov    0x8(%eax),%eax
801018f9:	85 c0                	test   %eax,%eax
801018fb:	75 06                	jne    80101903 <iget+0x77>
      empty = ip;
801018fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101900:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101903:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
80101907:	81 7d f4 54 fd 10 80 	cmpl   $0x8010fd54,-0xc(%ebp)
8010190e:	72 9e                	jb     801018ae <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80101910:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101914:	75 0c                	jne    80101922 <iget+0x96>
    panic("iget: no inodes");
80101916:	c7 04 24 fc 83 10 80 	movl   $0x801083fc,(%esp)
8010191d:	e8 24 ec ff ff       	call   80100546 <panic>

  ip = empty;
80101922:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101925:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80101928:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010192b:	8b 55 08             	mov    0x8(%ebp),%edx
8010192e:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80101930:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101933:	8b 55 0c             	mov    0xc(%ebp),%edx
80101936:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101939:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010193c:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
80101943:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101946:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
8010194d:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101954:	e8 0c 34 00 00       	call   80104d65 <release>

  return ip;
80101959:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010195c:	c9                   	leave  
8010195d:	c3                   	ret    

8010195e <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
8010195e:	55                   	push   %ebp
8010195f:	89 e5                	mov    %esp,%ebp
80101961:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101964:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
8010196b:	e8 93 33 00 00       	call   80104d03 <acquire>
  ip->ref++;
80101970:	8b 45 08             	mov    0x8(%ebp),%eax
80101973:	8b 40 08             	mov    0x8(%eax),%eax
80101976:	8d 50 01             	lea    0x1(%eax),%edx
80101979:	8b 45 08             	mov    0x8(%ebp),%eax
8010197c:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010197f:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101986:	e8 da 33 00 00       	call   80104d65 <release>
  return ip;
8010198b:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010198e:	c9                   	leave  
8010198f:	c3                   	ret    

80101990 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101990:	55                   	push   %ebp
80101991:	89 e5                	mov    %esp,%ebp
80101993:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101996:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010199a:	74 0a                	je     801019a6 <ilock+0x16>
8010199c:	8b 45 08             	mov    0x8(%ebp),%eax
8010199f:	8b 40 08             	mov    0x8(%eax),%eax
801019a2:	85 c0                	test   %eax,%eax
801019a4:	7f 0c                	jg     801019b2 <ilock+0x22>
    panic("ilock");
801019a6:	c7 04 24 0c 84 10 80 	movl   $0x8010840c,(%esp)
801019ad:	e8 94 eb ff ff       	call   80100546 <panic>

  acquire(&icache.lock);
801019b2:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
801019b9:	e8 45 33 00 00       	call   80104d03 <acquire>
  while(ip->flags & I_BUSY)
801019be:	eb 13                	jmp    801019d3 <ilock+0x43>
    sleep(ip, &icache.lock);
801019c0:	c7 44 24 04 80 ed 10 	movl   $0x8010ed80,0x4(%esp)
801019c7:	80 
801019c8:	8b 45 08             	mov    0x8(%ebp),%eax
801019cb:	89 04 24             	mov    %eax,(%esp)
801019ce:	e8 52 30 00 00       	call   80104a25 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
801019d3:	8b 45 08             	mov    0x8(%ebp),%eax
801019d6:	8b 40 0c             	mov    0xc(%eax),%eax
801019d9:	83 e0 01             	and    $0x1,%eax
801019dc:	85 c0                	test   %eax,%eax
801019de:	75 e0                	jne    801019c0 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
801019e0:	8b 45 08             	mov    0x8(%ebp),%eax
801019e3:	8b 40 0c             	mov    0xc(%eax),%eax
801019e6:	89 c2                	mov    %eax,%edx
801019e8:	83 ca 01             	or     $0x1,%edx
801019eb:	8b 45 08             	mov    0x8(%ebp),%eax
801019ee:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
801019f1:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
801019f8:	e8 68 33 00 00       	call   80104d65 <release>

  if(!(ip->flags & I_VALID)){
801019fd:	8b 45 08             	mov    0x8(%ebp),%eax
80101a00:	8b 40 0c             	mov    0xc(%eax),%eax
80101a03:	83 e0 02             	and    $0x2,%eax
80101a06:	85 c0                	test   %eax,%eax
80101a08:	0f 85 ce 00 00 00    	jne    80101adc <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
80101a0e:	8b 45 08             	mov    0x8(%ebp),%eax
80101a11:	8b 40 04             	mov    0x4(%eax),%eax
80101a14:	c1 e8 03             	shr    $0x3,%eax
80101a17:	8d 50 02             	lea    0x2(%eax),%edx
80101a1a:	8b 45 08             	mov    0x8(%ebp),%eax
80101a1d:	8b 00                	mov    (%eax),%eax
80101a1f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a23:	89 04 24             	mov    %eax,(%esp)
80101a26:	e8 7b e7 ff ff       	call   801001a6 <bread>
80101a2b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101a2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a31:	8d 50 18             	lea    0x18(%eax),%edx
80101a34:	8b 45 08             	mov    0x8(%ebp),%eax
80101a37:	8b 40 04             	mov    0x4(%eax),%eax
80101a3a:	83 e0 07             	and    $0x7,%eax
80101a3d:	c1 e0 06             	shl    $0x6,%eax
80101a40:	01 d0                	add    %edx,%eax
80101a42:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101a45:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a48:	0f b7 10             	movzwl (%eax),%edx
80101a4b:	8b 45 08             	mov    0x8(%ebp),%eax
80101a4e:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80101a52:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a55:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101a59:	8b 45 08             	mov    0x8(%ebp),%eax
80101a5c:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101a60:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a63:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101a67:	8b 45 08             	mov    0x8(%ebp),%eax
80101a6a:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101a6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a71:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101a75:	8b 45 08             	mov    0x8(%ebp),%eax
80101a78:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101a7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a7f:	8b 50 08             	mov    0x8(%eax),%edx
80101a82:	8b 45 08             	mov    0x8(%ebp),%eax
80101a85:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101a88:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a8b:	8d 50 0c             	lea    0xc(%eax),%edx
80101a8e:	8b 45 08             	mov    0x8(%ebp),%eax
80101a91:	83 c0 1c             	add    $0x1c,%eax
80101a94:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101a9b:	00 
80101a9c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101aa0:	89 04 24             	mov    %eax,(%esp)
80101aa3:	e8 89 35 00 00       	call   80105031 <memmove>
    brelse(bp);
80101aa8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101aab:	89 04 24             	mov    %eax,(%esp)
80101aae:	e8 64 e7 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80101ab3:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab6:	8b 40 0c             	mov    0xc(%eax),%eax
80101ab9:	89 c2                	mov    %eax,%edx
80101abb:	83 ca 02             	or     $0x2,%edx
80101abe:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac1:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80101ac4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101acb:	66 85 c0             	test   %ax,%ax
80101ace:	75 0c                	jne    80101adc <ilock+0x14c>
      panic("ilock: no type");
80101ad0:	c7 04 24 12 84 10 80 	movl   $0x80108412,(%esp)
80101ad7:	e8 6a ea ff ff       	call   80100546 <panic>
  }
}
80101adc:	c9                   	leave  
80101add:	c3                   	ret    

80101ade <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101ade:	55                   	push   %ebp
80101adf:	89 e5                	mov    %esp,%ebp
80101ae1:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80101ae4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101ae8:	74 17                	je     80101b01 <iunlock+0x23>
80101aea:	8b 45 08             	mov    0x8(%ebp),%eax
80101aed:	8b 40 0c             	mov    0xc(%eax),%eax
80101af0:	83 e0 01             	and    $0x1,%eax
80101af3:	85 c0                	test   %eax,%eax
80101af5:	74 0a                	je     80101b01 <iunlock+0x23>
80101af7:	8b 45 08             	mov    0x8(%ebp),%eax
80101afa:	8b 40 08             	mov    0x8(%eax),%eax
80101afd:	85 c0                	test   %eax,%eax
80101aff:	7f 0c                	jg     80101b0d <iunlock+0x2f>
    panic("iunlock");
80101b01:	c7 04 24 21 84 10 80 	movl   $0x80108421,(%esp)
80101b08:	e8 39 ea ff ff       	call   80100546 <panic>

  acquire(&icache.lock);
80101b0d:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101b14:	e8 ea 31 00 00       	call   80104d03 <acquire>
  ip->flags &= ~I_BUSY;
80101b19:	8b 45 08             	mov    0x8(%ebp),%eax
80101b1c:	8b 40 0c             	mov    0xc(%eax),%eax
80101b1f:	89 c2                	mov    %eax,%edx
80101b21:	83 e2 fe             	and    $0xfffffffe,%edx
80101b24:	8b 45 08             	mov    0x8(%ebp),%eax
80101b27:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101b2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b2d:	89 04 24             	mov    %eax,(%esp)
80101b30:	e8 c9 2f 00 00       	call   80104afe <wakeup>
  release(&icache.lock);
80101b35:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101b3c:	e8 24 32 00 00       	call   80104d65 <release>
}
80101b41:	c9                   	leave  
80101b42:	c3                   	ret    

80101b43 <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
80101b43:	55                   	push   %ebp
80101b44:	89 e5                	mov    %esp,%ebp
80101b46:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101b49:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101b50:	e8 ae 31 00 00       	call   80104d03 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101b55:	8b 45 08             	mov    0x8(%ebp),%eax
80101b58:	8b 40 08             	mov    0x8(%eax),%eax
80101b5b:	83 f8 01             	cmp    $0x1,%eax
80101b5e:	0f 85 93 00 00 00    	jne    80101bf7 <iput+0xb4>
80101b64:	8b 45 08             	mov    0x8(%ebp),%eax
80101b67:	8b 40 0c             	mov    0xc(%eax),%eax
80101b6a:	83 e0 02             	and    $0x2,%eax
80101b6d:	85 c0                	test   %eax,%eax
80101b6f:	0f 84 82 00 00 00    	je     80101bf7 <iput+0xb4>
80101b75:	8b 45 08             	mov    0x8(%ebp),%eax
80101b78:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101b7c:	66 85 c0             	test   %ax,%ax
80101b7f:	75 76                	jne    80101bf7 <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
80101b81:	8b 45 08             	mov    0x8(%ebp),%eax
80101b84:	8b 40 0c             	mov    0xc(%eax),%eax
80101b87:	83 e0 01             	and    $0x1,%eax
80101b8a:	85 c0                	test   %eax,%eax
80101b8c:	74 0c                	je     80101b9a <iput+0x57>
      panic("iput busy");
80101b8e:	c7 04 24 29 84 10 80 	movl   $0x80108429,(%esp)
80101b95:	e8 ac e9 ff ff       	call   80100546 <panic>
    ip->flags |= I_BUSY;
80101b9a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b9d:	8b 40 0c             	mov    0xc(%eax),%eax
80101ba0:	89 c2                	mov    %eax,%edx
80101ba2:	83 ca 01             	or     $0x1,%edx
80101ba5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ba8:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101bab:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101bb2:	e8 ae 31 00 00       	call   80104d65 <release>
    itrunc(ip);
80101bb7:	8b 45 08             	mov    0x8(%ebp),%eax
80101bba:	89 04 24             	mov    %eax,(%esp)
80101bbd:	e8 7d 01 00 00       	call   80101d3f <itrunc>
    ip->type = 0;
80101bc2:	8b 45 08             	mov    0x8(%ebp),%eax
80101bc5:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101bcb:	8b 45 08             	mov    0x8(%ebp),%eax
80101bce:	89 04 24             	mov    %eax,(%esp)
80101bd1:	e8 fe fb ff ff       	call   801017d4 <iupdate>
    acquire(&icache.lock);
80101bd6:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101bdd:	e8 21 31 00 00       	call   80104d03 <acquire>
    ip->flags = 0;
80101be2:	8b 45 08             	mov    0x8(%ebp),%eax
80101be5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101bec:	8b 45 08             	mov    0x8(%ebp),%eax
80101bef:	89 04 24             	mov    %eax,(%esp)
80101bf2:	e8 07 2f 00 00       	call   80104afe <wakeup>
  }
  ip->ref--;
80101bf7:	8b 45 08             	mov    0x8(%ebp),%eax
80101bfa:	8b 40 08             	mov    0x8(%eax),%eax
80101bfd:	8d 50 ff             	lea    -0x1(%eax),%edx
80101c00:	8b 45 08             	mov    0x8(%ebp),%eax
80101c03:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101c06:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101c0d:	e8 53 31 00 00       	call   80104d65 <release>
}
80101c12:	c9                   	leave  
80101c13:	c3                   	ret    

80101c14 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101c14:	55                   	push   %ebp
80101c15:	89 e5                	mov    %esp,%ebp
80101c17:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101c1a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c1d:	89 04 24             	mov    %eax,(%esp)
80101c20:	e8 b9 fe ff ff       	call   80101ade <iunlock>
  iput(ip);
80101c25:	8b 45 08             	mov    0x8(%ebp),%eax
80101c28:	89 04 24             	mov    %eax,(%esp)
80101c2b:	e8 13 ff ff ff       	call   80101b43 <iput>
}
80101c30:	c9                   	leave  
80101c31:	c3                   	ret    

80101c32 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101c32:	55                   	push   %ebp
80101c33:	89 e5                	mov    %esp,%ebp
80101c35:	53                   	push   %ebx
80101c36:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101c39:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101c3d:	77 3e                	ja     80101c7d <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101c3f:	8b 45 08             	mov    0x8(%ebp),%eax
80101c42:	8b 55 0c             	mov    0xc(%ebp),%edx
80101c45:	83 c2 04             	add    $0x4,%edx
80101c48:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c4c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c4f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c53:	75 20                	jne    80101c75 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101c55:	8b 45 08             	mov    0x8(%ebp),%eax
80101c58:	8b 00                	mov    (%eax),%eax
80101c5a:	89 04 24             	mov    %eax,(%esp)
80101c5d:	e8 45 f8 ff ff       	call   801014a7 <balloc>
80101c62:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c65:	8b 45 08             	mov    0x8(%ebp),%eax
80101c68:	8b 55 0c             	mov    0xc(%ebp),%edx
80101c6b:	8d 4a 04             	lea    0x4(%edx),%ecx
80101c6e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c71:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101c75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c78:	e9 bc 00 00 00       	jmp    80101d39 <bmap+0x107>
  }
  bn -= NDIRECT;
80101c7d:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101c81:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101c85:	0f 87 a2 00 00 00    	ja     80101d2d <bmap+0xfb>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101c8b:	8b 45 08             	mov    0x8(%ebp),%eax
80101c8e:	8b 40 4c             	mov    0x4c(%eax),%eax
80101c91:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c94:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c98:	75 19                	jne    80101cb3 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101c9a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c9d:	8b 00                	mov    (%eax),%eax
80101c9f:	89 04 24             	mov    %eax,(%esp)
80101ca2:	e8 00 f8 ff ff       	call   801014a7 <balloc>
80101ca7:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101caa:	8b 45 08             	mov    0x8(%ebp),%eax
80101cad:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cb0:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101cb3:	8b 45 08             	mov    0x8(%ebp),%eax
80101cb6:	8b 00                	mov    (%eax),%eax
80101cb8:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cbb:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cbf:	89 04 24             	mov    %eax,(%esp)
80101cc2:	e8 df e4 ff ff       	call   801001a6 <bread>
80101cc7:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101cca:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ccd:	83 c0 18             	add    $0x18,%eax
80101cd0:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101cd3:	8b 45 0c             	mov    0xc(%ebp),%eax
80101cd6:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101cdd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ce0:	01 d0                	add    %edx,%eax
80101ce2:	8b 00                	mov    (%eax),%eax
80101ce4:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101ce7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101ceb:	75 30                	jne    80101d1d <bmap+0xeb>
      a[bn] = addr = balloc(ip->dev);
80101ced:	8b 45 0c             	mov    0xc(%ebp),%eax
80101cf0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101cf7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cfa:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101cfd:	8b 45 08             	mov    0x8(%ebp),%eax
80101d00:	8b 00                	mov    (%eax),%eax
80101d02:	89 04 24             	mov    %eax,(%esp)
80101d05:	e8 9d f7 ff ff       	call   801014a7 <balloc>
80101d0a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d10:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101d12:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d15:	89 04 24             	mov    %eax,(%esp)
80101d18:	e8 f0 16 00 00       	call   8010340d <log_write>
    }
    brelse(bp);
80101d1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d20:	89 04 24             	mov    %eax,(%esp)
80101d23:	e8 ef e4 ff ff       	call   80100217 <brelse>
    return addr;
80101d28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d2b:	eb 0c                	jmp    80101d39 <bmap+0x107>
  }

  panic("bmap: out of range");
80101d2d:	c7 04 24 33 84 10 80 	movl   $0x80108433,(%esp)
80101d34:	e8 0d e8 ff ff       	call   80100546 <panic>
}
80101d39:	83 c4 24             	add    $0x24,%esp
80101d3c:	5b                   	pop    %ebx
80101d3d:	5d                   	pop    %ebp
80101d3e:	c3                   	ret    

80101d3f <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101d3f:	55                   	push   %ebp
80101d40:	89 e5                	mov    %esp,%ebp
80101d42:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101d45:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101d4c:	eb 44                	jmp    80101d92 <itrunc+0x53>
    if(ip->addrs[i]){
80101d4e:	8b 45 08             	mov    0x8(%ebp),%eax
80101d51:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d54:	83 c2 04             	add    $0x4,%edx
80101d57:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101d5b:	85 c0                	test   %eax,%eax
80101d5d:	74 2f                	je     80101d8e <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101d5f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d62:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d65:	83 c2 04             	add    $0x4,%edx
80101d68:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101d6c:	8b 45 08             	mov    0x8(%ebp),%eax
80101d6f:	8b 00                	mov    (%eax),%eax
80101d71:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d75:	89 04 24             	mov    %eax,(%esp)
80101d78:	e8 83 f8 ff ff       	call   80101600 <bfree>
      ip->addrs[i] = 0;
80101d7d:	8b 45 08             	mov    0x8(%ebp),%eax
80101d80:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d83:	83 c2 04             	add    $0x4,%edx
80101d86:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101d8d:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101d8e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101d92:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101d96:	7e b6                	jle    80101d4e <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101d98:	8b 45 08             	mov    0x8(%ebp),%eax
80101d9b:	8b 40 4c             	mov    0x4c(%eax),%eax
80101d9e:	85 c0                	test   %eax,%eax
80101da0:	0f 84 9b 00 00 00    	je     80101e41 <itrunc+0x102>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101da6:	8b 45 08             	mov    0x8(%ebp),%eax
80101da9:	8b 50 4c             	mov    0x4c(%eax),%edx
80101dac:	8b 45 08             	mov    0x8(%ebp),%eax
80101daf:	8b 00                	mov    (%eax),%eax
80101db1:	89 54 24 04          	mov    %edx,0x4(%esp)
80101db5:	89 04 24             	mov    %eax,(%esp)
80101db8:	e8 e9 e3 ff ff       	call   801001a6 <bread>
80101dbd:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101dc0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101dc3:	83 c0 18             	add    $0x18,%eax
80101dc6:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101dc9:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101dd0:	eb 3b                	jmp    80101e0d <itrunc+0xce>
      if(a[j])
80101dd2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101dd5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101ddc:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101ddf:	01 d0                	add    %edx,%eax
80101de1:	8b 00                	mov    (%eax),%eax
80101de3:	85 c0                	test   %eax,%eax
80101de5:	74 22                	je     80101e09 <itrunc+0xca>
        bfree(ip->dev, a[j]);
80101de7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101dea:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101df1:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101df4:	01 d0                	add    %edx,%eax
80101df6:	8b 10                	mov    (%eax),%edx
80101df8:	8b 45 08             	mov    0x8(%ebp),%eax
80101dfb:	8b 00                	mov    (%eax),%eax
80101dfd:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e01:	89 04 24             	mov    %eax,(%esp)
80101e04:	e8 f7 f7 ff ff       	call   80101600 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101e09:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101e0d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e10:	83 f8 7f             	cmp    $0x7f,%eax
80101e13:	76 bd                	jbe    80101dd2 <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101e15:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101e18:	89 04 24             	mov    %eax,(%esp)
80101e1b:	e8 f7 e3 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101e20:	8b 45 08             	mov    0x8(%ebp),%eax
80101e23:	8b 50 4c             	mov    0x4c(%eax),%edx
80101e26:	8b 45 08             	mov    0x8(%ebp),%eax
80101e29:	8b 00                	mov    (%eax),%eax
80101e2b:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e2f:	89 04 24             	mov    %eax,(%esp)
80101e32:	e8 c9 f7 ff ff       	call   80101600 <bfree>
    ip->addrs[NDIRECT] = 0;
80101e37:	8b 45 08             	mov    0x8(%ebp),%eax
80101e3a:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101e41:	8b 45 08             	mov    0x8(%ebp),%eax
80101e44:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101e4b:	8b 45 08             	mov    0x8(%ebp),%eax
80101e4e:	89 04 24             	mov    %eax,(%esp)
80101e51:	e8 7e f9 ff ff       	call   801017d4 <iupdate>
}
80101e56:	c9                   	leave  
80101e57:	c3                   	ret    

80101e58 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101e58:	55                   	push   %ebp
80101e59:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101e5b:	8b 45 08             	mov    0x8(%ebp),%eax
80101e5e:	8b 00                	mov    (%eax),%eax
80101e60:	89 c2                	mov    %eax,%edx
80101e62:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e65:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101e68:	8b 45 08             	mov    0x8(%ebp),%eax
80101e6b:	8b 50 04             	mov    0x4(%eax),%edx
80101e6e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e71:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101e74:	8b 45 08             	mov    0x8(%ebp),%eax
80101e77:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101e7b:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e7e:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101e81:	8b 45 08             	mov    0x8(%ebp),%eax
80101e84:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101e88:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e8b:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101e8f:	8b 45 08             	mov    0x8(%ebp),%eax
80101e92:	8b 50 18             	mov    0x18(%eax),%edx
80101e95:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e98:	89 50 10             	mov    %edx,0x10(%eax)
}
80101e9b:	5d                   	pop    %ebp
80101e9c:	c3                   	ret    

80101e9d <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101e9d:	55                   	push   %ebp
80101e9e:	89 e5                	mov    %esp,%ebp
80101ea0:	53                   	push   %ebx
80101ea1:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101ea4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ea7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101eab:	66 83 f8 03          	cmp    $0x3,%ax
80101eaf:	75 60                	jne    80101f11 <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101eb1:	8b 45 08             	mov    0x8(%ebp),%eax
80101eb4:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101eb8:	66 85 c0             	test   %ax,%ax
80101ebb:	78 20                	js     80101edd <readi+0x40>
80101ebd:	8b 45 08             	mov    0x8(%ebp),%eax
80101ec0:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ec4:	66 83 f8 09          	cmp    $0x9,%ax
80101ec8:	7f 13                	jg     80101edd <readi+0x40>
80101eca:	8b 45 08             	mov    0x8(%ebp),%eax
80101ecd:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ed1:	98                   	cwtl   
80101ed2:	8b 04 c5 20 ed 10 80 	mov    -0x7fef12e0(,%eax,8),%eax
80101ed9:	85 c0                	test   %eax,%eax
80101edb:	75 0a                	jne    80101ee7 <readi+0x4a>
      return -1;
80101edd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101ee2:	e9 1e 01 00 00       	jmp    80102005 <readi+0x168>
    return devsw[ip->major].read(ip, dst, n);
80101ee7:	8b 45 08             	mov    0x8(%ebp),%eax
80101eea:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101eee:	98                   	cwtl   
80101eef:	8b 04 c5 20 ed 10 80 	mov    -0x7fef12e0(,%eax,8),%eax
80101ef6:	8b 55 14             	mov    0x14(%ebp),%edx
80101ef9:	89 54 24 08          	mov    %edx,0x8(%esp)
80101efd:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f00:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f04:	8b 55 08             	mov    0x8(%ebp),%edx
80101f07:	89 14 24             	mov    %edx,(%esp)
80101f0a:	ff d0                	call   *%eax
80101f0c:	e9 f4 00 00 00       	jmp    80102005 <readi+0x168>
  }

  if(off > ip->size || off + n < off)
80101f11:	8b 45 08             	mov    0x8(%ebp),%eax
80101f14:	8b 40 18             	mov    0x18(%eax),%eax
80101f17:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f1a:	72 0d                	jb     80101f29 <readi+0x8c>
80101f1c:	8b 45 14             	mov    0x14(%ebp),%eax
80101f1f:	8b 55 10             	mov    0x10(%ebp),%edx
80101f22:	01 d0                	add    %edx,%eax
80101f24:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f27:	73 0a                	jae    80101f33 <readi+0x96>
    return -1;
80101f29:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f2e:	e9 d2 00 00 00       	jmp    80102005 <readi+0x168>
  if(off + n > ip->size)
80101f33:	8b 45 14             	mov    0x14(%ebp),%eax
80101f36:	8b 55 10             	mov    0x10(%ebp),%edx
80101f39:	01 c2                	add    %eax,%edx
80101f3b:	8b 45 08             	mov    0x8(%ebp),%eax
80101f3e:	8b 40 18             	mov    0x18(%eax),%eax
80101f41:	39 c2                	cmp    %eax,%edx
80101f43:	76 0c                	jbe    80101f51 <readi+0xb4>
    n = ip->size - off;
80101f45:	8b 45 08             	mov    0x8(%ebp),%eax
80101f48:	8b 40 18             	mov    0x18(%eax),%eax
80101f4b:	2b 45 10             	sub    0x10(%ebp),%eax
80101f4e:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101f51:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101f58:	e9 99 00 00 00       	jmp    80101ff6 <readi+0x159>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101f5d:	8b 45 10             	mov    0x10(%ebp),%eax
80101f60:	c1 e8 09             	shr    $0x9,%eax
80101f63:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f67:	8b 45 08             	mov    0x8(%ebp),%eax
80101f6a:	89 04 24             	mov    %eax,(%esp)
80101f6d:	e8 c0 fc ff ff       	call   80101c32 <bmap>
80101f72:	8b 55 08             	mov    0x8(%ebp),%edx
80101f75:	8b 12                	mov    (%edx),%edx
80101f77:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f7b:	89 14 24             	mov    %edx,(%esp)
80101f7e:	e8 23 e2 ff ff       	call   801001a6 <bread>
80101f83:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101f86:	8b 45 10             	mov    0x10(%ebp),%eax
80101f89:	89 c2                	mov    %eax,%edx
80101f8b:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80101f91:	b8 00 02 00 00       	mov    $0x200,%eax
80101f96:	89 c1                	mov    %eax,%ecx
80101f98:	29 d1                	sub    %edx,%ecx
80101f9a:	89 ca                	mov    %ecx,%edx
80101f9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f9f:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101fa2:	89 cb                	mov    %ecx,%ebx
80101fa4:	29 c3                	sub    %eax,%ebx
80101fa6:	89 d8                	mov    %ebx,%eax
80101fa8:	39 c2                	cmp    %eax,%edx
80101faa:	0f 46 c2             	cmovbe %edx,%eax
80101fad:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101fb0:	8b 45 10             	mov    0x10(%ebp),%eax
80101fb3:	25 ff 01 00 00       	and    $0x1ff,%eax
80101fb8:	8d 50 10             	lea    0x10(%eax),%edx
80101fbb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fbe:	01 d0                	add    %edx,%eax
80101fc0:	8d 50 08             	lea    0x8(%eax),%edx
80101fc3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fc6:	89 44 24 08          	mov    %eax,0x8(%esp)
80101fca:	89 54 24 04          	mov    %edx,0x4(%esp)
80101fce:	8b 45 0c             	mov    0xc(%ebp),%eax
80101fd1:	89 04 24             	mov    %eax,(%esp)
80101fd4:	e8 58 30 00 00       	call   80105031 <memmove>
    brelse(bp);
80101fd9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fdc:	89 04 24             	mov    %eax,(%esp)
80101fdf:	e8 33 e2 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101fe4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fe7:	01 45 f4             	add    %eax,-0xc(%ebp)
80101fea:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fed:	01 45 10             	add    %eax,0x10(%ebp)
80101ff0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ff3:	01 45 0c             	add    %eax,0xc(%ebp)
80101ff6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ff9:	3b 45 14             	cmp    0x14(%ebp),%eax
80101ffc:	0f 82 5b ff ff ff    	jb     80101f5d <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80102002:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102005:	83 c4 24             	add    $0x24,%esp
80102008:	5b                   	pop    %ebx
80102009:	5d                   	pop    %ebp
8010200a:	c3                   	ret    

8010200b <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
8010200b:	55                   	push   %ebp
8010200c:	89 e5                	mov    %esp,%ebp
8010200e:	53                   	push   %ebx
8010200f:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102012:	8b 45 08             	mov    0x8(%ebp),%eax
80102015:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102019:	66 83 f8 03          	cmp    $0x3,%ax
8010201d:	75 60                	jne    8010207f <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
8010201f:	8b 45 08             	mov    0x8(%ebp),%eax
80102022:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102026:	66 85 c0             	test   %ax,%ax
80102029:	78 20                	js     8010204b <writei+0x40>
8010202b:	8b 45 08             	mov    0x8(%ebp),%eax
8010202e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102032:	66 83 f8 09          	cmp    $0x9,%ax
80102036:	7f 13                	jg     8010204b <writei+0x40>
80102038:	8b 45 08             	mov    0x8(%ebp),%eax
8010203b:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010203f:	98                   	cwtl   
80102040:	8b 04 c5 24 ed 10 80 	mov    -0x7fef12dc(,%eax,8),%eax
80102047:	85 c0                	test   %eax,%eax
80102049:	75 0a                	jne    80102055 <writei+0x4a>
      return -1;
8010204b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102050:	e9 49 01 00 00       	jmp    8010219e <writei+0x193>
    return devsw[ip->major].write(ip, src, n);
80102055:	8b 45 08             	mov    0x8(%ebp),%eax
80102058:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010205c:	98                   	cwtl   
8010205d:	8b 04 c5 24 ed 10 80 	mov    -0x7fef12dc(,%eax,8),%eax
80102064:	8b 55 14             	mov    0x14(%ebp),%edx
80102067:	89 54 24 08          	mov    %edx,0x8(%esp)
8010206b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010206e:	89 54 24 04          	mov    %edx,0x4(%esp)
80102072:	8b 55 08             	mov    0x8(%ebp),%edx
80102075:	89 14 24             	mov    %edx,(%esp)
80102078:	ff d0                	call   *%eax
8010207a:	e9 1f 01 00 00       	jmp    8010219e <writei+0x193>
  }

  if(off > ip->size || off + n < off)
8010207f:	8b 45 08             	mov    0x8(%ebp),%eax
80102082:	8b 40 18             	mov    0x18(%eax),%eax
80102085:	3b 45 10             	cmp    0x10(%ebp),%eax
80102088:	72 0d                	jb     80102097 <writei+0x8c>
8010208a:	8b 45 14             	mov    0x14(%ebp),%eax
8010208d:	8b 55 10             	mov    0x10(%ebp),%edx
80102090:	01 d0                	add    %edx,%eax
80102092:	3b 45 10             	cmp    0x10(%ebp),%eax
80102095:	73 0a                	jae    801020a1 <writei+0x96>
    return -1;
80102097:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010209c:	e9 fd 00 00 00       	jmp    8010219e <writei+0x193>
  if(off + n > MAXFILE*BSIZE)
801020a1:	8b 45 14             	mov    0x14(%ebp),%eax
801020a4:	8b 55 10             	mov    0x10(%ebp),%edx
801020a7:	01 d0                	add    %edx,%eax
801020a9:	3d 00 18 01 00       	cmp    $0x11800,%eax
801020ae:	76 0a                	jbe    801020ba <writei+0xaf>
    return -1;
801020b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801020b5:	e9 e4 00 00 00       	jmp    8010219e <writei+0x193>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801020ba:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801020c1:	e9 a4 00 00 00       	jmp    8010216a <writei+0x15f>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801020c6:	8b 45 10             	mov    0x10(%ebp),%eax
801020c9:	c1 e8 09             	shr    $0x9,%eax
801020cc:	89 44 24 04          	mov    %eax,0x4(%esp)
801020d0:	8b 45 08             	mov    0x8(%ebp),%eax
801020d3:	89 04 24             	mov    %eax,(%esp)
801020d6:	e8 57 fb ff ff       	call   80101c32 <bmap>
801020db:	8b 55 08             	mov    0x8(%ebp),%edx
801020de:	8b 12                	mov    (%edx),%edx
801020e0:	89 44 24 04          	mov    %eax,0x4(%esp)
801020e4:	89 14 24             	mov    %edx,(%esp)
801020e7:	e8 ba e0 ff ff       	call   801001a6 <bread>
801020ec:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
801020ef:	8b 45 10             	mov    0x10(%ebp),%eax
801020f2:	89 c2                	mov    %eax,%edx
801020f4:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
801020fa:	b8 00 02 00 00       	mov    $0x200,%eax
801020ff:	89 c1                	mov    %eax,%ecx
80102101:	29 d1                	sub    %edx,%ecx
80102103:	89 ca                	mov    %ecx,%edx
80102105:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102108:	8b 4d 14             	mov    0x14(%ebp),%ecx
8010210b:	89 cb                	mov    %ecx,%ebx
8010210d:	29 c3                	sub    %eax,%ebx
8010210f:	89 d8                	mov    %ebx,%eax
80102111:	39 c2                	cmp    %eax,%edx
80102113:	0f 46 c2             	cmovbe %edx,%eax
80102116:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102119:	8b 45 10             	mov    0x10(%ebp),%eax
8010211c:	25 ff 01 00 00       	and    $0x1ff,%eax
80102121:	8d 50 10             	lea    0x10(%eax),%edx
80102124:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102127:	01 d0                	add    %edx,%eax
80102129:	8d 50 08             	lea    0x8(%eax),%edx
8010212c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010212f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102133:	8b 45 0c             	mov    0xc(%ebp),%eax
80102136:	89 44 24 04          	mov    %eax,0x4(%esp)
8010213a:	89 14 24             	mov    %edx,(%esp)
8010213d:	e8 ef 2e 00 00       	call   80105031 <memmove>
    log_write(bp);
80102142:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102145:	89 04 24             	mov    %eax,(%esp)
80102148:	e8 c0 12 00 00       	call   8010340d <log_write>
    brelse(bp);
8010214d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102150:	89 04 24             	mov    %eax,(%esp)
80102153:	e8 bf e0 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102158:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010215b:	01 45 f4             	add    %eax,-0xc(%ebp)
8010215e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102161:	01 45 10             	add    %eax,0x10(%ebp)
80102164:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102167:	01 45 0c             	add    %eax,0xc(%ebp)
8010216a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010216d:	3b 45 14             	cmp    0x14(%ebp),%eax
80102170:	0f 82 50 ff ff ff    	jb     801020c6 <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102176:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010217a:	74 1f                	je     8010219b <writei+0x190>
8010217c:	8b 45 08             	mov    0x8(%ebp),%eax
8010217f:	8b 40 18             	mov    0x18(%eax),%eax
80102182:	3b 45 10             	cmp    0x10(%ebp),%eax
80102185:	73 14                	jae    8010219b <writei+0x190>
    ip->size = off;
80102187:	8b 45 08             	mov    0x8(%ebp),%eax
8010218a:	8b 55 10             	mov    0x10(%ebp),%edx
8010218d:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102190:	8b 45 08             	mov    0x8(%ebp),%eax
80102193:	89 04 24             	mov    %eax,(%esp)
80102196:	e8 39 f6 ff ff       	call   801017d4 <iupdate>
  }
  return n;
8010219b:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010219e:	83 c4 24             	add    $0x24,%esp
801021a1:	5b                   	pop    %ebx
801021a2:	5d                   	pop    %ebp
801021a3:	c3                   	ret    

801021a4 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
801021a4:	55                   	push   %ebp
801021a5:	89 e5                	mov    %esp,%ebp
801021a7:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
801021aa:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801021b1:	00 
801021b2:	8b 45 0c             	mov    0xc(%ebp),%eax
801021b5:	89 44 24 04          	mov    %eax,0x4(%esp)
801021b9:	8b 45 08             	mov    0x8(%ebp),%eax
801021bc:	89 04 24             	mov    %eax,(%esp)
801021bf:	e8 11 2f 00 00       	call   801050d5 <strncmp>
}
801021c4:	c9                   	leave  
801021c5:	c3                   	ret    

801021c6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
801021c6:	55                   	push   %ebp
801021c7:	89 e5                	mov    %esp,%ebp
801021c9:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
801021cc:	8b 45 08             	mov    0x8(%ebp),%eax
801021cf:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801021d3:	66 83 f8 01          	cmp    $0x1,%ax
801021d7:	74 0c                	je     801021e5 <dirlookup+0x1f>
    panic("dirlookup not DIR");
801021d9:	c7 04 24 46 84 10 80 	movl   $0x80108446,(%esp)
801021e0:	e8 61 e3 ff ff       	call   80100546 <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
801021e5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801021ec:	e9 87 00 00 00       	jmp    80102278 <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801021f1:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801021f8:	00 
801021f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021fc:	89 44 24 08          	mov    %eax,0x8(%esp)
80102200:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102203:	89 44 24 04          	mov    %eax,0x4(%esp)
80102207:	8b 45 08             	mov    0x8(%ebp),%eax
8010220a:	89 04 24             	mov    %eax,(%esp)
8010220d:	e8 8b fc ff ff       	call   80101e9d <readi>
80102212:	83 f8 10             	cmp    $0x10,%eax
80102215:	74 0c                	je     80102223 <dirlookup+0x5d>
      panic("dirlink read");
80102217:	c7 04 24 58 84 10 80 	movl   $0x80108458,(%esp)
8010221e:	e8 23 e3 ff ff       	call   80100546 <panic>
    if(de.inum == 0)
80102223:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102227:	66 85 c0             	test   %ax,%ax
8010222a:	74 47                	je     80102273 <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
8010222c:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010222f:	83 c0 02             	add    $0x2,%eax
80102232:	89 44 24 04          	mov    %eax,0x4(%esp)
80102236:	8b 45 0c             	mov    0xc(%ebp),%eax
80102239:	89 04 24             	mov    %eax,(%esp)
8010223c:	e8 63 ff ff ff       	call   801021a4 <namecmp>
80102241:	85 c0                	test   %eax,%eax
80102243:	75 2f                	jne    80102274 <dirlookup+0xae>
      // entry matches path element
      if(poff)
80102245:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102249:	74 08                	je     80102253 <dirlookup+0x8d>
        *poff = off;
8010224b:	8b 45 10             	mov    0x10(%ebp),%eax
8010224e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102251:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102253:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102257:	0f b7 c0             	movzwl %ax,%eax
8010225a:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
8010225d:	8b 45 08             	mov    0x8(%ebp),%eax
80102260:	8b 00                	mov    (%eax),%eax
80102262:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102265:	89 54 24 04          	mov    %edx,0x4(%esp)
80102269:	89 04 24             	mov    %eax,(%esp)
8010226c:	e8 1b f6 ff ff       	call   8010188c <iget>
80102271:	eb 19                	jmp    8010228c <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
80102273:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
80102274:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80102278:	8b 45 08             	mov    0x8(%ebp),%eax
8010227b:	8b 40 18             	mov    0x18(%eax),%eax
8010227e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102281:	0f 87 6a ff ff ff    	ja     801021f1 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
80102287:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010228c:	c9                   	leave  
8010228d:	c3                   	ret    

8010228e <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
8010228e:	55                   	push   %ebp
8010228f:	89 e5                	mov    %esp,%ebp
80102291:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102294:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010229b:	00 
8010229c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010229f:	89 44 24 04          	mov    %eax,0x4(%esp)
801022a3:	8b 45 08             	mov    0x8(%ebp),%eax
801022a6:	89 04 24             	mov    %eax,(%esp)
801022a9:	e8 18 ff ff ff       	call   801021c6 <dirlookup>
801022ae:	89 45 f0             	mov    %eax,-0x10(%ebp)
801022b1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801022b5:	74 15                	je     801022cc <dirlink+0x3e>
    iput(ip);
801022b7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022ba:	89 04 24             	mov    %eax,(%esp)
801022bd:	e8 81 f8 ff ff       	call   80101b43 <iput>
    return -1;
801022c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801022c7:	e9 b8 00 00 00       	jmp    80102384 <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801022cc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801022d3:	eb 44                	jmp    80102319 <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801022d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022d8:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801022df:	00 
801022e0:	89 44 24 08          	mov    %eax,0x8(%esp)
801022e4:	8d 45 e0             	lea    -0x20(%ebp),%eax
801022e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801022eb:	8b 45 08             	mov    0x8(%ebp),%eax
801022ee:	89 04 24             	mov    %eax,(%esp)
801022f1:	e8 a7 fb ff ff       	call   80101e9d <readi>
801022f6:	83 f8 10             	cmp    $0x10,%eax
801022f9:	74 0c                	je     80102307 <dirlink+0x79>
      panic("dirlink read");
801022fb:	c7 04 24 58 84 10 80 	movl   $0x80108458,(%esp)
80102302:	e8 3f e2 ff ff       	call   80100546 <panic>
    if(de.inum == 0)
80102307:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010230b:	66 85 c0             	test   %ax,%ax
8010230e:	74 18                	je     80102328 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102310:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102313:	83 c0 10             	add    $0x10,%eax
80102316:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102319:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010231c:	8b 45 08             	mov    0x8(%ebp),%eax
8010231f:	8b 40 18             	mov    0x18(%eax),%eax
80102322:	39 c2                	cmp    %eax,%edx
80102324:	72 af                	jb     801022d5 <dirlink+0x47>
80102326:	eb 01                	jmp    80102329 <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
80102328:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
80102329:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102330:	00 
80102331:	8b 45 0c             	mov    0xc(%ebp),%eax
80102334:	89 44 24 04          	mov    %eax,0x4(%esp)
80102338:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010233b:	83 c0 02             	add    $0x2,%eax
8010233e:	89 04 24             	mov    %eax,(%esp)
80102341:	e8 e7 2d 00 00       	call   8010512d <strncpy>
  de.inum = inum;
80102346:	8b 45 10             	mov    0x10(%ebp),%eax
80102349:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010234d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102350:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102357:	00 
80102358:	89 44 24 08          	mov    %eax,0x8(%esp)
8010235c:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010235f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102363:	8b 45 08             	mov    0x8(%ebp),%eax
80102366:	89 04 24             	mov    %eax,(%esp)
80102369:	e8 9d fc ff ff       	call   8010200b <writei>
8010236e:	83 f8 10             	cmp    $0x10,%eax
80102371:	74 0c                	je     8010237f <dirlink+0xf1>
    panic("dirlink");
80102373:	c7 04 24 65 84 10 80 	movl   $0x80108465,(%esp)
8010237a:	e8 c7 e1 ff ff       	call   80100546 <panic>
  
  return 0;
8010237f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102384:	c9                   	leave  
80102385:	c3                   	ret    

80102386 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102386:	55                   	push   %ebp
80102387:	89 e5                	mov    %esp,%ebp
80102389:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
8010238c:	eb 04                	jmp    80102392 <skipelem+0xc>
    path++;
8010238e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102392:	8b 45 08             	mov    0x8(%ebp),%eax
80102395:	0f b6 00             	movzbl (%eax),%eax
80102398:	3c 2f                	cmp    $0x2f,%al
8010239a:	74 f2                	je     8010238e <skipelem+0x8>
    path++;
  if(*path == 0)
8010239c:	8b 45 08             	mov    0x8(%ebp),%eax
8010239f:	0f b6 00             	movzbl (%eax),%eax
801023a2:	84 c0                	test   %al,%al
801023a4:	75 0a                	jne    801023b0 <skipelem+0x2a>
    return 0;
801023a6:	b8 00 00 00 00       	mov    $0x0,%eax
801023ab:	e9 88 00 00 00       	jmp    80102438 <skipelem+0xb2>
  s = path;
801023b0:	8b 45 08             	mov    0x8(%ebp),%eax
801023b3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
801023b6:	eb 04                	jmp    801023bc <skipelem+0x36>
    path++;
801023b8:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
801023bc:	8b 45 08             	mov    0x8(%ebp),%eax
801023bf:	0f b6 00             	movzbl (%eax),%eax
801023c2:	3c 2f                	cmp    $0x2f,%al
801023c4:	74 0a                	je     801023d0 <skipelem+0x4a>
801023c6:	8b 45 08             	mov    0x8(%ebp),%eax
801023c9:	0f b6 00             	movzbl (%eax),%eax
801023cc:	84 c0                	test   %al,%al
801023ce:	75 e8                	jne    801023b8 <skipelem+0x32>
    path++;
  len = path - s;
801023d0:	8b 55 08             	mov    0x8(%ebp),%edx
801023d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023d6:	89 d1                	mov    %edx,%ecx
801023d8:	29 c1                	sub    %eax,%ecx
801023da:	89 c8                	mov    %ecx,%eax
801023dc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
801023df:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801023e3:	7e 1c                	jle    80102401 <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
801023e5:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801023ec:	00 
801023ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801023f4:	8b 45 0c             	mov    0xc(%ebp),%eax
801023f7:	89 04 24             	mov    %eax,(%esp)
801023fa:	e8 32 2c 00 00       	call   80105031 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801023ff:	eb 2a                	jmp    8010242b <skipelem+0xa5>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80102401:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102404:	89 44 24 08          	mov    %eax,0x8(%esp)
80102408:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010240b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010240f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102412:	89 04 24             	mov    %eax,(%esp)
80102415:	e8 17 2c 00 00       	call   80105031 <memmove>
    name[len] = 0;
8010241a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010241d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102420:	01 d0                	add    %edx,%eax
80102422:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
80102425:	eb 04                	jmp    8010242b <skipelem+0xa5>
    path++;
80102427:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
8010242b:	8b 45 08             	mov    0x8(%ebp),%eax
8010242e:	0f b6 00             	movzbl (%eax),%eax
80102431:	3c 2f                	cmp    $0x2f,%al
80102433:	74 f2                	je     80102427 <skipelem+0xa1>
    path++;
  return path;
80102435:	8b 45 08             	mov    0x8(%ebp),%eax
}
80102438:	c9                   	leave  
80102439:	c3                   	ret    

8010243a <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
8010243a:	55                   	push   %ebp
8010243b:	89 e5                	mov    %esp,%ebp
8010243d:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102440:	8b 45 08             	mov    0x8(%ebp),%eax
80102443:	0f b6 00             	movzbl (%eax),%eax
80102446:	3c 2f                	cmp    $0x2f,%al
80102448:	75 1c                	jne    80102466 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
8010244a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102451:	00 
80102452:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102459:	e8 2e f4 ff ff       	call   8010188c <iget>
8010245e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102461:	e9 af 00 00 00       	jmp    80102515 <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
80102466:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010246c:	8b 40 68             	mov    0x68(%eax),%eax
8010246f:	89 04 24             	mov    %eax,(%esp)
80102472:	e8 e7 f4 ff ff       	call   8010195e <idup>
80102477:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
8010247a:	e9 96 00 00 00       	jmp    80102515 <namex+0xdb>
    ilock(ip);
8010247f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102482:	89 04 24             	mov    %eax,(%esp)
80102485:	e8 06 f5 ff ff       	call   80101990 <ilock>
    if(ip->type != T_DIR){
8010248a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010248d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102491:	66 83 f8 01          	cmp    $0x1,%ax
80102495:	74 15                	je     801024ac <namex+0x72>
      iunlockput(ip);
80102497:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010249a:	89 04 24             	mov    %eax,(%esp)
8010249d:	e8 72 f7 ff ff       	call   80101c14 <iunlockput>
      return 0;
801024a2:	b8 00 00 00 00       	mov    $0x0,%eax
801024a7:	e9 a3 00 00 00       	jmp    8010254f <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
801024ac:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801024b0:	74 1d                	je     801024cf <namex+0x95>
801024b2:	8b 45 08             	mov    0x8(%ebp),%eax
801024b5:	0f b6 00             	movzbl (%eax),%eax
801024b8:	84 c0                	test   %al,%al
801024ba:	75 13                	jne    801024cf <namex+0x95>
      // Stop one level early.
      iunlock(ip);
801024bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024bf:	89 04 24             	mov    %eax,(%esp)
801024c2:	e8 17 f6 ff ff       	call   80101ade <iunlock>
      return ip;
801024c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024ca:	e9 80 00 00 00       	jmp    8010254f <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
801024cf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801024d6:	00 
801024d7:	8b 45 10             	mov    0x10(%ebp),%eax
801024da:	89 44 24 04          	mov    %eax,0x4(%esp)
801024de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024e1:	89 04 24             	mov    %eax,(%esp)
801024e4:	e8 dd fc ff ff       	call   801021c6 <dirlookup>
801024e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
801024ec:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801024f0:	75 12                	jne    80102504 <namex+0xca>
      iunlockput(ip);
801024f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024f5:	89 04 24             	mov    %eax,(%esp)
801024f8:	e8 17 f7 ff ff       	call   80101c14 <iunlockput>
      return 0;
801024fd:	b8 00 00 00 00       	mov    $0x0,%eax
80102502:	eb 4b                	jmp    8010254f <namex+0x115>
    }
    iunlockput(ip);
80102504:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102507:	89 04 24             	mov    %eax,(%esp)
8010250a:	e8 05 f7 ff ff       	call   80101c14 <iunlockput>
    ip = next;
8010250f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102512:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102515:	8b 45 10             	mov    0x10(%ebp),%eax
80102518:	89 44 24 04          	mov    %eax,0x4(%esp)
8010251c:	8b 45 08             	mov    0x8(%ebp),%eax
8010251f:	89 04 24             	mov    %eax,(%esp)
80102522:	e8 5f fe ff ff       	call   80102386 <skipelem>
80102527:	89 45 08             	mov    %eax,0x8(%ebp)
8010252a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010252e:	0f 85 4b ff ff ff    	jne    8010247f <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102534:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102538:	74 12                	je     8010254c <namex+0x112>
    iput(ip);
8010253a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010253d:	89 04 24             	mov    %eax,(%esp)
80102540:	e8 fe f5 ff ff       	call   80101b43 <iput>
    return 0;
80102545:	b8 00 00 00 00       	mov    $0x0,%eax
8010254a:	eb 03                	jmp    8010254f <namex+0x115>
  }
  return ip;
8010254c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010254f:	c9                   	leave  
80102550:	c3                   	ret    

80102551 <namei>:

struct inode*
namei(char *path)
{
80102551:	55                   	push   %ebp
80102552:	89 e5                	mov    %esp,%ebp
80102554:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102557:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010255a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010255e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102565:	00 
80102566:	8b 45 08             	mov    0x8(%ebp),%eax
80102569:	89 04 24             	mov    %eax,(%esp)
8010256c:	e8 c9 fe ff ff       	call   8010243a <namex>
}
80102571:	c9                   	leave  
80102572:	c3                   	ret    

80102573 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102573:	55                   	push   %ebp
80102574:	89 e5                	mov    %esp,%ebp
80102576:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102579:	8b 45 0c             	mov    0xc(%ebp),%eax
8010257c:	89 44 24 08          	mov    %eax,0x8(%esp)
80102580:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102587:	00 
80102588:	8b 45 08             	mov    0x8(%ebp),%eax
8010258b:	89 04 24             	mov    %eax,(%esp)
8010258e:	e8 a7 fe ff ff       	call   8010243a <namex>
}
80102593:	c9                   	leave  
80102594:	c3                   	ret    
80102595:	66 90                	xchg   %ax,%ax
80102597:	90                   	nop

80102598 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102598:	55                   	push   %ebp
80102599:	89 e5                	mov    %esp,%ebp
8010259b:	53                   	push   %ebx
8010259c:	83 ec 14             	sub    $0x14,%esp
8010259f:	8b 45 08             	mov    0x8(%ebp),%eax
801025a2:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801025a6:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801025aa:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801025ae:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801025b2:	ec                   	in     (%dx),%al
801025b3:	89 c3                	mov    %eax,%ebx
801025b5:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801025b8:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801025bc:	83 c4 14             	add    $0x14,%esp
801025bf:	5b                   	pop    %ebx
801025c0:	5d                   	pop    %ebp
801025c1:	c3                   	ret    

801025c2 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
801025c2:	55                   	push   %ebp
801025c3:	89 e5                	mov    %esp,%ebp
801025c5:	57                   	push   %edi
801025c6:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
801025c7:	8b 55 08             	mov    0x8(%ebp),%edx
801025ca:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801025cd:	8b 45 10             	mov    0x10(%ebp),%eax
801025d0:	89 cb                	mov    %ecx,%ebx
801025d2:	89 df                	mov    %ebx,%edi
801025d4:	89 c1                	mov    %eax,%ecx
801025d6:	fc                   	cld    
801025d7:	f3 6d                	rep insl (%dx),%es:(%edi)
801025d9:	89 c8                	mov    %ecx,%eax
801025db:	89 fb                	mov    %edi,%ebx
801025dd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801025e0:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
801025e3:	5b                   	pop    %ebx
801025e4:	5f                   	pop    %edi
801025e5:	5d                   	pop    %ebp
801025e6:	c3                   	ret    

801025e7 <outb>:

static inline void
outb(ushort port, uchar data)
{
801025e7:	55                   	push   %ebp
801025e8:	89 e5                	mov    %esp,%ebp
801025ea:	83 ec 08             	sub    $0x8,%esp
801025ed:	8b 55 08             	mov    0x8(%ebp),%edx
801025f0:	8b 45 0c             	mov    0xc(%ebp),%eax
801025f3:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801025f7:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801025fa:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801025fe:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102602:	ee                   	out    %al,(%dx)
}
80102603:	c9                   	leave  
80102604:	c3                   	ret    

80102605 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80102605:	55                   	push   %ebp
80102606:	89 e5                	mov    %esp,%ebp
80102608:	56                   	push   %esi
80102609:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
8010260a:	8b 55 08             	mov    0x8(%ebp),%edx
8010260d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102610:	8b 45 10             	mov    0x10(%ebp),%eax
80102613:	89 cb                	mov    %ecx,%ebx
80102615:	89 de                	mov    %ebx,%esi
80102617:	89 c1                	mov    %eax,%ecx
80102619:	fc                   	cld    
8010261a:	f3 6f                	rep outsl %ds:(%esi),(%dx)
8010261c:	89 c8                	mov    %ecx,%eax
8010261e:	89 f3                	mov    %esi,%ebx
80102620:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102623:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80102626:	5b                   	pop    %ebx
80102627:	5e                   	pop    %esi
80102628:	5d                   	pop    %ebp
80102629:	c3                   	ret    

8010262a <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
8010262a:	55                   	push   %ebp
8010262b:	89 e5                	mov    %esp,%ebp
8010262d:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80102630:	90                   	nop
80102631:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102638:	e8 5b ff ff ff       	call   80102598 <inb>
8010263d:	0f b6 c0             	movzbl %al,%eax
80102640:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102643:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102646:	25 c0 00 00 00       	and    $0xc0,%eax
8010264b:	83 f8 40             	cmp    $0x40,%eax
8010264e:	75 e1                	jne    80102631 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102650:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102654:	74 11                	je     80102667 <idewait+0x3d>
80102656:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102659:	83 e0 21             	and    $0x21,%eax
8010265c:	85 c0                	test   %eax,%eax
8010265e:	74 07                	je     80102667 <idewait+0x3d>
    return -1;
80102660:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102665:	eb 05                	jmp    8010266c <idewait+0x42>
  return 0;
80102667:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010266c:	c9                   	leave  
8010266d:	c3                   	ret    

8010266e <ideinit>:

void
ideinit(void)
{
8010266e:	55                   	push   %ebp
8010266f:	89 e5                	mov    %esp,%ebp
80102671:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80102674:	c7 44 24 04 6d 84 10 	movl   $0x8010846d,0x4(%esp)
8010267b:	80 
8010267c:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102683:	e8 5a 26 00 00       	call   80104ce2 <initlock>
  picenable(IRQ_IDE);
80102688:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010268f:	e8 85 15 00 00       	call   80103c19 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102694:	a1 20 04 11 80       	mov    0x80110420,%eax
80102699:	83 e8 01             	sub    $0x1,%eax
8010269c:	89 44 24 04          	mov    %eax,0x4(%esp)
801026a0:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801026a7:	e8 12 04 00 00       	call   80102abe <ioapicenable>
  idewait(0);
801026ac:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801026b3:	e8 72 ff ff ff       	call   8010262a <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
801026b8:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
801026bf:	00 
801026c0:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801026c7:	e8 1b ff ff ff       	call   801025e7 <outb>
  for(i=0; i<1000; i++){
801026cc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801026d3:	eb 20                	jmp    801026f5 <ideinit+0x87>
    if(inb(0x1f7) != 0){
801026d5:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801026dc:	e8 b7 fe ff ff       	call   80102598 <inb>
801026e1:	84 c0                	test   %al,%al
801026e3:	74 0c                	je     801026f1 <ideinit+0x83>
      havedisk1 = 1;
801026e5:	c7 05 38 b6 10 80 01 	movl   $0x1,0x8010b638
801026ec:	00 00 00 
      break;
801026ef:	eb 0d                	jmp    801026fe <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801026f1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801026f5:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801026fc:	7e d7                	jle    801026d5 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801026fe:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80102705:	00 
80102706:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010270d:	e8 d5 fe ff ff       	call   801025e7 <outb>
}
80102712:	c9                   	leave  
80102713:	c3                   	ret    

80102714 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80102714:	55                   	push   %ebp
80102715:	89 e5                	mov    %esp,%ebp
80102717:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
8010271a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010271e:	75 0c                	jne    8010272c <idestart+0x18>
    panic("idestart");
80102720:	c7 04 24 71 84 10 80 	movl   $0x80108471,(%esp)
80102727:	e8 1a de ff ff       	call   80100546 <panic>

  idewait(0);
8010272c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102733:	e8 f2 fe ff ff       	call   8010262a <idewait>
  outb(0x3f6, 0);  // generate interrupt
80102738:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010273f:	00 
80102740:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80102747:	e8 9b fe ff ff       	call   801025e7 <outb>
  outb(0x1f2, 1);  // number of sectors
8010274c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102753:	00 
80102754:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
8010275b:	e8 87 fe ff ff       	call   801025e7 <outb>
  outb(0x1f3, b->sector & 0xff);
80102760:	8b 45 08             	mov    0x8(%ebp),%eax
80102763:	8b 40 08             	mov    0x8(%eax),%eax
80102766:	0f b6 c0             	movzbl %al,%eax
80102769:	89 44 24 04          	mov    %eax,0x4(%esp)
8010276d:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102774:	e8 6e fe ff ff       	call   801025e7 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
80102779:	8b 45 08             	mov    0x8(%ebp),%eax
8010277c:	8b 40 08             	mov    0x8(%eax),%eax
8010277f:	c1 e8 08             	shr    $0x8,%eax
80102782:	0f b6 c0             	movzbl %al,%eax
80102785:	89 44 24 04          	mov    %eax,0x4(%esp)
80102789:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102790:	e8 52 fe ff ff       	call   801025e7 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
80102795:	8b 45 08             	mov    0x8(%ebp),%eax
80102798:	8b 40 08             	mov    0x8(%eax),%eax
8010279b:	c1 e8 10             	shr    $0x10,%eax
8010279e:	0f b6 c0             	movzbl %al,%eax
801027a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801027a5:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
801027ac:	e8 36 fe ff ff       	call   801025e7 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
801027b1:	8b 45 08             	mov    0x8(%ebp),%eax
801027b4:	8b 40 04             	mov    0x4(%eax),%eax
801027b7:	83 e0 01             	and    $0x1,%eax
801027ba:	89 c2                	mov    %eax,%edx
801027bc:	c1 e2 04             	shl    $0x4,%edx
801027bf:	8b 45 08             	mov    0x8(%ebp),%eax
801027c2:	8b 40 08             	mov    0x8(%eax),%eax
801027c5:	c1 e8 18             	shr    $0x18,%eax
801027c8:	83 e0 0f             	and    $0xf,%eax
801027cb:	09 d0                	or     %edx,%eax
801027cd:	83 c8 e0             	or     $0xffffffe0,%eax
801027d0:	0f b6 c0             	movzbl %al,%eax
801027d3:	89 44 24 04          	mov    %eax,0x4(%esp)
801027d7:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801027de:	e8 04 fe ff ff       	call   801025e7 <outb>
  if(b->flags & B_DIRTY){
801027e3:	8b 45 08             	mov    0x8(%ebp),%eax
801027e6:	8b 00                	mov    (%eax),%eax
801027e8:	83 e0 04             	and    $0x4,%eax
801027eb:	85 c0                	test   %eax,%eax
801027ed:	74 34                	je     80102823 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
801027ef:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
801027f6:	00 
801027f7:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801027fe:	e8 e4 fd ff ff       	call   801025e7 <outb>
    outsl(0x1f0, b->data, 512/4);
80102803:	8b 45 08             	mov    0x8(%ebp),%eax
80102806:	83 c0 18             	add    $0x18,%eax
80102809:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102810:	00 
80102811:	89 44 24 04          	mov    %eax,0x4(%esp)
80102815:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
8010281c:	e8 e4 fd ff ff       	call   80102605 <outsl>
80102821:	eb 14                	jmp    80102837 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80102823:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
8010282a:	00 
8010282b:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102832:	e8 b0 fd ff ff       	call   801025e7 <outb>
  }
}
80102837:	c9                   	leave  
80102838:	c3                   	ret    

80102839 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102839:	55                   	push   %ebp
8010283a:	89 e5                	mov    %esp,%ebp
8010283c:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
8010283f:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102846:	e8 b8 24 00 00       	call   80104d03 <acquire>
  if((b = idequeue) == 0){
8010284b:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102850:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102853:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102857:	75 11                	jne    8010286a <ideintr+0x31>
    release(&idelock);
80102859:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102860:	e8 00 25 00 00       	call   80104d65 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102865:	e9 90 00 00 00       	jmp    801028fa <ideintr+0xc1>
  }
  idequeue = b->qnext;
8010286a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010286d:	8b 40 14             	mov    0x14(%eax),%eax
80102870:	a3 34 b6 10 80       	mov    %eax,0x8010b634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102875:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102878:	8b 00                	mov    (%eax),%eax
8010287a:	83 e0 04             	and    $0x4,%eax
8010287d:	85 c0                	test   %eax,%eax
8010287f:	75 2e                	jne    801028af <ideintr+0x76>
80102881:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102888:	e8 9d fd ff ff       	call   8010262a <idewait>
8010288d:	85 c0                	test   %eax,%eax
8010288f:	78 1e                	js     801028af <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
80102891:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102894:	83 c0 18             	add    $0x18,%eax
80102897:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010289e:	00 
8010289f:	89 44 24 04          	mov    %eax,0x4(%esp)
801028a3:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801028aa:	e8 13 fd ff ff       	call   801025c2 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
801028af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028b2:	8b 00                	mov    (%eax),%eax
801028b4:	89 c2                	mov    %eax,%edx
801028b6:	83 ca 02             	or     $0x2,%edx
801028b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028bc:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
801028be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028c1:	8b 00                	mov    (%eax),%eax
801028c3:	89 c2                	mov    %eax,%edx
801028c5:	83 e2 fb             	and    $0xfffffffb,%edx
801028c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028cb:	89 10                	mov    %edx,(%eax)
  wakeup(b);
801028cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028d0:	89 04 24             	mov    %eax,(%esp)
801028d3:	e8 26 22 00 00       	call   80104afe <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
801028d8:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801028dd:	85 c0                	test   %eax,%eax
801028df:	74 0d                	je     801028ee <ideintr+0xb5>
    idestart(idequeue);
801028e1:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801028e6:	89 04 24             	mov    %eax,(%esp)
801028e9:	e8 26 fe ff ff       	call   80102714 <idestart>

  release(&idelock);
801028ee:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801028f5:	e8 6b 24 00 00       	call   80104d65 <release>
}
801028fa:	c9                   	leave  
801028fb:	c3                   	ret    

801028fc <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
801028fc:	55                   	push   %ebp
801028fd:	89 e5                	mov    %esp,%ebp
801028ff:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80102902:	8b 45 08             	mov    0x8(%ebp),%eax
80102905:	8b 00                	mov    (%eax),%eax
80102907:	83 e0 01             	and    $0x1,%eax
8010290a:	85 c0                	test   %eax,%eax
8010290c:	75 0c                	jne    8010291a <iderw+0x1e>
    panic("iderw: buf not busy");
8010290e:	c7 04 24 7a 84 10 80 	movl   $0x8010847a,(%esp)
80102915:	e8 2c dc ff ff       	call   80100546 <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
8010291a:	8b 45 08             	mov    0x8(%ebp),%eax
8010291d:	8b 00                	mov    (%eax),%eax
8010291f:	83 e0 06             	and    $0x6,%eax
80102922:	83 f8 02             	cmp    $0x2,%eax
80102925:	75 0c                	jne    80102933 <iderw+0x37>
    panic("iderw: nothing to do");
80102927:	c7 04 24 8e 84 10 80 	movl   $0x8010848e,(%esp)
8010292e:	e8 13 dc ff ff       	call   80100546 <panic>
  if(b->dev != 0 && !havedisk1)
80102933:	8b 45 08             	mov    0x8(%ebp),%eax
80102936:	8b 40 04             	mov    0x4(%eax),%eax
80102939:	85 c0                	test   %eax,%eax
8010293b:	74 15                	je     80102952 <iderw+0x56>
8010293d:	a1 38 b6 10 80       	mov    0x8010b638,%eax
80102942:	85 c0                	test   %eax,%eax
80102944:	75 0c                	jne    80102952 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102946:	c7 04 24 a3 84 10 80 	movl   $0x801084a3,(%esp)
8010294d:	e8 f4 db ff ff       	call   80100546 <panic>

  acquire(&idelock);  //DOC: acquire-lock
80102952:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102959:	e8 a5 23 00 00       	call   80104d03 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
8010295e:	8b 45 08             	mov    0x8(%ebp),%eax
80102961:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
80102968:	c7 45 f4 34 b6 10 80 	movl   $0x8010b634,-0xc(%ebp)
8010296f:	eb 0b                	jmp    8010297c <iderw+0x80>
80102971:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102974:	8b 00                	mov    (%eax),%eax
80102976:	83 c0 14             	add    $0x14,%eax
80102979:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010297c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010297f:	8b 00                	mov    (%eax),%eax
80102981:	85 c0                	test   %eax,%eax
80102983:	75 ec                	jne    80102971 <iderw+0x75>
    ;
  *pp = b;
80102985:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102988:	8b 55 08             	mov    0x8(%ebp),%edx
8010298b:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
8010298d:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102992:	3b 45 08             	cmp    0x8(%ebp),%eax
80102995:	75 22                	jne    801029b9 <iderw+0xbd>
    idestart(b);
80102997:	8b 45 08             	mov    0x8(%ebp),%eax
8010299a:	89 04 24             	mov    %eax,(%esp)
8010299d:	e8 72 fd ff ff       	call   80102714 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
801029a2:	eb 15                	jmp    801029b9 <iderw+0xbd>
    sleep(b, &idelock);
801029a4:	c7 44 24 04 00 b6 10 	movl   $0x8010b600,0x4(%esp)
801029ab:	80 
801029ac:	8b 45 08             	mov    0x8(%ebp),%eax
801029af:	89 04 24             	mov    %eax,(%esp)
801029b2:	e8 6e 20 00 00       	call   80104a25 <sleep>
801029b7:	eb 01                	jmp    801029ba <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
801029b9:	90                   	nop
801029ba:	8b 45 08             	mov    0x8(%ebp),%eax
801029bd:	8b 00                	mov    (%eax),%eax
801029bf:	83 e0 06             	and    $0x6,%eax
801029c2:	83 f8 02             	cmp    $0x2,%eax
801029c5:	75 dd                	jne    801029a4 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
801029c7:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801029ce:	e8 92 23 00 00       	call   80104d65 <release>
}
801029d3:	c9                   	leave  
801029d4:	c3                   	ret    
801029d5:	66 90                	xchg   %ax,%ax
801029d7:	90                   	nop

801029d8 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
801029d8:	55                   	push   %ebp
801029d9:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801029db:	a1 54 fd 10 80       	mov    0x8010fd54,%eax
801029e0:	8b 55 08             	mov    0x8(%ebp),%edx
801029e3:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
801029e5:	a1 54 fd 10 80       	mov    0x8010fd54,%eax
801029ea:	8b 40 10             	mov    0x10(%eax),%eax
}
801029ed:	5d                   	pop    %ebp
801029ee:	c3                   	ret    

801029ef <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
801029ef:	55                   	push   %ebp
801029f0:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801029f2:	a1 54 fd 10 80       	mov    0x8010fd54,%eax
801029f7:	8b 55 08             	mov    0x8(%ebp),%edx
801029fa:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
801029fc:	a1 54 fd 10 80       	mov    0x8010fd54,%eax
80102a01:	8b 55 0c             	mov    0xc(%ebp),%edx
80102a04:	89 50 10             	mov    %edx,0x10(%eax)
}
80102a07:	5d                   	pop    %ebp
80102a08:	c3                   	ret    

80102a09 <ioapicinit>:

void
ioapicinit(void)
{
80102a09:	55                   	push   %ebp
80102a0a:	89 e5                	mov    %esp,%ebp
80102a0c:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102a0f:	a1 24 fe 10 80       	mov    0x8010fe24,%eax
80102a14:	85 c0                	test   %eax,%eax
80102a16:	0f 84 9f 00 00 00    	je     80102abb <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
80102a1c:	c7 05 54 fd 10 80 00 	movl   $0xfec00000,0x8010fd54
80102a23:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102a26:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102a2d:	e8 a6 ff ff ff       	call   801029d8 <ioapicread>
80102a32:	c1 e8 10             	shr    $0x10,%eax
80102a35:	25 ff 00 00 00       	and    $0xff,%eax
80102a3a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102a3d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102a44:	e8 8f ff ff ff       	call   801029d8 <ioapicread>
80102a49:	c1 e8 18             	shr    $0x18,%eax
80102a4c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102a4f:	0f b6 05 20 fe 10 80 	movzbl 0x8010fe20,%eax
80102a56:	0f b6 c0             	movzbl %al,%eax
80102a59:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102a5c:	74 0c                	je     80102a6a <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102a5e:	c7 04 24 c4 84 10 80 	movl   $0x801084c4,(%esp)
80102a65:	e8 40 d9 ff ff       	call   801003aa <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102a6a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102a71:	eb 3e                	jmp    80102ab1 <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102a73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a76:	83 c0 20             	add    $0x20,%eax
80102a79:	0d 00 00 01 00       	or     $0x10000,%eax
80102a7e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a81:	83 c2 08             	add    $0x8,%edx
80102a84:	01 d2                	add    %edx,%edx
80102a86:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a8a:	89 14 24             	mov    %edx,(%esp)
80102a8d:	e8 5d ff ff ff       	call   801029ef <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102a92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a95:	83 c0 08             	add    $0x8,%eax
80102a98:	01 c0                	add    %eax,%eax
80102a9a:	83 c0 01             	add    $0x1,%eax
80102a9d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102aa4:	00 
80102aa5:	89 04 24             	mov    %eax,(%esp)
80102aa8:	e8 42 ff ff ff       	call   801029ef <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102aad:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102ab1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ab4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102ab7:	7e ba                	jle    80102a73 <ioapicinit+0x6a>
80102ab9:	eb 01                	jmp    80102abc <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
80102abb:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102abc:	c9                   	leave  
80102abd:	c3                   	ret    

80102abe <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102abe:	55                   	push   %ebp
80102abf:	89 e5                	mov    %esp,%ebp
80102ac1:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102ac4:	a1 24 fe 10 80       	mov    0x8010fe24,%eax
80102ac9:	85 c0                	test   %eax,%eax
80102acb:	74 39                	je     80102b06 <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102acd:	8b 45 08             	mov    0x8(%ebp),%eax
80102ad0:	83 c0 20             	add    $0x20,%eax
80102ad3:	8b 55 08             	mov    0x8(%ebp),%edx
80102ad6:	83 c2 08             	add    $0x8,%edx
80102ad9:	01 d2                	add    %edx,%edx
80102adb:	89 44 24 04          	mov    %eax,0x4(%esp)
80102adf:	89 14 24             	mov    %edx,(%esp)
80102ae2:	e8 08 ff ff ff       	call   801029ef <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102ae7:	8b 45 0c             	mov    0xc(%ebp),%eax
80102aea:	c1 e0 18             	shl    $0x18,%eax
80102aed:	8b 55 08             	mov    0x8(%ebp),%edx
80102af0:	83 c2 08             	add    $0x8,%edx
80102af3:	01 d2                	add    %edx,%edx
80102af5:	83 c2 01             	add    $0x1,%edx
80102af8:	89 44 24 04          	mov    %eax,0x4(%esp)
80102afc:	89 14 24             	mov    %edx,(%esp)
80102aff:	e8 eb fe ff ff       	call   801029ef <ioapicwrite>
80102b04:	eb 01                	jmp    80102b07 <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
80102b06:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
80102b07:	c9                   	leave  
80102b08:	c3                   	ret    
80102b09:	66 90                	xchg   %ax,%ax
80102b0b:	90                   	nop

80102b0c <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102b0c:	55                   	push   %ebp
80102b0d:	89 e5                	mov    %esp,%ebp
80102b0f:	8b 45 08             	mov    0x8(%ebp),%eax
80102b12:	05 00 00 00 80       	add    $0x80000000,%eax
80102b17:	5d                   	pop    %ebp
80102b18:	c3                   	ret    

80102b19 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102b19:	55                   	push   %ebp
80102b1a:	89 e5                	mov    %esp,%ebp
80102b1c:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102b1f:	c7 44 24 04 f6 84 10 	movl   $0x801084f6,0x4(%esp)
80102b26:	80 
80102b27:	c7 04 24 60 fd 10 80 	movl   $0x8010fd60,(%esp)
80102b2e:	e8 af 21 00 00       	call   80104ce2 <initlock>
  kmem.use_lock = 0;
80102b33:	c7 05 94 fd 10 80 00 	movl   $0x0,0x8010fd94
80102b3a:	00 00 00 
  freerange(vstart, vend);
80102b3d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b40:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b44:	8b 45 08             	mov    0x8(%ebp),%eax
80102b47:	89 04 24             	mov    %eax,(%esp)
80102b4a:	e8 26 00 00 00       	call   80102b75 <freerange>
}
80102b4f:	c9                   	leave  
80102b50:	c3                   	ret    

80102b51 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102b51:	55                   	push   %ebp
80102b52:	89 e5                	mov    %esp,%ebp
80102b54:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102b57:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b5a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b5e:	8b 45 08             	mov    0x8(%ebp),%eax
80102b61:	89 04 24             	mov    %eax,(%esp)
80102b64:	e8 0c 00 00 00       	call   80102b75 <freerange>
  kmem.use_lock = 1;
80102b69:	c7 05 94 fd 10 80 01 	movl   $0x1,0x8010fd94
80102b70:	00 00 00 
}
80102b73:	c9                   	leave  
80102b74:	c3                   	ret    

80102b75 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102b75:	55                   	push   %ebp
80102b76:	89 e5                	mov    %esp,%ebp
80102b78:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102b7b:	8b 45 08             	mov    0x8(%ebp),%eax
80102b7e:	05 ff 0f 00 00       	add    $0xfff,%eax
80102b83:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102b88:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102b8b:	eb 12                	jmp    80102b9f <freerange+0x2a>
    kfree(p);
80102b8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b90:	89 04 24             	mov    %eax,(%esp)
80102b93:	e8 16 00 00 00       	call   80102bae <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102b98:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102b9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ba2:	05 00 10 00 00       	add    $0x1000,%eax
80102ba7:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102baa:	76 e1                	jbe    80102b8d <freerange+0x18>
    kfree(p);
}
80102bac:	c9                   	leave  
80102bad:	c3                   	ret    

80102bae <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102bae:	55                   	push   %ebp
80102baf:	89 e5                	mov    %esp,%ebp
80102bb1:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102bb4:	8b 45 08             	mov    0x8(%ebp),%eax
80102bb7:	25 ff 0f 00 00       	and    $0xfff,%eax
80102bbc:	85 c0                	test   %eax,%eax
80102bbe:	75 1b                	jne    80102bdb <kfree+0x2d>
80102bc0:	81 7d 08 1c 2c 11 80 	cmpl   $0x80112c1c,0x8(%ebp)
80102bc7:	72 12                	jb     80102bdb <kfree+0x2d>
80102bc9:	8b 45 08             	mov    0x8(%ebp),%eax
80102bcc:	89 04 24             	mov    %eax,(%esp)
80102bcf:	e8 38 ff ff ff       	call   80102b0c <v2p>
80102bd4:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102bd9:	76 0c                	jbe    80102be7 <kfree+0x39>
    panic("kfree");
80102bdb:	c7 04 24 fb 84 10 80 	movl   $0x801084fb,(%esp)
80102be2:	e8 5f d9 ff ff       	call   80100546 <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102be7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102bee:	00 
80102bef:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102bf6:	00 
80102bf7:	8b 45 08             	mov    0x8(%ebp),%eax
80102bfa:	89 04 24             	mov    %eax,(%esp)
80102bfd:	e8 5c 23 00 00       	call   80104f5e <memset>

  if(kmem.use_lock)
80102c02:	a1 94 fd 10 80       	mov    0x8010fd94,%eax
80102c07:	85 c0                	test   %eax,%eax
80102c09:	74 0c                	je     80102c17 <kfree+0x69>
    acquire(&kmem.lock);
80102c0b:	c7 04 24 60 fd 10 80 	movl   $0x8010fd60,(%esp)
80102c12:	e8 ec 20 00 00       	call   80104d03 <acquire>
  r = (struct run*)v;
80102c17:	8b 45 08             	mov    0x8(%ebp),%eax
80102c1a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102c1d:	8b 15 98 fd 10 80    	mov    0x8010fd98,%edx
80102c23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c26:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102c28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c2b:	a3 98 fd 10 80       	mov    %eax,0x8010fd98
  if(kmem.use_lock)
80102c30:	a1 94 fd 10 80       	mov    0x8010fd94,%eax
80102c35:	85 c0                	test   %eax,%eax
80102c37:	74 0c                	je     80102c45 <kfree+0x97>
    release(&kmem.lock);
80102c39:	c7 04 24 60 fd 10 80 	movl   $0x8010fd60,(%esp)
80102c40:	e8 20 21 00 00       	call   80104d65 <release>
}
80102c45:	c9                   	leave  
80102c46:	c3                   	ret    

80102c47 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102c47:	55                   	push   %ebp
80102c48:	89 e5                	mov    %esp,%ebp
80102c4a:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102c4d:	a1 94 fd 10 80       	mov    0x8010fd94,%eax
80102c52:	85 c0                	test   %eax,%eax
80102c54:	74 0c                	je     80102c62 <kalloc+0x1b>
    acquire(&kmem.lock);
80102c56:	c7 04 24 60 fd 10 80 	movl   $0x8010fd60,(%esp)
80102c5d:	e8 a1 20 00 00       	call   80104d03 <acquire>
  r = kmem.freelist;
80102c62:	a1 98 fd 10 80       	mov    0x8010fd98,%eax
80102c67:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102c6a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102c6e:	74 0a                	je     80102c7a <kalloc+0x33>
    kmem.freelist = r->next;
80102c70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c73:	8b 00                	mov    (%eax),%eax
80102c75:	a3 98 fd 10 80       	mov    %eax,0x8010fd98
  if(kmem.use_lock)
80102c7a:	a1 94 fd 10 80       	mov    0x8010fd94,%eax
80102c7f:	85 c0                	test   %eax,%eax
80102c81:	74 0c                	je     80102c8f <kalloc+0x48>
    release(&kmem.lock);
80102c83:	c7 04 24 60 fd 10 80 	movl   $0x8010fd60,(%esp)
80102c8a:	e8 d6 20 00 00       	call   80104d65 <release>
  return (char*)r;
80102c8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102c92:	c9                   	leave  
80102c93:	c3                   	ret    

80102c94 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102c94:	55                   	push   %ebp
80102c95:	89 e5                	mov    %esp,%ebp
80102c97:	53                   	push   %ebx
80102c98:	83 ec 14             	sub    $0x14,%esp
80102c9b:	8b 45 08             	mov    0x8(%ebp),%eax
80102c9e:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102ca2:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102ca6:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102caa:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102cae:	ec                   	in     (%dx),%al
80102caf:	89 c3                	mov    %eax,%ebx
80102cb1:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102cb4:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102cb8:	83 c4 14             	add    $0x14,%esp
80102cbb:	5b                   	pop    %ebx
80102cbc:	5d                   	pop    %ebp
80102cbd:	c3                   	ret    

80102cbe <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102cbe:	55                   	push   %ebp
80102cbf:	89 e5                	mov    %esp,%ebp
80102cc1:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102cc4:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102ccb:	e8 c4 ff ff ff       	call   80102c94 <inb>
80102cd0:	0f b6 c0             	movzbl %al,%eax
80102cd3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102cd6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cd9:	83 e0 01             	and    $0x1,%eax
80102cdc:	85 c0                	test   %eax,%eax
80102cde:	75 0a                	jne    80102cea <kbdgetc+0x2c>
    return -1;
80102ce0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102ce5:	e9 25 01 00 00       	jmp    80102e0f <kbdgetc+0x151>
  data = inb(KBDATAP);
80102cea:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102cf1:	e8 9e ff ff ff       	call   80102c94 <inb>
80102cf6:	0f b6 c0             	movzbl %al,%eax
80102cf9:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102cfc:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102d03:	75 17                	jne    80102d1c <kbdgetc+0x5e>
    shift |= E0ESC;
80102d05:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d0a:	83 c8 40             	or     $0x40,%eax
80102d0d:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102d12:	b8 00 00 00 00       	mov    $0x0,%eax
80102d17:	e9 f3 00 00 00       	jmp    80102e0f <kbdgetc+0x151>
  } else if(data & 0x80){
80102d1c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d1f:	25 80 00 00 00       	and    $0x80,%eax
80102d24:	85 c0                	test   %eax,%eax
80102d26:	74 45                	je     80102d6d <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102d28:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d2d:	83 e0 40             	and    $0x40,%eax
80102d30:	85 c0                	test   %eax,%eax
80102d32:	75 08                	jne    80102d3c <kbdgetc+0x7e>
80102d34:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d37:	83 e0 7f             	and    $0x7f,%eax
80102d3a:	eb 03                	jmp    80102d3f <kbdgetc+0x81>
80102d3c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d3f:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102d42:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d45:	05 20 90 10 80       	add    $0x80109020,%eax
80102d4a:	0f b6 00             	movzbl (%eax),%eax
80102d4d:	83 c8 40             	or     $0x40,%eax
80102d50:	0f b6 c0             	movzbl %al,%eax
80102d53:	f7 d0                	not    %eax
80102d55:	89 c2                	mov    %eax,%edx
80102d57:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d5c:	21 d0                	and    %edx,%eax
80102d5e:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102d63:	b8 00 00 00 00       	mov    $0x0,%eax
80102d68:	e9 a2 00 00 00       	jmp    80102e0f <kbdgetc+0x151>
  } else if(shift & E0ESC){
80102d6d:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d72:	83 e0 40             	and    $0x40,%eax
80102d75:	85 c0                	test   %eax,%eax
80102d77:	74 14                	je     80102d8d <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102d79:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102d80:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d85:	83 e0 bf             	and    $0xffffffbf,%eax
80102d88:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  }

  shift |= shiftcode[data];
80102d8d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d90:	05 20 90 10 80       	add    $0x80109020,%eax
80102d95:	0f b6 00             	movzbl (%eax),%eax
80102d98:	0f b6 d0             	movzbl %al,%edx
80102d9b:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102da0:	09 d0                	or     %edx,%eax
80102da2:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  shift ^= togglecode[data];
80102da7:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102daa:	05 20 91 10 80       	add    $0x80109120,%eax
80102daf:	0f b6 00             	movzbl (%eax),%eax
80102db2:	0f b6 d0             	movzbl %al,%edx
80102db5:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102dba:	31 d0                	xor    %edx,%eax
80102dbc:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102dc1:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102dc6:	83 e0 03             	and    $0x3,%eax
80102dc9:	8b 14 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%edx
80102dd0:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102dd3:	01 d0                	add    %edx,%eax
80102dd5:	0f b6 00             	movzbl (%eax),%eax
80102dd8:	0f b6 c0             	movzbl %al,%eax
80102ddb:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102dde:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102de3:	83 e0 08             	and    $0x8,%eax
80102de6:	85 c0                	test   %eax,%eax
80102de8:	74 22                	je     80102e0c <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
80102dea:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102dee:	76 0c                	jbe    80102dfc <kbdgetc+0x13e>
80102df0:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102df4:	77 06                	ja     80102dfc <kbdgetc+0x13e>
      c += 'A' - 'a';
80102df6:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102dfa:	eb 10                	jmp    80102e0c <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80102dfc:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102e00:	76 0a                	jbe    80102e0c <kbdgetc+0x14e>
80102e02:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102e06:	77 04                	ja     80102e0c <kbdgetc+0x14e>
      c += 'a' - 'A';
80102e08:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102e0c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102e0f:	c9                   	leave  
80102e10:	c3                   	ret    

80102e11 <kbdintr>:

void
kbdintr(void)
{
80102e11:	55                   	push   %ebp
80102e12:	89 e5                	mov    %esp,%ebp
80102e14:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102e17:	c7 04 24 be 2c 10 80 	movl   $0x80102cbe,(%esp)
80102e1e:	e8 93 d9 ff ff       	call   801007b6 <consoleintr>
}
80102e23:	c9                   	leave  
80102e24:	c3                   	ret    
80102e25:	66 90                	xchg   %ax,%ax
80102e27:	90                   	nop

80102e28 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102e28:	55                   	push   %ebp
80102e29:	89 e5                	mov    %esp,%ebp
80102e2b:	83 ec 08             	sub    $0x8,%esp
80102e2e:	8b 55 08             	mov    0x8(%ebp),%edx
80102e31:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e34:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102e38:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e3b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102e3f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102e43:	ee                   	out    %al,(%dx)
}
80102e44:	c9                   	leave  
80102e45:	c3                   	ret    

80102e46 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102e46:	55                   	push   %ebp
80102e47:	89 e5                	mov    %esp,%ebp
80102e49:	53                   	push   %ebx
80102e4a:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102e4d:	9c                   	pushf  
80102e4e:	5b                   	pop    %ebx
80102e4f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80102e52:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102e55:	83 c4 10             	add    $0x10,%esp
80102e58:	5b                   	pop    %ebx
80102e59:	5d                   	pop    %ebp
80102e5a:	c3                   	ret    

80102e5b <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102e5b:	55                   	push   %ebp
80102e5c:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102e5e:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102e63:	8b 55 08             	mov    0x8(%ebp),%edx
80102e66:	c1 e2 02             	shl    $0x2,%edx
80102e69:	01 c2                	add    %eax,%edx
80102e6b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e6e:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102e70:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102e75:	83 c0 20             	add    $0x20,%eax
80102e78:	8b 00                	mov    (%eax),%eax
}
80102e7a:	5d                   	pop    %ebp
80102e7b:	c3                   	ret    

80102e7c <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
80102e7c:	55                   	push   %ebp
80102e7d:	89 e5                	mov    %esp,%ebp
80102e7f:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102e82:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102e87:	85 c0                	test   %eax,%eax
80102e89:	0f 84 47 01 00 00    	je     80102fd6 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102e8f:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102e96:	00 
80102e97:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102e9e:	e8 b8 ff ff ff       	call   80102e5b <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102ea3:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102eaa:	00 
80102eab:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102eb2:	e8 a4 ff ff ff       	call   80102e5b <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102eb7:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102ebe:	00 
80102ebf:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102ec6:	e8 90 ff ff ff       	call   80102e5b <lapicw>
  lapicw(TICR, 10000000); 
80102ecb:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102ed2:	00 
80102ed3:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102eda:	e8 7c ff ff ff       	call   80102e5b <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102edf:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102ee6:	00 
80102ee7:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102eee:	e8 68 ff ff ff       	call   80102e5b <lapicw>
  lapicw(LINT1, MASKED);
80102ef3:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102efa:	00 
80102efb:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102f02:	e8 54 ff ff ff       	call   80102e5b <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102f07:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102f0c:	83 c0 30             	add    $0x30,%eax
80102f0f:	8b 00                	mov    (%eax),%eax
80102f11:	c1 e8 10             	shr    $0x10,%eax
80102f14:	25 ff 00 00 00       	and    $0xff,%eax
80102f19:	83 f8 03             	cmp    $0x3,%eax
80102f1c:	76 14                	jbe    80102f32 <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80102f1e:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102f25:	00 
80102f26:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102f2d:	e8 29 ff ff ff       	call   80102e5b <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102f32:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102f39:	00 
80102f3a:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102f41:	e8 15 ff ff ff       	call   80102e5b <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102f46:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f4d:	00 
80102f4e:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102f55:	e8 01 ff ff ff       	call   80102e5b <lapicw>
  lapicw(ESR, 0);
80102f5a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f61:	00 
80102f62:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102f69:	e8 ed fe ff ff       	call   80102e5b <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102f6e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f75:	00 
80102f76:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102f7d:	e8 d9 fe ff ff       	call   80102e5b <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102f82:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f89:	00 
80102f8a:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102f91:	e8 c5 fe ff ff       	call   80102e5b <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102f96:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80102f9d:	00 
80102f9e:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102fa5:	e8 b1 fe ff ff       	call   80102e5b <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102faa:	90                   	nop
80102fab:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102fb0:	05 00 03 00 00       	add    $0x300,%eax
80102fb5:	8b 00                	mov    (%eax),%eax
80102fb7:	25 00 10 00 00       	and    $0x1000,%eax
80102fbc:	85 c0                	test   %eax,%eax
80102fbe:	75 eb                	jne    80102fab <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102fc0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102fc7:	00 
80102fc8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80102fcf:	e8 87 fe ff ff       	call   80102e5b <lapicw>
80102fd4:	eb 01                	jmp    80102fd7 <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
80102fd6:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80102fd7:	c9                   	leave  
80102fd8:	c3                   	ret    

80102fd9 <cpunum>:

int
cpunum(void)
{
80102fd9:	55                   	push   %ebp
80102fda:	89 e5                	mov    %esp,%ebp
80102fdc:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80102fdf:	e8 62 fe ff ff       	call   80102e46 <readeflags>
80102fe4:	25 00 02 00 00       	and    $0x200,%eax
80102fe9:	85 c0                	test   %eax,%eax
80102feb:	74 29                	je     80103016 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80102fed:	a1 40 b6 10 80       	mov    0x8010b640,%eax
80102ff2:	85 c0                	test   %eax,%eax
80102ff4:	0f 94 c2             	sete   %dl
80102ff7:	83 c0 01             	add    $0x1,%eax
80102ffa:	a3 40 b6 10 80       	mov    %eax,0x8010b640
80102fff:	84 d2                	test   %dl,%dl
80103001:	74 13                	je     80103016 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80103003:	8b 45 04             	mov    0x4(%ebp),%eax
80103006:	89 44 24 04          	mov    %eax,0x4(%esp)
8010300a:	c7 04 24 04 85 10 80 	movl   $0x80108504,(%esp)
80103011:	e8 94 d3 ff ff       	call   801003aa <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80103016:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
8010301b:	85 c0                	test   %eax,%eax
8010301d:	74 0f                	je     8010302e <cpunum+0x55>
    return lapic[ID]>>24;
8010301f:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80103024:	83 c0 20             	add    $0x20,%eax
80103027:	8b 00                	mov    (%eax),%eax
80103029:	c1 e8 18             	shr    $0x18,%eax
8010302c:	eb 05                	jmp    80103033 <cpunum+0x5a>
  return 0;
8010302e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103033:	c9                   	leave  
80103034:	c3                   	ret    

80103035 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103035:	55                   	push   %ebp
80103036:	89 e5                	mov    %esp,%ebp
80103038:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
8010303b:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80103040:	85 c0                	test   %eax,%eax
80103042:	74 14                	je     80103058 <lapiceoi+0x23>
    lapicw(EOI, 0);
80103044:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010304b:	00 
8010304c:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103053:	e8 03 fe ff ff       	call   80102e5b <lapicw>
}
80103058:	c9                   	leave  
80103059:	c3                   	ret    

8010305a <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
8010305a:	55                   	push   %ebp
8010305b:	89 e5                	mov    %esp,%ebp
}
8010305d:	5d                   	pop    %ebp
8010305e:	c3                   	ret    

8010305f <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010305f:	55                   	push   %ebp
80103060:	89 e5                	mov    %esp,%ebp
80103062:	83 ec 1c             	sub    $0x1c,%esp
80103065:	8b 45 08             	mov    0x8(%ebp),%eax
80103068:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
8010306b:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103072:	00 
80103073:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
8010307a:	e8 a9 fd ff ff       	call   80102e28 <outb>
  outb(IO_RTC+1, 0x0A);
8010307f:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103086:	00 
80103087:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
8010308e:	e8 95 fd ff ff       	call   80102e28 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103093:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
8010309a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010309d:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
801030a2:	8b 45 f8             	mov    -0x8(%ebp),%eax
801030a5:	8d 50 02             	lea    0x2(%eax),%edx
801030a8:	8b 45 0c             	mov    0xc(%ebp),%eax
801030ab:	c1 e8 04             	shr    $0x4,%eax
801030ae:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
801030b1:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801030b5:	c1 e0 18             	shl    $0x18,%eax
801030b8:	89 44 24 04          	mov    %eax,0x4(%esp)
801030bc:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801030c3:	e8 93 fd ff ff       	call   80102e5b <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801030c8:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
801030cf:	00 
801030d0:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801030d7:	e8 7f fd ff ff       	call   80102e5b <lapicw>
  microdelay(200);
801030dc:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801030e3:	e8 72 ff ff ff       	call   8010305a <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
801030e8:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
801030ef:	00 
801030f0:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801030f7:	e8 5f fd ff ff       	call   80102e5b <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801030fc:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103103:	e8 52 ff ff ff       	call   8010305a <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103108:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010310f:	eb 40                	jmp    80103151 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103111:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103115:	c1 e0 18             	shl    $0x18,%eax
80103118:	89 44 24 04          	mov    %eax,0x4(%esp)
8010311c:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103123:	e8 33 fd ff ff       	call   80102e5b <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103128:	8b 45 0c             	mov    0xc(%ebp),%eax
8010312b:	c1 e8 0c             	shr    $0xc,%eax
8010312e:	80 cc 06             	or     $0x6,%ah
80103131:	89 44 24 04          	mov    %eax,0x4(%esp)
80103135:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010313c:	e8 1a fd ff ff       	call   80102e5b <lapicw>
    microdelay(200);
80103141:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103148:	e8 0d ff ff ff       	call   8010305a <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010314d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103151:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103155:	7e ba                	jle    80103111 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103157:	c9                   	leave  
80103158:	c3                   	ret    
80103159:	66 90                	xchg   %ax,%ax
8010315b:	90                   	nop

8010315c <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
8010315c:	55                   	push   %ebp
8010315d:	89 e5                	mov    %esp,%ebp
8010315f:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103162:	c7 44 24 04 30 85 10 	movl   $0x80108530,0x4(%esp)
80103169:	80 
8010316a:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
80103171:	e8 6c 1b 00 00       	call   80104ce2 <initlock>
  readsb(ROOTDEV, &sb);
80103176:	8d 45 e8             	lea    -0x18(%ebp),%eax
80103179:	89 44 24 04          	mov    %eax,0x4(%esp)
8010317d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103184:	e8 87 e2 ff ff       	call   80101410 <readsb>
  log.start = sb.size - sb.nlog;
80103189:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010318c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010318f:	89 d1                	mov    %edx,%ecx
80103191:	29 c1                	sub    %eax,%ecx
80103193:	89 c8                	mov    %ecx,%eax
80103195:	a3 d4 fd 10 80       	mov    %eax,0x8010fdd4
  log.size = sb.nlog;
8010319a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010319d:	a3 d8 fd 10 80       	mov    %eax,0x8010fdd8
  log.dev = ROOTDEV;
801031a2:	c7 05 e0 fd 10 80 01 	movl   $0x1,0x8010fde0
801031a9:	00 00 00 
  recover_from_log();
801031ac:	e8 9a 01 00 00       	call   8010334b <recover_from_log>
}
801031b1:	c9                   	leave  
801031b2:	c3                   	ret    

801031b3 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801031b3:	55                   	push   %ebp
801031b4:	89 e5                	mov    %esp,%ebp
801031b6:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801031b9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801031c0:	e9 8c 00 00 00       	jmp    80103251 <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801031c5:	8b 15 d4 fd 10 80    	mov    0x8010fdd4,%edx
801031cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031ce:	01 d0                	add    %edx,%eax
801031d0:	83 c0 01             	add    $0x1,%eax
801031d3:	89 c2                	mov    %eax,%edx
801031d5:	a1 e0 fd 10 80       	mov    0x8010fde0,%eax
801031da:	89 54 24 04          	mov    %edx,0x4(%esp)
801031de:	89 04 24             	mov    %eax,(%esp)
801031e1:	e8 c0 cf ff ff       	call   801001a6 <bread>
801031e6:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
801031e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031ec:	83 c0 10             	add    $0x10,%eax
801031ef:	8b 04 85 a8 fd 10 80 	mov    -0x7fef0258(,%eax,4),%eax
801031f6:	89 c2                	mov    %eax,%edx
801031f8:	a1 e0 fd 10 80       	mov    0x8010fde0,%eax
801031fd:	89 54 24 04          	mov    %edx,0x4(%esp)
80103201:	89 04 24             	mov    %eax,(%esp)
80103204:	e8 9d cf ff ff       	call   801001a6 <bread>
80103209:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
8010320c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010320f:	8d 50 18             	lea    0x18(%eax),%edx
80103212:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103215:	83 c0 18             	add    $0x18,%eax
80103218:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010321f:	00 
80103220:	89 54 24 04          	mov    %edx,0x4(%esp)
80103224:	89 04 24             	mov    %eax,(%esp)
80103227:	e8 05 1e 00 00       	call   80105031 <memmove>
    bwrite(dbuf);  // write dst to disk
8010322c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010322f:	89 04 24             	mov    %eax,(%esp)
80103232:	e8 a6 cf ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103237:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010323a:	89 04 24             	mov    %eax,(%esp)
8010323d:	e8 d5 cf ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103242:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103245:	89 04 24             	mov    %eax,(%esp)
80103248:	e8 ca cf ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010324d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103251:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
80103256:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103259:	0f 8f 66 ff ff ff    	jg     801031c5 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
8010325f:	c9                   	leave  
80103260:	c3                   	ret    

80103261 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103261:	55                   	push   %ebp
80103262:	89 e5                	mov    %esp,%ebp
80103264:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103267:	a1 d4 fd 10 80       	mov    0x8010fdd4,%eax
8010326c:	89 c2                	mov    %eax,%edx
8010326e:	a1 e0 fd 10 80       	mov    0x8010fde0,%eax
80103273:	89 54 24 04          	mov    %edx,0x4(%esp)
80103277:	89 04 24             	mov    %eax,(%esp)
8010327a:	e8 27 cf ff ff       	call   801001a6 <bread>
8010327f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103282:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103285:	83 c0 18             	add    $0x18,%eax
80103288:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
8010328b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010328e:	8b 00                	mov    (%eax),%eax
80103290:	a3 e4 fd 10 80       	mov    %eax,0x8010fde4
  for (i = 0; i < log.lh.n; i++) {
80103295:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010329c:	eb 1b                	jmp    801032b9 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
8010329e:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032a1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801032a4:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
801032a8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801032ab:	83 c2 10             	add    $0x10,%edx
801032ae:	89 04 95 a8 fd 10 80 	mov    %eax,-0x7fef0258(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
801032b5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801032b9:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
801032be:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801032c1:	7f db                	jg     8010329e <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
801032c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032c6:	89 04 24             	mov    %eax,(%esp)
801032c9:	e8 49 cf ff ff       	call   80100217 <brelse>
}
801032ce:	c9                   	leave  
801032cf:	c3                   	ret    

801032d0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801032d0:	55                   	push   %ebp
801032d1:	89 e5                	mov    %esp,%ebp
801032d3:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801032d6:	a1 d4 fd 10 80       	mov    0x8010fdd4,%eax
801032db:	89 c2                	mov    %eax,%edx
801032dd:	a1 e0 fd 10 80       	mov    0x8010fde0,%eax
801032e2:	89 54 24 04          	mov    %edx,0x4(%esp)
801032e6:	89 04 24             	mov    %eax,(%esp)
801032e9:	e8 b8 ce ff ff       	call   801001a6 <bread>
801032ee:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801032f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032f4:	83 c0 18             	add    $0x18,%eax
801032f7:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801032fa:	8b 15 e4 fd 10 80    	mov    0x8010fde4,%edx
80103300:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103303:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103305:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010330c:	eb 1b                	jmp    80103329 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
8010330e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103311:	83 c0 10             	add    $0x10,%eax
80103314:	8b 0c 85 a8 fd 10 80 	mov    -0x7fef0258(,%eax,4),%ecx
8010331b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010331e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103321:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103325:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103329:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
8010332e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103331:	7f db                	jg     8010330e <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80103333:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103336:	89 04 24             	mov    %eax,(%esp)
80103339:	e8 9f ce ff ff       	call   801001dd <bwrite>
  brelse(buf);
8010333e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103341:	89 04 24             	mov    %eax,(%esp)
80103344:	e8 ce ce ff ff       	call   80100217 <brelse>
}
80103349:	c9                   	leave  
8010334a:	c3                   	ret    

8010334b <recover_from_log>:

static void
recover_from_log(void)
{
8010334b:	55                   	push   %ebp
8010334c:	89 e5                	mov    %esp,%ebp
8010334e:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103351:	e8 0b ff ff ff       	call   80103261 <read_head>
  install_trans(); // if committed, copy from log to disk
80103356:	e8 58 fe ff ff       	call   801031b3 <install_trans>
  log.lh.n = 0;
8010335b:	c7 05 e4 fd 10 80 00 	movl   $0x0,0x8010fde4
80103362:	00 00 00 
  write_head(); // clear the log
80103365:	e8 66 ff ff ff       	call   801032d0 <write_head>
}
8010336a:	c9                   	leave  
8010336b:	c3                   	ret    

8010336c <begin_trans>:

void
begin_trans(void)
{
8010336c:	55                   	push   %ebp
8010336d:	89 e5                	mov    %esp,%ebp
8010336f:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103372:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
80103379:	e8 85 19 00 00       	call   80104d03 <acquire>
  while (log.busy) {
8010337e:	eb 14                	jmp    80103394 <begin_trans+0x28>
    sleep(&log, &log.lock);
80103380:	c7 44 24 04 a0 fd 10 	movl   $0x8010fda0,0x4(%esp)
80103387:	80 
80103388:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
8010338f:	e8 91 16 00 00       	call   80104a25 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
80103394:	a1 dc fd 10 80       	mov    0x8010fddc,%eax
80103399:	85 c0                	test   %eax,%eax
8010339b:	75 e3                	jne    80103380 <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
8010339d:	c7 05 dc fd 10 80 01 	movl   $0x1,0x8010fddc
801033a4:	00 00 00 
  release(&log.lock);
801033a7:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
801033ae:	e8 b2 19 00 00       	call   80104d65 <release>
}
801033b3:	c9                   	leave  
801033b4:	c3                   	ret    

801033b5 <commit_trans>:

void
commit_trans(void)
{
801033b5:	55                   	push   %ebp
801033b6:	89 e5                	mov    %esp,%ebp
801033b8:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
801033bb:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
801033c0:	85 c0                	test   %eax,%eax
801033c2:	7e 19                	jle    801033dd <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
801033c4:	e8 07 ff ff ff       	call   801032d0 <write_head>
    install_trans(); // Now install writes to home locations
801033c9:	e8 e5 fd ff ff       	call   801031b3 <install_trans>
    log.lh.n = 0; 
801033ce:	c7 05 e4 fd 10 80 00 	movl   $0x0,0x8010fde4
801033d5:	00 00 00 
    write_head();    // Erase the transaction from the log
801033d8:	e8 f3 fe ff ff       	call   801032d0 <write_head>
  }
  
  acquire(&log.lock);
801033dd:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
801033e4:	e8 1a 19 00 00       	call   80104d03 <acquire>
  log.busy = 0;
801033e9:	c7 05 dc fd 10 80 00 	movl   $0x0,0x8010fddc
801033f0:	00 00 00 
  wakeup(&log);
801033f3:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
801033fa:	e8 ff 16 00 00       	call   80104afe <wakeup>
  release(&log.lock);
801033ff:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
80103406:	e8 5a 19 00 00       	call   80104d65 <release>
}
8010340b:	c9                   	leave  
8010340c:	c3                   	ret    

8010340d <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
8010340d:	55                   	push   %ebp
8010340e:	89 e5                	mov    %esp,%ebp
80103410:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103413:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
80103418:	83 f8 09             	cmp    $0x9,%eax
8010341b:	7f 12                	jg     8010342f <log_write+0x22>
8010341d:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
80103422:	8b 15 d8 fd 10 80    	mov    0x8010fdd8,%edx
80103428:	83 ea 01             	sub    $0x1,%edx
8010342b:	39 d0                	cmp    %edx,%eax
8010342d:	7c 0c                	jl     8010343b <log_write+0x2e>
    panic("too big a transaction");
8010342f:	c7 04 24 34 85 10 80 	movl   $0x80108534,(%esp)
80103436:	e8 0b d1 ff ff       	call   80100546 <panic>
  if (!log.busy)
8010343b:	a1 dc fd 10 80       	mov    0x8010fddc,%eax
80103440:	85 c0                	test   %eax,%eax
80103442:	75 0c                	jne    80103450 <log_write+0x43>
    panic("write outside of trans");
80103444:	c7 04 24 4a 85 10 80 	movl   $0x8010854a,(%esp)
8010344b:	e8 f6 d0 ff ff       	call   80100546 <panic>

  for (i = 0; i < log.lh.n; i++) {
80103450:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103457:	eb 1d                	jmp    80103476 <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
80103459:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010345c:	83 c0 10             	add    $0x10,%eax
8010345f:	8b 04 85 a8 fd 10 80 	mov    -0x7fef0258(,%eax,4),%eax
80103466:	89 c2                	mov    %eax,%edx
80103468:	8b 45 08             	mov    0x8(%ebp),%eax
8010346b:	8b 40 08             	mov    0x8(%eax),%eax
8010346e:	39 c2                	cmp    %eax,%edx
80103470:	74 10                	je     80103482 <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
80103472:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103476:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
8010347b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010347e:	7f d9                	jg     80103459 <log_write+0x4c>
80103480:	eb 01                	jmp    80103483 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
80103482:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
80103483:	8b 45 08             	mov    0x8(%ebp),%eax
80103486:	8b 40 08             	mov    0x8(%eax),%eax
80103489:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010348c:	83 c2 10             	add    $0x10,%edx
8010348f:	89 04 95 a8 fd 10 80 	mov    %eax,-0x7fef0258(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
80103496:	8b 15 d4 fd 10 80    	mov    0x8010fdd4,%edx
8010349c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010349f:	01 d0                	add    %edx,%eax
801034a1:	83 c0 01             	add    $0x1,%eax
801034a4:	89 c2                	mov    %eax,%edx
801034a6:	8b 45 08             	mov    0x8(%ebp),%eax
801034a9:	8b 40 04             	mov    0x4(%eax),%eax
801034ac:	89 54 24 04          	mov    %edx,0x4(%esp)
801034b0:	89 04 24             	mov    %eax,(%esp)
801034b3:	e8 ee cc ff ff       	call   801001a6 <bread>
801034b8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
801034bb:	8b 45 08             	mov    0x8(%ebp),%eax
801034be:	8d 50 18             	lea    0x18(%eax),%edx
801034c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034c4:	83 c0 18             	add    $0x18,%eax
801034c7:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801034ce:	00 
801034cf:	89 54 24 04          	mov    %edx,0x4(%esp)
801034d3:	89 04 24             	mov    %eax,(%esp)
801034d6:	e8 56 1b 00 00       	call   80105031 <memmove>
  bwrite(lbuf);
801034db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034de:	89 04 24             	mov    %eax,(%esp)
801034e1:	e8 f7 cc ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
801034e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034e9:	89 04 24             	mov    %eax,(%esp)
801034ec:	e8 26 cd ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
801034f1:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
801034f6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801034f9:	75 0d                	jne    80103508 <log_write+0xfb>
    log.lh.n++;
801034fb:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
80103500:	83 c0 01             	add    $0x1,%eax
80103503:	a3 e4 fd 10 80       	mov    %eax,0x8010fde4
  b->flags |= B_DIRTY; // XXX prevent eviction
80103508:	8b 45 08             	mov    0x8(%ebp),%eax
8010350b:	8b 00                	mov    (%eax),%eax
8010350d:	89 c2                	mov    %eax,%edx
8010350f:	83 ca 04             	or     $0x4,%edx
80103512:	8b 45 08             	mov    0x8(%ebp),%eax
80103515:	89 10                	mov    %edx,(%eax)
}
80103517:	c9                   	leave  
80103518:	c3                   	ret    
80103519:	66 90                	xchg   %ax,%ax
8010351b:	90                   	nop

8010351c <v2p>:
8010351c:	55                   	push   %ebp
8010351d:	89 e5                	mov    %esp,%ebp
8010351f:	8b 45 08             	mov    0x8(%ebp),%eax
80103522:	05 00 00 00 80       	add    $0x80000000,%eax
80103527:	5d                   	pop    %ebp
80103528:	c3                   	ret    

80103529 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103529:	55                   	push   %ebp
8010352a:	89 e5                	mov    %esp,%ebp
8010352c:	8b 45 08             	mov    0x8(%ebp),%eax
8010352f:	05 00 00 00 80       	add    $0x80000000,%eax
80103534:	5d                   	pop    %ebp
80103535:	c3                   	ret    

80103536 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103536:	55                   	push   %ebp
80103537:	89 e5                	mov    %esp,%ebp
80103539:	53                   	push   %ebx
8010353a:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
8010353d:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103540:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80103543:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103546:	89 c3                	mov    %eax,%ebx
80103548:	89 d8                	mov    %ebx,%eax
8010354a:	f0 87 02             	lock xchg %eax,(%edx)
8010354d:	89 c3                	mov    %eax,%ebx
8010354f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103552:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103555:	83 c4 10             	add    $0x10,%esp
80103558:	5b                   	pop    %ebx
80103559:	5d                   	pop    %ebp
8010355a:	c3                   	ret    

8010355b <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
8010355b:	55                   	push   %ebp
8010355c:	89 e5                	mov    %esp,%ebp
8010355e:	83 e4 f0             	and    $0xfffffff0,%esp
80103561:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103564:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
8010356b:	80 
8010356c:	c7 04 24 1c 2c 11 80 	movl   $0x80112c1c,(%esp)
80103573:	e8 a1 f5 ff ff       	call   80102b19 <kinit1>
  kvmalloc();      // kernel page table
80103578:	e8 ff 45 00 00       	call   80107b7c <kvmalloc>
  mpinit();        // collect info about this machine
8010357d:	e8 67 04 00 00       	call   801039e9 <mpinit>
  lapicinit(mpbcpu());
80103582:	e8 2e 02 00 00       	call   801037b5 <mpbcpu>
80103587:	89 04 24             	mov    %eax,(%esp)
8010358a:	e8 ed f8 ff ff       	call   80102e7c <lapicinit>
  seginit();       // set up segments
8010358f:	e8 7d 3f 00 00       	call   80107511 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103594:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010359a:	0f b6 00             	movzbl (%eax),%eax
8010359d:	0f b6 c0             	movzbl %al,%eax
801035a0:	89 44 24 04          	mov    %eax,0x4(%esp)
801035a4:	c7 04 24 61 85 10 80 	movl   $0x80108561,(%esp)
801035ab:	e8 fa cd ff ff       	call   801003aa <cprintf>
  picinit();       // interrupt controller
801035b0:	e8 99 06 00 00       	call   80103c4e <picinit>
  ioapicinit();    // another interrupt controller
801035b5:	e8 4f f4 ff ff       	call   80102a09 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
801035ba:	e8 d9 d4 ff ff       	call   80100a98 <consoleinit>
  uartinit();      // serial port
801035bf:	e8 98 32 00 00       	call   8010685c <uartinit>
  pinit();         // process table
801035c4:	e8 9e 0b 00 00       	call   80104167 <pinit>
  tvinit();        // trap vectors
801035c9:	e8 31 2e 00 00       	call   801063ff <tvinit>
  binit();         // buffer cache
801035ce:	e8 61 ca ff ff       	call   80100034 <binit>
  fileinit();      // file table
801035d3:	e8 4c da ff ff       	call   80101024 <fileinit>
  iinit();         // inode cache
801035d8:	e8 fc e0 ff ff       	call   801016d9 <iinit>
  ideinit();       // disk
801035dd:	e8 8c f0 ff ff       	call   8010266e <ideinit>
  if(!ismp)
801035e2:	a1 24 fe 10 80       	mov    0x8010fe24,%eax
801035e7:	85 c0                	test   %eax,%eax
801035e9:	75 05                	jne    801035f0 <main+0x95>
    timerinit();   // uniprocessor timer
801035eb:	e8 52 2d 00 00       	call   80106342 <timerinit>
  startothers();   // start other processors
801035f0:	e8 87 00 00 00       	call   8010367c <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801035f5:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801035fc:	8e 
801035fd:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103604:	e8 48 f5 ff ff       	call   80102b51 <kinit2>
  userinit();      // first user process
80103609:	e8 74 0c 00 00       	call   80104282 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
8010360e:	e8 22 00 00 00       	call   80103635 <mpmain>

80103613 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103613:	55                   	push   %ebp
80103614:	89 e5                	mov    %esp,%ebp
80103616:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
80103619:	e8 75 45 00 00       	call   80107b93 <switchkvm>
  seginit();
8010361e:	e8 ee 3e 00 00       	call   80107511 <seginit>
  lapicinit(cpunum());
80103623:	e8 b1 f9 ff ff       	call   80102fd9 <cpunum>
80103628:	89 04 24             	mov    %eax,(%esp)
8010362b:	e8 4c f8 ff ff       	call   80102e7c <lapicinit>
  mpmain();
80103630:	e8 00 00 00 00       	call   80103635 <mpmain>

80103635 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103635:	55                   	push   %ebp
80103636:	89 e5                	mov    %esp,%ebp
80103638:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
8010363b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103641:	0f b6 00             	movzbl (%eax),%eax
80103644:	0f b6 c0             	movzbl %al,%eax
80103647:	89 44 24 04          	mov    %eax,0x4(%esp)
8010364b:	c7 04 24 78 85 10 80 	movl   $0x80108578,(%esp)
80103652:	e8 53 cd ff ff       	call   801003aa <cprintf>
  idtinit();       // load idt register
80103657:	e8 17 2f 00 00       	call   80106573 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
8010365c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103662:	05 a8 00 00 00       	add    $0xa8,%eax
80103667:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010366e:	00 
8010366f:	89 04 24             	mov    %eax,(%esp)
80103672:	e8 bf fe ff ff       	call   80103536 <xchg>
  scheduler();     // start running processes
80103677:	e8 00 12 00 00       	call   8010487c <scheduler>

8010367c <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
8010367c:	55                   	push   %ebp
8010367d:	89 e5                	mov    %esp,%ebp
8010367f:	53                   	push   %ebx
80103680:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103683:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
8010368a:	e8 9a fe ff ff       	call   80103529 <p2v>
8010368f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103692:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103697:	89 44 24 08          	mov    %eax,0x8(%esp)
8010369b:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
801036a2:	80 
801036a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036a6:	89 04 24             	mov    %eax,(%esp)
801036a9:	e8 83 19 00 00       	call   80105031 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
801036ae:	c7 45 f4 40 fe 10 80 	movl   $0x8010fe40,-0xc(%ebp)
801036b5:	e9 86 00 00 00       	jmp    80103740 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
801036ba:	e8 1a f9 ff ff       	call   80102fd9 <cpunum>
801036bf:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801036c5:	05 40 fe 10 80       	add    $0x8010fe40,%eax
801036ca:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801036cd:	74 69                	je     80103738 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
801036cf:	e8 73 f5 ff ff       	call   80102c47 <kalloc>
801036d4:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
801036d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036da:	83 e8 04             	sub    $0x4,%eax
801036dd:	8b 55 ec             	mov    -0x14(%ebp),%edx
801036e0:	81 c2 00 10 00 00    	add    $0x1000,%edx
801036e6:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
801036e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036eb:	83 e8 08             	sub    $0x8,%eax
801036ee:	c7 00 13 36 10 80    	movl   $0x80103613,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
801036f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036f7:	8d 58 f4             	lea    -0xc(%eax),%ebx
801036fa:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
80103701:	e8 16 fe ff ff       	call   8010351c <v2p>
80103706:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103708:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010370b:	89 04 24             	mov    %eax,(%esp)
8010370e:	e8 09 fe ff ff       	call   8010351c <v2p>
80103713:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103716:	0f b6 12             	movzbl (%edx),%edx
80103719:	0f b6 d2             	movzbl %dl,%edx
8010371c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103720:	89 14 24             	mov    %edx,(%esp)
80103723:	e8 37 f9 ff ff       	call   8010305f <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103728:	90                   	nop
80103729:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010372c:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103732:	85 c0                	test   %eax,%eax
80103734:	74 f3                	je     80103729 <startothers+0xad>
80103736:	eb 01                	jmp    80103739 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
80103738:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103739:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103740:	a1 20 04 11 80       	mov    0x80110420,%eax
80103745:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010374b:	05 40 fe 10 80       	add    $0x8010fe40,%eax
80103750:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103753:	0f 87 61 ff ff ff    	ja     801036ba <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103759:	83 c4 24             	add    $0x24,%esp
8010375c:	5b                   	pop    %ebx
8010375d:	5d                   	pop    %ebp
8010375e:	c3                   	ret    
8010375f:	90                   	nop

80103760 <p2v>:
80103760:	55                   	push   %ebp
80103761:	89 e5                	mov    %esp,%ebp
80103763:	8b 45 08             	mov    0x8(%ebp),%eax
80103766:	05 00 00 00 80       	add    $0x80000000,%eax
8010376b:	5d                   	pop    %ebp
8010376c:	c3                   	ret    

8010376d <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010376d:	55                   	push   %ebp
8010376e:	89 e5                	mov    %esp,%ebp
80103770:	53                   	push   %ebx
80103771:	83 ec 14             	sub    $0x14,%esp
80103774:	8b 45 08             	mov    0x8(%ebp),%eax
80103777:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010377b:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
8010377f:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103783:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103787:	ec                   	in     (%dx),%al
80103788:	89 c3                	mov    %eax,%ebx
8010378a:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
8010378d:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103791:	83 c4 14             	add    $0x14,%esp
80103794:	5b                   	pop    %ebx
80103795:	5d                   	pop    %ebp
80103796:	c3                   	ret    

80103797 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103797:	55                   	push   %ebp
80103798:	89 e5                	mov    %esp,%ebp
8010379a:	83 ec 08             	sub    $0x8,%esp
8010379d:	8b 55 08             	mov    0x8(%ebp),%edx
801037a0:	8b 45 0c             	mov    0xc(%ebp),%eax
801037a3:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801037a7:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801037aa:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801037ae:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801037b2:	ee                   	out    %al,(%dx)
}
801037b3:	c9                   	leave  
801037b4:	c3                   	ret    

801037b5 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
801037b5:	55                   	push   %ebp
801037b6:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
801037b8:	a1 44 b6 10 80       	mov    0x8010b644,%eax
801037bd:	89 c2                	mov    %eax,%edx
801037bf:	b8 40 fe 10 80       	mov    $0x8010fe40,%eax
801037c4:	89 d1                	mov    %edx,%ecx
801037c6:	29 c1                	sub    %eax,%ecx
801037c8:	89 c8                	mov    %ecx,%eax
801037ca:	c1 f8 02             	sar    $0x2,%eax
801037cd:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
801037d3:	5d                   	pop    %ebp
801037d4:	c3                   	ret    

801037d5 <sum>:

static uchar
sum(uchar *addr, int len)
{
801037d5:	55                   	push   %ebp
801037d6:	89 e5                	mov    %esp,%ebp
801037d8:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
801037db:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
801037e2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801037e9:	eb 15                	jmp    80103800 <sum+0x2b>
    sum += addr[i];
801037eb:	8b 55 fc             	mov    -0x4(%ebp),%edx
801037ee:	8b 45 08             	mov    0x8(%ebp),%eax
801037f1:	01 d0                	add    %edx,%eax
801037f3:	0f b6 00             	movzbl (%eax),%eax
801037f6:	0f b6 c0             	movzbl %al,%eax
801037f9:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
801037fc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103800:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103803:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103806:	7c e3                	jl     801037eb <sum+0x16>
    sum += addr[i];
  return sum;
80103808:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010380b:	c9                   	leave  
8010380c:	c3                   	ret    

8010380d <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
8010380d:	55                   	push   %ebp
8010380e:	89 e5                	mov    %esp,%ebp
80103810:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103813:	8b 45 08             	mov    0x8(%ebp),%eax
80103816:	89 04 24             	mov    %eax,(%esp)
80103819:	e8 42 ff ff ff       	call   80103760 <p2v>
8010381e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103821:	8b 55 0c             	mov    0xc(%ebp),%edx
80103824:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103827:	01 d0                	add    %edx,%eax
80103829:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
8010382c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010382f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103832:	eb 3f                	jmp    80103873 <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103834:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010383b:	00 
8010383c:	c7 44 24 04 8c 85 10 	movl   $0x8010858c,0x4(%esp)
80103843:	80 
80103844:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103847:	89 04 24             	mov    %eax,(%esp)
8010384a:	e8 86 17 00 00       	call   80104fd5 <memcmp>
8010384f:	85 c0                	test   %eax,%eax
80103851:	75 1c                	jne    8010386f <mpsearch1+0x62>
80103853:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010385a:	00 
8010385b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010385e:	89 04 24             	mov    %eax,(%esp)
80103861:	e8 6f ff ff ff       	call   801037d5 <sum>
80103866:	84 c0                	test   %al,%al
80103868:	75 05                	jne    8010386f <mpsearch1+0x62>
      return (struct mp*)p;
8010386a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010386d:	eb 11                	jmp    80103880 <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
8010386f:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103873:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103876:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103879:	72 b9                	jb     80103834 <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
8010387b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103880:	c9                   	leave  
80103881:	c3                   	ret    

80103882 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103882:	55                   	push   %ebp
80103883:	89 e5                	mov    %esp,%ebp
80103885:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103888:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
8010388f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103892:	83 c0 0f             	add    $0xf,%eax
80103895:	0f b6 00             	movzbl (%eax),%eax
80103898:	0f b6 c0             	movzbl %al,%eax
8010389b:	89 c2                	mov    %eax,%edx
8010389d:	c1 e2 08             	shl    $0x8,%edx
801038a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038a3:	83 c0 0e             	add    $0xe,%eax
801038a6:	0f b6 00             	movzbl (%eax),%eax
801038a9:	0f b6 c0             	movzbl %al,%eax
801038ac:	09 d0                	or     %edx,%eax
801038ae:	c1 e0 04             	shl    $0x4,%eax
801038b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801038b4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801038b8:	74 21                	je     801038db <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
801038ba:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801038c1:	00 
801038c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038c5:	89 04 24             	mov    %eax,(%esp)
801038c8:	e8 40 ff ff ff       	call   8010380d <mpsearch1>
801038cd:	89 45 ec             	mov    %eax,-0x14(%ebp)
801038d0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801038d4:	74 50                	je     80103926 <mpsearch+0xa4>
      return mp;
801038d6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801038d9:	eb 5f                	jmp    8010393a <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
801038db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038de:	83 c0 14             	add    $0x14,%eax
801038e1:	0f b6 00             	movzbl (%eax),%eax
801038e4:	0f b6 c0             	movzbl %al,%eax
801038e7:	89 c2                	mov    %eax,%edx
801038e9:	c1 e2 08             	shl    $0x8,%edx
801038ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038ef:	83 c0 13             	add    $0x13,%eax
801038f2:	0f b6 00             	movzbl (%eax),%eax
801038f5:	0f b6 c0             	movzbl %al,%eax
801038f8:	09 d0                	or     %edx,%eax
801038fa:	c1 e0 0a             	shl    $0xa,%eax
801038fd:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103900:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103903:	2d 00 04 00 00       	sub    $0x400,%eax
80103908:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010390f:	00 
80103910:	89 04 24             	mov    %eax,(%esp)
80103913:	e8 f5 fe ff ff       	call   8010380d <mpsearch1>
80103918:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010391b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010391f:	74 05                	je     80103926 <mpsearch+0xa4>
      return mp;
80103921:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103924:	eb 14                	jmp    8010393a <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103926:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010392d:	00 
8010392e:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103935:	e8 d3 fe ff ff       	call   8010380d <mpsearch1>
}
8010393a:	c9                   	leave  
8010393b:	c3                   	ret    

8010393c <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
8010393c:	55                   	push   %ebp
8010393d:	89 e5                	mov    %esp,%ebp
8010393f:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103942:	e8 3b ff ff ff       	call   80103882 <mpsearch>
80103947:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010394a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010394e:	74 0a                	je     8010395a <mpconfig+0x1e>
80103950:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103953:	8b 40 04             	mov    0x4(%eax),%eax
80103956:	85 c0                	test   %eax,%eax
80103958:	75 0a                	jne    80103964 <mpconfig+0x28>
    return 0;
8010395a:	b8 00 00 00 00       	mov    $0x0,%eax
8010395f:	e9 83 00 00 00       	jmp    801039e7 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103964:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103967:	8b 40 04             	mov    0x4(%eax),%eax
8010396a:	89 04 24             	mov    %eax,(%esp)
8010396d:	e8 ee fd ff ff       	call   80103760 <p2v>
80103972:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103975:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010397c:	00 
8010397d:	c7 44 24 04 91 85 10 	movl   $0x80108591,0x4(%esp)
80103984:	80 
80103985:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103988:	89 04 24             	mov    %eax,(%esp)
8010398b:	e8 45 16 00 00       	call   80104fd5 <memcmp>
80103990:	85 c0                	test   %eax,%eax
80103992:	74 07                	je     8010399b <mpconfig+0x5f>
    return 0;
80103994:	b8 00 00 00 00       	mov    $0x0,%eax
80103999:	eb 4c                	jmp    801039e7 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
8010399b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010399e:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801039a2:	3c 01                	cmp    $0x1,%al
801039a4:	74 12                	je     801039b8 <mpconfig+0x7c>
801039a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039a9:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801039ad:	3c 04                	cmp    $0x4,%al
801039af:	74 07                	je     801039b8 <mpconfig+0x7c>
    return 0;
801039b1:	b8 00 00 00 00       	mov    $0x0,%eax
801039b6:	eb 2f                	jmp    801039e7 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
801039b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039bb:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801039bf:	0f b7 c0             	movzwl %ax,%eax
801039c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801039c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039c9:	89 04 24             	mov    %eax,(%esp)
801039cc:	e8 04 fe ff ff       	call   801037d5 <sum>
801039d1:	84 c0                	test   %al,%al
801039d3:	74 07                	je     801039dc <mpconfig+0xa0>
    return 0;
801039d5:	b8 00 00 00 00       	mov    $0x0,%eax
801039da:	eb 0b                	jmp    801039e7 <mpconfig+0xab>
  *pmp = mp;
801039dc:	8b 45 08             	mov    0x8(%ebp),%eax
801039df:	8b 55 f4             	mov    -0xc(%ebp),%edx
801039e2:	89 10                	mov    %edx,(%eax)
  return conf;
801039e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801039e7:	c9                   	leave  
801039e8:	c3                   	ret    

801039e9 <mpinit>:

void
mpinit(void)
{
801039e9:	55                   	push   %ebp
801039ea:	89 e5                	mov    %esp,%ebp
801039ec:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
801039ef:	c7 05 44 b6 10 80 40 	movl   $0x8010fe40,0x8010b644
801039f6:	fe 10 80 
  if((conf = mpconfig(&mp)) == 0)
801039f9:	8d 45 e0             	lea    -0x20(%ebp),%eax
801039fc:	89 04 24             	mov    %eax,(%esp)
801039ff:	e8 38 ff ff ff       	call   8010393c <mpconfig>
80103a04:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103a07:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103a0b:	0f 84 9c 01 00 00    	je     80103bad <mpinit+0x1c4>
    return;
  ismp = 1;
80103a11:	c7 05 24 fe 10 80 01 	movl   $0x1,0x8010fe24
80103a18:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103a1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a1e:	8b 40 24             	mov    0x24(%eax),%eax
80103a21:	a3 9c fd 10 80       	mov    %eax,0x8010fd9c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103a26:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a29:	83 c0 2c             	add    $0x2c,%eax
80103a2c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103a2f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a32:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103a36:	0f b7 d0             	movzwl %ax,%edx
80103a39:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a3c:	01 d0                	add    %edx,%eax
80103a3e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103a41:	e9 f4 00 00 00       	jmp    80103b3a <mpinit+0x151>
    switch(*p){
80103a46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a49:	0f b6 00             	movzbl (%eax),%eax
80103a4c:	0f b6 c0             	movzbl %al,%eax
80103a4f:	83 f8 04             	cmp    $0x4,%eax
80103a52:	0f 87 bf 00 00 00    	ja     80103b17 <mpinit+0x12e>
80103a58:	8b 04 85 d4 85 10 80 	mov    -0x7fef7a2c(,%eax,4),%eax
80103a5f:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103a61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a64:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103a67:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103a6a:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103a6e:	0f b6 d0             	movzbl %al,%edx
80103a71:	a1 20 04 11 80       	mov    0x80110420,%eax
80103a76:	39 c2                	cmp    %eax,%edx
80103a78:	74 2d                	je     80103aa7 <mpinit+0xbe>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103a7a:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103a7d:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103a81:	0f b6 d0             	movzbl %al,%edx
80103a84:	a1 20 04 11 80       	mov    0x80110420,%eax
80103a89:	89 54 24 08          	mov    %edx,0x8(%esp)
80103a8d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a91:	c7 04 24 96 85 10 80 	movl   $0x80108596,(%esp)
80103a98:	e8 0d c9 ff ff       	call   801003aa <cprintf>
        ismp = 0;
80103a9d:	c7 05 24 fe 10 80 00 	movl   $0x0,0x8010fe24
80103aa4:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103aa7:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103aaa:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103aae:	0f b6 c0             	movzbl %al,%eax
80103ab1:	83 e0 02             	and    $0x2,%eax
80103ab4:	85 c0                	test   %eax,%eax
80103ab6:	74 15                	je     80103acd <mpinit+0xe4>
        bcpu = &cpus[ncpu];
80103ab8:	a1 20 04 11 80       	mov    0x80110420,%eax
80103abd:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103ac3:	05 40 fe 10 80       	add    $0x8010fe40,%eax
80103ac8:	a3 44 b6 10 80       	mov    %eax,0x8010b644
      cpus[ncpu].id = ncpu;
80103acd:	8b 15 20 04 11 80    	mov    0x80110420,%edx
80103ad3:	a1 20 04 11 80       	mov    0x80110420,%eax
80103ad8:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103ade:	81 c2 40 fe 10 80    	add    $0x8010fe40,%edx
80103ae4:	88 02                	mov    %al,(%edx)
      ncpu++;
80103ae6:	a1 20 04 11 80       	mov    0x80110420,%eax
80103aeb:	83 c0 01             	add    $0x1,%eax
80103aee:	a3 20 04 11 80       	mov    %eax,0x80110420
      p += sizeof(struct mpproc);
80103af3:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103af7:	eb 41                	jmp    80103b3a <mpinit+0x151>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103af9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103afc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103aff:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103b02:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103b06:	a2 20 fe 10 80       	mov    %al,0x8010fe20
      p += sizeof(struct mpioapic);
80103b0b:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103b0f:	eb 29                	jmp    80103b3a <mpinit+0x151>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103b11:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103b15:	eb 23                	jmp    80103b3a <mpinit+0x151>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103b17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b1a:	0f b6 00             	movzbl (%eax),%eax
80103b1d:	0f b6 c0             	movzbl %al,%eax
80103b20:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b24:	c7 04 24 b4 85 10 80 	movl   $0x801085b4,(%esp)
80103b2b:	e8 7a c8 ff ff       	call   801003aa <cprintf>
      ismp = 0;
80103b30:	c7 05 24 fe 10 80 00 	movl   $0x0,0x8010fe24
80103b37:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103b3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b3d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103b40:	0f 82 00 ff ff ff    	jb     80103a46 <mpinit+0x5d>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103b46:	a1 24 fe 10 80       	mov    0x8010fe24,%eax
80103b4b:	85 c0                	test   %eax,%eax
80103b4d:	75 1d                	jne    80103b6c <mpinit+0x183>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103b4f:	c7 05 20 04 11 80 01 	movl   $0x1,0x80110420
80103b56:	00 00 00 
    lapic = 0;
80103b59:	c7 05 9c fd 10 80 00 	movl   $0x0,0x8010fd9c
80103b60:	00 00 00 
    ioapicid = 0;
80103b63:	c6 05 20 fe 10 80 00 	movb   $0x0,0x8010fe20
80103b6a:	eb 41                	jmp    80103bad <mpinit+0x1c4>
    return;
  }

  if(mp->imcrp){
80103b6c:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103b6f:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103b73:	84 c0                	test   %al,%al
80103b75:	74 36                	je     80103bad <mpinit+0x1c4>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103b77:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103b7e:	00 
80103b7f:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103b86:	e8 0c fc ff ff       	call   80103797 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103b8b:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103b92:	e8 d6 fb ff ff       	call   8010376d <inb>
80103b97:	83 c8 01             	or     $0x1,%eax
80103b9a:	0f b6 c0             	movzbl %al,%eax
80103b9d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ba1:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103ba8:	e8 ea fb ff ff       	call   80103797 <outb>
  }
}
80103bad:	c9                   	leave  
80103bae:	c3                   	ret    
80103baf:	90                   	nop

80103bb0 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103bb0:	55                   	push   %ebp
80103bb1:	89 e5                	mov    %esp,%ebp
80103bb3:	83 ec 08             	sub    $0x8,%esp
80103bb6:	8b 55 08             	mov    0x8(%ebp),%edx
80103bb9:	8b 45 0c             	mov    0xc(%ebp),%eax
80103bbc:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103bc0:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103bc3:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103bc7:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103bcb:	ee                   	out    %al,(%dx)
}
80103bcc:	c9                   	leave  
80103bcd:	c3                   	ret    

80103bce <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103bce:	55                   	push   %ebp
80103bcf:	89 e5                	mov    %esp,%ebp
80103bd1:	83 ec 0c             	sub    $0xc,%esp
80103bd4:	8b 45 08             	mov    0x8(%ebp),%eax
80103bd7:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103bdb:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103bdf:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80103be5:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103be9:	0f b6 c0             	movzbl %al,%eax
80103bec:	89 44 24 04          	mov    %eax,0x4(%esp)
80103bf0:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103bf7:	e8 b4 ff ff ff       	call   80103bb0 <outb>
  outb(IO_PIC2+1, mask >> 8);
80103bfc:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103c00:	66 c1 e8 08          	shr    $0x8,%ax
80103c04:	0f b6 c0             	movzbl %al,%eax
80103c07:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c0b:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103c12:	e8 99 ff ff ff       	call   80103bb0 <outb>
}
80103c17:	c9                   	leave  
80103c18:	c3                   	ret    

80103c19 <picenable>:

void
picenable(int irq)
{
80103c19:	55                   	push   %ebp
80103c1a:	89 e5                	mov    %esp,%ebp
80103c1c:	53                   	push   %ebx
80103c1d:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103c20:	8b 45 08             	mov    0x8(%ebp),%eax
80103c23:	ba 01 00 00 00       	mov    $0x1,%edx
80103c28:	89 d3                	mov    %edx,%ebx
80103c2a:	89 c1                	mov    %eax,%ecx
80103c2c:	d3 e3                	shl    %cl,%ebx
80103c2e:	89 d8                	mov    %ebx,%eax
80103c30:	89 c2                	mov    %eax,%edx
80103c32:	f7 d2                	not    %edx
80103c34:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103c3b:	21 d0                	and    %edx,%eax
80103c3d:	0f b7 c0             	movzwl %ax,%eax
80103c40:	89 04 24             	mov    %eax,(%esp)
80103c43:	e8 86 ff ff ff       	call   80103bce <picsetmask>
}
80103c48:	83 c4 04             	add    $0x4,%esp
80103c4b:	5b                   	pop    %ebx
80103c4c:	5d                   	pop    %ebp
80103c4d:	c3                   	ret    

80103c4e <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103c4e:	55                   	push   %ebp
80103c4f:	89 e5                	mov    %esp,%ebp
80103c51:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103c54:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103c5b:	00 
80103c5c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103c63:	e8 48 ff ff ff       	call   80103bb0 <outb>
  outb(IO_PIC2+1, 0xFF);
80103c68:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103c6f:	00 
80103c70:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103c77:	e8 34 ff ff ff       	call   80103bb0 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103c7c:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103c83:	00 
80103c84:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103c8b:	e8 20 ff ff ff       	call   80103bb0 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103c90:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103c97:	00 
80103c98:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103c9f:	e8 0c ff ff ff       	call   80103bb0 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103ca4:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103cab:	00 
80103cac:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103cb3:	e8 f8 fe ff ff       	call   80103bb0 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103cb8:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103cbf:	00 
80103cc0:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103cc7:	e8 e4 fe ff ff       	call   80103bb0 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103ccc:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103cd3:	00 
80103cd4:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103cdb:	e8 d0 fe ff ff       	call   80103bb0 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103ce0:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103ce7:	00 
80103ce8:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103cef:	e8 bc fe ff ff       	call   80103bb0 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103cf4:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103cfb:	00 
80103cfc:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103d03:	e8 a8 fe ff ff       	call   80103bb0 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103d08:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103d0f:	00 
80103d10:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103d17:	e8 94 fe ff ff       	call   80103bb0 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103d1c:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103d23:	00 
80103d24:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103d2b:	e8 80 fe ff ff       	call   80103bb0 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80103d30:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103d37:	00 
80103d38:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103d3f:	e8 6c fe ff ff       	call   80103bb0 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80103d44:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103d4b:	00 
80103d4c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103d53:	e8 58 fe ff ff       	call   80103bb0 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80103d58:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103d5f:	00 
80103d60:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103d67:	e8 44 fe ff ff       	call   80103bb0 <outb>

  if(irqmask != 0xFFFF)
80103d6c:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103d73:	66 83 f8 ff          	cmp    $0xffff,%ax
80103d77:	74 12                	je     80103d8b <picinit+0x13d>
    picsetmask(irqmask);
80103d79:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103d80:	0f b7 c0             	movzwl %ax,%eax
80103d83:	89 04 24             	mov    %eax,(%esp)
80103d86:	e8 43 fe ff ff       	call   80103bce <picsetmask>
}
80103d8b:	c9                   	leave  
80103d8c:	c3                   	ret    
80103d8d:	66 90                	xchg   %ax,%ax
80103d8f:	90                   	nop

80103d90 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103d90:	55                   	push   %ebp
80103d91:	89 e5                	mov    %esp,%ebp
80103d93:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80103d96:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103d9d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103da0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103da6:	8b 45 0c             	mov    0xc(%ebp),%eax
80103da9:	8b 10                	mov    (%eax),%edx
80103dab:	8b 45 08             	mov    0x8(%ebp),%eax
80103dae:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103db0:	e8 8b d2 ff ff       	call   80101040 <filealloc>
80103db5:	8b 55 08             	mov    0x8(%ebp),%edx
80103db8:	89 02                	mov    %eax,(%edx)
80103dba:	8b 45 08             	mov    0x8(%ebp),%eax
80103dbd:	8b 00                	mov    (%eax),%eax
80103dbf:	85 c0                	test   %eax,%eax
80103dc1:	0f 84 c8 00 00 00    	je     80103e8f <pipealloc+0xff>
80103dc7:	e8 74 d2 ff ff       	call   80101040 <filealloc>
80103dcc:	8b 55 0c             	mov    0xc(%ebp),%edx
80103dcf:	89 02                	mov    %eax,(%edx)
80103dd1:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dd4:	8b 00                	mov    (%eax),%eax
80103dd6:	85 c0                	test   %eax,%eax
80103dd8:	0f 84 b1 00 00 00    	je     80103e8f <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103dde:	e8 64 ee ff ff       	call   80102c47 <kalloc>
80103de3:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103de6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103dea:	0f 84 9e 00 00 00    	je     80103e8e <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80103df0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103df3:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103dfa:	00 00 00 
  p->writeopen = 1;
80103dfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e00:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103e07:	00 00 00 
  p->nwrite = 0;
80103e0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e0d:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103e14:	00 00 00 
  p->nread = 0;
80103e17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e1a:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103e21:	00 00 00 
  initlock(&p->lock, "pipe");
80103e24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e27:	c7 44 24 04 e8 85 10 	movl   $0x801085e8,0x4(%esp)
80103e2e:	80 
80103e2f:	89 04 24             	mov    %eax,(%esp)
80103e32:	e8 ab 0e 00 00       	call   80104ce2 <initlock>
  (*f0)->type = FD_PIPE;
80103e37:	8b 45 08             	mov    0x8(%ebp),%eax
80103e3a:	8b 00                	mov    (%eax),%eax
80103e3c:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103e42:	8b 45 08             	mov    0x8(%ebp),%eax
80103e45:	8b 00                	mov    (%eax),%eax
80103e47:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103e4b:	8b 45 08             	mov    0x8(%ebp),%eax
80103e4e:	8b 00                	mov    (%eax),%eax
80103e50:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103e54:	8b 45 08             	mov    0x8(%ebp),%eax
80103e57:	8b 00                	mov    (%eax),%eax
80103e59:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103e5c:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103e5f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e62:	8b 00                	mov    (%eax),%eax
80103e64:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103e6a:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e6d:	8b 00                	mov    (%eax),%eax
80103e6f:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103e73:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e76:	8b 00                	mov    (%eax),%eax
80103e78:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103e7c:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e7f:	8b 00                	mov    (%eax),%eax
80103e81:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103e84:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80103e87:	b8 00 00 00 00       	mov    $0x0,%eax
80103e8c:	eb 43                	jmp    80103ed1 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80103e8e:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80103e8f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103e93:	74 0b                	je     80103ea0 <pipealloc+0x110>
    kfree((char*)p);
80103e95:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e98:	89 04 24             	mov    %eax,(%esp)
80103e9b:	e8 0e ed ff ff       	call   80102bae <kfree>
  if(*f0)
80103ea0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ea3:	8b 00                	mov    (%eax),%eax
80103ea5:	85 c0                	test   %eax,%eax
80103ea7:	74 0d                	je     80103eb6 <pipealloc+0x126>
    fileclose(*f0);
80103ea9:	8b 45 08             	mov    0x8(%ebp),%eax
80103eac:	8b 00                	mov    (%eax),%eax
80103eae:	89 04 24             	mov    %eax,(%esp)
80103eb1:	e8 32 d2 ff ff       	call   801010e8 <fileclose>
  if(*f1)
80103eb6:	8b 45 0c             	mov    0xc(%ebp),%eax
80103eb9:	8b 00                	mov    (%eax),%eax
80103ebb:	85 c0                	test   %eax,%eax
80103ebd:	74 0d                	je     80103ecc <pipealloc+0x13c>
    fileclose(*f1);
80103ebf:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ec2:	8b 00                	mov    (%eax),%eax
80103ec4:	89 04 24             	mov    %eax,(%esp)
80103ec7:	e8 1c d2 ff ff       	call   801010e8 <fileclose>
  return -1;
80103ecc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103ed1:	c9                   	leave  
80103ed2:	c3                   	ret    

80103ed3 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103ed3:	55                   	push   %ebp
80103ed4:	89 e5                	mov    %esp,%ebp
80103ed6:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80103ed9:	8b 45 08             	mov    0x8(%ebp),%eax
80103edc:	89 04 24             	mov    %eax,(%esp)
80103edf:	e8 1f 0e 00 00       	call   80104d03 <acquire>
  if(writable){
80103ee4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103ee8:	74 1f                	je     80103f09 <pipeclose+0x36>
    p->writeopen = 0;
80103eea:	8b 45 08             	mov    0x8(%ebp),%eax
80103eed:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80103ef4:	00 00 00 
    wakeup(&p->nread);
80103ef7:	8b 45 08             	mov    0x8(%ebp),%eax
80103efa:	05 34 02 00 00       	add    $0x234,%eax
80103eff:	89 04 24             	mov    %eax,(%esp)
80103f02:	e8 f7 0b 00 00       	call   80104afe <wakeup>
80103f07:	eb 1d                	jmp    80103f26 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80103f09:	8b 45 08             	mov    0x8(%ebp),%eax
80103f0c:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80103f13:	00 00 00 
    wakeup(&p->nwrite);
80103f16:	8b 45 08             	mov    0x8(%ebp),%eax
80103f19:	05 38 02 00 00       	add    $0x238,%eax
80103f1e:	89 04 24             	mov    %eax,(%esp)
80103f21:	e8 d8 0b 00 00       	call   80104afe <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103f26:	8b 45 08             	mov    0x8(%ebp),%eax
80103f29:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103f2f:	85 c0                	test   %eax,%eax
80103f31:	75 25                	jne    80103f58 <pipeclose+0x85>
80103f33:	8b 45 08             	mov    0x8(%ebp),%eax
80103f36:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103f3c:	85 c0                	test   %eax,%eax
80103f3e:	75 18                	jne    80103f58 <pipeclose+0x85>
    release(&p->lock);
80103f40:	8b 45 08             	mov    0x8(%ebp),%eax
80103f43:	89 04 24             	mov    %eax,(%esp)
80103f46:	e8 1a 0e 00 00       	call   80104d65 <release>
    kfree((char*)p);
80103f4b:	8b 45 08             	mov    0x8(%ebp),%eax
80103f4e:	89 04 24             	mov    %eax,(%esp)
80103f51:	e8 58 ec ff ff       	call   80102bae <kfree>
80103f56:	eb 0b                	jmp    80103f63 <pipeclose+0x90>
  } else
    release(&p->lock);
80103f58:	8b 45 08             	mov    0x8(%ebp),%eax
80103f5b:	89 04 24             	mov    %eax,(%esp)
80103f5e:	e8 02 0e 00 00       	call   80104d65 <release>
}
80103f63:	c9                   	leave  
80103f64:	c3                   	ret    

80103f65 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80103f65:	55                   	push   %ebp
80103f66:	89 e5                	mov    %esp,%ebp
80103f68:	53                   	push   %ebx
80103f69:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80103f6c:	8b 45 08             	mov    0x8(%ebp),%eax
80103f6f:	89 04 24             	mov    %eax,(%esp)
80103f72:	e8 8c 0d 00 00       	call   80104d03 <acquire>
  for(i = 0; i < n; i++){
80103f77:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103f7e:	e9 a8 00 00 00       	jmp    8010402b <pipewrite+0xc6>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
80103f83:	8b 45 08             	mov    0x8(%ebp),%eax
80103f86:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103f8c:	85 c0                	test   %eax,%eax
80103f8e:	74 0d                	je     80103f9d <pipewrite+0x38>
80103f90:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103f96:	8b 40 24             	mov    0x24(%eax),%eax
80103f99:	85 c0                	test   %eax,%eax
80103f9b:	74 15                	je     80103fb2 <pipewrite+0x4d>
        release(&p->lock);
80103f9d:	8b 45 08             	mov    0x8(%ebp),%eax
80103fa0:	89 04 24             	mov    %eax,(%esp)
80103fa3:	e8 bd 0d 00 00       	call   80104d65 <release>
        return -1;
80103fa8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fad:	e9 9f 00 00 00       	jmp    80104051 <pipewrite+0xec>
      }
      wakeup(&p->nread);
80103fb2:	8b 45 08             	mov    0x8(%ebp),%eax
80103fb5:	05 34 02 00 00       	add    $0x234,%eax
80103fba:	89 04 24             	mov    %eax,(%esp)
80103fbd:	e8 3c 0b 00 00       	call   80104afe <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103fc2:	8b 45 08             	mov    0x8(%ebp),%eax
80103fc5:	8b 55 08             	mov    0x8(%ebp),%edx
80103fc8:	81 c2 38 02 00 00    	add    $0x238,%edx
80103fce:	89 44 24 04          	mov    %eax,0x4(%esp)
80103fd2:	89 14 24             	mov    %edx,(%esp)
80103fd5:	e8 4b 0a 00 00       	call   80104a25 <sleep>
80103fda:	eb 01                	jmp    80103fdd <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103fdc:	90                   	nop
80103fdd:	8b 45 08             	mov    0x8(%ebp),%eax
80103fe0:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80103fe6:	8b 45 08             	mov    0x8(%ebp),%eax
80103fe9:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80103fef:	05 00 02 00 00       	add    $0x200,%eax
80103ff4:	39 c2                	cmp    %eax,%edx
80103ff6:	74 8b                	je     80103f83 <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103ff8:	8b 45 08             	mov    0x8(%ebp),%eax
80103ffb:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104001:	89 c3                	mov    %eax,%ebx
80104003:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80104009:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010400c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010400f:	01 ca                	add    %ecx,%edx
80104011:	0f b6 0a             	movzbl (%edx),%ecx
80104014:	8b 55 08             	mov    0x8(%ebp),%edx
80104017:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
8010401b:	8d 50 01             	lea    0x1(%eax),%edx
8010401e:	8b 45 08             	mov    0x8(%ebp),%eax
80104021:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104027:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010402b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010402e:	3b 45 10             	cmp    0x10(%ebp),%eax
80104031:	7c a9                	jl     80103fdc <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104033:	8b 45 08             	mov    0x8(%ebp),%eax
80104036:	05 34 02 00 00       	add    $0x234,%eax
8010403b:	89 04 24             	mov    %eax,(%esp)
8010403e:	e8 bb 0a 00 00       	call   80104afe <wakeup>
  release(&p->lock);
80104043:	8b 45 08             	mov    0x8(%ebp),%eax
80104046:	89 04 24             	mov    %eax,(%esp)
80104049:	e8 17 0d 00 00       	call   80104d65 <release>
  return n;
8010404e:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104051:	83 c4 24             	add    $0x24,%esp
80104054:	5b                   	pop    %ebx
80104055:	5d                   	pop    %ebp
80104056:	c3                   	ret    

80104057 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104057:	55                   	push   %ebp
80104058:	89 e5                	mov    %esp,%ebp
8010405a:	53                   	push   %ebx
8010405b:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
8010405e:	8b 45 08             	mov    0x8(%ebp),%eax
80104061:	89 04 24             	mov    %eax,(%esp)
80104064:	e8 9a 0c 00 00       	call   80104d03 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104069:	eb 3a                	jmp    801040a5 <piperead+0x4e>
    if(proc->killed){
8010406b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104071:	8b 40 24             	mov    0x24(%eax),%eax
80104074:	85 c0                	test   %eax,%eax
80104076:	74 15                	je     8010408d <piperead+0x36>
      release(&p->lock);
80104078:	8b 45 08             	mov    0x8(%ebp),%eax
8010407b:	89 04 24             	mov    %eax,(%esp)
8010407e:	e8 e2 0c 00 00       	call   80104d65 <release>
      return -1;
80104083:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104088:	e9 b7 00 00 00       	jmp    80104144 <piperead+0xed>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010408d:	8b 45 08             	mov    0x8(%ebp),%eax
80104090:	8b 55 08             	mov    0x8(%ebp),%edx
80104093:	81 c2 34 02 00 00    	add    $0x234,%edx
80104099:	89 44 24 04          	mov    %eax,0x4(%esp)
8010409d:	89 14 24             	mov    %edx,(%esp)
801040a0:	e8 80 09 00 00       	call   80104a25 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801040a5:	8b 45 08             	mov    0x8(%ebp),%eax
801040a8:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801040ae:	8b 45 08             	mov    0x8(%ebp),%eax
801040b1:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801040b7:	39 c2                	cmp    %eax,%edx
801040b9:	75 0d                	jne    801040c8 <piperead+0x71>
801040bb:	8b 45 08             	mov    0x8(%ebp),%eax
801040be:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801040c4:	85 c0                	test   %eax,%eax
801040c6:	75 a3                	jne    8010406b <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801040c8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801040cf:	eb 4a                	jmp    8010411b <piperead+0xc4>
    if(p->nread == p->nwrite)
801040d1:	8b 45 08             	mov    0x8(%ebp),%eax
801040d4:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801040da:	8b 45 08             	mov    0x8(%ebp),%eax
801040dd:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801040e3:	39 c2                	cmp    %eax,%edx
801040e5:	74 3e                	je     80104125 <piperead+0xce>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
801040e7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801040ea:	8b 45 0c             	mov    0xc(%ebp),%eax
801040ed:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
801040f0:	8b 45 08             	mov    0x8(%ebp),%eax
801040f3:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801040f9:	89 c3                	mov    %eax,%ebx
801040fb:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80104101:	8b 55 08             	mov    0x8(%ebp),%edx
80104104:	0f b6 54 1a 34       	movzbl 0x34(%edx,%ebx,1),%edx
80104109:	88 11                	mov    %dl,(%ecx)
8010410b:	8d 50 01             	lea    0x1(%eax),%edx
8010410e:	8b 45 08             	mov    0x8(%ebp),%eax
80104111:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104117:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010411b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010411e:	3b 45 10             	cmp    0x10(%ebp),%eax
80104121:	7c ae                	jl     801040d1 <piperead+0x7a>
80104123:	eb 01                	jmp    80104126 <piperead+0xcf>
    if(p->nread == p->nwrite)
      break;
80104125:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104126:	8b 45 08             	mov    0x8(%ebp),%eax
80104129:	05 38 02 00 00       	add    $0x238,%eax
8010412e:	89 04 24             	mov    %eax,(%esp)
80104131:	e8 c8 09 00 00       	call   80104afe <wakeup>
  release(&p->lock);
80104136:	8b 45 08             	mov    0x8(%ebp),%eax
80104139:	89 04 24             	mov    %eax,(%esp)
8010413c:	e8 24 0c 00 00       	call   80104d65 <release>
  return i;
80104141:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104144:	83 c4 24             	add    $0x24,%esp
80104147:	5b                   	pop    %ebx
80104148:	5d                   	pop    %ebp
80104149:	c3                   	ret    
8010414a:	66 90                	xchg   %ax,%ax

8010414c <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
8010414c:	55                   	push   %ebp
8010414d:	89 e5                	mov    %esp,%ebp
8010414f:	53                   	push   %ebx
80104150:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104153:	9c                   	pushf  
80104154:	5b                   	pop    %ebx
80104155:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104158:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010415b:	83 c4 10             	add    $0x10,%esp
8010415e:	5b                   	pop    %ebx
8010415f:	5d                   	pop    %ebp
80104160:	c3                   	ret    

80104161 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104161:	55                   	push   %ebp
80104162:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104164:	fb                   	sti    
}
80104165:	5d                   	pop    %ebp
80104166:	c3                   	ret    

80104167 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104167:	55                   	push   %ebp
80104168:	89 e5                	mov    %esp,%ebp
8010416a:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
8010416d:	c7 44 24 04 ed 85 10 	movl   $0x801085ed,0x4(%esp)
80104174:	80 
80104175:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
8010417c:	e8 61 0b 00 00       	call   80104ce2 <initlock>
}
80104181:	c9                   	leave  
80104182:	c3                   	ret    

80104183 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104183:	55                   	push   %ebp
80104184:	89 e5                	mov    %esp,%ebp
80104186:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104189:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104190:	e8 6e 0b 00 00       	call   80104d03 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104195:	c7 45 f4 74 04 11 80 	movl   $0x80110474,-0xc(%ebp)
8010419c:	eb 0e                	jmp    801041ac <allocproc+0x29>
    if(p->state == UNUSED)
8010419e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041a1:	8b 40 0c             	mov    0xc(%eax),%eax
801041a4:	85 c0                	test   %eax,%eax
801041a6:	74 23                	je     801041cb <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801041a8:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801041ac:	81 7d f4 74 23 11 80 	cmpl   $0x80112374,-0xc(%ebp)
801041b3:	72 e9                	jb     8010419e <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
801041b5:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801041bc:	e8 a4 0b 00 00       	call   80104d65 <release>
  return 0;
801041c1:	b8 00 00 00 00       	mov    $0x0,%eax
801041c6:	e9 b5 00 00 00       	jmp    80104280 <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
801041cb:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
801041cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041cf:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
801041d6:	a1 04 b0 10 80       	mov    0x8010b004,%eax
801041db:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041de:	89 42 10             	mov    %eax,0x10(%edx)
801041e1:	83 c0 01             	add    $0x1,%eax
801041e4:	a3 04 b0 10 80       	mov    %eax,0x8010b004
  release(&ptable.lock);
801041e9:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801041f0:	e8 70 0b 00 00       	call   80104d65 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801041f5:	e8 4d ea ff ff       	call   80102c47 <kalloc>
801041fa:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041fd:	89 42 08             	mov    %eax,0x8(%edx)
80104200:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104203:	8b 40 08             	mov    0x8(%eax),%eax
80104206:	85 c0                	test   %eax,%eax
80104208:	75 11                	jne    8010421b <allocproc+0x98>
    p->state = UNUSED;
8010420a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010420d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104214:	b8 00 00 00 00       	mov    $0x0,%eax
80104219:	eb 65                	jmp    80104280 <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
8010421b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010421e:	8b 40 08             	mov    0x8(%eax),%eax
80104221:	05 00 10 00 00       	add    $0x1000,%eax
80104226:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104229:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
8010422d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104230:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104233:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104236:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
8010423a:	ba b4 63 10 80       	mov    $0x801063b4,%edx
8010423f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104242:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104244:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104248:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010424b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010424e:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104251:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104254:	8b 40 1c             	mov    0x1c(%eax),%eax
80104257:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
8010425e:	00 
8010425f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104266:	00 
80104267:	89 04 24             	mov    %eax,(%esp)
8010426a:	e8 ef 0c 00 00       	call   80104f5e <memset>
  p->context->eip = (uint)forkret;
8010426f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104272:	8b 40 1c             	mov    0x1c(%eax),%eax
80104275:	ba f9 49 10 80       	mov    $0x801049f9,%edx
8010427a:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
8010427d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104280:	c9                   	leave  
80104281:	c3                   	ret    

80104282 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104282:	55                   	push   %ebp
80104283:	89 e5                	mov    %esp,%ebp
80104285:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104288:	e8 f6 fe ff ff       	call   80104183 <allocproc>
8010428d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104290:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104293:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm(kalloc)) == 0)
80104298:	c7 04 24 47 2c 10 80 	movl   $0x80102c47,(%esp)
8010429f:	e8 1b 38 00 00       	call   80107abf <setupkvm>
801042a4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042a7:	89 42 04             	mov    %eax,0x4(%edx)
801042aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042ad:	8b 40 04             	mov    0x4(%eax),%eax
801042b0:	85 c0                	test   %eax,%eax
801042b2:	75 0c                	jne    801042c0 <userinit+0x3e>
    panic("userinit: out of memory?");
801042b4:	c7 04 24 f4 85 10 80 	movl   $0x801085f4,(%esp)
801042bb:	e8 86 c2 ff ff       	call   80100546 <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801042c0:	ba 2c 00 00 00       	mov    $0x2c,%edx
801042c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042c8:	8b 40 04             	mov    0x4(%eax),%eax
801042cb:	89 54 24 08          	mov    %edx,0x8(%esp)
801042cf:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
801042d6:	80 
801042d7:	89 04 24             	mov    %eax,(%esp)
801042da:	e8 38 3a 00 00       	call   80107d17 <inituvm>
  p->sz = PGSIZE;
801042df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042e2:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
801042e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042eb:	8b 40 18             	mov    0x18(%eax),%eax
801042ee:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
801042f5:	00 
801042f6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801042fd:	00 
801042fe:	89 04 24             	mov    %eax,(%esp)
80104301:	e8 58 0c 00 00       	call   80104f5e <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104306:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104309:	8b 40 18             	mov    0x18(%eax),%eax
8010430c:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104312:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104315:	8b 40 18             	mov    0x18(%eax),%eax
80104318:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010431e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104321:	8b 40 18             	mov    0x18(%eax),%eax
80104324:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104327:	8b 52 18             	mov    0x18(%edx),%edx
8010432a:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010432e:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104332:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104335:	8b 40 18             	mov    0x18(%eax),%eax
80104338:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010433b:	8b 52 18             	mov    0x18(%edx),%edx
8010433e:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104342:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104346:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104349:	8b 40 18             	mov    0x18(%eax),%eax
8010434c:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104353:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104356:	8b 40 18             	mov    0x18(%eax),%eax
80104359:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104360:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104363:	8b 40 18             	mov    0x18(%eax),%eax
80104366:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
8010436d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104370:	83 c0 6c             	add    $0x6c,%eax
80104373:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010437a:	00 
8010437b:	c7 44 24 04 0d 86 10 	movl   $0x8010860d,0x4(%esp)
80104382:	80 
80104383:	89 04 24             	mov    %eax,(%esp)
80104386:	e8 03 0e 00 00       	call   8010518e <safestrcpy>
  p->cwd = namei("/");
8010438b:	c7 04 24 16 86 10 80 	movl   $0x80108616,(%esp)
80104392:	e8 ba e1 ff ff       	call   80102551 <namei>
80104397:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010439a:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
8010439d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043a0:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
801043a7:	c9                   	leave  
801043a8:	c3                   	ret    

801043a9 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
801043a9:	55                   	push   %ebp
801043aa:	89 e5                	mov    %esp,%ebp
801043ac:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
801043af:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043b5:	8b 00                	mov    (%eax),%eax
801043b7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
801043ba:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801043be:	7e 34                	jle    801043f4 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
801043c0:	8b 55 08             	mov    0x8(%ebp),%edx
801043c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043c6:	01 c2                	add    %eax,%edx
801043c8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043ce:	8b 40 04             	mov    0x4(%eax),%eax
801043d1:	89 54 24 08          	mov    %edx,0x8(%esp)
801043d5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043d8:	89 54 24 04          	mov    %edx,0x4(%esp)
801043dc:	89 04 24             	mov    %eax,(%esp)
801043df:	e8 ad 3a 00 00       	call   80107e91 <allocuvm>
801043e4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801043e7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801043eb:	75 41                	jne    8010442e <growproc+0x85>
      return -1;
801043ed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043f2:	eb 58                	jmp    8010444c <growproc+0xa3>
  } else if(n < 0){
801043f4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801043f8:	79 34                	jns    8010442e <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801043fa:	8b 55 08             	mov    0x8(%ebp),%edx
801043fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104400:	01 c2                	add    %eax,%edx
80104402:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104408:	8b 40 04             	mov    0x4(%eax),%eax
8010440b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010440f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104412:	89 54 24 04          	mov    %edx,0x4(%esp)
80104416:	89 04 24             	mov    %eax,(%esp)
80104419:	e8 4d 3b 00 00       	call   80107f6b <deallocuvm>
8010441e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104421:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104425:	75 07                	jne    8010442e <growproc+0x85>
      return -1;
80104427:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010442c:	eb 1e                	jmp    8010444c <growproc+0xa3>
  }
  proc->sz = sz;
8010442e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104434:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104437:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104439:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010443f:	89 04 24             	mov    %eax,(%esp)
80104442:	e8 69 37 00 00       	call   80107bb0 <switchuvm>
  return 0;
80104447:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010444c:	c9                   	leave  
8010444d:	c3                   	ret    

8010444e <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
8010444e:	55                   	push   %ebp
8010444f:	89 e5                	mov    %esp,%ebp
80104451:	57                   	push   %edi
80104452:	56                   	push   %esi
80104453:	53                   	push   %ebx
80104454:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104457:	e8 27 fd ff ff       	call   80104183 <allocproc>
8010445c:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010445f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104463:	75 0a                	jne    8010446f <fork+0x21>
    return -1;
80104465:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010446a:	e9 3a 01 00 00       	jmp    801045a9 <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
8010446f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104475:	8b 10                	mov    (%eax),%edx
80104477:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010447d:	8b 40 04             	mov    0x4(%eax),%eax
80104480:	89 54 24 04          	mov    %edx,0x4(%esp)
80104484:	89 04 24             	mov    %eax,(%esp)
80104487:	e8 7b 3c 00 00       	call   80108107 <copyuvm>
8010448c:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010448f:	89 42 04             	mov    %eax,0x4(%edx)
80104492:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104495:	8b 40 04             	mov    0x4(%eax),%eax
80104498:	85 c0                	test   %eax,%eax
8010449a:	75 2c                	jne    801044c8 <fork+0x7a>
    kfree(np->kstack);
8010449c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010449f:	8b 40 08             	mov    0x8(%eax),%eax
801044a2:	89 04 24             	mov    %eax,(%esp)
801044a5:	e8 04 e7 ff ff       	call   80102bae <kfree>
    np->kstack = 0;
801044aa:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044ad:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
801044b4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044b7:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
801044be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044c3:	e9 e1 00 00 00       	jmp    801045a9 <fork+0x15b>
  }
  np->sz = proc->sz;
801044c8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044ce:	8b 10                	mov    (%eax),%edx
801044d0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044d3:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
801044d5:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801044dc:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044df:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
801044e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044e5:	8b 50 18             	mov    0x18(%eax),%edx
801044e8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044ee:	8b 40 18             	mov    0x18(%eax),%eax
801044f1:	89 c3                	mov    %eax,%ebx
801044f3:	b8 13 00 00 00       	mov    $0x13,%eax
801044f8:	89 d7                	mov    %edx,%edi
801044fa:	89 de                	mov    %ebx,%esi
801044fc:	89 c1                	mov    %eax,%ecx
801044fe:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104500:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104503:	8b 40 18             	mov    0x18(%eax),%eax
80104506:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
8010450d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104514:	eb 3d                	jmp    80104553 <fork+0x105>
    if(proc->ofile[i])
80104516:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010451c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010451f:	83 c2 08             	add    $0x8,%edx
80104522:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104526:	85 c0                	test   %eax,%eax
80104528:	74 25                	je     8010454f <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
8010452a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104530:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104533:	83 c2 08             	add    $0x8,%edx
80104536:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010453a:	89 04 24             	mov    %eax,(%esp)
8010453d:	e8 5e cb ff ff       	call   801010a0 <filedup>
80104542:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104545:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104548:	83 c1 08             	add    $0x8,%ecx
8010454b:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
8010454f:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104553:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104557:	7e bd                	jle    80104516 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104559:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010455f:	8b 40 68             	mov    0x68(%eax),%eax
80104562:	89 04 24             	mov    %eax,(%esp)
80104565:	e8 f4 d3 ff ff       	call   8010195e <idup>
8010456a:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010456d:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
80104570:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104573:	8b 40 10             	mov    0x10(%eax),%eax
80104576:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80104579:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010457c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104583:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104589:	8d 50 6c             	lea    0x6c(%eax),%edx
8010458c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010458f:	83 c0 6c             	add    $0x6c,%eax
80104592:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104599:	00 
8010459a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010459e:	89 04 24             	mov    %eax,(%esp)
801045a1:	e8 e8 0b 00 00       	call   8010518e <safestrcpy>
  return pid;
801045a6:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
801045a9:	83 c4 2c             	add    $0x2c,%esp
801045ac:	5b                   	pop    %ebx
801045ad:	5e                   	pop    %esi
801045ae:	5f                   	pop    %edi
801045af:	5d                   	pop    %ebp
801045b0:	c3                   	ret    

801045b1 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
801045b1:	55                   	push   %ebp
801045b2:	89 e5                	mov    %esp,%ebp
801045b4:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
801045b7:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801045be:	a1 48 b6 10 80       	mov    0x8010b648,%eax
801045c3:	39 c2                	cmp    %eax,%edx
801045c5:	75 0c                	jne    801045d3 <exit+0x22>
    panic("init exiting");
801045c7:	c7 04 24 18 86 10 80 	movl   $0x80108618,(%esp)
801045ce:	e8 73 bf ff ff       	call   80100546 <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801045d3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801045da:	eb 44                	jmp    80104620 <exit+0x6f>
    if(proc->ofile[fd]){
801045dc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045e2:	8b 55 f0             	mov    -0x10(%ebp),%edx
801045e5:	83 c2 08             	add    $0x8,%edx
801045e8:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801045ec:	85 c0                	test   %eax,%eax
801045ee:	74 2c                	je     8010461c <exit+0x6b>
      fileclose(proc->ofile[fd]);
801045f0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045f6:	8b 55 f0             	mov    -0x10(%ebp),%edx
801045f9:	83 c2 08             	add    $0x8,%edx
801045fc:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104600:	89 04 24             	mov    %eax,(%esp)
80104603:	e8 e0 ca ff ff       	call   801010e8 <fileclose>
      proc->ofile[fd] = 0;
80104608:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010460e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104611:	83 c2 08             	add    $0x8,%edx
80104614:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010461b:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010461c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104620:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104624:	7e b6                	jle    801045dc <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
80104626:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010462c:	8b 40 68             	mov    0x68(%eax),%eax
8010462f:	89 04 24             	mov    %eax,(%esp)
80104632:	e8 0c d5 ff ff       	call   80101b43 <iput>
  proc->cwd = 0;
80104637:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010463d:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104644:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
8010464b:	e8 b3 06 00 00       	call   80104d03 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104650:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104656:	8b 40 14             	mov    0x14(%eax),%eax
80104659:	89 04 24             	mov    %eax,(%esp)
8010465c:	e8 5f 04 00 00       	call   80104ac0 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104661:	c7 45 f4 74 04 11 80 	movl   $0x80110474,-0xc(%ebp)
80104668:	eb 38                	jmp    801046a2 <exit+0xf1>
    if(p->parent == proc){
8010466a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010466d:	8b 50 14             	mov    0x14(%eax),%edx
80104670:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104676:	39 c2                	cmp    %eax,%edx
80104678:	75 24                	jne    8010469e <exit+0xed>
      p->parent = initproc;
8010467a:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
80104680:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104683:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104686:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104689:	8b 40 0c             	mov    0xc(%eax),%eax
8010468c:	83 f8 05             	cmp    $0x5,%eax
8010468f:	75 0d                	jne    8010469e <exit+0xed>
        wakeup1(initproc);
80104691:	a1 48 b6 10 80       	mov    0x8010b648,%eax
80104696:	89 04 24             	mov    %eax,(%esp)
80104699:	e8 22 04 00 00       	call   80104ac0 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010469e:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801046a2:	81 7d f4 74 23 11 80 	cmpl   $0x80112374,-0xc(%ebp)
801046a9:	72 bf                	jb     8010466a <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
801046ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046b1:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
801046b8:	e8 58 02 00 00       	call   80104915 <sched>
  panic("zombie exit");
801046bd:	c7 04 24 25 86 10 80 	movl   $0x80108625,(%esp)
801046c4:	e8 7d be ff ff       	call   80100546 <panic>

801046c9 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
801046c9:	55                   	push   %ebp
801046ca:	89 e5                	mov    %esp,%ebp
801046cc:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
801046cf:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801046d6:	e8 28 06 00 00       	call   80104d03 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
801046db:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801046e2:	c7 45 f4 74 04 11 80 	movl   $0x80110474,-0xc(%ebp)
801046e9:	e9 9a 00 00 00       	jmp    80104788 <wait+0xbf>
      if(p->parent != proc)
801046ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046f1:	8b 50 14             	mov    0x14(%eax),%edx
801046f4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046fa:	39 c2                	cmp    %eax,%edx
801046fc:	0f 85 81 00 00 00    	jne    80104783 <wait+0xba>
        continue;
      havekids = 1;
80104702:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104709:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010470c:	8b 40 0c             	mov    0xc(%eax),%eax
8010470f:	83 f8 05             	cmp    $0x5,%eax
80104712:	75 70                	jne    80104784 <wait+0xbb>
        // Found one.
        pid = p->pid;
80104714:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104717:	8b 40 10             	mov    0x10(%eax),%eax
8010471a:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
8010471d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104720:	8b 40 08             	mov    0x8(%eax),%eax
80104723:	89 04 24             	mov    %eax,(%esp)
80104726:	e8 83 e4 ff ff       	call   80102bae <kfree>
        p->kstack = 0;
8010472b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010472e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104735:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104738:	8b 40 04             	mov    0x4(%eax),%eax
8010473b:	89 04 24             	mov    %eax,(%esp)
8010473e:	e8 e4 38 00 00       	call   80108027 <freevm>
        p->state = UNUSED;
80104743:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104746:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
8010474d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104750:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104757:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010475a:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104761:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104764:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80104768:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010476b:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104772:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104779:	e8 e7 05 00 00       	call   80104d65 <release>
        return pid;
8010477e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104781:	eb 53                	jmp    801047d6 <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
80104783:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104784:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104788:	81 7d f4 74 23 11 80 	cmpl   $0x80112374,-0xc(%ebp)
8010478f:	0f 82 59 ff ff ff    	jb     801046ee <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104795:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104799:	74 0d                	je     801047a8 <wait+0xdf>
8010479b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047a1:	8b 40 24             	mov    0x24(%eax),%eax
801047a4:	85 c0                	test   %eax,%eax
801047a6:	74 13                	je     801047bb <wait+0xf2>
      release(&ptable.lock);
801047a8:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801047af:	e8 b1 05 00 00       	call   80104d65 <release>
      return -1;
801047b4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047b9:	eb 1b                	jmp    801047d6 <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
801047bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047c1:	c7 44 24 04 40 04 11 	movl   $0x80110440,0x4(%esp)
801047c8:	80 
801047c9:	89 04 24             	mov    %eax,(%esp)
801047cc:	e8 54 02 00 00       	call   80104a25 <sleep>
  }
801047d1:	e9 05 ff ff ff       	jmp    801046db <wait+0x12>
}
801047d6:	c9                   	leave  
801047d7:	c3                   	ret    

801047d8 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
801047d8:	55                   	push   %ebp
801047d9:	89 e5                	mov    %esp,%ebp
801047db:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
801047de:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047e4:	8b 40 18             	mov    0x18(%eax),%eax
801047e7:	8b 40 44             	mov    0x44(%eax),%eax
801047ea:	89 c2                	mov    %eax,%edx
801047ec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047f2:	8b 40 04             	mov    0x4(%eax),%eax
801047f5:	89 54 24 04          	mov    %edx,0x4(%esp)
801047f9:	89 04 24             	mov    %eax,(%esp)
801047fc:	e8 17 3a 00 00       	call   80108218 <uva2ka>
80104801:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
80104804:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010480a:	8b 40 18             	mov    0x18(%eax),%eax
8010480d:	8b 40 44             	mov    0x44(%eax),%eax
80104810:	25 ff 0f 00 00       	and    $0xfff,%eax
80104815:	85 c0                	test   %eax,%eax
80104817:	75 0c                	jne    80104825 <register_handler+0x4d>
    panic("esp_offset == 0");
80104819:	c7 04 24 31 86 10 80 	movl   $0x80108631,(%esp)
80104820:	e8 21 bd ff ff       	call   80100546 <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80104825:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010482b:	8b 40 18             	mov    0x18(%eax),%eax
8010482e:	8b 40 44             	mov    0x44(%eax),%eax
80104831:	83 e8 04             	sub    $0x4,%eax
80104834:	89 c2                	mov    %eax,%edx
80104836:	81 e2 ff 0f 00 00    	and    $0xfff,%edx
8010483c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010483f:	01 c2                	add    %eax,%edx
          = proc->tf->eip;
80104841:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104847:	8b 40 18             	mov    0x18(%eax),%eax
8010484a:	8b 40 38             	mov    0x38(%eax),%eax
8010484d:	89 02                	mov    %eax,(%edx)
  proc->tf->esp -= 4;
8010484f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104855:	8b 40 18             	mov    0x18(%eax),%eax
80104858:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010485f:	8b 52 18             	mov    0x18(%edx),%edx
80104862:	8b 52 44             	mov    0x44(%edx),%edx
80104865:	83 ea 04             	sub    $0x4,%edx
80104868:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
8010486b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104871:	8b 40 18             	mov    0x18(%eax),%eax
80104874:	8b 55 08             	mov    0x8(%ebp),%edx
80104877:	89 50 38             	mov    %edx,0x38(%eax)
}
8010487a:	c9                   	leave  
8010487b:	c3                   	ret    

8010487c <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
8010487c:	55                   	push   %ebp
8010487d:	89 e5                	mov    %esp,%ebp
8010487f:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104882:	e8 da f8 ff ff       	call   80104161 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104887:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
8010488e:	e8 70 04 00 00       	call   80104d03 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104893:	c7 45 f4 74 04 11 80 	movl   $0x80110474,-0xc(%ebp)
8010489a:	eb 5f                	jmp    801048fb <scheduler+0x7f>
      if(p->state != RUNNABLE)
8010489c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010489f:	8b 40 0c             	mov    0xc(%eax),%eax
801048a2:	83 f8 03             	cmp    $0x3,%eax
801048a5:	75 4f                	jne    801048f6 <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801048a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048aa:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
801048b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048b3:	89 04 24             	mov    %eax,(%esp)
801048b6:	e8 f5 32 00 00       	call   80107bb0 <switchuvm>
      p->state = RUNNING;
801048bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048be:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
801048c5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048cb:	8b 40 1c             	mov    0x1c(%eax),%eax
801048ce:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801048d5:	83 c2 04             	add    $0x4,%edx
801048d8:	89 44 24 04          	mov    %eax,0x4(%esp)
801048dc:	89 14 24             	mov    %edx,(%esp)
801048df:	e8 20 09 00 00       	call   80105204 <swtch>
      switchkvm();
801048e4:	e8 aa 32 00 00       	call   80107b93 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
801048e9:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801048f0:	00 00 00 00 
801048f4:	eb 01                	jmp    801048f7 <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
801048f6:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801048f7:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801048fb:	81 7d f4 74 23 11 80 	cmpl   $0x80112374,-0xc(%ebp)
80104902:	72 98                	jb     8010489c <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104904:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
8010490b:	e8 55 04 00 00       	call   80104d65 <release>

  }
80104910:	e9 6d ff ff ff       	jmp    80104882 <scheduler+0x6>

80104915 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104915:	55                   	push   %ebp
80104916:	89 e5                	mov    %esp,%ebp
80104918:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
8010491b:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104922:	e8 06 05 00 00       	call   80104e2d <holding>
80104927:	85 c0                	test   %eax,%eax
80104929:	75 0c                	jne    80104937 <sched+0x22>
    panic("sched ptable.lock");
8010492b:	c7 04 24 41 86 10 80 	movl   $0x80108641,(%esp)
80104932:	e8 0f bc ff ff       	call   80100546 <panic>
  if(cpu->ncli != 1)
80104937:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010493d:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104943:	83 f8 01             	cmp    $0x1,%eax
80104946:	74 0c                	je     80104954 <sched+0x3f>
    panic("sched locks");
80104948:	c7 04 24 53 86 10 80 	movl   $0x80108653,(%esp)
8010494f:	e8 f2 bb ff ff       	call   80100546 <panic>
  if(proc->state == RUNNING)
80104954:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010495a:	8b 40 0c             	mov    0xc(%eax),%eax
8010495d:	83 f8 04             	cmp    $0x4,%eax
80104960:	75 0c                	jne    8010496e <sched+0x59>
    panic("sched running");
80104962:	c7 04 24 5f 86 10 80 	movl   $0x8010865f,(%esp)
80104969:	e8 d8 bb ff ff       	call   80100546 <panic>
  if(readeflags()&FL_IF)
8010496e:	e8 d9 f7 ff ff       	call   8010414c <readeflags>
80104973:	25 00 02 00 00       	and    $0x200,%eax
80104978:	85 c0                	test   %eax,%eax
8010497a:	74 0c                	je     80104988 <sched+0x73>
    panic("sched interruptible");
8010497c:	c7 04 24 6d 86 10 80 	movl   $0x8010866d,(%esp)
80104983:	e8 be bb ff ff       	call   80100546 <panic>
  intena = cpu->intena;
80104988:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010498e:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104994:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104997:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010499d:	8b 40 04             	mov    0x4(%eax),%eax
801049a0:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801049a7:	83 c2 1c             	add    $0x1c,%edx
801049aa:	89 44 24 04          	mov    %eax,0x4(%esp)
801049ae:	89 14 24             	mov    %edx,(%esp)
801049b1:	e8 4e 08 00 00       	call   80105204 <swtch>
  cpu->intena = intena;
801049b6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801049bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801049bf:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801049c5:	c9                   	leave  
801049c6:	c3                   	ret    

801049c7 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
801049c7:	55                   	push   %ebp
801049c8:	89 e5                	mov    %esp,%ebp
801049ca:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801049cd:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801049d4:	e8 2a 03 00 00       	call   80104d03 <acquire>
  proc->state = RUNNABLE;
801049d9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049df:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801049e6:	e8 2a ff ff ff       	call   80104915 <sched>
  release(&ptable.lock);
801049eb:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801049f2:	e8 6e 03 00 00       	call   80104d65 <release>
}
801049f7:	c9                   	leave  
801049f8:	c3                   	ret    

801049f9 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
801049f9:	55                   	push   %ebp
801049fa:	89 e5                	mov    %esp,%ebp
801049fc:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
801049ff:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104a06:	e8 5a 03 00 00       	call   80104d65 <release>

  if (first) {
80104a0b:	a1 20 b0 10 80       	mov    0x8010b020,%eax
80104a10:	85 c0                	test   %eax,%eax
80104a12:	74 0f                	je     80104a23 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104a14:	c7 05 20 b0 10 80 00 	movl   $0x0,0x8010b020
80104a1b:	00 00 00 
    initlog();
80104a1e:	e8 39 e7 ff ff       	call   8010315c <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104a23:	c9                   	leave  
80104a24:	c3                   	ret    

80104a25 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104a25:	55                   	push   %ebp
80104a26:	89 e5                	mov    %esp,%ebp
80104a28:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104a2b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a31:	85 c0                	test   %eax,%eax
80104a33:	75 0c                	jne    80104a41 <sleep+0x1c>
    panic("sleep");
80104a35:	c7 04 24 81 86 10 80 	movl   $0x80108681,(%esp)
80104a3c:	e8 05 bb ff ff       	call   80100546 <panic>

  if(lk == 0)
80104a41:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104a45:	75 0c                	jne    80104a53 <sleep+0x2e>
    panic("sleep without lk");
80104a47:	c7 04 24 87 86 10 80 	movl   $0x80108687,(%esp)
80104a4e:	e8 f3 ba ff ff       	call   80100546 <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104a53:	81 7d 0c 40 04 11 80 	cmpl   $0x80110440,0xc(%ebp)
80104a5a:	74 17                	je     80104a73 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104a5c:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104a63:	e8 9b 02 00 00       	call   80104d03 <acquire>
    release(lk);
80104a68:	8b 45 0c             	mov    0xc(%ebp),%eax
80104a6b:	89 04 24             	mov    %eax,(%esp)
80104a6e:	e8 f2 02 00 00       	call   80104d65 <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104a73:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a79:	8b 55 08             	mov    0x8(%ebp),%edx
80104a7c:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104a7f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a85:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80104a8c:	e8 84 fe ff ff       	call   80104915 <sched>

  // Tidy up.
  proc->chan = 0;
80104a91:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a97:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104a9e:	81 7d 0c 40 04 11 80 	cmpl   $0x80110440,0xc(%ebp)
80104aa5:	74 17                	je     80104abe <sleep+0x99>
    release(&ptable.lock);
80104aa7:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104aae:	e8 b2 02 00 00       	call   80104d65 <release>
    acquire(lk);
80104ab3:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ab6:	89 04 24             	mov    %eax,(%esp)
80104ab9:	e8 45 02 00 00       	call   80104d03 <acquire>
  }
}
80104abe:	c9                   	leave  
80104abf:	c3                   	ret    

80104ac0 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104ac0:	55                   	push   %ebp
80104ac1:	89 e5                	mov    %esp,%ebp
80104ac3:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104ac6:	c7 45 fc 74 04 11 80 	movl   $0x80110474,-0x4(%ebp)
80104acd:	eb 24                	jmp    80104af3 <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80104acf:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104ad2:	8b 40 0c             	mov    0xc(%eax),%eax
80104ad5:	83 f8 02             	cmp    $0x2,%eax
80104ad8:	75 15                	jne    80104aef <wakeup1+0x2f>
80104ada:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104add:	8b 40 20             	mov    0x20(%eax),%eax
80104ae0:	3b 45 08             	cmp    0x8(%ebp),%eax
80104ae3:	75 0a                	jne    80104aef <wakeup1+0x2f>
      p->state = RUNNABLE;
80104ae5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104ae8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104aef:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80104af3:	81 7d fc 74 23 11 80 	cmpl   $0x80112374,-0x4(%ebp)
80104afa:	72 d3                	jb     80104acf <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104afc:	c9                   	leave  
80104afd:	c3                   	ret    

80104afe <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104afe:	55                   	push   %ebp
80104aff:	89 e5                	mov    %esp,%ebp
80104b01:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104b04:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104b0b:	e8 f3 01 00 00       	call   80104d03 <acquire>
  wakeup1(chan);
80104b10:	8b 45 08             	mov    0x8(%ebp),%eax
80104b13:	89 04 24             	mov    %eax,(%esp)
80104b16:	e8 a5 ff ff ff       	call   80104ac0 <wakeup1>
  release(&ptable.lock);
80104b1b:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104b22:	e8 3e 02 00 00       	call   80104d65 <release>
}
80104b27:	c9                   	leave  
80104b28:	c3                   	ret    

80104b29 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104b29:	55                   	push   %ebp
80104b2a:	89 e5                	mov    %esp,%ebp
80104b2c:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104b2f:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104b36:	e8 c8 01 00 00       	call   80104d03 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b3b:	c7 45 f4 74 04 11 80 	movl   $0x80110474,-0xc(%ebp)
80104b42:	eb 41                	jmp    80104b85 <kill+0x5c>
    if(p->pid == pid){
80104b44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b47:	8b 40 10             	mov    0x10(%eax),%eax
80104b4a:	3b 45 08             	cmp    0x8(%ebp),%eax
80104b4d:	75 32                	jne    80104b81 <kill+0x58>
      p->killed = 1;
80104b4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b52:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104b59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b5c:	8b 40 0c             	mov    0xc(%eax),%eax
80104b5f:	83 f8 02             	cmp    $0x2,%eax
80104b62:	75 0a                	jne    80104b6e <kill+0x45>
        p->state = RUNNABLE;
80104b64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b67:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104b6e:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104b75:	e8 eb 01 00 00       	call   80104d65 <release>
      return 0;
80104b7a:	b8 00 00 00 00       	mov    $0x0,%eax
80104b7f:	eb 1e                	jmp    80104b9f <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b81:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104b85:	81 7d f4 74 23 11 80 	cmpl   $0x80112374,-0xc(%ebp)
80104b8c:	72 b6                	jb     80104b44 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104b8e:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104b95:	e8 cb 01 00 00       	call   80104d65 <release>
  return -1;
80104b9a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104b9f:	c9                   	leave  
80104ba0:	c3                   	ret    

80104ba1 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104ba1:	55                   	push   %ebp
80104ba2:	89 e5                	mov    %esp,%ebp
80104ba4:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ba7:	c7 45 f0 74 04 11 80 	movl   $0x80110474,-0x10(%ebp)
80104bae:	e9 d8 00 00 00       	jmp    80104c8b <procdump+0xea>
    if(p->state == UNUSED)
80104bb3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bb6:	8b 40 0c             	mov    0xc(%eax),%eax
80104bb9:	85 c0                	test   %eax,%eax
80104bbb:	0f 84 c5 00 00 00    	je     80104c86 <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104bc1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bc4:	8b 40 0c             	mov    0xc(%eax),%eax
80104bc7:	83 f8 05             	cmp    $0x5,%eax
80104bca:	77 23                	ja     80104bef <procdump+0x4e>
80104bcc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bcf:	8b 40 0c             	mov    0xc(%eax),%eax
80104bd2:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104bd9:	85 c0                	test   %eax,%eax
80104bdb:	74 12                	je     80104bef <procdump+0x4e>
      state = states[p->state];
80104bdd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104be0:	8b 40 0c             	mov    0xc(%eax),%eax
80104be3:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104bea:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104bed:	eb 07                	jmp    80104bf6 <procdump+0x55>
    else
      state = "???";
80104bef:	c7 45 ec 98 86 10 80 	movl   $0x80108698,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104bf6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bf9:	8d 50 6c             	lea    0x6c(%eax),%edx
80104bfc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bff:	8b 40 10             	mov    0x10(%eax),%eax
80104c02:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104c06:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104c09:	89 54 24 08          	mov    %edx,0x8(%esp)
80104c0d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104c11:	c7 04 24 9c 86 10 80 	movl   $0x8010869c,(%esp)
80104c18:	e8 8d b7 ff ff       	call   801003aa <cprintf>
    if(p->state == SLEEPING){
80104c1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c20:	8b 40 0c             	mov    0xc(%eax),%eax
80104c23:	83 f8 02             	cmp    $0x2,%eax
80104c26:	75 50                	jne    80104c78 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104c28:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c2b:	8b 40 1c             	mov    0x1c(%eax),%eax
80104c2e:	8b 40 0c             	mov    0xc(%eax),%eax
80104c31:	83 c0 08             	add    $0x8,%eax
80104c34:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104c37:	89 54 24 04          	mov    %edx,0x4(%esp)
80104c3b:	89 04 24             	mov    %eax,(%esp)
80104c3e:	e8 71 01 00 00       	call   80104db4 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104c43:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104c4a:	eb 1b                	jmp    80104c67 <procdump+0xc6>
        cprintf(" %p", pc[i]);
80104c4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c4f:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104c53:	89 44 24 04          	mov    %eax,0x4(%esp)
80104c57:	c7 04 24 a5 86 10 80 	movl   $0x801086a5,(%esp)
80104c5e:	e8 47 b7 ff ff       	call   801003aa <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104c63:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104c67:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104c6b:	7f 0b                	jg     80104c78 <procdump+0xd7>
80104c6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c70:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104c74:	85 c0                	test   %eax,%eax
80104c76:	75 d4                	jne    80104c4c <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104c78:	c7 04 24 a9 86 10 80 	movl   $0x801086a9,(%esp)
80104c7f:	e8 26 b7 ff ff       	call   801003aa <cprintf>
80104c84:	eb 01                	jmp    80104c87 <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80104c86:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104c87:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104c8b:	81 7d f0 74 23 11 80 	cmpl   $0x80112374,-0x10(%ebp)
80104c92:	0f 82 1b ff ff ff    	jb     80104bb3 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104c98:	c9                   	leave  
80104c99:	c3                   	ret    
80104c9a:	66 90                	xchg   %ax,%ax

80104c9c <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104c9c:	55                   	push   %ebp
80104c9d:	89 e5                	mov    %esp,%ebp
80104c9f:	53                   	push   %ebx
80104ca0:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104ca3:	9c                   	pushf  
80104ca4:	5b                   	pop    %ebx
80104ca5:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104ca8:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104cab:	83 c4 10             	add    $0x10,%esp
80104cae:	5b                   	pop    %ebx
80104caf:	5d                   	pop    %ebp
80104cb0:	c3                   	ret    

80104cb1 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80104cb1:	55                   	push   %ebp
80104cb2:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104cb4:	fa                   	cli    
}
80104cb5:	5d                   	pop    %ebp
80104cb6:	c3                   	ret    

80104cb7 <sti>:

static inline void
sti(void)
{
80104cb7:	55                   	push   %ebp
80104cb8:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104cba:	fb                   	sti    
}
80104cbb:	5d                   	pop    %ebp
80104cbc:	c3                   	ret    

80104cbd <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104cbd:	55                   	push   %ebp
80104cbe:	89 e5                	mov    %esp,%ebp
80104cc0:	53                   	push   %ebx
80104cc1:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80104cc4:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104cc7:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80104cca:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104ccd:	89 c3                	mov    %eax,%ebx
80104ccf:	89 d8                	mov    %ebx,%eax
80104cd1:	f0 87 02             	lock xchg %eax,(%edx)
80104cd4:	89 c3                	mov    %eax,%ebx
80104cd6:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104cd9:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104cdc:	83 c4 10             	add    $0x10,%esp
80104cdf:	5b                   	pop    %ebx
80104ce0:	5d                   	pop    %ebp
80104ce1:	c3                   	ret    

80104ce2 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104ce2:	55                   	push   %ebp
80104ce3:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104ce5:	8b 45 08             	mov    0x8(%ebp),%eax
80104ce8:	8b 55 0c             	mov    0xc(%ebp),%edx
80104ceb:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104cee:	8b 45 08             	mov    0x8(%ebp),%eax
80104cf1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104cf7:	8b 45 08             	mov    0x8(%ebp),%eax
80104cfa:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104d01:	5d                   	pop    %ebp
80104d02:	c3                   	ret    

80104d03 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104d03:	55                   	push   %ebp
80104d04:	89 e5                	mov    %esp,%ebp
80104d06:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104d09:	e8 49 01 00 00       	call   80104e57 <pushcli>
  if(holding(lk))
80104d0e:	8b 45 08             	mov    0x8(%ebp),%eax
80104d11:	89 04 24             	mov    %eax,(%esp)
80104d14:	e8 14 01 00 00       	call   80104e2d <holding>
80104d19:	85 c0                	test   %eax,%eax
80104d1b:	74 0c                	je     80104d29 <acquire+0x26>
    panic("acquire");
80104d1d:	c7 04 24 d5 86 10 80 	movl   $0x801086d5,(%esp)
80104d24:	e8 1d b8 ff ff       	call   80100546 <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80104d29:	90                   	nop
80104d2a:	8b 45 08             	mov    0x8(%ebp),%eax
80104d2d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80104d34:	00 
80104d35:	89 04 24             	mov    %eax,(%esp)
80104d38:	e8 80 ff ff ff       	call   80104cbd <xchg>
80104d3d:	85 c0                	test   %eax,%eax
80104d3f:	75 e9                	jne    80104d2a <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80104d41:	8b 45 08             	mov    0x8(%ebp),%eax
80104d44:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104d4b:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80104d4e:	8b 45 08             	mov    0x8(%ebp),%eax
80104d51:	83 c0 0c             	add    $0xc,%eax
80104d54:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d58:	8d 45 08             	lea    0x8(%ebp),%eax
80104d5b:	89 04 24             	mov    %eax,(%esp)
80104d5e:	e8 51 00 00 00       	call   80104db4 <getcallerpcs>
}
80104d63:	c9                   	leave  
80104d64:	c3                   	ret    

80104d65 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80104d65:	55                   	push   %ebp
80104d66:	89 e5                	mov    %esp,%ebp
80104d68:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80104d6b:	8b 45 08             	mov    0x8(%ebp),%eax
80104d6e:	89 04 24             	mov    %eax,(%esp)
80104d71:	e8 b7 00 00 00       	call   80104e2d <holding>
80104d76:	85 c0                	test   %eax,%eax
80104d78:	75 0c                	jne    80104d86 <release+0x21>
    panic("release");
80104d7a:	c7 04 24 dd 86 10 80 	movl   $0x801086dd,(%esp)
80104d81:	e8 c0 b7 ff ff       	call   80100546 <panic>

  lk->pcs[0] = 0;
80104d86:	8b 45 08             	mov    0x8(%ebp),%eax
80104d89:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80104d90:	8b 45 08             	mov    0x8(%ebp),%eax
80104d93:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80104d9a:	8b 45 08             	mov    0x8(%ebp),%eax
80104d9d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104da4:	00 
80104da5:	89 04 24             	mov    %eax,(%esp)
80104da8:	e8 10 ff ff ff       	call   80104cbd <xchg>

  popcli();
80104dad:	e8 ed 00 00 00       	call   80104e9f <popcli>
}
80104db2:	c9                   	leave  
80104db3:	c3                   	ret    

80104db4 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80104db4:	55                   	push   %ebp
80104db5:	89 e5                	mov    %esp,%ebp
80104db7:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80104dba:	8b 45 08             	mov    0x8(%ebp),%eax
80104dbd:	83 e8 08             	sub    $0x8,%eax
80104dc0:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80104dc3:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80104dca:	eb 38                	jmp    80104e04 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80104dcc:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80104dd0:	74 53                	je     80104e25 <getcallerpcs+0x71>
80104dd2:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80104dd9:	76 4a                	jbe    80104e25 <getcallerpcs+0x71>
80104ddb:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80104ddf:	74 44                	je     80104e25 <getcallerpcs+0x71>
      break;
    pcs[i] = ebp[1];     // saved %eip
80104de1:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104de4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80104deb:	8b 45 0c             	mov    0xc(%ebp),%eax
80104dee:	01 c2                	add    %eax,%edx
80104df0:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104df3:	8b 40 04             	mov    0x4(%eax),%eax
80104df6:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
80104df8:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104dfb:	8b 00                	mov    (%eax),%eax
80104dfd:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80104e00:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104e04:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104e08:	7e c2                	jle    80104dcc <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104e0a:	eb 19                	jmp    80104e25 <getcallerpcs+0x71>
    pcs[i] = 0;
80104e0c:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104e0f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80104e16:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e19:	01 d0                	add    %edx,%eax
80104e1b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104e21:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104e25:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104e29:	7e e1                	jle    80104e0c <getcallerpcs+0x58>
    pcs[i] = 0;
}
80104e2b:	c9                   	leave  
80104e2c:	c3                   	ret    

80104e2d <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80104e2d:	55                   	push   %ebp
80104e2e:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80104e30:	8b 45 08             	mov    0x8(%ebp),%eax
80104e33:	8b 00                	mov    (%eax),%eax
80104e35:	85 c0                	test   %eax,%eax
80104e37:	74 17                	je     80104e50 <holding+0x23>
80104e39:	8b 45 08             	mov    0x8(%ebp),%eax
80104e3c:	8b 50 08             	mov    0x8(%eax),%edx
80104e3f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e45:	39 c2                	cmp    %eax,%edx
80104e47:	75 07                	jne    80104e50 <holding+0x23>
80104e49:	b8 01 00 00 00       	mov    $0x1,%eax
80104e4e:	eb 05                	jmp    80104e55 <holding+0x28>
80104e50:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e55:	5d                   	pop    %ebp
80104e56:	c3                   	ret    

80104e57 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80104e57:	55                   	push   %ebp
80104e58:	89 e5                	mov    %esp,%ebp
80104e5a:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80104e5d:	e8 3a fe ff ff       	call   80104c9c <readeflags>
80104e62:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80104e65:	e8 47 fe ff ff       	call   80104cb1 <cli>
  if(cpu->ncli++ == 0)
80104e6a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e70:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104e76:	85 d2                	test   %edx,%edx
80104e78:	0f 94 c1             	sete   %cl
80104e7b:	83 c2 01             	add    $0x1,%edx
80104e7e:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104e84:	84 c9                	test   %cl,%cl
80104e86:	74 15                	je     80104e9d <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80104e88:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e8e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104e91:	81 e2 00 02 00 00    	and    $0x200,%edx
80104e97:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104e9d:	c9                   	leave  
80104e9e:	c3                   	ret    

80104e9f <popcli>:

void
popcli(void)
{
80104e9f:	55                   	push   %ebp
80104ea0:	89 e5                	mov    %esp,%ebp
80104ea2:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80104ea5:	e8 f2 fd ff ff       	call   80104c9c <readeflags>
80104eaa:	25 00 02 00 00       	and    $0x200,%eax
80104eaf:	85 c0                	test   %eax,%eax
80104eb1:	74 0c                	je     80104ebf <popcli+0x20>
    panic("popcli - interruptible");
80104eb3:	c7 04 24 e5 86 10 80 	movl   $0x801086e5,(%esp)
80104eba:	e8 87 b6 ff ff       	call   80100546 <panic>
  if(--cpu->ncli < 0)
80104ebf:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104ec5:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104ecb:	83 ea 01             	sub    $0x1,%edx
80104ece:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104ed4:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104eda:	85 c0                	test   %eax,%eax
80104edc:	79 0c                	jns    80104eea <popcli+0x4b>
    panic("popcli");
80104ede:	c7 04 24 fc 86 10 80 	movl   $0x801086fc,(%esp)
80104ee5:	e8 5c b6 ff ff       	call   80100546 <panic>
  if(cpu->ncli == 0 && cpu->intena)
80104eea:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104ef0:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104ef6:	85 c0                	test   %eax,%eax
80104ef8:	75 15                	jne    80104f0f <popcli+0x70>
80104efa:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104f00:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104f06:	85 c0                	test   %eax,%eax
80104f08:	74 05                	je     80104f0f <popcli+0x70>
    sti();
80104f0a:	e8 a8 fd ff ff       	call   80104cb7 <sti>
}
80104f0f:	c9                   	leave  
80104f10:	c3                   	ret    
80104f11:	66 90                	xchg   %ax,%ax
80104f13:	90                   	nop

80104f14 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80104f14:	55                   	push   %ebp
80104f15:	89 e5                	mov    %esp,%ebp
80104f17:	57                   	push   %edi
80104f18:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80104f19:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104f1c:	8b 55 10             	mov    0x10(%ebp),%edx
80104f1f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f22:	89 cb                	mov    %ecx,%ebx
80104f24:	89 df                	mov    %ebx,%edi
80104f26:	89 d1                	mov    %edx,%ecx
80104f28:	fc                   	cld    
80104f29:	f3 aa                	rep stos %al,%es:(%edi)
80104f2b:	89 ca                	mov    %ecx,%edx
80104f2d:	89 fb                	mov    %edi,%ebx
80104f2f:	89 5d 08             	mov    %ebx,0x8(%ebp)
80104f32:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80104f35:	5b                   	pop    %ebx
80104f36:	5f                   	pop    %edi
80104f37:	5d                   	pop    %ebp
80104f38:	c3                   	ret    

80104f39 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80104f39:	55                   	push   %ebp
80104f3a:	89 e5                	mov    %esp,%ebp
80104f3c:	57                   	push   %edi
80104f3d:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80104f3e:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104f41:	8b 55 10             	mov    0x10(%ebp),%edx
80104f44:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f47:	89 cb                	mov    %ecx,%ebx
80104f49:	89 df                	mov    %ebx,%edi
80104f4b:	89 d1                	mov    %edx,%ecx
80104f4d:	fc                   	cld    
80104f4e:	f3 ab                	rep stos %eax,%es:(%edi)
80104f50:	89 ca                	mov    %ecx,%edx
80104f52:	89 fb                	mov    %edi,%ebx
80104f54:	89 5d 08             	mov    %ebx,0x8(%ebp)
80104f57:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80104f5a:	5b                   	pop    %ebx
80104f5b:	5f                   	pop    %edi
80104f5c:	5d                   	pop    %ebp
80104f5d:	c3                   	ret    

80104f5e <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80104f5e:	55                   	push   %ebp
80104f5f:	89 e5                	mov    %esp,%ebp
80104f61:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80104f64:	8b 45 08             	mov    0x8(%ebp),%eax
80104f67:	83 e0 03             	and    $0x3,%eax
80104f6a:	85 c0                	test   %eax,%eax
80104f6c:	75 49                	jne    80104fb7 <memset+0x59>
80104f6e:	8b 45 10             	mov    0x10(%ebp),%eax
80104f71:	83 e0 03             	and    $0x3,%eax
80104f74:	85 c0                	test   %eax,%eax
80104f76:	75 3f                	jne    80104fb7 <memset+0x59>
    c &= 0xFF;
80104f78:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80104f7f:	8b 45 10             	mov    0x10(%ebp),%eax
80104f82:	c1 e8 02             	shr    $0x2,%eax
80104f85:	89 c2                	mov    %eax,%edx
80104f87:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f8a:	89 c1                	mov    %eax,%ecx
80104f8c:	c1 e1 18             	shl    $0x18,%ecx
80104f8f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f92:	c1 e0 10             	shl    $0x10,%eax
80104f95:	09 c1                	or     %eax,%ecx
80104f97:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f9a:	c1 e0 08             	shl    $0x8,%eax
80104f9d:	09 c8                	or     %ecx,%eax
80104f9f:	0b 45 0c             	or     0xc(%ebp),%eax
80104fa2:	89 54 24 08          	mov    %edx,0x8(%esp)
80104fa6:	89 44 24 04          	mov    %eax,0x4(%esp)
80104faa:	8b 45 08             	mov    0x8(%ebp),%eax
80104fad:	89 04 24             	mov    %eax,(%esp)
80104fb0:	e8 84 ff ff ff       	call   80104f39 <stosl>
80104fb5:	eb 19                	jmp    80104fd0 <memset+0x72>
  } else
    stosb(dst, c, n);
80104fb7:	8b 45 10             	mov    0x10(%ebp),%eax
80104fba:	89 44 24 08          	mov    %eax,0x8(%esp)
80104fbe:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fc1:	89 44 24 04          	mov    %eax,0x4(%esp)
80104fc5:	8b 45 08             	mov    0x8(%ebp),%eax
80104fc8:	89 04 24             	mov    %eax,(%esp)
80104fcb:	e8 44 ff ff ff       	call   80104f14 <stosb>
  return dst;
80104fd0:	8b 45 08             	mov    0x8(%ebp),%eax
}
80104fd3:	c9                   	leave  
80104fd4:	c3                   	ret    

80104fd5 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80104fd5:	55                   	push   %ebp
80104fd6:	89 e5                	mov    %esp,%ebp
80104fd8:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80104fdb:	8b 45 08             	mov    0x8(%ebp),%eax
80104fde:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80104fe1:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fe4:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80104fe7:	eb 32                	jmp    8010501b <memcmp+0x46>
    if(*s1 != *s2)
80104fe9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104fec:	0f b6 10             	movzbl (%eax),%edx
80104fef:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104ff2:	0f b6 00             	movzbl (%eax),%eax
80104ff5:	38 c2                	cmp    %al,%dl
80104ff7:	74 1a                	je     80105013 <memcmp+0x3e>
      return *s1 - *s2;
80104ff9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104ffc:	0f b6 00             	movzbl (%eax),%eax
80104fff:	0f b6 d0             	movzbl %al,%edx
80105002:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105005:	0f b6 00             	movzbl (%eax),%eax
80105008:	0f b6 c0             	movzbl %al,%eax
8010500b:	89 d1                	mov    %edx,%ecx
8010500d:	29 c1                	sub    %eax,%ecx
8010500f:	89 c8                	mov    %ecx,%eax
80105011:	eb 1c                	jmp    8010502f <memcmp+0x5a>
    s1++, s2++;
80105013:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105017:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
8010501b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010501f:	0f 95 c0             	setne  %al
80105022:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105026:	84 c0                	test   %al,%al
80105028:	75 bf                	jne    80104fe9 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
8010502a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010502f:	c9                   	leave  
80105030:	c3                   	ret    

80105031 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105031:	55                   	push   %ebp
80105032:	89 e5                	mov    %esp,%ebp
80105034:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105037:	8b 45 0c             	mov    0xc(%ebp),%eax
8010503a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
8010503d:	8b 45 08             	mov    0x8(%ebp),%eax
80105040:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105043:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105046:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105049:	73 54                	jae    8010509f <memmove+0x6e>
8010504b:	8b 45 10             	mov    0x10(%ebp),%eax
8010504e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105051:	01 d0                	add    %edx,%eax
80105053:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105056:	76 47                	jbe    8010509f <memmove+0x6e>
    s += n;
80105058:	8b 45 10             	mov    0x10(%ebp),%eax
8010505b:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
8010505e:	8b 45 10             	mov    0x10(%ebp),%eax
80105061:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105064:	eb 13                	jmp    80105079 <memmove+0x48>
      *--d = *--s;
80105066:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
8010506a:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
8010506e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105071:	0f b6 10             	movzbl (%eax),%edx
80105074:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105077:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105079:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010507d:	0f 95 c0             	setne  %al
80105080:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105084:	84 c0                	test   %al,%al
80105086:	75 de                	jne    80105066 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105088:	eb 25                	jmp    801050af <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
8010508a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010508d:	0f b6 10             	movzbl (%eax),%edx
80105090:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105093:	88 10                	mov    %dl,(%eax)
80105095:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105099:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010509d:	eb 01                	jmp    801050a0 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
8010509f:	90                   	nop
801050a0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801050a4:	0f 95 c0             	setne  %al
801050a7:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801050ab:	84 c0                	test   %al,%al
801050ad:	75 db                	jne    8010508a <memmove+0x59>
      *d++ = *s++;

  return dst;
801050af:	8b 45 08             	mov    0x8(%ebp),%eax
}
801050b2:	c9                   	leave  
801050b3:	c3                   	ret    

801050b4 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
801050b4:	55                   	push   %ebp
801050b5:	89 e5                	mov    %esp,%ebp
801050b7:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
801050ba:	8b 45 10             	mov    0x10(%ebp),%eax
801050bd:	89 44 24 08          	mov    %eax,0x8(%esp)
801050c1:	8b 45 0c             	mov    0xc(%ebp),%eax
801050c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801050c8:	8b 45 08             	mov    0x8(%ebp),%eax
801050cb:	89 04 24             	mov    %eax,(%esp)
801050ce:	e8 5e ff ff ff       	call   80105031 <memmove>
}
801050d3:	c9                   	leave  
801050d4:	c3                   	ret    

801050d5 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801050d5:	55                   	push   %ebp
801050d6:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
801050d8:	eb 0c                	jmp    801050e6 <strncmp+0x11>
    n--, p++, q++;
801050da:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801050de:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801050e2:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
801050e6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801050ea:	74 1a                	je     80105106 <strncmp+0x31>
801050ec:	8b 45 08             	mov    0x8(%ebp),%eax
801050ef:	0f b6 00             	movzbl (%eax),%eax
801050f2:	84 c0                	test   %al,%al
801050f4:	74 10                	je     80105106 <strncmp+0x31>
801050f6:	8b 45 08             	mov    0x8(%ebp),%eax
801050f9:	0f b6 10             	movzbl (%eax),%edx
801050fc:	8b 45 0c             	mov    0xc(%ebp),%eax
801050ff:	0f b6 00             	movzbl (%eax),%eax
80105102:	38 c2                	cmp    %al,%dl
80105104:	74 d4                	je     801050da <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105106:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010510a:	75 07                	jne    80105113 <strncmp+0x3e>
    return 0;
8010510c:	b8 00 00 00 00       	mov    $0x0,%eax
80105111:	eb 18                	jmp    8010512b <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
80105113:	8b 45 08             	mov    0x8(%ebp),%eax
80105116:	0f b6 00             	movzbl (%eax),%eax
80105119:	0f b6 d0             	movzbl %al,%edx
8010511c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010511f:	0f b6 00             	movzbl (%eax),%eax
80105122:	0f b6 c0             	movzbl %al,%eax
80105125:	89 d1                	mov    %edx,%ecx
80105127:	29 c1                	sub    %eax,%ecx
80105129:	89 c8                	mov    %ecx,%eax
}
8010512b:	5d                   	pop    %ebp
8010512c:	c3                   	ret    

8010512d <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
8010512d:	55                   	push   %ebp
8010512e:	89 e5                	mov    %esp,%ebp
80105130:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105133:	8b 45 08             	mov    0x8(%ebp),%eax
80105136:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105139:	90                   	nop
8010513a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010513e:	0f 9f c0             	setg   %al
80105141:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105145:	84 c0                	test   %al,%al
80105147:	74 30                	je     80105179 <strncpy+0x4c>
80105149:	8b 45 0c             	mov    0xc(%ebp),%eax
8010514c:	0f b6 10             	movzbl (%eax),%edx
8010514f:	8b 45 08             	mov    0x8(%ebp),%eax
80105152:	88 10                	mov    %dl,(%eax)
80105154:	8b 45 08             	mov    0x8(%ebp),%eax
80105157:	0f b6 00             	movzbl (%eax),%eax
8010515a:	84 c0                	test   %al,%al
8010515c:	0f 95 c0             	setne  %al
8010515f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105163:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105167:	84 c0                	test   %al,%al
80105169:	75 cf                	jne    8010513a <strncpy+0xd>
    ;
  while(n-- > 0)
8010516b:	eb 0c                	jmp    80105179 <strncpy+0x4c>
    *s++ = 0;
8010516d:	8b 45 08             	mov    0x8(%ebp),%eax
80105170:	c6 00 00             	movb   $0x0,(%eax)
80105173:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105177:	eb 01                	jmp    8010517a <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105179:	90                   	nop
8010517a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010517e:	0f 9f c0             	setg   %al
80105181:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105185:	84 c0                	test   %al,%al
80105187:	75 e4                	jne    8010516d <strncpy+0x40>
    *s++ = 0;
  return os;
80105189:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010518c:	c9                   	leave  
8010518d:	c3                   	ret    

8010518e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010518e:	55                   	push   %ebp
8010518f:	89 e5                	mov    %esp,%ebp
80105191:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105194:	8b 45 08             	mov    0x8(%ebp),%eax
80105197:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
8010519a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010519e:	7f 05                	jg     801051a5 <safestrcpy+0x17>
    return os;
801051a0:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051a3:	eb 35                	jmp    801051da <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
801051a5:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801051a9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801051ad:	7e 22                	jle    801051d1 <safestrcpy+0x43>
801051af:	8b 45 0c             	mov    0xc(%ebp),%eax
801051b2:	0f b6 10             	movzbl (%eax),%edx
801051b5:	8b 45 08             	mov    0x8(%ebp),%eax
801051b8:	88 10                	mov    %dl,(%eax)
801051ba:	8b 45 08             	mov    0x8(%ebp),%eax
801051bd:	0f b6 00             	movzbl (%eax),%eax
801051c0:	84 c0                	test   %al,%al
801051c2:	0f 95 c0             	setne  %al
801051c5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801051c9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801051cd:	84 c0                	test   %al,%al
801051cf:	75 d4                	jne    801051a5 <safestrcpy+0x17>
    ;
  *s = 0;
801051d1:	8b 45 08             	mov    0x8(%ebp),%eax
801051d4:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801051d7:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801051da:	c9                   	leave  
801051db:	c3                   	ret    

801051dc <strlen>:

int
strlen(const char *s)
{
801051dc:	55                   	push   %ebp
801051dd:	89 e5                	mov    %esp,%ebp
801051df:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
801051e2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801051e9:	eb 04                	jmp    801051ef <strlen+0x13>
801051eb:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801051ef:	8b 55 fc             	mov    -0x4(%ebp),%edx
801051f2:	8b 45 08             	mov    0x8(%ebp),%eax
801051f5:	01 d0                	add    %edx,%eax
801051f7:	0f b6 00             	movzbl (%eax),%eax
801051fa:	84 c0                	test   %al,%al
801051fc:	75 ed                	jne    801051eb <strlen+0xf>
    ;
  return n;
801051fe:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105201:	c9                   	leave  
80105202:	c3                   	ret    
80105203:	90                   	nop

80105204 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105204:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105208:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
8010520c:	55                   	push   %ebp
  pushl %ebx
8010520d:	53                   	push   %ebx
  pushl %esi
8010520e:	56                   	push   %esi
  pushl %edi
8010520f:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105210:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105212:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105214:	5f                   	pop    %edi
  popl %esi
80105215:	5e                   	pop    %esi
  popl %ebx
80105216:	5b                   	pop    %ebx
  popl %ebp
80105217:	5d                   	pop    %ebp
  ret
80105218:	c3                   	ret    
80105219:	66 90                	xchg   %ax,%ax
8010521b:	90                   	nop

8010521c <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
8010521c:	55                   	push   %ebp
8010521d:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
8010521f:	8b 45 08             	mov    0x8(%ebp),%eax
80105222:	8b 00                	mov    (%eax),%eax
80105224:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105227:	76 0f                	jbe    80105238 <fetchint+0x1c>
80105229:	8b 45 0c             	mov    0xc(%ebp),%eax
8010522c:	8d 50 04             	lea    0x4(%eax),%edx
8010522f:	8b 45 08             	mov    0x8(%ebp),%eax
80105232:	8b 00                	mov    (%eax),%eax
80105234:	39 c2                	cmp    %eax,%edx
80105236:	76 07                	jbe    8010523f <fetchint+0x23>
    return -1;
80105238:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010523d:	eb 0f                	jmp    8010524e <fetchint+0x32>
  *ip = *(int*)(addr);
8010523f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105242:	8b 10                	mov    (%eax),%edx
80105244:	8b 45 10             	mov    0x10(%ebp),%eax
80105247:	89 10                	mov    %edx,(%eax)
  return 0;
80105249:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010524e:	5d                   	pop    %ebp
8010524f:	c3                   	ret    

80105250 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
80105250:	55                   	push   %ebp
80105251:	89 e5                	mov    %esp,%ebp
80105253:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
80105256:	8b 45 08             	mov    0x8(%ebp),%eax
80105259:	8b 00                	mov    (%eax),%eax
8010525b:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010525e:	77 07                	ja     80105267 <fetchstr+0x17>
    return -1;
80105260:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105265:	eb 45                	jmp    801052ac <fetchstr+0x5c>
  *pp = (char*)addr;
80105267:	8b 55 0c             	mov    0xc(%ebp),%edx
8010526a:	8b 45 10             	mov    0x10(%ebp),%eax
8010526d:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
8010526f:	8b 45 08             	mov    0x8(%ebp),%eax
80105272:	8b 00                	mov    (%eax),%eax
80105274:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105277:	8b 45 10             	mov    0x10(%ebp),%eax
8010527a:	8b 00                	mov    (%eax),%eax
8010527c:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010527f:	eb 1e                	jmp    8010529f <fetchstr+0x4f>
    if(*s == 0)
80105281:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105284:	0f b6 00             	movzbl (%eax),%eax
80105287:	84 c0                	test   %al,%al
80105289:	75 10                	jne    8010529b <fetchstr+0x4b>
      return s - *pp;
8010528b:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010528e:	8b 45 10             	mov    0x10(%ebp),%eax
80105291:	8b 00                	mov    (%eax),%eax
80105293:	89 d1                	mov    %edx,%ecx
80105295:	29 c1                	sub    %eax,%ecx
80105297:	89 c8                	mov    %ecx,%eax
80105299:	eb 11                	jmp    801052ac <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
8010529b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010529f:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052a2:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801052a5:	72 da                	jb     80105281 <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
801052a7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801052ac:	c9                   	leave  
801052ad:	c3                   	ret    

801052ae <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801052ae:	55                   	push   %ebp
801052af:	89 e5                	mov    %esp,%ebp
801052b1:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
801052b4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052ba:	8b 40 18             	mov    0x18(%eax),%eax
801052bd:	8b 50 44             	mov    0x44(%eax),%edx
801052c0:	8b 45 08             	mov    0x8(%ebp),%eax
801052c3:	c1 e0 02             	shl    $0x2,%eax
801052c6:	01 d0                	add    %edx,%eax
801052c8:	8d 48 04             	lea    0x4(%eax),%ecx
801052cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052d1:	8b 55 0c             	mov    0xc(%ebp),%edx
801052d4:	89 54 24 08          	mov    %edx,0x8(%esp)
801052d8:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801052dc:	89 04 24             	mov    %eax,(%esp)
801052df:	e8 38 ff ff ff       	call   8010521c <fetchint>
}
801052e4:	c9                   	leave  
801052e5:	c3                   	ret    

801052e6 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801052e6:	55                   	push   %ebp
801052e7:	89 e5                	mov    %esp,%ebp
801052e9:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
801052ec:	8d 45 fc             	lea    -0x4(%ebp),%eax
801052ef:	89 44 24 04          	mov    %eax,0x4(%esp)
801052f3:	8b 45 08             	mov    0x8(%ebp),%eax
801052f6:	89 04 24             	mov    %eax,(%esp)
801052f9:	e8 b0 ff ff ff       	call   801052ae <argint>
801052fe:	85 c0                	test   %eax,%eax
80105300:	79 07                	jns    80105309 <argptr+0x23>
    return -1;
80105302:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105307:	eb 3d                	jmp    80105346 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105309:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010530c:	89 c2                	mov    %eax,%edx
8010530e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105314:	8b 00                	mov    (%eax),%eax
80105316:	39 c2                	cmp    %eax,%edx
80105318:	73 16                	jae    80105330 <argptr+0x4a>
8010531a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010531d:	89 c2                	mov    %eax,%edx
8010531f:	8b 45 10             	mov    0x10(%ebp),%eax
80105322:	01 c2                	add    %eax,%edx
80105324:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010532a:	8b 00                	mov    (%eax),%eax
8010532c:	39 c2                	cmp    %eax,%edx
8010532e:	76 07                	jbe    80105337 <argptr+0x51>
    return -1;
80105330:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105335:	eb 0f                	jmp    80105346 <argptr+0x60>
  *pp = (char*)i;
80105337:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010533a:	89 c2                	mov    %eax,%edx
8010533c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010533f:	89 10                	mov    %edx,(%eax)
  return 0;
80105341:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105346:	c9                   	leave  
80105347:	c3                   	ret    

80105348 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105348:	55                   	push   %ebp
80105349:	89 e5                	mov    %esp,%ebp
8010534b:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010534e:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105351:	89 44 24 04          	mov    %eax,0x4(%esp)
80105355:	8b 45 08             	mov    0x8(%ebp),%eax
80105358:	89 04 24             	mov    %eax,(%esp)
8010535b:	e8 4e ff ff ff       	call   801052ae <argint>
80105360:	85 c0                	test   %eax,%eax
80105362:	79 07                	jns    8010536b <argstr+0x23>
    return -1;
80105364:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105369:	eb 1e                	jmp    80105389 <argstr+0x41>
  return fetchstr(proc, addr, pp);
8010536b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010536e:	89 c2                	mov    %eax,%edx
80105370:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105376:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105379:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010537d:	89 54 24 04          	mov    %edx,0x4(%esp)
80105381:	89 04 24             	mov    %eax,(%esp)
80105384:	e8 c7 fe ff ff       	call   80105250 <fetchstr>
}
80105389:	c9                   	leave  
8010538a:	c3                   	ret    

8010538b <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
8010538b:	55                   	push   %ebp
8010538c:	89 e5                	mov    %esp,%ebp
8010538e:	53                   	push   %ebx
8010538f:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105392:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105398:	8b 40 18             	mov    0x18(%eax),%eax
8010539b:	8b 40 1c             	mov    0x1c(%eax),%eax
8010539e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
801053a1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801053a5:	78 2e                	js     801053d5 <syscall+0x4a>
801053a7:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801053ab:	7f 28                	jg     801053d5 <syscall+0x4a>
801053ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053b0:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801053b7:	85 c0                	test   %eax,%eax
801053b9:	74 1a                	je     801053d5 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
801053bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053c1:	8b 58 18             	mov    0x18(%eax),%ebx
801053c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053c7:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801053ce:	ff d0                	call   *%eax
801053d0:	89 43 1c             	mov    %eax,0x1c(%ebx)
801053d3:	eb 73                	jmp    80105448 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
801053d5:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801053d9:	7e 30                	jle    8010540b <syscall+0x80>
801053db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053de:	83 f8 15             	cmp    $0x15,%eax
801053e1:	77 28                	ja     8010540b <syscall+0x80>
801053e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053e6:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801053ed:	85 c0                	test   %eax,%eax
801053ef:	74 1a                	je     8010540b <syscall+0x80>
    proc->tf->eax = syscalls[num]();
801053f1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053f7:	8b 58 18             	mov    0x18(%eax),%ebx
801053fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053fd:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105404:	ff d0                	call   *%eax
80105406:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105409:	eb 3d                	jmp    80105448 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
8010540b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105411:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105414:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
8010541a:	8b 40 10             	mov    0x10(%eax),%eax
8010541d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105420:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105424:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105428:	89 44 24 04          	mov    %eax,0x4(%esp)
8010542c:	c7 04 24 03 87 10 80 	movl   $0x80108703,(%esp)
80105433:	e8 72 af ff ff       	call   801003aa <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105438:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010543e:	8b 40 18             	mov    0x18(%eax),%eax
80105441:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105448:	83 c4 24             	add    $0x24,%esp
8010544b:	5b                   	pop    %ebx
8010544c:	5d                   	pop    %ebp
8010544d:	c3                   	ret    
8010544e:	66 90                	xchg   %ax,%ax

80105450 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105450:	55                   	push   %ebp
80105451:	89 e5                	mov    %esp,%ebp
80105453:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105456:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105459:	89 44 24 04          	mov    %eax,0x4(%esp)
8010545d:	8b 45 08             	mov    0x8(%ebp),%eax
80105460:	89 04 24             	mov    %eax,(%esp)
80105463:	e8 46 fe ff ff       	call   801052ae <argint>
80105468:	85 c0                	test   %eax,%eax
8010546a:	79 07                	jns    80105473 <argfd+0x23>
    return -1;
8010546c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105471:	eb 50                	jmp    801054c3 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105473:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105476:	85 c0                	test   %eax,%eax
80105478:	78 21                	js     8010549b <argfd+0x4b>
8010547a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010547d:	83 f8 0f             	cmp    $0xf,%eax
80105480:	7f 19                	jg     8010549b <argfd+0x4b>
80105482:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105488:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010548b:	83 c2 08             	add    $0x8,%edx
8010548e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105492:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105495:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105499:	75 07                	jne    801054a2 <argfd+0x52>
    return -1;
8010549b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054a0:	eb 21                	jmp    801054c3 <argfd+0x73>
  if(pfd)
801054a2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801054a6:	74 08                	je     801054b0 <argfd+0x60>
    *pfd = fd;
801054a8:	8b 55 f0             	mov    -0x10(%ebp),%edx
801054ab:	8b 45 0c             	mov    0xc(%ebp),%eax
801054ae:	89 10                	mov    %edx,(%eax)
  if(pf)
801054b0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801054b4:	74 08                	je     801054be <argfd+0x6e>
    *pf = f;
801054b6:	8b 45 10             	mov    0x10(%ebp),%eax
801054b9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801054bc:	89 10                	mov    %edx,(%eax)
  return 0;
801054be:	b8 00 00 00 00       	mov    $0x0,%eax
}
801054c3:	c9                   	leave  
801054c4:	c3                   	ret    

801054c5 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801054c5:	55                   	push   %ebp
801054c6:	89 e5                	mov    %esp,%ebp
801054c8:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801054cb:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801054d2:	eb 30                	jmp    80105504 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
801054d4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054da:	8b 55 fc             	mov    -0x4(%ebp),%edx
801054dd:	83 c2 08             	add    $0x8,%edx
801054e0:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801054e4:	85 c0                	test   %eax,%eax
801054e6:	75 18                	jne    80105500 <fdalloc+0x3b>
      proc->ofile[fd] = f;
801054e8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054ee:	8b 55 fc             	mov    -0x4(%ebp),%edx
801054f1:	8d 4a 08             	lea    0x8(%edx),%ecx
801054f4:	8b 55 08             	mov    0x8(%ebp),%edx
801054f7:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
801054fb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801054fe:	eb 0f                	jmp    8010550f <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105500:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105504:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105508:	7e ca                	jle    801054d4 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
8010550a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010550f:	c9                   	leave  
80105510:	c3                   	ret    

80105511 <sys_dup>:

int
sys_dup(void)
{
80105511:	55                   	push   %ebp
80105512:	89 e5                	mov    %esp,%ebp
80105514:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105517:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010551a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010551e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105525:	00 
80105526:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010552d:	e8 1e ff ff ff       	call   80105450 <argfd>
80105532:	85 c0                	test   %eax,%eax
80105534:	79 07                	jns    8010553d <sys_dup+0x2c>
    return -1;
80105536:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010553b:	eb 29                	jmp    80105566 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
8010553d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105540:	89 04 24             	mov    %eax,(%esp)
80105543:	e8 7d ff ff ff       	call   801054c5 <fdalloc>
80105548:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010554b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010554f:	79 07                	jns    80105558 <sys_dup+0x47>
    return -1;
80105551:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105556:	eb 0e                	jmp    80105566 <sys_dup+0x55>
  filedup(f);
80105558:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010555b:	89 04 24             	mov    %eax,(%esp)
8010555e:	e8 3d bb ff ff       	call   801010a0 <filedup>
  return fd;
80105563:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105566:	c9                   	leave  
80105567:	c3                   	ret    

80105568 <sys_read>:

int
sys_read(void)
{
80105568:	55                   	push   %ebp
80105569:	89 e5                	mov    %esp,%ebp
8010556b:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010556e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105571:	89 44 24 08          	mov    %eax,0x8(%esp)
80105575:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010557c:	00 
8010557d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105584:	e8 c7 fe ff ff       	call   80105450 <argfd>
80105589:	85 c0                	test   %eax,%eax
8010558b:	78 35                	js     801055c2 <sys_read+0x5a>
8010558d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105590:	89 44 24 04          	mov    %eax,0x4(%esp)
80105594:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010559b:	e8 0e fd ff ff       	call   801052ae <argint>
801055a0:	85 c0                	test   %eax,%eax
801055a2:	78 1e                	js     801055c2 <sys_read+0x5a>
801055a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055a7:	89 44 24 08          	mov    %eax,0x8(%esp)
801055ab:	8d 45 ec             	lea    -0x14(%ebp),%eax
801055ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801055b2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801055b9:	e8 28 fd ff ff       	call   801052e6 <argptr>
801055be:	85 c0                	test   %eax,%eax
801055c0:	79 07                	jns    801055c9 <sys_read+0x61>
    return -1;
801055c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055c7:	eb 19                	jmp    801055e2 <sys_read+0x7a>
  return fileread(f, p, n);
801055c9:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801055cc:	8b 55 ec             	mov    -0x14(%ebp),%edx
801055cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055d2:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801055d6:	89 54 24 04          	mov    %edx,0x4(%esp)
801055da:	89 04 24             	mov    %eax,(%esp)
801055dd:	e8 2b bc ff ff       	call   8010120d <fileread>
}
801055e2:	c9                   	leave  
801055e3:	c3                   	ret    

801055e4 <sys_write>:

int
sys_write(void)
{
801055e4:	55                   	push   %ebp
801055e5:	89 e5                	mov    %esp,%ebp
801055e7:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801055ea:	8d 45 f4             	lea    -0xc(%ebp),%eax
801055ed:	89 44 24 08          	mov    %eax,0x8(%esp)
801055f1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801055f8:	00 
801055f9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105600:	e8 4b fe ff ff       	call   80105450 <argfd>
80105605:	85 c0                	test   %eax,%eax
80105607:	78 35                	js     8010563e <sys_write+0x5a>
80105609:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010560c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105610:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105617:	e8 92 fc ff ff       	call   801052ae <argint>
8010561c:	85 c0                	test   %eax,%eax
8010561e:	78 1e                	js     8010563e <sys_write+0x5a>
80105620:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105623:	89 44 24 08          	mov    %eax,0x8(%esp)
80105627:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010562a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010562e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105635:	e8 ac fc ff ff       	call   801052e6 <argptr>
8010563a:	85 c0                	test   %eax,%eax
8010563c:	79 07                	jns    80105645 <sys_write+0x61>
    return -1;
8010563e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105643:	eb 19                	jmp    8010565e <sys_write+0x7a>
  return filewrite(f, p, n);
80105645:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105648:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010564b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010564e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105652:	89 54 24 04          	mov    %edx,0x4(%esp)
80105656:	89 04 24             	mov    %eax,(%esp)
80105659:	e8 6b bc ff ff       	call   801012c9 <filewrite>
}
8010565e:	c9                   	leave  
8010565f:	c3                   	ret    

80105660 <sys_close>:

int
sys_close(void)
{
80105660:	55                   	push   %ebp
80105661:	89 e5                	mov    %esp,%ebp
80105663:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80105666:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105669:	89 44 24 08          	mov    %eax,0x8(%esp)
8010566d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105670:	89 44 24 04          	mov    %eax,0x4(%esp)
80105674:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010567b:	e8 d0 fd ff ff       	call   80105450 <argfd>
80105680:	85 c0                	test   %eax,%eax
80105682:	79 07                	jns    8010568b <sys_close+0x2b>
    return -1;
80105684:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105689:	eb 24                	jmp    801056af <sys_close+0x4f>
  proc->ofile[fd] = 0;
8010568b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105691:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105694:	83 c2 08             	add    $0x8,%edx
80105697:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010569e:	00 
  fileclose(f);
8010569f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056a2:	89 04 24             	mov    %eax,(%esp)
801056a5:	e8 3e ba ff ff       	call   801010e8 <fileclose>
  return 0;
801056aa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801056af:	c9                   	leave  
801056b0:	c3                   	ret    

801056b1 <sys_fstat>:

int
sys_fstat(void)
{
801056b1:	55                   	push   %ebp
801056b2:	89 e5                	mov    %esp,%ebp
801056b4:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801056b7:	8d 45 f4             	lea    -0xc(%ebp),%eax
801056ba:	89 44 24 08          	mov    %eax,0x8(%esp)
801056be:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801056c5:	00 
801056c6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801056cd:	e8 7e fd ff ff       	call   80105450 <argfd>
801056d2:	85 c0                	test   %eax,%eax
801056d4:	78 1f                	js     801056f5 <sys_fstat+0x44>
801056d6:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801056dd:	00 
801056de:	8d 45 f0             	lea    -0x10(%ebp),%eax
801056e1:	89 44 24 04          	mov    %eax,0x4(%esp)
801056e5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801056ec:	e8 f5 fb ff ff       	call   801052e6 <argptr>
801056f1:	85 c0                	test   %eax,%eax
801056f3:	79 07                	jns    801056fc <sys_fstat+0x4b>
    return -1;
801056f5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056fa:	eb 12                	jmp    8010570e <sys_fstat+0x5d>
  return filestat(f, st);
801056fc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801056ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105702:	89 54 24 04          	mov    %edx,0x4(%esp)
80105706:	89 04 24             	mov    %eax,(%esp)
80105709:	e8 b0 ba ff ff       	call   801011be <filestat>
}
8010570e:	c9                   	leave  
8010570f:	c3                   	ret    

80105710 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80105710:	55                   	push   %ebp
80105711:	89 e5                	mov    %esp,%ebp
80105713:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80105716:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105719:	89 44 24 04          	mov    %eax,0x4(%esp)
8010571d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105724:	e8 1f fc ff ff       	call   80105348 <argstr>
80105729:	85 c0                	test   %eax,%eax
8010572b:	78 17                	js     80105744 <sys_link+0x34>
8010572d:	8d 45 dc             	lea    -0x24(%ebp),%eax
80105730:	89 44 24 04          	mov    %eax,0x4(%esp)
80105734:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010573b:	e8 08 fc ff ff       	call   80105348 <argstr>
80105740:	85 c0                	test   %eax,%eax
80105742:	79 0a                	jns    8010574e <sys_link+0x3e>
    return -1;
80105744:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105749:	e9 3c 01 00 00       	jmp    8010588a <sys_link+0x17a>
  if((ip = namei(old)) == 0)
8010574e:	8b 45 d8             	mov    -0x28(%ebp),%eax
80105751:	89 04 24             	mov    %eax,(%esp)
80105754:	e8 f8 cd ff ff       	call   80102551 <namei>
80105759:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010575c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105760:	75 0a                	jne    8010576c <sys_link+0x5c>
    return -1;
80105762:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105767:	e9 1e 01 00 00       	jmp    8010588a <sys_link+0x17a>

  begin_trans();
8010576c:	e8 fb db ff ff       	call   8010336c <begin_trans>

  ilock(ip);
80105771:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105774:	89 04 24             	mov    %eax,(%esp)
80105777:	e8 14 c2 ff ff       	call   80101990 <ilock>
  if(ip->type == T_DIR){
8010577c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010577f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105783:	66 83 f8 01          	cmp    $0x1,%ax
80105787:	75 1a                	jne    801057a3 <sys_link+0x93>
    iunlockput(ip);
80105789:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010578c:	89 04 24             	mov    %eax,(%esp)
8010578f:	e8 80 c4 ff ff       	call   80101c14 <iunlockput>
    commit_trans();
80105794:	e8 1c dc ff ff       	call   801033b5 <commit_trans>
    return -1;
80105799:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010579e:	e9 e7 00 00 00       	jmp    8010588a <sys_link+0x17a>
  }

  ip->nlink++;
801057a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057a6:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801057aa:	8d 50 01             	lea    0x1(%eax),%edx
801057ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057b0:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801057b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057b7:	89 04 24             	mov    %eax,(%esp)
801057ba:	e8 15 c0 ff ff       	call   801017d4 <iupdate>
  iunlock(ip);
801057bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057c2:	89 04 24             	mov    %eax,(%esp)
801057c5:	e8 14 c3 ff ff       	call   80101ade <iunlock>

  if((dp = nameiparent(new, name)) == 0)
801057ca:	8b 45 dc             	mov    -0x24(%ebp),%eax
801057cd:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801057d0:	89 54 24 04          	mov    %edx,0x4(%esp)
801057d4:	89 04 24             	mov    %eax,(%esp)
801057d7:	e8 97 cd ff ff       	call   80102573 <nameiparent>
801057dc:	89 45 f0             	mov    %eax,-0x10(%ebp)
801057df:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801057e3:	74 68                	je     8010584d <sys_link+0x13d>
    goto bad;
  ilock(dp);
801057e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057e8:	89 04 24             	mov    %eax,(%esp)
801057eb:	e8 a0 c1 ff ff       	call   80101990 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801057f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057f3:	8b 10                	mov    (%eax),%edx
801057f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057f8:	8b 00                	mov    (%eax),%eax
801057fa:	39 c2                	cmp    %eax,%edx
801057fc:	75 20                	jne    8010581e <sys_link+0x10e>
801057fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105801:	8b 40 04             	mov    0x4(%eax),%eax
80105804:	89 44 24 08          	mov    %eax,0x8(%esp)
80105808:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010580b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010580f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105812:	89 04 24             	mov    %eax,(%esp)
80105815:	e8 74 ca ff ff       	call   8010228e <dirlink>
8010581a:	85 c0                	test   %eax,%eax
8010581c:	79 0d                	jns    8010582b <sys_link+0x11b>
    iunlockput(dp);
8010581e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105821:	89 04 24             	mov    %eax,(%esp)
80105824:	e8 eb c3 ff ff       	call   80101c14 <iunlockput>
    goto bad;
80105829:	eb 23                	jmp    8010584e <sys_link+0x13e>
  }
  iunlockput(dp);
8010582b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010582e:	89 04 24             	mov    %eax,(%esp)
80105831:	e8 de c3 ff ff       	call   80101c14 <iunlockput>
  iput(ip);
80105836:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105839:	89 04 24             	mov    %eax,(%esp)
8010583c:	e8 02 c3 ff ff       	call   80101b43 <iput>

  commit_trans();
80105841:	e8 6f db ff ff       	call   801033b5 <commit_trans>

  return 0;
80105846:	b8 00 00 00 00       	mov    $0x0,%eax
8010584b:	eb 3d                	jmp    8010588a <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
8010584d:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
8010584e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105851:	89 04 24             	mov    %eax,(%esp)
80105854:	e8 37 c1 ff ff       	call   80101990 <ilock>
  ip->nlink--;
80105859:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010585c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105860:	8d 50 ff             	lea    -0x1(%eax),%edx
80105863:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105866:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010586a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010586d:	89 04 24             	mov    %eax,(%esp)
80105870:	e8 5f bf ff ff       	call   801017d4 <iupdate>
  iunlockput(ip);
80105875:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105878:	89 04 24             	mov    %eax,(%esp)
8010587b:	e8 94 c3 ff ff       	call   80101c14 <iunlockput>
  commit_trans();
80105880:	e8 30 db ff ff       	call   801033b5 <commit_trans>
  return -1;
80105885:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010588a:	c9                   	leave  
8010588b:	c3                   	ret    

8010588c <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
8010588c:	55                   	push   %ebp
8010588d:	89 e5                	mov    %esp,%ebp
8010588f:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105892:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105899:	eb 4b                	jmp    801058e6 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010589b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010589e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801058a5:	00 
801058a6:	89 44 24 08          	mov    %eax,0x8(%esp)
801058aa:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801058ad:	89 44 24 04          	mov    %eax,0x4(%esp)
801058b1:	8b 45 08             	mov    0x8(%ebp),%eax
801058b4:	89 04 24             	mov    %eax,(%esp)
801058b7:	e8 e1 c5 ff ff       	call   80101e9d <readi>
801058bc:	83 f8 10             	cmp    $0x10,%eax
801058bf:	74 0c                	je     801058cd <isdirempty+0x41>
      panic("isdirempty: readi");
801058c1:	c7 04 24 1f 87 10 80 	movl   $0x8010871f,(%esp)
801058c8:	e8 79 ac ff ff       	call   80100546 <panic>
    if(de.inum != 0)
801058cd:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
801058d1:	66 85 c0             	test   %ax,%ax
801058d4:	74 07                	je     801058dd <isdirempty+0x51>
      return 0;
801058d6:	b8 00 00 00 00       	mov    $0x0,%eax
801058db:	eb 1b                	jmp    801058f8 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801058dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058e0:	83 c0 10             	add    $0x10,%eax
801058e3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801058e6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801058e9:	8b 45 08             	mov    0x8(%ebp),%eax
801058ec:	8b 40 18             	mov    0x18(%eax),%eax
801058ef:	39 c2                	cmp    %eax,%edx
801058f1:	72 a8                	jb     8010589b <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
801058f3:	b8 01 00 00 00       	mov    $0x1,%eax
}
801058f8:	c9                   	leave  
801058f9:	c3                   	ret    

801058fa <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
801058fa:	55                   	push   %ebp
801058fb:	89 e5                	mov    %esp,%ebp
801058fd:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105900:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105903:	89 44 24 04          	mov    %eax,0x4(%esp)
80105907:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010590e:	e8 35 fa ff ff       	call   80105348 <argstr>
80105913:	85 c0                	test   %eax,%eax
80105915:	79 0a                	jns    80105921 <sys_unlink+0x27>
    return -1;
80105917:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010591c:	e9 aa 01 00 00       	jmp    80105acb <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80105921:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105924:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105927:	89 54 24 04          	mov    %edx,0x4(%esp)
8010592b:	89 04 24             	mov    %eax,(%esp)
8010592e:	e8 40 cc ff ff       	call   80102573 <nameiparent>
80105933:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105936:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010593a:	75 0a                	jne    80105946 <sys_unlink+0x4c>
    return -1;
8010593c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105941:	e9 85 01 00 00       	jmp    80105acb <sys_unlink+0x1d1>

  begin_trans();
80105946:	e8 21 da ff ff       	call   8010336c <begin_trans>

  ilock(dp);
8010594b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010594e:	89 04 24             	mov    %eax,(%esp)
80105951:	e8 3a c0 ff ff       	call   80101990 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105956:	c7 44 24 04 31 87 10 	movl   $0x80108731,0x4(%esp)
8010595d:	80 
8010595e:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105961:	89 04 24             	mov    %eax,(%esp)
80105964:	e8 3b c8 ff ff       	call   801021a4 <namecmp>
80105969:	85 c0                	test   %eax,%eax
8010596b:	0f 84 45 01 00 00    	je     80105ab6 <sys_unlink+0x1bc>
80105971:	c7 44 24 04 33 87 10 	movl   $0x80108733,0x4(%esp)
80105978:	80 
80105979:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010597c:	89 04 24             	mov    %eax,(%esp)
8010597f:	e8 20 c8 ff ff       	call   801021a4 <namecmp>
80105984:	85 c0                	test   %eax,%eax
80105986:	0f 84 2a 01 00 00    	je     80105ab6 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
8010598c:	8d 45 c8             	lea    -0x38(%ebp),%eax
8010598f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105993:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105996:	89 44 24 04          	mov    %eax,0x4(%esp)
8010599a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010599d:	89 04 24             	mov    %eax,(%esp)
801059a0:	e8 21 c8 ff ff       	call   801021c6 <dirlookup>
801059a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
801059a8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801059ac:	0f 84 03 01 00 00    	je     80105ab5 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
801059b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059b5:	89 04 24             	mov    %eax,(%esp)
801059b8:	e8 d3 bf ff ff       	call   80101990 <ilock>

  if(ip->nlink < 1)
801059bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059c0:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801059c4:	66 85 c0             	test   %ax,%ax
801059c7:	7f 0c                	jg     801059d5 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
801059c9:	c7 04 24 36 87 10 80 	movl   $0x80108736,(%esp)
801059d0:	e8 71 ab ff ff       	call   80100546 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801059d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059d8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801059dc:	66 83 f8 01          	cmp    $0x1,%ax
801059e0:	75 1f                	jne    80105a01 <sys_unlink+0x107>
801059e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059e5:	89 04 24             	mov    %eax,(%esp)
801059e8:	e8 9f fe ff ff       	call   8010588c <isdirempty>
801059ed:	85 c0                	test   %eax,%eax
801059ef:	75 10                	jne    80105a01 <sys_unlink+0x107>
    iunlockput(ip);
801059f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059f4:	89 04 24             	mov    %eax,(%esp)
801059f7:	e8 18 c2 ff ff       	call   80101c14 <iunlockput>
    goto bad;
801059fc:	e9 b5 00 00 00       	jmp    80105ab6 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80105a01:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105a08:	00 
80105a09:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105a10:	00 
80105a11:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105a14:	89 04 24             	mov    %eax,(%esp)
80105a17:	e8 42 f5 ff ff       	call   80104f5e <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105a1c:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105a1f:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105a26:	00 
80105a27:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a2b:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105a2e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a35:	89 04 24             	mov    %eax,(%esp)
80105a38:	e8 ce c5 ff ff       	call   8010200b <writei>
80105a3d:	83 f8 10             	cmp    $0x10,%eax
80105a40:	74 0c                	je     80105a4e <sys_unlink+0x154>
    panic("unlink: writei");
80105a42:	c7 04 24 48 87 10 80 	movl   $0x80108748,(%esp)
80105a49:	e8 f8 aa ff ff       	call   80100546 <panic>
  if(ip->type == T_DIR){
80105a4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a51:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105a55:	66 83 f8 01          	cmp    $0x1,%ax
80105a59:	75 1c                	jne    80105a77 <sys_unlink+0x17d>
    dp->nlink--;
80105a5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a5e:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105a62:	8d 50 ff             	lea    -0x1(%eax),%edx
80105a65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a68:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105a6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a6f:	89 04 24             	mov    %eax,(%esp)
80105a72:	e8 5d bd ff ff       	call   801017d4 <iupdate>
  }
  iunlockput(dp);
80105a77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a7a:	89 04 24             	mov    %eax,(%esp)
80105a7d:	e8 92 c1 ff ff       	call   80101c14 <iunlockput>

  ip->nlink--;
80105a82:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a85:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105a89:	8d 50 ff             	lea    -0x1(%eax),%edx
80105a8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a8f:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105a93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a96:	89 04 24             	mov    %eax,(%esp)
80105a99:	e8 36 bd ff ff       	call   801017d4 <iupdate>
  iunlockput(ip);
80105a9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105aa1:	89 04 24             	mov    %eax,(%esp)
80105aa4:	e8 6b c1 ff ff       	call   80101c14 <iunlockput>

  commit_trans();
80105aa9:	e8 07 d9 ff ff       	call   801033b5 <commit_trans>

  return 0;
80105aae:	b8 00 00 00 00       	mov    $0x0,%eax
80105ab3:	eb 16                	jmp    80105acb <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80105ab5:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80105ab6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ab9:	89 04 24             	mov    %eax,(%esp)
80105abc:	e8 53 c1 ff ff       	call   80101c14 <iunlockput>
  commit_trans();
80105ac1:	e8 ef d8 ff ff       	call   801033b5 <commit_trans>
  return -1;
80105ac6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105acb:	c9                   	leave  
80105acc:	c3                   	ret    

80105acd <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105acd:	55                   	push   %ebp
80105ace:	89 e5                	mov    %esp,%ebp
80105ad0:	83 ec 48             	sub    $0x48,%esp
80105ad3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105ad6:	8b 55 10             	mov    0x10(%ebp),%edx
80105ad9:	8b 45 14             	mov    0x14(%ebp),%eax
80105adc:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105ae0:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105ae4:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105ae8:	8d 45 de             	lea    -0x22(%ebp),%eax
80105aeb:	89 44 24 04          	mov    %eax,0x4(%esp)
80105aef:	8b 45 08             	mov    0x8(%ebp),%eax
80105af2:	89 04 24             	mov    %eax,(%esp)
80105af5:	e8 79 ca ff ff       	call   80102573 <nameiparent>
80105afa:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105afd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105b01:	75 0a                	jne    80105b0d <create+0x40>
    return 0;
80105b03:	b8 00 00 00 00       	mov    $0x0,%eax
80105b08:	e9 7e 01 00 00       	jmp    80105c8b <create+0x1be>
  ilock(dp);
80105b0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b10:	89 04 24             	mov    %eax,(%esp)
80105b13:	e8 78 be ff ff       	call   80101990 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80105b18:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105b1b:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b1f:	8d 45 de             	lea    -0x22(%ebp),%eax
80105b22:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b29:	89 04 24             	mov    %eax,(%esp)
80105b2c:	e8 95 c6 ff ff       	call   801021c6 <dirlookup>
80105b31:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105b34:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105b38:	74 47                	je     80105b81 <create+0xb4>
    iunlockput(dp);
80105b3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b3d:	89 04 24             	mov    %eax,(%esp)
80105b40:	e8 cf c0 ff ff       	call   80101c14 <iunlockput>
    ilock(ip);
80105b45:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b48:	89 04 24             	mov    %eax,(%esp)
80105b4b:	e8 40 be ff ff       	call   80101990 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105b50:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105b55:	75 15                	jne    80105b6c <create+0x9f>
80105b57:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b5a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105b5e:	66 83 f8 02          	cmp    $0x2,%ax
80105b62:	75 08                	jne    80105b6c <create+0x9f>
      return ip;
80105b64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b67:	e9 1f 01 00 00       	jmp    80105c8b <create+0x1be>
    iunlockput(ip);
80105b6c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b6f:	89 04 24             	mov    %eax,(%esp)
80105b72:	e8 9d c0 ff ff       	call   80101c14 <iunlockput>
    return 0;
80105b77:	b8 00 00 00 00       	mov    $0x0,%eax
80105b7c:	e9 0a 01 00 00       	jmp    80105c8b <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105b81:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105b85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b88:	8b 00                	mov    (%eax),%eax
80105b8a:	89 54 24 04          	mov    %edx,0x4(%esp)
80105b8e:	89 04 24             	mov    %eax,(%esp)
80105b91:	e8 5f bb ff ff       	call   801016f5 <ialloc>
80105b96:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105b99:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105b9d:	75 0c                	jne    80105bab <create+0xde>
    panic("create: ialloc");
80105b9f:	c7 04 24 57 87 10 80 	movl   $0x80108757,(%esp)
80105ba6:	e8 9b a9 ff ff       	call   80100546 <panic>

  ilock(ip);
80105bab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bae:	89 04 24             	mov    %eax,(%esp)
80105bb1:	e8 da bd ff ff       	call   80101990 <ilock>
  ip->major = major;
80105bb6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bb9:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105bbd:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105bc1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bc4:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105bc8:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105bcc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bcf:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105bd5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bd8:	89 04 24             	mov    %eax,(%esp)
80105bdb:	e8 f4 bb ff ff       	call   801017d4 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105be0:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105be5:	75 6a                	jne    80105c51 <create+0x184>
    dp->nlink++;  // for ".."
80105be7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bea:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105bee:	8d 50 01             	lea    0x1(%eax),%edx
80105bf1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bf4:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105bf8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bfb:	89 04 24             	mov    %eax,(%esp)
80105bfe:	e8 d1 bb ff ff       	call   801017d4 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105c03:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c06:	8b 40 04             	mov    0x4(%eax),%eax
80105c09:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c0d:	c7 44 24 04 31 87 10 	movl   $0x80108731,0x4(%esp)
80105c14:	80 
80105c15:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c18:	89 04 24             	mov    %eax,(%esp)
80105c1b:	e8 6e c6 ff ff       	call   8010228e <dirlink>
80105c20:	85 c0                	test   %eax,%eax
80105c22:	78 21                	js     80105c45 <create+0x178>
80105c24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c27:	8b 40 04             	mov    0x4(%eax),%eax
80105c2a:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c2e:	c7 44 24 04 33 87 10 	movl   $0x80108733,0x4(%esp)
80105c35:	80 
80105c36:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c39:	89 04 24             	mov    %eax,(%esp)
80105c3c:	e8 4d c6 ff ff       	call   8010228e <dirlink>
80105c41:	85 c0                	test   %eax,%eax
80105c43:	79 0c                	jns    80105c51 <create+0x184>
      panic("create dots");
80105c45:	c7 04 24 66 87 10 80 	movl   $0x80108766,(%esp)
80105c4c:	e8 f5 a8 ff ff       	call   80100546 <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105c51:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c54:	8b 40 04             	mov    0x4(%eax),%eax
80105c57:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c5b:	8d 45 de             	lea    -0x22(%ebp),%eax
80105c5e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c62:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c65:	89 04 24             	mov    %eax,(%esp)
80105c68:	e8 21 c6 ff ff       	call   8010228e <dirlink>
80105c6d:	85 c0                	test   %eax,%eax
80105c6f:	79 0c                	jns    80105c7d <create+0x1b0>
    panic("create: dirlink");
80105c71:	c7 04 24 72 87 10 80 	movl   $0x80108772,(%esp)
80105c78:	e8 c9 a8 ff ff       	call   80100546 <panic>

  iunlockput(dp);
80105c7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c80:	89 04 24             	mov    %eax,(%esp)
80105c83:	e8 8c bf ff ff       	call   80101c14 <iunlockput>

  return ip;
80105c88:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105c8b:	c9                   	leave  
80105c8c:	c3                   	ret    

80105c8d <sys_open>:

int
sys_open(void)
{
80105c8d:	55                   	push   %ebp
80105c8e:	89 e5                	mov    %esp,%ebp
80105c90:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105c93:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105c96:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c9a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105ca1:	e8 a2 f6 ff ff       	call   80105348 <argstr>
80105ca6:	85 c0                	test   %eax,%eax
80105ca8:	78 17                	js     80105cc1 <sys_open+0x34>
80105caa:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105cad:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cb1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105cb8:	e8 f1 f5 ff ff       	call   801052ae <argint>
80105cbd:	85 c0                	test   %eax,%eax
80105cbf:	79 0a                	jns    80105ccb <sys_open+0x3e>
    return -1;
80105cc1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cc6:	e9 48 01 00 00       	jmp    80105e13 <sys_open+0x186>
  if(omode & O_CREATE){
80105ccb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105cce:	25 00 02 00 00       	and    $0x200,%eax
80105cd3:	85 c0                	test   %eax,%eax
80105cd5:	74 40                	je     80105d17 <sys_open+0x8a>
    begin_trans();
80105cd7:	e8 90 d6 ff ff       	call   8010336c <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80105cdc:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105cdf:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105ce6:	00 
80105ce7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105cee:	00 
80105cef:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80105cf6:	00 
80105cf7:	89 04 24             	mov    %eax,(%esp)
80105cfa:	e8 ce fd ff ff       	call   80105acd <create>
80105cff:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80105d02:	e8 ae d6 ff ff       	call   801033b5 <commit_trans>
    if(ip == 0)
80105d07:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105d0b:	75 5c                	jne    80105d69 <sys_open+0xdc>
      return -1;
80105d0d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d12:	e9 fc 00 00 00       	jmp    80105e13 <sys_open+0x186>
  } else {
    if((ip = namei(path)) == 0)
80105d17:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105d1a:	89 04 24             	mov    %eax,(%esp)
80105d1d:	e8 2f c8 ff ff       	call   80102551 <namei>
80105d22:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105d25:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105d29:	75 0a                	jne    80105d35 <sys_open+0xa8>
      return -1;
80105d2b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d30:	e9 de 00 00 00       	jmp    80105e13 <sys_open+0x186>
    ilock(ip);
80105d35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d38:	89 04 24             	mov    %eax,(%esp)
80105d3b:	e8 50 bc ff ff       	call   80101990 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80105d40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d43:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105d47:	66 83 f8 01          	cmp    $0x1,%ax
80105d4b:	75 1c                	jne    80105d69 <sys_open+0xdc>
80105d4d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105d50:	85 c0                	test   %eax,%eax
80105d52:	74 15                	je     80105d69 <sys_open+0xdc>
      iunlockput(ip);
80105d54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d57:	89 04 24             	mov    %eax,(%esp)
80105d5a:	e8 b5 be ff ff       	call   80101c14 <iunlockput>
      return -1;
80105d5f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d64:	e9 aa 00 00 00       	jmp    80105e13 <sys_open+0x186>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80105d69:	e8 d2 b2 ff ff       	call   80101040 <filealloc>
80105d6e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105d71:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105d75:	74 14                	je     80105d8b <sys_open+0xfe>
80105d77:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d7a:	89 04 24             	mov    %eax,(%esp)
80105d7d:	e8 43 f7 ff ff       	call   801054c5 <fdalloc>
80105d82:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105d85:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80105d89:	79 23                	jns    80105dae <sys_open+0x121>
    if(f)
80105d8b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105d8f:	74 0b                	je     80105d9c <sys_open+0x10f>
      fileclose(f);
80105d91:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d94:	89 04 24             	mov    %eax,(%esp)
80105d97:	e8 4c b3 ff ff       	call   801010e8 <fileclose>
    iunlockput(ip);
80105d9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d9f:	89 04 24             	mov    %eax,(%esp)
80105da2:	e8 6d be ff ff       	call   80101c14 <iunlockput>
    return -1;
80105da7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105dac:	eb 65                	jmp    80105e13 <sys_open+0x186>
  }
  iunlock(ip);
80105dae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105db1:	89 04 24             	mov    %eax,(%esp)
80105db4:	e8 25 bd ff ff       	call   80101ade <iunlock>

  f->type = FD_INODE;
80105db9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dbc:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80105dc2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dc5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105dc8:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80105dcb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dce:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80105dd5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105dd8:	83 e0 01             	and    $0x1,%eax
80105ddb:	85 c0                	test   %eax,%eax
80105ddd:	0f 94 c0             	sete   %al
80105de0:	89 c2                	mov    %eax,%edx
80105de2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105de5:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80105de8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105deb:	83 e0 01             	and    $0x1,%eax
80105dee:	85 c0                	test   %eax,%eax
80105df0:	75 0a                	jne    80105dfc <sys_open+0x16f>
80105df2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105df5:	83 e0 02             	and    $0x2,%eax
80105df8:	85 c0                	test   %eax,%eax
80105dfa:	74 07                	je     80105e03 <sys_open+0x176>
80105dfc:	b8 01 00 00 00       	mov    $0x1,%eax
80105e01:	eb 05                	jmp    80105e08 <sys_open+0x17b>
80105e03:	b8 00 00 00 00       	mov    $0x0,%eax
80105e08:	89 c2                	mov    %eax,%edx
80105e0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e0d:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80105e10:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80105e13:	c9                   	leave  
80105e14:	c3                   	ret    

80105e15 <sys_mkdir>:

int
sys_mkdir(void)
{
80105e15:	55                   	push   %ebp
80105e16:	89 e5                	mov    %esp,%ebp
80105e18:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80105e1b:	e8 4c d5 ff ff       	call   8010336c <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80105e20:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105e23:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e27:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105e2e:	e8 15 f5 ff ff       	call   80105348 <argstr>
80105e33:	85 c0                	test   %eax,%eax
80105e35:	78 2c                	js     80105e63 <sys_mkdir+0x4e>
80105e37:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e3a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105e41:	00 
80105e42:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105e49:	00 
80105e4a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105e51:	00 
80105e52:	89 04 24             	mov    %eax,(%esp)
80105e55:	e8 73 fc ff ff       	call   80105acd <create>
80105e5a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105e5d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e61:	75 0c                	jne    80105e6f <sys_mkdir+0x5a>
    commit_trans();
80105e63:	e8 4d d5 ff ff       	call   801033b5 <commit_trans>
    return -1;
80105e68:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e6d:	eb 15                	jmp    80105e84 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80105e6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e72:	89 04 24             	mov    %eax,(%esp)
80105e75:	e8 9a bd ff ff       	call   80101c14 <iunlockput>
  commit_trans();
80105e7a:	e8 36 d5 ff ff       	call   801033b5 <commit_trans>
  return 0;
80105e7f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105e84:	c9                   	leave  
80105e85:	c3                   	ret    

80105e86 <sys_mknod>:

int
sys_mknod(void)
{
80105e86:	55                   	push   %ebp
80105e87:	89 e5                	mov    %esp,%ebp
80105e89:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
80105e8c:	e8 db d4 ff ff       	call   8010336c <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
80105e91:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105e94:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e98:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105e9f:	e8 a4 f4 ff ff       	call   80105348 <argstr>
80105ea4:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ea7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105eab:	78 5e                	js     80105f0b <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80105ead:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105eb0:	89 44 24 04          	mov    %eax,0x4(%esp)
80105eb4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105ebb:	e8 ee f3 ff ff       	call   801052ae <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
80105ec0:	85 c0                	test   %eax,%eax
80105ec2:	78 47                	js     80105f0b <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80105ec4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105ec7:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ecb:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105ed2:	e8 d7 f3 ff ff       	call   801052ae <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80105ed7:	85 c0                	test   %eax,%eax
80105ed9:	78 30                	js     80105f0b <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80105edb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105ede:	0f bf c8             	movswl %ax,%ecx
80105ee1:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105ee4:	0f bf d0             	movswl %ax,%edx
80105ee7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80105eea:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80105eee:	89 54 24 08          	mov    %edx,0x8(%esp)
80105ef2:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80105ef9:	00 
80105efa:	89 04 24             	mov    %eax,(%esp)
80105efd:	e8 cb fb ff ff       	call   80105acd <create>
80105f02:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105f05:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105f09:	75 0c                	jne    80105f17 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80105f0b:	e8 a5 d4 ff ff       	call   801033b5 <commit_trans>
    return -1;
80105f10:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f15:	eb 15                	jmp    80105f2c <sys_mknod+0xa6>
  }
  iunlockput(ip);
80105f17:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f1a:	89 04 24             	mov    %eax,(%esp)
80105f1d:	e8 f2 bc ff ff       	call   80101c14 <iunlockput>
  commit_trans();
80105f22:	e8 8e d4 ff ff       	call   801033b5 <commit_trans>
  return 0;
80105f27:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f2c:	c9                   	leave  
80105f2d:	c3                   	ret    

80105f2e <sys_chdir>:

int
sys_chdir(void)
{
80105f2e:	55                   	push   %ebp
80105f2f:	89 e5                	mov    %esp,%ebp
80105f31:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80105f34:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f37:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f3b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f42:	e8 01 f4 ff ff       	call   80105348 <argstr>
80105f47:	85 c0                	test   %eax,%eax
80105f49:	78 14                	js     80105f5f <sys_chdir+0x31>
80105f4b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f4e:	89 04 24             	mov    %eax,(%esp)
80105f51:	e8 fb c5 ff ff       	call   80102551 <namei>
80105f56:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105f59:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f5d:	75 07                	jne    80105f66 <sys_chdir+0x38>
    return -1;
80105f5f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f64:	eb 57                	jmp    80105fbd <sys_chdir+0x8f>
  ilock(ip);
80105f66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f69:	89 04 24             	mov    %eax,(%esp)
80105f6c:	e8 1f ba ff ff       	call   80101990 <ilock>
  if(ip->type != T_DIR){
80105f71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f74:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105f78:	66 83 f8 01          	cmp    $0x1,%ax
80105f7c:	74 12                	je     80105f90 <sys_chdir+0x62>
    iunlockput(ip);
80105f7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f81:	89 04 24             	mov    %eax,(%esp)
80105f84:	e8 8b bc ff ff       	call   80101c14 <iunlockput>
    return -1;
80105f89:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f8e:	eb 2d                	jmp    80105fbd <sys_chdir+0x8f>
  }
  iunlock(ip);
80105f90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f93:	89 04 24             	mov    %eax,(%esp)
80105f96:	e8 43 bb ff ff       	call   80101ade <iunlock>
  iput(proc->cwd);
80105f9b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105fa1:	8b 40 68             	mov    0x68(%eax),%eax
80105fa4:	89 04 24             	mov    %eax,(%esp)
80105fa7:	e8 97 bb ff ff       	call   80101b43 <iput>
  proc->cwd = ip;
80105fac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105fb2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105fb5:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80105fb8:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105fbd:	c9                   	leave  
80105fbe:	c3                   	ret    

80105fbf <sys_exec>:

int
sys_exec(void)
{
80105fbf:	55                   	push   %ebp
80105fc0:	89 e5                	mov    %esp,%ebp
80105fc2:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80105fc8:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105fcb:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fcf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105fd6:	e8 6d f3 ff ff       	call   80105348 <argstr>
80105fdb:	85 c0                	test   %eax,%eax
80105fdd:	78 1a                	js     80105ff9 <sys_exec+0x3a>
80105fdf:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80105fe5:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fe9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105ff0:	e8 b9 f2 ff ff       	call   801052ae <argint>
80105ff5:	85 c0                	test   %eax,%eax
80105ff7:	79 0a                	jns    80106003 <sys_exec+0x44>
    return -1;
80105ff9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ffe:	e9 de 00 00 00       	jmp    801060e1 <sys_exec+0x122>
  }
  memset(argv, 0, sizeof(argv));
80106003:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010600a:	00 
8010600b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106012:	00 
80106013:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106019:	89 04 24             	mov    %eax,(%esp)
8010601c:	e8 3d ef ff ff       	call   80104f5e <memset>
  for(i=0;; i++){
80106021:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106028:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010602b:	83 f8 1f             	cmp    $0x1f,%eax
8010602e:	76 0a                	jbe    8010603a <sys_exec+0x7b>
      return -1;
80106030:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106035:	e9 a7 00 00 00       	jmp    801060e1 <sys_exec+0x122>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
8010603a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010603d:	c1 e0 02             	shl    $0x2,%eax
80106040:	89 c2                	mov    %eax,%edx
80106042:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106048:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
8010604b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106051:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80106057:	89 54 24 08          	mov    %edx,0x8(%esp)
8010605b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
8010605f:	89 04 24             	mov    %eax,(%esp)
80106062:	e8 b5 f1 ff ff       	call   8010521c <fetchint>
80106067:	85 c0                	test   %eax,%eax
80106069:	79 07                	jns    80106072 <sys_exec+0xb3>
      return -1;
8010606b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106070:	eb 6f                	jmp    801060e1 <sys_exec+0x122>
    if(uarg == 0){
80106072:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106078:	85 c0                	test   %eax,%eax
8010607a:	75 26                	jne    801060a2 <sys_exec+0xe3>
      argv[i] = 0;
8010607c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010607f:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106086:	00 00 00 00 
      break;
8010608a:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
8010608b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010608e:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106094:	89 54 24 04          	mov    %edx,0x4(%esp)
80106098:	89 04 24             	mov    %eax,(%esp)
8010609b:	e8 68 aa ff ff       	call   80100b08 <exec>
801060a0:	eb 3f                	jmp    801060e1 <sys_exec+0x122>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
801060a2:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801060a8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801060ab:	c1 e2 02             	shl    $0x2,%edx
801060ae:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
801060b1:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
801060b7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060bd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801060c1:	89 54 24 04          	mov    %edx,0x4(%esp)
801060c5:	89 04 24             	mov    %eax,(%esp)
801060c8:	e8 83 f1 ff ff       	call   80105250 <fetchstr>
801060cd:	85 c0                	test   %eax,%eax
801060cf:	79 07                	jns    801060d8 <sys_exec+0x119>
      return -1;
801060d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060d6:	eb 09                	jmp    801060e1 <sys_exec+0x122>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
801060d8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
801060dc:	e9 47 ff ff ff       	jmp    80106028 <sys_exec+0x69>
  return exec(path, argv);
}
801060e1:	c9                   	leave  
801060e2:	c3                   	ret    

801060e3 <sys_pipe>:

int
sys_pipe(void)
{
801060e3:	55                   	push   %ebp
801060e4:	89 e5                	mov    %esp,%ebp
801060e6:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
801060e9:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
801060f0:	00 
801060f1:	8d 45 ec             	lea    -0x14(%ebp),%eax
801060f4:	89 44 24 04          	mov    %eax,0x4(%esp)
801060f8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060ff:	e8 e2 f1 ff ff       	call   801052e6 <argptr>
80106104:	85 c0                	test   %eax,%eax
80106106:	79 0a                	jns    80106112 <sys_pipe+0x2f>
    return -1;
80106108:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010610d:	e9 9b 00 00 00       	jmp    801061ad <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106112:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106115:	89 44 24 04          	mov    %eax,0x4(%esp)
80106119:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010611c:	89 04 24             	mov    %eax,(%esp)
8010611f:	e8 6c dc ff ff       	call   80103d90 <pipealloc>
80106124:	85 c0                	test   %eax,%eax
80106126:	79 07                	jns    8010612f <sys_pipe+0x4c>
    return -1;
80106128:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010612d:	eb 7e                	jmp    801061ad <sys_pipe+0xca>
  fd0 = -1;
8010612f:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106136:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106139:	89 04 24             	mov    %eax,(%esp)
8010613c:	e8 84 f3 ff ff       	call   801054c5 <fdalloc>
80106141:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106144:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106148:	78 14                	js     8010615e <sys_pipe+0x7b>
8010614a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010614d:	89 04 24             	mov    %eax,(%esp)
80106150:	e8 70 f3 ff ff       	call   801054c5 <fdalloc>
80106155:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106158:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010615c:	79 37                	jns    80106195 <sys_pipe+0xb2>
    if(fd0 >= 0)
8010615e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106162:	78 14                	js     80106178 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106164:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010616a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010616d:	83 c2 08             	add    $0x8,%edx
80106170:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106177:	00 
    fileclose(rf);
80106178:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010617b:	89 04 24             	mov    %eax,(%esp)
8010617e:	e8 65 af ff ff       	call   801010e8 <fileclose>
    fileclose(wf);
80106183:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106186:	89 04 24             	mov    %eax,(%esp)
80106189:	e8 5a af ff ff       	call   801010e8 <fileclose>
    return -1;
8010618e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106193:	eb 18                	jmp    801061ad <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106195:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106198:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010619b:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
8010619d:	8b 45 ec             	mov    -0x14(%ebp),%eax
801061a0:	8d 50 04             	lea    0x4(%eax),%edx
801061a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061a6:	89 02                	mov    %eax,(%edx)
  return 0;
801061a8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061ad:	c9                   	leave  
801061ae:	c3                   	ret    
801061af:	90                   	nop

801061b0 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
801061b0:	55                   	push   %ebp
801061b1:	89 e5                	mov    %esp,%ebp
801061b3:	83 ec 08             	sub    $0x8,%esp
  return fork();
801061b6:	e8 93 e2 ff ff       	call   8010444e <fork>
}
801061bb:	c9                   	leave  
801061bc:	c3                   	ret    

801061bd <sys_exit>:

int
sys_exit(void)
{
801061bd:	55                   	push   %ebp
801061be:	89 e5                	mov    %esp,%ebp
801061c0:	83 ec 08             	sub    $0x8,%esp
  exit();
801061c3:	e8 e9 e3 ff ff       	call   801045b1 <exit>
  return 0;  // not reached
801061c8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061cd:	c9                   	leave  
801061ce:	c3                   	ret    

801061cf <sys_wait>:

int
sys_wait(void)
{
801061cf:	55                   	push   %ebp
801061d0:	89 e5                	mov    %esp,%ebp
801061d2:	83 ec 08             	sub    $0x8,%esp
  return wait();
801061d5:	e8 ef e4 ff ff       	call   801046c9 <wait>
}
801061da:	c9                   	leave  
801061db:	c3                   	ret    

801061dc <sys_kill>:

int
sys_kill(void)
{
801061dc:	55                   	push   %ebp
801061dd:	89 e5                	mov    %esp,%ebp
801061df:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
801061e2:	8d 45 f4             	lea    -0xc(%ebp),%eax
801061e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801061e9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061f0:	e8 b9 f0 ff ff       	call   801052ae <argint>
801061f5:	85 c0                	test   %eax,%eax
801061f7:	79 07                	jns    80106200 <sys_kill+0x24>
    return -1;
801061f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061fe:	eb 0b                	jmp    8010620b <sys_kill+0x2f>
  return kill(pid);
80106200:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106203:	89 04 24             	mov    %eax,(%esp)
80106206:	e8 1e e9 ff ff       	call   80104b29 <kill>
}
8010620b:	c9                   	leave  
8010620c:	c3                   	ret    

8010620d <sys_getpid>:

int
sys_getpid(void)
{
8010620d:	55                   	push   %ebp
8010620e:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106210:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106216:	8b 40 10             	mov    0x10(%eax),%eax
}
80106219:	5d                   	pop    %ebp
8010621a:	c3                   	ret    

8010621b <sys_sbrk>:

int
sys_sbrk(void)
{
8010621b:	55                   	push   %ebp
8010621c:	89 e5                	mov    %esp,%ebp
8010621e:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106221:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106224:	89 44 24 04          	mov    %eax,0x4(%esp)
80106228:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010622f:	e8 7a f0 ff ff       	call   801052ae <argint>
80106234:	85 c0                	test   %eax,%eax
80106236:	79 07                	jns    8010623f <sys_sbrk+0x24>
    return -1;
80106238:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010623d:	eb 24                	jmp    80106263 <sys_sbrk+0x48>
  addr = proc->sz;
8010623f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106245:	8b 00                	mov    (%eax),%eax
80106247:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
8010624a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010624d:	89 04 24             	mov    %eax,(%esp)
80106250:	e8 54 e1 ff ff       	call   801043a9 <growproc>
80106255:	85 c0                	test   %eax,%eax
80106257:	79 07                	jns    80106260 <sys_sbrk+0x45>
    return -1;
80106259:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010625e:	eb 03                	jmp    80106263 <sys_sbrk+0x48>
  return addr;
80106260:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106263:	c9                   	leave  
80106264:	c3                   	ret    

80106265 <sys_sleep>:

int
sys_sleep(void)
{
80106265:	55                   	push   %ebp
80106266:	89 e5                	mov    %esp,%ebp
80106268:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
8010626b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010626e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106272:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106279:	e8 30 f0 ff ff       	call   801052ae <argint>
8010627e:	85 c0                	test   %eax,%eax
80106280:	79 07                	jns    80106289 <sys_sleep+0x24>
    return -1;
80106282:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106287:	eb 6c                	jmp    801062f5 <sys_sleep+0x90>
  acquire(&tickslock);
80106289:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
80106290:	e8 6e ea ff ff       	call   80104d03 <acquire>
  ticks0 = ticks;
80106295:	a1 c0 2b 11 80       	mov    0x80112bc0,%eax
8010629a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
8010629d:	eb 34                	jmp    801062d3 <sys_sleep+0x6e>
    if(proc->killed){
8010629f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801062a5:	8b 40 24             	mov    0x24(%eax),%eax
801062a8:	85 c0                	test   %eax,%eax
801062aa:	74 13                	je     801062bf <sys_sleep+0x5a>
      release(&tickslock);
801062ac:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
801062b3:	e8 ad ea ff ff       	call   80104d65 <release>
      return -1;
801062b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062bd:	eb 36                	jmp    801062f5 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
801062bf:	c7 44 24 04 80 23 11 	movl   $0x80112380,0x4(%esp)
801062c6:	80 
801062c7:	c7 04 24 c0 2b 11 80 	movl   $0x80112bc0,(%esp)
801062ce:	e8 52 e7 ff ff       	call   80104a25 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
801062d3:	a1 c0 2b 11 80       	mov    0x80112bc0,%eax
801062d8:	89 c2                	mov    %eax,%edx
801062da:	2b 55 f4             	sub    -0xc(%ebp),%edx
801062dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062e0:	39 c2                	cmp    %eax,%edx
801062e2:	72 bb                	jb     8010629f <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
801062e4:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
801062eb:	e8 75 ea ff ff       	call   80104d65 <release>
  return 0;
801062f0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801062f5:	c9                   	leave  
801062f6:	c3                   	ret    

801062f7 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
801062f7:	55                   	push   %ebp
801062f8:	89 e5                	mov    %esp,%ebp
801062fa:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
801062fd:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
80106304:	e8 fa e9 ff ff       	call   80104d03 <acquire>
  xticks = ticks;
80106309:	a1 c0 2b 11 80       	mov    0x80112bc0,%eax
8010630e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106311:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
80106318:	e8 48 ea ff ff       	call   80104d65 <release>
  return xticks;
8010631d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106320:	c9                   	leave  
80106321:	c3                   	ret    
80106322:	66 90                	xchg   %ax,%ax

80106324 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106324:	55                   	push   %ebp
80106325:	89 e5                	mov    %esp,%ebp
80106327:	83 ec 08             	sub    $0x8,%esp
8010632a:	8b 55 08             	mov    0x8(%ebp),%edx
8010632d:	8b 45 0c             	mov    0xc(%ebp),%eax
80106330:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106334:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106337:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010633b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010633f:	ee                   	out    %al,(%dx)
}
80106340:	c9                   	leave  
80106341:	c3                   	ret    

80106342 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106342:	55                   	push   %ebp
80106343:	89 e5                	mov    %esp,%ebp
80106345:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106348:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
8010634f:	00 
80106350:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106357:	e8 c8 ff ff ff       	call   80106324 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
8010635c:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106363:	00 
80106364:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010636b:	e8 b4 ff ff ff       	call   80106324 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106370:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106377:	00 
80106378:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010637f:	e8 a0 ff ff ff       	call   80106324 <outb>
  picenable(IRQ_TIMER);
80106384:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010638b:	e8 89 d8 ff ff       	call   80103c19 <picenable>
}
80106390:	c9                   	leave  
80106391:	c3                   	ret    
80106392:	66 90                	xchg   %ax,%ax

80106394 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106394:	1e                   	push   %ds
  pushl %es
80106395:	06                   	push   %es
  pushl %fs
80106396:	0f a0                	push   %fs
  pushl %gs
80106398:	0f a8                	push   %gs
  pushal
8010639a:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
8010639b:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010639f:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801063a1:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
801063a3:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
801063a7:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
801063a9:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
801063ab:	54                   	push   %esp
  call trap
801063ac:	e8 de 01 00 00       	call   8010658f <trap>
  addl $4, %esp
801063b1:	83 c4 04             	add    $0x4,%esp

801063b4 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
801063b4:	61                   	popa   
  popl %gs
801063b5:	0f a9                	pop    %gs
  popl %fs
801063b7:	0f a1                	pop    %fs
  popl %es
801063b9:	07                   	pop    %es
  popl %ds
801063ba:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
801063bb:	83 c4 08             	add    $0x8,%esp
  iret
801063be:	cf                   	iret   
801063bf:	90                   	nop

801063c0 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
801063c0:	55                   	push   %ebp
801063c1:	89 e5                	mov    %esp,%ebp
801063c3:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801063c6:	8b 45 0c             	mov    0xc(%ebp),%eax
801063c9:	83 e8 01             	sub    $0x1,%eax
801063cc:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801063d0:	8b 45 08             	mov    0x8(%ebp),%eax
801063d3:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801063d7:	8b 45 08             	mov    0x8(%ebp),%eax
801063da:	c1 e8 10             	shr    $0x10,%eax
801063dd:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
801063e1:	8d 45 fa             	lea    -0x6(%ebp),%eax
801063e4:	0f 01 18             	lidtl  (%eax)
}
801063e7:	c9                   	leave  
801063e8:	c3                   	ret    

801063e9 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
801063e9:	55                   	push   %ebp
801063ea:	89 e5                	mov    %esp,%ebp
801063ec:	53                   	push   %ebx
801063ed:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801063f0:	0f 20 d3             	mov    %cr2,%ebx
801063f3:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
801063f6:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801063f9:	83 c4 10             	add    $0x10,%esp
801063fc:	5b                   	pop    %ebx
801063fd:	5d                   	pop    %ebp
801063fe:	c3                   	ret    

801063ff <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801063ff:	55                   	push   %ebp
80106400:	89 e5                	mov    %esp,%ebp
80106402:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106405:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010640c:	e9 c3 00 00 00       	jmp    801064d4 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106411:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106414:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
8010641b:	89 c2                	mov    %eax,%edx
8010641d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106420:	66 89 14 c5 c0 23 11 	mov    %dx,-0x7feedc40(,%eax,8)
80106427:	80 
80106428:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010642b:	66 c7 04 c5 c2 23 11 	movw   $0x8,-0x7feedc3e(,%eax,8)
80106432:	80 08 00 
80106435:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106438:	0f b6 14 c5 c4 23 11 	movzbl -0x7feedc3c(,%eax,8),%edx
8010643f:	80 
80106440:	83 e2 e0             	and    $0xffffffe0,%edx
80106443:	88 14 c5 c4 23 11 80 	mov    %dl,-0x7feedc3c(,%eax,8)
8010644a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010644d:	0f b6 14 c5 c4 23 11 	movzbl -0x7feedc3c(,%eax,8),%edx
80106454:	80 
80106455:	83 e2 1f             	and    $0x1f,%edx
80106458:	88 14 c5 c4 23 11 80 	mov    %dl,-0x7feedc3c(,%eax,8)
8010645f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106462:	0f b6 14 c5 c5 23 11 	movzbl -0x7feedc3b(,%eax,8),%edx
80106469:	80 
8010646a:	83 e2 f0             	and    $0xfffffff0,%edx
8010646d:	83 ca 0e             	or     $0xe,%edx
80106470:	88 14 c5 c5 23 11 80 	mov    %dl,-0x7feedc3b(,%eax,8)
80106477:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010647a:	0f b6 14 c5 c5 23 11 	movzbl -0x7feedc3b(,%eax,8),%edx
80106481:	80 
80106482:	83 e2 ef             	and    $0xffffffef,%edx
80106485:	88 14 c5 c5 23 11 80 	mov    %dl,-0x7feedc3b(,%eax,8)
8010648c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010648f:	0f b6 14 c5 c5 23 11 	movzbl -0x7feedc3b(,%eax,8),%edx
80106496:	80 
80106497:	83 e2 9f             	and    $0xffffff9f,%edx
8010649a:	88 14 c5 c5 23 11 80 	mov    %dl,-0x7feedc3b(,%eax,8)
801064a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064a4:	0f b6 14 c5 c5 23 11 	movzbl -0x7feedc3b(,%eax,8),%edx
801064ab:	80 
801064ac:	83 ca 80             	or     $0xffffff80,%edx
801064af:	88 14 c5 c5 23 11 80 	mov    %dl,-0x7feedc3b(,%eax,8)
801064b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064b9:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
801064c0:	c1 e8 10             	shr    $0x10,%eax
801064c3:	89 c2                	mov    %eax,%edx
801064c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064c8:	66 89 14 c5 c6 23 11 	mov    %dx,-0x7feedc3a(,%eax,8)
801064cf:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
801064d0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801064d4:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
801064db:	0f 8e 30 ff ff ff    	jle    80106411 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801064e1:	a1 98 b1 10 80       	mov    0x8010b198,%eax
801064e6:	66 a3 c0 25 11 80    	mov    %ax,0x801125c0
801064ec:	66 c7 05 c2 25 11 80 	movw   $0x8,0x801125c2
801064f3:	08 00 
801064f5:	0f b6 05 c4 25 11 80 	movzbl 0x801125c4,%eax
801064fc:	83 e0 e0             	and    $0xffffffe0,%eax
801064ff:	a2 c4 25 11 80       	mov    %al,0x801125c4
80106504:	0f b6 05 c4 25 11 80 	movzbl 0x801125c4,%eax
8010650b:	83 e0 1f             	and    $0x1f,%eax
8010650e:	a2 c4 25 11 80       	mov    %al,0x801125c4
80106513:	0f b6 05 c5 25 11 80 	movzbl 0x801125c5,%eax
8010651a:	83 c8 0f             	or     $0xf,%eax
8010651d:	a2 c5 25 11 80       	mov    %al,0x801125c5
80106522:	0f b6 05 c5 25 11 80 	movzbl 0x801125c5,%eax
80106529:	83 e0 ef             	and    $0xffffffef,%eax
8010652c:	a2 c5 25 11 80       	mov    %al,0x801125c5
80106531:	0f b6 05 c5 25 11 80 	movzbl 0x801125c5,%eax
80106538:	83 c8 60             	or     $0x60,%eax
8010653b:	a2 c5 25 11 80       	mov    %al,0x801125c5
80106540:	0f b6 05 c5 25 11 80 	movzbl 0x801125c5,%eax
80106547:	83 c8 80             	or     $0xffffff80,%eax
8010654a:	a2 c5 25 11 80       	mov    %al,0x801125c5
8010654f:	a1 98 b1 10 80       	mov    0x8010b198,%eax
80106554:	c1 e8 10             	shr    $0x10,%eax
80106557:	66 a3 c6 25 11 80    	mov    %ax,0x801125c6
  
  initlock(&tickslock, "time");
8010655d:	c7 44 24 04 84 87 10 	movl   $0x80108784,0x4(%esp)
80106564:	80 
80106565:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
8010656c:	e8 71 e7 ff ff       	call   80104ce2 <initlock>
}
80106571:	c9                   	leave  
80106572:	c3                   	ret    

80106573 <idtinit>:

void
idtinit(void)
{
80106573:	55                   	push   %ebp
80106574:	89 e5                	mov    %esp,%ebp
80106576:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106579:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106580:	00 
80106581:	c7 04 24 c0 23 11 80 	movl   $0x801123c0,(%esp)
80106588:	e8 33 fe ff ff       	call   801063c0 <lidt>
}
8010658d:	c9                   	leave  
8010658e:	c3                   	ret    

8010658f <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
8010658f:	55                   	push   %ebp
80106590:	89 e5                	mov    %esp,%ebp
80106592:	57                   	push   %edi
80106593:	56                   	push   %esi
80106594:	53                   	push   %ebx
80106595:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106598:	8b 45 08             	mov    0x8(%ebp),%eax
8010659b:	8b 40 30             	mov    0x30(%eax),%eax
8010659e:	83 f8 40             	cmp    $0x40,%eax
801065a1:	75 3e                	jne    801065e1 <trap+0x52>
    if(proc->killed)
801065a3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065a9:	8b 40 24             	mov    0x24(%eax),%eax
801065ac:	85 c0                	test   %eax,%eax
801065ae:	74 05                	je     801065b5 <trap+0x26>
      exit();
801065b0:	e8 fc df ff ff       	call   801045b1 <exit>
    proc->tf = tf;
801065b5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065bb:	8b 55 08             	mov    0x8(%ebp),%edx
801065be:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
801065c1:	e8 c5 ed ff ff       	call   8010538b <syscall>
    if(proc->killed)
801065c6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065cc:	8b 40 24             	mov    0x24(%eax),%eax
801065cf:	85 c0                	test   %eax,%eax
801065d1:	0f 84 34 02 00 00    	je     8010680b <trap+0x27c>
      exit();
801065d7:	e8 d5 df ff ff       	call   801045b1 <exit>
    return;
801065dc:	e9 2a 02 00 00       	jmp    8010680b <trap+0x27c>
  }

  switch(tf->trapno){
801065e1:	8b 45 08             	mov    0x8(%ebp),%eax
801065e4:	8b 40 30             	mov    0x30(%eax),%eax
801065e7:	83 e8 20             	sub    $0x20,%eax
801065ea:	83 f8 1f             	cmp    $0x1f,%eax
801065ed:	0f 87 bc 00 00 00    	ja     801066af <trap+0x120>
801065f3:	8b 04 85 2c 88 10 80 	mov    -0x7fef77d4(,%eax,4),%eax
801065fa:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801065fc:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106602:	0f b6 00             	movzbl (%eax),%eax
80106605:	84 c0                	test   %al,%al
80106607:	75 31                	jne    8010663a <trap+0xab>
      acquire(&tickslock);
80106609:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
80106610:	e8 ee e6 ff ff       	call   80104d03 <acquire>
      ticks++;
80106615:	a1 c0 2b 11 80       	mov    0x80112bc0,%eax
8010661a:	83 c0 01             	add    $0x1,%eax
8010661d:	a3 c0 2b 11 80       	mov    %eax,0x80112bc0
      wakeup(&ticks);
80106622:	c7 04 24 c0 2b 11 80 	movl   $0x80112bc0,(%esp)
80106629:	e8 d0 e4 ff ff       	call   80104afe <wakeup>
      release(&tickslock);
8010662e:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
80106635:	e8 2b e7 ff ff       	call   80104d65 <release>
    }
    lapiceoi();
8010663a:	e8 f6 c9 ff ff       	call   80103035 <lapiceoi>
    break;
8010663f:	e9 41 01 00 00       	jmp    80106785 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80106644:	e8 f0 c1 ff ff       	call   80102839 <ideintr>
    lapiceoi();
80106649:	e8 e7 c9 ff ff       	call   80103035 <lapiceoi>
    break;
8010664e:	e9 32 01 00 00       	jmp    80106785 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80106653:	e8 b9 c7 ff ff       	call   80102e11 <kbdintr>
    lapiceoi();
80106658:	e8 d8 c9 ff ff       	call   80103035 <lapiceoi>
    break;
8010665d:	e9 23 01 00 00       	jmp    80106785 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80106662:	e8 a9 03 00 00       	call   80106a10 <uartintr>
    lapiceoi();
80106667:	e8 c9 c9 ff ff       	call   80103035 <lapiceoi>
    break;
8010666c:	e9 14 01 00 00       	jmp    80106785 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80106671:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106674:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80106677:	8b 45 08             	mov    0x8(%ebp),%eax
8010667a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010667e:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80106681:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106687:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010668a:	0f b6 c0             	movzbl %al,%eax
8010668d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106691:	89 54 24 08          	mov    %edx,0x8(%esp)
80106695:	89 44 24 04          	mov    %eax,0x4(%esp)
80106699:	c7 04 24 8c 87 10 80 	movl   $0x8010878c,(%esp)
801066a0:	e8 05 9d ff ff       	call   801003aa <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
801066a5:	e8 8b c9 ff ff       	call   80103035 <lapiceoi>
    break;
801066aa:	e9 d6 00 00 00       	jmp    80106785 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
801066af:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066b5:	85 c0                	test   %eax,%eax
801066b7:	74 11                	je     801066ca <trap+0x13b>
801066b9:	8b 45 08             	mov    0x8(%ebp),%eax
801066bc:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801066c0:	0f b7 c0             	movzwl %ax,%eax
801066c3:	83 e0 03             	and    $0x3,%eax
801066c6:	85 c0                	test   %eax,%eax
801066c8:	75 46                	jne    80106710 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801066ca:	e8 1a fd ff ff       	call   801063e9 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
801066cf:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801066d2:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
801066d5:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801066dc:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801066df:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
801066e2:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801066e5:	8b 52 30             	mov    0x30(%edx),%edx
801066e8:	89 44 24 10          	mov    %eax,0x10(%esp)
801066ec:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801066f0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801066f4:	89 54 24 04          	mov    %edx,0x4(%esp)
801066f8:	c7 04 24 b0 87 10 80 	movl   $0x801087b0,(%esp)
801066ff:	e8 a6 9c ff ff       	call   801003aa <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80106704:	c7 04 24 e2 87 10 80 	movl   $0x801087e2,(%esp)
8010670b:	e8 36 9e ff ff       	call   80100546 <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106710:	e8 d4 fc ff ff       	call   801063e9 <rcr2>
80106715:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106717:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010671a:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010671d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106723:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106726:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106729:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010672c:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010672f:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106732:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106735:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010673b:	83 c0 6c             	add    $0x6c,%eax
8010673e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106741:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106747:	8b 40 10             	mov    0x10(%eax),%eax
8010674a:	89 54 24 1c          	mov    %edx,0x1c(%esp)
8010674e:	89 7c 24 18          	mov    %edi,0x18(%esp)
80106752:	89 74 24 14          	mov    %esi,0x14(%esp)
80106756:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010675a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010675e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106761:	89 54 24 08          	mov    %edx,0x8(%esp)
80106765:	89 44 24 04          	mov    %eax,0x4(%esp)
80106769:	c7 04 24 e8 87 10 80 	movl   $0x801087e8,(%esp)
80106770:	e8 35 9c ff ff       	call   801003aa <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80106775:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010677b:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80106782:	eb 01                	jmp    80106785 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80106784:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106785:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010678b:	85 c0                	test   %eax,%eax
8010678d:	74 24                	je     801067b3 <trap+0x224>
8010678f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106795:	8b 40 24             	mov    0x24(%eax),%eax
80106798:	85 c0                	test   %eax,%eax
8010679a:	74 17                	je     801067b3 <trap+0x224>
8010679c:	8b 45 08             	mov    0x8(%ebp),%eax
8010679f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801067a3:	0f b7 c0             	movzwl %ax,%eax
801067a6:	83 e0 03             	and    $0x3,%eax
801067a9:	83 f8 03             	cmp    $0x3,%eax
801067ac:	75 05                	jne    801067b3 <trap+0x224>
    exit();
801067ae:	e8 fe dd ff ff       	call   801045b1 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
801067b3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801067b9:	85 c0                	test   %eax,%eax
801067bb:	74 1e                	je     801067db <trap+0x24c>
801067bd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801067c3:	8b 40 0c             	mov    0xc(%eax),%eax
801067c6:	83 f8 04             	cmp    $0x4,%eax
801067c9:	75 10                	jne    801067db <trap+0x24c>
801067cb:	8b 45 08             	mov    0x8(%ebp),%eax
801067ce:	8b 40 30             	mov    0x30(%eax),%eax
801067d1:	83 f8 20             	cmp    $0x20,%eax
801067d4:	75 05                	jne    801067db <trap+0x24c>
    yield();
801067d6:	e8 ec e1 ff ff       	call   801049c7 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801067db:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801067e1:	85 c0                	test   %eax,%eax
801067e3:	74 27                	je     8010680c <trap+0x27d>
801067e5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801067eb:	8b 40 24             	mov    0x24(%eax),%eax
801067ee:	85 c0                	test   %eax,%eax
801067f0:	74 1a                	je     8010680c <trap+0x27d>
801067f2:	8b 45 08             	mov    0x8(%ebp),%eax
801067f5:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801067f9:	0f b7 c0             	movzwl %ax,%eax
801067fc:	83 e0 03             	and    $0x3,%eax
801067ff:	83 f8 03             	cmp    $0x3,%eax
80106802:	75 08                	jne    8010680c <trap+0x27d>
    exit();
80106804:	e8 a8 dd ff ff       	call   801045b1 <exit>
80106809:	eb 01                	jmp    8010680c <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
8010680b:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
8010680c:	83 c4 3c             	add    $0x3c,%esp
8010680f:	5b                   	pop    %ebx
80106810:	5e                   	pop    %esi
80106811:	5f                   	pop    %edi
80106812:	5d                   	pop    %ebp
80106813:	c3                   	ret    

80106814 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106814:	55                   	push   %ebp
80106815:	89 e5                	mov    %esp,%ebp
80106817:	53                   	push   %ebx
80106818:	83 ec 14             	sub    $0x14,%esp
8010681b:	8b 45 08             	mov    0x8(%ebp),%eax
8010681e:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106822:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80106826:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010682a:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010682e:	ec                   	in     (%dx),%al
8010682f:	89 c3                	mov    %eax,%ebx
80106831:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80106834:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80106838:	83 c4 14             	add    $0x14,%esp
8010683b:	5b                   	pop    %ebx
8010683c:	5d                   	pop    %ebp
8010683d:	c3                   	ret    

8010683e <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010683e:	55                   	push   %ebp
8010683f:	89 e5                	mov    %esp,%ebp
80106841:	83 ec 08             	sub    $0x8,%esp
80106844:	8b 55 08             	mov    0x8(%ebp),%edx
80106847:	8b 45 0c             	mov    0xc(%ebp),%eax
8010684a:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010684e:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106851:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106855:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106859:	ee                   	out    %al,(%dx)
}
8010685a:	c9                   	leave  
8010685b:	c3                   	ret    

8010685c <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
8010685c:	55                   	push   %ebp
8010685d:	89 e5                	mov    %esp,%ebp
8010685f:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106862:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106869:	00 
8010686a:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106871:	e8 c8 ff ff ff       	call   8010683e <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106876:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
8010687d:	00 
8010687e:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106885:	e8 b4 ff ff ff       	call   8010683e <outb>
  outb(COM1+0, 115200/9600);
8010688a:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106891:	00 
80106892:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106899:	e8 a0 ff ff ff       	call   8010683e <outb>
  outb(COM1+1, 0);
8010689e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801068a5:	00 
801068a6:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801068ad:	e8 8c ff ff ff       	call   8010683e <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
801068b2:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801068b9:	00 
801068ba:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801068c1:	e8 78 ff ff ff       	call   8010683e <outb>
  outb(COM1+4, 0);
801068c6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801068cd:	00 
801068ce:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
801068d5:	e8 64 ff ff ff       	call   8010683e <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
801068da:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801068e1:	00 
801068e2:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801068e9:	e8 50 ff ff ff       	call   8010683e <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
801068ee:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801068f5:	e8 1a ff ff ff       	call   80106814 <inb>
801068fa:	3c ff                	cmp    $0xff,%al
801068fc:	74 6c                	je     8010696a <uartinit+0x10e>
    return;
  uart = 1;
801068fe:	c7 05 4c b6 10 80 01 	movl   $0x1,0x8010b64c
80106905:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106908:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
8010690f:	e8 00 ff ff ff       	call   80106814 <inb>
  inb(COM1+0);
80106914:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010691b:	e8 f4 fe ff ff       	call   80106814 <inb>
  picenable(IRQ_COM1);
80106920:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106927:	e8 ed d2 ff ff       	call   80103c19 <picenable>
  ioapicenable(IRQ_COM1, 0);
8010692c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106933:	00 
80106934:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010693b:	e8 7e c1 ff ff       	call   80102abe <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106940:	c7 45 f4 ac 88 10 80 	movl   $0x801088ac,-0xc(%ebp)
80106947:	eb 15                	jmp    8010695e <uartinit+0x102>
    uartputc(*p);
80106949:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010694c:	0f b6 00             	movzbl (%eax),%eax
8010694f:	0f be c0             	movsbl %al,%eax
80106952:	89 04 24             	mov    %eax,(%esp)
80106955:	e8 13 00 00 00       	call   8010696d <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
8010695a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010695e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106961:	0f b6 00             	movzbl (%eax),%eax
80106964:	84 c0                	test   %al,%al
80106966:	75 e1                	jne    80106949 <uartinit+0xed>
80106968:	eb 01                	jmp    8010696b <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
8010696a:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
8010696b:	c9                   	leave  
8010696c:	c3                   	ret    

8010696d <uartputc>:

void
uartputc(int c)
{
8010696d:	55                   	push   %ebp
8010696e:	89 e5                	mov    %esp,%ebp
80106970:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80106973:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106978:	85 c0                	test   %eax,%eax
8010697a:	74 4d                	je     801069c9 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010697c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106983:	eb 10                	jmp    80106995 <uartputc+0x28>
    microdelay(10);
80106985:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
8010698c:	e8 c9 c6 ff ff       	call   8010305a <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106991:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106995:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106999:	7f 16                	jg     801069b1 <uartputc+0x44>
8010699b:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801069a2:	e8 6d fe ff ff       	call   80106814 <inb>
801069a7:	0f b6 c0             	movzbl %al,%eax
801069aa:	83 e0 20             	and    $0x20,%eax
801069ad:	85 c0                	test   %eax,%eax
801069af:	74 d4                	je     80106985 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
801069b1:	8b 45 08             	mov    0x8(%ebp),%eax
801069b4:	0f b6 c0             	movzbl %al,%eax
801069b7:	89 44 24 04          	mov    %eax,0x4(%esp)
801069bb:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801069c2:	e8 77 fe ff ff       	call   8010683e <outb>
801069c7:	eb 01                	jmp    801069ca <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
801069c9:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
801069ca:	c9                   	leave  
801069cb:	c3                   	ret    

801069cc <uartgetc>:

static int
uartgetc(void)
{
801069cc:	55                   	push   %ebp
801069cd:	89 e5                	mov    %esp,%ebp
801069cf:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
801069d2:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
801069d7:	85 c0                	test   %eax,%eax
801069d9:	75 07                	jne    801069e2 <uartgetc+0x16>
    return -1;
801069db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069e0:	eb 2c                	jmp    80106a0e <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
801069e2:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801069e9:	e8 26 fe ff ff       	call   80106814 <inb>
801069ee:	0f b6 c0             	movzbl %al,%eax
801069f1:	83 e0 01             	and    $0x1,%eax
801069f4:	85 c0                	test   %eax,%eax
801069f6:	75 07                	jne    801069ff <uartgetc+0x33>
    return -1;
801069f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069fd:	eb 0f                	jmp    80106a0e <uartgetc+0x42>
  return inb(COM1+0);
801069ff:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106a06:	e8 09 fe ff ff       	call   80106814 <inb>
80106a0b:	0f b6 c0             	movzbl %al,%eax
}
80106a0e:	c9                   	leave  
80106a0f:	c3                   	ret    

80106a10 <uartintr>:

void
uartintr(void)
{
80106a10:	55                   	push   %ebp
80106a11:	89 e5                	mov    %esp,%ebp
80106a13:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80106a16:	c7 04 24 cc 69 10 80 	movl   $0x801069cc,(%esp)
80106a1d:	e8 94 9d ff ff       	call   801007b6 <consoleintr>
}
80106a22:	c9                   	leave  
80106a23:	c3                   	ret    

80106a24 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106a24:	6a 00                	push   $0x0
  pushl $0
80106a26:	6a 00                	push   $0x0
  jmp alltraps
80106a28:	e9 67 f9 ff ff       	jmp    80106394 <alltraps>

80106a2d <vector1>:
.globl vector1
vector1:
  pushl $0
80106a2d:	6a 00                	push   $0x0
  pushl $1
80106a2f:	6a 01                	push   $0x1
  jmp alltraps
80106a31:	e9 5e f9 ff ff       	jmp    80106394 <alltraps>

80106a36 <vector2>:
.globl vector2
vector2:
  pushl $0
80106a36:	6a 00                	push   $0x0
  pushl $2
80106a38:	6a 02                	push   $0x2
  jmp alltraps
80106a3a:	e9 55 f9 ff ff       	jmp    80106394 <alltraps>

80106a3f <vector3>:
.globl vector3
vector3:
  pushl $0
80106a3f:	6a 00                	push   $0x0
  pushl $3
80106a41:	6a 03                	push   $0x3
  jmp alltraps
80106a43:	e9 4c f9 ff ff       	jmp    80106394 <alltraps>

80106a48 <vector4>:
.globl vector4
vector4:
  pushl $0
80106a48:	6a 00                	push   $0x0
  pushl $4
80106a4a:	6a 04                	push   $0x4
  jmp alltraps
80106a4c:	e9 43 f9 ff ff       	jmp    80106394 <alltraps>

80106a51 <vector5>:
.globl vector5
vector5:
  pushl $0
80106a51:	6a 00                	push   $0x0
  pushl $5
80106a53:	6a 05                	push   $0x5
  jmp alltraps
80106a55:	e9 3a f9 ff ff       	jmp    80106394 <alltraps>

80106a5a <vector6>:
.globl vector6
vector6:
  pushl $0
80106a5a:	6a 00                	push   $0x0
  pushl $6
80106a5c:	6a 06                	push   $0x6
  jmp alltraps
80106a5e:	e9 31 f9 ff ff       	jmp    80106394 <alltraps>

80106a63 <vector7>:
.globl vector7
vector7:
  pushl $0
80106a63:	6a 00                	push   $0x0
  pushl $7
80106a65:	6a 07                	push   $0x7
  jmp alltraps
80106a67:	e9 28 f9 ff ff       	jmp    80106394 <alltraps>

80106a6c <vector8>:
.globl vector8
vector8:
  pushl $8
80106a6c:	6a 08                	push   $0x8
  jmp alltraps
80106a6e:	e9 21 f9 ff ff       	jmp    80106394 <alltraps>

80106a73 <vector9>:
.globl vector9
vector9:
  pushl $0
80106a73:	6a 00                	push   $0x0
  pushl $9
80106a75:	6a 09                	push   $0x9
  jmp alltraps
80106a77:	e9 18 f9 ff ff       	jmp    80106394 <alltraps>

80106a7c <vector10>:
.globl vector10
vector10:
  pushl $10
80106a7c:	6a 0a                	push   $0xa
  jmp alltraps
80106a7e:	e9 11 f9 ff ff       	jmp    80106394 <alltraps>

80106a83 <vector11>:
.globl vector11
vector11:
  pushl $11
80106a83:	6a 0b                	push   $0xb
  jmp alltraps
80106a85:	e9 0a f9 ff ff       	jmp    80106394 <alltraps>

80106a8a <vector12>:
.globl vector12
vector12:
  pushl $12
80106a8a:	6a 0c                	push   $0xc
  jmp alltraps
80106a8c:	e9 03 f9 ff ff       	jmp    80106394 <alltraps>

80106a91 <vector13>:
.globl vector13
vector13:
  pushl $13
80106a91:	6a 0d                	push   $0xd
  jmp alltraps
80106a93:	e9 fc f8 ff ff       	jmp    80106394 <alltraps>

80106a98 <vector14>:
.globl vector14
vector14:
  pushl $14
80106a98:	6a 0e                	push   $0xe
  jmp alltraps
80106a9a:	e9 f5 f8 ff ff       	jmp    80106394 <alltraps>

80106a9f <vector15>:
.globl vector15
vector15:
  pushl $0
80106a9f:	6a 00                	push   $0x0
  pushl $15
80106aa1:	6a 0f                	push   $0xf
  jmp alltraps
80106aa3:	e9 ec f8 ff ff       	jmp    80106394 <alltraps>

80106aa8 <vector16>:
.globl vector16
vector16:
  pushl $0
80106aa8:	6a 00                	push   $0x0
  pushl $16
80106aaa:	6a 10                	push   $0x10
  jmp alltraps
80106aac:	e9 e3 f8 ff ff       	jmp    80106394 <alltraps>

80106ab1 <vector17>:
.globl vector17
vector17:
  pushl $17
80106ab1:	6a 11                	push   $0x11
  jmp alltraps
80106ab3:	e9 dc f8 ff ff       	jmp    80106394 <alltraps>

80106ab8 <vector18>:
.globl vector18
vector18:
  pushl $0
80106ab8:	6a 00                	push   $0x0
  pushl $18
80106aba:	6a 12                	push   $0x12
  jmp alltraps
80106abc:	e9 d3 f8 ff ff       	jmp    80106394 <alltraps>

80106ac1 <vector19>:
.globl vector19
vector19:
  pushl $0
80106ac1:	6a 00                	push   $0x0
  pushl $19
80106ac3:	6a 13                	push   $0x13
  jmp alltraps
80106ac5:	e9 ca f8 ff ff       	jmp    80106394 <alltraps>

80106aca <vector20>:
.globl vector20
vector20:
  pushl $0
80106aca:	6a 00                	push   $0x0
  pushl $20
80106acc:	6a 14                	push   $0x14
  jmp alltraps
80106ace:	e9 c1 f8 ff ff       	jmp    80106394 <alltraps>

80106ad3 <vector21>:
.globl vector21
vector21:
  pushl $0
80106ad3:	6a 00                	push   $0x0
  pushl $21
80106ad5:	6a 15                	push   $0x15
  jmp alltraps
80106ad7:	e9 b8 f8 ff ff       	jmp    80106394 <alltraps>

80106adc <vector22>:
.globl vector22
vector22:
  pushl $0
80106adc:	6a 00                	push   $0x0
  pushl $22
80106ade:	6a 16                	push   $0x16
  jmp alltraps
80106ae0:	e9 af f8 ff ff       	jmp    80106394 <alltraps>

80106ae5 <vector23>:
.globl vector23
vector23:
  pushl $0
80106ae5:	6a 00                	push   $0x0
  pushl $23
80106ae7:	6a 17                	push   $0x17
  jmp alltraps
80106ae9:	e9 a6 f8 ff ff       	jmp    80106394 <alltraps>

80106aee <vector24>:
.globl vector24
vector24:
  pushl $0
80106aee:	6a 00                	push   $0x0
  pushl $24
80106af0:	6a 18                	push   $0x18
  jmp alltraps
80106af2:	e9 9d f8 ff ff       	jmp    80106394 <alltraps>

80106af7 <vector25>:
.globl vector25
vector25:
  pushl $0
80106af7:	6a 00                	push   $0x0
  pushl $25
80106af9:	6a 19                	push   $0x19
  jmp alltraps
80106afb:	e9 94 f8 ff ff       	jmp    80106394 <alltraps>

80106b00 <vector26>:
.globl vector26
vector26:
  pushl $0
80106b00:	6a 00                	push   $0x0
  pushl $26
80106b02:	6a 1a                	push   $0x1a
  jmp alltraps
80106b04:	e9 8b f8 ff ff       	jmp    80106394 <alltraps>

80106b09 <vector27>:
.globl vector27
vector27:
  pushl $0
80106b09:	6a 00                	push   $0x0
  pushl $27
80106b0b:	6a 1b                	push   $0x1b
  jmp alltraps
80106b0d:	e9 82 f8 ff ff       	jmp    80106394 <alltraps>

80106b12 <vector28>:
.globl vector28
vector28:
  pushl $0
80106b12:	6a 00                	push   $0x0
  pushl $28
80106b14:	6a 1c                	push   $0x1c
  jmp alltraps
80106b16:	e9 79 f8 ff ff       	jmp    80106394 <alltraps>

80106b1b <vector29>:
.globl vector29
vector29:
  pushl $0
80106b1b:	6a 00                	push   $0x0
  pushl $29
80106b1d:	6a 1d                	push   $0x1d
  jmp alltraps
80106b1f:	e9 70 f8 ff ff       	jmp    80106394 <alltraps>

80106b24 <vector30>:
.globl vector30
vector30:
  pushl $0
80106b24:	6a 00                	push   $0x0
  pushl $30
80106b26:	6a 1e                	push   $0x1e
  jmp alltraps
80106b28:	e9 67 f8 ff ff       	jmp    80106394 <alltraps>

80106b2d <vector31>:
.globl vector31
vector31:
  pushl $0
80106b2d:	6a 00                	push   $0x0
  pushl $31
80106b2f:	6a 1f                	push   $0x1f
  jmp alltraps
80106b31:	e9 5e f8 ff ff       	jmp    80106394 <alltraps>

80106b36 <vector32>:
.globl vector32
vector32:
  pushl $0
80106b36:	6a 00                	push   $0x0
  pushl $32
80106b38:	6a 20                	push   $0x20
  jmp alltraps
80106b3a:	e9 55 f8 ff ff       	jmp    80106394 <alltraps>

80106b3f <vector33>:
.globl vector33
vector33:
  pushl $0
80106b3f:	6a 00                	push   $0x0
  pushl $33
80106b41:	6a 21                	push   $0x21
  jmp alltraps
80106b43:	e9 4c f8 ff ff       	jmp    80106394 <alltraps>

80106b48 <vector34>:
.globl vector34
vector34:
  pushl $0
80106b48:	6a 00                	push   $0x0
  pushl $34
80106b4a:	6a 22                	push   $0x22
  jmp alltraps
80106b4c:	e9 43 f8 ff ff       	jmp    80106394 <alltraps>

80106b51 <vector35>:
.globl vector35
vector35:
  pushl $0
80106b51:	6a 00                	push   $0x0
  pushl $35
80106b53:	6a 23                	push   $0x23
  jmp alltraps
80106b55:	e9 3a f8 ff ff       	jmp    80106394 <alltraps>

80106b5a <vector36>:
.globl vector36
vector36:
  pushl $0
80106b5a:	6a 00                	push   $0x0
  pushl $36
80106b5c:	6a 24                	push   $0x24
  jmp alltraps
80106b5e:	e9 31 f8 ff ff       	jmp    80106394 <alltraps>

80106b63 <vector37>:
.globl vector37
vector37:
  pushl $0
80106b63:	6a 00                	push   $0x0
  pushl $37
80106b65:	6a 25                	push   $0x25
  jmp alltraps
80106b67:	e9 28 f8 ff ff       	jmp    80106394 <alltraps>

80106b6c <vector38>:
.globl vector38
vector38:
  pushl $0
80106b6c:	6a 00                	push   $0x0
  pushl $38
80106b6e:	6a 26                	push   $0x26
  jmp alltraps
80106b70:	e9 1f f8 ff ff       	jmp    80106394 <alltraps>

80106b75 <vector39>:
.globl vector39
vector39:
  pushl $0
80106b75:	6a 00                	push   $0x0
  pushl $39
80106b77:	6a 27                	push   $0x27
  jmp alltraps
80106b79:	e9 16 f8 ff ff       	jmp    80106394 <alltraps>

80106b7e <vector40>:
.globl vector40
vector40:
  pushl $0
80106b7e:	6a 00                	push   $0x0
  pushl $40
80106b80:	6a 28                	push   $0x28
  jmp alltraps
80106b82:	e9 0d f8 ff ff       	jmp    80106394 <alltraps>

80106b87 <vector41>:
.globl vector41
vector41:
  pushl $0
80106b87:	6a 00                	push   $0x0
  pushl $41
80106b89:	6a 29                	push   $0x29
  jmp alltraps
80106b8b:	e9 04 f8 ff ff       	jmp    80106394 <alltraps>

80106b90 <vector42>:
.globl vector42
vector42:
  pushl $0
80106b90:	6a 00                	push   $0x0
  pushl $42
80106b92:	6a 2a                	push   $0x2a
  jmp alltraps
80106b94:	e9 fb f7 ff ff       	jmp    80106394 <alltraps>

80106b99 <vector43>:
.globl vector43
vector43:
  pushl $0
80106b99:	6a 00                	push   $0x0
  pushl $43
80106b9b:	6a 2b                	push   $0x2b
  jmp alltraps
80106b9d:	e9 f2 f7 ff ff       	jmp    80106394 <alltraps>

80106ba2 <vector44>:
.globl vector44
vector44:
  pushl $0
80106ba2:	6a 00                	push   $0x0
  pushl $44
80106ba4:	6a 2c                	push   $0x2c
  jmp alltraps
80106ba6:	e9 e9 f7 ff ff       	jmp    80106394 <alltraps>

80106bab <vector45>:
.globl vector45
vector45:
  pushl $0
80106bab:	6a 00                	push   $0x0
  pushl $45
80106bad:	6a 2d                	push   $0x2d
  jmp alltraps
80106baf:	e9 e0 f7 ff ff       	jmp    80106394 <alltraps>

80106bb4 <vector46>:
.globl vector46
vector46:
  pushl $0
80106bb4:	6a 00                	push   $0x0
  pushl $46
80106bb6:	6a 2e                	push   $0x2e
  jmp alltraps
80106bb8:	e9 d7 f7 ff ff       	jmp    80106394 <alltraps>

80106bbd <vector47>:
.globl vector47
vector47:
  pushl $0
80106bbd:	6a 00                	push   $0x0
  pushl $47
80106bbf:	6a 2f                	push   $0x2f
  jmp alltraps
80106bc1:	e9 ce f7 ff ff       	jmp    80106394 <alltraps>

80106bc6 <vector48>:
.globl vector48
vector48:
  pushl $0
80106bc6:	6a 00                	push   $0x0
  pushl $48
80106bc8:	6a 30                	push   $0x30
  jmp alltraps
80106bca:	e9 c5 f7 ff ff       	jmp    80106394 <alltraps>

80106bcf <vector49>:
.globl vector49
vector49:
  pushl $0
80106bcf:	6a 00                	push   $0x0
  pushl $49
80106bd1:	6a 31                	push   $0x31
  jmp alltraps
80106bd3:	e9 bc f7 ff ff       	jmp    80106394 <alltraps>

80106bd8 <vector50>:
.globl vector50
vector50:
  pushl $0
80106bd8:	6a 00                	push   $0x0
  pushl $50
80106bda:	6a 32                	push   $0x32
  jmp alltraps
80106bdc:	e9 b3 f7 ff ff       	jmp    80106394 <alltraps>

80106be1 <vector51>:
.globl vector51
vector51:
  pushl $0
80106be1:	6a 00                	push   $0x0
  pushl $51
80106be3:	6a 33                	push   $0x33
  jmp alltraps
80106be5:	e9 aa f7 ff ff       	jmp    80106394 <alltraps>

80106bea <vector52>:
.globl vector52
vector52:
  pushl $0
80106bea:	6a 00                	push   $0x0
  pushl $52
80106bec:	6a 34                	push   $0x34
  jmp alltraps
80106bee:	e9 a1 f7 ff ff       	jmp    80106394 <alltraps>

80106bf3 <vector53>:
.globl vector53
vector53:
  pushl $0
80106bf3:	6a 00                	push   $0x0
  pushl $53
80106bf5:	6a 35                	push   $0x35
  jmp alltraps
80106bf7:	e9 98 f7 ff ff       	jmp    80106394 <alltraps>

80106bfc <vector54>:
.globl vector54
vector54:
  pushl $0
80106bfc:	6a 00                	push   $0x0
  pushl $54
80106bfe:	6a 36                	push   $0x36
  jmp alltraps
80106c00:	e9 8f f7 ff ff       	jmp    80106394 <alltraps>

80106c05 <vector55>:
.globl vector55
vector55:
  pushl $0
80106c05:	6a 00                	push   $0x0
  pushl $55
80106c07:	6a 37                	push   $0x37
  jmp alltraps
80106c09:	e9 86 f7 ff ff       	jmp    80106394 <alltraps>

80106c0e <vector56>:
.globl vector56
vector56:
  pushl $0
80106c0e:	6a 00                	push   $0x0
  pushl $56
80106c10:	6a 38                	push   $0x38
  jmp alltraps
80106c12:	e9 7d f7 ff ff       	jmp    80106394 <alltraps>

80106c17 <vector57>:
.globl vector57
vector57:
  pushl $0
80106c17:	6a 00                	push   $0x0
  pushl $57
80106c19:	6a 39                	push   $0x39
  jmp alltraps
80106c1b:	e9 74 f7 ff ff       	jmp    80106394 <alltraps>

80106c20 <vector58>:
.globl vector58
vector58:
  pushl $0
80106c20:	6a 00                	push   $0x0
  pushl $58
80106c22:	6a 3a                	push   $0x3a
  jmp alltraps
80106c24:	e9 6b f7 ff ff       	jmp    80106394 <alltraps>

80106c29 <vector59>:
.globl vector59
vector59:
  pushl $0
80106c29:	6a 00                	push   $0x0
  pushl $59
80106c2b:	6a 3b                	push   $0x3b
  jmp alltraps
80106c2d:	e9 62 f7 ff ff       	jmp    80106394 <alltraps>

80106c32 <vector60>:
.globl vector60
vector60:
  pushl $0
80106c32:	6a 00                	push   $0x0
  pushl $60
80106c34:	6a 3c                	push   $0x3c
  jmp alltraps
80106c36:	e9 59 f7 ff ff       	jmp    80106394 <alltraps>

80106c3b <vector61>:
.globl vector61
vector61:
  pushl $0
80106c3b:	6a 00                	push   $0x0
  pushl $61
80106c3d:	6a 3d                	push   $0x3d
  jmp alltraps
80106c3f:	e9 50 f7 ff ff       	jmp    80106394 <alltraps>

80106c44 <vector62>:
.globl vector62
vector62:
  pushl $0
80106c44:	6a 00                	push   $0x0
  pushl $62
80106c46:	6a 3e                	push   $0x3e
  jmp alltraps
80106c48:	e9 47 f7 ff ff       	jmp    80106394 <alltraps>

80106c4d <vector63>:
.globl vector63
vector63:
  pushl $0
80106c4d:	6a 00                	push   $0x0
  pushl $63
80106c4f:	6a 3f                	push   $0x3f
  jmp alltraps
80106c51:	e9 3e f7 ff ff       	jmp    80106394 <alltraps>

80106c56 <vector64>:
.globl vector64
vector64:
  pushl $0
80106c56:	6a 00                	push   $0x0
  pushl $64
80106c58:	6a 40                	push   $0x40
  jmp alltraps
80106c5a:	e9 35 f7 ff ff       	jmp    80106394 <alltraps>

80106c5f <vector65>:
.globl vector65
vector65:
  pushl $0
80106c5f:	6a 00                	push   $0x0
  pushl $65
80106c61:	6a 41                	push   $0x41
  jmp alltraps
80106c63:	e9 2c f7 ff ff       	jmp    80106394 <alltraps>

80106c68 <vector66>:
.globl vector66
vector66:
  pushl $0
80106c68:	6a 00                	push   $0x0
  pushl $66
80106c6a:	6a 42                	push   $0x42
  jmp alltraps
80106c6c:	e9 23 f7 ff ff       	jmp    80106394 <alltraps>

80106c71 <vector67>:
.globl vector67
vector67:
  pushl $0
80106c71:	6a 00                	push   $0x0
  pushl $67
80106c73:	6a 43                	push   $0x43
  jmp alltraps
80106c75:	e9 1a f7 ff ff       	jmp    80106394 <alltraps>

80106c7a <vector68>:
.globl vector68
vector68:
  pushl $0
80106c7a:	6a 00                	push   $0x0
  pushl $68
80106c7c:	6a 44                	push   $0x44
  jmp alltraps
80106c7e:	e9 11 f7 ff ff       	jmp    80106394 <alltraps>

80106c83 <vector69>:
.globl vector69
vector69:
  pushl $0
80106c83:	6a 00                	push   $0x0
  pushl $69
80106c85:	6a 45                	push   $0x45
  jmp alltraps
80106c87:	e9 08 f7 ff ff       	jmp    80106394 <alltraps>

80106c8c <vector70>:
.globl vector70
vector70:
  pushl $0
80106c8c:	6a 00                	push   $0x0
  pushl $70
80106c8e:	6a 46                	push   $0x46
  jmp alltraps
80106c90:	e9 ff f6 ff ff       	jmp    80106394 <alltraps>

80106c95 <vector71>:
.globl vector71
vector71:
  pushl $0
80106c95:	6a 00                	push   $0x0
  pushl $71
80106c97:	6a 47                	push   $0x47
  jmp alltraps
80106c99:	e9 f6 f6 ff ff       	jmp    80106394 <alltraps>

80106c9e <vector72>:
.globl vector72
vector72:
  pushl $0
80106c9e:	6a 00                	push   $0x0
  pushl $72
80106ca0:	6a 48                	push   $0x48
  jmp alltraps
80106ca2:	e9 ed f6 ff ff       	jmp    80106394 <alltraps>

80106ca7 <vector73>:
.globl vector73
vector73:
  pushl $0
80106ca7:	6a 00                	push   $0x0
  pushl $73
80106ca9:	6a 49                	push   $0x49
  jmp alltraps
80106cab:	e9 e4 f6 ff ff       	jmp    80106394 <alltraps>

80106cb0 <vector74>:
.globl vector74
vector74:
  pushl $0
80106cb0:	6a 00                	push   $0x0
  pushl $74
80106cb2:	6a 4a                	push   $0x4a
  jmp alltraps
80106cb4:	e9 db f6 ff ff       	jmp    80106394 <alltraps>

80106cb9 <vector75>:
.globl vector75
vector75:
  pushl $0
80106cb9:	6a 00                	push   $0x0
  pushl $75
80106cbb:	6a 4b                	push   $0x4b
  jmp alltraps
80106cbd:	e9 d2 f6 ff ff       	jmp    80106394 <alltraps>

80106cc2 <vector76>:
.globl vector76
vector76:
  pushl $0
80106cc2:	6a 00                	push   $0x0
  pushl $76
80106cc4:	6a 4c                	push   $0x4c
  jmp alltraps
80106cc6:	e9 c9 f6 ff ff       	jmp    80106394 <alltraps>

80106ccb <vector77>:
.globl vector77
vector77:
  pushl $0
80106ccb:	6a 00                	push   $0x0
  pushl $77
80106ccd:	6a 4d                	push   $0x4d
  jmp alltraps
80106ccf:	e9 c0 f6 ff ff       	jmp    80106394 <alltraps>

80106cd4 <vector78>:
.globl vector78
vector78:
  pushl $0
80106cd4:	6a 00                	push   $0x0
  pushl $78
80106cd6:	6a 4e                	push   $0x4e
  jmp alltraps
80106cd8:	e9 b7 f6 ff ff       	jmp    80106394 <alltraps>

80106cdd <vector79>:
.globl vector79
vector79:
  pushl $0
80106cdd:	6a 00                	push   $0x0
  pushl $79
80106cdf:	6a 4f                	push   $0x4f
  jmp alltraps
80106ce1:	e9 ae f6 ff ff       	jmp    80106394 <alltraps>

80106ce6 <vector80>:
.globl vector80
vector80:
  pushl $0
80106ce6:	6a 00                	push   $0x0
  pushl $80
80106ce8:	6a 50                	push   $0x50
  jmp alltraps
80106cea:	e9 a5 f6 ff ff       	jmp    80106394 <alltraps>

80106cef <vector81>:
.globl vector81
vector81:
  pushl $0
80106cef:	6a 00                	push   $0x0
  pushl $81
80106cf1:	6a 51                	push   $0x51
  jmp alltraps
80106cf3:	e9 9c f6 ff ff       	jmp    80106394 <alltraps>

80106cf8 <vector82>:
.globl vector82
vector82:
  pushl $0
80106cf8:	6a 00                	push   $0x0
  pushl $82
80106cfa:	6a 52                	push   $0x52
  jmp alltraps
80106cfc:	e9 93 f6 ff ff       	jmp    80106394 <alltraps>

80106d01 <vector83>:
.globl vector83
vector83:
  pushl $0
80106d01:	6a 00                	push   $0x0
  pushl $83
80106d03:	6a 53                	push   $0x53
  jmp alltraps
80106d05:	e9 8a f6 ff ff       	jmp    80106394 <alltraps>

80106d0a <vector84>:
.globl vector84
vector84:
  pushl $0
80106d0a:	6a 00                	push   $0x0
  pushl $84
80106d0c:	6a 54                	push   $0x54
  jmp alltraps
80106d0e:	e9 81 f6 ff ff       	jmp    80106394 <alltraps>

80106d13 <vector85>:
.globl vector85
vector85:
  pushl $0
80106d13:	6a 00                	push   $0x0
  pushl $85
80106d15:	6a 55                	push   $0x55
  jmp alltraps
80106d17:	e9 78 f6 ff ff       	jmp    80106394 <alltraps>

80106d1c <vector86>:
.globl vector86
vector86:
  pushl $0
80106d1c:	6a 00                	push   $0x0
  pushl $86
80106d1e:	6a 56                	push   $0x56
  jmp alltraps
80106d20:	e9 6f f6 ff ff       	jmp    80106394 <alltraps>

80106d25 <vector87>:
.globl vector87
vector87:
  pushl $0
80106d25:	6a 00                	push   $0x0
  pushl $87
80106d27:	6a 57                	push   $0x57
  jmp alltraps
80106d29:	e9 66 f6 ff ff       	jmp    80106394 <alltraps>

80106d2e <vector88>:
.globl vector88
vector88:
  pushl $0
80106d2e:	6a 00                	push   $0x0
  pushl $88
80106d30:	6a 58                	push   $0x58
  jmp alltraps
80106d32:	e9 5d f6 ff ff       	jmp    80106394 <alltraps>

80106d37 <vector89>:
.globl vector89
vector89:
  pushl $0
80106d37:	6a 00                	push   $0x0
  pushl $89
80106d39:	6a 59                	push   $0x59
  jmp alltraps
80106d3b:	e9 54 f6 ff ff       	jmp    80106394 <alltraps>

80106d40 <vector90>:
.globl vector90
vector90:
  pushl $0
80106d40:	6a 00                	push   $0x0
  pushl $90
80106d42:	6a 5a                	push   $0x5a
  jmp alltraps
80106d44:	e9 4b f6 ff ff       	jmp    80106394 <alltraps>

80106d49 <vector91>:
.globl vector91
vector91:
  pushl $0
80106d49:	6a 00                	push   $0x0
  pushl $91
80106d4b:	6a 5b                	push   $0x5b
  jmp alltraps
80106d4d:	e9 42 f6 ff ff       	jmp    80106394 <alltraps>

80106d52 <vector92>:
.globl vector92
vector92:
  pushl $0
80106d52:	6a 00                	push   $0x0
  pushl $92
80106d54:	6a 5c                	push   $0x5c
  jmp alltraps
80106d56:	e9 39 f6 ff ff       	jmp    80106394 <alltraps>

80106d5b <vector93>:
.globl vector93
vector93:
  pushl $0
80106d5b:	6a 00                	push   $0x0
  pushl $93
80106d5d:	6a 5d                	push   $0x5d
  jmp alltraps
80106d5f:	e9 30 f6 ff ff       	jmp    80106394 <alltraps>

80106d64 <vector94>:
.globl vector94
vector94:
  pushl $0
80106d64:	6a 00                	push   $0x0
  pushl $94
80106d66:	6a 5e                	push   $0x5e
  jmp alltraps
80106d68:	e9 27 f6 ff ff       	jmp    80106394 <alltraps>

80106d6d <vector95>:
.globl vector95
vector95:
  pushl $0
80106d6d:	6a 00                	push   $0x0
  pushl $95
80106d6f:	6a 5f                	push   $0x5f
  jmp alltraps
80106d71:	e9 1e f6 ff ff       	jmp    80106394 <alltraps>

80106d76 <vector96>:
.globl vector96
vector96:
  pushl $0
80106d76:	6a 00                	push   $0x0
  pushl $96
80106d78:	6a 60                	push   $0x60
  jmp alltraps
80106d7a:	e9 15 f6 ff ff       	jmp    80106394 <alltraps>

80106d7f <vector97>:
.globl vector97
vector97:
  pushl $0
80106d7f:	6a 00                	push   $0x0
  pushl $97
80106d81:	6a 61                	push   $0x61
  jmp alltraps
80106d83:	e9 0c f6 ff ff       	jmp    80106394 <alltraps>

80106d88 <vector98>:
.globl vector98
vector98:
  pushl $0
80106d88:	6a 00                	push   $0x0
  pushl $98
80106d8a:	6a 62                	push   $0x62
  jmp alltraps
80106d8c:	e9 03 f6 ff ff       	jmp    80106394 <alltraps>

80106d91 <vector99>:
.globl vector99
vector99:
  pushl $0
80106d91:	6a 00                	push   $0x0
  pushl $99
80106d93:	6a 63                	push   $0x63
  jmp alltraps
80106d95:	e9 fa f5 ff ff       	jmp    80106394 <alltraps>

80106d9a <vector100>:
.globl vector100
vector100:
  pushl $0
80106d9a:	6a 00                	push   $0x0
  pushl $100
80106d9c:	6a 64                	push   $0x64
  jmp alltraps
80106d9e:	e9 f1 f5 ff ff       	jmp    80106394 <alltraps>

80106da3 <vector101>:
.globl vector101
vector101:
  pushl $0
80106da3:	6a 00                	push   $0x0
  pushl $101
80106da5:	6a 65                	push   $0x65
  jmp alltraps
80106da7:	e9 e8 f5 ff ff       	jmp    80106394 <alltraps>

80106dac <vector102>:
.globl vector102
vector102:
  pushl $0
80106dac:	6a 00                	push   $0x0
  pushl $102
80106dae:	6a 66                	push   $0x66
  jmp alltraps
80106db0:	e9 df f5 ff ff       	jmp    80106394 <alltraps>

80106db5 <vector103>:
.globl vector103
vector103:
  pushl $0
80106db5:	6a 00                	push   $0x0
  pushl $103
80106db7:	6a 67                	push   $0x67
  jmp alltraps
80106db9:	e9 d6 f5 ff ff       	jmp    80106394 <alltraps>

80106dbe <vector104>:
.globl vector104
vector104:
  pushl $0
80106dbe:	6a 00                	push   $0x0
  pushl $104
80106dc0:	6a 68                	push   $0x68
  jmp alltraps
80106dc2:	e9 cd f5 ff ff       	jmp    80106394 <alltraps>

80106dc7 <vector105>:
.globl vector105
vector105:
  pushl $0
80106dc7:	6a 00                	push   $0x0
  pushl $105
80106dc9:	6a 69                	push   $0x69
  jmp alltraps
80106dcb:	e9 c4 f5 ff ff       	jmp    80106394 <alltraps>

80106dd0 <vector106>:
.globl vector106
vector106:
  pushl $0
80106dd0:	6a 00                	push   $0x0
  pushl $106
80106dd2:	6a 6a                	push   $0x6a
  jmp alltraps
80106dd4:	e9 bb f5 ff ff       	jmp    80106394 <alltraps>

80106dd9 <vector107>:
.globl vector107
vector107:
  pushl $0
80106dd9:	6a 00                	push   $0x0
  pushl $107
80106ddb:	6a 6b                	push   $0x6b
  jmp alltraps
80106ddd:	e9 b2 f5 ff ff       	jmp    80106394 <alltraps>

80106de2 <vector108>:
.globl vector108
vector108:
  pushl $0
80106de2:	6a 00                	push   $0x0
  pushl $108
80106de4:	6a 6c                	push   $0x6c
  jmp alltraps
80106de6:	e9 a9 f5 ff ff       	jmp    80106394 <alltraps>

80106deb <vector109>:
.globl vector109
vector109:
  pushl $0
80106deb:	6a 00                	push   $0x0
  pushl $109
80106ded:	6a 6d                	push   $0x6d
  jmp alltraps
80106def:	e9 a0 f5 ff ff       	jmp    80106394 <alltraps>

80106df4 <vector110>:
.globl vector110
vector110:
  pushl $0
80106df4:	6a 00                	push   $0x0
  pushl $110
80106df6:	6a 6e                	push   $0x6e
  jmp alltraps
80106df8:	e9 97 f5 ff ff       	jmp    80106394 <alltraps>

80106dfd <vector111>:
.globl vector111
vector111:
  pushl $0
80106dfd:	6a 00                	push   $0x0
  pushl $111
80106dff:	6a 6f                	push   $0x6f
  jmp alltraps
80106e01:	e9 8e f5 ff ff       	jmp    80106394 <alltraps>

80106e06 <vector112>:
.globl vector112
vector112:
  pushl $0
80106e06:	6a 00                	push   $0x0
  pushl $112
80106e08:	6a 70                	push   $0x70
  jmp alltraps
80106e0a:	e9 85 f5 ff ff       	jmp    80106394 <alltraps>

80106e0f <vector113>:
.globl vector113
vector113:
  pushl $0
80106e0f:	6a 00                	push   $0x0
  pushl $113
80106e11:	6a 71                	push   $0x71
  jmp alltraps
80106e13:	e9 7c f5 ff ff       	jmp    80106394 <alltraps>

80106e18 <vector114>:
.globl vector114
vector114:
  pushl $0
80106e18:	6a 00                	push   $0x0
  pushl $114
80106e1a:	6a 72                	push   $0x72
  jmp alltraps
80106e1c:	e9 73 f5 ff ff       	jmp    80106394 <alltraps>

80106e21 <vector115>:
.globl vector115
vector115:
  pushl $0
80106e21:	6a 00                	push   $0x0
  pushl $115
80106e23:	6a 73                	push   $0x73
  jmp alltraps
80106e25:	e9 6a f5 ff ff       	jmp    80106394 <alltraps>

80106e2a <vector116>:
.globl vector116
vector116:
  pushl $0
80106e2a:	6a 00                	push   $0x0
  pushl $116
80106e2c:	6a 74                	push   $0x74
  jmp alltraps
80106e2e:	e9 61 f5 ff ff       	jmp    80106394 <alltraps>

80106e33 <vector117>:
.globl vector117
vector117:
  pushl $0
80106e33:	6a 00                	push   $0x0
  pushl $117
80106e35:	6a 75                	push   $0x75
  jmp alltraps
80106e37:	e9 58 f5 ff ff       	jmp    80106394 <alltraps>

80106e3c <vector118>:
.globl vector118
vector118:
  pushl $0
80106e3c:	6a 00                	push   $0x0
  pushl $118
80106e3e:	6a 76                	push   $0x76
  jmp alltraps
80106e40:	e9 4f f5 ff ff       	jmp    80106394 <alltraps>

80106e45 <vector119>:
.globl vector119
vector119:
  pushl $0
80106e45:	6a 00                	push   $0x0
  pushl $119
80106e47:	6a 77                	push   $0x77
  jmp alltraps
80106e49:	e9 46 f5 ff ff       	jmp    80106394 <alltraps>

80106e4e <vector120>:
.globl vector120
vector120:
  pushl $0
80106e4e:	6a 00                	push   $0x0
  pushl $120
80106e50:	6a 78                	push   $0x78
  jmp alltraps
80106e52:	e9 3d f5 ff ff       	jmp    80106394 <alltraps>

80106e57 <vector121>:
.globl vector121
vector121:
  pushl $0
80106e57:	6a 00                	push   $0x0
  pushl $121
80106e59:	6a 79                	push   $0x79
  jmp alltraps
80106e5b:	e9 34 f5 ff ff       	jmp    80106394 <alltraps>

80106e60 <vector122>:
.globl vector122
vector122:
  pushl $0
80106e60:	6a 00                	push   $0x0
  pushl $122
80106e62:	6a 7a                	push   $0x7a
  jmp alltraps
80106e64:	e9 2b f5 ff ff       	jmp    80106394 <alltraps>

80106e69 <vector123>:
.globl vector123
vector123:
  pushl $0
80106e69:	6a 00                	push   $0x0
  pushl $123
80106e6b:	6a 7b                	push   $0x7b
  jmp alltraps
80106e6d:	e9 22 f5 ff ff       	jmp    80106394 <alltraps>

80106e72 <vector124>:
.globl vector124
vector124:
  pushl $0
80106e72:	6a 00                	push   $0x0
  pushl $124
80106e74:	6a 7c                	push   $0x7c
  jmp alltraps
80106e76:	e9 19 f5 ff ff       	jmp    80106394 <alltraps>

80106e7b <vector125>:
.globl vector125
vector125:
  pushl $0
80106e7b:	6a 00                	push   $0x0
  pushl $125
80106e7d:	6a 7d                	push   $0x7d
  jmp alltraps
80106e7f:	e9 10 f5 ff ff       	jmp    80106394 <alltraps>

80106e84 <vector126>:
.globl vector126
vector126:
  pushl $0
80106e84:	6a 00                	push   $0x0
  pushl $126
80106e86:	6a 7e                	push   $0x7e
  jmp alltraps
80106e88:	e9 07 f5 ff ff       	jmp    80106394 <alltraps>

80106e8d <vector127>:
.globl vector127
vector127:
  pushl $0
80106e8d:	6a 00                	push   $0x0
  pushl $127
80106e8f:	6a 7f                	push   $0x7f
  jmp alltraps
80106e91:	e9 fe f4 ff ff       	jmp    80106394 <alltraps>

80106e96 <vector128>:
.globl vector128
vector128:
  pushl $0
80106e96:	6a 00                	push   $0x0
  pushl $128
80106e98:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80106e9d:	e9 f2 f4 ff ff       	jmp    80106394 <alltraps>

80106ea2 <vector129>:
.globl vector129
vector129:
  pushl $0
80106ea2:	6a 00                	push   $0x0
  pushl $129
80106ea4:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80106ea9:	e9 e6 f4 ff ff       	jmp    80106394 <alltraps>

80106eae <vector130>:
.globl vector130
vector130:
  pushl $0
80106eae:	6a 00                	push   $0x0
  pushl $130
80106eb0:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80106eb5:	e9 da f4 ff ff       	jmp    80106394 <alltraps>

80106eba <vector131>:
.globl vector131
vector131:
  pushl $0
80106eba:	6a 00                	push   $0x0
  pushl $131
80106ebc:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80106ec1:	e9 ce f4 ff ff       	jmp    80106394 <alltraps>

80106ec6 <vector132>:
.globl vector132
vector132:
  pushl $0
80106ec6:	6a 00                	push   $0x0
  pushl $132
80106ec8:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80106ecd:	e9 c2 f4 ff ff       	jmp    80106394 <alltraps>

80106ed2 <vector133>:
.globl vector133
vector133:
  pushl $0
80106ed2:	6a 00                	push   $0x0
  pushl $133
80106ed4:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80106ed9:	e9 b6 f4 ff ff       	jmp    80106394 <alltraps>

80106ede <vector134>:
.globl vector134
vector134:
  pushl $0
80106ede:	6a 00                	push   $0x0
  pushl $134
80106ee0:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80106ee5:	e9 aa f4 ff ff       	jmp    80106394 <alltraps>

80106eea <vector135>:
.globl vector135
vector135:
  pushl $0
80106eea:	6a 00                	push   $0x0
  pushl $135
80106eec:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80106ef1:	e9 9e f4 ff ff       	jmp    80106394 <alltraps>

80106ef6 <vector136>:
.globl vector136
vector136:
  pushl $0
80106ef6:	6a 00                	push   $0x0
  pushl $136
80106ef8:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80106efd:	e9 92 f4 ff ff       	jmp    80106394 <alltraps>

80106f02 <vector137>:
.globl vector137
vector137:
  pushl $0
80106f02:	6a 00                	push   $0x0
  pushl $137
80106f04:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80106f09:	e9 86 f4 ff ff       	jmp    80106394 <alltraps>

80106f0e <vector138>:
.globl vector138
vector138:
  pushl $0
80106f0e:	6a 00                	push   $0x0
  pushl $138
80106f10:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80106f15:	e9 7a f4 ff ff       	jmp    80106394 <alltraps>

80106f1a <vector139>:
.globl vector139
vector139:
  pushl $0
80106f1a:	6a 00                	push   $0x0
  pushl $139
80106f1c:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80106f21:	e9 6e f4 ff ff       	jmp    80106394 <alltraps>

80106f26 <vector140>:
.globl vector140
vector140:
  pushl $0
80106f26:	6a 00                	push   $0x0
  pushl $140
80106f28:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80106f2d:	e9 62 f4 ff ff       	jmp    80106394 <alltraps>

80106f32 <vector141>:
.globl vector141
vector141:
  pushl $0
80106f32:	6a 00                	push   $0x0
  pushl $141
80106f34:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80106f39:	e9 56 f4 ff ff       	jmp    80106394 <alltraps>

80106f3e <vector142>:
.globl vector142
vector142:
  pushl $0
80106f3e:	6a 00                	push   $0x0
  pushl $142
80106f40:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80106f45:	e9 4a f4 ff ff       	jmp    80106394 <alltraps>

80106f4a <vector143>:
.globl vector143
vector143:
  pushl $0
80106f4a:	6a 00                	push   $0x0
  pushl $143
80106f4c:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80106f51:	e9 3e f4 ff ff       	jmp    80106394 <alltraps>

80106f56 <vector144>:
.globl vector144
vector144:
  pushl $0
80106f56:	6a 00                	push   $0x0
  pushl $144
80106f58:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80106f5d:	e9 32 f4 ff ff       	jmp    80106394 <alltraps>

80106f62 <vector145>:
.globl vector145
vector145:
  pushl $0
80106f62:	6a 00                	push   $0x0
  pushl $145
80106f64:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80106f69:	e9 26 f4 ff ff       	jmp    80106394 <alltraps>

80106f6e <vector146>:
.globl vector146
vector146:
  pushl $0
80106f6e:	6a 00                	push   $0x0
  pushl $146
80106f70:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80106f75:	e9 1a f4 ff ff       	jmp    80106394 <alltraps>

80106f7a <vector147>:
.globl vector147
vector147:
  pushl $0
80106f7a:	6a 00                	push   $0x0
  pushl $147
80106f7c:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80106f81:	e9 0e f4 ff ff       	jmp    80106394 <alltraps>

80106f86 <vector148>:
.globl vector148
vector148:
  pushl $0
80106f86:	6a 00                	push   $0x0
  pushl $148
80106f88:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80106f8d:	e9 02 f4 ff ff       	jmp    80106394 <alltraps>

80106f92 <vector149>:
.globl vector149
vector149:
  pushl $0
80106f92:	6a 00                	push   $0x0
  pushl $149
80106f94:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80106f99:	e9 f6 f3 ff ff       	jmp    80106394 <alltraps>

80106f9e <vector150>:
.globl vector150
vector150:
  pushl $0
80106f9e:	6a 00                	push   $0x0
  pushl $150
80106fa0:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80106fa5:	e9 ea f3 ff ff       	jmp    80106394 <alltraps>

80106faa <vector151>:
.globl vector151
vector151:
  pushl $0
80106faa:	6a 00                	push   $0x0
  pushl $151
80106fac:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80106fb1:	e9 de f3 ff ff       	jmp    80106394 <alltraps>

80106fb6 <vector152>:
.globl vector152
vector152:
  pushl $0
80106fb6:	6a 00                	push   $0x0
  pushl $152
80106fb8:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80106fbd:	e9 d2 f3 ff ff       	jmp    80106394 <alltraps>

80106fc2 <vector153>:
.globl vector153
vector153:
  pushl $0
80106fc2:	6a 00                	push   $0x0
  pushl $153
80106fc4:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80106fc9:	e9 c6 f3 ff ff       	jmp    80106394 <alltraps>

80106fce <vector154>:
.globl vector154
vector154:
  pushl $0
80106fce:	6a 00                	push   $0x0
  pushl $154
80106fd0:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80106fd5:	e9 ba f3 ff ff       	jmp    80106394 <alltraps>

80106fda <vector155>:
.globl vector155
vector155:
  pushl $0
80106fda:	6a 00                	push   $0x0
  pushl $155
80106fdc:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80106fe1:	e9 ae f3 ff ff       	jmp    80106394 <alltraps>

80106fe6 <vector156>:
.globl vector156
vector156:
  pushl $0
80106fe6:	6a 00                	push   $0x0
  pushl $156
80106fe8:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80106fed:	e9 a2 f3 ff ff       	jmp    80106394 <alltraps>

80106ff2 <vector157>:
.globl vector157
vector157:
  pushl $0
80106ff2:	6a 00                	push   $0x0
  pushl $157
80106ff4:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80106ff9:	e9 96 f3 ff ff       	jmp    80106394 <alltraps>

80106ffe <vector158>:
.globl vector158
vector158:
  pushl $0
80106ffe:	6a 00                	push   $0x0
  pushl $158
80107000:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107005:	e9 8a f3 ff ff       	jmp    80106394 <alltraps>

8010700a <vector159>:
.globl vector159
vector159:
  pushl $0
8010700a:	6a 00                	push   $0x0
  pushl $159
8010700c:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107011:	e9 7e f3 ff ff       	jmp    80106394 <alltraps>

80107016 <vector160>:
.globl vector160
vector160:
  pushl $0
80107016:	6a 00                	push   $0x0
  pushl $160
80107018:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
8010701d:	e9 72 f3 ff ff       	jmp    80106394 <alltraps>

80107022 <vector161>:
.globl vector161
vector161:
  pushl $0
80107022:	6a 00                	push   $0x0
  pushl $161
80107024:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107029:	e9 66 f3 ff ff       	jmp    80106394 <alltraps>

8010702e <vector162>:
.globl vector162
vector162:
  pushl $0
8010702e:	6a 00                	push   $0x0
  pushl $162
80107030:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107035:	e9 5a f3 ff ff       	jmp    80106394 <alltraps>

8010703a <vector163>:
.globl vector163
vector163:
  pushl $0
8010703a:	6a 00                	push   $0x0
  pushl $163
8010703c:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107041:	e9 4e f3 ff ff       	jmp    80106394 <alltraps>

80107046 <vector164>:
.globl vector164
vector164:
  pushl $0
80107046:	6a 00                	push   $0x0
  pushl $164
80107048:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
8010704d:	e9 42 f3 ff ff       	jmp    80106394 <alltraps>

80107052 <vector165>:
.globl vector165
vector165:
  pushl $0
80107052:	6a 00                	push   $0x0
  pushl $165
80107054:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107059:	e9 36 f3 ff ff       	jmp    80106394 <alltraps>

8010705e <vector166>:
.globl vector166
vector166:
  pushl $0
8010705e:	6a 00                	push   $0x0
  pushl $166
80107060:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107065:	e9 2a f3 ff ff       	jmp    80106394 <alltraps>

8010706a <vector167>:
.globl vector167
vector167:
  pushl $0
8010706a:	6a 00                	push   $0x0
  pushl $167
8010706c:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107071:	e9 1e f3 ff ff       	jmp    80106394 <alltraps>

80107076 <vector168>:
.globl vector168
vector168:
  pushl $0
80107076:	6a 00                	push   $0x0
  pushl $168
80107078:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
8010707d:	e9 12 f3 ff ff       	jmp    80106394 <alltraps>

80107082 <vector169>:
.globl vector169
vector169:
  pushl $0
80107082:	6a 00                	push   $0x0
  pushl $169
80107084:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107089:	e9 06 f3 ff ff       	jmp    80106394 <alltraps>

8010708e <vector170>:
.globl vector170
vector170:
  pushl $0
8010708e:	6a 00                	push   $0x0
  pushl $170
80107090:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107095:	e9 fa f2 ff ff       	jmp    80106394 <alltraps>

8010709a <vector171>:
.globl vector171
vector171:
  pushl $0
8010709a:	6a 00                	push   $0x0
  pushl $171
8010709c:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801070a1:	e9 ee f2 ff ff       	jmp    80106394 <alltraps>

801070a6 <vector172>:
.globl vector172
vector172:
  pushl $0
801070a6:	6a 00                	push   $0x0
  pushl $172
801070a8:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801070ad:	e9 e2 f2 ff ff       	jmp    80106394 <alltraps>

801070b2 <vector173>:
.globl vector173
vector173:
  pushl $0
801070b2:	6a 00                	push   $0x0
  pushl $173
801070b4:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801070b9:	e9 d6 f2 ff ff       	jmp    80106394 <alltraps>

801070be <vector174>:
.globl vector174
vector174:
  pushl $0
801070be:	6a 00                	push   $0x0
  pushl $174
801070c0:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801070c5:	e9 ca f2 ff ff       	jmp    80106394 <alltraps>

801070ca <vector175>:
.globl vector175
vector175:
  pushl $0
801070ca:	6a 00                	push   $0x0
  pushl $175
801070cc:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
801070d1:	e9 be f2 ff ff       	jmp    80106394 <alltraps>

801070d6 <vector176>:
.globl vector176
vector176:
  pushl $0
801070d6:	6a 00                	push   $0x0
  pushl $176
801070d8:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
801070dd:	e9 b2 f2 ff ff       	jmp    80106394 <alltraps>

801070e2 <vector177>:
.globl vector177
vector177:
  pushl $0
801070e2:	6a 00                	push   $0x0
  pushl $177
801070e4:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801070e9:	e9 a6 f2 ff ff       	jmp    80106394 <alltraps>

801070ee <vector178>:
.globl vector178
vector178:
  pushl $0
801070ee:	6a 00                	push   $0x0
  pushl $178
801070f0:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
801070f5:	e9 9a f2 ff ff       	jmp    80106394 <alltraps>

801070fa <vector179>:
.globl vector179
vector179:
  pushl $0
801070fa:	6a 00                	push   $0x0
  pushl $179
801070fc:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107101:	e9 8e f2 ff ff       	jmp    80106394 <alltraps>

80107106 <vector180>:
.globl vector180
vector180:
  pushl $0
80107106:	6a 00                	push   $0x0
  pushl $180
80107108:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
8010710d:	e9 82 f2 ff ff       	jmp    80106394 <alltraps>

80107112 <vector181>:
.globl vector181
vector181:
  pushl $0
80107112:	6a 00                	push   $0x0
  pushl $181
80107114:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107119:	e9 76 f2 ff ff       	jmp    80106394 <alltraps>

8010711e <vector182>:
.globl vector182
vector182:
  pushl $0
8010711e:	6a 00                	push   $0x0
  pushl $182
80107120:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107125:	e9 6a f2 ff ff       	jmp    80106394 <alltraps>

8010712a <vector183>:
.globl vector183
vector183:
  pushl $0
8010712a:	6a 00                	push   $0x0
  pushl $183
8010712c:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107131:	e9 5e f2 ff ff       	jmp    80106394 <alltraps>

80107136 <vector184>:
.globl vector184
vector184:
  pushl $0
80107136:	6a 00                	push   $0x0
  pushl $184
80107138:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
8010713d:	e9 52 f2 ff ff       	jmp    80106394 <alltraps>

80107142 <vector185>:
.globl vector185
vector185:
  pushl $0
80107142:	6a 00                	push   $0x0
  pushl $185
80107144:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107149:	e9 46 f2 ff ff       	jmp    80106394 <alltraps>

8010714e <vector186>:
.globl vector186
vector186:
  pushl $0
8010714e:	6a 00                	push   $0x0
  pushl $186
80107150:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107155:	e9 3a f2 ff ff       	jmp    80106394 <alltraps>

8010715a <vector187>:
.globl vector187
vector187:
  pushl $0
8010715a:	6a 00                	push   $0x0
  pushl $187
8010715c:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107161:	e9 2e f2 ff ff       	jmp    80106394 <alltraps>

80107166 <vector188>:
.globl vector188
vector188:
  pushl $0
80107166:	6a 00                	push   $0x0
  pushl $188
80107168:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
8010716d:	e9 22 f2 ff ff       	jmp    80106394 <alltraps>

80107172 <vector189>:
.globl vector189
vector189:
  pushl $0
80107172:	6a 00                	push   $0x0
  pushl $189
80107174:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107179:	e9 16 f2 ff ff       	jmp    80106394 <alltraps>

8010717e <vector190>:
.globl vector190
vector190:
  pushl $0
8010717e:	6a 00                	push   $0x0
  pushl $190
80107180:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107185:	e9 0a f2 ff ff       	jmp    80106394 <alltraps>

8010718a <vector191>:
.globl vector191
vector191:
  pushl $0
8010718a:	6a 00                	push   $0x0
  pushl $191
8010718c:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107191:	e9 fe f1 ff ff       	jmp    80106394 <alltraps>

80107196 <vector192>:
.globl vector192
vector192:
  pushl $0
80107196:	6a 00                	push   $0x0
  pushl $192
80107198:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
8010719d:	e9 f2 f1 ff ff       	jmp    80106394 <alltraps>

801071a2 <vector193>:
.globl vector193
vector193:
  pushl $0
801071a2:	6a 00                	push   $0x0
  pushl $193
801071a4:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801071a9:	e9 e6 f1 ff ff       	jmp    80106394 <alltraps>

801071ae <vector194>:
.globl vector194
vector194:
  pushl $0
801071ae:	6a 00                	push   $0x0
  pushl $194
801071b0:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801071b5:	e9 da f1 ff ff       	jmp    80106394 <alltraps>

801071ba <vector195>:
.globl vector195
vector195:
  pushl $0
801071ba:	6a 00                	push   $0x0
  pushl $195
801071bc:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
801071c1:	e9 ce f1 ff ff       	jmp    80106394 <alltraps>

801071c6 <vector196>:
.globl vector196
vector196:
  pushl $0
801071c6:	6a 00                	push   $0x0
  pushl $196
801071c8:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
801071cd:	e9 c2 f1 ff ff       	jmp    80106394 <alltraps>

801071d2 <vector197>:
.globl vector197
vector197:
  pushl $0
801071d2:	6a 00                	push   $0x0
  pushl $197
801071d4:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801071d9:	e9 b6 f1 ff ff       	jmp    80106394 <alltraps>

801071de <vector198>:
.globl vector198
vector198:
  pushl $0
801071de:	6a 00                	push   $0x0
  pushl $198
801071e0:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801071e5:	e9 aa f1 ff ff       	jmp    80106394 <alltraps>

801071ea <vector199>:
.globl vector199
vector199:
  pushl $0
801071ea:	6a 00                	push   $0x0
  pushl $199
801071ec:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801071f1:	e9 9e f1 ff ff       	jmp    80106394 <alltraps>

801071f6 <vector200>:
.globl vector200
vector200:
  pushl $0
801071f6:	6a 00                	push   $0x0
  pushl $200
801071f8:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801071fd:	e9 92 f1 ff ff       	jmp    80106394 <alltraps>

80107202 <vector201>:
.globl vector201
vector201:
  pushl $0
80107202:	6a 00                	push   $0x0
  pushl $201
80107204:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107209:	e9 86 f1 ff ff       	jmp    80106394 <alltraps>

8010720e <vector202>:
.globl vector202
vector202:
  pushl $0
8010720e:	6a 00                	push   $0x0
  pushl $202
80107210:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107215:	e9 7a f1 ff ff       	jmp    80106394 <alltraps>

8010721a <vector203>:
.globl vector203
vector203:
  pushl $0
8010721a:	6a 00                	push   $0x0
  pushl $203
8010721c:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107221:	e9 6e f1 ff ff       	jmp    80106394 <alltraps>

80107226 <vector204>:
.globl vector204
vector204:
  pushl $0
80107226:	6a 00                	push   $0x0
  pushl $204
80107228:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
8010722d:	e9 62 f1 ff ff       	jmp    80106394 <alltraps>

80107232 <vector205>:
.globl vector205
vector205:
  pushl $0
80107232:	6a 00                	push   $0x0
  pushl $205
80107234:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107239:	e9 56 f1 ff ff       	jmp    80106394 <alltraps>

8010723e <vector206>:
.globl vector206
vector206:
  pushl $0
8010723e:	6a 00                	push   $0x0
  pushl $206
80107240:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107245:	e9 4a f1 ff ff       	jmp    80106394 <alltraps>

8010724a <vector207>:
.globl vector207
vector207:
  pushl $0
8010724a:	6a 00                	push   $0x0
  pushl $207
8010724c:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107251:	e9 3e f1 ff ff       	jmp    80106394 <alltraps>

80107256 <vector208>:
.globl vector208
vector208:
  pushl $0
80107256:	6a 00                	push   $0x0
  pushl $208
80107258:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
8010725d:	e9 32 f1 ff ff       	jmp    80106394 <alltraps>

80107262 <vector209>:
.globl vector209
vector209:
  pushl $0
80107262:	6a 00                	push   $0x0
  pushl $209
80107264:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107269:	e9 26 f1 ff ff       	jmp    80106394 <alltraps>

8010726e <vector210>:
.globl vector210
vector210:
  pushl $0
8010726e:	6a 00                	push   $0x0
  pushl $210
80107270:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107275:	e9 1a f1 ff ff       	jmp    80106394 <alltraps>

8010727a <vector211>:
.globl vector211
vector211:
  pushl $0
8010727a:	6a 00                	push   $0x0
  pushl $211
8010727c:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107281:	e9 0e f1 ff ff       	jmp    80106394 <alltraps>

80107286 <vector212>:
.globl vector212
vector212:
  pushl $0
80107286:	6a 00                	push   $0x0
  pushl $212
80107288:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
8010728d:	e9 02 f1 ff ff       	jmp    80106394 <alltraps>

80107292 <vector213>:
.globl vector213
vector213:
  pushl $0
80107292:	6a 00                	push   $0x0
  pushl $213
80107294:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107299:	e9 f6 f0 ff ff       	jmp    80106394 <alltraps>

8010729e <vector214>:
.globl vector214
vector214:
  pushl $0
8010729e:	6a 00                	push   $0x0
  pushl $214
801072a0:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
801072a5:	e9 ea f0 ff ff       	jmp    80106394 <alltraps>

801072aa <vector215>:
.globl vector215
vector215:
  pushl $0
801072aa:	6a 00                	push   $0x0
  pushl $215
801072ac:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
801072b1:	e9 de f0 ff ff       	jmp    80106394 <alltraps>

801072b6 <vector216>:
.globl vector216
vector216:
  pushl $0
801072b6:	6a 00                	push   $0x0
  pushl $216
801072b8:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
801072bd:	e9 d2 f0 ff ff       	jmp    80106394 <alltraps>

801072c2 <vector217>:
.globl vector217
vector217:
  pushl $0
801072c2:	6a 00                	push   $0x0
  pushl $217
801072c4:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
801072c9:	e9 c6 f0 ff ff       	jmp    80106394 <alltraps>

801072ce <vector218>:
.globl vector218
vector218:
  pushl $0
801072ce:	6a 00                	push   $0x0
  pushl $218
801072d0:	68 da 00 00 00       	push   $0xda
  jmp alltraps
801072d5:	e9 ba f0 ff ff       	jmp    80106394 <alltraps>

801072da <vector219>:
.globl vector219
vector219:
  pushl $0
801072da:	6a 00                	push   $0x0
  pushl $219
801072dc:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
801072e1:	e9 ae f0 ff ff       	jmp    80106394 <alltraps>

801072e6 <vector220>:
.globl vector220
vector220:
  pushl $0
801072e6:	6a 00                	push   $0x0
  pushl $220
801072e8:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801072ed:	e9 a2 f0 ff ff       	jmp    80106394 <alltraps>

801072f2 <vector221>:
.globl vector221
vector221:
  pushl $0
801072f2:	6a 00                	push   $0x0
  pushl $221
801072f4:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801072f9:	e9 96 f0 ff ff       	jmp    80106394 <alltraps>

801072fe <vector222>:
.globl vector222
vector222:
  pushl $0
801072fe:	6a 00                	push   $0x0
  pushl $222
80107300:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107305:	e9 8a f0 ff ff       	jmp    80106394 <alltraps>

8010730a <vector223>:
.globl vector223
vector223:
  pushl $0
8010730a:	6a 00                	push   $0x0
  pushl $223
8010730c:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107311:	e9 7e f0 ff ff       	jmp    80106394 <alltraps>

80107316 <vector224>:
.globl vector224
vector224:
  pushl $0
80107316:	6a 00                	push   $0x0
  pushl $224
80107318:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
8010731d:	e9 72 f0 ff ff       	jmp    80106394 <alltraps>

80107322 <vector225>:
.globl vector225
vector225:
  pushl $0
80107322:	6a 00                	push   $0x0
  pushl $225
80107324:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107329:	e9 66 f0 ff ff       	jmp    80106394 <alltraps>

8010732e <vector226>:
.globl vector226
vector226:
  pushl $0
8010732e:	6a 00                	push   $0x0
  pushl $226
80107330:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107335:	e9 5a f0 ff ff       	jmp    80106394 <alltraps>

8010733a <vector227>:
.globl vector227
vector227:
  pushl $0
8010733a:	6a 00                	push   $0x0
  pushl $227
8010733c:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107341:	e9 4e f0 ff ff       	jmp    80106394 <alltraps>

80107346 <vector228>:
.globl vector228
vector228:
  pushl $0
80107346:	6a 00                	push   $0x0
  pushl $228
80107348:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
8010734d:	e9 42 f0 ff ff       	jmp    80106394 <alltraps>

80107352 <vector229>:
.globl vector229
vector229:
  pushl $0
80107352:	6a 00                	push   $0x0
  pushl $229
80107354:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107359:	e9 36 f0 ff ff       	jmp    80106394 <alltraps>

8010735e <vector230>:
.globl vector230
vector230:
  pushl $0
8010735e:	6a 00                	push   $0x0
  pushl $230
80107360:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107365:	e9 2a f0 ff ff       	jmp    80106394 <alltraps>

8010736a <vector231>:
.globl vector231
vector231:
  pushl $0
8010736a:	6a 00                	push   $0x0
  pushl $231
8010736c:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107371:	e9 1e f0 ff ff       	jmp    80106394 <alltraps>

80107376 <vector232>:
.globl vector232
vector232:
  pushl $0
80107376:	6a 00                	push   $0x0
  pushl $232
80107378:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
8010737d:	e9 12 f0 ff ff       	jmp    80106394 <alltraps>

80107382 <vector233>:
.globl vector233
vector233:
  pushl $0
80107382:	6a 00                	push   $0x0
  pushl $233
80107384:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107389:	e9 06 f0 ff ff       	jmp    80106394 <alltraps>

8010738e <vector234>:
.globl vector234
vector234:
  pushl $0
8010738e:	6a 00                	push   $0x0
  pushl $234
80107390:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107395:	e9 fa ef ff ff       	jmp    80106394 <alltraps>

8010739a <vector235>:
.globl vector235
vector235:
  pushl $0
8010739a:	6a 00                	push   $0x0
  pushl $235
8010739c:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
801073a1:	e9 ee ef ff ff       	jmp    80106394 <alltraps>

801073a6 <vector236>:
.globl vector236
vector236:
  pushl $0
801073a6:	6a 00                	push   $0x0
  pushl $236
801073a8:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
801073ad:	e9 e2 ef ff ff       	jmp    80106394 <alltraps>

801073b2 <vector237>:
.globl vector237
vector237:
  pushl $0
801073b2:	6a 00                	push   $0x0
  pushl $237
801073b4:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
801073b9:	e9 d6 ef ff ff       	jmp    80106394 <alltraps>

801073be <vector238>:
.globl vector238
vector238:
  pushl $0
801073be:	6a 00                	push   $0x0
  pushl $238
801073c0:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
801073c5:	e9 ca ef ff ff       	jmp    80106394 <alltraps>

801073ca <vector239>:
.globl vector239
vector239:
  pushl $0
801073ca:	6a 00                	push   $0x0
  pushl $239
801073cc:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
801073d1:	e9 be ef ff ff       	jmp    80106394 <alltraps>

801073d6 <vector240>:
.globl vector240
vector240:
  pushl $0
801073d6:	6a 00                	push   $0x0
  pushl $240
801073d8:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
801073dd:	e9 b2 ef ff ff       	jmp    80106394 <alltraps>

801073e2 <vector241>:
.globl vector241
vector241:
  pushl $0
801073e2:	6a 00                	push   $0x0
  pushl $241
801073e4:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801073e9:	e9 a6 ef ff ff       	jmp    80106394 <alltraps>

801073ee <vector242>:
.globl vector242
vector242:
  pushl $0
801073ee:	6a 00                	push   $0x0
  pushl $242
801073f0:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801073f5:	e9 9a ef ff ff       	jmp    80106394 <alltraps>

801073fa <vector243>:
.globl vector243
vector243:
  pushl $0
801073fa:	6a 00                	push   $0x0
  pushl $243
801073fc:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107401:	e9 8e ef ff ff       	jmp    80106394 <alltraps>

80107406 <vector244>:
.globl vector244
vector244:
  pushl $0
80107406:	6a 00                	push   $0x0
  pushl $244
80107408:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
8010740d:	e9 82 ef ff ff       	jmp    80106394 <alltraps>

80107412 <vector245>:
.globl vector245
vector245:
  pushl $0
80107412:	6a 00                	push   $0x0
  pushl $245
80107414:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107419:	e9 76 ef ff ff       	jmp    80106394 <alltraps>

8010741e <vector246>:
.globl vector246
vector246:
  pushl $0
8010741e:	6a 00                	push   $0x0
  pushl $246
80107420:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107425:	e9 6a ef ff ff       	jmp    80106394 <alltraps>

8010742a <vector247>:
.globl vector247
vector247:
  pushl $0
8010742a:	6a 00                	push   $0x0
  pushl $247
8010742c:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107431:	e9 5e ef ff ff       	jmp    80106394 <alltraps>

80107436 <vector248>:
.globl vector248
vector248:
  pushl $0
80107436:	6a 00                	push   $0x0
  pushl $248
80107438:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
8010743d:	e9 52 ef ff ff       	jmp    80106394 <alltraps>

80107442 <vector249>:
.globl vector249
vector249:
  pushl $0
80107442:	6a 00                	push   $0x0
  pushl $249
80107444:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107449:	e9 46 ef ff ff       	jmp    80106394 <alltraps>

8010744e <vector250>:
.globl vector250
vector250:
  pushl $0
8010744e:	6a 00                	push   $0x0
  pushl $250
80107450:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107455:	e9 3a ef ff ff       	jmp    80106394 <alltraps>

8010745a <vector251>:
.globl vector251
vector251:
  pushl $0
8010745a:	6a 00                	push   $0x0
  pushl $251
8010745c:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107461:	e9 2e ef ff ff       	jmp    80106394 <alltraps>

80107466 <vector252>:
.globl vector252
vector252:
  pushl $0
80107466:	6a 00                	push   $0x0
  pushl $252
80107468:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
8010746d:	e9 22 ef ff ff       	jmp    80106394 <alltraps>

80107472 <vector253>:
.globl vector253
vector253:
  pushl $0
80107472:	6a 00                	push   $0x0
  pushl $253
80107474:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107479:	e9 16 ef ff ff       	jmp    80106394 <alltraps>

8010747e <vector254>:
.globl vector254
vector254:
  pushl $0
8010747e:	6a 00                	push   $0x0
  pushl $254
80107480:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107485:	e9 0a ef ff ff       	jmp    80106394 <alltraps>

8010748a <vector255>:
.globl vector255
vector255:
  pushl $0
8010748a:	6a 00                	push   $0x0
  pushl $255
8010748c:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107491:	e9 fe ee ff ff       	jmp    80106394 <alltraps>
80107496:	66 90                	xchg   %ax,%ax

80107498 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107498:	55                   	push   %ebp
80107499:	89 e5                	mov    %esp,%ebp
8010749b:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010749e:	8b 45 0c             	mov    0xc(%ebp),%eax
801074a1:	83 e8 01             	sub    $0x1,%eax
801074a4:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801074a8:	8b 45 08             	mov    0x8(%ebp),%eax
801074ab:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801074af:	8b 45 08             	mov    0x8(%ebp),%eax
801074b2:	c1 e8 10             	shr    $0x10,%eax
801074b5:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
801074b9:	8d 45 fa             	lea    -0x6(%ebp),%eax
801074bc:	0f 01 10             	lgdtl  (%eax)
}
801074bf:	c9                   	leave  
801074c0:	c3                   	ret    

801074c1 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
801074c1:	55                   	push   %ebp
801074c2:	89 e5                	mov    %esp,%ebp
801074c4:	83 ec 04             	sub    $0x4,%esp
801074c7:	8b 45 08             	mov    0x8(%ebp),%eax
801074ca:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
801074ce:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801074d2:	0f 00 d8             	ltr    %ax
}
801074d5:	c9                   	leave  
801074d6:	c3                   	ret    

801074d7 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
801074d7:	55                   	push   %ebp
801074d8:	89 e5                	mov    %esp,%ebp
801074da:	83 ec 04             	sub    $0x4,%esp
801074dd:	8b 45 08             	mov    0x8(%ebp),%eax
801074e0:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
801074e4:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801074e8:	8e e8                	mov    %eax,%gs
}
801074ea:	c9                   	leave  
801074eb:	c3                   	ret    

801074ec <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
801074ec:	55                   	push   %ebp
801074ed:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
801074ef:	8b 45 08             	mov    0x8(%ebp),%eax
801074f2:	0f 22 d8             	mov    %eax,%cr3
}
801074f5:	5d                   	pop    %ebp
801074f6:	c3                   	ret    

801074f7 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801074f7:	55                   	push   %ebp
801074f8:	89 e5                	mov    %esp,%ebp
801074fa:	8b 45 08             	mov    0x8(%ebp),%eax
801074fd:	05 00 00 00 80       	add    $0x80000000,%eax
80107502:	5d                   	pop    %ebp
80107503:	c3                   	ret    

80107504 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107504:	55                   	push   %ebp
80107505:	89 e5                	mov    %esp,%ebp
80107507:	8b 45 08             	mov    0x8(%ebp),%eax
8010750a:	05 00 00 00 80       	add    $0x80000000,%eax
8010750f:	5d                   	pop    %ebp
80107510:	c3                   	ret    

80107511 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107511:	55                   	push   %ebp
80107512:	89 e5                	mov    %esp,%ebp
80107514:	53                   	push   %ebx
80107515:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107518:	e8 bc ba ff ff       	call   80102fd9 <cpunum>
8010751d:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107523:	05 40 fe 10 80       	add    $0x8010fe40,%eax
80107528:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
8010752b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010752e:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80107534:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107537:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
8010753d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107540:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80107544:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107547:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010754b:	83 e2 f0             	and    $0xfffffff0,%edx
8010754e:	83 ca 0a             	or     $0xa,%edx
80107551:	88 50 7d             	mov    %dl,0x7d(%eax)
80107554:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107557:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010755b:	83 ca 10             	or     $0x10,%edx
8010755e:	88 50 7d             	mov    %dl,0x7d(%eax)
80107561:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107564:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107568:	83 e2 9f             	and    $0xffffff9f,%edx
8010756b:	88 50 7d             	mov    %dl,0x7d(%eax)
8010756e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107571:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107575:	83 ca 80             	or     $0xffffff80,%edx
80107578:	88 50 7d             	mov    %dl,0x7d(%eax)
8010757b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010757e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107582:	83 ca 0f             	or     $0xf,%edx
80107585:	88 50 7e             	mov    %dl,0x7e(%eax)
80107588:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010758b:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010758f:	83 e2 ef             	and    $0xffffffef,%edx
80107592:	88 50 7e             	mov    %dl,0x7e(%eax)
80107595:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107598:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010759c:	83 e2 df             	and    $0xffffffdf,%edx
8010759f:	88 50 7e             	mov    %dl,0x7e(%eax)
801075a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075a5:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801075a9:	83 ca 40             	or     $0x40,%edx
801075ac:	88 50 7e             	mov    %dl,0x7e(%eax)
801075af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075b2:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801075b6:	83 ca 80             	or     $0xffffff80,%edx
801075b9:	88 50 7e             	mov    %dl,0x7e(%eax)
801075bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075bf:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801075c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075c6:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801075cd:	ff ff 
801075cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075d2:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801075d9:	00 00 
801075db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075de:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801075e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075e8:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801075ef:	83 e2 f0             	and    $0xfffffff0,%edx
801075f2:	83 ca 02             	or     $0x2,%edx
801075f5:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801075fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075fe:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107605:	83 ca 10             	or     $0x10,%edx
80107608:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010760e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107611:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107618:	83 e2 9f             	and    $0xffffff9f,%edx
8010761b:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107621:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107624:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010762b:	83 ca 80             	or     $0xffffff80,%edx
8010762e:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107634:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107637:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010763e:	83 ca 0f             	or     $0xf,%edx
80107641:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107647:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010764a:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107651:	83 e2 ef             	and    $0xffffffef,%edx
80107654:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010765a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010765d:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107664:	83 e2 df             	and    $0xffffffdf,%edx
80107667:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010766d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107670:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107677:	83 ca 40             	or     $0x40,%edx
8010767a:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107680:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107683:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010768a:	83 ca 80             	or     $0xffffff80,%edx
8010768d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107693:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107696:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
8010769d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076a0:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
801076a7:	ff ff 
801076a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076ac:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
801076b3:	00 00 
801076b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076b8:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
801076bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076c2:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801076c9:	83 e2 f0             	and    $0xfffffff0,%edx
801076cc:	83 ca 0a             	or     $0xa,%edx
801076cf:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801076d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076d8:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801076df:	83 ca 10             	or     $0x10,%edx
801076e2:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801076e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076eb:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801076f2:	83 ca 60             	or     $0x60,%edx
801076f5:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801076fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076fe:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107705:	83 ca 80             	or     $0xffffff80,%edx
80107708:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010770e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107711:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107718:	83 ca 0f             	or     $0xf,%edx
8010771b:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107721:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107724:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010772b:	83 e2 ef             	and    $0xffffffef,%edx
8010772e:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107734:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107737:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010773e:	83 e2 df             	and    $0xffffffdf,%edx
80107741:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107747:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010774a:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107751:	83 ca 40             	or     $0x40,%edx
80107754:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010775a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010775d:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107764:	83 ca 80             	or     $0xffffff80,%edx
80107767:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010776d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107770:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80107777:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010777a:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107781:	ff ff 
80107783:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107786:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
8010778d:	00 00 
8010778f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107792:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80107799:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010779c:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801077a3:	83 e2 f0             	and    $0xfffffff0,%edx
801077a6:	83 ca 02             	or     $0x2,%edx
801077a9:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801077af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077b2:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801077b9:	83 ca 10             	or     $0x10,%edx
801077bc:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801077c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077c5:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801077cc:	83 ca 60             	or     $0x60,%edx
801077cf:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801077d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077d8:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801077df:	83 ca 80             	or     $0xffffff80,%edx
801077e2:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801077e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077eb:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801077f2:	83 ca 0f             	or     $0xf,%edx
801077f5:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801077fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077fe:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107805:	83 e2 ef             	and    $0xffffffef,%edx
80107808:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010780e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107811:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107818:	83 e2 df             	and    $0xffffffdf,%edx
8010781b:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107821:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107824:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010782b:	83 ca 40             	or     $0x40,%edx
8010782e:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107834:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107837:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010783e:	83 ca 80             	or     $0xffffff80,%edx
80107841:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107847:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010784a:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80107851:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107854:	05 b4 00 00 00       	add    $0xb4,%eax
80107859:	89 c3                	mov    %eax,%ebx
8010785b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010785e:	05 b4 00 00 00       	add    $0xb4,%eax
80107863:	c1 e8 10             	shr    $0x10,%eax
80107866:	89 c1                	mov    %eax,%ecx
80107868:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010786b:	05 b4 00 00 00       	add    $0xb4,%eax
80107870:	c1 e8 18             	shr    $0x18,%eax
80107873:	89 c2                	mov    %eax,%edx
80107875:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107878:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
8010787f:	00 00 
80107881:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107884:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
8010788b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010788e:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107894:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107897:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010789e:	83 e1 f0             	and    $0xfffffff0,%ecx
801078a1:	83 c9 02             	or     $0x2,%ecx
801078a4:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801078aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078ad:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801078b4:	83 c9 10             	or     $0x10,%ecx
801078b7:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801078bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078c0:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801078c7:	83 e1 9f             	and    $0xffffff9f,%ecx
801078ca:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801078d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078d3:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801078da:	83 c9 80             	or     $0xffffff80,%ecx
801078dd:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801078e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078e6:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801078ed:	83 e1 f0             	and    $0xfffffff0,%ecx
801078f0:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801078f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078f9:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107900:	83 e1 ef             	and    $0xffffffef,%ecx
80107903:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107909:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010790c:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107913:	83 e1 df             	and    $0xffffffdf,%ecx
80107916:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010791c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010791f:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107926:	83 c9 40             	or     $0x40,%ecx
80107929:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010792f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107932:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107939:	83 c9 80             	or     $0xffffff80,%ecx
8010793c:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107942:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107945:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
8010794b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010794e:	83 c0 70             	add    $0x70,%eax
80107951:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80107958:	00 
80107959:	89 04 24             	mov    %eax,(%esp)
8010795c:	e8 37 fb ff ff       	call   80107498 <lgdt>
  loadgs(SEG_KCPU << 3);
80107961:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80107968:	e8 6a fb ff ff       	call   801074d7 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
8010796d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107970:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80107976:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
8010797d:	00 00 00 00 
}
80107981:	83 c4 24             	add    $0x24,%esp
80107984:	5b                   	pop    %ebx
80107985:	5d                   	pop    %ebp
80107986:	c3                   	ret    

80107987 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80107987:	55                   	push   %ebp
80107988:	89 e5                	mov    %esp,%ebp
8010798a:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
8010798d:	8b 45 0c             	mov    0xc(%ebp),%eax
80107990:	c1 e8 16             	shr    $0x16,%eax
80107993:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010799a:	8b 45 08             	mov    0x8(%ebp),%eax
8010799d:	01 d0                	add    %edx,%eax
8010799f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
801079a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801079a5:	8b 00                	mov    (%eax),%eax
801079a7:	83 e0 01             	and    $0x1,%eax
801079aa:	85 c0                	test   %eax,%eax
801079ac:	74 17                	je     801079c5 <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
801079ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
801079b1:	8b 00                	mov    (%eax),%eax
801079b3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801079b8:	89 04 24             	mov    %eax,(%esp)
801079bb:	e8 44 fb ff ff       	call   80107504 <p2v>
801079c0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801079c3:	eb 4b                	jmp    80107a10 <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
801079c5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801079c9:	74 0e                	je     801079d9 <walkpgdir+0x52>
801079cb:	e8 77 b2 ff ff       	call   80102c47 <kalloc>
801079d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801079d3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801079d7:	75 07                	jne    801079e0 <walkpgdir+0x59>
      return 0;
801079d9:	b8 00 00 00 00       	mov    $0x0,%eax
801079de:	eb 47                	jmp    80107a27 <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
801079e0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801079e7:	00 
801079e8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801079ef:	00 
801079f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079f3:	89 04 24             	mov    %eax,(%esp)
801079f6:	e8 63 d5 ff ff       	call   80104f5e <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
801079fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079fe:	89 04 24             	mov    %eax,(%esp)
80107a01:	e8 f1 fa ff ff       	call   801074f7 <v2p>
80107a06:	89 c2                	mov    %eax,%edx
80107a08:	83 ca 07             	or     $0x7,%edx
80107a0b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107a0e:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107a10:	8b 45 0c             	mov    0xc(%ebp),%eax
80107a13:	c1 e8 0c             	shr    $0xc,%eax
80107a16:	25 ff 03 00 00       	and    $0x3ff,%eax
80107a1b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107a22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a25:	01 d0                	add    %edx,%eax
}
80107a27:	c9                   	leave  
80107a28:	c3                   	ret    

80107a29 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107a29:	55                   	push   %ebp
80107a2a:	89 e5                	mov    %esp,%ebp
80107a2c:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80107a2f:	8b 45 0c             	mov    0xc(%ebp),%eax
80107a32:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107a37:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107a3a:	8b 55 0c             	mov    0xc(%ebp),%edx
80107a3d:	8b 45 10             	mov    0x10(%ebp),%eax
80107a40:	01 d0                	add    %edx,%eax
80107a42:	83 e8 01             	sub    $0x1,%eax
80107a45:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107a4a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107a4d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80107a54:	00 
80107a55:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a58:	89 44 24 04          	mov    %eax,0x4(%esp)
80107a5c:	8b 45 08             	mov    0x8(%ebp),%eax
80107a5f:	89 04 24             	mov    %eax,(%esp)
80107a62:	e8 20 ff ff ff       	call   80107987 <walkpgdir>
80107a67:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107a6a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107a6e:	75 07                	jne    80107a77 <mappages+0x4e>
      return -1;
80107a70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107a75:	eb 46                	jmp    80107abd <mappages+0x94>
    if(*pte & PTE_P)
80107a77:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107a7a:	8b 00                	mov    (%eax),%eax
80107a7c:	83 e0 01             	and    $0x1,%eax
80107a7f:	85 c0                	test   %eax,%eax
80107a81:	74 0c                	je     80107a8f <mappages+0x66>
      panic("remap");
80107a83:	c7 04 24 b4 88 10 80 	movl   $0x801088b4,(%esp)
80107a8a:	e8 b7 8a ff ff       	call   80100546 <panic>
    *pte = pa | perm | PTE_P;
80107a8f:	8b 45 18             	mov    0x18(%ebp),%eax
80107a92:	0b 45 14             	or     0x14(%ebp),%eax
80107a95:	89 c2                	mov    %eax,%edx
80107a97:	83 ca 01             	or     $0x1,%edx
80107a9a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107a9d:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107a9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aa2:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107aa5:	74 10                	je     80107ab7 <mappages+0x8e>
      break;
    a += PGSIZE;
80107aa7:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107aae:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107ab5:	eb 96                	jmp    80107a4d <mappages+0x24>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80107ab7:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107ab8:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107abd:	c9                   	leave  
80107abe:	c3                   	ret    

80107abf <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80107abf:	55                   	push   %ebp
80107ac0:	89 e5                	mov    %esp,%ebp
80107ac2:	53                   	push   %ebx
80107ac3:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107ac6:	e8 7c b1 ff ff       	call   80102c47 <kalloc>
80107acb:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107ace:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107ad2:	75 0a                	jne    80107ade <setupkvm+0x1f>
    return 0;
80107ad4:	b8 00 00 00 00       	mov    $0x0,%eax
80107ad9:	e9 98 00 00 00       	jmp    80107b76 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80107ade:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107ae5:	00 
80107ae6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107aed:	00 
80107aee:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107af1:	89 04 24             	mov    %eax,(%esp)
80107af4:	e8 65 d4 ff ff       	call   80104f5e <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80107af9:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80107b00:	e8 ff f9 ff ff       	call   80107504 <p2v>
80107b05:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80107b0a:	76 0c                	jbe    80107b18 <setupkvm+0x59>
    panic("PHYSTOP too high");
80107b0c:	c7 04 24 ba 88 10 80 	movl   $0x801088ba,(%esp)
80107b13:	e8 2e 8a ff ff       	call   80100546 <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107b18:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
80107b1f:	eb 49                	jmp    80107b6a <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80107b21:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107b24:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80107b27:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107b2a:	8b 50 04             	mov    0x4(%eax),%edx
80107b2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b30:	8b 58 08             	mov    0x8(%eax),%ebx
80107b33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b36:	8b 40 04             	mov    0x4(%eax),%eax
80107b39:	29 c3                	sub    %eax,%ebx
80107b3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b3e:	8b 00                	mov    (%eax),%eax
80107b40:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107b44:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107b48:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107b4c:	89 44 24 04          	mov    %eax,0x4(%esp)
80107b50:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107b53:	89 04 24             	mov    %eax,(%esp)
80107b56:	e8 ce fe ff ff       	call   80107a29 <mappages>
80107b5b:	85 c0                	test   %eax,%eax
80107b5d:	79 07                	jns    80107b66 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80107b5f:	b8 00 00 00 00       	mov    $0x0,%eax
80107b64:	eb 10                	jmp    80107b76 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107b66:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107b6a:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
80107b71:	72 ae                	jb     80107b21 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80107b73:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107b76:	83 c4 34             	add    $0x34,%esp
80107b79:	5b                   	pop    %ebx
80107b7a:	5d                   	pop    %ebp
80107b7b:	c3                   	ret    

80107b7c <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107b7c:	55                   	push   %ebp
80107b7d:	89 e5                	mov    %esp,%ebp
80107b7f:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107b82:	e8 38 ff ff ff       	call   80107abf <setupkvm>
80107b87:	a3 18 2c 11 80       	mov    %eax,0x80112c18
  switchkvm();
80107b8c:	e8 02 00 00 00       	call   80107b93 <switchkvm>
}
80107b91:	c9                   	leave  
80107b92:	c3                   	ret    

80107b93 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107b93:	55                   	push   %ebp
80107b94:	89 e5                	mov    %esp,%ebp
80107b96:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80107b99:	a1 18 2c 11 80       	mov    0x80112c18,%eax
80107b9e:	89 04 24             	mov    %eax,(%esp)
80107ba1:	e8 51 f9 ff ff       	call   801074f7 <v2p>
80107ba6:	89 04 24             	mov    %eax,(%esp)
80107ba9:	e8 3e f9 ff ff       	call   801074ec <lcr3>
}
80107bae:	c9                   	leave  
80107baf:	c3                   	ret    

80107bb0 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107bb0:	55                   	push   %ebp
80107bb1:	89 e5                	mov    %esp,%ebp
80107bb3:	53                   	push   %ebx
80107bb4:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80107bb7:	e8 9b d2 ff ff       	call   80104e57 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80107bbc:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107bc2:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107bc9:	83 c2 08             	add    $0x8,%edx
80107bcc:	89 d3                	mov    %edx,%ebx
80107bce:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107bd5:	83 c2 08             	add    $0x8,%edx
80107bd8:	c1 ea 10             	shr    $0x10,%edx
80107bdb:	89 d1                	mov    %edx,%ecx
80107bdd:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107be4:	83 c2 08             	add    $0x8,%edx
80107be7:	c1 ea 18             	shr    $0x18,%edx
80107bea:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80107bf1:	67 00 
80107bf3:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80107bfa:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80107c00:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107c07:	83 e1 f0             	and    $0xfffffff0,%ecx
80107c0a:	83 c9 09             	or     $0x9,%ecx
80107c0d:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107c13:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107c1a:	83 c9 10             	or     $0x10,%ecx
80107c1d:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107c23:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107c2a:	83 e1 9f             	and    $0xffffff9f,%ecx
80107c2d:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107c33:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107c3a:	83 c9 80             	or     $0xffffff80,%ecx
80107c3d:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107c43:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107c4a:	83 e1 f0             	and    $0xfffffff0,%ecx
80107c4d:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107c53:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107c5a:	83 e1 ef             	and    $0xffffffef,%ecx
80107c5d:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107c63:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107c6a:	83 e1 df             	and    $0xffffffdf,%ecx
80107c6d:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107c73:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107c7a:	83 c9 40             	or     $0x40,%ecx
80107c7d:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107c83:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107c8a:	83 e1 7f             	and    $0x7f,%ecx
80107c8d:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107c93:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80107c99:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107c9f:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80107ca6:	83 e2 ef             	and    $0xffffffef,%edx
80107ca9:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80107caf:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107cb5:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80107cbb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107cc1:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80107cc8:	8b 52 08             	mov    0x8(%edx),%edx
80107ccb:	81 c2 00 10 00 00    	add    $0x1000,%edx
80107cd1:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80107cd4:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80107cdb:	e8 e1 f7 ff ff       	call   801074c1 <ltr>
  if(p->pgdir == 0)
80107ce0:	8b 45 08             	mov    0x8(%ebp),%eax
80107ce3:	8b 40 04             	mov    0x4(%eax),%eax
80107ce6:	85 c0                	test   %eax,%eax
80107ce8:	75 0c                	jne    80107cf6 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80107cea:	c7 04 24 cb 88 10 80 	movl   $0x801088cb,(%esp)
80107cf1:	e8 50 88 ff ff       	call   80100546 <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80107cf6:	8b 45 08             	mov    0x8(%ebp),%eax
80107cf9:	8b 40 04             	mov    0x4(%eax),%eax
80107cfc:	89 04 24             	mov    %eax,(%esp)
80107cff:	e8 f3 f7 ff ff       	call   801074f7 <v2p>
80107d04:	89 04 24             	mov    %eax,(%esp)
80107d07:	e8 e0 f7 ff ff       	call   801074ec <lcr3>
  popcli();
80107d0c:	e8 8e d1 ff ff       	call   80104e9f <popcli>
}
80107d11:	83 c4 14             	add    $0x14,%esp
80107d14:	5b                   	pop    %ebx
80107d15:	5d                   	pop    %ebp
80107d16:	c3                   	ret    

80107d17 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107d17:	55                   	push   %ebp
80107d18:	89 e5                	mov    %esp,%ebp
80107d1a:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80107d1d:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107d24:	76 0c                	jbe    80107d32 <inituvm+0x1b>
    panic("inituvm: more than a page");
80107d26:	c7 04 24 df 88 10 80 	movl   $0x801088df,(%esp)
80107d2d:	e8 14 88 ff ff       	call   80100546 <panic>
  mem = kalloc();
80107d32:	e8 10 af ff ff       	call   80102c47 <kalloc>
80107d37:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107d3a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107d41:	00 
80107d42:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107d49:	00 
80107d4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d4d:	89 04 24             	mov    %eax,(%esp)
80107d50:	e8 09 d2 ff ff       	call   80104f5e <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107d55:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d58:	89 04 24             	mov    %eax,(%esp)
80107d5b:	e8 97 f7 ff ff       	call   801074f7 <v2p>
80107d60:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107d67:	00 
80107d68:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107d6c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107d73:	00 
80107d74:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107d7b:	00 
80107d7c:	8b 45 08             	mov    0x8(%ebp),%eax
80107d7f:	89 04 24             	mov    %eax,(%esp)
80107d82:	e8 a2 fc ff ff       	call   80107a29 <mappages>
  memmove(mem, init, sz);
80107d87:	8b 45 10             	mov    0x10(%ebp),%eax
80107d8a:	89 44 24 08          	mov    %eax,0x8(%esp)
80107d8e:	8b 45 0c             	mov    0xc(%ebp),%eax
80107d91:	89 44 24 04          	mov    %eax,0x4(%esp)
80107d95:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d98:	89 04 24             	mov    %eax,(%esp)
80107d9b:	e8 91 d2 ff ff       	call   80105031 <memmove>
}
80107da0:	c9                   	leave  
80107da1:	c3                   	ret    

80107da2 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80107da2:	55                   	push   %ebp
80107da3:	89 e5                	mov    %esp,%ebp
80107da5:	53                   	push   %ebx
80107da6:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80107da9:	8b 45 0c             	mov    0xc(%ebp),%eax
80107dac:	25 ff 0f 00 00       	and    $0xfff,%eax
80107db1:	85 c0                	test   %eax,%eax
80107db3:	74 0c                	je     80107dc1 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80107db5:	c7 04 24 fc 88 10 80 	movl   $0x801088fc,(%esp)
80107dbc:	e8 85 87 ff ff       	call   80100546 <panic>
  for(i = 0; i < sz; i += PGSIZE){
80107dc1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107dc8:	e9 ad 00 00 00       	jmp    80107e7a <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80107dcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dd0:	8b 55 0c             	mov    0xc(%ebp),%edx
80107dd3:	01 d0                	add    %edx,%eax
80107dd5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107ddc:	00 
80107ddd:	89 44 24 04          	mov    %eax,0x4(%esp)
80107de1:	8b 45 08             	mov    0x8(%ebp),%eax
80107de4:	89 04 24             	mov    %eax,(%esp)
80107de7:	e8 9b fb ff ff       	call   80107987 <walkpgdir>
80107dec:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107def:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107df3:	75 0c                	jne    80107e01 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80107df5:	c7 04 24 1f 89 10 80 	movl   $0x8010891f,(%esp)
80107dfc:	e8 45 87 ff ff       	call   80100546 <panic>
    pa = PTE_ADDR(*pte);
80107e01:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107e04:	8b 00                	mov    (%eax),%eax
80107e06:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107e0b:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80107e0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e11:	8b 55 18             	mov    0x18(%ebp),%edx
80107e14:	89 d1                	mov    %edx,%ecx
80107e16:	29 c1                	sub    %eax,%ecx
80107e18:	89 c8                	mov    %ecx,%eax
80107e1a:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80107e1f:	77 11                	ja     80107e32 <loaduvm+0x90>
      n = sz - i;
80107e21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e24:	8b 55 18             	mov    0x18(%ebp),%edx
80107e27:	89 d1                	mov    %edx,%ecx
80107e29:	29 c1                	sub    %eax,%ecx
80107e2b:	89 c8                	mov    %ecx,%eax
80107e2d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107e30:	eb 07                	jmp    80107e39 <loaduvm+0x97>
    else
      n = PGSIZE;
80107e32:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80107e39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e3c:	8b 55 14             	mov    0x14(%ebp),%edx
80107e3f:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80107e42:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107e45:	89 04 24             	mov    %eax,(%esp)
80107e48:	e8 b7 f6 ff ff       	call   80107504 <p2v>
80107e4d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80107e50:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107e54:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107e58:	89 44 24 04          	mov    %eax,0x4(%esp)
80107e5c:	8b 45 10             	mov    0x10(%ebp),%eax
80107e5f:	89 04 24             	mov    %eax,(%esp)
80107e62:	e8 36 a0 ff ff       	call   80101e9d <readi>
80107e67:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107e6a:	74 07                	je     80107e73 <loaduvm+0xd1>
      return -1;
80107e6c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107e71:	eb 18                	jmp    80107e8b <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80107e73:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107e7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e7d:	3b 45 18             	cmp    0x18(%ebp),%eax
80107e80:	0f 82 47 ff ff ff    	jb     80107dcd <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80107e86:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107e8b:	83 c4 24             	add    $0x24,%esp
80107e8e:	5b                   	pop    %ebx
80107e8f:	5d                   	pop    %ebp
80107e90:	c3                   	ret    

80107e91 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107e91:	55                   	push   %ebp
80107e92:	89 e5                	mov    %esp,%ebp
80107e94:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80107e97:	8b 45 10             	mov    0x10(%ebp),%eax
80107e9a:	85 c0                	test   %eax,%eax
80107e9c:	79 0a                	jns    80107ea8 <allocuvm+0x17>
    return 0;
80107e9e:	b8 00 00 00 00       	mov    $0x0,%eax
80107ea3:	e9 c1 00 00 00       	jmp    80107f69 <allocuvm+0xd8>
  if(newsz < oldsz)
80107ea8:	8b 45 10             	mov    0x10(%ebp),%eax
80107eab:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107eae:	73 08                	jae    80107eb8 <allocuvm+0x27>
    return oldsz;
80107eb0:	8b 45 0c             	mov    0xc(%ebp),%eax
80107eb3:	e9 b1 00 00 00       	jmp    80107f69 <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80107eb8:	8b 45 0c             	mov    0xc(%ebp),%eax
80107ebb:	05 ff 0f 00 00       	add    $0xfff,%eax
80107ec0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107ec5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80107ec8:	e9 8d 00 00 00       	jmp    80107f5a <allocuvm+0xc9>
    mem = kalloc();
80107ecd:	e8 75 ad ff ff       	call   80102c47 <kalloc>
80107ed2:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80107ed5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107ed9:	75 2c                	jne    80107f07 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80107edb:	c7 04 24 3d 89 10 80 	movl   $0x8010893d,(%esp)
80107ee2:	e8 c3 84 ff ff       	call   801003aa <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80107ee7:	8b 45 0c             	mov    0xc(%ebp),%eax
80107eea:	89 44 24 08          	mov    %eax,0x8(%esp)
80107eee:	8b 45 10             	mov    0x10(%ebp),%eax
80107ef1:	89 44 24 04          	mov    %eax,0x4(%esp)
80107ef5:	8b 45 08             	mov    0x8(%ebp),%eax
80107ef8:	89 04 24             	mov    %eax,(%esp)
80107efb:	e8 6b 00 00 00       	call   80107f6b <deallocuvm>
      return 0;
80107f00:	b8 00 00 00 00       	mov    $0x0,%eax
80107f05:	eb 62                	jmp    80107f69 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80107f07:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107f0e:	00 
80107f0f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107f16:	00 
80107f17:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f1a:	89 04 24             	mov    %eax,(%esp)
80107f1d:	e8 3c d0 ff ff       	call   80104f5e <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107f22:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f25:	89 04 24             	mov    %eax,(%esp)
80107f28:	e8 ca f5 ff ff       	call   801074f7 <v2p>
80107f2d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107f30:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107f37:	00 
80107f38:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107f3c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107f43:	00 
80107f44:	89 54 24 04          	mov    %edx,0x4(%esp)
80107f48:	8b 45 08             	mov    0x8(%ebp),%eax
80107f4b:	89 04 24             	mov    %eax,(%esp)
80107f4e:	e8 d6 fa ff ff       	call   80107a29 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80107f53:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107f5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f5d:	3b 45 10             	cmp    0x10(%ebp),%eax
80107f60:	0f 82 67 ff ff ff    	jb     80107ecd <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80107f66:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107f69:	c9                   	leave  
80107f6a:	c3                   	ret    

80107f6b <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107f6b:	55                   	push   %ebp
80107f6c:	89 e5                	mov    %esp,%ebp
80107f6e:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80107f71:	8b 45 10             	mov    0x10(%ebp),%eax
80107f74:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107f77:	72 08                	jb     80107f81 <deallocuvm+0x16>
    return oldsz;
80107f79:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f7c:	e9 a4 00 00 00       	jmp    80108025 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80107f81:	8b 45 10             	mov    0x10(%ebp),%eax
80107f84:	05 ff 0f 00 00       	add    $0xfff,%eax
80107f89:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f8e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80107f91:	e9 80 00 00 00       	jmp    80108016 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80107f96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f99:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107fa0:	00 
80107fa1:	89 44 24 04          	mov    %eax,0x4(%esp)
80107fa5:	8b 45 08             	mov    0x8(%ebp),%eax
80107fa8:	89 04 24             	mov    %eax,(%esp)
80107fab:	e8 d7 f9 ff ff       	call   80107987 <walkpgdir>
80107fb0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80107fb3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107fb7:	75 09                	jne    80107fc2 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80107fb9:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80107fc0:	eb 4d                	jmp    8010800f <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80107fc2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107fc5:	8b 00                	mov    (%eax),%eax
80107fc7:	83 e0 01             	and    $0x1,%eax
80107fca:	85 c0                	test   %eax,%eax
80107fcc:	74 41                	je     8010800f <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80107fce:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107fd1:	8b 00                	mov    (%eax),%eax
80107fd3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107fd8:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80107fdb:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107fdf:	75 0c                	jne    80107fed <deallocuvm+0x82>
        panic("kfree");
80107fe1:	c7 04 24 55 89 10 80 	movl   $0x80108955,(%esp)
80107fe8:	e8 59 85 ff ff       	call   80100546 <panic>
      char *v = p2v(pa);
80107fed:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107ff0:	89 04 24             	mov    %eax,(%esp)
80107ff3:	e8 0c f5 ff ff       	call   80107504 <p2v>
80107ff8:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80107ffb:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107ffe:	89 04 24             	mov    %eax,(%esp)
80108001:	e8 a8 ab ff ff       	call   80102bae <kfree>
      *pte = 0;
80108006:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108009:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
8010800f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108016:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108019:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010801c:	0f 82 74 ff ff ff    	jb     80107f96 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80108022:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108025:	c9                   	leave  
80108026:	c3                   	ret    

80108027 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108027:	55                   	push   %ebp
80108028:	89 e5                	mov    %esp,%ebp
8010802a:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
8010802d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108031:	75 0c                	jne    8010803f <freevm+0x18>
    panic("freevm: no pgdir");
80108033:	c7 04 24 5b 89 10 80 	movl   $0x8010895b,(%esp)
8010803a:	e8 07 85 ff ff       	call   80100546 <panic>
  deallocuvm(pgdir, KERNBASE, 0);
8010803f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108046:	00 
80108047:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
8010804e:	80 
8010804f:	8b 45 08             	mov    0x8(%ebp),%eax
80108052:	89 04 24             	mov    %eax,(%esp)
80108055:	e8 11 ff ff ff       	call   80107f6b <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
8010805a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108061:	eb 48                	jmp    801080ab <freevm+0x84>
    if(pgdir[i] & PTE_P){
80108063:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108066:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010806d:	8b 45 08             	mov    0x8(%ebp),%eax
80108070:	01 d0                	add    %edx,%eax
80108072:	8b 00                	mov    (%eax),%eax
80108074:	83 e0 01             	and    $0x1,%eax
80108077:	85 c0                	test   %eax,%eax
80108079:	74 2c                	je     801080a7 <freevm+0x80>
      char * v = p2v(PTE_ADDR(pgdir[i]));
8010807b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010807e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108085:	8b 45 08             	mov    0x8(%ebp),%eax
80108088:	01 d0                	add    %edx,%eax
8010808a:	8b 00                	mov    (%eax),%eax
8010808c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108091:	89 04 24             	mov    %eax,(%esp)
80108094:	e8 6b f4 ff ff       	call   80107504 <p2v>
80108099:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
8010809c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010809f:	89 04 24             	mov    %eax,(%esp)
801080a2:	e8 07 ab ff ff       	call   80102bae <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
801080a7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801080ab:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
801080b2:	76 af                	jbe    80108063 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
801080b4:	8b 45 08             	mov    0x8(%ebp),%eax
801080b7:	89 04 24             	mov    %eax,(%esp)
801080ba:	e8 ef aa ff ff       	call   80102bae <kfree>
}
801080bf:	c9                   	leave  
801080c0:	c3                   	ret    

801080c1 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801080c1:	55                   	push   %ebp
801080c2:	89 e5                	mov    %esp,%ebp
801080c4:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801080c7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801080ce:	00 
801080cf:	8b 45 0c             	mov    0xc(%ebp),%eax
801080d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801080d6:	8b 45 08             	mov    0x8(%ebp),%eax
801080d9:	89 04 24             	mov    %eax,(%esp)
801080dc:	e8 a6 f8 ff ff       	call   80107987 <walkpgdir>
801080e1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
801080e4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801080e8:	75 0c                	jne    801080f6 <clearpteu+0x35>
    panic("clearpteu");
801080ea:	c7 04 24 6c 89 10 80 	movl   $0x8010896c,(%esp)
801080f1:	e8 50 84 ff ff       	call   80100546 <panic>
  *pte &= ~PTE_U;
801080f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080f9:	8b 00                	mov    (%eax),%eax
801080fb:	89 c2                	mov    %eax,%edx
801080fd:	83 e2 fb             	and    $0xfffffffb,%edx
80108100:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108103:	89 10                	mov    %edx,(%eax)
}
80108105:	c9                   	leave  
80108106:	c3                   	ret    

80108107 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108107:	55                   	push   %ebp
80108108:	89 e5                	mov    %esp,%ebp
8010810a:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
8010810d:	e8 ad f9 ff ff       	call   80107abf <setupkvm>
80108112:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108115:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108119:	75 0a                	jne    80108125 <copyuvm+0x1e>
    return 0;
8010811b:	b8 00 00 00 00       	mov    $0x0,%eax
80108120:	e9 f1 00 00 00       	jmp    80108216 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
80108125:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010812c:	e9 c0 00 00 00       	jmp    801081f1 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108131:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108134:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010813b:	00 
8010813c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108140:	8b 45 08             	mov    0x8(%ebp),%eax
80108143:	89 04 24             	mov    %eax,(%esp)
80108146:	e8 3c f8 ff ff       	call   80107987 <walkpgdir>
8010814b:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010814e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108152:	75 0c                	jne    80108160 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
80108154:	c7 04 24 76 89 10 80 	movl   $0x80108976,(%esp)
8010815b:	e8 e6 83 ff ff       	call   80100546 <panic>
    if(!(*pte & PTE_P))
80108160:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108163:	8b 00                	mov    (%eax),%eax
80108165:	83 e0 01             	and    $0x1,%eax
80108168:	85 c0                	test   %eax,%eax
8010816a:	75 0c                	jne    80108178 <copyuvm+0x71>
      panic("copyuvm: page not present");
8010816c:	c7 04 24 90 89 10 80 	movl   $0x80108990,(%esp)
80108173:	e8 ce 83 ff ff       	call   80100546 <panic>
    pa = PTE_ADDR(*pte);
80108178:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010817b:	8b 00                	mov    (%eax),%eax
8010817d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108182:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
80108185:	e8 bd aa ff ff       	call   80102c47 <kalloc>
8010818a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010818d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80108191:	74 6f                	je     80108202 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108193:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108196:	89 04 24             	mov    %eax,(%esp)
80108199:	e8 66 f3 ff ff       	call   80107504 <p2v>
8010819e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801081a5:	00 
801081a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801081aa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801081ad:	89 04 24             	mov    %eax,(%esp)
801081b0:	e8 7c ce ff ff       	call   80105031 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
801081b5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801081b8:	89 04 24             	mov    %eax,(%esp)
801081bb:	e8 37 f3 ff ff       	call   801074f7 <v2p>
801081c0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801081c3:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801081ca:	00 
801081cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
801081cf:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801081d6:	00 
801081d7:	89 54 24 04          	mov    %edx,0x4(%esp)
801081db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801081de:	89 04 24             	mov    %eax,(%esp)
801081e1:	e8 43 f8 ff ff       	call   80107a29 <mappages>
801081e6:	85 c0                	test   %eax,%eax
801081e8:	78 1b                	js     80108205 <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801081ea:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801081f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081f4:	3b 45 0c             	cmp    0xc(%ebp),%eax
801081f7:	0f 82 34 ff ff ff    	jb     80108131 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
801081fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108200:	eb 14                	jmp    80108216 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80108202:	90                   	nop
80108203:	eb 01                	jmp    80108206 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
80108205:	90                   	nop
  }
  return d;

bad:
  freevm(d);
80108206:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108209:	89 04 24             	mov    %eax,(%esp)
8010820c:	e8 16 fe ff ff       	call   80108027 <freevm>
  return 0;
80108211:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108216:	c9                   	leave  
80108217:	c3                   	ret    

80108218 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108218:	55                   	push   %ebp
80108219:	89 e5                	mov    %esp,%ebp
8010821b:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010821e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108225:	00 
80108226:	8b 45 0c             	mov    0xc(%ebp),%eax
80108229:	89 44 24 04          	mov    %eax,0x4(%esp)
8010822d:	8b 45 08             	mov    0x8(%ebp),%eax
80108230:	89 04 24             	mov    %eax,(%esp)
80108233:	e8 4f f7 ff ff       	call   80107987 <walkpgdir>
80108238:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
8010823b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010823e:	8b 00                	mov    (%eax),%eax
80108240:	83 e0 01             	and    $0x1,%eax
80108243:	85 c0                	test   %eax,%eax
80108245:	75 07                	jne    8010824e <uva2ka+0x36>
    return 0;
80108247:	b8 00 00 00 00       	mov    $0x0,%eax
8010824c:	eb 25                	jmp    80108273 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
8010824e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108251:	8b 00                	mov    (%eax),%eax
80108253:	83 e0 04             	and    $0x4,%eax
80108256:	85 c0                	test   %eax,%eax
80108258:	75 07                	jne    80108261 <uva2ka+0x49>
    return 0;
8010825a:	b8 00 00 00 00       	mov    $0x0,%eax
8010825f:	eb 12                	jmp    80108273 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80108261:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108264:	8b 00                	mov    (%eax),%eax
80108266:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010826b:	89 04 24             	mov    %eax,(%esp)
8010826e:	e8 91 f2 ff ff       	call   80107504 <p2v>
}
80108273:	c9                   	leave  
80108274:	c3                   	ret    

80108275 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80108275:	55                   	push   %ebp
80108276:	89 e5                	mov    %esp,%ebp
80108278:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
8010827b:	8b 45 10             	mov    0x10(%ebp),%eax
8010827e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80108281:	e9 89 00 00 00       	jmp    8010830f <copyout+0x9a>
    va0 = (uint)PGROUNDDOWN(va);
80108286:	8b 45 0c             	mov    0xc(%ebp),%eax
80108289:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010828e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80108291:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108294:	89 44 24 04          	mov    %eax,0x4(%esp)
80108298:	8b 45 08             	mov    0x8(%ebp),%eax
8010829b:	89 04 24             	mov    %eax,(%esp)
8010829e:	e8 75 ff ff ff       	call   80108218 <uva2ka>
801082a3:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
801082a6:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801082aa:	75 07                	jne    801082b3 <copyout+0x3e>
      return -1;
801082ac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801082b1:	eb 6b                	jmp    8010831e <copyout+0xa9>
    n = PGSIZE - (va - va0);
801082b3:	8b 45 0c             	mov    0xc(%ebp),%eax
801082b6:	8b 55 ec             	mov    -0x14(%ebp),%edx
801082b9:	89 d1                	mov    %edx,%ecx
801082bb:	29 c1                	sub    %eax,%ecx
801082bd:	89 c8                	mov    %ecx,%eax
801082bf:	05 00 10 00 00       	add    $0x1000,%eax
801082c4:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
801082c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801082ca:	3b 45 14             	cmp    0x14(%ebp),%eax
801082cd:	76 06                	jbe    801082d5 <copyout+0x60>
      n = len;
801082cf:	8b 45 14             	mov    0x14(%ebp),%eax
801082d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
801082d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801082d8:	8b 55 0c             	mov    0xc(%ebp),%edx
801082db:	29 c2                	sub    %eax,%edx
801082dd:	8b 45 e8             	mov    -0x18(%ebp),%eax
801082e0:	01 c2                	add    %eax,%edx
801082e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801082e5:	89 44 24 08          	mov    %eax,0x8(%esp)
801082e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082ec:	89 44 24 04          	mov    %eax,0x4(%esp)
801082f0:	89 14 24             	mov    %edx,(%esp)
801082f3:	e8 39 cd ff ff       	call   80105031 <memmove>
    len -= n;
801082f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801082fb:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801082fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108301:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80108304:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108307:	05 00 10 00 00       	add    $0x1000,%eax
8010830c:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010830f:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80108313:	0f 85 6d ff ff ff    	jne    80108286 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80108319:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010831e:	c9                   	leave  
8010831f:	c3                   	ret    
