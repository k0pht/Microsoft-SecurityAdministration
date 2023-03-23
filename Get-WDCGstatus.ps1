<#
.DESCRIPTION
This script gets all Windows clients from the AD, active during the last 90 days,
verifies the activation status of Windows Defender Credential Guard (WDCG) on these 
clients.
It can also be targeted against a single computer or a group of computers.

.PARAMETER Group
Specifies a target group name, containing computers.

.PARAMETER OU
Specifies a target OU distinguishedName (DN).

.PARAMETER ComputerName
Specifies a target computer.

.EXAMPLE
.\Get-WDCGstatus.ps1 -OU "OU=Berlin,DC=company,DC=de"
Get WDCG status for computers in Berlin OU.

.NOTES
https://github.com/k0pht
#>

#--------------- Parameters declaration and initialisation ---------------
param (
    [Parameter()][string]$Group,
    [Parameter()][string]$OU,
    [Parameter()][string]$ComputerName
)

#--------------- Main Code ---------------
# Instructions based on -Group parameter
if($Group) {
    # Targets definition
    $targets = (Get-ADGroupMember $Group).name
    $totalItems = $targets.count
    # Initialisation message
    Write-Host ""
    Write-Host "[*] Checking Windows Defender Credential Guard status on the"$targets.count"members of $Group..." -ForegroundColor Yellow
}
# Instructions based on -OU parameter
elseif($OU) {
    # Target definition
    $targets = (Get-ADComputer -Filter * -SearchBase "$OU").name
    # Initialisation message
    Write-Host ""
    Write-Host "[*] Checking Windows Defender Credential Guard status on the"$targets.count"members of $OU..." -ForegroundColor Yellow
}
# Instructions based on -ComputerName parameter
elseif($ComputerName) {
    # Target definition
    $targets = $ComputerName
    # Initialisation message
    Write-Host ""
    Write-Host "[*] Checking Windows Defender Credential Guard status on $targets..." -ForegroundColor Yellow
}
else {
    # Targets definition
    $gracePeriod = (Get-Date).AddDays(-90)
    $targets = (Get-ADComputer -Properties * -Filter {(LastLogonDate -gt $gracePeriod) -and (OperatingSystem -like "*windows 10*")}).name
    $totalItems = $targets.count
    # Initialisation message
    Write-Host ""
    Write-Host "[*] Checking Windows Defender Credential Guard status on the"$targets.count"active computer found..." -ForegroundColor Yellow
}
# Looping through each targeted computer
foreach ($computer in $targets){
    # Test if computer is reachable
    if (Test-Connection -BufferSize 32 -Count 1 -ComputerName $computer -Quiet){
        # Check if WDCG is enabled
        $value = (Get-CimInstance -ComputerName $computer -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue).SecurityServicesRunning
       
        if ($value){
            Write-Host "[$computer]: Enabled" -ForegroundColor Green
        }
        else{
            Write-Host "[$computer]: Disabled" -ForegroundColor Red
        }
    }
    else{
        Write-Host "[$computer]: Not reachable" -ForegroundColor Yellow
    }
}

Write-Host ""