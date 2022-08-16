//*********************************************************************
// NXT COMPILE TARGET:
// Compiles program for NXT1, NXT2, or NXT3
#define NXT_COMPILE_TARGET NXT1
//*********************************************************************

#include "JointController.h"
#include "MotorRegulator.h"
#include "kernel.h"
#include "kernel_id.h"
#include "ecrobot_interface.h"

/* LEJOS OSEK hooks */
DeclareCounter(SysTimerCnt);
DeclareTask(MainTask);
DeclareTask(LCDTask);

/* Function declarations */

void user_1ms_isr_type2(void)
{
	(void)SignalCounter(SysTimerCnt); 	// Increment OSEK Alarm Counter
}

void ecrobot_device_initialize()
{
	initJointController();
}

void ecrobot_device_terminate()
{
	termJointController();
}


// LCD
TASK(LCDTask)
{
	display_clear(0);

	display_goto_xy(0, 0);
	switch(ecrobot_get_bt_status()){
	case BT_NO_INIT: 		display_string("BT: NO INIT");		break;
	case BT_INITIALIZED: 	display_string("BT: INITIALIZED");	break;
	case BT_CONNECTED: 		display_string("BT: CONNECTED");	break;
	case BT_STREAM:			display_string("BT: STREAMING");	break;
	}

	display_goto_xy(0, 1);	display_string("J4 Lim: ");
	display_goto_xy(9, 1);	display_int(getLimitAngle(J4), 6);

	display_goto_xy(0, 2);	display_string("J5 Lim: ");
	display_goto_xy(9, 2);	display_int(getLimitAngle(J5), 6);

	display_goto_xy(0, 3);	display_string("J6 Lim: ");
	display_goto_xy(9, 3);	display_int(getLimitAngle(J6), 6);

	display_goto_xy(0, 4);	display_string("J4 Vel: ");
	display_goto_xy(9, 4);	display_int(getVelocity(J4), 6);

	display_goto_xy(0, 5);	display_string("J5 Vel: ");
	display_goto_xy(9, 5);	display_int(getVelocity(J5), 6);

	display_goto_xy(0, 6);	display_string("J6 Vel: ");
	display_goto_xy(9, 6);	display_int(getVelocity(J6), 6);

	display_goto_xy(0, 7);	display_string("systick: ");
	display_goto_xy(9, 7);	display_int(systick_get_ms(), 6);

	display_update();
	TerminateTask();
}

// MAIN SEQUENCE
TASK(MainTask)
{
	identityBeep();

	for(U8 i=2; i>0; i--)
	{
		moveJoints( 90.0,	0.0,	-90.0,	i );	systick_wait_ms(500);
		moveJoints( 90.0,	90.0,	-90.0,	i );	systick_wait_ms(500);
		moveJoints( -90.0,	90.0,	-90.0,	i );	systick_wait_ms(500);
		moveJoints( 0.0,	0.0,	0.0,	i );	systick_wait_ms(500);
	}

	while(1) systick_wait_ms(5);	//Technically this task can't end or the program crashes
}



