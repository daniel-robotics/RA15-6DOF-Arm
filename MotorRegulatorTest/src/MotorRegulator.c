#include "MotorRegulator.h"
#include "MotorRegulator_private.h"


/**
 * Abstraction for a NXT motor.
 * The basic control methods are:
 *  <code>forward, backward, reverseDirection, stop</code>
 * and <code>flt</code>. To set each motor's velocity, use {@link #setSpeed(S32)
 * <code>setSpeed  </code> }.
 * The maximum velocity of the motor limited by the battery voltage and load.
 * With no load, the maximum degrees per second is about 100 times the voltage.  <br>
 * The velocity is regulated by comparing the tacho count with velocity times elapsed
 * time, and adjusting motor power to keep these closely matched.
 * The methods <code>rotate(S32 angle) </code> and <code>rotateTo(S32 angel)</code>
 * use the tachometer to control the position at which the motor stops, usually within 1 degree
 * or 2.<br>
 *  <br> <b> Listeners.</b>  An object implementing the {@link lejos.robotics.TachoMotorListener
 * <code> TachoMotorListener </code> } interface  may register with this class.
 * It will be informed each time the motor starts or stops.
 * <br> <b>Stall detection</b> If a stall is detected, the motor will stop, and
 * <code>isStalled()</code >  returns <b>TRUE</b>.
 * <br>Motors will hold their position when stopped. If this is not what you require use
 * the flt() method instead of stop().
 * <br>
 * <p>
 * Example:<p>
 * <code><pre>
 *   Motor1.A.setSpeed(720);// 2 RPM
 *   Motor1.C.setSpeed(720);
 *   Motor1.A.forward();
 *   Motor1.C.forward();
 *   Thread.sleep (1000);
 *   Motor1.A.stop();
 *   Motor1.C.stop();
 *   Motor1.A.rotateTo( 360);
 *   Motor1.A.rotate(-720,TRUE);
 *   while(Motor1.A.isRotating() :Thread.yield();
 *   S32 angle = Motor1.A.getTachoCount(); // should be -360
 *   LCD.drawInt(angle,0,0);
 * </pre></code>
 * @author Roger Glassey/Andy Shaw/Daniel Kennedy
 */
	// PID constants for move and for hold, for each motor type (NXT_L, EV3_L, EV3_M).
	const F32 MOVE_P[3] = {4.00f, 4.00f, 6.00f};
	const F32 MOVE_I[3] = {0.04f, 0.04f, 0.02f};
	const F32 MOVE_D[3] = {32.0f, 32.0f, 15.00f};
	const F32 HOLD_P[3] = {2.00f, 2.00f, 1.00f};
	const F32 HOLD_I[3] = {0.04f, 0.04f, 0.04f};
	const F32 HOLD_D[3] = {8.00f, 8.00f, 12.00f};

	const S32 MAX_POWER = 100;			// Maximum PWM power
	const S32 NO_LIMIT = 0x7fffffff;	// Indicates no limit angle

	U8 regTaskDuration = 0;
	struct Regulator regs[3];			// One regulator struct for each motor. Index 0=A, 1=B, 2=C


    /**
     * Use this constructor to assign a variable of type motor connected to a particular port.
     * @param port  to which this motor is connected
     */
    void initMotorRegulator(U32 port, U8 motorType, BOOL mirror)
    {
    	nxt_motor_set_speed(port, 0, 1);
    	nxt_motor_set_count(port, 0);

    	//Initialize regulator struct
    	struct Regulator* reg = &regs[port];
    	reg->enabled		= TRUE;		// enabled		: true if this motor should be regulated
    	reg->port			= port;		// port			: port this regulator is for
    	reg->motorType		= motorType;// motorType	: NXT_L, EV3_L, or EV3_M
    	reg->limitAngle 	= 0;		// limitAngle	: target angular position
    	reg->speed 			= 0;		// speed		: target speed
    	reg->acceleration	= 1000;		// acceleration	: target acceleration
    	reg->mirror=(mirror==TRUE?-1:1);// mirror		: flips forward and backward directions for this motor
    	reg->stalled		= FALSE;	// stalled		: true if regulator detects stall condition
    	reg->stallLimit		= 50;		// stallLimit	: used for checking stall condition
    	reg->stallCnt		= 0;		// stallCnt		: used for checking stall condition
    	reg->pwmMode 		= BRAKE;	// pwmMode		: BRAKE or FLOAT at the end of a motion
    	reg->angle0 		= 0;		// angle0		: raw tacho count used as reference 0 angle
    	reg->basePower		= 0; 		// basePower	: used in PID for calculating power
    	reg->pwr			= 0;		// pwr			: actual PWM power percentage sent to motor
    	reg->err1 			= 0; 	   	// err1			: used in PID for smoothing
    	reg->err2 			= 0;     	// err2			: used in PID for smoothing
    	reg->curVelocity 	= 0;		// curVelocity	: calculated actual velocity
    	reg->baseVelocity	= 0;		// baseVelocity	:
    	reg->baseCnt 		= 0;		// baseCnt		:
    	reg->curCnt 		= 0;		// curCnt		:
    	reg->curAcc 		= 0;		// curAcc		:
    	reg->curTargetVelocity = 0;		// curTargetVelocity:
    	reg->curLimit 		= NO_LIMIT;	// curLimit		:
    	reg->curHold 		= TRUE;		// curHold		:
    	reg->accCnt 		= 0;		// accCnt		:
    	reg->now = systick_get_ms();	// now			: time (in ms) of task start
    	reg->baseTime 		= reg->now;	// baseTime		:
    	reg->accTime		= 0;		// accTime		:
    	reg->moving 		= FALSE;	// moving		: true if movement command is in progress
    	reg->pending		= FALSE;	// pending		: true if movement command is waiting for another command to complete
    	reg->pendingVelocity	= 0;	// pendingVelocity		: stores pending movement command target velocity
    	reg->pendingAcceleration= 0;	// pendingAcceleration	: stores pending movement command acceleration
    	reg->pendingLimitAngle 	= 0;	// pendingLimitAngle	: stores pending movement command limit angle
    	reg->pendingHold 		= TRUE;	// pendingHold			: stores pending movement command hold target
    }

    void termMotorRegulator(U32 port)
    {
    	regs[port].enabled = FALSE;
    	nxt_motor_set_speed(port, 0, 1);
    }

    /**
     * Rotate by the request number of degrees.
     * @param angle number of degrees to rotate relative to the current position
     */
    void rotate(U32 port, S32 angle)
    {
    	rotateTo(port, (S32)roundf(regs[port].curCnt) + angle);
    }

    /**
     * Rotate to the target angle.
     * @param limitAngle Angle to rotate to.
     */
    void rotateTo(U32 port, S32 limitAngle)
    {
    	struct Regulator* reg = &regs[port];
    	if(limitAngle == (S32)roundf(reg->curCnt) || limitAngle == reg->limitAngle)
    		stop(reg->port, reg->pwmMode);
    	else
    	{
			reg->limitAngle = limitAngle;
			newMove( reg, roundf(reg->curCnt) <= limitAngle ? +(reg->speed) : -(reg->speed), reg->acceleration, limitAngle, TRUE );
    	}
    }

    /**
     * Sets desired motor speed , in degrees per second;
     * The maximum reliably sustainable velocity is  100 x battery voltage under
     * moderate load, such as a direct drive robot on the level.
     * If the parameter is larger than that, the maximum sustainable value will
     * be used instead.
     * @param speed value in degrees/sec
     */
    void setSpeed(U32 port, S32 speed)
    {
    	struct Regulator* reg = &regs[port];
		reg->speed = (S32)fabsf(speed);
		if (reg->curTargetVelocity != 0)
			startSubMove( reg, (reg->curTargetVelocity < 0 ? -(reg->speed) : +(reg->speed)), reg->curAcc, reg->curLimit, reg->curHold );
		if (reg->pending == TRUE)
			reg->pendingVelocity = (reg->pendingVelocity < 0 ? -(reg->speed) : +(reg->speed));
    }

    /**
     * sets the acceleration rate of this motor in degrees/sec/sec <br>
     * The default value is 1000; Smaller values will make speeding up. or stopping
     * at the end of a rotate() task, smoother;
     * @param acceleration
     */
    void setAcceleration(U32 port, S32 acceleration)
    {
    	struct Regulator* reg = &regs[port];
		reg->acceleration = (S32)fabsf(acceleration);
		if (reg->curTargetVelocity != 0)
			startSubMove( reg, reg->curTargetVelocity, reg->acceleration, reg->curLimit, reg->curHold );
		if (reg->pending == TRUE)
			reg->pendingAcceleration = reg->acceleration;
    }

    S8 getPower(U32 port)
    {
    	return (S8)regs[port].pwr;
    }

    /**
     * @see lejos.robotics.TachoMotor#getTachoCount()
     */
    S32 getAngle(U32 port)
    {
        return (S32)roundf(regs[port].curCnt);
    }

    /**
     * Return the angle that this Motor1 is rotating to.
     * @return angle in degrees
     */
    S32 getLimitAngle(U32 port)
    {
        return regs[port].limitAngle;
    }

    /**
     * Return the current velocity.
     * @return current velocity in degrees/s
     */
    S32 getVelocity(U32 port)
    {
        return (S32)roundf(regs[port].curVelocity);
    }

    /**
     * Return the user-specified target speed.
     * @return the target speed.
     */
    S32 getTargetSpeed(U32 port)
    {
        return regs[port].speed;
    }

    /**
     * Return the current intermediate velocity target.
     * @return the current intermediate velocity target.
     */
    S32 getIntermediateVelocity(U32 port)
    {
        return regs[port].curTargetVelocity;
    }

    /**
     * returns target acceleration in degrees/second/second
     * @return the value of acceleration
     */
    S32 getAcceleration(U32 port)
    {
        return regs[port].acceleration;
    }

    /**
     * @see lejos.nxt.BasicMotor#forward()
     */
    void forwardUnlimited(U32 port)
    {
    	struct Regulator* reg = &regs[port];
        newMove(reg, +reg->speed, reg->acceleration, +NO_LIMIT, TRUE);
    }

    /**
     * @see lejos.nxt.BasicMotor#backward()
     */
    void backwardUnlimited(U32 port)
    {
    	struct Regulator* reg = &regs[port];
        newMove(reg, -reg->speed, reg->acceleration, -NO_LIMIT, TRUE);
    }

    /**
     * Stops motor, canceling any rotate() orders in progress.
     * @param pwmMode either BRAKE or FLOAT
     */
    void stop(U32 port, U16 pwmMode)
    {
    	struct Regulator* reg = &regs[port];
    	reg->pwmMode = pwmMode;
        newMove(reg, 0, reg->acceleration, NO_LIMIT, (pwmMode == BRAKE ? TRUE : FALSE) );
    }

    /**
     * This method returns <b>TRUE </b> if the motor is attempting to rotate.
     * The return value may not correspond to the actual motor movement.<br>
     * For example,  If the motor is stalled, isMoving()  will return <b> TRUE. </b><br>
     * After flt() is called, this method will return  <b>FALSE</b> even though the motor
     * axle may continue to rotate by inertia.
     * If the motor is stalled, isMoving()  will return <b> TRUE. </b> . A stall can
     * be detected  by calling {@link #getRotationSpeed()} or {@link #getError()};
     * @return TRUE iff the motor if the motor is attempting to rotate.<br>
     */
    BOOL isMoving(U32 port)
    {
        return regs[port].moving;
    }

    /**
     * Return TRUE if the motor is currently stalled.
     * @return
     */
    BOOL isStalled(U32 port)
    {
        return regs[port].stalled;
    }

    /**
     * Return TRUE if the last-received movement command is waiting on another move to finish.
     * @return
     */
    BOOL isPending(U32 port)
    {
    	return regs[port].pending;
    }

    /**
     * Returns amount of time, in milliseconds, that the last regulator task took.
     */
    U8 getRegulatorTaskDuration()
    {
    	return regTaskDuration;
    }





	/**
	 * Internal functions to regulate velocity; also stop motor at desired rotation angle.
	 * This class uses a very simple movement model based on simple linear
	 * acceleration. This model is used to generate ideal target positions which
	 * are then used to generate error terms between the actual and target position
	 * this error term is then used to drive a PID style motor controller to
	 * regulate the power supplied to the motor.
	 *
	 * If new command are issued while a move is in progress, the new command
	 * is blended with the current one to provide smooth movement.
	 *
	 * If the requested speed is not possible then the controller will simply
	 * drop move cycles until the motor catches up with the ideal position. If
	 * too many consecutive dropped moves are required then the motor is viewed
	 * to have stalled and the move is terminated.
	 *
	 * Once the motor stops, the final position is held using the same PID control
	 * mechanism (with slightly different parameters), as that used for movement.
	 **/


	/**
	 * Helper method. Start a sub move operation. A sub move consists
	 * of acceleration/deceleration to a set velocity and then holding that
	 * velocity up to an optional limit point. If a limit point is set this
	 * method will be called again to initiate a controlled deceleration
	 * to that point
	 * @param velocity
	 * @param acceleration
	 * @param limit
	 * @param hold
	 */
	void startSubMove(struct Regulator* reg, F32 velocity, F32 acceleration, S32 limit, BOOL hold)
	{
		F32 absAcc = fabsf(acceleration);
		reg->baseTime = reg->now;
		reg->curTargetVelocity = velocity;
		reg->curAcc = velocity - reg->curVelocity >= 0 ? absAcc : -absAcc;
		reg->accTime = (S32)roundf(((velocity - reg->curVelocity) / reg->curAcc) * 1000);
		reg->accCnt = (reg->curVelocity + reg->curTargetVelocity) * reg->accTime / (2 * 1000);
		reg->baseCnt = reg->curCnt;
		reg->baseVelocity = reg->curVelocity;
		reg->curLimit = (limit == -NO_LIMIT ? -limit : limit);
		reg->curHold = hold;
		reg->moving = (reg->curTargetVelocity != 0 || reg->baseVelocity != 0 ? TRUE : FALSE);
	}

	/**
	 * Initiate a new move and optionally wait for it to complete.
	 * If some other move is currently executing then ensure that this move
	 * is terminated correctly and then start the new move operation.
	 * @param velocity
	 * @param acceleration
	 * @param limit
	 * @param hold
	 */
	void newMove(struct Regulator* reg, S32 velocity, S32 acceleration, S32 limit, BOOL hold)
	{
		reg->pending = FALSE;	// ditch any existing pending command
		if (velocity == 0)
			startSubMove(reg, 0, acceleration, NO_LIMIT, hold);		// Stop moves always happen now
		else if (reg->moving == FALSE)
			startSubMove(reg, velocity, acceleration, limit, hold);	// not moving so start a new move
		else
		{
			// we already have a move in progress can we modify it to match
			// the new request? We must ensure that the new move is in the
			// same direction and that any stop will not exceed the current
			// acceleration request.
			F32 acc = (reg->curVelocity*reg->curVelocity)/(2*(limit - reg->curCnt));// calculate minimum acceleration necessary to carry out the new move
			if (velocity*reg->curVelocity >= 0 && fabsf(acc) <= acceleration)		// if current and new velocities are in the same direction, AND new acceleration is sufficient...
				startSubMove(reg, velocity, acceleration, limit, hold);				// carry out the new movement right away.
			else
			{	// If new angle target is in the opposite direction the motor is moving, or the new acceleration is too low,
				// Save the requested move for later (store as pending)
				reg->pendingVelocity = velocity;
				reg->pendingAcceleration = acceleration;
				reg->pendingLimitAngle = limit;
				reg->pendingHold = hold;
				reg->pending = TRUE;
				// and stop the current move. Pending movement command will execute after motor stops.
				startSubMove(reg, 0, acceleration, NO_LIMIT, TRUE);
			}
		}
	}

	/**
	 * The move has completed either by the motor stopping or by it stalling
	 * @param stalled
	 */
	void endMove(struct Regulator* reg, BOOL stalled)
	{
		reg->moving = reg->pending;
		if (stalled)
		{
			// stalled try and maintain current position
			reg->curCnt = reg->angle0 = reg->mirror*nxt_motor_get_count(reg->port); //Reset position
			reg->curVelocity = 0;
			reg->stallCnt = 0;
			startSubMove( reg, 0, 0, NO_LIMIT, reg->curHold );
		}
		// if we have a pending move, start it
		if (reg->pending == TRUE)
		{
			reg->pending = FALSE;
			startSubMove( reg, reg->pendingVelocity, reg->pendingAcceleration, reg->pendingLimitAngle, reg->pendingHold );
		}
	}

	/**
	 * helper method for velocity regulation.
	 * calculates power from error using double smoothing and PID like
	 * control
	 * @param error
	 */
	void calcPower(struct Regulator* reg, F32 error, F32 P, F32 I, F32 D)
	{
		// use smoothing to reduce the noise in frequent encoder count readings
		reg->err1 = 0.5f * reg->err1 + 0.5f * error;  // fast smoothing
		reg->err2 = 0.8f * reg->err2 + 0.2f * error; // slow smoothing
		F32 power = reg->basePower + P * reg->err1 + D * (reg->err1 - reg->err2);
		reg->basePower = reg->basePower + I * (power - reg->basePower);
		if (reg->basePower > MAX_POWER)
			reg->basePower = MAX_POWER;
		else if (reg->basePower < -MAX_POWER)
			reg->basePower = -MAX_POWER;
		reg->pwr = reg->mirror*(power > MAX_POWER ? MAX_POWER : power < -MAX_POWER ? -MAX_POWER : (S32)roundf(power)); //Clamp to -MAX_POWER to MAX_POWER
		nxt_motor_set_speed(reg->port, reg->pwr, reg->pwmMode);
	}

	/**
	 * Monitors time and tachoCount to regulate velocity and stop motor rotation at limit angle
	 */
	TASK(MotorRegulatorTask)
	{
		U32 taskStart = systick_get_ms();
		GetResource(Motors);

		for(U8 port=0; port<3; port++)
		{
			struct Regulator* reg = &regs[port];
			if(reg->enabled == TRUE)
			{
				F32 error;
				U32 delta = systick_get_ms() - reg->now;
				reg->now += delta;
				U32 elapsed = reg->now - reg->baseTime;
				S32 tachoCount = reg->mirror*nxt_motor_get_count(reg->port);
				S32 angle = tachoCount - reg->angle0;
				if (reg->moving == TRUE)
				{
					if (elapsed < reg->accTime)
					{
						// We are still accelerating, calculate new position
						reg->curVelocity = reg->baseVelocity + reg->curAcc * elapsed / (1000);
						reg->curCnt = reg->baseCnt + (reg->baseVelocity + reg->curVelocity) * elapsed / (2 * 1000);
						error = reg->curCnt - angle;
					} else
					{
						// no longer accelerating, calculate new position
						reg->curVelocity = reg->curTargetVelocity;
						reg->curCnt = reg->baseCnt + reg->accCnt + reg->curVelocity * (elapsed - reg->accTime) / 1000;
						error = reg->curCnt - angle;
						// Check to see if the move is complete
						if (reg->curTargetVelocity == 0 && (reg->pending==TRUE || (fabsf(error) < 2 && elapsed > reg->accTime + 100) || elapsed > reg->accTime + 500))
							endMove(reg, FALSE);
					}
					// check for stall
					if (fabsf(error) > reg->stallLimit)
					{
						reg->baseTime += delta;
						if (reg->stallCnt++ > 1000) endMove(reg, TRUE);
					}
					else
					{
						reg->stallCnt /= 2;
					}
					calcPower(reg, error, MOVE_P[reg->motorType], MOVE_I[reg->motorType], MOVE_D[reg->motorType]);
					// If we have a move limit, check for time to start the deceleration stage
					if (reg->curLimit != NO_LIMIT)
					{
						F32 acc = (reg->curVelocity*reg->curVelocity)/(2*(reg->curLimit - reg->curCnt));
						if (fabsf(acc) >= fabsf(reg->curAcc))
							startSubMove(reg, 0, acc, NO_LIMIT, reg->curHold);
					}
				} else if (reg->curHold)
				{
					// not moving, hold position
					error = reg->curCnt - angle;
					calcPower(reg, error, HOLD_P[reg->motorType], HOLD_I[reg->motorType], HOLD_D[reg->motorType]);
				}
			}
		}


		ReleaseResource(Motors);
		regTaskDuration = (U8)(systick_get_ms() - taskStart);
		TerminateTask();
	}
