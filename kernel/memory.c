#include "memory.h"
#include "lib.h"
void init_memory(){
    int i;
    int j;
    unsigned long Total_Mem = 0;
    struct E820 *p = NULL;
    color_printk(BLUE,BLACK, "Display Address MAP,Type(1:RAM,2:ROM or Reserved,3:ACPI Reclaim Memory,4:ACPI NVS Memory,Others:Undefined)\n");
    p = (struct E820*)0xffff800000007e00;
    for(i = 0; i < 32; i++){
        color_printk(ORANGE,BLACK,"Address:%#18lx\tLength:%#18lx\tType:%#10x\n",p->address,p->length,p->type);
        unsigned long tmp = 0;
        if(p->type == 1){
            Total_Mem += p->length;
        }
        mem_manager_struct.e820[i].address += p -> address;
        mem_manager_struct.e820[i].length += p -> length;
        mem_manager_struct.e820[i].type = p -> type;
        mem_manager_struct.e820_length = i;
        p++;
        if(p->type > 4){
            break;
        }
    }
    color_printk(ORANGE,BLACK,"OS can use total RAM:%#18lx\n",Total_Mem);
    Total_Mem = 0;
    for(i = 0; i < mem_manager_struct.e820_length; i++){
        unsigned long start, end;
        if(mem_manager_struct.e820[i].type != 1){
            continue;
        }
        start = PAGE_2M_ALIGN(mem_manager_struct.e820[i].address);
        end = ((mem_manager_struct.e820[i].address + mem_manager_struct.e820[i].length)
            >> PAGE_2M_SHIFT) << PAGE_2M_SHIFT;
        if(end <= start){
            continue;
        }
        Total_Mem += (end - start) >> PAGE_2M_SHIFT;
    }
    color_printk(ORANGE,BLACK, "OS Can Used Total 2M Pages:%#10x=%10d\n",Total_Mem,Total_Mem);
}