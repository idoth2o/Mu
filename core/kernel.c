/*
 *	@brief Multi platform Unified OS: Mu OS <br>
 *	Arch:x86/x64(LP64)
 *	License: GPL2 or Proprietary(TBD)
 *	@author .h2o

*/
#include <stdint.h>
#include <x86_x64.h>

char * uint_to_str(char *buf, uint32_t src, uint32_t base) {
  char *p = buf;
  char *p1, *p2;

  do {
    *p++ = "0123456789ABCDEF"[src%base];
  } while(src /= base);

  // Terminate BUF
  *p = 0;

  // Reverse BUF
  for(p1=buf, p2=p-1; p1 < p2; p1++, p2--) {
    char tmp = *p1;
    *p1 = *p2;
    *p2 = tmp;
  }

  return buf;
}

void putc(char *str){
	unsigned short *vram	     = (unsigned short *)(unsigned short *)(0xb8000 + KERNEL_VMA_BASE);
	for(;*str != '\0';str++,vram++)
		*vram = ((0x0f)<<8) | *str;
}

void main(uint32_t magic, uint32_t addr){
	/*
	char str[32];
	char *p;
	p = uint_to_str(str,addr, 16);
	*/
	putc("hello world");
	
	while(1){
		asm volatile ( "hlt" );
	}
}