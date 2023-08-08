#!/bin/bash
#set -vTx
# DESCRIPTION
# Allows you to program several YubiKeys
# in sequence with either YubiOTP seeds (Default) or 6 digit HOTP seeds.
#
#
# This script is based on Chris Streeks powershell
# Author: Juan Ignacio Quesada
#
# This script uses advancced shell programming syntax
#   Arrays
#   Advanced variable assigment
#   Ansi output with colors
#
#

# Help
Help () {
  echo Usage: $(basename $0) [OPTIONS]
  printf "\n"
  echo '  -slot2|-s2|-2 - YubiKeys will be programmed in their second slot rather than the default slot 1.'

  echo '  --hotp|-H - YubiKeys will be programmed with HOTP seeds rather than the default YubiOTP'

  echo '  --ignoreduplicates|-i - Script will not check if a YubiKey has already been programmed during the session'

  echo '  --whatif|-w - Script will not program YubiKeys and will instead write to the defined CSV file with dummy data'

  echo '  --help|-h - This help'
  printf "\n\n"
}

OS_Detector () {
  #MacOs uses system_profiler to list USB devices, while other unix use lsusb
  #Detect MacOs vs Linux
  local OS
  if [[ $(uname) == "Darwin" ]]; then
    OS=MAC
  else
    OS=Linux
  fi

  echo ${OS}

}

#####################
YubiKey_Detector () {

  #Detects yubikey is present and it is not the one we just arrProgrammed
  #Return codes:
  # -2 = Error running ykman
  # 0 = An unprogrammed Yubikey was found
  # 1 = A programmed Yubikey was found and ignoreduplicates is set to 1
  # 99 = Timeout occurred

  local -i tOUT=$1
  local OS=$2
  local lastSerial=$3

  local -i runs=0
  local -i returnCode=2
  local boolYK_Plugged=0


  (( tOUT = $tOUT * 2 ))

  #Loop until we find a YubiKey plugged in.
  #When a YK is plugged in, we get the serial number
  #Use serialnum parameter to ignore the YubiKey that was recently programmed

  while [ $boolYK_Plugged -eq 0 ] && [ $runs -lt $tOUT ]
  do
    # Prints number of Yubikeys Plugged in
    if [ $OS == MAC ]; then
      boolYK_Plugged=$(system_profiler SPUSBDataType 2>/dev/null|grep -i YubiKey|tail -1|wc -l)
    else
      boolYK_Plugged=$(lsusb|grep -i yubikey|wc -l)
    fi
    #A Yubikey was found. Now we get its serial number and store it in currentSerial variable
    if [[ boolYK_Plugged -eq 1 ]]; then
      ykmanoutput=$(${YKMAN} info 2>/dev/null)
      #ykman ran successfull so we catch both serial and device type
      if [ $? -eq 0 ]; then
        #currentSerial=$(echo $ykmanoutput|sed -E 's/.*Serial number: ([[:alnum:]]+).*$/\1/')
        currentSerial=$(${YKMAN} list -s)
        deviceType=$(echo $ykmanoutput|sed -E 's/^Device type: ([[:alnum:]].*) Serial.*$/\1/')
        if [[ $lastSerial == $currentSerial ]]; then
          if [[ $ignoreduplicates -eq 1 ]]; then
            returnCode=1
          else
            boolYK_Plugged=0
          fi
        else
          returnCode=0
        fi
      else
        echo Error running $YKMAN
        returnCode="-2"
      fi
    fi

    #Count number of runs to timeout eventually
    (( runs++ ))
    #To avoid having this process go too wild, let sleep for a bit before looking for a YubiKey again
    sleep .5
  done
  if [[ $runs -eq $tOUT ]]; then
    returnCode=99
  fi

  #Returns multiple variables
  echo "$returnCode $currentSerial $deviceType"
}

Redraw_GUI () {

  local -i numProgrammedYubiKeys=$1
  local currentSerial=$2
  local -i maxYubiKey=$3
  local deviceType="$4 $5 $6"
  local -i i currentTray
  local -ir TotalTray=50

  #Calculating the number of trays configured thus far
  # To do rounding up in truncating arithmetic,
  # simply add (denom-1) to the numerator
  (( currentTray = ($numProgrammedYubiKeys + ( $TotalTray - 1 )) / $TotalTray ))

  clear
  echo -e "\033[36m Batch Yubikey Configuration Tool \033[00m"
  if [[ $boolsetaccesscode -eq 1 ]]; then
    echo -e "Access Code:\033[36m Set to Serial\033[00m || YubiKeys Configured:\033[36m $numProgrammedYubiKeys\033[00m || Number of Trays Configured:\033[36m $currentTray\033[00m"
  else
    echo -e "Access Code:\033[36m None\033[00m || YubiKeys Configured:\033[36m $numProgrammedYubiKeys\033[00m || Number of Trays Configured:\033[36m $currentTray\033[00m"
  fi

  #Each tray hold up to 50 keys, so we use the division rest for the current tray
  (( numKeysInGUI_Tray = $numProgrammedYubiKeys % $TotalTray ))
  #We are going to use this next var to calculate number of empty rows
  numExtraLines=$numProgrammedYubiKeys

  #This switch case writes the total number of programmed yubikeys in this tray as a CLI GUI
  #However, it is an exact representation of the number and not the tray, so we use $numextralines to give us those extra lines
  while [[ $numKeysInGUI_Tray -gt 0 ]]
  do
    case $numKeysInGUI_Tray in
      0) echo -e "|-||-||-||-||-||-||-||-||-||-|"
         ;;
      1) echo -e "|\033[32mY\033[00m||-||-||-||-||-||-||-||-||-|"
         ;;
      2) echo -e "|\033[32mY\033[00m||\033[32mY\033[00m||-||-||-||-||-||-||-||-|"
         ;;
      3) echo -e "|\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||-||-||-||-||-||-||-|"
         ;;
      4) echo -e "|\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||-||-||-||-||-||-|"
         ;;
      5) echo -e "|\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||-||-||-||-||-|"
         ;;
      6) echo -e "|\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||-||-||-||-|"
         ;;
      7) echo -e "|\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||-||-||-|"
         ;;
      8) echo -e "|\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||-||-|"
         ;;
      9) echo -e "|\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||-|"
         ;;
      10) echo -e "|\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m|"
         ;;
       *) echo -e "|\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m||\033[32mY\033[00m|"
         ;;
    esac
    (( numKeysInGUI_Tray = $numKeysInGUI_Tray - 10 ))
  done

  #Again, as the above loop gives us an extra representation of the YubiKeys in the tray,
  #to represent the empty lines remaining in the tray, we do a little bit of math and use a loop.
  (( numExtraLines = ($numExtraLines + (10 - 1)) / 10 ))
  (( numExtraLines = 5 - $numExtraLines ))
  for (( i=0; i < $numExtraLines; i++ ))
  do
    echo -e "|\033[32m-\033[00m||\033[32m-\033[00m||\033[32m-\033[00m||\033[32m-\033[00m||\033[32m-\033[00m||\033[32m-\033[00m||\033[32m-\033[00m||\033[32m-\033[00m||\033[32m-\033[00m||\033[32m-\033[00m|"
  done
  echo -e "Device: \033[36m $deviceType\033[00m # Serial: \033[36m$currentSerial\033[00m programmed successfully"

}

Program_YubiKey () {

  #Program_YubiKey (serialnum ignoreduplicates WHATIF SlotToProgram boolsetaccesscode pathToCSV HOTP pathToHOTPAccessCodeCSV)
  #Returns diffent codes depending on the result
  #Return Code table
  # 0 = All good
  # 1 = Key programmed but access code could not be set
  # -2 = Error running ykman info
  # 5 = Already programmed key
  # 90 = Error writing seed file
  # 91 = Error writing HOTP Access code file
  # 101 = Error programming HOTP
  # 102 = Error programming YubiOTP

  #Assign parameters to local variables
  #It is better to work with local vars instead of global
  local serialnum=$1
  local ignoreduplicates=$2
  local WHATIF=$3
  local SlotToProgram=$4
  local boolsetaccesscode=$5
  local pathToCSV=$6
  local HOTP=$7
  local pathToHOTPAccessCodeCSV=$8

  local -i currentTray=0
  local -a args=()
  local -i RC

  # Gets Serial Number
  #typeset -i serialnum=$(printf " %b" $ykmanoutput|sed '/Serial number/!d; s/Serial number: \(.*$\)/\1/')
  # Gets Device Type
  #deviceType=$(printf " %b" $ykmanoutput|sed '/Device type/!d; s/Device type: \(.*$\)/\1/')

  #Setting Access Code in case we need it
  #Padding the serial number with 0s to align with access code requirements
  if [[ $boolsetaccesscode -eq 1 ]]; then
    accesscode=$(printf "%012d" $serialnum)
  else
    accesscode="000000000000"
  fi
  #Unless the -ignoreduplicates flag is set, if we have already programmed this key we either need to keep looking
  #(if it is the most recently programmed key) or tell the user that they need to insert a new YubiKey
  #arrProgrammedKeys is a GLOBAL variable to make things easier
  if [[ ${arrProgrammedKeys[@]} =~ "$serialnum" ]] && [[ $ignoreduplicates -eq 0 ]]; then
    echo Duplicate Warning:
    echo 'This YubiKey (#'$serialnum') has already been configured during this session'
    echo -e "\033[5Please insert the first YubiKey and press [Enter] to begin\033[0m\c"; read
    RC=5
  else
    if [[ $WHATIF -eq 1 ]] && [[ $HOTP -eq 1 ]]; then
      echo "$serialnum,722E6953707804F682654C69726C328636C9085D" >>$pathToCSV
      RC=0
    elif [ $WHATIF -eq 1 ]; then
      #Print timestamp
      timestamp=$(date "+%Y-%m-%d%H:%M:%S")
      #we're writing bogus information to the CSV file since the script is running in simulation mode
      echo "$serialnum,ccccccWHATIF,000000000001,00000000000000000000000000000001,000000000000,$timestamp," >>$pathToCSV
      RC=0
    elif [[ $HOTP -eq 1 ]]; then
      #Creating a 20 bytes Base32 string
      secretkey=$(LC_ALL=C tr -dc 'A-Z2-7' </dev/urandom | head -c 20; echo)
      args=( "otp" "hotp" "-d6" "-f" "$SlotToProgram" "$secretkey")
      #Now, configure the yubikey with OTP values

      ${YKMAN} ${args[@]} 2>/dev/null
      #HOTP programming does not produce an output when successfull so we process RC the old way
      if [[ $? -ne 0 ]]; then
        echo Error running ${YKMAN}. Please verify key $serialnum is not protected and you have permissions
        return 101
      else
        #Feed the seeds file
        echo "$serialnum,$secretkey" >> $pathToCSV
        if [[ $? -ne 0 ]]; then
          RC=90
        fi
        #If the user also wants an access code with HOTP, we write it to the separate file they have defined.
        if [[ $boolsetaccesscode -eq 1 ]]; then
          echo "$serialnum,$accesscode" >> $pathToHOTPAccessCodeCSV
          if [[ $? -ne 0 ]]; then
            RC=91
          else
            #Add this serial number to our array so we can track which YubiKeys have been programmed this session
            arrProgrammedKeys+=( $serialnum )
            RC=0
          fi
        fi
      fi
    else
      #Arguments for YubiOTP
      args=( "otp" "yubiotp" "-SgGf" $SlotToProgram )
      #Now, configure the yubikey with OTP values
      #ykmanoutput=$(${YKMAN} ${args[@]} 2>&1|sed 's/\(^.*$\)/\1\\n/g')
      ykmanoutput=$(${YKMAN} ${args[@]} 2>&1)
      if [[ $? -ne 0 ]]; then
        echo Error running ${YKMAN}. Please verify key $serialnum is not protected and you have permissions
        return 101
      else
        #Capture values into variables. We use sed to parse ykman output
        currentpublicid=$(echo $ykmanoutput|sed -E 's/.*public ID: ([[:alnum:]]+) Using.*$/\1/')
        currentprivateID=$(echo $ykmanoutput|sed -E 's/.*private ID: ([[:alnum:]]+) Using.*$/\1/')
        currentsecret=$(echo $ykmanoutput|sed -E 's/.*secret key: ([[:alnum:]]+)/\1/')
        #Write to the CSV file using the YubiOTP CSV format, writing the access code to the file if set to configure the YubiKey with one.
        #When boolsetaccesscode = 0, $accesscode will have all 0 in it
        timestamp=$(date "+%Y-%m-%d%H:%M:%S")
        echo ${serialnum},${currentpublicid},${currentprivateID},${currentsecret},${accesscode},${timestamp} >> ${pathToCSV}
        if [[ $? -ne 0 ]]; then
          RC=90
        else
          #Add this serial number to our array so we can track which YubiKeys have been programmed this session
          arrProgrammedKeys+=( $serialnum )
          RC=0
        fi
      fi
    fi


    #Setting an access code if this was defined during initial configuration and the WhatIf parameter is not enabled
    if [[ $boolsetaccesscode == 1 ]] && [[ $WHATIF != 1 ]]; then
      args=( "otp" "settings" "-f" "-A" "$accesscode" "$SlotToProgram" )
      echo Setting Access Code for YubiKey $serialnum
      ${YKMAN} ${args[@]} 2>/dev/null
      if [[ $? -ne 0 ]];then
        RC=1
      else
        RC=0
      fi
    fi
  fi

  return $RC
}

##############
## MAIN
##############
clear

#First of all, we parse command line arguments
while [[ $# -gt 0 ]]
do
  key=$1
  case $key in
    --slot2|-s2|-2)
	    SlotToProgram=2
 	    SLOT2=1
	    shift
    ;;
    --whatif|-w)
        WHATIF=1
	      shift
      ;;
    --hotp|-H)
        HOTP=1
	      shift
	    ;;
    --ignoreduplicates|-i)
        ignoreduplicates=1
	      shift
     	;;
    --help|-h)
        Help
        exit -1
      ;;
    *)
      Help
      read -rsp $'Invalid parameter. Press [ENTER] to exit...\n'
   	  exit -1
    ;;
	esac
done

#Check OS (Mac vs Linux)
OS=$(OS_Detector)
# Will try to locate ykman binary file
YKMAN=$(which ykman)
##Test to ensure the ykman executable exists
#Verifies YKMAN value. If ykman is not found it'll prompt for location
while [[ ! -f $YKMAN ]]; do
  read -rp "Can't find $YKMAN, please enter proper path: " YKMAN
done

# Initialize default parameters
# The syntax ${var:-VALUE} assigns VALUE to $var if if was not previously defined
typeset -i SlotToProgram=${SlotToProgram:-1}
typeset -i ignoreduplicates=${ignoreduplicates:-0}
typeset -i HOTP=${HOTP:-0}
typeset -i WHATIF=${WHATIF:-0}
typeset -i SLOT2=${SLOT2:-0}

typeset -i currentSerial=0
typeset deviceType="N/A"
typeset -ri TIMEOUT=120 #Timeout in seconds
#WORKDIR defaults to current directory
WORKDIR=$(pwd)
#Something to hold our serial numbers in. Using bash arrays
arrProgrammedKeys=()


echo -e "\033[36m YubiKey Batch Configuration Tool\033[00m"
echo -e "\033[31m MAKE SURE THERE ARE NO YubiKeys PLUGGED IN \033[00m"
echo '# Step 1: Seed File'


#Asks for CSV path (defaults to $WORKDIR/seed.csv)
typeset pathToCSV
read -rp "Please, enter CSV filename with full path: (ENTER for $WORKDIR/seed.csv) "  pathToCSV
pathToCSV=${pathToCSV:-$WORKDIR/seed.csv}
#We are making sure the CSV file exists and it is empty
>$pathToCSV

echo "OK, this script will save your CSV file to: $pathToCSV"

## Quick logic to see if user wants to set an access code during programming
echo '# Step 2: Access Code:'
echo 'To prevent users from manipulating the YubiKey and adding their own OTP configuration,'
echo 'an access code equal to the serial number of the YubiKey can be set'
read -rp $'Would you like to set an access code? (Y/n): \n' ReadHost
ReadHost=${ReadHost:-Y}

if [[ $ReadHost =~ [Nn] ]]; then
  echo "OK, an access code will not be set"
  boolsetaccesscode=0
else
  echo "OK, an access code will be set"
  boolsetaccesscode=1
fi

if [[ $HOTP -eq 1 ]] && [[ $boolsetaccesscode -eq 1 ]]; then
  echo 'As you are programming HOTP seeds, these access codes must be stored in a separate file alongside their associated YubiKey serial numbers'
  read -rp "Please enter CSV filename with full path HOTP Access code (ENTER for $WORKDIR/HOTPAccessCode.csv): " pathToHOTPAccessCodeCSV
  pathToHOTPAccessCodeCSV=${pathToHOTPAccessCodeCSV:-$WORKDIR/HOTPAccessCode.csv}
  #Make sure the file exists and it is empty
  >$pathToHOTPAccessCodeCSV
  echo "OK, this script will save your CSV file for access codes to: $pathToHOTPAccessCodeCSV"
fi
echo '# Step 3: Predefine number of YubiKeys to be programmed'
read -rp $'How many YubiKeys do you want to program this time (0 Unlimited until Ctrl-C)? ' maxYubiKey
maxYubiKey=${maxYubiKey:-50000}
echo '# Step 4: Batch Programming'
if [[ $ignoreduplicates -eq 1 ]]; then
  echo "- 'Ignore Duplicates' mode enabled: Script will not alert on YubiKeys that have already been configured this session "
fi
if [ $WHATIF -eq 1 ]; then
  echo "- 'WhatIf' mode enabled: Dummy data will be written to the CSV file and YubiKeys will not be configured."
fi
if [ $HOTP -eq 1 ]; then
  echo "- 'HOTP' mode enabled: HOTP seeds will be written to the YubiKey."
fi
if [ $SlotToProgram -eq 2 ]; then
  echo "- 'Slot 2' mode enabled: YubiKeys will be configured with YubiOTP/HOTP seeds in their second slot."
fi

echo -e "\033[5mPlease insert the first YubiKey and press [Enter] to begin\033[0m\c"; read


#Begin a loop to program YubiKeys
i=0; YKD_RC=0

while [[ $i -lt $maxYubiKey ]] && [[ $YKD_RC -ne 99 ]]
do
  echo Looking for the next YubiKey...

  YKDetector=$(YubiKey_Detector $TIMEOUT $OS $lastKey)
  YKD_RC=$(echo $YKDetector|cut -f1 -d' ')
  if [[ $YKD_RC -eq 99 ]]; then
    Redraw_GUI $i $currentSerial $maxYubiKey "$deviceType"
    echo "Time out waiting for the next YubiKey... Exiting"
    returnCode=$YKD_RC
  fi
  if [[ $YKD_RC -eq -2 ]]; then
    echo "Error running $YKMAN..."
  fi

  if [[ ${YKD_RC} =~ [01] ]]; then #Yubikey found and ready to be programmed
    currentSerial=$(echo $YKDetector|cut -f2 -d ' ')
    deviceType=$(echo $YKDetector|cut -f3- -d ' ')
    Program_YubiKey $currentSerial $ignoreduplicates $WHATIF $SlotToProgram $boolsetaccesscode $pathToCSV $HOTP $pathToHOTPAccessCodeCSV
    PK_returnCode=$?

    case $PK_returnCode in
      "2")
        echo Last YubiKey programmed was ${#arrProgrammedKeys[@]}... exiting
        returnCode=$PK_returnCode
        break
        ;;
      "0")
        (( i++ ))
        #Key programmed successfully, we redraw the screen and increment counter
        Redraw_GUI $i $currentSerial $maxYubiKey "$deviceType"
        #Add the current key to an array of programmed keys
        arrProgrammedKeys+=( $currentSerial )
        lastKey=${arrProgrammedKeys[${#arrProgrammedKeys[@]}-1]}
        #echo "LAST ELEMENT ${arrProgrammedKeys[${#arrProgrammedKeys[@]}-1]}"; read
        returnCode=$PK_returnCode
        ;;
      "1")
        echo Error running $YKMAN, Access code not set for key ${currentSerial}. Continuing...
        (( i++ ))
        Redraw_GUI $i $currentSerial $maxYubiKey "$deviceType"
        arrProgrammedKeys+=( $currentSerial )
        lastKey=${arrProgrammedKeys[${#arrProgrammedKeys[@]}-1]}
        returnCodeAccessCode=1
        ;;
      "5")
        #Nothing to here as we need to keep looking
        ;;
      "90"|"91")
        echo Error writing CSV file.
        echo Last YubiKey programmed was $lastKey... exiting
        returnCode=$PK_returnCode
        break
        ;;
      "101"|"102")
        echo Last YubiKey programmed was $lastKey... exiting
        returnCode=$PK_returnCode
        break
        ;;
    esac
  fi
done
if [[ $returnCodeAccessCode -eq 1 ]]; then
  echo $(basename $0) completed but Access code could not be set for some keys
  echo Check the csv file
  returnCode=1
fi
exit $returnCode
