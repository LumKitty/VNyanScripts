# Stream start countdown timer v1.2 - by Lum 
# https://twitch.tv/LumKitty https://github.com/LumKitty

# Usage

# Edit line 52 of this script to point to an appropriate location on your system, then add a text source in OBS that uses this file

# Stream is starting at 7:30 PM
# .\Countdown-Timer.ps1 -TrgTime 19:30

# Stream is starting in 10 minutes
# .\Countdown-Timer.ps1 -Minutes 10

# Stream is starting at half past the current hour (e.g. run this at 6:10 and it will start at 6:30 giving a 20min countdown)
# .\Countdown-Timer.ps1 -Minutes 30 -Past

# Streamdeck config using BarRaider's Advanced Launcher
# Application   : C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
# Arguments     : -WindowStyle Minimized D:\Twitch\Scripts\Countdown-Timer.ps1 -TrgTime 18:00
# Admin         : no                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^          ^^^^^ - Change these two parts
# Instances     : do not limit
# Kill instances: no
# Indicator     : no
# Background    : no

# Changelog

# v1.1 - Fix killing of previous versions of the timer
# v1.2 - Add -Past parameter, allows starting the script with e.g. 30 -Past to start at 30 minutes past the current hour (or next hour if it's already half past)
#        More efficient (but less readable) calculation of remaining time and delay times in the countdown loop to (hopefully) eliminate skipped seconds

[CmdletBinding()]
Param (
    [Parameter(Mandatory, Position=1, ParameterSetName='Target')] 
    [String]   $TrgTime     # Countdown until this specified time

   ,[Parameter(Mandatory, Position=1, ParameterSetName='Time')]
    [Parameter(Mandatory, Position=1, ParameterSetName='xPast')]
    [Int]      $Minutes     # Counddown for this many minutes
   
   ,[Parameter(           Position=2, ParameterSetName='Time')]
    [Parameter(           Position=2, ParameterSetName='xPast')]
    [Int]      $Seconds = 0 # And this many seconds

   ,[Parameter(Mandatory,             ParameterSetName='xPast')]
    [Switch]   $Past

   ,[String] $Prefix = '' # A text string to output before the text
   ,[String] $Suffix = '' # A text string to output after the text
   ,[String] $Format = 'mm\:ss' # Format to display the time in
   ,[String] $Done   = '' # A text string to output once the target time is reached
   ,[String] $File = 'D:\Twitch\Scripts\Countdown.txt' # Which text file to output to   *** EDIT THIS FOR YOUR OWN SYSTEM ***
)

$ErrorActionPreference = 'Stop'

Write-Verbose $PSCmdlet.ParameterSetName
Switch ($PSCmdlet.ParameterSetName) {
    'Time' { [DateTime]$TrgTime = (Get-Date).AddMinutes($Minutes).AddSeconds($Seconds) } # Calculate target time if time was specified in minutes
    'xPast' {
        $Now = Get-Date
        [DateTime]$TrgTime = $Now.AddMinutes(-$Now.Minute).AddSeconds(-$Now.Second).AddMinutes($Minutes).AddMinutes($Seconds)
        if ($TrgTime -lt $Now) { $TrgTime = $TrgTime.AddHours(1) }
    }
    'Target' { [DateTime]$TrgTime = [DateTime]$TrgTime }
}

# Kill any other running instance of this script
Get-CimInstance Win32_Process -Filter "name = 'powershell.exe'" | where {($_.ProcessID -ne $PID) -and ($_.CommandLine -like "*$($MyInvocation.MyCommand.Path)*")} | ForEach { Stop-Process -id $_.ProcessId }


Write-Host "Counting down until $TrgTime"

do {
    "$Prefix$(($TrgTime - (Get-Date)).ToString($Format))$Suffix" | Out-File $File -Encoding ascii # Write to file
    Start-Sleep -Milliseconds (1000 - (Get-Date).Millisecond)
} until ($WaitTime -gt $TrgTime)                                                     # Stop once we reach target time

$Done | Out-File $File -Encoding ascii # Write final text