#Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

param(
    [string] $CharacterFile = ".\CharacterList.csv",
    [string] $ShinyFile = ".\ShinyList.csv",
    [switch] $UpdateCharacterFile 
)

Add-Type @"
public class ShinyData {
    public string CollectionId;
    public string CollectionName;
    public string CollectionMemberId;
    public string CollectionMemberName;
    }
"@

Add-Type @"
public class CharacterShinyData {
    public string Name;
    public string Identifier;
    public string CollectionId;
    public string CollectionName;
    public string CollectionMemberId;
    public string CollectionMemberName;
    public string State;
    }
"@

# If you have gotten a ServiceId from https://census.daybreakgames.com/#devSignup, place it here.
# This should avoid throttling issues.
$serviceId = "s:DraxTraxPublic";

# Create a new list of custom objects
$characterShinyList = New-Object System.Collections.Generic.List[CharacterShinyData]

$characterDict = @{}

$characterInputData = Get-Content $CharacterFile |
    Select-String '^[^#]' | 
    ConvertFrom-Csv |
    Select-Object @{Name='CharacterId'; Expression={[long]$_.CharacterId}}, CharacterName

foreach($inputChar in $characterInputData)
{
    $characterDict.Add($inputChar.CharacterId, $inputChar.CharacterName);
}

$shinyData = @{}

$shinyInputData = Get-Content $ShinyFile |
    Select-String '^[^#]' | 
    ConvertFrom-Csv

foreach($inputShiny in $shinyInputData)
{
    $shinyData.Add($inputShiny.CollectionMemberId, $inputShiny)
}

$numCharacters = $characterDict.Keys.Count
$characterNumber = 0

foreach ($characterId in $($characterDict.Keys)) 
{ 
    $characterNumber++;

    Write-Progress -Activity "Looking up characters..." -Status "On $characterNumber of $numCharacters"

    $shinyList = (Invoke-RestMethod -Uri "http://census.daybreakgames.com/$serviceId/xml/get/eq2/character_misc/$($characterId)?c:show=collection_list" -Method Get)

    if ([string]::IsNullOrEmpty($characterDict[$characterId]))
    {
        $characterDetailsUri = "http://census.daybreakgames.com/$serviceId/json/get/eq2/character/"+$characterId+"?c:show=name,displayname"
        $characterDetails = Invoke-RestMethod -Uri $characterDetailsUri -Method Get
        $characterDict[$characterId] = $characterDetails.character_list.displayname
    }

    Write-Output "=============================================================="
    Write-Output "$characterId    :    $($characterDict[$characterId])"
    Write-Output "=============================================================="

    $allTheShinies = New-Object "System.Collections.Generic.Dictionary[[string],[CharacterShinyData]]"

    # Populate the list of shinies for this character / all the shinies they should need.
    foreach($shiny in $($shinyData.Keys))
    {
        $tempShiny = $shinyData[$shiny]
        $character = New-Object CharacterShinyData
        $character.Name = $characterDict[$characterId]
        $character.Identifier = "$($characterId)"     
        $character.CollectionId = $tempShiny.CollectionId
        $character.CollectionName = $tempShiny.CollectionName
        $character.CollectionMemberId = $tempShiny.CollectionMemberId
        $character.CollectionMemberName = $tempShiny.CollectionMemberName

        $allTheShinies.Add($tempShiny.CollectionMemberId, $character)
    }

    # Now just need all of this updated to have logic to know what all shinies "should be" needed
    foreach($shinyCollection in $shinyList.character_misc_list.character_misc.collection_list.collection)
    {
        #Write-Output "Shiny collection: $($shinyCollection.crc)";
        foreach($shinyItem in $shinyCollection.item_list.item) 
        { 
            $removeResult = $allTheShinies.Remove($shinyItem.crc)
        }
        #Write-Output "";
    }
    Write-Output "";
    Write-Output "";

    # Now update the shiny needed list with all the results of the above...
    $characterShinyList.AddRange($allTheShinies.Values)
}

if($UpdateCharacterFile) 
{
    $characterList = New-Object System.Collections.Generic.List[Object]

    foreach($character in $characterDict.GetEnumerator())
    {
        #Write-Output "$($character.Key) - $($character.Value)"
        $characterList.Add([PSCustomObject]@{Identifier = $character.Key; Name = $character.Value})
    }
    $characterList | Select-Object @{Name='CharacterId'; Expression={[long]$_.Identifier}}, @{Name='CharacterName'; Expression={[string]$_.Name}} | Export-Csv -Path $CharacterFile -NoTypeInformation
}

Write-Output "=============================================================================================="
Write-Output "Many thanks to Feldon / u.eq2wire.com for sharing the shiny details to make this possible!";
Write-Output "=============================================================================================="
$characterShinyList | Out-GridView -Title "Shinies Needed" -Wait
