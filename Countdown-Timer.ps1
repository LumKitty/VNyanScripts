# Stream start countdown timer - by Lum
# https://twitch.tv/LumKitty https://github.com/LumKitty

# Usage

# Edit line 32 of this script to point to an appropriate location on your system, then add a text source in OBS that uses this file

# Stream is starting at 7:30 PM
# .\Countdown-Timer.ps1 -TrgTime 19:30

# Stream is starting in 10 minutes
# .\Countdown-Timer.ps1 -Minutes 10

# Streamdeck config using BarRaider's Advanced Launcher
# Application   : C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
# Arguments     : -WindowStyle Minimized D:\Twitch\Scripts\Countdown-Timer.ps1 -TrgTime 18:00
# Admin         : no                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^          ^^^^^ - Change these two parts
# Instances     : do not limit
# Kill instances: no
# Indicator     : no
# Background    : no

[CmdletBinding()]
Param (
    [Parameter(Mandatory, Position=1, ParameterSetName='Target')] [DateTime] $TrgTime     # Countdown until this specified time
   ,[Parameter(Mandatory, Position=1, ParameterSetName='Time')]   [Int]      $Minutes     # Counddown for this many minutes
   ,[Parameter(           Position=2, ParameterSetName='Time')]   [Int]      $Seconds = 0 # And this many seconds
   ,[String] $Prefix = '' # A text string to output before the text
   ,[String] $Suffix = '' # A text string to output after the text
   ,[String] $Format = 'mm\:ss' # Format to display the time in
   ,[String] $Done   = '' # A text string to output once the target time is reached
   ,[String] $File = 'D:\Twitch\Scripts\Countdown.txt' # Which text file to output to   *** EDIT THIS FOR YOUR OWN SYSTEM ***
)

$ErrorActionPreference = 'Stop'

If ($PSCmdlet.ParameterSetName -eq 'Time') {
    $TrgTime = (Get-Date).AddMinutes($Minutes).AddSeconds($Seconds) # Calculate target time if time was specified in minutes
}

# Kill any other running instance of this script
Get-CimInstance Win32_Process -Filter "name = 'powershell.exe'" | where {($_.ProcessID -ne $PID) -and ($_.CommandLine -like "*$($MyInvocation.MyCommand.Path)*")} | Stop-Process

Write-Host "Counting down until $TrgTime"

do {
    $CurTime = (Get-Date)
    $WaitTime = $CurTime.AddMilliseconds(1000-$CurTime.Millisecond)                  # Add one second, but take into account script processing time, rather than lazily adding one second
    Start-Sleep -Milliseconds ($WaitTime - $CurTime).Milliseconds                    # Wait a bit
    $Remaining = ($TrgTime - $WaitTime)                                              # Calculate time remaining
    "$Prefix$($Remaining.ToString($Format))$Suffix" | Out-File $File -Encoding ascii # Write to file
} until ($WaitTime -gt $TrgTime)                                                     # Stop once we reach target time

$Done | Out-File $File -Encoding ascii # Write final text