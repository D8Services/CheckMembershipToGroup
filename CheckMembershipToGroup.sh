#!/bin/bash


	###############################################################
	#	Copyright (c) 2020, D8 Services Ltd.  All rights reserved.  
	#											
	#	
	#	THIS SOFTWARE IS PROVIDED BY D8 SERVICES LTD. "AS IS" AND ANY
	#	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
	#	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	#	DISCLAIMED. IN NO EVENT SHALL D8 SERVICES LTD. BE LIABLE FOR ANY
	#	DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
	#	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	#	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
	#	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	#	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	#	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
	#
	#
	###############################################################
	#
# Script to check a jamf server for computer membership
# useful if you need to check if a computer is in a 
# smart group indicating FileVault 2 has a valid recovery key.
# The URL remediate can then be given as an option to the user

# Usage of parameters
# sh CheckMembershipToGroup.sh 1 2 3 4 5 6 7 8 9 10 11
	# 1.MountPoint> 	from Jamf
	# 2.ComputerName 	from Jamf
	# 3.UserName 		from Jamf
	# 4.Salted apiUserName
	# 5.Salted apiPassword
	# 6.Message Subject Good
	# 7.Message Good
	# 8.Message Subject Bad
	# 9.Message Bad
	# 10.RemediationURL
	# 11. Group ID Number

version="1.0"
author="Tomos Tyler"
scriptName=$(basename "${0}")

##### Hardcoded Values - will by pass Parameters #####
# Parameter 6
theTitleGood="Success. Mac is in Group"
theMessageGood="This mac is in the group"
theTitleBad="Failed. Mac is NOT in Group"
theMessageBad="This mac is NOT in the group, open remediantion page?"
theURL="https://www.apple.com"
groupID="2000"

## Function Decrypt Strings
function DecryptString() {
	# Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${2}" -k "${3}"
}

apiUser=$(DecryptString "${4}" "d278225b2cf07d19" "30aa6c4b854a14f00414c644")
apiPass=$(DecryptString "${5}" "bf7939b07dde0603" "affa996ddcd29a39d366852b")

# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 4 > 11 AND, IF SO, ASSIGN TO "USERNAME"
if [ "${6}" != "" ] && [ "${theTitleGood}" == "" ];then
	theTitleGood="${6}"
fi
if [ "${7}" != "" ] && [ "${theMessageGood}" == "" ];then
	theMessageGood="${7}"
fi
if [ "${8}" != "" ] && [ "${theTitleBad}" == "" ];then
	theTitleBad="${8}"
fi
if [ "${9}" != "" ] && [ "${theMessageBad}" == "" ];then
	theMessageBad="${9}"
fi
if [ "${10}" != "" ] && [ "${theURL}" == "" ];then
	theURL="${10}"
fi
if [ "${11}" != "" ] && [ "${groupID}" == "" ];then
	groupID="${11}"
fi

if [[ -z "${apiUser}" ]] || [[ -z "${apiPass}" ]] || [[ -z "${theTitleGood}" ]] || [[ -z "${theMessageGood}" ]] || [[ -z "${theTitleBad}" ]] || [[ -z "${theMessageBad}" ]] || [[ -z "${theURL}" ]] || [[ -z "${groupID}" ]];then
	ScriptLogging "ERROR: one or more parameters were not passed from Jamf, please check your parameter use. Exiting"
	echo "ERROR: one or more parameters were not passed from Jamf, please check your parameter use. Exiting"
	exit 1
fi

serialNumber=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
jssURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
log_location="/var/log/CheckMembershipTogroup.log"

## Fuction Logging
ScriptLogging(){
DATE=`date +%Y-%m-%d\ %H:%M:%S`
LOG="$log_location"
echo "$DATE" " $1" >> $LOG
}

ScriptLogging "================================================="
ScriptLogging "Script ${scriptName} Started"
ScriptLogging "AUthor ${author} - version ${version}"
ScriptLogging "================================================="

## Check JSS Availability
jss_availability=`jamf checkJSSConnection -retry 6 | tr ' ' '\n' | tail -n1`
if [ ! $jss_availability = "available." ]; then
	ScriptLogging "ERROR: JSS Unavailable, nothing to do."
	exit 0
fi

GroupInfo=$(curl -sku "${apiUser}":"${apiPass}" -H "accept: text/xml" ${jssURL}JSSResource/computergroups/id/${groupID})
GroupName=$(echo ${GroupInfo} | xmllint --xpath '/computer_group/name/id/text()' -)
echo "Groupname is $GroupName"


if [[ "${GroupInfo}" =~ "${serialNumber}" ]];then
	echo "OK, Computer is a member"
	memberConfirmed="Yes"
	ScriptLogging "OK, Computer is a member"
	launchctl "asuser" "USER_ID" "$jamfHelper" -title "${theTitleGood}" -windowType utility -description "${theMessageGood}" -icon "/System/Library/CoreServices/ReportPanic.app/Contents/Resources/ProblemReporter.icns" -button1 "OK" -defaultButton 1 -countdown 20
else
	echo "Not a Member"
	ScriptLogging "Not a Member"
	memberConfirmed="No"
	launchctl "asuser" "USER_ID" "$jamfHelper" -title "${theTitleBad}" -windowType utility -description "${theMessageBad}" -icon "/System/Library/CoreServices/ReportPanic.app/Contents/Resources/ProblemReporter.icns" -button2 "Cancel" -button1 "Open" -defaultButton 1 -countdown 20
fi

# Open the URL if the user clicked OK
if [[ $? == "0" ]] && [[ ${memberConfirmed} == "No" ]];then
sudo -u $loggedInUser -i open "${theURL}"
fi
