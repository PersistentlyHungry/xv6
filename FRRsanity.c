

#include "types.h"
#include "stat.h"
#include "user.h"

#define N  10
#define P 1000


void
printChild()
{
  int i;
  int pid= getpid();
  for (i=0;i<P;i++)
     printf(2, "child %d prints for the %d time\n",pid ,i);
}

void
frrtest(void)
{
  int wTime[N];
  int rTime[N];
  int ioTime[N];
  int pid[N];
  int i, pidTemp,wTimeTemp, rTimeTemp, ioTimeTemp;
  printf(1, "FRRsanity test\n");

  for(i=0;i<N;i++)
  {
    pidTemp = fork();
    if(pidTemp == 0)
    {
      //printf(1,"%d ***************************************************************************\n", getpid());
      printChild();
      exit();      
    }
  }

  for(i=0; i<N; i++)
  {

    pid[i] = wait2(&wTimeTemp,&rTimeTemp,&ioTimeTemp);
    wTime[i]=wTimeTemp;
    ioTime[i]=ioTimeTemp;
    rTime[i]=rTimeTemp;
  }    
  
  for(i=0; i<N; i++)
  {
    printf(1, "child %d: wtime - %d, rtime - %d, iotimew - %d\n",pid[i],wTime[i],rTime[i], ioTime[i]);
  }     

}
int
main(void)
{
  frrtest();
  exit();
} 