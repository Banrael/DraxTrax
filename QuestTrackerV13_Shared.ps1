param(
    [string] $QuestFile = ".\QuestList.csv",
    [string] $CharacterFile = ".\CharacterList.csv",
    [switch] $UpdateCharacterFile
)

Add-Type @"
public class CharacterData {
    public string Name;
    public string Identifier;
    }
"@

# If you have gotten a ServiceId from https://census.daybreakgames.com/#devSignup, place it here.
# This should avoid throttling issues.
$serviceId = "";

# Create a new list of custom objects
$characterList = New-Object System.Collections.Generic.List[CharacterData]

$characterDict = @{}
$questCheckDict = @{}
 
$characterInputData = Get-Content $CharacterFile |
    Select-String '^[^#]' | 
    ConvertFrom-Csv |
    Select-Object @{Name='CharacterId'; Expression={[long]$_.CharacterId}}, CharacterName

foreach($inputChar in $characterInputData)
{
    $characterDict.Add($inputChar.CharacterId, $inputChar.CharacterName);
}

$questInputData = Get-Content $QuestFile |
    Select-String '^[^#]' | 
    ConvertFrom-Csv |
    Select-Object @{Name='QuestCRC'; Expression={[long]$_.QuestCRC}}, QuestName

foreach($inputQuest in $questInputData)
{
    $questCheckDict.Add($inputQuest.QuestCRC, $inputQuest.QuestName);
}

function Update-Character-Status {
    param(
        [CharacterData] $Character,
        [long] $QuestId,
        [string] $Status
    )

    Write-Host "Quest: $($questCheckDict[$QuestId])"
    $columnName = $questCheckDict[$QuestId] -replace "[ ',\[\]]", "_"
    Write-Host "Column: $columnName"
    $Character | Add-Member -MemberType NoteProperty -Name $columnName -Value $Status
}

$numCharacters = $characterDict.Keys.Count
$characterNumber = 0

foreach ($characterId in $($characterDict.Keys)) 
{ 
    $characterNumber++;

    Write-Progress -Activity "Looking up characters..." -Status "On $characterNumber of $numCharacters"
    $completedUri = "http://census.daybreakgames.com/$serviceId/json/get/eq2/character_misc/"+$characterId+"?c:show=completed_quest_list"
    $completedQuests = Invoke-RestMethod -Uri $completedUri -Method Get
    $activeUri = "http://census.daybreakgames.com/$serviceId/json/get/eq2/character_misc/"+$characterId+"?c:show=quest_list&c:resolve=quests"
    $activeQuests = Invoke-RestMethod -Uri $activeUri -Method Get

    if ([string]::IsNullOrEmpty($characterDict[$characterId]))
    {
        $characterDetailsUri = "http://census.daybreakgames.com/$serviceId/json/get/eq2/character/"+$characterId+"?c:show=name,displayname"
        $characterDetails = Invoke-RestMethod -Uri $characterDetailsUri -Method Get
        $characterDict[$characterId] = $characterDetails.character_list.displayname
    }

    Write-Output "=============================================================="
    Write-Output "$characterId    :    $($characterDict[$characterId])"
    Write-Output "=============================================================="

    $character = New-Object CharacterData
    $character.Name = $characterDict[$characterId];
    $character.Identifier = "$($characterId)";

    foreach($questId in $questCheckDict.Keys)
    {
        $state = 0;
        $column = 1;
        Write-Output "$($questCheckDict[$questId]) (Quest CRC: $questId)";
        $questNode = $completedQuests.character_misc_list.completed_quest_list | Where-Object {$_.crc -eq $questId}
        if ($questNode -ne $null) 
        {
            $state = 1;
            Write-Output "Completed: $($questNode.completion_date)"
            
            Update-Character-Status -Character $character -QuestId $questId -Status "Completed: $($questNode.completion_date)"
        }

        $questNode = $activeQuests.character_misc_list.quest_list | Where-Object {$_.crc -eq $questId}
        if ($questNode -ne $null) {
            $state = 2;
            Write-Output "Active"
            Write-Output $questNode.requiredItem_list.progress_text;

            $requirement_list = $questNode.requiredItem_list.progress_text -join ", "
            $status = "Active: $($requirement_list)" 

            Update-Character-Status -Character $character -QuestId $questId -Status $status
        }

        if ($state -eq 0)
        {
            Write-Output "Not picked up"

            Update-Character-Status -Character $character -QuestId $questId -Status "Not picked up"
        }


        Write-Output "";
        $row++;
    }
    Write-Output "";
    Write-Output "";
    $characterList.Add($character);
}

$fixedColumnArray = @("Identifier","Name")
$questColumnArray = $characterList[0] | Get-Member -MemberType NoteProperty | Select-Object Name | Sort-Object -Property Name | ForEach-Object { $_.Name.ToString() }

$sortedColumnArray = $fixedColumnArray + $questColumnArray;

$characterList | Select-Object -Property $sortedColumnArray | Out-GridView -Title "Quest Status" 

if($UpdateCharacterFile) 
{
    $characterList | Select-Object @{Name='CharacterId'; Expression={[long]$_.Identifier}}, @{Name='CharacterName'; Expression={[string]$_.Name}} | Export-Csv -Path $CharacterFile -NoTypeInformation
}