/*
 * lab04 (shell) main.c
 *
 * Roberto Segebre
 * Avi Das
 * Ahmad 
 */

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
#include <poll.h>
#include "list.h"
#include "filelist.h"

int flag=0;
int exitflag=0;

//Prints out system and user time

void listjobs(){
	
}

void pausePID(pid_t pid){
	kill(pid,SIGSTOP);
}

void resumePID(pid_t pid){
	kill(pid,SIGCONT);
}

void sysgetinf()
{
    int who = RUSAGE_CHILDREN;	
    struct rusage usage; 
    struct rusage *p = &usage;
    int ret = getrusage(who, p);
    if (ret == -1 )
	perror("EFAULT");
     	
    printf("\nUser time:  %lf \n",  ((double)p->ru_utime.tv_sec)*1000000 + p->ru_utime.tv_usec);
	printf("System time:  %lf \n",  ((double) p->ru_stime.tv_sec)*1000000 + p->ru_stime.tv_usec);

}

char * trim(char * s) {
    char *ptr;    
    if(!s) return NULL;
    if(!*s)
    return s;
    for(ptr=s+strlen(s)-1;(ptr>=s) && isspace(*ptr); --ptr);
    ptr[1]='\0';
    for(ptr=s;(*ptr!='\0') && isspace(*ptr); ++ptr);
    s = ptr;  
    return s;

}

char** tokenify(char* h, char * s) {
	
	if (strlen(h) == 0 ) return NULL;

	int words = 1, i = 0,j = 0;
	
	for (;i < strlen(h);i++) {
	    if (isspace(h[i])) words++;
	}
	
	char** arr = (char **) malloc((1000+1)*sizeof(char *));
	char * tmp;
	h=trim(h);
	
	if (h[0] == '#' ) {
	    arr[j] = NULL;
	    return arr;
	}
	tmp = strtok(h,s);
	arr[j] = tmp;
	
	j++;
	
	while ((tmp = trim(strtok(NULL,s))) != NULL) {
	    if( tmp[0] == '#') {
		 j++;
		 break;
	    }
	    arr[j] = trim(tmp);		
	    j++;
	}
	arr[j] = NULL;
	
	return arr;
}



pid_t runcommand(char **argv)
{
    pid_t pid = fork();
    if (pid == 0)
    {
        if (execv(argv[0], argv) < 0)
        {
            fprintf(stderr, "execv failed: %s\n", strerror(errno));
	    exit(-1);
        }
    }

    /* we're in the parent process if we get here */
    return pid;
}


void waitforchild(pid_t pid)
{
    /* example using waitpid: the parent will block until the child
       process dies */
    int childstatus = 0;
    pid_t rv = waitpid(pid, &childstatus, 0);
    if (rv == pid)
        printf("child process %d has exited with value %d\n", (int)pid, childstatus);
    else if (rv < 0)
        fprintf(stderr, "error waiting for child to complete: %s\n", strerror(errno));
}

/*process(char** cmd2) takes an array of string tokenized by ';' and then process each line, and executes accordingly*/

void parprocess(char** asdf, int s);

void seqprocess(char** cmd2, int i)    
{

   int j=0;
    while (cmd2[i] != NULL) 
    {
	
	char **cmd3 = tokenify(cmd2[i], " \n\t");
	if (cmd3 == NULL) break;
	//if(cmd3[0] == NULL) break;
	
	if(!strcmp(trim(cmd3[0]),"exit"))
	{
		exitflag = 1;   
		i++;
		continue;
	}
	int cmpmode = strcmp(trim(cmd3[0]),"mode");
	if(!strcmp(trim(cmd3[0]),"exit")) exitflag = 1;

	if( cmpmode == 0 && cmd3[1] == NULL) 
	{ 
            	printf("You are in sequential mode\n");
	    	j=1;
	}
	if(j!=1) 
	{
	    if(cmpmode == 0 && (strcmp(trim(cmd3[1]),"p") == 0 || strcmp(trim(cmd3[1]),"parallel") == 0))  
	    {
		flag = 1;
	        parprocess(cmd2,++i);
		free(cmd3); 
	 	return;
	    }
	    else if (cmpmode == 0 ){
		printf("You are in sequential mode\n");
	    }		   
	free(cmd3); 
	}	    

	if(cmd2[i] != NULL || strlen(cmd2[i]) > 3)  
	    {   
	    if (cmd3[0] != NULL && cmpmode !=0 )
	        {
	        pid_t baby = runcommand(cmd3);
		waitforchild(baby);
                }	
	    }
	i++;
	j=0;
      }
      if(exitflag==1){
	sysgetinf();
	exit(1);
      }		
}



void parprocess(char ** cmd2,int i)
{
	node *h = NULL;
	node **h1 = NULL;
	h1 = &h;
	
	int j=0;
	
	while (cmd2[i] != NULL) 
	{

		char **cmd3 = tokenify(cmd2[i], " \n\t");
		if (cmd3 == NULL) break;
		//if(cmd3[0] == NULL) break;
		if(!strcmp(trim(cmd3[0]),"exit"))
		{
			exitflag = 1;   
			i++;
			continue;
		}
		
		
		if(strcmp(cmd3[0],"mode")==0 && cmd3[1] == NULL) 
		{ 
	    		printf("You are in parallel mode\n"); 
	    		j=1;
		}
		if(j!=1) 
		{
			if(strcmp(trim(cmd3[0]),"mode") == 0 && (strcmp(trim(cmd3[1]),"s")==0||strcmp(trim(cmd3[1]),"sequential")==0))  
			{
	 		   flag=0;		   
	 		   seqprocess(cmd2,++i); 
			   free(cmd3);
			   freelist(h);
	  		   return;
			}
			else if (strcmp(trim(cmd3[0]),"mode") == 0)  {
				printf("You are in parallel mode\n");
	   		}    
		}
	  
		if(cmd2[i] != NULL || strlen(cmd2[i]) > 3)  
		{   
		        if (cmd3[0] != NULL && strcmp(trim(cmd3[0]),"mode")!=0)
			{	    
				pid_t baby = runcommand(cmd3);
				add(baby,h1);
			}
	    	}
	    	i++; j=0;
		free(cmd3);
	}
	
	node *tmp = h;
	while (tmp != NULL) {
	    waitforchild(tmp->pid);
	    tmp = tmp->next;
	}
	freelist(h);
	if(exitflag==1){
	    sysgetinf();	
	    exit(1);
      }	
	
}



int main(int argc, char **argv)
{
    // assume initially that we're in interactive mode
    FILE *inputstream = stdin;

    // if we get more than one command line arg, we're
    // in batch mode
    int batchmode = argc > 1;
    
    if (argc > 2) {
	fprintf(stderr, "Error: Too many arguments given when starting program: %s\n", strerror(errno));
        exit(-1);
    } 

    if (batchmode) 
    {
        inputstream = fopen(argv[1], "r");
        if (inputstream == NULL)
        {
            fprintf(stderr, "Error when starting batch mode, you are being taken to interactive mode: %s\n", strerror(errno));
        }
	
	char tmpbuf[1000];
	while ((fgets(tmpbuf, 1000, inputstream)) != NULL) {
	    printf("\n-----%s\n",tmpbuf);
	    char **cmd0 = tokenify(tmpbuf, ";");
	    if(flag==0) seqprocess(cmd0,0);
 	    else if(flag==1) parprocess(cmd0,0);
	    free(cmd0);

	}
	if (fclose(inputstream) != 0 ) {
	    perror("EBADF");
	    exit(1);
         }
	return 0;
	
    }


    // at this point, you know whether you're in batch mode or not, and
    // you've got the variable inputstream to read commands from

    char *prompt = "Prompt> ";
    printf("%s", prompt);
    fflush(stdout);
    
    char buffer[1024];

    while (fgets(buffer, 1024, stdin) != NULL)
    {
  	char **cmd2 = tokenify(buffer, ";");
	if(flag==0) seqprocess(cmd2,0);
	else if(flag==1) parprocess(cmd2,0);
	free(cmd2);
        printf("%s", prompt);
	fflush(stdout);
	// /bin/ps -l; /bin/ls -l; /bin/ps -l; /bin/ls -l; 
    }
    sysgetinf();	
    return 0;
}

