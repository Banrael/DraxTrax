#Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

param(
    [string] $CharacterFile = ".\CharacterList.csv",
    [string] $AdornFile = ".\AdornmentStateList.csv",
    [switch] $UpdateCharacterFile,
    [switch] $OnlyActionableAdorns
)

Add-Type @"
public class CharacterData {
    public string Name;
    public string Identifier;
    }
"@

Add-Type @"
public class CharacterAdornData {
    public string Name;
    public string Identifier;
    public string AdornmentName;
    public string AdornmentSlot;
    public string AdornmentColor;
    public string AdornmentId;
    public string AdornmentGameLink;
    public string State;
    }
"@

# Deprecated adornment regex - for identifying the "generally easy" deprecated adorns...
$generallyDeprecatedAdornRegex = "(^Empyral|^Shadowscream|^Void Etched|^Acrylia|Hua Jubilee|^Abysmal Sea Rune:.+\[IX\]$)"

# Potentially non-optimal adorns. May be needed/wanted for stats like reuse or casting speed.
$generallyNonOptimalAdornRegex = "(^Planar|^Incandescent)"

# If you have gotten a ServiceId from https://census.daybreakgames.com/#devSignup, place it here.
# This should avoid throttling issues.
$serviceId = "s:DraxTraxPublic";

# Create a new list of custom objects
$characterList = New-Object System.Collections.Generic.List[CharacterData]
$characterAdornList = New-Object System.Collections.Generic.List[CharacterAdornData]

$characterDict = @{}

$characterInputData = Get-Content $CharacterFile |
    Select-String '^[^#]' | 
    ConvertFrom-Csv |
    Select-Object @{Name='CharacterId'; Expression={[long]$_.CharacterId}}, CharacterName

foreach($inputChar in $characterInputData)
{
    $characterDict.Add($inputChar.CharacterId, $inputChar.CharacterName);
}

$adornStates = @{}

$adornInputData = Get-Content $AdornFile |
    Select-String '^[^#]' | 
    ConvertFrom-Csv |
    Select-Object AdornmentId,AdornmentState

foreach($inputAdorn in $adornInputData)
{
    $adornStates.Add($inputAdorn.AdornmentId, $inputAdorn.AdornmentState)
}

$numCharacters = $characterDict.Keys.Count
$characterNumber = 0

foreach ($characterId in $($characterDict.Keys)) 
{ 
    $characterNumber++;

    Write-Progress -Activity "Looking up characters..." -Status "On $characterNumber of $numCharacters"

    # This at least gets all the adorns by what slot they are in... And what color they are.. Then I just need to know more about the adorns. Do I really have to do a get on each?
    $adornList = (Invoke-RestMethod -Uri "http://census.daybreakgames.com/$serviceId/xml/get/eq2/character/$($characterId)?c:show=name,equipmentslot_list&c:join=item^on:equipmentslot_list.item.adornment_list.id^to:id" -Method Get)

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

    foreach($equipmentSlot in $adornList.character_list.character.equipmentslot_list.equipmentslot)
    {
        Write-Output "$($equipmentSlot.displayname) - $($equipmentSlot.name)";

        foreach($adorn in $equipmentSlot.item.adornment_list.adornment)
        {
            $adornItem = New-Object CharacterAdornData
            $adornItem.Name = $character.Name
            $adornItem.Identifier = $character.Identifier
            $adornItem.AdornmentColor = $adorn.color
            $adornItem.AdornmentName = $adorn.equipmentslot_list_item_adornment_list_id_join_item.displayname
            $adornItem.AdornmentSlot = $equipmentSlot.name
            $adornItem.AdornmentId = $adorn.id;
            $adornItem.AdornmentGameLink = $adorn.equipmentslot_list_item_adornment_list_id_join_item.gamelink
            $adornItem.State = $adornStates[$adornItem.AdornmentId]
            $characterAdornList.Add($adornItem)

            if($adornItem.State -eq "" -and $adornItem.AdornmentName -match $generallyDeprecatedAdornRegex)
            {
                $adornItem.State = "Deprecated - Check Panda or latest expansion starter box for upgrades."
            }

            if($adornItem.State -eq "" -and $adornItem.AdornmentName -match $generallyNonOptimalAdornRegex)
            {
                $adornItem.State = "Consider - Keep if needed for stats but may not be optimal."
            }

            if($adornItem.AdornmentName -eq "")
            {
                $adornItem.State = "Empty Adornment Slot"
            }

            Write-Output "$($adorn.color) - $($adorn.equipmentslot_list_item_adornment_list_id_join_item.displayname)"
        }

        Write-Output "";
    }
    Write-Output "";
    Write-Output "";

    #Start-Sleep -Seconds 2

    $characterList.Add($character);
}

if($UpdateCharacterFile) 
{
    $characterList | Select-Object @{Name='CharacterId'; Expression={[long]$_.Identifier}}, @{Name='CharacterName'; Expression={[string]$_.Name}} | Export-Csv -Path $CharacterFile -NoTypeInformation
}

if($OnlyActionableAdorns) 
{
    $characterAdornList = $characterAdornList | Where-Object { $_.State -ne "" }
}

$characterAdornList | Out-GridView -Title "Adorns" -Wait