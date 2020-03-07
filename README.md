## CheckMembershipToGroup
Script to check a Jamf PRO server for computer membership useful if you need to check if a computer is in a  smart group indicating FileVault 2 has a valid recovery key. The URL to remediate can then be given as an option to the user

### Salted API Credentials
Credentials are salted for use in this script, feel free to read the following for more information

https://github.com/jamf/Encrypted-Script-Parameters

### Usage of parameters
sh CheckMembershipToGroup.sh 1 2 3 4 5 6 7 8 9 10 11
	-.MountPoint> 	from Jamf
	-.ComputerName 	from Jamf
	-.UserName 		from Jamf
	-.Salted apiUserName
	-.Salted apiPassword
	-.Message Subject Good
	-.Message Good
	-.Message Subject Bad
	-.Message Bad
	-.RemediationURL
	-. Group ID Number
  
### Example Values
theTitleGood="Success. Mac is in Group"

theMessageGood="This mac is in the group"

theTitleBad="Failed. Mac is NOT in Group"

theMessageBad="This mac is NOT in the group, open remediantion page?"

theURL="https://www.apple.com"

groupID="2000
