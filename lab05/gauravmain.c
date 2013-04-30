/*
 * lab05 (shell) main.c
 *
 * lab partner names and other information up here, please
 *
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




char** tokenify(char *s, char *delim)
{
  char **result = (char**) malloc( strlen(s)*sizeof(char) );
  char *tok = NULL;
  tok = strtok( s, delim); //" \n");
  int i = 0;
  while (tok != NULL)
  {
     *(result + i) = tok;
     i += 1;
     tok = strtok(NULL, delim); //" \n");
  }
  *(result + i) = NULL;

  return result;

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

  int mode = 0; // 0 = sequential, 1=parallel

    char *prompt = "hitme> ";
    printf("%s", prompt);
    fflush(stdout);
    
//    char buffer[1024];
    char* buffer = malloc(1024*sizeof(char));
    while (fgets(buffer, 1024, stdin) != NULL)
    {
       //remove whitespace   
       buffer = removewhitespace(buffer);

       //deal with comments/'#'
       int index=0;
       int length= strlen(buffer);
       while (index<length){

         if(buffer[index]=='#') {
           *(buffer + index) ='\0'; 
           break;
         }
         index++;
       }

      // if command is not empty, process it 
      if(strcmp(buffer,"")) {


        if (!strcmp(buffer,"exit"))
        {
          exit(EXIT_SUCCESS);
        } // ?? rewrite this to search for it anywhere! or just add that as well.



          /* process current command line in buffer */
          /* just a hard-coded command here right now */


         char* copy = strdup(buffer);//orig);
         char a1[] ={';'}; 
         char a2[]={' ','\n'};
         char **cmdlist = tokenify(copy,a1);


         int i = 0;
         printf("tokenified <%s>.  next output should show each token on a separate line.\n", buffer);
         while (*(cmdlist+i)) {
             printf("\t<%s> ok \n", *(cmdlist+i));
             printf("number i is %d \n\n",i);
             i++;
         }
         


         
       //  char **clist = tokenify(*(cmdlist+1),a2);
       //  printf("\t<%s> \n", *(clist+0));
       //  printf("\t<%s> \n", *(clist+1));
         
         
         
         
         printf("BEGIN!!!! \n");
 
         //char **result = (char**) malloc( strlen(s)*sizeof(char) );
  
//         char **g[i]; // = (char**) malloc( strlen(s)*sizeof(char) );

         
        //char ***g = (char***) malloc (i * sizeof(char));
         char ***g;// = (char***) malloc (i * sizeof(char));

         printf("i was %d \n starting\n", i);

         int j=0;
         //while (cmdlist[j]) 
         for(j=0; j<i; j++)
         {
           //char** temp = tokenify(cmdlist[i],a2);

         //  g[j] = (char**) malloc(strlen(*(cmdlist+j)) * sizeof(char));
           //char **gj;// = (char**) malloc( sizeof(char));
          // gj = tokenify(*(cmdlist+j), a2);

           // *** OKAY JUST DO *** but dont allocate size then go along.
          
           g[j] = tokenify(*(cmdlist+j), a2);
        // *(g+j) = tokenify(*(cmdlist+j),a2);
      

        //  g[j] = gj; //tokenify(*(cmdlist+j),a2);
          //   printf("\t<%s>  ok \n", g[j][0] );
             printf("number j is %d \n",j);
            // j++;
         }



         //start stuff for individual commands here.
         // do depending on whether sequential or parallel
         printf("now next\n");
//
//         char** cmds = tokenify(cmdlist[0],a2);
//
//         int j=0;
//         while(cmds[j])
//         {
//           printf("<%s> ",cmds[j]);
//           j++;
//         }


//         printf("\nmore!! \n");
//

//         char** cmds1 = tokenify(cmdlist[1],a2);

//         printf("so now.. \n");
//         j=0;
//         while(cmds1[j])
//         {
//           printf("\t<%s> \n",cmds1[j]);
//           j++;
//         }
//
//         printf("\n");


         //char** cmds1 = tokenify(cmdlist[1],a2);

         //printf("\t<%s> <%s>  \n",cmds1[0], cmds1[1]);



         /*
         char*** cmds; //[i];
         i=0;
         while (cmdlist[i])
         {
           //cmds[i] = tokenify(cmdlist[i],a2);
           *(cmds+i) = tokenify(cmdlist[i],a2);
           i++;
         }


         printf("ok NOWWW:\n");

         i = 0;
         printf("tokenified <%s>.  next output should show each token on a separate line.\n", buffer);
         while (cmds[i]) {
           printf("here:\n");
             printf("\t<%s> ok \n", *(cmds[i]));
             i++;
         printf("number i is %d \n",i);
         }
         

         printf("ok done\n");


         */


          char *cmd[] = { "/bin/ls", "-ltr", ".", NULL };

          pid_t p = fork();
          if (p == 0) {
              /* in child */
              if (execv(cmd[0], cmd) < 0) {
                  fprintf(stderr, "execv failed: %s\n", strerror(errno));
              }

          } else if (p > 0) {
              /* in parent */
              int rstatus = 0;
              pid_t childp = wait(&rstatus);

              /* for this simple starter code, the only child process we should
                 "wait" for is the one we just spun off, so check that we got the
                 same process id */ 
              assert(p == childp);

              printf("Parent got carcass of child process %d, return val %d\n", childp, rstatus);
          } else {
              /* fork had an error; bail out */
              fprintf(stderr, "fork failed: %s\n", strerror(errno));
          }

      }

       printf("%s", prompt);
       fflush(stdout);
    }



    return 0;
}

