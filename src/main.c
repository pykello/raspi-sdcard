
#include "common.h"


uint8_t buf[512];

void c_entry(void)
{
	int i;
	struct emmc_block_dev dev;
	struct block_device *devptr = (struct block_device *) &dev;
	wdog_start(0xFFFFF);
	uart0_init();

	sd_card_init(&devptr);
	uart0_printf("read %d bytes\n", sd_read(devptr, buf, 512, 0));
	uart0_printf("BYTES: ");
	for (int i = 0; i < 512; i++)
		uart0_printf("%x ", buf[i]);
	uart0_printf("\n");

	uart0_print("Bye!\r\n");
	while(1)
	{
		unsigned int ra=wdog_get_remaining();
		uart0_printf("ra: %d\n", ra);
		if(ra<0xC2F6F) //4 seconds
		{
			uart0_printf("Wait for a reset\n");
			break;
		}
	}
}
