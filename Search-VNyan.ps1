# A shit script to search VNyan nodes
#
# https://twitch.tv/LumKitty - https://github.com/LumKitty
#
# Changelog
# v1.1 - Prettier, more readable output

Param(
    [Parameter(Mandatory, Position=1)] $SearchTerm
)

$FinalResults = @()

$Nodes = gci "$ENV:UserProfile\appdata\locallow\Suvidriel\VNyan\redeems*.json"
ForEach ($Node in $Nodes) {
    $Content = Get-Content $Node | ConvertFrom-Json
    $Results = @()
    ForEach ($Node in $Content.nodes) {
        $Success = $False
        ForEach ($Value in $Node.Values) {
            if ($Value.value -like $SearchTerm) { $Success = $True }
        }
        if ($Success) { $Results += $Node }
    }

    ForEach ($Result in $Results) {
        $FinalResults += [PSCustomObject]@{
            Graph = $Content.GraphName
            Name  = $Result.values | Where value -like $SearchTerm | Select -ExpandProperty value
            Type  = $Result.Path.Replace('Nodes/','')
            X     = [Math]::Round($Result.posX)
            Y     = [Math]::Round($Result.posY)
        }
    }
}
$FinalResults | FT