#############################
Read me for StorageExtend.ps1
#############################


Purpose:
Simplify storage extensions for either a single server or multiple.

How to use:
1. Launch script (need to have an admin powershell window thats signed into Vsphers.)
2. Read options and select the one that you need.
	- Option 1: Allows you to select one specific server and 1 specific drive to extend automatically.
	- Option 2: Prompts the user to select a saved .txt file for a list of servers and then select one drive letter to extend on all.
		EX: C:\temp\serverlist.txt has 10 servers and we need to extend C:\ on each one.
	- Option 3: Allows you to select one Specific server and then it will check each drive on the machine for any drive with available space.
3. Each option should provide you a confirmation output to ensure the sizes are correct.


Upcoming additions:
Precheck if there are any new drives
Initilize and format new drives, including what letter they need to be set to.


Please get with Dalton D. if you have any questions.