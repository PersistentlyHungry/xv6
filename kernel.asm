
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
8010002d:	b8 0f 35 10 80       	mov    $0x8010350f,%eax
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
8010003a:	c7 44 24 04 a8 82 10 	movl   $0x801082a8,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 3c 4c 00 00       	call   80104c8a <initlock>

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
801000bd:	e8 e9 4b 00 00       	call   80104cab <acquire>

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
80100104:	e8 04 4c 00 00       	call   80104d0d <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 a9 48 00 00       	call   801049cd <sleep>
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
8010017c:	e8 8c 4b 00 00       	call   80104d0d <release>
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
80100198:	c7 04 24 af 82 10 80 	movl   $0x801082af,(%esp)
8010019f:	e8 99 03 00 00       	call   8010053d <panic>
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
801001d3:	e8 e4 26 00 00       	call   801028bc <iderw>
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
801001ef:	c7 04 24 c0 82 10 80 	movl   $0x801082c0,(%esp)
801001f6:	e8 42 03 00 00       	call   8010053d <panic>
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
80100210:	e8 a7 26 00 00       	call   801028bc <iderw>
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
80100229:	c7 04 24 c7 82 10 80 	movl   $0x801082c7,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 6a 4a 00 00       	call   80104cab <acquire>

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
8010029d:	e8 04 48 00 00       	call   80104aa6 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 5f 4a 00 00       	call   80104d0d <release>
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
80100308:	74 19                	je     80100323 <printint+0x25>
8010030a:	8b 45 08             	mov    0x8(%ebp),%eax
8010030d:	c1 e8 1f             	shr    $0x1f,%eax
80100310:	89 45 10             	mov    %eax,0x10(%ebp)
80100313:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100317:	74 0a                	je     80100323 <printint+0x25>
    x = -xx;
80100319:	8b 45 08             	mov    0x8(%ebp),%eax
8010031c:	f7 d8                	neg    %eax
8010031e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100321:	eb 06                	jmp    80100329 <printint+0x2b>
  else
    x = xx;
80100323:	8b 45 08             	mov    0x8(%ebp),%eax
80100326:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100329:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100330:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80100333:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100336:	ba 00 00 00 00       	mov    $0x0,%edx
8010033b:	f7 f1                	div    %ecx
8010033d:	89 d0                	mov    %edx,%eax
8010033f:	0f b6 90 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%edx
80100346:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100349:	03 45 f4             	add    -0xc(%ebp),%eax
8010034c:	88 10                	mov    %dl,(%eax)
8010034e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
80100352:	8b 55 0c             	mov    0xc(%ebp),%edx
80100355:	89 55 d4             	mov    %edx,-0x2c(%ebp)
80100358:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010035b:	ba 00 00 00 00       	mov    $0x0,%edx
80100360:	f7 75 d4             	divl   -0x2c(%ebp)
80100363:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100366:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010036a:	75 c4                	jne    80100330 <printint+0x32>

  if(sign)
8010036c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100370:	74 23                	je     80100395 <printint+0x97>
    buf[i++] = '-';
80100372:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100375:	03 45 f4             	add    -0xc(%ebp),%eax
80100378:	c6 00 2d             	movb   $0x2d,(%eax)
8010037b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
8010037f:	eb 14                	jmp    80100395 <printint+0x97>
    consputc(buf[i]);
80100381:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100384:	03 45 f4             	add    -0xc(%ebp),%eax
80100387:	0f b6 00             	movzbl (%eax),%eax
8010038a:	0f be c0             	movsbl %al,%eax
8010038d:	89 04 24             	mov    %eax,(%esp)
80100390:	e8 bb 03 00 00       	call   80100750 <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
80100395:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100399:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010039d:	79 e2                	jns    80100381 <printint+0x83>
    consputc(buf[i]);
}
8010039f:	c9                   	leave  
801003a0:	c3                   	ret    

801003a1 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003a1:	55                   	push   %ebp
801003a2:	89 e5                	mov    %esp,%ebp
801003a4:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003a7:	a1 f4 b5 10 80       	mov    0x8010b5f4,%eax
801003ac:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003af:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b3:	74 0c                	je     801003c1 <cprintf+0x20>
    acquire(&cons.lock);
801003b5:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
801003bc:	e8 ea 48 00 00       	call   80104cab <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 ce 82 10 80 	movl   $0x801082ce,(%esp)
801003cf:	e8 69 01 00 00       	call   8010053d <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003d4:	8d 45 0c             	lea    0xc(%ebp),%eax
801003d7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003da:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003e1:	e9 20 01 00 00       	jmp    80100506 <cprintf+0x165>
    if(c != '%'){
801003e6:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003ea:	74 10                	je     801003fc <cprintf+0x5b>
      consputc(c);
801003ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003ef:	89 04 24             	mov    %eax,(%esp)
801003f2:	e8 59 03 00 00       	call   80100750 <consputc>
      continue;
801003f7:	e9 06 01 00 00       	jmp    80100502 <cprintf+0x161>
    }
    c = fmt[++i] & 0xff;
801003fc:	8b 55 08             	mov    0x8(%ebp),%edx
801003ff:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100403:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100406:	01 d0                	add    %edx,%eax
80100408:	0f b6 00             	movzbl (%eax),%eax
8010040b:	0f be c0             	movsbl %al,%eax
8010040e:	25 ff 00 00 00       	and    $0xff,%eax
80100413:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100416:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010041a:	0f 84 08 01 00 00    	je     80100528 <cprintf+0x187>
      break;
    switch(c){
80100420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100423:	83 f8 70             	cmp    $0x70,%eax
80100426:	74 4d                	je     80100475 <cprintf+0xd4>
80100428:	83 f8 70             	cmp    $0x70,%eax
8010042b:	7f 13                	jg     80100440 <cprintf+0x9f>
8010042d:	83 f8 25             	cmp    $0x25,%eax
80100430:	0f 84 a6 00 00 00    	je     801004dc <cprintf+0x13b>
80100436:	83 f8 64             	cmp    $0x64,%eax
80100439:	74 14                	je     8010044f <cprintf+0xae>
8010043b:	e9 aa 00 00 00       	jmp    801004ea <cprintf+0x149>
80100440:	83 f8 73             	cmp    $0x73,%eax
80100443:	74 53                	je     80100498 <cprintf+0xf7>
80100445:	83 f8 78             	cmp    $0x78,%eax
80100448:	74 2b                	je     80100475 <cprintf+0xd4>
8010044a:	e9 9b 00 00 00       	jmp    801004ea <cprintf+0x149>
    case 'd':
      printint(*argp++, 10, 1);
8010044f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100452:	8b 00                	mov    (%eax),%eax
80100454:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
80100458:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010045f:	00 
80100460:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100467:	00 
80100468:	89 04 24             	mov    %eax,(%esp)
8010046b:	e8 8e fe ff ff       	call   801002fe <printint>
      break;
80100470:	e9 8d 00 00 00       	jmp    80100502 <cprintf+0x161>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
80100475:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100478:	8b 00                	mov    (%eax),%eax
8010047a:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
8010047e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100485:	00 
80100486:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010048d:	00 
8010048e:	89 04 24             	mov    %eax,(%esp)
80100491:	e8 68 fe ff ff       	call   801002fe <printint>
      break;
80100496:	eb 6a                	jmp    80100502 <cprintf+0x161>
    case 's':
      if((s = (char*)*argp++) == 0)
80100498:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010049b:	8b 00                	mov    (%eax),%eax
8010049d:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004a0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004a4:	0f 94 c0             	sete   %al
801004a7:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
801004ab:	84 c0                	test   %al,%al
801004ad:	74 20                	je     801004cf <cprintf+0x12e>
        s = "(null)";
801004af:	c7 45 ec d7 82 10 80 	movl   $0x801082d7,-0x14(%ebp)
      for(; *s; s++)
801004b6:	eb 17                	jmp    801004cf <cprintf+0x12e>
        consputc(*s);
801004b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004bb:	0f b6 00             	movzbl (%eax),%eax
801004be:	0f be c0             	movsbl %al,%eax
801004c1:	89 04 24             	mov    %eax,(%esp)
801004c4:	e8 87 02 00 00       	call   80100750 <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004c9:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004cd:	eb 01                	jmp    801004d0 <cprintf+0x12f>
801004cf:	90                   	nop
801004d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004d3:	0f b6 00             	movzbl (%eax),%eax
801004d6:	84 c0                	test   %al,%al
801004d8:	75 de                	jne    801004b8 <cprintf+0x117>
        consputc(*s);
      break;
801004da:	eb 26                	jmp    80100502 <cprintf+0x161>
    case '%':
      consputc('%');
801004dc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004e3:	e8 68 02 00 00       	call   80100750 <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x161>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 5a 02 00 00       	call   80100750 <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 4f 02 00 00       	call   80100750 <consputc>
      break;
80100501:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100506:	8b 55 08             	mov    0x8(%ebp),%edx
80100509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010050c:	01 d0                	add    %edx,%eax
8010050e:	0f b6 00             	movzbl (%eax),%eax
80100511:	0f be c0             	movsbl %al,%eax
80100514:	25 ff 00 00 00       	and    $0xff,%eax
80100519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010051c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100520:	0f 85 c0 fe ff ff    	jne    801003e6 <cprintf+0x45>
80100526:	eb 01                	jmp    80100529 <cprintf+0x188>
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
80100528:	90                   	nop
      consputc(c);
      break;
    }
  }

  if(locking)
80100529:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010052d:	74 0c                	je     8010053b <cprintf+0x19a>
    release(&cons.lock);
8010052f:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100536:	e8 d2 47 00 00       	call   80104d0d <release>
}
8010053b:	c9                   	leave  
8010053c:	c3                   	ret    

8010053d <panic>:

void
panic(char *s)
{
8010053d:	55                   	push   %ebp
8010053e:	89 e5                	mov    %esp,%ebp
80100540:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
80100543:	e8 b0 fd ff ff       	call   801002f8 <cli>
  cons.locking = 0;
80100548:	c7 05 f4 b5 10 80 00 	movl   $0x0,0x8010b5f4
8010054f:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
80100552:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100558:	0f b6 00             	movzbl (%eax),%eax
8010055b:	0f b6 c0             	movzbl %al,%eax
8010055e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100562:	c7 04 24 de 82 10 80 	movl   $0x801082de,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 ed 82 10 80 	movl   $0x801082ed,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 c5 47 00 00       	call   80104d5c <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 ef 82 10 80 	movl   $0x801082ef,(%esp)
801005b2:	e8 ea fd ff ff       	call   801003a1 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005b7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005bb:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005bf:	7e df                	jle    801005a0 <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005c1:	c7 05 a0 b5 10 80 01 	movl   $0x1,0x8010b5a0
801005c8:	00 00 00 
  for(;;)
    ;
801005cb:	eb fe                	jmp    801005cb <panic+0x8e>

801005cd <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005cd:	55                   	push   %ebp
801005ce:	89 e5                	mov    %esp,%ebp
801005d0:	83 ec 28             	sub    $0x28,%esp
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005d3:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005da:	00 
801005db:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801005e2:	e8 f3 fc ff ff       	call   801002da <outb>
  pos = inb(CRTPORT+1) << 8;
801005e7:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
801005ee:	e8 bd fc ff ff       	call   801002b0 <inb>
801005f3:	0f b6 c0             	movzbl %al,%eax
801005f6:	c1 e0 08             	shl    $0x8,%eax
801005f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
801005fc:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100603:	00 
80100604:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
8010060b:	e8 ca fc ff ff       	call   801002da <outb>
  pos |= inb(CRTPORT+1);
80100610:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100617:	e8 94 fc ff ff       	call   801002b0 <inb>
8010061c:	0f b6 c0             	movzbl %al,%eax
8010061f:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
80100622:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100626:	75 30                	jne    80100658 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100628:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010062b:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100630:	89 c8                	mov    %ecx,%eax
80100632:	f7 ea                	imul   %edx
80100634:	c1 fa 05             	sar    $0x5,%edx
80100637:	89 c8                	mov    %ecx,%eax
80100639:	c1 f8 1f             	sar    $0x1f,%eax
8010063c:	29 c2                	sub    %eax,%edx
8010063e:	89 d0                	mov    %edx,%eax
80100640:	c1 e0 02             	shl    $0x2,%eax
80100643:	01 d0                	add    %edx,%eax
80100645:	c1 e0 04             	shl    $0x4,%eax
80100648:	89 ca                	mov    %ecx,%edx
8010064a:	29 c2                	sub    %eax,%edx
8010064c:	b8 50 00 00 00       	mov    $0x50,%eax
80100651:	29 d0                	sub    %edx,%eax
80100653:	01 45 f4             	add    %eax,-0xc(%ebp)
80100656:	eb 32                	jmp    8010068a <cgaputc+0xbd>
  else if(c == BACKSPACE){
80100658:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010065f:	75 0c                	jne    8010066d <cgaputc+0xa0>
    if(pos > 0) --pos;
80100661:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100665:	7e 23                	jle    8010068a <cgaputc+0xbd>
80100667:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
8010066b:	eb 1d                	jmp    8010068a <cgaputc+0xbd>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010066d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100672:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100675:	01 d2                	add    %edx,%edx
80100677:	01 c2                	add    %eax,%edx
80100679:	8b 45 08             	mov    0x8(%ebp),%eax
8010067c:	66 25 ff 00          	and    $0xff,%ax
80100680:	80 cc 07             	or     $0x7,%ah
80100683:	66 89 02             	mov    %ax,(%edx)
80100686:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  
  if((pos/80) >= 24){  // Scroll up.
8010068a:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
80100691:	7e 53                	jle    801006e6 <cgaputc+0x119>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
80100693:	a1 00 90 10 80       	mov    0x80109000,%eax
80100698:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010069e:	a1 00 90 10 80       	mov    0x80109000,%eax
801006a3:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006aa:	00 
801006ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801006af:	89 04 24             	mov    %eax,(%esp)
801006b2:	e8 16 49 00 00       	call   80104fcd <memmove>
    pos -= 80;
801006b7:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006bb:	b8 80 07 00 00       	mov    $0x780,%eax
801006c0:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006c3:	01 c0                	add    %eax,%eax
801006c5:	8b 15 00 90 10 80    	mov    0x80109000,%edx
801006cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ce:	01 c9                	add    %ecx,%ecx
801006d0:	01 ca                	add    %ecx,%edx
801006d2:	89 44 24 08          	mov    %eax,0x8(%esp)
801006d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006dd:	00 
801006de:	89 14 24             	mov    %edx,(%esp)
801006e1:	e8 14 48 00 00       	call   80104efa <memset>
  }
  
  outb(CRTPORT, 14);
801006e6:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801006ed:	00 
801006ee:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801006f5:	e8 e0 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos>>8);
801006fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006fd:	c1 f8 08             	sar    $0x8,%eax
80100700:	0f b6 c0             	movzbl %al,%eax
80100703:	89 44 24 04          	mov    %eax,0x4(%esp)
80100707:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
8010070e:	e8 c7 fb ff ff       	call   801002da <outb>
  outb(CRTPORT, 15);
80100713:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010071a:	00 
8010071b:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100722:	e8 b3 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos);
80100727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010072a:	0f b6 c0             	movzbl %al,%eax
8010072d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100731:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100738:	e8 9d fb ff ff       	call   801002da <outb>
  crt[pos] = ' ' | 0x0700;
8010073d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100742:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100745:	01 d2                	add    %edx,%edx
80100747:	01 d0                	add    %edx,%eax
80100749:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
8010074e:	c9                   	leave  
8010074f:	c3                   	ret    

80100750 <consputc>:

void
consputc(int c)
{
80100750:	55                   	push   %ebp
80100751:	89 e5                	mov    %esp,%ebp
80100753:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
80100756:	a1 a0 b5 10 80       	mov    0x8010b5a0,%eax
8010075b:	85 c0                	test   %eax,%eax
8010075d:	74 07                	je     80100766 <consputc+0x16>
    cli();
8010075f:	e8 94 fb ff ff       	call   801002f8 <cli>
    for(;;)
      ;
80100764:	eb fe                	jmp    80100764 <consputc+0x14>
  }

  if(c == BACKSPACE){
80100766:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010076d:	75 26                	jne    80100795 <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010076f:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100776:	e8 92 61 00 00       	call   8010690d <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 86 61 00 00       	call   8010690d <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 7a 61 00 00       	call   8010690d <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 6d 61 00 00       	call   8010690d <uartputc>
  cgaputc(c);
801007a0:	8b 45 08             	mov    0x8(%ebp),%eax
801007a3:	89 04 24             	mov    %eax,(%esp)
801007a6:	e8 22 fe ff ff       	call   801005cd <cgaputc>
}
801007ab:	c9                   	leave  
801007ac:	c3                   	ret    

801007ad <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007ad:	55                   	push   %ebp
801007ae:	89 e5                	mov    %esp,%ebp
801007b0:	83 ec 28             	sub    $0x28,%esp
  int c;

  acquire(&input.lock);
801007b3:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
801007ba:	e8 ec 44 00 00       	call   80104cab <acquire>
  while((c = getc()) >= 0){
801007bf:	e9 41 01 00 00       	jmp    80100905 <consoleintr+0x158>
    switch(c){
801007c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801007c7:	83 f8 10             	cmp    $0x10,%eax
801007ca:	74 1e                	je     801007ea <consoleintr+0x3d>
801007cc:	83 f8 10             	cmp    $0x10,%eax
801007cf:	7f 0a                	jg     801007db <consoleintr+0x2e>
801007d1:	83 f8 08             	cmp    $0x8,%eax
801007d4:	74 68                	je     8010083e <consoleintr+0x91>
801007d6:	e9 94 00 00 00       	jmp    8010086f <consoleintr+0xc2>
801007db:	83 f8 15             	cmp    $0x15,%eax
801007de:	74 2f                	je     8010080f <consoleintr+0x62>
801007e0:	83 f8 7f             	cmp    $0x7f,%eax
801007e3:	74 59                	je     8010083e <consoleintr+0x91>
801007e5:	e9 85 00 00 00       	jmp    8010086f <consoleintr+0xc2>
    case C('P'):  // Process listing.
      procdump();
801007ea:	e8 5a 43 00 00       	call   80104b49 <procdump>
      break;
801007ef:	e9 11 01 00 00       	jmp    80100905 <consoleintr+0x158>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(BACKSPACE);
80100801:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100808:	e8 43 ff ff ff       	call   80100750 <consputc>
8010080d:	eb 01                	jmp    80100810 <consoleintr+0x63>
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
8010080f:	90                   	nop
80100810:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
80100816:	a1 58 de 10 80       	mov    0x8010de58,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	0f 84 db 00 00 00    	je     801008fe <consoleintr+0x151>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100823:	a1 5c de 10 80       	mov    0x8010de5c,%eax
80100828:	83 e8 01             	sub    $0x1,%eax
8010082b:	83 e0 7f             	and    $0x7f,%eax
8010082e:	0f b6 80 d4 dd 10 80 	movzbl -0x7fef222c(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100835:	3c 0a                	cmp    $0xa,%al
80100837:	75 bb                	jne    801007f4 <consoleintr+0x47>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100839:	e9 c0 00 00 00       	jmp    801008fe <consoleintr+0x151>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
8010083e:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
80100844:	a1 58 de 10 80       	mov    0x8010de58,%eax
80100849:	39 c2                	cmp    %eax,%edx
8010084b:	0f 84 b0 00 00 00    	je     80100901 <consoleintr+0x154>
        input.e--;
80100851:	a1 5c de 10 80       	mov    0x8010de5c,%eax
80100856:	83 e8 01             	sub    $0x1,%eax
80100859:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(BACKSPACE);
8010085e:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100865:	e8 e6 fe ff ff       	call   80100750 <consputc>
      }
      break;
8010086a:	e9 92 00 00 00       	jmp    80100901 <consoleintr+0x154>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010086f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100873:	0f 84 8b 00 00 00    	je     80100904 <consoleintr+0x157>
80100879:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
8010087f:	a1 54 de 10 80       	mov    0x8010de54,%eax
80100884:	89 d1                	mov    %edx,%ecx
80100886:	29 c1                	sub    %eax,%ecx
80100888:	89 c8                	mov    %ecx,%eax
8010088a:	83 f8 7f             	cmp    $0x7f,%eax
8010088d:	77 75                	ja     80100904 <consoleintr+0x157>
        c = (c == '\r') ? '\n' : c;
8010088f:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
80100893:	74 05                	je     8010089a <consoleintr+0xed>
80100895:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100898:	eb 05                	jmp    8010089f <consoleintr+0xf2>
8010089a:	b8 0a 00 00 00       	mov    $0xa,%eax
8010089f:	89 45 f4             	mov    %eax,-0xc(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
801008a2:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008a7:	89 c1                	mov    %eax,%ecx
801008a9:	83 e1 7f             	and    $0x7f,%ecx
801008ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
801008af:	88 91 d4 dd 10 80    	mov    %dl,-0x7fef222c(%ecx)
801008b5:	83 c0 01             	add    $0x1,%eax
801008b8:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(c);
801008bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008c0:	89 04 24             	mov    %eax,(%esp)
801008c3:	e8 88 fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c8:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008cc:	74 18                	je     801008e6 <consoleintr+0x139>
801008ce:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008d2:	74 12                	je     801008e6 <consoleintr+0x139>
801008d4:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008d9:	8b 15 54 de 10 80    	mov    0x8010de54,%edx
801008df:	83 ea 80             	sub    $0xffffff80,%edx
801008e2:	39 d0                	cmp    %edx,%eax
801008e4:	75 1e                	jne    80100904 <consoleintr+0x157>
          input.w = input.e;
801008e6:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008eb:	a3 58 de 10 80       	mov    %eax,0x8010de58
          wakeup(&input.r);
801008f0:	c7 04 24 54 de 10 80 	movl   $0x8010de54,(%esp)
801008f7:	e8 aa 41 00 00       	call   80104aa6 <wakeup>
        }
      }
      break;
801008fc:	eb 06                	jmp    80100904 <consoleintr+0x157>
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
801008fe:	90                   	nop
801008ff:	eb 04                	jmp    80100905 <consoleintr+0x158>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100901:	90                   	nop
80100902:	eb 01                	jmp    80100905 <consoleintr+0x158>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
          input.w = input.e;
          wakeup(&input.r);
        }
      }
      break;
80100904:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
80100905:	8b 45 08             	mov    0x8(%ebp),%eax
80100908:	ff d0                	call   *%eax
8010090a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010090d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100911:	0f 89 ad fe ff ff    	jns    801007c4 <consoleintr+0x17>
        }
      }
      break;
    }
  }
  release(&input.lock);
80100917:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
8010091e:	e8 ea 43 00 00       	call   80104d0d <release>
}
80100923:	c9                   	leave  
80100924:	c3                   	ret    

80100925 <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
80100925:	55                   	push   %ebp
80100926:	89 e5                	mov    %esp,%ebp
80100928:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
8010092b:	8b 45 08             	mov    0x8(%ebp),%eax
8010092e:	89 04 24             	mov    %eax,(%esp)
80100931:	e8 88 11 00 00       	call   80101abe <iunlock>
  target = n;
80100936:	8b 45 10             	mov    0x10(%ebp),%eax
80100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
8010093c:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100943:	e8 63 43 00 00       	call   80104cab <acquire>
  while(n > 0){
80100948:	e9 a8 00 00 00       	jmp    801009f5 <consoleread+0xd0>
    while(input.r == input.w){
      if(proc->killed){
8010094d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100953:	8b 40 24             	mov    0x24(%eax),%eax
80100956:	85 c0                	test   %eax,%eax
80100958:	74 21                	je     8010097b <consoleread+0x56>
        release(&input.lock);
8010095a:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100961:	e8 a7 43 00 00       	call   80104d0d <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 ff 0f 00 00       	call   80101970 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 a0 dd 10 	movl   $0x8010dda0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 54 de 10 80 	movl   $0x8010de54,(%esp)
8010098a:	e8 3e 40 00 00       	call   801049cd <sleep>
8010098f:	eb 01                	jmp    80100992 <consoleread+0x6d>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100991:	90                   	nop
80100992:	8b 15 54 de 10 80    	mov    0x8010de54,%edx
80100998:	a1 58 de 10 80       	mov    0x8010de58,%eax
8010099d:	39 c2                	cmp    %eax,%edx
8010099f:	74 ac                	je     8010094d <consoleread+0x28>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009a1:	a1 54 de 10 80       	mov    0x8010de54,%eax
801009a6:	89 c2                	mov    %eax,%edx
801009a8:	83 e2 7f             	and    $0x7f,%edx
801009ab:	0f b6 92 d4 dd 10 80 	movzbl -0x7fef222c(%edx),%edx
801009b2:	0f be d2             	movsbl %dl,%edx
801009b5:	89 55 f0             	mov    %edx,-0x10(%ebp)
801009b8:	83 c0 01             	add    $0x1,%eax
801009bb:	a3 54 de 10 80       	mov    %eax,0x8010de54
    if(c == C('D')){  // EOF
801009c0:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801009c4:	75 17                	jne    801009dd <consoleread+0xb8>
      if(n < target){
801009c6:	8b 45 10             	mov    0x10(%ebp),%eax
801009c9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801009cc:	73 2f                	jae    801009fd <consoleread+0xd8>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
801009ce:	a1 54 de 10 80       	mov    0x8010de54,%eax
801009d3:	83 e8 01             	sub    $0x1,%eax
801009d6:	a3 54 de 10 80       	mov    %eax,0x8010de54
      }
      break;
801009db:	eb 20                	jmp    801009fd <consoleread+0xd8>
    }
    *dst++ = c;
801009dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801009e0:	89 c2                	mov    %eax,%edx
801009e2:	8b 45 0c             	mov    0xc(%ebp),%eax
801009e5:	88 10                	mov    %dl,(%eax)
801009e7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
    --n;
801009eb:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
801009ef:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
801009f3:	74 0b                	je     80100a00 <consoleread+0xdb>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
801009f5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801009f9:	7f 96                	jg     80100991 <consoleread+0x6c>
801009fb:	eb 04                	jmp    80100a01 <consoleread+0xdc>
      if(n < target){
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
801009fd:	90                   	nop
801009fe:	eb 01                	jmp    80100a01 <consoleread+0xdc>
    }
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
80100a00:	90                   	nop
  }
  release(&input.lock);
80100a01:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100a08:	e8 00 43 00 00       	call   80104d0d <release>
  ilock(ip);
80100a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a10:	89 04 24             	mov    %eax,(%esp)
80100a13:	e8 58 0f 00 00       	call   80101970 <ilock>

  return target - n;
80100a18:	8b 45 10             	mov    0x10(%ebp),%eax
80100a1b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a1e:	89 d1                	mov    %edx,%ecx
80100a20:	29 c1                	sub    %eax,%ecx
80100a22:	89 c8                	mov    %ecx,%eax
}
80100a24:	c9                   	leave  
80100a25:	c3                   	ret    

80100a26 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a26:	55                   	push   %ebp
80100a27:	89 e5                	mov    %esp,%ebp
80100a29:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a2c:	8b 45 08             	mov    0x8(%ebp),%eax
80100a2f:	89 04 24             	mov    %eax,(%esp)
80100a32:	e8 87 10 00 00       	call   80101abe <iunlock>
  acquire(&cons.lock);
80100a37:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a3e:	e8 68 42 00 00       	call   80104cab <acquire>
  for(i = 0; i < n; i++)
80100a43:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a4a:	eb 1d                	jmp    80100a69 <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100a4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a4f:	03 45 0c             	add    0xc(%ebp),%eax
80100a52:	0f b6 00             	movzbl (%eax),%eax
80100a55:	0f be c0             	movsbl %al,%eax
80100a58:	25 ff 00 00 00       	and    $0xff,%eax
80100a5d:	89 04 24             	mov    %eax,(%esp)
80100a60:	e8 eb fc ff ff       	call   80100750 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100a65:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a6c:	3b 45 10             	cmp    0x10(%ebp),%eax
80100a6f:	7c db                	jl     80100a4c <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100a71:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a78:	e8 90 42 00 00       	call   80104d0d <release>
  ilock(ip);
80100a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 e8 0e 00 00       	call   80101970 <ilock>

  return n;
80100a88:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100a8b:	c9                   	leave  
80100a8c:	c3                   	ret    

80100a8d <consoleinit>:

void
consoleinit(void)
{
80100a8d:	55                   	push   %ebp
80100a8e:	89 e5                	mov    %esp,%ebp
80100a90:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100a93:	c7 44 24 04 f3 82 10 	movl   $0x801082f3,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100aa2:	e8 e3 41 00 00       	call   80104c8a <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 fb 82 10 	movl   $0x801082fb,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100ab6:	e8 cf 41 00 00       	call   80104c8a <initlock>

  devsw[CONSOLE].write = consolewrite;
80100abb:	c7 05 2c ed 10 80 26 	movl   $0x80100a26,0x8010ed2c
80100ac2:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ac5:	c7 05 28 ed 10 80 25 	movl   $0x80100925,0x8010ed28
80100acc:	09 10 80 
  cons.locking = 1;
80100acf:	c7 05 f4 b5 10 80 01 	movl   $0x1,0x8010b5f4
80100ad6:	00 00 00 

  picenable(IRQ_KBD);
80100ad9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae0:	e8 e4 30 00 00       	call   80103bc9 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 85 1f 00 00       	call   80102a7e <ioapicenable>
}
80100af9:	c9                   	leave  
80100afa:	c3                   	ret    
	...

80100afc <exec>:
char path_variable[MAX_PATH_ENTRIES][INPUT_BUF];
int path_variable_count = 1;

int
exec(char *path, char **argv)
{
80100afc:	55                   	push   %ebp
80100afd:	89 e5                	mov    %esp,%ebp
80100aff:	57                   	push   %edi
80100b00:	56                   	push   %esi
80100b01:	53                   	push   %ebx
80100b02:	81 ec 5c 01 00 00    	sub    $0x15c,%esp
80100b08:	89 e0                	mov    %esp,%eax
80100b0a:	89 c6                	mov    %eax,%esi
  safestrcpy(path_variable[0],"/os/",sizeof(path_variable[0]));
80100b0c:	c7 44 24 08 81 00 00 	movl   $0x81,0x8(%esp)
80100b13:	00 
80100b14:	c7 44 24 04 01 83 10 	movl   $0x80108301,0x4(%esp)
80100b1b:	80 
80100b1c:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100b23:	e8 02 46 00 00       	call   8010512a <safestrcpy>
  int i, off;
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  int pathLength = strlen(path);
80100b28:	8b 45 08             	mov    0x8(%ebp),%eax
80100b2b:	89 04 24             	mov    %eax,(%esp)
80100b2e:	e8 45 46 00 00       	call   80105178 <strlen>
80100b33:	89 45 c0             	mov    %eax,-0x40(%ebp)
  char tempPath[pathLength+INPUT_BUF];
80100b36:	8b 45 c0             	mov    -0x40(%ebp),%eax
80100b39:	05 81 00 00 00       	add    $0x81,%eax
80100b3e:	8d 50 ff             	lea    -0x1(%eax),%edx
80100b41:	89 55 bc             	mov    %edx,-0x44(%ebp)
80100b44:	8d 50 0f             	lea    0xf(%eax),%edx
80100b47:	b8 10 00 00 00       	mov    $0x10,%eax
80100b4c:	83 e8 01             	sub    $0x1,%eax
80100b4f:	01 d0                	add    %edx,%eax
80100b51:	c7 85 c4 fe ff ff 10 	movl   $0x10,-0x13c(%ebp)
80100b58:	00 00 00 
80100b5b:	ba 00 00 00 00       	mov    $0x0,%edx
80100b60:	f7 b5 c4 fe ff ff    	divl   -0x13c(%ebp)
80100b66:	6b c0 10             	imul   $0x10,%eax,%eax
80100b69:	29 c4                	sub    %eax,%esp
80100b6b:	8d 44 24 14          	lea    0x14(%esp),%eax
80100b6f:	83 c0 0f             	add    $0xf,%eax
80100b72:	c1 e8 04             	shr    $0x4,%eax
80100b75:	c1 e0 04             	shl    $0x4,%eax
80100b78:	89 45 b8             	mov    %eax,-0x48(%ebp)
  pde_t *pgdir, *oldpgdir;

  if((ip = namei(path)) == 0)
80100b7b:	8b 45 08             	mov    0x8(%ebp),%eax
80100b7e:	89 04 24             	mov    %eax,(%esp)
80100b81:	e8 8c 19 00 00       	call   80102512 <namei>
80100b86:	89 45 c8             	mov    %eax,-0x38(%ebp)
80100b89:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
80100b8d:	0f 85 81 00 00 00    	jne    80100c14 <exec+0x118>
    for(i=0;i<path_variable_count;i++)
80100b93:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
80100b9a:	eb 6e                	jmp    80100c0a <exec+0x10e>
    {
      //If the path is not in pwd, look for it in one of the path_variable
      // Yuval git check
      safestrcpy(tempPath, path_variable[i], INPUT_BUF);
80100b9c:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100b9f:	89 d0                	mov    %edx,%eax
80100ba1:	c1 e0 07             	shl    $0x7,%eax
80100ba4:	01 d0                	add    %edx,%eax
80100ba6:	8d 90 60 de 10 80    	lea    -0x7fef21a0(%eax),%edx
80100bac:	8b 45 b8             	mov    -0x48(%ebp),%eax
80100baf:	c7 44 24 08 81 00 00 	movl   $0x81,0x8(%esp)
80100bb6:	00 
80100bb7:	89 54 24 04          	mov    %edx,0x4(%esp)
80100bbb:	89 04 24             	mov    %eax,(%esp)
80100bbe:	e8 67 45 00 00       	call   8010512a <safestrcpy>
      safestrcpy(&tempPath[strlen(tempPath)],path,(strlen(path)));
80100bc3:	8b 45 08             	mov    0x8(%ebp),%eax
80100bc6:	89 04 24             	mov    %eax,(%esp)
80100bc9:	e8 aa 45 00 00       	call   80105178 <strlen>
80100bce:	89 c3                	mov    %eax,%ebx
80100bd0:	8b 7d b8             	mov    -0x48(%ebp),%edi
80100bd3:	8b 45 b8             	mov    -0x48(%ebp),%eax
80100bd6:	89 04 24             	mov    %eax,(%esp)
80100bd9:	e8 9a 45 00 00       	call   80105178 <strlen>
80100bde:	8d 14 07             	lea    (%edi,%eax,1),%edx
80100be1:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80100be5:	8b 45 08             	mov    0x8(%ebp),%eax
80100be8:	89 44 24 04          	mov    %eax,0x4(%esp)
80100bec:	89 14 24             	mov    %edx,(%esp)
80100bef:	e8 36 45 00 00       	call   8010512a <safestrcpy>
      if((ip = namei(tempPath)) != 0)
80100bf4:	8b 45 b8             	mov    -0x48(%ebp),%eax
80100bf7:	89 04 24             	mov    %eax,(%esp)
80100bfa:	e8 13 19 00 00       	call   80102512 <namei>
80100bff:	89 45 c8             	mov    %eax,-0x38(%ebp)
80100c02:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
  int pathLength = strlen(path);
  char tempPath[pathLength+INPUT_BUF];
  pde_t *pgdir, *oldpgdir;

  if((ip = namei(path)) == 0)
    for(i=0;i<path_variable_count;i++)
80100c06:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
80100c0a:	a1 18 90 10 80       	mov    0x80109018,%eax
80100c0f:	39 45 dc             	cmp    %eax,-0x24(%ebp)
80100c12:	7c 88                	jl     80100b9c <exec+0xa0>
      if((ip = namei(tempPath)) != 0)
      {
        continue;
      }
    }
  if(ip==0)
80100c14:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
80100c18:	75 0a                	jne    80100c24 <exec+0x128>
      return -1;
80100c1a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100c1f:	e9 da 03 00 00       	jmp    80100ffe <exec+0x502>
  ilock(ip);
80100c24:	8b 45 c8             	mov    -0x38(%ebp),%eax
80100c27:	89 04 24             	mov    %eax,(%esp)
80100c2a:	e8 41 0d 00 00       	call   80101970 <ilock>
  pgdir = 0;
80100c2f:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100c36:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100c3d:	00 
80100c3e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100c45:	00 
80100c46:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
80100c4c:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c50:	8b 45 c8             	mov    -0x38(%ebp),%eax
80100c53:	89 04 24             	mov    %eax,(%esp)
80100c56:	e8 0b 12 00 00       	call   80101e66 <readi>
80100c5b:	83 f8 33             	cmp    $0x33,%eax
80100c5e:	0f 86 54 03 00 00    	jbe    80100fb8 <exec+0x4bc>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100c64:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100c6a:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100c6f:	0f 85 46 03 00 00    	jne    80100fbb <exec+0x4bf>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
80100c75:	c7 04 24 07 2c 10 80 	movl   $0x80102c07,(%esp)
80100c7c:	e8 d0 6d 00 00       	call   80107a51 <setupkvm>
80100c81:	89 45 c4             	mov    %eax,-0x3c(%ebp)
80100c84:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
80100c88:	0f 84 30 03 00 00    	je     80100fbe <exec+0x4c2>
    goto bad;

  // Load program into memory.
  sz = 0;
80100c8e:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c95:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
80100c9c:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100ca2:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100ca5:	e9 c5 00 00 00       	jmp    80100d6f <exec+0x273>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100caa:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100cad:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100cb4:	00 
80100cb5:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cb9:	8d 85 d0 fe ff ff    	lea    -0x130(%ebp),%eax
80100cbf:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cc3:	8b 45 c8             	mov    -0x38(%ebp),%eax
80100cc6:	89 04 24             	mov    %eax,(%esp)
80100cc9:	e8 98 11 00 00       	call   80101e66 <readi>
80100cce:	83 f8 20             	cmp    $0x20,%eax
80100cd1:	0f 85 ea 02 00 00    	jne    80100fc1 <exec+0x4c5>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
80100cd7:	8b 85 d0 fe ff ff    	mov    -0x130(%ebp),%eax
80100cdd:	83 f8 01             	cmp    $0x1,%eax
80100ce0:	75 7f                	jne    80100d61 <exec+0x265>
      continue;
    if(ph.memsz < ph.filesz)
80100ce2:	8b 95 e4 fe ff ff    	mov    -0x11c(%ebp),%edx
80100ce8:	8b 85 e0 fe ff ff    	mov    -0x120(%ebp),%eax
80100cee:	39 c2                	cmp    %eax,%edx
80100cf0:	0f 82 ce 02 00 00    	jb     80100fc4 <exec+0x4c8>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100cf6:	8b 95 d8 fe ff ff    	mov    -0x128(%ebp),%edx
80100cfc:	8b 85 e4 fe ff ff    	mov    -0x11c(%ebp),%eax
80100d02:	01 d0                	add    %edx,%eax
80100d04:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d08:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100d0b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d0f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80100d12:	89 04 24             	mov    %eax,(%esp)
80100d15:	e8 09 71 00 00       	call   80107e23 <allocuvm>
80100d1a:	89 45 d0             	mov    %eax,-0x30(%ebp)
80100d1d:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
80100d21:	0f 84 a0 02 00 00    	je     80100fc7 <exec+0x4cb>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100d27:	8b 8d e0 fe ff ff    	mov    -0x120(%ebp),%ecx
80100d2d:	8b 95 d4 fe ff ff    	mov    -0x12c(%ebp),%edx
80100d33:	8b 85 d8 fe ff ff    	mov    -0x128(%ebp),%eax
80100d39:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100d3d:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d41:	8b 55 c8             	mov    -0x38(%ebp),%edx
80100d44:	89 54 24 08          	mov    %edx,0x8(%esp)
80100d48:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d4c:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80100d4f:	89 04 24             	mov    %eax,(%esp)
80100d52:	e8 dd 6f 00 00       	call   80107d34 <loaduvm>
80100d57:	85 c0                	test   %eax,%eax
80100d59:	0f 88 6b 02 00 00    	js     80100fca <exec+0x4ce>
80100d5f:	eb 01                	jmp    80100d62 <exec+0x266>
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
80100d61:	90                   	nop
  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100d62:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
80100d66:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100d69:	83 c0 20             	add    $0x20,%eax
80100d6c:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100d6f:	0f b7 85 1c ff ff ff 	movzwl -0xe4(%ebp),%eax
80100d76:	0f b7 c0             	movzwl %ax,%eax
80100d79:	3b 45 dc             	cmp    -0x24(%ebp),%eax
80100d7c:	0f 8f 28 ff ff ff    	jg     80100caa <exec+0x1ae>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100d82:	8b 45 c8             	mov    -0x38(%ebp),%eax
80100d85:	89 04 24             	mov    %eax,(%esp)
80100d88:	e8 67 0e 00 00       	call   80101bf4 <iunlockput>
  ip = 0;
80100d8d:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100d94:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100d97:	05 ff 0f 00 00       	add    $0xfff,%eax
80100d9c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100da1:	89 45 d0             	mov    %eax,-0x30(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100da4:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100da7:	05 00 20 00 00       	add    $0x2000,%eax
80100dac:	89 44 24 08          	mov    %eax,0x8(%esp)
80100db0:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100db3:	89 44 24 04          	mov    %eax,0x4(%esp)
80100db7:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80100dba:	89 04 24             	mov    %eax,(%esp)
80100dbd:	e8 61 70 00 00       	call   80107e23 <allocuvm>
80100dc2:	89 45 d0             	mov    %eax,-0x30(%ebp)
80100dc5:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
80100dc9:	0f 84 fe 01 00 00    	je     80100fcd <exec+0x4d1>
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100dcf:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100dd2:	2d 00 20 00 00       	sub    $0x2000,%eax
80100dd7:	89 44 24 04          	mov    %eax,0x4(%esp)
80100ddb:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80100dde:	89 04 24             	mov    %eax,(%esp)
80100de1:	e8 61 72 00 00       	call   80108047 <clearpteu>
  sp = sz;
80100de6:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100de9:	89 45 cc             	mov    %eax,-0x34(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100dec:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
80100df3:	e9 81 00 00 00       	jmp    80100e79 <exec+0x37d>
    if(argc >= MAXARG)
80100df8:	83 7d d4 1f          	cmpl   $0x1f,-0x2c(%ebp)
80100dfc:	0f 87 ce 01 00 00    	ja     80100fd0 <exec+0x4d4>
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100e02:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e05:	c1 e0 02             	shl    $0x2,%eax
80100e08:	03 45 0c             	add    0xc(%ebp),%eax
80100e0b:	8b 00                	mov    (%eax),%eax
80100e0d:	89 04 24             	mov    %eax,(%esp)
80100e10:	e8 63 43 00 00       	call   80105178 <strlen>
80100e15:	f7 d0                	not    %eax
80100e17:	03 45 cc             	add    -0x34(%ebp),%eax
80100e1a:	83 e0 fc             	and    $0xfffffffc,%eax
80100e1d:	89 45 cc             	mov    %eax,-0x34(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100e20:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e23:	c1 e0 02             	shl    $0x2,%eax
80100e26:	03 45 0c             	add    0xc(%ebp),%eax
80100e29:	8b 00                	mov    (%eax),%eax
80100e2b:	89 04 24             	mov    %eax,(%esp)
80100e2e:	e8 45 43 00 00       	call   80105178 <strlen>
80100e33:	83 c0 01             	add    $0x1,%eax
80100e36:	89 c2                	mov    %eax,%edx
80100e38:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e3b:	c1 e0 02             	shl    $0x2,%eax
80100e3e:	03 45 0c             	add    0xc(%ebp),%eax
80100e41:	8b 00                	mov    (%eax),%eax
80100e43:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100e47:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e4b:	8b 45 cc             	mov    -0x34(%ebp),%eax
80100e4e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e52:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80100e55:	89 04 24             	mov    %eax,(%esp)
80100e58:	e8 9e 73 00 00       	call   801081fb <copyout>
80100e5d:	85 c0                	test   %eax,%eax
80100e5f:	0f 88 6e 01 00 00    	js     80100fd3 <exec+0x4d7>
      goto bad;
    ustack[3+argc] = sp;
80100e65:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e68:	8d 50 03             	lea    0x3(%eax),%edx
80100e6b:	8b 45 cc             	mov    -0x34(%ebp),%eax
80100e6e:	89 84 95 24 ff ff ff 	mov    %eax,-0xdc(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100e75:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
80100e79:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e7c:	c1 e0 02             	shl    $0x2,%eax
80100e7f:	03 45 0c             	add    0xc(%ebp),%eax
80100e82:	8b 00                	mov    (%eax),%eax
80100e84:	85 c0                	test   %eax,%eax
80100e86:	0f 85 6c ff ff ff    	jne    80100df8 <exec+0x2fc>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100e8c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e8f:	83 c0 03             	add    $0x3,%eax
80100e92:	c7 84 85 24 ff ff ff 	movl   $0x0,-0xdc(%ebp,%eax,4)
80100e99:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100e9d:	c7 85 24 ff ff ff ff 	movl   $0xffffffff,-0xdc(%ebp)
80100ea4:	ff ff ff 
  ustack[1] = argc;
80100ea7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100eaa:	89 85 28 ff ff ff    	mov    %eax,-0xd8(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100eb0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100eb3:	83 c0 01             	add    $0x1,%eax
80100eb6:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100ebd:	8b 45 cc             	mov    -0x34(%ebp),%eax
80100ec0:	29 d0                	sub    %edx,%eax
80100ec2:	89 85 2c ff ff ff    	mov    %eax,-0xd4(%ebp)

  sp -= (3+argc+1) * 4;
80100ec8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ecb:	83 c0 04             	add    $0x4,%eax
80100ece:	c1 e0 02             	shl    $0x2,%eax
80100ed1:	29 45 cc             	sub    %eax,-0x34(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100ed4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ed7:	83 c0 04             	add    $0x4,%eax
80100eda:	c1 e0 02             	shl    $0x2,%eax
80100edd:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100ee1:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
80100ee7:	89 44 24 08          	mov    %eax,0x8(%esp)
80100eeb:	8b 45 cc             	mov    -0x34(%ebp),%eax
80100eee:	89 44 24 04          	mov    %eax,0x4(%esp)
80100ef2:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80100ef5:	89 04 24             	mov    %eax,(%esp)
80100ef8:	e8 fe 72 00 00       	call   801081fb <copyout>
80100efd:	85 c0                	test   %eax,%eax
80100eff:	0f 88 d1 00 00 00    	js     80100fd6 <exec+0x4da>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100f05:	8b 45 08             	mov    0x8(%ebp),%eax
80100f08:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80100f0b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100f0e:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100f11:	eb 17                	jmp    80100f2a <exec+0x42e>
    if(*s == '/')
80100f13:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100f16:	0f b6 00             	movzbl (%eax),%eax
80100f19:	3c 2f                	cmp    $0x2f,%al
80100f1b:	75 09                	jne    80100f26 <exec+0x42a>
      last = s+1;
80100f1d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100f20:	83 c0 01             	add    $0x1,%eax
80100f23:	89 45 e0             	mov    %eax,-0x20(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100f26:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100f2a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100f2d:	0f b6 00             	movzbl (%eax),%eax
80100f30:	84 c0                	test   %al,%al
80100f32:	75 df                	jne    80100f13 <exec+0x417>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100f34:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f3a:	8d 50 6c             	lea    0x6c(%eax),%edx
80100f3d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100f44:	00 
80100f45:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100f48:	89 44 24 04          	mov    %eax,0x4(%esp)
80100f4c:	89 14 24             	mov    %edx,(%esp)
80100f4f:	e8 d6 41 00 00       	call   8010512a <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100f54:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f5a:	8b 40 04             	mov    0x4(%eax),%eax
80100f5d:	89 45 b4             	mov    %eax,-0x4c(%ebp)
  proc->pgdir = pgdir;
80100f60:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f66:	8b 55 c4             	mov    -0x3c(%ebp),%edx
80100f69:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100f6c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f72:	8b 55 d0             	mov    -0x30(%ebp),%edx
80100f75:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100f77:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f7d:	8b 40 18             	mov    0x18(%eax),%eax
80100f80:	8b 95 08 ff ff ff    	mov    -0xf8(%ebp),%edx
80100f86:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100f89:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f8f:	8b 40 18             	mov    0x18(%eax),%eax
80100f92:	8b 55 cc             	mov    -0x34(%ebp),%edx
80100f95:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100f98:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f9e:	89 04 24             	mov    %eax,(%esp)
80100fa1:	e8 9c 6b 00 00       	call   80107b42 <switchuvm>
  freevm(oldpgdir);
80100fa6:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80100fa9:	89 04 24             	mov    %eax,(%esp)
80100fac:	e8 08 70 00 00       	call   80107fb9 <freevm>
  return 0;
80100fb1:	b8 00 00 00 00       	mov    $0x0,%eax
80100fb6:	eb 46                	jmp    80100ffe <exec+0x502>
  ilock(ip);
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
    goto bad;
80100fb8:	90                   	nop
80100fb9:	eb 1c                	jmp    80100fd7 <exec+0x4db>
  if(elf.magic != ELF_MAGIC)
    goto bad;
80100fbb:	90                   	nop
80100fbc:	eb 19                	jmp    80100fd7 <exec+0x4db>

  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;
80100fbe:	90                   	nop
80100fbf:	eb 16                	jmp    80100fd7 <exec+0x4db>

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
80100fc1:	90                   	nop
80100fc2:	eb 13                	jmp    80100fd7 <exec+0x4db>
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
80100fc4:	90                   	nop
80100fc5:	eb 10                	jmp    80100fd7 <exec+0x4db>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
80100fc7:	90                   	nop
80100fc8:	eb 0d                	jmp    80100fd7 <exec+0x4db>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
80100fca:	90                   	nop
80100fcb:	eb 0a                	jmp    80100fd7 <exec+0x4db>

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
80100fcd:	90                   	nop
80100fce:	eb 07                	jmp    80100fd7 <exec+0x4db>
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
80100fd0:	90                   	nop
80100fd1:	eb 04                	jmp    80100fd7 <exec+0x4db>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
80100fd3:	90                   	nop
80100fd4:	eb 01                	jmp    80100fd7 <exec+0x4db>
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;
80100fd6:	90                   	nop
  switchuvm(proc);
  freevm(oldpgdir);
  return 0;

 bad:
  if(pgdir)
80100fd7:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
80100fdb:	74 0b                	je     80100fe8 <exec+0x4ec>
    freevm(pgdir);
80100fdd:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80100fe0:	89 04 24             	mov    %eax,(%esp)
80100fe3:	e8 d1 6f 00 00       	call   80107fb9 <freevm>
  if(ip)
80100fe8:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
80100fec:	74 0b                	je     80100ff9 <exec+0x4fd>
    iunlockput(ip);
80100fee:	8b 45 c8             	mov    -0x38(%ebp),%eax
80100ff1:	89 04 24             	mov    %eax,(%esp)
80100ff4:	e8 fb 0b 00 00       	call   80101bf4 <iunlockput>
  return -1;
80100ff9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100ffe:	89 f4                	mov    %esi,%esp
}
80101000:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101003:	5b                   	pop    %ebx
80101004:	5e                   	pop    %esi
80101005:	5f                   	pop    %edi
80101006:	5d                   	pop    %ebp
80101007:	c3                   	ret    

80101008 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80101008:	55                   	push   %ebp
80101009:	89 e5                	mov    %esp,%ebp
8010100b:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
8010100e:	c7 44 24 04 06 83 10 	movl   $0x80108306,0x4(%esp)
80101015:	80 
80101016:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
8010101d:	e8 68 3c 00 00       	call   80104c8a <initlock>
}
80101022:	c9                   	leave  
80101023:	c3                   	ret    

80101024 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80101024:	55                   	push   %ebp
80101025:	89 e5                	mov    %esp,%ebp
80101027:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
8010102a:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
80101031:	e8 75 3c 00 00       	call   80104cab <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80101036:	c7 45 f4 b4 e3 10 80 	movl   $0x8010e3b4,-0xc(%ebp)
8010103d:	eb 29                	jmp    80101068 <filealloc+0x44>
    if(f->ref == 0){
8010103f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101042:	8b 40 04             	mov    0x4(%eax),%eax
80101045:	85 c0                	test   %eax,%eax
80101047:	75 1b                	jne    80101064 <filealloc+0x40>
      f->ref = 1;
80101049:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010104c:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80101053:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
8010105a:	e8 ae 3c 00 00       	call   80104d0d <release>
      return f;
8010105f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101062:	eb 1e                	jmp    80101082 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80101064:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80101068:	81 7d f4 14 ed 10 80 	cmpl   $0x8010ed14,-0xc(%ebp)
8010106f:	72 ce                	jb     8010103f <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80101071:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
80101078:	e8 90 3c 00 00       	call   80104d0d <release>
  return 0;
8010107d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101082:	c9                   	leave  
80101083:	c3                   	ret    

80101084 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80101084:	55                   	push   %ebp
80101085:	89 e5                	mov    %esp,%ebp
80101087:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
8010108a:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
80101091:	e8 15 3c 00 00       	call   80104cab <acquire>
  if(f->ref < 1)
80101096:	8b 45 08             	mov    0x8(%ebp),%eax
80101099:	8b 40 04             	mov    0x4(%eax),%eax
8010109c:	85 c0                	test   %eax,%eax
8010109e:	7f 0c                	jg     801010ac <filedup+0x28>
    panic("filedup");
801010a0:	c7 04 24 0d 83 10 80 	movl   $0x8010830d,(%esp)
801010a7:	e8 91 f4 ff ff       	call   8010053d <panic>
  f->ref++;
801010ac:	8b 45 08             	mov    0x8(%ebp),%eax
801010af:	8b 40 04             	mov    0x4(%eax),%eax
801010b2:	8d 50 01             	lea    0x1(%eax),%edx
801010b5:	8b 45 08             	mov    0x8(%ebp),%eax
801010b8:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
801010bb:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
801010c2:	e8 46 3c 00 00       	call   80104d0d <release>
  return f;
801010c7:	8b 45 08             	mov    0x8(%ebp),%eax
}
801010ca:	c9                   	leave  
801010cb:	c3                   	ret    

801010cc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
801010cc:	55                   	push   %ebp
801010cd:	89 e5                	mov    %esp,%ebp
801010cf:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
801010d2:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
801010d9:	e8 cd 3b 00 00       	call   80104cab <acquire>
  if(f->ref < 1)
801010de:	8b 45 08             	mov    0x8(%ebp),%eax
801010e1:	8b 40 04             	mov    0x4(%eax),%eax
801010e4:	85 c0                	test   %eax,%eax
801010e6:	7f 0c                	jg     801010f4 <fileclose+0x28>
    panic("fileclose");
801010e8:	c7 04 24 15 83 10 80 	movl   $0x80108315,(%esp)
801010ef:	e8 49 f4 ff ff       	call   8010053d <panic>
  if(--f->ref > 0){
801010f4:	8b 45 08             	mov    0x8(%ebp),%eax
801010f7:	8b 40 04             	mov    0x4(%eax),%eax
801010fa:	8d 50 ff             	lea    -0x1(%eax),%edx
801010fd:	8b 45 08             	mov    0x8(%ebp),%eax
80101100:	89 50 04             	mov    %edx,0x4(%eax)
80101103:	8b 45 08             	mov    0x8(%ebp),%eax
80101106:	8b 40 04             	mov    0x4(%eax),%eax
80101109:	85 c0                	test   %eax,%eax
8010110b:	7e 11                	jle    8010111e <fileclose+0x52>
    release(&ftable.lock);
8010110d:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
80101114:	e8 f4 3b 00 00       	call   80104d0d <release>
    return;
80101119:	e9 82 00 00 00       	jmp    801011a0 <fileclose+0xd4>
  }
  ff = *f;
8010111e:	8b 45 08             	mov    0x8(%ebp),%eax
80101121:	8b 10                	mov    (%eax),%edx
80101123:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101126:	8b 50 04             	mov    0x4(%eax),%edx
80101129:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010112c:	8b 50 08             	mov    0x8(%eax),%edx
8010112f:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101132:	8b 50 0c             	mov    0xc(%eax),%edx
80101135:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101138:	8b 50 10             	mov    0x10(%eax),%edx
8010113b:	89 55 f0             	mov    %edx,-0x10(%ebp)
8010113e:	8b 40 14             	mov    0x14(%eax),%eax
80101141:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101144:	8b 45 08             	mov    0x8(%ebp),%eax
80101147:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
8010114e:	8b 45 08             	mov    0x8(%ebp),%eax
80101151:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101157:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
8010115e:	e8 aa 3b 00 00       	call   80104d0d <release>
  
  if(ff.type == FD_PIPE)
80101163:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101166:	83 f8 01             	cmp    $0x1,%eax
80101169:	75 18                	jne    80101183 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
8010116b:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
8010116f:	0f be d0             	movsbl %al,%edx
80101172:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101175:	89 54 24 04          	mov    %edx,0x4(%esp)
80101179:	89 04 24             	mov    %eax,(%esp)
8010117c:	e8 02 2d 00 00       	call   80103e83 <pipeclose>
80101181:	eb 1d                	jmp    801011a0 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
80101183:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101186:	83 f8 02             	cmp    $0x2,%eax
80101189:	75 15                	jne    801011a0 <fileclose+0xd4>
    begin_trans();
8010118b:	e8 95 21 00 00       	call   80103325 <begin_trans>
    iput(ff.ip);
80101190:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101193:	89 04 24             	mov    %eax,(%esp)
80101196:	e8 88 09 00 00       	call   80101b23 <iput>
    commit_trans();
8010119b:	e8 ce 21 00 00       	call   8010336e <commit_trans>
  }
}
801011a0:	c9                   	leave  
801011a1:	c3                   	ret    

801011a2 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801011a2:	55                   	push   %ebp
801011a3:	89 e5                	mov    %esp,%ebp
801011a5:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801011a8:	8b 45 08             	mov    0x8(%ebp),%eax
801011ab:	8b 00                	mov    (%eax),%eax
801011ad:	83 f8 02             	cmp    $0x2,%eax
801011b0:	75 38                	jne    801011ea <filestat+0x48>
    ilock(f->ip);
801011b2:	8b 45 08             	mov    0x8(%ebp),%eax
801011b5:	8b 40 10             	mov    0x10(%eax),%eax
801011b8:	89 04 24             	mov    %eax,(%esp)
801011bb:	e8 b0 07 00 00       	call   80101970 <ilock>
    stati(f->ip, st);
801011c0:	8b 45 08             	mov    0x8(%ebp),%eax
801011c3:	8b 40 10             	mov    0x10(%eax),%eax
801011c6:	8b 55 0c             	mov    0xc(%ebp),%edx
801011c9:	89 54 24 04          	mov    %edx,0x4(%esp)
801011cd:	89 04 24             	mov    %eax,(%esp)
801011d0:	e8 4c 0c 00 00       	call   80101e21 <stati>
    iunlock(f->ip);
801011d5:	8b 45 08             	mov    0x8(%ebp),%eax
801011d8:	8b 40 10             	mov    0x10(%eax),%eax
801011db:	89 04 24             	mov    %eax,(%esp)
801011de:	e8 db 08 00 00       	call   80101abe <iunlock>
    return 0;
801011e3:	b8 00 00 00 00       	mov    $0x0,%eax
801011e8:	eb 05                	jmp    801011ef <filestat+0x4d>
  }
  return -1;
801011ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801011ef:	c9                   	leave  
801011f0:	c3                   	ret    

801011f1 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801011f1:	55                   	push   %ebp
801011f2:	89 e5                	mov    %esp,%ebp
801011f4:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
801011f7:	8b 45 08             	mov    0x8(%ebp),%eax
801011fa:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801011fe:	84 c0                	test   %al,%al
80101200:	75 0a                	jne    8010120c <fileread+0x1b>
    return -1;
80101202:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101207:	e9 9f 00 00 00       	jmp    801012ab <fileread+0xba>
  if(f->type == FD_PIPE)
8010120c:	8b 45 08             	mov    0x8(%ebp),%eax
8010120f:	8b 00                	mov    (%eax),%eax
80101211:	83 f8 01             	cmp    $0x1,%eax
80101214:	75 1e                	jne    80101234 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101216:	8b 45 08             	mov    0x8(%ebp),%eax
80101219:	8b 40 0c             	mov    0xc(%eax),%eax
8010121c:	8b 55 10             	mov    0x10(%ebp),%edx
8010121f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101223:	8b 55 0c             	mov    0xc(%ebp),%edx
80101226:	89 54 24 04          	mov    %edx,0x4(%esp)
8010122a:	89 04 24             	mov    %eax,(%esp)
8010122d:	e8 d3 2d 00 00       	call   80104005 <piperead>
80101232:	eb 77                	jmp    801012ab <fileread+0xba>
  if(f->type == FD_INODE){
80101234:	8b 45 08             	mov    0x8(%ebp),%eax
80101237:	8b 00                	mov    (%eax),%eax
80101239:	83 f8 02             	cmp    $0x2,%eax
8010123c:	75 61                	jne    8010129f <fileread+0xae>
    ilock(f->ip);
8010123e:	8b 45 08             	mov    0x8(%ebp),%eax
80101241:	8b 40 10             	mov    0x10(%eax),%eax
80101244:	89 04 24             	mov    %eax,(%esp)
80101247:	e8 24 07 00 00       	call   80101970 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010124c:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010124f:	8b 45 08             	mov    0x8(%ebp),%eax
80101252:	8b 50 14             	mov    0x14(%eax),%edx
80101255:	8b 45 08             	mov    0x8(%ebp),%eax
80101258:	8b 40 10             	mov    0x10(%eax),%eax
8010125b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010125f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101263:	8b 55 0c             	mov    0xc(%ebp),%edx
80101266:	89 54 24 04          	mov    %edx,0x4(%esp)
8010126a:	89 04 24             	mov    %eax,(%esp)
8010126d:	e8 f4 0b 00 00       	call   80101e66 <readi>
80101272:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101275:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101279:	7e 11                	jle    8010128c <fileread+0x9b>
      f->off += r;
8010127b:	8b 45 08             	mov    0x8(%ebp),%eax
8010127e:	8b 50 14             	mov    0x14(%eax),%edx
80101281:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101284:	01 c2                	add    %eax,%edx
80101286:	8b 45 08             	mov    0x8(%ebp),%eax
80101289:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
8010128c:	8b 45 08             	mov    0x8(%ebp),%eax
8010128f:	8b 40 10             	mov    0x10(%eax),%eax
80101292:	89 04 24             	mov    %eax,(%esp)
80101295:	e8 24 08 00 00       	call   80101abe <iunlock>
    return r;
8010129a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010129d:	eb 0c                	jmp    801012ab <fileread+0xba>
  }
  panic("fileread");
8010129f:	c7 04 24 1f 83 10 80 	movl   $0x8010831f,(%esp)
801012a6:	e8 92 f2 ff ff       	call   8010053d <panic>
}
801012ab:	c9                   	leave  
801012ac:	c3                   	ret    

801012ad <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801012ad:	55                   	push   %ebp
801012ae:	89 e5                	mov    %esp,%ebp
801012b0:	53                   	push   %ebx
801012b1:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801012b4:	8b 45 08             	mov    0x8(%ebp),%eax
801012b7:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801012bb:	84 c0                	test   %al,%al
801012bd:	75 0a                	jne    801012c9 <filewrite+0x1c>
    return -1;
801012bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012c4:	e9 23 01 00 00       	jmp    801013ec <filewrite+0x13f>
  if(f->type == FD_PIPE)
801012c9:	8b 45 08             	mov    0x8(%ebp),%eax
801012cc:	8b 00                	mov    (%eax),%eax
801012ce:	83 f8 01             	cmp    $0x1,%eax
801012d1:	75 21                	jne    801012f4 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
801012d3:	8b 45 08             	mov    0x8(%ebp),%eax
801012d6:	8b 40 0c             	mov    0xc(%eax),%eax
801012d9:	8b 55 10             	mov    0x10(%ebp),%edx
801012dc:	89 54 24 08          	mov    %edx,0x8(%esp)
801012e0:	8b 55 0c             	mov    0xc(%ebp),%edx
801012e3:	89 54 24 04          	mov    %edx,0x4(%esp)
801012e7:	89 04 24             	mov    %eax,(%esp)
801012ea:	e8 26 2c 00 00       	call   80103f15 <pipewrite>
801012ef:	e9 f8 00 00 00       	jmp    801013ec <filewrite+0x13f>
  if(f->type == FD_INODE){
801012f4:	8b 45 08             	mov    0x8(%ebp),%eax
801012f7:	8b 00                	mov    (%eax),%eax
801012f9:	83 f8 02             	cmp    $0x2,%eax
801012fc:	0f 85 de 00 00 00    	jne    801013e0 <filewrite+0x133>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
80101302:	c7 45 ec 00 06 00 00 	movl   $0x600,-0x14(%ebp)
    int i = 0;
80101309:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101310:	e9 a8 00 00 00       	jmp    801013bd <filewrite+0x110>
      int n1 = n - i;
80101315:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101318:	8b 55 10             	mov    0x10(%ebp),%edx
8010131b:	89 d1                	mov    %edx,%ecx
8010131d:	29 c1                	sub    %eax,%ecx
8010131f:	89 c8                	mov    %ecx,%eax
80101321:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101324:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101327:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010132a:	7e 06                	jle    80101332 <filewrite+0x85>
        n1 = max;
8010132c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010132f:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_trans();
80101332:	e8 ee 1f 00 00       	call   80103325 <begin_trans>
      ilock(f->ip);
80101337:	8b 45 08             	mov    0x8(%ebp),%eax
8010133a:	8b 40 10             	mov    0x10(%eax),%eax
8010133d:	89 04 24             	mov    %eax,(%esp)
80101340:	e8 2b 06 00 00       	call   80101970 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101345:	8b 5d f0             	mov    -0x10(%ebp),%ebx
80101348:	8b 45 08             	mov    0x8(%ebp),%eax
8010134b:	8b 48 14             	mov    0x14(%eax),%ecx
8010134e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101351:	89 c2                	mov    %eax,%edx
80101353:	03 55 0c             	add    0xc(%ebp),%edx
80101356:	8b 45 08             	mov    0x8(%ebp),%eax
80101359:	8b 40 10             	mov    0x10(%eax),%eax
8010135c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80101360:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80101364:	89 54 24 04          	mov    %edx,0x4(%esp)
80101368:	89 04 24             	mov    %eax,(%esp)
8010136b:	e8 61 0c 00 00       	call   80101fd1 <writei>
80101370:	89 45 e8             	mov    %eax,-0x18(%ebp)
80101373:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101377:	7e 11                	jle    8010138a <filewrite+0xdd>
        f->off += r;
80101379:	8b 45 08             	mov    0x8(%ebp),%eax
8010137c:	8b 50 14             	mov    0x14(%eax),%edx
8010137f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101382:	01 c2                	add    %eax,%edx
80101384:	8b 45 08             	mov    0x8(%ebp),%eax
80101387:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
8010138a:	8b 45 08             	mov    0x8(%ebp),%eax
8010138d:	8b 40 10             	mov    0x10(%eax),%eax
80101390:	89 04 24             	mov    %eax,(%esp)
80101393:	e8 26 07 00 00       	call   80101abe <iunlock>
      commit_trans();
80101398:	e8 d1 1f 00 00       	call   8010336e <commit_trans>

      if(r < 0)
8010139d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801013a1:	78 28                	js     801013cb <filewrite+0x11e>
        break;
      if(r != n1)
801013a3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801013a6:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801013a9:	74 0c                	je     801013b7 <filewrite+0x10a>
        panic("short filewrite");
801013ab:	c7 04 24 28 83 10 80 	movl   $0x80108328,(%esp)
801013b2:	e8 86 f1 ff ff       	call   8010053d <panic>
      i += r;
801013b7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801013ba:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801013bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013c0:	3b 45 10             	cmp    0x10(%ebp),%eax
801013c3:	0f 8c 4c ff ff ff    	jl     80101315 <filewrite+0x68>
801013c9:	eb 01                	jmp    801013cc <filewrite+0x11f>
        f->off += r;
      iunlock(f->ip);
      commit_trans();

      if(r < 0)
        break;
801013cb:	90                   	nop
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801013cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013cf:	3b 45 10             	cmp    0x10(%ebp),%eax
801013d2:	75 05                	jne    801013d9 <filewrite+0x12c>
801013d4:	8b 45 10             	mov    0x10(%ebp),%eax
801013d7:	eb 05                	jmp    801013de <filewrite+0x131>
801013d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801013de:	eb 0c                	jmp    801013ec <filewrite+0x13f>
  }
  panic("filewrite");
801013e0:	c7 04 24 38 83 10 80 	movl   $0x80108338,(%esp)
801013e7:	e8 51 f1 ff ff       	call   8010053d <panic>
}
801013ec:	83 c4 24             	add    $0x24,%esp
801013ef:	5b                   	pop    %ebx
801013f0:	5d                   	pop    %ebp
801013f1:	c3                   	ret    
	...

801013f4 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801013f4:	55                   	push   %ebp
801013f5:	89 e5                	mov    %esp,%ebp
801013f7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
801013fa:	8b 45 08             	mov    0x8(%ebp),%eax
801013fd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101404:	00 
80101405:	89 04 24             	mov    %eax,(%esp)
80101408:	e8 99 ed ff ff       	call   801001a6 <bread>
8010140d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101410:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101413:	83 c0 18             	add    $0x18,%eax
80101416:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010141d:	00 
8010141e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101422:	8b 45 0c             	mov    0xc(%ebp),%eax
80101425:	89 04 24             	mov    %eax,(%esp)
80101428:	e8 a0 3b 00 00       	call   80104fcd <memmove>
  brelse(bp);
8010142d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101430:	89 04 24             	mov    %eax,(%esp)
80101433:	e8 df ed ff ff       	call   80100217 <brelse>
}
80101438:	c9                   	leave  
80101439:	c3                   	ret    

8010143a <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
8010143a:	55                   	push   %ebp
8010143b:	89 e5                	mov    %esp,%ebp
8010143d:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80101440:	8b 55 0c             	mov    0xc(%ebp),%edx
80101443:	8b 45 08             	mov    0x8(%ebp),%eax
80101446:	89 54 24 04          	mov    %edx,0x4(%esp)
8010144a:	89 04 24             	mov    %eax,(%esp)
8010144d:	e8 54 ed ff ff       	call   801001a6 <bread>
80101452:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101455:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101458:	83 c0 18             	add    $0x18,%eax
8010145b:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80101462:	00 
80101463:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010146a:	00 
8010146b:	89 04 24             	mov    %eax,(%esp)
8010146e:	e8 87 3a 00 00       	call   80104efa <memset>
  log_write(bp);
80101473:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101476:	89 04 24             	mov    %eax,(%esp)
80101479:	e8 48 1f 00 00       	call   801033c6 <log_write>
  brelse(bp);
8010147e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101481:	89 04 24             	mov    %eax,(%esp)
80101484:	e8 8e ed ff ff       	call   80100217 <brelse>
}
80101489:	c9                   	leave  
8010148a:	c3                   	ret    

8010148b <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
8010148b:	55                   	push   %ebp
8010148c:	89 e5                	mov    %esp,%ebp
8010148e:	53                   	push   %ebx
8010148f:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
80101492:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80101499:	8b 45 08             	mov    0x8(%ebp),%eax
8010149c:	8d 55 d8             	lea    -0x28(%ebp),%edx
8010149f:	89 54 24 04          	mov    %edx,0x4(%esp)
801014a3:	89 04 24             	mov    %eax,(%esp)
801014a6:	e8 49 ff ff ff       	call   801013f4 <readsb>
  for(b = 0; b < sb.size; b += BPB){
801014ab:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801014b2:	e9 11 01 00 00       	jmp    801015c8 <balloc+0x13d>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
801014b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801014ba:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801014c0:	85 c0                	test   %eax,%eax
801014c2:	0f 48 c2             	cmovs  %edx,%eax
801014c5:	c1 f8 0c             	sar    $0xc,%eax
801014c8:	8b 55 e0             	mov    -0x20(%ebp),%edx
801014cb:	c1 ea 03             	shr    $0x3,%edx
801014ce:	01 d0                	add    %edx,%eax
801014d0:	83 c0 03             	add    $0x3,%eax
801014d3:	89 44 24 04          	mov    %eax,0x4(%esp)
801014d7:	8b 45 08             	mov    0x8(%ebp),%eax
801014da:	89 04 24             	mov    %eax,(%esp)
801014dd:	e8 c4 ec ff ff       	call   801001a6 <bread>
801014e2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801014e5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801014ec:	e9 a7 00 00 00       	jmp    80101598 <balloc+0x10d>
      m = 1 << (bi % 8);
801014f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014f4:	89 c2                	mov    %eax,%edx
801014f6:	c1 fa 1f             	sar    $0x1f,%edx
801014f9:	c1 ea 1d             	shr    $0x1d,%edx
801014fc:	01 d0                	add    %edx,%eax
801014fe:	83 e0 07             	and    $0x7,%eax
80101501:	29 d0                	sub    %edx,%eax
80101503:	ba 01 00 00 00       	mov    $0x1,%edx
80101508:	89 d3                	mov    %edx,%ebx
8010150a:	89 c1                	mov    %eax,%ecx
8010150c:	d3 e3                	shl    %cl,%ebx
8010150e:	89 d8                	mov    %ebx,%eax
80101510:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101513:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101516:	8d 50 07             	lea    0x7(%eax),%edx
80101519:	85 c0                	test   %eax,%eax
8010151b:	0f 48 c2             	cmovs  %edx,%eax
8010151e:	c1 f8 03             	sar    $0x3,%eax
80101521:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101524:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101529:	0f b6 c0             	movzbl %al,%eax
8010152c:	23 45 e8             	and    -0x18(%ebp),%eax
8010152f:	85 c0                	test   %eax,%eax
80101531:	75 61                	jne    80101594 <balloc+0x109>
        bp->data[bi/8] |= m;  // Mark block in use.
80101533:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101536:	8d 50 07             	lea    0x7(%eax),%edx
80101539:	85 c0                	test   %eax,%eax
8010153b:	0f 48 c2             	cmovs  %edx,%eax
8010153e:	c1 f8 03             	sar    $0x3,%eax
80101541:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101544:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101549:	89 d1                	mov    %edx,%ecx
8010154b:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010154e:	09 ca                	or     %ecx,%edx
80101550:	89 d1                	mov    %edx,%ecx
80101552:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101555:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101559:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010155c:	89 04 24             	mov    %eax,(%esp)
8010155f:	e8 62 1e 00 00       	call   801033c6 <log_write>
        brelse(bp);
80101564:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101567:	89 04 24             	mov    %eax,(%esp)
8010156a:	e8 a8 ec ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
8010156f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101572:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101575:	01 c2                	add    %eax,%edx
80101577:	8b 45 08             	mov    0x8(%ebp),%eax
8010157a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010157e:	89 04 24             	mov    %eax,(%esp)
80101581:	e8 b4 fe ff ff       	call   8010143a <bzero>
        return b + bi;
80101586:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101589:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010158c:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
8010158e:	83 c4 34             	add    $0x34,%esp
80101591:	5b                   	pop    %ebx
80101592:	5d                   	pop    %ebp
80101593:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101594:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101598:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
8010159f:	7f 15                	jg     801015b6 <balloc+0x12b>
801015a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015a4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015a7:	01 d0                	add    %edx,%eax
801015a9:	89 c2                	mov    %eax,%edx
801015ab:	8b 45 d8             	mov    -0x28(%ebp),%eax
801015ae:	39 c2                	cmp    %eax,%edx
801015b0:	0f 82 3b ff ff ff    	jb     801014f1 <balloc+0x66>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801015b6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801015b9:	89 04 24             	mov    %eax,(%esp)
801015bc:	e8 56 ec ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
801015c1:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801015c8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015cb:	8b 45 d8             	mov    -0x28(%ebp),%eax
801015ce:	39 c2                	cmp    %eax,%edx
801015d0:	0f 82 e1 fe ff ff    	jb     801014b7 <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801015d6:	c7 04 24 42 83 10 80 	movl   $0x80108342,(%esp)
801015dd:	e8 5b ef ff ff       	call   8010053d <panic>

801015e2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
801015e2:	55                   	push   %ebp
801015e3:	89 e5                	mov    %esp,%ebp
801015e5:	53                   	push   %ebx
801015e6:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
801015e9:	8d 45 dc             	lea    -0x24(%ebp),%eax
801015ec:	89 44 24 04          	mov    %eax,0x4(%esp)
801015f0:	8b 45 08             	mov    0x8(%ebp),%eax
801015f3:	89 04 24             	mov    %eax,(%esp)
801015f6:	e8 f9 fd ff ff       	call   801013f4 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
801015fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801015fe:	89 c2                	mov    %eax,%edx
80101600:	c1 ea 0c             	shr    $0xc,%edx
80101603:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101606:	c1 e8 03             	shr    $0x3,%eax
80101609:	01 d0                	add    %edx,%eax
8010160b:	8d 50 03             	lea    0x3(%eax),%edx
8010160e:	8b 45 08             	mov    0x8(%ebp),%eax
80101611:	89 54 24 04          	mov    %edx,0x4(%esp)
80101615:	89 04 24             	mov    %eax,(%esp)
80101618:	e8 89 eb ff ff       	call   801001a6 <bread>
8010161d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101620:	8b 45 0c             	mov    0xc(%ebp),%eax
80101623:	25 ff 0f 00 00       	and    $0xfff,%eax
80101628:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010162b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010162e:	89 c2                	mov    %eax,%edx
80101630:	c1 fa 1f             	sar    $0x1f,%edx
80101633:	c1 ea 1d             	shr    $0x1d,%edx
80101636:	01 d0                	add    %edx,%eax
80101638:	83 e0 07             	and    $0x7,%eax
8010163b:	29 d0                	sub    %edx,%eax
8010163d:	ba 01 00 00 00       	mov    $0x1,%edx
80101642:	89 d3                	mov    %edx,%ebx
80101644:	89 c1                	mov    %eax,%ecx
80101646:	d3 e3                	shl    %cl,%ebx
80101648:	89 d8                	mov    %ebx,%eax
8010164a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
8010164d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101650:	8d 50 07             	lea    0x7(%eax),%edx
80101653:	85 c0                	test   %eax,%eax
80101655:	0f 48 c2             	cmovs  %edx,%eax
80101658:	c1 f8 03             	sar    $0x3,%eax
8010165b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010165e:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101663:	0f b6 c0             	movzbl %al,%eax
80101666:	23 45 ec             	and    -0x14(%ebp),%eax
80101669:	85 c0                	test   %eax,%eax
8010166b:	75 0c                	jne    80101679 <bfree+0x97>
    panic("freeing free block");
8010166d:	c7 04 24 58 83 10 80 	movl   $0x80108358,(%esp)
80101674:	e8 c4 ee ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
80101679:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010167c:	8d 50 07             	lea    0x7(%eax),%edx
8010167f:	85 c0                	test   %eax,%eax
80101681:	0f 48 c2             	cmovs  %edx,%eax
80101684:	c1 f8 03             	sar    $0x3,%eax
80101687:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010168a:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010168f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
80101692:	f7 d1                	not    %ecx
80101694:	21 ca                	and    %ecx,%edx
80101696:	89 d1                	mov    %edx,%ecx
80101698:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010169b:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
8010169f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016a2:	89 04 24             	mov    %eax,(%esp)
801016a5:	e8 1c 1d 00 00       	call   801033c6 <log_write>
  brelse(bp);
801016aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016ad:	89 04 24             	mov    %eax,(%esp)
801016b0:	e8 62 eb ff ff       	call   80100217 <brelse>
}
801016b5:	83 c4 34             	add    $0x34,%esp
801016b8:	5b                   	pop    %ebx
801016b9:	5d                   	pop    %ebp
801016ba:	c3                   	ret    

801016bb <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
801016bb:	55                   	push   %ebp
801016bc:	89 e5                	mov    %esp,%ebp
801016be:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
801016c1:	c7 44 24 04 6b 83 10 	movl   $0x8010836b,0x4(%esp)
801016c8:	80 
801016c9:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
801016d0:	e8 b5 35 00 00       	call   80104c8a <initlock>
}
801016d5:	c9                   	leave  
801016d6:	c3                   	ret    

801016d7 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
801016d7:	55                   	push   %ebp
801016d8:	89 e5                	mov    %esp,%ebp
801016da:	83 ec 48             	sub    $0x48,%esp
801016dd:	8b 45 0c             	mov    0xc(%ebp),%eax
801016e0:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
801016e4:	8b 45 08             	mov    0x8(%ebp),%eax
801016e7:	8d 55 dc             	lea    -0x24(%ebp),%edx
801016ea:	89 54 24 04          	mov    %edx,0x4(%esp)
801016ee:	89 04 24             	mov    %eax,(%esp)
801016f1:	e8 fe fc ff ff       	call   801013f4 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
801016f6:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
801016fd:	e9 98 00 00 00       	jmp    8010179a <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
80101702:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101705:	c1 e8 03             	shr    $0x3,%eax
80101708:	83 c0 02             	add    $0x2,%eax
8010170b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010170f:	8b 45 08             	mov    0x8(%ebp),%eax
80101712:	89 04 24             	mov    %eax,(%esp)
80101715:	e8 8c ea ff ff       	call   801001a6 <bread>
8010171a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
8010171d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101720:	8d 50 18             	lea    0x18(%eax),%edx
80101723:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101726:	83 e0 07             	and    $0x7,%eax
80101729:	c1 e0 06             	shl    $0x6,%eax
8010172c:	01 d0                	add    %edx,%eax
8010172e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80101731:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101734:	0f b7 00             	movzwl (%eax),%eax
80101737:	66 85 c0             	test   %ax,%ax
8010173a:	75 4f                	jne    8010178b <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
8010173c:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
80101743:	00 
80101744:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010174b:	00 
8010174c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010174f:	89 04 24             	mov    %eax,(%esp)
80101752:	e8 a3 37 00 00       	call   80104efa <memset>
      dip->type = type;
80101757:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010175a:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
8010175e:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101761:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101764:	89 04 24             	mov    %eax,(%esp)
80101767:	e8 5a 1c 00 00       	call   801033c6 <log_write>
      brelse(bp);
8010176c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010176f:	89 04 24             	mov    %eax,(%esp)
80101772:	e8 a0 ea ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101777:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010177a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010177e:	8b 45 08             	mov    0x8(%ebp),%eax
80101781:	89 04 24             	mov    %eax,(%esp)
80101784:	e8 e3 00 00 00       	call   8010186c <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
80101789:	c9                   	leave  
8010178a:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
8010178b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010178e:	89 04 24             	mov    %eax,(%esp)
80101791:	e8 81 ea ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
80101796:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010179a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010179d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801017a0:	39 c2                	cmp    %eax,%edx
801017a2:	0f 82 5a ff ff ff    	jb     80101702 <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
801017a8:	c7 04 24 72 83 10 80 	movl   $0x80108372,(%esp)
801017af:	e8 89 ed ff ff       	call   8010053d <panic>

801017b4 <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
801017b4:	55                   	push   %ebp
801017b5:	89 e5                	mov    %esp,%ebp
801017b7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
801017ba:	8b 45 08             	mov    0x8(%ebp),%eax
801017bd:	8b 40 04             	mov    0x4(%eax),%eax
801017c0:	c1 e8 03             	shr    $0x3,%eax
801017c3:	8d 50 02             	lea    0x2(%eax),%edx
801017c6:	8b 45 08             	mov    0x8(%ebp),%eax
801017c9:	8b 00                	mov    (%eax),%eax
801017cb:	89 54 24 04          	mov    %edx,0x4(%esp)
801017cf:	89 04 24             	mov    %eax,(%esp)
801017d2:	e8 cf e9 ff ff       	call   801001a6 <bread>
801017d7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801017da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017dd:	8d 50 18             	lea    0x18(%eax),%edx
801017e0:	8b 45 08             	mov    0x8(%ebp),%eax
801017e3:	8b 40 04             	mov    0x4(%eax),%eax
801017e6:	83 e0 07             	and    $0x7,%eax
801017e9:	c1 e0 06             	shl    $0x6,%eax
801017ec:	01 d0                	add    %edx,%eax
801017ee:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
801017f1:	8b 45 08             	mov    0x8(%ebp),%eax
801017f4:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801017f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017fb:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801017fe:	8b 45 08             	mov    0x8(%ebp),%eax
80101801:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80101805:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101808:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
8010180c:	8b 45 08             	mov    0x8(%ebp),%eax
8010180f:	0f b7 50 14          	movzwl 0x14(%eax),%edx
80101813:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101816:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
8010181a:	8b 45 08             	mov    0x8(%ebp),%eax
8010181d:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101821:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101824:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101828:	8b 45 08             	mov    0x8(%ebp),%eax
8010182b:	8b 50 18             	mov    0x18(%eax),%edx
8010182e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101831:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101834:	8b 45 08             	mov    0x8(%ebp),%eax
80101837:	8d 50 1c             	lea    0x1c(%eax),%edx
8010183a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010183d:	83 c0 0c             	add    $0xc,%eax
80101840:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101847:	00 
80101848:	89 54 24 04          	mov    %edx,0x4(%esp)
8010184c:	89 04 24             	mov    %eax,(%esp)
8010184f:	e8 79 37 00 00       	call   80104fcd <memmove>
  log_write(bp);
80101854:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101857:	89 04 24             	mov    %eax,(%esp)
8010185a:	e8 67 1b 00 00       	call   801033c6 <log_write>
  brelse(bp);
8010185f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101862:	89 04 24             	mov    %eax,(%esp)
80101865:	e8 ad e9 ff ff       	call   80100217 <brelse>
}
8010186a:	c9                   	leave  
8010186b:	c3                   	ret    

8010186c <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
8010186c:	55                   	push   %ebp
8010186d:	89 e5                	mov    %esp,%ebp
8010186f:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
80101872:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101879:	e8 2d 34 00 00       	call   80104cab <acquire>

  // Is the inode already cached?
  empty = 0;
8010187e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101885:	c7 45 f4 b4 ed 10 80 	movl   $0x8010edb4,-0xc(%ebp)
8010188c:	eb 59                	jmp    801018e7 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
8010188e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101891:	8b 40 08             	mov    0x8(%eax),%eax
80101894:	85 c0                	test   %eax,%eax
80101896:	7e 35                	jle    801018cd <iget+0x61>
80101898:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010189b:	8b 00                	mov    (%eax),%eax
8010189d:	3b 45 08             	cmp    0x8(%ebp),%eax
801018a0:	75 2b                	jne    801018cd <iget+0x61>
801018a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018a5:	8b 40 04             	mov    0x4(%eax),%eax
801018a8:	3b 45 0c             	cmp    0xc(%ebp),%eax
801018ab:	75 20                	jne    801018cd <iget+0x61>
      ip->ref++;
801018ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018b0:	8b 40 08             	mov    0x8(%eax),%eax
801018b3:	8d 50 01             	lea    0x1(%eax),%edx
801018b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018b9:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
801018bc:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
801018c3:	e8 45 34 00 00       	call   80104d0d <release>
      return ip;
801018c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018cb:	eb 6f                	jmp    8010193c <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801018cd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801018d1:	75 10                	jne    801018e3 <iget+0x77>
801018d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018d6:	8b 40 08             	mov    0x8(%eax),%eax
801018d9:	85 c0                	test   %eax,%eax
801018db:	75 06                	jne    801018e3 <iget+0x77>
      empty = ip;
801018dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018e0:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801018e3:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
801018e7:	81 7d f4 54 fd 10 80 	cmpl   $0x8010fd54,-0xc(%ebp)
801018ee:	72 9e                	jb     8010188e <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801018f0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801018f4:	75 0c                	jne    80101902 <iget+0x96>
    panic("iget: no inodes");
801018f6:	c7 04 24 84 83 10 80 	movl   $0x80108384,(%esp)
801018fd:	e8 3b ec ff ff       	call   8010053d <panic>

  ip = empty;
80101902:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101905:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80101908:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010190b:	8b 55 08             	mov    0x8(%ebp),%edx
8010190e:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80101910:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101913:	8b 55 0c             	mov    0xc(%ebp),%edx
80101916:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101919:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010191c:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
80101923:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101926:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
8010192d:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101934:	e8 d4 33 00 00       	call   80104d0d <release>

  return ip;
80101939:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010193c:	c9                   	leave  
8010193d:	c3                   	ret    

8010193e <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
8010193e:	55                   	push   %ebp
8010193f:	89 e5                	mov    %esp,%ebp
80101941:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101944:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
8010194b:	e8 5b 33 00 00       	call   80104cab <acquire>
  ip->ref++;
80101950:	8b 45 08             	mov    0x8(%ebp),%eax
80101953:	8b 40 08             	mov    0x8(%eax),%eax
80101956:	8d 50 01             	lea    0x1(%eax),%edx
80101959:	8b 45 08             	mov    0x8(%ebp),%eax
8010195c:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010195f:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101966:	e8 a2 33 00 00       	call   80104d0d <release>
  return ip;
8010196b:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010196e:	c9                   	leave  
8010196f:	c3                   	ret    

80101970 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101970:	55                   	push   %ebp
80101971:	89 e5                	mov    %esp,%ebp
80101973:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101976:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010197a:	74 0a                	je     80101986 <ilock+0x16>
8010197c:	8b 45 08             	mov    0x8(%ebp),%eax
8010197f:	8b 40 08             	mov    0x8(%eax),%eax
80101982:	85 c0                	test   %eax,%eax
80101984:	7f 0c                	jg     80101992 <ilock+0x22>
    panic("ilock");
80101986:	c7 04 24 94 83 10 80 	movl   $0x80108394,(%esp)
8010198d:	e8 ab eb ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80101992:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101999:	e8 0d 33 00 00       	call   80104cab <acquire>
  while(ip->flags & I_BUSY)
8010199e:	eb 13                	jmp    801019b3 <ilock+0x43>
    sleep(ip, &icache.lock);
801019a0:	c7 44 24 04 80 ed 10 	movl   $0x8010ed80,0x4(%esp)
801019a7:	80 
801019a8:	8b 45 08             	mov    0x8(%ebp),%eax
801019ab:	89 04 24             	mov    %eax,(%esp)
801019ae:	e8 1a 30 00 00       	call   801049cd <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
801019b3:	8b 45 08             	mov    0x8(%ebp),%eax
801019b6:	8b 40 0c             	mov    0xc(%eax),%eax
801019b9:	83 e0 01             	and    $0x1,%eax
801019bc:	84 c0                	test   %al,%al
801019be:	75 e0                	jne    801019a0 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
801019c0:	8b 45 08             	mov    0x8(%ebp),%eax
801019c3:	8b 40 0c             	mov    0xc(%eax),%eax
801019c6:	89 c2                	mov    %eax,%edx
801019c8:	83 ca 01             	or     $0x1,%edx
801019cb:	8b 45 08             	mov    0x8(%ebp),%eax
801019ce:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
801019d1:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
801019d8:	e8 30 33 00 00       	call   80104d0d <release>

  if(!(ip->flags & I_VALID)){
801019dd:	8b 45 08             	mov    0x8(%ebp),%eax
801019e0:	8b 40 0c             	mov    0xc(%eax),%eax
801019e3:	83 e0 02             	and    $0x2,%eax
801019e6:	85 c0                	test   %eax,%eax
801019e8:	0f 85 ce 00 00 00    	jne    80101abc <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
801019ee:	8b 45 08             	mov    0x8(%ebp),%eax
801019f1:	8b 40 04             	mov    0x4(%eax),%eax
801019f4:	c1 e8 03             	shr    $0x3,%eax
801019f7:	8d 50 02             	lea    0x2(%eax),%edx
801019fa:	8b 45 08             	mov    0x8(%ebp),%eax
801019fd:	8b 00                	mov    (%eax),%eax
801019ff:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a03:	89 04 24             	mov    %eax,(%esp)
80101a06:	e8 9b e7 ff ff       	call   801001a6 <bread>
80101a0b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101a0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a11:	8d 50 18             	lea    0x18(%eax),%edx
80101a14:	8b 45 08             	mov    0x8(%ebp),%eax
80101a17:	8b 40 04             	mov    0x4(%eax),%eax
80101a1a:	83 e0 07             	and    $0x7,%eax
80101a1d:	c1 e0 06             	shl    $0x6,%eax
80101a20:	01 d0                	add    %edx,%eax
80101a22:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101a25:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a28:	0f b7 10             	movzwl (%eax),%edx
80101a2b:	8b 45 08             	mov    0x8(%ebp),%eax
80101a2e:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80101a32:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a35:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101a39:	8b 45 08             	mov    0x8(%ebp),%eax
80101a3c:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101a40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a43:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101a47:	8b 45 08             	mov    0x8(%ebp),%eax
80101a4a:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101a4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a51:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101a55:	8b 45 08             	mov    0x8(%ebp),%eax
80101a58:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101a5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a5f:	8b 50 08             	mov    0x8(%eax),%edx
80101a62:	8b 45 08             	mov    0x8(%ebp),%eax
80101a65:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101a68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a6b:	8d 50 0c             	lea    0xc(%eax),%edx
80101a6e:	8b 45 08             	mov    0x8(%ebp),%eax
80101a71:	83 c0 1c             	add    $0x1c,%eax
80101a74:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101a7b:	00 
80101a7c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a80:	89 04 24             	mov    %eax,(%esp)
80101a83:	e8 45 35 00 00       	call   80104fcd <memmove>
    brelse(bp);
80101a88:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a8b:	89 04 24             	mov    %eax,(%esp)
80101a8e:	e8 84 e7 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80101a93:	8b 45 08             	mov    0x8(%ebp),%eax
80101a96:	8b 40 0c             	mov    0xc(%eax),%eax
80101a99:	89 c2                	mov    %eax,%edx
80101a9b:	83 ca 02             	or     $0x2,%edx
80101a9e:	8b 45 08             	mov    0x8(%ebp),%eax
80101aa1:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80101aa4:	8b 45 08             	mov    0x8(%ebp),%eax
80101aa7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101aab:	66 85 c0             	test   %ax,%ax
80101aae:	75 0c                	jne    80101abc <ilock+0x14c>
      panic("ilock: no type");
80101ab0:	c7 04 24 9a 83 10 80 	movl   $0x8010839a,(%esp)
80101ab7:	e8 81 ea ff ff       	call   8010053d <panic>
  }
}
80101abc:	c9                   	leave  
80101abd:	c3                   	ret    

80101abe <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101abe:	55                   	push   %ebp
80101abf:	89 e5                	mov    %esp,%ebp
80101ac1:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80101ac4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101ac8:	74 17                	je     80101ae1 <iunlock+0x23>
80101aca:	8b 45 08             	mov    0x8(%ebp),%eax
80101acd:	8b 40 0c             	mov    0xc(%eax),%eax
80101ad0:	83 e0 01             	and    $0x1,%eax
80101ad3:	85 c0                	test   %eax,%eax
80101ad5:	74 0a                	je     80101ae1 <iunlock+0x23>
80101ad7:	8b 45 08             	mov    0x8(%ebp),%eax
80101ada:	8b 40 08             	mov    0x8(%eax),%eax
80101add:	85 c0                	test   %eax,%eax
80101adf:	7f 0c                	jg     80101aed <iunlock+0x2f>
    panic("iunlock");
80101ae1:	c7 04 24 a9 83 10 80 	movl   $0x801083a9,(%esp)
80101ae8:	e8 50 ea ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80101aed:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101af4:	e8 b2 31 00 00       	call   80104cab <acquire>
  ip->flags &= ~I_BUSY;
80101af9:	8b 45 08             	mov    0x8(%ebp),%eax
80101afc:	8b 40 0c             	mov    0xc(%eax),%eax
80101aff:	89 c2                	mov    %eax,%edx
80101b01:	83 e2 fe             	and    $0xfffffffe,%edx
80101b04:	8b 45 08             	mov    0x8(%ebp),%eax
80101b07:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101b0a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b0d:	89 04 24             	mov    %eax,(%esp)
80101b10:	e8 91 2f 00 00       	call   80104aa6 <wakeup>
  release(&icache.lock);
80101b15:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101b1c:	e8 ec 31 00 00       	call   80104d0d <release>
}
80101b21:	c9                   	leave  
80101b22:	c3                   	ret    

80101b23 <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
80101b23:	55                   	push   %ebp
80101b24:	89 e5                	mov    %esp,%ebp
80101b26:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101b29:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101b30:	e8 76 31 00 00       	call   80104cab <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101b35:	8b 45 08             	mov    0x8(%ebp),%eax
80101b38:	8b 40 08             	mov    0x8(%eax),%eax
80101b3b:	83 f8 01             	cmp    $0x1,%eax
80101b3e:	0f 85 93 00 00 00    	jne    80101bd7 <iput+0xb4>
80101b44:	8b 45 08             	mov    0x8(%ebp),%eax
80101b47:	8b 40 0c             	mov    0xc(%eax),%eax
80101b4a:	83 e0 02             	and    $0x2,%eax
80101b4d:	85 c0                	test   %eax,%eax
80101b4f:	0f 84 82 00 00 00    	je     80101bd7 <iput+0xb4>
80101b55:	8b 45 08             	mov    0x8(%ebp),%eax
80101b58:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101b5c:	66 85 c0             	test   %ax,%ax
80101b5f:	75 76                	jne    80101bd7 <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
80101b61:	8b 45 08             	mov    0x8(%ebp),%eax
80101b64:	8b 40 0c             	mov    0xc(%eax),%eax
80101b67:	83 e0 01             	and    $0x1,%eax
80101b6a:	84 c0                	test   %al,%al
80101b6c:	74 0c                	je     80101b7a <iput+0x57>
      panic("iput busy");
80101b6e:	c7 04 24 b1 83 10 80 	movl   $0x801083b1,(%esp)
80101b75:	e8 c3 e9 ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
80101b7a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b7d:	8b 40 0c             	mov    0xc(%eax),%eax
80101b80:	89 c2                	mov    %eax,%edx
80101b82:	83 ca 01             	or     $0x1,%edx
80101b85:	8b 45 08             	mov    0x8(%ebp),%eax
80101b88:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101b8b:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101b92:	e8 76 31 00 00       	call   80104d0d <release>
    itrunc(ip);
80101b97:	8b 45 08             	mov    0x8(%ebp),%eax
80101b9a:	89 04 24             	mov    %eax,(%esp)
80101b9d:	e8 72 01 00 00       	call   80101d14 <itrunc>
    ip->type = 0;
80101ba2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ba5:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101bab:	8b 45 08             	mov    0x8(%ebp),%eax
80101bae:	89 04 24             	mov    %eax,(%esp)
80101bb1:	e8 fe fb ff ff       	call   801017b4 <iupdate>
    acquire(&icache.lock);
80101bb6:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101bbd:	e8 e9 30 00 00       	call   80104cab <acquire>
    ip->flags = 0;
80101bc2:	8b 45 08             	mov    0x8(%ebp),%eax
80101bc5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101bcc:	8b 45 08             	mov    0x8(%ebp),%eax
80101bcf:	89 04 24             	mov    %eax,(%esp)
80101bd2:	e8 cf 2e 00 00       	call   80104aa6 <wakeup>
  }
  ip->ref--;
80101bd7:	8b 45 08             	mov    0x8(%ebp),%eax
80101bda:	8b 40 08             	mov    0x8(%eax),%eax
80101bdd:	8d 50 ff             	lea    -0x1(%eax),%edx
80101be0:	8b 45 08             	mov    0x8(%ebp),%eax
80101be3:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101be6:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101bed:	e8 1b 31 00 00       	call   80104d0d <release>
}
80101bf2:	c9                   	leave  
80101bf3:	c3                   	ret    

80101bf4 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101bf4:	55                   	push   %ebp
80101bf5:	89 e5                	mov    %esp,%ebp
80101bf7:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101bfa:	8b 45 08             	mov    0x8(%ebp),%eax
80101bfd:	89 04 24             	mov    %eax,(%esp)
80101c00:	e8 b9 fe ff ff       	call   80101abe <iunlock>
  iput(ip);
80101c05:	8b 45 08             	mov    0x8(%ebp),%eax
80101c08:	89 04 24             	mov    %eax,(%esp)
80101c0b:	e8 13 ff ff ff       	call   80101b23 <iput>
}
80101c10:	c9                   	leave  
80101c11:	c3                   	ret    

80101c12 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101c12:	55                   	push   %ebp
80101c13:	89 e5                	mov    %esp,%ebp
80101c15:	53                   	push   %ebx
80101c16:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101c19:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101c1d:	77 3e                	ja     80101c5d <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101c1f:	8b 45 08             	mov    0x8(%ebp),%eax
80101c22:	8b 55 0c             	mov    0xc(%ebp),%edx
80101c25:	83 c2 04             	add    $0x4,%edx
80101c28:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c2c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c2f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c33:	75 20                	jne    80101c55 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101c35:	8b 45 08             	mov    0x8(%ebp),%eax
80101c38:	8b 00                	mov    (%eax),%eax
80101c3a:	89 04 24             	mov    %eax,(%esp)
80101c3d:	e8 49 f8 ff ff       	call   8010148b <balloc>
80101c42:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c45:	8b 45 08             	mov    0x8(%ebp),%eax
80101c48:	8b 55 0c             	mov    0xc(%ebp),%edx
80101c4b:	8d 4a 04             	lea    0x4(%edx),%ecx
80101c4e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c51:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101c55:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c58:	e9 b1 00 00 00       	jmp    80101d0e <bmap+0xfc>
  }
  bn -= NDIRECT;
80101c5d:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101c61:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101c65:	0f 87 97 00 00 00    	ja     80101d02 <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101c6b:	8b 45 08             	mov    0x8(%ebp),%eax
80101c6e:	8b 40 4c             	mov    0x4c(%eax),%eax
80101c71:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c74:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c78:	75 19                	jne    80101c93 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101c7a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c7d:	8b 00                	mov    (%eax),%eax
80101c7f:	89 04 24             	mov    %eax,(%esp)
80101c82:	e8 04 f8 ff ff       	call   8010148b <balloc>
80101c87:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c8a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c8d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c90:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101c93:	8b 45 08             	mov    0x8(%ebp),%eax
80101c96:	8b 00                	mov    (%eax),%eax
80101c98:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c9b:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c9f:	89 04 24             	mov    %eax,(%esp)
80101ca2:	e8 ff e4 ff ff       	call   801001a6 <bread>
80101ca7:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101caa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cad:	83 c0 18             	add    $0x18,%eax
80101cb0:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101cb3:	8b 45 0c             	mov    0xc(%ebp),%eax
80101cb6:	c1 e0 02             	shl    $0x2,%eax
80101cb9:	03 45 ec             	add    -0x14(%ebp),%eax
80101cbc:	8b 00                	mov    (%eax),%eax
80101cbe:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101cc1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101cc5:	75 2b                	jne    80101cf2 <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
80101cc7:	8b 45 0c             	mov    0xc(%ebp),%eax
80101cca:	c1 e0 02             	shl    $0x2,%eax
80101ccd:	89 c3                	mov    %eax,%ebx
80101ccf:	03 5d ec             	add    -0x14(%ebp),%ebx
80101cd2:	8b 45 08             	mov    0x8(%ebp),%eax
80101cd5:	8b 00                	mov    (%eax),%eax
80101cd7:	89 04 24             	mov    %eax,(%esp)
80101cda:	e8 ac f7 ff ff       	call   8010148b <balloc>
80101cdf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101ce2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ce5:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101ce7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cea:	89 04 24             	mov    %eax,(%esp)
80101ced:	e8 d4 16 00 00       	call   801033c6 <log_write>
    }
    brelse(bp);
80101cf2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cf5:	89 04 24             	mov    %eax,(%esp)
80101cf8:	e8 1a e5 ff ff       	call   80100217 <brelse>
    return addr;
80101cfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d00:	eb 0c                	jmp    80101d0e <bmap+0xfc>
  }

  panic("bmap: out of range");
80101d02:	c7 04 24 bb 83 10 80 	movl   $0x801083bb,(%esp)
80101d09:	e8 2f e8 ff ff       	call   8010053d <panic>
}
80101d0e:	83 c4 24             	add    $0x24,%esp
80101d11:	5b                   	pop    %ebx
80101d12:	5d                   	pop    %ebp
80101d13:	c3                   	ret    

80101d14 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101d14:	55                   	push   %ebp
80101d15:	89 e5                	mov    %esp,%ebp
80101d17:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101d1a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101d21:	eb 44                	jmp    80101d67 <itrunc+0x53>
    if(ip->addrs[i]){
80101d23:	8b 45 08             	mov    0x8(%ebp),%eax
80101d26:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d29:	83 c2 04             	add    $0x4,%edx
80101d2c:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101d30:	85 c0                	test   %eax,%eax
80101d32:	74 2f                	je     80101d63 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101d34:	8b 45 08             	mov    0x8(%ebp),%eax
80101d37:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d3a:	83 c2 04             	add    $0x4,%edx
80101d3d:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101d41:	8b 45 08             	mov    0x8(%ebp),%eax
80101d44:	8b 00                	mov    (%eax),%eax
80101d46:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d4a:	89 04 24             	mov    %eax,(%esp)
80101d4d:	e8 90 f8 ff ff       	call   801015e2 <bfree>
      ip->addrs[i] = 0;
80101d52:	8b 45 08             	mov    0x8(%ebp),%eax
80101d55:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d58:	83 c2 04             	add    $0x4,%edx
80101d5b:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101d62:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101d63:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101d67:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101d6b:	7e b6                	jle    80101d23 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101d6d:	8b 45 08             	mov    0x8(%ebp),%eax
80101d70:	8b 40 4c             	mov    0x4c(%eax),%eax
80101d73:	85 c0                	test   %eax,%eax
80101d75:	0f 84 8f 00 00 00    	je     80101e0a <itrunc+0xf6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101d7b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d7e:	8b 50 4c             	mov    0x4c(%eax),%edx
80101d81:	8b 45 08             	mov    0x8(%ebp),%eax
80101d84:	8b 00                	mov    (%eax),%eax
80101d86:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d8a:	89 04 24             	mov    %eax,(%esp)
80101d8d:	e8 14 e4 ff ff       	call   801001a6 <bread>
80101d92:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101d95:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d98:	83 c0 18             	add    $0x18,%eax
80101d9b:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101d9e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101da5:	eb 2f                	jmp    80101dd6 <itrunc+0xc2>
      if(a[j])
80101da7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101daa:	c1 e0 02             	shl    $0x2,%eax
80101dad:	03 45 e8             	add    -0x18(%ebp),%eax
80101db0:	8b 00                	mov    (%eax),%eax
80101db2:	85 c0                	test   %eax,%eax
80101db4:	74 1c                	je     80101dd2 <itrunc+0xbe>
        bfree(ip->dev, a[j]);
80101db6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101db9:	c1 e0 02             	shl    $0x2,%eax
80101dbc:	03 45 e8             	add    -0x18(%ebp),%eax
80101dbf:	8b 10                	mov    (%eax),%edx
80101dc1:	8b 45 08             	mov    0x8(%ebp),%eax
80101dc4:	8b 00                	mov    (%eax),%eax
80101dc6:	89 54 24 04          	mov    %edx,0x4(%esp)
80101dca:	89 04 24             	mov    %eax,(%esp)
80101dcd:	e8 10 f8 ff ff       	call   801015e2 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101dd2:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101dd6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101dd9:	83 f8 7f             	cmp    $0x7f,%eax
80101ddc:	76 c9                	jbe    80101da7 <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101dde:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101de1:	89 04 24             	mov    %eax,(%esp)
80101de4:	e8 2e e4 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101de9:	8b 45 08             	mov    0x8(%ebp),%eax
80101dec:	8b 50 4c             	mov    0x4c(%eax),%edx
80101def:	8b 45 08             	mov    0x8(%ebp),%eax
80101df2:	8b 00                	mov    (%eax),%eax
80101df4:	89 54 24 04          	mov    %edx,0x4(%esp)
80101df8:	89 04 24             	mov    %eax,(%esp)
80101dfb:	e8 e2 f7 ff ff       	call   801015e2 <bfree>
    ip->addrs[NDIRECT] = 0;
80101e00:	8b 45 08             	mov    0x8(%ebp),%eax
80101e03:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101e0a:	8b 45 08             	mov    0x8(%ebp),%eax
80101e0d:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101e14:	8b 45 08             	mov    0x8(%ebp),%eax
80101e17:	89 04 24             	mov    %eax,(%esp)
80101e1a:	e8 95 f9 ff ff       	call   801017b4 <iupdate>
}
80101e1f:	c9                   	leave  
80101e20:	c3                   	ret    

80101e21 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101e21:	55                   	push   %ebp
80101e22:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101e24:	8b 45 08             	mov    0x8(%ebp),%eax
80101e27:	8b 00                	mov    (%eax),%eax
80101e29:	89 c2                	mov    %eax,%edx
80101e2b:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e2e:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101e31:	8b 45 08             	mov    0x8(%ebp),%eax
80101e34:	8b 50 04             	mov    0x4(%eax),%edx
80101e37:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e3a:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101e3d:	8b 45 08             	mov    0x8(%ebp),%eax
80101e40:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101e44:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e47:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101e4a:	8b 45 08             	mov    0x8(%ebp),%eax
80101e4d:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101e51:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e54:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101e58:	8b 45 08             	mov    0x8(%ebp),%eax
80101e5b:	8b 50 18             	mov    0x18(%eax),%edx
80101e5e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e61:	89 50 10             	mov    %edx,0x10(%eax)
}
80101e64:	5d                   	pop    %ebp
80101e65:	c3                   	ret    

80101e66 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101e66:	55                   	push   %ebp
80101e67:	89 e5                	mov    %esp,%ebp
80101e69:	53                   	push   %ebx
80101e6a:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101e6d:	8b 45 08             	mov    0x8(%ebp),%eax
80101e70:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101e74:	66 83 f8 03          	cmp    $0x3,%ax
80101e78:	75 60                	jne    80101eda <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101e7a:	8b 45 08             	mov    0x8(%ebp),%eax
80101e7d:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e81:	66 85 c0             	test   %ax,%ax
80101e84:	78 20                	js     80101ea6 <readi+0x40>
80101e86:	8b 45 08             	mov    0x8(%ebp),%eax
80101e89:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e8d:	66 83 f8 09          	cmp    $0x9,%ax
80101e91:	7f 13                	jg     80101ea6 <readi+0x40>
80101e93:	8b 45 08             	mov    0x8(%ebp),%eax
80101e96:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e9a:	98                   	cwtl   
80101e9b:	8b 04 c5 20 ed 10 80 	mov    -0x7fef12e0(,%eax,8),%eax
80101ea2:	85 c0                	test   %eax,%eax
80101ea4:	75 0a                	jne    80101eb0 <readi+0x4a>
      return -1;
80101ea6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101eab:	e9 1b 01 00 00       	jmp    80101fcb <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80101eb0:	8b 45 08             	mov    0x8(%ebp),%eax
80101eb3:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101eb7:	98                   	cwtl   
80101eb8:	8b 14 c5 20 ed 10 80 	mov    -0x7fef12e0(,%eax,8),%edx
80101ebf:	8b 45 14             	mov    0x14(%ebp),%eax
80101ec2:	89 44 24 08          	mov    %eax,0x8(%esp)
80101ec6:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ec9:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ecd:	8b 45 08             	mov    0x8(%ebp),%eax
80101ed0:	89 04 24             	mov    %eax,(%esp)
80101ed3:	ff d2                	call   *%edx
80101ed5:	e9 f1 00 00 00       	jmp    80101fcb <readi+0x165>
  }

  if(off > ip->size || off + n < off)
80101eda:	8b 45 08             	mov    0x8(%ebp),%eax
80101edd:	8b 40 18             	mov    0x18(%eax),%eax
80101ee0:	3b 45 10             	cmp    0x10(%ebp),%eax
80101ee3:	72 0d                	jb     80101ef2 <readi+0x8c>
80101ee5:	8b 45 14             	mov    0x14(%ebp),%eax
80101ee8:	8b 55 10             	mov    0x10(%ebp),%edx
80101eeb:	01 d0                	add    %edx,%eax
80101eed:	3b 45 10             	cmp    0x10(%ebp),%eax
80101ef0:	73 0a                	jae    80101efc <readi+0x96>
    return -1;
80101ef2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101ef7:	e9 cf 00 00 00       	jmp    80101fcb <readi+0x165>
  if(off + n > ip->size)
80101efc:	8b 45 14             	mov    0x14(%ebp),%eax
80101eff:	8b 55 10             	mov    0x10(%ebp),%edx
80101f02:	01 c2                	add    %eax,%edx
80101f04:	8b 45 08             	mov    0x8(%ebp),%eax
80101f07:	8b 40 18             	mov    0x18(%eax),%eax
80101f0a:	39 c2                	cmp    %eax,%edx
80101f0c:	76 0c                	jbe    80101f1a <readi+0xb4>
    n = ip->size - off;
80101f0e:	8b 45 08             	mov    0x8(%ebp),%eax
80101f11:	8b 40 18             	mov    0x18(%eax),%eax
80101f14:	2b 45 10             	sub    0x10(%ebp),%eax
80101f17:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101f1a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101f21:	e9 96 00 00 00       	jmp    80101fbc <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101f26:	8b 45 10             	mov    0x10(%ebp),%eax
80101f29:	c1 e8 09             	shr    $0x9,%eax
80101f2c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f30:	8b 45 08             	mov    0x8(%ebp),%eax
80101f33:	89 04 24             	mov    %eax,(%esp)
80101f36:	e8 d7 fc ff ff       	call   80101c12 <bmap>
80101f3b:	8b 55 08             	mov    0x8(%ebp),%edx
80101f3e:	8b 12                	mov    (%edx),%edx
80101f40:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f44:	89 14 24             	mov    %edx,(%esp)
80101f47:	e8 5a e2 ff ff       	call   801001a6 <bread>
80101f4c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101f4f:	8b 45 10             	mov    0x10(%ebp),%eax
80101f52:	89 c2                	mov    %eax,%edx
80101f54:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80101f5a:	b8 00 02 00 00       	mov    $0x200,%eax
80101f5f:	89 c1                	mov    %eax,%ecx
80101f61:	29 d1                	sub    %edx,%ecx
80101f63:	89 ca                	mov    %ecx,%edx
80101f65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f68:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101f6b:	89 cb                	mov    %ecx,%ebx
80101f6d:	29 c3                	sub    %eax,%ebx
80101f6f:	89 d8                	mov    %ebx,%eax
80101f71:	39 c2                	cmp    %eax,%edx
80101f73:	0f 46 c2             	cmovbe %edx,%eax
80101f76:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101f79:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f7c:	8d 50 18             	lea    0x18(%eax),%edx
80101f7f:	8b 45 10             	mov    0x10(%ebp),%eax
80101f82:	25 ff 01 00 00       	and    $0x1ff,%eax
80101f87:	01 c2                	add    %eax,%edx
80101f89:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f8c:	89 44 24 08          	mov    %eax,0x8(%esp)
80101f90:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f94:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f97:	89 04 24             	mov    %eax,(%esp)
80101f9a:	e8 2e 30 00 00       	call   80104fcd <memmove>
    brelse(bp);
80101f9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fa2:	89 04 24             	mov    %eax,(%esp)
80101fa5:	e8 6d e2 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101faa:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fad:	01 45 f4             	add    %eax,-0xc(%ebp)
80101fb0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fb3:	01 45 10             	add    %eax,0x10(%ebp)
80101fb6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fb9:	01 45 0c             	add    %eax,0xc(%ebp)
80101fbc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101fbf:	3b 45 14             	cmp    0x14(%ebp),%eax
80101fc2:	0f 82 5e ff ff ff    	jb     80101f26 <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80101fc8:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101fcb:	83 c4 24             	add    $0x24,%esp
80101fce:	5b                   	pop    %ebx
80101fcf:	5d                   	pop    %ebp
80101fd0:	c3                   	ret    

80101fd1 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101fd1:	55                   	push   %ebp
80101fd2:	89 e5                	mov    %esp,%ebp
80101fd4:	53                   	push   %ebx
80101fd5:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101fd8:	8b 45 08             	mov    0x8(%ebp),%eax
80101fdb:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101fdf:	66 83 f8 03          	cmp    $0x3,%ax
80101fe3:	75 60                	jne    80102045 <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101fe5:	8b 45 08             	mov    0x8(%ebp),%eax
80101fe8:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101fec:	66 85 c0             	test   %ax,%ax
80101fef:	78 20                	js     80102011 <writei+0x40>
80101ff1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ff4:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ff8:	66 83 f8 09          	cmp    $0x9,%ax
80101ffc:	7f 13                	jg     80102011 <writei+0x40>
80101ffe:	8b 45 08             	mov    0x8(%ebp),%eax
80102001:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102005:	98                   	cwtl   
80102006:	8b 04 c5 24 ed 10 80 	mov    -0x7fef12dc(,%eax,8),%eax
8010200d:	85 c0                	test   %eax,%eax
8010200f:	75 0a                	jne    8010201b <writei+0x4a>
      return -1;
80102011:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102016:	e9 46 01 00 00       	jmp    80102161 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
8010201b:	8b 45 08             	mov    0x8(%ebp),%eax
8010201e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102022:	98                   	cwtl   
80102023:	8b 14 c5 24 ed 10 80 	mov    -0x7fef12dc(,%eax,8),%edx
8010202a:	8b 45 14             	mov    0x14(%ebp),%eax
8010202d:	89 44 24 08          	mov    %eax,0x8(%esp)
80102031:	8b 45 0c             	mov    0xc(%ebp),%eax
80102034:	89 44 24 04          	mov    %eax,0x4(%esp)
80102038:	8b 45 08             	mov    0x8(%ebp),%eax
8010203b:	89 04 24             	mov    %eax,(%esp)
8010203e:	ff d2                	call   *%edx
80102040:	e9 1c 01 00 00       	jmp    80102161 <writei+0x190>
  }

  if(off > ip->size || off + n < off)
80102045:	8b 45 08             	mov    0x8(%ebp),%eax
80102048:	8b 40 18             	mov    0x18(%eax),%eax
8010204b:	3b 45 10             	cmp    0x10(%ebp),%eax
8010204e:	72 0d                	jb     8010205d <writei+0x8c>
80102050:	8b 45 14             	mov    0x14(%ebp),%eax
80102053:	8b 55 10             	mov    0x10(%ebp),%edx
80102056:	01 d0                	add    %edx,%eax
80102058:	3b 45 10             	cmp    0x10(%ebp),%eax
8010205b:	73 0a                	jae    80102067 <writei+0x96>
    return -1;
8010205d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102062:	e9 fa 00 00 00       	jmp    80102161 <writei+0x190>
  if(off + n > MAXFILE*BSIZE)
80102067:	8b 45 14             	mov    0x14(%ebp),%eax
8010206a:	8b 55 10             	mov    0x10(%ebp),%edx
8010206d:	01 d0                	add    %edx,%eax
8010206f:	3d 00 18 01 00       	cmp    $0x11800,%eax
80102074:	76 0a                	jbe    80102080 <writei+0xaf>
    return -1;
80102076:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010207b:	e9 e1 00 00 00       	jmp    80102161 <writei+0x190>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102080:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102087:	e9 a1 00 00 00       	jmp    8010212d <writei+0x15c>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
8010208c:	8b 45 10             	mov    0x10(%ebp),%eax
8010208f:	c1 e8 09             	shr    $0x9,%eax
80102092:	89 44 24 04          	mov    %eax,0x4(%esp)
80102096:	8b 45 08             	mov    0x8(%ebp),%eax
80102099:	89 04 24             	mov    %eax,(%esp)
8010209c:	e8 71 fb ff ff       	call   80101c12 <bmap>
801020a1:	8b 55 08             	mov    0x8(%ebp),%edx
801020a4:	8b 12                	mov    (%edx),%edx
801020a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801020aa:	89 14 24             	mov    %edx,(%esp)
801020ad:	e8 f4 e0 ff ff       	call   801001a6 <bread>
801020b2:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
801020b5:	8b 45 10             	mov    0x10(%ebp),%eax
801020b8:	89 c2                	mov    %eax,%edx
801020ba:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
801020c0:	b8 00 02 00 00       	mov    $0x200,%eax
801020c5:	89 c1                	mov    %eax,%ecx
801020c7:	29 d1                	sub    %edx,%ecx
801020c9:	89 ca                	mov    %ecx,%edx
801020cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020ce:	8b 4d 14             	mov    0x14(%ebp),%ecx
801020d1:	89 cb                	mov    %ecx,%ebx
801020d3:	29 c3                	sub    %eax,%ebx
801020d5:	89 d8                	mov    %ebx,%eax
801020d7:	39 c2                	cmp    %eax,%edx
801020d9:	0f 46 c2             	cmovbe %edx,%eax
801020dc:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
801020df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020e2:	8d 50 18             	lea    0x18(%eax),%edx
801020e5:	8b 45 10             	mov    0x10(%ebp),%eax
801020e8:	25 ff 01 00 00       	and    $0x1ff,%eax
801020ed:	01 c2                	add    %eax,%edx
801020ef:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020f2:	89 44 24 08          	mov    %eax,0x8(%esp)
801020f6:	8b 45 0c             	mov    0xc(%ebp),%eax
801020f9:	89 44 24 04          	mov    %eax,0x4(%esp)
801020fd:	89 14 24             	mov    %edx,(%esp)
80102100:	e8 c8 2e 00 00       	call   80104fcd <memmove>
    log_write(bp);
80102105:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102108:	89 04 24             	mov    %eax,(%esp)
8010210b:	e8 b6 12 00 00       	call   801033c6 <log_write>
    brelse(bp);
80102110:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102113:	89 04 24             	mov    %eax,(%esp)
80102116:	e8 fc e0 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010211b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010211e:	01 45 f4             	add    %eax,-0xc(%ebp)
80102121:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102124:	01 45 10             	add    %eax,0x10(%ebp)
80102127:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010212a:	01 45 0c             	add    %eax,0xc(%ebp)
8010212d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102130:	3b 45 14             	cmp    0x14(%ebp),%eax
80102133:	0f 82 53 ff ff ff    	jb     8010208c <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102139:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010213d:	74 1f                	je     8010215e <writei+0x18d>
8010213f:	8b 45 08             	mov    0x8(%ebp),%eax
80102142:	8b 40 18             	mov    0x18(%eax),%eax
80102145:	3b 45 10             	cmp    0x10(%ebp),%eax
80102148:	73 14                	jae    8010215e <writei+0x18d>
    ip->size = off;
8010214a:	8b 45 08             	mov    0x8(%ebp),%eax
8010214d:	8b 55 10             	mov    0x10(%ebp),%edx
80102150:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102153:	8b 45 08             	mov    0x8(%ebp),%eax
80102156:	89 04 24             	mov    %eax,(%esp)
80102159:	e8 56 f6 ff ff       	call   801017b4 <iupdate>
  }
  return n;
8010215e:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102161:	83 c4 24             	add    $0x24,%esp
80102164:	5b                   	pop    %ebx
80102165:	5d                   	pop    %ebp
80102166:	c3                   	ret    

80102167 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102167:	55                   	push   %ebp
80102168:	89 e5                	mov    %esp,%ebp
8010216a:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
8010216d:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102174:	00 
80102175:	8b 45 0c             	mov    0xc(%ebp),%eax
80102178:	89 44 24 04          	mov    %eax,0x4(%esp)
8010217c:	8b 45 08             	mov    0x8(%ebp),%eax
8010217f:	89 04 24             	mov    %eax,(%esp)
80102182:	e8 ea 2e 00 00       	call   80105071 <strncmp>
}
80102187:	c9                   	leave  
80102188:	c3                   	ret    

80102189 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102189:	55                   	push   %ebp
8010218a:	89 e5                	mov    %esp,%ebp
8010218c:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
8010218f:	8b 45 08             	mov    0x8(%ebp),%eax
80102192:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102196:	66 83 f8 01          	cmp    $0x1,%ax
8010219a:	74 0c                	je     801021a8 <dirlookup+0x1f>
    panic("dirlookup not DIR");
8010219c:	c7 04 24 ce 83 10 80 	movl   $0x801083ce,(%esp)
801021a3:	e8 95 e3 ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
801021a8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801021af:	e9 87 00 00 00       	jmp    8010223b <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801021b4:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801021bb:	00 
801021bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021bf:	89 44 24 08          	mov    %eax,0x8(%esp)
801021c3:	8d 45 e0             	lea    -0x20(%ebp),%eax
801021c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801021ca:	8b 45 08             	mov    0x8(%ebp),%eax
801021cd:	89 04 24             	mov    %eax,(%esp)
801021d0:	e8 91 fc ff ff       	call   80101e66 <readi>
801021d5:	83 f8 10             	cmp    $0x10,%eax
801021d8:	74 0c                	je     801021e6 <dirlookup+0x5d>
      panic("dirlink read");
801021da:	c7 04 24 e0 83 10 80 	movl   $0x801083e0,(%esp)
801021e1:	e8 57 e3 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
801021e6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801021ea:	66 85 c0             	test   %ax,%ax
801021ed:	74 47                	je     80102236 <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
801021ef:	8d 45 e0             	lea    -0x20(%ebp),%eax
801021f2:	83 c0 02             	add    $0x2,%eax
801021f5:	89 44 24 04          	mov    %eax,0x4(%esp)
801021f9:	8b 45 0c             	mov    0xc(%ebp),%eax
801021fc:	89 04 24             	mov    %eax,(%esp)
801021ff:	e8 63 ff ff ff       	call   80102167 <namecmp>
80102204:	85 c0                	test   %eax,%eax
80102206:	75 2f                	jne    80102237 <dirlookup+0xae>
      // entry matches path element
      if(poff)
80102208:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010220c:	74 08                	je     80102216 <dirlookup+0x8d>
        *poff = off;
8010220e:	8b 45 10             	mov    0x10(%ebp),%eax
80102211:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102214:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102216:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010221a:	0f b7 c0             	movzwl %ax,%eax
8010221d:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102220:	8b 45 08             	mov    0x8(%ebp),%eax
80102223:	8b 00                	mov    (%eax),%eax
80102225:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102228:	89 54 24 04          	mov    %edx,0x4(%esp)
8010222c:	89 04 24             	mov    %eax,(%esp)
8010222f:	e8 38 f6 ff ff       	call   8010186c <iget>
80102234:	eb 19                	jmp    8010224f <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
80102236:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
80102237:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010223b:	8b 45 08             	mov    0x8(%ebp),%eax
8010223e:	8b 40 18             	mov    0x18(%eax),%eax
80102241:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102244:	0f 87 6a ff ff ff    	ja     801021b4 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
8010224a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010224f:	c9                   	leave  
80102250:	c3                   	ret    

80102251 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102251:	55                   	push   %ebp
80102252:	89 e5                	mov    %esp,%ebp
80102254:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102257:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010225e:	00 
8010225f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102262:	89 44 24 04          	mov    %eax,0x4(%esp)
80102266:	8b 45 08             	mov    0x8(%ebp),%eax
80102269:	89 04 24             	mov    %eax,(%esp)
8010226c:	e8 18 ff ff ff       	call   80102189 <dirlookup>
80102271:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102274:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102278:	74 15                	je     8010228f <dirlink+0x3e>
    iput(ip);
8010227a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010227d:	89 04 24             	mov    %eax,(%esp)
80102280:	e8 9e f8 ff ff       	call   80101b23 <iput>
    return -1;
80102285:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010228a:	e9 b8 00 00 00       	jmp    80102347 <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010228f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102296:	eb 44                	jmp    801022dc <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102298:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010229b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801022a2:	00 
801022a3:	89 44 24 08          	mov    %eax,0x8(%esp)
801022a7:	8d 45 e0             	lea    -0x20(%ebp),%eax
801022aa:	89 44 24 04          	mov    %eax,0x4(%esp)
801022ae:	8b 45 08             	mov    0x8(%ebp),%eax
801022b1:	89 04 24             	mov    %eax,(%esp)
801022b4:	e8 ad fb ff ff       	call   80101e66 <readi>
801022b9:	83 f8 10             	cmp    $0x10,%eax
801022bc:	74 0c                	je     801022ca <dirlink+0x79>
      panic("dirlink read");
801022be:	c7 04 24 e0 83 10 80 	movl   $0x801083e0,(%esp)
801022c5:	e8 73 e2 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
801022ca:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801022ce:	66 85 c0             	test   %ax,%ax
801022d1:	74 18                	je     801022eb <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801022d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022d6:	83 c0 10             	add    $0x10,%eax
801022d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801022dc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022df:	8b 45 08             	mov    0x8(%ebp),%eax
801022e2:	8b 40 18             	mov    0x18(%eax),%eax
801022e5:	39 c2                	cmp    %eax,%edx
801022e7:	72 af                	jb     80102298 <dirlink+0x47>
801022e9:	eb 01                	jmp    801022ec <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
801022eb:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
801022ec:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801022f3:	00 
801022f4:	8b 45 0c             	mov    0xc(%ebp),%eax
801022f7:	89 44 24 04          	mov    %eax,0x4(%esp)
801022fb:	8d 45 e0             	lea    -0x20(%ebp),%eax
801022fe:	83 c0 02             	add    $0x2,%eax
80102301:	89 04 24             	mov    %eax,(%esp)
80102304:	e8 c0 2d 00 00       	call   801050c9 <strncpy>
  de.inum = inum;
80102309:	8b 45 10             	mov    0x10(%ebp),%eax
8010230c:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102310:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102313:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010231a:	00 
8010231b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010231f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102322:	89 44 24 04          	mov    %eax,0x4(%esp)
80102326:	8b 45 08             	mov    0x8(%ebp),%eax
80102329:	89 04 24             	mov    %eax,(%esp)
8010232c:	e8 a0 fc ff ff       	call   80101fd1 <writei>
80102331:	83 f8 10             	cmp    $0x10,%eax
80102334:	74 0c                	je     80102342 <dirlink+0xf1>
    panic("dirlink");
80102336:	c7 04 24 ed 83 10 80 	movl   $0x801083ed,(%esp)
8010233d:	e8 fb e1 ff ff       	call   8010053d <panic>
  
  return 0;
80102342:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102347:	c9                   	leave  
80102348:	c3                   	ret    

80102349 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102349:	55                   	push   %ebp
8010234a:	89 e5                	mov    %esp,%ebp
8010234c:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
8010234f:	eb 04                	jmp    80102355 <skipelem+0xc>
    path++;
80102351:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102355:	8b 45 08             	mov    0x8(%ebp),%eax
80102358:	0f b6 00             	movzbl (%eax),%eax
8010235b:	3c 2f                	cmp    $0x2f,%al
8010235d:	74 f2                	je     80102351 <skipelem+0x8>
    path++;
  if(*path == 0)
8010235f:	8b 45 08             	mov    0x8(%ebp),%eax
80102362:	0f b6 00             	movzbl (%eax),%eax
80102365:	84 c0                	test   %al,%al
80102367:	75 0a                	jne    80102373 <skipelem+0x2a>
    return 0;
80102369:	b8 00 00 00 00       	mov    $0x0,%eax
8010236e:	e9 86 00 00 00       	jmp    801023f9 <skipelem+0xb0>
  s = path;
80102373:	8b 45 08             	mov    0x8(%ebp),%eax
80102376:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102379:	eb 04                	jmp    8010237f <skipelem+0x36>
    path++;
8010237b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
8010237f:	8b 45 08             	mov    0x8(%ebp),%eax
80102382:	0f b6 00             	movzbl (%eax),%eax
80102385:	3c 2f                	cmp    $0x2f,%al
80102387:	74 0a                	je     80102393 <skipelem+0x4a>
80102389:	8b 45 08             	mov    0x8(%ebp),%eax
8010238c:	0f b6 00             	movzbl (%eax),%eax
8010238f:	84 c0                	test   %al,%al
80102391:	75 e8                	jne    8010237b <skipelem+0x32>
    path++;
  len = path - s;
80102393:	8b 55 08             	mov    0x8(%ebp),%edx
80102396:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102399:	89 d1                	mov    %edx,%ecx
8010239b:	29 c1                	sub    %eax,%ecx
8010239d:	89 c8                	mov    %ecx,%eax
8010239f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
801023a2:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801023a6:	7e 1c                	jle    801023c4 <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
801023a8:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801023af:	00 
801023b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023b3:	89 44 24 04          	mov    %eax,0x4(%esp)
801023b7:	8b 45 0c             	mov    0xc(%ebp),%eax
801023ba:	89 04 24             	mov    %eax,(%esp)
801023bd:	e8 0b 2c 00 00       	call   80104fcd <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801023c2:	eb 28                	jmp    801023ec <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
801023c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023c7:	89 44 24 08          	mov    %eax,0x8(%esp)
801023cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023ce:	89 44 24 04          	mov    %eax,0x4(%esp)
801023d2:	8b 45 0c             	mov    0xc(%ebp),%eax
801023d5:	89 04 24             	mov    %eax,(%esp)
801023d8:	e8 f0 2b 00 00       	call   80104fcd <memmove>
    name[len] = 0;
801023dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023e0:	03 45 0c             	add    0xc(%ebp),%eax
801023e3:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
801023e6:	eb 04                	jmp    801023ec <skipelem+0xa3>
    path++;
801023e8:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801023ec:	8b 45 08             	mov    0x8(%ebp),%eax
801023ef:	0f b6 00             	movzbl (%eax),%eax
801023f2:	3c 2f                	cmp    $0x2f,%al
801023f4:	74 f2                	je     801023e8 <skipelem+0x9f>
    path++;
  return path;
801023f6:	8b 45 08             	mov    0x8(%ebp),%eax
}
801023f9:	c9                   	leave  
801023fa:	c3                   	ret    

801023fb <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
801023fb:	55                   	push   %ebp
801023fc:	89 e5                	mov    %esp,%ebp
801023fe:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102401:	8b 45 08             	mov    0x8(%ebp),%eax
80102404:	0f b6 00             	movzbl (%eax),%eax
80102407:	3c 2f                	cmp    $0x2f,%al
80102409:	75 1c                	jne    80102427 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
8010240b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102412:	00 
80102413:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010241a:	e8 4d f4 ff ff       	call   8010186c <iget>
8010241f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102422:	e9 af 00 00 00       	jmp    801024d6 <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
80102427:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010242d:	8b 40 68             	mov    0x68(%eax),%eax
80102430:	89 04 24             	mov    %eax,(%esp)
80102433:	e8 06 f5 ff ff       	call   8010193e <idup>
80102438:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
8010243b:	e9 96 00 00 00       	jmp    801024d6 <namex+0xdb>
    ilock(ip);
80102440:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102443:	89 04 24             	mov    %eax,(%esp)
80102446:	e8 25 f5 ff ff       	call   80101970 <ilock>
    if(ip->type != T_DIR){
8010244b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010244e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102452:	66 83 f8 01          	cmp    $0x1,%ax
80102456:	74 15                	je     8010246d <namex+0x72>
      iunlockput(ip);
80102458:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010245b:	89 04 24             	mov    %eax,(%esp)
8010245e:	e8 91 f7 ff ff       	call   80101bf4 <iunlockput>
      return 0;
80102463:	b8 00 00 00 00       	mov    $0x0,%eax
80102468:	e9 a3 00 00 00       	jmp    80102510 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
8010246d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102471:	74 1d                	je     80102490 <namex+0x95>
80102473:	8b 45 08             	mov    0x8(%ebp),%eax
80102476:	0f b6 00             	movzbl (%eax),%eax
80102479:	84 c0                	test   %al,%al
8010247b:	75 13                	jne    80102490 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
8010247d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102480:	89 04 24             	mov    %eax,(%esp)
80102483:	e8 36 f6 ff ff       	call   80101abe <iunlock>
      return ip;
80102488:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010248b:	e9 80 00 00 00       	jmp    80102510 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102490:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102497:	00 
80102498:	8b 45 10             	mov    0x10(%ebp),%eax
8010249b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010249f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024a2:	89 04 24             	mov    %eax,(%esp)
801024a5:	e8 df fc ff ff       	call   80102189 <dirlookup>
801024aa:	89 45 f0             	mov    %eax,-0x10(%ebp)
801024ad:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801024b1:	75 12                	jne    801024c5 <namex+0xca>
      iunlockput(ip);
801024b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024b6:	89 04 24             	mov    %eax,(%esp)
801024b9:	e8 36 f7 ff ff       	call   80101bf4 <iunlockput>
      return 0;
801024be:	b8 00 00 00 00       	mov    $0x0,%eax
801024c3:	eb 4b                	jmp    80102510 <namex+0x115>
    }
    iunlockput(ip);
801024c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024c8:	89 04 24             	mov    %eax,(%esp)
801024cb:	e8 24 f7 ff ff       	call   80101bf4 <iunlockput>
    ip = next;
801024d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024d3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801024d6:	8b 45 10             	mov    0x10(%ebp),%eax
801024d9:	89 44 24 04          	mov    %eax,0x4(%esp)
801024dd:	8b 45 08             	mov    0x8(%ebp),%eax
801024e0:	89 04 24             	mov    %eax,(%esp)
801024e3:	e8 61 fe ff ff       	call   80102349 <skipelem>
801024e8:	89 45 08             	mov    %eax,0x8(%ebp)
801024eb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801024ef:	0f 85 4b ff ff ff    	jne    80102440 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
801024f5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801024f9:	74 12                	je     8010250d <namex+0x112>
    iput(ip);
801024fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024fe:	89 04 24             	mov    %eax,(%esp)
80102501:	e8 1d f6 ff ff       	call   80101b23 <iput>
    return 0;
80102506:	b8 00 00 00 00       	mov    $0x0,%eax
8010250b:	eb 03                	jmp    80102510 <namex+0x115>
  }
  return ip;
8010250d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102510:	c9                   	leave  
80102511:	c3                   	ret    

80102512 <namei>:

struct inode*
namei(char *path)
{
80102512:	55                   	push   %ebp
80102513:	89 e5                	mov    %esp,%ebp
80102515:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102518:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010251b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010251f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102526:	00 
80102527:	8b 45 08             	mov    0x8(%ebp),%eax
8010252a:	89 04 24             	mov    %eax,(%esp)
8010252d:	e8 c9 fe ff ff       	call   801023fb <namex>
}
80102532:	c9                   	leave  
80102533:	c3                   	ret    

80102534 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102534:	55                   	push   %ebp
80102535:	89 e5                	mov    %esp,%ebp
80102537:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
8010253a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010253d:	89 44 24 08          	mov    %eax,0x8(%esp)
80102541:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102548:	00 
80102549:	8b 45 08             	mov    0x8(%ebp),%eax
8010254c:	89 04 24             	mov    %eax,(%esp)
8010254f:	e8 a7 fe ff ff       	call   801023fb <namex>
}
80102554:	c9                   	leave  
80102555:	c3                   	ret    
	...

80102558 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102558:	55                   	push   %ebp
80102559:	89 e5                	mov    %esp,%ebp
8010255b:	53                   	push   %ebx
8010255c:	83 ec 14             	sub    $0x14,%esp
8010255f:	8b 45 08             	mov    0x8(%ebp),%eax
80102562:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102566:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
8010256a:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010256e:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102572:	ec                   	in     (%dx),%al
80102573:	89 c3                	mov    %eax,%ebx
80102575:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102578:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
8010257c:	83 c4 14             	add    $0x14,%esp
8010257f:	5b                   	pop    %ebx
80102580:	5d                   	pop    %ebp
80102581:	c3                   	ret    

80102582 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102582:	55                   	push   %ebp
80102583:	89 e5                	mov    %esp,%ebp
80102585:	57                   	push   %edi
80102586:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102587:	8b 55 08             	mov    0x8(%ebp),%edx
8010258a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010258d:	8b 45 10             	mov    0x10(%ebp),%eax
80102590:	89 cb                	mov    %ecx,%ebx
80102592:	89 df                	mov    %ebx,%edi
80102594:	89 c1                	mov    %eax,%ecx
80102596:	fc                   	cld    
80102597:	f3 6d                	rep insl (%dx),%es:(%edi)
80102599:	89 c8                	mov    %ecx,%eax
8010259b:	89 fb                	mov    %edi,%ebx
8010259d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801025a0:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
801025a3:	5b                   	pop    %ebx
801025a4:	5f                   	pop    %edi
801025a5:	5d                   	pop    %ebp
801025a6:	c3                   	ret    

801025a7 <outb>:

static inline void
outb(ushort port, uchar data)
{
801025a7:	55                   	push   %ebp
801025a8:	89 e5                	mov    %esp,%ebp
801025aa:	83 ec 08             	sub    $0x8,%esp
801025ad:	8b 55 08             	mov    0x8(%ebp),%edx
801025b0:	8b 45 0c             	mov    0xc(%ebp),%eax
801025b3:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801025b7:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801025ba:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801025be:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801025c2:	ee                   	out    %al,(%dx)
}
801025c3:	c9                   	leave  
801025c4:	c3                   	ret    

801025c5 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
801025c5:	55                   	push   %ebp
801025c6:	89 e5                	mov    %esp,%ebp
801025c8:	56                   	push   %esi
801025c9:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
801025ca:	8b 55 08             	mov    0x8(%ebp),%edx
801025cd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801025d0:	8b 45 10             	mov    0x10(%ebp),%eax
801025d3:	89 cb                	mov    %ecx,%ebx
801025d5:	89 de                	mov    %ebx,%esi
801025d7:	89 c1                	mov    %eax,%ecx
801025d9:	fc                   	cld    
801025da:	f3 6f                	rep outsl %ds:(%esi),(%dx)
801025dc:	89 c8                	mov    %ecx,%eax
801025de:	89 f3                	mov    %esi,%ebx
801025e0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801025e3:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
801025e6:	5b                   	pop    %ebx
801025e7:	5e                   	pop    %esi
801025e8:	5d                   	pop    %ebp
801025e9:	c3                   	ret    

801025ea <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
801025ea:	55                   	push   %ebp
801025eb:	89 e5                	mov    %esp,%ebp
801025ed:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
801025f0:	90                   	nop
801025f1:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801025f8:	e8 5b ff ff ff       	call   80102558 <inb>
801025fd:	0f b6 c0             	movzbl %al,%eax
80102600:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102603:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102606:	25 c0 00 00 00       	and    $0xc0,%eax
8010260b:	83 f8 40             	cmp    $0x40,%eax
8010260e:	75 e1                	jne    801025f1 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102610:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102614:	74 11                	je     80102627 <idewait+0x3d>
80102616:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102619:	83 e0 21             	and    $0x21,%eax
8010261c:	85 c0                	test   %eax,%eax
8010261e:	74 07                	je     80102627 <idewait+0x3d>
    return -1;
80102620:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102625:	eb 05                	jmp    8010262c <idewait+0x42>
  return 0;
80102627:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010262c:	c9                   	leave  
8010262d:	c3                   	ret    

8010262e <ideinit>:

void
ideinit(void)
{
8010262e:	55                   	push   %ebp
8010262f:	89 e5                	mov    %esp,%ebp
80102631:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80102634:	c7 44 24 04 f5 83 10 	movl   $0x801083f5,0x4(%esp)
8010263b:	80 
8010263c:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102643:	e8 42 26 00 00       	call   80104c8a <initlock>
  picenable(IRQ_IDE);
80102648:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010264f:	e8 75 15 00 00       	call   80103bc9 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102654:	a1 20 04 11 80       	mov    0x80110420,%eax
80102659:	83 e8 01             	sub    $0x1,%eax
8010265c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102660:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102667:	e8 12 04 00 00       	call   80102a7e <ioapicenable>
  idewait(0);
8010266c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102673:	e8 72 ff ff ff       	call   801025ea <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102678:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
8010267f:	00 
80102680:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102687:	e8 1b ff ff ff       	call   801025a7 <outb>
  for(i=0; i<1000; i++){
8010268c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102693:	eb 20                	jmp    801026b5 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102695:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010269c:	e8 b7 fe ff ff       	call   80102558 <inb>
801026a1:	84 c0                	test   %al,%al
801026a3:	74 0c                	je     801026b1 <ideinit+0x83>
      havedisk1 = 1;
801026a5:	c7 05 38 b6 10 80 01 	movl   $0x1,0x8010b638
801026ac:	00 00 00 
      break;
801026af:	eb 0d                	jmp    801026be <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801026b1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801026b5:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801026bc:	7e d7                	jle    80102695 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801026be:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
801026c5:	00 
801026c6:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801026cd:	e8 d5 fe ff ff       	call   801025a7 <outb>
}
801026d2:	c9                   	leave  
801026d3:	c3                   	ret    

801026d4 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
801026d4:	55                   	push   %ebp
801026d5:	89 e5                	mov    %esp,%ebp
801026d7:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
801026da:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801026de:	75 0c                	jne    801026ec <idestart+0x18>
    panic("idestart");
801026e0:	c7 04 24 f9 83 10 80 	movl   $0x801083f9,(%esp)
801026e7:	e8 51 de ff ff       	call   8010053d <panic>

  idewait(0);
801026ec:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801026f3:	e8 f2 fe ff ff       	call   801025ea <idewait>
  outb(0x3f6, 0);  // generate interrupt
801026f8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801026ff:	00 
80102700:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80102707:	e8 9b fe ff ff       	call   801025a7 <outb>
  outb(0x1f2, 1);  // number of sectors
8010270c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102713:	00 
80102714:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
8010271b:	e8 87 fe ff ff       	call   801025a7 <outb>
  outb(0x1f3, b->sector & 0xff);
80102720:	8b 45 08             	mov    0x8(%ebp),%eax
80102723:	8b 40 08             	mov    0x8(%eax),%eax
80102726:	0f b6 c0             	movzbl %al,%eax
80102729:	89 44 24 04          	mov    %eax,0x4(%esp)
8010272d:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102734:	e8 6e fe ff ff       	call   801025a7 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
80102739:	8b 45 08             	mov    0x8(%ebp),%eax
8010273c:	8b 40 08             	mov    0x8(%eax),%eax
8010273f:	c1 e8 08             	shr    $0x8,%eax
80102742:	0f b6 c0             	movzbl %al,%eax
80102745:	89 44 24 04          	mov    %eax,0x4(%esp)
80102749:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102750:	e8 52 fe ff ff       	call   801025a7 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
80102755:	8b 45 08             	mov    0x8(%ebp),%eax
80102758:	8b 40 08             	mov    0x8(%eax),%eax
8010275b:	c1 e8 10             	shr    $0x10,%eax
8010275e:	0f b6 c0             	movzbl %al,%eax
80102761:	89 44 24 04          	mov    %eax,0x4(%esp)
80102765:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
8010276c:	e8 36 fe ff ff       	call   801025a7 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
80102771:	8b 45 08             	mov    0x8(%ebp),%eax
80102774:	8b 40 04             	mov    0x4(%eax),%eax
80102777:	83 e0 01             	and    $0x1,%eax
8010277a:	89 c2                	mov    %eax,%edx
8010277c:	c1 e2 04             	shl    $0x4,%edx
8010277f:	8b 45 08             	mov    0x8(%ebp),%eax
80102782:	8b 40 08             	mov    0x8(%eax),%eax
80102785:	c1 e8 18             	shr    $0x18,%eax
80102788:	83 e0 0f             	and    $0xf,%eax
8010278b:	09 d0                	or     %edx,%eax
8010278d:	83 c8 e0             	or     $0xffffffe0,%eax
80102790:	0f b6 c0             	movzbl %al,%eax
80102793:	89 44 24 04          	mov    %eax,0x4(%esp)
80102797:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010279e:	e8 04 fe ff ff       	call   801025a7 <outb>
  if(b->flags & B_DIRTY){
801027a3:	8b 45 08             	mov    0x8(%ebp),%eax
801027a6:	8b 00                	mov    (%eax),%eax
801027a8:	83 e0 04             	and    $0x4,%eax
801027ab:	85 c0                	test   %eax,%eax
801027ad:	74 34                	je     801027e3 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
801027af:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
801027b6:	00 
801027b7:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801027be:	e8 e4 fd ff ff       	call   801025a7 <outb>
    outsl(0x1f0, b->data, 512/4);
801027c3:	8b 45 08             	mov    0x8(%ebp),%eax
801027c6:	83 c0 18             	add    $0x18,%eax
801027c9:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801027d0:	00 
801027d1:	89 44 24 04          	mov    %eax,0x4(%esp)
801027d5:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801027dc:	e8 e4 fd ff ff       	call   801025c5 <outsl>
801027e1:	eb 14                	jmp    801027f7 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
801027e3:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801027ea:	00 
801027eb:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801027f2:	e8 b0 fd ff ff       	call   801025a7 <outb>
  }
}
801027f7:	c9                   	leave  
801027f8:	c3                   	ret    

801027f9 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
801027f9:	55                   	push   %ebp
801027fa:	89 e5                	mov    %esp,%ebp
801027fc:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
801027ff:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102806:	e8 a0 24 00 00       	call   80104cab <acquire>
  if((b = idequeue) == 0){
8010280b:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102810:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102813:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102817:	75 11                	jne    8010282a <ideintr+0x31>
    release(&idelock);
80102819:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102820:	e8 e8 24 00 00       	call   80104d0d <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102825:	e9 90 00 00 00       	jmp    801028ba <ideintr+0xc1>
  }
  idequeue = b->qnext;
8010282a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010282d:	8b 40 14             	mov    0x14(%eax),%eax
80102830:	a3 34 b6 10 80       	mov    %eax,0x8010b634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102835:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102838:	8b 00                	mov    (%eax),%eax
8010283a:	83 e0 04             	and    $0x4,%eax
8010283d:	85 c0                	test   %eax,%eax
8010283f:	75 2e                	jne    8010286f <ideintr+0x76>
80102841:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102848:	e8 9d fd ff ff       	call   801025ea <idewait>
8010284d:	85 c0                	test   %eax,%eax
8010284f:	78 1e                	js     8010286f <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
80102851:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102854:	83 c0 18             	add    $0x18,%eax
80102857:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010285e:	00 
8010285f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102863:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
8010286a:	e8 13 fd ff ff       	call   80102582 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
8010286f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102872:	8b 00                	mov    (%eax),%eax
80102874:	89 c2                	mov    %eax,%edx
80102876:	83 ca 02             	or     $0x2,%edx
80102879:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010287c:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
8010287e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102881:	8b 00                	mov    (%eax),%eax
80102883:	89 c2                	mov    %eax,%edx
80102885:	83 e2 fb             	and    $0xfffffffb,%edx
80102888:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010288b:	89 10                	mov    %edx,(%eax)
  wakeup(b);
8010288d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102890:	89 04 24             	mov    %eax,(%esp)
80102893:	e8 0e 22 00 00       	call   80104aa6 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102898:	a1 34 b6 10 80       	mov    0x8010b634,%eax
8010289d:	85 c0                	test   %eax,%eax
8010289f:	74 0d                	je     801028ae <ideintr+0xb5>
    idestart(idequeue);
801028a1:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801028a6:	89 04 24             	mov    %eax,(%esp)
801028a9:	e8 26 fe ff ff       	call   801026d4 <idestart>

  release(&idelock);
801028ae:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801028b5:	e8 53 24 00 00       	call   80104d0d <release>
}
801028ba:	c9                   	leave  
801028bb:	c3                   	ret    

801028bc <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
801028bc:	55                   	push   %ebp
801028bd:	89 e5                	mov    %esp,%ebp
801028bf:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
801028c2:	8b 45 08             	mov    0x8(%ebp),%eax
801028c5:	8b 00                	mov    (%eax),%eax
801028c7:	83 e0 01             	and    $0x1,%eax
801028ca:	85 c0                	test   %eax,%eax
801028cc:	75 0c                	jne    801028da <iderw+0x1e>
    panic("iderw: buf not busy");
801028ce:	c7 04 24 02 84 10 80 	movl   $0x80108402,(%esp)
801028d5:	e8 63 dc ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801028da:	8b 45 08             	mov    0x8(%ebp),%eax
801028dd:	8b 00                	mov    (%eax),%eax
801028df:	83 e0 06             	and    $0x6,%eax
801028e2:	83 f8 02             	cmp    $0x2,%eax
801028e5:	75 0c                	jne    801028f3 <iderw+0x37>
    panic("iderw: nothing to do");
801028e7:	c7 04 24 16 84 10 80 	movl   $0x80108416,(%esp)
801028ee:	e8 4a dc ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
801028f3:	8b 45 08             	mov    0x8(%ebp),%eax
801028f6:	8b 40 04             	mov    0x4(%eax),%eax
801028f9:	85 c0                	test   %eax,%eax
801028fb:	74 15                	je     80102912 <iderw+0x56>
801028fd:	a1 38 b6 10 80       	mov    0x8010b638,%eax
80102902:	85 c0                	test   %eax,%eax
80102904:	75 0c                	jne    80102912 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102906:	c7 04 24 2b 84 10 80 	movl   $0x8010842b,(%esp)
8010290d:	e8 2b dc ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
80102912:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102919:	e8 8d 23 00 00       	call   80104cab <acquire>

  // Append b to idequeue.
  b->qnext = 0;
8010291e:	8b 45 08             	mov    0x8(%ebp),%eax
80102921:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
80102928:	c7 45 f4 34 b6 10 80 	movl   $0x8010b634,-0xc(%ebp)
8010292f:	eb 0b                	jmp    8010293c <iderw+0x80>
80102931:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102934:	8b 00                	mov    (%eax),%eax
80102936:	83 c0 14             	add    $0x14,%eax
80102939:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010293c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010293f:	8b 00                	mov    (%eax),%eax
80102941:	85 c0                	test   %eax,%eax
80102943:	75 ec                	jne    80102931 <iderw+0x75>
    ;
  *pp = b;
80102945:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102948:	8b 55 08             	mov    0x8(%ebp),%edx
8010294b:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
8010294d:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102952:	3b 45 08             	cmp    0x8(%ebp),%eax
80102955:	75 22                	jne    80102979 <iderw+0xbd>
    idestart(b);
80102957:	8b 45 08             	mov    0x8(%ebp),%eax
8010295a:	89 04 24             	mov    %eax,(%esp)
8010295d:	e8 72 fd ff ff       	call   801026d4 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102962:	eb 15                	jmp    80102979 <iderw+0xbd>
    sleep(b, &idelock);
80102964:	c7 44 24 04 00 b6 10 	movl   $0x8010b600,0x4(%esp)
8010296b:	80 
8010296c:	8b 45 08             	mov    0x8(%ebp),%eax
8010296f:	89 04 24             	mov    %eax,(%esp)
80102972:	e8 56 20 00 00       	call   801049cd <sleep>
80102977:	eb 01                	jmp    8010297a <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102979:	90                   	nop
8010297a:	8b 45 08             	mov    0x8(%ebp),%eax
8010297d:	8b 00                	mov    (%eax),%eax
8010297f:	83 e0 06             	and    $0x6,%eax
80102982:	83 f8 02             	cmp    $0x2,%eax
80102985:	75 dd                	jne    80102964 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
80102987:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
8010298e:	e8 7a 23 00 00       	call   80104d0d <release>
}
80102993:	c9                   	leave  
80102994:	c3                   	ret    
80102995:	00 00                	add    %al,(%eax)
	...

80102998 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102998:	55                   	push   %ebp
80102999:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
8010299b:	a1 54 fd 10 80       	mov    0x8010fd54,%eax
801029a0:	8b 55 08             	mov    0x8(%ebp),%edx
801029a3:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
801029a5:	a1 54 fd 10 80       	mov    0x8010fd54,%eax
801029aa:	8b 40 10             	mov    0x10(%eax),%eax
}
801029ad:	5d                   	pop    %ebp
801029ae:	c3                   	ret    

801029af <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
801029af:	55                   	push   %ebp
801029b0:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801029b2:	a1 54 fd 10 80       	mov    0x8010fd54,%eax
801029b7:	8b 55 08             	mov    0x8(%ebp),%edx
801029ba:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
801029bc:	a1 54 fd 10 80       	mov    0x8010fd54,%eax
801029c1:	8b 55 0c             	mov    0xc(%ebp),%edx
801029c4:	89 50 10             	mov    %edx,0x10(%eax)
}
801029c7:	5d                   	pop    %ebp
801029c8:	c3                   	ret    

801029c9 <ioapicinit>:

void
ioapicinit(void)
{
801029c9:	55                   	push   %ebp
801029ca:	89 e5                	mov    %esp,%ebp
801029cc:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
801029cf:	a1 24 fe 10 80       	mov    0x8010fe24,%eax
801029d4:	85 c0                	test   %eax,%eax
801029d6:	0f 84 9f 00 00 00    	je     80102a7b <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
801029dc:	c7 05 54 fd 10 80 00 	movl   $0xfec00000,0x8010fd54
801029e3:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
801029e6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801029ed:	e8 a6 ff ff ff       	call   80102998 <ioapicread>
801029f2:	c1 e8 10             	shr    $0x10,%eax
801029f5:	25 ff 00 00 00       	and    $0xff,%eax
801029fa:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
801029fd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102a04:	e8 8f ff ff ff       	call   80102998 <ioapicread>
80102a09:	c1 e8 18             	shr    $0x18,%eax
80102a0c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102a0f:	0f b6 05 20 fe 10 80 	movzbl 0x8010fe20,%eax
80102a16:	0f b6 c0             	movzbl %al,%eax
80102a19:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102a1c:	74 0c                	je     80102a2a <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102a1e:	c7 04 24 4c 84 10 80 	movl   $0x8010844c,(%esp)
80102a25:	e8 77 d9 ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102a2a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102a31:	eb 3e                	jmp    80102a71 <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102a33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a36:	83 c0 20             	add    $0x20,%eax
80102a39:	0d 00 00 01 00       	or     $0x10000,%eax
80102a3e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a41:	83 c2 08             	add    $0x8,%edx
80102a44:	01 d2                	add    %edx,%edx
80102a46:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a4a:	89 14 24             	mov    %edx,(%esp)
80102a4d:	e8 5d ff ff ff       	call   801029af <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102a52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a55:	83 c0 08             	add    $0x8,%eax
80102a58:	01 c0                	add    %eax,%eax
80102a5a:	83 c0 01             	add    $0x1,%eax
80102a5d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102a64:	00 
80102a65:	89 04 24             	mov    %eax,(%esp)
80102a68:	e8 42 ff ff ff       	call   801029af <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102a6d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102a71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a74:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102a77:	7e ba                	jle    80102a33 <ioapicinit+0x6a>
80102a79:	eb 01                	jmp    80102a7c <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
80102a7b:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102a7c:	c9                   	leave  
80102a7d:	c3                   	ret    

80102a7e <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102a7e:	55                   	push   %ebp
80102a7f:	89 e5                	mov    %esp,%ebp
80102a81:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102a84:	a1 24 fe 10 80       	mov    0x8010fe24,%eax
80102a89:	85 c0                	test   %eax,%eax
80102a8b:	74 39                	je     80102ac6 <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102a8d:	8b 45 08             	mov    0x8(%ebp),%eax
80102a90:	83 c0 20             	add    $0x20,%eax
80102a93:	8b 55 08             	mov    0x8(%ebp),%edx
80102a96:	83 c2 08             	add    $0x8,%edx
80102a99:	01 d2                	add    %edx,%edx
80102a9b:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a9f:	89 14 24             	mov    %edx,(%esp)
80102aa2:	e8 08 ff ff ff       	call   801029af <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102aa7:	8b 45 0c             	mov    0xc(%ebp),%eax
80102aaa:	c1 e0 18             	shl    $0x18,%eax
80102aad:	8b 55 08             	mov    0x8(%ebp),%edx
80102ab0:	83 c2 08             	add    $0x8,%edx
80102ab3:	01 d2                	add    %edx,%edx
80102ab5:	83 c2 01             	add    $0x1,%edx
80102ab8:	89 44 24 04          	mov    %eax,0x4(%esp)
80102abc:	89 14 24             	mov    %edx,(%esp)
80102abf:	e8 eb fe ff ff       	call   801029af <ioapicwrite>
80102ac4:	eb 01                	jmp    80102ac7 <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
80102ac6:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
80102ac7:	c9                   	leave  
80102ac8:	c3                   	ret    
80102ac9:	00 00                	add    %al,(%eax)
	...

80102acc <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102acc:	55                   	push   %ebp
80102acd:	89 e5                	mov    %esp,%ebp
80102acf:	8b 45 08             	mov    0x8(%ebp),%eax
80102ad2:	05 00 00 00 80       	add    $0x80000000,%eax
80102ad7:	5d                   	pop    %ebp
80102ad8:	c3                   	ret    

80102ad9 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102ad9:	55                   	push   %ebp
80102ada:	89 e5                	mov    %esp,%ebp
80102adc:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102adf:	c7 44 24 04 7e 84 10 	movl   $0x8010847e,0x4(%esp)
80102ae6:	80 
80102ae7:	c7 04 24 60 fd 10 80 	movl   $0x8010fd60,(%esp)
80102aee:	e8 97 21 00 00       	call   80104c8a <initlock>
  kmem.use_lock = 0;
80102af3:	c7 05 94 fd 10 80 00 	movl   $0x0,0x8010fd94
80102afa:	00 00 00 
  freerange(vstart, vend);
80102afd:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b00:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b04:	8b 45 08             	mov    0x8(%ebp),%eax
80102b07:	89 04 24             	mov    %eax,(%esp)
80102b0a:	e8 26 00 00 00       	call   80102b35 <freerange>
}
80102b0f:	c9                   	leave  
80102b10:	c3                   	ret    

80102b11 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102b11:	55                   	push   %ebp
80102b12:	89 e5                	mov    %esp,%ebp
80102b14:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102b17:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b1a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b1e:	8b 45 08             	mov    0x8(%ebp),%eax
80102b21:	89 04 24             	mov    %eax,(%esp)
80102b24:	e8 0c 00 00 00       	call   80102b35 <freerange>
  kmem.use_lock = 1;
80102b29:	c7 05 94 fd 10 80 01 	movl   $0x1,0x8010fd94
80102b30:	00 00 00 
}
80102b33:	c9                   	leave  
80102b34:	c3                   	ret    

80102b35 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102b35:	55                   	push   %ebp
80102b36:	89 e5                	mov    %esp,%ebp
80102b38:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102b3b:	8b 45 08             	mov    0x8(%ebp),%eax
80102b3e:	05 ff 0f 00 00       	add    $0xfff,%eax
80102b43:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102b48:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102b4b:	eb 12                	jmp    80102b5f <freerange+0x2a>
    kfree(p);
80102b4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b50:	89 04 24             	mov    %eax,(%esp)
80102b53:	e8 16 00 00 00       	call   80102b6e <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102b58:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102b5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b62:	05 00 10 00 00       	add    $0x1000,%eax
80102b67:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102b6a:	76 e1                	jbe    80102b4d <freerange+0x18>
    kfree(p);
}
80102b6c:	c9                   	leave  
80102b6d:	c3                   	ret    

80102b6e <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102b6e:	55                   	push   %ebp
80102b6f:	89 e5                	mov    %esp,%ebp
80102b71:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102b74:	8b 45 08             	mov    0x8(%ebp),%eax
80102b77:	25 ff 0f 00 00       	and    $0xfff,%eax
80102b7c:	85 c0                	test   %eax,%eax
80102b7e:	75 1b                	jne    80102b9b <kfree+0x2d>
80102b80:	81 7d 08 1c 2c 11 80 	cmpl   $0x80112c1c,0x8(%ebp)
80102b87:	72 12                	jb     80102b9b <kfree+0x2d>
80102b89:	8b 45 08             	mov    0x8(%ebp),%eax
80102b8c:	89 04 24             	mov    %eax,(%esp)
80102b8f:	e8 38 ff ff ff       	call   80102acc <v2p>
80102b94:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102b99:	76 0c                	jbe    80102ba7 <kfree+0x39>
    panic("kfree");
80102b9b:	c7 04 24 83 84 10 80 	movl   $0x80108483,(%esp)
80102ba2:	e8 96 d9 ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102ba7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102bae:	00 
80102baf:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102bb6:	00 
80102bb7:	8b 45 08             	mov    0x8(%ebp),%eax
80102bba:	89 04 24             	mov    %eax,(%esp)
80102bbd:	e8 38 23 00 00       	call   80104efa <memset>

  if(kmem.use_lock)
80102bc2:	a1 94 fd 10 80       	mov    0x8010fd94,%eax
80102bc7:	85 c0                	test   %eax,%eax
80102bc9:	74 0c                	je     80102bd7 <kfree+0x69>
    acquire(&kmem.lock);
80102bcb:	c7 04 24 60 fd 10 80 	movl   $0x8010fd60,(%esp)
80102bd2:	e8 d4 20 00 00       	call   80104cab <acquire>
  r = (struct run*)v;
80102bd7:	8b 45 08             	mov    0x8(%ebp),%eax
80102bda:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102bdd:	8b 15 98 fd 10 80    	mov    0x8010fd98,%edx
80102be3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102be6:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102be8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102beb:	a3 98 fd 10 80       	mov    %eax,0x8010fd98
  if(kmem.use_lock)
80102bf0:	a1 94 fd 10 80       	mov    0x8010fd94,%eax
80102bf5:	85 c0                	test   %eax,%eax
80102bf7:	74 0c                	je     80102c05 <kfree+0x97>
    release(&kmem.lock);
80102bf9:	c7 04 24 60 fd 10 80 	movl   $0x8010fd60,(%esp)
80102c00:	e8 08 21 00 00       	call   80104d0d <release>
}
80102c05:	c9                   	leave  
80102c06:	c3                   	ret    

80102c07 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102c07:	55                   	push   %ebp
80102c08:	89 e5                	mov    %esp,%ebp
80102c0a:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102c0d:	a1 94 fd 10 80       	mov    0x8010fd94,%eax
80102c12:	85 c0                	test   %eax,%eax
80102c14:	74 0c                	je     80102c22 <kalloc+0x1b>
    acquire(&kmem.lock);
80102c16:	c7 04 24 60 fd 10 80 	movl   $0x8010fd60,(%esp)
80102c1d:	e8 89 20 00 00       	call   80104cab <acquire>
  r = kmem.freelist;
80102c22:	a1 98 fd 10 80       	mov    0x8010fd98,%eax
80102c27:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102c2a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102c2e:	74 0a                	je     80102c3a <kalloc+0x33>
    kmem.freelist = r->next;
80102c30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c33:	8b 00                	mov    (%eax),%eax
80102c35:	a3 98 fd 10 80       	mov    %eax,0x8010fd98
  if(kmem.use_lock)
80102c3a:	a1 94 fd 10 80       	mov    0x8010fd94,%eax
80102c3f:	85 c0                	test   %eax,%eax
80102c41:	74 0c                	je     80102c4f <kalloc+0x48>
    release(&kmem.lock);
80102c43:	c7 04 24 60 fd 10 80 	movl   $0x8010fd60,(%esp)
80102c4a:	e8 be 20 00 00       	call   80104d0d <release>
  return (char*)r;
80102c4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102c52:	c9                   	leave  
80102c53:	c3                   	ret    

80102c54 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102c54:	55                   	push   %ebp
80102c55:	89 e5                	mov    %esp,%ebp
80102c57:	53                   	push   %ebx
80102c58:	83 ec 14             	sub    $0x14,%esp
80102c5b:	8b 45 08             	mov    0x8(%ebp),%eax
80102c5e:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102c62:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102c66:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102c6a:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102c6e:	ec                   	in     (%dx),%al
80102c6f:	89 c3                	mov    %eax,%ebx
80102c71:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102c74:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102c78:	83 c4 14             	add    $0x14,%esp
80102c7b:	5b                   	pop    %ebx
80102c7c:	5d                   	pop    %ebp
80102c7d:	c3                   	ret    

80102c7e <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102c7e:	55                   	push   %ebp
80102c7f:	89 e5                	mov    %esp,%ebp
80102c81:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102c84:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102c8b:	e8 c4 ff ff ff       	call   80102c54 <inb>
80102c90:	0f b6 c0             	movzbl %al,%eax
80102c93:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102c96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c99:	83 e0 01             	and    $0x1,%eax
80102c9c:	85 c0                	test   %eax,%eax
80102c9e:	75 0a                	jne    80102caa <kbdgetc+0x2c>
    return -1;
80102ca0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102ca5:	e9 23 01 00 00       	jmp    80102dcd <kbdgetc+0x14f>
  data = inb(KBDATAP);
80102caa:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102cb1:	e8 9e ff ff ff       	call   80102c54 <inb>
80102cb6:	0f b6 c0             	movzbl %al,%eax
80102cb9:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102cbc:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102cc3:	75 17                	jne    80102cdc <kbdgetc+0x5e>
    shift |= E0ESC;
80102cc5:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cca:	83 c8 40             	or     $0x40,%eax
80102ccd:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102cd2:	b8 00 00 00 00       	mov    $0x0,%eax
80102cd7:	e9 f1 00 00 00       	jmp    80102dcd <kbdgetc+0x14f>
  } else if(data & 0x80){
80102cdc:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102cdf:	25 80 00 00 00       	and    $0x80,%eax
80102ce4:	85 c0                	test   %eax,%eax
80102ce6:	74 45                	je     80102d2d <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102ce8:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102ced:	83 e0 40             	and    $0x40,%eax
80102cf0:	85 c0                	test   %eax,%eax
80102cf2:	75 08                	jne    80102cfc <kbdgetc+0x7e>
80102cf4:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102cf7:	83 e0 7f             	and    $0x7f,%eax
80102cfa:	eb 03                	jmp    80102cff <kbdgetc+0x81>
80102cfc:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102cff:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102d02:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d05:	05 20 90 10 80       	add    $0x80109020,%eax
80102d0a:	0f b6 00             	movzbl (%eax),%eax
80102d0d:	83 c8 40             	or     $0x40,%eax
80102d10:	0f b6 c0             	movzbl %al,%eax
80102d13:	f7 d0                	not    %eax
80102d15:	89 c2                	mov    %eax,%edx
80102d17:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d1c:	21 d0                	and    %edx,%eax
80102d1e:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102d23:	b8 00 00 00 00       	mov    $0x0,%eax
80102d28:	e9 a0 00 00 00       	jmp    80102dcd <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80102d2d:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d32:	83 e0 40             	and    $0x40,%eax
80102d35:	85 c0                	test   %eax,%eax
80102d37:	74 14                	je     80102d4d <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102d39:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102d40:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d45:	83 e0 bf             	and    $0xffffffbf,%eax
80102d48:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  }

  shift |= shiftcode[data];
80102d4d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d50:	05 20 90 10 80       	add    $0x80109020,%eax
80102d55:	0f b6 00             	movzbl (%eax),%eax
80102d58:	0f b6 d0             	movzbl %al,%edx
80102d5b:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d60:	09 d0                	or     %edx,%eax
80102d62:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  shift ^= togglecode[data];
80102d67:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d6a:	05 20 91 10 80       	add    $0x80109120,%eax
80102d6f:	0f b6 00             	movzbl (%eax),%eax
80102d72:	0f b6 d0             	movzbl %al,%edx
80102d75:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d7a:	31 d0                	xor    %edx,%eax
80102d7c:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102d81:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d86:	83 e0 03             	and    $0x3,%eax
80102d89:	8b 04 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%eax
80102d90:	03 45 fc             	add    -0x4(%ebp),%eax
80102d93:	0f b6 00             	movzbl (%eax),%eax
80102d96:	0f b6 c0             	movzbl %al,%eax
80102d99:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102d9c:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102da1:	83 e0 08             	and    $0x8,%eax
80102da4:	85 c0                	test   %eax,%eax
80102da6:	74 22                	je     80102dca <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80102da8:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102dac:	76 0c                	jbe    80102dba <kbdgetc+0x13c>
80102dae:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102db2:	77 06                	ja     80102dba <kbdgetc+0x13c>
      c += 'A' - 'a';
80102db4:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102db8:	eb 10                	jmp    80102dca <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80102dba:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102dbe:	76 0a                	jbe    80102dca <kbdgetc+0x14c>
80102dc0:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102dc4:	77 04                	ja     80102dca <kbdgetc+0x14c>
      c += 'a' - 'A';
80102dc6:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102dca:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102dcd:	c9                   	leave  
80102dce:	c3                   	ret    

80102dcf <kbdintr>:

void
kbdintr(void)
{
80102dcf:	55                   	push   %ebp
80102dd0:	89 e5                	mov    %esp,%ebp
80102dd2:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102dd5:	c7 04 24 7e 2c 10 80 	movl   $0x80102c7e,(%esp)
80102ddc:	e8 cc d9 ff ff       	call   801007ad <consoleintr>
}
80102de1:	c9                   	leave  
80102de2:	c3                   	ret    
	...

80102de4 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102de4:	55                   	push   %ebp
80102de5:	89 e5                	mov    %esp,%ebp
80102de7:	83 ec 08             	sub    $0x8,%esp
80102dea:	8b 55 08             	mov    0x8(%ebp),%edx
80102ded:	8b 45 0c             	mov    0xc(%ebp),%eax
80102df0:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102df4:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102df7:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102dfb:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102dff:	ee                   	out    %al,(%dx)
}
80102e00:	c9                   	leave  
80102e01:	c3                   	ret    

80102e02 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102e02:	55                   	push   %ebp
80102e03:	89 e5                	mov    %esp,%ebp
80102e05:	53                   	push   %ebx
80102e06:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102e09:	9c                   	pushf  
80102e0a:	5b                   	pop    %ebx
80102e0b:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80102e0e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102e11:	83 c4 10             	add    $0x10,%esp
80102e14:	5b                   	pop    %ebx
80102e15:	5d                   	pop    %ebp
80102e16:	c3                   	ret    

80102e17 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102e17:	55                   	push   %ebp
80102e18:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102e1a:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102e1f:	8b 55 08             	mov    0x8(%ebp),%edx
80102e22:	c1 e2 02             	shl    $0x2,%edx
80102e25:	01 c2                	add    %eax,%edx
80102e27:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e2a:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102e2c:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102e31:	83 c0 20             	add    $0x20,%eax
80102e34:	8b 00                	mov    (%eax),%eax
}
80102e36:	5d                   	pop    %ebp
80102e37:	c3                   	ret    

80102e38 <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
80102e38:	55                   	push   %ebp
80102e39:	89 e5                	mov    %esp,%ebp
80102e3b:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102e3e:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102e43:	85 c0                	test   %eax,%eax
80102e45:	0f 84 47 01 00 00    	je     80102f92 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102e4b:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102e52:	00 
80102e53:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102e5a:	e8 b8 ff ff ff       	call   80102e17 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102e5f:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102e66:	00 
80102e67:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102e6e:	e8 a4 ff ff ff       	call   80102e17 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102e73:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102e7a:	00 
80102e7b:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102e82:	e8 90 ff ff ff       	call   80102e17 <lapicw>
  lapicw(TICR, 10000000); 
80102e87:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102e8e:	00 
80102e8f:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102e96:	e8 7c ff ff ff       	call   80102e17 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102e9b:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102ea2:	00 
80102ea3:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102eaa:	e8 68 ff ff ff       	call   80102e17 <lapicw>
  lapicw(LINT1, MASKED);
80102eaf:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102eb6:	00 
80102eb7:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102ebe:	e8 54 ff ff ff       	call   80102e17 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102ec3:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102ec8:	83 c0 30             	add    $0x30,%eax
80102ecb:	8b 00                	mov    (%eax),%eax
80102ecd:	c1 e8 10             	shr    $0x10,%eax
80102ed0:	25 ff 00 00 00       	and    $0xff,%eax
80102ed5:	83 f8 03             	cmp    $0x3,%eax
80102ed8:	76 14                	jbe    80102eee <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80102eda:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102ee1:	00 
80102ee2:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102ee9:	e8 29 ff ff ff       	call   80102e17 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102eee:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102ef5:	00 
80102ef6:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102efd:	e8 15 ff ff ff       	call   80102e17 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102f02:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f09:	00 
80102f0a:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102f11:	e8 01 ff ff ff       	call   80102e17 <lapicw>
  lapicw(ESR, 0);
80102f16:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f1d:	00 
80102f1e:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102f25:	e8 ed fe ff ff       	call   80102e17 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102f2a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f31:	00 
80102f32:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102f39:	e8 d9 fe ff ff       	call   80102e17 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102f3e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f45:	00 
80102f46:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102f4d:	e8 c5 fe ff ff       	call   80102e17 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102f52:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80102f59:	00 
80102f5a:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102f61:	e8 b1 fe ff ff       	call   80102e17 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102f66:	90                   	nop
80102f67:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102f6c:	05 00 03 00 00       	add    $0x300,%eax
80102f71:	8b 00                	mov    (%eax),%eax
80102f73:	25 00 10 00 00       	and    $0x1000,%eax
80102f78:	85 c0                	test   %eax,%eax
80102f7a:	75 eb                	jne    80102f67 <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102f7c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f83:	00 
80102f84:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80102f8b:	e8 87 fe ff ff       	call   80102e17 <lapicw>
80102f90:	eb 01                	jmp    80102f93 <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
80102f92:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80102f93:	c9                   	leave  
80102f94:	c3                   	ret    

80102f95 <cpunum>:

int
cpunum(void)
{
80102f95:	55                   	push   %ebp
80102f96:	89 e5                	mov    %esp,%ebp
80102f98:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80102f9b:	e8 62 fe ff ff       	call   80102e02 <readeflags>
80102fa0:	25 00 02 00 00       	and    $0x200,%eax
80102fa5:	85 c0                	test   %eax,%eax
80102fa7:	74 29                	je     80102fd2 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80102fa9:	a1 40 b6 10 80       	mov    0x8010b640,%eax
80102fae:	85 c0                	test   %eax,%eax
80102fb0:	0f 94 c2             	sete   %dl
80102fb3:	83 c0 01             	add    $0x1,%eax
80102fb6:	a3 40 b6 10 80       	mov    %eax,0x8010b640
80102fbb:	84 d2                	test   %dl,%dl
80102fbd:	74 13                	je     80102fd2 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80102fbf:	8b 45 04             	mov    0x4(%ebp),%eax
80102fc2:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fc6:	c7 04 24 8c 84 10 80 	movl   $0x8010848c,(%esp)
80102fcd:	e8 cf d3 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80102fd2:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102fd7:	85 c0                	test   %eax,%eax
80102fd9:	74 0f                	je     80102fea <cpunum+0x55>
    return lapic[ID]>>24;
80102fdb:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102fe0:	83 c0 20             	add    $0x20,%eax
80102fe3:	8b 00                	mov    (%eax),%eax
80102fe5:	c1 e8 18             	shr    $0x18,%eax
80102fe8:	eb 05                	jmp    80102fef <cpunum+0x5a>
  return 0;
80102fea:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102fef:	c9                   	leave  
80102ff0:	c3                   	ret    

80102ff1 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80102ff1:	55                   	push   %ebp
80102ff2:	89 e5                	mov    %esp,%ebp
80102ff4:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80102ff7:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102ffc:	85 c0                	test   %eax,%eax
80102ffe:	74 14                	je     80103014 <lapiceoi+0x23>
    lapicw(EOI, 0);
80103000:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103007:	00 
80103008:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
8010300f:	e8 03 fe ff ff       	call   80102e17 <lapicw>
}
80103014:	c9                   	leave  
80103015:	c3                   	ret    

80103016 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103016:	55                   	push   %ebp
80103017:	89 e5                	mov    %esp,%ebp
}
80103019:	5d                   	pop    %ebp
8010301a:	c3                   	ret    

8010301b <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010301b:	55                   	push   %ebp
8010301c:	89 e5                	mov    %esp,%ebp
8010301e:	83 ec 1c             	sub    $0x1c,%esp
80103021:	8b 45 08             	mov    0x8(%ebp),%eax
80103024:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
80103027:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010302e:	00 
8010302f:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103036:	e8 a9 fd ff ff       	call   80102de4 <outb>
  outb(IO_RTC+1, 0x0A);
8010303b:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103042:	00 
80103043:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
8010304a:	e8 95 fd ff ff       	call   80102de4 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
8010304f:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80103056:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103059:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
8010305e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103061:	8d 50 02             	lea    0x2(%eax),%edx
80103064:	8b 45 0c             	mov    0xc(%ebp),%eax
80103067:	c1 e8 04             	shr    $0x4,%eax
8010306a:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
8010306d:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103071:	c1 e0 18             	shl    $0x18,%eax
80103074:	89 44 24 04          	mov    %eax,0x4(%esp)
80103078:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010307f:	e8 93 fd ff ff       	call   80102e17 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103084:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
8010308b:	00 
8010308c:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103093:	e8 7f fd ff ff       	call   80102e17 <lapicw>
  microdelay(200);
80103098:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010309f:	e8 72 ff ff ff       	call   80103016 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
801030a4:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
801030ab:	00 
801030ac:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801030b3:	e8 5f fd ff ff       	call   80102e17 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801030b8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801030bf:	e8 52 ff ff ff       	call   80103016 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801030c4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801030cb:	eb 40                	jmp    8010310d <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
801030cd:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801030d1:	c1 e0 18             	shl    $0x18,%eax
801030d4:	89 44 24 04          	mov    %eax,0x4(%esp)
801030d8:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801030df:	e8 33 fd ff ff       	call   80102e17 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
801030e4:	8b 45 0c             	mov    0xc(%ebp),%eax
801030e7:	c1 e8 0c             	shr    $0xc,%eax
801030ea:	80 cc 06             	or     $0x6,%ah
801030ed:	89 44 24 04          	mov    %eax,0x4(%esp)
801030f1:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801030f8:	e8 1a fd ff ff       	call   80102e17 <lapicw>
    microdelay(200);
801030fd:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103104:	e8 0d ff ff ff       	call   80103016 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103109:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010310d:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103111:	7e ba                	jle    801030cd <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103113:	c9                   	leave  
80103114:	c3                   	ret    
80103115:	00 00                	add    %al,(%eax)
	...

80103118 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
80103118:	55                   	push   %ebp
80103119:	89 e5                	mov    %esp,%ebp
8010311b:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
8010311e:	c7 44 24 04 b8 84 10 	movl   $0x801084b8,0x4(%esp)
80103125:	80 
80103126:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
8010312d:	e8 58 1b 00 00       	call   80104c8a <initlock>
  readsb(ROOTDEV, &sb);
80103132:	8d 45 e8             	lea    -0x18(%ebp),%eax
80103135:	89 44 24 04          	mov    %eax,0x4(%esp)
80103139:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103140:	e8 af e2 ff ff       	call   801013f4 <readsb>
  log.start = sb.size - sb.nlog;
80103145:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103148:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010314b:	89 d1                	mov    %edx,%ecx
8010314d:	29 c1                	sub    %eax,%ecx
8010314f:	89 c8                	mov    %ecx,%eax
80103151:	a3 d4 fd 10 80       	mov    %eax,0x8010fdd4
  log.size = sb.nlog;
80103156:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103159:	a3 d8 fd 10 80       	mov    %eax,0x8010fdd8
  log.dev = ROOTDEV;
8010315e:	c7 05 e0 fd 10 80 01 	movl   $0x1,0x8010fde0
80103165:	00 00 00 
  recover_from_log();
80103168:	e8 97 01 00 00       	call   80103304 <recover_from_log>
}
8010316d:	c9                   	leave  
8010316e:	c3                   	ret    

8010316f <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
8010316f:	55                   	push   %ebp
80103170:	89 e5                	mov    %esp,%ebp
80103172:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103175:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010317c:	e9 89 00 00 00       	jmp    8010320a <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103181:	a1 d4 fd 10 80       	mov    0x8010fdd4,%eax
80103186:	03 45 f4             	add    -0xc(%ebp),%eax
80103189:	83 c0 01             	add    $0x1,%eax
8010318c:	89 c2                	mov    %eax,%edx
8010318e:	a1 e0 fd 10 80       	mov    0x8010fde0,%eax
80103193:	89 54 24 04          	mov    %edx,0x4(%esp)
80103197:	89 04 24             	mov    %eax,(%esp)
8010319a:	e8 07 d0 ff ff       	call   801001a6 <bread>
8010319f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
801031a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031a5:	83 c0 10             	add    $0x10,%eax
801031a8:	8b 04 85 a8 fd 10 80 	mov    -0x7fef0258(,%eax,4),%eax
801031af:	89 c2                	mov    %eax,%edx
801031b1:	a1 e0 fd 10 80       	mov    0x8010fde0,%eax
801031b6:	89 54 24 04          	mov    %edx,0x4(%esp)
801031ba:	89 04 24             	mov    %eax,(%esp)
801031bd:	e8 e4 cf ff ff       	call   801001a6 <bread>
801031c2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801031c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031c8:	8d 50 18             	lea    0x18(%eax),%edx
801031cb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801031ce:	83 c0 18             	add    $0x18,%eax
801031d1:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801031d8:	00 
801031d9:	89 54 24 04          	mov    %edx,0x4(%esp)
801031dd:	89 04 24             	mov    %eax,(%esp)
801031e0:	e8 e8 1d 00 00       	call   80104fcd <memmove>
    bwrite(dbuf);  // write dst to disk
801031e5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801031e8:	89 04 24             	mov    %eax,(%esp)
801031eb:	e8 ed cf ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
801031f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031f3:	89 04 24             	mov    %eax,(%esp)
801031f6:	e8 1c d0 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
801031fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801031fe:	89 04 24             	mov    %eax,(%esp)
80103201:	e8 11 d0 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103206:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010320a:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
8010320f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103212:	0f 8f 69 ff ff ff    	jg     80103181 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103218:	c9                   	leave  
80103219:	c3                   	ret    

8010321a <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010321a:	55                   	push   %ebp
8010321b:	89 e5                	mov    %esp,%ebp
8010321d:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103220:	a1 d4 fd 10 80       	mov    0x8010fdd4,%eax
80103225:	89 c2                	mov    %eax,%edx
80103227:	a1 e0 fd 10 80       	mov    0x8010fde0,%eax
8010322c:	89 54 24 04          	mov    %edx,0x4(%esp)
80103230:	89 04 24             	mov    %eax,(%esp)
80103233:	e8 6e cf ff ff       	call   801001a6 <bread>
80103238:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
8010323b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010323e:	83 c0 18             	add    $0x18,%eax
80103241:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103244:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103247:	8b 00                	mov    (%eax),%eax
80103249:	a3 e4 fd 10 80       	mov    %eax,0x8010fde4
  for (i = 0; i < log.lh.n; i++) {
8010324e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103255:	eb 1b                	jmp    80103272 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
80103257:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010325a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010325d:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103261:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103264:	83 c2 10             	add    $0x10,%edx
80103267:	89 04 95 a8 fd 10 80 	mov    %eax,-0x7fef0258(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
8010326e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103272:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
80103277:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010327a:	7f db                	jg     80103257 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
8010327c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010327f:	89 04 24             	mov    %eax,(%esp)
80103282:	e8 90 cf ff ff       	call   80100217 <brelse>
}
80103287:	c9                   	leave  
80103288:	c3                   	ret    

80103289 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103289:	55                   	push   %ebp
8010328a:	89 e5                	mov    %esp,%ebp
8010328c:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010328f:	a1 d4 fd 10 80       	mov    0x8010fdd4,%eax
80103294:	89 c2                	mov    %eax,%edx
80103296:	a1 e0 fd 10 80       	mov    0x8010fde0,%eax
8010329b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010329f:	89 04 24             	mov    %eax,(%esp)
801032a2:	e8 ff ce ff ff       	call   801001a6 <bread>
801032a7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801032aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032ad:	83 c0 18             	add    $0x18,%eax
801032b0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801032b3:	8b 15 e4 fd 10 80    	mov    0x8010fde4,%edx
801032b9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032bc:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801032be:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801032c5:	eb 1b                	jmp    801032e2 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
801032c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032ca:	83 c0 10             	add    $0x10,%eax
801032cd:	8b 0c 85 a8 fd 10 80 	mov    -0x7fef0258(,%eax,4),%ecx
801032d4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032d7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801032da:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
801032de:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801032e2:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
801032e7:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801032ea:	7f db                	jg     801032c7 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
801032ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032ef:	89 04 24             	mov    %eax,(%esp)
801032f2:	e8 e6 ce ff ff       	call   801001dd <bwrite>
  brelse(buf);
801032f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032fa:	89 04 24             	mov    %eax,(%esp)
801032fd:	e8 15 cf ff ff       	call   80100217 <brelse>
}
80103302:	c9                   	leave  
80103303:	c3                   	ret    

80103304 <recover_from_log>:

static void
recover_from_log(void)
{
80103304:	55                   	push   %ebp
80103305:	89 e5                	mov    %esp,%ebp
80103307:	83 ec 08             	sub    $0x8,%esp
  read_head();      
8010330a:	e8 0b ff ff ff       	call   8010321a <read_head>
  install_trans(); // if committed, copy from log to disk
8010330f:	e8 5b fe ff ff       	call   8010316f <install_trans>
  log.lh.n = 0;
80103314:	c7 05 e4 fd 10 80 00 	movl   $0x0,0x8010fde4
8010331b:	00 00 00 
  write_head(); // clear the log
8010331e:	e8 66 ff ff ff       	call   80103289 <write_head>
}
80103323:	c9                   	leave  
80103324:	c3                   	ret    

80103325 <begin_trans>:

void
begin_trans(void)
{
80103325:	55                   	push   %ebp
80103326:	89 e5                	mov    %esp,%ebp
80103328:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
8010332b:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
80103332:	e8 74 19 00 00       	call   80104cab <acquire>
  while (log.busy) {
80103337:	eb 14                	jmp    8010334d <begin_trans+0x28>
    sleep(&log, &log.lock);
80103339:	c7 44 24 04 a0 fd 10 	movl   $0x8010fda0,0x4(%esp)
80103340:	80 
80103341:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
80103348:	e8 80 16 00 00       	call   801049cd <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
8010334d:	a1 dc fd 10 80       	mov    0x8010fddc,%eax
80103352:	85 c0                	test   %eax,%eax
80103354:	75 e3                	jne    80103339 <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
80103356:	c7 05 dc fd 10 80 01 	movl   $0x1,0x8010fddc
8010335d:	00 00 00 
  release(&log.lock);
80103360:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
80103367:	e8 a1 19 00 00       	call   80104d0d <release>
}
8010336c:	c9                   	leave  
8010336d:	c3                   	ret    

8010336e <commit_trans>:

void
commit_trans(void)
{
8010336e:	55                   	push   %ebp
8010336f:	89 e5                	mov    %esp,%ebp
80103371:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
80103374:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
80103379:	85 c0                	test   %eax,%eax
8010337b:	7e 19                	jle    80103396 <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
8010337d:	e8 07 ff ff ff       	call   80103289 <write_head>
    install_trans(); // Now install writes to home locations
80103382:	e8 e8 fd ff ff       	call   8010316f <install_trans>
    log.lh.n = 0; 
80103387:	c7 05 e4 fd 10 80 00 	movl   $0x0,0x8010fde4
8010338e:	00 00 00 
    write_head();    // Erase the transaction from the log
80103391:	e8 f3 fe ff ff       	call   80103289 <write_head>
  }
  
  acquire(&log.lock);
80103396:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
8010339d:	e8 09 19 00 00       	call   80104cab <acquire>
  log.busy = 0;
801033a2:	c7 05 dc fd 10 80 00 	movl   $0x0,0x8010fddc
801033a9:	00 00 00 
  wakeup(&log);
801033ac:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
801033b3:	e8 ee 16 00 00       	call   80104aa6 <wakeup>
  release(&log.lock);
801033b8:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
801033bf:	e8 49 19 00 00       	call   80104d0d <release>
}
801033c4:	c9                   	leave  
801033c5:	c3                   	ret    

801033c6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801033c6:	55                   	push   %ebp
801033c7:	89 e5                	mov    %esp,%ebp
801033c9:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
801033cc:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
801033d1:	83 f8 09             	cmp    $0x9,%eax
801033d4:	7f 12                	jg     801033e8 <log_write+0x22>
801033d6:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
801033db:	8b 15 d8 fd 10 80    	mov    0x8010fdd8,%edx
801033e1:	83 ea 01             	sub    $0x1,%edx
801033e4:	39 d0                	cmp    %edx,%eax
801033e6:	7c 0c                	jl     801033f4 <log_write+0x2e>
    panic("too big a transaction");
801033e8:	c7 04 24 bc 84 10 80 	movl   $0x801084bc,(%esp)
801033ef:	e8 49 d1 ff ff       	call   8010053d <panic>
  if (!log.busy)
801033f4:	a1 dc fd 10 80       	mov    0x8010fddc,%eax
801033f9:	85 c0                	test   %eax,%eax
801033fb:	75 0c                	jne    80103409 <log_write+0x43>
    panic("write outside of trans");
801033fd:	c7 04 24 d2 84 10 80 	movl   $0x801084d2,(%esp)
80103404:	e8 34 d1 ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
80103409:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103410:	eb 1d                	jmp    8010342f <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
80103412:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103415:	83 c0 10             	add    $0x10,%eax
80103418:	8b 04 85 a8 fd 10 80 	mov    -0x7fef0258(,%eax,4),%eax
8010341f:	89 c2                	mov    %eax,%edx
80103421:	8b 45 08             	mov    0x8(%ebp),%eax
80103424:	8b 40 08             	mov    0x8(%eax),%eax
80103427:	39 c2                	cmp    %eax,%edx
80103429:	74 10                	je     8010343b <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
8010342b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010342f:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
80103434:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103437:	7f d9                	jg     80103412 <log_write+0x4c>
80103439:	eb 01                	jmp    8010343c <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
8010343b:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
8010343c:	8b 45 08             	mov    0x8(%ebp),%eax
8010343f:	8b 40 08             	mov    0x8(%eax),%eax
80103442:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103445:	83 c2 10             	add    $0x10,%edx
80103448:	89 04 95 a8 fd 10 80 	mov    %eax,-0x7fef0258(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
8010344f:	a1 d4 fd 10 80       	mov    0x8010fdd4,%eax
80103454:	03 45 f4             	add    -0xc(%ebp),%eax
80103457:	83 c0 01             	add    $0x1,%eax
8010345a:	89 c2                	mov    %eax,%edx
8010345c:	8b 45 08             	mov    0x8(%ebp),%eax
8010345f:	8b 40 04             	mov    0x4(%eax),%eax
80103462:	89 54 24 04          	mov    %edx,0x4(%esp)
80103466:	89 04 24             	mov    %eax,(%esp)
80103469:	e8 38 cd ff ff       	call   801001a6 <bread>
8010346e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
80103471:	8b 45 08             	mov    0x8(%ebp),%eax
80103474:	8d 50 18             	lea    0x18(%eax),%edx
80103477:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010347a:	83 c0 18             	add    $0x18,%eax
8010347d:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103484:	00 
80103485:	89 54 24 04          	mov    %edx,0x4(%esp)
80103489:	89 04 24             	mov    %eax,(%esp)
8010348c:	e8 3c 1b 00 00       	call   80104fcd <memmove>
  bwrite(lbuf);
80103491:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103494:	89 04 24             	mov    %eax,(%esp)
80103497:	e8 41 cd ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
8010349c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010349f:	89 04 24             	mov    %eax,(%esp)
801034a2:	e8 70 cd ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
801034a7:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
801034ac:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801034af:	75 0d                	jne    801034be <log_write+0xf8>
    log.lh.n++;
801034b1:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
801034b6:	83 c0 01             	add    $0x1,%eax
801034b9:	a3 e4 fd 10 80       	mov    %eax,0x8010fde4
  b->flags |= B_DIRTY; // XXX prevent eviction
801034be:	8b 45 08             	mov    0x8(%ebp),%eax
801034c1:	8b 00                	mov    (%eax),%eax
801034c3:	89 c2                	mov    %eax,%edx
801034c5:	83 ca 04             	or     $0x4,%edx
801034c8:	8b 45 08             	mov    0x8(%ebp),%eax
801034cb:	89 10                	mov    %edx,(%eax)
}
801034cd:	c9                   	leave  
801034ce:	c3                   	ret    
	...

801034d0 <v2p>:
801034d0:	55                   	push   %ebp
801034d1:	89 e5                	mov    %esp,%ebp
801034d3:	8b 45 08             	mov    0x8(%ebp),%eax
801034d6:	05 00 00 00 80       	add    $0x80000000,%eax
801034db:	5d                   	pop    %ebp
801034dc:	c3                   	ret    

801034dd <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801034dd:	55                   	push   %ebp
801034de:	89 e5                	mov    %esp,%ebp
801034e0:	8b 45 08             	mov    0x8(%ebp),%eax
801034e3:	05 00 00 00 80       	add    $0x80000000,%eax
801034e8:	5d                   	pop    %ebp
801034e9:	c3                   	ret    

801034ea <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
801034ea:	55                   	push   %ebp
801034eb:	89 e5                	mov    %esp,%ebp
801034ed:	53                   	push   %ebx
801034ee:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
801034f1:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801034f4:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
801034f7:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801034fa:	89 c3                	mov    %eax,%ebx
801034fc:	89 d8                	mov    %ebx,%eax
801034fe:	f0 87 02             	lock xchg %eax,(%edx)
80103501:	89 c3                	mov    %eax,%ebx
80103503:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103506:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103509:	83 c4 10             	add    $0x10,%esp
8010350c:	5b                   	pop    %ebx
8010350d:	5d                   	pop    %ebp
8010350e:	c3                   	ret    

8010350f <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
8010350f:	55                   	push   %ebp
80103510:	89 e5                	mov    %esp,%ebp
80103512:	83 e4 f0             	and    $0xfffffff0,%esp
80103515:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103518:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
8010351f:	80 
80103520:	c7 04 24 1c 2c 11 80 	movl   $0x80112c1c,(%esp)
80103527:	e8 ad f5 ff ff       	call   80102ad9 <kinit1>
  kvmalloc();      // kernel page table
8010352c:	e8 dd 45 00 00       	call   80107b0e <kvmalloc>
  mpinit();        // collect info about this machine
80103531:	e8 63 04 00 00       	call   80103999 <mpinit>
  lapicinit(mpbcpu());
80103536:	e8 2e 02 00 00       	call   80103769 <mpbcpu>
8010353b:	89 04 24             	mov    %eax,(%esp)
8010353e:	e8 f5 f8 ff ff       	call   80102e38 <lapicinit>
  seginit();       // set up segments
80103543:	e8 69 3f 00 00       	call   801074b1 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103548:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010354e:	0f b6 00             	movzbl (%eax),%eax
80103551:	0f b6 c0             	movzbl %al,%eax
80103554:	89 44 24 04          	mov    %eax,0x4(%esp)
80103558:	c7 04 24 e9 84 10 80 	movl   $0x801084e9,(%esp)
8010355f:	e8 3d ce ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80103564:	e8 95 06 00 00       	call   80103bfe <picinit>
  ioapicinit();    // another interrupt controller
80103569:	e8 5b f4 ff ff       	call   801029c9 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
8010356e:	e8 1a d5 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
80103573:	e8 84 32 00 00       	call   801067fc <uartinit>
  pinit();         // process table
80103578:	e8 96 0b 00 00       	call   80104113 <pinit>
  tvinit();        // trap vectors
8010357d:	e8 1d 2e 00 00       	call   8010639f <tvinit>
  binit();         // buffer cache
80103582:	e8 ad ca ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103587:	e8 7c da ff ff       	call   80101008 <fileinit>
  iinit();         // inode cache
8010358c:	e8 2a e1 ff ff       	call   801016bb <iinit>
  ideinit();       // disk
80103591:	e8 98 f0 ff ff       	call   8010262e <ideinit>
  if(!ismp)
80103596:	a1 24 fe 10 80       	mov    0x8010fe24,%eax
8010359b:	85 c0                	test   %eax,%eax
8010359d:	75 05                	jne    801035a4 <main+0x95>
    timerinit();   // uniprocessor timer
8010359f:	e8 3e 2d 00 00       	call   801062e2 <timerinit>
  startothers();   // start other processors
801035a4:	e8 87 00 00 00       	call   80103630 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801035a9:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801035b0:	8e 
801035b1:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
801035b8:	e8 54 f5 ff ff       	call   80102b11 <kinit2>
  userinit();      // first user process
801035bd:	e8 6c 0c 00 00       	call   8010422e <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
801035c2:	e8 22 00 00 00       	call   801035e9 <mpmain>

801035c7 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801035c7:	55                   	push   %ebp
801035c8:	89 e5                	mov    %esp,%ebp
801035ca:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
801035cd:	e8 53 45 00 00       	call   80107b25 <switchkvm>
  seginit();
801035d2:	e8 da 3e 00 00       	call   801074b1 <seginit>
  lapicinit(cpunum());
801035d7:	e8 b9 f9 ff ff       	call   80102f95 <cpunum>
801035dc:	89 04 24             	mov    %eax,(%esp)
801035df:	e8 54 f8 ff ff       	call   80102e38 <lapicinit>
  mpmain();
801035e4:	e8 00 00 00 00       	call   801035e9 <mpmain>

801035e9 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
801035e9:	55                   	push   %ebp
801035ea:	89 e5                	mov    %esp,%ebp
801035ec:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
801035ef:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801035f5:	0f b6 00             	movzbl (%eax),%eax
801035f8:	0f b6 c0             	movzbl %al,%eax
801035fb:	89 44 24 04          	mov    %eax,0x4(%esp)
801035ff:	c7 04 24 00 85 10 80 	movl   $0x80108500,(%esp)
80103606:	e8 96 cd ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
8010360b:	e8 03 2f 00 00       	call   80106513 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103610:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103616:	05 a8 00 00 00       	add    $0xa8,%eax
8010361b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103622:	00 
80103623:	89 04 24             	mov    %eax,(%esp)
80103626:	e8 bf fe ff ff       	call   801034ea <xchg>
  scheduler();     // start running processes
8010362b:	e8 f4 11 00 00       	call   80104824 <scheduler>

80103630 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103630:	55                   	push   %ebp
80103631:	89 e5                	mov    %esp,%ebp
80103633:	53                   	push   %ebx
80103634:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103637:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
8010363e:	e8 9a fe ff ff       	call   801034dd <p2v>
80103643:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103646:	b8 8a 00 00 00       	mov    $0x8a,%eax
8010364b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010364f:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
80103656:	80 
80103657:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010365a:	89 04 24             	mov    %eax,(%esp)
8010365d:	e8 6b 19 00 00       	call   80104fcd <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103662:	c7 45 f4 40 fe 10 80 	movl   $0x8010fe40,-0xc(%ebp)
80103669:	e9 86 00 00 00       	jmp    801036f4 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
8010366e:	e8 22 f9 ff ff       	call   80102f95 <cpunum>
80103673:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103679:	05 40 fe 10 80       	add    $0x8010fe40,%eax
8010367e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103681:	74 69                	je     801036ec <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103683:	e8 7f f5 ff ff       	call   80102c07 <kalloc>
80103688:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
8010368b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010368e:	83 e8 04             	sub    $0x4,%eax
80103691:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103694:	81 c2 00 10 00 00    	add    $0x1000,%edx
8010369a:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
8010369c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010369f:	83 e8 08             	sub    $0x8,%eax
801036a2:	c7 00 c7 35 10 80    	movl   $0x801035c7,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
801036a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036ab:	8d 58 f4             	lea    -0xc(%eax),%ebx
801036ae:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
801036b5:	e8 16 fe ff ff       	call   801034d0 <v2p>
801036ba:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
801036bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036bf:	89 04 24             	mov    %eax,(%esp)
801036c2:	e8 09 fe ff ff       	call   801034d0 <v2p>
801036c7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801036ca:	0f b6 12             	movzbl (%edx),%edx
801036cd:	0f b6 d2             	movzbl %dl,%edx
801036d0:	89 44 24 04          	mov    %eax,0x4(%esp)
801036d4:	89 14 24             	mov    %edx,(%esp)
801036d7:	e8 3f f9 ff ff       	call   8010301b <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
801036dc:	90                   	nop
801036dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036e0:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
801036e6:	85 c0                	test   %eax,%eax
801036e8:	74 f3                	je     801036dd <startothers+0xad>
801036ea:	eb 01                	jmp    801036ed <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
801036ec:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
801036ed:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
801036f4:	a1 20 04 11 80       	mov    0x80110420,%eax
801036f9:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801036ff:	05 40 fe 10 80       	add    $0x8010fe40,%eax
80103704:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103707:	0f 87 61 ff ff ff    	ja     8010366e <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
8010370d:	83 c4 24             	add    $0x24,%esp
80103710:	5b                   	pop    %ebx
80103711:	5d                   	pop    %ebp
80103712:	c3                   	ret    
	...

80103714 <p2v>:
80103714:	55                   	push   %ebp
80103715:	89 e5                	mov    %esp,%ebp
80103717:	8b 45 08             	mov    0x8(%ebp),%eax
8010371a:	05 00 00 00 80       	add    $0x80000000,%eax
8010371f:	5d                   	pop    %ebp
80103720:	c3                   	ret    

80103721 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103721:	55                   	push   %ebp
80103722:	89 e5                	mov    %esp,%ebp
80103724:	53                   	push   %ebx
80103725:	83 ec 14             	sub    $0x14,%esp
80103728:	8b 45 08             	mov    0x8(%ebp),%eax
8010372b:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010372f:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103733:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103737:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010373b:	ec                   	in     (%dx),%al
8010373c:	89 c3                	mov    %eax,%ebx
8010373e:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103741:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103745:	83 c4 14             	add    $0x14,%esp
80103748:	5b                   	pop    %ebx
80103749:	5d                   	pop    %ebp
8010374a:	c3                   	ret    

8010374b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010374b:	55                   	push   %ebp
8010374c:	89 e5                	mov    %esp,%ebp
8010374e:	83 ec 08             	sub    $0x8,%esp
80103751:	8b 55 08             	mov    0x8(%ebp),%edx
80103754:	8b 45 0c             	mov    0xc(%ebp),%eax
80103757:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010375b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010375e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103762:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103766:	ee                   	out    %al,(%dx)
}
80103767:	c9                   	leave  
80103768:	c3                   	ret    

80103769 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103769:	55                   	push   %ebp
8010376a:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
8010376c:	a1 44 b6 10 80       	mov    0x8010b644,%eax
80103771:	89 c2                	mov    %eax,%edx
80103773:	b8 40 fe 10 80       	mov    $0x8010fe40,%eax
80103778:	89 d1                	mov    %edx,%ecx
8010377a:	29 c1                	sub    %eax,%ecx
8010377c:	89 c8                	mov    %ecx,%eax
8010377e:	c1 f8 02             	sar    $0x2,%eax
80103781:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103787:	5d                   	pop    %ebp
80103788:	c3                   	ret    

80103789 <sum>:

static uchar
sum(uchar *addr, int len)
{
80103789:	55                   	push   %ebp
8010378a:	89 e5                	mov    %esp,%ebp
8010378c:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
8010378f:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103796:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010379d:	eb 13                	jmp    801037b2 <sum+0x29>
    sum += addr[i];
8010379f:	8b 45 fc             	mov    -0x4(%ebp),%eax
801037a2:	03 45 08             	add    0x8(%ebp),%eax
801037a5:	0f b6 00             	movzbl (%eax),%eax
801037a8:	0f b6 c0             	movzbl %al,%eax
801037ab:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
801037ae:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801037b2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801037b5:	3b 45 0c             	cmp    0xc(%ebp),%eax
801037b8:	7c e5                	jl     8010379f <sum+0x16>
    sum += addr[i];
  return sum;
801037ba:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801037bd:	c9                   	leave  
801037be:	c3                   	ret    

801037bf <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
801037bf:	55                   	push   %ebp
801037c0:	89 e5                	mov    %esp,%ebp
801037c2:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
801037c5:	8b 45 08             	mov    0x8(%ebp),%eax
801037c8:	89 04 24             	mov    %eax,(%esp)
801037cb:	e8 44 ff ff ff       	call   80103714 <p2v>
801037d0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
801037d3:	8b 45 0c             	mov    0xc(%ebp),%eax
801037d6:	03 45 f0             	add    -0x10(%ebp),%eax
801037d9:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
801037dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037df:	89 45 f4             	mov    %eax,-0xc(%ebp)
801037e2:	eb 3f                	jmp    80103823 <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
801037e4:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801037eb:	00 
801037ec:	c7 44 24 04 14 85 10 	movl   $0x80108514,0x4(%esp)
801037f3:	80 
801037f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037f7:	89 04 24             	mov    %eax,(%esp)
801037fa:	e8 72 17 00 00       	call   80104f71 <memcmp>
801037ff:	85 c0                	test   %eax,%eax
80103801:	75 1c                	jne    8010381f <mpsearch1+0x60>
80103803:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010380a:	00 
8010380b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010380e:	89 04 24             	mov    %eax,(%esp)
80103811:	e8 73 ff ff ff       	call   80103789 <sum>
80103816:	84 c0                	test   %al,%al
80103818:	75 05                	jne    8010381f <mpsearch1+0x60>
      return (struct mp*)p;
8010381a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010381d:	eb 11                	jmp    80103830 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
8010381f:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103823:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103826:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103829:	72 b9                	jb     801037e4 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
8010382b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103830:	c9                   	leave  
80103831:	c3                   	ret    

80103832 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103832:	55                   	push   %ebp
80103833:	89 e5                	mov    %esp,%ebp
80103835:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103838:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
8010383f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103842:	83 c0 0f             	add    $0xf,%eax
80103845:	0f b6 00             	movzbl (%eax),%eax
80103848:	0f b6 c0             	movzbl %al,%eax
8010384b:	89 c2                	mov    %eax,%edx
8010384d:	c1 e2 08             	shl    $0x8,%edx
80103850:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103853:	83 c0 0e             	add    $0xe,%eax
80103856:	0f b6 00             	movzbl (%eax),%eax
80103859:	0f b6 c0             	movzbl %al,%eax
8010385c:	09 d0                	or     %edx,%eax
8010385e:	c1 e0 04             	shl    $0x4,%eax
80103861:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103864:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103868:	74 21                	je     8010388b <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
8010386a:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103871:	00 
80103872:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103875:	89 04 24             	mov    %eax,(%esp)
80103878:	e8 42 ff ff ff       	call   801037bf <mpsearch1>
8010387d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103880:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103884:	74 50                	je     801038d6 <mpsearch+0xa4>
      return mp;
80103886:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103889:	eb 5f                	jmp    801038ea <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
8010388b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010388e:	83 c0 14             	add    $0x14,%eax
80103891:	0f b6 00             	movzbl (%eax),%eax
80103894:	0f b6 c0             	movzbl %al,%eax
80103897:	89 c2                	mov    %eax,%edx
80103899:	c1 e2 08             	shl    $0x8,%edx
8010389c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010389f:	83 c0 13             	add    $0x13,%eax
801038a2:	0f b6 00             	movzbl (%eax),%eax
801038a5:	0f b6 c0             	movzbl %al,%eax
801038a8:	09 d0                	or     %edx,%eax
801038aa:	c1 e0 0a             	shl    $0xa,%eax
801038ad:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
801038b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038b3:	2d 00 04 00 00       	sub    $0x400,%eax
801038b8:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801038bf:	00 
801038c0:	89 04 24             	mov    %eax,(%esp)
801038c3:	e8 f7 fe ff ff       	call   801037bf <mpsearch1>
801038c8:	89 45 ec             	mov    %eax,-0x14(%ebp)
801038cb:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801038cf:	74 05                	je     801038d6 <mpsearch+0xa4>
      return mp;
801038d1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801038d4:	eb 14                	jmp    801038ea <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
801038d6:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801038dd:	00 
801038de:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
801038e5:	e8 d5 fe ff ff       	call   801037bf <mpsearch1>
}
801038ea:	c9                   	leave  
801038eb:	c3                   	ret    

801038ec <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
801038ec:	55                   	push   %ebp
801038ed:	89 e5                	mov    %esp,%ebp
801038ef:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
801038f2:	e8 3b ff ff ff       	call   80103832 <mpsearch>
801038f7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801038fa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801038fe:	74 0a                	je     8010390a <mpconfig+0x1e>
80103900:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103903:	8b 40 04             	mov    0x4(%eax),%eax
80103906:	85 c0                	test   %eax,%eax
80103908:	75 0a                	jne    80103914 <mpconfig+0x28>
    return 0;
8010390a:	b8 00 00 00 00       	mov    $0x0,%eax
8010390f:	e9 83 00 00 00       	jmp    80103997 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103914:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103917:	8b 40 04             	mov    0x4(%eax),%eax
8010391a:	89 04 24             	mov    %eax,(%esp)
8010391d:	e8 f2 fd ff ff       	call   80103714 <p2v>
80103922:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103925:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010392c:	00 
8010392d:	c7 44 24 04 19 85 10 	movl   $0x80108519,0x4(%esp)
80103934:	80 
80103935:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103938:	89 04 24             	mov    %eax,(%esp)
8010393b:	e8 31 16 00 00       	call   80104f71 <memcmp>
80103940:	85 c0                	test   %eax,%eax
80103942:	74 07                	je     8010394b <mpconfig+0x5f>
    return 0;
80103944:	b8 00 00 00 00       	mov    $0x0,%eax
80103949:	eb 4c                	jmp    80103997 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
8010394b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010394e:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103952:	3c 01                	cmp    $0x1,%al
80103954:	74 12                	je     80103968 <mpconfig+0x7c>
80103956:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103959:	0f b6 40 06          	movzbl 0x6(%eax),%eax
8010395d:	3c 04                	cmp    $0x4,%al
8010395f:	74 07                	je     80103968 <mpconfig+0x7c>
    return 0;
80103961:	b8 00 00 00 00       	mov    $0x0,%eax
80103966:	eb 2f                	jmp    80103997 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103968:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010396b:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010396f:	0f b7 c0             	movzwl %ax,%eax
80103972:	89 44 24 04          	mov    %eax,0x4(%esp)
80103976:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103979:	89 04 24             	mov    %eax,(%esp)
8010397c:	e8 08 fe ff ff       	call   80103789 <sum>
80103981:	84 c0                	test   %al,%al
80103983:	74 07                	je     8010398c <mpconfig+0xa0>
    return 0;
80103985:	b8 00 00 00 00       	mov    $0x0,%eax
8010398a:	eb 0b                	jmp    80103997 <mpconfig+0xab>
  *pmp = mp;
8010398c:	8b 45 08             	mov    0x8(%ebp),%eax
8010398f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103992:	89 10                	mov    %edx,(%eax)
  return conf;
80103994:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103997:	c9                   	leave  
80103998:	c3                   	ret    

80103999 <mpinit>:

void
mpinit(void)
{
80103999:	55                   	push   %ebp
8010399a:	89 e5                	mov    %esp,%ebp
8010399c:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
8010399f:	c7 05 44 b6 10 80 40 	movl   $0x8010fe40,0x8010b644
801039a6:	fe 10 80 
  if((conf = mpconfig(&mp)) == 0)
801039a9:	8d 45 e0             	lea    -0x20(%ebp),%eax
801039ac:	89 04 24             	mov    %eax,(%esp)
801039af:	e8 38 ff ff ff       	call   801038ec <mpconfig>
801039b4:	89 45 f0             	mov    %eax,-0x10(%ebp)
801039b7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801039bb:	0f 84 9c 01 00 00    	je     80103b5d <mpinit+0x1c4>
    return;
  ismp = 1;
801039c1:	c7 05 24 fe 10 80 01 	movl   $0x1,0x8010fe24
801039c8:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
801039cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039ce:	8b 40 24             	mov    0x24(%eax),%eax
801039d1:	a3 9c fd 10 80       	mov    %eax,0x8010fd9c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
801039d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039d9:	83 c0 2c             	add    $0x2c,%eax
801039dc:	89 45 f4             	mov    %eax,-0xc(%ebp)
801039df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039e2:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801039e6:	0f b7 c0             	movzwl %ax,%eax
801039e9:	03 45 f0             	add    -0x10(%ebp),%eax
801039ec:	89 45 ec             	mov    %eax,-0x14(%ebp)
801039ef:	e9 f4 00 00 00       	jmp    80103ae8 <mpinit+0x14f>
    switch(*p){
801039f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039f7:	0f b6 00             	movzbl (%eax),%eax
801039fa:	0f b6 c0             	movzbl %al,%eax
801039fd:	83 f8 04             	cmp    $0x4,%eax
80103a00:	0f 87 bf 00 00 00    	ja     80103ac5 <mpinit+0x12c>
80103a06:	8b 04 85 5c 85 10 80 	mov    -0x7fef7aa4(,%eax,4),%eax
80103a0d:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103a0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a12:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103a15:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103a18:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103a1c:	0f b6 d0             	movzbl %al,%edx
80103a1f:	a1 20 04 11 80       	mov    0x80110420,%eax
80103a24:	39 c2                	cmp    %eax,%edx
80103a26:	74 2d                	je     80103a55 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103a28:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103a2b:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103a2f:	0f b6 d0             	movzbl %al,%edx
80103a32:	a1 20 04 11 80       	mov    0x80110420,%eax
80103a37:	89 54 24 08          	mov    %edx,0x8(%esp)
80103a3b:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a3f:	c7 04 24 1e 85 10 80 	movl   $0x8010851e,(%esp)
80103a46:	e8 56 c9 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
80103a4b:	c7 05 24 fe 10 80 00 	movl   $0x0,0x8010fe24
80103a52:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103a55:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103a58:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103a5c:	0f b6 c0             	movzbl %al,%eax
80103a5f:	83 e0 02             	and    $0x2,%eax
80103a62:	85 c0                	test   %eax,%eax
80103a64:	74 15                	je     80103a7b <mpinit+0xe2>
        bcpu = &cpus[ncpu];
80103a66:	a1 20 04 11 80       	mov    0x80110420,%eax
80103a6b:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103a71:	05 40 fe 10 80       	add    $0x8010fe40,%eax
80103a76:	a3 44 b6 10 80       	mov    %eax,0x8010b644
      cpus[ncpu].id = ncpu;
80103a7b:	8b 15 20 04 11 80    	mov    0x80110420,%edx
80103a81:	a1 20 04 11 80       	mov    0x80110420,%eax
80103a86:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103a8c:	81 c2 40 fe 10 80    	add    $0x8010fe40,%edx
80103a92:	88 02                	mov    %al,(%edx)
      ncpu++;
80103a94:	a1 20 04 11 80       	mov    0x80110420,%eax
80103a99:	83 c0 01             	add    $0x1,%eax
80103a9c:	a3 20 04 11 80       	mov    %eax,0x80110420
      p += sizeof(struct mpproc);
80103aa1:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103aa5:	eb 41                	jmp    80103ae8 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103aa7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103aaa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103aad:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103ab0:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103ab4:	a2 20 fe 10 80       	mov    %al,0x8010fe20
      p += sizeof(struct mpioapic);
80103ab9:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103abd:	eb 29                	jmp    80103ae8 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103abf:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103ac3:	eb 23                	jmp    80103ae8 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103ac5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ac8:	0f b6 00             	movzbl (%eax),%eax
80103acb:	0f b6 c0             	movzbl %al,%eax
80103ace:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ad2:	c7 04 24 3c 85 10 80 	movl   $0x8010853c,(%esp)
80103ad9:	e8 c3 c8 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80103ade:	c7 05 24 fe 10 80 00 	movl   $0x0,0x8010fe24
80103ae5:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103ae8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103aeb:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103aee:	0f 82 00 ff ff ff    	jb     801039f4 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103af4:	a1 24 fe 10 80       	mov    0x8010fe24,%eax
80103af9:	85 c0                	test   %eax,%eax
80103afb:	75 1d                	jne    80103b1a <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103afd:	c7 05 20 04 11 80 01 	movl   $0x1,0x80110420
80103b04:	00 00 00 
    lapic = 0;
80103b07:	c7 05 9c fd 10 80 00 	movl   $0x0,0x8010fd9c
80103b0e:	00 00 00 
    ioapicid = 0;
80103b11:	c6 05 20 fe 10 80 00 	movb   $0x0,0x8010fe20
    return;
80103b18:	eb 44                	jmp    80103b5e <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103b1a:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103b1d:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103b21:	84 c0                	test   %al,%al
80103b23:	74 39                	je     80103b5e <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103b25:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103b2c:	00 
80103b2d:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103b34:	e8 12 fc ff ff       	call   8010374b <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103b39:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103b40:	e8 dc fb ff ff       	call   80103721 <inb>
80103b45:	83 c8 01             	or     $0x1,%eax
80103b48:	0f b6 c0             	movzbl %al,%eax
80103b4b:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b4f:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103b56:	e8 f0 fb ff ff       	call   8010374b <outb>
80103b5b:	eb 01                	jmp    80103b5e <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80103b5d:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80103b5e:	c9                   	leave  
80103b5f:	c3                   	ret    

80103b60 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103b60:	55                   	push   %ebp
80103b61:	89 e5                	mov    %esp,%ebp
80103b63:	83 ec 08             	sub    $0x8,%esp
80103b66:	8b 55 08             	mov    0x8(%ebp),%edx
80103b69:	8b 45 0c             	mov    0xc(%ebp),%eax
80103b6c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103b70:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103b73:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103b77:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103b7b:	ee                   	out    %al,(%dx)
}
80103b7c:	c9                   	leave  
80103b7d:	c3                   	ret    

80103b7e <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103b7e:	55                   	push   %ebp
80103b7f:	89 e5                	mov    %esp,%ebp
80103b81:	83 ec 0c             	sub    $0xc,%esp
80103b84:	8b 45 08             	mov    0x8(%ebp),%eax
80103b87:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103b8b:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103b8f:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80103b95:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103b99:	0f b6 c0             	movzbl %al,%eax
80103b9c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ba0:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103ba7:	e8 b4 ff ff ff       	call   80103b60 <outb>
  outb(IO_PIC2+1, mask >> 8);
80103bac:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103bb0:	66 c1 e8 08          	shr    $0x8,%ax
80103bb4:	0f b6 c0             	movzbl %al,%eax
80103bb7:	89 44 24 04          	mov    %eax,0x4(%esp)
80103bbb:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103bc2:	e8 99 ff ff ff       	call   80103b60 <outb>
}
80103bc7:	c9                   	leave  
80103bc8:	c3                   	ret    

80103bc9 <picenable>:

void
picenable(int irq)
{
80103bc9:	55                   	push   %ebp
80103bca:	89 e5                	mov    %esp,%ebp
80103bcc:	53                   	push   %ebx
80103bcd:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103bd0:	8b 45 08             	mov    0x8(%ebp),%eax
80103bd3:	ba 01 00 00 00       	mov    $0x1,%edx
80103bd8:	89 d3                	mov    %edx,%ebx
80103bda:	89 c1                	mov    %eax,%ecx
80103bdc:	d3 e3                	shl    %cl,%ebx
80103bde:	89 d8                	mov    %ebx,%eax
80103be0:	89 c2                	mov    %eax,%edx
80103be2:	f7 d2                	not    %edx
80103be4:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103beb:	21 d0                	and    %edx,%eax
80103bed:	0f b7 c0             	movzwl %ax,%eax
80103bf0:	89 04 24             	mov    %eax,(%esp)
80103bf3:	e8 86 ff ff ff       	call   80103b7e <picsetmask>
}
80103bf8:	83 c4 04             	add    $0x4,%esp
80103bfb:	5b                   	pop    %ebx
80103bfc:	5d                   	pop    %ebp
80103bfd:	c3                   	ret    

80103bfe <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103bfe:	55                   	push   %ebp
80103bff:	89 e5                	mov    %esp,%ebp
80103c01:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103c04:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103c0b:	00 
80103c0c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103c13:	e8 48 ff ff ff       	call   80103b60 <outb>
  outb(IO_PIC2+1, 0xFF);
80103c18:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103c1f:	00 
80103c20:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103c27:	e8 34 ff ff ff       	call   80103b60 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103c2c:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103c33:	00 
80103c34:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103c3b:	e8 20 ff ff ff       	call   80103b60 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103c40:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103c47:	00 
80103c48:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103c4f:	e8 0c ff ff ff       	call   80103b60 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103c54:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103c5b:	00 
80103c5c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103c63:	e8 f8 fe ff ff       	call   80103b60 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103c68:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103c6f:	00 
80103c70:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103c77:	e8 e4 fe ff ff       	call   80103b60 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103c7c:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103c83:	00 
80103c84:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103c8b:	e8 d0 fe ff ff       	call   80103b60 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103c90:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103c97:	00 
80103c98:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103c9f:	e8 bc fe ff ff       	call   80103b60 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103ca4:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103cab:	00 
80103cac:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103cb3:	e8 a8 fe ff ff       	call   80103b60 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103cb8:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103cbf:	00 
80103cc0:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103cc7:	e8 94 fe ff ff       	call   80103b60 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103ccc:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103cd3:	00 
80103cd4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103cdb:	e8 80 fe ff ff       	call   80103b60 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80103ce0:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103ce7:	00 
80103ce8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103cef:	e8 6c fe ff ff       	call   80103b60 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80103cf4:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103cfb:	00 
80103cfc:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103d03:	e8 58 fe ff ff       	call   80103b60 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80103d08:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103d0f:	00 
80103d10:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103d17:	e8 44 fe ff ff       	call   80103b60 <outb>

  if(irqmask != 0xFFFF)
80103d1c:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103d23:	66 83 f8 ff          	cmp    $0xffff,%ax
80103d27:	74 12                	je     80103d3b <picinit+0x13d>
    picsetmask(irqmask);
80103d29:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103d30:	0f b7 c0             	movzwl %ax,%eax
80103d33:	89 04 24             	mov    %eax,(%esp)
80103d36:	e8 43 fe ff ff       	call   80103b7e <picsetmask>
}
80103d3b:	c9                   	leave  
80103d3c:	c3                   	ret    
80103d3d:	00 00                	add    %al,(%eax)
	...

80103d40 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103d40:	55                   	push   %ebp
80103d41:	89 e5                	mov    %esp,%ebp
80103d43:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80103d46:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103d4d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d50:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103d56:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d59:	8b 10                	mov    (%eax),%edx
80103d5b:	8b 45 08             	mov    0x8(%ebp),%eax
80103d5e:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103d60:	e8 bf d2 ff ff       	call   80101024 <filealloc>
80103d65:	8b 55 08             	mov    0x8(%ebp),%edx
80103d68:	89 02                	mov    %eax,(%edx)
80103d6a:	8b 45 08             	mov    0x8(%ebp),%eax
80103d6d:	8b 00                	mov    (%eax),%eax
80103d6f:	85 c0                	test   %eax,%eax
80103d71:	0f 84 c8 00 00 00    	je     80103e3f <pipealloc+0xff>
80103d77:	e8 a8 d2 ff ff       	call   80101024 <filealloc>
80103d7c:	8b 55 0c             	mov    0xc(%ebp),%edx
80103d7f:	89 02                	mov    %eax,(%edx)
80103d81:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d84:	8b 00                	mov    (%eax),%eax
80103d86:	85 c0                	test   %eax,%eax
80103d88:	0f 84 b1 00 00 00    	je     80103e3f <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103d8e:	e8 74 ee ff ff       	call   80102c07 <kalloc>
80103d93:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103d96:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103d9a:	0f 84 9e 00 00 00    	je     80103e3e <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80103da0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103da3:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103daa:	00 00 00 
  p->writeopen = 1;
80103dad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103db0:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103db7:	00 00 00 
  p->nwrite = 0;
80103dba:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103dbd:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103dc4:	00 00 00 
  p->nread = 0;
80103dc7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103dca:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103dd1:	00 00 00 
  initlock(&p->lock, "pipe");
80103dd4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103dd7:	c7 44 24 04 70 85 10 	movl   $0x80108570,0x4(%esp)
80103dde:	80 
80103ddf:	89 04 24             	mov    %eax,(%esp)
80103de2:	e8 a3 0e 00 00       	call   80104c8a <initlock>
  (*f0)->type = FD_PIPE;
80103de7:	8b 45 08             	mov    0x8(%ebp),%eax
80103dea:	8b 00                	mov    (%eax),%eax
80103dec:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103df2:	8b 45 08             	mov    0x8(%ebp),%eax
80103df5:	8b 00                	mov    (%eax),%eax
80103df7:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103dfb:	8b 45 08             	mov    0x8(%ebp),%eax
80103dfe:	8b 00                	mov    (%eax),%eax
80103e00:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103e04:	8b 45 08             	mov    0x8(%ebp),%eax
80103e07:	8b 00                	mov    (%eax),%eax
80103e09:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103e0c:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103e0f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e12:	8b 00                	mov    (%eax),%eax
80103e14:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103e1a:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e1d:	8b 00                	mov    (%eax),%eax
80103e1f:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103e23:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e26:	8b 00                	mov    (%eax),%eax
80103e28:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103e2c:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e2f:	8b 00                	mov    (%eax),%eax
80103e31:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103e34:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80103e37:	b8 00 00 00 00       	mov    $0x0,%eax
80103e3c:	eb 43                	jmp    80103e81 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80103e3e:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80103e3f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103e43:	74 0b                	je     80103e50 <pipealloc+0x110>
    kfree((char*)p);
80103e45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e48:	89 04 24             	mov    %eax,(%esp)
80103e4b:	e8 1e ed ff ff       	call   80102b6e <kfree>
  if(*f0)
80103e50:	8b 45 08             	mov    0x8(%ebp),%eax
80103e53:	8b 00                	mov    (%eax),%eax
80103e55:	85 c0                	test   %eax,%eax
80103e57:	74 0d                	je     80103e66 <pipealloc+0x126>
    fileclose(*f0);
80103e59:	8b 45 08             	mov    0x8(%ebp),%eax
80103e5c:	8b 00                	mov    (%eax),%eax
80103e5e:	89 04 24             	mov    %eax,(%esp)
80103e61:	e8 66 d2 ff ff       	call   801010cc <fileclose>
  if(*f1)
80103e66:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e69:	8b 00                	mov    (%eax),%eax
80103e6b:	85 c0                	test   %eax,%eax
80103e6d:	74 0d                	je     80103e7c <pipealloc+0x13c>
    fileclose(*f1);
80103e6f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e72:	8b 00                	mov    (%eax),%eax
80103e74:	89 04 24             	mov    %eax,(%esp)
80103e77:	e8 50 d2 ff ff       	call   801010cc <fileclose>
  return -1;
80103e7c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103e81:	c9                   	leave  
80103e82:	c3                   	ret    

80103e83 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103e83:	55                   	push   %ebp
80103e84:	89 e5                	mov    %esp,%ebp
80103e86:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80103e89:	8b 45 08             	mov    0x8(%ebp),%eax
80103e8c:	89 04 24             	mov    %eax,(%esp)
80103e8f:	e8 17 0e 00 00       	call   80104cab <acquire>
  if(writable){
80103e94:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103e98:	74 1f                	je     80103eb9 <pipeclose+0x36>
    p->writeopen = 0;
80103e9a:	8b 45 08             	mov    0x8(%ebp),%eax
80103e9d:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80103ea4:	00 00 00 
    wakeup(&p->nread);
80103ea7:	8b 45 08             	mov    0x8(%ebp),%eax
80103eaa:	05 34 02 00 00       	add    $0x234,%eax
80103eaf:	89 04 24             	mov    %eax,(%esp)
80103eb2:	e8 ef 0b 00 00       	call   80104aa6 <wakeup>
80103eb7:	eb 1d                	jmp    80103ed6 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80103eb9:	8b 45 08             	mov    0x8(%ebp),%eax
80103ebc:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80103ec3:	00 00 00 
    wakeup(&p->nwrite);
80103ec6:	8b 45 08             	mov    0x8(%ebp),%eax
80103ec9:	05 38 02 00 00       	add    $0x238,%eax
80103ece:	89 04 24             	mov    %eax,(%esp)
80103ed1:	e8 d0 0b 00 00       	call   80104aa6 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103ed6:	8b 45 08             	mov    0x8(%ebp),%eax
80103ed9:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103edf:	85 c0                	test   %eax,%eax
80103ee1:	75 25                	jne    80103f08 <pipeclose+0x85>
80103ee3:	8b 45 08             	mov    0x8(%ebp),%eax
80103ee6:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103eec:	85 c0                	test   %eax,%eax
80103eee:	75 18                	jne    80103f08 <pipeclose+0x85>
    release(&p->lock);
80103ef0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ef3:	89 04 24             	mov    %eax,(%esp)
80103ef6:	e8 12 0e 00 00       	call   80104d0d <release>
    kfree((char*)p);
80103efb:	8b 45 08             	mov    0x8(%ebp),%eax
80103efe:	89 04 24             	mov    %eax,(%esp)
80103f01:	e8 68 ec ff ff       	call   80102b6e <kfree>
80103f06:	eb 0b                	jmp    80103f13 <pipeclose+0x90>
  } else
    release(&p->lock);
80103f08:	8b 45 08             	mov    0x8(%ebp),%eax
80103f0b:	89 04 24             	mov    %eax,(%esp)
80103f0e:	e8 fa 0d 00 00       	call   80104d0d <release>
}
80103f13:	c9                   	leave  
80103f14:	c3                   	ret    

80103f15 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80103f15:	55                   	push   %ebp
80103f16:	89 e5                	mov    %esp,%ebp
80103f18:	53                   	push   %ebx
80103f19:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80103f1c:	8b 45 08             	mov    0x8(%ebp),%eax
80103f1f:	89 04 24             	mov    %eax,(%esp)
80103f22:	e8 84 0d 00 00       	call   80104cab <acquire>
  for(i = 0; i < n; i++){
80103f27:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103f2e:	e9 a6 00 00 00       	jmp    80103fd9 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
80103f33:	8b 45 08             	mov    0x8(%ebp),%eax
80103f36:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103f3c:	85 c0                	test   %eax,%eax
80103f3e:	74 0d                	je     80103f4d <pipewrite+0x38>
80103f40:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103f46:	8b 40 24             	mov    0x24(%eax),%eax
80103f49:	85 c0                	test   %eax,%eax
80103f4b:	74 15                	je     80103f62 <pipewrite+0x4d>
        release(&p->lock);
80103f4d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f50:	89 04 24             	mov    %eax,(%esp)
80103f53:	e8 b5 0d 00 00       	call   80104d0d <release>
        return -1;
80103f58:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f5d:	e9 9d 00 00 00       	jmp    80103fff <pipewrite+0xea>
      }
      wakeup(&p->nread);
80103f62:	8b 45 08             	mov    0x8(%ebp),%eax
80103f65:	05 34 02 00 00       	add    $0x234,%eax
80103f6a:	89 04 24             	mov    %eax,(%esp)
80103f6d:	e8 34 0b 00 00       	call   80104aa6 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103f72:	8b 45 08             	mov    0x8(%ebp),%eax
80103f75:	8b 55 08             	mov    0x8(%ebp),%edx
80103f78:	81 c2 38 02 00 00    	add    $0x238,%edx
80103f7e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f82:	89 14 24             	mov    %edx,(%esp)
80103f85:	e8 43 0a 00 00       	call   801049cd <sleep>
80103f8a:	eb 01                	jmp    80103f8d <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103f8c:	90                   	nop
80103f8d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f90:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80103f96:	8b 45 08             	mov    0x8(%ebp),%eax
80103f99:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80103f9f:	05 00 02 00 00       	add    $0x200,%eax
80103fa4:	39 c2                	cmp    %eax,%edx
80103fa6:	74 8b                	je     80103f33 <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103fa8:	8b 45 08             	mov    0x8(%ebp),%eax
80103fab:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103fb1:	89 c3                	mov    %eax,%ebx
80103fb3:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80103fb9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103fbc:	03 55 0c             	add    0xc(%ebp),%edx
80103fbf:	0f b6 0a             	movzbl (%edx),%ecx
80103fc2:	8b 55 08             	mov    0x8(%ebp),%edx
80103fc5:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
80103fc9:	8d 50 01             	lea    0x1(%eax),%edx
80103fcc:	8b 45 08             	mov    0x8(%ebp),%eax
80103fcf:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80103fd5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103fd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fdc:	3b 45 10             	cmp    0x10(%ebp),%eax
80103fdf:	7c ab                	jl     80103f8c <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103fe1:	8b 45 08             	mov    0x8(%ebp),%eax
80103fe4:	05 34 02 00 00       	add    $0x234,%eax
80103fe9:	89 04 24             	mov    %eax,(%esp)
80103fec:	e8 b5 0a 00 00       	call   80104aa6 <wakeup>
  release(&p->lock);
80103ff1:	8b 45 08             	mov    0x8(%ebp),%eax
80103ff4:	89 04 24             	mov    %eax,(%esp)
80103ff7:	e8 11 0d 00 00       	call   80104d0d <release>
  return n;
80103ffc:	8b 45 10             	mov    0x10(%ebp),%eax
}
80103fff:	83 c4 24             	add    $0x24,%esp
80104002:	5b                   	pop    %ebx
80104003:	5d                   	pop    %ebp
80104004:	c3                   	ret    

80104005 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104005:	55                   	push   %ebp
80104006:	89 e5                	mov    %esp,%ebp
80104008:	53                   	push   %ebx
80104009:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
8010400c:	8b 45 08             	mov    0x8(%ebp),%eax
8010400f:	89 04 24             	mov    %eax,(%esp)
80104012:	e8 94 0c 00 00       	call   80104cab <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104017:	eb 3a                	jmp    80104053 <piperead+0x4e>
    if(proc->killed){
80104019:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010401f:	8b 40 24             	mov    0x24(%eax),%eax
80104022:	85 c0                	test   %eax,%eax
80104024:	74 15                	je     8010403b <piperead+0x36>
      release(&p->lock);
80104026:	8b 45 08             	mov    0x8(%ebp),%eax
80104029:	89 04 24             	mov    %eax,(%esp)
8010402c:	e8 dc 0c 00 00       	call   80104d0d <release>
      return -1;
80104031:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104036:	e9 b6 00 00 00       	jmp    801040f1 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010403b:	8b 45 08             	mov    0x8(%ebp),%eax
8010403e:	8b 55 08             	mov    0x8(%ebp),%edx
80104041:	81 c2 34 02 00 00    	add    $0x234,%edx
80104047:	89 44 24 04          	mov    %eax,0x4(%esp)
8010404b:	89 14 24             	mov    %edx,(%esp)
8010404e:	e8 7a 09 00 00       	call   801049cd <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104053:	8b 45 08             	mov    0x8(%ebp),%eax
80104056:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
8010405c:	8b 45 08             	mov    0x8(%ebp),%eax
8010405f:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104065:	39 c2                	cmp    %eax,%edx
80104067:	75 0d                	jne    80104076 <piperead+0x71>
80104069:	8b 45 08             	mov    0x8(%ebp),%eax
8010406c:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104072:	85 c0                	test   %eax,%eax
80104074:	75 a3                	jne    80104019 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104076:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010407d:	eb 49                	jmp    801040c8 <piperead+0xc3>
    if(p->nread == p->nwrite)
8010407f:	8b 45 08             	mov    0x8(%ebp),%eax
80104082:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104088:	8b 45 08             	mov    0x8(%ebp),%eax
8010408b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104091:	39 c2                	cmp    %eax,%edx
80104093:	74 3d                	je     801040d2 <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104095:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104098:	89 c2                	mov    %eax,%edx
8010409a:	03 55 0c             	add    0xc(%ebp),%edx
8010409d:	8b 45 08             	mov    0x8(%ebp),%eax
801040a0:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801040a6:	89 c3                	mov    %eax,%ebx
801040a8:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
801040ae:	8b 4d 08             	mov    0x8(%ebp),%ecx
801040b1:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
801040b6:	88 0a                	mov    %cl,(%edx)
801040b8:	8d 50 01             	lea    0x1(%eax),%edx
801040bb:	8b 45 08             	mov    0x8(%ebp),%eax
801040be:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801040c4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801040c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040cb:	3b 45 10             	cmp    0x10(%ebp),%eax
801040ce:	7c af                	jl     8010407f <piperead+0x7a>
801040d0:	eb 01                	jmp    801040d3 <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
801040d2:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801040d3:	8b 45 08             	mov    0x8(%ebp),%eax
801040d6:	05 38 02 00 00       	add    $0x238,%eax
801040db:	89 04 24             	mov    %eax,(%esp)
801040de:	e8 c3 09 00 00       	call   80104aa6 <wakeup>
  release(&p->lock);
801040e3:	8b 45 08             	mov    0x8(%ebp),%eax
801040e6:	89 04 24             	mov    %eax,(%esp)
801040e9:	e8 1f 0c 00 00       	call   80104d0d <release>
  return i;
801040ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801040f1:	83 c4 24             	add    $0x24,%esp
801040f4:	5b                   	pop    %ebx
801040f5:	5d                   	pop    %ebp
801040f6:	c3                   	ret    
	...

801040f8 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801040f8:	55                   	push   %ebp
801040f9:	89 e5                	mov    %esp,%ebp
801040fb:	53                   	push   %ebx
801040fc:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801040ff:	9c                   	pushf  
80104100:	5b                   	pop    %ebx
80104101:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104104:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104107:	83 c4 10             	add    $0x10,%esp
8010410a:	5b                   	pop    %ebx
8010410b:	5d                   	pop    %ebp
8010410c:	c3                   	ret    

8010410d <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
8010410d:	55                   	push   %ebp
8010410e:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104110:	fb                   	sti    
}
80104111:	5d                   	pop    %ebp
80104112:	c3                   	ret    

80104113 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104113:	55                   	push   %ebp
80104114:	89 e5                	mov    %esp,%ebp
80104116:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104119:	c7 44 24 04 75 85 10 	movl   $0x80108575,0x4(%esp)
80104120:	80 
80104121:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104128:	e8 5d 0b 00 00       	call   80104c8a <initlock>
}
8010412d:	c9                   	leave  
8010412e:	c3                   	ret    

8010412f <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
8010412f:	55                   	push   %ebp
80104130:	89 e5                	mov    %esp,%ebp
80104132:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104135:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
8010413c:	e8 6a 0b 00 00       	call   80104cab <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104141:	c7 45 f4 74 04 11 80 	movl   $0x80110474,-0xc(%ebp)
80104148:	eb 0e                	jmp    80104158 <allocproc+0x29>
    if(p->state == UNUSED)
8010414a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010414d:	8b 40 0c             	mov    0xc(%eax),%eax
80104150:	85 c0                	test   %eax,%eax
80104152:	74 23                	je     80104177 <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104154:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104158:	81 7d f4 74 23 11 80 	cmpl   $0x80112374,-0xc(%ebp)
8010415f:	72 e9                	jb     8010414a <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104161:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104168:	e8 a0 0b 00 00       	call   80104d0d <release>
  return 0;
8010416d:	b8 00 00 00 00       	mov    $0x0,%eax
80104172:	e9 b5 00 00 00       	jmp    8010422c <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
80104177:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104178:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010417b:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104182:	a1 04 b0 10 80       	mov    0x8010b004,%eax
80104187:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010418a:	89 42 10             	mov    %eax,0x10(%edx)
8010418d:	83 c0 01             	add    $0x1,%eax
80104190:	a3 04 b0 10 80       	mov    %eax,0x8010b004
  release(&ptable.lock);
80104195:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
8010419c:	e8 6c 0b 00 00       	call   80104d0d <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801041a1:	e8 61 ea ff ff       	call   80102c07 <kalloc>
801041a6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041a9:	89 42 08             	mov    %eax,0x8(%edx)
801041ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041af:	8b 40 08             	mov    0x8(%eax),%eax
801041b2:	85 c0                	test   %eax,%eax
801041b4:	75 11                	jne    801041c7 <allocproc+0x98>
    p->state = UNUSED;
801041b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041b9:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801041c0:	b8 00 00 00 00       	mov    $0x0,%eax
801041c5:	eb 65                	jmp    8010422c <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
801041c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041ca:	8b 40 08             	mov    0x8(%eax),%eax
801041cd:	05 00 10 00 00       	add    $0x1000,%eax
801041d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
801041d5:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
801041d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041dc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801041df:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
801041e2:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
801041e6:	ba 54 63 10 80       	mov    $0x80106354,%edx
801041eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041ee:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
801041f0:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
801041f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041f7:	8b 55 f0             	mov    -0x10(%ebp),%edx
801041fa:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
801041fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104200:	8b 40 1c             	mov    0x1c(%eax),%eax
80104203:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
8010420a:	00 
8010420b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104212:	00 
80104213:	89 04 24             	mov    %eax,(%esp)
80104216:	e8 df 0c 00 00       	call   80104efa <memset>
  p->context->eip = (uint)forkret;
8010421b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010421e:	8b 40 1c             	mov    0x1c(%eax),%eax
80104221:	ba a1 49 10 80       	mov    $0x801049a1,%edx
80104226:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104229:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010422c:	c9                   	leave  
8010422d:	c3                   	ret    

8010422e <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
8010422e:	55                   	push   %ebp
8010422f:	89 e5                	mov    %esp,%ebp
80104231:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104234:	e8 f6 fe ff ff       	call   8010412f <allocproc>
80104239:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
8010423c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010423f:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm(kalloc)) == 0)
80104244:	c7 04 24 07 2c 10 80 	movl   $0x80102c07,(%esp)
8010424b:	e8 01 38 00 00       	call   80107a51 <setupkvm>
80104250:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104253:	89 42 04             	mov    %eax,0x4(%edx)
80104256:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104259:	8b 40 04             	mov    0x4(%eax),%eax
8010425c:	85 c0                	test   %eax,%eax
8010425e:	75 0c                	jne    8010426c <userinit+0x3e>
    panic("userinit: out of memory?");
80104260:	c7 04 24 7c 85 10 80 	movl   $0x8010857c,(%esp)
80104267:	e8 d1 c2 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
8010426c:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104271:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104274:	8b 40 04             	mov    0x4(%eax),%eax
80104277:	89 54 24 08          	mov    %edx,0x8(%esp)
8010427b:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
80104282:	80 
80104283:	89 04 24             	mov    %eax,(%esp)
80104286:	e8 1e 3a 00 00       	call   80107ca9 <inituvm>
  p->sz = PGSIZE;
8010428b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010428e:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104294:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104297:	8b 40 18             	mov    0x18(%eax),%eax
8010429a:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
801042a1:	00 
801042a2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801042a9:	00 
801042aa:	89 04 24             	mov    %eax,(%esp)
801042ad:	e8 48 0c 00 00       	call   80104efa <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801042b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042b5:	8b 40 18             	mov    0x18(%eax),%eax
801042b8:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801042be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042c1:	8b 40 18             	mov    0x18(%eax),%eax
801042c4:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
801042ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042cd:	8b 40 18             	mov    0x18(%eax),%eax
801042d0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042d3:	8b 52 18             	mov    0x18(%edx),%edx
801042d6:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801042da:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801042de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042e1:	8b 40 18             	mov    0x18(%eax),%eax
801042e4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042e7:	8b 52 18             	mov    0x18(%edx),%edx
801042ea:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801042ee:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801042f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042f5:	8b 40 18             	mov    0x18(%eax),%eax
801042f8:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801042ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104302:	8b 40 18             	mov    0x18(%eax),%eax
80104305:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
8010430c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010430f:	8b 40 18             	mov    0x18(%eax),%eax
80104312:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104319:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010431c:	83 c0 6c             	add    $0x6c,%eax
8010431f:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104326:	00 
80104327:	c7 44 24 04 95 85 10 	movl   $0x80108595,0x4(%esp)
8010432e:	80 
8010432f:	89 04 24             	mov    %eax,(%esp)
80104332:	e8 f3 0d 00 00       	call   8010512a <safestrcpy>
  p->cwd = namei("/");
80104337:	c7 04 24 9e 85 10 80 	movl   $0x8010859e,(%esp)
8010433e:	e8 cf e1 ff ff       	call   80102512 <namei>
80104343:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104346:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80104349:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010434c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104353:	c9                   	leave  
80104354:	c3                   	ret    

80104355 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104355:	55                   	push   %ebp
80104356:	89 e5                	mov    %esp,%ebp
80104358:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
8010435b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104361:	8b 00                	mov    (%eax),%eax
80104363:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104366:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010436a:	7e 34                	jle    801043a0 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
8010436c:	8b 45 08             	mov    0x8(%ebp),%eax
8010436f:	89 c2                	mov    %eax,%edx
80104371:	03 55 f4             	add    -0xc(%ebp),%edx
80104374:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010437a:	8b 40 04             	mov    0x4(%eax),%eax
8010437d:	89 54 24 08          	mov    %edx,0x8(%esp)
80104381:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104384:	89 54 24 04          	mov    %edx,0x4(%esp)
80104388:	89 04 24             	mov    %eax,(%esp)
8010438b:	e8 93 3a 00 00       	call   80107e23 <allocuvm>
80104390:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104393:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104397:	75 41                	jne    801043da <growproc+0x85>
      return -1;
80104399:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010439e:	eb 58                	jmp    801043f8 <growproc+0xa3>
  } else if(n < 0){
801043a0:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801043a4:	79 34                	jns    801043da <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801043a6:	8b 45 08             	mov    0x8(%ebp),%eax
801043a9:	89 c2                	mov    %eax,%edx
801043ab:	03 55 f4             	add    -0xc(%ebp),%edx
801043ae:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043b4:	8b 40 04             	mov    0x4(%eax),%eax
801043b7:	89 54 24 08          	mov    %edx,0x8(%esp)
801043bb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043be:	89 54 24 04          	mov    %edx,0x4(%esp)
801043c2:	89 04 24             	mov    %eax,(%esp)
801043c5:	e8 33 3b 00 00       	call   80107efd <deallocuvm>
801043ca:	89 45 f4             	mov    %eax,-0xc(%ebp)
801043cd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801043d1:	75 07                	jne    801043da <growproc+0x85>
      return -1;
801043d3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043d8:	eb 1e                	jmp    801043f8 <growproc+0xa3>
  }
  proc->sz = sz;
801043da:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043e0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043e3:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
801043e5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043eb:	89 04 24             	mov    %eax,(%esp)
801043ee:	e8 4f 37 00 00       	call   80107b42 <switchuvm>
  return 0;
801043f3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801043f8:	c9                   	leave  
801043f9:	c3                   	ret    

801043fa <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
801043fa:	55                   	push   %ebp
801043fb:	89 e5                	mov    %esp,%ebp
801043fd:	57                   	push   %edi
801043fe:	56                   	push   %esi
801043ff:	53                   	push   %ebx
80104400:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104403:	e8 27 fd ff ff       	call   8010412f <allocproc>
80104408:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010440b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010440f:	75 0a                	jne    8010441b <fork+0x21>
    return -1;
80104411:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104416:	e9 3a 01 00 00       	jmp    80104555 <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
8010441b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104421:	8b 10                	mov    (%eax),%edx
80104423:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104429:	8b 40 04             	mov    0x4(%eax),%eax
8010442c:	89 54 24 04          	mov    %edx,0x4(%esp)
80104430:	89 04 24             	mov    %eax,(%esp)
80104433:	e8 55 3c 00 00       	call   8010808d <copyuvm>
80104438:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010443b:	89 42 04             	mov    %eax,0x4(%edx)
8010443e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104441:	8b 40 04             	mov    0x4(%eax),%eax
80104444:	85 c0                	test   %eax,%eax
80104446:	75 2c                	jne    80104474 <fork+0x7a>
    kfree(np->kstack);
80104448:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010444b:	8b 40 08             	mov    0x8(%eax),%eax
8010444e:	89 04 24             	mov    %eax,(%esp)
80104451:	e8 18 e7 ff ff       	call   80102b6e <kfree>
    np->kstack = 0;
80104456:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104459:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104460:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104463:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
8010446a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010446f:	e9 e1 00 00 00       	jmp    80104555 <fork+0x15b>
  }
  np->sz = proc->sz;
80104474:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010447a:	8b 10                	mov    (%eax),%edx
8010447c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010447f:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104481:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104488:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010448b:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
8010448e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104491:	8b 50 18             	mov    0x18(%eax),%edx
80104494:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010449a:	8b 40 18             	mov    0x18(%eax),%eax
8010449d:	89 c3                	mov    %eax,%ebx
8010449f:	b8 13 00 00 00       	mov    $0x13,%eax
801044a4:	89 d7                	mov    %edx,%edi
801044a6:	89 de                	mov    %ebx,%esi
801044a8:	89 c1                	mov    %eax,%ecx
801044aa:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
801044ac:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044af:	8b 40 18             	mov    0x18(%eax),%eax
801044b2:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801044b9:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801044c0:	eb 3d                	jmp    801044ff <fork+0x105>
    if(proc->ofile[i])
801044c2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044c8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801044cb:	83 c2 08             	add    $0x8,%edx
801044ce:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801044d2:	85 c0                	test   %eax,%eax
801044d4:	74 25                	je     801044fb <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
801044d6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044dc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801044df:	83 c2 08             	add    $0x8,%edx
801044e2:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801044e6:	89 04 24             	mov    %eax,(%esp)
801044e9:	e8 96 cb ff ff       	call   80101084 <filedup>
801044ee:	8b 55 e0             	mov    -0x20(%ebp),%edx
801044f1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801044f4:	83 c1 08             	add    $0x8,%ecx
801044f7:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
801044fb:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801044ff:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104503:	7e bd                	jle    801044c2 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104505:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010450b:	8b 40 68             	mov    0x68(%eax),%eax
8010450e:	89 04 24             	mov    %eax,(%esp)
80104511:	e8 28 d4 ff ff       	call   8010193e <idup>
80104516:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104519:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
8010451c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010451f:	8b 40 10             	mov    0x10(%eax),%eax
80104522:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80104525:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104528:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
8010452f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104535:	8d 50 6c             	lea    0x6c(%eax),%edx
80104538:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010453b:	83 c0 6c             	add    $0x6c,%eax
8010453e:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104545:	00 
80104546:	89 54 24 04          	mov    %edx,0x4(%esp)
8010454a:	89 04 24             	mov    %eax,(%esp)
8010454d:	e8 d8 0b 00 00       	call   8010512a <safestrcpy>
  return pid;
80104552:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104555:	83 c4 2c             	add    $0x2c,%esp
80104558:	5b                   	pop    %ebx
80104559:	5e                   	pop    %esi
8010455a:	5f                   	pop    %edi
8010455b:	5d                   	pop    %ebp
8010455c:	c3                   	ret    

8010455d <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
8010455d:	55                   	push   %ebp
8010455e:	89 e5                	mov    %esp,%ebp
80104560:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104563:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010456a:	a1 48 b6 10 80       	mov    0x8010b648,%eax
8010456f:	39 c2                	cmp    %eax,%edx
80104571:	75 0c                	jne    8010457f <exit+0x22>
    panic("init exiting");
80104573:	c7 04 24 a0 85 10 80 	movl   $0x801085a0,(%esp)
8010457a:	e8 be bf ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010457f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104586:	eb 44                	jmp    801045cc <exit+0x6f>
    if(proc->ofile[fd]){
80104588:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010458e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104591:	83 c2 08             	add    $0x8,%edx
80104594:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104598:	85 c0                	test   %eax,%eax
8010459a:	74 2c                	je     801045c8 <exit+0x6b>
      fileclose(proc->ofile[fd]);
8010459c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045a2:	8b 55 f0             	mov    -0x10(%ebp),%edx
801045a5:	83 c2 08             	add    $0x8,%edx
801045a8:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801045ac:	89 04 24             	mov    %eax,(%esp)
801045af:	e8 18 cb ff ff       	call   801010cc <fileclose>
      proc->ofile[fd] = 0;
801045b4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045ba:	8b 55 f0             	mov    -0x10(%ebp),%edx
801045bd:	83 c2 08             	add    $0x8,%edx
801045c0:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801045c7:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801045c8:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801045cc:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
801045d0:	7e b6                	jle    80104588 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
801045d2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045d8:	8b 40 68             	mov    0x68(%eax),%eax
801045db:	89 04 24             	mov    %eax,(%esp)
801045de:	e8 40 d5 ff ff       	call   80101b23 <iput>
  proc->cwd = 0;
801045e3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045e9:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
801045f0:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801045f7:	e8 af 06 00 00       	call   80104cab <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
801045fc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104602:	8b 40 14             	mov    0x14(%eax),%eax
80104605:	89 04 24             	mov    %eax,(%esp)
80104608:	e8 5b 04 00 00       	call   80104a68 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010460d:	c7 45 f4 74 04 11 80 	movl   $0x80110474,-0xc(%ebp)
80104614:	eb 38                	jmp    8010464e <exit+0xf1>
    if(p->parent == proc){
80104616:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104619:	8b 50 14             	mov    0x14(%eax),%edx
8010461c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104622:	39 c2                	cmp    %eax,%edx
80104624:	75 24                	jne    8010464a <exit+0xed>
      p->parent = initproc;
80104626:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
8010462c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010462f:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104632:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104635:	8b 40 0c             	mov    0xc(%eax),%eax
80104638:	83 f8 05             	cmp    $0x5,%eax
8010463b:	75 0d                	jne    8010464a <exit+0xed>
        wakeup1(initproc);
8010463d:	a1 48 b6 10 80       	mov    0x8010b648,%eax
80104642:	89 04 24             	mov    %eax,(%esp)
80104645:	e8 1e 04 00 00       	call   80104a68 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010464a:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010464e:	81 7d f4 74 23 11 80 	cmpl   $0x80112374,-0xc(%ebp)
80104655:	72 bf                	jb     80104616 <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80104657:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010465d:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80104664:	e8 54 02 00 00       	call   801048bd <sched>
  panic("zombie exit");
80104669:	c7 04 24 ad 85 10 80 	movl   $0x801085ad,(%esp)
80104670:	e8 c8 be ff ff       	call   8010053d <panic>

80104675 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80104675:	55                   	push   %ebp
80104676:	89 e5                	mov    %esp,%ebp
80104678:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
8010467b:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104682:	e8 24 06 00 00       	call   80104cab <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80104687:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010468e:	c7 45 f4 74 04 11 80 	movl   $0x80110474,-0xc(%ebp)
80104695:	e9 9a 00 00 00       	jmp    80104734 <wait+0xbf>
      if(p->parent != proc)
8010469a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010469d:	8b 50 14             	mov    0x14(%eax),%edx
801046a0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046a6:	39 c2                	cmp    %eax,%edx
801046a8:	0f 85 81 00 00 00    	jne    8010472f <wait+0xba>
        continue;
      havekids = 1;
801046ae:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
801046b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046b8:	8b 40 0c             	mov    0xc(%eax),%eax
801046bb:	83 f8 05             	cmp    $0x5,%eax
801046be:	75 70                	jne    80104730 <wait+0xbb>
        // Found one.
        pid = p->pid;
801046c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046c3:	8b 40 10             	mov    0x10(%eax),%eax
801046c6:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
801046c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046cc:	8b 40 08             	mov    0x8(%eax),%eax
801046cf:	89 04 24             	mov    %eax,(%esp)
801046d2:	e8 97 e4 ff ff       	call   80102b6e <kfree>
        p->kstack = 0;
801046d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046da:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
801046e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046e4:	8b 40 04             	mov    0x4(%eax),%eax
801046e7:	89 04 24             	mov    %eax,(%esp)
801046ea:	e8 ca 38 00 00       	call   80107fb9 <freevm>
        p->state = UNUSED;
801046ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046f2:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
801046f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046fc:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104703:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104706:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
8010470d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104710:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80104714:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104717:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
8010471e:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104725:	e8 e3 05 00 00       	call   80104d0d <release>
        return pid;
8010472a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010472d:	eb 53                	jmp    80104782 <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
8010472f:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104730:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104734:	81 7d f4 74 23 11 80 	cmpl   $0x80112374,-0xc(%ebp)
8010473b:	0f 82 59 ff ff ff    	jb     8010469a <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104741:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104745:	74 0d                	je     80104754 <wait+0xdf>
80104747:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010474d:	8b 40 24             	mov    0x24(%eax),%eax
80104750:	85 c0                	test   %eax,%eax
80104752:	74 13                	je     80104767 <wait+0xf2>
      release(&ptable.lock);
80104754:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
8010475b:	e8 ad 05 00 00       	call   80104d0d <release>
      return -1;
80104760:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104765:	eb 1b                	jmp    80104782 <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104767:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010476d:	c7 44 24 04 40 04 11 	movl   $0x80110440,0x4(%esp)
80104774:	80 
80104775:	89 04 24             	mov    %eax,(%esp)
80104778:	e8 50 02 00 00       	call   801049cd <sleep>
  }
8010477d:	e9 05 ff ff ff       	jmp    80104687 <wait+0x12>
}
80104782:	c9                   	leave  
80104783:	c3                   	ret    

80104784 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
80104784:	55                   	push   %ebp
80104785:	89 e5                	mov    %esp,%ebp
80104787:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
8010478a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104790:	8b 40 18             	mov    0x18(%eax),%eax
80104793:	8b 40 44             	mov    0x44(%eax),%eax
80104796:	89 c2                	mov    %eax,%edx
80104798:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010479e:	8b 40 04             	mov    0x4(%eax),%eax
801047a1:	89 54 24 04          	mov    %edx,0x4(%esp)
801047a5:	89 04 24             	mov    %eax,(%esp)
801047a8:	e8 f1 39 00 00       	call   8010819e <uva2ka>
801047ad:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
801047b0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047b6:	8b 40 18             	mov    0x18(%eax),%eax
801047b9:	8b 40 44             	mov    0x44(%eax),%eax
801047bc:	25 ff 0f 00 00       	and    $0xfff,%eax
801047c1:	85 c0                	test   %eax,%eax
801047c3:	75 0c                	jne    801047d1 <register_handler+0x4d>
    panic("esp_offset == 0");
801047c5:	c7 04 24 b9 85 10 80 	movl   $0x801085b9,(%esp)
801047cc:	e8 6c bd ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
801047d1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047d7:	8b 40 18             	mov    0x18(%eax),%eax
801047da:	8b 40 44             	mov    0x44(%eax),%eax
801047dd:	83 e8 04             	sub    $0x4,%eax
801047e0:	25 ff 0f 00 00       	and    $0xfff,%eax
801047e5:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
801047e8:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801047ef:	8b 52 18             	mov    0x18(%edx),%edx
801047f2:	8b 52 38             	mov    0x38(%edx),%edx
801047f5:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
801047f7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047fd:	8b 40 18             	mov    0x18(%eax),%eax
80104800:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104807:	8b 52 18             	mov    0x18(%edx),%edx
8010480a:	8b 52 44             	mov    0x44(%edx),%edx
8010480d:	83 ea 04             	sub    $0x4,%edx
80104810:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
80104813:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104819:	8b 40 18             	mov    0x18(%eax),%eax
8010481c:	8b 55 08             	mov    0x8(%ebp),%edx
8010481f:	89 50 38             	mov    %edx,0x38(%eax)
}
80104822:	c9                   	leave  
80104823:	c3                   	ret    

80104824 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104824:	55                   	push   %ebp
80104825:	89 e5                	mov    %esp,%ebp
80104827:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
8010482a:	e8 de f8 ff ff       	call   8010410d <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
8010482f:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104836:	e8 70 04 00 00       	call   80104cab <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010483b:	c7 45 f4 74 04 11 80 	movl   $0x80110474,-0xc(%ebp)
80104842:	eb 5f                	jmp    801048a3 <scheduler+0x7f>
      if(p->state != RUNNABLE)
80104844:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104847:	8b 40 0c             	mov    0xc(%eax),%eax
8010484a:	83 f8 03             	cmp    $0x3,%eax
8010484d:	75 4f                	jne    8010489e <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
8010484f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104852:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104858:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010485b:	89 04 24             	mov    %eax,(%esp)
8010485e:	e8 df 32 00 00       	call   80107b42 <switchuvm>
      p->state = RUNNING;
80104863:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104866:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
8010486d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104873:	8b 40 1c             	mov    0x1c(%eax),%eax
80104876:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010487d:	83 c2 04             	add    $0x4,%edx
80104880:	89 44 24 04          	mov    %eax,0x4(%esp)
80104884:	89 14 24             	mov    %edx,(%esp)
80104887:	e8 14 09 00 00       	call   801051a0 <swtch>
      switchkvm();
8010488c:	e8 94 32 00 00       	call   80107b25 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104891:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104898:	00 00 00 00 
8010489c:	eb 01                	jmp    8010489f <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
8010489e:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010489f:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801048a3:	81 7d f4 74 23 11 80 	cmpl   $0x80112374,-0xc(%ebp)
801048aa:	72 98                	jb     80104844 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
801048ac:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801048b3:	e8 55 04 00 00       	call   80104d0d <release>

  }
801048b8:	e9 6d ff ff ff       	jmp    8010482a <scheduler+0x6>

801048bd <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
801048bd:	55                   	push   %ebp
801048be:	89 e5                	mov    %esp,%ebp
801048c0:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
801048c3:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801048ca:	e8 fa 04 00 00       	call   80104dc9 <holding>
801048cf:	85 c0                	test   %eax,%eax
801048d1:	75 0c                	jne    801048df <sched+0x22>
    panic("sched ptable.lock");
801048d3:	c7 04 24 c9 85 10 80 	movl   $0x801085c9,(%esp)
801048da:	e8 5e bc ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
801048df:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801048e5:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801048eb:	83 f8 01             	cmp    $0x1,%eax
801048ee:	74 0c                	je     801048fc <sched+0x3f>
    panic("sched locks");
801048f0:	c7 04 24 db 85 10 80 	movl   $0x801085db,(%esp)
801048f7:	e8 41 bc ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
801048fc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104902:	8b 40 0c             	mov    0xc(%eax),%eax
80104905:	83 f8 04             	cmp    $0x4,%eax
80104908:	75 0c                	jne    80104916 <sched+0x59>
    panic("sched running");
8010490a:	c7 04 24 e7 85 10 80 	movl   $0x801085e7,(%esp)
80104911:	e8 27 bc ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
80104916:	e8 dd f7 ff ff       	call   801040f8 <readeflags>
8010491b:	25 00 02 00 00       	and    $0x200,%eax
80104920:	85 c0                	test   %eax,%eax
80104922:	74 0c                	je     80104930 <sched+0x73>
    panic("sched interruptible");
80104924:	c7 04 24 f5 85 10 80 	movl   $0x801085f5,(%esp)
8010492b:	e8 0d bc ff ff       	call   8010053d <panic>
  intena = cpu->intena;
80104930:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104936:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
8010493c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
8010493f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104945:	8b 40 04             	mov    0x4(%eax),%eax
80104948:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010494f:	83 c2 1c             	add    $0x1c,%edx
80104952:	89 44 24 04          	mov    %eax,0x4(%esp)
80104956:	89 14 24             	mov    %edx,(%esp)
80104959:	e8 42 08 00 00       	call   801051a0 <swtch>
  cpu->intena = intena;
8010495e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104964:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104967:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
8010496d:	c9                   	leave  
8010496e:	c3                   	ret    

8010496f <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
8010496f:	55                   	push   %ebp
80104970:	89 e5                	mov    %esp,%ebp
80104972:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104975:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
8010497c:	e8 2a 03 00 00       	call   80104cab <acquire>
  proc->state = RUNNABLE;
80104981:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104987:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
8010498e:	e8 2a ff ff ff       	call   801048bd <sched>
  release(&ptable.lock);
80104993:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
8010499a:	e8 6e 03 00 00       	call   80104d0d <release>
}
8010499f:	c9                   	leave  
801049a0:	c3                   	ret    

801049a1 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
801049a1:	55                   	push   %ebp
801049a2:	89 e5                	mov    %esp,%ebp
801049a4:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
801049a7:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801049ae:	e8 5a 03 00 00       	call   80104d0d <release>

  if (first) {
801049b3:	a1 20 b0 10 80       	mov    0x8010b020,%eax
801049b8:	85 c0                	test   %eax,%eax
801049ba:	74 0f                	je     801049cb <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
801049bc:	c7 05 20 b0 10 80 00 	movl   $0x0,0x8010b020
801049c3:	00 00 00 
    initlog();
801049c6:	e8 4d e7 ff ff       	call   80103118 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
801049cb:	c9                   	leave  
801049cc:	c3                   	ret    

801049cd <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
801049cd:	55                   	push   %ebp
801049ce:	89 e5                	mov    %esp,%ebp
801049d0:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
801049d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049d9:	85 c0                	test   %eax,%eax
801049db:	75 0c                	jne    801049e9 <sleep+0x1c>
    panic("sleep");
801049dd:	c7 04 24 09 86 10 80 	movl   $0x80108609,(%esp)
801049e4:	e8 54 bb ff ff       	call   8010053d <panic>

  if(lk == 0)
801049e9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801049ed:	75 0c                	jne    801049fb <sleep+0x2e>
    panic("sleep without lk");
801049ef:	c7 04 24 0f 86 10 80 	movl   $0x8010860f,(%esp)
801049f6:	e8 42 bb ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
801049fb:	81 7d 0c 40 04 11 80 	cmpl   $0x80110440,0xc(%ebp)
80104a02:	74 17                	je     80104a1b <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104a04:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104a0b:	e8 9b 02 00 00       	call   80104cab <acquire>
    release(lk);
80104a10:	8b 45 0c             	mov    0xc(%ebp),%eax
80104a13:	89 04 24             	mov    %eax,(%esp)
80104a16:	e8 f2 02 00 00       	call   80104d0d <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104a1b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a21:	8b 55 08             	mov    0x8(%ebp),%edx
80104a24:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104a27:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a2d:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80104a34:	e8 84 fe ff ff       	call   801048bd <sched>

  // Tidy up.
  proc->chan = 0;
80104a39:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a3f:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104a46:	81 7d 0c 40 04 11 80 	cmpl   $0x80110440,0xc(%ebp)
80104a4d:	74 17                	je     80104a66 <sleep+0x99>
    release(&ptable.lock);
80104a4f:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104a56:	e8 b2 02 00 00       	call   80104d0d <release>
    acquire(lk);
80104a5b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104a5e:	89 04 24             	mov    %eax,(%esp)
80104a61:	e8 45 02 00 00       	call   80104cab <acquire>
  }
}
80104a66:	c9                   	leave  
80104a67:	c3                   	ret    

80104a68 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104a68:	55                   	push   %ebp
80104a69:	89 e5                	mov    %esp,%ebp
80104a6b:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104a6e:	c7 45 fc 74 04 11 80 	movl   $0x80110474,-0x4(%ebp)
80104a75:	eb 24                	jmp    80104a9b <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80104a77:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104a7a:	8b 40 0c             	mov    0xc(%eax),%eax
80104a7d:	83 f8 02             	cmp    $0x2,%eax
80104a80:	75 15                	jne    80104a97 <wakeup1+0x2f>
80104a82:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104a85:	8b 40 20             	mov    0x20(%eax),%eax
80104a88:	3b 45 08             	cmp    0x8(%ebp),%eax
80104a8b:	75 0a                	jne    80104a97 <wakeup1+0x2f>
      p->state = RUNNABLE;
80104a8d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104a90:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104a97:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80104a9b:	81 7d fc 74 23 11 80 	cmpl   $0x80112374,-0x4(%ebp)
80104aa2:	72 d3                	jb     80104a77 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104aa4:	c9                   	leave  
80104aa5:	c3                   	ret    

80104aa6 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104aa6:	55                   	push   %ebp
80104aa7:	89 e5                	mov    %esp,%ebp
80104aa9:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104aac:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104ab3:	e8 f3 01 00 00       	call   80104cab <acquire>
  wakeup1(chan);
80104ab8:	8b 45 08             	mov    0x8(%ebp),%eax
80104abb:	89 04 24             	mov    %eax,(%esp)
80104abe:	e8 a5 ff ff ff       	call   80104a68 <wakeup1>
  release(&ptable.lock);
80104ac3:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104aca:	e8 3e 02 00 00       	call   80104d0d <release>
}
80104acf:	c9                   	leave  
80104ad0:	c3                   	ret    

80104ad1 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104ad1:	55                   	push   %ebp
80104ad2:	89 e5                	mov    %esp,%ebp
80104ad4:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104ad7:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104ade:	e8 c8 01 00 00       	call   80104cab <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ae3:	c7 45 f4 74 04 11 80 	movl   $0x80110474,-0xc(%ebp)
80104aea:	eb 41                	jmp    80104b2d <kill+0x5c>
    if(p->pid == pid){
80104aec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aef:	8b 40 10             	mov    0x10(%eax),%eax
80104af2:	3b 45 08             	cmp    0x8(%ebp),%eax
80104af5:	75 32                	jne    80104b29 <kill+0x58>
      p->killed = 1;
80104af7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104afa:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104b01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b04:	8b 40 0c             	mov    0xc(%eax),%eax
80104b07:	83 f8 02             	cmp    $0x2,%eax
80104b0a:	75 0a                	jne    80104b16 <kill+0x45>
        p->state = RUNNABLE;
80104b0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b0f:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104b16:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104b1d:	e8 eb 01 00 00       	call   80104d0d <release>
      return 0;
80104b22:	b8 00 00 00 00       	mov    $0x0,%eax
80104b27:	eb 1e                	jmp    80104b47 <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b29:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104b2d:	81 7d f4 74 23 11 80 	cmpl   $0x80112374,-0xc(%ebp)
80104b34:	72 b6                	jb     80104aec <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104b36:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104b3d:	e8 cb 01 00 00       	call   80104d0d <release>
  return -1;
80104b42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104b47:	c9                   	leave  
80104b48:	c3                   	ret    

80104b49 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104b49:	55                   	push   %ebp
80104b4a:	89 e5                	mov    %esp,%ebp
80104b4c:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b4f:	c7 45 f0 74 04 11 80 	movl   $0x80110474,-0x10(%ebp)
80104b56:	e9 d8 00 00 00       	jmp    80104c33 <procdump+0xea>
    if(p->state == UNUSED)
80104b5b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b5e:	8b 40 0c             	mov    0xc(%eax),%eax
80104b61:	85 c0                	test   %eax,%eax
80104b63:	0f 84 c5 00 00 00    	je     80104c2e <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104b69:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b6c:	8b 40 0c             	mov    0xc(%eax),%eax
80104b6f:	83 f8 05             	cmp    $0x5,%eax
80104b72:	77 23                	ja     80104b97 <procdump+0x4e>
80104b74:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b77:	8b 40 0c             	mov    0xc(%eax),%eax
80104b7a:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104b81:	85 c0                	test   %eax,%eax
80104b83:	74 12                	je     80104b97 <procdump+0x4e>
      state = states[p->state];
80104b85:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b88:	8b 40 0c             	mov    0xc(%eax),%eax
80104b8b:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104b92:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104b95:	eb 07                	jmp    80104b9e <procdump+0x55>
    else
      state = "???";
80104b97:	c7 45 ec 20 86 10 80 	movl   $0x80108620,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104b9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ba1:	8d 50 6c             	lea    0x6c(%eax),%edx
80104ba4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ba7:	8b 40 10             	mov    0x10(%eax),%eax
80104baa:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104bae:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104bb1:	89 54 24 08          	mov    %edx,0x8(%esp)
80104bb5:	89 44 24 04          	mov    %eax,0x4(%esp)
80104bb9:	c7 04 24 24 86 10 80 	movl   $0x80108624,(%esp)
80104bc0:	e8 dc b7 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80104bc5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bc8:	8b 40 0c             	mov    0xc(%eax),%eax
80104bcb:	83 f8 02             	cmp    $0x2,%eax
80104bce:	75 50                	jne    80104c20 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104bd0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bd3:	8b 40 1c             	mov    0x1c(%eax),%eax
80104bd6:	8b 40 0c             	mov    0xc(%eax),%eax
80104bd9:	83 c0 08             	add    $0x8,%eax
80104bdc:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104bdf:	89 54 24 04          	mov    %edx,0x4(%esp)
80104be3:	89 04 24             	mov    %eax,(%esp)
80104be6:	e8 71 01 00 00       	call   80104d5c <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104beb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104bf2:	eb 1b                	jmp    80104c0f <procdump+0xc6>
        cprintf(" %p", pc[i]);
80104bf4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bf7:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104bfb:	89 44 24 04          	mov    %eax,0x4(%esp)
80104bff:	c7 04 24 2d 86 10 80 	movl   $0x8010862d,(%esp)
80104c06:	e8 96 b7 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104c0b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104c0f:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104c13:	7f 0b                	jg     80104c20 <procdump+0xd7>
80104c15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c18:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104c1c:	85 c0                	test   %eax,%eax
80104c1e:	75 d4                	jne    80104bf4 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104c20:	c7 04 24 31 86 10 80 	movl   $0x80108631,(%esp)
80104c27:	e8 75 b7 ff ff       	call   801003a1 <cprintf>
80104c2c:	eb 01                	jmp    80104c2f <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80104c2e:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104c2f:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104c33:	81 7d f0 74 23 11 80 	cmpl   $0x80112374,-0x10(%ebp)
80104c3a:	0f 82 1b ff ff ff    	jb     80104b5b <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104c40:	c9                   	leave  
80104c41:	c3                   	ret    
	...

80104c44 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104c44:	55                   	push   %ebp
80104c45:	89 e5                	mov    %esp,%ebp
80104c47:	53                   	push   %ebx
80104c48:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104c4b:	9c                   	pushf  
80104c4c:	5b                   	pop    %ebx
80104c4d:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104c50:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104c53:	83 c4 10             	add    $0x10,%esp
80104c56:	5b                   	pop    %ebx
80104c57:	5d                   	pop    %ebp
80104c58:	c3                   	ret    

80104c59 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80104c59:	55                   	push   %ebp
80104c5a:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104c5c:	fa                   	cli    
}
80104c5d:	5d                   	pop    %ebp
80104c5e:	c3                   	ret    

80104c5f <sti>:

static inline void
sti(void)
{
80104c5f:	55                   	push   %ebp
80104c60:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104c62:	fb                   	sti    
}
80104c63:	5d                   	pop    %ebp
80104c64:	c3                   	ret    

80104c65 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104c65:	55                   	push   %ebp
80104c66:	89 e5                	mov    %esp,%ebp
80104c68:	53                   	push   %ebx
80104c69:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80104c6c:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104c6f:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80104c72:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104c75:	89 c3                	mov    %eax,%ebx
80104c77:	89 d8                	mov    %ebx,%eax
80104c79:	f0 87 02             	lock xchg %eax,(%edx)
80104c7c:	89 c3                	mov    %eax,%ebx
80104c7e:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104c81:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104c84:	83 c4 10             	add    $0x10,%esp
80104c87:	5b                   	pop    %ebx
80104c88:	5d                   	pop    %ebp
80104c89:	c3                   	ret    

80104c8a <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104c8a:	55                   	push   %ebp
80104c8b:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104c8d:	8b 45 08             	mov    0x8(%ebp),%eax
80104c90:	8b 55 0c             	mov    0xc(%ebp),%edx
80104c93:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104c96:	8b 45 08             	mov    0x8(%ebp),%eax
80104c99:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104c9f:	8b 45 08             	mov    0x8(%ebp),%eax
80104ca2:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104ca9:	5d                   	pop    %ebp
80104caa:	c3                   	ret    

80104cab <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104cab:	55                   	push   %ebp
80104cac:	89 e5                	mov    %esp,%ebp
80104cae:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104cb1:	e8 3d 01 00 00       	call   80104df3 <pushcli>
  if(holding(lk))
80104cb6:	8b 45 08             	mov    0x8(%ebp),%eax
80104cb9:	89 04 24             	mov    %eax,(%esp)
80104cbc:	e8 08 01 00 00       	call   80104dc9 <holding>
80104cc1:	85 c0                	test   %eax,%eax
80104cc3:	74 0c                	je     80104cd1 <acquire+0x26>
    panic("acquire");
80104cc5:	c7 04 24 5d 86 10 80 	movl   $0x8010865d,(%esp)
80104ccc:	e8 6c b8 ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80104cd1:	90                   	nop
80104cd2:	8b 45 08             	mov    0x8(%ebp),%eax
80104cd5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80104cdc:	00 
80104cdd:	89 04 24             	mov    %eax,(%esp)
80104ce0:	e8 80 ff ff ff       	call   80104c65 <xchg>
80104ce5:	85 c0                	test   %eax,%eax
80104ce7:	75 e9                	jne    80104cd2 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80104ce9:	8b 45 08             	mov    0x8(%ebp),%eax
80104cec:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104cf3:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80104cf6:	8b 45 08             	mov    0x8(%ebp),%eax
80104cf9:	83 c0 0c             	add    $0xc,%eax
80104cfc:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d00:	8d 45 08             	lea    0x8(%ebp),%eax
80104d03:	89 04 24             	mov    %eax,(%esp)
80104d06:	e8 51 00 00 00       	call   80104d5c <getcallerpcs>
}
80104d0b:	c9                   	leave  
80104d0c:	c3                   	ret    

80104d0d <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80104d0d:	55                   	push   %ebp
80104d0e:	89 e5                	mov    %esp,%ebp
80104d10:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80104d13:	8b 45 08             	mov    0x8(%ebp),%eax
80104d16:	89 04 24             	mov    %eax,(%esp)
80104d19:	e8 ab 00 00 00       	call   80104dc9 <holding>
80104d1e:	85 c0                	test   %eax,%eax
80104d20:	75 0c                	jne    80104d2e <release+0x21>
    panic("release");
80104d22:	c7 04 24 65 86 10 80 	movl   $0x80108665,(%esp)
80104d29:	e8 0f b8 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80104d2e:	8b 45 08             	mov    0x8(%ebp),%eax
80104d31:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80104d38:	8b 45 08             	mov    0x8(%ebp),%eax
80104d3b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80104d42:	8b 45 08             	mov    0x8(%ebp),%eax
80104d45:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104d4c:	00 
80104d4d:	89 04 24             	mov    %eax,(%esp)
80104d50:	e8 10 ff ff ff       	call   80104c65 <xchg>

  popcli();
80104d55:	e8 e1 00 00 00       	call   80104e3b <popcli>
}
80104d5a:	c9                   	leave  
80104d5b:	c3                   	ret    

80104d5c <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80104d5c:	55                   	push   %ebp
80104d5d:	89 e5                	mov    %esp,%ebp
80104d5f:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80104d62:	8b 45 08             	mov    0x8(%ebp),%eax
80104d65:	83 e8 08             	sub    $0x8,%eax
80104d68:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80104d6b:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80104d72:	eb 32                	jmp    80104da6 <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80104d74:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80104d78:	74 47                	je     80104dc1 <getcallerpcs+0x65>
80104d7a:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80104d81:	76 3e                	jbe    80104dc1 <getcallerpcs+0x65>
80104d83:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80104d87:	74 38                	je     80104dc1 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80104d89:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104d8c:	c1 e0 02             	shl    $0x2,%eax
80104d8f:	03 45 0c             	add    0xc(%ebp),%eax
80104d92:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104d95:	8b 52 04             	mov    0x4(%edx),%edx
80104d98:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80104d9a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104d9d:	8b 00                	mov    (%eax),%eax
80104d9f:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80104da2:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104da6:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104daa:	7e c8                	jle    80104d74 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104dac:	eb 13                	jmp    80104dc1 <getcallerpcs+0x65>
    pcs[i] = 0;
80104dae:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104db1:	c1 e0 02             	shl    $0x2,%eax
80104db4:	03 45 0c             	add    0xc(%ebp),%eax
80104db7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104dbd:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104dc1:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104dc5:	7e e7                	jle    80104dae <getcallerpcs+0x52>
    pcs[i] = 0;
}
80104dc7:	c9                   	leave  
80104dc8:	c3                   	ret    

80104dc9 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80104dc9:	55                   	push   %ebp
80104dca:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80104dcc:	8b 45 08             	mov    0x8(%ebp),%eax
80104dcf:	8b 00                	mov    (%eax),%eax
80104dd1:	85 c0                	test   %eax,%eax
80104dd3:	74 17                	je     80104dec <holding+0x23>
80104dd5:	8b 45 08             	mov    0x8(%ebp),%eax
80104dd8:	8b 50 08             	mov    0x8(%eax),%edx
80104ddb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104de1:	39 c2                	cmp    %eax,%edx
80104de3:	75 07                	jne    80104dec <holding+0x23>
80104de5:	b8 01 00 00 00       	mov    $0x1,%eax
80104dea:	eb 05                	jmp    80104df1 <holding+0x28>
80104dec:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104df1:	5d                   	pop    %ebp
80104df2:	c3                   	ret    

80104df3 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80104df3:	55                   	push   %ebp
80104df4:	89 e5                	mov    %esp,%ebp
80104df6:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80104df9:	e8 46 fe ff ff       	call   80104c44 <readeflags>
80104dfe:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80104e01:	e8 53 fe ff ff       	call   80104c59 <cli>
  if(cpu->ncli++ == 0)
80104e06:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e0c:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104e12:	85 d2                	test   %edx,%edx
80104e14:	0f 94 c1             	sete   %cl
80104e17:	83 c2 01             	add    $0x1,%edx
80104e1a:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104e20:	84 c9                	test   %cl,%cl
80104e22:	74 15                	je     80104e39 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80104e24:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e2a:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104e2d:	81 e2 00 02 00 00    	and    $0x200,%edx
80104e33:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104e39:	c9                   	leave  
80104e3a:	c3                   	ret    

80104e3b <popcli>:

void
popcli(void)
{
80104e3b:	55                   	push   %ebp
80104e3c:	89 e5                	mov    %esp,%ebp
80104e3e:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80104e41:	e8 fe fd ff ff       	call   80104c44 <readeflags>
80104e46:	25 00 02 00 00       	and    $0x200,%eax
80104e4b:	85 c0                	test   %eax,%eax
80104e4d:	74 0c                	je     80104e5b <popcli+0x20>
    panic("popcli - interruptible");
80104e4f:	c7 04 24 6d 86 10 80 	movl   $0x8010866d,(%esp)
80104e56:	e8 e2 b6 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80104e5b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e61:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104e67:	83 ea 01             	sub    $0x1,%edx
80104e6a:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104e70:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104e76:	85 c0                	test   %eax,%eax
80104e78:	79 0c                	jns    80104e86 <popcli+0x4b>
    panic("popcli");
80104e7a:	c7 04 24 84 86 10 80 	movl   $0x80108684,(%esp)
80104e81:	e8 b7 b6 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80104e86:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e8c:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104e92:	85 c0                	test   %eax,%eax
80104e94:	75 15                	jne    80104eab <popcli+0x70>
80104e96:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e9c:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104ea2:	85 c0                	test   %eax,%eax
80104ea4:	74 05                	je     80104eab <popcli+0x70>
    sti();
80104ea6:	e8 b4 fd ff ff       	call   80104c5f <sti>
}
80104eab:	c9                   	leave  
80104eac:	c3                   	ret    
80104ead:	00 00                	add    %al,(%eax)
	...

80104eb0 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80104eb0:	55                   	push   %ebp
80104eb1:	89 e5                	mov    %esp,%ebp
80104eb3:	57                   	push   %edi
80104eb4:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80104eb5:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104eb8:	8b 55 10             	mov    0x10(%ebp),%edx
80104ebb:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ebe:	89 cb                	mov    %ecx,%ebx
80104ec0:	89 df                	mov    %ebx,%edi
80104ec2:	89 d1                	mov    %edx,%ecx
80104ec4:	fc                   	cld    
80104ec5:	f3 aa                	rep stos %al,%es:(%edi)
80104ec7:	89 ca                	mov    %ecx,%edx
80104ec9:	89 fb                	mov    %edi,%ebx
80104ecb:	89 5d 08             	mov    %ebx,0x8(%ebp)
80104ece:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80104ed1:	5b                   	pop    %ebx
80104ed2:	5f                   	pop    %edi
80104ed3:	5d                   	pop    %ebp
80104ed4:	c3                   	ret    

80104ed5 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80104ed5:	55                   	push   %ebp
80104ed6:	89 e5                	mov    %esp,%ebp
80104ed8:	57                   	push   %edi
80104ed9:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80104eda:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104edd:	8b 55 10             	mov    0x10(%ebp),%edx
80104ee0:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ee3:	89 cb                	mov    %ecx,%ebx
80104ee5:	89 df                	mov    %ebx,%edi
80104ee7:	89 d1                	mov    %edx,%ecx
80104ee9:	fc                   	cld    
80104eea:	f3 ab                	rep stos %eax,%es:(%edi)
80104eec:	89 ca                	mov    %ecx,%edx
80104eee:	89 fb                	mov    %edi,%ebx
80104ef0:	89 5d 08             	mov    %ebx,0x8(%ebp)
80104ef3:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80104ef6:	5b                   	pop    %ebx
80104ef7:	5f                   	pop    %edi
80104ef8:	5d                   	pop    %ebp
80104ef9:	c3                   	ret    

80104efa <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80104efa:	55                   	push   %ebp
80104efb:	89 e5                	mov    %esp,%ebp
80104efd:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80104f00:	8b 45 08             	mov    0x8(%ebp),%eax
80104f03:	83 e0 03             	and    $0x3,%eax
80104f06:	85 c0                	test   %eax,%eax
80104f08:	75 49                	jne    80104f53 <memset+0x59>
80104f0a:	8b 45 10             	mov    0x10(%ebp),%eax
80104f0d:	83 e0 03             	and    $0x3,%eax
80104f10:	85 c0                	test   %eax,%eax
80104f12:	75 3f                	jne    80104f53 <memset+0x59>
    c &= 0xFF;
80104f14:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80104f1b:	8b 45 10             	mov    0x10(%ebp),%eax
80104f1e:	c1 e8 02             	shr    $0x2,%eax
80104f21:	89 c2                	mov    %eax,%edx
80104f23:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f26:	89 c1                	mov    %eax,%ecx
80104f28:	c1 e1 18             	shl    $0x18,%ecx
80104f2b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f2e:	c1 e0 10             	shl    $0x10,%eax
80104f31:	09 c1                	or     %eax,%ecx
80104f33:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f36:	c1 e0 08             	shl    $0x8,%eax
80104f39:	09 c8                	or     %ecx,%eax
80104f3b:	0b 45 0c             	or     0xc(%ebp),%eax
80104f3e:	89 54 24 08          	mov    %edx,0x8(%esp)
80104f42:	89 44 24 04          	mov    %eax,0x4(%esp)
80104f46:	8b 45 08             	mov    0x8(%ebp),%eax
80104f49:	89 04 24             	mov    %eax,(%esp)
80104f4c:	e8 84 ff ff ff       	call   80104ed5 <stosl>
80104f51:	eb 19                	jmp    80104f6c <memset+0x72>
  } else
    stosb(dst, c, n);
80104f53:	8b 45 10             	mov    0x10(%ebp),%eax
80104f56:	89 44 24 08          	mov    %eax,0x8(%esp)
80104f5a:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f5d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104f61:	8b 45 08             	mov    0x8(%ebp),%eax
80104f64:	89 04 24             	mov    %eax,(%esp)
80104f67:	e8 44 ff ff ff       	call   80104eb0 <stosb>
  return dst;
80104f6c:	8b 45 08             	mov    0x8(%ebp),%eax
}
80104f6f:	c9                   	leave  
80104f70:	c3                   	ret    

80104f71 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80104f71:	55                   	push   %ebp
80104f72:	89 e5                	mov    %esp,%ebp
80104f74:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80104f77:	8b 45 08             	mov    0x8(%ebp),%eax
80104f7a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80104f7d:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f80:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80104f83:	eb 32                	jmp    80104fb7 <memcmp+0x46>
    if(*s1 != *s2)
80104f85:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f88:	0f b6 10             	movzbl (%eax),%edx
80104f8b:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104f8e:	0f b6 00             	movzbl (%eax),%eax
80104f91:	38 c2                	cmp    %al,%dl
80104f93:	74 1a                	je     80104faf <memcmp+0x3e>
      return *s1 - *s2;
80104f95:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f98:	0f b6 00             	movzbl (%eax),%eax
80104f9b:	0f b6 d0             	movzbl %al,%edx
80104f9e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104fa1:	0f b6 00             	movzbl (%eax),%eax
80104fa4:	0f b6 c0             	movzbl %al,%eax
80104fa7:	89 d1                	mov    %edx,%ecx
80104fa9:	29 c1                	sub    %eax,%ecx
80104fab:	89 c8                	mov    %ecx,%eax
80104fad:	eb 1c                	jmp    80104fcb <memcmp+0x5a>
    s1++, s2++;
80104faf:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104fb3:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80104fb7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104fbb:	0f 95 c0             	setne  %al
80104fbe:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104fc2:	84 c0                	test   %al,%al
80104fc4:	75 bf                	jne    80104f85 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80104fc6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104fcb:	c9                   	leave  
80104fcc:	c3                   	ret    

80104fcd <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80104fcd:	55                   	push   %ebp
80104fce:	89 e5                	mov    %esp,%ebp
80104fd0:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80104fd3:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fd6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80104fd9:	8b 45 08             	mov    0x8(%ebp),%eax
80104fdc:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80104fdf:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104fe2:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80104fe5:	73 54                	jae    8010503b <memmove+0x6e>
80104fe7:	8b 45 10             	mov    0x10(%ebp),%eax
80104fea:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104fed:	01 d0                	add    %edx,%eax
80104fef:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80104ff2:	76 47                	jbe    8010503b <memmove+0x6e>
    s += n;
80104ff4:	8b 45 10             	mov    0x10(%ebp),%eax
80104ff7:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80104ffa:	8b 45 10             	mov    0x10(%ebp),%eax
80104ffd:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105000:	eb 13                	jmp    80105015 <memmove+0x48>
      *--d = *--s;
80105002:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105006:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
8010500a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010500d:	0f b6 10             	movzbl (%eax),%edx
80105010:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105013:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105015:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105019:	0f 95 c0             	setne  %al
8010501c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105020:	84 c0                	test   %al,%al
80105022:	75 de                	jne    80105002 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105024:	eb 25                	jmp    8010504b <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80105026:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105029:	0f b6 10             	movzbl (%eax),%edx
8010502c:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010502f:	88 10                	mov    %dl,(%eax)
80105031:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105035:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105039:	eb 01                	jmp    8010503c <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
8010503b:	90                   	nop
8010503c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105040:	0f 95 c0             	setne  %al
80105043:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105047:	84 c0                	test   %al,%al
80105049:	75 db                	jne    80105026 <memmove+0x59>
      *d++ = *s++;

  return dst;
8010504b:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010504e:	c9                   	leave  
8010504f:	c3                   	ret    

80105050 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105050:	55                   	push   %ebp
80105051:	89 e5                	mov    %esp,%ebp
80105053:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105056:	8b 45 10             	mov    0x10(%ebp),%eax
80105059:	89 44 24 08          	mov    %eax,0x8(%esp)
8010505d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105060:	89 44 24 04          	mov    %eax,0x4(%esp)
80105064:	8b 45 08             	mov    0x8(%ebp),%eax
80105067:	89 04 24             	mov    %eax,(%esp)
8010506a:	e8 5e ff ff ff       	call   80104fcd <memmove>
}
8010506f:	c9                   	leave  
80105070:	c3                   	ret    

80105071 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105071:	55                   	push   %ebp
80105072:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105074:	eb 0c                	jmp    80105082 <strncmp+0x11>
    n--, p++, q++;
80105076:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010507a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010507e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105082:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105086:	74 1a                	je     801050a2 <strncmp+0x31>
80105088:	8b 45 08             	mov    0x8(%ebp),%eax
8010508b:	0f b6 00             	movzbl (%eax),%eax
8010508e:	84 c0                	test   %al,%al
80105090:	74 10                	je     801050a2 <strncmp+0x31>
80105092:	8b 45 08             	mov    0x8(%ebp),%eax
80105095:	0f b6 10             	movzbl (%eax),%edx
80105098:	8b 45 0c             	mov    0xc(%ebp),%eax
8010509b:	0f b6 00             	movzbl (%eax),%eax
8010509e:	38 c2                	cmp    %al,%dl
801050a0:	74 d4                	je     80105076 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
801050a2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801050a6:	75 07                	jne    801050af <strncmp+0x3e>
    return 0;
801050a8:	b8 00 00 00 00       	mov    $0x0,%eax
801050ad:	eb 18                	jmp    801050c7 <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
801050af:	8b 45 08             	mov    0x8(%ebp),%eax
801050b2:	0f b6 00             	movzbl (%eax),%eax
801050b5:	0f b6 d0             	movzbl %al,%edx
801050b8:	8b 45 0c             	mov    0xc(%ebp),%eax
801050bb:	0f b6 00             	movzbl (%eax),%eax
801050be:	0f b6 c0             	movzbl %al,%eax
801050c1:	89 d1                	mov    %edx,%ecx
801050c3:	29 c1                	sub    %eax,%ecx
801050c5:	89 c8                	mov    %ecx,%eax
}
801050c7:	5d                   	pop    %ebp
801050c8:	c3                   	ret    

801050c9 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
801050c9:	55                   	push   %ebp
801050ca:	89 e5                	mov    %esp,%ebp
801050cc:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801050cf:	8b 45 08             	mov    0x8(%ebp),%eax
801050d2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
801050d5:	90                   	nop
801050d6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801050da:	0f 9f c0             	setg   %al
801050dd:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801050e1:	84 c0                	test   %al,%al
801050e3:	74 30                	je     80105115 <strncpy+0x4c>
801050e5:	8b 45 0c             	mov    0xc(%ebp),%eax
801050e8:	0f b6 10             	movzbl (%eax),%edx
801050eb:	8b 45 08             	mov    0x8(%ebp),%eax
801050ee:	88 10                	mov    %dl,(%eax)
801050f0:	8b 45 08             	mov    0x8(%ebp),%eax
801050f3:	0f b6 00             	movzbl (%eax),%eax
801050f6:	84 c0                	test   %al,%al
801050f8:	0f 95 c0             	setne  %al
801050fb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801050ff:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105103:	84 c0                	test   %al,%al
80105105:	75 cf                	jne    801050d6 <strncpy+0xd>
    ;
  while(n-- > 0)
80105107:	eb 0c                	jmp    80105115 <strncpy+0x4c>
    *s++ = 0;
80105109:	8b 45 08             	mov    0x8(%ebp),%eax
8010510c:	c6 00 00             	movb   $0x0,(%eax)
8010510f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105113:	eb 01                	jmp    80105116 <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105115:	90                   	nop
80105116:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010511a:	0f 9f c0             	setg   %al
8010511d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105121:	84 c0                	test   %al,%al
80105123:	75 e4                	jne    80105109 <strncpy+0x40>
    *s++ = 0;
  return os;
80105125:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105128:	c9                   	leave  
80105129:	c3                   	ret    

8010512a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010512a:	55                   	push   %ebp
8010512b:	89 e5                	mov    %esp,%ebp
8010512d:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105130:	8b 45 08             	mov    0x8(%ebp),%eax
80105133:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105136:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010513a:	7f 05                	jg     80105141 <safestrcpy+0x17>
    return os;
8010513c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010513f:	eb 35                	jmp    80105176 <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
80105141:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105145:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105149:	7e 22                	jle    8010516d <safestrcpy+0x43>
8010514b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010514e:	0f b6 10             	movzbl (%eax),%edx
80105151:	8b 45 08             	mov    0x8(%ebp),%eax
80105154:	88 10                	mov    %dl,(%eax)
80105156:	8b 45 08             	mov    0x8(%ebp),%eax
80105159:	0f b6 00             	movzbl (%eax),%eax
8010515c:	84 c0                	test   %al,%al
8010515e:	0f 95 c0             	setne  %al
80105161:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105165:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105169:	84 c0                	test   %al,%al
8010516b:	75 d4                	jne    80105141 <safestrcpy+0x17>
    ;
  *s = 0;
8010516d:	8b 45 08             	mov    0x8(%ebp),%eax
80105170:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105173:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105176:	c9                   	leave  
80105177:	c3                   	ret    

80105178 <strlen>:

int
strlen(const char *s)
{
80105178:	55                   	push   %ebp
80105179:	89 e5                	mov    %esp,%ebp
8010517b:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
8010517e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105185:	eb 04                	jmp    8010518b <strlen+0x13>
80105187:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010518b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010518e:	03 45 08             	add    0x8(%ebp),%eax
80105191:	0f b6 00             	movzbl (%eax),%eax
80105194:	84 c0                	test   %al,%al
80105196:	75 ef                	jne    80105187 <strlen+0xf>
    ;
  return n;
80105198:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010519b:	c9                   	leave  
8010519c:	c3                   	ret    
8010519d:	00 00                	add    %al,(%eax)
	...

801051a0 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
801051a0:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801051a4:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
801051a8:	55                   	push   %ebp
  pushl %ebx
801051a9:	53                   	push   %ebx
  pushl %esi
801051aa:	56                   	push   %esi
  pushl %edi
801051ab:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
801051ac:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
801051ae:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
801051b0:	5f                   	pop    %edi
  popl %esi
801051b1:	5e                   	pop    %esi
  popl %ebx
801051b2:	5b                   	pop    %ebx
  popl %ebp
801051b3:	5d                   	pop    %ebp
  ret
801051b4:	c3                   	ret    
801051b5:	00 00                	add    %al,(%eax)
	...

801051b8 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
801051b8:	55                   	push   %ebp
801051b9:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
801051bb:	8b 45 08             	mov    0x8(%ebp),%eax
801051be:	8b 00                	mov    (%eax),%eax
801051c0:	3b 45 0c             	cmp    0xc(%ebp),%eax
801051c3:	76 0f                	jbe    801051d4 <fetchint+0x1c>
801051c5:	8b 45 0c             	mov    0xc(%ebp),%eax
801051c8:	8d 50 04             	lea    0x4(%eax),%edx
801051cb:	8b 45 08             	mov    0x8(%ebp),%eax
801051ce:	8b 00                	mov    (%eax),%eax
801051d0:	39 c2                	cmp    %eax,%edx
801051d2:	76 07                	jbe    801051db <fetchint+0x23>
    return -1;
801051d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051d9:	eb 0f                	jmp    801051ea <fetchint+0x32>
  *ip = *(int*)(addr);
801051db:	8b 45 0c             	mov    0xc(%ebp),%eax
801051de:	8b 10                	mov    (%eax),%edx
801051e0:	8b 45 10             	mov    0x10(%ebp),%eax
801051e3:	89 10                	mov    %edx,(%eax)
  return 0;
801051e5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801051ea:	5d                   	pop    %ebp
801051eb:	c3                   	ret    

801051ec <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
801051ec:	55                   	push   %ebp
801051ed:	89 e5                	mov    %esp,%ebp
801051ef:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
801051f2:	8b 45 08             	mov    0x8(%ebp),%eax
801051f5:	8b 00                	mov    (%eax),%eax
801051f7:	3b 45 0c             	cmp    0xc(%ebp),%eax
801051fa:	77 07                	ja     80105203 <fetchstr+0x17>
    return -1;
801051fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105201:	eb 45                	jmp    80105248 <fetchstr+0x5c>
  *pp = (char*)addr;
80105203:	8b 55 0c             	mov    0xc(%ebp),%edx
80105206:	8b 45 10             	mov    0x10(%ebp),%eax
80105209:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
8010520b:	8b 45 08             	mov    0x8(%ebp),%eax
8010520e:	8b 00                	mov    (%eax),%eax
80105210:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105213:	8b 45 10             	mov    0x10(%ebp),%eax
80105216:	8b 00                	mov    (%eax),%eax
80105218:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010521b:	eb 1e                	jmp    8010523b <fetchstr+0x4f>
    if(*s == 0)
8010521d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105220:	0f b6 00             	movzbl (%eax),%eax
80105223:	84 c0                	test   %al,%al
80105225:	75 10                	jne    80105237 <fetchstr+0x4b>
      return s - *pp;
80105227:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010522a:	8b 45 10             	mov    0x10(%ebp),%eax
8010522d:	8b 00                	mov    (%eax),%eax
8010522f:	89 d1                	mov    %edx,%ecx
80105231:	29 c1                	sub    %eax,%ecx
80105233:	89 c8                	mov    %ecx,%eax
80105235:	eb 11                	jmp    80105248 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
80105237:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010523b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010523e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105241:	72 da                	jb     8010521d <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
80105243:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105248:	c9                   	leave  
80105249:	c3                   	ret    

8010524a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010524a:	55                   	push   %ebp
8010524b:	89 e5                	mov    %esp,%ebp
8010524d:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
80105250:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105256:	8b 40 18             	mov    0x18(%eax),%eax
80105259:	8b 50 44             	mov    0x44(%eax),%edx
8010525c:	8b 45 08             	mov    0x8(%ebp),%eax
8010525f:	c1 e0 02             	shl    $0x2,%eax
80105262:	01 d0                	add    %edx,%eax
80105264:	8d 48 04             	lea    0x4(%eax),%ecx
80105267:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010526d:	8b 55 0c             	mov    0xc(%ebp),%edx
80105270:	89 54 24 08          	mov    %edx,0x8(%esp)
80105274:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80105278:	89 04 24             	mov    %eax,(%esp)
8010527b:	e8 38 ff ff ff       	call   801051b8 <fetchint>
}
80105280:	c9                   	leave  
80105281:	c3                   	ret    

80105282 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105282:	55                   	push   %ebp
80105283:	89 e5                	mov    %esp,%ebp
80105285:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105288:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010528b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010528f:	8b 45 08             	mov    0x8(%ebp),%eax
80105292:	89 04 24             	mov    %eax,(%esp)
80105295:	e8 b0 ff ff ff       	call   8010524a <argint>
8010529a:	85 c0                	test   %eax,%eax
8010529c:	79 07                	jns    801052a5 <argptr+0x23>
    return -1;
8010529e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052a3:	eb 3d                	jmp    801052e2 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
801052a5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052a8:	89 c2                	mov    %eax,%edx
801052aa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052b0:	8b 00                	mov    (%eax),%eax
801052b2:	39 c2                	cmp    %eax,%edx
801052b4:	73 16                	jae    801052cc <argptr+0x4a>
801052b6:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052b9:	89 c2                	mov    %eax,%edx
801052bb:	8b 45 10             	mov    0x10(%ebp),%eax
801052be:	01 c2                	add    %eax,%edx
801052c0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052c6:	8b 00                	mov    (%eax),%eax
801052c8:	39 c2                	cmp    %eax,%edx
801052ca:	76 07                	jbe    801052d3 <argptr+0x51>
    return -1;
801052cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052d1:	eb 0f                	jmp    801052e2 <argptr+0x60>
  *pp = (char*)i;
801052d3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052d6:	89 c2                	mov    %eax,%edx
801052d8:	8b 45 0c             	mov    0xc(%ebp),%eax
801052db:	89 10                	mov    %edx,(%eax)
  return 0;
801052dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
801052e2:	c9                   	leave  
801052e3:	c3                   	ret    

801052e4 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
801052e4:	55                   	push   %ebp
801052e5:	89 e5                	mov    %esp,%ebp
801052e7:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
801052ea:	8d 45 fc             	lea    -0x4(%ebp),%eax
801052ed:	89 44 24 04          	mov    %eax,0x4(%esp)
801052f1:	8b 45 08             	mov    0x8(%ebp),%eax
801052f4:	89 04 24             	mov    %eax,(%esp)
801052f7:	e8 4e ff ff ff       	call   8010524a <argint>
801052fc:	85 c0                	test   %eax,%eax
801052fe:	79 07                	jns    80105307 <argstr+0x23>
    return -1;
80105300:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105305:	eb 1e                	jmp    80105325 <argstr+0x41>
  return fetchstr(proc, addr, pp);
80105307:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010530a:	89 c2                	mov    %eax,%edx
8010530c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105312:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105315:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105319:	89 54 24 04          	mov    %edx,0x4(%esp)
8010531d:	89 04 24             	mov    %eax,(%esp)
80105320:	e8 c7 fe ff ff       	call   801051ec <fetchstr>
}
80105325:	c9                   	leave  
80105326:	c3                   	ret    

80105327 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
80105327:	55                   	push   %ebp
80105328:	89 e5                	mov    %esp,%ebp
8010532a:	53                   	push   %ebx
8010532b:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
8010532e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105334:	8b 40 18             	mov    0x18(%eax),%eax
80105337:	8b 40 1c             	mov    0x1c(%eax),%eax
8010533a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
8010533d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105341:	78 2e                	js     80105371 <syscall+0x4a>
80105343:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80105347:	7f 28                	jg     80105371 <syscall+0x4a>
80105349:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010534c:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105353:	85 c0                	test   %eax,%eax
80105355:	74 1a                	je     80105371 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
80105357:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010535d:	8b 58 18             	mov    0x18(%eax),%ebx
80105360:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105363:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
8010536a:	ff d0                	call   *%eax
8010536c:	89 43 1c             	mov    %eax,0x1c(%ebx)
8010536f:	eb 73                	jmp    801053e4 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
80105371:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80105375:	7e 30                	jle    801053a7 <syscall+0x80>
80105377:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010537a:	83 f8 15             	cmp    $0x15,%eax
8010537d:	77 28                	ja     801053a7 <syscall+0x80>
8010537f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105382:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105389:	85 c0                	test   %eax,%eax
8010538b:	74 1a                	je     801053a7 <syscall+0x80>
    proc->tf->eax = syscalls[num]();
8010538d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105393:	8b 58 18             	mov    0x18(%eax),%ebx
80105396:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105399:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801053a0:	ff d0                	call   *%eax
801053a2:	89 43 1c             	mov    %eax,0x1c(%ebx)
801053a5:	eb 3d                	jmp    801053e4 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
801053a7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053ad:	8d 48 6c             	lea    0x6c(%eax),%ecx
801053b0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
801053b6:	8b 40 10             	mov    0x10(%eax),%eax
801053b9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801053bc:	89 54 24 0c          	mov    %edx,0xc(%esp)
801053c0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801053c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801053c8:	c7 04 24 8b 86 10 80 	movl   $0x8010868b,(%esp)
801053cf:	e8 cd af ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
801053d4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053da:	8b 40 18             	mov    0x18(%eax),%eax
801053dd:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
801053e4:	83 c4 24             	add    $0x24,%esp
801053e7:	5b                   	pop    %ebx
801053e8:	5d                   	pop    %ebp
801053e9:	c3                   	ret    
	...

801053ec <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801053ec:	55                   	push   %ebp
801053ed:	89 e5                	mov    %esp,%ebp
801053ef:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801053f2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801053f5:	89 44 24 04          	mov    %eax,0x4(%esp)
801053f9:	8b 45 08             	mov    0x8(%ebp),%eax
801053fc:	89 04 24             	mov    %eax,(%esp)
801053ff:	e8 46 fe ff ff       	call   8010524a <argint>
80105404:	85 c0                	test   %eax,%eax
80105406:	79 07                	jns    8010540f <argfd+0x23>
    return -1;
80105408:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010540d:	eb 50                	jmp    8010545f <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
8010540f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105412:	85 c0                	test   %eax,%eax
80105414:	78 21                	js     80105437 <argfd+0x4b>
80105416:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105419:	83 f8 0f             	cmp    $0xf,%eax
8010541c:	7f 19                	jg     80105437 <argfd+0x4b>
8010541e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105424:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105427:	83 c2 08             	add    $0x8,%edx
8010542a:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010542e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105431:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105435:	75 07                	jne    8010543e <argfd+0x52>
    return -1;
80105437:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010543c:	eb 21                	jmp    8010545f <argfd+0x73>
  if(pfd)
8010543e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105442:	74 08                	je     8010544c <argfd+0x60>
    *pfd = fd;
80105444:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105447:	8b 45 0c             	mov    0xc(%ebp),%eax
8010544a:	89 10                	mov    %edx,(%eax)
  if(pf)
8010544c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105450:	74 08                	je     8010545a <argfd+0x6e>
    *pf = f;
80105452:	8b 45 10             	mov    0x10(%ebp),%eax
80105455:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105458:	89 10                	mov    %edx,(%eax)
  return 0;
8010545a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010545f:	c9                   	leave  
80105460:	c3                   	ret    

80105461 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105461:	55                   	push   %ebp
80105462:	89 e5                	mov    %esp,%ebp
80105464:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105467:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010546e:	eb 30                	jmp    801054a0 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105470:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105476:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105479:	83 c2 08             	add    $0x8,%edx
8010547c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105480:	85 c0                	test   %eax,%eax
80105482:	75 18                	jne    8010549c <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105484:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010548a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010548d:	8d 4a 08             	lea    0x8(%edx),%ecx
80105490:	8b 55 08             	mov    0x8(%ebp),%edx
80105493:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105497:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010549a:	eb 0f                	jmp    801054ab <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
8010549c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801054a0:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
801054a4:	7e ca                	jle    80105470 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
801054a6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801054ab:	c9                   	leave  
801054ac:	c3                   	ret    

801054ad <sys_dup>:

int
sys_dup(void)
{
801054ad:	55                   	push   %ebp
801054ae:	89 e5                	mov    %esp,%ebp
801054b0:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
801054b3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801054b6:	89 44 24 08          	mov    %eax,0x8(%esp)
801054ba:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801054c1:	00 
801054c2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801054c9:	e8 1e ff ff ff       	call   801053ec <argfd>
801054ce:	85 c0                	test   %eax,%eax
801054d0:	79 07                	jns    801054d9 <sys_dup+0x2c>
    return -1;
801054d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054d7:	eb 29                	jmp    80105502 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
801054d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054dc:	89 04 24             	mov    %eax,(%esp)
801054df:	e8 7d ff ff ff       	call   80105461 <fdalloc>
801054e4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801054e7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801054eb:	79 07                	jns    801054f4 <sys_dup+0x47>
    return -1;
801054ed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054f2:	eb 0e                	jmp    80105502 <sys_dup+0x55>
  filedup(f);
801054f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054f7:	89 04 24             	mov    %eax,(%esp)
801054fa:	e8 85 bb ff ff       	call   80101084 <filedup>
  return fd;
801054ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105502:	c9                   	leave  
80105503:	c3                   	ret    

80105504 <sys_read>:

int
sys_read(void)
{
80105504:	55                   	push   %ebp
80105505:	89 e5                	mov    %esp,%ebp
80105507:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010550a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010550d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105511:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105518:	00 
80105519:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105520:	e8 c7 fe ff ff       	call   801053ec <argfd>
80105525:	85 c0                	test   %eax,%eax
80105527:	78 35                	js     8010555e <sys_read+0x5a>
80105529:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010552c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105530:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105537:	e8 0e fd ff ff       	call   8010524a <argint>
8010553c:	85 c0                	test   %eax,%eax
8010553e:	78 1e                	js     8010555e <sys_read+0x5a>
80105540:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105543:	89 44 24 08          	mov    %eax,0x8(%esp)
80105547:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010554a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010554e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105555:	e8 28 fd ff ff       	call   80105282 <argptr>
8010555a:	85 c0                	test   %eax,%eax
8010555c:	79 07                	jns    80105565 <sys_read+0x61>
    return -1;
8010555e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105563:	eb 19                	jmp    8010557e <sys_read+0x7a>
  return fileread(f, p, n);
80105565:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105568:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010556b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010556e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105572:	89 54 24 04          	mov    %edx,0x4(%esp)
80105576:	89 04 24             	mov    %eax,(%esp)
80105579:	e8 73 bc ff ff       	call   801011f1 <fileread>
}
8010557e:	c9                   	leave  
8010557f:	c3                   	ret    

80105580 <sys_write>:

int
sys_write(void)
{
80105580:	55                   	push   %ebp
80105581:	89 e5                	mov    %esp,%ebp
80105583:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105586:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105589:	89 44 24 08          	mov    %eax,0x8(%esp)
8010558d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105594:	00 
80105595:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010559c:	e8 4b fe ff ff       	call   801053ec <argfd>
801055a1:	85 c0                	test   %eax,%eax
801055a3:	78 35                	js     801055da <sys_write+0x5a>
801055a5:	8d 45 f0             	lea    -0x10(%ebp),%eax
801055a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801055ac:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801055b3:	e8 92 fc ff ff       	call   8010524a <argint>
801055b8:	85 c0                	test   %eax,%eax
801055ba:	78 1e                	js     801055da <sys_write+0x5a>
801055bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055bf:	89 44 24 08          	mov    %eax,0x8(%esp)
801055c3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801055c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801055ca:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801055d1:	e8 ac fc ff ff       	call   80105282 <argptr>
801055d6:	85 c0                	test   %eax,%eax
801055d8:	79 07                	jns    801055e1 <sys_write+0x61>
    return -1;
801055da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055df:	eb 19                	jmp    801055fa <sys_write+0x7a>
  return filewrite(f, p, n);
801055e1:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801055e4:	8b 55 ec             	mov    -0x14(%ebp),%edx
801055e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055ea:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801055ee:	89 54 24 04          	mov    %edx,0x4(%esp)
801055f2:	89 04 24             	mov    %eax,(%esp)
801055f5:	e8 b3 bc ff ff       	call   801012ad <filewrite>
}
801055fa:	c9                   	leave  
801055fb:	c3                   	ret    

801055fc <sys_close>:

int
sys_close(void)
{
801055fc:	55                   	push   %ebp
801055fd:	89 e5                	mov    %esp,%ebp
801055ff:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80105602:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105605:	89 44 24 08          	mov    %eax,0x8(%esp)
80105609:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010560c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105610:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105617:	e8 d0 fd ff ff       	call   801053ec <argfd>
8010561c:	85 c0                	test   %eax,%eax
8010561e:	79 07                	jns    80105627 <sys_close+0x2b>
    return -1;
80105620:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105625:	eb 24                	jmp    8010564b <sys_close+0x4f>
  proc->ofile[fd] = 0;
80105627:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010562d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105630:	83 c2 08             	add    $0x8,%edx
80105633:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010563a:	00 
  fileclose(f);
8010563b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010563e:	89 04 24             	mov    %eax,(%esp)
80105641:	e8 86 ba ff ff       	call   801010cc <fileclose>
  return 0;
80105646:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010564b:	c9                   	leave  
8010564c:	c3                   	ret    

8010564d <sys_fstat>:

int
sys_fstat(void)
{
8010564d:	55                   	push   %ebp
8010564e:	89 e5                	mov    %esp,%ebp
80105650:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80105653:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105656:	89 44 24 08          	mov    %eax,0x8(%esp)
8010565a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105661:	00 
80105662:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105669:	e8 7e fd ff ff       	call   801053ec <argfd>
8010566e:	85 c0                	test   %eax,%eax
80105670:	78 1f                	js     80105691 <sys_fstat+0x44>
80105672:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105679:	00 
8010567a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010567d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105681:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105688:	e8 f5 fb ff ff       	call   80105282 <argptr>
8010568d:	85 c0                	test   %eax,%eax
8010568f:	79 07                	jns    80105698 <sys_fstat+0x4b>
    return -1;
80105691:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105696:	eb 12                	jmp    801056aa <sys_fstat+0x5d>
  return filestat(f, st);
80105698:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010569b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010569e:	89 54 24 04          	mov    %edx,0x4(%esp)
801056a2:	89 04 24             	mov    %eax,(%esp)
801056a5:	e8 f8 ba ff ff       	call   801011a2 <filestat>
}
801056aa:	c9                   	leave  
801056ab:	c3                   	ret    

801056ac <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
801056ac:	55                   	push   %ebp
801056ad:	89 e5                	mov    %esp,%ebp
801056af:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801056b2:	8d 45 d8             	lea    -0x28(%ebp),%eax
801056b5:	89 44 24 04          	mov    %eax,0x4(%esp)
801056b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801056c0:	e8 1f fc ff ff       	call   801052e4 <argstr>
801056c5:	85 c0                	test   %eax,%eax
801056c7:	78 17                	js     801056e0 <sys_link+0x34>
801056c9:	8d 45 dc             	lea    -0x24(%ebp),%eax
801056cc:	89 44 24 04          	mov    %eax,0x4(%esp)
801056d0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801056d7:	e8 08 fc ff ff       	call   801052e4 <argstr>
801056dc:	85 c0                	test   %eax,%eax
801056de:	79 0a                	jns    801056ea <sys_link+0x3e>
    return -1;
801056e0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056e5:	e9 3c 01 00 00       	jmp    80105826 <sys_link+0x17a>
  if((ip = namei(old)) == 0)
801056ea:	8b 45 d8             	mov    -0x28(%ebp),%eax
801056ed:	89 04 24             	mov    %eax,(%esp)
801056f0:	e8 1d ce ff ff       	call   80102512 <namei>
801056f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801056f8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801056fc:	75 0a                	jne    80105708 <sys_link+0x5c>
    return -1;
801056fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105703:	e9 1e 01 00 00       	jmp    80105826 <sys_link+0x17a>

  begin_trans();
80105708:	e8 18 dc ff ff       	call   80103325 <begin_trans>

  ilock(ip);
8010570d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105710:	89 04 24             	mov    %eax,(%esp)
80105713:	e8 58 c2 ff ff       	call   80101970 <ilock>
  if(ip->type == T_DIR){
80105718:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010571b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010571f:	66 83 f8 01          	cmp    $0x1,%ax
80105723:	75 1a                	jne    8010573f <sys_link+0x93>
    iunlockput(ip);
80105725:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105728:	89 04 24             	mov    %eax,(%esp)
8010572b:	e8 c4 c4 ff ff       	call   80101bf4 <iunlockput>
    commit_trans();
80105730:	e8 39 dc ff ff       	call   8010336e <commit_trans>
    return -1;
80105735:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010573a:	e9 e7 00 00 00       	jmp    80105826 <sys_link+0x17a>
  }

  ip->nlink++;
8010573f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105742:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105746:	8d 50 01             	lea    0x1(%eax),%edx
80105749:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010574c:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105750:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105753:	89 04 24             	mov    %eax,(%esp)
80105756:	e8 59 c0 ff ff       	call   801017b4 <iupdate>
  iunlock(ip);
8010575b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010575e:	89 04 24             	mov    %eax,(%esp)
80105761:	e8 58 c3 ff ff       	call   80101abe <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80105766:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105769:	8d 55 e2             	lea    -0x1e(%ebp),%edx
8010576c:	89 54 24 04          	mov    %edx,0x4(%esp)
80105770:	89 04 24             	mov    %eax,(%esp)
80105773:	e8 bc cd ff ff       	call   80102534 <nameiparent>
80105778:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010577b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010577f:	74 68                	je     801057e9 <sys_link+0x13d>
    goto bad;
  ilock(dp);
80105781:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105784:	89 04 24             	mov    %eax,(%esp)
80105787:	e8 e4 c1 ff ff       	call   80101970 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
8010578c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010578f:	8b 10                	mov    (%eax),%edx
80105791:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105794:	8b 00                	mov    (%eax),%eax
80105796:	39 c2                	cmp    %eax,%edx
80105798:	75 20                	jne    801057ba <sys_link+0x10e>
8010579a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010579d:	8b 40 04             	mov    0x4(%eax),%eax
801057a0:	89 44 24 08          	mov    %eax,0x8(%esp)
801057a4:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801057a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801057ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057ae:	89 04 24             	mov    %eax,(%esp)
801057b1:	e8 9b ca ff ff       	call   80102251 <dirlink>
801057b6:	85 c0                	test   %eax,%eax
801057b8:	79 0d                	jns    801057c7 <sys_link+0x11b>
    iunlockput(dp);
801057ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057bd:	89 04 24             	mov    %eax,(%esp)
801057c0:	e8 2f c4 ff ff       	call   80101bf4 <iunlockput>
    goto bad;
801057c5:	eb 23                	jmp    801057ea <sys_link+0x13e>
  }
  iunlockput(dp);
801057c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057ca:	89 04 24             	mov    %eax,(%esp)
801057cd:	e8 22 c4 ff ff       	call   80101bf4 <iunlockput>
  iput(ip);
801057d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057d5:	89 04 24             	mov    %eax,(%esp)
801057d8:	e8 46 c3 ff ff       	call   80101b23 <iput>

  commit_trans();
801057dd:	e8 8c db ff ff       	call   8010336e <commit_trans>

  return 0;
801057e2:	b8 00 00 00 00       	mov    $0x0,%eax
801057e7:	eb 3d                	jmp    80105826 <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
801057e9:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
801057ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057ed:	89 04 24             	mov    %eax,(%esp)
801057f0:	e8 7b c1 ff ff       	call   80101970 <ilock>
  ip->nlink--;
801057f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057f8:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801057fc:	8d 50 ff             	lea    -0x1(%eax),%edx
801057ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105802:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105806:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105809:	89 04 24             	mov    %eax,(%esp)
8010580c:	e8 a3 bf ff ff       	call   801017b4 <iupdate>
  iunlockput(ip);
80105811:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105814:	89 04 24             	mov    %eax,(%esp)
80105817:	e8 d8 c3 ff ff       	call   80101bf4 <iunlockput>
  commit_trans();
8010581c:	e8 4d db ff ff       	call   8010336e <commit_trans>
  return -1;
80105821:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105826:	c9                   	leave  
80105827:	c3                   	ret    

80105828 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105828:	55                   	push   %ebp
80105829:	89 e5                	mov    %esp,%ebp
8010582b:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010582e:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105835:	eb 4b                	jmp    80105882 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105837:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010583a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105841:	00 
80105842:	89 44 24 08          	mov    %eax,0x8(%esp)
80105846:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105849:	89 44 24 04          	mov    %eax,0x4(%esp)
8010584d:	8b 45 08             	mov    0x8(%ebp),%eax
80105850:	89 04 24             	mov    %eax,(%esp)
80105853:	e8 0e c6 ff ff       	call   80101e66 <readi>
80105858:	83 f8 10             	cmp    $0x10,%eax
8010585b:	74 0c                	je     80105869 <isdirempty+0x41>
      panic("isdirempty: readi");
8010585d:	c7 04 24 a7 86 10 80 	movl   $0x801086a7,(%esp)
80105864:	e8 d4 ac ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80105869:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
8010586d:	66 85 c0             	test   %ax,%ax
80105870:	74 07                	je     80105879 <isdirempty+0x51>
      return 0;
80105872:	b8 00 00 00 00       	mov    $0x0,%eax
80105877:	eb 1b                	jmp    80105894 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105879:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010587c:	83 c0 10             	add    $0x10,%eax
8010587f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105882:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105885:	8b 45 08             	mov    0x8(%ebp),%eax
80105888:	8b 40 18             	mov    0x18(%eax),%eax
8010588b:	39 c2                	cmp    %eax,%edx
8010588d:	72 a8                	jb     80105837 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
8010588f:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105894:	c9                   	leave  
80105895:	c3                   	ret    

80105896 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105896:	55                   	push   %ebp
80105897:	89 e5                	mov    %esp,%ebp
80105899:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
8010589c:	8d 45 cc             	lea    -0x34(%ebp),%eax
8010589f:	89 44 24 04          	mov    %eax,0x4(%esp)
801058a3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801058aa:	e8 35 fa ff ff       	call   801052e4 <argstr>
801058af:	85 c0                	test   %eax,%eax
801058b1:	79 0a                	jns    801058bd <sys_unlink+0x27>
    return -1;
801058b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801058b8:	e9 aa 01 00 00       	jmp    80105a67 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
801058bd:	8b 45 cc             	mov    -0x34(%ebp),%eax
801058c0:	8d 55 d2             	lea    -0x2e(%ebp),%edx
801058c3:	89 54 24 04          	mov    %edx,0x4(%esp)
801058c7:	89 04 24             	mov    %eax,(%esp)
801058ca:	e8 65 cc ff ff       	call   80102534 <nameiparent>
801058cf:	89 45 f4             	mov    %eax,-0xc(%ebp)
801058d2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801058d6:	75 0a                	jne    801058e2 <sys_unlink+0x4c>
    return -1;
801058d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801058dd:	e9 85 01 00 00       	jmp    80105a67 <sys_unlink+0x1d1>

  begin_trans();
801058e2:	e8 3e da ff ff       	call   80103325 <begin_trans>

  ilock(dp);
801058e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058ea:	89 04 24             	mov    %eax,(%esp)
801058ed:	e8 7e c0 ff ff       	call   80101970 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801058f2:	c7 44 24 04 b9 86 10 	movl   $0x801086b9,0x4(%esp)
801058f9:	80 
801058fa:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801058fd:	89 04 24             	mov    %eax,(%esp)
80105900:	e8 62 c8 ff ff       	call   80102167 <namecmp>
80105905:	85 c0                	test   %eax,%eax
80105907:	0f 84 45 01 00 00    	je     80105a52 <sys_unlink+0x1bc>
8010590d:	c7 44 24 04 bb 86 10 	movl   $0x801086bb,0x4(%esp)
80105914:	80 
80105915:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105918:	89 04 24             	mov    %eax,(%esp)
8010591b:	e8 47 c8 ff ff       	call   80102167 <namecmp>
80105920:	85 c0                	test   %eax,%eax
80105922:	0f 84 2a 01 00 00    	je     80105a52 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105928:	8d 45 c8             	lea    -0x38(%ebp),%eax
8010592b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010592f:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105932:	89 44 24 04          	mov    %eax,0x4(%esp)
80105936:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105939:	89 04 24             	mov    %eax,(%esp)
8010593c:	e8 48 c8 ff ff       	call   80102189 <dirlookup>
80105941:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105944:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105948:	0f 84 03 01 00 00    	je     80105a51 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
8010594e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105951:	89 04 24             	mov    %eax,(%esp)
80105954:	e8 17 c0 ff ff       	call   80101970 <ilock>

  if(ip->nlink < 1)
80105959:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010595c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105960:	66 85 c0             	test   %ax,%ax
80105963:	7f 0c                	jg     80105971 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80105965:	c7 04 24 be 86 10 80 	movl   $0x801086be,(%esp)
8010596c:	e8 cc ab ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105971:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105974:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105978:	66 83 f8 01          	cmp    $0x1,%ax
8010597c:	75 1f                	jne    8010599d <sys_unlink+0x107>
8010597e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105981:	89 04 24             	mov    %eax,(%esp)
80105984:	e8 9f fe ff ff       	call   80105828 <isdirempty>
80105989:	85 c0                	test   %eax,%eax
8010598b:	75 10                	jne    8010599d <sys_unlink+0x107>
    iunlockput(ip);
8010598d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105990:	89 04 24             	mov    %eax,(%esp)
80105993:	e8 5c c2 ff ff       	call   80101bf4 <iunlockput>
    goto bad;
80105998:	e9 b5 00 00 00       	jmp    80105a52 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
8010599d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801059a4:	00 
801059a5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801059ac:	00 
801059ad:	8d 45 e0             	lea    -0x20(%ebp),%eax
801059b0:	89 04 24             	mov    %eax,(%esp)
801059b3:	e8 42 f5 ff ff       	call   80104efa <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801059b8:	8b 45 c8             	mov    -0x38(%ebp),%eax
801059bb:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801059c2:	00 
801059c3:	89 44 24 08          	mov    %eax,0x8(%esp)
801059c7:	8d 45 e0             	lea    -0x20(%ebp),%eax
801059ca:	89 44 24 04          	mov    %eax,0x4(%esp)
801059ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059d1:	89 04 24             	mov    %eax,(%esp)
801059d4:	e8 f8 c5 ff ff       	call   80101fd1 <writei>
801059d9:	83 f8 10             	cmp    $0x10,%eax
801059dc:	74 0c                	je     801059ea <sys_unlink+0x154>
    panic("unlink: writei");
801059de:	c7 04 24 d0 86 10 80 	movl   $0x801086d0,(%esp)
801059e5:	e8 53 ab ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
801059ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059ed:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801059f1:	66 83 f8 01          	cmp    $0x1,%ax
801059f5:	75 1c                	jne    80105a13 <sys_unlink+0x17d>
    dp->nlink--;
801059f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059fa:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801059fe:	8d 50 ff             	lea    -0x1(%eax),%edx
80105a01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a04:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105a08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a0b:	89 04 24             	mov    %eax,(%esp)
80105a0e:	e8 a1 bd ff ff       	call   801017b4 <iupdate>
  }
  iunlockput(dp);
80105a13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a16:	89 04 24             	mov    %eax,(%esp)
80105a19:	e8 d6 c1 ff ff       	call   80101bf4 <iunlockput>

  ip->nlink--;
80105a1e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a21:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105a25:	8d 50 ff             	lea    -0x1(%eax),%edx
80105a28:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a2b:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105a2f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a32:	89 04 24             	mov    %eax,(%esp)
80105a35:	e8 7a bd ff ff       	call   801017b4 <iupdate>
  iunlockput(ip);
80105a3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a3d:	89 04 24             	mov    %eax,(%esp)
80105a40:	e8 af c1 ff ff       	call   80101bf4 <iunlockput>

  commit_trans();
80105a45:	e8 24 d9 ff ff       	call   8010336e <commit_trans>

  return 0;
80105a4a:	b8 00 00 00 00       	mov    $0x0,%eax
80105a4f:	eb 16                	jmp    80105a67 <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80105a51:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80105a52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a55:	89 04 24             	mov    %eax,(%esp)
80105a58:	e8 97 c1 ff ff       	call   80101bf4 <iunlockput>
  commit_trans();
80105a5d:	e8 0c d9 ff ff       	call   8010336e <commit_trans>
  return -1;
80105a62:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105a67:	c9                   	leave  
80105a68:	c3                   	ret    

80105a69 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105a69:	55                   	push   %ebp
80105a6a:	89 e5                	mov    %esp,%ebp
80105a6c:	83 ec 48             	sub    $0x48,%esp
80105a6f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105a72:	8b 55 10             	mov    0x10(%ebp),%edx
80105a75:	8b 45 14             	mov    0x14(%ebp),%eax
80105a78:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105a7c:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105a80:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105a84:	8d 45 de             	lea    -0x22(%ebp),%eax
80105a87:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a8b:	8b 45 08             	mov    0x8(%ebp),%eax
80105a8e:	89 04 24             	mov    %eax,(%esp)
80105a91:	e8 9e ca ff ff       	call   80102534 <nameiparent>
80105a96:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105a99:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105a9d:	75 0a                	jne    80105aa9 <create+0x40>
    return 0;
80105a9f:	b8 00 00 00 00       	mov    $0x0,%eax
80105aa4:	e9 7e 01 00 00       	jmp    80105c27 <create+0x1be>
  ilock(dp);
80105aa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105aac:	89 04 24             	mov    %eax,(%esp)
80105aaf:	e8 bc be ff ff       	call   80101970 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80105ab4:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105ab7:	89 44 24 08          	mov    %eax,0x8(%esp)
80105abb:	8d 45 de             	lea    -0x22(%ebp),%eax
80105abe:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ac2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ac5:	89 04 24             	mov    %eax,(%esp)
80105ac8:	e8 bc c6 ff ff       	call   80102189 <dirlookup>
80105acd:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105ad0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105ad4:	74 47                	je     80105b1d <create+0xb4>
    iunlockput(dp);
80105ad6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ad9:	89 04 24             	mov    %eax,(%esp)
80105adc:	e8 13 c1 ff ff       	call   80101bf4 <iunlockput>
    ilock(ip);
80105ae1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ae4:	89 04 24             	mov    %eax,(%esp)
80105ae7:	e8 84 be ff ff       	call   80101970 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105aec:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105af1:	75 15                	jne    80105b08 <create+0x9f>
80105af3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105af6:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105afa:	66 83 f8 02          	cmp    $0x2,%ax
80105afe:	75 08                	jne    80105b08 <create+0x9f>
      return ip;
80105b00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b03:	e9 1f 01 00 00       	jmp    80105c27 <create+0x1be>
    iunlockput(ip);
80105b08:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b0b:	89 04 24             	mov    %eax,(%esp)
80105b0e:	e8 e1 c0 ff ff       	call   80101bf4 <iunlockput>
    return 0;
80105b13:	b8 00 00 00 00       	mov    $0x0,%eax
80105b18:	e9 0a 01 00 00       	jmp    80105c27 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105b1d:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105b21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b24:	8b 00                	mov    (%eax),%eax
80105b26:	89 54 24 04          	mov    %edx,0x4(%esp)
80105b2a:	89 04 24             	mov    %eax,(%esp)
80105b2d:	e8 a5 bb ff ff       	call   801016d7 <ialloc>
80105b32:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105b35:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105b39:	75 0c                	jne    80105b47 <create+0xde>
    panic("create: ialloc");
80105b3b:	c7 04 24 df 86 10 80 	movl   $0x801086df,(%esp)
80105b42:	e8 f6 a9 ff ff       	call   8010053d <panic>

  ilock(ip);
80105b47:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b4a:	89 04 24             	mov    %eax,(%esp)
80105b4d:	e8 1e be ff ff       	call   80101970 <ilock>
  ip->major = major;
80105b52:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b55:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105b59:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105b5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b60:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105b64:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105b68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b6b:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105b71:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b74:	89 04 24             	mov    %eax,(%esp)
80105b77:	e8 38 bc ff ff       	call   801017b4 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105b7c:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105b81:	75 6a                	jne    80105bed <create+0x184>
    dp->nlink++;  // for ".."
80105b83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b86:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105b8a:	8d 50 01             	lea    0x1(%eax),%edx
80105b8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b90:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105b94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b97:	89 04 24             	mov    %eax,(%esp)
80105b9a:	e8 15 bc ff ff       	call   801017b4 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105b9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ba2:	8b 40 04             	mov    0x4(%eax),%eax
80105ba5:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ba9:	c7 44 24 04 b9 86 10 	movl   $0x801086b9,0x4(%esp)
80105bb0:	80 
80105bb1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bb4:	89 04 24             	mov    %eax,(%esp)
80105bb7:	e8 95 c6 ff ff       	call   80102251 <dirlink>
80105bbc:	85 c0                	test   %eax,%eax
80105bbe:	78 21                	js     80105be1 <create+0x178>
80105bc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bc3:	8b 40 04             	mov    0x4(%eax),%eax
80105bc6:	89 44 24 08          	mov    %eax,0x8(%esp)
80105bca:	c7 44 24 04 bb 86 10 	movl   $0x801086bb,0x4(%esp)
80105bd1:	80 
80105bd2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bd5:	89 04 24             	mov    %eax,(%esp)
80105bd8:	e8 74 c6 ff ff       	call   80102251 <dirlink>
80105bdd:	85 c0                	test   %eax,%eax
80105bdf:	79 0c                	jns    80105bed <create+0x184>
      panic("create dots");
80105be1:	c7 04 24 ee 86 10 80 	movl   $0x801086ee,(%esp)
80105be8:	e8 50 a9 ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105bed:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bf0:	8b 40 04             	mov    0x4(%eax),%eax
80105bf3:	89 44 24 08          	mov    %eax,0x8(%esp)
80105bf7:	8d 45 de             	lea    -0x22(%ebp),%eax
80105bfa:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bfe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c01:	89 04 24             	mov    %eax,(%esp)
80105c04:	e8 48 c6 ff ff       	call   80102251 <dirlink>
80105c09:	85 c0                	test   %eax,%eax
80105c0b:	79 0c                	jns    80105c19 <create+0x1b0>
    panic("create: dirlink");
80105c0d:	c7 04 24 fa 86 10 80 	movl   $0x801086fa,(%esp)
80105c14:	e8 24 a9 ff ff       	call   8010053d <panic>

  iunlockput(dp);
80105c19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c1c:	89 04 24             	mov    %eax,(%esp)
80105c1f:	e8 d0 bf ff ff       	call   80101bf4 <iunlockput>

  return ip;
80105c24:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105c27:	c9                   	leave  
80105c28:	c3                   	ret    

80105c29 <sys_open>:

int
sys_open(void)
{
80105c29:	55                   	push   %ebp
80105c2a:	89 e5                	mov    %esp,%ebp
80105c2c:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105c2f:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105c32:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c36:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105c3d:	e8 a2 f6 ff ff       	call   801052e4 <argstr>
80105c42:	85 c0                	test   %eax,%eax
80105c44:	78 17                	js     80105c5d <sys_open+0x34>
80105c46:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105c49:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c4d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105c54:	e8 f1 f5 ff ff       	call   8010524a <argint>
80105c59:	85 c0                	test   %eax,%eax
80105c5b:	79 0a                	jns    80105c67 <sys_open+0x3e>
    return -1;
80105c5d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c62:	e9 46 01 00 00       	jmp    80105dad <sys_open+0x184>
  if(omode & O_CREATE){
80105c67:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105c6a:	25 00 02 00 00       	and    $0x200,%eax
80105c6f:	85 c0                	test   %eax,%eax
80105c71:	74 40                	je     80105cb3 <sys_open+0x8a>
    begin_trans();
80105c73:	e8 ad d6 ff ff       	call   80103325 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80105c78:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105c7b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105c82:	00 
80105c83:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105c8a:	00 
80105c8b:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80105c92:	00 
80105c93:	89 04 24             	mov    %eax,(%esp)
80105c96:	e8 ce fd ff ff       	call   80105a69 <create>
80105c9b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80105c9e:	e8 cb d6 ff ff       	call   8010336e <commit_trans>
    if(ip == 0)
80105ca3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ca7:	75 5c                	jne    80105d05 <sys_open+0xdc>
      return -1;
80105ca9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cae:	e9 fa 00 00 00       	jmp    80105dad <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80105cb3:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105cb6:	89 04 24             	mov    %eax,(%esp)
80105cb9:	e8 54 c8 ff ff       	call   80102512 <namei>
80105cbe:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105cc1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105cc5:	75 0a                	jne    80105cd1 <sys_open+0xa8>
      return -1;
80105cc7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ccc:	e9 dc 00 00 00       	jmp    80105dad <sys_open+0x184>
    ilock(ip);
80105cd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cd4:	89 04 24             	mov    %eax,(%esp)
80105cd7:	e8 94 bc ff ff       	call   80101970 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80105cdc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cdf:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105ce3:	66 83 f8 01          	cmp    $0x1,%ax
80105ce7:	75 1c                	jne    80105d05 <sys_open+0xdc>
80105ce9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105cec:	85 c0                	test   %eax,%eax
80105cee:	74 15                	je     80105d05 <sys_open+0xdc>
      iunlockput(ip);
80105cf0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cf3:	89 04 24             	mov    %eax,(%esp)
80105cf6:	e8 f9 be ff ff       	call   80101bf4 <iunlockput>
      return -1;
80105cfb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d00:	e9 a8 00 00 00       	jmp    80105dad <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80105d05:	e8 1a b3 ff ff       	call   80101024 <filealloc>
80105d0a:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105d0d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105d11:	74 14                	je     80105d27 <sys_open+0xfe>
80105d13:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d16:	89 04 24             	mov    %eax,(%esp)
80105d19:	e8 43 f7 ff ff       	call   80105461 <fdalloc>
80105d1e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105d21:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80105d25:	79 23                	jns    80105d4a <sys_open+0x121>
    if(f)
80105d27:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105d2b:	74 0b                	je     80105d38 <sys_open+0x10f>
      fileclose(f);
80105d2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d30:	89 04 24             	mov    %eax,(%esp)
80105d33:	e8 94 b3 ff ff       	call   801010cc <fileclose>
    iunlockput(ip);
80105d38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d3b:	89 04 24             	mov    %eax,(%esp)
80105d3e:	e8 b1 be ff ff       	call   80101bf4 <iunlockput>
    return -1;
80105d43:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d48:	eb 63                	jmp    80105dad <sys_open+0x184>
  }
  iunlock(ip);
80105d4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d4d:	89 04 24             	mov    %eax,(%esp)
80105d50:	e8 69 bd ff ff       	call   80101abe <iunlock>

  f->type = FD_INODE;
80105d55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d58:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80105d5e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d61:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105d64:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80105d67:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d6a:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80105d71:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105d74:	83 e0 01             	and    $0x1,%eax
80105d77:	85 c0                	test   %eax,%eax
80105d79:	0f 94 c2             	sete   %dl
80105d7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d7f:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80105d82:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105d85:	83 e0 01             	and    $0x1,%eax
80105d88:	84 c0                	test   %al,%al
80105d8a:	75 0a                	jne    80105d96 <sys_open+0x16d>
80105d8c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105d8f:	83 e0 02             	and    $0x2,%eax
80105d92:	85 c0                	test   %eax,%eax
80105d94:	74 07                	je     80105d9d <sys_open+0x174>
80105d96:	b8 01 00 00 00       	mov    $0x1,%eax
80105d9b:	eb 05                	jmp    80105da2 <sys_open+0x179>
80105d9d:	b8 00 00 00 00       	mov    $0x0,%eax
80105da2:	89 c2                	mov    %eax,%edx
80105da4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105da7:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80105daa:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80105dad:	c9                   	leave  
80105dae:	c3                   	ret    

80105daf <sys_mkdir>:

int
sys_mkdir(void)
{
80105daf:	55                   	push   %ebp
80105db0:	89 e5                	mov    %esp,%ebp
80105db2:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80105db5:	e8 6b d5 ff ff       	call   80103325 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80105dba:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105dbd:	89 44 24 04          	mov    %eax,0x4(%esp)
80105dc1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105dc8:	e8 17 f5 ff ff       	call   801052e4 <argstr>
80105dcd:	85 c0                	test   %eax,%eax
80105dcf:	78 2c                	js     80105dfd <sys_mkdir+0x4e>
80105dd1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dd4:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105ddb:	00 
80105ddc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105de3:	00 
80105de4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105deb:	00 
80105dec:	89 04 24             	mov    %eax,(%esp)
80105def:	e8 75 fc ff ff       	call   80105a69 <create>
80105df4:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105df7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105dfb:	75 0c                	jne    80105e09 <sys_mkdir+0x5a>
    commit_trans();
80105dfd:	e8 6c d5 ff ff       	call   8010336e <commit_trans>
    return -1;
80105e02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e07:	eb 15                	jmp    80105e1e <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80105e09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e0c:	89 04 24             	mov    %eax,(%esp)
80105e0f:	e8 e0 bd ff ff       	call   80101bf4 <iunlockput>
  commit_trans();
80105e14:	e8 55 d5 ff ff       	call   8010336e <commit_trans>
  return 0;
80105e19:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105e1e:	c9                   	leave  
80105e1f:	c3                   	ret    

80105e20 <sys_mknod>:

int
sys_mknod(void)
{
80105e20:	55                   	push   %ebp
80105e21:	89 e5                	mov    %esp,%ebp
80105e23:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
80105e26:	e8 fa d4 ff ff       	call   80103325 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
80105e2b:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105e2e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e32:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105e39:	e8 a6 f4 ff ff       	call   801052e4 <argstr>
80105e3e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105e41:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e45:	78 5e                	js     80105ea5 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80105e47:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105e4a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e4e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105e55:	e8 f0 f3 ff ff       	call   8010524a <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
80105e5a:	85 c0                	test   %eax,%eax
80105e5c:	78 47                	js     80105ea5 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80105e5e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105e61:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e65:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105e6c:	e8 d9 f3 ff ff       	call   8010524a <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80105e71:	85 c0                	test   %eax,%eax
80105e73:	78 30                	js     80105ea5 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80105e75:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105e78:	0f bf c8             	movswl %ax,%ecx
80105e7b:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105e7e:	0f bf d0             	movswl %ax,%edx
80105e81:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80105e84:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80105e88:	89 54 24 08          	mov    %edx,0x8(%esp)
80105e8c:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80105e93:	00 
80105e94:	89 04 24             	mov    %eax,(%esp)
80105e97:	e8 cd fb ff ff       	call   80105a69 <create>
80105e9c:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105e9f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105ea3:	75 0c                	jne    80105eb1 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80105ea5:	e8 c4 d4 ff ff       	call   8010336e <commit_trans>
    return -1;
80105eaa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105eaf:	eb 15                	jmp    80105ec6 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80105eb1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105eb4:	89 04 24             	mov    %eax,(%esp)
80105eb7:	e8 38 bd ff ff       	call   80101bf4 <iunlockput>
  commit_trans();
80105ebc:	e8 ad d4 ff ff       	call   8010336e <commit_trans>
  return 0;
80105ec1:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ec6:	c9                   	leave  
80105ec7:	c3                   	ret    

80105ec8 <sys_chdir>:

int
sys_chdir(void)
{
80105ec8:	55                   	push   %ebp
80105ec9:	89 e5                	mov    %esp,%ebp
80105ecb:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80105ece:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105ed1:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ed5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105edc:	e8 03 f4 ff ff       	call   801052e4 <argstr>
80105ee1:	85 c0                	test   %eax,%eax
80105ee3:	78 14                	js     80105ef9 <sys_chdir+0x31>
80105ee5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ee8:	89 04 24             	mov    %eax,(%esp)
80105eeb:	e8 22 c6 ff ff       	call   80102512 <namei>
80105ef0:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ef3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ef7:	75 07                	jne    80105f00 <sys_chdir+0x38>
    return -1;
80105ef9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105efe:	eb 57                	jmp    80105f57 <sys_chdir+0x8f>
  ilock(ip);
80105f00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f03:	89 04 24             	mov    %eax,(%esp)
80105f06:	e8 65 ba ff ff       	call   80101970 <ilock>
  if(ip->type != T_DIR){
80105f0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f0e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105f12:	66 83 f8 01          	cmp    $0x1,%ax
80105f16:	74 12                	je     80105f2a <sys_chdir+0x62>
    iunlockput(ip);
80105f18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f1b:	89 04 24             	mov    %eax,(%esp)
80105f1e:	e8 d1 bc ff ff       	call   80101bf4 <iunlockput>
    return -1;
80105f23:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f28:	eb 2d                	jmp    80105f57 <sys_chdir+0x8f>
  }
  iunlock(ip);
80105f2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f2d:	89 04 24             	mov    %eax,(%esp)
80105f30:	e8 89 bb ff ff       	call   80101abe <iunlock>
  iput(proc->cwd);
80105f35:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f3b:	8b 40 68             	mov    0x68(%eax),%eax
80105f3e:	89 04 24             	mov    %eax,(%esp)
80105f41:	e8 dd bb ff ff       	call   80101b23 <iput>
  proc->cwd = ip;
80105f46:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f4c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105f4f:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80105f52:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f57:	c9                   	leave  
80105f58:	c3                   	ret    

80105f59 <sys_exec>:

int
sys_exec(void)
{
80105f59:	55                   	push   %ebp
80105f5a:	89 e5                	mov    %esp,%ebp
80105f5c:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80105f62:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f65:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f69:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f70:	e8 6f f3 ff ff       	call   801052e4 <argstr>
80105f75:	85 c0                	test   %eax,%eax
80105f77:	78 1a                	js     80105f93 <sys_exec+0x3a>
80105f79:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80105f7f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f83:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105f8a:	e8 bb f2 ff ff       	call   8010524a <argint>
80105f8f:	85 c0                	test   %eax,%eax
80105f91:	79 0a                	jns    80105f9d <sys_exec+0x44>
    return -1;
80105f93:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f98:	e9 e2 00 00 00       	jmp    8010607f <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
80105f9d:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80105fa4:	00 
80105fa5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105fac:	00 
80105fad:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80105fb3:	89 04 24             	mov    %eax,(%esp)
80105fb6:	e8 3f ef ff ff       	call   80104efa <memset>
  for(i=0;; i++){
80105fbb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80105fc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fc5:	83 f8 1f             	cmp    $0x1f,%eax
80105fc8:	76 0a                	jbe    80105fd4 <sys_exec+0x7b>
      return -1;
80105fca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fcf:	e9 ab 00 00 00       	jmp    8010607f <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80105fd4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fd7:	c1 e0 02             	shl    $0x2,%eax
80105fda:	89 c2                	mov    %eax,%edx
80105fdc:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80105fe2:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80105fe5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105feb:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80105ff1:	89 54 24 08          	mov    %edx,0x8(%esp)
80105ff5:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80105ff9:	89 04 24             	mov    %eax,(%esp)
80105ffc:	e8 b7 f1 ff ff       	call   801051b8 <fetchint>
80106001:	85 c0                	test   %eax,%eax
80106003:	79 07                	jns    8010600c <sys_exec+0xb3>
      return -1;
80106005:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010600a:	eb 73                	jmp    8010607f <sys_exec+0x126>
    if(uarg == 0){
8010600c:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106012:	85 c0                	test   %eax,%eax
80106014:	75 26                	jne    8010603c <sys_exec+0xe3>
      argv[i] = 0;
80106016:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106019:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106020:	00 00 00 00 
      break;
80106024:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106025:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106028:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
8010602e:	89 54 24 04          	mov    %edx,0x4(%esp)
80106032:	89 04 24             	mov    %eax,(%esp)
80106035:	e8 c2 aa ff ff       	call   80100afc <exec>
8010603a:	eb 43                	jmp    8010607f <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
8010603c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010603f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80106046:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
8010604c:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
8010604f:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
80106055:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010605b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010605f:	89 54 24 04          	mov    %edx,0x4(%esp)
80106063:	89 04 24             	mov    %eax,(%esp)
80106066:	e8 81 f1 ff ff       	call   801051ec <fetchstr>
8010606b:	85 c0                	test   %eax,%eax
8010606d:	79 07                	jns    80106076 <sys_exec+0x11d>
      return -1;
8010606f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106074:	eb 09                	jmp    8010607f <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106076:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
8010607a:	e9 43 ff ff ff       	jmp    80105fc2 <sys_exec+0x69>
  return exec(path, argv);
}
8010607f:	c9                   	leave  
80106080:	c3                   	ret    

80106081 <sys_pipe>:

int
sys_pipe(void)
{
80106081:	55                   	push   %ebp
80106082:	89 e5                	mov    %esp,%ebp
80106084:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106087:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
8010608e:	00 
8010608f:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106092:	89 44 24 04          	mov    %eax,0x4(%esp)
80106096:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010609d:	e8 e0 f1 ff ff       	call   80105282 <argptr>
801060a2:	85 c0                	test   %eax,%eax
801060a4:	79 0a                	jns    801060b0 <sys_pipe+0x2f>
    return -1;
801060a6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060ab:	e9 9b 00 00 00       	jmp    8010614b <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
801060b0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801060b3:	89 44 24 04          	mov    %eax,0x4(%esp)
801060b7:	8d 45 e8             	lea    -0x18(%ebp),%eax
801060ba:	89 04 24             	mov    %eax,(%esp)
801060bd:	e8 7e dc ff ff       	call   80103d40 <pipealloc>
801060c2:	85 c0                	test   %eax,%eax
801060c4:	79 07                	jns    801060cd <sys_pipe+0x4c>
    return -1;
801060c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060cb:	eb 7e                	jmp    8010614b <sys_pipe+0xca>
  fd0 = -1;
801060cd:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
801060d4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801060d7:	89 04 24             	mov    %eax,(%esp)
801060da:	e8 82 f3 ff ff       	call   80105461 <fdalloc>
801060df:	89 45 f4             	mov    %eax,-0xc(%ebp)
801060e2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060e6:	78 14                	js     801060fc <sys_pipe+0x7b>
801060e8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801060eb:	89 04 24             	mov    %eax,(%esp)
801060ee:	e8 6e f3 ff ff       	call   80105461 <fdalloc>
801060f3:	89 45 f0             	mov    %eax,-0x10(%ebp)
801060f6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801060fa:	79 37                	jns    80106133 <sys_pipe+0xb2>
    if(fd0 >= 0)
801060fc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106100:	78 14                	js     80106116 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106102:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106108:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010610b:	83 c2 08             	add    $0x8,%edx
8010610e:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106115:	00 
    fileclose(rf);
80106116:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106119:	89 04 24             	mov    %eax,(%esp)
8010611c:	e8 ab af ff ff       	call   801010cc <fileclose>
    fileclose(wf);
80106121:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106124:	89 04 24             	mov    %eax,(%esp)
80106127:	e8 a0 af ff ff       	call   801010cc <fileclose>
    return -1;
8010612c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106131:	eb 18                	jmp    8010614b <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106133:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106136:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106139:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
8010613b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010613e:	8d 50 04             	lea    0x4(%eax),%edx
80106141:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106144:	89 02                	mov    %eax,(%edx)
  return 0;
80106146:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010614b:	c9                   	leave  
8010614c:	c3                   	ret    
8010614d:	00 00                	add    %al,(%eax)
	...

80106150 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106150:	55                   	push   %ebp
80106151:	89 e5                	mov    %esp,%ebp
80106153:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106156:	e8 9f e2 ff ff       	call   801043fa <fork>
}
8010615b:	c9                   	leave  
8010615c:	c3                   	ret    

8010615d <sys_exit>:

int
sys_exit(void)
{
8010615d:	55                   	push   %ebp
8010615e:	89 e5                	mov    %esp,%ebp
80106160:	83 ec 08             	sub    $0x8,%esp
  exit();
80106163:	e8 f5 e3 ff ff       	call   8010455d <exit>
  return 0;  // not reached
80106168:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010616d:	c9                   	leave  
8010616e:	c3                   	ret    

8010616f <sys_wait>:

int
sys_wait(void)
{
8010616f:	55                   	push   %ebp
80106170:	89 e5                	mov    %esp,%ebp
80106172:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106175:	e8 fb e4 ff ff       	call   80104675 <wait>
}
8010617a:	c9                   	leave  
8010617b:	c3                   	ret    

8010617c <sys_kill>:

int
sys_kill(void)
{
8010617c:	55                   	push   %ebp
8010617d:	89 e5                	mov    %esp,%ebp
8010617f:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106182:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106185:	89 44 24 04          	mov    %eax,0x4(%esp)
80106189:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106190:	e8 b5 f0 ff ff       	call   8010524a <argint>
80106195:	85 c0                	test   %eax,%eax
80106197:	79 07                	jns    801061a0 <sys_kill+0x24>
    return -1;
80106199:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010619e:	eb 0b                	jmp    801061ab <sys_kill+0x2f>
  return kill(pid);
801061a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061a3:	89 04 24             	mov    %eax,(%esp)
801061a6:	e8 26 e9 ff ff       	call   80104ad1 <kill>
}
801061ab:	c9                   	leave  
801061ac:	c3                   	ret    

801061ad <sys_getpid>:

int
sys_getpid(void)
{
801061ad:	55                   	push   %ebp
801061ae:	89 e5                	mov    %esp,%ebp
  return proc->pid;
801061b0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061b6:	8b 40 10             	mov    0x10(%eax),%eax
}
801061b9:	5d                   	pop    %ebp
801061ba:	c3                   	ret    

801061bb <sys_sbrk>:

int
sys_sbrk(void)
{
801061bb:	55                   	push   %ebp
801061bc:	89 e5                	mov    %esp,%ebp
801061be:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801061c1:	8d 45 f0             	lea    -0x10(%ebp),%eax
801061c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801061c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061cf:	e8 76 f0 ff ff       	call   8010524a <argint>
801061d4:	85 c0                	test   %eax,%eax
801061d6:	79 07                	jns    801061df <sys_sbrk+0x24>
    return -1;
801061d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061dd:	eb 24                	jmp    80106203 <sys_sbrk+0x48>
  addr = proc->sz;
801061df:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061e5:	8b 00                	mov    (%eax),%eax
801061e7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
801061ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061ed:	89 04 24             	mov    %eax,(%esp)
801061f0:	e8 60 e1 ff ff       	call   80104355 <growproc>
801061f5:	85 c0                	test   %eax,%eax
801061f7:	79 07                	jns    80106200 <sys_sbrk+0x45>
    return -1;
801061f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061fe:	eb 03                	jmp    80106203 <sys_sbrk+0x48>
  return addr;
80106200:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106203:	c9                   	leave  
80106204:	c3                   	ret    

80106205 <sys_sleep>:

int
sys_sleep(void)
{
80106205:	55                   	push   %ebp
80106206:	89 e5                	mov    %esp,%ebp
80106208:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
8010620b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010620e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106212:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106219:	e8 2c f0 ff ff       	call   8010524a <argint>
8010621e:	85 c0                	test   %eax,%eax
80106220:	79 07                	jns    80106229 <sys_sleep+0x24>
    return -1;
80106222:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106227:	eb 6c                	jmp    80106295 <sys_sleep+0x90>
  acquire(&tickslock);
80106229:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
80106230:	e8 76 ea ff ff       	call   80104cab <acquire>
  ticks0 = ticks;
80106235:	a1 c0 2b 11 80       	mov    0x80112bc0,%eax
8010623a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
8010623d:	eb 34                	jmp    80106273 <sys_sleep+0x6e>
    if(proc->killed){
8010623f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106245:	8b 40 24             	mov    0x24(%eax),%eax
80106248:	85 c0                	test   %eax,%eax
8010624a:	74 13                	je     8010625f <sys_sleep+0x5a>
      release(&tickslock);
8010624c:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
80106253:	e8 b5 ea ff ff       	call   80104d0d <release>
      return -1;
80106258:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010625d:	eb 36                	jmp    80106295 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
8010625f:	c7 44 24 04 80 23 11 	movl   $0x80112380,0x4(%esp)
80106266:	80 
80106267:	c7 04 24 c0 2b 11 80 	movl   $0x80112bc0,(%esp)
8010626e:	e8 5a e7 ff ff       	call   801049cd <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106273:	a1 c0 2b 11 80       	mov    0x80112bc0,%eax
80106278:	89 c2                	mov    %eax,%edx
8010627a:	2b 55 f4             	sub    -0xc(%ebp),%edx
8010627d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106280:	39 c2                	cmp    %eax,%edx
80106282:	72 bb                	jb     8010623f <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106284:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
8010628b:	e8 7d ea ff ff       	call   80104d0d <release>
  return 0;
80106290:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106295:	c9                   	leave  
80106296:	c3                   	ret    

80106297 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106297:	55                   	push   %ebp
80106298:	89 e5                	mov    %esp,%ebp
8010629a:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
8010629d:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
801062a4:	e8 02 ea ff ff       	call   80104cab <acquire>
  xticks = ticks;
801062a9:	a1 c0 2b 11 80       	mov    0x80112bc0,%eax
801062ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
801062b1:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
801062b8:	e8 50 ea ff ff       	call   80104d0d <release>
  return xticks;
801062bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801062c0:	c9                   	leave  
801062c1:	c3                   	ret    
	...

801062c4 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801062c4:	55                   	push   %ebp
801062c5:	89 e5                	mov    %esp,%ebp
801062c7:	83 ec 08             	sub    $0x8,%esp
801062ca:	8b 55 08             	mov    0x8(%ebp),%edx
801062cd:	8b 45 0c             	mov    0xc(%ebp),%eax
801062d0:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801062d4:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801062d7:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801062db:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801062df:	ee                   	out    %al,(%dx)
}
801062e0:	c9                   	leave  
801062e1:	c3                   	ret    

801062e2 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
801062e2:	55                   	push   %ebp
801062e3:	89 e5                	mov    %esp,%ebp
801062e5:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
801062e8:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
801062ef:	00 
801062f0:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
801062f7:	e8 c8 ff ff ff       	call   801062c4 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801062fc:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106303:	00 
80106304:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010630b:	e8 b4 ff ff ff       	call   801062c4 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106310:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106317:	00 
80106318:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010631f:	e8 a0 ff ff ff       	call   801062c4 <outb>
  picenable(IRQ_TIMER);
80106324:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010632b:	e8 99 d8 ff ff       	call   80103bc9 <picenable>
}
80106330:	c9                   	leave  
80106331:	c3                   	ret    
	...

80106334 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106334:	1e                   	push   %ds
  pushl %es
80106335:	06                   	push   %es
  pushl %fs
80106336:	0f a0                	push   %fs
  pushl %gs
80106338:	0f a8                	push   %gs
  pushal
8010633a:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
8010633b:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010633f:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106341:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106343:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106347:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106349:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
8010634b:	54                   	push   %esp
  call trap
8010634c:	e8 de 01 00 00       	call   8010652f <trap>
  addl $4, %esp
80106351:	83 c4 04             	add    $0x4,%esp

80106354 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106354:	61                   	popa   
  popl %gs
80106355:	0f a9                	pop    %gs
  popl %fs
80106357:	0f a1                	pop    %fs
  popl %es
80106359:	07                   	pop    %es
  popl %ds
8010635a:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
8010635b:	83 c4 08             	add    $0x8,%esp
  iret
8010635e:	cf                   	iret   
	...

80106360 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106360:	55                   	push   %ebp
80106361:	89 e5                	mov    %esp,%ebp
80106363:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106366:	8b 45 0c             	mov    0xc(%ebp),%eax
80106369:	83 e8 01             	sub    $0x1,%eax
8010636c:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106370:	8b 45 08             	mov    0x8(%ebp),%eax
80106373:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106377:	8b 45 08             	mov    0x8(%ebp),%eax
8010637a:	c1 e8 10             	shr    $0x10,%eax
8010637d:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106381:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106384:	0f 01 18             	lidtl  (%eax)
}
80106387:	c9                   	leave  
80106388:	c3                   	ret    

80106389 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106389:	55                   	push   %ebp
8010638a:	89 e5                	mov    %esp,%ebp
8010638c:	53                   	push   %ebx
8010638d:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106390:	0f 20 d3             	mov    %cr2,%ebx
80106393:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
80106396:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80106399:	83 c4 10             	add    $0x10,%esp
8010639c:	5b                   	pop    %ebx
8010639d:	5d                   	pop    %ebp
8010639e:	c3                   	ret    

8010639f <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
8010639f:	55                   	push   %ebp
801063a0:	89 e5                	mov    %esp,%ebp
801063a2:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
801063a5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801063ac:	e9 c3 00 00 00       	jmp    80106474 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801063b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063b4:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
801063bb:	89 c2                	mov    %eax,%edx
801063bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063c0:	66 89 14 c5 c0 23 11 	mov    %dx,-0x7feedc40(,%eax,8)
801063c7:	80 
801063c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063cb:	66 c7 04 c5 c2 23 11 	movw   $0x8,-0x7feedc3e(,%eax,8)
801063d2:	80 08 00 
801063d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063d8:	0f b6 14 c5 c4 23 11 	movzbl -0x7feedc3c(,%eax,8),%edx
801063df:	80 
801063e0:	83 e2 e0             	and    $0xffffffe0,%edx
801063e3:	88 14 c5 c4 23 11 80 	mov    %dl,-0x7feedc3c(,%eax,8)
801063ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063ed:	0f b6 14 c5 c4 23 11 	movzbl -0x7feedc3c(,%eax,8),%edx
801063f4:	80 
801063f5:	83 e2 1f             	and    $0x1f,%edx
801063f8:	88 14 c5 c4 23 11 80 	mov    %dl,-0x7feedc3c(,%eax,8)
801063ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106402:	0f b6 14 c5 c5 23 11 	movzbl -0x7feedc3b(,%eax,8),%edx
80106409:	80 
8010640a:	83 e2 f0             	and    $0xfffffff0,%edx
8010640d:	83 ca 0e             	or     $0xe,%edx
80106410:	88 14 c5 c5 23 11 80 	mov    %dl,-0x7feedc3b(,%eax,8)
80106417:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010641a:	0f b6 14 c5 c5 23 11 	movzbl -0x7feedc3b(,%eax,8),%edx
80106421:	80 
80106422:	83 e2 ef             	and    $0xffffffef,%edx
80106425:	88 14 c5 c5 23 11 80 	mov    %dl,-0x7feedc3b(,%eax,8)
8010642c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010642f:	0f b6 14 c5 c5 23 11 	movzbl -0x7feedc3b(,%eax,8),%edx
80106436:	80 
80106437:	83 e2 9f             	and    $0xffffff9f,%edx
8010643a:	88 14 c5 c5 23 11 80 	mov    %dl,-0x7feedc3b(,%eax,8)
80106441:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106444:	0f b6 14 c5 c5 23 11 	movzbl -0x7feedc3b(,%eax,8),%edx
8010644b:	80 
8010644c:	83 ca 80             	or     $0xffffff80,%edx
8010644f:	88 14 c5 c5 23 11 80 	mov    %dl,-0x7feedc3b(,%eax,8)
80106456:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106459:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
80106460:	c1 e8 10             	shr    $0x10,%eax
80106463:	89 c2                	mov    %eax,%edx
80106465:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106468:	66 89 14 c5 c6 23 11 	mov    %dx,-0x7feedc3a(,%eax,8)
8010646f:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106470:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106474:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
8010647b:	0f 8e 30 ff ff ff    	jle    801063b1 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106481:	a1 98 b1 10 80       	mov    0x8010b198,%eax
80106486:	66 a3 c0 25 11 80    	mov    %ax,0x801125c0
8010648c:	66 c7 05 c2 25 11 80 	movw   $0x8,0x801125c2
80106493:	08 00 
80106495:	0f b6 05 c4 25 11 80 	movzbl 0x801125c4,%eax
8010649c:	83 e0 e0             	and    $0xffffffe0,%eax
8010649f:	a2 c4 25 11 80       	mov    %al,0x801125c4
801064a4:	0f b6 05 c4 25 11 80 	movzbl 0x801125c4,%eax
801064ab:	83 e0 1f             	and    $0x1f,%eax
801064ae:	a2 c4 25 11 80       	mov    %al,0x801125c4
801064b3:	0f b6 05 c5 25 11 80 	movzbl 0x801125c5,%eax
801064ba:	83 c8 0f             	or     $0xf,%eax
801064bd:	a2 c5 25 11 80       	mov    %al,0x801125c5
801064c2:	0f b6 05 c5 25 11 80 	movzbl 0x801125c5,%eax
801064c9:	83 e0 ef             	and    $0xffffffef,%eax
801064cc:	a2 c5 25 11 80       	mov    %al,0x801125c5
801064d1:	0f b6 05 c5 25 11 80 	movzbl 0x801125c5,%eax
801064d8:	83 c8 60             	or     $0x60,%eax
801064db:	a2 c5 25 11 80       	mov    %al,0x801125c5
801064e0:	0f b6 05 c5 25 11 80 	movzbl 0x801125c5,%eax
801064e7:	83 c8 80             	or     $0xffffff80,%eax
801064ea:	a2 c5 25 11 80       	mov    %al,0x801125c5
801064ef:	a1 98 b1 10 80       	mov    0x8010b198,%eax
801064f4:	c1 e8 10             	shr    $0x10,%eax
801064f7:	66 a3 c6 25 11 80    	mov    %ax,0x801125c6
  
  initlock(&tickslock, "time");
801064fd:	c7 44 24 04 0c 87 10 	movl   $0x8010870c,0x4(%esp)
80106504:	80 
80106505:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
8010650c:	e8 79 e7 ff ff       	call   80104c8a <initlock>
}
80106511:	c9                   	leave  
80106512:	c3                   	ret    

80106513 <idtinit>:

void
idtinit(void)
{
80106513:	55                   	push   %ebp
80106514:	89 e5                	mov    %esp,%ebp
80106516:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106519:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106520:	00 
80106521:	c7 04 24 c0 23 11 80 	movl   $0x801123c0,(%esp)
80106528:	e8 33 fe ff ff       	call   80106360 <lidt>
}
8010652d:	c9                   	leave  
8010652e:	c3                   	ret    

8010652f <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
8010652f:	55                   	push   %ebp
80106530:	89 e5                	mov    %esp,%ebp
80106532:	57                   	push   %edi
80106533:	56                   	push   %esi
80106534:	53                   	push   %ebx
80106535:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106538:	8b 45 08             	mov    0x8(%ebp),%eax
8010653b:	8b 40 30             	mov    0x30(%eax),%eax
8010653e:	83 f8 40             	cmp    $0x40,%eax
80106541:	75 3e                	jne    80106581 <trap+0x52>
    if(proc->killed)
80106543:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106549:	8b 40 24             	mov    0x24(%eax),%eax
8010654c:	85 c0                	test   %eax,%eax
8010654e:	74 05                	je     80106555 <trap+0x26>
      exit();
80106550:	e8 08 e0 ff ff       	call   8010455d <exit>
    proc->tf = tf;
80106555:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010655b:	8b 55 08             	mov    0x8(%ebp),%edx
8010655e:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106561:	e8 c1 ed ff ff       	call   80105327 <syscall>
    if(proc->killed)
80106566:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010656c:	8b 40 24             	mov    0x24(%eax),%eax
8010656f:	85 c0                	test   %eax,%eax
80106571:	0f 84 34 02 00 00    	je     801067ab <trap+0x27c>
      exit();
80106577:	e8 e1 df ff ff       	call   8010455d <exit>
    return;
8010657c:	e9 2a 02 00 00       	jmp    801067ab <trap+0x27c>
  }

  switch(tf->trapno){
80106581:	8b 45 08             	mov    0x8(%ebp),%eax
80106584:	8b 40 30             	mov    0x30(%eax),%eax
80106587:	83 e8 20             	sub    $0x20,%eax
8010658a:	83 f8 1f             	cmp    $0x1f,%eax
8010658d:	0f 87 bc 00 00 00    	ja     8010664f <trap+0x120>
80106593:	8b 04 85 b4 87 10 80 	mov    -0x7fef784c(,%eax,4),%eax
8010659a:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
8010659c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801065a2:	0f b6 00             	movzbl (%eax),%eax
801065a5:	84 c0                	test   %al,%al
801065a7:	75 31                	jne    801065da <trap+0xab>
      acquire(&tickslock);
801065a9:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
801065b0:	e8 f6 e6 ff ff       	call   80104cab <acquire>
      ticks++;
801065b5:	a1 c0 2b 11 80       	mov    0x80112bc0,%eax
801065ba:	83 c0 01             	add    $0x1,%eax
801065bd:	a3 c0 2b 11 80       	mov    %eax,0x80112bc0
      wakeup(&ticks);
801065c2:	c7 04 24 c0 2b 11 80 	movl   $0x80112bc0,(%esp)
801065c9:	e8 d8 e4 ff ff       	call   80104aa6 <wakeup>
      release(&tickslock);
801065ce:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
801065d5:	e8 33 e7 ff ff       	call   80104d0d <release>
    }
    lapiceoi();
801065da:	e8 12 ca ff ff       	call   80102ff1 <lapiceoi>
    break;
801065df:	e9 41 01 00 00       	jmp    80106725 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801065e4:	e8 10 c2 ff ff       	call   801027f9 <ideintr>
    lapiceoi();
801065e9:	e8 03 ca ff ff       	call   80102ff1 <lapiceoi>
    break;
801065ee:	e9 32 01 00 00       	jmp    80106725 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801065f3:	e8 d7 c7 ff ff       	call   80102dcf <kbdintr>
    lapiceoi();
801065f8:	e8 f4 c9 ff ff       	call   80102ff1 <lapiceoi>
    break;
801065fd:	e9 23 01 00 00       	jmp    80106725 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80106602:	e8 a9 03 00 00       	call   801069b0 <uartintr>
    lapiceoi();
80106607:	e8 e5 c9 ff ff       	call   80102ff1 <lapiceoi>
    break;
8010660c:	e9 14 01 00 00       	jmp    80106725 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80106611:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106614:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80106617:	8b 45 08             	mov    0x8(%ebp),%eax
8010661a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010661e:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80106621:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106627:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010662a:	0f b6 c0             	movzbl %al,%eax
8010662d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106631:	89 54 24 08          	mov    %edx,0x8(%esp)
80106635:	89 44 24 04          	mov    %eax,0x4(%esp)
80106639:	c7 04 24 14 87 10 80 	movl   $0x80108714,(%esp)
80106640:	e8 5c 9d ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80106645:	e8 a7 c9 ff ff       	call   80102ff1 <lapiceoi>
    break;
8010664a:	e9 d6 00 00 00       	jmp    80106725 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
8010664f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106655:	85 c0                	test   %eax,%eax
80106657:	74 11                	je     8010666a <trap+0x13b>
80106659:	8b 45 08             	mov    0x8(%ebp),%eax
8010665c:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106660:	0f b7 c0             	movzwl %ax,%eax
80106663:	83 e0 03             	and    $0x3,%eax
80106666:	85 c0                	test   %eax,%eax
80106668:	75 46                	jne    801066b0 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010666a:	e8 1a fd ff ff       	call   80106389 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
8010666f:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106672:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106675:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010667c:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010667f:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106682:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106685:	8b 52 30             	mov    0x30(%edx),%edx
80106688:	89 44 24 10          	mov    %eax,0x10(%esp)
8010668c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80106690:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106694:	89 54 24 04          	mov    %edx,0x4(%esp)
80106698:	c7 04 24 38 87 10 80 	movl   $0x80108738,(%esp)
8010669f:	e8 fd 9c ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
801066a4:	c7 04 24 6a 87 10 80 	movl   $0x8010876a,(%esp)
801066ab:	e8 8d 9e ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801066b0:	e8 d4 fc ff ff       	call   80106389 <rcr2>
801066b5:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801066b7:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801066ba:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801066bd:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801066c3:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801066c6:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801066c9:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801066cc:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801066cf:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801066d2:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801066d5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066db:	83 c0 6c             	add    $0x6c,%eax
801066de:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801066e1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801066e7:	8b 40 10             	mov    0x10(%eax),%eax
801066ea:	89 54 24 1c          	mov    %edx,0x1c(%esp)
801066ee:	89 7c 24 18          	mov    %edi,0x18(%esp)
801066f2:	89 74 24 14          	mov    %esi,0x14(%esp)
801066f6:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801066fa:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801066fe:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106701:	89 54 24 08          	mov    %edx,0x8(%esp)
80106705:	89 44 24 04          	mov    %eax,0x4(%esp)
80106709:	c7 04 24 70 87 10 80 	movl   $0x80108770,(%esp)
80106710:	e8 8c 9c ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80106715:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010671b:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80106722:	eb 01                	jmp    80106725 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80106724:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106725:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010672b:	85 c0                	test   %eax,%eax
8010672d:	74 24                	je     80106753 <trap+0x224>
8010672f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106735:	8b 40 24             	mov    0x24(%eax),%eax
80106738:	85 c0                	test   %eax,%eax
8010673a:	74 17                	je     80106753 <trap+0x224>
8010673c:	8b 45 08             	mov    0x8(%ebp),%eax
8010673f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106743:	0f b7 c0             	movzwl %ax,%eax
80106746:	83 e0 03             	and    $0x3,%eax
80106749:	83 f8 03             	cmp    $0x3,%eax
8010674c:	75 05                	jne    80106753 <trap+0x224>
    exit();
8010674e:	e8 0a de ff ff       	call   8010455d <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80106753:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106759:	85 c0                	test   %eax,%eax
8010675b:	74 1e                	je     8010677b <trap+0x24c>
8010675d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106763:	8b 40 0c             	mov    0xc(%eax),%eax
80106766:	83 f8 04             	cmp    $0x4,%eax
80106769:	75 10                	jne    8010677b <trap+0x24c>
8010676b:	8b 45 08             	mov    0x8(%ebp),%eax
8010676e:	8b 40 30             	mov    0x30(%eax),%eax
80106771:	83 f8 20             	cmp    $0x20,%eax
80106774:	75 05                	jne    8010677b <trap+0x24c>
    yield();
80106776:	e8 f4 e1 ff ff       	call   8010496f <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010677b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106781:	85 c0                	test   %eax,%eax
80106783:	74 27                	je     801067ac <trap+0x27d>
80106785:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010678b:	8b 40 24             	mov    0x24(%eax),%eax
8010678e:	85 c0                	test   %eax,%eax
80106790:	74 1a                	je     801067ac <trap+0x27d>
80106792:	8b 45 08             	mov    0x8(%ebp),%eax
80106795:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106799:	0f b7 c0             	movzwl %ax,%eax
8010679c:	83 e0 03             	and    $0x3,%eax
8010679f:	83 f8 03             	cmp    $0x3,%eax
801067a2:	75 08                	jne    801067ac <trap+0x27d>
    exit();
801067a4:	e8 b4 dd ff ff       	call   8010455d <exit>
801067a9:	eb 01                	jmp    801067ac <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
801067ab:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
801067ac:	83 c4 3c             	add    $0x3c,%esp
801067af:	5b                   	pop    %ebx
801067b0:	5e                   	pop    %esi
801067b1:	5f                   	pop    %edi
801067b2:	5d                   	pop    %ebp
801067b3:	c3                   	ret    

801067b4 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801067b4:	55                   	push   %ebp
801067b5:	89 e5                	mov    %esp,%ebp
801067b7:	53                   	push   %ebx
801067b8:	83 ec 14             	sub    $0x14,%esp
801067bb:	8b 45 08             	mov    0x8(%ebp),%eax
801067be:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801067c2:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801067c6:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801067ca:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801067ce:	ec                   	in     (%dx),%al
801067cf:	89 c3                	mov    %eax,%ebx
801067d1:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801067d4:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801067d8:	83 c4 14             	add    $0x14,%esp
801067db:	5b                   	pop    %ebx
801067dc:	5d                   	pop    %ebp
801067dd:	c3                   	ret    

801067de <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801067de:	55                   	push   %ebp
801067df:	89 e5                	mov    %esp,%ebp
801067e1:	83 ec 08             	sub    $0x8,%esp
801067e4:	8b 55 08             	mov    0x8(%ebp),%edx
801067e7:	8b 45 0c             	mov    0xc(%ebp),%eax
801067ea:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801067ee:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801067f1:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801067f5:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801067f9:	ee                   	out    %al,(%dx)
}
801067fa:	c9                   	leave  
801067fb:	c3                   	ret    

801067fc <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
801067fc:	55                   	push   %ebp
801067fd:	89 e5                	mov    %esp,%ebp
801067ff:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106802:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106809:	00 
8010680a:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106811:	e8 c8 ff ff ff       	call   801067de <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106816:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
8010681d:	00 
8010681e:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106825:	e8 b4 ff ff ff       	call   801067de <outb>
  outb(COM1+0, 115200/9600);
8010682a:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106831:	00 
80106832:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106839:	e8 a0 ff ff ff       	call   801067de <outb>
  outb(COM1+1, 0);
8010683e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106845:	00 
80106846:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
8010684d:	e8 8c ff ff ff       	call   801067de <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106852:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106859:	00 
8010685a:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106861:	e8 78 ff ff ff       	call   801067de <outb>
  outb(COM1+4, 0);
80106866:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010686d:	00 
8010686e:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106875:	e8 64 ff ff ff       	call   801067de <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
8010687a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106881:	00 
80106882:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106889:	e8 50 ff ff ff       	call   801067de <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
8010688e:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106895:	e8 1a ff ff ff       	call   801067b4 <inb>
8010689a:	3c ff                	cmp    $0xff,%al
8010689c:	74 6c                	je     8010690a <uartinit+0x10e>
    return;
  uart = 1;
8010689e:	c7 05 4c b6 10 80 01 	movl   $0x1,0x8010b64c
801068a5:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
801068a8:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801068af:	e8 00 ff ff ff       	call   801067b4 <inb>
  inb(COM1+0);
801068b4:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801068bb:	e8 f4 fe ff ff       	call   801067b4 <inb>
  picenable(IRQ_COM1);
801068c0:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801068c7:	e8 fd d2 ff ff       	call   80103bc9 <picenable>
  ioapicenable(IRQ_COM1, 0);
801068cc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801068d3:	00 
801068d4:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801068db:	e8 9e c1 ff ff       	call   80102a7e <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801068e0:	c7 45 f4 34 88 10 80 	movl   $0x80108834,-0xc(%ebp)
801068e7:	eb 15                	jmp    801068fe <uartinit+0x102>
    uartputc(*p);
801068e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068ec:	0f b6 00             	movzbl (%eax),%eax
801068ef:	0f be c0             	movsbl %al,%eax
801068f2:	89 04 24             	mov    %eax,(%esp)
801068f5:	e8 13 00 00 00       	call   8010690d <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801068fa:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801068fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106901:	0f b6 00             	movzbl (%eax),%eax
80106904:	84 c0                	test   %al,%al
80106906:	75 e1                	jne    801068e9 <uartinit+0xed>
80106908:	eb 01                	jmp    8010690b <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
8010690a:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
8010690b:	c9                   	leave  
8010690c:	c3                   	ret    

8010690d <uartputc>:

void
uartputc(int c)
{
8010690d:	55                   	push   %ebp
8010690e:	89 e5                	mov    %esp,%ebp
80106910:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80106913:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106918:	85 c0                	test   %eax,%eax
8010691a:	74 4d                	je     80106969 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010691c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106923:	eb 10                	jmp    80106935 <uartputc+0x28>
    microdelay(10);
80106925:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
8010692c:	e8 e5 c6 ff ff       	call   80103016 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106931:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106935:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106939:	7f 16                	jg     80106951 <uartputc+0x44>
8010693b:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106942:	e8 6d fe ff ff       	call   801067b4 <inb>
80106947:	0f b6 c0             	movzbl %al,%eax
8010694a:	83 e0 20             	and    $0x20,%eax
8010694d:	85 c0                	test   %eax,%eax
8010694f:	74 d4                	je     80106925 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80106951:	8b 45 08             	mov    0x8(%ebp),%eax
80106954:	0f b6 c0             	movzbl %al,%eax
80106957:	89 44 24 04          	mov    %eax,0x4(%esp)
8010695b:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106962:	e8 77 fe ff ff       	call   801067de <outb>
80106967:	eb 01                	jmp    8010696a <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80106969:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
8010696a:	c9                   	leave  
8010696b:	c3                   	ret    

8010696c <uartgetc>:

static int
uartgetc(void)
{
8010696c:	55                   	push   %ebp
8010696d:	89 e5                	mov    %esp,%ebp
8010696f:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106972:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106977:	85 c0                	test   %eax,%eax
80106979:	75 07                	jne    80106982 <uartgetc+0x16>
    return -1;
8010697b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106980:	eb 2c                	jmp    801069ae <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106982:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106989:	e8 26 fe ff ff       	call   801067b4 <inb>
8010698e:	0f b6 c0             	movzbl %al,%eax
80106991:	83 e0 01             	and    $0x1,%eax
80106994:	85 c0                	test   %eax,%eax
80106996:	75 07                	jne    8010699f <uartgetc+0x33>
    return -1;
80106998:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010699d:	eb 0f                	jmp    801069ae <uartgetc+0x42>
  return inb(COM1+0);
8010699f:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801069a6:	e8 09 fe ff ff       	call   801067b4 <inb>
801069ab:	0f b6 c0             	movzbl %al,%eax
}
801069ae:	c9                   	leave  
801069af:	c3                   	ret    

801069b0 <uartintr>:

void
uartintr(void)
{
801069b0:	55                   	push   %ebp
801069b1:	89 e5                	mov    %esp,%ebp
801069b3:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
801069b6:	c7 04 24 6c 69 10 80 	movl   $0x8010696c,(%esp)
801069bd:	e8 eb 9d ff ff       	call   801007ad <consoleintr>
}
801069c2:	c9                   	leave  
801069c3:	c3                   	ret    

801069c4 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801069c4:	6a 00                	push   $0x0
  pushl $0
801069c6:	6a 00                	push   $0x0
  jmp alltraps
801069c8:	e9 67 f9 ff ff       	jmp    80106334 <alltraps>

801069cd <vector1>:
.globl vector1
vector1:
  pushl $0
801069cd:	6a 00                	push   $0x0
  pushl $1
801069cf:	6a 01                	push   $0x1
  jmp alltraps
801069d1:	e9 5e f9 ff ff       	jmp    80106334 <alltraps>

801069d6 <vector2>:
.globl vector2
vector2:
  pushl $0
801069d6:	6a 00                	push   $0x0
  pushl $2
801069d8:	6a 02                	push   $0x2
  jmp alltraps
801069da:	e9 55 f9 ff ff       	jmp    80106334 <alltraps>

801069df <vector3>:
.globl vector3
vector3:
  pushl $0
801069df:	6a 00                	push   $0x0
  pushl $3
801069e1:	6a 03                	push   $0x3
  jmp alltraps
801069e3:	e9 4c f9 ff ff       	jmp    80106334 <alltraps>

801069e8 <vector4>:
.globl vector4
vector4:
  pushl $0
801069e8:	6a 00                	push   $0x0
  pushl $4
801069ea:	6a 04                	push   $0x4
  jmp alltraps
801069ec:	e9 43 f9 ff ff       	jmp    80106334 <alltraps>

801069f1 <vector5>:
.globl vector5
vector5:
  pushl $0
801069f1:	6a 00                	push   $0x0
  pushl $5
801069f3:	6a 05                	push   $0x5
  jmp alltraps
801069f5:	e9 3a f9 ff ff       	jmp    80106334 <alltraps>

801069fa <vector6>:
.globl vector6
vector6:
  pushl $0
801069fa:	6a 00                	push   $0x0
  pushl $6
801069fc:	6a 06                	push   $0x6
  jmp alltraps
801069fe:	e9 31 f9 ff ff       	jmp    80106334 <alltraps>

80106a03 <vector7>:
.globl vector7
vector7:
  pushl $0
80106a03:	6a 00                	push   $0x0
  pushl $7
80106a05:	6a 07                	push   $0x7
  jmp alltraps
80106a07:	e9 28 f9 ff ff       	jmp    80106334 <alltraps>

80106a0c <vector8>:
.globl vector8
vector8:
  pushl $8
80106a0c:	6a 08                	push   $0x8
  jmp alltraps
80106a0e:	e9 21 f9 ff ff       	jmp    80106334 <alltraps>

80106a13 <vector9>:
.globl vector9
vector9:
  pushl $0
80106a13:	6a 00                	push   $0x0
  pushl $9
80106a15:	6a 09                	push   $0x9
  jmp alltraps
80106a17:	e9 18 f9 ff ff       	jmp    80106334 <alltraps>

80106a1c <vector10>:
.globl vector10
vector10:
  pushl $10
80106a1c:	6a 0a                	push   $0xa
  jmp alltraps
80106a1e:	e9 11 f9 ff ff       	jmp    80106334 <alltraps>

80106a23 <vector11>:
.globl vector11
vector11:
  pushl $11
80106a23:	6a 0b                	push   $0xb
  jmp alltraps
80106a25:	e9 0a f9 ff ff       	jmp    80106334 <alltraps>

80106a2a <vector12>:
.globl vector12
vector12:
  pushl $12
80106a2a:	6a 0c                	push   $0xc
  jmp alltraps
80106a2c:	e9 03 f9 ff ff       	jmp    80106334 <alltraps>

80106a31 <vector13>:
.globl vector13
vector13:
  pushl $13
80106a31:	6a 0d                	push   $0xd
  jmp alltraps
80106a33:	e9 fc f8 ff ff       	jmp    80106334 <alltraps>

80106a38 <vector14>:
.globl vector14
vector14:
  pushl $14
80106a38:	6a 0e                	push   $0xe
  jmp alltraps
80106a3a:	e9 f5 f8 ff ff       	jmp    80106334 <alltraps>

80106a3f <vector15>:
.globl vector15
vector15:
  pushl $0
80106a3f:	6a 00                	push   $0x0
  pushl $15
80106a41:	6a 0f                	push   $0xf
  jmp alltraps
80106a43:	e9 ec f8 ff ff       	jmp    80106334 <alltraps>

80106a48 <vector16>:
.globl vector16
vector16:
  pushl $0
80106a48:	6a 00                	push   $0x0
  pushl $16
80106a4a:	6a 10                	push   $0x10
  jmp alltraps
80106a4c:	e9 e3 f8 ff ff       	jmp    80106334 <alltraps>

80106a51 <vector17>:
.globl vector17
vector17:
  pushl $17
80106a51:	6a 11                	push   $0x11
  jmp alltraps
80106a53:	e9 dc f8 ff ff       	jmp    80106334 <alltraps>

80106a58 <vector18>:
.globl vector18
vector18:
  pushl $0
80106a58:	6a 00                	push   $0x0
  pushl $18
80106a5a:	6a 12                	push   $0x12
  jmp alltraps
80106a5c:	e9 d3 f8 ff ff       	jmp    80106334 <alltraps>

80106a61 <vector19>:
.globl vector19
vector19:
  pushl $0
80106a61:	6a 00                	push   $0x0
  pushl $19
80106a63:	6a 13                	push   $0x13
  jmp alltraps
80106a65:	e9 ca f8 ff ff       	jmp    80106334 <alltraps>

80106a6a <vector20>:
.globl vector20
vector20:
  pushl $0
80106a6a:	6a 00                	push   $0x0
  pushl $20
80106a6c:	6a 14                	push   $0x14
  jmp alltraps
80106a6e:	e9 c1 f8 ff ff       	jmp    80106334 <alltraps>

80106a73 <vector21>:
.globl vector21
vector21:
  pushl $0
80106a73:	6a 00                	push   $0x0
  pushl $21
80106a75:	6a 15                	push   $0x15
  jmp alltraps
80106a77:	e9 b8 f8 ff ff       	jmp    80106334 <alltraps>

80106a7c <vector22>:
.globl vector22
vector22:
  pushl $0
80106a7c:	6a 00                	push   $0x0
  pushl $22
80106a7e:	6a 16                	push   $0x16
  jmp alltraps
80106a80:	e9 af f8 ff ff       	jmp    80106334 <alltraps>

80106a85 <vector23>:
.globl vector23
vector23:
  pushl $0
80106a85:	6a 00                	push   $0x0
  pushl $23
80106a87:	6a 17                	push   $0x17
  jmp alltraps
80106a89:	e9 a6 f8 ff ff       	jmp    80106334 <alltraps>

80106a8e <vector24>:
.globl vector24
vector24:
  pushl $0
80106a8e:	6a 00                	push   $0x0
  pushl $24
80106a90:	6a 18                	push   $0x18
  jmp alltraps
80106a92:	e9 9d f8 ff ff       	jmp    80106334 <alltraps>

80106a97 <vector25>:
.globl vector25
vector25:
  pushl $0
80106a97:	6a 00                	push   $0x0
  pushl $25
80106a99:	6a 19                	push   $0x19
  jmp alltraps
80106a9b:	e9 94 f8 ff ff       	jmp    80106334 <alltraps>

80106aa0 <vector26>:
.globl vector26
vector26:
  pushl $0
80106aa0:	6a 00                	push   $0x0
  pushl $26
80106aa2:	6a 1a                	push   $0x1a
  jmp alltraps
80106aa4:	e9 8b f8 ff ff       	jmp    80106334 <alltraps>

80106aa9 <vector27>:
.globl vector27
vector27:
  pushl $0
80106aa9:	6a 00                	push   $0x0
  pushl $27
80106aab:	6a 1b                	push   $0x1b
  jmp alltraps
80106aad:	e9 82 f8 ff ff       	jmp    80106334 <alltraps>

80106ab2 <vector28>:
.globl vector28
vector28:
  pushl $0
80106ab2:	6a 00                	push   $0x0
  pushl $28
80106ab4:	6a 1c                	push   $0x1c
  jmp alltraps
80106ab6:	e9 79 f8 ff ff       	jmp    80106334 <alltraps>

80106abb <vector29>:
.globl vector29
vector29:
  pushl $0
80106abb:	6a 00                	push   $0x0
  pushl $29
80106abd:	6a 1d                	push   $0x1d
  jmp alltraps
80106abf:	e9 70 f8 ff ff       	jmp    80106334 <alltraps>

80106ac4 <vector30>:
.globl vector30
vector30:
  pushl $0
80106ac4:	6a 00                	push   $0x0
  pushl $30
80106ac6:	6a 1e                	push   $0x1e
  jmp alltraps
80106ac8:	e9 67 f8 ff ff       	jmp    80106334 <alltraps>

80106acd <vector31>:
.globl vector31
vector31:
  pushl $0
80106acd:	6a 00                	push   $0x0
  pushl $31
80106acf:	6a 1f                	push   $0x1f
  jmp alltraps
80106ad1:	e9 5e f8 ff ff       	jmp    80106334 <alltraps>

80106ad6 <vector32>:
.globl vector32
vector32:
  pushl $0
80106ad6:	6a 00                	push   $0x0
  pushl $32
80106ad8:	6a 20                	push   $0x20
  jmp alltraps
80106ada:	e9 55 f8 ff ff       	jmp    80106334 <alltraps>

80106adf <vector33>:
.globl vector33
vector33:
  pushl $0
80106adf:	6a 00                	push   $0x0
  pushl $33
80106ae1:	6a 21                	push   $0x21
  jmp alltraps
80106ae3:	e9 4c f8 ff ff       	jmp    80106334 <alltraps>

80106ae8 <vector34>:
.globl vector34
vector34:
  pushl $0
80106ae8:	6a 00                	push   $0x0
  pushl $34
80106aea:	6a 22                	push   $0x22
  jmp alltraps
80106aec:	e9 43 f8 ff ff       	jmp    80106334 <alltraps>

80106af1 <vector35>:
.globl vector35
vector35:
  pushl $0
80106af1:	6a 00                	push   $0x0
  pushl $35
80106af3:	6a 23                	push   $0x23
  jmp alltraps
80106af5:	e9 3a f8 ff ff       	jmp    80106334 <alltraps>

80106afa <vector36>:
.globl vector36
vector36:
  pushl $0
80106afa:	6a 00                	push   $0x0
  pushl $36
80106afc:	6a 24                	push   $0x24
  jmp alltraps
80106afe:	e9 31 f8 ff ff       	jmp    80106334 <alltraps>

80106b03 <vector37>:
.globl vector37
vector37:
  pushl $0
80106b03:	6a 00                	push   $0x0
  pushl $37
80106b05:	6a 25                	push   $0x25
  jmp alltraps
80106b07:	e9 28 f8 ff ff       	jmp    80106334 <alltraps>

80106b0c <vector38>:
.globl vector38
vector38:
  pushl $0
80106b0c:	6a 00                	push   $0x0
  pushl $38
80106b0e:	6a 26                	push   $0x26
  jmp alltraps
80106b10:	e9 1f f8 ff ff       	jmp    80106334 <alltraps>

80106b15 <vector39>:
.globl vector39
vector39:
  pushl $0
80106b15:	6a 00                	push   $0x0
  pushl $39
80106b17:	6a 27                	push   $0x27
  jmp alltraps
80106b19:	e9 16 f8 ff ff       	jmp    80106334 <alltraps>

80106b1e <vector40>:
.globl vector40
vector40:
  pushl $0
80106b1e:	6a 00                	push   $0x0
  pushl $40
80106b20:	6a 28                	push   $0x28
  jmp alltraps
80106b22:	e9 0d f8 ff ff       	jmp    80106334 <alltraps>

80106b27 <vector41>:
.globl vector41
vector41:
  pushl $0
80106b27:	6a 00                	push   $0x0
  pushl $41
80106b29:	6a 29                	push   $0x29
  jmp alltraps
80106b2b:	e9 04 f8 ff ff       	jmp    80106334 <alltraps>

80106b30 <vector42>:
.globl vector42
vector42:
  pushl $0
80106b30:	6a 00                	push   $0x0
  pushl $42
80106b32:	6a 2a                	push   $0x2a
  jmp alltraps
80106b34:	e9 fb f7 ff ff       	jmp    80106334 <alltraps>

80106b39 <vector43>:
.globl vector43
vector43:
  pushl $0
80106b39:	6a 00                	push   $0x0
  pushl $43
80106b3b:	6a 2b                	push   $0x2b
  jmp alltraps
80106b3d:	e9 f2 f7 ff ff       	jmp    80106334 <alltraps>

80106b42 <vector44>:
.globl vector44
vector44:
  pushl $0
80106b42:	6a 00                	push   $0x0
  pushl $44
80106b44:	6a 2c                	push   $0x2c
  jmp alltraps
80106b46:	e9 e9 f7 ff ff       	jmp    80106334 <alltraps>

80106b4b <vector45>:
.globl vector45
vector45:
  pushl $0
80106b4b:	6a 00                	push   $0x0
  pushl $45
80106b4d:	6a 2d                	push   $0x2d
  jmp alltraps
80106b4f:	e9 e0 f7 ff ff       	jmp    80106334 <alltraps>

80106b54 <vector46>:
.globl vector46
vector46:
  pushl $0
80106b54:	6a 00                	push   $0x0
  pushl $46
80106b56:	6a 2e                	push   $0x2e
  jmp alltraps
80106b58:	e9 d7 f7 ff ff       	jmp    80106334 <alltraps>

80106b5d <vector47>:
.globl vector47
vector47:
  pushl $0
80106b5d:	6a 00                	push   $0x0
  pushl $47
80106b5f:	6a 2f                	push   $0x2f
  jmp alltraps
80106b61:	e9 ce f7 ff ff       	jmp    80106334 <alltraps>

80106b66 <vector48>:
.globl vector48
vector48:
  pushl $0
80106b66:	6a 00                	push   $0x0
  pushl $48
80106b68:	6a 30                	push   $0x30
  jmp alltraps
80106b6a:	e9 c5 f7 ff ff       	jmp    80106334 <alltraps>

80106b6f <vector49>:
.globl vector49
vector49:
  pushl $0
80106b6f:	6a 00                	push   $0x0
  pushl $49
80106b71:	6a 31                	push   $0x31
  jmp alltraps
80106b73:	e9 bc f7 ff ff       	jmp    80106334 <alltraps>

80106b78 <vector50>:
.globl vector50
vector50:
  pushl $0
80106b78:	6a 00                	push   $0x0
  pushl $50
80106b7a:	6a 32                	push   $0x32
  jmp alltraps
80106b7c:	e9 b3 f7 ff ff       	jmp    80106334 <alltraps>

80106b81 <vector51>:
.globl vector51
vector51:
  pushl $0
80106b81:	6a 00                	push   $0x0
  pushl $51
80106b83:	6a 33                	push   $0x33
  jmp alltraps
80106b85:	e9 aa f7 ff ff       	jmp    80106334 <alltraps>

80106b8a <vector52>:
.globl vector52
vector52:
  pushl $0
80106b8a:	6a 00                	push   $0x0
  pushl $52
80106b8c:	6a 34                	push   $0x34
  jmp alltraps
80106b8e:	e9 a1 f7 ff ff       	jmp    80106334 <alltraps>

80106b93 <vector53>:
.globl vector53
vector53:
  pushl $0
80106b93:	6a 00                	push   $0x0
  pushl $53
80106b95:	6a 35                	push   $0x35
  jmp alltraps
80106b97:	e9 98 f7 ff ff       	jmp    80106334 <alltraps>

80106b9c <vector54>:
.globl vector54
vector54:
  pushl $0
80106b9c:	6a 00                	push   $0x0
  pushl $54
80106b9e:	6a 36                	push   $0x36
  jmp alltraps
80106ba0:	e9 8f f7 ff ff       	jmp    80106334 <alltraps>

80106ba5 <vector55>:
.globl vector55
vector55:
  pushl $0
80106ba5:	6a 00                	push   $0x0
  pushl $55
80106ba7:	6a 37                	push   $0x37
  jmp alltraps
80106ba9:	e9 86 f7 ff ff       	jmp    80106334 <alltraps>

80106bae <vector56>:
.globl vector56
vector56:
  pushl $0
80106bae:	6a 00                	push   $0x0
  pushl $56
80106bb0:	6a 38                	push   $0x38
  jmp alltraps
80106bb2:	e9 7d f7 ff ff       	jmp    80106334 <alltraps>

80106bb7 <vector57>:
.globl vector57
vector57:
  pushl $0
80106bb7:	6a 00                	push   $0x0
  pushl $57
80106bb9:	6a 39                	push   $0x39
  jmp alltraps
80106bbb:	e9 74 f7 ff ff       	jmp    80106334 <alltraps>

80106bc0 <vector58>:
.globl vector58
vector58:
  pushl $0
80106bc0:	6a 00                	push   $0x0
  pushl $58
80106bc2:	6a 3a                	push   $0x3a
  jmp alltraps
80106bc4:	e9 6b f7 ff ff       	jmp    80106334 <alltraps>

80106bc9 <vector59>:
.globl vector59
vector59:
  pushl $0
80106bc9:	6a 00                	push   $0x0
  pushl $59
80106bcb:	6a 3b                	push   $0x3b
  jmp alltraps
80106bcd:	e9 62 f7 ff ff       	jmp    80106334 <alltraps>

80106bd2 <vector60>:
.globl vector60
vector60:
  pushl $0
80106bd2:	6a 00                	push   $0x0
  pushl $60
80106bd4:	6a 3c                	push   $0x3c
  jmp alltraps
80106bd6:	e9 59 f7 ff ff       	jmp    80106334 <alltraps>

80106bdb <vector61>:
.globl vector61
vector61:
  pushl $0
80106bdb:	6a 00                	push   $0x0
  pushl $61
80106bdd:	6a 3d                	push   $0x3d
  jmp alltraps
80106bdf:	e9 50 f7 ff ff       	jmp    80106334 <alltraps>

80106be4 <vector62>:
.globl vector62
vector62:
  pushl $0
80106be4:	6a 00                	push   $0x0
  pushl $62
80106be6:	6a 3e                	push   $0x3e
  jmp alltraps
80106be8:	e9 47 f7 ff ff       	jmp    80106334 <alltraps>

80106bed <vector63>:
.globl vector63
vector63:
  pushl $0
80106bed:	6a 00                	push   $0x0
  pushl $63
80106bef:	6a 3f                	push   $0x3f
  jmp alltraps
80106bf1:	e9 3e f7 ff ff       	jmp    80106334 <alltraps>

80106bf6 <vector64>:
.globl vector64
vector64:
  pushl $0
80106bf6:	6a 00                	push   $0x0
  pushl $64
80106bf8:	6a 40                	push   $0x40
  jmp alltraps
80106bfa:	e9 35 f7 ff ff       	jmp    80106334 <alltraps>

80106bff <vector65>:
.globl vector65
vector65:
  pushl $0
80106bff:	6a 00                	push   $0x0
  pushl $65
80106c01:	6a 41                	push   $0x41
  jmp alltraps
80106c03:	e9 2c f7 ff ff       	jmp    80106334 <alltraps>

80106c08 <vector66>:
.globl vector66
vector66:
  pushl $0
80106c08:	6a 00                	push   $0x0
  pushl $66
80106c0a:	6a 42                	push   $0x42
  jmp alltraps
80106c0c:	e9 23 f7 ff ff       	jmp    80106334 <alltraps>

80106c11 <vector67>:
.globl vector67
vector67:
  pushl $0
80106c11:	6a 00                	push   $0x0
  pushl $67
80106c13:	6a 43                	push   $0x43
  jmp alltraps
80106c15:	e9 1a f7 ff ff       	jmp    80106334 <alltraps>

80106c1a <vector68>:
.globl vector68
vector68:
  pushl $0
80106c1a:	6a 00                	push   $0x0
  pushl $68
80106c1c:	6a 44                	push   $0x44
  jmp alltraps
80106c1e:	e9 11 f7 ff ff       	jmp    80106334 <alltraps>

80106c23 <vector69>:
.globl vector69
vector69:
  pushl $0
80106c23:	6a 00                	push   $0x0
  pushl $69
80106c25:	6a 45                	push   $0x45
  jmp alltraps
80106c27:	e9 08 f7 ff ff       	jmp    80106334 <alltraps>

80106c2c <vector70>:
.globl vector70
vector70:
  pushl $0
80106c2c:	6a 00                	push   $0x0
  pushl $70
80106c2e:	6a 46                	push   $0x46
  jmp alltraps
80106c30:	e9 ff f6 ff ff       	jmp    80106334 <alltraps>

80106c35 <vector71>:
.globl vector71
vector71:
  pushl $0
80106c35:	6a 00                	push   $0x0
  pushl $71
80106c37:	6a 47                	push   $0x47
  jmp alltraps
80106c39:	e9 f6 f6 ff ff       	jmp    80106334 <alltraps>

80106c3e <vector72>:
.globl vector72
vector72:
  pushl $0
80106c3e:	6a 00                	push   $0x0
  pushl $72
80106c40:	6a 48                	push   $0x48
  jmp alltraps
80106c42:	e9 ed f6 ff ff       	jmp    80106334 <alltraps>

80106c47 <vector73>:
.globl vector73
vector73:
  pushl $0
80106c47:	6a 00                	push   $0x0
  pushl $73
80106c49:	6a 49                	push   $0x49
  jmp alltraps
80106c4b:	e9 e4 f6 ff ff       	jmp    80106334 <alltraps>

80106c50 <vector74>:
.globl vector74
vector74:
  pushl $0
80106c50:	6a 00                	push   $0x0
  pushl $74
80106c52:	6a 4a                	push   $0x4a
  jmp alltraps
80106c54:	e9 db f6 ff ff       	jmp    80106334 <alltraps>

80106c59 <vector75>:
.globl vector75
vector75:
  pushl $0
80106c59:	6a 00                	push   $0x0
  pushl $75
80106c5b:	6a 4b                	push   $0x4b
  jmp alltraps
80106c5d:	e9 d2 f6 ff ff       	jmp    80106334 <alltraps>

80106c62 <vector76>:
.globl vector76
vector76:
  pushl $0
80106c62:	6a 00                	push   $0x0
  pushl $76
80106c64:	6a 4c                	push   $0x4c
  jmp alltraps
80106c66:	e9 c9 f6 ff ff       	jmp    80106334 <alltraps>

80106c6b <vector77>:
.globl vector77
vector77:
  pushl $0
80106c6b:	6a 00                	push   $0x0
  pushl $77
80106c6d:	6a 4d                	push   $0x4d
  jmp alltraps
80106c6f:	e9 c0 f6 ff ff       	jmp    80106334 <alltraps>

80106c74 <vector78>:
.globl vector78
vector78:
  pushl $0
80106c74:	6a 00                	push   $0x0
  pushl $78
80106c76:	6a 4e                	push   $0x4e
  jmp alltraps
80106c78:	e9 b7 f6 ff ff       	jmp    80106334 <alltraps>

80106c7d <vector79>:
.globl vector79
vector79:
  pushl $0
80106c7d:	6a 00                	push   $0x0
  pushl $79
80106c7f:	6a 4f                	push   $0x4f
  jmp alltraps
80106c81:	e9 ae f6 ff ff       	jmp    80106334 <alltraps>

80106c86 <vector80>:
.globl vector80
vector80:
  pushl $0
80106c86:	6a 00                	push   $0x0
  pushl $80
80106c88:	6a 50                	push   $0x50
  jmp alltraps
80106c8a:	e9 a5 f6 ff ff       	jmp    80106334 <alltraps>

80106c8f <vector81>:
.globl vector81
vector81:
  pushl $0
80106c8f:	6a 00                	push   $0x0
  pushl $81
80106c91:	6a 51                	push   $0x51
  jmp alltraps
80106c93:	e9 9c f6 ff ff       	jmp    80106334 <alltraps>

80106c98 <vector82>:
.globl vector82
vector82:
  pushl $0
80106c98:	6a 00                	push   $0x0
  pushl $82
80106c9a:	6a 52                	push   $0x52
  jmp alltraps
80106c9c:	e9 93 f6 ff ff       	jmp    80106334 <alltraps>

80106ca1 <vector83>:
.globl vector83
vector83:
  pushl $0
80106ca1:	6a 00                	push   $0x0
  pushl $83
80106ca3:	6a 53                	push   $0x53
  jmp alltraps
80106ca5:	e9 8a f6 ff ff       	jmp    80106334 <alltraps>

80106caa <vector84>:
.globl vector84
vector84:
  pushl $0
80106caa:	6a 00                	push   $0x0
  pushl $84
80106cac:	6a 54                	push   $0x54
  jmp alltraps
80106cae:	e9 81 f6 ff ff       	jmp    80106334 <alltraps>

80106cb3 <vector85>:
.globl vector85
vector85:
  pushl $0
80106cb3:	6a 00                	push   $0x0
  pushl $85
80106cb5:	6a 55                	push   $0x55
  jmp alltraps
80106cb7:	e9 78 f6 ff ff       	jmp    80106334 <alltraps>

80106cbc <vector86>:
.globl vector86
vector86:
  pushl $0
80106cbc:	6a 00                	push   $0x0
  pushl $86
80106cbe:	6a 56                	push   $0x56
  jmp alltraps
80106cc0:	e9 6f f6 ff ff       	jmp    80106334 <alltraps>

80106cc5 <vector87>:
.globl vector87
vector87:
  pushl $0
80106cc5:	6a 00                	push   $0x0
  pushl $87
80106cc7:	6a 57                	push   $0x57
  jmp alltraps
80106cc9:	e9 66 f6 ff ff       	jmp    80106334 <alltraps>

80106cce <vector88>:
.globl vector88
vector88:
  pushl $0
80106cce:	6a 00                	push   $0x0
  pushl $88
80106cd0:	6a 58                	push   $0x58
  jmp alltraps
80106cd2:	e9 5d f6 ff ff       	jmp    80106334 <alltraps>

80106cd7 <vector89>:
.globl vector89
vector89:
  pushl $0
80106cd7:	6a 00                	push   $0x0
  pushl $89
80106cd9:	6a 59                	push   $0x59
  jmp alltraps
80106cdb:	e9 54 f6 ff ff       	jmp    80106334 <alltraps>

80106ce0 <vector90>:
.globl vector90
vector90:
  pushl $0
80106ce0:	6a 00                	push   $0x0
  pushl $90
80106ce2:	6a 5a                	push   $0x5a
  jmp alltraps
80106ce4:	e9 4b f6 ff ff       	jmp    80106334 <alltraps>

80106ce9 <vector91>:
.globl vector91
vector91:
  pushl $0
80106ce9:	6a 00                	push   $0x0
  pushl $91
80106ceb:	6a 5b                	push   $0x5b
  jmp alltraps
80106ced:	e9 42 f6 ff ff       	jmp    80106334 <alltraps>

80106cf2 <vector92>:
.globl vector92
vector92:
  pushl $0
80106cf2:	6a 00                	push   $0x0
  pushl $92
80106cf4:	6a 5c                	push   $0x5c
  jmp alltraps
80106cf6:	e9 39 f6 ff ff       	jmp    80106334 <alltraps>

80106cfb <vector93>:
.globl vector93
vector93:
  pushl $0
80106cfb:	6a 00                	push   $0x0
  pushl $93
80106cfd:	6a 5d                	push   $0x5d
  jmp alltraps
80106cff:	e9 30 f6 ff ff       	jmp    80106334 <alltraps>

80106d04 <vector94>:
.globl vector94
vector94:
  pushl $0
80106d04:	6a 00                	push   $0x0
  pushl $94
80106d06:	6a 5e                	push   $0x5e
  jmp alltraps
80106d08:	e9 27 f6 ff ff       	jmp    80106334 <alltraps>

80106d0d <vector95>:
.globl vector95
vector95:
  pushl $0
80106d0d:	6a 00                	push   $0x0
  pushl $95
80106d0f:	6a 5f                	push   $0x5f
  jmp alltraps
80106d11:	e9 1e f6 ff ff       	jmp    80106334 <alltraps>

80106d16 <vector96>:
.globl vector96
vector96:
  pushl $0
80106d16:	6a 00                	push   $0x0
  pushl $96
80106d18:	6a 60                	push   $0x60
  jmp alltraps
80106d1a:	e9 15 f6 ff ff       	jmp    80106334 <alltraps>

80106d1f <vector97>:
.globl vector97
vector97:
  pushl $0
80106d1f:	6a 00                	push   $0x0
  pushl $97
80106d21:	6a 61                	push   $0x61
  jmp alltraps
80106d23:	e9 0c f6 ff ff       	jmp    80106334 <alltraps>

80106d28 <vector98>:
.globl vector98
vector98:
  pushl $0
80106d28:	6a 00                	push   $0x0
  pushl $98
80106d2a:	6a 62                	push   $0x62
  jmp alltraps
80106d2c:	e9 03 f6 ff ff       	jmp    80106334 <alltraps>

80106d31 <vector99>:
.globl vector99
vector99:
  pushl $0
80106d31:	6a 00                	push   $0x0
  pushl $99
80106d33:	6a 63                	push   $0x63
  jmp alltraps
80106d35:	e9 fa f5 ff ff       	jmp    80106334 <alltraps>

80106d3a <vector100>:
.globl vector100
vector100:
  pushl $0
80106d3a:	6a 00                	push   $0x0
  pushl $100
80106d3c:	6a 64                	push   $0x64
  jmp alltraps
80106d3e:	e9 f1 f5 ff ff       	jmp    80106334 <alltraps>

80106d43 <vector101>:
.globl vector101
vector101:
  pushl $0
80106d43:	6a 00                	push   $0x0
  pushl $101
80106d45:	6a 65                	push   $0x65
  jmp alltraps
80106d47:	e9 e8 f5 ff ff       	jmp    80106334 <alltraps>

80106d4c <vector102>:
.globl vector102
vector102:
  pushl $0
80106d4c:	6a 00                	push   $0x0
  pushl $102
80106d4e:	6a 66                	push   $0x66
  jmp alltraps
80106d50:	e9 df f5 ff ff       	jmp    80106334 <alltraps>

80106d55 <vector103>:
.globl vector103
vector103:
  pushl $0
80106d55:	6a 00                	push   $0x0
  pushl $103
80106d57:	6a 67                	push   $0x67
  jmp alltraps
80106d59:	e9 d6 f5 ff ff       	jmp    80106334 <alltraps>

80106d5e <vector104>:
.globl vector104
vector104:
  pushl $0
80106d5e:	6a 00                	push   $0x0
  pushl $104
80106d60:	6a 68                	push   $0x68
  jmp alltraps
80106d62:	e9 cd f5 ff ff       	jmp    80106334 <alltraps>

80106d67 <vector105>:
.globl vector105
vector105:
  pushl $0
80106d67:	6a 00                	push   $0x0
  pushl $105
80106d69:	6a 69                	push   $0x69
  jmp alltraps
80106d6b:	e9 c4 f5 ff ff       	jmp    80106334 <alltraps>

80106d70 <vector106>:
.globl vector106
vector106:
  pushl $0
80106d70:	6a 00                	push   $0x0
  pushl $106
80106d72:	6a 6a                	push   $0x6a
  jmp alltraps
80106d74:	e9 bb f5 ff ff       	jmp    80106334 <alltraps>

80106d79 <vector107>:
.globl vector107
vector107:
  pushl $0
80106d79:	6a 00                	push   $0x0
  pushl $107
80106d7b:	6a 6b                	push   $0x6b
  jmp alltraps
80106d7d:	e9 b2 f5 ff ff       	jmp    80106334 <alltraps>

80106d82 <vector108>:
.globl vector108
vector108:
  pushl $0
80106d82:	6a 00                	push   $0x0
  pushl $108
80106d84:	6a 6c                	push   $0x6c
  jmp alltraps
80106d86:	e9 a9 f5 ff ff       	jmp    80106334 <alltraps>

80106d8b <vector109>:
.globl vector109
vector109:
  pushl $0
80106d8b:	6a 00                	push   $0x0
  pushl $109
80106d8d:	6a 6d                	push   $0x6d
  jmp alltraps
80106d8f:	e9 a0 f5 ff ff       	jmp    80106334 <alltraps>

80106d94 <vector110>:
.globl vector110
vector110:
  pushl $0
80106d94:	6a 00                	push   $0x0
  pushl $110
80106d96:	6a 6e                	push   $0x6e
  jmp alltraps
80106d98:	e9 97 f5 ff ff       	jmp    80106334 <alltraps>

80106d9d <vector111>:
.globl vector111
vector111:
  pushl $0
80106d9d:	6a 00                	push   $0x0
  pushl $111
80106d9f:	6a 6f                	push   $0x6f
  jmp alltraps
80106da1:	e9 8e f5 ff ff       	jmp    80106334 <alltraps>

80106da6 <vector112>:
.globl vector112
vector112:
  pushl $0
80106da6:	6a 00                	push   $0x0
  pushl $112
80106da8:	6a 70                	push   $0x70
  jmp alltraps
80106daa:	e9 85 f5 ff ff       	jmp    80106334 <alltraps>

80106daf <vector113>:
.globl vector113
vector113:
  pushl $0
80106daf:	6a 00                	push   $0x0
  pushl $113
80106db1:	6a 71                	push   $0x71
  jmp alltraps
80106db3:	e9 7c f5 ff ff       	jmp    80106334 <alltraps>

80106db8 <vector114>:
.globl vector114
vector114:
  pushl $0
80106db8:	6a 00                	push   $0x0
  pushl $114
80106dba:	6a 72                	push   $0x72
  jmp alltraps
80106dbc:	e9 73 f5 ff ff       	jmp    80106334 <alltraps>

80106dc1 <vector115>:
.globl vector115
vector115:
  pushl $0
80106dc1:	6a 00                	push   $0x0
  pushl $115
80106dc3:	6a 73                	push   $0x73
  jmp alltraps
80106dc5:	e9 6a f5 ff ff       	jmp    80106334 <alltraps>

80106dca <vector116>:
.globl vector116
vector116:
  pushl $0
80106dca:	6a 00                	push   $0x0
  pushl $116
80106dcc:	6a 74                	push   $0x74
  jmp alltraps
80106dce:	e9 61 f5 ff ff       	jmp    80106334 <alltraps>

80106dd3 <vector117>:
.globl vector117
vector117:
  pushl $0
80106dd3:	6a 00                	push   $0x0
  pushl $117
80106dd5:	6a 75                	push   $0x75
  jmp alltraps
80106dd7:	e9 58 f5 ff ff       	jmp    80106334 <alltraps>

80106ddc <vector118>:
.globl vector118
vector118:
  pushl $0
80106ddc:	6a 00                	push   $0x0
  pushl $118
80106dde:	6a 76                	push   $0x76
  jmp alltraps
80106de0:	e9 4f f5 ff ff       	jmp    80106334 <alltraps>

80106de5 <vector119>:
.globl vector119
vector119:
  pushl $0
80106de5:	6a 00                	push   $0x0
  pushl $119
80106de7:	6a 77                	push   $0x77
  jmp alltraps
80106de9:	e9 46 f5 ff ff       	jmp    80106334 <alltraps>

80106dee <vector120>:
.globl vector120
vector120:
  pushl $0
80106dee:	6a 00                	push   $0x0
  pushl $120
80106df0:	6a 78                	push   $0x78
  jmp alltraps
80106df2:	e9 3d f5 ff ff       	jmp    80106334 <alltraps>

80106df7 <vector121>:
.globl vector121
vector121:
  pushl $0
80106df7:	6a 00                	push   $0x0
  pushl $121
80106df9:	6a 79                	push   $0x79
  jmp alltraps
80106dfb:	e9 34 f5 ff ff       	jmp    80106334 <alltraps>

80106e00 <vector122>:
.globl vector122
vector122:
  pushl $0
80106e00:	6a 00                	push   $0x0
  pushl $122
80106e02:	6a 7a                	push   $0x7a
  jmp alltraps
80106e04:	e9 2b f5 ff ff       	jmp    80106334 <alltraps>

80106e09 <vector123>:
.globl vector123
vector123:
  pushl $0
80106e09:	6a 00                	push   $0x0
  pushl $123
80106e0b:	6a 7b                	push   $0x7b
  jmp alltraps
80106e0d:	e9 22 f5 ff ff       	jmp    80106334 <alltraps>

80106e12 <vector124>:
.globl vector124
vector124:
  pushl $0
80106e12:	6a 00                	push   $0x0
  pushl $124
80106e14:	6a 7c                	push   $0x7c
  jmp alltraps
80106e16:	e9 19 f5 ff ff       	jmp    80106334 <alltraps>

80106e1b <vector125>:
.globl vector125
vector125:
  pushl $0
80106e1b:	6a 00                	push   $0x0
  pushl $125
80106e1d:	6a 7d                	push   $0x7d
  jmp alltraps
80106e1f:	e9 10 f5 ff ff       	jmp    80106334 <alltraps>

80106e24 <vector126>:
.globl vector126
vector126:
  pushl $0
80106e24:	6a 00                	push   $0x0
  pushl $126
80106e26:	6a 7e                	push   $0x7e
  jmp alltraps
80106e28:	e9 07 f5 ff ff       	jmp    80106334 <alltraps>

80106e2d <vector127>:
.globl vector127
vector127:
  pushl $0
80106e2d:	6a 00                	push   $0x0
  pushl $127
80106e2f:	6a 7f                	push   $0x7f
  jmp alltraps
80106e31:	e9 fe f4 ff ff       	jmp    80106334 <alltraps>

80106e36 <vector128>:
.globl vector128
vector128:
  pushl $0
80106e36:	6a 00                	push   $0x0
  pushl $128
80106e38:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80106e3d:	e9 f2 f4 ff ff       	jmp    80106334 <alltraps>

80106e42 <vector129>:
.globl vector129
vector129:
  pushl $0
80106e42:	6a 00                	push   $0x0
  pushl $129
80106e44:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80106e49:	e9 e6 f4 ff ff       	jmp    80106334 <alltraps>

80106e4e <vector130>:
.globl vector130
vector130:
  pushl $0
80106e4e:	6a 00                	push   $0x0
  pushl $130
80106e50:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80106e55:	e9 da f4 ff ff       	jmp    80106334 <alltraps>

80106e5a <vector131>:
.globl vector131
vector131:
  pushl $0
80106e5a:	6a 00                	push   $0x0
  pushl $131
80106e5c:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80106e61:	e9 ce f4 ff ff       	jmp    80106334 <alltraps>

80106e66 <vector132>:
.globl vector132
vector132:
  pushl $0
80106e66:	6a 00                	push   $0x0
  pushl $132
80106e68:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80106e6d:	e9 c2 f4 ff ff       	jmp    80106334 <alltraps>

80106e72 <vector133>:
.globl vector133
vector133:
  pushl $0
80106e72:	6a 00                	push   $0x0
  pushl $133
80106e74:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80106e79:	e9 b6 f4 ff ff       	jmp    80106334 <alltraps>

80106e7e <vector134>:
.globl vector134
vector134:
  pushl $0
80106e7e:	6a 00                	push   $0x0
  pushl $134
80106e80:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80106e85:	e9 aa f4 ff ff       	jmp    80106334 <alltraps>

80106e8a <vector135>:
.globl vector135
vector135:
  pushl $0
80106e8a:	6a 00                	push   $0x0
  pushl $135
80106e8c:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80106e91:	e9 9e f4 ff ff       	jmp    80106334 <alltraps>

80106e96 <vector136>:
.globl vector136
vector136:
  pushl $0
80106e96:	6a 00                	push   $0x0
  pushl $136
80106e98:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80106e9d:	e9 92 f4 ff ff       	jmp    80106334 <alltraps>

80106ea2 <vector137>:
.globl vector137
vector137:
  pushl $0
80106ea2:	6a 00                	push   $0x0
  pushl $137
80106ea4:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80106ea9:	e9 86 f4 ff ff       	jmp    80106334 <alltraps>

80106eae <vector138>:
.globl vector138
vector138:
  pushl $0
80106eae:	6a 00                	push   $0x0
  pushl $138
80106eb0:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80106eb5:	e9 7a f4 ff ff       	jmp    80106334 <alltraps>

80106eba <vector139>:
.globl vector139
vector139:
  pushl $0
80106eba:	6a 00                	push   $0x0
  pushl $139
80106ebc:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80106ec1:	e9 6e f4 ff ff       	jmp    80106334 <alltraps>

80106ec6 <vector140>:
.globl vector140
vector140:
  pushl $0
80106ec6:	6a 00                	push   $0x0
  pushl $140
80106ec8:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80106ecd:	e9 62 f4 ff ff       	jmp    80106334 <alltraps>

80106ed2 <vector141>:
.globl vector141
vector141:
  pushl $0
80106ed2:	6a 00                	push   $0x0
  pushl $141
80106ed4:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80106ed9:	e9 56 f4 ff ff       	jmp    80106334 <alltraps>

80106ede <vector142>:
.globl vector142
vector142:
  pushl $0
80106ede:	6a 00                	push   $0x0
  pushl $142
80106ee0:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80106ee5:	e9 4a f4 ff ff       	jmp    80106334 <alltraps>

80106eea <vector143>:
.globl vector143
vector143:
  pushl $0
80106eea:	6a 00                	push   $0x0
  pushl $143
80106eec:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80106ef1:	e9 3e f4 ff ff       	jmp    80106334 <alltraps>

80106ef6 <vector144>:
.globl vector144
vector144:
  pushl $0
80106ef6:	6a 00                	push   $0x0
  pushl $144
80106ef8:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80106efd:	e9 32 f4 ff ff       	jmp    80106334 <alltraps>

80106f02 <vector145>:
.globl vector145
vector145:
  pushl $0
80106f02:	6a 00                	push   $0x0
  pushl $145
80106f04:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80106f09:	e9 26 f4 ff ff       	jmp    80106334 <alltraps>

80106f0e <vector146>:
.globl vector146
vector146:
  pushl $0
80106f0e:	6a 00                	push   $0x0
  pushl $146
80106f10:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80106f15:	e9 1a f4 ff ff       	jmp    80106334 <alltraps>

80106f1a <vector147>:
.globl vector147
vector147:
  pushl $0
80106f1a:	6a 00                	push   $0x0
  pushl $147
80106f1c:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80106f21:	e9 0e f4 ff ff       	jmp    80106334 <alltraps>

80106f26 <vector148>:
.globl vector148
vector148:
  pushl $0
80106f26:	6a 00                	push   $0x0
  pushl $148
80106f28:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80106f2d:	e9 02 f4 ff ff       	jmp    80106334 <alltraps>

80106f32 <vector149>:
.globl vector149
vector149:
  pushl $0
80106f32:	6a 00                	push   $0x0
  pushl $149
80106f34:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80106f39:	e9 f6 f3 ff ff       	jmp    80106334 <alltraps>

80106f3e <vector150>:
.globl vector150
vector150:
  pushl $0
80106f3e:	6a 00                	push   $0x0
  pushl $150
80106f40:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80106f45:	e9 ea f3 ff ff       	jmp    80106334 <alltraps>

80106f4a <vector151>:
.globl vector151
vector151:
  pushl $0
80106f4a:	6a 00                	push   $0x0
  pushl $151
80106f4c:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80106f51:	e9 de f3 ff ff       	jmp    80106334 <alltraps>

80106f56 <vector152>:
.globl vector152
vector152:
  pushl $0
80106f56:	6a 00                	push   $0x0
  pushl $152
80106f58:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80106f5d:	e9 d2 f3 ff ff       	jmp    80106334 <alltraps>

80106f62 <vector153>:
.globl vector153
vector153:
  pushl $0
80106f62:	6a 00                	push   $0x0
  pushl $153
80106f64:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80106f69:	e9 c6 f3 ff ff       	jmp    80106334 <alltraps>

80106f6e <vector154>:
.globl vector154
vector154:
  pushl $0
80106f6e:	6a 00                	push   $0x0
  pushl $154
80106f70:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80106f75:	e9 ba f3 ff ff       	jmp    80106334 <alltraps>

80106f7a <vector155>:
.globl vector155
vector155:
  pushl $0
80106f7a:	6a 00                	push   $0x0
  pushl $155
80106f7c:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80106f81:	e9 ae f3 ff ff       	jmp    80106334 <alltraps>

80106f86 <vector156>:
.globl vector156
vector156:
  pushl $0
80106f86:	6a 00                	push   $0x0
  pushl $156
80106f88:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80106f8d:	e9 a2 f3 ff ff       	jmp    80106334 <alltraps>

80106f92 <vector157>:
.globl vector157
vector157:
  pushl $0
80106f92:	6a 00                	push   $0x0
  pushl $157
80106f94:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80106f99:	e9 96 f3 ff ff       	jmp    80106334 <alltraps>

80106f9e <vector158>:
.globl vector158
vector158:
  pushl $0
80106f9e:	6a 00                	push   $0x0
  pushl $158
80106fa0:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80106fa5:	e9 8a f3 ff ff       	jmp    80106334 <alltraps>

80106faa <vector159>:
.globl vector159
vector159:
  pushl $0
80106faa:	6a 00                	push   $0x0
  pushl $159
80106fac:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80106fb1:	e9 7e f3 ff ff       	jmp    80106334 <alltraps>

80106fb6 <vector160>:
.globl vector160
vector160:
  pushl $0
80106fb6:	6a 00                	push   $0x0
  pushl $160
80106fb8:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80106fbd:	e9 72 f3 ff ff       	jmp    80106334 <alltraps>

80106fc2 <vector161>:
.globl vector161
vector161:
  pushl $0
80106fc2:	6a 00                	push   $0x0
  pushl $161
80106fc4:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80106fc9:	e9 66 f3 ff ff       	jmp    80106334 <alltraps>

80106fce <vector162>:
.globl vector162
vector162:
  pushl $0
80106fce:	6a 00                	push   $0x0
  pushl $162
80106fd0:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80106fd5:	e9 5a f3 ff ff       	jmp    80106334 <alltraps>

80106fda <vector163>:
.globl vector163
vector163:
  pushl $0
80106fda:	6a 00                	push   $0x0
  pushl $163
80106fdc:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80106fe1:	e9 4e f3 ff ff       	jmp    80106334 <alltraps>

80106fe6 <vector164>:
.globl vector164
vector164:
  pushl $0
80106fe6:	6a 00                	push   $0x0
  pushl $164
80106fe8:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80106fed:	e9 42 f3 ff ff       	jmp    80106334 <alltraps>

80106ff2 <vector165>:
.globl vector165
vector165:
  pushl $0
80106ff2:	6a 00                	push   $0x0
  pushl $165
80106ff4:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80106ff9:	e9 36 f3 ff ff       	jmp    80106334 <alltraps>

80106ffe <vector166>:
.globl vector166
vector166:
  pushl $0
80106ffe:	6a 00                	push   $0x0
  pushl $166
80107000:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107005:	e9 2a f3 ff ff       	jmp    80106334 <alltraps>

8010700a <vector167>:
.globl vector167
vector167:
  pushl $0
8010700a:	6a 00                	push   $0x0
  pushl $167
8010700c:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107011:	e9 1e f3 ff ff       	jmp    80106334 <alltraps>

80107016 <vector168>:
.globl vector168
vector168:
  pushl $0
80107016:	6a 00                	push   $0x0
  pushl $168
80107018:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
8010701d:	e9 12 f3 ff ff       	jmp    80106334 <alltraps>

80107022 <vector169>:
.globl vector169
vector169:
  pushl $0
80107022:	6a 00                	push   $0x0
  pushl $169
80107024:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107029:	e9 06 f3 ff ff       	jmp    80106334 <alltraps>

8010702e <vector170>:
.globl vector170
vector170:
  pushl $0
8010702e:	6a 00                	push   $0x0
  pushl $170
80107030:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107035:	e9 fa f2 ff ff       	jmp    80106334 <alltraps>

8010703a <vector171>:
.globl vector171
vector171:
  pushl $0
8010703a:	6a 00                	push   $0x0
  pushl $171
8010703c:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107041:	e9 ee f2 ff ff       	jmp    80106334 <alltraps>

80107046 <vector172>:
.globl vector172
vector172:
  pushl $0
80107046:	6a 00                	push   $0x0
  pushl $172
80107048:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
8010704d:	e9 e2 f2 ff ff       	jmp    80106334 <alltraps>

80107052 <vector173>:
.globl vector173
vector173:
  pushl $0
80107052:	6a 00                	push   $0x0
  pushl $173
80107054:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107059:	e9 d6 f2 ff ff       	jmp    80106334 <alltraps>

8010705e <vector174>:
.globl vector174
vector174:
  pushl $0
8010705e:	6a 00                	push   $0x0
  pushl $174
80107060:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107065:	e9 ca f2 ff ff       	jmp    80106334 <alltraps>

8010706a <vector175>:
.globl vector175
vector175:
  pushl $0
8010706a:	6a 00                	push   $0x0
  pushl $175
8010706c:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107071:	e9 be f2 ff ff       	jmp    80106334 <alltraps>

80107076 <vector176>:
.globl vector176
vector176:
  pushl $0
80107076:	6a 00                	push   $0x0
  pushl $176
80107078:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
8010707d:	e9 b2 f2 ff ff       	jmp    80106334 <alltraps>

80107082 <vector177>:
.globl vector177
vector177:
  pushl $0
80107082:	6a 00                	push   $0x0
  pushl $177
80107084:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107089:	e9 a6 f2 ff ff       	jmp    80106334 <alltraps>

8010708e <vector178>:
.globl vector178
vector178:
  pushl $0
8010708e:	6a 00                	push   $0x0
  pushl $178
80107090:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107095:	e9 9a f2 ff ff       	jmp    80106334 <alltraps>

8010709a <vector179>:
.globl vector179
vector179:
  pushl $0
8010709a:	6a 00                	push   $0x0
  pushl $179
8010709c:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801070a1:	e9 8e f2 ff ff       	jmp    80106334 <alltraps>

801070a6 <vector180>:
.globl vector180
vector180:
  pushl $0
801070a6:	6a 00                	push   $0x0
  pushl $180
801070a8:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801070ad:	e9 82 f2 ff ff       	jmp    80106334 <alltraps>

801070b2 <vector181>:
.globl vector181
vector181:
  pushl $0
801070b2:	6a 00                	push   $0x0
  pushl $181
801070b4:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801070b9:	e9 76 f2 ff ff       	jmp    80106334 <alltraps>

801070be <vector182>:
.globl vector182
vector182:
  pushl $0
801070be:	6a 00                	push   $0x0
  pushl $182
801070c0:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801070c5:	e9 6a f2 ff ff       	jmp    80106334 <alltraps>

801070ca <vector183>:
.globl vector183
vector183:
  pushl $0
801070ca:	6a 00                	push   $0x0
  pushl $183
801070cc:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801070d1:	e9 5e f2 ff ff       	jmp    80106334 <alltraps>

801070d6 <vector184>:
.globl vector184
vector184:
  pushl $0
801070d6:	6a 00                	push   $0x0
  pushl $184
801070d8:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801070dd:	e9 52 f2 ff ff       	jmp    80106334 <alltraps>

801070e2 <vector185>:
.globl vector185
vector185:
  pushl $0
801070e2:	6a 00                	push   $0x0
  pushl $185
801070e4:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801070e9:	e9 46 f2 ff ff       	jmp    80106334 <alltraps>

801070ee <vector186>:
.globl vector186
vector186:
  pushl $0
801070ee:	6a 00                	push   $0x0
  pushl $186
801070f0:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801070f5:	e9 3a f2 ff ff       	jmp    80106334 <alltraps>

801070fa <vector187>:
.globl vector187
vector187:
  pushl $0
801070fa:	6a 00                	push   $0x0
  pushl $187
801070fc:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107101:	e9 2e f2 ff ff       	jmp    80106334 <alltraps>

80107106 <vector188>:
.globl vector188
vector188:
  pushl $0
80107106:	6a 00                	push   $0x0
  pushl $188
80107108:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
8010710d:	e9 22 f2 ff ff       	jmp    80106334 <alltraps>

80107112 <vector189>:
.globl vector189
vector189:
  pushl $0
80107112:	6a 00                	push   $0x0
  pushl $189
80107114:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107119:	e9 16 f2 ff ff       	jmp    80106334 <alltraps>

8010711e <vector190>:
.globl vector190
vector190:
  pushl $0
8010711e:	6a 00                	push   $0x0
  pushl $190
80107120:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107125:	e9 0a f2 ff ff       	jmp    80106334 <alltraps>

8010712a <vector191>:
.globl vector191
vector191:
  pushl $0
8010712a:	6a 00                	push   $0x0
  pushl $191
8010712c:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107131:	e9 fe f1 ff ff       	jmp    80106334 <alltraps>

80107136 <vector192>:
.globl vector192
vector192:
  pushl $0
80107136:	6a 00                	push   $0x0
  pushl $192
80107138:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
8010713d:	e9 f2 f1 ff ff       	jmp    80106334 <alltraps>

80107142 <vector193>:
.globl vector193
vector193:
  pushl $0
80107142:	6a 00                	push   $0x0
  pushl $193
80107144:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107149:	e9 e6 f1 ff ff       	jmp    80106334 <alltraps>

8010714e <vector194>:
.globl vector194
vector194:
  pushl $0
8010714e:	6a 00                	push   $0x0
  pushl $194
80107150:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107155:	e9 da f1 ff ff       	jmp    80106334 <alltraps>

8010715a <vector195>:
.globl vector195
vector195:
  pushl $0
8010715a:	6a 00                	push   $0x0
  pushl $195
8010715c:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107161:	e9 ce f1 ff ff       	jmp    80106334 <alltraps>

80107166 <vector196>:
.globl vector196
vector196:
  pushl $0
80107166:	6a 00                	push   $0x0
  pushl $196
80107168:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
8010716d:	e9 c2 f1 ff ff       	jmp    80106334 <alltraps>

80107172 <vector197>:
.globl vector197
vector197:
  pushl $0
80107172:	6a 00                	push   $0x0
  pushl $197
80107174:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107179:	e9 b6 f1 ff ff       	jmp    80106334 <alltraps>

8010717e <vector198>:
.globl vector198
vector198:
  pushl $0
8010717e:	6a 00                	push   $0x0
  pushl $198
80107180:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107185:	e9 aa f1 ff ff       	jmp    80106334 <alltraps>

8010718a <vector199>:
.globl vector199
vector199:
  pushl $0
8010718a:	6a 00                	push   $0x0
  pushl $199
8010718c:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107191:	e9 9e f1 ff ff       	jmp    80106334 <alltraps>

80107196 <vector200>:
.globl vector200
vector200:
  pushl $0
80107196:	6a 00                	push   $0x0
  pushl $200
80107198:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
8010719d:	e9 92 f1 ff ff       	jmp    80106334 <alltraps>

801071a2 <vector201>:
.globl vector201
vector201:
  pushl $0
801071a2:	6a 00                	push   $0x0
  pushl $201
801071a4:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801071a9:	e9 86 f1 ff ff       	jmp    80106334 <alltraps>

801071ae <vector202>:
.globl vector202
vector202:
  pushl $0
801071ae:	6a 00                	push   $0x0
  pushl $202
801071b0:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801071b5:	e9 7a f1 ff ff       	jmp    80106334 <alltraps>

801071ba <vector203>:
.globl vector203
vector203:
  pushl $0
801071ba:	6a 00                	push   $0x0
  pushl $203
801071bc:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801071c1:	e9 6e f1 ff ff       	jmp    80106334 <alltraps>

801071c6 <vector204>:
.globl vector204
vector204:
  pushl $0
801071c6:	6a 00                	push   $0x0
  pushl $204
801071c8:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801071cd:	e9 62 f1 ff ff       	jmp    80106334 <alltraps>

801071d2 <vector205>:
.globl vector205
vector205:
  pushl $0
801071d2:	6a 00                	push   $0x0
  pushl $205
801071d4:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
801071d9:	e9 56 f1 ff ff       	jmp    80106334 <alltraps>

801071de <vector206>:
.globl vector206
vector206:
  pushl $0
801071de:	6a 00                	push   $0x0
  pushl $206
801071e0:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
801071e5:	e9 4a f1 ff ff       	jmp    80106334 <alltraps>

801071ea <vector207>:
.globl vector207
vector207:
  pushl $0
801071ea:	6a 00                	push   $0x0
  pushl $207
801071ec:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
801071f1:	e9 3e f1 ff ff       	jmp    80106334 <alltraps>

801071f6 <vector208>:
.globl vector208
vector208:
  pushl $0
801071f6:	6a 00                	push   $0x0
  pushl $208
801071f8:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
801071fd:	e9 32 f1 ff ff       	jmp    80106334 <alltraps>

80107202 <vector209>:
.globl vector209
vector209:
  pushl $0
80107202:	6a 00                	push   $0x0
  pushl $209
80107204:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107209:	e9 26 f1 ff ff       	jmp    80106334 <alltraps>

8010720e <vector210>:
.globl vector210
vector210:
  pushl $0
8010720e:	6a 00                	push   $0x0
  pushl $210
80107210:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107215:	e9 1a f1 ff ff       	jmp    80106334 <alltraps>

8010721a <vector211>:
.globl vector211
vector211:
  pushl $0
8010721a:	6a 00                	push   $0x0
  pushl $211
8010721c:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107221:	e9 0e f1 ff ff       	jmp    80106334 <alltraps>

80107226 <vector212>:
.globl vector212
vector212:
  pushl $0
80107226:	6a 00                	push   $0x0
  pushl $212
80107228:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
8010722d:	e9 02 f1 ff ff       	jmp    80106334 <alltraps>

80107232 <vector213>:
.globl vector213
vector213:
  pushl $0
80107232:	6a 00                	push   $0x0
  pushl $213
80107234:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107239:	e9 f6 f0 ff ff       	jmp    80106334 <alltraps>

8010723e <vector214>:
.globl vector214
vector214:
  pushl $0
8010723e:	6a 00                	push   $0x0
  pushl $214
80107240:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107245:	e9 ea f0 ff ff       	jmp    80106334 <alltraps>

8010724a <vector215>:
.globl vector215
vector215:
  pushl $0
8010724a:	6a 00                	push   $0x0
  pushl $215
8010724c:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107251:	e9 de f0 ff ff       	jmp    80106334 <alltraps>

80107256 <vector216>:
.globl vector216
vector216:
  pushl $0
80107256:	6a 00                	push   $0x0
  pushl $216
80107258:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
8010725d:	e9 d2 f0 ff ff       	jmp    80106334 <alltraps>

80107262 <vector217>:
.globl vector217
vector217:
  pushl $0
80107262:	6a 00                	push   $0x0
  pushl $217
80107264:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107269:	e9 c6 f0 ff ff       	jmp    80106334 <alltraps>

8010726e <vector218>:
.globl vector218
vector218:
  pushl $0
8010726e:	6a 00                	push   $0x0
  pushl $218
80107270:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107275:	e9 ba f0 ff ff       	jmp    80106334 <alltraps>

8010727a <vector219>:
.globl vector219
vector219:
  pushl $0
8010727a:	6a 00                	push   $0x0
  pushl $219
8010727c:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107281:	e9 ae f0 ff ff       	jmp    80106334 <alltraps>

80107286 <vector220>:
.globl vector220
vector220:
  pushl $0
80107286:	6a 00                	push   $0x0
  pushl $220
80107288:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
8010728d:	e9 a2 f0 ff ff       	jmp    80106334 <alltraps>

80107292 <vector221>:
.globl vector221
vector221:
  pushl $0
80107292:	6a 00                	push   $0x0
  pushl $221
80107294:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107299:	e9 96 f0 ff ff       	jmp    80106334 <alltraps>

8010729e <vector222>:
.globl vector222
vector222:
  pushl $0
8010729e:	6a 00                	push   $0x0
  pushl $222
801072a0:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801072a5:	e9 8a f0 ff ff       	jmp    80106334 <alltraps>

801072aa <vector223>:
.globl vector223
vector223:
  pushl $0
801072aa:	6a 00                	push   $0x0
  pushl $223
801072ac:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801072b1:	e9 7e f0 ff ff       	jmp    80106334 <alltraps>

801072b6 <vector224>:
.globl vector224
vector224:
  pushl $0
801072b6:	6a 00                	push   $0x0
  pushl $224
801072b8:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801072bd:	e9 72 f0 ff ff       	jmp    80106334 <alltraps>

801072c2 <vector225>:
.globl vector225
vector225:
  pushl $0
801072c2:	6a 00                	push   $0x0
  pushl $225
801072c4:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801072c9:	e9 66 f0 ff ff       	jmp    80106334 <alltraps>

801072ce <vector226>:
.globl vector226
vector226:
  pushl $0
801072ce:	6a 00                	push   $0x0
  pushl $226
801072d0:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801072d5:	e9 5a f0 ff ff       	jmp    80106334 <alltraps>

801072da <vector227>:
.globl vector227
vector227:
  pushl $0
801072da:	6a 00                	push   $0x0
  pushl $227
801072dc:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801072e1:	e9 4e f0 ff ff       	jmp    80106334 <alltraps>

801072e6 <vector228>:
.globl vector228
vector228:
  pushl $0
801072e6:	6a 00                	push   $0x0
  pushl $228
801072e8:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
801072ed:	e9 42 f0 ff ff       	jmp    80106334 <alltraps>

801072f2 <vector229>:
.globl vector229
vector229:
  pushl $0
801072f2:	6a 00                	push   $0x0
  pushl $229
801072f4:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801072f9:	e9 36 f0 ff ff       	jmp    80106334 <alltraps>

801072fe <vector230>:
.globl vector230
vector230:
  pushl $0
801072fe:	6a 00                	push   $0x0
  pushl $230
80107300:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107305:	e9 2a f0 ff ff       	jmp    80106334 <alltraps>

8010730a <vector231>:
.globl vector231
vector231:
  pushl $0
8010730a:	6a 00                	push   $0x0
  pushl $231
8010730c:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107311:	e9 1e f0 ff ff       	jmp    80106334 <alltraps>

80107316 <vector232>:
.globl vector232
vector232:
  pushl $0
80107316:	6a 00                	push   $0x0
  pushl $232
80107318:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
8010731d:	e9 12 f0 ff ff       	jmp    80106334 <alltraps>

80107322 <vector233>:
.globl vector233
vector233:
  pushl $0
80107322:	6a 00                	push   $0x0
  pushl $233
80107324:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107329:	e9 06 f0 ff ff       	jmp    80106334 <alltraps>

8010732e <vector234>:
.globl vector234
vector234:
  pushl $0
8010732e:	6a 00                	push   $0x0
  pushl $234
80107330:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107335:	e9 fa ef ff ff       	jmp    80106334 <alltraps>

8010733a <vector235>:
.globl vector235
vector235:
  pushl $0
8010733a:	6a 00                	push   $0x0
  pushl $235
8010733c:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107341:	e9 ee ef ff ff       	jmp    80106334 <alltraps>

80107346 <vector236>:
.globl vector236
vector236:
  pushl $0
80107346:	6a 00                	push   $0x0
  pushl $236
80107348:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
8010734d:	e9 e2 ef ff ff       	jmp    80106334 <alltraps>

80107352 <vector237>:
.globl vector237
vector237:
  pushl $0
80107352:	6a 00                	push   $0x0
  pushl $237
80107354:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107359:	e9 d6 ef ff ff       	jmp    80106334 <alltraps>

8010735e <vector238>:
.globl vector238
vector238:
  pushl $0
8010735e:	6a 00                	push   $0x0
  pushl $238
80107360:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107365:	e9 ca ef ff ff       	jmp    80106334 <alltraps>

8010736a <vector239>:
.globl vector239
vector239:
  pushl $0
8010736a:	6a 00                	push   $0x0
  pushl $239
8010736c:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107371:	e9 be ef ff ff       	jmp    80106334 <alltraps>

80107376 <vector240>:
.globl vector240
vector240:
  pushl $0
80107376:	6a 00                	push   $0x0
  pushl $240
80107378:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
8010737d:	e9 b2 ef ff ff       	jmp    80106334 <alltraps>

80107382 <vector241>:
.globl vector241
vector241:
  pushl $0
80107382:	6a 00                	push   $0x0
  pushl $241
80107384:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107389:	e9 a6 ef ff ff       	jmp    80106334 <alltraps>

8010738e <vector242>:
.globl vector242
vector242:
  pushl $0
8010738e:	6a 00                	push   $0x0
  pushl $242
80107390:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107395:	e9 9a ef ff ff       	jmp    80106334 <alltraps>

8010739a <vector243>:
.globl vector243
vector243:
  pushl $0
8010739a:	6a 00                	push   $0x0
  pushl $243
8010739c:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801073a1:	e9 8e ef ff ff       	jmp    80106334 <alltraps>

801073a6 <vector244>:
.globl vector244
vector244:
  pushl $0
801073a6:	6a 00                	push   $0x0
  pushl $244
801073a8:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801073ad:	e9 82 ef ff ff       	jmp    80106334 <alltraps>

801073b2 <vector245>:
.globl vector245
vector245:
  pushl $0
801073b2:	6a 00                	push   $0x0
  pushl $245
801073b4:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801073b9:	e9 76 ef ff ff       	jmp    80106334 <alltraps>

801073be <vector246>:
.globl vector246
vector246:
  pushl $0
801073be:	6a 00                	push   $0x0
  pushl $246
801073c0:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801073c5:	e9 6a ef ff ff       	jmp    80106334 <alltraps>

801073ca <vector247>:
.globl vector247
vector247:
  pushl $0
801073ca:	6a 00                	push   $0x0
  pushl $247
801073cc:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801073d1:	e9 5e ef ff ff       	jmp    80106334 <alltraps>

801073d6 <vector248>:
.globl vector248
vector248:
  pushl $0
801073d6:	6a 00                	push   $0x0
  pushl $248
801073d8:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801073dd:	e9 52 ef ff ff       	jmp    80106334 <alltraps>

801073e2 <vector249>:
.globl vector249
vector249:
  pushl $0
801073e2:	6a 00                	push   $0x0
  pushl $249
801073e4:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801073e9:	e9 46 ef ff ff       	jmp    80106334 <alltraps>

801073ee <vector250>:
.globl vector250
vector250:
  pushl $0
801073ee:	6a 00                	push   $0x0
  pushl $250
801073f0:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801073f5:	e9 3a ef ff ff       	jmp    80106334 <alltraps>

801073fa <vector251>:
.globl vector251
vector251:
  pushl $0
801073fa:	6a 00                	push   $0x0
  pushl $251
801073fc:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107401:	e9 2e ef ff ff       	jmp    80106334 <alltraps>

80107406 <vector252>:
.globl vector252
vector252:
  pushl $0
80107406:	6a 00                	push   $0x0
  pushl $252
80107408:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
8010740d:	e9 22 ef ff ff       	jmp    80106334 <alltraps>

80107412 <vector253>:
.globl vector253
vector253:
  pushl $0
80107412:	6a 00                	push   $0x0
  pushl $253
80107414:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107419:	e9 16 ef ff ff       	jmp    80106334 <alltraps>

8010741e <vector254>:
.globl vector254
vector254:
  pushl $0
8010741e:	6a 00                	push   $0x0
  pushl $254
80107420:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107425:	e9 0a ef ff ff       	jmp    80106334 <alltraps>

8010742a <vector255>:
.globl vector255
vector255:
  pushl $0
8010742a:	6a 00                	push   $0x0
  pushl $255
8010742c:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107431:	e9 fe ee ff ff       	jmp    80106334 <alltraps>
	...

80107438 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107438:	55                   	push   %ebp
80107439:	89 e5                	mov    %esp,%ebp
8010743b:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010743e:	8b 45 0c             	mov    0xc(%ebp),%eax
80107441:	83 e8 01             	sub    $0x1,%eax
80107444:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107448:	8b 45 08             	mov    0x8(%ebp),%eax
8010744b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010744f:	8b 45 08             	mov    0x8(%ebp),%eax
80107452:	c1 e8 10             	shr    $0x10,%eax
80107455:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107459:	8d 45 fa             	lea    -0x6(%ebp),%eax
8010745c:	0f 01 10             	lgdtl  (%eax)
}
8010745f:	c9                   	leave  
80107460:	c3                   	ret    

80107461 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107461:	55                   	push   %ebp
80107462:	89 e5                	mov    %esp,%ebp
80107464:	83 ec 04             	sub    $0x4,%esp
80107467:	8b 45 08             	mov    0x8(%ebp),%eax
8010746a:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
8010746e:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107472:	0f 00 d8             	ltr    %ax
}
80107475:	c9                   	leave  
80107476:	c3                   	ret    

80107477 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107477:	55                   	push   %ebp
80107478:	89 e5                	mov    %esp,%ebp
8010747a:	83 ec 04             	sub    $0x4,%esp
8010747d:	8b 45 08             	mov    0x8(%ebp),%eax
80107480:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107484:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107488:	8e e8                	mov    %eax,%gs
}
8010748a:	c9                   	leave  
8010748b:	c3                   	ret    

8010748c <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
8010748c:	55                   	push   %ebp
8010748d:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010748f:	8b 45 08             	mov    0x8(%ebp),%eax
80107492:	0f 22 d8             	mov    %eax,%cr3
}
80107495:	5d                   	pop    %ebp
80107496:	c3                   	ret    

80107497 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107497:	55                   	push   %ebp
80107498:	89 e5                	mov    %esp,%ebp
8010749a:	8b 45 08             	mov    0x8(%ebp),%eax
8010749d:	05 00 00 00 80       	add    $0x80000000,%eax
801074a2:	5d                   	pop    %ebp
801074a3:	c3                   	ret    

801074a4 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801074a4:	55                   	push   %ebp
801074a5:	89 e5                	mov    %esp,%ebp
801074a7:	8b 45 08             	mov    0x8(%ebp),%eax
801074aa:	05 00 00 00 80       	add    $0x80000000,%eax
801074af:	5d                   	pop    %ebp
801074b0:	c3                   	ret    

801074b1 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801074b1:	55                   	push   %ebp
801074b2:	89 e5                	mov    %esp,%ebp
801074b4:	53                   	push   %ebx
801074b5:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801074b8:	e8 d8 ba ff ff       	call   80102f95 <cpunum>
801074bd:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801074c3:	05 40 fe 10 80       	add    $0x8010fe40,%eax
801074c8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801074cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074ce:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801074d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074d7:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
801074dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074e0:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801074e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074e7:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801074eb:	83 e2 f0             	and    $0xfffffff0,%edx
801074ee:	83 ca 0a             	or     $0xa,%edx
801074f1:	88 50 7d             	mov    %dl,0x7d(%eax)
801074f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074f7:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801074fb:	83 ca 10             	or     $0x10,%edx
801074fe:	88 50 7d             	mov    %dl,0x7d(%eax)
80107501:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107504:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107508:	83 e2 9f             	and    $0xffffff9f,%edx
8010750b:	88 50 7d             	mov    %dl,0x7d(%eax)
8010750e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107511:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107515:	83 ca 80             	or     $0xffffff80,%edx
80107518:	88 50 7d             	mov    %dl,0x7d(%eax)
8010751b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010751e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107522:	83 ca 0f             	or     $0xf,%edx
80107525:	88 50 7e             	mov    %dl,0x7e(%eax)
80107528:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010752b:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010752f:	83 e2 ef             	and    $0xffffffef,%edx
80107532:	88 50 7e             	mov    %dl,0x7e(%eax)
80107535:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107538:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010753c:	83 e2 df             	and    $0xffffffdf,%edx
8010753f:	88 50 7e             	mov    %dl,0x7e(%eax)
80107542:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107545:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107549:	83 ca 40             	or     $0x40,%edx
8010754c:	88 50 7e             	mov    %dl,0x7e(%eax)
8010754f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107552:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107556:	83 ca 80             	or     $0xffffff80,%edx
80107559:	88 50 7e             	mov    %dl,0x7e(%eax)
8010755c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010755f:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107563:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107566:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
8010756d:	ff ff 
8010756f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107572:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80107579:	00 00 
8010757b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010757e:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80107585:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107588:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010758f:	83 e2 f0             	and    $0xfffffff0,%edx
80107592:	83 ca 02             	or     $0x2,%edx
80107595:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010759b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010759e:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801075a5:	83 ca 10             	or     $0x10,%edx
801075a8:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801075ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075b1:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801075b8:	83 e2 9f             	and    $0xffffff9f,%edx
801075bb:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801075c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075c4:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801075cb:	83 ca 80             	or     $0xffffff80,%edx
801075ce:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801075d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075d7:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801075de:	83 ca 0f             	or     $0xf,%edx
801075e1:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801075e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075ea:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801075f1:	83 e2 ef             	and    $0xffffffef,%edx
801075f4:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801075fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075fd:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107604:	83 e2 df             	and    $0xffffffdf,%edx
80107607:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010760d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107610:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107617:	83 ca 40             	or     $0x40,%edx
8010761a:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107620:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107623:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010762a:	83 ca 80             	or     $0xffffff80,%edx
8010762d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107633:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107636:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
8010763d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107640:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80107647:	ff ff 
80107649:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010764c:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107653:	00 00 
80107655:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107658:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
8010765f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107662:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107669:	83 e2 f0             	and    $0xfffffff0,%edx
8010766c:	83 ca 0a             	or     $0xa,%edx
8010766f:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107675:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107678:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010767f:	83 ca 10             	or     $0x10,%edx
80107682:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107688:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010768b:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107692:	83 ca 60             	or     $0x60,%edx
80107695:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010769b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010769e:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801076a5:	83 ca 80             	or     $0xffffff80,%edx
801076a8:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801076ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076b1:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801076b8:	83 ca 0f             	or     $0xf,%edx
801076bb:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801076c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076c4:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801076cb:	83 e2 ef             	and    $0xffffffef,%edx
801076ce:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801076d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076d7:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801076de:	83 e2 df             	and    $0xffffffdf,%edx
801076e1:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801076e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076ea:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801076f1:	83 ca 40             	or     $0x40,%edx
801076f4:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801076fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076fd:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107704:	83 ca 80             	or     $0xffffff80,%edx
80107707:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010770d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107710:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80107717:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010771a:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107721:	ff ff 
80107723:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107726:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
8010772d:	00 00 
8010772f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107732:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80107739:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010773c:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107743:	83 e2 f0             	and    $0xfffffff0,%edx
80107746:	83 ca 02             	or     $0x2,%edx
80107749:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010774f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107752:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107759:	83 ca 10             	or     $0x10,%edx
8010775c:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107762:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107765:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010776c:	83 ca 60             	or     $0x60,%edx
8010776f:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107775:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107778:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010777f:	83 ca 80             	or     $0xffffff80,%edx
80107782:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107788:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010778b:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107792:	83 ca 0f             	or     $0xf,%edx
80107795:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010779b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010779e:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801077a5:	83 e2 ef             	and    $0xffffffef,%edx
801077a8:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801077ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077b1:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801077b8:	83 e2 df             	and    $0xffffffdf,%edx
801077bb:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801077c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077c4:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801077cb:	83 ca 40             	or     $0x40,%edx
801077ce:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801077d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077d7:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801077de:	83 ca 80             	or     $0xffffff80,%edx
801077e1:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801077e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ea:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
801077f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077f4:	05 b4 00 00 00       	add    $0xb4,%eax
801077f9:	89 c3                	mov    %eax,%ebx
801077fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077fe:	05 b4 00 00 00       	add    $0xb4,%eax
80107803:	c1 e8 10             	shr    $0x10,%eax
80107806:	89 c1                	mov    %eax,%ecx
80107808:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010780b:	05 b4 00 00 00       	add    $0xb4,%eax
80107810:	c1 e8 18             	shr    $0x18,%eax
80107813:	89 c2                	mov    %eax,%edx
80107815:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107818:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
8010781f:	00 00 
80107821:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107824:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
8010782b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010782e:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107834:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107837:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010783e:	83 e1 f0             	and    $0xfffffff0,%ecx
80107841:	83 c9 02             	or     $0x2,%ecx
80107844:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010784a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010784d:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107854:	83 c9 10             	or     $0x10,%ecx
80107857:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010785d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107860:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107867:	83 e1 9f             	and    $0xffffff9f,%ecx
8010786a:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107870:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107873:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010787a:	83 c9 80             	or     $0xffffff80,%ecx
8010787d:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107883:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107886:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010788d:	83 e1 f0             	and    $0xfffffff0,%ecx
80107890:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107896:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107899:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801078a0:	83 e1 ef             	and    $0xffffffef,%ecx
801078a3:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801078a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078ac:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801078b3:	83 e1 df             	and    $0xffffffdf,%ecx
801078b6:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801078bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078bf:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801078c6:	83 c9 40             	or     $0x40,%ecx
801078c9:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801078cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078d2:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801078d9:	83 c9 80             	or     $0xffffff80,%ecx
801078dc:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801078e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078e5:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
801078eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078ee:	83 c0 70             	add    $0x70,%eax
801078f1:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
801078f8:	00 
801078f9:	89 04 24             	mov    %eax,(%esp)
801078fc:	e8 37 fb ff ff       	call   80107438 <lgdt>
  loadgs(SEG_KCPU << 3);
80107901:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80107908:	e8 6a fb ff ff       	call   80107477 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
8010790d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107910:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80107916:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
8010791d:	00 00 00 00 
}
80107921:	83 c4 24             	add    $0x24,%esp
80107924:	5b                   	pop    %ebx
80107925:	5d                   	pop    %ebp
80107926:	c3                   	ret    

80107927 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80107927:	55                   	push   %ebp
80107928:	89 e5                	mov    %esp,%ebp
8010792a:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
8010792d:	8b 45 0c             	mov    0xc(%ebp),%eax
80107930:	c1 e8 16             	shr    $0x16,%eax
80107933:	c1 e0 02             	shl    $0x2,%eax
80107936:	03 45 08             	add    0x8(%ebp),%eax
80107939:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
8010793c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010793f:	8b 00                	mov    (%eax),%eax
80107941:	83 e0 01             	and    $0x1,%eax
80107944:	84 c0                	test   %al,%al
80107946:	74 17                	je     8010795f <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80107948:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010794b:	8b 00                	mov    (%eax),%eax
8010794d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107952:	89 04 24             	mov    %eax,(%esp)
80107955:	e8 4a fb ff ff       	call   801074a4 <p2v>
8010795a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010795d:	eb 4b                	jmp    801079aa <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
8010795f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107963:	74 0e                	je     80107973 <walkpgdir+0x4c>
80107965:	e8 9d b2 ff ff       	call   80102c07 <kalloc>
8010796a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010796d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107971:	75 07                	jne    8010797a <walkpgdir+0x53>
      return 0;
80107973:	b8 00 00 00 00       	mov    $0x0,%eax
80107978:	eb 41                	jmp    801079bb <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
8010797a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107981:	00 
80107982:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107989:	00 
8010798a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010798d:	89 04 24             	mov    %eax,(%esp)
80107990:	e8 65 d5 ff ff       	call   80104efa <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107995:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107998:	89 04 24             	mov    %eax,(%esp)
8010799b:	e8 f7 fa ff ff       	call   80107497 <v2p>
801079a0:	89 c2                	mov    %eax,%edx
801079a2:	83 ca 07             	or     $0x7,%edx
801079a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801079a8:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
801079aa:	8b 45 0c             	mov    0xc(%ebp),%eax
801079ad:	c1 e8 0c             	shr    $0xc,%eax
801079b0:	25 ff 03 00 00       	and    $0x3ff,%eax
801079b5:	c1 e0 02             	shl    $0x2,%eax
801079b8:	03 45 f4             	add    -0xc(%ebp),%eax
}
801079bb:	c9                   	leave  
801079bc:	c3                   	ret    

801079bd <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
801079bd:	55                   	push   %ebp
801079be:	89 e5                	mov    %esp,%ebp
801079c0:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
801079c3:	8b 45 0c             	mov    0xc(%ebp),%eax
801079c6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801079cb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
801079ce:	8b 45 0c             	mov    0xc(%ebp),%eax
801079d1:	03 45 10             	add    0x10(%ebp),%eax
801079d4:	83 e8 01             	sub    $0x1,%eax
801079d7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801079dc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
801079df:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
801079e6:	00 
801079e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ea:	89 44 24 04          	mov    %eax,0x4(%esp)
801079ee:	8b 45 08             	mov    0x8(%ebp),%eax
801079f1:	89 04 24             	mov    %eax,(%esp)
801079f4:	e8 2e ff ff ff       	call   80107927 <walkpgdir>
801079f9:	89 45 ec             	mov    %eax,-0x14(%ebp)
801079fc:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107a00:	75 07                	jne    80107a09 <mappages+0x4c>
      return -1;
80107a02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107a07:	eb 46                	jmp    80107a4f <mappages+0x92>
    if(*pte & PTE_P)
80107a09:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107a0c:	8b 00                	mov    (%eax),%eax
80107a0e:	83 e0 01             	and    $0x1,%eax
80107a11:	84 c0                	test   %al,%al
80107a13:	74 0c                	je     80107a21 <mappages+0x64>
      panic("remap");
80107a15:	c7 04 24 3c 88 10 80 	movl   $0x8010883c,(%esp)
80107a1c:	e8 1c 8b ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80107a21:	8b 45 18             	mov    0x18(%ebp),%eax
80107a24:	0b 45 14             	or     0x14(%ebp),%eax
80107a27:	89 c2                	mov    %eax,%edx
80107a29:	83 ca 01             	or     $0x1,%edx
80107a2c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107a2f:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107a31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a34:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107a37:	74 10                	je     80107a49 <mappages+0x8c>
      break;
    a += PGSIZE;
80107a39:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107a40:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107a47:	eb 96                	jmp    801079df <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80107a49:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107a4a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107a4f:	c9                   	leave  
80107a50:	c3                   	ret    

80107a51 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80107a51:	55                   	push   %ebp
80107a52:	89 e5                	mov    %esp,%ebp
80107a54:	53                   	push   %ebx
80107a55:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107a58:	e8 aa b1 ff ff       	call   80102c07 <kalloc>
80107a5d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107a60:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107a64:	75 0a                	jne    80107a70 <setupkvm+0x1f>
    return 0;
80107a66:	b8 00 00 00 00       	mov    $0x0,%eax
80107a6b:	e9 98 00 00 00       	jmp    80107b08 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80107a70:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107a77:	00 
80107a78:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107a7f:	00 
80107a80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107a83:	89 04 24             	mov    %eax,(%esp)
80107a86:	e8 6f d4 ff ff       	call   80104efa <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80107a8b:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80107a92:	e8 0d fa ff ff       	call   801074a4 <p2v>
80107a97:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80107a9c:	76 0c                	jbe    80107aaa <setupkvm+0x59>
    panic("PHYSTOP too high");
80107a9e:	c7 04 24 42 88 10 80 	movl   $0x80108842,(%esp)
80107aa5:	e8 93 8a ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107aaa:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
80107ab1:	eb 49                	jmp    80107afc <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80107ab3:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107ab6:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80107ab9:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107abc:	8b 50 04             	mov    0x4(%eax),%edx
80107abf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ac2:	8b 58 08             	mov    0x8(%eax),%ebx
80107ac5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ac8:	8b 40 04             	mov    0x4(%eax),%eax
80107acb:	29 c3                	sub    %eax,%ebx
80107acd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ad0:	8b 00                	mov    (%eax),%eax
80107ad2:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107ad6:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107ada:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107ade:	89 44 24 04          	mov    %eax,0x4(%esp)
80107ae2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107ae5:	89 04 24             	mov    %eax,(%esp)
80107ae8:	e8 d0 fe ff ff       	call   801079bd <mappages>
80107aed:	85 c0                	test   %eax,%eax
80107aef:	79 07                	jns    80107af8 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80107af1:	b8 00 00 00 00       	mov    $0x0,%eax
80107af6:	eb 10                	jmp    80107b08 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107af8:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107afc:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
80107b03:	72 ae                	jb     80107ab3 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80107b05:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107b08:	83 c4 34             	add    $0x34,%esp
80107b0b:	5b                   	pop    %ebx
80107b0c:	5d                   	pop    %ebp
80107b0d:	c3                   	ret    

80107b0e <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107b0e:	55                   	push   %ebp
80107b0f:	89 e5                	mov    %esp,%ebp
80107b11:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107b14:	e8 38 ff ff ff       	call   80107a51 <setupkvm>
80107b19:	a3 18 2c 11 80       	mov    %eax,0x80112c18
  switchkvm();
80107b1e:	e8 02 00 00 00       	call   80107b25 <switchkvm>
}
80107b23:	c9                   	leave  
80107b24:	c3                   	ret    

80107b25 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107b25:	55                   	push   %ebp
80107b26:	89 e5                	mov    %esp,%ebp
80107b28:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80107b2b:	a1 18 2c 11 80       	mov    0x80112c18,%eax
80107b30:	89 04 24             	mov    %eax,(%esp)
80107b33:	e8 5f f9 ff ff       	call   80107497 <v2p>
80107b38:	89 04 24             	mov    %eax,(%esp)
80107b3b:	e8 4c f9 ff ff       	call   8010748c <lcr3>
}
80107b40:	c9                   	leave  
80107b41:	c3                   	ret    

80107b42 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107b42:	55                   	push   %ebp
80107b43:	89 e5                	mov    %esp,%ebp
80107b45:	53                   	push   %ebx
80107b46:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80107b49:	e8 a5 d2 ff ff       	call   80104df3 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80107b4e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107b54:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107b5b:	83 c2 08             	add    $0x8,%edx
80107b5e:	89 d3                	mov    %edx,%ebx
80107b60:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107b67:	83 c2 08             	add    $0x8,%edx
80107b6a:	c1 ea 10             	shr    $0x10,%edx
80107b6d:	89 d1                	mov    %edx,%ecx
80107b6f:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107b76:	83 c2 08             	add    $0x8,%edx
80107b79:	c1 ea 18             	shr    $0x18,%edx
80107b7c:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80107b83:	67 00 
80107b85:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80107b8c:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80107b92:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107b99:	83 e1 f0             	and    $0xfffffff0,%ecx
80107b9c:	83 c9 09             	or     $0x9,%ecx
80107b9f:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107ba5:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107bac:	83 c9 10             	or     $0x10,%ecx
80107baf:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107bb5:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107bbc:	83 e1 9f             	and    $0xffffff9f,%ecx
80107bbf:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107bc5:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107bcc:	83 c9 80             	or     $0xffffff80,%ecx
80107bcf:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107bd5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107bdc:	83 e1 f0             	and    $0xfffffff0,%ecx
80107bdf:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107be5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107bec:	83 e1 ef             	and    $0xffffffef,%ecx
80107bef:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107bf5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107bfc:	83 e1 df             	and    $0xffffffdf,%ecx
80107bff:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107c05:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107c0c:	83 c9 40             	or     $0x40,%ecx
80107c0f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107c15:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107c1c:	83 e1 7f             	and    $0x7f,%ecx
80107c1f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107c25:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80107c2b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107c31:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80107c38:	83 e2 ef             	and    $0xffffffef,%edx
80107c3b:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80107c41:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107c47:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80107c4d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107c53:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80107c5a:	8b 52 08             	mov    0x8(%edx),%edx
80107c5d:	81 c2 00 10 00 00    	add    $0x1000,%edx
80107c63:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80107c66:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80107c6d:	e8 ef f7 ff ff       	call   80107461 <ltr>
  if(p->pgdir == 0)
80107c72:	8b 45 08             	mov    0x8(%ebp),%eax
80107c75:	8b 40 04             	mov    0x4(%eax),%eax
80107c78:	85 c0                	test   %eax,%eax
80107c7a:	75 0c                	jne    80107c88 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80107c7c:	c7 04 24 53 88 10 80 	movl   $0x80108853,(%esp)
80107c83:	e8 b5 88 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80107c88:	8b 45 08             	mov    0x8(%ebp),%eax
80107c8b:	8b 40 04             	mov    0x4(%eax),%eax
80107c8e:	89 04 24             	mov    %eax,(%esp)
80107c91:	e8 01 f8 ff ff       	call   80107497 <v2p>
80107c96:	89 04 24             	mov    %eax,(%esp)
80107c99:	e8 ee f7 ff ff       	call   8010748c <lcr3>
  popcli();
80107c9e:	e8 98 d1 ff ff       	call   80104e3b <popcli>
}
80107ca3:	83 c4 14             	add    $0x14,%esp
80107ca6:	5b                   	pop    %ebx
80107ca7:	5d                   	pop    %ebp
80107ca8:	c3                   	ret    

80107ca9 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107ca9:	55                   	push   %ebp
80107caa:	89 e5                	mov    %esp,%ebp
80107cac:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80107caf:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107cb6:	76 0c                	jbe    80107cc4 <inituvm+0x1b>
    panic("inituvm: more than a page");
80107cb8:	c7 04 24 67 88 10 80 	movl   $0x80108867,(%esp)
80107cbf:	e8 79 88 ff ff       	call   8010053d <panic>
  mem = kalloc();
80107cc4:	e8 3e af ff ff       	call   80102c07 <kalloc>
80107cc9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107ccc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107cd3:	00 
80107cd4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107cdb:	00 
80107cdc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cdf:	89 04 24             	mov    %eax,(%esp)
80107ce2:	e8 13 d2 ff ff       	call   80104efa <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107ce7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cea:	89 04 24             	mov    %eax,(%esp)
80107ced:	e8 a5 f7 ff ff       	call   80107497 <v2p>
80107cf2:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107cf9:	00 
80107cfa:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107cfe:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107d05:	00 
80107d06:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107d0d:	00 
80107d0e:	8b 45 08             	mov    0x8(%ebp),%eax
80107d11:	89 04 24             	mov    %eax,(%esp)
80107d14:	e8 a4 fc ff ff       	call   801079bd <mappages>
  memmove(mem, init, sz);
80107d19:	8b 45 10             	mov    0x10(%ebp),%eax
80107d1c:	89 44 24 08          	mov    %eax,0x8(%esp)
80107d20:	8b 45 0c             	mov    0xc(%ebp),%eax
80107d23:	89 44 24 04          	mov    %eax,0x4(%esp)
80107d27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d2a:	89 04 24             	mov    %eax,(%esp)
80107d2d:	e8 9b d2 ff ff       	call   80104fcd <memmove>
}
80107d32:	c9                   	leave  
80107d33:	c3                   	ret    

80107d34 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80107d34:	55                   	push   %ebp
80107d35:	89 e5                	mov    %esp,%ebp
80107d37:	53                   	push   %ebx
80107d38:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80107d3b:	8b 45 0c             	mov    0xc(%ebp),%eax
80107d3e:	25 ff 0f 00 00       	and    $0xfff,%eax
80107d43:	85 c0                	test   %eax,%eax
80107d45:	74 0c                	je     80107d53 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80107d47:	c7 04 24 84 88 10 80 	movl   $0x80108884,(%esp)
80107d4e:	e8 ea 87 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
80107d53:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107d5a:	e9 ad 00 00 00       	jmp    80107e0c <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80107d5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d62:	8b 55 0c             	mov    0xc(%ebp),%edx
80107d65:	01 d0                	add    %edx,%eax
80107d67:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107d6e:	00 
80107d6f:	89 44 24 04          	mov    %eax,0x4(%esp)
80107d73:	8b 45 08             	mov    0x8(%ebp),%eax
80107d76:	89 04 24             	mov    %eax,(%esp)
80107d79:	e8 a9 fb ff ff       	call   80107927 <walkpgdir>
80107d7e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107d81:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107d85:	75 0c                	jne    80107d93 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80107d87:	c7 04 24 a7 88 10 80 	movl   $0x801088a7,(%esp)
80107d8e:	e8 aa 87 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80107d93:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107d96:	8b 00                	mov    (%eax),%eax
80107d98:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107d9d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80107da0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107da3:	8b 55 18             	mov    0x18(%ebp),%edx
80107da6:	89 d1                	mov    %edx,%ecx
80107da8:	29 c1                	sub    %eax,%ecx
80107daa:	89 c8                	mov    %ecx,%eax
80107dac:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80107db1:	77 11                	ja     80107dc4 <loaduvm+0x90>
      n = sz - i;
80107db3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107db6:	8b 55 18             	mov    0x18(%ebp),%edx
80107db9:	89 d1                	mov    %edx,%ecx
80107dbb:	29 c1                	sub    %eax,%ecx
80107dbd:	89 c8                	mov    %ecx,%eax
80107dbf:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107dc2:	eb 07                	jmp    80107dcb <loaduvm+0x97>
    else
      n = PGSIZE;
80107dc4:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80107dcb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dce:	8b 55 14             	mov    0x14(%ebp),%edx
80107dd1:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80107dd4:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107dd7:	89 04 24             	mov    %eax,(%esp)
80107dda:	e8 c5 f6 ff ff       	call   801074a4 <p2v>
80107ddf:	8b 55 f0             	mov    -0x10(%ebp),%edx
80107de2:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107de6:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107dea:	89 44 24 04          	mov    %eax,0x4(%esp)
80107dee:	8b 45 10             	mov    0x10(%ebp),%eax
80107df1:	89 04 24             	mov    %eax,(%esp)
80107df4:	e8 6d a0 ff ff       	call   80101e66 <readi>
80107df9:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107dfc:	74 07                	je     80107e05 <loaduvm+0xd1>
      return -1;
80107dfe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107e03:	eb 18                	jmp    80107e1d <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80107e05:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107e0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e0f:	3b 45 18             	cmp    0x18(%ebp),%eax
80107e12:	0f 82 47 ff ff ff    	jb     80107d5f <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80107e18:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107e1d:	83 c4 24             	add    $0x24,%esp
80107e20:	5b                   	pop    %ebx
80107e21:	5d                   	pop    %ebp
80107e22:	c3                   	ret    

80107e23 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107e23:	55                   	push   %ebp
80107e24:	89 e5                	mov    %esp,%ebp
80107e26:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80107e29:	8b 45 10             	mov    0x10(%ebp),%eax
80107e2c:	85 c0                	test   %eax,%eax
80107e2e:	79 0a                	jns    80107e3a <allocuvm+0x17>
    return 0;
80107e30:	b8 00 00 00 00       	mov    $0x0,%eax
80107e35:	e9 c1 00 00 00       	jmp    80107efb <allocuvm+0xd8>
  if(newsz < oldsz)
80107e3a:	8b 45 10             	mov    0x10(%ebp),%eax
80107e3d:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107e40:	73 08                	jae    80107e4a <allocuvm+0x27>
    return oldsz;
80107e42:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e45:	e9 b1 00 00 00       	jmp    80107efb <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80107e4a:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e4d:	05 ff 0f 00 00       	add    $0xfff,%eax
80107e52:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107e57:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80107e5a:	e9 8d 00 00 00       	jmp    80107eec <allocuvm+0xc9>
    mem = kalloc();
80107e5f:	e8 a3 ad ff ff       	call   80102c07 <kalloc>
80107e64:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80107e67:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107e6b:	75 2c                	jne    80107e99 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80107e6d:	c7 04 24 c5 88 10 80 	movl   $0x801088c5,(%esp)
80107e74:	e8 28 85 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80107e79:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e7c:	89 44 24 08          	mov    %eax,0x8(%esp)
80107e80:	8b 45 10             	mov    0x10(%ebp),%eax
80107e83:	89 44 24 04          	mov    %eax,0x4(%esp)
80107e87:	8b 45 08             	mov    0x8(%ebp),%eax
80107e8a:	89 04 24             	mov    %eax,(%esp)
80107e8d:	e8 6b 00 00 00       	call   80107efd <deallocuvm>
      return 0;
80107e92:	b8 00 00 00 00       	mov    $0x0,%eax
80107e97:	eb 62                	jmp    80107efb <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80107e99:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107ea0:	00 
80107ea1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107ea8:	00 
80107ea9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107eac:	89 04 24             	mov    %eax,(%esp)
80107eaf:	e8 46 d0 ff ff       	call   80104efa <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107eb4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107eb7:	89 04 24             	mov    %eax,(%esp)
80107eba:	e8 d8 f5 ff ff       	call   80107497 <v2p>
80107ebf:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107ec2:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107ec9:	00 
80107eca:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107ece:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107ed5:	00 
80107ed6:	89 54 24 04          	mov    %edx,0x4(%esp)
80107eda:	8b 45 08             	mov    0x8(%ebp),%eax
80107edd:	89 04 24             	mov    %eax,(%esp)
80107ee0:	e8 d8 fa ff ff       	call   801079bd <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80107ee5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107eec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107eef:	3b 45 10             	cmp    0x10(%ebp),%eax
80107ef2:	0f 82 67 ff ff ff    	jb     80107e5f <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80107ef8:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107efb:	c9                   	leave  
80107efc:	c3                   	ret    

80107efd <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107efd:	55                   	push   %ebp
80107efe:	89 e5                	mov    %esp,%ebp
80107f00:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80107f03:	8b 45 10             	mov    0x10(%ebp),%eax
80107f06:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107f09:	72 08                	jb     80107f13 <deallocuvm+0x16>
    return oldsz;
80107f0b:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f0e:	e9 a4 00 00 00       	jmp    80107fb7 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80107f13:	8b 45 10             	mov    0x10(%ebp),%eax
80107f16:	05 ff 0f 00 00       	add    $0xfff,%eax
80107f1b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f20:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80107f23:	e9 80 00 00 00       	jmp    80107fa8 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80107f28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f2b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107f32:	00 
80107f33:	89 44 24 04          	mov    %eax,0x4(%esp)
80107f37:	8b 45 08             	mov    0x8(%ebp),%eax
80107f3a:	89 04 24             	mov    %eax,(%esp)
80107f3d:	e8 e5 f9 ff ff       	call   80107927 <walkpgdir>
80107f42:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80107f45:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107f49:	75 09                	jne    80107f54 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80107f4b:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80107f52:	eb 4d                	jmp    80107fa1 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80107f54:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f57:	8b 00                	mov    (%eax),%eax
80107f59:	83 e0 01             	and    $0x1,%eax
80107f5c:	84 c0                	test   %al,%al
80107f5e:	74 41                	je     80107fa1 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80107f60:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f63:	8b 00                	mov    (%eax),%eax
80107f65:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f6a:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80107f6d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107f71:	75 0c                	jne    80107f7f <deallocuvm+0x82>
        panic("kfree");
80107f73:	c7 04 24 dd 88 10 80 	movl   $0x801088dd,(%esp)
80107f7a:	e8 be 85 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
80107f7f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107f82:	89 04 24             	mov    %eax,(%esp)
80107f85:	e8 1a f5 ff ff       	call   801074a4 <p2v>
80107f8a:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80107f8d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107f90:	89 04 24             	mov    %eax,(%esp)
80107f93:	e8 d6 ab ff ff       	call   80102b6e <kfree>
      *pte = 0;
80107f98:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f9b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80107fa1:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107fa8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fab:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107fae:	0f 82 74 ff ff ff    	jb     80107f28 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80107fb4:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107fb7:	c9                   	leave  
80107fb8:	c3                   	ret    

80107fb9 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80107fb9:	55                   	push   %ebp
80107fba:	89 e5                	mov    %esp,%ebp
80107fbc:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80107fbf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80107fc3:	75 0c                	jne    80107fd1 <freevm+0x18>
    panic("freevm: no pgdir");
80107fc5:	c7 04 24 e3 88 10 80 	movl   $0x801088e3,(%esp)
80107fcc:	e8 6c 85 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80107fd1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107fd8:	00 
80107fd9:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80107fe0:	80 
80107fe1:	8b 45 08             	mov    0x8(%ebp),%eax
80107fe4:	89 04 24             	mov    %eax,(%esp)
80107fe7:	e8 11 ff ff ff       	call   80107efd <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80107fec:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107ff3:	eb 3c                	jmp    80108031 <freevm+0x78>
    if(pgdir[i] & PTE_P){
80107ff5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ff8:	c1 e0 02             	shl    $0x2,%eax
80107ffb:	03 45 08             	add    0x8(%ebp),%eax
80107ffe:	8b 00                	mov    (%eax),%eax
80108000:	83 e0 01             	and    $0x1,%eax
80108003:	84 c0                	test   %al,%al
80108005:	74 26                	je     8010802d <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108007:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010800a:	c1 e0 02             	shl    $0x2,%eax
8010800d:	03 45 08             	add    0x8(%ebp),%eax
80108010:	8b 00                	mov    (%eax),%eax
80108012:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108017:	89 04 24             	mov    %eax,(%esp)
8010801a:	e8 85 f4 ff ff       	call   801074a4 <p2v>
8010801f:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108022:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108025:	89 04 24             	mov    %eax,(%esp)
80108028:	e8 41 ab ff ff       	call   80102b6e <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
8010802d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108031:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108038:	76 bb                	jbe    80107ff5 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
8010803a:	8b 45 08             	mov    0x8(%ebp),%eax
8010803d:	89 04 24             	mov    %eax,(%esp)
80108040:	e8 29 ab ff ff       	call   80102b6e <kfree>
}
80108045:	c9                   	leave  
80108046:	c3                   	ret    

80108047 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108047:	55                   	push   %ebp
80108048:	89 e5                	mov    %esp,%ebp
8010804a:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010804d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108054:	00 
80108055:	8b 45 0c             	mov    0xc(%ebp),%eax
80108058:	89 44 24 04          	mov    %eax,0x4(%esp)
8010805c:	8b 45 08             	mov    0x8(%ebp),%eax
8010805f:	89 04 24             	mov    %eax,(%esp)
80108062:	e8 c0 f8 ff ff       	call   80107927 <walkpgdir>
80108067:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
8010806a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010806e:	75 0c                	jne    8010807c <clearpteu+0x35>
    panic("clearpteu");
80108070:	c7 04 24 f4 88 10 80 	movl   $0x801088f4,(%esp)
80108077:	e8 c1 84 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
8010807c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010807f:	8b 00                	mov    (%eax),%eax
80108081:	89 c2                	mov    %eax,%edx
80108083:	83 e2 fb             	and    $0xfffffffb,%edx
80108086:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108089:	89 10                	mov    %edx,(%eax)
}
8010808b:	c9                   	leave  
8010808c:	c3                   	ret    

8010808d <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
8010808d:	55                   	push   %ebp
8010808e:	89 e5                	mov    %esp,%ebp
80108090:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
80108093:	e8 b9 f9 ff ff       	call   80107a51 <setupkvm>
80108098:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010809b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010809f:	75 0a                	jne    801080ab <copyuvm+0x1e>
    return 0;
801080a1:	b8 00 00 00 00       	mov    $0x0,%eax
801080a6:	e9 f1 00 00 00       	jmp    8010819c <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
801080ab:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801080b2:	e9 c0 00 00 00       	jmp    80108177 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801080b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080ba:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801080c1:	00 
801080c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801080c6:	8b 45 08             	mov    0x8(%ebp),%eax
801080c9:	89 04 24             	mov    %eax,(%esp)
801080cc:	e8 56 f8 ff ff       	call   80107927 <walkpgdir>
801080d1:	89 45 ec             	mov    %eax,-0x14(%ebp)
801080d4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801080d8:	75 0c                	jne    801080e6 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
801080da:	c7 04 24 fe 88 10 80 	movl   $0x801088fe,(%esp)
801080e1:	e8 57 84 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
801080e6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801080e9:	8b 00                	mov    (%eax),%eax
801080eb:	83 e0 01             	and    $0x1,%eax
801080ee:	85 c0                	test   %eax,%eax
801080f0:	75 0c                	jne    801080fe <copyuvm+0x71>
      panic("copyuvm: page not present");
801080f2:	c7 04 24 18 89 10 80 	movl   $0x80108918,(%esp)
801080f9:	e8 3f 84 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
801080fe:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108101:	8b 00                	mov    (%eax),%eax
80108103:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108108:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
8010810b:	e8 f7 aa ff ff       	call   80102c07 <kalloc>
80108110:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80108113:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80108117:	74 6f                	je     80108188 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108119:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010811c:	89 04 24             	mov    %eax,(%esp)
8010811f:	e8 80 f3 ff ff       	call   801074a4 <p2v>
80108124:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010812b:	00 
8010812c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108130:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108133:	89 04 24             	mov    %eax,(%esp)
80108136:	e8 92 ce ff ff       	call   80104fcd <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
8010813b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010813e:	89 04 24             	mov    %eax,(%esp)
80108141:	e8 51 f3 ff ff       	call   80107497 <v2p>
80108146:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108149:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108150:	00 
80108151:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108155:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010815c:	00 
8010815d:	89 54 24 04          	mov    %edx,0x4(%esp)
80108161:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108164:	89 04 24             	mov    %eax,(%esp)
80108167:	e8 51 f8 ff ff       	call   801079bd <mappages>
8010816c:	85 c0                	test   %eax,%eax
8010816e:	78 1b                	js     8010818b <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80108170:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108177:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010817a:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010817d:	0f 82 34 ff ff ff    	jb     801080b7 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
80108183:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108186:	eb 14                	jmp    8010819c <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80108188:	90                   	nop
80108189:	eb 01                	jmp    8010818c <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
8010818b:	90                   	nop
  }
  return d;

bad:
  freevm(d);
8010818c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010818f:	89 04 24             	mov    %eax,(%esp)
80108192:	e8 22 fe ff ff       	call   80107fb9 <freevm>
  return 0;
80108197:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010819c:	c9                   	leave  
8010819d:	c3                   	ret    

8010819e <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010819e:	55                   	push   %ebp
8010819f:	89 e5                	mov    %esp,%ebp
801081a1:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801081a4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801081ab:	00 
801081ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801081af:	89 44 24 04          	mov    %eax,0x4(%esp)
801081b3:	8b 45 08             	mov    0x8(%ebp),%eax
801081b6:	89 04 24             	mov    %eax,(%esp)
801081b9:	e8 69 f7 ff ff       	call   80107927 <walkpgdir>
801081be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801081c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081c4:	8b 00                	mov    (%eax),%eax
801081c6:	83 e0 01             	and    $0x1,%eax
801081c9:	85 c0                	test   %eax,%eax
801081cb:	75 07                	jne    801081d4 <uva2ka+0x36>
    return 0;
801081cd:	b8 00 00 00 00       	mov    $0x0,%eax
801081d2:	eb 25                	jmp    801081f9 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801081d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081d7:	8b 00                	mov    (%eax),%eax
801081d9:	83 e0 04             	and    $0x4,%eax
801081dc:	85 c0                	test   %eax,%eax
801081de:	75 07                	jne    801081e7 <uva2ka+0x49>
    return 0;
801081e0:	b8 00 00 00 00       	mov    $0x0,%eax
801081e5:	eb 12                	jmp    801081f9 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
801081e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081ea:	8b 00                	mov    (%eax),%eax
801081ec:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801081f1:	89 04 24             	mov    %eax,(%esp)
801081f4:	e8 ab f2 ff ff       	call   801074a4 <p2v>
}
801081f9:	c9                   	leave  
801081fa:	c3                   	ret    

801081fb <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801081fb:	55                   	push   %ebp
801081fc:	89 e5                	mov    %esp,%ebp
801081fe:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80108201:	8b 45 10             	mov    0x10(%ebp),%eax
80108204:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80108207:	e9 8b 00 00 00       	jmp    80108297 <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
8010820c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010820f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108214:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80108217:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010821a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010821e:	8b 45 08             	mov    0x8(%ebp),%eax
80108221:	89 04 24             	mov    %eax,(%esp)
80108224:	e8 75 ff ff ff       	call   8010819e <uva2ka>
80108229:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
8010822c:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108230:	75 07                	jne    80108239 <copyout+0x3e>
      return -1;
80108232:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108237:	eb 6d                	jmp    801082a6 <copyout+0xab>
    n = PGSIZE - (va - va0);
80108239:	8b 45 0c             	mov    0xc(%ebp),%eax
8010823c:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010823f:	89 d1                	mov    %edx,%ecx
80108241:	29 c1                	sub    %eax,%ecx
80108243:	89 c8                	mov    %ecx,%eax
80108245:	05 00 10 00 00       	add    $0x1000,%eax
8010824a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
8010824d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108250:	3b 45 14             	cmp    0x14(%ebp),%eax
80108253:	76 06                	jbe    8010825b <copyout+0x60>
      n = len;
80108255:	8b 45 14             	mov    0x14(%ebp),%eax
80108258:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010825b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010825e:	8b 55 0c             	mov    0xc(%ebp),%edx
80108261:	89 d1                	mov    %edx,%ecx
80108263:	29 c1                	sub    %eax,%ecx
80108265:	89 c8                	mov    %ecx,%eax
80108267:	03 45 e8             	add    -0x18(%ebp),%eax
8010826a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010826d:	89 54 24 08          	mov    %edx,0x8(%esp)
80108271:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108274:	89 54 24 04          	mov    %edx,0x4(%esp)
80108278:	89 04 24             	mov    %eax,(%esp)
8010827b:	e8 4d cd ff ff       	call   80104fcd <memmove>
    len -= n;
80108280:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108283:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108286:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108289:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
8010828c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010828f:	05 00 10 00 00       	add    $0x1000,%eax
80108294:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80108297:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010829b:	0f 85 6b ff ff ff    	jne    8010820c <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801082a1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801082a6:	c9                   	leave  
801082a7:	c3                   	ret    
