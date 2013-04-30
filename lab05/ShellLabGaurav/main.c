/*
 * lab05 (shell) main.c
 *
 * Gaurav Ragtah
 *
 * Note: For usage time stats,
 * info for child processes was added separately using RUSAGE_CHILDREN
 * since RUSAGE_SELF didn't seem to have that info. It only had info on
 * the main process. Checked online forums and many others
 * have come across this bug in some linux versions(?)
 */


/* you probably won't need any other header files for
   any of the stages of this lab */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <ctype.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <poll.h>
#include <signal.h>
#include <errno.h>
#include <assert.h>
#include <sys/time.h>

struct node {
     pid_t proc;
     int paused;
     char* command;
     struct node* next;
};
struct path {
     char* folder;
     struct path* next;
};

char***
parseCommands(char *s)
{
     char* programSep = ";\n";
     char* argSep = " \t";
     char** progArray;
     int countProgs = 0;
     char* currProg;
     char progStr[strlen(s)];
     int index = 0;
     char*** parsedCommands;
     int countArgs = 0;
     char* currArg;
     int argIndex;

     strcpy(progStr,s);
     for (currProg = strtok(progStr, programSep); currProg; currProg = strtok(NULL,programSep))
     {
          countProgs++;
     }
     progArray = (char**) malloc((sizeof(char*)*(countProgs+1)));
     parsedCommands = (char***) malloc (sizeof(char**)*(countProgs+1));
     parsedCommands[countProgs] = NULL;
     progArray[countProgs] = NULL;
     for (currProg = strtok(s, programSep); currProg; currProg = strtok(NULL,programSep))
     {
          progArray[index] = (char*) malloc((sizeof(char)*(strlen(currProg)+1)));
          strcpy(progArray[index],currProg);
          index++;
     }
     for (index = 0; index < countProgs; index++)
     {
          countArgs = 0;
          char thisProg[strlen(progArray[index])];
          strcpy(thisProg, progArray[index]);
          char tmpstr[strlen(thisProg)];
          strcpy(tmpstr,thisProg);
          for (currArg = strtok(tmpstr, argSep);currArg;currArg = strtok(NULL,argSep))
          {
               countArgs ++;
          }
          
          parsedCommands[index] = (char**) malloc(sizeof(char*)*(countArgs+1));
          parsedCommands[index][countArgs] = NULL;
          argIndex = 0;
          
          for (currArg = strtok(thisProg, argSep);currArg;currArg = strtok(NULL,argSep))
          {
               parsedCommands[index][argIndex] = (char*) malloc((sizeof(char)*(strlen(currArg)+1)));
               strcpy(parsedCommands[index][argIndex],currArg);
               argIndex++;
          }		
     }
     index = 0;
     while(progArray[index])
     {
          free(progArray[index]);
          index++;
     }
     
     free(progArray);
     return parsedCommands;
}


char*
removewhitespace(char *s1)

{
      char *start = &s1[0];
      int i = 0;

      while(isspace(*(s1+i)))
      {
           i++;
      }


      start = &s1[i];
      s1 = &start[0];

      i = strlen(s1) -1;
      *(s1+i)='\0';
      i--;

      while(isspace(*(start+i)))
      {
             i--;
       }

      *(s1+i+1)='\0';
      return s1;

}



int main(int argc, char **argv)
{

     int who = RUSAGE_SELF;
     int who2 = RUSAGE_CHILDREN;
     char *prompt = "gragtah> ";
     char** cmd;
     struct node* running = (struct node*) malloc (sizeof(struct node));
     running->proc = 0; 
     running->next = NULL;
     running->paused=0;
     running->command = NULL;
     char*** parsedInput;
     char buffer[1024];
     char* mode = "sequential";
     int ex = 0;
     int fileend = 0;
     struct rusage cpuStats, cpuStats2;
     struct timeval userTime, userTime2, userTime3;
     struct timeval systemTime, systemTime2, systemTime3;
     int usageErr, usageErr2;
     FILE *datafile = NULL;
     struct path* PATH = (struct path*) malloc(sizeof(struct path));
     struct stat statresult;
     char currLine[500];
     PATH->folder = NULL;
     PATH->next = NULL;
     datafile = fopen("./shell-config", "r");
     if (datafile == NULL)
     {
          printf("Missing shell-config. Please use full paths for programs.\n");
     }
     else
     {
          while(fgets(currLine,500,datafile))
          {
               if (currLine[strlen(currLine)-1]=='\n')
               {
                    currLine[strlen(currLine)-1] = '\0';
               }
               if (currLine[strlen(currLine)-1] != '/')
               {
                    
                    currLine[strlen(currLine) + 1] = '\0';
                    currLine[strlen(currLine)] = '/';
                    
               }

               if (PATH -> folder == NULL){
                    PATH->folder = (char*) malloc (sizeof(char)*(strlen(currLine)+1));
                    strcpy(PATH->folder,currLine);
                 
               }
               else {
                    struct path* tmp = (struct path*) malloc (sizeof(struct path));
                    tmp->folder = (char*) malloc(sizeof(char)*(strlen(currLine)+1));
                    strcpy(tmp->folder,currLine);
                    tmp->next = PATH;
                    PATH = tmp;

               }
          }
     }
     printf("%s", prompt);
     fflush(stdout);
     struct pollfd pfd[1];
     pfd[0].fd = 0;
     pfd[0].events = POLLIN;
     pfd[0].revents = 0;
     int somethingDone = 0;

     while (1)
     {
          int rv = poll(&pfd[0],1,250);
          somethingDone = 0;
          
          if (rv == 1 && pfd[0].revents == POLLIN){
               somethingDone = 1;
               char* result;
               fgets(buffer,1025,stdin);
               result = removewhitespace(buffer);
               if (result == NULL)
                    break;
               else if (rv == -1)
               {
                    printf("Poll failed, exiting\n");
                    exit(1);
               }
          }
               
          if (feof(stdin)){

               fileend = 1;
          }
          
          int index;
          for(index = 0; index < sizeof(buffer);index++) 
          { 
               if (buffer[index] == '#'){
                    buffer[index] = '\0';
                    break;
               }
               
          }
          parsedInput = parseCommands(buffer);
          int curr = 0;
          while(parsedInput[curr] && ex == 0 && somethingDone == 1)
          {
              
               if (!strcmp(mode,"sequential"))   // SEQUENTIAL MODE
               {
                    while (parsedInput[curr])
                    {
                         cmd = parsedInput[curr];
                         curr++;
                         if (cmd[0] == NULL)
                              continue;
                         while (isblank(cmd[0][0]) && cmd[0][0]!='\0'){
                              cmd[0]++;
                         }
                         if (cmd[0] == '\0')
                              continue;
                         if (!strcmp(cmd[0],"exit"))
                         {
                              if (running->proc)
                              {
                                   printf("Cannot exit while processes are running, please try again later.\n");
                                   continue;
                              }
                              else
                              {
                                   ex = 1;
                                   break;
                              }
                         }
                         else if (!strcmp(cmd[0],"mode"))
                         {
                              if (cmd[1] == NULL)
                              {
                                   printf("Current mode is: %s\n",mode);
                                   continue;
                              }
                              else if (!strcmp(cmd[1],"parallel") || !strcmp(cmd[1],"p"))
                              {
                                   mode = "parallel";
                                   printf("Mode switched to: %s\n",mode);
                                   continue;
                              }
                              else if (!strcmp(cmd[1],"sequential") || !strcmp(cmd[1],"s"))
                              {
                                   mode = "sequential";
                                   printf("Mode switched to: %s\n",mode);
                                   continue;
                              }
                              else
                              {
                                   printf("Current mode is: %s\n",mode);
                                   continue;
                              }
                         }
                         
                         else if(!strcmp(cmd[0],"jobs"))
                         {
                              struct node* tmpProc;
                              tmpProc= running;
                              printf("PID\tCMD\tPAUSED\n");
                              while (tmpProc->proc)
                              {
                                   
                                   printf("%d\t%s\t%d\n",tmpProc->proc,tmpProc->command,tmpProc->paused);
                                   tmpProc = tmpProc->next;
                              }
                              continue;
                         }
                         else if(!strcmp(cmd[0],"pause"))
                         {
                              if(!(cmd[1]))
                              {
                                   printf("Please provide a PID to pause.\n");
                                   continue;
                              }
                              pid_t pausePid = atoi(cmd[1]);

                              int pauseResult = kill(pausePid,SIGSTOP);
                              if (pauseResult != 0 )
                                   printf("PID not found\n");
                              else
                              {
                                   struct node* tmpProc;
                                   tmpProc = running;
                                   while(tmpProc->proc != pausePid)
                                   {
                                        tmpProc = tmpProc-> next;
                                   }
                                   tmpProc->paused = 1;
                              }
                              continue;
                              
                         }
                         else if(!strcmp(cmd[0],"resume"))
                         {
                              if(!(cmd[1]))
                              {
                                   printf("Please provide a PID to resume.\n");
                                   continue;
                              }
                              pid_t resumePid = atoi(cmd[1]);

                              int resumeResult = kill(resumePid,SIGCONT);
                              if (resumeResult != 0 )
                                   printf("PID not found\n");
                              else
                              {
                                   struct node* tmpProc;
                                   tmpProc = running;
                                   while(tmpProc->proc != resumePid)
                                   {
                                        tmpProc = tmpProc-> next;
                                   }
                                   tmpProc->paused = 0;
                              }
                              continue;
                              
                         }
                         else if (!strcmp(cmd[0],mode))
                              continue;

                         pid_t p = fork();
                         if (p == 0) {
                              /* in child */
                              rv  = stat(cmd[0], &statresult);
                              
                              if (rv < 0) 
                              {
                                   struct path* currPath;
                                 if (PATH->folder != NULL) 
                                {
                                   currPath = PATH;
                                   while (currPath)
                                   {
                                        char* currDirectory = (currPath->folder);
                                        
                                        int currDirlen;

                                        currDirlen = strlen(currDirectory);
                                        
                                        char tmpCmd[currDirlen + strlen(cmd[0])-1];
                                        if (currDirectory!=NULL)strcpy(tmpCmd,currDirectory);
                                        strcpy(tmpCmd+currDirlen,cmd[0]);
                                        rv = stat(tmpCmd, &statresult);
                                   
                                        if (rv == 0)
                                        {
                                             strcpy(cmd[0],tmpCmd);
                                             break;
                                        }
                                   
                                        currPath = currPath -> next;
                                   }
                                }
                                    if (execv(cmd[0], cmd) < 0) {
                                         fprintf(stderr, "execv failed: %s\n", strerror(errno));
                                    }

                                 _exit(0);
                              }
                         

                              else if (execv(cmd[0], cmd) < 0) {
                                   fprintf(stderr, "execv failed: %s\n", strerror(errno));
                              }

                         } else if (p > 0) {
                              /* in parent */
                              int rstatus = 0;
                              pid_t childp = wait(&rstatus);

                              assert(p == childp);

                             if(rstatus == 0) 
                               printf("Parent got carcass of child process %d\n", childp);
                             else 
                               fprintf(stderr, "execv failed: %s\n", strerror(errno));

                         } else {
                              /* fork had an error; bail out */
                              fprintf(stderr, "fork failed: %s\n", strerror(errno));
                         }

                    }
               }

               else             //PARALLEL MODE
               {
                    while (parsedInput[curr])
                    {
                         cmd = parsedInput[curr];
                         curr++;
                         if (cmd[0] == NULL)
                              continue;
                         while (isblank(cmd[0][0]) && cmd[0][0]!='\0'){
                              cmd[0]++;
                         }
                         if (cmd[0] == '\0')
                              continue;
                         if (!strcmp(cmd[0],"exit"))
                         {
                              if (running->proc)
                              {
                                   printf("Cannot exit while processes are running, please try again later.\n");
                                   continue;
                              }
                              else
                              {
                                   ex = 1;
                                   break;
                              }
                         }
                         if (!strcmp(cmd[0],"mode"))
                         {
                              if (cmd[1] == NULL)
                              {
                                   printf("Current mode is: %s\n",mode);
                                   continue;
                              }
                              else if (!strcmp(cmd[1],"parallel") || !strcmp(cmd[1],"p"))
                              {
                                   mode = "parallel";
                                   printf("Mode switched to: %s\n",mode);
                                   continue;
                              }
                              else if (!strcmp(cmd[1],"sequential") || !strcmp(cmd[1],"s"))
                              {
                                   mode = "sequential";
                                   printf("Mode switched to: %s\n",mode);
                                   continue;
                              }
                              else
                              {
                                   printf("Current mode is: %s\n",mode);
                                   continue;
                              }
                         }
                         if(!strcmp(cmd[0],"jobs"))
                         {
                              struct node* tmpProc;
                              tmpProc= running;
                              printf("PID\tCMD\tPAUSED\n");
                              while (tmpProc->proc)
                              {
                                   
                                   printf("%d\t%s\t%d\n",tmpProc->proc,tmpProc->command,tmpProc->paused);
                                   tmpProc = tmpProc->next;
                              }
                              continue;
                         }
                         if(!strcmp(cmd[0],"pause"))
                         {
                              if(!(cmd[1]))
                              {
                                   printf("Please provide a PID to pause.\n");
                                   continue;
                              }
                              pid_t pausePid = atoi(cmd[1]);

                              int pauseResult = kill(pausePid,SIGSTOP);
                              if (pauseResult != 0 )
                                   printf("PID not found\n");
                              else
                              {
                                   struct node* tmpProc;
                                   tmpProc = running;
                                   while(tmpProc->proc != pausePid)
                                   {
                                        tmpProc = tmpProc-> next;
                                   }
                                   tmpProc->paused = 1;
                              }
                              continue;
                              
                         }
                         if(!strcmp(cmd[0],"resume"))
                         {
                              if(!(cmd[1]))
                              {
                                   printf("Please provide a PID to resume.\n");
                                   continue;
                              }
                              pid_t resumePid = atoi(cmd[1]);

                              int resumeResult = kill(resumePid,SIGCONT);
                              if (resumeResult != 0 )
                                   printf("PID not found\n");
                              else
                              {
                                   struct node* tmpProc;
                                   tmpProc = running;
                                   while(tmpProc->proc != resumePid)
                                   {
                                        tmpProc = tmpProc-> next;
                                   }
                                   tmpProc->paused = 0;
                              }
                              continue;
                              
                         }
                         if (!strcmp(cmd[0],mode))
                              continue;
                         pid_t p = fork();
                         char newCmdBuff[500];
                         if (p == 0) {
                              /* in child */
                              rv  = stat(cmd[0], &statresult);
                         
                              if (rv < 0)
                              {
                                   struct path* currPath;
                                 if (PATH->folder != NULL)
                                 {
                                   currPath = PATH;
                                   while (currPath)
                                   {
                                   
                                        char* currDirectory = (currPath->folder);
                                        char tmpCmd[strlen(currDirectory) + strlen(cmd[0])-1];
                                        strcpy(tmpCmd,currDirectory);
                                        strcpy(tmpCmd+(strlen(currDirectory)),cmd[0]);
                                        rv = stat(tmpCmd, &statresult);
                                   
                                        if (rv == 0)
                                        {;
                                             strcpy(newCmdBuff,tmpCmd);
                                             cmd[0] = newCmdBuff;
                                             break;
                                        }
                                  
                                   
                                        currPath = currPath -> next;
                                   }
                                 }
                                    if (execv(cmd[0], cmd) < 0) {
                                         fprintf(stderr, "execv failed: %s\n", strerror(errno));
                                    }

                                 _exit(0);
                              
                              }
                         
                        
                              else if (execv(cmd[0], cmd) < 0) {
                                   fprintf(stderr, "execv failed: %s\n", strerror(errno));
                              }

                         } else if (p > 0) {
                              /* in parent */
                              struct node* tmp = (struct node*) malloc (sizeof(struct node));
                              tmp->command = (char*)malloc(sizeof(char)*(strlen(cmd[0]+1)));
                              strcpy(tmp->command,cmd[0]);
                              tmp->proc = p;
                              tmp->next = running;
                              tmp->paused=0;
                              running = tmp;

                         } else {
                              /* fork had an error; bail out */
                              fprintf(stderr, "fork failed: %s\n", strerror(errno));
                         }

                    }
               }
          }
          struct node* placeHolder = running;
          int exitedArr[500];
          int exitedIndex = 0;
          while(placeHolder->proc)
          {
               
               pid_t currPid = placeHolder->proc;
               int waitResult;
               int waitStatus;
               waitResult = waitpid(currPid,&waitStatus,WNOHANG);
               if (waitResult == -1)
               {
                    printf("Wait error\n");
                    
               }
               else if (waitResult == currPid)
               {
                     if(waitStatus == 0) printf("Parent got carcass of child process %d\n", currPid);
                     else fprintf(stderr, "execv failed: %s\n", strerror(errno));
               
                    printf("%s", prompt);
                    fflush(stdout);
                    exitedArr[exitedIndex] = currPid;
                    exitedIndex++;
                    
               }
               placeHolder = placeHolder->next;
              

          }
          exitedIndex--;
          while(exitedIndex >= 0)
          {
               placeHolder = running;
               int thisPid = exitedArr[exitedIndex];
               exitedIndex--;
               if (placeHolder-> proc == thisPid)
               {
                    running = running->next;
                    free(placeHolder->command);
                    free(placeHolder);
                    continue;
               }
               while(placeHolder->next->proc != thisPid)
               {
                    placeHolder = placeHolder->next;
               }
               struct node* tmpProc = placeHolder->next->next;
               free(placeHolder->next->command);
               free(placeHolder->next);
               placeHolder->next = tmpProc;
                  
          }
          int parsedFree = 0;
          while(parsedInput[parsedFree])
          {
               int tok = 0;
               while(parsedInput[parsedFree][tok])
               {
                    free(parsedInput[parsedFree][tok]);
                    tok++;
               }
               free(parsedInput[parsedFree]);
               parsedFree ++;
          }
          if (parsedInput)
               free(parsedInput);
          if (ex == 1 || fileend == 1)
          {
               
               while(PATH){
                    struct path* tmpPath = PATH->next;
                    free(PATH->folder);
                    free(PATH);
                    PATH = tmpPath;
               }
               free(PATH);
               struct node* tmpRunning;
               tmpRunning = running;
               while(running)
               {
                    tmpRunning = running->next;
                    free(running->command);
                    free(running);
                    running = tmpRunning;
               }
               
               usageErr = getrusage(who, &cpuStats);
               if (usageErr != 0)
                    exit(1);
               userTime = cpuStats.ru_utime;
               systemTime = cpuStats.ru_stime;
               
               usageErr2 = getrusage(who2, &cpuStats2);
               if (usageErr2 != 0)
                    exit(1);
               userTime2 = cpuStats2.ru_utime;
               systemTime2 = cpuStats2.ru_stime;

               timeradd(&userTime, &userTime2, &userTime3);
               timeradd(&systemTime, &systemTime2, &systemTime3);
               printf("\nUser time:      %ld.%06ld\n", userTime3.tv_sec, userTime3.tv_usec);
               printf("System time:    %ld.%06ld\n", systemTime3.tv_sec, systemTime3.tv_usec);

               exit(EXIT_SUCCESS);
          }
          
          if (somethingDone == 1)
          {
               printf("%s", prompt);
               fflush(stdout);
          }

     }
     fclose(datafile); 
     return 0;
}

