## CheckMembershipToGroup
Script to check a Jamf PRO server for computer membership useful if you need to check if a computer is in a  smart group indicating FileVault 2 has a valid recovery key. The URL to remediate can then be given as an option to the user

### Salted API Credentials
Credentials are salted for use in this script, feel free to read the following for more information

https://github.com/jamf/Encrypted-Script-Parameters

### Usage of parameters
sh CheckMembershipToGroup.sh 1 2 3 4 5 6 7 8 9 10 11
1. MountPoint> 	from Jamf
2. ComputerName 	from Jamf
3. UserName 		from Jamf
4. Salted apiUserName
5. Salted apiPassword
6. Message Subject Good
7. Message Good
8. Message Subject Bad
9. Message Bad
10. RemediationURL
11. Group ID Number
  
### Example Values
- theTitleGood="Success. Mac is in Group"
- theMessageGood="This mac is in the group"
- theTitleBad="Failed. Mac is NOT in Group"
- theMessageBad="This mac is NOT in the group, open remediantion page?"
- theURL="jamfselfservice://content?entity=policy&id=xx&action=view"
- groupID="2000

##### Note on theURL value
Do not forget to set theURL to your Self Service remediation page or remediation web URL, mine was
jamfselfservice://content?entity=policy&id=62&action=view
you may have a separate web page you want to direct users to with a remediation

### Full Example
As mentioned I wrote this with FileVault 2 recovery keys in mind. So If wanted users who enroled an existing configured Mac to be tested if FileVault 2 were enabled. If not, then two items
1. Config profile with Escrow of Key configured to Jamf PRO Scoped to "All Computers"
2. Policy Setup to enable FileVault 2 at next login, Policy set to run on "Enrollment Complete" Trigger, target Macs without FileVault 2 enabled.

But what if the device has FileVault enabled. We need to get the item back into Jamf. So after enrolment the user can open Self Service and check if their machine if configured with a Recovery Key via policy, leveraging this script.

Configuration profile
Security and Privacy payload configured to Escrow the Recovery Key to Jamf PRO Scope all Computers

**Policy**
1. Policy set to run another script by Jamf to reissue the FileVault key.
  - In the Self Service pane of this policy copy the View URL and this will be the parameter "__theURL__".
  - Scope: All Computers
  - Frequency: Once Per Day
  - Trigger: Self Service
  - Payload:  Script ReissueKey.sh
    - Files and Process Execute Command "**jamf policy**"
  - https://github.com/jamf/FileVault2_Scripts/blob/master/reissueKey.sh
2. Smart Group
  To Check if a FileVault 2 Individual Recovery Key is Valid, ID of this Smart Group is the parameter "__groupID__"
3. Policy to run the CheckMemebershipToGroup.sh Script.
- scope:      All Computers
- Frequency:  Ongoing but your choice  
- Trigger:    Self Service
- Payload:    Script CheckMemebershipToGroup.sh
  - Parameters:
    - P1...3 Managed by Jamf
    - P4. QWERTYUIOP1234567890sdfghjkl
    - P5. QWERTYUIOP1234567890ZXCVBNMASDFGHJKL
    - P6. Success. Mac is in Group
    - P7. This mac is in the group
    - P8. Failed. Mac is NOT in Group
    - P9. This mac is NOT in the group, open remediantion page?
    - P10. jamfselfservice://content?entity=policy&id=62&action=view
    - P11. 62

