
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
8010002d:	b8 5f 34 10 80       	mov    $0x8010345f,%eax
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
8010003a:	c7 44 24 04 24 82 10 	movl   $0x80108224,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 98 4b 00 00       	call   80104be6 <initlock>

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
801000bd:	e8 45 4b 00 00       	call   80104c07 <acquire>

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
80100104:	e8 60 4b 00 00       	call   80104c69 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 05 48 00 00       	call   80104929 <sleep>
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
8010017c:	e8 e8 4a 00 00       	call   80104c69 <release>
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
80100198:	c7 04 24 2b 82 10 80 	movl   $0x8010822b,(%esp)
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
801001d3:	e8 28 26 00 00       	call   80102800 <iderw>
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
801001ef:	c7 04 24 3c 82 10 80 	movl   $0x8010823c,(%esp)
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
80100210:	e8 eb 25 00 00       	call   80102800 <iderw>
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
80100229:	c7 04 24 43 82 10 80 	movl   $0x80108243,(%esp)
80100230:	e8 11 03 00 00       	call   80100546 <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 c6 49 00 00       	call   80104c07 <acquire>

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
8010029d:	e8 60 47 00 00       	call   80104a02 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 bb 49 00 00       	call   80104c69 <release>
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
801003c5:	e8 3d 48 00 00       	call   80104c07 <acquire>

  if (fmt == 0)
801003ca:	8b 45 08             	mov    0x8(%ebp),%eax
801003cd:	85 c0                	test   %eax,%eax
801003cf:	75 0c                	jne    801003dd <cprintf+0x33>
    panic("null fmt");
801003d1:	c7 04 24 4a 82 10 80 	movl   $0x8010824a,(%esp)
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
801004b8:	c7 45 ec 53 82 10 80 	movl   $0x80108253,-0x14(%ebp)
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
8010053f:	e8 25 47 00 00       	call   80104c69 <release>
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
8010056b:	c7 04 24 5a 82 10 80 	movl   $0x8010825a,(%esp)
80100572:	e8 33 fe ff ff       	call   801003aa <cprintf>
  cprintf(s);
80100577:	8b 45 08             	mov    0x8(%ebp),%eax
8010057a:	89 04 24             	mov    %eax,(%esp)
8010057d:	e8 28 fe ff ff       	call   801003aa <cprintf>
  cprintf("\n");
80100582:	c7 04 24 69 82 10 80 	movl   $0x80108269,(%esp)
80100589:	e8 1c fe ff ff       	call   801003aa <cprintf>
  getcallerpcs(&s, pcs);
8010058e:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100591:	89 44 24 04          	mov    %eax,0x4(%esp)
80100595:	8d 45 08             	lea    0x8(%ebp),%eax
80100598:	89 04 24             	mov    %eax,(%esp)
8010059b:	e8 18 47 00 00       	call   80104cb8 <getcallerpcs>
  for(i=0; i<10; i++)
801005a0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801005a7:	eb 1b                	jmp    801005c4 <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005ac:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005b0:	89 44 24 04          	mov    %eax,0x4(%esp)
801005b4:	c7 04 24 6b 82 10 80 	movl   $0x8010826b,(%esp)
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
801006bb:	e8 75 48 00 00       	call   80104f35 <memmove>
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
801006ea:	e8 73 47 00 00       	call   80104e62 <memset>
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
8010077f:	e8 ed 60 00 00       	call   80106871 <uartputc>
80100784:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010078b:	e8 e1 60 00 00       	call   80106871 <uartputc>
80100790:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100797:	e8 d5 60 00 00       	call   80106871 <uartputc>
8010079c:	eb 0b                	jmp    801007a9 <consputc+0x50>
  } else
    uartputc(c);
8010079e:	8b 45 08             	mov    0x8(%ebp),%eax
801007a1:	89 04 24             	mov    %eax,(%esp)
801007a4:	e8 c8 60 00 00       	call   80106871 <uartputc>
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
801007c3:	e8 3f 44 00 00       	call   80104c07 <acquire>
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
801007f3:	e8 ad 42 00 00       	call   80104aa5 <procdump>
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
80100900:	e8 fd 40 00 00       	call   80104a02 <wakeup>
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
80100927:	e8 3d 43 00 00       	call   80104c69 <release>
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
8010093a:	e8 a3 10 00 00       	call   801019e2 <iunlock>
  target = n;
8010093f:	8b 45 10             	mov    0x10(%ebp),%eax
80100942:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
80100945:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
8010094c:	e8 b6 42 00 00       	call   80104c07 <acquire>
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
8010096a:	e8 fa 42 00 00       	call   80104c69 <release>
        ilock(ip);
8010096f:	8b 45 08             	mov    0x8(%ebp),%eax
80100972:	89 04 24             	mov    %eax,(%esp)
80100975:	e8 1a 0f 00 00       	call   80101894 <ilock>
        return -1;
8010097a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010097f:	e9 a9 00 00 00       	jmp    80100a2d <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
80100984:	c7 44 24 04 a0 dd 10 	movl   $0x8010dda0,0x4(%esp)
8010098b:	80 
8010098c:	c7 04 24 54 de 10 80 	movl   $0x8010de54,(%esp)
80100993:	e8 91 3f 00 00       	call   80104929 <sleep>
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
80100a11:	e8 53 42 00 00       	call   80104c69 <release>
  ilock(ip);
80100a16:	8b 45 08             	mov    0x8(%ebp),%eax
80100a19:	89 04 24             	mov    %eax,(%esp)
80100a1c:	e8 73 0e 00 00       	call   80101894 <ilock>

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
80100a3b:	e8 a2 0f 00 00       	call   801019e2 <iunlock>
  acquire(&cons.lock);
80100a40:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a47:	e8 bb 41 00 00       	call   80104c07 <acquire>
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
80100a83:	e8 e1 41 00 00       	call   80104c69 <release>
  ilock(ip);
80100a88:	8b 45 08             	mov    0x8(%ebp),%eax
80100a8b:	89 04 24             	mov    %eax,(%esp)
80100a8e:	e8 01 0e 00 00       	call   80101894 <ilock>

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
80100a9e:	c7 44 24 04 6f 82 10 	movl   $0x8010826f,0x4(%esp)
80100aa5:	80 
80100aa6:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100aad:	e8 34 41 00 00       	call   80104be6 <initlock>
  initlock(&input.lock, "input");
80100ab2:	c7 44 24 04 77 82 10 	movl   $0x80108277,0x4(%esp)
80100ab9:	80 
80100aba:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100ac1:	e8 20 41 00 00       	call   80104be6 <initlock>

  devsw[CONSOLE].write = consolewrite;
80100ac6:	c7 05 0c e8 10 80 2f 	movl   $0x80100a2f,0x8010e80c
80100acd:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ad0:	c7 05 08 e8 10 80 2e 	movl   $0x8010092e,0x8010e808
80100ad7:	09 10 80 
  cons.locking = 1;
80100ada:	c7 05 f4 b5 10 80 01 	movl   $0x1,0x8010b5f4
80100ae1:	00 00 00 

  picenable(IRQ_KBD);
80100ae4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100aeb:	e8 2d 30 00 00       	call   80103b1d <picenable>
  ioapicenable(IRQ_KBD, 0);
80100af0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100af7:	00 
80100af8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100aff:	e8 be 1e 00 00       	call   801029c2 <ioapicenable>
}
80100b04:	c9                   	leave  
80100b05:	c3                   	ret    
80100b06:	66 90                	xchg   %ax,%ax

80100b08 <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100b08:	55                   	push   %ebp
80100b09:	89 e5                	mov    %esp,%ebp
80100b0b:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  if((ip = namei(path)) == 0)
80100b11:	8b 45 08             	mov    0x8(%ebp),%eax
80100b14:	89 04 24             	mov    %eax,(%esp)
80100b17:	e8 39 19 00 00       	call   80102455 <namei>
80100b1c:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b1f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b23:	75 0a                	jne    80100b2f <exec+0x27>
    return -1;
80100b25:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b2a:	e9 f6 03 00 00       	jmp    80100f25 <exec+0x41d>
  ilock(ip);
80100b2f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b32:	89 04 24             	mov    %eax,(%esp)
80100b35:	e8 5a 0d 00 00       	call   80101894 <ilock>
  pgdir = 0;
80100b3a:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100b41:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b48:	00 
80100b49:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b50:	00 
80100b51:	8d 85 0c ff ff ff    	lea    -0xf4(%ebp),%eax
80100b57:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b5b:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b5e:	89 04 24             	mov    %eax,(%esp)
80100b61:	e8 3b 12 00 00       	call   80101da1 <readi>
80100b66:	83 f8 33             	cmp    $0x33,%eax
80100b69:	0f 86 70 03 00 00    	jbe    80100edf <exec+0x3d7>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100b6f:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b75:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b7a:	0f 85 62 03 00 00    	jne    80100ee2 <exec+0x3da>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
80100b80:	c7 04 24 4b 2b 10 80 	movl   $0x80102b4b,(%esp)
80100b87:	e8 37 6e 00 00       	call   801079c3 <setupkvm>
80100b8c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b8f:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b93:	0f 84 4c 03 00 00    	je     80100ee5 <exec+0x3dd>
    goto bad;

  // Load program into memory.
  sz = 0;
80100b99:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100ba0:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100ba7:	8b 85 28 ff ff ff    	mov    -0xd8(%ebp),%eax
80100bad:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100bb0:	e9 c5 00 00 00       	jmp    80100c7a <exec+0x172>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100bb5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100bb8:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100bbf:	00 
80100bc0:	89 44 24 08          	mov    %eax,0x8(%esp)
80100bc4:	8d 85 ec fe ff ff    	lea    -0x114(%ebp),%eax
80100bca:	89 44 24 04          	mov    %eax,0x4(%esp)
80100bce:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100bd1:	89 04 24             	mov    %eax,(%esp)
80100bd4:	e8 c8 11 00 00       	call   80101da1 <readi>
80100bd9:	83 f8 20             	cmp    $0x20,%eax
80100bdc:	0f 85 06 03 00 00    	jne    80100ee8 <exec+0x3e0>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
80100be2:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100be8:	83 f8 01             	cmp    $0x1,%eax
80100beb:	75 7f                	jne    80100c6c <exec+0x164>
      continue;
    if(ph.memsz < ph.filesz)
80100bed:	8b 95 00 ff ff ff    	mov    -0x100(%ebp),%edx
80100bf3:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100bf9:	39 c2                	cmp    %eax,%edx
80100bfb:	0f 82 ea 02 00 00    	jb     80100eeb <exec+0x3e3>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100c01:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80100c07:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
80100c0d:	01 d0                	add    %edx,%eax
80100c0f:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c13:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c16:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c1a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c1d:	89 04 24             	mov    %eax,(%esp)
80100c20:	e8 70 71 00 00       	call   80107d95 <allocuvm>
80100c25:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c28:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c2c:	0f 84 bc 02 00 00    	je     80100eee <exec+0x3e6>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100c32:	8b 8d fc fe ff ff    	mov    -0x104(%ebp),%ecx
80100c38:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c3e:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
80100c44:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100c48:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100c4c:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100c4f:	89 54 24 08          	mov    %edx,0x8(%esp)
80100c53:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c57:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c5a:	89 04 24             	mov    %eax,(%esp)
80100c5d:	e8 44 70 00 00       	call   80107ca6 <loaduvm>
80100c62:	85 c0                	test   %eax,%eax
80100c64:	0f 88 87 02 00 00    	js     80100ef1 <exec+0x3e9>
80100c6a:	eb 01                	jmp    80100c6d <exec+0x165>
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
80100c6c:	90                   	nop
  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c6d:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100c71:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c74:	83 c0 20             	add    $0x20,%eax
80100c77:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c7a:	0f b7 85 38 ff ff ff 	movzwl -0xc8(%ebp),%eax
80100c81:	0f b7 c0             	movzwl %ax,%eax
80100c84:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100c87:	0f 8f 28 ff ff ff    	jg     80100bb5 <exec+0xad>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100c8d:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c90:	89 04 24             	mov    %eax,(%esp)
80100c93:	e8 80 0e 00 00       	call   80101b18 <iunlockput>
  ip = 0;
80100c98:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100c9f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ca2:	05 ff 0f 00 00       	add    $0xfff,%eax
80100ca7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100cac:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100caf:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cb2:	05 00 20 00 00       	add    $0x2000,%eax
80100cb7:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cbb:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cbe:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cc2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cc5:	89 04 24             	mov    %eax,(%esp)
80100cc8:	e8 c8 70 00 00       	call   80107d95 <allocuvm>
80100ccd:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cd0:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100cd4:	0f 84 1a 02 00 00    	je     80100ef4 <exec+0x3ec>
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100cda:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cdd:	2d 00 20 00 00       	sub    $0x2000,%eax
80100ce2:	89 44 24 04          	mov    %eax,0x4(%esp)
80100ce6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ce9:	89 04 24             	mov    %eax,(%esp)
80100cec:	e8 d4 72 00 00       	call   80107fc5 <clearpteu>
  sp = sz;
80100cf1:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cf4:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100cf7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100cfe:	e9 97 00 00 00       	jmp    80100d9a <exec+0x292>
    if(argc >= MAXARG)
80100d03:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100d07:	0f 87 ea 01 00 00    	ja     80100ef7 <exec+0x3ef>
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100d0d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d10:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d17:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d1a:	01 d0                	add    %edx,%eax
80100d1c:	8b 00                	mov    (%eax),%eax
80100d1e:	89 04 24             	mov    %eax,(%esp)
80100d21:	e8 ba 43 00 00       	call   801050e0 <strlen>
80100d26:	f7 d0                	not    %eax
80100d28:	89 c2                	mov    %eax,%edx
80100d2a:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d2d:	01 d0                	add    %edx,%eax
80100d2f:	83 e0 fc             	and    $0xfffffffc,%eax
80100d32:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d35:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d38:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d3f:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d42:	01 d0                	add    %edx,%eax
80100d44:	8b 00                	mov    (%eax),%eax
80100d46:	89 04 24             	mov    %eax,(%esp)
80100d49:	e8 92 43 00 00       	call   801050e0 <strlen>
80100d4e:	83 c0 01             	add    $0x1,%eax
80100d51:	89 c2                	mov    %eax,%edx
80100d53:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d56:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80100d5d:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d60:	01 c8                	add    %ecx,%eax
80100d62:	8b 00                	mov    (%eax),%eax
80100d64:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d68:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d6c:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d6f:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d73:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d76:	89 04 24             	mov    %eax,(%esp)
80100d79:	e8 fb 73 00 00       	call   80108179 <copyout>
80100d7e:	85 c0                	test   %eax,%eax
80100d80:	0f 88 74 01 00 00    	js     80100efa <exec+0x3f2>
      goto bad;
    ustack[3+argc] = sp;
80100d86:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d89:	8d 50 03             	lea    0x3(%eax),%edx
80100d8c:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d8f:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d96:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100d9a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d9d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100da4:	8b 45 0c             	mov    0xc(%ebp),%eax
80100da7:	01 d0                	add    %edx,%eax
80100da9:	8b 00                	mov    (%eax),%eax
80100dab:	85 c0                	test   %eax,%eax
80100dad:	0f 85 50 ff ff ff    	jne    80100d03 <exec+0x1fb>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100db3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100db6:	83 c0 03             	add    $0x3,%eax
80100db9:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
80100dc0:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100dc4:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
80100dcb:	ff ff ff 
  ustack[1] = argc;
80100dce:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dd1:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100dd7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dda:	83 c0 01             	add    $0x1,%eax
80100ddd:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100de4:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100de7:	29 d0                	sub    %edx,%eax
80100de9:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80100def:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100df2:	83 c0 04             	add    $0x4,%eax
80100df5:	c1 e0 02             	shl    $0x2,%eax
80100df8:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100dfb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dfe:	83 c0 04             	add    $0x4,%eax
80100e01:	c1 e0 02             	shl    $0x2,%eax
80100e04:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100e08:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80100e0e:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e12:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e15:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e19:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e1c:	89 04 24             	mov    %eax,(%esp)
80100e1f:	e8 55 73 00 00       	call   80108179 <copyout>
80100e24:	85 c0                	test   %eax,%eax
80100e26:	0f 88 d1 00 00 00    	js     80100efd <exec+0x3f5>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e2c:	8b 45 08             	mov    0x8(%ebp),%eax
80100e2f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e35:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e38:	eb 17                	jmp    80100e51 <exec+0x349>
    if(*s == '/')
80100e3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e3d:	0f b6 00             	movzbl (%eax),%eax
80100e40:	3c 2f                	cmp    $0x2f,%al
80100e42:	75 09                	jne    80100e4d <exec+0x345>
      last = s+1;
80100e44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e47:	83 c0 01             	add    $0x1,%eax
80100e4a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e4d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e54:	0f b6 00             	movzbl (%eax),%eax
80100e57:	84 c0                	test   %al,%al
80100e59:	75 df                	jne    80100e3a <exec+0x332>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100e5b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e61:	8d 50 6c             	lea    0x6c(%eax),%edx
80100e64:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100e6b:	00 
80100e6c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e6f:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e73:	89 14 24             	mov    %edx,(%esp)
80100e76:	e8 17 42 00 00       	call   80105092 <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100e7b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e81:	8b 40 04             	mov    0x4(%eax),%eax
80100e84:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
80100e87:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e8d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100e90:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100e93:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e99:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100e9c:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100e9e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ea4:	8b 40 18             	mov    0x18(%eax),%eax
80100ea7:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
80100ead:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100eb0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100eb6:	8b 40 18             	mov    0x18(%eax),%eax
80100eb9:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100ebc:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100ebf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ec5:	89 04 24             	mov    %eax,(%esp)
80100ec8:	e8 e7 6b 00 00       	call   80107ab4 <switchuvm>
  freevm(oldpgdir);
80100ecd:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ed0:	89 04 24             	mov    %eax,(%esp)
80100ed3:	e8 53 70 00 00       	call   80107f2b <freevm>
  return 0;
80100ed8:	b8 00 00 00 00       	mov    $0x0,%eax
80100edd:	eb 46                	jmp    80100f25 <exec+0x41d>
  ilock(ip);
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
    goto bad;
80100edf:	90                   	nop
80100ee0:	eb 1c                	jmp    80100efe <exec+0x3f6>
  if(elf.magic != ELF_MAGIC)
    goto bad;
80100ee2:	90                   	nop
80100ee3:	eb 19                	jmp    80100efe <exec+0x3f6>

  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;
80100ee5:	90                   	nop
80100ee6:	eb 16                	jmp    80100efe <exec+0x3f6>

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
80100ee8:	90                   	nop
80100ee9:	eb 13                	jmp    80100efe <exec+0x3f6>
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
80100eeb:	90                   	nop
80100eec:	eb 10                	jmp    80100efe <exec+0x3f6>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
80100eee:	90                   	nop
80100eef:	eb 0d                	jmp    80100efe <exec+0x3f6>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
80100ef1:	90                   	nop
80100ef2:	eb 0a                	jmp    80100efe <exec+0x3f6>

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
80100ef4:	90                   	nop
80100ef5:	eb 07                	jmp    80100efe <exec+0x3f6>
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
80100ef7:	90                   	nop
80100ef8:	eb 04                	jmp    80100efe <exec+0x3f6>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
80100efa:	90                   	nop
80100efb:	eb 01                	jmp    80100efe <exec+0x3f6>
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;
80100efd:	90                   	nop
  switchuvm(proc);
  freevm(oldpgdir);
  return 0;

 bad:
  if(pgdir)
80100efe:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100f02:	74 0b                	je     80100f0f <exec+0x407>
    freevm(pgdir);
80100f04:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100f07:	89 04 24             	mov    %eax,(%esp)
80100f0a:	e8 1c 70 00 00       	call   80107f2b <freevm>
  if(ip)
80100f0f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100f13:	74 0b                	je     80100f20 <exec+0x418>
    iunlockput(ip);
80100f15:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100f18:	89 04 24             	mov    %eax,(%esp)
80100f1b:	e8 f8 0b 00 00       	call   80101b18 <iunlockput>
  return -1;
80100f20:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100f25:	c9                   	leave  
80100f26:	c3                   	ret    
80100f27:	90                   	nop

80100f28 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100f28:	55                   	push   %ebp
80100f29:	89 e5                	mov    %esp,%ebp
80100f2b:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100f2e:	c7 44 24 04 7d 82 10 	movl   $0x8010827d,0x4(%esp)
80100f35:	80 
80100f36:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f3d:	e8 a4 3c 00 00       	call   80104be6 <initlock>
}
80100f42:	c9                   	leave  
80100f43:	c3                   	ret    

80100f44 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100f44:	55                   	push   %ebp
80100f45:	89 e5                	mov    %esp,%ebp
80100f47:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100f4a:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f51:	e8 b1 3c 00 00       	call   80104c07 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f56:	c7 45 f4 94 de 10 80 	movl   $0x8010de94,-0xc(%ebp)
80100f5d:	eb 29                	jmp    80100f88 <filealloc+0x44>
    if(f->ref == 0){
80100f5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f62:	8b 40 04             	mov    0x4(%eax),%eax
80100f65:	85 c0                	test   %eax,%eax
80100f67:	75 1b                	jne    80100f84 <filealloc+0x40>
      f->ref = 1;
80100f69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f6c:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80100f73:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f7a:	e8 ea 3c 00 00       	call   80104c69 <release>
      return f;
80100f7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f82:	eb 1e                	jmp    80100fa2 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f84:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f88:	81 7d f4 f4 e7 10 80 	cmpl   $0x8010e7f4,-0xc(%ebp)
80100f8f:	72 ce                	jb     80100f5f <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f91:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f98:	e8 cc 3c 00 00       	call   80104c69 <release>
  return 0;
80100f9d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100fa2:	c9                   	leave  
80100fa3:	c3                   	ret    

80100fa4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100fa4:	55                   	push   %ebp
80100fa5:	89 e5                	mov    %esp,%ebp
80100fa7:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80100faa:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100fb1:	e8 51 3c 00 00       	call   80104c07 <acquire>
  if(f->ref < 1)
80100fb6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb9:	8b 40 04             	mov    0x4(%eax),%eax
80100fbc:	85 c0                	test   %eax,%eax
80100fbe:	7f 0c                	jg     80100fcc <filedup+0x28>
    panic("filedup");
80100fc0:	c7 04 24 84 82 10 80 	movl   $0x80108284,(%esp)
80100fc7:	e8 7a f5 ff ff       	call   80100546 <panic>
  f->ref++;
80100fcc:	8b 45 08             	mov    0x8(%ebp),%eax
80100fcf:	8b 40 04             	mov    0x4(%eax),%eax
80100fd2:	8d 50 01             	lea    0x1(%eax),%edx
80100fd5:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd8:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fdb:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100fe2:	e8 82 3c 00 00       	call   80104c69 <release>
  return f;
80100fe7:	8b 45 08             	mov    0x8(%ebp),%eax
}
80100fea:	c9                   	leave  
80100feb:	c3                   	ret    

80100fec <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100fec:	55                   	push   %ebp
80100fed:	89 e5                	mov    %esp,%ebp
80100fef:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80100ff2:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100ff9:	e8 09 3c 00 00       	call   80104c07 <acquire>
  if(f->ref < 1)
80100ffe:	8b 45 08             	mov    0x8(%ebp),%eax
80101001:	8b 40 04             	mov    0x4(%eax),%eax
80101004:	85 c0                	test   %eax,%eax
80101006:	7f 0c                	jg     80101014 <fileclose+0x28>
    panic("fileclose");
80101008:	c7 04 24 8c 82 10 80 	movl   $0x8010828c,(%esp)
8010100f:	e8 32 f5 ff ff       	call   80100546 <panic>
  if(--f->ref > 0){
80101014:	8b 45 08             	mov    0x8(%ebp),%eax
80101017:	8b 40 04             	mov    0x4(%eax),%eax
8010101a:	8d 50 ff             	lea    -0x1(%eax),%edx
8010101d:	8b 45 08             	mov    0x8(%ebp),%eax
80101020:	89 50 04             	mov    %edx,0x4(%eax)
80101023:	8b 45 08             	mov    0x8(%ebp),%eax
80101026:	8b 40 04             	mov    0x4(%eax),%eax
80101029:	85 c0                	test   %eax,%eax
8010102b:	7e 11                	jle    8010103e <fileclose+0x52>
    release(&ftable.lock);
8010102d:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80101034:	e8 30 3c 00 00       	call   80104c69 <release>
80101039:	e9 82 00 00 00       	jmp    801010c0 <fileclose+0xd4>
    return;
  }
  ff = *f;
8010103e:	8b 45 08             	mov    0x8(%ebp),%eax
80101041:	8b 10                	mov    (%eax),%edx
80101043:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101046:	8b 50 04             	mov    0x4(%eax),%edx
80101049:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010104c:	8b 50 08             	mov    0x8(%eax),%edx
8010104f:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101052:	8b 50 0c             	mov    0xc(%eax),%edx
80101055:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101058:	8b 50 10             	mov    0x10(%eax),%edx
8010105b:	89 55 f0             	mov    %edx,-0x10(%ebp)
8010105e:	8b 40 14             	mov    0x14(%eax),%eax
80101061:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101064:	8b 45 08             	mov    0x8(%ebp),%eax
80101067:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
8010106e:	8b 45 08             	mov    0x8(%ebp),%eax
80101071:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101077:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
8010107e:	e8 e6 3b 00 00       	call   80104c69 <release>
  
  if(ff.type == FD_PIPE)
80101083:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101086:	83 f8 01             	cmp    $0x1,%eax
80101089:	75 18                	jne    801010a3 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
8010108b:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
8010108f:	0f be d0             	movsbl %al,%edx
80101092:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101095:	89 54 24 04          	mov    %edx,0x4(%esp)
80101099:	89 04 24             	mov    %eax,(%esp)
8010109c:	e8 36 2d 00 00       	call   80103dd7 <pipeclose>
801010a1:	eb 1d                	jmp    801010c0 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
801010a3:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010a6:	83 f8 02             	cmp    $0x2,%eax
801010a9:	75 15                	jne    801010c0 <fileclose+0xd4>
    begin_trans();
801010ab:	e8 c0 21 00 00       	call   80103270 <begin_trans>
    iput(ff.ip);
801010b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801010b3:	89 04 24             	mov    %eax,(%esp)
801010b6:	e8 8c 09 00 00       	call   80101a47 <iput>
    commit_trans();
801010bb:	e8 f9 21 00 00       	call   801032b9 <commit_trans>
  }
}
801010c0:	c9                   	leave  
801010c1:	c3                   	ret    

801010c2 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801010c2:	55                   	push   %ebp
801010c3:	89 e5                	mov    %esp,%ebp
801010c5:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801010c8:	8b 45 08             	mov    0x8(%ebp),%eax
801010cb:	8b 00                	mov    (%eax),%eax
801010cd:	83 f8 02             	cmp    $0x2,%eax
801010d0:	75 38                	jne    8010110a <filestat+0x48>
    ilock(f->ip);
801010d2:	8b 45 08             	mov    0x8(%ebp),%eax
801010d5:	8b 40 10             	mov    0x10(%eax),%eax
801010d8:	89 04 24             	mov    %eax,(%esp)
801010db:	e8 b4 07 00 00       	call   80101894 <ilock>
    stati(f->ip, st);
801010e0:	8b 45 08             	mov    0x8(%ebp),%eax
801010e3:	8b 40 10             	mov    0x10(%eax),%eax
801010e6:	8b 55 0c             	mov    0xc(%ebp),%edx
801010e9:	89 54 24 04          	mov    %edx,0x4(%esp)
801010ed:	89 04 24             	mov    %eax,(%esp)
801010f0:	e8 67 0c 00 00       	call   80101d5c <stati>
    iunlock(f->ip);
801010f5:	8b 45 08             	mov    0x8(%ebp),%eax
801010f8:	8b 40 10             	mov    0x10(%eax),%eax
801010fb:	89 04 24             	mov    %eax,(%esp)
801010fe:	e8 df 08 00 00       	call   801019e2 <iunlock>
    return 0;
80101103:	b8 00 00 00 00       	mov    $0x0,%eax
80101108:	eb 05                	jmp    8010110f <filestat+0x4d>
  }
  return -1;
8010110a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010110f:	c9                   	leave  
80101110:	c3                   	ret    

80101111 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80101111:	55                   	push   %ebp
80101112:	89 e5                	mov    %esp,%ebp
80101114:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
80101117:	8b 45 08             	mov    0x8(%ebp),%eax
8010111a:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010111e:	84 c0                	test   %al,%al
80101120:	75 0a                	jne    8010112c <fileread+0x1b>
    return -1;
80101122:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101127:	e9 9f 00 00 00       	jmp    801011cb <fileread+0xba>
  if(f->type == FD_PIPE)
8010112c:	8b 45 08             	mov    0x8(%ebp),%eax
8010112f:	8b 00                	mov    (%eax),%eax
80101131:	83 f8 01             	cmp    $0x1,%eax
80101134:	75 1e                	jne    80101154 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101136:	8b 45 08             	mov    0x8(%ebp),%eax
80101139:	8b 40 0c             	mov    0xc(%eax),%eax
8010113c:	8b 55 10             	mov    0x10(%ebp),%edx
8010113f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101143:	8b 55 0c             	mov    0xc(%ebp),%edx
80101146:	89 54 24 04          	mov    %edx,0x4(%esp)
8010114a:	89 04 24             	mov    %eax,(%esp)
8010114d:	e8 09 2e 00 00       	call   80103f5b <piperead>
80101152:	eb 77                	jmp    801011cb <fileread+0xba>
  if(f->type == FD_INODE){
80101154:	8b 45 08             	mov    0x8(%ebp),%eax
80101157:	8b 00                	mov    (%eax),%eax
80101159:	83 f8 02             	cmp    $0x2,%eax
8010115c:	75 61                	jne    801011bf <fileread+0xae>
    ilock(f->ip);
8010115e:	8b 45 08             	mov    0x8(%ebp),%eax
80101161:	8b 40 10             	mov    0x10(%eax),%eax
80101164:	89 04 24             	mov    %eax,(%esp)
80101167:	e8 28 07 00 00       	call   80101894 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010116c:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010116f:	8b 45 08             	mov    0x8(%ebp),%eax
80101172:	8b 50 14             	mov    0x14(%eax),%edx
80101175:	8b 45 08             	mov    0x8(%ebp),%eax
80101178:	8b 40 10             	mov    0x10(%eax),%eax
8010117b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010117f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101183:	8b 55 0c             	mov    0xc(%ebp),%edx
80101186:	89 54 24 04          	mov    %edx,0x4(%esp)
8010118a:	89 04 24             	mov    %eax,(%esp)
8010118d:	e8 0f 0c 00 00       	call   80101da1 <readi>
80101192:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101195:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101199:	7e 11                	jle    801011ac <fileread+0x9b>
      f->off += r;
8010119b:	8b 45 08             	mov    0x8(%ebp),%eax
8010119e:	8b 50 14             	mov    0x14(%eax),%edx
801011a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801011a4:	01 c2                	add    %eax,%edx
801011a6:	8b 45 08             	mov    0x8(%ebp),%eax
801011a9:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
801011ac:	8b 45 08             	mov    0x8(%ebp),%eax
801011af:	8b 40 10             	mov    0x10(%eax),%eax
801011b2:	89 04 24             	mov    %eax,(%esp)
801011b5:	e8 28 08 00 00       	call   801019e2 <iunlock>
    return r;
801011ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801011bd:	eb 0c                	jmp    801011cb <fileread+0xba>
  }
  panic("fileread");
801011bf:	c7 04 24 96 82 10 80 	movl   $0x80108296,(%esp)
801011c6:	e8 7b f3 ff ff       	call   80100546 <panic>
}
801011cb:	c9                   	leave  
801011cc:	c3                   	ret    

801011cd <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801011cd:	55                   	push   %ebp
801011ce:	89 e5                	mov    %esp,%ebp
801011d0:	53                   	push   %ebx
801011d1:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801011d4:	8b 45 08             	mov    0x8(%ebp),%eax
801011d7:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801011db:	84 c0                	test   %al,%al
801011dd:	75 0a                	jne    801011e9 <filewrite+0x1c>
    return -1;
801011df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801011e4:	e9 23 01 00 00       	jmp    8010130c <filewrite+0x13f>
  if(f->type == FD_PIPE)
801011e9:	8b 45 08             	mov    0x8(%ebp),%eax
801011ec:	8b 00                	mov    (%eax),%eax
801011ee:	83 f8 01             	cmp    $0x1,%eax
801011f1:	75 21                	jne    80101214 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
801011f3:	8b 45 08             	mov    0x8(%ebp),%eax
801011f6:	8b 40 0c             	mov    0xc(%eax),%eax
801011f9:	8b 55 10             	mov    0x10(%ebp),%edx
801011fc:	89 54 24 08          	mov    %edx,0x8(%esp)
80101200:	8b 55 0c             	mov    0xc(%ebp),%edx
80101203:	89 54 24 04          	mov    %edx,0x4(%esp)
80101207:	89 04 24             	mov    %eax,(%esp)
8010120a:	e8 5a 2c 00 00       	call   80103e69 <pipewrite>
8010120f:	e9 f8 00 00 00       	jmp    8010130c <filewrite+0x13f>
  if(f->type == FD_INODE){
80101214:	8b 45 08             	mov    0x8(%ebp),%eax
80101217:	8b 00                	mov    (%eax),%eax
80101219:	83 f8 02             	cmp    $0x2,%eax
8010121c:	0f 85 de 00 00 00    	jne    80101300 <filewrite+0x133>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
80101222:	c7 45 ec 00 06 00 00 	movl   $0x600,-0x14(%ebp)
    int i = 0;
80101229:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101230:	e9 a8 00 00 00       	jmp    801012dd <filewrite+0x110>
      int n1 = n - i;
80101235:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101238:	8b 55 10             	mov    0x10(%ebp),%edx
8010123b:	89 d1                	mov    %edx,%ecx
8010123d:	29 c1                	sub    %eax,%ecx
8010123f:	89 c8                	mov    %ecx,%eax
80101241:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101244:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101247:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010124a:	7e 06                	jle    80101252 <filewrite+0x85>
        n1 = max;
8010124c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010124f:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_trans();
80101252:	e8 19 20 00 00       	call   80103270 <begin_trans>
      ilock(f->ip);
80101257:	8b 45 08             	mov    0x8(%ebp),%eax
8010125a:	8b 40 10             	mov    0x10(%eax),%eax
8010125d:	89 04 24             	mov    %eax,(%esp)
80101260:	e8 2f 06 00 00       	call   80101894 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101265:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80101268:	8b 45 08             	mov    0x8(%ebp),%eax
8010126b:	8b 50 14             	mov    0x14(%eax),%edx
8010126e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
80101271:	8b 45 0c             	mov    0xc(%ebp),%eax
80101274:	01 c3                	add    %eax,%ebx
80101276:	8b 45 08             	mov    0x8(%ebp),%eax
80101279:	8b 40 10             	mov    0x10(%eax),%eax
8010127c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101280:	89 54 24 08          	mov    %edx,0x8(%esp)
80101284:	89 5c 24 04          	mov    %ebx,0x4(%esp)
80101288:	89 04 24             	mov    %eax,(%esp)
8010128b:	e8 7f 0c 00 00       	call   80101f0f <writei>
80101290:	89 45 e8             	mov    %eax,-0x18(%ebp)
80101293:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101297:	7e 11                	jle    801012aa <filewrite+0xdd>
        f->off += r;
80101299:	8b 45 08             	mov    0x8(%ebp),%eax
8010129c:	8b 50 14             	mov    0x14(%eax),%edx
8010129f:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012a2:	01 c2                	add    %eax,%edx
801012a4:	8b 45 08             	mov    0x8(%ebp),%eax
801012a7:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
801012aa:	8b 45 08             	mov    0x8(%ebp),%eax
801012ad:	8b 40 10             	mov    0x10(%eax),%eax
801012b0:	89 04 24             	mov    %eax,(%esp)
801012b3:	e8 2a 07 00 00       	call   801019e2 <iunlock>
      commit_trans();
801012b8:	e8 fc 1f 00 00       	call   801032b9 <commit_trans>

      if(r < 0)
801012bd:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801012c1:	78 28                	js     801012eb <filewrite+0x11e>
        break;
      if(r != n1)
801012c3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012c6:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012c9:	74 0c                	je     801012d7 <filewrite+0x10a>
        panic("short filewrite");
801012cb:	c7 04 24 9f 82 10 80 	movl   $0x8010829f,(%esp)
801012d2:	e8 6f f2 ff ff       	call   80100546 <panic>
      i += r;
801012d7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012da:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801012dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012e0:	3b 45 10             	cmp    0x10(%ebp),%eax
801012e3:	0f 8c 4c ff ff ff    	jl     80101235 <filewrite+0x68>
801012e9:	eb 01                	jmp    801012ec <filewrite+0x11f>
        f->off += r;
      iunlock(f->ip);
      commit_trans();

      if(r < 0)
        break;
801012eb:	90                   	nop
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801012ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012ef:	3b 45 10             	cmp    0x10(%ebp),%eax
801012f2:	75 05                	jne    801012f9 <filewrite+0x12c>
801012f4:	8b 45 10             	mov    0x10(%ebp),%eax
801012f7:	eb 05                	jmp    801012fe <filewrite+0x131>
801012f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012fe:	eb 0c                	jmp    8010130c <filewrite+0x13f>
  }
  panic("filewrite");
80101300:	c7 04 24 af 82 10 80 	movl   $0x801082af,(%esp)
80101307:	e8 3a f2 ff ff       	call   80100546 <panic>
}
8010130c:	83 c4 24             	add    $0x24,%esp
8010130f:	5b                   	pop    %ebx
80101310:	5d                   	pop    %ebp
80101311:	c3                   	ret    
80101312:	66 90                	xchg   %ax,%ax

80101314 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80101314:	55                   	push   %ebp
80101315:	89 e5                	mov    %esp,%ebp
80101317:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
8010131a:	8b 45 08             	mov    0x8(%ebp),%eax
8010131d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101324:	00 
80101325:	89 04 24             	mov    %eax,(%esp)
80101328:	e8 79 ee ff ff       	call   801001a6 <bread>
8010132d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101330:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101333:	83 c0 18             	add    $0x18,%eax
80101336:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010133d:	00 
8010133e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101342:	8b 45 0c             	mov    0xc(%ebp),%eax
80101345:	89 04 24             	mov    %eax,(%esp)
80101348:	e8 e8 3b 00 00       	call   80104f35 <memmove>
  brelse(bp);
8010134d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101350:	89 04 24             	mov    %eax,(%esp)
80101353:	e8 bf ee ff ff       	call   80100217 <brelse>
}
80101358:	c9                   	leave  
80101359:	c3                   	ret    

8010135a <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
8010135a:	55                   	push   %ebp
8010135b:	89 e5                	mov    %esp,%ebp
8010135d:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80101360:	8b 55 0c             	mov    0xc(%ebp),%edx
80101363:	8b 45 08             	mov    0x8(%ebp),%eax
80101366:	89 54 24 04          	mov    %edx,0x4(%esp)
8010136a:	89 04 24             	mov    %eax,(%esp)
8010136d:	e8 34 ee ff ff       	call   801001a6 <bread>
80101372:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101375:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101378:	83 c0 18             	add    $0x18,%eax
8010137b:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80101382:	00 
80101383:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010138a:	00 
8010138b:	89 04 24             	mov    %eax,(%esp)
8010138e:	e8 cf 3a 00 00       	call   80104e62 <memset>
  log_write(bp);
80101393:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101396:	89 04 24             	mov    %eax,(%esp)
80101399:	e8 73 1f 00 00       	call   80103311 <log_write>
  brelse(bp);
8010139e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013a1:	89 04 24             	mov    %eax,(%esp)
801013a4:	e8 6e ee ff ff       	call   80100217 <brelse>
}
801013a9:	c9                   	leave  
801013aa:	c3                   	ret    

801013ab <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
801013ab:	55                   	push   %ebp
801013ac:	89 e5                	mov    %esp,%ebp
801013ae:	53                   	push   %ebx
801013af:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
801013b2:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
801013b9:	8b 45 08             	mov    0x8(%ebp),%eax
801013bc:	8d 55 d8             	lea    -0x28(%ebp),%edx
801013bf:	89 54 24 04          	mov    %edx,0x4(%esp)
801013c3:	89 04 24             	mov    %eax,(%esp)
801013c6:	e8 49 ff ff ff       	call   80101314 <readsb>
  for(b = 0; b < sb.size; b += BPB){
801013cb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801013d2:	e9 0d 01 00 00       	jmp    801014e4 <balloc+0x139>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
801013d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013da:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801013e0:	85 c0                	test   %eax,%eax
801013e2:	0f 48 c2             	cmovs  %edx,%eax
801013e5:	c1 f8 0c             	sar    $0xc,%eax
801013e8:	8b 55 e0             	mov    -0x20(%ebp),%edx
801013eb:	c1 ea 03             	shr    $0x3,%edx
801013ee:	01 d0                	add    %edx,%eax
801013f0:	83 c0 03             	add    $0x3,%eax
801013f3:	89 44 24 04          	mov    %eax,0x4(%esp)
801013f7:	8b 45 08             	mov    0x8(%ebp),%eax
801013fa:	89 04 24             	mov    %eax,(%esp)
801013fd:	e8 a4 ed ff ff       	call   801001a6 <bread>
80101402:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101405:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010140c:	e9 a3 00 00 00       	jmp    801014b4 <balloc+0x109>
      m = 1 << (bi % 8);
80101411:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101414:	89 c2                	mov    %eax,%edx
80101416:	c1 fa 1f             	sar    $0x1f,%edx
80101419:	c1 ea 1d             	shr    $0x1d,%edx
8010141c:	01 d0                	add    %edx,%eax
8010141e:	83 e0 07             	and    $0x7,%eax
80101421:	29 d0                	sub    %edx,%eax
80101423:	ba 01 00 00 00       	mov    $0x1,%edx
80101428:	89 d3                	mov    %edx,%ebx
8010142a:	89 c1                	mov    %eax,%ecx
8010142c:	d3 e3                	shl    %cl,%ebx
8010142e:	89 d8                	mov    %ebx,%eax
80101430:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101433:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101436:	8d 50 07             	lea    0x7(%eax),%edx
80101439:	85 c0                	test   %eax,%eax
8010143b:	0f 48 c2             	cmovs  %edx,%eax
8010143e:	c1 f8 03             	sar    $0x3,%eax
80101441:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101444:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101449:	0f b6 c0             	movzbl %al,%eax
8010144c:	23 45 e8             	and    -0x18(%ebp),%eax
8010144f:	85 c0                	test   %eax,%eax
80101451:	75 5d                	jne    801014b0 <balloc+0x105>
        bp->data[bi/8] |= m;  // Mark block in use.
80101453:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101456:	8d 50 07             	lea    0x7(%eax),%edx
80101459:	85 c0                	test   %eax,%eax
8010145b:	0f 48 c2             	cmovs  %edx,%eax
8010145e:	c1 f8 03             	sar    $0x3,%eax
80101461:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101464:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101469:	89 d1                	mov    %edx,%ecx
8010146b:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010146e:	09 ca                	or     %ecx,%edx
80101470:	89 d1                	mov    %edx,%ecx
80101472:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101475:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101479:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010147c:	89 04 24             	mov    %eax,(%esp)
8010147f:	e8 8d 1e 00 00       	call   80103311 <log_write>
        brelse(bp);
80101484:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101487:	89 04 24             	mov    %eax,(%esp)
8010148a:	e8 88 ed ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
8010148f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101492:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101495:	01 c2                	add    %eax,%edx
80101497:	8b 45 08             	mov    0x8(%ebp),%eax
8010149a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010149e:	89 04 24             	mov    %eax,(%esp)
801014a1:	e8 b4 fe ff ff       	call   8010135a <bzero>
        return b + bi;
801014a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014a9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014ac:	01 d0                	add    %edx,%eax
801014ae:	eb 4e                	jmp    801014fe <balloc+0x153>

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801014b0:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801014b4:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
801014bb:	7f 15                	jg     801014d2 <balloc+0x127>
801014bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014c0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014c3:	01 d0                	add    %edx,%eax
801014c5:	89 c2                	mov    %eax,%edx
801014c7:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014ca:	39 c2                	cmp    %eax,%edx
801014cc:	0f 82 3f ff ff ff    	jb     80101411 <balloc+0x66>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801014d2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014d5:	89 04 24             	mov    %eax,(%esp)
801014d8:	e8 3a ed ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
801014dd:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801014e4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014e7:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014ea:	39 c2                	cmp    %eax,%edx
801014ec:	0f 82 e5 fe ff ff    	jb     801013d7 <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801014f2:	c7 04 24 b9 82 10 80 	movl   $0x801082b9,(%esp)
801014f9:	e8 48 f0 ff ff       	call   80100546 <panic>
}
801014fe:	83 c4 34             	add    $0x34,%esp
80101501:	5b                   	pop    %ebx
80101502:	5d                   	pop    %ebp
80101503:	c3                   	ret    

80101504 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
80101504:	55                   	push   %ebp
80101505:	89 e5                	mov    %esp,%ebp
80101507:	53                   	push   %ebx
80101508:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
8010150b:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010150e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101512:	8b 45 08             	mov    0x8(%ebp),%eax
80101515:	89 04 24             	mov    %eax,(%esp)
80101518:	e8 f7 fd ff ff       	call   80101314 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
8010151d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101520:	89 c2                	mov    %eax,%edx
80101522:	c1 ea 0c             	shr    $0xc,%edx
80101525:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101528:	c1 e8 03             	shr    $0x3,%eax
8010152b:	01 d0                	add    %edx,%eax
8010152d:	8d 50 03             	lea    0x3(%eax),%edx
80101530:	8b 45 08             	mov    0x8(%ebp),%eax
80101533:	89 54 24 04          	mov    %edx,0x4(%esp)
80101537:	89 04 24             	mov    %eax,(%esp)
8010153a:	e8 67 ec ff ff       	call   801001a6 <bread>
8010153f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101542:	8b 45 0c             	mov    0xc(%ebp),%eax
80101545:	25 ff 0f 00 00       	and    $0xfff,%eax
8010154a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010154d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101550:	89 c2                	mov    %eax,%edx
80101552:	c1 fa 1f             	sar    $0x1f,%edx
80101555:	c1 ea 1d             	shr    $0x1d,%edx
80101558:	01 d0                	add    %edx,%eax
8010155a:	83 e0 07             	and    $0x7,%eax
8010155d:	29 d0                	sub    %edx,%eax
8010155f:	ba 01 00 00 00       	mov    $0x1,%edx
80101564:	89 d3                	mov    %edx,%ebx
80101566:	89 c1                	mov    %eax,%ecx
80101568:	d3 e3                	shl    %cl,%ebx
8010156a:	89 d8                	mov    %ebx,%eax
8010156c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
8010156f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101572:	8d 50 07             	lea    0x7(%eax),%edx
80101575:	85 c0                	test   %eax,%eax
80101577:	0f 48 c2             	cmovs  %edx,%eax
8010157a:	c1 f8 03             	sar    $0x3,%eax
8010157d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101580:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101585:	0f b6 c0             	movzbl %al,%eax
80101588:	23 45 ec             	and    -0x14(%ebp),%eax
8010158b:	85 c0                	test   %eax,%eax
8010158d:	75 0c                	jne    8010159b <bfree+0x97>
    panic("freeing free block");
8010158f:	c7 04 24 cf 82 10 80 	movl   $0x801082cf,(%esp)
80101596:	e8 ab ef ff ff       	call   80100546 <panic>
  bp->data[bi/8] &= ~m;
8010159b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010159e:	8d 50 07             	lea    0x7(%eax),%edx
801015a1:	85 c0                	test   %eax,%eax
801015a3:	0f 48 c2             	cmovs  %edx,%eax
801015a6:	c1 f8 03             	sar    $0x3,%eax
801015a9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015ac:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801015b1:	8b 4d ec             	mov    -0x14(%ebp),%ecx
801015b4:	f7 d1                	not    %ecx
801015b6:	21 ca                	and    %ecx,%edx
801015b8:	89 d1                	mov    %edx,%ecx
801015ba:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015bd:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
801015c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015c4:	89 04 24             	mov    %eax,(%esp)
801015c7:	e8 45 1d 00 00       	call   80103311 <log_write>
  brelse(bp);
801015cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015cf:	89 04 24             	mov    %eax,(%esp)
801015d2:	e8 40 ec ff ff       	call   80100217 <brelse>
}
801015d7:	83 c4 34             	add    $0x34,%esp
801015da:	5b                   	pop    %ebx
801015db:	5d                   	pop    %ebp
801015dc:	c3                   	ret    

801015dd <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
801015dd:	55                   	push   %ebp
801015de:	89 e5                	mov    %esp,%ebp
801015e0:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
801015e3:	c7 44 24 04 e2 82 10 	movl   $0x801082e2,0x4(%esp)
801015ea:	80 
801015eb:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
801015f2:	e8 ef 35 00 00       	call   80104be6 <initlock>
}
801015f7:	c9                   	leave  
801015f8:	c3                   	ret    

801015f9 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
801015f9:	55                   	push   %ebp
801015fa:	89 e5                	mov    %esp,%ebp
801015fc:	83 ec 48             	sub    $0x48,%esp
801015ff:	8b 45 0c             	mov    0xc(%ebp),%eax
80101602:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
80101606:	8b 45 08             	mov    0x8(%ebp),%eax
80101609:	8d 55 dc             	lea    -0x24(%ebp),%edx
8010160c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101610:	89 04 24             	mov    %eax,(%esp)
80101613:	e8 fc fc ff ff       	call   80101314 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
80101618:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
8010161f:	e9 98 00 00 00       	jmp    801016bc <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
80101624:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101627:	c1 e8 03             	shr    $0x3,%eax
8010162a:	83 c0 02             	add    $0x2,%eax
8010162d:	89 44 24 04          	mov    %eax,0x4(%esp)
80101631:	8b 45 08             	mov    0x8(%ebp),%eax
80101634:	89 04 24             	mov    %eax,(%esp)
80101637:	e8 6a eb ff ff       	call   801001a6 <bread>
8010163c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
8010163f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101642:	8d 50 18             	lea    0x18(%eax),%edx
80101645:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101648:	83 e0 07             	and    $0x7,%eax
8010164b:	c1 e0 06             	shl    $0x6,%eax
8010164e:	01 d0                	add    %edx,%eax
80101650:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80101653:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101656:	0f b7 00             	movzwl (%eax),%eax
80101659:	66 85 c0             	test   %ax,%ax
8010165c:	75 4f                	jne    801016ad <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
8010165e:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
80101665:	00 
80101666:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010166d:	00 
8010166e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101671:	89 04 24             	mov    %eax,(%esp)
80101674:	e8 e9 37 00 00       	call   80104e62 <memset>
      dip->type = type;
80101679:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010167c:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
80101680:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101683:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101686:	89 04 24             	mov    %eax,(%esp)
80101689:	e8 83 1c 00 00       	call   80103311 <log_write>
      brelse(bp);
8010168e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101691:	89 04 24             	mov    %eax,(%esp)
80101694:	e8 7e eb ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101699:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010169c:	89 44 24 04          	mov    %eax,0x4(%esp)
801016a0:	8b 45 08             	mov    0x8(%ebp),%eax
801016a3:	89 04 24             	mov    %eax,(%esp)
801016a6:	e8 e5 00 00 00       	call   80101790 <iget>
801016ab:	eb 29                	jmp    801016d6 <ialloc+0xdd>
    }
    brelse(bp);
801016ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016b0:	89 04 24             	mov    %eax,(%esp)
801016b3:	e8 5f eb ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
801016b8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801016bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801016bf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801016c2:	39 c2                	cmp    %eax,%edx
801016c4:	0f 82 5a ff ff ff    	jb     80101624 <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
801016ca:	c7 04 24 e9 82 10 80 	movl   $0x801082e9,(%esp)
801016d1:	e8 70 ee ff ff       	call   80100546 <panic>
}
801016d6:	c9                   	leave  
801016d7:	c3                   	ret    

801016d8 <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
801016d8:	55                   	push   %ebp
801016d9:	89 e5                	mov    %esp,%ebp
801016db:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
801016de:	8b 45 08             	mov    0x8(%ebp),%eax
801016e1:	8b 40 04             	mov    0x4(%eax),%eax
801016e4:	c1 e8 03             	shr    $0x3,%eax
801016e7:	8d 50 02             	lea    0x2(%eax),%edx
801016ea:	8b 45 08             	mov    0x8(%ebp),%eax
801016ed:	8b 00                	mov    (%eax),%eax
801016ef:	89 54 24 04          	mov    %edx,0x4(%esp)
801016f3:	89 04 24             	mov    %eax,(%esp)
801016f6:	e8 ab ea ff ff       	call   801001a6 <bread>
801016fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801016fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101701:	8d 50 18             	lea    0x18(%eax),%edx
80101704:	8b 45 08             	mov    0x8(%ebp),%eax
80101707:	8b 40 04             	mov    0x4(%eax),%eax
8010170a:	83 e0 07             	and    $0x7,%eax
8010170d:	c1 e0 06             	shl    $0x6,%eax
80101710:	01 d0                	add    %edx,%eax
80101712:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80101715:	8b 45 08             	mov    0x8(%ebp),%eax
80101718:	0f b7 50 10          	movzwl 0x10(%eax),%edx
8010171c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010171f:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101722:	8b 45 08             	mov    0x8(%ebp),%eax
80101725:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80101729:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010172c:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101730:	8b 45 08             	mov    0x8(%ebp),%eax
80101733:	0f b7 50 14          	movzwl 0x14(%eax),%edx
80101737:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010173a:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
8010173e:	8b 45 08             	mov    0x8(%ebp),%eax
80101741:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101745:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101748:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
8010174c:	8b 45 08             	mov    0x8(%ebp),%eax
8010174f:	8b 50 18             	mov    0x18(%eax),%edx
80101752:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101755:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101758:	8b 45 08             	mov    0x8(%ebp),%eax
8010175b:	8d 50 1c             	lea    0x1c(%eax),%edx
8010175e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101761:	83 c0 0c             	add    $0xc,%eax
80101764:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
8010176b:	00 
8010176c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101770:	89 04 24             	mov    %eax,(%esp)
80101773:	e8 bd 37 00 00       	call   80104f35 <memmove>
  log_write(bp);
80101778:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010177b:	89 04 24             	mov    %eax,(%esp)
8010177e:	e8 8e 1b 00 00       	call   80103311 <log_write>
  brelse(bp);
80101783:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101786:	89 04 24             	mov    %eax,(%esp)
80101789:	e8 89 ea ff ff       	call   80100217 <brelse>
}
8010178e:	c9                   	leave  
8010178f:	c3                   	ret    

80101790 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80101790:	55                   	push   %ebp
80101791:	89 e5                	mov    %esp,%ebp
80101793:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
80101796:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
8010179d:	e8 65 34 00 00       	call   80104c07 <acquire>

  // Is the inode already cached?
  empty = 0;
801017a2:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801017a9:	c7 45 f4 94 e8 10 80 	movl   $0x8010e894,-0xc(%ebp)
801017b0:	eb 59                	jmp    8010180b <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801017b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017b5:	8b 40 08             	mov    0x8(%eax),%eax
801017b8:	85 c0                	test   %eax,%eax
801017ba:	7e 35                	jle    801017f1 <iget+0x61>
801017bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017bf:	8b 00                	mov    (%eax),%eax
801017c1:	3b 45 08             	cmp    0x8(%ebp),%eax
801017c4:	75 2b                	jne    801017f1 <iget+0x61>
801017c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017c9:	8b 40 04             	mov    0x4(%eax),%eax
801017cc:	3b 45 0c             	cmp    0xc(%ebp),%eax
801017cf:	75 20                	jne    801017f1 <iget+0x61>
      ip->ref++;
801017d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017d4:	8b 40 08             	mov    0x8(%eax),%eax
801017d7:	8d 50 01             	lea    0x1(%eax),%edx
801017da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017dd:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
801017e0:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
801017e7:	e8 7d 34 00 00       	call   80104c69 <release>
      return ip;
801017ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017ef:	eb 6f                	jmp    80101860 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801017f1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017f5:	75 10                	jne    80101807 <iget+0x77>
801017f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017fa:	8b 40 08             	mov    0x8(%eax),%eax
801017fd:	85 c0                	test   %eax,%eax
801017ff:	75 06                	jne    80101807 <iget+0x77>
      empty = ip;
80101801:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101804:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101807:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
8010180b:	81 7d f4 34 f8 10 80 	cmpl   $0x8010f834,-0xc(%ebp)
80101812:	72 9e                	jb     801017b2 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80101814:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101818:	75 0c                	jne    80101826 <iget+0x96>
    panic("iget: no inodes");
8010181a:	c7 04 24 fb 82 10 80 	movl   $0x801082fb,(%esp)
80101821:	e8 20 ed ff ff       	call   80100546 <panic>

  ip = empty;
80101826:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101829:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
8010182c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010182f:	8b 55 08             	mov    0x8(%ebp),%edx
80101832:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80101834:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101837:	8b 55 0c             	mov    0xc(%ebp),%edx
8010183a:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
8010183d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101840:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
80101847:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010184a:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101851:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101858:	e8 0c 34 00 00       	call   80104c69 <release>

  return ip;
8010185d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101860:	c9                   	leave  
80101861:	c3                   	ret    

80101862 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80101862:	55                   	push   %ebp
80101863:	89 e5                	mov    %esp,%ebp
80101865:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101868:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
8010186f:	e8 93 33 00 00       	call   80104c07 <acquire>
  ip->ref++;
80101874:	8b 45 08             	mov    0x8(%ebp),%eax
80101877:	8b 40 08             	mov    0x8(%eax),%eax
8010187a:	8d 50 01             	lea    0x1(%eax),%edx
8010187d:	8b 45 08             	mov    0x8(%ebp),%eax
80101880:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101883:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
8010188a:	e8 da 33 00 00       	call   80104c69 <release>
  return ip;
8010188f:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101892:	c9                   	leave  
80101893:	c3                   	ret    

80101894 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101894:	55                   	push   %ebp
80101895:	89 e5                	mov    %esp,%ebp
80101897:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
8010189a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010189e:	74 0a                	je     801018aa <ilock+0x16>
801018a0:	8b 45 08             	mov    0x8(%ebp),%eax
801018a3:	8b 40 08             	mov    0x8(%eax),%eax
801018a6:	85 c0                	test   %eax,%eax
801018a8:	7f 0c                	jg     801018b6 <ilock+0x22>
    panic("ilock");
801018aa:	c7 04 24 0b 83 10 80 	movl   $0x8010830b,(%esp)
801018b1:	e8 90 ec ff ff       	call   80100546 <panic>

  acquire(&icache.lock);
801018b6:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
801018bd:	e8 45 33 00 00       	call   80104c07 <acquire>
  while(ip->flags & I_BUSY)
801018c2:	eb 13                	jmp    801018d7 <ilock+0x43>
    sleep(ip, &icache.lock);
801018c4:	c7 44 24 04 60 e8 10 	movl   $0x8010e860,0x4(%esp)
801018cb:	80 
801018cc:	8b 45 08             	mov    0x8(%ebp),%eax
801018cf:	89 04 24             	mov    %eax,(%esp)
801018d2:	e8 52 30 00 00       	call   80104929 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
801018d7:	8b 45 08             	mov    0x8(%ebp),%eax
801018da:	8b 40 0c             	mov    0xc(%eax),%eax
801018dd:	83 e0 01             	and    $0x1,%eax
801018e0:	85 c0                	test   %eax,%eax
801018e2:	75 e0                	jne    801018c4 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
801018e4:	8b 45 08             	mov    0x8(%ebp),%eax
801018e7:	8b 40 0c             	mov    0xc(%eax),%eax
801018ea:	89 c2                	mov    %eax,%edx
801018ec:	83 ca 01             	or     $0x1,%edx
801018ef:	8b 45 08             	mov    0x8(%ebp),%eax
801018f2:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
801018f5:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
801018fc:	e8 68 33 00 00       	call   80104c69 <release>

  if(!(ip->flags & I_VALID)){
80101901:	8b 45 08             	mov    0x8(%ebp),%eax
80101904:	8b 40 0c             	mov    0xc(%eax),%eax
80101907:	83 e0 02             	and    $0x2,%eax
8010190a:	85 c0                	test   %eax,%eax
8010190c:	0f 85 ce 00 00 00    	jne    801019e0 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
80101912:	8b 45 08             	mov    0x8(%ebp),%eax
80101915:	8b 40 04             	mov    0x4(%eax),%eax
80101918:	c1 e8 03             	shr    $0x3,%eax
8010191b:	8d 50 02             	lea    0x2(%eax),%edx
8010191e:	8b 45 08             	mov    0x8(%ebp),%eax
80101921:	8b 00                	mov    (%eax),%eax
80101923:	89 54 24 04          	mov    %edx,0x4(%esp)
80101927:	89 04 24             	mov    %eax,(%esp)
8010192a:	e8 77 e8 ff ff       	call   801001a6 <bread>
8010192f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101932:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101935:	8d 50 18             	lea    0x18(%eax),%edx
80101938:	8b 45 08             	mov    0x8(%ebp),%eax
8010193b:	8b 40 04             	mov    0x4(%eax),%eax
8010193e:	83 e0 07             	and    $0x7,%eax
80101941:	c1 e0 06             	shl    $0x6,%eax
80101944:	01 d0                	add    %edx,%eax
80101946:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101949:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010194c:	0f b7 10             	movzwl (%eax),%edx
8010194f:	8b 45 08             	mov    0x8(%ebp),%eax
80101952:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80101956:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101959:	0f b7 50 02          	movzwl 0x2(%eax),%edx
8010195d:	8b 45 08             	mov    0x8(%ebp),%eax
80101960:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101964:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101967:	0f b7 50 04          	movzwl 0x4(%eax),%edx
8010196b:	8b 45 08             	mov    0x8(%ebp),%eax
8010196e:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101972:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101975:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101979:	8b 45 08             	mov    0x8(%ebp),%eax
8010197c:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101980:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101983:	8b 50 08             	mov    0x8(%eax),%edx
80101986:	8b 45 08             	mov    0x8(%ebp),%eax
80101989:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
8010198c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010198f:	8d 50 0c             	lea    0xc(%eax),%edx
80101992:	8b 45 08             	mov    0x8(%ebp),%eax
80101995:	83 c0 1c             	add    $0x1c,%eax
80101998:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
8010199f:	00 
801019a0:	89 54 24 04          	mov    %edx,0x4(%esp)
801019a4:	89 04 24             	mov    %eax,(%esp)
801019a7:	e8 89 35 00 00       	call   80104f35 <memmove>
    brelse(bp);
801019ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019af:	89 04 24             	mov    %eax,(%esp)
801019b2:	e8 60 e8 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
801019b7:	8b 45 08             	mov    0x8(%ebp),%eax
801019ba:	8b 40 0c             	mov    0xc(%eax),%eax
801019bd:	89 c2                	mov    %eax,%edx
801019bf:	83 ca 02             	or     $0x2,%edx
801019c2:	8b 45 08             	mov    0x8(%ebp),%eax
801019c5:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
801019c8:	8b 45 08             	mov    0x8(%ebp),%eax
801019cb:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801019cf:	66 85 c0             	test   %ax,%ax
801019d2:	75 0c                	jne    801019e0 <ilock+0x14c>
      panic("ilock: no type");
801019d4:	c7 04 24 11 83 10 80 	movl   $0x80108311,(%esp)
801019db:	e8 66 eb ff ff       	call   80100546 <panic>
  }
}
801019e0:	c9                   	leave  
801019e1:	c3                   	ret    

801019e2 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
801019e2:	55                   	push   %ebp
801019e3:	89 e5                	mov    %esp,%ebp
801019e5:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
801019e8:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801019ec:	74 17                	je     80101a05 <iunlock+0x23>
801019ee:	8b 45 08             	mov    0x8(%ebp),%eax
801019f1:	8b 40 0c             	mov    0xc(%eax),%eax
801019f4:	83 e0 01             	and    $0x1,%eax
801019f7:	85 c0                	test   %eax,%eax
801019f9:	74 0a                	je     80101a05 <iunlock+0x23>
801019fb:	8b 45 08             	mov    0x8(%ebp),%eax
801019fe:	8b 40 08             	mov    0x8(%eax),%eax
80101a01:	85 c0                	test   %eax,%eax
80101a03:	7f 0c                	jg     80101a11 <iunlock+0x2f>
    panic("iunlock");
80101a05:	c7 04 24 20 83 10 80 	movl   $0x80108320,(%esp)
80101a0c:	e8 35 eb ff ff       	call   80100546 <panic>

  acquire(&icache.lock);
80101a11:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101a18:	e8 ea 31 00 00       	call   80104c07 <acquire>
  ip->flags &= ~I_BUSY;
80101a1d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a20:	8b 40 0c             	mov    0xc(%eax),%eax
80101a23:	89 c2                	mov    %eax,%edx
80101a25:	83 e2 fe             	and    $0xfffffffe,%edx
80101a28:	8b 45 08             	mov    0x8(%ebp),%eax
80101a2b:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101a2e:	8b 45 08             	mov    0x8(%ebp),%eax
80101a31:	89 04 24             	mov    %eax,(%esp)
80101a34:	e8 c9 2f 00 00       	call   80104a02 <wakeup>
  release(&icache.lock);
80101a39:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101a40:	e8 24 32 00 00       	call   80104c69 <release>
}
80101a45:	c9                   	leave  
80101a46:	c3                   	ret    

80101a47 <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
80101a47:	55                   	push   %ebp
80101a48:	89 e5                	mov    %esp,%ebp
80101a4a:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101a4d:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101a54:	e8 ae 31 00 00       	call   80104c07 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101a59:	8b 45 08             	mov    0x8(%ebp),%eax
80101a5c:	8b 40 08             	mov    0x8(%eax),%eax
80101a5f:	83 f8 01             	cmp    $0x1,%eax
80101a62:	0f 85 93 00 00 00    	jne    80101afb <iput+0xb4>
80101a68:	8b 45 08             	mov    0x8(%ebp),%eax
80101a6b:	8b 40 0c             	mov    0xc(%eax),%eax
80101a6e:	83 e0 02             	and    $0x2,%eax
80101a71:	85 c0                	test   %eax,%eax
80101a73:	0f 84 82 00 00 00    	je     80101afb <iput+0xb4>
80101a79:	8b 45 08             	mov    0x8(%ebp),%eax
80101a7c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101a80:	66 85 c0             	test   %ax,%ax
80101a83:	75 76                	jne    80101afb <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
80101a85:	8b 45 08             	mov    0x8(%ebp),%eax
80101a88:	8b 40 0c             	mov    0xc(%eax),%eax
80101a8b:	83 e0 01             	and    $0x1,%eax
80101a8e:	85 c0                	test   %eax,%eax
80101a90:	74 0c                	je     80101a9e <iput+0x57>
      panic("iput busy");
80101a92:	c7 04 24 28 83 10 80 	movl   $0x80108328,(%esp)
80101a99:	e8 a8 ea ff ff       	call   80100546 <panic>
    ip->flags |= I_BUSY;
80101a9e:	8b 45 08             	mov    0x8(%ebp),%eax
80101aa1:	8b 40 0c             	mov    0xc(%eax),%eax
80101aa4:	89 c2                	mov    %eax,%edx
80101aa6:	83 ca 01             	or     $0x1,%edx
80101aa9:	8b 45 08             	mov    0x8(%ebp),%eax
80101aac:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101aaf:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101ab6:	e8 ae 31 00 00       	call   80104c69 <release>
    itrunc(ip);
80101abb:	8b 45 08             	mov    0x8(%ebp),%eax
80101abe:	89 04 24             	mov    %eax,(%esp)
80101ac1:	e8 7d 01 00 00       	call   80101c43 <itrunc>
    ip->type = 0;
80101ac6:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac9:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101acf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad2:	89 04 24             	mov    %eax,(%esp)
80101ad5:	e8 fe fb ff ff       	call   801016d8 <iupdate>
    acquire(&icache.lock);
80101ada:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101ae1:	e8 21 31 00 00       	call   80104c07 <acquire>
    ip->flags = 0;
80101ae6:	8b 45 08             	mov    0x8(%ebp),%eax
80101ae9:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101af0:	8b 45 08             	mov    0x8(%ebp),%eax
80101af3:	89 04 24             	mov    %eax,(%esp)
80101af6:	e8 07 2f 00 00       	call   80104a02 <wakeup>
  }
  ip->ref--;
80101afb:	8b 45 08             	mov    0x8(%ebp),%eax
80101afe:	8b 40 08             	mov    0x8(%eax),%eax
80101b01:	8d 50 ff             	lea    -0x1(%eax),%edx
80101b04:	8b 45 08             	mov    0x8(%ebp),%eax
80101b07:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101b0a:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101b11:	e8 53 31 00 00       	call   80104c69 <release>
}
80101b16:	c9                   	leave  
80101b17:	c3                   	ret    

80101b18 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101b18:	55                   	push   %ebp
80101b19:	89 e5                	mov    %esp,%ebp
80101b1b:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101b1e:	8b 45 08             	mov    0x8(%ebp),%eax
80101b21:	89 04 24             	mov    %eax,(%esp)
80101b24:	e8 b9 fe ff ff       	call   801019e2 <iunlock>
  iput(ip);
80101b29:	8b 45 08             	mov    0x8(%ebp),%eax
80101b2c:	89 04 24             	mov    %eax,(%esp)
80101b2f:	e8 13 ff ff ff       	call   80101a47 <iput>
}
80101b34:	c9                   	leave  
80101b35:	c3                   	ret    

80101b36 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101b36:	55                   	push   %ebp
80101b37:	89 e5                	mov    %esp,%ebp
80101b39:	53                   	push   %ebx
80101b3a:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101b3d:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101b41:	77 3e                	ja     80101b81 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101b43:	8b 45 08             	mov    0x8(%ebp),%eax
80101b46:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b49:	83 c2 04             	add    $0x4,%edx
80101b4c:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b50:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b53:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b57:	75 20                	jne    80101b79 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101b59:	8b 45 08             	mov    0x8(%ebp),%eax
80101b5c:	8b 00                	mov    (%eax),%eax
80101b5e:	89 04 24             	mov    %eax,(%esp)
80101b61:	e8 45 f8 ff ff       	call   801013ab <balloc>
80101b66:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b69:	8b 45 08             	mov    0x8(%ebp),%eax
80101b6c:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b6f:	8d 4a 04             	lea    0x4(%edx),%ecx
80101b72:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b75:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101b79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b7c:	e9 bc 00 00 00       	jmp    80101c3d <bmap+0x107>
  }
  bn -= NDIRECT;
80101b81:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101b85:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101b89:	0f 87 a2 00 00 00    	ja     80101c31 <bmap+0xfb>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101b8f:	8b 45 08             	mov    0x8(%ebp),%eax
80101b92:	8b 40 4c             	mov    0x4c(%eax),%eax
80101b95:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b98:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b9c:	75 19                	jne    80101bb7 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101b9e:	8b 45 08             	mov    0x8(%ebp),%eax
80101ba1:	8b 00                	mov    (%eax),%eax
80101ba3:	89 04 24             	mov    %eax,(%esp)
80101ba6:	e8 00 f8 ff ff       	call   801013ab <balloc>
80101bab:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bae:	8b 45 08             	mov    0x8(%ebp),%eax
80101bb1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bb4:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101bb7:	8b 45 08             	mov    0x8(%ebp),%eax
80101bba:	8b 00                	mov    (%eax),%eax
80101bbc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bbf:	89 54 24 04          	mov    %edx,0x4(%esp)
80101bc3:	89 04 24             	mov    %eax,(%esp)
80101bc6:	e8 db e5 ff ff       	call   801001a6 <bread>
80101bcb:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101bce:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101bd1:	83 c0 18             	add    $0x18,%eax
80101bd4:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101bd7:	8b 45 0c             	mov    0xc(%ebp),%eax
80101bda:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101be1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101be4:	01 d0                	add    %edx,%eax
80101be6:	8b 00                	mov    (%eax),%eax
80101be8:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101beb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101bef:	75 30                	jne    80101c21 <bmap+0xeb>
      a[bn] = addr = balloc(ip->dev);
80101bf1:	8b 45 0c             	mov    0xc(%ebp),%eax
80101bf4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101bfb:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101bfe:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101c01:	8b 45 08             	mov    0x8(%ebp),%eax
80101c04:	8b 00                	mov    (%eax),%eax
80101c06:	89 04 24             	mov    %eax,(%esp)
80101c09:	e8 9d f7 ff ff       	call   801013ab <balloc>
80101c0e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c14:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101c16:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c19:	89 04 24             	mov    %eax,(%esp)
80101c1c:	e8 f0 16 00 00       	call   80103311 <log_write>
    }
    brelse(bp);
80101c21:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c24:	89 04 24             	mov    %eax,(%esp)
80101c27:	e8 eb e5 ff ff       	call   80100217 <brelse>
    return addr;
80101c2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c2f:	eb 0c                	jmp    80101c3d <bmap+0x107>
  }

  panic("bmap: out of range");
80101c31:	c7 04 24 32 83 10 80 	movl   $0x80108332,(%esp)
80101c38:	e8 09 e9 ff ff       	call   80100546 <panic>
}
80101c3d:	83 c4 24             	add    $0x24,%esp
80101c40:	5b                   	pop    %ebx
80101c41:	5d                   	pop    %ebp
80101c42:	c3                   	ret    

80101c43 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101c43:	55                   	push   %ebp
80101c44:	89 e5                	mov    %esp,%ebp
80101c46:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c49:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101c50:	eb 44                	jmp    80101c96 <itrunc+0x53>
    if(ip->addrs[i]){
80101c52:	8b 45 08             	mov    0x8(%ebp),%eax
80101c55:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c58:	83 c2 04             	add    $0x4,%edx
80101c5b:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c5f:	85 c0                	test   %eax,%eax
80101c61:	74 2f                	je     80101c92 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101c63:	8b 45 08             	mov    0x8(%ebp),%eax
80101c66:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c69:	83 c2 04             	add    $0x4,%edx
80101c6c:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c70:	8b 45 08             	mov    0x8(%ebp),%eax
80101c73:	8b 00                	mov    (%eax),%eax
80101c75:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c79:	89 04 24             	mov    %eax,(%esp)
80101c7c:	e8 83 f8 ff ff       	call   80101504 <bfree>
      ip->addrs[i] = 0;
80101c81:	8b 45 08             	mov    0x8(%ebp),%eax
80101c84:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c87:	83 c2 04             	add    $0x4,%edx
80101c8a:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101c91:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c92:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101c96:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101c9a:	7e b6                	jle    80101c52 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101c9c:	8b 45 08             	mov    0x8(%ebp),%eax
80101c9f:	8b 40 4c             	mov    0x4c(%eax),%eax
80101ca2:	85 c0                	test   %eax,%eax
80101ca4:	0f 84 9b 00 00 00    	je     80101d45 <itrunc+0x102>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101caa:	8b 45 08             	mov    0x8(%ebp),%eax
80101cad:	8b 50 4c             	mov    0x4c(%eax),%edx
80101cb0:	8b 45 08             	mov    0x8(%ebp),%eax
80101cb3:	8b 00                	mov    (%eax),%eax
80101cb5:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cb9:	89 04 24             	mov    %eax,(%esp)
80101cbc:	e8 e5 e4 ff ff       	call   801001a6 <bread>
80101cc1:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101cc4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cc7:	83 c0 18             	add    $0x18,%eax
80101cca:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101ccd:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101cd4:	eb 3b                	jmp    80101d11 <itrunc+0xce>
      if(a[j])
80101cd6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cd9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101ce0:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101ce3:	01 d0                	add    %edx,%eax
80101ce5:	8b 00                	mov    (%eax),%eax
80101ce7:	85 c0                	test   %eax,%eax
80101ce9:	74 22                	je     80101d0d <itrunc+0xca>
        bfree(ip->dev, a[j]);
80101ceb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cee:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101cf5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101cf8:	01 d0                	add    %edx,%eax
80101cfa:	8b 10                	mov    (%eax),%edx
80101cfc:	8b 45 08             	mov    0x8(%ebp),%eax
80101cff:	8b 00                	mov    (%eax),%eax
80101d01:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d05:	89 04 24             	mov    %eax,(%esp)
80101d08:	e8 f7 f7 ff ff       	call   80101504 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101d0d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101d11:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d14:	83 f8 7f             	cmp    $0x7f,%eax
80101d17:	76 bd                	jbe    80101cd6 <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101d19:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d1c:	89 04 24             	mov    %eax,(%esp)
80101d1f:	e8 f3 e4 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101d24:	8b 45 08             	mov    0x8(%ebp),%eax
80101d27:	8b 50 4c             	mov    0x4c(%eax),%edx
80101d2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d2d:	8b 00                	mov    (%eax),%eax
80101d2f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d33:	89 04 24             	mov    %eax,(%esp)
80101d36:	e8 c9 f7 ff ff       	call   80101504 <bfree>
    ip->addrs[NDIRECT] = 0;
80101d3b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d3e:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101d45:	8b 45 08             	mov    0x8(%ebp),%eax
80101d48:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101d4f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d52:	89 04 24             	mov    %eax,(%esp)
80101d55:	e8 7e f9 ff ff       	call   801016d8 <iupdate>
}
80101d5a:	c9                   	leave  
80101d5b:	c3                   	ret    

80101d5c <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101d5c:	55                   	push   %ebp
80101d5d:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101d5f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d62:	8b 00                	mov    (%eax),%eax
80101d64:	89 c2                	mov    %eax,%edx
80101d66:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d69:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101d6c:	8b 45 08             	mov    0x8(%ebp),%eax
80101d6f:	8b 50 04             	mov    0x4(%eax),%edx
80101d72:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d75:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101d78:	8b 45 08             	mov    0x8(%ebp),%eax
80101d7b:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101d7f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d82:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101d85:	8b 45 08             	mov    0x8(%ebp),%eax
80101d88:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101d8c:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d8f:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101d93:	8b 45 08             	mov    0x8(%ebp),%eax
80101d96:	8b 50 18             	mov    0x18(%eax),%edx
80101d99:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d9c:	89 50 10             	mov    %edx,0x10(%eax)
}
80101d9f:	5d                   	pop    %ebp
80101da0:	c3                   	ret    

80101da1 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101da1:	55                   	push   %ebp
80101da2:	89 e5                	mov    %esp,%ebp
80101da4:	53                   	push   %ebx
80101da5:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101da8:	8b 45 08             	mov    0x8(%ebp),%eax
80101dab:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101daf:	66 83 f8 03          	cmp    $0x3,%ax
80101db3:	75 60                	jne    80101e15 <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101db5:	8b 45 08             	mov    0x8(%ebp),%eax
80101db8:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101dbc:	66 85 c0             	test   %ax,%ax
80101dbf:	78 20                	js     80101de1 <readi+0x40>
80101dc1:	8b 45 08             	mov    0x8(%ebp),%eax
80101dc4:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101dc8:	66 83 f8 09          	cmp    $0x9,%ax
80101dcc:	7f 13                	jg     80101de1 <readi+0x40>
80101dce:	8b 45 08             	mov    0x8(%ebp),%eax
80101dd1:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101dd5:	98                   	cwtl   
80101dd6:	8b 04 c5 00 e8 10 80 	mov    -0x7fef1800(,%eax,8),%eax
80101ddd:	85 c0                	test   %eax,%eax
80101ddf:	75 0a                	jne    80101deb <readi+0x4a>
      return -1;
80101de1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101de6:	e9 1e 01 00 00       	jmp    80101f09 <readi+0x168>
    return devsw[ip->major].read(ip, dst, n);
80101deb:	8b 45 08             	mov    0x8(%ebp),%eax
80101dee:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101df2:	98                   	cwtl   
80101df3:	8b 04 c5 00 e8 10 80 	mov    -0x7fef1800(,%eax,8),%eax
80101dfa:	8b 55 14             	mov    0x14(%ebp),%edx
80101dfd:	89 54 24 08          	mov    %edx,0x8(%esp)
80101e01:	8b 55 0c             	mov    0xc(%ebp),%edx
80101e04:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e08:	8b 55 08             	mov    0x8(%ebp),%edx
80101e0b:	89 14 24             	mov    %edx,(%esp)
80101e0e:	ff d0                	call   *%eax
80101e10:	e9 f4 00 00 00       	jmp    80101f09 <readi+0x168>
  }

  if(off > ip->size || off + n < off)
80101e15:	8b 45 08             	mov    0x8(%ebp),%eax
80101e18:	8b 40 18             	mov    0x18(%eax),%eax
80101e1b:	3b 45 10             	cmp    0x10(%ebp),%eax
80101e1e:	72 0d                	jb     80101e2d <readi+0x8c>
80101e20:	8b 45 14             	mov    0x14(%ebp),%eax
80101e23:	8b 55 10             	mov    0x10(%ebp),%edx
80101e26:	01 d0                	add    %edx,%eax
80101e28:	3b 45 10             	cmp    0x10(%ebp),%eax
80101e2b:	73 0a                	jae    80101e37 <readi+0x96>
    return -1;
80101e2d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101e32:	e9 d2 00 00 00       	jmp    80101f09 <readi+0x168>
  if(off + n > ip->size)
80101e37:	8b 45 14             	mov    0x14(%ebp),%eax
80101e3a:	8b 55 10             	mov    0x10(%ebp),%edx
80101e3d:	01 c2                	add    %eax,%edx
80101e3f:	8b 45 08             	mov    0x8(%ebp),%eax
80101e42:	8b 40 18             	mov    0x18(%eax),%eax
80101e45:	39 c2                	cmp    %eax,%edx
80101e47:	76 0c                	jbe    80101e55 <readi+0xb4>
    n = ip->size - off;
80101e49:	8b 45 08             	mov    0x8(%ebp),%eax
80101e4c:	8b 40 18             	mov    0x18(%eax),%eax
80101e4f:	2b 45 10             	sub    0x10(%ebp),%eax
80101e52:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101e55:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101e5c:	e9 99 00 00 00       	jmp    80101efa <readi+0x159>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101e61:	8b 45 10             	mov    0x10(%ebp),%eax
80101e64:	c1 e8 09             	shr    $0x9,%eax
80101e67:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e6b:	8b 45 08             	mov    0x8(%ebp),%eax
80101e6e:	89 04 24             	mov    %eax,(%esp)
80101e71:	e8 c0 fc ff ff       	call   80101b36 <bmap>
80101e76:	8b 55 08             	mov    0x8(%ebp),%edx
80101e79:	8b 12                	mov    (%edx),%edx
80101e7b:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e7f:	89 14 24             	mov    %edx,(%esp)
80101e82:	e8 1f e3 ff ff       	call   801001a6 <bread>
80101e87:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101e8a:	8b 45 10             	mov    0x10(%ebp),%eax
80101e8d:	89 c2                	mov    %eax,%edx
80101e8f:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80101e95:	b8 00 02 00 00       	mov    $0x200,%eax
80101e9a:	89 c1                	mov    %eax,%ecx
80101e9c:	29 d1                	sub    %edx,%ecx
80101e9e:	89 ca                	mov    %ecx,%edx
80101ea0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ea3:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101ea6:	89 cb                	mov    %ecx,%ebx
80101ea8:	29 c3                	sub    %eax,%ebx
80101eaa:	89 d8                	mov    %ebx,%eax
80101eac:	39 c2                	cmp    %eax,%edx
80101eae:	0f 46 c2             	cmovbe %edx,%eax
80101eb1:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101eb4:	8b 45 10             	mov    0x10(%ebp),%eax
80101eb7:	25 ff 01 00 00       	and    $0x1ff,%eax
80101ebc:	8d 50 10             	lea    0x10(%eax),%edx
80101ebf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ec2:	01 d0                	add    %edx,%eax
80101ec4:	8d 50 08             	lea    0x8(%eax),%edx
80101ec7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101eca:	89 44 24 08          	mov    %eax,0x8(%esp)
80101ece:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ed2:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ed5:	89 04 24             	mov    %eax,(%esp)
80101ed8:	e8 58 30 00 00       	call   80104f35 <memmove>
    brelse(bp);
80101edd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ee0:	89 04 24             	mov    %eax,(%esp)
80101ee3:	e8 2f e3 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101ee8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101eeb:	01 45 f4             	add    %eax,-0xc(%ebp)
80101eee:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ef1:	01 45 10             	add    %eax,0x10(%ebp)
80101ef4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ef7:	01 45 0c             	add    %eax,0xc(%ebp)
80101efa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101efd:	3b 45 14             	cmp    0x14(%ebp),%eax
80101f00:	0f 82 5b ff ff ff    	jb     80101e61 <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80101f06:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101f09:	83 c4 24             	add    $0x24,%esp
80101f0c:	5b                   	pop    %ebx
80101f0d:	5d                   	pop    %ebp
80101f0e:	c3                   	ret    

80101f0f <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101f0f:	55                   	push   %ebp
80101f10:	89 e5                	mov    %esp,%ebp
80101f12:	53                   	push   %ebx
80101f13:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101f16:	8b 45 08             	mov    0x8(%ebp),%eax
80101f19:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101f1d:	66 83 f8 03          	cmp    $0x3,%ax
80101f21:	75 60                	jne    80101f83 <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101f23:	8b 45 08             	mov    0x8(%ebp),%eax
80101f26:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f2a:	66 85 c0             	test   %ax,%ax
80101f2d:	78 20                	js     80101f4f <writei+0x40>
80101f2f:	8b 45 08             	mov    0x8(%ebp),%eax
80101f32:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f36:	66 83 f8 09          	cmp    $0x9,%ax
80101f3a:	7f 13                	jg     80101f4f <writei+0x40>
80101f3c:	8b 45 08             	mov    0x8(%ebp),%eax
80101f3f:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f43:	98                   	cwtl   
80101f44:	8b 04 c5 04 e8 10 80 	mov    -0x7fef17fc(,%eax,8),%eax
80101f4b:	85 c0                	test   %eax,%eax
80101f4d:	75 0a                	jne    80101f59 <writei+0x4a>
      return -1;
80101f4f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f54:	e9 49 01 00 00       	jmp    801020a2 <writei+0x193>
    return devsw[ip->major].write(ip, src, n);
80101f59:	8b 45 08             	mov    0x8(%ebp),%eax
80101f5c:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f60:	98                   	cwtl   
80101f61:	8b 04 c5 04 e8 10 80 	mov    -0x7fef17fc(,%eax,8),%eax
80101f68:	8b 55 14             	mov    0x14(%ebp),%edx
80101f6b:	89 54 24 08          	mov    %edx,0x8(%esp)
80101f6f:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f72:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f76:	8b 55 08             	mov    0x8(%ebp),%edx
80101f79:	89 14 24             	mov    %edx,(%esp)
80101f7c:	ff d0                	call   *%eax
80101f7e:	e9 1f 01 00 00       	jmp    801020a2 <writei+0x193>
  }

  if(off > ip->size || off + n < off)
80101f83:	8b 45 08             	mov    0x8(%ebp),%eax
80101f86:	8b 40 18             	mov    0x18(%eax),%eax
80101f89:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f8c:	72 0d                	jb     80101f9b <writei+0x8c>
80101f8e:	8b 45 14             	mov    0x14(%ebp),%eax
80101f91:	8b 55 10             	mov    0x10(%ebp),%edx
80101f94:	01 d0                	add    %edx,%eax
80101f96:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f99:	73 0a                	jae    80101fa5 <writei+0x96>
    return -1;
80101f9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101fa0:	e9 fd 00 00 00       	jmp    801020a2 <writei+0x193>
  if(off + n > MAXFILE*BSIZE)
80101fa5:	8b 45 14             	mov    0x14(%ebp),%eax
80101fa8:	8b 55 10             	mov    0x10(%ebp),%edx
80101fab:	01 d0                	add    %edx,%eax
80101fad:	3d 00 18 01 00       	cmp    $0x11800,%eax
80101fb2:	76 0a                	jbe    80101fbe <writei+0xaf>
    return -1;
80101fb4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101fb9:	e9 e4 00 00 00       	jmp    801020a2 <writei+0x193>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80101fbe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101fc5:	e9 a4 00 00 00       	jmp    8010206e <writei+0x15f>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101fca:	8b 45 10             	mov    0x10(%ebp),%eax
80101fcd:	c1 e8 09             	shr    $0x9,%eax
80101fd0:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fd4:	8b 45 08             	mov    0x8(%ebp),%eax
80101fd7:	89 04 24             	mov    %eax,(%esp)
80101fda:	e8 57 fb ff ff       	call   80101b36 <bmap>
80101fdf:	8b 55 08             	mov    0x8(%ebp),%edx
80101fe2:	8b 12                	mov    (%edx),%edx
80101fe4:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fe8:	89 14 24             	mov    %edx,(%esp)
80101feb:	e8 b6 e1 ff ff       	call   801001a6 <bread>
80101ff0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101ff3:	8b 45 10             	mov    0x10(%ebp),%eax
80101ff6:	89 c2                	mov    %eax,%edx
80101ff8:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80101ffe:	b8 00 02 00 00       	mov    $0x200,%eax
80102003:	89 c1                	mov    %eax,%ecx
80102005:	29 d1                	sub    %edx,%ecx
80102007:	89 ca                	mov    %ecx,%edx
80102009:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010200c:	8b 4d 14             	mov    0x14(%ebp),%ecx
8010200f:	89 cb                	mov    %ecx,%ebx
80102011:	29 c3                	sub    %eax,%ebx
80102013:	89 d8                	mov    %ebx,%eax
80102015:	39 c2                	cmp    %eax,%edx
80102017:	0f 46 c2             	cmovbe %edx,%eax
8010201a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
8010201d:	8b 45 10             	mov    0x10(%ebp),%eax
80102020:	25 ff 01 00 00       	and    $0x1ff,%eax
80102025:	8d 50 10             	lea    0x10(%eax),%edx
80102028:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010202b:	01 d0                	add    %edx,%eax
8010202d:	8d 50 08             	lea    0x8(%eax),%edx
80102030:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102033:	89 44 24 08          	mov    %eax,0x8(%esp)
80102037:	8b 45 0c             	mov    0xc(%ebp),%eax
8010203a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010203e:	89 14 24             	mov    %edx,(%esp)
80102041:	e8 ef 2e 00 00       	call   80104f35 <memmove>
    log_write(bp);
80102046:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102049:	89 04 24             	mov    %eax,(%esp)
8010204c:	e8 c0 12 00 00       	call   80103311 <log_write>
    brelse(bp);
80102051:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102054:	89 04 24             	mov    %eax,(%esp)
80102057:	e8 bb e1 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010205c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010205f:	01 45 f4             	add    %eax,-0xc(%ebp)
80102062:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102065:	01 45 10             	add    %eax,0x10(%ebp)
80102068:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010206b:	01 45 0c             	add    %eax,0xc(%ebp)
8010206e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102071:	3b 45 14             	cmp    0x14(%ebp),%eax
80102074:	0f 82 50 ff ff ff    	jb     80101fca <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
8010207a:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010207e:	74 1f                	je     8010209f <writei+0x190>
80102080:	8b 45 08             	mov    0x8(%ebp),%eax
80102083:	8b 40 18             	mov    0x18(%eax),%eax
80102086:	3b 45 10             	cmp    0x10(%ebp),%eax
80102089:	73 14                	jae    8010209f <writei+0x190>
    ip->size = off;
8010208b:	8b 45 08             	mov    0x8(%ebp),%eax
8010208e:	8b 55 10             	mov    0x10(%ebp),%edx
80102091:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102094:	8b 45 08             	mov    0x8(%ebp),%eax
80102097:	89 04 24             	mov    %eax,(%esp)
8010209a:	e8 39 f6 ff ff       	call   801016d8 <iupdate>
  }
  return n;
8010209f:	8b 45 14             	mov    0x14(%ebp),%eax
}
801020a2:	83 c4 24             	add    $0x24,%esp
801020a5:	5b                   	pop    %ebx
801020a6:	5d                   	pop    %ebp
801020a7:	c3                   	ret    

801020a8 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
801020a8:	55                   	push   %ebp
801020a9:	89 e5                	mov    %esp,%ebp
801020ab:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
801020ae:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801020b5:	00 
801020b6:	8b 45 0c             	mov    0xc(%ebp),%eax
801020b9:	89 44 24 04          	mov    %eax,0x4(%esp)
801020bd:	8b 45 08             	mov    0x8(%ebp),%eax
801020c0:	89 04 24             	mov    %eax,(%esp)
801020c3:	e8 11 2f 00 00       	call   80104fd9 <strncmp>
}
801020c8:	c9                   	leave  
801020c9:	c3                   	ret    

801020ca <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
801020ca:	55                   	push   %ebp
801020cb:	89 e5                	mov    %esp,%ebp
801020cd:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
801020d0:	8b 45 08             	mov    0x8(%ebp),%eax
801020d3:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801020d7:	66 83 f8 01          	cmp    $0x1,%ax
801020db:	74 0c                	je     801020e9 <dirlookup+0x1f>
    panic("dirlookup not DIR");
801020dd:	c7 04 24 45 83 10 80 	movl   $0x80108345,(%esp)
801020e4:	e8 5d e4 ff ff       	call   80100546 <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
801020e9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801020f0:	e9 87 00 00 00       	jmp    8010217c <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801020f5:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801020fc:	00 
801020fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102100:	89 44 24 08          	mov    %eax,0x8(%esp)
80102104:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102107:	89 44 24 04          	mov    %eax,0x4(%esp)
8010210b:	8b 45 08             	mov    0x8(%ebp),%eax
8010210e:	89 04 24             	mov    %eax,(%esp)
80102111:	e8 8b fc ff ff       	call   80101da1 <readi>
80102116:	83 f8 10             	cmp    $0x10,%eax
80102119:	74 0c                	je     80102127 <dirlookup+0x5d>
      panic("dirlink read");
8010211b:	c7 04 24 57 83 10 80 	movl   $0x80108357,(%esp)
80102122:	e8 1f e4 ff ff       	call   80100546 <panic>
    if(de.inum == 0)
80102127:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010212b:	66 85 c0             	test   %ax,%ax
8010212e:	74 47                	je     80102177 <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
80102130:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102133:	83 c0 02             	add    $0x2,%eax
80102136:	89 44 24 04          	mov    %eax,0x4(%esp)
8010213a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010213d:	89 04 24             	mov    %eax,(%esp)
80102140:	e8 63 ff ff ff       	call   801020a8 <namecmp>
80102145:	85 c0                	test   %eax,%eax
80102147:	75 2f                	jne    80102178 <dirlookup+0xae>
      // entry matches path element
      if(poff)
80102149:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010214d:	74 08                	je     80102157 <dirlookup+0x8d>
        *poff = off;
8010214f:	8b 45 10             	mov    0x10(%ebp),%eax
80102152:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102155:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102157:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010215b:	0f b7 c0             	movzwl %ax,%eax
8010215e:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102161:	8b 45 08             	mov    0x8(%ebp),%eax
80102164:	8b 00                	mov    (%eax),%eax
80102166:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102169:	89 54 24 04          	mov    %edx,0x4(%esp)
8010216d:	89 04 24             	mov    %eax,(%esp)
80102170:	e8 1b f6 ff ff       	call   80101790 <iget>
80102175:	eb 19                	jmp    80102190 <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
80102177:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
80102178:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010217c:	8b 45 08             	mov    0x8(%ebp),%eax
8010217f:	8b 40 18             	mov    0x18(%eax),%eax
80102182:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102185:	0f 87 6a ff ff ff    	ja     801020f5 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
8010218b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102190:	c9                   	leave  
80102191:	c3                   	ret    

80102192 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102192:	55                   	push   %ebp
80102193:	89 e5                	mov    %esp,%ebp
80102195:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102198:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010219f:	00 
801021a0:	8b 45 0c             	mov    0xc(%ebp),%eax
801021a3:	89 44 24 04          	mov    %eax,0x4(%esp)
801021a7:	8b 45 08             	mov    0x8(%ebp),%eax
801021aa:	89 04 24             	mov    %eax,(%esp)
801021ad:	e8 18 ff ff ff       	call   801020ca <dirlookup>
801021b2:	89 45 f0             	mov    %eax,-0x10(%ebp)
801021b5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801021b9:	74 15                	je     801021d0 <dirlink+0x3e>
    iput(ip);
801021bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021be:	89 04 24             	mov    %eax,(%esp)
801021c1:	e8 81 f8 ff ff       	call   80101a47 <iput>
    return -1;
801021c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801021cb:	e9 b8 00 00 00       	jmp    80102288 <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801021d0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801021d7:	eb 44                	jmp    8010221d <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801021d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021dc:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801021e3:	00 
801021e4:	89 44 24 08          	mov    %eax,0x8(%esp)
801021e8:	8d 45 e0             	lea    -0x20(%ebp),%eax
801021eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801021ef:	8b 45 08             	mov    0x8(%ebp),%eax
801021f2:	89 04 24             	mov    %eax,(%esp)
801021f5:	e8 a7 fb ff ff       	call   80101da1 <readi>
801021fa:	83 f8 10             	cmp    $0x10,%eax
801021fd:	74 0c                	je     8010220b <dirlink+0x79>
      panic("dirlink read");
801021ff:	c7 04 24 57 83 10 80 	movl   $0x80108357,(%esp)
80102206:	e8 3b e3 ff ff       	call   80100546 <panic>
    if(de.inum == 0)
8010220b:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010220f:	66 85 c0             	test   %ax,%ax
80102212:	74 18                	je     8010222c <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102214:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102217:	83 c0 10             	add    $0x10,%eax
8010221a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010221d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102220:	8b 45 08             	mov    0x8(%ebp),%eax
80102223:	8b 40 18             	mov    0x18(%eax),%eax
80102226:	39 c2                	cmp    %eax,%edx
80102228:	72 af                	jb     801021d9 <dirlink+0x47>
8010222a:	eb 01                	jmp    8010222d <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
8010222c:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
8010222d:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102234:	00 
80102235:	8b 45 0c             	mov    0xc(%ebp),%eax
80102238:	89 44 24 04          	mov    %eax,0x4(%esp)
8010223c:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010223f:	83 c0 02             	add    $0x2,%eax
80102242:	89 04 24             	mov    %eax,(%esp)
80102245:	e8 e7 2d 00 00       	call   80105031 <strncpy>
  de.inum = inum;
8010224a:	8b 45 10             	mov    0x10(%ebp),%eax
8010224d:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102251:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102254:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010225b:	00 
8010225c:	89 44 24 08          	mov    %eax,0x8(%esp)
80102260:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102263:	89 44 24 04          	mov    %eax,0x4(%esp)
80102267:	8b 45 08             	mov    0x8(%ebp),%eax
8010226a:	89 04 24             	mov    %eax,(%esp)
8010226d:	e8 9d fc ff ff       	call   80101f0f <writei>
80102272:	83 f8 10             	cmp    $0x10,%eax
80102275:	74 0c                	je     80102283 <dirlink+0xf1>
    panic("dirlink");
80102277:	c7 04 24 64 83 10 80 	movl   $0x80108364,(%esp)
8010227e:	e8 c3 e2 ff ff       	call   80100546 <panic>
  
  return 0;
80102283:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102288:	c9                   	leave  
80102289:	c3                   	ret    

8010228a <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
8010228a:	55                   	push   %ebp
8010228b:	89 e5                	mov    %esp,%ebp
8010228d:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
80102290:	eb 04                	jmp    80102296 <skipelem+0xc>
    path++;
80102292:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102296:	8b 45 08             	mov    0x8(%ebp),%eax
80102299:	0f b6 00             	movzbl (%eax),%eax
8010229c:	3c 2f                	cmp    $0x2f,%al
8010229e:	74 f2                	je     80102292 <skipelem+0x8>
    path++;
  if(*path == 0)
801022a0:	8b 45 08             	mov    0x8(%ebp),%eax
801022a3:	0f b6 00             	movzbl (%eax),%eax
801022a6:	84 c0                	test   %al,%al
801022a8:	75 0a                	jne    801022b4 <skipelem+0x2a>
    return 0;
801022aa:	b8 00 00 00 00       	mov    $0x0,%eax
801022af:	e9 88 00 00 00       	jmp    8010233c <skipelem+0xb2>
  s = path;
801022b4:	8b 45 08             	mov    0x8(%ebp),%eax
801022b7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
801022ba:	eb 04                	jmp    801022c0 <skipelem+0x36>
    path++;
801022bc:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
801022c0:	8b 45 08             	mov    0x8(%ebp),%eax
801022c3:	0f b6 00             	movzbl (%eax),%eax
801022c6:	3c 2f                	cmp    $0x2f,%al
801022c8:	74 0a                	je     801022d4 <skipelem+0x4a>
801022ca:	8b 45 08             	mov    0x8(%ebp),%eax
801022cd:	0f b6 00             	movzbl (%eax),%eax
801022d0:	84 c0                	test   %al,%al
801022d2:	75 e8                	jne    801022bc <skipelem+0x32>
    path++;
  len = path - s;
801022d4:	8b 55 08             	mov    0x8(%ebp),%edx
801022d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022da:	89 d1                	mov    %edx,%ecx
801022dc:	29 c1                	sub    %eax,%ecx
801022de:	89 c8                	mov    %ecx,%eax
801022e0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
801022e3:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801022e7:	7e 1c                	jle    80102305 <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
801022e9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801022f0:	00 
801022f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022f4:	89 44 24 04          	mov    %eax,0x4(%esp)
801022f8:	8b 45 0c             	mov    0xc(%ebp),%eax
801022fb:	89 04 24             	mov    %eax,(%esp)
801022fe:	e8 32 2c 00 00       	call   80104f35 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102303:	eb 2a                	jmp    8010232f <skipelem+0xa5>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80102305:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102308:	89 44 24 08          	mov    %eax,0x8(%esp)
8010230c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010230f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102313:	8b 45 0c             	mov    0xc(%ebp),%eax
80102316:	89 04 24             	mov    %eax,(%esp)
80102319:	e8 17 2c 00 00       	call   80104f35 <memmove>
    name[len] = 0;
8010231e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102321:	8b 45 0c             	mov    0xc(%ebp),%eax
80102324:	01 d0                	add    %edx,%eax
80102326:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
80102329:	eb 04                	jmp    8010232f <skipelem+0xa5>
    path++;
8010232b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
8010232f:	8b 45 08             	mov    0x8(%ebp),%eax
80102332:	0f b6 00             	movzbl (%eax),%eax
80102335:	3c 2f                	cmp    $0x2f,%al
80102337:	74 f2                	je     8010232b <skipelem+0xa1>
    path++;
  return path;
80102339:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010233c:	c9                   	leave  
8010233d:	c3                   	ret    

8010233e <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
8010233e:	55                   	push   %ebp
8010233f:	89 e5                	mov    %esp,%ebp
80102341:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102344:	8b 45 08             	mov    0x8(%ebp),%eax
80102347:	0f b6 00             	movzbl (%eax),%eax
8010234a:	3c 2f                	cmp    $0x2f,%al
8010234c:	75 1c                	jne    8010236a <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
8010234e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102355:	00 
80102356:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010235d:	e8 2e f4 ff ff       	call   80101790 <iget>
80102362:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102365:	e9 af 00 00 00       	jmp    80102419 <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
8010236a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102370:	8b 40 68             	mov    0x68(%eax),%eax
80102373:	89 04 24             	mov    %eax,(%esp)
80102376:	e8 e7 f4 ff ff       	call   80101862 <idup>
8010237b:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
8010237e:	e9 96 00 00 00       	jmp    80102419 <namex+0xdb>
    ilock(ip);
80102383:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102386:	89 04 24             	mov    %eax,(%esp)
80102389:	e8 06 f5 ff ff       	call   80101894 <ilock>
    if(ip->type != T_DIR){
8010238e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102391:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102395:	66 83 f8 01          	cmp    $0x1,%ax
80102399:	74 15                	je     801023b0 <namex+0x72>
      iunlockput(ip);
8010239b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010239e:	89 04 24             	mov    %eax,(%esp)
801023a1:	e8 72 f7 ff ff       	call   80101b18 <iunlockput>
      return 0;
801023a6:	b8 00 00 00 00       	mov    $0x0,%eax
801023ab:	e9 a3 00 00 00       	jmp    80102453 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
801023b0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801023b4:	74 1d                	je     801023d3 <namex+0x95>
801023b6:	8b 45 08             	mov    0x8(%ebp),%eax
801023b9:	0f b6 00             	movzbl (%eax),%eax
801023bc:	84 c0                	test   %al,%al
801023be:	75 13                	jne    801023d3 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
801023c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023c3:	89 04 24             	mov    %eax,(%esp)
801023c6:	e8 17 f6 ff ff       	call   801019e2 <iunlock>
      return ip;
801023cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023ce:	e9 80 00 00 00       	jmp    80102453 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
801023d3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801023da:	00 
801023db:	8b 45 10             	mov    0x10(%ebp),%eax
801023de:	89 44 24 04          	mov    %eax,0x4(%esp)
801023e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023e5:	89 04 24             	mov    %eax,(%esp)
801023e8:	e8 dd fc ff ff       	call   801020ca <dirlookup>
801023ed:	89 45 f0             	mov    %eax,-0x10(%ebp)
801023f0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801023f4:	75 12                	jne    80102408 <namex+0xca>
      iunlockput(ip);
801023f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023f9:	89 04 24             	mov    %eax,(%esp)
801023fc:	e8 17 f7 ff ff       	call   80101b18 <iunlockput>
      return 0;
80102401:	b8 00 00 00 00       	mov    $0x0,%eax
80102406:	eb 4b                	jmp    80102453 <namex+0x115>
    }
    iunlockput(ip);
80102408:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010240b:	89 04 24             	mov    %eax,(%esp)
8010240e:	e8 05 f7 ff ff       	call   80101b18 <iunlockput>
    ip = next;
80102413:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102416:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102419:	8b 45 10             	mov    0x10(%ebp),%eax
8010241c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102420:	8b 45 08             	mov    0x8(%ebp),%eax
80102423:	89 04 24             	mov    %eax,(%esp)
80102426:	e8 5f fe ff ff       	call   8010228a <skipelem>
8010242b:	89 45 08             	mov    %eax,0x8(%ebp)
8010242e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102432:	0f 85 4b ff ff ff    	jne    80102383 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102438:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010243c:	74 12                	je     80102450 <namex+0x112>
    iput(ip);
8010243e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102441:	89 04 24             	mov    %eax,(%esp)
80102444:	e8 fe f5 ff ff       	call   80101a47 <iput>
    return 0;
80102449:	b8 00 00 00 00       	mov    $0x0,%eax
8010244e:	eb 03                	jmp    80102453 <namex+0x115>
  }
  return ip;
80102450:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102453:	c9                   	leave  
80102454:	c3                   	ret    

80102455 <namei>:

struct inode*
namei(char *path)
{
80102455:	55                   	push   %ebp
80102456:	89 e5                	mov    %esp,%ebp
80102458:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
8010245b:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010245e:	89 44 24 08          	mov    %eax,0x8(%esp)
80102462:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102469:	00 
8010246a:	8b 45 08             	mov    0x8(%ebp),%eax
8010246d:	89 04 24             	mov    %eax,(%esp)
80102470:	e8 c9 fe ff ff       	call   8010233e <namex>
}
80102475:	c9                   	leave  
80102476:	c3                   	ret    

80102477 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102477:	55                   	push   %ebp
80102478:	89 e5                	mov    %esp,%ebp
8010247a:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
8010247d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102480:	89 44 24 08          	mov    %eax,0x8(%esp)
80102484:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010248b:	00 
8010248c:	8b 45 08             	mov    0x8(%ebp),%eax
8010248f:	89 04 24             	mov    %eax,(%esp)
80102492:	e8 a7 fe ff ff       	call   8010233e <namex>
}
80102497:	c9                   	leave  
80102498:	c3                   	ret    
80102499:	66 90                	xchg   %ax,%ax
8010249b:	90                   	nop

8010249c <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010249c:	55                   	push   %ebp
8010249d:	89 e5                	mov    %esp,%ebp
8010249f:	53                   	push   %ebx
801024a0:	83 ec 14             	sub    $0x14,%esp
801024a3:	8b 45 08             	mov    0x8(%ebp),%eax
801024a6:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801024aa:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801024ae:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801024b2:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801024b6:	ec                   	in     (%dx),%al
801024b7:	89 c3                	mov    %eax,%ebx
801024b9:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801024bc:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801024c0:	83 c4 14             	add    $0x14,%esp
801024c3:	5b                   	pop    %ebx
801024c4:	5d                   	pop    %ebp
801024c5:	c3                   	ret    

801024c6 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
801024c6:	55                   	push   %ebp
801024c7:	89 e5                	mov    %esp,%ebp
801024c9:	57                   	push   %edi
801024ca:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
801024cb:	8b 55 08             	mov    0x8(%ebp),%edx
801024ce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801024d1:	8b 45 10             	mov    0x10(%ebp),%eax
801024d4:	89 cb                	mov    %ecx,%ebx
801024d6:	89 df                	mov    %ebx,%edi
801024d8:	89 c1                	mov    %eax,%ecx
801024da:	fc                   	cld    
801024db:	f3 6d                	rep insl (%dx),%es:(%edi)
801024dd:	89 c8                	mov    %ecx,%eax
801024df:	89 fb                	mov    %edi,%ebx
801024e1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801024e4:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
801024e7:	5b                   	pop    %ebx
801024e8:	5f                   	pop    %edi
801024e9:	5d                   	pop    %ebp
801024ea:	c3                   	ret    

801024eb <outb>:

static inline void
outb(ushort port, uchar data)
{
801024eb:	55                   	push   %ebp
801024ec:	89 e5                	mov    %esp,%ebp
801024ee:	83 ec 08             	sub    $0x8,%esp
801024f1:	8b 55 08             	mov    0x8(%ebp),%edx
801024f4:	8b 45 0c             	mov    0xc(%ebp),%eax
801024f7:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801024fb:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801024fe:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102502:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102506:	ee                   	out    %al,(%dx)
}
80102507:	c9                   	leave  
80102508:	c3                   	ret    

80102509 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80102509:	55                   	push   %ebp
8010250a:	89 e5                	mov    %esp,%ebp
8010250c:	56                   	push   %esi
8010250d:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
8010250e:	8b 55 08             	mov    0x8(%ebp),%edx
80102511:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102514:	8b 45 10             	mov    0x10(%ebp),%eax
80102517:	89 cb                	mov    %ecx,%ebx
80102519:	89 de                	mov    %ebx,%esi
8010251b:	89 c1                	mov    %eax,%ecx
8010251d:	fc                   	cld    
8010251e:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102520:	89 c8                	mov    %ecx,%eax
80102522:	89 f3                	mov    %esi,%ebx
80102524:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102527:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
8010252a:	5b                   	pop    %ebx
8010252b:	5e                   	pop    %esi
8010252c:	5d                   	pop    %ebp
8010252d:	c3                   	ret    

8010252e <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
8010252e:	55                   	push   %ebp
8010252f:	89 e5                	mov    %esp,%ebp
80102531:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80102534:	90                   	nop
80102535:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010253c:	e8 5b ff ff ff       	call   8010249c <inb>
80102541:	0f b6 c0             	movzbl %al,%eax
80102544:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102547:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010254a:	25 c0 00 00 00       	and    $0xc0,%eax
8010254f:	83 f8 40             	cmp    $0x40,%eax
80102552:	75 e1                	jne    80102535 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102554:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102558:	74 11                	je     8010256b <idewait+0x3d>
8010255a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010255d:	83 e0 21             	and    $0x21,%eax
80102560:	85 c0                	test   %eax,%eax
80102562:	74 07                	je     8010256b <idewait+0x3d>
    return -1;
80102564:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102569:	eb 05                	jmp    80102570 <idewait+0x42>
  return 0;
8010256b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102570:	c9                   	leave  
80102571:	c3                   	ret    

80102572 <ideinit>:

void
ideinit(void)
{
80102572:	55                   	push   %ebp
80102573:	89 e5                	mov    %esp,%ebp
80102575:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80102578:	c7 44 24 04 6c 83 10 	movl   $0x8010836c,0x4(%esp)
8010257f:	80 
80102580:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102587:	e8 5a 26 00 00       	call   80104be6 <initlock>
  picenable(IRQ_IDE);
8010258c:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102593:	e8 85 15 00 00       	call   80103b1d <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102598:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
8010259d:	83 e8 01             	sub    $0x1,%eax
801025a0:	89 44 24 04          	mov    %eax,0x4(%esp)
801025a4:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801025ab:	e8 12 04 00 00       	call   801029c2 <ioapicenable>
  idewait(0);
801025b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801025b7:	e8 72 ff ff ff       	call   8010252e <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
801025bc:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
801025c3:	00 
801025c4:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801025cb:	e8 1b ff ff ff       	call   801024eb <outb>
  for(i=0; i<1000; i++){
801025d0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801025d7:	eb 20                	jmp    801025f9 <ideinit+0x87>
    if(inb(0x1f7) != 0){
801025d9:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801025e0:	e8 b7 fe ff ff       	call   8010249c <inb>
801025e5:	84 c0                	test   %al,%al
801025e7:	74 0c                	je     801025f5 <ideinit+0x83>
      havedisk1 = 1;
801025e9:	c7 05 38 b6 10 80 01 	movl   $0x1,0x8010b638
801025f0:	00 00 00 
      break;
801025f3:	eb 0d                	jmp    80102602 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801025f5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801025f9:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102600:	7e d7                	jle    801025d9 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80102602:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80102609:	00 
8010260a:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102611:	e8 d5 fe ff ff       	call   801024eb <outb>
}
80102616:	c9                   	leave  
80102617:	c3                   	ret    

80102618 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80102618:	55                   	push   %ebp
80102619:	89 e5                	mov    %esp,%ebp
8010261b:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
8010261e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102622:	75 0c                	jne    80102630 <idestart+0x18>
    panic("idestart");
80102624:	c7 04 24 70 83 10 80 	movl   $0x80108370,(%esp)
8010262b:	e8 16 df ff ff       	call   80100546 <panic>

  idewait(0);
80102630:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102637:	e8 f2 fe ff ff       	call   8010252e <idewait>
  outb(0x3f6, 0);  // generate interrupt
8010263c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102643:	00 
80102644:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
8010264b:	e8 9b fe ff ff       	call   801024eb <outb>
  outb(0x1f2, 1);  // number of sectors
80102650:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102657:	00 
80102658:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
8010265f:	e8 87 fe ff ff       	call   801024eb <outb>
  outb(0x1f3, b->sector & 0xff);
80102664:	8b 45 08             	mov    0x8(%ebp),%eax
80102667:	8b 40 08             	mov    0x8(%eax),%eax
8010266a:	0f b6 c0             	movzbl %al,%eax
8010266d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102671:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102678:	e8 6e fe ff ff       	call   801024eb <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
8010267d:	8b 45 08             	mov    0x8(%ebp),%eax
80102680:	8b 40 08             	mov    0x8(%eax),%eax
80102683:	c1 e8 08             	shr    $0x8,%eax
80102686:	0f b6 c0             	movzbl %al,%eax
80102689:	89 44 24 04          	mov    %eax,0x4(%esp)
8010268d:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102694:	e8 52 fe ff ff       	call   801024eb <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
80102699:	8b 45 08             	mov    0x8(%ebp),%eax
8010269c:	8b 40 08             	mov    0x8(%eax),%eax
8010269f:	c1 e8 10             	shr    $0x10,%eax
801026a2:	0f b6 c0             	movzbl %al,%eax
801026a5:	89 44 24 04          	mov    %eax,0x4(%esp)
801026a9:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
801026b0:	e8 36 fe ff ff       	call   801024eb <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
801026b5:	8b 45 08             	mov    0x8(%ebp),%eax
801026b8:	8b 40 04             	mov    0x4(%eax),%eax
801026bb:	83 e0 01             	and    $0x1,%eax
801026be:	89 c2                	mov    %eax,%edx
801026c0:	c1 e2 04             	shl    $0x4,%edx
801026c3:	8b 45 08             	mov    0x8(%ebp),%eax
801026c6:	8b 40 08             	mov    0x8(%eax),%eax
801026c9:	c1 e8 18             	shr    $0x18,%eax
801026cc:	83 e0 0f             	and    $0xf,%eax
801026cf:	09 d0                	or     %edx,%eax
801026d1:	83 c8 e0             	or     $0xffffffe0,%eax
801026d4:	0f b6 c0             	movzbl %al,%eax
801026d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801026db:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801026e2:	e8 04 fe ff ff       	call   801024eb <outb>
  if(b->flags & B_DIRTY){
801026e7:	8b 45 08             	mov    0x8(%ebp),%eax
801026ea:	8b 00                	mov    (%eax),%eax
801026ec:	83 e0 04             	and    $0x4,%eax
801026ef:	85 c0                	test   %eax,%eax
801026f1:	74 34                	je     80102727 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
801026f3:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
801026fa:	00 
801026fb:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102702:	e8 e4 fd ff ff       	call   801024eb <outb>
    outsl(0x1f0, b->data, 512/4);
80102707:	8b 45 08             	mov    0x8(%ebp),%eax
8010270a:	83 c0 18             	add    $0x18,%eax
8010270d:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102714:	00 
80102715:	89 44 24 04          	mov    %eax,0x4(%esp)
80102719:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102720:	e8 e4 fd ff ff       	call   80102509 <outsl>
80102725:	eb 14                	jmp    8010273b <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80102727:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
8010272e:	00 
8010272f:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102736:	e8 b0 fd ff ff       	call   801024eb <outb>
  }
}
8010273b:	c9                   	leave  
8010273c:	c3                   	ret    

8010273d <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
8010273d:	55                   	push   %ebp
8010273e:	89 e5                	mov    %esp,%ebp
80102740:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80102743:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
8010274a:	e8 b8 24 00 00       	call   80104c07 <acquire>
  if((b = idequeue) == 0){
8010274f:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102754:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102757:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010275b:	75 11                	jne    8010276e <ideintr+0x31>
    release(&idelock);
8010275d:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102764:	e8 00 25 00 00       	call   80104c69 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102769:	e9 90 00 00 00       	jmp    801027fe <ideintr+0xc1>
  }
  idequeue = b->qnext;
8010276e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102771:	8b 40 14             	mov    0x14(%eax),%eax
80102774:	a3 34 b6 10 80       	mov    %eax,0x8010b634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102779:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010277c:	8b 00                	mov    (%eax),%eax
8010277e:	83 e0 04             	and    $0x4,%eax
80102781:	85 c0                	test   %eax,%eax
80102783:	75 2e                	jne    801027b3 <ideintr+0x76>
80102785:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010278c:	e8 9d fd ff ff       	call   8010252e <idewait>
80102791:	85 c0                	test   %eax,%eax
80102793:	78 1e                	js     801027b3 <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
80102795:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102798:	83 c0 18             	add    $0x18,%eax
8010279b:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801027a2:	00 
801027a3:	89 44 24 04          	mov    %eax,0x4(%esp)
801027a7:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801027ae:	e8 13 fd ff ff       	call   801024c6 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
801027b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027b6:	8b 00                	mov    (%eax),%eax
801027b8:	89 c2                	mov    %eax,%edx
801027ba:	83 ca 02             	or     $0x2,%edx
801027bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027c0:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
801027c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027c5:	8b 00                	mov    (%eax),%eax
801027c7:	89 c2                	mov    %eax,%edx
801027c9:	83 e2 fb             	and    $0xfffffffb,%edx
801027cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027cf:	89 10                	mov    %edx,(%eax)
  wakeup(b);
801027d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027d4:	89 04 24             	mov    %eax,(%esp)
801027d7:	e8 26 22 00 00       	call   80104a02 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
801027dc:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801027e1:	85 c0                	test   %eax,%eax
801027e3:	74 0d                	je     801027f2 <ideintr+0xb5>
    idestart(idequeue);
801027e5:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801027ea:	89 04 24             	mov    %eax,(%esp)
801027ed:	e8 26 fe ff ff       	call   80102618 <idestart>

  release(&idelock);
801027f2:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801027f9:	e8 6b 24 00 00       	call   80104c69 <release>
}
801027fe:	c9                   	leave  
801027ff:	c3                   	ret    

80102800 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80102800:	55                   	push   %ebp
80102801:	89 e5                	mov    %esp,%ebp
80102803:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80102806:	8b 45 08             	mov    0x8(%ebp),%eax
80102809:	8b 00                	mov    (%eax),%eax
8010280b:	83 e0 01             	and    $0x1,%eax
8010280e:	85 c0                	test   %eax,%eax
80102810:	75 0c                	jne    8010281e <iderw+0x1e>
    panic("iderw: buf not busy");
80102812:	c7 04 24 79 83 10 80 	movl   $0x80108379,(%esp)
80102819:	e8 28 dd ff ff       	call   80100546 <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
8010281e:	8b 45 08             	mov    0x8(%ebp),%eax
80102821:	8b 00                	mov    (%eax),%eax
80102823:	83 e0 06             	and    $0x6,%eax
80102826:	83 f8 02             	cmp    $0x2,%eax
80102829:	75 0c                	jne    80102837 <iderw+0x37>
    panic("iderw: nothing to do");
8010282b:	c7 04 24 8d 83 10 80 	movl   $0x8010838d,(%esp)
80102832:	e8 0f dd ff ff       	call   80100546 <panic>
  if(b->dev != 0 && !havedisk1)
80102837:	8b 45 08             	mov    0x8(%ebp),%eax
8010283a:	8b 40 04             	mov    0x4(%eax),%eax
8010283d:	85 c0                	test   %eax,%eax
8010283f:	74 15                	je     80102856 <iderw+0x56>
80102841:	a1 38 b6 10 80       	mov    0x8010b638,%eax
80102846:	85 c0                	test   %eax,%eax
80102848:	75 0c                	jne    80102856 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
8010284a:	c7 04 24 a2 83 10 80 	movl   $0x801083a2,(%esp)
80102851:	e8 f0 dc ff ff       	call   80100546 <panic>

  acquire(&idelock);  //DOC: acquire-lock
80102856:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
8010285d:	e8 a5 23 00 00       	call   80104c07 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102862:	8b 45 08             	mov    0x8(%ebp),%eax
80102865:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
8010286c:	c7 45 f4 34 b6 10 80 	movl   $0x8010b634,-0xc(%ebp)
80102873:	eb 0b                	jmp    80102880 <iderw+0x80>
80102875:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102878:	8b 00                	mov    (%eax),%eax
8010287a:	83 c0 14             	add    $0x14,%eax
8010287d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102880:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102883:	8b 00                	mov    (%eax),%eax
80102885:	85 c0                	test   %eax,%eax
80102887:	75 ec                	jne    80102875 <iderw+0x75>
    ;
  *pp = b;
80102889:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010288c:	8b 55 08             	mov    0x8(%ebp),%edx
8010288f:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102891:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102896:	3b 45 08             	cmp    0x8(%ebp),%eax
80102899:	75 22                	jne    801028bd <iderw+0xbd>
    idestart(b);
8010289b:	8b 45 08             	mov    0x8(%ebp),%eax
8010289e:	89 04 24             	mov    %eax,(%esp)
801028a1:	e8 72 fd ff ff       	call   80102618 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
801028a6:	eb 15                	jmp    801028bd <iderw+0xbd>
    sleep(b, &idelock);
801028a8:	c7 44 24 04 00 b6 10 	movl   $0x8010b600,0x4(%esp)
801028af:	80 
801028b0:	8b 45 08             	mov    0x8(%ebp),%eax
801028b3:	89 04 24             	mov    %eax,(%esp)
801028b6:	e8 6e 20 00 00       	call   80104929 <sleep>
801028bb:	eb 01                	jmp    801028be <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
801028bd:	90                   	nop
801028be:	8b 45 08             	mov    0x8(%ebp),%eax
801028c1:	8b 00                	mov    (%eax),%eax
801028c3:	83 e0 06             	and    $0x6,%eax
801028c6:	83 f8 02             	cmp    $0x2,%eax
801028c9:	75 dd                	jne    801028a8 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
801028cb:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801028d2:	e8 92 23 00 00       	call   80104c69 <release>
}
801028d7:	c9                   	leave  
801028d8:	c3                   	ret    
801028d9:	66 90                	xchg   %ax,%ax
801028db:	90                   	nop

801028dc <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
801028dc:	55                   	push   %ebp
801028dd:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801028df:	a1 34 f8 10 80       	mov    0x8010f834,%eax
801028e4:	8b 55 08             	mov    0x8(%ebp),%edx
801028e7:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
801028e9:	a1 34 f8 10 80       	mov    0x8010f834,%eax
801028ee:	8b 40 10             	mov    0x10(%eax),%eax
}
801028f1:	5d                   	pop    %ebp
801028f2:	c3                   	ret    

801028f3 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
801028f3:	55                   	push   %ebp
801028f4:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801028f6:	a1 34 f8 10 80       	mov    0x8010f834,%eax
801028fb:	8b 55 08             	mov    0x8(%ebp),%edx
801028fe:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102900:	a1 34 f8 10 80       	mov    0x8010f834,%eax
80102905:	8b 55 0c             	mov    0xc(%ebp),%edx
80102908:	89 50 10             	mov    %edx,0x10(%eax)
}
8010290b:	5d                   	pop    %ebp
8010290c:	c3                   	ret    

8010290d <ioapicinit>:

void
ioapicinit(void)
{
8010290d:	55                   	push   %ebp
8010290e:	89 e5                	mov    %esp,%ebp
80102910:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102913:	a1 04 f9 10 80       	mov    0x8010f904,%eax
80102918:	85 c0                	test   %eax,%eax
8010291a:	0f 84 9f 00 00 00    	je     801029bf <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
80102920:	c7 05 34 f8 10 80 00 	movl   $0xfec00000,0x8010f834
80102927:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
8010292a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102931:	e8 a6 ff ff ff       	call   801028dc <ioapicread>
80102936:	c1 e8 10             	shr    $0x10,%eax
80102939:	25 ff 00 00 00       	and    $0xff,%eax
8010293e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102941:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102948:	e8 8f ff ff ff       	call   801028dc <ioapicread>
8010294d:	c1 e8 18             	shr    $0x18,%eax
80102950:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102953:	0f b6 05 00 f9 10 80 	movzbl 0x8010f900,%eax
8010295a:	0f b6 c0             	movzbl %al,%eax
8010295d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102960:	74 0c                	je     8010296e <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102962:	c7 04 24 c0 83 10 80 	movl   $0x801083c0,(%esp)
80102969:	e8 3c da ff ff       	call   801003aa <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
8010296e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102975:	eb 3e                	jmp    801029b5 <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102977:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010297a:	83 c0 20             	add    $0x20,%eax
8010297d:	0d 00 00 01 00       	or     $0x10000,%eax
80102982:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102985:	83 c2 08             	add    $0x8,%edx
80102988:	01 d2                	add    %edx,%edx
8010298a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010298e:	89 14 24             	mov    %edx,(%esp)
80102991:	e8 5d ff ff ff       	call   801028f3 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102996:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102999:	83 c0 08             	add    $0x8,%eax
8010299c:	01 c0                	add    %eax,%eax
8010299e:	83 c0 01             	add    $0x1,%eax
801029a1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801029a8:	00 
801029a9:	89 04 24             	mov    %eax,(%esp)
801029ac:	e8 42 ff ff ff       	call   801028f3 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
801029b1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801029b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029b8:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801029bb:	7e ba                	jle    80102977 <ioapicinit+0x6a>
801029bd:	eb 01                	jmp    801029c0 <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
801029bf:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
801029c0:	c9                   	leave  
801029c1:	c3                   	ret    

801029c2 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
801029c2:	55                   	push   %ebp
801029c3:	89 e5                	mov    %esp,%ebp
801029c5:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
801029c8:	a1 04 f9 10 80       	mov    0x8010f904,%eax
801029cd:	85 c0                	test   %eax,%eax
801029cf:	74 39                	je     80102a0a <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
801029d1:	8b 45 08             	mov    0x8(%ebp),%eax
801029d4:	83 c0 20             	add    $0x20,%eax
801029d7:	8b 55 08             	mov    0x8(%ebp),%edx
801029da:	83 c2 08             	add    $0x8,%edx
801029dd:	01 d2                	add    %edx,%edx
801029df:	89 44 24 04          	mov    %eax,0x4(%esp)
801029e3:	89 14 24             	mov    %edx,(%esp)
801029e6:	e8 08 ff ff ff       	call   801028f3 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
801029eb:	8b 45 0c             	mov    0xc(%ebp),%eax
801029ee:	c1 e0 18             	shl    $0x18,%eax
801029f1:	8b 55 08             	mov    0x8(%ebp),%edx
801029f4:	83 c2 08             	add    $0x8,%edx
801029f7:	01 d2                	add    %edx,%edx
801029f9:	83 c2 01             	add    $0x1,%edx
801029fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a00:	89 14 24             	mov    %edx,(%esp)
80102a03:	e8 eb fe ff ff       	call   801028f3 <ioapicwrite>
80102a08:	eb 01                	jmp    80102a0b <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
80102a0a:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
80102a0b:	c9                   	leave  
80102a0c:	c3                   	ret    
80102a0d:	66 90                	xchg   %ax,%ax
80102a0f:	90                   	nop

80102a10 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102a10:	55                   	push   %ebp
80102a11:	89 e5                	mov    %esp,%ebp
80102a13:	8b 45 08             	mov    0x8(%ebp),%eax
80102a16:	05 00 00 00 80       	add    $0x80000000,%eax
80102a1b:	5d                   	pop    %ebp
80102a1c:	c3                   	ret    

80102a1d <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102a1d:	55                   	push   %ebp
80102a1e:	89 e5                	mov    %esp,%ebp
80102a20:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102a23:	c7 44 24 04 f2 83 10 	movl   $0x801083f2,0x4(%esp)
80102a2a:	80 
80102a2b:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102a32:	e8 af 21 00 00       	call   80104be6 <initlock>
  kmem.use_lock = 0;
80102a37:	c7 05 74 f8 10 80 00 	movl   $0x0,0x8010f874
80102a3e:	00 00 00 
  freerange(vstart, vend);
80102a41:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a44:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a48:	8b 45 08             	mov    0x8(%ebp),%eax
80102a4b:	89 04 24             	mov    %eax,(%esp)
80102a4e:	e8 26 00 00 00       	call   80102a79 <freerange>
}
80102a53:	c9                   	leave  
80102a54:	c3                   	ret    

80102a55 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102a55:	55                   	push   %ebp
80102a56:	89 e5                	mov    %esp,%ebp
80102a58:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102a5b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a5e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a62:	8b 45 08             	mov    0x8(%ebp),%eax
80102a65:	89 04 24             	mov    %eax,(%esp)
80102a68:	e8 0c 00 00 00       	call   80102a79 <freerange>
  kmem.use_lock = 1;
80102a6d:	c7 05 74 f8 10 80 01 	movl   $0x1,0x8010f874
80102a74:	00 00 00 
}
80102a77:	c9                   	leave  
80102a78:	c3                   	ret    

80102a79 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102a79:	55                   	push   %ebp
80102a7a:	89 e5                	mov    %esp,%ebp
80102a7c:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102a7f:	8b 45 08             	mov    0x8(%ebp),%eax
80102a82:	05 ff 0f 00 00       	add    $0xfff,%eax
80102a87:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102a8c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a8f:	eb 12                	jmp    80102aa3 <freerange+0x2a>
    kfree(p);
80102a91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a94:	89 04 24             	mov    %eax,(%esp)
80102a97:	e8 16 00 00 00       	call   80102ab2 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a9c:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102aa3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aa6:	05 00 10 00 00       	add    $0x1000,%eax
80102aab:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102aae:	76 e1                	jbe    80102a91 <freerange+0x18>
    kfree(p);
}
80102ab0:	c9                   	leave  
80102ab1:	c3                   	ret    

80102ab2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102ab2:	55                   	push   %ebp
80102ab3:	89 e5                	mov    %esp,%ebp
80102ab5:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102ab8:	8b 45 08             	mov    0x8(%ebp),%eax
80102abb:	25 ff 0f 00 00       	and    $0xfff,%eax
80102ac0:	85 c0                	test   %eax,%eax
80102ac2:	75 1b                	jne    80102adf <kfree+0x2d>
80102ac4:	81 7d 08 fc 26 11 80 	cmpl   $0x801126fc,0x8(%ebp)
80102acb:	72 12                	jb     80102adf <kfree+0x2d>
80102acd:	8b 45 08             	mov    0x8(%ebp),%eax
80102ad0:	89 04 24             	mov    %eax,(%esp)
80102ad3:	e8 38 ff ff ff       	call   80102a10 <v2p>
80102ad8:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102add:	76 0c                	jbe    80102aeb <kfree+0x39>
    panic("kfree");
80102adf:	c7 04 24 f7 83 10 80 	movl   $0x801083f7,(%esp)
80102ae6:	e8 5b da ff ff       	call   80100546 <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102aeb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102af2:	00 
80102af3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102afa:	00 
80102afb:	8b 45 08             	mov    0x8(%ebp),%eax
80102afe:	89 04 24             	mov    %eax,(%esp)
80102b01:	e8 5c 23 00 00       	call   80104e62 <memset>

  if(kmem.use_lock)
80102b06:	a1 74 f8 10 80       	mov    0x8010f874,%eax
80102b0b:	85 c0                	test   %eax,%eax
80102b0d:	74 0c                	je     80102b1b <kfree+0x69>
    acquire(&kmem.lock);
80102b0f:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102b16:	e8 ec 20 00 00       	call   80104c07 <acquire>
  r = (struct run*)v;
80102b1b:	8b 45 08             	mov    0x8(%ebp),%eax
80102b1e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102b21:	8b 15 78 f8 10 80    	mov    0x8010f878,%edx
80102b27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b2a:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102b2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b2f:	a3 78 f8 10 80       	mov    %eax,0x8010f878
  if(kmem.use_lock)
80102b34:	a1 74 f8 10 80       	mov    0x8010f874,%eax
80102b39:	85 c0                	test   %eax,%eax
80102b3b:	74 0c                	je     80102b49 <kfree+0x97>
    release(&kmem.lock);
80102b3d:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102b44:	e8 20 21 00 00       	call   80104c69 <release>
}
80102b49:	c9                   	leave  
80102b4a:	c3                   	ret    

80102b4b <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102b4b:	55                   	push   %ebp
80102b4c:	89 e5                	mov    %esp,%ebp
80102b4e:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102b51:	a1 74 f8 10 80       	mov    0x8010f874,%eax
80102b56:	85 c0                	test   %eax,%eax
80102b58:	74 0c                	je     80102b66 <kalloc+0x1b>
    acquire(&kmem.lock);
80102b5a:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102b61:	e8 a1 20 00 00       	call   80104c07 <acquire>
  r = kmem.freelist;
80102b66:	a1 78 f8 10 80       	mov    0x8010f878,%eax
80102b6b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102b6e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102b72:	74 0a                	je     80102b7e <kalloc+0x33>
    kmem.freelist = r->next;
80102b74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b77:	8b 00                	mov    (%eax),%eax
80102b79:	a3 78 f8 10 80       	mov    %eax,0x8010f878
  if(kmem.use_lock)
80102b7e:	a1 74 f8 10 80       	mov    0x8010f874,%eax
80102b83:	85 c0                	test   %eax,%eax
80102b85:	74 0c                	je     80102b93 <kalloc+0x48>
    release(&kmem.lock);
80102b87:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102b8e:	e8 d6 20 00 00       	call   80104c69 <release>
  return (char*)r;
80102b93:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102b96:	c9                   	leave  
80102b97:	c3                   	ret    

80102b98 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102b98:	55                   	push   %ebp
80102b99:	89 e5                	mov    %esp,%ebp
80102b9b:	53                   	push   %ebx
80102b9c:	83 ec 14             	sub    $0x14,%esp
80102b9f:	8b 45 08             	mov    0x8(%ebp),%eax
80102ba2:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102ba6:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102baa:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102bae:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102bb2:	ec                   	in     (%dx),%al
80102bb3:	89 c3                	mov    %eax,%ebx
80102bb5:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102bb8:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102bbc:	83 c4 14             	add    $0x14,%esp
80102bbf:	5b                   	pop    %ebx
80102bc0:	5d                   	pop    %ebp
80102bc1:	c3                   	ret    

80102bc2 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102bc2:	55                   	push   %ebp
80102bc3:	89 e5                	mov    %esp,%ebp
80102bc5:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102bc8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102bcf:	e8 c4 ff ff ff       	call   80102b98 <inb>
80102bd4:	0f b6 c0             	movzbl %al,%eax
80102bd7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102bda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bdd:	83 e0 01             	and    $0x1,%eax
80102be0:	85 c0                	test   %eax,%eax
80102be2:	75 0a                	jne    80102bee <kbdgetc+0x2c>
    return -1;
80102be4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102be9:	e9 25 01 00 00       	jmp    80102d13 <kbdgetc+0x151>
  data = inb(KBDATAP);
80102bee:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102bf5:	e8 9e ff ff ff       	call   80102b98 <inb>
80102bfa:	0f b6 c0             	movzbl %al,%eax
80102bfd:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102c00:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102c07:	75 17                	jne    80102c20 <kbdgetc+0x5e>
    shift |= E0ESC;
80102c09:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c0e:	83 c8 40             	or     $0x40,%eax
80102c11:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102c16:	b8 00 00 00 00       	mov    $0x0,%eax
80102c1b:	e9 f3 00 00 00       	jmp    80102d13 <kbdgetc+0x151>
  } else if(data & 0x80){
80102c20:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c23:	25 80 00 00 00       	and    $0x80,%eax
80102c28:	85 c0                	test   %eax,%eax
80102c2a:	74 45                	je     80102c71 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102c2c:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c31:	83 e0 40             	and    $0x40,%eax
80102c34:	85 c0                	test   %eax,%eax
80102c36:	75 08                	jne    80102c40 <kbdgetc+0x7e>
80102c38:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c3b:	83 e0 7f             	and    $0x7f,%eax
80102c3e:	eb 03                	jmp    80102c43 <kbdgetc+0x81>
80102c40:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c43:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102c46:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c49:	05 20 90 10 80       	add    $0x80109020,%eax
80102c4e:	0f b6 00             	movzbl (%eax),%eax
80102c51:	83 c8 40             	or     $0x40,%eax
80102c54:	0f b6 c0             	movzbl %al,%eax
80102c57:	f7 d0                	not    %eax
80102c59:	89 c2                	mov    %eax,%edx
80102c5b:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c60:	21 d0                	and    %edx,%eax
80102c62:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102c67:	b8 00 00 00 00       	mov    $0x0,%eax
80102c6c:	e9 a2 00 00 00       	jmp    80102d13 <kbdgetc+0x151>
  } else if(shift & E0ESC){
80102c71:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c76:	83 e0 40             	and    $0x40,%eax
80102c79:	85 c0                	test   %eax,%eax
80102c7b:	74 14                	je     80102c91 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102c7d:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102c84:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c89:	83 e0 bf             	and    $0xffffffbf,%eax
80102c8c:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  }

  shift |= shiftcode[data];
80102c91:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c94:	05 20 90 10 80       	add    $0x80109020,%eax
80102c99:	0f b6 00             	movzbl (%eax),%eax
80102c9c:	0f b6 d0             	movzbl %al,%edx
80102c9f:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102ca4:	09 d0                	or     %edx,%eax
80102ca6:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  shift ^= togglecode[data];
80102cab:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102cae:	05 20 91 10 80       	add    $0x80109120,%eax
80102cb3:	0f b6 00             	movzbl (%eax),%eax
80102cb6:	0f b6 d0             	movzbl %al,%edx
80102cb9:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cbe:	31 d0                	xor    %edx,%eax
80102cc0:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102cc5:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cca:	83 e0 03             	and    $0x3,%eax
80102ccd:	8b 14 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%edx
80102cd4:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102cd7:	01 d0                	add    %edx,%eax
80102cd9:	0f b6 00             	movzbl (%eax),%eax
80102cdc:	0f b6 c0             	movzbl %al,%eax
80102cdf:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102ce2:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102ce7:	83 e0 08             	and    $0x8,%eax
80102cea:	85 c0                	test   %eax,%eax
80102cec:	74 22                	je     80102d10 <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
80102cee:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102cf2:	76 0c                	jbe    80102d00 <kbdgetc+0x13e>
80102cf4:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102cf8:	77 06                	ja     80102d00 <kbdgetc+0x13e>
      c += 'A' - 'a';
80102cfa:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102cfe:	eb 10                	jmp    80102d10 <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80102d00:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102d04:	76 0a                	jbe    80102d10 <kbdgetc+0x14e>
80102d06:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102d0a:	77 04                	ja     80102d10 <kbdgetc+0x14e>
      c += 'a' - 'A';
80102d0c:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102d10:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102d13:	c9                   	leave  
80102d14:	c3                   	ret    

80102d15 <kbdintr>:

void
kbdintr(void)
{
80102d15:	55                   	push   %ebp
80102d16:	89 e5                	mov    %esp,%ebp
80102d18:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102d1b:	c7 04 24 c2 2b 10 80 	movl   $0x80102bc2,(%esp)
80102d22:	e8 8f da ff ff       	call   801007b6 <consoleintr>
}
80102d27:	c9                   	leave  
80102d28:	c3                   	ret    
80102d29:	66 90                	xchg   %ax,%ax
80102d2b:	90                   	nop

80102d2c <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102d2c:	55                   	push   %ebp
80102d2d:	89 e5                	mov    %esp,%ebp
80102d2f:	83 ec 08             	sub    $0x8,%esp
80102d32:	8b 55 08             	mov    0x8(%ebp),%edx
80102d35:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d38:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102d3c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102d3f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102d43:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102d47:	ee                   	out    %al,(%dx)
}
80102d48:	c9                   	leave  
80102d49:	c3                   	ret    

80102d4a <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102d4a:	55                   	push   %ebp
80102d4b:	89 e5                	mov    %esp,%ebp
80102d4d:	53                   	push   %ebx
80102d4e:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102d51:	9c                   	pushf  
80102d52:	5b                   	pop    %ebx
80102d53:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80102d56:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102d59:	83 c4 10             	add    $0x10,%esp
80102d5c:	5b                   	pop    %ebx
80102d5d:	5d                   	pop    %ebp
80102d5e:	c3                   	ret    

80102d5f <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102d5f:	55                   	push   %ebp
80102d60:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102d62:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102d67:	8b 55 08             	mov    0x8(%ebp),%edx
80102d6a:	c1 e2 02             	shl    $0x2,%edx
80102d6d:	01 c2                	add    %eax,%edx
80102d6f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d72:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102d74:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102d79:	83 c0 20             	add    $0x20,%eax
80102d7c:	8b 00                	mov    (%eax),%eax
}
80102d7e:	5d                   	pop    %ebp
80102d7f:	c3                   	ret    

80102d80 <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
80102d80:	55                   	push   %ebp
80102d81:	89 e5                	mov    %esp,%ebp
80102d83:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102d86:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102d8b:	85 c0                	test   %eax,%eax
80102d8d:	0f 84 47 01 00 00    	je     80102eda <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102d93:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102d9a:	00 
80102d9b:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102da2:	e8 b8 ff ff ff       	call   80102d5f <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102da7:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102dae:	00 
80102daf:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102db6:	e8 a4 ff ff ff       	call   80102d5f <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102dbb:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102dc2:	00 
80102dc3:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102dca:	e8 90 ff ff ff       	call   80102d5f <lapicw>
  lapicw(TICR, 10000000); 
80102dcf:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102dd6:	00 
80102dd7:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102dde:	e8 7c ff ff ff       	call   80102d5f <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102de3:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102dea:	00 
80102deb:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102df2:	e8 68 ff ff ff       	call   80102d5f <lapicw>
  lapicw(LINT1, MASKED);
80102df7:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102dfe:	00 
80102dff:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102e06:	e8 54 ff ff ff       	call   80102d5f <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102e0b:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102e10:	83 c0 30             	add    $0x30,%eax
80102e13:	8b 00                	mov    (%eax),%eax
80102e15:	c1 e8 10             	shr    $0x10,%eax
80102e18:	25 ff 00 00 00       	and    $0xff,%eax
80102e1d:	83 f8 03             	cmp    $0x3,%eax
80102e20:	76 14                	jbe    80102e36 <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80102e22:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102e29:	00 
80102e2a:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102e31:	e8 29 ff ff ff       	call   80102d5f <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102e36:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102e3d:	00 
80102e3e:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102e45:	e8 15 ff ff ff       	call   80102d5f <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102e4a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e51:	00 
80102e52:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102e59:	e8 01 ff ff ff       	call   80102d5f <lapicw>
  lapicw(ESR, 0);
80102e5e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e65:	00 
80102e66:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102e6d:	e8 ed fe ff ff       	call   80102d5f <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102e72:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e79:	00 
80102e7a:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102e81:	e8 d9 fe ff ff       	call   80102d5f <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102e86:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e8d:	00 
80102e8e:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102e95:	e8 c5 fe ff ff       	call   80102d5f <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102e9a:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80102ea1:	00 
80102ea2:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102ea9:	e8 b1 fe ff ff       	call   80102d5f <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102eae:	90                   	nop
80102eaf:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102eb4:	05 00 03 00 00       	add    $0x300,%eax
80102eb9:	8b 00                	mov    (%eax),%eax
80102ebb:	25 00 10 00 00       	and    $0x1000,%eax
80102ec0:	85 c0                	test   %eax,%eax
80102ec2:	75 eb                	jne    80102eaf <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102ec4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102ecb:	00 
80102ecc:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80102ed3:	e8 87 fe ff ff       	call   80102d5f <lapicw>
80102ed8:	eb 01                	jmp    80102edb <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
80102eda:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80102edb:	c9                   	leave  
80102edc:	c3                   	ret    

80102edd <cpunum>:

int
cpunum(void)
{
80102edd:	55                   	push   %ebp
80102ede:	89 e5                	mov    %esp,%ebp
80102ee0:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80102ee3:	e8 62 fe ff ff       	call   80102d4a <readeflags>
80102ee8:	25 00 02 00 00       	and    $0x200,%eax
80102eed:	85 c0                	test   %eax,%eax
80102eef:	74 29                	je     80102f1a <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80102ef1:	a1 40 b6 10 80       	mov    0x8010b640,%eax
80102ef6:	85 c0                	test   %eax,%eax
80102ef8:	0f 94 c2             	sete   %dl
80102efb:	83 c0 01             	add    $0x1,%eax
80102efe:	a3 40 b6 10 80       	mov    %eax,0x8010b640
80102f03:	84 d2                	test   %dl,%dl
80102f05:	74 13                	je     80102f1a <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80102f07:	8b 45 04             	mov    0x4(%ebp),%eax
80102f0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f0e:	c7 04 24 00 84 10 80 	movl   $0x80108400,(%esp)
80102f15:	e8 90 d4 ff ff       	call   801003aa <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80102f1a:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102f1f:	85 c0                	test   %eax,%eax
80102f21:	74 0f                	je     80102f32 <cpunum+0x55>
    return lapic[ID]>>24;
80102f23:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102f28:	83 c0 20             	add    $0x20,%eax
80102f2b:	8b 00                	mov    (%eax),%eax
80102f2d:	c1 e8 18             	shr    $0x18,%eax
80102f30:	eb 05                	jmp    80102f37 <cpunum+0x5a>
  return 0;
80102f32:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102f37:	c9                   	leave  
80102f38:	c3                   	ret    

80102f39 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80102f39:	55                   	push   %ebp
80102f3a:	89 e5                	mov    %esp,%ebp
80102f3c:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80102f3f:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102f44:	85 c0                	test   %eax,%eax
80102f46:	74 14                	je     80102f5c <lapiceoi+0x23>
    lapicw(EOI, 0);
80102f48:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f4f:	00 
80102f50:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102f57:	e8 03 fe ff ff       	call   80102d5f <lapicw>
}
80102f5c:	c9                   	leave  
80102f5d:	c3                   	ret    

80102f5e <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80102f5e:	55                   	push   %ebp
80102f5f:	89 e5                	mov    %esp,%ebp
}
80102f61:	5d                   	pop    %ebp
80102f62:	c3                   	ret    

80102f63 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80102f63:	55                   	push   %ebp
80102f64:	89 e5                	mov    %esp,%ebp
80102f66:	83 ec 1c             	sub    $0x1c,%esp
80102f69:	8b 45 08             	mov    0x8(%ebp),%eax
80102f6c:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
80102f6f:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80102f76:	00 
80102f77:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80102f7e:	e8 a9 fd ff ff       	call   80102d2c <outb>
  outb(IO_RTC+1, 0x0A);
80102f83:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80102f8a:	00 
80102f8b:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80102f92:	e8 95 fd ff ff       	call   80102d2c <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80102f97:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80102f9e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102fa1:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80102fa6:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102fa9:	8d 50 02             	lea    0x2(%eax),%edx
80102fac:	8b 45 0c             	mov    0xc(%ebp),%eax
80102faf:	c1 e8 04             	shr    $0x4,%eax
80102fb2:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80102fb5:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80102fb9:	c1 e0 18             	shl    $0x18,%eax
80102fbc:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fc0:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102fc7:	e8 93 fd ff ff       	call   80102d5f <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102fcc:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80102fd3:	00 
80102fd4:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102fdb:	e8 7f fd ff ff       	call   80102d5f <lapicw>
  microdelay(200);
80102fe0:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102fe7:	e8 72 ff ff ff       	call   80102f5e <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80102fec:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80102ff3:	00 
80102ff4:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102ffb:	e8 5f fd ff ff       	call   80102d5f <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103000:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103007:	e8 52 ff ff ff       	call   80102f5e <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010300c:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103013:	eb 40                	jmp    80103055 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103015:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103019:	c1 e0 18             	shl    $0x18,%eax
8010301c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103020:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103027:	e8 33 fd ff ff       	call   80102d5f <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
8010302c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010302f:	c1 e8 0c             	shr    $0xc,%eax
80103032:	80 cc 06             	or     $0x6,%ah
80103035:	89 44 24 04          	mov    %eax,0x4(%esp)
80103039:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103040:	e8 1a fd ff ff       	call   80102d5f <lapicw>
    microdelay(200);
80103045:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010304c:	e8 0d ff ff ff       	call   80102f5e <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103051:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103055:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103059:	7e ba                	jle    80103015 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
8010305b:	c9                   	leave  
8010305c:	c3                   	ret    
8010305d:	66 90                	xchg   %ax,%ax
8010305f:	90                   	nop

80103060 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
80103060:	55                   	push   %ebp
80103061:	89 e5                	mov    %esp,%ebp
80103063:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103066:	c7 44 24 04 2c 84 10 	movl   $0x8010842c,0x4(%esp)
8010306d:	80 
8010306e:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80103075:	e8 6c 1b 00 00       	call   80104be6 <initlock>
  readsb(ROOTDEV, &sb);
8010307a:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010307d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103081:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103088:	e8 87 e2 ff ff       	call   80101314 <readsb>
  log.start = sb.size - sb.nlog;
8010308d:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103090:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103093:	89 d1                	mov    %edx,%ecx
80103095:	29 c1                	sub    %eax,%ecx
80103097:	89 c8                	mov    %ecx,%eax
80103099:	a3 b4 f8 10 80       	mov    %eax,0x8010f8b4
  log.size = sb.nlog;
8010309e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030a1:	a3 b8 f8 10 80       	mov    %eax,0x8010f8b8
  log.dev = ROOTDEV;
801030a6:	c7 05 c0 f8 10 80 01 	movl   $0x1,0x8010f8c0
801030ad:	00 00 00 
  recover_from_log();
801030b0:	e8 9a 01 00 00       	call   8010324f <recover_from_log>
}
801030b5:	c9                   	leave  
801030b6:	c3                   	ret    

801030b7 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801030b7:	55                   	push   %ebp
801030b8:	89 e5                	mov    %esp,%ebp
801030ba:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801030bd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801030c4:	e9 8c 00 00 00       	jmp    80103155 <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801030c9:	8b 15 b4 f8 10 80    	mov    0x8010f8b4,%edx
801030cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030d2:	01 d0                	add    %edx,%eax
801030d4:	83 c0 01             	add    $0x1,%eax
801030d7:	89 c2                	mov    %eax,%edx
801030d9:	a1 c0 f8 10 80       	mov    0x8010f8c0,%eax
801030de:	89 54 24 04          	mov    %edx,0x4(%esp)
801030e2:	89 04 24             	mov    %eax,(%esp)
801030e5:	e8 bc d0 ff ff       	call   801001a6 <bread>
801030ea:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
801030ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030f0:	83 c0 10             	add    $0x10,%eax
801030f3:	8b 04 85 88 f8 10 80 	mov    -0x7fef0778(,%eax,4),%eax
801030fa:	89 c2                	mov    %eax,%edx
801030fc:	a1 c0 f8 10 80       	mov    0x8010f8c0,%eax
80103101:	89 54 24 04          	mov    %edx,0x4(%esp)
80103105:	89 04 24             	mov    %eax,(%esp)
80103108:	e8 99 d0 ff ff       	call   801001a6 <bread>
8010310d:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103110:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103113:	8d 50 18             	lea    0x18(%eax),%edx
80103116:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103119:	83 c0 18             	add    $0x18,%eax
8010311c:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103123:	00 
80103124:	89 54 24 04          	mov    %edx,0x4(%esp)
80103128:	89 04 24             	mov    %eax,(%esp)
8010312b:	e8 05 1e 00 00       	call   80104f35 <memmove>
    bwrite(dbuf);  // write dst to disk
80103130:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103133:	89 04 24             	mov    %eax,(%esp)
80103136:	e8 a2 d0 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
8010313b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010313e:	89 04 24             	mov    %eax,(%esp)
80103141:	e8 d1 d0 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103146:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103149:	89 04 24             	mov    %eax,(%esp)
8010314c:	e8 c6 d0 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103151:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103155:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
8010315a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010315d:	0f 8f 66 ff ff ff    	jg     801030c9 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103163:	c9                   	leave  
80103164:	c3                   	ret    

80103165 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103165:	55                   	push   %ebp
80103166:	89 e5                	mov    %esp,%ebp
80103168:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010316b:	a1 b4 f8 10 80       	mov    0x8010f8b4,%eax
80103170:	89 c2                	mov    %eax,%edx
80103172:	a1 c0 f8 10 80       	mov    0x8010f8c0,%eax
80103177:	89 54 24 04          	mov    %edx,0x4(%esp)
8010317b:	89 04 24             	mov    %eax,(%esp)
8010317e:	e8 23 d0 ff ff       	call   801001a6 <bread>
80103183:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103186:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103189:	83 c0 18             	add    $0x18,%eax
8010318c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
8010318f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103192:	8b 00                	mov    (%eax),%eax
80103194:	a3 c4 f8 10 80       	mov    %eax,0x8010f8c4
  for (i = 0; i < log.lh.n; i++) {
80103199:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801031a0:	eb 1b                	jmp    801031bd <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
801031a2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801031a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801031a8:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
801031ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
801031af:	83 c2 10             	add    $0x10,%edx
801031b2:	89 04 95 88 f8 10 80 	mov    %eax,-0x7fef0778(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
801031b9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801031bd:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
801031c2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801031c5:	7f db                	jg     801031a2 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
801031c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031ca:	89 04 24             	mov    %eax,(%esp)
801031cd:	e8 45 d0 ff ff       	call   80100217 <brelse>
}
801031d2:	c9                   	leave  
801031d3:	c3                   	ret    

801031d4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801031d4:	55                   	push   %ebp
801031d5:	89 e5                	mov    %esp,%ebp
801031d7:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801031da:	a1 b4 f8 10 80       	mov    0x8010f8b4,%eax
801031df:	89 c2                	mov    %eax,%edx
801031e1:	a1 c0 f8 10 80       	mov    0x8010f8c0,%eax
801031e6:	89 54 24 04          	mov    %edx,0x4(%esp)
801031ea:	89 04 24             	mov    %eax,(%esp)
801031ed:	e8 b4 cf ff ff       	call   801001a6 <bread>
801031f2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801031f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031f8:	83 c0 18             	add    $0x18,%eax
801031fb:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801031fe:	8b 15 c4 f8 10 80    	mov    0x8010f8c4,%edx
80103204:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103207:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103209:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103210:	eb 1b                	jmp    8010322d <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
80103212:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103215:	83 c0 10             	add    $0x10,%eax
80103218:	8b 0c 85 88 f8 10 80 	mov    -0x7fef0778(,%eax,4),%ecx
8010321f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103222:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103225:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103229:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010322d:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
80103232:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103235:	7f db                	jg     80103212 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80103237:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010323a:	89 04 24             	mov    %eax,(%esp)
8010323d:	e8 9b cf ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103242:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103245:	89 04 24             	mov    %eax,(%esp)
80103248:	e8 ca cf ff ff       	call   80100217 <brelse>
}
8010324d:	c9                   	leave  
8010324e:	c3                   	ret    

8010324f <recover_from_log>:

static void
recover_from_log(void)
{
8010324f:	55                   	push   %ebp
80103250:	89 e5                	mov    %esp,%ebp
80103252:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103255:	e8 0b ff ff ff       	call   80103165 <read_head>
  install_trans(); // if committed, copy from log to disk
8010325a:	e8 58 fe ff ff       	call   801030b7 <install_trans>
  log.lh.n = 0;
8010325f:	c7 05 c4 f8 10 80 00 	movl   $0x0,0x8010f8c4
80103266:	00 00 00 
  write_head(); // clear the log
80103269:	e8 66 ff ff ff       	call   801031d4 <write_head>
}
8010326e:	c9                   	leave  
8010326f:	c3                   	ret    

80103270 <begin_trans>:

void
begin_trans(void)
{
80103270:	55                   	push   %ebp
80103271:	89 e5                	mov    %esp,%ebp
80103273:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103276:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010327d:	e8 85 19 00 00       	call   80104c07 <acquire>
  while (log.busy) {
80103282:	eb 14                	jmp    80103298 <begin_trans+0x28>
    sleep(&log, &log.lock);
80103284:	c7 44 24 04 80 f8 10 	movl   $0x8010f880,0x4(%esp)
8010328b:	80 
8010328c:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80103293:	e8 91 16 00 00       	call   80104929 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
80103298:	a1 bc f8 10 80       	mov    0x8010f8bc,%eax
8010329d:	85 c0                	test   %eax,%eax
8010329f:	75 e3                	jne    80103284 <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
801032a1:	c7 05 bc f8 10 80 01 	movl   $0x1,0x8010f8bc
801032a8:	00 00 00 
  release(&log.lock);
801032ab:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801032b2:	e8 b2 19 00 00       	call   80104c69 <release>
}
801032b7:	c9                   	leave  
801032b8:	c3                   	ret    

801032b9 <commit_trans>:

void
commit_trans(void)
{
801032b9:	55                   	push   %ebp
801032ba:	89 e5                	mov    %esp,%ebp
801032bc:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
801032bf:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
801032c4:	85 c0                	test   %eax,%eax
801032c6:	7e 19                	jle    801032e1 <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
801032c8:	e8 07 ff ff ff       	call   801031d4 <write_head>
    install_trans(); // Now install writes to home locations
801032cd:	e8 e5 fd ff ff       	call   801030b7 <install_trans>
    log.lh.n = 0; 
801032d2:	c7 05 c4 f8 10 80 00 	movl   $0x0,0x8010f8c4
801032d9:	00 00 00 
    write_head();    // Erase the transaction from the log
801032dc:	e8 f3 fe ff ff       	call   801031d4 <write_head>
  }
  
  acquire(&log.lock);
801032e1:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801032e8:	e8 1a 19 00 00       	call   80104c07 <acquire>
  log.busy = 0;
801032ed:	c7 05 bc f8 10 80 00 	movl   $0x0,0x8010f8bc
801032f4:	00 00 00 
  wakeup(&log);
801032f7:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801032fe:	e8 ff 16 00 00       	call   80104a02 <wakeup>
  release(&log.lock);
80103303:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010330a:	e8 5a 19 00 00       	call   80104c69 <release>
}
8010330f:	c9                   	leave  
80103310:	c3                   	ret    

80103311 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103311:	55                   	push   %ebp
80103312:	89 e5                	mov    %esp,%ebp
80103314:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103317:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
8010331c:	83 f8 09             	cmp    $0x9,%eax
8010331f:	7f 12                	jg     80103333 <log_write+0x22>
80103321:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
80103326:	8b 15 b8 f8 10 80    	mov    0x8010f8b8,%edx
8010332c:	83 ea 01             	sub    $0x1,%edx
8010332f:	39 d0                	cmp    %edx,%eax
80103331:	7c 0c                	jl     8010333f <log_write+0x2e>
    panic("too big a transaction");
80103333:	c7 04 24 30 84 10 80 	movl   $0x80108430,(%esp)
8010333a:	e8 07 d2 ff ff       	call   80100546 <panic>
  if (!log.busy)
8010333f:	a1 bc f8 10 80       	mov    0x8010f8bc,%eax
80103344:	85 c0                	test   %eax,%eax
80103346:	75 0c                	jne    80103354 <log_write+0x43>
    panic("write outside of trans");
80103348:	c7 04 24 46 84 10 80 	movl   $0x80108446,(%esp)
8010334f:	e8 f2 d1 ff ff       	call   80100546 <panic>

  for (i = 0; i < log.lh.n; i++) {
80103354:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010335b:	eb 1d                	jmp    8010337a <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
8010335d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103360:	83 c0 10             	add    $0x10,%eax
80103363:	8b 04 85 88 f8 10 80 	mov    -0x7fef0778(,%eax,4),%eax
8010336a:	89 c2                	mov    %eax,%edx
8010336c:	8b 45 08             	mov    0x8(%ebp),%eax
8010336f:	8b 40 08             	mov    0x8(%eax),%eax
80103372:	39 c2                	cmp    %eax,%edx
80103374:	74 10                	je     80103386 <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
80103376:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010337a:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
8010337f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103382:	7f d9                	jg     8010335d <log_write+0x4c>
80103384:	eb 01                	jmp    80103387 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
80103386:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
80103387:	8b 45 08             	mov    0x8(%ebp),%eax
8010338a:	8b 40 08             	mov    0x8(%eax),%eax
8010338d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103390:	83 c2 10             	add    $0x10,%edx
80103393:	89 04 95 88 f8 10 80 	mov    %eax,-0x7fef0778(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
8010339a:	8b 15 b4 f8 10 80    	mov    0x8010f8b4,%edx
801033a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033a3:	01 d0                	add    %edx,%eax
801033a5:	83 c0 01             	add    $0x1,%eax
801033a8:	89 c2                	mov    %eax,%edx
801033aa:	8b 45 08             	mov    0x8(%ebp),%eax
801033ad:	8b 40 04             	mov    0x4(%eax),%eax
801033b0:	89 54 24 04          	mov    %edx,0x4(%esp)
801033b4:	89 04 24             	mov    %eax,(%esp)
801033b7:	e8 ea cd ff ff       	call   801001a6 <bread>
801033bc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
801033bf:	8b 45 08             	mov    0x8(%ebp),%eax
801033c2:	8d 50 18             	lea    0x18(%eax),%edx
801033c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033c8:	83 c0 18             	add    $0x18,%eax
801033cb:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801033d2:	00 
801033d3:	89 54 24 04          	mov    %edx,0x4(%esp)
801033d7:	89 04 24             	mov    %eax,(%esp)
801033da:	e8 56 1b 00 00       	call   80104f35 <memmove>
  bwrite(lbuf);
801033df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033e2:	89 04 24             	mov    %eax,(%esp)
801033e5:	e8 f3 cd ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
801033ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033ed:	89 04 24             	mov    %eax,(%esp)
801033f0:	e8 22 ce ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
801033f5:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
801033fa:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801033fd:	75 0d                	jne    8010340c <log_write+0xfb>
    log.lh.n++;
801033ff:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
80103404:	83 c0 01             	add    $0x1,%eax
80103407:	a3 c4 f8 10 80       	mov    %eax,0x8010f8c4
  b->flags |= B_DIRTY; // XXX prevent eviction
8010340c:	8b 45 08             	mov    0x8(%ebp),%eax
8010340f:	8b 00                	mov    (%eax),%eax
80103411:	89 c2                	mov    %eax,%edx
80103413:	83 ca 04             	or     $0x4,%edx
80103416:	8b 45 08             	mov    0x8(%ebp),%eax
80103419:	89 10                	mov    %edx,(%eax)
}
8010341b:	c9                   	leave  
8010341c:	c3                   	ret    
8010341d:	66 90                	xchg   %ax,%ax
8010341f:	90                   	nop

80103420 <v2p>:
80103420:	55                   	push   %ebp
80103421:	89 e5                	mov    %esp,%ebp
80103423:	8b 45 08             	mov    0x8(%ebp),%eax
80103426:	05 00 00 00 80       	add    $0x80000000,%eax
8010342b:	5d                   	pop    %ebp
8010342c:	c3                   	ret    

8010342d <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
8010342d:	55                   	push   %ebp
8010342e:	89 e5                	mov    %esp,%ebp
80103430:	8b 45 08             	mov    0x8(%ebp),%eax
80103433:	05 00 00 00 80       	add    $0x80000000,%eax
80103438:	5d                   	pop    %ebp
80103439:	c3                   	ret    

8010343a <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
8010343a:	55                   	push   %ebp
8010343b:	89 e5                	mov    %esp,%ebp
8010343d:	53                   	push   %ebx
8010343e:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80103441:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103444:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80103447:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010344a:	89 c3                	mov    %eax,%ebx
8010344c:	89 d8                	mov    %ebx,%eax
8010344e:	f0 87 02             	lock xchg %eax,(%edx)
80103451:	89 c3                	mov    %eax,%ebx
80103453:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103456:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103459:	83 c4 10             	add    $0x10,%esp
8010345c:	5b                   	pop    %ebx
8010345d:	5d                   	pop    %ebp
8010345e:	c3                   	ret    

8010345f <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
8010345f:	55                   	push   %ebp
80103460:	89 e5                	mov    %esp,%ebp
80103462:	83 e4 f0             	and    $0xfffffff0,%esp
80103465:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103468:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
8010346f:	80 
80103470:	c7 04 24 fc 26 11 80 	movl   $0x801126fc,(%esp)
80103477:	e8 a1 f5 ff ff       	call   80102a1d <kinit1>
  kvmalloc();      // kernel page table
8010347c:	e8 ff 45 00 00       	call   80107a80 <kvmalloc>
  mpinit();        // collect info about this machine
80103481:	e8 67 04 00 00       	call   801038ed <mpinit>
  lapicinit(mpbcpu());
80103486:	e8 2e 02 00 00       	call   801036b9 <mpbcpu>
8010348b:	89 04 24             	mov    %eax,(%esp)
8010348e:	e8 ed f8 ff ff       	call   80102d80 <lapicinit>
  seginit();       // set up segments
80103493:	e8 7d 3f 00 00       	call   80107415 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103498:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010349e:	0f b6 00             	movzbl (%eax),%eax
801034a1:	0f b6 c0             	movzbl %al,%eax
801034a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801034a8:	c7 04 24 5d 84 10 80 	movl   $0x8010845d,(%esp)
801034af:	e8 f6 ce ff ff       	call   801003aa <cprintf>
  picinit();       // interrupt controller
801034b4:	e8 99 06 00 00       	call   80103b52 <picinit>
  ioapicinit();    // another interrupt controller
801034b9:	e8 4f f4 ff ff       	call   8010290d <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
801034be:	e8 d5 d5 ff ff       	call   80100a98 <consoleinit>
  uartinit();      // serial port
801034c3:	e8 98 32 00 00       	call   80106760 <uartinit>
  pinit();         // process table
801034c8:	e8 9e 0b 00 00       	call   8010406b <pinit>
  tvinit();        // trap vectors
801034cd:	e8 31 2e 00 00       	call   80106303 <tvinit>
  binit();         // buffer cache
801034d2:	e8 5d cb ff ff       	call   80100034 <binit>
  fileinit();      // file table
801034d7:	e8 4c da ff ff       	call   80100f28 <fileinit>
  iinit();         // inode cache
801034dc:	e8 fc e0 ff ff       	call   801015dd <iinit>
  ideinit();       // disk
801034e1:	e8 8c f0 ff ff       	call   80102572 <ideinit>
  if(!ismp)
801034e6:	a1 04 f9 10 80       	mov    0x8010f904,%eax
801034eb:	85 c0                	test   %eax,%eax
801034ed:	75 05                	jne    801034f4 <main+0x95>
    timerinit();   // uniprocessor timer
801034ef:	e8 52 2d 00 00       	call   80106246 <timerinit>
  startothers();   // start other processors
801034f4:	e8 87 00 00 00       	call   80103580 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801034f9:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103500:	8e 
80103501:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103508:	e8 48 f5 ff ff       	call   80102a55 <kinit2>
  userinit();      // first user process
8010350d:	e8 74 0c 00 00       	call   80104186 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103512:	e8 22 00 00 00       	call   80103539 <mpmain>

80103517 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103517:	55                   	push   %ebp
80103518:	89 e5                	mov    %esp,%ebp
8010351a:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
8010351d:	e8 75 45 00 00       	call   80107a97 <switchkvm>
  seginit();
80103522:	e8 ee 3e 00 00       	call   80107415 <seginit>
  lapicinit(cpunum());
80103527:	e8 b1 f9 ff ff       	call   80102edd <cpunum>
8010352c:	89 04 24             	mov    %eax,(%esp)
8010352f:	e8 4c f8 ff ff       	call   80102d80 <lapicinit>
  mpmain();
80103534:	e8 00 00 00 00       	call   80103539 <mpmain>

80103539 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103539:	55                   	push   %ebp
8010353a:	89 e5                	mov    %esp,%ebp
8010353c:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
8010353f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103545:	0f b6 00             	movzbl (%eax),%eax
80103548:	0f b6 c0             	movzbl %al,%eax
8010354b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010354f:	c7 04 24 74 84 10 80 	movl   $0x80108474,(%esp)
80103556:	e8 4f ce ff ff       	call   801003aa <cprintf>
  idtinit();       // load idt register
8010355b:	e8 17 2f 00 00       	call   80106477 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103560:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103566:	05 a8 00 00 00       	add    $0xa8,%eax
8010356b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103572:	00 
80103573:	89 04 24             	mov    %eax,(%esp)
80103576:	e8 bf fe ff ff       	call   8010343a <xchg>
  scheduler();     // start running processes
8010357b:	e8 00 12 00 00       	call   80104780 <scheduler>

80103580 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103580:	55                   	push   %ebp
80103581:	89 e5                	mov    %esp,%ebp
80103583:	53                   	push   %ebx
80103584:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103587:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
8010358e:	e8 9a fe ff ff       	call   8010342d <p2v>
80103593:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103596:	b8 8a 00 00 00       	mov    $0x8a,%eax
8010359b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010359f:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
801035a6:	80 
801035a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035aa:	89 04 24             	mov    %eax,(%esp)
801035ad:	e8 83 19 00 00       	call   80104f35 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
801035b2:	c7 45 f4 20 f9 10 80 	movl   $0x8010f920,-0xc(%ebp)
801035b9:	e9 86 00 00 00       	jmp    80103644 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
801035be:	e8 1a f9 ff ff       	call   80102edd <cpunum>
801035c3:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801035c9:	05 20 f9 10 80       	add    $0x8010f920,%eax
801035ce:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801035d1:	74 69                	je     8010363c <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
801035d3:	e8 73 f5 ff ff       	call   80102b4b <kalloc>
801035d8:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
801035db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035de:	83 e8 04             	sub    $0x4,%eax
801035e1:	8b 55 ec             	mov    -0x14(%ebp),%edx
801035e4:	81 c2 00 10 00 00    	add    $0x1000,%edx
801035ea:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
801035ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035ef:	83 e8 08             	sub    $0x8,%eax
801035f2:	c7 00 17 35 10 80    	movl   $0x80103517,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
801035f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035fb:	8d 58 f4             	lea    -0xc(%eax),%ebx
801035fe:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
80103605:	e8 16 fe ff ff       	call   80103420 <v2p>
8010360a:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
8010360c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010360f:	89 04 24             	mov    %eax,(%esp)
80103612:	e8 09 fe ff ff       	call   80103420 <v2p>
80103617:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010361a:	0f b6 12             	movzbl (%edx),%edx
8010361d:	0f b6 d2             	movzbl %dl,%edx
80103620:	89 44 24 04          	mov    %eax,0x4(%esp)
80103624:	89 14 24             	mov    %edx,(%esp)
80103627:	e8 37 f9 ff ff       	call   80102f63 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
8010362c:	90                   	nop
8010362d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103630:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103636:	85 c0                	test   %eax,%eax
80103638:	74 f3                	je     8010362d <startothers+0xad>
8010363a:	eb 01                	jmp    8010363d <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
8010363c:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
8010363d:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103644:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
80103649:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010364f:	05 20 f9 10 80       	add    $0x8010f920,%eax
80103654:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103657:	0f 87 61 ff ff ff    	ja     801035be <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
8010365d:	83 c4 24             	add    $0x24,%esp
80103660:	5b                   	pop    %ebx
80103661:	5d                   	pop    %ebp
80103662:	c3                   	ret    
80103663:	90                   	nop

80103664 <p2v>:
80103664:	55                   	push   %ebp
80103665:	89 e5                	mov    %esp,%ebp
80103667:	8b 45 08             	mov    0x8(%ebp),%eax
8010366a:	05 00 00 00 80       	add    $0x80000000,%eax
8010366f:	5d                   	pop    %ebp
80103670:	c3                   	ret    

80103671 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103671:	55                   	push   %ebp
80103672:	89 e5                	mov    %esp,%ebp
80103674:	53                   	push   %ebx
80103675:	83 ec 14             	sub    $0x14,%esp
80103678:	8b 45 08             	mov    0x8(%ebp),%eax
8010367b:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010367f:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103683:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103687:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010368b:	ec                   	in     (%dx),%al
8010368c:	89 c3                	mov    %eax,%ebx
8010368e:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103691:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103695:	83 c4 14             	add    $0x14,%esp
80103698:	5b                   	pop    %ebx
80103699:	5d                   	pop    %ebp
8010369a:	c3                   	ret    

8010369b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010369b:	55                   	push   %ebp
8010369c:	89 e5                	mov    %esp,%ebp
8010369e:	83 ec 08             	sub    $0x8,%esp
801036a1:	8b 55 08             	mov    0x8(%ebp),%edx
801036a4:	8b 45 0c             	mov    0xc(%ebp),%eax
801036a7:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801036ab:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801036ae:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801036b2:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801036b6:	ee                   	out    %al,(%dx)
}
801036b7:	c9                   	leave  
801036b8:	c3                   	ret    

801036b9 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
801036b9:	55                   	push   %ebp
801036ba:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
801036bc:	a1 44 b6 10 80       	mov    0x8010b644,%eax
801036c1:	89 c2                	mov    %eax,%edx
801036c3:	b8 20 f9 10 80       	mov    $0x8010f920,%eax
801036c8:	89 d1                	mov    %edx,%ecx
801036ca:	29 c1                	sub    %eax,%ecx
801036cc:	89 c8                	mov    %ecx,%eax
801036ce:	c1 f8 02             	sar    $0x2,%eax
801036d1:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
801036d7:	5d                   	pop    %ebp
801036d8:	c3                   	ret    

801036d9 <sum>:

static uchar
sum(uchar *addr, int len)
{
801036d9:	55                   	push   %ebp
801036da:	89 e5                	mov    %esp,%ebp
801036dc:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
801036df:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
801036e6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801036ed:	eb 15                	jmp    80103704 <sum+0x2b>
    sum += addr[i];
801036ef:	8b 55 fc             	mov    -0x4(%ebp),%edx
801036f2:	8b 45 08             	mov    0x8(%ebp),%eax
801036f5:	01 d0                	add    %edx,%eax
801036f7:	0f b6 00             	movzbl (%eax),%eax
801036fa:	0f b6 c0             	movzbl %al,%eax
801036fd:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80103700:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103704:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103707:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010370a:	7c e3                	jl     801036ef <sum+0x16>
    sum += addr[i];
  return sum;
8010370c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010370f:	c9                   	leave  
80103710:	c3                   	ret    

80103711 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103711:	55                   	push   %ebp
80103712:	89 e5                	mov    %esp,%ebp
80103714:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103717:	8b 45 08             	mov    0x8(%ebp),%eax
8010371a:	89 04 24             	mov    %eax,(%esp)
8010371d:	e8 42 ff ff ff       	call   80103664 <p2v>
80103722:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103725:	8b 55 0c             	mov    0xc(%ebp),%edx
80103728:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010372b:	01 d0                	add    %edx,%eax
8010372d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103730:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103733:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103736:	eb 3f                	jmp    80103777 <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103738:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010373f:	00 
80103740:	c7 44 24 04 88 84 10 	movl   $0x80108488,0x4(%esp)
80103747:	80 
80103748:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010374b:	89 04 24             	mov    %eax,(%esp)
8010374e:	e8 86 17 00 00       	call   80104ed9 <memcmp>
80103753:	85 c0                	test   %eax,%eax
80103755:	75 1c                	jne    80103773 <mpsearch1+0x62>
80103757:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010375e:	00 
8010375f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103762:	89 04 24             	mov    %eax,(%esp)
80103765:	e8 6f ff ff ff       	call   801036d9 <sum>
8010376a:	84 c0                	test   %al,%al
8010376c:	75 05                	jne    80103773 <mpsearch1+0x62>
      return (struct mp*)p;
8010376e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103771:	eb 11                	jmp    80103784 <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103773:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103777:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010377a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010377d:	72 b9                	jb     80103738 <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
8010377f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103784:	c9                   	leave  
80103785:	c3                   	ret    

80103786 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103786:	55                   	push   %ebp
80103787:	89 e5                	mov    %esp,%ebp
80103789:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
8010378c:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103793:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103796:	83 c0 0f             	add    $0xf,%eax
80103799:	0f b6 00             	movzbl (%eax),%eax
8010379c:	0f b6 c0             	movzbl %al,%eax
8010379f:	89 c2                	mov    %eax,%edx
801037a1:	c1 e2 08             	shl    $0x8,%edx
801037a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037a7:	83 c0 0e             	add    $0xe,%eax
801037aa:	0f b6 00             	movzbl (%eax),%eax
801037ad:	0f b6 c0             	movzbl %al,%eax
801037b0:	09 d0                	or     %edx,%eax
801037b2:	c1 e0 04             	shl    $0x4,%eax
801037b5:	89 45 f0             	mov    %eax,-0x10(%ebp)
801037b8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801037bc:	74 21                	je     801037df <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
801037be:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801037c5:	00 
801037c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037c9:	89 04 24             	mov    %eax,(%esp)
801037cc:	e8 40 ff ff ff       	call   80103711 <mpsearch1>
801037d1:	89 45 ec             	mov    %eax,-0x14(%ebp)
801037d4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801037d8:	74 50                	je     8010382a <mpsearch+0xa4>
      return mp;
801037da:	8b 45 ec             	mov    -0x14(%ebp),%eax
801037dd:	eb 5f                	jmp    8010383e <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
801037df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037e2:	83 c0 14             	add    $0x14,%eax
801037e5:	0f b6 00             	movzbl (%eax),%eax
801037e8:	0f b6 c0             	movzbl %al,%eax
801037eb:	89 c2                	mov    %eax,%edx
801037ed:	c1 e2 08             	shl    $0x8,%edx
801037f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037f3:	83 c0 13             	add    $0x13,%eax
801037f6:	0f b6 00             	movzbl (%eax),%eax
801037f9:	0f b6 c0             	movzbl %al,%eax
801037fc:	09 d0                	or     %edx,%eax
801037fe:	c1 e0 0a             	shl    $0xa,%eax
80103801:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103804:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103807:	2d 00 04 00 00       	sub    $0x400,%eax
8010380c:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103813:	00 
80103814:	89 04 24             	mov    %eax,(%esp)
80103817:	e8 f5 fe ff ff       	call   80103711 <mpsearch1>
8010381c:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010381f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103823:	74 05                	je     8010382a <mpsearch+0xa4>
      return mp;
80103825:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103828:	eb 14                	jmp    8010383e <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
8010382a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103831:	00 
80103832:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103839:	e8 d3 fe ff ff       	call   80103711 <mpsearch1>
}
8010383e:	c9                   	leave  
8010383f:	c3                   	ret    

80103840 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103840:	55                   	push   %ebp
80103841:	89 e5                	mov    %esp,%ebp
80103843:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103846:	e8 3b ff ff ff       	call   80103786 <mpsearch>
8010384b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010384e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103852:	74 0a                	je     8010385e <mpconfig+0x1e>
80103854:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103857:	8b 40 04             	mov    0x4(%eax),%eax
8010385a:	85 c0                	test   %eax,%eax
8010385c:	75 0a                	jne    80103868 <mpconfig+0x28>
    return 0;
8010385e:	b8 00 00 00 00       	mov    $0x0,%eax
80103863:	e9 83 00 00 00       	jmp    801038eb <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103868:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010386b:	8b 40 04             	mov    0x4(%eax),%eax
8010386e:	89 04 24             	mov    %eax,(%esp)
80103871:	e8 ee fd ff ff       	call   80103664 <p2v>
80103876:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103879:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103880:	00 
80103881:	c7 44 24 04 8d 84 10 	movl   $0x8010848d,0x4(%esp)
80103888:	80 
80103889:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010388c:	89 04 24             	mov    %eax,(%esp)
8010388f:	e8 45 16 00 00       	call   80104ed9 <memcmp>
80103894:	85 c0                	test   %eax,%eax
80103896:	74 07                	je     8010389f <mpconfig+0x5f>
    return 0;
80103898:	b8 00 00 00 00       	mov    $0x0,%eax
8010389d:	eb 4c                	jmp    801038eb <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
8010389f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038a2:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801038a6:	3c 01                	cmp    $0x1,%al
801038a8:	74 12                	je     801038bc <mpconfig+0x7c>
801038aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038ad:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801038b1:	3c 04                	cmp    $0x4,%al
801038b3:	74 07                	je     801038bc <mpconfig+0x7c>
    return 0;
801038b5:	b8 00 00 00 00       	mov    $0x0,%eax
801038ba:	eb 2f                	jmp    801038eb <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
801038bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038bf:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801038c3:	0f b7 c0             	movzwl %ax,%eax
801038c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801038ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038cd:	89 04 24             	mov    %eax,(%esp)
801038d0:	e8 04 fe ff ff       	call   801036d9 <sum>
801038d5:	84 c0                	test   %al,%al
801038d7:	74 07                	je     801038e0 <mpconfig+0xa0>
    return 0;
801038d9:	b8 00 00 00 00       	mov    $0x0,%eax
801038de:	eb 0b                	jmp    801038eb <mpconfig+0xab>
  *pmp = mp;
801038e0:	8b 45 08             	mov    0x8(%ebp),%eax
801038e3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801038e6:	89 10                	mov    %edx,(%eax)
  return conf;
801038e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801038eb:	c9                   	leave  
801038ec:	c3                   	ret    

801038ed <mpinit>:

void
mpinit(void)
{
801038ed:	55                   	push   %ebp
801038ee:	89 e5                	mov    %esp,%ebp
801038f0:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
801038f3:	c7 05 44 b6 10 80 20 	movl   $0x8010f920,0x8010b644
801038fa:	f9 10 80 
  if((conf = mpconfig(&mp)) == 0)
801038fd:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103900:	89 04 24             	mov    %eax,(%esp)
80103903:	e8 38 ff ff ff       	call   80103840 <mpconfig>
80103908:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010390b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010390f:	0f 84 9c 01 00 00    	je     80103ab1 <mpinit+0x1c4>
    return;
  ismp = 1;
80103915:	c7 05 04 f9 10 80 01 	movl   $0x1,0x8010f904
8010391c:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
8010391f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103922:	8b 40 24             	mov    0x24(%eax),%eax
80103925:	a3 7c f8 10 80       	mov    %eax,0x8010f87c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010392a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010392d:	83 c0 2c             	add    $0x2c,%eax
80103930:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103933:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103936:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010393a:	0f b7 d0             	movzwl %ax,%edx
8010393d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103940:	01 d0                	add    %edx,%eax
80103942:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103945:	e9 f4 00 00 00       	jmp    80103a3e <mpinit+0x151>
    switch(*p){
8010394a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010394d:	0f b6 00             	movzbl (%eax),%eax
80103950:	0f b6 c0             	movzbl %al,%eax
80103953:	83 f8 04             	cmp    $0x4,%eax
80103956:	0f 87 bf 00 00 00    	ja     80103a1b <mpinit+0x12e>
8010395c:	8b 04 85 d0 84 10 80 	mov    -0x7fef7b30(,%eax,4),%eax
80103963:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103965:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103968:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
8010396b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010396e:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103972:	0f b6 d0             	movzbl %al,%edx
80103975:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
8010397a:	39 c2                	cmp    %eax,%edx
8010397c:	74 2d                	je     801039ab <mpinit+0xbe>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
8010397e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103981:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103985:	0f b6 d0             	movzbl %al,%edx
80103988:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
8010398d:	89 54 24 08          	mov    %edx,0x8(%esp)
80103991:	89 44 24 04          	mov    %eax,0x4(%esp)
80103995:	c7 04 24 92 84 10 80 	movl   $0x80108492,(%esp)
8010399c:	e8 09 ca ff ff       	call   801003aa <cprintf>
        ismp = 0;
801039a1:	c7 05 04 f9 10 80 00 	movl   $0x0,0x8010f904
801039a8:	00 00 00 
      }
      if(proc->flags & MPBOOT)
801039ab:	8b 45 e8             	mov    -0x18(%ebp),%eax
801039ae:	0f b6 40 03          	movzbl 0x3(%eax),%eax
801039b2:	0f b6 c0             	movzbl %al,%eax
801039b5:	83 e0 02             	and    $0x2,%eax
801039b8:	85 c0                	test   %eax,%eax
801039ba:	74 15                	je     801039d1 <mpinit+0xe4>
        bcpu = &cpus[ncpu];
801039bc:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
801039c1:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801039c7:	05 20 f9 10 80       	add    $0x8010f920,%eax
801039cc:	a3 44 b6 10 80       	mov    %eax,0x8010b644
      cpus[ncpu].id = ncpu;
801039d1:	8b 15 00 ff 10 80    	mov    0x8010ff00,%edx
801039d7:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
801039dc:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
801039e2:	81 c2 20 f9 10 80    	add    $0x8010f920,%edx
801039e8:	88 02                	mov    %al,(%edx)
      ncpu++;
801039ea:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
801039ef:	83 c0 01             	add    $0x1,%eax
801039f2:	a3 00 ff 10 80       	mov    %eax,0x8010ff00
      p += sizeof(struct mpproc);
801039f7:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
801039fb:	eb 41                	jmp    80103a3e <mpinit+0x151>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
801039fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a00:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103a03:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103a06:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103a0a:	a2 00 f9 10 80       	mov    %al,0x8010f900
      p += sizeof(struct mpioapic);
80103a0f:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103a13:	eb 29                	jmp    80103a3e <mpinit+0x151>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103a15:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103a19:	eb 23                	jmp    80103a3e <mpinit+0x151>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103a1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a1e:	0f b6 00             	movzbl (%eax),%eax
80103a21:	0f b6 c0             	movzbl %al,%eax
80103a24:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a28:	c7 04 24 b0 84 10 80 	movl   $0x801084b0,(%esp)
80103a2f:	e8 76 c9 ff ff       	call   801003aa <cprintf>
      ismp = 0;
80103a34:	c7 05 04 f9 10 80 00 	movl   $0x0,0x8010f904
80103a3b:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103a3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a41:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103a44:	0f 82 00 ff ff ff    	jb     8010394a <mpinit+0x5d>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103a4a:	a1 04 f9 10 80       	mov    0x8010f904,%eax
80103a4f:	85 c0                	test   %eax,%eax
80103a51:	75 1d                	jne    80103a70 <mpinit+0x183>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103a53:	c7 05 00 ff 10 80 01 	movl   $0x1,0x8010ff00
80103a5a:	00 00 00 
    lapic = 0;
80103a5d:	c7 05 7c f8 10 80 00 	movl   $0x0,0x8010f87c
80103a64:	00 00 00 
    ioapicid = 0;
80103a67:	c6 05 00 f9 10 80 00 	movb   $0x0,0x8010f900
80103a6e:	eb 41                	jmp    80103ab1 <mpinit+0x1c4>
    return;
  }

  if(mp->imcrp){
80103a70:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103a73:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103a77:	84 c0                	test   %al,%al
80103a79:	74 36                	je     80103ab1 <mpinit+0x1c4>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103a7b:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103a82:	00 
80103a83:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103a8a:	e8 0c fc ff ff       	call   8010369b <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103a8f:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103a96:	e8 d6 fb ff ff       	call   80103671 <inb>
80103a9b:	83 c8 01             	or     $0x1,%eax
80103a9e:	0f b6 c0             	movzbl %al,%eax
80103aa1:	89 44 24 04          	mov    %eax,0x4(%esp)
80103aa5:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103aac:	e8 ea fb ff ff       	call   8010369b <outb>
  }
}
80103ab1:	c9                   	leave  
80103ab2:	c3                   	ret    
80103ab3:	90                   	nop

80103ab4 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103ab4:	55                   	push   %ebp
80103ab5:	89 e5                	mov    %esp,%ebp
80103ab7:	83 ec 08             	sub    $0x8,%esp
80103aba:	8b 55 08             	mov    0x8(%ebp),%edx
80103abd:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ac0:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103ac4:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103ac7:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103acb:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103acf:	ee                   	out    %al,(%dx)
}
80103ad0:	c9                   	leave  
80103ad1:	c3                   	ret    

80103ad2 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103ad2:	55                   	push   %ebp
80103ad3:	89 e5                	mov    %esp,%ebp
80103ad5:	83 ec 0c             	sub    $0xc,%esp
80103ad8:	8b 45 08             	mov    0x8(%ebp),%eax
80103adb:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103adf:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103ae3:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80103ae9:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103aed:	0f b6 c0             	movzbl %al,%eax
80103af0:	89 44 24 04          	mov    %eax,0x4(%esp)
80103af4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103afb:	e8 b4 ff ff ff       	call   80103ab4 <outb>
  outb(IO_PIC2+1, mask >> 8);
80103b00:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103b04:	66 c1 e8 08          	shr    $0x8,%ax
80103b08:	0f b6 c0             	movzbl %al,%eax
80103b0b:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b0f:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103b16:	e8 99 ff ff ff       	call   80103ab4 <outb>
}
80103b1b:	c9                   	leave  
80103b1c:	c3                   	ret    

80103b1d <picenable>:

void
picenable(int irq)
{
80103b1d:	55                   	push   %ebp
80103b1e:	89 e5                	mov    %esp,%ebp
80103b20:	53                   	push   %ebx
80103b21:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103b24:	8b 45 08             	mov    0x8(%ebp),%eax
80103b27:	ba 01 00 00 00       	mov    $0x1,%edx
80103b2c:	89 d3                	mov    %edx,%ebx
80103b2e:	89 c1                	mov    %eax,%ecx
80103b30:	d3 e3                	shl    %cl,%ebx
80103b32:	89 d8                	mov    %ebx,%eax
80103b34:	89 c2                	mov    %eax,%edx
80103b36:	f7 d2                	not    %edx
80103b38:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103b3f:	21 d0                	and    %edx,%eax
80103b41:	0f b7 c0             	movzwl %ax,%eax
80103b44:	89 04 24             	mov    %eax,(%esp)
80103b47:	e8 86 ff ff ff       	call   80103ad2 <picsetmask>
}
80103b4c:	83 c4 04             	add    $0x4,%esp
80103b4f:	5b                   	pop    %ebx
80103b50:	5d                   	pop    %ebp
80103b51:	c3                   	ret    

80103b52 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103b52:	55                   	push   %ebp
80103b53:	89 e5                	mov    %esp,%ebp
80103b55:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103b58:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103b5f:	00 
80103b60:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103b67:	e8 48 ff ff ff       	call   80103ab4 <outb>
  outb(IO_PIC2+1, 0xFF);
80103b6c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103b73:	00 
80103b74:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103b7b:	e8 34 ff ff ff       	call   80103ab4 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103b80:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103b87:	00 
80103b88:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103b8f:	e8 20 ff ff ff       	call   80103ab4 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103b94:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103b9b:	00 
80103b9c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103ba3:	e8 0c ff ff ff       	call   80103ab4 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103ba8:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103baf:	00 
80103bb0:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103bb7:	e8 f8 fe ff ff       	call   80103ab4 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103bbc:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103bc3:	00 
80103bc4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103bcb:	e8 e4 fe ff ff       	call   80103ab4 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103bd0:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103bd7:	00 
80103bd8:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103bdf:	e8 d0 fe ff ff       	call   80103ab4 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103be4:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103beb:	00 
80103bec:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103bf3:	e8 bc fe ff ff       	call   80103ab4 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103bf8:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103bff:	00 
80103c00:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103c07:	e8 a8 fe ff ff       	call   80103ab4 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103c0c:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103c13:	00 
80103c14:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103c1b:	e8 94 fe ff ff       	call   80103ab4 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103c20:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103c27:	00 
80103c28:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103c2f:	e8 80 fe ff ff       	call   80103ab4 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80103c34:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103c3b:	00 
80103c3c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103c43:	e8 6c fe ff ff       	call   80103ab4 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80103c48:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103c4f:	00 
80103c50:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103c57:	e8 58 fe ff ff       	call   80103ab4 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80103c5c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103c63:	00 
80103c64:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103c6b:	e8 44 fe ff ff       	call   80103ab4 <outb>

  if(irqmask != 0xFFFF)
80103c70:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103c77:	66 83 f8 ff          	cmp    $0xffff,%ax
80103c7b:	74 12                	je     80103c8f <picinit+0x13d>
    picsetmask(irqmask);
80103c7d:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103c84:	0f b7 c0             	movzwl %ax,%eax
80103c87:	89 04 24             	mov    %eax,(%esp)
80103c8a:	e8 43 fe ff ff       	call   80103ad2 <picsetmask>
}
80103c8f:	c9                   	leave  
80103c90:	c3                   	ret    
80103c91:	66 90                	xchg   %ax,%ax
80103c93:	90                   	nop

80103c94 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103c94:	55                   	push   %ebp
80103c95:	89 e5                	mov    %esp,%ebp
80103c97:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80103c9a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103ca1:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ca4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103caa:	8b 45 0c             	mov    0xc(%ebp),%eax
80103cad:	8b 10                	mov    (%eax),%edx
80103caf:	8b 45 08             	mov    0x8(%ebp),%eax
80103cb2:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103cb4:	e8 8b d2 ff ff       	call   80100f44 <filealloc>
80103cb9:	8b 55 08             	mov    0x8(%ebp),%edx
80103cbc:	89 02                	mov    %eax,(%edx)
80103cbe:	8b 45 08             	mov    0x8(%ebp),%eax
80103cc1:	8b 00                	mov    (%eax),%eax
80103cc3:	85 c0                	test   %eax,%eax
80103cc5:	0f 84 c8 00 00 00    	je     80103d93 <pipealloc+0xff>
80103ccb:	e8 74 d2 ff ff       	call   80100f44 <filealloc>
80103cd0:	8b 55 0c             	mov    0xc(%ebp),%edx
80103cd3:	89 02                	mov    %eax,(%edx)
80103cd5:	8b 45 0c             	mov    0xc(%ebp),%eax
80103cd8:	8b 00                	mov    (%eax),%eax
80103cda:	85 c0                	test   %eax,%eax
80103cdc:	0f 84 b1 00 00 00    	je     80103d93 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103ce2:	e8 64 ee ff ff       	call   80102b4b <kalloc>
80103ce7:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103cea:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103cee:	0f 84 9e 00 00 00    	je     80103d92 <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80103cf4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cf7:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103cfe:	00 00 00 
  p->writeopen = 1;
80103d01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d04:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103d0b:	00 00 00 
  p->nwrite = 0;
80103d0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d11:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103d18:	00 00 00 
  p->nread = 0;
80103d1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d1e:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103d25:	00 00 00 
  initlock(&p->lock, "pipe");
80103d28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d2b:	c7 44 24 04 e4 84 10 	movl   $0x801084e4,0x4(%esp)
80103d32:	80 
80103d33:	89 04 24             	mov    %eax,(%esp)
80103d36:	e8 ab 0e 00 00       	call   80104be6 <initlock>
  (*f0)->type = FD_PIPE;
80103d3b:	8b 45 08             	mov    0x8(%ebp),%eax
80103d3e:	8b 00                	mov    (%eax),%eax
80103d40:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103d46:	8b 45 08             	mov    0x8(%ebp),%eax
80103d49:	8b 00                	mov    (%eax),%eax
80103d4b:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103d4f:	8b 45 08             	mov    0x8(%ebp),%eax
80103d52:	8b 00                	mov    (%eax),%eax
80103d54:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103d58:	8b 45 08             	mov    0x8(%ebp),%eax
80103d5b:	8b 00                	mov    (%eax),%eax
80103d5d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d60:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103d63:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d66:	8b 00                	mov    (%eax),%eax
80103d68:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103d6e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d71:	8b 00                	mov    (%eax),%eax
80103d73:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103d77:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d7a:	8b 00                	mov    (%eax),%eax
80103d7c:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103d80:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d83:	8b 00                	mov    (%eax),%eax
80103d85:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d88:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80103d8b:	b8 00 00 00 00       	mov    $0x0,%eax
80103d90:	eb 43                	jmp    80103dd5 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80103d92:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80103d93:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103d97:	74 0b                	je     80103da4 <pipealloc+0x110>
    kfree((char*)p);
80103d99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d9c:	89 04 24             	mov    %eax,(%esp)
80103d9f:	e8 0e ed ff ff       	call   80102ab2 <kfree>
  if(*f0)
80103da4:	8b 45 08             	mov    0x8(%ebp),%eax
80103da7:	8b 00                	mov    (%eax),%eax
80103da9:	85 c0                	test   %eax,%eax
80103dab:	74 0d                	je     80103dba <pipealloc+0x126>
    fileclose(*f0);
80103dad:	8b 45 08             	mov    0x8(%ebp),%eax
80103db0:	8b 00                	mov    (%eax),%eax
80103db2:	89 04 24             	mov    %eax,(%esp)
80103db5:	e8 32 d2 ff ff       	call   80100fec <fileclose>
  if(*f1)
80103dba:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dbd:	8b 00                	mov    (%eax),%eax
80103dbf:	85 c0                	test   %eax,%eax
80103dc1:	74 0d                	je     80103dd0 <pipealloc+0x13c>
    fileclose(*f1);
80103dc3:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dc6:	8b 00                	mov    (%eax),%eax
80103dc8:	89 04 24             	mov    %eax,(%esp)
80103dcb:	e8 1c d2 ff ff       	call   80100fec <fileclose>
  return -1;
80103dd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103dd5:	c9                   	leave  
80103dd6:	c3                   	ret    

80103dd7 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103dd7:	55                   	push   %ebp
80103dd8:	89 e5                	mov    %esp,%ebp
80103dda:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80103ddd:	8b 45 08             	mov    0x8(%ebp),%eax
80103de0:	89 04 24             	mov    %eax,(%esp)
80103de3:	e8 1f 0e 00 00       	call   80104c07 <acquire>
  if(writable){
80103de8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103dec:	74 1f                	je     80103e0d <pipeclose+0x36>
    p->writeopen = 0;
80103dee:	8b 45 08             	mov    0x8(%ebp),%eax
80103df1:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80103df8:	00 00 00 
    wakeup(&p->nread);
80103dfb:	8b 45 08             	mov    0x8(%ebp),%eax
80103dfe:	05 34 02 00 00       	add    $0x234,%eax
80103e03:	89 04 24             	mov    %eax,(%esp)
80103e06:	e8 f7 0b 00 00       	call   80104a02 <wakeup>
80103e0b:	eb 1d                	jmp    80103e2a <pipeclose+0x53>
  } else {
    p->readopen = 0;
80103e0d:	8b 45 08             	mov    0x8(%ebp),%eax
80103e10:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80103e17:	00 00 00 
    wakeup(&p->nwrite);
80103e1a:	8b 45 08             	mov    0x8(%ebp),%eax
80103e1d:	05 38 02 00 00       	add    $0x238,%eax
80103e22:	89 04 24             	mov    %eax,(%esp)
80103e25:	e8 d8 0b 00 00       	call   80104a02 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103e2a:	8b 45 08             	mov    0x8(%ebp),%eax
80103e2d:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103e33:	85 c0                	test   %eax,%eax
80103e35:	75 25                	jne    80103e5c <pipeclose+0x85>
80103e37:	8b 45 08             	mov    0x8(%ebp),%eax
80103e3a:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103e40:	85 c0                	test   %eax,%eax
80103e42:	75 18                	jne    80103e5c <pipeclose+0x85>
    release(&p->lock);
80103e44:	8b 45 08             	mov    0x8(%ebp),%eax
80103e47:	89 04 24             	mov    %eax,(%esp)
80103e4a:	e8 1a 0e 00 00       	call   80104c69 <release>
    kfree((char*)p);
80103e4f:	8b 45 08             	mov    0x8(%ebp),%eax
80103e52:	89 04 24             	mov    %eax,(%esp)
80103e55:	e8 58 ec ff ff       	call   80102ab2 <kfree>
80103e5a:	eb 0b                	jmp    80103e67 <pipeclose+0x90>
  } else
    release(&p->lock);
80103e5c:	8b 45 08             	mov    0x8(%ebp),%eax
80103e5f:	89 04 24             	mov    %eax,(%esp)
80103e62:	e8 02 0e 00 00       	call   80104c69 <release>
}
80103e67:	c9                   	leave  
80103e68:	c3                   	ret    

80103e69 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80103e69:	55                   	push   %ebp
80103e6a:	89 e5                	mov    %esp,%ebp
80103e6c:	53                   	push   %ebx
80103e6d:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80103e70:	8b 45 08             	mov    0x8(%ebp),%eax
80103e73:	89 04 24             	mov    %eax,(%esp)
80103e76:	e8 8c 0d 00 00       	call   80104c07 <acquire>
  for(i = 0; i < n; i++){
80103e7b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103e82:	e9 a8 00 00 00       	jmp    80103f2f <pipewrite+0xc6>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
80103e87:	8b 45 08             	mov    0x8(%ebp),%eax
80103e8a:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103e90:	85 c0                	test   %eax,%eax
80103e92:	74 0d                	je     80103ea1 <pipewrite+0x38>
80103e94:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103e9a:	8b 40 24             	mov    0x24(%eax),%eax
80103e9d:	85 c0                	test   %eax,%eax
80103e9f:	74 15                	je     80103eb6 <pipewrite+0x4d>
        release(&p->lock);
80103ea1:	8b 45 08             	mov    0x8(%ebp),%eax
80103ea4:	89 04 24             	mov    %eax,(%esp)
80103ea7:	e8 bd 0d 00 00       	call   80104c69 <release>
        return -1;
80103eac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103eb1:	e9 9f 00 00 00       	jmp    80103f55 <pipewrite+0xec>
      }
      wakeup(&p->nread);
80103eb6:	8b 45 08             	mov    0x8(%ebp),%eax
80103eb9:	05 34 02 00 00       	add    $0x234,%eax
80103ebe:	89 04 24             	mov    %eax,(%esp)
80103ec1:	e8 3c 0b 00 00       	call   80104a02 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103ec6:	8b 45 08             	mov    0x8(%ebp),%eax
80103ec9:	8b 55 08             	mov    0x8(%ebp),%edx
80103ecc:	81 c2 38 02 00 00    	add    $0x238,%edx
80103ed2:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ed6:	89 14 24             	mov    %edx,(%esp)
80103ed9:	e8 4b 0a 00 00       	call   80104929 <sleep>
80103ede:	eb 01                	jmp    80103ee1 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103ee0:	90                   	nop
80103ee1:	8b 45 08             	mov    0x8(%ebp),%eax
80103ee4:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80103eea:	8b 45 08             	mov    0x8(%ebp),%eax
80103eed:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80103ef3:	05 00 02 00 00       	add    $0x200,%eax
80103ef8:	39 c2                	cmp    %eax,%edx
80103efa:	74 8b                	je     80103e87 <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103efc:	8b 45 08             	mov    0x8(%ebp),%eax
80103eff:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103f05:	89 c3                	mov    %eax,%ebx
80103f07:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80103f0d:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80103f10:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f13:	01 ca                	add    %ecx,%edx
80103f15:	0f b6 0a             	movzbl (%edx),%ecx
80103f18:	8b 55 08             	mov    0x8(%ebp),%edx
80103f1b:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
80103f1f:	8d 50 01             	lea    0x1(%eax),%edx
80103f22:	8b 45 08             	mov    0x8(%ebp),%eax
80103f25:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80103f2b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103f2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f32:	3b 45 10             	cmp    0x10(%ebp),%eax
80103f35:	7c a9                	jl     80103ee0 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103f37:	8b 45 08             	mov    0x8(%ebp),%eax
80103f3a:	05 34 02 00 00       	add    $0x234,%eax
80103f3f:	89 04 24             	mov    %eax,(%esp)
80103f42:	e8 bb 0a 00 00       	call   80104a02 <wakeup>
  release(&p->lock);
80103f47:	8b 45 08             	mov    0x8(%ebp),%eax
80103f4a:	89 04 24             	mov    %eax,(%esp)
80103f4d:	e8 17 0d 00 00       	call   80104c69 <release>
  return n;
80103f52:	8b 45 10             	mov    0x10(%ebp),%eax
}
80103f55:	83 c4 24             	add    $0x24,%esp
80103f58:	5b                   	pop    %ebx
80103f59:	5d                   	pop    %ebp
80103f5a:	c3                   	ret    

80103f5b <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103f5b:	55                   	push   %ebp
80103f5c:	89 e5                	mov    %esp,%ebp
80103f5e:	53                   	push   %ebx
80103f5f:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80103f62:	8b 45 08             	mov    0x8(%ebp),%eax
80103f65:	89 04 24             	mov    %eax,(%esp)
80103f68:	e8 9a 0c 00 00       	call   80104c07 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103f6d:	eb 3a                	jmp    80103fa9 <piperead+0x4e>
    if(proc->killed){
80103f6f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103f75:	8b 40 24             	mov    0x24(%eax),%eax
80103f78:	85 c0                	test   %eax,%eax
80103f7a:	74 15                	je     80103f91 <piperead+0x36>
      release(&p->lock);
80103f7c:	8b 45 08             	mov    0x8(%ebp),%eax
80103f7f:	89 04 24             	mov    %eax,(%esp)
80103f82:	e8 e2 0c 00 00       	call   80104c69 <release>
      return -1;
80103f87:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f8c:	e9 b7 00 00 00       	jmp    80104048 <piperead+0xed>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80103f91:	8b 45 08             	mov    0x8(%ebp),%eax
80103f94:	8b 55 08             	mov    0x8(%ebp),%edx
80103f97:	81 c2 34 02 00 00    	add    $0x234,%edx
80103f9d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103fa1:	89 14 24             	mov    %edx,(%esp)
80103fa4:	e8 80 09 00 00       	call   80104929 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103fa9:	8b 45 08             	mov    0x8(%ebp),%eax
80103fac:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80103fb2:	8b 45 08             	mov    0x8(%ebp),%eax
80103fb5:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103fbb:	39 c2                	cmp    %eax,%edx
80103fbd:	75 0d                	jne    80103fcc <piperead+0x71>
80103fbf:	8b 45 08             	mov    0x8(%ebp),%eax
80103fc2:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103fc8:	85 c0                	test   %eax,%eax
80103fca:	75 a3                	jne    80103f6f <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103fcc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103fd3:	eb 4a                	jmp    8010401f <piperead+0xc4>
    if(p->nread == p->nwrite)
80103fd5:	8b 45 08             	mov    0x8(%ebp),%eax
80103fd8:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80103fde:	8b 45 08             	mov    0x8(%ebp),%eax
80103fe1:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103fe7:	39 c2                	cmp    %eax,%edx
80103fe9:	74 3e                	je     80104029 <piperead+0xce>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80103feb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103fee:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ff1:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80103ff4:	8b 45 08             	mov    0x8(%ebp),%eax
80103ff7:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80103ffd:	89 c3                	mov    %eax,%ebx
80103fff:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80104005:	8b 55 08             	mov    0x8(%ebp),%edx
80104008:	0f b6 54 1a 34       	movzbl 0x34(%edx,%ebx,1),%edx
8010400d:	88 11                	mov    %dl,(%ecx)
8010400f:	8d 50 01             	lea    0x1(%eax),%edx
80104012:	8b 45 08             	mov    0x8(%ebp),%eax
80104015:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010401b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010401f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104022:	3b 45 10             	cmp    0x10(%ebp),%eax
80104025:	7c ae                	jl     80103fd5 <piperead+0x7a>
80104027:	eb 01                	jmp    8010402a <piperead+0xcf>
    if(p->nread == p->nwrite)
      break;
80104029:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
8010402a:	8b 45 08             	mov    0x8(%ebp),%eax
8010402d:	05 38 02 00 00       	add    $0x238,%eax
80104032:	89 04 24             	mov    %eax,(%esp)
80104035:	e8 c8 09 00 00       	call   80104a02 <wakeup>
  release(&p->lock);
8010403a:	8b 45 08             	mov    0x8(%ebp),%eax
8010403d:	89 04 24             	mov    %eax,(%esp)
80104040:	e8 24 0c 00 00       	call   80104c69 <release>
  return i;
80104045:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104048:	83 c4 24             	add    $0x24,%esp
8010404b:	5b                   	pop    %ebx
8010404c:	5d                   	pop    %ebp
8010404d:	c3                   	ret    
8010404e:	66 90                	xchg   %ax,%ax

80104050 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104050:	55                   	push   %ebp
80104051:	89 e5                	mov    %esp,%ebp
80104053:	53                   	push   %ebx
80104054:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104057:	9c                   	pushf  
80104058:	5b                   	pop    %ebx
80104059:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
8010405c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010405f:	83 c4 10             	add    $0x10,%esp
80104062:	5b                   	pop    %ebx
80104063:	5d                   	pop    %ebp
80104064:	c3                   	ret    

80104065 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104065:	55                   	push   %ebp
80104066:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104068:	fb                   	sti    
}
80104069:	5d                   	pop    %ebp
8010406a:	c3                   	ret    

8010406b <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
8010406b:	55                   	push   %ebp
8010406c:	89 e5                	mov    %esp,%ebp
8010406e:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104071:	c7 44 24 04 e9 84 10 	movl   $0x801084e9,0x4(%esp)
80104078:	80 
80104079:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104080:	e8 61 0b 00 00       	call   80104be6 <initlock>
}
80104085:	c9                   	leave  
80104086:	c3                   	ret    

80104087 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104087:	55                   	push   %ebp
80104088:	89 e5                	mov    %esp,%ebp
8010408a:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
8010408d:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104094:	e8 6e 0b 00 00       	call   80104c07 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104099:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
801040a0:	eb 0e                	jmp    801040b0 <allocproc+0x29>
    if(p->state == UNUSED)
801040a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040a5:	8b 40 0c             	mov    0xc(%eax),%eax
801040a8:	85 c0                	test   %eax,%eax
801040aa:	74 23                	je     801040cf <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801040ac:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801040b0:	81 7d f4 54 1e 11 80 	cmpl   $0x80111e54,-0xc(%ebp)
801040b7:	72 e9                	jb     801040a2 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
801040b9:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801040c0:	e8 a4 0b 00 00       	call   80104c69 <release>
  return 0;
801040c5:	b8 00 00 00 00       	mov    $0x0,%eax
801040ca:	e9 b5 00 00 00       	jmp    80104184 <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
801040cf:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
801040d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040d3:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
801040da:	a1 04 b0 10 80       	mov    0x8010b004,%eax
801040df:	8b 55 f4             	mov    -0xc(%ebp),%edx
801040e2:	89 42 10             	mov    %eax,0x10(%edx)
801040e5:	83 c0 01             	add    $0x1,%eax
801040e8:	a3 04 b0 10 80       	mov    %eax,0x8010b004
  release(&ptable.lock);
801040ed:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801040f4:	e8 70 0b 00 00       	call   80104c69 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801040f9:	e8 4d ea ff ff       	call   80102b4b <kalloc>
801040fe:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104101:	89 42 08             	mov    %eax,0x8(%edx)
80104104:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104107:	8b 40 08             	mov    0x8(%eax),%eax
8010410a:	85 c0                	test   %eax,%eax
8010410c:	75 11                	jne    8010411f <allocproc+0x98>
    p->state = UNUSED;
8010410e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104111:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104118:	b8 00 00 00 00       	mov    $0x0,%eax
8010411d:	eb 65                	jmp    80104184 <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
8010411f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104122:	8b 40 08             	mov    0x8(%eax),%eax
80104125:	05 00 10 00 00       	add    $0x1000,%eax
8010412a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
8010412d:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104131:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104134:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104137:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
8010413a:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
8010413e:	ba b8 62 10 80       	mov    $0x801062b8,%edx
80104143:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104146:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104148:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
8010414c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010414f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104152:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104155:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104158:	8b 40 1c             	mov    0x1c(%eax),%eax
8010415b:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104162:	00 
80104163:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010416a:	00 
8010416b:	89 04 24             	mov    %eax,(%esp)
8010416e:	e8 ef 0c 00 00       	call   80104e62 <memset>
  p->context->eip = (uint)forkret;
80104173:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104176:	8b 40 1c             	mov    0x1c(%eax),%eax
80104179:	ba fd 48 10 80       	mov    $0x801048fd,%edx
8010417e:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104181:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104184:	c9                   	leave  
80104185:	c3                   	ret    

80104186 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104186:	55                   	push   %ebp
80104187:	89 e5                	mov    %esp,%ebp
80104189:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
8010418c:	e8 f6 fe ff ff       	call   80104087 <allocproc>
80104191:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104194:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104197:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm(kalloc)) == 0)
8010419c:	c7 04 24 4b 2b 10 80 	movl   $0x80102b4b,(%esp)
801041a3:	e8 1b 38 00 00       	call   801079c3 <setupkvm>
801041a8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041ab:	89 42 04             	mov    %eax,0x4(%edx)
801041ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041b1:	8b 40 04             	mov    0x4(%eax),%eax
801041b4:	85 c0                	test   %eax,%eax
801041b6:	75 0c                	jne    801041c4 <userinit+0x3e>
    panic("userinit: out of memory?");
801041b8:	c7 04 24 f0 84 10 80 	movl   $0x801084f0,(%esp)
801041bf:	e8 82 c3 ff ff       	call   80100546 <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801041c4:	ba 2c 00 00 00       	mov    $0x2c,%edx
801041c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041cc:	8b 40 04             	mov    0x4(%eax),%eax
801041cf:	89 54 24 08          	mov    %edx,0x8(%esp)
801041d3:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
801041da:	80 
801041db:	89 04 24             	mov    %eax,(%esp)
801041de:	e8 38 3a 00 00       	call   80107c1b <inituvm>
  p->sz = PGSIZE;
801041e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041e6:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
801041ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041ef:	8b 40 18             	mov    0x18(%eax),%eax
801041f2:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
801041f9:	00 
801041fa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104201:	00 
80104202:	89 04 24             	mov    %eax,(%esp)
80104205:	e8 58 0c 00 00       	call   80104e62 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
8010420a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010420d:	8b 40 18             	mov    0x18(%eax),%eax
80104210:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104216:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104219:	8b 40 18             	mov    0x18(%eax),%eax
8010421c:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80104222:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104225:	8b 40 18             	mov    0x18(%eax),%eax
80104228:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010422b:	8b 52 18             	mov    0x18(%edx),%edx
8010422e:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104232:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104236:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104239:	8b 40 18             	mov    0x18(%eax),%eax
8010423c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010423f:	8b 52 18             	mov    0x18(%edx),%edx
80104242:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104246:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
8010424a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010424d:	8b 40 18             	mov    0x18(%eax),%eax
80104250:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104257:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010425a:	8b 40 18             	mov    0x18(%eax),%eax
8010425d:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104264:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104267:	8b 40 18             	mov    0x18(%eax),%eax
8010426a:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104271:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104274:	83 c0 6c             	add    $0x6c,%eax
80104277:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010427e:	00 
8010427f:	c7 44 24 04 09 85 10 	movl   $0x80108509,0x4(%esp)
80104286:	80 
80104287:	89 04 24             	mov    %eax,(%esp)
8010428a:	e8 03 0e 00 00       	call   80105092 <safestrcpy>
  p->cwd = namei("/");
8010428f:	c7 04 24 12 85 10 80 	movl   $0x80108512,(%esp)
80104296:	e8 ba e1 ff ff       	call   80102455 <namei>
8010429b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010429e:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
801042a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042a4:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
801042ab:	c9                   	leave  
801042ac:	c3                   	ret    

801042ad <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
801042ad:	55                   	push   %ebp
801042ae:	89 e5                	mov    %esp,%ebp
801042b0:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
801042b3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801042b9:	8b 00                	mov    (%eax),%eax
801042bb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
801042be:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801042c2:	7e 34                	jle    801042f8 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
801042c4:	8b 55 08             	mov    0x8(%ebp),%edx
801042c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042ca:	01 c2                	add    %eax,%edx
801042cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801042d2:	8b 40 04             	mov    0x4(%eax),%eax
801042d5:	89 54 24 08          	mov    %edx,0x8(%esp)
801042d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042dc:	89 54 24 04          	mov    %edx,0x4(%esp)
801042e0:	89 04 24             	mov    %eax,(%esp)
801042e3:	e8 ad 3a 00 00       	call   80107d95 <allocuvm>
801042e8:	89 45 f4             	mov    %eax,-0xc(%ebp)
801042eb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801042ef:	75 41                	jne    80104332 <growproc+0x85>
      return -1;
801042f1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042f6:	eb 58                	jmp    80104350 <growproc+0xa3>
  } else if(n < 0){
801042f8:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801042fc:	79 34                	jns    80104332 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801042fe:	8b 55 08             	mov    0x8(%ebp),%edx
80104301:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104304:	01 c2                	add    %eax,%edx
80104306:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010430c:	8b 40 04             	mov    0x4(%eax),%eax
8010430f:	89 54 24 08          	mov    %edx,0x8(%esp)
80104313:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104316:	89 54 24 04          	mov    %edx,0x4(%esp)
8010431a:	89 04 24             	mov    %eax,(%esp)
8010431d:	e8 4d 3b 00 00       	call   80107e6f <deallocuvm>
80104322:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104325:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104329:	75 07                	jne    80104332 <growproc+0x85>
      return -1;
8010432b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104330:	eb 1e                	jmp    80104350 <growproc+0xa3>
  }
  proc->sz = sz;
80104332:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104338:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010433b:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
8010433d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104343:	89 04 24             	mov    %eax,(%esp)
80104346:	e8 69 37 00 00       	call   80107ab4 <switchuvm>
  return 0;
8010434b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104350:	c9                   	leave  
80104351:	c3                   	ret    

80104352 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104352:	55                   	push   %ebp
80104353:	89 e5                	mov    %esp,%ebp
80104355:	57                   	push   %edi
80104356:	56                   	push   %esi
80104357:	53                   	push   %ebx
80104358:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
8010435b:	e8 27 fd ff ff       	call   80104087 <allocproc>
80104360:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104363:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104367:	75 0a                	jne    80104373 <fork+0x21>
    return -1;
80104369:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010436e:	e9 3a 01 00 00       	jmp    801044ad <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104373:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104379:	8b 10                	mov    (%eax),%edx
8010437b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104381:	8b 40 04             	mov    0x4(%eax),%eax
80104384:	89 54 24 04          	mov    %edx,0x4(%esp)
80104388:	89 04 24             	mov    %eax,(%esp)
8010438b:	e8 7b 3c 00 00       	call   8010800b <copyuvm>
80104390:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104393:	89 42 04             	mov    %eax,0x4(%edx)
80104396:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104399:	8b 40 04             	mov    0x4(%eax),%eax
8010439c:	85 c0                	test   %eax,%eax
8010439e:	75 2c                	jne    801043cc <fork+0x7a>
    kfree(np->kstack);
801043a0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043a3:	8b 40 08             	mov    0x8(%eax),%eax
801043a6:	89 04 24             	mov    %eax,(%esp)
801043a9:	e8 04 e7 ff ff       	call   80102ab2 <kfree>
    np->kstack = 0;
801043ae:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043b1:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
801043b8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043bb:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
801043c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043c7:	e9 e1 00 00 00       	jmp    801044ad <fork+0x15b>
  }
  np->sz = proc->sz;
801043cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043d2:	8b 10                	mov    (%eax),%edx
801043d4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043d7:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
801043d9:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801043e0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043e3:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
801043e6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043e9:	8b 50 18             	mov    0x18(%eax),%edx
801043ec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043f2:	8b 40 18             	mov    0x18(%eax),%eax
801043f5:	89 c3                	mov    %eax,%ebx
801043f7:	b8 13 00 00 00       	mov    $0x13,%eax
801043fc:	89 d7                	mov    %edx,%edi
801043fe:	89 de                	mov    %ebx,%esi
80104400:	89 c1                	mov    %eax,%ecx
80104402:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104404:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104407:	8b 40 18             	mov    0x18(%eax),%eax
8010440a:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104411:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104418:	eb 3d                	jmp    80104457 <fork+0x105>
    if(proc->ofile[i])
8010441a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104420:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104423:	83 c2 08             	add    $0x8,%edx
80104426:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010442a:	85 c0                	test   %eax,%eax
8010442c:	74 25                	je     80104453 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
8010442e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104434:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104437:	83 c2 08             	add    $0x8,%edx
8010443a:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010443e:	89 04 24             	mov    %eax,(%esp)
80104441:	e8 5e cb ff ff       	call   80100fa4 <filedup>
80104446:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104449:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010444c:	83 c1 08             	add    $0x8,%ecx
8010444f:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104453:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104457:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
8010445b:	7e bd                	jle    8010441a <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
8010445d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104463:	8b 40 68             	mov    0x68(%eax),%eax
80104466:	89 04 24             	mov    %eax,(%esp)
80104469:	e8 f4 d3 ff ff       	call   80101862 <idup>
8010446e:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104471:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
80104474:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104477:	8b 40 10             	mov    0x10(%eax),%eax
8010447a:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
8010447d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104480:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104487:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010448d:	8d 50 6c             	lea    0x6c(%eax),%edx
80104490:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104493:	83 c0 6c             	add    $0x6c,%eax
80104496:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010449d:	00 
8010449e:	89 54 24 04          	mov    %edx,0x4(%esp)
801044a2:	89 04 24             	mov    %eax,(%esp)
801044a5:	e8 e8 0b 00 00       	call   80105092 <safestrcpy>
  return pid;
801044aa:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
801044ad:	83 c4 2c             	add    $0x2c,%esp
801044b0:	5b                   	pop    %ebx
801044b1:	5e                   	pop    %esi
801044b2:	5f                   	pop    %edi
801044b3:	5d                   	pop    %ebp
801044b4:	c3                   	ret    

801044b5 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
801044b5:	55                   	push   %ebp
801044b6:	89 e5                	mov    %esp,%ebp
801044b8:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
801044bb:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801044c2:	a1 48 b6 10 80       	mov    0x8010b648,%eax
801044c7:	39 c2                	cmp    %eax,%edx
801044c9:	75 0c                	jne    801044d7 <exit+0x22>
    panic("init exiting");
801044cb:	c7 04 24 14 85 10 80 	movl   $0x80108514,(%esp)
801044d2:	e8 6f c0 ff ff       	call   80100546 <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801044d7:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801044de:	eb 44                	jmp    80104524 <exit+0x6f>
    if(proc->ofile[fd]){
801044e0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044e6:	8b 55 f0             	mov    -0x10(%ebp),%edx
801044e9:	83 c2 08             	add    $0x8,%edx
801044ec:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801044f0:	85 c0                	test   %eax,%eax
801044f2:	74 2c                	je     80104520 <exit+0x6b>
      fileclose(proc->ofile[fd]);
801044f4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044fa:	8b 55 f0             	mov    -0x10(%ebp),%edx
801044fd:	83 c2 08             	add    $0x8,%edx
80104500:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104504:	89 04 24             	mov    %eax,(%esp)
80104507:	e8 e0 ca ff ff       	call   80100fec <fileclose>
      proc->ofile[fd] = 0;
8010450c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104512:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104515:	83 c2 08             	add    $0x8,%edx
80104518:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010451f:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104520:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104524:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104528:	7e b6                	jle    801044e0 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
8010452a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104530:	8b 40 68             	mov    0x68(%eax),%eax
80104533:	89 04 24             	mov    %eax,(%esp)
80104536:	e8 0c d5 ff ff       	call   80101a47 <iput>
  proc->cwd = 0;
8010453b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104541:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104548:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
8010454f:	e8 b3 06 00 00       	call   80104c07 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104554:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010455a:	8b 40 14             	mov    0x14(%eax),%eax
8010455d:	89 04 24             	mov    %eax,(%esp)
80104560:	e8 5f 04 00 00       	call   801049c4 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104565:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
8010456c:	eb 38                	jmp    801045a6 <exit+0xf1>
    if(p->parent == proc){
8010456e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104571:	8b 50 14             	mov    0x14(%eax),%edx
80104574:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010457a:	39 c2                	cmp    %eax,%edx
8010457c:	75 24                	jne    801045a2 <exit+0xed>
      p->parent = initproc;
8010457e:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
80104584:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104587:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
8010458a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010458d:	8b 40 0c             	mov    0xc(%eax),%eax
80104590:	83 f8 05             	cmp    $0x5,%eax
80104593:	75 0d                	jne    801045a2 <exit+0xed>
        wakeup1(initproc);
80104595:	a1 48 b6 10 80       	mov    0x8010b648,%eax
8010459a:	89 04 24             	mov    %eax,(%esp)
8010459d:	e8 22 04 00 00       	call   801049c4 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801045a2:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801045a6:	81 7d f4 54 1e 11 80 	cmpl   $0x80111e54,-0xc(%ebp)
801045ad:	72 bf                	jb     8010456e <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
801045af:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045b5:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
801045bc:	e8 58 02 00 00       	call   80104819 <sched>
  panic("zombie exit");
801045c1:	c7 04 24 21 85 10 80 	movl   $0x80108521,(%esp)
801045c8:	e8 79 bf ff ff       	call   80100546 <panic>

801045cd <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
801045cd:	55                   	push   %ebp
801045ce:	89 e5                	mov    %esp,%ebp
801045d0:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
801045d3:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801045da:	e8 28 06 00 00       	call   80104c07 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
801045df:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801045e6:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
801045ed:	e9 9a 00 00 00       	jmp    8010468c <wait+0xbf>
      if(p->parent != proc)
801045f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045f5:	8b 50 14             	mov    0x14(%eax),%edx
801045f8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045fe:	39 c2                	cmp    %eax,%edx
80104600:	0f 85 81 00 00 00    	jne    80104687 <wait+0xba>
        continue;
      havekids = 1;
80104606:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
8010460d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104610:	8b 40 0c             	mov    0xc(%eax),%eax
80104613:	83 f8 05             	cmp    $0x5,%eax
80104616:	75 70                	jne    80104688 <wait+0xbb>
        // Found one.
        pid = p->pid;
80104618:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010461b:	8b 40 10             	mov    0x10(%eax),%eax
8010461e:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104621:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104624:	8b 40 08             	mov    0x8(%eax),%eax
80104627:	89 04 24             	mov    %eax,(%esp)
8010462a:	e8 83 e4 ff ff       	call   80102ab2 <kfree>
        p->kstack = 0;
8010462f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104632:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104639:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010463c:	8b 40 04             	mov    0x4(%eax),%eax
8010463f:	89 04 24             	mov    %eax,(%esp)
80104642:	e8 e4 38 00 00       	call   80107f2b <freevm>
        p->state = UNUSED;
80104647:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010464a:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104651:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104654:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
8010465b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010465e:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104665:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104668:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
8010466c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010466f:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104676:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
8010467d:	e8 e7 05 00 00       	call   80104c69 <release>
        return pid;
80104682:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104685:	eb 53                	jmp    801046da <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
80104687:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104688:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010468c:	81 7d f4 54 1e 11 80 	cmpl   $0x80111e54,-0xc(%ebp)
80104693:	0f 82 59 ff ff ff    	jb     801045f2 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104699:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010469d:	74 0d                	je     801046ac <wait+0xdf>
8010469f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046a5:	8b 40 24             	mov    0x24(%eax),%eax
801046a8:	85 c0                	test   %eax,%eax
801046aa:	74 13                	je     801046bf <wait+0xf2>
      release(&ptable.lock);
801046ac:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801046b3:	e8 b1 05 00 00       	call   80104c69 <release>
      return -1;
801046b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046bd:	eb 1b                	jmp    801046da <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
801046bf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046c5:	c7 44 24 04 20 ff 10 	movl   $0x8010ff20,0x4(%esp)
801046cc:	80 
801046cd:	89 04 24             	mov    %eax,(%esp)
801046d0:	e8 54 02 00 00       	call   80104929 <sleep>
  }
801046d5:	e9 05 ff ff ff       	jmp    801045df <wait+0x12>
}
801046da:	c9                   	leave  
801046db:	c3                   	ret    

801046dc <register_handler>:

void
register_handler(sighandler_t sighandler)
{
801046dc:	55                   	push   %ebp
801046dd:	89 e5                	mov    %esp,%ebp
801046df:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
801046e2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046e8:	8b 40 18             	mov    0x18(%eax),%eax
801046eb:	8b 40 44             	mov    0x44(%eax),%eax
801046ee:	89 c2                	mov    %eax,%edx
801046f0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046f6:	8b 40 04             	mov    0x4(%eax),%eax
801046f9:	89 54 24 04          	mov    %edx,0x4(%esp)
801046fd:	89 04 24             	mov    %eax,(%esp)
80104700:	e8 17 3a 00 00       	call   8010811c <uva2ka>
80104705:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
80104708:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010470e:	8b 40 18             	mov    0x18(%eax),%eax
80104711:	8b 40 44             	mov    0x44(%eax),%eax
80104714:	25 ff 0f 00 00       	and    $0xfff,%eax
80104719:	85 c0                	test   %eax,%eax
8010471b:	75 0c                	jne    80104729 <register_handler+0x4d>
    panic("esp_offset == 0");
8010471d:	c7 04 24 2d 85 10 80 	movl   $0x8010852d,(%esp)
80104724:	e8 1d be ff ff       	call   80100546 <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80104729:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010472f:	8b 40 18             	mov    0x18(%eax),%eax
80104732:	8b 40 44             	mov    0x44(%eax),%eax
80104735:	83 e8 04             	sub    $0x4,%eax
80104738:	89 c2                	mov    %eax,%edx
8010473a:	81 e2 ff 0f 00 00    	and    $0xfff,%edx
80104740:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104743:	01 c2                	add    %eax,%edx
          = proc->tf->eip;
80104745:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010474b:	8b 40 18             	mov    0x18(%eax),%eax
8010474e:	8b 40 38             	mov    0x38(%eax),%eax
80104751:	89 02                	mov    %eax,(%edx)
  proc->tf->esp -= 4;
80104753:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104759:	8b 40 18             	mov    0x18(%eax),%eax
8010475c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104763:	8b 52 18             	mov    0x18(%edx),%edx
80104766:	8b 52 44             	mov    0x44(%edx),%edx
80104769:	83 ea 04             	sub    $0x4,%edx
8010476c:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
8010476f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104775:	8b 40 18             	mov    0x18(%eax),%eax
80104778:	8b 55 08             	mov    0x8(%ebp),%edx
8010477b:	89 50 38             	mov    %edx,0x38(%eax)
}
8010477e:	c9                   	leave  
8010477f:	c3                   	ret    

80104780 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104780:	55                   	push   %ebp
80104781:	89 e5                	mov    %esp,%ebp
80104783:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104786:	e8 da f8 ff ff       	call   80104065 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
8010478b:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104792:	e8 70 04 00 00       	call   80104c07 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104797:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
8010479e:	eb 5f                	jmp    801047ff <scheduler+0x7f>
      if(p->state != RUNNABLE)
801047a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047a3:	8b 40 0c             	mov    0xc(%eax),%eax
801047a6:	83 f8 03             	cmp    $0x3,%eax
801047a9:	75 4f                	jne    801047fa <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801047ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047ae:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
801047b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047b7:	89 04 24             	mov    %eax,(%esp)
801047ba:	e8 f5 32 00 00       	call   80107ab4 <switchuvm>
      p->state = RUNNING;
801047bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047c2:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
801047c9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047cf:	8b 40 1c             	mov    0x1c(%eax),%eax
801047d2:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801047d9:	83 c2 04             	add    $0x4,%edx
801047dc:	89 44 24 04          	mov    %eax,0x4(%esp)
801047e0:	89 14 24             	mov    %edx,(%esp)
801047e3:	e8 20 09 00 00       	call   80105108 <swtch>
      switchkvm();
801047e8:	e8 aa 32 00 00       	call   80107a97 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
801047ed:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801047f4:	00 00 00 00 
801047f8:	eb 01                	jmp    801047fb <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
801047fa:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801047fb:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801047ff:	81 7d f4 54 1e 11 80 	cmpl   $0x80111e54,-0xc(%ebp)
80104806:	72 98                	jb     801047a0 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104808:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
8010480f:	e8 55 04 00 00       	call   80104c69 <release>

  }
80104814:	e9 6d ff ff ff       	jmp    80104786 <scheduler+0x6>

80104819 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104819:	55                   	push   %ebp
8010481a:	89 e5                	mov    %esp,%ebp
8010481c:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
8010481f:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104826:	e8 06 05 00 00       	call   80104d31 <holding>
8010482b:	85 c0                	test   %eax,%eax
8010482d:	75 0c                	jne    8010483b <sched+0x22>
    panic("sched ptable.lock");
8010482f:	c7 04 24 3d 85 10 80 	movl   $0x8010853d,(%esp)
80104836:	e8 0b bd ff ff       	call   80100546 <panic>
  if(cpu->ncli != 1)
8010483b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104841:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104847:	83 f8 01             	cmp    $0x1,%eax
8010484a:	74 0c                	je     80104858 <sched+0x3f>
    panic("sched locks");
8010484c:	c7 04 24 4f 85 10 80 	movl   $0x8010854f,(%esp)
80104853:	e8 ee bc ff ff       	call   80100546 <panic>
  if(proc->state == RUNNING)
80104858:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010485e:	8b 40 0c             	mov    0xc(%eax),%eax
80104861:	83 f8 04             	cmp    $0x4,%eax
80104864:	75 0c                	jne    80104872 <sched+0x59>
    panic("sched running");
80104866:	c7 04 24 5b 85 10 80 	movl   $0x8010855b,(%esp)
8010486d:	e8 d4 bc ff ff       	call   80100546 <panic>
  if(readeflags()&FL_IF)
80104872:	e8 d9 f7 ff ff       	call   80104050 <readeflags>
80104877:	25 00 02 00 00       	and    $0x200,%eax
8010487c:	85 c0                	test   %eax,%eax
8010487e:	74 0c                	je     8010488c <sched+0x73>
    panic("sched interruptible");
80104880:	c7 04 24 69 85 10 80 	movl   $0x80108569,(%esp)
80104887:	e8 ba bc ff ff       	call   80100546 <panic>
  intena = cpu->intena;
8010488c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104892:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104898:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
8010489b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801048a1:	8b 40 04             	mov    0x4(%eax),%eax
801048a4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801048ab:	83 c2 1c             	add    $0x1c,%edx
801048ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801048b2:	89 14 24             	mov    %edx,(%esp)
801048b5:	e8 4e 08 00 00       	call   80105108 <swtch>
  cpu->intena = intena;
801048ba:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801048c0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801048c3:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801048c9:	c9                   	leave  
801048ca:	c3                   	ret    

801048cb <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
801048cb:	55                   	push   %ebp
801048cc:	89 e5                	mov    %esp,%ebp
801048ce:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801048d1:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801048d8:	e8 2a 03 00 00       	call   80104c07 <acquire>
  proc->state = RUNNABLE;
801048dd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048e3:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801048ea:	e8 2a ff ff ff       	call   80104819 <sched>
  release(&ptable.lock);
801048ef:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801048f6:	e8 6e 03 00 00       	call   80104c69 <release>
}
801048fb:	c9                   	leave  
801048fc:	c3                   	ret    

801048fd <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
801048fd:	55                   	push   %ebp
801048fe:	89 e5                	mov    %esp,%ebp
80104900:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104903:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
8010490a:	e8 5a 03 00 00       	call   80104c69 <release>

  if (first) {
8010490f:	a1 20 b0 10 80       	mov    0x8010b020,%eax
80104914:	85 c0                	test   %eax,%eax
80104916:	74 0f                	je     80104927 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104918:	c7 05 20 b0 10 80 00 	movl   $0x0,0x8010b020
8010491f:	00 00 00 
    initlog();
80104922:	e8 39 e7 ff ff       	call   80103060 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104927:	c9                   	leave  
80104928:	c3                   	ret    

80104929 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104929:	55                   	push   %ebp
8010492a:	89 e5                	mov    %esp,%ebp
8010492c:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
8010492f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104935:	85 c0                	test   %eax,%eax
80104937:	75 0c                	jne    80104945 <sleep+0x1c>
    panic("sleep");
80104939:	c7 04 24 7d 85 10 80 	movl   $0x8010857d,(%esp)
80104940:	e8 01 bc ff ff       	call   80100546 <panic>

  if(lk == 0)
80104945:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104949:	75 0c                	jne    80104957 <sleep+0x2e>
    panic("sleep without lk");
8010494b:	c7 04 24 83 85 10 80 	movl   $0x80108583,(%esp)
80104952:	e8 ef bb ff ff       	call   80100546 <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104957:	81 7d 0c 20 ff 10 80 	cmpl   $0x8010ff20,0xc(%ebp)
8010495e:	74 17                	je     80104977 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104960:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104967:	e8 9b 02 00 00       	call   80104c07 <acquire>
    release(lk);
8010496c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010496f:	89 04 24             	mov    %eax,(%esp)
80104972:	e8 f2 02 00 00       	call   80104c69 <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104977:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010497d:	8b 55 08             	mov    0x8(%ebp),%edx
80104980:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104983:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104989:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80104990:	e8 84 fe ff ff       	call   80104819 <sched>

  // Tidy up.
  proc->chan = 0;
80104995:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010499b:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801049a2:	81 7d 0c 20 ff 10 80 	cmpl   $0x8010ff20,0xc(%ebp)
801049a9:	74 17                	je     801049c2 <sleep+0x99>
    release(&ptable.lock);
801049ab:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801049b2:	e8 b2 02 00 00       	call   80104c69 <release>
    acquire(lk);
801049b7:	8b 45 0c             	mov    0xc(%ebp),%eax
801049ba:	89 04 24             	mov    %eax,(%esp)
801049bd:	e8 45 02 00 00       	call   80104c07 <acquire>
  }
}
801049c2:	c9                   	leave  
801049c3:	c3                   	ret    

801049c4 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801049c4:	55                   	push   %ebp
801049c5:	89 e5                	mov    %esp,%ebp
801049c7:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801049ca:	c7 45 fc 54 ff 10 80 	movl   $0x8010ff54,-0x4(%ebp)
801049d1:	eb 24                	jmp    801049f7 <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
801049d3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801049d6:	8b 40 0c             	mov    0xc(%eax),%eax
801049d9:	83 f8 02             	cmp    $0x2,%eax
801049dc:	75 15                	jne    801049f3 <wakeup1+0x2f>
801049de:	8b 45 fc             	mov    -0x4(%ebp),%eax
801049e1:	8b 40 20             	mov    0x20(%eax),%eax
801049e4:	3b 45 08             	cmp    0x8(%ebp),%eax
801049e7:	75 0a                	jne    801049f3 <wakeup1+0x2f>
      p->state = RUNNABLE;
801049e9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801049ec:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801049f3:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
801049f7:	81 7d fc 54 1e 11 80 	cmpl   $0x80111e54,-0x4(%ebp)
801049fe:	72 d3                	jb     801049d3 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104a00:	c9                   	leave  
80104a01:	c3                   	ret    

80104a02 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104a02:	55                   	push   %ebp
80104a03:	89 e5                	mov    %esp,%ebp
80104a05:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104a08:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104a0f:	e8 f3 01 00 00       	call   80104c07 <acquire>
  wakeup1(chan);
80104a14:	8b 45 08             	mov    0x8(%ebp),%eax
80104a17:	89 04 24             	mov    %eax,(%esp)
80104a1a:	e8 a5 ff ff ff       	call   801049c4 <wakeup1>
  release(&ptable.lock);
80104a1f:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104a26:	e8 3e 02 00 00       	call   80104c69 <release>
}
80104a2b:	c9                   	leave  
80104a2c:	c3                   	ret    

80104a2d <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104a2d:	55                   	push   %ebp
80104a2e:	89 e5                	mov    %esp,%ebp
80104a30:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104a33:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104a3a:	e8 c8 01 00 00       	call   80104c07 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a3f:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
80104a46:	eb 41                	jmp    80104a89 <kill+0x5c>
    if(p->pid == pid){
80104a48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a4b:	8b 40 10             	mov    0x10(%eax),%eax
80104a4e:	3b 45 08             	cmp    0x8(%ebp),%eax
80104a51:	75 32                	jne    80104a85 <kill+0x58>
      p->killed = 1;
80104a53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a56:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104a5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a60:	8b 40 0c             	mov    0xc(%eax),%eax
80104a63:	83 f8 02             	cmp    $0x2,%eax
80104a66:	75 0a                	jne    80104a72 <kill+0x45>
        p->state = RUNNABLE;
80104a68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a6b:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104a72:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104a79:	e8 eb 01 00 00       	call   80104c69 <release>
      return 0;
80104a7e:	b8 00 00 00 00       	mov    $0x0,%eax
80104a83:	eb 1e                	jmp    80104aa3 <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a85:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104a89:	81 7d f4 54 1e 11 80 	cmpl   $0x80111e54,-0xc(%ebp)
80104a90:	72 b6                	jb     80104a48 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104a92:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104a99:	e8 cb 01 00 00       	call   80104c69 <release>
  return -1;
80104a9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104aa3:	c9                   	leave  
80104aa4:	c3                   	ret    

80104aa5 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104aa5:	55                   	push   %ebp
80104aa6:	89 e5                	mov    %esp,%ebp
80104aa8:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104aab:	c7 45 f0 54 ff 10 80 	movl   $0x8010ff54,-0x10(%ebp)
80104ab2:	e9 d8 00 00 00       	jmp    80104b8f <procdump+0xea>
    if(p->state == UNUSED)
80104ab7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104aba:	8b 40 0c             	mov    0xc(%eax),%eax
80104abd:	85 c0                	test   %eax,%eax
80104abf:	0f 84 c5 00 00 00    	je     80104b8a <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104ac5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ac8:	8b 40 0c             	mov    0xc(%eax),%eax
80104acb:	83 f8 05             	cmp    $0x5,%eax
80104ace:	77 23                	ja     80104af3 <procdump+0x4e>
80104ad0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ad3:	8b 40 0c             	mov    0xc(%eax),%eax
80104ad6:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104add:	85 c0                	test   %eax,%eax
80104adf:	74 12                	je     80104af3 <procdump+0x4e>
      state = states[p->state];
80104ae1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ae4:	8b 40 0c             	mov    0xc(%eax),%eax
80104ae7:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104aee:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104af1:	eb 07                	jmp    80104afa <procdump+0x55>
    else
      state = "???";
80104af3:	c7 45 ec 94 85 10 80 	movl   $0x80108594,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104afa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104afd:	8d 50 6c             	lea    0x6c(%eax),%edx
80104b00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b03:	8b 40 10             	mov    0x10(%eax),%eax
80104b06:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104b0a:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104b0d:	89 54 24 08          	mov    %edx,0x8(%esp)
80104b11:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b15:	c7 04 24 98 85 10 80 	movl   $0x80108598,(%esp)
80104b1c:	e8 89 b8 ff ff       	call   801003aa <cprintf>
    if(p->state == SLEEPING){
80104b21:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b24:	8b 40 0c             	mov    0xc(%eax),%eax
80104b27:	83 f8 02             	cmp    $0x2,%eax
80104b2a:	75 50                	jne    80104b7c <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104b2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b2f:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b32:	8b 40 0c             	mov    0xc(%eax),%eax
80104b35:	83 c0 08             	add    $0x8,%eax
80104b38:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104b3b:	89 54 24 04          	mov    %edx,0x4(%esp)
80104b3f:	89 04 24             	mov    %eax,(%esp)
80104b42:	e8 71 01 00 00       	call   80104cb8 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104b47:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104b4e:	eb 1b                	jmp    80104b6b <procdump+0xc6>
        cprintf(" %p", pc[i]);
80104b50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b53:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104b57:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b5b:	c7 04 24 a1 85 10 80 	movl   $0x801085a1,(%esp)
80104b62:	e8 43 b8 ff ff       	call   801003aa <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104b67:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104b6b:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104b6f:	7f 0b                	jg     80104b7c <procdump+0xd7>
80104b71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b74:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104b78:	85 c0                	test   %eax,%eax
80104b7a:	75 d4                	jne    80104b50 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104b7c:	c7 04 24 a5 85 10 80 	movl   $0x801085a5,(%esp)
80104b83:	e8 22 b8 ff ff       	call   801003aa <cprintf>
80104b88:	eb 01                	jmp    80104b8b <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80104b8a:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b8b:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104b8f:	81 7d f0 54 1e 11 80 	cmpl   $0x80111e54,-0x10(%ebp)
80104b96:	0f 82 1b ff ff ff    	jb     80104ab7 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104b9c:	c9                   	leave  
80104b9d:	c3                   	ret    
80104b9e:	66 90                	xchg   %ax,%ax

80104ba0 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104ba0:	55                   	push   %ebp
80104ba1:	89 e5                	mov    %esp,%ebp
80104ba3:	53                   	push   %ebx
80104ba4:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104ba7:	9c                   	pushf  
80104ba8:	5b                   	pop    %ebx
80104ba9:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104bac:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104baf:	83 c4 10             	add    $0x10,%esp
80104bb2:	5b                   	pop    %ebx
80104bb3:	5d                   	pop    %ebp
80104bb4:	c3                   	ret    

80104bb5 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80104bb5:	55                   	push   %ebp
80104bb6:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104bb8:	fa                   	cli    
}
80104bb9:	5d                   	pop    %ebp
80104bba:	c3                   	ret    

80104bbb <sti>:

static inline void
sti(void)
{
80104bbb:	55                   	push   %ebp
80104bbc:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104bbe:	fb                   	sti    
}
80104bbf:	5d                   	pop    %ebp
80104bc0:	c3                   	ret    

80104bc1 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104bc1:	55                   	push   %ebp
80104bc2:	89 e5                	mov    %esp,%ebp
80104bc4:	53                   	push   %ebx
80104bc5:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80104bc8:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104bcb:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80104bce:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104bd1:	89 c3                	mov    %eax,%ebx
80104bd3:	89 d8                	mov    %ebx,%eax
80104bd5:	f0 87 02             	lock xchg %eax,(%edx)
80104bd8:	89 c3                	mov    %eax,%ebx
80104bda:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104bdd:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104be0:	83 c4 10             	add    $0x10,%esp
80104be3:	5b                   	pop    %ebx
80104be4:	5d                   	pop    %ebp
80104be5:	c3                   	ret    

80104be6 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104be6:	55                   	push   %ebp
80104be7:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104be9:	8b 45 08             	mov    0x8(%ebp),%eax
80104bec:	8b 55 0c             	mov    0xc(%ebp),%edx
80104bef:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104bf2:	8b 45 08             	mov    0x8(%ebp),%eax
80104bf5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104bfb:	8b 45 08             	mov    0x8(%ebp),%eax
80104bfe:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104c05:	5d                   	pop    %ebp
80104c06:	c3                   	ret    

80104c07 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104c07:	55                   	push   %ebp
80104c08:	89 e5                	mov    %esp,%ebp
80104c0a:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104c0d:	e8 49 01 00 00       	call   80104d5b <pushcli>
  if(holding(lk))
80104c12:	8b 45 08             	mov    0x8(%ebp),%eax
80104c15:	89 04 24             	mov    %eax,(%esp)
80104c18:	e8 14 01 00 00       	call   80104d31 <holding>
80104c1d:	85 c0                	test   %eax,%eax
80104c1f:	74 0c                	je     80104c2d <acquire+0x26>
    panic("acquire");
80104c21:	c7 04 24 d1 85 10 80 	movl   $0x801085d1,(%esp)
80104c28:	e8 19 b9 ff ff       	call   80100546 <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80104c2d:	90                   	nop
80104c2e:	8b 45 08             	mov    0x8(%ebp),%eax
80104c31:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80104c38:	00 
80104c39:	89 04 24             	mov    %eax,(%esp)
80104c3c:	e8 80 ff ff ff       	call   80104bc1 <xchg>
80104c41:	85 c0                	test   %eax,%eax
80104c43:	75 e9                	jne    80104c2e <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80104c45:	8b 45 08             	mov    0x8(%ebp),%eax
80104c48:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104c4f:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80104c52:	8b 45 08             	mov    0x8(%ebp),%eax
80104c55:	83 c0 0c             	add    $0xc,%eax
80104c58:	89 44 24 04          	mov    %eax,0x4(%esp)
80104c5c:	8d 45 08             	lea    0x8(%ebp),%eax
80104c5f:	89 04 24             	mov    %eax,(%esp)
80104c62:	e8 51 00 00 00       	call   80104cb8 <getcallerpcs>
}
80104c67:	c9                   	leave  
80104c68:	c3                   	ret    

80104c69 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80104c69:	55                   	push   %ebp
80104c6a:	89 e5                	mov    %esp,%ebp
80104c6c:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80104c6f:	8b 45 08             	mov    0x8(%ebp),%eax
80104c72:	89 04 24             	mov    %eax,(%esp)
80104c75:	e8 b7 00 00 00       	call   80104d31 <holding>
80104c7a:	85 c0                	test   %eax,%eax
80104c7c:	75 0c                	jne    80104c8a <release+0x21>
    panic("release");
80104c7e:	c7 04 24 d9 85 10 80 	movl   $0x801085d9,(%esp)
80104c85:	e8 bc b8 ff ff       	call   80100546 <panic>

  lk->pcs[0] = 0;
80104c8a:	8b 45 08             	mov    0x8(%ebp),%eax
80104c8d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80104c94:	8b 45 08             	mov    0x8(%ebp),%eax
80104c97:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80104c9e:	8b 45 08             	mov    0x8(%ebp),%eax
80104ca1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104ca8:	00 
80104ca9:	89 04 24             	mov    %eax,(%esp)
80104cac:	e8 10 ff ff ff       	call   80104bc1 <xchg>

  popcli();
80104cb1:	e8 ed 00 00 00       	call   80104da3 <popcli>
}
80104cb6:	c9                   	leave  
80104cb7:	c3                   	ret    

80104cb8 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80104cb8:	55                   	push   %ebp
80104cb9:	89 e5                	mov    %esp,%ebp
80104cbb:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80104cbe:	8b 45 08             	mov    0x8(%ebp),%eax
80104cc1:	83 e8 08             	sub    $0x8,%eax
80104cc4:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80104cc7:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80104cce:	eb 38                	jmp    80104d08 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80104cd0:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80104cd4:	74 53                	je     80104d29 <getcallerpcs+0x71>
80104cd6:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80104cdd:	76 4a                	jbe    80104d29 <getcallerpcs+0x71>
80104cdf:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80104ce3:	74 44                	je     80104d29 <getcallerpcs+0x71>
      break;
    pcs[i] = ebp[1];     // saved %eip
80104ce5:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104ce8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80104cef:	8b 45 0c             	mov    0xc(%ebp),%eax
80104cf2:	01 c2                	add    %eax,%edx
80104cf4:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104cf7:	8b 40 04             	mov    0x4(%eax),%eax
80104cfa:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
80104cfc:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104cff:	8b 00                	mov    (%eax),%eax
80104d01:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80104d04:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104d08:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104d0c:	7e c2                	jle    80104cd0 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104d0e:	eb 19                	jmp    80104d29 <getcallerpcs+0x71>
    pcs[i] = 0;
80104d10:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104d13:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80104d1a:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d1d:	01 d0                	add    %edx,%eax
80104d1f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104d25:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104d29:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104d2d:	7e e1                	jle    80104d10 <getcallerpcs+0x58>
    pcs[i] = 0;
}
80104d2f:	c9                   	leave  
80104d30:	c3                   	ret    

80104d31 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80104d31:	55                   	push   %ebp
80104d32:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80104d34:	8b 45 08             	mov    0x8(%ebp),%eax
80104d37:	8b 00                	mov    (%eax),%eax
80104d39:	85 c0                	test   %eax,%eax
80104d3b:	74 17                	je     80104d54 <holding+0x23>
80104d3d:	8b 45 08             	mov    0x8(%ebp),%eax
80104d40:	8b 50 08             	mov    0x8(%eax),%edx
80104d43:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104d49:	39 c2                	cmp    %eax,%edx
80104d4b:	75 07                	jne    80104d54 <holding+0x23>
80104d4d:	b8 01 00 00 00       	mov    $0x1,%eax
80104d52:	eb 05                	jmp    80104d59 <holding+0x28>
80104d54:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d59:	5d                   	pop    %ebp
80104d5a:	c3                   	ret    

80104d5b <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80104d5b:	55                   	push   %ebp
80104d5c:	89 e5                	mov    %esp,%ebp
80104d5e:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80104d61:	e8 3a fe ff ff       	call   80104ba0 <readeflags>
80104d66:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80104d69:	e8 47 fe ff ff       	call   80104bb5 <cli>
  if(cpu->ncli++ == 0)
80104d6e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104d74:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104d7a:	85 d2                	test   %edx,%edx
80104d7c:	0f 94 c1             	sete   %cl
80104d7f:	83 c2 01             	add    $0x1,%edx
80104d82:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104d88:	84 c9                	test   %cl,%cl
80104d8a:	74 15                	je     80104da1 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80104d8c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104d92:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104d95:	81 e2 00 02 00 00    	and    $0x200,%edx
80104d9b:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104da1:	c9                   	leave  
80104da2:	c3                   	ret    

80104da3 <popcli>:

void
popcli(void)
{
80104da3:	55                   	push   %ebp
80104da4:	89 e5                	mov    %esp,%ebp
80104da6:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80104da9:	e8 f2 fd ff ff       	call   80104ba0 <readeflags>
80104dae:	25 00 02 00 00       	and    $0x200,%eax
80104db3:	85 c0                	test   %eax,%eax
80104db5:	74 0c                	je     80104dc3 <popcli+0x20>
    panic("popcli - interruptible");
80104db7:	c7 04 24 e1 85 10 80 	movl   $0x801085e1,(%esp)
80104dbe:	e8 83 b7 ff ff       	call   80100546 <panic>
  if(--cpu->ncli < 0)
80104dc3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104dc9:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104dcf:	83 ea 01             	sub    $0x1,%edx
80104dd2:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104dd8:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104dde:	85 c0                	test   %eax,%eax
80104de0:	79 0c                	jns    80104dee <popcli+0x4b>
    panic("popcli");
80104de2:	c7 04 24 f8 85 10 80 	movl   $0x801085f8,(%esp)
80104de9:	e8 58 b7 ff ff       	call   80100546 <panic>
  if(cpu->ncli == 0 && cpu->intena)
80104dee:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104df4:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104dfa:	85 c0                	test   %eax,%eax
80104dfc:	75 15                	jne    80104e13 <popcli+0x70>
80104dfe:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e04:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104e0a:	85 c0                	test   %eax,%eax
80104e0c:	74 05                	je     80104e13 <popcli+0x70>
    sti();
80104e0e:	e8 a8 fd ff ff       	call   80104bbb <sti>
}
80104e13:	c9                   	leave  
80104e14:	c3                   	ret    
80104e15:	66 90                	xchg   %ax,%ax
80104e17:	90                   	nop

80104e18 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80104e18:	55                   	push   %ebp
80104e19:	89 e5                	mov    %esp,%ebp
80104e1b:	57                   	push   %edi
80104e1c:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80104e1d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e20:	8b 55 10             	mov    0x10(%ebp),%edx
80104e23:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e26:	89 cb                	mov    %ecx,%ebx
80104e28:	89 df                	mov    %ebx,%edi
80104e2a:	89 d1                	mov    %edx,%ecx
80104e2c:	fc                   	cld    
80104e2d:	f3 aa                	rep stos %al,%es:(%edi)
80104e2f:	89 ca                	mov    %ecx,%edx
80104e31:	89 fb                	mov    %edi,%ebx
80104e33:	89 5d 08             	mov    %ebx,0x8(%ebp)
80104e36:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80104e39:	5b                   	pop    %ebx
80104e3a:	5f                   	pop    %edi
80104e3b:	5d                   	pop    %ebp
80104e3c:	c3                   	ret    

80104e3d <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80104e3d:	55                   	push   %ebp
80104e3e:	89 e5                	mov    %esp,%ebp
80104e40:	57                   	push   %edi
80104e41:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80104e42:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e45:	8b 55 10             	mov    0x10(%ebp),%edx
80104e48:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e4b:	89 cb                	mov    %ecx,%ebx
80104e4d:	89 df                	mov    %ebx,%edi
80104e4f:	89 d1                	mov    %edx,%ecx
80104e51:	fc                   	cld    
80104e52:	f3 ab                	rep stos %eax,%es:(%edi)
80104e54:	89 ca                	mov    %ecx,%edx
80104e56:	89 fb                	mov    %edi,%ebx
80104e58:	89 5d 08             	mov    %ebx,0x8(%ebp)
80104e5b:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80104e5e:	5b                   	pop    %ebx
80104e5f:	5f                   	pop    %edi
80104e60:	5d                   	pop    %ebp
80104e61:	c3                   	ret    

80104e62 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80104e62:	55                   	push   %ebp
80104e63:	89 e5                	mov    %esp,%ebp
80104e65:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80104e68:	8b 45 08             	mov    0x8(%ebp),%eax
80104e6b:	83 e0 03             	and    $0x3,%eax
80104e6e:	85 c0                	test   %eax,%eax
80104e70:	75 49                	jne    80104ebb <memset+0x59>
80104e72:	8b 45 10             	mov    0x10(%ebp),%eax
80104e75:	83 e0 03             	and    $0x3,%eax
80104e78:	85 c0                	test   %eax,%eax
80104e7a:	75 3f                	jne    80104ebb <memset+0x59>
    c &= 0xFF;
80104e7c:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80104e83:	8b 45 10             	mov    0x10(%ebp),%eax
80104e86:	c1 e8 02             	shr    $0x2,%eax
80104e89:	89 c2                	mov    %eax,%edx
80104e8b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e8e:	89 c1                	mov    %eax,%ecx
80104e90:	c1 e1 18             	shl    $0x18,%ecx
80104e93:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e96:	c1 e0 10             	shl    $0x10,%eax
80104e99:	09 c1                	or     %eax,%ecx
80104e9b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e9e:	c1 e0 08             	shl    $0x8,%eax
80104ea1:	09 c8                	or     %ecx,%eax
80104ea3:	0b 45 0c             	or     0xc(%ebp),%eax
80104ea6:	89 54 24 08          	mov    %edx,0x8(%esp)
80104eaa:	89 44 24 04          	mov    %eax,0x4(%esp)
80104eae:	8b 45 08             	mov    0x8(%ebp),%eax
80104eb1:	89 04 24             	mov    %eax,(%esp)
80104eb4:	e8 84 ff ff ff       	call   80104e3d <stosl>
80104eb9:	eb 19                	jmp    80104ed4 <memset+0x72>
  } else
    stosb(dst, c, n);
80104ebb:	8b 45 10             	mov    0x10(%ebp),%eax
80104ebe:	89 44 24 08          	mov    %eax,0x8(%esp)
80104ec2:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ec5:	89 44 24 04          	mov    %eax,0x4(%esp)
80104ec9:	8b 45 08             	mov    0x8(%ebp),%eax
80104ecc:	89 04 24             	mov    %eax,(%esp)
80104ecf:	e8 44 ff ff ff       	call   80104e18 <stosb>
  return dst;
80104ed4:	8b 45 08             	mov    0x8(%ebp),%eax
}
80104ed7:	c9                   	leave  
80104ed8:	c3                   	ret    

80104ed9 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80104ed9:	55                   	push   %ebp
80104eda:	89 e5                	mov    %esp,%ebp
80104edc:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80104edf:	8b 45 08             	mov    0x8(%ebp),%eax
80104ee2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80104ee5:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ee8:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80104eeb:	eb 32                	jmp    80104f1f <memcmp+0x46>
    if(*s1 != *s2)
80104eed:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104ef0:	0f b6 10             	movzbl (%eax),%edx
80104ef3:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104ef6:	0f b6 00             	movzbl (%eax),%eax
80104ef9:	38 c2                	cmp    %al,%dl
80104efb:	74 1a                	je     80104f17 <memcmp+0x3e>
      return *s1 - *s2;
80104efd:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f00:	0f b6 00             	movzbl (%eax),%eax
80104f03:	0f b6 d0             	movzbl %al,%edx
80104f06:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104f09:	0f b6 00             	movzbl (%eax),%eax
80104f0c:	0f b6 c0             	movzbl %al,%eax
80104f0f:	89 d1                	mov    %edx,%ecx
80104f11:	29 c1                	sub    %eax,%ecx
80104f13:	89 c8                	mov    %ecx,%eax
80104f15:	eb 1c                	jmp    80104f33 <memcmp+0x5a>
    s1++, s2++;
80104f17:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104f1b:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80104f1f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104f23:	0f 95 c0             	setne  %al
80104f26:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104f2a:	84 c0                	test   %al,%al
80104f2c:	75 bf                	jne    80104eed <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80104f2e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104f33:	c9                   	leave  
80104f34:	c3                   	ret    

80104f35 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80104f35:	55                   	push   %ebp
80104f36:	89 e5                	mov    %esp,%ebp
80104f38:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80104f3b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f3e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80104f41:	8b 45 08             	mov    0x8(%ebp),%eax
80104f44:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80104f47:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f4a:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80104f4d:	73 54                	jae    80104fa3 <memmove+0x6e>
80104f4f:	8b 45 10             	mov    0x10(%ebp),%eax
80104f52:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104f55:	01 d0                	add    %edx,%eax
80104f57:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80104f5a:	76 47                	jbe    80104fa3 <memmove+0x6e>
    s += n;
80104f5c:	8b 45 10             	mov    0x10(%ebp),%eax
80104f5f:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80104f62:	8b 45 10             	mov    0x10(%ebp),%eax
80104f65:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80104f68:	eb 13                	jmp    80104f7d <memmove+0x48>
      *--d = *--s;
80104f6a:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80104f6e:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80104f72:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f75:	0f b6 10             	movzbl (%eax),%edx
80104f78:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104f7b:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80104f7d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104f81:	0f 95 c0             	setne  %al
80104f84:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104f88:	84 c0                	test   %al,%al
80104f8a:	75 de                	jne    80104f6a <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80104f8c:	eb 25                	jmp    80104fb3 <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80104f8e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f91:	0f b6 10             	movzbl (%eax),%edx
80104f94:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104f97:	88 10                	mov    %dl,(%eax)
80104f99:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104f9d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104fa1:	eb 01                	jmp    80104fa4 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80104fa3:	90                   	nop
80104fa4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104fa8:	0f 95 c0             	setne  %al
80104fab:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104faf:	84 c0                	test   %al,%al
80104fb1:	75 db                	jne    80104f8e <memmove+0x59>
      *d++ = *s++;

  return dst;
80104fb3:	8b 45 08             	mov    0x8(%ebp),%eax
}
80104fb6:	c9                   	leave  
80104fb7:	c3                   	ret    

80104fb8 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80104fb8:	55                   	push   %ebp
80104fb9:	89 e5                	mov    %esp,%ebp
80104fbb:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80104fbe:	8b 45 10             	mov    0x10(%ebp),%eax
80104fc1:	89 44 24 08          	mov    %eax,0x8(%esp)
80104fc5:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fc8:	89 44 24 04          	mov    %eax,0x4(%esp)
80104fcc:	8b 45 08             	mov    0x8(%ebp),%eax
80104fcf:	89 04 24             	mov    %eax,(%esp)
80104fd2:	e8 5e ff ff ff       	call   80104f35 <memmove>
}
80104fd7:	c9                   	leave  
80104fd8:	c3                   	ret    

80104fd9 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80104fd9:	55                   	push   %ebp
80104fda:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80104fdc:	eb 0c                	jmp    80104fea <strncmp+0x11>
    n--, p++, q++;
80104fde:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104fe2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80104fe6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80104fea:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104fee:	74 1a                	je     8010500a <strncmp+0x31>
80104ff0:	8b 45 08             	mov    0x8(%ebp),%eax
80104ff3:	0f b6 00             	movzbl (%eax),%eax
80104ff6:	84 c0                	test   %al,%al
80104ff8:	74 10                	je     8010500a <strncmp+0x31>
80104ffa:	8b 45 08             	mov    0x8(%ebp),%eax
80104ffd:	0f b6 10             	movzbl (%eax),%edx
80105000:	8b 45 0c             	mov    0xc(%ebp),%eax
80105003:	0f b6 00             	movzbl (%eax),%eax
80105006:	38 c2                	cmp    %al,%dl
80105008:	74 d4                	je     80104fde <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
8010500a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010500e:	75 07                	jne    80105017 <strncmp+0x3e>
    return 0;
80105010:	b8 00 00 00 00       	mov    $0x0,%eax
80105015:	eb 18                	jmp    8010502f <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
80105017:	8b 45 08             	mov    0x8(%ebp),%eax
8010501a:	0f b6 00             	movzbl (%eax),%eax
8010501d:	0f b6 d0             	movzbl %al,%edx
80105020:	8b 45 0c             	mov    0xc(%ebp),%eax
80105023:	0f b6 00             	movzbl (%eax),%eax
80105026:	0f b6 c0             	movzbl %al,%eax
80105029:	89 d1                	mov    %edx,%ecx
8010502b:	29 c1                	sub    %eax,%ecx
8010502d:	89 c8                	mov    %ecx,%eax
}
8010502f:	5d                   	pop    %ebp
80105030:	c3                   	ret    

80105031 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105031:	55                   	push   %ebp
80105032:	89 e5                	mov    %esp,%ebp
80105034:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105037:	8b 45 08             	mov    0x8(%ebp),%eax
8010503a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
8010503d:	90                   	nop
8010503e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105042:	0f 9f c0             	setg   %al
80105045:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105049:	84 c0                	test   %al,%al
8010504b:	74 30                	je     8010507d <strncpy+0x4c>
8010504d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105050:	0f b6 10             	movzbl (%eax),%edx
80105053:	8b 45 08             	mov    0x8(%ebp),%eax
80105056:	88 10                	mov    %dl,(%eax)
80105058:	8b 45 08             	mov    0x8(%ebp),%eax
8010505b:	0f b6 00             	movzbl (%eax),%eax
8010505e:	84 c0                	test   %al,%al
80105060:	0f 95 c0             	setne  %al
80105063:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105067:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
8010506b:	84 c0                	test   %al,%al
8010506d:	75 cf                	jne    8010503e <strncpy+0xd>
    ;
  while(n-- > 0)
8010506f:	eb 0c                	jmp    8010507d <strncpy+0x4c>
    *s++ = 0;
80105071:	8b 45 08             	mov    0x8(%ebp),%eax
80105074:	c6 00 00             	movb   $0x0,(%eax)
80105077:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010507b:	eb 01                	jmp    8010507e <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
8010507d:	90                   	nop
8010507e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105082:	0f 9f c0             	setg   %al
80105085:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105089:	84 c0                	test   %al,%al
8010508b:	75 e4                	jne    80105071 <strncpy+0x40>
    *s++ = 0;
  return os;
8010508d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105090:	c9                   	leave  
80105091:	c3                   	ret    

80105092 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105092:	55                   	push   %ebp
80105093:	89 e5                	mov    %esp,%ebp
80105095:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105098:	8b 45 08             	mov    0x8(%ebp),%eax
8010509b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
8010509e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801050a2:	7f 05                	jg     801050a9 <safestrcpy+0x17>
    return os;
801050a4:	8b 45 fc             	mov    -0x4(%ebp),%eax
801050a7:	eb 35                	jmp    801050de <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
801050a9:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801050ad:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801050b1:	7e 22                	jle    801050d5 <safestrcpy+0x43>
801050b3:	8b 45 0c             	mov    0xc(%ebp),%eax
801050b6:	0f b6 10             	movzbl (%eax),%edx
801050b9:	8b 45 08             	mov    0x8(%ebp),%eax
801050bc:	88 10                	mov    %dl,(%eax)
801050be:	8b 45 08             	mov    0x8(%ebp),%eax
801050c1:	0f b6 00             	movzbl (%eax),%eax
801050c4:	84 c0                	test   %al,%al
801050c6:	0f 95 c0             	setne  %al
801050c9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801050cd:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801050d1:	84 c0                	test   %al,%al
801050d3:	75 d4                	jne    801050a9 <safestrcpy+0x17>
    ;
  *s = 0;
801050d5:	8b 45 08             	mov    0x8(%ebp),%eax
801050d8:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801050db:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801050de:	c9                   	leave  
801050df:	c3                   	ret    

801050e0 <strlen>:

int
strlen(const char *s)
{
801050e0:	55                   	push   %ebp
801050e1:	89 e5                	mov    %esp,%ebp
801050e3:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
801050e6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801050ed:	eb 04                	jmp    801050f3 <strlen+0x13>
801050ef:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801050f3:	8b 55 fc             	mov    -0x4(%ebp),%edx
801050f6:	8b 45 08             	mov    0x8(%ebp),%eax
801050f9:	01 d0                	add    %edx,%eax
801050fb:	0f b6 00             	movzbl (%eax),%eax
801050fe:	84 c0                	test   %al,%al
80105100:	75 ed                	jne    801050ef <strlen+0xf>
    ;
  return n;
80105102:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105105:	c9                   	leave  
80105106:	c3                   	ret    
80105107:	90                   	nop

80105108 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105108:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
8010510c:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105110:	55                   	push   %ebp
  pushl %ebx
80105111:	53                   	push   %ebx
  pushl %esi
80105112:	56                   	push   %esi
  pushl %edi
80105113:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105114:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105116:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105118:	5f                   	pop    %edi
  popl %esi
80105119:	5e                   	pop    %esi
  popl %ebx
8010511a:	5b                   	pop    %ebx
  popl %ebp
8010511b:	5d                   	pop    %ebp
  ret
8010511c:	c3                   	ret    
8010511d:	66 90                	xchg   %ax,%ax
8010511f:	90                   	nop

80105120 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
80105120:	55                   	push   %ebp
80105121:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
80105123:	8b 45 08             	mov    0x8(%ebp),%eax
80105126:	8b 00                	mov    (%eax),%eax
80105128:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010512b:	76 0f                	jbe    8010513c <fetchint+0x1c>
8010512d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105130:	8d 50 04             	lea    0x4(%eax),%edx
80105133:	8b 45 08             	mov    0x8(%ebp),%eax
80105136:	8b 00                	mov    (%eax),%eax
80105138:	39 c2                	cmp    %eax,%edx
8010513a:	76 07                	jbe    80105143 <fetchint+0x23>
    return -1;
8010513c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105141:	eb 0f                	jmp    80105152 <fetchint+0x32>
  *ip = *(int*)(addr);
80105143:	8b 45 0c             	mov    0xc(%ebp),%eax
80105146:	8b 10                	mov    (%eax),%edx
80105148:	8b 45 10             	mov    0x10(%ebp),%eax
8010514b:	89 10                	mov    %edx,(%eax)
  return 0;
8010514d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105152:	5d                   	pop    %ebp
80105153:	c3                   	ret    

80105154 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
80105154:	55                   	push   %ebp
80105155:	89 e5                	mov    %esp,%ebp
80105157:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
8010515a:	8b 45 08             	mov    0x8(%ebp),%eax
8010515d:	8b 00                	mov    (%eax),%eax
8010515f:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105162:	77 07                	ja     8010516b <fetchstr+0x17>
    return -1;
80105164:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105169:	eb 45                	jmp    801051b0 <fetchstr+0x5c>
  *pp = (char*)addr;
8010516b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010516e:	8b 45 10             	mov    0x10(%ebp),%eax
80105171:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
80105173:	8b 45 08             	mov    0x8(%ebp),%eax
80105176:	8b 00                	mov    (%eax),%eax
80105178:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
8010517b:	8b 45 10             	mov    0x10(%ebp),%eax
8010517e:	8b 00                	mov    (%eax),%eax
80105180:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105183:	eb 1e                	jmp    801051a3 <fetchstr+0x4f>
    if(*s == 0)
80105185:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105188:	0f b6 00             	movzbl (%eax),%eax
8010518b:	84 c0                	test   %al,%al
8010518d:	75 10                	jne    8010519f <fetchstr+0x4b>
      return s - *pp;
8010518f:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105192:	8b 45 10             	mov    0x10(%ebp),%eax
80105195:	8b 00                	mov    (%eax),%eax
80105197:	89 d1                	mov    %edx,%ecx
80105199:	29 c1                	sub    %eax,%ecx
8010519b:	89 c8                	mov    %ecx,%eax
8010519d:	eb 11                	jmp    801051b0 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
8010519f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801051a3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051a6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801051a9:	72 da                	jb     80105185 <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
801051ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801051b0:	c9                   	leave  
801051b1:	c3                   	ret    

801051b2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801051b2:	55                   	push   %ebp
801051b3:	89 e5                	mov    %esp,%ebp
801051b5:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
801051b8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051be:	8b 40 18             	mov    0x18(%eax),%eax
801051c1:	8b 50 44             	mov    0x44(%eax),%edx
801051c4:	8b 45 08             	mov    0x8(%ebp),%eax
801051c7:	c1 e0 02             	shl    $0x2,%eax
801051ca:	01 d0                	add    %edx,%eax
801051cc:	8d 48 04             	lea    0x4(%eax),%ecx
801051cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051d5:	8b 55 0c             	mov    0xc(%ebp),%edx
801051d8:	89 54 24 08          	mov    %edx,0x8(%esp)
801051dc:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801051e0:	89 04 24             	mov    %eax,(%esp)
801051e3:	e8 38 ff ff ff       	call   80105120 <fetchint>
}
801051e8:	c9                   	leave  
801051e9:	c3                   	ret    

801051ea <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801051ea:	55                   	push   %ebp
801051eb:	89 e5                	mov    %esp,%ebp
801051ed:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
801051f0:	8d 45 fc             	lea    -0x4(%ebp),%eax
801051f3:	89 44 24 04          	mov    %eax,0x4(%esp)
801051f7:	8b 45 08             	mov    0x8(%ebp),%eax
801051fa:	89 04 24             	mov    %eax,(%esp)
801051fd:	e8 b0 ff ff ff       	call   801051b2 <argint>
80105202:	85 c0                	test   %eax,%eax
80105204:	79 07                	jns    8010520d <argptr+0x23>
    return -1;
80105206:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010520b:	eb 3d                	jmp    8010524a <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
8010520d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105210:	89 c2                	mov    %eax,%edx
80105212:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105218:	8b 00                	mov    (%eax),%eax
8010521a:	39 c2                	cmp    %eax,%edx
8010521c:	73 16                	jae    80105234 <argptr+0x4a>
8010521e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105221:	89 c2                	mov    %eax,%edx
80105223:	8b 45 10             	mov    0x10(%ebp),%eax
80105226:	01 c2                	add    %eax,%edx
80105228:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010522e:	8b 00                	mov    (%eax),%eax
80105230:	39 c2                	cmp    %eax,%edx
80105232:	76 07                	jbe    8010523b <argptr+0x51>
    return -1;
80105234:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105239:	eb 0f                	jmp    8010524a <argptr+0x60>
  *pp = (char*)i;
8010523b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010523e:	89 c2                	mov    %eax,%edx
80105240:	8b 45 0c             	mov    0xc(%ebp),%eax
80105243:	89 10                	mov    %edx,(%eax)
  return 0;
80105245:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010524a:	c9                   	leave  
8010524b:	c3                   	ret    

8010524c <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
8010524c:	55                   	push   %ebp
8010524d:	89 e5                	mov    %esp,%ebp
8010524f:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105252:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105255:	89 44 24 04          	mov    %eax,0x4(%esp)
80105259:	8b 45 08             	mov    0x8(%ebp),%eax
8010525c:	89 04 24             	mov    %eax,(%esp)
8010525f:	e8 4e ff ff ff       	call   801051b2 <argint>
80105264:	85 c0                	test   %eax,%eax
80105266:	79 07                	jns    8010526f <argstr+0x23>
    return -1;
80105268:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010526d:	eb 1e                	jmp    8010528d <argstr+0x41>
  return fetchstr(proc, addr, pp);
8010526f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105272:	89 c2                	mov    %eax,%edx
80105274:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010527a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010527d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105281:	89 54 24 04          	mov    %edx,0x4(%esp)
80105285:	89 04 24             	mov    %eax,(%esp)
80105288:	e8 c7 fe ff ff       	call   80105154 <fetchstr>
}
8010528d:	c9                   	leave  
8010528e:	c3                   	ret    

8010528f <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
8010528f:	55                   	push   %ebp
80105290:	89 e5                	mov    %esp,%ebp
80105292:	53                   	push   %ebx
80105293:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105296:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010529c:	8b 40 18             	mov    0x18(%eax),%eax
8010529f:	8b 40 1c             	mov    0x1c(%eax),%eax
801052a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
801052a5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801052a9:	78 2e                	js     801052d9 <syscall+0x4a>
801052ab:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801052af:	7f 28                	jg     801052d9 <syscall+0x4a>
801052b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052b4:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801052bb:	85 c0                	test   %eax,%eax
801052bd:	74 1a                	je     801052d9 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
801052bf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052c5:	8b 58 18             	mov    0x18(%eax),%ebx
801052c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052cb:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801052d2:	ff d0                	call   *%eax
801052d4:	89 43 1c             	mov    %eax,0x1c(%ebx)
801052d7:	eb 73                	jmp    8010534c <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
801052d9:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801052dd:	7e 30                	jle    8010530f <syscall+0x80>
801052df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052e2:	83 f8 15             	cmp    $0x15,%eax
801052e5:	77 28                	ja     8010530f <syscall+0x80>
801052e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052ea:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801052f1:	85 c0                	test   %eax,%eax
801052f3:	74 1a                	je     8010530f <syscall+0x80>
    proc->tf->eax = syscalls[num]();
801052f5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052fb:	8b 58 18             	mov    0x18(%eax),%ebx
801052fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105301:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105308:	ff d0                	call   *%eax
8010530a:	89 43 1c             	mov    %eax,0x1c(%ebx)
8010530d:	eb 3d                	jmp    8010534c <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
8010530f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105315:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105318:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
8010531e:	8b 40 10             	mov    0x10(%eax),%eax
80105321:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105324:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105328:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010532c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105330:	c7 04 24 ff 85 10 80 	movl   $0x801085ff,(%esp)
80105337:	e8 6e b0 ff ff       	call   801003aa <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
8010533c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105342:	8b 40 18             	mov    0x18(%eax),%eax
80105345:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
8010534c:	83 c4 24             	add    $0x24,%esp
8010534f:	5b                   	pop    %ebx
80105350:	5d                   	pop    %ebp
80105351:	c3                   	ret    
80105352:	66 90                	xchg   %ax,%ax

80105354 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105354:	55                   	push   %ebp
80105355:	89 e5                	mov    %esp,%ebp
80105357:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010535a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010535d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105361:	8b 45 08             	mov    0x8(%ebp),%eax
80105364:	89 04 24             	mov    %eax,(%esp)
80105367:	e8 46 fe ff ff       	call   801051b2 <argint>
8010536c:	85 c0                	test   %eax,%eax
8010536e:	79 07                	jns    80105377 <argfd+0x23>
    return -1;
80105370:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105375:	eb 50                	jmp    801053c7 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105377:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010537a:	85 c0                	test   %eax,%eax
8010537c:	78 21                	js     8010539f <argfd+0x4b>
8010537e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105381:	83 f8 0f             	cmp    $0xf,%eax
80105384:	7f 19                	jg     8010539f <argfd+0x4b>
80105386:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010538c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010538f:	83 c2 08             	add    $0x8,%edx
80105392:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105396:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105399:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010539d:	75 07                	jne    801053a6 <argfd+0x52>
    return -1;
8010539f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801053a4:	eb 21                	jmp    801053c7 <argfd+0x73>
  if(pfd)
801053a6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801053aa:	74 08                	je     801053b4 <argfd+0x60>
    *pfd = fd;
801053ac:	8b 55 f0             	mov    -0x10(%ebp),%edx
801053af:	8b 45 0c             	mov    0xc(%ebp),%eax
801053b2:	89 10                	mov    %edx,(%eax)
  if(pf)
801053b4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801053b8:	74 08                	je     801053c2 <argfd+0x6e>
    *pf = f;
801053ba:	8b 45 10             	mov    0x10(%ebp),%eax
801053bd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801053c0:	89 10                	mov    %edx,(%eax)
  return 0;
801053c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801053c7:	c9                   	leave  
801053c8:	c3                   	ret    

801053c9 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801053c9:	55                   	push   %ebp
801053ca:	89 e5                	mov    %esp,%ebp
801053cc:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801053cf:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801053d6:	eb 30                	jmp    80105408 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
801053d8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053de:	8b 55 fc             	mov    -0x4(%ebp),%edx
801053e1:	83 c2 08             	add    $0x8,%edx
801053e4:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801053e8:	85 c0                	test   %eax,%eax
801053ea:	75 18                	jne    80105404 <fdalloc+0x3b>
      proc->ofile[fd] = f;
801053ec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053f2:	8b 55 fc             	mov    -0x4(%ebp),%edx
801053f5:	8d 4a 08             	lea    0x8(%edx),%ecx
801053f8:	8b 55 08             	mov    0x8(%ebp),%edx
801053fb:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
801053ff:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105402:	eb 0f                	jmp    80105413 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105404:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105408:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
8010540c:	7e ca                	jle    801053d8 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
8010540e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105413:	c9                   	leave  
80105414:	c3                   	ret    

80105415 <sys_dup>:

int
sys_dup(void)
{
80105415:	55                   	push   %ebp
80105416:	89 e5                	mov    %esp,%ebp
80105418:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
8010541b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010541e:	89 44 24 08          	mov    %eax,0x8(%esp)
80105422:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105429:	00 
8010542a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105431:	e8 1e ff ff ff       	call   80105354 <argfd>
80105436:	85 c0                	test   %eax,%eax
80105438:	79 07                	jns    80105441 <sys_dup+0x2c>
    return -1;
8010543a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010543f:	eb 29                	jmp    8010546a <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105441:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105444:	89 04 24             	mov    %eax,(%esp)
80105447:	e8 7d ff ff ff       	call   801053c9 <fdalloc>
8010544c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010544f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105453:	79 07                	jns    8010545c <sys_dup+0x47>
    return -1;
80105455:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010545a:	eb 0e                	jmp    8010546a <sys_dup+0x55>
  filedup(f);
8010545c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010545f:	89 04 24             	mov    %eax,(%esp)
80105462:	e8 3d bb ff ff       	call   80100fa4 <filedup>
  return fd;
80105467:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010546a:	c9                   	leave  
8010546b:	c3                   	ret    

8010546c <sys_read>:

int
sys_read(void)
{
8010546c:	55                   	push   %ebp
8010546d:	89 e5                	mov    %esp,%ebp
8010546f:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105472:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105475:	89 44 24 08          	mov    %eax,0x8(%esp)
80105479:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105480:	00 
80105481:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105488:	e8 c7 fe ff ff       	call   80105354 <argfd>
8010548d:	85 c0                	test   %eax,%eax
8010548f:	78 35                	js     801054c6 <sys_read+0x5a>
80105491:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105494:	89 44 24 04          	mov    %eax,0x4(%esp)
80105498:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010549f:	e8 0e fd ff ff       	call   801051b2 <argint>
801054a4:	85 c0                	test   %eax,%eax
801054a6:	78 1e                	js     801054c6 <sys_read+0x5a>
801054a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054ab:	89 44 24 08          	mov    %eax,0x8(%esp)
801054af:	8d 45 ec             	lea    -0x14(%ebp),%eax
801054b2:	89 44 24 04          	mov    %eax,0x4(%esp)
801054b6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801054bd:	e8 28 fd ff ff       	call   801051ea <argptr>
801054c2:	85 c0                	test   %eax,%eax
801054c4:	79 07                	jns    801054cd <sys_read+0x61>
    return -1;
801054c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054cb:	eb 19                	jmp    801054e6 <sys_read+0x7a>
  return fileread(f, p, n);
801054cd:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801054d0:	8b 55 ec             	mov    -0x14(%ebp),%edx
801054d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054d6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801054da:	89 54 24 04          	mov    %edx,0x4(%esp)
801054de:	89 04 24             	mov    %eax,(%esp)
801054e1:	e8 2b bc ff ff       	call   80101111 <fileread>
}
801054e6:	c9                   	leave  
801054e7:	c3                   	ret    

801054e8 <sys_write>:

int
sys_write(void)
{
801054e8:	55                   	push   %ebp
801054e9:	89 e5                	mov    %esp,%ebp
801054eb:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801054ee:	8d 45 f4             	lea    -0xc(%ebp),%eax
801054f1:	89 44 24 08          	mov    %eax,0x8(%esp)
801054f5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801054fc:	00 
801054fd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105504:	e8 4b fe ff ff       	call   80105354 <argfd>
80105509:	85 c0                	test   %eax,%eax
8010550b:	78 35                	js     80105542 <sys_write+0x5a>
8010550d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105510:	89 44 24 04          	mov    %eax,0x4(%esp)
80105514:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010551b:	e8 92 fc ff ff       	call   801051b2 <argint>
80105520:	85 c0                	test   %eax,%eax
80105522:	78 1e                	js     80105542 <sys_write+0x5a>
80105524:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105527:	89 44 24 08          	mov    %eax,0x8(%esp)
8010552b:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010552e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105532:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105539:	e8 ac fc ff ff       	call   801051ea <argptr>
8010553e:	85 c0                	test   %eax,%eax
80105540:	79 07                	jns    80105549 <sys_write+0x61>
    return -1;
80105542:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105547:	eb 19                	jmp    80105562 <sys_write+0x7a>
  return filewrite(f, p, n);
80105549:	8b 4d f0             	mov    -0x10(%ebp),%ecx
8010554c:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010554f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105552:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105556:	89 54 24 04          	mov    %edx,0x4(%esp)
8010555a:	89 04 24             	mov    %eax,(%esp)
8010555d:	e8 6b bc ff ff       	call   801011cd <filewrite>
}
80105562:	c9                   	leave  
80105563:	c3                   	ret    

80105564 <sys_close>:

int
sys_close(void)
{
80105564:	55                   	push   %ebp
80105565:	89 e5                	mov    %esp,%ebp
80105567:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
8010556a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010556d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105571:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105574:	89 44 24 04          	mov    %eax,0x4(%esp)
80105578:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010557f:	e8 d0 fd ff ff       	call   80105354 <argfd>
80105584:	85 c0                	test   %eax,%eax
80105586:	79 07                	jns    8010558f <sys_close+0x2b>
    return -1;
80105588:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010558d:	eb 24                	jmp    801055b3 <sys_close+0x4f>
  proc->ofile[fd] = 0;
8010558f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105595:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105598:	83 c2 08             	add    $0x8,%edx
8010559b:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801055a2:	00 
  fileclose(f);
801055a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055a6:	89 04 24             	mov    %eax,(%esp)
801055a9:	e8 3e ba ff ff       	call   80100fec <fileclose>
  return 0;
801055ae:	b8 00 00 00 00       	mov    $0x0,%eax
}
801055b3:	c9                   	leave  
801055b4:	c3                   	ret    

801055b5 <sys_fstat>:

int
sys_fstat(void)
{
801055b5:	55                   	push   %ebp
801055b6:	89 e5                	mov    %esp,%ebp
801055b8:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801055bb:	8d 45 f4             	lea    -0xc(%ebp),%eax
801055be:	89 44 24 08          	mov    %eax,0x8(%esp)
801055c2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801055c9:	00 
801055ca:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801055d1:	e8 7e fd ff ff       	call   80105354 <argfd>
801055d6:	85 c0                	test   %eax,%eax
801055d8:	78 1f                	js     801055f9 <sys_fstat+0x44>
801055da:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801055e1:	00 
801055e2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801055e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801055e9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801055f0:	e8 f5 fb ff ff       	call   801051ea <argptr>
801055f5:	85 c0                	test   %eax,%eax
801055f7:	79 07                	jns    80105600 <sys_fstat+0x4b>
    return -1;
801055f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055fe:	eb 12                	jmp    80105612 <sys_fstat+0x5d>
  return filestat(f, st);
80105600:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105603:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105606:	89 54 24 04          	mov    %edx,0x4(%esp)
8010560a:	89 04 24             	mov    %eax,(%esp)
8010560d:	e8 b0 ba ff ff       	call   801010c2 <filestat>
}
80105612:	c9                   	leave  
80105613:	c3                   	ret    

80105614 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80105614:	55                   	push   %ebp
80105615:	89 e5                	mov    %esp,%ebp
80105617:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
8010561a:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010561d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105621:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105628:	e8 1f fc ff ff       	call   8010524c <argstr>
8010562d:	85 c0                	test   %eax,%eax
8010562f:	78 17                	js     80105648 <sys_link+0x34>
80105631:	8d 45 dc             	lea    -0x24(%ebp),%eax
80105634:	89 44 24 04          	mov    %eax,0x4(%esp)
80105638:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010563f:	e8 08 fc ff ff       	call   8010524c <argstr>
80105644:	85 c0                	test   %eax,%eax
80105646:	79 0a                	jns    80105652 <sys_link+0x3e>
    return -1;
80105648:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010564d:	e9 3c 01 00 00       	jmp    8010578e <sys_link+0x17a>
  if((ip = namei(old)) == 0)
80105652:	8b 45 d8             	mov    -0x28(%ebp),%eax
80105655:	89 04 24             	mov    %eax,(%esp)
80105658:	e8 f8 cd ff ff       	call   80102455 <namei>
8010565d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105660:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105664:	75 0a                	jne    80105670 <sys_link+0x5c>
    return -1;
80105666:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010566b:	e9 1e 01 00 00       	jmp    8010578e <sys_link+0x17a>

  begin_trans();
80105670:	e8 fb db ff ff       	call   80103270 <begin_trans>

  ilock(ip);
80105675:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105678:	89 04 24             	mov    %eax,(%esp)
8010567b:	e8 14 c2 ff ff       	call   80101894 <ilock>
  if(ip->type == T_DIR){
80105680:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105683:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105687:	66 83 f8 01          	cmp    $0x1,%ax
8010568b:	75 1a                	jne    801056a7 <sys_link+0x93>
    iunlockput(ip);
8010568d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105690:	89 04 24             	mov    %eax,(%esp)
80105693:	e8 80 c4 ff ff       	call   80101b18 <iunlockput>
    commit_trans();
80105698:	e8 1c dc ff ff       	call   801032b9 <commit_trans>
    return -1;
8010569d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056a2:	e9 e7 00 00 00       	jmp    8010578e <sys_link+0x17a>
  }

  ip->nlink++;
801056a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056aa:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801056ae:	8d 50 01             	lea    0x1(%eax),%edx
801056b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056b4:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801056b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056bb:	89 04 24             	mov    %eax,(%esp)
801056be:	e8 15 c0 ff ff       	call   801016d8 <iupdate>
  iunlock(ip);
801056c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056c6:	89 04 24             	mov    %eax,(%esp)
801056c9:	e8 14 c3 ff ff       	call   801019e2 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
801056ce:	8b 45 dc             	mov    -0x24(%ebp),%eax
801056d1:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801056d4:	89 54 24 04          	mov    %edx,0x4(%esp)
801056d8:	89 04 24             	mov    %eax,(%esp)
801056db:	e8 97 cd ff ff       	call   80102477 <nameiparent>
801056e0:	89 45 f0             	mov    %eax,-0x10(%ebp)
801056e3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801056e7:	74 68                	je     80105751 <sys_link+0x13d>
    goto bad;
  ilock(dp);
801056e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056ec:	89 04 24             	mov    %eax,(%esp)
801056ef:	e8 a0 c1 ff ff       	call   80101894 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801056f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056f7:	8b 10                	mov    (%eax),%edx
801056f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056fc:	8b 00                	mov    (%eax),%eax
801056fe:	39 c2                	cmp    %eax,%edx
80105700:	75 20                	jne    80105722 <sys_link+0x10e>
80105702:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105705:	8b 40 04             	mov    0x4(%eax),%eax
80105708:	89 44 24 08          	mov    %eax,0x8(%esp)
8010570c:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010570f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105713:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105716:	89 04 24             	mov    %eax,(%esp)
80105719:	e8 74 ca ff ff       	call   80102192 <dirlink>
8010571e:	85 c0                	test   %eax,%eax
80105720:	79 0d                	jns    8010572f <sys_link+0x11b>
    iunlockput(dp);
80105722:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105725:	89 04 24             	mov    %eax,(%esp)
80105728:	e8 eb c3 ff ff       	call   80101b18 <iunlockput>
    goto bad;
8010572d:	eb 23                	jmp    80105752 <sys_link+0x13e>
  }
  iunlockput(dp);
8010572f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105732:	89 04 24             	mov    %eax,(%esp)
80105735:	e8 de c3 ff ff       	call   80101b18 <iunlockput>
  iput(ip);
8010573a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010573d:	89 04 24             	mov    %eax,(%esp)
80105740:	e8 02 c3 ff ff       	call   80101a47 <iput>

  commit_trans();
80105745:	e8 6f db ff ff       	call   801032b9 <commit_trans>

  return 0;
8010574a:	b8 00 00 00 00       	mov    $0x0,%eax
8010574f:	eb 3d                	jmp    8010578e <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80105751:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
80105752:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105755:	89 04 24             	mov    %eax,(%esp)
80105758:	e8 37 c1 ff ff       	call   80101894 <ilock>
  ip->nlink--;
8010575d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105760:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105764:	8d 50 ff             	lea    -0x1(%eax),%edx
80105767:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010576a:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010576e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105771:	89 04 24             	mov    %eax,(%esp)
80105774:	e8 5f bf ff ff       	call   801016d8 <iupdate>
  iunlockput(ip);
80105779:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010577c:	89 04 24             	mov    %eax,(%esp)
8010577f:	e8 94 c3 ff ff       	call   80101b18 <iunlockput>
  commit_trans();
80105784:	e8 30 db ff ff       	call   801032b9 <commit_trans>
  return -1;
80105789:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010578e:	c9                   	leave  
8010578f:	c3                   	ret    

80105790 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105790:	55                   	push   %ebp
80105791:	89 e5                	mov    %esp,%ebp
80105793:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105796:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
8010579d:	eb 4b                	jmp    801057ea <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010579f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057a2:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801057a9:	00 
801057aa:	89 44 24 08          	mov    %eax,0x8(%esp)
801057ae:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801057b1:	89 44 24 04          	mov    %eax,0x4(%esp)
801057b5:	8b 45 08             	mov    0x8(%ebp),%eax
801057b8:	89 04 24             	mov    %eax,(%esp)
801057bb:	e8 e1 c5 ff ff       	call   80101da1 <readi>
801057c0:	83 f8 10             	cmp    $0x10,%eax
801057c3:	74 0c                	je     801057d1 <isdirempty+0x41>
      panic("isdirempty: readi");
801057c5:	c7 04 24 1b 86 10 80 	movl   $0x8010861b,(%esp)
801057cc:	e8 75 ad ff ff       	call   80100546 <panic>
    if(de.inum != 0)
801057d1:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
801057d5:	66 85 c0             	test   %ax,%ax
801057d8:	74 07                	je     801057e1 <isdirempty+0x51>
      return 0;
801057da:	b8 00 00 00 00       	mov    $0x0,%eax
801057df:	eb 1b                	jmp    801057fc <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801057e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057e4:	83 c0 10             	add    $0x10,%eax
801057e7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801057ea:	8b 55 f4             	mov    -0xc(%ebp),%edx
801057ed:	8b 45 08             	mov    0x8(%ebp),%eax
801057f0:	8b 40 18             	mov    0x18(%eax),%eax
801057f3:	39 c2                	cmp    %eax,%edx
801057f5:	72 a8                	jb     8010579f <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
801057f7:	b8 01 00 00 00       	mov    $0x1,%eax
}
801057fc:	c9                   	leave  
801057fd:	c3                   	ret    

801057fe <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
801057fe:	55                   	push   %ebp
801057ff:	89 e5                	mov    %esp,%ebp
80105801:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105804:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105807:	89 44 24 04          	mov    %eax,0x4(%esp)
8010580b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105812:	e8 35 fa ff ff       	call   8010524c <argstr>
80105817:	85 c0                	test   %eax,%eax
80105819:	79 0a                	jns    80105825 <sys_unlink+0x27>
    return -1;
8010581b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105820:	e9 aa 01 00 00       	jmp    801059cf <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80105825:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105828:	8d 55 d2             	lea    -0x2e(%ebp),%edx
8010582b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010582f:	89 04 24             	mov    %eax,(%esp)
80105832:	e8 40 cc ff ff       	call   80102477 <nameiparent>
80105837:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010583a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010583e:	75 0a                	jne    8010584a <sys_unlink+0x4c>
    return -1;
80105840:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105845:	e9 85 01 00 00       	jmp    801059cf <sys_unlink+0x1d1>

  begin_trans();
8010584a:	e8 21 da ff ff       	call   80103270 <begin_trans>

  ilock(dp);
8010584f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105852:	89 04 24             	mov    %eax,(%esp)
80105855:	e8 3a c0 ff ff       	call   80101894 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
8010585a:	c7 44 24 04 2d 86 10 	movl   $0x8010862d,0x4(%esp)
80105861:	80 
80105862:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105865:	89 04 24             	mov    %eax,(%esp)
80105868:	e8 3b c8 ff ff       	call   801020a8 <namecmp>
8010586d:	85 c0                	test   %eax,%eax
8010586f:	0f 84 45 01 00 00    	je     801059ba <sys_unlink+0x1bc>
80105875:	c7 44 24 04 2f 86 10 	movl   $0x8010862f,0x4(%esp)
8010587c:	80 
8010587d:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105880:	89 04 24             	mov    %eax,(%esp)
80105883:	e8 20 c8 ff ff       	call   801020a8 <namecmp>
80105888:	85 c0                	test   %eax,%eax
8010588a:	0f 84 2a 01 00 00    	je     801059ba <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105890:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105893:	89 44 24 08          	mov    %eax,0x8(%esp)
80105897:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010589a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010589e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058a1:	89 04 24             	mov    %eax,(%esp)
801058a4:	e8 21 c8 ff ff       	call   801020ca <dirlookup>
801058a9:	89 45 f0             	mov    %eax,-0x10(%ebp)
801058ac:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801058b0:	0f 84 03 01 00 00    	je     801059b9 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
801058b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058b9:	89 04 24             	mov    %eax,(%esp)
801058bc:	e8 d3 bf ff ff       	call   80101894 <ilock>

  if(ip->nlink < 1)
801058c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058c4:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801058c8:	66 85 c0             	test   %ax,%ax
801058cb:	7f 0c                	jg     801058d9 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
801058cd:	c7 04 24 32 86 10 80 	movl   $0x80108632,(%esp)
801058d4:	e8 6d ac ff ff       	call   80100546 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801058d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058dc:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801058e0:	66 83 f8 01          	cmp    $0x1,%ax
801058e4:	75 1f                	jne    80105905 <sys_unlink+0x107>
801058e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058e9:	89 04 24             	mov    %eax,(%esp)
801058ec:	e8 9f fe ff ff       	call   80105790 <isdirempty>
801058f1:	85 c0                	test   %eax,%eax
801058f3:	75 10                	jne    80105905 <sys_unlink+0x107>
    iunlockput(ip);
801058f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058f8:	89 04 24             	mov    %eax,(%esp)
801058fb:	e8 18 c2 ff ff       	call   80101b18 <iunlockput>
    goto bad;
80105900:	e9 b5 00 00 00       	jmp    801059ba <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80105905:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010590c:	00 
8010590d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105914:	00 
80105915:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105918:	89 04 24             	mov    %eax,(%esp)
8010591b:	e8 42 f5 ff ff       	call   80104e62 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105920:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105923:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010592a:	00 
8010592b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010592f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105932:	89 44 24 04          	mov    %eax,0x4(%esp)
80105936:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105939:	89 04 24             	mov    %eax,(%esp)
8010593c:	e8 ce c5 ff ff       	call   80101f0f <writei>
80105941:	83 f8 10             	cmp    $0x10,%eax
80105944:	74 0c                	je     80105952 <sys_unlink+0x154>
    panic("unlink: writei");
80105946:	c7 04 24 44 86 10 80 	movl   $0x80108644,(%esp)
8010594d:	e8 f4 ab ff ff       	call   80100546 <panic>
  if(ip->type == T_DIR){
80105952:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105955:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105959:	66 83 f8 01          	cmp    $0x1,%ax
8010595d:	75 1c                	jne    8010597b <sys_unlink+0x17d>
    dp->nlink--;
8010595f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105962:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105966:	8d 50 ff             	lea    -0x1(%eax),%edx
80105969:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010596c:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105970:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105973:	89 04 24             	mov    %eax,(%esp)
80105976:	e8 5d bd ff ff       	call   801016d8 <iupdate>
  }
  iunlockput(dp);
8010597b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010597e:	89 04 24             	mov    %eax,(%esp)
80105981:	e8 92 c1 ff ff       	call   80101b18 <iunlockput>

  ip->nlink--;
80105986:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105989:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010598d:	8d 50 ff             	lea    -0x1(%eax),%edx
80105990:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105993:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105997:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010599a:	89 04 24             	mov    %eax,(%esp)
8010599d:	e8 36 bd ff ff       	call   801016d8 <iupdate>
  iunlockput(ip);
801059a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059a5:	89 04 24             	mov    %eax,(%esp)
801059a8:	e8 6b c1 ff ff       	call   80101b18 <iunlockput>

  commit_trans();
801059ad:	e8 07 d9 ff ff       	call   801032b9 <commit_trans>

  return 0;
801059b2:	b8 00 00 00 00       	mov    $0x0,%eax
801059b7:	eb 16                	jmp    801059cf <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
801059b9:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
801059ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059bd:	89 04 24             	mov    %eax,(%esp)
801059c0:	e8 53 c1 ff ff       	call   80101b18 <iunlockput>
  commit_trans();
801059c5:	e8 ef d8 ff ff       	call   801032b9 <commit_trans>
  return -1;
801059ca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801059cf:	c9                   	leave  
801059d0:	c3                   	ret    

801059d1 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
801059d1:	55                   	push   %ebp
801059d2:	89 e5                	mov    %esp,%ebp
801059d4:	83 ec 48             	sub    $0x48,%esp
801059d7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801059da:	8b 55 10             	mov    0x10(%ebp),%edx
801059dd:	8b 45 14             	mov    0x14(%ebp),%eax
801059e0:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
801059e4:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
801059e8:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801059ec:	8d 45 de             	lea    -0x22(%ebp),%eax
801059ef:	89 44 24 04          	mov    %eax,0x4(%esp)
801059f3:	8b 45 08             	mov    0x8(%ebp),%eax
801059f6:	89 04 24             	mov    %eax,(%esp)
801059f9:	e8 79 ca ff ff       	call   80102477 <nameiparent>
801059fe:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105a01:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105a05:	75 0a                	jne    80105a11 <create+0x40>
    return 0;
80105a07:	b8 00 00 00 00       	mov    $0x0,%eax
80105a0c:	e9 7e 01 00 00       	jmp    80105b8f <create+0x1be>
  ilock(dp);
80105a11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a14:	89 04 24             	mov    %eax,(%esp)
80105a17:	e8 78 be ff ff       	call   80101894 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80105a1c:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105a1f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a23:	8d 45 de             	lea    -0x22(%ebp),%eax
80105a26:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a2d:	89 04 24             	mov    %eax,(%esp)
80105a30:	e8 95 c6 ff ff       	call   801020ca <dirlookup>
80105a35:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105a38:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105a3c:	74 47                	je     80105a85 <create+0xb4>
    iunlockput(dp);
80105a3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a41:	89 04 24             	mov    %eax,(%esp)
80105a44:	e8 cf c0 ff ff       	call   80101b18 <iunlockput>
    ilock(ip);
80105a49:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a4c:	89 04 24             	mov    %eax,(%esp)
80105a4f:	e8 40 be ff ff       	call   80101894 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105a54:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105a59:	75 15                	jne    80105a70 <create+0x9f>
80105a5b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a5e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105a62:	66 83 f8 02          	cmp    $0x2,%ax
80105a66:	75 08                	jne    80105a70 <create+0x9f>
      return ip;
80105a68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a6b:	e9 1f 01 00 00       	jmp    80105b8f <create+0x1be>
    iunlockput(ip);
80105a70:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a73:	89 04 24             	mov    %eax,(%esp)
80105a76:	e8 9d c0 ff ff       	call   80101b18 <iunlockput>
    return 0;
80105a7b:	b8 00 00 00 00       	mov    $0x0,%eax
80105a80:	e9 0a 01 00 00       	jmp    80105b8f <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105a85:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105a89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a8c:	8b 00                	mov    (%eax),%eax
80105a8e:	89 54 24 04          	mov    %edx,0x4(%esp)
80105a92:	89 04 24             	mov    %eax,(%esp)
80105a95:	e8 5f bb ff ff       	call   801015f9 <ialloc>
80105a9a:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105a9d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105aa1:	75 0c                	jne    80105aaf <create+0xde>
    panic("create: ialloc");
80105aa3:	c7 04 24 53 86 10 80 	movl   $0x80108653,(%esp)
80105aaa:	e8 97 aa ff ff       	call   80100546 <panic>

  ilock(ip);
80105aaf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ab2:	89 04 24             	mov    %eax,(%esp)
80105ab5:	e8 da bd ff ff       	call   80101894 <ilock>
  ip->major = major;
80105aba:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105abd:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105ac1:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105ac5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ac8:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105acc:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105ad0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ad3:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105ad9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105adc:	89 04 24             	mov    %eax,(%esp)
80105adf:	e8 f4 bb ff ff       	call   801016d8 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105ae4:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105ae9:	75 6a                	jne    80105b55 <create+0x184>
    dp->nlink++;  // for ".."
80105aeb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105aee:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105af2:	8d 50 01             	lea    0x1(%eax),%edx
80105af5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105af8:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105afc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105aff:	89 04 24             	mov    %eax,(%esp)
80105b02:	e8 d1 bb ff ff       	call   801016d8 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105b07:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b0a:	8b 40 04             	mov    0x4(%eax),%eax
80105b0d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b11:	c7 44 24 04 2d 86 10 	movl   $0x8010862d,0x4(%esp)
80105b18:	80 
80105b19:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b1c:	89 04 24             	mov    %eax,(%esp)
80105b1f:	e8 6e c6 ff ff       	call   80102192 <dirlink>
80105b24:	85 c0                	test   %eax,%eax
80105b26:	78 21                	js     80105b49 <create+0x178>
80105b28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b2b:	8b 40 04             	mov    0x4(%eax),%eax
80105b2e:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b32:	c7 44 24 04 2f 86 10 	movl   $0x8010862f,0x4(%esp)
80105b39:	80 
80105b3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b3d:	89 04 24             	mov    %eax,(%esp)
80105b40:	e8 4d c6 ff ff       	call   80102192 <dirlink>
80105b45:	85 c0                	test   %eax,%eax
80105b47:	79 0c                	jns    80105b55 <create+0x184>
      panic("create dots");
80105b49:	c7 04 24 62 86 10 80 	movl   $0x80108662,(%esp)
80105b50:	e8 f1 a9 ff ff       	call   80100546 <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105b55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b58:	8b 40 04             	mov    0x4(%eax),%eax
80105b5b:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b5f:	8d 45 de             	lea    -0x22(%ebp),%eax
80105b62:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b69:	89 04 24             	mov    %eax,(%esp)
80105b6c:	e8 21 c6 ff ff       	call   80102192 <dirlink>
80105b71:	85 c0                	test   %eax,%eax
80105b73:	79 0c                	jns    80105b81 <create+0x1b0>
    panic("create: dirlink");
80105b75:	c7 04 24 6e 86 10 80 	movl   $0x8010866e,(%esp)
80105b7c:	e8 c5 a9 ff ff       	call   80100546 <panic>

  iunlockput(dp);
80105b81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b84:	89 04 24             	mov    %eax,(%esp)
80105b87:	e8 8c bf ff ff       	call   80101b18 <iunlockput>

  return ip;
80105b8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105b8f:	c9                   	leave  
80105b90:	c3                   	ret    

80105b91 <sys_open>:

int
sys_open(void)
{
80105b91:	55                   	push   %ebp
80105b92:	89 e5                	mov    %esp,%ebp
80105b94:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105b97:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105b9a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b9e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105ba5:	e8 a2 f6 ff ff       	call   8010524c <argstr>
80105baa:	85 c0                	test   %eax,%eax
80105bac:	78 17                	js     80105bc5 <sys_open+0x34>
80105bae:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105bb1:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bb5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105bbc:	e8 f1 f5 ff ff       	call   801051b2 <argint>
80105bc1:	85 c0                	test   %eax,%eax
80105bc3:	79 0a                	jns    80105bcf <sys_open+0x3e>
    return -1;
80105bc5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105bca:	e9 48 01 00 00       	jmp    80105d17 <sys_open+0x186>
  if(omode & O_CREATE){
80105bcf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105bd2:	25 00 02 00 00       	and    $0x200,%eax
80105bd7:	85 c0                	test   %eax,%eax
80105bd9:	74 40                	je     80105c1b <sys_open+0x8a>
    begin_trans();
80105bdb:	e8 90 d6 ff ff       	call   80103270 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80105be0:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105be3:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105bea:	00 
80105beb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105bf2:	00 
80105bf3:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80105bfa:	00 
80105bfb:	89 04 24             	mov    %eax,(%esp)
80105bfe:	e8 ce fd ff ff       	call   801059d1 <create>
80105c03:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80105c06:	e8 ae d6 ff ff       	call   801032b9 <commit_trans>
    if(ip == 0)
80105c0b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105c0f:	75 5c                	jne    80105c6d <sys_open+0xdc>
      return -1;
80105c11:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c16:	e9 fc 00 00 00       	jmp    80105d17 <sys_open+0x186>
  } else {
    if((ip = namei(path)) == 0)
80105c1b:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105c1e:	89 04 24             	mov    %eax,(%esp)
80105c21:	e8 2f c8 ff ff       	call   80102455 <namei>
80105c26:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105c29:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105c2d:	75 0a                	jne    80105c39 <sys_open+0xa8>
      return -1;
80105c2f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c34:	e9 de 00 00 00       	jmp    80105d17 <sys_open+0x186>
    ilock(ip);
80105c39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c3c:	89 04 24             	mov    %eax,(%esp)
80105c3f:	e8 50 bc ff ff       	call   80101894 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80105c44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c47:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105c4b:	66 83 f8 01          	cmp    $0x1,%ax
80105c4f:	75 1c                	jne    80105c6d <sys_open+0xdc>
80105c51:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105c54:	85 c0                	test   %eax,%eax
80105c56:	74 15                	je     80105c6d <sys_open+0xdc>
      iunlockput(ip);
80105c58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c5b:	89 04 24             	mov    %eax,(%esp)
80105c5e:	e8 b5 be ff ff       	call   80101b18 <iunlockput>
      return -1;
80105c63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c68:	e9 aa 00 00 00       	jmp    80105d17 <sys_open+0x186>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80105c6d:	e8 d2 b2 ff ff       	call   80100f44 <filealloc>
80105c72:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105c75:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105c79:	74 14                	je     80105c8f <sys_open+0xfe>
80105c7b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c7e:	89 04 24             	mov    %eax,(%esp)
80105c81:	e8 43 f7 ff ff       	call   801053c9 <fdalloc>
80105c86:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105c89:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80105c8d:	79 23                	jns    80105cb2 <sys_open+0x121>
    if(f)
80105c8f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105c93:	74 0b                	je     80105ca0 <sys_open+0x10f>
      fileclose(f);
80105c95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c98:	89 04 24             	mov    %eax,(%esp)
80105c9b:	e8 4c b3 ff ff       	call   80100fec <fileclose>
    iunlockput(ip);
80105ca0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ca3:	89 04 24             	mov    %eax,(%esp)
80105ca6:	e8 6d be ff ff       	call   80101b18 <iunlockput>
    return -1;
80105cab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cb0:	eb 65                	jmp    80105d17 <sys_open+0x186>
  }
  iunlock(ip);
80105cb2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cb5:	89 04 24             	mov    %eax,(%esp)
80105cb8:	e8 25 bd ff ff       	call   801019e2 <iunlock>

  f->type = FD_INODE;
80105cbd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cc0:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80105cc6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cc9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105ccc:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80105ccf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cd2:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80105cd9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105cdc:	83 e0 01             	and    $0x1,%eax
80105cdf:	85 c0                	test   %eax,%eax
80105ce1:	0f 94 c0             	sete   %al
80105ce4:	89 c2                	mov    %eax,%edx
80105ce6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ce9:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80105cec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105cef:	83 e0 01             	and    $0x1,%eax
80105cf2:	85 c0                	test   %eax,%eax
80105cf4:	75 0a                	jne    80105d00 <sys_open+0x16f>
80105cf6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105cf9:	83 e0 02             	and    $0x2,%eax
80105cfc:	85 c0                	test   %eax,%eax
80105cfe:	74 07                	je     80105d07 <sys_open+0x176>
80105d00:	b8 01 00 00 00       	mov    $0x1,%eax
80105d05:	eb 05                	jmp    80105d0c <sys_open+0x17b>
80105d07:	b8 00 00 00 00       	mov    $0x0,%eax
80105d0c:	89 c2                	mov    %eax,%edx
80105d0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d11:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80105d14:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80105d17:	c9                   	leave  
80105d18:	c3                   	ret    

80105d19 <sys_mkdir>:

int
sys_mkdir(void)
{
80105d19:	55                   	push   %ebp
80105d1a:	89 e5                	mov    %esp,%ebp
80105d1c:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80105d1f:	e8 4c d5 ff ff       	call   80103270 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80105d24:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105d27:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d2b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105d32:	e8 15 f5 ff ff       	call   8010524c <argstr>
80105d37:	85 c0                	test   %eax,%eax
80105d39:	78 2c                	js     80105d67 <sys_mkdir+0x4e>
80105d3b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d3e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105d45:	00 
80105d46:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105d4d:	00 
80105d4e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105d55:	00 
80105d56:	89 04 24             	mov    %eax,(%esp)
80105d59:	e8 73 fc ff ff       	call   801059d1 <create>
80105d5e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105d61:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105d65:	75 0c                	jne    80105d73 <sys_mkdir+0x5a>
    commit_trans();
80105d67:	e8 4d d5 ff ff       	call   801032b9 <commit_trans>
    return -1;
80105d6c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d71:	eb 15                	jmp    80105d88 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80105d73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d76:	89 04 24             	mov    %eax,(%esp)
80105d79:	e8 9a bd ff ff       	call   80101b18 <iunlockput>
  commit_trans();
80105d7e:	e8 36 d5 ff ff       	call   801032b9 <commit_trans>
  return 0;
80105d83:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105d88:	c9                   	leave  
80105d89:	c3                   	ret    

80105d8a <sys_mknod>:

int
sys_mknod(void)
{
80105d8a:	55                   	push   %ebp
80105d8b:	89 e5                	mov    %esp,%ebp
80105d8d:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
80105d90:	e8 db d4 ff ff       	call   80103270 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
80105d95:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105d98:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d9c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105da3:	e8 a4 f4 ff ff       	call   8010524c <argstr>
80105da8:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105dab:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105daf:	78 5e                	js     80105e0f <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80105db1:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105db4:	89 44 24 04          	mov    %eax,0x4(%esp)
80105db8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105dbf:	e8 ee f3 ff ff       	call   801051b2 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
80105dc4:	85 c0                	test   %eax,%eax
80105dc6:	78 47                	js     80105e0f <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80105dc8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105dcb:	89 44 24 04          	mov    %eax,0x4(%esp)
80105dcf:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105dd6:	e8 d7 f3 ff ff       	call   801051b2 <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80105ddb:	85 c0                	test   %eax,%eax
80105ddd:	78 30                	js     80105e0f <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80105ddf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105de2:	0f bf c8             	movswl %ax,%ecx
80105de5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105de8:	0f bf d0             	movswl %ax,%edx
80105deb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80105dee:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80105df2:	89 54 24 08          	mov    %edx,0x8(%esp)
80105df6:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80105dfd:	00 
80105dfe:	89 04 24             	mov    %eax,(%esp)
80105e01:	e8 cb fb ff ff       	call   801059d1 <create>
80105e06:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105e09:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105e0d:	75 0c                	jne    80105e1b <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80105e0f:	e8 a5 d4 ff ff       	call   801032b9 <commit_trans>
    return -1;
80105e14:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e19:	eb 15                	jmp    80105e30 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80105e1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e1e:	89 04 24             	mov    %eax,(%esp)
80105e21:	e8 f2 bc ff ff       	call   80101b18 <iunlockput>
  commit_trans();
80105e26:	e8 8e d4 ff ff       	call   801032b9 <commit_trans>
  return 0;
80105e2b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105e30:	c9                   	leave  
80105e31:	c3                   	ret    

80105e32 <sys_chdir>:

int
sys_chdir(void)
{
80105e32:	55                   	push   %ebp
80105e33:	89 e5                	mov    %esp,%ebp
80105e35:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80105e38:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105e3b:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e3f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105e46:	e8 01 f4 ff ff       	call   8010524c <argstr>
80105e4b:	85 c0                	test   %eax,%eax
80105e4d:	78 14                	js     80105e63 <sys_chdir+0x31>
80105e4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e52:	89 04 24             	mov    %eax,(%esp)
80105e55:	e8 fb c5 ff ff       	call   80102455 <namei>
80105e5a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105e5d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e61:	75 07                	jne    80105e6a <sys_chdir+0x38>
    return -1;
80105e63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e68:	eb 57                	jmp    80105ec1 <sys_chdir+0x8f>
  ilock(ip);
80105e6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e6d:	89 04 24             	mov    %eax,(%esp)
80105e70:	e8 1f ba ff ff       	call   80101894 <ilock>
  if(ip->type != T_DIR){
80105e75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e78:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105e7c:	66 83 f8 01          	cmp    $0x1,%ax
80105e80:	74 12                	je     80105e94 <sys_chdir+0x62>
    iunlockput(ip);
80105e82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e85:	89 04 24             	mov    %eax,(%esp)
80105e88:	e8 8b bc ff ff       	call   80101b18 <iunlockput>
    return -1;
80105e8d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e92:	eb 2d                	jmp    80105ec1 <sys_chdir+0x8f>
  }
  iunlock(ip);
80105e94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e97:	89 04 24             	mov    %eax,(%esp)
80105e9a:	e8 43 bb ff ff       	call   801019e2 <iunlock>
  iput(proc->cwd);
80105e9f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ea5:	8b 40 68             	mov    0x68(%eax),%eax
80105ea8:	89 04 24             	mov    %eax,(%esp)
80105eab:	e8 97 bb ff ff       	call   80101a47 <iput>
  proc->cwd = ip;
80105eb0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105eb6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105eb9:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80105ebc:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ec1:	c9                   	leave  
80105ec2:	c3                   	ret    

80105ec3 <sys_exec>:

int
sys_exec(void)
{
80105ec3:	55                   	push   %ebp
80105ec4:	89 e5                	mov    %esp,%ebp
80105ec6:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80105ecc:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105ecf:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ed3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105eda:	e8 6d f3 ff ff       	call   8010524c <argstr>
80105edf:	85 c0                	test   %eax,%eax
80105ee1:	78 1a                	js     80105efd <sys_exec+0x3a>
80105ee3:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80105ee9:	89 44 24 04          	mov    %eax,0x4(%esp)
80105eed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105ef4:	e8 b9 f2 ff ff       	call   801051b2 <argint>
80105ef9:	85 c0                	test   %eax,%eax
80105efb:	79 0a                	jns    80105f07 <sys_exec+0x44>
    return -1;
80105efd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f02:	e9 de 00 00 00       	jmp    80105fe5 <sys_exec+0x122>
  }
  memset(argv, 0, sizeof(argv));
80105f07:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80105f0e:	00 
80105f0f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105f16:	00 
80105f17:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80105f1d:	89 04 24             	mov    %eax,(%esp)
80105f20:	e8 3d ef ff ff       	call   80104e62 <memset>
  for(i=0;; i++){
80105f25:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80105f2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f2f:	83 f8 1f             	cmp    $0x1f,%eax
80105f32:	76 0a                	jbe    80105f3e <sys_exec+0x7b>
      return -1;
80105f34:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f39:	e9 a7 00 00 00       	jmp    80105fe5 <sys_exec+0x122>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80105f3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f41:	c1 e0 02             	shl    $0x2,%eax
80105f44:	89 c2                	mov    %eax,%edx
80105f46:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80105f4c:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80105f4f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f55:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80105f5b:	89 54 24 08          	mov    %edx,0x8(%esp)
80105f5f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80105f63:	89 04 24             	mov    %eax,(%esp)
80105f66:	e8 b5 f1 ff ff       	call   80105120 <fetchint>
80105f6b:	85 c0                	test   %eax,%eax
80105f6d:	79 07                	jns    80105f76 <sys_exec+0xb3>
      return -1;
80105f6f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f74:	eb 6f                	jmp    80105fe5 <sys_exec+0x122>
    if(uarg == 0){
80105f76:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80105f7c:	85 c0                	test   %eax,%eax
80105f7e:	75 26                	jne    80105fa6 <sys_exec+0xe3>
      argv[i] = 0;
80105f80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f83:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80105f8a:	00 00 00 00 
      break;
80105f8e:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80105f8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f92:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80105f98:	89 54 24 04          	mov    %edx,0x4(%esp)
80105f9c:	89 04 24             	mov    %eax,(%esp)
80105f9f:	e8 64 ab ff ff       	call   80100b08 <exec>
80105fa4:	eb 3f                	jmp    80105fe5 <sys_exec+0x122>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
80105fa6:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80105fac:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105faf:	c1 e2 02             	shl    $0x2,%edx
80105fb2:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80105fb5:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
80105fbb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105fc1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105fc5:	89 54 24 04          	mov    %edx,0x4(%esp)
80105fc9:	89 04 24             	mov    %eax,(%esp)
80105fcc:	e8 83 f1 ff ff       	call   80105154 <fetchstr>
80105fd1:	85 c0                	test   %eax,%eax
80105fd3:	79 07                	jns    80105fdc <sys_exec+0x119>
      return -1;
80105fd5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fda:	eb 09                	jmp    80105fe5 <sys_exec+0x122>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80105fdc:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
80105fe0:	e9 47 ff ff ff       	jmp    80105f2c <sys_exec+0x69>
  return exec(path, argv);
}
80105fe5:	c9                   	leave  
80105fe6:	c3                   	ret    

80105fe7 <sys_pipe>:

int
sys_pipe(void)
{
80105fe7:	55                   	push   %ebp
80105fe8:	89 e5                	mov    %esp,%ebp
80105fea:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80105fed:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80105ff4:	00 
80105ff5:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105ff8:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ffc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106003:	e8 e2 f1 ff ff       	call   801051ea <argptr>
80106008:	85 c0                	test   %eax,%eax
8010600a:	79 0a                	jns    80106016 <sys_pipe+0x2f>
    return -1;
8010600c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106011:	e9 9b 00 00 00       	jmp    801060b1 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106016:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106019:	89 44 24 04          	mov    %eax,0x4(%esp)
8010601d:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106020:	89 04 24             	mov    %eax,(%esp)
80106023:	e8 6c dc ff ff       	call   80103c94 <pipealloc>
80106028:	85 c0                	test   %eax,%eax
8010602a:	79 07                	jns    80106033 <sys_pipe+0x4c>
    return -1;
8010602c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106031:	eb 7e                	jmp    801060b1 <sys_pipe+0xca>
  fd0 = -1;
80106033:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
8010603a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010603d:	89 04 24             	mov    %eax,(%esp)
80106040:	e8 84 f3 ff ff       	call   801053c9 <fdalloc>
80106045:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106048:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010604c:	78 14                	js     80106062 <sys_pipe+0x7b>
8010604e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106051:	89 04 24             	mov    %eax,(%esp)
80106054:	e8 70 f3 ff ff       	call   801053c9 <fdalloc>
80106059:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010605c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106060:	79 37                	jns    80106099 <sys_pipe+0xb2>
    if(fd0 >= 0)
80106062:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106066:	78 14                	js     8010607c <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106068:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010606e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106071:	83 c2 08             	add    $0x8,%edx
80106074:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010607b:	00 
    fileclose(rf);
8010607c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010607f:	89 04 24             	mov    %eax,(%esp)
80106082:	e8 65 af ff ff       	call   80100fec <fileclose>
    fileclose(wf);
80106087:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010608a:	89 04 24             	mov    %eax,(%esp)
8010608d:	e8 5a af ff ff       	call   80100fec <fileclose>
    return -1;
80106092:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106097:	eb 18                	jmp    801060b1 <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106099:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010609c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010609f:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801060a1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801060a4:	8d 50 04             	lea    0x4(%eax),%edx
801060a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060aa:	89 02                	mov    %eax,(%edx)
  return 0;
801060ac:	b8 00 00 00 00       	mov    $0x0,%eax
}
801060b1:	c9                   	leave  
801060b2:	c3                   	ret    
801060b3:	90                   	nop

801060b4 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
801060b4:	55                   	push   %ebp
801060b5:	89 e5                	mov    %esp,%ebp
801060b7:	83 ec 08             	sub    $0x8,%esp
  return fork();
801060ba:	e8 93 e2 ff ff       	call   80104352 <fork>
}
801060bf:	c9                   	leave  
801060c0:	c3                   	ret    

801060c1 <sys_exit>:

int
sys_exit(void)
{
801060c1:	55                   	push   %ebp
801060c2:	89 e5                	mov    %esp,%ebp
801060c4:	83 ec 08             	sub    $0x8,%esp
  exit();
801060c7:	e8 e9 e3 ff ff       	call   801044b5 <exit>
  return 0;  // not reached
801060cc:	b8 00 00 00 00       	mov    $0x0,%eax
}
801060d1:	c9                   	leave  
801060d2:	c3                   	ret    

801060d3 <sys_wait>:

int
sys_wait(void)
{
801060d3:	55                   	push   %ebp
801060d4:	89 e5                	mov    %esp,%ebp
801060d6:	83 ec 08             	sub    $0x8,%esp
  return wait();
801060d9:	e8 ef e4 ff ff       	call   801045cd <wait>
}
801060de:	c9                   	leave  
801060df:	c3                   	ret    

801060e0 <sys_kill>:

int
sys_kill(void)
{
801060e0:	55                   	push   %ebp
801060e1:	89 e5                	mov    %esp,%ebp
801060e3:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
801060e6:	8d 45 f4             	lea    -0xc(%ebp),%eax
801060e9:	89 44 24 04          	mov    %eax,0x4(%esp)
801060ed:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060f4:	e8 b9 f0 ff ff       	call   801051b2 <argint>
801060f9:	85 c0                	test   %eax,%eax
801060fb:	79 07                	jns    80106104 <sys_kill+0x24>
    return -1;
801060fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106102:	eb 0b                	jmp    8010610f <sys_kill+0x2f>
  return kill(pid);
80106104:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106107:	89 04 24             	mov    %eax,(%esp)
8010610a:	e8 1e e9 ff ff       	call   80104a2d <kill>
}
8010610f:	c9                   	leave  
80106110:	c3                   	ret    

80106111 <sys_getpid>:

int
sys_getpid(void)
{
80106111:	55                   	push   %ebp
80106112:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106114:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010611a:	8b 40 10             	mov    0x10(%eax),%eax
}
8010611d:	5d                   	pop    %ebp
8010611e:	c3                   	ret    

8010611f <sys_sbrk>:

int
sys_sbrk(void)
{
8010611f:	55                   	push   %ebp
80106120:	89 e5                	mov    %esp,%ebp
80106122:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106125:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106128:	89 44 24 04          	mov    %eax,0x4(%esp)
8010612c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106133:	e8 7a f0 ff ff       	call   801051b2 <argint>
80106138:	85 c0                	test   %eax,%eax
8010613a:	79 07                	jns    80106143 <sys_sbrk+0x24>
    return -1;
8010613c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106141:	eb 24                	jmp    80106167 <sys_sbrk+0x48>
  addr = proc->sz;
80106143:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106149:	8b 00                	mov    (%eax),%eax
8010614b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
8010614e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106151:	89 04 24             	mov    %eax,(%esp)
80106154:	e8 54 e1 ff ff       	call   801042ad <growproc>
80106159:	85 c0                	test   %eax,%eax
8010615b:	79 07                	jns    80106164 <sys_sbrk+0x45>
    return -1;
8010615d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106162:	eb 03                	jmp    80106167 <sys_sbrk+0x48>
  return addr;
80106164:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106167:	c9                   	leave  
80106168:	c3                   	ret    

80106169 <sys_sleep>:

int
sys_sleep(void)
{
80106169:	55                   	push   %ebp
8010616a:	89 e5                	mov    %esp,%ebp
8010616c:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
8010616f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106172:	89 44 24 04          	mov    %eax,0x4(%esp)
80106176:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010617d:	e8 30 f0 ff ff       	call   801051b2 <argint>
80106182:	85 c0                	test   %eax,%eax
80106184:	79 07                	jns    8010618d <sys_sleep+0x24>
    return -1;
80106186:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010618b:	eb 6c                	jmp    801061f9 <sys_sleep+0x90>
  acquire(&tickslock);
8010618d:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
80106194:	e8 6e ea ff ff       	call   80104c07 <acquire>
  ticks0 = ticks;
80106199:	a1 a0 26 11 80       	mov    0x801126a0,%eax
8010619e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
801061a1:	eb 34                	jmp    801061d7 <sys_sleep+0x6e>
    if(proc->killed){
801061a3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061a9:	8b 40 24             	mov    0x24(%eax),%eax
801061ac:	85 c0                	test   %eax,%eax
801061ae:	74 13                	je     801061c3 <sys_sleep+0x5a>
      release(&tickslock);
801061b0:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
801061b7:	e8 ad ea ff ff       	call   80104c69 <release>
      return -1;
801061bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061c1:	eb 36                	jmp    801061f9 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
801061c3:	c7 44 24 04 60 1e 11 	movl   $0x80111e60,0x4(%esp)
801061ca:	80 
801061cb:	c7 04 24 a0 26 11 80 	movl   $0x801126a0,(%esp)
801061d2:	e8 52 e7 ff ff       	call   80104929 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
801061d7:	a1 a0 26 11 80       	mov    0x801126a0,%eax
801061dc:	89 c2                	mov    %eax,%edx
801061de:	2b 55 f4             	sub    -0xc(%ebp),%edx
801061e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061e4:	39 c2                	cmp    %eax,%edx
801061e6:	72 bb                	jb     801061a3 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
801061e8:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
801061ef:	e8 75 ea ff ff       	call   80104c69 <release>
  return 0;
801061f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061f9:	c9                   	leave  
801061fa:	c3                   	ret    

801061fb <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
801061fb:	55                   	push   %ebp
801061fc:	89 e5                	mov    %esp,%ebp
801061fe:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106201:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
80106208:	e8 fa e9 ff ff       	call   80104c07 <acquire>
  xticks = ticks;
8010620d:	a1 a0 26 11 80       	mov    0x801126a0,%eax
80106212:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106215:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
8010621c:	e8 48 ea ff ff       	call   80104c69 <release>
  return xticks;
80106221:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106224:	c9                   	leave  
80106225:	c3                   	ret    
80106226:	66 90                	xchg   %ax,%ax

80106228 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106228:	55                   	push   %ebp
80106229:	89 e5                	mov    %esp,%ebp
8010622b:	83 ec 08             	sub    $0x8,%esp
8010622e:	8b 55 08             	mov    0x8(%ebp),%edx
80106231:	8b 45 0c             	mov    0xc(%ebp),%eax
80106234:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106238:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010623b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010623f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106243:	ee                   	out    %al,(%dx)
}
80106244:	c9                   	leave  
80106245:	c3                   	ret    

80106246 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106246:	55                   	push   %ebp
80106247:	89 e5                	mov    %esp,%ebp
80106249:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
8010624c:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106253:	00 
80106254:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
8010625b:	e8 c8 ff ff ff       	call   80106228 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106260:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106267:	00 
80106268:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010626f:	e8 b4 ff ff ff       	call   80106228 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106274:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
8010627b:	00 
8010627c:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106283:	e8 a0 ff ff ff       	call   80106228 <outb>
  picenable(IRQ_TIMER);
80106288:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010628f:	e8 89 d8 ff ff       	call   80103b1d <picenable>
}
80106294:	c9                   	leave  
80106295:	c3                   	ret    
80106296:	66 90                	xchg   %ax,%ax

80106298 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106298:	1e                   	push   %ds
  pushl %es
80106299:	06                   	push   %es
  pushl %fs
8010629a:	0f a0                	push   %fs
  pushl %gs
8010629c:	0f a8                	push   %gs
  pushal
8010629e:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
8010629f:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801062a3:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801062a5:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
801062a7:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
801062ab:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
801062ad:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
801062af:	54                   	push   %esp
  call trap
801062b0:	e8 de 01 00 00       	call   80106493 <trap>
  addl $4, %esp
801062b5:	83 c4 04             	add    $0x4,%esp

801062b8 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
801062b8:	61                   	popa   
  popl %gs
801062b9:	0f a9                	pop    %gs
  popl %fs
801062bb:	0f a1                	pop    %fs
  popl %es
801062bd:	07                   	pop    %es
  popl %ds
801062be:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
801062bf:	83 c4 08             	add    $0x8,%esp
  iret
801062c2:	cf                   	iret   
801062c3:	90                   	nop

801062c4 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
801062c4:	55                   	push   %ebp
801062c5:	89 e5                	mov    %esp,%ebp
801062c7:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801062ca:	8b 45 0c             	mov    0xc(%ebp),%eax
801062cd:	83 e8 01             	sub    $0x1,%eax
801062d0:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801062d4:	8b 45 08             	mov    0x8(%ebp),%eax
801062d7:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801062db:	8b 45 08             	mov    0x8(%ebp),%eax
801062de:	c1 e8 10             	shr    $0x10,%eax
801062e1:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
801062e5:	8d 45 fa             	lea    -0x6(%ebp),%eax
801062e8:	0f 01 18             	lidtl  (%eax)
}
801062eb:	c9                   	leave  
801062ec:	c3                   	ret    

801062ed <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
801062ed:	55                   	push   %ebp
801062ee:	89 e5                	mov    %esp,%ebp
801062f0:	53                   	push   %ebx
801062f1:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801062f4:	0f 20 d3             	mov    %cr2,%ebx
801062f7:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
801062fa:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801062fd:	83 c4 10             	add    $0x10,%esp
80106300:	5b                   	pop    %ebx
80106301:	5d                   	pop    %ebp
80106302:	c3                   	ret    

80106303 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106303:	55                   	push   %ebp
80106304:	89 e5                	mov    %esp,%ebp
80106306:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106309:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106310:	e9 c3 00 00 00       	jmp    801063d8 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106315:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106318:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
8010631f:	89 c2                	mov    %eax,%edx
80106321:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106324:	66 89 14 c5 a0 1e 11 	mov    %dx,-0x7feee160(,%eax,8)
8010632b:	80 
8010632c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010632f:	66 c7 04 c5 a2 1e 11 	movw   $0x8,-0x7feee15e(,%eax,8)
80106336:	80 08 00 
80106339:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010633c:	0f b6 14 c5 a4 1e 11 	movzbl -0x7feee15c(,%eax,8),%edx
80106343:	80 
80106344:	83 e2 e0             	and    $0xffffffe0,%edx
80106347:	88 14 c5 a4 1e 11 80 	mov    %dl,-0x7feee15c(,%eax,8)
8010634e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106351:	0f b6 14 c5 a4 1e 11 	movzbl -0x7feee15c(,%eax,8),%edx
80106358:	80 
80106359:	83 e2 1f             	and    $0x1f,%edx
8010635c:	88 14 c5 a4 1e 11 80 	mov    %dl,-0x7feee15c(,%eax,8)
80106363:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106366:	0f b6 14 c5 a5 1e 11 	movzbl -0x7feee15b(,%eax,8),%edx
8010636d:	80 
8010636e:	83 e2 f0             	and    $0xfffffff0,%edx
80106371:	83 ca 0e             	or     $0xe,%edx
80106374:	88 14 c5 a5 1e 11 80 	mov    %dl,-0x7feee15b(,%eax,8)
8010637b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010637e:	0f b6 14 c5 a5 1e 11 	movzbl -0x7feee15b(,%eax,8),%edx
80106385:	80 
80106386:	83 e2 ef             	and    $0xffffffef,%edx
80106389:	88 14 c5 a5 1e 11 80 	mov    %dl,-0x7feee15b(,%eax,8)
80106390:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106393:	0f b6 14 c5 a5 1e 11 	movzbl -0x7feee15b(,%eax,8),%edx
8010639a:	80 
8010639b:	83 e2 9f             	and    $0xffffff9f,%edx
8010639e:	88 14 c5 a5 1e 11 80 	mov    %dl,-0x7feee15b(,%eax,8)
801063a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063a8:	0f b6 14 c5 a5 1e 11 	movzbl -0x7feee15b(,%eax,8),%edx
801063af:	80 
801063b0:	83 ca 80             	or     $0xffffff80,%edx
801063b3:	88 14 c5 a5 1e 11 80 	mov    %dl,-0x7feee15b(,%eax,8)
801063ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063bd:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
801063c4:	c1 e8 10             	shr    $0x10,%eax
801063c7:	89 c2                	mov    %eax,%edx
801063c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063cc:	66 89 14 c5 a6 1e 11 	mov    %dx,-0x7feee15a(,%eax,8)
801063d3:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
801063d4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801063d8:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
801063df:	0f 8e 30 ff ff ff    	jle    80106315 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801063e5:	a1 98 b1 10 80       	mov    0x8010b198,%eax
801063ea:	66 a3 a0 20 11 80    	mov    %ax,0x801120a0
801063f0:	66 c7 05 a2 20 11 80 	movw   $0x8,0x801120a2
801063f7:	08 00 
801063f9:	0f b6 05 a4 20 11 80 	movzbl 0x801120a4,%eax
80106400:	83 e0 e0             	and    $0xffffffe0,%eax
80106403:	a2 a4 20 11 80       	mov    %al,0x801120a4
80106408:	0f b6 05 a4 20 11 80 	movzbl 0x801120a4,%eax
8010640f:	83 e0 1f             	and    $0x1f,%eax
80106412:	a2 a4 20 11 80       	mov    %al,0x801120a4
80106417:	0f b6 05 a5 20 11 80 	movzbl 0x801120a5,%eax
8010641e:	83 c8 0f             	or     $0xf,%eax
80106421:	a2 a5 20 11 80       	mov    %al,0x801120a5
80106426:	0f b6 05 a5 20 11 80 	movzbl 0x801120a5,%eax
8010642d:	83 e0 ef             	and    $0xffffffef,%eax
80106430:	a2 a5 20 11 80       	mov    %al,0x801120a5
80106435:	0f b6 05 a5 20 11 80 	movzbl 0x801120a5,%eax
8010643c:	83 c8 60             	or     $0x60,%eax
8010643f:	a2 a5 20 11 80       	mov    %al,0x801120a5
80106444:	0f b6 05 a5 20 11 80 	movzbl 0x801120a5,%eax
8010644b:	83 c8 80             	or     $0xffffff80,%eax
8010644e:	a2 a5 20 11 80       	mov    %al,0x801120a5
80106453:	a1 98 b1 10 80       	mov    0x8010b198,%eax
80106458:	c1 e8 10             	shr    $0x10,%eax
8010645b:	66 a3 a6 20 11 80    	mov    %ax,0x801120a6
  
  initlock(&tickslock, "time");
80106461:	c7 44 24 04 80 86 10 	movl   $0x80108680,0x4(%esp)
80106468:	80 
80106469:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
80106470:	e8 71 e7 ff ff       	call   80104be6 <initlock>
}
80106475:	c9                   	leave  
80106476:	c3                   	ret    

80106477 <idtinit>:

void
idtinit(void)
{
80106477:	55                   	push   %ebp
80106478:	89 e5                	mov    %esp,%ebp
8010647a:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
8010647d:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106484:	00 
80106485:	c7 04 24 a0 1e 11 80 	movl   $0x80111ea0,(%esp)
8010648c:	e8 33 fe ff ff       	call   801062c4 <lidt>
}
80106491:	c9                   	leave  
80106492:	c3                   	ret    

80106493 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106493:	55                   	push   %ebp
80106494:	89 e5                	mov    %esp,%ebp
80106496:	57                   	push   %edi
80106497:	56                   	push   %esi
80106498:	53                   	push   %ebx
80106499:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
8010649c:	8b 45 08             	mov    0x8(%ebp),%eax
8010649f:	8b 40 30             	mov    0x30(%eax),%eax
801064a2:	83 f8 40             	cmp    $0x40,%eax
801064a5:	75 3e                	jne    801064e5 <trap+0x52>
    if(proc->killed)
801064a7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064ad:	8b 40 24             	mov    0x24(%eax),%eax
801064b0:	85 c0                	test   %eax,%eax
801064b2:	74 05                	je     801064b9 <trap+0x26>
      exit();
801064b4:	e8 fc df ff ff       	call   801044b5 <exit>
    proc->tf = tf;
801064b9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064bf:	8b 55 08             	mov    0x8(%ebp),%edx
801064c2:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
801064c5:	e8 c5 ed ff ff       	call   8010528f <syscall>
    if(proc->killed)
801064ca:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064d0:	8b 40 24             	mov    0x24(%eax),%eax
801064d3:	85 c0                	test   %eax,%eax
801064d5:	0f 84 34 02 00 00    	je     8010670f <trap+0x27c>
      exit();
801064db:	e8 d5 df ff ff       	call   801044b5 <exit>
    return;
801064e0:	e9 2a 02 00 00       	jmp    8010670f <trap+0x27c>
  }

  switch(tf->trapno){
801064e5:	8b 45 08             	mov    0x8(%ebp),%eax
801064e8:	8b 40 30             	mov    0x30(%eax),%eax
801064eb:	83 e8 20             	sub    $0x20,%eax
801064ee:	83 f8 1f             	cmp    $0x1f,%eax
801064f1:	0f 87 bc 00 00 00    	ja     801065b3 <trap+0x120>
801064f7:	8b 04 85 28 87 10 80 	mov    -0x7fef78d8(,%eax,4),%eax
801064fe:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80106500:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106506:	0f b6 00             	movzbl (%eax),%eax
80106509:	84 c0                	test   %al,%al
8010650b:	75 31                	jne    8010653e <trap+0xab>
      acquire(&tickslock);
8010650d:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
80106514:	e8 ee e6 ff ff       	call   80104c07 <acquire>
      ticks++;
80106519:	a1 a0 26 11 80       	mov    0x801126a0,%eax
8010651e:	83 c0 01             	add    $0x1,%eax
80106521:	a3 a0 26 11 80       	mov    %eax,0x801126a0
      wakeup(&ticks);
80106526:	c7 04 24 a0 26 11 80 	movl   $0x801126a0,(%esp)
8010652d:	e8 d0 e4 ff ff       	call   80104a02 <wakeup>
      release(&tickslock);
80106532:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
80106539:	e8 2b e7 ff ff       	call   80104c69 <release>
    }
    lapiceoi();
8010653e:	e8 f6 c9 ff ff       	call   80102f39 <lapiceoi>
    break;
80106543:	e9 41 01 00 00       	jmp    80106689 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80106548:	e8 f0 c1 ff ff       	call   8010273d <ideintr>
    lapiceoi();
8010654d:	e8 e7 c9 ff ff       	call   80102f39 <lapiceoi>
    break;
80106552:	e9 32 01 00 00       	jmp    80106689 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80106557:	e8 b9 c7 ff ff       	call   80102d15 <kbdintr>
    lapiceoi();
8010655c:	e8 d8 c9 ff ff       	call   80102f39 <lapiceoi>
    break;
80106561:	e9 23 01 00 00       	jmp    80106689 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80106566:	e8 a9 03 00 00       	call   80106914 <uartintr>
    lapiceoi();
8010656b:	e8 c9 c9 ff ff       	call   80102f39 <lapiceoi>
    break;
80106570:	e9 14 01 00 00       	jmp    80106689 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80106575:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106578:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
8010657b:	8b 45 08             	mov    0x8(%ebp),%eax
8010657e:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106582:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80106585:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010658b:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010658e:	0f b6 c0             	movzbl %al,%eax
80106591:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106595:	89 54 24 08          	mov    %edx,0x8(%esp)
80106599:	89 44 24 04          	mov    %eax,0x4(%esp)
8010659d:	c7 04 24 88 86 10 80 	movl   $0x80108688,(%esp)
801065a4:	e8 01 9e ff ff       	call   801003aa <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
801065a9:	e8 8b c9 ff ff       	call   80102f39 <lapiceoi>
    break;
801065ae:	e9 d6 00 00 00       	jmp    80106689 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
801065b3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065b9:	85 c0                	test   %eax,%eax
801065bb:	74 11                	je     801065ce <trap+0x13b>
801065bd:	8b 45 08             	mov    0x8(%ebp),%eax
801065c0:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801065c4:	0f b7 c0             	movzwl %ax,%eax
801065c7:	83 e0 03             	and    $0x3,%eax
801065ca:	85 c0                	test   %eax,%eax
801065cc:	75 46                	jne    80106614 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801065ce:	e8 1a fd ff ff       	call   801062ed <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
801065d3:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801065d6:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
801065d9:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801065e0:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801065e3:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
801065e6:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801065e9:	8b 52 30             	mov    0x30(%edx),%edx
801065ec:	89 44 24 10          	mov    %eax,0x10(%esp)
801065f0:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801065f4:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801065f8:	89 54 24 04          	mov    %edx,0x4(%esp)
801065fc:	c7 04 24 ac 86 10 80 	movl   $0x801086ac,(%esp)
80106603:	e8 a2 9d ff ff       	call   801003aa <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80106608:	c7 04 24 de 86 10 80 	movl   $0x801086de,(%esp)
8010660f:	e8 32 9f ff ff       	call   80100546 <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106614:	e8 d4 fc ff ff       	call   801062ed <rcr2>
80106619:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010661b:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010661e:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106621:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106627:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010662a:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010662d:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106630:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106633:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106636:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106639:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010663f:	83 c0 6c             	add    $0x6c,%eax
80106642:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106645:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010664b:	8b 40 10             	mov    0x10(%eax),%eax
8010664e:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80106652:	89 7c 24 18          	mov    %edi,0x18(%esp)
80106656:	89 74 24 14          	mov    %esi,0x14(%esp)
8010665a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010665e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106662:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106665:	89 54 24 08          	mov    %edx,0x8(%esp)
80106669:	89 44 24 04          	mov    %eax,0x4(%esp)
8010666d:	c7 04 24 e4 86 10 80 	movl   $0x801086e4,(%esp)
80106674:	e8 31 9d ff ff       	call   801003aa <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80106679:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010667f:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80106686:	eb 01                	jmp    80106689 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80106688:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106689:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010668f:	85 c0                	test   %eax,%eax
80106691:	74 24                	je     801066b7 <trap+0x224>
80106693:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106699:	8b 40 24             	mov    0x24(%eax),%eax
8010669c:	85 c0                	test   %eax,%eax
8010669e:	74 17                	je     801066b7 <trap+0x224>
801066a0:	8b 45 08             	mov    0x8(%ebp),%eax
801066a3:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801066a7:	0f b7 c0             	movzwl %ax,%eax
801066aa:	83 e0 03             	and    $0x3,%eax
801066ad:	83 f8 03             	cmp    $0x3,%eax
801066b0:	75 05                	jne    801066b7 <trap+0x224>
    exit();
801066b2:	e8 fe dd ff ff       	call   801044b5 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
801066b7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066bd:	85 c0                	test   %eax,%eax
801066bf:	74 1e                	je     801066df <trap+0x24c>
801066c1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066c7:	8b 40 0c             	mov    0xc(%eax),%eax
801066ca:	83 f8 04             	cmp    $0x4,%eax
801066cd:	75 10                	jne    801066df <trap+0x24c>
801066cf:	8b 45 08             	mov    0x8(%ebp),%eax
801066d2:	8b 40 30             	mov    0x30(%eax),%eax
801066d5:	83 f8 20             	cmp    $0x20,%eax
801066d8:	75 05                	jne    801066df <trap+0x24c>
    yield();
801066da:	e8 ec e1 ff ff       	call   801048cb <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801066df:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066e5:	85 c0                	test   %eax,%eax
801066e7:	74 27                	je     80106710 <trap+0x27d>
801066e9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066ef:	8b 40 24             	mov    0x24(%eax),%eax
801066f2:	85 c0                	test   %eax,%eax
801066f4:	74 1a                	je     80106710 <trap+0x27d>
801066f6:	8b 45 08             	mov    0x8(%ebp),%eax
801066f9:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801066fd:	0f b7 c0             	movzwl %ax,%eax
80106700:	83 e0 03             	and    $0x3,%eax
80106703:	83 f8 03             	cmp    $0x3,%eax
80106706:	75 08                	jne    80106710 <trap+0x27d>
    exit();
80106708:	e8 a8 dd ff ff       	call   801044b5 <exit>
8010670d:	eb 01                	jmp    80106710 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
8010670f:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80106710:	83 c4 3c             	add    $0x3c,%esp
80106713:	5b                   	pop    %ebx
80106714:	5e                   	pop    %esi
80106715:	5f                   	pop    %edi
80106716:	5d                   	pop    %ebp
80106717:	c3                   	ret    

80106718 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106718:	55                   	push   %ebp
80106719:	89 e5                	mov    %esp,%ebp
8010671b:	53                   	push   %ebx
8010671c:	83 ec 14             	sub    $0x14,%esp
8010671f:	8b 45 08             	mov    0x8(%ebp),%eax
80106722:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106726:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
8010672a:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010672e:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80106732:	ec                   	in     (%dx),%al
80106733:	89 c3                	mov    %eax,%ebx
80106735:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80106738:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
8010673c:	83 c4 14             	add    $0x14,%esp
8010673f:	5b                   	pop    %ebx
80106740:	5d                   	pop    %ebp
80106741:	c3                   	ret    

80106742 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106742:	55                   	push   %ebp
80106743:	89 e5                	mov    %esp,%ebp
80106745:	83 ec 08             	sub    $0x8,%esp
80106748:	8b 55 08             	mov    0x8(%ebp),%edx
8010674b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010674e:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106752:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106755:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106759:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010675d:	ee                   	out    %al,(%dx)
}
8010675e:	c9                   	leave  
8010675f:	c3                   	ret    

80106760 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106760:	55                   	push   %ebp
80106761:	89 e5                	mov    %esp,%ebp
80106763:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106766:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010676d:	00 
8010676e:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106775:	e8 c8 ff ff ff       	call   80106742 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
8010677a:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106781:	00 
80106782:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106789:	e8 b4 ff ff ff       	call   80106742 <outb>
  outb(COM1+0, 115200/9600);
8010678e:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106795:	00 
80106796:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010679d:	e8 a0 ff ff ff       	call   80106742 <outb>
  outb(COM1+1, 0);
801067a2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801067a9:	00 
801067aa:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801067b1:	e8 8c ff ff ff       	call   80106742 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
801067b6:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801067bd:	00 
801067be:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801067c5:	e8 78 ff ff ff       	call   80106742 <outb>
  outb(COM1+4, 0);
801067ca:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801067d1:	00 
801067d2:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
801067d9:	e8 64 ff ff ff       	call   80106742 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
801067de:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801067e5:	00 
801067e6:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801067ed:	e8 50 ff ff ff       	call   80106742 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
801067f2:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801067f9:	e8 1a ff ff ff       	call   80106718 <inb>
801067fe:	3c ff                	cmp    $0xff,%al
80106800:	74 6c                	je     8010686e <uartinit+0x10e>
    return;
  uart = 1;
80106802:	c7 05 4c b6 10 80 01 	movl   $0x1,0x8010b64c
80106809:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
8010680c:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106813:	e8 00 ff ff ff       	call   80106718 <inb>
  inb(COM1+0);
80106818:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010681f:	e8 f4 fe ff ff       	call   80106718 <inb>
  picenable(IRQ_COM1);
80106824:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010682b:	e8 ed d2 ff ff       	call   80103b1d <picenable>
  ioapicenable(IRQ_COM1, 0);
80106830:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106837:	00 
80106838:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010683f:	e8 7e c1 ff ff       	call   801029c2 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106844:	c7 45 f4 a8 87 10 80 	movl   $0x801087a8,-0xc(%ebp)
8010684b:	eb 15                	jmp    80106862 <uartinit+0x102>
    uartputc(*p);
8010684d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106850:	0f b6 00             	movzbl (%eax),%eax
80106853:	0f be c0             	movsbl %al,%eax
80106856:	89 04 24             	mov    %eax,(%esp)
80106859:	e8 13 00 00 00       	call   80106871 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
8010685e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106862:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106865:	0f b6 00             	movzbl (%eax),%eax
80106868:	84 c0                	test   %al,%al
8010686a:	75 e1                	jne    8010684d <uartinit+0xed>
8010686c:	eb 01                	jmp    8010686f <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
8010686e:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
8010686f:	c9                   	leave  
80106870:	c3                   	ret    

80106871 <uartputc>:

void
uartputc(int c)
{
80106871:	55                   	push   %ebp
80106872:	89 e5                	mov    %esp,%ebp
80106874:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80106877:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
8010687c:	85 c0                	test   %eax,%eax
8010687e:	74 4d                	je     801068cd <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106880:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106887:	eb 10                	jmp    80106899 <uartputc+0x28>
    microdelay(10);
80106889:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106890:	e8 c9 c6 ff ff       	call   80102f5e <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106895:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106899:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
8010689d:	7f 16                	jg     801068b5 <uartputc+0x44>
8010689f:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801068a6:	e8 6d fe ff ff       	call   80106718 <inb>
801068ab:	0f b6 c0             	movzbl %al,%eax
801068ae:	83 e0 20             	and    $0x20,%eax
801068b1:	85 c0                	test   %eax,%eax
801068b3:	74 d4                	je     80106889 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
801068b5:	8b 45 08             	mov    0x8(%ebp),%eax
801068b8:	0f b6 c0             	movzbl %al,%eax
801068bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801068bf:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801068c6:	e8 77 fe ff ff       	call   80106742 <outb>
801068cb:	eb 01                	jmp    801068ce <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
801068cd:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
801068ce:	c9                   	leave  
801068cf:	c3                   	ret    

801068d0 <uartgetc>:

static int
uartgetc(void)
{
801068d0:	55                   	push   %ebp
801068d1:	89 e5                	mov    %esp,%ebp
801068d3:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
801068d6:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
801068db:	85 c0                	test   %eax,%eax
801068dd:	75 07                	jne    801068e6 <uartgetc+0x16>
    return -1;
801068df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068e4:	eb 2c                	jmp    80106912 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
801068e6:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801068ed:	e8 26 fe ff ff       	call   80106718 <inb>
801068f2:	0f b6 c0             	movzbl %al,%eax
801068f5:	83 e0 01             	and    $0x1,%eax
801068f8:	85 c0                	test   %eax,%eax
801068fa:	75 07                	jne    80106903 <uartgetc+0x33>
    return -1;
801068fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106901:	eb 0f                	jmp    80106912 <uartgetc+0x42>
  return inb(COM1+0);
80106903:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010690a:	e8 09 fe ff ff       	call   80106718 <inb>
8010690f:	0f b6 c0             	movzbl %al,%eax
}
80106912:	c9                   	leave  
80106913:	c3                   	ret    

80106914 <uartintr>:

void
uartintr(void)
{
80106914:	55                   	push   %ebp
80106915:	89 e5                	mov    %esp,%ebp
80106917:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
8010691a:	c7 04 24 d0 68 10 80 	movl   $0x801068d0,(%esp)
80106921:	e8 90 9e ff ff       	call   801007b6 <consoleintr>
}
80106926:	c9                   	leave  
80106927:	c3                   	ret    

80106928 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106928:	6a 00                	push   $0x0
  pushl $0
8010692a:	6a 00                	push   $0x0
  jmp alltraps
8010692c:	e9 67 f9 ff ff       	jmp    80106298 <alltraps>

80106931 <vector1>:
.globl vector1
vector1:
  pushl $0
80106931:	6a 00                	push   $0x0
  pushl $1
80106933:	6a 01                	push   $0x1
  jmp alltraps
80106935:	e9 5e f9 ff ff       	jmp    80106298 <alltraps>

8010693a <vector2>:
.globl vector2
vector2:
  pushl $0
8010693a:	6a 00                	push   $0x0
  pushl $2
8010693c:	6a 02                	push   $0x2
  jmp alltraps
8010693e:	e9 55 f9 ff ff       	jmp    80106298 <alltraps>

80106943 <vector3>:
.globl vector3
vector3:
  pushl $0
80106943:	6a 00                	push   $0x0
  pushl $3
80106945:	6a 03                	push   $0x3
  jmp alltraps
80106947:	e9 4c f9 ff ff       	jmp    80106298 <alltraps>

8010694c <vector4>:
.globl vector4
vector4:
  pushl $0
8010694c:	6a 00                	push   $0x0
  pushl $4
8010694e:	6a 04                	push   $0x4
  jmp alltraps
80106950:	e9 43 f9 ff ff       	jmp    80106298 <alltraps>

80106955 <vector5>:
.globl vector5
vector5:
  pushl $0
80106955:	6a 00                	push   $0x0
  pushl $5
80106957:	6a 05                	push   $0x5
  jmp alltraps
80106959:	e9 3a f9 ff ff       	jmp    80106298 <alltraps>

8010695e <vector6>:
.globl vector6
vector6:
  pushl $0
8010695e:	6a 00                	push   $0x0
  pushl $6
80106960:	6a 06                	push   $0x6
  jmp alltraps
80106962:	e9 31 f9 ff ff       	jmp    80106298 <alltraps>

80106967 <vector7>:
.globl vector7
vector7:
  pushl $0
80106967:	6a 00                	push   $0x0
  pushl $7
80106969:	6a 07                	push   $0x7
  jmp alltraps
8010696b:	e9 28 f9 ff ff       	jmp    80106298 <alltraps>

80106970 <vector8>:
.globl vector8
vector8:
  pushl $8
80106970:	6a 08                	push   $0x8
  jmp alltraps
80106972:	e9 21 f9 ff ff       	jmp    80106298 <alltraps>

80106977 <vector9>:
.globl vector9
vector9:
  pushl $0
80106977:	6a 00                	push   $0x0
  pushl $9
80106979:	6a 09                	push   $0x9
  jmp alltraps
8010697b:	e9 18 f9 ff ff       	jmp    80106298 <alltraps>

80106980 <vector10>:
.globl vector10
vector10:
  pushl $10
80106980:	6a 0a                	push   $0xa
  jmp alltraps
80106982:	e9 11 f9 ff ff       	jmp    80106298 <alltraps>

80106987 <vector11>:
.globl vector11
vector11:
  pushl $11
80106987:	6a 0b                	push   $0xb
  jmp alltraps
80106989:	e9 0a f9 ff ff       	jmp    80106298 <alltraps>

8010698e <vector12>:
.globl vector12
vector12:
  pushl $12
8010698e:	6a 0c                	push   $0xc
  jmp alltraps
80106990:	e9 03 f9 ff ff       	jmp    80106298 <alltraps>

80106995 <vector13>:
.globl vector13
vector13:
  pushl $13
80106995:	6a 0d                	push   $0xd
  jmp alltraps
80106997:	e9 fc f8 ff ff       	jmp    80106298 <alltraps>

8010699c <vector14>:
.globl vector14
vector14:
  pushl $14
8010699c:	6a 0e                	push   $0xe
  jmp alltraps
8010699e:	e9 f5 f8 ff ff       	jmp    80106298 <alltraps>

801069a3 <vector15>:
.globl vector15
vector15:
  pushl $0
801069a3:	6a 00                	push   $0x0
  pushl $15
801069a5:	6a 0f                	push   $0xf
  jmp alltraps
801069a7:	e9 ec f8 ff ff       	jmp    80106298 <alltraps>

801069ac <vector16>:
.globl vector16
vector16:
  pushl $0
801069ac:	6a 00                	push   $0x0
  pushl $16
801069ae:	6a 10                	push   $0x10
  jmp alltraps
801069b0:	e9 e3 f8 ff ff       	jmp    80106298 <alltraps>

801069b5 <vector17>:
.globl vector17
vector17:
  pushl $17
801069b5:	6a 11                	push   $0x11
  jmp alltraps
801069b7:	e9 dc f8 ff ff       	jmp    80106298 <alltraps>

801069bc <vector18>:
.globl vector18
vector18:
  pushl $0
801069bc:	6a 00                	push   $0x0
  pushl $18
801069be:	6a 12                	push   $0x12
  jmp alltraps
801069c0:	e9 d3 f8 ff ff       	jmp    80106298 <alltraps>

801069c5 <vector19>:
.globl vector19
vector19:
  pushl $0
801069c5:	6a 00                	push   $0x0
  pushl $19
801069c7:	6a 13                	push   $0x13
  jmp alltraps
801069c9:	e9 ca f8 ff ff       	jmp    80106298 <alltraps>

801069ce <vector20>:
.globl vector20
vector20:
  pushl $0
801069ce:	6a 00                	push   $0x0
  pushl $20
801069d0:	6a 14                	push   $0x14
  jmp alltraps
801069d2:	e9 c1 f8 ff ff       	jmp    80106298 <alltraps>

801069d7 <vector21>:
.globl vector21
vector21:
  pushl $0
801069d7:	6a 00                	push   $0x0
  pushl $21
801069d9:	6a 15                	push   $0x15
  jmp alltraps
801069db:	e9 b8 f8 ff ff       	jmp    80106298 <alltraps>

801069e0 <vector22>:
.globl vector22
vector22:
  pushl $0
801069e0:	6a 00                	push   $0x0
  pushl $22
801069e2:	6a 16                	push   $0x16
  jmp alltraps
801069e4:	e9 af f8 ff ff       	jmp    80106298 <alltraps>

801069e9 <vector23>:
.globl vector23
vector23:
  pushl $0
801069e9:	6a 00                	push   $0x0
  pushl $23
801069eb:	6a 17                	push   $0x17
  jmp alltraps
801069ed:	e9 a6 f8 ff ff       	jmp    80106298 <alltraps>

801069f2 <vector24>:
.globl vector24
vector24:
  pushl $0
801069f2:	6a 00                	push   $0x0
  pushl $24
801069f4:	6a 18                	push   $0x18
  jmp alltraps
801069f6:	e9 9d f8 ff ff       	jmp    80106298 <alltraps>

801069fb <vector25>:
.globl vector25
vector25:
  pushl $0
801069fb:	6a 00                	push   $0x0
  pushl $25
801069fd:	6a 19                	push   $0x19
  jmp alltraps
801069ff:	e9 94 f8 ff ff       	jmp    80106298 <alltraps>

80106a04 <vector26>:
.globl vector26
vector26:
  pushl $0
80106a04:	6a 00                	push   $0x0
  pushl $26
80106a06:	6a 1a                	push   $0x1a
  jmp alltraps
80106a08:	e9 8b f8 ff ff       	jmp    80106298 <alltraps>

80106a0d <vector27>:
.globl vector27
vector27:
  pushl $0
80106a0d:	6a 00                	push   $0x0
  pushl $27
80106a0f:	6a 1b                	push   $0x1b
  jmp alltraps
80106a11:	e9 82 f8 ff ff       	jmp    80106298 <alltraps>

80106a16 <vector28>:
.globl vector28
vector28:
  pushl $0
80106a16:	6a 00                	push   $0x0
  pushl $28
80106a18:	6a 1c                	push   $0x1c
  jmp alltraps
80106a1a:	e9 79 f8 ff ff       	jmp    80106298 <alltraps>

80106a1f <vector29>:
.globl vector29
vector29:
  pushl $0
80106a1f:	6a 00                	push   $0x0
  pushl $29
80106a21:	6a 1d                	push   $0x1d
  jmp alltraps
80106a23:	e9 70 f8 ff ff       	jmp    80106298 <alltraps>

80106a28 <vector30>:
.globl vector30
vector30:
  pushl $0
80106a28:	6a 00                	push   $0x0
  pushl $30
80106a2a:	6a 1e                	push   $0x1e
  jmp alltraps
80106a2c:	e9 67 f8 ff ff       	jmp    80106298 <alltraps>

80106a31 <vector31>:
.globl vector31
vector31:
  pushl $0
80106a31:	6a 00                	push   $0x0
  pushl $31
80106a33:	6a 1f                	push   $0x1f
  jmp alltraps
80106a35:	e9 5e f8 ff ff       	jmp    80106298 <alltraps>

80106a3a <vector32>:
.globl vector32
vector32:
  pushl $0
80106a3a:	6a 00                	push   $0x0
  pushl $32
80106a3c:	6a 20                	push   $0x20
  jmp alltraps
80106a3e:	e9 55 f8 ff ff       	jmp    80106298 <alltraps>

80106a43 <vector33>:
.globl vector33
vector33:
  pushl $0
80106a43:	6a 00                	push   $0x0
  pushl $33
80106a45:	6a 21                	push   $0x21
  jmp alltraps
80106a47:	e9 4c f8 ff ff       	jmp    80106298 <alltraps>

80106a4c <vector34>:
.globl vector34
vector34:
  pushl $0
80106a4c:	6a 00                	push   $0x0
  pushl $34
80106a4e:	6a 22                	push   $0x22
  jmp alltraps
80106a50:	e9 43 f8 ff ff       	jmp    80106298 <alltraps>

80106a55 <vector35>:
.globl vector35
vector35:
  pushl $0
80106a55:	6a 00                	push   $0x0
  pushl $35
80106a57:	6a 23                	push   $0x23
  jmp alltraps
80106a59:	e9 3a f8 ff ff       	jmp    80106298 <alltraps>

80106a5e <vector36>:
.globl vector36
vector36:
  pushl $0
80106a5e:	6a 00                	push   $0x0
  pushl $36
80106a60:	6a 24                	push   $0x24
  jmp alltraps
80106a62:	e9 31 f8 ff ff       	jmp    80106298 <alltraps>

80106a67 <vector37>:
.globl vector37
vector37:
  pushl $0
80106a67:	6a 00                	push   $0x0
  pushl $37
80106a69:	6a 25                	push   $0x25
  jmp alltraps
80106a6b:	e9 28 f8 ff ff       	jmp    80106298 <alltraps>

80106a70 <vector38>:
.globl vector38
vector38:
  pushl $0
80106a70:	6a 00                	push   $0x0
  pushl $38
80106a72:	6a 26                	push   $0x26
  jmp alltraps
80106a74:	e9 1f f8 ff ff       	jmp    80106298 <alltraps>

80106a79 <vector39>:
.globl vector39
vector39:
  pushl $0
80106a79:	6a 00                	push   $0x0
  pushl $39
80106a7b:	6a 27                	push   $0x27
  jmp alltraps
80106a7d:	e9 16 f8 ff ff       	jmp    80106298 <alltraps>

80106a82 <vector40>:
.globl vector40
vector40:
  pushl $0
80106a82:	6a 00                	push   $0x0
  pushl $40
80106a84:	6a 28                	push   $0x28
  jmp alltraps
80106a86:	e9 0d f8 ff ff       	jmp    80106298 <alltraps>

80106a8b <vector41>:
.globl vector41
vector41:
  pushl $0
80106a8b:	6a 00                	push   $0x0
  pushl $41
80106a8d:	6a 29                	push   $0x29
  jmp alltraps
80106a8f:	e9 04 f8 ff ff       	jmp    80106298 <alltraps>

80106a94 <vector42>:
.globl vector42
vector42:
  pushl $0
80106a94:	6a 00                	push   $0x0
  pushl $42
80106a96:	6a 2a                	push   $0x2a
  jmp alltraps
80106a98:	e9 fb f7 ff ff       	jmp    80106298 <alltraps>

80106a9d <vector43>:
.globl vector43
vector43:
  pushl $0
80106a9d:	6a 00                	push   $0x0
  pushl $43
80106a9f:	6a 2b                	push   $0x2b
  jmp alltraps
80106aa1:	e9 f2 f7 ff ff       	jmp    80106298 <alltraps>

80106aa6 <vector44>:
.globl vector44
vector44:
  pushl $0
80106aa6:	6a 00                	push   $0x0
  pushl $44
80106aa8:	6a 2c                	push   $0x2c
  jmp alltraps
80106aaa:	e9 e9 f7 ff ff       	jmp    80106298 <alltraps>

80106aaf <vector45>:
.globl vector45
vector45:
  pushl $0
80106aaf:	6a 00                	push   $0x0
  pushl $45
80106ab1:	6a 2d                	push   $0x2d
  jmp alltraps
80106ab3:	e9 e0 f7 ff ff       	jmp    80106298 <alltraps>

80106ab8 <vector46>:
.globl vector46
vector46:
  pushl $0
80106ab8:	6a 00                	push   $0x0
  pushl $46
80106aba:	6a 2e                	push   $0x2e
  jmp alltraps
80106abc:	e9 d7 f7 ff ff       	jmp    80106298 <alltraps>

80106ac1 <vector47>:
.globl vector47
vector47:
  pushl $0
80106ac1:	6a 00                	push   $0x0
  pushl $47
80106ac3:	6a 2f                	push   $0x2f
  jmp alltraps
80106ac5:	e9 ce f7 ff ff       	jmp    80106298 <alltraps>

80106aca <vector48>:
.globl vector48
vector48:
  pushl $0
80106aca:	6a 00                	push   $0x0
  pushl $48
80106acc:	6a 30                	push   $0x30
  jmp alltraps
80106ace:	e9 c5 f7 ff ff       	jmp    80106298 <alltraps>

80106ad3 <vector49>:
.globl vector49
vector49:
  pushl $0
80106ad3:	6a 00                	push   $0x0
  pushl $49
80106ad5:	6a 31                	push   $0x31
  jmp alltraps
80106ad7:	e9 bc f7 ff ff       	jmp    80106298 <alltraps>

80106adc <vector50>:
.globl vector50
vector50:
  pushl $0
80106adc:	6a 00                	push   $0x0
  pushl $50
80106ade:	6a 32                	push   $0x32
  jmp alltraps
80106ae0:	e9 b3 f7 ff ff       	jmp    80106298 <alltraps>

80106ae5 <vector51>:
.globl vector51
vector51:
  pushl $0
80106ae5:	6a 00                	push   $0x0
  pushl $51
80106ae7:	6a 33                	push   $0x33
  jmp alltraps
80106ae9:	e9 aa f7 ff ff       	jmp    80106298 <alltraps>

80106aee <vector52>:
.globl vector52
vector52:
  pushl $0
80106aee:	6a 00                	push   $0x0
  pushl $52
80106af0:	6a 34                	push   $0x34
  jmp alltraps
80106af2:	e9 a1 f7 ff ff       	jmp    80106298 <alltraps>

80106af7 <vector53>:
.globl vector53
vector53:
  pushl $0
80106af7:	6a 00                	push   $0x0
  pushl $53
80106af9:	6a 35                	push   $0x35
  jmp alltraps
80106afb:	e9 98 f7 ff ff       	jmp    80106298 <alltraps>

80106b00 <vector54>:
.globl vector54
vector54:
  pushl $0
80106b00:	6a 00                	push   $0x0
  pushl $54
80106b02:	6a 36                	push   $0x36
  jmp alltraps
80106b04:	e9 8f f7 ff ff       	jmp    80106298 <alltraps>

80106b09 <vector55>:
.globl vector55
vector55:
  pushl $0
80106b09:	6a 00                	push   $0x0
  pushl $55
80106b0b:	6a 37                	push   $0x37
  jmp alltraps
80106b0d:	e9 86 f7 ff ff       	jmp    80106298 <alltraps>

80106b12 <vector56>:
.globl vector56
vector56:
  pushl $0
80106b12:	6a 00                	push   $0x0
  pushl $56
80106b14:	6a 38                	push   $0x38
  jmp alltraps
80106b16:	e9 7d f7 ff ff       	jmp    80106298 <alltraps>

80106b1b <vector57>:
.globl vector57
vector57:
  pushl $0
80106b1b:	6a 00                	push   $0x0
  pushl $57
80106b1d:	6a 39                	push   $0x39
  jmp alltraps
80106b1f:	e9 74 f7 ff ff       	jmp    80106298 <alltraps>

80106b24 <vector58>:
.globl vector58
vector58:
  pushl $0
80106b24:	6a 00                	push   $0x0
  pushl $58
80106b26:	6a 3a                	push   $0x3a
  jmp alltraps
80106b28:	e9 6b f7 ff ff       	jmp    80106298 <alltraps>

80106b2d <vector59>:
.globl vector59
vector59:
  pushl $0
80106b2d:	6a 00                	push   $0x0
  pushl $59
80106b2f:	6a 3b                	push   $0x3b
  jmp alltraps
80106b31:	e9 62 f7 ff ff       	jmp    80106298 <alltraps>

80106b36 <vector60>:
.globl vector60
vector60:
  pushl $0
80106b36:	6a 00                	push   $0x0
  pushl $60
80106b38:	6a 3c                	push   $0x3c
  jmp alltraps
80106b3a:	e9 59 f7 ff ff       	jmp    80106298 <alltraps>

80106b3f <vector61>:
.globl vector61
vector61:
  pushl $0
80106b3f:	6a 00                	push   $0x0
  pushl $61
80106b41:	6a 3d                	push   $0x3d
  jmp alltraps
80106b43:	e9 50 f7 ff ff       	jmp    80106298 <alltraps>

80106b48 <vector62>:
.globl vector62
vector62:
  pushl $0
80106b48:	6a 00                	push   $0x0
  pushl $62
80106b4a:	6a 3e                	push   $0x3e
  jmp alltraps
80106b4c:	e9 47 f7 ff ff       	jmp    80106298 <alltraps>

80106b51 <vector63>:
.globl vector63
vector63:
  pushl $0
80106b51:	6a 00                	push   $0x0
  pushl $63
80106b53:	6a 3f                	push   $0x3f
  jmp alltraps
80106b55:	e9 3e f7 ff ff       	jmp    80106298 <alltraps>

80106b5a <vector64>:
.globl vector64
vector64:
  pushl $0
80106b5a:	6a 00                	push   $0x0
  pushl $64
80106b5c:	6a 40                	push   $0x40
  jmp alltraps
80106b5e:	e9 35 f7 ff ff       	jmp    80106298 <alltraps>

80106b63 <vector65>:
.globl vector65
vector65:
  pushl $0
80106b63:	6a 00                	push   $0x0
  pushl $65
80106b65:	6a 41                	push   $0x41
  jmp alltraps
80106b67:	e9 2c f7 ff ff       	jmp    80106298 <alltraps>

80106b6c <vector66>:
.globl vector66
vector66:
  pushl $0
80106b6c:	6a 00                	push   $0x0
  pushl $66
80106b6e:	6a 42                	push   $0x42
  jmp alltraps
80106b70:	e9 23 f7 ff ff       	jmp    80106298 <alltraps>

80106b75 <vector67>:
.globl vector67
vector67:
  pushl $0
80106b75:	6a 00                	push   $0x0
  pushl $67
80106b77:	6a 43                	push   $0x43
  jmp alltraps
80106b79:	e9 1a f7 ff ff       	jmp    80106298 <alltraps>

80106b7e <vector68>:
.globl vector68
vector68:
  pushl $0
80106b7e:	6a 00                	push   $0x0
  pushl $68
80106b80:	6a 44                	push   $0x44
  jmp alltraps
80106b82:	e9 11 f7 ff ff       	jmp    80106298 <alltraps>

80106b87 <vector69>:
.globl vector69
vector69:
  pushl $0
80106b87:	6a 00                	push   $0x0
  pushl $69
80106b89:	6a 45                	push   $0x45
  jmp alltraps
80106b8b:	e9 08 f7 ff ff       	jmp    80106298 <alltraps>

80106b90 <vector70>:
.globl vector70
vector70:
  pushl $0
80106b90:	6a 00                	push   $0x0
  pushl $70
80106b92:	6a 46                	push   $0x46
  jmp alltraps
80106b94:	e9 ff f6 ff ff       	jmp    80106298 <alltraps>

80106b99 <vector71>:
.globl vector71
vector71:
  pushl $0
80106b99:	6a 00                	push   $0x0
  pushl $71
80106b9b:	6a 47                	push   $0x47
  jmp alltraps
80106b9d:	e9 f6 f6 ff ff       	jmp    80106298 <alltraps>

80106ba2 <vector72>:
.globl vector72
vector72:
  pushl $0
80106ba2:	6a 00                	push   $0x0
  pushl $72
80106ba4:	6a 48                	push   $0x48
  jmp alltraps
80106ba6:	e9 ed f6 ff ff       	jmp    80106298 <alltraps>

80106bab <vector73>:
.globl vector73
vector73:
  pushl $0
80106bab:	6a 00                	push   $0x0
  pushl $73
80106bad:	6a 49                	push   $0x49
  jmp alltraps
80106baf:	e9 e4 f6 ff ff       	jmp    80106298 <alltraps>

80106bb4 <vector74>:
.globl vector74
vector74:
  pushl $0
80106bb4:	6a 00                	push   $0x0
  pushl $74
80106bb6:	6a 4a                	push   $0x4a
  jmp alltraps
80106bb8:	e9 db f6 ff ff       	jmp    80106298 <alltraps>

80106bbd <vector75>:
.globl vector75
vector75:
  pushl $0
80106bbd:	6a 00                	push   $0x0
  pushl $75
80106bbf:	6a 4b                	push   $0x4b
  jmp alltraps
80106bc1:	e9 d2 f6 ff ff       	jmp    80106298 <alltraps>

80106bc6 <vector76>:
.globl vector76
vector76:
  pushl $0
80106bc6:	6a 00                	push   $0x0
  pushl $76
80106bc8:	6a 4c                	push   $0x4c
  jmp alltraps
80106bca:	e9 c9 f6 ff ff       	jmp    80106298 <alltraps>

80106bcf <vector77>:
.globl vector77
vector77:
  pushl $0
80106bcf:	6a 00                	push   $0x0
  pushl $77
80106bd1:	6a 4d                	push   $0x4d
  jmp alltraps
80106bd3:	e9 c0 f6 ff ff       	jmp    80106298 <alltraps>

80106bd8 <vector78>:
.globl vector78
vector78:
  pushl $0
80106bd8:	6a 00                	push   $0x0
  pushl $78
80106bda:	6a 4e                	push   $0x4e
  jmp alltraps
80106bdc:	e9 b7 f6 ff ff       	jmp    80106298 <alltraps>

80106be1 <vector79>:
.globl vector79
vector79:
  pushl $0
80106be1:	6a 00                	push   $0x0
  pushl $79
80106be3:	6a 4f                	push   $0x4f
  jmp alltraps
80106be5:	e9 ae f6 ff ff       	jmp    80106298 <alltraps>

80106bea <vector80>:
.globl vector80
vector80:
  pushl $0
80106bea:	6a 00                	push   $0x0
  pushl $80
80106bec:	6a 50                	push   $0x50
  jmp alltraps
80106bee:	e9 a5 f6 ff ff       	jmp    80106298 <alltraps>

80106bf3 <vector81>:
.globl vector81
vector81:
  pushl $0
80106bf3:	6a 00                	push   $0x0
  pushl $81
80106bf5:	6a 51                	push   $0x51
  jmp alltraps
80106bf7:	e9 9c f6 ff ff       	jmp    80106298 <alltraps>

80106bfc <vector82>:
.globl vector82
vector82:
  pushl $0
80106bfc:	6a 00                	push   $0x0
  pushl $82
80106bfe:	6a 52                	push   $0x52
  jmp alltraps
80106c00:	e9 93 f6 ff ff       	jmp    80106298 <alltraps>

80106c05 <vector83>:
.globl vector83
vector83:
  pushl $0
80106c05:	6a 00                	push   $0x0
  pushl $83
80106c07:	6a 53                	push   $0x53
  jmp alltraps
80106c09:	e9 8a f6 ff ff       	jmp    80106298 <alltraps>

80106c0e <vector84>:
.globl vector84
vector84:
  pushl $0
80106c0e:	6a 00                	push   $0x0
  pushl $84
80106c10:	6a 54                	push   $0x54
  jmp alltraps
80106c12:	e9 81 f6 ff ff       	jmp    80106298 <alltraps>

80106c17 <vector85>:
.globl vector85
vector85:
  pushl $0
80106c17:	6a 00                	push   $0x0
  pushl $85
80106c19:	6a 55                	push   $0x55
  jmp alltraps
80106c1b:	e9 78 f6 ff ff       	jmp    80106298 <alltraps>

80106c20 <vector86>:
.globl vector86
vector86:
  pushl $0
80106c20:	6a 00                	push   $0x0
  pushl $86
80106c22:	6a 56                	push   $0x56
  jmp alltraps
80106c24:	e9 6f f6 ff ff       	jmp    80106298 <alltraps>

80106c29 <vector87>:
.globl vector87
vector87:
  pushl $0
80106c29:	6a 00                	push   $0x0
  pushl $87
80106c2b:	6a 57                	push   $0x57
  jmp alltraps
80106c2d:	e9 66 f6 ff ff       	jmp    80106298 <alltraps>

80106c32 <vector88>:
.globl vector88
vector88:
  pushl $0
80106c32:	6a 00                	push   $0x0
  pushl $88
80106c34:	6a 58                	push   $0x58
  jmp alltraps
80106c36:	e9 5d f6 ff ff       	jmp    80106298 <alltraps>

80106c3b <vector89>:
.globl vector89
vector89:
  pushl $0
80106c3b:	6a 00                	push   $0x0
  pushl $89
80106c3d:	6a 59                	push   $0x59
  jmp alltraps
80106c3f:	e9 54 f6 ff ff       	jmp    80106298 <alltraps>

80106c44 <vector90>:
.globl vector90
vector90:
  pushl $0
80106c44:	6a 00                	push   $0x0
  pushl $90
80106c46:	6a 5a                	push   $0x5a
  jmp alltraps
80106c48:	e9 4b f6 ff ff       	jmp    80106298 <alltraps>

80106c4d <vector91>:
.globl vector91
vector91:
  pushl $0
80106c4d:	6a 00                	push   $0x0
  pushl $91
80106c4f:	6a 5b                	push   $0x5b
  jmp alltraps
80106c51:	e9 42 f6 ff ff       	jmp    80106298 <alltraps>

80106c56 <vector92>:
.globl vector92
vector92:
  pushl $0
80106c56:	6a 00                	push   $0x0
  pushl $92
80106c58:	6a 5c                	push   $0x5c
  jmp alltraps
80106c5a:	e9 39 f6 ff ff       	jmp    80106298 <alltraps>

80106c5f <vector93>:
.globl vector93
vector93:
  pushl $0
80106c5f:	6a 00                	push   $0x0
  pushl $93
80106c61:	6a 5d                	push   $0x5d
  jmp alltraps
80106c63:	e9 30 f6 ff ff       	jmp    80106298 <alltraps>

80106c68 <vector94>:
.globl vector94
vector94:
  pushl $0
80106c68:	6a 00                	push   $0x0
  pushl $94
80106c6a:	6a 5e                	push   $0x5e
  jmp alltraps
80106c6c:	e9 27 f6 ff ff       	jmp    80106298 <alltraps>

80106c71 <vector95>:
.globl vector95
vector95:
  pushl $0
80106c71:	6a 00                	push   $0x0
  pushl $95
80106c73:	6a 5f                	push   $0x5f
  jmp alltraps
80106c75:	e9 1e f6 ff ff       	jmp    80106298 <alltraps>

80106c7a <vector96>:
.globl vector96
vector96:
  pushl $0
80106c7a:	6a 00                	push   $0x0
  pushl $96
80106c7c:	6a 60                	push   $0x60
  jmp alltraps
80106c7e:	e9 15 f6 ff ff       	jmp    80106298 <alltraps>

80106c83 <vector97>:
.globl vector97
vector97:
  pushl $0
80106c83:	6a 00                	push   $0x0
  pushl $97
80106c85:	6a 61                	push   $0x61
  jmp alltraps
80106c87:	e9 0c f6 ff ff       	jmp    80106298 <alltraps>

80106c8c <vector98>:
.globl vector98
vector98:
  pushl $0
80106c8c:	6a 00                	push   $0x0
  pushl $98
80106c8e:	6a 62                	push   $0x62
  jmp alltraps
80106c90:	e9 03 f6 ff ff       	jmp    80106298 <alltraps>

80106c95 <vector99>:
.globl vector99
vector99:
  pushl $0
80106c95:	6a 00                	push   $0x0
  pushl $99
80106c97:	6a 63                	push   $0x63
  jmp alltraps
80106c99:	e9 fa f5 ff ff       	jmp    80106298 <alltraps>

80106c9e <vector100>:
.globl vector100
vector100:
  pushl $0
80106c9e:	6a 00                	push   $0x0
  pushl $100
80106ca0:	6a 64                	push   $0x64
  jmp alltraps
80106ca2:	e9 f1 f5 ff ff       	jmp    80106298 <alltraps>

80106ca7 <vector101>:
.globl vector101
vector101:
  pushl $0
80106ca7:	6a 00                	push   $0x0
  pushl $101
80106ca9:	6a 65                	push   $0x65
  jmp alltraps
80106cab:	e9 e8 f5 ff ff       	jmp    80106298 <alltraps>

80106cb0 <vector102>:
.globl vector102
vector102:
  pushl $0
80106cb0:	6a 00                	push   $0x0
  pushl $102
80106cb2:	6a 66                	push   $0x66
  jmp alltraps
80106cb4:	e9 df f5 ff ff       	jmp    80106298 <alltraps>

80106cb9 <vector103>:
.globl vector103
vector103:
  pushl $0
80106cb9:	6a 00                	push   $0x0
  pushl $103
80106cbb:	6a 67                	push   $0x67
  jmp alltraps
80106cbd:	e9 d6 f5 ff ff       	jmp    80106298 <alltraps>

80106cc2 <vector104>:
.globl vector104
vector104:
  pushl $0
80106cc2:	6a 00                	push   $0x0
  pushl $104
80106cc4:	6a 68                	push   $0x68
  jmp alltraps
80106cc6:	e9 cd f5 ff ff       	jmp    80106298 <alltraps>

80106ccb <vector105>:
.globl vector105
vector105:
  pushl $0
80106ccb:	6a 00                	push   $0x0
  pushl $105
80106ccd:	6a 69                	push   $0x69
  jmp alltraps
80106ccf:	e9 c4 f5 ff ff       	jmp    80106298 <alltraps>

80106cd4 <vector106>:
.globl vector106
vector106:
  pushl $0
80106cd4:	6a 00                	push   $0x0
  pushl $106
80106cd6:	6a 6a                	push   $0x6a
  jmp alltraps
80106cd8:	e9 bb f5 ff ff       	jmp    80106298 <alltraps>

80106cdd <vector107>:
.globl vector107
vector107:
  pushl $0
80106cdd:	6a 00                	push   $0x0
  pushl $107
80106cdf:	6a 6b                	push   $0x6b
  jmp alltraps
80106ce1:	e9 b2 f5 ff ff       	jmp    80106298 <alltraps>

80106ce6 <vector108>:
.globl vector108
vector108:
  pushl $0
80106ce6:	6a 00                	push   $0x0
  pushl $108
80106ce8:	6a 6c                	push   $0x6c
  jmp alltraps
80106cea:	e9 a9 f5 ff ff       	jmp    80106298 <alltraps>

80106cef <vector109>:
.globl vector109
vector109:
  pushl $0
80106cef:	6a 00                	push   $0x0
  pushl $109
80106cf1:	6a 6d                	push   $0x6d
  jmp alltraps
80106cf3:	e9 a0 f5 ff ff       	jmp    80106298 <alltraps>

80106cf8 <vector110>:
.globl vector110
vector110:
  pushl $0
80106cf8:	6a 00                	push   $0x0
  pushl $110
80106cfa:	6a 6e                	push   $0x6e
  jmp alltraps
80106cfc:	e9 97 f5 ff ff       	jmp    80106298 <alltraps>

80106d01 <vector111>:
.globl vector111
vector111:
  pushl $0
80106d01:	6a 00                	push   $0x0
  pushl $111
80106d03:	6a 6f                	push   $0x6f
  jmp alltraps
80106d05:	e9 8e f5 ff ff       	jmp    80106298 <alltraps>

80106d0a <vector112>:
.globl vector112
vector112:
  pushl $0
80106d0a:	6a 00                	push   $0x0
  pushl $112
80106d0c:	6a 70                	push   $0x70
  jmp alltraps
80106d0e:	e9 85 f5 ff ff       	jmp    80106298 <alltraps>

80106d13 <vector113>:
.globl vector113
vector113:
  pushl $0
80106d13:	6a 00                	push   $0x0
  pushl $113
80106d15:	6a 71                	push   $0x71
  jmp alltraps
80106d17:	e9 7c f5 ff ff       	jmp    80106298 <alltraps>

80106d1c <vector114>:
.globl vector114
vector114:
  pushl $0
80106d1c:	6a 00                	push   $0x0
  pushl $114
80106d1e:	6a 72                	push   $0x72
  jmp alltraps
80106d20:	e9 73 f5 ff ff       	jmp    80106298 <alltraps>

80106d25 <vector115>:
.globl vector115
vector115:
  pushl $0
80106d25:	6a 00                	push   $0x0
  pushl $115
80106d27:	6a 73                	push   $0x73
  jmp alltraps
80106d29:	e9 6a f5 ff ff       	jmp    80106298 <alltraps>

80106d2e <vector116>:
.globl vector116
vector116:
  pushl $0
80106d2e:	6a 00                	push   $0x0
  pushl $116
80106d30:	6a 74                	push   $0x74
  jmp alltraps
80106d32:	e9 61 f5 ff ff       	jmp    80106298 <alltraps>

80106d37 <vector117>:
.globl vector117
vector117:
  pushl $0
80106d37:	6a 00                	push   $0x0
  pushl $117
80106d39:	6a 75                	push   $0x75
  jmp alltraps
80106d3b:	e9 58 f5 ff ff       	jmp    80106298 <alltraps>

80106d40 <vector118>:
.globl vector118
vector118:
  pushl $0
80106d40:	6a 00                	push   $0x0
  pushl $118
80106d42:	6a 76                	push   $0x76
  jmp alltraps
80106d44:	e9 4f f5 ff ff       	jmp    80106298 <alltraps>

80106d49 <vector119>:
.globl vector119
vector119:
  pushl $0
80106d49:	6a 00                	push   $0x0
  pushl $119
80106d4b:	6a 77                	push   $0x77
  jmp alltraps
80106d4d:	e9 46 f5 ff ff       	jmp    80106298 <alltraps>

80106d52 <vector120>:
.globl vector120
vector120:
  pushl $0
80106d52:	6a 00                	push   $0x0
  pushl $120
80106d54:	6a 78                	push   $0x78
  jmp alltraps
80106d56:	e9 3d f5 ff ff       	jmp    80106298 <alltraps>

80106d5b <vector121>:
.globl vector121
vector121:
  pushl $0
80106d5b:	6a 00                	push   $0x0
  pushl $121
80106d5d:	6a 79                	push   $0x79
  jmp alltraps
80106d5f:	e9 34 f5 ff ff       	jmp    80106298 <alltraps>

80106d64 <vector122>:
.globl vector122
vector122:
  pushl $0
80106d64:	6a 00                	push   $0x0
  pushl $122
80106d66:	6a 7a                	push   $0x7a
  jmp alltraps
80106d68:	e9 2b f5 ff ff       	jmp    80106298 <alltraps>

80106d6d <vector123>:
.globl vector123
vector123:
  pushl $0
80106d6d:	6a 00                	push   $0x0
  pushl $123
80106d6f:	6a 7b                	push   $0x7b
  jmp alltraps
80106d71:	e9 22 f5 ff ff       	jmp    80106298 <alltraps>

80106d76 <vector124>:
.globl vector124
vector124:
  pushl $0
80106d76:	6a 00                	push   $0x0
  pushl $124
80106d78:	6a 7c                	push   $0x7c
  jmp alltraps
80106d7a:	e9 19 f5 ff ff       	jmp    80106298 <alltraps>

80106d7f <vector125>:
.globl vector125
vector125:
  pushl $0
80106d7f:	6a 00                	push   $0x0
  pushl $125
80106d81:	6a 7d                	push   $0x7d
  jmp alltraps
80106d83:	e9 10 f5 ff ff       	jmp    80106298 <alltraps>

80106d88 <vector126>:
.globl vector126
vector126:
  pushl $0
80106d88:	6a 00                	push   $0x0
  pushl $126
80106d8a:	6a 7e                	push   $0x7e
  jmp alltraps
80106d8c:	e9 07 f5 ff ff       	jmp    80106298 <alltraps>

80106d91 <vector127>:
.globl vector127
vector127:
  pushl $0
80106d91:	6a 00                	push   $0x0
  pushl $127
80106d93:	6a 7f                	push   $0x7f
  jmp alltraps
80106d95:	e9 fe f4 ff ff       	jmp    80106298 <alltraps>

80106d9a <vector128>:
.globl vector128
vector128:
  pushl $0
80106d9a:	6a 00                	push   $0x0
  pushl $128
80106d9c:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80106da1:	e9 f2 f4 ff ff       	jmp    80106298 <alltraps>

80106da6 <vector129>:
.globl vector129
vector129:
  pushl $0
80106da6:	6a 00                	push   $0x0
  pushl $129
80106da8:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80106dad:	e9 e6 f4 ff ff       	jmp    80106298 <alltraps>

80106db2 <vector130>:
.globl vector130
vector130:
  pushl $0
80106db2:	6a 00                	push   $0x0
  pushl $130
80106db4:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80106db9:	e9 da f4 ff ff       	jmp    80106298 <alltraps>

80106dbe <vector131>:
.globl vector131
vector131:
  pushl $0
80106dbe:	6a 00                	push   $0x0
  pushl $131
80106dc0:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80106dc5:	e9 ce f4 ff ff       	jmp    80106298 <alltraps>

80106dca <vector132>:
.globl vector132
vector132:
  pushl $0
80106dca:	6a 00                	push   $0x0
  pushl $132
80106dcc:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80106dd1:	e9 c2 f4 ff ff       	jmp    80106298 <alltraps>

80106dd6 <vector133>:
.globl vector133
vector133:
  pushl $0
80106dd6:	6a 00                	push   $0x0
  pushl $133
80106dd8:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80106ddd:	e9 b6 f4 ff ff       	jmp    80106298 <alltraps>

80106de2 <vector134>:
.globl vector134
vector134:
  pushl $0
80106de2:	6a 00                	push   $0x0
  pushl $134
80106de4:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80106de9:	e9 aa f4 ff ff       	jmp    80106298 <alltraps>

80106dee <vector135>:
.globl vector135
vector135:
  pushl $0
80106dee:	6a 00                	push   $0x0
  pushl $135
80106df0:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80106df5:	e9 9e f4 ff ff       	jmp    80106298 <alltraps>

80106dfa <vector136>:
.globl vector136
vector136:
  pushl $0
80106dfa:	6a 00                	push   $0x0
  pushl $136
80106dfc:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80106e01:	e9 92 f4 ff ff       	jmp    80106298 <alltraps>

80106e06 <vector137>:
.globl vector137
vector137:
  pushl $0
80106e06:	6a 00                	push   $0x0
  pushl $137
80106e08:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80106e0d:	e9 86 f4 ff ff       	jmp    80106298 <alltraps>

80106e12 <vector138>:
.globl vector138
vector138:
  pushl $0
80106e12:	6a 00                	push   $0x0
  pushl $138
80106e14:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80106e19:	e9 7a f4 ff ff       	jmp    80106298 <alltraps>

80106e1e <vector139>:
.globl vector139
vector139:
  pushl $0
80106e1e:	6a 00                	push   $0x0
  pushl $139
80106e20:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80106e25:	e9 6e f4 ff ff       	jmp    80106298 <alltraps>

80106e2a <vector140>:
.globl vector140
vector140:
  pushl $0
80106e2a:	6a 00                	push   $0x0
  pushl $140
80106e2c:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80106e31:	e9 62 f4 ff ff       	jmp    80106298 <alltraps>

80106e36 <vector141>:
.globl vector141
vector141:
  pushl $0
80106e36:	6a 00                	push   $0x0
  pushl $141
80106e38:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80106e3d:	e9 56 f4 ff ff       	jmp    80106298 <alltraps>

80106e42 <vector142>:
.globl vector142
vector142:
  pushl $0
80106e42:	6a 00                	push   $0x0
  pushl $142
80106e44:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80106e49:	e9 4a f4 ff ff       	jmp    80106298 <alltraps>

80106e4e <vector143>:
.globl vector143
vector143:
  pushl $0
80106e4e:	6a 00                	push   $0x0
  pushl $143
80106e50:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80106e55:	e9 3e f4 ff ff       	jmp    80106298 <alltraps>

80106e5a <vector144>:
.globl vector144
vector144:
  pushl $0
80106e5a:	6a 00                	push   $0x0
  pushl $144
80106e5c:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80106e61:	e9 32 f4 ff ff       	jmp    80106298 <alltraps>

80106e66 <vector145>:
.globl vector145
vector145:
  pushl $0
80106e66:	6a 00                	push   $0x0
  pushl $145
80106e68:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80106e6d:	e9 26 f4 ff ff       	jmp    80106298 <alltraps>

80106e72 <vector146>:
.globl vector146
vector146:
  pushl $0
80106e72:	6a 00                	push   $0x0
  pushl $146
80106e74:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80106e79:	e9 1a f4 ff ff       	jmp    80106298 <alltraps>

80106e7e <vector147>:
.globl vector147
vector147:
  pushl $0
80106e7e:	6a 00                	push   $0x0
  pushl $147
80106e80:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80106e85:	e9 0e f4 ff ff       	jmp    80106298 <alltraps>

80106e8a <vector148>:
.globl vector148
vector148:
  pushl $0
80106e8a:	6a 00                	push   $0x0
  pushl $148
80106e8c:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80106e91:	e9 02 f4 ff ff       	jmp    80106298 <alltraps>

80106e96 <vector149>:
.globl vector149
vector149:
  pushl $0
80106e96:	6a 00                	push   $0x0
  pushl $149
80106e98:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80106e9d:	e9 f6 f3 ff ff       	jmp    80106298 <alltraps>

80106ea2 <vector150>:
.globl vector150
vector150:
  pushl $0
80106ea2:	6a 00                	push   $0x0
  pushl $150
80106ea4:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80106ea9:	e9 ea f3 ff ff       	jmp    80106298 <alltraps>

80106eae <vector151>:
.globl vector151
vector151:
  pushl $0
80106eae:	6a 00                	push   $0x0
  pushl $151
80106eb0:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80106eb5:	e9 de f3 ff ff       	jmp    80106298 <alltraps>

80106eba <vector152>:
.globl vector152
vector152:
  pushl $0
80106eba:	6a 00                	push   $0x0
  pushl $152
80106ebc:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80106ec1:	e9 d2 f3 ff ff       	jmp    80106298 <alltraps>

80106ec6 <vector153>:
.globl vector153
vector153:
  pushl $0
80106ec6:	6a 00                	push   $0x0
  pushl $153
80106ec8:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80106ecd:	e9 c6 f3 ff ff       	jmp    80106298 <alltraps>

80106ed2 <vector154>:
.globl vector154
vector154:
  pushl $0
80106ed2:	6a 00                	push   $0x0
  pushl $154
80106ed4:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80106ed9:	e9 ba f3 ff ff       	jmp    80106298 <alltraps>

80106ede <vector155>:
.globl vector155
vector155:
  pushl $0
80106ede:	6a 00                	push   $0x0
  pushl $155
80106ee0:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80106ee5:	e9 ae f3 ff ff       	jmp    80106298 <alltraps>

80106eea <vector156>:
.globl vector156
vector156:
  pushl $0
80106eea:	6a 00                	push   $0x0
  pushl $156
80106eec:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80106ef1:	e9 a2 f3 ff ff       	jmp    80106298 <alltraps>

80106ef6 <vector157>:
.globl vector157
vector157:
  pushl $0
80106ef6:	6a 00                	push   $0x0
  pushl $157
80106ef8:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80106efd:	e9 96 f3 ff ff       	jmp    80106298 <alltraps>

80106f02 <vector158>:
.globl vector158
vector158:
  pushl $0
80106f02:	6a 00                	push   $0x0
  pushl $158
80106f04:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80106f09:	e9 8a f3 ff ff       	jmp    80106298 <alltraps>

80106f0e <vector159>:
.globl vector159
vector159:
  pushl $0
80106f0e:	6a 00                	push   $0x0
  pushl $159
80106f10:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80106f15:	e9 7e f3 ff ff       	jmp    80106298 <alltraps>

80106f1a <vector160>:
.globl vector160
vector160:
  pushl $0
80106f1a:	6a 00                	push   $0x0
  pushl $160
80106f1c:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80106f21:	e9 72 f3 ff ff       	jmp    80106298 <alltraps>

80106f26 <vector161>:
.globl vector161
vector161:
  pushl $0
80106f26:	6a 00                	push   $0x0
  pushl $161
80106f28:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80106f2d:	e9 66 f3 ff ff       	jmp    80106298 <alltraps>

80106f32 <vector162>:
.globl vector162
vector162:
  pushl $0
80106f32:	6a 00                	push   $0x0
  pushl $162
80106f34:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80106f39:	e9 5a f3 ff ff       	jmp    80106298 <alltraps>

80106f3e <vector163>:
.globl vector163
vector163:
  pushl $0
80106f3e:	6a 00                	push   $0x0
  pushl $163
80106f40:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80106f45:	e9 4e f3 ff ff       	jmp    80106298 <alltraps>

80106f4a <vector164>:
.globl vector164
vector164:
  pushl $0
80106f4a:	6a 00                	push   $0x0
  pushl $164
80106f4c:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80106f51:	e9 42 f3 ff ff       	jmp    80106298 <alltraps>

80106f56 <vector165>:
.globl vector165
vector165:
  pushl $0
80106f56:	6a 00                	push   $0x0
  pushl $165
80106f58:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80106f5d:	e9 36 f3 ff ff       	jmp    80106298 <alltraps>

80106f62 <vector166>:
.globl vector166
vector166:
  pushl $0
80106f62:	6a 00                	push   $0x0
  pushl $166
80106f64:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80106f69:	e9 2a f3 ff ff       	jmp    80106298 <alltraps>

80106f6e <vector167>:
.globl vector167
vector167:
  pushl $0
80106f6e:	6a 00                	push   $0x0
  pushl $167
80106f70:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80106f75:	e9 1e f3 ff ff       	jmp    80106298 <alltraps>

80106f7a <vector168>:
.globl vector168
vector168:
  pushl $0
80106f7a:	6a 00                	push   $0x0
  pushl $168
80106f7c:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80106f81:	e9 12 f3 ff ff       	jmp    80106298 <alltraps>

80106f86 <vector169>:
.globl vector169
vector169:
  pushl $0
80106f86:	6a 00                	push   $0x0
  pushl $169
80106f88:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80106f8d:	e9 06 f3 ff ff       	jmp    80106298 <alltraps>

80106f92 <vector170>:
.globl vector170
vector170:
  pushl $0
80106f92:	6a 00                	push   $0x0
  pushl $170
80106f94:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80106f99:	e9 fa f2 ff ff       	jmp    80106298 <alltraps>

80106f9e <vector171>:
.globl vector171
vector171:
  pushl $0
80106f9e:	6a 00                	push   $0x0
  pushl $171
80106fa0:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80106fa5:	e9 ee f2 ff ff       	jmp    80106298 <alltraps>

80106faa <vector172>:
.globl vector172
vector172:
  pushl $0
80106faa:	6a 00                	push   $0x0
  pushl $172
80106fac:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80106fb1:	e9 e2 f2 ff ff       	jmp    80106298 <alltraps>

80106fb6 <vector173>:
.globl vector173
vector173:
  pushl $0
80106fb6:	6a 00                	push   $0x0
  pushl $173
80106fb8:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80106fbd:	e9 d6 f2 ff ff       	jmp    80106298 <alltraps>

80106fc2 <vector174>:
.globl vector174
vector174:
  pushl $0
80106fc2:	6a 00                	push   $0x0
  pushl $174
80106fc4:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80106fc9:	e9 ca f2 ff ff       	jmp    80106298 <alltraps>

80106fce <vector175>:
.globl vector175
vector175:
  pushl $0
80106fce:	6a 00                	push   $0x0
  pushl $175
80106fd0:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80106fd5:	e9 be f2 ff ff       	jmp    80106298 <alltraps>

80106fda <vector176>:
.globl vector176
vector176:
  pushl $0
80106fda:	6a 00                	push   $0x0
  pushl $176
80106fdc:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80106fe1:	e9 b2 f2 ff ff       	jmp    80106298 <alltraps>

80106fe6 <vector177>:
.globl vector177
vector177:
  pushl $0
80106fe6:	6a 00                	push   $0x0
  pushl $177
80106fe8:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80106fed:	e9 a6 f2 ff ff       	jmp    80106298 <alltraps>

80106ff2 <vector178>:
.globl vector178
vector178:
  pushl $0
80106ff2:	6a 00                	push   $0x0
  pushl $178
80106ff4:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80106ff9:	e9 9a f2 ff ff       	jmp    80106298 <alltraps>

80106ffe <vector179>:
.globl vector179
vector179:
  pushl $0
80106ffe:	6a 00                	push   $0x0
  pushl $179
80107000:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107005:	e9 8e f2 ff ff       	jmp    80106298 <alltraps>

8010700a <vector180>:
.globl vector180
vector180:
  pushl $0
8010700a:	6a 00                	push   $0x0
  pushl $180
8010700c:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107011:	e9 82 f2 ff ff       	jmp    80106298 <alltraps>

80107016 <vector181>:
.globl vector181
vector181:
  pushl $0
80107016:	6a 00                	push   $0x0
  pushl $181
80107018:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
8010701d:	e9 76 f2 ff ff       	jmp    80106298 <alltraps>

80107022 <vector182>:
.globl vector182
vector182:
  pushl $0
80107022:	6a 00                	push   $0x0
  pushl $182
80107024:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107029:	e9 6a f2 ff ff       	jmp    80106298 <alltraps>

8010702e <vector183>:
.globl vector183
vector183:
  pushl $0
8010702e:	6a 00                	push   $0x0
  pushl $183
80107030:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107035:	e9 5e f2 ff ff       	jmp    80106298 <alltraps>

8010703a <vector184>:
.globl vector184
vector184:
  pushl $0
8010703a:	6a 00                	push   $0x0
  pushl $184
8010703c:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107041:	e9 52 f2 ff ff       	jmp    80106298 <alltraps>

80107046 <vector185>:
.globl vector185
vector185:
  pushl $0
80107046:	6a 00                	push   $0x0
  pushl $185
80107048:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
8010704d:	e9 46 f2 ff ff       	jmp    80106298 <alltraps>

80107052 <vector186>:
.globl vector186
vector186:
  pushl $0
80107052:	6a 00                	push   $0x0
  pushl $186
80107054:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107059:	e9 3a f2 ff ff       	jmp    80106298 <alltraps>

8010705e <vector187>:
.globl vector187
vector187:
  pushl $0
8010705e:	6a 00                	push   $0x0
  pushl $187
80107060:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107065:	e9 2e f2 ff ff       	jmp    80106298 <alltraps>

8010706a <vector188>:
.globl vector188
vector188:
  pushl $0
8010706a:	6a 00                	push   $0x0
  pushl $188
8010706c:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107071:	e9 22 f2 ff ff       	jmp    80106298 <alltraps>

80107076 <vector189>:
.globl vector189
vector189:
  pushl $0
80107076:	6a 00                	push   $0x0
  pushl $189
80107078:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
8010707d:	e9 16 f2 ff ff       	jmp    80106298 <alltraps>

80107082 <vector190>:
.globl vector190
vector190:
  pushl $0
80107082:	6a 00                	push   $0x0
  pushl $190
80107084:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107089:	e9 0a f2 ff ff       	jmp    80106298 <alltraps>

8010708e <vector191>:
.globl vector191
vector191:
  pushl $0
8010708e:	6a 00                	push   $0x0
  pushl $191
80107090:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107095:	e9 fe f1 ff ff       	jmp    80106298 <alltraps>

8010709a <vector192>:
.globl vector192
vector192:
  pushl $0
8010709a:	6a 00                	push   $0x0
  pushl $192
8010709c:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
801070a1:	e9 f2 f1 ff ff       	jmp    80106298 <alltraps>

801070a6 <vector193>:
.globl vector193
vector193:
  pushl $0
801070a6:	6a 00                	push   $0x0
  pushl $193
801070a8:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801070ad:	e9 e6 f1 ff ff       	jmp    80106298 <alltraps>

801070b2 <vector194>:
.globl vector194
vector194:
  pushl $0
801070b2:	6a 00                	push   $0x0
  pushl $194
801070b4:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801070b9:	e9 da f1 ff ff       	jmp    80106298 <alltraps>

801070be <vector195>:
.globl vector195
vector195:
  pushl $0
801070be:	6a 00                	push   $0x0
  pushl $195
801070c0:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
801070c5:	e9 ce f1 ff ff       	jmp    80106298 <alltraps>

801070ca <vector196>:
.globl vector196
vector196:
  pushl $0
801070ca:	6a 00                	push   $0x0
  pushl $196
801070cc:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
801070d1:	e9 c2 f1 ff ff       	jmp    80106298 <alltraps>

801070d6 <vector197>:
.globl vector197
vector197:
  pushl $0
801070d6:	6a 00                	push   $0x0
  pushl $197
801070d8:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801070dd:	e9 b6 f1 ff ff       	jmp    80106298 <alltraps>

801070e2 <vector198>:
.globl vector198
vector198:
  pushl $0
801070e2:	6a 00                	push   $0x0
  pushl $198
801070e4:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801070e9:	e9 aa f1 ff ff       	jmp    80106298 <alltraps>

801070ee <vector199>:
.globl vector199
vector199:
  pushl $0
801070ee:	6a 00                	push   $0x0
  pushl $199
801070f0:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801070f5:	e9 9e f1 ff ff       	jmp    80106298 <alltraps>

801070fa <vector200>:
.globl vector200
vector200:
  pushl $0
801070fa:	6a 00                	push   $0x0
  pushl $200
801070fc:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107101:	e9 92 f1 ff ff       	jmp    80106298 <alltraps>

80107106 <vector201>:
.globl vector201
vector201:
  pushl $0
80107106:	6a 00                	push   $0x0
  pushl $201
80107108:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
8010710d:	e9 86 f1 ff ff       	jmp    80106298 <alltraps>

80107112 <vector202>:
.globl vector202
vector202:
  pushl $0
80107112:	6a 00                	push   $0x0
  pushl $202
80107114:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107119:	e9 7a f1 ff ff       	jmp    80106298 <alltraps>

8010711e <vector203>:
.globl vector203
vector203:
  pushl $0
8010711e:	6a 00                	push   $0x0
  pushl $203
80107120:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107125:	e9 6e f1 ff ff       	jmp    80106298 <alltraps>

8010712a <vector204>:
.globl vector204
vector204:
  pushl $0
8010712a:	6a 00                	push   $0x0
  pushl $204
8010712c:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107131:	e9 62 f1 ff ff       	jmp    80106298 <alltraps>

80107136 <vector205>:
.globl vector205
vector205:
  pushl $0
80107136:	6a 00                	push   $0x0
  pushl $205
80107138:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
8010713d:	e9 56 f1 ff ff       	jmp    80106298 <alltraps>

80107142 <vector206>:
.globl vector206
vector206:
  pushl $0
80107142:	6a 00                	push   $0x0
  pushl $206
80107144:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107149:	e9 4a f1 ff ff       	jmp    80106298 <alltraps>

8010714e <vector207>:
.globl vector207
vector207:
  pushl $0
8010714e:	6a 00                	push   $0x0
  pushl $207
80107150:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107155:	e9 3e f1 ff ff       	jmp    80106298 <alltraps>

8010715a <vector208>:
.globl vector208
vector208:
  pushl $0
8010715a:	6a 00                	push   $0x0
  pushl $208
8010715c:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107161:	e9 32 f1 ff ff       	jmp    80106298 <alltraps>

80107166 <vector209>:
.globl vector209
vector209:
  pushl $0
80107166:	6a 00                	push   $0x0
  pushl $209
80107168:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
8010716d:	e9 26 f1 ff ff       	jmp    80106298 <alltraps>

80107172 <vector210>:
.globl vector210
vector210:
  pushl $0
80107172:	6a 00                	push   $0x0
  pushl $210
80107174:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107179:	e9 1a f1 ff ff       	jmp    80106298 <alltraps>

8010717e <vector211>:
.globl vector211
vector211:
  pushl $0
8010717e:	6a 00                	push   $0x0
  pushl $211
80107180:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107185:	e9 0e f1 ff ff       	jmp    80106298 <alltraps>

8010718a <vector212>:
.globl vector212
vector212:
  pushl $0
8010718a:	6a 00                	push   $0x0
  pushl $212
8010718c:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107191:	e9 02 f1 ff ff       	jmp    80106298 <alltraps>

80107196 <vector213>:
.globl vector213
vector213:
  pushl $0
80107196:	6a 00                	push   $0x0
  pushl $213
80107198:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
8010719d:	e9 f6 f0 ff ff       	jmp    80106298 <alltraps>

801071a2 <vector214>:
.globl vector214
vector214:
  pushl $0
801071a2:	6a 00                	push   $0x0
  pushl $214
801071a4:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
801071a9:	e9 ea f0 ff ff       	jmp    80106298 <alltraps>

801071ae <vector215>:
.globl vector215
vector215:
  pushl $0
801071ae:	6a 00                	push   $0x0
  pushl $215
801071b0:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
801071b5:	e9 de f0 ff ff       	jmp    80106298 <alltraps>

801071ba <vector216>:
.globl vector216
vector216:
  pushl $0
801071ba:	6a 00                	push   $0x0
  pushl $216
801071bc:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
801071c1:	e9 d2 f0 ff ff       	jmp    80106298 <alltraps>

801071c6 <vector217>:
.globl vector217
vector217:
  pushl $0
801071c6:	6a 00                	push   $0x0
  pushl $217
801071c8:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
801071cd:	e9 c6 f0 ff ff       	jmp    80106298 <alltraps>

801071d2 <vector218>:
.globl vector218
vector218:
  pushl $0
801071d2:	6a 00                	push   $0x0
  pushl $218
801071d4:	68 da 00 00 00       	push   $0xda
  jmp alltraps
801071d9:	e9 ba f0 ff ff       	jmp    80106298 <alltraps>

801071de <vector219>:
.globl vector219
vector219:
  pushl $0
801071de:	6a 00                	push   $0x0
  pushl $219
801071e0:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
801071e5:	e9 ae f0 ff ff       	jmp    80106298 <alltraps>

801071ea <vector220>:
.globl vector220
vector220:
  pushl $0
801071ea:	6a 00                	push   $0x0
  pushl $220
801071ec:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801071f1:	e9 a2 f0 ff ff       	jmp    80106298 <alltraps>

801071f6 <vector221>:
.globl vector221
vector221:
  pushl $0
801071f6:	6a 00                	push   $0x0
  pushl $221
801071f8:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801071fd:	e9 96 f0 ff ff       	jmp    80106298 <alltraps>

80107202 <vector222>:
.globl vector222
vector222:
  pushl $0
80107202:	6a 00                	push   $0x0
  pushl $222
80107204:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107209:	e9 8a f0 ff ff       	jmp    80106298 <alltraps>

8010720e <vector223>:
.globl vector223
vector223:
  pushl $0
8010720e:	6a 00                	push   $0x0
  pushl $223
80107210:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107215:	e9 7e f0 ff ff       	jmp    80106298 <alltraps>

8010721a <vector224>:
.globl vector224
vector224:
  pushl $0
8010721a:	6a 00                	push   $0x0
  pushl $224
8010721c:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107221:	e9 72 f0 ff ff       	jmp    80106298 <alltraps>

80107226 <vector225>:
.globl vector225
vector225:
  pushl $0
80107226:	6a 00                	push   $0x0
  pushl $225
80107228:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
8010722d:	e9 66 f0 ff ff       	jmp    80106298 <alltraps>

80107232 <vector226>:
.globl vector226
vector226:
  pushl $0
80107232:	6a 00                	push   $0x0
  pushl $226
80107234:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107239:	e9 5a f0 ff ff       	jmp    80106298 <alltraps>

8010723e <vector227>:
.globl vector227
vector227:
  pushl $0
8010723e:	6a 00                	push   $0x0
  pushl $227
80107240:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107245:	e9 4e f0 ff ff       	jmp    80106298 <alltraps>

8010724a <vector228>:
.globl vector228
vector228:
  pushl $0
8010724a:	6a 00                	push   $0x0
  pushl $228
8010724c:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107251:	e9 42 f0 ff ff       	jmp    80106298 <alltraps>

80107256 <vector229>:
.globl vector229
vector229:
  pushl $0
80107256:	6a 00                	push   $0x0
  pushl $229
80107258:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
8010725d:	e9 36 f0 ff ff       	jmp    80106298 <alltraps>

80107262 <vector230>:
.globl vector230
vector230:
  pushl $0
80107262:	6a 00                	push   $0x0
  pushl $230
80107264:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107269:	e9 2a f0 ff ff       	jmp    80106298 <alltraps>

8010726e <vector231>:
.globl vector231
vector231:
  pushl $0
8010726e:	6a 00                	push   $0x0
  pushl $231
80107270:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107275:	e9 1e f0 ff ff       	jmp    80106298 <alltraps>

8010727a <vector232>:
.globl vector232
vector232:
  pushl $0
8010727a:	6a 00                	push   $0x0
  pushl $232
8010727c:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107281:	e9 12 f0 ff ff       	jmp    80106298 <alltraps>

80107286 <vector233>:
.globl vector233
vector233:
  pushl $0
80107286:	6a 00                	push   $0x0
  pushl $233
80107288:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
8010728d:	e9 06 f0 ff ff       	jmp    80106298 <alltraps>

80107292 <vector234>:
.globl vector234
vector234:
  pushl $0
80107292:	6a 00                	push   $0x0
  pushl $234
80107294:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107299:	e9 fa ef ff ff       	jmp    80106298 <alltraps>

8010729e <vector235>:
.globl vector235
vector235:
  pushl $0
8010729e:	6a 00                	push   $0x0
  pushl $235
801072a0:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
801072a5:	e9 ee ef ff ff       	jmp    80106298 <alltraps>

801072aa <vector236>:
.globl vector236
vector236:
  pushl $0
801072aa:	6a 00                	push   $0x0
  pushl $236
801072ac:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
801072b1:	e9 e2 ef ff ff       	jmp    80106298 <alltraps>

801072b6 <vector237>:
.globl vector237
vector237:
  pushl $0
801072b6:	6a 00                	push   $0x0
  pushl $237
801072b8:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
801072bd:	e9 d6 ef ff ff       	jmp    80106298 <alltraps>

801072c2 <vector238>:
.globl vector238
vector238:
  pushl $0
801072c2:	6a 00                	push   $0x0
  pushl $238
801072c4:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
801072c9:	e9 ca ef ff ff       	jmp    80106298 <alltraps>

801072ce <vector239>:
.globl vector239
vector239:
  pushl $0
801072ce:	6a 00                	push   $0x0
  pushl $239
801072d0:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
801072d5:	e9 be ef ff ff       	jmp    80106298 <alltraps>

801072da <vector240>:
.globl vector240
vector240:
  pushl $0
801072da:	6a 00                	push   $0x0
  pushl $240
801072dc:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
801072e1:	e9 b2 ef ff ff       	jmp    80106298 <alltraps>

801072e6 <vector241>:
.globl vector241
vector241:
  pushl $0
801072e6:	6a 00                	push   $0x0
  pushl $241
801072e8:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801072ed:	e9 a6 ef ff ff       	jmp    80106298 <alltraps>

801072f2 <vector242>:
.globl vector242
vector242:
  pushl $0
801072f2:	6a 00                	push   $0x0
  pushl $242
801072f4:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801072f9:	e9 9a ef ff ff       	jmp    80106298 <alltraps>

801072fe <vector243>:
.globl vector243
vector243:
  pushl $0
801072fe:	6a 00                	push   $0x0
  pushl $243
80107300:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107305:	e9 8e ef ff ff       	jmp    80106298 <alltraps>

8010730a <vector244>:
.globl vector244
vector244:
  pushl $0
8010730a:	6a 00                	push   $0x0
  pushl $244
8010730c:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107311:	e9 82 ef ff ff       	jmp    80106298 <alltraps>

80107316 <vector245>:
.globl vector245
vector245:
  pushl $0
80107316:	6a 00                	push   $0x0
  pushl $245
80107318:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
8010731d:	e9 76 ef ff ff       	jmp    80106298 <alltraps>

80107322 <vector246>:
.globl vector246
vector246:
  pushl $0
80107322:	6a 00                	push   $0x0
  pushl $246
80107324:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107329:	e9 6a ef ff ff       	jmp    80106298 <alltraps>

8010732e <vector247>:
.globl vector247
vector247:
  pushl $0
8010732e:	6a 00                	push   $0x0
  pushl $247
80107330:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107335:	e9 5e ef ff ff       	jmp    80106298 <alltraps>

8010733a <vector248>:
.globl vector248
vector248:
  pushl $0
8010733a:	6a 00                	push   $0x0
  pushl $248
8010733c:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107341:	e9 52 ef ff ff       	jmp    80106298 <alltraps>

80107346 <vector249>:
.globl vector249
vector249:
  pushl $0
80107346:	6a 00                	push   $0x0
  pushl $249
80107348:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
8010734d:	e9 46 ef ff ff       	jmp    80106298 <alltraps>

80107352 <vector250>:
.globl vector250
vector250:
  pushl $0
80107352:	6a 00                	push   $0x0
  pushl $250
80107354:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107359:	e9 3a ef ff ff       	jmp    80106298 <alltraps>

8010735e <vector251>:
.globl vector251
vector251:
  pushl $0
8010735e:	6a 00                	push   $0x0
  pushl $251
80107360:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107365:	e9 2e ef ff ff       	jmp    80106298 <alltraps>

8010736a <vector252>:
.globl vector252
vector252:
  pushl $0
8010736a:	6a 00                	push   $0x0
  pushl $252
8010736c:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107371:	e9 22 ef ff ff       	jmp    80106298 <alltraps>

80107376 <vector253>:
.globl vector253
vector253:
  pushl $0
80107376:	6a 00                	push   $0x0
  pushl $253
80107378:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
8010737d:	e9 16 ef ff ff       	jmp    80106298 <alltraps>

80107382 <vector254>:
.globl vector254
vector254:
  pushl $0
80107382:	6a 00                	push   $0x0
  pushl $254
80107384:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107389:	e9 0a ef ff ff       	jmp    80106298 <alltraps>

8010738e <vector255>:
.globl vector255
vector255:
  pushl $0
8010738e:	6a 00                	push   $0x0
  pushl $255
80107390:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107395:	e9 fe ee ff ff       	jmp    80106298 <alltraps>
8010739a:	66 90                	xchg   %ax,%ax

8010739c <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
8010739c:	55                   	push   %ebp
8010739d:	89 e5                	mov    %esp,%ebp
8010739f:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801073a2:	8b 45 0c             	mov    0xc(%ebp),%eax
801073a5:	83 e8 01             	sub    $0x1,%eax
801073a8:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801073ac:	8b 45 08             	mov    0x8(%ebp),%eax
801073af:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801073b3:	8b 45 08             	mov    0x8(%ebp),%eax
801073b6:	c1 e8 10             	shr    $0x10,%eax
801073b9:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
801073bd:	8d 45 fa             	lea    -0x6(%ebp),%eax
801073c0:	0f 01 10             	lgdtl  (%eax)
}
801073c3:	c9                   	leave  
801073c4:	c3                   	ret    

801073c5 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
801073c5:	55                   	push   %ebp
801073c6:	89 e5                	mov    %esp,%ebp
801073c8:	83 ec 04             	sub    $0x4,%esp
801073cb:	8b 45 08             	mov    0x8(%ebp),%eax
801073ce:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
801073d2:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801073d6:	0f 00 d8             	ltr    %ax
}
801073d9:	c9                   	leave  
801073da:	c3                   	ret    

801073db <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
801073db:	55                   	push   %ebp
801073dc:	89 e5                	mov    %esp,%ebp
801073de:	83 ec 04             	sub    $0x4,%esp
801073e1:	8b 45 08             	mov    0x8(%ebp),%eax
801073e4:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
801073e8:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801073ec:	8e e8                	mov    %eax,%gs
}
801073ee:	c9                   	leave  
801073ef:	c3                   	ret    

801073f0 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
801073f0:	55                   	push   %ebp
801073f1:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
801073f3:	8b 45 08             	mov    0x8(%ebp),%eax
801073f6:	0f 22 d8             	mov    %eax,%cr3
}
801073f9:	5d                   	pop    %ebp
801073fa:	c3                   	ret    

801073fb <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801073fb:	55                   	push   %ebp
801073fc:	89 e5                	mov    %esp,%ebp
801073fe:	8b 45 08             	mov    0x8(%ebp),%eax
80107401:	05 00 00 00 80       	add    $0x80000000,%eax
80107406:	5d                   	pop    %ebp
80107407:	c3                   	ret    

80107408 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107408:	55                   	push   %ebp
80107409:	89 e5                	mov    %esp,%ebp
8010740b:	8b 45 08             	mov    0x8(%ebp),%eax
8010740e:	05 00 00 00 80       	add    $0x80000000,%eax
80107413:	5d                   	pop    %ebp
80107414:	c3                   	ret    

80107415 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107415:	55                   	push   %ebp
80107416:	89 e5                	mov    %esp,%ebp
80107418:	53                   	push   %ebx
80107419:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
8010741c:	e8 bc ba ff ff       	call   80102edd <cpunum>
80107421:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107427:	05 20 f9 10 80       	add    $0x8010f920,%eax
8010742c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
8010742f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107432:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80107438:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010743b:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80107441:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107444:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80107448:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010744b:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010744f:	83 e2 f0             	and    $0xfffffff0,%edx
80107452:	83 ca 0a             	or     $0xa,%edx
80107455:	88 50 7d             	mov    %dl,0x7d(%eax)
80107458:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010745b:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010745f:	83 ca 10             	or     $0x10,%edx
80107462:	88 50 7d             	mov    %dl,0x7d(%eax)
80107465:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107468:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010746c:	83 e2 9f             	and    $0xffffff9f,%edx
8010746f:	88 50 7d             	mov    %dl,0x7d(%eax)
80107472:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107475:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107479:	83 ca 80             	or     $0xffffff80,%edx
8010747c:	88 50 7d             	mov    %dl,0x7d(%eax)
8010747f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107482:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107486:	83 ca 0f             	or     $0xf,%edx
80107489:	88 50 7e             	mov    %dl,0x7e(%eax)
8010748c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010748f:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107493:	83 e2 ef             	and    $0xffffffef,%edx
80107496:	88 50 7e             	mov    %dl,0x7e(%eax)
80107499:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010749c:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801074a0:	83 e2 df             	and    $0xffffffdf,%edx
801074a3:	88 50 7e             	mov    %dl,0x7e(%eax)
801074a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074a9:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801074ad:	83 ca 40             	or     $0x40,%edx
801074b0:	88 50 7e             	mov    %dl,0x7e(%eax)
801074b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074b6:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801074ba:	83 ca 80             	or     $0xffffff80,%edx
801074bd:	88 50 7e             	mov    %dl,0x7e(%eax)
801074c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074c3:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801074c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074ca:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801074d1:	ff ff 
801074d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074d6:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801074dd:	00 00 
801074df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074e2:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801074e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074ec:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801074f3:	83 e2 f0             	and    $0xfffffff0,%edx
801074f6:	83 ca 02             	or     $0x2,%edx
801074f9:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801074ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107502:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107509:	83 ca 10             	or     $0x10,%edx
8010750c:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107512:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107515:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010751c:	83 e2 9f             	and    $0xffffff9f,%edx
8010751f:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107525:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107528:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010752f:	83 ca 80             	or     $0xffffff80,%edx
80107532:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107538:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010753b:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107542:	83 ca 0f             	or     $0xf,%edx
80107545:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010754b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010754e:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107555:	83 e2 ef             	and    $0xffffffef,%edx
80107558:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010755e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107561:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107568:	83 e2 df             	and    $0xffffffdf,%edx
8010756b:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107571:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107574:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010757b:	83 ca 40             	or     $0x40,%edx
8010757e:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107584:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107587:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010758e:	83 ca 80             	or     $0xffffff80,%edx
80107591:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107597:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010759a:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801075a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075a4:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
801075ab:	ff ff 
801075ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075b0:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
801075b7:	00 00 
801075b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075bc:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
801075c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075c6:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801075cd:	83 e2 f0             	and    $0xfffffff0,%edx
801075d0:	83 ca 0a             	or     $0xa,%edx
801075d3:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801075d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075dc:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801075e3:	83 ca 10             	or     $0x10,%edx
801075e6:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801075ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075ef:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801075f6:	83 ca 60             	or     $0x60,%edx
801075f9:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801075ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107602:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107609:	83 ca 80             	or     $0xffffff80,%edx
8010760c:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107612:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107615:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010761c:	83 ca 0f             	or     $0xf,%edx
8010761f:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107625:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107628:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010762f:	83 e2 ef             	and    $0xffffffef,%edx
80107632:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107638:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010763b:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107642:	83 e2 df             	and    $0xffffffdf,%edx
80107645:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010764b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010764e:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107655:	83 ca 40             	or     $0x40,%edx
80107658:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010765e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107661:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107668:	83 ca 80             	or     $0xffffff80,%edx
8010766b:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107671:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107674:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010767b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010767e:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107685:	ff ff 
80107687:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010768a:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80107691:	00 00 
80107693:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107696:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
8010769d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076a0:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801076a7:	83 e2 f0             	and    $0xfffffff0,%edx
801076aa:	83 ca 02             	or     $0x2,%edx
801076ad:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801076b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076b6:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801076bd:	83 ca 10             	or     $0x10,%edx
801076c0:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801076c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076c9:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801076d0:	83 ca 60             	or     $0x60,%edx
801076d3:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801076d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076dc:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801076e3:	83 ca 80             	or     $0xffffff80,%edx
801076e6:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801076ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076ef:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801076f6:	83 ca 0f             	or     $0xf,%edx
801076f9:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801076ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107702:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107709:	83 e2 ef             	and    $0xffffffef,%edx
8010770c:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107712:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107715:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010771c:	83 e2 df             	and    $0xffffffdf,%edx
8010771f:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107725:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107728:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010772f:	83 ca 40             	or     $0x40,%edx
80107732:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107738:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010773b:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107742:	83 ca 80             	or     $0xffffff80,%edx
80107745:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010774b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010774e:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80107755:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107758:	05 b4 00 00 00       	add    $0xb4,%eax
8010775d:	89 c3                	mov    %eax,%ebx
8010775f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107762:	05 b4 00 00 00       	add    $0xb4,%eax
80107767:	c1 e8 10             	shr    $0x10,%eax
8010776a:	89 c1                	mov    %eax,%ecx
8010776c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010776f:	05 b4 00 00 00       	add    $0xb4,%eax
80107774:	c1 e8 18             	shr    $0x18,%eax
80107777:	89 c2                	mov    %eax,%edx
80107779:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010777c:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80107783:	00 00 
80107785:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107788:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
8010778f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107792:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107798:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010779b:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801077a2:	83 e1 f0             	and    $0xfffffff0,%ecx
801077a5:	83 c9 02             	or     $0x2,%ecx
801077a8:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801077ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077b1:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801077b8:	83 c9 10             	or     $0x10,%ecx
801077bb:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801077c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077c4:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801077cb:	83 e1 9f             	and    $0xffffff9f,%ecx
801077ce:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801077d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077d7:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801077de:	83 c9 80             	or     $0xffffff80,%ecx
801077e1:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801077e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ea:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801077f1:	83 e1 f0             	and    $0xfffffff0,%ecx
801077f4:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801077fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077fd:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107804:	83 e1 ef             	and    $0xffffffef,%ecx
80107807:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010780d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107810:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107817:	83 e1 df             	and    $0xffffffdf,%ecx
8010781a:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107820:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107823:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010782a:	83 c9 40             	or     $0x40,%ecx
8010782d:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107833:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107836:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010783d:	83 c9 80             	or     $0xffffff80,%ecx
80107840:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107846:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107849:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
8010784f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107852:	83 c0 70             	add    $0x70,%eax
80107855:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
8010785c:	00 
8010785d:	89 04 24             	mov    %eax,(%esp)
80107860:	e8 37 fb ff ff       	call   8010739c <lgdt>
  loadgs(SEG_KCPU << 3);
80107865:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
8010786c:	e8 6a fb ff ff       	call   801073db <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80107871:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107874:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
8010787a:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80107881:	00 00 00 00 
}
80107885:	83 c4 24             	add    $0x24,%esp
80107888:	5b                   	pop    %ebx
80107889:	5d                   	pop    %ebp
8010788a:	c3                   	ret    

8010788b <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
8010788b:	55                   	push   %ebp
8010788c:	89 e5                	mov    %esp,%ebp
8010788e:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107891:	8b 45 0c             	mov    0xc(%ebp),%eax
80107894:	c1 e8 16             	shr    $0x16,%eax
80107897:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010789e:	8b 45 08             	mov    0x8(%ebp),%eax
801078a1:	01 d0                	add    %edx,%eax
801078a3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
801078a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801078a9:	8b 00                	mov    (%eax),%eax
801078ab:	83 e0 01             	and    $0x1,%eax
801078ae:	85 c0                	test   %eax,%eax
801078b0:	74 17                	je     801078c9 <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
801078b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801078b5:	8b 00                	mov    (%eax),%eax
801078b7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801078bc:	89 04 24             	mov    %eax,(%esp)
801078bf:	e8 44 fb ff ff       	call   80107408 <p2v>
801078c4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801078c7:	eb 4b                	jmp    80107914 <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
801078c9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801078cd:	74 0e                	je     801078dd <walkpgdir+0x52>
801078cf:	e8 77 b2 ff ff       	call   80102b4b <kalloc>
801078d4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801078d7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801078db:	75 07                	jne    801078e4 <walkpgdir+0x59>
      return 0;
801078dd:	b8 00 00 00 00       	mov    $0x0,%eax
801078e2:	eb 47                	jmp    8010792b <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
801078e4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801078eb:	00 
801078ec:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801078f3:	00 
801078f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078f7:	89 04 24             	mov    %eax,(%esp)
801078fa:	e8 63 d5 ff ff       	call   80104e62 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
801078ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107902:	89 04 24             	mov    %eax,(%esp)
80107905:	e8 f1 fa ff ff       	call   801073fb <v2p>
8010790a:	89 c2                	mov    %eax,%edx
8010790c:	83 ca 07             	or     $0x7,%edx
8010790f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107912:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107914:	8b 45 0c             	mov    0xc(%ebp),%eax
80107917:	c1 e8 0c             	shr    $0xc,%eax
8010791a:	25 ff 03 00 00       	and    $0x3ff,%eax
8010791f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107926:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107929:	01 d0                	add    %edx,%eax
}
8010792b:	c9                   	leave  
8010792c:	c3                   	ret    

8010792d <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
8010792d:	55                   	push   %ebp
8010792e:	89 e5                	mov    %esp,%ebp
80107930:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80107933:	8b 45 0c             	mov    0xc(%ebp),%eax
80107936:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010793b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
8010793e:	8b 55 0c             	mov    0xc(%ebp),%edx
80107941:	8b 45 10             	mov    0x10(%ebp),%eax
80107944:	01 d0                	add    %edx,%eax
80107946:	83 e8 01             	sub    $0x1,%eax
80107949:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010794e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107951:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80107958:	00 
80107959:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010795c:	89 44 24 04          	mov    %eax,0x4(%esp)
80107960:	8b 45 08             	mov    0x8(%ebp),%eax
80107963:	89 04 24             	mov    %eax,(%esp)
80107966:	e8 20 ff ff ff       	call   8010788b <walkpgdir>
8010796b:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010796e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107972:	75 07                	jne    8010797b <mappages+0x4e>
      return -1;
80107974:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107979:	eb 46                	jmp    801079c1 <mappages+0x94>
    if(*pte & PTE_P)
8010797b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010797e:	8b 00                	mov    (%eax),%eax
80107980:	83 e0 01             	and    $0x1,%eax
80107983:	85 c0                	test   %eax,%eax
80107985:	74 0c                	je     80107993 <mappages+0x66>
      panic("remap");
80107987:	c7 04 24 b0 87 10 80 	movl   $0x801087b0,(%esp)
8010798e:	e8 b3 8b ff ff       	call   80100546 <panic>
    *pte = pa | perm | PTE_P;
80107993:	8b 45 18             	mov    0x18(%ebp),%eax
80107996:	0b 45 14             	or     0x14(%ebp),%eax
80107999:	89 c2                	mov    %eax,%edx
8010799b:	83 ca 01             	or     $0x1,%edx
8010799e:	8b 45 ec             	mov    -0x14(%ebp),%eax
801079a1:	89 10                	mov    %edx,(%eax)
    if(a == last)
801079a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079a6:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801079a9:	74 10                	je     801079bb <mappages+0x8e>
      break;
    a += PGSIZE;
801079ab:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
801079b2:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
801079b9:	eb 96                	jmp    80107951 <mappages+0x24>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
801079bb:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
801079bc:	b8 00 00 00 00       	mov    $0x0,%eax
}
801079c1:	c9                   	leave  
801079c2:	c3                   	ret    

801079c3 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
801079c3:	55                   	push   %ebp
801079c4:	89 e5                	mov    %esp,%ebp
801079c6:	53                   	push   %ebx
801079c7:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
801079ca:	e8 7c b1 ff ff       	call   80102b4b <kalloc>
801079cf:	89 45 f0             	mov    %eax,-0x10(%ebp)
801079d2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801079d6:	75 0a                	jne    801079e2 <setupkvm+0x1f>
    return 0;
801079d8:	b8 00 00 00 00       	mov    $0x0,%eax
801079dd:	e9 98 00 00 00       	jmp    80107a7a <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
801079e2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801079e9:	00 
801079ea:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801079f1:	00 
801079f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801079f5:	89 04 24             	mov    %eax,(%esp)
801079f8:	e8 65 d4 ff ff       	call   80104e62 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
801079fd:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80107a04:	e8 ff f9 ff ff       	call   80107408 <p2v>
80107a09:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80107a0e:	76 0c                	jbe    80107a1c <setupkvm+0x59>
    panic("PHYSTOP too high");
80107a10:	c7 04 24 b6 87 10 80 	movl   $0x801087b6,(%esp)
80107a17:	e8 2a 8b ff ff       	call   80100546 <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107a1c:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
80107a23:	eb 49                	jmp    80107a6e <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80107a25:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107a28:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80107a2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107a2e:	8b 50 04             	mov    0x4(%eax),%edx
80107a31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a34:	8b 58 08             	mov    0x8(%eax),%ebx
80107a37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a3a:	8b 40 04             	mov    0x4(%eax),%eax
80107a3d:	29 c3                	sub    %eax,%ebx
80107a3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a42:	8b 00                	mov    (%eax),%eax
80107a44:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107a48:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107a4c:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107a50:	89 44 24 04          	mov    %eax,0x4(%esp)
80107a54:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107a57:	89 04 24             	mov    %eax,(%esp)
80107a5a:	e8 ce fe ff ff       	call   8010792d <mappages>
80107a5f:	85 c0                	test   %eax,%eax
80107a61:	79 07                	jns    80107a6a <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80107a63:	b8 00 00 00 00       	mov    $0x0,%eax
80107a68:	eb 10                	jmp    80107a7a <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107a6a:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107a6e:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
80107a75:	72 ae                	jb     80107a25 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80107a77:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107a7a:	83 c4 34             	add    $0x34,%esp
80107a7d:	5b                   	pop    %ebx
80107a7e:	5d                   	pop    %ebp
80107a7f:	c3                   	ret    

80107a80 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107a80:	55                   	push   %ebp
80107a81:	89 e5                	mov    %esp,%ebp
80107a83:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107a86:	e8 38 ff ff ff       	call   801079c3 <setupkvm>
80107a8b:	a3 f8 26 11 80       	mov    %eax,0x801126f8
  switchkvm();
80107a90:	e8 02 00 00 00       	call   80107a97 <switchkvm>
}
80107a95:	c9                   	leave  
80107a96:	c3                   	ret    

80107a97 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107a97:	55                   	push   %ebp
80107a98:	89 e5                	mov    %esp,%ebp
80107a9a:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80107a9d:	a1 f8 26 11 80       	mov    0x801126f8,%eax
80107aa2:	89 04 24             	mov    %eax,(%esp)
80107aa5:	e8 51 f9 ff ff       	call   801073fb <v2p>
80107aaa:	89 04 24             	mov    %eax,(%esp)
80107aad:	e8 3e f9 ff ff       	call   801073f0 <lcr3>
}
80107ab2:	c9                   	leave  
80107ab3:	c3                   	ret    

80107ab4 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107ab4:	55                   	push   %ebp
80107ab5:	89 e5                	mov    %esp,%ebp
80107ab7:	53                   	push   %ebx
80107ab8:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80107abb:	e8 9b d2 ff ff       	call   80104d5b <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80107ac0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107ac6:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107acd:	83 c2 08             	add    $0x8,%edx
80107ad0:	89 d3                	mov    %edx,%ebx
80107ad2:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107ad9:	83 c2 08             	add    $0x8,%edx
80107adc:	c1 ea 10             	shr    $0x10,%edx
80107adf:	89 d1                	mov    %edx,%ecx
80107ae1:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107ae8:	83 c2 08             	add    $0x8,%edx
80107aeb:	c1 ea 18             	shr    $0x18,%edx
80107aee:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80107af5:	67 00 
80107af7:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80107afe:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80107b04:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107b0b:	83 e1 f0             	and    $0xfffffff0,%ecx
80107b0e:	83 c9 09             	or     $0x9,%ecx
80107b11:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107b17:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107b1e:	83 c9 10             	or     $0x10,%ecx
80107b21:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107b27:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107b2e:	83 e1 9f             	and    $0xffffff9f,%ecx
80107b31:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107b37:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107b3e:	83 c9 80             	or     $0xffffff80,%ecx
80107b41:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107b47:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107b4e:	83 e1 f0             	and    $0xfffffff0,%ecx
80107b51:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107b57:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107b5e:	83 e1 ef             	and    $0xffffffef,%ecx
80107b61:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107b67:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107b6e:	83 e1 df             	and    $0xffffffdf,%ecx
80107b71:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107b77:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107b7e:	83 c9 40             	or     $0x40,%ecx
80107b81:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107b87:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107b8e:	83 e1 7f             	and    $0x7f,%ecx
80107b91:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107b97:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80107b9d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107ba3:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80107baa:	83 e2 ef             	and    $0xffffffef,%edx
80107bad:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80107bb3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107bb9:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80107bbf:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107bc5:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80107bcc:	8b 52 08             	mov    0x8(%edx),%edx
80107bcf:	81 c2 00 10 00 00    	add    $0x1000,%edx
80107bd5:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80107bd8:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80107bdf:	e8 e1 f7 ff ff       	call   801073c5 <ltr>
  if(p->pgdir == 0)
80107be4:	8b 45 08             	mov    0x8(%ebp),%eax
80107be7:	8b 40 04             	mov    0x4(%eax),%eax
80107bea:	85 c0                	test   %eax,%eax
80107bec:	75 0c                	jne    80107bfa <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80107bee:	c7 04 24 c7 87 10 80 	movl   $0x801087c7,(%esp)
80107bf5:	e8 4c 89 ff ff       	call   80100546 <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80107bfa:	8b 45 08             	mov    0x8(%ebp),%eax
80107bfd:	8b 40 04             	mov    0x4(%eax),%eax
80107c00:	89 04 24             	mov    %eax,(%esp)
80107c03:	e8 f3 f7 ff ff       	call   801073fb <v2p>
80107c08:	89 04 24             	mov    %eax,(%esp)
80107c0b:	e8 e0 f7 ff ff       	call   801073f0 <lcr3>
  popcli();
80107c10:	e8 8e d1 ff ff       	call   80104da3 <popcli>
}
80107c15:	83 c4 14             	add    $0x14,%esp
80107c18:	5b                   	pop    %ebx
80107c19:	5d                   	pop    %ebp
80107c1a:	c3                   	ret    

80107c1b <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107c1b:	55                   	push   %ebp
80107c1c:	89 e5                	mov    %esp,%ebp
80107c1e:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80107c21:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107c28:	76 0c                	jbe    80107c36 <inituvm+0x1b>
    panic("inituvm: more than a page");
80107c2a:	c7 04 24 db 87 10 80 	movl   $0x801087db,(%esp)
80107c31:	e8 10 89 ff ff       	call   80100546 <panic>
  mem = kalloc();
80107c36:	e8 10 af ff ff       	call   80102b4b <kalloc>
80107c3b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107c3e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107c45:	00 
80107c46:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c4d:	00 
80107c4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c51:	89 04 24             	mov    %eax,(%esp)
80107c54:	e8 09 d2 ff ff       	call   80104e62 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107c59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c5c:	89 04 24             	mov    %eax,(%esp)
80107c5f:	e8 97 f7 ff ff       	call   801073fb <v2p>
80107c64:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107c6b:	00 
80107c6c:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107c70:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107c77:	00 
80107c78:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c7f:	00 
80107c80:	8b 45 08             	mov    0x8(%ebp),%eax
80107c83:	89 04 24             	mov    %eax,(%esp)
80107c86:	e8 a2 fc ff ff       	call   8010792d <mappages>
  memmove(mem, init, sz);
80107c8b:	8b 45 10             	mov    0x10(%ebp),%eax
80107c8e:	89 44 24 08          	mov    %eax,0x8(%esp)
80107c92:	8b 45 0c             	mov    0xc(%ebp),%eax
80107c95:	89 44 24 04          	mov    %eax,0x4(%esp)
80107c99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c9c:	89 04 24             	mov    %eax,(%esp)
80107c9f:	e8 91 d2 ff ff       	call   80104f35 <memmove>
}
80107ca4:	c9                   	leave  
80107ca5:	c3                   	ret    

80107ca6 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80107ca6:	55                   	push   %ebp
80107ca7:	89 e5                	mov    %esp,%ebp
80107ca9:	53                   	push   %ebx
80107caa:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80107cad:	8b 45 0c             	mov    0xc(%ebp),%eax
80107cb0:	25 ff 0f 00 00       	and    $0xfff,%eax
80107cb5:	85 c0                	test   %eax,%eax
80107cb7:	74 0c                	je     80107cc5 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80107cb9:	c7 04 24 f8 87 10 80 	movl   $0x801087f8,(%esp)
80107cc0:	e8 81 88 ff ff       	call   80100546 <panic>
  for(i = 0; i < sz; i += PGSIZE){
80107cc5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107ccc:	e9 ad 00 00 00       	jmp    80107d7e <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80107cd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cd4:	8b 55 0c             	mov    0xc(%ebp),%edx
80107cd7:	01 d0                	add    %edx,%eax
80107cd9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107ce0:	00 
80107ce1:	89 44 24 04          	mov    %eax,0x4(%esp)
80107ce5:	8b 45 08             	mov    0x8(%ebp),%eax
80107ce8:	89 04 24             	mov    %eax,(%esp)
80107ceb:	e8 9b fb ff ff       	call   8010788b <walkpgdir>
80107cf0:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107cf3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107cf7:	75 0c                	jne    80107d05 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80107cf9:	c7 04 24 1b 88 10 80 	movl   $0x8010881b,(%esp)
80107d00:	e8 41 88 ff ff       	call   80100546 <panic>
    pa = PTE_ADDR(*pte);
80107d05:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107d08:	8b 00                	mov    (%eax),%eax
80107d0a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107d0f:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80107d12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d15:	8b 55 18             	mov    0x18(%ebp),%edx
80107d18:	89 d1                	mov    %edx,%ecx
80107d1a:	29 c1                	sub    %eax,%ecx
80107d1c:	89 c8                	mov    %ecx,%eax
80107d1e:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80107d23:	77 11                	ja     80107d36 <loaduvm+0x90>
      n = sz - i;
80107d25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d28:	8b 55 18             	mov    0x18(%ebp),%edx
80107d2b:	89 d1                	mov    %edx,%ecx
80107d2d:	29 c1                	sub    %eax,%ecx
80107d2f:	89 c8                	mov    %ecx,%eax
80107d31:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107d34:	eb 07                	jmp    80107d3d <loaduvm+0x97>
    else
      n = PGSIZE;
80107d36:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80107d3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d40:	8b 55 14             	mov    0x14(%ebp),%edx
80107d43:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80107d46:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107d49:	89 04 24             	mov    %eax,(%esp)
80107d4c:	e8 b7 f6 ff ff       	call   80107408 <p2v>
80107d51:	8b 55 f0             	mov    -0x10(%ebp),%edx
80107d54:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107d58:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107d5c:	89 44 24 04          	mov    %eax,0x4(%esp)
80107d60:	8b 45 10             	mov    0x10(%ebp),%eax
80107d63:	89 04 24             	mov    %eax,(%esp)
80107d66:	e8 36 a0 ff ff       	call   80101da1 <readi>
80107d6b:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107d6e:	74 07                	je     80107d77 <loaduvm+0xd1>
      return -1;
80107d70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107d75:	eb 18                	jmp    80107d8f <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80107d77:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107d7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d81:	3b 45 18             	cmp    0x18(%ebp),%eax
80107d84:	0f 82 47 ff ff ff    	jb     80107cd1 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80107d8a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107d8f:	83 c4 24             	add    $0x24,%esp
80107d92:	5b                   	pop    %ebx
80107d93:	5d                   	pop    %ebp
80107d94:	c3                   	ret    

80107d95 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107d95:	55                   	push   %ebp
80107d96:	89 e5                	mov    %esp,%ebp
80107d98:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80107d9b:	8b 45 10             	mov    0x10(%ebp),%eax
80107d9e:	85 c0                	test   %eax,%eax
80107da0:	79 0a                	jns    80107dac <allocuvm+0x17>
    return 0;
80107da2:	b8 00 00 00 00       	mov    $0x0,%eax
80107da7:	e9 c1 00 00 00       	jmp    80107e6d <allocuvm+0xd8>
  if(newsz < oldsz)
80107dac:	8b 45 10             	mov    0x10(%ebp),%eax
80107daf:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107db2:	73 08                	jae    80107dbc <allocuvm+0x27>
    return oldsz;
80107db4:	8b 45 0c             	mov    0xc(%ebp),%eax
80107db7:	e9 b1 00 00 00       	jmp    80107e6d <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80107dbc:	8b 45 0c             	mov    0xc(%ebp),%eax
80107dbf:	05 ff 0f 00 00       	add    $0xfff,%eax
80107dc4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107dc9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80107dcc:	e9 8d 00 00 00       	jmp    80107e5e <allocuvm+0xc9>
    mem = kalloc();
80107dd1:	e8 75 ad ff ff       	call   80102b4b <kalloc>
80107dd6:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80107dd9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107ddd:	75 2c                	jne    80107e0b <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80107ddf:	c7 04 24 39 88 10 80 	movl   $0x80108839,(%esp)
80107de6:	e8 bf 85 ff ff       	call   801003aa <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80107deb:	8b 45 0c             	mov    0xc(%ebp),%eax
80107dee:	89 44 24 08          	mov    %eax,0x8(%esp)
80107df2:	8b 45 10             	mov    0x10(%ebp),%eax
80107df5:	89 44 24 04          	mov    %eax,0x4(%esp)
80107df9:	8b 45 08             	mov    0x8(%ebp),%eax
80107dfc:	89 04 24             	mov    %eax,(%esp)
80107dff:	e8 6b 00 00 00       	call   80107e6f <deallocuvm>
      return 0;
80107e04:	b8 00 00 00 00       	mov    $0x0,%eax
80107e09:	eb 62                	jmp    80107e6d <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80107e0b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107e12:	00 
80107e13:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107e1a:	00 
80107e1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107e1e:	89 04 24             	mov    %eax,(%esp)
80107e21:	e8 3c d0 ff ff       	call   80104e62 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107e26:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107e29:	89 04 24             	mov    %eax,(%esp)
80107e2c:	e8 ca f5 ff ff       	call   801073fb <v2p>
80107e31:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107e34:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107e3b:	00 
80107e3c:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107e40:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107e47:	00 
80107e48:	89 54 24 04          	mov    %edx,0x4(%esp)
80107e4c:	8b 45 08             	mov    0x8(%ebp),%eax
80107e4f:	89 04 24             	mov    %eax,(%esp)
80107e52:	e8 d6 fa ff ff       	call   8010792d <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80107e57:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107e5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e61:	3b 45 10             	cmp    0x10(%ebp),%eax
80107e64:	0f 82 67 ff ff ff    	jb     80107dd1 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80107e6a:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107e6d:	c9                   	leave  
80107e6e:	c3                   	ret    

80107e6f <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107e6f:	55                   	push   %ebp
80107e70:	89 e5                	mov    %esp,%ebp
80107e72:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80107e75:	8b 45 10             	mov    0x10(%ebp),%eax
80107e78:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107e7b:	72 08                	jb     80107e85 <deallocuvm+0x16>
    return oldsz;
80107e7d:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e80:	e9 a4 00 00 00       	jmp    80107f29 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80107e85:	8b 45 10             	mov    0x10(%ebp),%eax
80107e88:	05 ff 0f 00 00       	add    $0xfff,%eax
80107e8d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107e92:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80107e95:	e9 80 00 00 00       	jmp    80107f1a <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80107e9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e9d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107ea4:	00 
80107ea5:	89 44 24 04          	mov    %eax,0x4(%esp)
80107ea9:	8b 45 08             	mov    0x8(%ebp),%eax
80107eac:	89 04 24             	mov    %eax,(%esp)
80107eaf:	e8 d7 f9 ff ff       	call   8010788b <walkpgdir>
80107eb4:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80107eb7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107ebb:	75 09                	jne    80107ec6 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80107ebd:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80107ec4:	eb 4d                	jmp    80107f13 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80107ec6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107ec9:	8b 00                	mov    (%eax),%eax
80107ecb:	83 e0 01             	and    $0x1,%eax
80107ece:	85 c0                	test   %eax,%eax
80107ed0:	74 41                	je     80107f13 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80107ed2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107ed5:	8b 00                	mov    (%eax),%eax
80107ed7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107edc:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80107edf:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107ee3:	75 0c                	jne    80107ef1 <deallocuvm+0x82>
        panic("kfree");
80107ee5:	c7 04 24 51 88 10 80 	movl   $0x80108851,(%esp)
80107eec:	e8 55 86 ff ff       	call   80100546 <panic>
      char *v = p2v(pa);
80107ef1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107ef4:	89 04 24             	mov    %eax,(%esp)
80107ef7:	e8 0c f5 ff ff       	call   80107408 <p2v>
80107efc:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80107eff:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107f02:	89 04 24             	mov    %eax,(%esp)
80107f05:	e8 a8 ab ff ff       	call   80102ab2 <kfree>
      *pte = 0;
80107f0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f0d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80107f13:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107f1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f1d:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107f20:	0f 82 74 ff ff ff    	jb     80107e9a <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80107f26:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107f29:	c9                   	leave  
80107f2a:	c3                   	ret    

80107f2b <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80107f2b:	55                   	push   %ebp
80107f2c:	89 e5                	mov    %esp,%ebp
80107f2e:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80107f31:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80107f35:	75 0c                	jne    80107f43 <freevm+0x18>
    panic("freevm: no pgdir");
80107f37:	c7 04 24 57 88 10 80 	movl   $0x80108857,(%esp)
80107f3e:	e8 03 86 ff ff       	call   80100546 <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80107f43:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107f4a:	00 
80107f4b:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80107f52:	80 
80107f53:	8b 45 08             	mov    0x8(%ebp),%eax
80107f56:	89 04 24             	mov    %eax,(%esp)
80107f59:	e8 11 ff ff ff       	call   80107e6f <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80107f5e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107f65:	eb 48                	jmp    80107faf <freevm+0x84>
    if(pgdir[i] & PTE_P){
80107f67:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f6a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107f71:	8b 45 08             	mov    0x8(%ebp),%eax
80107f74:	01 d0                	add    %edx,%eax
80107f76:	8b 00                	mov    (%eax),%eax
80107f78:	83 e0 01             	and    $0x1,%eax
80107f7b:	85 c0                	test   %eax,%eax
80107f7d:	74 2c                	je     80107fab <freevm+0x80>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80107f7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f82:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107f89:	8b 45 08             	mov    0x8(%ebp),%eax
80107f8c:	01 d0                	add    %edx,%eax
80107f8e:	8b 00                	mov    (%eax),%eax
80107f90:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f95:	89 04 24             	mov    %eax,(%esp)
80107f98:	e8 6b f4 ff ff       	call   80107408 <p2v>
80107f9d:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80107fa0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107fa3:	89 04 24             	mov    %eax,(%esp)
80107fa6:	e8 07 ab ff ff       	call   80102ab2 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80107fab:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107faf:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80107fb6:	76 af                	jbe    80107f67 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80107fb8:	8b 45 08             	mov    0x8(%ebp),%eax
80107fbb:	89 04 24             	mov    %eax,(%esp)
80107fbe:	e8 ef aa ff ff       	call   80102ab2 <kfree>
}
80107fc3:	c9                   	leave  
80107fc4:	c3                   	ret    

80107fc5 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80107fc5:	55                   	push   %ebp
80107fc6:	89 e5                	mov    %esp,%ebp
80107fc8:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80107fcb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107fd2:	00 
80107fd3:	8b 45 0c             	mov    0xc(%ebp),%eax
80107fd6:	89 44 24 04          	mov    %eax,0x4(%esp)
80107fda:	8b 45 08             	mov    0x8(%ebp),%eax
80107fdd:	89 04 24             	mov    %eax,(%esp)
80107fe0:	e8 a6 f8 ff ff       	call   8010788b <walkpgdir>
80107fe5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80107fe8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107fec:	75 0c                	jne    80107ffa <clearpteu+0x35>
    panic("clearpteu");
80107fee:	c7 04 24 68 88 10 80 	movl   $0x80108868,(%esp)
80107ff5:	e8 4c 85 ff ff       	call   80100546 <panic>
  *pte &= ~PTE_U;
80107ffa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ffd:	8b 00                	mov    (%eax),%eax
80107fff:	89 c2                	mov    %eax,%edx
80108001:	83 e2 fb             	and    $0xfffffffb,%edx
80108004:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108007:	89 10                	mov    %edx,(%eax)
}
80108009:	c9                   	leave  
8010800a:	c3                   	ret    

8010800b <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
8010800b:	55                   	push   %ebp
8010800c:	89 e5                	mov    %esp,%ebp
8010800e:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
80108011:	e8 ad f9 ff ff       	call   801079c3 <setupkvm>
80108016:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108019:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010801d:	75 0a                	jne    80108029 <copyuvm+0x1e>
    return 0;
8010801f:	b8 00 00 00 00       	mov    $0x0,%eax
80108024:	e9 f1 00 00 00       	jmp    8010811a <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
80108029:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108030:	e9 c0 00 00 00       	jmp    801080f5 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108035:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108038:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010803f:	00 
80108040:	89 44 24 04          	mov    %eax,0x4(%esp)
80108044:	8b 45 08             	mov    0x8(%ebp),%eax
80108047:	89 04 24             	mov    %eax,(%esp)
8010804a:	e8 3c f8 ff ff       	call   8010788b <walkpgdir>
8010804f:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108052:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108056:	75 0c                	jne    80108064 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
80108058:	c7 04 24 72 88 10 80 	movl   $0x80108872,(%esp)
8010805f:	e8 e2 84 ff ff       	call   80100546 <panic>
    if(!(*pte & PTE_P))
80108064:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108067:	8b 00                	mov    (%eax),%eax
80108069:	83 e0 01             	and    $0x1,%eax
8010806c:	85 c0                	test   %eax,%eax
8010806e:	75 0c                	jne    8010807c <copyuvm+0x71>
      panic("copyuvm: page not present");
80108070:	c7 04 24 8c 88 10 80 	movl   $0x8010888c,(%esp)
80108077:	e8 ca 84 ff ff       	call   80100546 <panic>
    pa = PTE_ADDR(*pte);
8010807c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010807f:	8b 00                	mov    (%eax),%eax
80108081:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108086:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
80108089:	e8 bd aa ff ff       	call   80102b4b <kalloc>
8010808e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80108091:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80108095:	74 6f                	je     80108106 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108097:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010809a:	89 04 24             	mov    %eax,(%esp)
8010809d:	e8 66 f3 ff ff       	call   80107408 <p2v>
801080a2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801080a9:	00 
801080aa:	89 44 24 04          	mov    %eax,0x4(%esp)
801080ae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801080b1:	89 04 24             	mov    %eax,(%esp)
801080b4:	e8 7c ce ff ff       	call   80104f35 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
801080b9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801080bc:	89 04 24             	mov    %eax,(%esp)
801080bf:	e8 37 f3 ff ff       	call   801073fb <v2p>
801080c4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801080c7:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801080ce:	00 
801080cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
801080d3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801080da:	00 
801080db:	89 54 24 04          	mov    %edx,0x4(%esp)
801080df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801080e2:	89 04 24             	mov    %eax,(%esp)
801080e5:	e8 43 f8 ff ff       	call   8010792d <mappages>
801080ea:	85 c0                	test   %eax,%eax
801080ec:	78 1b                	js     80108109 <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801080ee:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801080f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080f8:	3b 45 0c             	cmp    0xc(%ebp),%eax
801080fb:	0f 82 34 ff ff ff    	jb     80108035 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
80108101:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108104:	eb 14                	jmp    8010811a <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80108106:	90                   	nop
80108107:	eb 01                	jmp    8010810a <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
80108109:	90                   	nop
  }
  return d;

bad:
  freevm(d);
8010810a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010810d:	89 04 24             	mov    %eax,(%esp)
80108110:	e8 16 fe ff ff       	call   80107f2b <freevm>
  return 0;
80108115:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010811a:	c9                   	leave  
8010811b:	c3                   	ret    

8010811c <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010811c:	55                   	push   %ebp
8010811d:	89 e5                	mov    %esp,%ebp
8010811f:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108122:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108129:	00 
8010812a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010812d:	89 44 24 04          	mov    %eax,0x4(%esp)
80108131:	8b 45 08             	mov    0x8(%ebp),%eax
80108134:	89 04 24             	mov    %eax,(%esp)
80108137:	e8 4f f7 ff ff       	call   8010788b <walkpgdir>
8010813c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
8010813f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108142:	8b 00                	mov    (%eax),%eax
80108144:	83 e0 01             	and    $0x1,%eax
80108147:	85 c0                	test   %eax,%eax
80108149:	75 07                	jne    80108152 <uva2ka+0x36>
    return 0;
8010814b:	b8 00 00 00 00       	mov    $0x0,%eax
80108150:	eb 25                	jmp    80108177 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80108152:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108155:	8b 00                	mov    (%eax),%eax
80108157:	83 e0 04             	and    $0x4,%eax
8010815a:	85 c0                	test   %eax,%eax
8010815c:	75 07                	jne    80108165 <uva2ka+0x49>
    return 0;
8010815e:	b8 00 00 00 00       	mov    $0x0,%eax
80108163:	eb 12                	jmp    80108177 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80108165:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108168:	8b 00                	mov    (%eax),%eax
8010816a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010816f:	89 04 24             	mov    %eax,(%esp)
80108172:	e8 91 f2 ff ff       	call   80107408 <p2v>
}
80108177:	c9                   	leave  
80108178:	c3                   	ret    

80108179 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80108179:	55                   	push   %ebp
8010817a:	89 e5                	mov    %esp,%ebp
8010817c:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
8010817f:	8b 45 10             	mov    0x10(%ebp),%eax
80108182:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80108185:	e9 89 00 00 00       	jmp    80108213 <copyout+0x9a>
    va0 = (uint)PGROUNDDOWN(va);
8010818a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010818d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108192:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80108195:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108198:	89 44 24 04          	mov    %eax,0x4(%esp)
8010819c:	8b 45 08             	mov    0x8(%ebp),%eax
8010819f:	89 04 24             	mov    %eax,(%esp)
801081a2:	e8 75 ff ff ff       	call   8010811c <uva2ka>
801081a7:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
801081aa:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801081ae:	75 07                	jne    801081b7 <copyout+0x3e>
      return -1;
801081b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801081b5:	eb 6b                	jmp    80108222 <copyout+0xa9>
    n = PGSIZE - (va - va0);
801081b7:	8b 45 0c             	mov    0xc(%ebp),%eax
801081ba:	8b 55 ec             	mov    -0x14(%ebp),%edx
801081bd:	89 d1                	mov    %edx,%ecx
801081bf:	29 c1                	sub    %eax,%ecx
801081c1:	89 c8                	mov    %ecx,%eax
801081c3:	05 00 10 00 00       	add    $0x1000,%eax
801081c8:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
801081cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801081ce:	3b 45 14             	cmp    0x14(%ebp),%eax
801081d1:	76 06                	jbe    801081d9 <copyout+0x60>
      n = len;
801081d3:	8b 45 14             	mov    0x14(%ebp),%eax
801081d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
801081d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801081dc:	8b 55 0c             	mov    0xc(%ebp),%edx
801081df:	29 c2                	sub    %eax,%edx
801081e1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801081e4:	01 c2                	add    %eax,%edx
801081e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801081e9:	89 44 24 08          	mov    %eax,0x8(%esp)
801081ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801081f4:	89 14 24             	mov    %edx,(%esp)
801081f7:	e8 39 cd ff ff       	call   80104f35 <memmove>
    len -= n;
801081fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801081ff:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108202:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108205:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80108208:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010820b:	05 00 10 00 00       	add    $0x1000,%eax
80108210:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80108213:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80108217:	0f 85 6d ff ff ff    	jne    8010818a <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
8010821d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108222:	c9                   	leave  
80108223:	c3                   	ret    
