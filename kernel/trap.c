#include"gate.h"
#include"printK.h"
#include"trap.h"
#include<stddef.h>
void do_divide_error(unsigned long rsp,unsigned long err_code){
    unsigned long* p = NULL;
    p = (unsigned long*)(rsp + 0x98);
	color_printk(RED,BLACK,"divide_error(0)!\n");
	while(1);
}
void do_debug(unsigned long rsp,unsigned long error_code)
{
	unsigned long * p = NULL;
	p = (unsigned long *)(rsp + 0x98);
	color_printk(RED,BLACK,"do_debug(1)\n");
	while(1);
}
void do_nmi(unsigned long rsp,unsigned long err_code){
    unsigned long* p = NULL;
    p = (unsigned long*)(rsp + 0x98);
    color_printk(RED,BLACK,"nmi_error(2)!\n");
    while(1);
}
void do_int3(unsigned long rsp,unsigned long error_code)
{
	unsigned long * p = NULL;
	p = (unsigned long *)(rsp + 0x98);
	color_printk(RED,BLACK,"do_int3(3)\n");
	while(1);
}
void do_overflow(unsigned long rsp,unsigned long error_code)
{
	unsigned long * p = NULL;
	p = (unsigned long *)(rsp + 0x98);
	color_printk(RED,BLACK,"do_overflow(4)\n");
	while(1);
}
void do_bounds(unsigned long rsp,unsigned long error_code)
{
	unsigned long * p = NULL;
	p = (unsigned long *)(rsp + 0x98);
	color_printk(RED,BLACK,"do_bounds(5)\n");
	while(1);
}
void do_undefined_opcode(unsigned long rsp,unsigned long error_code)
{
	unsigned long * p = NULL;
	p = (unsigned long *)(rsp + 0x98);
	color_printk(RED,BLACK,"do_undefined_opcode(6)\n");
	while(1);
}
void do_dev_not_available(unsigned long rsp,unsigned long error_code)
{
	unsigned long * p = NULL;
	p = (unsigned long *)(rsp + 0x98);
	color_printk(RED,BLACK,"do_dev_not_available(7)\n");
	while(1);
}
void do_double_fault(unsigned long rsp,unsigned long error_code)
{
	unsigned long * p = NULL;
	p = (unsigned long *)(rsp + 0x98);
	color_printk(RED,BLACK,"do_double_fault(8)\n");
	while(1);
}
void do_coprocessor_segment_overrun(unsigned long rsp,unsigned long error_code)
{
	unsigned long * p = NULL;
	p = (unsigned long *)(rsp + 0x98);
	color_printk(RED,BLACK,"do_coprocessor_segment_overrun(9)\n");
	while(1);
}
void do_invalid_TSS(unsigned long rsp, unsigned long err_code){
	unsigned long* p = NULL;
	p = (unsigned long*)(rsp + 0x98);
	color_printk(RED,BLACK,"do_invalid_tss(10)!\n");
	//color_printk(RED,BLACK,"Segment Selector iNDEX:%#010x\n",err_code & 0xfff8);
	while(1);
}
void do_segment_not_present(unsigned long rsp,unsigned long error_code)
{
	unsigned long * p = NULL;
	p = (unsigned long *)(rsp + 0x98);
	color_printk(RED,BLACK,"do_segment_not_present(11)\n");
	//color_printk(RED,BLACK,"Segment Selector Index:%#010x\n",error_code & 0xfff8);
	while(1);
}
void do_stack_segment_fault(unsigned long rsp,unsigned long error_code)
{
	unsigned long * p = NULL;
	p = (unsigned long *)(rsp + 0x98);
	color_printk(RED,BLACK,"do_stack_segment_fault(12)\n");
	//color_printk(RED,BLACK,"Segment Selector Index:%#010x\n",error_code & 0xfff8);
	while(1);
}
void do_general_protection(unsigned long rsp,unsigned long error_code)
{
	unsigned long * p = NULL;
	p = (unsigned long *)(rsp + 0x98);
	color_printk(RED,BLACK,"do_general_protection(13)\n");
	//color_printk(RED,BLACK,"Segment Selector Index:%#010x\n",error_code & 0xfff8);
	while(1);
}

void do_page_fault(unsigned long rsp, unsigned long err_code){
	unsigned long* p = NULL;
	unsigned long cr2 = 0;
	__asm__ __volatile__("movq %%cr2, %0":"=r"(cr2)::"memory");
	p = (unsigned long*)(rsp + 0x98);
	color_printk(RED,BLACK,"do_page_fault(14)!\n");
	while(1);
}
void do_x87_FPU_error(unsigned long rsp,unsigned long error_code)
{
	unsigned long * p = NULL;
	p = (unsigned long *)(rsp + 0x98);
	color_printk(RED,BLACK,"do_x87_FPU_error(16)\n");
	while(1);
}
void do_alignment_check(unsigned long rsp,unsigned long error_code)
{
	unsigned long * p = NULL;
	p = (unsigned long *)(rsp + 0x98);
	color_printk(RED,BLACK,"do_alignment_check(17)\n");
	while(1);
}
void do_machine_check(unsigned long rsp,unsigned long error_code)
{
	unsigned long * p = NULL;
	p = (unsigned long *)(rsp + 0x98);
	color_printk(RED,BLACK,"do_machine_check(18)\n");
	while(1);
}
void do_SIMD_exception(unsigned long rsp,unsigned long error_code)
{
	unsigned long * p = NULL;
	p = (unsigned long *)(rsp + 0x98);
	color_printk(RED,BLACK,"do_SIMD_exception(19)\n");
	while(1);
}
void do_virtualization_exception(unsigned long rsp,unsigned long error_code)
{
	unsigned long * p = NULL;
	p = (unsigned long *)(rsp + 0x98);
	color_printk(RED,BLACK,"do_virtualization_exception(20)\n");
	while(1);
}
void sys_vector_init(){
    set_trap_gate(0,1,divide_error);
	set_trap_gate(1,1,debug);
	set_intr_gate(2,1,nmi);
	set_system_gate(3,1,int3);
	set_system_gate(4,1,overflow);
	set_system_gate(5,1,bounds);
	set_trap_gate(6,1,undefined_opcode);
	set_trap_gate(7,1,dev_not_available);
	set_trap_gate(8,1,double_fault);
	set_trap_gate(9,1,coprocessor_segment_overrun);
	set_trap_gate(10,1,invalid_TSS);
	set_trap_gate(11,1,segment_not_present);
	set_trap_gate(12,1,stack_segment_fault);
	set_trap_gate(13,1,general_protection);
	set_trap_gate(14,1,page_fault);
	//15 Intel reserved. Do not use.
	set_trap_gate(16,1,x87_FPU_error);
	set_trap_gate(17,1,alignment_check);
	set_trap_gate(18,1,machine_check);
	set_trap_gate(19,1,SIMD_exception);
	set_trap_gate(20,1,virtualization_exception);
}