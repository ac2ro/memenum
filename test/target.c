#include<stdio.h>

void main () {
char* name = "HelpImTest!!";
int health = 1337;
printf("name address : 0x%p" , name);
printf("health add : 0x%p" , &health);
getchar();
}