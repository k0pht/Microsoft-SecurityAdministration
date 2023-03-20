<#
.DESCRIPTION
This script gets all groups memberships from a specific user or all users
from a specific OU and expand nested groups.
Requires ActiveDirectory PowerShell module.

.PARAMETER User
Specifies a target user.

.PARAMETER OU
Specifies a OU distinguishedName, containing target users.

.PARAMETER ExportCSV
Output results to a .csv file, instead of default console output.

.PARAMETER DNSRoot
Specifies a target domain DNS root. Optional, usually not needed.

.EXAMPLE
.\Get-GroupMembership.ps1 -OU "OU=Administrators,DC=company,DC=local" -ExportCSV
Get group membership for all users in OU "Administrators" and export the results 
in a CSV file.

.NOTES
https://github.com/k0pht
#>

#--------------- Parameters declaration and initialisation ---------------
param (
    [Parameter(Mandatory,ParameterSetName="User")][string]$User,
    [Parameter(Mandatory,ParameterSetName="OU")][string]$OU,
    [Parameter()][switch]$ExportCSV,
    [Parameter()][string]$DNSRoot = (Get-ADDomain).DNSRoot   
)

#--------------- Functions declaration -----------------------------------
# Function to get all group memberships, inlcuding nested groups
function Get-UserGroups ($User, $Indent = "", $Filename) {
    $groups = Get-ADPrincipalGroupMembership -Identity $user -ResourceContextServer $DNSRoot
    
    foreach ($group in $groups) {
        $groupname = $group.name
        $groupdescription = (Get-ADGroup $group -Properties *).description
        $content = "$indent$groupname # $groupdescription" 
        if ($null -ne $Filename) {
            Add-Content $Filename -Value $content
        }
        else {
            $content
        }
        Get-UserGroups -User $group -Indent "$groupname < " -Filename $Filename
    }
}

#--------------- Main code -----------------------------------------------
# Setting users variable based on User or OU parameter
if ($OU) {
    $users = Get-ADUser -SearchBase $OU -Filter *
}
else {
    $users = $User
}

foreach ($user in $users) {
    $fulluser = Get-ADUser $user
    
    if ($ExportCSV) {
        $filename = $fulluser.Surname + $fulluser.GivenName + "_" + $fulluser.samaccountname + "_" + (Get-Date -Format "yyyyMMdd") + ".csv"
        Get-UserGroups -User $user -Filename $filename
    }
    else {
        Write-Host "--------- " $fulluser.samaccountname " ---------" -ForegroundColor Cyan
        Get-UserGroups -User $user 
        Write-Host "`n"
    }
}