# A shit script to search VNyan nodes
# https://twitch.tv/LumKitty

Param(
    [Parameter(Mandatory, Position=1)] $SearchTerm
)

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

    if ($Results) {
        Write-Host "Node Graph name: $($Content.GraphName)"
        $Results | Select values, posX, PosY, path | FL
    }
}