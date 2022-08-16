/*
 * MotorRegulator_private.h
 *
 *  Private functions for MotorRegulator
 *
 *  Created on: Dec 9, 2018
 *      Author: Daniel
 */

#ifndef SRC_MOTORREGULATOR_PRIVATE_H_
#define SRC_MOTORREGULATOR_PRIVATE_H_

#include <string.h>
#include <math.h>
#include "kernel.h"
#include "ecrobot_interface.h"

//************************************************************************************************
//  PRIVATE FUNCTIONS
//************************************************************************************************

DeclareResource(Motors);
DeclareTask(MotorRegulatorTask);
TASK(MotorRegulatorTask);

struct Regulator {
	BOOL enabled;		// enabled		: true if this motor should be regulated
	U32 port;			// port			: motor port this regulator is for
	U8	motorType;		// motorType	: NXT_L, EV3_L, or EV3_M
    S32 limitAngle;		// limitAngle	: target angular position
    S32 speed;			// speed		: target speed
    S32 acceleration;	// acceleration	: target acceleration
    S32	mirror;			// mirror		: if true, flips forward and backward directions.
	BOOL stalled;		// stalled		: true if regulator detects stall condition
    S32 stallLimit;		// stallLimit	: used for checking stall condition
    S32 stallCnt;		// stallCnt		: used for checking stall condition
    U16 pwmMode;		// pwmMode		: BRAKE or FLOAT at the end of a motion
	S32 angle0;			// angle0		: raw tacho count used as reference 0 angle
	F32 basePower; 		// basePower	: used in PID for calculateing power
	S32 pwr;			// pwr			: actual PWM power percentage sent to motor
	F32 err1; 	   		// err1			: used in PID for smoothing
	F32 err2;     		// err2			: used in PID for smoothing
	F32 curVelocity;	// curVelocity	: calculated actual velocity
	F32 baseVelocity;	// baseVelocity	:
	F32 baseCnt;		// baseCnt		:
	F32 curCnt;			// curCnt		:
	F32 curAcc;			// curAcc		:
	F32 curTargetVelocity;// curTargetVelocity:
	S32 curLimit;		// curLimit		:
	BOOL curHold;		// curHold		:
	F32 accCnt;			// accCnt		:
	U32 now;			// now			: time (in ms) of task start
	U32 baseTime;		// baseTime		:
	U32 accTime;		// accTime		:
	BOOL moving;		// moving		: true if movement command is in progress
	BOOL pending;		// pending		: true if movement command is waiting for another command to complete
	S32 pendingVelocity;	// pendingVelocity		: stores pending movement command target velocity
	S32 pendingAcceleration;// pendingAcceleration	: stores pending movement command acceleration
	S32 pendingLimitAngle;	// pendingLimitAngle	: stores pending movement command limit angle
	BOOL pendingHold;		// pendingHold			: stores pending movement command hold target
};

void startSubMove(struct Regulator* reg, F32 velocity, F32 acceleration, S32 limit, BOOL hold);
void endMove(struct Regulator* reg, BOOL stalled);
void calcPower(struct Regulator* reg, F32 error, F32 P, F32 I, F32 D);
void newMove(struct Regulator* reg, S32 velocity, S32 acceleration, S32 limit, BOOL hold);


#endif /* SRC_MOTORREGULATOR_PRIVATE_H_ */
