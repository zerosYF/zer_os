#ifndef __MEMORY_H__
#define __MEMORY_H__

#include "lib.h"
#include "printK.h"

#define PTRS_PER_PAGE 512 //4KB/8B
#define PAGE_OFFSET ((unsigned long)0xffff800000000000)
#define PAGE_GDT_SHIFT 39
#define PAGE_1G_SHIFT 30
#define PAGE_2M_SHIFT 21
#define PAGE_4K_SHIFT 12
#define PAGE_2M_SIZE (1UL << PAGE_2M_SHIFT)
#define PAGE_4K_SIZE (1UL << PAGE_4K_SHIFT)
#define PAGE_2M_MASK (~(PAGE_2M_SIZE - 1))
#define PAGE_4K_MASK (~(PAGE_4K_SIZE - 1))
#define PAGE_2M_ALIGN(addr) (((unsigned long)(addr) + PAGE_2M_SIZE - 1) & PAGE_2M_MASK)
#define PAGE_4K_ALIGN(addr) (((unsigned long)(addr) + PAGE_4K_SIZE - 1) & PAGE_4K_MASK)
#define Virt_To_Phy(addr) ((unsigned long)(addr) - PAGE_OFFSET)
#define Phy_To_Virt(addr) ((unsigned long*)(unsigned long)(addr) + PAGE_OFFSET)

#define Virt_To_2M_Page(kaddr)	(memory_management_struct.pages_struct + (Virt_To_Phy(kaddr) >> PAGE_2M_SHIFT))
#define Phy_to_2M_Page(kaddr)	(memory_management_struct.pages_struct + ((unsigned long)(kaddr) >> PAGE_2M_SHIFT))

////page table attribute

//	bit 63	Execution Disable:
#define PAGE_XD		(unsigned long)0x1000000000000000

//	bit 12	Page Attribute Table
#define	PAGE_PAT	(unsigned long)0x1000

//	bit 8	Global Page:1,global;0,part
#define	PAGE_Global	(unsigned long)0x0100

//	bit 7	Page Size:1,big page;0,small page;
#define	PAGE_PS		(unsigned long)0x0080

//	bit 6	Dirty:1,dirty;0,clean;
#define	PAGE_Dirty	(unsigned long)0x0040

//	bit 5	Accessed:1,visited;0,unvisited;
#define	PAGE_Accessed	(unsigned long)0x0020

//	bit 4	Page Level Cache Disable
#define PAGE_PCD	(unsigned long)0x0010

//	bit 3	Page Level Write Through
#define PAGE_PWT	(unsigned long)0x0008

//	bit 2	User Supervisor:1,user and supervisor;0,supervisor;
#define	PAGE_U_S	(unsigned long)0x0004

//	bit 1	Read Write:1,read and write;0,read;
#define	PAGE_R_W	(unsigned long)0x0002

//	bit 0	Present:1,present;0,no present;
#define	PAGE_Present	(unsigned long)0x0001

//1,0
#define PAGE_KERNEL_GDT		(PAGE_R_W | PAGE_Present)

//1,0	
#define PAGE_KERNEL_Dir		(PAGE_R_W | PAGE_Present)

//7,1,0
#define	PAGE_KERNEL_Page	(PAGE_PS  | PAGE_R_W | PAGE_Present)

//2,1,0
#define PAGE_USER_Dir		(PAGE_U_S | PAGE_R_W | PAGE_Present)

//7,2,1,0
#define	PAGE_USER_Page		(PAGE_PS  | PAGE_U_S | PAGE_R_W | PAGE_Present)


typedef struct {unsigned long pml4t;} pml4t_t;
#define	mk_mpl4t(addr,attr)	((unsigned long)(addr) | (unsigned long)(attr))
#define set_mpl4t(mpl4tptr,mpl4tval)	(*(mpl4tptr) = (mpl4tval))


typedef struct {unsigned long pdpt;} pdpt_t;
#define mk_pdpt(addr,attr)	((unsigned long)(addr) | (unsigned long)(attr))
#define set_pdpt(pdptptr,pdptval)	(*(pdptptr) = (pdptval))


typedef struct {unsigned long pdt;} pdt_t;
#define mk_pdt(addr,attr)	((unsigned long)(addr) | (unsigned long)(attr))
#define set_pdt(pdtptr,pdtval)		(*(pdtptr) = (pdtval))


typedef struct {unsigned long pt;} pt_t;
#define mk_pt(addr,attr)	((unsigned long)(addr) | (unsigned long)(attr))
#define set_pt(ptptr,ptval)		(*(ptptr) = (ptval))


struct E820
{
    unsigned long address;
    unsigned long length;
    unsigned int type;
}__attribute__((packed));

struct Global_Memory_Descriptor{
    struct E820 e820[32];
    unsigned long e820_length;
};
extern struct Global_Memory_Descriptor mem_manager_struct;

struct Page{
    struct Zone* zone_struct;
    unsigned long PHY_addr;
    unsigned long attribute;
    unsigned long reference_count;
    unsigned long age;
};

struct Zone{
    struct Page* pages_group;
    unsigned long pages_length;
    unsigned long zone_start_addr;
    unsigned long zone_end_addr;
    unsigned long zone_length;
    unsigned long attribute;
    struct Global_Memory_Descriptor* GMD_struct;
    unsigned long page_using_cnt;
    unsigned long page_free_cnt;
    unsigned long total_pages_link;
};


void init_memory();
#endif