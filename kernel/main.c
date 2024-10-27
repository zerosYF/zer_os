#include"printK.h"
#include"lib.h"
#include"gate.h"
#include"trap.h"
#include"memory.h"
struct Global_Memory_Descriptor mem_manager_struct = {{0}, 0};
void print_test(){
    unsigned int *addr = (unsigned int *)0xffff800000a00000;
    int i;

    for (i = 0; i < 1440 * 20; i++) {
        *(addr++) = BLUE; // ARGB
    }
    for (i = 0; i < 1440 * 20; i++) {
        *(addr++) = GREEN; // ARGB
    }
    for (i = 0; i < 1440 * 20; i++) {
        *(addr++) = RED; // ARGB
    }
    for (i = 0; i < 1440 * 20; i++) {
        *(addr++) = WHITE; // ARGB
    }
}
void Start_Kernel(void){
    //print_test();
    Pos.XResolution = 1440;
    Pos.YResolution = 900;

    Pos.XPosition = 0;
    Pos.YPosition = 0;

    Pos.XCharSize = 8;
    Pos.YCharSize = 16;

    Pos.FB_addr = (unsigned int *)0xffff800000a00000;
    Pos.FB_Length = (Pos.XResolution * Pos.YResolution * 4);

    load_TR(8);

	set_tss64(0xffff800000007c00, 
        0xffff800000007c00, 0xffff800000007c00, 
        0xffff800000007c00, 0xffff800000007c00, 
        0xffff800000007c00, 0xffff800000007c00, 
        0xffff800000007c00, 0xffff800000007c00, 
        0xffff800000007c00);

	sys_vector_init();
    color_printk(YELLOW, BLACK, "Hello World!\n");
    color_printk(RED,BLACK,"memory init\n");
    init_memory();
    while(1);
}