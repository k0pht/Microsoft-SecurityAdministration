<#
.DESCRIPTION
This script looks for all PowerShell scripts within a directory, recursively, tests the presence 
of the Zone.Identifier Alternate Data Stream (ADS), read it if it exists, then exports the results
to a .csv file.

.PARAMETER Path
Specifies the path to search for scripts. Default is present working directory.

.PARAMETER NoRecurse
Switch parameter to disable recursive search through child directories.

.PARAMETER NoResultOutput
Switch parameter to disable console output of identified scripts. Results will still be
saved to the .csv file.

.EXAMPLE
.\Get-ZoneIdentifierADS.ps1 -Path \\targetcomputer\c$\targetfolder -NoResultOutput
Executes the script in target path and all its child directories recursively, doesn't output
the results to the console but exports them to a .csv file.

.NOTES
https://github.com/k0pht
#>

#--------------- Parameters declaration and variables initialisations ---------------
param (
    [Parameter()][string]$Path=$PWD.Path,
    [Parameter()][switch]$NoRecurse,
    [Parameter()][switch]$NoResultOutput
)

$ErrorActionPreference = "SilentlyContinue"
$scriptCount = 0

#--------------- Main Code ---------------

# Instructions based on -NoRecurse switch parameter
if ($NoRecurse) {
    $targets = (Get-ChildItem *.ps1 -Path $Path).FullName
    Write-Host ""
    Write-Host "[*] Looking for PowerShell scripts with a Zone.Identifier ADS in $Path..." -ForegroundColor Yellow
}
else {
    $targets = (Get-ChildItem *.ps1 -Path $Path -Recurse).FullName
    Write-Host ""
    Write-Host "[*] Looking for PowerShell scripts with a Zone.Identifier ADS in $Path and all its child directories..." -ForegroundColor Yellow
}

# Main instructions
$output = foreach ($target in $targets) {
    $scriptWithADS = (Get-Item $target -Stream * | where {$_.stream -like "Zone.Identifier"}).FileName
    
    if ($scriptWithADS) {
        $zoneIdentifier = Get-Content $target -Stream "Zone.Identifier"
        $zoneIdSplit = ("$zoneIdentifier" -split "ZoneId=")[1]
        $zoneID  = $zoneIdSplit[0]

        switch ($zoneID) {
            0 {$zoneName = "My Computer"}
            1 {$zoneName = "Local Intranet"}
            2 {$zoneName = "Trusted Sites"}
            3 {$zoneName = "Internet"}
            4 {$zoneName = "Restricted Sites"}
        }

        New-Object psobject -Property @{
            "Script Path" = $target
            "Zone ID" = $zoneID
            "Zone Name" = $zoneName
        }
        $scriptCount += 1
    }
}

# Instructions based on -NoResultOutput switch parameter
if ($NoResultOutput -eq $false) {
    Write-Host "[*] Search complete, script(s) found:" -ForegroundColor Green
    $output | Select-Object "Script Path", "Zone ID", "Zone Name" | Format-Table
}

# Export results to .csv file
$filename = "PSScript_ZoneIdentifierADS_" + (Get-Date -Format FileDateTime) + ".csv"
$output | select "Script Path", "Zone ID", "Zone Name" | Export-Csv $filename -NoTypeInformation
Write-Host "[*] $scriptCount record(s) saved to $PWD\$filename" -ForegroundColor Yellow
Write-Host ""