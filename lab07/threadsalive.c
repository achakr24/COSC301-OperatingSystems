/*
 * 
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <strings.h>
#include <string.h>

#include "threadsalive.h"


/* stage 1 library functions */

void ta_libinit(void)
{
    return;
}

void ta_create(void (*func)(void *), void *arg)
{
    return;
}

void ta_yield(void)
{
    return;
}

int ta_waitall(void)
{
    return -1;
}

