# DraxTrax AdornCheck
Powershell script for pulling data from Census. Intended for checking for old adornments to help folks upgrade them.

![image](https://user-images.githubusercontent.com/47707771/223884407-e26358ac-7594-400a-aa0a-a8900fe88093.png)

# Setup
1. Download / copy the contents of the following files - you can right-click and save-as the below files, making sure to save the QuestList and CharacterList as .csv files:
   * AdornCheck_Shared.ps1 - https://raw.githubusercontent.com/Banrael/DraxTrax/main/AdornCheck/AdornCheck_Shared.ps1
   * AdornmentStateList.csv - https://raw.githubusercontent.com/Banrael/DraxTrax/main/AdornCheck/AdornmentStateList.csv
   * CharacterList.csv - https://raw.githubusercontent.com/Banrael/DraxTrax/main/AdornCheck/CharacterList.csv
2. Gather a list of characters you want to check adornment status for, and place them in CharacterList.csv. 
   * I recommend creating a group of characters on u.eq2wire.com, viewing the "Gear Report", and copying the list of character IDs from the URL - example:
     https://u.eq2wire.com/gearreport/show/character/433793647390,433792610756
   * Note that for your CharacterList.csv, you can just fill it in with "CharacterId" followed by one Character Identifier per row. The tool will take care of looking up the name of the character.<br>
     CharacterId<br>
     433793647390<br>
     433792610756<br>

# Usage
1. Go to Start -> type in PowerShell and choose "Windows Powershell"
2. Navigate to the folder you saved your copy of the scripts into.
3. Run: PowerShell.exe -ExecutionPolicy Bypass -File .\AdornCheck_Shared.ps1

Once this completes, you should see a Grid View that gives you the current status for the selected characters and adornments.

Note:
* If you want to avoid extraneous lookups to Census, when you run the script the first time you should pass in the additional "-UpdateCharacterFile" switch, like the below. This will write back an updated character file that should contain the names of the characters you are looking up so the names don't need to be looked up again.
  * Run: PowerShell.exe -ExecutionPolicy Bypass -File .\AdornCheck_Shared.ps1 -UpdateCharacterFile
* If you want to only get back adornments that have recommendations on them, you should pass in the additional "-OnlyActionableAdorns" switch, like the below:
  * Run: PowerShell.exe -ExecutionPolicy Bypass -File .\AdornCheck_Shared.ps1 -OnlyActionableAdorns
