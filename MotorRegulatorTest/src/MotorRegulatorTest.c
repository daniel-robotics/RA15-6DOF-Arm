#include "MotorRegulator.h"

#include <string.h>
#include "kernel.h"
#include "kernel_id.h"
#include "ecrobot_interface.h"

#define PIN "1234"
#define BT_NAME "NXT1"
#define BT_PACKET_SIZE 60
#define MAX_PACKETS 500

DeclareCounter(SysTimerCnt);
DeclareTask(BluetoothTask);
DeclareTask(LCDTask);
DeclareTask(MainTask);

U8 bluetoothTaskDuration = 0;
U32 packetsSent = 0;

void user_1ms_isr_type2(void)
{
	(void)SignalCounter(SysTimerCnt); 	// Increment OSEK Alarm Counter
}

void ecrobot_device_initialize()
{
	initMotorRegulator(A, EV3_M, NO_MIRROR);
	initMotorRegulator(B, EV3_M, NO_MIRROR);
	initMotorRegulator(C, NXT_L, NO_MIRROR);
	ecrobot_init_bt_slave(PIN);
//	ecrobot_set_bt_device_name(BT_NAME);
}

void ecrobot_device_terminate()
{
	termMotorRegulator(A);
	termMotorRegulator(B);
	termMotorRegulator(C);
	ecrobot_term_bt_connection();
}

TASK(BluetoothTask)
{
	ecrobot_init_bt_slave(PIN);	//Listen for incoming bluetooth connections
	struct packet{
		U32 v1;
		U32 v2;
		U8  v3;
		U16 v4;
		S8  v5;
		S8  v6;
		S8  v7;	//14 bytes
		S32 v8;
		S32 v9;
		S32 v10;
		S32 v11;
		S32 v12;
		S32 v13; //48 bytes
		S16 v14;
		S16 v15;
		S16 v16;
		S16 v17;
		S16 v18;
		S16 v19; //60 bytes
		U32 v20; //64 bytes
	} p = {
		packetsSent+1,
		systick_get_ms(),
		getRegulatorTaskDuration(),
		ecrobot_get_battery_voltage(),
		getPower(A),
		getPower(B),
		getPower(C),
		getAngle(A),
		getAngle(B),
		getAngle(C),
		getLimitAngle(A),
		getLimitAngle(B),
		getLimitAngle(C),
		getVelocity(A),
		getVelocity(B),
		getVelocity(C),
		getTargetSpeed(A),
		getTargetSpeed(B),
		getTargetSpeed(C),
		0
	};

	if(ecrobot_get_bt_status() == BT_STREAM && packetsSent < MAX_PACKETS)
	{
		U8 outbuf[BT_PACKET_SIZE];
		U8 offset = 0;
		memcpy(outbuf+offset, &p.v1,	sizeof(p.v1));	offset+=sizeof(p.v1);
		memcpy(outbuf+offset, &p.v2,	sizeof(p.v2));	offset+=sizeof(p.v2);
		memcpy(outbuf+offset, &p.v3,	sizeof(p.v3));	offset+=sizeof(p.v3);
		memcpy(outbuf+offset, &p.v4,	sizeof(p.v4));	offset+=sizeof(p.v4);
		memcpy(outbuf+offset, &p.v5,	sizeof(p.v5));	offset+=sizeof(p.v5);
		memcpy(outbuf+offset, &p.v6,	sizeof(p.v6));	offset+=sizeof(p.v6);
		memcpy(outbuf+offset, &p.v7,	sizeof(p.v7));	offset+=sizeof(p.v7);
		memcpy(outbuf+offset, &p.v8,	sizeof(p.v8));	offset+=sizeof(p.v8);
		memcpy(outbuf+offset, &p.v9,	sizeof(p.v9));	offset+=sizeof(p.v9);
		memcpy(outbuf+offset, &p.v10,	sizeof(p.v10));	offset+=sizeof(p.v10);
		memcpy(outbuf+offset, &p.v11,	sizeof(p.v11));	offset+=sizeof(p.v11);
		memcpy(outbuf+offset, &p.v12,	sizeof(p.v12));	offset+=sizeof(p.v12);
		memcpy(outbuf+offset, &p.v13,	sizeof(p.v13));	offset+=sizeof(p.v13);
		memcpy(outbuf+offset, &p.v14,	sizeof(p.v14));	offset+=sizeof(p.v14);
		memcpy(outbuf+offset, &p.v15,	sizeof(p.v15));	offset+=sizeof(p.v15);
		memcpy(outbuf+offset, &p.v16,	sizeof(p.v16));	offset+=sizeof(p.v16);
		memcpy(outbuf+offset, &p.v17,	sizeof(p.v17));	offset+=sizeof(p.v17);
		memcpy(outbuf+offset, &p.v18,	sizeof(p.v18));	offset+=sizeof(p.v18);
		memcpy(outbuf+offset, &p.v19,	sizeof(p.v19));	offset+=sizeof(p.v19);
		memcpy(outbuf+offset, &p.v20,	sizeof(p.v20));	offset+=sizeof(p.v20);

		ecrobot_send_bt_packet(outbuf, BT_PACKET_SIZE);
		packetsSent++;
		if(packetsSent == MAX_PACKETS)
			ecrobot_term_bt_connection();
	}

	bluetoothTaskDuration = systick_get_ms() - p.v2;
	TerminateTask();
}

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

	display_goto_xy(0, 1);	display_string("Packets: ");
	display_goto_xy(9, 1);	display_int(packetsSent, 6);

	display_goto_xy(0, 2);	display_string("RegTask: ");
	display_goto_xy(9, 2);	display_int(getRegulatorTaskDuration(), 6);

	display_goto_xy(0, 3);	display_string("BT_Task: ");
	display_goto_xy(9, 3);	display_int(bluetoothTaskDuration, 6);

	display_goto_xy(0, 4);	display_string("Motor_A: ");
	display_goto_xy(9, 4);	display_int(nxt_motor_get_count(A), 6);

	display_goto_xy(0, 5);	display_string("Motor_B: ");
	display_goto_xy(9, 5);	display_int(nxt_motor_get_count(B), 6);

	display_goto_xy(0, 6);	display_string("Motor_C: ");
	display_goto_xy(9, 6);	display_int(nxt_motor_get_count(C), 6);

	display_goto_xy(0, 7);	display_string("systick: ");
	display_goto_xy(9, 7);	display_int(systick_get_ms(), 6);

	display_update();
	TerminateTask();
}

// MAIN SEQUENCE

TASK(MainTask)
{
	while(ecrobot_get_bt_status() != BT_STREAM)		systick_wait_ms(1);	//Wait for bluetooth connection

	setSpeed(A, 850);
	setSpeed(B, 500);
	setSpeed(C, 500);
	setAcceleration(A, 2000);
	setAcceleration(B, 1000);
	setAcceleration(C, 1000);

	rotateTo(A, 90.0f*20.0f*60.0f/144.0f);
	while(isMoving(A) == TRUE) systick_wait_ms(1);
	rotateTo(A, 0);
	while(isMoving(A) == TRUE) systick_wait_ms(1);
	rotateTo(A, -90.0f*20.0f*60.0f/144.0f);
	while(isMoving(A) == TRUE) systick_wait_ms(1);
	rotateTo(A, 0);
	while(isMoving(A) == TRUE) systick_wait_ms(1);
	systick_wait_ms(500);
	rotateTo(A, 90.0f*20.0f*60.0f/144.0f);
	while(isMoving(A) == TRUE) systick_wait_ms(1);
	rotateTo(A, 0);
	while(isMoving(A) == TRUE) systick_wait_ms(1);
	rotateTo(A, -90.0f*20.0f*60.0f/144.0f);
	while(isMoving(A) == TRUE) systick_wait_ms(1);
	rotateTo(A, 0);
	while(isMoving(A) == TRUE) systick_wait_ms(1);

	while(1) systick_wait_ms(5);	//Technically this task can't end or the program crashes
}



