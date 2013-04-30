/*
 * Gaurav Ragtah, 9/14/2011
*/

// use -lm when compiling because linux apparently links math library differently
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <math.h>
#include <ctype.h>
#include <sys/resource.h>

#include "list.h"

void usage(char *program)
{
    fprintf(stderr, "usage: %s [<datafile>]\n", program);
    exit(1);
}


int main(int argc, char **argv)
{
    int who = RUSAGE_SELF;
    struct rusage ru;

    struct element * head = NULL;

    FILE *datafile = NULL;

    /* find out how we got invoked and deal with it */
    switch (argc)
    {
        case 1:
            /* only one program argument (the program name) */ 
            /* just equate stdin with our datafile */
            datafile = stdin;        
            break;

        case 2:
            /* two arguments: program name and input file */
            /* open the file, assign to datafile */
            datafile = fopen(argv[1], "r");
            if (datafile == NULL) {
                printf("Unable to open file %s: %s\n", argv[1], strerror(errno));
                exit(-1);
            }
            break;

        default:
            /* more than two arguments?  throw hands up in resignation */
            usage(argv[0]);
    }

    /* 
     * you should be able to just read from datafile regardless 
     * whether it's stdin or a "real" file.
     */

    int i=0,j=0,k=0;
    char c=' ';
    char num[80];
    char line[80];
    double d=0;

    while(fgets(line, 80, datafile) != NULL)
        {
             for(i=0;i<strlen(line);++i)
             {
                  if (line[i]=='#') break;

                  c=line[i];

                  while(isdigit((int)c)||c=='-'||c=='.')
                  {
                    num[j]=c; ++j; ++i;
                    if(i<strlen(line)) c=line[i];
                    else break;
                    k=1;
                  }
                  
                  num[j]='\0';
                  d=strtod(num,NULL);

                  if(k==1 && floor(d)==d) add_to_list(atoi(num),&head);
                  j=0;
                  k=0; 
             }

        }


    fclose(datafile);
    print_list(&head);
    deallocate_list(head);

    struct timeval utim,stim;
    getrusage(who, &ru);
    utim = ru.ru_utime;
    stim = ru.ru_stime;
    printf("User time   : %d.%06d\n", utim.tv_sec, utim.tv_usec);
    printf("System time : %d.%06d\n", stim.tv_sec, stim.tv_usec);

    return 0;
}

