#pragma once

#define STACK_SIZE		0x4000

#ifdef __x86__
#define KERNEL_LMA_BASE		0x00100000
#define KERNEL_VMA_BASE		0x00000000
#else
#define KERNEL_LMA_BASE		0x0000000000100000
#define KERNEL_VMA_BASE		0xFFFFFFFF80000000
#endif

#define GDT_SEG_64				0xA0
#define GDT_SEG_32				0xC0
#define GDT_KERNEL				0x90
#define GDT_USER				0xf0
#define GDT_DS					0x3
#define GDT_CS					0xb

#define GDT_ENTRY_SET(arch, mode, type, base, limit)\
    .word   (((limit) >> 12) & 0xFFFF);             \
    .word   ((base) & 0xFFFF);                      \
    .byte   (((base) >> 16) & 0xFF);                \
    .byte   (mode | (type));                        \
    .byte   ((arch) | (((limit) >> 28) & 0xF));     \
    .byte   (((base) >> 24) & 0xFF)

/*
 : 0x08 = 00001,0,00 = index 1  TI=0(0:GDT 1:LDT) RPL= 0
 : 0x10 = 00010,0,00 = index 2
 : 0x18 = 00011,0,00 = index 3
 : 0x20 = 00100,0,00 = index 4
 :
 */
#define GDT_KC32	0x08
#define GDT_KD32	0x10
#define GDT_UC32	0x18
#define GDT_UD32	0x20

#define GDT_KC64	0x28
#define GDT_KD64	0x30
#define GDT_UC64	0x38
#define GDT_UD64	0x40


/*
 *  Paging
*/
#define PAGE_SIZE   				4096

#define PAGE_PRESENT            (1 << 0)
#define PAGE_WRITABLE           (1 << 1)
#define PAGE_USER               (1 << 2)
#define PAGE_WRITETHROUGH       (1 << 3)
#define PAGE_NONCACHABLE        (1 << 4)
#define PAGE_ACCESSED           (1 << 5)
#define PAGE_DIRTY              (1 << 6)
#define PAGE_2MB                (1 << 7)
#define PAGE_GLOBAL             (1 << 8)
#define PAGE_EXECUTE_DISABLE    (1 << 63)

#define PT_(vaddr)     (((vaddr) >> (12)      ) & 0x1FF)
#define PD_(vaddr)     (((vaddr) >> (21)    ) & 0x1FF)
#define PDPT_(vaddr)   (((vaddr) >> (21+9)  ) & 0x1FF)
#define PML4_(vaddr)   (((vaddr) >> (21+9+9)) & 0x1FF)

#define EFER       0xC0000080
/*
 * Define CRx Register
*/

#define CR0_PAGING              (1 << 31)
#define CR4_PSE                 (1 << 4)
#define CR4_PAE                 (1 << 5)