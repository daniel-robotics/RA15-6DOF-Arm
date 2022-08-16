/*
 * MotorRegulator.h
 *
 *	Public interface for MotorRegulator.
 *
 *     Version: 1.0
 *  Created on: Dec 9, 2018
 *      Author: Daniel
 */

#ifndef SRC_MOTORREGULATOR_H_
#define SRC_MOTORREGULATOR_H_

#include <string.h>
#include <math.h>
#include "kernel.h"
#include "ecrobot_interface.h"

//************************************************************************************************
//  PUBLIC FUNCTIONS
//************************************************************************************************

// Motor Ports
#define A NXT_PORT_A
#define B NXT_PORT_B
#define C NXT_PORT_C

// Motor Types
#define NXT_L 0
#define EV3_L 1
#define EV3_M 2

// Mirror modes
#define MIRROR TRUE
#define NO_MIRROR FALSE

// PWM Modes
#define BRAKE 1
#define FLOAT 0

// NXT_OSEK Hook Routines
void initMotorRegulator(U32 port, U8 motorType, BOOL mirror);
void termMotorRegulator(U32 port);

// Setters
void rotate(U32 port, S32 angle);
void rotateTo(U32 port, S32 limitAngle);
void setSpeed(U32 port, S32 speed);
void setAcceleration(U32 port, S32 acceleration);

// Getters
S8  getPower(U32 port);
S32 getAngle(U32 port);
S32 getLimitAngle(U32 port);
S32 getVelocity(U32 port);
S32 getTargetSpeed(U32 port);
S32 getIntermediateVelocity(U32 port);
S32 getAcceleration(U32 port);

// Unlimited move/stop
void forwardUnlimited(U32 port);
void backwardUnlimited(U32 port);
void stop(U32 port, U16 pwmMode);

// Status
BOOL isMoving(U32 port);
BOOL isStalled(U32 port);
BOOL isPending(U32 port);
BOOL isEnabled(U32 port);

// Misc
U8   getRegulatorTaskDuration();




#endif /* SRC_MOTORREGULATOR_H_ */
