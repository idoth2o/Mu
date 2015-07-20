#define  SHARE_BOOT
#include <multiboot.h>
#include <x86_x64.h>

#data section for boot
.section .boot_data, "aw", @progbits
.global	stack
stack:
	.space	STACK_SIZE

.p2align 3
pre_gdt:
	.quad	0x0	// GDT_NULL ENTRY
	GDT_ENTRY_SET( GDT_SEG_32,	GDT_KERNEL, GDT_CS, 0x0,  0xFFFFFFFF)
	GDT_ENTRY_SET( GDT_SEG_32,	GDT_KERNEL, GDT_DS, 0x0,  0xFFFFFFFF)
	GDT_ENTRY_SET( GDT_SEG_32,	  GDT_USER, GDT_CS, 0x0,  0xFFFFFFFF)
	GDT_ENTRY_SET( GDT_SEG_32,	  GDT_USER, GDT_DS, 0x0,  0xFFFFFFFF)
#ifdef __x86_64__
	GDT_ENTRY_SET( GDT_SEG_64,	GDT_KERNEL, GDT_CS, 0x0,  0xFFFFFFFF)
	GDT_ENTRY_SET( GDT_SEG_64,	GDT_KERNEL, GDT_DS, 0x0,  0xFFFFFFFF)
	GDT_ENTRY_SET( GDT_SEG_64,	  GDT_USER, GDT_CS, 0x0,  0xFFFFFFFF)
	GDT_ENTRY_SET( GDT_SEG_64,	  GDT_USER, GDT_DS, 0x0,  0xFFFFFFFF)
#endif
pre_gdt_end:

pre_gdt_p:
	.word	pre_gdt_end - pre_gdt + 1
#ifdef __x86__
	.long	pre_gdt
#else
	.quad	pre_gdt
#endif


.p2align 12
pre_pml4:
    .zero   PAGE_SIZE
.p2align 12
pre_pdpt_low:
    .zero   PAGE_SIZE
.p2align 12
pre_pdpt_high:
    .zero   PAGE_SIZE
.p2align 12
pre_pd:
    .zero   PAGE_SIZE
    
# multiboot header
mb_magic:	.long	0xff
mb_addr:	.long	0xff

#text section for boot
.section .boot_text, "ax"
.code32
.global start
.extern  main

start:
	jmp entry
	.align 4
	# multiboot header
	.long MULTIBOOT_HEADER_MAGIC
	.long MULTIBOOT_HEADER_FLAGS
	.long MULTIBOOT_HEADER_CHECKSUM

entry:
	pushl $0x0
	popf
	
	# Setup Stack
	movl	$(stack+STACK_SIZE),	%esp
	
	# save multiboot info
	movl	%eax,	mb_magic
	movl	%ebx,	mb_addr
		
	# Enable A20 line via System Port A
	in		$0x92,				%al				#load System Control Port A(0x92)
	cmpb	$0xff,				%al				#retun 0xff? -> no A20
	jz		no92
	or		$2,					%al				#mask for A20 line enable
	and		$0xFE,				%al				#clear the INIT_NOW bit  -> don't accidently reset the machine
	out		%al,				$0x92
no92:
		
	# Setup pre-GDT
	lgdt	pre_gdt_p

	# Set Segment Register
	ljmp	$GDT_KC32,$gdt_flush
gdt_flush:
	#setup data segment selectors
	mov		$GDT_KD32,			%eax
   	mov 	%ax, 				%ds
   	mov 	%ax, 				%es
   	mov 	%ax, 				%ss
	xorl	%eax,				%eax
   	mov 	%ax, 				%fs
   	mov 	%ax, 				%gs

#ifdef __x86__
	#load multiboot info
	movl	mb_magic,	%eax	
	movl	mb_addr,	%ebx
	push	%ebx
	push	%eax
	
#else
		#
		# - Setup Paging
		#

#define ENTRY_SIZE 0x8

		movl	$(pre_pdpt_low), 	%eax
		orl		$PAGE_PRESENT, 	%eax
		movl	%eax, 				pre_pml4

		movl	$(pre_pdpt_high),	%eax
		orl		$PAGE_PRESENT, 	%eax
		movl	%eax, 				pre_pml4 + (ENTRY_SIZE * PML4_(KERNEL_VMA_BASE))

		movl	$pre_pd, 			%eax
		orl		$PAGE_PRESENT, 	%eax
		movl	%eax, 				pre_pdpt_low
		movl	%eax, 				pre_pdpt_high + (ENTRY_SIZE * PDPT_(KERNEL_VMA_BASE))

		xorl	%eax,				%eax    # physical_address 0x0 ...
		orl		$PAGE_2MB,			%eax
		orl		$PAGE_WRITABLE,	%eax
		orl		$PAGE_PRESENT,	%eax
		movl	%eax, 				pre_pd
		movl	%eax, 				pre_pd + (ENTRY_SIZE * PD_(KERNEL_VMA_BASE))

		# Setup long mode page table
		movl $(pre_pml4), 		%eax
    	movl %eax, 				%cr3


		#enable PAE
		movl	%cr4,				%eax			# read Control register 4
		orl		$CR4_PAE,			%eax			# enable PAE
		orl		$CR4_PSE,			%eax			# enable PSE
		movl	%eax,				%cr4			# re-write

		#enable long mode
		movl	$EFER,				%ecx
		rdmsr										# read msr
		bts		$8,					%eax			# LME bit = 1
		wrmsr										# write msr 

		#enable Paging
		movl    %cr0, 			%eax
		orl     $CR0_PAGING, 	%eax
		movl    %eax, 			%cr0

		ljmp	$GDT_KC64,		$.entry_long

.code64
.entry_long:
		# Setup Stack (Higher)
		movq	$(KERNEL_VMA_BASE),	%rax
		addq	%rax,				%rsp

		#setup data segment selectors
		mov		$GDT_KD64,			%eax
    	mov 	%ax, 				%ds
    	mov 	%ax, 				%es
    	mov 	%ax, 				%ss

		# Setup args 1st: %rdi 2nd:%rsi	
		movq	mb_magic,	%rdi
		movq	mb_addr,	%rsi
		
#endif
		call	main	
#GUARD
end:
		hlt
		jmp end		
