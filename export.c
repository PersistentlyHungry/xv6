#include "types.h"
#include "stat.h"
#include "user.h"
#include "fs.h"

int
main(int argc, char *argv[])
{
  int offset=0;
  int i;
  char currPath[128];

  if(argc != 2){
    printf(2, "Usage: export need path\n");
    exit();
  }

  for(i = 0; argv[1][i] != '\0' ; i++){
    if(argv[1][i]!=':')
    {
      currPath[offset]=argv[1][i];
      offset++;
    }
    else
    {
      currPath[offset]='\0';
      if(add_path(currPath)<0)
      {
        printf(2, "currPath: %s failed to create\n", currPath);
        break;  
      }
      else
      {
        printf(2, "currPath: %s success to create\n", currPath);
      }
      offset=0;
    }

  }

  if(offset!=0)
    {
      currPath[offset]='\0';
      if(add_path(currPath)<0)
      {
        printf(2, "currPath: %s failed to create\n", currPath);
      }
      else
      {
        printf(2, "currPath: %s success to create\n", currPath);
      }
    }

  exit();
}
