#include <stdio.h>
#include <stdlib.h>
#include "list.h"

/* your list function definitions */

void add_to_list(int number, struct element** head)
{
  struct element* tmp = (struct element *) malloc(sizeof(struct element));
  tmp -> value = number;
  tmp -> next = NULL;

  if (*head == NULL)
  {
    *head = tmp;
  }
  else
  {
    // head is not NULL
    struct element* curr = *head;
    if(number < curr -> value)
    {
      //new head of list!
      tmp -> next = curr;
      *head = tmp;
    }
    else
    {
      while (curr -> next != NULL && number > curr -> next -> value)
      {
        curr = curr -> next;
      }
      tmp -> next = curr -> next;
      curr -> next = tmp;

    }

  }

}


void print_list(struct element** head)
{
  struct element* curr = *head;
  printf("*** List Contents Begin ***\n");
  while (curr != NULL)
  {
    printf("%d\n", curr -> value);
    curr = curr -> next;
  }
  printf("*** List Contents End ***\n");
}


void deallocate_list(struct element* head)
{
  struct element* tmp;

  while(head != NULL)
  {
    tmp = head;
    head = head -> next;
    free(tmp);
  }

}
