# Microsoft Security Administration
This repository contains scripts I wrote and used during different engagements, for security administration tasks. This README file categorize them by activities or projects I used the scripts for and gives a short explanation on the goals I tried to achieve with. 

## AD Tiering Model
Once working on implementing the AD Tiering Model, now part of the [Enterprise access model](https://learn.microsoft.com/en-us/security/privileged-access-workstations/privileged-access-access-model), I used `New-BulkADUsers.ps1` and `Get-GroupMembership.ps1` for the tasks described below.

### Create new privileged accounts with [New-BulkADUsers.ps1](https://github.com/k0pht/Microsoft-SecurityAdministration/blob/main/New-BulkADUsers.ps1)
To start with new fresh privileged (administrator) T0, T1 and T2 accounts, with cleaner ACLs than existing ones and no group membership, I created all the accounts with `New-BulkADUsers.ps1`.

### Audit privileged accounts group membership with [Get-GroupMembership.ps1](https://github.com/k0pht/Microsoft-SecurityAdministration/blob/main/Get-GroupMembership.ps1)
To clean up the group membership of privileged accounts, I exported all groups from which the targeted privileged accounts are members of for further review with the IT team.


## Require LDAP signing on the Domain Controllers
To protects against relay attacks, among others, towards the LDAP service of the Domain Controllers, [they should be configured](https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/enable-ldap-signing-in-windows-server) to accept only signed (or more broadly, secured) LDAP binds. I used the scripts `Get-InsecureLDAP.ps1`, `Get-InsecureLDAP_ScheduledTask.ps1` and `Get-DNSReverseFromA.ps1` for the tasks described below.

### Audit insecure LDAP binds with [Get-InsecureLDAP.ps1](https://github.com/k0pht/Microsoft-SecurityAdministration/blob/main/Get-InsecureLDAP.ps1) and [Get-InsecureLDAP_ScheduledTask.ps1](https://github.com/k0pht/Microsoft-SecurityAdministration/blob/main/Get-InsecureLDAP_ScheduledTask.ps1)
I used `Get-InsecureLDAP_ScheduledTask.ps1` in a daily scheduled tasks to save the related events from the Domain Controllers for further analysis, and `Get-InsecureLDAP.ps1` for live troubleshooting and verifications of applications identified in the logs.

### Find hostnames without PTR records with [Get-DNSReverseFromA.ps1](https://github.com/k0pht/Microsoft-SecurityAdministration/blob/main/Get-DNSReverseFromA.ps1)
Reading the logs gathered with `Get-InsecureLDAP_ScheduledTask.ps1`, it is easier to identify the source applications with hostnames than with IP addresses, which is what the event logs give us. `Get-DNSReverseFromA.ps1` is useful if no PTR records exists for the host in the DNS, as the *Resolve-DnsName* cmdlet cannot be used in this case.
Ideally, this script should be written as a function and integrated in `Get-InsecureLDAP_ScheduledTask.ps1` and `Get-InsecureLDAP.ps1`.


## Protect from credential dumping with LSA Protection and Windows Defender Credential Guard
To harden Windows endpoints against credential dumping attacks, you can enable [LSA Protection](https://learn.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection) and [Windows Defender Credential Guard](https://learn.microsoft.com/en-us/windows/security/identity-protection/credential-guard/credential-guard-manage). I used the scripts `Get-LSAaudit.ps1` and `Get-WDCGStatus.ps1` for the tasks described below.

### Audit process affected by LSA Protection with [Get-LSAaudit.ps1](https://github.com/k0pht/Microsoft-SecurityAdministration/blob/main/Get-LSAaudit.ps1)
After [enabling the auditing of LSA plug-ins and drivers that fail to run as a protected process](https://learn.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection#auditing-to-identify-lsa-plug-ins-and-drivers-that-fail-to-run-as-a-protected-process), I used `Get-LSAaudit.ps1` to gather relevant event logs on target devices.

### Check Windows Defender Credential Guard status with [Get-WDCGstatus.ps1](https://github.com/k0pht/Microsoft-SecurityAdministration/blob/main/Get-WDCGstatus.ps1)
To ensure that WDCG is enabled on targeted devices, I used `Get-WDCGstatus.ps1`.


## Set the PowerShell execution policy to RemoteSigned
The potential impact of PowerShell execution policy set to RemoteSigned can be assessed with `Get-ZoneIdentifierADS.ps1`.