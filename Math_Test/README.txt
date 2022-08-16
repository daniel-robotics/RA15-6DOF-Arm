*****************************************
***  Creating a New NXT OSEK Project  ***
*****************************************

Open Eclipse IDE for C/C++ Developers.
 - Switch to Workspace in "Cygwin/nxtOSEK2.18/projects"
 - All projects should be created within this workspace, in this folder.

In Project Explorer panel:
 - Right click "OSEK_C_Template" or "OSEK_CPP_Template" project, click Copy
 - Right click empty space in the Project Explorer, click Paste
 - Type a name for the new C project. NO SPACES ALLOWED.

Edit Makefile to set filenames for the project
 - TARGET					: name of resulting binary, as it will appear on the NXT
 - TARGET_SOURCES			: names of all .c or .cpp files to be compiled together
 - TOPPERS_OSEK_OIL_SOURCE	: name of .oil file which defines the operating parameters for the program

Rename files as needed to reflect changes to the Makefile.
Edit .oil file to change operating parameters of the real-time operating system.


*****************************************
***  Downloading an NXT OSEK Project  ***
*****************************************

NXT must have the NXC Enhanced Firmware downloaded. Install firmware using BricxCC.
 - This firmware is compatible with standard NXT-G programs, NXC programs, and NXT-OSEK programs.
 - Max program size (ROM+RAM) is 64 KB
After creating a new NXT-OSEK project:
 - Change the Launch configuration to "nxtOSEK RXE Flash"
 - Click Run

For larger program size, use Launch Configuration "nxtOSEK BIOS Flash" to install OSEK-specific firmware.
 - This firmware is only compatible with NXT-OSEK programs.
 - Max program size is 224 KB (ROM) and 50KB (RAM) 
After creating a new NXT-OSEK project:
 - Change the Launch configuration to "nxtOSEK App Flash"
 - Click Run


*****************************************
***         Troubleshooting           ***
*****************************************

Errors/Files not found/tools not working:
 - Set the system environment variable "CYGWIN_HOME" = B:\Tools\Cygwin	(or whatever the path is)

No Launch Configurations, or Launch Configuration Not Working:
 - Run -> External Tools -> External Tools Configurations
 - Double-click "Program" to create a new Program Launch Configuration
 	Name = nxtOSEK RXE Flash
 	Location = B:\Tools\Cygwin\bin\bash.exe		(or whatever the path is)
 	Working Directory = ${project_loc}
 	Arguments = ./rxeflash.sh
 - Click the "Build" tab, check "Build before launch" and "The project with the selected resource"
 - Repeat 2 more times for "nxtOSEK BIOS Flash" (./biosflash.sh) and "nxtOSEK App Flash" (./appflash.sh).

Functions/methods not found (lots of red squiggles in editor):
 - Project -> Properties -> C/C++ Build -> Paths and Symbols
 - Click "Import Settings"
 - Click "Browse"
 - Select nxtOSEK2.18/projects/nxtOSEK-Paths-Configuration.xml
 - Click "Finish"
 - Rebuild project

Various fields undefined (red squiggles under OSEK data types, etc)
 - Right click project -> Index -> Rebuild
 - Rebuild project
 
 
