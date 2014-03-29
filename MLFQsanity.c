

#include "types.h"
#include "stat.h"
#include "user.h"

#define N  20
#define P 500


void
printChild(int cid)
{
  int i;
  for (i=0;i<P;i++)
     printf(1, "child %d prints for the %d time\n",cid ,i);
}

void
mlfqtest(void)
{
  int wTime[N];
  int rTime[N];
  int ioTime[N];
  int pid[N];
  int i, j,pidTemp,wTimeTemp, rTimeTemp, ioTimeTemp;
  int wTimeAverage[3]={0,0,0}, rTimeAverage[3]={0,0,0}, ioTimeAverage[3]={0,0,0};
  printf(1, "MLFQsanity test\n");

  for(i=0;i<N;i++)
  {
    pid[i] = fork();
    if(pid[i] == 0 && i%2==0)
    {
      printChild(i);
      exit();      
    }
    else if(pid[i] == 0 && i%2==1)
    {
      sleep(1); // sould replace to i/o system call
      printChild(i);
      exit();      
    }
  }

  for(i=0; i<N; i++)
  {

    pidTemp = wait2(&wTimeTemp,&rTimeTemp,&ioTimeTemp);
    for(j=0;j<N;j++)
    {
      if(pid[j]==pidTemp)
      {
        wTimeAverage[0]+=wTimeTemp;
        rTimeAverage[0]+=rTimeTemp;
        ioTimeAverage[0]+=ioTimeTemp;
        wTime[j]=wTimeTemp;
        ioTime[j]=ioTimeTemp;
        rTime[j]=rTimeTemp;
        if(j%2==0)
        {
          wTimeAverage[1]+=wTimeTemp;
          rTimeAverage[1]+=rTimeTemp;
          ioTimeAverage[1]+=ioTimeTemp;
        }
        else
        {
          wTimeAverage[2]+=wTimeTemp;
          rTimeAverage[2]+=rTimeTemp;
          ioTimeAverage[2]+=ioTimeTemp;
        }
        continue;
      }
    }
  }    
  
  printf(1, "Average: Wtime - %d, Rtime - %d, TAtime - %d\n",
      wTimeAverage[0]/N,rTimeAverage[0]/N, (wTimeAverage[0]+rTimeAverage[0]+ioTimeAverage[0])/N);
  printf(1, "Average Low Piriority: Wtime - %d, Rtime - %d, TAtime - %d\n",
      wTimeAverage[1]/(N/2),rTimeAverage[1]/(N/2), (wTimeAverage[1]+rTimeAverage[1]+ioTimeAverage[1])/N);
  printf(1, "Average High Piriority: Wtime - %d, Rtime - %d, TAtime - %d\n",
      wTimeAverage[2]/N,rTimeAverage[2]/N, (wTimeAverage[2]+rTimeAverage[2]+ioTimeAverage[2])/N);
  for(i=0; i<N; i++)
  {
    printf(1, "Cid %d: Wtime - %d, Rtime - %d, TAtime - %d\n",
      i, wTime[i],rTime[i], wTime[i]+rTime[i]+ ioTime[i]);
  }     

}
int
main(void)
{
  mlfqtest();
  exit();
} 