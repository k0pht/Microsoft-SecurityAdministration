<#
.DESCRIPTION
This script gets all Windows servers and clients from the AD, active during the last 90 days,
and gets events 3065 and 3066 from "Microsoft-Windows-Codeintegrity/Operational". These events
identify LSA plug-ins and drivers that fail to run as protected process.
It can also be targeted against a single computer or a group of computers.

.PARAMETER Group
Specifies a target group name, containing computers.

.PARAMETER ComputerName
Specifies a target computer.

.PARAMETER ConsoleOutput
Output results to console instead of default .csv export.

.EXAMPLE
.\Get-LSAuadit.ps1 -Group HR_Computers
Get LSA protection audit logs for computers in HR_Computers group.

.NOTES
https://github.com/k0pht
#>

#--------------- Parameters declaration and initialisation ---------------
param (
    [Parameter()][string]$Group,
    [Parameter()][string]$ComputerName,
    [Parameter()][switch]$ConsoleOutput
)

$ErrorActionPreference = "SilentlyContinue"

$output = @()
$currentItem = 0
$percentComplete = 0

#--------------- Main Code ---------------

# Instructions based on -Group parameter
if($Group) {
    # Targets definition
    $targets = (Get-ADGroupMember $Group).name
    $totalItems = $targets.count
    # Initialisation message
    Write-Host ""
    Write-Host "[*] Gathering data from event logs on the"$targets.count"members of $Group..." -ForegroundColor Yellow
    # Filename definition
    $filename = "LSAaudit_" + $group + "_" + (Get-Date -Format FileDateTime) + ".csv"
}
# Instructions based on -ComputerName parameter
elseif($ComputerName) {
    # Target definition
    $targets = $ComputerName
    # Filename definition
    $filename = "LSAaudit_" + $ComputerName + "_" + (Get-Date -Format FileDateTime) + ".csv"
}
else {
    # Targets definition
    $gracePeriod = (Get-Date).AddDays(-90)
    $targets = (Get-ADComputer -Properties * -Filter {(LastLogonDate -gt $gracePeriod) -and (OperatingSystem -like "*windows*")}).name
    $totalItems = $targets.count
    # Initialisation message
    Write-Host ""
    Write-Host "[*] Gathering data from event logs on the"$targets.count"active computer found..." -ForegroundColor Yellow
    # Filename definition
    $filename = "LSAaudit_AllActiveComputers_" + (Get-Date -Format FileDateTime) + ".csv"
}

# Main instructions
ForEach ($computer in $targets) {
    # Progress bar when multiple computers are targeted
    if($ComputerName -eq $NULL) {
        Write-Progress -Activity "Getting events on targets" -Status "Status $percentComplete%" -PercentComplete $percentComplete
        $currentItem++
        $percentComplete = [int](($currentItem / $totalItems) * 100)
    }
    
    # Get event if target is reachable
    if (Test-Connection -BufferSize 32 -Count 1 -ComputerName $computer -Quiet) {
        $output += Get-WinEvent -ComputerName $computer -FilterHashtable @{LogName = "Microsoft-Windows-Codeintegrity/Operational"; ID = 3065, 3066} |
        Select-Object @{name='ComputerName'; expression={$computer}}, Id, Message, TimeCreated
    }
    elseif ($ComputerName) {
        Write-Host "$computer is not reachable." -ForegroundColor Red
    }
}
# Instructions based on -ConsoleOutput
if ($ConsoleOutput -eq $TRUE) {
    $output
}
else {
    # Export results to .csv file
    $output | Export-Csv $filename -NoTypeInformation
    Write-Host "[*]"$output.count"log entries found!" -ForegroundColor Green
    Write-Host "[+] Data exported to $PWD\$filename" -ForegroundColor Green
}