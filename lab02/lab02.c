#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

char* removewhitespace(char *s1)
{
  char *endptr = s1;
  char *start = &s1[0];

  while(*endptr)
  {
    if (isspace(*endptr))
    {
	    endptr++;
    }
    else
    {
	    *s1++ = *endptr++;
    }
  }
  *s1 = '\0';
  return start;
}

char* c2pascal(char *s1)
{
  int i=0;
  int len=strlen(s1);
  if (len > 255)
  {
    return NULL;
  }

  for(i=len;i>=1;--i)
  {	  
    *(s1+i) = *(s1 + i-1);
  }

  *(s1+0) = len;

  return s1;
    
}

char* pascal2c(char *s1)
{
  int i=0;
  int len= *(s1+0); 

  for(i=0;i<len;++i)
  {
    *(s1+i) = *(s1 + i+1);
  }

  *(s1 + len) = '\0'; 

  return s1;

}

char** tokenify(char *s)
{
  char **result = (char**) malloc( strlen(s)*sizeof(char) );
  char *tok = NULL;
  tok = strtok( s, " ");
  int i = 0;
  while (tok != NULL)
  {
    *(result + i) = tok;
    i += 1; 
    tok = strtok(NULL, " ");
  }
  *(result + i) = '\0';

  return result;

}


