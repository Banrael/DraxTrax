Add-Type @"
public class CharacterData {
    public string Name;
    public string Identifier;
    }
"@

Add-Type @"
public class Quest {
    public string Name;
    public string Crc;
    }
"@

# If you have gotten a ServiceId from https://census.daybreakgames.com/#devSignup, place it here.
# This should avoid throttling issues.
$serviceId = "";

# Create a new list of custom objects
$characterList = New-Object System.Collections.Generic.List[CharacterData]

#CharIds:
# Put in characters below as 
# characterId = "Character Name you want to display"
$characterDict = 
@{
433793647390 = "Halls_of_Fate.Draks";
}

$questCheckDict = 
@{
[long] 3986379077 = [Quest] @{Name="It's Alright, Hizite [Heroic I]";Crc=3986379077}
[long] 4281269931 = [Quest] @{Name="It's Alright, Hizite [Heroic II]";Crc=4281269931}
[long] 1955725567 = [Quest] @{Name="Hang Tight, Hizite [Heroic I]";Crc=1955725567}
[long] 1713876753 = [Quest] @{Name="Hang Tight, Hizite [Heroic II]";Crc=1713876753}
#[long] 3780857602 = [Quest] @{Name="It's Alright, Hizite [Solo]";Crc=3780857602}
#[long] 2018647736 = [Quest] @{Name="Hang Tight, Hizite [Solo]";Crc=2018647736}
#[long] 2181356442 = [Quest] @{Name="Renewal of Ro I [Raid] Raj'dur";Crc=2181356442}
#[long] 453872160 = [Quest] @{Name="Renewal of Ro II [Raid] Sandstone";Crc=453872160}
}

function Update-Character-Status {
    param(
        [CharacterData] $Character,
        [long] $QuestId,
        [string] $Status
    )

    Write-Host "Quest: $($questCheckDict[$QuestId].Name)"
    $columnName = $questCheckDict[$QuestId].Name -replace "[ ',\[\]]", "_"
    Write-Host "Column: $columnName"
    $Character | Add-Member -MemberType NoteProperty -Name $columnName -Value $Status
}

$numCharacters = $characterDict.Keys.Count
$characterNumber = 0
foreach ($characterId in $characterDict.Keys) 
{ 
    $characterNumber++;
    Write-Progress -Activity "Looking up characters..." -Status "On $characterNumber of $numCharacters"
    $completedUri = "http://census.daybreakgames.com/$serviceId/json/get/eq2/character_misc/"+$characterId+"?c:show=completed_quest_list"
    $completedQuests = Invoke-RestMethod -Uri $completedUri -Method Get
    $activeUri = "http://census.daybreakgames.com/$serviceId/json/get/eq2/character_misc/"+$characterId+"?c:show=quest_list&c:resolve=quests"
    $activeQuests = Invoke-RestMethod -Uri $activeUri -Method Get

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
        Write-Output "$($questCheckDict[$questId].Name) (Quest CRC: $questId)";
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

