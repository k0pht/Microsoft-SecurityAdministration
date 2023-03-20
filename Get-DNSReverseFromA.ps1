<#
.DESCRIPTION
This script gets records from a specific zone on a target DNS server, then looks
for records for given IP addresses to return its hostname. This can be used when PTR
records don't exist.

.PARAMETER IPv4
Specifies target IPv4 address on which lookup will be done.

.PARAMETER SourceFile
Specifies target file containing IPv4 addresses on which lookups will be done.

.PARAMETER NameServer
Specifies target name server.

.PARAMETER ZoneName
Specifies target zone name.

.PARAMETER ConsoleOutput
Output results to console instead of default .csv export. Default with -IPv4
parameter.

.EXAMPLE
.\Get-DNSReverseFromA -SourceFile ips.txt -NameServer dc01.mydomain.com -ZoneName mydomain.com

.NOTES
https://github.com/k0pht
#>

#--------------- Parameters declaration and variables initialisation ---------------
param (
    [Parameter()][string]$IPv4,
    [Parameter()][string]$SourceFile,
    [Parameter()][string]$NameServer = "dc01.yourdomain.com",
    [Parameter()][string]$ZoneName = "yourdomain.com",
    [Parameter()][switch]$ConsoleOutput
)

$ErrorActionPreference = "SilentlyContinue"

$output = @()

#--------------- Main Code ---------------

# Instructions based on -Group parameter
if($IPv4) {
    # Targets definition
    $IPaddresses = $IPv4
}
# Instructions based on -SourceFile parameter
elseif($SourceFile) {
    # Target definition
    $IPaddresses = Get-Content $SourceFile
    # Filename definition
    $filename = "DNSReverseFromA" + "_" + (Get-Date -Format FileDateTime) + ".csv"
}

# Main instructions
foreach ($IPaddress in $IPaddresses){
    # Get values
    $record = Get-DnsServerResourceRecord -ComputerName $NameServer -ZoneName $ZoneName | Where-Object {$_.RecordData.IPv4Address -eq $IPaddress}
    
    if ($record){
        $hostname = $record.Hostname
        $ip = $record.RecordData.IPv4Address
    }
    else{
        $hostname = "NOT FOUND"
        $ip = $IPaddress
    }
    
    # Add Them To a Row in our Array
	$Row = "" | select Hostname,IPAddress
    $Row.Hostname = $hostname
    $Row.IPAddress = $ip
	
	# Add the row to our Array
	$output += $Row
}

# Instructions based on -ConsoleOutput
if ($ConsoleOutput -eq $TRUE -or $IPv4) {
    $output
}
else {
    # Export results to .csv file
    $output | Export-Csv $filename -NoTypeInformation
    Write-Host "[+] Data exported to $PWD\$filename" -ForegroundColor Green
}