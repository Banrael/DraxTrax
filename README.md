# DraxTrax
Powershell scripts for pulling quest completion data from Census. Intended for tracking progress of characters on Weekly quests, but is extensible to track other quests.

# Setup
1. Download / copy the contents of the following files:
   * QuestTrackerV13_Shared.ps1
   * QuestList.csv
   * CharacterList.csv
2. Gather a list of characters you want to track quest status for, and place them in CharacterList.csv. 
   * I recommend creating a group of characters on u.eq2wire.com, viewing the "Gear Report", and copying the list of character IDs from the URL - example:
     https://u.eq2wire.com/gearreport/show/character/433793647390,433792610756
   * Note that for your CharacterList.csv, you can just fill it in with "CharacterId" followed by one Character Identifier per row. The tool will take care of looking up the name of the character.<br>
     CharacterId<br>
     433793647390<br>
     433792610756<br>

# Usage
1. Go to Start -> type in PowerShell and choose "Windows Powershell"
2. Navigate to the folder you saved your copy of the scripts into.
3. Run: PowerShell.exe -ExecutionPolicy Bypass -File .\QuestTrackerV13_Shared.ps1

Once this completes, you should see a Grid View that gives you the current status for the selected characters and quests.

Note:
* If you want to avoid extraneous lookups to Census, when you run the script the first time you should pass in the additional "-UpdateCharacterFile" switch, like the below. This will write back an updated character file that should contain the names of the characters you are looking up so the names don't need to be looked up again.
  * Run: PowerShell.exe -ExecutionPolicy Bypass -File .\QuestTrackerV13_Shared.ps1 -UpdateCharacterFile
  
