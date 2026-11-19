# PHASE 07 - WINDOWS 11 ADMINISTRATION

## Windows Server 2025 Enterprise Infrastructure

**Project:** Windows Server 2025 Enterprise Infrastructure  
**Domain:** `diarabaka.com`  
**Domain Controllers:** `DC01`, `DC02`  
**File Server:** `FILE01`  
**Client:** `WIN11`  
**Platform:** VMware  
**Professional Domain:** Microsoft Infrastructure

---

# 07.0 - Objectif

L'objectif n'est pas d'administrer Windows 11 comme un poste personnel.

L'objectif est de démontrer l'administration d'un poste d'entreprise intégré à l'infrastructure Microsoft :

Architecture :

```text
                    DIARABAKA.COM
                         │
             ┌───────────┴───────────┐
             │                       │
             ▼                       ▼
           DC01                    DC02
      AD / DNS / DHCP         AD / DNS / DHCP
             │                       │
             └───────────┬───────────┘
                         │
                    Group Policy
                         │
                         ▼
                       WIN11
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
       Identity        Security        Access
          │              │              │
      Kerberos       Defender        FILE01
      Secure         Firewall         SMB
      Channel        BitLocker        AGDLP
      AD Groups      LAPS             NTFS
                         │
                         ▼
                  Windows Update
                         │
                         ▼
                   Troubleshooting
                         │
                         ▼
                      Evidence
```

---

# 07.1 - Evidence Pack

Sur `WIN11` :

```powershell
$EvidenceRoot = "C:\Evidence\Windows11"

$Folders = @(
    "01-Baseline",
    "02-Network",
    "03-DNS",
    "04-AD",
    "05-Kerberos",
    "06-Time",
    "07-Secure-Channel",
    "08-GPO",
    "09-Defender",
    "10-Firewall",
    "11-BitLocker",
    "12-LAPS",
    "13-Windows-Update",
    "14-Local-Admins",
    "15-File-Access",
    "16-Helpdesk-Incidents",
    "17-Post-Reboot",
    "18-Final-Regression"
)

New-Item -ItemType Directory -Path $EvidenceRoot -Force | Out-Null

foreach ($Folder in $Folders) {
    New-Item `
        -ItemType Directory `
        -Path (Join-Path $EvidenceRoot $Folder) `
        -Force |
        Out-Null
}
```

---

# 07.2 - Baseline WIN11

```powershell
Get-Date
hostname
whoami
```

Puis :

```powershell
Get-ComputerInfo |
    Select-Object `
        CsName,
        WindowsProductName,
        WindowsVersion,
        OsBuildNumber
```

---

# 07.3 - Vérifier l'appartenance domaine

```powershell
Get-CimInstance Win32_ComputerSystem |
    Select-Object `
        Name,
        Domain,
        PartOfDomain
```

Cible :

```text
Name         : WIN11
Domain       : diarabaka.com
PartOfDomain : True
```

---

# 07.4 - Vérifier l'identité utilisateur

```powershell
whoami
```

Puis :

```powershell
whoami /upn
```

Puis :

```powershell
whoami /groups
```

Documenter :

```text
Current user
UPN
Domain
Security groups
Integrity / privilege context
```

---

# 07.5 - Position AD canonique de WIN11

Depuis DC01 :

```powershell
Get-ADComputer WIN11 |
    Select-Object `
        Name,
        DistinguishedName,
        Enabled
```

Cible :

```text
CN=WIN11,OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com
```

Le chemin historique :

```text
OU=Workstations,DC=diarabaka,DC=com
```

ne doit plus être utilisé.

---

# 07.6 - Architecture OU

```text
DIARABAKA.COM
│
└── OU=Diarabaka
    │
    └── OU=Computers
        │
        └── OU=Workstations
            │
            └── WIN11
```

Cela permet :

```text
WIN11
 ↓
Correct OU
 ↓
Correct GPO Links
 ↓
Correct Policy Scope
```

---

# 07.7 - Vérifier configuration réseau

```powershell
Get-NetIPConfiguration
```

Puis :

```powershell
ipconfig /all
```

Vérifier :

```text
IPv4 Address
Subnet Mask
Default Gateway
DHCP Enabled
DHCP Server
DNS Servers
DNS Suffix
```

---

# 07.8 - Vérifier adaptateur réseau

```powershell
Get-NetAdapter |
    Select-Object `
        Name,
        InterfaceDescription,
        Status,
        LinkSpeed,
        MacAddress
```

Cible :

```text
Status : Up
```

---

# 07.9 - Vérifier DHCP client state

```powershell
Get-NetIPInterface `
    -AddressFamily IPv4 |
    Select-Object `
        InterfaceAlias,
        Dhcp,
        ConnectionState
```

Documenter si WIN11 utilise :

```text
DHCP
or
Static configuration
```

selon le design réel.

---

# 07.10 - Vérifier la gateway

```powershell
Get-NetRoute `
    -DestinationPrefix "0.0.0.0/0" |
    Select-Object `
        InterfaceAlias,
        NextHop,
        RouteMetric
```

Cible du lab :

```text
NextHop : 192.168.1.1
```

---

# 07.11 - Vérifier profil réseau

```powershell
Get-NetConnectionProfile |
    Select-Object `
        InterfaceAlias,
        Name,
        NetworkCategory,
        IPv4Connectivity
```

---

# 07.12 - Vérifier DNS client

```powershell
Get-DnsClientServerAddress `
    -AddressFamily IPv4
```

Cible :

```text
192.168.1.10
192.168.1.11
```

Éviter :

```text
8.8.8.8
1.1.1.1
```

comme seuls DNS du poste domaine.

---

# 07.13 - Vérifier suffixe DNS

```powershell
Get-DnsClient |
    Select-Object `
        InterfaceAlias,
        ConnectionSpecificSuffix,
        RegisterThisConnectionsAddress
```

Puis :

```powershell
ipconfig /all
```

Cible :

```text
diarabaka.com
```

---

# 07.14 - Résolution DNS interne

```powershell
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com
Resolve-DnsName file01.diarabaka.com
Resolve-DnsName diarabaka.com
```

---

# 07.15 - Résolution LDAP SRV

```powershell
Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV
```

Objectif :

```text
SRV records
  ↓
Domain Controllers
```

---

# 07.16 - DC Locator

```powershell
nltest /dsgetdc:diarabaka.com
```

Documenter :

```text
DC name
Address
Domain
Forest
Site
Flags
```

---

# 07.17 - Vérifier AD Site

```powershell
nltest /dsgetsite
```

Cette commande permet de documenter le site AD vu par le client.

---

# 07.18 - Connectivité DC

```powershell
Test-Connection DC01 -Count 2
Test-Connection DC02 -Count 2
```

Puis :

```powershell
Test-NetConnection DC01 -Port 53
Test-NetConnection DC02 -Port 53
```

Puis LDAP :

```powershell
Test-NetConnection DC01 -Port 389
Test-NetConnection DC02 -Port 389
```

Puis Kerberos :

```powershell
Test-NetConnection DC01 -Port 88
Test-NetConnection DC02 -Port 88
```

Ces contrôles prouvent la connectivité, pas le fonctionnement complet du protocole.

---

# 07.19 - Kerberos : inspecter le cache

```powershell
klist
```

Vérifier la présence d'un TGT pour une session domaine.

Architecture :

```text
DOMAIN LOGON
   ↓
TGT
   ↓
SERVICE ACCESS
   ↓
SERVICE TICKET
```

---

# 07.20 - Kerberos fonctionnel avec FILE01

Accéder à une ressource domaine :

```powershell
Get-ChildItem "\\FILE01\Public$"
```

Puis :

```powershell
klist
```

Rechercher un ticket de service de type :

```text
cifs/FILE01
```

ou FQDN correspondant.

La preuve devient :

```text
TGT PRESENT
+
CIFS SERVICE TICKET
+
SMB ACCESS
=
KERBEROS FUNCTIONAL EVIDENCE
```

---

# 07.21 - Kerberos test contrôlé

Seulement si nécessaire :

```powershell
klist purge
```

Puis :

```powershell
Get-ChildItem "\\FILE01\Public$"
```

Puis :

```powershell
klist
```

`klist purge` perturbe temporairement la session Kerberos ; ne pas l'utiliser comme commande de routine.

---

# 07.22 - Synchronisation horaire

```powershell
w32tm /query /status
```

Puis :

```powershell
w32tm /query /source
```

Documenter :

```text
Source
Stratum
Last successful sync
Offset / status
```

---

# 07.23 - Secure Channel

```powershell
Test-ComputerSecureChannel
```

Cible :

```text
True
```

Ne pas retirer/réintégrer immédiatement le poste si le résultat est `False`.

---

# 07.24 - Secure Channel Troubleshooting

Workflow :

```text
SECURE CHANNEL FALSE
      ↓
DNS correct?
      ↓
DC Locator?
      ↓
Time synchronized?
      ↓
Network?
      ↓
Computer object enabled?
      ↓
AD replication?
      ↓
Repair justified?
```

Après diagnostic seulement :

```powershell
Test-ComputerSecureChannel `
    -Repair `
    -Credential (Get-Credential)
```

---

# 07.25 - GPO Baseline

Créer :

```powershell
New-Item `
    -Path "C:\Temp" `
    -ItemType Directory `
    -Force |
    Out-Null
```

Puis :

```powershell
gpupdate /force
```

Puis :

```powershell
gpresult /r /scope computer
```

---

# 07.26 - GPResult HTML

```powershell
gpresult `
    /scope computer `
    /h "C:\Temp\WIN11-GPResult.html"
```

Vérifier :

```powershell
Test-Path "C:\Temp\WIN11-GPResult.html"
```

---

# 07.27 - GPOs attendues

Selon Phase 05 :

```text
GPO-WS-Security-Baseline
GPO-Windows11-BitLocker
GPO-Windows11-LAPS
```

La liste réelle de `gpresult` est l'autorité de validation.

---

# 07.28 - Applied vs Denied GPOs

Dans le rapport :

```text
Applied Group Policy Objects
Denied Group Policy Objects
Filtering reason
Security
WMI
```

Une GPO liée mais refusée n'est pas appliquée.

---

# 07.29 - GroupPolicy Operational Log

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

À utiliser pour approfondir un problème de traitement GPO.

---

# 07.30 - GPO Troubleshooting côté DC

Depuis DC01 si nécessaire :

```powershell
Get-GPInheritance `
    -Target "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

Puis :

```powershell
repadmin /replsummary
```

Ne pas supposer la réplication saine sans sortie réelle.

---

# 07.31 - Microsoft Defender runtime

```powershell
Get-MpComputerStatus |
    Select-Object `
        AntivirusEnabled,
        AMServiceEnabled,
        AntispywareEnabled,
        RealTimeProtectionEnabled,
        BehaviorMonitorEnabled,
        IoavProtectionEnabled
```

---

# 07.32 - Microsoft Defender effective policy

```powershell
Get-MpPreference |
    Select-Object `
        DisableRealtimeMonitoring,
        MAPSReporting,
        SubmitSamplesConsent
```

Objectif :

```text
GPO
 ↓
Effective preference
 ↓
Runtime state
```

---

# 07.33 - Windows Firewall

```powershell
Get-NetFirewallProfile |
    Select-Object `
        Name,
        Enabled,
        DefaultInboundAction,
        DefaultOutboundAction
```

Cible projet :

```text
Domain  → Enabled
Private → Enabled
Public  → Enabled
```

---

# 07.34 - Firewall functional validation

Tester un flux métier requis :

```powershell
Test-NetConnection `
    FILE01 `
    -Port 445
```

Objectif :

```text
FIREWALL ENABLED
+
REQUIRED SMB FLOW WORKS
=
FUNCTIONAL
```

---

# 07.35 - Firewall Rule Investigation

```powershell
Get-NetFirewallRule |
    Where-Object {
        $_.Enabled -eq "True"
    } |
    Select-Object `
        DisplayName,
        Direction,
        Action,
        Profile
```

Ne pas modifier toutes les règles.

---

# 07.36 - BitLocker baseline

```powershell
Get-BitLockerVolume `
    -MountPoint "C:" |
    Select-Object `
        MountPoint,
        VolumeStatus,
        ProtectionStatus,
        EncryptionPercentage,
        KeyProtector
```

Puis :

```powershell
Get-Tpm
```

Cible :

```text
TpmPresent : True
TpmReady   : True
```

---

# 07.37 - BitLocker protectors

```powershell
manage-bde -protectors -get C:
```

Rechercher :

```text
TPM
Numerical Password
```

Ne jamais publier le recovery password en clair.

---

# 07.38 - BitLocker Recovery AD

Depuis DC01 :

```powershell
$ComputerDN = (
    Get-ADComputer WIN11
).DistinguishedName
```

Puis :

```powershell
Get-ADObject `
    -Filter 'objectClass -eq "msFVE-RecoveryInformation"' `
    -SearchBase $ComputerDN |
    Select-Object `
        Name,
        ObjectClass,
        DistinguishedName
```

Objectif :

```text
Recovery object present
```

sans exposer le secret.

---

# 07.39 - Windows LAPS module

Sur WIN11 :

```powershell
Get-Command -Module LAPS
```

Puis :

```powershell
gpresult /r /scope computer
```

Chercher :

```text
GPO-Windows11-LAPS
```

---

# 07.40 - Identifier le compte local géré

```powershell
Get-LocalUser |
    Select-Object `
        Name,
        Enabled,
        SID
```

Ne pas supposer que le compte local admin s'appelle toujours `Administrator`.

---

# 07.41 - LAPS processing

```powershell
Invoke-LapsPolicyProcessing
```

Puis :

```powershell
Get-LapsDiagnostics
```

---

# 07.42 - LAPS events

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-LAPS/Operational" `
    -MaxEvents 50 |
    Select-Object `
        TimeCreated,
        Id,
        LevelDisplayName,
        Message
```

---

# 07.43 - LAPS AD verification

Depuis DC01 :

```powershell
Get-LapsADPassword `
    -Identity "WIN11"
```

Ne pas utiliser `-AsPlainText` dans les captures ou preuves publiques.

---

# 07.44 - Local Administrators Audit

```powershell
Get-LocalGroupMember `
    -Group "Administrators" |
    Select-Object `
        Name,
        ObjectClass,
        PrincipalSource
```

Chaque membre doit être justifié.

---

# 07.45 - Standard User Must Not Be Local Admin

Avec le compte standard de test :

```powershell
whoami
whoami /groups
```

Puis comparer avec :

```powershell
Get-LocalGroupMember `
    -Group "Administrators"
```

Cible :

```text
Standard domain user
  ↓
Not local administrator
```

---

# 07.46 - Windows Update service inventory

```powershell
Get-Service wuauserv
```

Le service n'a pas besoin d'être constamment `Running` pour conclure qu'un client Windows Update est sain.

Documenter l'état réel.

---

# 07.47 - Windows Update via GPO / RSoP

Utiliser :

```powershell
gpresult `
    /scope computer `
    /h "C:\Temp\WIN11-GPResult.html"
```

Vérifier les paramètres Windows Update réellement appliqués dans le rapport.

---

# 07.48 - Update History baseline

```powershell
Get-HotFix |
    Sort-Object InstalledOn -Descending |
    Select-Object -First 10 `
        HotFixID,
        Description,
        InstalledOn
```

Ce contrôle documente l'historique de correctifs visible, mais ne remplace pas la validation de la policy.

---

# 07.49 - FILE01 DNS

```powershell
Resolve-DnsName FILE01
Resolve-DnsName FILE01.diarabaka.com
```

---

# 07.50 - FILE01 SMB Connectivity

```powershell
Test-NetConnection `
    FILE01 `
    -Port 445
```

Cible :

```text
TcpTestSucceeded : True
```

---

# 07.51 - FILE01 Public Access

```powershell
Test-Path "\\FILE01\Public$"
```

Puis :

```powershell
Get-ChildItem "\\FILE01\Public$"
```

---

# 07.52 - AGDLP validation HR

Avec utilisateur HR :

```powershell
whoami /groups
```

Vérifier :

```text
DIARABAKA\GG-HR
```

Côté AD :

```powershell
Get-ADGroupMember "DL-FS-HR-Modify"
```

Cible :

```text
GG-HR
```

Puis côté FILE01 :

```powershell
Get-SmbShareAccess `
    -Name "HR$"
```

Cible :

```text
DIARABAKA\DL-FS-HR-Modify
```

---

# 07.53 - Découvrir le chemin réel HR

Sur FILE01 :

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

Ne pas coder :

```text
D:\Shares
E:\Shares
```

sans découverte réelle.

---

# 07.54 - HR positive functional access

Sur WIN11 :

```powershell
"WIN11 ACCESS TEST" |
    Out-File "\\FILE01\HR$\WIN11-Test.txt"
```

Puis :

```powershell
Get-Content "\\FILE01\HR$\WIN11-Test.txt"
```

Puis :

```powershell
Remove-Item "\\FILE01\HR$\WIN11-Test.txt"
```

---

# 07.55 - Explicit negative access HR → Finance

```powershell
try {

    Get-ChildItem "\\FILE01\Finance$" `
        -ErrorAction Stop

    Write-Host "UNEXPECTED ACCESS"

}
catch {

    $_.Exception.Message
}
```

Cible :

```text
Access is denied
```

ou équivalent localisé.

---

# 07.56 - SMB Kerberos validation

Après accès à FILE01 :

```powershell
klist
```

Rechercher :

```text
cifs/FILE01
```

Cela relie :

```text
DNS
+
Kerberos
+
SMB
+
Authorization
```

---

# 07.57 - Helpdesk Troubleshooting Method

```text
SYMPTOM
   ↓
SCOPE
   ↓
IDENTITY
   ↓
NETWORK
   ↓
DNS
   ↓
DC LOCATOR
   ↓
TIME
   ↓
AUTHENTICATION
   ↓
GPO
   ↓
RESOURCE
   ↓
PERMISSIONS
   ↓
LOGS
   ↓
ROOT CAUSE
   ↓
MINIMUM CORRECTION
   ↓
FUNCTIONAL RETEST
   ↓
EVIDENCE
```

---

# 07.58 - Ticket WIN-INC-001 : DNS interne indisponible

Symptôme :

```text
Internet works
Internal resources fail
```

Vérifier :

```powershell
ipconfig /all
```

Puis :

```powershell
Get-DnsClientServerAddress `
    -AddressFamily IPv4
```

Puis :

```powershell
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com
Resolve-DnsName file01.diarabaka.com
```

Puis :

```powershell
Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV
```

Puis :

```powershell
nltest /dsgetdc:diarabaka.com
```

Puis :

```powershell
Test-NetConnection FILE01 -Port 445
```

---

# 07.59 - Ticket WIN-INC-002 : GPO non appliquée

Sur DC01 :

```powershell
Get-ADComputer WIN11 |
    Select-Object DistinguishedName
```

Puis :

```powershell
Get-GPInheritance `
    -Target "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

Sur WIN11 :

```powershell
gpresult /r /scope computer
```

Puis :

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-GroupPolicy/Operational" `
    -MaxEvents 100
```

Si nécessaire côté DC :

```powershell
repadmin /replsummary
```

Ensuite seulement :

```powershell
gpupdate /force
```

et retest.

---

# 07.60 - Ticket WIN-INC-003 : Account Lockout

Sur DC01 :

```powershell
Get-ADUser <USERNAME> `
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

Si autorisé et réellement verrouillé :

```powershell
Unlock-ADAccount `
    -Identity <USERNAME>
```

Puis :

```powershell
Get-ADUser <USERNAME> `
    -Properties LockedOut |
    Select-Object `
        SamAccountName,
        LockedOut
```

Si relock :

```text
SEARCH:
Saved credentials
Mapped drives
Scheduled tasks
Services
Other logged-on devices
Repeated bad password
```

---

# 07.61 - Ticket WIN-INC-004 : HR Access Denied

Sur WIN11 :

```powershell
whoami
whoami /groups
Resolve-DnsName FILE01
Test-NetConnection FILE01 -Port 445
```

Sur DC01 :

```powershell
Get-ADGroupMember "GG-HR"
Get-ADGroupMember "DL-FS-HR-Modify"
```

Sur FILE01 :

```powershell
Get-SmbShareAccess -Name "HR$"

$HRPath = (
    Get-SmbShare -Name "HR$"
).Path

icacls $HRPath
```

---

# 07.62 - Ticket WIN-INC-005 : Domain Logon Failure

```powershell
ipconfig /all
```

Puis :

```powershell
Resolve-DnsName diarabaka.com
```

Puis :

```powershell
Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV
```

Puis :

```powershell
nltest /dsgetdc:diarabaka.com
```

Puis :

```powershell
Test-NetConnection DC01 -Port 389
Test-NetConnection DC01 -Port 88
```

Puis :

```powershell
w32tm /query /status
w32tm /query /source
```

Puis :

```powershell
Test-ComputerSecureChannel
```

---

# 07.63 - Ticket WIN-INC-006 : APIPA / DHCP

Symptôme :

```text
169.254.x.x
```

D'abord :

```powershell
Get-NetAdapter |
    Select-Object `
        Name,
        Status,
        LinkSpeed
```

Puis :

```powershell
Get-NetIPInterface `
    -AddressFamily IPv4 |
    Select-Object `
        InterfaceAlias,
        Dhcp,
        ConnectionState
```

Puis :

```powershell
ipconfig /all
```

Puis :

```powershell
ipconfig /release
ipconfig /renew
```

Seulement ensuite, si nécessaire, serveur DHCP :

```powershell
Get-Service DHCPServer
Get-DhcpServerv4Scope
Get-DhcpServerv4ScopeStatistics `
    -ScopeId 192.168.1.0
Get-DhcpServerv4Failover
```

---

# 07.64 - Ticket WIN-INC-007 : LAPS indisponible

Sur WIN11 :

```powershell
gpresult /r /scope computer
Invoke-LapsPolicyProcessing
Get-LapsDiagnostics
```

Puis :

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-LAPS/Operational" `
    -MaxEvents 50
```

Sur DC01 :

```powershell
Get-LapsADPassword `
    -Identity "WIN11"
```

---

# 07.65 - Ticket WIN-INC-008 : BitLocker Recovery

Sur WIN11 :

```powershell
Get-BitLockerVolume `
    -MountPoint "C:"
```

Puis :

```powershell
manage-bde -protectors -get C:
```

Sur DC01 :

```powershell
$ComputerDN = (
    Get-ADComputer WIN11
).DistinguishedName

Get-ADObject `
    -Filter 'objectClass -eq "msFVE-RecoveryInformation"' `
    -SearchBase $ComputerDN
```

Ne jamais publier le recovery password.

---

# 07.66 - Ticket WIN-INC-009 : Defender désactivé

```powershell
Get-MpComputerStatus |
    Select-Object `
        AntivirusEnabled,
        RealTimeProtectionEnabled,
        BehaviorMonitorEnabled
```

Puis :

```powershell
Get-MpPreference |
    Select-Object `
        DisableRealtimeMonitoring,
        MAPSReporting,
        SubmitSamplesConsent
```

Puis :

```powershell
gpresult /r /scope computer
```

Diagnostiquer :

```text
GPO?
Third-party AV?
Local policy?
Service?
Platform state?
```

---

# 07.67 - Ticket WIN-INC-010 : Firewall bloque un service

Ne pas désactiver le firewall.

Tester :

```powershell
Test-NetConnection `
    <SERVER> `
    -Port <PORT>
```

Puis :

```powershell
Get-NetFirewallProfile
```

Puis examiner les règles pertinentes.

Correction :

```text
Required flow
  ↓
Specific rule
  ↓
Least privilege
```

---

# 07.68 - Ticket WIN-INC-011 : Network Profile Incorrect

```powershell
Get-NetConnectionProfile
```

Si le profil est `Public` alors que le client est sur le réseau domaine, vérifier :

```text
DNS
DC Locator
NLA
Secure Channel
Network
```

Ne pas forcer artificiellement le profil sans traiter la cause.

---

# 07.69 - Ticket WIN-INC-012 : Secure Channel Broken

```powershell
Test-ComputerSecureChannel
```

Puis :

```powershell
Resolve-DnsName diarabaka.com
nltest /dsgetdc:diarabaka.com
w32tm /query /status
```

Puis côté DC si nécessaire :

```powershell
Get-ADComputer WIN11
repadmin /replsummary
```

Repair seulement si diagnostic confirmé.

---

# 07.70 - Post-Reboot Baseline

Avant reboot :

```powershell
whoami
Test-ComputerSecureChannel
nltest /dsgetdc:diarabaka.com
w32tm /query /status
gpresult /r /scope computer
Get-MpComputerStatus
Get-NetFirewallProfile
Get-BitLockerVolume -MountPoint "C:"
```

---

# 07.71 - Reboot

```powershell
Restart-Computer
```

Après reconnexion, attendre que la session et le réseau soient pleinement disponibles avant validation.

---

# 07.72 - Post-Reboot Domain

```powershell
hostname
```

Puis :

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

# 07.73 - Post-Reboot DNS / DC Locator

```powershell
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com
Resolve-DnsName file01.diarabaka.com
```

Puis :

```powershell
nltest /dsgetdc:diarabaka.com
```

---

# 07.74 - Post-Reboot Kerberos

```powershell
klist
```

Puis :

```powershell
Get-ChildItem "\\FILE01\Public$"
```

Puis :

```powershell
klist
```

Rechercher le ticket CIFS.

---

# 07.75 - Post-Reboot GPO

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

# 07.76 - Post-Reboot Security

Defender :

```powershell
Get-MpComputerStatus |
    Select-Object `
        AntivirusEnabled,
        RealTimeProtectionEnabled
```

Firewall :

```powershell
Get-NetFirewallProfile |
    Select-Object `
        Name,
        Enabled
```

BitLocker :

```powershell
Get-BitLockerVolume `
    -MountPoint "C:"
```

---

# 07.77 - Post-Reboot LAPS

```powershell
Invoke-LapsPolicyProcessing
```

Puis :

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-LAPS/Operational" `
    -MaxEvents 20
```

---

# 07.78 - Post-Reboot FILE01

```powershell
Resolve-DnsName FILE01
Test-NetConnection FILE01 -Port 445
Test-Path "\\FILE01\Public$"
```

Avec utilisateur HR :

```powershell
Test-Path "\\FILE01\HR$"
```

---

# 07.79 - Final Workstation Regression

```text
DOMAIN
  ↓
DNS
  ↓
DC LOCATOR
  ↓
TIME
  ↓
SECURE CHANNEL
  ↓
KERBEROS
  ↓
GPO
  ↓
DEFENDER
  ↓
FIREWALL
  ↓
BITLOCKER
  ↓
LAPS
  ↓
WINDOWS UPDATE
  ↓
LOCAL ADMINS
  ↓
FILE01
  ↓
NEGATIVE ACCESS
  ↓
NO REGRESSION
```

# 07.85 - Final Architecture

```text
                      DIARABAKA.COM
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
            DC01                      DC02
      AD / DNS / DHCP           AD / DNS / DHCP
              │                         │
              └────────────┬────────────┘
                           │
                          GPO
                           │
                           ▼
                         WIN11
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
       Identity          Security          Access
         │                 │                 │
      DNS / DC          Defender          FILE01
      Locator           Firewall          SMB
      Kerberos          BitLocker         AGDLP
      Secure            LAPS              NTFS
      Channel           Updates
         │                 │                 │
         └─────────────────┼─────────────────┘
                           │
                           ▼
                     Troubleshooting
                           │
                           ▼
                        Evidence
                           │
                           ▼
                       Validation
```

# 07.5 - Baseline WIN11

Sur `WIN11` :

```powershell
Get-Date
hostname
whoami
```

Puis :

```powershell
Get-ComputerInfo |
    Select-Object `
        CsName,
        WindowsProductName,
        WindowsVersion,
        OsBuildNumber
```

---

# 07.6 - Domain Membership

```powershell
Get-CimInstance Win32_ComputerSystem |
    Select-Object `
        Name,
        Domain,
        PartOfDomain
```

Cible :

```text
Name         : WIN11
Domain       : diarabaka.com
PartOfDomain : True
```

---

# 07.7 - Canonical AD OU

Sur DC01 :

```powershell
Get-ADComputer WIN11 |
    Select-Object `
        Name,
        DistinguishedName,
        Enabled
```

Cible :

```text
CN=WIN11,OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com
```

L'ancien chemin :

```text
OU=Workstations,DC=diarabaka,DC=com
```

ne doit plus être utilisé.

---

# 07.8 - User Identity

Sur WIN11 :

```powershell
whoami
```

Puis :

```powershell
whoami /upn
```

Puis :

```powershell
whoami /groups
```

---

# 07.9 - Network Adapter Baseline

```powershell
Get-NetAdapter |
    Select-Object `
        Name,
        InterfaceDescription,
        Status,
        LinkSpeed,
        MacAddress
```

Cible :

```text
Status : Up
```

---

# 07.10 - IPv4 Baseline

```powershell
Get-NetIPConfiguration
```

Puis :

```powershell
ipconfig /all
```

Vérifier :

```text
IPv4 Address
Prefix
Default Gateway
DHCP State
DHCP Server
DNS Servers
DNS Suffix
```

---

# 07.11 - DHCP Client State

```powershell
Get-NetIPInterface `
    -AddressFamily IPv4 |
    Select-Object `
        InterfaceAlias,
        Dhcp,
        ConnectionState
```

---

# 07.12 - Default Gateway

```powershell
Get-NetRoute `
    -DestinationPrefix "0.0.0.0/0" |
    Select-Object `
        InterfaceAlias,
        NextHop,
        RouteMetric
```

Cible du lab :

```text
192.168.1.1
```

---

# 07.13 - Network Profile

```powershell
Get-NetConnectionProfile |
    Select-Object `
        InterfaceAlias,
        Name,
        NetworkCategory,
        IPv4Connectivity
```

Cible habituelle sur le réseau domaine :

```text
DomainAuthenticated
```

Un profil `Public` doit être diagnostiqué, pas forcé arbitrairement.

---

# 07.14 - DNS Client Baseline

```powershell
Get-DnsClientServerAddress `
    -AddressFamily IPv4 |
    Where-Object {
        $_.ServerAddresses
    } |
    Select-Object `
        InterfaceAlias,
        ServerAddresses
```

Cible :

```text
192.168.1.10
192.168.1.11
```

Éviter :

```text
Public DNS only
```

---

# 07.15 - DNS Suffix

```powershell
Get-DnsClient |
    Select-Object `
        InterfaceAlias,
        ConnectionSpecificSuffix,
        RegisterThisConnectionsAddress
```

Cible :

```text
diarabaka.com
```

---

# 07.16 - Internal DNS Resolution

```powershell
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com
Resolve-DnsName file01.diarabaka.com
Resolve-DnsName diarabaka.com
```

---

# 07.17 - LDAP SRV

```powershell
Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV
```

Cible :

```text
DC01
DC02
```

selon les enregistrements réellement présents.

---

# 07.18 - Kerberos SRV

```powershell
Resolve-DnsName `
    "_kerberos._tcp.diarabaka.com" `
    -Type SRV
```

---

# 07.19 - DC Locator

```powershell
nltest /dsgetdc:diarabaka.com
```

Documenter :

```text
DC Name
Address
Domain
Forest
Site
Flags
```

---

# 07.20 - AD Site

```powershell
nltest /dsgetsite
```

---

# 07.21 - DC Connectivity

```powershell
Test-Connection DC01 -Count 2
Test-Connection DC02 -Count 2
```

Puis LDAP :

```powershell
Test-NetConnection DC01 -Port 389
Test-NetConnection DC02 -Port 389
```

Puis Kerberos :

```powershell
Test-NetConnection DC01 -Port 88
Test-NetConnection DC02 -Port 88
```

Ces contrôles prouvent la connectivité, pas l'authentification complète.

---

# 07.22 - Kerberos Cache

```powershell
klist
```

Vérifier la présence d'un TGT pour une session domaine.

---

# 07.23 - Kerberos Functional SMB Test

Accéder à FILE01 :

```powershell
Get-ChildItem "\\FILE01\Public$"
```

Puis :

```powershell
klist
```

Rechercher un ticket de service :

```text
cifs/FILE01
```

ou l'équivalent FQDN.

Validation forte :

```text
TGT
+
SMB ACCESS
+
CIFS SERVICE TICKET
=
KERBEROS FUNCTIONAL EVIDENCE
```

---

# 07.24 - Time Synchronization

```powershell
w32tm /query /status
```

Puis :

```powershell
w32tm /query /source
```

Documenter :

```text
Source
Last successful synchronization
Status
```

---

# 07.25 - Secure Channel

```powershell
Test-ComputerSecureChannel
```

Cible :

```text
True
```

Un `False` doit être diagnostiqué avant toute réintégration domaine.

---

# 07.26 - GPO Baseline

```powershell
New-Item `
    -Path "C:\Temp" `
    -ItemType Directory `
    -Force |
    Out-Null
```

Puis :

```powershell
gpresult /r /scope computer
```

---

# 07.27 - GPResult HTML

```powershell
gpresult `
    /scope computer `
    /h "C:\Temp\WIN11-GPResult.html"
```

Vérifier :

```text
Applied Group Policy Objects
Denied Group Policy Objects
Filtering reasons
```

---

# 07.28 - GPO Inheritance

Sur DC01 :

```powershell
Get-GPInheritance `
    -Target "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

---

# 07.29 - GPO Inventory

```powershell
Get-GPO -All |
    Select-Object `
        DisplayName,
        GpoStatus |
    Sort-Object DisplayName
```

---

# 07.30 - GroupPolicy Operational Log

Sur WIN11 :

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

# 07.31 - GPO Troubleshooting Chain

```text
CORRECT COMPUTER?
      ↓
CORRECT OU?
      ↓
GPO EXISTS?
      ↓
LINK PRESENT?
      ↓
LINK ENABLED?
      ↓
SECURITY FILTERING?
      ↓
WMI FILTER?
      ↓
INHERITANCE?
      ↓
AD / DNS?
      ↓
AD REPLICATION?
      ↓
SYSVOL?
      ↓
CLIENT PROCESSING?
      ↓
GPRESULT?
      ↓
EFFECTIVE SETTING?
      ↓
FUNCTIONAL BEHAVIOR?
```

Si nécessaire côté DC :

```powershell
repadmin /replsummary
```

---

# 07.32 - Microsoft Defender Runtime

```powershell
Get-MpComputerStatus |
    Select-Object `
        AntivirusEnabled,
        AMServiceEnabled,
        AntispywareEnabled,
        RealTimeProtectionEnabled,
        BehaviorMonitorEnabled
```

---

# 07.33 - Microsoft Defender Effective Policy

```powershell
Get-MpPreference |
    Select-Object `
        DisableRealtimeMonitoring,
        MAPSReporting,
        SubmitSamplesConsent
```

Objectif :

```text
GPO
 ↓
Effective configuration
 ↓
Runtime state
```

---

# 07.34 - Windows Firewall

```powershell
Get-NetFirewallProfile |
    Select-Object `
        Name,
        Enabled,
        DefaultInboundAction,
        DefaultOutboundAction
```

---

# 07.35 - Firewall Functional Flow

```powershell
Test-NetConnection `
    FILE01 `
    -Port 445
```

Validation :

```text
Firewall enabled
+
Required SMB flow functional
```

---

# 07.36 - Firewall Rules Investigation

```powershell
Get-NetFirewallRule |
    Where-Object {
        $_.Enabled -eq "True"
    } |
    Select-Object `
        DisplayName,
        Direction,
        Action,
        Profile
```

---

# 07.37 - BitLocker Baseline

```powershell
Get-BitLockerVolume `
    -MountPoint "C:" |
    Select-Object `
        MountPoint,
        VolumeStatus,
        ProtectionStatus,
        EncryptionPercentage,
        KeyProtector
```

---

# 07.38 - TPM

```powershell
Get-Tpm
```

Cible :

```text
TpmPresent : True
TpmReady   : True
```

---

# 07.39 - BitLocker Protectors

```powershell
manage-bde -protectors -get C:
```

Identifier les types de protecteurs.

Ne jamais publier la recovery password.

---

# 07.40 - BitLocker Recovery AD

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

---

# 07.41 - Windows LAPS Module

Sur WIN11 :

```powershell
Get-Command -Module LAPS
```

---

# 07.42 - LAPS Managed Local Account Inventory

```powershell
Get-LocalUser |
    Select-Object `
        Name,
        Enabled,
        SID
```

Ne pas supposer que le compte géré se nomme toujours `Administrator`.

---

# 07.43 - LAPS GPO

```powershell
gpresult /r /scope computer
```

Chercher :

```text
GPO-Windows11-LAPS
```

---

# 07.44 - LAPS Processing

```powershell
Invoke-LapsPolicyProcessing
```

Puis :

```powershell
Get-LapsDiagnostics
```

---

# 07.45 - LAPS Events

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-LAPS/Operational" `
    -MaxEvents 50 |
    Select-Object `
        TimeCreated,
        Id,
        LevelDisplayName,
        Message
```

---

# 07.46 - LAPS AD Backup

Sur DC01 :

```powershell
Get-LapsADPassword `
    -Identity "WIN11"
```

Ne pas utiliser `-AsPlainText` dans les preuves.

---

# 07.47 - Windows Update Service

```powershell
Get-Service wuauserv
```

Ne pas interpréter automatiquement :

```text
Stopped
=
Broken
```

sans contexte.

---

# 07.48 - Windows Update History

```powershell
Get-HotFix |
    Sort-Object InstalledOn -Descending |
    Select-Object -First 10 `
        HotFixID,
        Description,
        InstalledOn
```

---

# 07.49 - Windows Update Policy Validation

Utiliser :

```powershell
gpresult `
    /scope computer `
    /h "C:\Temp\WIN11-GPResult.html"
```

et vérifier les paramètres Windows Update effectivement appliqués.

---

# 07.50 - Local Administrators Audit

```powershell
Get-LocalGroupMember `
    -Group "Administrators" |
    Select-Object `
        Name,
        ObjectClass,
        PrincipalSource
```

Chaque membre doit être justifié.

---

# 07.51 - Standard User Must Not Be Local Admin

Avec le compte standard de test :

```powershell
whoami
whoami /groups
```

Puis comparer avec :

```powershell
Get-LocalGroupMember `
    -Group "Administrators"
```

Cible :

```text
Standard domain user
      ↓
Not local administrator
```

---

# 07.52 - FILE01 DNS

```powershell
Resolve-DnsName FILE01
Resolve-DnsName FILE01.diarabaka.com
```

---

# 07.53 - FILE01 SMB Connectivity

```powershell
Test-NetConnection `
    FILE01 `
    -Port 445
```

---

# 07.54 - FILE01 Public Functional Access

```powershell
Get-ChildItem "\\FILE01\Public$"
```

---

# 07.55 - AGDLP Model

Authorization design :

```text
ACCOUNT
  ↓
GLOBAL GROUP
  ↓
DOMAIN LOCAL RESOURCE GROUP
  ↓
SMB / NTFS
```

Exemple HR :

```text
mmartin
  ↓
GG-HR
  ↓
DL-FS-HR-Modify
  ↓
HR$ / NTFS
```

---

# 07.56 - HR Group Membership

Sur WIN11 avec l'utilisateur HR :

```powershell
whoami /groups
```

Chercher :

```text
DIARABAKA\GG-HR
```

---

# 07.57 - HR Global Group Membership in AD

Sur DC01 :

```powershell
Get-ADGroupMember "GG-HR" |
    Select-Object `
        Name,
        SamAccountName
```

---

# 07.58 - AGDLP Nesting HR

```powershell
Get-ADGroupMember "DL-FS-HR-Modify" |
    Select-Object `
        Name,
        SamAccountName,
        ObjectClass
```

Cible :

```text
GG-HR
```

---

# 07.59 - HR Share ACL

Sur FILE01 :

```powershell
Get-SmbShareAccess `
    -Name "HR$"
```

Cible :

```text
DIARABAKA\DL-FS-HR-Modify
```

selon la baseline Phase 06.

---

# 07.60 - Discover HR NTFS Path

Sur FILE01 :

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

Ne pas coder en dur :

```text
D:\Shares
E:\Shares
```

sans découverte réelle.

---

# 07.61 - HR Positive Functional Test

Depuis WIN11 :

```powershell
"HELPDESK ACCESS TEST" |
    Out-File "\\FILE01\HR$\Helpdesk-Test.txt"
```

Lire :

```powershell
Get-Content `
    "\\FILE01\HR$\Helpdesk-Test.txt"
```

Supprimer :

```powershell
Remove-Item `
    "\\FILE01\HR$\Helpdesk-Test.txt"
```

---

# 07.62 - HR Negative Test Against Finance

Ne pas utiliser seulement :

```powershell
Test-Path "\\FILE01\Finance$"
```

Utiliser :

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

Cible :

```text
Access is denied
```

ou équivalent localisé.

---

# 07.63 - Ticket 01 - Internal Resources Unavailable

## Situation

Utilisateur :

> Internet fonctionne mais les ressources internes sont indisponibles.

Hypothèses :

```text
Wrong DNS
Internal DNS unavailable
SRV records unavailable
DC Locator failure
FILE01 name resolution failure
SMB unavailable
```

Diagnostic :

```powershell
ipconfig /all
Get-DnsClientServerAddress -AddressFamily IPv4
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com
Resolve-DnsName file01.diarabaka.com
Resolve-DnsName "_ldap._tcp.dc._msdcs.diarabaka.com" -Type SRV
nltest /dsgetdc:diarabaka.com
Test-NetConnection FILE01 -Port 445
```

Validation :

```text
Internal DNS restored
+
DC Locator works
+
Business resource access restored
```

---

# 07.64 - Ticket 02 - GPO Not Applied

## Situation

> La politique de sécurité du poste ne semble pas appliquée.

Diagnostic :

```powershell
hostname
```

Sur DC01 :

```powershell
Get-ADComputer WIN11 |
    Select-Object `
        Name,
        DistinguishedName
```

Puis :

```powershell
Get-GPInheritance `
    -Target "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

Sur WIN11 :

```powershell
gpresult /r /scope computer
```

Puis :

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-GroupPolicy/Operational" `
    -MaxEvents 100
```

Si nécessaire :

```powershell
repadmin /replsummary
```

Après diagnostic seulement :

```powershell
gpupdate /force
```

Puis retest.

---

# 07.65 - Ticket 03 - Account Locked

## Situation

> Je connais mon mot de passe mais ma connexion est refusée.

Sur DC01 :

```powershell
Get-ADUser <USERNAME> `
    -Properties `
        Enabled,
        LockedOut,
        PasswordExpired,
        AccountExpirationDate |
    Select-Object `
        SamAccountName,
        Enabled,
        LockedOut,
        PasswordExpired,
        AccountExpirationDate
```

Puis :

```powershell
Search-ADAccount -LockedOut
```

Si autorisé :

```powershell
Unlock-ADAccount `
    -Identity <USERNAME>
```

Retest :

```powershell
Get-ADUser <USERNAME> `
    -Properties LockedOut |
    Select-Object `
        SamAccountName,
        LockedOut
```

Si relock :

```text
Stored credential
Mapped drive
Scheduled task
Service
Application
Other logged-on device
Old password
Repeated failed logon
```

Event utile :

```text
4740
```

---

# 07.66 - Ticket 04 - HR Share Access Denied

## Situation

> Je suis dans HR mais je n'accède pas au partage HR.

Workflow :

```text
USER
 ↓
GG-HR
 ↓
DL-FS-HR-Modify
 ↓
NETWORK
 ↓
SMB
 ↓
SHARE ACL
 ↓
NTFS ACL
 ↓
TOKEN
 ↓
FUNCTIONAL ACCESS
```

Sur WIN11 :

```powershell
whoami
whoami /groups
Resolve-DnsName FILE01
Test-NetConnection FILE01 -Port 445
```

Sur DC01 :

```powershell
Get-ADGroupMember "GG-HR"
Get-ADGroupMember "DL-FS-HR-Modify"
```

Sur FILE01 :

```powershell
Get-SmbShareAccess -Name "HR$"

$HRPath = (
    Get-SmbShare -Name "HR$"
).Path

icacls $HRPath
```

Puis test fonctionnel.

---

# 07.67 - Ticket 05 - Domain Logon Problem

## Situation

> Le PC est sur le réseau mais la connexion domaine échoue.

Diagnostic :

```powershell
Get-NetAdapter
Get-NetIPConfiguration
Get-DnsClientServerAddress -AddressFamily IPv4
Resolve-DnsName diarabaka.com
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com
Resolve-DnsName "_ldap._tcp.dc._msdcs.diarabaka.com" -Type SRV
nltest /dsgetdc:diarabaka.com
Test-NetConnection DC01 -Port 389
Test-NetConnection DC01 -Port 88
w32tm /query /status
w32tm /query /source
Test-ComputerSecureChannel
```

Ne pas réintégrer immédiatement le poste au domaine.

---

# 07.68 - Ticket 06 - DHCP / APIPA

## Situation

```text
169.254.x.x
```

D'abord côté WIN11 :

```powershell
Get-NetAdapter |
    Select-Object `
        Name,
        Status,
        LinkSpeed
```

Puis :

```powershell
Get-NetIPInterface `
    -AddressFamily IPv4 |
    Select-Object `
        InterfaceAlias,
        Dhcp,
        ConnectionState
```

Puis :

```powershell
ipconfig /all
```

Puis :

```powershell
ipconfig /release
ipconfig /renew
```

Si problème persistant, DC01 :

```powershell
Get-Service DHCPServer
Get-DhcpServerv4Scope
Get-DhcpServerv4ScopeStatistics `
    -ScopeId 192.168.1.0
Get-DhcpServerv4Failover `
    -ComputerName DC01
```

Puis DC02 :

```powershell
Get-Service `
    -ComputerName DC02 `
    -Name DHCPServer

Get-DhcpServerv4Failover `
    -ComputerName DC02
```

---

# 07.69 - Ticket 07 - BitLocker Recovery

## Situation

> Le poste demande une clé de récupération BitLocker.

Sur WIN11 si accessible :

```powershell
Get-BitLockerVolume `
    -MountPoint "C:"
```

Puis :

```powershell
Get-Tpm
```

Puis :

```powershell
manage-bde -protectors -get C:
```

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

# 07.70 - Ticket 08 - LAPS Password Unavailable

Sur WIN11 :

```powershell
Get-LocalUser
gpresult /r /scope computer
Invoke-LapsPolicyProcessing
Get-LapsDiagnostics
```

Puis :

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-LAPS/Operational" `
    -MaxEvents 50
```

Sur DC01 :

```powershell
Get-LapsADPassword `
    -Identity "WIN11"
```

---

# 07.71 - Ticket 09 - Defender Disabled

```powershell
Get-MpComputerStatus |
    Select-Object `
        AntivirusEnabled,
        RealTimeProtectionEnabled,
        BehaviorMonitorEnabled
```

Puis :

```powershell
Get-MpPreference |
    Select-Object `
        DisableRealtimeMonitoring,
        MAPSReporting,
        SubmitSamplesConsent
```

Puis :

```powershell
gpresult /r /scope computer
```

Hypothèses :

```text
GPO
Local policy
Third-party AV
Service
Security platform state
```

---

# 07.72 - Ticket 10 - Firewall Connectivity Problem

Ne pas désactiver le firewall.

```powershell
Get-NetFirewallProfile
```

Puis :

```powershell
Test-NetConnection `
    <SERVER> `
    -Port <PORT>
```

Puis :

```powershell
Get-NetFirewallRule |
    Where-Object {
        $_.Enabled -eq "True"
    }
```

Objectif :

```text
Required flow
  ↓
Specific rule
  ↓
Least privilege correction
```

---

# 07.73 - Ticket 11 - Network Profile Incorrect

## Situation

Le poste est sur le réseau domaine mais affiche un profil `Public`.

```powershell
Get-NetConnectionProfile
```

Vérifier :

```text
DNS
DC Locator
NLA
Secure Channel
Network connectivity
```

Ne pas forcer le profil sans traiter la cause.

---

# 07.74 - Ticket 12 - Secure Channel Broken

```powershell
Test-ComputerSecureChannel
```

Si `False` :

```powershell
Resolve-DnsName diarabaka.com
nltest /dsgetdc:diarabaka.com
w32tm /query /status
```

Puis côté DC si nécessaire :

```powershell
Get-ADComputer WIN11
repadmin /replsummary
```

Repair uniquement si justifié :

```powershell
Test-ComputerSecureChannel `
    -Repair `
    -Credential (Get-Credential)
```

---

# 07.75 - Ticket 13 - Windows Update Issue

## Situation

> Le poste semble ne plus recevoir de correctifs.

Vérifier :

```powershell
Get-Service wuauserv
```

Puis :

```powershell
Get-HotFix |
    Sort-Object InstalledOn -Descending |
    Select-Object -First 10
```

Puis :

```powershell
gpresult `
    /scope computer `
    /h "C:\Temp\WIN11-GPResult.html"
```

Workflow :

```text
Service inventory
 ↓
Policy / RSoP
 ↓
Update history
 ↓
Client logs if needed
 ↓
Root cause
```

---

# 07.76 - Ticket 14 - Unexpected Local Administrator

## Situation

Un compte inattendu apparaît dans le groupe local Administrators.

```powershell
Get-LocalGroupMember `
    -Group "Administrators" |
    Select-Object `
        Name,
        ObjectClass,
        PrincipalSource
```

Vérifier :

```text
Expected?
Authorized?
Role-based?
Temporary?
Unapproved?
```

Ne pas supprimer aveuglément sans comprendre la source de gestion.

---

# 07.77 - Ticket 15 - SMB Works but Wrong Permissions

## Situation

Le partage est accessible mais les droits ne correspondent pas au rôle.

Diagnostic :

```text
USER
 ↓
GLOBAL GROUP
 ↓
DOMAIN LOCAL GROUP
 ↓
SHARE ACL
 ↓
NTFS ACL
 ↓
TOKEN
 ↓
EFFECTIVE ACCESS
```

Contrôles :

```powershell
whoami /groups
```

Sur DC01 :

```powershell
Get-ADGroupMember <GLOBAL_GROUP>
Get-ADGroupMember <DOMAIN_LOCAL_GROUP>
```

Sur FILE01 :

```powershell
Get-SmbShareAccess -Name <SHARE>

$Path = (
    Get-SmbShare -Name <SHARE>
).Path

icacls $Path
```

---

# 07.78 - Incident Validation Requirements

Un ticket est `VALIDATED` uniquement si :

```text
SYMPTOM CONFIRMED
       +
ROOT CAUSE IDENTIFIED
       +
MINIMUM CORRECTION
       +
SERVICE RESTORED
       +
SECURITY PRESERVED
       +
NEGATIVE TEST IF RELEVANT
       +
POST-REBOOT RETEST IF RELEVANT
       +
EVIDENCE
```

---

# 07.79 - Post-Reboot Baseline

Avant reboot :

```powershell
Test-ComputerSecureChannel
nltest /dsgetdc:diarabaka.com
w32tm /query /status
gpresult /r /scope computer
Get-MpComputerStatus
Get-NetFirewallProfile
Get-BitLockerVolume -MountPoint "C:"
```

---

# 07.80 - Reboot

```powershell
Restart-Computer
```

Après reconnexion, refaire la validation complète.

---

# 07.81 - Post-Reboot Domain

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

# 07.82 - Post-Reboot DNS

```powershell
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com
Resolve-DnsName file01.diarabaka.com
```

Puis :

```powershell
nltest /dsgetdc:diarabaka.com
```

---

# 07.83 - Post-Reboot Kerberos

```powershell
klist
```

Puis :

```powershell
Get-ChildItem "\\FILE01\Public$"
```

Puis :

```powershell
klist
```

Rechercher le ticket CIFS.

---

# 07.84 - Post-Reboot GPO

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

# 07.85 - Post-Reboot Security

```powershell
Get-MpComputerStatus |
    Select-Object `
        AntivirusEnabled,
        RealTimeProtectionEnabled
```

Puis :

```powershell
Get-NetFirewallProfile
```

Puis :

```powershell
Get-BitLockerVolume `
    -MountPoint "C:"
```

---

# 07.86 - Post-Reboot FILE01

```powershell
Resolve-DnsName FILE01
Test-NetConnection FILE01 -Port 445
Get-ChildItem "\\FILE01\Public$"
```

Avec utilisateur HR :

```powershell
Get-ChildItem "\\FILE01\HR$"
```

---

# 07.87 - Final Security Regression

Après toute correction, vérifier qu'on n'a pas cassé autre chose.

Exemple HR :

```text
HR access restored
+
Finance still denied
+
Firewall still enabled
+
Standard user still not admin
=
Security preserved
```

---

# 07.88 - Final Workstation Regression

```text
DOMAIN
 ↓
OU
 ↓
NETWORK
 ↓
DNS
 ↓
DC LOCATOR
 ↓
TIME
 ↓
SECURE CHANNEL
 ↓
KERBEROS
 ↓
GPO
 ↓
DEFENDER
 ↓
FIREWALL
 ↓
BITLOCKER
 ↓
LAPS
 ↓
WINDOWS UPDATE
 ↓
LOCAL ADMINS
 ↓
FILE01
 ↓
NEGATIVE ACCESS
 ↓
NO REGRESSION
```

---

# 07.89 - Diagnostic Command Reference

## Identity

```powershell
whoami
whoami /upn
whoami /groups
```

## Network

```powershell
Get-NetAdapter
Get-NetIPConfiguration
Get-NetIPInterface -AddressFamily IPv4
Get-NetConnectionProfile
Test-Connection <HOST>
Test-NetConnection <HOST> -Port <PORT>
```

## DNS

```powershell
Get-DnsClientServerAddress -AddressFamily IPv4
Resolve-DnsName <HOST>
```

## Active Directory

```powershell
nltest /dsgetdc:diarabaka.com
nltest /dsgetsite
Test-ComputerSecureChannel
```

## Kerberos

```powershell
klist
```

## Group Policy

```powershell
gpresult /r /scope computer
gpresult /scope computer /h C:\Temp\WIN11-GPResult.html
```

## Security

```powershell
Get-MpComputerStatus
Get-MpPreference
Get-NetFirewallProfile
Get-BitLockerVolume -MountPoint "C:"
Get-Tpm
Get-LocalGroupMember -Group "Administrators"
```

## SMB

```powershell
Resolve-DnsName FILE01
Test-NetConnection FILE01 -Port 445
Get-ChildItem "\\FILE01\Public$"
```
