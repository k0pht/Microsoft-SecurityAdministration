<#
.DESCRIPTION
This script queries the Windows event logs from targeted Domain Controllers, and get the events
related to insecure LDAP connections.

.PARAMETER Records
Specifies the last X number of records to look for on each Domain Controller.

.PARAMETER Period
Specifies the period, in minutes, to look for events on each Domain Controller.

.EXAMPLE
.\Get-InsecureLDAP.ps1 -Period 5
Gets all insecure LDAP events from the last 5 minutes.

.NOTES
https://github.com/k0pht

Script source:
https://github.com/russelltomkins/Active-Directory/blob/master/Query-InsecureLDAPBinds.ps1

( i ) XML values can be retrieved in (GUI) Event Viewer > Right-click on a target Event > Event
Properties > Details tab > XML View
#>

#--------------- Parameters declaration and variables initialisation ---------------
param (
	[parameter(Mandatory,ParameterSetName="Records")][int]$Records,
	[parameter(Mandatory,ParameterSetName="Period")][int]$Period
)

# Set the DNS names of your domain controllers
$DomainControllers = "DC01", "DC02"

$InsecureLDAPBinds = @()
$Events = @()

$ErrorActionPreference = "Ignore"

#--------------- Main code -----------------------------------------------
# Grab the appropriate event entries
if ($Records) {
	foreach ($DomainController in $DomainControllers) {
		$Events += Get-WinEvent -ComputerName $DomainController -FilterHashtable @{Logname='Directory Service';Id=2889} | Select -First $Records
	}
}
elseif ($Period) {
	foreach ($DomainController in $DomainControllers) {
		$Events += Get-WinEvent -ComputerName $DomainController -FilterHashtable @{Logname='Directory Service';Id=2889; StartTime=(get-date).AddMinutes("-$Period")}
	}
}

# Loop through each event and output the values
ForEach ($Event in $Events) { 
	$eventXML = [xml]$Event.ToXml()
	
	# Build Our Values
	$DC = $eventXML.event.System.Computer
	$Client = ($eventXML.event.EventData.Data[0])
	$IPAddress = $Client.SubString(0,$Client.LastIndexOf(":")) #Accomodates for IPV6 Addresses
	$Port = $Client.SubString($Client.LastIndexOf(":")+1) #Accomodates for IPV6 Addresses
    $Hostname = Resolve-DnsName $IPAddress -ErrorAction Ignore
	$User = $eventXML.event.EventData.Data[1]
	$DateTime = $Event.TimeCreated
	Switch ($eventXML.event.EventData.Data[2])
		{
		0 {$BindType = "Unsigned"}
		1 {$BindType = "Simple"}
		}
	
	# Add Them To a Row in our Array
	$Row = "" | select DomainController,IPAddress,Hostname,Port,User,DateTime,BindType
	$Row.DomainController = $DC
	$Row.IPAddress = $IPAddress
    $Row.Hostname = $Hostname.NameHost
	$Row.Port = $Port
	$Row.User = $User
	$Row.DateTime = $DateTime
	$Row.BindType = $BindType
	
	# Add the row to our Array
	$InsecureLDAPBinds += $Row
}

# Output the results
$InsecureLDAPBinds | Format-Table