# PHASE 09 - TROUBLESHOOTING & REAL-WORLD TICKETS

## Windows Server 2025 Enterprise Infrastructure

**Project:** Windows Server 2025 Enterprise Infrastructure  
**Domain:** `diarabaka.com`  
**Network:** `192.168.1.0/24`  
**Domain Controllers:** `DC01`, `DC02`  
**File Server:** `FILE01`  
**Client:** `WIN11`  
**Platform:** VMware  
**Professional Domain:** Microsoft Infrastructure

---

# 09.0 - Objective

Cette phase transforme le lab en environnement d'exploitation.

L'objectif n'est plus uniquement :

```text
CONFIGURE
```

mais :

```text
RECEIVE TICKET
      ↓
UNDERSTAND
      ↓
DEFINE SCOPE
      ↓
COLLECT EVIDENCE
      ↓
CHECK DEPENDENCIES
      ↓
DIAGNOSE
      ↓
IDENTIFY ROOT CAUSE
      ↓
APPLY MINIMUM CORRECTION
      ↓
FUNCTIONAL RETEST
      ↓
SECURITY REGRESSION
      ↓
POST-INCIDENT HEALTH CHECK
      ↓
DOCUMENT
      ↓
CLOSE / ESCALATE
```

Un administrateur confirmé commence par établir :

```text
WHAT IS BROKEN?
WHO IS AFFECTED?
SINCE WHEN?
WHAT CHANGED?
WHAT STILL WORKS?
WHAT DOES NOT WORK?
WHAT DEPENDENCY COMES NEXT?
WHAT EVIDENCE SUPPORTS THE HYPOTHESIS?
```

---

# 09.1 - Troubleshooting Methodology

Workflow général :

```text
                    TICKET
                       │
                       ▼
                DEFINE SCOPE
                       │
                       ▼
              COLLECT BASELINE
                       │
                       ▼
                  IDENTITY
                       │
                       ▼
                    NETWORK
                       │
                       ▼
                      DNS
                       │
                       ▼
                 DC LOCATOR
                       │
                       ▼
                      TIME
                       │
                       ▼
               ACTIVE DIRECTORY
                       │
                       ▼
               AUTHENTICATION
                       │
                       ▼
                     GPO
                       │
                       ▼
                  RESOURCE
                       │
                       ▼
                  PERMISSIONS
                       │
                       ▼
                  ROOT CAUSE
                       │
                       ▼
             MINIMUM CORRECTION
                       │
                       ▼
                FUNCTIONAL RETEST
                       │
                       ▼
             SECURITY REGRESSION
                       │
                       ▼
               GLOBAL HEALTH CHECK
                       │
                       ▼
                DOCUMENT / CLOSE
```

L'ordre exact dépend du ticket, mais les dépendances doivent guider le diagnostic.

---

# 09.2 - Diagnostic First

Principe :

```text
OBSERVE
   ↓
MEASURE
   ↓
COMPARE
   ↓
DIAGNOSE
   ↓
CHANGE
```

et non :

```text
PROBLEM
   ↓
RANDOM CHANGE
   ↓
REBOOT
   ↓
HOPE
```

Les commandes suivantes modifient déjà l'état :

```powershell
gpupdate /force
klist purge
ipconfig /release
ipconfig /renew
Unlock-ADAccount
Set-ADAccountPassword
Restart-Service
Stop-Service
Test-ComputerSecureChannel -Repair
Add-Computer
```

Elles doivent être utilisées après la collecte initiale lorsqu'elles sont justifiées.

---

# 09.3 - Ticket Record

Chaque incident doit disposer d'une fiche :

```text
Ticket ID:
Date / Time:
Requester:
Affected system:
Affected user:

SYMPTOM:
...

BUSINESS IMPACT:
...

SCOPE:
Single user / Multiple users / Workstation / Server / Domain

INITIAL STATE:
...

DEPENDENCIES CHECKED:
...

DIAGNOSTIC:
...

EXPECTED:
...

ACTUAL:
...

ROOT CAUSE:
...

CORRECTION:
...

FUNCTIONAL RETEST:
...

SECURITY REGRESSION:
...

POST-INCIDENT HEALTH CHECK:
...

ROLLBACK:
...

EVIDENCE:
...

FINAL STATUS:
OPEN / DIAGNOSING / RESOLVED / VALIDATED / ESCALATED
```

---

# 09.4 - Ticket Status Model

```text
OPEN
DIAGNOSING
ROOT CAUSE IDENTIFIED
CORRECTED
RESOLVED
VALIDATED
ESCALATED
```

Définition :

```text
RESOLVED
=
Service restored

VALIDATED
=
Root cause confirmed
+
Minimum correction
+
Functional retest
+
Security preserved
+
Health check completed
+
Evidence collected
```

---

# 09.5 - Severity Model

Exemple pour le lab :

| Severity | Exemple                                                                |
| -------- | ---------------------------------------------------------------------- |
| `P1`     | Authentification domaine ou plusieurs services critiques indisponibles |
| `P2`     | Composant d'infrastructure majeur dégradé                              |
| `P3`     | Un utilisateur ou poste incapable de travailler normalement            |
| `P4`     | Demande mineure ou incident à faible impact                            |

En entreprise réelle, la priorité dépend des SLA, du business impact et des procédures internes.

---

# 09.6 - Incident Evidence Rule

Une simulation ne doit pas être présentée comme un incident réellement exécuté.

Avant exécution :

```text
READY FOR VALIDATION
```

Après test contrôlé :

```text
SYMPTOM REPRODUCED
       +
DIAGNOSTIC
       +
ROOT CAUSE
       +
CORRECTION
       +
FUNCTIONAL RETEST
       +
SECURITY REGRESSION
       +
POST HEALTH CHECK
       +
EVIDENCE
       =
VALIDATED
```

---

# 09.7 - TICKET INC-001 - Domain Logon Failure

## Situation

Utilisateur :

> Je n'arrive plus à me connecter avec mon compte domaine.

Machine :

```text
WIN11
```

Impact initial :

```text
Domain authentication unavailable
```

---

# 09.7.1 - Scope

Avant modification :

```text
Only this user?
Only WIN11?
Several users?
Several computers?
Entire domain?
```

Une panne utilisateur unique et une panne domaine-wide ne doivent pas suivre le même diagnostic.

---

# 09.7.2 - Network Adapter

```powershell
Get-NetAdapter |
    Select-Object `
        Name,
        Status,
        LinkSpeed
```

---

# 09.7.3 - IP Baseline

```powershell
ipconfig /all
```

Puis :

```powershell
Get-NetIPConfiguration
```

Collecter :

```text
IPv4
Prefix
Gateway
DHCP
DNS
DNS suffix
```

---

# 09.7.4 - Network Profile

```powershell
Get-NetConnectionProfile
```

Sur le réseau domaine, le profil attendu est généralement :

```text
DomainAuthenticated
```

Un profil `Public` est un symptôme à diagnostiquer.

---

# 09.7.5 - DC Connectivity

```powershell
Test-NetConnection DC01 -Port 53
Test-NetConnection DC01 -Port 88
Test-NetConnection DC01 -Port 389

Test-NetConnection DC02 -Port 53
Test-NetConnection DC02 -Port 88
Test-NetConnection DC02 -Port 389
```

La connectivité TCP ne prouve pas à elle seule que LDAP ou Kerberos fonctionnent complètement.

---

# 09.7.6 - DNS Client

```powershell
Get-DnsClientServerAddress `
    -AddressFamily IPv4
```

Cible :

```text
192.168.1.10
192.168.1.11
```

---

# 09.7.7 - DNS Resolution

```powershell
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com
```

Puis :

```powershell
Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV
```

Puis :

```powershell
Resolve-DnsName `
    "_kerberos._tcp.diarabaka.com" `
    -Type SRV
```

---

# 09.7.8 - DC Locator

```powershell
nltest /dsgetdc:diarabaka.com
```

Attendu :

```text
A valid domain controller is discovered
```

---

# 09.7.9 - AD Site

```powershell
nltest /dsgetsite
```

---

# 09.7.10 - Time

```powershell
w32tm /query /status
w32tm /query /source
```

Une dérive importante peut casser Kerberos.

---

# 09.7.11 - Secure Channel

Si une session locale administrative est disponible :

```powershell
Test-ComputerSecureChannel
```

Attendu :

```text
True
```

Si `False` :

```text
DNS
 ↓
DC Locator
 ↓
Time
 ↓
Network
 ↓
Computer object
 ↓
AD replication
 ↓
Repair only if justified
```

---

# 09.7.12 - User Account

Sur DC01 :

```powershell
Get-ADUser "<username>" `
    -Properties `
        Enabled,
        LockedOut,
        PasswordExpired,
        PasswordLastSet,
        AccountExpirationDate |
    Select-Object `
        SamAccountName,
        Enabled,
        LockedOut,
        PasswordExpired,
        PasswordLastSet,
        AccountExpirationDate
```

---

# 09.7.13 - Kerberos Evidence

Après ouverture d'une session permettant le test :

```powershell
klist
```

Puis accès à une ressource :

```powershell
Get-ChildItem "\\FILE01\Public$"
```

Puis :

```powershell
klist
```

Rechercher :

```text
cifs/FILE01
```

---

# 09.7.14 - Root Cause Matrix

| Observation                                      | Direction                |
| ------------------------------------------------ | ------------------------ |
| Wrong DNS servers                                | Client DNS configuration |
| SRV missing                                      | AD DNS                   |
| No DC discovered                                 | DNS / AD / network       |
| Time wrong                                       | Kerberos / Windows Time  |
| Secure channel false                             | Computer trust           |
| Account locked                                   | Account lifecycle        |
| Several users affected                           | Infrastructure           |
| CIFS ticket absent despite resource access issue | Authentication path      |

---

# 09.7.15 - Validation

Après correction :

```powershell
nltest /dsgetdc:diarabaka.com
Test-ComputerSecureChannel
w32tm /query /status
```

Puis vrai test utilisateur :

```text
Domain logon successful
```

---

# 09.8 - TICKET INC-002 - Account Locked

## Situation

> Mon mot de passe est correct mais mon compte est verrouillé.

---

# 09.8.1 - Verify

```powershell
Get-ADUser "<username>" `
    -Properties `
        LockedOut,
        BadPwdCount,
        LastBadPasswordAttempt |
    Select-Object `
        SamAccountName,
        LockedOut,
        BadPwdCount,
        LastBadPasswordAttempt
```

---

# 09.8.2 - Security Event 4740

Sur les DC concernés :

```powershell
Get-WinEvent `
    -FilterHashtable @{
        LogName = "Security"
        Id      = 4740
    } `
    -ErrorAction SilentlyContinue |
    Select-Object `
        TimeCreated,
        Id,
        Message
```

---

# 09.8.3 - Root Cause Candidates

```text
Credential Manager
Scheduled Task
Service
Mapped Resource
Application
Another Workstation
Another Session
Old Password
Repeated Failed Logon
```

---

# 09.8.4 - Unlock

Lorsque justifié :

```powershell
Unlock-ADAccount `
    -Identity "<username>"
```

---

# 09.8.5 - Validate

```powershell
Get-ADUser "<username>" `
    -Properties LockedOut |
    Select-Object `
        SamAccountName,
        LockedOut
```

Puis :

```text
Authentication successful
No immediate relock
```

Si relock immédiat :

```text
Incident not validated
Root cause source still active
```

---

# 09.9 - TICKET INC-003 - Forgotten Password

## Situation

> J'ai oublié mon mot de passe.

Avant intervention :

```text
Verify identity
Check account state
Use delegated Helpdesk rights
Avoid Domain Admin
Protect temporary secret
```

---

# 09.9.1 - Inspect Account

```powershell
Get-ADUser "<username>" `
    -Properties `
        Enabled,
        LockedOut,
        PasswordExpired |
    Select-Object `
        SamAccountName,
        Enabled,
        LockedOut,
        PasswordExpired
```

---

# 09.9.2 - Reset Password

```powershell
$Password = Read-Host `
    "Temporary password" `
    -AsSecureString
```

Puis :

```powershell
Set-ADAccountPassword `
    -Identity "<username>" `
    -Reset `
    -NewPassword $Password
```

Puis :

```powershell
Set-ADUser `
    -Identity "<username>" `
    -ChangePasswordAtLogon $true
```

---

# 09.9.3 - Secret Handling

Ne jamais mettre le mot de passe temporaire dans :

```text
Ticket
Screenshot
GitHub
Transcript
Evidence
Email
Documentation
```

---

# 09.9.4 - Validate

```powershell
Get-ADUser "<username>" `
    -Properties PasswordLastSet |
    Select-Object `
        SamAccountName,
        PasswordLastSet
```

Puis :

```text
User authenticates
User changes temporary password if policy requires
```

---

# 09.10 - TICKET INC-004 - HR Share Access Denied

## Situation

Utilisateur HR :

```text
\\FILE01\HR$
```

Retour :

```text
Access Denied
```

---

# 09.10.1 - AGDLP Model

Le modèle attendu est :

```text
USER
 ↓
GG-HR
 ↓
DL-FS-HR-Modify
 ↓
SMB / NTFS
```

Pas :

```text
User directly on ACL
```

ni :

```text
GG-HR directly on ACL
```

si la baseline AGDLP Phase 06 est déployée.

---

# 09.10.2 - Identity and Token

```powershell
whoami
whoami /groups
```

Chercher :

```text
DIARABAKA\GG-HR
```

Une nouvelle appartenance groupe peut nécessiter une nouvelle session Windows.

---

# 09.10.3 - Connectivity

```powershell
Resolve-DnsName FILE01
Test-NetConnection FILE01 -Port 445
```

---

# 09.10.4 - AD Membership

Sur DC01 :

```powershell
Get-ADGroupMember "GG-HR" |
    Select-Object `
        Name,
        SamAccountName
```

Puis :

```powershell
Get-ADGroupMember "DL-FS-HR-Modify" |
    Select-Object `
        Name,
        SamAccountName,
        ObjectClass
```

Cible :

```text
GG-HR nested in DL-FS-HR-Modify
```

---

# 09.10.5 - SMB ACL

Sur FILE01 :

```powershell
Get-SmbShareAccess `
    -Name "HR$"
```

Cible :

```text
DIARABAKA\DL-FS-HR-Modify
```

selon la baseline.

---

# 09.10.6 - Discover NTFS Path

```powershell
$HRPath = (
    Get-SmbShare `
        -Name "HR$"
).Path

$HRPath
```

Puis :

```powershell
icacls $HRPath
```

Ne pas supposer :

```text
D:\Shares
E:\Shares
```

---

# 09.10.7 - Positive Functional Test

```powershell
$TestFile = `
    "\\FILE01\HR$\validation-$env:COMPUTERNAME-$([guid]::NewGuid()).txt"

"Controlled HR access validation" |
    Set-Content `
        -Path $TestFile `
        -ErrorAction Stop
```

Puis :

```powershell
Get-Content `
    -Path $TestFile `
    -ErrorAction Stop
```

Puis :

```powershell
Remove-Item `
    -Path $TestFile `
    -Force `
    -ErrorAction Stop
```

---

# 09.10.8 - Negative Security Test

Avec le même utilisateur HR :

```powershell
try {

    Get-ChildItem `
        "\\FILE01\Finance$" `
        -ErrorAction Stop

    Write-Host "UNEXPECTED ACCESS"

}
catch {

    Write-Host $_.Exception.Message
}
```

Attendu :

```text
Access is denied
```

ou équivalent localisé.

---

# 09.10.9 - Validation

```text
HR access restored
+
Finance still denied
+
AGDLP preserved
+
No direct user ACL
```

---

# 09.11 - TICKET INC-005 - GPO Not Applied

## Situation

> Une politique de sécurité n'est plus appliquée sur WIN11.

---

# 09.11.1 - Computer Location

Sur DC01 :

```powershell
Get-ADComputer WIN11 `
    -Properties DistinguishedName |
    Select-Object `
        Name,
        DistinguishedName
```

Cible :

```text
CN=WIN11,OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com
```

---

# 09.11.2 - RSoP

Sur WIN11 :

```powershell
gpresult /r /scope computer
```

Puis :

```powershell
New-Item `
    -Path "C:\Temp" `
    -ItemType Directory `
    -Force |
    Out-Null
```

Puis :

```powershell
gpresult `
    /scope computer `
    /h "C:\Temp\WIN11-GPResult.html"
```

---

# 09.11.3 - GPO Link / Inheritance

Sur DC01 :

```powershell
Get-GPInheritance `
    -Target "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

---

# 09.11.4 - Diagnostic Tree

```text
Correct computer?
 ↓
Correct OU?
 ↓
GPO exists?
 ↓
Link present?
 ↓
Link enabled?
 ↓
GPO enabled?
 ↓
Security filtering?
 ↓
WMI filter?
 ↓
Inheritance?
 ↓
Block inheritance?
 ↓
Enforced?
 ↓
AD replication?
 ↓
SYSVOL?
 ↓
DNS?
 ↓
Client processing?
 ↓
Effective setting?
```

---

# 09.11.5 - GroupPolicy Operational Log

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-GroupPolicy/Operational" `
    -MaxEvents 100 |
    Select-Object `
        TimeCreated,
        Id,
        LevelDisplayName,
        Message
```

---

# 09.11.6 - Replication Dependency

Si nécessaire :

```powershell
repadmin /replsummary
```

Ne pas déclarer la réplication saine tant que la sortie actuelle ne le prouve pas.

---

# 09.11.7 - Refresh

Seulement après collecte :

```powershell
gpupdate /force
```

Puis refaire :

```powershell
gpresult /r /scope computer
```

---

# 09.11.8 - Functional Validation

Valider le paramètre réel.

Exemples :

```text
Firewall enabled
Defender setting effective
BitLocker policy effective
LAPS processing succeeds
```

---

# 09.12 - TICKET INC-006 - FILE01 Unavailable

## Situation

> FILE01 n'est plus accessible.

---

# 09.12.1 - Client DNS

Depuis WIN11 :

```powershell
Resolve-DnsName FILE01
Resolve-DnsName FILE01.diarabaka.com
```

---

# 09.12.2 - SMB Connectivity

```powershell
Test-NetConnection `
    FILE01 `
    -Port 445
```

---

# 09.12.3 - FILE01 Service

Sur FILE01 :

```powershell
Get-Service LanmanServer
```

---

# 09.12.4 - Shares

```powershell
Get-SmbShare |
    Select-Object `
        Name,
        Path,
        FolderEnumerationMode,
        EncryptData
```

---

# 09.12.5 - Storage

```powershell
Get-Volume |
    Select-Object `
        DriveLetter,
        FileSystemLabel,
        HealthStatus,
        Size,
        SizeRemaining
```

---

# 09.12.6 - SMB Sessions

```powershell
Get-SmbSession
```

---

# 09.12.7 - Event Logs

```powershell
$Since = (Get-Date).AddHours(-4)

Get-WinEvent `
    -FilterHashtable @{
        LogName   = "System"
        StartTime = $Since
        Level     = 1,2
    } `
    -ErrorAction SilentlyContinue |
    Select-Object `
        TimeCreated,
        Id,
        ProviderName,
        Message
```

---

# 09.12.8 - Diagnostic Tree

```text
CLIENT
 ↓
DNS
 ↓
TCP 445
 ↓
FILE01
 ↓
LanmanServer
 ↓
Share present
 ↓
Storage healthy
 ↓
SMB ACL
 ↓
NTFS ACL
```

Distinguer :

```text
SERVER UNAVAILABLE
SHARE MISSING
ACCESS DENIED
STORAGE FAILURE
```

---

# 09.13 - TICKET INC-007 - DHCP Does Not Assign Address

## Situation

WIN11 reçoit :

```text
169.254.x.x
```

---

# 09.13.1 - Preserve Client State

Avant release/renew :

```powershell
Get-NetAdapter
Get-NetIPInterface -AddressFamily IPv4
ipconfig /all
```

Collecter :

```text
Adapter state
DHCP enabled
Current address
Gateway
DNS
DHCP server
Lease times
```

---

# 09.13.2 - Renew Only After Baseline

```powershell
ipconfig /release
ipconfig /renew
```

Si le client reste APIPA, ne pas répéter sans analyse.

---

# 09.13.3 - DHCP Service DC01

```powershell
Get-Service DHCPServer
```

---

# 09.13.4 - DHCP Service DC02

```powershell
Get-Service `
    -ComputerName DC02 `
    -Name DHCPServer
```

---

# 09.13.5 - Authorization

```powershell
Get-DhcpServerInDC
```

---

# 09.13.6 - Scope DC01

```powershell
Get-DhcpServerv4Scope `
    -ComputerName DC01
```

---

# 09.13.7 - Scope DC02

```powershell
Get-DhcpServerv4Scope `
    -ComputerName DC02
```

---

# 09.13.8 - Capacity

```powershell
Get-DhcpServerv4ScopeStatistics `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0
```

---

# 09.13.9 - Bindings

```powershell
Get-DhcpServerv4Binding `
    -ComputerName DC01

Get-DhcpServerv4Binding `
    -ComputerName DC02
```

---

# 09.13.10 - Failover DC01

```powershell
Get-DhcpServerv4Failover `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0 |
    Format-List
```

---

# 09.13.11 - Failover DC02

```powershell
Get-DhcpServerv4Failover `
    -ComputerName DC02 `
    -ScopeId 192.168.1.0 |
    Format-List
```

Vérifier :

```text
Partner
Mode
State
Load balance
Scope
```

---

# 09.13.12 - Client Validation

Après correction :

```powershell
ipconfig /renew
ipconfig /all
```

Cible :

```text
IP from expected scope
Gateway 192.168.1.1
DNS DC01 + DC02
Suffix diarabaka.com
```

---

# 09.14 - TICKET INC-008 - AD Replication Failure

## Situation

Phase 08 Health Check :

```text
AD REPLICATION : CRITICAL
```

---

# 09.14.1 - Summary

```powershell
repadmin /replsummary
```

Capturer l'erreur exacte.

---

# 09.14.2 - DC01 Detail

```powershell
repadmin /showrepl DC01
```

---

# 09.14.3 - DC02 Detail

```powershell
repadmin /showrepl DC02
```

---

# 09.14.4 - DCDIAG Replications

```powershell
dcdiag /test:replications
```

---

# 09.14.5 - DCDIAG DNS

```powershell
dcdiag /test:dns
```

---

# 09.14.6 - DNS Dependencies

```powershell
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com
```

Puis :

```powershell
Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV
```

---

# 09.14.7 - RPC Diagnostic

```powershell
Test-NetConnection DC01 -Port 135
Test-NetConnection DC02 -Port 135
```

TCP/135 n'est qu'une partie du chemin RPC.

---

# 09.14.8 - Time

```powershell
w32tm /query /status
w32tm /query /source
```

Sur DC02 :

```powershell
Invoke-Command `
    -ComputerName DC02 `
    -ScriptBlock {
        w32tm /query /status
        w32tm /query /source
    }
```

---

# 09.14.9 - Critical Services

```powershell
Get-Service `
    NTDS,
    DNS,
    Netlogon,
    KDC |
    Select-Object `
        Name,
        Status
```

Sur DC02 :

```powershell
Invoke-Command `
    -ComputerName DC02 `
    -ScriptBlock {
        Get-Service `
            NTDS,
            DNS,
            Netlogon,
            KDC |
            Select-Object `
                Name,
                Status
    }
```

---

# 09.14.10 - Event Logs

Examiner selon contexte :

```text
Directory Service
DNS Server
System
DFS Replication
```

---

# 09.14.11 - Error-Oriented Diagnosis

```text
ERROR CODE
   ↓
EXACT CONTEXT
   ↓
DEPENDENCY
   ↓
ROOT CAUSE
   ↓
MINIMUM CORRECTION
```

Ne pas :

```text
Error code
 ↓
Random internet fix
```

---

# 09.14.12 - Validation

Après correction :

```powershell
repadmin /replsummary
```

Puis :

```powershell
dcdiag /test:replications
```

Cible :

```text
0 current replication failures
```

Aucun `PASS` ne doit être écrit avant vraie sortie.

---

# 09.15 - TICKET INC-009 - FILE01 Low Disk Space

## Situation

FILE01 approche d'un seuil critique.

---

# 09.15.1 - Capacity

```powershell
Get-Volume |
    Where-Object DriveLetter |
    Select-Object `
        DriveLetter,
        FileSystemLabel,
        HealthStatus,
        @{
            Name = "SizeGB"
            Expression = {
                [math]::Round($_.Size / 1GB,2)
            }
        },
        @{
            Name = "FreeGB"
            Expression = {
                [math]::Round($_.SizeRemaining / 1GB,2)
            }
        },
        @{
            Name = "FreePercent"
            Expression = {
                if ($_.Size -gt 0) {
                    [math]::Round(
                        ($_.SizeRemaining / $_.Size) * 100,
                        2
                    )
                }
            }
        }
```

---

# 09.15.2 - Discover Data Path

Ne pas coder :

```text
D:\Shares
E:\Shares
```

Découvrir :

```powershell
Get-SmbShare |
    Where-Object {
        $_.Name -in @(
            "IT$",
            "HR$",
            "Finance$",
            "Marketing$",
            "Sales$",
            "Public$"
        )
    } |
    Select-Object `
        Name,
        Path
```

---

# 09.15.3 - Identify Large Data

Pour chaque chemin réellement découvert :

```powershell
Get-ChildItem `
    "<ACTUAL_PATH>" `
    -Directory
```

Ne pas lancer de suppression automatique.

---

# 09.15.4 - FSRM

```powershell
Get-FsrmQuota |
    Select-Object `
        Path,
        Size,
        Usage,
        Disabled,
        SoftLimit
```

---

# 09.15.5 - Root Cause Candidates

```text
User growth
Temporary data
Logs
Unexpected files
Backup accumulation
Application data
Quota policy mismatch
```

---

# 09.15.6 - Correction Policy

```text
IDENTIFY
 ↓
CONFIRM OWNER
 ↓
CONFIRM RETENTION
 ↓
BACKUP IF REQUIRED
 ↓
ARCHIVE / DELETE / MOVE
 ↓
VALIDATE CAPACITY
 ↓
VALIDATE APPLICATION / SHARE
```

---

# 09.16 - TICKET INC-010 - WIN11 Security Degraded

## Situation

Le health check indique qu'un contrôle de sécurité est dégradé.

---

# 09.16.1 - Defender Runtime

```powershell
Get-MpComputerStatus |
    Select-Object `
        AntivirusEnabled,
        RealTimeProtectionEnabled,
        BehaviorMonitorEnabled,
        AntivirusSignatureLastUpdated
```

---

# 09.16.2 - Defender Effective Policy

```powershell
Get-MpPreference |
    Select-Object `
        DisableRealtimeMonitoring,
        MAPSReporting,
        SubmitSamplesConsent
```

---

# 09.16.3 - Firewall

```powershell
Get-NetFirewallProfile |
    Select-Object `
        Name,
        Enabled,
        DefaultInboundAction,
        DefaultOutboundAction
```

---

# 09.16.4 - Firewall Functional Flow

```powershell
Test-NetConnection `
    FILE01 `
    -Port 445
```

---

# 09.16.5 - BitLocker

```powershell
Get-BitLockerVolume `
    -MountPoint "C:" |
    Select-Object `
        MountPoint,
        VolumeStatus,
        ProtectionStatus,
        EncryptionPercentage
```

---

# 09.16.6 - TPM

```powershell
Get-Tpm |
    Select-Object `
        TpmPresent,
        TpmReady,
        TpmEnabled,
        TpmActivated
```

---

# 09.16.7 - BitLocker Recovery AD

Sur DC01 :

```powershell
$ComputerDN = (
    Get-ADComputer WIN11
).DistinguishedName

Get-ADObject `
    -Filter 'objectClass -eq "msFVE-RecoveryInformation"' `
    -SearchBase $ComputerDN |
    Select-Object `
        Name,
        ObjectClass,
        DistinguishedName
```

Ne jamais publier la recovery password.

---

# 09.16.8 - LAPS

Sur WIN11 :

```powershell
Get-LocalUser
```

Puis :

```powershell
Invoke-LapsPolicyProcessing
Get-LapsDiagnostics
```

Puis :

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-LAPS/Operational" `
    -MaxEvents 30
```

Sur DC01 :

```powershell
Get-LapsADPassword `
    -Identity "WIN11"
```

Ne pas exposer le secret.

---

# 09.16.9 - Local Administrators

```powershell
Get-LocalGroupMember `
    -Group "Administrators" |
    Select-Object `
        Name,
        ObjectClass,
        PrincipalSource
```

---

# 09.16.10 - GPO

```powershell
gpresult /r /scope computer
```

Puis :

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-GroupPolicy/Operational" `
    -MaxEvents 50
```

---

# 09.16.11 - Validation

```text
Security setting restored
+
GPO still correct
+
Required business flows still work
+
No privilege broadening
```

---

# 09.17 - TICKET INC-011 - Computer Cannot Join Domain

## Situation

Un nouveau poste ne peut pas rejoindre :

```text
diarabaka.com
```

---

# 09.17.1 - Network

```powershell
Get-NetAdapter
Get-NetIPConfiguration
ipconfig /all
```

---

# 09.17.2 - DNS

```powershell
Resolve-DnsName diarabaka.com
```

Puis :

```powershell
Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV
```

---

# 09.17.3 - DC Locator

```powershell
nltest /dsgetdc:diarabaka.com
```

---

# 09.17.4 - Service Connectivity

```powershell
Test-NetConnection DC01 -Port 53
Test-NetConnection DC01 -Port 88
Test-NetConnection DC01 -Port 389
```

Puis DC02 si nécessaire.

---

# 09.17.5 - Time

```powershell
w32tm /query /status
```

---

# 09.17.6 - Existing Computer Object

Sur DC01 :

```powershell
Get-ADComputer `
    -Identity "<ComputerName>" `
    -ErrorAction SilentlyContinue
```

Ne pas supprimer automatiquement l'objet.

---

# 09.17.7 - Join

Après prérequis validés :

```powershell
Add-Computer `
    -DomainName "diarabaka.com" `
    -Credential (Get-Credential)
```

Puis redémarrage contrôlé.

---

# 09.17.8 - Validate Join

```powershell
Get-CimInstance Win32_ComputerSystem |
    Select-Object `
        Name,
        Domain,
        PartOfDomain
```

Puis :

```powershell
Test-ComputerSecureChannel
```

---

# 09.18 - TICKET INC-012 - Windows Update Not Applying

## Situation

WIN11 semble ne plus recevoir les correctifs attendus.

---

# 09.18.1 - Service Inventory

```powershell
Get-Service wuauserv
```

Ne pas conclure automatiquement qu'un service `Stopped` signifie Windows Update cassé.

---

# 09.18.2 - Patch History

```powershell
Get-HotFix |
    Sort-Object InstalledOn -Descending |
    Select-Object -First 10 `
        HotFixID,
        Description,
        InstalledOn
```

---

# 09.18.3 - GPO / RSoP

```powershell
gpresult `
    /scope computer `
    /h "C:\Temp\WIN11-GPResult.html"
```

Vérifier les paramètres réellement appliqués.

---

# 09.18.4 - Diagnostic Model

```text
Service inventory
 ↓
GPO / RSoP
 ↓
Effective policy
 ↓
Update history
 ↓
Logs if needed
 ↓
Root cause
```

---

# 09.19 - TICKET INC-013 - Unexpected Local Administrator

## Situation

Un compte inattendu apparaît dans `Administrators`.

```powershell
Get-LocalGroupMember `
    -Group "Administrators" |
    Select-Object `
        Name,
        ObjectClass,
        PrincipalSource
```

Questions :

```text
Expected?
Authorized?
Role based?
Temporary?
GPO-managed?
Manual drift?
```

Ne pas supprimer aveuglément avant d'identifier la source.

---

# 09.20 - TICKET INC-014 - Network Profile Incorrect

## Situation

WIN11 affiche :

```text
Public
```

alors qu'il se trouve sur le réseau domaine.

---

# 09.20.1 - Profile

```powershell
Get-NetConnectionProfile
```

---

# 09.20.2 - Dependencies

```powershell
Get-DnsClientServerAddress -AddressFamily IPv4
Resolve-DnsName diarabaka.com
nltest /dsgetdc:diarabaka.com
Test-ComputerSecureChannel
```

---

# 09.20.3 - Principle

Ne pas forcer artificiellement le profil sans corriger :

```text
DNS
DC Locator
NLA
Secure Channel
Network
```

---

# 09.21 - TICKET INC-015 - Secure Channel Broken

## Situation

```powershell
Test-ComputerSecureChannel
```

retourne :

```text
False
```

---

# 09.21.1 - Diagnose

```powershell
Resolve-DnsName diarabaka.com
nltest /dsgetdc:diarabaka.com
w32tm /query /status
w32tm /query /source
```

Sur DC01 :

```powershell
Get-ADComputer WIN11
```

Si nécessaire :

```powershell
repadmin /replsummary
```

---

# 09.21.2 - Repair

Seulement si justifié :

```powershell
Test-ComputerSecureChannel `
    -Repair `
    -Credential (Get-Credential)
```

---

# 09.21.3 - Validate

```powershell
Test-ComputerSecureChannel
```

Puis :

```powershell
nltest /dsgetdc:diarabaka.com
```

Puis vrai accès domaine.

---

# 09.22 - Root Cause vs Workaround

Il faut distinguer :

```text
WORKAROUND
```

de :

```text
ROOT CAUSE FIX
```

Exemple mauvais :

```text
HR user cannot access HR$
 ↓
Add user directly to NTFS
 ↓
Access restored
```

Correction préférée :

```text
User
 ↓
GG-HR
 ↓
DL-FS-HR-Modify
 ↓
SMB / NTFS
 ↓
Access
```

---

# 09.23 - Minimum Change Principle

Une correction doit être :

```text
TARGETED
REVERSIBLE
DOCUMENTED
TESTABLE
LEAST PRIVILEGE
```

Éviter :

```text
Disable Firewall
Give Domain Admin
Give Everyone Full Control
Disable GPO
Disable Antivirus
Delete AD Object
Restart All Servers
```

---

# 09.24 - Rollback

Avant modification significative :

```text
What changes?
What can fail?
How is previous state restored?
What evidence exists before change?
```

Exemple :

```text
CURRENT STATE
 ↓
EVIDENCE / BACKUP
 ↓
CONTROLLED CHANGE
 ↓
TEST
 ↓
FAILURE?
 ↓
ROLLBACK
```

---

# 09.25 - Functional Validation

Une commande réussie n'est pas suffisante.

| Correction             | Functional Test                                    |
| ---------------------- | -------------------------------------------------- |
| Account unlock         | User authenticates and does not immediately relock |
| Password reset         | User logs on and follows temporary-password flow   |
| DNS repair             | Internal resolution + SRV + DC Locator             |
| DHCP repair            | Client receives valid lease/options                |
| GPO repair             | Effective setting is observed                      |
| File permission repair | Authorized user works; unauthorized user denied    |
| SMB repair             | Expected share opens                               |
| Replication repair     | Current repadmin/dcdiag show healthy result        |
| Secure channel repair  | Trust true + domain resource access                |
| Firewall repair        | Firewall stays enabled + required flow works       |

---

# 09.26 - Security Regression

Après correction :

```text
SERVICE RESTORED
      +
SECURITY STILL CORRECT
```

Exemples :

```text
HR works
Finance denied

Firewall enabled
SMB works

User unlocked
No privilege escalation

GPO restored
Defender remains enabled
```

---

# 09.27 - Post-Incident Health Check

Après un incident infrastructure :

```text
FIX COMPONENT
      ↓
TEST COMPONENT
      ↓
RUN PHASE 08 HEALTH CHECK
      ↓
CHECK REGRESSION
```

Commande prévue :

```powershell
C:\SysAdminToolkit\08-HealthCheck\Invoke-InfrastructureHealthCheck.ps1
```

Ne pas déclarer `HEALTHY` si le script n'a pas été réellement exécuté et interprété.

---

# 09.38 - Troubleshooting Decision Model

```text
                         INCIDENT
                             │
                             ▼
                       DEFINE SCOPE
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
            USER          WORKSTATION     SERVER
              │              │              │
              └──────────────┼──────────────┘
                             ▼
                           NETWORK
                             │
                             ▼
                            DNS
                             │
                             ▼
                        DC LOCATOR
                             │
                             ▼
                           TIME
                             │
                             ▼
                             AD
                             │
                             ▼
                      AUTHENTICATION
                             │
                             ▼
                            GPO
                             │
                             ▼
                        RESOURCE
                             │
                             ▼
                        PERMISSIONS
                             │
                             ▼
                         ROOT CAUSE
                             │
                             ▼
                     MINIMUM CHANGE
                             │
                             ▼
                     FUNCTIONAL TEST
                             │
                             ▼
                    SECURITY REGRESSION
                             │
                             ▼
                       HEALTH CHECK
                             │
                             ▼
                       DOCUMENTATION
```

---

# 09.39 - Do Not Do This

```text
DNS problem
   → Flush DNS immediately

GPO problem
   → Edit GPO immediately

Access denied
   → Full Control

Firewall issue
   → Disable Firewall

Domain issue
   → Remove / rejoin immediately

Account issue
   → Reset password immediately

Replication issue
   → Force sync without diagnosis

Disk issue
   → Delete random files

Server issue
   → Reboot immediately
```

---

# 09.40 - Professional Troubleshooting Mindset

```text
What exactly failed?
Who is affected?
What still works?
What changed?
What dependency is next?
What evidence supports the hypothesis?
What is the smallest safe correction?
Did service return?
Did security remain intact?
Did global health remain intact?
```

---

# 09.41 - Final Architecture

```text
                         USER
                           │
                           ▼
                         TICKET
                           │
                           ▼
                    WINDOWS ADMIN
                           │
                           ▼
                         TRIAGE
                           │
                           ▼
                      DIAGNOSTIC
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
         AD               DNS            NETWORK
          │                │                │
          ├──────────┬─────┴─────┬──────────┤
          │          │           │          │
          ▼          ▼           ▼          ▼
         GPO       DHCP       FILE01      WIN11
          │          │           │          │
          └──────────┴─────┬─────┴──────────┘
                           │
                           ▼
                       ROOT CAUSE
                           │
                           ▼
                   MINIMUM CORRECTION
                           │
                           ▼
                    FUNCTIONAL RETEST
                           │
                           ▼
                   SECURITY REGRESSION
                           │
                           ▼
                      HEALTH CHECK
                           │
                           ▼
                        EVIDENCE
                           │
                           ▼
                   CLOSE / ESCALATE
```
