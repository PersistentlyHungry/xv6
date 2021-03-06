#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "x86.h"
#include "proc.h"
#include "spinlock.h"

#define QUEUESIZE NPROC

typedef struct {
        struct spinlock lock;
        struct proc * q[QUEUESIZE+1];   /* body of queue */
        int first;                      /* position of first element */
        int last;                       /* position of last element */
        int count;                      /* number of queue elements */
} queue;

struct {
  struct spinlock lock;
  struct proc proc[NPROC];
} ptable;

static struct proc *initproc;

static queue FRRqueue;

struct {
  queue low;
  queue medium;
  queue high;
} multiQueue;

int nextpid = 1;
extern void forkret(void);
extern void trapret(void);

static void wakeup1(void *chan);

void DefualtHandler(int pID)
{
  cprintf("A signal was accepted by process %d \n", pID);
}

void InitQ(queue* pqueue, char* lockKey)
{
  // Init queue process
  initlock(&pqueue->lock, lockKey);
  pqueue->first = 0;
  pqueue->last = NPROC-1;
  pqueue->count = 0;
}

void
pinit(void)
{
  initlock(&ptable.lock, "ptable");

  InitQ(&FRRqueue, "FRR");
  InitQ(&multiQueue.low, "LOW");
  InitQ(&multiQueue.high, "HIGH");
  InitQ(&multiQueue.medium, "MEDIUM");
}



void enqueue(queue* pqueue, struct proc * x)
{
  int NeedQueue = 0;
  #if defined (SCHED_FRR)  || defined (SCHED_FCFS)
  if(pqueue == &FRRqueue)
    NeedQueue = 1;
  #endif 
  #ifdef SCHED_3Q
  if((pqueue == &multiQueue.low)||(pqueue==&multiQueue.medium)||(pqueue==&multiQueue.high))
    NeedQueue = 1;
  #endif      

  if(NeedQueue)
  {
    acquire(&pqueue->lock);

    if (pqueue->count >= QUEUESIZE)
          cprintf("Warning: queue overflow enqueue ");
    else {
            pqueue->last = (pqueue->last+1) % QUEUESIZE;
            pqueue->q[ pqueue->last ] = x;  
            
            pqueue->count = pqueue->count + 1;
    }
    release(&pqueue->lock);
  }
}

struct proc * dequeue(queue* pqueue)
{
    acquire(&pqueue->lock);
    struct proc * x;

    if (pqueue->count <= 0) cprintf("Warning: empty queue dequeue.\n");
    else {
            x = pqueue->q[ pqueue->first ];
            pqueue->first = (pqueue->first+1) % QUEUESIZE;
            pqueue->count = pqueue->count - 1;
    }
    release(&pqueue->lock);
    return(x);
}

//PAGEBREAK: 32
// Look in the process table for an UNUSED proc.
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
  p->pid = nextpid++; 
  release(&ptable.lock);

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
    return 0;
  }
  sp = p->kstack + KSTACKSIZE;
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
  p->tf = (struct trapframe*)sp;
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
  *(uint*)sp = (uint)trapret;

  sp -= sizeof *p->context;
  p->context = (struct context*)sp;
  memset(p->context, 0, sizeof *p->context);
  p->context->eip = (uint)forkret;
  return p;
}

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
  initproc = p;
  if((p->pgdir = setupkvm(kalloc)) == 0)
    panic("userinit: out of memory?");
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
  p->sz = PGSIZE;
  memset(p->tf, 0, sizeof(*p->tf));
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
  p->tf->es = p->tf->ds;
  p->tf->ss = p->tf->ds;
  p->tf->eflags = FL_IF;
  p->tf->esp = PGSIZE;
  p->tf->eip = 0;  // beginning of initcode.S

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  // Init proc signal values
  p->pending = 0;
  int FuncIter;
  for(FuncIter = 0; FuncIter < 32; ++FuncIter)
  {
    p->PendingFunctions[FuncIter] = 0;
  }


  p->state = RUNNABLE;
  p->ctime = ticks;
  enqueue(&FRRqueue, p);
  p->queuePriorty = MEDIUM;
  enqueue(&multiQueue.medium,p);
}

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  
  sz = proc->sz;
  if(n > 0){
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
      return -1;
  } else if(n < 0){
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
      return -1;
  }
  proc->sz = sz;
  switchuvm(proc);
  return 0;
}

// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
    return -1;

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
    kfree(np->kstack);
    np->kstack = 0;
    np->state = UNUSED;
    return -1;
  }
  np->sz = proc->sz;
  np->parent = proc;
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
 
  pid = np->pid;

  // Init proc signal values
  np->pending = proc->pending;
  int FuncIter;
  for(FuncIter = 0; FuncIter < 32; ++FuncIter)
  {
    np->PendingFunctions[FuncIter] = proc->PendingFunctions[FuncIter];
  }


  np->state = RUNNABLE;
  np->ctime = ticks;
  enqueue(&FRRqueue, np);
  np->queuePriorty = MEDIUM;
  enqueue(&multiQueue.medium,np);
  np->iotime = 0;
  np-> rtime = 0;
  np-> etime = 0;
  safestrcpy(np->name, proc->name, sizeof(proc->name));
  
  return pid;
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
  struct proc *p;
  int fd;

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd]){
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
  proc->cwd = 0;

  acquire(&ptable.lock);

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->parent == proc){
      p->parent = initproc;
      if(p->state == ZOMBIE)
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
  proc->etime= ticks;
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid and its rtime, wtime and iotime.
// Return -1 if this process has no children.
int
wait2(int *wtime, int *rtime, int *iotime)
{
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
      havekids = 1;
      if(p->state == ZOMBIE){
        // Found one.
        *wtime = p->etime - p->ctime - p->rtime - p->iotime;
        *rtime = p->rtime;
        *iotime = p->iotime;
        pid = p->pid;
        kfree(p->kstack);
        p->kstack = 0;
        freevm(p->pgdir);
        p->state = UNUSED;
        p->pid = 0;
        p->parent = 0;
        p->name[0] = 0;
        p->killed = 0;
        release(&ptable.lock);
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
      release(&ptable.lock);
      return -1;
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
  }
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
  int garbage=0;
  return wait2(&garbage, &garbage, &garbage);
}


int 
signal(int signum, int handler)
//signal(int signum, sighandler_t handler)
{
  return 0;
}

int 
sigsend(int pid, int signum)
{
  return 0;
}

void 
alarm(int ticks)
{

}

void
register_handler(sighandler_t sighandler)
{
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
  if ((proc->tf->esp & 0xFFF) == 0)
    panic("esp_offset == 0");

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
          = proc->tf->eip;
  proc->tf->esp -= 4;

    /* update eip */
  proc->tf->eip = (uint)sighandler;
}

#if defined (SCHED_DEFAULT)

struct proc* FirstProcess()
{
  return ptable.proc;
}

struct proc* NextProcess(struct proc *p)
{
  if(p < &ptable.proc[NPROC])
  {
    return ++p;
  }
  else
  {
    return 0;
  }
}

#endif

#if defined (SCHED_FRR)  || defined (SCHED_FCFS)


struct proc* NextProcess(struct proc *p)
{
  if(FRRqueue.count == 0)
  {
    return 0;
  }
  else
  {
    return dequeue(&FRRqueue);
  }
  
}

struct proc* FirstProcess()
{
  return NextProcess(0);
}

#endif



#ifdef SCHED_3Q

struct proc* NextProcess(struct proc *p)
{
  if(multiQueue.high.count > 0)
  {
    return dequeue(&multiQueue.high);
  }
  else if(multiQueue.medium.count > 0)
  {
    return dequeue(&multiQueue.medium); 
  }
  else if(multiQueue.low.count > 0)
  {
    return dequeue(&multiQueue.low); 
  }
  else
  {
    return 0;
  }
}

struct proc* FirstProcess()
{
  return NextProcess(0);
}

#endif

//PAGEBREAK: 42
// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    p = FirstProcess();
    while( p!= 0 )
    {
      if(p->state == RUNNABLE)
      {
        // Switch to chosen process.  It is the process's job
        // to release ptable.lock and then reacquire it
        // before jumping back to us.
        proc = p;
        switchuvm(p);
        p->state = RUNNING;
        //  cprintf("Before Scheduler for %d \n", p->pid);
        swtch(&cpu->scheduler, proc->context);
        //cprintf("After Scheduler for %d \n", p->pid);
        switchkvm();

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        proc = 0;
      }
      p = NextProcess(p);
    }
    release(&ptable.lock);

  }
}


// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
  int intena;

  if(!holding(&ptable.lock))
    panic("sched ptable.lock");
  if(cpu->ncli != 1)
    panic("sched locks");
  if(proc->state == RUNNING)
    panic("sched running");
  if(readeflags()&FL_IF)
    panic("sched interruptible");
  intena = cpu->intena;
  swtch(&proc->context, cpu->scheduler);
  cpu->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  acquire(&ptable.lock);  //DOC: yieldlock
  proc->state = RUNNABLE;
 // cprintf("yeild for %d \n", proc->pid);
  enqueue(&FRRqueue ,proc);

  if(proc->queuePriorty == LOW)
  {
     enqueue(&multiQueue.low ,proc); 
  }
  else if(proc->queuePriorty == MEDIUM)
  {
    enqueue(&multiQueue.medium ,proc); 
  }
  else
  {
    enqueue(&multiQueue.high ,proc);   
  }

  sched();
  release(&ptable.lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);

  if (first) {
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
    initlog();
  }
  
  // Return to "caller", actually trapret (see allocproc).
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  if(proc == 0)
    panic("sleep");

  if(lk == 0)
    panic("sleep without lk");

  // Must acquire ptable.lock in order to
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
    acquire(&ptable.lock);  //DOC: sleeplock1
    release(lk);
  }

  // Go to sleep.
  proc->chan = chan;
  proc->state = SLEEPING;
  sched();

  // Tidy up.
  proc->chan = 0;

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
    release(&ptable.lock);
    acquire(lk);
  }
}

void PromoteOneLevel(struct proc *p)
{
      if(p->queuePriorty == LOW)
      {
         p->queuePriorty = MEDIUM;
         enqueue(&multiQueue.medium ,p); 
      }
      else
      {
        p->queuePriorty = MEDIUM;
        enqueue(&multiQueue.high ,p);   
      }  
}

//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == SLEEPING && p->chan == chan)
    {
      p->state = RUNNABLE;
      enqueue(&FRRqueue, p);
      PromoteOneLevel(p);

    }
}

//PAGEBREAK!
// look wether the process are RUNNING or SLEEPING
void
addiortime(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  {
    if(p->state==RUNNING)
      p->rtime++;
    else if(p->state==SLEEPING)
      p->iotime++;
    }
}


// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
  acquire(&ptable.lock);
  wakeup1(chan);
  release(&ptable.lock);
}

// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->pid == pid){
      p->killed = 1;
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
      {
        p->state = RUNNABLE;
        enqueue(&FRRqueue, p);
        PromoteOneLevel(p);
      }
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
  return -1;
}

//PAGEBREAK: 36
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [EMBRYO]    "embryo",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}


