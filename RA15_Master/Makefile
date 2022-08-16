# Name of resulting executable
TARGET = RA15

# List of all .c files. Each file on its own line, separate lines by \ character.
TARGET_SOURCES = ./src/RA15.c									\
				 ./src/Globals.c								\
				 ./src/Control/Timing.c							\
				 ./src/Control/MotorRegulator.c					\
				 ./src/Control/Targeting.c						\
				 ./src/Control/Kinematics.c						\
				 ./src/Control/Homing.c							\
				 ./src/Sensors/Sensors.c						\
				 ./src/Sensors/PCF8574.c						\
				 ./src/Sensors/EOPD.c							\
				 ./src/Comms/RS485.c							\
				 ./src/Comms/Bluetooth.c						\
				 ./src/Comms/RCXComm.c							\
				 ./src/HumanInterface/Sound.c					\
				 ./src/HumanInterface/LCD.c						\
				 fix16.c										\
				 fix16_str.c									\
				 fix16_sqrt.c									\
				 fix16_trig.c									\
				 fixmatrix.c									\
				 fixarray.c


# OSEK .oil file, which configures the RTOS environment and tasks
TOPPERS_OSEK_OIL_SOURCE = ./RA15.oil



# External libraries to include. Each path on its own line, separate lines by \ character.
# IF USING ECLIPSE: Also add these paths to the project's Includes list.
USER_INC_PATH = B:/Libraries/C/libfixmatrix-master				\
				B:/Libraries/C/libfixmath-master/libfixmath

VPATH = $(USER_INC_PATH)

BUILD_MODE = RXE_ONLY

# Don't modify below part
O_PATH ?= build

# Makefile for C build
include ../../ecrobot/ecrobot.mak
