#include "regs.h"
//#include <regdef.h>
//#include <asm/mipsregs.h>  

#include "start.h"      
#ifndef boot32        
#define NEWSTACK        (0x80670000)
#else
#define NEWSTACK        (0x809FFF00)
#endif
	.globl old_stack_pointer
        
	.extern __start_dram
 
        .text
        .globl __start              
__start:
		 
	nop
	move s0, zero
	mtc0 s0, $12
	nop
	nop
        nop
	la s0, _bstart
        la s1, _bend

        move t0, s0

1:
        sw zero, 0(t0)
        addi t0, 4
        bne t0, s1, 1b

	move t0, s1
	addi t0, t0, 4096
 	move sp, t0
 	move a0, t0
                
        j main
        nop

        .globl exit                
exit:
        j exit
        nop

        .globl start_kernel
start_kernel:
        move t0, a0
        li a0, 0
        li a1, 0
        li a2, 0
		jr t0
       	nop 


hfclock_setting:
		// Check chip version to set divider register
	li		t1, REG_REVISION
	lw		t0, 0(t1)
	li		t1, 0xf0000000
		and		t0, t0, t1
		srl		t0, t0, 0x1c		// Right shift 28 bits
		
		beq		t0, VERSION_D, version_8186_C //set D cut keep 108MHz
		nop
		
//		bne		t0, VERSION_D, 1f
//		nop
//		j		ra			// 8186 D cut doesn't need watch dog reset.
//		nop

1:
		beq		t0, VERSION_C, version_8186_C
		nop


version_8186_B:
		// Check PLLMNR and SYSCLKR Registers.
		la   	a0, REG_PLLMNR
		lw		t0, 0(a0)
		and		t0, t0, 0x3FFFF	//You must mask other bits!!
		li   	t1, VAL_PLLMNR_8186B
		bne		t0, t1, set_B
		nop

		la   	a0, REG_SYSCLKR
		lw		t0, 0(a0)
		and		t0, t0, 0xFFF		//You must mask other bits!!
		li   	t1, VAL_SYSCLKR_8186B
		bne		t0, t1, set_B
		nop

		j		ra			//PLLMNR and SYSCLKR are set already.
		nop

set_B:
		// Set CPU/MEM Clock and Watch Dog Reset.
		li		t0, VAL_PLLMNR_8186B
		la		a0, REG_PLLMNR
		sw		t0, 0(a0)

		li		t0, VAL_SYSCLKR_8186B
		la		a0, REG_SYSCLKR
		sw		t0, 0(a0)
		
		j		start_watch_dog
		nop

version_8186_C:
		// Check PLLMNR and SYSCLKR Registers.
		la   	a0, REG_PLLMNR
		lw		t0, 0(a0)
		and		t0, t0, 0x3FFFF		//You must mask other bits!!
		li   	t1, VAL_PLLMNR_8186C
		bne		t0, t1, set_C
		nop

		la   	a0, REG_SYSCLKR
		lw		t0, 0(a0)
		and		t0, t0, 0xFFF			//You must mask other bits!!
		li   	t1, VAL_SYSCLKR_8186C
		bne		t0, t1, set_C
		nop

		j		ra
		nop

set_C:
		// Set CPU/MEM Clock and Watch Dog Reset.
		li		t0, VAL_PLLMNR_8186C
		la		a0, REG_PLLMNR
		sw		t0, 0(a0)

		li		t0, VAL_SYSCLKR_8186C
		la		a0, REG_SYSCLKR
		sw		t0, 0(a0)
		
		j		start_watch_dog
		nop

start_watch_dog:
		// start WDTDOG
		la		a0, REG_CDBR
		la		t0, 0x2
		sw		t0, 0(a0)
		la		t0, 0x100
		la		a0, REG_WDTCNR
		sw		t0, 0(a0)
1:
		b		1b
		nop


