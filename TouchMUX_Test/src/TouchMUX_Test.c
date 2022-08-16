/* TouchMUX_Test.c for TOPPERS/ATK(OSEK) */



#include "kernel.h"
#include "kernel_id.h"
#include "ecrobot_interface.h"

#define TMUX NXT_PORT_S3


DeclareTask(TASK_BACKGROUND);
U32 num_characters_signed(S32 n);
U32 num_characters_unsigned(U32 n);
void data_to_hex_str(char* str, U8* data, U32 num_bytes);
void display_labeled_unsigned(const char* label, U32 value, int linenum);	//linenum from 0 to 7


void user_1ms_isr_type2(void){}

void ecrobot_device_initialize()
{
	ecrobot_init_i2c(TMUX, LOWSPEED);
	ecrobot_send_i2c(TMUX, 0x20, 0xFF, 0, 0);
}

void ecrobot_device_terminate()
{
	ecrobot_term_i2c(TMUX);
}


//Start, h41 [ h20 | RD ], hFF, hFF, hFF, hFF, hFF NAK,
//Restart, h40 [ h20 | WR ], hFF, Stop

TASK(OSEK_Task_Background)
{
	while(1)
	{
		static U8 rx[2] = {0};


		if(ecrobot_is_ENTER_button_pressed())
		{
			while(ecrobot_is_ENTER_button_pressed()) {};
			ecrobot_sound_tone(1000, 20, 50);
			i2c_start_transaction(TMUX, 0x20, 0, 0, rx, 1, 0);
		}


		display_clear(0);

		char tmux_str1[] = "TMUX: 0x  ";
		data_to_hex_str(&tmux_str1[8], &rx[0], 1);
		display_goto_xy(0, 0);	display_string(tmux_str1);
		display_goto_xy(12, 0);	display_unsigned(rx[0],3);

		display_labeled_unsigned("systick:", systick_get_ms(),	7);

		display_update();

		systick_wait_ms(20);
	}
}



void display_labeled_unsigned(const char* label, U32 value, int linenum)	//linenum from 0 to 7
{
	U32 places = num_characters_unsigned(value);
	display_goto_xy(0, linenum);
	display_string(label);
	display_goto_xy(16-places, linenum);
	display_unsigned(value, places);
}

U32 num_characters_signed(S32 n)
{
	U32 neg = 0;
    if (n < 0)
    {
    	neg = 1;	//add 1 character for the negative sign
    	n = (n == -2147483648) ? 2147483647 : -n;	//flip negative n to positive n
    }
    if (n < 10) return 1+neg;
    if (n < 100) return 2+neg;
    if (n < 1000) return 3+neg;
    if (n < 10000) return 4+neg;
    if (n < 100000) return 5+neg;
    if (n < 1000000) return 6+neg;
    if (n < 10000000) return 7+neg;
    if (n < 100000000) return 8+neg;
    if (n < 1000000000) return 9+neg;
    return 10;
}

U32 num_characters_unsigned(U32 n)
{
    if (n < 10) return 1;
    if (n < 100) return 2;
    if (n < 1000) return 3;
    if (n < 10000) return 4;
    if (n < 100000) return 5;
    if (n < 1000000) return 6;
    if (n < 10000000) return 7;
    if (n < 100000000) return 8;
    if (n < 1000000000) return 9;
    return 10;
}

void data_to_hex_str(char* str, U8* data, U32 num_bytes)
{
	U8 nib;
	U32 num_chars = num_bytes<<1;	//multiply by 2; there are 2 hex characters per byte

	for(int i=0; i<num_chars; i++)
	{
		nib = i&1 ? data[i>>1]&0x0F : (data[i>>1]&0xF0)>>4 ;	//if character index is odd, look at lower half of byte. If even, look at upper half of byte.
		if(nib < 0x0A)								//if value is 0-9, simply add the value to the ascii code for '0'
			str[i] = '0' + nib;
		else										//if value is 10-15, add the value to the ascii code for 'A'
			str[i] = 'A' + (nib-10);
	}
}
