# DraxTrax ShinyCheck
Powershell scripts for pulling what shinies a set of characters need from Census, focused on Renewal of Ro shinies.<br>
Many thanks to Feldon / u.eq2wire.com for providing the shiny details needed to make this tool possible!

![image](https://user-images.githubusercontent.com/47707771/224463217-cf95e12d-84a1-4786-9054-16cda789595b.png)

# Setup
1. Download / copy the contents of the following files - you can right-click and save-as the below files, making sure to save the ShinyList and CharacterList as .csv files:
   * GetNeededShinyList.ps1 - https://raw.githubusercontent.com/Banrael/DraxTrax/main/ShinyCheck/GetNeededShinyList.ps1
   * ShinyList.csv - https://raw.githubusercontent.com/Banrael/DraxTrax/main/ShinyCheck/ShinyList.csv
   * CharacterList.csv - https://raw.githubusercontent.com/Banrael/DraxTrax/main/ShinyCheck/CharacterList.csv
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
3. Run: PowerShell.exe -ExecutionPolicy Bypass -File .\GetNeededShinyList.ps1

Once this completes, you should see a Grid View that gives you the current status for the selected characters and what shinies they still need.

Note:
* If you want to avoid extraneous lookups to Census, when you run the script the first time you should pass in the additional "-UpdateCharacterFile" switch, like the below. This will write back an updated character file that should contain the names of the characters you are looking up so the names don't need to be looked up again.
  * Run: PowerShell.exe -ExecutionPolicy Bypass -File .\GetNeededShinyList.ps1 -UpdateCharacterFile
