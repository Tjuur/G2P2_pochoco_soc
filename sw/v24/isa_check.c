/* Functional interpreter for the actual RV32E machine code, not cycle-accurate RTL.
   Rejects unsupported instructions, accesses outside mapped regions, extra registers. */
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
static uint32_t regs[16],ram[256],rom[1024],pc; static int ready,price,code,booted;
static int insns,cycles,loads,jumps;
static int32_t sx(uint32_t x,unsigned n){return (int32_t)(x<<(32-n))>>(32-n);}
static void fail(const char *msg,uint32_t i){fprintf(stderr,"ISA error %s pc=%08x insn=%08x\n",msg,pc,i);abort();}
void loadrom(const uint32_t *r,int n){memset(rom,0,sizeof rom);memcpy(rom,r,n*4);}
void restart(void){memset(regs,0,sizeof regs);memset(ram,0xa5,sizeof ram);pc=0;ready=0;price=0;code=0;booted=0;}
static int run(void){
 insns=cycles=loads=jumps=0;
 for(int n=0;n<10000;n++){
  if(pc>=4096 || pc%4)fail("pc",pc);uint32_t i=rom[pc/4],next=pc+4,op=i&127,rd=(i>>7)&31,f=(i>>12)&7,a=(i>>15)&31,b=(i>>20)&31;
  uint32_t x=0,y=0,v=0,addr;int wr=0,taken=0,emit=0;
  if(op==0x13||op==0x33||op==3||op==0x23||op==0x63||op==0x67){if(a>=16)fail("rs1",i);x=regs[a];}
  if(op==0x33||op==0x23||op==0x63){if(b>=16)fail("rs2",i);y=regs[b];}
  if(op==0x13)y=sx(i>>20,12);
  insns++;cycles+=2;
  switch(op){
  case 0x37:v=i&0xfffff000;wr=1;break;
  case 0x13:case 0x33:
    wr=1;switch(f){case 0:v=(op==0x33 && (i>>25)==32)?x-y:x+y;break;case 2:v=(int32_t)x<(int32_t)y;break;case 3:v=x<y;break;case 4:v=x^y;break;case 6:v=x|y;break;case 7:v=x&y;break;default:fail("unsupported ALU",i);}break;
  case 3:
    if(f!=2)fail("not LW",i);addr=x+sx(i>>20,12);wr=1;loads++;cycles++;
    if(addr>=0x10000000 && addr<0x10000400 && !(addr&3))v=ram[(addr-0x10000000)/4];
    else if(addr==0x80010000)v=ready;
    else if(addr==0x80010004){if(!ready)fail("read without price",i);v=price;ready=0;}
    else fail("load address",i);break;
  case 0x23:
    if(f!=2)fail("not SW",i);addr=x+sx(((i>>25)<<5)|((i>>7)&31),12);
    if(addr>=0x10000000 && addr<0x10000400 && !(addr&3))ram[(addr-0x10000000)/4]=y;
    else if(addr==0x80010008){if(ready)fail("unread price",i);code=y;emit=1;}
    else fail("store address",i);break;
  case 0x63:
    switch(f){case 0:taken=x==y;break;case 1:taken=x!=y;break;case 4:taken=(int32_t)x<(int32_t)y;break;case 5:taken=(int32_t)x>=(int32_t)y;break;case 6:taken=x<y;break;case 7:taken=x>=y;break;default:fail("branch",i);}
    if(taken)next=pc+sx(((i>>31)<<12)|(((i>>7)&1)<<11)|(((i>>25)&63)<<5)|(((i>>8)&15)<<1),13);break;
  case 0x6f:wr=1;v=pc+4;taken=1;next=pc+sx(((i>>31)<<20)|(((i>>12)&255)<<12)|(((i>>20)&1)<<11)|(((i>>21)&1023)<<1),21);break;
  case 0x67:wr=1;v=pc+4;taken=1;next=(x+sx(i>>20,12))&~1u;break;
  default:fail("opcode",i);
  }
  if(wr){if(rd>=16)fail("rd",i);if(rd)regs[rd]=v;}if(taken){cycles++;jumps++;}pc=next;
  if(emit)return code;
 }
 fail("instruction limit",0);return -1;
}
int boot(void){int v=run();booted=1;return v;}
int tick(int p,int *out){if(!booted||ready)fail("not ready",0);price=p;ready=1;int v=run();out[0]=ram[106];out[1]=ram[107];out[2]=insns;out[3]=cycles;out[4]=loads;out[5]=jumps;return v;}
