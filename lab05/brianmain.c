	
/*
 * lab05 (shell) main.c
 *
 * Brian Merrifield
 * Adam Lock
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
#include <sys/time.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <poll.h>
#include <signal.h>
#include <errno.h>
#include <assert.h>
#include "tokenify.h"

int main(int argc, char **argv)
{
    char *prompt = "yeah what do you want> ";
    printf("%s", prompt);
    fflush(stdout);

    int mode = 0;
    int exitatend=0;
    char buffer[1024];
    while (fgets(buffer, 1024, stdin) != NULL)
    {
    if(checkenter(buffer)){
        printf("%s", prompt);
        continue;
    }

    char *buf = stripwhite(buffer);
        char *del1=";";
    buf=checkhash(buffer);
        char **cmd = tokenify(buf, del1);
        int i=0;

        while(cmd[i]!=NULL){
            char *del2= " ";
            char** delcmd = tokenify(cmd[i], del2);
        /*might have to check hash again*/
            exitatend=checkexit(*delcmd);
        if(exitatend){
        i++;
        if(cmd[i]==NULL){
            exitshell(delcmd);
        }
        continue;
        }
            int tempmode=checkmode(delcmd);

            if(tempmode==-1){
                printf("Error: This mode does not exist try again.\n");
        } else if ((tempmode==0) || (tempmode==1)) {
        mode = tempmode;
        } else if (tempmode==2) {
        printf("Current Execution Mode:  ");
            if (mode==0) { printf("Sequential\n"); }
        else { printf("Parallel\n"); }
            } else {
        if(mode==0){
                    pid_t p = fork();
                    if (p == 0) {
                        /* in child */
                            if (execv(delcmd[0], delcmd) < 0) {
                                    fprintf(stderr, "execv failed: %s\n", strerror(errno));
                            }   
                    } else if (p > 0) {
                        /* in parent */
                            int rstatus = 0;
                            pid_t childp = wait(&rstatus);
                            /* for this simple starter code, the only child process we should "wait"*/
                /*for is the one we just spun off, so check that we got the same process id */
                            assert(p == childp);
                            printf("Parent got carcass of child process %d, return val %d\n", childp, rstatus);
                    } else {
                   /* fork had an error; bail out */
                            fprintf(stderr, "fork failed: %s\n", strerror(errno));
                    }
        }
        else if(mode==1){
            pid_t p = fork();
                    if (p == 0) {
                        /* in child */
                            if (execv(delcmd[0], delcmd) < 0) {
                                    fprintf(stderr, "execv failed: %s\n", strerror(errno));
                            }
            }else if (p > 0&&cmd[i+1]==NULL) {
                        /* in parent */
                while(i){
                                int rstatus = 0;
                                pid_t childp = wait(&rstatus);
                                /* for this simple starter code, the only child process we should "wait"*/
                    /*for is the one we just spun off, so check that we got the same process id */
                                assert(p == childp);
                                printf("Parent got carcass of child process %d, return val %d\n", childp, rstatus);   
                    i--;
                }
                break;
                    }else if(p<0) {
                           /* fork had an error; bail out */
                            fprintf(stderr, "fork failed: %s\n", strerror(errno));
                    }
        }
            }
            i++;
        if(exitatend&&cmd[i]==NULL){
        exitshell(delcmd);
        }
        }
    free(cmd);
    printf("%s", prompt);
    fflush(stdout);
    }
    return 0;
}

