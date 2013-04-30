#ifndef __LIST_H__
#define __LIST_H__

/* your list data structure declarations */

struct element
{
  int value;
  struct element *next;
};


/* your function declarations associated with the list */


void add_to_list(int, struct element** );
void print_list(struct element** );
void deallocate_list(struct element*);


#endif // __LIST_H__
