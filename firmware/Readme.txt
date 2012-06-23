Readme
==================
The script is a simple tool to process FIRMWARE IMPORT PROCEDURE automatically

Installation Home
	/mot/proj/wibb_bts/daily/firmware

Upload dir
	/mot/proj/wibb_bts/daily/firmware/upload
Working dir
	/mot/proj/wibb_bts/daily/firmware/wimax
	
Scripts
	firmware.sh firmware_import.sh
	
Configuration
	firmware.conf r4.0.firmware|...
	
Usage
	./firmware.sh r4.0.firmware [validate|init|unpack|import|all]
	
Pre-requirement
	- Download and upload Firmware Release Package to [Upload dir], it should follow the package pattern, looks like this
		[Upload dir]
			|-[FIRMWARE_WIBBFW_R4.0.1_REL-0.5.0]
				|- Wi4_RFH_pkg.bin
				|- [2x]
				|	|- Wi4_2s_DSP_pkg.bin
				|	|- Wi4_2s_MFPGA_pkg.bin
				|	|- physap_N401_pkg.zip
				|- [4x]
					|- Wi4_4s_DSP_pkg.bin
					|- Wi4_4s_MFPGA_pkg.bin
					|- physap4x_N401_pkg.zip
	
	- Configure r4.0.firmware(any name you want), need includes 2 variables
		FIRMWARE_RELEASE=WIBBFW_R4.0.1_REL-0.5.0
		FIRMWARE_VIEW=40firmware_delivery
		#package name pattern
		FIRMWARE_PKG_PATTERN=N401

How it works?
	this tool can be used in two strategies, one is "step-by-step" and another is "all-in-one"
	[step-by-step]
		./firmware.sh r4.0.firmware validate
		./firmware.sh r4.0.firmware init
		./firmware.sh r4.0.firmware unpack
		./firmware.sh r4.0.firmware import
	[all-in-one]
		./firmware.sh r4.0.firmware all
		
Notes
	- We recomment you use [step-by-step] before you are family with the tool.
	- Validate,init,unpack,import should be invoked one by one, you cannot direct go to unpack without init
	otherwise you may get script error.
	- Import a Firmware Release Package twice is not allowed.
	
Contact
	Any issues you found please contact with cwnj74@motorola.com
	

	
	
		
	