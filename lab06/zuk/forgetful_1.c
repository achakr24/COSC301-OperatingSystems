#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "forgetful.h"
/* Josh Zukoff
   Zach Rabin
   Connor Ford
   Only Part 1
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

     int internalRequestSize = requestSize + 3*(sizeof(int));
     assert(internalRequestSize >= 12);
     /* Each block has a header with a size, next, and free bit (0 is nonfree, 1 is free) */
     if (freeList == NULL)
     {
          vrv = sbrk(internalRequestSize);
          if (vrv == -1)
          {
               //No more memory in the system
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
          int* currEntry = freeList;
          int allocated = 0;
         
          while ((*currEntry < (requestSize) ||  *(currEntry+2) != 1))
          {
               if (*(currEntry + 1) == 0 ) // end of freeList, must allocate more space
               {
                   
                    vrv = sbrk(internalRequestSize);
                    if (vrv == -1)
                    {
                         //No more memory in the system
                         return NULL;
                    }
                    irv = (int*) vrv;
                    *irv = requestSize;
                    *(irv + 1) = 0;
                    *(irv + 2) = 0;
                    *(currEntry + 1) = vrv;;
                    allocated = 1;
                    break;
               }
               else
                    currEntry = *(currEntry + 1);
              
              
          }
          if (allocated == 0) //while loop ended by finding a space that fit
          {
               // if space after what we need is not big enough for a headerall we need to do is change free to allocated and return the pointer, the other entries should be filled out and there is enough free space to fit our request
               if (*currEntry < (internalRequestSize + 3*sizeof(int) + 1))
               {
                    irv = currEntry;
                    *(irv+2) = 0;
               }
               //else want to split chunk of memory
               else
               {
                    void * voidCurr = (void *) currEntry;
                    *((int *) (voidCurr + internalRequestSize)) =  (*currEntry) - internalRequestSize;
                    *((int*)(voidCurr + internalRequestSize + sizeof(int))) = *(currEntry + 1);
                    *((int*)(voidCurr + internalRequestSize + 2*sizeof(int))) = 1;
                    *(currEntry + 1) = (voidCurr + internalRequestSize);
                    *(currEntry + 2) = 0;
                    *(currEntry) = requestSize;
                    irv = currEntry;
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
    int *intBlock = (int *) ptr;
    
    *(intBlock - 1) = 1;
    /* coalesce blocks */
    int *currEntry = (int *) freeList;
    while (1)
    {
         if (*(currEntry + 1)==0)
              break;
         if (*(currEntry + 2) == 1)
         {
              int* nextEntry = *(currEntry + 1);
              if (*(nextEntry + 2) == 1)
              {
                   *(currEntry + 1) = *(nextEntry + 1); //point next to the correct place
                   *(currEntry) += *nextEntry + 3*sizeof(int);
                   /* do not advance currEntry, this way more than one spot can coalesce */
                   
              }
              else
                   currEntry = *(currEntry + 1);
         }
         else
              currEntry = *(currEntry + 1);
         
    }
    
    
    return;
}


void dumpMemoryMap(void)
{
     fprintf(stderr, "*** begin heap map ***\n");
     fprintf(stderr, "block\tsize\tfree?\taddress\n");
     fprintf(stderr, "_____\t____\t______\t_______\n");
         
	
     /* your heap map implementation */
     int *currEntry = (int * ) freeList;
     int currBlock = 0;
     int beginAddress = 0;
     int endAddress = 0;
     while (1)
     {
          int size = *currEntry;
          int isFree = *(currEntry + 2);
          endAddress = beginAddress + size + 3*sizeof(int) - 1;
          //int beginAddress = (int) (currEntry+3) ;
          //int endAddress = beginAddress + *currEntry;
          fprintf(stderr, "%d\t%d\t%d\t%d-%d\n",currBlock,size,isFree,beginAddress,endAddress);
          beginAddress = endAddress + 1;
          currBlock ++;
          if (*(currEntry + 1) == 0)
               break;
          else
          {
               currEntry = *(currEntry + 1);
              
          }   
     }

     fprintf(stderr, "*** end heap map ***\n");
}

