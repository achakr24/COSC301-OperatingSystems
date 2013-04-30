#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <sys/time.h>
#include <assert.h>


void test1()
{
    void *v1 = malloc(52);
    assert(v1);
    free (v1);

    v1 = malloc(52);
    assert(v1);
    free (v1);

    v1 = malloc(10);
    assert(v1);
    void *v2 = malloc(10);
    assert(v2);
    
    free (v1);
    free (v2);
}

void test2()
{
    void *v1 = malloc(100);
    assert(v1);
    void *v2 = malloc(200);
    assert(v2);
    free(v2);
    free(v1);
    v1 = malloc(200);
    assert(v1);
    v2 = malloc(50);
    assert(v2);
    void *v3 = malloc(100);
    assert(v3);
    free(v1);
    free(v2);
    v1 = malloc(100);
    assert(v1);
    v2 = malloc(150);
    assert(v2);
    free(v1);
    free(v3);
    free(v2);
}

void test3()
{
    test1();

    void *v1 = malloc(100);
    assert(v1);
    void *v2 = malloc(200);
    assert(v2);
    free(v1);
    void *v3 = malloc(50);
    assert(v3);
    void *v4 = malloc(50);
    assert(v4);
    free(v4);
    free(v3);
    free(v2);
}

void test4()
{
#define ASIZE 100
#define MAXBUF 1000
#define XITER 10

    void *myarray[ASIZE];
    int i = 0;
    for (i = 0; i < ASIZE; i++)
    {
        myarray[i] = malloc(random() % MAXBUF + 1);
        assert(myarray[i]);
    }
    
    for (i = 0; i < XITER; i++)
    {
        int idx = random() % ASIZE;
        free(myarray[idx]);
        myarray[idx] = malloc(random() % MAXBUF + 1);
        assert(myarray[idx]);
    }

    for (i = 0; i < ASIZE; i++)
    {
        free(myarray[i]);
    }
}

void test5()
{
    void *v1 = malloc(100);
    assert(v1);
    char *c = (char *)v1;
    *(c-1) = 0xaa;
    *(c+100) = random() % 255;
    *(c+101) = random() % 255;
    free(v1);
    void *v2 = malloc(200);
    assert(v2);
    v1 = malloc(100);
    assert(v1);
    free(v1);
    c = (char *)v2;
    *(c-1) = random() % 255;
    *(c-2) = random() % 255;
    *(c+200) = random() % 255;
    *(c+201) = random() % 255;
    free(v2);
}

void usage(char *progname)
{
    fprintf(stderr, "usage: %s -t<1..5>\n", progname);
    fprintf(stderr, "\t-t1: basic malloc/free test (stage 1)\n");
    fprintf(stderr, "\t-t2: slightly more complicated test (stage 1)\n");
    fprintf(stderr, "\t-t3: advanced malloc/free test (stage 1)\n");
    fprintf(stderr, "\t-t4: random malloc/free test (stage 1)\n");
    fprintf(stderr, "\t-t5: memory corruption test (stage 2)\n");
    exit(-1);
}


int main(int argc, char **argv)
{
    int testnum = 0;
    int c = 0;
    while ((c = getopt(argc, argv, "t:")) != EOF)
    {
        switch (c)
        {
            case 't':
                testnum = atoi(optarg);
                if (testnum < 1 || testnum > 5)
                    usage(argv[0]);
                break;

            default:
                usage(argv[0]);
                break;
        }
    }

    srandom(time(NULL));

    switch (testnum)
    {
        case 1:
            test1();
            break;
        case 2:
            test2();
            break;
        case 3:
            test3();
            break;
        case 4:
            test4();
            break;
        case 5:
            test5();
            break;
        default:
            usage(argv[0]);
            break;
    }


    return 0;
}
