/*
 * JointController.c
 *
 *     Version: 1.0
 *  Created on: Jan 6, 2019
 *      Author: Daniel
 */

#include "JointController.h"

static U32 JA, JB, JC;					// motor ports
static F32 gearA, gearB, gearC;			// gear ratios for joints A, B, C
static F32 gear6_4 = 0, gear6_5 = 0;	// gear ratios for axis 6's dependencies on 4 and 5
static S32 maxSpeedA, maxSpeedB, maxSpeedC;
static F32 maxAngleA, maxAngleB, maxAngleC;
static F32 minAngleA, minAngleB, minAngleC;
static BOOL overLimit[3];

void initJointController()
{
	#if NXT_COMPILE_TARGET == NXT1
		initMotorRegulator(J4, J4_TYPE, J4_MIRROR);
		setAcceleration(J4, J4_ACCEL);
		JA = J4;
		gearA = J4_GEAR;
		maxSpeedA = J4_MAX_SPEED;
		maxAngleA = J4_MAX_ANGLE;
		minAngleA = J4_MIN_ANGLE;
		initMotorRegulator(J5, J5_TYPE, J5_MIRROR);
		setAcceleration(J5, J5_ACCEL);
		JB = J5;
		gearB = J5_GEAR;
		maxSpeedB = J5_MAX_SPEED;
		maxAngleB = J5_MAX_ANGLE;
		minAngleB = J5_MIN_ANGLE;
		initMotorRegulator(J6, J6_TYPE, J6_MIRROR);
		setAcceleration(J6, J6_ACCEL);
		JC = J6;
		gearC = J6_GEAR;
		gear6_4 = J6_4_GEAR;
		gear6_5 = J6_5_GEAR;
		maxSpeedC = J6_MAX_SPEED;
		maxAngleC = J6_MAX_ANGLE;
		minAngleC = J6_MIN_ANGLE;
	#elif NXT_COMPILE_TARGET == NXT2
		initMotorRegulator(J2_1, J2_1_TYPE, J2_1_MIRROR);
		setAcceleration(J2_1, J2_ACCEL);
		JA = J2_1;
		gearA = J2_GEAR;
		maxSpeedA = J2_MAX_SPEED;
		maxAngleA = J2_MAX_ANGLE;
		minAngleA = J2_MIN_ANGLE;
		initMotorRegulator(J2_2, J2_2_TYPE, J2_2_MIRROR);
		setAcceleration(J2_2, J2_ACCEL);
		JB = J2_2;
		gearB = J2_GEAR;
		maxSpeedB = J2_MAX_SPEED;
		maxAngleB = J2_MAX_ANGLE;
		minAngleB = J2_MIN_ANGLE;
		initMotorRegulator(J1_1, J1_1_TYPE, J1_1_MIRROR);
		setAcceleration(J1_1, J1_ACCEL);
		JC = J1_1;
		gearC = J1_GEAR;
		maxSpeedC = J1_MAX_SPEED;
		maxAngleC = J1_MAX_ANGLE;
		minAngleC = J1_MIN_ANGLE;
	#elif NXT_COMPILE_TARGET == NXT3
		initMotorRegulator(J3_1, J3_1_TYPE, J3_1_MIRROR);
		setAcceleration(J3_1, J3_ACCEL);
		JA = J3_1;
		gearA = J2_GEAR;
		maxSpeedA = J2_MAX_SPEED;
		maxAngleA = J2_MAX_ANGLE;
		minAngleA = J2_MIN_ANGLE;
		initMotorRegulator(J3_2, J3_2_TYPE, J3_2_MIRROR);
		setAcceleration(J3_2, J3_ACCEL);
		JB = J3_2;
		gearB = J2_GEAR;
		maxSpeedB = J2_MAX_SPEED;
		maxAngleB = J2_MAX_ANGLE;
		minAngleB = J2_MIN_ANGLE;
		initMotorRegulator(J1_2, J1_2_TYPE, J1_2_MIRROR);
		setAcceleration(J1_2, J1_ACCEL);
		JC = J1_2;
		gearC = J1_GEAR;
		maxSpeedC = J1_MAX_SPEED;
		maxAngleC = J1_MAX_ANGLE;
		minAngleC = J1_MIN_ANGLE;
	#endif
}

void termJointController()
{

}




//	move:
//	Moves robot joints A, B, C to the specified final angles, taking into account gear ratios, and where C may be dependent on the other two axes.
//  Waits for all movements to complete before returning.
void moveJoints(F32 angleA, F32 angleB, F32 angleC, F32 timeSeconds)
{
	// Clamp angles to their min/max values if over angle limit
	if(angleA > maxAngleA){			angleA = maxAngleA;		overLimit[JA] = TRUE; }
	else if(angleA < minAngleA){	angleA = minAngleA;		overLimit[JA] = TRUE; }
	else overLimit[JA] = FALSE;
	if(angleB > maxAngleB){		angleB = maxAngleB;	overLimit[JB] = TRUE; }
	else if(angleB < minAngleB){	angleB = minAngleB;	overLimit[JB] = TRUE; }
	else overLimit[JB] = FALSE;
	if(angleC > maxAngleC){		angleC = maxAngleC;	overLimit[JC] = TRUE; }
	else if(angleC < minAngleC){	angleC = minAngleC;	overLimit[JC] = TRUE; }
	else overLimit[JC] = FALSE;

	// Overwrite input "final joint" angles with "motor shaft" angles by using gear ratios
	angleC = angleC*gearC + angleA*gear6_4 + angleB*gear6_5;	//NXT1, axis 6 is dependent on 4 and 5. Gear dependencies are 0 if not NXT1.
	angleA = angleA*gearA;
	angleB = angleB*gearB;

	// Speed = Change_in_angle / Change_in_time		(so all joints finish at roughly the same time)
	setSpeed(JA, (S32)roundf(((F32)getAngle(JA)-angleA)/timeSeconds) );
	setSpeed(JB, (S32)roundf(((F32)getAngle(JB)-angleA)/timeSeconds) );
	setSpeed(JC, (S32)roundf(((F32)getAngle(JC)-angleA)/timeSeconds) );

	// Instruct motors to move to their new positions and wait for them to finish rotating
	if(angleA != getLimitAngle(JA)) rotateTo(JA, angleA);
	if(angleB != getLimitAngle(JB)) rotateTo(JB, angleB);
	if(angleC != getLimitAngle(JC)) rotateTo(JC, angleC);
	while(isMoving(JA)==TRUE || isMoving(JB)==TRUE || isMoving(JC)==TRUE) systick_wait_ms(1);
}

//	moveJointsSync:
//	Moves robot joints A, B, C to the specified final angles, taking into account gear ratios.
//	Adjusts motor speeds so all joints complete the specified movement in the same amount of time.
//  Waits for all movements to complete before returning.
void moveJointsSync(U8 JA, F32 angleA, U8 JB, F32 angleB, U8 JC, F32 angleC, F32 timeSeconds)
{

}

void moveHome()
{
	moveJoints(0, 0, 0, 4.0);
}

BOOL isOverLimit(U8 axis)
{
	return overLimit[axis];
}

void identityBeep()
{
	#if NXT_COMPILE_TARGET == NXT1			// Beep once for NXT1
		ecrobot_sound_tone(500, 50, 25);
	#elif NXT_COMPILE_TARGET == NXT2		// Beep twice for NXT2
		ecrobot_sound_tone(500, 50, 25);
		systick_wait_ms(500);
		ecrobot_sound_tone(500, 50, 25);
	#elif NXT_COMPILE_TARGET == NXT3		// Beep thrice for NXT3
		ecrobot_sound_tone(500, 50, 25);
		systick_wait_ms(500);
		ecrobot_sound_tone(500, 50, 25);
		systick_wait_ms(500);
		ecrobot_sound_tone(500, 50, 25);
	#endif
}
