/*
 * 
 */

#ifndef __THREADSALIVE_H__
#define __THREADSALIVE_H__

void ta_libinit(void);
void ta_create(void (*)(void *), void *);
void ta_yield(void);
int ta_waitall(void);

#endif /* __THREADSALIVE_H__ */
