#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "forgetful.h"
/* 
  Gaurav Ragtah
  Lab 06
*/

static void *freeList = NULL;
static int atexitRegistered = 0;

void *malloc(size_t requestSize)
{
     
     void *rv = NULL;
     int *irv = NULL;
     void *vrv = NULL;
    
     if (!atexitRegistered)
     {
          atexitRegistered = 1;
          atexit(dumpMemoryMap);
     }

     /* Each block has a size, next, and free bit (0 =non/free; 1=free) */
     int internalRequestSize = requestSize + 3*(sizeof(int));
     assert(internalRequestSize >= 12);
     if (freeList == NULL)
     {
          vrv = sbrk(internalRequestSize);
          if (vrv == (void *) -1) //  -1
          {
               //No more memory
               return NULL;
          }
          irv = (int*) vrv;
          *irv = requestSize;
          *(irv + 1) = 0;
          *(irv + 2) = 0;
          freeList =(void * ) irv;
     }
     else
     {
          int* current = freeList;
          int allocated = 0;
         
          while ((*current < (requestSize) ||  *(current+2) != 1))
          {
               if (*(current + 1) == 0 ) // end of freeList-> allocate more space
               {
                   
                    vrv = sbrk(internalRequestSize);
                    if (vrv == (void *) -1)
                    {
                         //out of memory
                         return NULL;
                    }
                    irv = (int*) vrv;
                    *irv = requestSize;
                    *(irv + 1) = 0;
                    *(irv + 2) = 0;
                    *(current + 1) = (int*) vrv;
                    allocated = 1;
                    break;
               }
               else
                    current = *(current + 1);
              
              
          }
          if (allocated == 0) //find a space that fits
          {
               if (*current < (internalRequestSize + 3*sizeof(int) + 1))
               {
                    irv = current;
                    *(irv+2) = 0;
               }
               //split chunk of memory
               else
               {
                    void * voidCurr = (void *) current;
                    *((int *) (voidCurr + internalRequestSize)) =  (*current) - internalRequestSize;
                    *((int*)(voidCurr + internalRequestSize + sizeof(int))) = *(current + 1);
                    *((int*)(voidCurr + internalRequestSize + 2*sizeof(int))) = 1;
                    *(current + 1) = (voidCurr + internalRequestSize);
                    *(current + 2) = 0;
                    *(current) = requestSize;
                    irv = current;
               }
               
          }
     }
     

     rv = (void *)(irv + 3);
     return rv;
}


void free(void *ptr)
{
    
     if (ptr == NULL)
          return;
    
     
    /* your free implementation */
    int *block = (int *) ptr;
    
    *(block - 1) = 1;

    /* coalesce blocks */
    int *current = (int *) freeList;
    while (1)
    {
         if (*(current + 1)==0)
              break;
              
         int* next = *(current + 1);
         if (*(current + 2) == 1 && *(next + 2) == 1)
         {
                   *(current + 1) = *(next + 1);
                   *(current) += *next + 3*sizeof(int);
         }
         else
              current = *(current + 1);
         
    }
    
    
    return;
}


void dumpMemoryMap(void)
{
     fprintf(stderr, "*** begin heap map ***\n");
     fprintf(stderr, "\nblock\tsize\tfree?\taddress\n");
     fprintf(stderr, "-----\t-----\t-----\t-----\n");
         
	
     /* your heap map implementation */
     int *current = (int * ) freeList;
     int currBlock = 0;
     int startAddress = 0;
     int endAddress = 0;
     while (1)
     {
          int size = *current;
          int isFree = *(current + 2);
          endAddress = startAddress + size + 3*sizeof(int) - 1;
          fprintf(stderr, "%d\t%d\t%d\t%d-%d\n",currBlock,size,isFree,startAddress,endAddress);
          startAddress = endAddress + 1;
          currBlock ++;
          if (*(current + 1) == 0)
               break;
          else
          {
               current = *(current + 1);
              
          }   
     }

     fprintf(stderr, "*** end heap map ***\n");
}

