<#
.DESCRIPTION
This script queries the Windows event logs from targeted Domain Controllers, and get the events
related to insecure LDAP connections. It is intented to use in a Scheduled Task, to export the 
events periodically and store them in a desired location for further analysis.

.NOTES
https://github.com/k0pht

Script source:
https://github.com/russelltomkins/Active-Directory/blob/master/Query-InsecureLDAPBinds.ps1

( i ) XML values can be retrieved in (GUI) Event Viewer > Right-click on a target Event > Event
Properties > Details tab > XML View
#>

#--------------- Variables initialisation ---------------
# Set the DNS names of your domain controllers
$DomainControllers = "DC01", "DC02"
# Set the path for the CSV export
$CSVPath = "C:\Users\USERNAME\Documents\LDAP_Signing_AuditLogs"
# Set the path for the log file
$Logfile = "C:\Users\USERNAME\Documents\LDAP_Signing_AuditLogs\ScriptExecutions.log"

$InsecureLDAPBinds = @()
$Events = @()
$Date = Get-Date -Format FileDate

#--------------- Functions declaration -----------------------------------
# Function to write logs
Function New-LogWrite
{
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
}

#--------------- Main code -----------------------------------------------
New-LogWrite "==================================== SCRIPT EXECUTION LOGS FOR $Date ===================================="

# Get Directory Service event logs file size and target events on each Domain Controller
foreach ($DomainController in $DomainControllers) {
	$LogFileSize = (Get-Item "\\$DomainController\c$\Windows\System32\Winevt\Logs\Directory Service.evtx").Length/1MB
	New-LogWrite "[$DomainController] Directory Service.evtx size is $LogFileSize MB"
	$Events += Get-WinEvent -ComputerName $DomainController -FilterHashtable @{Logname='Directory Service';Id=2889}
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
# Export to CSV
$filename = "LDAPsigningAudit_AllDCs_" + (Get-Date -Format FileDateTime) + ".csv"
$numberOfRecords = $InsecureLDAPBinds.Count
New-LogWrite "[*] $numberOfRecords records saved to $CSVPath\$filename"
New-LogWrite ""
$InsecureLDAPBinds | Export-CSV -NoTypeInformation "$CSVPath\$filename"