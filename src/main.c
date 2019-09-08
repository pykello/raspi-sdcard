
#include "common.h"


uint8_t buf[512];

void c_entry(void)
{
	int i;
	struct emmc_block_dev dev;
	struct block_device *devptr = (struct block_device *) &dev;
	uart0_init();

	sd_card_init(&devptr);
	uart0_printf("read %d bytes\n", sd_read(devptr, buf, 512, 0));
	uart0_printf("BYTES: ");
	for (int i = 0; i < 512; i++)
		uart0_printf("%x ", buf[i]);
	uart0_printf("\n");

	uart0_print("Bye!\r\n");
}
