# Stream start countdown timer v1.3 - by Lum 
# https://twitch.tv/LumKitty https://github.com/LumKitty

# Usage

# Edit line 55 of this script to point to an appropriate location on your system, then add a text source in OBS that uses this file

# Stream is starting at 7:30 PM
# .\Countdown-Timer.ps1 -TrgTime 19:30

# Stream is starting in 10 minutes
# .\Countdown-Timer.ps1 -Minutes 10

# Stream is starting at half past the current hour (e.g. run this at 6:10 and it will start at 6:30 giving a 20min countdown)
# .\Countdown-Timer.ps1 -Minutes 30 -Past

# Streamdeck config using BarRaider's Advanced Launcher
# Application   : C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
# Arguments     : -WindowStyle Minimized D:\Twitch\Scripts\Countdown-Timer.ps1 -TrgTime 18:00
# Admin         : no                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^ - Change these two parts
# Instances     : do not limit
# Kill instances: no
# Indicator     : no
# Background    : no

# Changelog

# v1.1 - Fix killing of previous versions of the timer
# v1.2 - Add -Past parameter, allows starting the script with e.g. 30 -Past to start at 30 minutes past the current hour (or next hour if it's already half past)
#        More efficient (but less readable) calculation of remaining time and delay times in the countdown loop to (hopefully) eliminate skipped seconds
# v1.3 - Use System.Timers.Timer and Wait-Event to make the script more efficient

[CmdletBinding()]
Param (
    [Parameter(Mandatory, Position=1, ParameterSetName='Target')] 
    [String]   $TrgTime                                     # Countdown until this specified time

   ,[ValidateRange(0, 59)]
    [Parameter(Mandatory, Position=1, ParameterSetName='Time')]
    [Parameter(Mandatory, Position=1, ParameterSetName='xPast')]
    [Int]      $Minutes                                     # Countdown for this many minutes (or until this many minutes past the hour if -Past is used)
   
   ,[ValidateRange(0, 59)]
    [Parameter(           Position=2, ParameterSetName='Time')]
    [Parameter(           Position=2, ParameterSetName='xPast')]
    [Int]      $Seconds = 0                                 # And this many seconds

   ,[Parameter(Mandatory,             ParameterSetName='xPast')]
    [Switch]   $Past                                        # Wait until -Minutes past the hour

   ,[String]   $Prefix  = ''                                # A text string to output before the text
   ,[String]   $Suffix  = ''                                # A text string to output after the text
   ,[String]   $Format  = 'mm\:ss'                          # Format to display the time in
   ,[String]   $Done    = ''                                # A text string to output once the target time is reached
   ,[String]   $File    = 'D:\Twitch\Scripts\Countdown.txt' # Which text file to output to   *** EDIT THIS FOR YOUR OWN SYSTEM ***
)
$ErrorActionPreference = 'Stop'

Switch ($PSCmdlet.ParameterSetName) {
    'Time'   { [DateTime]$TrgTime = (Get-Date).AddMinutes($Minutes).AddSeconds($Seconds) } # Calculate target time if time was specified in minutes
    'xPast'  {
        $Now = Get-Date
        [DateTime]$TrgTime = $Now.AddMinutes(-$Now.Minute).AddSeconds(-$Now.Second).AddMinutes($Minutes).AddMinutes($Seconds)
        if ($TrgTime -lt $Now) { $TrgTime = $TrgTime.AddHours(1) }
    }
    'Target' { [DateTime]$TrgTime = [DateTime]$TrgTime } # Force cast from string to DateTime
}

# Kill any other running instance of this script
Get-CimInstance Win32_Process -Filter "name = 'powershell.exe'" | where {($_.ProcessID -ne $PID) -and ($_.CommandLine -like "*$($MyInvocation.MyCommand.Path)*")} | ForEach { Stop-Process -id $_.ProcessId }

Write-Host "Counting down until $TrgTime"

$Global:Prefix = $Prefix  #
$Global:Suffix = $Suffix  #
$Global:File   = $File    # These all need to be readable from inside the timer event
$Global:TrgTime= $TrgTime #
$Global:Format = $Format  #

$TimerName = 'lum.uk.timer' # Hopefully unique name... if not, why are you using my domain name in your own timer event? :/
Try {
    $Action = { "$Global:Prefix$(($Global:TrgTime - (Get-Date)).ToString($Global:Format))$Global:Suffix" | Out-File $Global:File -Encoding ascii } # Called when the timer ticks
    Invoke-Command $Action                        # The above is Also called manually at the start of the script
    $Timer = New-Object System.Timers.Timer(1000) # Call every 1 second
    $Timer.AutoReset = $True                      # Means the timer will keep calling
    $Start = Register-ObjectEvent -InputObject $timer -SourceIdentifier $TimerName -EventName Elapsed -Action $Action # Attach event to timer
    $Timer.Start()
    Wait-Event -Timeout ($TrgTime - (Get-Date)).TotalSeconds # Wait until the timer is due to expire
} finally {
    Get-EventSubscriber -SourceIdentifier $TimerName -EA SilentlyContinue | Unregister-Event
    $Timer.Stop()
}
$Done | Out-File $File -Encoding ascii # Write final text (will not be written if the timer is killed or an error occurs