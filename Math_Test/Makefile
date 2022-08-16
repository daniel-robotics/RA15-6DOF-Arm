# Name of resulting executable
TARGET = Math_Test_OSEK

# List of all .c files. Each file on its own line, separat lines by \ character.
TARGET_SOURCES = ./src/Math_Test.c

# OSEK .oil file, which configures the RTOS environment and tasks
TOPPERS_OSEK_OIL_SOURCE = ./template.oil

# External libraries to include. Each path on its own line, separate lines by \ character.
# IF USING ECLIPSE: Also add these paths to the project's Includes list.
USER_INC_PATH = B:/Libraries/C/libfixmatrix-master				\
				B:/Libraries/C/libfixmath-master/libfixmath

# Don't modify below part
O_PATH ?= build

# Makefile for C build
include ../../ecrobot/ecrobot.mak
