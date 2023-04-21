<#
.DESCRIPTION
This script reads the content from a CSV file and create Active Directory user 
accounts from its values with random complex passwords. The template for the 
CSV file (userlist.csv) is available on the GitHub repository.
Requires ActiveDirectory PowerShell module.

.PARAMETER UserList
Specifies the path of the CSV file containing the list of users to create.

.PARAMETER Domain
Specifies the domain DNS name, as it should be used in the UserPrincipalName.

.EXAMPLE
.\New-BulkADUsers -UserList "C:\temp\userlist.csv"
Get group membership for all users in OU "Administrators" and export the results 
in a CSV file.

.NOTES
https://github.com/k0pht
#>

#--------------- Parameters declaration and initialisation ---------------
param (
    [Parameter(Mandatory=$true)][string]$UserList,
    [Parameter()][string]$Domain = (Get-ADDomain).DNSRoot    
)

#--------------- Functions declaration -----------------------------------
# Create password with character range values from the ASCII table
function New-Password {
    $password = -join (48..57 + 65..90 + 97..122 + 33 + 36 + 40..41 + 60..64 | Get-Random -Count 20 | % {[char]$_})
    $password
}

#--------------- Main code -----------------------------------------------
# Import CSV content
$users = Import-Csv -Path $UserList -Delimiter ";"

# Loop through each user from the csv and create corresponding account in Active Directory
foreach ($user in $users) {
    $givenname = $user.'Givenname'
    $surname = $user.'Surname'
    $name = $user.'Name'
    $displayname = $user.'Displayname'
    $description = $user.'Description'
    $samaccountname = $user.'samaccountname'
    $ou = $user.'OU'
    $password = ConvertTo-SecureString -AsPlainText New-Password -Force
    
    if (Get-ADUser -Filter {SamAccountName -eq $samaccountname}) {
        Write-Warning "Account '$samaccountname' already exists."
    }
    else {
        New-ADUser `
            -Givenname $givenname `
            -Surname $surname `
            -Name $name `
            -DisplayName $displayname `
            -Description $description `
            -SamAccountName $samaccountname `
            -UserPrincipalName "$samaccountname@$Domain" `
            -Path $ou `
            -AccountPassword $password -ChangePasswordAtLogon $True `
            -Enabled $true
        
        if ($?) {
            Write-Host "Account '$samaccountname' created." -ForegroundColor Green
        }
    }
}