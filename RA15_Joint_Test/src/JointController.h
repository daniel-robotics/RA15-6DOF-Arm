/*
 * JointController.h
 * Built for RA15 robot.
 *  - Initializes, commands, monitors motor regulators
 *  - Moves robot joints to specified angular positions, taking into account gear ratios and mechanical dependencies
 *  - Synchronizes motions so all joints arrive at their target positions at (roughly) the same time
 *  - Respects mechanical limitations to prevent moving any joint too far or too fast
 *  - Handles automatic homing
 *
 *
 *     Version: 1.0
 *  Created on: Jan 6, 2019
 *      Author: Daniel
 */

#ifndef SRC_JOINTCONTROLLER_H_
#define SRC_JOINTCONTROLLER_H_

// NXT_COMPILE_TARGET PARAMETER SHOULD BE DEFINED AT THE TOP OF THE MAIN PROGRAM
#ifndef NXT_COMPILE_TARGET				// NXT1 : Upper arm control (axes 4, 5, 6), master controller, UI, touch sensors, US(?) sensors
#define NXT_COMPILE_TARGET NXT1			// NXT2 : Lower arm control (axes 2 and 1), RS485 slave to NXT1, EOPD sensors
#endif									// NXT3 : Middle arm contrl (axes 3 and 1), RS485 slave to NXT1, Light sensors

#include "MotorRegulator.h"
#include <math.h>
#include "kernel.h"
#include "ecrobot_interface.h"

//**************************************************************************************************
//*** RA15 PARAMETERS ******************************************************************************
//**************************************************************************************************

// Gear ratios
const F32 J1_GEAR = 21.0000f;		// J1: shoulder rotation	: (24/8)*(56/8)
const F32 J2_GEAR = 21.0000f;		// J2: shoulder extension	: (24/8)*(56/8)
const F32 J3_GEAR = 21.0000f;		// J3: elbow extension		: (24/8)*(56/8)
const F32 J4_GEAR = 8.33333f; 		// J4: elbow rotation		: (20/12)*(60/12)
const F32 J5_GEAR = 7.00000f; 		// J5: wrist extension		: (56/8)
const F32 J6_GEAR = 8.33333f; 		// J6: wrist rotation		: (20/12)*(20/12)*(60/20)
const F32 J6_4_GEAR = 1.00000f; 	// J6's dependency on J4	: (1)
const F32 J6_5_GEAR = 2.77777f;		// J6's dependency on J5	: (20/12)*(20/12)

// Motor ports
#define J1_1 NXT_PORT_C
#define J1_2 NXT_PORT_C
#define J2_1 NXT_PORT_A
#define J2_2 NXT_PORT_B
#define J3_1 NXT_PORT_A
#define J3_2 NXT_PORT_B
#define J4 NXT_PORT_A
#define J5 NXT_PORT_C
#define J6 NXT_PORT_B

// Motor regulator parameters
#define J1_1_MIRROR FALSE
#define J1_2_MIRROR TRUE
#define J2_1_MIRROR FALSE
#define J2_2_MIRROR TRUE
#define J3_1_MIRROR FALSE
#define J3_2_MIRROR TRUE
#define J4_MIRROR FALSE
#define J5_MIRROR FALSE
#define J6_MIRROR FALSE

#define J1_1_TYPE NXT_L
#define J1_2_TYPE NXT_L
#define J2_1_TYPE NXT_L
#define J2_2_TYPE NXT_L
#define J3_1_TYPE NXT_L
#define J3_2_TYPE NXT_L
#define J4_TYPE EV3_M
#define J5_TYPE NXT_L
#define J6_TYPE EV3_M

#define J1_ACCEL 1000
#define J2_ACCEL 1000
#define J3_ACCEL 1000
#define J4_ACCEL 1000
#define J5_ACCEL 1000
#define J6_ACCEL 1000

// Mechanical limits
#define J1_MAX_ANGLE 90.0f		// Max/min angles are for final joint positions
#define J1_MIN_ANGLE -90.0f
#define J1_MAX_SPEED 600		// Max speed is degrees/s and is for UNGEARED motor output (due to dependencies of joint 6, final output can't be used)
#define J2_MAX_ANGLE 50.0f
#define J2_MIN_ANGLE -50.0f
#define J2_MAX_SPEED 750
#define J3_MAX_ANGLE 75.0f
#define J3_MIN_ANGLE -75.0f
#define J3_MAX_SPEED 750
#define J4_MAX_ANGLE 90.0f
#define J4_MIN_ANGLE -90.0f
#define J4_MAX_SPEED 750
#define J5_MAX_ANGLE 120.0f
#define J5_MIN_ANGLE -90.0f
#define J5_MAX_SPEED 800
#define J6_MAX_ANGLE 300.0f
#define J6_MIN_ANGLE -300.0f
#define J6_MAX_SPEED 750


//**************************************************************************************************
//*** PUBLIC FUNCTIONS *****************************************************************************
//**************************************************************************************************

void initJointController();
void termJointController();

void moveJoints(F32 angleA, F32 angleB, F32 angleC, F32 timeSeconds);
void moveHome();
void identityBeep();
BOOL isOverLimit(U8 axis);

#endif /* SRC_JOINTCONTROLLER_H_ */
