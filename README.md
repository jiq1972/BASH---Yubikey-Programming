
#Bash script to program yubikeys in batch

This is a Bash script that allows you to quickly batch configure large or small quantities of YubiKeys with either YubiOTP or HOTP seed values.

###Additional Features

	▪	You may choose to batch configure an access code to each YubiKey, preventing users from reprogramming the devices
	▪	You may choose which slot you'd like to batch configure.
	▪	Keep track of your progress with a nice little CLI GUI displaying a tray of YubiKeys that fills as you go
	▪	Will not let you accidentally program a YubiKey you've already programmed during a given session.
	▪	Exports to CSV already configured for easy import into Okta/Duo/etc.

##Requirements

	▪	Linux, MacOS
	▪	Installed latest version of the [YubiKey Manager] (https://www.yubico.com/products/services-software/download/yubikey-manager/)

##Security Recommendations

	▪	Given that you'll be generating OTP seed values for a large quantity of YubiKeys into a cleartext CSV file, it is is recommended that you run this script on an offline machine, taking care to delete the CSV file once it is uploaded to the platform you're using with the YubiKeys.
	▪	As a general rule of thumb, do not run bash scripts that you do not understand. Please take a look at the script if you are so inclined.

##How to Use (YubiOTP)

	1.	Ensure the YubiKey Manager is installed.
	2.	Launch Bash_Batch_YubiKey_Config.sh
	3.	Click Enter on the keyboard when prompted to select a location for the CSV file which will hold the OTP seeds.
	4.	Choose whether or not to set an access code to the YubiKeys. The access code will be set to the serial number of the YubiKeys.
	5.	Specify how many YubiKeys you intent to program (Enter 0 for unlimited)
	6.	Insert the first YubiKey to program and press the [Enter] key to begin batch programming.
	7.	When unlimited number of keys are to be programmed, simply press Control+C to finish the script. Throughout the session, the script will simply append to the CSV file that you defined.
	8.	Upload the CSV file to the desired platform, delete the CSV file from your machine.

##How to Use (HOTP)

	1.	Ensure the YubiKey Manager is installed.
	2.	Launch the .sh file with the hotp or h  flag attached. YK-Programming.sh --hotp or YK-Programming.sh -h
	3.	Click Enter on the keyboard when prompted to select a location for the CSV file which will hold the OTP seeds.
	4.	Choose whether or not to set an access code to the YubiKeys. The access code will be set to the serial number of the YubiKeys.
	5.	Specify how many YubiKeys you intent to program (Enter 0 for unlimited)
	6.	If you choose to set an access code, you will be additionally prompted to set a location to store those access codes.
	7.	Insert the first YubiKey to program and press the [Enter] key to begin batch programming.
	8.	When unlimited number of keys are to be programmed, simply press Control+C to finish the script. Throughout the session, the script will simply append to the CSV file that you defined.
	9.	Upload the CSV file to the desired platform, delete the CSV file from your machine.


##Optional Flags

--help - Displays help

--slot2 | -s2 | -2 - YubiKeys will be programmed in their second slot rather than the default slot 1.

--hotp | -h - YubiKeys will be programmed with HOTP seeds rather than the default YubiOTP

--ignoreduplicates | -i - Script will not check if a YubiKey has already been programmed during the session

--whatif | -w - Script will not program YubiKeys and will instead write to the defined CSV file with dummy data
